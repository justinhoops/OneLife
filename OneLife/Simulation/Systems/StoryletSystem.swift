import Foundation

struct StoryletSystem {
    func preferredTagWeights(for world: WorldSnapshot) -> [String: Int] {
        let state = world.state
        var weights: [String: Int] = [:]
        let relationships = state.relationships

        add(state.originProfile?.focusTags ?? [], weight: 4, to: &weights)
        add(state.originProfile?.openingEventSeed ?? [], weight: 3, to: &weights)
        for candidate in state.narrativeArcs.activeCandidates {
            for (tag, weight) in candidate.seed.influence.eventTagWeights {
                weights[tag, default: 0] += weight
            }
        }

        if state.education.pathway == .student && state.education.attendancePressure >= 48 {
            add(["school", "routine"], weight: 9, to: &weights)
        }

        if state.player.age <= 17 && state.education.activityMomentum >= 52 {
            add(["school", "social", "chance"], weight: 5, to: &weights)
        }

        switch state.trajectory.direction {
        case .rising:
            add(["career", "chance", "growth"], weight: 6, to: &weights)
        case .stable:
            add(["routine", "career"], weight: 2, to: &weights)
        case .fragile:
            add(["cost", "health", "routine"], weight: 6, to: &weights)
        case .sliding:
            add(["risk", "cost", "health"], weight: 8, to: &weights)
        }

        switch state.trajectory.lifePhase {
        case .adolescence:
            add(["school", "social"], weight: 4, to: &weights)
        case .launch:
            add(["career", "money", "housing"], weight: 5, to: &weights)
        case .earlyCareer:
            add(["career", "chance", "routine"], weight: 4, to: &weights)
        case .familyBuilder:
            add(["family", "housing", "cost"], weight: 5, to: &weights)
        case .midlife:
            add(["career", "health", "family"], weight: 4, to: &weights)
        case .laterLife:
            add(["health", "family", "legacy"], weight: 4, to: &weights)
        }

        if state.trajectory.socialCapital >= 65 {
            add(["social", "career", "chance"], weight: 5, to: &weights)
        } else if state.trajectory.socialCapital <= 38 {
            add(["social", "routine"], weight: 4, to: &weights)
        }

        if state.trajectory.socioeconomicPressure >= 62 {
            add(["money", "cost", "housing"], weight: 8, to: &weights)
        }

        if state.trajectory.opportunityVisibility >= 62 {
            add(["career", "chance"], weight: 6, to: &weights)
        } else if state.trajectory.opportunityVisibility <= 38 {
            add(["routine", "money"], weight: 4, to: &weights)
        }

        if state.career.status == .unemployed || state.career.performance < 40 {
            add(["career", "money"], weight: 8, to: &weights)
        } else if state.career.performance >= 75 {
            add(["career", "chance"], weight: 5, to: &weights)
        }

        if state.career.burnout >= 58 || state.career.schedulePressure >= 55 {
            add(["career", "health", "routine"], weight: 7, to: &weights)
        }
        if state.career.relationshipSpillover >= 52 {
            add(["social", "romance", "career"], weight: 6, to: &weights)
        }
        if state.career.jobSecurity <= 45 {
            add(["career", "money", "risk"], weight: 7, to: &weights)
        }
        if state.career.managerFriction >= 55 {
            add(["career", "social", "routine"], weight: 7, to: &weights)
        }
        if state.career.scheduleControl <= 38 {
            add(["career", "relationships", "health"], weight: 7, to: &weights)
        }

        switch state.career.profile {
        case .stableAdmin:
            add(["career", "routine"], weight: 3, to: &weights)
        case .physicalLabor:
            add(["career", "health", "money"], weight: 4, to: &weights)
        case .serviceFrontline:
            add(["career", "social", "routine"], weight: 4, to: &weights)
        case .creativeFreelance:
            add(["career", "chance", "risk"], weight: 5, to: &weights)
        case .credentialedProfessional:
            add(["career", "money", "school"], weight: 4, to: &weights)
        case .militaryService:
            add(["career", "military", "routine"], weight: 5, to: &weights)
        case .medicalProfessional:
            add(["career", "health", "school"], weight: 6, to: &weights)
        case .legalProfessional:
            add(["career", "social", "school"], weight: 5, to: &weights)
        case .techSpecialist:
            add(["career", "technology", "money"], weight: 5, to: &weights)
        case .financialExpert:
            add(["career", "money", "risk"], weight: 5, to: &weights)
        }

        switch state.career.workIdentity {
        case .climber:
            add(["career", "chance"], weight: 6, to: &weights)
        case .caretaker:
            add(["health", "relationships", "routine"], weight: 5, to: &weights)
        case .drifter:
            add(["career", "money", "risk"], weight: 5, to: &weights)
        case .hustler:
            add(["money", "career", "risk"], weight: 6, to: &weights)
        case .burnedOutProvider:
            add(["money", "health", "relationships"], weight: 8, to: &weights)
        case .unsettled:
            break
        }

        switch state.career.activeOpportunityDoor {
        case .internalPromotionTrack:
            add(["career", "chance", "social"], weight: 8, to: &weights)
        case .lateralEscapeRoute:
            add(["career", "money", "routine"], weight: 7, to: &weights)
        case .credentialPivot:
            add(["career", "school", "money"], weight: 8, to: &weights)
        case .contractWindfall:
            add(["career", "money", "risk"], weight: 8, to: &weights)
        case .unionStability:
            add(["career", "money", "health"], weight: 7, to: &weights)
        case .burnoutExit:
            add(["career", "health", "relationships"], weight: 9, to: &weights)
        case .none:
            break
        }

        if state.finance.financialStress >= 42 || state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < 0 {
            add(["money", "cost", "routine"], weight: 10, to: &weights)
        } else if state.finance.lastYearBalanceDelta > 4_000 {
            add(["chance", "money"], weight: 4, to: &weights)
        }

        if state.player.health < 50 || state.healthProfile.mentalWellness < 45 || !state.healthProfile.activeConditions.isEmpty {
            add(["health", "routine"], weight: 10, to: &weights)
        }

        let strainedCount = (state.relationships.friends + state.relationships.romanticPartners)
            .filter { $0.status == .strained }
            .count
        if strainedCount > 0 || (state.relationships.friends.isEmpty && !state.relationships.hasPartner) {
            add(["social", "romance"], weight: 7, to: &weights)
        }

        if relationships.activeRumorHeat >= 45 {
            add(["social", "romance", "career", "risk"], weight: 8, to: &weights)
        }
        if relationships.activeTensionCount > 0 {
            add(["relationships", "social", "routine"], weight: 7, to: &weights)
        }
        if relationships.futureAlignment.averageReadiness <= 42 && relationships.hasPartner {
            add(["family", "housing", "money", "romance"], weight: 8, to: &weights)
        } else if relationships.futureAlignment.averageReadiness >= 66 && relationships.hasPartner {
            add(["romance", "family", "chance"], weight: 5, to: &weights)
        }
        if relationships.publicReputation >= 65 {
            add(["social", "career", "chance"], weight: 4, to: &weights)
        } else if relationships.publicReputation <= 40 {
            add(["social", "risk", "health"], weight: 5, to: &weights)
        }

        if state.family.isPregnant || state.family.childCount > 0 {
            add(["family", "romance", "cost"], weight: 8, to: &weights)
        }

        if let lifePath = state.progress.currentLifePath {
            switch lifePath {
            case .scholar:
                add(["school", "career", "routine"], weight: 5, to: &weights)
            case .striver:
                add(["career", "money"], weight: 5, to: &weights)
            case .provider:
                add(["money", "cost", "routine"], weight: 5, to: &weights)
            case .connector:
                add(["social", "romance"], weight: 6, to: &weights)
            case .survivor:
                add(["health", "money", "routine"], weight: 6, to: &weights)
            }
        }

        for trait in state.player.traits {
            switch trait {
            case .disciplined:
                add(["routine", "school", "career"], weight: 3, to: &weights)
            case .impulsive:
                add(["risk", "spend", "social"], weight: 4, to: &weights)
            case .charismatic:
                add(["social", "romance", "career"], weight: 3, to: &weights)
            case .anxious:
                add(["health", "school"], weight: 3, to: &weights)
            case .lucky:
                add(["chance", "money"], weight: 3, to: &weights)
            case .manipulative:
                add(["social", "risk", "career"], weight: 4, to: &weights)
            case .coldBlooded:
                add(["risk", "money", "career"], weight: 4, to: &weights)
            case .visionary:
                add(["career", "chance", "money"], weight: 4, to: &weights)
            case .burnoutProne:
                add(["health", "routine"], weight: 8, to: &weights)
            case .workaholic:
                add(["career", "money"], weight: 10, to: &weights)
                add(["social", "romance"], weight: -6, to: &weights)
            case .resilient:
                add(["risk", "health"], weight: 5, to: &weights)
            case .unreliable:
                add(["routine"], weight: -10, to: &weights)
                add(["social", "chance"], weight: 5, to: &weights)
            case .ptsd:
                add(["health", "risk"], weight: 12, to: &weights)
            }
        }

        return weights
    }

    func preferredTagWeights(for state: GameState) -> [String: Int] {
        preferredTagWeights(for: WorldSnapshotBuilder().build(from: state))
    }

    private func add(_ tags: [String], weight: Int, to weights: inout [String: Int]) {
        for tag in tags {
            weights[tag, default: 0] += weight
        }
    }
}
