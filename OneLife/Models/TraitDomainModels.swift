import Foundation

// MARK: - Trait Domain

enum PersonalityTrait: String, Codable, CaseIterable, Identifiable {
    case disciplined
    case impulsive
    case charismatic
    case anxious
    case lucky
    
    // Mutated Traits
    case manipulative
    case coldBlooded
    case visionary
    case burnoutProne
    case workaholic
    case resilient
    case unreliable
    case ptsd

    var id: String { rawValue }
}


struct TraitProfile: Equatable {
    var name: String
    var summary: String
    var yearlyDrift: CoreStatDelta
    var yearlyFinanceDrift: FinanceDelta
    var eventTagWeights: [String: Int]
    var eventTagOutcomes: [String: CoreStatDelta]
    var eventTagFinanceOutcomes: [String: FinanceDelta]
}

enum TraitCatalog {
    static func profile(for trait: PersonalityTrait) -> TraitProfile {
        switch trait {
        case .disciplined:
            return TraitProfile(
                name: "Disciplined",
                summary: "Steady and self-controlled, with an edge in school, work, and healthy routines.",
                yearlyDrift: CoreStatDelta(happiness: 0, smarts: 1, looks: 0, health: 1),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["school": 5, "career": 6, "health": 4, "routine": 4],
                eventTagOutcomes: [
                    "school": CoreStatDelta(smarts: 2),
                    "career": CoreStatDelta(smarts: 1),
                    "health": CoreStatDelta(health: 2)
                ],
                eventTagFinanceOutcomes: [
                    "career": FinanceDelta(cash: 150)
                ]
            )
        case .impulsive:
            return TraitProfile(
                name: "Impulsive",
                summary: "Quick to act, making risky or social years feel more tempting and swingy.",
                yearlyDrift: CoreStatDelta(happiness: 1, smarts: -1, looks: 0, health: -1),
                yearlyFinanceDrift: FinanceDelta(cash: -50),
                eventTagWeights: ["risk": 7, "social": 4, "spend": 6, "romance": 3],
                eventTagOutcomes: [
                    "risk": CoreStatDelta(happiness: 2, health: -2),
                    "spend": CoreStatDelta(happiness: 1),
                    "social": CoreStatDelta(happiness: 1)
                ],
                eventTagFinanceOutcomes: [
                    "risk": FinanceDelta(cash: -100),
                    "spend": FinanceDelta(cash: -150)
                ]
            )
        case .charismatic:
            return TraitProfile(
                name: "Charismatic",
                summary: "Socially magnetic, with better momentum in relationships and public-facing opportunities.",
                yearlyDrift: CoreStatDelta(happiness: 1, smarts: 0, looks: 1, health: 0),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["social": 6, "romance": 7, "career": 3],
                eventTagOutcomes: [
                    "social": CoreStatDelta(happiness: 2),
                    "romance": CoreStatDelta(happiness: 2, looks: 1),
                    "career": CoreStatDelta()
                ],
                eventTagFinanceOutcomes: [
                    "career": FinanceDelta(cash: 100)
                ]
            )
        case .anxious:
            return TraitProfile(
                name: "Anxious",
                summary: "Cautious and tense, leaning away from risky situations and carrying more mental strain.",
                yearlyDrift: CoreStatDelta(happiness: -1, smarts: 1, looks: 0, health: -1),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["risk": -8, "health": 4, "school": 3],
                eventTagOutcomes: [
                    "risk": CoreStatDelta(happiness: -2, health: -1),
                    "health": CoreStatDelta(smarts: 1),
                    "school": CoreStatDelta(smarts: 1)
                ],
                eventTagFinanceOutcomes: [:]
            )
        case .lucky:
            return TraitProfile(
                name: "Lucky",
                summary: "Things tend to break your way just often enough to nudge long-term outcomes upward.",
                yearlyDrift: CoreStatDelta(happiness: 1, smarts: 0, looks: 0, health: 0),
                yearlyFinanceDrift: FinanceDelta(cash: 75),
                eventTagWeights: ["chance": 10, "career": 2, "money": 4],
                eventTagOutcomes: [
                    "chance": CoreStatDelta(happiness: 2),
                    "money": CoreStatDelta(),
                    "career": CoreStatDelta()
                ],
                eventTagFinanceOutcomes: [
                    "chance": FinanceDelta(cash: 250),
                    "money": FinanceDelta(cash: 150),
                    "career": FinanceDelta(cash: 100)
                ]
            )
        case .manipulative:
            return TraitProfile(
                name: "Manipulative",
                summary: "You see people as leverage. Bonds are harder to form, but social capital builds faster.",
                yearlyDrift: CoreStatDelta(happiness: -1),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["social": 8, "risk": 5],
                eventTagOutcomes: ["social": CoreStatDelta(smarts: 1)],
                eventTagFinanceOutcomes: [:]
            )
        case .coldBlooded:
            return TraitProfile(
                name: "Cold-Blooded",
                summary: "Volatility doesn't shake you. Immune to financial stress effects, but isolated from deep connections.",
                yearlyDrift: CoreStatDelta(happiness: -2),
                yearlyFinanceDrift: FinanceDelta(cash: 200),
                eventTagWeights: ["money": 10, "risk": 7],
                eventTagOutcomes: ["money": CoreStatDelta(smarts: 2)],
                eventTagFinanceOutcomes: ["money": FinanceDelta(cash: 500)]
            )
        case .visionary:
            return TraitProfile(
                name: "Visionary",
                summary: "You see the horizon. Massive growth in valuation and standing, but your mind is never at rest.",
                yearlyDrift: CoreStatDelta(happiness: -1, smarts: 2),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["career": 12, "routine": 5],
                eventTagOutcomes: ["career": CoreStatDelta(smarts: 3)],
                eventTagFinanceOutcomes: [:]
            )
        case .burnoutProne:
            return TraitProfile(
                name: "Burnout Prone",
                summary: "High energy but low durability. You move fast until you stop completely.",
                yearlyDrift: CoreStatDelta(health: -2),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["routine": 8, "health": 10],
                eventTagOutcomes: ["routine": CoreStatDelta(health: -3)],
                eventTagFinanceOutcomes: [:]
            )
        case .workaholic:
            return TraitProfile(
                name: "Workaholic",
                summary: "Your career is your identity. High performance and income, but personal life is a ghost town.",
                yearlyDrift: CoreStatDelta(happiness: -2),
                yearlyFinanceDrift: FinanceDelta(cash: 400),
                eventTagWeights: ["career": 15, "social": -5],
                eventTagOutcomes: ["career": CoreStatDelta(smarts: 2)],
                eventTagFinanceOutcomes: ["career": FinanceDelta(cash: 1000)]
            )
        case .resilient:
            return TraitProfile(
                name: "Resilient",
                summary: "You can take a hit. Drastically reduced impacts from stress and setbacks.",
                yearlyDrift: CoreStatDelta(health: 1),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["risk": 8, "health": 5],
                eventTagOutcomes: ["risk": CoreStatDelta(happiness: 1)],
                eventTagFinanceOutcomes: [:]
            )
        case .unreliable:
            return TraitProfile(
                name: "Unreliable",
                summary: "Commitment is hard. High risk of losing stability, but life is less stressful.",
                yearlyDrift: CoreStatDelta(happiness: 1),
                yearlyFinanceDrift: FinanceDelta(cash: -200),
                eventTagWeights: ["routine": -10, "social": 5],
                eventTagOutcomes: ["career": CoreStatDelta(smarts: -1)],
                eventTagFinanceOutcomes: [:]
            )
        case .ptsd:
            return TraitProfile(
                name: "PTSD",
                summary: "The trauma stays with you. Constant drain on happiness and mental wellness.",
                yearlyDrift: CoreStatDelta(happiness: -3, health: -1),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["risk": 15, "health": 10],
                eventTagOutcomes: ["health": CoreStatDelta(happiness: -2)],
                eventTagFinanceOutcomes: [:]
            )
        }
    }
}

struct TraitSystem {
    func processMutations(player: inout Player, state: GameState) -> [DomainNote] {
        var notes: [DomainNote] = []
        let specialCareer = state.specialCareer
        let career = state.career
        let military = state.military
        let finance = state.finance
        
        // Shadow Operative -> Manipulative
        if specialCareer.track == .shadowOperative, specialCareer.yearsActive >= 8, player.traits.contains(.charismatic), !player.traits.contains(.manipulative) {
            mutate(from: .charismatic, to: .manipulative, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "Years of leverage and secrets have changed how you see people. Your charm has hardened into something more calculated.", tags: [.progress, .lifeEvent]))
        }
        
        // Trader -> Cold-Blooded
        if specialCareer.track == .trader, specialCareer.notoriety >= 60, player.traits.contains(.anxious), !player.traits.contains(.coldBlooded) {
            mutate(from: .anxious, to: .coldBlooded, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "The market's volatility no longer shakes you. You've traded your anxiety for a clinical, cold-blooded perspective on risk.", tags: [.progress, .lifeEvent]))
        }
        
        // Founder -> Visionary
        if specialCareer.track == .founder, specialCareer.audience >= 50, player.traits.contains(.disciplined), !player.traits.contains(.visionary) {
            mutate(from: .disciplined, to: .visionary, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "Building something from nothing has expanded your horizon. You no longer just follow a routine; you see the future.", tags: [.progress, .lifeEvent]))
        }
        
        // Career -> Workaholic
        if career.burnout >= 80, career.performance >= 80, !player.traits.contains(.workaholic) {
            mutate(to: .workaholic, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "You've crossed a line. Work isn't what you do; it's who you are. You are now a Workaholic.", tags: [.progress, .lifeEvent]))
        }
        
        // Combat -> PTSD or Resilient
        if military.combatTrauma >= 50, !player.traits.contains(.ptsd) {
            mutate(to: .ptsd, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "The sounds and sights of the front lines have left a permanent mark on your mind.", tags: [.progress, .lifeEvent, .health]))
        } else if military.yearsServed >= 8, military.discipline >= 85, !player.traits.contains(.resilient) {
            mutate(to: .resilient, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "Years of service and strict discipline have forged you into someone who doesn't break under pressure.", tags: [.progress, .lifeEvent]))
        }
        
        // AWOL/Debt -> Unreliable
        if (military.isAWOL || finance.debtDelinquencyRisk >= 80), !player.traits.contains(.unreliable) {
            mutate(to: .unreliable, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "A pattern of running from obligations has hardened. People no longer expect you to show up when it matters.", tags: [.progress, .lifeEvent]))
        }

        return notes
    }
    
    private func mutate(from: PersonalityTrait? = nil, to: PersonalityTrait, on player: inout Player) {
        if let from = from, let index = player.traits.firstIndex(of: from) {
            player.traits[index] = to
        } else if !player.traits.contains(to) {
            if player.traits.count >= 3 {
                player.traits.removeFirst()
            }
            player.traits.append(to)
        }
    }

    func generateInitialTraits(count: Int = 3, preferredTraits: [PersonalityTrait] = []) -> [PersonalityTrait] {
        var weightedPool: [PersonalityTrait] = PersonalityTrait.allCases
        for trait in preferredTraits {
            weightedPool.append(contentsOf: Array(repeating: trait, count: 3))
        }

        var chosen: [PersonalityTrait] = []
        while chosen.count < min(count, PersonalityTrait.allCases.count), !weightedPool.isEmpty {
            guard let pick = weightedPool.randomElement() else { break }
            if !chosen.contains(pick) {
                chosen.append(pick)
            }
            weightedPool.removeAll { $0 == pick }
        }

        return chosen
    }

    func ensureInitialTraits(on player: inout Player, preferredTraits: [PersonalityTrait] = []) -> [DomainNote] {
        guard player.traits.isEmpty else { return [] }
        player.traits = generateInitialTraits(preferredTraits: preferredTraits)
        let names = player.traits.map { TraitCatalog.profile(for: $0).name }.joined(separator: ", ")
        return [DomainNote(title: "Personality", text: "Your early personality starts taking shape: \(names).")]
    }

    func applyYearlyInfluence(to player: inout Player, finance: inout FinanceState) -> DomainYearResult {
        for trait in player.traits {
            let profile = TraitCatalog.profile(for: trait)
            apply(profile.yearlyDrift, to: &player)
            apply(profile.yearlyFinanceDrift, to: &finance)
        }

        player.clampStats()
        return DomainYearResult()
    }

    func adjustedWeight(for event: GameEvent, player: Player) -> Int {
        let modifier = player.traits.reduce(0) { partial, trait in
            let profile = TraitCatalog.profile(for: trait)
            let tagBonus = event.tags.reduce(0) { $0 + (profile.eventTagWeights[$1] ?? 0) }
            return partial + tagBonus
        }

        return max(1, event.weight + modifier)
    }

    func applyEventOutcomeInfluence(for event: GameEvent, player: inout Player, finance: inout FinanceState) {
        for trait in player.traits {
            let profile = TraitCatalog.profile(for: trait)
            for tag in event.tags {
                if let delta = profile.eventTagOutcomes[tag] {
                    apply(delta, to: &player)
                }
                if let financeDelta = profile.eventTagFinanceOutcomes[tag] {
                    apply(financeDelta, to: &finance)
                }
            }
        }

        player.clampStats()
    }

    private func apply(_ delta: CoreStatDelta, to player: inout Player) {
        player.happiness += delta.happiness
        player.smarts += delta.smarts
        player.looks += delta.looks
        player.health += delta.health
    }

    private func apply(_ delta: FinanceDelta, to finance: inout FinanceState) {
        finance.cashOnHand += delta.cash
    }
}

