import Foundation

enum DomainArtifactDomain: String, Codable, CaseIterable {
    case education
    case career
    case crime
    case finance
    case relationships
    case health
    case housing
    case family
    case assets
    case progress
}

struct WorldCache: Equatable {
    var age: Int
    var ageBand: String
    var isSchoolAge: Bool
    var strongestRelationshipBond: Int
    var strainedRelationshipCount: Int
    var socialConnectionCount: Int
    var publicReputation: Int
    var privateReputation: Int
    var rumorHeat: Int
    var activeRelationshipTensionCount: Int
    var futureAlignmentAverage: Int
    var activeHealthConditionCount: Int
    var dependentChildCount: Int
    var infantCount: Int
    var focusTags: [String]
    var criticalStatuses: [String]
    var situationID: String
}

struct EducationDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var education: EducationState
    var career: CareerState
    var finance: FinanceState
    var relationships: RelationshipState
    var health: HealthState
    var policySupport: Int
}

struct TrajectoryDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var trajectory: TrajectoryState
    var education: EducationState
    var career: CareerState
    var finance: FinanceState
    var relationships: RelationshipState
    var family: FamilyState
    var health: HealthState
    var housing: HousingState
    var originProfile: OriginProfile?
    var childhoodDossier: ChildhoodDossier?
}

struct CareerDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var education: EducationState
    var career: CareerState
    var health: HealthState
    var relationships: RelationshipState
    var childhoodDossier: ChildhoodDossier?
}

struct SpecialCareerDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var career: CareerState
    var specialCareer: SpecialCareerState
    var finance: FinanceState
    var health: HealthState
    var relationships: RelationshipState
    var housing: HousingState
}

struct CrimeDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var career: CareerState
    var crime: CrimeState
    var finance: FinanceState
    var health: HealthState
    var relationships: RelationshipState
    var housing: HousingState
}

struct FinanceDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var finance: FinanceState
    var career: CareerState
    var education: EducationState
    var health: HealthState
    var relationships: RelationshipState
    var family: FamilyState
    var housing: HousingState
    var assets: AssetState
}

struct InvestmentDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var finance: FinanceState
    var career: CareerState
    var assets: AssetState
}

struct RelationshipDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var relationships: RelationshipState
    var family: FamilyState
    var health: HealthState
    var housing: HousingState
    var financialStress: Int
}

struct FamilyDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var relationships: RelationshipState
    var family: FamilyState
    var health: HealthState
    var finance: FinanceState
}

struct HealthDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var career: CareerState
    var relationships: RelationshipState
    var housing: HousingState
    var health: HealthState
    var healthcarePressure: Int
}

struct HousingDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var housing: HousingState
    var finance: FinanceState
    var assets: AssetState
}

struct AssetDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var career: CareerState
    var finance: FinanceState
    var assets: AssetState
    var housing: HousingState
}

struct ProgressDomainSnapshot: Equatable {
    var world: WorldCache
    var state: GameState
}

struct TraitDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var finance: FinanceState
}

struct WorldSnapshot: Equatable {
    var state: GameState
    var cache: WorldCache
    var trajectory: TrajectoryDomainSnapshot
    var education: EducationDomainSnapshot
    var career: CareerDomainSnapshot
    var specialCareer: SpecialCareerDomainSnapshot
    var crime: CrimeDomainSnapshot
    var finance: FinanceDomainSnapshot
    var investment: InvestmentDomainSnapshot
    var relationships: RelationshipDomainSnapshot
    var family: FamilyDomainSnapshot
    var health: HealthDomainSnapshot
    var housing: HousingDomainSnapshot
    var assets: AssetDomainSnapshot
    var progress: ProgressDomainSnapshot
    var traits: TraitDomainSnapshot
}

struct WorldSnapshotBuilder {
    private let policySystem: PolicySystem

    init(policySystem: PolicySystem = PolicySystem()) {
        self.policySystem = policySystem
    }

    func build(from state: GameState) -> WorldSnapshot {
        let strongestBond = max(state.relationships.friends.strongestBond, state.relationships.partnerBond)
        let strainedCount = (state.relationships.friends + state.relationships.romanticPartners)
            .filter { $0.status == .strained }
            .count
        let socialConnectionCount = state.relationships.friends.count + (state.relationships.hasPartner ? 1 : 0)
        let criticalStatuses = resolvedCriticalStatuses(for: state, strongestBond: strongestBond, strainedCount: strainedCount)
        let cache = WorldCache(
            age: state.player.age,
            ageBand: ageBand(for: state.player.age),
            isSchoolAge: state.player.age < 18,
            strongestRelationshipBond: strongestBond,
            strainedRelationshipCount: strainedCount,
            socialConnectionCount: socialConnectionCount,
            publicReputation: state.relationships.publicReputation,
            privateReputation: state.relationships.privateReputation,
            rumorHeat: state.relationships.activeRumorHeat,
            activeRelationshipTensionCount: state.relationships.activeTensionCount,
            futureAlignmentAverage: state.relationships.futureAlignment.averageReadiness,
            activeHealthConditionCount: state.healthProfile.activeConditions.count,
            dependentChildCount: state.family.dependentChildCount,
            infantCount: state.family.infantCount,
            focusTags: state.originProfile?.focusTags ?? [],
            criticalStatuses: criticalStatuses,
            situationID: situationID(for: state, criticalStatuses: criticalStatuses)
        )

        let education = EducationDomainSnapshot(
            world: cache,
            player: state.player,
            education: state.education,
            career: state.career,
            finance: state.finance,
            relationships: state.relationships,
            health: state.healthProfile,
            policySupport: policySystem.educationSupport(for: state.finance)
        )
        let trajectory = TrajectoryDomainSnapshot(
            world: cache,
            player: state.player,
            trajectory: state.trajectory,
            education: state.education,
            career: state.career,
            finance: state.finance,
            relationships: state.relationships,
            family: state.family,
            health: state.healthProfile,
            housing: state.housing,
            originProfile: state.originProfile,
            childhoodDossier: state.childhoodDossier
        )
        let career = CareerDomainSnapshot(
            world: cache,
            player: state.player,
            education: state.education,
            career: state.career,
            health: state.healthProfile,
            relationships: state.relationships,
            childhoodDossier: state.childhoodDossier
        )
        let specialCareer = SpecialCareerDomainSnapshot(
            world: cache,
            player: state.player,
            career: state.career,
            specialCareer: state.specialCareer,
            finance: state.finance,
            health: state.healthProfile,
            relationships: state.relationships,
            housing: state.housing
        )
        let crime = CrimeDomainSnapshot(
            world: cache,
            player: state.player,
            career: state.career,
            crime: state.crime,
            finance: state.finance,
            health: state.healthProfile,
            relationships: state.relationships,
            housing: state.housing
        )
        let finance = FinanceDomainSnapshot(
            world: cache,
            player: state.player,
            finance: state.finance,
            career: state.career,
            education: state.education,
            health: state.healthProfile,
            relationships: state.relationships,
            family: state.family,
            housing: state.housing,
            assets: state.assets
        )
        let investment = InvestmentDomainSnapshot(
            world: cache,
            player: state.player,
            finance: state.finance,
            career: state.career,
            assets: state.assets
        )
        let relationships = RelationshipDomainSnapshot(
            world: cache,
            player: state.player,
            relationships: state.relationships,
            family: state.family,
            health: state.healthProfile,
            housing: state.housing,
            financialStress: state.finance.financialStress
        )
        let family = FamilyDomainSnapshot(
            world: cache,
            player: state.player,
            relationships: state.relationships,
            family: state.family,
            health: state.healthProfile,
            finance: state.finance
        )
        let health = HealthDomainSnapshot(
            world: cache,
            player: state.player,
            career: state.career,
            relationships: state.relationships,
            housing: state.housing,
            health: state.healthProfile,
            healthcarePressure: policySystem.healthcarePressure(for: state.finance)
        )
        let housing = HousingDomainSnapshot(
            world: cache,
            player: state.player,
            housing: state.housing,
            finance: state.finance,
            assets: state.assets
        )
        let assets = AssetDomainSnapshot(
            world: cache,
            player: state.player,
            career: state.career,
            finance: state.finance,
            assets: state.assets,
            housing: state.housing
        )
        let progress = ProgressDomainSnapshot(world: cache, state: state)
        let traits = TraitDomainSnapshot(world: cache, player: state.player, finance: state.finance)

        return WorldSnapshot(
            state: state,
            cache: cache,
            trajectory: trajectory,
            education: education,
            career: career,
            specialCareer: specialCareer,
            crime: crime,
            finance: finance,
            investment: investment,
            relationships: relationships,
            family: family,
            health: health,
            housing: housing,
            assets: assets,
            progress: progress,
            traits: traits
        )
    }

    private func ageBand(for age: Int) -> String {
        switch age {
        case ..<13: return "child"
        case 13...17: return "teen"
        case 18...22: return "young_adult"
        case 23...34: return "adult"
        case 35...54: return "midlife"
        default: return "late_life"
        }
    }

    private func resolvedCriticalStatuses(for state: GameState, strongestBond: Int, strainedCount: Int) -> [String] {
        var statuses: [String] = []
        if state.finance.financialStress >= 45 || state.finance.cashOnHand < 0 {
            statuses.append("finance_pressure")
        }
        if state.healthProfile.mentalWellness < 45 || state.player.health < 50 {
            statuses.append("health_pressure")
        }
        if strainedCount > 0 || strongestBond < 40 {
            statuses.append("relationship_strain")
        }
        if state.relationships.activeRumorHeat >= 55 {
            statuses.append("rumor_pressure")
        }
        if state.relationships.activeTensionCount > 0 {
            statuses.append("loose_ends")
        }
        if state.education.burnoutRisk >= 55 || state.education.attendancePressure >= 55 {
            statuses.append("education_pressure")
        }
        if state.housing.housingStability < 42 || state.housing.livingArrangement == .couchSurfing {
            statuses.append("housing_instability")
        }
        if statuses.isEmpty {
            statuses.append("stable")
        }
        return statuses
    }

    private func situationID(for state: GameState, criticalStatuses: [String]) -> String {
        let lifePath = state.progress.currentLifePath?.rawValue ?? "none"
        let region = state.finance.currentRegionPolicyID ?? "mountain_standard"
        let joined = criticalStatuses.joined(separator: "-")
        let financeBand = bandLabel(for: state.finance.financialStress, thresholds: [25, 45, 65], labels: ["finance_light", "finance_rising", "finance_heavy", "finance_acute"])
        let housingBand = bandLabel(for: max(0, 100 - state.housing.housingStability), thresholds: [20, 40, 60], labels: ["housing_settled", "housing_shaky", "housing_unstable", "housing_crisis"])
        let healthBand = bandLabel(for: max(0, 100 - min(state.healthProfile.mentalWellness, state.healthProfile.physicalWellness)), thresholds: [20, 40, 60], labels: ["health_stable", "health_shaky", "health_strained", "health_critical"])
        return "\(ageBand(for: state.player.age))-\(lifePath)-\(region)-\(joined)-\(financeBand)-\(housingBand)-\(healthBand)"
    }

    private func bandLabel(for value: Int, thresholds: [Int], labels: [String]) -> String {
        guard labels.count == thresholds.count + 1 else {
            return labels.first ?? "band"
        }

        for (index, threshold) in thresholds.enumerated() where value < threshold {
            return labels[index]
        }
        return labels.last ?? "band"
    }
}
