import Foundation

struct OriginTemplateDefinition: Equatable {
    var id: OriginTemplateID
    var title: String
    var summary: String
}

enum OriginCatalog {
    static let templates: [OriginTemplateDefinition] = [
        OriginTemplateDefinition(
            id: .stableHomeAverageMeans,
            title: "Stable Home",
            summary: "Average means, low pressure, modest support."
        ),
        OriginTemplateDefinition(
            id: .financialStrainToughenedEarly,
            title: "Financial Strain",
            summary: "Money is tight, and you've learned to watch the budget early."
        ),
        OriginTemplateDefinition(
            id: .academicPromise,
            title: "Academic Promise",
            summary: "You're sharp, and people expect you to capitalize on it."
        ),
        OriginTemplateDefinition(
            id: .socialMagnet,
            title: "Social Magnet",
            summary: "People like having you around, which opens its own kind of doors."
        ),
        OriginTemplateDefinition(
            id: .fragileHealthStart,
            title: "Fragile Health",
            summary: "Early setbacks taught you to notice your body sooner than most."
        ),
        OriginTemplateDefinition(
            id: .chaoticHomeSelfReliant,
            title: "Self-Reliant",
            summary: "Inconsistent support forced you to adapt and trust yourself."
        ),
        OriginTemplateDefinition(
            id: .luckyBreak,
            title: "Lucky Break",
            summary: "A few things went your way before life really opened up."
        ),
        OriginTemplateDefinition(
            id: .wealthyDynasty,
            title: "Wealthy Dynasty",
            summary: "Legacy, capital, and the pressure that comes with a name."
        ),
        OriginTemplateDefinition(
            id: .academicLegacy,
            title: "Academic Legacy",
            summary: "Born into a house of books and elite expectations."
        ),
        OriginTemplateDefinition(
            id: .ruralEscapist,
            title: "Rural Escapist",
            summary: "Low cost, low opportunity, but high grit and connection to nature."
        ),
        OriginTemplateDefinition(
            id: .techProdigy,
            title: "Tech Prodigy",
            summary: "High logic and technical skill, focused on early digital mastery."
        ),
        OriginTemplateDefinition(
            id: .artisticDrifter,
            title: "Artistic Drifter",
            summary: "Creative, restless, and largely untethered to financial stability."
        )
    ]

    static func definition(for templateID: OriginTemplateID) -> OriginTemplateDefinition {
        templates.first(where: { $0.id == templateID }) ?? templates[0]
    }
}

struct OriginSystem {
    private let traitSystem = TraitSystem()
    private let friendNames = ["Maya", "Jordan", "Riley", "Sam", "Taylor", "Casey", "Quinn", "Avery", "Parker", "Skyler"]

    func makePreview(mode: StartMode, templateID: OriginTemplateID?, narrativeArcSystem: NarrativeArcSystem = NarrativeArcSystem(), meta: MetaState, resilience: LifeResilience = .resilient) -> GameState {
        var state = GameState()
        state.resilience = resilience
        let usesDeterministicTemplateSeed = mode == .template && templateID != nil
        let resolvedTemplate = resolvedTemplateID(for: mode, templateID: templateID)
        let childhoodInfluences = makeChildhoodInfluences(for: resolvedTemplate, deterministic: usesDeterministicTemplateSeed)
        let profile = makeOriginProfile(mode: mode, templateID: resolvedTemplate, childhoodInfluences: childhoodInfluences)

        if mode == .custom {
            // In custom mode, we can further refine the profile or state if needed
            // Currently ContentView applies the name/region right before beginLife
        }

        applyTemplate(resolvedTemplate, to: &state, deterministic: usesDeterministicTemplateSeed)
        applyInfluences(childhoodInfluences, to: &state)
        applyMetaProgression(meta, to: &state)

        state.player.age = 14
        state.education.pathway = .student
        state.career.status = .student
        state.career.roleID = nil
        state.originProfile = profile
        state.syncResilienceToPlayer()
        state.openingSummary = openingSummary(for: profile, childhoodInfluences: childhoodInfluences)
        state.startupState = .choosingOrigin
        state.player.traits = usesDeterministicTemplateSeed
            ? deterministicInitialTraits(preferredTraits: profile.starterTraitBias)
            : traitSystem.generateInitialTraits(preferredTraits: profile.starterTraitBias)

        // Wire dossier generation here so the live "Your Character at 14" preview (and final state)
        // carries real CareerAptitude DNA + narrative hints. This is what makes childhood origin
        // mechanically matter for special career qualification, starting power, and "Echoes of What Could Be".
        let dossierEngine = ChildhoodGenerationEngine()
        state.childhoodDossier = dossierEngine.generate(
            templateID: resolvedTemplate,
            traits: state.player.traits,
            deterministic: usesDeterministicTemplateSeed
        )

        state.player.clampStats()
        state.education.clamp()
        state.healthProfile.clamp()
        state.housing.clamp()
        narrativeArcSystem.populatePreviewArcs(for: &state)
        return state
    }

    /// Re-generates the dossier for a preview state after a trait override (or other late tweak to traits/template).
    /// Keeps the live creation preview's "Starting Shape" and future-path hints in sync with player choices.
    func regenerateDossier(for state: inout GameState, templateID: OriginTemplateID, deterministic: Bool) {
        let dossierEngine = ChildhoodGenerationEngine()
        state.childhoodDossier = dossierEngine.generate(
            templateID: templateID,
            traits: state.player.traits,
            deterministic: deterministic
        )
    }

    private func resolvedTemplateID(for mode: StartMode, templateID: OriginTemplateID?) -> OriginTemplateID {
        if mode == .template, let templateID {
            return templateID
        }

        let weightedPool: [OriginTemplateID] = [
            .stableHomeAverageMeans, .stableHomeAverageMeans,
            .financialStrainToughenedEarly,
            .academicPromise,
            .socialMagnet,
            .fragileHealthStart,
            .chaoticHomeSelfReliant,
            .luckyBreak,
            .ruralEscapist,
            .techProdigy,
            .artisticDrifter
        ]
        return weightedPool.randomElement() ?? .stableHomeAverageMeans
    }

    private func makeOriginProfile(
        mode: StartMode,
        templateID: OriginTemplateID,
        childhoodInfluences: [String]
    ) -> OriginProfile {
        switch templateID {
        case .stableHomeAverageMeans:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "Low pressure, modest means",
                schoolStanding: "Steady student",
                socialSupport: "A couple dependable people",
                starterTraitBias: [.disciplined, .charismatic],
                startingCashBand: "$250-$900 cushion",
                focusTags: ["school", "routine"],
                openingEventSeed: ["school", "routine"],
                homeSummary: "Home is not luxurious, but it is stable enough that most of your stress comes from your own choices.",
                schoolSummary: "Teachers see you as steady, not brilliant or doomed, with room to drift upward.",
                selfSummary: "You start with a little structure, a little confidence, and no guarantee of anything bigger.",
                signalHighlights: ["Routine helps", "School steady", "Cash modest"]
            )
        case .financialStrainToughenedEarly:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "Money pressure at home",
                schoolStanding: "Holding on under strain",
                socialSupport: "Thin but real",
                starterTraitBias: [.disciplined, .anxious],
                startingCashBand: "$0-$250 cushion",
                focusTags: ["money", "career", "routine"],
                openingEventSeed: ["money", "cost"],
                homeSummary: "Money has been a recurring stressor, so comfort always feels conditional.",
                schoolSummary: "School matters, but it competes with real-life pressure and adult worries at home.",
                selfSummary: "You already know how to stretch a little, hold back a little, and notice when things feel unstable.",
                signalHighlights: ["Money tight", "Stress elevated", "Grit rising"]
            )
        case .academicPromise:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "Performance pressure",
                schoolStanding: "Top of the class orbit",
                socialSupport: "Respect more than closeness",
                starterTraitBias: [.disciplined, .anxious],
                startingCashBand: "$250-$700 cushion",
                focusTags: ["school", "career"],
                openingEventSeed: ["school", "career"],
                homeSummary: "The adults around you talk about potential often enough that it is starting to feel like a burden.",
                schoolSummary: "Your academic footing is strong, and people already expect you to capitalize on it.",
                selfSummary: "You begin sharp and capable, but not always relaxed.",
                signalHighlights: ["Smarts up", "Expectations high", "Future-focused"]
            )
        case .socialMagnet:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "Manageable background noise",
                schoolStanding: "Capable but distractible",
                socialSupport: "You rarely feel invisible",
                starterTraitBias: [.charismatic, .impulsive],
                startingCashBand: "$150-$700 cushion",
                focusTags: ["social", "romance"],
                openingEventSeed: ["social", "money"],
                homeSummary: "Home is not the main story of your life right now. People are.",
                schoolSummary: "You can do fine in class, but your energy often follows the room rather than the assignment.",
                selfSummary: "You start with social momentum, which can become leverage or noise depending on your choices.",
                signalHighlights: ["Friends nearby", "Charm high", "Focus mixed"]
            )
        case .fragileHealthStart:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "Health vigilance at home",
                schoolStanding: "Interrupted but resilient",
                socialSupport: "Selective support",
                starterTraitBias: [.disciplined, .anxious],
                startingCashBand: "$100-$500 cushion",
                focusTags: ["health", "routine"],
                openingEventSeed: ["health", "routine"],
                homeSummary: "Health has already shaped what normal feels like, so recovery and caution are part of your baseline.",
                schoolSummary: "You can keep up, but not always without effort or adjustment.",
                selfSummary: "You begin more aware of your limits, which can sharpen discipline if it does not become fear.",
                signalHighlights: ["Health guarded", "Habits matter", "Energy uneven"]
            )
        case .chaoticHomeSelfReliant:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "High volatility at home",
                schoolStanding: "Uneven but salvageable",
                socialSupport: "Mostly self-made",
                starterTraitBias: [.impulsive, .disciplined],
                startingCashBand: "$0-$300 cushion",
                focusTags: ["career", "risk", "money"],
                openingEventSeed: ["risk", "money"],
                homeSummary: "Home has been unpredictable enough that you trust yourself before you trust stability.",
                schoolSummary: "Your school footing is patchy, but you are not out of the fight.",
                selfSummary: "You start tougher and more self-directed than most, but carrying more static.",
                signalHighlights: ["Home unstable", "Self-reliant", "Pressure high"]
            )
        case .luckyBreak:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "Ordinary pressure, softened by luck",
                schoolStanding: "Promising with room",
                socialSupport: "One or two bright spots",
                starterTraitBias: [.lucky, .charismatic],
                startingCashBand: "$500-$1,400 cushion",
                focusTags: ["chance", "career", "social"],
                openingEventSeed: ["chance", "money"],
                homeSummary: "Not everything has been easy, but a few breaks landed in your favor before life really opened up.",
                schoolSummary: "You have enough footing to try things without feeling immediately trapped.",
                selfSummary: "You start with just enough wind at your back to think upward.",
                signalHighlights: ["Cash buffered", "Momentum good", "Luck live"]
            )
        case .wealthyDynasty:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "Non-existent",
                schoolStanding: "Expected excellence",
                socialSupport: "High-net-worth network",
                starterTraitBias: [.charismatic, .disciplined],
                startingCashBand: "$10,000-$25,000 headstart",
                focusTags: ["finance", "social"],
                openingEventSeed: ["money", "career"],
                homeSummary: "Your family name carries weight, and your bank account reflects it. Failure is an option, but it's expensive.",
                schoolSummary: "Private tutoring and high expectations. You're set up for a fast track if you stay focused.",
                selfSummary: "A massive financial advantage, but with social pressures that others don't have.",
                signalHighlights: ["Massive capital", "Network access", "High pressure"]
            )
        case .academicLegacy:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "High academic pressure",
                schoolStanding: "Elite standing",
                socialSupport: "Educated network",
                starterTraitBias: [.disciplined, .anxious],
                startingCashBand: "$800-$2,000",
                focusTags: ["school", "career"],
                openingEventSeed: ["school", "routine"],
                homeSummary: "Both your parents are professionals. The house is full of books and the expectation of a PhD.",
                schoolSummary: "You are already at the top of your class, but the burnout is already starting to flicker.",
                selfSummary: "Start with elite Smarts and standing, but a higher baseline of anxiety and burnout risk.",
                signalHighlights: ["Elite Smarts", "Standing high", "Burnout risk"]
            )
        case .ruralEscapist:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "Quiet expectations",
                schoolStanding: "Pragmatic learner",
                socialSupport: "Deep roots",
                starterTraitBias: [.disciplined, .lucky],
                startingCashBand: "$300-$1,000 cushion",
                focusTags: ["routine", "health"],
                openingEventSeed: ["routine", "health"],
                homeSummary: "Life moves slower where you're from. There's a connection to the land that most city people don't understand.",
                schoolSummary: "You're a practical student, more interested in things that work than things that are just theory.",
                selfSummary: "You start with a strong foundation and a perspective that values the tangible.",
                signalHighlights: ["Cost low", "Grit high", "Stable roots"]
            )
        case .techProdigy:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "Cognitive expectations",
                schoolStanding: "Highly specialized",
                socialSupport: "Digital-first circle",
                starterTraitBias: [.visionary, .anxious],
                startingCashBand: "$500-$1,500 cushion",
                focusTags: ["career", "routine"],
                openingEventSeed: ["career", "routine"],
                homeSummary: "You spent more time looking at screens than looking at the neighborhood. It's where you feel most capable.",
                schoolSummary: "You're light years ahead in technical subjects, but sometimes struggle with the social friction of high school.",
                selfSummary: "You start with a significant technical edge and a mind built for systems.",
                signalHighlights: ["Technical high", "Social friction", "Logic-focused"]
            )
        case .artisticDrifter:
            return OriginProfile(
                startMode: mode,
                templateID: templateID,
                householdPressure: "Low tether, low pressure",
                schoolStanding: "Non-conformist",
                socialSupport: "Found family",
                starterTraitBias: [.visionary, .impulsive],
                startingCashBand: "$100-$400 cushion",
                focusTags: ["social", "career"],
                openingEventSeed: ["social", "career"],
                homeSummary: "Structure was never the priority. Expression was. You've learned to value freedom over security.",
                schoolSummary: "You're often physically present in class, but your mind is usually working on a different project entirely.",
                selfSummary: "You start with a restless creative energy and very few traditional safety nets.",
                signalHighlights: ["Creativity high", "Stability low", "Restless"]
            )
        }
    }

    private func applyMetaProgression(_ meta: MetaState, to state: inout GameState) {
        // Generation Flags (Echoes from previous lives)
        if meta.generationFlags.contains("reached_retirement") {
            state.player.health += 5
            state.healthProfile.physicalWellness += 5
        }
        
        if meta.generationFlags.contains("wealthy_dynasty") {
            state.finance.cashOnHand += 1000
            state.relationships.socialCapital += 100
        }
        
        if meta.generationFlags.contains("academic_legend") {
            state.player.smarts += 5
            state.education.schoolStanding += 5
        }

        // P4: D4 life-shape + stance + focus scar meta progression (stronger effects on next-life start)
        if meta.generationFlags.contains("drifted_through_life") || meta.generationFlags.contains("left_loose_ends") {
            state.player.happiness += 4
            state.healthProfile.mentalWellness += 6
            state.education.credentialStrength = max(15, state.education.credentialStrength - 12)
            state.career.performance = max(20, state.career.performance - 5)
        }
        if meta.generationFlags.contains("lived_driven") || meta.generationFlags.contains("passed_on_the_drive") {
            state.player.smarts += 4
            state.career.performance += 10
            state.correlationLedger.publish(CorrelationSignal(kind: .focusStance, domain: "career", strength: 30, age: 14))
            state.education.credentialStrength = min(100, state.education.credentialStrength + 8)
        }
        if meta.generationFlags.contains("modeled_steady_care") {
            state.healthProfile.mentalWellness += 8
            state.relationships.socialCapital += 15
        }
        if meta.generationFlags.contains("stuck_in_a_rut_once") || meta.generationFlags.contains("scars_from_the_fast_lane") {
            state.healthProfile.mentalWellness = max(20, state.healthProfile.mentalWellness - 8)
            state.career.burnout += 10
        }
        if meta.generationFlags.contains("scars_of_the_strong") {
            state.player.smarts += 3
            state.correlationLedger.publish(CorrelationSignal(kind: .focusStance, domain: "health", strength: 20, age: 14))
        }
        
        // Legacy Point Upgrades (Example)
        if meta.legacyPoints > 0 {
             // Simple example: each legacy point gives $10 starting cash
             state.finance.cashOnHand += meta.legacyPoints * 10
        }
        
        state.player.clampStats()

        // P4: replay hooks - starting notes based on previous D4 shapes/scars so "one more life" feels different immediately
        if meta.generationFlags.contains("drifted_through_life") || meta.generationFlags.contains("left_loose_ends") {
            state.history.insert(HistoryEntry(age: 14, title: "Echo from Before", text: "You start this life already knowing what it feels like to let years slide. The comfort is familiar, the cost too.", tags: [.lifeEvent]), at: 0)
        }
        if meta.generationFlags.contains("lived_driven") || meta.generationFlags.contains("passed_on_the_drive") {
            state.history.insert(HistoryEntry(age: 14, title: "Echo from Before", text: "Something in you already expects the next year to be a grind worth winning. The shape feels familiar.", tags: [.lifeEvent]), at: 0)
        }
        if meta.generationFlags.contains("scars_from_the_fast_lane") || meta.generationFlags.contains("scars_of_the_strong") {
            state.history.insert(HistoryEntry(age: 14, title: "Echo from Before", text: "The last life left marks. You start with a little less margin and a little more hunger.", tags: [.lifeEvent]), at: 0)
        }

        // CT3-3: Diamond empire meta echoes (strong next-life advantages for having built institutions)
        if meta.generationFlags.contains("built_a_studio") || meta.generationFlags.contains("built_a_label_empire") {
            state.finance.cashOnHand += 8000
            state.specialCareer.audience += 15
            state.history.insert(HistoryEntry(age: 14, title: "Echo from Before", text: "You start this life with quiet money and an eye for what the world will pay to see. The last one left you the taste.", tags: [.lifeEvent]), at: 0)
        }
        if meta.generationFlags.contains("program_builder") || meta.generationFlags.contains("dynasty_builder") {
            state.player.smarts += 5
            state.relationships.socialCapital += 20
            state.history.insert(HistoryEntry(age: 14, title: "Echo from Before", text: "You start knowing how to build a room that wins. People already look at you like you belong on the sideline.", tags: [.lifeEvent]), at: 0)
        }
        if meta.generationFlags.contains("built_a_dark_empire") || meta.generationFlags.contains("washed_the_empire_clean") {
            state.finance.cashOnHand += 12000
            state.specialCareer.heat += 10 // the shadow follows
            state.history.insert(HistoryEntry(age: 14, title: "Echo from Before", text: "You start with doors that open in rooms most people don't know exist. The money is clean on paper. The history is not.", tags: [.lifeEvent]), at: 0)
        }
        if meta.generationFlags.contains("empire_builder") {
            state.correlationLedger.publish(CorrelationSignal(kind: .focusStance, domain: "career", strength: 25, age: 14))
        }
    }

    private func applyTemplate(_ templateID: OriginTemplateID, to state: inout GameState, deterministic: Bool) {
        switch templateID {
        case .stableHomeAverageMeans:
            state.player.happiness += 4
            state.player.smarts += 2
            state.education.schoolStanding += 4
            state.finance.cashOnHand = deterministic ? 575 : Int.random(in: 250...900)
            state.finance.financialStress = 16
            seedFriends(count: 1, bondRange: 54...67, into: &state.relationships, deterministic: deterministic)
            state.healthProfile.habits.exercise += 3
            state.healthProfile.habits.nutrition += 3
        case .financialStrainToughenedEarly:
            state.player.happiness -= 4
            state.player.smarts += 2
            state.education.attendancePressure += 8
            state.finance.cashOnHand = deterministic ? 125 : Int.random(in: 0...250)
            state.finance.financialStress = 28
            state.finance.lastYearBalanceDelta = -450
            state.healthProfile.mentalWellness -= 4
            seedFriends(count: 1, bondRange: 48...58, into: &state.relationships, deterministic: deterministic)
        case .academicPromise:
            state.player.smarts += 10
            state.player.happiness -= 1
            state.education.schoolStanding += 12
            state.education.engagement += 8
            state.career.performance += 8
            state.finance.cashOnHand = deterministic ? 475 : Int.random(in: 250...700)
            state.healthProfile.habits.stressManagement -= 3
        case .socialMagnet:
            state.player.happiness += 6
            state.player.looks += 5
            state.player.smarts -= 1
            state.education.engagement -= 3
            state.finance.cashOnHand = deterministic ? 425 : Int.random(in: 150...700)
            state.finance.financialStress = 20
            seedFriends(count: 2, bondRange: 56...72, into: &state.relationships, deterministic: deterministic)
        case .fragileHealthStart:
            state.player.health -= 8
            state.player.happiness -= 2
            state.education.attendancePressure += 5
            state.finance.cashOnHand = deterministic ? 300 : Int.random(in: 100...500)
            state.healthProfile.physicalWellness -= 10
            state.healthProfile.mentalWellness -= 3
            state.healthProfile.habits.exercise -= 4
            state.healthProfile.activeConditions.append(HealthCondition(name: "Recurring Fatigue", severity: 22))
        case .chaoticHomeSelfReliant:
            state.player.happiness -= 5
            state.player.smarts += 1
            state.education.schoolStanding -= 6
            state.housing.housingStability -= 12
            state.finance.cashOnHand = deterministic ? 150 : Int.random(in: 0...300)
            state.finance.financialStress = 30
            state.healthProfile.mentalWellness -= 5
            state.healthProfile.habits.stressManagement -= 4
            state.career.performance += 3
        case .luckyBreak:
            state.player.happiness += 5
            state.player.smarts += 2
            state.education.schoolStanding += 5
            state.finance.cashOnHand = deterministic ? 950 : Int.random(in: 500...1400)
            state.finance.financialStress = 12
            seedFriends(count: 1, bondRange: 55...68, into: &state.relationships, deterministic: deterministic)
            state.healthProfile.habits.stressManagement += 2
        case .wealthyDynasty:
            state.player.happiness += 12
            state.player.looks += 8
            state.player.smarts += 6
            state.finance.cashOnHand = deterministic ? 18000 : Int.random(in: 10000...25000)
            state.finance.financialStress = 5
            state.healthProfile.habits.nutrition += 10
            seedFriends(count: 3, bondRange: 60...80, into: &state.relationships, deterministic: deterministic)
        case .academicLegacy:
            state.player.smarts += 18
            state.education.schoolStanding += 20
            state.education.burnoutRisk += 15
            state.healthProfile.mentalWellness -= 10
            state.finance.cashOnHand = deterministic ? 1200 : Int.random(in: 800...2000)
            seedFriends(count: 1, bondRange: 50...65, into: &state.relationships, deterministic: deterministic)
        case .ruralEscapist:
            state.player.health += 5
            state.player.happiness += 2
            state.housing.housingStability += 15
            state.finance.cashOnHand = deterministic ? 650 : Int.random(in: 300...1000)
            state.healthProfile.habits.exercise += 5
        case .techProdigy:
            state.player.smarts += 12
            state.player.happiness -= 2
            state.education.schoolStanding += 8
            state.finance.cashOnHand = deterministic ? 1000 : Int.random(in: 500...1500)
            state.healthProfile.habits.stressManagement -= 4
        case .artisticDrifter:
            state.player.happiness += 8
            state.player.looks += 3
            state.housing.housingStability -= 10
            state.finance.cashOnHand = deterministic ? 250 : Int.random(in: 100...400)
            state.healthProfile.mentalWellness += 5
        }
    }

    private func makeChildhoodInfluences(for templateID: OriginTemplateID, deterministic: Bool = false) -> [String] {
        let common = [
            "You learned early that routine can either save a week or ruin it.",
            "A few small setbacks made consequences feel real before adulthood did.",
            "You picked up habits from the people around you, for better and worse.",
            "By middle school, you already had a sense of what kind of pressure you fold under."
        ]

        let themed: [String]
        switch templateID {
        case .stableHomeAverageMeans:
            themed = [
                "There was usually enough structure at home to keep life from slipping.",
                "You were encouraged to be responsible, even when nobody made a big speech about it."
            ]
        case .financialStrainToughenedEarly:
            themed = [
                "Money has been a recurring stressor, so comfort always feels conditional.",
                "School matters, but it competes with real-life pressure and adult worries at home."
            ]
        case .academicPromise:
            themed = [
                "The adults around you talk about potential often enough that it is starting to feel like a burden.",
                "Your academic footing is strong, and people already expect you to capitalize on it."
            ]
        case .socialMagnet:
            themed = [
                "Home is not the main story of your life right now. People are.",
                "You can do fine in class, but your energy often follows the room rather than the assignment."
            ]
        case .fragileHealthStart:
            themed = [
                "Health has already shaped what normal feels like, so recovery and caution are part of your baseline.",
                "Rest stopped feeling optional a long time ago."
            ]
        case .chaoticHomeSelfReliant:
            themed = [
                "Inconsistent support forced you to adapt faster than you should have needed to.",
                "You got used to managing your own emotions when home felt noisy."
            ]
        case .luckyBreak:
            themed = [
                "A couple of unexpected breaks kept your confidence alive.",
                "When life could have pinned you down, something small often went your way."
            ]
        case .wealthyDynasty:
            themed = [
                "You saw early how money can make some problems simply disappear.",
                "High expectations were the tax on a very comfortable upbringing."
            ]
        case .academicLegacy:
            themed = [
                "The house was full of books and the assumption that you would read them all.",
                "Standardized tests weren't a challenge; they were a baseline."
            ]
        case .ruralEscapist:
            themed = [
                "Life moves slower where you're from. There's a connection to the land that most city people don't understand.",
                "You're a practical student, more interested in things that work than things that are just theory."
            ]
        case .techProdigy:
            themed = [
                "You spent more time looking at screens than looking at the neighborhood. It's where you feel most capable.",
                "You're light years ahead in technical subjects, but sometimes struggle with the social friction of high school."
            ]
        case .artisticDrifter:
            themed = [
                "Structure was never the priority. Expression was. You've learned to value freedom over security.",
                "You're often physically present in class, but your mind is usually working on a different project entirely."
            ]
        }

        let influences = common + themed
        if deterministic {
            return Array(influences.prefix(4))
        }
        return Array(influences.shuffled().prefix(Int.random(in: 3...5)))
    }

    private func applyInfluences(_ influences: [String], to state: inout GameState) {
        for influence in influences {
            if influence.contains("routine") {
                state.healthProfile.habits.stressManagement += 1
                state.career.performance += 1
            }
            if influence.contains("money") || influence.contains("dollar") {
                state.finance.financialStress += 2
            }
            if influence.contains("grades") || influence.contains("performed") {
                state.player.smarts += 1
            }
            if influence.contains("people") || influence.contains("belonging") {
                state.player.happiness += 1
            }
            if influence.contains("body") || influence.contains("Rest") {
                state.healthProfile.habits.exercise += 1
                state.healthProfile.habits.nutrition += 1
            }
            if influence.contains("adapt") || influence.contains("manage") {
                state.player.happiness -= 1
                state.player.smarts += 1
            }
        }
    }

    private func seedFriends(count: Int, bondRange: ClosedRange<Int>, into relationships: inout RelationshipState, deterministic: Bool = false) {
        let names = deterministic ? Array(friendNames.prefix(count)) : Array(friendNames.shuffled().prefix(count))
        for name in names {
            let bond = deterministic ? ((bondRange.lowerBound + bondRange.upperBound) / 2) : Int.random(in: bondRange)
            relationships.friends.append(Relationship(name: name, type: .friend, bond: bond))
        }
    }

    private func deterministicInitialTraits(preferredTraits: [PersonalityTrait], count: Int = 3) -> [PersonalityTrait] {
        var ordered = preferredTraits
        for trait in PersonalityTrait.allCases where !ordered.contains(trait) {
            ordered.append(trait)
        }
        return Array(ordered.prefix(min(count, PersonalityTrait.allCases.count)))
    }

    private func openingSummary(for profile: OriginProfile, childhoodInfluences: [String]) -> String {
        guard let templateID = profile.templateID else {
            // Quick start — use a generic present-tense vignette
            let vignettes = [
                "You're 14 and you already know more about how the world actually works than adults think you do. The rest is up to you.",
                "Summer before ninth grade. The future feels very far away and also like it starts tomorrow.",
                "You've watched enough people around you make decisions to know what some of the wrong ones look like. Doesn't mean you won't make them.",
            ]
            return vignettes.randomElement() ?? vignettes[0]
        }
        return templateVignette(for: templateID)
    }

    private func templateVignette(for templateID: OriginTemplateID) -> String {
        switch templateID {
        case .stableHomeAverageMeans:
            let lines = [
                "Your bedroom is the same bedroom it's always been. Same posters, same carpet, same water stain near the window your parents keep saying they'll fix. It's fine. Everything here is fine. You've started wondering if fine is enough.",
                "Dinner is at the same time every night. Your mom asks about school. Your dad watches the news after. Nothing is wrong. You keep waiting for something to be wrong, and it never is, and you're not sure what to do with that.",
                "The house is quiet in a good way. You have your own room. You have enough. You've started to notice that 'enough' is its own kind of pressure.",
            ]
            return lines.randomElement() ?? lines[0]

        case .financialStrainToughenedEarly:
            let lines = [
                "Your mom does the bills at the kitchen table on the first of the month. You learned what that look on her face means when you were nine. You don't ask about it. She doesn't explain it. You both just know.",
                "The heat works but only barely. You've gotten good at layering. You've also gotten good at not mentioning things that cost money — not because anyone told you to, but because you watched and learned.",
                "You've counted the cash in your room three times this week. $47. It's not enough for what you need, but it's yours. That part matters.",
            ]
            return lines.randomElement() ?? lines[0]

        case .academicPromise:
            let lines = [
                "Your teacher pulled you aside last week to talk about your 'potential.' Everyone keeps using that word. You smiled and said thank you. You didn't say that potential feels like a debt you didn't ask for.",
                "The honor roll certificate is on the fridge. It's been on the fridge so long the edges are curling. Adults bring it up at family dinners. You've learned to nod.",
                "You're good at school. You've always been good at school. The part nobody talks about is what happens when the thing you're good at starts to feel like a cage.",
            ]
            return lines.randomElement() ?? lines[0]

        case .socialMagnet:
            let lines = [
                "Your phone buzzes before you're even out of bed. Someone wants to know what you're doing. Three other people want to know if you're coming. You don't always like everyone who wants to be around you. But you like being wanted.",
                "Lunch is wherever you decide to sit, which means a lot of people are always watching to see where that is. You've gotten used to it. You're not sure that's a good thing.",
                "People tell you things. Secrets, plans, feelings — they just come out around you. You listen. You store it all. You've never figured out what to do with how much you know about everyone.",
            ]
            return lines.randomElement() ?? lines[0]

        case .fragileHealthStart:
            let lines = [
                "You've spent more time in waiting rooms than most kids your age. You know the smell of hospitals. You know which nurses are kind and which ones are just efficient. Your body has been the main character in your life more than you'd like.",
                "There's a pill organizer on your nightstand. It's been there so long it's just furniture now. You don't think about it unless someone else notices it and gets that look.",
                "You know your limits in a way other 14-year-olds don't. You also know how to push past them carefully. That's not nothing. But it costs something too.",
            ]
            return lines.randomElement() ?? lines[0]

        case .chaoticHomeSelfReliant:
            let lines = [
                "You learned early that plans change without warning. The electricity, the address, the rules — all of it subject to revision. So you keep a version of yourself that doesn't depend on anything staying the same.",
                "Some nights are fine. Some nights you're eating cereal at 9pm because nobody's home and there's nothing else. You stopped being upset about it a while back. Now it's just logistics.",
                "You've been making your own decisions longer than most kids your age. Not because anyone gave you permission — just because you had to. You're good at it. You're also tired of it.",
            ]
            return lines.randomElement() ?? lines[0]

        case .luckyBreak:
            let lines = [
                "The car you wanted? You got it. The concert tickets that sold out? You found a pair. Life isn't perfect, but it sure is helpful. You've started wondering when the bill comes due.",
                "Things just work out. Not because you're special, but because that's the pattern. You walk through the world with a confidence that others have to earn.",
                "You've never really been truly stuck. There's always been a way out, a side door, a lucky break. It makes the world feel like a playground.",
            ]
            return lines.randomElement() ?? lines[0]
        case .wealthyDynasty:
            let lines = [
                "The house has more rooms than people. The quiet is expensive. You've never seen your parents talk about money, only about legacy. It's a weight you were born carrying.",
                "Your last name is on the side of a building downtown. People treat you differently because of it — some with respect, some with a distance you can't bridge.",
                "Everything is provided for. Everything. The only thing you can't buy is the feeling that you've earned any of it yourself.",
            ]
            return lines.randomElement() ?? lines[0]
        case .academicLegacy:
            let lines = [
                "Dinner conversations are about research papers and university politics. Both your parents have doctorates. You've known your GPA to three decimal places since you were twelve.",
                "The expectation is not just that you go to a good school, but that you go to *the* school. Anything less is a quiet, polite tragedy.",
                "You're brilliant. Everyone says so. But sometimes you look at a textbook and just want to throw it out the window and walk until you're someone else.",
            ]
            return lines.randomElement() ?? lines[0]
        case .ruralEscapist:
            let lines = [
                "The horizon is always where it should be—clear and open. You know every path in the woods behind your house. The city feels like a story someone else is telling.",
                "You helped fix the fence before school. The air was cold and smelled like wet dirt and old wood. You liked it. You're not sure you'd like an office nearly as much.",
                "Your parents don't talk about 'careers.' They talk about seasons and repairs and what needs doing today. It makes the world feel solid in a way your books don't.",
            ]
            return lines.randomElement() ?? lines[0]
        case .techProdigy:
            let lines = [
                "The blue light from your monitor is usually the last thing you see before you sleep. You've built systems that actually work, unlike the social hierarchy at school.",
                "Your parents don't understand what you do, but they like that you're quiet and occupied. They don't know you've already found three ways to bypass their router limits.",
                "Algorithms make sense. People don't. You've spent more time in forums and documentation than you have in the cafeteria, and you're fine with that.",
            ]
            return lines.randomElement() ?? lines[0]
        case .artisticDrifter:
            let lines = [
                "Your notebooks are full of sketches and lyrics, but your homework remains empty. You're not lazy; you're just occupied with things that actually matter.",
                "The house feels too small, the town feels too quiet, and the rules feel like someone else's mistake. You're just waiting for the day you can start moving.",
                "You've already started a band, a magazine, and a protest. None of them lasted more than a month, but they all felt more real than your history class.",
            ]
            return lines.randomElement() ?? lines[0]
        }
    }
}
