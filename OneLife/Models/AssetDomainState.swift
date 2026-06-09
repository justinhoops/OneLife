import Foundation

// MARK: - Asset Domain

enum PrimaryResidenceStatus: String, Codable, CaseIterable {
    case current
    case delinquent
    case foreclosed
}

enum HouseUpgrade: String, Codable, CaseIterable {
    case pool
    case bioLandscape
    case sauna
    case gym
    case basketballCourt
    case tennisCourt
    case hotTub

    var cost: Int {
        switch self {
        case .pool: return 45000
        case .bioLandscape: return 12000
        case .sauna: return 8000
        case .gym: return 15000
        case .basketballCourt: return 25000
        case .tennisCourt: return 35000
        case .hotTub: return 10000
        }
    }

    var valueBoost: Int {
        switch self {
        case .pool: return 30000
        case .bioLandscape: return 15000
        case .sauna: return 5000
        case .gym: return 10000
        case .basketballCourt: return 15000
        case .tennisCourt: return 20000
        case .hotTub: return 6000
        }
    }

    var maintenanceCost: Int {
        switch self {
        case .pool: return 200
        case .bioLandscape: return 50
        case .sauna: return 30
        case .gym: return 40
        case .basketballCourt: return 20
        case .tennisCourt: return 40
        case .hotTub: return 80
        }
    }
}

struct PrimaryResidenceState: Codable, Equatable {
    var homeValue: Int
    var mortgagePrincipal: Int
    var monthlyMortgageCost: Int
    var mortgageRatePercent: Int
    var remainingMortgageYears: Int
    var equity: Int
    var downPaymentPaid: Int
    var maintenanceReserve: Int
    var status: PrimaryResidenceStatus = .current
    var yearsOwned: Int = 0
    var upgrades: [HouseUpgrade] = []

    var totalValue: Int {
        homeValue + upgrades.reduce(0) { $0 + $1.valueBoost }
    }

    var totalMonthlyMaintenance: Int {
        upgrades.reduce(0) { $0 + $1.maintenanceCost }
    }

    mutating func normalize() {
        homeValue = max(0, homeValue)
        mortgagePrincipal = max(0, mortgagePrincipal)
        monthlyMortgageCost = max(0, monthlyMortgageCost)
        mortgageRatePercent = mortgageRatePercent.clamped(to: 2...12)
        remainingMortgageYears = max(0, remainingMortgageYears)
        maintenanceReserve = max(0, maintenanceReserve)
        downPaymentPaid = max(0, downPaymentPaid)
        equity = max(0, homeValue - mortgagePrincipal)
        if mortgagePrincipal == 0 {
            monthlyMortgageCost = 0
            remainingMortgageYears = 0
            status = .current
        }
    }

    static func legacyStarterHome() -> PrimaryResidenceState {
        var home = PrimaryResidenceState(
            homeValue: 180_000,
            mortgagePrincipal: 125_000,
            monthlyMortgageCost: 980,
            mortgageRatePercent: 6,
            remainingMortgageYears: 28,
            equity: 55_000,
            downPaymentPaid: 32_000,
            maintenanceReserve: 2_000
        )
        home.normalize()
        return home
    }
}

enum FirearmType: String, Codable, CaseIterable {
    case handgun
    case shotgun
    case rifle
    case precisionRifle
}

enum WeaponUpgrade: String, Codable, CaseIterable {
    case optic
    case extendedMag
    case highCapacityDrum
    case suppressor
    case carbonFiberSuppressor
    case tacticalLight
    case matchTrigger
    case stippledGrip
    case rapidFireSwitch

    var cost: Int {
        switch self {
        case .optic: return 400
        case .extendedMag: return 150
        case .highCapacityDrum: return 450
        case .suppressor: return 800
        case .carbonFiberSuppressor: return 2200
        case .tacticalLight: return 100
        case .matchTrigger: return 300
        case .stippledGrip: return 200
        case .rapidFireSwitch: return 1500
        }
    }

    var powerBonus: Int {
        switch self {
        case .matchTrigger: return 5
        case .optic: return 2
        case .highCapacityDrum: return 12
        case .carbonFiberSuppressor: return 3
        case .rapidFireSwitch: return 25
        default: return 0
        }
    }

    var reliabilityBonus: Int {
        switch self {
        case .tacticalLight: return 5
        case .optic: return 3
        case .stippledGrip: return 8
        case .highCapacityDrum: return -5
        case .carbonFiberSuppressor: return 2
        case .rapidFireSwitch: return -15
        default: return 0
        }
    }

    var isIllicit: Bool {
        switch self {
        case .rapidFireSwitch, .highCapacityDrum, .suppressor, .carbonFiberSuppressor: return true
        default: return false
        }
    }
}

enum FirearmRarity: String, Codable, CaseIterable {
    case common
    case rare
    case exotic
    case prototype
}

struct Firearm: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: FirearmType
    var isLegal: Bool
    var basePower: Int
    var reliability: Int
    var rarity: FirearmRarity = .common
    var upgrades: [WeaponUpgrade] = []

    var totalPower: Int {
        basePower + upgrades.reduce(0) { $0 + $1.powerBonus }
    }

    var totalReliability: Int {
        reliability + upgrades.reduce(0) { $0 + $1.reliabilityBonus }
    }
    
    var isCurrentlyIllicit: Bool {
        !isLegal || upgrades.contains { $0.isIllicit }
    }
}

enum VehicleType: String, Codable, CaseIterable {
    case compact
    case sedan
    case truck
    case sportsCar
    case supercar
    case hypercar
}

enum AviationType: String, Codable, CaseIterable {
    case lightAircraft
    case privateJet
    case helicopter
    case heavyJet
}

struct AviationAsset: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: AviationType
    var cost: Int
    var resaleValue: Int
    var monthlyMaintenance: Int
}

enum MarineType: String, Codable, CaseIterable {
    case jetSki
    case speedboat
    case yacht
    case superYacht
}

struct MarineAsset: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: MarineType
    var cost: Int
    var resaleValue: Int
    var monthlyMaintenance: Int
}

// MARK: - Assets2: Signature Assets (Special Career Identity)

/// High-status, path-unique assets that reinforce a special career's identity and provide unique prestige/mechanical payoffs.
enum SignatureAssetCategory: String, Codable, CaseIterable {
    case athleteTeamStake      // Ownership or equity in a sports team/franchise
    case athleteTrainingEmpire // Personal training facilities, performance centers
    case founderStrategicStake // Equity in other companies / venture holdings
    case founderCompound       // Large private estate used for business + lifestyle
    case creatorStudio         // Production studio or content company
    case creatorBrandEstate    // Properties tied to personal brand (content houses, etc.)
    case politicsInfluenceHold // "Foundations", large donor properties, or strategic real estate
    case politicsLegacyEstate  // Grand estates used for political entertaining and legacy
    // CE3: Criminal/gray enterprise signature holdings — high prestige + real social/legal risk
    case crimeSafehouse        // Quiet, high-security properties for staying low or moving product
    case crimeOffshoreHoldings // Shell companies, foreign accounts, "investment" properties that are hard to trace
    case crimeFrontBusiness    // Legitimate-looking businesses that are actually cash flow / laundering vehicles
    case crimeLuxuryFront      // Flashy but dangerous (yachts under LLCs, penthouses bought through proxies)
}

struct SignatureAsset: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var category: SignatureAssetCategory
    var cost: Int
    var resaleValue: Int
    var monthlyMaintenance: Int
    var prestigeBonus: Int          // Extra boost to effective LifestyleScore / Fame when owned
    var associatedTrack: SpecialCareerTrack // Which special career this asset "belongs" to
}

enum VehicleUpgrade: String, Codable, CaseIterable {
    case supercharger
    case nos
    case racingSuspension
    case driftKit
    case rollCage
    case performanceTires
    case weightReduction

    var cost: Int {
        switch self {
        case .supercharger: return 4500
        case .nos: return 1200
        case .racingSuspension: return 2000
        case .driftKit: return 1500
        case .rollCage: return 800
        case .performanceTires: return 1000
        case .weightReduction: return 3000
        }
    }

    var speedBonus: Int {
        switch self {
        case .supercharger: return 20
        case .nos: return 15
        case .weightReduction: return 10
        case .performanceTires: return 5
        default: return 0
        }
    }

    var handlingBonus: Int {
        switch self {
        case .racingSuspension: return 15
        case .driftKit: return 12
        case .performanceTires: return 8
        case .rollCage: return 5
        default: return 0
        }
    }

    var safetyBonus: Int {
        switch self {
        case .rollCage: return 25
        default: return 0
        }
    }
}

struct Vehicle: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: VehicleType
    var isLegal: Bool
    var baseSpeed: Int
    var baseHandling: Int
    var upgrades: [VehicleUpgrade] = []

    var totalSpeed: Int {
        baseSpeed + upgrades.reduce(0) { $0 + $1.speedBonus }
    }

    var totalHandling: Int {
        baseHandling + upgrades.reduce(0) { $0 + $1.handlingBonus }
    }

    var totalSafety: Int {
        upgrades.reduce(0) { $0 + $1.safetyBonus }
    }
}

enum JewelryType: String, Codable, CaseIterable {
    case watch
    case chain
    case pendant
    case earrings
    case bracelet
}

struct Jewelry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: JewelryType
    var rarity: FirearmRarity = .common
    var cost: Int
    var resaleValue: Int
}

struct AssetState: Codable, Equatable {
    var homeownershipTrackActive: Bool = false
    var targetHomeValue: Int = 0
    var primaryResidence: PrimaryResidenceState? = nil
    var firearms: [Firearm] = []
    var vehicles: [Vehicle] = []
    var jewelry: [Jewelry] = []
    var aviation: [AviationAsset] = []
    var marine: [MarineAsset] = []

    // Assets2: Career-specific Signature Assets (high-status, path-unique holdings)
    var signatureAssets: [SignatureAsset] = []

    private enum CodingKeys: String, CodingKey {
        case homeownershipTrackActive
        case targetHomeValue
        case primaryResidence
        case firearms
        case vehicles
        case jewelry
        case aviation
        case marine
        case ownsHome // for legacy decoding
        case signatureAssets
    }

    init() {}

    init(homeownershipTrackActive: Bool = false, targetHomeValue: Int = 0, primaryResidence: PrimaryResidenceState? = nil) {
        self.homeownershipTrackActive = homeownershipTrackActive
        self.targetHomeValue = targetHomeValue
        self.primaryResidence = primaryResidence
        self.firearms = []
        self.vehicles = []
        self.jewelry = []
        self.aviation = []
        self.marine = []
        normalize()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        homeownershipTrackActive = try container.decodeIfPresent(Bool.self, forKey: .homeownershipTrackActive) ?? false
        targetHomeValue = try container.decodeIfPresent(Int.self, forKey: .targetHomeValue) ?? 0
        primaryResidence = try container.decodeIfPresent(PrimaryResidenceState.self, forKey: .primaryResidence)
        firearms = try container.decodeIfPresent([Firearm].self, forKey: .firearms) ?? []
        vehicles = try container.decodeIfPresent([Vehicle].self, forKey: .vehicles) ?? []
        jewelry = try container.decodeIfPresent([Jewelry].self, forKey: .jewelry) ?? []
        aviation = try container.decodeIfPresent([AviationAsset].self, forKey: .aviation) ?? []
        marine = try container.decodeIfPresent([MarineAsset].self, forKey: .marine) ?? []
        signatureAssets = try container.decodeIfPresent([SignatureAsset].self, forKey: .signatureAssets) ?? []

        let legacyOwnsHome = try container.decodeIfPresent(Bool.self, forKey: .ownsHome) ?? false
        if primaryResidence == nil, legacyOwnsHome {
            primaryResidence = .legacyStarterHome()
            homeownershipTrackActive = true
            targetHomeValue = max(targetHomeValue, primaryResidence?.homeValue ?? 180_000)
        }
        normalize()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(homeownershipTrackActive, forKey: .homeownershipTrackActive)
        try container.encode(targetHomeValue, forKey: .targetHomeValue)
        try container.encodeIfPresent(primaryResidence, forKey: .primaryResidence)
        try container.encode(firearms, forKey: .firearms)
        try container.encode(vehicles, forKey: .vehicles)
        try container.encode(jewelry, forKey: .jewelry)
        try container.encode(aviation, forKey: .aviation)
        try container.encode(marine, forKey: .marine)
        try container.encode(signatureAssets, forKey: .signatureAssets)
    }

    var ownsHome: Bool {
        get { primaryResidence?.status != .foreclosed && primaryResidence != nil }
        set {
            if newValue {
                homeownershipTrackActive = true
                if targetHomeValue == 0 {
                    targetHomeValue = 180_000
                }
                if primaryResidence == nil {
                    primaryResidence = .legacyStarterHome()
                }
            } else {
                primaryResidence = nil
            }
            normalize()
        }
    }

    var isSavingForHome: Bool {
        homeownershipTrackActive && !ownsHome
    }

    /// Aggressive QoL: Visible Lifestyle / Status score from assets.
    /// High asset ownership gives tangible prestige and can influence social/finance events.
    var lifestyleScore: Int {
        var score = 0
        
        // Housing prestige
        if let home = primaryResidence {
            score += home.totalValue / 20_000
            score += home.upgrades.count * 8
        }
        
        // Vehicles
        score += vehicles.count * 5
        score += vehicles.filter { $0.upgrades.count > 0 }.count * 3
        
        // Luxury
        score += jewelry.count * 4
        score += aviation.count * 15
        score += marine.count * 12
        score += firearms.count * 2

        // Assets2: Signature Assets give strong, career-specific prestige
        for sig in signatureAssets {
            score += sig.prestigeBonus
        }
        
        return max(0, min(100, score))
    }

    mutating func normalize() {
        targetHomeValue = max(0, targetHomeValue)
        primaryResidence?.normalize()
        if primaryResidence == nil && targetHomeValue == 0 {
            homeownershipTrackActive = false
        }
    }
}

