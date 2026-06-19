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

    init(
        age: Int = 0,
        ageBand: String = "unknown",
        isSchoolAge: Bool = false,
        strongestRelationshipBond: Int = 0,
        strainedRelationshipCount: Int = 0,
        socialConnectionCount: Int = 0,
        publicReputation: Int = 50,
        privateReputation: Int = 50,
        rumorHeat: Int = 0,
        activeRelationshipTensionCount: Int = 0,
        futureAlignmentAverage: Int = 50,
        activeHealthConditionCount: Int = 0,
        dependentChildCount: Int = 0,
        infantCount: Int = 0,
        focusTags: [String] = [],
        criticalStatuses: [String] = [],
        situationID: String = "default"
    ) {
        self.age = age
        self.ageBand = ageBand
        self.isSchoolAge = isSchoolAge
        self.strongestRelationshipBond = strongestRelationshipBond
        self.strainedRelationshipCount = strainedRelationshipCount
        self.socialConnectionCount = socialConnectionCount
        self.publicReputation = publicReputation
        self.privateReputation = privateReputation
        self.rumorHeat = rumorHeat
        self.activeRelationshipTensionCount = activeRelationshipTensionCount
        self.futureAlignmentAverage = futureAlignmentAverage
        self.activeHealthConditionCount = activeHealthConditionCount
        self.dependentChildCount = dependentChildCount
        self.infantCount = infantCount
        self.focusTags = focusTags
        self.criticalStatuses = criticalStatuses
        self.situationID = situationID
    }
}

struct EducationDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var education: EducationState
    var military: MilitaryState
    var career: CareerState
    var finance: FinanceState
    var relationships: RelationshipState
    var health: HealthState
    var policySupport: Int
    var childhoodDossier: ChildhoodDossier?
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
    var recentStances: [YearlyStanceID] = []
    var resilience: LifeResilience = .resilient
    var reentryFrictionYears: Int = 0
    var custodyProgramCompleted: Bool = false
    var recordPressure: Int = 0
    var prisonResidueTags: [String] = []
}

struct LegalDomainSnapshot: Equatable {
    var player: Player
    var legal: LegalState
    var recentStances: [YearlyStanceID] = []
    var resilience: LifeResilience = .resilient
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
    var worldEra: WorldEra
    var childhoodDossier: ChildhoodDossier?
    var recentStances: [YearlyStanceID] = []
    var resilience: LifeResilience = .resilient
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
    var activeTier: CrimeTier? = nil
    var recentStances: [YearlyStanceID] = []
    var resilience: LifeResilience = .resilient
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
    var worldEra: WorldEra
    var economy: EconomyState
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
    var worldEra: WorldEra
    var parentRegularArchetype: CareerArchetype? = nil
    var parentCareerBurnout: Int = 0
    var parentCrimeTier: CrimeTier? = nil
    var parentCrimeHeat: Int = 0
    var parentInCustody: Bool = false
    var parentCustodyFacility: CustodyFacility? = nil
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
    var reentryFrictionYears: Int = 0
    var recordPressure: Int = 0
}

struct AssetDomainSnapshot: Equatable {
    var world: WorldCache
    var player: Player
    var military: MilitaryState
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
    var educationPolicySupport: Int
    var healthcarePressure: Int

    var trajectory: TrajectoryDomainSnapshot {
        TrajectoryDomainSnapshot(world: cache, player: state.player, trajectory: state.trajectory, education: state.education, career: state.career, finance: state.finance, relationships: state.relationships, family: state.family, health: state.healthProfile, housing: state.housing, originProfile: state.originProfile, childhoodDossier: state.childhoodDossier)
    }

    var education: EducationDomainSnapshot {
        EducationDomainSnapshot(world: cache, player: state.player, education: state.education, military: state.military, career: state.career, finance: state.finance, relationships: state.relationships, health: state.healthProfile, policySupport: educationPolicySupport, childhoodDossier: state.childhoodDossier)
    }

    var career: CareerDomainSnapshot {
        CareerDomainSnapshot(
            world: cache,
            player: state.player,
            education: state.education,
            career: state.career,
            health: state.healthProfile,
            relationships: state.relationships,
            childhoodDossier: state.childhoodDossier,
            recentStances: state.yearlyStance.recentStances,
            resilience: state.resilience,
            reentryFrictionYears: state.legal.reentryYearsRemaining,
            custodyProgramCompleted: state.legal.custodyProfile.programProgress >= 100,
            recordPressure: state.legal.recordPressure,
            prisonResidueTags: state.legal.prisonResidue?.tags ?? []
        )
    }

    var legal: LegalDomainSnapshot {
        LegalDomainSnapshot(
            player: state.player,
            legal: state.legal,
            recentStances: state.yearlyStance.recentStances,
            resilience: state.resilience
        )
    }

    var specialCareer: SpecialCareerDomainSnapshot {
        SpecialCareerDomainSnapshot(
            world: cache,
            player: state.player,
            career: state.career,
            specialCareer: state.specialCareer,
            finance: state.finance,
            health: state.healthProfile,
            relationships: state.relationships,
            housing: state.housing,
            worldEra: state.currentEra,
            childhoodDossier: state.childhoodDossier,
            recentStances: state.yearlyStance.recentStances,
            resilience: state.resilience
        )
    }

    var crime: CrimeDomainSnapshot {
        CrimeDomainSnapshot(
            world: cache,
            player: state.player,
            career: state.career,
            crime: state.crime,
            finance: state.finance,
            health: state.healthProfile,
            relationships: state.relationships,
            housing: state.housing,
            activeTier: CrimeTier.resolve(crime: state.crime, specialCareer: state.specialCareer),
            recentStances: state.yearlyStance.recentStances,
            resilience: state.resilience
        )
    }

    var finance: FinanceDomainSnapshot {
        FinanceDomainSnapshot(world: cache, player: state.player, finance: state.finance, career: state.career, education: state.education, health: state.healthProfile, relationships: state.relationships, family: state.family, housing: state.housing, assets: state.assets)
    }

    var investments: InvestmentDomainSnapshot {
        InvestmentDomainSnapshot(world: cache, player: state.player, finance: state.finance, career: state.career, assets: state.assets, worldEra: state.currentEra, economy: state.economy)
    }

    var relationships: RelationshipDomainSnapshot {
        RelationshipDomainSnapshot(world: cache, player: state.player, relationships: state.relationships, family: state.family, health: state.healthProfile, housing: state.housing, financialStress: state.finance.financialStress)
    }

    var family: FamilyDomainSnapshot {
        FamilyDomainSnapshot(
            world: cache,
            player: state.player,
            relationships: state.relationships,
            family: state.family,
            health: state.healthProfile,
            finance: state.finance,
            worldEra: state.currentEra,
            parentRegularArchetype: state.specialCareer.track == .inactive ? state.career.regularArchetype : nil,
            parentCareerBurnout: state.career.burnout,
            parentCrimeTier: CrimeTier.resolve(crime: state.crime, specialCareer: state.specialCareer),
            parentCrimeHeat: max(state.crime.heat, state.specialCareer.heat),
            parentInCustody: state.legal.isInCustody,
            parentCustodyFacility: state.legal.isInCustody ? state.legal.custodyProfile.facility : nil
        )
    }

    var health: HealthDomainSnapshot {
        HealthDomainSnapshot(world: cache, player: state.player, career: state.career, relationships: state.relationships, housing: state.housing, health: state.healthProfile, healthcarePressure: healthcarePressure)
    }

    var housing: HousingDomainSnapshot {
        HousingDomainSnapshot(
            world: cache,
            player: state.player,
            housing: state.housing,
            finance: state.finance,
            assets: state.assets,
            reentryFrictionYears: state.legal.reentryYearsRemaining,
            recordPressure: state.legal.recordPressure
        )
    }

    var assets: AssetDomainSnapshot {
        AssetDomainSnapshot(world: cache, player: state.player, military: state.military, career: state.career, finance: state.finance, assets: state.assets, housing: state.housing)
    }

    var progress: ProgressDomainSnapshot {
        ProgressDomainSnapshot(world: cache, state: state)
    }

    var traits: TraitDomainSnapshot {
        TraitDomainSnapshot(world: cache, player: state.player, finance: state.finance)
    }
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

        return WorldSnapshot(
            state: state,
            cache: cache,
            educationPolicySupport: policySystem.educationSupport(for: state.finance),
            healthcarePressure: policySystem.healthcarePressure(for: state.finance)
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
