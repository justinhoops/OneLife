import Foundation

struct DomainActionContext: Equatable {
    let state: GameState
    let isTeenExperience: Bool
    let isStudentLifeExperience: Bool
    let canAccessInvesting: Bool
    let investmentEmergencyReserve: Int
}

struct SuggestedPlayerAction: Codable, Equatable {
    var domain: ActionDomain
    var choiceID: ActionChoiceID
    var headline: String
}

struct FinanceActionSection: Identifiable, Equatable {
    let id: String
    let title: String
    let choices: [ActionChoiceID]
}

struct DomainActionRegistry {
    let context: DomainActionContext

    private var state: GameState { context.state }

    // MARK: - Public API

    func availableCommitted(for domain: ActionDomain) -> [ActionChoiceID] {
        switch domain {
        case .education: return educationCommittedChoices()
        case .career: return careerCommittedChoices()
        case .crime: return crimeCommittedChoices()
        case .finance: return financeCommittedChoices()
        case .relationships: return relationshipCommittedChoices()
        case .health: return healthCommittedChoices()
        }
    }

    func availableQuick(for domain: ActionDomain) -> [ActionChoiceID] {
        let committed = Set(availableCommitted(for: domain))
        var quick = baseQuickChoices(for: domain).filter {
            committed.contains($0) || resolutionTier(for: $0, domain: domain) == .instant
        }
        for choice in availableInstantPromotions(for: domain) {
            guard committed.contains(choice) || resolutionTier(for: choice, domain: domain) == .instant else { continue }
            if !quick.contains(choice) { quick.append(choice) }
        }
        if domain == .finance, state.finance.debtPressureBand == .crushing || state.finance.debtPressureBand == .heavy {
            for debtQuick in [ActionChoiceID.minimumPayments, .consolidateDebt, .payDownDebt] where committed.contains(debtQuick) {
                if !quick.contains(debtQuick) { quick.insert(debtQuick, at: 0) }
            }
        }
        return Array(quick.prefix(6))
    }

    func resolutionTier(for choiceID: ActionChoiceID, domain: ActionDomain) -> ActionResolutionTier {
        if contextualInstantChoices(for: domain).contains(choiceID) {
            return .instant
        }
        return ActionChoiceCatalog.baseResolutionTier(for: choiceID)
    }

    func suggestedChoice(for domain: ActionDomain) -> ActionChoiceID? {
        switch domain {
        case .education:
            if state.education.burnoutRisk >= 55 || state.healthProfile.mentalWellness < 45 { return .keepThePeace }
            if state.education.applicationReadiness >= 60 { return .buildPortfolio }
            if state.relationships.friends.isEmpty { return .joinClub }
            return .studyConsistently
        case .career:
            if state.career.status == .unemployed { return .jobHunt }
            if state.career.activeOpportunityDoor == .burnoutExit { return .protectYourEnergy }
            if state.career.activeOpportunityDoor == .credentialPivot { return .retrain }
            if state.career.activeOpportunityDoor == .lateralEscapeRoute { return .jobHunt }
            if state.career.activeOpportunityDoor == .internalPromotionTrack { return .network }
            if state.career.activeOpportunityDoor == .contractWindfall { return .takeOvertime }
            if state.career.burnout >= 68 || state.career.relationshipSpillover >= 58 { return .protectYourEnergy }
            if state.career.performance < 55 { return .workHard }
            if state.career.retrainingProgress == 0 && state.career.profile != .credentialedProfessional && state.career.yearsWorked >= 2 { return .retrain }
            if state.specialCareer.track == .entertainment && state.specialCareer.burnout < 70 { return .chaseSpotlight }
            if state.career.performance >= 74 { return .network }
            return .coast
        case .crime:
            if state.crime.heat >= 65 { return .layLow }
            if state.finance.cashOnHand < 0 { return .cleanMoney }
            return .runScheme
        case .finance:
            if context.isStudentLifeExperience {
                if state.finance.studentDebt > 0 && state.finance.debtPressureBand == .heavy { return .deferStudentLoans }
                return state.finance.financialStress >= 40 ? .cutSpending : .takeExtraShifts
            }
            if state.finance.canUseDebtReset { return .declareBankruptcy }
            if state.finance.debtPressureBand == .crushing { return .consolidateDebt }
            if state.finance.debtPressureBand == .heavy { return .minimumPayments }
            if state.assets.ownsHome && state.assets.primaryResidence?.status == .delinquent { return .refinanceMortgage }
            if state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < 0 { return .cutSpending }
            if context.canAccessInvesting && !state.finance.hasInvestments { return .buyIndexFund }
            if state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 { return .saveForDownPayment }
            return context.canAccessInvesting ? .buildEmergencyFund : .takeSideWork
        case .relationships:
            let strained = (state.relationships.friends + state.relationships.romanticPartners).filter { $0.status == .strained }.count
            if strained > 0 { return .repairTension }
            if context.isTeenExperience && state.relationships.friends.isEmpty && !state.relationships.hasPartner { return .findYourCrowd }
            if state.relationships.hasPartner { return .strengthenBond }
            return .reachOut
        case .health:
            if !state.healthProfile.activeConditions.isEmpty { return context.isStudentLifeExperience ? .rest : .seeDoctor }
            if state.healthProfile.mentalWellness < 45 { return context.isStudentLifeExperience ? .protectSleep : .rest }
            return .rest
        }
    }

    func isCrimeLaneActive() -> Bool {
        state.player.age >= 18 && (
            state.crime.status != .inactive ||
            state.pendingActions.contains(where: { $0.domain == .crime }) ||
            state.finance.cashOnHand < 600 ||
            state.specialCareer.track == .crime
        )
    }

    func financeActionSections() -> [FinanceActionSection] {
        let choices = financeCommittedChoices()
        var cash: [ActionChoiceID] = []
        var debt: [ActionChoiceID] = []
        var invest: [ActionChoiceID] = []
        var home: [ActionChoiceID] = []

        let debtIDs: Set<ActionChoiceID> = [.payDownDebt, .consolidateDebt, .minimumPayments, .deferStudentLoans, .declareBankruptcy]
        let investIDs: Set<ActionChoiceID> = [.buildEmergencyFund, .buyIndexFund, .speculateStocks, .holdPositions, .sellToCover, .dayTrade, .analyzeMarkets]
        let homeIDs: Set<ActionChoiceID> = [.saveForDownPayment, .buyStarterHome, .refinanceMortgage, .buildMaintenanceReserve, .sellHome]

        for choice in choices {
            if debtIDs.contains(choice) { debt.append(choice) }
            else if investIDs.contains(choice) { invest.append(choice) }
            else if homeIDs.contains(choice) { home.append(choice) }
            else { cash.append(choice) }
        }

        var sections: [FinanceActionSection] = []
        if !cash.isEmpty { sections.append(FinanceActionSection(id: "cash", title: "Cash Flow", choices: cash)) }
        if !debt.isEmpty { sections.append(FinanceActionSection(id: "debt", title: "Debt", choices: debt)) }
        if !invest.isEmpty { sections.append(FinanceActionSection(id: "invest", title: "Invest", choices: invest)) }
        if !home.isEmpty { sections.append(FinanceActionSection(id: "home", title: "Home", choices: home)) }
        return sections
    }

    func familyPhaseIsActive() -> Bool {
        state.family.isPregnant || state.family.childCount > 0 || state.family.postpartumYearsRemaining > 0
    }

    func familyPhaseCommittedChoices() -> [ActionChoiceID] {
        guard familyPhaseIsActive() else { return [] }
        var choices: [ActionChoiceID] = [.strengthenBond, .repairTension, .discussFuture]
        if state.family.isPregnant {
            choices.append(contentsOf: [.avoidPregnancy, .tryForBaby])
        }
        if !state.healthProfile.activeConditions.isEmpty {
            choices.append(.seeDoctor)
        }
        let relationshipDeck = Set(availableCommitted(for: .relationships))
        return dedupe(choices.filter { relationshipDeck.contains($0) || $0 == .seeDoctor })
    }

    func familyPhaseQuickChoices() -> [ActionChoiceID] {
        guard familyPhaseIsActive() else { return [] }
        return dedupe([.protectSleep, .rest, .repairTension, .seeDoctor].filter {
            resolutionTier(for: $0, domain: .health) == .instant || resolutionTier(for: $0, domain: .relationships) == .instant
                || availableQuick(for: .health).contains($0) || availableQuick(for: .relationships).contains($0)
        })
    }

    /// NPC / pressure callback surfaced on Home (max one).
    func suggestedCallbackAction() -> SuggestedPlayerAction? {
        if let stored = state.suggestedPlayerAction,
           storedMatchesPlayable(stored) {
            return stored
        }
        return deriveSuggestedCallbackAction()
    }

    static func refreshSuggestedAction(in state: inout GameState, isTeenExperience: Bool) {
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: isTeenExperience,
                isStudentLifeExperience: state.player.age <= 22 && (state.education.pathway == .student || state.education.pathway == .training),
                canAccessInvesting: state.player.age >= 18 && state.finance.isEligibleToCompound(emergencyReserve: max(2_500, state.finance.annualNetIncome / 4)),
                investmentEmergencyReserve: max(2_500, state.finance.annualNetIncome / 4)
            )
        )
        state.suggestedPlayerAction = registry.deriveSuggestedCallbackAction()
    }

    static func quickActionTitle(for choiceID: ActionChoiceID) -> String {
        switch choiceID {
        case .studyConsistently: return "Study"
        case .joinClub: return "Join Club"
        case .buildPortfolio: return "Build Portfolio"
        case .skipClass: return "Skip Class"
        case .lockInRoutine: return "Routine"
        case .workHard: return "Work Hard"
        case .network: return "Network"
        case .jobHunt: return "Job Hunt"
        case .protectYourEnergy: return "Protect Energy"
        case .takeOvertime: return "Overtime"
        case .cutSpending: return "Budget"
        case .takeSideWork: return "Side Work"
        case .payDownDebt: return "Pay Debt"
        case .buildEmergencyFund: return "Emergency Fund"
        case .spendForRelief: return "Spend For Relief"
        case .reachOut: return "Reach Out"
        case .findYourCrowd: return "Find Friends"
        case .dateCarefully: return "Date"
        case .strengthenBond: return "Strengthen Bond"
        case .repairTension: return "Repair"
        case .rest: return "Rest"
        case .protectSleep: return "Sleep"
        case .pushThrough: return "Push Through"
        case .seeDoctor: return "Doctor"
        case .layLow: return "Lay Low"
        case .stepAway: return "Step Away"
        case .cleanMoney: return "Clean Money"
        case .analyzeMarkets: return "Markets"
        case .holdPositions: return "Hold"
        case .minimumPayments: return "Min Pay"
        case .consolidateDebt: return "Consolidate"
        case .stayInvisible: return "Lay Low Social"
        case .chaseStatus: return "Chase Status"
        default: return ActionChoiceCatalog.definition(for: choiceID).title
        }
    }

    // MARK: - Instant tier

    private func contextualInstantChoices(for domain: ActionDomain) -> Set<ActionChoiceID> {
        var instant = Set<ActionChoiceID>()
        for choice in ActionChoiceID.allCases where ActionChoiceCatalog.baseResolutionTier(for: choice) == .instant {
            instant.insert(choice)
        }
        instant.formUnion(availableInstantPromotions(for: domain))
        return instant
    }

    private func availableInstantPromotions(for domain: ActionDomain) -> [ActionChoiceID] {
        switch domain {
        case .education:
            var choices: [ActionChoiceID] = [.studyConsistently, .joinClub, .lockInRoutine]
            if state.education.attendancePressure >= 50 || state.education.burnoutRisk >= 45 {
                choices.append(.layLow)
            }
            return choices
        case .career:
            var choices: [ActionChoiceID] = [.protectYourEnergy, .network]
            if state.career.status == .unemployed { choices.insert(.jobHunt, at: 0) }
            return choices
        case .finance:
            var choices: [ActionChoiceID] = [.cutSpending, .takeSideWork, .spendForRelief]
            if investmentsActive { choices.append(contentsOf: [.analyzeMarkets, .holdPositions]) }
            return choices
        case .relationships:
            var choices: [ActionChoiceID] = [.reachOut, .repairTension, .keepDistance]
            if context.isTeenExperience { choices.append(contentsOf: [.stayInvisible, .chaseStatus]) }
            return choices
        case .health:
            var choices: [ActionChoiceID] = [.rest, .protectSleep, .seeDoctor]
            if state.career.burnout >= 58 || state.education.burnoutRisk >= 50 {
                choices.insert(.protectSleep, at: 0)
            }
            return choices
        case .crime:
            var choices: [ActionChoiceID] = [.layLow, .cleanMoney]
            if state.crime.heat >= 50 { choices.insert(.stepAway, at: 0) }
            return choices
        }
    }

    private var investmentsActive: Bool {
        state.player.age >= 18 && (
            state.finance.hasInvestments ||
            (state.finance.lastYearBalanceDelta >= 0 && state.finance.cashOnHand >= 6_000)
        )
    }

    // MARK: - Quick catalog

    private func baseQuickChoices(for domain: ActionDomain) -> [ActionChoiceID] {
        switch domain {
        case .education:
            return state.education.stage == .inactive ? [] : [.studyConsistently, .joinClub, .buildPortfolio, .skipClass, .lockInRoutine]
        case .career:
            guard state.player.age >= 16 else { return [] }
            return [.workHard, .network, .jobHunt, .protectYourEnergy, .takeOvertime]
        case .finance:
            var choices: [ActionChoiceID] = [.cutSpending, .takeSideWork, .buildEmergencyFund, .spendForRelief]
            if state.finance.totalNonHousingDebt > 0 { choices.insert(.payDownDebt, at: 2) }
            return choices
        case .relationships:
            if state.relationships.hasPartner {
                return [.reachOut, .strengthenBond, .repairTension, .dateCarefully]
            }
            return [.reachOut, .findYourCrowd, .dateCarefully, .repairTension]
        case .health:
            return [.rest, .protectSleep, .pushThrough, .seeDoctor]
        case .crime:
            guard isCrimeLaneActive() else { return [] }
            return [.layLow, .stepAway, .cleanMoney, .runScheme]
        }
    }

    // MARK: - Committed decks

    private func educationCommittedChoices() -> [ActionChoiceID] {
        if context.isTeenExperience {
            return [.studyConsistently, .cramAndSurvive, .joinClub, .buildPortfolio, .skipAndDrift, .keepThePeace]
        }
        if context.isStudentLifeExperience {
            return [.studyConsistently, .cramAndSurvive, .buildPortfolio, .keepThePeace, .skipAndDrift, .lockInRoutine]
        }
        return [.studyHard, .layLow, .skipClass]
    }

    private func careerCommittedChoices() -> [ActionChoiceID] {
        if state.player.age < 16 { return [] }

        if state.specialCareer.track == .founder {
            var founder: [ActionChoiceID] = [.pivotBusiness, .raiseCapital, .aggressiveExpansion, .protectYourEnergy, .network]
            if state.specialCareer.audience >= 75 { founder.append(.ipoExit) }
            if SpecialCareerSystem.qualificationIssue(for: .startCompany, state: state) == nil {
                founder.insert(.startCompany, at: 0)
            }
            return founder
        }
        if state.specialCareer.track == .entertainment {
            return [.chaseSpotlight, .compete, .intenseTraining, .protectYourEnergy, .network, .coast]
        }
        if state.specialCareer.track == .crime {
            return [.runScheme, .layLow, .buildCrew, .cleanMoney, .stepAway]
        }

        var options: [ActionChoiceID] = []
        if state.player.age >= 18 {
            options = [.workHard, .protectYourEnergy, .network, .retrain, .takeOvertime, .coast, .jobHunt, .chaseSpotlight]
            if SpecialCareerSystem.qualificationIssue(for: .startCompany, state: state) == nil {
                options.append(.startCompany)
            }
            if SpecialCareerSystem.qualificationIssue(for: .manageFund, state: state) == nil {
                options.append(.manageFund)
            }
            if SpecialCareerSystem.qualificationIssue(for: .acquireCompetitor, state: state) == nil {
                options.append(.acquireCompetitor)
            }
            options.append(contentsOf: [.intenseTraining, .compete])
            if SpecialCareerSystem.qualificationIssue(for: .gatherIntelligence, state: state) == nil {
                options.append(contentsOf: [.gatherIntelligence, .exploitLeverage])
            }
        } else {
            options = [.workHard, .coast, .jobHunt]
        }
        return options
    }

    private func crimeCommittedChoices() -> [ActionChoiceID] {
        guard isCrimeLaneActive() else { return [] }
        return [.runScheme, .layLow, .buildCrew, .cleanMoney, .stepAway]
    }

    private func financeCommittedChoices() -> [ActionChoiceID] {
        if context.isStudentLifeExperience {
            var studentOptions: [ActionChoiceID] = [.takeExtraShifts, .saveForEscape, .cutSpending, .spendToCope]
            if state.finance.studentDebt > 0 { studentOptions.append(.deferStudentLoans) }
            return studentOptions
        }
        var financeOptions: [ActionChoiceID] = []
        if (14...15).contains(state.player.age) {
            financeOptions = [.smallHustle, .cutSpending, .spendForRelief]
        } else if state.player.age >= 18 {
            financeOptions = [.cutSpending, .spendForRelief, .takeSideWork]
            if state.finance.totalNonHousingDebt > 0 {
                financeOptions.append(contentsOf: [.payDownDebt, .consolidateDebt, .minimumPayments])
                if state.finance.studentDebt > 0 { financeOptions.append(.deferStudentLoans) }
                if state.finance.canUseDebtReset { financeOptions.append(.declareBankruptcy) }
            }
            if state.finance.cashOnHand >= 2_000 {
                financeOptions.append(contentsOf: [.dayTrade, .analyzeMarkets])
            }
        }

        if state.assets.ownsHome {
            financeOptions.append(contentsOf: [.buildMaintenanceReserve, .refinanceMortgage, .sellHome])
        }

        if state.player.age >= 18 && state.career.status == .fullTime {
            let canBuyStarterHome =
                state.career.yearsWorked >= 2 &&
                state.finance.lastYearBalanceDelta >= 0 &&
                state.finance.homeDownPaymentSavings + state.finance.cashOnHand >= 35_000 &&
                state.finance.debtPressureBand != .heavy &&
                state.finance.debtPressureBand != .crushing &&
                state.finance.recentDebtReliefYears == 0
            if canBuyStarterHome || state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 {
                financeOptions.append(contentsOf: canBuyStarterHome
                    ? [.saveForDownPayment, .buyStarterHome, .buyIndexFund]
                    : [.saveForDownPayment, .cutSpending, .takeSideWork])
            }
        }

        if context.canAccessInvesting {
            let isUnderPressure = state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < context.investmentEmergencyReserve
            if isUnderPressure, state.finance.hasInvestments {
                financeOptions.append(contentsOf: [.buildEmergencyFund, .holdPositions, .sellToCover])
            } else if state.finance.hasInvestments {
                financeOptions.append(contentsOf: [.buyIndexFund, .speculateStocks, .holdPositions])
            } else {
                financeOptions.append(contentsOf: [.buildEmergencyFund, .buyIndexFund, .speculateStocks])
            }
        }
        return Array(Set(financeOptions))
    }

    private func relationshipCommittedChoices() -> [ActionChoiceID] {
        if context.isTeenExperience {
            return [.findYourCrowd, .dateCarefully, .chaseStatus, .stayInvisible, .leanOnMentor]
        }
        if state.relationships.hasPartner {
            var actions: [ActionChoiceID] = [.strengthenBond, .discussFuture]
            if !state.relationships.hasCohabitingPartner { actions.append(.moveInTogether) }
            actions.append(contentsOf: [.tryForBaby, .avoidPregnancy, .letChanceDecide, .repairTension])
            if state.player.age >= 18 { actions.append(.callInFavor) }
            return actions
        }
        var options: [ActionChoiceID] = [.reachOut, .keepDistance, .repairTension]
        if state.player.age >= 18 { options.append(.callInFavor) }
        return options
    }

    private func healthCommittedChoices() -> [ActionChoiceID] {
        context.isStudentLifeExperience ? [.protectSleep, .pushThrough, .rest, .seeDoctor] : [.rest, .pushThrough, .seeDoctor]
    }

    // MARK: - Suggested callback

    private func deriveSuggestedCallbackAction() -> SuggestedPlayerAction? {
        if let strainedFriend = state.relationships.friends.first(where: { $0.status == .strained }) {
            return SuggestedPlayerAction(
                domain: .relationships,
                choiceID: .repairTension,
                headline: "Repair things with \(strainedFriend.name)"
            )
        }
        if state.relationships.hasPartner, state.relationships.partnerBond < 50, let partner = state.relationships.romanticPartner {
            return SuggestedPlayerAction(
                domain: .relationships,
                choiceID: .strengthenBond,
                headline: "Invest in \(partner.name)"
            )
        }
        if state.consequences.narrativeFlags["npc_autonomy_pulse", default: 0] > 0,
           let friend = state.relationships.friends.first {
            return SuggestedPlayerAction(
                domain: .relationships,
                choiceID: .reachOut,
                headline: "Check in with \(friend.name)"
            )
        }
        let topPressure = state.consequences.pressureByDomain.max(by: { $0.value < $1.value })
        if let topPressure, topPressure.value >= 28, let domain = ActionDomain(rawValue: topPressure.key),
           let choice = suggestedChoice(for: domain) {
            return SuggestedPlayerAction(
                domain: domain,
                choiceID: choice,
                headline: "Respond to \(topPressure.key) pressure"
            )
        }
        return nil
    }

    private func storedMatchesPlayable(_ suggested: SuggestedPlayerAction) -> Bool {
        availableCommitted(for: suggested.domain).contains(suggested.choiceID)
            || availableQuick(for: suggested.domain).contains(suggested.choiceID)
            || resolutionTier(for: suggested.choiceID, domain: suggested.domain) == .instant
    }

    private func dedupe(_ choices: [ActionChoiceID]) -> [ActionChoiceID] {
        var seen: Set<ActionChoiceID> = []
        return choices.filter { seen.insert($0).inserted }
    }
}

extension GameViewModel {
    func makeActionRegistry() -> DomainActionRegistry {
        DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: isTeenExperience,
                isStudentLifeExperience: isStudentLifeExperience,
                canAccessInvesting: canAccessInvesting,
                investmentEmergencyReserve: investmentEmergencyReserve
            )
        )
    }
}
