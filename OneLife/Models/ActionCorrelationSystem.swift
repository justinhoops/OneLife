import Foundation

struct ActionCorrelationSystem {
    func record(action: PlayerYearAction, age: Int, pressureDeltas: [String: Int], state: inout GameState) {
        let count = state.correlationLedger.recordAction(action)
        let label = pressureCauseLabel(for: action.choiceID)

        for (domain, delta) in pressureDeltas {
            state.correlationLedger.adjustResidue(domain: domain, delta: delta)
            state.correlationLedger.recordPressureCause(
                domain: domain,
                label: label,
                delta: delta,
                age: age,
                sourceAction: action.choiceID
            )
        }

        recordPatternHook(for: action, count: count, age: age, state: &state)
        recordNPCImpressions(for: action, state: &state)
    }

    private func recordPatternHook(for action: PlayerYearAction, count: Int, age: Int, state: inout GameState) {
        guard count >= 2 else { return }

        switch action.choiceID {
        case .takeExtraShifts, .takeSideWork, .takeOvertime, .smallHustle:
            state.correlationLedger.upsertHook(tag: "overwork", domain: "health", dueAge: age + 1, strength: min(20, count * 4), sourceAction: action.choiceID)
        case .rest, .protectSleep, .seeDoctor:
            state.correlationLedger.upsertHook(tag: "recovery", domain: "health", dueAge: age + 1, strength: min(20, count * 4), sourceAction: action.choiceID)
        case .spendForRelief, .spendToCope:
            state.correlationLedger.upsertHook(tag: "coping_spend", domain: "finance", dueAge: age + 1, strength: min(20, count * 4), sourceAction: action.choiceID)
        case .reachOut, .joinClub, .findYourCrowd, .repairTension, .strengthenBond:
            state.correlationLedger.upsertHook(tag: "reachable", domain: "relationships", dueAge: age + 1, strength: min(20, count * 4), sourceAction: action.choiceID)
        case .keepDistance, .stayInvisible, .layLow, .coast:
            state.correlationLedger.upsertHook(tag: "withdrawal", domain: "relationships", dueAge: age + 1, strength: min(20, count * 4), sourceAction: action.choiceID)
        default:
            break
        }
    }

    private func recordNPCImpressions(for action: PlayerYearAction, state: inout GameState) {
        let impressions = npcImpressionDeltas(for: action.choiceID)
        guard !impressions.isEmpty else { return }

        var ids: [String] = state.relationships.friends.map { $0.id.uuidString }
        if let partner = state.relationships.primaryPartner {
            ids.append(partner.id.uuidString)
        }

        for id in ids {
            for (key, delta) in impressions {
                state.correlationLedger.adjustNPCImpression(id: id, key: key, delta: delta)
            }
        }
    }

    private func npcImpressionDeltas(for choiceID: ActionChoiceID) -> [String: Int] {
        switch choiceID {
        case .reachOut, .joinClub, .findYourCrowd, .repairTension, .strengthenBond:
            return ["reachable": 2, "absent": -1]
        case .keepDistance, .stayInvisible, .layLow, .coast:
            return ["absent": 2]
        case .takeExtraShifts, .takeSideWork, .takeOvertime, .workHard:
            return ["overworked": 2]
        case .protectYourEnergy, .rest, .protectSleep:
            return ["available": 1, "overworked": -1]
        default:
            return [:]
        }
    }

    private func pressureCauseLabel(for choiceID: ActionChoiceID) -> String {
        switch choiceID {
        case .protectSleep: return "Sleep"
        case .rest: return "Rest"
        case .seeDoctor: return "Care"
        case .takeExtraShifts: return "Extra shifts"
        case .takeSideWork: return "Side work"
        case .smallHustle: return "Small hustle"
        case .takeOvertime: return "Overtime"
        case .cutSpending: return "Cut spending"
        case .buildEmergencyFund: return "Emergency fund"
        case .spendForRelief: return "Relief spend"
        case .spendToCope: return "Coping spend"
        case .pushThrough: return "Push through"
        case .repairTension: return "Repair"
        case .strengthenBond: return "Bond"
        case .discussFuture: return "Future talk"
        case .keepDistance: return "Distance"
        case .stayInvisible: return "Invisible"
        case .workHard: return "Work hard"
        case .network: return "Network"
        case .retrain: return "Retrain"
        case .protectYourEnergy: return "Protect energy"
        case .coast: return "Coast"
        case .layLow: return "Lay low"
        case .jobHunt: return "Job hunt"
        default: return ActionChoiceCatalog.definition(for: choiceID).title
        }
    }
}

