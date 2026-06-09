import Foundation

// MARK: - Progress Domain

enum MilestoneID: String, Codable, CaseIterable, Identifiable {
    case graduate
    case firstJob
    case homeowner
    case married
    case millionaire
    case longLived
    case raisedGoodKids   // Phase 2.3: Family legacy milestone
    case culturalIcon
    case infamous
    case householdName

    var id: String { rawValue }
}

struct MilestoneUnlock: Codable, Identifiable, Equatable {
    var id: MilestoneID
    var unlockedAtAge: Int
}

enum LifePathID: String, Codable, CaseIterable, Identifiable {
    case scholar
    case striver
    case provider
    case connector
    case survivor

    var id: String { rawValue }
}

struct LifePathProfile: Equatable {
    var title: String
    var summary: String
    var symbol: String
}

enum LifePathCatalog {
    static func profile(for id: LifePathID) -> LifePathProfile {
        switch id {
        case .scholar:
            return LifePathProfile(
                title: "Scholar",
                summary: "Your life is being defined by study, credentials, and disciplined upward movement.",
                symbol: "book.closed.fill"
            )
        case .striver:
            return LifePathProfile(
                title: "Striver",
                summary: "You are pushing for traction through work, consistency, and earned advancement.",
                symbol: "briefcase.fill"
            )
        case .provider:
            return LifePathProfile(
                title: "Provider",
                summary: "Stability, money discipline, and practical security are shaping your choices.",
                symbol: "dollarsign.circle.fill"
            )
        case .connector:
            return LifePathProfile(
                title: "Connector",
                summary: "Relationships are the strongest force in your life, for warmth and for consequence.",
                symbol: "person.2.fill"
            )
        case .survivor:
            return LifePathProfile(
                title: "Survivor",
                summary: "This life is being defined by pressure, endurance, and staying upright through strain.",
                symbol: "cross.case.fill"
            )
        }
    }
}

struct LifePathUnlock: Codable, Identifiable, Equatable {
    var id: LifePathID
    var unlockedAtAge: Int
}

struct ProgressState: Codable, Equatable {
    var unlockedMilestones: [MilestoneUnlock] = []
    var unlockedLifePaths: [LifePathUnlock] = []
    var currentLifePath: LifePathID? = nil
    var finalLifePath: LifePathID? = nil
    var legacyScore: Int = 0

    init() {}

    private enum CodingKeys: String, CodingKey {
        case unlockedMilestones
        case unlockedLifePaths
        case currentLifePath
        case finalLifePath
        case legacyScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        unlockedMilestones = try container.decodeIfPresent([MilestoneUnlock].self, forKey: .unlockedMilestones) ?? []
        unlockedLifePaths = try container.decodeIfPresent([LifePathUnlock].self, forKey: .unlockedLifePaths) ?? []
        currentLifePath = try container.decodeIfPresent(LifePathID.self, forKey: .currentLifePath)
        finalLifePath = try container.decodeIfPresent(LifePathID.self, forKey: .finalLifePath)
        legacyScore = try container.decodeIfPresent(Int.self, forKey: .legacyScore) ?? 0
    }
}

