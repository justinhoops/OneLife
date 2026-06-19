import Foundation

struct LifeConsoleSnapshot {
    let name: String
    let age: Int
    let role: String
    let cash: String
    let cashTone: PlannerTone
    let health: Int
    let healthTone: PlannerTone
    let topPressures: [PlannerInsight]
    let selectedAction: String
    let ageUpRisk: [AgeUpRiskSignal]
    let eraName: String
    let eraIcon: String
    let eraTone: PlannerTone

    static let empty = LifeConsoleSnapshot(
        name: "",
        age: 0,
        role: "",
        cash: "$0",
        cashTone: .neutral,
        health: 0,
        healthTone: .neutral,
        topPressures: [],
        selectedAction: "None",
        ageUpRisk: [],
        eraName: "",
        eraIcon: "clock",
        eraTone: .neutral
    )
}

struct ActionSectionModel: Identifiable {
    let id: String
    let title: String
    let actions: [ActionPresentationModel]
}

struct DomainPanelModel {
    let id: ConsoleDomain
    let title: String
    let icon: String
    let tone: PlannerTone
    let status: String
    let velocity: String
    let metrics: [ConsoleMetricModel]
    let pressureLine: String
    let quickActions: [ActionPresentationModel]
    let actions: [ActionPresentationModel]
    let actionSections: [ActionSectionModel]?
    let riskQuickActions: [ActionPresentationModel]
    let riskActions: [ActionPresentationModel]
    let familyQuickActions: [ActionPresentationModel]
    let familyActions: [ActionPresentationModel]
    let detailDestination: PlannerDetailDestination?
    let detailButtonIdentifier: String?
    var previewProvider: ((ActionChoiceID) -> [String])? = nil
    var secondaryAction: (title: String, icon: String, action: () -> Void)? = nil
}

struct ConsoleMetricModel: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let tone: PlannerTone
}

struct ActionPresentationModel: Identifiable {
    let id: String
    let domain: ActionDomain
    let choiceID: ActionChoiceID
    var title: String
    let subtitle: String
    let icon: String
    let tone: PlannerTone
    let tags: [String]
    var disabledReason: String?
    var isSelected: Bool
}

enum ConsoleDomain: String, CaseIterable, Identifiable, Hashable {
    case life
    case work
    case money
    case people
    case activities
    case body
    case log

    var id: String { rawValue }
}

/// Tier B: Teach / coach flags for console domain panels (rebuilt with derived caches).
struct ConsoleTeachSnapshot: Equatable {
    var showHoldHint: Bool = false
    var seenFirstLongPressTeach: Bool = false
    var firstQuickActionTeachLine: String?
    var adultChildrenFocusChip: String?

    static let empty = ConsoleTeachSnapshot()
}

/// Tier B: Audit ribbon chips above domain metrics (no live `GameState` reads in panel body).
struct ConsoleAuditRibbonSnapshot: Equatable {
    var chips: [GlanceAuditChip] = []
    var momentumVisible: Bool = false
    var momentumStrength: Int = 0
    var showCulturalFame: Bool = false
    var culturalFame: Int = 0

    static let empty = ConsoleAuditRibbonSnapshot()
}

/// Glance chip for the 2-second domain audit row.
struct GlanceAuditChip: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let value: String
    let tone: PlannerTone
}

/// Single-line late-game recognition summary. Full fame remains behind existing detail routes.
struct RecognitionGlanceItem: Identifiable, Equatable {
    let id = "recognition-glance"
    let label: String
    let score: Int
    let subtitle: String
    let tone: PlannerTone
    let destination: PlannerDetailDestination?
}

/// Single-line collection/lifestyle identity for the Money tab console.
struct CollectionGlanceItem: Identifiable, Equatable {
    let id = "collection-glance"
    let label: String
    let score: Int
    let subtitle: String
    let tone: PlannerTone
    let completedSetCount: Int
}

/// Compact adult-child summary for late-game People panels.
struct AdultChildrenCompactSummary: Equatable {
    var previewItems: [FamilyChildGlanceItem] = []
    var overflowCount: Int = 0
    var summaryLine: String?

    static let empty = AdultChildrenCompactSummary()
}

/// Tier B: Family glance payloads bundled for People tab panels.
struct ConsoleFamilyGlancePresentation: Equatable {
    var household: FamilyHouseholdSnapshot = .empty
    var atHomeItems: [FamilyAtHomeGlanceItem] = []
    var atHomeOverflow: Int = 0
    var adultChildrenFull: [FamilyChildGlanceItem] = []
    var adultChildrenCompact: AdultChildrenCompactSummary = .empty
    var showFamilyTraySubtitle: Bool = false
    var showHouseholdStrip: Bool = false

    static let empty = ConsoleFamilyGlancePresentation()
}

/// At-home child row for People tab glance (Tier B cache).
struct FamilyAtHomeGlanceItem: Identifiable, Equatable {
    let id: String
    let name: String
    let age: Int
    let temperament: String
    let bond: Int
    let vibeLine: String
}

/// Adult child chip for People tab glance (Tier B cache).
struct FamilyChildGlanceItem: Identifiable, Equatable {
    let id: String
    let name: String
    let age: Int
    let outcomeLabel: String
    let temperament: String
    let bond: Int
    let continuityHint: String
    let storyTease: String
    let relationshipQuality: Int
}

/// Tier B: Single console presentation bundle — panels + glance data rebuilt together.
struct ConsolePresentationSnapshot {
    var panels: [ConsoleDomain: DomainPanelModel] = [:]
    var familyGlance: ConsoleFamilyGlancePresentation = .empty
    var teach: ConsoleTeachSnapshot = .empty
    var auditRibbon: ConsoleAuditRibbonSnapshot = .empty
    var recognitionGlance: RecognitionGlanceItem?
    var collectionGlance: CollectionGlanceItem?

    static let empty = ConsolePresentationSnapshot()

    func panel(for domain: ConsoleDomain) -> DomainPanelModel? {
        panels[domain]
    }
}
