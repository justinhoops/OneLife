import Foundation

enum DebugScenarioID: String, CaseIterable, Identifiable {
    case teenEducationPressure
    case adultCareerFlow
    case specialCareerEntertainment
    case specialCareerCrime
    case partnerCohabitationFlow
    case pregnancyYoungFamily
    case healthCrisis
    case housingDeficitFlow
    case universityTrack
    case tradeTrack
    case adultEdRebuild
    case eventPreview
    case yearSummaryPreview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .teenEducationPressure: return "Teen Education Pressure"
        case .adultCareerFlow: return "Adult Career Flow"
        case .specialCareerEntertainment: return "Entertainment Track"
        case .specialCareerCrime: return "Crime Track"
        case .partnerCohabitationFlow: return "Partner / Move-In Flow"
        case .pregnancyYoungFamily: return "Pregnancy / Young Family"
        case .healthCrisis: return "Health Crisis"
        case .housingDeficitFlow: return "Housing Deficit"
        case .universityTrack: return "University State"
        case .tradeTrack: return "Trade Training State"
        case .adultEdRebuild: return "Adult-Ed Rebuild"
        case .eventPreview: return "Event Sheet Preview"
        case .yearSummaryPreview: return "Year Summary Preview"
        }
    }

    var summary: String {
        switch self {
        case .teenEducationPressure:
            return "Struggling school-year pressure with thin cash, burnout risk, and teen-only actions."
        case .adultCareerFlow:
            return "Stable adult work state with full-time career actions and visible upward momentum."
        case .specialCareerEntertainment:
            return "Entertainment path with fame, audience, payout, and spotlight pressure visible."
        case .specialCareerCrime:
            return "Crime path with heat, notoriety, unstable cash, and risky-career pressure."
        case .partnerCohabitationFlow:
            return "Committed adult partner state that exposes relationship planning and move-in choices."
        case .pregnancyYoungFamily:
            return "Young family state with pregnancy, child load, and cross-domain pressure."
        case .healthCrisis:
            return "Adult health breakdown with active conditions and doctor-oriented recovery choices."
        case .housingDeficitFlow:
            return "Negative-cash unstable housing setup with deficit finance pressure."
        case .universityTrack:
            return "University-specific education state with scholarship/debt pressure for testing."
        case .tradeTrack:
            return "Trade-training education state with practical-lane messaging and actions."
        case .adultEdRebuild:
            return "Adult-ed recovery route with slower momentum and rebuild framing."
        case .eventPreview:
            return "Launch directly into an event sheet without waiting for random event selection."
        case .yearSummaryPreview:
            return "Launch directly into a year summary sheet without progressing a turn."
        }
    }
}

enum DebugScenarioModal: String, Equatable {
    case none
    case event
    case yearSummary
}

struct DebugScenarioPayload: Equatable {
    var state: GameState
    var event: GameEvent? = nil
    var yearSummary: YearlyOutcomeSummary? = nil
}

struct DebugTestingConfiguration: Equatable {
    var scenarioID: DebugScenarioID? = nil
    var modal: DebugScenarioModal = .none

    static var inactive: DebugTestingConfiguration { DebugTestingConfiguration() }

    static func fromProcessInfo() -> DebugTestingConfiguration {
        let arguments = ProcessInfo.processInfo.arguments
        guard let scenarioFlagIndex = arguments.firstIndex(of: "-debug-scenario"),
              arguments.indices.contains(scenarioFlagIndex + 1),
              let scenarioID = DebugScenarioID(rawValue: arguments[scenarioFlagIndex + 1]) else {
            return .inactive
        }

        var modal: DebugScenarioModal = .none
        if let modalIndex = arguments.firstIndex(of: "-debug-modal"),
           arguments.indices.contains(modalIndex + 1),
           let parsedModal = DebugScenarioModal(rawValue: arguments[modalIndex + 1]) {
            modal = parsedModal
        }

        return DebugTestingConfiguration(scenarioID: scenarioID, modal: modal)
    }
}

struct DebugTestingCoordinator {
    func payload(for scenarioID: DebugScenarioID) -> DebugScenarioPayload {
        switch scenarioID {
        case .teenEducationPressure:
            return teenEducationPressure()
        case .adultCareerFlow:
            return adultCareerFlow()
        case .specialCareerEntertainment:
            return entertainmentTrack()
        case .specialCareerCrime:
            return crimeTrack()
        case .partnerCohabitationFlow:
            return partnerFlow()
        case .pregnancyYoungFamily:
            return pregnancyFlow()
        case .healthCrisis:
            return healthCrisis()
        case .housingDeficitFlow:
            return housingDeficit()
        case .universityTrack:
            return universityTrack()
        case .tradeTrack:
            return tradeTrack()
        case .adultEdRebuild:
            return adultEdRebuild()
        case .eventPreview:
            return eventPreview()
        case .yearSummaryPreview:
            return yearSummaryPreview()
        }
    }

    private func teenEducationPressure() -> DebugScenarioPayload {
        var state = baseState(name: "Maya", age: 16)
        state.player.traits = [.anxious, .disciplined, .charismatic]
        state.education.pathway = .student
        state.education.stage = .secondary
        state.education.academicTrack = .struggling
        state.education.schoolStanding = 39
        state.education.engagement = 35
        state.education.attendancePressure = 67
        state.education.schoolBelonging = 28
        state.education.reputationRisk = 61
        state.education.teacherSupport = 26
        state.education.applicationReadiness = 33
        state.education.burnoutRisk = 72
        state.education.mentorSupport = 29
        state.education.peerPressure = 63
        state.finance.cashOnHand = 42
        state.finance.financialStress = 51
        state.finance.annualEducationCost = 400
        state.finance.lastYearBalanceDelta = -320
        state.relationships.friends = [
            Relationship(name: "Tia", type: .friend, status: .strained, bond: 31, yearsKnown: 2, stage: .dating, isCohabiting: false, commitmentAlignment: 0)
        ]
        state.healthProfile.mentalWellness = 38
        state.healthProfile.habits.stressManagement = 32
        state.housing.housingStability = 41
        state.pendingActions = [
            PlayerYearAction(domain: .education, choiceID: .studyConsistently),
            PlayerYearAction(domain: .finance, choiceID: .takeExtraShifts),
            PlayerYearAction(domain: .relationships, choiceID: .findYourCrowd)
        ]
        state.history = [
            HistoryEntry(age: 16, title: "Education", text: "School pressure started to spill into sleep and your social life.", tags: [.education, .health, .relationships]),
            HistoryEntry(age: 15, title: "Finance", text: "Money got tighter at home, and your margin for mistakes disappeared.", tags: [.finance, .housing]),
            HistoryEntry(age: 15, title: "Relationships", text: "You drifted from your safest friend when life got loud.", tags: [.relationships])
        ]
        state.progress.currentLifePath = .survivor
        return finalized(state)
    }

    private func adultCareerFlow() -> DebugScenarioPayload {
        var state = baseState(name: "Andre", age: 24)
        state.player.traits = [.disciplined, .lucky, .charismatic]
        state.career.status = .fullTime
        state.career.roleID = "operations_coordinator"
        state.career.level = 4
        state.career.annualIncome = 36_000
        state.career.performance = 78
        state.career.yearsWorked = 4
        state.finance.cashOnHand = 12_400
        state.finance.annualGrossIncome = 36_000
        state.finance.annualNetIncome = 29_400
        state.finance.annualTotalExpenses = 20_800
        state.finance.lastYearBalanceDelta = 8_600
        state.finance.financialStress = 24
        state.finance.currentRegionPolicyID = "mountain_standard"
        state.relationships.friends = [
            Relationship(name: "Noah", type: .friend, status: .active, bond: 72, yearsKnown: 5, stage: .dating, isCohabiting: false, commitmentAlignment: 0)
        ]
        state.housing.livingArrangement = .roommates
        state.housing.hasRoommate = true
        state.housing.housingStability = 73
        state.progress.currentLifePath = .striver
        state.progress.unlockedMilestones = [
            MilestoneUnlock(id: .firstJob, unlockedAtAge: 18)
        ]
        state.pendingActions = [
            PlayerYearAction(domain: .career, choiceID: .workHard),
            PlayerYearAction(domain: .finance, choiceID: .takeSideWork)
        ]
        state.history = [
            HistoryEntry(age: 24, title: "Career", text: "You held onto work momentum and started looking promotable.", tags: [.career, .progress]),
            HistoryEntry(age: 23, title: "Finance", text: "For the first time, work income created real breathing room.", tags: [.finance]),
            HistoryEntry(age: 22, title: "Milestone", text: "Steady adult work finally became part of your identity.", tags: [.progress, .career])
        ]
        return finalized(state)
    }

    private func entertainmentTrack() -> DebugScenarioPayload {
        var state = baseState(name: "Lena", age: 22)
        state.player.traits = [.charismatic, .impulsive, .lucky]
        state.career.status = .partTime
        state.career.roleID = "shop_clerk"
        state.career.level = 2
        state.career.annualIncome = 4_200
        state.career.performance = 63
        state.specialCareer.track = .entertainment
        state.specialCareer.tier = 2
        state.specialCareer.fame = 68
        state.specialCareer.audience = 74
        state.specialCareer.burnout = 61
        state.specialCareer.yearsActive = 3
        state.specialCareer.lastPayout = 5_200
        state.finance.cashOnHand = 5_600
        state.finance.lastYearBalanceDelta = 2_400
        state.finance.financialStress = 29
        state.relationships.friends = [
            Relationship(name: "Jules", type: .friend, status: .active, bond: 67, yearsKnown: 4, stage: .dating, isCohabiting: false, commitmentAlignment: 0)
        ]
        state.healthProfile.mentalWellness = 47
        state.healthProfile.habits.stressManagement = 41
        state.progress.currentLifePath = .connector
        state.pendingActions = [
            PlayerYearAction(domain: .career, choiceID: .chaseSpotlight),
            PlayerYearAction(domain: .health, choiceID: .rest)
        ]
        state.history = [
            HistoryEntry(age: 22, title: "Career", text: "Attention finally turned into money, but the pace felt unstable.", tags: [.career, .finance]),
            HistoryEntry(age: 21, title: "Health", text: "Your sleep started paying the price for being visible all the time.", tags: [.health, .career])
        ]
        return finalized(state)
    }

    private func crimeTrack() -> DebugScenarioPayload {
        var state = baseState(name: "Dante", age: 23)
        state.player.traits = [.impulsive, .charismatic, .anxious]
        state.career.status = .unemployed
        state.career.performance = 44
        state.crime.status = .active
        state.crime.roleTier = 2
        state.crime.heat = 73
        state.crime.notoriety = 69
        state.crime.burnout = 64
        state.crime.yearsActive = 2
        state.crime.lastPayout = 6_400
        state.crime.loyalty = 58
        state.crime.territoryPressure = 61
        state.finance.cashOnHand = 9_200
        state.finance.lastYearBalanceDelta = 3_600
        state.finance.financialStress = 42
        state.housing.livingArrangement = .roommates
        state.housing.housingStability = 46
        state.healthProfile.mentalWellness = 36
        state.healthProfile.habits.stressManagement = 28
        state.progress.currentLifePath = .survivor
        state.pendingActions = [
            PlayerYearAction(domain: .crime, choiceID: .runScheme),
            PlayerYearAction(domain: .finance, choiceID: .spendForRelief)
        ]
        state.history = [
            HistoryEntry(age: 23, title: "Crime", text: "The fast money helped, but it also made your life harder to stabilize.", tags: [.crime, .finance, .health]),
            HistoryEntry(age: 22, title: "Relationships", text: "People got more cautious around you once the risk stopped feeling abstract.", tags: [.relationships, .crime])
        ]
        return finalized(state)
    }

    private func partnerFlow() -> DebugScenarioPayload {
        var state = baseState(name: "Renee", age: 27)
        state.player.traits = [.disciplined, .charismatic, .anxious]
        state.career.status = .fullTime
        state.career.roleID = "team_lead"
        state.career.level = 5
        state.career.annualIncome = 51_000
        state.career.performance = 73
        state.finance.cashOnHand = 14_800
        state.finance.annualNetIncome = 39_000
        state.finance.annualTotalExpenses = 24_500
        state.finance.lastYearBalanceDelta = 5_200
        state.relationships.romanticPartner = Relationship(name: "Micah", type: .romantic, status: .active, bond: 82, yearsKnown: 4, stage: .committed, isCohabiting: false, commitmentAlignment: 74)
        state.relationships.friends = [
            Relationship(name: "Sofia", type: .friend, status: .active, bond: 64, yearsKnown: 7, stage: .dating, isCohabiting: false, commitmentAlignment: 0)
        ]
        state.family.pregnancyIntent = .chance
        state.housing.livingArrangement = .soloRenting
        state.housing.housingStability = 69
        state.progress.currentLifePath = .connector
        state.pendingActions = [
            PlayerYearAction(domain: .relationships, choiceID: .moveInTogether),
            PlayerYearAction(domain: .finance, choiceID: .cutSpending)
        ]
        state.history = [
            HistoryEntry(age: 27, title: "Relationships", text: "Commitment feels real now, and practical next steps are on the table.", tags: [.relationships, .lifeEvent]),
            HistoryEntry(age: 26, title: "Finance", text: "Your budget can support a shared next step, but only if you stay disciplined.", tags: [.finance, .relationships])
        ]
        return finalized(state)
    }

    private func pregnancyFlow() -> DebugScenarioPayload {
        var state = baseState(name: "Tess", age: 29)
        state.player.traits = [.disciplined, .anxious, .charismatic]
        state.career.status = .fullTime
        state.career.roleID = "operations_coordinator"
        state.career.level = 4
        state.career.annualIncome = 36_000
        state.career.performance = 69
        state.finance.cashOnHand = 4_300
        state.finance.annualNetIncome = 29_400
        state.finance.annualDependentCost = 2_400
        state.finance.annualTotalExpenses = 31_700
        state.finance.lastYearBalanceDelta = -1_500
        state.finance.financialStress = 56
        state.relationships.romanticPartner = Relationship(name: "Owen", type: .romantic, status: .active, bond: 77, yearsKnown: 5, stage: .married, isCohabiting: true, commitmentAlignment: 80)
        state.family.children = [
            ChildRecord(name: "Ivy", age: 1, livesAtHome: true, otherParentName: "Owen", supportLoad: 64)
        ]
        state.family.pregnancy = PregnancyState(phase: .thirdTrimester, otherParentName: "Owen", isPlanned: true, isHighRisk: false, yearsActive: 1)
        state.family.pregnancyIntent = .trying
        state.healthProfile.physicalWellness = 51
        state.healthProfile.mentalWellness = 43
        state.healthProfile.habits.stressManagement = 35
        state.housing.livingArrangement = .roommates
        state.housing.hasRoommate = true
        state.housing.housingStability = 58
        state.progress.currentLifePath = .provider
        state.pendingActions = [
            PlayerYearAction(domain: .relationships, choiceID: .repairTension),
            PlayerYearAction(domain: .health, choiceID: .rest)
        ]
        state.history = [
            HistoryEntry(age: 29, title: "Birth", text: "Family pressure is no longer theoretical. It is money, health, and relationship strain all at once.", tags: [.lifeEvent, .finance, .health, .relationships]),
            HistoryEntry(age: 28, title: "Finance", text: "Child-related costs started shrinking your margin quickly.", tags: [.finance, .lifeEvent])
        ]
        return finalized(state)
    }

    private func healthCrisis() -> DebugScenarioPayload {
        var state = baseState(name: "Caleb", age: 31)
        state.player.traits = [.anxious, .disciplined, .lucky]
        state.player.health = 34
        state.career.status = .fullTime
        state.career.roleID = "operations_coordinator"
        state.career.level = 4
        state.career.annualIncome = 36_000
        state.career.performance = 58
        state.finance.cashOnHand = 1_150
        state.finance.annualNetIncome = 29_400
        state.finance.annualTotalExpenses = 28_900
        state.finance.financialStress = 49
        state.finance.lastYearBalanceDelta = -650
        state.healthProfile.physicalWellness = 32
        state.healthProfile.mentalWellness = 29
        state.healthProfile.habits.exercise = 21
        state.healthProfile.habits.nutrition = 37
        state.healthProfile.habits.stressManagement = 18
        state.healthProfile.activeConditions = [
            HealthCondition(name: "Hypertension", severity: 68),
            HealthCondition(name: "Exhaustion", severity: 74)
        ]
        state.healthProfile.hasPrimaryCare = false
        state.housing.livingArrangement = .soloRenting
        state.housing.housingStability = 49
        state.progress.currentLifePath = .survivor
        state.pendingActions = [
            PlayerYearAction(domain: .health, choiceID: .seeDoctor),
            PlayerYearAction(domain: .career, choiceID: .coast)
        ]
        state.history = [
            HistoryEntry(age: 31, title: "Health", text: "Your body started forcing decisions that stress had delayed for too long.", tags: [.health, .career]),
            HistoryEntry(age: 30, title: "Finance", text: "Skipping care saved cash briefly, but it did not save stability.", tags: [.finance, .health])
        ]
        return finalized(state)
    }

    private func housingDeficit() -> DebugScenarioPayload {
        var state = baseState(name: "Nia", age: 26)
        state.player.traits = [.anxious, .impulsive, .charismatic]
        state.career.status = .unemployed
        state.career.performance = 33
        state.finance.cashOnHand = -620
        state.finance.annualNetIncome = 0
        state.finance.annualTotalExpenses = 12_800
        state.finance.financialStress = 73
        state.finance.consecutiveDeficitYears = 2
        state.finance.lastYearBalanceDelta = -4_800
        state.finance.currentRegionPolicyID = "expensive_coastal"
        state.housing.livingArrangement = .couchSurfing
        state.housing.housingCostBand = 61
        state.housing.housingStability = 22
        state.relationships.friends = [
            Relationship(name: "Kay", type: .friend, status: .strained, bond: 36, yearsKnown: 4, stage: .dating, isCohabiting: false, commitmentAlignment: 0)
        ]
        state.healthProfile.mentalWellness = 34
        state.healthProfile.habits.stressManagement = 24
        state.progress.currentLifePath = .survivor
        state.pendingActions = [
            PlayerYearAction(domain: .finance, choiceID: .cutSpending),
            PlayerYearAction(domain: .career, choiceID: .jobHunt)
        ]
        state.history = [
            HistoryEntry(age: 26, title: "Housing", text: "Your living situation stopped feeling temporary and started feeling unstable.", tags: [.housing, .finance, .health]),
            HistoryEntry(age: 25, title: "Finance", text: "Two straight bad years turned money pressure into a life problem.", tags: [.finance, .progress])
        ]
        return finalized(state)
    }

    private func universityTrack() -> DebugScenarioPayload {
        var state = baseState(name: "Priya", age: 19)
        state.player.traits = [.disciplined, .anxious, .lucky]
        state.education.pathway = .graduate
        state.education.stage = .university
        state.education.academicTrack = .honors
        state.education.schoolStanding = 76
        state.education.applicationReadiness = 88
        state.education.campusFit = 58
        state.education.schoolBelonging = 44
        state.education.burnoutRisk = 57
        state.education.hasScholarship = true
        state.education.studyFocus = .technology
        state.education.yearsInStage = 1
        state.finance.cashOnHand = 860
        state.finance.studentDebt = 5_200
        state.finance.annualEducationCost = 7_800
        state.finance.annualNetIncome = 3_200
        state.finance.annualTotalExpenses = 9_600
        state.finance.financialStress = 46
        state.housing.livingArrangement = .roommates
        state.housing.hasRoommate = true
        state.housing.housingStability = 62
        state.progress.currentLifePath = .scholar
        state.pendingActions = [
            PlayerYearAction(domain: .education, choiceID: .buildPortfolio),
            PlayerYearAction(domain: .health, choiceID: .protectSleep)
        ]
        state.history = [
            HistoryEntry(age: 19, title: "Education", text: "University opened doors, but the pressure got more adult immediately.", tags: [.education, .finance, .progress])
        ]
        return finalized(state)
    }

    private func tradeTrack() -> DebugScenarioPayload {
        var state = baseState(name: "Marco", age: 20)
        state.player.traits = [.disciplined, .charismatic, .lucky]
        state.education.pathway = .training
        state.education.stage = .tradeTraining
        state.education.academicTrack = .vocational
        state.education.schoolStanding = 68
        state.education.applicationReadiness = 59
        state.education.campusFit = 63
        state.education.burnoutRisk = 34
        state.education.studyFocus = .trades
        state.education.credentials = ["OSHA Fundamentals"]
        state.education.yearsInStage = 1
        state.finance.cashOnHand = 1_950
        state.finance.annualEducationCost = 1_600
        state.finance.annualNetIncome = 8_400
        state.finance.annualTotalExpenses = 6_200
        state.finance.financialStress = 27
        state.housing.livingArrangement = .roommates
        state.housing.housingStability = 66
        state.progress.currentLifePath = .provider
        state.pendingActions = [
            PlayerYearAction(domain: .education, choiceID: .studyConsistently),
            PlayerYearAction(domain: .finance, choiceID: .takeSideWork)
        ]
        state.history = [
            HistoryEntry(age: 20, title: "Education", text: "Trade training started paying off faster than prestige routes, but the schedule is still demanding.", tags: [.education, .career])
        ]
        return finalized(state)
    }

    private func adultEdRebuild() -> DebugScenarioPayload {
        var state = baseState(name: "Jasmine", age: 22)
        state.player.traits = [.anxious, .disciplined, .charismatic]
        state.education.pathway = .dropout
        state.education.stage = .adultEd
        state.education.academicTrack = .general
        state.education.schoolStanding = 51
        state.education.engagement = 48
        state.education.applicationReadiness = 41
        state.education.campusFit = 46
        state.education.burnoutRisk = 43
        state.education.teacherSupport = 58
        state.education.mentorSupport = 61
        state.finance.cashOnHand = 320
        state.finance.annualNetIncome = 10_400
        state.finance.annualEducationCost = 2_100
        state.finance.annualTotalExpenses = 11_700
        state.finance.financialStress = 39
        state.housing.livingArrangement = .familyHome
        state.housing.housingStability = 54
        state.progress.currentLifePath = .survivor
        state.pendingActions = [
            PlayerYearAction(domain: .education, choiceID: .keepThePeace),
            PlayerYearAction(domain: .finance, choiceID: .saveForEscape)
        ]
        state.history = [
            HistoryEntry(age: 22, title: "Education", text: "You found a slower route back into structure, but it still feels fragile.", tags: [.education, .progress])
        ]
        return finalized(state)
    }

    private func eventPreview() -> DebugScenarioPayload {
        var payload = adultCareerFlow()
        payload.event = GameEvent(
            id: "debug_event_preview",
            category: .career,
            tags: ["career", "money"],
            title: "A recruiter reached out",
            text: "A mid-sized company noticed your work and offered a risky interview loop with real upside but no guarantee.",
            minAge: 18,
            maxAge: 65,
            weight: 1,
            cooldownYears: 0,
            requirements: [],
            choices: [
                EventChoice(
                    text: "Take the interview",
                    effects: ChoiceEffects(
                        core: CoreStatEffects(happiness: 2, smarts: 1, looks: nil, health: nil),
                        career: CareerEffects(performance: 4, yearsWorked: nil, setStatus: .fullTime, setRoleID: nil, incomeBonus: 2_000, promote: nil, loseJob: nil),
                        finance: FinanceEffects(cashDelta: 300, studentDebtDelta: nil, livingCostDelta: nil, educationCostDelta: nil, dependentCostDelta: nil, discretionaryCostDelta: nil, financialStressDelta: -2, setRegionPolicyID: nil)
                    )
                ),
                EventChoice(
                    text: "Stay where you are",
                    effects: ChoiceEffects(
                        core: CoreStatEffects(happiness: -1, smarts: nil, looks: nil, health: nil),
                        finance: FinanceEffects(cashDelta: nil, studentDebtDelta: nil, livingCostDelta: nil, educationCostDelta: nil, dependentCostDelta: nil, discretionaryCostDelta: nil, financialStressDelta: 1, setRegionPolicyID: nil)
                    )
                )
            ]
        )
        return payload
    }

    private func yearSummaryPreview() -> DebugScenarioPayload {
        var payload = housingDeficit()
        payload.yearSummary = YearlyOutcomeSummary(
            age: payload.state.player.age,
            headlines: [
                YearlyOutcomeItem(title: "Cash Flow", detail: "You finished the year with another serious deficit.", domain: .finance, tone: .warning, impactScore: -16),
                YearlyOutcomeItem(title: "Housing", detail: "Couch surfing turned home into a source of instability.", domain: .housing, tone: .warning, impactScore: -14),
                YearlyOutcomeItem(title: "Job Search", detail: "You created a small opening, but not enough to stabilize the year.", domain: .career, tone: .neutral, impactScore: 4)
            ],
            topProblem: YearlyOutcomeItem(title: "Top Problem", detail: "Money pressure is now driving housing and mental strain together.", domain: .finance, tone: .warning, impactScore: -20),
            topOpportunity: YearlyOutcomeItem(title: "Top Opportunity", detail: "A steady job would relieve multiple domains at once.", domain: .career, tone: .positive, impactScore: 9),
            momentum: YearlyOutcomeItem(title: "Momentum", detail: "The pattern is still negative, but not fully locked in.", domain: .progress, tone: .neutral, impactScore: 2),
            spillovers: [
                YearlyOutcomeItem(title: "Health Spillover", detail: "Stress dragged recovery down and made daily life harder to hold together.", domain: .health, tone: .warning, impactScore: -9),
                YearlyOutcomeItem(title: "Relationship Spillover", detail: "Instability started fraying one of your closest friendships.", domain: .relationships, tone: .warning, impactScore: -7)
            ],
            checkpoint: YearlyOutcomeItem(title: "Age Checkpoint", detail: "This year clarified that survival pressure is becoming your dominant life pattern.", domain: .progress, tone: .warning, impactScore: -10)
        )
        return payload
    }

    private func baseState(name: String, age: Int) -> GameState {
        var state = GameState()
        state.player.name = name
        state.player.age = age
        state.player.happiness = 55
        state.player.smarts = 58
        state.player.looks = 53
        state.player.health = 62
        state.startupState = .active
        if age >= 18 {
            state.education.stage = .inactive
            state.education.pathway = .graduate
        }
        state.originProfile = OriginProfile(
            startMode: .template,
            templateID: .stableHomeAverageMeans,
            householdPressure: "Mixed but manageable",
            schoolStanding: "Enough structure to matter",
            socialSupport: "Some warmth, not much margin",
            starterTraitBias: [],
            startingCashBand: "Thin",
            focusTags: ["debug", "testing"],
            openingEventSeed: [],
            homeSummary: "This is a seeded QA life for deterministic testing.",
            schoolSummary: "The visible UI should match production, but this state is intentionally staged.",
            selfSummary: "Traits and pressure are set to expose a specific feature band.",
            signalHighlights: ["QA Scenario", "Deterministic", "Debug Only"]
        )
        state.openingSummary = "This life was loaded from a debug-only QA scenario so hidden feature bands are reachable immediately."
        return state
    }

    private func finalized(_ state: GameState) -> DebugScenarioPayload {
        var finalState = state
        finalState.player.clampStats()
        finalState.education.clamp()
        finalState.healthProfile.clamp()
        finalState.housing.clamp()
        finalState.specialCareer.clamp()
        finalState.crime.clamp()
        return DebugScenarioPayload(state: finalState)
    }
}
