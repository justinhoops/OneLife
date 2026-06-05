import Foundation

// MARK: - SilentYearEngine
//
// Codex IX, Layer 3: The Weight of Nothing.
//
// When EventEngine.pickEvent returns nil, the year doesn't disappear silently.
// SilentYearEngine generates a single journal line that captures the texture
// of a quiet year — the grind, the plateau, the loneliness, the rare peace.
//
// These notes are added to GameState.history as HistoryEntry with the .lifeEvent tag.
// Silence is not a fallback. It is a feature.

struct SilentYearEngine {

    private let resolver = NarrativeToneResolver()

    /// Generate a HistoryEntry for a year where no event fired.
    /// Returns nil only if the player is dead or game is over.
    func silentYearEntry(for state: GameState) -> HistoryEntry? {
        guard !state.isGameOver else { return nil }

        let tone = resolver.resolve(for: state)
        let age  = state.player.age
        let note = pickNote(tone: tone, state: state)

        return HistoryEntry(
            age: age,
            title: "Age \(age)",
            text: note,
            tags: [.lifeEvent]
        )
    }

    // MARK: - Note Selection

    private func pickNote(tone: NarrativeTone, state: GameState) -> String {
        let pool = notePool(for: tone, state: state)
        var baseNote = pool.randomElement() ?? "Another year passed."

        // Engine2 + cross-engine: quiet years feel recent instant + autonomous (world/NPC) activity
        let heat = state.correlationLedger.recentActivityLevel
        let momentum = state.instantMomentum.overallStrength
        let recentAutonomy = state.correlationLedger.recentSignals(kind: .npcAutonomyPulse, minStrength: 5).count +
                             state.correlationLedger.recentSignals(kind: .worldAutonomyPulse, minStrength: 5).count

        // D4: stance + focus history in silent years (focus chains)
        let lastStance = state.yearlyStance.lastCompletedStance
        let recentFocus = state.correlationLedger.recentSignals(kind: .focusStance, minStrength: 10).count

        if heat >= 55 && momentum < 20 {
            if tone == .burnedOut || tone == .grinding || tone == .cornered {
                baseNote += " The last stretch of focused moves is still sitting in your body."
            } else if tone == .isolated {
                baseNote += " All that recent intensity made the quiet feel heavier."
            } else {
                baseNote += " Recent choices are still echoing, even in the stillness."
            }
        } else if heat >= 35 && momentum >= 30 {
            baseNote += " The momentum from before is still carrying a little."
        }

        if recentAutonomy > 0 {
            baseNote += " The world didn't pause just because you did."
        }

        // D4 focus residue
        if let s = lastStance, recentFocus > 0 {
            switch s {
            case .pushCareer:
                baseNote += " The career push from before left its mark on the quiet."
            case .letYearDrift:
                baseNote += " The drift still lingers; the quiet feels earned and a little empty."
            case .protectHealth:
                baseNote += " Taking care of the body paid quiet dividends here."
            default:
                if recentFocus >= 2 {
                    baseNote += " The shape of what you focused on (or avoided) is still audible."
                }
            }
        }

        // D4: ambient life-shape tracker (tallied from recent stances + automation signals, surfaces in quiet years)
        let shape = deriveLifeShape(state: state)
        if !shape.isEmpty {
            baseNote += " (\(shape))"
        }

        // P1 content injection: more D4/stance/era aware quiet year flavor for variety (lightweight storylets)
        if let last = state.yearlyStance.lastCompletedStance {
            switch last {
            case .pushCareer:
                if Int.random(in: 0...100) < 25 { baseNote += " The drive from your career focus still echoes in how opportunities (or their absence) present themselves." }
            case .protectHealth:
                if Int.random(in: 0...100) < 25 { baseNote += " Protecting the body paid off in small, invisible ways this quiet stretch." }
            case .letYearDrift:
                if Int.random(in: 0...100) < 30 { baseNote += " The looseness you allowed is still coloring what the world bothers to bring to your door." }
            case .stabilizeMoney:
                if Int.random(in: 0...100) < 25 { baseNote += " The money discipline you practiced makes the quiet feel less precarious than it used to." }
            default:
                if Int.random(in: 0...100) < 15 { baseNote += " Your focus pattern is quietly rewriting the texture of uneventful years." }
            }
        }
        if state.correlationLedger.recentActivityLevel < 20 && shape.contains("loose") {
            baseNote += " The shape feels diffuse; the year didn't push back much."
        }

        // P5-1: Edge flavor for long lives (80+) and extremes (high notoriety/fame/heat, zero kids, very low wealth)
        if state.player.age >= 80 {
            if Int.random(in: 0...100) < 18 {
                baseNote += " At this age the quiet is no longer empty — it is the sound of everything that came before."
            }
        }
        if state.fame.notoriety >= 65 || state.crime.heat >= 60 {
            if Int.random(in: 0...100) < 12 {
                baseNote += " Even in stillness, the name (or the heat) travels ahead of you."
            }
        }
        if state.family.children.isEmpty && state.player.age >= 50 {
            if Int.random(in: 0...100) < 10 {
                baseNote += " The house is quiet in a different way. The future will not carry your name the same way."
            }
        }
        if state.finance.cashOnHand < 0 && state.player.age >= 45 {
            if Int.random(in: 0...100) < 10 {
                baseNote += " The margin is gone. The quiet years now carry the weight of every choice that spent it."
            }
        }

        return baseNote
    }
    }

    private func notePool(for tone: NarrativeTone, state: GameState) -> [String] {
        switch tone {

        case .cornered:
            return corneredNotes(state)

        case .grinding:
            return grindingNotes(state)

        case .burnedOut:
            return burnedOutNotes(state)

        case .isolated:
            return isolatedNotes(state)

        case .holding:
            return holdingNotes(state)

        case .hopeful:
            return hopefulNotes(state)

        case .clear:
            return clearNotes(state)
        }
    }

    // MARK: - Note Pools by Tone

    private func corneredNotes(_ state: GameState) -> [String] {
        [
            "Everything needed attention at once. Nothing got enough.",
            "You kept moving. Barely.",
            "The year stacked problems on top of problems and asked you to smile.",
            "You held it together. From the outside, anyway.",
            "You stopped counting what was wrong. Too many things to count.",
            "Survival mode isn't a strategy. But it got you through.",
            "You didn't fix anything. You just didn't let anything break all the way.",
        ]
    }

    private func grindingNotes(_ state: GameState) -> [String] {
        var notes = [
            "Another month of watching the balance creep toward zero.",
            "You made it work. You always make it work. It's exhausting.",
            "The math didn't add up this year. You made it add up anyway.",
            "Tight year. You've had tighter.",
            "Money was short. You stretched it.",
            "You checked the account more than you'd like to admit.",
            "Nothing catastrophic. Just the slow grind of not having enough.",
        ]
        if state.finance.cashOnHand < 0 {
            notes += [
                "You went negative. You've been here before.",
                "The account went red. You already know what that feels like.",
            ]
        }
        if state.finance.financialStress >= 70 {
            notes += [
                "The financial pressure was loud this year. Constant background noise.",
                "You did the math again. You already knew the answer.",
            ]
        }
        return notes
    }

    private func burnedOutNotes(_ state: GameState) -> [String] {
        var notes = [
            "You made it through. That's all you can say.",
            "Another year of pushing through what you should have stopped and fixed.",
            "You were tired before the year started.",
            "You went through the motions. The motions went through you.",
            "Work, sleep, repeat. The three-part life.",
            "You kept showing up. That counts for something. Probably.",
            "Not a bad year. Not a year you'd want to repeat, either.",
        ]
        if state.career.burnout >= 75 {
            notes += [
                "The job is taking more than it's giving. It's been taking more for a while.",
                "You're running on empty and everyone pretends not to notice.",
            ]
        }
        if state.healthProfile.mentalWellness < 35 {
            notes += [
                "The mental weight of it all was hard to describe. Still is.",
                "You functioned. That's different from being okay.",
            ]
        }
        return notes
    }

    private func isolatedNotes(_ state: GameState) -> [String] {
        var notes = [
            "Quiet year. Nobody really checked in.",
            "You spent a lot of time with your own thoughts. They weren't great company.",
            "The distance between you and people just grew a little more.",
            "You didn't reach out. They didn't reach out. That's how it goes.",
            "Loneliness isn't dramatic. It's just quiet.",
            "Another year of being fine, technically.",
            "You're not disconnected. You're just... at a distance.",
        ]
        if state.relationships.friends.isEmpty && !state.relationships.hasPartner {
            notes += [
                "No one to call. No real reason to call anyone.",
                "The social circle shrank to just you. You got used to it.",
            ]
        }
        return notes
    }

    private func holdingNotes(_ state: GameState) -> [String] {
        let yearsAtJob = state.career.yearsWorked
        var notes = [
            "Nothing broke. You almost didn't notice.",
            "Same rhythms. Same results. A stable year.",
            "The year passed the way most years pass — without asking permission.",
            "No big wins. No big losses. You stayed the course.",
            "Steady. Which is underrated.",
            "The routine held. The routine always holds.",
        ]
        if yearsAtJob >= 3 {
            notes += [
                "Same job. \(yearsAtJob == 3 ? "Third" : "\(yearsAtJob)th") year running.",
                "You're still there. That's both reassuring and unsettling.",
            ]
        }
        if state.player.age >= 30 && state.player.age <= 45 {
            notes += [
                "Another year of the life you've built. Sometimes that's enough.",
                "This is what the middle looks like. You expected more drama.",
            ]
        }
        return notes
    }

    private func hopefulNotes(_ state: GameState) -> [String] {
        [
            "Something shifted this year. You can feel it.",
            "Not a breakthrough year. But the direction is right.",
            "The momentum is quiet, but it's real.",
            "Things are moving. Slowly, but moving.",
            "You're not where you want to be. But you can see it from here.",
            "It was a good year to look back on.",
            "The effort is starting to compound. Finally.",
        ]
    }

    private func clearNotes(_ state: GameState) -> [String] {
        [
            "Nothing broke. Everything held. That's rarer than it sounds.",
            "A genuinely good year. You should sit with that.",
            "Stable across the board. You've earned this.",
            "No chaos. No crisis. Just a life working the way it should.",
            "The kind of year you forget because nothing went wrong.",
            "You looked up and everything was okay. Not spectacular. Okay. It was enough.",
        ]
    }

    // D4: derive ambient life shape from recent stances (pragmatic/careful/loose/driven) + heat
    private func deriveLifeShape(state: GameState) -> String {
        let recent = state.yearlyStance.recentStances
        guard !recent.isEmpty else { return "" }
        var pragmatic = 0, careful = 0, loose = 0, driven = 0
        for s in recent {
            switch s {
            case .stabilizeMoney: pragmatic += 1
            case .protectHealth: careful += 1
            case .letYearDrift: loose += 1
            case .pushCareer, .soldierStance: driven += 1
            default: pragmatic += 1
            }
        }
        let heat = state.correlationLedger.recentActivityLevel
        if heat >= 50 { driven += 1 }
        if loose > max(pragmatic, careful, driven) { return "loose edges" }
        if careful > max(pragmatic, loose, driven) { return "careful shape" }
        if driven > max(pragmatic, careful, loose) { return "driven current" }
        return "pragmatic"
    }
