import Foundation

// MARK: - Assets1 Volume + Collector Identity

struct JewelryListing: Equatable {
    let name: String
    let type: JewelryType
    let cost: Int
    let resale: Int
    let rarity: FirearmRarity

    func makeItem() -> Jewelry {
        Jewelry(name: name, type: type, rarity: rarity, cost: cost, resaleValue: resale)
    }
}

struct FirearmListing: Equatable {
    let name: String
    let type: FirearmType
    let cost: Int
    let isLegal: Bool
    let power: Int
    let reliability: Int
    let rarity: FirearmRarity

    func makeItem() -> Firearm {
        Firearm(name: name, type: type, isLegal: isLegal, basePower: power, reliability: reliability, rarity: rarity)
    }
}

enum AssetCollectorSet: String, CaseIterable, Codable {
    case horologist
    case iceCollector
    case armoryCurator
    case garageRoyalty
    case fleetCommander

    var title: String {
        switch self {
        case .horologist: return "Horologist"
        case .iceCollector: return "Ice Collector"
        case .armoryCurator: return "Armory Curator"
        case .garageRoyalty: return "Garage Royalty"
        case .fleetCommander: return "Fleet Commander"
        }
    }

    var subtitle: String {
        switch self {
        case .horologist: return "3+ watches in rotation"
        case .iceCollector: return "2+ exotic or prototype pieces"
        case .armoryCurator: return "3+ firearms secured"
        case .garageRoyalty: return "3+ vehicles, one performance tier"
        case .fleetCommander: return "Aviation + marine holdings"
        }
    }

    var lifestyleBonus: Int { 3 }
}

struct AssetShowpiece: Equatable {
    enum Category: String, Equatable {
        case jewelry
        case firearm
        case vehicle
        case aviation
        case marine
        case signature
        case residence
    }

    let name: String
    let category: Category
    let prestigeWeight: Int
}

struct CollectionIdentity: Equatable {
    let label: String
    let subtitle: String
    let lifestyleScore: Int
    let completedSets: [AssetCollectorSet]
    let showpiece: AssetShowpiece?
}

enum AssetCatalog {

    static let jewelryMarket: [JewelryListing] = [
        JewelryListing(name: "Steel Watch", type: .watch, cost: 2_500, resale: 1_800, rarity: .common),
        JewelryListing(name: "Timex Weekender", type: .watch, cost: 180, resale: 120, rarity: .common),
        JewelryListing(name: "Gold Chain", type: .chain, cost: 5_500, resale: 4_800, rarity: .rare),
        JewelryListing(name: "Cuban Link", type: .chain, cost: 12_000, resale: 9_500, rarity: .rare),
        JewelryListing(name: "Diamond Studs", type: .earrings, cost: 12_000, resale: 9_000, rarity: .exotic),
        JewelryListing(name: "VVS Choker", type: .chain, cost: 28_000, resale: 22_000, rarity: .exotic),
        JewelryListing(name: "Tennis Bracelet", type: .bracelet, cost: 18_000, resale: 14_000, rarity: .rare),
        JewelryListing(name: "Cross Pendant", type: .pendant, cost: 3_200, resale: 2_400, rarity: .common),
        JewelryListing(name: "Bust-down AP", type: .watch, cost: 65_000, resale: 45_000, rarity: .exotic),
        JewelryListing(name: "Patek Nautilus", type: .watch, cost: 95_000, resale: 88_000, rarity: .exotic),
        JewelryListing(name: "Richard Mille RM", type: .watch, cost: 280_000, resale: 240_000, rarity: .prototype),
        JewelryListing(name: "Royal Crown Jewel", type: .pendant, cost: 150_000, resale: 120_000, rarity: .prototype),
    ]

    static let legalFirearms: [FirearmListing] = [
        FirearmListing(name: "9mm Handgun", type: .handgun, cost: 600, isLegal: true, power: 15, reliability: 90, rarity: .common),
        FirearmListing(name: "Pump Shotgun", type: .shotgun, cost: 1_200, isLegal: true, power: 25, reliability: 85, rarity: .common),
        FirearmListing(name: "Precision Bolt-Action", type: .precisionRifle, cost: 3_500, isLegal: true, power: 40, reliability: 95, rarity: .common),
        FirearmListing(name: "Tactical Rifle", type: .rifle, cost: 2_800, isLegal: true, power: 35, reliability: 88, rarity: .rare),
        FirearmListing(name: "Gold-Plated Deagle", type: .handgun, cost: 15_000, isLegal: true, power: 45, reliability: 70, rarity: .exotic),
        FirearmListing(name: "Antique Duelling Pistol", type: .handgun, cost: 12_000, isLegal: true, power: 10, reliability: 30, rarity: .rare),
    ]

    static let blackMarketFirearms: [FirearmListing] = [
        FirearmListing(name: "G-Series Handgun", type: .handgun, cost: 850, isLegal: false, power: 18, reliability: 85, rarity: .common),
        FirearmListing(name: "Modified SMG", type: .handgun, cost: 2_500, isLegal: false, power: 35, reliability: 65, rarity: .rare),
        FirearmListing(name: "Sawn-off Shotgun", type: .shotgun, cost: 1_800, isLegal: false, power: 30, reliability: 60, rarity: .rare),
        FirearmListing(name: "Tactical Carbine", type: .rifle, cost: 6_500, isLegal: false, power: 55, reliability: 80, rarity: .exotic),
        FirearmListing(name: "Street Sweeper", type: .shotgun, cost: 4_200, isLegal: false, power: 42, reliability: 55, rarity: .exotic),
    ]

    static let exoticFirearms: [FirearmListing] = [
        FirearmListing(name: "Experimental Railgun", type: .precisionRifle, cost: 85_000, isLegal: false, power: 120, reliability: 40, rarity: .prototype),
        FirearmListing(name: "Custom Engraved Revolver", type: .handgun, cost: 22_000, isLegal: true, power: 28, reliability: 75, rarity: .exotic),
    ]

    static func completedCollectorSets(in assets: AssetState) -> [AssetCollectorSet] {
        AssetCollectorSet.allCases.filter { isComplete($0, in: assets) }
    }

    static func collectionBonus(in assets: AssetState) -> Int {
        completedCollectorSets(in: assets).reduce(0) { $0 + $1.lifestyleBonus }
    }

    static func isComplete(_ set: AssetCollectorSet, in assets: AssetState) -> Bool {
        switch set {
        case .horologist:
            return assets.jewelry.filter { $0.type == .watch }.count >= 3
        case .iceCollector:
            return assets.jewelry.filter { $0.rarity == .exotic || $0.rarity == .prototype }.count >= 2
        case .armoryCurator:
            return assets.firearms.count >= 3
        case .garageRoyalty:
            let performanceCount = assets.vehicles.filter {
                $0.type == .sportsCar || $0.type == .supercar || $0.type == .hypercar
            }.count
            return assets.vehicles.count >= 3 && performanceCount >= 1
        case .fleetCommander:
            return !assets.aviation.isEmpty && !assets.marine.isEmpty
        }
    }

    static func collectionIdentity(from assets: AssetState) -> CollectionIdentity? {
        let inventoryCount = assets.jewelry.count
            + assets.firearms.count
            + assets.vehicles.count
            + assets.aviation.count
            + assets.marine.count
            + assets.signatureAssets.count
        guard assets.effectiveLifestyleScore >= 35 || inventoryCount >= 3 else { return nil }

        let sets = completedCollectorSets(in: assets)
        let showpiece = premierShowpiece(from: assets)

        let label: String
        if let primary = sets.first {
            label = primary.title
        } else if assets.jewelry.count >= 2 {
            label = "Jewelry Collector"
        } else if assets.firearms.count >= 2 {
            label = "Armory Owner"
        } else if assets.vehicles.count >= 2 {
            label = "Car Enthusiast"
        } else if !assets.signatureAssets.isEmpty {
            label = "Signature Holder"
        } else {
            label = "Lifestyle Builder"
        }

        let subtitle: String
        if let showpiece {
            subtitle = showpiece.name
        } else if !sets.isEmpty {
            subtitle = sets.map(\.title).joined(separator: " · ")
        } else {
            subtitle = "\(inventoryCount) pieces · Lifestyle \(assets.effectiveLifestyleScore)"
        }

        return CollectionIdentity(
            label: label,
            subtitle: subtitle,
            lifestyleScore: assets.effectiveLifestyleScore,
            completedSets: sets,
            showpiece: showpiece
        )
    }

    static func premierShowpiece(from assets: AssetState) -> AssetShowpiece? {
        var candidates: [AssetShowpiece] = []

        for item in assets.signatureAssets {
            candidates.append(AssetShowpiece(name: item.name, category: .signature, prestigeWeight: item.prestigeBonus * 1_000 + item.cost / 100))
        }
        for item in assets.marine {
            let weight = item.type == .superYacht ? 900 : (item.type == .yacht ? 650 : 200)
            candidates.append(AssetShowpiece(name: item.name, category: .marine, prestigeWeight: weight + item.cost / 50_000))
        }
        for item in assets.aviation {
            let weight = item.type == .heavyJet ? 850 : (item.type == .privateJet ? 700 : 350)
            candidates.append(AssetShowpiece(name: item.name, category: .aviation, prestigeWeight: weight + item.cost / 100_000))
        }
        for item in assets.jewelry {
            let rarityWeight: Int = {
                switch item.rarity {
                case .prototype: return 500
                case .exotic: return 350
                case .rare: return 180
                default: return 80
                }
            }()
            candidates.append(AssetShowpiece(name: item.name, category: .jewelry, prestigeWeight: rarityWeight + item.cost / 1_000))
        }
        for item in assets.vehicles {
            let typeWeight: Int = {
                switch item.type {
                case .hypercar: return 420
                case .supercar: return 320
                case .sportsCar: return 220
                default: return 100
                }
            }()
            candidates.append(AssetShowpiece(name: item.name, category: .vehicle, prestigeWeight: typeWeight))
        }
        for item in assets.firearms {
            let rarityWeight: Int = {
                switch item.rarity {
                case .prototype: return 280
                case .exotic: return 200
                case .rare: return 120
                default: return 60
                }
            }()
            candidates.append(AssetShowpiece(name: item.name, category: .firearm, prestigeWeight: rarityWeight + item.totalPower))
        }
        if let home = assets.primaryResidence, home.totalValue >= 500_000 {
            candidates.append(AssetShowpiece(name: "Primary Residence", category: .residence, prestigeWeight: home.totalValue / 10_000))
        }

        return candidates.max(by: { $0.prestigeWeight < $1.prestigeWeight })
    }

    static func flexNarrative(for showpiece: AssetShowpiece, toneDeaf: Bool) -> (title: String, text: String) {
        if toneDeaf {
            return (
                "Tone-Deaf Flex",
                "You made sure everyone saw the \(showpiece.name). Some people were impressed. More people were annoyed."
            )
        }

        let text: String
        switch showpiece.category {
        case .jewelry:
            text = "The \(showpiece.name) caught the light at the right moment. People stopped pretending they didn't notice."
        case .firearm:
            text = "The \(showpiece.name) did the talking before you did. Respect and distance in equal measure."
        case .vehicle:
            text = "You pulled up in the \(showpiece.name). The engine note said what your bank account couldn't."
        case .aviation:
            text = "The \(showpiece.name) on the tarmac changed the room before you landed."
        case .marine:
            text = "Dockside whispers followed the \(showpiece.name). The harbor knows money when it arrives."
        case .signature:
            text = "The \(showpiece.name) isn't just property — it's proof of who you became."
        case .residence:
            text = "You hosted from the \(showpiece.name). The address did half the networking for you."
        }
        return ("Showpiece Flex", text)
    }

    static func flexPreviewLine(for assets: AssetState) -> String? {
        guard let showpiece = premierShowpiece(from: assets) else {
            return "Build a collection worth showing off first."
        }
        return "Spotlight: \(showpiece.name)"
    }
}
