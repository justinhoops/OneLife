import Foundation

// MARK: - Criminal path identity

enum CriminalPathMode: String, Codable, CaseIterable, Identifiable {
    case solo
    case gangMember
    case gangLeader
    case enterprise

    var id: String { rawValue }
    var title: String { rawValue == "gangMember" ? "Gang member" : rawValue == "gangLeader" ? "Gang leader" : rawValue.capitalized }
}

enum CriminalRank: String, Codable, CaseIterable, Identifiable {
    case solo, recruit, member, specialist, lieutenant, leader, enterpriseLeader

    var id: String { rawValue }
    var authority: Int {
        switch self {
        case .solo: 0; case .recruit: 1; case .member: 2; case .specialist: 3
        case .lieutenant: 4; case .leader: 5; case .enterpriseLeader: 6
        }
    }
    var title: String { rawValue == "enterpriseLeader" ? "Enterprise leader" : rawValue.capitalized }
}

enum SpecialistRole: String, Codable, CaseIterable, Identifiable {
    case planner, driver, enforcer, technician, broker, lookout, lieutenant
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

/// The player's assigned street-level specialty inside a gang. This is
/// intentionally separate from SpecialistRole, which describes NPCs managed
/// by a Syndicate/enterprise organization.
enum CriminalSpecialty: String, Codable, CaseIterable, Identifiable {
    case streetDistributor
    case drugManufacturer
    case runner
    case supplier
    case enforcer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .streetDistributor: "Street distributor"
        case .drugManufacturer: "Drug manufacturer"
        case .runner: "Runner"
        case .supplier: "Supply retriever"
        case .enforcer: "Enforcer"
        }
    }

    var detail: String {
        switch self {
        case .streetDistributor: "Move product at street level for a commission."
        case .drugManufacturer: "Prepare product for the gang's distribution network."
        case .runner: "Move packages and messages through the gang's routes."
        case .supplier: "Keep materials and connections flowing to the crew."
        case .enforcer: "Protect the gang's people, territory, and reputation."
        }
    }

    /// Annual personal income contribution before rank and trust modifiers.
    var annualIncome: Int {
        switch self {
        case .streetDistributor: 420
        case .drugManufacturer: 520
        case .runner: 460
        case .supplier: 560
        case .enforcer: 500
        }
    }

    /// Contextual exposure from doing this job, before heat and rank.
    var exposureRisk: Int {
        switch self {
        case .streetDistributor: 9
        case .drugManufacturer: 13
        case .runner: 11
        case .supplier: 8
        case .enforcer: 16
        }
    }

    var proficiencyKey: String { "specialty.\(rawValue)" }
}

enum CrimeOperationType: String, Codable, CaseIterable, Identifiable {
    case burglary, vehicleTheft, robbery, fraud, extortion, smuggling, kidnapping, murder, territoryAttack
    var id: String { rawValue }
    var title: String {
        switch self {
        case .vehicleTheft: "Vehicle theft"
        case .territoryAttack: "Rival-territory attack"
        default: rawValue.capitalized
        }
    }
    var baseRisk: Int {
        switch self {
        case .burglary: 28; case .vehicleTheft: 32; case .robbery: 42; case .fraud: 36
        case .extortion: 48; case .smuggling: 46; case .kidnapping: 72; case .murder: 84
        case .territoryAttack: 68
        }
    }
    var basePayout: Int {
        switch self {
        case .burglary: 700; case .vehicleTheft: 1_200; case .robbery: 2_000; case .fraud: 1_500
        case .extortion: 1_800; case .smuggling: 2_400; case .kidnapping: 4_000; case .murder: 3_000
        case .territoryAttack: 0
        }
    }

    var isStarterOperation: Bool {
        switch self {
        case .burglary, .vehicleTheft, .fraud, .smuggling: true
        case .robbery, .extortion, .kidnapping, .murder, .territoryAttack: false
        }
    }

    var minimumAge: Int { isStarterOperation ? 14 : 18 }

    /// Authority required for organization plans. Solo starter operations
    /// remain available without an organization; escalation belongs to the
    /// organization path.
    var minimumOrganizationAuthority: Int {
        switch self {
        case .burglary, .vehicleTheft, .fraud, .smuggling: 0
        case .robbery: CriminalRank.member.authority
        case .extortion: CriminalRank.lieutenant.authority
        case .territoryAttack: CriminalRank.leader.authority
        case .kidnapping, .murder: CriminalRank.enterpriseLeader.authority
        }
    }

    var accessLabel: String {
        switch self {
        case .burglary, .vehicleTheft, .fraud, .smuggling: "Starter operation"
        case .robbery: "Requires crew standing"
        case .extortion: "Requires lieutenant standing"
        case .territoryAttack: "Requires leadership"
        case .kidnapping, .murder: "Requires enterprise leadership"
        }
    }
}

enum CrimeApproach: String, Codable, CaseIterable, Identifiable {
    case stealth, force, deception, technical, contact, logistics
    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var riskAdjustment: Int {
        switch self {
        case .stealth: -5
        case .force: 10
        case .deception: -2
        case .technical: -6
        case .contact: -3
        case .logistics: -4
        }
    }

    var payoutMultiplierPercent: Int {
        switch self {
        case .stealth: 100
        case .force: 115
        case .deception: 108
        case .technical: 112
        case .contact: 96
        case .logistics: 104
        }
    }
}

enum CrimeTask: String, Codable, CaseIterable, Identifiable {
    case planning, transport, entry, technical, security, escape, negotiation
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct CrimeOperationDefinition: Codable, Equatable, Identifiable {
    let id: CrimeOperationType
    let approaches: [CrimeApproach]
    let preferredApproaches: [CrimeApproach]
    let preferredRoles: [SpecialistRole]
    let tasks: [CrimeTask]
    let successHeat: Int
    let failureHeat: Int
    let failureHealth: Int
    let payoutMultiplierPercent: Int
    let detail: String

    static let catalog: [CrimeOperationDefinition] = CrimeOperationType.allCases.map { type in
        let roles: [SpecialistRole]
        let tasks: [CrimeTask]
        let preferred: [CrimeApproach]
        let successHeat: Int
        let failureHeat: Int
        let failureHealth: Int
        let payoutMultiplierPercent: Int
        switch type {
        case .burglary:
            roles = [.planner, .lookout, .driver]; tasks = [.planning, .entry, .escape]
            preferred = [.stealth, .technical]; successHeat = 5; failureHeat = 14; failureHealth = 1; payoutMultiplierPercent = 100
        case .vehicleTheft:
            roles = [.driver, .lookout, .broker]; tasks = [.planning, .transport, .escape]
            preferred = [.technical, .logistics]; successHeat = 8; failureHeat = 18; failureHealth = 2; payoutMultiplierPercent = 110
        case .fraud:
            roles = [.technician, .broker, .planner]; tasks = [.planning, .technical, .negotiation]
            preferred = [.deception, .technical, .contact]; successHeat = 3; failureHeat = 12; failureHealth = 1; payoutMultiplierPercent = 118
        case .smuggling:
            roles = [.driver, .broker, .lookout]; tasks = [.transport, .security, .escape]
            preferred = [.logistics, .contact]; successHeat = 10; failureHeat = 22; failureHealth = 3; payoutMultiplierPercent = 106
        case .robbery:
            roles = [.planner, .enforcer, .driver]; tasks = [.planning, .security, .escape]
            preferred = [.stealth, .force]; successHeat = 12; failureHeat = 26; failureHealth = 4; payoutMultiplierPercent = 108
        case .extortion:
            roles = [.enforcer, .broker, .lookout]; tasks = [.planning, .security, .negotiation]
            preferred = [.contact, .force]; successHeat = 10; failureHeat = 24; failureHealth = 3; payoutMultiplierPercent = 112
        case .kidnapping:
            roles = [.planner, .enforcer, .driver]; tasks = [.planning, .security, .escape]
            preferred = [.logistics, .force]; successHeat = 18; failureHeat = 35; failureHealth = 7; payoutMultiplierPercent = 120
        case .murder:
            roles = [.enforcer, .planner, .lookout]; tasks = [.planning, .security, .escape]
            preferred = [.contact, .stealth]; successHeat = 30; failureHeat = 45; failureHealth = 10; payoutMultiplierPercent = 100
        case .territoryAttack:
            roles = [.lieutenant, .enforcer, .lookout]; tasks = [.planning, .security, .escape]
            preferred = [.force, .logistics]; successHeat = 22; failureHeat = 38; failureHealth = 6; payoutMultiplierPercent = 100
        }
        return CrimeOperationDefinition(
            id: type,
            approaches: [.stealth, .force, .deception, .technical, .contact, .logistics],
            preferredApproaches: preferred,
            preferredRoles: roles,
            tasks: tasks,
            successHeat: successHeat,
            failureHeat: failureHeat,
            failureHealth: failureHealth,
            payoutMultiplierPercent: payoutMultiplierPercent,
            detail: "A \(type.title.lowercased()) operation with distinct preparation, exposure, and failure pressure."
        )
    }

    static func definition(for type: CrimeOperationType) -> CrimeOperationDefinition {
        catalog.first { $0.id == type }!
    }
}

struct SpecialistState: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var role: SpecialistRole
    var competence: Int
    var loyalty: Int
    var fear: Int
    var respect: Int
    var ambition: Int
    var poachingRisk: Int
    var relationship: Int
    var knownFacts: Set<String> = []
    var operationExperience: [String: Int] = [:]
    var isArrested = false
    var isInjured = false
    var isDead = false
    var hasDefected = false

    var isAvailable: Bool { !isArrested && !isInjured && !isDead && !hasDefected }

    func knownValue(_ fact: String, value: String) -> String {
        knownFacts.contains(fact) ? value : "Unknown"
    }

    mutating func clamp() {
        competence = min(100, max(0, competence)); loyalty = min(100, max(0, loyalty))
        fear = min(100, max(0, fear)); respect = min(100, max(0, respect))
        ambition = min(100, max(0, ambition)); poachingRisk = min(100, max(0, poachingRisk))
        relationship = min(100, max(-100, relationship))
        operationExperience = operationExperience.filter { !$0.key.isEmpty }.mapValues { min(100, max(0, $0)) }
    }
}

struct CrimeRiskBreakdown: Codable, Equatable {
    var operation = 0
    var approach = 0
    var task = 0
    var competence = 0
    var loyalty = 0
    var equipment = 0
    var heat = 0
    var repetition = 0
    var informant = 0
    var rival = 0
    var preparation = 0

    var total: Int { min(99, max(1, operation + approach + task - competence - loyalty + equipment + heat + repetition + informant + rival - preparation)) }

    var lines: [String] {
        [
            ("Operation", operation), ("Approach", approach), ("Assigned tasks", task), ("Competence", -competence),
            ("Loyalty", -loyalty), ("Equipment", equipment), ("Heat", heat),
            ("Repeated method", repetition), ("Informant pressure", informant), ("Rival pressure", rival), ("Preparation", -preparation)
        ].filter { $0.1 != 0 }.map { "\($0.0) \($0.1 > 0 ? "+" : "")\($0.1)" }
    }
}

extension CrimeRiskBreakdown {
    private enum CodingKeys: String, CodingKey { case operation, approach, task, competence, loyalty, equipment, heat, repetition, informant, rival, preparation }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        operation = try c.decodeIfPresent(Int.self, forKey: .operation) ?? 0
        approach = try c.decodeIfPresent(Int.self, forKey: .approach) ?? 0
        task = try c.decodeIfPresent(Int.self, forKey: .task) ?? 0
        competence = try c.decodeIfPresent(Int.self, forKey: .competence) ?? 0
        loyalty = try c.decodeIfPresent(Int.self, forKey: .loyalty) ?? 0
        equipment = try c.decodeIfPresent(Int.self, forKey: .equipment) ?? 0
        heat = try c.decodeIfPresent(Int.self, forKey: .heat) ?? 0
        repetition = try c.decodeIfPresent(Int.self, forKey: .repetition) ?? 0
        informant = try c.decodeIfPresent(Int.self, forKey: .informant) ?? 0
        rival = try c.decodeIfPresent(Int.self, forKey: .rival) ?? 0
        preparation = try c.decodeIfPresent(Int.self, forKey: .preparation) ?? 0
    }
}

struct CrimePlan: Codable, Equatable, Identifiable {
    var id: String
    var operation: CrimeOperationType
    var approach: CrimeApproach = .stealth
    var assignments: [CrimeTask: String] = [:]
    var equipmentLoadout = "low-profile"
    var kitID: String?
    var preparation = 0
    var mastery = 0
    var exposure = 0
    var lastRisk: CrimeRiskBreakdown?
    var lastOutcome: String?
    var lastExecutedAge: Int?

    mutating func clamp() {
        preparation = min(20, max(0, preparation)); mastery = min(100, max(0, mastery)); exposure = min(100, max(0, exposure))
    }
}

struct CriminalKit: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var personalAssetIDs: [UInt64] = []
    var stolenAssetIDs: [UInt64] = []
    var purchasedEquipment = 0
    var lastUsedAge: Int?

    var assetCount: Int { personalAssetIDs.count + stolenAssetIDs.count }

    mutating func clamp() {
        var personalSeen = Set<UInt64>()
        personalAssetIDs = Array(personalAssetIDs.filter { personalSeen.insert($0).inserted }.prefix(8))
        var stolenSeen = Set<UInt64>()
        stolenAssetIDs = Array(stolenAssetIDs.filter { stolenSeen.insert($0).inserted }.prefix(8))
        purchasedEquipment = min(25_000, max(0, purchasedEquipment))
    }
}

enum CriminalAssetConversionRoute: String, Codable, CaseIterable, Identifiable {
    case fence
    case frontBusiness

    var id: String { rawValue }
    var title: String {
        switch self {
        case .fence: "Move through a fence"
        case .frontBusiness: "Move through the front business"
        }
    }
}

struct CriminalKitReadiness: Equatable {
    var requirement: String
    var matched = false
    var condition = 100
    var riskAdjustment = 0

    var summary: String {
        matched ? "\(requirement) ready · risk \(riskAdjustment >= 0 ? "+" : "")\(riskAdjustment)" : "Needs \(requirement.lowercased())"
    }
}

struct CriminalCareerSnapshot: Equatable {
    var pathTitle: String
    var rankTitle: String
    var cashFlow: Int
    var heat: Int
    var notoriety: Int
    var nextOperation: CrimeOperationType?
    var blocker: String?

    var nextOperationTitle: String { nextOperation?.title ?? "No operation available" }
}

struct CriminalStolenAsset: Codable, Equatable, Identifiable {
    var id: UInt64
    var listingID: String
    var name: String
    var category: AssetCategory
    var estimatedValue: Int
    var acquiredAge: Int
    var condition = 100
}

struct CrimeEquipmentState: Codable, Equatable {
    var budget = 0
    var vehicleQuality = 0
    var weaponQuality = 0
    var technicalQuality = 0
    var concealmentQuality = 0
    var condition = 100
    var maintenanceDue = false

    var effectiveness: Int { max(0, (vehicleQuality + weaponQuality + technicalQuality + concealmentQuality) / 4 - (100 - condition) / 4) }

    mutating func clamp() {
        budget = max(0, budget); vehicleQuality = min(100, max(0, vehicleQuality)); weaponQuality = min(100, max(0, weaponQuality))
        technicalQuality = min(100, max(0, technicalQuality)); concealmentQuality = min(100, max(0, concealmentQuality))
        condition = min(100, max(0, condition)); maintenanceDue = condition < 45
    }
}

struct SafehouseState: Codable, Equatable {
    var name = "No safehouse"
    var level = 0
    var concealment = 0
    var storage = 0
    var planning = 0
    var compromised = false
}

struct FrontBusinessState: Codable, Equatable {
    var name: String
    var acquired = true
    var operatingBudget = 0
    var staffing = 0
    var legitimateCashFlow = 0
    var heatReduction = 0
    var inspectionPressure = 0
    var legalScrutiny = 0
    var closureYearsRemaining = 0
    var isLegallyRestricted = false
    var linkedBusinessID: String?

    mutating func clamp() {
        operatingBudget = max(0, operatingBudget); staffing = min(5, max(0, staffing)); legitimateCashFlow = max(0, legitimateCashFlow)
        heatReduction = min(20, max(0, heatReduction)); inspectionPressure = min(100, max(0, inspectionPressure))
        legalScrutiny = min(100, max(0, legalScrutiny)); closureYearsRemaining = max(0, closureYearsRemaining)
        if closureYearsRemaining == 0 { isLegallyRestricted = false }
    }
}

extension FrontBusinessState {
    private enum CodingKeys: String, CodingKey {
        case name, acquired, operatingBudget, staffing, legitimateCashFlow, heatReduction, inspectionPressure
        case legalScrutiny, closureYearsRemaining, isLegallyRestricted, linkedBusinessID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        acquired = try c.decodeIfPresent(Bool.self, forKey: .acquired) ?? true
        operatingBudget = try c.decodeIfPresent(Int.self, forKey: .operatingBudget) ?? 0
        staffing = try c.decodeIfPresent(Int.self, forKey: .staffing) ?? 0
        legitimateCashFlow = try c.decodeIfPresent(Int.self, forKey: .legitimateCashFlow) ?? 0
        heatReduction = try c.decodeIfPresent(Int.self, forKey: .heatReduction) ?? 0
        inspectionPressure = try c.decodeIfPresent(Int.self, forKey: .inspectionPressure) ?? 0
        legalScrutiny = try c.decodeIfPresent(Int.self, forKey: .legalScrutiny) ?? 0
        closureYearsRemaining = try c.decodeIfPresent(Int.self, forKey: .closureYearsRemaining) ?? 0
        isLegallyRestricted = try c.decodeIfPresent(Bool.self, forKey: .isLegallyRestricted) ?? false
        linkedBusinessID = try c.decodeIfPresent(String.self, forKey: .linkedBusinessID)
        clamp()
    }
}

struct RivalGangState: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var relationship = 0
    var hatred = 0
    var fear = 0
    var strength = 50
    var territory = 10
    var retaliation = 50
    var membersLost = 0
    var specialistsPoached = 0

    mutating func clamp() {
        relationship = min(100, max(-100, relationship)); hatred = min(100, max(0, hatred))
        fear = min(100, max(0, fear)); strength = min(100, max(0, strength))
        territory = min(100, max(0, territory)); retaliation = min(100, max(0, retaliation))
        membersLost = max(0, membersLost); specialistsPoached = max(0, specialistsPoached)
    }
}

enum DrugEnterpriseRole: String, Codable, CaseIterable, Identifiable {
    case mule, runner, supplyRetriever

    var id: String { rawValue }
    var title: String {
        switch self {
        case .mule: "Mules"
        case .runner: "Runners"
        case .supplyRetriever: "Supply retrievers"
        }
    }
    var cost: Int {
        switch self {
        case .mule: 600
        case .runner: 800
        case .supplyRetriever: 1_000
        }
    }
}

struct DrugEnterpriseState: Codable, Equatable {
    var active = false
    var productQuality = 45
    var demand = 35
    var supplyReliability = 40
    var networkCoverage = 10
    var mules = 0
    var runners = 0
    var supplyRetrievers = 0
    var lastManagedAge: Int?
    var totalRevenue = 0

    mutating func clamp() {
        productQuality = min(100, max(0, productQuality)); demand = min(100, max(0, demand))
        supplyReliability = min(100, max(0, supplyReliability)); networkCoverage = min(100, max(0, networkCoverage))
        mules = min(8, max(0, mules)); runners = min(8, max(0, runners)); supplyRetrievers = min(6, max(0, supplyRetrievers))
        totalRevenue = max(0, totalRevenue)
    }
}

struct DrugEnterpriseOutcome: Equatable {
    var headline: String
    var detail: String
    var risk: CrimeRiskBreakdown
    var payout = 0
    var succeeded = false
    var healthDelta = 0
    var relationshipsDelta = 0
    var repDelta = 0
    var consequences: [DomainConsequence] = []
}

struct CriminalPathState: Codable, Equatable {
    var mode: CriminalPathMode = .solo
    var rank: CriminalRank = .solo
    var gangName: String?
    var gangTrust = 0
    var notoriety = 0
    var heat = 0
    var influence = 0
    var territory = 0
    var cashFlow = 0
    /// Assigned only for the player's street-level gang role. Syndicate uses
    /// managed specialists and does not require a player specialty.
    var gangSpecialty: CriminalSpecialty?
    var gangSpecialtySkill = 0
    var lastSpecialtyWorkAge: Int?
    var drugEnterprise: DrugEnterpriseState?
    var proficiencies: [String: Int] = [:]
    var specialists: [SpecialistState] = []
    var plans: [CrimePlan] = []
    var equipment = CrimeEquipmentState()
    var safehouses: [SafehouseState] = []
    var frontBusiness: FrontBusinessState?
    var successionOrder: [String] = []
    var actingLeaderID: String?
    var organizationAbsent = false
    var organizationMorale = 50
    var repeatedOperations: [String: Int] = [:]
    var lastSoloCrimeAge: [String: Int] = [:]
    var customKits: [CriminalKit] = []
    var soloKitID: String?
    var stolenAssets: [CriminalStolenAsset] = []
    var nextStolenAssetID: UInt64 = 1
    var defenseTeam: [DefenseLawyerState] = []
    var rivals: [RivalGangState] = []

    var isOrganization: Bool { mode != .solo }
    var canManageDrugEnterprise: Bool { mode == .gangLeader || mode == .enterprise }

    mutating func clamp() {
        gangTrust = min(100, max(0, gangTrust)); notoriety = min(100, max(0, notoriety)); heat = min(100, max(0, heat))
        influence = min(100, max(0, influence)); territory = min(100, max(0, territory)); cashFlow = max(-10_000, cashFlow)
        organizationMorale = min(100, max(0, organizationMorale))
        gangSpecialtySkill = min(100, max(0, gangSpecialtySkill))
        defenseTeam = Array(defenseTeam.prefix(3)); defenseTeam.indices.forEach { defenseTeam[$0].clamp() }
        rivals = Array(rivals.prefix(3)); rivals.indices.forEach { rivals[$0].clamp() }
        proficiencies = proficiencies.mapValues { min(100, max(0, $0)) }
        specialists = Array(specialists.prefix(6)); specialists.indices.forEach { specialists[$0].clamp() }
        plans = Array(plans.prefix(12)); plans.indices.forEach { plans[$0].clamp() }
        equipment.clamp(); safehouses = Array(safehouses.prefix(4)); customKits = Array(customKits.prefix(8)); customKits.indices.forEach { customKits[$0].clamp() }
        stolenAssets = Array(stolenAssets.prefix(24)); stolenAssets.indices.forEach { stolenAssets[$0].condition = min(100, max(0, stolenAssets[$0].condition)) }
        nextStolenAssetID = max(nextStolenAssetID, (stolenAssets.map(\.id).max() ?? 0) &+ 1)
        frontBusiness?.clamp()
        drugEnterprise?.clamp()
        successionOrder = successionOrder.filter { candidateID in
            specialists.contains { specialist in specialist.id == candidateID }
        }
    }
}

extension CriminalPathState {
    private enum CodingKeys: String, CodingKey {
        case mode, rank, gangName, gangTrust, notoriety, heat, influence, territory, cashFlow, gangSpecialty, gangSpecialtySkill, lastSpecialtyWorkAge, drugEnterprise, proficiencies, specialists, plans, equipment, safehouses, frontBusiness, successionOrder, actingLeaderID, organizationAbsent, organizationMorale, repeatedOperations, lastSoloCrimeAge, customKits, soloKitID, stolenAssets, nextStolenAssetID, defenseTeam, rivals
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mode = try c.decodeIfPresent(CriminalPathMode.self, forKey: .mode) ?? .solo
        rank = try c.decodeIfPresent(CriminalRank.self, forKey: .rank) ?? .solo
        gangName = try c.decodeIfPresent(String.self, forKey: .gangName)
        gangTrust = try c.decodeIfPresent(Int.self, forKey: .gangTrust) ?? 0
        notoriety = try c.decodeIfPresent(Int.self, forKey: .notoriety) ?? 0
        heat = try c.decodeIfPresent(Int.self, forKey: .heat) ?? 0
        influence = try c.decodeIfPresent(Int.self, forKey: .influence) ?? 0
        territory = try c.decodeIfPresent(Int.self, forKey: .territory) ?? 0
        cashFlow = try c.decodeIfPresent(Int.self, forKey: .cashFlow) ?? 0
        gangSpecialty = try c.decodeIfPresent(CriminalSpecialty.self, forKey: .gangSpecialty)
        gangSpecialtySkill = try c.decodeIfPresent(Int.self, forKey: .gangSpecialtySkill) ?? 0
        lastSpecialtyWorkAge = try c.decodeIfPresent(Int.self, forKey: .lastSpecialtyWorkAge)
        drugEnterprise = try c.decodeIfPresent(DrugEnterpriseState.self, forKey: .drugEnterprise)
        proficiencies = try c.decodeIfPresent([String: Int].self, forKey: .proficiencies) ?? [:]
        specialists = try c.decodeIfPresent([SpecialistState].self, forKey: .specialists) ?? []
        plans = try c.decodeIfPresent([CrimePlan].self, forKey: .plans) ?? []
        equipment = try c.decodeIfPresent(CrimeEquipmentState.self, forKey: .equipment) ?? CrimeEquipmentState()
        safehouses = try c.decodeIfPresent([SafehouseState].self, forKey: .safehouses) ?? []
        frontBusiness = try c.decodeIfPresent(FrontBusinessState.self, forKey: .frontBusiness)
        successionOrder = try c.decodeIfPresent([String].self, forKey: .successionOrder) ?? []
        actingLeaderID = try c.decodeIfPresent(String.self, forKey: .actingLeaderID)
        organizationAbsent = try c.decodeIfPresent(Bool.self, forKey: .organizationAbsent) ?? false
        organizationMorale = try c.decodeIfPresent(Int.self, forKey: .organizationMorale) ?? 50
        repeatedOperations = try c.decodeIfPresent([String: Int].self, forKey: .repeatedOperations) ?? [:]
        lastSoloCrimeAge = try c.decodeIfPresent([String: Int].self, forKey: .lastSoloCrimeAge) ?? [:]
        customKits = try c.decodeIfPresent([CriminalKit].self, forKey: .customKits) ?? []
        soloKitID = try c.decodeIfPresent(String.self, forKey: .soloKitID)
        stolenAssets = try c.decodeIfPresent([CriminalStolenAsset].self, forKey: .stolenAssets) ?? []
        nextStolenAssetID = try c.decodeIfPresent(UInt64.self, forKey: .nextStolenAssetID) ?? 1
        defenseTeam = try c.decodeIfPresent([DefenseLawyerState].self, forKey: .defenseTeam) ?? []
        rivals = try c.decodeIfPresent([RivalGangState].self, forKey: .rivals) ?? []
        clamp()
    }
}

struct CrimeOperationResult: Equatable {
    var headline: String
    var detail: String
    var risk: CrimeRiskBreakdown
    var payout = 0
    var succeeded = false
    var healthDelta = 0
    var consequences: [DomainConsequence] = []
    var kitID: String?
    var kitAssetIDs: [UInt64] = []
    var stolenAssetName: String?
}

enum CrimeSystem {
    static let starterOperations: [CrimeOperationType] = [.burglary, .vehicleTheft, .fraud, .smuggling]
    static let soloOperations = starterOperations

    static let organizationStartupCost = 10_000
    static let gangStartupCost = 500

    static func canAccess(_ operation: CrimeOperationType, state: LifeState) -> Bool {
        guard state.character.age >= operation.minimumAge else { return false }
        guard let path = state.career.criminalPath else {
            return operation.isStarterOperation
        }
        guard path.isOrganization else { return operation.isStarterOperation }
        return path.rank.authority >= operation.minimumOrganizationAuthority
    }

    static func createCustomKit(name: String, state: inout LifeState) -> CriminalKit? {
        guard state.character.age >= 14 else { return nil }
        var path = ensurePath(state: &state)
        let kit = CriminalKit(id: "kit-\(path.customKits.count + 1)-\(state.character.age)", name: name.isEmpty ? "Personal operation kit" : name)
        path.customKits.append(kit)
        path.clamp()
        state.career.criminalPath = path
        return kit
    }

    static func setCustomKitAssets(kitID: String, personalAssetIDs: [UInt64], stolenAssetIDs: [UInt64] = [], state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath,
              let index = path.customKits.firstIndex(where: { $0.id == kitID }) else { return false }
        let validPersonal = personalAssetIDs.filter { id in
            state.assets.movableAssets.contains { $0.id == id && ($0.firearm != nil || $0.vehicle != nil) }
        }
        path.customKits[index].personalAssetIDs = validPersonal
        let validStolen = stolenAssetIDs.filter { id in path.stolenAssets.contains { $0.id == id } }
        var stolenSeen = Set<UInt64>()
        path.customKits[index].stolenAssetIDs = Array(validStolen.filter { stolenSeen.insert($0).inserted }.prefix(8))
        path.clamp()
        state.career.criminalPath = path
        return true
    }

    private static func stolenListingID(for operation: CrimeOperationType) -> String? {
        switch operation {
        case .vehicleTheft: return "car-used-compact"
        case .burglary: return "jewelry-diamond-ring"
        case .smuggling: return "gun-unregistered-handgun"
        default: return nil
        }
    }

    private static func appendStolenAsset(for operation: CrimeOperationType, path: inout CriminalPathState, age: Int) -> CriminalStolenAsset? {
        guard let listingID = stolenListingID(for: operation), let listing = AssetCatalog.listing(for: listingID) else { return nil }
        let value: Int
        switch listing.terms {
        case .cash(let price): value = max(1, price * 65 / 100)
        case .mortgage: return nil
        }
        let item = CriminalStolenAsset(id: path.nextStolenAssetID, listingID: listing.id, name: listing.name, category: listing.category, estimatedValue: value, acquiredAge: age)
        path.nextStolenAssetID &+= 1
        path.stolenAssets.append(item)
        path.clamp()
        return item
    }

    static func resolveStolenKitUse(kitID: String?, succeeded: Bool, risk: Int, state: inout LifeState) -> String? {
        guard var path = state.career.criminalPath,
              let kitID,
              let kitIndex = path.customKits.firstIndex(where: { $0.id == kitID }) else { return nil }
        let ids = path.customKits[kitIndex].stolenAssetIDs
        guard !ids.isEmpty else { return nil }
        for index in path.stolenAssets.indices where ids.contains(path.stolenAssets[index].id) {
            path.stolenAssets[index].condition = max(0, path.stolenAssets[index].condition - (succeeded ? 1 : 8))
        }
        path.customKits[kitIndex].lastUsedAge = state.character.age
        if !succeeded && risk >= 78, let lostID = ids.sorted().first,
           let lostIndex = path.stolenAssets.firstIndex(where: { $0.id == lostID }) {
            let lost = path.stolenAssets.remove(at: lostIndex)
            path.customKits[kitIndex].stolenAssetIDs.removeAll { $0 == lostID }
            path.clamp(); state.career.criminalPath = path
            return "The operation lost the stolen \(lost.name) from the kit."
        }
        path.clamp(); state.career.criminalPath = path
        return succeeded ? "The stolen kit came through with light wear." : "The stolen kit took heavy wear while the operation went wrong."
    }

    static func recoverStolenAsset(id: UInt64, state: inout LifeState) -> Int? {
        guard var path = state.career.criminalPath,
              !path.customKits.contains(where: { $0.stolenAssetIDs.contains(id) }),
              let index = path.stolenAssets.firstIndex(where: { $0.id == id }) else { return nil }
        let item = path.stolenAssets.remove(at: index)
        path.customKits.indices.forEach { path.customKits[$0].stolenAssetIDs.removeAll { $0 == id } }
        path.heat = min(100, path.heat + 2)
        path.notoriety = min(100, path.notoriety + 1)
        path.clamp(); state.career.criminalPath = path
        return max(1, item.estimatedValue * 30 / 100)
    }

    static func convertStolenAsset(id: UInt64, route: CriminalAssetConversionRoute, state: inout LifeState) -> Int? {
        guard var path = state.career.criminalPath,
              !path.customKits.contains(where: { $0.stolenAssetIDs.contains(id) }),
              let index = path.stolenAssets.firstIndex(where: { $0.id == id }) else { return nil }
        if route == .frontBusiness && (!path.isOrganization || path.frontBusiness == nil) { return nil }
        let item = path.stolenAssets.remove(at: index)
        let base = item.estimatedValue * item.condition / 100
        let proceeds = max(1, base * (route == .frontBusiness ? 45 : 30) / 100)
        path.heat = min(100, path.heat + (route == .frontBusiness ? 1 : 3))
        path.notoriety = min(100, path.notoriety + (route == .frontBusiness ? 0 : 1))
        path.clamp(); state.career.criminalPath = path
        return proceeds
    }

    static func purchaseKitEquipment(kitID: String, amount: Int, state: inout LifeState) -> Int? {
        guard amount > 0, var path = state.career.criminalPath,
              path.customKits.contains(where: { $0.id == kitID }) else { return nil }
        guard state.cash >= amount else { return nil }
        guard let index = path.customKits.firstIndex(where: { $0.id == kitID }) else { return nil }
        path.customKits[index].purchasedEquipment = min(25_000, path.customKits[index].purchasedEquipment + amount)
        path.clamp(); state.career.criminalPath = path
        return amount
    }

    static func consumeKitEquipment(kitID: String?, succeeded: Bool, state: inout LifeState) -> Int {
        guard var path = state.career.criminalPath, let kitID,
              let index = path.customKits.firstIndex(where: { $0.id == kitID }),
              path.customKits[index].purchasedEquipment > 0 else { return 0 }
        let used = min(path.customKits[index].purchasedEquipment, succeeded ? 250 : 400)
        path.customKits[index].purchasedEquipment -= used
        path.clamp(); state.career.criminalPath = path
        return used
    }

    static func kitReadiness(for plan: CrimePlan, state: LifeState) -> CriminalKitReadiness {
        let requirement: (String, AssetCategory?)
        switch plan.operation {
        case .vehicleTheft, .kidnapping: requirement = ("a vehicle", .cars)
        case .burglary: requirement = ("a valuable item", .jewelry)
        case .smuggling, .murder: requirement = ("a firearm", .guns)
        case .robbery, .territoryAttack: requirement = ("a protected weapon or vehicle", nil)
        case .fraud, .extortion: requirement = ("purchased equipment", nil)
        }
        let path = state.career.criminalPath ?? CriminalPathState()
        guard let kit = plan.kitID.flatMap({ id in path.customKits.first { $0.id == id } }) else {
            return CriminalKitReadiness(requirement: requirement.0, matched: false, condition: 0, riskAdjustment: requirement.1 == nil ? 2 : 5)
        }
        let personal = state.assets.movableAssets.filter { kit.personalAssetIDs.contains($0.id) }.map(\.category)
        let stolen = path.stolenAssets.filter { kit.stolenAssetIDs.contains($0.id) }.map(\.category)
        let categories = personal + stolen
        let matched: Bool
        if let requiredCategory = requirement.1 {
            matched = categories.contains(requiredCategory)
        } else {
            matched = kit.purchasedEquipment >= 500
        }
        let conditionValues = state.assets.movableAssets.filter { kit.personalAssetIDs.contains($0.id) }.compactMap { asset in
            asset.firearm?.condition ?? asset.vehicle?.condition
        } + path.stolenAssets.filter { kit.stolenAssetIDs.contains($0.id) }.map(\.condition)
        let condition = conditionValues.isEmpty ? (matched ? 80 : 0) : conditionValues.reduce(0, +) / conditionValues.count
        let risk = matched ? (condition < 45 ? 4 : -4) : (requirement.1 == nil && kit.purchasedEquipment >= 500 ? -3 : 6)
        return CriminalKitReadiness(requirement: requirement.0, matched: matched, condition: condition, riskAdjustment: risk)
    }

    static func setSoloKit(kitID: String?, state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath,
              kitID == nil || path.customKits.contains(where: { $0.id == kitID }) else { return false }
        path.soloKitID = kitID
        state.career.criminalPath = path
        return true
    }

    static func assignKitToPlan(planID: String, kitID: String?, state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath,
              let planIndex = path.plans.firstIndex(where: { $0.id == planID }) else { return false }
        guard kitID == nil || path.customKits.contains(where: { $0.id == kitID }) else { return false }
        path.plans[planIndex].kitID = kitID
        path.clamp()
        state.career.criminalPath = path
        return true
    }

    static func setPlanApproach(planID: String, approach: CrimeApproach, state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath,
              let planIndex = path.plans.firstIndex(where: { $0.id == planID }) else { return false }
        path.plans[planIndex].approach = approach
        path.plans[planIndex].lastRisk = nil
        path.clamp()
        state.career.criminalPath = path
        return true
    }

    /// Finance is charged by LifeSimulator; CrimeSystem owns the preparation state.
    static func preparePlan(planID: String, state: inout LifeState) -> Int? {
        guard var path = state.career.criminalPath,
              let planIndex = path.plans.firstIndex(where: { $0.id == planID }),
              path.plans[planIndex].preparation < 20 else { return nil }
        let current = path.plans[planIndex].preparation
        let cost = 250 + current * 50
        guard state.cash >= cost else { return nil }
        path.plans[planIndex].preparation = min(20, current + 4)
        path.plans[planIndex].lastRisk = nil
        path.clamp()
        state.career.criminalPath = path
        return cost
    }

    static func defaultSpecialists() -> [SpecialistState] {
        [
            SpecialistState(id: "planner", name: "Mara Velez", role: .planner, competence: 58, loyalty: 56, fear: 40, respect: 54, ambition: 48, poachingRisk: 18, relationship: 8),
            SpecialistState(id: "driver", name: "Darius Cole", role: .driver, competence: 62, loyalty: 52, fear: 46, respect: 50, ambition: 42, poachingRisk: 22, relationship: 5),
            SpecialistState(id: "enforcer", name: "Rico Bell", role: .enforcer, competence: 55, loyalty: 64, fear: 62, respect: 60, ambition: 55, poachingRisk: 14, relationship: 10),
            SpecialistState(id: "technician", name: "Nina Shah", role: .technician, competence: 66, loyalty: 45, fear: 28, respect: 46, ambition: 61, poachingRisk: 30, relationship: 0),
            SpecialistState(id: "broker", name: "Cal Mercer", role: .broker, competence: 57, loyalty: 49, fear: 34, respect: 52, ambition: 58, poachingRisk: 26, relationship: 4),
            SpecialistState(id: "lookout", name: "June Park", role: .lookout, competence: 51, loyalty: 60, fear: 38, respect: 44, ambition: 35, poachingRisk: 16, relationship: 6)
        ]
    }

    static func defaultRivals() -> [RivalGangState] {
        [
            RivalGangState(id: "rival-east", name: "East Borough Crew", relationship: -20, hatred: 35, fear: 20, strength: 58, territory: 18, retaliation: 55),
            RivalGangState(id: "rival-docks", name: "Docks Collective", relationship: 5, hatred: 18, fear: 10, strength: 46, territory: 12, retaliation: 35)
        ]
    }

    static func ensurePath(state: inout LifeState) -> CriminalPathState {
        if state.career.criminalPath == nil { state.career.criminalPath = CriminalPathState() }
        return state.career.criminalPath!
    }

    static func joinExistingGang(name: String, state: inout LifeState) -> Bool {
        guard state.character.age >= 14 else { return false }
        var path = ensurePath(state: &state)
        guard !path.isOrganization else { return false }
        guard path.notoriety >= 5 || state.aggregates.soloCrimeAttempts > 0 else { return false }
        path.mode = .gangMember; path.rank = .member; path.gangName = name.isEmpty ? "The local crew" : name
        path.gangTrust = 35; path.cashFlow = 350; path.influence = 12
        path.specialists = Array(defaultSpecialists().prefix(3))
        path.successionOrder = path.specialists.map(\.id)
        path.rivals = defaultRivals()
        path.clamp(); state.career.criminalPath = path
        return true
    }

    /// Assigns the player's one street-level specialty after the gang has
    /// appointed them into its rank structure. Syndicate management remains a
    /// separate path and does not use this choice.
    static func chooseGangSpecialty(_ specialty: CriminalSpecialty, state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath,
              path.mode == .gangMember,
              path.rank != .solo else { return false }
        guard path.gangSpecialty == nil else { return false }
        path.gangSpecialty = specialty
        path.gangSpecialtySkill = 12
        path.proficiencies[specialty.proficiencyKey] = path.gangSpecialtySkill
        path.clamp()
        state.career.criminalPath = path
        return true
    }

    static func performGangSpecialtyWork(state: inout LifeState) -> CrimeOperationResult? {
        guard var path = state.career.criminalPath,
              path.mode == .gangMember,
              let specialty = path.gangSpecialty,
              path.lastSpecialtyWorkAge != state.character.age else { return nil }

        let risk = CrimeRiskBreakdown(
            operation: specialty.exposureRisk + max(0, 12 - path.gangTrust / 10),
            task: specialty == .enforcer ? 8 : 4,
            competence: max(0, path.gangSpecialtySkill - 35) / 3,
            loyalty: max(0, path.gangTrust - 45) / 12,
            heat: path.heat / 8,
            preparation: path.gangSpecialtySkill / 12
        )
        let succeeded = state.randomStreams.action.next(in: 1...100) > risk.total
        let payout = succeeded ? specialty.annualIncome / 4 + path.gangSpecialtySkill * 5 + path.gangTrust * 2 : 0
        path.lastSpecialtyWorkAge = state.character.age
        path.gangSpecialtySkill = min(100, path.gangSpecialtySkill + (succeeded ? 3 : 1))
        path.proficiencies[specialty.proficiencyKey] = path.gangSpecialtySkill
        path.heat = min(100, path.heat + (succeeded ? max(1, specialty.exposureRisk / 3) : specialty.exposureRisk / 2))
        if succeeded { path.notoriety = min(100, path.notoriety + 1) }
        path.clamp()
        state.career.criminalPath = path

        let consequence = DomainConsequence(
            source: .legal,
            target: .career,
            kind: .legalTrouble,
            magnitude: succeeded ? .minor : .major,
            openedAge: state.character.age,
            yearsRemaining: succeeded ? 1 : 3,
            headline: "Street work changed your exposure",
            detail: "Your assigned gang specialty brought money, attention, and a clearer place in the organization."
        )
        let detail = succeeded
            ? "The gang's network put your specialty to work and paid your cut."
            : "The job went wrong before the gang could protect your position."
        return CrimeOperationResult(
            headline: succeeded ? "Specialty Work Paid" : "Specialty Work Went Wrong",
            detail: detail,
            risk: risk,
            payout: payout,
            succeeded: succeeded,
            consequences: [consequence]
        )
    }

    static func startDrugEnterprise(state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath, path.canManageDrugEnterprise,
              path.drugEnterprise == nil else { return false }
        path.drugEnterprise = DrugEnterpriseState(active: true)
        path.influence = min(100, path.influence + 5)
        path.clamp(); state.career.criminalPath = path
        return true
    }

    static func recruitDrugEnterpriseRole(_ role: DrugEnterpriseRole, state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath, path.canManageDrugEnterprise,
              var enterprise = path.drugEnterprise, enterprise.active else { return false }
        switch role {
        case .mule: enterprise.mules += 1
        case .runner: enterprise.runners += 1
        case .supplyRetriever: enterprise.supplyRetrievers += 1
        }
        enterprise.clamp()
        path.drugEnterprise = enterprise
        path.clamp(); state.career.criminalPath = path
        return true
    }

    static func improveDrugFormula(state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath, path.canManageDrugEnterprise,
              var enterprise = path.drugEnterprise, enterprise.active,
              enterprise.productQuality < 100 else { return false }
        enterprise.productQuality += 8
        enterprise.demand += 3
        enterprise.networkCoverage += 2
        enterprise.clamp()
        path.drugEnterprise = enterprise
        path.heat = min(100, path.heat + 2)
        path.clamp(); state.career.criminalPath = path
        return true
    }

    static func manageDrugEnterprise(state: inout LifeState) -> DrugEnterpriseOutcome? {
        guard var path = state.career.criminalPath, path.canManageDrugEnterprise,
              var enterprise = path.drugEnterprise, enterprise.active,
              enterprise.lastManagedAge != state.character.age else { return nil }
        let staffing = enterprise.mules * 3 + enterprise.runners * 4 + enterprise.supplyRetrievers * 5
        let risk = CrimeRiskBreakdown(
            operation: max(18, 48 - enterprise.supplyReliability / 3 - enterprise.networkCoverage / 4),
            task: max(3, 16 - staffing / 3),
            competence: path.specialists.filter(\.isAvailable).map(\.competence).max().map { max(0, $0 - 35) / 4 } ?? 0,
            loyalty: max(0, path.gangTrust - 45) / 12,
            heat: path.heat / 7,
            rival: path.rivals.map { max(0, $0.hatred - $0.fear) / 20 }.max() ?? 0,
            preparation: enterprise.productQuality / 15
        )
        let succeeded = state.randomStreams.action.next(in: 1...100) > risk.total
        let payout = succeeded ? 800 + enterprise.demand * 12 + enterprise.productQuality * 6 + staffing * 20 : 0
        enterprise.lastManagedAge = state.character.age
        enterprise.totalRevenue += payout
        enterprise.demand = min(100, enterprise.demand + (succeeded ? 2 : -5))
        enterprise.supplyReliability = min(100, max(0, enterprise.supplyReliability + (succeeded ? 2 : -8)))
        enterprise.networkCoverage = min(100, max(0, enterprise.networkCoverage + (succeeded ? 2 : -3)))
        path.drugEnterprise = enterprise
        path.heat = min(100, path.heat + (succeeded ? 8 : 15))
        path.notoriety = min(100, path.notoriety + (succeeded ? 4 : 1))
        path.gangTrust = min(100, max(0, path.gangTrust + (succeeded ? 2 : -4)))
        path.clamp(); state.career.criminalPath = path

        let relationshipsDelta: Int = enterprise.runners + enterprise.mules >= 3 ? -2 : -1
        let healthDelta = enterprise.productQuality >= 70 ? -2 : -1
        let repDelta = succeeded ? 2 : -1
        var consequences = [
            DomainConsequence(source: .career, target: .health, kind: .burnout, magnitude: .minor, openedAge: state.character.age, yearsRemaining: 1, headline: "The enterprise took a physical toll", detail: "Managing a high-risk operation left less room for recovery."),
            DomainConsequence(source: .career, target: .relationships, kind: .burnout, magnitude: .minor, openedAge: state.character.age, yearsRemaining: 2, headline: "The enterprise followed you home", detail: "The people around you noticed the secrecy, pressure, and missing time.")
        ]
        if !succeeded {
            consequences.append(DomainConsequence(source: .career, target: .legal, kind: .legalTrouble, magnitude: .major, openedAge: state.character.age, yearsRemaining: 3, headline: "The enterprise became harder to hide", detail: "A failed operation increased the chance that the organization and its network will be investigated."))
        }
        return DrugEnterpriseOutcome(
            headline: succeeded ? "The Drug Enterprise Expanded" : "The Drug Enterprise Faltered",
            detail: succeeded ? "The organization moved product through its network and collected a larger management share." : "Supply and distribution broke down, damaging trust and drawing attention.",
            risk: risk,
            payout: payout,
            succeeded: succeeded,
            healthDelta: healthDelta,
            relationshipsDelta: relationshipsDelta,
            repDelta: repDelta,
            consequences: consequences
        )
    }

    /// The gang appoints rank during the yearly tick. The player can improve
    /// the inputs through their specialty, but cannot directly select a rank.
    private static func resolveGangAppointment(path: inout CriminalPathState, result: inout SystemYearDeltas) {
        guard path.mode == .gangMember else { return }
        let skill = path.gangSpecialtySkill
        let trust = path.gangTrust
        let canAdvance: Bool
        switch path.rank {
        case .member:
            canAdvance = skill >= 25 && trust >= 45
        case .specialist:
            canAdvance = skill >= 50 && trust >= 60 && path.notoriety >= 15
        case .lieutenant:
            canAdvance = skill >= 70 && trust >= 70 && path.notoriety >= 25 && path.influence >= 20
        default:
            canAdvance = false
        }

        if canAdvance {
            switch path.rank {
            case .member:
                path.rank = .specialist
                result.bullets.append("The gang appointed you as a specialist")
            case .specialist:
                path.rank = .lieutenant
                result.bullets.append("The gang appointed you as a lieutenant")
            case .lieutenant:
                path.rank = .leader
                path.mode = .gangLeader
                path.gangTrust = max(path.gangTrust, 75)
                result.bullets.append("The gang appointed you as its leader")
            default:
                break
            }
            return
        }

        guard path.heat >= 82 || path.gangTrust < 20 else { return }
        switch path.rank {
        case .lieutenant:
            path.rank = .specialist
            result.notes.append("The gang stripped you of lieutenant authority.")
        case .specialist:
            path.rank = .member
            result.notes.append("The gang reduced you to a regular member.")
        default:
            break
        }
    }

    static func startIndependentOrganization(name: String, state: inout LifeState) -> Bool {
        guard state.character.age >= 18 else { return false }
        var path = ensurePath(state: &state)
        guard !path.isOrganization else { return false }
        guard state.cash >= organizationStartupCost else { return false }
        guard path.notoriety >= 20 || state.aggregates.soloCrimeAttempts >= 3 else { return false }
        path.mode = .enterprise; path.rank = .enterpriseLeader; path.gangName = name.isEmpty ? "Independent organization" : name
        path.gangTrust = 55; path.cashFlow = 1_250; path.influence = 20; path.territory = 5
        path.specialists = defaultSpecialists(); path.successionOrder = path.specialists.map(\.id)
        path.rivals = defaultRivals()
        path.clamp(); state.career.criminalPath = path
        return true
    }

    static func promoteToLeader(state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath, path.mode == .gangMember else { return false }
        path.mode = .gangLeader; path.rank = .leader; path.gangTrust = max(path.gangTrust, 60)
        if path.specialists.isEmpty { path.specialists = defaultSpecialists() }
        path.successionOrder = path.specialists.map(\.id)
        path.clamp(); state.career.criminalPath = path
        return true
    }

    static func createPlan(operation: CrimeOperationType, state: inout LifeState) -> CrimePlan? {
        guard var path = state.career.criminalPath, path.isOrganization else { return nil }
        guard canAccess(operation, state: state) else { return nil }
        if path.specialists.isEmpty { path.specialists = defaultSpecialists() }
        var plan = path.plans.first { $0.operation == operation }
            ?? CrimePlan(id: "plan-\(operation.rawValue)", operation: operation)
        let definition = CrimeOperationDefinition.definition(for: operation)
        for task in definition.tasks where plan.assignments[task] == nil {
            if let specialist = path.specialists.first(where: { $0.isAvailable && definition.preferredRoles.contains($0.role) }) {
                plan.assignments[task] = specialist.id
            }
        }
        path.plans.removeAll { $0.id == plan.id }; path.plans.append(plan); path.clamp()
        state.career.criminalPath = path
        return plan
    }

    static func executePlan(id: String, state: inout LifeState) -> CrimeOperationResult? {
        guard var path = state.career.criminalPath, path.isOrganization,
              let index = path.plans.firstIndex(where: { $0.id == id }) else { return nil }
        var plan = path.plans[index]
        guard canAccess(plan.operation, state: state) else { return nil }
        let risk = risk(for: plan, state: state)
        let success = state.randomStreams.action.next(in: 1...100) > risk.total
        let definition = CrimeOperationDefinition.definition(for: plan.operation)
        let payout = success ? adjustedPayout(plan.operation.basePayout + plan.mastery * 10, operation: definition, approach: plan.approach) : 0
        plan.lastRisk = risk; plan.lastExecutedAge = state.character.age
        plan.lastOutcome = success ? "Success" : "Failure"
        plan.mastery = min(100, plan.mastery + (success ? 5 : 2)); plan.exposure = min(100, plan.exposure + 4)
        path.repeatedOperations[plan.operation.rawValue, default: 0] += 1
        path.equipment.condition = max(0, path.equipment.condition - 3)
        path.heat = min(100, path.heat + (success ? definition.successHeat : definition.failureHeat))
        path.notoriety = min(100, path.notoriety + (success ? 4 : 1))
        for specialistID in plan.assignments.values {
            guard let specialistIndex = path.specialists.firstIndex(where: { $0.id == specialistID }) else { continue }
            path.specialists[specialistIndex].operationExperience[plan.operation.rawValue, default: 0] += 1
            if success { path.specialists[specialistIndex].competence = min(100, path.specialists[specialistIndex].competence + 1) }
        }
        path.plans[index] = plan
        let stolenAsset = success ? appendStolenAsset(for: plan.operation, path: &path, age: state.character.age) : nil
        path.clamp(); state.career.criminalPath = path
        let consequence = DomainConsequence(source: .legal, target: .career, kind: .legalTrouble, magnitude: success ? .minor : .major, openedAge: state.character.age, yearsRemaining: success ? 2 : 4, headline: "The organization drew attention", detail: "A planned operation changed the organization's risk profile.")
        let kitAssetIDs = plan.kitID.flatMap { kitID in path.customKits.first { $0.id == kitID }?.personalAssetIDs } ?? []
        let detail = success ? (stolenAsset.map { "The crew completed the plan and recovered \($0.name) into criminal inventory." } ?? "The crew completed the plan and gained experience.") : "The crew failed to execute the plan cleanly."
        return CrimeOperationResult(headline: success ? "Operation Succeeded" : "Operation Failed", detail: detail, risk: risk, payout: payout, succeeded: success, healthDelta: success ? 0 : -definition.failureHealth, consequences: [consequence], kitID: plan.kitID, kitAssetIDs: kitAssetIDs, stolenAssetName: stolenAsset?.name)
    }

    static func delegateIndividualTask(specialistID: String, operation: CrimeOperationType, state: inout LifeState) -> CrimeOperationResult? {
        guard var path = state.career.criminalPath, path.isOrganization,
              canAccess(operation, state: state),
              let specialistIndex = path.specialists.firstIndex(where: { $0.id == specialistID && $0.isAvailable }) else { return nil }
        let specialist = path.specialists[specialistIndex]
        var risk = CrimeRiskBreakdown(operation: operation.baseRisk, task: 10, competence: max(0, specialist.competence - 35) / 3, loyalty: max(0, specialist.loyalty - 45) / 10, equipment: max(0, 10 - path.equipment.effectiveness / 8), heat: path.heat / 8, repetition: path.repeatedOperations[operation.rawValue, default: 0] / 3, informant: specialist.poachingRisk / 20, rival: path.rivals.map { max(0, $0.hatred - $0.fear) / 25 }.max() ?? 0, preparation: 0)
        let refused = specialist.loyalty < 25 && state.randomStreams.action.next(in: 1...100) <= 35
        let success = !refused && state.randomStreams.action.next(in: 1...100) > risk.total
        path.repeatedOperations[operation.rawValue, default: 0] += 1
        path.heat = min(100, path.heat + (success ? operation.baseRisk / 12 : operation.baseRisk / 7))
        path.notoriety = min(100, path.notoriety + (success ? 3 : 1))
        path.equipment.condition = max(0, path.equipment.condition - 2)
        path.specialists[specialistIndex].operationExperience[operation.rawValue, default: 0] += 1
        if success {
            path.specialists[specialistIndex].competence = min(100, specialist.competence + 2)
            path.specialists[specialistIndex].relationship = min(100, specialist.relationship + 2)
        } else if refused || specialist.loyalty < 35 {
            path.specialists[specialistIndex].loyalty = max(0, specialist.loyalty - 4)
            if specialist.loyalty < 20 && state.randomStreams.action.next(in: 1...100) <= 10 { path.specialists[specialistIndex].hasDefected = true }
        }
        path.clamp(); state.career.criminalPath = path
        risk.rival = path.rivals.map { max(0, $0.hatred - $0.fear) / 25 }.max() ?? 0
        let detail = refused ? "The specialist refused the task, and the refusal weakened the chain of command." : success ? "The specialist completed the task and gained experience." : "The specialist failed or was compromised while carrying out the task."
        return CrimeOperationResult(headline: refused ? "The Specialist Refused" : success ? "Delegated Task Succeeded" : "Delegated Task Failed", detail: detail, risk: risk, payout: success ? operation.basePayout / 2 : 0, succeeded: success)
    }

    static func buildSpecialistRelationship(_ specialistID: String, state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath,
              let index = path.specialists.firstIndex(where: { $0.id == specialistID }) else { return false }
        var specialist = path.specialists[index]
        specialist.relationship = min(100, specialist.relationship + 8)
        specialist.loyalty = min(100, specialist.loyalty + (specialist.relationship >= 40 ? 2 : 1))
        if specialist.relationship >= 16 { specialist.knownFacts.insert("competence") }
        if specialist.relationship >= 40 { specialist.knownFacts.insert("loyalty") }
        if specialist.relationship >= 60 { specialist.knownFacts.insert("fear-respect") }
        if specialist.relationship >= 80 { specialist.knownFacts.insert("ambition-poaching") }
        path.specialists[index] = specialist
        path.clamp(); state.career.criminalPath = path
        return true
    }

    static func rewardSpecialist(_ specialistID: String, state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath,
              let index = path.specialists.firstIndex(where: { $0.id == specialistID && $0.isAvailable }) else { return false }
        path.specialists[index].loyalty = min(100, path.specialists[index].loyalty + 6)
        path.specialists[index].relationship = min(100, path.specialists[index].relationship + 4)
        path.organizationMorale = min(100, path.organizationMorale + 2)
        path.clamp(); state.career.criminalPath = path
        return true
    }

    static func negotiateWithRival(_ rivalID: String, state: inout LifeState) -> Bool {
        guard var path = state.career.criminalPath, path.isOrganization,
              let index = path.rivals.firstIndex(where: { $0.id == rivalID }) else { return false }
        path.rivals[index].relationship = min(100, path.rivals[index].relationship + 12)
        path.rivals[index].hatred = max(0, path.rivals[index].hatred - 8)
        path.rivals[index].retaliation = max(0, path.rivals[index].retaliation - 10)
        path.organizationMorale = min(100, path.organizationMorale + 2)
        path.clamp(); state.career.criminalPath = path
        return true
    }

    static func attackRival(_ rivalID: String, state: inout LifeState) -> CrimeOperationResult? {
        guard var path = state.career.criminalPath, path.isOrganization,
              let index = path.rivals.firstIndex(where: { $0.id == rivalID }) else { return nil }
        let rival = path.rivals[index]
        let available = path.specialists.filter(\.isAvailable)
        let competence = available.isEmpty ? 20 : available.map(\.competence).reduce(0, +) / available.count
        let risk = CrimeRiskBreakdown(operation: CrimeOperationType.territoryAttack.baseRisk, task: 16, competence: max(0, competence - 35) / 3, loyalty: available.isEmpty ? 0 : available.map(\.loyalty).reduce(0, +) / 20, equipment: max(0, 10 - path.equipment.effectiveness / 8), heat: path.heat / 8, rival: max(0, rival.strength + rival.hatred - path.influence) / 5)
        let success = state.randomStreams.action.next(in: 1...100) > risk.total
        path.rivals[index].relationship = max(-100, path.rivals[index].relationship - 25)
        path.rivals[index].hatred = min(100, path.rivals[index].hatred + 15)
        path.rivals[index].retaliation = min(100, path.rivals[index].retaliation + 15)
        if success {
            path.territory = min(100, path.territory + 5); path.influence = min(100, path.influence + 4)
            path.rivals[index].strength = max(0, path.rivals[index].strength - 10)
        } else {
            path.territory = max(0, path.territory - 3); path.organizationMorale = max(0, path.organizationMorale - 8)
        }
        path.heat = min(100, path.heat + (success ? 8 : 14)); path.clamp(); state.career.criminalPath = path
        return CrimeOperationResult(headline: success ? "Territory Taken" : "The Rival Struck Back", detail: success ? "The rival lost ground, but the conflict is now more visible." : "The attack failed and the rival gained a reason to retaliate.", risk: risk, succeeded: success)
    }

    static func setSuccessionOrder(_ ids: [String], state: inout LifeState) {
        guard var path = state.career.criminalPath else { return }
        path.successionOrder = ids; path.clamp(); state.career.criminalPath = path
    }

    static func setActingLeader(_ id: String, state: inout LifeState) {
        guard var path = state.career.criminalPath,
              path.specialists.contains(where: { $0.id == id && $0.isAvailable }) else { return }
        path.actingLeaderID = id
        path.successionOrder.removeAll { $0 == id }; path.successionOrder.insert(id, at: 0)
        path.clamp(); state.career.criminalPath = path
    }

    static func syncAbsenceWithPrison(state: inout LifeState) {
        guard var path = state.career.criminalPath, path.isOrganization else { return }
        if state.prison.isIncarcerated {
            path.organizationAbsent = true
            let valid = path.successionOrder.compactMap { id in path.specialists.first { $0.id == id && $0.isAvailable } }
            let fallback = path.specialists.filter(\.isAvailable).sorted {
                if $0.role == .lieutenant && $1.role != .lieutenant { return true }
                return $0.competence > $1.competence
            }
            path.actingLeaderID = valid.first?.id ?? fallback.first?.id
        } else if path.organizationAbsent {
            path.organizationAbsent = false
            path.actingLeaderID = nil
        }
        path.clamp(); state.career.criminalPath = path
    }

    static func acquireSafehouse(name: String, state: inout LifeState) {
        guard var path = state.career.criminalPath, path.isOrganization else { return }
        path.safehouses.append(SafehouseState(name: name.isEmpty ? "Back-room safehouse" : name, level: 1, concealment: 15, storage: 10, planning: 5))
        path.clamp(); state.career.criminalPath = path
    }

    static func acquireFrontBusiness(name: String, state: inout LifeState) {
        guard var path = state.career.criminalPath, path.isOrganization else { return }
        path.frontBusiness = FrontBusinessState(name: name.isEmpty ? "Cash business" : name, acquired: true, operatingBudget: 500, staffing: 1, legitimateCashFlow: 150, heatReduction: 3, inspectionPressure: 10, linkedBusinessID: nil)
        path.clamp(); state.career.criminalPath = path
    }

    static func applyLegalImpact(_ impact: EnterpriseLegalImpact, state: inout LifeState) {
        guard var path = state.career.criminalPath else { return }
        path.organizationMorale = min(100, max(0, path.organizationMorale + impact.organizationMoraleDelta))
        path.cashFlow = max(-10_000, path.cashFlow + impact.organizationCashFlowDelta)
        path.heat = min(100, max(0, path.heat + impact.organizationHeatDelta))
        if impact.specialistLoyaltyDelta != 0 {
            for index in path.specialists.indices where !path.specialists[index].isArrested {
                path.specialists[index].loyalty = min(100, max(0, path.specialists[index].loyalty + impact.specialistLoyaltyDelta))
            }
        }
        for specialistID in impact.unavailableSpecialistIDs {
            if let index = path.specialists.firstIndex(where: { $0.id == specialistID }) {
                path.specialists[index].isArrested = true
            }
        }
        if var front = path.frontBusiness {
            front.legalScrutiny = min(100, max(0, front.legalScrutiny + impact.frontBusinessScrutinyDelta))
            if impact.frontBusinessClosureYears > 0 {
                front.closureYearsRemaining = max(front.closureYearsRemaining, impact.frontBusinessClosureYears)
                front.isLegallyRestricted = impact.frontBusinessRestricted
            }
            path.frontBusiness = front
        }
        path.clamp(); state.career.criminalPath = path
    }

    static func investInEquipment(state: inout LifeState) {
        guard var path = state.career.criminalPath, path.isOrganization else { return }
        path.equipment.budget += 1_000
        path.equipment.vehicleQuality = min(100, path.equipment.vehicleQuality + 8)
        path.equipment.weaponQuality = min(100, path.equipment.weaponQuality + 8)
        path.equipment.technicalQuality = min(100, path.equipment.technicalQuality + 8)
        path.equipment.concealmentQuality = min(100, path.equipment.concealmentQuality + 8)
        path.equipment.condition = min(100, path.equipment.condition + 10)
        path.clamp(); state.career.criminalPath = path
    }

    static func upgradeSafehouse(state: inout LifeState) {
        guard var path = state.career.criminalPath, let index = path.safehouses.indices.last else { return }
        path.safehouses[index].level = min(5, path.safehouses[index].level + 1)
        path.safehouses[index].concealment += 8; path.safehouses[index].storage += 8; path.safehouses[index].planning += 5
        path.clamp(); state.career.criminalPath = path
    }

    static func risk(for plan: CrimePlan, state: LifeState) -> CrimeRiskBreakdown {
        let path = state.career.criminalPath ?? CriminalPathState()
        let definition = CrimeOperationDefinition.definition(for: plan.operation)
        let assigned = plan.assignments.values.compactMap { id in path.specialists.first { $0.id == id && $0.isAvailable } }
        let competence = assigned.reduce(0) { $0 + max(0, $1.competence - 45) / 4 }
        let loyalty = assigned.isEmpty ? 0 : assigned.reduce(0) { $0 + max(0, $1.loyalty - 50) / 12 }
        let taskRisk = max(0, definition.tasks.count * 3 - assigned.count * 2)
        let kit = plan.kitID.flatMap { id in path.customKits.first { $0.id == id } }
        let referencedIDs = Set((kit?.personalAssetIDs ?? []) + (kit?.stolenAssetIDs ?? []))
        let referencedAssets = state.assets.movableAssets.filter { referencedIDs.contains($0.id) }
        let firearmBenefit = referencedAssets.compactMap(\.firearm).reduce(0) { total, firearm in
            total + firearm.upgrades.count + (firearm.secureStorage ? 1 : 0)
        }
        let vehicleBenefit = referencedAssets.compactMap(\.vehicle).reduce(0) { $0 + ($1.performance + $1.protection) / 6 }
        let kitBenefit = kit.map { min(12, firearmBenefit + vehicleBenefit + $0.purchasedEquipment / 2_000) } ?? 0
        let readiness = kitReadiness(for: plan, state: state)
        let equipmentRisk = max(0, 12 - path.equipment.effectiveness / 8 - kitBenefit + readiness.riskAdjustment)
        let repetition = min(20, plan.exposure / 4)
        let informant = assigned.reduce(0) { $0 + $1.poachingRisk / 25 }
        let heat = path.heat / 8
        let rival = path.rivals.map { max(0, $0.hatred - $0.fear) / 25 }.max() ?? 0
        let approachFit = definition.preferredApproaches.contains(plan.approach) ? -6 : 5
        return CrimeRiskBreakdown(operation: plan.operation.baseRisk, approach: plan.approach.riskAdjustment + approachFit, task: taskRisk, competence: competence, loyalty: loyalty, equipment: equipmentRisk, heat: heat, repetition: repetition, informant: informant, rival: rival, preparation: plan.preparation)
    }

    private static func adjustedPayout(_ amount: Int, operation: CrimeOperationDefinition, approach: CrimeApproach) -> Int {
        max(0, amount * operation.payoutMultiplierPercent / 100 * approach.payoutMultiplierPercent / 100)
    }

    static func executeSolo(operation: CrimeOperationType, state: inout LifeState) -> CrimeOperationResult {
        var path = ensurePath(state: &state)
        var plan = path.plans.first { $0.operation == operation && $0.assignments.isEmpty } ?? CrimePlan(id: "solo-\(operation.rawValue)", operation: operation)
        plan.kitID = path.soloKitID
        let risk = risk(for: plan, state: state)
        let roll = state.randomStreams.action.next(in: 1...100)
        let success = roll > risk.total
        let skill = path.proficiencies[operation.rawValue, default: 0]
        let definition = CrimeOperationDefinition.definition(for: operation)
        let notorietyGain = success ? (operation == .murder ? 9 : 3) : 1
        let heatGain = success ? definition.successHeat : definition.failureHeat
        let payout = success ? adjustedPayout(operation.basePayout + skill * 12, operation: definition, approach: plan.approach) : 0
        path.proficiencies[operation.rawValue] = min(100, skill + (success ? 5 : 2))
        path.notoriety = min(100, path.notoriety + notorietyGain)
        path.heat = min(100, path.heat + heatGain)
        path.repeatedOperations[operation.rawValue, default: 0] += 1
        path.lastSoloCrimeAge[operation.rawValue] = state.character.age
        plan.mastery = min(100, plan.mastery + (success ? 4 : 2)); plan.exposure = min(100, plan.exposure + 3)
        plan.lastRisk = risk; plan.lastExecutedAge = state.character.age
        plan.lastOutcome = success ? "Success" : "Failure"
        path.plans.removeAll { $0.id == plan.id }; path.plans.append(plan)
        let stolenAsset = success ? appendStolenAsset(for: operation, path: &path, age: state.character.age) : nil
        state.career.criminalPath = path
        NotorietySystem.adjust(notorietyGain, age: state.character.age, state: &state)
        let consequence = DomainConsequence(source: .legal, target: .career, kind: .legalTrouble, magnitude: operation == .murder ? .critical : .minor, openedAge: state.character.age, yearsRemaining: operation == .murder ? 6 : 2, headline: operation == .murder ? "A killing drew serious attention" : "Criminal exposure narrowed your options", detail: "Repeated criminal activity is changing the pressure around your work and future choices.")
        let kitAssetIDs = plan.kitID.flatMap { kitID in path.customKits.first { $0.id == kitID }?.personalAssetIDs } ?? []
        let detail: String
        if let stolenAsset { detail = "The operation paid $\(payout) and recovered \(stolenAsset.name) into criminal inventory. Skill grew, but the method left a clearer signature." }
        else if operation == .vehicleTheft { detail = success ? "The vehicle was moved, but no durable inventory was recovered." : "The vehicle theft failed. Heat and attention rose without a payout." }
        else if operation == .burglary { detail = success ? "The target yielded no durable inventory, but the operation paid $\(payout)." : "The burglary failed. Heat and attention rose without a payout." }
        else if operation == .smuggling { detail = success ? "The shipment moved, but no durable contraband entered inventory." : "The shipment was compromised. Heat and attention rose without a payout." }
        else { detail = success ? "The operation paid $\(payout). Skill grew, but the method left a clearer signature." : "The operation failed. Heat and attention rose without a payout." }
        return CrimeOperationResult(headline: success ? "\(operation.title) Succeeded" : "\(operation.title) Went Wrong", detail: detail, risk: risk, payout: payout, succeeded: success, healthDelta: success ? 0 : -definition.failureHealth, consequences: [consequence], kitID: plan.kitID, kitAssetIDs: kitAssetIDs, stolenAssetName: stolenAsset?.name)
    }

    static func resolveYear(state: inout LifeState) -> SystemYearDeltas {
        guard var path = state.career.criminalPath else { return SystemYearDeltas() }
        var result = SystemYearDeltas()
        if var front = path.frontBusiness, front.closureYearsRemaining > 0 {
            front.closureYearsRemaining -= 1
            if front.closureYearsRemaining == 0 { front.isLegallyRestricted = false; front.legalScrutiny = max(0, front.legalScrutiny - 8) }
            path.frontBusiness = front
        }
        let frontHeatReduction = path.frontBusiness?.isLegallyRestricted == true ? 0 : (path.frontBusiness?.heatReduction ?? 0)
        path.heat = max(0, path.heat - frontHeatReduction - 2)
        if path.isOrganization {
            let leaderID = path.actingLeaderID ?? path.successionOrder.first
            let leader = path.specialists.first { $0.id == leaderID && $0.isAvailable }
            let competence = leader?.competence ?? 25
            let loyalty = leader?.loyalty ?? 25
            let frontIncome = path.frontBusiness?.isLegallyRestricted == true ? 0 : (path.frontBusiness?.legitimateCashFlow ?? 0)
            let income = max(0, path.cashFlow + frontIncome + competence * 4 - max(0, 50 - loyalty) * 5)
            path.cashFlow = income
            result.deltas.cash += income
            result.bullets.append("Organization cash flow +$\(income)")
            if path.organizationAbsent { result.notes.append(competence >= 60 ? "The acting leader kept the organization moving." : "The organization struggled without you.") }
            if competence < 35 { path.organizationMorale -= 6; path.heat += 4 }
            if loyalty < 30 { path.organizationMorale -= 8; result.notes.append("Loyalty inside the organization weakened.") }
            for index in path.rivals.indices {
                let pressure = max(1, path.rivals[index].strength + path.rivals[index].retaliation / 2 - path.influence / 2)
                if state.randomStreams.action.next(in: 1...100) <= min(35, pressure / 5) {
                    path.territory = max(0, path.territory - 1)
                    path.organizationMorale = max(0, path.organizationMorale - 2)
                    result.notes.append("\(path.rivals[index].name) pressured your territory.")
                }
                for specialistIndex in path.specialists.indices where path.specialists[specialistIndex].isAvailable {
                    let poachChance = max(1, (path.rivals[index].strength + path.specialists[specialistIndex].poachingRisk - path.specialists[specialistIndex].loyalty) / 30)
                    if state.randomStreams.action.next(in: 1...100) <= poachChance {
                        path.specialists[specialistIndex].hasDefected = true
                        path.rivals[index].specialistsPoached += 1
                        path.organizationMorale = max(0, path.organizationMorale - 5)
                        result.notes.append("\(path.specialists[specialistIndex].name) was poached by \(path.rivals[index].name).")
                        break
                    }
                }
            }
        }
        if path.mode == .gangMember, let specialty = path.gangSpecialty {
            let specialtyIncome = specialty.annualIncome + path.gangSpecialtySkill * 4 + path.gangTrust * 2
            result.deltas.cash += specialtyIncome
            path.heat = min(100, path.heat + max(1, specialty.exposureRisk / 4))
            path.gangSpecialtySkill = min(100, path.gangSpecialtySkill + 3)
            path.proficiencies[specialty.proficiencyKey] = path.gangSpecialtySkill
            result.bullets.append("\(specialty.title) work paid $\(specialtyIncome)")
            if specialty == .drugManufacturer {
                result.deltas.health -= 1
                result.notes.append("Manufacturing work took a quiet toll on your health.")
            }
        }
        resolveGangAppointment(path: &path, result: &result)
        state.aggregates.recordIncome(result.deltas.cash, source: path.isOrganization ? .enterprise : .crime)
        path.clamp(); state.career.criminalPath = path
        return result
    }
}
