import Foundation

enum AmbientContactRole: String, Codable, CaseIterable {
    case friend
    case guardian
    case mentor
    case partner
}

enum AmbientContactCadence: String, Codable, CaseIterable {
    case quiet
    case regular
    case frequent
}

struct AmbientContact: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var role: AmbientContactRole
    var bond: Int
    var reliability: Int
    var cadence: AmbientContactCadence
    var lastInteractionAge: Int? = nil
    var memoryFlags: [String] = []
}
struct YearForecastCard: Codable, Equatable, Identifiable {
    var id: String
    var age: Int
    var title: String
    var subtitle: String
    var focusTitle: String
    var focusDetail: String
    var pressureLabel: String
    var pressureDetail: String
    var anticipationTitle: String
    var anticipationDetail: String
    var tone: YearlyOutcomeTone
    /// Optional ambient contact voice surfaced on the forecast commit beat (Y2).
    var voiceName: String? = nil
    var voiceLine: String? = nil
}

struct TurnStakesSignal: Codable, Equatable, Identifiable {
    var id: String
    var label: String
    var title: String
    var detail: String
    var domain: HistoryDomainTag
    var tone: YearlyOutcomeTone
}

struct TurnStakesSnapshot: Codable, Equatable {
    var focus: TurnStakesSignal
    var topPressure: TurnStakesSignal
    var topOpportunity: TurnStakesSignal
    var ignoredRisk: TurnStakesSignal
    var spilloverRisk: TurnStakesSignal
    var momentum: TurnStakesSignal?   // Phase 2: Instant action momentum carrying into the year
}

struct YearReactionCard: Codable, Equatable, Identifiable {
    var id: String
    var kicker: String
    var title: String
    var detail: String
    var domain: HistoryDomainTag
    var tone: YearlyOutcomeTone
}

struct LegalCaseSummary: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var allegation: String
    var evidence: Int
    var disposition: String
    var consequence: String
    var decisiveCauses: [String]
}

struct ActiveYearChapter: Codable, Equatable {
    var targetAge: Int
    var phase: YearChapterPhase = .forecast
    var plannedActions: [PlayerYearAction]
    var forecast: YearForecastCard
    var stakes: TurnStakesSnapshot? = nil
    var pendingEventIDs: [String] = []
    var eventID: String? = nil
    var selectedChoiceText: String? = nil
    var reactionCards: [YearReactionCard] = []
    var currentReactionIndex: Int = 0
    var pendingCombatFight: CombatFightSummary? = nil
    var pendingLegalCase: LegalCaseSummary? = nil
    var pendingSummary: YearlyOutcomeSummary? = nil
    var pendingConsequencePreview: ConsequencePreview? = nil
    var dominantUnresolvedConsequence: ConsequencePreview? = nil
    var pendingResolution: ResolutionPreview? = nil
    var pendingCrisis: CrisisInteraction? = nil
    var pendingPitchDeck: PitchDeckInteraction? = nil
    var resolutionCardIndex: Int = 0
}
struct ScheduledEventTrigger: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var eventID: String
    var yearsFromNow: Int
    var title: String? = nil
    var detail: String? = nil

    private enum CodingKeys: String, CodingKey {
        case id
        case eventID
        case yearsFromNow
        case title
        case detail
    }

    init(
        id: String = UUID().uuidString,
        eventID: String,
        yearsFromNow: Int,
        title: String? = nil,
        detail: String? = nil
    ) {
        self.id = id
        self.eventID = eventID
        self.yearsFromNow = yearsFromNow
        self.title = title
        self.detail = detail
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        eventID = try container.decode(String.self, forKey: .eventID)
        yearsFromNow = try container.decode(Int.self, forKey: .yearsFromNow)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        detail = try container.decodeIfPresent(String.self, forKey: .detail)
    }
}
struct HistoryEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var age: Int
    var title: String
    var text: String
    var tags: [HistoryDomainTag] = []

    private enum CodingKeys: String, CodingKey {
        case id
        case age
        case title
        case text
        case tags
    }

    init(id: UUID = UUID(), age: Int, title: String, text: String, tags: [HistoryDomainTag] = []) {
        self.id = id
        self.age = age
        self.title = title
        self.text = text
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        age = try container.decode(Int.self, forKey: .age)
        title = try container.decode(String.self, forKey: .title)
        text = try container.decode(String.self, forKey: .text)
        tags = try container.decodeIfPresent([HistoryDomainTag].self, forKey: .tags) ?? []
    }

    static func == (lhs: HistoryEntry, rhs: HistoryEntry) -> Bool {
        lhs.age == rhs.age &&
        lhs.title == rhs.title &&
        lhs.text == rhs.text &&
        lhs.tags == rhs.tags
    }
}

struct DomainYearResult: Equatable {
    var notes: [DomainNote] = []
    var events: [GameEvent] = []
    var spilloverSignals: [SpilloverSignal] = []
    var coreEffects: CoreStatEffects? = nil
    var trajectoryEffects: TrajectoryEffects? = nil
    var educationEffects: EducationEffects? = nil
    var careerEffects: CareerEffects? = nil
    var specialCareerEffects: SpecialCareerEffects? = nil
    var militaryEffects: MilitaryEffects? = nil
    var crimeEffects: CrimeEffects? = nil
    var legalEffects: LegalEffects? = nil
    var financeEffects: FinanceEffects? = nil
    var relationshipEffects: RelationshipEffects? = nil
    var familyEffects: FamilyEffects? = nil
    var healthEffects: HealthEffects? = nil
    var housingEffects: HousingEffects? = nil
    var assetEffects: AssetEffects? = nil
    var fameEffects: FameEffects? = nil   // Fame Web F1
    var combatFightSummary: CombatFightSummary? = nil
    var legalCaseSummary: LegalCaseSummary? = nil
}

struct DomainNote: Equatable {
    var title: String
    var text: String
    var tags: [HistoryDomainTag] = []
}

struct SpilloverSignal: Equatable {
    var title: String
    var detail: String
    var sourceDomain: HistoryDomainTag
    var impactedDomain: HistoryDomainTag
    var tone: YearlyOutcomeTone
    var impactScore: Int
}


struct YearlyOutcomeItem: Codable, Identifiable, Equatable {
    var title: String
    var detail: String
    var domain: HistoryDomainTag
    var tone: YearlyOutcomeTone
    var impactScore: Int

    var id: String { "\(domain.rawValue)-\(title)-\(detail)" }
}

struct YearlyOutcomeSummary: Codable, Equatable {
    var age: Int
    var headlines: [YearlyOutcomeItem] = []
    var topProblem: YearlyOutcomeItem? = nil
    var topOpportunity: YearlyOutcomeItem? = nil
    var momentum: YearlyOutcomeItem? = nil
    var spillovers: [YearlyOutcomeItem] = []
    var checkpoint: YearlyOutcomeItem? = nil
    var focusOutcome: YearlyOutcomeItem? = nil
    var mainTradeoff: YearlyOutcomeItem? = nil
    var nextYearPressure: YearlyOutcomeItem? = nil
    var yearlyStanceOutcome: YearlyOutcomeItem? = nil
}

struct ConsequencePreview: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var domain: HistoryDomainTag
    var tone: YearlyOutcomeTone
}

struct ResolutionPreview: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var actionTitle: String
}

struct CrisisChoice: Codable, Equatable, Identifiable {
    var id: String
    var text: String
    var detail: String
    var costSummary: String
    var isBuyBack: Bool // true = survive with penalty, false = accept death/failure
}

struct CrisisInteraction: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var choices: [CrisisChoice]
}

enum BusinessSector: String, Codable, CaseIterable {
    case general
    case semiconductors
    case restaurants
    case automobiles
    case gaming
}

enum AdvisorSpecialty: String, Codable, CaseIterable {
    case growth
    case strategy
    case political
}

struct BusinessAdvisor: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var specialty: AdvisorSpecialty
    var yearlyFee: Int
}

struct PitchDeckChoice: Codable, Equatable, Identifiable {
    var id: String
    var text: String
    var detail: String
    var sector: BusinessSector
}

struct PitchDeckInteraction: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var choices: [PitchDeckChoice]
}

