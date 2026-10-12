import Foundation
import Testing
import UIKit
@testable import OneLife

private final class BlockingPersistence: LifePersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var storedSnapshots: [LifeState] = []
    private let firstStarted = DispatchSemaphore(value: 0)
    private let releaseFirst = DispatchSemaphore(value: 0)
    private let secondFinished = DispatchSemaphore(value: 0)

    func save(_ state: LifeState) -> Result<Void, Error> {
        lock.lock()
        storedSnapshots.append(state)
        let ordinal = storedSnapshots.count
        lock.unlock()
        if ordinal == 1 {
            firstStarted.signal()
            _ = releaseFirst.wait(timeout: .now() + 30)
        } else if ordinal == 2 {
            secondFinished.signal()
        }
        return .success(())
    }

    func clear() {
        lock.lock()
        storedSnapshots.removeAll()
        lock.unlock()
    }

    func waitUntilFirstStarts() async -> Bool {
        await wait(for: firstStarted)
    }
    func allowFirstToFinish() { releaseFirst.signal() }
    func waitUntilSecondFinishes() async -> Bool {
        await wait(for: secondFinished)
    }

    private func wait(for semaphore: DispatchSemaphore) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: semaphore.wait(timeout: .now() + 10) == .success)
            }
        }
    }

    var snapshots: [LifeState] {
        lock.lock()
        defer { lock.unlock() }
        return storedSnapshots
    }
}

@MainActor
struct CareerOccupationCatalogTests {
    @Test func passZeroCatalogCoversFourFamiliesWithFourOccupationsEach() {
        #expect(CareerCatalog.definitions.count == 16)
        for track in [CareerTrack.office, .trades, .careService, .freelance] {
            #expect(CareerCatalog.occupations(for: track).count == 4)
            #expect(CareerCatalog.occupations(for: track).allSatisfy { $0.track == track })
        }
    }

    @Test func choosingARegularTrackAssignsAStableCatalogDefault() {
        var state = LifeState(name: "Occupation", seed: 42)
        state.career.level = .unemployed
        _ = CareerSystem.resolve(.chooseTrades, state: &state)
        #expect(state.career.track == .trades)
        #expect(state.career.occupation == nil)
        _ = CareerSystem.resolve(.chooseElectrician, state: &state)
        #expect(state.career.occupation == .electrician)
        #expect(CareerCatalog.definition(for: .electrician).startingSecurity == 70)
    }

    @Test func occupationActionsAreAvailableOnlyForTheChosenFamily() throws {
        var state = LifeState(name: "Occupation actions", seed: 44)
        state.career.track = .office
        let simulator = LifeSimulator(state: state)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .chooseAccountant)) == .available)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .chooseElectrician)) != .available)
        _ = try #require(simulator.execute(.chooseAccountant))
        #expect(simulator.state.career.occupation == .accountant)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .chooseAccountant)) != .available)
    }

    @Test func legacyCareerWithoutOccupationMigratesByTrack() throws {
        var state = LifeState(name: "Legacy occupation", seed: 43)
        state.career.track = .careService
        let encoded = try JSONEncoder().encode(state)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var career = try #require(object["career"] as? [String: Any])
        career.removeValue(forKey: "occupation")
        object["career"] = career
        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder().decode(LifeState.self, from: legacyData)
        #expect(restored.career.occupation == .teacher)
        #expect(restored.career.track == .careService)
    }

    @Test func occupationUsesNamedRanksAndSkillBasedPromotion() {
        var state = LifeState(name: "Career rank", seed: 45)
        state.career.track = .trades
        state.career.occupation = .electrician
        state.career.level = .entry
        state.career.performance = 68
        state.career.skill = 45
        let result = CareerSystem.resolve(.promote, state: &state)
        #expect(state.career.level == .established)
        #expect(state.career.rankTitle == "Licensed Electrician")
        #expect(result.headline == "You Earned The Next Title")
    }

    @Test func credentialGatedSeniorRankCanRequireAnotherAttempt() {
        var state = LifeState(name: "Credentialed career", seed: 46)
        state.career.track = .careService
        state.career.occupation = .nurse
        state.career.level = .established
        state.career.performance = 76
        state.career.skill = 60
        _ = CareerSystem.resolve(.promote, state: &state)
        #expect(state.career.level == .established)
        #expect(state.career.rankTitle == "Charge Nurse")
        state.career.credentialProgress = 35
        _ = CareerSystem.resolve(.promote, state: &state)
        #expect(state.career.level == .senior)
        #expect(state.career.rankTitle == "Nurse Manager")
    }

    @Test func careerManagementActionsCarryVisibleTradeoffs() {
        var state = LifeState(name: "Career management", seed: 47)
        state.cash = 20_000
        state.career.track = .office
        state.career.occupation = .accountant
        state.career.level = .established
        state.career.performance = 70
        state.career.workload = 40
        let startingIncome = state.career.annualIncome
        let startingCash = state.cash

        _ = CareerSystem.resolve(.negotiateRaise, state: &state)
        #expect(state.career.negotiationLeverage == 18)
        #expect(state.career.annualIncome > startingIncome)

        _ = CareerSystem.resolve(.overtime, state: &state)
        #expect(state.cash > startingCash)
        #expect(state.career.workload > 40)
        #expect(state.career.burnout > 10)

        _ = CareerSystem.resolve(.certification, state: &state)
        #expect(state.career.credentialProgress == 20)
        #expect(state.cash < startingCash + 1_000)

        let burnoutBeforeLeave = state.career.burnout
        _ = CareerSystem.resolve(.careerLeave, state: &state)
        #expect(state.career.burnout < burnoutBeforeLeave)
        #expect(state.career.workload < 40)
    }

    @Test func workplaceStateChangesWithoutChangingOccupation() {
        var state = LifeState(name: "Workplace", seed: 48)
        state.career.track = .office
        state.career.occupation = .accountant
        state.career.level = .established
        let occupation = state.career.occupation
        let employer = state.career.workplace.employer

        _ = CareerSystem.resolve(.workplaceRelationship, state: &state)
        #expect(state.career.workplace.managerRelationship > 45)
        #expect(state.career.workplace.coworkerStanding > 45)

        _ = CareerSystem.resolve(.changeEmployer, state: &state)
        #expect(state.career.occupation == occupation)
        #expect(state.career.workplace.employer != employer)
        #expect(state.career.workplace.yearsAtEmployer == 0)
    }

    @Test func flexibleScheduleTradesVisibilityForCapacity() {
        var state = LifeState(name: "Flexibility", seed: 49)
        state.career.track = .office
        state.career.occupation = .accountant
        state.career.level = .established
        state.career.workload = 50
        let performance = state.career.performance
        _ = CareerSystem.resolve(.flexibleSchedule, state: &state)
        #expect(state.career.workplace.flexibility > 25)
        #expect(state.career.workload < 50)
        #expect(state.career.performance < performance)
    }

    @Test func careerMobilityBuildsPortableProof() {
        var state = LifeState(name: "Career mobility", seed: 50)
        state.cash = 5_000
        state.career.track = .office
        state.career.occupation = .accountant
        state.career.level = .established

        _ = CareerSystem.resolve(.buildCareerPortfolio, state: &state)
        #expect(state.career.careerReputation == 12)
        #expect(state.career.skill == 49)
        #expect(state.cash < 5_000)

        _ = CareerSystem.resolve(.requestReference, state: &state)
        #expect(state.career.referenceStrength == 18)
        _ = CareerSystem.resolve(.testJobMarket, state: &state)
        #expect(state.career.negotiationLeverage == 10)
        #expect(state.career.security > 50)
    }

    @Test func careerFocusCreatesDistinctProgressionTradeoffs() {
        var state = LifeState(name: "Career focus", seed: 51)
        state.career.track = .trades
        state.career.occupation = .electrician
        state.career.level = .established
        _ = CareerSystem.resolve(.specializeTechnical, state: &state)
        #expect(state.career.focus == .technicalDepth)
        #expect(state.career.skill > 45)

        let workload = state.career.workload
        _ = CareerSystem.resolve(.specializeLeadership, state: &state)
        #expect(state.career.focus == .peopleLeadership)
        #expect(state.career.mentorship > 0)
        #expect(state.career.workload > workload)
    }

    @Test func benefitsAndPaidLeaveTradeTermsForRecovery() {
        var state = LifeState(name: "Benefits", seed: 52)
        state.career.level = .established
        state.career.burnout = 60
        state.career.workload = 70
        let originalBenefits = state.career.benefits
        _ = CareerSystem.resolve(.negotiateBenefits, state: &state)
        #expect(state.career.benefits > originalBenefits)
        _ = CareerSystem.resolve(.usePaidLeave, state: &state)
        #expect(state.career.paidLeaveDays == 20)
        #expect(state.career.burnout < 60)
        #expect(state.career.workload < 70)
    }

    @Test func lateCareerPlanningBuildsAnExitRamp() {
        var state = LifeState(name: "Retirement planning", seed: 53, startingAge: 58)
        state.career.level = .senior
        _ = CareerSystem.resolve(.prepareRetirement, state: &state)
        #expect(state.career.retirementReadiness == 20)
        #expect(state.career.workload < 20)
    }
}

@MainActor
struct CriminalPathTests {
    private func state(seed: UInt64 = 7, age: Int = 14) -> LifeState {
        LifeState(name: "Criminal", seed: seed, startingAge: age)
    }

    @Test func investigationSpecialistArrestSurvivesLaterCaseConviction() {
        var resolved = false
        for seed in 1...500 where !resolved {
            var state = state(seed: UInt64(seed), age: 35)
            state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader, cashFlow: 200, specialists: CrimeSystem.defaultSpecialists())
            let plannerID = state.career.criminalPath?.specialists.first?.id ?? "planner"
            state.legal.legalRandom = SeededRandom(seed: UInt64(seed))
            state.legal.cases = [
                LegalCaseState(id: "investigation", operation: .fraud, severity: .serious, origin: .enterprise, status: .investigation, evidenceStrength: 100, enterpriseEvidence: 100, investigationVisibility: 100, targets: [LegalTargetState(id: "specialist:\(plannerID)", type: .specialist)]),
                LegalCaseState(id: "trial", operation: .fraud, severity: .serious, origin: .enterprise, status: .trial, evidenceStrength: 100, enterpriseEvidence: 100, trialProgress: 1, convictionIsFelony: true, sentenceYears: 3)
            ]
            let outcome = CriminalLegalSystem.resolveYear(state: &state)
            let arrested = state.career.criminalPath?.specialists.first(where: { $0.id == plannerID })?.isArrested == true
            let convicted = state.legal.cases.first(where: { $0.id == "trial" })?.status == .convicted
            if arrested && convicted {
                #expect(state.career.criminalPath?.cashFlow == 125)
                #expect(state.career.criminalPath?.specialists.first(where: { $0.id == plannerID })?.isArrested == true)
                #expect(outcome.convictedCaseID == "trial")
                resolved = true
            }
        }
        #expect(resolved)
    }

    @Test func soloCrimeIsAvailableFromAdolescenceWithoutGangMembership() {
        let simulator = LifeSimulator(state: state())
        #expect(simulator.availableSoloCrimeOperations() == CrimeSystem.starterOperations)
        #expect(!simulator.availableSoloCrimeOperations().contains(.murder))
        #expect(simulator.state.career.criminalPath == nil)
        #expect(!simulator.canExecuteSoloCrime(.murder))
        #expect(simulator.canExecuteSoloCrime(.burglary))
    }

    @Test func criminalCareerSnapshotSummarizesStarterPathAndBlocker() {
        let simulator = LifeSimulator(state: state(seed: 80, age: 14))
        let snapshot = simulator.criminalCareerSnapshot()
        #expect(snapshot.pathTitle == "Solo")
        #expect(snapshot.rankTitle == "Solo")
        #expect(snapshot.nextOperation == .burglary)
        #expect(snapshot.blocker == nil)
    }

    @Test func advancedCrimeRequiresOrganizationAuthority() {
        var state = state(seed: 87, age: 18)
        state.career.criminalPath = CriminalPathState(mode: .gangMember, rank: .member)
        let simulator = LifeSimulator(state: state)
        #expect(!simulator.canExecuteSoloCrime(.murder))
        #expect(CrimeSystem.canAccess(.robbery, state: state))
        #expect(!CrimeSystem.canAccess(.extortion, state: state))
    }

    @Test func soloCrimeCreatesPersistentSkillNotorietyAndHeat() {
        let simulator = LifeSimulator(state: state(seed: 81))
        let before = simulator.state.assets.notoriety.score
        let outcome = simulator.executeSoloCrime(.vehicleTheft)
        #expect(outcome != nil)
        #expect(simulator.state.career.criminalPath?.proficiencies[CrimeOperationType.vehicleTheft.rawValue] != nil)
        #expect(simulator.state.career.criminalPath?.heat ?? 0 > 0)
        #expect(simulator.state.assets.notoriety.score > before)
        #expect(!simulator.canExecuteSoloCrime(.vehicleTheft))
    }

    @Test func gangSpecialtyWorkIsLimitedToOneActionPerYear() {
        var state = state(seed: 82, age: 24)
        state.career.criminalPath = CriminalPathState(
            mode: .gangMember,
            rank: .member,
            gangName: "North Line",
            gangTrust: 55,
            gangSpecialty: .drugManufacturer,
            gangSpecialtySkill: 30
        )
        let beforeHeat = state.career.criminalPath?.heat ?? 0
        let first = CrimeSystem.performGangSpecialtyWork(state: &state)
        let second = CrimeSystem.performGangSpecialtyWork(state: &state)
        #expect(first != nil)
        #expect(second == nil)
        #expect(state.career.criminalPath?.lastSpecialtyWorkAge == 24)
        #expect((state.career.criminalPath?.heat ?? 0) > beforeHeat)
    }

    @Test func gangAppointmentsAdvanceOneRankAtATime() {
        var state = state(seed: 83, age: 25)
        state.career.criminalPath = CriminalPathState(
            mode: .gangMember,
            rank: .member,
            gangTrust: 50,
            notoriety: 20,
            influence: 20,
            gangSpecialty: .streetDistributor,
            gangSpecialtySkill: 30
        )
        _ = CrimeSystem.resolveYear(state: &state)
        #expect(state.career.criminalPath?.rank == .specialist)
        #expect(state.career.criminalPath?.mode == .gangMember)

        state.career.criminalPath?.gangSpecialtySkill = 60
        state.career.criminalPath?.gangTrust = 65
        _ = CrimeSystem.resolveYear(state: &state)
        #expect(state.career.criminalPath?.rank == .lieutenant)
    }

    @Test func gangHeatCanCauseAuthorityDemotion() {
        var state = state(seed: 84, age: 26)
        state.career.criminalPath = CriminalPathState(
            mode: .gangMember,
            rank: .lieutenant,
            gangTrust: 65,
            heat: 90,
            gangSpecialty: .runner,
            gangSpecialtySkill: 55
        )
        _ = CrimeSystem.resolveYear(state: &state)
        #expect(state.career.criminalPath?.rank == .specialist)
        #expect(state.career.criminalPath?.mode == .gangMember)
    }

    @Test func diamondDrugEnterpriseUsesOptionalManagementLayer() {
        var state = state(seed: 85, age: 30)
        state.career.criminalPath = CriminalPathState(
            mode: .enterprise,
            rank: .enterpriseLeader,
            gangTrust: 70,
            influence: 35,
            specialists: CrimeSystem.defaultSpecialists()
        )
        #expect(CrimeSystem.startDrugEnterprise(state: &state))
        #expect(CrimeSystem.recruitDrugEnterpriseRole(.runner, state: &state))
        #expect(CrimeSystem.improveDrugFormula(state: &state))
        let outcome = CrimeSystem.manageDrugEnterprise(state: &state)
        #expect(outcome != nil)
        #expect(state.career.criminalPath?.drugEnterprise?.lastManagedAge == 30)
        #expect(state.career.criminalPath?.drugEnterprise?.runners == 1)
    }

    @Test func drugEnterpriseManagementProducesCrossDomainConsequences() {
        var state = state(seed: 86, age: 31)
        state.career.criminalPath = CriminalPathState(
            mode: .gangLeader,
            rank: .leader,
            gangTrust: 80,
            influence: 50,
            drugEnterprise: DrugEnterpriseState(active: true, productQuality: 80, demand: 70, supplyReliability: 70, networkCoverage: 60, mules: 2, runners: 2, supplyRetrievers: 1)
        )
        let outcome = CrimeSystem.manageDrugEnterprise(state: &state)
        #expect(outcome?.healthDelta ?? 0 < 0)
        #expect(outcome?.relationshipsDelta ?? 0 < 0)
        #expect(outcome?.consequences.contains { $0.target == .health } == true)
        #expect(outcome?.consequences.contains { $0.target == .relationships } == true)
    }

    @Test func riskBreakdownReflectsAssignedSpecialistAndEquipment() {
        var state = state(seed: 91, age: 30)
        state.career.criminalPath = CriminalPathState(mode: .gangLeader, rank: .leader, gangName: "The North Line", gangTrust: 70, notoriety: 55, heat: 10, influence: 40, territory: 20, cashFlow: 300)
        state.career.criminalPath?.specialists = [
            SpecialistState(id: "planner", name: "Mara", role: .planner, competence: 86, loyalty: 84, fear: 35, respect: 70, ambition: 40, poachingRisk: 8, relationship: 65)
        ]
        var plan = CrimePlan(id: "robbery-plan", operation: .robbery, assignments: [.planning: "planner"])
        let weak = CrimeSystem.risk(for: plan, state: state)
        plan.preparation = 12
        state.career.criminalPath?.equipment.vehicleQuality = 80
        state.career.criminalPath?.equipment.weaponQuality = 80
        state.career.criminalPath?.equipment.technicalQuality = 60
        state.career.criminalPath?.equipment.concealmentQuality = 70
        let strong = CrimeSystem.risk(for: plan, state: state)
        #expect(strong.total < weak.total)
        #expect(strong.lines.contains { $0.contains("Competence") })
    }

    @Test func phaseTwoApproachAndPreparationChangeProjectedRisk() {
        var state = state(seed: 92, age: 30)
        state.cash = 5_000
        state.career.criminalPath = CriminalPathState(mode: .gangLeader, rank: .leader, specialists: CrimeSystem.defaultSpecialists())
        #expect(CrimeSystem.createPlan(operation: .fraud, state: &state) != nil)
        guard var plan = state.career.criminalPath?.plans.first else { return }
        let baseline = CrimeSystem.risk(for: plan, state: state)
        plan.approach = .technical
        let technical = CrimeSystem.risk(for: plan, state: state)
        #expect(technical.total < baseline.total)
        #expect(CrimeSystem.setPlanApproach(planID: plan.id, approach: .technical, state: &state))
        let cost = CrimeSystem.preparePlan(planID: plan.id, state: &state)
        #expect(cost == 250)
        let prepared = state.career.criminalPath?.plans.first.map { CrimeSystem.risk(for: $0, state: state) }
        #expect(prepared?.total ?? 99 < technical.total)
    }

    @Test func phaseTwoApproachChangesSuccessfulPayoutBand() {
        var forceState = state(seed: 93, age: 30)
        forceState.career.criminalPath = CriminalPathState(mode: .gangLeader, rank: .leader, specialists: CrimeSystem.defaultSpecialists())
        _ = CrimeSystem.createPlan(operation: .fraud, state: &forceState)
        guard let forceID = forceState.career.criminalPath?.plans.first?.id else { return }
        _ = CrimeSystem.setPlanApproach(planID: forceID, approach: .force, state: &forceState)
        let force = CrimeSystem.executePlan(id: forceID, state: &forceState)

        var stealthState = state(seed: 93, age: 30)
        stealthState.career.criminalPath = CriminalPathState(mode: .gangLeader, rank: .leader, specialists: CrimeSystem.defaultSpecialists())
        _ = CrimeSystem.createPlan(operation: .fraud, state: &stealthState)
        guard let stealthID = stealthState.career.criminalPath?.plans.first?.id else { return }
        _ = CrimeSystem.setPlanApproach(planID: stealthID, approach: .stealth, state: &stealthState)
        let stealth = CrimeSystem.executePlan(id: stealthID, state: &stealthState)

        #expect(force?.succeeded == stealth?.succeeded)
        if force?.succeeded == true { #expect((force?.payout ?? 0) >= (stealth?.payout ?? 0)) }
    }

    @Test func phaseThreeStarterCrimesHaveDistinctExposureProfiles() {
        let burglary = CrimeOperationDefinition.definition(for: .burglary)
        let fraud = CrimeOperationDefinition.definition(for: .fraud)
        let smuggling = CrimeOperationDefinition.definition(for: .smuggling)
        #expect(burglary.preferredApproaches.contains(.stealth))
        #expect(fraud.preferredApproaches.contains(.deception))
        #expect(smuggling.preferredApproaches.contains(.logistics))
        #expect(burglary.failureHealth < smuggling.failureHealth)
        #expect(fraud.successHeat < smuggling.successHeat)
        #expect(fraud.payoutMultiplierPercent > burglary.payoutMultiplierPercent)
    }

    @Test func criminalPathPersistsThroughSaveMigration() throws {
        var state = state(seed: 101, age: 30)
        state.career.criminalPath = CriminalPathState(mode: .gangLeader, rank: .leader, gangName: "Harbor Crew", gangTrust: 66, notoriety: 44, heat: 12, influence: 30, territory: 15, cashFlow: 220)
        state.career.criminalPath?.plans = [CrimePlan(id: "solo-fraud", operation: .fraud, mastery: 18, exposure: 9)]
        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(restored.saveVersion == state.saveVersion)
        #expect(restored.career.criminalPath == state.career.criminalPath)
    }

    @Test func organizationCashFlowUsesActingLeaderCompetenceDuringAbsence() {
        var state = state(seed: 111, age: 40)
        state.career.criminalPath = CriminalPathState(mode: .gangLeader, rank: .leader, gangName: "Eastside", gangTrust: 70, notoriety: 60, heat: 15, influence: 55, territory: 40, cashFlow: 200, organizationAbsent: true)
        state.career.criminalPath?.specialists = [
            SpecialistState(id: "lieutenant", name: "Rhea", role: .lieutenant, competence: 75, loyalty: 78, fear: 30, respect: 74, ambition: 50, poachingRisk: 10, relationship: 60)
        ]
        state.career.criminalPath?.actingLeaderID = "lieutenant"
        let result = CrimeSystem.resolveYear(state: &state)
        #expect(result.deltas.cash > 0)
        #expect(result.notes.contains { $0.contains("kept the organization") })
    }

    @Test func independentOrganizationCreatesPersistentPlansAndInfrastructure() {
        var state = state(seed: 121, age: 30)
        state.cash = CrimeSystem.organizationStartupCost
        state.career.criminalPath = CriminalPathState(notoriety: 25)
        #expect(CrimeSystem.startIndependentOrganization(name: "North Line", state: &state))
        #expect(CrimeSystem.createPlan(operation: .robbery, state: &state) != nil)
        CrimeSystem.acquireSafehouse(name: "Warehouse", state: &state)
        CrimeSystem.acquireFrontBusiness(name: "Auto shop", state: &state)
        #expect(state.career.criminalPath?.plans.count == 1)
        #expect(state.career.criminalPath?.safehouses.count == 1)
        #expect(state.career.criminalPath?.frontBusiness?.heatReduction == 3)
    }

    @Test func successionOrderOverridesCompetenceFallback() {
        var state = state(seed: 122, age: 30)
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader)
        state.career.criminalPath?.specialists = CrimeSystem.defaultSpecialists()
        CrimeSystem.setSuccessionOrder(["technician", "planner"], state: &state)
        #expect(state.career.criminalPath?.successionOrder == ["technician", "planner"])
    }

    @Test func incarcerationAssignsActingLeaderAndReleaseRestoresControl() {
        var state = state(seed: 123, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader, gangName: "Harbor Crew", cashFlow: 500)
        state.career.criminalPath?.specialists = CrimeSystem.defaultSpecialists()
        state.career.criminalPath?.successionOrder = ["planner", "lieutenant"]
        PrisonSystem.sentence(level: .medium, years: 1, role: .leader, state: &state)
        #expect(state.career.criminalPath?.organizationAbsent == true)
        #expect(state.career.criminalPath?.actingLeaderID == "planner")
        let outcome = PrisonSystem.resolveYear(state: &state)
        #expect(outcome.released)
        #expect(state.career.criminalPath?.organizationAbsent == false)
        #expect(state.career.criminalPath?.actingLeaderID == nil)
    }

    @Test func prisonSupportImprovesOrganizationContinuityWhenContactIsAllowed() {
        var state = state(seed: 124, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .gangLeader, rank: .leader, gangTrust: 40, organizationMorale: 40)
        PrisonSystem.sentence(level: .low, years: 3, role: .leader, state: &state)
        let before = state.career.criminalPath?.organizationMorale ?? 0
        #expect(PrisonSystem.sendOrganizationSupport(state: &state))
        #expect((state.career.criminalPath?.organizationMorale ?? 0) > before)
    }

    @Test func prisonCommandsAreLimitedAndCanAuthorizeSavedOperations() {
        var state = state(seed: 126, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader, gangTrust: 55, organizationMorale: 45)
        state.career.criminalPath?.specialists = CrimeSystem.defaultSpecialists()
        #expect(CrimeSystem.createPlan(operation: .robbery, state: &state) != nil)
        PrisonSystem.sentence(level: .low, years: 3, role: .leader, state: &state)
        state.prison.communicationSecurity = 100
        let moraleBefore = state.career.criminalPath?.organizationMorale ?? 0
        let message = PrisonSystem.issueOrganizationCommand(.reassureCrew, state: &state)
        #expect(message.intercepted == false)
        #expect((state.career.criminalPath?.organizationMorale ?? 0) > moraleBefore)
        let planID = state.career.criminalPath?.plans.first?.id
        let operation = PrisonSystem.issueOrganizationCommand(.authorizePlan, planID: planID, state: &state)
        #expect(operation.operation != nil)
        #expect(state.prison.commandsRemaining < state.prison.commandCapacity)
    }

    @Test func interceptedPrisonCommandDamagesTrustAndRaisesHeat() {
        var state = state(seed: 127, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .gangLeader, rank: .leader, gangTrust: 70, heat: 10, organizationMorale: 70)
        PrisonSystem.sentence(level: .high, years: 3, role: .leader, state: &state)
        state.prison.communicationSecurity = 0
        state.prison.prisonRandom = SeededRandom(seed: 2)
        let trustBefore = state.career.criminalPath?.gangTrust ?? 0
        let result = PrisonSystem.issueOrganizationCommand(.reassureCrew, state: &state)
        #expect(result.intercepted)
        #expect((state.career.criminalPath?.gangTrust ?? 100) < trustBefore)
        #expect((state.career.criminalPath?.heat ?? 0) > 10)
    }

    @Test func prisonProtectionReducesInsideNotorietyAndCreatesAnOngoingStatus() {
        var state = state(seed: 125, age: 35)
        state.cash = 1_000
        state.career.criminalPath = CriminalPathState(mode: .gangMember, rank: .member, notoriety: 45)
        PrisonSystem.sentence(level: .medium, years: 3, role: .member, state: &state)
        state.prison.prisonNotoriety = 30
        let result = PrisonSystem.perform(.payForProtection, targetID: nil, state: &state)
        #expect(result.cashDelta < 0)
        #expect(state.prison.protectionYearsRemaining == 1)
        #expect(state.prison.prisonNotoriety < 30)
    }

    @Test func informantChoiceStartsHiddenAndCanExposeLater() {
        var state = state(seed: 126, age: 35)
        PrisonSystem.sentence(level: .highMaxSecurity, years: 4, role: .member, state: &state)
        state.prison.informantOffered = true
        PrisonSystem.acceptInformant(state: &state)
        #expect(state.prison.isInformant)
        #expect(!state.prison.informantExposed)
        #expect(!state.prison.hasFlippedOnPlayer)
    }

    @Test func newLegalAndPrisonFieldsRoundTripThroughSaves() throws {
        var state = state(seed: 127, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .gangMember, rank: .member)
        state.legal.cases = [LegalCaseState(id: "case-1", operation: .robbery, severity: .serious, origin: .gangMember, evidenceStrength: 55)]
        state.career.criminalPath?.defenseTeam = [DefenseLawyerState(id: "lawyer-1", name: "Avery", specialty: .organizedCrime, defenseSkill: 70, trialSkill: 65, pleaSkill: 75, appealSkill: 60)]
        PrisonSystem.sentence(level: .high, years: 5, role: .member, state: &state)
        state.prison.inmates = [PrisonInmateState(id: "inmate-1", name: "Rivera", gangName: "North Block")]
        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(restored.legal.cases.count == 1)
        #expect(restored.career.criminalPath?.defenseTeam.count == 1)
        #expect(restored.prison.inmates.count == 1)
    }

    @Test func enterpriseCasesBeginAsInvestigationsAndCanReachPretrial() {
        var state = state(seed: 137, age: 35)
        state.career.criminalPath = CriminalPathState(
            mode: .enterprise,
            rank: .enterpriseLeader,
            notoriety: 80,
            heat: 80,
            specialists: CrimeSystem.defaultSpecialists()
        )
        let opened = CriminalLegalSystem.registerCrime(
            operation: .fraud,
            risk: CrimeRiskBreakdown(operation: 90, informant: 8),
            state: &state
        )
        #expect(opened.openedCaseID != nil)
        #expect(state.legal.cases.first?.status == .investigation)
        #expect(state.legal.cases.first?.agency == .financialCrimes)

        for _ in 0..<5 where state.legal.cases.first?.status == .investigation {
            _ = CriminalLegalSystem.resolveYear(state: &state)
        }
        #expect(state.legal.cases.first?.status == .pretrial || state.legal.cases.first?.status == .pleaOffered)
        #expect((state.legal.cases.first?.yearsUnderInvestigation ?? 0) > 0)
    }

    @Test func pretrialBailAndDetentionChangeAvailableCrimeActions() {
        var state = state(seed: 138, age: 35)
        state.cash = 20_000
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader, specialists: CrimeSystem.defaultSpecialists())
        state.legal.cases = [LegalCaseState(
            id: "pretrial-1",
            operation: .fraud,
            severity: .serious,
            origin: .enterprise,
            status: .pretrial,
            agency: .financialCrimes,
            evidenceStrength: 60,
            enterpriseEvidence: 55,
            investigationVisibility: 80,
            financialTrailStrength: 70,
            witnessPressure: 30,
            pretrialStatus: .detained,
            bailAmount: 8_000,
            travelRestricted: true,
            noContactRestricted: true
        )]
        let simulator = LifeSimulator(state: state)
        #expect(!simulator.canExecuteSoloCrime(.fraud))
        #expect(simulator.postLegalBail("pretrial-1") != nil)
        #expect(simulator.state.cash == 12_000)
        #expect(simulator.state.legal.cases[0].pretrialStatus == .restricted)
        #expect(simulator.acceptLegalDetention("pretrial-1") != nil)
        #expect(simulator.state.legal.cases[0].pretrialStatus == .detained)
    }

    @Test func newLegalInvestigationFieldsDecodeWithLegacyDefaults() throws {
        var source = state(seed: 139, age: 35)
        source.legal.cases = [LegalCaseState(id: "legacy-case", operation: .robbery, severity: .serious, origin: .gangMember, evidenceStrength: 40)]
        let data = try JSONEncoder().encode(source)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var legal = try #require(json["legal"] as? [String: Any])
        var cases = try #require(legal["cases"] as? [[String: Any]])
        for key in ["agency", "investigationVisibility", "financialTrailStrength", "witnessPressure", "searchWarrantCount", "yearsUnderInvestigation", "pretrialStatus", "bailAmount", "postedBailAmount", "travelRestricted", "noContactRestricted", "pretrialViolationCount"] {
            cases[0].removeValue(forKey: key)
        }
        legal["cases"] = cases
        json["legal"] = legal
        let legacyData = try JSONSerialization.data(withJSONObject: json)
        let restored = try JSONDecoder().decode(LifeState.self, from: legacyData)
        #expect(restored.legal.cases.first?.agency == .local)
        #expect(restored.legal.cases.first?.pretrialStatus == PretrialStatus.none)
    }

    @Test func enterpriseCasesKeepBoundedMultiTargetLiabilityInsideOneCase() {
        var state = state(seed: 140, age: 35)
        state.career.criminalPath = CriminalPathState(
            mode: .enterprise,
            rank: .enterpriseLeader,
            specialists: CrimeSystem.defaultSpecialists(),
            frontBusiness: FrontBusinessState(name: "Auto shop", legitimateCashFlow: 150, heatReduction: 3)
        )
        let opened = CriminalLegalSystem.registerCrime(
            operation: .fraud,
            risk: CrimeRiskBreakdown(operation: 80, informant: 5),
            state: &state
        )
        let targets = state.legal.cases.first?.targets ?? []
        #expect(opened.openedCaseID != nil)
        #expect(targets.count == 1 + 1 + min(6, CrimeSystem.defaultSpecialists().count) + 1)
        #expect(targets.filter { $0.type == .organization }.count == 1)
        #expect(targets.filter { $0.type == .frontBusiness }.count == 1)
        #expect(state.legal.cases.count == 1)
    }

    @Test func enterpriseCooperationActionsAreDistinctAndLimitedPerAge() {
        var state = state(seed: 141, age: 35)
        state.cash = 20_000
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader, specialists: CrimeSystem.defaultSpecialists())
        let opened = CriminalLegalSystem.registerCrime(operation: .fraud, risk: CrimeRiskBreakdown(operation: 90), state: &state)
        let specialistID = state.legal.cases[0].targets.first(where: { $0.type == .specialist })?.id
        #expect(opened.openedCaseID != nil)
        #expect(specialistID != nil)
        guard let caseID = opened.openedCaseID, let specialistID else { return }
        if let index = state.legal.cases[0].targets.firstIndex(where: { $0.id == specialistID }) {
            state.legal.cases[0].targets[index].status = .questioned
            state.legal.cases[0].targets[index].exposure = 60
        }
        guard let outcome = CriminalLegalSystem.applyEnterpriseAction(caseID: caseID, targetID: specialistID, action: .protect, state: &state) else {
            Issue.record("Expected protect action to be available")
            return
        }
        #expect(CriminalLegalSystem.availableEnterpriseActions(caseID: caseID, targetID: specialistID, state: state).isEmpty)
        #expect(outcome.cashDelta == -2_500)
        #expect(outcome.impact.organizationMoraleDelta == 3)
    }

    @Test func frontBusinessLegalClosureDisablesHeatReductionAndReopens() {
        var state = state(seed: 142, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader, heat: 20, cashFlow: 200,
            frontBusiness: FrontBusinessState(name: "Auto shop", legitimateCashFlow: 150, heatReduction: 3))
        CrimeSystem.applyLegalImpact(EnterpriseLegalImpact(frontBusinessClosureYears: 2, frontBusinessScrutinyDelta: 20, frontBusinessRestricted: true), state: &state)
        #expect(state.career.criminalPath?.frontBusiness?.closureYearsRemaining == 2)
        #expect(state.career.criminalPath?.frontBusiness?.isLegallyRestricted == true)
        _ = CrimeSystem.resolveYear(state: &state)
        #expect(state.career.criminalPath?.frontBusiness?.closureYearsRemaining == 1)
        _ = CrimeSystem.resolveYear(state: &state)
        #expect(state.career.criminalPath?.frontBusiness?.closureYearsRemaining == 0)
        #expect(state.career.criminalPath?.frontBusiness?.isLegallyRestricted == false)
    }

    @Test func cooperationOfferRequiresAnEligibleSpecialistTarget() {
        var state = state(seed: 143, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader, specialists: CrimeSystem.defaultSpecialists())
        let specialist = LegalTargetState(id: "specialist:planner", type: .specialist, status: .exposed)
        state.legal.cases = [LegalCaseState(id: "cooperation-1", operation: .fraud, severity: .serious, origin: .enterprise, status: .pretrial, pleaYears: 6, sentenceYears: 8, targets: [LegalTargetState(id: "player", type: .player), specialist], cooperationStatus: .offerAvailable, cooperationTargetID: specialist.id, cooperationSentenceReduction: 2)]
        #expect(CriminalLegalSystem.cooperationOffer(caseID: "cooperation-1", state: state) == nil)
        state.legal.cases[0].targets[1].status = .questioned
        #expect(CriminalLegalSystem.cooperationOffer(caseID: "cooperation-1", state: state)?.targetID == specialist.id)
    }

    @Test func specialistCooperationImprovesPleaPositionAndDamagesContinuity() {
        var state = state(seed: 144, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader, cashFlow: 200, specialists: CrimeSystem.defaultSpecialists(), organizationMorale: 60)
        let specialist = LegalTargetState(id: "specialist:planner", type: .specialist, evidenceStrength: 30, status: .questioned)
        state.legal.cases = [LegalCaseState(id: "cooperation-2", operation: .fraud, severity: .serious, origin: .enterprise, status: .pretrial, evidenceStrength: 55, enterpriseEvidence: 50, pleaYears: 6, sentenceYears: 8, targets: [LegalTargetState(id: "player", type: .player), specialist], cooperationStatus: .offerAvailable, cooperationTargetID: specialist.id, cooperationSentenceReduction: 2)]
        let simulator = LifeSimulator(state: state)
        #expect(simulator.acceptLegalCooperation(caseID: "cooperation-2") != nil)
        #expect(simulator.state.legal.cases[0].cooperationStatus == .accepted)
        #expect(simulator.state.legal.cases[0].enterpriseEvidence > 50)
        #expect(simulator.state.legal.cases[0].pleaYears == 4)
        #expect(simulator.state.career.criminalPath?.organizationMorale == 48)
        #expect(simulator.state.career.criminalPath?.specialists.first(where: { $0.id == "planner" })?.isArrested == true)
        #expect(simulator.state.legal.cases.count == 1)
    }

    @Test func playerCooperationReducesSentenceAndOpensRelationshipConsequence() {
        var state = state(seed: 145, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader, heat: 20, specialists: CrimeSystem.defaultSpecialists(), organizationMorale: 60)
        state.legal.cases = [LegalCaseState(id: "cooperation-3", operation: .fraud, severity: .serious, origin: .enterprise, status: .pretrial, evidenceStrength: 85, enterpriseEvidence: 80, pleaYears: 10, sentenceYears: 12, targets: [LegalTargetState(id: "player", type: .player), LegalTargetState(id: "organization", type: .organization)], cooperationStatus: .offerAvailable, cooperationTargetID: "player", cooperationSentenceReduction: 3)]
        let simulator = LifeSimulator(state: state)
        #expect(simulator.acceptLegalCooperation(caseID: "cooperation-3") != nil)
        #expect(simulator.state.legal.cases[0].playerCooperated)
        #expect(simulator.state.legal.cases[0].cooperationRecordPermanent)
        #expect(simulator.state.legal.cases[0].sentenceYears == 9)
        #expect(simulator.state.career.criminalPath?.heat == 40)
        #expect(simulator.state.lifeThreads.contains { $0.kind == .legalTrouble })
    }

    @Test func decliningCooperationPreservesEvidenceAndCannotBeAcceptedLater() {
        var state = state(seed: 146, age: 35)
        let player = LegalTargetState(id: "player", type: .player)
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader)
        state.legal.cases = [LegalCaseState(id: "cooperation-4", operation: .fraud, severity: .serious, origin: .enterprise, status: .pretrial, evidenceStrength: 72, enterpriseEvidence: 65, pleaYears: 7, sentenceYears: 9, targets: [player], cooperationStatus: .offerAvailable, cooperationTargetID: "player", cooperationSentenceReduction: 2)]
        let simulator = LifeSimulator(state: state)
        #expect(simulator.declineLegalCooperation(caseID: "cooperation-4") != nil)
        #expect(simulator.state.legal.cases[0].cooperationStatus == .declined)
        #expect(simulator.state.legal.cases[0].evidenceStrength == 72)
        #expect(simulator.acceptLegalCooperation(caseID: "cooperation-4") == nil)
    }

    @Test func cooperationFieldsDecodeWithNeutralDefaultsFromV46() throws {
        var source = state(seed: 147, age: 35)
        source.legal.cases = [LegalCaseState(id: "legacy-cooperation", operation: .fraud, severity: .serious, origin: .enterprise)]
        let data = try JSONEncoder().encode(source)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var legal = try #require(json["legal"] as? [String: Any])
        var cases = try #require(legal["cases"] as? [[String: Any]])
        for key in ["cooperationStatus", "cooperationTargetID", "cooperationOfferAge", "cooperationDecisionAge", "playerCooperated", "cooperationRecordPermanent", "cooperationSentenceReduction"] {
            cases[0].removeValue(forKey: key)
        }
        legal["cases"] = cases
        json["legal"] = legal
        let restored = try JSONDecoder().decode(LifeState.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(restored.legal.cases[0].cooperationStatus == .none)
        #expect(restored.legal.cases[0].cooperationTargetID == nil)
        #expect(restored.legal.cases[0].playerCooperated == false)
        #expect(restored.legal.cases[0].cooperationRecordPermanent == false)
    }

    @Test func prisonContentActionsCreateDebtAndMentalHealthTradeoffs() {
        var state = state(seed: 128, age: 35)
        state.cash = 1_000
        PrisonSystem.sentence(level: .high, years: 3, role: .none, state: &state)
        let job = PrisonSystem.perform(.takePrisonJob, targetID: nil, state: &state)
        let care = PrisonSystem.perform(.requestMedicalCare, targetID: nil, state: &state)
        #expect(job.bullets.contains { $0.contains("prison job") })
        #expect(care.healthDelta > 0)
        #expect(state.prison.medicalDebt > 0)
        #expect(state.prison.prisonJob != nil)
    }

    @Test func rivalsSupportNegotiationAttackAndTerritoryPressure() {
        var state = state(seed: 128, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader, influence: 70, territory: 20)
        state.career.criminalPath?.specialists = CrimeSystem.defaultSpecialists()
        state.career.criminalPath?.rivals = CrimeSystem.defaultRivals()
        let rivalID = state.career.criminalPath?.rivals[0].id ?? ""
        #expect(CrimeSystem.negotiateWithRival(rivalID, state: &state))
        #expect(CrimeSystem.attackRival(rivalID, state: &state) != nil)
        #expect(state.career.criminalPath?.rivals.first?.hatred ?? 0 > 0)
    }

    @Test func individualDelegationTracksExperienceAndCanExposeTheCrew() {
        var state = state(seed: 129, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .gangLeader, rank: .leader, heat: 10)
        state.career.criminalPath?.specialists = CrimeSystem.defaultSpecialists()
        let result = CrimeSystem.delegateIndividualTask(specialistID: "enforcer", operation: .robbery, state: &state)
        #expect(result != nil)
        #expect(state.career.criminalPath?.specialists.first(where: { $0.id == "enforcer" })?.operationExperience[CrimeOperationType.robbery.rawValue] == 1)
    }

    @Test func specialistRelationshipsRevealFactsWithoutExposingEverythingImmediately() {
        var state = state(seed: 130, age: 35)
        state.career.criminalPath = CriminalPathState(mode: .enterprise, rank: .enterpriseLeader)
        state.career.criminalPath?.specialists = CrimeSystem.defaultSpecialists()
        #expect(CrimeSystem.buildSpecialistRelationship("planner", state: &state))
        #expect(state.career.criminalPath?.specialists.first?.knownFacts.contains("competence") == true)
        #expect(state.career.criminalPath?.specialists.first?.knownFacts.contains("ambition-poaching") == false)
        for _ in 0..<8 { _ = CrimeSystem.buildSpecialistRelationship("planner", state: &state) }
        #expect(state.career.criminalPath?.specialists.first?.knownFacts.contains("ambition-poaching") == true)
    }
}

private final class ManualPersistence: LifePersisting, @unchecked Sendable {
    let automaticallyPersistsCommits = false
    private(set) var saveCount = 0

    func save(_ state: LifeState) -> Result<Void, Error> {
        saveCount += 1
        return .success(())
    }

    func clear() {}
}

@MainActor
struct OneLifeTests {
    private func isolatedSimulator(state: LifeState) -> LifeSimulator {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-test-\(UUID().uuidString).json")
        return LifeSimulator(state: state, store: LifePersistence(saveURL: url))
    }

    @Test func lifeMomentPresentationStylesUseExistingEventContext() {
        func event(_ id: String, partner: Bool = false, kind: PresentedEvent.Kind = .instant) -> PresentedEvent {
            PresentedEvent(
                id: id,
                headline: "A choice",
                detail: "Decide what happens next.",
                choices: [],
                yearDeltas: DeltaSummary(),
                isPartnerEvent: partner,
                kind: kind
            )
        }

        #expect(LifeMomentPresentationStyle.resolve(for: event("partner-friction", partner: true)) == .relationship)
        #expect(LifeMomentPresentationStyle.resolve(for: event("economy-debt-workout")) == .finance)
        #expect(LifeMomentPresentationStyle.resolve(for: event("recovery-year-resistance")) == .recovery)
        #expect(LifeMomentPresentationStyle.resolve(for: event("school_exam_push")) == .school)
        #expect(LifeMomentPresentationStyle.resolve(for: event("friend_night_out")) == .play)
        #expect(LifeMomentPresentationStyle.resolve(for: event("unknown-future-event")) == .general)
        #expect(LifeMomentPresentationStyle.resolve(for: event("unknown-yearly-event", kind: .yearly)) == .yearly)
    }

    @Test func playerDecisionsPersistIntentAndCausalContext() throws {
        var state = LifeState(name: "Signal", seed: 901, startingAge: 33)
        state.partner = PartnerState(name: "Morgan", compatibility: 70, committed: true)
        let action = DomainActionRegistry.action(for: .pursuePromotion)

        let signal = PlayerDecisionSignalSystem.signal(for: action, state: state)
        #expect(signal.kind == .playerDecision)
        #expect(signal.intent == .advance)
        #expect(signal.commitment == .ambition)
        #expect(signal.exposure == .network)
        #expect(signal.affectedDomains.contains(.career))

        state.rememberDecisionSignal(signal)
        let encoded = try JSONEncoder().encode(state)
        let restored = try JSONDecoder().decode(LifeState.self, from: encoded)
        #expect(restored.recentDecisionSignals == [signal])
    }

    @Test func playerDecisionMemoryIsBoundedAndDeduplicated() {
        var state = LifeState(name: "Memory", seed: 902)
        let action = DomainActionRegistry.action(for: .workShift)
        let signal = PlayerDecisionSignalSystem.signal(for: action, state: state)

        state.rememberDecisionSignal(signal)
        state.rememberDecisionSignal(signal)
        #expect(state.recentDecisionSignals.count == 1)

        for age in 19...30 {
            state.character.age = age
            state.rememberDecisionSignal(PlayerDecisionSignalSystem.signal(for: action, state: state))
        }
        #expect(state.recentDecisionSignals.count == 6)
        #expect(state.recentDecisionSignals.first?.age == 30)
    }

    @Test func currentNarrativeAndTimelineDeriveFromExistingLifeState() {
        var state = LifeState(name: "Narrative", seed: 73, startingAge: 33)
        state.partner = PartnerState(name: "Jordan", compatibility: 55, bond: 30, resentment: 60)
        state.lifeThreads = [
            LifeThread(
                kind: .burnout,
                headline: "Work Followed You Home",
                intensity: 5,
                openedAge: 32,
                yearsRemaining: 2,
                source: .career,
                target: .relationships,
                detail: "The promotion is still taking more than it promised."
            )
        ]
        state.history = [
            HistoryEntry(id: 2, age: 33, headline: "A Quiet Shift", detail: "Ordinary feedback.", deltas: DeltaSummary()),
            HistoryEntry(
                id: 1,
                age: 32,
                headline: "A Promotion Changed The Pace",
                detail: "Work became a larger part of the household.",
                deltas: DeltaSummary(),
                yearSummary: YearSummary(
                    bullets: ["Promotion"], stanceTitle: nil, shapeTitle: nil, focusNote: nil,
                    silenceNote: nil, wasQuiet: false, age: 32, headline: "Promotion", importance: .major
                )
            )
        ]

        let narrative = CurrentLifeNarrativeResolver.resolve(for: state)
        #expect(narrative.chapter == "Work Followed You Home")
        #expect(narrative.context.contains("promotion"))
        #expect(LifeTimelineResolver.milestones(for: state).map(\.headline) == ["A Promotion Changed The Pace"])
    }

    @Test func adolescenceHibernatesAdultSystemsAndShowsFourSchoolCommitments() {
        let state = LifeState(name: "Freshman", seed: 14, startingAge: 14)
        let simulator = isolatedSimulator(state: state)

        #expect(simulator.state.lifeStage == .adolescence)
        #expect(simulator.state.education.phase == .highSchool)
        #expect(!SystemRegistry.isActive(.career, in: simulator.state))
        #expect(!SystemRegistry.isActive(.finance, in: simulator.state))
        #expect(Set(simulator.visibleActions(in: .school).map(\.id)) == Set([
            .focusGrades, .findYourPeople, .commitActivity, .helpAtHome
        ]))
    }

    @Test func oneSchoolCommitmentDefinesTheYearAndCreatesAStableTeacher() throws {
        let simulator = isolatedSimulator(state: LifeState(name: "Student", seed: 15, startingAge: 14))

        let outcome = try #require(simulator.execute(.focusGrades))
        let firstTeacher = try #require(simulator.state.npcs[.teacher])

        #expect(simulator.state.education.commitment == .academics)
        #expect(outcome.headline == "Grades Became The Priority")
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .findYourPeople)) == .locked("This school year's focus is already set"))

        simulator.ageUp()
        if let event = simulator.state.pendingEvent, let choice = event.choices.first { simulator.execute(choice.id) }
        #expect(simulator.state.education.commitment == nil)
        #expect(simulator.state.npcs[.teacher]?.name == firstTeacher.name)
    }

    @Test func fourStrongSchoolYearsProduceAPlayerDirectedScholarshipOffer() {
        var state = LifeState(name: "Graduate", seed: 16, startingAge: 14)
        var finalOutcome = EducationYearOutcome()

        for nextAge in 15...18 {
            _ = EducationSystem.resolve(.focusGrades, state: &state)
            state.character.age = nextAge
            finalOutcome = EducationSystem.resolveYear(state: &state)
        }

        #expect(state.education.highSchoolDiploma)
        #expect(state.education.phase == .awaitingDecision)
        #expect(state.education.postSchoolPath == .undecided)
        #expect(finalOutcome.milestoneHeadline == "High School Is Behind You")
        #expect(!state.flags.attendsSchool)
        #expect(finalOutcome.graduationOffers.count == 3)
        #expect(finalOutcome.graduationOffers.first?.transition == .enroll(.scholarshipUniversity))

        let enrollment = EducationSystem.resolve(.enroll(.scholarshipUniversity), state: &state)
        #expect(enrollment.followUp == .chooseField)
        #expect(state.education.college.credits == 2)
        #expect(state.finance.studentDebt == 0)
        _ = EducationSystem.resolve(.chooseField(.appliedTechnical), state: &state)
        #expect(state.education.college.status == .enrolled)
        #expect(state.education.college.field == .appliedTechnical)
    }

    @Test func highSchoolStateRoundTripsWithoutLosingTheYearFocus() throws {
        var state = LifeState(name: "Saved Student", seed: 17, startingAge: 14)
        _ = EducationSystem.resolve(.commitActivity, state: &state)
        state.education.commitmentYears = [.academics: 2, .activity: 1]
        state.education.legacyFlags = [.activityIdentity, .rumorScar]
        state.education.launchInfluenceYearsRemaining = 6
        state.education.legacySnapshot = SchoolLegacyModifiers(studyProgressBonus: 1, yearsRemaining: 7)

        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))

        #expect(restored.education == state.education)
        #expect(restored.lifeStage == .adolescence)
        #expect(restored.isValidSave)
    }

    @Test func schoolEnvironmentIsDeterministicVariedAndDoesNotConsumeRNG() {
        let seeds = Array(1...40).map(UInt64.init)
        let environments = Set(seeds.map(EducationSystem.schoolEnvironment(for:)))
        #expect(environments.count == SchoolEnvironment.allCases.count)

        for seed in seeds {
            let state = LifeState(name: "School", seed: seed, startingAge: 14)
            #expect(state.education.schoolEnvironment == EducationSystem.schoolEnvironment(for: seed))
            #expect(state.random == SeededRandom(seed: seed))
            #expect(state.randomStreams == SimulationRandomStreams(runSeed: seed))
        }
    }

    @Test func oneActivityArcJoinsCommitsLeadsAndEnds() {
        var state = LifeState(name: "Activity", seed: 18, startingAge: 14)
        _ = EducationSystem.resolve(.commitActivity, state: &state)
        #expect(state.education.activity != .none)
        #expect(state.education.activityStage == .joined)

        state.education.commitment = nil
        _ = EducationSystem.resolve(.commitActivity, state: &state)
        #expect(state.education.activityStage == .committed)
        EducationSystem.apply(EducationChoiceEffect(activityStage: .leader), state: &state)
        #expect(state.education.activityStage == .leader)
        EducationSystem.apply(EducationChoiceEffect(activityStage: .ended), state: &state)
        #expect(state.education.activityStage == .ended)
        #expect(RequirementEvaluator.unmetReason(.schoolActivityOpen, in: state) == "That school activity chapter has ended")
    }

    @Test func schoolWeightingUsesEnvironmentGradeAndSchoolOnlyReputation() {
        var state = LifeState(name: "Weights", seed: 19, startingAge: 14)
        state.character.age = 16
        state.education.schoolEnvironment = .competitive
        let weighted = EducationSystem.schoolEventWeight(eventID: "junior-future-pressure", baseWeight: 5, state: state)
        state.education.schoolEnvironment = .closeKnit
        let otherEnvironment = EducationSystem.schoolEventWeight(eventID: "junior-future-pressure", baseWeight: 5, state: state)
        #expect(weighted > otherEnvironment)

        state.character.age = 15
        let otherGrade = EducationSystem.schoolEventWeight(eventID: "junior-future-pressure", baseWeight: 5, state: state)
        #expect(otherEnvironment > otherGrade)

        state.character.age = 17
        state.lifeStage = .adolescence
        state.education.phase = .highSchool
        state.education.highSchoolDiploma = true
        state.education.futureReadiness = 60
        state.education.academicStanding = 60
        let offersBefore = EducationSystem.graduationOffers(for: state)
        let careerBefore = EducationSystem.credentialModifiers(for: state)
        state.education.schoolReputation = 100
        #expect(EducationSystem.graduationOffers(for: state) == offersBefore)
        #expect(EducationSystem.credentialModifiers(for: state).kind == careerBefore.kind)
        #expect(EducationSystem.credentialModifiers(for: state).field == careerBefore.field)
    }

    @Test func schoolMemoriesComeFromChoicesStayBoundedAndFreezeAtGraduation() throws {
        var state = LifeState(name: "Memory", seed: 20, startingAge: 14)
        for index in 0..<8 {
            let choice = EventChoice(
                id: index.isMultiple(of: 2) ? .accept : .talk,
                title: "Choice \(index)",
                detail: "A real choice.",
                effects: EffectRange(),
                partnerEffect: PartnerEffect(),
                narrative: "It happened.",
                educationEffect: EducationChoiceEffect(
                    memoryKind: index == 7 ? .ending : .belonging,
                    memorySignificance: index == 7 ? 5 : 2
                )
            )
            let event = PresentedEvent(
                id: "school-memory-\(index)", headline: "A Real School Moment Happens", detail: "A moment.",
                choices: [choice], yearDeltas: DeltaSummary(), isPartnerEvent: false
            )
            state.character.age = 14 + min(3, index / 2)
            EducationSystem.recordSchoolChoice(event: event, choice: choice, state: &state)
        }
        #expect(state.education.schoolMemories.count == 6)
        #expect(state.education.schoolMemories.contains { $0.eventID == "school-memory-7" })

        state.character.age = 18
        state.education.academicStanding = 60
        _ = EducationSystem.resolveYear(state: &state)
        let defining = try #require(state.education.frozenDefiningMemory)
        #expect(defining.eventID == "school-memory-7")
        #expect(state.education.definingHighSchoolMemory?.contains("real school moment") == true)
        #expect(LifeReviewModel.build(from: state).educationLine.contains("real school moment"))
        #expect(EchoFlavorResolver.line(state: state)?.contains("real school moment") == true)
        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(restored.education.frozenDefiningMemory == defining)
    }

    @Test func highSchoolStoryletsStayHeadlineFirstAndRelationshipEffectsSurviveFlavoring() throws {
        let newIDs: Set<String> = [
            "freshman-lunch-table", "bullying-line-crossed", "sophomore-name-sticks", "school-date-invitation",
            "discipline-office", "junior-future-pressure", "part-time-school-week", "family-needs-school-hours",
            "activity-injury", "academic-burnout-week", "activity-leadership", "activity-pushed-out",
            "prom-cost", "senior-last-night"
        ]
        let events = LifeEventRegistry.all.filter { newIDs.contains($0.id) }
        #expect(events.count == newIDs.count)
        for event in events {
            #expect((5...7).contains(event.headline.split(separator: " ").count))
            #expect((1...3).contains(event.choices.count))
            var fixture = LifeState(name: "Fixture", seed: 22, startingAge: 14)
            fixture.education.schoolBelonging = 60
            switch event.id {
            case "freshman-lunch-table": fixture.character.age = 14
            case "bullying-line-crossed": fixture.character.age = 14; fixture.education.schoolBelonging = 40
            case "sophomore-name-sticks": fixture.character.age = 15
            case "school-date-invitation": fixture.character.age = 15
            case "discipline-office": fixture.character.age = 15; fixture.education.schoolReputation = 30
            case "junior-future-pressure": fixture.character.age = 16
            case "part-time-school-week": fixture.character.age = 16; fixture.cash = 100
            case "family-needs-school-hours": fixture.character.age = 16; fixture.education.commitmentYears = [.home: 1]
            case "activity-injury", "activity-leadership": fixture.character.age = 16; fixture.education.activityStage = .committed
            case "academic-burnout-week": fixture.character.age = 16; fixture.education.commitmentYears = [.academics: 2]; fixture.education.academicStanding = 80
            case "activity-pushed-out": fixture.character.age = 16; fixture.education.activityStage = .committed; fixture.education.schoolBelonging = 30
            case "prom-cost": fixture.character.age = 17; fixture.cash = 100
            case "senior-last-night": fixture.character.age = 17
            default: break
            }
            #expect(event.weight(fixture) > 0, "No reachable fixture for \(event.id)")
        }

        var state = LifeGenerationSystem.customPreview(
            name: "Social", seed: 21, origin: .social, context: .ordinary,
            definingTrait: .outgoing, talent: nil
        ).state
        let event = try #require(events.first { $0.id == "freshman-lunch-table" })
        var social = SocialReactivitySystem()
        let flavored = social.contextualize(event, state: &state)
        #expect(flavored.choices.first?.relationshipRole == .friend)
        #expect(flavored.choices.first?.npcRapportDelta == 3)
        let before = try #require(state.npcs[.friend]?.rapport)
        state.pendingEvent = PresentedEvent(flavored)
        let simulator = isolatedSimulator(state: state)
        simulator.execute(.accept)
        #expect(simulator.state.npcs[.friend]?.rapport == before + 3)
    }

    @Test func graduationOfferProfilesAreDeterministicBoundedAndRecoverable() {
        func graduate(academic: Int, future: Int, support: Int, commitment: SchoolCommitment? = nil, seed: UInt64) -> (LifeState, EducationYearOutcome, SeededRandom) {
            var state = LifeState(name: "Path", seed: seed, startingAge: 14)
            state.character.age = 18
            state.education.academicStanding = academic
            state.education.futureReadiness = future
            state.education.teacherSupport = support
            state.education.commitment = commitment
            let random = state.random
            let outcome = EducationSystem.resolveYear(state: &state)
            return (state, outcome, random)
        }

        let scholarship = graduate(academic: 84, future: 74, support: 60, seed: 701)
        let standard = graduate(academic: 62, future: 58, support: 40, seed: 702)
        let community = graduate(academic: 56, future: 42, support: 40, seed: 703)
        let noDiploma = graduate(academic: 40, future: 40, support: 40, seed: 704)

        #expect(scholarship.1.graduationOffers.map(\.transition) == [.enroll(.scholarshipUniversity), .enroll(.communityCollege), .choosePath(.work)])
        #expect(standard.1.graduationOffers.map(\.transition) == [.enroll(.publicUniversity), .enroll(.communityCollege), .choosePath(.work)])
        #expect(community.1.graduationOffers.map(\.transition) == [.enroll(.communityCollege), .choosePath(.work), .choosePath(.undecided)])
        #expect(noDiploma.1.graduationOffers.map(\.transition) == [.choosePath(.alternativeCredential), .choosePath(.work), .choosePath(.undecided)])
        #expect(scholarship.0.random == scholarship.2)
        #expect(standard.0.random == standard.2)
        #expect(community.0.random == community.2)
        #expect(noDiploma.0.random == noDiploma.2)
        #expect([scholarship, standard, community, noDiploma].allSatisfy { $0.1.graduationOffers.count <= 3 })

        var work = standard.0
        work.cash = 100
        work.career.performance = 0
        work.career.security = 0
        let transition = EducationSystem.resolve(.choosePath(.work), state: &work)
        CareerSystem.applySchoolTransition(transition.career, state: &work)
        _ = FinanceSystem.applySchoolTransition(transition.finance, state: &work)
        #expect(work.cash == 7_600)
        #expect(work.career.level == .entry)
        #expect(work.career.security == 5)
    }

    @Test func schoolLegacyModifiersStayBoundedAndFadePermanentlyAtTwentyFive() {
        var state = LifeState(name: "Launch", seed: 718, startingAge: 14)
        state.character.age = 18
        state.education.phase = .leftSchool
        state.education.postSchoolPath = .training
        state.education.academicStanding = 82
        state.education.schoolBelonging = 78
        state.education.futureReadiness = 80
        state.education.commitmentYears = [.home: 3]
        state.education.legacyFlags = [.mentorBacked, .carriedHomeLoad]
        state.education.launchInfluenceYearsRemaining = 7
        state.education.legacySnapshot = SchoolLegacyModifiers(
            studyProgressBonus: 2,
            skillProgressBonus: 2,
            jobSearchChanceDelta: 8,
            socialActionDelta: 1,
            mentorEventWeight: 8,
            familyObligationEventWeight: 9,
            yearsRemaining: 7
        )

        let initial = EducationSystem.legacyModifiers(for: state)
        #expect((-1...2).contains(initial.studyProgressBonus))
        #expect((-8...8).contains(initial.jobSearchChanceDelta))
        #expect((-1...1).contains(initial.socialActionDelta))
        #expect(initial.socialActionDelta == 1)
        state.education.academicStanding = 10
        state.education.schoolBelonging = 10
        #expect(EducationSystem.legacyModifiers(for: state) == initial)

        for age in 19...24 {
            state.character.age = age
            _ = EducationSystem.resolveYear(state: &state)
            #expect(state.education.launchInfluenceYearsRemaining == 25 - age)
        }
        state.character.age = 25
        _ = EducationSystem.resolveYear(state: &state)
        #expect(state.education.launchInfluenceYearsRemaining == 0)
        #expect(EducationSystem.legacyModifiers(for: state) == SchoolLegacyModifiers())
        state.character.age = 24
        #expect(EducationSystem.legacyModifiers(for: state) == SchoolLegacyModifiers())
    }

    @Test func highSchoolYearsAreExplicitAndLegacyDimensionsRemainBounded() throws {
        #expect(HighSchoolYear(age: 14) == .freshman)
        #expect(HighSchoolYear(age: 15) == .sophomore)
        #expect(HighSchoolYear(age: 16) == .junior)
        #expect(HighSchoolYear(age: 17) == .senior)

        var state = LifeState(name: "Legacy dimensions", seed: 722, startingAge: 14)
        state.character.age = 18
        state.education.phase = .leftSchool
        state.education.postSchoolPath = .college
        state.education.academicStanding = 82
        state.education.schoolBelonging = 78
        state.education.futureReadiness = 80
        state.education.teacherSupport = 80
        state.education.legacyFlags = [.mentorBacked, .recommendationEarned, .sociallyRooted]
        state.education.launchInfluenceYearsRemaining = 7
        state.education.legacySnapshot = SchoolLegacyModifiers(
            opportunityAccess: 12,
            socialConfidence: 8,
            mentorAvailability: 10,
            recoveryResilience: 8,
            yearsRemaining: 7
        )

        let modifiers = EducationSystem.legacyModifiers(for: state)
        #expect((-12...12).contains(modifiers.opportunityAccess))
        #expect((-8...8).contains(modifiers.socialConfidence))
        #expect((0...10).contains(modifiers.mentorAvailability))
        #expect((0...8).contains(modifiers.recoveryResilience))

        var legacyJSON = try JSONSerialization.jsonObject(with: JSONEncoder().encode(SchoolLegacyModifiers(jobSearchChanceDelta: 4, yearsRemaining: 7))) as! [String: Any]
        legacyJSON.removeValue(forKey: "opportunityAccess")
        legacyJSON.removeValue(forKey: "socialConfidence")
        let restored = try JSONDecoder().decode(SchoolLegacyModifiers.self, from: JSONSerialization.data(withJSONObject: legacyJSON))
        #expect(restored.opportunityAccess == 0)
        #expect(restored.socialConfidence == 0)
        #expect(restored.jobSearchChanceDelta == 4)
    }

    @Test func pivotalSchoolPeopleReturnSelectivelyAndRemainHibernated() {
        var state = LifeState(name: "Memory", seed: 719, startingAge: 14)
        state.character.age = 20
        state.education.phase = .leftSchool
        state.education.legacyFlags = [.mentorBacked, .sociallyRooted]
        state.npcs[.teacher] = NPCState(name: "Ms. Rivera", role: .teacher, importance: .pivotal, coreFlags: [.encouraging], lastInteractionAge: 18)
        state.npcs[.friend] = NPCState(name: "Jamie", role: .friend, importance: .background, coreFlags: [.fair], lastInteractionAge: 17)

        #expect(EducationSystem.allowsPivotalReturn(role: .teacher, eventID: "mentor-referral", state: state))
        #expect(!EducationSystem.allowsPivotalReturn(role: .teacher, eventID: "school-reunion", state: state))
        #expect(!EducationSystem.allowsPivotalReturn(role: .friend, eventID: "school-reunion", state: state))
        let beforeFriend = state.npcs[.friend]
        var social = SocialReactivitySystem()
        let reunion = LifeEventRegistry.all.first { $0.id == "school-reunion" }!
        _ = social.contextualize(reunion, state: &state)
        #expect(state.npcs[.friend] == beforeFriend)
    }

    @Test func schoolOutcomeOddsAndSocialNudgesRemainRecoverableAndBounded() {
        var strong = LifeState(name: "Strong", seed: 721)
        strong.character.age = 19
        strong.lifeStage = .launch
        strong.education.phase = .leftSchool
        strong.education.launchInfluenceYearsRemaining = 6
        strong.education.legacySnapshot = SchoolLegacyModifiers(
            jobSearchChanceDelta: 8,
            socialActionDelta: 1,
            yearsRemaining: 7
        )
        var rough = strong
        rough.character.name = "Rough"
        rough.education.legacySnapshot = SchoolLegacyModifiers(
            jobSearchChanceDelta: -8,
            socialActionDelta: -1,
            yearsRemaining: 7
        )
        let world = WorldSystem.modifiers(for: strong.world)
        let strongChance = CareerSystem.jobSearchChance(state: strong, world: world)
        let roughChance = CareerSystem.jobSearchChance(state: rough, world: world)

        #expect(strongChance > roughChance)
        #expect((5...85).contains(strongChance))
        #expect((5...85).contains(roughChance))
        #expect(strongChance - roughChance <= 16)

        let socialAction = DomainActionRegistry.action(for: .seeFriends)
        var social = SocialReactivitySystem()
        let strongLove = strong.stats.love
        let roughLove = rough.stats.love
        _ = social.applySchoolLegacy(for: socialAction, state: &strong)
        _ = social.applySchoolLegacy(for: socialAction, state: &rough)
        #expect(strong.stats.love - strongLove == 1)
        #expect(rough.stats.love - roughLove == -1)
    }

    @Test func schoolMemoryAppearsInEchoAndLifeReview() {
        var state = LifeState(name: "Remembered", seed: 720)
        state.character.age = 30
        state.education.highSchoolDiploma = true
        state.education.postSchoolPath = .scholarship
        state.education.commitmentYears = [.academics: 3]
        state.education.legacyFlags = [.recommendationEarned]

        #expect(EchoFlavorResolver.line(state: state)?.contains("school") == true)
        let review = LifeReviewModel.build(from: state)
        #expect(review.educationLine.contains("diploma earned"))
        #expect(review.educationLine.contains("scholarship"))
        #expect(review.educationLine.contains("chasing grades"))
        #expect(review.educationLine.contains("put their name behind your future"))
    }

    @Test func collegeEnrollmentFieldAndStateRoundTrip() throws {
        var state = LifeState(name: "College", seed: 730, startingAge: 14)
        state.character.age = 18
        state.education.highSchoolDiploma = true
        state.education.phase = .awaitingDecision

        let enrollment = EducationSystem.resolve(.enroll(.publicUniversity), state: &state)
        #expect(enrollment.followUp == .chooseField)
        #expect(state.education.college.status == .awaitingField)
        #expect(state.education.college.credits == 1)
        #expect(state.flags.attendsSchool)
        _ = EducationSystem.resolve(.chooseField(.business), state: &state)
        #expect(state.education.college.status == .enrolled)
        #expect(state.education.college.field == .business)

        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(restored.education.college == state.education.college)
        #expect(restored.education.credentialKind == .none)
    }

    @Test func collegeTuitionStandingCompletionTransferAndAgeExitStayDeterministic() {
        var publicState = LifeState(name: "Public", seed: 731, startingAge: 14)
        publicState.character.age = 19
        publicState.education.phase = .postsecondary
        publicState.flags.attendsSchool = true
        publicState.education.college = CollegeState(status: .enrolled, institution: .publicUniversity, field: .appliedTechnical, credits: 5, academicStanding: 55, campusBelonging: 50, lastTuitionAge: 18)
        publicState.actionUsage[ActionID.study.rawValue] = 18
        publicState.actionUsage[ActionID.attendClass.rawValue] = 18
        let random = publicState.random
        let year = EducationSystem.resolveYear(state: &publicState)
        #expect(year.graduationTransition?.finance.studentDebtDelta == 4_500)
        #expect(publicState.education.college.academicStanding == 59)
        #expect(publicState.education.college.yearsEnrolled == 1)
        #expect(publicState.random == random)
        let repeated = EducationSystem.resolveYear(state: &publicState)
        #expect(repeated.graduationTransition == nil)

        var community = publicState
        community.character.age = 20
        community.education.college = CollegeState(status: .enrolled, institution: .communityCollege, field: .peopleCreative, credits: 8, academicStanding: 60, campusBelonging: 55, lastTuitionAge: 20)
        let completion = EducationSystem.resolveYear(state: &community)
        #expect(completion.followUp == .communityCompletion)
        #expect(community.education.credentialKind == .associateDegree)
        _ = EducationSystem.resolve(.transferToUniversity, state: &community)
        #expect(community.education.college.institution == .publicUniversity)
        #expect(community.education.college.credits == 8)
        #expect(community.education.college.status == .enrolled)

        community.education.college.credits = 12
        community.education.college.academicStanding = 60
        community.education.college.lastTuitionAge = 21
        community.character.age = 21
        let bachelor = EducationSystem.resolveYear(state: &community)
        #expect(bachelor.milestoneHeadline == "You Finished The Degree")
        #expect(community.education.credentialKind == .bachelorsDegree)

        var unfinished = publicState
        unfinished.character.age = 25
        unfinished.education.credential = false
        unfinished.education.credentialKind = .none
        unfinished.education.college.credits = 7
        let exit = EducationSystem.resolveYear(state: &unfinished)
        #expect(exit.milestoneHeadline == "College Time Ran Out")
        #expect(unfinished.education.college.status == .withdrawn)
        #expect(!unfinished.education.credential)
    }

    @Test func collegeProbationIsAChoiceAndDeferredApplicationsRemainOpen() {
        var state = LifeState(name: "Probation", seed: 732, startingAge: 14)
        state.character.age = 19
        state.education.phase = .postsecondary
        state.flags.attendsSchool = true
        state.education.college = CollegeState(status: .enrolled, institution: .communityCollege, field: .business, credits: 3, academicStanding: 42, campusBelonging: 40, lastTuitionAge: 18)
        let year = EducationSystem.resolveYear(state: &state)
        #expect(year.followUp == .probation)
        #expect(state.education.college.status == .probation)
        _ = EducationSystem.resolve(.recoverProbation, state: &state)
        #expect(state.education.college.status == .enrolled)
        #expect(state.education.college.academicStanding == 42)

        var deferred = LifeState(name: "Deferred", seed: 733, startingAge: 14)
        deferred.character.age = 22
        deferred.lifeStage = .launch
        deferred.flags.attendsSchool = false
        deferred.education.phase = .leftSchool
        deferred.education.highSchoolDiploma = true
        deferred.education.postSchoolPath = .work
        let simulator = isolatedSimulator(state: deferred)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .applyToCollege)) == .available)
        _ = simulator.execute(.applyToCollege)
        #expect(simulator.state.pendingEvent?.id == "college-application-22")
        #expect((simulator.state.pendingEvent?.choices.count ?? 0) <= 3)
    }

    @Test func typedCredentialsSoftlyImproveMatchingCareers() {
        var state = LifeState(name: "Credential", seed: 734)
        state.education.credential = true
        state.education.credentialKind = .bachelorsDegree
        state.education.credentialField = .appliedTechnical
        state.career.track = .trades
        let world = WorldSystem.modifiers(for: state.world)
        let matching = CareerSystem.jobSearchChance(state: state, world: world)
        state.career.track = .careService
        let mismatched = CareerSystem.jobSearchChance(state: state, world: world)
        state.education.credential = false
        state.education.credentialKind = .none
        let none = CareerSystem.jobSearchChance(state: state, world: world)
        #expect(matching > mismatched)
        #expect(mismatched > none)
        #expect(matching - none <= 6)
    }

    @Test func educationRecoveryOffersStayCompactDeterministicAndAgeFlexible() {
        var noDiploma = LifeState(name: "Second chance", seed: 735)
        noDiploma.character.age = 30
        noDiploma.lifeStage = .build
        noDiploma.flags.attendsSchool = false
        noDiploma.education.phase = .leftSchool
        noDiploma.education.highSchoolDiploma = false
        let random = noDiploma.random
        #expect(EducationSystem.recoveryOffers(for: noDiploma).map(\.transition) == [
            .beginRecovery(.alternativeCredential), .beginRecovery(.technicalCertificate), .keepCurrentPath
        ])
        #expect(noDiploma.random == random)

        noDiploma.education.highSchoolDiploma = true
        #expect(EducationSystem.recoveryOffers(for: noDiploma).first?.transition == .enrollAdultCommunity)

        noDiploma.education.college = CollegeState(
            status: .withdrawn,
            institution: .publicUniversity,
            field: .business,
            credits: 5,
            academicStanding: 35
        )
        #expect(EducationSystem.recoveryOffers(for: noDiploma).first?.transition == .resumeCollege)

        let simulator = isolatedSimulator(state: noDiploma)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .returnToEducation)) == .available)
        _ = simulator.execute(.returnToEducation)
        #expect(simulator.state.pendingEvent?.id == "education-recovery-30")
        #expect((simulator.state.pendingEvent?.choices.count ?? 0) <= 3)
    }

    @Test func shortRecoveryTracksCompleteWithoutAnotherLedger() {
        var certificate = LifeState(name: "Certificate", seed: 736)
        certificate.character.age = 30
        certificate.lifeStage = .build
        certificate.flags.attendsSchool = false
        certificate.education.phase = .leftSchool
        _ = EducationSystem.resolve(.beginRecovery(.technicalCertificate), state: &certificate)
        #expect(certificate.education.recovery.isActive)
        #expect(certificate.flags.attendsSchool)
        ProgressionSystem.resolve(action: DomainActionRegistry.action(for: .study), state: &certificate)
        ProgressionSystem.resolve(action: DomainActionRegistry.action(for: .attendClass), state: &certificate)
        certificate.character.age = 31
        ProgressionSystem.resolve(action: DomainActionRegistry.action(for: .study), state: &certificate)
        let completed = EducationSystem.resolveYear(state: &certificate)
        #expect(completed.graduationTransition?.finance.studentDebtDelta == 1_000)
        #expect(completed.milestoneHeadline == "The Technical Certificate Is Yours")
        #expect(certificate.education.credentialKind == .professionalCertificate)
        #expect(certificate.education.credentialField == .appliedTechnical)
        #expect(!certificate.flags.attendsSchool)

        var alternative = LifeState(name: "Alternative", seed: 737)
        alternative.character.age = 35
        alternative.lifeStage = .build
        alternative.education.phase = .leftSchool
        _ = EducationSystem.resolve(.beginRecovery(.alternativeCredential), state: &alternative)
        alternative.education.recovery.progress = 6
        let alternativeCompletion = EducationSystem.resolveYear(state: &alternative)
        #expect(alternativeCompletion.graduationTransition == nil)
        #expect(alternative.education.hasAlternativeCredential)
        #expect(EducationSystem.recoveryOffers(for: alternative).first?.transition == .enrollAdultCommunity)
        #expect(EducationSystem.legacyModifiers(for: alternative) == SchoolLegacyModifiers())
    }

    @Test func adultCollegeReentryPreservesCreditsDebtAndSurvivesLaunchCutoff() {
        var state = LifeState(name: "Returner", seed: 738)
        state.character.age = 32
        state.lifeStage = .build
        state.flags.attendsSchool = false
        state.education.phase = .leftSchool
        state.education.highSchoolDiploma = true
        state.education.college = CollegeState(
            status: .withdrawn,
            institution: .publicUniversity,
            field: .peopleCreative,
            credits: 5,
            academicStanding: 35,
            campusBelonging: 30,
            yearsEnrolled: 2,
            lastTuitionAge: 24
        )
        state.finance.studentDebt = 90
        let random = state.random
        _ = EducationSystem.resolve(.resumeCollege, state: &state)
        #expect(state.education.college.credits == 5)
        #expect(state.finance.studentDebt == 90)
        #expect(state.education.college.adultReentryAge == 32)
        state.character.age = 33
        state.actionUsage[ActionID.study.rawValue] = 32
        let year = EducationSystem.resolveYear(state: &state)
        #expect(state.education.college.status == .enrolled)
        #expect(year.graduationTransition?.finance.studentDebtDelta == 4_500)
        #expect(state.random == random)
    }

    @Test func everyActionHasAConsistentOutcomeForTheSameSeed() {
        for action in DomainActionRegistry.all {
            let first = isolatedSimulator(state: executableState(for: action, seed: 42))
            let second = isolatedSimulator(state: executableState(for: action, seed: 42))
            let before = first.state
            let firstHistoryCount = first.state.history.count
            let immediateOutcome = first.execute(action.id)
            second.execute(action.id)
            #expect(first.state.history.count == firstHistoryCount + 1, "\(action.id) did not execute end to end")
            #expect(first.state.usedActionThisAge(action.id), "\(action.id) did not record usage")
            #expect(immediateOutcome != nil, "\(action.id) did not return an immediate outcome")
            #expect(immediateOutcome == first.lastOutcome, "\(action.id) returned a stale outcome")
            #expect(first.state == second.state)
            if let immediateOutcome {
                #expect(immediateOutcome.deltas.school == first.state.stats.school - before.stats.school, "\(action.id) reported the wrong School delta")
                #expect(immediateOutcome.deltas.cash == first.state.cash - before.cash, "\(action.id) reported the wrong Cash delta")
                #expect(immediateOutcome.deltas.love == first.state.stats.love - before.stats.love, "\(action.id) reported the wrong Love delta")
                #expect(immediateOutcome.deltas.play == first.state.stats.play - before.stats.play, "\(action.id) reported the wrong Play delta")
                #expect(immediateOutcome.deltas.health == first.state.stats.health - before.stats.health, "\(action.id) reported the wrong Health delta")
                #expect(immediateOutcome.deltas.looks == first.state.stats.looks - before.stats.looks, "\(action.id) reported the wrong Looks delta")
                #expect(immediateOutcome.deltas.rep == first.state.stats.rep - before.stats.rep, "\(action.id) reported the wrong Rep delta")
                if let beforePartner = before.partner, let afterPartner = first.state.partner {
                    #expect(immediateOutcome.deltas.bond == afterPartner.bond - beforePartner.bond, "\(action.id) reported the wrong Bond delta")
                    #expect(immediateOutcome.deltas.resentment == afterPartner.resentment - beforePartner.resentment, "\(action.id) reported the wrong Resentment delta")
                }
            }
        }
    }

    @Test func clampedEffectsReportOnlyTheMutationThatActuallyLanded() {
        var state = LifeState(name: "Boundary", seed: 1_202)
        state.stats.health = 0
        state.stats.play = 100
        state.cash = 0

        let actual = EffectResolutionSystem.apply(
            DeltaSummary(cash: -80, play: 6, health: -5),
            state: &state
        )

        #expect(actual.cash == 0)
        #expect(actual.play == 0)
        #expect(actual.health == 0)
        #expect(actual.isEmpty)
        #expect(state.finance.consumerDebt == 80)
    }

    @Test func genericEffectsNormalizeOnlyTheDomainsTheyOwn() {
        var state = LifeState(name: "Scoped normalization", seed: 1_204)
        state.career.performance = 140
        state.finance.financialStress = 140
        state.family.caregivingLoad = 140
        state.legal.firearmHeat = 140
        let originalPlay = state.stats.play

        _ = EffectResolutionSystem.apply(DeltaSummary(play: 1), state: &state)

        #expect(state.stats.play == originalPlay + 1)
        #expect(state.career.performance == 140)
        #expect(state.finance.financialStress == 140)
        #expect(state.family.caregivingLoad == 140)
        #expect(state.legal.firearmHeat == 140)
    }

    @Test func yearlyOutcomeDeltasMatchTheStateThatActuallyLanded() throws {
        var state = LifeState(name: "Year Boundary", seed: 1_203)
        state.stats = LifeStats(school: 100, love: 100, play: 0, health: 100, looks: 0, rep: 100)
        state.cash = -500
        state.flags.attendsSchool = false
        let simulator = isolatedSimulator(state: state)
        let before = simulator.state

        simulator.ageUp()
        let outcome = try #require(simulator.lastOutcome)

        #expect(outcome.isYearly)
        #expect(outcome.deltas.school == simulator.state.stats.school - before.stats.school)
        #expect(outcome.deltas.cash == simulator.state.cash - before.cash)
        #expect(outcome.deltas.love == simulator.state.stats.love - before.stats.love)
        #expect(outcome.deltas.play == simulator.state.stats.play - before.stats.play)
        #expect(outcome.deltas.health == simulator.state.stats.health - before.stats.health)
        #expect(outcome.deltas.looks == simulator.state.stats.looks - before.stats.looks)
        #expect(outcome.deltas.rep == simulator.state.stats.rep - before.stats.rep)
    }

    @Test func presentedEventKindDefaultsLegacyPayloadsToInstantAndRoundTripsYearly() throws {
        let choice = EventChoice(
            id: .accept,
            title: "Accept",
            detail: "Take the risk.",
            effects: EffectRange(),
            partnerEffect: PartnerEffect(),
            narrative: "You accepted."
        )
        let yearly = PresentedEvent(
            id: "kind-test",
            headline: "A Decision Arrives This Year",
            detail: "The moment requires an answer.",
            choices: [choice],
            yearDeltas: DeltaSummary(cash: 10),
            isPartnerEvent: false,
            kind: .yearly
        )
        let encoded = try JSONEncoder().encode(yearly)
        #expect(try JSONDecoder().decode(PresentedEvent.self, from: encoded).kind == .yearly)

        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json.removeValue(forKey: "kind")
        let legacy = try JSONSerialization.data(withJSONObject: json)
        #expect(try JSONDecoder().decode(PresentedEvent.self, from: legacy).kind == .instant)
    }

    @Test func eventKindControlsYearlyFinalizationAndInstantChoicesLeaveTheRecapAlone() throws {
        let choice = EventChoice(
            id: .accept,
            title: "Take it",
            detail: "Commit without certainty.",
            effects: EffectRange(cash: 3...3),
            partnerEffect: PartnerEffect(),
            narrative: "You committed."
        )
        let event = LifeEvent(
            id: "event-kind-resolution",
            headline: "A Narrow Window Opens Today",
            detail: "The offer will not wait.",
            weight: { _ in 0 },
            choices: [choice]
        )

        var yearlyState = LifeState(name: "Yearly", seed: 1_204)
        yearlyState.lastYearSummary = YearSummarySystem.compose(
            age: yearlyState.character.age,
            headline: event.headline,
            bullets: [event.headline],
            deltas: DeltaSummary(cash: 5),
            stanceTitle: nil,
            shapeTitle: nil,
            focusNote: nil,
            silenceNote: nil,
            wasQuiet: false
        )
        yearlyState.pendingEvent = PresentedEvent(event, yearDeltas: DeltaSummary(cash: 5), kind: .yearly)
        let yearly = isolatedSimulator(state: yearlyState)
        yearly.execute(.accept)
        let yearlyOutcome = try #require(yearly.lastOutcome)
        #expect(yearlyOutcome.isYearly)
        #expect(yearlyOutcome.deltas.cash == 8)
        #expect(yearly.state.lastYearSummary?.deltas.cash == 8)

        var instantState = LifeState(name: "Instant", seed: 1_205)
        let preservedSummary = YearSummarySystem.compose(
            age: instantState.character.age,
            headline: "The Previous Year",
            bullets: ["Nothing was rewritten"],
            deltas: DeltaSummary(health: 1),
            stanceTitle: nil,
            shapeTitle: nil,
            focusNote: nil,
            silenceNote: nil,
            wasQuiet: false
        )
        instantState.lastYearSummary = preservedSummary
        instantState.pendingEvent = PresentedEvent(event, kind: .instant)
        let instant = isolatedSimulator(state: instantState)
        instant.execute(.accept)
        #expect(instant.lastOutcome?.isYearly == false)
        #expect(instant.lastOutcome?.yearSummary == nil)
        #expect(instant.state.lastYearSummary == preservedSummary)
    }

    @Test func yearlyEducationFollowUpsPreserveKindAndAccumulatedYearDeltas() throws {
        var state = LifeState(name: "Graduate", seed: 1_206, startingAge: 14)
        state.character.age = 18
        state.education.highSchoolDiploma = true
        state.education.phase = .awaitingDecision
        state.flags.attendsSchool = false
        let event = EducationSystem.offerEvent(
            id: "yearly-college-offer",
            headline: "Your College Options Finally Arrive",
            detail: "One route remains open.",
            offers: [
                PostSchoolOffer(
                    title: "Choose public university",
                    detail: "Take the direct degree route.",
                    transition: .enroll(.publicUniversity)
                )
            ]
        )
        let yearDeltas = DeltaSummary(cash: 7, health: -2)
        state.lastYearSummary = YearSummarySystem.compose(
            age: 18,
            headline: event.headline,
            bullets: [event.headline],
            deltas: yearDeltas,
            stanceTitle: nil,
            shapeTitle: nil,
            focusNote: nil,
            silenceNote: nil,
            wasQuiet: false
        )
        state.pendingEvent = PresentedEvent(event, yearDeltas: yearDeltas, kind: .yearly)
        let simulator = isolatedSimulator(state: state)

        simulator.execute(.focus)
        let followUp = try #require(simulator.state.pendingEvent)
        #expect(followUp.kind == .yearly)
        #expect(followUp.yearDeltas.cash == 7)
        #expect(followUp.yearDeltas.health == -2)

        simulator.execute(.focus)
        #expect(simulator.state.pendingEvent == nil)
        #expect(simulator.lastOutcome?.isYearly == true)
        #expect(simulator.lastOutcome?.deltas.cash == 7)
        #expect(simulator.lastOutcome?.deltas.health == -2)
        #expect(simulator.state.lastYearSummary?.deltas.cash == 7)
    }

    @Test func yearSummaryCompositionRanksImpactsDeduplicatesAndClassifiesWeight() {
        let deltas = DeltaSummary(cash: 90, love: 5, health: -10, resentment: -3)
        let summary = YearSummarySystem.compose(
            age: 33,
            headline: "A Difficult Year Finally Landed",
            bullets: ["Health -10", "Promotion earned", "promotion earned", "A relationship held"],
            deltas: deltas,
            stanceTitle: "Push Career",
            shapeTitle: "Driven",
            focusNote: nil,
            silenceNote: nil,
            wasQuiet: false
        )
        #expect(summary.importance == .major)
        #expect(summary.developments.map(\.text) == ["Promotion earned", "A relationship held"])
        let impacts = YearSummarySystem.rankedImpacts(deltas)
        #expect(impacts.map(\.label) == ["Health", "Cash", "Happy", "Resentment"])
        #expect(impacts.last?.beneficial == true)

        let quiet = YearSummarySystem.compose(
            age: 34,
            headline: "Another Year",
            bullets: [],
            deltas: DeltaSummary(),
            stanceTitle: nil,
            shapeTitle: nil,
            focusNote: nil,
            silenceNote: "Life moved quietly.",
            wasQuiet: true
        )
        #expect(quiet.importance == .quiet)
        let critical = YearSummarySystem.compose(
            age: 70,
            headline: "Your Body Demands An Answer",
            bullets: [],
            deltas: DeltaSummary(health: -2),
            stanceTitle: nil,
            shapeTitle: nil,
            focusNote: nil,
            silenceNote: nil,
            wasQuiet: false,
            mortalityWarning: "Mortality pressure is critical."
        )
        #expect(critical.importance == .critical)
    }

    @Test func registryCoversEveryActionExactlyOnceWithPlayableMetadata() {
        #expect(DomainActionRegistry.all.count == ActionID.allCases.count)
        #expect(Set(DomainActionRegistry.all.map(\.id)) == Set(ActionID.allCases))
        for action in DomainActionRegistry.all {
            #expect(!action.name.isEmpty)
            #expect(!action.shortDescription.isEmpty)
            #expect(!action.narrative.isEmpty)
            #expect(!action.microBeat.isEmpty)
            #expect(!action.effects.previewLines.isEmpty || action.domainEffects != nil)
        }
    }

    @Test func sovereignInstantProcessorsOwnDeterministicDomainMutations() {
        let effects = EffectRange(
            school: 2...5,
            cash: -20 ... -10,
            love: 1...3,
            play: 0...2,
            health: -2 ... -1,
            looks: 0...1,
            rep: 1...2
        )
        var first = LifeState(name: "Systems A", seed: 7_171)
        var second = LifeState(name: "Systems B", seed: 7_171)
        let firstDeltas = EffectResolutionSystem.apply(effects, state: &first)
        let secondDeltas = EffectResolutionSystem.apply(effects, state: &second)
        #expect(firstDeltas == secondDeltas)
        #expect(first.stats == second.stats)
        #expect(first.cash == second.cash)
        #expect(first.random == second.random)

        first.education.progress = 10
        first.stats.school = 60
        ProgressionSystem.resolve(action: DomainActionRegistry.action(for: .study), state: &first)
        #expect(first.education.progress == 12)
        #expect(first.education.credential)

        ProgressionSystem.resolve(action: DomainActionRegistry.action(for: .applyForBetterWork), state: &first)
        #expect(first.job.tier == .skilled)
        #expect(first.flags.hasJob)

        let beforeInfluence = first.influenceLedger.current
        InfluenceSystem.record(action: DomainActionRegistry.action(for: .study), state: &first)
        #expect(first.influenceLedger.current != beforeInfluence)
        #expect(first.momentum.intensity > 0)
    }

    @Test func lockedRequirementsDoNotChangeState() {
        let simulator = isolatedSimulator(state: LifeState(name: "A", seed: 1))
        let before = simulator.state
        simulator.execute(.repairConflict)
        #expect(simulator.state == before)
    }

    @Test func careerUpgradeRequirementMutationAndNarrativeStayAligned() throws {
        var unqualified = LifeState(name: "Career", seed: 1_101)
        unqualified.stats.school = 70
        let locked = isolatedSimulator(state: unqualified)
        let before = locked.state
        #expect(locked.execute(.applyForBetterWork) == nil)
        #expect(locked.state == before)
        #expect(locked.availability(for: DomainActionRegistry.action(for: .applyForBetterWork)) == .locked("Requires a credential"))

        var qualified = unqualified
        qualified.education.credential = true
        let simulator = isolatedSimulator(state: qualified)
        let outcome = try #require(simulator.execute(.applyForBetterWork))
        #expect(simulator.state.job.tier == .skilled)
        #expect(simulator.state.flags.hasJob)
        #expect(outcome.narrative.contains("Skilled work is now your lane"))
        #expect(outcome == simulator.lastOutcome)
    }

    @Test func ageUpTenTimesKeepsTheStateValid() {
        let simulator = isolatedSimulator(state: LifeState(name: "A", seed: 9))
        for _ in 0..<10 {
            simulator.ageUp()
            if let event = simulator.state.pendingEvent { simulator.execute(event.choices[0].id) }
        }
        #expect(simulator.state.character.age == 28)
        #expect((0...100).contains(simulator.state.stats.school))
        #expect((0...100).contains(simulator.state.stats.health))
        #expect(simulator.state.cash >= 0)
    }

    @Test func jobAndPartnerFlagsFollowCanonicalDomainState() throws {
        var state = LifeState(name: "Invariants", seed: 1_303)
        #expect(state.job.tier == .entry)
        #expect(state.flags.hasJob)
        #expect(!state.flags.hasPartner)

        state.flags.hasJob = false
        state.flags.hasPartner = true
        state.partner = nil
        state.clamp()
        #expect(state.flags.hasJob)
        #expect(!state.flags.hasPartner)

        state.job.tier = .unemployed
        state.partner = PartnerState(compatibility: 60)
        state.clamp()
        #expect(!state.flags.hasJob)
        #expect(state.flags.hasPartner)

        let data = try JSONEncoder().encode(state)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var flags = try #require(json["flags"] as? [String: Any])
        flags["hasJob"] = true
        flags["hasPartner"] = false
        json["flags"] = flags
        let decoded = try JSONDecoder().decode(
            LifeState.self,
            from: JSONSerialization.data(withJSONObject: json)
        )
        #expect(!decoded.flags.hasJob)
        #expect(decoded.flags.hasPartner)
    }

    @Test func ageUpCanResolveWithoutAnEligibleEvent() {
        var state = LifeState(name: "A", seed: 3)
        state.stats = LifeStats(school: 50, love: 100, play: 100, health: 100)
        state.cash = 400
        state.flags.attendsSchool = false // avoid school-pressure / graduation noise
        let simulator = isolatedSimulator(state: state)
        simulator.ageUp()
        #expect(!simulator.state.isGameOver)
        #expect(simulator.state.isValidSave)
        // Either a quiet journal year or a single major beat sheet — never a soft-lock.
        if simulator.state.pendingEvent == nil {
            #expect(simulator.state.history.isEmpty == false)
        }
    }

    @Test func systemRegistryHibernatesStateContingentDomains() {
        var state = LifeState(name: "Active", seed: 4)
        let launch = SystemRegistry.activeSystems(in: state)
        #expect(SystemRegistry.coreSystems.isSubset(of: launch))
        #expect(!launch.contains(.mortality))
        #expect(!launch.contains(.social))

        state.partner = PartnerState(name: "Morgan", startedAge: 18, compatibility: 60)
        #expect(SystemRegistry.isActive(.social, in: state))

        state.partner = nil
        state.character.age = 70
        state.lifeStage = .legacy
        #expect(SystemRegistry.isActive(.mortality, in: state))
        #expect(!SystemRegistry.isActive(.social, in: state))
    }

    @Test func instantSystemRegistryWakesOnlyRelevantProcessors() {
        let state = LifeState(name: "Instant", seed: 5)
        let budget = SystemRegistry.activeInstantSystems(
            for: DomainActionRegistry.action(for: .budget),
            in: state
        )
        #expect(budget == [.effects, .narrative, .influence, .personality])

        let work = SystemRegistry.activeInstantSystems(
            for: DomainActionRegistry.action(for: .workShift),
            in: state
        )
        #expect(work.contains(.progression))
        #expect(work.contains(.social))
        #expect(!work.contains(.recovery))

        let soloReachOut = SystemRegistry.activeInstantSystems(
            for: DomainActionRegistry.action(for: .reachOut),
            in: state
        )
        #expect(!soloReachOut.contains(.social))

        var crisis = state
        crisis.recovery = RecoveryWindow(kind: .financial, openedAge: state.character.age)
        let recovery = SystemRegistry.activeInstantSystems(
            for: DomainActionRegistry.action(for: .budget),
            in: crisis
        )
        #expect(recovery.contains(.recovery))

        let irrelevantToCrisis = SystemRegistry.activeInstantSystems(
            for: DomainActionRegistry.action(for: .pursueHobby),
            in: crisis
        )
        #expect(!irrelevantToCrisis.contains(.recovery))
    }

    @Test func zeroEffectsDoNotAdvanceTheSeededRandomStream() {
        var state = LifeState(name: "No-op", seed: 6)
        let before = state.random
        let deltas = EffectResolutionSystem.apply(EffectRange(), state: &state)
        #expect(deltas.isEmpty)
        #expect(state.random == before)
    }

    @Test func aFixedSeedReplaysExactly() {
        let actions: [ActionID] = [.study, .workShift, .reachOut, .exercise]
        let first = isolatedSimulator(state: LifeState(name: "A", seed: 88))
        let second = isolatedSimulator(state: LifeState(name: "A", seed: 88))
        for action in actions { first.execute(action); second.execute(action) }
        first.ageUp(); second.ageUp()
        if let event = first.state.pendingEvent { first.execute(event.choices[0].id) }
        if let event = second.state.pendingEvent { second.execute(event.choices[0].id) }
        if first.state != second.state {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
            let left = (try? encoder.encode(first.state)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let right = (try? encoder.encode(second.state)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let index = Array(zip(left, right)).firstIndex { $0 != $1 } ?? 0
            Issue.record("REPLAY FIRST DIFF \(index): \(String(left.dropFirst(max(0, index - 120)).prefix(450))) | \(String(right.dropFirst(max(0, index - 120)).prefix(450)))")
        }
        #expect(first.state == second.state)
    }

    @Test func runSeedSurvivesRandomDrawsAndPersistence() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-seed-\(UUID().uuidString).json")
        let persistence = LifePersistence(saveURL: url)
        let simulator = LifeSimulator(state: LifeState(name: "Seed", seed: 9_876), store: persistence)
        simulator.execute(.workShift)
        simulator.saveForLifecycle()
        #expect(simulator.state.randomStreams.action.drawCount > 0)
        #expect(simulator.state.random.drawCount == 0)
        #expect(simulator.state.runSeed == 9_876)
        if case .loaded(let loaded) = persistence.load() {
            #expect(loaded.runSeed == 9_876)
            #expect(loaded.random == simulator.state.random)
            #expect(loaded.randomStreams == simulator.state.randomStreams)
        } else {
            Issue.record("Seeded save should load")
        }
        try? FileManager.default.removeItem(at: url)
    }

    @Test func lifecycleFlushCannotBeOverwrittenByAnOlderQueuedSave() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-ordered-save-\(UUID().uuidString).json")
        let persistence = LifePersistence(saveURL: url)
        let simulator = LifeSimulator(state: LifeState(name: "Ordered", seed: 8_888), store: persistence)
        simulator.execute(.workShift)
        simulator.execute(.budget)
        simulator.saveForLifecycle()

        if case .loaded(let loaded) = persistence.load() {
            #expect(loaded == simulator.state)
            #expect(loaded.usedActionThisAge(.workShift))
            #expect(loaded.usedActionThisAge(.budget))
        } else {
            Issue.record("Newest queued snapshot should load")
        }
        try? FileManager.default.removeItem(at: url)
    }

    @Test func abandoningLifeDrainsQueuedSavesBeforeClearingTheSlot() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-abandon-\(UUID().uuidString).json")
        let persistence = LifePersistence(saveURL: url)
        let simulator = LifeSimulator(state: LifeState(name: "Abandoned", seed: 8_889), store: persistence)

        simulator.execute(.workShift)
        simulator.execute(.budget)
        simulator.abandonLife()

        #expect(!FileManager.default.fileExists(atPath: url.path))
        if case .freshStart(let message) = persistence.load() {
            #expect(message == nil)
        } else {
            Issue.record("An abandoned life must not be resurrected by queued saves")
        }
    }

    @Test func rapidActionsCoalesceQueuedPersistenceToTheNewestSnapshot() async {
        let persistence = BlockingPersistence()
        let simulator = LifeSimulator(state: LifeState(name: "Coalesce", seed: 8_890), store: persistence)

        simulator.execute(.workShift)
        #expect(await persistence.waitUntilFirstStarts())
        simulator.execute(.budget)
        #expect(simulator.execute(.rest) != nil)
        persistence.allowFirstToFinish()
        #expect(await persistence.waitUntilSecondFinishes())

        let snapshots = persistence.snapshots
        #expect(snapshots.count == 2)
        #expect(snapshots[0].usedActionThisAge(.workShift))
        #expect(!snapshots[0].usedActionThisAge(.budget))
        #expect(snapshots[1].usedActionThisAge(.workShift))
        #expect(snapshots[1].usedActionThisAge(.budget))
        #expect(snapshots[1].usedActionThisAge(.rest))
    }

    @Test func pureSimulationCanSkipAutomaticPersistenceWithoutDisablingExplicitSaves() {
        let persistence = ManualPersistence()
        let simulator = LifeSimulator(
            state: LifeState(name: "Pure simulation", seed: 8_891),
            store: persistence
        )

        #expect(simulator.execute(.workShift) != nil)
        #expect(persistence.saveCount == 0)

        simulator.saveForLifecycle()
        #expect(persistence.saveCount == 1)
    }

    @Test func fiftyAndEightyYearLivesAreDeterministic() {
        for years in [50, 80] {
            let first = isolatedSimulator(state: LifeState(name: "A", seed: 700))
            let second = isolatedSimulator(state: LifeState(name: "A", seed: 700))
            for _ in 0..<years {
                first.execute(.workShift); second.execute(.workShift)
                first.ageUp(); second.ageUp()
                if let event = first.state.pendingEvent { first.execute(event.choices[0].id) }
                if let event = second.state.pendingEvent { second.execute(event.choices[0].id) }
                if first.state.isGameOver || second.state.isGameOver { break }
            }
            #expect(first.state == second.state)
            #expect(first.state.history.count <= 40)
        }
    }

    @Test func playtestRecordingDoesNotChangeSeededGameplay() {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-playtest-parity-\(UUID().uuidString)", isDirectory: true)
        let recorder = FilePlaytestRecorder(baseURL: directory)
        let initial = LifeState(name: "Parity", seed: 44_001)
        let recorded = LifeSimulator(
            state: initial,
            store: LifePersistence(saveURL: directory.appendingPathComponent("recorded-save.json")),
            playtestRecorder: recorder,
            playtestOrigin: .balanced
        )
        let plain = LifeSimulator(
            state: initial,
            store: LifePersistence(saveURL: directory.appendingPathComponent("plain-save.json"))
        )

        for action in [ActionID.study, .workShift, .reachOut, .exercise] {
            recorded.execute(action)
            plain.execute(action)
        }
        recorded.ageUp()
        plain.ageUp()
        if let event = recorded.state.pendingEvent { recorded.execute(event.choices[0].id) }
        if let event = plain.state.pendingEvent { plain.execute(event.choices[0].id) }

        #expect(recorded.state == plain.state)
        #expect(recorded.lastOutcome == plain.lastOutcome)
        #expect(recorder.currentReport()?.moments.isEmpty == false)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func playtestReportsResumeExportAndOutliveCappedHistory() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-playtest-report-\(UUID().uuidString)", isDirectory: true)
        var clock = Date(timeIntervalSince1970: 1_700_000_000)
        let recorder = FilePlaytestRecorder(baseURL: directory, now: { clock })
        let state = LifeState(name: "Report", seed: 55_001)
        recorder.startOrResume(seed: state.runSeed, origin: OriginPreset.academic.rawValue, initialState: state)

        let outcome = ActionOutcome(
            headline: "A Test Moment",
            narrative: "A complete diagnostic beat.",
            deltas: DeltaSummary(cash: 10)
        )
        for index in 0..<45 {
            clock.addTimeInterval(5)
            recorder.record(
                source: .action(index.isMultiple(of: 2) ? .study : .budget),
                outcome: outcome,
                state: state
            )
        }
        recorder.annotate(kind: .boring, note: "The loop repeated.", state: state)
        _ = recorder.exportURLs() // drains queued diagnostic persistence before simulating a relaunch

        let resumed = FilePlaytestRecorder(baseURL: directory, now: { clock })
        resumed.startOrResume(seed: state.runSeed, origin: nil, initialState: state)
        #expect(resumed.currentReport()?.moments.count == 45)
        #expect(resumed.currentReport()?.firstBoringAnnotation?.note == "The loop repeated.")

        let urls = resumed.exportURLs()
        #expect(urls.count == 2)
        #expect(urls.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })
        let jsonURL = try #require(urls.first { $0.pathExtension == "json" })
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PlaytestRunReport.self, from: Data(contentsOf: jsonURL))
        #expect(decoded.moments.count == 45)
        #expect(decoded.markdown.contains("The loop repeated."))
        #expect(decoded.counts(for: .instantAction).first?.1 == 23)
        #expect(decoded.sandboxDiagnostics.proactiveActionCount == 45)
        #expect(decoded.sandboxDiagnostics.uniqueActionCount == 2)
        #expect(decoded.sandboxDiagnostics.actionCountsByDomain.contains { $0.domain == Domain.school.rawValue && $0.count == 23 })
        #expect(decoded.sandboxDiagnostics.actionCountsByDomain.contains { $0.domain == Domain.cash.rawValue && $0.count == 22 })
        #expect(decoded.markdown.contains("## Sandbox Health"))

        var legacyJSON = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: jsonURL)) as? [String: Any])
        legacyJSON["schemaVersion"] = 1
        legacyJSON.removeValue(forKey: "playStyle")
        if var moments = legacyJSON["moments"] as? [[String: Any]] {
            for index in moments.indices {
                if var source = moments[index]["source"] as? [String: Any] {
                    source.removeValue(forKey: "domain")
                    moments[index]["source"] = source
                }
                guard var snapshot = moments[index]["state"] as? [String: Any] else { continue }
                snapshot.removeValue(forKey: "worldProfile")
                snapshot.removeValue(forKey: "worldConditions")
                snapshot.removeValue(forKey: "worldHeadline")
                snapshot.removeValue(forKey: "publicHealthProfile")
                snapshot.removeValue(forKey: "publicHealthCondition")
                moments[index]["state"] = snapshot
            }
            legacyJSON["moments"] = moments
        }
        let legacyData = try JSONSerialization.data(withJSONObject: legacyJSON, options: [.sortedKeys])
        let legacyDecoded = try decoder.decode(PlaytestRunReport.self, from: legacyData)
        #expect(legacyDecoded.schemaVersion == 1)
        #expect(legacyDecoded.moments.first?.state.worldProfile == nil)
        #expect(legacyDecoded.moments.first?.source.domain == nil)
        #expect(legacyDecoded.playStyle == nil)
        #expect(legacyDecoded.outcomeAssessment == nil)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func playtestSandboxDiagnosticsExposeDominantLoopsPassiveYearsAndRecovery() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-playtest-sandbox-\(UUID().uuidString)", isDirectory: true)
        let recorder = FilePlaytestRecorder(baseURL: directory)
        var state = LifeState(name: "Sandbox", seed: 55_002, startingAge: 18)
        recorder.startOrResume(seed: state.runSeed, origin: OriginPreset.balanced.rawValue, initialState: state)
        let outcome = ActionOutcome(
            headline: "The Same Move Again",
            narrative: "The routine repeats.",
            deltas: DeltaSummary(cash: 1)
        )

        for _ in 0..<12 {
            recorder.record(source: .action(.workShift), outcome: outcome, state: state)
        }
        state.character.age = 19
        state.recovery = RecoveryWindow(kind: .financial, openedAge: 18)
        recorder.record(source: .yearly, outcome: outcome, state: state)
        state.character.age = 20
        state.recovery = nil
        recorder.record(source: .yearly, outcome: outcome, state: state)
        for age in 21...23 {
            state.character.age = age
            recorder.record(source: .yearly, outcome: outcome, state: state)
        }

        let diagnostics = try #require(recorder.currentReport()?.sandboxDiagnostics)
        #expect(diagnostics.proactiveActionCount == 12)
        #expect(diagnostics.uniqueActionCount == 1)
        #expect(diagnostics.topAction == ActionID.workShift.rawValue)
        #expect(diagnostics.topActionShare == 1)
        #expect(diagnostics.longestRepeatedActionStreak == 12)
        #expect(diagnostics.advancedYearCount == 5)
        #expect(diagnostics.yearsWithoutProactiveAction == [19, 20, 21, 22])
        #expect(diagnostics.recoveryArcsStarted == 1)
        #expect(diagnostics.recoveryArcsResolved == 1)
        #expect(diagnostics.warnings.contains { $0.contains("Dominant loop") })
        #expect(diagnostics.warnings.contains { $0.contains("Passive years") })
        #expect(diagnostics.warnings.contains { $0.contains("Untouched domains") })
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func playtestCohortEnforcesMixDurationAndIndependentRecurringEvidence() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-playtest-cohort-\(UUID().uuidString)", isDirectory: true)
        var clock = Date(timeIntervalSince1970: 1_700_200_000)
        let origins: [OriginPreset] = [
            .balanced, .balanced, .balanced,
            .academic, .academic, .academic,
            .social, .social, .social, .social
        ]
        let styles: [PlaytestStyle] = [
            .grind, .social, .survival, .mixed, .grind,
            .social, .survival, .mixed, .grind, .mixed
        ]
        let outcome = ActionOutcome(
            headline: "The Routine Wins Again",
            narrative: "The same move keeps carrying the year.",
            deltas: DeltaSummary(cash: 1)
        )

        for index in origins.indices {
            var state = LifeState(name: "Cohort \(index)", seed: UInt64(60_000 + index), startingAge: 18)
            let recorder = FilePlaytestRecorder(baseURL: directory, now: { clock })
            recorder.startOrResume(
                seed: state.runSeed,
                origin: origins[index].rawValue,
                initialState: state
            )
            recorder.setPlayStyle(styles[index])
            for _ in 0..<12 {
                recorder.record(source: .action(.workShift), outcome: outcome, state: state)
            }
            if index < 2 {
                recorder.annotate(kind: .weakChoice, note: "Work felt automatic.", state: state)
            }
            clock.addTimeInterval(35 * 60)
            state.isGameOver = true
            state.endReason = .naturalCauses
            recorder.finalize(status: .completed, state: state)
            recorder.assessOutcome(
                explanation: "Repeated work choices traded variety for financial stability.",
                reviewAgrees: true
            )
            _ = recorder.exportURLs()
            clock.addTimeInterval(1)
        }

        let reader = FilePlaytestRecorder(baseURL: directory, now: { clock })
        let analysis = reader.cohortAnalysis()
        #expect(analysis.completedReportCount == 10)
        #expect(analysis.outcomeAssessmentCount == 10)
        #expect(analysis.outcomeAgreementCount == 10)
        #expect(analysis.medianDurationMinutes == 35)
        #expect(analysis.originCounts.first { $0.label == OriginPreset.balanced.rawValue }?.count == 3)
        #expect(analysis.originCounts.first { $0.label == OriginPreset.academic.rawValue }?.count == 3)
        #expect(analysis.originCounts.first { $0.label == OriginPreset.social.rawValue }?.count == 4)
        #expect(analysis.styleCounts.allSatisfy { $0.count > 0 })
        #expect(analysis.recurringSignals.contains { $0.id == "dominant:workShift" && $0.runCount == 10 })
        #expect(analysis.recurringSignals.contains {
            $0.id == "annotation:weakChoice:cash" && $0.seeds.count == 2 && $0.ages == [18]
        })
        #expect(analysis.isReadyForPhase2)
        #expect(analysis.missingRequirements.isEmpty)
        #expect(analysis.nextRecommendation == nil)

        let cohortURL = try #require(reader.exportCohortURL())
        let markdown = try String(contentsOf: cohortURL, encoding: .utf8)
        #expect(markdown.contains("Phase 2 ready: Yes"))
        #expect(markdown.contains("Outcome explanations captured: 10/10"))
        #expect(markdown.contains("Life Review agreements: 10/10"))
        #expect(markdown.contains("Dominant action: workShift"))
        #expect(markdown.contains("Work felt automatic."))

        let empty = PlaytestCohortAnalysis(reports: [])
        #expect(!empty.isReadyForPhase2)
        #expect(empty.missingRequirements.contains { $0.contains("10 more") })
        #expect(empty.nextRecommendation == PlaytestCohortRecommendation(origin: .balanced, style: .grind))
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func playtestCohortRecommendsTheNextMissingOriginAndStyle() {
        let startedAt = Date(timeIntervalSince1970: 1_700_250_000)
        let origins: [OriginPreset] = [
            .balanced, .balanced, .balanced, .balanced,
            .academic, .academic, .academic,
            .social, .social
        ]
        let reports = origins.indices.map { index in
            PlaytestRunReport(
                runSeed: UInt64(65_000 + index),
                origin: origins[index].rawValue,
                playStyle: PlaytestStyle.social.rawValue,
                startedAt: startedAt,
                updatedAt: startedAt.addingTimeInterval(35 * 60),
                endedAt: startedAt.addingTimeInterval(35 * 60),
                status: .completed,
                moments: [],
                annotations: [],
                endReason: EndReason.naturalCauses.rawValue,
                finalTrajectory: "A complete life.",
                outcomeAssessment: PlaytestOutcomeAssessment(
                    explanation: "Connection shaped the outcome.",
                    reviewAgrees: true,
                    recordedAt: startedAt.addingTimeInterval(35 * 60)
                )
            )
        }

        let analysis = PlaytestCohortAnalysis(reports: reports)

        #expect(analysis.nextRecommendation == PlaytestCohortRecommendation(origin: .social, style: .grind))
        #expect(analysis.markdown.contains("Next run target: Social · Grind"))
    }

    @Test func playtestOutcomeAssessmentPersistsAndReviewMismatchKeepsGateOpen() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-playtest-outcome-\(UUID().uuidString)", isDirectory: true)
        var clock = Date(timeIntervalSince1970: 1_700_300_000)
        var state = LifeState(name: "Outcome", seed: 70_001, startingAge: 18)
        let recorder = FilePlaytestRecorder(baseURL: directory, now: { clock })
        recorder.startOrResume(seed: state.runSeed, origin: OriginPreset.balanced.rawValue, initialState: state)
        recorder.setPlayStyle(.mixed)
        clock.addTimeInterval(35 * 60)
        state.isGameOver = true
        state.endReason = .naturalCauses
        recorder.finalize(status: .completed, state: state)
        clock.addTimeInterval(1)
        recorder.assessOutcome(
            explanation: "  Health pressure ended a life built around work.  ",
            reviewAgrees: false
        )
        _ = recorder.exportURLs()

        let report = try #require(recorder.currentReport())
        #expect(report.schemaVersion == 10)
        #expect(report.outcomeAssessment?.explanation == "Health pressure ended a life built around work.")
        #expect(report.outcomeAssessment?.reviewAgrees == false)
        #expect(report.markdown.contains("Life Review agrees: No"))

        let analysis = FilePlaytestRecorder(baseURL: directory, now: { clock }).cohortAnalysis()
        #expect(analysis.outcomeAssessmentCount == 1)
        #expect(analysis.outcomeAgreementCount == 0)
        #expect(!analysis.isReadyForPhase2)
        #expect(analysis.missingRequirements.contains { $0.contains("Life Review mismatch") })
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func cleanPlaytestCohortCanPassWithoutInventingAProblemOrMixedStyle() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-playtest-clean-cohort-\(UUID().uuidString)", isDirectory: true)
        var clock = Date(timeIntervalSince1970: 1_700_400_000)
        let origins: [OriginPreset] = [
            .balanced, .balanced, .balanced, .balanced,
            .academic, .academic, .academic,
            .social, .social, .social
        ]
        let styles: [PlaytestStyle] = [
            .grind, .social, .survival, .grind, .social,
            .survival, .grind, .social, .survival, .grind
        ]
        let actions: [ActionID] = [.focusGrades, .workShift, .reachOut, .seeFriends, .rest]
        let outcome = ActionOutcome(
            headline: "A Deliberate Choice",
            narrative: "The life kept moving without one repeated shortcut.",
            deltas: DeltaSummary()
        )

        for index in origins.indices {
            var state = LifeState(name: "Clean Cohort \(index)", seed: UInt64(80_000 + index), startingAge: 18)
            let recorder = FilePlaytestRecorder(baseURL: directory, now: { clock })
            recorder.startOrResume(seed: state.runSeed, origin: origins[index].rawValue, initialState: state)
            recorder.setPlayStyle(styles[index])
            for _ in 0..<3 {
                for action in actions {
                    recorder.record(source: .action(action), outcome: outcome, state: state)
                }
            }
            clock.addTimeInterval(35 * 60)
            state.isGameOver = true
            state.endReason = .naturalCauses
            recorder.finalize(status: .completed, state: state)
            recorder.assessOutcome(
                explanation: "Choices stayed balanced across the four everyday domains.",
                reviewAgrees: true
            )
            _ = recorder.exportURLs()
            clock.addTimeInterval(1)
        }

        let analysis = FilePlaytestRecorder(baseURL: directory, now: { clock }).cohortAnalysis()
        #expect(analysis.completedReportCount == 10)
        #expect(analysis.recurringSignals.isEmpty)
        #expect(analysis.styleCounts.first { $0.label == PlaytestStyle.mixed.rawValue }?.count == 0)
        #expect(analysis.isReadyForPhase2)
        #expect(analysis.missingRequirements.isEmpty)
        #expect(analysis.nextRecommendation == nil)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func playtestFinalizationRetainsOnlyTwentyCompletedReports() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-playtest-retention-\(UUID().uuidString)", isDirectory: true)
        var clock = Date(timeIntervalSince1970: 1_700_100_000)

        for seed in 1...22 {
            var state = LifeState(name: "Retention", seed: UInt64(seed))
            state.isGameOver = true
            state.endReason = .naturalCauses
            let recorder = FilePlaytestRecorder(baseURL: directory, now: { clock })
            recorder.startOrResume(seed: UInt64(seed), origin: nil, initialState: state)
            clock.addTimeInterval(2)
            recorder.finalize(status: .completed, state: state)
            _ = recorder.exportURLs() // drains finalization before checking retention
        }

        let completed = directory.appendingPathComponent("Completed", isDirectory: true)
        let reports = try FileManager.default.contentsOfDirectory(at: completed, includingPropertiesForKeys: nil)
        #expect(reports.count == 20)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func financialHardshipContinuesWithoutTerminalRecovery() {
        var state = LifeState(name: "A", seed: 2)
        state.career.level = .unemployed
        state.cash = 0
        state.finance.consumerDebt = 40_000
        state.recovery = RecoveryWindow(kind: .financial, openedAge: 18)
        let simulator = isolatedSimulator(state: state)
        simulator.ageUp()
        #expect(simulator.state.character.age == 19)
        #expect(simulator.state.recovery?.kind != .financial)
        #expect(!simulator.state.isGameOver)
        #expect(simulator.state.cash >= 0)
        #expect(simulator.state.finance.consumerDebt > 40_000)
    }

    @Test func persistenceRetainsMalformedSaveAndStartsFresh() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("onelife-malformed-\(UUID().uuidString).json")
        let malformed = Data("not json".utf8)
        let preservedURL = url.appendingPathExtension("preserved")
        try malformed.write(to: url)
        let persistence = LifePersistence(saveURL: url)
        if case .freshStart(let message) = persistence.load() { #expect(message != nil) } else { Issue.record("Malformed save should not load") }
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(try Data(contentsOf: preservedURL) == malformed)

        let fresh = LifeState(name: "Fresh", seed: 200)
        if case .failure(let error) = persistence.save(fresh) { Issue.record("Fresh save failed: \(error)") }
        #expect(try Data(contentsOf: preservedURL) == malformed)
        if case .loaded(let loaded) = persistence.load() {
            #expect(loaded.character.name == "Fresh")
        } else {
            Issue.record("Fresh life should replace only the primary path")
        }
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: preservedURL)
    }

    @Test func saveVersionsThreeThroughTwentyMigrateWithDeterministicDefaults() throws {
        for version in 3...20 {
            let url = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("onelife-v\(version)-fixture-\(UUID().uuidString).json")
            var source = LifeState(name: "Migration v\(version)", seed: 4_003 + UInt64(version))
            source.random = SeededRandom(seed: source.runSeed)
            _ = source.random.next(in: 1...100)
            source.rememberEvent("school-pressure")

            let encoded = try JSONEncoder().encode(source)
            var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            json["saveVersion"] = version
            if version <= 3 { json.removeValue(forKey: "npcs") }
            if version <= 4 { json.removeValue(forKey: "runSeed") }
            if version <= 5 { json.removeValue(forKey: "recentEventIDs") }
            if version <= 6 {
                json.removeValue(forKey: "career")
                json["job"] = ["tier": "skilled"]
            }
            if version <= 7 { json.removeValue(forKey: "finance") }
            if version <= 8 { json.removeValue(forKey: "family") }
            if version <= 9 { json.removeValue(forKey: "health") }
            if version <= 10 {
                json.removeValue(forKey: "startingContext")
                json.removeValue(forKey: "coreTrait")
                json.removeValue(forKey: "lifeThreads")
            }
            if version <= 11 { json.removeValue(forKey: "world") }
            if version == 12, var world = json["world"] as? [String: Any] {
                world.removeValue(forKey: "publicHealth")
                json["world"] = world
            }
            if version <= 13 { json.removeValue(forKey: "assets") }
            if version <= 15 { json.removeValue(forKey: "legal") }
            if version <= 16, var education = json["education"] as? [String: Any] {
                education.removeValue(forKey: "commitmentYears")
                education.removeValue(forKey: "legacyFlags")
                education.removeValue(forKey: "launchInfluenceYearsRemaining")
                education.removeValue(forKey: "legacySnapshot")
                json["education"] = education
            }
            if version <= 18, var education = json["education"] as? [String: Any] {
                education.removeValue(forKey: "college")
                education.removeValue(forKey: "credentialKind")
                education.removeValue(forKey: "credentialField")
                json["education"] = education
            }
            if version <= 20, var education = json["education"] as? [String: Any] {
                education.removeValue(forKey: "recovery")
                json["education"] = education
            }
            try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url, options: .atomic)

            let persistence = LifePersistence(saveURL: url)
            if case .loaded(let migrated) = persistence.load() {
                #expect(migrated.saveVersion == LifeState.currentSaveVersion)
                #expect(migrated.character.name == source.character.name)
                #expect(migrated.random == source.random)
                if version <= 5 { #expect(migrated.recentEventIDs.isEmpty) }
                if version <= 4 {
                    #expect(migrated.runSeed == source.random.seed)
                } else {
                    #expect(migrated.runSeed == source.runSeed)
                }
                if version == 3 { #expect(migrated.npcs.all.isEmpty) }
                if version == 6 { #expect(migrated.career.level == .established); #expect(migrated.career.track == .undecided) }
                #expect(migrated.health.overall == migrated.stats.health)
                #expect(migrated.education.commitmentYears.isEmpty)
                #expect(migrated.education.legacyFlags.isEmpty)
                #expect(migrated.education.launchInfluenceYearsRemaining == 0)
                #expect(migrated.education.legacySnapshot == nil)
                if version <= 11 {
                    #expect(migrated.world.profile == .neutral)
                    #expect(migrated.world.conditions.macro == .steady)
                } else {
                    #expect(migrated.world.profile == source.world.profile)
                    #expect(migrated.world.conditions == source.world.conditions)
                    #expect(migrated.world.worldRandom == source.world.worldRandom)
                }
                if version <= 12 {
                    #expect(migrated.world.publicHealth.healthcareCapacity == .standard)
                    #expect(migrated.world.publicHealth.diseaseBurden == .typical)
                    #expect(migrated.world.publicHealth.condition == .stable)
                } else {
                    #expect(migrated.world.publicHealth == source.world.publicHealth)
                }
                #expect(migrated.assets.ownedCount == 0)
                #expect(migrated.legal == LegalSystem.initialize(runSeed: migrated.runSeed))
                #expect(migrated.random == source.random)
            } else {
                Issue.record("v\(version) fixture should migrate")
            }
            try? FileManager.default.removeItem(at: url)
        }
    }

    @Test func careerTracksAreReachableAndMateriallyDistinct() throws {
        let ids: [ActionID] = [.chooseOffice, .chooseTrades, .chooseCareService, .chooseFreelance]
        var results: [CareerState] = []
        for (offset, id) in ids.enumerated() {
            let simulator = isolatedSimulator(state: LifeState(name: "Track", seed: UInt64(7_000 + offset)))
            _ = try #require(simulator.execute(id))
            results.append(simulator.state.career)
        }
        #expect(Set(results.map(\.track)).count == 4)
        #expect(Set(results.map(\.security)).count >= 3)
        #expect(Set(results.map(\.annualIncome)).count >= 3)
    }

    @Test func careerPivotHasOneCostRequiresDirectionAndPreservesJobSearchUncertainty() throws {
        var state = LifeState(name: "Pivot", seed: 7_050)
        state.character.age = 32
        state.lifeStage = .build
        state.cash = 20000
        state.career.track = .office
        state.career.level = .established
        state.career.performance = 68
        state.career.security = 72
        state.flags.hasJob = true

        var domainOnly = state
        _ = CareerSystem.resolve(.pivot, state: &domainOnly)
        #expect(domainOnly.cash == state.cash)

        let simulator = isolatedSimulator(state: state)

        let pivot = try #require(simulator.execute(.changeCareer))
        #expect(simulator.state.cash == state.cash + pivot.deltas.cash)
        #expect((-4_500 ... -3_500).contains(pivot.deltas.cash))
        #expect(simulator.state.career.track == .undecided)
        #expect(simulator.state.career.level == .unemployed)
        #expect(simulator.state.career.unemploymentDuration == 0)
        #expect(simulator.state.career.lastTransition == .pivoted)
        #expect(!simulator.state.flags.hasJob)
        #expect(pivot.headline == "You Left The Known Career Path")
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .jobSearch)) == .locked("Choose a career direction first"))

        let direction = try #require(simulator.execute(.chooseTrades))
        #expect(simulator.state.career.track == .trades)
        #expect(simulator.state.career.level == .unemployed)
        #expect(simulator.state.career.lastTransition == .pivoted)
        #expect(!simulator.state.flags.hasJob)
        #expect(direction.headline == "Trades Became The Next Direction")
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .jobSearch)) == .available)

        var searching = simulator.state
        let chance = CareerSystem.jobSearchChance(
            state: searching,
            world: WorldSystem.modifiers(for: searching.world)
        )
        let successfulSeed = try #require((UInt64(1)...100).first { seed in
            var random = SeededRandom(seed: seed)
            return random.next(in: 1...100) <= chance
        })
        searching.randomStreams.career = SeededRandom(seed: successfulSeed)
        let search = isolatedSimulator(state: searching)
        let hired = try #require(search.execute(.jobSearch))
        #expect(hired.headline == "Work Found A Foothold")
        #expect(search.state.career.level == .entry)
        #expect(search.state.career.lastTransition == .hired)
        #expect(search.state.career.unemploymentDuration == 0)
        #expect(search.state.flags.hasJob)

        for _ in 0..<110 where !search.state.isGameOver {
            if let event = search.state.pendingEvent, let choice = event.choices.first {
                search.execute(choice.id)
                continue
            }
            if let recovery = search.state.recovery {
                let recoveryAction: ActionID = recovery.kind == .financial ? .workShift : .rest
                search.execute(recoveryAction)
            } else {
                search.execute(.rest)
            }
            search.ageUp()
        }
        #expect(search.state.isGameOver)
        #expect(search.state.endReason != nil)
        #expect(search.state.career.track == .trades)
        #expect(search.state.flags.hasJob == search.state.career.level.isEmployed)

        let restored = try JSONDecoder().decode(
            LifeState.self,
            from: JSONEncoder().encode(simulator.state)
        )
        #expect(restored.career.track == .trades)
        #expect(restored.career.level == .unemployed)
        #expect(restored.career.lastTransition == .pivoted)
        #expect(!restored.flags.hasJob)
    }

    @Test func ordinaryCareerSupportsPlateauAndRetirementWithoutAForcedFailure() {
        var state = LifeState(name: "Career arc", seed: 7_051)
        state.character.age = 49
        state.lifeStage = .pressure
        state.career.track = .office
        state.career.level = .established
        state.career.performance = 72
        state.career.security = 100
        state.career.tenure = 10
        var stableWorld = WorldModifierSnapshot()
        stableWorld.layoffRiskMultiplier = 0

        let plateau = CareerSystem.resolveYear(state: &state, world: stableWorld)
        #expect(plateau.bullets.contains("Career plateau pressure"))
        #expect(state.career.level == .established)
        #expect(state.career.lastTransition != .laidOff)

        state.character.age = 65
        state.lifeStage = .legacy
        let retirement = CareerSystem.resolveYear(state: &state, world: stableWorld)
        #expect(state.career.level == .retired)
        #expect(state.career.lastTransition == .retired)
        #expect(!state.flags.hasJob)
        #expect(retirement.milestoneHeadline == "You Retired From The Daily Grind")
    }

    @Test func householdLedgerKeepsCashCanonicalAndBoundsEquity() throws {
        var state = LifeState(name: "Household", seed: 7_100)
        state.character.age = 30
        state.lifeStage = .build
        state.cash = 90000
        state.career.track = .trades
        state.career.level = .established
        let simulator = isolatedSimulator(state: state)
        _ = try #require(simulator.execute(.buyHome))
        #expect(simulator.state.cash == 60_000)
        #expect(simulator.state.assets.propertyEquity == 30_000)
        simulator.ageUp()
        #expect(simulator.state.finance.annualLedger.income > 0)
        #expect(simulator.state.assets.propertyEquity >= 0)
        #expect(simulator.state.finance.retirementBalance >= 0)
    }

    @Test func retirementSavingsBecomeSpendableIncomeInsteadOfGrowingForever() {
        var funded = LifeState(name: "Retirement", seed: 7_101, startingAge: 66)
        funded.world = WorldSystem.neutral(runSeed: 7_101, age: 66)
        funded.career.level = .retired; funded.cash = 0
        funded.finance.retirementBalance = 100_000
        funded.finance.retirementContributionPercent = 15
        var unfunded = funded; unfunded.finance.retirementBalance = 0
        let fundedYear = FinanceSystem.yearlySettlement(state: &funded)
        _ = FinanceSystem.yearlySettlement(state: &unfunded)
        #expect(funded.finance.annualLedger.retirementContribution == 0)
        #expect(funded.finance.retirementBalance < 103_000)
        #expect(fundedYear.bullets.contains { $0.hasPrefix("Retirement draw") })
        #expect(funded.finance.consumerDebt == 0)
        #expect(unfunded.finance.consumerDebt > 0)
        #expect(funded.cash >= 0 && unfunded.cash >= 0)
    }

    @Test func assetCatalogIsStaticExhaustiveAndAgeGated() {
        #expect(AssetCatalog.all.count == 44)
        #expect(Set(AssetCatalog.all.map(\.id)).count == 44)
        #expect(AssetCatalog.listings(in: .guns).count == 8)
        #expect(AssetCatalog.listings(in: .cars).count == 26)
        #expect(AssetCatalog.listings(in: .houses).count == 6)
        #expect(AssetCatalog.listings(in: .jewelry).count == 4)
        #expect(Set(AssetCatalog.listings(in: .houses).compactMap { $0.property?.type }) == Set(PropertyType.allCases))
        #expect(Set(AssetCatalog.listings(in: .houses).map(\.name)).count == 6)
        var state = LifeState(name: "Catalog", seed: 71_001)
        state.cash = 5_000_000
        state.character.age = 20
        let gun = AssetCatalog.listings(in: .guns)[0]
        #expect(AssetSystem.availability(for: gun, state: state) == .locked("Available at age 21"))
        state.character.age = 21
        #expect(AssetSystem.availability(for: gun, state: state) == .available)

        let luxury = AssetCatalog.listings(in: .houses)[5]
        state.career.level = .established
        #expect(AssetSystem.availability(for: luxury, state: state) == .locked("Requires a senior career"))
        state.career.level = .senior
        #expect(AssetSystem.availability(for: luxury, state: state) == .locked("Income cannot support another mortgage"))
    }

    @Test func vehicleCatalogCoversEveryClassWithStaticRequirements() throws {
        #expect(AssetCatalog.vehicleListings(of: .car).count == 16)
        #expect(AssetCatalog.vehicleListings(of: .helicopter).count == 3)
        #expect(AssetCatalog.vehicleListings(of: .plane).count == 3)
        #expect(AssetCatalog.vehicleListings(of: .boat).count == 4)
        #expect(Set(AssetCatalog.listings(in: .cars).compactMap { $0.vehicle?.kind }) == Set(VehicleKind.allCases))

        let expectedCars: [(String, String, Int, CarCatalogGroup, CarBodyStyle, CareerLevel?)] = [
            ("car-used-compact", "Older hatchback", 180, .everyday, .hatchback, nil),
            ("car-reliable-sedan", "Budget sedan", 300, .everyday, .sedan, nil),
            ("car-practical-wagon", "Practical wagon", 450, .everyday, .wagon, .entry),
            ("car-efficient-hybrid", "Efficient hybrid", 650, .everyday, .hybrid, .entry),
            ("car-utility-vehicle", "Compact crossover", 700, .utility, .crossover, .entry),
            ("car-family-minivan", "Family minivan", 900, .utility, .minivan, .entry),
            ("car-work-pickup", "Work pickup", 1_100, .utility, .pickup, .entry),
            ("car-full-size-suv", "Full-size SUV", 1_400, .utility, .suv, .established),
            ("car-used-roadster", "Used roadster", 900, .performance, .roadster, .entry),
            ("car-sport-sedan", "Sport sedan", 1_300, .performance, .sedan, .established),
            ("car-luxury-coupe", "Performance coupe", 1_800, .performance, .coupe, .established),
            ("car-track-supercar", "Track-focused supercar", 3_000, .performance, .supercar, .senior),
            ("car-executive-sedan", "Executive sedan", 1_500, .luxury, .sedan, .established),
            ("car-luxury-suv", "Luxury SUV", 2_200, .luxury, .suv, .established),
            ("car-grand-tourer", "Grand tourer", 2_700, .luxury, .grandTourer, .senior),
            ("car-limousine", "Chauffeured limousine", 3_400, .luxury, .limousine, .senior)
        ]
        let cars = AssetCatalog.vehicleListings(of: .car)
        #expect(cars.map(\.id) == expectedCars.map(\.0))
        for (listing, expected) in zip(cars, expectedCars) {
            #expect(listing.name == expected.1)
            #expect(listing.terms.committedCash == expected.2 * 50)
            #expect(listing.vehicle?.carGroup == expected.3)
            #expect(listing.vehicle?.bodyStyle == expected.4)
            #expect(listing.vehicle?.minimumCareerLevel == expected.5)
        }
        for group in CarCatalogGroup.allCases {
            #expect(AssetCatalog.carListings(in: group).count == 4)
        }
        for style in CarBodyStyle.allCases {
            #expect(UIImage(systemName: style.symbolName) != nil)
        }

        var state = LifeState(name: "Vehicle requirements", seed: 71_010)
        state.character.age = 20
        state.cash = 10_000_000
        state.career.level = .entry
        let helicopter = try #require(AssetCatalog.listing(for: "helicopter-utility"))
        #expect(AssetSystem.availability(for: helicopter, state: state) == .locked("Available at age 21"))
        state.character.age = 21
        #expect(AssetSystem.availability(for: helicopter, state: state) == .locked("Requires an established career"))
        state.career.level = .established
        #expect(AssetSystem.availability(for: helicopter, state: state) == .available)
        let jet = try #require(AssetCatalog.listing(for: "plane-private-jet"))
        #expect(AssetSystem.availability(for: jet, state: state) == .locked("Requires a senior career"))
        state.career.level = .senior
        state.cash = 7_499_999
        #expect(AssetSystem.availability(for: jet, state: state) == .locked("Requires $7500000"))
    }

    @Test func vehiclePurchasesDuplicatesAndSalesAreDeterministicAndLossy() throws {
        var state = LifeState(name: "Vehicle collection", seed: 71_011)
        state.character.age = 30
        state.career.level = .senior
        state.cash = 20_000_000
        let gameplay = state.random
        let economy = state.world.worldRandom
        let publicHealth = state.world.publicHealth.publicHealthRandom
        let legal = state.legal.legalRandom
        let simulator = isolatedSimulator(state: state)

        _ = try #require(simulator.purchaseAsset(listingID: "plane-private-jet"))
        _ = try #require(simulator.purchaseAsset(listingID: "plane-private-jet"))
        _ = try #require(simulator.purchaseAsset(listingID: "boat-fishing"))
        #expect(simulator.state.assets.movableAssets.map(\.id) == [1, 2, 3])
        #expect(simulator.state.assets.vehicleCount(of: .plane) == 2)
        #expect(simulator.state.assets.vehicleCount(of: .boat) == 1)
        #expect(simulator.state.assets.vehicleValue(of: .plane) == 9_750_000)
        #expect(simulator.state.cash == 4_984_000)
        #expect(simulator.state.random == gameplay)
        #expect(simulator.state.world.worldRandom == economy)
        #expect(simulator.state.world.publicHealth.publicHealthRandom == publicHealth)
        #expect(simulator.state.legal.legalRandom == legal)

        _ = try #require(simulator.sellAsset(ownershipID: 1))
        #expect(simulator.state.assets.vehicleCount(of: .plane) == 1)
        #expect(simulator.state.cash == 9_859_000)
        #expect(simulator.state.history.first?.headline == "You Sold Private jet")
        #expect(simulator.state.random == gameplay)
        #expect(simulator.state.world.worldRandom == economy)
        #expect(simulator.state.world.publicHealth.publicHealthRandom == publicHealth)
        #expect(simulator.state.legal.legalRandom == legal)
    }

    @Test func vehicleNamesNormalizeValidateAndRemainIndependentAcrossDuplicates() throws {
        #expect(PlayerAssignedNamePolicy.validate("  Road   Runner  ") == .valid("Road Runner"))
        #expect(PlayerAssignedNamePolicy.validate(String(repeating: "A", count: 25)) == .invalid("Use 24 characters or fewer."))
        #expect(PlayerAssignedNamePolicy.validate("Two\nLines") == .invalid("Use a single line without control characters."))
        #expect(PlayerAssignedNamePolicy.validate("   ") == .invalid("Enter a name."))

        var state = LifeState(name: "Vehicle names", seed: 71_012)
        state.character.age = 30
        state.career.level = .senior
        state.cash = 200000
        let simulator = isolatedSimulator(state: state)
        _ = try #require(simulator.purchaseAsset(listingID: "car-used-compact"))
        _ = try #require(simulator.purchaseAsset(listingID: "car-used-compact"))
        let cash = simulator.state.cash
        let age = simulator.state.character.age
        let history = simulator.state.history
        let gameplay = simulator.state.random
        let streams = simulator.state.randomStreams
        let economy = simulator.state.world.worldRandom
        let publicHealth = simulator.state.world.publicHealth.publicHealthRandom
        let legal = simulator.state.legal.legalRandom

        #expect(simulator.renameVehicle(ownershipID: 1, to: "  Road   Runner  ") == .renamed("Road Runner"))
        #expect(simulator.state.assets.movableAssets[0].displayName == "Road Runner")
        #expect(simulator.state.assets.movableAssets[0].name == "Older hatchback")
        #expect(simulator.state.assets.movableAssets[1].displayName == "Older hatchback")
        #expect(simulator.renameVehicle(ownershipID: 2, to: "Two\nLines") == .rejected("Use a single line without control characters."))
        #expect(simulator.state.cash == cash)
        #expect(simulator.state.character.age == age)
        #expect(simulator.state.history == history)
        #expect(simulator.state.random == gameplay)
        #expect(simulator.state.randomStreams == streams)
        #expect(simulator.state.world.worldRandom == economy)
        #expect(simulator.state.world.publicHealth.publicHealthRandom == publicHealth)
        #expect(simulator.state.legal.legalRandom == legal)

        #expect(simulator.clearVehicleName(ownershipID: 1))
        #expect(simulator.state.assets.movableAssets[0].displayName == "Older hatchback")
        #expect(simulator.renameVehicle(ownershipID: 1, to: "Bluebird") == .renamed("Bluebird"))
        _ = try #require(simulator.sellAsset(ownershipID: 1))
        #expect(simulator.state.history.first?.headline == "You Sold Bluebird")
        #expect(simulator.state.assets.movableAssets.first?.id == 2)
    }

    @Test func vehicleDepreciationUsesKindSpecificCurvesAndResidualFloors() {
        #expect(AssetSystem.depreciationRate(for: .car, age: 1) > AssetSystem.depreciationRate(for: .plane, age: 1))
        #expect(AssetSystem.depreciationRate(for: .boat, age: 1) > AssetSystem.depreciationRate(for: .plane, age: 1))
        #expect(AssetSystem.residualRate(for: .car) < AssetSystem.residualRate(for: .plane))

        var state = LifeState(name: "Vehicle depreciation", seed: 71_014)
        state.character.age = 40
        state.assets.movableAssets = [
            OwnedAsset(id: 1, listingID: "car-used-compact", category: .cars, name: "Car", purchaseAge: 18, purchasePrice: 10_000, vehicle: OwnedVehicleState(kind: .car, currentValue: 10_000)),
            OwnedAsset(id: 2, listingID: "plane-light-sport", category: .cars, name: "Plane", purchaseAge: 18, purchasePrice: 10_000, vehicle: OwnedVehicleState(kind: .plane, currentValue: 10_000))
        ]
        state.assets.normalize()
        _ = AssetSystem.prepareYear(assets: &state.assets, world: WorldModifierSnapshot(), age: state.character.age)
        #expect(state.assets.movableAssets[0].vehicle?.currentValue ?? 0 < state.assets.movableAssets[1].vehicle?.currentValue ?? 0)
        #expect(state.assets.movableAssets.allSatisfy { $0.vehicle?.currentValue ?? 0 >= $0.purchasePrice * AssetSystem.residualRate(for: $0.vehicle?.kind ?? .car) / 100 })
    }

    @Test func vehicleMaintenanceRestoresConditionAndCostsMoreForMoreExpensiveVehicles() throws {
        var state = LifeState(name: "Vehicle maintenance", seed: 71_015)
        state.character.age = 35
        state.cash = 1_000_000
        state.assets.movableAssets = [
            OwnedAsset(id: 1, listingID: "car-used-compact", category: .cars, name: "Cheap car", purchaseAge: 20, purchasePrice: 10_000, vehicle: OwnedVehicleState(kind: .car, condition: 55, currentValue: 10_000, repairState: .needsRepair)),
            OwnedAsset(id: 2, listingID: "car-limousine", category: .cars, name: "Expensive car", purchaseAge: 20, purchasePrice: 100_000, vehicle: OwnedVehicleState(kind: .car, condition: 55, currentValue: 100_000, repairState: .needsRepair))
        ]
        state.assets.normalize()
        let cheapCost = AssetSystem.maintenanceCost(.breakdown, vehicle: try #require(state.assets.movableAssets[0].vehicle))
        let expensiveCost = AssetSystem.maintenanceCost(.breakdown, vehicle: try #require(state.assets.movableAssets[1].vehicle))
        #expect(expensiveCost > cheapCost)
        _ = try #require(AssetSystem.maintainVehicle(ownershipID: 1, kind: .breakdown, state: &state))
        #expect(state.assets.movableAssets[0].vehicle?.condition == 90)
        #expect(state.assets.movableAssets[0].vehicle?.repairState == .healthy)
        #expect(AssetSystem.vehicleMaintenanceAvailability(.breakdown, ownershipID: 1, state: state) == .locked("No breakdown requires repair"))
    }

    @Test func vehicleEventEffectsRemoveTotalLossAndPreserveReplacementBudget() {
        var assets = AssetState(movableAssets: [
            OwnedAsset(id: 1, listingID: "car-used-compact", category: .cars, name: "Old car", purchaseAge: 18, purchasePrice: 10_000, vehicle: OwnedVehicleState(kind: .car, condition: 10, currentValue: 4_000, repairState: .totaled))
        ])
        AssetSystem.applyVehicleEventEffect(.init(vehicleID: 1, action: .replace), assets: &assets, age: 40)
        #expect(assets.movableAssets.isEmpty)
        #expect(assets.vehicleReplacementBudget == 2_200)
    }

    @Test func vehicleRenamePersistsImmediatelyWithoutCreatingHistory() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-vehicle-rename-\(UUID().uuidString).json")
        var state = LifeState(name: "Persistent driver", seed: 71_013)
        state.character.age = 30
        state.career.level = .senior
        state.cash = 200000
        _ = try #require(AssetSystem.purchase(listingID: "car-used-compact", state: &state))
        let history = state.history
        let simulator = LifeSimulator(state: state, store: LifePersistence(saveURL: url))

        #expect(simulator.renameVehicle(ownershipID: 1, to: "Bluebird") == .renamed("Bluebird"))
        simulator.saveForLifecycle()
        guard case .loaded(let loaded) = LifePersistence(saveURL: url).load() else {
            Issue.record("Renamed vehicle should reload")
            return
        }
        #expect(loaded.assets.movableAssets.first?.displayName == "Bluebird")
        #expect(loaded.assets.movableAssets.first?.name == "Older hatchback")
        #expect(loaded.history == history)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func propertyAmenityCatalogIsStaticExhaustiveAndTiered() throws {
        #expect(PropertyAmenityCatalog.all.map(\.id) == PropertyAmenityID.allCases)
        #expect(Set(PropertyAmenityCatalog.all.map(\.id)).count == 6)
        let expected: [(PropertyAmenityID, PropertyTier, Int, Int, Int)] = [
            (.homeGym, .standard, 180, 117, 18),
            (.basketballCourt, .premium, 220, 143, 22),
            (.sauna, .premium, 260, 169, 28),
            (.swimmingPool, .premium, 360, 234, 45),
            (.tennisCourt, .luxury, 450, 292, 55),
            (.bioluminescentLandscaping, .trophy, 700, 455, 80)
        ]
        for values in expected {
            let definition = try #require(PropertyAmenityCatalog.definition(for: values.0))
            #expect(definition.minimumTier == values.1)
            #expect(definition.installationPrice == values.2 * 100)
            #expect(definition.valueContribution == values.3 * 100)
            #expect(definition.annualUpkeep == values.4 * 100)
        }
    }

    @Test func propertyAmenityAvailabilityCoversTierCashDelinquencyAndDuplicates() throws {
        var state = LifeState(name: "Amenity locks", seed: 71_020)
        state.character.age = 35
        state.career.track = .office
        state.career.level = .senior
        state.cash = 500000
        state.assets.lastRentalIncome = 500
        _ = try #require(AssetSystem.purchase(listingID: "house-starter-condo", state: &state))
        _ = try #require(AssetSystem.purchase(listingID: "house-family", state: &state))
        let starterID = state.assets.properties[0].id
        let premiumID = state.assets.properties[1].id
        let gym = try #require(PropertyAmenityCatalog.definition(for: .homeGym))
        let tennis = try #require(PropertyAmenityCatalog.definition(for: .tennisCourt))
        #expect(AssetSystem.amenityAvailability(gym, propertyID: starterID, state: state) == .locked("Requires a standard property"))
        #expect(AssetSystem.amenityAvailability(tennis, propertyID: premiumID, state: state) == .locked("Requires a luxury property"))

        _ = try #require(AssetSystem.installAmenity(propertyID: premiumID, amenityID: .homeGym, state: &state))
        #expect(AssetSystem.amenityAvailability(gym, propertyID: premiumID, state: state) == .locked("Already installed"))
        state.assets.properties[1].delinquentYears = 2
        let pool = try #require(PropertyAmenityCatalog.definition(for: .swimmingPool))
        #expect(AssetSystem.amenityAvailability(pool, propertyID: premiumID, state: state) == .locked("Resolve mortgage delinquency first"))
        state.assets.properties[1].delinquentYears = 0
        state.cash = 0
        #expect(AssetSystem.amenityAvailability(pool, propertyID: premiumID, state: state) == .locked("Requires $36000"))
    }

    @Test func propertyAmenitiesAreRNGFreeFinancialUpgradesThroughSale() throws {
        var state = LifeState(name: "Improved home", seed: 71_021)
        state.character.age = 35
        state.lifeStage = .build
        state.career.level = .senior
        state.cash = 500000
        let simulator = isolatedSimulator(state: state)
        _ = try #require(simulator.purchaseAsset(listingID: "house-family"))
        let propertyID = try #require(simulator.state.assets.properties.first?.id)
        let gameplay = simulator.state.random
        let economy = simulator.state.world.worldRandom
        let publicHealth = simulator.state.world.publicHealth.publicHealthRandom
        let legal = simulator.state.legal.legalRandom
        let netWorthBefore = simulator.state.netWorth

        _ = try #require(simulator.installPropertyAmenity(propertyID: propertyID, amenityID: .homeGym))
        let improved = try #require(simulator.state.assets.properties.first)
        #expect(improved.amenities.count == 1)
        #expect(improved.improvementValue == 11_700)
        #expect(improved.currentValue == 336_700)
        #expect(improved.amenityUpkeep == 1_800)
        #expect(improved.totalAnnualCost == 10_218)
        #expect(improved.equity == 76_700)
        #expect(improved.closingCost == 16_835)
        #expect(improved.saleProceeds == 59_865)
        #expect(simulator.state.netWorth == netWorthBefore - 6_300)
        #expect(simulator.state.random == gameplay)
        #expect(simulator.state.world.worldRandom == economy)
        #expect(simulator.state.world.publicHealth.publicHealthRandom == publicHealth)
        #expect(simulator.state.legal.legalRandom == legal)

        let roundTrip = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(simulator.state))
        #expect(roundTrip.assets.properties.first?.amenities == improved.amenities)

        var crunch = WorldModifierSnapshot()
        crunch.housingCostMultiplier = 1.15
        let financial = AssetSystem.financialSnapshot(assets: simulator.state.assets, world: crunch)
        #expect(financial.annualPropertyCosts == 11_751)
        #expect(financial.mortgageInterest == 15_600)

        _ = try #require(simulator.sellAsset(ownershipID: propertyID))
        #expect(simulator.state.assets.properties.isEmpty)
        #expect(simulator.state.cash == 476_865)
        #expect(simulator.state.random == gameplay)
        #expect(simulator.state.world.worldRandom == economy)
        #expect(simulator.state.world.publicHealth.publicHealthRandom == publicHealth)
        #expect(simulator.state.legal.legalRandom == legal)
    }

    @Test func propertyAmenityNormalizationIsDeterministicAndDefensive() {
        var property = OwnedProperty(
            id: 1,
            listingID: "house-townhouse",
            name: "Normalization home",
            purchaseAge: 30,
            purchasePrice: 1_800,
            mortgageBalance: 1_350,
            annualCost: 240,
            delinquentYears: 0,
            isPrimaryResidence: true,
            propertyType: .townhome,
            propertyTier: .standard,
            amenities: [
                .init(amenityID: .homeGym, installedAge: 20, paidPrice: -1, valueContribution: -2, annualUpkeep: -3),
                .init(amenityID: .homeGym, installedAge: 31, paidPrice: 180, valueContribution: 117, annualUpkeep: 18),
                .init(amenityID: .swimmingPool, installedAge: 31, paidPrice: 360, valueContribution: 234, annualUpkeep: 45)
            ]
        )
        var assets = AssetState(properties: [property])
        assets.normalize()
        property = assets.properties[0]
        #expect(property.amenities.count == 1)
        #expect(property.amenities[0].amenityID == .homeGym)
        #expect(property.amenities[0].installedAge == 30)
        #expect(property.amenities[0].paidPrice == 0)
        #expect(property.amenities[0].valueContribution == 0)
        #expect(property.amenities[0].annualUpkeep == 0)
    }

    @Test func firearmMarketsRarityFelonyHeatAndUpgradesAreDeterministic() throws {
        let legalListing = try #require(AssetCatalog.listing(for: "gun-sporting-handgun"))
        let illicitListing = try #require(AssetCatalog.listing(for: "gun-unregistered-handgun"))
        #expect(legalListing.firearm?.market == .legal)
        #expect(illicitListing.firearm?.market == .illicit)
        #expect(AssetCatalog.firearmListings(in: .legal).count == 4)
        #expect(AssetCatalog.firearmListings(in: .illicit).count == 4)

        var state = LifeState(name: "Market", seed: 71_100)
        state.character.age = 25
        state.lifeStage = .build
        state.cash = 5_000
        while state.character.age < 100, AssetSystem.availability(for: illicitListing, state: state) != .available {
            state.character.age += 1
        }
        _ = try #require(AssetSystem.availability(for: illicitListing, state: state) == .available)
        let gameplay = state.random
        let economy = state.world.worldRandom
        let publicHealth = state.world.publicHealth.publicHealthRandom
        let legalRandom = state.legal.legalRandom
        let simulator = isolatedSimulator(state: state)
        _ = try #require(simulator.purchaseAsset(listingID: illicitListing.id))
        let owned = try #require(simulator.state.assets.movableAssets.first)
        #expect(owned.firearm?.market == .illicit)
        #expect(simulator.state.legal.firearmHeat == 8)
        #expect(simulator.state.random == gameplay)
        #expect(simulator.state.world.worldRandom == economy)
        #expect(simulator.state.world.publicHealth.publicHealthRandom == publicHealth)
        #expect(simulator.state.legal.legalRandom == legalRandom)

        let optic = FirearmUpgradeCatalog.definition(for: .optic)
        _ = try #require(simulator.upgradeFirearm(ownershipID: owned.id, upgradeID: optic.id))
        #expect(simulator.state.assets.movableAssets.first?.firearm?.upgrades == [.optic])
        #expect(simulator.state.legal.firearmHeat == 8)

        var felon = simulator.state
        felon.legal.record = .felony
        #expect(AssetSystem.availability(for: legalListing, state: felon) == .locked("Felony record blocks legal purchase"))
        let exposure = AssetSystem.firearmExposure(assets: felon.assets, legal: felon.legal)
        #expect(exposure.illicitCount == 1)
        #expect(exposure.totalRisk == 8)
    }

    @Test func firearmStorageAndInspectionAreFinanceOnlyManagementActions() throws {
        var state = LifeState(name: "Firearm storage", seed: 71_103)
        state.character.age = 30
        state.cash = 5_000
        state.assets.movableAssets = [
            OwnedAsset(
                id: 1,
                listingID: "gun-sporting-handgun",
                category: .guns,
                name: "Sporting handgun",
                purchaseAge: 25,
                purchasePrice: 1_000,
                firearm: OwnedFirearmState(market: .legal, rarity: .common, baseHeat: 0)
            )
        ]
        state.assets.normalize()
        let before = AssetSystem.firearmExposure(assets: state.assets, legal: state.legal)
        #expect(before.totalRisk == 6)
        _ = try #require(AssetSystem.manageFirearm(ownershipID: 1, action: .secureStorage, state: &state))
        #expect(state.assets.movableAssets[0].firearm?.secureStorage == true)
        #expect(AssetSystem.firearmExposure(assets: state.assets, legal: state.legal).totalRisk == 0)
        _ = try #require(AssetSystem.manageFirearm(ownershipID: 1, action: .inspection, state: &state))
        #expect(state.assets.movableAssets[0].firearm?.condition == 100)
        #expect(AssetSystem.firearmManagementAvailability(.inspection, ownershipID: 1, state: state) == .locked("Already inspected this year"))
    }

    @Test func jewelryGetsIndependentMarketValueAndConditionResale() throws {
        var state = LifeState(name: "Jewelry market", seed: 71_104)
        state.character.age = 35
        state.assets.movableAssets = [
            OwnedAsset(
                id: 1,
                listingID: "jewelry-gold-watch",
                category: .jewelry,
                name: "Gold watch",
                purchaseAge: 25,
                purchasePrice: 10_000,
                jewelry: OwnedJewelryState(marketValue: 10_000, condition: 100)
            )
        ]
        state.assets.normalize()
        let before = state.assets.movableAssets[0].jewelry
        _ = AssetSystem.prepareYear(assets: &state.assets, world: WorldModifierSnapshot(), age: state.character.age)
        let after = try #require(state.assets.movableAssets[0].jewelry)
        #expect(after.condition == 99)
        #expect(after.marketValue >= 1)
        #expect(state.assets.movableAssets[0].resaleValue <= after.marketValue)
        #expect(before?.marketValue != 0)
    }

    @Test func legalConsequencesUseOnlyTheDedicatedStreamAndCanConfiscate() throws {
        var state = LifeState(name: "Exposure", seed: 71_101)
        state.character.age = 30
        state.cash = 5_000
        let listing = try #require(AssetCatalog.listing(for: "gun-automatic-contraband"))
        while state.character.age < 120, AssetSystem.availability(for: listing, state: state) != .available {
            state.character.age += 1
        }
        _ = try #require(AssetSystem.availability(for: listing, state: state) == .available)
        let transaction = try #require(AssetSystem.purchase(listingID: listing.id, state: &state))
        LegalSystem.apply(transaction: transaction, legal: &state.legal)
        state.legal.firearmHeat = 100
        let gameplay = state.random
        let economy = state.world.worldRandom
        let care = state.world.publicHealth.publicHealthRandom
        let exposure = AssetSystem.firearmExposure(assets: state.assets, legal: state.legal)

        var outcome = LegalYearOutcome()
        for age in state.character.age...(state.character.age + 20) where outcome.confiscatedOwnershipID == nil {
            outcome = LegalSystem.resolveYear(legal: &state.legal, exposure: exposure, age: age)
        }
        let confiscatedID = try #require(outcome.confiscatedOwnershipID)
        _ = AssetSystem.confiscate(ownershipID: confiscatedID, assets: &state.assets, age: state.character.age)
        #expect(state.legal.isFelon)
        #expect(state.legal.supervisionYearsRemaining == 6)
        #expect(state.assets.count(in: .guns) == 0)
        #expect(Set(outcome.consequences.map(\.target)) == [.career, .finance, .relationships])
        #expect(state.random == gameplay)
        #expect(state.world.worldRandom == economy)
        #expect(state.world.publicHealth.publicHealthRandom == care)
    }

    @Test func legalSupervisionOnlyProgressesAfterRiskyExposureEnds() {
        var state = LifeState(name: "Legal recovery", seed: 71_102)
        state.legal.record = .felony
        state.legal.firearmHeat = 16
        state.legal.supervisionYearsRemaining = 2
        let risky = FirearmExposureSnapshot(
            lawfulCount: 0,
            illicitCount: 1,
            totalRisk: 1,
            items: [FirearmExposureItem(ownershipID: 1, risk: 1)]
        )

        _ = LegalSystem.resolveYear(legal: &state.legal, exposure: risky, age: 40)
        #expect(state.legal.supervisionYearsRemaining >= 2)
        #expect(state.legal.cleanYears == 0)
        #expect(SystemRegistry.isActive(.legal, in: state))

        var completion = LegalYearOutcome()
        let yearsToComplete = state.legal.supervisionYearsRemaining
        for age in 41..<(41 + yearsToComplete) {
            completion = LegalSystem.resolveYear(legal: &state.legal, exposure: .empty, age: age)
        }
        #expect(completion.completedSupervision)
        #expect(completion.bullets.contains("Legal supervision completed"))
        #expect(state.legal.supervisionYearsRemaining == 0)
        #expect(state.legal.cleanYears == yearsToComplete)
        #expect(state.legal.isFelon)
        while state.legal.firearmHeat > 0 {
            _ = LegalSystem.resolveYear(legal: &state.legal, exposure: .empty, age: 50)
        }
        #expect(!SystemRegistry.isActive(.legal, in: state))
    }

    @Test func versionTwentyNineAddsCompletedLegalSupervisionAndReviewKeepsTheRecord() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v29-legal-supervision-\(UUID().uuidString).json")
        var source = LifeState(name: "Old legal record", seed: 71_103)
        source.saveVersion = 29
        source.legal.record = .felony
        source.legal.lastFirearmConsequenceAge = 30
        let legalRandom = source.legal.legalRandom
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        var legal = try #require(json["legal"] as? [String: Any])
        legal.removeValue(forKey: "supervisionYearsRemaining")
        legal.removeValue(forKey: "cleanYears")
        json["legal"] = legal
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        guard case .loaded(let migrated) = LifePersistence(saveURL: url).load() else {
            Issue.record("v29 legal save should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.legal.isFelon)
        #expect(!migrated.legal.isUnderSupervision)
        #expect(migrated.legal.cleanYears == 0)
        #expect(migrated.legal.legalRandom == legalRandom)
        #expect(LifeReviewModel.build(from: migrated).legalLine.contains("supervision was completed"))
        #expect(migrated.lifeSummary.contains("Legal:"))
        try? FileManager.default.removeItem(at: url)
    }

    @Test func lifeReviewClosesCurrentAndRecordedWorldPressure() {
        var state = LifeState(name: "World review", seed: 71_104)
        state.world.profileDisclosed = true
        state.world.conditions.macro = .recovery
        state.world.conditions.price = .housingCrunch
        state.world.conditions.priceYearsRemaining = 2
        state.world.recentEventIDs = ["world-macro-recession", "world-prices-easing"]
        state.world.publicHealth.condition = .recovery
        state.world.publicHealth.recentEventIDs = ["world-health-outbreak"]

        let line = LifeReviewModel.build(from: state).worldLine
        #expect(line.contains("Recorded 3 major world shifts"))
        #expect(line.contains("ended during recovery conditions"))
        #expect(line.contains("recovery public health"))
        #expect(line.contains("housingCrunch still active"))
    }

    @Test func duplicateAssetTransactionsAreDeterministicRNGFreeAndLossy() throws {
        var state = LifeState(name: "Collector", seed: 71_002)
        state.character.age = 22
        state.cash = 100000
        let gameplay = state.random
        let economy = state.world.worldRandom
        let publicHealth = state.world.publicHealth.publicHealthRandom
        let simulator = isolatedSimulator(state: state)

        _ = try #require(simulator.purchaseAsset(listingID: "jewelry-silver-chain"))
        _ = try #require(simulator.purchaseAsset(listingID: "jewelry-silver-chain"))
        #expect(simulator.state.assets.movableAssets.map(\.id) == [1, 2])
        #expect(simulator.state.assets.count(in: .jewelry) == 2)
        #expect(simulator.state.cash == 98_800)
        #expect(simulator.state.random == gameplay)
        #expect(simulator.state.world.worldRandom == economy)
        #expect(simulator.state.world.publicHealth.publicHealthRandom == publicHealth)

        _ = try #require(simulator.sellAsset(ownershipID: 1))
        #expect(simulator.state.cash == 99_190)
        #expect(simulator.state.assets.count(in: .jewelry) == 1)
        #expect(simulator.state.history.first?.headline == "You Sold Silver chain")
        #expect(simulator.state.netWorth == 99_580)
        #expect(simulator.state.random == gameplay)
    }

    @Test func assetTransactionsAppearInPlaytestDiagnostics() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-asset-playtest-\(UUID().uuidString)", isDirectory: true)
        var state = LifeState(name: "Recorded collector", seed: 71_003)
        state.character.age = 22
        state.cash = 50000
        let recorder = FilePlaytestRecorder(baseURL: directory)
        let simulator = LifeSimulator(
            state: state,
            store: LifePersistence(saveURL: directory.appendingPathComponent("save.json")),
            playtestRecorder: recorder
        )
        _ = try #require(simulator.purchaseAsset(listingID: "car-used-compact"))
        let report = try #require(recorder.currentReport())
        #expect(report.moments.last?.source.kind == .assetTransaction)
        #expect(report.moments.last?.state.assetCounts?["cars"] == 1)
        #expect(report.moments.last?.state.movableAssetResaleValue == 5_850)
        let recordedMomentCount = report.moments.count
        #expect(simulator.renameVehicle(ownershipID: 1, to: "Private Name") == .renamed("Private Name"))
        #expect(recorder.currentReport()?.moments.count == recordedMomentCount)
        _ = try #require(simulator.sellAsset(ownershipID: 1))
        #expect(simulator.state.history.first?.headline == "You Sold Private Name")
        #expect(recorder.currentReport()?.moments.last?.headline == "You Sold Older hatchback")
        let markdownURL = try #require(recorder.exportURLs().first(where: { $0.pathExtension == "md" }))
        #expect(try String(contentsOf: markdownURL, encoding: .utf8).contains("Private Name") == false)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func multiplePropertiesCarryCostsPayPrincipalAndPromotePrimary() throws {
        var state = LifeState(name: "Property", seed: 71_004)
        state.character.age = 35
        state.lifeStage = .build
        state.career.level = .senior
        state.cash = 500000
        let simulator = isolatedSimulator(state: state)
        _ = try #require(simulator.purchaseAsset(listingID: "house-starter-condo"))
        _ = try #require(simulator.purchaseAsset(listingID: "house-townhouse"))
        #expect(simulator.state.assets.properties.count == 2)
        #expect(simulator.state.assets.properties[0].isPrimaryResidence)
        #expect(!simulator.state.assets.properties[1].isPrimaryResidence)
        #expect(simulator.state.assets.totalMortgageDebt == 300_000)

        var crunch = WorldModifierSnapshot()
        crunch.housingCostMultiplier = 1.15
        let snapshot = AssetSystem.financialSnapshot(assets: simulator.state.assets, world: crunch)
        #expect(snapshot.annualPropertyCosts == 10_782)
        #expect(snapshot.mortgageInterest == 18_000)

        var assets = simulator.state.assets
        _ = propertyReceiptYear(assets: &assets, missed: false, principal: 10_000)
        #expect(assets.properties[0].mortgageBalance == 110_000)
        #expect(assets.properties[1].mortgageBalance == 180_000)
        let firstID = assets.properties[0].id
        var selling = simulator.state
        selling.assets = assets
        let proceeds = assets.properties[0].saleProceeds
        _ = try #require(AssetSystem.sell(ownershipID: firstID, state: &selling))
        #expect(selling.assets.properties.count == 1)
        #expect(selling.assets.properties[0].isPrimaryResidence)
        #expect(selling.cash == simulator.state.cash + proceeds)
    }

    @Test func propertyDelinquencyAndAssetHibernationAreStateContingent() throws {
        var empty = LifeState(name: "Renter", seed: 71_005)
        #expect(!SystemRegistry.isActive(.assets, in: empty))
        empty.cash = 200000
        empty.character.age = 30
        empty.career.level = .established
        _ = try #require(AssetSystem.purchase(listingID: "house-starter-condo", state: &empty))
        #expect(SystemRegistry.isActive(.assets, in: empty))
        _ = propertyReceiptYear(assets: &empty.assets, missed: true)
        let second = propertyReceiptYear(assets: &empty.assets, missed: true)
        #expect(second.newlyDelinquent)
        #expect(empty.assets.hasDelinquentProperty)
    }

    @Test func propertyDelinquencyCanRecoverOrEndInRememberedForeclosure() throws {
        var recovering = LifeState(name: "Recovering homeowner", seed: 71_030)
        recovering.character.age = 35
        recovering.career.level = .established
        recovering.cash = 200000
        _ = try #require(AssetSystem.purchase(listingID: "house-starter-condo", state: &recovering))
        _ = propertyReceiptYear(assets: &recovering.assets, missed: true, age: 36)
        _ = propertyReceiptYear(assets: &recovering.assets, missed: true, age: 37)
        #expect(recovering.assets.hasDelinquentProperty)

        let easing = propertyReceiptYear(assets: &recovering.assets, missed: false, age: 38)
        let resolved = propertyReceiptYear(assets: &recovering.assets, missed: false, age: 39)
        #expect(easing.bullets.contains("Mortgage delinquency resolved: Cedar Court Condo"))
        #expect(!resolved.bullets.contains(where: { $0.contains("delinquency") }))
        #expect(!recovering.assets.hasDelinquentProperty)
        #expect(recovering.assets.properties[0].delinquentYears == 0)

        var failing = LifeState(name: "Foreclosed homeowner", seed: 71_031)
        failing.character.age = 35
        failing.career.level = .established
        failing.cash = 200000
        _ = try #require(AssetSystem.purchase(listingID: "house-starter-condo", state: &failing))
        var foreclosure = AssetYearOutcome()
        for age in 36...39 {
            foreclosure = propertyReceiptYear(assets: &failing.assets, missed: true, age: age)
        }
        #expect(foreclosure.foreclosedCount == 1)
        #expect(foreclosure.bullets.contains("Foreclosure: Cedar Court Condo"))
        #expect(foreclosure.consequences.first?.source == .assets)
        #expect(foreclosure.consequences.first?.target == .finance)
        #expect(failing.assets.properties.isEmpty)
        #expect(failing.assets.propertyHistory.first?.reason == .foreclosed)
        #expect(failing.assets.propertyHistory.first?.cashRecovered == foreclosure.cashSettlement)
    }

    @Test func propertyExitsPersistAndCloseTheHousingLifeReviewArc() throws {
        var state = LifeState(name: "Housing history", seed: 71_032)
        state.character.age = 45
        state.lifeStage = .pressure
        state.career.level = .senior
        state.cash = 200000
        let purchase = try #require(AssetSystem.purchase(listingID: "house-starter-condo", state: &state))
        let sale = try #require(AssetSystem.sell(ownershipID: purchase.ownershipID, state: &state))
        #expect(sale.cashDelta > 0)
        #expect(state.assets.propertyHistory.first?.reason == .sold)
        #expect(state.assets.propertyHistory.first?.cashRecovered == sale.cashDelta)

        state.isGameOver = true
        state.endReason = .naturalCauses
        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(restored.assets.propertyHistory == state.assets.propertyHistory)
        #expect(LifeReviewModel.build(from: restored).housingLine.contains("was sold at age 45"))
        #expect(restored.lifeSummary.contains("Housing:"))
    }

    @Test func versionTwentyEightAddsEmptyPropertyHistoryWithoutChangingAssets() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v28-property-history-\(UUID().uuidString).json")
        var source = LifeState(name: "Existing homeowner", seed: 71_033)
        source.character.age = 35
        source.career.level = .established
        source.cash = 200000
        _ = try #require(AssetSystem.purchase(listingID: "house-starter-condo", state: &source))
        source.saveVersion = 28
        let properties = source.assets.properties
        let streams = source.randomStreams
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        var assets = try #require(json["assets"] as? [String: Any])
        assets.removeValue(forKey: "propertyHistory")
        json["assets"] = assets
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        guard case .loaded(let migrated) = LifePersistence(saveURL: url).load() else {
            Issue.record("v28 property save should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.assets.properties.map(\.id) == properties.map(\.id))
        #expect(migrated.assets.properties.map(\.mortgageBalance) == properties.map(\.mortgageBalance))
        #expect(migrated.assets.properties.first?.condition == 90)
        #expect(migrated.assets.propertyHistory.isEmpty)
        #expect(migrated.randomStreams == streams)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func versionThirteenHomeMigratesWithoutChangingRNGOrValue() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v13-assets-\(UUID().uuidString).json")
        var source = LifeState(name: "Legacy homeowner", seed: 71_006)
        source.saveVersion = 13
        source.finance.housing = HousingState(
            kind: .delinquent,
            homeValue: 1_500,
            mortgageBalance: 900,
            annualCost: 220,
            maintenanceReserve: 15,
            delinquentYears: 2
        )
        let gameplay = source.random
        let economy = source.world.worldRandom
        let publicHealth = source.world.publicHealth.publicHealthRandom
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        json.removeValue(forKey: "assets")
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        let persistence = LifePersistence(saveURL: url)
        guard case .loaded(let migrated) = persistence.load() else {
            Issue.record("v13 home should migrate")
            return
        }
        #expect(migrated.assets.properties.count == 1)
        #expect(migrated.assets.propertyEquity == 60_000)
        #expect(migrated.assets.totalMortgageDebt == 90_000)
        #expect(migrated.assets.hasDelinquentProperty)
        #expect(migrated.finance.housing.kind == .renting)
        #expect(migrated.random == gameplay)
        #expect(migrated.world.worldRandom == economy)
        #expect(migrated.world.publicHealth.publicHealthRandom == publicHealth)
        let roundTrip = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(migrated))
        #expect(roundTrip == migrated)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func versionSeventeenPropertiesMigrateWithEmptyAmenitiesAndStableRNG() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v17-amenities-\(UUID().uuidString).json")
        var source = LifeState(name: "Legacy property owner", seed: 71_022)
        source.saveVersion = 17
        source.character.age = 35
        source.career.level = .senior
        source.cash = 500000
        _ = try #require(AssetSystem.purchase(listingID: "house-family", state: &source))
        let gameplay = source.random
        let economy = source.world.worldRandom
        let publicHealth = source.world.publicHealth.publicHealthRandom
        let legal = source.legal.legalRandom
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        var assets = try #require(json["assets"] as? [String: Any])
        var properties = try #require(assets["properties"] as? [[String: Any]])
        for index in properties.indices { properties[index].removeValue(forKey: "amenities") }
        assets["properties"] = properties
        json["assets"] = assets
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        let persistence = LifePersistence(saveURL: url)
        guard case .loaded(let migrated) = persistence.load() else {
            Issue.record("v17 property should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.assets.properties.first?.amenities.isEmpty == true)
        #expect(migrated.assets.properties.first?.purchasePrice == 325_000)
        #expect(migrated.assets.properties.first?.mortgageBalance == 260_000)
        #expect(migrated.random == gameplay)
        #expect(migrated.world.worldRandom == economy)
        #expect(migrated.world.publicHealth.publicHealthRandom == publicHealth)
        #expect(migrated.legal.legalRandom == legal)
        let roundTrip = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(migrated))
        #expect(roundTrip == migrated)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func versionEighteenCollegeMigratesWithoutNewDebtOrRNGWork() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v18-college-\(UUID().uuidString).json")
        var source = LifeState(name: "Legacy student", seed: 71_023, startingAge: 14)
        source.saveVersion = 18
        source.character.age = 21
        source.lifeStage = .launch
        source.flags.attendsSchool = true
        source.education.phase = .postsecondary
        source.education.postSchoolPath = .college
        source.education.progress = 6
        source.finance.studentDebt = 88
        let gameplay = source.random
        let economy = source.world.worldRandom
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        var education = try #require(json["education"] as? [String: Any])
        education.removeValue(forKey: "college")
        education.removeValue(forKey: "credentialKind")
        education.removeValue(forKey: "credentialField")
        json["education"] = education
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        let persistence = LifePersistence(saveURL: url)
        guard case .loaded(let migrated) = persistence.load() else {
            Issue.record("v18 college save should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.education.college.status == .enrolled)
        #expect(migrated.education.college.institution == .publicUniversity)
        #expect(migrated.education.college.field == .generalStudies)
        #expect(migrated.education.college.credits == 6)
        #expect(migrated.education.college.lastTuitionAge == 21)
        #expect(migrated.finance.studentDebt == 8_800)
        #expect(migrated.random == gameplay)
        #expect(migrated.world.worldRandom == economy)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func versionNineteenCarsMigrateToExplicitVehicleStateWithoutRNGWork() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v19-vehicles-\(UUID().uuidString).json")
        var source = LifeState(name: "Legacy driver", seed: 71_024)
        source.saveVersion = 19
        source.cash = 100000
        source.assets = AssetState(
            movableAssets: [
                OwnedAsset(
                    id: 1,
                    listingID: "car-used-compact",
                    category: .cars,
                    name: "Used compact",
                    purchaseAge: 24,
                    purchasePrice: 250,
                    vehicle: OwnedVehicleState(kind: .car)
                )
            ],
            nextOwnershipSequence: 2
        )
        let gameplay = source.random
        let economy = source.world.worldRandom
        let publicHealth = source.world.publicHealth.publicHealthRandom
        let legal = source.legal.legalRandom
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        var assets = try #require(json["assets"] as? [String: Any])
        var movable = try #require(assets["movableAssets"] as? [[String: Any]])
        for index in movable.indices { movable[index].removeValue(forKey: "vehicle") }
        assets["movableAssets"] = movable
        json["assets"] = assets
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        let persistence = LifePersistence(saveURL: url)
        guard case .loaded(let migrated) = persistence.load() else {
            Issue.record("v19 car should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.assets.movableAssets.first?.vehicle?.kind == .car)
        #expect(migrated.assets.movableAssets.first?.vehicle?.condition == 100)
        #expect(migrated.assets.movableAssets.first?.vehicle?.currentValue == 12_500)
        #expect(migrated.assets.movableAssets.first?.vehicle?.repairState == .healthy)
        #expect(migrated.assets.movableAssets.first?.purchasePrice == 12_500)
        #expect(migrated.random == gameplay)
        #expect(migrated.world.worldRandom == economy)
        #expect(migrated.world.publicHealth.publicHealthRandom == publicHealth)
        #expect(migrated.legal.legalRandom == legal)
        let roundTrip = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(migrated))
        #expect(roundTrip == migrated)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func versionTwentyFiveVehiclesGainNeutralPrivateNamesWithoutRNGOrValueChanges() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v25-vehicle-names-\(UUID().uuidString).json")
        var source = LifeState(name: "Pre-rename driver", seed: 71_027)
        source.saveVersion = 25
        source.character.age = 30
        source.career.level = .senior
        source.cash = 500000
        _ = try #require(AssetSystem.purchase(listingID: "car-used-compact", state: &source))
        let gameplay = source.random
        let streams = source.randomStreams
        let economy = source.world.worldRandom
        let publicHealth = source.world.publicHealth.publicHealthRandom
        let legal = source.legal.legalRandom
        let value = source.assets.totalValue
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        var assets = try #require(json["assets"] as? [String: Any])
        var movable = try #require(assets["movableAssets"] as? [[String: Any]])
        for index in movable.indices {
            var vehicle = try #require(movable[index]["vehicle"] as? [String: Any])
            vehicle.removeValue(forKey: "customName")
            movable[index]["vehicle"] = vehicle
        }
        assets["movableAssets"] = movable
        json["assets"] = assets
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        let persistence = LifePersistence(saveURL: url)
        guard case .loaded(let migrated) = persistence.load() else {
            Issue.record("v25 vehicle should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.assets.movableAssets.first?.vehicle?.customName == nil)
        #expect(migrated.assets.movableAssets.first?.name == "Older hatchback")
        #expect(migrated.assets.totalValue == value * 50)
        #expect(migrated.random == gameplay)
        #expect(migrated.randomStreams == streams)
        #expect(migrated.world.worldRandom == economy)
        #expect(migrated.world.publicHealth.publicHealthRandom == publicHealth)
        #expect(migrated.legal.legalRandom == legal)
        let roundTrip = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(migrated))
        #expect(roundTrip == migrated)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func versionTwentyAddsNeutralEducationRecoveryWithoutRNGOrDebtWork() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v20-education-recovery-\(UUID().uuidString).json")
        var source = LifeState(name: "Legacy adult", seed: 71_026)
        source.saveVersion = 20
        source.character.age = 36
        source.lifeStage = .build
        source.education.phase = .leftSchool
        source.finance.studentDebt = 63
        let gameplay = source.random
        let economy = source.world.worldRandom
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        var education = try #require(json["education"] as? [String: Any])
        education.removeValue(forKey: "recovery")
        json["education"] = education
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        let persistence = LifePersistence(saveURL: url)
        guard case .loaded(let migrated) = persistence.load() else {
            Issue.record("v20 education save should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.education.recovery == EducationRecoveryState())
        #expect(migrated.finance.studentDebt == 6_300)
        #expect(migrated.random == gameplay)
        #expect(migrated.world.worldRandom == economy)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func vehicleTransactionsAppearInPlaytestDiagnostics() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-vehicle-playtest-\(UUID().uuidString)", isDirectory: true)
        var state = LifeState(name: "Vehicle recorder", seed: 71_025)
        state.character.age = 30
        state.career.level = .senior
        state.cash = 10_000_000
        let recorder = FilePlaytestRecorder(baseURL: directory)
        let simulator = LifeSimulator(
            state: state,
            store: LifePersistence(saveURL: directory.appendingPathComponent("save.json")),
            playtestRecorder: recorder
        )
        _ = try #require(simulator.purchaseAsset(listingID: "helicopter-utility"))
        let report = try #require(recorder.currentReport())
        #expect(report.moments.last?.source.kind == .assetTransaction)
        #expect(report.moments.last?.state.vehicleCounts?["helicopter"] == 1)
        #expect(report.moments.last?.state.vehicleResaleValue == 429_000)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func propertyAmenitiesAppearInHistoryAndPlaytestDiagnostics() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-amenity-playtest-\(UUID().uuidString)", isDirectory: true)
        var state = LifeState(name: "Amenity recorder", seed: 71_023)
        state.character.age = 35
        state.career.level = .senior
        state.cash = 500000
        _ = try #require(AssetSystem.purchase(listingID: "house-family", state: &state))
        let propertyID = try #require(state.assets.properties.first?.id)
        let recorder = FilePlaytestRecorder(baseURL: directory)
        let simulator = LifeSimulator(
            state: state,
            store: LifePersistence(saveURL: directory.appendingPathComponent("save.json")),
            playtestRecorder: recorder
        )
        _ = try #require(simulator.installPropertyAmenity(propertyID: propertyID, amenityID: .homeGym))
        #expect(simulator.state.history.first?.headline == "You Added Home gym")
        let report = try #require(recorder.currentReport())
        #expect(report.schemaVersion == 10)
        #expect(report.moments.last?.source.kind == .assetTransaction)
        #expect(report.moments.last?.source.identifier == "property-upgrade:\(propertyID):homeGym")
        #expect(report.moments.last?.state.propertyAmenityCount == 1)
        #expect(report.moments.last?.state.propertyImprovementValue == 11_700)
        #expect(report.moments.last?.state.propertyAmenityUpkeep == 1_800)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func familyLifecycleAgesOnlyInfluentialPeople() throws {
        var state = partneredState(seed: 7_200, bond: 75)
        state.partner?.stage = .married
        state.partner?.committed = true
        state.family.intention = .buildingFamily
        let simulator = isolatedSimulator(state: state)
        _ = try #require(simulator.execute(.familyPlanning))
        let child = try #require(simulator.state.family.children.first)
        #expect(child.age == 0)
        simulator.ageUp()
        #expect(simulator.state.family.children.first?.age == 1)
        #expect(simulator.state.family.contacts.isEmpty)
    }

    @Test func childfreeLifeIsPlayableReversibleAndNeverCreatesAChildByImplication() throws {
        var state = partneredState(seed: 7_201, bond: 75)
        state.partner?.stage = .committed
        state.partner?.committed = true
        state.family.intention = .openToChildren
        let simulator = isolatedSimulator(state: state)

        let childfree = try #require(simulator.execute(.chooseChildfree))
        #expect(childfree.headline == "You Chose A Childfree Life")
        #expect(simulator.state.family.intention == .childfree)
        #expect(simulator.state.family.children.isEmpty)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .familyPlanning)) == .available)

        _ = try #require(simulator.execute(.familyPlanning))
        #expect(simulator.state.family.intention == .openToChildren)
        #expect(simulator.state.family.children.isEmpty)

        var parentState = simulator.state
        parentState.family.children = [ChildState(name: "Alex", age: 2, temperament: .curious)]
        parentState.actionUsage.removeValue(forKey: ActionID.chooseChildfree.rawValue)
        let parent = isolatedSimulator(state: parentState)
        #expect(parent.availability(for: DomainActionRegistry.action(for: .chooseChildfree)) == .locked("This choice is only available before parenthood"))
    }

    @Test func endedRelationshipsRemainPartOfPersistenceAndLifeReview() throws {
        var state = partneredState(seed: 7_202, bond: 42, resentment: 61)
        state.character.age = 40
        state.partner?.startedAge = 22
        state.partner?.stage = .married
        state.partner?.committed = true
        let formerName = try #require(state.partner?.name)

        let outcome = FamilySystem.resolve(.separate, state: &state)
        #expect(outcome.headline == "You Ended The Shared Future")
        #expect(state.partner == nil)
        #expect(!state.flags.hasPartner)
        let former = try #require(state.formerRelationships.first)
        #expect(former.name == formerName)
        #expect(former.yearsTogether == 18)
        #expect(former.finalStage == .married)
        #expect(former.reason == .playerSeparated)
        #expect(LifeReviewModel.build(from: state).relationshipLine.contains("18-year relationship"))
        #expect(LifeReviewModel.build(from: state).legacySummary.contains(formerName))

        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(restored.formerRelationships == state.formerRelationships)
        #expect(restored.partner == nil)

        var ruptured = partneredState(seed: 7_203, bond: 20, resentment: 85)
        var social = SocialReactivitySystem()
        _ = social.applyPartnerEffect(PartnerEffect(endRelationship: true), state: &ruptured)
        #expect(ruptured.partner == nil)
        #expect(ruptured.formerRelationships.first?.reason == .partnerLeftAfterRupture)
    }

    @Test func caregivingNamesThePersonAndPressureCanResolve() throws {
        var state = LifeState(name: "Care", seed: 7_204)
        state.character.age = 35
        state.lifeStage = .build

        let care = FamilySystem.resolve(.caregive, state: &state)
        let contact = try #require(state.family.contacts.first)
        #expect(care.headline == "Care Became Part Of The Week")
        #expect(care.detail?.contains(contact.name) == true)
        #expect(state.family.caregivingLoad == 8)
        #expect(contact.lastResolvedAge == 35)

        state.character.age = 36
        let activeYear = FamilySystem.resolveYear(state: &state)
        #expect(state.family.caregivingLoad == 8)
        #expect(!activeYear.bullets.contains("The caregiving season eased"))

        state.character.age = 37
        let easedYear = FamilySystem.resolveYear(state: &state)
        #expect(state.family.caregivingLoad == 0)
        #expect(easedYear.bullets.contains("The caregiving season eased"))
    }

    @Test func adultChildTransitionsArePlayerReadableAndPersisted() throws {
        var state = LifeState(name: "Parent", seed: 7_205)
        state.character.age = 45
        state.family.children = [ChildState(name: "River", age: 17, temperament: .calm, bond: 70)]

        let adulthood = FamilySystem.resolveYear(state: &state)
        #expect(state.family.children.first?.age == 18)
        #expect(state.family.children.first?.dependent == false)
        #expect(state.family.children.first?.adultOutcome == .independent)
        #expect(adulthood.bullets.contains("River reached adulthood · independent"))

        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(restored.family.children.first?.adultOutcome == .independent)
        #expect(LifeReviewModel.build(from: restored).legacySummary.contains("Adult outcomes"))
    }

    @Test func dependentCostsAppearOnceInTheFinanceLedger() {
        var state = LifeState(name: "Household costs", seed: 7_207)
        state.character.age = 35
        state.lifeStage = .build
        state.career.track = .office
        state.career.level = .established
        state.family.children = [ChildState(name: "Sam", age: 8, temperament: .social)]

        var withoutChild = state
        withoutChild.family.children = []
        let baseline = FinanceSystem.yearlySettlement(state: &withoutChild)
        let household = FinanceSystem.yearlySettlement(state: &state)
        #expect(household.deltas.cash == baseline.deltas.cash - 6_000)
        #expect(state.finance.annualLedger.livingCosts == withoutChild.finance.annualLedger.livingCosts + 6_000)

        let family = FamilySystem.resolveYear(state: &state)
        #expect(family.deltas.cash == 0)
        #expect(family.deltas.play == -1)
        #expect(family.bullets.contains("Dependents 1"))
    }

    @Test func versionTwentySixAddsEmptyRelationshipHistoryWithoutChangingTheLife() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v26-relationships-\(UUID().uuidString).json")
        var source = partneredState(seed: 7_206, bond: 68)
        source.saveVersion = 26
        let randomStreams = source.randomStreams
        let partner = source.partner
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        json.removeValue(forKey: "formerRelationships")
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        let persistence = LifePersistence(saveURL: url)
        guard case .loaded(let migrated) = persistence.load() else {
            Issue.record("v26 relationship save should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.formerRelationships.isEmpty)
        #expect(migrated.partner == partner)
        #expect(migrated.randomStreams == randomStreams)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func canonicalHealthCapsConditionsAndManagementImprovesThem() throws {
        var state = LifeState(name: "Health", seed: 7_300)
        state.cash = 500
        state.health.conditions = [
            ChronicCondition(kind: .depression, severity: 40, management: 0),
            ChronicCondition(kind: .chronicPain, severity: 50, management: 0),
            ChronicCondition(kind: .cardiovascularStrain, severity: 45, management: 0),
            ChronicCondition(kind: .metabolicIllness, severity: 30, management: 0)
        ]
        state.clamp()
        #expect(state.health.conditions.count == 3)
        let before = state.health.conditions.map(\.severity)
        let simulator = isolatedSimulator(state: state)
        _ = try #require(simulator.execute(.manageCondition))
        #expect(zip(before, simulator.state.health.conditions.map(\.severity)).allSatisfy { $1 < $0 })
        #expect(simulator.state.stats.health == simulator.state.health.overall)
    }

    @Test func yearlyDriftAndSelfCareRemainCanonicalThroughClamping() throws {
        var state = LifeState(name: "Canonical health", seed: 7_301)
        state.character.age = 40
        state.lifeStage = .build
        let before = state.health.overall
        let year = HealthSystem.yearlyDrift(state: &state, world: WorldModifierSnapshot())

        #expect(year.deltas.health == -2)
        #expect(state.health.overall == before - 2)
        state.clamp()
        #expect(state.stats.health == before - 2)

        let simulator = isolatedSimulator(state: state)
        let rest = try #require(simulator.execute(.rest))
        #expect(rest.deltas.health > 0)
        #expect(simulator.state.health.overall == state.health.overall + rest.deltas.health)
        var clamped = simulator.state
        clamped.clamp()
        #expect(clamped.stats.health == clamped.health.overall)
    }

    @Test func chronicConditionsStabilizeWithCareAndRelapseWithoutMaintenance() throws {
        var state = LifeState(name: "Managed health", seed: 7_302)
        state.cash = 500
        state.health.bodyLoad = 20
        state.health.conditions = [
            ChronicCondition(kind: .chronicPain, severity: 12, management: 18)
        ]

        let managed = ConditionHealthSystem.resolve(.manage, state: &state)
        #expect(managed.headline == "Care Made The Condition Manageable")
        #expect(state.health.conditions[0].status == .stable)
        let stabilizedLoad = state.health.bodyLoad

        var relapse: SystemYearDeltas?
        for _ in 0..<6 where state.health.conditions[0].status == .stable {
            let year = ConditionHealthSystem.resolveYear(state: &state)
            if !year.consequences.isEmpty { relapse = year }
        }
        #expect(state.health.bodyLoad < stabilizedLoad)
        #expect(state.health.conditions[0].status == .active)
        #expect(state.health.conditions[0].severity >= 18)
        #expect(relapse?.consequences.first?.kind == .illness)
        #expect(relapse?.bullets.contains("Chronic pain became active again") == true)
    }

    @Test func healthRecoveryActionsRepairCanonicalHealthBeforeAgingResumes() throws {
        var state = LifeState(name: "Health recovery", seed: 7_303)
        state.cash = 500
        state.health.physicalWellbeing = 0
        state.health.mentalWellbeing = 0
        state.syncHealthCompatibility()
        state.recovery = RecoveryWindow(kind: .health, openedAge: state.character.age)
        let simulator = isolatedSimulator(state: state)

        for action in [ActionID.rest, .exercise, .seekCare] where simulator.state.recovery != nil {
            _ = try #require(simulator.execute(action))
        }

        #expect(simulator.state.recovery == nil)
        #expect(simulator.state.health.overall > 12)
        #expect(simulator.state.stats.health == simulator.state.health.overall)
        let age = simulator.state.character.age
        simulator.ageUp()
        #expect(simulator.state.character.age == age + 1)
        #expect(!simulator.state.isGameOver)
    }

    @Test func versionTwentySevenConditionsMigrateActiveAndHealthPersistsToLifeReview() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v27-health-\(UUID().uuidString).json")
        var source = LifeState(name: "Health history", seed: 7_304)
        source.saveVersion = 27
        source.health.conditions = [
            ChronicCondition(kind: .depression, severity: 22, management: 9)
        ]
        let streams = source.randomStreams
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        var health = try #require(json["health"] as? [String: Any])
        var conditions = try #require(health["conditions"] as? [[String: Any]])
        conditions[0].removeValue(forKey: "status")
        health["conditions"] = conditions
        json["health"] = health
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        guard case .loaded(let migrated) = LifePersistence(saveURL: url).load() else {
            Issue.record("v27 health save should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.health.conditions[0].status == .active)
        #expect(migrated.randomStreams == streams)

        var reviewed = migrated
        reviewed.health.conditions[0].status = .stable
        reviewed.isGameOver = true
        reviewed.endReason = .naturalCauses
        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(reviewed))
        #expect(restored.health.conditions[0].status == .stable)
        #expect(LifeReviewModel.build(from: restored).healthLine.contains("stable through ongoing care"))
        #expect(restored.lifeSummary.contains("Health:"))
        try? FileManager.default.removeItem(at: url)
    }

    @Test func identityTradeoffsThreadsAndLegacyRemainNonFinancial() {
        let supported = LifeState(name: "Supported", seed: 7_400, context: .supported, trait: .driven)
        let precarious = LifeState(name: "Precarious", seed: 7_400, context: .precarious, trait: .empathetic)
        #expect(supported.cash != precarious.cash)
        #expect(supported.career.burnout > precarious.career.burnout)
        var archive = LegacyArchive()
        archive.add(LegacyEcho(name: "One", endingAge: 80, headline: "A life", completedAt: Date(timeIntervalSince1970: 1)))
        #expect(archive.echoes.count == 1)
        #expect(precarious.cash == LifeState(name: "Precarious", seed: 7_400, context: .precarious, trait: .empathetic).cash)
    }

    @Test func typedConsequencesDeduplicateStabilizeAndSurviveOldThreadData() throws {
        var state = LifeState(name: "Continuity", seed: 7_401)
        state.character.age = 30
        let consequence = DomainConsequence(
            source: .career, target: .finance, kind: .layoff, magnitude: .major,
            openedAge: 30, yearsRemaining: 3,
            headline: "The layoff still shapes your choices",
            detail: "Lost income is still narrowing the household."
        )
        LifeThreadSystem.open([consequence, consequence], state: &state)
        #expect(state.lifeThreads.count == 1)
        #expect(state.lifeThreads[0].source == .career)
        #expect(state.lifeThreads[0].target == .finance)
        #expect(YearContext(state: state).pressure(on: .finance) == 4)

        LifeThreadSystem.stabilize(kind: .layoff, amount: 2, state: &state)
        #expect(state.lifeThreads[0].resolution == .stabilizing)
        state.character.age = 31
        _ = LifeThreadSystem.resolveYear(state: &state)
        #expect(state.lifeThreads[0].intensity == 1)
        #expect(state.lifeThreads[0].yearsRemaining == 2)

        let legacy = Data(#"{"kind":"debt","headline":"Old debt","intensity":3,"openedAge":22,"yearsRemaining":2}"#.utf8)
        let decoded = try JSONDecoder().decode(LifeThread.self, from: legacy)
        #expect(decoded.source == nil)
        #expect(decoded.target == nil)
        #expect(decoded.resolution == .open)
    }

    @Test func leavingSchoolWithoutDiplomaCreatesCareerContinuity() {
        var state = LifeState(name: "Detour", seed: 7_403, startingAge: 17)
        state.character.age = 18
        state.education.academicStanding = 20

        let outcome = EducationSystem.resolveYear(state: &state)

        #expect(!state.education.highSchoolDiploma)
        #expect(outcome.consequences.count == 1)
        #expect(outcome.consequences.first?.source == .education)
        #expect(outcome.consequences.first?.target == .career)
        #expect(outcome.consequences.first?.kind == .majorDecision)

        var pressured = state
        LifeThreadSystem.open(outcome.consequences, state: &pressured)
        let world = WorldSystem.modifiers(for: state.world)
        #expect(CareerSystem.jobSearchChance(state: pressured, world: world)
            < CareerSystem.jobSearchChance(state: state, world: world))
    }

    @Test func receivingDomainOwnsTypedConsequencePressure() {
        var baseline = LifeState(name: "Baseline", seed: 7_402)
        baseline.character.age = 32
        baseline.lifeStage = .build
        baseline.cash = 50_000
        var pressured = baseline
        LifeThreadSystem.open([
            DomainConsequence(
                source: .career, target: .finance, kind: .layoff, magnitude: .major,
                openedAge: 32, yearsRemaining: 3,
                headline: "Work disappeared",
                detail: "The household has to absorb the loss."
            )
        ], state: &pressured)

        _ = FinanceSystem.yearlySettlement(state: &baseline)
        _ = FinanceSystem.yearlySettlement(state: &pressured)
        #expect(pressured.finance.annualLedger.livingCosts == baseline.finance.annualLedger.livingCosts + 1_600)
        #expect(pressured.finance.financialStress > baseline.finance.financialStress)
        #expect(pressured.career == baseline.career)
    }

    @Test func careerBurnoutUsesTypedHealthAndRelationshipHandoffs() {
        var source = LifeState(name: "Burned out", seed: 7_404)
        source.character.age = 38
        source.lifeStage = .build
        source.career.level = .established
        source.career.burnout = 76
        source.partner = PartnerState(name: "Avery", startedAge: 30, compatibility: 60)
        let healthBefore = source.health
        let partnerBefore = source.partner

        let career = CareerSystem.resolveYear(state: &source)

        #expect(career.consequences.contains { $0.source == .career && $0.target == .health && $0.kind == .burnout })
        #expect(career.consequences.contains { $0.source == .career && $0.target == .relationships && $0.kind == .burnout })
        #expect(source.health == healthBefore)
        #expect(source.partner == partnerBefore)

        LifeThreadSystem.open(career.consequences, state: &source)
        var baseline = source
        baseline.lifeThreads = []
        _ = HealthSystem.yearlyDrift(state: &baseline)
        _ = HealthSystem.yearlyDrift(state: &source)
        _ = FamilySystem.resolveYear(state: &baseline)
        _ = FamilySystem.resolveYear(state: &source)
        #expect(source.health.overall < baseline.health.overall)
        #expect((source.partner?.resentment ?? 0) > (baseline.partner?.resentment ?? 0))
    }

    @Test func boundariesStabilizeOnlyCareerBurnoutAtARealOpportunityCost() {
        var state = LifeState(name: "Boundaries", seed: 7_405)
        state.character.age = 40
        state.career.level = .established
        state.career.burnout = 85
        LifeThreadSystem.open([
            DomainConsequence(
                source: .career, target: .health, kind: .burnout, magnitude: .major,
                openedAge: 40, yearsRemaining: 3, headline: "Work is consuming recovery", detail: "Career pressure"
            ),
            DomainConsequence(
                source: .family, target: .health, kind: .familyConflict, magnitude: .major,
                openedAge: 40, yearsRemaining: 3, headline: "Care is consuming recovery", detail: "Family pressure"
            )
        ], state: &state)
        let performance = state.career.performance

        _ = CareerSystem.resolve(.boundaries, state: &state, world: WorldSystem.modifiers(for: state.world))

        #expect(state.career.burnout == 71)
        #expect(state.career.performance == performance - 3)
        #expect(state.lifeThreads.first { $0.kind == .burnout }?.intensity == 2)
        #expect(state.lifeThreads.first { $0.kind == .familyConflict }?.intensity == 4)
    }

    @Test func financialPressureReachesHousingAndHealthThroughTypedReceivers() throws {
        var state = LifeState(name: "Thin margin", seed: 7_406)
        state.character.age = 36
        state.lifeStage = .build
        state.career.level = .established
        state.cash = 200_000
        _ = try #require(AssetSystem.purchase(listingID: "house-starter-condo", state: &state))
        state.finance.consumerDebt = 300
        state.finance.financialStress = 100
        state.assets.properties[0].delinquentYears = 2
        let assetsBefore = state.assets
        let healthBefore = state.health

        let finance = FinanceSystem.yearlySettlement(state: &state)

        #expect(finance.consequences.contains { $0.source == .finance && $0.target == .relationships })
        #expect(finance.consequences.count <= 3)
        #expect(finance.consequences.contains { $0.source == .finance && $0.target == .health })
        #expect(state.assets == assetsBefore)
        #expect(state.health == healthBefore)

        LifeThreadSystem.open(finance.consequences, state: &state)
        var baselineAssets = state.assets
        var pressuredAssets = state.assets
        _ = propertyReceiptYear(assets: &baselineAssets, missed: false)
        _ = propertyReceiptYear(assets: &pressuredAssets, missed: true)
        #expect(baselineAssets.properties[0].delinquentYears == 1)
        #expect(pressuredAssets.properties[0].delinquentYears == 3)
    }

    @Test func illnessAndCaregivingUseTypedCapacityHandoffs() {
        var ill = LifeState(name: "Low capacity", seed: 7_407)
        ill.character.age = 38
        ill.lifeStage = .build
        ill.career.level = .established
        ill.health.physicalWellbeing = 28
        ill.health.mentalWellbeing = 28
        ill.syncHealthCompatibility()
        ill.partner = PartnerState(name: "Avery", startedAge: 30, compatibility: 60)
        ill.family.children = [ChildState(name: "Sam", temperament: .calm)]
        let careerBefore = ill.career
        let familyBefore = ill.family

        let health = HealthSystem.yearlyDrift(state: &ill)

        #expect(health.consequences.contains { $0.source == .health && $0.target == .career })
        #expect(health.consequences.contains { $0.source == .health && $0.target == .family })
        #expect(ill.career == careerBefore)
        #expect(ill.family == familyBefore)

        LifeThreadSystem.open(health.consequences, state: &ill)
        var baseline = ill
        baseline.lifeThreads = []
        _ = CareerSystem.resolveYear(state: &baseline)
        _ = CareerSystem.resolveYear(state: &ill)
        _ = FamilySystem.resolveYear(state: &baseline)
        _ = FamilySystem.resolveYear(state: &ill)
        #expect(ill.career.performance < baseline.career.performance)
        #expect(ill.family.caregivingLoad > baseline.family.caregivingLoad)

        var caregiving = baseline
        caregiving.family.caregivingLoad = 70
        let financeBefore = caregiving.finance
        let healthBefore = caregiving.health
        let care = FamilySystem.resolveYear(state: &caregiving)
        #expect(Set(care.consequences.map(\.target)) == [.career, .finance, .health])
        #expect(caregiving.finance == financeBefore)
        #expect(caregiving.health == healthBefore)
    }

    @Test func separationAllowsAChangedRelationshipFutureAndReviewKeepsBoth() {
        var state = LifeState(name: "Afterward", seed: 7_408)
        state.cash = 50_000
        state.character.age = 35
        state.lifeStage = .build
        state.stats.love = 80
        state.partner = PartnerState(name: "Taylor", startedAge: 25, compatibility: 55)
        _ = FamilySystem.resolve(.separate, state: &state)
        #expect(state.partner == nil)
        #expect(state.formerRelationships.first?.name == "Taylor")

        let simulator = isolatedSimulator(state: state)
        simulator.execute(.goOnDate)

        #expect(simulator.state.partner != nil)
        #expect(simulator.state.formerRelationships.first?.name == "Taylor")
        let review = LifeReviewModel.build(from: simulator.state)
        #expect(review.relationshipLine.contains("Earlier"))
        #expect(review.relationshipLine.contains("Taylor"))
    }

    @Test func lifeReviewNamesUnresolvedTypedBurdens() {
        var state = LifeState(name: "Unfinished", seed: 7_409)
        state.character.age = 70
        LifeThreadSystem.open([
            DomainConsequence(
                source: .career, target: .health, kind: .burnout, magnitude: .major,
                openedAge: 69, yearsRemaining: 2,
                headline: "Work is consuming your recovery", detail: "The burden remained."
            )
        ], state: &state)

        let review = LifeReviewModel.build(from: state)
        #expect(review.continuityLine.contains("1 unresolved burden"))
        #expect(review.continuityLine.contains("Work is consuming your recovery"))
        #expect(review.legacySummary.contains("Continuity:"))
    }

    @Test func futureSaveVersionIsRejectedWithoutBeingOverwritten() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-future-fixture-\(UUID().uuidString).json")
        var future = LifeState(name: "Future", seed: 9_999)
        future.saveVersion = LifeState.currentSaveVersion + 1
        let data = try JSONEncoder().encode(future)
        try data.write(to: url, options: .atomic)

        let persistence = LifePersistence(saveURL: url)
        let preservedURL = url.appendingPathExtension("preserved")
        if case .freshStart(let message) = persistence.load() {
            #expect(message?.contains("newer app") == true)
        } else {
            Issue.record("Future saves must not load in an older app")
        }
        #expect(try Data(contentsOf: url) == data)
        #expect(try Data(contentsOf: preservedURL) == data)

        if case .failure(let error) = persistence.save(LifeState(name: "Current", seed: 10_000)) {
            Issue.record("Current save failed: \(error)")
        }
        #expect(try Data(contentsOf: preservedURL) == data)
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: preservedURL)
    }

    @Test func releaseGateScenariosReplayExactly() {
        let scenarios: [(seed: UInt64, policy: String, years: Int)] = [
            (101, "balanced", 20),
            (202, "grind", 50),
            (303, "social", 50),
            (404, "survival", 80),
            (505, "balanced", 80)
        ]

        for scenario in scenarios {
            let first = runScenario(seed: scenario.seed, policy: scenario.policy, years: scenario.years)
            let second = runScenario(seed: scenario.seed, policy: scenario.policy, years: scenario.years)
            #expect(first == second, "Seed \(scenario.seed) / \(scenario.policy) diverged")
            #expect(first.history.count <= 40)
            #expect(first.isValidSave)
        }
    }

    @Test func terminalLifeHasAReadableReviewSummary() {
        var state = LifeState(name: "A", seed: 8)
        state.recovery = RecoveryWindow(kind: .health, openedAge: 18)
        let simulator = isolatedSimulator(state: state)
        simulator.ageUp()
        #expect(simulator.state.isGameOver)
        #expect(simulator.state.history.first?.headline == "Life Ended")
        #expect(simulator.state.lifeSummary.contains("relationship"))
        #expect(simulator.state.lifeSummary.contains("financial run"))
    }

    @Test func influenceLedgerCapsAndResetsAtAgeUp() {
        let simulator = isolatedSimulator(state: partneredState(seed: 11))
        // Extra shifts have an action-specific two-use window.
        simulator.execute(.workShift)
        simulator.execute(.workShift)
        #expect(simulator.state.influenceLedger.current.work >= 3)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .workShift)) != .available)
        simulator.ageUp()
        for _ in 0..<2 {
            if let event = simulator.state.pendingEvent { simulator.execute(event.choices[0].id) }
        }
        #expect(simulator.state.influenceLedger.current == InfluenceVector())
        #expect((simulator.state.influenceLedger.recentYears.first?.scores.work ?? 0) >= 3)
    }

    @Test func repeatedConnectionHasItsOwnRecognizableLifeShape() {
        var momentum = MomentumState()
        let connection = YearInfluenceSnapshot(
            age: 30,
            scores: InfluenceVector(family: 3),
            influentialAction: .reachOut
        )

        momentum.absorb(snapshot: connection)
        momentum.absorb(snapshot: YearInfluenceSnapshot(
            age: 31,
            scores: connection.scores,
            influentialAction: connection.influentialAction
        ))

        #expect(LifeShape.allCases.count == 6)
        #expect(momentum.shape == .connected)
        #expect(momentum.stripLabel.contains("people-centered"))

        var state = LifeState(name: "Community", seed: 11)
        state.momentum = momentum
        state.endReason = .naturalCauses
        #expect(LifeReviewModel.build(from: state).legacyHeadline.contains("connected life"))
    }

    @Test func partnerCreationIsSeededAndNeverReplacesAnExistingPartner() throws {
        var initial = LifeState(name: "A", seed: 44)
        initial.cash = 50_000
        let first = isolatedSimulator(state: initial)
        let second = isolatedSimulator(state: initial)
        for simulator in [first, second] {
            simulator.execute(.reachOut)
            simulator.execute(.reachOut)
            simulator.execute(.goOnDate)
        }
        #expect(first.state == second.state)
        let original = try #require(first.state.partner)
        #expect(original.coreFlags.count == 2)
        #expect(Set(original.coreFlags).count == 2)
        first.execute(.goOnDate)
        let after = try #require(first.state.partner)
        #expect(after.name == original.name)
        #expect(after.startedAge == original.startedAge)
        #expect(after.compatibility == original.compatibility)
        #expect(after.coreFlags == original.coreFlags)
    }

    @Test func personalityFlagsChangeTheSameWorkHeavyYear() throws {
        var demanding = partneredState(seed: 12, flags: [.demanding, .cautious])
        var independent = partneredState(seed: 12, flags: [.independent, .supportive])
        demanding.influenceLedger.current = InfluenceVector(work: 3)
        independent.influenceLedger.current = InfluenceVector(work: 3)
        var demandingSystem = SocialReactivitySystem()
        var independentSystem = SocialReactivitySystem()
        _ = demandingSystem.resolveYear(state: &demanding, baseDeltas: DeltaSummary())
        _ = independentSystem.resolveYear(state: &independent, baseDeltas: DeltaSummary())
        #expect(try #require(demanding.partner).bond < #require(independent.partner).bond)
        #expect(try #require(demanding.partner).resentment > #require(independent.partner).resentment)
    }

    @Test func threeAttentiveYearsTeachSecurity() throws {
        var state = partneredState(seed: 13, flags: [.loyal, .supportive])
        for _ in 0..<3 {
            state.character.age += 1
            state.influenceLedger.current = InfluenceVector(family: 3, stability: 2)
            var system = SocialReactivitySystem()
            _ = system.resolveYear(state: &state, baseDeltas: DeltaSummary())
        }
        let partner = try #require(state.partner)
        #expect(partner.flags.contains(.secure))
        #expect(!partner.flags.contains(.guarded))
    }

    @Test func unifiedPartnerRuleIsCanonicalOverLegacyBranches() throws {
        let simulator = isolatedSimulator(state: partneredState(seed: 71, flags: [.supportive, .loyal, .secure]))
        simulator.execute(.repairConflict)

        let partner = try #require(simulator.state.partner)
        let outcome = try #require(simulator.lastOutcome)
        #expect(partner.bond == 60) // base +4, unified empathetic reaction +1
        #expect(partner.resentment == 0)
        #expect(outcome.headline == "Care Met Care")
        #expect(outcome.personalityContext?.contains("Empathetic partner") == true)
        #expect(simulator.state.history.first?.detail.contains("empathy") == true)
    }

    @Test func personalityResponsesAreLimitedToOncePerActionPerAge() throws {
        let simulator = isolatedSimulator(state: partneredState(seed: 72, flags: [.cautious, .supportive]))
        simulator.execute(.party)
        let afterFirst = simulator.state
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .party)) == .available)
        simulator.execute(.party)
        #expect(simulator.state.actionUseCount(for: ActionID.party.rawValue) == 2)
        #expect(simulator.state.partner?.personalityActionUsage == afterFirst.partner?.personalityActionUsage)
        simulator.execute(.party)
        #expect(simulator.state.actionUseCount(for: ActionID.party.rawValue) == 3)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .party)) != .available)

        simulator.ageUp()
        if let event = simulator.state.pendingEvent { simulator.execute(event.choices[0].id) }
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .party)) == .available)
    }

    @Test func unpartneredActionsKeepTheirExistingOutcome() throws {
        var initial = LifeState(name: "Solo", seed: 73)
        initial.cash = 50_000
        let simulator = isolatedSimulator(state: initial)
        simulator.execute(.party)
        let outcome = try #require(simulator.lastOutcome)
        // NPC flavor may rename the headline; core path still applies play deltas and no partner.
        #expect(outcome.deltas.play > 0)
        #expect(simulator.state.partner == nil)
        #expect(simulator.state.usedActionThisAge(.party))
    }

    @Test func simulationAutoResolvesPartnerEvents() {
        let simulator = isolatedSimulator(state: partneredState(seed: 74, bond: 43, resentment: 44, flags: [.demanding, .cautious]))
        let report = simulator.simulate(years: 3, policy: "grind")
        #expect(report.contains("simulate grind:"))
        // Completed the requested years or ended the life cleanly — never stuck on a sheet.
        #expect(simulator.state.pendingEvent == nil)
        #expect(simulator.state.isValidSave)
        #expect(report.contains("3y") || simulator.state.isGameOver || simulator.state.character.age >= 20)
    }

    @Test func namedDiagnosticPoliciesActuallyTraverseTheirDomainPaths() {
        let social = isolatedSimulator(state: LifeState(name: "Social Path", seed: 7_401))
        _ = social.simulate(years: 6, policy: "social")
        #expect(social.state.partner != nil)
        #expect(social.state.influenceLedger.recentYears.contains { $0.scores.family > 0 })

        let grind = isolatedSimulator(state: LifeState(name: "Grind Path", seed: 7_402, origin: .academic))
        _ = grind.simulate(years: 12, policy: "grind")
        #expect(grind.state.education.credential)
        #expect(grind.state.job.tier == .skilled || grind.state.job.tier == .retired)
    }

    @Test func lightweightNPCsAreCreatedLazilyAndDeterministically() throws {
        let first = isolatedSimulator(state: LifeState(name: "A", seed: 801))
        let second = isolatedSimulator(state: LifeState(name: "A", seed: 801))
        #expect(first.state.npcs.all.isEmpty)

        first.execute(.study); second.execute(.study)
        let firstTeacher = try #require(first.state.npcs[.teacher])
        let secondTeacher = try #require(second.state.npcs[.teacher])
        #expect(firstTeacher == secondTeacher)
        #expect(firstTeacher.importance == .pivotal)
        #expect(first.state.npcs[.friend] == nil)

        first.execute(.seeFriends)
        #expect(first.state.npcs[.friend]?.importance == .recurring)
    }

    @Test func friendPersonalityOnlyChangesTheSocialActionPath() throws {
        var state = LifeState(name: "Social", seed: 802)
        state.npcs[.friend] = NPCState(
            name: "Jamie", role: .friend, importance: .recurring,
            coreFlags: [.sociable, .dependable], lastInteractionAge: state.character.age
        )
        let simulator = isolatedSimulator(state: state)
        simulator.execute(.seeFriends)

        let friend = try #require(simulator.state.npcs[.friend])
        let outcome = try #require(simulator.lastOutcome)
        #expect(friend.rapport == 1)
        #expect(friend.usedPersonalityResponse(for: .seeFriends, at: simulator.state.character.age))
        #expect(outcome.personalityContext?.contains("Jamie · Friend") == true)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .seeFriends)) == .available)
        #expect(simulator.state.partner == nil)
    }

    @Test func bossAndTeacherBranchesStayInTheirDomains() throws {
        var state = LifeState(name: "Work", seed: 803)
        state.npcs[.teacher] = NPCState(name: "Dr. Patel", role: .teacher, importance: .pivotal, coreFlags: [.encouraging], lastInteractionAge: 18)
        state.npcs[.boss] = NPCState(name: "Dana", role: .boss, importance: .recurring, coreFlags: [.fair], lastInteractionAge: 18)
        let simulator = isolatedSimulator(state: state)

        simulator.execute(.study)
        #expect(simulator.state.npcs[.teacher]?.rapport == 1)
        #expect(simulator.state.npcs[.boss]?.rapport == 0)
        simulator.execute(.workShift)
        #expect(simulator.state.npcs[.boss]?.rapport == 1)
        #expect(simulator.state.npcs[.teacher]?.rapport == 1)
    }

    @Test func npcDirectoryRoundTripsWithLegacyDefaults() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("onelife-npc-\(UUID().uuidString)")
        let saveURL = directory.appendingPathComponent("save.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var state = LifeState(name: "Save", seed: 804)
        state.npcs[.friend] = NPCState(name: "Avery", role: .friend, importance: .recurring, coreFlags: [.dependable], rapport: 7, lastInteractionAge: 18, learnedStance: .warm)
        let persistence = LifePersistence(saveURL: saveURL)
        if case .failure(let error) = persistence.save(state) { Issue.record("Save failed: \(error)") }
        if case .loaded(let loaded) = persistence.load() {
            #expect(loaded.npcs[.friend]?.name == "Avery")
            #expect(loaded.npcs[.friend]?.learnedStance == .warm)
        } else { Issue.record("NPC directory should round trip") }
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func socialPreviewAndResolveChooseTheSameExistingNPCBranch() throws {
        var state = LifeState(name: "Preview", seed: 805)
        state.npcs[.friend] = NPCState(name: "Jamie", role: .friend, importance: .recurring, coreFlags: [.sociable], lastInteractionAge: 18)
        let action = DomainActionRegistry.action(for: .seeFriends)
        var system = SocialReactivitySystem()
        let preview = system.preview(action: action, state: state)
        let resolved = system.resolve(action: action, state: &state)
        #expect(preview.headline == resolved.headline)
        #expect(preview.npcEffect == resolved.npcEffect)
        #expect(preview.npcRapportDelta == resolved.npcRapportDelta)
    }

    @Test func backgroundNPCsStayHibernatedAndUntouchedAtYearEnd() {
        var state = LifeState(name: "Prune", seed: 806)
        state.flags.attendsSchool = false
        state.npcs[.teacher] = NPCState(name: "Ms. Brooks", role: .teacher, importance: .background, coreFlags: [.fair], lastInteractionAge: 18)
        let before = state.npcs[.teacher]

        #expect(!SystemRegistry.isActive(.social, in: state))
        let simulator = isolatedSimulator(state: state)
        simulator.ageUp()

        #expect(simulator.state.npcs[.teacher] == before)
    }

    @Test func tenYearWorkAndFamilyRunsDiverge() throws {
        let work = isolatedSimulator(state: partneredState(seed: 90, flags: [.demanding, .cautious]))
        let family = isolatedSimulator(state: partneredState(seed: 90, flags: [.loyal, .supportive]))

        for _ in 0..<10 where !work.state.isGameOver && work.state.partner != nil {
            work.execute(.workShift)
            work.ageUp()
            if let event = work.state.pendingEvent {
                let choice: EventChoiceID = event.id == "partner-confrontation" ? .dismiss
                    : event.id == "partner-ultimatum" ? .chooseWork
                    : event.choices[0].id
                work.execute(choice)
            }
        }

        for year in 0..<10 where !family.state.isGameOver {
            family.execute(year.isMultiple(of: 2) ? .reachOut : .goOnDate)
            family.ageUp()
            if let event = family.state.pendingEvent {
                family.execute(event.id == "partner-commitment" ? .accept : event.choices[0].id)
            }
        }

        #expect(work.state.partner == nil)
        #expect(work.state.history.contains { $0.headline == "Work Keeps Winning at Home" })
        let familyPartner = try #require(family.state.partner)
        #expect(familyPartner.bond >= 70)
        #expect(familyPartner.resentment <= 20)
        #expect(familyPartner.committed)
        #expect(familyPartner.flags.contains(.secure))
    }

    @Test func pendingPartnerChoiceCombinesAnnualAndChoiceDeltas() throws {
        let simulator = isolatedSimulator(state: partneredState(seed: 91, bond: 43, resentment: 44, flags: [.demanding, .cautious]))
        simulator.execute(.workShift)
        simulator.ageUp()
        let event = try #require(simulator.state.pendingEvent)
        #expect(event.id == "partner-confrontation")
        let yearCash = event.yearDeltas.cash
        #expect(yearCash != 0)
        simulator.execute(.dismiss)
        let entry = try #require(simulator.state.history.first)
        #expect(entry.deltas.cash == yearCash)
        #expect(entry.deltas.bond < -8)
        #expect(entry.deltas.resentment > 12)
    }

    @Test func saveRoundTripsAndLegacyIsRetained() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("onelife-v3-\(UUID().uuidString)")
        let saveURL = directory.appendingPathComponent("onelife-v3.json")
        let legacyURL = directory.appendingPathComponent("onelife-v1.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var legacyState = partneredState(seed: 91)
        legacyState.saveVersion = 1
        try JSONEncoder().encode(legacyState).write(to: legacyURL)
        let persistence = LifePersistence(saveURL: saveURL, legacySaveURL: legacyURL)
        if case .freshStart(let message) = persistence.load() { #expect(message?.contains("kept safe") == true) }
        else { Issue.record("A legacy-only installation should request a fresh life") }
        #expect(FileManager.default.fileExists(atPath: legacyURL.path))

        let state = partneredState(seed: 92)
        if case .failure(let error) = persistence.save(state) { Issue.record("Save failed: \(error)") }
        if case .loaded(let loaded) = persistence.load() {
            #expect(loaded.character.name == state.character.name)
            #expect(loaded.partner?.name == state.partner?.name)
            #expect(loaded.saveVersion == LifeState.currentSaveVersion)
        } else { Issue.record("Current save should round trip") }
        #expect(FileManager.default.fileExists(atPath: legacyURL.path))
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func phase0InstantAndYearlyLoopStayValid() {
        let simulator = isolatedSimulator(state: LifeState(name: "Loop", seed: 4242))
        for year in 0..<15 where !simulator.state.isGameOver {
            let domain = Domain.primaryTabs[year % Domain.primaryTabs.count]
            if let action = simulator.availableActions(in: domain).first {
                simulator.execute(action.id)
            }
            #expect(simulator.lastOutcome != nil)
            simulator.ageUp()
            if let event = simulator.state.pendingEvent {
                simulator.execute(event.choices[0].id)
            }
            #expect(simulator.state.isValidSave)
        }
        #expect(simulator.state.character.age >= 30)
        #expect(!simulator.state.history.isEmpty)
        #expect(simulator.state.lifeStage == .build || simulator.state.lifeStage == .launch)
    }

    @Test func completeLivesAlwaysTerminateWithEndReason() {
        for origin in OriginPreset.allCases {
            for (seed, policy) in [(UInt64(101), "balanced"), (202, "grind"), (303, "social"), (404, "survival")] {
                let originSalt: UInt64 = origin == .balanced ? 0 : origin == .academic ? 1_000 : 2_000
                let state = runScenario(seed: seed &+ originSalt, policy: policy, years: 120, origin: origin)
                #expect(state.isGameOver || state.character.age >= LifeLimits.maximumAge - 1, "seed \(seed) \(origin)")
                if state.isGameOver {
                    #expect(state.endReason != nil)
                    let review = LifeReviewModel.build(from: state)
                    #expect(!review.legacyHeadline.isEmpty)
                    #expect(review.age == state.character.age)
                }
            }
        }
    }

    @Test func repeatWindowBlocksFarmingUntilAgeUp() {
        let simulator = isolatedSimulator(state: LifeState(name: "Farm", seed: 55))
        for _ in 0..<3 { simulator.execute(.study) }
        let after = simulator.state
        simulator.execute(.study)
        #expect(simulator.state == after)
        if case .locked(let reason) = simulator.availability(for: DomainActionRegistry.action(for: .study)) {
            #expect(reason.contains("Age Up") || reason.contains("year"))
        } else {
            Issue.record("Study should be locked after its annual window")
        }
        simulator.ageUp()
        for _ in 0..<2 {
            if let event = simulator.state.pendingEvent { simulator.execute(event.choices[0].id) }
        }
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .study)) == .available)
    }

    @Test func stageBoundariesAndSchoolExitFire() {
        let simulator = isolatedSimulator(state: LifeState(name: "Stages", seed: 66, origin: .academic))
        // Drive education hard then age into build.
        for _ in 0..<20 where !simulator.state.isGameOver {
            if simulator.state.flags.attendsSchool {
                if case .available = simulator.availability(for: DomainActionRegistry.action(for: .study)) {
                    simulator.execute(.study)
                } else if case .available = simulator.availability(for: DomainActionRegistry.action(for: .attendClass)) {
                    simulator.execute(.attendClass)
                }
            } else {
                simulator.execute(.workShift)
            }
            simulator.ageUp()
            if let event = simulator.state.pendingEvent { simulator.execute(event.choices[0].id) }
            if simulator.state.character.age >= 30 { break }
        }
        #expect(simulator.state.character.age >= 25)
        #expect(simulator.state.lifeStage == .build || simulator.state.lifeStage == .pressure)
        #expect(simulator.state.history.contains { $0.yearSummary?.stageTransition != nil || $0.headline.contains("Building") || $0.headline.contains("Graduat") || $0.headline.contains("School") })
    }

    @Test func lateLifeMortalityPressureIsVisible() {
        var state = LifeState(name: "Elder", seed: 77)
        state.character.age = 70
        state.lifeStage = .legacy
        state.stats.health = 35
        state.job.tier = .retired
        let simulator = isolatedSimulator(state: state)
        simulator.ageUp()
        if let event = simulator.state.pendingEvent { simulator.execute(event.choices[0].id) }
        #expect(simulator.state.mortalityPressure == .vulnerable || simulator.state.mortalityPressure == .critical || simulator.state.isGameOver)
        if !simulator.state.isGameOver {
            #expect(simulator.state.lastYearSummary?.mortalityWarning != nil || simulator.state.mortalityPressure != .stable)
        }
    }

    @Test func postSchoolSkillsActionsUnlockAndSchoolActionsLock() {
        var state = LifeState(name: "Skills", seed: 88)
        state.character.age = 28
        state.flags.attendsSchool = false
        state.lifeStage = .build
        state.cash = 10000
        let simulator = isolatedSimulator(state: state)
        // Simulator re-derives stage from age in init
        #expect(simulator.state.lifeStage == .build)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .study)) != .available)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .networkContacts)) == .available)
        #expect(simulator.availability(for: DomainActionRegistry.action(for: .skillCourse)) == .available)
        simulator.execute(.networkContacts)
        #expect(simulator.state.usedActionThisAge(.networkContacts))
        #expect(simulator.state.stats.rep >= 48)
    }

    @Test func chapterEventsAreStageWeighted() {
        // Launch rent scare only when launch + thin cash
        var launch = LifeState(name: "L", seed: 1)
        launch.lifeStage = .launch
        launch.cash = 100
        let launchWeights = LifeEventRegistry.all.map { ($0.id, $0.weight(launch)) }
        #expect(launchWeights.contains { $0.0 == "first-rent-scare" && $0.1 > 0 })

        var legacy = LifeState(name: "Leg", seed: 2)
        legacy.character.age = 70
        legacy.lifeStage = .legacy
        legacy.flags.attendsSchool = false
        legacy.stats.health = 50
        let legacyWeights = Dictionary(uniqueKeysWithValues: LifeEventRegistry.all.map { ($0.id, $0.weight(legacy)) })
        #expect((legacyWeights["who-you-still-call"] ?? 0) > 0)
        #expect((legacyWeights["school-pressure"] ?? 0) == 0)
    }

    @Test func seededEventMemoryAvoidsImmediateStoryletRepeats() {
        let simulator = isolatedSimulator(state: LifeState(name: "Variety", seed: 6_060))
        let registryIDs = Set(LifeEventRegistry.all.map(\.id))
        var previousRegistryEvent: String?
        var observed = 0

        for _ in 0..<35 where !simulator.state.isGameOver {
            simulator.ageUp()
            if let event = simulator.state.pendingEvent {
                if registryIDs.contains(event.id) {
                    #expect(event.id != previousRegistryEvent)
                    previousRegistryEvent = event.id
                    observed += 1
                }
                simulator.execute(event.choices[0].id)
            }
        }
        #expect(observed >= 3)
        #expect(simulator.state.recentEventIDs.count <= 6)
    }

    @Test func whatMattersPointsAtDomainsAndActions() {
        var state = LifeState(name: "WM", seed: 9)
        state.cash = 20
        state.stats.health = 30
        let items = WhatMattersResolver.items(for: state, limit: 3)
        #expect(!items.isEmpty)
        #expect(items.allSatisfy { $0.suggestedAction != nil })
        #expect(items.contains { $0.domain == .cash || $0.domain == .health })
    }

    @Test func echoFlavorMentionsRecentFocus() {
        var state = LifeState(name: "Echo", seed: 10)
        state.influenceLedger.recentYears = [
            YearInfluenceSnapshot(age: 20, scores: InfluenceVector(work: 3), influentialAction: .workShift)
        ]
        let line = EchoFlavorResolver.line(state: state)
        #expect(line?.contains("work") == true || line?.contains("shift") == true)
    }

    @Test func narrativeVibeTracksStateAndChangesActionFlavor() {
        var grounded = LifeState(name: "Grounded", seed: 10)
        grounded.cash = 50_000
        #expect(NarrativeVibeResolver.resolve(grounded) == .grounded)

        grounded.influenceLedger.current = InfluenceVector(work: 3)
        #expect(NarrativeVibeResolver.resolve(grounded) == .driven)

        grounded.influenceLedger.current = InfluenceVector(family: 3)
        #expect(NarrativeVibeResolver.resolve(grounded) == .connected)

        grounded.cash = 20
        #expect(NarrativeVibeResolver.resolve(grounded) == .strained)

        grounded.recovery = RecoveryWindow(kind: .financial, openedAge: 18)
        #expect(NarrativeVibeResolver.resolve(grounded) == .crisis)

        var crisis = LifeState(name: "Crisis", seed: 11)
        crisis.stats.health = 5
        let simulator = isolatedSimulator(state: crisis)
        simulator.execute(.exercise)
        #expect(simulator.lastOutcome?.narrative.contains("health") == true
            || simulator.lastOutcome?.narrative.contains("body") == true)
    }

    @Test func narrativeFlavorIsSeedStableWithoutConsumingGameplayRandomness() {
        var state = LifeState(name: "Flavor", seed: 41)
        state.stats.health = 12
        let randomBefore = state.random

        let first = NarrativeVibeResolver.flavor("You take the long way home.", state: state)
        let second = NarrativeVibeResolver.flavor("You take the long way home.", state: state)

        #expect(first == second)
        #expect(state.random == randomBefore)
        #expect(NarrativeVibeResolver.flavor(first, state: state) == first)

        let variants = Set((1...24).map { seed -> String in
            var seeded = LifeState(name: "Flavor", seed: UInt64(seed))
            seeded.stats.health = 12
            return NarrativeVibeResolver.flavor("You take the long way home.", state: seeded)
        })
        #expect(variants.count > 1)
    }

    @Test func crossDomainStoryletsStayCompressedAndApplyConsequences() throws {
        let ids = [
            "work-followed-home",
            "money-between-you",
            "body-collected-overtime",
            "friendships-went-quiet",
            "college-first-weeks",
            "college-aid-gap",
            "college-major-doubt",
            "college-internship-opening"
        ]
        let events = try ids.map { id in
            try #require(LifeEventRegistry.all.first { $0.id == id })
        }

        #expect(events.allSatisfy { (5...7).contains($0.headline.split(separator: " ").count) })
        #expect(events.allSatisfy { $0.choices.count <= 3 })

        let workAtHome = try #require(events.first { $0.id == "work-followed-home" })
        #expect(workAtHome.choices.contains { !$0.partnerEffect.isEmpty })

        var pressured = LifeState(name: "Collision", seed: 50)
        pressured.partner = PartnerState(compatibility: 70)
        pressured.flags.hasJob = true
        pressured.influenceLedger.current = InfluenceVector(work: 3)
        #expect(workAtHome.weight(pressured) > 0)

        let body = try #require(events.first { $0.id == "body-collected-overtime" })
        pressured.aggregates.yearsWorked = 11
        pressured.stats.health = 40
        #expect(body.weight(pressured) > 0)
    }

    @Test func worldProfilesAreSeededStableAndDiverse() {
        for seed in UInt64(1)...40 {
            #expect(WorldSystem.initialize(runSeed: seed) == WorldSystem.initialize(runSeed: seed))
        }
        let profiles = Set((UInt64(1)...40).map { seed in
            let profile = WorldSystem.initialize(runSeed: seed).profile
            return "\(profile.costEnvironment.rawValue)-\(profile.laborStructure.rawValue)-\(profile.safetyNet.rawValue)"
        })
        #expect(profiles.count >= 8)
    }

    @Test func publicHealthProfilesAreSeededStableDiverseAndIndependent() {
        let profiles = Set((UInt64(1)...60).map { seed in
            let first = WorldSystem.initialize(runSeed: seed)
            let second = WorldSystem.initialize(runSeed: seed)
            #expect(first.publicHealth == second.publicHealth)
            return "\(first.publicHealth.healthcareCapacity.rawValue)-\(first.publicHealth.diseaseBurden.rawValue)"
        })
        #expect(profiles.count >= 6)

        var state = LifeState(name: "Separate health stream", seed: 91_002)
        state.world.publicHealth.profileDisclosed = true
        state.world.publicHealth.yearsRemaining = 1
        let gameplayRandom = state.random
        let economicRandom = state.world.worldRandom
        let publicHealthRandom = state.world.publicHealth.publicHealthRandom
        _ = WorldSystem.resolvePublicHealthYear(publicHealth: &state.world.publicHealth)
        #expect(state.random == gameplayRandom)
        #expect(state.world.worldRandom == economicRandom)
        #expect(state.world.publicHealth.publicHealthRandom != publicHealthRandom)
    }

    @Test func worldRegistryAndSystemActivationAreExhaustive() {
        #expect(Set(WorldEventRegistry.macroEvents.keys) == Set(WorldMacroCondition.allCases))
        #expect(Set(WorldEventRegistry.macroEvents.values.map(\.id)).count == WorldMacroCondition.allCases.count)
        for condition in WorldMacroCondition.allCases {
            let event = WorldEventRegistry.definition(for: condition)
            let expectedFlag: WorldFlag = switch condition {
            case .steady: WorldFlag.steadyEconomy
            case .expansion: WorldFlag.expansion
            case .recession: WorldFlag.recession
            case .recovery: WorldFlag.recovery
            }
            #expect(event.flag == expectedFlag)
            #expect(!event.transitionWeights.isEmpty)
        }
        #expect(SystemRegistry.isActive(.world, in: LifeState(name: "Registry", seed: 1)))
        #expect(Set(WorldEventRegistry.publicHealthEvents.keys) == Set(WorldPublicHealthCondition.allCases))
        #expect(Set(WorldEventRegistry.publicHealthEvents.values.map(\.id)).count == WorldPublicHealthCondition.allCases.count)
    }

    @Test func worldResolutionNeverAdvancesGameplayRandom() {
        var state = LifeState(name: "Separate streams", seed: 91_001)
        state.world.profileDisclosed = true
        state.world.conditions.macroYearsRemaining = 1
        state.world.nextPriceReviewAge = state.character.age
        let gameplayRandom = state.random
        let oldWorldRandom = state.world.worldRandom

        _ = WorldSystem.resolveYear(world: &state.world, age: state.character.age + 1)

        #expect(state.random == gameplayRandom)
        #expect(state.world.worldRandom != oldWorldRandom)
    }

    @Test func worldTransitionsKeepFlagsExclusiveAndDurationsBounded() {
        var world = WorldSystem.initialize(runSeed: 77_777)
        world.profileDisclosed = true
        for age in 19...92 {
            _ = WorldSystem.resolveYear(world: &world, age: age)
            let macroFlags = world.flags.intersection([.steadyEconomy, .expansion, .recession, .recovery])
            let priceFlags = world.flags.intersection([.inflationShock, .housingCrunch])
            #expect(macroFlags.count == 1)
            #expect(priceFlags.count <= 1)
            #expect((0...10).contains(world.conditions.macroYearsRemaining))
            if world.conditions.price != nil {
                #expect((1...5).contains(world.conditions.priceYearsRemaining))
            }
            #expect(world.flags.intersection([.stablePublicHealth, .seasonalHealthStrain, .publicHealthOutbreak, .publicHealthRecovery]).count == 1)
            #expect(world.flags.intersection([.constrainedHealthcare, .standardHealthcare, .resourcedHealthcare]).count == 1)
            #expect(world.flags.intersection([.lowDiseaseBurden, .typicalDiseaseBurden, .highDiseaseBurden]).count == 1)
            #expect((0...14).contains(world.publicHealth.yearsRemaining))
        }
    }

    @Test func publicHealthModifiersMatchTuningAndCaps() {
        var world = WorldSystem.initialize(runSeed: 2)
        world.publicHealth.healthcareCapacity = .constrained
        world.publicHealth.diseaseBurden = .high
        world.publicHealth.condition = .outbreak
        let pressured = WorldSystem.modifiers(for: world)
        #expect(pressured.careCostMultiplier == 1.35)
        #expect(abs(pressured.careEffectivenessMultiplier - 0.765) < 0.000_001)
        #expect(pressured.conditionDiscoveryModifier == 23)
        #expect(pressured.annualHealthDrift == -2)
        #expect(pressured.medicalDebtMultiplier == 1.50)

        world.publicHealth.healthcareCapacity = .resourced
        world.publicHealth.diseaseBurden = .low
        world.publicHealth.condition = .recovery
        let supported = WorldSystem.modifiers(for: world)
        #expect(abs(supported.careCostMultiplier - 0.945) < 0.000_001)
        #expect(supported.careEffectivenessMultiplier == 1.08)
        #expect(supported.conditionDiscoveryModifier == -10)
        #expect(supported.annualHealthDrift == 0)
        #expect(supported.medicalDebtMultiplier == 0.80)
    }

    @Test func worldModifiersMatchTuningAndCaps() {
        var world = WorldSystem.initialize(runSeed: 1)
        world.profile = WorldProfile(costEnvironment: .expensive, laborStructure: .volatile, safetyNet: .strong)
        world.conditions = WorldConditionState(macro: .recession, macroYearsRemaining: 4, price: .inflationShock, priceYearsRemaining: 3)
        let recession = WorldSystem.modifiers(for: world)
        #expect(recession.incomeMultiplier == 0.96)
        #expect(recession.livingCostMultiplier == 1.22)
        #expect(recession.layoffRiskMultiplier == 2.0)
        #expect(recession.hiringModifier == -15)
        #expect(recession.securityDrift == -4)
        #expect(recession.unemploymentSupport == 7_000)

        world.profile = WorldProfile(costEnvironment: .affordable, laborStructure: .resilient, safetyNet: .thin)
        world.conditions = WorldConditionState(macro: .expansion, macroYearsRemaining: 6, price: nil, priceYearsRemaining: 0)
        let expansion = WorldSystem.modifiers(for: world)
        #expect(expansion.incomeMultiplier == 1.06)
        #expect(expansion.livingCostMultiplier == 0.92)
        #expect(expansion.layoffRiskMultiplier >= 0.5)
        #expect(expansion.hiringModifier == 12)
        #expect(expansion.unemploymentSupport == 0)
    }

    @Test func worldPolicyChangesCareerAndFinanceWithoutCrossDomainMutation() {
        var recessionState = LifeState(name: "Pressure", seed: 8_800)
        recessionState.character.age = 25
        recessionState.lifeStage = .build
        recessionState.career.level = .entry
        recessionState.career.security = 60
        var neutralState = recessionState

        var recession = WorldModifierSnapshot()
        recession.securityDrift = -4
        recession.unemploymentSupport = 70
        _ = CareerSystem.resolveYear(state: &recessionState, world: recession)
        _ = CareerSystem.resolveYear(state: &neutralState, world: WorldModifierSnapshot())
        #expect(recessionState.career.security == neutralState.career.security - 4)

        recessionState.career.level = .unemployed
        neutralState.career.level = .unemployed
        let pressuredCash = recessionState.cash
        let neutralCash = neutralState.cash
        _ = FinanceSystem.yearlySettlement(state: &recessionState, world: recession)
        var thinSupport = WorldModifierSnapshot()
        thinSupport.unemploymentSupport = 0
        _ = FinanceSystem.yearlySettlement(state: &neutralState, world: thinSupport)
        #expect(neutralState.finance.consumerDebt - recessionState.finance.consumerDebt == 70)
        #expect(recessionState.cash == pressuredCash - min(pressuredCash, 25_200))
        #expect(neutralState.cash == neutralCash - min(neutralCash, 25_200))
    }

    @Test func professionalCareUsesPersonalAndWorldAccessWhileSelfCareDoesNot() throws {
        var pressured = LifeState(name: "Care pressure", seed: 70_001)
        pressured.cash = 50000
        pressured.health.careAccess = .limited
        pressured.world.publicHealth.healthcareCapacity = .constrained
        pressured.world.publicHealth.condition = .outbreak
        var supported = pressured
        supported.health.careAccess = .reliable
        supported.world.publicHealth.healthcareCapacity = .resourced
        supported.world.publicHealth.condition = .stable

        let pressuredPreview = ConditionHealthSystem.professionalCarePreview(
            effect: .seekCare, state: pressured, world: WorldSystem.modifiers(for: pressured.world)
        )
        let supportedPreview = ConditionHealthSystem.professionalCarePreview(
            effect: .seekCare, state: supported, world: WorldSystem.modifiers(for: supported.world)
        )
        #expect(pressuredPreview.first == "Projected care cost $5400–8100")
        #expect(supportedPreview.first == "Projected care cost $3400–5100")

        let pressuredSimulator = isolatedSimulator(state: pressured)
        let supportedSimulator = isolatedSimulator(state: supported)
        _ = try #require(pressuredSimulator.execute(.seekCare))
        _ = try #require(supportedSimulator.execute(.seekCare))
        #expect(50_000 - pressuredSimulator.state.cash > 50_000 - supportedSimulator.state.cash)

        let outbreakRest = isolatedSimulator(state: pressured)
        let normalRest = isolatedSimulator(state: supported)
        _ = try #require(outbreakRest.execute(.rest))
        _ = try #require(normalRest.execute(.rest))
        #expect(outbreakRest.lastOutcome?.deltas == normalRest.lastOutcome?.deltas)
    }

    @Test func outbreakDriftAndMedicalDebtStayDomainOwned() {
        var outbreak = LifeState(name: "Outbreak", seed: 70_002)
        var stable = outbreak
        var outbreakPolicy = WorldModifierSnapshot()
        outbreakPolicy.annualHealthDrift = -2
        let outbreakYear = HealthSystem.yearlyDrift(state: &outbreak, world: outbreakPolicy)
        let stableYear = HealthSystem.yearlyDrift(state: &stable, world: WorldModifierSnapshot())
        #expect(outbreakYear.deltas.health == stableYear.deltas.health - 2)

        outbreak.health.addictionPressure = 70
        let debtBefore = outbreak.finance.medicalDebt
        let healthOutcome = ConditionHealthSystem.resolveYear(state: &outbreak, world: outbreakPolicy)
        #expect(outbreak.finance.medicalDebt == debtBefore)
        let impact = healthOutcome.medicalImpact
        #expect(impact?.requestedDebtCharge == 1_500)
        var debtPolicy = WorldModifierSnapshot()
        debtPolicy.medicalDebtMultiplier = 1.5
        if let impact {
            #expect(FinanceSystem.applyMedicalImpact(impact, state: &outbreak, world: debtPolicy) == 2_250)
        }
        #expect(outbreak.finance.medicalDebt == debtBefore + 2_250)
    }

    @Test func publicHealthProfileAndSimultaneousNewsStayCompressed() {
        var world = WorldSystem.initialize(runSeed: 70_003)
        world.conditions.macroYearsRemaining = 5
        world.publicHealth.yearsRemaining = 5
        let disclosure = WorldSystem.resolveYear(world: &world, age: 19).news
        #expect(disclosure?.headline == "The World You Entered")
        #expect(disclosure?.impactLines.count == 5)
        #expect(world.profileDisclosed)
        #expect(world.publicHealth.profileDisclosed)

        world.conditions.price = .inflationShock
        world.conditions.priceYearsRemaining = 1
        world.publicHealth.condition = .outbreak
        world.publicHealth.yearsRemaining = 1
        let simultaneous = WorldSystem.resolveYear(world: &world, age: 20).news
        #expect(simultaneous?.id.contains("world-prices-easing") == true)
        #expect(simultaneous?.id.contains("world-health-") == true)
        #expect((simultaneous?.impactLines.count ?? 0) <= 5)
    }

    @Test func worldHeadlineCoexistsWithPlayerEventWithoutCreatingAnotherChoice() {
        var state = LifeState(name: "News", seed: 81_313)
        state.world.profileDisclosed = true
        state.world.publicHealth.profileDisclosed = true
        state.world.conditions.price = .inflationShock
        state.world.conditions.priceYearsRemaining = 1
        let simulator = isolatedSimulator(state: state)

        simulator.ageUp()

        #expect(simulator.state.lastYearSummary?.worldNews?.id == "world-prices-easing")
        #expect((simulator.state.pendingEvent?.choices.count ?? 0) <= 3)
        #expect(simulator.state.history.first?.yearSummary?.worldNews != nil || simulator.state.pendingEvent != nil)
    }

    @Test func worldStateRoundTripsMidCycle() throws {
        var source = LifeState(name: "Mid-cycle", seed: 45_678)
        source.world.profileDisclosed = true
        source.world.conditions = WorldConditionState(
            macro: .recession,
            macroYearsRemaining: 3,
            price: .housingCrunch,
            priceYearsRemaining: 2
        )
        _ = source.world.worldRandom.next(in: 1...100)
        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(LifeState.self, from: data)
        #expect(decoded == source)
    }

    @Test func seededLifeGenerationIsStableAndCreatesInitialPeople() {
        let first = LifeGenerationSystem.randomPreview(seed: 42_424)
        let second = LifeGenerationSystem.randomPreview(seed: 42_424)
        #expect(first == second)
        #expect(first.state.character.age == 14)
        #expect(first.state.npcs[.friend] != nil)
        #expect(first.state.npcs[.teacher] != nil)
        #expect(first.state.runSeed == first.seed)
    }

    @Test func randomGenerationUsesWeightedRealisticDistribution() {
        var ordinary = 0
        var balanced = 0
        var talents = 0
        for seed in 1...1_000 {
            let preview = LifeGenerationSystem.randomPreview(seed: UInt64(seed))
            if preview.context == .ordinary { ordinary += 1 }
            if preview.origin == .balanced { balanced += 1 }
            if preview.state.personality.talent != nil { talents += 1 }
        }
        #expect(ordinary > 550)
        #expect(balanced > 400)
        #expect((200...300).contains(talents))
    }

    @Test func customTraitIsStrongWhileSeedStillDifferentiatesTheLife() {
        let first = LifeGenerationSystem.customPreview(
            name: "A", seed: 91, origin: .academic, context: .precarious,
            definingTrait: .reserved, talent: .publicLeadership
        )
        let second = LifeGenerationSystem.customPreview(
            name: "A", seed: 92, origin: .academic, context: .precarious,
            definingTrait: .reserved, talent: .publicLeadership
        )
        #expect(first.state.personality.current.sociability <= 28)
        #expect(first.state.personality.talent == .publicLeadership)
        #expect(first.state.personality.current != second.state.personality.current)
        #expect(first.state.world != second.state.world)
    }

    @Test func personalityDevelopmentIsGradualBoundedAndPersisted() throws {
        var profile = PersonalityProfile.neutral
        for age in 15...18 {
            PersonalitySystem.record(PersonalityImpulse(drive: 20), profile: &profile)
            _ = PersonalitySystem.resolveYear(profile: &profile, age: age)
        }
        #expect(profile.current.drive == 66)
        #expect(profile.has(.driven))
        let data = try JSONEncoder().encode(profile)
        #expect(try JSONDecoder().decode(PersonalityProfile.self, from: data) == profile)
    }

    @Test func personalityFlagsUseNeutralBandAndStableHysteresis() {
        var profile = PersonalityProfile.neutral
        #expect(profile.salientFlags.isEmpty)
        #expect(!profile.has(.driven))
        #expect(!profile.has(.content))

        profile.current.drive = 62
        profile.refreshEstablishedFlags()
        #expect(profile.has(.driven))
        profile.current.drive = 58
        profile.refreshEstablishedFlags()
        #expect(profile.has(.driven))
        profile.current.drive = 46
        profile.refreshEstablishedFlags()
        #expect(!profile.has(.driven))
        #expect(!profile.has(.content))
        profile.current.drive = 38
        profile.refreshEstablishedFlags()
        #expect(profile.has(.content))
    }

    @Test func compoundIdentityChangesTheSameActionExplanationAndEffect() {
        var methodical = LifeGenerationSystem.customPreview(
            name: "Methodical", seed: 991, origin: .balanced, context: .ordinary,
            definingTrait: .driven, talent: nil
        ).state
        methodical.personality.current.riskTolerance = 25
        methodical.personality.refreshEstablishedFlags()
        #expect(methodical.personality.identitySignature.id == .methodicalBuilder)

        var independent = LifeGenerationSystem.customPreview(
            name: "Independent", seed: 992, origin: .balanced, context: .ordinary,
            definingTrait: .selfReliant, talent: nil
        ).state
        independent.personality.current.drive = 50
        independent.personality.refreshEstablishedFlags()
        let action = DomainActionRegistry.action(for: .budget)
        let first = SocialReactivitySystem().preview(action: action, state: methodical)
        let second = SocialReactivitySystem().preview(action: action, state: independent)
        #expect(first.personalityContext?.contains("Methodical builder") == true)
        #expect(second.personalityContext?.contains("Self-reliant tendency") == true)
        #expect(first.npcEffect != second.npcEffect)
        methodical.character.age = 30; methodical.lifeStage = .build; methodical.flags.attendsSchool = false
        let simulator = isolatedSimulator(state: methodical)
        simulator.execute(.budget)
        #expect(simulator.lastOutcome?.personalityContext?.contains("Methodical builder") == true)
        #expect(SystemRegistry.activeInstantSystems(for: action, in: methodical).contains(.personality))
    }

    @Test func everyPairedFlagHasAPlayableReactionRule() {
        for flag in PersonalityFlag.allCases {
            #expect(UnifiedReactionRegistry.rules.contains { $0.predicate.playerFlags.contains(flag) }, "Missing playable rule for \(flag)")
        }
    }

    @Test func everyFlagHasStrategicActionRelationshipWorldAndEventDepth() {
        for flag in PersonalityFlag.allCases {
            let actionIDs = Set(UnifiedReactionRegistry.rules.filter {
                $0.channel == .playerPersonality && $0.predicate.playerFlags.contains(flag)
            }.flatMap(\.actionIDs))
            #expect(actionIDs.count >= 6, "\(flag) needs at least six strategic actions")
            #expect(UnifiedReactionRegistry.rules.filter {
                $0.channel == .npcOrPartner && $0.predicate.role == .partner && $0.predicate.npcFlags.contains(flag)
            }.count >= 2, "\(flag) needs aligned and conflicting partner reactions")
            #expect(UnifiedReactionRegistry.rules.filter {
                $0.channel == .world && $0.predicate.playerFlags.contains(flag)
            }.count >= 2, "\(flag) needs favorable and adverse world reactions")
            #expect(BundledLifeContentRegistry.pack.events.filter {
                $0.predicate.playerFlags.contains(flag)
            }.count >= 2, "\(flag) needs opportunity and cost events")
        }
        for signature in IdentitySignatureID.allCases.prefix(10) {
            #expect(BundledLifeContentRegistry.pack.events.contains {
                $0.predicate.identitySignatures.contains(signature)
            }, "Missing pivotal compound event for \(signature)")
        }
    }

    @Test func reactionRulesStayInsideNormalizedBudgets() {
        for rule in UnifiedReactionRegistry.rules {
            #expect(ReactionBalancePolicy.isWithinChannelBudget(rule), "Over-budget reaction: \(rule.id)")
        }
    }

    @Test func compoundIdentityReplacesBaseRuleAndChannelsCoexist() throws {
        var state = LifeGenerationSystem.customPreview(
            name: "Channels", seed: 771, origin: .balanced, context: .ordinary,
            definingTrait: .adventurous, talent: nil
        ).state
        state.character.age = 30; state.lifeStage = .build
        state.world.conditions.macro = .expansion
        state.partner = PartnerState(name: "Morgan", startedAge: 20, compatibility: 60)
        state.partner?.personality.current.riskTolerance = 20
        state.partner?.personality.refreshEstablishedFlags()
        let party = SocialReactivitySystem().preview(action: DomainActionRegistry.action(for: .party), state: state)
        #expect(Set(party.reactionRules.map(\.channel)).isSuperset(of: [.playerPersonality, .npcOrPartner, .world]))

        state.personality.current.drive = 80
        state.personality.current.riskTolerance = 20
        state.personality.refreshEstablishedFlags()
        let budgetSignals = SimulationSignalSnapshot(state: state)
        let match = try #require(UnifiedReactionRegistry.bestMatch(channel: .playerPersonality, action: .budget, signals: budgetSignals))
        #expect(match.id == "methodical-builder-compounds")
        #expect(match.isCompoundIdentity)
    }

    @Test func normalizedCashTracksLivingCosts() throws {
        let rule = try #require(UnifiedReactionRegistry.rules.first { $0.id == "self-reliant-carries-load" })
        var lowCost = LifeState(name: "Low", seed: 1)
        lowCost.finance.annualLedger.livingCosts = 20_000
        var highCost = lowCost
        highCost.finance.annualLedger.livingCosts = 100_000
        let low = ReactionBalancePolicy.resolvedEffects(for: rule.impact, state: lowCost).cash.lowerBound
        let high = ReactionBalancePolicy.resolvedEffects(for: rule.impact, state: highCost).cash.lowerBound
        #expect(low == 1_000)
        #expect(high == 5_000)
        #expect(high > low)
    }

    @Test func contraryBehaviorLeavesAStrongerDevelopmentTrace() {
        var profile = PersonalityProfile(
            baseline: PersonalityVector(adaptability: 20),
            current: PersonalityVector(adaptability: 20),
            definingTrait: .steadfast,
            talent: nil
        )
        profile.refreshEstablishedFlags()
        let contrary = PersonalitySystem.developmentImpulse(PersonalityImpulse(adaptability: 2), for: profile)
        let repeated = PersonalitySystem.developmentImpulse(PersonalityImpulse(adaptability: -2), for: profile)
        #expect(contrary.adaptability == 3)
        #expect(repeated.adaptability == -2)
        #expect(DomainActionRegistry.action(for: .preventiveCare).resolvedPersonalityImpulse.adaptability < 0)
        #expect(DomainActionRegistry.action(for: .changeCareer).resolvedPersonalityImpulse.adaptability > 0)
    }

    @Test func randomLanesAreIndependentAcrossSocialAndEvents() {
        var state = LifeGenerationSystem.customPreview(
            name: "Lanes", seed: 808, origin: .balanced, context: .ordinary,
            definingTrait: .adaptable, talent: nil
        ).state
        state.npcs[.boss] = nil
        let eventBefore = state.randomStreams.event
        let actionBefore = state.randomStreams.action
        var social = SocialReactivitySystem()
        _ = social.resolve(action: DomainActionRegistry.action(for: .workShift), state: &state)
        #expect(state.randomStreams.event == eventBefore)
        #expect(state.randomStreams.action == actionBefore)
    }

    @Test func talentsCreateCappedAdvantagesWithoutChangingRequirements() {
        let action = DomainActionRegistry.action(for: .exercise)
        var talented = LifeState(name: "Talent", seed: 1)
        talented.personality.talent = .athletic
        let modified = TalentSystem.modifiedEffects(for: action, state: talented)
        #expect(modified.health.lowerBound == action.effects.health.lowerBound + 2)
        #expect(TalentSystem.context(for: action, state: talented) == "Athletic talent")
        let locked = DomainActionRegistry.action(for: .buyHome)
        let before = locked.requirements.unmetReason(in: talented)
        talented.personality.talent = .entrepreneurial
        #expect(locked.requirements.unmetReason(in: talented) == before)
    }

    @Test func unifiedReactionUsesPersonalityAndWorldSignals() {
        var state = LifeState(name: "Signals", seed: 12)
        state.npcs[.friend] = NPCState(
            name: "Jamie", role: .friend, importance: .recurring, coreFlags: [],
            personality: PersonalityProfile(
                baseline: PersonalityVector(sociability: 80),
                current: PersonalityVector(sociability: 80),
                definingTrait: .outgoing,
                talent: nil
            ),
            lastInteractionAge: state.character.age
        )
        let outgoing = SocialReactivitySystem().preview(action: DomainActionRegistry.action(for: .seeFriends), state: state)
        state.npcs[.friend]?.personality.current.sociability = 20
        let reserved = SocialReactivitySystem().preview(action: DomainActionRegistry.action(for: .seeFriends), state: state)
        #expect(outgoing.npcEffect.love.lowerBound > reserved.npcEffect.love.lowerBound)
        #expect(outgoing.reactionRules.contains { $0.id == "friend-outgoing-social" })
    }

    @Test func bundledPersonalityContentDecodesAndValidates() throws {
        let url = try #require(Bundle.main.url(forResource: "PersonalityEvents", withExtension: "json"))
        let pack = try JSONDecoder().decode(LifeContentPack.self, from: Data(contentsOf: url))
        try LifeContentValidator.validate(pack)
        #expect(pack.events.count == 34)
        #expect(Set(pack.events.map(\.id)).count == pack.events.count)
        let teacher = try #require(pack.events.first { $0.id == "driven-teacher-raises-bar" })
        #expect(teacher.predicate.minimumPlayerAxes[.drive] == 60)
        #expect(teacher.predicate.requiredDomainStates == [.attendsSchool])
        #expect(teacher.choices.first?.npcRapportDelta == 2)
    }

    @Test func bundledRelationshipEffectsUseTheDeclaredTargetRole() throws {
        let event = try #require(BundledLifeContentRegistry.pack.events.first { $0.id == "driven-teacher-raises-bar" })
        var state = LifeGenerationSystem.customPreview(
            name: "Driven", seed: 700_001, origin: .academic, context: .ordinary,
            definingTrait: .driven, talent: nil
        ).state
        state.stats.school = 70
        state.npcs[.teacher]?.personality.current.drive = 80
        let before = try #require(state.npcs[.teacher]?.rapport)
        state.pendingEvent = PresentedEvent(event.lifeEvent(for: state))
        let simulator = isolatedSimulator(state: state)
        simulator.execute(.focus)
        #expect(simulator.state.npcs[.teacher]?.rapport == before + 2)
        #expect(simulator.state.personality.pendingImpulse.drive == 3)
    }

    @Test func everyBundledPredicateHasAReachableFixture() {
        for (index, event) in BundledLifeContentRegistry.pack.events.enumerated() {
            var state = LifeState(name: "Fixture", seed: UInt64(710_000 + index))
            if let stage = event.stages.first {
                state.lifeStage = stage
                state.character.age = switch stage { case .adolescence: 16; case .launch: 22; case .build: 35; case .pressure: 52; case .legacy: 70 }
            }
            let requiredFlags = event.predicate.playerFlags
                + event.predicate.identitySignatures.flatMap(PersonalitySystem.requiredFlags)
            state.personality.current = PersonalityVector()
            for flag in requiredFlags {
                state.personality.current[flag.axis] = flag.favorsHighValue ? 80 : 20
            }
            state.personality.baseline = state.personality.current
            state.personality.definingTrait = requiredFlags.first ?? .adaptable
            state.personality.talent = event.predicate.talent
            for (axis, value) in event.predicate.minimumPlayerAxes { state.personality.current[axis] = max(value, state.personality.current[axis]) }
            for (axis, value) in event.predicate.maximumPlayerAxes { state.personality.current[axis] = min(value, state.personality.current[axis]) }
            state.personality.refreshEstablishedFlags()
            for (domain, value) in event.predicate.minimumStats { state.stats[domain] = max(value, state.stats[domain]) }
            for (domain, value) in event.predicate.maximumStats { state.stats[domain] = min(value, state.stats[domain]) }

            for flag in event.predicate.worldFlags {
                switch flag {
                case .expansion: state.world.conditions.macro = .expansion
                case .recession: state.world.conditions.macro = .recession
                case .recovery: state.world.conditions.macro = .recovery
                case .steadyEconomy: state.world.conditions.macro = .steady
                case .inflationShock: state.world.conditions.price = .inflationShock
                case .housingCrunch: state.world.conditions.price = .housingCrunch
                case .thinSafetyNet: state.world.profile.safetyNet = .thin
                case .strongSafetyNet: state.world.profile.safetyNet = .strong
                case .volatileLabor: state.world.profile.laborStructure = .volatile
                case .resilientLabor: state.world.profile.laborStructure = .resilient
                case .affordableCosts: state.world.profile.costEnvironment = .affordable
                case .expensiveCosts: state.world.profile.costEnvironment = .expensive
                case .constrainedHealthcare: state.world.publicHealth.healthcareCapacity = .constrained
                case .resourcedHealthcare: state.world.publicHealth.healthcareCapacity = .resourced
                case .stablePublicHealth: state.world.publicHealth.condition = .stable
                case .publicHealthOutbreak: state.world.publicHealth.condition = .outbreak
                default: break
                }
            }
            for requirement in event.predicate.requiredDomainStates {
                switch requirement {
                case .attendsSchool: state.flags.attendsSchool = true
                case .employed: state.flags.hasJob = true; state.career.level = .entry
                case .partnered:
                    state.flags.hasPartner = true
                    state.partner = PartnerState(name: "Morgan", startedAge: state.character.age - 2, compatibility: 60)
                case .inRecovery: state.recovery = RecoveryWindow(kind: .health, openedAge: state.character.age)
                case .hasDebt: state.finance.consumerDebt = 10_000
                case .hasDependents: state.family.children = [ChildState(name: "Avery", age: 4, temperament: .curious)]
                case .hasCondition: state.health.conditions = [ChronicCondition(kind: .chronicPain, severity: 30, management: 30)]
                default: break
                }
            }
            if let role = event.predicate.npcRole {
                var npcProfile = PersonalityProfile.neutral
                for flag in event.predicate.npcFlags {
                    npcProfile.current[flag.axis] = flag.favorsHighValue ? 80 : 20
                }
                npcProfile.baseline = npcProfile.current
                npcProfile.definingTrait = event.predicate.npcFlags.first ?? .adaptable
                npcProfile.refreshEstablishedFlags()
                if role == .partner {
                    if state.partner == nil { state.partner = PartnerState(name: "Morgan", startedAge: state.character.age - 2, compatibility: 60) }
                    state.partner?.personality = npcProfile
                } else if let npcRole = role.npcRole {
                    state.npcs[npcRole] = NPCState(name: "Fixture NPC", role: npcRole, importance: .recurring, coreFlags: [], personality: npcProfile, lastInteractionAge: state.character.age)
                }
            }
            #expect(event.weight(in: state) > 0, "No reachable fixture for \(event.id)")
        }
    }

    @Test func versionTwentyOneAddsStableProfilesWithoutChangingCanonicalLife() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v21-personality-\(UUID().uuidString).json")
        var source = LifeState(name: "Legacy", seed: 700_002, context: .precarious, trait: .driven)
        source.saveVersion = 21
        source.cash = 317
        source.stats.love = 63
        source.partner = PartnerState(
            name: "Morgan", startedAge: 18, compatibility: 61, bond: 73, resentment: 12,
            flags: [.supportive, .secure]
        )
        source.npcs[.friend] = NPCState(
            name: "Jamie", role: .friend, importance: .recurring,
            coreFlags: [.sociable, .dependable], rapport: 8,
            lastInteractionAge: source.character.age, learnedStance: .warm
        )
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        json.removeValue(forKey: "personality")
        json.removeValue(forKey: "randomStreams")
        var partner = try #require(json["partner"] as? [String: Any])
        partner.removeValue(forKey: "personality")
        json["partner"] = partner
        var directory = try #require(json["npcs"] as? [String: Any])
        var people = try #require(directory["entries"] as? [String: Any])
        var friend = try #require(people["friend"] as? [String: Any])
        friend.removeValue(forKey: "personality")
        people["friend"] = friend
        directory["entries"] = people
        json["npcs"] = directory
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        guard case .loaded(let migrated) = LifePersistence(saveURL: url).load() else {
            Issue.record("v21 personality save should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.cash == 31_700)
        #expect(migrated.stats.love == 63)
        #expect(migrated.personality.has(.driven))
        #expect(migrated.personality.talent == nil)
        #expect(migrated.partner?.bond == 73)
        #expect(migrated.partner?.resentment == 12)
        #expect(migrated.npcs[.friend]?.rapport == 8)
        #expect(migrated.npcs[.friend]?.learnedStance == .warm)
        #expect(migrated.randomStreams == SimulationRandomStreams(runSeed: migrated.runSeed))
        try? FileManager.default.removeItem(at: url)
    }

    @Test func versionTwentyThreeAddsNeutralSchoolIdentityWithoutChangingCanonicalLife() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v23-school-identity-\(UUID().uuidString).json")
        var source = LifeState(name: "Legacy student", seed: 700_023, startingAge: 14)
        source.saveVersion = 23
        source.education.activity = .club
        source.finance.studentDebt = 42
        source.education.college.credits = 3
        let random = source.random
        let streams = source.randomStreams
        let career = source.career
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        var education = try #require(json["education"] as? [String: Any])
        for key in ["schoolEnvironment", "schoolReputation", "activityStage", "schoolMemories", "frozenDefiningMemory"] {
            education.removeValue(forKey: key)
        }
        json["education"] = education
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        guard case .loaded(let migrated) = LifePersistence(saveURL: url).load() else {
            Issue.record("v23 school identity save should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.education.schoolEnvironment == EducationSystem.schoolEnvironment(for: source.runSeed))
        #expect(migrated.education.schoolReputation == 50)
        #expect(migrated.education.activityStage == .committed)
        #expect(migrated.education.schoolMemories.isEmpty)
        #expect(migrated.education.frozenDefiningMemory == nil)
        #expect(migrated.finance.studentDebt == 4_200)
        #expect(migrated.education.college.credits == 3)
        #expect(migrated.career == career)
        #expect(migrated.random == random)
        #expect(migrated.randomStreams == streams)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func versionTwentyFourEstablishesFlagsWithoutChangingLifeOrRNG() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v24-stable-flags-\(UUID().uuidString).json")
        var source = LifeState(name: "Threshold", seed: 700_024)
        source.saveVersion = 24
        source.cash = 413
        source.personality.current.drive = 66
        source.personality.establishedFlags = []
        let current = source.personality.current
        let streams = source.randomStreams
        try JSONEncoder().encode(source).write(to: url)

        guard case .loaded(let migrated) = LifePersistence(saveURL: url).load() else {
            Issue.record("v24 stable flag save should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.cash == 41_300)
        #expect(migrated.personality.current == current)
        #expect(migrated.personality.has(.driven))
        #expect(migrated.randomStreams == streams)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func contentValidatorRejectsContradictoryFlags() throws {
        let json = """
        {"schemaVersion":1,"events":[{"id":"bad","headline":"This Headline Has Exactly Five Words","detail":"Bad.","baseWeight":5,"predicate":{"playerFlags":["driven","content"]},"choices":[{"id":"accept","title":"Accept","detail":"Do it.","narrative":"Done.","effects":{}}]}]}
        """
        let pack = try JSONDecoder().decode(LifeContentPack.self, from: Data(json.utf8))
        #expect(throws: LifeContentValidationError.incompatibleFlags("bad")) {
            try LifeContentValidator.validate(pack)
        }
    }

    private func runScenario(seed: UInt64, policy: String, years: Int, origin: OriginPreset = .balanced) -> LifeState {
        let simulator = isolatedSimulator(state: LifeState(name: "Release Gate", seed: seed, origin: origin))
        let domains: [Domain] = [.school, .cash, .love, .play, .health]

        for year in 0..<years where !simulator.state.isGameOver {
            if let recovery = simulator.state.recovery {
                simulator.execute(recovery.kind == .financial ? .workShift : .rest)
                if simulator.state.recovery != nil {
                    // Cannot stabilize — next ageUp ends life
                }
            } else {
                let domain: Domain
                switch policy {
                case "grind": domain = simulator.state.flags.attendsSchool ? .school : .cash
                case "social": domain = .love
                case "survival": domain = .health
                default: domain = domains[year % domains.count]
                }
                if let action = simulator.availableActions(in: domain).first {
                    simulator.execute(action.id)
                } else if let any = Domain.allCases.compactMap({ simulator.availableActions(in: $0).first }).first {
                    simulator.execute(any.id)
                }
            }
            simulator.ageUp()
            if let event = simulator.state.pendingEvent, let choice = event.choices.first { simulator.execute(choice.id) }
        }
        return simulator.state
    }

    private func executableState(for action: DomainAction, seed: UInt64) -> LifeState {
        var state = LifeState(name: "Registry", seed: seed)
        state.character.age = action.requirements.minimumAge ?? 30
        if let stage = action.requirements.allowedStages?.first {
            state.character.age = switch stage {
            case .adolescence: 14
            case .launch: max(18, action.requirements.minimumAge ?? 18)
            case .build: 30
            case .pressure: 50
            case .legacy: 70
            }
        }
        state.lifeStage = LifeStage.stage(for: state.character.age)
        state.cash = max(100_000, action.requirements.minimumCash ?? 0)
        if let minimumStat = action.requirements.minimumStat, let domain = action.requirements.statDomain {
            state.stats[domain] = minimumStat
        }
        state.flags.attendsSchool = action.requirements.requiresSchool
        if action.requirements.requiresLeftSchool { state.flags.attendsSchool = false }
        if action.requirements.requiresCredential { state.education.credential = true }
        if action.requirements.requiresJob {
            state.flags.hasJob = true
            state.job.tier = .entry
        }
        if action.requirements.requiresPartner {
            state.flags.hasPartner = true
            state.partner = PartnerState(
                name: "Morgan",
                startedAge: state.character.age,
                compatibility: 60,
                bond: 50,
                resentment: 35,
                flags: [.supportive, .loyal]
            )
        }
        for requirement in action.requirements.values {
            satisfy(requirement, state: &state)
        }
        state.clamp()
        return state
    }

    private func propertyReceiptYear(assets: inout AssetState, missed: Bool, principal: Int = 0, age: Int = 35) -> AssetYearOutcome {
        let receipts = assets.properties.enumerated().map { index, p in
            MortgageReceipt(propertyID: p.id, principal: index == 0 ? principal : 0, missedPayment: missed)
        }
        return AssetSystem.finalizeYear(assets: &assets, receipts: receipts, age: age)
    }

    private func satisfy(_ requirement: ActionRequirement, state: inout LifeState) {
        switch requirement {
        case .minimumAge(let age): state.character.age = max(state.character.age, age)
        case .minimumCash(let cash): state.cash = max(state.cash, cash)
        case .minimumStat(let domain, let value): state.stats[domain] = max(state.stats[domain], value)
        case .schoolEnrollment(let enrolled): state.flags.attendsSchool = enrolled
        case .credential: state.education.credential = true
        case .partner:
            if state.partner == nil { state.partner = PartnerState(startedAge: state.character.age, compatibility: 60) }
        case .employed: state.career.level = .entry
        case .careerTrack(let track): state.career.track = track
        case .careerClass(let careerClass): state.career.careerClass = careerClass
        case .careerDirectionChosen: state.career.track = .office
        case .careerOccupationNotChosen: state.career.occupation = nil
        case .careerOccupation(let occupation): state.career.track = occupation.track; state.career.occupation = occupation
        case .careerLevels(let levels): state.career.level = levels.first ?? .entry
        case .careerPaidLeave(let days): state.career.paidLeaveDays = max(state.career.paidLeaveDays, days)
        case .specialCareerEligible:
            state.career.careerClass = .normal
            state.career.level = .established
            state.career.performance = 82
            state.stats.rep = 70
        case .diamondCareerEligible:
            state.career.careerClass = .special
            state.career.level = .senior
            state.career.specialMomentum = 60
            state.stats.rep = 80
            state.cash = max(state.cash, 250_000)
        case .relationshipStages(let stages):
            if state.partner == nil { state.partner = PartnerState(startedAge: state.character.age, compatibility: 60) }
            let stage = stages.first ?? .dating
            state.partner?.stage = stage
            state.partner?.committed = stage != .dating
        case .familyIntention(let intentions): state.family.intention = intentions.first ?? .openToChildren
        case .noChildren: state.family.children = []
        case .hasDependents: state.family.children = [ChildState(name: "Alex", age: 8, temperament: .curious)]
        case .housing(let kinds):
            let kind = kinds.first ?? .renting
            state.assets = kind == .renting
                ? AssetState()
                : AssetSystem.migrateLegacyHousing(
                    HousingState(kind: kind, homeValue: 1_500, mortgageBalance: 900, annualCost: 220),
                    age: state.character.age
                )
        case .debtWorkoutEligible: state.finance.consumerDebt = 100_000; state.finance.economy.shortfallYears = 2
        case .hasDebt: state.finance.consumerDebt = 10_000
        case .hasCondition: state.health.conditions = [ChronicCondition(kind: .chronicPain, severity: 35, management: 5)]
        case .schoolCommitmentOpen: state.education.commitment = nil
        case .schoolActivityOpen:
            if state.education.activityStage == .ended { state.education.activityStage = .none }
        case .collegeApplicationEligible:
            state.character.age = min(24, max(18, state.character.age))
            state.lifeStage = .launch
            state.flags.attendsSchool = false
            state.education.highSchoolDiploma = true
            state.education.phase = .leftSchool
            state.education.college = CollegeState()
            state.education.credentialKind = .none
        case .educationRecoveryEligible:
            state.character.age = min(64, max(18, state.character.age))
            state.flags.attendsSchool = false
            state.education.phase = .leftSchool
            state.education.college = CollegeState()
            state.education.recovery = EducationRecoveryState()
            state.education.credentialKind = .none
        case .stages(let stages):
            if let stage = stages.first {
                state.character.age = switch stage { case .adolescence: 14; case .launch: 20; case .build: 30; case .pressure: 50; case .legacy: 70 }
                state.lifeStage = stage
            }
        case .all(let values): for value in values { satisfy(value, state: &state) }
        case .any(let values): if let first = values.first { satisfy(first, state: &state) }
        }
    }

    @Test func rentalPortfolioUsesDedicatedRandomAndWorldBoundedValues() throws {
        var state = LifeState(name: "Landlord", seed: 81_001)
        state.character.age = 35
        state.career.level = .senior
        state.cash = 1000000
        _ = try #require(AssetSystem.purchase(listingID: "house-starter-condo", state: &state))
        _ = try #require(AssetSystem.purchase(listingID: "house-townhouse", state: &state))
        _ = try #require(AssetSystem.listPropertyForRent(propertyID: 2, strategy: .stable, state: &state))
        let gameplay = state.random
        let streams = state.randomStreams
        let economy = state.world.worldRandom
        let care = state.world.publicHealth.publicHealthRandom
        let legal = state.legal.legalRandom
        let beforeRealEstate = state.assets.realEstateRandom
        var world = WorldModifierSnapshot()
        world.propertyValueGrowthRate = 0.05

        let prepared = AssetSystem.prepareYear(assets: &state.assets, world: world, age: 36)
        #expect(state.assets.properties[0].marketAdjustment == 7_500)
        #expect(state.assets.properties[1].marketAdjustment == 11_250)
        #expect(state.assets.realEstateRandom != beforeRealEstate)
        #expect(prepared.financialSnapshot.occupiedRentals + prepared.financialSnapshot.vacantRentals == 1)
        #expect(state.random == gameplay)
        #expect(state.randomStreams == streams)
        #expect(state.world.worldRandom == economy)
        #expect(state.world.publicHealth.publicHealthRandom == care)
        #expect(state.legal.legalRandom == legal)

        var primaryOnly = LifeState(name: "Owner", seed: 81_002)
        primaryOnly.character.age = 35
        primaryOnly.career.level = .senior
        primaryOnly.cash = 200000
        _ = try #require(AssetSystem.purchase(listingID: "house-starter-condo", state: &primaryOnly))
        let sleepingRandom = primaryOnly.assets.realEstateRandom
        _ = AssetSystem.prepareYear(assets: &primaryOnly.assets, world: world, age: 36)
        #expect(primaryOnly.assets.realEstateRandom == sleepingRandom)
    }

    @Test func occupiedRentalFlowsThroughFinanceOnceAndKeepsTenantLocal() throws {
        var state = LifeState(name: "Portfolio", seed: 81_003)
        state.character.age = 40
        state.career.level = .senior
        state.cash = 1000000
        _ = try #require(AssetSystem.purchase(listingID: "house-starter-condo", state: &state))
        _ = try #require(AssetSystem.purchase(listingID: "house-townhouse", state: &state))
        _ = try #require(AssetSystem.listPropertyForRent(propertyID: 2, strategy: .market, state: &state))
        state.assets.properties[1].rental?.tenant = RentalTenantProfile(
            id: 1,
            name: "Taylor",
            householdType: .family,
            reliability: 100,
            care: 80,
            occupiedSinceAge: 40,
            leaseYearsRemaining: 3
        )
        let world = WorldModifierSnapshot()
        let prepared = AssetSystem.prepareYear(assets: &state.assets, world: world, age: 41)
        let rent = prepared.financialSnapshot.rentalIncome
        #expect(rent > 0)
        #expect(state.npcs[.friend] == nil)
        _ = FinanceSystem.yearlySettlement(state: &state, world: world, assets: prepared.financialSnapshot)
        #expect(state.finance.annualLedger.rentalIncome == rent)
        #expect(state.finance.annualLedger.rentalTaxes == 0)
        #expect(state.finance.annualLedger.income >= rent)
    }

    @Test func rentalOperationsRepairsAndPrimaryPromotionAreEndToEnd() throws {
        var state = LifeState(name: "Property manager", seed: 81_004)
        state.character.age = 40
        state.career.level = .senior
        state.cash = 1000000
        let simulator = isolatedSimulator(state: state)
        _ = try #require(simulator.purchaseAsset(listingID: "house-starter-condo"))
        _ = try #require(simulator.purchaseAsset(listingID: "house-townhouse"))
        #expect(simulator.rentalAvailability(propertyID: 1) == .locked("Primary residence cannot be rented"))
        _ = try #require(simulator.listPropertyForRent(propertyID: 2, strategy: .aggressive))
        #expect(simulator.state.assets.properties[1].use == .rental)
        #expect(simulator.changeRentalStrategy(propertyID: 2, strategy: .stable) == nil)
        _ = try #require(simulator.sellAsset(ownershipID: 1))
        #expect(simulator.state.assets.primaryProperty == nil)
        #expect(simulator.state.housingKind == .renting)
        #expect(simulator.state.assets.properties[0].use == .rental)

        _ = try #require(simulator.withdrawRentalListing(propertyID: 2))
        var repairState = simulator.state
        repairState.assets.properties[0].condition = 50
        let repairSimulator = isolatedSimulator(state: repairState)
        let cash = repairSimulator.state.cash
        _ = try #require(repairSimulator.performPropertyRepair(propertyID: 2, kind: .restoration))
        #expect(repairSimulator.state.assets.properties[0].condition == 85)
        #expect(repairSimulator.state.cash < cash)
        #expect(repairSimulator.propertyRepairAvailability(.routine, propertyID: 2) == .locked("Already repaired this year"))
    }

    @Test func versionThirtyMigrationAddsNeutralRealEstateWithoutTouchingOtherStreams() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v30-real-estate-\(UUID().uuidString).json")
        var source = LifeState(name: "Legacy owner", seed: 81_005)
        source.saveVersion = 30
        source.character.age = 40
        source.career.level = .senior
        source.cash = 500000
        _ = try #require(AssetSystem.purchase(listingID: "house-starter-condo", state: &source))
        let random = source.random
        let streams = source.randomStreams
        let world = source.world
        let legal = source.legal
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        var assets = try #require(json["assets"] as? [String: Any])
        for key in ["nextTenantSequence", "realEstateRandom", "recentPropertyEventIDs", "lastRentalIncome"] {
            assets.removeValue(forKey: key)
        }
        var properties = try #require(assets["properties"] as? [[String: Any]])
        for index in properties.indices {
            for key in ["use", "marketAdjustment", "condition", "lastRepairAge", "lastRentStrategyAge", "rental"] {
                properties[index].removeValue(forKey: key)
            }
            properties[index]["isPrimaryResidence"] = true
        }
        assets["properties"] = properties
        json["assets"] = assets
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)
        guard case .loaded(let migrated) = LifePersistence(saveURL: url).load() else {
            Issue.record("v30 property should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.assets.properties.first?.condition == 90)
        #expect(migrated.assets.properties.first?.use == .primaryResidence)
        #expect(migrated.assets.properties.first?.rental == nil)
        #expect(migrated.random == random)
        #expect(migrated.randomStreams == streams)
        #expect(migrated.world == world)
        #expect(migrated.legal == legal)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func versionThirtyOneMigrationBackfillsTypedYearSummariesWithoutChangingSimulation() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v31-year-summary-\(UUID().uuidString).json")
        var source = LifeState(name: "Legacy summary", seed: 81_006)
        source.character.age = 41
        let legacySummary = YearSummary(
            bullets: ["Promotion earned", "Health -4"],
            stanceTitle: "Push Career",
            shapeTitle: "Driven",
            focusNote: nil,
            silenceNote: nil,
            wasQuiet: false
        )
        source.lastYearSummary = legacySummary
        source.history = [
            HistoryEntry(
                id: 1,
                age: 41,
                headline: "Work Finally Recognized Your Name",
                detail: "The title changed; the pressure did not.",
                deltas: DeltaSummary(cash: 85, health: -4),
                yearSummary: legacySummary
            )
        ]
        let random = source.random
        let streams = source.randomStreams
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        json["saveVersion"] = 31

        func legacyJSON(_ value: Any?) -> [String: Any]? {
            guard var summary = value as? [String: Any] else { return nil }
            summary["bullets"] = ["Promotion earned", "Health -4"]
            for key in ["age", "headline", "deltas", "developments", "importance"] {
                summary.removeValue(forKey: key)
            }
            return summary
        }

        json["lastYearSummary"] = legacyJSON(json["lastYearSummary"])
        var history = try #require(json["history"] as? [[String: Any]])
        history[0]["yearSummary"] = legacyJSON(history[0]["yearSummary"])
        json["history"] = history
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        guard case .loaded(let migrated) = LifePersistence(saveURL: url).load() else {
            Issue.record("v31 summary should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.lastYearSummary?.age == 41)
        #expect(migrated.lastYearSummary?.headline == "Work Finally Recognized Your Name")
        #expect(migrated.lastYearSummary?.deltas == DeltaSummary(cash: 85, health: -4))
        #expect(migrated.lastYearSummary?.developments.map(\.text) == ["Promotion earned"])
        #expect(migrated.history.first?.yearSummary?.age == 41)
        #expect(migrated.random == random)
        #expect(migrated.randomStreams == streams)
        try? FileManager.default.removeItem(at: url)
    }

    private func partneredState(
        seed: UInt64,
        bond: Int = 55,
        resentment: Int = 0,
        flags: [PartnerFlag] = [.supportive, .loyal]
    ) -> LifeState {
        var state = LifeState(name: "Partnered", seed: seed)
        state.cash = 100_000
        state.flags.hasPartner = true
        state.partner = PartnerState(
            name: "Morgan",
            startedAge: state.character.age,
            compatibility: 60,
            bond: bond,
            resentment: resentment,
            flags: flags
        )
        return state
    }
}

@MainActor
struct PersistentSituationTests {
    @Test func promotionTrackRecordsActionsResolvesAndPersists() throws {
        var state = LifeState(name: "Arc", seed: 34_001)
        state.character.age = 34
        state.lifeStage = .build
        state.career.track = .office
        state.career.level = .established
        state.career.performance = 76
        state.career.activeSituation = CareerSituation(kind: .promotionTrack, startedAge: 32, remainingYears: 1, commitment: 4, pressure: 2)

        CareerSituationSystem.record(.pursuedWork, state: &state)
        let result = CareerSituationSystem.resolveYear(state: &state)

        #expect(result.milestoneHeadline == "The Promotion Became Yours")
        #expect(state.career.level == .senior)
        #expect(state.career.activeSituation == nil)
        #expect(state.career.resolvedSituations.first?.kind == CareerSituationKind.promotionTrack.rawValue)

        let decoded = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(decoded.career.resolvedSituations == state.career.resolvedSituations)
    }

    @Test func workHomeCollisionEmitsRelationshipConsequenceWithoutMutatingPartner() {
        var state = LifeState(name: "Boundary", seed: 34_002)
        state.character.age = 42
        state.lifeStage = .build
        state.career.track = .office
        state.career.level = .established
        state.partner = PartnerState(name: "Morgan", startedAge: 30, compatibility: 60, committed: true)
        state.career.activeSituation = CareerSituation(kind: .workFollowsHome, startedAge: 40, remainingYears: 1, commitment: 6, pressure: 8)
        let partnerBefore = state.partner

        let result = CareerSituationSystem.resolveYear(state: &state)

        #expect(result.consequences.contains { $0.source == .career && $0.target == .relationships })
        #expect(state.partner == partnerBefore)
        #expect(result.milestoneHeadline == "Work Won The Argument")
    }

    @Test func distanceArcRewardsFollowThroughOverTwoYears() {
        var state = LifeState(name: "Repair", seed: 34_003)
        state.character.age = 38
        state.partner = PartnerState(name: "Alex", startedAge: 30, compatibility: 65, bond: 42, resentment: 50, committed: true)
        state.partner?.activeSituation = RelationshipSituation(startedAge: 36, remainingYears: 1, repairProgress: 3, strain: 2)

        RelationshipSituationSystem.record(.repairedConflict, state: &state)
        let result = RelationshipSituationSystem.resolveYear(state: &state)

        #expect(result.milestoneHeadline == "You Closed The Distance")
        #expect(state.partner?.activeSituation == nil)
        #expect(state.resolvedRelationshipSituations.first?.kind == RelationshipSituationKind.distance.rawValue)
        #expect((state.partner?.bond ?? 0) > 42)
    }

    @Test func v33SaveDefaultsNewSituationStateWithoutChangingCoreState() throws {
        let source = LifeState(name: "Legacy", seed: 34_004)
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        json["saveVersion"] = 33
        json.removeValue(forKey: "resolvedRelationshipSituations")
        if var career = json["career"] as? [String: Any] {
            career.removeValue(forKey: "activeSituation")
            career.removeValue(forKey: "resolvedSituations")
            json["career"] = career
        }
        let decoded = try JSONDecoder().decode(LifeState.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded.career.activeSituation == nil)
        #expect(decoded.career.resolvedSituations.isEmpty)
        #expect(decoded.resolvedRelationshipSituations.isEmpty)
        #expect(decoded.cash == source.cash)
        #expect(decoded.randomStreams == source.randomStreams)
    }

    @Test func activeSituationsSuppressDuplicateStorylets() {
        var state = LifeState(name: "No Duplicate", seed: 34_005)
        state.career.activeSituation = CareerSituation(kind: .promotionTrack, startedAge: 30)
        #expect(!SituationStoryletPolicy.allows(eventID: "career-promotion-window", state: state))
        #expect(!SituationStoryletPolicy.allows(eventID: "promotion-or-plateau", state: state))
        #expect(SituationStoryletPolicy.allows(eventID: "health-pain", state: state))
    }
}

@MainActor
struct FamilyAppraisalTests {
    @Test func felonyEstrangesAPrincipledFamilyContactOnce() {
        var state = LifeState(name: "Consequences", seed: 35_001)
        state.character.age = 32
        var cautious = PersonalityProfile.neutral
        cautious.baseline.riskTolerance = 20
        cautious.current.riskTolerance = 20
        cautious.refreshEstablishedFlags()
        state.family.contacts = [FamilyContact(
            name: "Jordan",
            role: .sibling,
            bond: 30,
            lastResolvedAge: 20,
            personality: cautious
        )]
        state.legal.record = .felony
        state.legal.lastFirearmConsequenceAge = 32

        let result = FamilyAppraisalSystem.resolveYear(
            state: &state,
            snapshot: YearInfluenceSnapshot(age: 32, scores: InfluenceVector(), influentialAction: nil)
        )

        #expect(state.family.contacts[0].bond == 18)
        #expect(state.family.contacts[0].stance == .estranged)
        #expect(result.milestoneHeadline == "Jordan Pulled Away")

        state.character.age = 33
        _ = FamilyAppraisalSystem.resolveYear(
            state: &state,
            snapshot: YearInfluenceSnapshot(age: 33, scores: InfluenceVector(), influentialAction: nil)
        )
        #expect(state.family.contacts[0].bond == 18)
    }

    @Test func familyFocusImprovesChildrenAndEmpatheticContactWithoutExtraActions() {
        var state = LifeState(name: "Present", seed: 35_002)
        state.character.age = 34
        state.family.children = [ChildState(name: "River", temperament: .curious)]
        var empathetic = PersonalityProfile.neutral
        empathetic.baseline.empathy = 78
        empathetic.current.empathy = 78
        empathetic.refreshEstablishedFlags()
        state.family.contacts = [FamilyContact(
            name: "Avery",
            role: .parent,
            bond: 66,
            lastResolvedAge: 25,
            personality: empathetic
        )]

        let result = FamilyAppraisalSystem.resolveYear(
            state: &state,
            snapshot: YearInfluenceSnapshot(age: 34, scores: InfluenceVector(family: 3), influentialAction: .parentingPresence)
        )

        #expect(state.family.children[0].bond == 57)
        #expect(state.family.contacts[0].bond == 70)
        #expect(state.family.contacts[0].stance == .warm)
        #expect(result.bullets == ["Avery moved closer"])
    }

    @Test func legacyFamilyContactDecodesWithNeutralAppraisalState() throws {
        let contact = FamilyContact(name: "Lee", role: .relative, lastResolvedAge: 24)
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(contact)) as? [String: Any])
        json.removeValue(forKey: "personality")
        json.removeValue(forKey: "stance")
        json.removeValue(forKey: "lastJudgementAge")
        json.removeValue(forKey: "lastJudgementReason")
        let decoded = try JSONDecoder().decode(FamilyContact.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded.bond == 45)
        #expect(decoded.stance == .neutral)
        #expect(decoded.personality == .neutral)
    }
}

@MainActor
struct DynamicCastTests {
    @Test func castMembersKeepIdentitySeparateFromRoleAndSelectTheRelevantPerson() {
        var directory = NPCDirectory()
        directory.insert(NPCState(
            memberID: "friend-jordan",
            name: "Jordan",
            role: .friend,
            importance: .recurring,
            coreFlags: [.dependable],
            rapport: 8,
            lastInteractionAge: 28
        ))
        directory.insert(NPCState(
            memberID: "friend-riley",
            name: "Riley",
            role: .friend,
            importance: .pivotal,
            coreFlags: [.critical],
            rapport: -28,
            lastInteractionAge: 21,
            activity: .hostile
        ))

        #expect(directory.members(for: .friend).count == 2)
        #expect(directory[.friend]?.memberID == "friend-riley")
        #expect(directory[.friend]?.id == "friend-riley")
    }

    @Test func dormantCastMemberReactivatesOnRelevantContextAndRetainsMemory() {
        var state = LifeState(name: "Cast", seed: 36_001)
        state.character.age = 30
        state.npcs.insert(NPCState(
            memberID: "boss-dana",
            name: "Dana",
            role: .boss,
            importance: .recurring,
            coreFlags: [.ambitious],
            rapport: 4,
            lastInteractionAge: 24,
            activity: .dormant
        ))

        DynamicCastSystem.reactivate(role: .boss, state: &state)
        guard var member = state.npcs[.boss] else {
            Issue.record("Expected dormant boss to remain in the cast")
            return
        }
        #expect(member.activity == .active)
        member.rapport = -30
        DynamicCastSystem.recordInteraction(.protectBoundaries, member: &member, age: 30)
        state.npcs.update(member)

        #expect(state.npcs[.boss]?.activity == .hostile)
        #expect(state.npcs[.boss]?.memories.first?.actionID == .protectBoundaries)
    }

    @Test func inactiveNonPivotalCastMembersHibernateWithoutRemovingThem() {
        var state = LifeState(name: "Dormant", seed: 36_002)
        state.character.age = 40
        state.npcs.insert(NPCState(
            memberID: "friend-jamie",
            name: "Jamie",
            role: .friend,
            importance: .recurring,
            coreFlags: [.sociable],
            lastInteractionAge: 36
        ))

        _ = DynamicCastSystem.resolveYear(state: &state)

        #expect(state.npcs[.friend]?.activity == .dormant)
        #expect(state.npcs.members(for: .friend).count == 1)
    }

    @Test func interactionBuildsDurableBondAndRevealsPersonalityFromRepeatedEvidence() {
        var personality = PersonalityProfile.neutral
        personality.current.drive = 82
        personality.current.sociability = 20
        personality.refreshEstablishedFlags()
        var member = NPCState(
            memberID: "friend-observed",
            name: "Avery",
            role: .friend,
            importance: .recurring,
            coreFlags: [.ambitious],
            personality: personality,
            rapport: 2,
            lastInteractionAge: 24
        )

        DynamicCastSystem.recordInteraction(.reachOut, member: &member, age: 25)

        #expect(member.bond == 21)
        #expect(member.discoveredTraits.isEmpty)

        DynamicCastSystem.recordInteraction(.reachOut, member: &member, age: 26)

        #expect(member.bond == 24)
        #expect(member.discoveredTraits.count == 1)
        #expect(personality.salientFlags.contains(member.discoveredTraits[0]))
    }

    @Test func generatedCastHasBoundedCompatibleTagsQuietGoalsAndAConnection() {
        let state = LifeState(name: "Generated cast", seed: 41_001)
        let first = LifeGenerationSystem.generatedNPC(role: .friend, importance: .recurring, state: state)
        let second = LifeGenerationSystem.generatedNPC(role: .friend, importance: .recurring, state: state)

        #expect(first.stableTags.count >= 2)
        #expect(first.stableTags.count <= 4)
        #expect(CharacterTagSystem.areCompatible(first.stableTags))
        #expect((1...2).contains(first.goals.count))
        #expect(first.connections == [NPCConnection(kind: .friend, startedAge: state.character.age, endedAge: nil)])
        #expect(first.stableTags == second.stableTags)
        #expect(first.goals == second.goals)
    }

    @Test func strongBehaviorRevealsAStableTagButGoalsRemainInternalState() {
        var member = NPCState(
            memberID: "friend-loyal",
            name: "Jordan",
            role: .friend,
            importance: .recurring,
            coreFlags: [.dependable],
            stableTags: [.loyal],
            goals: [NPCGoalState(kind: .belonging, progress: 44, lastResolvedAge: 30)],
            lastInteractionAge: 30
        )

        NPCObservationSystem.record(
            stableTag: .loyal,
            strength: 2,
            age: 31,
            reason: "They checked in.",
            member: &member
        )
        #expect(member.discoveredTags.isEmpty)

        NPCObservationSystem.record(
            stableTag: .loyal,
            age: 32,
            reason: "They stayed through the difficult part.",
            member: &member
        )
        #expect(member.discoveredTags == [.loyal])
        #expect(member.primaryGoal?.kind == .belonging)
    }

    @Test func quietGoalsHibernateAndCatchUpOnlyWhenThePersonBecomesRelevant() {
        var state = LifeState(name: "Quiet goals", seed: 41_002)
        state.character.age = 36
        state.npcs.insert(NPCState(
            memberID: "boss-goal",
            name: "Dana",
            role: .boss,
            importance: .recurring,
            coreFlags: [.ambitious],
            stableTags: [.dutyBound],
            goals: [NPCGoalState(kind: .careerProgress, progress: 30, lastResolvedAge: 24)],
            lastInteractionAge: 24,
            activity: .dormant,
            independentLife: NPCIndependentLife(lastResolvedAge: 24)
        ))

        _ = DynamicCastSystem.resolveYear(state: &state)
        #expect(state.npcs[.boss]?.goals.first?.progress == 30)

        DynamicCastSystem.reactivate(role: .boss, state: &state)
        #expect((state.npcs[.boss]?.goals.first?.progress ?? 0) > 30)
        #expect(state.npcs[.boss]?.goals.first?.lastResolvedAge == 36)
    }

    @Test func sameCrisisProducesDifferentReactionsFromStableCharacterTags() {
        var state = LifeState(name: "Character reactions", seed: 41_003)
        state.character.age = 34
        state.npcs.insert(NPCState(
            memberID: "friend-loyal",
            name: "Jordan",
            role: .friend,
            importance: .pivotal,
            coreFlags: [.dependable],
            stableTags: [.loyal],
            bond: 40,
            rapport: 10,
            lastInteractionAge: 34,
            activity: .pivotal
        ))
        state.npcs.insert(NPCState(
            memberID: "friend-material",
            name: "Riley",
            role: .friend,
            importance: .pivotal,
            coreFlags: [.critical],
            stableTags: [.materialistic],
            bond: 40,
            rapport: 10,
            lastInteractionAge: 34,
            activity: .pivotal
        ))
        let crisis = LifeSignal(kind: .financialCrisis, magnitude: .critical, age: 34, sourceHeadline: "Money became an immediate crisis")

        _ = DynamicCastSystem.resolveYear(state: &state, signals: [crisis])

        #expect(state.npcs.member(id: "friend-loyal")?.rapport == 13)
        #expect(state.npcs.member(id: "friend-loyal")?.discoveredTags == [.loyal])
        #expect(state.npcs.member(id: "friend-material")?.rapport == 6)
        #expect(state.npcs.member(id: "friend-material")?.discoveredTags == [.materialistic])
    }

    @Test func contentPredicateCanTargetACharacterCombinationInsteadOfOneFlag() {
        var state = LifeState(name: "Combination", seed: 41_004)
        state.character.age = 35
        state.npcs.insert(NPCState(
            memberID: "friend-combination",
            name: "Avery",
            role: .friend,
            importance: .recurring,
            coreFlags: [.dependable],
            stableTags: [.loyal, .creative],
            goals: [NPCGoalState(kind: .creativeAchievement, progress: 55, lastResolvedAge: 34)],
            connections: [NPCConnection(kind: .professionalContact, startedAge: 30, endedAge: nil)],
            bond: 58,
            rapport: 14,
            lastInteractionAge: 33,
            memories: [CastMemory(age: 33, actionID: .reachOut, note: "You stayed in touch.")],
            circumstances: [NPCCircumstance(kind: .confident, intensity: 1, startedAge: 34, expiresAge: 36)],
            independentLife: NPCIndependentLife(chapter: .buildingCareer, careerStanding: 61, lastResolvedAge: 34)
        ))
        let predicate = ContentPredicate(
            npcRole: .friend,
            npcTags: [.loyal, .creative],
            npcCircumstances: [.confident],
            npcGoals: [.creativeAchievement],
            npcConnections: [.professionalContact],
            requiredNPCMemoryActions: [.reachOut],
            independentChapters: [.buildingCareer],
            minimumBond: 50,
            minimumRapport: 10,
            minimumYearsSinceContact: 2,
            maximumYearsSinceContact: 3
        )

        #expect(predicate.matches(state))
        state.npcs[.friend]?.rapport = 5
        #expect(!predicate.matches(state))
    }

    @Test func versionFortyBackfillsCharacterDepthWithoutConsumingGameplayRandomness() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("onelife-v40-character-depth-\(UUID().uuidString).json")
        var source = LifeState(name: "Legacy cast", seed: 41_005)
        source.npcs.insert(NPCState(
            memberID: "friend-legacy",
            name: "Jamie",
            role: .friend,
            importance: .recurring,
            coreFlags: [.dependable],
            lastInteractionAge: 28
        ))
        let random = source.random
        let streams = source.randomStreams
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(source)) as? [String: Any])
        json["saveVersion"] = 40
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: url)

        guard case .loaded(let migrated) = LifePersistence(saveURL: url).load(),
              let member = migrated.npcs.member(id: "friend-legacy") else {
            Issue.record("v40 cast should migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect((2...4).contains(member.stableTags.count))
        #expect((1...2).contains(member.goals.count))
        #expect(member.connections.first?.kind == .friend)
        #expect(migrated.random == random)
        #expect(migrated.randomStreams == streams)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func dormantLivesHibernateUntilContextReactivatesThem() {
        var state = LifeState(name: "Lazy", seed: 38_002)
        state.character.age = 36
        state.npcs.insert(NPCState(
            memberID: "boss-sleeping",
            name: "Quinn",
            role: .boss,
            importance: .recurring,
            coreFlags: [.fair],
            lastInteractionAge: 26,
            activity: .dormant,
            independentLife: NPCIndependentLife(lastResolvedAge: 24)
        ))

        _ = DynamicCastSystem.resolveYear(state: &state)
        #expect(state.npcs[.boss]?.independentLife.lastResolvedAge == 24)

        DynamicCastSystem.reactivate(role: .boss, state: &state)
        #expect(state.npcs[.boss]?.independentLife.lastResolvedAge == 36)
        #expect(state.npcs[.boss]?.activity == .active)
    }

    @Test func promotionReactionComesFromPersonalityCircumstanceAndHistory() {
        var state = LifeState(name: "Promoted", seed: 38_003)
        state.character.age = 34
        var personality = PersonalityProfile.neutral
        personality.current.drive = 85
        personality.current.empathy = 25
        personality.refreshEstablishedFlags()
        state.npcs.insert(NPCState(
            memberID: "friend-rival",
            name: "Riley",
            role: .friend,
            importance: .pivotal,
            coreFlags: [.ambitious],
            personality: personality,
            bond: 48,
            rapport: 16,
            lastInteractionAge: 33,
            activity: .pivotal,
            independentLife: NPCIndependentLife(careerStanding: 30, lastResolvedAge: 34)
        ))

        let resolution = DynamicCastSystem.resolveYear(state: &state, careerMilestone: "The Promotion Became Yours")
        let member = state.npcs.member(id: "friend-rival")

        #expect(member?.rapport == 11)
        #expect(member?.bond == 48)
        #expect(member?.currentCircumstance?.kind == .jealous)
        #expect(resolution.bullets.first?.contains("comparison") == true)
    }
}

@MainActor
struct CastSituationTests {
    @Test func hostileCastMemberSurfacesOnlyWhenThereIsCurrentExposureAndThenCoolsDown() {
        var state = LifeState(name: "Exposure", seed: 37_001)
        state.character.age = 35
        state.career.level = .established
        state.stats.rep = 62
        state.npcs.insert(NPCState(
            memberID: "boss-rival-dana",
            name: "Dana",
            role: .boss,
            importance: .recurring,
            coreFlags: [.ambitious],
            rapport: -35,
            lastInteractionAge: 31,
            activity: .hostile
        ))

        let event = CastSituationSystem.select(state: &state)

        #expect(event?.headline == "Dana Reopens An Old Grudge")
        #expect(event?.choices.allSatisfy { $0.castMemberID == "boss-rival-dana" } == true)
        #expect(state.npcs.member(id: "boss-rival-dana")?.lastSituationAge == 35)
        #expect(CastSituationSystem.select(state: &state) == nil)
    }

    @Test func dormantSupportRequiresFinancialPressureAndChoiceBecomesCastHistory() {
        var state = LifeState(name: "Support", seed: 37_002)
        state.character.age = 42
        state.finance.financialStress = 62
        state.npcs.insert(NPCState(
            memberID: "friend-jordan",
            name: "Jordan",
            role: .friend,
            importance: .recurring,
            coreFlags: [.dependable],
            rapport: 30,
            lastInteractionAge: 37,
            activity: .dormant
        ))

        guard let event = CastSituationSystem.select(state: &state),
              let choice = event.choices.first(where: { $0.id == .accept }) else {
            Issue.record("Expected a dormant supportive contact to surface during financial stress")
            return
        }
        let beforeCash = state.cash
        _ = EventChoiceCoordinator.resolve(
            choice: choice,
            event: PresentedEvent(event, kind: .yearly),
            state: &state
        )

        let member = state.npcs.member(id: "friend-jordan")
        #expect(event.headline == "Jordan Calls At A Tight Moment")
        #expect(state.cash > beforeCash)
        #expect(member?.rapport == 33)
        #expect(member?.activity == .pivotal)
        #expect(member?.memories.first?.age == 42)
    }

    @Test func dormantSupportDoesNotAppearWithoutItsCause() {
        var state = LifeState(name: "No Rescue", seed: 37_003)
        state.character.age = 42
        state.finance.financialStress = 20
        state.npcs.insert(NPCState(
            memberID: "friend-casey",
            name: "Casey",
            role: .friend,
            importance: .recurring,
            coreFlags: [.dependable],
            rapport: 35,
            lastInteractionAge: 37,
            activity: .dormant
        ))

        #expect(CastSituationSystem.select(state: &state) == nil)
    }

    @Test func successfulDormantContactCanCreateEarnedOpportunity() {
        var state = LifeState(name: "Network", seed: 38_004)
        state.character.age = 40
        state.finance.financialStress = 20
        state.career.level = .entry
        state.npcs.insert(NPCState(
            memberID: "friend-success",
            name: "Jamie",
            role: .friend,
            importance: .recurring,
            coreFlags: [.ambitious],
            rapport: 18,
            lastInteractionAge: 34,
            activity: .dormant,
            independentLife: NPCIndependentLife(chapter: .established, careerStanding: 82, lastResolvedAge: 34, currentNote: "Their career took off.")
        ))

        let event = CastSituationSystem.select(state: &state)

        #expect(event?.headline == "An Old Contact Opens A Door")
        #expect(event?.choices.count == 2)
    }
}

@MainActor
struct CastDomainHookTests {
    @Test func familyHealthMomentTargetsOneContactAndWritesBackTheChoice() {
        var state = LifeState(name: "Family Hook", seed: 39_001)
        state.character.age = 41
        state.health.physicalWellbeing = 30
        state.health.mentalWellbeing = 35
        state.family.contacts = [
            FamilyContact(name: "Morgan", role: .parent, bond: 68, lastResolvedAge: 35, lastJudgementAge: 40)
        ]

        guard let event = FamilySituationSystem.select(state: state),
              let choice = event.choices.first(where: { $0.id == .accept }) else {
            Issue.record("Expected a supportive family health moment")
            return
        }
        _ = EventChoiceCoordinator.resolve(choice: choice, event: PresentedEvent(event, kind: .yearly), state: &state)

        #expect(event.headline == "Morgan Notices You Are Struggling")
        #expect(state.family.contacts[0].bond == 75)
        #expect(state.family.contacts[0].lastJudgementAge == 41)
        #expect(state.family.contacts[0].lastSituationAge == 41)
    }

    @Test func friendReferralWritesTheOutcomeToBothPeople() {
        var state = LifeState(name: "Referral", seed: 39_002)
        state.character.age = 38
        state.career.level = .established
        state.npcs.insert(NPCState(
            memberID: "friend-avery",
            name: "Avery",
            role: .friend,
            importance: .recurring,
            coreFlags: [.dependable],
            rapport: 24,
            lastInteractionAge: 36,
            activity: .active
        ))
        state.npcs.insert(NPCState(
            memberID: "boss-dana",
            name: "Dana",
            role: .boss,
            importance: .recurring,
            coreFlags: [.fair],
            rapport: 2,
            lastInteractionAge: 37,
            activity: .active
        ))

        guard let event = CastSituationSystem.select(state: &state),
              let choice = event.choices.first(where: { $0.id == .accept }) else {
            Issue.record("Expected an earned two-person referral")
            return
        }
        _ = EventChoiceCoordinator.resolve(choice: choice, event: PresentedEvent(event, kind: .yearly), state: &state)

        #expect(event.headline == "Avery Puts Their Name On Yours")
        #expect(state.npcs.member(id: "friend-avery")?.rapport == 27)
        #expect(state.npcs.member(id: "boss-dana")?.rapport == 7)
    }

    @Test func ordinaryWorkPressureNeedsVisibleWorkInstability() {
        var state = LifeState(name: "Work Hook", seed: 39_003)
        state.character.age = 35
        state.career.level = .entry
        state.career.careerClass = .normal
        state.career.security = 35
        state.npcs.insert(NPCState(
            memberID: "boss-reese",
            name: "Reese",
            role: .boss,
            importance: .recurring,
            coreFlags: [.fair],
            rapport: 4,
            lastInteractionAge: 34,
            activity: .active
        ))

        #expect(CastSituationSystem.select(state: &state)?.headline == "Reese Wants A Clear Answer")
    }
}

@MainActor
struct CharacterDrivenContextTests {
    @Test func currentContextRanksCrisisDomainsWithoutLosingOtherDomainState() {
        var state = LifeState(name: "Context", seed: 38_005, startingAge: 34)
        state.career.level = .unemployed
        state.finance.financialStress = 85
        state.health.physicalWellbeing = 30
        state.health.mentalWellbeing = 32
        state.syncHealthCompatibility()

        let signals = LifeContextResolver.topSignals(for: state)

        #expect(signals.count == 3)
        #expect(Set(signals.map(\.domain)).count == 3)
        #expect(signals.contains(where: { $0.domain == .career }))
        #expect(signals.contains(where: { $0.domain == .finances }))
    }

    @Test func storedTimelineSurvivesJournalTrimming() {
        var state = LifeState(name: "Biography", seed: 38_006)
        state.timeline = [LifeTimelineEntry(id: 1, age: 18, headline: "Graduated High School", detail: "The first chapter closed.")]
        state.history = (2...50).map {
            HistoryEntry(id: UInt64($0), age: $0, headline: "Ordinary Year", detail: "Life continued.", deltas: DeltaSummary())
        }
        state.clamp()

        #expect(state.history.count == 40)
        #expect(LifeTimelineResolver.milestones(for: state).first?.age == 18)
    }
}

@MainActor
struct CareerClassTests {
    @Test func careerClassesHaveDistinctEconomicsAndEarnedGates() {
        var state = LifeState(name: "Career", seed: 39_001, startingAge: 32)
        state.career.track = .office
        state.career.level = .established
        state.career.performance = 72
        state.stats.rep = 60
        state.personality.talent = .publicLeadership
        state.cash = 20_000
        let normalIncome = state.career.annualIncome

        #expect(CareerOpportunitySystem.specialEligibilityIssue(in: state) == nil)
        _ = CareerSystem.resolve(.enterSpecial, state: &state)
        #expect(state.career.careerClass == .special)
        #expect(state.career.specialCareerID == .entrepreneurship)
        #expect(state.career.venture != nil)
        #expect(state.cash == 10_000)
        #expect(state.career.annualIncome > normalIncome)

        state.career.level = .senior
        state.career.specialMomentum = 65
        state.stats.rep = 84
        state.cash = CareerPolicy.diamondCapitalThreshold
        #expect(CareerOpportunitySystem.diamondEligibilityIssue(in: state) == nil)

        _ = CareerSystem.resolve(.enterDiamond, state: &state)
        #expect(state.career.careerClass == .diamond)
        #expect(state.career.legacyLeverage == 10)
    }

    @Test func partTimeWorkTradesIncomeForLowerBurnout() {
        var state = LifeState(name: "Part Time", seed: 39_002, startingAge: 30)
        state.career.track = .trades
        state.career.level = .established
        state.career.burnout = 50
        let normalIncome = state.career.annualIncome

        _ = CareerSystem.resolve(.partTime, state: &state)

        #expect(state.career.careerClass == .partTime)
        #expect(state.career.annualIncome < normalIncome)
        #expect(state.career.burnout == 40)
    }

    @Test func diamondCareerCannotBeSelectedWithoutSpecialCareerHistory() {
        var state = LifeState(name: "Gate", seed: 39_003, startingAge: 40)
        state.career.level = .senior
        state.career.performance = 95
        state.career.specialMomentum = 90
        state.stats.rep = 95
        state.cash = CareerPolicy.diamondCapitalThreshold - 1

        #expect(CareerOpportunitySystem.diamondEligibilityIssue(in: state) == "Requires a proven Special career")
        _ = CareerSystem.resolve(.enterDiamond, state: &state)
        #expect(state.career.careerClass == .normal)
    }
}

@MainActor
struct VentureSystemTests {
    @Test func splitMixSequenceIsPinned() {
        var random = SeededRandom(seed: 123)
        #expect((0..<8).map { _ in random.next(in: 0...99) } == [75, 48, 40, 71, 22, 96, 34, 37])
    }

    @Test func ventureDecisionsAreLimitedAndStateRoundTrips() throws {
        var venture = VentureState(seed: 91)
        #expect(VentureSystem.decide(.pivot, venture: &venture, age: 30) != nil)
        #expect(VentureSystem.decide(.cutBurn, venture: &venture, age: 30) != nil)
        #expect(VentureSystem.decide(.hireAdvisor, venture: &venture, age: 30) == nil)
        #expect(VentureSystem.decide(.pivot, venture: &venture, age: 31) != nil)
        var state = LifeState(name: "Founder", seed: 91)
        state.career.venture = venture
        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(restored.career.venture == venture)
    }

    @Test func ventureReplayAndOfferExpiryAreDeterministic() {
        var first = VentureState(seed: 992)
        var second = VentureState(seed: 992)
        var firstOutcomes: [VentureYearOutcome?] = []
        var secondOutcomes: [VentureYearOutcome?] = []
        for age in 30...45 {
            firstOutcomes.append(VentureSystem.resolveYear(venture: &first, age: age, talent: .entrepreneurial, policy: WorldModifierSnapshot()))
            secondOutcomes.append(VentureSystem.resolveYear(venture: &second, age: age, talent: .entrepreneurial, policy: WorldModifierSnapshot()))
        }
        #expect(first == second)
        #expect(firstOutcomes == secondOutcomes)
        first.stage = .growth
        first.pendingOffer = VentureOffer(id: "expired", headline: "Old offer", amount: 25_000, expiresAtAge: 40)
        _ = VentureSystem.resolveYear(venture: &first, age: 41, talent: nil, policy: WorldModifierSnapshot())
        #expect(first.pendingOffer == nil)
    }

    @Test func ventureAdvancesAndFailureCarriesDomainConsequences() {
        var venture = VentureState(seed: 1_204)
        venture.companyCash = 250_000
        venture.annualBurn = 500
        venture.traction = 24
        var reachedPrototype = false
        for age in 30...55 {
            _ = VentureSystem.resolveYear(venture: &venture, age: age, talent: .entrepreneurial, policy: WorldModifierSnapshot())
            if venture.stage == .prototype { reachedPrototype = true; break }
        }
        #expect(reachedPrototype)

        venture.stage = .idea
        venture.companyCash = 1
        venture.annualBurn = 3_000
        let failure = VentureSystem.resolveYear(venture: &venture, age: 60, talent: nil, policy: WorldModifierSnapshot())
        #expect(venture.stage == .failed)
        #expect(failure?.health == -5)
        #expect(failure?.relationship == -3)
    }

    @Test func ventureCommandsRespectBlockedAndPendingEventStates() {
        var eventState = LifeState(name: "Pending", seed: 992)
        eventState.career.venture = VentureState(seed: 992)
        eventState.pendingEvent = PresentedEvent(LifeEventRegistry.all[0])
        let eventSimulator = LifeSimulator(state: eventState)
        #expect(eventSimulator.availability(for: .domain(.venture(.pivot))) == .locked("Finish the current moment first"))

        var state = LifeState(name: "Blocked", seed: 993)
        state.career.venture = VentureState(seed: 993)
        state.recovery = RecoveryWindow(kind: .financial, openedAge: state.character.age)
        let simulator = LifeSimulator(state: state)
        #expect(simulator.execute(.domain(.venture(.pivot))) == nil)
        #expect(simulator.availability(for: .domain(.venture(.pivot))) == .locked("Stabilize your recovery first"))
        #expect(simulator.state == state)
    }

    @Test func ventureExitIsAttributedToEnterpriseIncome() {
        var state = LifeState(name: "Founder exit", seed: 994, startingAge: 30)
        var venture = VentureState(seed: 994)
        venture.companyCash = 30_000
        venture.pendingOffer = VentureOffer(id: "offer", headline: "A buyer called", amount: 70_000, expiresAtAge: 31)
        state.career.venture = venture
        let simulator = LifeSimulator(state: state)

        #expect(simulator.execute(.domain(.venture(.acceptOffer))) != nil)
        #expect(simulator.state.aggregates.lifetimeIncomeBySource[.enterprise] == 100_000)
        #expect(simulator.state.aggregates.lifetimeIncomeBySource[.special] == nil)
    }
}

@MainActor
struct EconomyTests {
    private func neutral() -> LifeState {
        var s = LifeState(name: "Economy", seed: 551, startingAge: 30)
        s.world = WorldSystem.neutral(runSeed: 551, age: 30)
        s.career.track = .office; s.career.level = .entry
        s.flags.attendsSchool = false; s.education.phase = .leftSchool
        s.cash = 0
        return s
    }

    @Test func incomeSourceTotalsRoundTripAndExcludeUntypedInflows() throws {
        var state = neutral()
        _ = FinanceSystem.transact(.init(amount: 2_500, purpose: .income, incomeSource: .crime), state: &state)
        _ = FinanceSystem.transact(.init(amount: 8_000, purpose: .income), state: &state)
        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(restored.aggregates.lifetimeIncomeBySource[.crime] == 2_500)
        #expect(restored.aggregates.lifetimeIncomeBySource[.salary] == nil)
    }

    @Test func peakCashDecodeIsPureAndLegacyMigrationSeedsIt() throws {
        var state = neutral()
        state.cash = 25_000
        state.aggregates.peakCash = 0
        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(LifeState.self, from: encoded)
        #expect(decoded.aggregates.peakCash == 0)

        var legacy = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy["saveVersion"] = 49
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("onelife-peak-migration-\(UUID().uuidString).json")
        try JSONSerialization.data(withJSONObject: legacy, options: [.sortedKeys]).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        guard case .loaded(let migrated) = LifePersistence(saveURL: url).load() else {
            Issue.record("Legacy peak cash save should migrate")
            return
        }
        #expect(migrated.aggregates.peakCash == 25_000)
    }

    @Test func giftAndLossSequencesStayUniqueAfterHistoryTrimming() {
        var state = neutral()
        state.assets.giftHistory = (1...24).map {
            AssetGiftRecord(id: UInt64($0), age: 30, assetCategory: .jewelry, assetName: "Ring", value: 1_000, recipientID: "friend", recipientName: "Avery", major: false)
        }
        state.assets.lossHistory = (1...24).map {
            AssetLossRecord(id: UInt64($0), age: 30, assetCategory: .jewelry, assetName: "Ring", value: 1_000, action: .report, reason: "test")
        }
        state.clamp()
        let giftID = state.assets.claimGiftSequence()
        let lossID = state.assets.claimLossSequence()
        #expect(state.assets.giftHistory.count == 12)
        #expect(state.assets.lossHistory.count == 12)
        #expect(!state.assets.giftHistory.contains { $0.id == giftID })
        #expect(!state.assets.lossHistory.contains { $0.id == lossID })
        #expect(giftID == 25)
        #expect(lossID == 25)
    }

    @Test func ordinaryWorkSupportsEarnedStability() {
        let s = neutral()
        let d = EconomyCalculator.calculate(s, world: WorldModifierSnapshot(), earned: 42_000, rent: 0).detail
        #expect(d.totalTaxes == 6_350)
        #expect(d.expectedNet == 8_050)
        #expect(d.closingCash == 8_050)
        #expect((4_200...8_400).contains(d.expectedNet))
        let care = EconomyCalculator.calculate(s, world: WorldModifierSnapshot(), earned: 34_000, rent: 0).detail
        #expect(care.expectedNet > 0)
    }
    @Test func forecastIsPureAndMatchesFixedSettlement() {
        let s = neutral(); let before = s
        let forecast = EconomyCalculator.forecast(s)
        let actual = EconomyCalculator.calculate(s, world: WorldSystem.modifiers(for: s.world), earned: EconomyCalculator.earnings(s, world: WorldSystem.modifiers(for: s.world)), rent: 0)
        #expect(forecast.detail == actual.detail)
        #expect(s == before)
    }
    @Test func budgetDoesNotCreateCashOrStack() {
        var s = neutral(); s.cash = 1_000
        _ = HouseholdFinanceSystem.resolve(.budget, state: &s)
        _ = HouseholdFinanceSystem.resolve(.budget, state: &s)
        #expect(s.cash == 1_000)
        let result = EconomyCalculator.forecast(s)
        #expect(result.detail.discretionary == 600)
    }
    @Test func extraEarningsArePaidOnceAndTaxReconciles() {
        var s = neutral()
        FinanceSystem.creditExtra(2_100, state: &s)
        #expect(s.cash == 1_522)
        let actual = EconomyCalculator.calculate(s, world: WorldModifierSnapshot(), earned: 42_000, rent: 0)
        #expect(actual.detail.totalTaxes == EconomyPolicy.tax(44_100))
        #expect(actual.detail.closingCash == 44_100 - EconomyPolicy.tax(44_100) - 27_600)
        #expect(actual.finance.economy.earnedExtras == 0)
    }
    @Test func shortfallsRemainDebtWithoutCashFloorLoss() {
        var s = neutral(); s.career.level = .unemployed
        let r = EconomyCalculator.calculate(s, world: WorldModifierSnapshot(), earned: 0, rent: 0)
        #expect(r.detail.closingCash == 0)
        #expect(r.finance.consumerDebt == 21_700)
        #expect(r.finance.economy.shortfallYears == 1)
        let receipt = FinanceSystem.transact(.init(amount: -50_000, purpose: .medical), state: &s)
        #expect(receipt.debtAdded == 50_000)
        #expect(s.finance.medicalDebt == 50_000)
    }
    @Test func optionalPurchaseCannotBorrow() {
        var s = neutral(); s.cash = 500
        let before = s
        let result = FinanceSystem.transact(.init(amount: -1_000, purpose: .optionalPurchase), state: &s)
        #expect(!result.accepted)
        #expect(s == before)
    }
    @Test func mortgagesRequireActualPrincipalPayment() {
        var s = neutral(); s.cash = 50_000
        #expect(AssetSystem.purchase(listingID: "house-starter-condo", state: &s) != nil)
        let opening = s.assets.totalMortgageDebt
        let result = EconomyCalculator.calculate(s, world: WorldModifierSnapshot(), earned: 42_000, rent: 0)
        let paid = result.detail.receipts.reduce(0) { $0 + $1.principal }
        #expect(paid > 0)
        _ = AssetSystem.finalizeYear(assets: &s.assets, receipts: result.detail.receipts, age: 31)
        #expect(s.assets.totalMortgageDebt == opening - paid)
        #expect(result.detail.openingCash + 42_000 - result.detail.taxReconciliation - result.detail.essentials - result.detail.primaryHousing - result.detail.discretionary == result.detail.closingCash)
    }
    @Test func unpaidMortgageAccruesWithoutFreeEquity() {
        var s = neutral(); s.cash = 50_000
        _ = AssetSystem.purchase(listingID: "house-starter-condo", state: &s)
        s.cash = 0
        let before = s.assets.totalMortgageDebt
        let r = EconomyCalculator.calculate(s, world: WorldModifierSnapshot(), earned: 0, rent: 0)
        #expect(r.detail.receipts.first?.principal == 0)
        _ = AssetSystem.finalizeYear(assets: &s.assets, receipts: r.detail.receipts, age: 31)
        #expect(s.assets.totalMortgageDebt > before)
        #expect(s.assets.properties[0].delinquentYears == 1)
    }
    @Test func buyingThenSellingCannotMintMoney() {
        var s = neutral(); s.cash = 100_000
        let before = s.cash
        let receipt = AssetSystem.purchase(listingID: "car-used-compact", state: &s)!
        _ = AssetSystem.sell(ownershipID: receipt.ownershipID, state: &s)
        #expect(s.cash < before)
    }
    @Test func retirementAndDebtPaymentsConserveTransfers() {
        var s = neutral(); s.cash = 20_000; s.finance.consumerDebt = 15_000
        let worth = s.cash - s.finance.consumerDebt
        _ = HouseholdFinanceSystem.resolve(.payDebt, state: &s)
        #expect(s.cash - s.finance.consumerDebt == worth)
        s.finance.retirementContributionPercent = 15
        _ = HouseholdFinanceSystem.resolve(.retirement, state: &s)
        #expect(s.finance.retirementContributionPercent == 0)
    }
    @Test func workoutCompletesAndProtectsStudentDebt() {
        var s = neutral(); s.career.level = .unemployed
        s.finance.consumerDebt = 100_000; s.finance.medicalDebt = 20_000
        s.finance.studentDebt = 10_000; s.finance.economy.shortfallYears = 2
        #expect(FinanceSystem.workoutEligible(s))
        FinanceSystem.startWorkout(state: &s)
        for age in 31...35 {
            s.character.age = age
            let r = EconomyCalculator.calculate(s, world: WorldModifierSnapshot(), earned: 0, rent: 0)
            s.finance = r.finance; s.cash = r.detail.closingCash
        }
        #expect(s.finance.economy.workoutYearsRemaining == 0)
        #expect(s.finance.consumerDebt == 0 && s.finance.medicalDebt == 0)
        #expect(s.finance.studentDebt > 0)
        #expect(s.finance.economy.forgivenDebt >= 120_000)
        #expect(!FinanceSystem.workoutEligible(s))
    }
    @Test func migrationPreservesIdentityRNGAndConvertsOnce() throws {
        var s = neutral(); s.saveVersion = 32; s.cash = -400; s.finance.studentDebt = 50
        s.recovery = RecoveryWindow(kind: .financial, openedAge: 30)
        let migrated = try EconomyMigration.convert(s)
        #expect(migrated.cash == 0)
        #expect(migrated.finance.consumerDebt == 40_000)
        #expect(migrated.finance.studentDebt == 5_000)
        #expect(migrated.character == s.character && migrated.randomStreams == s.randomStreams)
        #expect(migrated.recovery == nil)
        #expect(try EconomyMigration.convert(migrated) == migrated)
        #expect(try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(migrated)) == migrated)
    }
    @Test func migrationKeepsEndedLifeEnded() throws {
        var s = neutral(); s.saveVersion = 32; s.isGameOver = true; s.endReason = .unresolvedFinancialCrisis
        let migrated = try EconomyMigration.convert(s)
        #expect(migrated.isGameOver && migrated.endReason == .unresolvedFinancialCrisis)
    }
}

extension EconomyTests {
    @Test func financedRentalCanLoseMoneyAndDepositsAreNotSpendable() {
        var s = neutral(); s.cash = 100_000; s.career.level = .senior
        _ = AssetSystem.purchase(listingID: "house-starter-condo", state: &s)
        _ = AssetSystem.purchase(listingID: "house-townhouse", state: &s)
        s.assets.properties[1].use = .rental
        s.assets.properties[1].rental = RentalPropertyState(strategy: .market, listedAge: 30, restrictedDeposit: 1_000)
        let before = s.cash
        let r = EconomyCalculator.calculate(s, world: WorldModifierSnapshot(), earned: 92_000, rent: s.assets.properties[1].expectedMarketRent)
        #expect(r.detail.rentalNet < 0)
        #expect(s.cash == before)
        #expect(s.assets.properties[1].rental?.restrictedDeposit == 1_000)
    }
    @Test func foreclosureRetainsDeficiencyAndTemporaryHousing() {
        var s = neutral(); s.cash = 50_000
        _ = AssetSystem.purchase(listingID: "house-starter-condo", state: &s)
        s.assets.properties[0].mortgageBalance = 200_000
        s.assets.properties[0].delinquentYears = 3
        let id = s.assets.properties[0].id
        let expected = s.assets.properties[0].saleProceeds
        let outcome = AssetSystem.finalizeYear(assets: &s.assets,
            receipts: [.init(propertyID: id, missedPayment: true)], age: 31)
        #expect(outcome.lostPrimary)
        #expect(outcome.cashSettlement == expected && expected < 0)
        s.cash = 0
        _ = FinanceSystem.transact(.init(amount: outcome.cashSettlement, purpose: .household), state: &s)
        #expect(s.finance.consumerDebt == -expected)
        s.finance.economy.temporaryHousing = true
        let r = EconomyCalculator.forecast(s)
        #expect(r.detail.primaryHousing <= 8_640)
    }
    @Test func vehicleCostsReplaceTransitAndCollegeReducesPay() {
        var s = neutral(); let w = WorldModifierSnapshot()
        let base = EconomyCalculator.essentialCost(s, world: w)
        s.cash = 20_000
        _ = AssetSystem.purchase(listingID: "car-used-compact", state: &s)
        #expect(EconomyCalculator.essentialCost(s, world: w) == base - 1_200)
        s.education.college.status = .enrolled
        #expect(EconomyCalculator.earnings(s, world: w) == 21_000)
    }
    @Test func currentSaveBackupAndPendingQuoteMigrationAreExact() throws {
        var s = neutral(); s.saveVersion = 32; s.cash = 250
        s.pendingEvent = PresentedEvent(LifeEvent(id: "frozen-quote", headline: "A Pending Choice", detail: "Keep this quote", weight: { _ in 0 }, choices: [
            EventChoice(id: .accept, title: "Pay", detail: "A cost", effects: EffectRange(cash: -15 ... -10), partnerEffect: PartnerEffect(), narrative: "Paid")
        ]))
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("life.json")
        let original = try JSONEncoder().encode(s)
        try original.write(to: url)
        let store = LifePersistence(saveURL: url)
        guard case .loaded(let migrated) = store.load() else { Issue.record("Legacy life did not load"); return }
        #expect(migrated.cash == 25_000)
        #expect(migrated.pendingEvent?.choices.first?.id == .accept)
        #expect(migrated.pendingEvent?.choices.first?.effects.cash == -1_500 ... -1_000)
        #expect(migrated.randomStreams == s.randomStreams)
        #expect(try Data(contentsOf: url.appendingPathExtension("before-economy-v33")) == original)
        _ = store.save(migrated)
        guard case .loaded(let again) = store.load() else { Issue.record("Converted life did not reload"); return }
        #expect(again == migrated)
        #expect(try Data(contentsOf: url.appendingPathExtension("before-economy-v33")) == original)
    }
    @Test func workoutCancellationDoesNotSellAssets() {
        var s = neutral(); s.cash = 10_000
        _ = AssetSystem.purchase(listingID: "car-used-compact", state: &s)
        s.finance.consumerDebt = 100_000; s.finance.economy.shortfallYears = 2
        let assets = s.assets
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("workout-\(UUID().uuidString).json")
        let simulator = LifeSimulator(state: s, store: LifePersistence(saveURL: url))
        _ = simulator.execute(.negotiateDebt)
        #expect(simulator.state.pendingEvent?.id == "economy-debt-workout")
        simulator.execute(.decline)
        #expect(simulator.state.assets == assets)
        #expect(simulator.state.finance.consumerDebt == 100_000)
        #expect(simulator.state.finance.economy.workoutYearsRemaining == 0)
    }
}

@MainActor
struct UnifiedResolutionTests {
    private func simulator(_ state: LifeState) -> LifeSimulator {
        LifeSimulator(state: state, store: ManualPersistence())
    }

    @Test func repeatableIncomeIsBoundedAndSeedReplays() {
        var state = LifeState(name: "Extra work", seed: 9_101)
        state.character.age = 30
        state.lifeStage = .build
        state.career.level = .entry
        state.cash = 2_000
        let first = simulator(state)
        let second = simulator(state)
        for run in [first, second] {
            #expect(run.execute(.workShift) != nil)
            #expect(run.execute(.workShift) != nil)
            let afterTwo = run.state
            #expect(run.execute(.workShift) == nil)
            #expect(run.state == afterTwo)
            #expect(run.state.actionUseCount(for: ActionID.workShift.rawValue) == 2)
            #expect(run.state.cash < 12_000)
        }
        #expect(first.state == second.state)
        #expect(first.lastOutcome == second.lastOutcome)
    }

    @Test func suggestionsAreReadOnlyBoundedAndMissingTargetsLock() {
        var state = LifeState(name: "Focus", seed: 9_102)
        state.character.age = 30
        state.lifeStage = .build
        state.partner = PartnerState(name: "Morgan", startedAge: 22, compatibility: 60, bond: 35, resentment: 40)
        let run = simulator(state)
        let before = run.state
        let first = run.suggestedActions(in: .love, focus: .partner)
        let second = run.suggestedActions(in: .love, focus: .partner)
        #expect(first.count <= 3)
        #expect(first.map(\.id) == second.map(\.id))
        #expect(run.state == before)
        #expect(first.contains { $0.request.key == "context:makeAmends" })
        #expect(run.availability(for: .contextual(.makeAmends, target: .cast("gone"))) != .available)
        #expect(run.execute(.contextual(.makeAmends, target: .cast("gone"))) == nil)
    }

    @Test func queuedSecondYearChoicePersistsAndResolvesSequentially() throws {
        let choice = EventChoice(id: .accept, title: "Continue", detail: "Carry on.", effects: EffectRange(), partnerEffect: PartnerEffect(), narrative: "You carried on.")
        var state = LifeState(name: "Two moments", seed: 9_103)
        state.character.age = 30
        state.lifeStage = .build
        state.lastYearSummary = YearSummary(bullets: [], stanceTitle: nil, shapeTitle: nil, focusNote: nil, silenceNote: nil, wasQuiet: false, age: 30, headline: "A Year of Choices")
        state.pendingEvent = PresentedEvent(id: "first", headline: "The First Pressure", detail: "A choice arrived.", choices: [choice], yearDeltas: DeltaSummary(), isPartnerEvent: false, kind: .yearly)
        state.queuedYearEvents = [PresentedEvent(id: "second", headline: "The Second Opening", detail: "Another choice arrived.", choices: [choice], yearDeltas: DeltaSummary(), isPartnerEvent: false, kind: .yearly)]
        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(restored.queuedYearEvents.count == 1)
        #expect(restored.randomStreams == state.randomStreams)
        let run = simulator(restored)
        run.execute(.accept)
        #expect(run.state.pendingEvent?.id == "second")
        #expect(run.state.yearChoicesResolved == 1)
        #expect(run.state.queuedYearEvents.isEmpty)
        run.execute(.accept)
        #expect(run.state.pendingEvent == nil)
        #expect(run.state.yearChoicesResolved == 2)
        #expect(run.state.lastYearSummary?.headline == "The Second Opening")
        #expect(run.state.lastYearSummary?.bullets.contains("The First Pressure") == true)
    }

    @Test func v47UseAgeMigratesWithoutChangingRandomStreams() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("onelife-action-v47-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        var state = LifeState(name: "Migration", seed: 9_104)
        state.saveVersion = 47
        state.actionUsage[ActionID.study.rawValue] = state.character.age
        let streams = state.randomStreams
        try JSONEncoder().encode(state).write(to: url)
        let result = LifePersistence(saveURL: url).load()
        guard case .loaded(let migrated) = result else {
            Issue.record("v47 save did not migrate")
            return
        }
        #expect(migrated.saveVersion == LifeState.currentSaveVersion)
        #expect(migrated.actionUseCount(for: ActionID.study.rawValue) == 1)
        #expect(migrated.randomStreams == streams)
    }
}

@MainActor
extension EconomyTests {
    @Test func negativeEquitySurvivesNormalizationAndSave() throws {
        var s = neutral(); s.cash = 50_000
        _ = AssetSystem.purchase(listingID: "house-starter-condo", state: &s)
        s.assets.properties[0].mortgageBalance = 200_000
        s.assets.normalize()
        let reloaded = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(s))
        #expect(reloaded.assets.properties[0].mortgageBalance == 200_000)
        #expect(reloaded.assets.properties[0].equity < 0)
    }
    @Test func extraDebtPaymentSpillsAcrossCategories() {
        var s = neutral(); s.cash = 10_000
        s.finance.consumerDebt = 1_000; s.finance.medicalDebt = 2_000; s.finance.studentDebt = 9_000
        let before = s.cash - s.finance.totalDebt
        _ = HouseholdFinanceSystem.resolve(.payDebt, state: &s)
        #expect(s.cash == 0 && s.finance.studentDebt == 2_000)
        #expect(s.cash - s.finance.totalDebt == before)
    }
    @Test func freelanceRangeIsBoundedWithoutRandomConsumption() {
        var s = neutral(); s.career.track = .freelance
        let before = s
        let baseline = EconomyCalculator.earnings(s, world: WorldSystem.modifiers(for: s.world))
        #expect(EconomyCalculator.earningsRange(s) == EconomyPolicy.rate(baseline, 7_500)...EconomyPolicy.rate(baseline, 12_500))
        #expect(s == before)
    }
}

@MainActor
extension EconomyTests {
    @Test func rentalAndWorkUseOnePersonalAllowance() {
        let s = neutral()
        let r = EconomyCalculator.calculate(s, world: WorldModifierSnapshot(), earned: 42_000, rent: 10_000)
        #expect(r.detail.totalTaxes == 8_350)
    }
    @Test func storyRetirementAndDebtPaymentsConserveWealth() {
        var s = neutral(); s.cash = 10_000; s.finance.consumerDebt = 5_000
        let before = s.netWorth
        _ = FinanceSystem.transact(.init(amount: -3_000, purpose: .retirementTransfer), state: &s)
        #expect(s.finance.retirementBalance == 3_000 && s.cash == 7_000)
        _ = FinanceSystem.transact(.init(amount: -2_000, purpose: .debtPayment), state: &s)
        #expect(s.finance.consumerDebt == 3_000 && s.cash == 5_000)
        #expect(s.netWorth == before)
    }
    @Test func optionalEventCannotSilentlyBorrow() {
        var s = neutral(); s.cash = 100
        let event = LifeEventRegistry.all.first { $0.id == "prom-cost" }!
        let choice = event.choices.first { $0.effects.cash.lowerBound < 0 }!
        #expect(FinanceSystem.choiceAvailability(choice, eventID: event.id, state: s) != .available)
        s.pendingEvent = PresentedEvent(event)
        let simulator = LifeSimulator(state: s, store: LifePersistence(saveURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)))
        simulator.execute(choice.id)
        #expect(simulator.state.cash == 100 && simulator.state.pendingEvent != nil)
    }
}

@MainActor
extension EconomyTests {
    @Test func assetGiftingRemovesMovableAssetAndImprovesPartnerBond() {
        var state = neutral()
        state.cash = 20_000
        state.partner = PartnerState(name: "Morgan", startedAge: 18, compatibility: 60)
        let vehicle = OwnedAsset(id: 1, listingID: "car-used-compact", category: .cars, name: "Compact", purchaseAge: 18, purchasePrice: 10_000, vehicle: OwnedVehicleState(kind: .car, condition: 82, currentValue: 8_000))
        state.assets.movableAssets = [vehicle]
        let before = state.partner!.bond
        let transaction = AssetSystem.gift(ownershipID: 1, recipient: .partner, state: &state)
        #expect(transaction != nil)
        #expect(state.assets.movableAssets.isEmpty)
        #expect(state.partner!.bond > before)
        #expect(state.assets.giftHistory.count == 1)
    }

    @Test func assetLossActionsRecordHistoryAndApplyCondition() {
        var state = neutral()
        state.cash = 10_000
        state.assets.movableAssets = [OwnedAsset(id: 1, listingID: "jewelry-gold-ring", category: .jewelry, name: "Ring", purchaseAge: 18, purchasePrice: 4_000, jewelry: OwnedJewelryState(marketValue: 4_000, condition: 90))]
        AssetSystem.applyAssetLossEffect(AssetLossEffect(assetID: 1, action: .recoverPrivately), assets: &state.assets, age: 30)
        #expect(state.assets.movableAssets.first?.jewelry?.condition == 80)
        #expect(state.assets.lossHistory.last?.action == .recoverPrivately)
        AssetSystem.applyAssetLossEffect(AssetLossEffect(assetID: 1, action: .report), assets: &state.assets, age: 31)
        #expect(state.assets.movableAssets.isEmpty)
        #expect(state.assets.movableAssetsLost == 1)
        #expect(state.assets.lossHistory.last?.action == .report)
    }

    @Test func emergencyLiquidationUsesNormalSaleProceeds() {
        var state = neutral()
        state.cash = 20_000
        state.assets.movableAssets = [OwnedAsset(id: 1, listingID: "car-used-compact", category: .cars, name: "Car", purchaseAge: 18, purchasePrice: 10_000, vehicle: OwnedVehicleState(kind: .car, currentValue: 7_000))]
        let simulator = LifeSimulator(state: state, store: LifePersistence(saveURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)))
        let expected = simulator.state.assets.movableAssets[0].resaleValue
        _ = simulator.execute(.domain(.liquidateAssets([1])))
        #expect(simulator.state.assets.movableAssets.isEmpty)
        #expect(simulator.state.cash == state.cash + expected)
        #expect(simulator.state.assets.movableAssetSaleProceeds == expected)
    }

    @Test func notorietyClampsAndPersistsWithAssetSummaries() throws {
        var state = neutral()
        state.assets.notoriety.adjust(140, age: 30)
        state.assets.notoriety.adjust(-200, age: 31)
        #expect(state.assets.notoriety.score == 0)
        state.assets.giftHistory = [AssetGiftRecord(id: 1, age: 30, assetCategory: .jewelry, assetName: "Ring", value: 20_000, recipientID: "partner", recipientName: "Morgan", major: true)]
        let restored = try JSONDecoder().decode(LifeState.self, from: JSONEncoder().encode(state))
        #expect(restored.assets.notoriety == state.assets.notoriety)
        #expect(restored.assets.giftHistory == state.assets.giftHistory)
    }

    @Test func registeredReactionPassIsDeterministicAndBounded() {
        var first = neutral()
        first.partner = PartnerState(name: "Morgan", startedAge: 24, compatibility: 60)
        var second = first
        let disabledBefore = first
        _ = ReactionResolver.run(.action(.workShift, target: nil), enabled: false, state: &first)
        #expect(first == disabledBefore)
        let a = ReactionResolver.run(.action(.workShift, target: nil), state: &first)
        let b = ReactionResolver.run(.action(.workShift, target: nil), state: &second)
        #expect(first.randomStreams.action == disabledBefore.randomStreams.action)
        #expect(a.visibleLines == b.visibleLines)
        #expect(first.npcs.all.map(\.memberID) == second.npcs.all.map(\.memberID))
        #expect(a.evaluatedPeople <= ReactionTuning.maxPeople)
        #expect(a.visibleLines.count <= ReactionTuning.maxVisible)
        #expect(first.npcs.all.filter { $0.connections.contains { $0.kind == .coworker && $0.isCurrent } }.count == 3)
        #expect(first.reactions.recentLineIDs.count <= 12)
    }

    @Test func deferredReactionMaturesAtNextAgeAndPersists() throws {
        var state = neutral()
        state.partner = PartnerState(name: "Morgan", startedAge: 24, compatibility: 60)
        state.reactions.enqueue(DeferredReaction(kind: .partnerAbsence, person: .partner, pressure: 1, createdAge: 30, sourceAction: .workShift, visibleAtCreation: true))
        state.reactions.enqueue(DeferredReaction(kind: .partnerAbsence, person: .partner, pressure: 2, createdAge: 30, sourceAction: .acceptOvertime, visibleAtCreation: true))
        #expect(state.reactions.pending.count == 1)
        #expect(state.reactions.pending[0].pressure == 3)
        let encoded = try JSONEncoder().encode(state)
        let restored = try JSONDecoder().decode(LifeState.self, from: encoded)
        #expect(restored.reactions == state.reactions)
        #expect(ReactionResolver.matureYear(state: &state).isEmpty)
        #expect(state.reactions.pending.count == 1)
        state.character.age = 30
        #expect(ReactionResolver.matureYear(state: &state).isEmpty)
        state.character.age = 31
        let bullets = ReactionResolver.matureYear(state: &state)
        #expect(bullets.count == 1)
        #expect(state.partner!.resentment == 3)
        #expect(state.reactions.pending.isEmpty)
        var capped = ReactionState()
        for index in 0..<20 {
            capped.enqueue(DeferredReaction(kind: .familyDistance, person: .family("contact-\(index)"), pressure: 1, createdAge: 20, sourceAction: .workShift, visibleAtCreation: true))
        }
        #expect(capped.pending.count == ReactionTuning.pendingCap)
    }

    @Test func reactionContentRejectsDuplicateIDsAndUnknownSlots() {
        #expect(ReactionLineContent.templates.count >= 30)
        #expect(ReactionLineContent.validate(ReactionLineContent.templates) == nil)
        let duplicate = ReactionLineTemplate(id: "same", action: .workShift, audience: "coworker", text: "{person} noticed.")
        #expect(ReactionLineContent.validate([duplicate, duplicate]) != nil)
        let invalid = ReactionLineTemplate(id: "invalid", action: .workShift, audience: "coworker", text: "{secret} noticed.")
        #expect(ReactionLineContent.validate([invalid]) != nil)
    }

    @Test func v51SaveLoadsWithEmptyReactionState() throws {
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(neutral())) as? [String: Any])
        object["saveVersion"] = 51
        object.removeValue(forKey: "reactions")
        let data = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder().decode(LifeState.self, from: data)
        #expect(restored.reactions == ReactionState())
    }
}
