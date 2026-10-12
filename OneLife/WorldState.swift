import Foundation

// MARK: - Persisted world data

enum WorldCostEnvironment: String, Codable, CaseIterable {
    case affordable, standard, expensive
}

enum WorldLaborStructure: String, Codable, CaseIterable {
    case resilient, balanced, volatile
}

enum WorldSafetyNet: String, Codable, CaseIterable {
    case thin, standard, strong
}

enum WorldMacroCondition: String, Codable, CaseIterable {
    case steady, expansion, recession, recovery
}

enum WorldPriceCondition: String, Codable, CaseIterable {
    case inflationShock, housingCrunch
}

enum WorldHealthcareCapacity: String, Codable, CaseIterable {
    case constrained, standard, resourced
}

enum WorldDiseaseBurden: String, Codable, CaseIterable {
    case low, typical, high
}

enum WorldPublicHealthCondition: String, Codable, CaseIterable {
    case stable, seasonalStrain, outbreak, recovery
}

enum WorldFlag: String, Codable, CaseIterable, Hashable {
    case affordableCosts, standardCosts, expensiveCosts
    case resilientLabor, balancedLabor, volatileLabor
    case thinSafetyNet, standardSafetyNet, strongSafetyNet
    case steadyEconomy, expansion, recession, recovery
    case inflationShock, housingCrunch
    case constrainedHealthcare, standardHealthcare, resourcedHealthcare
    case lowDiseaseBurden, typicalDiseaseBurden, highDiseaseBurden
    case stablePublicHealth, seasonalHealthStrain, publicHealthOutbreak, publicHealthRecovery

    var title: String {
        switch self {
        case .affordableCosts: "Affordable costs"
        case .standardCosts: "Standard costs"
        case .expensiveCosts: "Expensive costs"
        case .resilientLabor: "Resilient labor market"
        case .balancedLabor: "Balanced labor market"
        case .volatileLabor: "Volatile labor market"
        case .thinSafetyNet: "Thin safety net"
        case .standardSafetyNet: "Standard safety net"
        case .strongSafetyNet: "Strong safety net"
        case .steadyEconomy: "Steady economy"
        case .expansion: "Economic expansion"
        case .recession: "Recession"
        case .recovery: "Economic recovery"
        case .inflationShock: "Inflation shock"
        case .housingCrunch: "Housing crunch"
        case .constrainedHealthcare: "Constrained healthcare"
        case .standardHealthcare: "Standard healthcare"
        case .resourcedHealthcare: "Resourced healthcare"
        case .lowDiseaseBurden: "Low disease burden"
        case .typicalDiseaseBurden: "Typical disease burden"
        case .highDiseaseBurden: "High disease burden"
        case .stablePublicHealth: "Stable public health"
        case .seasonalHealthStrain: "Seasonal health strain"
        case .publicHealthOutbreak: "Public health outbreak"
        case .publicHealthRecovery: "Public health recovery"
        }
    }
}

struct WorldProfile: Codable, Equatable {
    var costEnvironment: WorldCostEnvironment
    var laborStructure: WorldLaborStructure
    var safetyNet: WorldSafetyNet

    static let neutral = WorldProfile(
        costEnvironment: .standard,
        laborStructure: .balanced,
        safetyNet: .standard
    )

    var flags: Set<WorldFlag> {
        let cost: WorldFlag = switch costEnvironment {
        case .affordable: .affordableCosts
        case .standard: .standardCosts
        case .expensive: .expensiveCosts
        }
        let labor: WorldFlag = switch laborStructure {
        case .resilient: .resilientLabor
        case .balanced: .balancedLabor
        case .volatile: .volatileLabor
        }
        let support: WorldFlag = switch safetyNet {
        case .thin: .thinSafetyNet
        case .standard: .standardSafetyNet
        case .strong: .strongSafetyNet
        }
        return [cost, labor, support]
    }
}

struct WorldConditionState: Codable, Equatable {
    var macro: WorldMacroCondition
    var macroYearsRemaining: Int
    var price: WorldPriceCondition?
    var priceYearsRemaining: Int
}

struct PublicHealthWorldState: Codable, Equatable {
    var healthcareCapacity: WorldHealthcareCapacity
    var diseaseBurden: WorldDiseaseBurden
    var condition: WorldPublicHealthCondition
    var yearsRemaining: Int
    var profileDisclosed: Bool
    var recentEventIDs: [String]
    var publicHealthRandom: SeededRandom

    var flags: Set<WorldFlag> {
        let capacity: WorldFlag = switch healthcareCapacity {
        case .constrained: .constrainedHealthcare
        case .standard: .standardHealthcare
        case .resourced: .resourcedHealthcare
        }
        let burden: WorldFlag = switch diseaseBurden {
        case .low: .lowDiseaseBurden
        case .typical: .typicalDiseaseBurden
        case .high: .highDiseaseBurden
        }
        let dynamic: WorldFlag = switch condition {
        case .stable: .stablePublicHealth
        case .seasonalStrain: .seasonalHealthStrain
        case .outbreak: .publicHealthOutbreak
        case .recovery: .publicHealthRecovery
        }
        return [capacity, burden, dynamic]
    }

    mutating func remember(_ eventID: String) {
        recentEventIDs.removeAll { $0 == eventID }
        recentEventIDs.insert(eventID, at: 0)
        recentEventIDs = Array(recentEventIDs.prefix(6))
    }

    mutating func clamp() {
        yearsRemaining = max(0, yearsRemaining)
        recentEventIDs = Array(recentEventIDs.prefix(6))
    }
}

struct WorldState: Codable, Equatable {
    var profile: WorldProfile
    var conditions: WorldConditionState
    var nextPriceReviewAge: Int
    var recentEventIDs: [String]
    var profileDisclosed: Bool
    var worldRandom: SeededRandom
    var publicHealth: PublicHealthWorldState

    var flags: Set<WorldFlag> {
        var result = profile.flags
        let macroFlag: WorldFlag = switch conditions.macro {
        case .steady: .steadyEconomy
        case .expansion: .expansion
        case .recession: .recession
        case .recovery: .recovery
        }
        result.insert(macroFlag)
        if let price = conditions.price {
            result.insert(price == .inflationShock ? .inflationShock : .housingCrunch)
        }
        result.formUnion(publicHealth.flags)
        return result
    }

    mutating func remember(_ eventID: String) {
        recentEventIDs.removeAll { $0 == eventID }
        recentEventIDs.insert(eventID, at: 0)
        recentEventIDs = Array(recentEventIDs.prefix(6))
    }

    mutating func clamp() {
        conditions.macroYearsRemaining = max(0, conditions.macroYearsRemaining)
        conditions.priceYearsRemaining = conditions.price == nil ? 0 : max(0, conditions.priceYearsRemaining)
        nextPriceReviewAge = max(18, nextPriceReviewAge)
        recentEventIDs = Array(recentEventIDs.prefix(6))
        publicHealth.clamp()
    }

    private enum CodingKeys: String, CodingKey {
        case profile, conditions, nextPriceReviewAge, recentEventIDs, profileDisclosed, worldRandom, publicHealth
    }

    init(
        profile: WorldProfile,
        conditions: WorldConditionState,
        nextPriceReviewAge: Int,
        recentEventIDs: [String],
        profileDisclosed: Bool,
        worldRandom: SeededRandom,
        publicHealth: PublicHealthWorldState
    ) {
        self.profile = profile
        self.conditions = conditions
        self.nextPriceReviewAge = nextPriceReviewAge
        self.recentEventIDs = recentEventIDs
        self.profileDisclosed = profileDisclosed
        self.worldRandom = worldRandom
        self.publicHealth = publicHealth
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profile = try c.decode(WorldProfile.self, forKey: .profile)
        conditions = try c.decode(WorldConditionState.self, forKey: .conditions)
        nextPriceReviewAge = try c.decode(Int.self, forKey: .nextPriceReviewAge)
        recentEventIDs = try c.decodeIfPresent([String].self, forKey: .recentEventIDs) ?? []
        profileDisclosed = try c.decodeIfPresent(Bool.self, forKey: .profileDisclosed) ?? false
        worldRandom = try c.decode(SeededRandom.self, forKey: .worldRandom)
        publicHealth = try c.decodeIfPresent(PublicHealthWorldState.self, forKey: .publicHealth)
            ?? WorldSystem.neutralPublicHealth(runSeed: 1, age: 18)
    }
}

// MARK: - Read-only policy output

struct WorldModifierSnapshot: Codable, Equatable {
    var incomeMultiplier = 1.0
    var livingCostMultiplier = 1.0
    var housingCostMultiplier = 1.0
    var layoffRiskMultiplier = 1.0
    var hiringModifier = 0
    var securityDrift = 0
    var unemploymentSupport = 3500
    var careCostMultiplier = 1.0
    var careEffectivenessMultiplier = 1.0
    var conditionDiscoveryModifier = 0
    var annualHealthDrift = 0
    var medicalDebtMultiplier = 1.0
    var propertyValueGrowthRate = 0.01

    mutating func clamp() {
        incomeMultiplier = min(1.12, max(0.90, incomeMultiplier))
        livingCostMultiplier = min(1.22, max(0.90, livingCostMultiplier))
        housingCostMultiplier = min(1.22, max(0.90, housingCostMultiplier))
        layoffRiskMultiplier = min(2.0, max(0.5, layoffRiskMultiplier))
        unemploymentSupport = min(7_000, max(0, unemploymentSupport))
        careCostMultiplier = min(1.35, max(0.85, careCostMultiplier))
        careEffectivenessMultiplier = min(1.15, max(0.75, careEffectivenessMultiplier))
        conditionDiscoveryModifier = min(25, max(-10, conditionDiscoveryModifier))
        annualHealthDrift = min(0, max(-2, annualHealthDrift))
        medicalDebtMultiplier = min(1.50, max(0.75, medicalDebtMultiplier))
        propertyValueGrowthRate = min(0.05, max(-0.05, propertyValueGrowthRate))
    }
}

enum WorldNewsSeverity: String, Codable, Equatable {
    case neutral, pressure, danger
}

struct WorldNews: Codable, Equatable {
    var id: String
    var headline: String
    var detail: String
    var severity: WorldNewsSeverity
    var impactLines: [String]
}

struct WorldYearOutcome: Equatable {
    var modifiers: WorldModifierSnapshot
    var news: WorldNews?
}

struct WorldTransitionWeight: Equatable {
    var condition: WorldMacroCondition
    var weight: Int
}

struct WorldEventDefinition {
    var id: String
    var flag: WorldFlag
    var requiredFlags: Set<WorldFlag> = []
    var forbiddenFlags: Set<WorldFlag> = []
    var transitionWeights: [WorldTransitionWeight]
    var duration: ClosedRange<Int>
    var headline: String
    var detail: String
    var severity: WorldNewsSeverity
    var impactLines: [String]
}

struct WorldPublicHealthTransitionWeight: Equatable {
    var condition: WorldPublicHealthCondition
    var weight: Int
}

struct WorldPublicHealthEventDefinition {
    var id: String
    var flag: WorldFlag
    var requiredFlags: Set<WorldFlag> = []
    var forbiddenFlags: Set<WorldFlag> = []
    var transitionWeights: [WorldPublicHealthTransitionWeight]
    var duration: ClosedRange<Int>
    var headline: String
    var detail: String
    var severity: WorldNewsSeverity
    var impactLines: [String]
}

enum WorldEventRegistry {
    static let macroEvents: [WorldMacroCondition: WorldEventDefinition] = [
        .steady: WorldEventDefinition(
            id: "world-macro-steady", flag: .steadyEconomy,
            transitionWeights: [
                .init(condition: .steady, weight: 35),
                .init(condition: .expansion, weight: 40),
                .init(condition: .recession, weight: 25)
            ],
            duration: 6...10,
            headline: "The Economy Finds Its Balance",
            detail: "Hiring, prices, and pay settle into a less dramatic rhythm.",
            severity: .neutral,
            impactLines: ["Income and layoff pressure normalize"]
        ),
        .expansion: WorldEventDefinition(
            id: "world-macro-expansion", flag: .expansion,
            transitionWeights: [
                .init(condition: .expansion, weight: 30),
                .init(condition: .steady, weight: 50),
                .init(condition: .recession, weight: 20)
            ],
            duration: 6...10,
            headline: "Opportunity Starts Moving More Freely",
            detail: "Employers compete harder and pay stretches further, for now.",
            severity: .neutral,
            impactLines: ["Income +6%", "Hiring +12", "Layoff risk lower"]
        ),
        .recession: WorldEventDefinition(
            id: "world-macro-recession", flag: .recession,
            transitionWeights: [
                .init(condition: .recovery, weight: 80),
                .init(condition: .steady, weight: 20)
            ],
            duration: 4...6,
            headline: "A Recession Reaches Everyday Work",
            detail: "Employers retreat. Security thins before most households can adjust.",
            severity: .danger,
            impactLines: ["Income −4%", "Hiring −15", "Layoff risk sharply higher"]
        ),
        .recovery: WorldEventDefinition(
            id: "world-macro-recovery", flag: .recovery,
            transitionWeights: [
                .init(condition: .steady, weight: 65),
                .init(condition: .expansion, weight: 35)
            ],
            duration: 3...5,
            headline: "The Job Market Begins Recovering",
            detail: "Openings return unevenly, and confidence follows a few steps behind.",
            severity: .neutral,
            impactLines: ["Income +2%", "Hiring +6", "Security begins recovering"]
        )
    ]

    static func definition(for condition: WorldMacroCondition) -> WorldEventDefinition {
        guard let event = macroEvents[condition] else {
            preconditionFailure("Missing world event for \(condition.rawValue)")
        }
        return event
    }

    static let publicHealthEvents: [WorldPublicHealthCondition: WorldPublicHealthEventDefinition] = [
        .stable: .init(
            id: "world-health-stable", flag: .stablePublicHealth,
            transitionWeights: [
                .init(condition: .stable, weight: 60),
                .init(condition: .seasonalStrain, weight: 30),
                .init(condition: .outbreak, weight: 10)
            ],
            duration: 8...14,
            headline: "Care Access Returns to Normal",
            detail: "Clinics regain ordinary capacity and acute pressure recedes.",
            severity: .neutral,
            impactLines: ["Professional care pressure normalizes"]
        ),
        .seasonalStrain: .init(
            id: "world-health-seasonal-strain", flag: .seasonalHealthStrain,
            transitionWeights: [
                .init(condition: .stable, weight: 70),
                .init(condition: .seasonalStrain, weight: 20),
                .init(condition: .outbreak, weight: 10)
            ],
            duration: 2...3,
            headline: "Healthcare Strain Begins Building",
            detail: "Routine care remains available, but demand starts crowding the system.",
            severity: .pressure,
            impactLines: ["Care costs rise", "Care is slightly less effective"]
        ),
        .outbreak: .init(
            id: "world-health-outbreak", flag: .publicHealthOutbreak,
            transitionWeights: [
                .init(condition: .recovery, weight: 85),
                .init(condition: .stable, weight: 15)
            ],
            duration: 2...4,
            headline: "A Public-Health Outbreak Escalates",
            detail: "Widespread illness stretches care capacity and makes untreated conditions harder to avoid.",
            severity: .danger,
            impactLines: ["Health −2/year", "Care costs rise sharply", "Condition risk increases"]
        ),
        .recovery: .init(
            id: "world-health-recovery", flag: .publicHealthRecovery,
            transitionWeights: [
                .init(condition: .stable, weight: 80),
                .init(condition: .seasonalStrain, weight: 20)
            ],
            duration: 2...3,
            headline: "Healthcare Capacity Starts Recovering",
            detail: "The worst pressure has passed, though access has not fully normalized.",
            severity: .neutral,
            impactLines: ["Care pressure begins easing"]
        )
    ]

    static func definition(for condition: WorldPublicHealthCondition) -> WorldPublicHealthEventDefinition {
        guard let event = publicHealthEvents[condition] else {
            preconditionFailure("Missing public-health event for \(condition.rawValue)")
        }
        return event
    }
}

// MARK: - Sovereign world processor

enum WorldSystem {
    private static let seedSalt: UInt64 = 0x574F_524C_4453_5441
    private static let publicHealthSeedSalt: UInt64 = 0x5055_424C_484C_5448

    static func initialize(runSeed: UInt64) -> WorldState {
        var rng = SeededRandom(seed: derivedSeed(from: runSeed))
        let profile = WorldProfile(
            costEnvironment: weightedThird(using: &rng, values: WorldCostEnvironment.allCases),
            laborStructure: weightedThird(using: &rng, values: WorldLaborStructure.allCases),
            safetyNet: weightedThird(using: &rng, values: WorldSafetyNet.allCases)
        )
        let duration = rng.next(in: 6...10)
        let reviewAge = 18 + rng.next(in: 5...9)
        return WorldState(
            profile: profile,
            conditions: WorldConditionState(
                macro: .steady,
                macroYearsRemaining: duration,
                price: nil,
                priceYearsRemaining: 0
            ),
            nextPriceReviewAge: reviewAge,
            recentEventIDs: [],
            profileDisclosed: false,
            worldRandom: rng,
            publicHealth: initializePublicHealth(runSeed: runSeed)
        )
    }

    static func neutral(runSeed: UInt64, age: Int) -> WorldState {
        var rng = SeededRandom(seed: derivedSeed(from: runSeed))
        return WorldState(
            profile: .neutral,
            conditions: WorldConditionState(
                macro: .steady,
                macroYearsRemaining: rng.next(in: 6...10),
                price: nil,
                priceYearsRemaining: 0
            ),
            nextPriceReviewAge: age + rng.next(in: 5...9),
            recentEventIDs: [],
            profileDisclosed: false,
            worldRandom: rng,
            publicHealth: neutralPublicHealth(runSeed: runSeed, age: age)
        )
    }

    static func initializePublicHealth(runSeed: UInt64) -> PublicHealthWorldState {
        var rng = SeededRandom(seed: derivedPublicHealthSeed(from: runSeed))
        return PublicHealthWorldState(
            healthcareCapacity: weightedThird(using: &rng, values: WorldHealthcareCapacity.allCases),
            diseaseBurden: weightedThird(using: &rng, values: WorldDiseaseBurden.allCases),
            condition: .stable,
            yearsRemaining: rng.next(in: 8...14),
            profileDisclosed: false,
            recentEventIDs: [],
            publicHealthRandom: rng
        )
    }

    static func neutralPublicHealth(runSeed: UInt64, age: Int) -> PublicHealthWorldState {
        var rng = SeededRandom(seed: derivedPublicHealthSeed(from: runSeed))
        return PublicHealthWorldState(
            healthcareCapacity: .standard,
            diseaseBurden: .typical,
            condition: .stable,
            yearsRemaining: rng.next(in: 8...14),
            profileDisclosed: false,
            recentEventIDs: [],
            publicHealthRandom: rng
        )
    }

    static func resolveYear(world: inout WorldState, age: Int) -> WorldYearOutcome {
        var news: WorldNews?

        if !world.profileDisclosed && !world.publicHealth.profileDisclosed {
            world.profileDisclosed = true
            world.publicHealth.profileDisclosed = true
            news = profileNews(world.profile, publicHealth: world.publicHealth)
        } else if !world.profileDisclosed {
            world.profileDisclosed = true
            news = profileNews(world.profile, publicHealth: nil)
        } else if !world.publicHealth.profileDisclosed {
            world.publicHealth.profileDisclosed = true
            news = publicHealthProfileNews(world.publicHealth)
        }

        news = merge(news, resolvePublicHealthYear(publicHealth: &world.publicHealth))

        world.conditions.macroYearsRemaining -= 1
        if world.conditions.macroYearsRemaining <= 0 {
            let previous = world.conditions.macro
            let source = WorldEventRegistry.definition(for: previous)
            let next = weightedTransition(source.transitionWeights, using: &world.worldRandom)
            let target = WorldEventRegistry.definition(for: next)
            world.conditions.macro = next
            world.conditions.macroYearsRemaining = world.worldRandom.next(in: target.duration)
            if next != previous, matches(target, flags: world.flags) {
                let transitionNews = WorldNews(
                    id: target.id,
                    headline: target.headline,
                    detail: target.detail,
                    severity: target.severity,
                    impactLines: target.impactLines
                )
                news = merge(news, transitionNews)
                world.remember(target.id)
            }
        }

        if world.conditions.price != nil {
            world.conditions.priceYearsRemaining -= 1
            if world.conditions.priceYearsRemaining <= 0 {
                let ending = world.conditions.price
                world.conditions.price = nil
                world.conditions.priceYearsRemaining = 0
                world.nextPriceReviewAge = age + world.worldRandom.next(in: 5...9)
                let easing = WorldNews(
                    id: "world-prices-easing",
                    headline: "Price Pressure Finally Begins Easing",
                    detail: ending == .housingCrunch
                        ? "Housing remains costly, but the sharpest increases lose momentum."
                        : "Essential costs stop accelerating as quickly as before.",
                    severity: .neutral,
                    impactLines: ["Extra cost pressure removed"]
                )
                news = merge(news, easing)
                world.remember(easing.id)
            }
        } else if age >= world.nextPriceReviewAge {
            let roll = world.worldRandom.next(in: 1...100)
            if roll <= 18 {
                world.conditions.price = .inflationShock
                world.conditions.priceYearsRemaining = world.worldRandom.next(in: 3...5)
                let inflation = WorldNews(
                    id: "world-price-inflation", headline: "Essential Prices Rise Faster Again",
                    detail: "Ordinary purchases begin taking a larger share of household income.",
                    severity: .pressure, impactLines: ["Living costs +12%"]
                )
                news = merge(news, inflation)
                world.remember(inflation.id)
            } else if roll <= 30 {
                world.conditions.price = .housingCrunch
                world.conditions.priceYearsRemaining = world.worldRandom.next(in: 3...5)
                let housing = WorldNews(
                    id: "world-price-housing", headline: "Housing Costs Tighten Their Grip",
                    detail: "Rent, maintenance, and ownership costs climb faster than other essentials.",
                    severity: .pressure, impactLines: ["Housing costs +15%", "Other living costs +3%"]
                )
                news = merge(news, housing)
                world.remember(housing.id)
            } else {
                world.nextPriceReviewAge = age + world.worldRandom.next(in: 5...9)
            }
        }

        world.clamp()
        return WorldYearOutcome(modifiers: modifiers(for: world), news: news)
    }

    static func resolvePublicHealthYear(publicHealth: inout PublicHealthWorldState) -> WorldNews? {
        publicHealth.yearsRemaining -= 1
        guard publicHealth.yearsRemaining <= 0 else {
            publicHealth.clamp()
            return nil
        }

        let previous = publicHealth.condition
        let source = WorldEventRegistry.definition(for: previous)
        var weights = source.transitionWeights
        if previous == .stable {
            switch publicHealth.diseaseBurden {
            case .low:
                adjustPublicHealthWeight(.stable, by: 5, in: &weights)
                adjustPublicHealthWeight(.outbreak, by: -5, in: &weights)
            case .typical:
                break
            case .high:
                adjustPublicHealthWeight(.stable, by: -5, in: &weights)
                adjustPublicHealthWeight(.outbreak, by: 5, in: &weights)
            }
        }
        let next = weightedPublicHealthTransition(weights, using: &publicHealth.publicHealthRandom)
        let target = WorldEventRegistry.definition(for: next)
        publicHealth.condition = next
        publicHealth.yearsRemaining = publicHealth.publicHealthRandom.next(in: target.duration)
        publicHealth.clamp()
        guard next != previous, matches(target, flags: publicHealth.flags) else { return nil }
        publicHealth.remember(target.id)
        return WorldNews(
            id: target.id,
            headline: target.headline,
            detail: target.detail,
            severity: target.severity,
            impactLines: target.impactLines
        )
    }

    static func modifiers(for world: WorldState) -> WorldModifierSnapshot {
        var result = WorldModifierSnapshot()
        let costMultiplier: Double = switch world.profile.costEnvironment {
        case .affordable: 0.92
        case .standard: 1.0
        case .expensive: 1.10
        }
        result.livingCostMultiplier *= costMultiplier
        let laborMultiplier: Double = switch world.profile.laborStructure {
        case .resilient: 0.80
        case .balanced: 1.0
        case .volatile: 1.25
        }
        result.layoffRiskMultiplier *= laborMultiplier
        result.unemploymentSupport = switch world.profile.safetyNet {
        case .thin: 0
        case .standard: 3_500
        case .strong: 7_000
        }
        switch world.conditions.macro {
        case .steady:
            break
        case .expansion:
            result.incomeMultiplier *= 1.06
            result.layoffRiskMultiplier *= 0.70
            result.hiringModifier += 12
            result.propertyValueGrowthRate = 0.03
        case .recession:
            result.incomeMultiplier *= 0.96
            result.layoffRiskMultiplier *= 1.75
            result.hiringModifier -= 15
            result.securityDrift -= 4
            result.propertyValueGrowthRate = -0.04
        case .recovery:
            result.incomeMultiplier *= 1.02
            result.layoffRiskMultiplier *= 0.90
            result.hiringModifier += 6
            result.securityDrift += 2
            result.propertyValueGrowthRate = 0.02
        }
        switch world.conditions.price {
        case .inflationShock:
            result.livingCostMultiplier *= 1.12
            result.propertyValueGrowthRate += 0.01
        case .housingCrunch:
            result.livingCostMultiplier *= 1.03
            result.housingCostMultiplier *= 1.15
            result.propertyValueGrowthRate += 0.02
        case nil:
            break
        }
        switch world.publicHealth.healthcareCapacity {
        case .constrained:
            result.careCostMultiplier *= 1.15
            result.careEffectivenessMultiplier *= 0.90
            result.medicalDebtMultiplier *= 1.20
        case .standard:
            break
        case .resourced:
            result.careCostMultiplier *= 0.90
            result.careEffectivenessMultiplier *= 1.08
            result.medicalDebtMultiplier *= 0.80
        }
        switch world.publicHealth.diseaseBurden {
        case .low: result.conditionDiscoveryModifier -= 8
        case .typical: break
        case .high: result.conditionDiscoveryModifier += 8
        }
        switch world.publicHealth.condition {
        case .stable:
            break
        case .seasonalStrain:
            result.careCostMultiplier *= 1.08
            result.careEffectivenessMultiplier *= 0.95
            result.conditionDiscoveryModifier += 5
        case .outbreak:
            result.careCostMultiplier *= 1.20
            result.careEffectivenessMultiplier *= 0.85
            result.conditionDiscoveryModifier += 15
            result.annualHealthDrift -= 2
            result.medicalDebtMultiplier *= 1.25
        case .recovery:
            result.careCostMultiplier *= 1.05
            result.conditionDiscoveryModifier -= 5
        }
        result.clamp()
        return result
    }

    private static func derivedSeed(from runSeed: UInt64) -> UInt64 {
        var value = runSeed ^ seedSalt
        value &+= 0x9E37_79B9_7F4A_7C15
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    private static func derivedPublicHealthSeed(from runSeed: UInt64) -> UInt64 {
        var value = runSeed ^ publicHealthSeedSalt
        value &+= 0x9E37_79B9_7F4A_7C15
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    private static func weightedThird<T>(using rng: inout SeededRandom, values: [T]) -> T {
        precondition(values.count == 3)
        let roll = rng.next(in: 1...100)
        return roll <= 25 ? values[0] : (roll <= 75 ? values[1] : values[2])
    }

    private static func weightedTransition(
        _ values: [WorldTransitionWeight],
        using rng: inout SeededRandom
    ) -> WorldMacroCondition {
        let total = values.reduce(0) { $0 + max(0, $1.weight) }
        precondition(total > 0)
        var roll = rng.next(in: 1...total)
        for value in values {
            roll -= max(0, value.weight)
            if roll <= 0 { return value.condition }
        }
        return values.last!.condition
    }

    private static func matches(_ event: WorldEventDefinition, flags: Set<WorldFlag>) -> Bool {
        event.requiredFlags.isSubset(of: flags) && event.forbiddenFlags.isDisjoint(with: flags)
    }

    private static func matches(_ event: WorldPublicHealthEventDefinition, flags: Set<WorldFlag>) -> Bool {
        event.requiredFlags.isSubset(of: flags) && event.forbiddenFlags.isDisjoint(with: flags)
    }

    private static func adjustPublicHealthWeight(
        _ condition: WorldPublicHealthCondition,
        by adjustment: Int,
        in weights: inout [WorldPublicHealthTransitionWeight]
    ) {
        guard let index = weights.firstIndex(where: { $0.condition == condition }) else { return }
        weights[index].weight = max(0, weights[index].weight + adjustment)
    }

    private static func weightedPublicHealthTransition(
        _ values: [WorldPublicHealthTransitionWeight],
        using rng: inout SeededRandom
    ) -> WorldPublicHealthCondition {
        let total = values.reduce(0) { $0 + max(0, $1.weight) }
        precondition(total > 0)
        var roll = rng.next(in: 1...total)
        for value in values {
            roll -= max(0, value.weight)
            if roll <= 0 { return value.condition }
        }
        return values.last!.condition
    }

    private static func profileNews(_ profile: WorldProfile, publicHealth: PublicHealthWorldState?) -> WorldNews {
        let cost = switch profile.costEnvironment {
        case .affordable: "Living costs start below average"
        case .standard: "Living costs begin near average"
        case .expensive: "Living costs start above average"
        }
        let labor = switch profile.laborStructure {
        case .resilient: "Jobs are relatively resilient"
        case .balanced: "The labor market is balanced"
        case .volatile: "Jobs carry greater instability"
        }
        let support = switch profile.safetyNet {
        case .thin: "Unemployment support is thin"
        case .standard: "Unemployment support is modest"
        case .strong: "Unemployment support is stronger"
        }
        var impacts = [cost, labor, support]
        if let publicHealth {
            impacts.append(capacityImpact(publicHealth.healthcareCapacity))
            impacts.append(burdenImpact(publicHealth.diseaseBurden))
        }
        return WorldNews(
            id: "world-profile", headline: "The World You Entered",
            detail: "The economy and care system have starting conditions that outlast any single choice.",
            severity: profile.costEnvironment == .expensive || profile.laborStructure == .volatile || publicHealth?.healthcareCapacity == .constrained ? .pressure : .neutral,
            impactLines: Array(impacts.prefix(5))
        )
    }

    private static func publicHealthProfileNews(_ publicHealth: PublicHealthWorldState) -> WorldNews {
        WorldNews(
            id: "world-health-profile",
            headline: "The Care System Around You",
            detail: "The public-health environment shapes access and risk beyond your individual choices.",
            severity: publicHealth.healthcareCapacity == .constrained || publicHealth.diseaseBurden == .high ? .pressure : .neutral,
            impactLines: [capacityImpact(publicHealth.healthcareCapacity), burdenImpact(publicHealth.diseaseBurden)]
        )
    }

    private static func capacityImpact(_ capacity: WorldHealthcareCapacity) -> String {
        switch capacity {
        case .constrained: "Healthcare capacity is constrained"
        case .standard: "Healthcare capacity is typical"
        case .resourced: "Healthcare capacity is well resourced"
        }
    }

    private static func burdenImpact(_ burden: WorldDiseaseBurden) -> String {
        switch burden {
        case .low: "Background disease burden is low"
        case .typical: "Background disease burden is typical"
        case .high: "Background disease burden is high"
        }
    }

    private static func merge(_ first: WorldNews?, _ second: WorldNews?) -> WorldNews? {
        guard let second else { return first }
        guard let first else { return second }
        let severity: WorldNewsSeverity = if first.severity == .danger || second.severity == .danger {
            .danger
        } else if first.severity == .pressure || second.severity == .pressure {
            .pressure
        } else {
            .neutral
        }
        return WorldNews(
            id: "\(first.id)+\(second.id)",
            headline: severity == second.severity ? second.headline : first.headline,
            detail: "\(first.detail) \(second.detail)",
            severity: severity,
            impactLines: Array((first.impactLines + second.impactLines).prefix(5))
        )
    }
}
