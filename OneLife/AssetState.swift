import Foundation

enum AssetCategory: String, Codable, CaseIterable, Identifiable {
    case guns, cars, houses, jewelry

    var id: String { rawValue }
    var title: String { self == .cars ? "Vehicles" : rawValue.capitalized }
    var symbol: String {
        switch self {
        case .guns: "scope"
        case .cars: "car.fill"
        case .houses: "house.fill"
        case .jewelry: "diamond.fill"
        }
    }
}

enum AssetPurchaseTerms: Codable, Equatable {
    case cash(price: Int)
    case mortgage(value: Int, downPayment: Int, annualCost: Int, minimumCareerLevel: CareerLevel)

    var committedCash: Int {
        switch self {
        case .cash(let price): price
        case .mortgage(_, let downPayment, _, _): downPayment
        }
    }
}

enum FirearmMarket: String, Codable, CaseIterable, Identifiable {
    case legal
    case illicit

    var id: String { rawValue }
    var title: String { self == .legal ? "Legal market" : "Illegal market" }
}

enum FirearmRarity: String, Codable, CaseIterable {
    case common, uncommon, rare, contraband

    var acquisitionChance: Int {
        switch self {
        case .common: 100
        case .uncommon: 82
        case .rare: 55
        case .contraband: 30
        }
    }
}

struct FirearmListingMetadata: Equatable {
    let market: FirearmMarket
    let rarity: FirearmRarity
    let heat: Int
}

enum FirearmUpgradeID: String, Codable, CaseIterable, Identifiable {
    case optic
    case extendedMagazine
    case flashlight
    case conversionSwitch

    var id: String { rawValue }
}

struct FirearmUpgradeDefinition: Identifiable, Equatable {
    let id: FirearmUpgradeID
    let name: String
    let detail: String
    let price: Int
    let market: FirearmMarket
    let rarity: FirearmRarity
    let heat: Int
}

enum FirearmUpgradeCatalog {
    static let all: [FirearmUpgradeDefinition] = [
        .init(id: .optic, name: "Optic / scope", detail: "A lawful sighting accessory; no use simulation is added.", price: EconomyPolicy.assetQuote("optic.price"), market: .legal, rarity: .common, heat: 0),
        .init(id: .extendedMagazine, name: "Extended magazine", detail: "A restricted capacity upgrade represented only as legal exposure.", price: EconomyPolicy.assetQuote("extendedMagazine.price"), market: .illicit, rarity: .rare, heat: 7),
        .init(id: .flashlight, name: "Weapon flashlight", detail: "A lawful low-light accessory represented as a kit utility modifier.", price: EconomyPolicy.assetQuote("flashlight.price"), market: .legal, rarity: .common, heat: 0),
        .init(id: .conversionSwitch, name: "Conversion switch", detail: "A prohibited modification with severe legal exposure; no operational detail is simulated.", price: EconomyPolicy.assetQuote("conversionSwitch.price"), market: .illicit, rarity: .contraband, heat: 18)
    ]

    static func definition(for id: FirearmUpgradeID) -> FirearmUpgradeDefinition {
        all.first(where: { $0.id == id })!
    }
}

enum VehicleUpgradeID: String, Codable, CaseIterable, Identifiable {
    case nitrous
    case supercharger
    case rollCage
    case bulletResistantWindows
    case armoredTires
    case performanceWheels
    case performanceEngine

    var id: String { rawValue }
}

struct VehicleUpgradeDefinition: Identifiable, Equatable {
    let id: VehicleUpgradeID
    let name: String
    let detail: String
    let price: Int
    let valueContribution: Int
    let performance: Int
    let protection: Int
    let conditionCost: Int
    let allowedKinds: Set<VehicleKind>
}

enum VehicleUpgradeCatalog {
    static let all: [VehicleUpgradeDefinition] = [
        .init(id: .nitrous, name: "Nitrous system", detail: "A short performance burst with additional condition strain.", price: EconomyPolicy.assetQuote("vehicle.nitrous.price"), valueContribution: EconomyPolicy.assetQuote("vehicle.nitrous.value"), performance: 12, protection: 0, conditionCost: 2, allowedKinds: [.car]),
        .init(id: .supercharger, name: "Supercharger", detail: "Sustained engine performance with higher service demands.", price: EconomyPolicy.assetQuote("vehicle.supercharger.price"), valueContribution: EconomyPolicy.assetQuote("vehicle.supercharger.value"), performance: 16, protection: 0, conditionCost: 3, allowedKinds: [.car]),
        .init(id: .rollCage, name: "Roll cage", detail: "Structural protection that improves vehicle resilience.", price: EconomyPolicy.assetQuote("vehicle.rollCage.price"), valueContribution: EconomyPolicy.assetQuote("vehicle.rollCage.value"), performance: 0, protection: 12, conditionCost: 0, allowedKinds: [.car]),
        .init(id: .bulletResistantWindows, name: "Bullet-resistant windows", detail: "Protective glass represented as a high-risk operation modifier.", price: EconomyPolicy.assetQuote("vehicle.windows.price"), valueContribution: EconomyPolicy.assetQuote("vehicle.windows.value"), performance: 0, protection: 16, conditionCost: 1, allowedKinds: [.car]),
        .init(id: .armoredTires, name: "Armored tires", detail: "Reinforced tires that improve escape resilience.", price: EconomyPolicy.assetQuote("vehicle.tires.price"), valueContribution: EconomyPolicy.assetQuote("vehicle.tires.value"), performance: 2, protection: 10, conditionCost: 1, allowedKinds: [.car]),
        .init(id: .performanceWheels, name: "Performance wheels", detail: "Handling-focused wheels for performance builds.", price: EconomyPolicy.assetQuote("vehicle.wheels.price"), valueContribution: EconomyPolicy.assetQuote("vehicle.wheels.value"), performance: 8, protection: 0, conditionCost: 1, allowedKinds: [.car, .boat]),
        .init(id: .performanceEngine, name: "Performance engine", detail: "A major performance conversion for high-output vehicles.", price: EconomyPolicy.assetQuote("vehicle.engine.price"), valueContribution: EconomyPolicy.assetQuote("vehicle.engine.value"), performance: 20, protection: 0, conditionCost: 4, allowedKinds: [.car, .boat])
    ]

    static func definition(for id: VehicleUpgradeID) -> VehicleUpgradeDefinition { all.first { $0.id == id }! }
}

struct OwnedFirearmState: Codable, Equatable {
    let market: FirearmMarket
    let rarity: FirearmRarity
    let baseHeat: Int
    var upgrades: [FirearmUpgradeID] = []
    var condition: Int = 100
    var secureStorage = false
    var lastInspectionAge: Int? = nil

    var totalHeat: Int {
        baseHeat + upgrades.reduce(0) { $0 + FirearmUpgradeCatalog.definition(for: $1).heat }
    }

    var storageRisk: Int { secureStorage ? 0 : 6 }
    var conditionRisk: Int { max(0, (100 - condition) / 10) }

    private enum CodingKeys: String, CodingKey {
        case market, rarity, baseHeat, upgrades, condition, secureStorage, lastInspectionAge
    }

    init(
        market: FirearmMarket,
        rarity: FirearmRarity,
        baseHeat: Int,
        upgrades: [FirearmUpgradeID] = [],
        condition: Int = 100,
        secureStorage: Bool = false,
        lastInspectionAge: Int? = nil
    ) {
        self.market = market
        self.rarity = rarity
        self.baseHeat = baseHeat
        self.upgrades = upgrades
        self.condition = condition
        self.secureStorage = secureStorage
        self.lastInspectionAge = lastInspectionAge
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        market = try c.decode(FirearmMarket.self, forKey: .market)
        rarity = try c.decode(FirearmRarity.self, forKey: .rarity)
        baseHeat = try c.decode(Int.self, forKey: .baseHeat)
        upgrades = try c.decodeIfPresent([FirearmUpgradeID].self, forKey: .upgrades) ?? []
        condition = try c.decodeIfPresent(Int.self, forKey: .condition) ?? 100
        secureStorage = try c.decodeIfPresent(Bool.self, forKey: .secureStorage) ?? false
        lastInspectionAge = try c.decodeIfPresent(Int.self, forKey: .lastInspectionAge)
    }
}

struct OwnedJewelryState: Codable, Equatable {
    var marketValue: Int
    var condition: Int = 100
    var lastAppraisalAge: Int? = nil

    private enum CodingKeys: String, CodingKey { case marketValue, condition, lastAppraisalAge }

    init(marketValue: Int, condition: Int = 100, lastAppraisalAge: Int? = nil) {
        self.marketValue = marketValue
        self.condition = condition
        self.lastAppraisalAge = lastAppraisalAge
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        marketValue = try c.decodeIfPresent(Int.self, forKey: .marketValue) ?? 0
        condition = try c.decodeIfPresent(Int.self, forKey: .condition) ?? 100
        lastAppraisalAge = try c.decodeIfPresent(Int.self, forKey: .lastAppraisalAge)
    }

    var resaleValue: Int {
        max(0, marketValue * max(45, 65 - (100 - condition) / 5) / 100)
    }
}

struct NotorietyState: Codable, Equatable {
    var score = 0
    var cleanYears = 0
    var lastIncidentAge: Int?

    mutating func adjust(_ delta: Int, age: Int? = nil) {
        score = min(100, max(0, score + delta))
        if delta > 0 {
            cleanYears = 0
            if let age { lastIncidentAge = age }
        }
    }

    mutating func recordCleanYear() {
        cleanYears += 1
        if cleanYears >= 2 { score = max(0, score - 1) }
    }
}

enum AssetGiftRecipient: Codable, Equatable, Identifiable {
    case partner
    case family(contactID: String)
    case cast(memberID: String)

    var id: String {
        switch self {
        case .partner: "partner"
        case .family(let contactID): "family-\(contactID)"
        case .cast(let memberID): "cast-\(memberID)"
        }
    }
}

struct AssetGiftRecord: Codable, Equatable, Identifiable {
    let id: UInt64
    let age: Int
    let assetCategory: AssetCategory
    let assetName: String
    let value: Int
    let recipientID: String
    let recipientName: String
    let major: Bool
    let reciprocityValue: Int
    let transferredCondition: Int?
    let transferredUpgrades: [FirearmUpgradeID]
    let transferredSecureStorage: Bool?
    let transferredMarket: FirearmMarket?
    let transferredRarity: FirearmRarity?
    let transferredLegalHeat: Int?

    init(
        id: UInt64,
        age: Int,
        assetCategory: AssetCategory,
        assetName: String,
        value: Int,
        recipientID: String,
        recipientName: String,
        major: Bool,
        reciprocityValue: Int = 0,
        transferredCondition: Int? = nil,
        transferredUpgrades: [FirearmUpgradeID] = [],
        transferredSecureStorage: Bool? = nil,
        transferredMarket: FirearmMarket? = nil,
        transferredRarity: FirearmRarity? = nil,
        transferredLegalHeat: Int? = nil
    ) {
        self.id = id
        self.age = age
        self.assetCategory = assetCategory
        self.assetName = assetName
        self.value = value
        self.recipientID = recipientID
        self.recipientName = recipientName
        self.major = major
        self.reciprocityValue = reciprocityValue
        self.transferredCondition = transferredCondition
        self.transferredUpgrades = transferredUpgrades
        self.transferredSecureStorage = transferredSecureStorage
        self.transferredMarket = transferredMarket
        self.transferredRarity = transferredRarity
        self.transferredLegalHeat = transferredLegalHeat
    }

    private enum CodingKeys: String, CodingKey {
        case id, age, assetCategory, assetName, value, recipientID, recipientName, major
        case reciprocityValue, transferredCondition, transferredUpgrades, transferredSecureStorage
        case transferredMarket, transferredRarity, transferredLegalHeat
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UInt64.self, forKey: .id)
        age = try c.decode(Int.self, forKey: .age)
        assetCategory = try c.decode(AssetCategory.self, forKey: .assetCategory)
        assetName = try c.decode(String.self, forKey: .assetName)
        value = try c.decode(Int.self, forKey: .value)
        recipientID = try c.decode(String.self, forKey: .recipientID)
        recipientName = try c.decode(String.self, forKey: .recipientName)
        major = try c.decodeIfPresent(Bool.self, forKey: .major) ?? (value > 10_000)
        reciprocityValue = try c.decodeIfPresent(Int.self, forKey: .reciprocityValue) ?? 0
        transferredCondition = try c.decodeIfPresent(Int.self, forKey: .transferredCondition)
        transferredUpgrades = try c.decodeIfPresent([FirearmUpgradeID].self, forKey: .transferredUpgrades) ?? []
        transferredSecureStorage = try c.decodeIfPresent(Bool.self, forKey: .transferredSecureStorage)
        transferredMarket = try c.decodeIfPresent(FirearmMarket.self, forKey: .transferredMarket)
        transferredRarity = try c.decodeIfPresent(FirearmRarity.self, forKey: .transferredRarity)
        transferredLegalHeat = try c.decodeIfPresent(Int.self, forKey: .transferredLegalHeat)
    }
}

struct GiftReciprocityState: Codable, Equatable {
    var balances: [String: Int] = [:]
    var usedEventKeys: [String] = []

    mutating func add(_ value: Int, for recipientID: String) {
        guard value > 0 else { return }
        balances[recipientID] = min(25_000, max(0, (balances[recipientID] ?? 0) + value))
    }

    mutating func consume(_ value: Int, recipientID: String, eventKey: String) -> Int {
        guard value > 0, !usedEventKeys.contains(eventKey) else { return 0 }
        let available = max(0, balances[recipientID] ?? 0)
        let consumed = min(value, available)
        guard consumed > 0 else { return 0 }
        balances[recipientID] = available - consumed
        usedEventKeys.insert(eventKey, at: 0)
        usedEventKeys = Array(usedEventKeys.prefix(24))
        return consumed
    }
}

struct AssetGiftOutcome: Equatable {
    let transaction: AssetTransaction
    let recipient: AssetGiftRecipient
    let recipientID: String
    let recipientName: String
    let relationshipDelta: Int
    let reciprocityValue: Int
    let notorietyDelta: Int

    var headline: String { transaction.headline }
    var detail: String { transaction.detail }
    var cashDelta: Int { transaction.cashDelta }
}

struct AssetGiftPreview: Equatable {
    let assetName: String
    let resaleValue: Int
    let recipientName: String
    let relationshipDelta: Int
    let reciprocityValue: Int
}

struct AssetReciprocityOutcome: Equatable {
    let recipientID: String
    let valueConsumed: Int
    let cashSupport: Int
    let stabilitySupport: Int
}

struct CriminalAssetUseOutcome: Equatable {
    let affectedAssetIDs: [UInt64]
    let lostAssetID: UInt64?
    let detail: String
}

enum AssetLossAction: String, Codable, CaseIterable, Identifiable {
    case recoverPrivately
    case report
    case accept

    var id: String { rawValue }
}

struct AssetLossRecord: Codable, Equatable, Identifiable {
    let id: UInt64
    let age: Int
    let assetCategory: AssetCategory
    let assetName: String
    let value: Int
    let action: AssetLossAction
    let reason: String
}

struct AssetLossEffect: Codable, Equatable {
    let assetID: UInt64
    let action: AssetLossAction
}

struct AssetRecoveryCase: Codable, Equatable, Identifiable {
    let id: UInt64
    let assetCategory: AssetCategory
    let assetName: String
    let estimatedValue: Int
    let openedAge: Int
    var evidence = 50
    var attempts = 0

    mutating func clamp() {
        evidence = min(100, max(0, evidence))
        attempts = min(2, max(0, attempts))
    }
}

enum AssetRecoveryResult: Equatable {
    case recovered(cash: Int)
    case cold
}

enum NotorietySystem {
    static func adjust(_ delta: Int, age: Int, state: inout LifeState) {
        state.assets.notoriety.adjust(delta, age: age)
    }

    static func cleanYear(state: inout LifeState) {
        state.assets.notoriety.recordCleanYear()
    }
}

enum VehicleKind: String, Codable, CaseIterable, Identifiable {
    case car, helicopter, plane, boat

    var id: String { rawValue }
    var title: String {
        switch self {
        case .car: "Cars"
        case .helicopter: "Helicopters"
        case .plane: "Planes"
        case .boat: "Boats & Yachts"
        }
    }
    var singularTitle: String {
        switch self {
        case .car: "Car"
        case .helicopter: "Helicopter"
        case .plane: "Plane"
        case .boat: "Boat / yacht"
        }
    }
    var symbol: String {
        switch self {
        case .car: "car.fill"
        case .helicopter: "airplane.circle.fill"
        case .plane: "airplane"
        case .boat: "sailboat.fill"
        }
    }
}

enum CarCatalogGroup: String, Codable, CaseIterable, Identifiable {
    case everyday, utility, performance, luxury

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum CarBodyStyle: String, Codable, CaseIterable {
    case hatchback, sedan, wagon, hybrid, crossover, minivan, pickup, suv
    case roadster, coupe, supercar, grandTourer, limousine

    var title: String {
        switch self {
        case .grandTourer: "Grand tourer"
        default: rawValue.capitalized
        }
    }

    var symbolName: String {
        switch self {
        case .crossover, .suv: "suv.side.fill"
        case .pickup: "truck.pickup.side.fill"
        case .minivan: "car.2.fill"
        case .roadster, .coupe, .supercar: "car.rear.fill"
        case .hatchback, .sedan, .wagon, .hybrid, .grandTourer, .limousine: "car.side.fill"
        }
    }
}

struct VehicleListingMetadata: Equatable {
    let kind: VehicleKind
    let minimumCareerLevel: CareerLevel?
    let carGroup: CarCatalogGroup?
    let bodyStyle: CarBodyStyle?

    init(
        kind: VehicleKind,
        minimumCareerLevel: CareerLevel?,
        carGroup: CarCatalogGroup? = nil,
        bodyStyle: CarBodyStyle? = nil
    ) {
        self.kind = kind
        self.minimumCareerLevel = minimumCareerLevel
        self.carGroup = carGroup
        self.bodyStyle = bodyStyle
    }

    var symbolName: String { bodyStyle?.symbolName ?? kind.symbol }
}

struct OwnedVehicleState: Codable, Equatable {
    let kind: VehicleKind
    var customName: String? = nil
    var condition: Int = 100
    var currentValue: Int = 0
    var lastMaintenanceAge: Int? = nil
    var repairState: VehicleRepairState = .healthy
    var upgrades: [VehicleUpgradeID] = []

    var performance: Int { upgrades.reduce(0) { $0 + VehicleUpgradeCatalog.definition(for: $1).performance } }
    var protection: Int { upgrades.reduce(0) { $0 + VehicleUpgradeCatalog.definition(for: $1).protection } }

    var reliability: Int {
        max(0, min(100, condition - (repairState == .needsRepair ? 25 : 0)))
    }

    private enum CodingKeys: String, CodingKey { case kind, customName, condition, currentValue, lastMaintenanceAge, repairState, upgrades }

    init(
        kind: VehicleKind,
        customName: String? = nil,
        condition: Int = 100,
        currentValue: Int = 0,
        lastMaintenanceAge: Int? = nil,
        repairState: VehicleRepairState = .healthy
        , upgrades: [VehicleUpgradeID] = []
    ) {
        self.kind = kind
        self.customName = customName
        self.condition = condition
        self.currentValue = currentValue
        self.lastMaintenanceAge = lastMaintenanceAge
        self.repairState = repairState
        self.upgrades = upgrades
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(VehicleKind.self, forKey: .kind)
        customName = try c.decodeIfPresent(String.self, forKey: .customName)
        condition = try c.decodeIfPresent(Int.self, forKey: .condition) ?? 100
        currentValue = try c.decodeIfPresent(Int.self, forKey: .currentValue) ?? 0
        lastMaintenanceAge = try c.decodeIfPresent(Int.self, forKey: .lastMaintenanceAge)
        repairState = try c.decodeIfPresent(VehicleRepairState.self, forKey: .repairState) ?? .healthy
        upgrades = try c.decodeIfPresent([VehicleUpgradeID].self, forKey: .upgrades) ?? []
    }
}

enum VehicleRepairState: String, Codable, Equatable {
    case healthy
    case needsRepair
    case totaled
}

enum VehicleMaintenanceKind: String, Codable, CaseIterable, Identifiable {
    case routine
    case breakdown

    var id: String { rawValue }
    var title: String { self == .routine ? "Routine maintenance" : "Repair breakdown" }
    var conditionGain: Int { self == .routine ? 12 : 35 }
    var valueRate: Int { self == .routine ? 4 : 12 }
}

enum FirearmManagementAction: String, Codable, CaseIterable, Identifiable {
    case secureStorage
    case inspection

    var id: String { rawValue }
    var title: String { self == .secureStorage ? "Secure storage" : "Inspection and cleaning" }
    var price: Int { self == .secureStorage ? 250 : 150 }
    var conditionGain: Int { self == .secureStorage ? 0 : 15 }
}

enum PlayerAssignedNameValidation: Equatable {
    case valid(String)
    case invalid(String)
}

enum PlayerAssignedNamePolicy {
    static let maximumLength = 24

    static func validate(_ rawValue: String) -> PlayerAssignedNameValidation {
        if rawValue.unicodeScalars.contains(where: {
            CharacterSet.controlCharacters.contains($0) || CharacterSet.newlines.contains($0)
        }) {
            return .invalid("Use a single line without control characters.")
        }
        let normalized = rawValue.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        guard !normalized.isEmpty else { return .invalid("Enter a name.") }
        guard normalized.count <= maximumLength else {
            return .invalid("Use \(maximumLength) characters or fewer.")
        }
        return .valid(normalized)
    }
}

enum PropertyType: String, Codable, CaseIterable {
    case condo, townhome, house, penthouse, mansion, estate
}

enum PropertyTier: String, Codable, CaseIterable {
    case starter, standard, premium, luxury, trophy

    var rank: Int {
        switch self {
        case .starter: 0
        case .standard: 1
        case .premium: 2
        case .luxury: 3
        case .trophy: 4
        }
    }
}

enum PropertyUseState: String, Codable, CaseIterable {
    case primaryResidence, vacant, rental

    var title: String {
        switch self {
        case .primaryResidence: "Primary"
        case .vacant: "Vacant"
        case .rental: "Rental"
        }
    }
}

enum PropertyConditionBand: String, Codable {
    case sound, worn, distressed, severe

    static func band(for condition: Int) -> Self {
        if condition >= 80 { return .sound }
        if condition >= 60 { return .worn }
        if condition >= 40 { return .distressed }
        return .severe
    }

    var valuePercent: Int {
        switch self {
        case .sound: 100
        case .worn: 95
        case .distressed: 85
        case .severe: 70
        }
    }

    var title: String { rawValue.capitalized }
}

enum RentalStrategy: String, Codable, CaseIterable, Identifiable {
    case stable, market, aggressive

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var rentPercent: Int { self == .stable ? 90 : (self == .market ? 100 : 115) }
    var fillChance: Int { self == .stable ? 90 : (self == .market ? 75 : 55) }
    var renewalChance: Int { self == .stable ? 90 : (self == .market ? 75 : 50) }
    var reliabilityModifier: Int { self == .stable ? 5 : (self == .market ? 0 : -10) }
}

enum RentalHouseholdType: String, Codable, CaseIterable {
    case individual, couple, family

    var title: String {
        switch self {
        case .individual: "Individual"
        case .couple: "Couple"
        case .family: "Family"
        }
    }
}

struct RentalTenantProfile: Codable, Equatable, Identifiable {
    let id: UInt64
    let name: String
    let householdType: RentalHouseholdType
    var reliability: Int
    var care: Int
    let occupiedSinceAge: Int
    var leaseYearsRemaining: Int
}

struct RentalPropertyState: Codable, Equatable {
    var strategy: RentalStrategy
    var tenant: RentalTenantProfile?
    var listedAge: Int
    var vacancyYears = 0
    var lastCollectedRent = 0
    var missedPaymentThisYear = false
    var restrictedDeposit: Int? = nil
}

enum PropertyRepairKind: String, Codable, CaseIterable, Identifiable {
    case routine, restoration

    var id: String { rawValue }
    var title: String { self == .routine ? "Routine maintenance" : "Major restoration" }
    var conditionGain: Int { self == .routine ? 15 : 35 }
}

enum PropertyAmenityID: String, Codable, CaseIterable, Identifiable {
    case homeGym
    case basketballCourt
    case hotTub
    case sauna
    case swimmingPool
    case tennisCourt
    case landscaping
    case bioluminescentLandscaping

    var id: String { rawValue }
}

struct PropertyAmenityDefinition: Identifiable, Equatable {
    let id: PropertyAmenityID
    let name: String
    let detail: String
    let minimumTier: PropertyTier
    let installationPrice: Int
    let valueContribution: Int
    let annualUpkeep: Int
}

enum PropertyAmenityCatalog {
    static let all: [PropertyAmenityDefinition] = [
        .init(id: .homeGym, name: "Home gym", detail: "A dedicated training space with equipment to maintain.", minimumTier: .standard, installationPrice: EconomyPolicy.assetQuote("homeGym.installationPrice"), valueContribution: EconomyPolicy.assetQuote("homeGym.valueContribution"), annualUpkeep: EconomyPolicy.assetQuote("homeGym.annualUpkeep")),
        .init(id: .basketballCourt, name: "Basketball court", detail: "A private court that adds space, value, and upkeep.", minimumTier: .premium, installationPrice: EconomyPolicy.assetQuote("basketballCourt.installationPrice"), valueContribution: EconomyPolicy.assetQuote("basketballCourt.valueContribution"), annualUpkeep: EconomyPolicy.assetQuote("basketballCourt.annualUpkeep")),
        .init(id: .hotTub, name: "Hot tub", detail: "A compact luxury amenity with regular service needs.", minimumTier: .standard, installationPrice: EconomyPolicy.assetQuote("hotTub.installationPrice"), valueContribution: EconomyPolicy.assetQuote("hotTub.valueContribution"), annualUpkeep: EconomyPolicy.assetQuote("hotTub.annualUpkeep")),
        .init(id: .sauna, name: "Sauna", detail: "A built-in luxury room with ongoing service costs.", minimumTier: .premium, installationPrice: EconomyPolicy.assetQuote("sauna.installationPrice"), valueContribution: EconomyPolicy.assetQuote("sauna.valueContribution"), annualUpkeep: EconomyPolicy.assetQuote("sauna.annualUpkeep")),
        .init(id: .swimmingPool, name: "Swimming pool", detail: "A major installation with substantial yearly maintenance.", minimumTier: .premium, installationPrice: EconomyPolicy.assetQuote("swimmingPool.installationPrice"), valueContribution: EconomyPolicy.assetQuote("swimmingPool.valueContribution"), annualUpkeep: EconomyPolicy.assetQuote("swimmingPool.annualUpkeep")),
        .init(id: .tennisCourt, name: "Tennis court", detail: "A luxury-tier court with expensive surface upkeep.", minimumTier: .luxury, installationPrice: EconomyPolicy.assetQuote("tennisCourt.installationPrice"), valueContribution: EconomyPolicy.assetQuote("tennisCourt.valueContribution"), annualUpkeep: EconomyPolicy.assetQuote("tennisCourt.annualUpkeep")),
        .init(id: .landscaping, name: "Landscaping", detail: "A maintained outdoor setting that improves the property's presentation.", minimumTier: .standard, installationPrice: EconomyPolicy.assetQuote("landscaping.installationPrice"), valueContribution: EconomyPolicy.assetQuote("landscaping.valueContribution"), annualUpkeep: EconomyPolicy.assetQuote("landscaping.annualUpkeep")),
        .init(id: .bioluminescentLandscaping, name: "Bioluminescent landscaping", detail: "A rare luminous garden reserved for trophy properties.", minimumTier: .trophy, installationPrice: EconomyPolicy.assetQuote("bioluminescentLandscaping.installationPrice"), valueContribution: EconomyPolicy.assetQuote("bioluminescentLandscaping.valueContribution"), annualUpkeep: EconomyPolicy.assetQuote("bioluminescentLandscaping.annualUpkeep"))
    ]

    private static let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func definition(for id: PropertyAmenityID) -> PropertyAmenityDefinition? { byID[id] }
}

struct InstalledPropertyAmenity: Codable, Equatable, Identifiable {
    var id: PropertyAmenityID { amenityID }
    let amenityID: PropertyAmenityID
    let installedAge: Int
    let paidPrice: Int
    let valueContribution: Int
    let annualUpkeep: Int
}

struct PropertyListingMetadata: Equatable {
    let type: PropertyType
    let tier: PropertyTier
}

struct AssetListing: Identifiable, Equatable {
    let id: String
    let category: AssetCategory
    let name: String
    let detail: String
    let minimumAge: Int
    let terms: AssetPurchaseTerms
    let firearm: FirearmListingMetadata?
    let property: PropertyListingMetadata?
    let vehicle: VehicleListingMetadata?

    init(
        id: String,
        category: AssetCategory,
        name: String,
        detail: String,
        minimumAge: Int,
        terms: AssetPurchaseTerms,
        firearm: FirearmListingMetadata? = nil,
        property: PropertyListingMetadata? = nil,
        vehicle: VehicleListingMetadata? = nil
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.detail = detail
        self.minimumAge = minimumAge
        self.terms = terms
        self.firearm = firearm
        self.property = property
        self.vehicle = vehicle
    }
}

enum AssetCatalog {
    static let all: [AssetListing] = [
        .init(id: "gun-sporting-handgun", category: .guns, name: "Sporting handgun", detail: "A common lawful firearm requiring secure storage.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("gun-sporting-handgun.price")), firearm: .init(market: .legal, rarity: .common, heat: 0)),
        .init(id: "gun-hunting-rifle", category: .guns, name: "Hunting rifle", detail: "A common lawful sporting rifle kept secured.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("gun-hunting-rifle.price")), firearm: .init(market: .legal, rarity: .common, heat: 0)),
        .init(id: "gun-sporting-shotgun", category: .guns, name: "Sporting shotgun", detail: "A less-common lawful sporting purchase.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("gun-sporting-shotgun.price")), firearm: .init(market: .legal, rarity: .uncommon, heat: 0)),
        .init(id: "gun-collector-firearm", category: .guns, name: "Collector firearm", detail: "A rare lawful collection piece kept secured.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("gun-collector-firearm.price")), firearm: .init(market: .legal, rarity: .rare, heat: 0)),
        .init(id: "gun-unregistered-handgun", category: .guns, name: "Unregistered handgun", detail: "An illegal-market firearm carrying persistent legal exposure.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("gun-unregistered-handgun.price")), firearm: .init(market: .illicit, rarity: .uncommon, heat: 8)),
        .init(id: "gun-altered-firearm", category: .guns, name: "Illegally altered firearm", detail: "A dangerous illegal-market weapon with high scrutiny.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("gun-altered-firearm.price")), firearm: .init(market: .illicit, rarity: .rare, heat: 15)),
        .init(id: "gun-trafficked-collector", category: .guns, name: "Trafficked collector weapon", detail: "A rare illicit piece whose provenance creates risk.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("gun-trafficked-collector.price")), firearm: .init(market: .illicit, rarity: .rare, heat: 17)),
        .init(id: "gun-automatic-contraband", category: .guns, name: "Automatic contraband firearm", detail: "A prohibited high-risk weapon; ownership has no combat benefit.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("gun-automatic-contraband.price")), firearm: .init(market: .illicit, rarity: .contraband, heat: 28)),

        .init(id: "car-used-compact", category: .cars, name: "Older hatchback", detail: "Cheap transportation carrying years of prior use.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-used-compact.price")), vehicle: .init(kind: .car, minimumCareerLevel: nil, carGroup: .everyday, bodyStyle: .hatchback)),
        .init(id: "car-reliable-sedan", category: .cars, name: "Budget sedan", detail: "Basic four-door transportation without status attached.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-reliable-sedan.price")), vehicle: .init(kind: .car, minimumCareerLevel: nil, carGroup: .everyday, bodyStyle: .sedan)),
        .init(id: "car-practical-wagon", category: .cars, name: "Practical wagon", detail: "Extra cargo room for an employed household.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-practical-wagon.price")), vehicle: .init(kind: .car, minimumCareerLevel: .entry, carGroup: .everyday, bodyStyle: .wagon)),
        .init(id: "car-efficient-hybrid", category: .cars, name: "Efficient hybrid", detail: "A newer commuter bought for sensible daily travel.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-efficient-hybrid.price")), vehicle: .init(kind: .car, minimumCareerLevel: .entry, carGroup: .everyday, bodyStyle: .hybrid)),

        .init(id: "car-utility-vehicle", category: .cars, name: "Compact crossover", detail: "A modest utility shape with room for ordinary life.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-utility-vehicle.price")), vehicle: .init(kind: .car, minimumCareerLevel: .entry, carGroup: .utility, bodyStyle: .crossover)),
        .init(id: "car-family-minivan", category: .cars, name: "Family minivan", detail: "Passenger space without luxury pricing.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-family-minivan.price")), vehicle: .init(kind: .car, minimumCareerLevel: .entry, carGroup: .utility, bodyStyle: .minivan)),
        .init(id: "car-work-pickup", category: .cars, name: "Work pickup", detail: "A practical truck purchased with steady employment.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-work-pickup.price")), vehicle: .init(kind: .car, minimumCareerLevel: .entry, carGroup: .utility, bodyStyle: .pickup)),
        .init(id: "car-full-size-suv", category: .cars, name: "Full-size SUV", detail: "A large utility vehicle with an established-career price.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-full-size-suv.price")), vehicle: .init(kind: .car, minimumCareerLevel: .established, carGroup: .utility, bodyStyle: .suv)),

        .init(id: "car-used-roadster", category: .cars, name: "Used roadster", detail: "An older open-top indulgence with no performance effects yet.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-used-roadster.price")), vehicle: .init(kind: .car, minimumCareerLevel: .entry, carGroup: .performance, bodyStyle: .roadster)),
        .init(id: "car-sport-sedan", category: .cars, name: "Sport sedan", detail: "A faster-looking daily car for an established career.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-sport-sedan.price")), vehicle: .init(kind: .car, minimumCareerLevel: .established, carGroup: .performance, bodyStyle: .sedan)),
        .init(id: "car-luxury-coupe", category: .cars, name: "Performance coupe", detail: "A focused two-door purchase with visible expense.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-luxury-coupe.price")), vehicle: .init(kind: .car, minimumCareerLevel: .established, carGroup: .performance, bodyStyle: .coupe)),
        .init(id: "car-track-supercar", category: .cars, name: "Track-focused supercar", detail: "A senior-career trophy with no active performance simulation.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-track-supercar.price")), vehicle: .init(kind: .car, minimumCareerLevel: .senior, carGroup: .performance, bodyStyle: .supercar)),

        .init(id: "car-executive-sedan", category: .cars, name: "Executive sedan", detail: "A restrained luxury car tied to established-career means.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-executive-sedan.price")), vehicle: .init(kind: .car, minimumCareerLevel: .established, carGroup: .luxury, bodyStyle: .sedan)),
        .init(id: "car-luxury-suv", category: .cars, name: "Luxury SUV", detail: "Premium utility purchased without income or stat effects.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-luxury-suv.price")), vehicle: .init(kind: .car, minimumCareerLevel: .established, carGroup: .luxury, bodyStyle: .suv)),
        .init(id: "car-grand-tourer", category: .cars, name: "Grand tourer", detail: "A senior-career long-distance luxury shape.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-grand-tourer.price")), vehicle: .init(kind: .car, minimumCareerLevel: .senior, carGroup: .luxury, bodyStyle: .grandTourer)),
        .init(id: "car-limousine", category: .cars, name: "Chauffeured limousine", detail: "The catalog's largest manufacturer-free luxury car.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("car-limousine.price")), vehicle: .init(kind: .car, minimumCareerLevel: .senior, carGroup: .luxury, bodyStyle: .limousine)),

        .init(id: "helicopter-utility", category: .cars, name: "Utility helicopter", detail: "A workhorse rotorcraft purchased without operating mechanics.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("helicopter-utility.price")), vehicle: .init(kind: .helicopter, minimumCareerLevel: .established)),
        .init(id: "helicopter-executive", category: .cars, name: "Executive helicopter", detail: "Private short-range air travel with a severe acquisition cost.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("helicopter-executive.price")), vehicle: .init(kind: .helicopter, minimumCareerLevel: .senior)),
        .init(id: "helicopter-luxury", category: .cars, name: "Luxury helicopter", detail: "A top-tier rotorcraft held strictly as an owned asset.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("helicopter-luxury.price")), vehicle: .init(kind: .helicopter, minimumCareerLevel: .senior)),

        .init(id: "plane-light-sport", category: .cars, name: "Light sport aircraft", detail: "A compact private aircraft with no flight simulation in this pass.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("plane-light-sport.price")), vehicle: .init(kind: .plane, minimumCareerLevel: .established)),
        .init(id: "plane-twin-engine", category: .cars, name: "Twin-engine plane", detail: "A serious private aircraft requiring senior-career means.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("plane-twin-engine.price")), vehicle: .init(kind: .plane, minimumCareerLevel: .senior)),
        .init(id: "plane-private-jet", category: .cars, name: "Private jet", detail: "The catalog's largest aviation purchase, without passive income or use effects.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("plane-private-jet.price")), vehicle: .init(kind: .plane, minimumCareerLevel: .senior)),

        .init(id: "boat-fishing", category: .cars, name: "Fishing boat", detail: "A practical small vessel bought outright.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("boat-fishing.price")), vehicle: .init(kind: .boat, minimumCareerLevel: .entry)),
        .init(id: "boat-speedboat", category: .cars, name: "Speedboat", detail: "A fast recreational vessel with no active-use effects yet.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("boat-speedboat.price")), vehicle: .init(kind: .boat, minimumCareerLevel: .established)),
        .init(id: "boat-cabin-cruiser", category: .cars, name: "Cabin cruiser", detail: "A larger private boat meant for ownership rather than income.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("boat-cabin-cruiser.price")), vehicle: .init(kind: .boat, minimumCareerLevel: .established)),
        .init(id: "boat-luxury-yacht", category: .cars, name: "Luxury yacht", detail: "A senior-career trophy vessel with no appreciation or rental income.", minimumAge: 21, terms: .cash(price: EconomyPolicy.assetQuote("boat-luxury-yacht.price")), vehicle: .init(kind: .boat, minimumCareerLevel: .senior)),

        .init(id: "house-starter-condo", category: .houses, name: "Cedar Court Condo", detail: "A starter condo with shared walls and a manageable mortgage.", minimumAge: 18, terms: EconomyPolicy.propertyTerms("house-starter-condo", minimumCareerLevel: .entry), property: .init(type: .condo, tier: .starter)),
        .init(id: "house-townhouse", category: .houses, name: "Juniper Row Townhome", detail: "A standard townhome with more space and another obligation.", minimumAge: 18, terms: EconomyPolicy.propertyTerms("house-townhouse", minimumCareerLevel: .entry), property: .init(type: .townhome, tier: .standard)),
        .init(id: "house-family", category: .houses, name: "Maple Street House", detail: "A premium detached house financed over time.", minimumAge: 18, terms: EconomyPolicy.propertyTerms("house-family", minimumCareerLevel: .established), property: .init(type: .house, tier: .premium)),
        .init(id: "house-skyline-penthouse", category: .houses, name: "Skyline Penthouse", detail: "A luxury penthouse with a steep carrying cost.", minimumAge: 18, terms: EconomyPolicy.propertyTerms("house-skyline-penthouse", minimumCareerLevel: .established), property: .init(type: .penthouse, tier: .luxury)),
        .init(id: "house-grandview-mansion", category: .houses, name: "Grandview Mansion", detail: "A trophy mansion requiring senior-career income.", minimumAge: 18, terms: EconomyPolicy.propertyTerms("house-grandview-mansion", minimumCareerLevel: .senior), property: .init(type: .mansion, tier: .trophy)),
        .init(id: "house-luxury-estate", category: .houses, name: "Lakefront Estate", detail: "A trophy estate with the catalog's largest obligation.", minimumAge: 18, terms: EconomyPolicy.propertyTerms("house-luxury-estate", minimumCareerLevel: .senior), property: .init(type: .estate, tier: .trophy)),

        .init(id: "jewelry-silver-chain", category: .jewelry, name: "Silver chain", detail: "A small piece bought without leverage.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("jewelry-silver-chain.price"))),
        .init(id: "jewelry-gold-watch", category: .jewelry, name: "Gold watch", detail: "A visible luxury that stores some value.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("jewelry-gold-watch.price"))),
        .init(id: "jewelry-diamond-ring", category: .jewelry, name: "Diamond ring", detail: "A costly object without a promised story.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("jewelry-diamond-ring.price"))),
        .init(id: "jewelry-statement-piece", category: .jewelry, name: "Statement piece", detail: "An expensive piece purchased for ownership alone.", minimumAge: 18, terms: .cash(price: EconomyPolicy.assetQuote("jewelry-statement-piece.price")))
    ]

    private static let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func listings(in category: AssetCategory) -> [AssetListing] {
        all.filter { $0.category == category }
    }

    static func firearmListings(in market: FirearmMarket) -> [AssetListing] {
        listings(in: .guns).filter { $0.firearm?.market == market }
    }

    static func vehicleListings(of kind: VehicleKind) -> [AssetListing] {
        listings(in: .cars).filter { $0.vehicle?.kind == kind }
    }

    static func carListings(in group: CarCatalogGroup) -> [AssetListing] {
        vehicleListings(of: .car).filter { $0.vehicle?.carGroup == group }
    }

    static func listing(for id: String) -> AssetListing? { byID[id] }
}

struct OwnedAsset: Codable, Equatable, Identifiable {
    let id: UInt64
    let listingID: String
    let category: AssetCategory
    let name: String
    let purchaseAge: Int
    var purchasePrice: Int
    var firearm: OwnedFirearmState? = nil
    var vehicle: OwnedVehicleState? = nil
    var jewelry: OwnedJewelryState? = nil

    var resaleValue: Int {
        if let vehicle, vehicle.currentValue > 0 { return vehicle.currentValue * 65 / 100 }
        if let jewelry { return jewelry.resaleValue }
        return purchasePrice * 65 / 100
    }
    var displayName: String { vehicle?.customName ?? name }
}

struct OwnedProperty: Codable, Equatable, Identifiable {
    let id: UInt64
    let listingID: String
    let name: String
    let purchaseAge: Int
    var purchasePrice: Int
    var mortgageBalance: Int
    var mortgageMonthlyPayment = 0
    var mortgageMonthsRemaining = 360
    var operatingArrears = 0
    var annualCost: Int
    var delinquentYears: Int
    var use: PropertyUseState
    var propertyType: PropertyType? = nil
    var propertyTier: PropertyTier? = nil
    var amenities: [InstalledPropertyAmenity] = []
    var marketAdjustment = 0
    var condition = 90
    var lastRepairAge: Int? = nil
    var lastRentStrategyAge: Int? = nil
    var rental: RentalPropertyState? = nil

    init(
        id: UInt64,
        listingID: String,
        name: String,
        purchaseAge: Int,
        purchasePrice: Int,
        mortgageBalance: Int,
        annualCost: Int,
        delinquentYears: Int,
        isPrimaryResidence: Bool,
        propertyType: PropertyType? = nil,
        propertyTier: PropertyTier? = nil,
        amenities: [InstalledPropertyAmenity] = [],
        marketAdjustment: Int = 0,
        condition: Int = 90,
        lastRepairAge: Int? = nil,
        lastRentStrategyAge: Int? = nil,
        rental: RentalPropertyState? = nil
    ) {
        self.id = id
        self.listingID = listingID
        self.name = name
        self.purchaseAge = purchaseAge
        self.purchasePrice = purchasePrice
        self.mortgageBalance = mortgageBalance
        self.mortgageMonthlyPayment = EconomyPolicy.monthlyMortgage(mortgageBalance)
        self.annualCost = annualCost
        self.delinquentYears = delinquentYears
        use = isPrimaryResidence ? .primaryResidence : (rental == nil ? .vacant : .rental)
        self.propertyType = propertyType
        self.propertyTier = propertyTier
        self.amenities = amenities
        self.marketAdjustment = marketAdjustment
        self.condition = condition
        self.lastRepairAge = lastRepairAge
        self.lastRentStrategyAge = lastRentStrategyAge
        self.rental = rental
    }

    var isPrimaryResidence: Bool {
        get { use == .primaryResidence }
        set {
            use = newValue ? .primaryResidence : (rental == nil ? .vacant : .rental)
            if newValue { rental = nil }
        }
    }

    var improvementValue: Int { amenities.reduce(0) { $0 + $1.valueContribution } }
    var conditionBand: PropertyConditionBand { .band(for: condition) }
    var preConditionValue: Int { max(1, purchasePrice + marketAdjustment + improvementValue) }
    var currentValue: Int { preConditionValue * conditionBand.valuePercent / 100 }
    var amenityUpkeep: Int { amenities.reduce(0) { $0 + $1.annualUpkeep } }
    var totalAnnualCost: Int { EconomyPolicy.rate(currentValue, 250) + amenityUpkeep }
    var equity: Int { currentValue - mortgageBalance - operatingArrears }
    var closingCost: Int { max(8_000, EconomyPolicy.rate(currentValue, 500)) }
    var saleProceeds: Int { currentValue - mortgageBalance - closingCost - operatingArrears }
    var expectedMarketRent: Int {
        guard use == .rental, let rental else { return 0 }
        return AssetSystem.projectedAnnualRent(for: self, strategy: rental.strategy)
    }
}

enum PropertyExitReason: String, Codable {
    case sold, foreclosed

    var reviewText: String {
        switch self {
        case .sold: "sold"
        case .foreclosed: "lost to foreclosure"
        }
    }
}

struct PropertyExitRecord: Codable, Equatable, Identifiable {
    var id: UInt64 { propertyID }
    let propertyID: UInt64
    let name: String
    let purchaseAge: Int
    let exitAge: Int
    let reason: PropertyExitReason
    let finalValue: Int
    let finalMortgage: Int
    let cashRecovered: Int
    let amenityCount: Int
}

extension OwnedProperty {
    enum CodingKeys: String, CodingKey {
        case id, listingID, name, purchaseAge, purchasePrice, mortgageBalance, annualCost
        case delinquentYears, isPrimaryResidence, use, propertyType, propertyTier, amenities
        case marketAdjustment, condition, lastRepairAge, lastRentStrategyAge, rental
        case mortgageMonthlyPayment, mortgageMonthsRemaining, operatingArrears
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UInt64.self, forKey: .id)
        listingID = try c.decode(String.self, forKey: .listingID)
        name = try c.decode(String.self, forKey: .name)
        purchaseAge = try c.decode(Int.self, forKey: .purchaseAge)
        purchasePrice = try c.decode(Int.self, forKey: .purchasePrice)
        mortgageBalance = try c.decode(Int.self, forKey: .mortgageBalance)
        mortgageMonthlyPayment = try c.decodeIfPresent(Int.self, forKey: .mortgageMonthlyPayment) ?? 0
        mortgageMonthsRemaining = try c.decodeIfPresent(Int.self, forKey: .mortgageMonthsRemaining) ?? 360
        operatingArrears = try c.decodeIfPresent(Int.self, forKey: .operatingArrears) ?? 0
        annualCost = try c.decode(Int.self, forKey: .annualCost)
        delinquentYears = try c.decode(Int.self, forKey: .delinquentYears)
        let legacyPrimary = try c.decodeIfPresent(Bool.self, forKey: .isPrimaryResidence) ?? false
        use = try c.decodeIfPresent(PropertyUseState.self, forKey: .use)
            ?? (legacyPrimary ? .primaryResidence : .vacant)
        propertyType = try c.decodeIfPresent(PropertyType.self, forKey: .propertyType)
        propertyTier = try c.decodeIfPresent(PropertyTier.self, forKey: .propertyTier)
        amenities = try c.decodeIfPresent([InstalledPropertyAmenity].self, forKey: .amenities) ?? []
        marketAdjustment = try c.decodeIfPresent(Int.self, forKey: .marketAdjustment) ?? 0
        condition = try c.decodeIfPresent(Int.self, forKey: .condition) ?? 90
        lastRepairAge = try c.decodeIfPresent(Int.self, forKey: .lastRepairAge)
        lastRentStrategyAge = try c.decodeIfPresent(Int.self, forKey: .lastRentStrategyAge)
        rental = try c.decodeIfPresent(RentalPropertyState.self, forKey: .rental)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(listingID, forKey: .listingID)
        try c.encode(name, forKey: .name)
        try c.encode(purchaseAge, forKey: .purchaseAge)
        try c.encode(purchasePrice, forKey: .purchasePrice)
        try c.encode(mortgageBalance, forKey: .mortgageBalance)
        try c.encode(mortgageMonthlyPayment, forKey: .mortgageMonthlyPayment)
        try c.encode(mortgageMonthsRemaining, forKey: .mortgageMonthsRemaining)
        try c.encode(operatingArrears, forKey: .operatingArrears)
        try c.encode(annualCost, forKey: .annualCost)
        try c.encode(delinquentYears, forKey: .delinquentYears)
        try c.encode(use, forKey: .use)
        try c.encodeIfPresent(propertyType, forKey: .propertyType)
        try c.encodeIfPresent(propertyTier, forKey: .propertyTier)
        try c.encode(amenities, forKey: .amenities)
        try c.encode(marketAdjustment, forKey: .marketAdjustment)
        try c.encode(condition, forKey: .condition)
        try c.encodeIfPresent(lastRepairAge, forKey: .lastRepairAge)
        try c.encodeIfPresent(lastRentStrategyAge, forKey: .lastRentStrategyAge)
        try c.encodeIfPresent(rental, forKey: .rental)
    }
}

struct AssetState: Codable, Equatable {
    var movableAssets: [OwnedAsset] = []
    var properties: [OwnedProperty] = []
    var propertyHistory: [PropertyExitRecord] = []
    var nextOwnershipSequence: UInt64 = 1
    var nextTenantSequence: UInt64 = 1
    var nextGiftSequence: UInt64 = 1
    var nextLossSequence: UInt64 = 1
    var realEstateRandom = SeededRandom(seed: 1)
    var vehicleRandom = SeededRandom(seed: 1)
    var jewelryRandom = SeededRandom(seed: 1)
    var lossRandom = SeededRandom(seed: 1)
    var recentPropertyEventIDs: [String] = []
    var recentVehicleEventIDs: [String] = []
    var lastRentalIncome = 0
    var vehicleReplacementBudget = 0
    var notoriety = NotorietyState()
    var giftHistory: [AssetGiftRecord] = []
    var lossHistory: [AssetLossRecord] = []
    var recoveryCases: [AssetRecoveryCase] = []
    var nextRecoveryCaseID: UInt64 = 1
    var reciprocity = GiftReciprocityState()
    var movableAssetsAcquired = 0
    var movableAssetsGifted = 0
    var movableAssetsLost = 0
    var movableAssetsSold = 0
    var movableAssetSaleProceeds = 0

    var ownedCount: Int { movableAssets.count + properties.count }
    var movableResaleValue: Int { movableAssets.reduce(0) { $0 + $1.resaleValue } }
    var propertyEquity: Int { properties.reduce(0) { $0 + $1.equity } }
    var totalMortgageDebt: Int { properties.reduce(0) { $0 + $1.mortgageBalance } }
    var totalValue: Int { movableResaleValue + propertyEquity }
    var currentResaleValue: Int { movableResaleValue + properties.reduce(0) { $0 + $1.saleProceeds } }
    var highestValueMovableAsset: OwnedAsset? { movableAssets.max { $0.resaleValue < $1.resaleValue } }
    var hasDelinquentProperty: Bool { properties.contains { $0.delinquentYears >= 2 } }
    var primaryProperty: OwnedProperty? { properties.first(where: \.isPrimaryResidence) }
    var propertyMarketValue: Int { properties.reduce(0) { $0 + $1.currentValue } }
    var occupiedRentalCount: Int { properties.count { $0.use == .rental && $0.rental?.tenant != nil } }
    var vacantRentalCount: Int { properties.count { $0.use == .rental && $0.rental?.tenant == nil } }

    func count(in category: AssetCategory) -> Int {
        category == .houses ? properties.count : movableAssets.count { $0.category == category }
    }

    func vehicleCount(of kind: VehicleKind) -> Int {
        movableAssets.count { $0.vehicle?.kind == kind }
    }

    func vehicleValue(of kind: VehicleKind) -> Int {
        movableAssets.filter { $0.vehicle?.kind == kind }.reduce(0) { $0 + $1.resaleValue }
    }

    mutating func claimSequence() -> UInt64 {
        let result = nextOwnershipSequence
        nextOwnershipSequence &+= 1
        return result
    }

    mutating func claimGiftSequence() -> UInt64 {
        let result = nextGiftSequence
        nextGiftSequence &+= 1
        return result
    }

    mutating func claimLossSequence() -> UInt64 {
        let result = nextLossSequence
        nextLossSequence &+= 1
        return result
    }

    mutating func normalize() {
        movableAssets.removeAll { $0.category == .houses }
        for index in movableAssets.indices where movableAssets[index].category == .cars {
            if movableAssets[index].vehicle == nil {
                let kind = AssetCatalog.listing(for: movableAssets[index].listingID)?.vehicle?.kind ?? .car
                movableAssets[index].vehicle = OwnedVehicleState(kind: kind)
            }
            if var vehicle = movableAssets[index].vehicle {
                if vehicle.currentValue == 0 { vehicle.currentValue = movableAssets[index].purchasePrice }
                vehicle.condition = max(0, min(100, vehicle.condition))
                movableAssets[index].vehicle = vehicle
            }
            if let customName = movableAssets[index].vehicle?.customName {
                switch PlayerAssignedNamePolicy.validate(customName) {
                case .valid(let normalized): movableAssets[index].vehicle?.customName = normalized
                case .invalid: movableAssets[index].vehicle?.customName = nil
                }
            }
        }
        for index in movableAssets.indices where movableAssets[index].category == .guns {
            if var firearm = movableAssets[index].firearm {
                firearm.condition = max(0, min(100, firearm.condition))
                movableAssets[index].firearm = firearm
            }
        }
        for index in movableAssets.indices where movableAssets[index].category == .jewelry {
            if var jewelry = movableAssets[index].jewelry {
                if jewelry.marketValue == 0 { jewelry.marketValue = movableAssets[index].purchasePrice }
                jewelry.marketValue = max(1, jewelry.marketValue)
                jewelry.condition = max(0, min(100, jewelry.condition))
                movableAssets[index].jewelry = jewelry
            } else {
                movableAssets[index].jewelry = OwnedJewelryState(marketValue: movableAssets[index].purchasePrice)
            }
        }
        properties = properties.map { property in
            var copy = property
#if DEBUG
            assert(copy.mortgageBalance >= 0, "Mortgage balances cannot be negative")
#endif
            copy.mortgageBalance = max(0, copy.mortgageBalance)
            copy.delinquentYears = max(0, copy.delinquentYears)
            copy.condition = max(0, min(100, copy.condition))
            copy.marketAdjustment = max(-copy.purchasePrice / 4, min(copy.purchasePrice / 2, copy.marketAdjustment))
            if copy.use == .primaryResidence {
                copy.rental = nil
            } else if copy.use == .rental, copy.rental == nil {
                copy.use = .vacant
            } else if copy.use == .vacant {
                copy.rental = nil
            }
            if var rental = copy.rental {
                rental.vacancyYears = max(0, rental.vacancyYears)
                rental.lastCollectedRent = max(0, rental.lastCollectedRent)
                if var tenant = rental.tenant {
                    tenant.reliability = max(0, min(100, tenant.reliability))
                    tenant.care = max(0, min(100, tenant.care))
                    tenant.leaseYearsRemaining = max(1, tenant.leaseYearsRemaining)
                    rental.tenant = tenant
                }
                copy.rental = rental
            }
            var seenAmenities = Set<PropertyAmenityID>()
            copy.amenities = copy.amenities.compactMap { installed in
                guard seenAmenities.insert(installed.amenityID).inserted,
                      let definition = PropertyAmenityCatalog.definition(for: installed.amenityID),
                      (copy.propertyTier ?? .standard).rank >= definition.minimumTier.rank else { return nil }
                return InstalledPropertyAmenity(
                    amenityID: installed.amenityID,
                    installedAge: max(copy.purchaseAge, installed.installedAge),
                    paidPrice: max(0, installed.paidPrice),
                    valueContribution: max(0, installed.valueContribution),
                    annualUpkeep: max(0, installed.annualUpkeep)
                )
            }
            return copy
        }
        propertyHistory = Array(propertyHistory
            .sorted {
                if $0.exitAge == $1.exitAge { return $0.propertyID > $1.propertyID }
                return $0.exitAge > $1.exitAge
            }
            .prefix(6))
        nextTenantSequence = max(1, nextTenantSequence)
        nextGiftSequence = max(nextGiftSequence, (giftHistory.map(\.id).max() ?? 0) &+ 1)
        nextLossSequence = max(nextLossSequence, (lossHistory.map(\.id).max() ?? 0) &+ 1)
        recentPropertyEventIDs = Array(recentPropertyEventIDs.suffix(6))
        recentVehicleEventIDs = Array(recentVehicleEventIDs.suffix(6))
        lastRentalIncome = max(0, lastRentalIncome)
        vehicleReplacementBudget = max(0, vehicleReplacementBudget)
        notoriety.score = min(100, max(0, notoriety.score))
        notoriety.cleanYears = max(0, notoriety.cleanYears)
        giftHistory = Array(giftHistory.suffix(12))
        lossHistory = Array(lossHistory.suffix(12))
        recoveryCases = Array(recoveryCases.suffix(4)); recoveryCases.indices.forEach { recoveryCases[$0].clamp() }
        nextRecoveryCaseID = max(nextRecoveryCaseID, (recoveryCases.map(\.id).max() ?? 0) &+ 1)
        movableAssetsAcquired = max(0, movableAssetsAcquired)
        movableAssetsGifted = max(0, movableAssetsGifted)
        movableAssetsLost = max(0, movableAssetsLost)
        movableAssetsSold = max(0, movableAssetsSold)
        movableAssetSaleProceeds = max(0, movableAssetSaleProceeds)
        reciprocity.balances = reciprocity.balances.mapValues { min(25_000, max(0, $0)) }
        reciprocity.usedEventKeys = Array(reciprocity.usedEventKeys.prefix(24))
        if properties.isEmpty {
            nextOwnershipSequence = max(1, nextOwnershipSequence)
            return
        }
        let preferredID = properties
            .filter(\.isPrimaryResidence)
            .sorted { ($0.purchaseAge, $0.id) < ($1.purchaseAge, $1.id) }
            .first?.id
            ?? properties.filter { $0.use == .vacant }
                .sorted { ($0.purchaseAge, $0.id) < ($1.purchaseAge, $1.id) }
                .first?.id
        for index in properties.indices where properties[index].isPrimaryResidence {
            properties[index].isPrimaryResidence = properties[index].id == preferredID
        }
        if let preferredID,
           let index = properties.firstIndex(where: { $0.id == preferredID }),
           properties[index].use == .vacant {
            properties[index].isPrimaryResidence = true
        }
        let maximumID = (movableAssets.map(\.id) + properties.map(\.id)).max() ?? 0
        nextOwnershipSequence = max(nextOwnershipSequence, maximumID &+ 1)
    }
}

extension AssetState {
    enum CodingKeys: String, CodingKey {
        case movableAssets, properties, propertyHistory, nextOwnershipSequence
        case nextTenantSequence, nextGiftSequence, nextLossSequence, realEstateRandom, recentPropertyEventIDs, lastRentalIncome
        case vehicleRandom, jewelryRandom, lossRandom, recentVehicleEventIDs, vehicleReplacementBudget
        case notoriety, giftHistory, lossHistory, recoveryCases, nextRecoveryCaseID, reciprocity, movableAssetsAcquired, movableAssetsGifted, movableAssetsLost, movableAssetsSold, movableAssetSaleProceeds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        movableAssets = try c.decodeIfPresent([OwnedAsset].self, forKey: .movableAssets) ?? []
        properties = try c.decodeIfPresent([OwnedProperty].self, forKey: .properties) ?? []
        propertyHistory = try c.decodeIfPresent([PropertyExitRecord].self, forKey: .propertyHistory) ?? []
        nextOwnershipSequence = try c.decodeIfPresent(UInt64.self, forKey: .nextOwnershipSequence) ?? 1
        nextTenantSequence = try c.decodeIfPresent(UInt64.self, forKey: .nextTenantSequence) ?? 1
        nextGiftSequence = try c.decodeIfPresent(UInt64.self, forKey: .nextGiftSequence) ?? 1
        nextLossSequence = try c.decodeIfPresent(UInt64.self, forKey: .nextLossSequence) ?? 1
        realEstateRandom = try c.decodeIfPresent(SeededRandom.self, forKey: .realEstateRandom) ?? SeededRandom(seed: 1)
        vehicleRandom = try c.decodeIfPresent(SeededRandom.self, forKey: .vehicleRandom) ?? SeededRandom(seed: 1)
        jewelryRandom = try c.decodeIfPresent(SeededRandom.self, forKey: .jewelryRandom) ?? SeededRandom(seed: 1)
        lossRandom = try c.decodeIfPresent(SeededRandom.self, forKey: .lossRandom) ?? SeededRandom(seed: 1)
        recentPropertyEventIDs = try c.decodeIfPresent([String].self, forKey: .recentPropertyEventIDs) ?? []
        recentVehicleEventIDs = try c.decodeIfPresent([String].self, forKey: .recentVehicleEventIDs) ?? []
        lastRentalIncome = try c.decodeIfPresent(Int.self, forKey: .lastRentalIncome) ?? 0
        vehicleReplacementBudget = try c.decodeIfPresent(Int.self, forKey: .vehicleReplacementBudget) ?? 0
        notoriety = try c.decodeIfPresent(NotorietyState.self, forKey: .notoriety) ?? NotorietyState()
        giftHistory = try c.decodeIfPresent([AssetGiftRecord].self, forKey: .giftHistory) ?? []
        lossHistory = try c.decodeIfPresent([AssetLossRecord].self, forKey: .lossHistory) ?? []
        recoveryCases = try c.decodeIfPresent([AssetRecoveryCase].self, forKey: .recoveryCases) ?? []
        nextRecoveryCaseID = try c.decodeIfPresent(UInt64.self, forKey: .nextRecoveryCaseID) ?? 1
        reciprocity = try c.decodeIfPresent(GiftReciprocityState.self, forKey: .reciprocity) ?? GiftReciprocityState()
        movableAssetsAcquired = try c.decodeIfPresent(Int.self, forKey: .movableAssetsAcquired) ?? movableAssets.count
        movableAssetsGifted = try c.decodeIfPresent(Int.self, forKey: .movableAssetsGifted) ?? 0
        movableAssetsLost = try c.decodeIfPresent(Int.self, forKey: .movableAssetsLost) ?? 0
        movableAssetsSold = try c.decodeIfPresent(Int.self, forKey: .movableAssetsSold) ?? 0
        movableAssetSaleProceeds = try c.decodeIfPresent(Int.self, forKey: .movableAssetSaleProceeds) ?? 0
    }
}

enum AssetTransactionKind: String, Codable { case purchase, sale, upgrade, management, repair, totalLoss }

enum VehicleRenameResult: Equatable {
    case renamed(String)
    case rejected(String)
}

struct AssetTransaction: Codable, Equatable {
    let kind: AssetTransactionKind
    let category: AssetCategory
    let listingID: String
    let ownershipID: UInt64
    let headline: String
    let detail: String
    let cashDelta: Int
    var legalHeatDelta = 0
}

struct AssetFinancialSnapshot: Equatable {
    let annualPropertyCosts: Int
    let mortgageInterest: Int
    let securedDebt: Int
    let propertyEquity: Int
    let rentalIncome: Int
    let occupiedRentals: Int
    let vacantRentals: Int

    static let empty = AssetFinancialSnapshot(
        annualPropertyCosts: 0,
        mortgageInterest: 0,
        securedDebt: 0,
        propertyEquity: 0,
        rentalIncome: 0,
        occupiedRentals: 0,
        vacantRentals: 0
    )
}

enum PropertyEventAction: String, Codable {
    case offerPaymentPlan, formalNotice, repairNow, deferRepair
    case renewLease, raiseRent, absorbDamage, retainDeposit, lowerRent, holdRent
}

enum VehicleEventAction: String, Codable {
    case repair, deferRepair, sell, keepSettlement, replace
}

struct VehicleEventEffect: Codable, Equatable {
    let vehicleID: UInt64
    let action: VehicleEventAction
}

struct PropertyEventEffect: Codable, Equatable {
    let propertyID: UInt64
    let action: PropertyEventAction
}

struct PropertyYearPreparation {
    let financialSnapshot: AssetFinancialSnapshot
    var outcome: AssetYearOutcome
    var event: LifeEvent?
}

struct AssetYearOutcome: Equatable {
    var bullets: [String] = []
    var notes: [String] = []
    var newlyDelinquent = false
    var foreclosedCount = 0
    var cashSettlement = 0
    var lostPrimary = false
    var consequences: [DomainConsequence] = []
}

enum AssetSystem {
    private static let realEstateSeedSalt: UInt64 = 0x5245_414C_4553_5441
    private static let vehicleSeedSalt: UInt64 = 0x5645_4849_434C_4553
    private static let lossSeedSalt: UInt64 = 0x4C4F_5353_524E_4753

    static func initialize(runSeed: UInt64) -> AssetState {
        AssetState(
            realEstateRandom: SeededRandom(seed: derivedRealEstateSeed(from: runSeed)),
            vehicleRandom: SeededRandom(seed: derivedVehicleSeed(from: runSeed)),
            jewelryRandom: SeededRandom(seed: derivedJewelrySeed(from: runSeed)),
            lossRandom: SeededRandom(seed: derivedLossSeed(from: runSeed))
        )
    }

    static func availability(for listing: AssetListing, state: LifeState) -> Availability {
        if state.isGameOver { return .locked("This life has ended") }
        if state.finance.economy.workoutYearsRemaining > 0 { return .locked("Debt workout pauses purchases") }
        if state.character.age < listing.minimumAge { return .locked("Available at age \(listing.minimumAge)") }
        if state.cash < listing.terms.committedCash { return .locked("Requires $\(listing.terms.committedCash)") }
        if let firearm = listing.firearm {
            if firearm.market == .legal, state.legal.isFelon {
                return .locked("Felony record blocks legal purchase")
            }
            if acquisitionRoll(runSeed: state.runSeed, key: listing.id, age: state.character.age) > firearm.rarity.acquisitionChance {
                return .locked("No \(firearm.rarity.rawValue) seller this year")
            }
        }
        if let vehicle = listing.vehicle,
           let minimumLevel = vehicle.minimumCareerLevel,
           !career(state.career.level, meets: minimumLevel) {
            if minimumLevel == .entry { return .locked("Requires employment") }
            let article = minimumLevel == .established ? "an" : "a"
            return .locked("Requires \(article) \(minimumLevel.rawValue) career")
        }
        if case .mortgage(_, _, _, let minimumLevel) = listing.terms,
           !career(state.career.level, meets: minimumLevel) {
            return .locked(minimumLevel == .entry ? "Requires employment" : "Requires a \(minimumLevel.rawValue) career")
        }
        if case .mortgage(let value, let downPayment, let annualCost, _) = listing.terms,
           !canCarrySecondaryMortgage(mortgageBalance: value - downPayment, annualCost: annualCost, state: state) {
            return .locked("Income cannot support another mortgage")
        }
        return .available
    }

    static func purchase(listingID: String, state: inout LifeState) -> AssetTransaction? {
        guard let listing = AssetCatalog.listing(for: listingID), availability(for: listing, state: state) == .available else { return nil }
        let ownershipID = state.assets.claimSequence()
        let cashDelta: Int
        switch listing.terms {
        case .cash(let price):
            _ = FinanceSystem.transact(.init(amount: -price, purpose: .optionalPurchase), state: &state)
            if listing.vehicle != nil, state.assets.vehicleReplacementBudget > 0 {
                state.assets.vehicleReplacementBudget = max(0, state.assets.vehicleReplacementBudget - price)
            }
            state.assets.movableAssets.append(
                OwnedAsset(
                    id: ownershipID,
                    listingID: listing.id,
                    category: listing.category,
                    name: listing.name,
                    purchaseAge: state.character.age,
                    purchasePrice: price,
                    firearm: listing.firearm.map {
                        OwnedFirearmState(market: $0.market, rarity: $0.rarity, baseHeat: $0.heat)
                    },
                    vehicle: listing.vehicle.map { OwnedVehicleState(kind: $0.kind) },
                    jewelry: listing.category == .jewelry ? OwnedJewelryState(marketValue: price) : nil
                )
            )
            state.assets.movableAssetsAcquired += 1
            if listing.firearm?.market == .illicit {
                state.assets.notoriety.adjust(3, age: state.character.age)
            }
            cashDelta = -price
        case .mortgage(let value, let downPayment, let annualCost, _):
            _ = FinanceSystem.transact(.init(amount: -downPayment, purpose: .optionalPurchase), state: &state)
            let tier = listing.property?.tier ?? .standard
            state.assets.properties.append(
                OwnedProperty(
                    id: ownershipID,
                    listingID: listing.id,
                    name: listing.name,
                    purchaseAge: state.character.age,
                    purchasePrice: value,
                    mortgageBalance: value - downPayment,
                    annualCost: annualCost,
                    delinquentYears: 0,
                    isPrimaryResidence: state.assets.primaryProperty == nil,
                    propertyType: listing.property?.type,
                    propertyTier: listing.property?.tier,
                    condition: initialCondition(for: tier)
                )
            )
            cashDelta = -downPayment
        }
        state.assets.normalize()
        if state.cash < 0 { state.finance.consumerDebt = EconomyPolicy.checkedAdd(state.finance.consumerDebt, -state.cash); state.cash = 0 }
        return AssetTransaction(
            kind: .purchase,
            category: listing.category,
            listingID: listing.id,
            ownershipID: ownershipID,
            headline: "You Bought \(listing.name)",
            detail: purchaseDetail(for: listing),
            cashDelta: cashDelta,
            legalHeatDelta: listing.firearm?.heat ?? 0
        )
    }

    static func upgradeAvailability(
        _ upgrade: FirearmUpgradeDefinition,
        ownershipID: UInt64,
        state: LifeState
    ) -> Availability {
        if state.finance.economy.workoutYearsRemaining > 0 { return .locked("Purchases pause during debt relief") }
        guard let owned = state.assets.movableAssets.first(where: { $0.id == ownershipID }),
              let firearm = owned.firearm else { return .locked("Requires an owned firearm") }
        if firearm.upgrades.contains(upgrade.id) { return .locked("Already installed") }
        if state.cash < upgrade.price { return .locked("Requires $\(upgrade.price)") }
        if upgrade.market == .legal, state.legal.isFelon { return .locked("Felony record blocks legal purchase") }
        let key = "upgrade:\(upgrade.id.rawValue):\(ownershipID)"
        if acquisitionRoll(runSeed: state.runSeed, key: key, age: state.character.age) > upgrade.rarity.acquisitionChance {
            return .locked("No \(upgrade.rarity.rawValue) supplier this year")
        }
        return .available
    }

    static func renameVehicle(
        ownershipID: UInt64,
        to rawName: String,
        state: inout LifeState
    ) -> VehicleRenameResult {
        guard let index = state.assets.movableAssets.firstIndex(where: { $0.id == ownershipID }),
              state.assets.movableAssets[index].vehicle != nil else {
            return .rejected("That vehicle is no longer owned.")
        }
        switch PlayerAssignedNamePolicy.validate(rawName) {
        case .invalid(let reason):
            return .rejected(reason)
        case .valid(let normalized):
            state.assets.movableAssets[index].vehicle?.customName = normalized
            return .renamed(normalized)
        }
    }

    static func clearVehicleName(ownershipID: UInt64, state: inout LifeState) -> Bool {
        guard let index = state.assets.movableAssets.firstIndex(where: { $0.id == ownershipID }),
              state.assets.movableAssets[index].vehicle != nil else { return false }
        state.assets.movableAssets[index].vehicle?.customName = nil
        return true
    }

    static func upgradeFirearm(
        ownershipID: UInt64,
        upgradeID: FirearmUpgradeID,
        state: inout LifeState
    ) -> AssetTransaction? {
        let upgrade = FirearmUpgradeCatalog.definition(for: upgradeID)
        guard upgradeAvailability(upgrade, ownershipID: ownershipID, state: state) == .available,
              let index = state.assets.movableAssets.firstIndex(where: { $0.id == ownershipID }),
              state.assets.movableAssets[index].firearm != nil else { return nil }
        _ = FinanceSystem.transact(.init(amount: -upgrade.price, purpose: .optionalPurchase), state: &state)
        state.assets.movableAssets[index].firearm?.upgrades.append(upgrade.id)
        if upgrade.market == .illicit {
            state.assets.notoriety.adjust(2, age: state.character.age)
        }
        if state.cash < 0 { state.finance.consumerDebt = EconomyPolicy.checkedAdd(state.finance.consumerDebt, -state.cash); state.cash = 0 }
        return AssetTransaction(
            kind: .upgrade,
            category: .guns,
            listingID: "upgrade-\(upgrade.id.rawValue)",
            ownershipID: ownershipID,
            headline: "You Added \(upgrade.name)",
            detail: upgrade.market == .illicit
                ? "The prohibited upgrade added \(upgrade.heat) heat. No operational use is simulated."
                : "The lawful accessory was added without legal heat.",
            cashDelta: -upgrade.price,
            legalHeatDelta: upgrade.heat
        )
    }

    static func vehicleUpgradeAvailability(_ upgrade: VehicleUpgradeDefinition, ownershipID: UInt64, state: LifeState) -> Availability {
        if state.finance.economy.workoutYearsRemaining > 0 { return .locked("Purchases pause during debt relief") }
        guard let owned = state.assets.movableAssets.first(where: { $0.id == ownershipID }), let vehicle = owned.vehicle else { return .locked("Requires an owned vehicle") }
        guard upgrade.allowedKinds.contains(vehicle.kind) else { return .locked("Not compatible with this vehicle") }
        if vehicle.upgrades.contains(upgrade.id) { return .locked("Already installed") }
        if state.cash < upgrade.price { return .locked("Requires $(upgrade.price)") }
        return .available
    }

    static func upgradeVehicle(ownershipID: UInt64, upgradeID: VehicleUpgradeID, state: inout LifeState) -> AssetTransaction? {
        let upgrade = VehicleUpgradeCatalog.definition(for: upgradeID)
        guard vehicleUpgradeAvailability(upgrade, ownershipID: ownershipID, state: state) == .available,
              let index = state.assets.movableAssets.firstIndex(where: { $0.id == ownershipID }),
              var vehicle = state.assets.movableAssets[index].vehicle else { return nil }
        _ = FinanceSystem.transact(.init(amount: -upgrade.price, purpose: .optionalPurchase), state: &state)
        vehicle.upgrades.append(upgrade.id)
        vehicle.currentValue += upgrade.valueContribution
        vehicle.condition = max(0, vehicle.condition - upgrade.conditionCost)
        state.assets.movableAssets[index].vehicle = vehicle
        state.assets.normalize()
        return AssetTransaction(
            kind: .upgrade,
            category: .cars,
            listingID: "vehicle-upgrade-\(upgrade.id.rawValue)",
            ownershipID: ownershipID,
            headline: "You Added \(upgrade.name)",
            detail: "\(state.assets.movableAssets[index].displayName) gained \(upgrade.performance) performance and \(upgrade.protection) protection.",
            cashDelta: -upgrade.price
        )
    }

    static func firearmManagementAvailability(
        _ action: FirearmManagementAction,
        ownershipID: UInt64,
        state: LifeState
    ) -> Availability {
        guard let owned = state.assets.movableAssets.first(where: { $0.id == ownershipID }),
              let firearm = owned.firearm else { return .locked("Requires an owned firearm") }
        if action == .secureStorage, firearm.secureStorage { return .locked("Storage is already secure") }
        if action == .inspection, firearm.lastInspectionAge == state.character.age { return .locked("Already inspected this year") }
        if state.cash < action.price { return .locked("Requires $(action.price)") }
        return .available
    }

    static func manageFirearm(
        ownershipID: UInt64,
        action: FirearmManagementAction,
        state: inout LifeState
    ) -> AssetTransaction? {
        guard firearmManagementAvailability(action, ownershipID: ownershipID, state: state) == .available,
              let index = state.assets.movableAssets.firstIndex(where: { $0.id == ownershipID }),
              var firearm = state.assets.movableAssets[index].firearm else { return nil }
        _ = FinanceSystem.transact(.init(amount: -action.price, purpose: .optionalPurchase), state: &state)
        switch action {
        case .secureStorage:
            firearm.secureStorage = true
        case .inspection:
            firearm.condition = min(100, firearm.condition + action.conditionGain)
            firearm.lastInspectionAge = state.character.age
        }
        state.assets.movableAssets[index].firearm = firearm
        state.assets.normalize()
        return AssetTransaction(
            kind: .management,
            category: .guns,
            listingID: state.assets.movableAssets[index].listingID,
            ownershipID: ownershipID,
            headline: "\(action.title) Completed",
            detail: "The firearm is now \(firearm.condition)% condition with \(firearm.secureStorage ? "secure" : "unsecured") storage.",
            cashDelta: -action.price
        )
    }

    static func amenityAvailability(
        _ amenity: PropertyAmenityDefinition,
        propertyID: UInt64,
        state: LifeState
    ) -> Availability {
        if state.finance.economy.workoutYearsRemaining > 0 { return .locked("Purchases pause during debt relief") }
        guard let property = state.assets.properties.first(where: { $0.id == propertyID }) else {
            return .locked("Requires an owned property")
        }
        if property.amenities.contains(where: { $0.amenityID == amenity.id }) {
            return .locked("Already installed")
        }
        let tier = property.propertyTier ?? .standard
        if tier.rank < amenity.minimumTier.rank {
            return .locked("Requires a \(amenity.minimumTier.rawValue) property")
        }
        if property.delinquentYears >= 2 { return .locked("Resolve mortgage delinquency first") }
        if state.cash < amenity.installationPrice { return .locked("Requires $\(amenity.installationPrice)") }
        return .available
    }

    static func installAmenity(
        propertyID: UInt64,
        amenityID: PropertyAmenityID,
        state: inout LifeState
    ) -> AssetTransaction? {
        guard let amenity = PropertyAmenityCatalog.definition(for: amenityID),
              amenityAvailability(amenity, propertyID: propertyID, state: state) == .available,
              let index = state.assets.properties.firstIndex(where: { $0.id == propertyID }) else { return nil }
        _ = FinanceSystem.transact(.init(amount: -amenity.installationPrice, purpose: .optionalPurchase), state: &state)
        state.assets.properties[index].amenities.append(
            InstalledPropertyAmenity(
                amenityID: amenity.id,
                installedAge: state.character.age,
                paidPrice: amenity.installationPrice,
                valueContribution: amenity.valueContribution,
                annualUpkeep: amenity.annualUpkeep
            )
        )
        state.assets.normalize()
        if state.cash < 0 { state.finance.consumerDebt = EconomyPolicy.checkedAdd(state.finance.consumerDebt, -state.cash); state.cash = 0 }
        return AssetTransaction(
            kind: .upgrade,
            category: .houses,
            listingID: "amenity-\(amenity.id.rawValue)",
            ownershipID: propertyID,
            headline: "You Added \(amenity.name)",
            detail: "The $\(amenity.installationPrice) installation added $\(amenity.valueContribution) in property value and $\(amenity.annualUpkeep) in yearly upkeep.",
            cashDelta: -amenity.installationPrice
        )
    }

    static func rentalAvailability(propertyID: UInt64, state: LifeState) -> Availability {
        guard let property = state.assets.properties.first(where: { $0.id == propertyID }) else {
            return .locked("Requires an owned property")
        }
        if property.isPrimaryResidence { return .locked("Primary residence cannot be rented") }
        if property.delinquentYears >= 2 { return .locked("Resolve mortgage delinquency first") }
        if property.use == .rental { return .locked("Already listed as a rental") }
        return .available
    }

    static func projectedAnnualRent(for property: OwnedProperty, strategy: RentalStrategy) -> Int {
        max(0, property.currentValue * 6 / 100 * strategy.rentPercent / 100)
    }

    static func listPropertyForRent(
        propertyID: UInt64,
        strategy: RentalStrategy,
        state: inout LifeState
    ) -> AssetTransaction? {
        guard rentalAvailability(propertyID: propertyID, state: state) == .available,
              let index = state.assets.properties.firstIndex(where: { $0.id == propertyID }) else { return nil }
        state.assets.properties[index].use = .rental
        state.assets.properties[index].rental = RentalPropertyState(
            strategy: strategy,
            tenant: nil,
            listedAge: state.character.age
        )
        state.assets.properties[index].lastRentStrategyAge = state.character.age
        let property = state.assets.properties[index]
        return AssetTransaction(
            kind: .management,
            category: .houses,
            listingID: "rental-listing:\(property.listingID)",
            ownershipID: property.id,
            headline: "You Listed \(property.name)",
            detail: "The \(strategy.title.lowercased()) strategy targets $\(property.expectedMarketRent) per year. A tenant search begins next year.",
            cashDelta: 0
        )
    }

    static func changeRentalStrategy(
        propertyID: UInt64,
        strategy: RentalStrategy,
        state: inout LifeState
    ) -> AssetTransaction? {
        guard let index = state.assets.properties.firstIndex(where: { $0.id == propertyID }),
              state.assets.properties[index].use == .rental,
              state.assets.properties[index].rental != nil,
              state.assets.properties[index].lastRentStrategyAge != state.character.age else { return nil }
        state.assets.properties[index].rental?.strategy = strategy
        state.assets.properties[index].lastRentStrategyAge = state.character.age
        let property = state.assets.properties[index]
        return AssetTransaction(
            kind: .management,
            category: .houses,
            listingID: "rent-strategy:\(property.listingID)",
            ownershipID: property.id,
            headline: "Rent Strategy Changed",
            detail: "\(property.name) now uses the \(strategy.title.lowercased()) strategy at about $\(property.expectedMarketRent) per year.",
            cashDelta: 0
        )
    }

    static func withdrawRentalListing(propertyID: UInt64, state: inout LifeState) -> AssetTransaction? {
        guard let index = state.assets.properties.firstIndex(where: { $0.id == propertyID }),
              state.assets.properties[index].use == .rental,
              state.assets.properties[index].rental?.tenant == nil else { return nil }
        let property = state.assets.properties[index]
        state.assets.properties[index].use = .vacant
        state.assets.properties[index].rental = nil
        return AssetTransaction(
            kind: .management,
            category: .houses,
            listingID: "rental-withdraw:\(property.listingID)",
            ownershipID: property.id,
            headline: "Rental Listing Withdrawn",
            detail: "\(property.name) is vacant and no longer searching for tenants.",
            cashDelta: 0
        )
    }

    static func repairCost(_ kind: PropertyRepairKind, property: OwnedProperty) -> Int {
        switch kind {
        case .routine: max(4_000, EconomyPolicy.rate(property.currentValue, 100))
        case .restoration: max(12_000, property.currentValue * 8 / 100)
        }
    }

    static func repairAvailability(
        _ kind: PropertyRepairKind,
        propertyID: UInt64,
        state: LifeState
    ) -> Availability {
        guard let property = state.assets.properties.first(where: { $0.id == propertyID }) else {
            return .locked("Requires an owned property")
        }
        if property.delinquentYears >= 2 { return .locked("Resolve mortgage delinquency first") }
        if property.lastRepairAge == state.character.age { return .locked("Already repaired this year") }
        if kind == .restoration, property.condition >= 60 { return .locked("Available below 60 condition") }
        let cost = repairCost(kind, property: property)
        if state.cash < cost { return .locked("Requires $\(cost)") }
        return .available
    }

    static func performPropertyRepair(
        propertyID: UInt64,
        kind: PropertyRepairKind,
        state: inout LifeState
    ) -> AssetTransaction? {
        guard repairAvailability(kind, propertyID: propertyID, state: state) == .available,
              let index = state.assets.properties.firstIndex(where: { $0.id == propertyID }) else { return nil }
        let cost = repairCost(kind, property: state.assets.properties[index])
        _ = FinanceSystem.transact(.init(amount: -cost, purpose: .optionalPurchase), state: &state)
        state.assets.properties[index].condition = min(
            100,
            state.assets.properties[index].condition + kind.conditionGain
        )
        state.assets.properties[index].lastRepairAge = state.character.age
        let property = state.assets.properties[index]
        if state.cash < 0 { state.finance.consumerDebt = EconomyPolicy.checkedAdd(state.finance.consumerDebt, -state.cash); state.cash = 0 }
        return AssetTransaction(
            kind: .repair,
            category: .houses,
            listingID: "property-repair:\(kind.rawValue)",
            ownershipID: property.id,
            headline: "\(kind.title) Completed",
            detail: "\(property.name) reached \(property.condition)% condition after $\(cost) in work.",
            cashDelta: -cost
        )
    }

    static func sell(ownershipID: UInt64, state: inout LifeState) -> AssetTransaction? {
        guard !committedCriminalAssetIDs(state: state).contains(ownershipID) else { return nil }
        if let index = state.assets.movableAssets.firstIndex(where: { $0.id == ownershipID }) {
            let owned = state.assets.movableAssets.remove(at: index)
            let proceeds = owned.resaleValue
            state.assets.movableAssetSaleProceeds += proceeds
            state.assets.movableAssetsSold += 1
            _ = FinanceSystem.transact(.init(amount: proceeds, purpose: .household), state: &state)
            state.aggregates.recordIncome(max(0, proceeds - owned.purchasePrice), source: .assetSale)
            if state.cash < 0 { state.finance.consumerDebt = EconomyPolicy.checkedAdd(state.finance.consumerDebt, -state.cash); state.cash = 0 }
            return AssetTransaction(
                kind: .sale,
                category: owned.category,
                listingID: owned.listingID,
                ownershipID: owned.id,
                headline: "You Sold \(owned.displayName)",
                detail: "The sale returned $\(proceeds), well below what you paid.",
                cashDelta: proceeds
            )
        }
        guard let index = state.assets.properties.firstIndex(where: { $0.id == ownershipID }) else { return nil }
        let owned = state.assets.properties.remove(at: index)
        let proceeds = owned.saleProceeds
        _ = FinanceSystem.transact(.init(amount: proceeds, purpose: .household), state: &state)
        state.aggregates.recordIncome(max(0, proceeds - owned.purchasePrice), source: .assetSale)
        state.assets.propertyHistory.insert(
            PropertyExitRecord(
                propertyID: owned.id,
                name: owned.name,
                purchaseAge: owned.purchaseAge,
                exitAge: state.character.age,
                reason: .sold,
                finalValue: owned.currentValue,
                finalMortgage: owned.mortgageBalance,
                cashRecovered: proceeds,
                amenityCount: owned.amenities.count
            ),
            at: 0
        )
        state.assets.normalize()
        if state.cash < 0 { state.finance.consumerDebt = EconomyPolicy.checkedAdd(state.finance.consumerDebt, -state.cash); state.cash = 0 }
        return AssetTransaction(
            kind: .sale,
            category: .houses,
            listingID: owned.listingID,
            ownershipID: owned.id,
            headline: "You Sold \(owned.name)",
            detail: "The mortgage and $\(owned.closingCost) closing cost were paid before $\(proceeds) reached you.\(owned.rental?.tenant == nil ? "" : " The existing lease transferred with the property.")",
            cashDelta: proceeds
        )
    }

    static func financialSnapshot(assets: AssetState, world: WorldModifierSnapshot) -> AssetFinancialSnapshot {
        let propertyCosts = assets.properties.reduce(0) {
            $0 + Int((Double($1.totalAnnualCost) * world.housingCostMultiplier).rounded())
        }
        let householdRent = assets.primaryProperty == nil
            ? Int((Double(EconomyPolicy.rent) * world.housingCostMultiplier).rounded())
            : 0
        return AssetFinancialSnapshot(
            annualPropertyCosts: propertyCosts + householdRent,
            mortgageInterest: assets.properties.reduce(0) { $0 + EconomyPolicy.rate($1.mortgageBalance, 600) },
            securedDebt: assets.totalMortgageDebt,
            propertyEquity: assets.propertyEquity,
            rentalIncome: assets.lastRentalIncome,
            occupiedRentals: assets.occupiedRentalCount,
            vacantRentals: assets.vacantRentalCount
        )
    }

    static func prepareYear(
        assets: inout AssetState,
        world: WorldModifierSnapshot,
        age: Int
    ) -> PropertyYearPreparation {
        var outcome = AssetYearOutcome()
        var collectedRent = 0
        var eventCandidates: [(String, UInt64)] = []
        var vehicleEventCandidates: [(String, UInt64)] = []
        var lossCandidates: [UInt64] = []
        let hasRiskyExposure = assets.movableAssets.contains { owned in
            guard let firearm = owned.firearm else { return false }
            return firearm.market == .illicit || firearm.storageRisk > 0 || assets.notoriety.score > 0
        }
        if hasRiskyExposure { assets.notoriety.cleanYears = 0 } else { assets.notoriety.recordCleanYear() }

        for index in assets.movableAssets.indices where assets.movableAssets[index].firearm != nil {
            guard var firearm = assets.movableAssets[index].firearm else { continue }
            firearm.condition = max(0, firearm.condition - (firearm.secureStorage ? 1 : 3))
            assets.movableAssets[index].firearm = firearm
        }

        for index in assets.movableAssets.indices where assets.movableAssets[index].jewelry != nil {
            guard var jewelry = assets.movableAssets[index].jewelry else { continue }
            let movement = assets.jewelryRandom.next(in: 1...100)
            if movement <= 12 {
                jewelry.marketValue += max(1, jewelry.marketValue / 100)
            } else if movement >= 88 {
                jewelry.marketValue = max(1, jewelry.marketValue - max(1, jewelry.marketValue / 100))
            }
            jewelry.condition = max(0, jewelry.condition - 1)
            assets.movableAssets[index].jewelry = jewelry
        }

        for index in assets.movableAssets.indices where assets.movableAssets[index].vehicle != nil {
            guard var vehicle = assets.movableAssets[index].vehicle else { continue }
            let owned = assets.movableAssets[index]
            let vehicleAge = max(0, age - owned.purchaseAge)
            let rate = depreciationRate(for: vehicle.kind, age: vehicleAge)
            if vehicle.kind == .plane, assets.vehicleRandom.next(in: 1...100) <= 12 {
                vehicle.currentValue = max(vehicle.currentValue, vehicle.currentValue + max(1, vehicle.currentValue * 1 / 100))
            } else {
                vehicle.currentValue = max(residualRate(for: vehicle.kind) * owned.purchasePrice / 100, vehicle.currentValue * (100 - rate) / 100)
            }
            vehicle.condition = max(0, vehicle.condition - conditionLoss(for: vehicle.kind))

            if vehicle.repairState == .healthy,
               (vehicleAge >= breakdownAge(for: vehicle.kind) || vehicle.condition < 68),
               assets.vehicleRandom.next(in: 1...100) <= breakdownChance(condition: vehicle.condition, age: vehicleAge) {
                if vehicle.condition <= 22,
                   assets.vehicleRandom.next(in: 1...100) <= 35 {
                    vehicle.repairState = .totaled
                    vehicleEventCandidates.append(("vehicle-total-loss", owned.id))
                } else {
                    vehicle.repairState = .needsRepair
                    vehicleEventCandidates.append(("vehicle-breakdown", owned.id))
                }
            }
            assets.movableAssets[index].vehicle = vehicle
        }

        for owned in assets.movableAssets {
            let chance = assetLossChance(for: owned, assets: assets)
            if chance > 0, assets.lossRandom.next(in: 1...100) <= chance {
                lossCandidates.append(owned.id)
            }
        }
        if lossCandidates.count > 1 {
            lossCandidates = [lossCandidates[assets.lossRandom.next(in: 0...(lossCandidates.count - 1))]]
        }

        for index in assets.properties.indices {
            let marketDelta = Int((Double(assets.properties[index].purchasePrice) * world.propertyValueGrowthRate).rounded())
            assets.properties[index].marketAdjustment += marketDelta
            let lower = -assets.properties[index].purchasePrice / 4
            let upper = assets.properties[index].purchasePrice / 2
            assets.properties[index].marketAdjustment = max(lower, min(upper, assets.properties[index].marketAdjustment))

            switch assets.properties[index].use {
            case .primaryResidence:
                assets.properties[index].condition -= 2
            case .vacant:
                assets.properties[index].condition -= 1
            case .rental:
                guard var rental = assets.properties[index].rental else { continue }
                rental.missedPaymentThisYear = false
                if rental.tenant == nil {
                    rental.vacancyYears += 1
                    if assets.realEstateRandom.next(in: 1...100) <= rental.strategy.fillChance {
                        rental.tenant = makeTenant(assets: &assets, age: age)
                        rental.restrictedDeposit = assets.properties[index].expectedMarketRent / 12
                        rental.vacancyYears = 0
                        outcome.bullets.append("Tenant found: \(assets.properties[index].name)")
                    } else if rental.vacancyYears >= 2 {
                        eventCandidates.append(("property-long-vacancy", assets.properties[index].id))
                    }
                }
                if var tenant = rental.tenant {
                    let wearAdjustment = tenant.care >= 80 ? -1 : (tenant.care < 60 ? 2 : 0)
                    assets.properties[index].condition -= 3 + wearAdjustment
                    let rent = projectedAnnualRent(for: assets.properties[index], strategy: rental.strategy)
                    let threshold = max(0, min(100, tenant.reliability + rental.strategy.reliabilityModifier))
                    if assets.realEstateRandom.next(in: 1...100) <= threshold {
                        rental.lastCollectedRent = rent
                    } else {
                        rental.lastCollectedRent = rent / 2
                        rental.missedPaymentThisYear = true
                        eventCandidates.append(("property-missed-rent", assets.properties[index].id))
                    }
                    collectedRent += rental.lastCollectedRent
                    tenant.leaseYearsRemaining -= 1
                    if tenant.leaseYearsRemaining <= 0 {
                        if assets.realEstateRandom.next(in: 1...100) <= rental.strategy.renewalChance {
                            tenant.leaseYearsRemaining = assets.realEstateRandom.next(in: 2...4)
                        } else {
                            eventCandidates.append(("property-lease-renewal", assets.properties[index].id))
                            tenant.leaseYearsRemaining = 1
                        }
                        rental.tenant = tenant
                    } else {
                        rental.tenant = tenant
                    }
                    if tenant.care < 60, assets.realEstateRandom.next(in: 1...100) <= 18 {
                        eventCandidates.append(("property-tenant-damage", assets.properties[index].id))
                    }
                } else {
                    assets.properties[index].condition -= 1
                }
                assets.properties[index].rental = rental
            }
            assets.properties[index].condition = max(0, min(100, assets.properties[index].condition))
            if assets.properties[index].condition < 50 {
                eventCandidates.append(("property-urgent-repair", assets.properties[index].id))
            }
        }

        assets.lastRentalIncome = collectedRent
        if collectedRent > 0 { outcome.bullets.append("Rental income $\(collectedRent)") }
        let event = selectAssetLossEvent(candidates: lossCandidates, assets: &assets, age: age)
            ?? selectVehicleEvent(candidates: vehicleEventCandidates, assets: &assets)
            ?? selectPropertyEvent(candidates: eventCandidates, assets: &assets)
        assets.normalize()
        return PropertyYearPreparation(
            financialSnapshot: financialSnapshot(assets: assets, world: world),
            outcome: outcome,
            event: event
        )
    }

    static func firearmExposure(assets: AssetState, legal: LegalState) -> FirearmExposureSnapshot {
        let firearms = assets.movableAssets.compactMap { owned -> (OwnedAsset, OwnedFirearmState)? in
            guard let firearm = owned.firearm else { return nil }
            return (owned, firearm)
        }
        let items = firearms.compactMap { owned, firearm -> FirearmExposureItem? in
            let risk = firearm.market == .illicit
                ? firearm.totalHeat + firearm.conditionRisk
                : (legal.isFelon ? 5 + firearm.storageRisk + firearm.conditionRisk : firearm.storageRisk + firearm.conditionRisk)
            return risk > 0 ? FirearmExposureItem(ownershipID: owned.id, risk: risk) : nil
        }
        return FirearmExposureSnapshot(
            lawfulCount: firearms.count { $0.1.market == .legal },
            illicitCount: firearms.count { $0.1.market == .illicit },
            totalRisk: items.reduce(0) { $0 + $1.risk },
            items: items
        )
    }

    static func confiscate(ownershipID: UInt64, assets: inout AssetState, age: Int) -> OwnedAsset? {
        guard let index = assets.movableAssets.firstIndex(where: { $0.id == ownershipID }) else { return nil }
        let removed = assets.movableAssets.remove(at: index)
        assets.movableAssetsLost += 1
        assets.notoriety.adjust(4, age: age)
        assets.lossHistory.append(AssetLossRecord(id: assets.claimLossSequence(), age: age, assetCategory: removed.category, assetName: removed.displayName, value: removed.resaleValue, action: .report, reason: "confiscated"))
        assets.lossHistory = Array(assets.lossHistory.suffix(24))
        assets.normalize()
        return removed
    }

    static func selectableLiquidationAssets(state: LifeState) -> [OwnedAsset] {
        let committed = committedCriminalAssetIDs(state: state)
        return state.assets.movableAssets.filter { !committed.contains($0.id) }.sorted { $0.resaleValue > $1.resaleValue }
    }

    static func committedCriminalAssetIDs(state: LifeState) -> Set<UInt64> {
        guard let path = state.career.criminalPath else { return [] }
        let activeKitIDs = Set(path.plans.compactMap(\.kitID) + [path.soloKitID].compactMap { $0 })
        let ids = path.customKits.filter { activeKitIDs.contains($0.id) }.flatMap { $0.personalAssetIDs }
        return Set(ids)
    }

    static func resolveCriminalKitUse(kitID: String?, assetIDs: [UInt64], succeeded: Bool, risk: Int, state: inout LifeState) -> CriminalAssetUseOutcome? {
        guard !assetIDs.isEmpty else { return nil }
        let affected = assetIDs.filter { id in state.assets.movableAssets.contains { $0.id == id } }
        guard !affected.isEmpty else { return nil }
        var lostID: UInt64?
        for id in affected {
            guard let index = state.assets.movableAssets.firstIndex(where: { $0.id == id }) else { continue }
            if var firearm = state.assets.movableAssets[index].firearm {
                firearm.condition = max(0, firearm.condition - (succeeded ? 1 : 7))
                state.assets.movableAssets[index].firearm = firearm
            }
            if var vehicle = state.assets.movableAssets[index].vehicle {
                vehicle.condition = max(0, vehicle.condition - (succeeded ? 2 : 9))
                state.assets.movableAssets[index].vehicle = vehicle
            }
        }
        if !succeeded, risk >= 78, let id = affected.sorted().first,
           let index = state.assets.movableAssets.firstIndex(where: { $0.id == id }) {
            let lost = state.assets.movableAssets.remove(at: index)
            lostID = lost.id
            state.assets.movableAssetsLost += 1
            state.assets.lossHistory.append(AssetLossRecord(id: state.assets.claimLossSequence(), age: state.character.age, assetCategory: lost.category, assetName: lost.displayName, value: lost.resaleValue, action: .accept, reason: "criminal operation loss"))
            state.assets.lossHistory = Array(state.assets.lossHistory.suffix(24))
        }
        if var path = state.career.criminalPath, let kitID, let kitIndex = path.customKits.firstIndex(where: { $0.id == kitID }) {
            path.customKits[kitIndex].lastUsedAge = state.character.age
            if let lostID { path.customKits[kitIndex].personalAssetIDs.removeAll { $0 == lostID } }
            path.clamp()
            state.career.criminalPath = path
        }
        state.assets.normalize()
        if let lostID {
            let lostName = state.assets.lossHistory.last?.assetName ?? "kit item"
            return CriminalAssetUseOutcome(affectedAssetIDs: affected, lostAssetID: lostID, detail: "A high-risk failure cost the operation's \(lostName).")
        }
        return CriminalAssetUseOutcome(affectedAssetIDs: affected, lostAssetID: nil, detail: succeeded ? "Kit items took light wear." : "The failed operation damaged the kit items.")
    }

    static func giftPreview(ownershipID: UInt64, recipient: AssetGiftRecipient, state: LifeState) -> AssetGiftPreview? {
        guard let owned = state.assets.movableAssets.first(where: { $0.id == ownershipID }),
              let recipientName = recipientDisplayName(recipient, state: state) else { return nil }
        let value = owned.resaleValue
        let magnitude = value > 10_000 ? 3 : (value >= 1_000 ? 2 : 1)
        let relationshipDelta = magnitude * (recipient == .partner ? 4 : 3)
        let reciprocityValue = min(25_000, max(100, value * (value > 10_000 ? 35 : 20) / 100))
        return AssetGiftPreview(assetName: owned.displayName, resaleValue: value, recipientName: recipientName, relationshipDelta: relationshipDelta, reciprocityValue: reciprocityValue)
    }

    static func gift(ownershipID: UInt64, recipient: AssetGiftRecipient, state: inout LifeState) -> AssetGiftOutcome? {
        guard state.finance.economy.workoutYearsRemaining == 0, !state.isGameOver,
              !committedCriminalAssetIDs(state: state).contains(ownershipID),
              recipientExists(recipient, state: state),
              let index = state.assets.movableAssets.firstIndex(where: { $0.id == ownershipID }) else { return nil }
        let owned = state.assets.movableAssets.remove(at: index)
        let value = owned.resaleValue
        let magnitude = value > 10_000 ? 3 : (value >= 1_000 ? 2 : 1)
        let relationshipDelta: Int
        let recipientID: String
        let recipientName: String
        switch recipient {
        case .partner:
            guard let partner = state.partner else { return nil }
            recipientID = "partner"
            recipientName = partner.name
            relationshipDelta = magnitude * 4
        case .family(let contactID):
            guard let contactIndex = state.family.contacts.firstIndex(where: { $0.id == contactID }) else { return nil }
            recipientID = contactID
            recipientName = state.family.contacts[contactIndex].name
            relationshipDelta = magnitude * 3
        case .cast(let memberID):
            guard let member = state.npcs.member(id: memberID) else { return nil }
            recipientID = memberID
            recipientName = member.name
            relationshipDelta = magnitude * 3
        }
        let major = value > 10_000
        let reciprocityValue = min(25_000, max(100, value * (major ? 35 : 20) / 100))
        let transferredFirearm = owned.firearm
        state.assets.movableAssetsGifted += 1
        state.assets.reciprocity.add(reciprocityValue, for: recipientID)
        state.assets.giftHistory.append(AssetGiftRecord(
            id: state.assets.claimGiftSequence(),
            age: state.character.age,
            assetCategory: owned.category,
            assetName: owned.displayName,
            value: value,
            recipientID: recipientID,
            recipientName: recipientName,
            major: major,
            reciprocityValue: reciprocityValue,
            transferredCondition: owned.firearm?.condition ?? owned.vehicle?.condition ?? owned.jewelry?.condition,
            transferredUpgrades: transferredFirearm?.upgrades ?? [],
            transferredSecureStorage: transferredFirearm?.secureStorage,
            transferredMarket: transferredFirearm?.market,
            transferredRarity: transferredFirearm?.rarity,
            transferredLegalHeat: transferredFirearm.map { $0.totalHeat }
        ))
        state.assets.giftHistory = Array(state.assets.giftHistory.suffix(24))
        let notorietyDelta = major ? 1 : 0
        if notorietyDelta > 0 { state.assets.notoriety.adjust(notorietyDelta, age: state.character.age) }
        state.assets.normalize()
        let transaction = AssetTransaction(kind: .management, category: owned.category, listingID: owned.listingID, ownershipID: ownershipID, headline: "You Gave Away \(owned.displayName)", detail: "\(recipientName) received an asset worth about $\(value). Future support value: $\(reciprocityValue).", cashDelta: 0)
        let outcome = AssetGiftOutcome(transaction: transaction, recipient: recipient, recipientID: recipientID, recipientName: recipientName, relationshipDelta: relationshipDelta, reciprocityValue: reciprocityValue, notorietyDelta: notorietyDelta)
        RelationshipSystem.applyGiftOutcome(outcome, state: &state)
        return outcome
    }

    static func consumeReciprocity(
        recipient: AssetGiftRecipient,
        requestedValue: Int,
        eventKey: String,
        state: inout LifeState
    ) -> AssetReciprocityOutcome? {
        let recipientID = recipient.id
        let consumed = state.assets.reciprocity.consume(requestedValue, recipientID: recipientID, eventKey: eventKey)
        guard consumed > 0 else { return nil }
        let cashSupport = min(consumed, max(250, consumed * 70 / 100))
        let stabilitySupport = min(8, max(1, consumed / 1_000))
        state.aggregates.assetReciprocityUsed += 1
        return AssetReciprocityOutcome(recipientID: recipientID, valueConsumed: consumed, cashSupport: cashSupport, stabilitySupport: stabilitySupport)
    }

    private static func recipientExists(_ recipient: AssetGiftRecipient, state: LifeState) -> Bool {
        recipientDisplayName(recipient, state: state) != nil
    }

    private static func recipientDisplayName(_ recipient: AssetGiftRecipient, state: LifeState) -> String? {
        switch recipient {
        case .partner: state.partner?.name
        case .family(let contactID): state.family.contacts.first(where: { $0.id == contactID })?.name
        case .cast(let memberID): state.npcs.member(id: memberID)?.name
        }
    }

    static func applyAssetLossEffect(_ effect: AssetLossEffect, assets: inout AssetState, age: Int) {
        guard let index = assets.movableAssets.firstIndex(where: { $0.id == effect.assetID }) else { return }
        let owned = assets.movableAssets[index]
        let value = owned.resaleValue
        switch effect.action {
        case .recoverPrivately:
            if var firearm = assets.movableAssets[index].firearm { firearm.condition = max(0, firearm.condition - 10); assets.movableAssets[index].firearm = firearm }
            if var vehicle = assets.movableAssets[index].vehicle { vehicle.condition = max(0, vehicle.condition - 10); assets.movableAssets[index].vehicle = vehicle }
            if var jewelry = assets.movableAssets[index].jewelry { jewelry.condition = max(0, jewelry.condition - 10); assets.movableAssets[index].jewelry = jewelry }
            assets.notoriety.adjust(1, age: age)
        case .report:
            assets.movableAssets.remove(at: index)
            assets.movableAssetsLost += 1
            assets.notoriety.adjust(2, age: age)
        case .accept:
            assets.movableAssets.remove(at: index)
            assets.movableAssetsLost += 1
            assets.notoriety.adjust(-1, age: age)
        }
        assets.lossHistory.append(AssetLossRecord(id: assets.claimLossSequence(), age: age, assetCategory: owned.category, assetName: owned.displayName, value: value, action: effect.action, reason: "stolen or missing"))
        assets.lossHistory = Array(assets.lossHistory.suffix(24))
        assets.normalize()
    }

    @discardableResult
    static func resolveAssetLoss(action: AssetLossAction, ownershipID: UInt64, state: inout LifeState) -> AssetTransaction? {
        guard let owned = state.assets.movableAssets.first(where: { $0.id == ownershipID }) else { return nil }
        let value = owned.resaleValue
        let cashDelta: Int
        switch action {
        case .recoverPrivately:
            cashDelta = -(value * 25 / 100)
            guard state.cash >= -cashDelta else { return nil }
        case .report:
            cashDelta = value * 10 / 100
        case .accept:
            cashDelta = 0
        }
        if cashDelta != 0 { _ = FinanceSystem.transact(.init(amount: cashDelta, purpose: .household), state: &state) }
        applyAssetLossEffect(AssetLossEffect(assetID: ownershipID, action: action), assets: &state.assets, age: state.character.age)
        if action == .report {
            let recoveryCase = AssetRecoveryCase(id: state.assets.nextRecoveryCaseID, assetCategory: owned.category, assetName: owned.displayName, estimatedValue: value, openedAge: state.character.age, evidence: min(90, 45 + state.assets.notoriety.score / 3))
            state.assets.nextRecoveryCaseID &+= 1
            state.assets.recoveryCases.append(recoveryCase)
            state.assets.normalize()
        }
        return AssetTransaction(kind: .management, category: owned.category, listingID: owned.listingID, ownershipID: ownershipID, headline: "Asset Loss Resolved", detail: "\(owned.displayName) was handled through the \(action.rawValue) response.", cashDelta: cashDelta)
    }

    static func investigateRecoveryCase(caseID: UInt64, state: inout LifeState) -> AssetRecoveryResult? {
        guard let index = state.assets.recoveryCases.firstIndex(where: { $0.id == caseID }) else { return nil }
        var recoveryCase = state.assets.recoveryCases[index]
        let investigationCost = max(250, recoveryCase.estimatedValue * 10 / 100)
        guard state.cash >= investigationCost else { return nil }
        _ = FinanceSystem.transact(.init(amount: -investigationCost, purpose: .household), state: &state)
        let chance = min(85, max(10, recoveryCase.evidence + state.assets.notoriety.score / 4 - recoveryCase.attempts * 15))
        let roll = state.assets.lossRandom.next(in: 1...100)
        if roll <= chance {
            let recovery = max(1, recoveryCase.estimatedValue * 35 / 100)
            _ = FinanceSystem.transact(.init(amount: recovery, purpose: .household), state: &state)
            state.assets.recoveryCases.remove(at: index)
            state.assets.normalize()
            return .recovered(cash: recovery - investigationCost)
        }
        recoveryCase.attempts += 1
        recoveryCase.evidence -= 20
        if recoveryCase.attempts >= 2 { state.assets.recoveryCases.remove(at: index) }
        else { state.assets.recoveryCases[index] = recoveryCase }
        state.assets.normalize()
        return .cold
    }

    static func finalizeYear(
        assets: inout AssetState,
        receipts: [MortgageReceipt] = [],
        age: Int? = nil
    ) -> AssetYearOutcome {
        var result = AssetYearOutcome()
        var paidPrincipalTotal = 0
        for receipt in receipts {
            guard let index = assets.properties.firstIndex(where: { $0.id == receipt.propertyID }) else { continue }
#if DEBUG
            assert(receipt.principal >= 0 && receipt.principal <= assets.properties[index].mortgageBalance, "Mortgage principal receipt is outside the remaining balance")
#endif
            let principal = min(assets.properties[index].mortgageBalance, max(0, receipt.principal))
            paidPrincipalTotal = EconomyPolicy.checkedAdd(paidPrincipalTotal, principal)
            let unpaidInterest = max(0, receipt.unpaidInterest)
            assets.properties[index].mortgageBalance = EconomyPolicy.checkedAdd(assets.properties[index].mortgageBalance - principal, unpaidInterest)
            assets.properties[index].mortgageMonthsRemaining = max(1, assets.properties[index].mortgageMonthsRemaining - receipt.monthsElapsed)
            assets.properties[index].operatingArrears = receipt.operatingArrears
            let previous = assets.properties[index].delinquentYears
            assets.properties[index].delinquentYears = receipt.missedPayment ? previous + 1 : max(0, previous - 1)
            if previous < 2 && assets.properties[index].delinquentYears >= 2 { result.newlyDelinquent = true }
            if previous >= 2 && assets.properties[index].delinquentYears < 2 { result.bullets.append("Mortgage delinquency resolved: \(assets.properties[index].name)") }
        }
        let foreclosedIDs = assets.properties
            .filter { $0.delinquentYears >= 4 }
            .map(\.id)
        for propertyID in foreclosedIDs {
            guard let index = assets.properties.firstIndex(where: { $0.id == propertyID }) else { continue }
            let lost = assets.properties.remove(at: index)
            result.cashSettlement += lost.saleProceeds
            result.lostPrimary = result.lostPrimary || lost.isPrimaryResidence
            assets.propertyHistory.insert(
                PropertyExitRecord(
                    propertyID: lost.id,
                    name: lost.name,
                    purchaseAge: lost.purchaseAge,
                    exitAge: age ?? lost.purchaseAge,
                    reason: .foreclosed,
                    finalValue: lost.currentValue,
                    finalMortgage: lost.mortgageBalance,
                    cashRecovered: lost.saleProceeds,
                    amenityCount: lost.amenities.count
                ),
                at: 0
            )
            result.foreclosedCount += 1
            result.bullets.append("Foreclosure: \(lost.name)")
            result.notes.append("Foreclosure settled the remaining equity or deficiency in the household ledger.")
            result.consequences.append(DomainConsequence(
                source: .assets, target: .finance, kind: .debt, magnitude: .critical,
                openedAge: age ?? lost.purchaseAge, yearsRemaining: 5,
                headline: "The home was lost to foreclosure",
                detail: "Years of missed payments ended ownership. Sale equity or remaining debt stays in the household ledger."
            ))
        }
        if !assets.properties.isEmpty {
            let paid = paidPrincipalTotal
            result.bullets.append("Property costs across \(assets.properties.count) home\(assets.properties.count == 1 ? "" : "s")")
            if paid > 0 { result.bullets.append("Mortgage principal −$\(paid)") }
        }
        if result.newlyDelinquent {
            result.notes.append("A property mortgage became delinquent.")
            result.consequences.append(DomainConsequence(
                source: .assets, target: .finance, kind: .debt, magnitude: .critical,
                openedAge: age ?? assets.properties.map(\.purchaseAge).max() ?? 14,
                yearsRemaining: 4,
                headline: "Property delinquency follows the household",
                detail: "The home now threatens cash flow, stability, and the equity already committed."
            ))
        }
        assets.normalize()
        return result
    }

    static func applyPropertyEventEffect(_ effect: PropertyEventEffect, assets: inout AssetState, age: Int) {
        guard let index = assets.properties.firstIndex(where: { $0.id == effect.propertyID }) else { return }
        switch effect.action {
        case .offerPaymentPlan:
            assets.properties[index].rental?.tenant?.reliability += 8
        case .formalNotice, .retainDeposit:
            assets.properties[index].rental?.tenant = nil
            assets.properties[index].rental?.vacancyYears = 0
        case .repairNow:
            assets.properties[index].condition += PropertyRepairKind.restoration.conditionGain
            assets.properties[index].lastRepairAge = age
        case .deferRepair:
            assets.properties[index].condition -= 10
            assets.properties[index].rental?.tenant?.reliability -= 5
        case .renewLease:
            assets.properties[index].rental?.tenant?.leaseYearsRemaining = 2
        case .raiseRent:
            assets.properties[index].rental?.strategy = .aggressive
            assets.properties[index].rental?.tenant?.leaseYearsRemaining = 2
            assets.properties[index].lastRentStrategyAge = age
        case .absorbDamage:
            assets.properties[index].condition += PropertyRepairKind.routine.conditionGain
            assets.properties[index].lastRepairAge = age
        case .lowerRent:
            assets.properties[index].rental?.strategy = .stable
            assets.properties[index].lastRentStrategyAge = age
        case .holdRent:
            break
        }
        assets.normalize()
    }

    static func migrateLegacyHousing(_ housing: HousingState, age: Int) -> AssetState {
        guard housing.kind != .renting || housing.homeValue > 0 || housing.mortgageBalance > 0 else { return AssetState() }
        return AssetState(
            movableAssets: [],
            properties: [
                OwnedProperty(
                    id: 1,
                    listingID: "house-existing-home",
                    name: "Existing home",
                    purchaseAge: age,
                    purchasePrice: housing.homeValue,
                    mortgageBalance: housing.mortgageBalance,
                    annualCost: housing.annualCost,
                    delinquentYears: housing.kind == .delinquent ? max(2, housing.delinquentYears) : housing.delinquentYears,
                    isPrimaryResidence: true,
                    propertyType: .house,
                    propertyTier: .standard
                )
            ],
            nextOwnershipSequence: 2
        )
    }

    static func migrateRealEstateState(_ assets: inout AssetState, runSeed: UInt64) {
        assets.realEstateRandom = SeededRandom(seed: derivedRealEstateSeed(from: runSeed))
        assets.nextTenantSequence = 1
        assets.recentPropertyEventIDs = []
        assets.lastRentalIncome = 0
        for index in assets.properties.indices {
            assets.properties[index].marketAdjustment = 0
            assets.properties[index].condition = 90
            assets.properties[index].lastRepairAge = nil
            assets.properties[index].lastRentStrategyAge = nil
            assets.properties[index].rental = nil
            assets.properties[index].use = assets.properties[index].isPrimaryResidence ? .primaryResidence : .vacant
        }
        assets.normalize()
    }

    private static func initialCondition(for tier: PropertyTier) -> Int {
        switch tier {
        case .starter: 82
        case .standard: 85
        case .premium: 88
        case .luxury: 91
        case .trophy: 94
        }
    }

    private static func canCarrySecondaryMortgage(mortgageBalance: Int, annualCost: Int, state: LifeState) -> Bool {
        EconomyCalculator.qualifies(mortgage: mortgageBalance, state: state, world: WorldSystem.modifiers(for: state.world))
    }

    private static func makeTenant(assets: inout AssetState, age: Int) -> RentalTenantProfile {
        let names = ["Avery", "Cameron", "Devin", "Emery", "Jordan", "Kai", "Morgan", "Quinn", "Riley", "Taylor"]
        let households = RentalHouseholdType.allCases
        let id = assets.nextTenantSequence
        assets.nextTenantSequence &+= 1
        return RentalTenantProfile(
            id: id,
            name: names[assets.realEstateRandom.next(in: 0...(names.count - 1))],
            householdType: households[assets.realEstateRandom.next(in: 0...(households.count - 1))],
            reliability: assets.realEstateRandom.next(in: 55...95),
            care: assets.realEstateRandom.next(in: 45...95),
            occupiedSinceAge: age,
            leaseYearsRemaining: assets.realEstateRandom.next(in: 2...4)
        )
    }

    private static func selectPropertyEvent(
        candidates: [(String, UInt64)],
        assets: inout AssetState
    ) -> LifeEvent? {
        var seen = Set<String>()
        let eligible = candidates.filter { candidate in
            seen.insert(candidate.0).inserted && !assets.recentPropertyEventIDs.contains(candidate.0)
        }
        guard !eligible.isEmpty else { return nil }
        let candidate = eligible[assets.realEstateRandom.next(in: 0...(eligible.count - 1))]
        guard let property = assets.properties.first(where: { $0.id == candidate.1 }) else { return nil }
        return propertyEvent(id: candidate.0, property: property)
    }

    private static func selectVehicleEvent(
        candidates: [(String, UInt64)],
        assets: inout AssetState
    ) -> LifeEvent? {
        var seen = Set<String>()
        let eligible = candidates.filter { candidate in
            seen.insert(candidate.0).inserted && !assets.recentVehicleEventIDs.contains(candidate.0)
        }
        guard !eligible.isEmpty else { return nil }
        let candidate = eligible[assets.vehicleRandom.next(in: 0...(eligible.count - 1))]
        guard let owned = assets.movableAssets.first(where: { $0.id == candidate.1 }),
              let vehicle = owned.vehicle else { return nil }
        return vehicleEvent(id: candidate.0, owned: owned, vehicle: vehicle)
    }

    private static func assetLossChance(for owned: OwnedAsset, assets: AssetState) -> Int {
        if let firearm = owned.firearm {
            return min(35, 1 + assets.notoriety.score / 5 + firearm.storageRisk * 2 + (firearm.market == .illicit ? 6 : 0))
        }
        if owned.jewelry != nil { return min(12, 1 + assets.notoriety.score / 20) }
        if owned.vehicle != nil { return min(10, 1 + assets.notoriety.score / 25) }
        return 0
    }

    private static func selectAssetLossEvent(candidates: [UInt64], assets: inout AssetState, age: Int) -> LifeEvent? {
        guard let ownershipID = candidates.first,
              let owned = assets.movableAssets.first(where: { $0.id == ownershipID }) else { return nil }
        let value = owned.resaleValue
        let recoverCost = max(1, value * 25 / 100)
        let reportRecovery = max(0, value * 10 / 100)
        let choice = { (id: EventChoiceID, title: String, detail: String, narrative: String, effects: EffectRange, action: AssetLossAction) in
            EventChoice(
                id: id,
                title: title,
                detail: detail,
                effects: effects,
                partnerEffect: PartnerEffect(),
                narrative: narrative,
                assetLossEffect: AssetLossEffect(assetID: ownershipID, action: action)
            )
        }
        return LifeEvent(
            id: "asset-loss-\(ownershipID)-\(age)",
            headline: "Your \(owned.displayName) Is Missing",
            detail: "An asset disappeared from your life. Decide how much money, attention, and risk you want to spend recovering it.",
            weight: { _ in 0 },
            choices: [
                choice(.assetRecover, "Recover privately", "Pay $\(recoverCost) and keep it, but accept 10 condition damage.", "You recovered the asset privately and paid for the trouble.", EffectRange(cash: -recoverCost ... -recoverCost), .recoverPrivately),
                choice(.assetReport, "Report the loss", "Remove it and recover $\(reportRecovery) as a documented settlement.", "You reported the loss and created a public record of the incident.", EffectRange(cash: reportRecovery ... reportRecovery), .report),
                choice(.assetAccept, "Accept the loss", "Remove it with no cash recovery and avoid more attention.", "You accepted the loss and let the matter go.", EffectRange(), .accept)
            ]
        )
    }

    static func rememberVehicleEvent(_ id: String, assets: inout AssetState) {
        assets.recentVehicleEventIDs.removeAll { $0 == id }
        assets.recentVehicleEventIDs.append(id)
        assets.recentVehicleEventIDs = Array(assets.recentVehicleEventIDs.suffix(6))
    }

    private static func vehicleEvent(id: String, owned: OwnedAsset, vehicle: OwnedVehicleState) -> LifeEvent {
        let breakdownCost = maintenanceCost(.breakdown, vehicle: vehicle)
        let saleValue = owned.resaleValue
        let choice: (EventChoiceID, String, String, String, EffectRange, VehicleEventAction) -> EventChoice = {
            EventChoice(
                id: $0,
                title: $1,
                detail: $2,
                effects: $4,
                partnerEffect: PartnerEffect(),
                narrative: $3,
                vehicleEffect: VehicleEventEffect(vehicleID: owned.id, action: $5)
            )
        }
        if id == "vehicle-total-loss" {
            let settlement = max(1, vehicle.currentValue * 55 / 100)
            return LifeEvent(
                id: id,
                headline: "Your \(owned.displayName) Is Totaled",
                detail: "The vehicle is beyond economical repair. An abstract catastrophic-loss settlement provides $\(settlement); no insurance policy is created.",
                weight: { _ in 0 },
                choices: [
                    choice(.vehicleKeepSettlement, "Keep the settlement", "Take the cash and remain without a replacement vehicle.", "You kept the settlement and adjusted to life without the vehicle.", EffectRange(cash: settlement...settlement), .keepSettlement),
                    choice(.vehicleReplace, "Shop for a replacement", "Take the settlement and review available vehicles in Assets.", "The settlement is available for a replacement purchase in Assets.", EffectRange(cash: settlement...settlement), .replace)
                ]
            )
        }
        return LifeEvent(
            id: id,
            headline: "Your \(owned.displayName) Breaks Down",
            detail: "Condition has fallen far enough that the vehicle now needs a decision.",
            weight: { _ in 0 },
            choices: [
                choice(.vehicleRepair, "Repair it", "Pay $\(breakdownCost) and restore reliability.", "The vehicle is back on the road after an expensive repair.", EffectRange(cash: -breakdownCost ... -breakdownCost), .repair),
                choice(.vehicleDefer, "Defer the repair", "Keep your cash and accept lower reliability.", "You deferred the repair and accepted a less reliable vehicle.", EffectRange(), .deferRepair),
                choice(.vehicleSell, "Sell it", "Take the current resale value of $\(saleValue).", "You sold the unreliable vehicle before the next failure.", EffectRange(cash: saleValue...saleValue), .sell)
            ]
        )
    }

    static func depreciationRate(for kind: VehicleKind, age: Int) -> Int {
        switch kind {
        case .car: age < 5 ? 12 : (age < 10 ? 7 : 4)
        case .boat: age < 5 ? 8 : (age < 10 ? 5 : 3)
        case .helicopter: age < 5 ? 10 : (age < 10 ? 6 : 3)
        case .plane: age < 5 ? 7 : (age < 10 ? 4 : 2)
        }
    }

    static func residualRate(for kind: VehicleKind) -> Int {
        switch kind {
        case .car: 20
        case .boat: 25
        case .helicopter: 30
        case .plane: 35
        }
    }

    static func conditionLoss(for kind: VehicleKind) -> Int {
        switch kind {
        case .car: 5
        case .boat: 4
        case .helicopter: 3
        case .plane: 2
        }
    }

    static func breakdownAge(for kind: VehicleKind) -> Int {
        switch kind {
        case .car: 6
        case .boat: 8
        case .helicopter: 9
        case .plane: 10
        }
    }

    static func breakdownChance(condition: Int, age: Int) -> Int {
        max(8, min(70, (100 - condition) + max(0, age - 5) * 4))
    }

    static func maintenanceCost(_ kind: VehicleMaintenanceKind, vehicle: OwnedVehicleState) -> Int {
        max(kind == .routine ? 300 : 700, vehicle.currentValue * kind.valueRate / 100)
    }

    static func vehicleMaintenanceAvailability(
        _ kind: VehicleMaintenanceKind,
        ownershipID: UInt64,
        state: LifeState
    ) -> Availability {
        guard let owned = state.assets.movableAssets.first(where: { $0.id == ownershipID }),
              let vehicle = owned.vehicle else { return .locked("Requires an owned vehicle") }
        if vehicle.repairState == .totaled { return .locked("This vehicle was totaled") }
        if vehicle.lastMaintenanceAge == state.character.age { return .locked("Already serviced this year") }
        if kind == .breakdown, vehicle.repairState != .needsRepair { return .locked("No breakdown requires repair") }
        if kind == .routine, vehicle.repairState != .healthy {
            return .locked("Breakdown repair is required")
        }
        if kind == .routine, vehicle.condition >= 80 {
            return .locked("Maintenance is not needed yet")
        }
        let cost = maintenanceCost(kind, vehicle: vehicle)
        if state.cash < cost { return .locked("Requires $(cost)") }
        return .available
    }

    static func maintainVehicle(
        ownershipID: UInt64,
        kind: VehicleMaintenanceKind,
        state: inout LifeState
    ) -> AssetTransaction? {
        guard vehicleMaintenanceAvailability(kind, ownershipID: ownershipID, state: state) == .available,
              let index = state.assets.movableAssets.firstIndex(where: { $0.id == ownershipID }),
              var vehicle = state.assets.movableAssets[index].vehicle else { return nil }
        let cost = maintenanceCost(kind, vehicle: vehicle)
        _ = FinanceSystem.transact(.init(amount: -cost, purpose: .optionalPurchase), state: &state)
        vehicle.condition = min(100, vehicle.condition + kind.conditionGain)
        vehicle.lastMaintenanceAge = state.character.age
        vehicle.repairState = .healthy
        state.assets.movableAssets[index].vehicle = vehicle
        state.assets.normalize()
        return AssetTransaction(
            kind: .repair,
            category: .cars,
            listingID: state.assets.movableAssets[index].listingID,
            ownershipID: ownershipID,
            headline: "\(kind.title) Completed",
            detail: "\(state.assets.movableAssets[index].displayName) reached \(vehicle.condition)% condition after a $\(cost) service.",
            cashDelta: -cost
        )
    }

    static func applyVehicleEventEffect(_ effect: VehicleEventEffect, assets: inout AssetState, age: Int) {
        guard let index = assets.movableAssets.firstIndex(where: { $0.id == effect.vehicleID }) else { return }
        switch effect.action {
        case .repair:
            if var vehicle = assets.movableAssets[index].vehicle {
                vehicle.condition = min(100, vehicle.condition + VehicleMaintenanceKind.breakdown.conditionGain)
                vehicle.repairState = .healthy
                vehicle.lastMaintenanceAge = age
                assets.movableAssets[index].vehicle = vehicle
            }
        case .deferRepair:
            if var vehicle = assets.movableAssets[index].vehicle {
                vehicle.condition = max(0, vehicle.condition - 10)
                vehicle.repairState = .needsRepair
                assets.movableAssets[index].vehicle = vehicle
            }
        case .sell:
            assets.movableAssets.remove(at: index)
        case .keepSettlement, .replace:
            let vehicle = assets.movableAssets.remove(at: index)
            let settlement = max(1, (vehicle.vehicle?.currentValue ?? vehicle.purchasePrice) * 55 / 100)
            assets.movableAssetsLost += 1
            assets.lossHistory.append(AssetLossRecord(
                id: assets.claimLossSequence(),
                age: age,
                assetCategory: vehicle.category,
                assetName: vehicle.displayName,
                value: settlement,
                action: .accept,
                reason: "vehicle total loss"
            ))
            assets.lossHistory = Array(assets.lossHistory.suffix(24))
            if effect.action == .replace { assets.vehicleReplacementBudget += settlement }
        }
        assets.normalize()
    }

    static func rememberPropertyEvent(_ id: String, assets: inout AssetState) {
        assets.recentPropertyEventIDs.removeAll { $0 == id }
        assets.recentPropertyEventIDs.append(id)
        assets.recentPropertyEventIDs = Array(assets.recentPropertyEventIDs.suffix(6))
    }

    private static func propertyEvent(id: String, property: OwnedProperty) -> LifeEvent {
        func choice(
            _ id: EventChoiceID,
            _ title: String,
            _ detail: String,
            _ narrative: String,
            effects: EffectRange = EffectRange(),
            action: PropertyEventAction
        ) -> EventChoice {
            EventChoice(
                id: id,
                title: title,
                detail: detail,
                effects: effects,
                partnerEffect: PartnerEffect(),
                narrative: narrative,
                propertyEffect: PropertyEventEffect(propertyID: property.id, action: action)
            )
        }
        let details: (String, String, [EventChoice]) = switch id {
        case "property-missed-rent": (
            "The Rent Arrives Only Half-Paid",
            "The tenant asks for time while your mortgage keeps moving.",
            [
                choice(.talk, "Offer a payment plan", "Keep the lease and build reliability.", "You traded immediate leverage for a more stable arrangement.", effects: EffectRange(rep: 1...1), action: .offerPaymentPlan),
                choice(.decline, "Issue formal notice", "End the tenancy without confrontation.", "The lease ended formally, leaving the property vacant.", effects: EffectRange(rep: -2 ... -2), action: .formalNotice)
            ]
        )
        case "property-urgent-repair": (
            "The Property Cannot Hide The Damage",
            "Condition has fallen below the point where delay feels neutral.",
            [
                choice(.accept, "Restore it now", "Pay for major work and recover condition.", "The expensive work protected the building and its value.", effects: EffectRange(cash: -repairCost(.restoration, property: property)...(-repairCost(.restoration, property: property))), action: .repairNow),
                choice(.decline, "Defer the repair", "Preserve cash and accept deeper damage.", "The problem remained and the tenant noticed.", effects: EffectRange(rep: -2 ... -2), action: .deferRepair)
            ]
        )
        case "property-lease-renewal": (
            "The Lease Reaches Its Decision Point",
            "Another term can preserve stability or become a chance to push rent.",
            [
                choice(.accept, "Renew the lease", "Keep the current arrangement for two years.", "The familiar tenant stayed under familiar terms.", effects: EffectRange(rep: 1...1), action: .renewLease),
                choice(.negotiate, "Raise the rent", "Move to aggressive pricing for the next term.", "You chose yield over certainty.", effects: EffectRange(rep: -2 ... -1), action: .raiseRent)
            ]
        )
        case "property-tenant-damage": (
            "Tenant Damage Reaches The Walkthrough",
            "Wear has crossed into a dispute over who should pay.",
            [
                choice(.accept, "Absorb the repair", "Pay for routine work and keep the lease stable.", "You covered the repair and protected the relationship.", effects: EffectRange(cash: -repairCost(.routine, property: property)...(-repairCost(.routine, property: property)), rep: 1...1), action: .absorbDamage),
                choice(.decline, "Retain the deposit", "Apply the held deposit to actual repairs and pay any remainder.", "You kept the deposit and the property returned to vacancy.", effects: EffectRange(cash: -max(0, repairCost(.routine, property: property) - (property.rental?.restrictedDeposit ?? 0))...(-max(0, repairCost(.routine, property: property) - (property.rental?.restrictedDeposit ?? 0))), rep: -3 ... -3), action: .retainDeposit)
            ]
        )
        default: (
            "The Rental Sits Empty Again",
            "Another vacant year is turning theoretical rent into real carrying cost.",
            [
                choice(.negotiate, "Lower the rent", "Switch to stable pricing and improve the tenant search.", "You accepted less rent in exchange for a stronger chance of occupancy.", action: .lowerRent),
                choice(.focus, "Hold the price", "Keep the current strategy and tolerate vacancy.", "You held your line and carried the empty property another year.", action: .holdRent)
            ]
        )
        }
        return LifeEvent(id: id, headline: details.0, detail: details.1, weight: { _ in 0 }, choices: details.2)
    }

    private static func derivedRealEstateSeed(from runSeed: UInt64) -> UInt64 {
        var value = runSeed ^ realEstateSeedSalt
        value &+= 0x9E37_79B9_7F4A_7C15
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    private static func derivedVehicleSeed(from runSeed: UInt64) -> UInt64 {
        var value = runSeed ^ vehicleSeedSalt
        value &+= 0x9E37_79B9_7F4A_7C15
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    private static func derivedJewelrySeed(from runSeed: UInt64) -> UInt64 {
        var value = runSeed ^ 0x4A45_5745_4C52_5953
        value &+= 0x9E37_79B9_7F4A_7C15
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    private static func derivedLossSeed(from runSeed: UInt64) -> UInt64 {
        var value = runSeed ^ lossSeedSalt
        value &+= 0x9E37_79B9_7F4A_7C15
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    private static func purchaseDetail(for listing: AssetListing) -> String {
        if let firearm = listing.firearm {
            if firearm.market == .illicit {
                return "You paid $\(listing.terms.committedCash) through the illegal market. Ownership added \(firearm.heat) heat."
            }
            return "You paid $\(listing.terms.committedCash) through the legal market. Secure storage remains required."
        }
        return switch listing.terms {
        case .cash(let price): "You paid $\(price). Selling it now would return only $\(price * 65 / 100)."
        case .mortgage(let value, let down, let annual, _): "You put down $\(down) on a $\(value) property. Annual mortgage payments are $\(EconomyPolicy.monthlyMortgage(value - down) * 12), plus $\(annual) operating costs."
        }
    }

    private static func acquisitionRoll(runSeed: UInt64, key: String, age: Int) -> Int {
        var value = runSeed ^ UInt64(bitPattern: Int64(age)) ^ 0x4153_5345_545F_4D4B
        for byte in key.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        value ^= value >> 32
        return Int(value % 100) + 1
    }

    private static func career(_ actual: CareerLevel, meets required: CareerLevel) -> Bool {
        func rank(_ value: CareerLevel) -> Int {
            switch value {
            case .entry: 1
            case .established: 2
            case .senior: 3
            case .unemployed, .retired: 0
            }
        }
        return rank(actual) >= rank(required)
    }
}
