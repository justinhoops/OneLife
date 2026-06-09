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
        let pool: [String]
        if let streak = LifeShapeResolver.stanceStreak(in: state, minimum: 3) {
            pool = stanceDrivenPool(for: streak, tone: tone, state: state)
        } else {
            pool = notePool(for: tone, state: state)
        }
        var baseNote = pool.randomElement() ?? "Another year passed."

        let heat = state.correlationLedger.recentActivityLevel
        let momentum = state.instantMomentum.overallStrength
        let recentAutonomy = state.correlationLedger.recentSignals(kind: .npcAutonomyPulse, minStrength: 5).count +
                             state.correlationLedger.recentSignals(kind: .worldAutonomyPulse, minStrength: 5).count
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

        if recentFocus >= 2, LifeShapeResolver.stanceStreak(in: state, minimum: 3) == nil {
            baseNote += " The shape of what you focused on (or avoided) is still audible."
        }

        let shapeLabel = LifeShapeResolver.label(from: state, includeActivityHeat: true)
        if !shapeLabel.isEmpty {
            baseNote += " (\(shapeLabel))"
        }

        if state.correlationLedger.recentActivityLevel < 20 && shapeLabel.contains("loose") {
            baseNote += " The shape feels diffuse; doors stayed closed without drama."
        }

        if state.player.age >= 80, Int.random(in: 0...100) < 18 {
            baseNote += " At this age the quiet is no longer empty — it is the sound of everything that came before."
        }
        if state.fame.notoriety >= 65 || state.crime.heat >= 60, Int.random(in: 0...100) < 12 {
            baseNote += " Even in stillness, the name (or the heat) travels ahead of you."
        }
        if state.family.children.isEmpty && state.player.age >= 50, Int.random(in: 0...100) < 10 {
            baseNote += " The house is quiet in a different way. The future will not carry your name the same way."
        }
        if state.finance.cashOnHand < 0 && state.player.age >= 45, Int.random(in: 0...100) < 10 {
            baseNote += " The margin is gone. The quiet years now carry the weight of every choice that spent it."
        }

        return baseNote
    }

    /// Primary silence pool when the same stance landed three years in a row — the world remembers the pattern.
    private func stanceDrivenPool(for stance: YearlyStanceID, tone: NarrativeTone, state: GameState) -> [String] {
        switch stance {
        case .pushCareer, .soldierStance, .studentStance:
            return [
                "Same grind. The career lane kept taking priority and everything else waited.",
                "You pushed again. The year didn't reward it loudly, but the pattern is obvious now.",
                "Another year of showing up first for work. The cost is starting to show in what didn't happen.",
                "The hustle continued. Quiet doesn't mean easy — it means the engine never really idled.",
                "Opportunities arrived smaller than they used to. You were too busy to notice until now.",
            ]
        case .protectHealth:
            return [
                "You kept protecting the body. Small wins, no headlines — but you're still upright.",
                "Another year of choosing rest over reach. The quiet feels earned, not accidental.",
                "The maintenance held. Nothing dramatic broke because you refused to ignore the signals.",
                "You treated recovery like a job. It paid off in ways that don't photograph well.",
                "The machine is still running because you stopped pretending it was invincible.",
            ]
        case .letYearDrift:
            return [
                "You let the year slide again. Fewer doors knocked; fewer people reached back.",
                "The looseness compounded. Nothing fell apart — it just didn't tighten.",
                "Another drift year. The world stopped offering as much and you didn't fight it.",
                "Quiet, but thin. The life feels wider at the edges and lighter in the middle.",
                "Relationships didn't explode. They just moved a little further away without a scene.",
            ]
        case .stabilizeMoney:
            return [
                "You kept the money discipline. The quiet felt less precarious than it used to.",
                "Another year of watching numbers instead of chasing noise. Stability has its own texture.",
                "The ledger stayed controlled. Boring on paper, relieving in the body.",
                "You chose margin over momentum. The year respected that choice without celebrating it.",
                "Financial quiet isn't peace — but it's closer than you've been in a while.",
            ]
        case .repairPeople:
            return [
                "You kept showing up for people in small ways. The bonds didn't snap; some didn't deepen either.",
                "Another year of tending relationships without fireworks. The work is invisible until it isn't.",
                "You chose connection over conquest. The quiet carries who still answers your texts.",
                "The social fabric held. Not tight, not torn — just maintained.",
                "People noticed you tried, even when the year had nothing dramatic to report.",
            ]
        default:
            return notePool(for: tone, state: state)
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
}
