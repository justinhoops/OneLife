import SwiftUI

// MARK: - Premium surfaces (adapts light / dark)

enum OLTheme {
    static func cardFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color.white.opacity(0.94)
    }

    static func cardStroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
    }

    static func cardShadowOpacity(_ scheme: ColorScheme) -> Double {
        scheme == .dark ? 0.5 : 0.08
    }

    static func subtleFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
    }
}

enum HeaderOccupationCopy {
    static func specialCareer(_ track: SpecialCareerTrack) -> (title: String, symbol: String) {
        switch track {
        case .inactive:
            return ("", "briefcase.fill")
        case .entertainment:
            return ("Entertainment", "star.fill")
        case .movieActor:
            return ("Movie Actor", "theatermasks.fill")
        case .musicProducer:
            return ("Producer", "slider.horizontal.3")
        case .movieProducer:
            return ("♦ Movie Producer", "crown.fill")  // CT1-2: Diamond tier visual signal
        case .recordLabelOwner:
            return ("♦ Record Label", "crown.fill")
        case .coach:
            return ("Program Coach", "sportscourt.fill")
        case .sportsOwner:
            return ("♦ Sports Owner", "building.2.crop.circle")
        case .crime:
            return ("Street Career", "flame.fill")  // Basic crime - Special tier, separate from Diamond Enterprise paths
        case .founder:
            return ("Founder", "rocket.fill")
        case .athlete:
            return ("Athlete", "figure.run")
        case .fightEmpire:
            return ("♦ Fight Empire", "crown.fill")
        case .shadowOperative:
            return ("♦ Shadow Operative", "crown.fill")  // Diamond tier - Criminal Enterprise
        case .trader:
            return ("♦ Gray Market Trader", "crown.fill")  // Diamond tier - Criminal Enterprise
        case .ventureCapitalist:
            return ("♦ Venture Capitalist", "crown.fill")  // Diamond tier - Criminal Enterprise
        case .corporateRaider:
            return ("♦ Corporate Raider", "crown.fill")  // Diamond tier - Criminal Enterprise
        case .contentCreator:
            return ("Creator", "camera.fill")
        case .politics:
            return ("Politics", "person.3.fill")
        case .military:
            return ("Military", "shield.fill")
        }
    }
}

struct PlannerInsight: Identifiable, Hashable {
    let title: String
    let value: String
    let tone: PlannerTone

    var id: String { title }
}

struct YearlyStanceChip: Identifiable, Hashable {
    let id: YearlyStanceID
    let title: String
    let detail: String
    let tone: PlannerTone
    let isSelected: Bool
}

struct RecommendedActionChip: Identifiable, Hashable {
    let id: String
    let domain: ActionDomain
    let choiceID: ActionChoiceID
    let title: String
    let relief: String
    let cost: String
    let tone: PlannerTone
}

struct OverviewSignal: Identifiable, Hashable {
    let symbol: String
    let title: String
    let value: String
    let tone: PlannerTone
    let insightTopic: ChangeInsightTopic?

    init(symbol: String, title: String, value: String, tone: PlannerTone, insightTopic: ChangeInsightTopic? = nil) {
        self.symbol = symbol
        self.title = title
        self.value = value
        self.tone = tone
        self.insightTopic = insightTopic
    }

    var id: String { title }
}

struct PressureSummary: Hashable {
    let symbol: String
    let title: String
    let detail: String
    let tone: PlannerTone
    let destination: PlannerDetailDestination?
}

struct RecommendedFocus: Hashable {
    let domain: ActionDomain?
    let choiceID: ActionChoiceID?
    let title: String
    let subtitle: String
    let previewTags: [String]
    let isSelected: Bool
}

struct TabOverviewModel: Hashable {
    let title: String
    let symbol: String
    let status: String
    let summary: String
    let tone: PlannerTone
    let trendLabel: String
    let detailDestination: PlannerDetailDestination?
    let topSignals: [OverviewSignal]
    let primaryPressure: PressureSummary
    let recommendedFocus: RecommendedFocus
    let stripTitle: String
    let stripItems: [String]
    var continuity: ContinuityHubModel? = nil
}

struct ContinuityHubItem: Identifiable, Hashable {
    let title: String
    let detail: String
    let tone: PlannerTone

    var id: String { "\(title)-\(detail)" }
}

struct ContinuityHubModel: Hashable {
    let status: String
    let changed: [ContinuityHubItem]
    let unresolved: [ContinuityHubItem]
    let comingBack: [String]
}

enum PlannerDetailDestination: String, Identifiable {
    case careerOverview
    case careerTrack
    case careerHistory
    case educationOverview
    case educationClimate
    case educationHistory
    case financeCashflow
    case financeInvesting
    case financePolicy
    case financeHistory
    case relationshipsConnections
    case relationshipsFamily
    case relationshipsHistory
    case healthOverview
    case healthConditions
    case healthHistory
    case lifeHousing
    case lifeLegacy
    case lifeHistory

    var id: String { rawValue }
}

enum FeedbackIntensitySetting: String, CaseIterable, Identifiable {
    case full
    case reduced
    case off

    var id: String { rawValue }

    var title: String {
        switch self {
        case .full: return "Full"
        case .reduced: return "Reduced"
        case .off: return "Off"
        }
    }
}

enum AutoLifePace: String, CaseIterable, Identifiable {
    case manual
    case guided
    case autopilot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual: return "Manual"
        case .guided: return "Guided"
        case .autopilot: return "Autopilot"
        }
    }
}

enum ColorEmphasisSetting: String, CaseIterable, Identifiable {
    case full
    case softened
    case muted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .full: return "Full"
        case .softened: return "Softened"
        case .muted: return "Muted"
        }
    }

    var saturation: Double {
        switch self {
        case .full: return 1.0
        case .softened: return 0.82
        case .muted: return 0.68
        }
    }
}

struct BackgroundPulseItem: Identifiable, Hashable {
    let title: String
    let detail: String
    let tone: PlannerTone

    var id: String { "\(title)-\(detail)" }
}

enum ChangeInsightTopic: String, CaseIterable, Identifiable, Hashable {
    case money
    case work
    case relationships
    case health

    var id: String { rawValue }

    var title: String {
        switch self {
        case .money: return "Money Pressure"
        case .work: return "Work Stability"
        case .relationships: return "Relationship Stability"
        case .health: return "Health"
        }
    }

    var symbol: String {
        switch self {
        case .money: return "dollarsign.circle.fill"
        case .work: return "briefcase.fill"
        case .relationships: return "person.2.fill"
        case .health: return "cross.case.fill"
        }
    }
}

struct ChangeInsightCard: Identifiable, Hashable {
    let topic: ChangeInsightTopic
    let headline: String
    let causes: [String]
    let implication: String?
    let tone: PlannerTone

    var id: String { topic.rawValue }
}

struct ActivityPulse: Equatable {
    let title: String
    let detail: String
    let tone: PlannerTone
}

/// Represents a floating delta that appears when an instant action has immediate visible impact.
/// This is core to making the frictionless system feel responsive.
struct FloatingDelta: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let tone: PlannerTone
    let domain: ActionDomain?
}

struct AgeUpRiskSignal: Identifiable, Hashable {
    let title: String
    let symbol: String
    let tone: PlannerTone

    var id: String { "\(symbol)-\(title)" }
}

struct CauseTrailItem: Identifiable, Hashable {
    let title: String
    let detail: String
    let tone: PlannerTone

    var id: String { "\(title)-\(detail)" }
}

struct PlannerReturnContext: Equatable {
    let tab: GameViewModel.Tab
    let destination: PlannerDetailDestination

    var title: String {
        switch destination {
        case .careerOverview: return "Back to Career Details"
        case .careerTrack: return "Back to Track Details"
        case .careerHistory: return "Back to Career History"
        case .educationOverview: return "Back to Education Details"
        case .educationClimate: return "Back to School Climate"
        case .educationHistory: return "Back to Education History"
        case .financeCashflow: return "Back to Cash Flow"
        case .financeInvesting: return "Back to Investing"
        case .financePolicy: return "Back to Policy And Housing"
        case .financeHistory: return "Back to Finance History"
        case .relationshipsConnections: return "Back to Connections"
        case .relationshipsFamily: return "Back to Family Planning"
        case .relationshipsHistory: return "Back to Relationship History"
        case .healthOverview: return "Back to Health Details"
        case .healthConditions: return "Back to Recovery Risks"
        case .healthHistory: return "Back to Health History"
        case .lifeHousing: return "Back to Housing Details"
        case .lifeLegacy: return "Back to Legacy Details"
        case .lifeHistory: return "Back to Life History"
        }
    }
}

enum ContinuityLanguage {
    static func changedTitle(for showingEducation: Bool) -> String {
        showingEducation ? "School Path Shifted" : "Work And Money Shifted"
    }

    static func pressureTitle(for domain: GameViewModel.Tab, showingEducation: Bool) -> String {
        switch domain {
        case .home:
            return "Wellness & Activity Is Active"
        case .occupation:
            return showingEducation ? "School Pressure Is Active" : "Work Stability Is Active"
        case .assets:
            return "Financial Inventory Is Active"
        case .relationships:
            return "Relationship Pressure Is Active"
        case .activities:
            return "Instant Actions Are Live"
        case .history:
            return "Your Story Log Is Open"
        }
    }

    static func continuityStatus(changed: [ContinuityHubItem], unresolved: [ContinuityHubItem], comingBack: [String]) -> String {
        if !unresolved.isEmpty {
            return "Still active"
        }
        if !comingBack.isEmpty {
            return "Coming back later"
        }
        if !changed.isEmpty {
            return "This year moved"
        }
        return "No major carryover"
    }
}

