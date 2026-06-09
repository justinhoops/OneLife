import Foundation

// MARK: - Health Domain

struct LifestyleHabits: Codable, Equatable {
    var exercise: Int = 50
    var nutrition: Int = 50
    var stressManagement: Int = 45

    mutating func clamp() {
        exercise = exercise.clamped(to: 0...100)
        nutrition = nutrition.clamped(to: 0...100)
        stressManagement = stressManagement.clamped(to: 0...100)
    }
}

struct HealthCondition: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var severity: Int

    mutating func clamp() {
        severity = severity.clamped(to: 1...100)
    }

    static func == (lhs: HealthCondition, rhs: HealthCondition) -> Bool {
        lhs.name == rhs.name && lhs.severity == rhs.severity
    }
}

struct HealthState: Codable, Equatable {
    var physicalWellness: Int = 60
    var mentalWellness: Int = 55
    var addiction: Int = 0
    var habits: LifestyleHabits = LifestyleHabits()
    var activeConditions: [HealthCondition] = []
    var hasPrimaryCare: Bool = false

    init(
        physicalWellness: Int = 60,
        mentalWellness: Int = 55,
        addiction: Int = 0,
        habits: LifestyleHabits = LifestyleHabits(),
        activeConditions: [HealthCondition] = [],
        hasPrimaryCare: Bool = false
    ) {
        self.physicalWellness = physicalWellness
        self.mentalWellness = mentalWellness
        self.addiction = addiction
        self.habits = habits
        self.activeConditions = activeConditions
        self.hasPrimaryCare = hasPrimaryCare
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        physicalWellness = try container.decodeIfPresent(Int.self, forKey: .physicalWellness) ?? 60
        mentalWellness = try container.decodeIfPresent(Int.self, forKey: .mentalWellness) ?? 55
        addiction = try container.decodeIfPresent(Int.self, forKey: .addiction) ?? 0
        habits = try container.decodeIfPresent(LifestyleHabits.self, forKey: .habits) ?? LifestyleHabits()
        activeConditions = try container.decodeIfPresent([HealthCondition].self, forKey: .activeConditions) ?? []
        hasPrimaryCare = try container.decodeIfPresent(Bool.self, forKey: .hasPrimaryCare) ?? false
        clamp()
    }

    mutating func clamp() {
        physicalWellness = physicalWellness.clamped(to: 0...100)
        mentalWellness = mentalWellness.clamped(to: 0...100)
        addiction = addiction.clamped(to: 0...100)
        habits.clamp()
        activeConditions.indices.forEach { activeConditions[$0].clamp() }
    }
}

