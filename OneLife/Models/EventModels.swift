import Foundation

// MARK: - Event Data Models



struct EventPack: Codable {
    var events: [GameEvent]
}

struct GameEvent: Codable, Identifiable, Equatable {
    var id: String
    var category: EventCategory
    var tags: [String]
    var severity: EventSeverity
    var title: String
    var text: String
    var minAge: Int
    var maxAge: Int
    var weight: Int
    var cooldownYears: Int
    var triggerOnce: Bool
    var requirements: [String]
    var followUpEventIDs: [String]
    var choices: [EventChoice]

    init(
        id: String,
        category: EventCategory = .general,
        tags: [String] = [],
        severity: EventSeverity = .routine,
        title: String,
        text: String,
        minAge: Int,
        maxAge: Int,
        weight: Int,
        cooldownYears: Int,
        triggerOnce: Bool = false,
        requirements: [String],
        followUpEventIDs: [String] = [],
        choices: [EventChoice]
    ) {
        self.id = id
        self.category = category
        self.tags = tags
        self.severity = severity
        self.title = title
        self.text = text
        self.minAge = minAge
        self.maxAge = maxAge
        self.weight = weight
        self.cooldownYears = cooldownYears
        self.triggerOnce = triggerOnce
        self.requirements = requirements
        self.followUpEventIDs = followUpEventIDs
        self.choices = choices
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case tags
        case severity
        case title
        case text
        case minAge
        case maxAge
        case weight
        case cooldownYears
        case triggerOnce
        case requirements
        case followUpEventIDs
        case choices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        category = try container.decodeIfPresent(EventCategory.self, forKey: .category) ?? .general
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        severity = try container.decodeIfPresent(EventSeverity.self, forKey: .severity) ?? .routine
        title = try container.decode(String.self, forKey: .title)
        text = try container.decode(String.self, forKey: .text)
        minAge = try container.decode(Int.self, forKey: .minAge)
        maxAge = try container.decode(Int.self, forKey: .maxAge)
        weight = try container.decode(Int.self, forKey: .weight)
        cooldownYears = try container.decode(Int.self, forKey: .cooldownYears)
        triggerOnce = try container.decodeIfPresent(Bool.self, forKey: .triggerOnce) ?? false
        requirements = try container.decodeIfPresent([String].self, forKey: .requirements) ?? []
        followUpEventIDs = try container.decodeIfPresent([String].self, forKey: .followUpEventIDs) ?? []
        choices = try container.decode([EventChoice].self, forKey: .choices)
    }
}

struct EventChoice: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var text: String
    var effects: ChoiceEffects
    var microBeat: String?
    var baseFriction: ActionFrictionLevel = .none

    private enum CodingKeys: String, CodingKey {
        case text
        case effects
        case microBeat
        case baseFriction
    }

    init(text: String, effects: ChoiceEffects, microBeat: String? = nil, baseFriction: ActionFrictionLevel = .none) {
        self.text = text
        self.effects = effects
        self.microBeat = microBeat
        self.baseFriction = baseFriction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        effects = try container.decode(ChoiceEffects.self, forKey: .effects)
        microBeat = try container.decodeIfPresent(String.self, forKey: .microBeat)
        baseFriction = try container.decodeIfPresent(ActionFrictionLevel.self, forKey: .baseFriction) ?? .none
    }

    static func == (lhs: EventChoice, rhs: EventChoice) -> Bool {
        lhs.text == rhs.text && lhs.effects == rhs.effects && lhs.microBeat == rhs.microBeat && lhs.baseFriction == rhs.baseFriction
    }
}

