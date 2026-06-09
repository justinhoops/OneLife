import Foundation

// MARK: - Lifecycle & Domain Tag Enums

enum CharacterCreationStep: Int, CaseIterable, Codable {
    case name       = 0
    case origin     = 1
    case trait      = 2
    case resilience = 3   // "Life Feel" choice — key for replayability tuning
}
enum StartupState: String, Codable, Equatable {
    case choosingOrigin
    case active
    case inheritingLegacy
}
enum StartMode: String, Codable, CaseIterable, Identifiable {
    case quickStart
    case template
    case custom

    var id: String { rawValue }
}
enum OriginTemplateID: String, Codable, CaseIterable, Identifiable {
    case stableHomeAverageMeans
    case financialStrainToughenedEarly
    case academicPromise
    case socialMagnet
    case fragileHealthStart
    case chaoticHomeSelfReliant
    case luckyBreak
    case wealthyDynasty
    case academicLegacy
    case ruralEscapist
    case techProdigy
    case artisticDrifter
    var id: String { rawValue }
}
enum LifePhase: String, Codable, CaseIterable {
    case adolescence
    case launch
    case earlyCareer
    case familyBuilder
    case midlife
    case laterLife
}
enum TrajectoryDirection: String, Codable, CaseIterable {
    case rising
    case stable
    case fragile
    case sliding
}
enum LifeResilience: String, Codable, CaseIterable, Identifiable {
    case resilient
    case grounded

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .resilient: return "Resilient"
        case .grounded: return "Grounded"
        }
    }

    var description: String {
        switch self {
        case .resilient:
            return "More room to recover from rough years. Still authentic, but less punishing spirals."
        case .grounded:
            return "Full Life Killer experience. Harsh consequences, minimal safety nets. For veterans."
        }
    }

    var isDefault: Bool { self == .resilient }
}
enum LivingArrangement: String, Codable, CaseIterable {
    case familyHome
    case roommates
    case soloRenting
    case ownerOccupied
    case couchSurfing
}
enum YearChapterPhase: String, Codable, Equatable {
    case forecast
    case event
    case reaction
    case summary
    case resolution
    case crisis
}
enum HistoryDomainTag: String, Codable, CaseIterable, Identifiable {
    case system
    case activities
    case education
    case career
    case military
    case social
    case fame
    case crime
    case legal
    case risk
    case finance
    case relationships
    case health
    case family
    case housing
    case assets
    case progress
    case lifeEvent
    case identity  // D1 self domain
    /// Instant-path autonomous world reaction (NPC, health spillover, etc.)
    case autonomousReaction

    var id: String { rawValue }
}
enum YearlyOutcomeTone: String, Codable, Equatable {
    case positive
    case neutral
    case warning
}
enum EventCategory: String, Codable, CaseIterable {
    case general
    case education
    case career
    case finance
    case relationships
    case social
    case health
}
enum EventSeverity: String, Codable, CaseIterable {
    case routine
    case consequential
    case critical
}

