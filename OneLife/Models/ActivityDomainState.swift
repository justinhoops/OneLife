import Foundation

enum ActivityCategory: String, Codable, CaseIterable, Identifiable {
    case mindBody
    case social
    case leisure
    case romanceSex
    case viceRisk
    case familyHome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mindBody: return "Mind & Body"
        case .social: return "Social"
        case .leisure: return "Leisure"
        case .romanceSex: return "Romance & Sex"
        case .viceRisk: return "Vice & Risk"
        case .familyHome: return "Family & Home"
        }
    }

    var symbol: String {
        switch self {
        case .mindBody: return "figure.mind.and.body"
        case .social: return "person.3.fill"
        case .leisure: return "gamecontroller.fill"
        case .romanceSex: return "heart.fill"
        case .viceRisk: return "flame.fill"
        case .familyHome: return "house.fill"
        }
    }
}

enum ActivityRiskLevel: String, Codable, Equatable {
    case grounding
    case easy
    case charged
    case dangerous

    var label: String {
        switch self {
        case .grounding: return "Grounding"
        case .easy: return "Low risk"
        case .charged: return "Charged"
        case .dangerous: return "Risky"
        }
    }

    var tone: YearlyOutcomeTone {
        switch self {
        case .grounding:
            return .positive
        case .easy:
            return .neutral
        case .charged, .dangerous:
            return .warning
        }
    }
}

struct ActivityEffects: Equatable {
    var happiness: Int = 0
    var smarts: Int = 0
    var looks: Int = 0
    var health: Int = 0
    var cash: Int = 0
    var financialStress: Int = 0
    var physicalWellness: Int = 0
    var mentalWellness: Int = 0
    var stressManagement: Int = 0
    var schoolStanding: Int = 0
    var engagement: Int = 0
    var schoolBelonging: Int = 0
    var activityMomentum: Int = 0
    var careerPerformance: Int = 0
    var careerBurnout: Int = 0
    var careerJobSecurity: Int = 0
    var friendBond: Int = 0
    var partnerBond: Int = 0
    var partnerCommitmentAlignment: Int = 0
    var crimeHeat: Int = 0
    var housingStability: Int = 0
    var consequences: [String: Int] = [:]
    var identityTags: [String: Int] = [:]
    var socialMomentum: Int = 0
    var recoveryBalance: Int = 0
    var riskLoad: Int = 0

    init(
        happiness: Int = 0,
        smarts: Int = 0,
        looks: Int = 0,
        health: Int = 0,
        cash: Int = 0,
        financialStress: Int = 0,
        physicalWellness: Int = 0,
        mentalWellness: Int = 0,
        stressManagement: Int = 0,
        schoolStanding: Int = 0,
        engagement: Int = 0,
        schoolBelonging: Int = 0,
        activityMomentum: Int = 0,
        careerPerformance: Int = 0,
        careerBurnout: Int = 0,
        careerJobSecurity: Int = 0,
        friendBond: Int = 0,
        partnerBond: Int = 0,
        partnerCommitmentAlignment: Int = 0,
        crimeHeat: Int = 0,
        housingStability: Int = 0,
        consequences: [String: Int] = [:],
        identityTags: [String: Int] = [:],
        socialMomentum: Int = 0,
        recoveryBalance: Int = 0,
        riskLoad: Int = 0
    ) {
        self.happiness = happiness
        self.smarts = smarts
        self.looks = looks
        self.health = health
        self.cash = cash
        self.financialStress = financialStress
        self.physicalWellness = physicalWellness
        self.mentalWellness = mentalWellness
        self.stressManagement = stressManagement
        self.schoolStanding = schoolStanding
        self.engagement = engagement
        self.schoolBelonging = schoolBelonging
        self.activityMomentum = activityMomentum
        self.careerPerformance = careerPerformance
        self.careerBurnout = careerBurnout
        self.careerJobSecurity = careerJobSecurity
        self.friendBond = friendBond
        self.partnerBond = partnerBond
        self.partnerCommitmentAlignment = partnerCommitmentAlignment
        self.crimeHeat = crimeHeat
        self.housingStability = housingStability
        self.consequences = consequences
        self.identityTags = identityTags
        self.socialMomentum = socialMomentum
        self.recoveryBalance = recoveryBalance
        self.riskLoad = riskLoad
    }
}

struct ActivityDefinition: Identifiable, Equatable {
    let id: String
    let title: String
    let category: ActivityCategory
    let costLine: String
    let previewTags: [String]
    let risk: ActivityRiskLevel
    let minimumAge: Int?
    let requiresPartner: Bool
    let requiresFriends: Bool
    let requiresChildren: Bool
    let effects: ActivityEffects

    init(
        id: String,
        title: String,
        category: ActivityCategory,
        costLine: String,
        previewTags: [String],
        risk: ActivityRiskLevel,
        minimumAge: Int? = nil,
        requiresPartner: Bool = false,
        requiresFriends: Bool = false,
        requiresChildren: Bool = false,
        effects: ActivityEffects
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.costLine = costLine
        self.previewTags = previewTags
        self.risk = risk
        self.minimumAge = minimumAge
        self.requiresPartner = requiresPartner
        self.requiresFriends = requiresFriends
        self.requiresChildren = requiresChildren
        self.effects = effects
    }

    func isAvailable(in state: GameState) -> Bool {
        if let minimumAge, state.player.age < minimumAge { return false }
        if requiresPartner, !state.relationships.hasPartner { return false }
        if requiresFriends, state.relationships.friends.isEmpty { return false }
        if requiresChildren, state.family.childCount == 0 { return false }
        switch id {
        case "art_collecting":
            return state.finance.cashOnHand >= 5_000
        case "high_end_racing":
            return state.finance.cashOnHand >= 15_000
        default:
            break
        }
        return true
    }
}

struct ActivityRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var age: Int
    var activityID: String
    var title: String
    var category: ActivityCategory
    var headline: String
    var detail: String
    var tone: YearlyOutcomeTone

    static func == (lhs: ActivityRecord, rhs: ActivityRecord) -> Bool {
        lhs.age == rhs.age &&
        lhs.activityID == rhs.activityID &&
        lhs.title == rhs.title &&
        lhs.category == rhs.category &&
        lhs.headline == rhs.headline &&
        lhs.detail == rhs.detail &&
        lhs.tone == rhs.tone
    }
}

struct ActivityState: Codable, Equatable {
    var currentYearAge: Int = 14
    var currentYearActivities: [ActivityRecord] = []
    var currentYearCounts: [String: Int] = [:]
    var previousYearCounts: [String: Int] = [:]
    var yearlyStreaks: [String: Int] = [:]
    var lifetimeCounts: [String: Int] = [:]
    var identityWeights: [String: Int] = [:]
    var socialMomentum: Int = 0
    var recoveryBalance: Int = 0
    var riskLoad: Int = 0

    init(currentYearAge: Int = 14) {
        self.currentYearAge = currentYearAge
    }

    var yearlyCount: Int { currentYearActivities.count }

    mutating func rolloverIfNeeded(to age: Int) {
        guard currentYearAge != age else { return }

        var nextStreaks: [String: Int] = [:]
        for (activityID, count) in currentYearCounts where count > 0 {
            let priorCount = previousYearCounts[activityID, default: 0]
            nextStreaks[activityID] = priorCount > 0 ? yearlyStreaks[activityID, default: 1] + 1 : 1
        }

        previousYearCounts = currentYearCounts
        currentYearCounts = [:]
        currentYearActivities = []
        yearlyStreaks = nextStreaks
        currentYearAge = age
    }

    func preferredEventWeights() -> [String: Int] {
        var weights: [String: Int] = [:]

        if recoveryBalance >= 6 {
            weights["health", default: 0] += 5
            weights["routine", default: 0] += 4
        }
        if socialMomentum >= 5 {
            weights["social", default: 0] += 6
            weights["romance", default: 0] += 4
            weights["family", default: 0] += 2
        }
        if riskLoad >= 8 {
            weights["risk", default: 0] += 8
            weights["money", default: 0] += 4
            weights["health", default: 0] += 4
        }
        if identityWeights["self_improvement", default: 0] >= 4 {
            weights["career", default: 0] += 4
            weights["school", default: 0] += 4
        }
        if identityWeights["domestic", default: 0] >= 4 {
            weights["housing", default: 0] += 4
            weights["family", default: 0] += 5
        }
        if identityWeights["escapist", default: 0] >= 4 {
            weights["chance", default: 0] += 4
            weights["risk", default: 0] += 5
        }

        return weights
    }
}

struct ActivityResolution: Equatable {
    var headline: String
    var detail: String
    var tone: YearlyOutcomeTone
    var pressureChanges: [String: Int]
    var historyEntry: HistoryEntry
    var record: ActivityRecord
    var majorPreview: ConsequencePreview? = nil
}

struct ActivitySystem {
    func availableActivities(for state: GameState, in category: ActivityCategory) -> [ActivityDefinition] {
        Self.catalog.filter { $0.category == category && $0.isAvailable(in: state) }
    }

    func activity(withID id: String) -> ActivityDefinition? {
        Self.catalog.first { $0.id == id }
    }

    func apply(activityID: String, to state: inout GameState) -> ActivityResolution? {
        state.activities.rolloverIfNeeded(to: state.player.age)
        guard let definition = activity(withID: activityID), definition.isAvailable(in: state) else { return nil }

        let repeatCount = state.activities.currentYearCounts[activityID, default: 0]
        let yearlyCount = state.activities.yearlyCount
        let scaled = scaledEffects(for: definition, repeatCount: repeatCount, yearlyCount: yearlyCount)
        apply(scaled, from: definition, to: &state)

        state.activities.currentYearCounts[activityID, default: 0] += 1
        state.activities.lifetimeCounts[activityID, default: 0] += 1
        
        // Hobby/Vice Extension
        if definition.category == .viceRisk {
            state.healthProfile.addiction += 8
        }
        
        for (tag, value) in scaled.identityTags {
            state.activities.identityWeights[tag, default: 0] += value
        }
        state.activities.socialMomentum = (state.activities.socialMomentum + scaled.socialMomentum).clamped(to: -20...20)
        state.activities.recoveryBalance = (state.activities.recoveryBalance + scaled.recoveryBalance).clamped(to: -20...20)
        state.activities.riskLoad = (state.activities.riskLoad + scaled.riskLoad).clamped(to: 0...40)
        for (domain, delta) in scaled.consequences {
            state.consequences.adjustPressure(domain: domain, delta: delta)
        }

        let detail = detailLine(for: definition, scaled: scaled, repeatCount: repeatCount, yearlyCount: yearlyCount)
        let tone = resolutionTone(for: definition, scaled: scaled)
        let record = ActivityRecord(
            age: state.player.age,
            activityID: definition.id,
            title: definition.title,
            category: definition.category,
            headline: headline(for: definition, scaled: scaled),
            detail: detail,
            tone: tone
        )
        state.activities.currentYearActivities.insert(record, at: 0)
        let historyEntry = HistoryEntry(
            age: state.player.age,
            title: record.headline,
            text: detail,
            tags: historyTags(for: definition)
        )
        state.history.insert(historyEntry, at: 0)

        return ActivityResolution(
            headline: record.headline,
            detail: detail,
            tone: tone,
            pressureChanges: scaled.consequences,
            historyEntry: historyEntry,
            record: record,
            majorPreview: majorPreview(for: definition, state: state)
        )
    }

    private func apply(_ effects: ActivityEffects, from definition: ActivityDefinition, to state: inout GameState) {
        state.player.happiness += effects.happiness
        state.player.smarts += effects.smarts
        state.player.looks += effects.looks
        state.player.health += effects.health

        state.finance.cashOnHand += effects.cash
        state.finance.financialStress = (state.finance.financialStress + effects.financialStress).clamped(to: 0...100)

        state.healthProfile.physicalWellness = (state.healthProfile.physicalWellness + effects.physicalWellness).clamped(to: 0...100)
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + effects.mentalWellness).clamped(to: 0...100)
        state.healthProfile.habits.stressManagement = (state.healthProfile.habits.stressManagement + effects.stressManagement).clamped(to: 0...100)

        state.education.schoolStanding = (state.education.schoolStanding + effects.schoolStanding).clamped(to: 0...100)
        state.education.engagement = (state.education.engagement + effects.engagement).clamped(to: 0...100)
        state.education.schoolBelonging = (state.education.schoolBelonging + effects.schoolBelonging).clamped(to: 0...100)
        state.education.activityMomentum = (state.education.activityMomentum + effects.activityMomentum).clamped(to: 0...100)

        state.career.performance = (state.career.performance + effects.careerPerformance).clamped(to: 0...100)
        state.career.burnout = (state.career.burnout + effects.careerBurnout).clamped(to: 0...100)
        state.career.jobSecurity = (state.career.jobSecurity + effects.careerJobSecurity).clamped(to: 0...100)

        if effects.friendBond != 0 {
            if state.relationships.friends.isEmpty, effects.friendBond > 0 {
                state.relationships.friends.append(
                    Relationship(
                        name: Self.generatedFriendName(seed: state.activities.lifetimeCounts[definition.id, default: 0]),
                        type: .friend,
                        bond: min(70, max(38, 36 + effects.friendBond))
                    )
                )
            } else if !state.relationships.friends.isEmpty {
                state.relationships.friends[0].bond = (state.relationships.friends[0].bond + effects.friendBond).clamped(to: 0...100)
                if state.relationships.friends[0].bond < 35 {
                    state.relationships.friends[0].status = .strained
                }
            }
        }

        if effects.partnerBond != 0, let index = state.relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
            var partner = state.relationships.romanticPartners[index]
            partner.bond = (partner.bond + effects.partnerBond).clamped(to: 0...100)
            partner.commitmentAlignment = (partner.commitmentAlignment + effects.partnerCommitmentAlignment).clamped(to: 0...100)
            if effects.partnerBond <= -4 {
                partner.status = .strained
            } else if partner.bond >= 45 && partner.status == .strained {
                partner.status = .active
            }
            state.relationships.romanticPartners[index] = partner
        }

        state.crime.heat = (state.crime.heat + effects.crimeHeat).clamped(to: 0...100)
        state.housing.housingStability = (state.housing.housingStability + effects.housingStability).clamped(to: 0...100)

        state.player.clampStats()
        state.education.clamp()
        state.finance.financialStress = state.finance.financialStress.clamped(to: 0...100)
        state.healthProfile.clamp()
        state.career.clamp()
        state.specialCareer.clamp()
        state.crime.clamp()
        state.housing.clamp()
    }

    private func scaledEffects(for definition: ActivityDefinition, repeatCount: Int, yearlyCount: Int) -> ActivityEffects {
        func scale(_ value: Int, positiveDecay: Double, negativeEscalation: Double) -> Int {
            guard value != 0 else { return 0 }
            if value > 0 {
                let multiplier = max(0.35, 1.0 - (Double(repeatCount) * positiveDecay))
                return scaledInt(value, multiplier: multiplier)
            }
            let annualLoad = max(0, yearlyCount - 2)
            let multiplier = 1.0 + (Double(repeatCount) * negativeEscalation) + (Double(annualLoad) * 0.12)
            return scaledInt(value, multiplier: multiplier)
        }

        let risky = definition.risk == .dangerous || definition.risk == .charged
        let positiveDecay = risky ? 0.28 : 0.18
        let negativeEscalation = risky ? 0.35 : 0.18
        let base = definition.effects

        return ActivityEffects(
            happiness: scale(base.happiness, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            smarts: scale(base.smarts, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            looks: scale(base.looks, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            health: scale(base.health, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            cash: scale(base.cash, positiveDecay: 0.05, negativeEscalation: 0.22),
            financialStress: scale(base.financialStress, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            physicalWellness: scale(base.physicalWellness, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            mentalWellness: scale(base.mentalWellness, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            stressManagement: scale(base.stressManagement, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            schoolStanding: scale(base.schoolStanding, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            engagement: scale(base.engagement, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            schoolBelonging: scale(base.schoolBelonging, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            activityMomentum: scale(base.activityMomentum, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            careerPerformance: scale(base.careerPerformance, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            careerBurnout: scale(base.careerBurnout, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            careerJobSecurity: scale(base.careerJobSecurity, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            friendBond: scale(base.friendBond, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            partnerBond: scale(base.partnerBond, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            partnerCommitmentAlignment: scale(base.partnerCommitmentAlignment, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            crimeHeat: scale(base.crimeHeat, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            housingStability: scale(base.housingStability, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            consequences: base.consequences.mapValues { scale($0, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation) },
            identityTags: base.identityTags,
            socialMomentum: scale(base.socialMomentum, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            recoveryBalance: scale(base.recoveryBalance, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            riskLoad: scale(base.riskLoad, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation)
        )
    }

    private func scaledInt(_ value: Int, multiplier: Double) -> Int {
        let scaled = Int((Double(value) * multiplier).rounded())
        if value > 0 {
            return max(1, scaled)
        }
        return min(-1, scaled)
    }

    private func headline(for definition: ActivityDefinition, scaled: ActivityEffects) -> String {
        switch definition.id {
        case "gym_session": return "You forced your body back into the year"
        case "therapy_session": return "You stopped pretending it would sort itself out"
        case "journal_night": return "You made the noise legible for once"
        case "hang_with_friends": return "You remembered what company can soften"
        case "meet_new_people": return "You put yourself back into circulation"
        case "community_event": return "You showed up somewhere beyond your own head"
        case "gaming_binge": return "You disappeared into a smaller world for a while"
        case "read_or_class": return "You fed the future version of yourself"
        case "weekend_trip": return "You spent money to make the year feel wider"
        case "date_night": return "You made the relationship feel chosen again"
        case "look_for_date": return "You aimed yourself back at intimacy"
        case "hookup": return "You chased closeness without asking for permanence"
        case "drink_night": return "You paid for relief and called it fun"
        case "casino_trip": return "You let chance sit too close to your money"
        case "reckless_night": return "You gave impulse too much room"
        case "visit_family": return "You went back to the people who still know you"
        case "family_night_in": return "You chose steadiness over escape for a night"
        case "deep_clean_home": return "You made the place feel livable again"
        case "childcare_day": return "You spent energy where the family actually needed it"
        default:
            return scaled.happiness >= 0 ? "\(definition.title) landed" : "\(definition.title) came with a bill"
        }
    }

    private func detailLine(for definition: ActivityDefinition, scaled: ActivityEffects, repeatCount: Int, yearlyCount: Int) -> String {
        var fragments: [String] = []
        if scaled.cash != 0 {
            fragments.append(scaled.cash > 0 ? "Cash +$\(scaled.cash)" : "Cash -$\(abs(scaled.cash))")
        }
        if scaled.mentalWellness != 0 {
            fragments.append("Mental \(scaled.mentalWellness > 0 ? "+" : "")\(scaled.mentalWellness)")
        }
        if scaled.physicalWellness != 0 {
            fragments.append("Physical \(scaled.physicalWellness > 0 ? "+" : "")\(scaled.physicalWellness)")
        }
        if scaled.friendBond != 0 || scaled.partnerBond != 0 {
            let socialDelta = scaled.friendBond != 0 ? scaled.friendBond : scaled.partnerBond
            fragments.append("Bond \(socialDelta > 0 ? "+" : "")\(socialDelta)")
        }
        if fragments.isEmpty {
            fragments.append(definition.costLine)
        }
        if repeatCount > 0 {
            fragments.append("repeat payoff tapering")
        }
        if yearlyCount >= 4 {
            fragments.append("the year is starting to push back")
        }
        return fragments.joined(separator: " • ")
    }

    private func resolutionTone(for definition: ActivityDefinition, scaled: ActivityEffects) -> YearlyOutcomeTone {
        if definition.risk == .dangerous || definition.risk == .charged {
            return (scaled.mentalWellness < 0 || scaled.cash < 0 || scaled.crimeHeat > 0) ? .warning : .neutral
        }
        if scaled.mentalWellness > 0 || scaled.physicalWellness > 0 || scaled.friendBond > 0 || scaled.partnerBond > 0 {
            return .positive
        }
        return .neutral
    }

    private func majorPreview(for definition: ActivityDefinition, state: GameState) -> ConsequencePreview? {
        guard state.activities.yearlyCount >= 4 else { return nil }

        switch definition.category {
        case .viceRisk where state.activities.riskLoad >= 10:
            return ConsequencePreview(
                id: "activity-risk-\(state.player.age)-\(definition.id)",
                title: "The activity is starting to run ahead of you",
                detail: "What felt like relief is becoming a pattern the rest of the year will have to absorb.",
                domain: .activities,
                tone: .warning
            )
        case .romanceSex where state.relationships.hasPartner && state.relationships.partnerBond < 45:
            return ConsequencePreview(
                id: "activity-romance-\(state.player.age)-\(definition.id)",
                title: "Your romantic choices are starting to leave a mark",
                detail: "The relationship side of life is no longer treating this as harmless background behavior.",
                domain: .relationships,
                tone: .warning
            )
        default:
            return nil
        }
    }

    private func historyTags(for definition: ActivityDefinition) -> [HistoryDomainTag] {
        var tags: [HistoryDomainTag] = [.activities]
        switch definition.category {
        case .mindBody:
            tags.append(.health)
        case .social:
            tags.append(.relationships)
        case .leisure:
            tags.append(.progress)
        case .romanceSex:
            tags.append(contentsOf: [.relationships, .lifeEvent])
        case .viceRisk:
            tags.append(contentsOf: [.health, .finance])
        case .familyHome:
            tags.append(contentsOf: [.housing, .relationships])
        }
        return Array(Set(tags))
    }

    private static func generatedFriendName(seed: Int) -> String {
        let names = ["Maya", "Rico", "Leah", "Andre", "Naomi", "Eli", "Sasha", "Jules", "Ava", "Marcus"]
        return names[abs(seed) % names.count]
    }

    static let catalog: [ActivityDefinition] = [
        ActivityDefinition(
            id: "gym_session",
            title: "Hit The Gym",
            category: .mindBody,
            costLine: "$20 • energy • visible payoff",
            previewTags: ["Recovery", "Looks", "Discipline"],
            risk: .grounding,
            effects: ActivityEffects(happiness: 1, looks: 1, health: 1, cash: -20, physicalWellness: 4, mentalWellness: 1, stressManagement: 2, careerBurnout: -1, consequences: ["health": -2], identityTags: ["self_improvement": 1], recoveryBalance: 2)
        ),
        ActivityDefinition(
            id: "therapy_session",
            title: "Go To Therapy",
            category: .mindBody,
            costLine: "$90 • emotional labor • steadier floor",
            previewTags: ["Mental", "Stress", "Counterbalance"],
            risk: .grounding,
            minimumAge: 16,
            effects: ActivityEffects(happiness: 1, cash: -90, financialStress: 1, mentalWellness: 5, stressManagement: 4, careerBurnout: -2, consequences: ["health": -4, "relationships": -1], identityTags: ["grounded": 1], recoveryBalance: 3)
        ),
        ActivityDefinition(
            id: "journal_night",
            title: "Journal For A Night",
            category: .mindBody,
            costLine: "quiet evening • low cost • small relief",
            previewTags: ["Mental", "Cheap", "Routine"],
            risk: .easy,
            effects: ActivityEffects(happiness: 1, mentalWellness: 3, stressManagement: 2, engagement: 1, careerBurnout: -1, consequences: ["health": -1], identityTags: ["grounded": 1], recoveryBalance: 2)
        ),
        ActivityDefinition(
            id: "hang_with_friends",
            title: "Hang Out With Friends",
            category: .social,
            costLine: "$25 • time • softens isolation",
            previewTags: ["Belonging", "Bond", "Relief"],
            risk: .easy,
            requiresFriends: true,
            effects: ActivityEffects(happiness: 2, cash: -25, mentalWellness: 2, schoolBelonging: 3, careerBurnout: -1, friendBond: 4, consequences: ["relationships": -2], identityTags: ["social": 1], socialMomentum: 2)
        ),
        ActivityDefinition(
            id: "meet_new_people",
            title: "Meet New People",
            category: .social,
            costLine: "$15 • uncertain • maybe worth it",
            previewTags: ["Belonging", "Exposure", "Chance"],
            risk: .easy,
            effects: ActivityEffects(happiness: 1, looks: 1, cash: -15, schoolBelonging: 2, activityMomentum: 1, friendBond: 3, consequences: ["relationships": -1], identityTags: ["social": 1], socialMomentum: 2)
        ),
        ActivityDefinition(
            id: "community_event",
            title: "Go To A Community Event",
            category: .social,
            costLine: "$10 • low stakes • outside your bubble",
            previewTags: ["Routine", "Social", "Grounding"],
            risk: .grounding,
            effects: ActivityEffects(happiness: 1, cash: -10, mentalWellness: 2, schoolBelonging: 2, careerPerformance: 1, friendBond: 2, housingStability: 1, consequences: ["relationships": -1], identityTags: ["grounded": 1, "social": 1], socialMomentum: 1, recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "gaming_binge",
            title: "Lose A Night To Gaming",
            category: .leisure,
            costLine: "cheap • relief now • drift later",
            previewTags: ["Escape", "Cheap", "Time sink"],
            risk: .charged,
            effects: ActivityEffects(happiness: 2, smarts: 1, mentalWellness: 1, stressManagement: 1, engagement: -1, careerPerformance: -1, consequences: ["career": 1], identityTags: ["escapist": 1], recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "read_or_class",
            title: "Read Or Take A Small Class",
            category: .leisure,
            costLine: "$30 • focus • future-facing",
            previewTags: ["Smarts", "Career", "Routine"],
            risk: .grounding,
            effects: ActivityEffects(happiness: 1, smarts: 3, cash: -30, mentalWellness: 1, schoolStanding: 2, engagement: 2, careerPerformance: 2, consequences: ["career": -1], identityTags: ["self_improvement": 1], recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "weekend_trip",
            title: "Take A Weekend Trip",
            category: .leisure,
            costLine: "$180 • reset • not cheap",
            previewTags: ["Relief", "Spend", "Reset"],
            risk: .easy,
            minimumAge: 16,
            effects: ActivityEffects(happiness: 3, cash: -180, financialStress: 2, mentalWellness: 3, stressManagement: 2, careerBurnout: -2, consequences: ["finance": 2, "health": -1], identityTags: ["escapist": 1], recoveryBalance: 2)
        ),
        ActivityDefinition(
            id: "date_night",
            title: "Plan A Date Night",
            category: .romanceSex,
            costLine: "$70 • intimacy • shared attention",
            previewTags: ["Partner", "Bond", "Cost"],
            risk: .easy,
            minimumAge: 16,
            requiresPartner: true,
            effects: ActivityEffects(happiness: 2, cash: -70, mentalWellness: 1, partnerBond: 5, partnerCommitmentAlignment: 2, consequences: ["relationships": -3], identityTags: ["romantic": 1], socialMomentum: 1)
        ),
        ActivityDefinition(
            id: "look_for_date",
            title: "Put Yourself Out There",
            category: .romanceSex,
            costLine: "$40 • vulnerable • image heavy",
            previewTags: ["Looks", "Chance", "Exposure"],
            risk: .charged,
            minimumAge: 16,
            effects: ActivityEffects(happiness: 1, looks: 1, cash: -40, mentalWellness: 1, schoolBelonging: 1, consequences: ["relationships": 1], identityTags: ["romantic": 1], socialMomentum: 1, riskLoad: 1)
        ),
        ActivityDefinition(
            id: "hookup",
            title: "Go For A Hookup",
            category: .romanceSex,
            costLine: "immediate closeness • unstable aftertaste",
            previewTags: ["Desire", "Risk", "Aftermath"],
            risk: .dangerous,
            minimumAge: 18,
            effects: ActivityEffects(happiness: 2, looks: 1, mentalWellness: -1, stressManagement: -1, partnerBond: -5, consequences: ["relationships": 4, "health": 2], identityTags: ["romantic": 1, "escapist": 1], socialMomentum: 1, riskLoad: 3)
        ),
        ActivityDefinition(
            id: "drink_night",
            title: "Go Drinking",
            category: .viceRisk,
            costLine: "$45 • short relief • messy tomorrow",
            previewTags: ["Relief", "Vice", "Health bill"],
            risk: .dangerous,
            minimumAge: 21,
            effects: ActivityEffects(happiness: 2, health: -1, cash: -45, mentalWellness: 1, stressManagement: -2, careerPerformance: -1, careerBurnout: 1, crimeHeat: 1, consequences: ["health": 3, "career": 2], identityTags: ["escapist": 1, "indulgent": 1], riskLoad: 3)
        ),
        ActivityDefinition(
            id: "casino_trip",
            title: "Go To The Casino",
            category: .viceRisk,
            costLine: "cash swing • adrenaline • bad floor",
            previewTags: ["Money", "Chance", "Vice"],
            risk: .dangerous,
            minimumAge: 21,
            effects: ActivityEffects(happiness: 2, cash: -120, financialStress: 2, mentalWellness: 1, careerPerformance: -1, consequences: ["finance": 5], identityTags: ["escapist": 1, "indulgent": 1], riskLoad: 4)
        ),
        ActivityDefinition(
            id: "reckless_night",
            title: "Have A Reckless Night",
            category: .viceRisk,
            costLine: "$80 • chaos • possible fallout",
            previewTags: ["Impulse", "Heat", "Health"],
            risk: .dangerous,
            minimumAge: 18,
            effects: ActivityEffects(happiness: 3, health: -2, cash: -80, mentalWellness: -1, careerPerformance: -2, crimeHeat: 4, consequences: ["health": 4, "career": 3, "relationships": 2], identityTags: ["escapist": 1, "indulgent": 1], riskLoad: 5)
        ),
        ActivityDefinition(
            id: "visit_family",
            title: "Visit Family",
            category: .familyHome,
            costLine: "$20 • emotional weight • grounding",
            previewTags: ["Family", "History", "Support"],
            risk: .grounding,
            effects: ActivityEffects(happiness: 1, cash: -20, mentalWellness: 2, stressManagement: 2, housingStability: 1, consequences: ["relationships": -1], identityTags: ["domestic": 1], socialMomentum: 1, recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "art_collecting",
            title: "Art Collecting",
            category: .leisure,
            costLine: "$2,000 • status • long-term floor",
            previewTags: ["Status", "Mental floor", "Expensive"],
            risk: .grounding,
            minimumAge: 25,
            effects: ActivityEffects(happiness: 2, cash: -2000, mentalWellness: 4, stressManagement: 3, careerJobSecurity: 2, identityTags: ["connoisseur": 1], recoveryBalance: 2)
        ),
        ActivityDefinition(
            id: "high_end_racing",
            title: "High-End Racing",
            category: .viceRisk,
            costLine: "$8,000 • adrenaline • dangerous",
            previewTags: ["Adrenaline", "Status", "Lethal risk"],
            risk: .dangerous,
            minimumAge: 21,
            effects: ActivityEffects(happiness: 4, looks: 2, cash: -8000, mentalWellness: 1, stressManagement: -2, careerPerformance: 1, consequences: ["health": 8, "finance": 4], identityTags: ["indulgent": 1], riskLoad: 8)
        ),
        ActivityDefinition(
            id: "family_night_in",
            title: "Stay In With Family",
            category: .familyHome,
            costLine: "cheap • calming • less freedom",
            previewTags: ["Domestic", "Bond", "Routine"],
            risk: .grounding,
            minimumAge: 16,
            requiresPartner: true,
            effects: ActivityEffects(happiness: 1, mentalWellness: 2, stressManagement: 2, partnerBond: 4, consequences: ["relationships": -2, "health": -1], identityTags: ["domestic": 1], socialMomentum: 1, recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "deep_clean_home",
            title: "Deep Clean Your Place",
            category: .familyHome,
            costLine: "$10 • annoying • stabilizing",
            previewTags: ["Home", "Routine", "Control"],
            risk: .easy,
            effects: ActivityEffects(happiness: 1, cash: -10, mentalWellness: 1, stressManagement: 2, housingStability: 4, consequences: ["housing": -3], identityTags: ["domestic": 1], recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "childcare_day",
            title: "Take The Parenting Load",
            category: .familyHome,
            costLine: "energy • less freedom • more trust",
            previewTags: ["Family", "Responsibility", "Bond"],
            risk: .charged,
            requiresChildren: true,
            effects: ActivityEffects(happiness: 1, mentalWellness: -1, stressManagement: -1, careerBurnout: 1, partnerBond: 3, housingStability: 1, consequences: ["relationships": -1, "health": 1], identityTags: ["domestic": 1], socialMomentum: 1)
        )
    ]
}

