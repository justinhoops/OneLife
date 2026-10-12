import Combine
import Foundation
import os

/// Lock-backed cancellation is read on the persistence queue and written on
/// the interaction thread. A canceled queued snapshot exits before encoding.
private final class PersistenceRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var canceled = false

    func cancel() {
        lock.lock()
        canceled = true
        lock.unlock()
    }

    var isCanceled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return canceled
    }
}

final class LifeSimulator: ObservableObject {
    @Published private(set) var state: LifeState
    @Published private(set) var lastOutcome: ActionOutcome?
    @Published private(set) var saveErrorMessage: String?

    private let store: any LifePersisting
    private let playtestRecorder: any PlaytestRecording
    private var playtestSource: PlaytestSource?
    private var actionCache: [Domain: [DomainAction]] = [:]
    private let persistenceQueue = DispatchQueue(label: "OneLife.persistence", qos: .utility)
    private var saveGeneration: UInt64 = 0
    private var pendingPersistenceRequest: PersistenceRequest?
    private static let performanceLog = OSLog(
        subsystem: "LifeApp.OneLife",
        category: .pointsOfInterest
    )

    init(
        state: LifeState,
        store: any LifePersisting = LifePersistence(),
        playtestRecorder: any PlaytestRecording = NoopPlaytestRecorder.shared,
        playtestOrigin: OriginPreset? = nil
    ) {
        self.state = state
        self.store = store
        self.playtestRecorder = playtestRecorder
        self.state.lifeStage = LifeStage.stage(for: state.character.age)
        self.state.adoptHealthCompatibility()
        playtestRecorder.startOrResume(
            seed: state.runSeed,
            origin: playtestOrigin?.rawValue,
            initialState: self.state
        )
    }

    // MARK: - Queries

    private func acceptPrisonInformantOffer() {
        guard state.prison.informantOffered else { return }
        PrisonSystem.acceptInformant(state: &state)
        state.clamp()
        record(
            headline: "You chose the federal line",
            detail: "The offer bought information and protection, but your gang will treat the choice as a betrayal.",
            deltas: DeltaSummary(),
            isYearly: false
        )
        commit()
    }

    private func deferPrisonInformantOffer() {
        guard state.prison.informantOffered else { return }
        state.prison.informantOffered = false
        state.clamp()
        commit()
    }

    @discardableResult
    func performPrisonAction(_ action: PrisonActionKind, targetID: String? = nil) -> ActionOutcome? {
        guard state.prison.isIncarcerated else { return nil }
        let outcome = PrisonSystem.perform(action, targetID: targetID, state: &state)
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: outcome.cashDelta, health: outcome.healthDelta), state: &state)
        LifeThreadSystem.open(outcome.consequences, state: &state)
        state.clamp()
        record(headline: action.title, detail: outcome.bullets.joined(separator: " "), deltas: DeltaSummary(cash: outcome.cashDelta, health: outcome.healthDelta))
        commit()
        return lastOutcome
    }

    @discardableResult
    func acceptLegalPlea(_ caseID: String) -> ActionOutcome? {
        guard CriminalLegalSystem.acceptPlea(caseID: caseID, state: &state) else { return nil }
        record(headline: "Plea deal accepted", detail: "The sentence is reduced, but the conviction remains on your permanent record.", deltas: DeltaSummary())
        commit(); return lastOutcome
    }

    @discardableResult
    func takeLegalCaseToTrial(_ caseID: String) -> ActionOutcome? {
        guard CriminalLegalSystem.chooseTrial(caseID: caseID, state: &state) else { return nil }
        record(headline: "Case moved to trial", detail: "The outcome will resolve through the yearly legal pipeline.", deltas: DeltaSummary())
        commit(); return lastOutcome
    }

    @discardableResult
    func appealLegalCase(_ caseID: String) -> ActionOutcome? {
        guard CriminalLegalSystem.appeal(caseID: caseID, state: &state) else { return nil }
        record(headline: "Appeal filed", detail: "The conviction is being reviewed. An appeal can uphold, reduce, retry, or overturn it.", deltas: DeltaSummary())
        commit(); return lastOutcome
    }

    @discardableResult
    func postLegalBail(_ caseID: String) -> ActionOutcome? {
        guard let amount = CriminalLegalSystem.postBail(caseID: caseID, state: &state) else { return nil }
        record(headline: "Bail posted", detail: "$\(amount) was reserved while you remain under pretrial restrictions.", deltas: DeltaSummary(cash: -amount))
        commit(); return lastOutcome
    }

    @discardableResult
    func acceptLegalDetention(_ caseID: String) -> ActionOutcome? {
        guard CriminalLegalSystem.acceptDetention(caseID: caseID, state: &state) else { return nil }
        record(headline: "You accepted detention", detail: "The case will continue while your movement and criminal operations are suspended.", deltas: DeltaSummary())
        commit(); return lastOutcome
    }

    @discardableResult
    func requestSupervisedRelease(_ caseID: String) -> ActionOutcome? {
        guard CriminalLegalSystem.requestSupervisedRelease(caseID: caseID, state: &state) else { return nil }
        record(headline: "Supervised release granted", detail: "Electronic monitoring and strict travel conditions replaced detention.", deltas: DeltaSummary(cash: -1_500))
        commit(); return lastOutcome
    }

    @discardableResult
    func resolvePretrialViolation(_ caseID: String) -> ActionOutcome? {
        guard CriminalLegalSystem.resolvePretrialViolation(caseID: caseID, state: &state) else { return nil }
        record(headline: "Pretrial violation recorded", detail: "The court revoked your release and the case became harder to defend.", deltas: DeltaSummary())
        commit(); return lastOutcome
    }

    @discardableResult
    func hireDefenseLawyer(_ specialty: LegalLawyerSpecialty, forOrganization: Bool) -> ActionOutcome? {
        guard let lawyer = CriminalLegalSystem.hireLawyer(specialty: specialty, forOrganization: forOrganization, state: &state) else { return nil }
        let roster: String
        if forOrganization {
            roster = "organization defense team"
        } else {
            roster = "personal defense roster"
        }
        record(headline: "Lawyer retained", detail: "\(lawyer.name) joined the \(roster) as a \(lawyer.specialty.title) specialist.", deltas: DeltaSummary(cash: -lawyer.retainer))
        commit(); return lastOutcome
    }

    @discardableResult
    private func assignDefenseLawyer(_ lawyerID: String, to caseID: String) -> ActionOutcome? {
        guard CriminalLegalSystem.assignLawyer(caseID: caseID, lawyerID: lawyerID, state: &state) else { return nil }
        record(headline: "Defense counsel assigned", detail: "The selected lawyer will shape the next plea, trial, or appeal decision.", deltas: DeltaSummary())
        commit(); return lastOutcome
    }

    func enterpriseLegalTargets(for caseID: String) -> [LegalTargetState] {
        CriminalLegalSystem.enterpriseTargets(caseID: caseID, state: state)
    }

    func enterpriseLegalActions(for caseID: String, targetID: String) -> [EnterpriseLegalAction] {
        CriminalLegalSystem.availableEnterpriseActions(caseID: caseID, targetID: targetID, state: state)
    }

    func cooperationOffer(for caseID: String) -> LegalCooperationOffer? {
        CriminalLegalSystem.cooperationOffer(caseID: caseID, state: state)
    }

    @discardableResult
    func acceptLegalCooperation(caseID: String) -> ActionOutcome? {
        applyCooperationDecision(caseID: caseID, accept: true)
    }

    @discardableResult
    func declineLegalCooperation(caseID: String) -> ActionOutcome? {
        applyCooperationDecision(caseID: caseID, accept: false)
    }

    @discardableResult
    private func protectEnterpriseSpecialist(caseID: String, targetID: String) -> ActionOutcome? {
        applyEnterpriseLegalAction(.protect, caseID: caseID, targetID: targetID)
    }

    @discardableResult
    private func cutLooseEnterpriseSpecialist(caseID: String, targetID: String) -> ActionOutcome? {
        applyEnterpriseLegalAction(.cutLoose, caseID: caseID, targetID: targetID)
    }

    @discardableResult
    private func threatenEnterpriseSpecialist(caseID: String, targetID: String) -> ActionOutcome? {
        applyEnterpriseLegalAction(.threaten, caseID: caseID, targetID: targetID)
    }

    @discardableResult
    private func provideEnterpriseLegalSupport(caseID: String, targetID: String) -> ActionOutcome? {
        applyEnterpriseLegalAction(.provideLegalSupport, caseID: caseID, targetID: targetID)
    }

    @discardableResult
    private func applyEnterpriseLegalAction(_ action: EnterpriseLegalAction, caseID: String, targetID: String) -> ActionOutcome? {
        guard let outcome = CriminalLegalSystem.applyEnterpriseAction(caseID: caseID, targetID: targetID, action: action, state: &state) else { return nil }
        if outcome.cashDelta != 0 { _ = EffectResolutionSystem.apply(DeltaSummary(cash: outcome.cashDelta), state: &state) }
        CrimeSystem.applyLegalImpact(outcome.impact, state: &state)
        state.clamp()
        record(headline: outcome.headline, detail: outcome.detail, deltas: DeltaSummary(cash: outcome.cashDelta))
        commit()
        return lastOutcome
    }

    @discardableResult
    private func applyCooperationDecision(caseID: String, accept: Bool) -> ActionOutcome? {
        let outcome: CriminalLegalActionOutcome?
        if accept {
            outcome = CriminalLegalSystem.acceptCooperation(caseID: caseID, state: &state)
        } else {
            outcome = CriminalLegalSystem.declineCooperation(caseID: caseID, state: &state)
        }
        guard let outcome else { return nil }
        if outcome.cashDelta != 0 { _ = EffectResolutionSystem.apply(DeltaSummary(cash: outcome.cashDelta), state: &state) }
        CrimeSystem.applyLegalImpact(outcome.impact, state: &state)
        LifeThreadSystem.open(outcome.consequences, state: &state)
        state.clamp()
        record(headline: outcome.headline, detail: outcome.detail, deltas: DeltaSummary(cash: outcome.cashDelta))
        commit()
        return lastOutcome
    }

    @discardableResult
    private func sendOrganizationSupportFromPrison() -> ActionOutcome? {
        guard state.cash >= 200, PrisonSystem.sendOrganizationSupport(state: &state) else { return nil }
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: -200), state: &state)
        state.clamp()
        record(headline: "A message reached the organization", detail: "The support strengthened morale and reminded the crew that your authority still exists outside.", deltas: DeltaSummary(cash: -200))
        commit()
        return lastOutcome
    }

    @discardableResult
    private func issueOrganizationCommand(_ command: PrisonOrganizationCommand, planID: String? = nil) -> ActionOutcome? {
        guard state.prison.isIncarcerated else { return nil }
        let result = PrisonSystem.issueOrganizationCommand(command, planID: planID, state: &state)
        guard !result.bullets.isEmpty else { return nil }
        var cashDelta = result.cashDelta
        var healthDelta = 0
        var crimeReaction = ReactionPassResult()
        if let operation = result.operation {
            cashDelta = operation.payout
            _ = AssetSystem.resolveCriminalKitUse(kitID: operation.kitID, assetIDs: operation.kitAssetIDs, succeeded: operation.succeeded, risk: operation.risk.total, state: &state)
            _ = CrimeSystem.resolveStolenKitUse(kitID: operation.kitID, succeeded: operation.succeeded, risk: operation.risk.total, state: &state)
            _ = CrimeSystem.consumeKitEquipment(kitID: operation.kitID, succeeded: operation.succeeded, state: &state)
            healthDelta = operation.succeeded ? 0 : -2
            let (legalOutcome, reaction) = registerCrimeWithReaction(planID.map { planOperation(for: $0, state: state) } ?? .robbery, risk: operation.risk)
            crimeReaction = reaction
            cashDelta += legalOutcome.cashDelta
            LifeThreadSystem.open(operation.consequences, state: &state)
        }
        _ = EffectResolutionSystem.apply(
            DeltaSummary(cash: cashDelta, health: healthDelta),
            state: &state,
            incomeSource: result.operation == nil ? nil : .enterprise
        )
        state.clamp()
        let detail = result.bullets.joined(separator: " ") + (result.intercepted ? " The organization must now decide how much to trust the line." : "") + (crimeReaction.visibleLines.isEmpty ? "" : " " + crimeReaction.visibleLines.joined(separator: " "))
        record(headline: result.intercepted ? "The prison message was intercepted" : command.title, detail: detail, deltas: DeltaSummary(cash: cashDelta, health: healthDelta), reactionNote: crimeReaction.visibleLines.first, impacts: crimeReaction.impact.map { [$0] } ?? [])
        commit()
        return lastOutcome
    }

    @discardableResult
    private func appointActingLeaderFromPrison(_ specialistID: String) -> ActionOutcome? {
        guard state.prison.canManageGang, state.career.criminalPath?.isOrganization == true else { return nil }
        CrimeSystem.setActingLeader(specialistID, state: &state)
        record(headline: "You named an acting leader", detail: "The organization will use this specialist for outside decisions while you are unavailable.", deltas: DeltaSummary())
        commit()
        return lastOutcome
    }

    // MARK: - Criminal path

    func availableSoloCrimeOperations() -> [CrimeOperationType] {
        guard state.character.age >= 14, !state.isGameOver, state.pendingEvent == nil else { return [] }
        guard !CriminalLegalSystem.isCrimeRestricted(state: state) else { return [] }
        return CrimeSystem.soloOperations.filter { CrimeSystem.canAccess($0, state: state) }
    }

    func criminalCareerSnapshot() -> CriminalCareerSnapshot {
        let path = state.career.criminalPath ?? CriminalPathState()
        let available = availableSoloCrimeOperations()
        let next = available.first
        let blocker: String?
        if state.isGameOver {
            blocker = "The life is over"
        } else if state.pendingEvent != nil {
            blocker = "Resolve the pending event"
        } else if CriminalLegalSystem.isCrimeRestricted(state: state) {
            blocker = "Legal restrictions are active"
        } else if available.isEmpty {
            blocker = state.character.age < 14 ? "Criminal work opens at age 14" : "No starter operation is available"
        } else {
            blocker = nil
        }
        return CriminalCareerSnapshot(
            pathTitle: path.mode.title,
            rankTitle: path.rank.title,
            cashFlow: path.cashFlow,
            heat: path.heat,
            notoriety: path.notoriety,
            nextOperation: next,
            blocker: blocker
        )
    }

    func soloCrimeRisk(_ operation: CrimeOperationType) -> CrimeRiskBreakdown {
        let path = state.career.criminalPath ?? CriminalPathState()
        var plan = path.plans.first { $0.operation == operation && $0.assignments.isEmpty }
            ?? CrimePlan(id: "solo-\(operation.rawValue)", operation: operation)
        plan.kitID = path.soloKitID
        return CrimeSystem.risk(for: plan, state: state)
    }

    func canExecuteSoloCrime(_ operation: CrimeOperationType) -> Bool {
        guard state.character.age >= 14, !state.isGameOver, state.pendingEvent == nil else { return false }
        guard CrimeSystem.soloOperations.contains(operation), CrimeSystem.canAccess(operation, state: state) else { return false }
        guard !CriminalLegalSystem.isCrimeRestricted(state: state) else { return false }
        return state.career.criminalPath?.lastSoloCrimeAge[operation.rawValue] != state.character.age
    }

    private func registerCrimeWithReaction(_ operation: CrimeOperationType, risk: CrimeRiskBreakdown) -> (CriminalLegalYearOutcome, ReactionPassResult) {
        let casesBefore = state.legal.cases.count
        let convictionsBefore = state.legal.misdemeanorConvictions
        let legal = CriminalLegalSystem.registerCrime(operation: operation, risk: risk, state: &state)
        let recorded = state.legal.cases.count > casesBefore || state.legal.misdemeanorConvictions > convictionsBefore
        let reaction = ReactionResolver.run(.crime(operation.rawValue, recorded: recorded), state: &state)
        return (legal, reaction)
    }

    @discardableResult
    func executeSoloCrime(_ operation: CrimeOperationType) -> ActionOutcome? {
        guard canExecuteSoloCrime(operation) else { return nil }
        let before = state
        let result = CrimeSystem.executeSolo(operation: operation, state: &state)
        let assetUse = AssetSystem.resolveCriminalKitUse(kitID: result.kitID, assetIDs: result.kitAssetIDs, succeeded: result.succeeded, risk: result.risk.total, state: &state)
        let stolenUse = CrimeSystem.resolveStolenKitUse(kitID: result.kitID, succeeded: result.succeeded, risk: result.risk.total, state: &state)
        let equipmentUsed = CrimeSystem.consumeKitEquipment(kitID: result.kitID, succeeded: result.succeeded, state: &state)
        var deltas = DeltaSummary(cash: result.payout, health: result.healthDelta)
        if operation == .murder { deltas.love -= 2 }
        _ = EffectResolutionSystem.apply(deltas, state: &state, incomeSource: .crime)
        LifeThreadSystem.open(result.consequences, state: &state)
        state.aggregates.soloCrimeAttempts += 1
        if result.succeeded { state.aggregates.soloCrimeSuccesses += 1 }
        let (legalOutcome, reaction) = registerCrimeWithReaction(operation, risk: result.risk)
        if legalOutcome.cashDelta != 0 {
            _ = EffectResolutionSystem.apply(DeltaSummary(cash: legalOutcome.cashDelta), state: &state)
        }
        state.clamp()
        let actualDeltas = DeltaSummary(
            school: state.stats.school - before.stats.school,
            cash: state.cash - before.cash,
            love: state.stats.love - before.stats.love,
            play: state.stats.play - before.stats.play,
            health: state.stats.health - before.stats.health,
            looks: state.stats.looks - before.stats.looks,
            rep: state.stats.rep - before.stats.rep
        )
        let legalDetail = (legalOutcome.bullets + legalOutcome.notes).joined(separator: " ")
        let detail = result.detail + " Risk \(result.risk.total)%." + (legalDetail.isEmpty ? "" : " \(legalDetail)") + (assetUse.map { " \($0.detail)" } ?? "") + (stolenUse.map { " \($0)" } ?? "") + (equipmentUsed > 0 ? " Kit supplies used: $\(equipmentUsed)." : "") + (reaction.visibleLines.isEmpty ? "" : " " + reaction.visibleLines.joined(separator: " "))
        record(headline: result.headline, detail: detail, deltas: actualDeltas, reactionNote: reaction.visibleLines.first, impacts: reaction.impact.map { [$0] } ?? [])
        commit()
        return lastOutcome
    }

    @discardableResult
    func joinExistingGang(name: String = "") -> ActionOutcome? {
        guard !state.isGameOver, state.cash >= CrimeSystem.gangStartupCost else { return nil }
        let before = state
        guard CrimeSystem.joinExistingGang(name: name, state: &state) else { return nil }
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: -CrimeSystem.gangStartupCost), state: &state)
        state.clamp()
        let delta = DeltaSummary(cash: state.cash - before.cash)
        record(headline: "You joined a crew", detail: "The crew provides a network, but your role and control are limited until trust grows.", deltas: delta)
        commit()
        return lastOutcome
    }

    @discardableResult
    private func chooseGangSpecialty(_ specialty: CriminalSpecialty) -> ActionOutcome? {
        guard !state.isGameOver, state.pendingEvent == nil else { return nil }
        guard CrimeSystem.chooseGangSpecialty(specialty, state: &state) else { return nil }
        record(
            headline: "Your gang role was assigned",
            detail: "You are now a \(specialty.title.lowercased()). The role shapes your income, exposure, and future opportunities inside the gang.",
            deltas: DeltaSummary()
        )
        commit()
        return lastOutcome
    }

    @discardableResult
    func performGangSpecialtyWork() -> ActionOutcome? {
        guard !state.isGameOver, state.pendingEvent == nil, !CriminalLegalSystem.isCrimeRestricted(state: state, requiresOrganizationContact: true) else { return nil }
        let before = state
        guard let result = CrimeSystem.performGangSpecialtyWork(state: &state) else { return nil }
        var effects = DeltaSummary(cash: result.payout)
        if !result.succeeded { effects.health = -1 }
        _ = EffectResolutionSystem.apply(effects, state: &state, incomeSource: .crime)
        LifeThreadSystem.open(result.consequences, state: &state)
        let (legalOutcome, reaction) = registerCrimeWithReaction(.smuggling, risk: result.risk)
        if legalOutcome.cashDelta != 0 {
            _ = EffectResolutionSystem.apply(DeltaSummary(cash: legalOutcome.cashDelta), state: &state)
        }
        state.clamp()
        let delta = DeltaSummary(
            cash: state.cash - before.cash,
            health: state.stats.health - before.stats.health
        )
        let legalDetail = (legalOutcome.bullets + legalOutcome.notes).joined(separator: " ")
        record(
            headline: result.headline,
            detail: result.detail + " Risk \(result.risk.total)%." + (legalDetail.isEmpty ? "" : " \(legalDetail)") + (reaction.visibleLines.isEmpty ? "" : " " + reaction.visibleLines.joined(separator: " ")),
            deltas: delta,
            reactionNote: reaction.visibleLines.first,
            impacts: reaction.impact.map { [$0] } ?? []
        )
        commit()
        return lastOutcome
    }

    @discardableResult
    func startDrugEnterprise() -> ActionOutcome? {
        let setupCost = 3_000
        guard !state.isGameOver, state.pendingEvent == nil, state.cash >= setupCost,
              CrimeSystem.startDrugEnterprise(state: &state) else { return nil }
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: -setupCost), state: &state)
        record(headline: "The drug enterprise opened", detail: "The Diamond organization now has an optional drug branch. Management, staffing, and exposure are yours to balance.", deltas: DeltaSummary(cash: -setupCost))
        commit()
        return lastOutcome
    }

    @discardableResult
    func recruitDrugEnterpriseRole(_ role: DrugEnterpriseRole) -> ActionOutcome? {
        guard let path = state.career.criminalPath,
              let enterprise = path.drugEnterprise,
              enterprise.active,
              state.cash >= role.cost,
              CrimeSystem.recruitDrugEnterpriseRole(role, state: &state) else { return nil }
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: -role.cost), state: &state)
        record(headline: "The network gained \(role.title.lowercased())", detail: "The new role improved the enterprise's capacity, but also added another point of failure.", deltas: DeltaSummary(cash: -role.cost))
        commit()
        return lastOutcome
    }

    @discardableResult
    func improveDrugFormula() -> ActionOutcome? {
        guard state.cash >= 500, CrimeSystem.improveDrugFormula(state: &state) else { return nil }
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: -500), state: &state)
        record(headline: "The product formula improved", detail: "Quality and demand rose, along with the enterprise's visibility.", deltas: DeltaSummary(cash: -500))
        commit()
        return lastOutcome
    }

    @discardableResult
    func manageDrugEnterprise() -> ActionOutcome? {
        guard !state.isGameOver, state.pendingEvent == nil, !CriminalLegalSystem.isCrimeRestricted(state: state, requiresOrganizationContact: true) else { return nil }
        let before = state
        guard let result = CrimeSystem.manageDrugEnterprise(state: &state) else { return nil }
        _ = EffectResolutionSystem.apply(
            DeltaSummary(cash: result.payout, love: result.relationshipsDelta, health: result.healthDelta, rep: result.repDelta),
            state: &state,
            incomeSource: .enterprise
        )
        LifeThreadSystem.open(result.consequences, state: &state)
        let (legalOutcome, reaction) = registerCrimeWithReaction(.smuggling, risk: result.risk)
        if legalOutcome.cashDelta != 0 {
            _ = EffectResolutionSystem.apply(DeltaSummary(cash: legalOutcome.cashDelta), state: &state)
        }
        state.clamp()
        let delta = DeltaSummary(cash: state.cash - before.cash, love: state.stats.love - before.stats.love, health: state.stats.health - before.stats.health, rep: state.stats.rep - before.stats.rep)
        let legalDetail = (legalOutcome.bullets + legalOutcome.notes).joined(separator: " ")
        record(headline: result.headline, detail: result.detail + " Risk \(result.risk.total)%." + (legalDetail.isEmpty ? "" : " \(legalDetail)") + (reaction.visibleLines.isEmpty ? "" : " " + reaction.visibleLines.joined(separator: " ")), deltas: delta, reactionNote: reaction.visibleLines.first, impacts: reaction.impact.map { [$0] } ?? [])
        commit()
        return lastOutcome
    }

    @discardableResult
    func startCriminalOrganization(name: String = "") -> ActionOutcome? {
        guard !state.isGameOver, state.cash >= CrimeSystem.organizationStartupCost else { return nil }
        let before = state
        guard CrimeSystem.startIndependentOrganization(name: name, state: &state) else { return nil }
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: -CrimeSystem.organizationStartupCost), state: &state)
        state.clamp()
        let delta = DeltaSummary(cash: state.cash - before.cash)
        record(headline: "Your organization took shape", detail: "The existing criminal path has a leadership structure, specialists, plans, and room to grow.", deltas: delta)
        commit()
        return lastOutcome
    }

    @discardableResult
    func promoteCriminalPathToLeader() -> ActionOutcome? {
        guard CrimeSystem.promoteToLeader(state: &state) else { return nil }
        record(headline: "You inherited the organization", detail: "The gang's existing members, infrastructure, relationships, and plans now answer to you.", deltas: DeltaSummary())
        commit()
        return lastOutcome
    }

    private func saveCrimePlan(_ operation: CrimeOperationType) {
        guard !CriminalLegalSystem.isCrimeRestricted(state: state, requiresOrganizationContact: true) else { return }
        guard CrimeSystem.createPlan(operation: operation, state: &state) != nil else { return }
        state.clamp(); commit()
    }

    func crimePlanRisk(_ plan: CrimePlan) -> CrimeRiskBreakdown {
        CrimeSystem.risk(for: plan, state: state)
    }

    @discardableResult
    private func setCrimePlanApproach(planID: String, approach: CrimeApproach) -> Bool {
        let changed = CrimeSystem.setPlanApproach(planID: planID, approach: approach, state: &state)
        if changed { state.clamp(); commit() }
        return changed
    }

    @discardableResult
    func prepareCrimePlan(_ planID: String) -> ActionOutcome? {
        guard !state.isGameOver, state.pendingEvent == nil,
              !CriminalLegalSystem.isCrimeRestricted(state: state, requiresOrganizationContact: true),
              let cost = CrimeSystem.preparePlan(planID: planID, state: &state) else { return nil }
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: -cost), state: &state)
        let risk = state.career.criminalPath?.plans.first(where: { $0.id == planID }).map { CrimeSystem.risk(for: $0, state: state).total } ?? 0
        record(headline: "The operation was prepared", detail: "Preparation cost $\(cost) and brought projected risk to \(risk)%.", deltas: DeltaSummary(cash: -cost))
        commit()
        return lastOutcome
    }

    @discardableResult
    private func createCriminalKit(name: String = "") -> CriminalKit? {
        guard state.pendingEvent == nil, !state.isGameOver else { return nil }
        let kit = CrimeSystem.createCustomKit(name: name, state: &state)
        if kit != nil { state.clamp(); commit() }
        return kit
    }

    @discardableResult
    private func setCriminalKitAssets(kitID: String, personalAssetIDs: [UInt64], stolenAssetIDs: [UInt64] = []) -> Bool {
        let changed = CrimeSystem.setCustomKitAssets(kitID: kitID, personalAssetIDs: personalAssetIDs, stolenAssetIDs: stolenAssetIDs, state: &state)
        if changed { state.clamp(); commit() }
        return changed
    }

    @discardableResult
    func recoverStolenAsset(_ id: UInt64) -> ActionOutcome? {
        guard !state.isGameOver, state.pendingEvent == nil, let value = CrimeSystem.recoverStolenAsset(id: id, state: &state) else { return nil }
        let before = state.cash
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: value), state: &state)
        record(headline: "Stolen value moved", detail: "The item left criminal inventory and returned a limited cash recovery.", deltas: DeltaSummary(cash: state.cash - before))
        commit()
        return lastOutcome
    }

    @discardableResult
    func convertStolenAsset(_ id: UInt64, route: CriminalAssetConversionRoute) -> ActionOutcome? {
        guard !state.isGameOver, state.pendingEvent == nil, let value = CrimeSystem.convertStolenAsset(id: id, route: route, state: &state) else { return nil }
        let before = state.cash
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: value), state: &state)
        record(headline: "Criminal inventory converted", detail: "The item moved through a controlled resale channel for $\(value).", deltas: DeltaSummary(cash: state.cash - before))
        commit()
        return lastOutcome
    }

    @discardableResult
    func purchaseCriminalKitEquipment(kitID: String, amount: Int = 1_000) -> ActionOutcome? {
        guard !state.isGameOver, state.pendingEvent == nil, let spent = CrimeSystem.purchaseKitEquipment(kitID: kitID, amount: amount, state: &state) else { return nil }
        let before = state.cash
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: -spent), state: &state)
        record(headline: "Kit supplies acquired", detail: "The operation kit gained $\(spent) of consumable support.", deltas: DeltaSummary(cash: state.cash - before))
        commit()
        return lastOutcome
    }

    @discardableResult
    private func setSoloCriminalKit(kitID: String?) -> Bool {
        let changed = CrimeSystem.setSoloKit(kitID: kitID, state: &state)
        if changed { state.clamp(); commit() }
        return changed
    }

    @discardableResult
    private func assignCriminalKit(planID: String, kitID: String?) -> Bool {
        let changed = CrimeSystem.assignKitToPlan(planID: planID, kitID: kitID, state: &state)
        if changed { state.clamp(); commit() }
        return changed
    }

    @discardableResult
    func executeCrimePlan(_ planID: String) -> ActionOutcome? {
        guard !state.isGameOver, state.pendingEvent == nil, !CriminalLegalSystem.isCrimeRestricted(state: state, requiresOrganizationContact: true) else { return nil }
        let before = state
        guard let result = CrimeSystem.executePlan(id: planID, state: &state) else { return nil }
        let assetUse = AssetSystem.resolveCriminalKitUse(kitID: result.kitID, assetIDs: result.kitAssetIDs, succeeded: result.succeeded, risk: result.risk.total, state: &state)
        let stolenUse = CrimeSystem.resolveStolenKitUse(kitID: result.kitID, succeeded: result.succeeded, risk: result.risk.total, state: &state)
        let equipmentUsed = CrimeSystem.consumeKitEquipment(kitID: result.kitID, succeeded: result.succeeded, state: &state)
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: result.payout, health: result.healthDelta), state: &state, incomeSource: .crime)
        let (legalOutcome, reaction) = registerCrimeWithReaction(planOperation(for: planID, state: state), risk: result.risk)
        if legalOutcome.cashDelta != 0 {
            _ = EffectResolutionSystem.apply(DeltaSummary(cash: legalOutcome.cashDelta), state: &state)
        }
        LifeThreadSystem.open(result.consequences, state: &state)
        state.clamp()
        let delta = DeltaSummary(cash: state.cash - before.cash, health: state.stats.health - before.stats.health)
        let legalDetail = (legalOutcome.bullets + legalOutcome.notes).joined(separator: " ")
        record(headline: result.headline, detail: result.detail + " Risk \(result.risk.total)%." + (legalDetail.isEmpty ? "" : " \(legalDetail)") + (assetUse.map { " \($0.detail)" } ?? "") + (stolenUse.map { " \($0)" } ?? "") + (equipmentUsed > 0 ? " Kit supplies used: $\(equipmentUsed)." : "") + (reaction.visibleLines.isEmpty ? "" : " " + reaction.visibleLines.joined(separator: " ")), deltas: delta, reactionNote: reaction.visibleLines.first, impacts: reaction.impact.map { [$0] } ?? [])
        commit()
        return lastOutcome
    }

    @discardableResult
    func delegateCriminalTask(to specialistID: String, operation: CrimeOperationType = .robbery) -> ActionOutcome? {
        guard !state.isGameOver, state.pendingEvent == nil, !CriminalLegalSystem.isCrimeRestricted(state: state, requiresOrganizationContact: true) else { return nil }
        let before = state
        guard let result = CrimeSystem.delegateIndividualTask(specialistID: specialistID, operation: operation, state: &state) else { return nil }
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: result.payout, health: result.healthDelta), state: &state, incomeSource: .crime)
        state.clamp()
        let delta = DeltaSummary(cash: state.cash - before.cash, health: state.stats.health - before.stats.health)
        record(headline: result.headline, detail: result.detail + " Risk \(result.risk.total)%.", deltas: delta)
        commit()
        return lastOutcome
    }

    @discardableResult
    func buildSpecialistRelationship(_ specialistID: String) -> ActionOutcome? {
        guard CrimeSystem.buildSpecialistRelationship(specialistID, state: &state) else { return nil }
        record(headline: "The relationship deepened", detail: "Time with the specialist revealed more about their capabilities and loyalties.", deltas: DeltaSummary())
        commit()
        return lastOutcome
    }

    @discardableResult
    func rewardSpecialist(_ specialistID: String) -> ActionOutcome? {
        guard state.cash >= 500, CrimeSystem.rewardSpecialist(specialistID, state: &state) else { return nil }
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: -500), state: &state)
        record(headline: "The specialist was rewarded", detail: "The payment reinforced loyalty and organization morale.", deltas: DeltaSummary(cash: -500))
        commit()
        return lastOutcome
    }

    @discardableResult
    func negotiateWithRival(_ rivalID: String) -> ActionOutcome? {
        guard CrimeSystem.negotiateWithRival(rivalID, state: &state) else { return nil }
        record(headline: "A rival accepted de-escalation", detail: "The relationship improved and immediate retaliation pressure eased.", deltas: DeltaSummary())
        commit()
        return lastOutcome
    }

    @discardableResult
    func attackRival(_ rivalID: String) -> ActionOutcome? {
        guard let result = CrimeSystem.attackRival(rivalID, state: &state) else { return nil }
        state.clamp()
        record(headline: result.headline, detail: result.detail + " Risk \(result.risk.total)%.", deltas: DeltaSummary())
        commit()
        return lastOutcome
    }

    private func planOperation(for planID: String, state: LifeState) -> CrimeOperationType {
        state.career.criminalPath?.plans.first(where: { $0.id == planID })?.operation ?? .robbery
    }

    private func acquireCriminalSafehouse() {
        CrimeSystem.acquireSafehouse(name: "Back-room safehouse", state: &state)
        state.clamp(); commit()
    }

    private func acquireCriminalFrontBusiness() {
        CrimeSystem.acquireFrontBusiness(name: "Cash business", state: &state)
        state.clamp(); commit()
    }

    private func investInCriminalEquipment() {
        guard state.cash >= 1_000 else { return }
        CrimeSystem.investInEquipment(state: &state)
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: -1_000), state: &state)
        state.clamp(); commit()
    }

    private func upgradeCriminalSafehouse() {
        guard state.cash >= 750 else { return }
        CrimeSystem.upgradeSafehouse(state: &state)
        _ = EffectResolutionSystem.apply(DeltaSummary(cash: -750), state: &state)
        state.clamp(); commit()
    }

    func availableActions(in domain: Domain) -> [DomainAction] {
        if let cached = actionCache[domain] { return cached }
        let actions = DomainActionRegistry.actions(in: domain).filter { availability(for: $0) == .available }
        actionCache[domain] = actions
        return actions
    }

    /// Chapter-relevant actions for the UI. Hard requirements remain readable as
    /// locks, while mutually exclusive systems stay hibernated off the surface.
    func visibleActions(in domain: Domain) -> [DomainAction] {
        DomainActionRegistry.visibleActions(in: domain, state: state)
    }

    func suggestedActions(in domain: Domain, focus: PersonReference? = nil) -> [ActionSuggestion] {
        SuggestedActionSystem.suggestions(in: domain, state: state, focus: focus) { id in
            availability(for: DomainActionRegistry.action(for: id))
        }
    }

    func availability(for request: ActionRequest) -> Availability {
        switch request {
        case .contextual(let id, let target):
            return ContextActionSystem.availability(id, target: target, state: state)
        case .domain(let command):
            guard !state.isGameOver, state.pendingEvent == nil else { return .locked("Finish the current moment first") }
            guard state.recovery == nil else { return .locked("Stabilize your recovery first") }
            switch command {
            case .purchaseAsset(let id):
                guard let listing = AssetCatalog.all.first(where: { $0.id == id }) else { return .locked("Item unavailable") }
                return assetAvailability(for: listing)
            case .soloCrime(let operation):
                return canExecuteSoloCrime(operation) ? .available : .locked("Operation unavailable")
            case .prison:
                return state.prison.isIncarcerated ? .available : .locked("Only available in prison")
            case .venture(let command):
                guard state.career.venture != nil else { return .locked("No active venture") }
                if command == .acceptOffer || command == .declineOffer {
                    guard state.career.venture?.pendingOffer != nil else { return .locked("No offer to resolve") }
                }
                let venture = state.career.venture!
                guard venture.decisionAge != state.character.age || venture.decisionsThisYear < 2 else { return .locked("Two venture decisions already used this year") }
                return .available
            default:
                return .available
            }
        case .registered(let id, let target):
            let action = DomainActionRegistry.action(for: id)
            if let target {
                guard action.domain == .love || action.domain == .play else { return .locked("This action has no person target") }
                switch target {
                case .partner:
                    guard state.partner != nil else { return .locked("This relationship has ended") }
                case .cast(let memberID):
                    guard let member = state.npcs.member(id: memberID) else { return .locked("This person is no longer available") }
                    guard id == .reachOut || (id == .seeFriends && member.role == .friend) else {
                        return .locked("Choose an action for this person")
                    }
                case .family:
                    return .locked("Choose a family action for this person")
                }
            }
            return availability(for: action)
        }
    }

    func choiceAvailability(_ choice: EventChoice, eventID: String) -> Availability {
        FinanceSystem.choiceAvailability(choice, purpose: EventChoiceCoordinator.financialPurpose(choice: choice, eventID: eventID), state: state)
    }

    func availability(for action: DomainAction) -> Availability {
        if state.isGameOver { return .locked("This life has ended") }
        if action.effects.cash.lowerBound < 0 && state.cash < -action.effects.cash.lowerBound
            && action.domain != .health && action.domain != .school {
            return .locked("Requires $\(-action.effects.cash.lowerBound)")
        }
        if state.lifeStage == .adolescence, !DomainActionRegistry.isAdolescenceRelevant(action) {
            return .locked("Available after high school")
        }
        if let reason = action.requirements.unmetReason(in: state) { return .locked(reason) }
        let annualLimit = ActionCadenceSystem.policy(for: action.id).maxPerAge
            + (isRecoveryException(action) ? 2 : 0)
        if state.actionUseCount(for: action.id.rawValue) >= annualLimit {
            return .locked("Spent for this year — Age Up to refresh")
        }
        if let healthEffect = action.domainEffects?.health,
           let reason = ConditionHealthSystem.professionalCareLockReason(
               effect: healthEffect,
               state: state,
               world: WorldSystem.modifiers(for: state.world)
           ) {
            return .locked(reason)
        }
        if let reason = SocialReactivitySystem().lockReason(action: action, state: state),
           ActionCadenceSystem.policy(for: action.id).maxPerAge == 1,
           !isRecoveryException(action) {
            return .locked(reason)
        }
        return .available
    }

    /// Recovery windows allow repeated stabilizing actions until the crisis clears.
    private func isRecoveryException(_ action: DomainAction) -> Bool {
        guard let recovery = state.recovery else { return false }
        switch recovery.kind {
        case .financial: return false
        case .health: return action.id == .rest || action.id == .seekCare || action.id == .exercise
        }
    }

    func pressures(for domain: Domain) -> [DomainPressure] {
        var list = PressureResolver.pressures(for: domain, in: state)
        if domain == .health, state.lifeStage == .legacy || state.mortalityPressure != .stable {
            list.insert(
                DomainPressure(
                    id: "mortality",
                    label: "Mortality",
                    symbol: "heart.circle",
                    level: state.mortalityPressure == .critical ? .high : (state.mortalityPressure == .vulnerable ? .medium : .low),
                    detail: state.mortalityPressure.detail
                ),
                at: 0
            )
            list = Array(list.prefix(4))
        }
        return list
    }

    func whatMatters(limit: Int = 3) -> [WhatMattersItem] {
        WhatMattersResolver.items(for: state, limit: limit)
    }

    func lifeReview() -> LifeReviewModel {
        LifeReviewModel.build(from: state)
    }

    func archiveCompletedLife() {
        LegacyArchiveStore().recordCompleted(state)
    }

    func statusLine() -> String {
        "seed \(state.runSeed) | age \(state.character.age) | \(state.lifeStage.title) | cash $\(state.cash) | \(state.mortalityPressure.rawValue)"
    }

    func worldPreviewLines(for action: DomainAction) -> [String] {
        if action.id == .workShift {
            let gross = EconomyPolicy.rate(EconomyPolicy.salary(state.career), 500)
            return ["Extra work this year: \(MoneyText.exact(gross)) gross", "Estimated tax withheld: \(MoneyText.exact(EconomyPolicy.rate(gross, 2_750)))", "Available once per year"]
        }
        if action.id == .sideHustle { return ["Annual side earnings: $1,500–$4,000 gross", "Estimated tax withheld: 27.5%; reconciled at Age Up", "Available once per year"] }
        if action.id == .budget { return ["Discretionary allowance: $600 this year", "No immediate cash reward; cannot stack"] }

        let policy = WorldSystem.modifiers(for: state.world)
        if let healthEffect = action.domainEffects?.health {
            return ConditionHealthSystem.professionalCarePreview(
                effect: healthEffect,
                state: state,
                world: policy
            )
        }
        if action.id == .jobSearch {
            let chance = CareerSystem.jobSearchChance(state: state, world: policy)
            return ["Hiring chance \(chance)% under the current \(state.world.conditions.macro.rawValue) economy."]
        }
        guard action.category == .money || action.category == .housing || action.category == .career else {
            return []
        }
        let projection = FinanceSystem.projection(state: state, world: policy)
        return [
            "Projected yearly income $\(projection.income)",
            "Projected living and housing costs $\(projection.costs)"
        ]
    }

    func assetAvailability(for listing: AssetListing) -> Availability {
        AssetSystem.availability(for: listing, state: state)
    }

    @discardableResult
    func renameVehicle(ownershipID: UInt64, to name: String) -> VehicleRenameResult {
        guard state.pendingEvent == nil else { return .rejected("Finish the current choice first.") }
        return AssetSystem.renameVehicle(ownershipID: ownershipID, to: name, state: &state)
    }

    @discardableResult
    func clearVehicleName(ownershipID: UInt64) -> Bool {
        guard state.pendingEvent == nil,
              AssetSystem.clearVehicleName(ownershipID: ownershipID, state: &state) else { return false }
        return true
    }

    func vehicleMaintenanceAvailability(_ kind: VehicleMaintenanceKind, ownershipID: UInt64) -> Availability {
        AssetSystem.vehicleMaintenanceAvailability(kind, ownershipID: ownershipID, state: state)
    }

    @discardableResult
    func maintainVehicle(ownershipID: UInt64, kind: VehicleMaintenanceKind) -> ActionOutcome? {
        performAssetManagement(source: "vehicle-maintenance:\(ownershipID):\(kind.rawValue)") { state in
            AssetSystem.maintainVehicle(ownershipID: ownershipID, kind: kind, state: &state)
        }
    }

    func vehicleUpgradeAvailability(_ upgrade: VehicleUpgradeDefinition, ownershipID: UInt64) -> Availability {
        AssetSystem.vehicleUpgradeAvailability(upgrade, ownershipID: ownershipID, state: state)
    }

    @discardableResult
    func upgradeVehicle(ownershipID: UInt64, upgradeID: VehicleUpgradeID) -> ActionOutcome? {
        performAssetManagement(source: "vehicle-upgrade:(ownershipID):(upgradeID.rawValue)") { state in
            AssetSystem.upgradeVehicle(ownershipID: ownershipID, upgradeID: upgradeID, state: &state)
        }
    }

    @discardableResult
    func purchaseAsset(listingID: String) -> ActionOutcome? {
        guard state.pendingEvent == nil else { return nil }
        playtestSource = .assetTransaction("purchase:\(listingID)")
        defer { playtestSource = nil }
        guard let transaction = AssetSystem.purchase(listingID: listingID, state: &state) else { return nil }
        LegalSystem.apply(transaction: transaction, legal: &state.legal)
        record(
            headline: transaction.headline,
            detail: transaction.detail,
            deltas: DeltaSummary(cash: transaction.cashDelta)
        )
        commit()
        return lastOutcome
    }

    func firearmUpgradeAvailability(
        _ upgrade: FirearmUpgradeDefinition,
        ownershipID: UInt64
    ) -> Availability {
        AssetSystem.upgradeAvailability(upgrade, ownershipID: ownershipID, state: state)
    }

    @discardableResult
    func upgradeFirearm(ownershipID: UInt64, upgradeID: FirearmUpgradeID) -> ActionOutcome? {
        guard state.pendingEvent == nil else { return nil }
        playtestSource = .assetTransaction("upgrade:\(ownershipID):\(upgradeID.rawValue)")
        defer { playtestSource = nil }
        guard let transaction = AssetSystem.upgradeFirearm(
            ownershipID: ownershipID,
            upgradeID: upgradeID,
            state: &state
        ) else { return nil }
        LegalSystem.apply(transaction: transaction, legal: &state.legal)
        record(
            headline: transaction.headline,
            detail: transaction.detail,
            deltas: DeltaSummary(cash: transaction.cashDelta)
        )
        commit()
        return lastOutcome
    }

    func firearmManagementAvailability(_ action: FirearmManagementAction, ownershipID: UInt64) -> Availability {
        AssetSystem.firearmManagementAvailability(action, ownershipID: ownershipID, state: state)
    }

    @discardableResult
    func manageFirearm(ownershipID: UInt64, action: FirearmManagementAction) -> ActionOutcome? {
        performAssetManagement(source: "firearm-management:\(ownershipID):\(action.rawValue)") { state in
            AssetSystem.manageFirearm(ownershipID: ownershipID, action: action, state: &state)
        }
    }

    func propertyAmenityAvailability(
        _ amenity: PropertyAmenityDefinition,
        propertyID: UInt64
    ) -> Availability {
        AssetSystem.amenityAvailability(amenity, propertyID: propertyID, state: state)
    }

    @discardableResult
    func installPropertyAmenity(
        propertyID: UInt64,
        amenityID: PropertyAmenityID
    ) -> ActionOutcome? {
        guard state.pendingEvent == nil else { return nil }
        playtestSource = .assetTransaction("property-upgrade:\(propertyID):\(amenityID.rawValue)")
        defer { playtestSource = nil }
        guard let transaction = AssetSystem.installAmenity(
            propertyID: propertyID,
            amenityID: amenityID,
            state: &state
        ) else { return nil }
        record(
            headline: transaction.headline,
            detail: transaction.detail,
            deltas: DeltaSummary(cash: transaction.cashDelta)
        )
        commit()
        return lastOutcome
    }

    func rentalAvailability(propertyID: UInt64) -> Availability {
        AssetSystem.rentalAvailability(propertyID: propertyID, state: state)
    }

    @discardableResult
    func listPropertyForRent(propertyID: UInt64, strategy: RentalStrategy) -> ActionOutcome? {
        performAssetManagement(source: "rental-list:\(propertyID):\(strategy.rawValue)") { state in
            AssetSystem.listPropertyForRent(propertyID: propertyID, strategy: strategy, state: &state)
        }
    }

    @discardableResult
    func changeRentalStrategy(propertyID: UInt64, strategy: RentalStrategy) -> ActionOutcome? {
        performAssetManagement(source: "rental-strategy:\(propertyID):\(strategy.rawValue)") { state in
            AssetSystem.changeRentalStrategy(propertyID: propertyID, strategy: strategy, state: &state)
        }
    }

    @discardableResult
    func withdrawRentalListing(propertyID: UInt64) -> ActionOutcome? {
        performAssetManagement(source: "rental-withdraw:\(propertyID)") { state in
            AssetSystem.withdrawRentalListing(propertyID: propertyID, state: &state)
        }
    }

    func propertyRepairAvailability(_ kind: PropertyRepairKind, propertyID: UInt64) -> Availability {
        AssetSystem.repairAvailability(kind, propertyID: propertyID, state: state)
    }

    @discardableResult
    func performPropertyRepair(propertyID: UInt64, kind: PropertyRepairKind) -> ActionOutcome? {
        performAssetManagement(source: "property-repair:\(propertyID):\(kind.rawValue)") { state in
            AssetSystem.performPropertyRepair(propertyID: propertyID, kind: kind, state: &state)
        }
    }

    @discardableResult
    func sellAsset(ownershipID: UInt64) -> ActionOutcome? {
        guard state.pendingEvent == nil else { return nil }
        let diagnosticCatalogName = state.assets.movableAssets
            .first(where: { $0.id == ownershipID })?
            .name
        playtestSource = .assetTransaction("sale:\(ownershipID)")
        defer { playtestSource = nil }
        guard let transaction = AssetSystem.sell(ownershipID: ownershipID, state: &state) else { return nil }
        record(
            headline: transaction.headline,
            detail: transaction.detail,
            deltas: DeltaSummary(cash: transaction.cashDelta),
            playtestHeadline: diagnosticCatalogName.map { "You Sold \($0)" }
        )
        commit()
        return lastOutcome
    }

    @discardableResult
    func giftAsset(ownershipID: UInt64, recipient: AssetGiftRecipient) -> ActionOutcome? {
        guard state.pendingEvent == nil else { return nil }
        playtestSource = .assetTransaction("asset-gift:\(ownershipID):\(recipient.id)")
        defer { playtestSource = nil }
        guard let outcome = AssetSystem.gift(ownershipID: ownershipID, recipient: recipient, state: &state) else { return nil }
        let person: PersonHandle = switch recipient {
        case .partner: .partner
        case .family(let id): .family(id)
        case .cast(let id): .npc(id)
        }
        let reaction = ReactionResolver.run(.gift(person, value: outcome.reciprocityValue), state: &state)
        record(
            headline: outcome.headline,
            detail: ([outcome.detail] + reaction.visibleLines).joined(separator: " "),
            deltas: DeltaSummary(cash: outcome.cashDelta),
            reactionNote: reaction.visibleLines.first,
            impacts: reaction.impact.map { [$0] } ?? []
        )
        commit()
        return lastOutcome
    }

    @discardableResult
    func consumeAssetReciprocity(recipient: AssetGiftRecipient, requestedValue: Int, eventKey: String) -> AssetReciprocityOutcome? {
        guard state.pendingEvent == nil, !state.isGameOver else { return nil }
        guard let outcome = AssetSystem.consumeReciprocity(recipient: recipient, requestedValue: requestedValue, eventKey: eventKey, state: &state) else { return nil }
        if outcome.cashSupport > 0 {
            _ = FinanceSystem.transact(.init(amount: outcome.cashSupport, purpose: .household), state: &state)
        }
        record(
            headline: "Support Came Through",
            detail: "A prior gift returned $\(outcome.cashSupport) of practical support.",
            deltas: DeltaSummary(cash: outcome.cashSupport, love: outcome.stabilitySupport)
        )
        commit()
        return outcome
    }

    @discardableResult
    func resolveAssetLoss(_ action: AssetLossAction) -> ActionOutcome? {
        guard let event = state.pendingEvent,
              let choiceID: EventChoiceID = switch action {
              case .recoverPrivately: .assetRecover
              case .report: .assetReport
              case .accept: .assetAccept
              },
              event.choices.contains(where: { $0.id == choiceID }) else { return nil }
        execute(choiceID)
        return lastOutcome
    }

    @discardableResult
    private func investigateAssetLoss(_ caseID: UInt64) -> ActionOutcome? {
        guard state.pendingEvent == nil, !state.isGameOver,
              let result = AssetSystem.investigateRecoveryCase(caseID: caseID, state: &state) else { return nil }
        switch result {
        case .recovered(let cash):
            record(headline: "The trail paid off", detail: "The investigation recovered a net $\(cash) after costs.", deltas: DeltaSummary(cash: cash))
        case .cold:
            record(headline: "The trail went cold", detail: "The investigation cost money but did not recover the asset.", deltas: DeltaSummary())
        }
        commit()
        return lastOutcome
    }

    @discardableResult
    private func liquidateAssets(ownershipIDs: [UInt64]) -> ActionOutcome? {
        guard state.pendingEvent == nil, !state.isGameOver else { return nil }
        var sold: [AssetTransaction] = []
        for ownershipID in ownershipIDs {
            if let transaction = AssetSystem.sell(ownershipID: ownershipID, state: &state) {
                sold.append(transaction)
            }
        }
        guard !sold.isEmpty else { return nil }
        let proceeds = sold.reduce(0) { $0 + $1.cashDelta }
        record(
            headline: "Emergency Asset Sale",
            detail: "Sold \(sold.count) movable asset\(sold.count == 1 ? "" : "s") and released $\(proceeds) of cash.",
            deltas: DeltaSummary(cash: proceeds)
        )
        commit()
        return lastOutcome
    }

    func acknowledgeEconomyConversion() {
        state.finance.economy.conversionNotice = false
        commit()
    }

    func saveForLifecycle() {
        saveGeneration &+= 1
        pendingPersistenceRequest?.cancel()
        pendingPersistenceRequest = nil
        let snapshot = state
        let result = persistenceQueue.sync { store.save(snapshot) }
        if case .failure = result {
            saveErrorMessage = "Your latest changes could not be saved. Try again when storage is available."
        } else {
            saveErrorMessage = nil
        }
    }

    /// Destructive reset uses the same serial lane as background saves. Waiting
    /// for older snapshots before clearing prevents an abandoned run from being
    /// recreated by a late queued write.
    func abandonLife() {
        if !state.isGameOver { playtestRecorder.finalize(status: .abandoned, state: state) }
        saveGeneration &+= 1
        pendingPersistenceRequest?.cancel()
        pendingPersistenceRequest = nil
        persistenceQueue.sync { store.clear() }
        saveErrorMessage = nil
    }

    /// Deterministic multi-year helper for tests and debug console.
    func simulate(years: Int, policy: String) -> String {
        var completed = 0
        var safety = years * 8 + 16
        while completed < years && !state.isGameOver && safety > 0 {
            safety -= 1
            if let event = state.pendingEvent, let choice = event.choices.first(where: { choiceAvailability($0, eventID: event.id) == .available }) {
                execute(choice.id)
                continue
            }
            if let recovery = state.recovery {
                let id: ActionID = recovery.kind == .financial ? .workShift : .rest
                if availability(for: DomainActionRegistry.action(for: id)) == .available {
                    execute(id)
                }
                if state.recovery != nil {
                    ageUp() // unresolved recovery ends the life
                    completed += 1
                }
                continue
            }
            let preferredCommand = SimulationPolicySystem.preferredDomainCommand(policy: policy, completedYears: completed, state: state)
            if let preferredCommand {
                _ = execute(.domain(preferredCommand))
            } else if let preferredID = SimulationPolicySystem.preferredAction(
                policy: policy,
                completedYears: completed,
                state: state
            ), availability(for: DomainActionRegistry.action(for: preferredID)) == .available {
                execute(preferredID)
            } else {
                let domain: Domain
                switch policy {
                case "social": domain = .love
                case "survival": domain = .health
                case "grind": domain = state.flags.attendsSchool ? .school : .cash
                default:
                    let cycle: [Domain] = state.flags.attendsSchool
                        ? [.school, .cash, .love, .play, .health]
                        : [.cash, .love, .play, .health, .cash]
                    domain = cycle[completed % cycle.count]
                }
                if let action = availableActions(in: domain).first {
                    execute(action.id)
                } else if let any = Domain.allCases.compactMap({ availableActions(in: $0).first }).first {
                    execute(any.id)
                }
            }
            var choiceSafety = 3
            while choiceSafety > 0,
                  let event = state.pendingEvent,
                  let choice = event.choices.first(where: { choiceAvailability($0, eventID: event.id) == .available }) {
                choiceSafety -= 1
                execute(choice.id)
            }
            if state.pendingEvent != nil { break }
            ageUp()
            completed += 1
        }
        var finalChoiceSafety = 3
        while !state.isGameOver, finalChoiceSafety > 0,
              let event = state.pendingEvent,
              let choice = event.choices.first(where: { choiceAvailability($0, eventID: event.id) == .available }) {
            finalChoiceSafety -= 1
            execute(choice.id)
        }
        let relationship = state.partner.map { "partner \($0.name), bond \($0.bond)" } ?? "no partner"
        return "simulate \(policy): \(completed)y, \(relationship), \(statusLine())"
    }

    func markLongPressSeen() {
        guard !state.flags.seenLongPressHint else { return }
        state.flags.seenLongPressHint = true
        saveForLifecycle()
    }

    // MARK: - Instant execute

    /// Resolves an action and publishes its complete result on the calling turn.
    /// Persistence is queued only after the outcome exists, so storage latency
    /// never sits between a player's tap and visible feedback.
    @discardableResult
    func execute(_ actionID: ActionID) -> ActionOutcome? {
        execute(.registered(actionID))
    }

    @discardableResult
    func execute(_ request: ActionRequest) -> ActionOutcome? {
        guard availability(for: request) == .available else { return nil }
        switch request {
        case .registered(let id, let target):
            return executeRegistered(id, target: target)
        case .domain(let command):
            return executeDomainCommand(command)
        case .contextual(let id, let target):
            let before = state
            guard let resolution = ContextActionSystem.resolve(id, target: target, state: &state) else { return nil }
            playtestSource = .contextual(id)
            record(
                headline: resolution.headline,
                detail: resolution.detail,
                deltas: resolution.deltas,
                impacts: resolution.impacts,
                actionKey: request.key
            )
            playtestSource = nil
            if before != state { commit() }
            return lastOutcome
        }
    }

    private func executeDomainCommand(_ command: DomainCommandRequest) -> ActionOutcome? {
        switch command {
        case .purchaseAsset(let id): return purchaseAsset(listingID: id)
        case .sellAsset(let id): return sellAsset(ownershipID: id)
        case .giftAsset(let id, let recipient): return giftAsset(ownershipID: id, recipient: recipient)
        case .maintainVehicle(let id, let kind): return maintainVehicle(ownershipID: id, kind: kind)
        case .upgradeVehicle(let id, let upgrade): return upgradeVehicle(ownershipID: id, upgradeID: upgrade)
        case .upgradeFirearm(let id, let upgrade): return upgradeFirearm(ownershipID: id, upgradeID: upgrade)
        case .manageFirearm(let id, let action): return manageFirearm(ownershipID: id, action: action)
        case .installAmenity(let id, let amenity): return installPropertyAmenity(propertyID: id, amenityID: amenity)
        case .rentProperty(let id, let strategy): return listPropertyForRent(propertyID: id, strategy: strategy)
        case .changeRentalStrategy(let id, let strategy): return changeRentalStrategy(propertyID: id, strategy: strategy)
        case .withdrawRental(let id): return withdrawRentalListing(propertyID: id)
        case .repairProperty(let id, let kind): return performPropertyRepair(propertyID: id, kind: kind)
        case .investigateAssetLoss(let id): return investigateAssetLoss(id)
        case .liquidateAssets(let ids): return liquidateAssets(ownershipIDs: ids)
        case .soloCrime(let operation): return executeSoloCrime(operation)
        case .joinGang: return joinExistingGang()
        case .workGangSpecialty: return performGangSpecialtyWork()
        case .startDrugEnterprise: return startDrugEnterprise()
        case .improveDrugFormula: return improveDrugFormula()
        case .manageDrugEnterprise: return manageDrugEnterprise()
        case .recruitDrugEnterpriseRole(let role): return recruitDrugEnterpriseRole(role)
        case .startOrganization: return startCriminalOrganization()
        case .promoteCriminalLeader: return promoteCriminalPathToLeader()
        case .prepareCrimePlan(let id): return prepareCrimePlan(id)
        case .executeCrimePlan(let id): return executeCrimePlan(id)
        case .delegateCrime(let id, let operation): return delegateCriminalTask(to: id, operation: operation)
        case .recoverStolenAsset(let id): return recoverStolenAsset(id)
        case .convertStolenAsset(let id, let route): return convertStolenAsset(id, route: route)
        case .purchaseKitEquipment(let id, let amount): return purchaseCriminalKitEquipment(kitID: id, amount: amount)
        case .saveCrimePlan(let operation): saveCrimePlan(operation); return nil
        case .setCrimePlanApproach(let id, let approach): _ = setCrimePlanApproach(planID: id, approach: approach); return nil
        case .setSoloCriminalKit(let id): _ = setSoloCriminalKit(kitID: id); return nil
        case .assignCriminalKit(let planID, let kitID): _ = assignCriminalKit(planID: planID, kitID: kitID); return nil
        case .setCriminalKitAssets(let kitID, let personalIDs, let stolenIDs):
            _ = setCriminalKitAssets(kitID: kitID, personalAssetIDs: personalIDs, stolenAssetIDs: stolenIDs); return nil
        case .createCriminalKit(let name): _ = createCriminalKit(name: name); return nil
        case .upgradeCriminalSafehouse: upgradeCriminalSafehouse(); return nil
        case .buildSpecialistRelationship(let id): return buildSpecialistRelationship(id)
        case .rewardSpecialist(let id): return rewardSpecialist(id)
        case .negotiateRival(let id): return negotiateWithRival(id)
        case .attackRival(let id): return attackRival(id)
        case .legalPlea(let id): return acceptLegalPlea(id)
        case .legalTrial(let id): return takeLegalCaseToTrial(id)
        case .legalAppeal(let id): return appealLegalCase(id)
        case .legalBail(let id): return postLegalBail(id)
        case .legalDetention(let id): return acceptLegalDetention(id)
        case .supervisedRelease(let id): return requestSupervisedRelease(id)
        case .pretrialViolation(let id): return resolvePretrialViolation(id)
        case .legalCooperation(let id, let accept):
            return accept ? acceptLegalCooperation(caseID: id) : declineLegalCooperation(caseID: id)

        case .hireDefenseLawyer(let specialty, let forOrganization): return hireDefenseLawyer(specialty, forOrganization: forOrganization)
        case .threatenEnterpriseSpecialist(let caseID, let targetID):
            return applyEnterpriseLegalAction(.threaten, caseID: caseID, targetID: targetID)
        case .enterpriseLegal(let caseID, let targetID, let action): return applyEnterpriseLegalAction(action, caseID: caseID, targetID: targetID)
        case .prison(let action, let target): return performPrisonAction(action, targetID: target)
        case .prisonSupport: return sendOrganizationSupportFromPrison()
        case .prisonCommand(let command, let planID): return issueOrganizationCommand(command, planID: planID)
        case .appointActingLeader(let id): return appointActingLeaderFromPrison(id)
        case .venture(let command): return executeVentureCommand(command)
        case .chooseGangSpecialty(let specialty): return chooseGangSpecialty(specialty)
        case .assignDefenseLawyer(let lawyer, let caseID): return assignDefenseLawyer(lawyer, to: caseID)
        case .prisonInformant(let accept):
            if accept { acceptPrisonInformantOffer() } else { deferPrisonInformantOffer() }
            return nil
        case .acquireCriminalSafehouse: acquireCriminalSafehouse(); return nil
        case .acquireCriminalFrontBusiness: acquireCriminalFrontBusiness(); return nil
        case .investCriminalEquipment: investInCriminalEquipment(); return nil
        case .renameVehicle(let id, let name):
            guard case .renamed = renameVehicle(ownershipID: id, to: name) else { return nil }
            record(headline: "Vehicle Name Saved", detail: "The vehicle now carries the name you chose.", deltas: DeltaSummary(), actionKey: "vehicle.rename")
            commit(); return lastOutcome
        case .clearVehicleName(let id):
            guard clearVehicleName(ownershipID: id) else { return nil }
            record(headline: "Vehicle Name Cleared", detail: "The original vehicle listing name is back.", deltas: DeltaSummary(), actionKey: "vehicle.rename.clear")
            commit(); return lastOutcome
        }
    }

    private func executeVentureCommand(_ command: VentureCommand) -> ActionOutcome? {
        guard var venture = state.career.venture else { return nil }
        let beforeCash = state.cash
        let result = VentureSystem.decide(command, venture: &venture, age: state.character.age)
        guard let result else { return nil }
        state.career.venture = venture
        var deltas = DeltaSummary(health: result.health)
        if command == .acceptOffer {
            let amount = venture.companyCash
            _ = FinanceSystem.transact(.init(amount: amount, purpose: .income, incomeSource: .enterprise), state: &state)
            deltas.cash = state.cash - beforeCash
        }
        if result.relationship != 0, var partner = state.partner {
            partner.bond += result.relationship; partner.clamp(); state.partner = partner
        }
        record(headline: result.headline, detail: result.detail, deltas: deltas, actionKey: "venture.\(String(describing: command))")
        commit()
        return lastOutcome
    }

    @discardableResult
    private func executeRegistered(_ actionID: ActionID, target: PersonReference?) -> ActionOutcome? {
        let signpostID = OSSignpostID(log: Self.performanceLog)
        os_signpost(
            .begin,
            log: Self.performanceLog,
            name: "Instant Action",
            signpostID: signpostID,
            "action=%{public}@",
            actionID.rawValue as NSString
        )
        defer {
            os_signpost(
                .end,
                log: Self.performanceLog,
                name: "Instant Action",
                signpostID: signpostID
            )
        }

        guard state.pendingEvent == nil else { return nil }
        let action = DomainActionRegistry.action(for: actionID)
        guard availability(for: .registered(actionID, target: target)) == .available else { return nil }
        playtestSource = .action(actionID)
        defer { playtestSource = nil }
        let resolution = InstantActionCoordinator.resolve(action: action, target: target, state: &state)
        if let note = resolution.recoveryNote {
            record(headline: "Recovery Stabilized", detail: note, deltas: DeltaSummary())
        }
        record(
            headline: resolution.headline,
            detail: resolution.detail,
            deltas: resolution.deltas,
            reactionNote: resolution.reactionNote,
            personalityContext: resolution.personalityContext,
            impacts: resolution.impacts,
            actionKey: actionID.rawValue
        )
        state.pendingEvent = resolution.pendingEvent
        commit()
        return lastOutcome
    }

    func execute(_ choiceID: EventChoiceID) {
        guard let event = state.pendingEvent, let choice = event.choices.first(where: { $0.id == choiceID }) else { return }
        guard choiceAvailability(choice, eventID: event.id) == .available else { return }
        playtestSource = .choice(eventID: event.id, choiceID: choiceID)
        defer { playtestSource = nil }
        let resolution = EventChoiceCoordinator.resolve(choice: choice, event: event, state: &state)
        if event.kind == .yearly {
            state.yearChoicesResolved = min(2, state.yearChoicesResolved + 1)
            if state.yearChoicesResolved >= 2 {
                state.queuedYearEvents = []
            }
        }
        record(
            headline: resolution.headline,
            detail: resolution.detail,
            deltas: resolution.deltas,
            isYearly: resolution.isYearly,
            yearSummary: resolution.yearSummary,
            reactionNote: resolution.reactionNote,
            impacts: resolution.impacts
        )
        if event.kind == .yearly, state.yearChoicesResolved < 2, state.pendingEvent == nil {
            advanceYearEventQueue()
        }
        commit()
    }

    private func advanceYearEventQueue() {
        while !state.queuedYearEvents.isEmpty {
            let candidate = state.queuedYearEvents.removeFirst()
            guard YearMomentQueueSystem.isStillRelevant(candidate, state: state),
                  candidate.choices.contains(where: { choiceAvailability($0, eventID: candidate.id) == .available }) else { continue }
            let updated = PresentedEvent(
                id: candidate.id,
                headline: candidate.headline,
                detail: candidate.detail,
                choices: candidate.choices,
                yearDeltas: state.lastYearSummary?.deltas ?? candidate.yearDeltas,
                isPartnerEvent: candidate.isPartnerEvent,
                kind: .yearly
            )
            state.pendingEvent = updated
            state.rememberEvent(updated.id)
            if var summary = state.lastYearSummary {
                var developments = summary.bullets
                if !developments.contains(summary.headline) { developments.append(summary.headline) }
                if !developments.contains(updated.headline) { developments.append(updated.headline) }
                summary.bullets = developments
                state.lastYearSummary = summary
            }
            return
        }
    }

    // MARK: - Age Up (sole yearly mutation path)

    func ageUp() {
        let signpostID = OSSignpostID(log: Self.performanceLog)
        os_signpost(.begin, log: Self.performanceLog, name: "Yearly Tick", signpostID: signpostID)
        defer {
            os_signpost(.end, log: Self.performanceLog, name: "Yearly Tick", signpostID: signpostID)
        }
        guard state.pendingEvent == nil, state.queuedYearEvents.isEmpty, !state.isGameOver else { return }
        state.yearChoicesResolved = 0
        playtestSource = .yearly
        defer { playtestSource = nil }

        if state.recovery?.kind == .financial { state.recovery = nil }
        // Health crises retain their existing terminal recovery path.
        if let recovery = state.recovery {
            endLife(
                reason: .unresolvedHealthCrisis,
                detail: "Your \(recovery.kind.rawValue) crisis could not be stabilized."
            )
            return
        }

        let yearStartState = state

        state.character.age += 1
        if !state.flags.seenAgeUpHint { state.flags.seenAgeUpHint = true }
        let reactionMaturityBullets = ReactionResolver.matureYear(state: &state)

        // Sovereign systems (order matters)
        let activeSystems = SystemRegistry.activeSystems(in: state)
        let world = WorldSystem.resolveYear(world: &state.world, age: state.character.age)
        let education = EducationSystem.resolveYear(state: &state)
        LifeThreadSystem.open(education.consequences, state: &state)
        let educationDeltas = EffectResolutionSystem.apply(education.deltas, state: &state)
        var schoolTransitionDeltas = DeltaSummary()
        if let transition = education.graduationTransition {
            CareerSystem.applySchoolTransition(transition.career, state: &state)
            schoolTransitionDeltas = FinanceSystem.applySchoolTransition(transition.finance, state: &state)
        }
        let progression = ProgressionSystem.resolveYear(state: &state)
        let progressionDeltas = EffectResolutionSystem.apply(progression.deltas, state: &state)

        let career = YearlyTickCoordinator.resolveCareer(state: &state, world: world.modifiers, isActive: activeSystems.contains(.career))
        LifeThreadSystem.open(career.consequences, state: &state)
        let careerDeltas = EffectResolutionSystem.apply(career.deltas, state: &state)
        let ventureYear: VentureYearOutcome? = {
            guard activeSystems.contains(.career), var venture = state.career.venture else { return nil }
            let outcome = VentureSystem.resolveYear(venture: &venture, age: state.character.age, talent: state.personality.talent, drive: state.personality.current.drive, riskTolerance: state.personality.current.riskTolerance, policy: world.modifiers)
            state.career.venture = venture
            if let outcome {
                state.stats.health += outcome.health
                if var partner = state.partner { partner.bond += outcome.relationship; partner.clamp(); state.partner = partner }
            }
            return outcome
        }()
        let criminalLegalYear = CriminalLegalSystem.resolveYear(state: &state)
        CrimeSystem.applyLegalImpact(criminalLegalYear.enterpriseImpact, state: &state)
        LifeThreadSystem.open(criminalLegalYear.consequences, state: &state)

        var propertyPreparation = activeSystems.contains(.assets)
            ? AssetSystem.prepareYear(assets: &state.assets, world: world.modifiers, age: state.character.age)
            : PropertyYearPreparation(
                financialSnapshot: AssetSystem.financialSnapshot(assets: state.assets, world: world.modifiers),
                outcome: AssetYearOutcome(),
                event: nil
            )
        let assetSnapshot = propertyPreparation.financialSnapshot
        let finance = activeSystems.contains(.finance)
            ? FinanceSystem.yearlySettlement(
                state: &state,
                world: world.modifiers,
                assets: assetSnapshot
            )
            : SystemYearDeltas()
        LifeThreadSystem.open(finance.consequences, state: &state)
        let assetYear: AssetYearOutcome
        if SystemRegistry.isActive(.assets, in: state) {
            assetYear = AssetSystem.finalizeYear(
                assets: &state.assets,
                receipts: finance.mortgageReceipts,
                age: state.character.age
            )
            _ = FinanceSystem.transact(.init(amount: assetYear.cashSettlement, purpose: .household), state: &state)
            if assetYear.lostPrimary { state.finance.economy.temporaryHousing = true }
            LifeThreadSystem.open(assetYear.consequences, state: &state)
        } else {
            assetYear = AssetYearOutcome()
        }
        propertyPreparation.outcome.bullets += assetYear.bullets
        propertyPreparation.outcome.notes += assetYear.notes
        propertyPreparation.outcome.newlyDelinquent = propertyPreparation.outcome.newlyDelinquent || assetYear.newlyDelinquent
        propertyPreparation.outcome.foreclosedCount += assetYear.foreclosedCount
        propertyPreparation.outcome.consequences += assetYear.consequences
        let combinedAssetYear = propertyPreparation.outcome
        let legalYear: LegalYearOutcome
        if activeSystems.contains(.legal) {
            let exposure = AssetSystem.firearmExposure(assets: state.assets, legal: state.legal)
            legalYear = LegalSystem.resolveYear(
                legal: &state.legal,
                exposure: exposure,
                age: state.character.age
            )
            if let ownershipID = legalYear.confiscatedOwnershipID {
                _ = AssetSystem.confiscate(ownershipID: ownershipID, assets: &state.assets, age: state.character.age)
            }
            if legalYear.completedSupervision {
                LifeThreadSystem.stabilize(kind: .legalTrouble, amount: 6, state: &state)
            }
            LifeThreadSystem.open(legalYear.consequences, state: &state)
        } else {
            legalYear = LegalYearOutcome()
        }
        let prisonYear: PrisonYearOutcome
        if activeSystems.contains(.prison) {
            let servedYear = state.prison.isIncarcerated
            prisonYear = PrisonSystem.resolveYear(state: &state)
            if servedYear { state.aggregates.prisonYearsServed += 1 }
            LifeThreadSystem.open(prisonYear.consequences, state: &state)
            if prisonYear.partnerBondDelta != 0, var partner = state.partner {
                partner.bond += prisonYear.partnerBondDelta
                partner.clamp()
                state.partner = partner
            }
            if prisonYear.familyBondDelta != 0 {
                for index in state.family.contacts.indices {
                    state.family.contacts[index].bond += prisonYear.familyBondDelta
                }
            }
            if prisonYear.childBondDelta != 0 {
                for index in state.family.children.indices {
                    state.family.children[index].bond += prisonYear.childBondDelta
                }
            }
            state.family.clamp()
            _ = EffectResolutionSystem.apply(
                DeltaSummary(cash: prisonYear.cashDelta, health: prisonYear.healthDelta),
                state: &state,
                financialPurpose: .household
            )
        } else {
            prisonYear = PrisonYearOutcome()
        }
        let health = HealthSystem.yearlyDrift(state: &state, world: world.modifiers)
        if let healthConsequence = ConditionHealthSystem.discoverIfNeeded(state: &state, world: world.modifiers) {
            LifeThreadSystem.open([healthConsequence], state: &state)
        }
        var conditions = ConditionHealthSystem.resolveYear(state: &state, world: world.modifiers)
        LifeThreadSystem.open(conditions.consequences, state: &state)
        if let medicalImpact = conditions.medicalImpact {
            let charge = FinanceSystem.applyMedicalImpact(
                medicalImpact,
                state: &state,
                world: world.modifiers
            )
            conditions.bullets.append("Medical debt +$\(charge)")
        }
        let family = FamilySystem.resolveYear(state: &state)
        LifeThreadSystem.open(family.consequences, state: &state)
        let familyDeltas = EffectResolutionSystem.apply(family.deltas, state: &state)
        let threads = LifeThreadSystem.resolveYear(state: &state)
        let personalityChange = PersonalitySystem.resolveYear(profile: &state.personality, age: state.character.age)
        state.aggregates.observe(netWorth: state.netWorth, age: state.character.age)
        state.clamp()

        let baseDeltas = finance.deltas + health.deltas + conditions.deltas + educationDeltas + schoolTransitionDeltas + progressionDeltas + careerDeltas + familyDeltas
        var bullets = ["Age \(state.character.age)", "Stage \(state.lifeStage.title)"]
            + education.bullets + finance.bullets + combinedAssetYear.bullets + legalYear.bullets + criminalLegalYear.bullets + prisonYear.bullets + health.bullets + progression.bullets + career.bullets + family.bullets + conditions.bullets + threads.bullets
        bullets += reactionMaturityBullets
        if let ventureYear { bullets.append("\(ventureYear.headline): \(ventureYear.detail)") }
        if let personalityChange { bullets.append("Personality: \(personalityChange.flag.title)") }

        if prisonYear.killed {
            let summary = YearSummarySystem.compose(
                age: state.character.age,
                headline: "Prison violence ended your life",
                bullets: bullets,
                deltas: baseDeltas,
                stanceTitle: state.momentum.stance.title,
                shapeTitle: state.momentum.shape.title,
                focusNote: nil,
                silenceNote: nil,
                wasQuiet: false,
                mortalityWarning: nil,
                worldNews: world.news
            )
            endLife(reason: .prisonKilling, detail: "A rival found you inside. The institution became the final chapter.", deltas: baseDeltas, summary: summary)
            return
        }

        // Recovery windows
        let financialCrisis = activeSystems.contains(.finance) && FinanceSystem.openFinancialRecoveryIfNeeded(state: &state)
        let healthCrisis = HealthSystem.openHealthRecoveryIfNeeded(state: &state)
        let resolvedSignals = LifeSignalSystem.detect(
            before: yearStartState,
            after: state,
            careerMilestone: career.milestoneHeadline,
            educationMilestone: education.milestoneHeadline,
            financialCrisis: financialCrisis,
            healthCrisis: healthCrisis,
            foreclosedCount: combinedAssetYear.foreclosedCount
        )
        // A player's most recent decision is causal context for this tick.
        // It is deliberately short-lived: older decisions remain in memory
        // for variety and history, but do not keep re-triggering reactions.
        let recentDecisions = state.recentDecisionSignals.filter {
            $0.age >= yearStartState.character.age && $0.age <= state.character.age
        }
        let lifeSignals = (recentDecisions + resolvedSignals).sorted {
            if $0.magnitude == $1.magnitude { return $0.sourceHeadline < $1.sourceHeadline }
            return $0.magnitude > $1.magnitude
        }
        let cast = activeSystems.contains(.social)
            ? DynamicCastSystem.resolveYear(state: &state, signals: lifeSignals)
            : CastYearResolution()
        bullets += cast.bullets

        // Mortality hibernates until late life (after health drift).
        let mortality = activeSystems.contains(.mortality)
            ? MortalitySystem.evaluate(state: &state)
            : MortalityOutcome(pressure: .stable)
        if let warning = mortality.warning {
            bullets.append(warning)
        }

        if mortality.died, let reason = mortality.endReason {
            let snapshot = InfluenceSystem.closeYear(state: &state)
            state.momentum.absorb(snapshot: snapshot)
            let summary = YearSummarySystem.compose(
                age: state.character.age,
                headline: mortality.bullets.first ?? reason.title,
                bullets: bullets + mortality.bullets,
                deltas: baseDeltas,
                stanceTitle: state.momentum.stance.title,
                shapeTitle: state.momentum.shape.title,
                focusNote: InfluenceSystem.focusNote(for: snapshot),
                silenceNote: nil,
                wasQuiet: false,
                mortalityWarning: mortality.warning,
                worldNews: world.news
            )
            state.lastYearSummary = summary
            endLife(reason: reason, detail: MortalitySystem.deathNarrative(reason: reason, state: state), deltas: baseDeltas, summary: summary)
            return
        }

        if financialCrisis || healthCrisis, let recovery = state.recovery {
            let snapshot = InfluenceSystem.closeYear(state: &state)
            state.momentum.absorb(snapshot: snapshot)
            let summary = YearSummarySystem.compose(
                age: state.character.age,
                headline: "Recovery Window",
                bullets: bullets + [
                    recovery.kind == .financial ? "Cash crisis opened" : "Health crisis opened"
                ],
                deltas: baseDeltas,
                stanceTitle: state.momentum.stance.title,
                shapeTitle: state.momentum.shape.title,
                focusNote: InfluenceSystem.focusNote(for: snapshot),
                silenceNote: nil,
                wasQuiet: false,
                mortalityWarning: mortality.warning,
                worldNews: world.news
            )
            state.lastYearSummary = summary
            record(
                headline: "Recovery Window",
                detail: recovery.kind == .financial
                    ? "Work a shift or budget hard before you Age Up again."
                    : "Rest or seek care before you Age Up again.",
                deltas: baseDeltas,
                isYearly: true,
                yearSummary: summary
            )
            commit()
            return
        }

        // Influence is core. Social resolution only wakes for known people.
        let closedSnapshot = InfluenceSystem.closeYear(state: &state)
        let partnerResolution = YearlyTickCoordinator.resolveRelationship(
            state: &state,
            baseDeltas: baseDeltas,
            snapshot: closedSnapshot,
            isActive: activeSystems.contains(.social)
        )
        let familyAppraisal = FamilyAppraisalSystem.resolveYear(
            state: &state,
            snapshot: closedSnapshot
        )
        state.momentum.absorb(snapshot: closedSnapshot)
        let yearDeltas = baseDeltas + partnerResolution.deltas
        let snapshot = closedSnapshot
        let focus = InfluenceSystem.focusNote(for: snapshot)
        bullets += familyAppraisal.bullets

        // Graduation is the adolescence reckoning; it outranks the generic Launch transition.
        if let milestoneHeadline = education.milestoneHeadline,
           !education.graduationOffers.isEmpty {
            let milestoneDetail = education.milestoneDetail ?? milestoneHeadline
            let event = EducationSystem.offerEvent(
                id: "high-school-graduation-\(state.runSeed)",
                headline: milestoneHeadline,
                detail: milestoneDetail,
                offers: education.graduationOffers
            )
            presentYearEvent(
                event,
                yearDeltas: yearDeltas,
                bullets: bullets,
                focus: focus,
                stageTransition: progression.stageTransition?.title,
                mortalityWarning: mortality.warning,
                worldNews: world.news
            )
            return
        }

        if let followUp = education.followUp {
            presentYearEvent(
                EducationSystem.followUpEvent(followUp, state: state),
                yearDeltas: yearDeltas,
                bullets: bullets,
                focus: focus,
                stageTransition: progression.stageTransition?.title,
                mortalityWarning: mortality.warning,
                worldNews: world.news
            )
            return
        }

        if let milestoneHeadline = education.milestoneHeadline {
            let detail = education.milestoneDetail ?? milestoneHeadline
            let event = LifeEvent(
                id: "education-milestone-\(state.character.age)",
                headline: milestoneHeadline,
                detail: detail,
                weight: { _ in 0 },
                choices: [EventChoice(id: .accept, title: "Face what comes next", detail: detail, effects: EffectRange(), partnerEffect: PartnerEffect(), narrative: detail)]
            )
            presentYearEvent(event, yearDeltas: yearDeltas, bullets: bullets, focus: focus, stageTransition: progression.stageTransition?.title, mortalityWarning: mortality.warning, worldNews: world.news)
            return
        }

        // Priority: stage transition → partner event → registry event → mortality warning quiet → silence
        if let stage = progression.stageTransition {
            presentYearEvent(
                ProgressionSystem.stageTransitionEvent(stage),
                yearDeltas: yearDeltas,
                bullets: bullets,
                focus: focus,
                stageTransition: stage.title,
                mortalityWarning: mortality.warning,
                extraHeadline: progression.milestoneHeadline ?? career.milestoneHeadline,
                worldNews: world.news
            )
            return
        }

        if let milestoneHeadline = progression.milestoneHeadline ?? career.milestoneHeadline ?? familyAppraisal.milestoneHeadline {
            let milestoneDetail = progression.milestoneDetail ?? career.milestoneDetail ?? familyAppraisal.milestoneDetail ?? milestoneHeadline
            let event = LifeEvent(
                id: "milestone-\(state.character.age)",
                headline: milestoneHeadline,
                detail: milestoneDetail,
                weight: { _ in 0 },
                choices: [
                    EventChoice(
                        id: .accept,
                        title: "Continue",
                        detail: "Carry this into the next year.",
                        effects: EffectRange(),
                        partnerEffect: PartnerEffect(),
                        narrative: milestoneDetail
                    )
                ]
            )
            presentYearEvent(
                event,
                yearDeltas: yearDeltas,
                bullets: bullets + [milestoneHeadline],
                focus: focus,
                mortalityWarning: mortality.warning,
                worldNews: world.news
            )
            return
        }

        if let partnerEvent = partnerResolution.event {
            presentPartnerEvent(partnerEvent, yearDeltas: yearDeltas, bullets: bullets, focus: focus, mortalityWarning: mortality.warning, worldNews: world.news)
            return
        }

        if let propertyEvent = propertyPreparation.event {
            if propertyEvent.id.hasPrefix("vehicle-") {
                AssetSystem.rememberVehicleEvent(propertyEvent.id, assets: &state.assets)
            } else {
                AssetSystem.rememberPropertyEvent(propertyEvent.id, assets: &state.assets)
            }
            presentYearEvent(propertyEvent, yearDeltas: yearDeltas, bullets: bullets, focus: focus, mortalityWarning: mortality.warning, worldNews: world.news)
            return
        }

        if let event = FamilySituationSystem.select(state: state) {
            presentYearEvent(event, yearDeltas: yearDeltas, bullets: bullets, focus: focus, mortalityWarning: mortality.warning, worldNews: world.news)
            return
        }

        if let event = CastSituationSystem.select(state: &state) {
            presentYearEvent(event, yearDeltas: yearDeltas, bullets: bullets, focus: focus, mortalityWarning: mortality.warning, worldNews: world.news)
            return
        }

        if let event = NarrativeEventSystem.select(state: &state) {
            presentYearEvent(event, yearDeltas: yearDeltas, bullets: bullets, focus: focus, mortalityWarning: mortality.warning, worldNews: world.news)
            return
        }

        // Quiet year with compressed summary (always produces something)
        let silence = SilentYearEngine.note(state: state, snapshot: snapshot, partnerNote: partnerResolution.note)
        let headline: String
        if let worldNews = world.news {
            headline = worldNews.headline
        } else if mortality.warning != nil {
            headline = "A Careful Year"
        } else if partnerResolution.note != nil {
            headline = "Home Felt Different This Year"
        } else {
            headline = "Another Year"
        }
        let summary = YearSummarySystem.compose(
            age: state.character.age,
            headline: headline,
            bullets: Array((bullets + yearDeltas.lines.prefix(3)).prefix(6)),
            deltas: yearDeltas,
            stanceTitle: state.momentum.stance.title,
            shapeTitle: state.momentum.shape.title,
            focusNote: focus,
            silenceNote: world.news == nil ? silence : nil,
            wasQuiet: world.news == nil,
            mortalityWarning: mortality.warning,
            worldNews: world.news
        )
        state.lastYearSummary = summary
        record(
            headline: headline,
            detail: world.news?.detail ?? silence,
            deltas: yearDeltas,
            isYearly: true,
            isSilence: world.news == nil,
            yearSummary: summary
        )
        commit()
    }

    // MARK: - Internals

    private func performAssetManagement(
        source: String,
        operation: (inout LifeState) -> AssetTransaction?
    ) -> ActionOutcome? {
        guard state.pendingEvent == nil else { return nil }
        playtestSource = .assetTransaction(source)
        defer { playtestSource = nil }
        guard let transaction = operation(&state) else { return nil }
        record(
            headline: transaction.headline,
            detail: transaction.detail,
            deltas: DeltaSummary(cash: transaction.cashDelta)
        )
        commit()
        return lastOutcome
    }

    private func presentYearEvent(
        _ event: LifeEvent,
        yearDeltas: DeltaSummary,
        bullets: [String],
        focus: String?,
        stageTransition: String? = nil,
        mortalityWarning: String? = nil,
        extraHeadline: String? = nil,
        worldNews: WorldNews? = nil
    ) {
        let summary = YearSummarySystem.compose(
            age: state.character.age,
            headline: extraHeadline ?? event.headline,
            bullets: Array((bullets + [event.headline] + yearDeltas.lines.prefix(3)).prefix(6)),
            deltas: yearDeltas,
            stanceTitle: state.momentum.stance.title,
            shapeTitle: state.momentum.shape.title,
            focusNote: focus,
            silenceNote: nil,
            wasQuiet: false,
            stageTransition: stageTransition,
            mortalityWarning: mortalityWarning,
            worldNews: worldNews
        )
        state.lastYearSummary = summary
        state.rememberEvent(event.id)
        let flavoredDetail = NarrativeFlavorSystem.compose(detail: event.detail, key: event.id, state: &state)
        state.pendingEvent = PresentedEvent(
            id: event.id, headline: event.headline, detail: flavoredDetail,
            choices: event.choices, yearDeltas: yearDeltas,
            isPartnerEvent: false, kind: .yearly
        )
        enqueueSecondaryYearEvent(excluding: event.id)
        lastOutcome = ActionOutcome(
            headline: extraHeadline ?? event.headline,
            narrative: flavoredDetail,
            deltas: yearDeltas,
            isYearly: true,
            yearSummary: summary
        )
        if let lastOutcome {
            playtestRecorder.record(source: .event(event.id), outcome: lastOutcome, state: state)
        }
        commit()
    }

    private func presentPartnerEvent(
        _ event: PresentedEvent,
        yearDeltas: DeltaSummary,
        bullets: [String],
        focus: String?,
        mortalityWarning: String?,
        worldNews: WorldNews? = nil
    ) {
        let summary = YearSummarySystem.compose(
            age: state.character.age,
            headline: event.headline,
            bullets: Array((bullets + [event.headline] + yearDeltas.lines.prefix(3)).prefix(6)),
            deltas: yearDeltas,
            stanceTitle: state.momentum.stance.title,
            shapeTitle: state.momentum.shape.title,
            focusNote: focus,
            silenceNote: nil,
            wasQuiet: false,
            mortalityWarning: mortalityWarning,
            worldNews: worldNews
        )
        state.lastYearSummary = summary
        state.rememberEvent(event.id)
        var yearlyEvent = event
        yearlyEvent.kind = .yearly
        let flavoredDetail = NarrativeFlavorSystem.compose(detail: yearlyEvent.detail, key: yearlyEvent.id, state: &state)
        state.pendingEvent = PresentedEvent(
            id: yearlyEvent.id, headline: yearlyEvent.headline, detail: flavoredDetail,
            choices: yearlyEvent.choices, yearDeltas: yearDeltas,
            isPartnerEvent: true, kind: .yearly
        )
        enqueueSecondaryYearEvent(excluding: event.id)
        lastOutcome = ActionOutcome(
            headline: event.headline,
            narrative: flavoredDetail,
            deltas: yearDeltas,
            isYearly: true,
            yearSummary: summary
        )
        if let lastOutcome {
            playtestRecorder.record(source: .event(event.id), outcome: lastOutcome, state: state)
        }
        commit()
    }

    private func enqueueSecondaryYearEvent(excluding primaryID: String) {
        guard state.queuedYearEvents.isEmpty,
              !primaryID.hasPrefix("high-school-graduation"),
              !primaryID.hasPrefix("education-") else { return }
        let family = FamilySituationSystem.select(state: state)
        let candidate: LifeEvent?
        if let family, family.id != primaryID {
            candidate = family
        } else if let cast = CastSituationSystem.select(state: &state), cast.id != primaryID {
            candidate = cast
        } else if primaryID.hasPrefix("milestone-") || primaryID.hasPrefix("stage-")
                    || primaryID.hasPrefix("partner-") || primaryID.hasPrefix("property-") {
            candidate = NarrativeEventSystem.select(state: &state).flatMap { $0.id == primaryID ? nil : $0 }
        } else {
            candidate = nil
        }
        guard let candidate else { return }
        let detail = NarrativeFlavorSystem.compose(detail: candidate.detail, key: candidate.id, state: &state)
        state.queuedYearEvents = [PresentedEvent(
            id: candidate.id,
            headline: candidate.headline,
            detail: detail,
            choices: Array(candidate.choices.prefix(3)),
            yearDeltas: DeltaSummary(),
            isPartnerEvent: false,
            kind: .yearly
        )]
    }

    private func endLife(
        reason: EndReason,
        detail: String,
        deltas: DeltaSummary = DeltaSummary(),
        summary: YearSummary? = nil
    ) {
        state.isGameOver = true
        state.endReason = reason
        state.recovery = nil
        let finalSummary = summary ?? YearSummarySystem.compose(
            age: state.character.age,
            headline: reason.title,
            bullets: ["Age \(state.character.age)", reason.title],
            deltas: deltas,
            stanceTitle: state.momentum.stance.title,
            shapeTitle: state.momentum.shape.title,
            focusNote: nil,
            silenceNote: nil,
            wasQuiet: false
        )
        state.lastYearSummary = finalSummary
        playtestSource = .ending
        record(
            headline: "Life Ended",
            detail: detail,
            deltas: deltas,
            isYearly: true,
            yearSummary: finalSummary
        )
        commit()
        playtestRecorder.finalize(status: .completed, state: state)
    }

    private func record(
        headline: String,
        detail: String,
        deltas: DeltaSummary,
        isYearly: Bool = false,
        isSilence: Bool = false,
        yearSummary: YearSummary? = nil,
        reactionNote: String? = nil,
        personalityContext: String? = nil,
        playtestHeadline: String? = nil,
        impacts: [ActionImpact] = [],
        actionKey: String? = nil
    ) {
        let resolvedDetail = NarrativeFlavorSystem.compose(detail: detail, key: actionKey ?? headline, state: &state)
        state.historySequence &+= 1
        let entry = HistoryEntry(
            id: state.historySequence,
            age: state.character.age,
            headline: headline,
            detail: resolvedDetail,
            deltas: deltas,
            isSilence: isSilence,
            yearSummary: yearSummary
        )
        if LifeTimelineResolver.isMilestone(entry),
           !state.timeline.contains(where: { $0.id == entry.id }) {
            state.timeline.append(
                LifeTimelineEntry(id: entry.id, age: entry.age, headline: entry.headline, detail: entry.detail)
            )
            state.timeline = Array(state.timeline.suffix(32))
        }
        let outcome = ActionOutcome(
            headline: headline,
            narrative: resolvedDetail,
            deltas: deltas,
            isYearly: isYearly,
            yearSummary: yearSummary,
            reactionNote: reactionNote,
            personalityContext: personalityContext,
            severity: OutcomeSignalSystem.severity(for: deltas, isYearly: isYearly, state: state),
            actionKey: actionKey,
            impacts: impacts
        )
        let source = headline.contains("Recovery")
            ? PlaytestSource.recovery
            : (playtestSource ?? .yearly)
        let diagnosticOutcome = playtestHeadline.map {
            ActionOutcome(
                headline: $0,
                narrative: resolvedDetail,
                deltas: deltas,
                isYearly: isYearly,
                yearSummary: yearSummary,
                reactionNote: reactionNote,
                personalityContext: personalityContext,
                severity: outcome.severity,
                actionKey: actionKey,
                impacts: impacts
            )
        } ?? outcome
        playtestRecorder.record(source: source, outcome: diagnosticOutcome, state: state)
        state.history.insert(entry, at: 0)
        state.history = Array(state.history.prefix(40))
        lastOutcome = outcome
    }

    func addPlaytestAnnotation(kind: PlaytestAnnotationKind, note: String) {
        playtestRecorder.annotate(kind: kind, note: note, state: state)
    }

    func setPlaytestStyle(_ style: PlaytestStyle) {
        playtestRecorder.setPlayStyle(style)
    }

    func assessPlaytestOutcome(explanation: String, reviewAgrees: Bool) {
        playtestRecorder.assessOutcome(explanation: explanation, reviewAgrees: reviewAgrees)
    }

    func playtestReport() -> PlaytestRunReport? {
        playtestRecorder.currentReport()
    }

    func playtestExportURLs() -> [URL] {
        playtestRecorder.exportURLs()
    }

    func playtestCohortAnalysis() -> PlaytestCohortAnalysis {
        playtestRecorder.cohortAnalysis()
    }

    func playtestCohortExportURL() -> URL? {
        playtestRecorder.exportCohortURL()
    }

    private func commit() {
        actionCache.removeAll()
        guard store.automaticallyPersistsCommits else {
            pendingPersistenceRequest = nil
            saveErrorMessage = nil
            return
        }
        saveGeneration &+= 1
        let generation = saveGeneration
        let snapshot = state
        let store = store
        pendingPersistenceRequest?.cancel()
        let request = PersistenceRequest()
        pendingPersistenceRequest = request
        persistenceQueue.async { [weak self] in
            guard !request.isCanceled else { return }
            let succeeded: Bool
            if case .success = store.save(snapshot) { succeeded = true } else { succeeded = false }
            DispatchQueue.main.async { [weak self] in
                guard let self, self.saveGeneration == generation else { return }
                self.pendingPersistenceRequest = nil
                self.saveErrorMessage = succeeded
                    ? nil
                    : "Your latest changes could not be saved. Try again when storage is available."
            }
        }
    }
}
