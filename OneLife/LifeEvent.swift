import Foundation

enum EventChoiceID: String, Codable, Identifiable {
    case focus, accept, recover, talk, decline
    case makeTime, negotiate, dismiss, prioritizeFamily, compromise, chooseWork
    case vehicleRepair, vehicleDefer, vehicleSell, vehicleKeepSettlement, vehicleReplace
    case assetRecover, assetReport, assetAccept
    var id: String { rawValue }
}

enum FinanceChoiceEffect: String, Codable {
    case startWorkout
}

/// Presentation-only categorization for the shared life-moment sheet. It is
/// derived from existing event metadata and never enters persistence or game
/// resolution, so new content retains a safe generic fallback by default.
enum LifeMomentPresentationStyle: Equatable {
    case relationship
    case finance
    case recovery
    case school
    case play
    case yearly
    case general

    static func resolve(for event: PresentedEvent) -> Self {
        if event.isPartnerEvent { return .relationship }

        let identifier = event.id.lowercased()
        if containsAny(identifier, ["economy", "debt", "bill", "rent", "mortgage", "foreclosure", "cash", "cost", "workout", "housing", "property", "insurance"]) {
            return .finance
        }
        if containsAny(identifier, ["recovery", "health", "medical", "body", "sleep", "burnout", "care", "condition"]) {
            return .recovery
        }
        if containsAny(identifier, ["school", "exam", "study", "scholarship", "teacher", "college", "credential", "grade", "activity"]) {
            return .school
        }
        if containsAny(identifier, ["party", "friend", "club", "night", "open-mic", "creative", "weekend"]) {
            return .play
        }
        return event.kind == .yearly ? .yearly : .general
    }

    private static func containsAny(_ value: String, _ terms: [String]) -> Bool {
        terms.contains { value.contains($0) }
    }
}

struct EventChoice: Codable, Equatable, Identifiable {
    let id: EventChoiceID
    let title: String
    let detail: String
    let effects: EffectRange
    let partnerEffect: PartnerEffect
    let narrative: String
    var educationEffect: EducationChoiceEffect? = nil
    var educationTransitionEffect: EducationTransitionEffect? = nil
    var personalityImpulse: PersonalityImpulse? = nil
    var relationshipRole: SimulationRole? = nil
    var npcRapportDelta: Int? = nil
    var propertyEffect: PropertyEventEffect? = nil
    var vehicleEffect: VehicleEventEffect? = nil
    var assetLossEffect: AssetLossEffect? = nil
    var financeEffect: FinanceChoiceEffect? = nil
    var financialPurpose: FinancialPurpose? = nil
    /// Dynamic-cast situations target one identity rather than whichever NPC
    /// currently occupies a broad contextual role.
    var castMemberID: String? = nil
    var castRapportDelta: Int? = nil
    /// Some decisions materially involve two people in the cast—for example,
    /// a friend risking their standing to introduce the player to a boss.
    var secondaryCastMemberID: String? = nil
    var secondaryCastRapportDelta: Int? = nil
    /// Family remains a distinct domain from the dynamic cast, but authored
    /// family moments still need to resolve against one exact contact.
    var familyContactID: String? = nil
    var familyBondDelta: Int? = nil
}

struct LifeEvent: Identifiable {
    let id: String
    let headline: String
    let detail: String
    let weight: (LifeState) -> Int
    let choices: [EventChoice]
}

struct PresentedEvent: Codable, Equatable, Identifiable {
    enum Kind: String, Codable {
        case instant
        case yearly
    }

    let id: String
    let headline: String
    let detail: String
    let choices: [EventChoice]
    let yearDeltas: DeltaSummary
    let isPartnerEvent: Bool
    var kind: Kind

    init(
        _ event: LifeEvent,
        yearDeltas: DeltaSummary = DeltaSummary(),
        isPartnerEvent: Bool = false,
        kind: Kind = .instant
    ) {
        id = event.id
        headline = event.headline
        detail = event.detail
        choices = event.choices
        self.yearDeltas = yearDeltas
        self.isPartnerEvent = isPartnerEvent
        self.kind = kind
    }

    init(
        id: String,
        headline: String,
        detail: String,
        choices: [EventChoice],
        yearDeltas: DeltaSummary,
        isPartnerEvent: Bool,
        kind: Kind = .instant
    ) {
        self.id = id
        self.headline = headline
        self.detail = detail
        self.choices = choices
        self.yearDeltas = yearDeltas
        self.isPartnerEvent = isPartnerEvent
        self.kind = kind
    }

    private enum CodingKeys: String, CodingKey {
        case id, headline, detail, choices, yearDeltas, isPartnerEvent, kind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        headline = try container.decode(String.self, forKey: .headline)
        detail = try container.decode(String.self, forKey: .detail)
        choices = try container.decode([EventChoice].self, forKey: .choices)
        yearDeltas = try container.decodeIfPresent(DeltaSummary.self, forKey: .yearDeltas) ?? DeltaSummary()
        isPartnerEvent = try container.decodeIfPresent(Bool.self, forKey: .isPartnerEvent) ?? false
        kind = try container.decodeIfPresent(Kind.self, forKey: .kind) ?? .instant
    }
}
