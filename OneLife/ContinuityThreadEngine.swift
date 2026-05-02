import Foundation

// MARK: - ContinuityThreadEngine
//
// Codex IX — Continuity Thread.
// The teen years and adulthood must feel like the same life.
//
// This engine fires narrative beats at key continuity moments:
//   - Age 18: a backward + forward beat that names the transition explicitly
//   - Age 20: a first lookback that reads the actual history of the teen years
//   - First employment: a trait callback that connects who you were at 14 to what you just did
//
// Life path crystallization improvements live in ProgressCoreSystems.swift.
// Teen flag density lives in SampleEvents.json.
//
// Called once per yearly tick from resolvePreparedYearChapter, after all
// domain systems have run. Receives both before and after state.

struct ContinuityThreadEngine {

    private let toneResolver = NarrativeToneResolver()

    func evaluate(before: GameState, after: inout GameState) -> DomainYearResult {
        var result = DomainYearResult()

        // Age 18 fires once — the hard transition
        if after.player.age == 18,
           !after.consequences.narrativeFlags.keys.contains("continuity_age18_fired") {
            after.consequences.narrativeFlags["continuity_age18_fired"] = 18
            if let note = age18Beat(after) {
                result.notes.append(note)
            }
        }

        // Age 20 fires once — first look back
        if after.player.age == 20,
           !after.consequences.narrativeFlags.keys.contains("continuity_age20_fired") {
            after.consequences.narrativeFlags["continuity_age20_fired"] = 20
            if let note = age20Lookback(after) {
                result.notes.append(note)
            }
        }

        // First employment — fires once when status transitions into work
        if detectsFirstEmployment(before: before, after: after),
           !after.consequences.narrativeFlags.keys.contains("continuity_first_job_fired") {
            after.consequences.narrativeFlags["continuity_first_job_fired"] = after.player.age
            if let note = firstJobTraitCallback(after) {
                result.notes.append(note)
            }
        }

        return result
    }

    // MARK: - Age 18 Beat

    private func age18Beat(_ state: GameState) -> DomainNote? {
        let trait  = state.player.traits.first
        let flags  = state.consequences.narrativeFlags

        // One sentence looking backward — shaped by teen flags
        let backwardLine: String
        if flags["peer_pressure_gave_in"] != nil {
            backwardLine = "The years between 14 and now had more wrong turns than you'd admit to."
        } else if flags["teacher_believed_in_you"] != nil {
            backwardLine = "Someone paid attention to you between 14 and now. That changed more than one thing."
        } else if flags["survived_adversity_early"] != nil {
            backwardLine = "The years between 14 and 18 were harder than they should have been. You made it through."
        } else if flags["anxiety_spiral_history"] != nil {
            backwardLine = "The teen years were louder inside your head than they looked from the outside."
        } else if flags["scholarship_won"] != nil {
            backwardLine = "The work between 14 and now paid off in at least one concrete way."
        } else {
            backwardLine = "You made it through the years between 14 and now mostly intact."
        }

        // One sentence looking forward — shaped by education path
        let forwardLine: String
        switch state.education.stage {
        case .university:
            forwardLine = "Now there's a campus, a debt, and a version of the future that might actually work."
        case .tradeTraining:
            forwardLine = "The trade path is less glamorous. It's also more honest about what it offers."
        case .adultEd:
            forwardLine = "The traditional route closed. You're finding a different one."
        default:
            if state.education.pathway == .dropout {
                forwardLine = "School is done. The next chapter doesn't have a name yet."
            } else {
                forwardLine = "Adulthood doesn't announce itself. It just starts billing."
            }
        }

        // One sentence from the trait — connects character identity to the moment
        let traitLine: String
        if let trait {
            traitLine = age18TraitLine(for: trait)
        } else {
            traitLine = "The person you were at 14 is still in there, somewhere."
        }

        let text = "\(backwardLine) \(forwardLine)\n\n\(traitLine)"
        return DomainNote(title: "Age 18", text: text, tags: [.progress, .lifeEvent])
    }

    private func age18TraitLine(for trait: PersonalityTrait) -> String {
        switch trait {
        case .disciplined:
            return "You've been building the habit since before you knew it mattered. Now it does."
        case .impulsive:
            return "Every decision made fast, some of them good. Adulthood just raises the stakes."
        case .charismatic:
            return "People have been watching you for years. You're starting to decide what to do with that."
        case .anxious:
            return "You've been thinking three steps ahead your whole life. For once, ahead is here."
        case .lucky:
            return "The breaks that went your way before 18 don't carry over automatically. But they gave you runway."
        case .manipulative:
            return "Reading people got you this far. Adulthood is where that talent starts leaving marks."
        case .coldBlooded:
            return "Staying detached helped before. Now it can look like strength or cost, depending on the room."
        case .visionary:
            return "You've been living partly in the future for years. Now the future expects receipts."
        case .burnoutProne:
            return "You learned early how to push past your limit. Adult life is about what that habit takes back."
        }
    }

    // MARK: - Age 20 Lookback

    private func age20Lookback(_ state: GameState) -> DomainNote? {
        let tone  = toneResolver.resolve(for: state)
        let flags = state.consequences.narrativeFlags

        // Count meaningful history entries from teen years
        let teenEntries = state.history.filter { $0.age >= 14 && $0.age < 18 }
        let wasEventful = teenEntries.count >= 5

        // Opening line — tone-matched
        let openingLine: String
        switch tone {
        case .cornered, .grinding:
            openingLine = "Six years since you were 14. Most of them harder than expected."
        case .burnedOut:
            openingLine = "Six years since you were 14. You're tired in a way that started earlier than it should have."
        case .isolated:
            openingLine = "Six years since you were 14. The social map is smaller than you planned."
        case .hopeful:
            openingLine = "Six years since you were 14. Something is starting to build."
        case .clear:
            openingLine = "Six years since you were 14. Most things held together."
        case .holding:
            openingLine = "Six years since you were 14. The life is taking shape slowly."
        }

        // Middle line — shaped by how eventful the teen years were
        let middleLine: String
        if wasEventful {
            middleLine = "A lot moved between then and now — school, money, people, decisions you can't take back and a few you would."
        } else {
            middleLine = "The teen years were quieter than most. That's either good groundwork or a debt not yet paid."
        }

        // Closing line — most specific thing available
        let closingLine: String
        if flags["scholarship_won"] != nil {
            closingLine = "The scholarship was real. That changed the financial math."
        } else if flags["anxiety_spiral_history"] != nil {
            closingLine = "The anxiety that started before 18 is still part of the operating cost. That's worth knowing."
        } else if flags["survived_adversity_early"] != nil {
            closingLine = "The early adversity left something behind. Hard to name, but it's there."
        } else if state.finance.studentDebt > 15_000 {
            let formatted = formattedDebt(state.finance.studentDebt)
            closingLine = "The \(formatted) in debt is real. It will be real for a while."
        } else if let lifePath = state.progress.currentLifePath {
            let profile = LifePathCatalog.profile(for: lifePath)
            closingLine = "The shape of this life is starting to show: \(profile.title.lowercased())."
        } else {
            closingLine = "The shape of it isn't clear yet. That's not uncommon at 20."
        }

        let text = "\(openingLine) \(middleLine) \(closingLine)"
        return DomainNote(title: "Age 20 — First Look Back", text: text, tags: [.progress, .lifeEvent])
    }

    // MARK: - First Job Trait Callback

    private func firstJobTraitCallback(_ state: GameState) -> DomainNote? {
        // Job-specific line
        let jobLine: String
        switch state.career.profile {
        case .stableAdmin:
            jobLine = "The job is steady. The desk is yours. Not exciting — but real."
        case .physicalLabor:
            jobLine = "The work is physical and the pay is honest. Your body will notice by year three."
        case .serviceFrontline:
            jobLine = "You're facing the public now. It takes something out of you every shift. Most people don't last long in it."
        case .creativeFreelance:
            jobLine = "Real income and no safety net. Both of those are true at the same time."
        case .credentialedProfessional:
            jobLine = "The credential opened the door exactly the way everyone said it would."
        }

        // Trait-specific line — connects identity to the first day
        guard let trait = state.player.traits.first else {
            return DomainNote(title: "First Real Work", text: jobLine, tags: [.career, .progress])
        }
        let traitLine = firstJobTraitLine(for: trait, state: state)
        let text = "\(jobLine) \(traitLine)"
        return DomainNote(title: "First Real Work", text: text, tags: [.career, .progress])
    }

    private func firstJobTraitLine(for trait: PersonalityTrait, state: GameState) -> String {
        let name = state.player.name
        let useFirstPerson = name == "Player" || name.isEmpty
        let subject = useFirstPerson ? "You" : name

        switch trait {
        case .disciplined:
            return "\(subject) showed up early. \(useFirstPerson ? "You'll" : "\(name) will") probably always show up early."
        case .impulsive:
            return "\(subject) said yes before finishing the offer letter. That's consistent, at least."
        case .charismatic:
            return "Within two weeks, \(subject.lowercased()) knew everyone's name. That's not a small thing."
        case .anxious:
            return "\(subject) prepared more than anyone expected. Also worried more than anyone knew."
        case .lucky:
            return "\(subject) got the interview through a coincidence. Same as most things."
        case .manipulative:
            return "\(subject) read the room fast and used it. Work tends to reward that until it doesn't."
        case .coldBlooded:
            return "\(subject) stayed calm enough to look almost untouchable. People notice that at work."
        case .visionary:
            return "\(subject) was already talking about what the job could become before the first shift settled."
        case .burnoutProne:
            return "\(subject) started hard, fast, and a little too far over the limit."
        }
    }

    // MARK: - Detection

    private func detectsFirstEmployment(before: GameState, after: GameState) -> Bool {
        let wasNotWorking = before.career.status == .unemployed || before.career.status == .student
        let isNowWorking  = after.career.status == .fullTime || after.career.status == .partTime
        let isEarlyCareer = after.career.yearsWorked <= 1
        return wasNotWorking && isNowWorking && isEarlyCareer && after.player.age >= 16
    }

    // MARK: - Helpers

    private func formattedDebt(_ amount: Int) -> String {
        if amount >= 1_000_000 { return "$\(amount / 1_000_000)M" }
        if amount >= 1_000     { return "$\(amount / 1_000)K" }
        return "$\(amount)"
    }
}
