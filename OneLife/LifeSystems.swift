import Foundation

// MARK: - Shared year-tick result pieces

struct SystemYearDeltas: Equatable {
    var deltas = DeltaSummary()
    var bullets: [String] = []
    var notes: [String] = []
    var milestoneHeadline: String?
    var milestoneDetail: String?
    var medicalImpact: MedicalFinanceImpact?
    var assetPrincipalPayment = 0
    var mortgageReceipts: [MortgageReceipt] = []
    var consequences: [DomainConsequence] = []
}

typealias DomainYearResult = SystemYearDeltas

/// Immutable information shared with yearly processors. It prevents domains
/// from reaching into unrelated mutable state to answer environmental questions.
struct YearContext: Equatable {
    let age: Int
    let lifeStage: LifeStage
    let world: WorldModifierSnapshot
    let personality: PersonalityProfile
    let activeThreads: [LifeThread]

    init(state: LifeState, world: WorldModifierSnapshot? = nil) {
        age = state.character.age
        lifeStage = state.lifeStage
        self.world = world ?? WorldSystem.modifiers(for: state.world)
        personality = state.personality
        activeThreads = state.lifeThreads.filter { $0.resolution != .resolved }
    }

    func pressure(on domain: ConsequenceDomain) -> Int {
        activeThreads
            .filter { $0.target == domain }
            .reduce(0) { $0 + $1.intensity }
    }

    func pressure(on domain: ConsequenceDomain, from source: ConsequenceDomain) -> Int {
        activeThreads
            .filter { $0.target == domain && $0.source == source }
            .reduce(0) { $0 + $1.intensity }
    }
}

struct MedicalFinanceImpact: Equatable {
    var requestedDebtCharge: Int
    var reason: String
}

// MARK: - Year summary composition

/// Distills domain-owned yearly results into one stable presentation snapshot.
/// The UI renders this data but never decides which consequences matter most.
enum YearSummarySystem {
    static func compose(
        age: Int,
        headline: String,
        bullets: [String],
        deltas: DeltaSummary,
        stanceTitle: String?,
        shapeTitle: String?,
        focusNote: String?,
        silenceNote: String?,
        wasQuiet: Bool,
        stageTransition: String? = nil,
        mortalityWarning: String? = nil,
        worldNews: WorldNews? = nil
    ) -> YearSummary {
        let developments = makeDevelopments(age: age, headline: headline, bullets: bullets, deltas: deltas)
        let importance = importance(
            wasQuiet: wasQuiet,
            deltas: deltas,
            developments: developments,
            stageTransition: stageTransition,
            mortalityWarning: mortalityWarning,
            worldNews: worldNews
        )
        var summary = YearSummary(
            bullets: [],
            stanceTitle: stanceTitle,
            shapeTitle: shapeTitle,
            focusNote: focusNote,
            silenceNote: silenceNote,
            wasQuiet: wasQuiet,
            stageTransition: stageTransition,
            mortalityWarning: mortalityWarning,
            worldNews: worldNews,
            age: age,
            headline: headline,
            deltas: deltas,
            importance: importance
        )
        summary.developments = developments
        return summary
    }

    static func finalize(
        _ summary: YearSummary,
        headline: String,
        deltas: DeltaSummary
    ) -> YearSummary {
        var finalized = summary
        finalized.headline = headline
        finalized.deltas = deltas
        finalized.developments = makeDevelopments(
            age: summary.age,
            headline: headline,
            bullets: summary.developments.map(\.text),
            deltas: deltas
        )
        finalized.importance = importance(
            wasQuiet: finalized.wasQuiet,
            deltas: deltas,
            developments: finalized.developments,
            stageTransition: finalized.stageTransition,
            mortalityWarning: finalized.mortalityWarning,
            worldNews: finalized.worldNews
        )
        return finalized
    }

    static func rankedImpacts(_ deltas: DeltaSummary, limit: Int = 4) -> [SemanticDelta] {
        Array(deltas.semanticLines.sorted { lhs, rhs in
            let left = normalizedMagnitude(lhs)
            let right = normalizedMagnitude(rhs)
            if left == right { return lhs.label < rhs.label }
            return left > right
        }.prefix(limit))
    }

    private static func makeDevelopments(
        age: Int,
        headline: String,
        bullets: [String],
        deltas: DeltaSummary
    ) -> [YearDevelopment] {
        let deltaLines = Set(deltas.lines.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        })
        var seen: Set<String> = [normalize(headline)]
        return bullets.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = normalize(trimmed)
            guard !trimmed.isEmpty, !deltaLines.contains(key), seen.insert(key).inserted else { return nil }
            return YearDevelopment(
                id: "year-\(age)-\(stableIdentifier(key))",
                text: trimmed
            )
        }
    }

    private static func importance(
        wasQuiet: Bool,
        deltas: DeltaSummary,
        developments: [YearDevelopment],
        stageTransition: String?,
        mortalityWarning: String?,
        worldNews: WorldNews?
    ) -> YearSummaryImportance {
        if mortalityWarning != nil || worldNews?.severity == .danger { return .critical }
        let impacts = deltas.semanticLines
        let hasMajorImpact = impacts.contains { delta in
            delta.label == "Cash" ? abs(delta.value) >= 80 : abs(delta.value) >= 8
        }
        if stageTransition != nil || worldNews?.severity == .pressure || hasMajorImpact { return .major }
        if !impacts.isEmpty || !developments.isEmpty || !wasQuiet { return .notable }
        return .quiet
    }

    private static func normalizedMagnitude(_ delta: SemanticDelta) -> Double {
        delta.label == "Cash" ? Double(abs(delta.value)) / 10.0 : Double(abs(delta.value))
    }

    private static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func stableIdentifier(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let pieces = value.unicodeScalars.map { allowed.contains($0) ? String($0) : "-" }
        return pieces.joined().replacingOccurrences(of: "--", with: "-")
    }
}

// MARK: - Declarative effect application

/// Owns the generic EffectRange → state transformation used by actions and
/// event choices. Domain systems decide *which* effects exist; this processor
/// applies them consistently without putting calculation in the orchestrator.
enum EffectResolutionSystem {
    @discardableResult
    static func apply(_ effects: EffectRange, state: inout LifeState, financialPurpose: FinancialPurpose = .household) -> DeltaSummary {
        guard effects != EffectRange() else { return DeltaSummary() }
        state.adoptHealthCompatibility()
        var school = state.randomStreams.action.next(in: effects.school)
        let cashRoll = state.randomStreams.action.next(in: effects.cash)
        var love = state.randomStreams.action.next(in: effects.love)
        var play = state.randomStreams.action.next(in: effects.play)
        var health = state.randomStreams.action.next(in: effects.health)
        var looks = state.randomStreams.action.next(in: effects.looks)
        var rep = state.randomStreams.action.next(in: effects.rep)

        school = diminishGain(school, current: state.stats.school)
        love = diminishGain(love, current: state.stats.love)
        play = diminishGain(play, current: state.stats.play)
        health = diminishGain(health, current: state.health.overall)
        looks = diminishGain(looks, current: state.stats.looks)
        rep = diminishGain(rep, current: state.stats.rep)

        let cash = cashRoll
        if state.lifeStage == .pressure || state.lifeStage == .legacy {
            if health < 0 { health -= 1 }

        }

        let deltas = DeltaSummary(
            school: school,
            cash: cash,
            love: love,
            play: play,
            health: health,
            looks: looks,
            rep: rep
        )
        return apply(deltas, state: &state, financialPurpose: financialPurpose)
    }

    @discardableResult
    static func apply(
        _ deltas: DeltaSummary,
        state: inout LifeState,
        financialPurpose: FinancialPurpose = .household,
        incomeSource: IncomeSource? = nil
    ) -> DeltaSummary {
        state.adoptHealthCompatibility()
        let beforeStats = state.stats
        let beforeHealth = state.health.overall
        let beforeCash = state.cash
        state.stats.school += deltas.school
        _ = FinanceSystem.transact(.init(amount: deltas.cash, purpose: financialPurpose, incomeSource: incomeSource), state: &state)
        state.stats.love += deltas.love
        state.stats.play += deltas.play
        state.health.physicalWellbeing += deltas.health
        state.health.mentalWellbeing += deltas.health
        state.stats.looks += deltas.looks
        state.stats.rep += deltas.rep
        // Generic effects own only canonical stats, cash, and health. Running
        // LifeState.clamp() here used to re-normalize every unrelated domain
        // (including the full property portfolio) several times per action and
        // yearly tick. The orchestrator still performs one whole-state clamp at
        // the yearly commit boundary.
        state.stats.clamp()
        state.health.clamp()
        state.syncHealthCompatibility()
        if state.cash < 0 { state.finance.consumerDebt = EconomyPolicy.checkedAdd(state.finance.consumerDebt, -state.cash); state.cash = 0 }
        return DeltaSummary(
            school: state.stats.school - beforeStats.school,
            cash: state.cash - beforeCash,
            love: state.stats.love - beforeStats.love,
            play: state.stats.play - beforeStats.play,
            health: state.health.overall - beforeHealth,
            looks: state.stats.looks - beforeStats.looks,
            rep: state.stats.rep - beforeStats.rep
        )
    }

    private static func diminishGain(_ value: Int, current: Int) -> Int {
        guard value > 0 else { return value }
        if current >= 88 { return max(1, value / 3) }
        if current >= 72 { return max(1, (value * 2) / 3) }
        return value
    }
}

struct InstantNarrativeResolution: Equatable {
    let detail: String
    let reaction: String?
    let personalityContext: String?
}

/// Owns compact, state-correlated prose for immediate actions.
enum InstantNarrativeSystem {
    static func resolve(
        action: DomainAction,
        social: SocialActionResolution,
        deltas: DeltaSummary,
        state: LifeState
    ) -> InstantNarrativeResolution {
        let contextual = social.hasPersonalityResponse || social.npcEffect != EffectRange()
        let progressionReaction = reaction(for: action, deltas: deltas, state: state)
        let socialReaction = contextual ? social.narrative : nil
        let reactions = [socialReaction, progressionReaction]
            .compactMap { $0 }
            .reduce(into: [String]()) { unique, line in
                if !unique.contains(line) { unique.append(line) }
            }
        let reaction = reactions.isEmpty ? nil : reactions.joined(separator: " ")
        let contexts = [social.personalityContext, social.npcContext]
            .compactMap { $0 }
            .joined(separator: " · ")
        let rawDetail: String
        if !contexts.isEmpty, let reaction {
            rawDetail = "\(contexts) — \(reaction)"
        } else {
            rawDetail = reaction ?? action.narrative
        }
        return InstantNarrativeResolution(
            detail: NarrativeVibeResolver.flavor(rawDetail, state: state),
            reaction: reaction,
            personalityContext: contexts.isEmpty ? nil : contexts
        )
    }

    private static func reaction(for action: DomainAction, deltas: DeltaSummary, state: LifeState) -> String? {
        if action.id == .applyForBetterWork, state.education.credential, state.job.tier == .skilled {
            return "The application stuck. Skilled work is now your lane."
        }
        if action.id == .goOnDate, state.partner != nil, deltas.love > 0 {
            return "Something between you is no longer theoretical."
        }
        if action.id == .party, deltas.health <= -3 {
            return "Fun first. The body files the complaint later."
        }
        if action.id == .repairConflict, deltas.bond > 0 {
            return "The hard talk cost something. It also bought air."
        }
        if !action.partnerEffect.isEmpty, state.partner != nil {
            return action.narrative
        }
        return nil
    }
}

/// A bounded, action-specific repeat window; no global action counter exists.
enum ActionCadenceSystem {
    private static let incomeActions: Set<ActionID> = [.workShift, .sideHustle]
    private static let routineActions: Set<ActionID> = [
        .study, .attendClass, .networkContacts, .developSkill,
        .reachOut, .seeFriends, .pursueHobby, .party, .quietNight, .familyDinner,
        .exercise, .rest, .seekCare, .therapySupport, .manageCondition,
        .preventiveCare, .cutBack, .parentingPresence, .caregiving,
        .buildProfessionalNetwork, .buildWorkplaceRelationship
    ]

    static func policy(for id: ActionID) -> ActionRepeatPolicy {
        if incomeActions.contains(id) { return .repeatable(maxPerAge: 2) }
        if routineActions.contains(id) { return .repeatable(maxPerAge: 3) }
        return .oncePerAge
    }

    /// Exceptional rolls are possible only inside the finite repeat window.
    /// Negative costs are never discounted by repeating an action.
    static func adjusted(_ effects: EffectRange, for action: ActionID, state: inout LifeState) -> EffectRange {
        let priorUses = state.actionUseCount(for: action.rawValue)
        guard priorUses > 0, policy(for: action).maxPerAge > 1 else { return effects }
        let roll = state.randomStreams.action.next(in: 1...100)
        let scale: Int
        if roll <= 4 { scale = 115 }
        else if priorUses == 1 { scale = roll <= 35 ? 45 : (roll <= 75 ? 65 : 85) }
        else { scale = roll <= 45 ? 20 : (roll <= 85 ? 40 : 65) }
        func adjust(_ range: ClosedRange<Int>) -> ClosedRange<Int> {
            func point(_ value: Int) -> Int { value > 0 ? value * scale / 100 : value }
            return point(range.lowerBound)...point(range.upperBound)
        }
        var result = effects
        result.school = adjust(effects.school)
        result.cash = adjust(effects.cash)
        result.love = adjust(effects.love)
        result.play = adjust(effects.play)
        result.health = adjust(effects.health)
        result.looks = adjust(effects.looks)
        result.rep = adjust(effects.rep)
        return result
    }

    static func adjustedIncome(_ gross: Int, for action: ActionID, state: inout LifeState) -> Int {
        guard state.actionUseCount(for: action.rawValue) > 1 else { return gross }
        let roll = state.randomStreams.finance.next(in: 1...100)
        let percent = roll <= 4 ? 110 : (roll <= 35 ? 40 : (roll <= 80 ? 60 : 75))
        return max(0, gross * percent / 100)
    }
}

struct ContextActionResolution {
    let headline: String
    let detail: String
    let deltas: DeltaSummary
    let impacts: [ActionImpact]
}

/// Context selection reads state only. Its five commands delegate their effects
/// to the domains that already own school, money, relationships, and health.
enum ContextActionSystem {
    static func title(for id: ContextActionID, target: PersonReference?, state: LifeState) -> String {
        let name = target.flatMap { state.name(for: $0) }
        return switch id {
        case .teacherHelp: "Ask \(name ?? "a teacher") for help"
        case .hardshipExtension: "Request payment extension"
        case .makeAmends: "Make amends with \(name ?? "someone")"
        case .friendInvitation: "Join \(name ?? "a friend")'s plan"
        case .adjustCarePlan: "Adjust your care plan"
        }
    }

    static func domain(for id: ContextActionID) -> Domain {
        return switch id {
        case .teacherHelp: .school
        case .hardshipExtension: .cash
        case .makeAmends: .love
        case .friendInvitation: .play
        case .adjustCarePlan: .health
        }
    }

    static func availability(_ id: ContextActionID, target: PersonReference?, state: LifeState) -> Availability {
        guard !state.isGameOver, state.pendingEvent == nil else { return .locked("Finish the current moment first") }
        guard state.actionUseCount(for: "context:\(id.rawValue)") == 0 else { return .locked("Spent for this year") }
        switch id {
        case .teacherHelp:
            guard state.flags.attendsSchool, state.stats.school < 75,
                  case .some(.cast(let memberID)) = target,
                  state.npcs.member(id: memberID)?.role == .teacher else { return .locked("Needs a current teacher and room to improve") }
        case .hardshipExtension:
            guard state.finance.totalDebt > 0, state.finance.financialStress >= 35 else { return .locked("Needs active debt pressure") }
        case .makeAmends:
            guard let target else { return .locked("Choose a person first") }
            switch target {
            case .partner:
                guard let partner = state.partner, partner.resentment >= 20 || partner.bond <= 50 else { return .locked("There is no active conflict to repair") }
            case .cast(let memberID):
                guard let member = state.npcs.member(id: memberID), member.rapport <= -8 else { return .locked("This connection is not strained") }
            case .family(let contactID):
                guard let contact = state.family.contacts.first(where: { $0.id == contactID }), contact.bond <= 40 else { return .locked("This family connection is not strained") }
            }
        case .friendInvitation:
            guard case .some(.cast(let memberID)) = target,
                  let friend = state.npcs.member(id: memberID), friend.role == .friend,
                  friend.rapport >= 7 else { return .locked("Choose a friend who wants to spend time") }
        case .adjustCarePlan:
            guard !state.health.conditions.isEmpty else { return .locked("No condition needs a care plan") }
        }
        return .available
    }

    static func resolve(_ id: ContextActionID, target: PersonReference?, state: inout LifeState) -> ContextActionResolution? {
        guard availability(id, target: target, state: state) == .available else { return nil }
        let before = state
        var impacts: [ActionImpact] = []
        let detail: String
        switch id {
        case .teacherHelp:
            guard case .some(.cast(let memberID)) = target else { return nil }
            _ = EducationSystem.resolveTeacherHelp(state: &state)
            SocialReactivitySystem.recordContextContact(memberID: memberID, rapport: 2, state: &state)
            impacts = [ActionImpact(domain: .relationships, label: "Teacher rapport", change: 2)]
            detail = "The extra time made the material clearer and the teacher noticed your effort."
        case .hardshipExtension:
            FinanceSystem.requestHardshipExtension(state: &state)
            impacts = [ActionImpact(domain: .finance, label: "Debt", change: 200), ActionImpact(domain: .finance, label: "Financial stress", change: -12)]
            detail = "The payment pressure eased this year, but the lender added a fee to the balance."
        case .makeAmends:
            guard let target else { return nil }
            let result = SocialReactivitySystem.makeAmends(with: target, state: &state)
            impacts = [ActionImpact(domain: .relationships, label: result.label, change: result.change)]
            detail = result.detail
        case .friendInvitation:
            guard case .some(.cast(let memberID)) = target else { return nil }
            let welcomed = SocialReactivitySystem.joinFriendInvitation(memberID: memberID, state: &state)
            _ = EffectResolutionSystem.apply(
                EffectRange(love: welcomed ? 2...4 : 0...1, play: welcomed ? 3...5 : 1...2), state: &state
            )
            impacts = [ActionImpact(domain: .relationships, label: "Friend rapport", change: welcomed ? 2 : -1)]
            detail = welcomed ? "You went along and the friendship had room to grow." : "The plan was awkward, but you learned where the friendship stands."
        case .adjustCarePlan:
            _ = ConditionHealthSystem.resolve(.manage, state: &state, world: WorldSystem.modifiers(for: state.world))
            impacts = [ActionImpact(domain: .health, label: "Care plan revised", change: nil)]
            detail = "The plan changed to fit the condition you are actually living with."
        }
        state.markActionUsed(key: "context:\(id.rawValue)")
        state.clamp()
        return ContextActionResolution(
            headline: title(for: id, target: target, state: state),
            detail: detail,
            deltas: DeltaSummary(
                school: state.stats.school - before.stats.school,
                cash: state.cash - before.cash,
                love: state.stats.love - before.stats.love,
                play: state.stats.play - before.stats.play,
                health: state.stats.health - before.stats.health,
                looks: state.stats.looks - before.stats.looks,
                rep: state.stats.rep - before.stats.rep,
                bond: (state.partner?.bond ?? 0) - (before.partner?.bond ?? 0),
                resentment: (state.partner?.resentment ?? 0) - (before.partner?.resentment ?? 0)
            ),
            impacts: impacts
        )
    }
}

extension LifeState {
    func name(for person: PersonReference) -> String? {
        return switch person {
        case .partner: partner?.name
        case .cast(let id): npcs.member(id: id)?.name
        case .family(let id): family.contacts.first(where: { $0.id == id })?.name
        }
    }
}

extension EducationSystem {
    static func resolveTeacherHelp(state: inout LifeState) -> DeltaSummary {
        EffectResolutionSystem.apply(EffectRange(school: 2...5, health: -1 ... -1), state: &state)
    }
}

extension FinanceSystem {
    static func requestHardshipExtension(state: inout LifeState) {
        if state.finance.consumerDebt > 0 { state.finance.consumerDebt += 200 }
        else if state.finance.studentDebt > 0 { state.finance.studentDebt += 200 }
        else { state.finance.medicalDebt += 200 }
        state.finance.financialStress = max(0, state.finance.financialStress - 12)
        state.finance.hardshipExtensionAge = state.character.age
        LifeThreadSystem.stabilize(kind: .debt, amount: 1, state: &state)
    }
}

extension SocialReactivitySystem {
    static func recordContextContact(memberID: String, rapport: Int, state: inout LifeState) {
        guard var member = state.npcs.member(id: memberID) else { return }
        member.rapport += rapport
        member.lastInteractionAge = state.character.age
        member.clamp()
        state.npcs.update(member)
    }

    static func makeAmends(with target: PersonReference, state: inout LifeState) -> (label: String, change: Int, detail: String) {
        let roll = state.randomStreams.social.next(in: 1...100)
        switch target {
        case .partner:
            guard var partner = state.partner else { return ("Bond", 0, "The moment passed.") }
            let chance = min(85, max(20, 45 + partner.personality.current[.empathy] / 4 - partner.resentment / 5))
            let success = roll <= chance
            let oldBond = partner.bond
            partner.bond += success ? 5 : -2
            partner.resentment += success ? -7 : 2
            partner.lastInteractionAge = state.character.age
            partner.clamp()
            state.partner = partner
            return ("Bond", partner.bond - oldBond, success ? "You named the hurt and they heard the effort." : "You tried to repair it, but they were not ready to trust the words.")
        case .cast(let id):
            guard var member = state.npcs.member(id: id) else { return ("Rapport", 0, "The person was no longer reachable.") }
            let chance = min(85, max(20, 45 + member.personality.current[.empathy] / 4 + member.rapport / 6))
            let old = member.rapport
            member.rapport += roll <= chance ? 5 : -2
            member.lastInteractionAge = state.character.age
            member.clamp()
            state.npcs.update(member)
            return ("Rapport", member.rapport - old, roll <= chance ? "You owned your part and they gave the connection another chance." : "The apology landed, but the trust did not return yet.")
        case .family(let id):
            guard let index = state.family.contacts.firstIndex(where: { $0.id == id }) else { return ("Family bond", 0, "The person was no longer reachable.") }
            let old = state.family.contacts[index].bond
            let chance = min(85, max(20, 45 + state.family.contacts[index].personality.current[.empathy] / 4 + (old - 50) / 5))
            state.family.contacts[index].bond += roll <= chance ? 5 : -2
            state.family.contacts[index].lastResolvedAge = state.character.age
            state.family.clamp()
            return ("Family bond", state.family.contacts[index].bond - old, roll <= chance ? "You made room for a harder, more honest conversation." : "The history between you did not loosen in one talk.")
        }
    }

    static func joinFriendInvitation(memberID: String, state: inout LifeState) -> Bool {
        guard var member = state.npcs.member(id: memberID) else { return false }
        let chance = min(90, max(35, 55 + member.rapport / 3 + member.personality.current[.sociability] / 6))
        let welcomed = state.randomStreams.social.next(in: 1...100) <= chance
        member.rapport += welcomed ? 2 : -1
        member.lastInteractionAge = state.character.age
        member.clamp()
        state.npcs.update(member)
        return welcomed
    }
}

enum SuggestedActionSystem {
    static func suggestions(
        in domain: Domain,
        state: LifeState,
        focus: PersonReference?,
        registeredAvailability: (ActionID) -> Availability
    ) -> [ActionSuggestion] {
        var candidates: [ActionSuggestion] = []
        func rankedScore(_ base: Int, key: String, title: String) -> Int {
            let recent = state.history.prefix(5).filter { $0.headline == title }.count
            let priorUses = state.actionUseCount(for: key)
            let personality: Int = switch domain {
            case .school, .cash: (state.personality.current[.drive] - 50) / 10
            case .love: (state.personality.current[.empathy] - 50) / 10
            case .play: (state.personality.current[.sociability] - 50) / 10
            case .health: (state.personality.current[.adaptability] - 50) / 10
            }
            return base + personality - recent * 5 - priorUses * 7
        }
        func offer(_ id: ActionID, score: Int, reason: String) {
            guard registeredAvailability(id) == .available else { return }
            let title = DomainActionRegistry.action(for: id).name
            candidates.append(ActionSuggestion(
                request: .registered(id, target: nil),
                title: title,
                reason: reason,
                score: rankedScore(score, key: id.rawValue, title: title)
            ))
        }
        func context(_ id: ContextActionID, target: PersonReference?, score: Int, reason: String) {
            guard ContextActionSystem.availability(id, target: target, state: state) == .available else { return }
            let title = ContextActionSystem.title(for: id, target: target, state: state)
            candidates.append(ActionSuggestion(
                request: .contextual(id, target: target),
                title: title,
                reason: reason,
                score: rankedScore(score, key: "context:\(id.rawValue)", title: title)
            ))
        }
        switch domain {
        case .school:
            if let teacher = state.npcs[.teacher] {
                context(.teacherHelp, target: .cast(teacher.memberID), score: 80 + max(0, 65 - state.stats.school) / 2, reason: "Grades need support")
            }
            if state.flags.attendsSchool, state.stats.school < 65 { offer(.study, score: 72, reason: "School is slipping") }
            if !state.flags.attendsSchool, state.career.level == .unemployed { offer(.networkContacts, score: 68, reason: "Work needs an opening") }
        case .cash:
            if state.finance.financialStress >= 35 {
                context(.hardshipExtension, target: nil, score: 85 + min(10, state.finance.financialStress / 10), reason: "Debt pressure is rising")
            }
            if state.cash < 2_000 { offer(.workShift, score: 80, reason: "Cash runway is thin") }
            if state.finance.totalDebt > 0 { offer(.payDebt, score: 67, reason: "Debt still has a cost") }
            if state.career.burnout >= 55 { offer(.protectBoundaries, score: 70, reason: "Work is wearing you down") }
        case .love:
            let person = focus ?? (state.partner == nil ? state.npcs.all.first.map { .cast($0.memberID) } : .partner)
            context(.makeAmends, target: person, score: 90, reason: "Repair a strained connection")
            if state.partner != nil { offer(.familyDinner, score: 60, reason: "Make time together") }
            else { offer(.reachOut, score: 55, reason: "Keep a connection alive") }
        case .play:
            let friend = focus ?? state.npcs[.friend].map { .cast($0.memberID) }
            context(.friendInvitation, target: friend, score: 82, reason: "A friend has room for you")
            if state.stats.play < 55 { offer(.pursueHobby, score: 72, reason: "Make room for yourself") }
            if state.stats.love < 55 { offer(.seeFriends, score: 65, reason: "Your social life is thin") }
        case .health:
            if !state.health.conditions.isEmpty {
                context(.adjustCarePlan, target: nil, score: 88, reason: "A condition needs attention")
            }
            if state.stats.health < 55 { offer(.seekCare, score: 78, reason: "Health is under pressure") }
            if state.health.bodyLoad >= 25 { offer(.rest, score: 70, reason: "Your body needs recovery") }
        }
        return Array(candidates.sorted {
            $0.score == $1.score ? $0.id < $1.id : $0.score > $1.score
        }.prefix(3))
    }
}

enum OutcomeSignalSystem {
    static func severity(for deltas: DeltaSummary, isYearly: Bool, state: LifeState) -> OutcomeSeverity {
        if state.isGameOver { return .critical }
        let largest = deltas.semanticLines.map { line in
            line.label == "Cash" ? abs(line.value) / 100 : abs(line.value)
        }.max() ?? 0
        if largest >= 12 || (isYearly && state.lastYearSummary?.importance == .critical) { return .major }
        if largest >= 3 { return .minor }
        return .micro
    }
}

/// Flavor is drawn only after a domain has resolved. It has its own persisted
/// random lane and bounded recent-use memory, so prose never changes outcomes.
enum NarrativeFlavorSystem {
    static func compose(detail: String, key: String, state: inout LifeState) -> String {
        let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return detail }
        let sentenceCount = trimmed.filter { ".!?".contains($0) }.count
        guard sentenceCount < 2 else { return trimmed }
        var pool: [(String, String)] = []
        if state.health.mentalWellbeing < 40 || state.career.burnout >= 65 {
            pool += [("strained-1", "It took more out of you than you expected."),
                     ("strained-2", "Even the useful parts felt heavy.")]
        } else if state.finance.financialStress >= 55 {
            pool += [("money-1", "The cost stayed on your mind."),
                     ("money-2", "You still counted what it cost.")]
        } else if state.personality.current[.drive] >= 65 {
            pool += [("driven-1", "You were already thinking about what comes next."),
                     ("driven-2", "You did not let the moment stand still.")]
        } else {
            pool += [("grounded-1", "The ordinary details made it real."),
                     ("grounded-2", "It stayed with you longer than the moment did.")]
        }
        let available = pool.filter { !state.recentFlavorIDs.contains($0.0) }
        let choices = available.isEmpty ? pool : available
        let selected = choices[state.randomStreams.narrative.next(in: 0...(choices.count - 1))]
        state.rememberFlavor(selected.0)
        return "\(trimmed) \(selected.1)"
    }
}

enum YearMomentQueueSystem {
    static func isStillRelevant(_ event: PresentedEvent, state: LifeState) -> Bool {
        if event.isPartnerEvent && state.partner == nil { return false }
        return event.choices.contains { choice in
            if let memberID = choice.castMemberID, state.npcs.member(id: memberID) == nil { return false }
            if let memberID = choice.secondaryCastMemberID, state.npcs.member(id: memberID) == nil { return false }
            if let contactID = choice.familyContactID,
               !state.family.contacts.contains(where: { $0.id == contactID }) { return false }
            return true
        }
    }
}

// MARK: - State-contingent system registry

enum SimulationSystemID: String, CaseIterable, Hashable {
    case world, education, progression, career, finance, assets, legal, prison, health, influence, mortality, social
}

enum InstantSimulationSystemID: String, CaseIterable, Hashable {
    case effects, narrative, education, progression, influence, personality, social, recovery
}

enum SystemRegistry {
    static let coreSystems: Set<SimulationSystemID> = [.world, .education, .progression, .health, .influence]

    static func isActive(_ system: SimulationSystemID, in state: LifeState) -> Bool {
        if coreSystems.contains(system) { return true }
        switch system {
        case .career, .finance:
            return state.lifeStage != .adolescence
        case .mortality:
            return state.character.age >= LifeLimits.lateLifeStart
        case .social:
            // Lightweight NPCs resolve only when a matching action/event asks
            // for them. The yearly social phase exists solely for partnership
            // drift and must not wake just because a background contact exists.
            return state.partner != nil
        case .assets:
            return !state.assets.properties.isEmpty
        case .legal:
            return state.legal.firearmHeat > 0
                || state.legal.isUnderSupervision
                || AssetSystem.firearmExposure(assets: state.assets, legal: state.legal).totalRisk > 0
        case .prison:
            return state.prison.isIncarcerated
        case .world, .education, .progression, .health, .influence:
            return true
        }
    }

    static func activeSystems(in state: LifeState) -> Set<SimulationSystemID> {
        Set(SimulationSystemID.allCases.filter { isActive($0, in: state) })
    }

    static func activeInstantSystems(for action: DomainAction, in state: LifeState) -> Set<InstantSimulationSystemID> {
        var active: Set<InstantSimulationSystemID> = [.effects, .narrative, .personality]
        if !action.influence.isEmpty { active.insert(.influence) }
        if let recovery = state.recovery {
            let canAffectRecovery = switch recovery.kind {
            case .financial: action.effects.cash != 0...0 || action.domainEffects?.finance != nil
            case .health: action.effects.health != 0...0 || action.domainEffects?.health != nil
            }
            if canAffectRecovery { active.insert(.recovery) }
        }
        if progressionActionIDs.contains(action.id) { active.insert(.progression) }
        if action.domainEffects?.education != nil { active.insert(.education) }
        let partnerRelevant = (state.partner != nil
            && (!action.partnerEffect.isEmpty || !action.personalityBranches.isEmpty))
            || (state.partner == nil && action.effects.gainsPartner)
        let npcRelevant = action.npcRole != nil || !action.npcPersonalityBranches.isEmpty
        if partnerRelevant || npcRelevant {
            active.insert(.social)
        }
        return active
    }

    private static let progressionActionIDs: Set<ActionID> = [
        .study, .attendClass, .joinClub, .skillCourse, .applyToCollege, .returnToEducation,
        .applyForBetterWork, .workShift, .sideHustle
    ]
}

// MARK: - Education (high-school identity and postsecondary footing)

struct EducationYearOutcome: Equatable {
    var deltas = DeltaSummary()
    var bullets: [String] = []
    var milestoneHeadline: String?
    var milestoneDetail: String?
    var graduationTransition: SchoolGraduationTransition?
    var graduationOffers: [PostSchoolOffer] = []
    var followUp: EducationFollowUp?
    var consequences: [DomainConsequence] = []
}

enum EducationTransitionEffect: Codable, Equatable {
    case enroll(CollegeInstitution)
    case enrollAdultCommunity
    case chooseField(CollegeField)
    case choosePath(PostSchoolPath)
    case beginRecovery(EducationRecoveryKind)
    case resumeCollege
    case keepCurrentPath
    case transferToUniversity
    case finishCommunityCollege
    case recoverProbation
    case withdrawFromCollege
}

enum EducationFollowUp: Equatable {
    case chooseField
    case communityCompletion
    case probation
}

struct PostSchoolOffer: Equatable {
    let title: String
    let detail: String
    let transition: EducationTransitionEffect
}

struct EducationTransitionOutcome: Equatable {
    var finance = SchoolFinanceTransition()
    var career = SchoolCareerTransition()
    var headline: String?
    var detail: String?
    var followUp: EducationFollowUp?
}

struct SchoolFinanceTransition: Equatable {
    var studentDebtDelta = 0
    var cashDelta = 0
}

struct SchoolCareerTransition: Equatable {
    var beginsEntryWork = false
    var performanceDelta = 0
    var securityDelta = 0
}

struct SchoolGraduationTransition: Equatable {
    var finance = SchoolFinanceTransition()
    var career = SchoolCareerTransition()
}

struct SchoolLegacyModifiers: Codable, Equatable {
    var studyProgressBonus = 0
    var skillProgressBonus = 0
    var jobSearchChanceDelta = 0
    var socialActionDelta = 0
    var mentorEventWeight = 0
    var secondChanceEventWeight = 0
    var familyObligationEventWeight = 0
    var opportunityAccess = 0
    var socialConfidence = 0
    var burnoutPressure = 0
    var mentorAvailability = 0
    var familyObligationPressure = 0
    var recoveryResilience = 0
    var yearsRemaining = 0

    var isActive: Bool { yearsRemaining > 0 }

    private enum CodingKeys: String, CodingKey {
        case studyProgressBonus, skillProgressBonus, jobSearchChanceDelta, socialActionDelta
        case mentorEventWeight, secondChanceEventWeight, familyObligationEventWeight
        case opportunityAccess, socialConfidence, burnoutPressure, mentorAvailability
        case familyObligationPressure, recoveryResilience, yearsRemaining
    }

    init(
        studyProgressBonus: Int = 0,
        skillProgressBonus: Int = 0,
        jobSearchChanceDelta: Int = 0,
        socialActionDelta: Int = 0,
        mentorEventWeight: Int = 0,
        secondChanceEventWeight: Int = 0,
        familyObligationEventWeight: Int = 0,
        opportunityAccess: Int = 0,
        socialConfidence: Int = 0,
        burnoutPressure: Int = 0,
        mentorAvailability: Int = 0,
        familyObligationPressure: Int = 0,
        recoveryResilience: Int = 0,
        yearsRemaining: Int = 0
    ) {
        self.studyProgressBonus = studyProgressBonus
        self.skillProgressBonus = skillProgressBonus
        self.jobSearchChanceDelta = jobSearchChanceDelta
        self.socialActionDelta = socialActionDelta
        self.mentorEventWeight = mentorEventWeight
        self.secondChanceEventWeight = secondChanceEventWeight
        self.familyObligationEventWeight = familyObligationEventWeight
        self.opportunityAccess = opportunityAccess
        self.socialConfidence = socialConfidence
        self.burnoutPressure = burnoutPressure
        self.mentorAvailability = mentorAvailability
        self.familyObligationPressure = familyObligationPressure
        self.recoveryResilience = recoveryResilience
        self.yearsRemaining = yearsRemaining
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            studyProgressBonus: try c.decodeIfPresent(Int.self, forKey: .studyProgressBonus) ?? 0,
            skillProgressBonus: try c.decodeIfPresent(Int.self, forKey: .skillProgressBonus) ?? 0,
            jobSearchChanceDelta: try c.decodeIfPresent(Int.self, forKey: .jobSearchChanceDelta) ?? 0,
            socialActionDelta: try c.decodeIfPresent(Int.self, forKey: .socialActionDelta) ?? 0,
            mentorEventWeight: try c.decodeIfPresent(Int.self, forKey: .mentorEventWeight) ?? 0,
            secondChanceEventWeight: try c.decodeIfPresent(Int.self, forKey: .secondChanceEventWeight) ?? 0,
            familyObligationEventWeight: try c.decodeIfPresent(Int.self, forKey: .familyObligationEventWeight) ?? 0,
            opportunityAccess: try c.decodeIfPresent(Int.self, forKey: .opportunityAccess) ?? 0,
            socialConfidence: try c.decodeIfPresent(Int.self, forKey: .socialConfidence) ?? 0,
            burnoutPressure: try c.decodeIfPresent(Int.self, forKey: .burnoutPressure) ?? 0,
            mentorAvailability: try c.decodeIfPresent(Int.self, forKey: .mentorAvailability) ?? 0,
            familyObligationPressure: try c.decodeIfPresent(Int.self, forKey: .familyObligationPressure) ?? 0,
            recoveryResilience: try c.decodeIfPresent(Int.self, forKey: .recoveryResilience) ?? 0,
            yearsRemaining: try c.decodeIfPresent(Int.self, forKey: .yearsRemaining) ?? 0
        )
    }
}

struct EducationCredentialModifiers: Equatable {
    let kind: EducationCredentialKind
    let field: CollegeField?

    func jobSearchDelta(for track: CareerTrack) -> Int {
        let base: Int = switch kind {
        case .bachelorsDegree: 3
        case .associateDegree: 2
        case .professionalCertificate, .alternativeCredential, .legacyCredential: 1
        case .none: 0
        }
        guard let field else { return base }
        let matches: Bool = switch field {
        case .appliedTechnical: track == .office || track == .trades
        case .business: track == .office || track == .freelance
        case .peopleCreative: track == .careService || track == .freelance
        case .generalStudies: false
        }
        return base + (matches ? (kind == .bachelorsDegree ? 3 : 2) : 0)
    }

    var promotionDelta: Int {
        switch kind {
        case .bachelorsDegree: 4
        case .associateDegree: 2
        case .professionalCertificate, .alternativeCredential, .legacyCredential: 1
        case .none: 0
        }
    }
}

struct EducationChoiceEffect: Codable, Equatable {
    var academicStanding = 0
    var schoolBelonging = 0
    var teacherSupport = 0
    var futureReadiness = 0
    var schoolReputation = 0
    var activityStage: SchoolActivityStage? = nil
    var memoryKind: SchoolMemoryKind? = nil
    var memorySignificance = 0
    var flagsToAdd: Set<SchoolLegacyFlag>? = nil
    var collegeStanding = 0
    var campusBelonging = 0

    var isEmpty: Bool {
        academicStanding == 0 && schoolBelonging == 0 && teacherSupport == 0 && futureReadiness == 0
            && schoolReputation == 0 && activityStage == nil && memoryKind == nil && memorySignificance == 0
            && (flagsToAdd?.isEmpty ?? true) && collegeStanding == 0 && campusBelonging == 0
    }
}

extension EducationChoiceEffect {
    private enum CodingKeys: String, CodingKey {
        case academicStanding, schoolBelonging, teacherSupport, futureReadiness
        case schoolReputation, activityStage, memoryKind, memorySignificance, flagsToAdd
        case collegeStanding, campusBelonging
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        academicStanding = try c.decodeIfPresent(Int.self, forKey: .academicStanding) ?? 0
        schoolBelonging = try c.decodeIfPresent(Int.self, forKey: .schoolBelonging) ?? 0
        teacherSupport = try c.decodeIfPresent(Int.self, forKey: .teacherSupport) ?? 0
        futureReadiness = try c.decodeIfPresent(Int.self, forKey: .futureReadiness) ?? 0
        schoolReputation = try c.decodeIfPresent(Int.self, forKey: .schoolReputation) ?? 0
        activityStage = try c.decodeIfPresent(SchoolActivityStage.self, forKey: .activityStage)
        memoryKind = try c.decodeIfPresent(SchoolMemoryKind.self, forKey: .memoryKind)
        memorySignificance = try c.decodeIfPresent(Int.self, forKey: .memorySignificance) ?? 0
        flagsToAdd = try c.decodeIfPresent(Set<SchoolLegacyFlag>.self, forKey: .flagsToAdd)
        collegeStanding = try c.decodeIfPresent(Int.self, forKey: .collegeStanding) ?? 0
        campusBelonging = try c.decodeIfPresent(Int.self, forKey: .campusBelonging) ?? 0
    }
}

enum EducationSystem {
    private static let schoolEventIDs: Set<String> = [
        "freshman-lunch-table", "bullying-line-crossed", "sophomore-name-sticks", "school-date-invitation",
        "discipline-office", "junior-future-pressure", "part-time-school-week", "family-needs-school-hours",
        "activity-injury", "academic-burnout-week", "senior-last-night", "prom-cost",
        "activity-leadership", "activity-pushed-out", "hallway-rumor", "teacher-stays-late",
        "school-trip-cost", "activity-tryout", "friend-group-fracture", "recommendation-window"
    ]

    static func schoolEnvironment(for runSeed: UInt64) -> SchoolEnvironment {
        var mixed = runSeed &+ 0x9E3779B97F4A7C15
        mixed ^= mixed >> 30
        mixed &*= 0xBF58476D1CE4E5B9
        mixed ^= mixed >> 27
        mixed &*= 0x94D049BB133111EB
        mixed ^= mixed >> 31
        return SchoolEnvironment.allCases[Int(mixed % UInt64(SchoolEnvironment.allCases.count))]
    }

    static func generatedActivity(for state: LifeState) -> SchoolActivity {
        if state.personality.talent == .athletic { return .athletics }
        if state.personality.talent == .publicLeadership { return .service }
        if state.personality.current.drive >= 65 { return .academicTeam }
        if state.personality.current.sociability >= 60 { return .arts }
        let choices: [SchoolActivity] = [.athletics, .arts, .service, .academicTeam]
        return choices[Int((state.runSeed ^ 0x5343484F4F4C) % UInt64(choices.count))]
    }

    static func currentSchoolPressure(for state: LifeState) -> String {
        let education = state.education
        switch education.schoolEnvironment {
        case .competitive where education.academicStanding < 60:
            return "Keeping up in a competitive school"
        case .underfunded where state.cash < 22000:
            return "Making do with less"
        case .closeKnit where education.schoolReputation < 40:
            return "Everyone knowing the same story"
        case .affluent where state.cash < 26000:
            return "The cost of fitting in"
        case .chaotic where education.schoolBelonging < 50:
            return "Staying out of the crossfire"
        default:
            break
        }
        switch min(3, max(0, state.character.age - 14)) {
        case 0:
            return education.schoolBelonging < 45 ? "Finding a place" : "Learning the social map"
        case 1:
            return education.schoolReputation < 40 ? "A reputation sticking" : "Deciding who to be"
        case 2:
            return education.academicStanding < 50 ? "Keeping the future open" : "Pressure about what comes next"
        default:
            return education.futureReadiness < 50 ? "Leaving without a clear map" : "Endings and next steps"
        }
    }

    static func primarySchoolRelationship(for state: LifeState) -> String {
        let peer = state.npcs[.friend]
        let adult = state.npcs[.teacher]
        if let peer, abs(peer.rapport) >= max(8, abs(adult?.rapport ?? 0)) {
            return "\(peer.rapport < 0 ? "Rival" : "Friend") · \(peer.name)"
        }
        if let adult {
            let role = state.education.activityStage == .leader || state.education.activityStage == .committed
                ? "Coach" : "Mentor"
            return "\(role) · \(adult.name)"
        }
        return "No defining relationship yet"
    }

    static func schoolEventWeight(eventID: String, baseWeight: Int, state: LifeState) -> Int {
        guard state.education.phase == .highSchool, state.lifeStage == .adolescence,
              schoolEventIDs.contains(eventID), baseWeight > 0 else { return baseWeight }
        var weight = baseWeight
        let grade = HighSchoolYear.allCases.firstIndex(of: state.education.highSchoolYear(for: state.character.age)) ?? 0
        let gradeEvents: [[String]] = [
            ["freshman-lunch-table", "bullying-line-crossed", "teacher-stays-late"],
            ["sophomore-name-sticks", "school-date-invitation", "hallway-rumor", "discipline-office"],
            ["junior-future-pressure", "part-time-school-week", "family-needs-school-hours", "activity-injury", "academic-burnout-week"],
            ["senior-last-night", "prom-cost", "recommendation-window", "activity-leadership"]
        ]
        if gradeEvents[grade].contains(eventID) { weight += 4 }

        let environmentEvents: [SchoolEnvironment: Set<String>] = [
            .competitive: ["junior-future-pressure", "academic-burnout-week", "recommendation-window", "activity-leadership"],
            .underfunded: ["school-trip-cost", "prom-cost", "part-time-school-week", "family-needs-school-hours", "discipline-office"],
            .closeKnit: ["freshman-lunch-table", "friend-group-fracture", "school-date-invitation", "teacher-stays-late", "senior-last-night"],
            .affluent: ["prom-cost", "school-trip-cost", "recommendation-window", "sophomore-name-sticks"],
            .chaotic: ["hallway-rumor", "bullying-line-crossed", "discipline-office", "activity-pushed-out", "friend-group-fracture"]
        ]
        if environmentEvents[state.education.schoolEnvironment]?.contains(eventID) == true { weight += 3 }
        if state.education.schoolReputation >= 65,
           ["school-date-invitation", "activity-leadership", "senior-last-night"].contains(eventID) { weight += 2 }
        if state.education.schoolReputation < 40,
           ["hallway-rumor", "bullying-line-crossed", "discipline-office", "sophomore-name-sticks"].contains(eventID) { weight += 2 }
        if state.education.activityStage == .joined || state.education.activityStage == .committed,
           ["activity-tryout", "activity-leadership", "activity-injury", "activity-pushed-out"].contains(eventID) { weight += 2 }
        if let friend = state.npcs[.friend], friend.rapport < -8,
           ["hallway-rumor", "bullying-line-crossed", "friend-group-fracture"].contains(eventID) { weight += 2 }
        if let teacher = state.npcs[.teacher], teacher.rapport >= 8,
           ["teacher-stays-late", "recommendation-window", "junior-future-pressure"].contains(eventID) { weight += 2 }
        return weight
    }

    static func resolve(_ effect: EducationActionEffect, state: inout LifeState) -> DomainActionResolution {
        var result = DomainActionResolution()
        guard state.education.phase == .highSchool, state.education.commitment == nil else { return result }
        switch effect {
        case .openCollegeOffers, .openRecoveryOffers:
            break
        case .focusGrades:
            state.education.commitment = .academics
            apply(EducationChoiceEffect(academicStanding: 8, teacherSupport: 2, futureReadiness: 5), state: &state)
            result.headline = "Grades Became The Priority"
            result.detail = "You organized the year around the transcript. The work is visible; so is the cost."
        case .findYourPeople:
            state.education.commitment = .belonging
            apply(EducationChoiceEffect(schoolBelonging: 10, futureReadiness: 1, schoolReputation: 3), state: &state)
            result.headline = "You Chose To Be Known"
            result.detail = "The social map still shifts, but you are no longer standing outside it."
        case .commitActivity:
            guard state.education.activityStage != .ended else { return result }
            state.education.commitment = .activity
            if state.education.activity == .none {
                state.education.activity = generatedActivity(for: state)
                state.education.activityStage = .joined
            } else if state.education.activityStage == .joined {
                state.education.activityStage = .committed
            }
            apply(EducationChoiceEffect(academicStanding: 1, schoolBelonging: 7, futureReadiness: 5, schoolReputation: 2), state: &state)
            result.headline = "Something After School Became Yours"
            result.detail = "The commitment takes time and gives your week an identity."
        case .helpAtHome:
            state.education.commitment = .home
            apply(EducationChoiceEffect(academicStanding: -4, schoolBelonging: -2, futureReadiness: -1), state: &state)
            result.headline = "Home Needed More From You"
            result.detail = "You carried real responsibility that the school record will never fully explain."
        }
        state.education.clamp()
        return result
    }

    static func apply(_ effect: EducationChoiceEffect?, state: inout LifeState) {
        guard let effect, !effect.isEmpty else { return }
        state.education.academicStanding += effect.academicStanding
        state.education.schoolBelonging += effect.schoolBelonging
        state.education.teacherSupport += effect.teacherSupport
        state.education.futureReadiness += effect.futureReadiness
        state.education.schoolReputation += effect.schoolReputation
        if let activityStage = effect.activityStage { state.education.activityStage = activityStage }
        state.education.legacyFlags.formUnion(effect.flagsToAdd ?? [])
        state.education.college.academicStanding += effect.collegeStanding
        state.education.college.campusBelonging += effect.campusBelonging
        state.education.clamp()
    }

    static func recordSchoolChoice(event: PresentedEvent, choice: EventChoice, state: inout LifeState) {
        guard state.education.phase == .highSchool,
              let kind = choice.educationEffect?.memoryKind else { return }
        let memory = SchoolMemory(
            eventID: event.id,
            headline: event.headline,
            choiceID: choice.id,
            choiceTitle: choice.title,
            age: state.character.age,
            kind: kind,
            significance: min(5, max(1, choice.educationEffect?.memorySignificance ?? 1))
        )
        state.education.schoolMemories.removeAll { $0.eventID == memory.eventID }
        state.education.schoolMemories.append(memory)
        state.education.clamp()
    }

    static func resolveYear(state: inout LifeState) -> EducationYearOutcome {
        var outcome = EducationYearOutcome()
        guard state.education.phase == .highSchool else {
            state.education.launchInfluenceYearsRemaining = state.character.age >= 18 && state.character.age <= 24
                ? max(0, 25 - state.character.age)
                : 0
            if state.education.college.isEnrolled {
                return resolveCollegeYear(state: &state)
            }
            if state.education.recovery.isActive {
                return resolveRecoveryYear(state: &state)
            }
            return outcome
        }
        let completedGrade = min(12, max(9, state.character.age - 6))
        let commitment = state.education.commitment
        if let commitment {
            state.education.commitmentYears[commitment, default: 0] += 1
        }
        switch commitment {
        case .academics:
            apply(EducationChoiceEffect(academicStanding: 4, schoolBelonging: -2, teacherSupport: 2, futureReadiness: 5), state: &state)
            outcome.deltas = DeltaSummary(health: -1)
        case .belonging:
            apply(EducationChoiceEffect(academicStanding: -1, schoolBelonging: 5, futureReadiness: 1), state: &state)
            outcome.deltas = DeltaSummary(love: 2, play: 1)
        case .activity:
            apply(EducationChoiceEffect(academicStanding: 1, schoolBelonging: 4, teacherSupport: 1, futureReadiness: 4), state: &state)
            outcome.deltas = DeltaSummary(play: 1, health: -1, rep: 1)
        case .home:
            apply(EducationChoiceEffect(academicStanding: -4, schoolBelonging: -2, futureReadiness: -1, flagsToAdd: [.carriedHomeLoad]), state: &state)
            outcome.deltas = DeltaSummary(cash: 2500, play: -2, health: -1)
        case nil:
            apply(EducationChoiceEffect(academicStanding: -6, schoolBelonging: -2, teacherSupport: -1, futureReadiness: -3), state: &state)
            outcome.deltas = DeltaSummary(play: 1)
        }
        outcome.bullets.append("Completed grade \(completedGrade)")
        outcome.bullets.append("Grades \(state.education.academicStanding) · belonging \(state.education.schoolBelonging) · future \(state.education.futureReadiness)")
        state.education.commitment = nil

        guard state.character.age >= 18 else { return outcome }
        let diploma = state.education.academicStanding >= 45
        state.education.highSchoolDiploma = diploma
        var transition = SchoolGraduationTransition()
        state.education.postSchoolPath = .undecided
        state.education.phase = .awaitingDecision
        state.flags.attendsSchool = false
        outcome.milestoneHeadline = diploma ? "High School Is Behind You" : "High School Did Not End Cleanly"
        outcome.milestoneDetail = diploma
            ? "Your record created real options. None of them chooses the life for you."
            : "You leave without the standard diploma. The detour is real, but work and a second chance remain open."
        finalizeLegacy(state: &state, transition: &transition)
        if state.education.legacyFlags.contains(.academicBurnout) {
            outcome.consequences.append(DomainConsequence(
                source: .education,
                target: .health,
                kind: .burnout,
                magnitude: .minor,
                openedAge: state.character.age,
                yearsRemaining: 4,
                headline: "Achievement Left A Health Cost",
                detail: "The record is strong, but the pressure you carried into graduation may still need recovery."
            ))
        }
        if state.education.legacyFlags.contains(.carriedHomeLoad) {
            outcome.consequences.append(DomainConsequence(
                source: .education,
                target: .family,
                kind: .familyConflict,
                magnitude: .minor,
                openedAge: state.character.age,
                yearsRemaining: 4,
                headline: "Home Still Counts On You",
                detail: "Responsibility learned in school can keep following you after the schedule changes."
            ))
        }
        outcome.graduationOffers = graduationOffers(for: state)
        outcome.graduationTransition = transition
        outcome.bullets.append("High school: \(diploma ? "diploma earned" : "alternative path")")
        outcome.bullets.append("Post-school decision waiting")
        if !diploma {
            outcome.consequences.append(DomainConsequence(
                source: .education,
                target: .career,
                kind: .majorDecision,
                magnitude: .major,
                openedAge: state.character.age,
                yearsRemaining: 5,
                headline: "Leaving School Narrowed The First Doors",
                detail: "Work remains possible, but the missing credential will shape early applications until you recover it."
            ))
        }
        return outcome
    }

    static func graduationOffers(for state: LifeState) -> [PostSchoolOffer] {
        guard state.education.highSchoolDiploma else {
            return [
                PostSchoolOffer(title: "Pursue an alternative credential", detail: "Keep a second-chance route alive.", transition: .choosePath(.alternativeCredential)),
                PostSchoolOffer(title: "Start working", detail: "Take immediate entry-level footing.", transition: .choosePath(.work)),
                PostSchoolOffer(title: "Stay undecided", detail: "Leave without inventing a permanent answer.", transition: .choosePath(.undecided))
            ]
        }
        let backed = state.education.teacherSupport >= 55
            || state.education.legacyFlags.contains(.recommendationEarned)
            || state.education.legacyFlags.contains(.mentorBacked)
        let scholarship = state.education.academicStanding >= 75
            && state.education.futureReadiness >= 70 && backed
        let publicQualified = state.education.academicStanding >= 55
            && state.education.futureReadiness >= 50
        let primary: PostSchoolOffer
        if scholarship {
            primary = PostSchoolOffer(title: "Take the scholarship", detail: "Begin university with two credits and minimal annual debt.", transition: .enroll(.scholarshipUniversity))
        } else if publicQualified {
            primary = PostSchoolOffer(title: "Choose public university", detail: "Take the direct degree route and its yearly cost.", transition: .enroll(.publicUniversity))
        } else {
            primary = PostSchoolOffer(title: "Choose community college", detail: "Start locally with a shorter credential target.", transition: .enroll(.communityCollege))
        }
        let alternatePath: PostSchoolPath = state.education.commitmentYears[.activity, default: 0] > 0
            ? .training : .work
        var offers = [primary]
        if primary.transition != .enroll(.communityCollege) {
            offers.append(PostSchoolOffer(title: "Start at community college", detail: "Take the lower-cost route with transfer still possible.", transition: .enroll(.communityCollege)))
        }
        offers.append(PostSchoolOffer(
            title: alternatePath == .training ? "Choose practical training" : "Start working",
            detail: alternatePath == .training ? "Build skills outside a degree track." : "Take immediate entry-level footing.",
            transition: .choosePath(alternatePath)
        ))
        if offers.count < 3 {
            offers.append(PostSchoolOffer(
                title: "Stay undecided",
                detail: "Keep every route open without adding debt.",
                transition: .choosePath(.undecided)
            ))
        }
        return Array(offers.prefix(3))
    }

    static func collegeOffers(for state: LifeState) -> [PostSchoolOffer] {
        guard state.education.highSchoolDiploma || state.education.hasAlternativeCredential,
              state.character.age <= 24 else { return [] }
        let publicQualified = state.education.academicStanding >= 55 && state.education.futureReadiness >= 50
        var offers: [PostSchoolOffer] = []
        if publicQualified {
            offers.append(PostSchoolOffer(title: "Enter public university", detail: "$45 student debt per enrolled year.", transition: .enroll(.publicUniversity)))
        }
        offers.append(PostSchoolOffer(title: "Enter community college", detail: "$20 student debt per enrolled year.", transition: .enroll(.communityCollege)))
        offers.append(PostSchoolOffer(title: "Keep your current path", detail: "Do not enroll this year.", transition: .keepCurrentPath))
        return Array(offers.prefix(3))
    }

    static func recoveryOffers(for state: LifeState) -> [PostSchoolOffer] {
        var offers: [PostSchoolOffer] = []
        if state.education.college.status == .withdrawn,
           state.education.college.institution != nil {
            offers.append(PostSchoolOffer(
                title: "Resume college",
                detail: "Keep every earned credit and the debt already created.",
                transition: .resumeCollege
            ))
        } else if state.education.highSchoolDiploma || state.education.hasAlternativeCredential {
            offers.append(PostSchoolOffer(
                title: "Enter community college",
                detail: "Start or restart a degree at the lower annual cost.",
                transition: .enrollAdultCommunity
            ))
        } else {
            offers.append(PostSchoolOffer(
                title: "Earn an alternative credential",
                detail: "Complete one short second-chance track without annual debt.",
                transition: .beginRecovery(.alternativeCredential)
            ))
        }
        if state.education.credentialKind != .professionalCertificate {
            offers.append(PostSchoolOffer(
                title: "Earn a technical certificate",
                detail: "Take a shorter applied route with $10 annual debt.",
                transition: .beginRecovery(.technicalCertificate)
            ))
        }
        offers.append(PostSchoolOffer(
            title: "Keep your current path",
            detail: "Leave the record open without enrolling now.",
            transition: .keepCurrentPath
        ))
        return Array(offers.prefix(3))
    }

    static func resolve(_ transition: EducationTransitionEffect, state: inout LifeState) -> EducationTransitionOutcome {
        var outcome = EducationTransitionOutcome()
        switch transition {
        case .enroll(let institution):
            state.education.college = CollegeState(
                status: .awaitingField,
                institution: institution,
                credits: institution == .scholarshipUniversity ? 2 : (institution == .publicUniversity ? 1 : 0),
                academicStanding: min(80, max(40, (state.education.academicStanding + state.education.futureReadiness) / 2)),
                campusBelonging: state.education.schoolBelonging
            )
            state.education.progress = state.education.college.credits
            state.education.phase = .postsecondary
            state.education.postSchoolPath = institution == .scholarshipUniversity ? .scholarship : .college
            state.flags.attendsSchool = true
            outcome.headline = "College Became A Real Commitment"
            outcome.detail = "The offer is accepted. Now you have to decide what the work is for."
            outcome.followUp = .chooseField
        case .enrollAdultCommunity:
            state.education.college = CollegeState(
                status: .awaitingField,
                institution: .communityCollege,
                academicStanding: min(70, max(45, state.stats.school)),
                campusBelonging: 45,
                adultReentryAge: state.character.age
            )
            state.education.recovery = EducationRecoveryState()
            state.education.phase = .postsecondary
            state.education.postSchoolPath = .college
            state.flags.attendsSchool = true
            outcome.headline = "School Became Possible Again"
            outcome.detail = "Community college begins with a clean schedule, not a clean history."
            outcome.followUp = .chooseField
        case .chooseField(let field):
            guard state.education.college.status == .awaitingField else { break }
            state.education.college.field = field
            state.education.college.status = .enrolled
            outcome.headline = "You Chose A Direction"
            outcome.detail = "\(field.title) becomes the center of the degree without deciding every job that follows."
        case .choosePath(let path):
            state.education.postSchoolPath = path
            state.education.phase = .leftSchool
            state.flags.attendsSchool = false
            switch path {
            case .training:
                outcome.career.performanceDelta = 5
                outcome.career.securityDelta = 8
            case .work:
                outcome.finance.cashDelta = EconomyPolicy.dollars(75)
                outcome.career.beginsEntryWork = true
                outcome.career.securityDelta = 5
            case .alternativeCredential:
                beginRecovery(.alternativeCredential, state: &state)
            case .undecided, .scholarship, .college:
                break
            }
            outcome.headline = "You Chose \(path.title)"
            outcome.detail = "The choice creates footing, not a permanent lock."
        case .beginRecovery(let kind):
            beginRecovery(kind, state: &state)
            outcome.headline = "A Second Chance Became Concrete"
            outcome.detail = "\(kind.title) is one short progress track. Study or attend class; no separate course ledger appears."
        case .resumeCollege:
            guard state.education.college.status == .withdrawn,
                  state.education.college.institution != nil else { break }
            state.education.college.status = .enrolled
            state.education.college.academicStanding = max(45, state.education.college.academicStanding)
            state.education.college.lastTuitionAge = nil
            state.education.college.adultReentryAge = state.character.age
            state.education.recovery = EducationRecoveryState()
            state.education.phase = .postsecondary
            state.flags.attendsSchool = true
            outcome.headline = "Your Credits Were Still There"
            outcome.detail = "The old credits and debt remain. A narrower schedule gives the degree another chance."
        case .keepCurrentPath:
            outcome.headline = "You Kept Your Current Path"
            outcome.detail = "The application closes without rewriting the footing you already built."
        case .transferToUniversity:
            state.education.college.institution = .publicUniversity
            state.education.college.status = .enrolled
            state.education.college.lastTuitionAge = nil
            state.education.phase = .postsecondary
            state.education.postSchoolPath = .college
            state.flags.attendsSchool = true
            outcome.headline = "Your Credits Moved With You"
            outcome.detail = "Eight credits transfer. The bachelor’s target and the higher yearly cost are now real."
        case .finishCommunityCollege:
            state.education.college.status = .completed
            state.education.phase = .leftSchool
            state.flags.attendsSchool = false
            outcome.headline = "The Associate Degree Is Yours"
            outcome.detail = "You leave college with a completed credential and the debt already created."
        case .recoverProbation:
            state.education.college.status = .enrolled
            state.education.college.academicStanding += 8
            outcome.headline = "You Stayed In The Program"
            outcome.detail = "The plan is narrower now, but the degree remains recoverable."
        case .withdrawFromCollege:
            state.education.college.status = .withdrawn
            state.education.phase = .leftSchool
            state.flags.attendsSchool = false
            outcome.headline = "You Stepped Away From College"
            outcome.detail = "The credits and debt remain. The unfinished degree does not become an invented credential."
        }
        state.education.clamp()
        return outcome
    }

    private static func beginRecovery(_ kind: EducationRecoveryKind, state: inout LifeState) {
        state.education.recovery = EducationRecoveryState(
            status: .active,
            kind: kind,
            startedAge: state.character.age
        )
        state.education.phase = .postsecondary
        state.education.postSchoolPath = kind == .alternativeCredential ? .alternativeCredential : .training
        state.flags.attendsSchool = true
    }

    static func credentialModifiers(for state: LifeState) -> EducationCredentialModifiers {
        EducationCredentialModifiers(kind: state.education.credentialKind, field: state.education.credentialField)
    }

    static func offerEvent(
        id: String,
        headline: String,
        detail: String,
        offers: [PostSchoolOffer]
    ) -> LifeEvent {
        let ids: [EventChoiceID] = [.focus, .accept, .decline]
        return LifeEvent(
            id: id,
            headline: headline,
            detail: detail,
            weight: { _ in 0 },
            choices: zip(ids, offers.prefix(3)).map { choiceID, offer in
                EventChoice(
                    id: choiceID,
                    title: offer.title,
                    detail: offer.detail,
                    effects: EffectRange(),
                    partnerEffect: PartnerEffect(),
                    narrative: offer.detail,
                    educationTransitionEffect: offer.transition
                )
            }
        )
    }

    static func followUpEvent(_ followUp: EducationFollowUp, state: LifeState) -> LifeEvent {
        switch followUp {
        case .chooseField:
            let ids: [EventChoiceID] = [.focus, .accept, .decline]
            return LifeEvent(
                id: "college-field-\(state.character.age)",
                headline: "Choose What You Will Study",
                detail: "A field changes which doors open more easily. It does not decide your whole career.",
                weight: { _ in 0 },
                choices: zip(ids, CollegeField.playerChoices).map { choiceID, field in
                    EventChoice(
                        id: choiceID,
                        title: field.title,
                        detail: "Build a credential around \(field.title.lowercased()).",
                        effects: EffectRange(),
                        partnerEffect: PartnerEffect(),
                        narrative: "You choose \(field.title.lowercased()) and accept the work that comes with it.",
                        educationTransitionEffect: .chooseField(field)
                    )
                }
            )
        case .communityCompletion:
            return LifeEvent(
                id: "community-completion-\(state.character.age)",
                headline: "Your Associate Degree Is Complete",
                detail: "Eight credits became a credential. Every credit can move with you, but the next cost is larger.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(id: .accept, title: "Enter adult life", detail: "Leave college with the completed degree.", effects: EffectRange(), partnerEffect: PartnerEffect(), narrative: "You leave with a real credential and the debt already created.", educationTransitionEffect: .finishCommunityCollege),
                    EventChoice(id: .focus, title: "Transfer every credit", detail: "Continue toward a bachelor’s degree at public-university cost.", effects: EffectRange(), partnerEffect: PartnerEffect(), narrative: "The credits transfer. The larger target and cost begin now.", educationTransitionEffect: .transferToUniversity)
                ]
            )
        case .probation:
            return LifeEvent(
                id: "college-probation-\(state.character.age)",
                headline: "College Put You On Probation",
                detail: "The record is slipping. The degree is still recoverable, but pretending otherwise is no longer an option.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(id: .focus, title: "Narrow the plan", detail: "Accept support and stay enrolled.", effects: EffectRange(health: -1...0), partnerEffect: PartnerEffect(), narrative: "The plan gets smaller and more honest.", educationTransitionEffect: .recoverProbation),
                    EventChoice(id: .decline, title: "Withdraw", detail: "Stop adding tuition before the record gets worse.", effects: EffectRange(play: 1...2), partnerEffect: PartnerEffect(), narrative: "The credits and debt remain after the schedule disappears.", educationTransitionEffect: .withdrawFromCollege)
                ]
            )
        }
    }

    private static func resolveCollegeYear(state: inout LifeState) -> EducationYearOutcome {
        var outcome = EducationYearOutcome()
        guard state.education.college.status != .awaitingField else { return outcome }
        if state.character.age >= 25, state.education.college.adultReentryAge == nil {
            state.education.college.status = .withdrawn
            state.education.phase = .leftSchool
            state.flags.attendsSchool = false
            outcome.milestoneHeadline = "College Time Ran Out"
            outcome.milestoneDetail = "The credits remain on the record. No degree appears where the work did not finish."
            outcome.bullets.append("Left college with \(state.education.college.credits) credits")
            return outcome
        }
        guard let institution = state.education.college.institution else { return outcome }
        if state.education.college.lastTuitionAge != state.character.age {
            state.education.college.lastTuitionAge = state.character.age
            state.education.college.yearsEnrolled += 1
            var transition = SchoolGraduationTransition()
            transition.finance.studentDebtDelta = institution.annualDebt
            outcome.graduationTransition = transition
            outcome.bullets.append("College cost added $\(institution.annualDebt) student debt")
        }
        let priorAge = state.character.age - 1
        let studied = state.actionUsage[ActionID.study.rawValue] == priorAge
        let attended = state.actionUsage[ActionID.attendClass.rawValue] == priorAge
        if studied && attended {
            state.education.college.academicStanding += 4
        } else if !studied && !attended {
            state.education.college.academicStanding -= 8
        }
        state.education.college.clamp()
        state.education.progress = state.education.college.credits
        if state.education.college.credits >= institution.creditTarget,
           state.education.college.academicStanding >= 50 {
            state.education.credential = true
            state.education.credentialField = state.education.college.field
            state.education.college.status = .completed
            state.education.phase = .leftSchool
            state.flags.attendsSchool = false
            if institution == .communityCollege {
                state.education.credentialKind = .associateDegree
                outcome.milestoneHeadline = "Your Associate Degree Is Complete"
                outcome.milestoneDetail = "Eight credits became a real credential. You can enter adult life or transfer every credit."
                outcome.followUp = .communityCompletion
            } else {
                state.education.credentialKind = .bachelorsDegree
                outcome.milestoneHeadline = "You Finished The Degree"
                outcome.milestoneDetail = "The bachelor’s degree is real. The field helps, but it does not guarantee the life after it."
            }
            outcome.deltas.rep += institution == .communityCollege ? 1 : 2
        } else if state.education.college.academicStanding < 40 {
            state.education.college.status = .probation
            outcome.milestoneHeadline = "College Put You On Probation"
            outcome.milestoneDetail = "The record is slipping. You can narrow the plan, or leave before more debt accumulates."
            outcome.followUp = .probation
        }
        return outcome
    }

    private static func resolveRecoveryYear(state: inout LifeState) -> EducationYearOutcome {
        var outcome = EducationYearOutcome()
        guard let kind = state.education.recovery.kind else { return outcome }
        if state.education.recovery.lastCostAge != state.character.age {
            state.education.recovery.lastCostAge = state.character.age
            if kind.annualDebt > 0 {
                var transition = SchoolGraduationTransition()
                transition.finance.studentDebtDelta = kind.annualDebt
                outcome.graduationTransition = transition
                outcome.bullets.append("Education cost added $\(kind.annualDebt) student debt")
            }
        }
        outcome.bullets.append("\(kind.title): \(state.education.recovery.progress)/\(kind.target)")
        guard state.education.recovery.progress >= kind.target else { return outcome }

        state.education.recovery.status = .completed
        state.education.phase = .leftSchool
        state.flags.attendsSchool = false
        state.education.credential = true
        switch kind {
        case .alternativeCredential:
            if state.education.credentialKind == .none || state.education.credentialKind == .legacyCredential {
                state.education.credentialKind = .alternativeCredential
            }
            outcome.milestoneHeadline = "Your Second Chance Became Official"
            outcome.milestoneDetail = "The alternative credential is complete. Community college is now a real option, not an invented guarantee."
        case .technicalCertificate:
            if state.education.credentialKind != .associateDegree && state.education.credentialKind != .bachelorsDegree {
                state.education.credentialKind = .professionalCertificate
                state.education.credentialField = .appliedTechnical
            }
            outcome.milestoneHeadline = "The Technical Certificate Is Yours"
            outcome.milestoneDetail = "A short applied credential is complete. It helps matching work without locking every other route."
        }
        outcome.deltas.rep = 1
        state.education.clamp()
        return outcome
    }

    static func legacyModifiers(for state: LifeState) -> SchoolLegacyModifiers {
        let education = state.education
        let years = education.launchInfluenceYearsRemaining
        guard (18...24).contains(state.character.age), years > 0,
              education.hasSchoolLegacy, let snapshot = education.legacySnapshot else {
            return SchoolLegacyModifiers()
        }
        func scaled(_ value: Int) -> Int {
            Int((Double(value) * Double(years) / 7.0).rounded())
        }
        return SchoolLegacyModifiers(
            studyProgressBonus: min(2, max(-1, scaled(snapshot.studyProgressBonus))),
            skillProgressBonus: min(2, max(0, scaled(snapshot.skillProgressBonus))),
            jobSearchChanceDelta: min(8, max(-8, scaled(snapshot.jobSearchChanceDelta))),
            socialActionDelta: min(1, max(-1, scaled(snapshot.socialActionDelta))),
            mentorEventWeight: max(0, scaled(snapshot.mentorEventWeight)),
            secondChanceEventWeight: max(0, scaled(snapshot.secondChanceEventWeight)),
            familyObligationEventWeight: max(0, scaled(snapshot.familyObligationEventWeight)),
            opportunityAccess: min(12, max(-12, scaled(snapshot.opportunityAccess))),
            socialConfidence: min(8, max(-8, scaled(snapshot.socialConfidence))),
            burnoutPressure: min(8, max(0, scaled(snapshot.burnoutPressure))),
            mentorAvailability: min(10, max(0, scaled(snapshot.mentorAvailability))),
            familyObligationPressure: min(10, max(0, scaled(snapshot.familyObligationPressure))),
            recoveryResilience: min(8, max(0, scaled(snapshot.recoveryResilience))),
            yearsRemaining: years
        )
    }

    static func allowsPivotalReturn(role: NPCRole, eventID: String, state: LifeState) -> Bool {
        guard state.character.age >= 18, state.npcs[role]?.importance == .pivotal else { return false }
        switch role {
        case .teacher:
            return ["mentor-referral", "second-chance-application"].contains(eventID)
                && (state.education.legacyFlags.contains(.mentorBacked)
                    || state.education.legacyFlags.contains(.recommendationEarned))
        case .friend:
            return ["school-reunion", "old-rumor-resurfaces"].contains(eventID)
        case .boss:
            return false
        }
    }

    private static func finalizeLegacy(
        state: inout LifeState,
        transition: inout SchoolGraduationTransition
    ) {
        state.education.launchInfluenceYearsRemaining = 7
        if state.education.teacherSupport >= 55 { state.education.legacyFlags.insert(.mentorBacked) }
        if state.education.schoolBelonging >= 65 { state.education.legacyFlags.insert(.sociallyRooted) }
        if state.education.activity != .none { state.education.legacyFlags.insert(.activityIdentity) }
        if state.education.commitmentYears[.home, default: 0] >= 2 {
            state.education.legacyFlags.insert(.carriedHomeLoad)
            transition.career.securityDelta += 4
        }
        if state.education.commitmentYears[.academics, default: 0] >= 3, state.stats.health <= 55 {
            state.education.legacyFlags.insert(.academicBurnout)
        }
        if var teacher = state.npcs[.teacher], state.education.legacyFlags.contains(.mentorBacked) {
            teacher.importance = .pivotal
            state.npcs[.teacher] = teacher
        }
        if var friend = state.npcs[.friend], state.education.schoolBelonging >= 60 {
            friend.importance = .pivotal
            state.npcs[.friend] = friend
        }
        state.education.frozenDefiningMemory = state.education.schoolMemories.max {
            if $0.significance == $1.significance { return $0.age < $1.age }
            return $0.significance < $1.significance
        }
        state.education.clamp()
        state.education.legacySnapshot = makeLegacySnapshot(for: state)
    }

    private static func makeLegacySnapshot(for state: LifeState) -> SchoolLegacyModifiers {
        let education = state.education
        let academic: Int = if education.academicStanding >= 75 { 2 }
            else if education.academicStanding >= 60 { 1 }
            else if education.academicStanding < 45 { -1 }
            else { 0 }
        var jobSearch: Int = switch education.postSchoolPath {
        case .training: 8
        case .work: 4
        case .scholarship, .college: 2
        case .alternativeCredential: -8
        case .undecided: 0
        }
        if education.futureReadiness >= 75 { jobSearch += 2 }
        if education.futureReadiness < 40 { jobSearch -= 2 }
        let social = education.schoolBelonging >= 65 ? 1 : (education.schoolBelonging < 40 ? -1 : 0)
        let mentor = education.legacyFlags.contains(.mentorBacked) || education.legacyFlags.contains(.recommendationEarned) ? 8 : 0
        let training = education.postSchoolPath == .training ? 1 : 0
        let opportunity = jobSearch + (education.legacyFlags.contains(.recommendationEarned) ? 3 : 0)
        let socialConfidence = education.schoolBelonging >= 65 ? 6 : (education.schoolBelonging < 40 ? -6 : 0)
        let burnout = education.legacyFlags.contains(.academicBurnout) ? 6 : 0
        let mentorAvailability = mentor + (education.teacherSupport >= 70 ? 2 : 0)
        let familyPressure = education.legacyFlags.contains(.carriedHomeLoad) ? 7 : 0
        let resilience = education.futureReadiness >= 65 || education.legacyFlags.contains(.mentorBacked) ? 4 : 0
        return SchoolLegacyModifiers(
            studyProgressBonus: min(2, max(-1, academic)),
            skillProgressBonus: min(2, max(0, max(0, academic) + training)),
            jobSearchChanceDelta: min(8, max(-8, jobSearch)),
            socialActionDelta: min(1, max(-1, social)),
            mentorEventWeight: mentor,
            secondChanceEventWeight: education.postSchoolPath == .alternativeCredential ? 10 : 0,
            familyObligationEventWeight: education.commitmentYears[.home, default: 0] * 3,
            opportunityAccess: min(12, max(-12, opportunity)),
            socialConfidence: socialConfidence,
            burnoutPressure: burnout,
            mentorAvailability: min(10, max(0, mentorAvailability)),
            familyObligationPressure: familyPressure,
            recoveryResilience: resilience,
            yearsRemaining: 7
        )
    }
}

enum InfluenceSystem {
    static func record(action: DomainAction, state: inout LifeState) {
        state.influenceLedger.record(action: action, partnerExists: state.partner != nil)
        guard !action.influence.isEmpty else { return }
        let probe = state.influenceLedger.current
        let peak = max(probe.work, probe.family, probe.stability, probe.risk)
        state.momentum.intensity = min(5, max(state.momentum.intensity, peak))
    }

    static func closeYear(state: inout LifeState) -> YearInfluenceSnapshot {
        state.influenceLedger.closeYear(age: state.character.age)
    }

    static func focusNote(for snapshot: YearInfluenceSnapshot) -> String? {
        guard let actionID = snapshot.influentialAction else {
            if snapshot.scores.isEmpty { return "You did not push a clear focus this year." }
            return "Because of your focus on \(snapshot.scores.dominantLabel)."
        }
        let name = DomainActionRegistry.action(for: actionID).name.lowercased()
        return "Because of your focus — you kept choosing to \(name)."
    }
}

// MARK: - Progression (life stage, school exit, work ladder)

struct ProgressionOutcome: Equatable {
    var deltas = DeltaSummary()
    var bullets: [String] = []
    var stageTransition: LifeStage?
    var milestoneHeadline: String?
    var milestoneDetail: String?
}

enum ProgressionSystem {
    /// Apply education and career consequences owned by an instant action.
    static func resolve(action: DomainAction, state: inout LifeState) {
        switch action.id {
        case .study, .attendClass:
            let gain = max(1, 2 + EducationSystem.legacyModifiers(for: state).studyProgressBonus)
            if state.education.college.isEnrolled {
                state.education.college.credits += gain
                state.education.progress = state.education.college.credits
            } else if state.education.recovery.isActive {
                state.education.recovery.progress += gain
                state.education.recovery.clamp()
                state.education.progress = state.education.recovery.progress
            } else {
                state.education.progress += gain
                if state.education.progress >= 12, state.stats.school >= 60 {
                    state.education.credential = true
                    if state.education.credentialKind == .none { state.education.credentialKind = .legacyCredential }
                }
            }
        case .joinClub:
            if state.education.college.isEnrolled {
                state.education.college.campusBelonging += 5
                state.education.college.clamp()
            }
        case .skillCourse:
            state.education.progress += 1 + EducationSystem.legacyModifiers(for: state).skillProgressBonus
            if state.education.progress >= 12, state.stats.school >= 55 {
                state.education.credential = true
                state.education.credentialKind = .professionalCertificate
            }
        case .applyForBetterWork:
            guard state.education.credential else { return }
            state.flags.hasJob = true
            state.career.level = .established
            state.career.lastTransition = .promoted
            if var boss = state.npcs[.boss] {
                boss.importance = .pivotal
                state.npcs[.boss] = boss
            }
        case .workShift, .sideHustle:
            if state.job.tier == .unemployed || (action.id == .workShift && state.job.tier == .retired) {
                state.career.level = .entry
                state.career.lastTransition = .hired
            }
            state.flags.hasJob = true
        default:
            break
        }
    }

    /// Apply age-driven stage, graduation, retirement, and light career drift.
    static func resolveYear(state: inout LifeState) -> ProgressionOutcome {
        var outcome = ProgressionOutcome()
        let previous = state.lifeStage
        let next = LifeStage.stage(for: state.character.age)
        if next != previous {
            state.lifeStage = next
            outcome.stageTransition = next
            outcome.bullets.append("Entered \(next.title) (\(next.ageBand))")
        } else {
            state.lifeStage = next
        }

        // Education → leave school
        if state.flags.attendsSchool, state.education.phase == .postsecondary,
           !state.education.college.isEnrolled {
            let ready = state.education.credential
                || state.character.age >= 24
            if ready {
                state.flags.attendsSchool = false
                if state.education.credential || state.education.progress >= 12 {
                    outcome.milestoneHeadline = "You Graduated Into The World"
                    outcome.milestoneDetail = "School closed behind you. The credential — or the hours — now have to earn their keep."
                    outcome.bullets.append("Left school")
                    if state.education.credential { outcome.deltas.rep += 2 }
                } else {
                    outcome.milestoneHeadline = "You Stepped Away From School"
                    outcome.milestoneDetail = "The classroom is no longer the center. Work and life take the open hours."
                    outcome.bullets.append("Left school without a full credential")
                }
            }
        }

        return outcome
    }

    static func stageTransitionEvent(_ stage: LifeStage) -> LifeEvent {
        LifeEvent(
            id: "stage-\(stage.rawValue)",
            headline: stage.transitionHeadline,
            detail: stage.transitionDetail,
            weight: { _ in 0 },
            choices: [
                EventChoice(
                    id: .accept,
                    title: "Face this chapter",
                    detail: stage.focusLine,
                    effects: EffectRange(),
                    partnerEffect: PartnerEffect(),
                    narrative: "You step into \(stage.title.lowercased()) with your eyes open."
                )
            ]
        )
    }
}

// MARK: - Finance

enum FinanceSystem {
    static func applySchoolTransition(
        _ transition: SchoolFinanceTransition,
        state: inout LifeState
    ) -> DeltaSummary {
        state.finance.studentDebt += transition.studentDebtDelta
        state.finance.clamp()
        return EffectResolutionSystem.apply(DeltaSummary(cash: transition.cashDelta), state: &state)
    }

    @discardableResult
    static func applyMedicalImpact(
        _ impact: MedicalFinanceImpact,
        state: inout LifeState,
        world: WorldModifierSnapshot
    ) -> Int {
        let charge = max(0, Int((Double(impact.requestedDebtCharge) * world.medicalDebtMultiplier).rounded()))
        state.finance.medicalDebt += charge
        state.finance.clamp()
        return charge
    }

    static func yearlySettlement(
        state: inout LifeState,
        world: WorldModifierSnapshot? = nil,
        assets: AssetFinancialSnapshot? = nil
    ) -> SystemYearDeltas {
        settleEconomy(state: &state, world: world ?? WorldSystem.modifiers(for: state.world))
    }

    static func scaledPay(state: LifeState, world: WorldModifierSnapshot? = nil) -> (income: Int, cost: Int) {
        let policy = world ?? WorldSystem.modifiers(for: state.world)
        return (EconomyCalculator.grossHousehold(state, world: policy), EconomyCalculator.essentialCost(state, world: policy))
    }

    static func projection(state: LifeState, world: WorldModifierSnapshot) -> (income: Int, costs: Int) {
        let d = EconomyCalculator.forecast(state).detail
        let income = d.earnings + d.partnerEarnings + d.support + d.pension + d.rentalIncome + d.retirementDraw
        return (income, income - d.expectedNet)
    }

    static func openFinancialRecoveryIfNeeded(state: inout LifeState) -> Bool {
        if state.recovery?.kind == .financial { state.recovery = nil }
        return false
    }
}

// MARK: - Health (yearly decay, not mortality)

enum HealthSystem {
    static func yearlyDrift(
        state: inout LifeState,
        world: WorldModifierSnapshot? = nil
    ) -> SystemYearDeltas {
        var result = SystemYearDeltas()
        let policy = world ?? WorldSystem.modifiers(for: state.world)
        var healthChange: Int
        var playChange = -1
        var looksChange = 0

        switch state.lifeStage {
        case .adolescence:
            healthChange = 0
            playChange = 0
        case .launch:
            healthChange = -1
        case .build:
            healthChange = state.character.age >= 35 ? -2 : -1
        case .pressure:
            healthChange = -2
            looksChange = state.character.age >= 50 ? -1 : 0
            playChange = -1
        case .legacy:
            healthChange = state.stats.health < 40 ? -3 : -2
            looksChange = -1
            playChange = -1
        }
        healthChange += policy.annualHealthDrift
        let continuityPressure = LifeThreadSystem.pressure(on: .health, state: state)
        if continuityPressure > 0 {
            healthChange -= min(3, max(1, continuityPressure / 3))
            result.notes.append("An unresolved life pressure is wearing on your health.")
        }

        result.deltas = EffectResolutionSystem.apply(
            DeltaSummary(play: playChange, health: healthChange, looks: looksChange),
            state: &state
        )
        let appliedHealth = result.deltas.health
        result.bullets.append("Health \(appliedHealth > 0 ? "+" : "")\(appliedHealth)")
        if state.health.overall <= 30 {
            result.consequences.append(contentsOf: [
                DomainConsequence(
                    source: .health, target: .career, kind: .illness, magnitude: .major,
                    openedAge: state.character.age, yearsRemaining: 3,
                    headline: "Health is limiting work capacity",
                    detail: "Low physical and mental margin are narrowing what you can sustain at work."
                ),
                DomainConsequence(
                    source: .health, target: .family, kind: .illness, magnitude: .minor,
                    openedAge: state.character.age, yearsRemaining: 3,
                    headline: "Illness changed the family load",
                    detail: "The household is absorbing more care and less available energy than before."
                )
            ])
        }
        return result
    }

    static func openHealthRecoveryIfNeeded(state: inout LifeState) -> Bool {
        if state.stats.health <= 0 {
            state.stats.health = 0
            state.recovery = RecoveryWindow(kind: .health, openedAge: state.character.age)
            return true
        }
        // Late-life critical also opens recovery if health very low
        if state.lifeStage == .legacy, state.stats.health <= 12 {
            state.recovery = RecoveryWindow(kind: .health, openedAge: state.character.age)
            return true
        }
        return false
    }

    static func resolveRecoveryIfPossible(state: inout LifeState) -> String? {
        guard let recovery = state.recovery else { return nil }
        // One strong stabilizing action should clear a crisis (no multi-shift farm required).
        let recovered = recovery.kind == .financial ? state.cash > -350 : state.stats.health > 12
        if recovered {
            state.recovery = nil
            return "You created enough room to keep going."
        }
        return nil
    }
}

// MARK: - Mortality

struct MortalityOutcome: Equatable {
    var pressure: MortalityPressure
    var died = false
    var endReason: EndReason?
    var warning: String?
    var bullets: [String] = []
}

enum MortalitySystem {
    static func deathNarrative(reason: EndReason, state: LifeState) -> String {
        switch reason {
        case .naturalCauses:
            return "The years ran out gently and completely. Health \(state.stats.health) at age \(state.character.age)."
        case .maximumAge:
            return "You reached the far edge of a long life. The story closes at \(LifeLimits.maximumAge)."
        case .unresolvedHealthCrisis:
            return "Your health crisis could not be stabilized."
        case .unresolvedFinancialCrisis:
            return "Your financial crisis could not be stabilized."
        case .prisonKilling:
            return "A rival found you inside. The institution became the final chapter."
        }
    }

    static func evaluate(state: inout LifeState) -> MortalityOutcome {
        var outcome = MortalityOutcome(pressure: .stable)
        let age = state.character.age
        let health = state.stats.health

        // Hard ceiling
        if age >= LifeLimits.maximumAge {
            outcome.died = true
            outcome.endReason = .maximumAge
            outcome.pressure = .critical
            outcome.bullets.append("Maximum age reached")
            state.mortalityPressure = .critical
            return outcome
        }

        if age < LifeLimits.lateLifeStart {
            outcome.pressure = .stable
            state.mortalityPressure = .stable
            return outcome
        }

        // Visible pressure band
        if health <= 25 || age >= 85 {
            outcome.pressure = .critical
        } else if health <= 45 || age >= 75 {
            outcome.pressure = .vulnerable
        } else {
            outcome.pressure = .stable
        }
        state.mortalityPressure = outcome.pressure

        if outcome.pressure == .vulnerable {
            outcome.warning = "Mortality pressure is rising — health \(health) at age \(age)."
            outcome.bullets.append("Vulnerable")
        } else if outcome.pressure == .critical {
            outcome.warning = "Critical mortality pressure — the next hard year may be the last."
            outcome.bullets.append("Critical")
        }

        // Seeded natural death chance (telegraphed by pressure)
        var chance = 0
        switch outcome.pressure {
        case .stable:
            chance = age >= 80 ? 4 : 1
        case .vulnerable:
            chance = 8 + (age - 65) / 3
        case .critical:
            chance = 18 + (age - 65) / 2 + max(0, 30 - health)
        }
        chance = min(55, chance)
        let roll = state.randomStreams.mortality.next(in: 1...100)
        if roll <= chance {
            outcome.died = true
            outcome.endReason = .naturalCauses
            outcome.bullets.append("Natural death")
        }
        return outcome
    }
}

// MARK: - What matters this year (glance helper)

struct WhatMattersItem: Identifiable, Equatable {
    let id: String
    let pressureLabel: String
    let actionName: String
    let reason: String
    /// Domain to open when the player taps this row.
    let domain: Domain
    /// Preferred instant to run (if available).
    let suggestedAction: ActionID?
}

enum WhatMattersResolver {
    static func items(for state: LifeState, limit: Int = 3) -> [WhatMattersItem] {
        var items: [WhatMattersItem] = []

        if state.recovery?.kind == .financial {
            items.append(item("rec-f", "Cash crisis", "Work a shift", "Stabilize before Age Up ends the life.", .cash, .workShift))
        }
        if state.recovery?.kind == .health {
            items.append(item("rec-h", "Health crisis", "Rest", "Stabilize before Age Up ends the life.", .health, .rest))
        }
        if state.mortalityPressure != .stable {
            items.append(item("mort", "Mortality \(state.mortalityPressure.title)", "Seek care", state.mortalityPressure.detail, .health, .seekCare))
        }
        if state.cash < 8000 {
            items.append(item("cash", "Runway", "Work a shift", "Cash $\(state.cash) is thin.", .cash, .workShift))
        }
        if state.stats.health < 45 {
            items.append(item("health", "Body", "Rest", "Health \(state.stats.health).", .health, .rest))
        }
        if let partner = state.partner, partner.resentment >= 40 || partner.bond < 40 {
            let action: ActionID = partner.resentment >= 50 ? .repairConflict : .reachOut
            items.append(item("love", "Home tension", DomainActionRegistry.action(for: action).name, "\(partner.name) needs presence.", .love, action))
        }
        if state.flags.attendsSchool, state.stats.school < 50 {
            let action: ActionID = state.lifeStage == .adolescence ? .focusGrades : .study
            items.append(item("school", "School footing", DomainActionRegistry.action(for: action).name, "Smart \(state.stats.school).", .school, action))
        }
        if state.education.phase == .highSchool, state.education.commitment == nil {
            let action: ActionID = state.education.schoolBelonging < state.education.academicStanding ? .findYourPeople : .focusGrades
            items.append(item("school-focus", "This school year", DomainActionRegistry.action(for: action).name, "Choose what gets your limited time.", .school, action))
        }
        if state.education.college.isEnrolled {
            items.append(item("cred", "College credits", "Study", "Progress \(state.education.college.credits)/\(state.education.college.creditTarget).", .school, .study))
        } else if state.education.recovery.isActive, let kind = state.education.recovery.kind {
            items.append(item("recovery-education", kind.title, "Study", "Progress \(state.education.recovery.progress)/\(kind.target).", .school, .study))
        } else if state.education.phase == .postsecondary, !state.education.credential, state.flags.attendsSchool {
            items.append(item("cred", "Credential", "Study", "Progress \(state.education.progress)/12.", .school, .study))
        }
        if !state.flags.attendsSchool, state.stats.school < 55, state.lifeStage != .launch {
            items.append(item("skills", "Skills edge", "Skill course", "Keep the market from passing you.", .school, .skillCourse))
        }
        if state.job.tier == .unemployed {
            items.append(item("job", "Work", "Work a shift", "You need footing again.", .cash, .workShift))
        }
        if state.stats.play < 35 {
            let action: ActionID = state.lifeStage == .legacy ? .quietNight : .seeFriends
            items.append(item("play", "Joy", DomainActionRegistry.action(for: action).name, "Fun \(state.stats.play).", .play, action))
        }

        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }.prefix(limit).map { $0 }
    }

    private static func item(
        _ id: String,
        _ pressure: String,
        _ actionName: String,
        _ reason: String,
        _ domain: Domain,
        _ action: ActionID?
    ) -> WhatMattersItem {
        WhatMattersItem(
            id: id,
            pressureLabel: pressure,
            actionName: actionName,
            reason: reason,
            domain: domain,
            suggestedAction: action
        )
    }
}

// MARK: - Deterministic diagnostic policy

/// Chooses intentful actions for automated complete-life probes. This is not a
/// gameplay AI; it exists so release scenarios genuinely traverse the domain
/// paths their policy names instead of repeatedly taking the first grid item.
enum SimulationPolicySystem {
    static func preferredAction(policy: String, completedYears: Int, state: LifeState) -> ActionID? {
        if state.character.age >= 18 {
            if policy == "grind" && state.flags.attendsSchool { return .study }
            if FinanceSystem.workoutEligible(state) { return .negotiateDebt }
            if state.career.track == .undecided { return .chooseOffice }
            if state.career.level == .unemployed { return .jobSearch }
            if policy == "balanced" || policy == "grind" {
                if state.finance.totalDebt > 0 && state.cash > 5_000 && completedYears.isMultiple(of: 3) { return .payDebt }
                if state.finance.retirementContributionPercent == 0 && state.cash > 10_000 && completedYears.isMultiple(of: 4) { return .adjustRetirement }
                if state.assets.properties.isEmpty && state.cash > 40_000 && completedYears.isMultiple(of: 5) { return .buyHome }
                if state.career.level == .entry && state.career.performance >= 60 { return .pursuePromotion }
                if state.career.performance < 60 && completedYears.isMultiple(of: 3) { return .developSkill }
            }
        }

        switch policy {
        case "social":
            if let partner = state.partner {
                if partner.resentment >= 45 || partner.bond <= 40 { return .repairConflict }
                return completedYears.isMultiple(of: 2) ? .goOnDate : .reachOut
            }
            return .goOnDate
        case "survival":
            if state.stats.health < 45, state.cash >= 4000 { return .seekCare }
            return completedYears.isMultiple(of: 2) ? .exercise : .rest
        case "landlord":
            if state.career.level == .entry && state.career.performance >= 60 { return .pursuePromotion }
            return state.assets.properties.isEmpty && state.cash > 50_000 ? .buyHome : .workShift
        case "specialist", "diamond-seeking":
            if policy == "diamond-seeking", state.career.careerClass == .special, CareerOpportunitySystem.diamondEligibilityIssue(in: state) == nil { return .buildDiamondCareer }
            if CareerOpportunitySystem.specialEligibilityIssue(in: state) == nil { return .pursueSpecialCareer }
            if state.career.level == .entry && state.career.performance >= 60 { return .pursuePromotion }
            return state.career.performance < 75 ? .developSkill : .workShift
        case "drifter": return completedYears.isMultiple(of: 3) ? .party : .rest
        case "criminal": return completedYears.isMultiple(of: 3) ? .jobSearch : .workShift
        case "grind":
            if state.education.phase == .highSchool { return .focusGrades }
            if state.flags.attendsSchool { return .study }
            if state.education.credential, state.job.tier != .skilled { return .applyForBetterWork }
            return .workShift
        default:
            return nil
        }
    }

    static func preferredDomainCommand(policy: String, completedYears: Int, state: LifeState) -> DomainCommandRequest? {
        if policy == "landlord", state.character.age >= 18 {
            if let property = state.assets.properties.first(where: { !$0.isPrimaryResidence && $0.use != .rental }) {
                return .rentProperty(property.id, .market)
            }
            if state.assets.properties.contains(where: \.isPrimaryResidence), state.assets.properties.filter({ !$0.isPrimaryResidence }).isEmpty, state.cash >= 30_000 {
                return .purchaseAsset("house-starter-condo")
            }
        }
        if policy == "criminal", state.character.age >= 18 {
            let operations = CrimeSystem.soloOperations
            guard !operations.isEmpty else { return nil }
            return .soloCrime(operations[completedYears % operations.count])
        }
        return nil
    }
}
