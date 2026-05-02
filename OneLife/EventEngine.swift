import Foundation

final class EventEngine {
    private(set) var allEvents: [GameEvent] = []
    private let traitSystem = TraitSystem()
    private var hasLoggedEventPackWarning = false

    init(events: [GameEvent]? = nil) {
        if let events {
            allEvents = events
        } else {
            loadEventsFromBundle()
        }
    }

    private func loadEventsFromBundle() {
        guard let url = Bundle.main.url(forResource: "SampleEvents", withExtension: "json") else {
            assertionFailure("Missing SampleEvents.json in bundle")
            allEvents = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let pack = try JSONDecoder().decode(EventPack.self, from: data)
            allEvents = pack.events
        } catch {
            assertionFailure("Failed to load events: \(error)")
            allEvents = []
        }
    }

    func pickEvent(for state: GameState, preferredTags: [String] = []) -> GameEvent? {
        let preferredTagWeights = preferredTags.reduce(into: [String: Int]()) { partial, tag in
            partial[tag, default: 0] += 5
        }
        return pickEvent(for: state, preferredTagWeights: preferredTagWeights)
    }

    func event(withID id: String) -> GameEvent? {
        allEvents.first(where: { $0.id == id })
    }

    func registerDynamicEvent(_ event: GameEvent) {
        if !allEvents.contains(where: { $0.id == event.id }) {
            allEvents.append(event)
        }
    }

    func pickEvent(for state: GameState, preferredTagWeights: [String: Int]) -> GameEvent? {
        warnIfEventPackIsLarge()
        let age = state.player.age

        let eligible = allEvents.filter { event in
            guard age >= event.minAge && age <= event.maxAge else { return false }
            guard requirementsMet(event.requirements, state: state) else { return false }

            if let lastYear = state.lastEventYearById[event.id], (age - lastYear) < event.cooldownYears {
                return false
            }

            if event.triggerOnce, state.lastEventYearById[event.id] != nil {
                return false
            }

            return event.weight > 0
        }

        guard !eligible.isEmpty else { return nil }
        return weightedPick(eligible, for: state, preferredTagWeights: preferredTagWeights)
    }

    private func requirementsMet(_ requirements: [String], state: GameState) -> Bool {
        for raw in requirements {
            let requirement = raw.replacingOccurrences(of: " ", with: "")
            guard let (key, op, rhs) = splitRequirement(requirement) else { return false }

            if key.hasPrefix("consequence.flag.") {
                guard let lhs = boolValue(for: key, state: state), let rhsBool = Bool(rhs.lowercased()) else { return false }
                if !compareBool(lhs: lhs, op: op, rhs: rhsBool) { return false }
                continue
            }

            if key.hasPrefix("consequence.pressure.") {
                guard let lhs = numericValue(for: key, state: state), let rhsInt = Int(rhs) else { return false }
                if !compareInt(lhs: lhs, op: op, rhs: rhsInt) { return false }
                continue
            }

            switch key {
            case "name", "career.role", "career.profile", "career.identity", "career.openDoor", "education.pathway", "education.stage", "education.academicTrack", "education.studyFocus", "finance.region", "progress.lifePath", "specialCareer.track", "crime.status":
                guard let lhs = stringValue(for: key, state: state) else { return false }
                if !compareString(lhs: lhs, op: op, rhs: rhs) { return false }

            case "trait":
                if !compareTraits(state.player.traits, op: op, rhs: rhs) { return false }

            case "career.status", "relationship.partnerStatus", "relationships.partnerStage", "family.pregnancyIntent", "event.category":
                guard let lhs = stringValue(for: key, state: state) else { return false }
                if !compareString(lhs: lhs, op: op, rhs: rhs) { return false }

            case "relationships.hasPartner", "relationships.hasSpouse", "relationships.cohabiting", "family.isPregnant", "health.hasPrimaryCare", "assets.ownsHome":
                guard let lhs = boolValue(for: key, state: state), let rhsBool = Bool(rhs.lowercased()) else { return false }
                if !compareBool(lhs: lhs, op: op, rhs: rhsBool) { return false }

            default:
                guard let lhs = numericValue(for: key, state: state), let rhsInt = Int(rhs) else { return false }
                if !compareInt(lhs: lhs, op: op, rhs: rhsInt) { return false }
            }
        }

        return true
    }

    private func splitRequirement(_ requirement: String) -> (String, String, String)? {
        let operators = ["==", "!=", ">=", "<=", ">", "<"]
        for op in operators {
            if let range = requirement.range(of: op) {
                let key = String(requirement[..<range.lowerBound])
                let rhs = String(requirement[range.upperBound...])
                return (key, op, rhs)
            }
        }
        return nil
    }

    private func numericValue(for key: String, state: GameState) -> Int? {
        if key.hasPrefix("consequence.pressure.") {
            let domain = String(key.dropFirst("consequence.pressure.".count))
            return state.consequences.pressureByDomain[domain] ?? 0
        }
        switch key {
        case "age": return state.player.age
        case "happiness": return state.player.happiness
        case "smarts": return state.player.smarts
        case "looks": return state.player.looks
        case "health": return state.player.health
        case "money": return state.finance.cashOnHand
        case "career.performance": return state.career.performance
        case "career.income": return state.career.annualIncome
        case "career.yearsWorked": return state.career.yearsWorked
        case "career.burnout": return state.career.burnout
        case "career.schedulePressure": return state.career.schedulePressure
        case "career.relationshipSpillover": return state.career.relationshipSpillover
        case "career.jobSecurity": return state.career.jobSecurity
        case "career.managerFriction": return state.career.managerFriction
        case "career.scheduleControl": return state.career.scheduleControl
        case "career.retrainingProgress": return state.career.retrainingProgress
        case "career.doorYearsRemaining": return state.career.opportunityDoorYearsRemaining
        case "specialCareer.tier": return state.specialCareer.tier
        case "specialCareer.fame": return state.specialCareer.fame
        case "specialCareer.audience": return state.specialCareer.audience
        case "specialCareer.burnout": return state.specialCareer.burnout
        case "specialCareer.yearsActive": return state.specialCareer.yearsActive
        case "specialCareer.lastPayout": return state.specialCareer.lastPayout
        case "crime.roleTier": return state.crime.roleTier
        case "crime.heat": return state.crime.heat
        case "crime.notoriety": return state.crime.notoriety
        case "crime.burnout": return state.crime.burnout
        case "crime.yearsActive": return state.crime.yearsActive
        case "crime.lastPayout": return state.crime.lastPayout
        case "crime.loyalty": return state.crime.loyalty
        case "education.schoolStanding": return state.education.schoolStanding
        case "education.engagement": return state.education.engagement
        case "education.attendancePressure": return state.education.attendancePressure
        case "education.activityMomentum": return state.education.activityMomentum
        case "education.schoolBelonging": return state.education.schoolBelonging
        case "education.reputationRisk": return state.education.reputationRisk
        case "education.teacherSupport": return state.education.teacherSupport
        case "education.applicationReadiness": return state.education.applicationReadiness
        case "education.campusFit": return state.education.campusFit
        case "education.burnoutRisk": return state.education.burnoutRisk
        case "education.disciplineRecord": return state.education.disciplineRecord
        case "education.mentorSupport": return state.education.mentorSupport
        case "education.peerPressure": return state.education.peerPressure
        case "finance.cashOnHand": return state.finance.cashOnHand
        case "finance.studentDebt": return state.finance.studentDebt
        case "finance.annualGrossIncome": return state.finance.annualGrossIncome
        case "finance.annualTotalExpenses": return state.finance.annualTotalExpenses
        case "finance.financialStress": return state.finance.financialStress
        case "finance.lastYearBalanceDelta": return state.finance.lastYearBalanceDelta
        case "relationships.friendCount": return state.relationships.friends.count
        case "relationships.partnerCount": return state.relationships.hasPartner ? 1 : 0
        case "relationships.strainedCount":
            return (state.relationships.friends + state.relationships.romanticPartners)
                .filter { $0.status == .strained }
                .count
        case "relationships.bestFriendBond": return state.relationships.friends.strongestBond
        case "relationships.partnerBond": return state.relationships.partnerBond
        case "family.childCount": return state.family.childCount
        case "family.infantCount": return state.family.infantCount
        case "family.postpartumYearsRemaining": return state.family.postpartumYearsRemaining
        case "health.physicalWellness": return state.healthProfile.physicalWellness
        case "health.mentalWellness": return state.healthProfile.mentalWellness
        case "health.conditionCount": return state.healthProfile.activeConditions.count
        case "health.exercise": return state.healthProfile.habits.exercise
        case "health.nutrition": return state.healthProfile.habits.nutrition
        case "health.stressManagement": return state.healthProfile.habits.stressManagement
        case "housing.stability": return state.housing.housingStability
        default: return nil
        }
    }

    private func boolValue(for key: String, state: GameState) -> Bool? {
        if key.hasPrefix("consequence.flag.") {
            let flag = String(key.dropFirst("consequence.flag.".count))
            return state.consequences.narrativeFlags[flag] != nil
        }
        switch key {
        case "relationships.hasPartner":
            return state.relationships.hasPartner
        case "relationships.hasSpouse":
            return state.relationships.hasSpouse
        case "relationships.cohabiting":
            return state.relationships.hasCohabitingPartner
        case "family.isPregnant":
            return state.family.isPregnant
        case "health.hasPrimaryCare":
            return state.healthProfile.hasPrimaryCare
        case "assets.ownsHome":
            return state.assets.ownsHome
        default:
            return nil
        }
    }

    private func stringValue(for key: String, state: GameState) -> String? {
        switch key {
        case "name":
            return state.player.name
        case "career.role":
            return CareerCatalog.definition(for: state.career.roleID)?.title
        case "career.status":
            return state.career.status.rawValue
        case "career.profile":
            return state.career.profile.rawValue
        case "career.identity":
            return state.career.workIdentity.rawValue
        case "career.openDoor":
            return state.career.activeOpportunityDoor?.rawValue ?? "none"
        case "education.pathway":
            return state.education.pathway.rawValue
        case "education.stage":
            return state.education.stage.rawValue
        case "education.academicTrack":
            return state.education.academicTrack.rawValue
        case "education.studyFocus":
            return state.education.studyFocus?.rawValue ?? "none"
        case "finance.region":
            return state.finance.currentRegionPolicyID ?? "mountain_standard"
        case "progress.lifePath":
            return state.progress.currentLifePath?.rawValue ?? "none"
        case "specialCareer.track":
            return state.specialCareer.track.rawValue
        case "crime.status":
            return state.crime.status.rawValue
        case "relationship.partnerStatus":
            return state.relationships.partnerStatus?.rawValue ?? "none"
        case "relationships.partnerStage":
            return state.relationships.partnerStage?.rawValue ?? "none"
        case "family.pregnancyIntent":
            return state.family.pregnancyIntent.rawValue
        case "event.category":
            return "general"
        default:
            return nil
        }
    }

    private func compareInt(lhs: Int, op: String, rhs: Int) -> Bool {
        switch op {
        case "==": return lhs == rhs
        case "!=": return lhs != rhs
        case ">=": return lhs >= rhs
        case "<=": return lhs <= rhs
        case ">": return lhs > rhs
        case "<": return lhs < rhs
        default: return false
        }
    }

    private func compareBool(lhs: Bool, op: String, rhs: Bool) -> Bool {
        switch op {
        case "==": return lhs == rhs
        case "!=": return lhs != rhs
        default: return false
        }
    }

    private func compareString(lhs: String, op: String, rhs: String) -> Bool {
        switch op {
        case "==": return lhs == rhs
        case "!=": return lhs != rhs
        default: return false
        }
    }

    private func compareTraits(_ traits: [PersonalityTrait], op: String, rhs: String) -> Bool {
        guard let targetTrait = PersonalityTrait(rawValue: rhs) else { return false }
        switch op {
        case "==":
            return traits.contains(targetTrait)
        case "!=":
            return !traits.contains(targetTrait)
        default:
            return false
        }
    }

    private func weightedPick(_ events: [GameEvent], for state: GameState, preferredTagWeights: [String: Int]) -> GameEvent {
        let weightedEvents = events.map { event in
            let traitWeight = traitSystem.adjustedWeight(for: event, player: state.player)
            let focusBonus = event.tags.reduce(0) { partial, tag in
                partial + (preferredTagWeights[tag] ?? 0)
            }
            let stabilityAdjustment = stabilityWeightAdjustment(for: event, state: state)
            return (event, max(1, traitWeight + focusBonus + stabilityAdjustment))
        }
        let total = weightedEvents.reduce(0) { $0 + max(0, $1.1) }
        guard total > 0 else { return events[0] }

        var roll = Int.random(in: 1...total)
        for (event, adjustedWeight) in weightedEvents {
            roll -= max(0, adjustedWeight)
            if roll <= 0 { return event }
        }
        return events[0]
    }

    private func stabilityWeightAdjustment(for event: GameEvent, state: GameState) -> Int {
        let pressureScore =
            max(0, state.finance.financialStress - 40) +
            max(0, state.career.burnout - 45) +
            max(0, 50 - state.healthProfile.mentalWellness) +
            (state.relationships.activeTensionCount * 6) +
            ((state.consequences.pressureByDomain.values.max() ?? 0) / 2)
        let eventTags = Set(event.tags)

        if !eventTags.isDisjoint(with: ["risk", "chance"]) {
            if pressureScore < 20 { return -10 }
            if pressureScore < 40 { return -5 }
            if pressureScore >= 70 { return 4 }
        }

        if !eventTags.isDisjoint(with: ["routine", "school", "career", "money", "health", "social"]) && pressureScore < 35 {
            return 3
        }

        return 0
    }

    private func warnIfEventPackIsLarge() {
        #if DEBUG
        guard !hasLoggedEventPackWarning else { return }
        guard allEvents.count > PerformanceBudgets.eventPackWarningThreshold else { return }
        hasLoggedEventPackWarning = true
        print("OneLife performance warning: event pack contains \(allEvents.count) events. Consider indexing before growing further.")
        #endif
    }
}
