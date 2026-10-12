import Foundation

struct PartnerYearResolution {
    let deltas: DeltaSummary
    let note: String?
    let event: PresentedEvent?
}

enum RelationshipSystem {
    static func applyReaction(bondDelta: Int = 0, resentmentDelta: Int = 0, state: inout LifeState) {
        guard var partner = state.partner else { return }
        partner.bond += bondDelta
        partner.resentment += resentmentDelta
        partner.clamp()
        state.partner = partner
    }

    static func applyGiftOutcome(_ outcome: AssetGiftOutcome, state: inout LifeState) {
        let delta = outcome.relationshipDelta
        guard delta > 0 else { return }
        switch outcome.recipient {
        case .partner:
            guard var partner = state.partner else { return }
            partner.bond = min(100, partner.bond + delta)
            partner.lastInteractionAge = state.character.age
            state.partner = partner
        case .family(let contactID):
            guard let index = state.family.contacts.firstIndex(where: { $0.id == contactID }) else { return }
            state.family.contacts[index].bond = min(100, state.family.contacts[index].bond + delta)
            state.family.contacts[index].lastSituationAge = state.character.age
            state.family.clamp()
        case .cast(let memberID):
            guard var member = state.npcs.member(id: memberID) else { return }
            member.rapport = min(100, member.rapport + delta)
            member.lastInteractionAge = state.character.age
            member.clamp()
            state.npcs.update(member)
        }
    }

    static func endCurrent(_ reason: RelationshipEndReason, state: inout LifeState) {
        guard let partner = state.partner else { return }
        state.formerRelationships.insert(
            FormerRelationship(
                name: partner.name,
                startedAge: partner.startedAge,
                endedAge: state.character.age,
                finalStage: partner.stage,
                finalBond: partner.bond,
                finalResentment: partner.resentment,
                reason: reason
            ),
            at: 0
        )
        state.formerRelationships = Array(state.formerRelationships.prefix(4))
        state.partner = nil
        state.flags.hasPartner = false
    }
}

/// Owns partner and lightweight-NPC behavior. LifeSimulator only sequences it.
struct SocialReactivitySystem {
    func preview(action: DomainAction, target: PersonReference? = nil, state: LifeState) -> SocialActionResolution {
        let partner: PartnerState? = {
            if case .some(.cast) = target { return nil }
            return state.partner
        }()
        let core = partner.flatMap { partner in action.personalityBranches.first { !$0.isLearned && $0.matches(partner) } }
        let learned = partner.flatMap { partner in action.personalityBranches.first { $0.isLearned && $0.matches(partner) } }
        let legacyPartnerBranches = [core, learned].compactMap { $0 }
        let playerSignals = SimulationSignalSnapshot(state: state)
        let playerRule = UnifiedReactionRegistry.bestMatch(channel: .playerPersonality, action: action.id, signals: playerSignals)
        let worldRule = UnifiedReactionRegistry.bestMatch(channel: .world, action: action.id, signals: playerSignals)
        let talentRule = UnifiedReactionRegistry.bestMatch(channel: .talent, action: action.id, signals: playerSignals)
        let partnerRule = partner == nil ? nil : UnifiedReactionRegistry.bestMatch(
            channel: .npcOrPartner, action: action.id, signals: playerSignals
        )

        let npc: NPCState? = {
            if case .some(.cast(let memberID)) = target { return state.npcs.member(id: memberID) }
            if target != nil { return nil }
            return action.npcRole.flatMap { state.npcs[$0] }
        }()
        let npcSignals = npc.map { SimulationSignalSnapshot(state: state, npc: $0) }
        let npcRule = npcSignals.flatMap {
            UnifiedReactionRegistry.bestMatch(channel: .npcOrPartner, action: action.id, signals: $0)
        }
        let socialRule = [partnerRule, npcRule].compactMap { $0 }.sorted {
            if $0.predicate.specificity == $1.predicate.specificity { return $0.id < $1.id }
            return $0.predicate.specificity > $1.predicate.specificity
        }.first
        let selectedPartnerRule = socialRule?.id == partnerRule?.id ? socialRule : nil
        let selectedNPCRule = socialRule?.id == npcRule?.id ? socialRule : nil
        // New declarative rules are canonical. Legacy branches remain a save-
        // compatible fallback until every old authored reaction is migrated.
        let partnerBranches = selectedPartnerRule == nil ? legacyPartnerBranches : []
        var partnerEffect = action.partnerEffect
        if case .some(.cast) = target { partnerEffect = PartnerEffect() }
        for branch in partnerBranches {
            partnerEffect.bond += branch.modifier.bond
            partnerEffect.resentment += branch.modifier.resentment
        }
        if let rule = selectedPartnerRule {
            partnerEffect.bond += rule.partnerModifier.bond
            partnerEffect.resentment += rule.partnerModifier.resentment
        }
        partnerEffect.bond = min(6, max(-3, partnerEffect.bond))
        partnerEffect.resentment = min(4, max(-7, partnerEffect.resentment))
        let npcBranch = npc.flatMap { npc in action.npcPersonalityBranches.first { $0.matches(npc) } }
        let effectiveNPCBranch = socialRule == nil ? npcBranch : nil
        let genericRules = [playerRule, socialRule, worldRule, talentRule].compactMap { $0 }
        let headline = genericRules.first?.headline ?? (core ?? learned)?.headline ?? effectiveNPCBranch?.headline ?? action.name
        let narratives = partnerBranches.map(\.narrative)
            + (effectiveNPCBranch.map { [$0.narrative] } ?? [])
            + genericRules.map(\.narrative)
        let contexts = partnerBranches.map { $0.requiredFlags.map(\.title).joined(separator: " + ") }
            + (effectiveNPCBranch.map { [$0.requiredFlags.map(\.title).joined(separator: " + ")] } ?? [])
            + genericRules.map { "\($0.channel.title): \($0.cause.isEmpty ? $0.previewHint : $0.cause)" }
        let hints = partnerBranches.map(\.previewHint) + (effectiveNPCBranch.map { [$0.previewHint] } ?? []) + genericRules.map(\.previewHint)
        var npcEffect = effectiveNPCBranch?.modifier ?? EffectRange()
        for rule in [playerRule, selectedNPCRule, worldRule, talentRule].compactMap({ $0 }) {
            npcEffect = npcEffect.shifted(by: ReactionBalancePolicy.resolvedEffects(for: rule.impact, state: state))
        }
        if action.id != .helpAtHome { npcEffect.cash = 0...0 }
        return SocialActionResolution(
            action: action,
            partnerEffect: partnerEffect,
            headline: headline,
            narrative: narratives.isEmpty ? action.narrative : narratives.joined(separator: " "),
            personalityContext: contexts.isEmpty ? nil : contexts.joined(separator: " · "),
            previewHint: hints.isEmpty ? nil : hints.joined(separator: " "),
            appliedBranches: partnerBranches,
            npc: npc,
            npcEffect: npcEffect,
            npcContext: npc.map { "\($0.name) · \($0.role.title)" },
            npcRapportDelta: (effectiveNPCBranch?.rapportDelta ?? 0) + (selectedNPCRule?.rapportDelta ?? 0)
                + ((target != nil && (action.id == .reachOut || action.id == .seeFriends)) ? 2 : 0),
            reactionRules: genericRules
        )
    }

    func lockReason(action: DomainAction, state: LifeState) -> String? {
        let resolution = preview(action: action, state: state)
        if let partner = state.partner,
           (!resolution.appliedBranches.isEmpty || resolution.reactionRules.contains(where: { $0.predicate.role == .partner })),
           partner.usedPersonalityResponse(for: action.id, at: state.character.age) {
            return "You already had this kind of moment this year"
        }
        if let npc = resolution.npc, resolution.npcEffect != EffectRange(),
           npc.usedPersonalityResponse(for: action.id, at: state.character.age) {
            return "You already had this kind of moment this year"
        }
        return nil
    }

    mutating func resolve(action: DomainAction, target: PersonReference? = nil, state: inout LifeState) -> SocialActionResolution {
        if target == nil { ensureNPC(for: action, state: &state) }
        return preview(action: action, target: target, state: state)
    }

    @discardableResult
    mutating func apply(_ resolution: SocialActionResolution, state: inout LifeState) -> DeltaSummary {
        let deltas = applyPartnerEffect(resolution.partnerEffect, state: &state)
        if (!resolution.appliedBranches.isEmpty || resolution.reactionRules.contains(where: { $0.predicate.role == .partner })),
           var partner = state.partner {
            partner.markPersonalityResponseUsed(for: resolution.action.id, at: state.character.age)
            state.partner = partner
        }
        if resolution.npcEffect != EffectRange() || resolution.npcRapportDelta != 0, var npc = resolution.npc {
            npc.rapport += resolution.npcRapportDelta
            npc.lastInteractionAge = state.character.age
            npc.markPersonalityResponseUsed(for: resolution.action.id, at: state.character.age)
            if npc.importance != .background {
                npc.learnedStance = npc.rapport >= 6 ? .warm : (npc.rapport <= -6 ? .wary : npc.learnedStance)
            }
            let socialImpulse = PersonalityImpulse(
                empathy: resolution.npcRapportDelta > 0 ? 1 : (resolution.npcRapportDelta < 0 ? -1 : 0),
                sociability: resolution.action.resolvedPersonalityImpulse.sociability == 0 ? 0 : 1,
                adaptability: resolution.npcRapportDelta == 0 ? 0 : 1
            )
            PersonalitySystem.record(socialImpulse, profile: &npc.personality)
            // Interactions record impulses; personality development resolves once at Age+.
            DynamicCastSystem.recordInteraction(
                resolution.action.id,
                member: &npc,
                age: state.character.age
            )
            npc.clamp()
            state.npcs.update(npc)
        }
        return deltas
    }

    /// School belonging is a soft Launch-era nudge, never more than one point.
    @discardableResult
    mutating func applySchoolLegacy(for action: DomainAction, state: inout LifeState) -> DeltaSummary {
        let socialActions: Set<ActionID> = [.reachOut, .goOnDate, .repairConflict, .seeFriends]
        guard socialActions.contains(action.id) else { return DeltaSummary() }
        let legacy = EducationSystem.legacyModifiers(for: state)
        let confidenceNudge = legacy.socialConfidence == 0 ? 0 : (legacy.socialConfidence > 0 ? 1 : -1)
        let delta = max(-1, min(1, legacy.socialActionDelta + confidenceNudge))
        guard delta != 0 else { return DeltaSummary() }
        return EffectResolutionSystem.apply(EffectRange(love: delta...delta), state: &state)
    }

    @discardableResult
    mutating func applyPartnerEffect(_ effect: PartnerEffect, state: inout LifeState) -> DeltaSummary {
        guard var partner = state.partner else { return DeltaSummary() }
        if effect.endRelationship {
            RelationshipSystem.endCurrent(.partnerLeftAfterRupture, state: &state)
            return DeltaSummary(bond: effect.bond, resentment: effect.resentment)
        }
        let beforeBond = partner.bond
        let beforeResentment = partner.resentment
        partner.bond += effect.bond
        partner.resentment += effect.resentment
        if let committed = effect.committed { partner.committed = committed }
        if let ruptureStage = effect.ruptureStage { partner.ruptureStage = ruptureStage }
        if let repairPromise = effect.repairPromise { partner.repairPromise = repairPromise }
        if effect.bond > 0 || effect.resentment < 0 { partner.lastInteractionAge = state.character.age }
        partner.clamp()
        state.partner = partner
        return DeltaSummary(
            bond: partner.bond - beforeBond,
            resentment: partner.resentment - beforeResentment
        )
    }

    mutating func createPartnerIfEligible(for action: DomainAction, state: inout LifeState) {
        guard action.effects.gainsPartner, state.partner == nil, state.stats.love >= 58 else { return }
        let names = ["Morgan", "Alex", "Jordan", "Riley", "Sam", "Casey"]
        let name = names[state.randomStreams.social.next(in: 0...(names.count - 1))]
        let first = PartnerFlag.coreCases[state.randomStreams.social.next(in: 0...(PartnerFlag.coreCases.count - 1))]
        let remaining = PartnerFlag.coreCases.filter { $0 != first }
        let second = remaining[state.randomStreams.social.next(in: 0...(remaining.count - 1))]
        var partnerRandom = SimulationRandomStreams.npcStream(runSeed: state.runSeed, identity: "partner-\(state.character.age)-\(name)")
        let profile = PersonalitySystem.generated(random: &partnerRandom)
        let compatibility = PersonalitySystem.compatibility(state.personality, profile)
        state.partner = PartnerState(name: name, startedAge: state.character.age, compatibility: compatibility, lastInteractionAge: state.character.age, flags: [first, second], personality: profile)
        state.flags.hasPartner = true
    }

    mutating func resolveYear(
        state: inout LifeState,
        baseDeltas: DeltaSummary,
        snapshot suppliedSnapshot: YearInfluenceSnapshot? = nil
    ) -> PartnerYearResolution {
        let snapshot = suppliedSnapshot ?? state.influenceLedger.closeYear(age: state.character.age)
        guard var partner = state.partner else {
            return PartnerYearResolution(deltas: DeltaSummary(), note: nil, event: nil)
        }

        let scores = snapshot.scores
        let workDominant = scores.work > scores.family
        let attentive = scores.family >= 2 && scores.family >= scores.work
        var neglect = max(0, scores.work - scores.family) + (scores.family == 0 ? 2 : 0)

        if partner.flags.contains(.demanding), workDominant { neglect += 1 }
        if partner.flags.contains(.independent) { neglect -= 2 }
        neglect = min(8, max(0, neglect))

        var bondDelta = scores.family * 2 + scores.stability / 2 - neglect * 2 - scores.risk / 2
        var resentmentDelta = neglect * 2 + scores.risk - scores.family - scores.stability / 2

        if partner.flags.contains(.loyal) {
            resentmentDelta -= 2
            if attentive { bondDelta += 1 }
        }
        if partner.flags.contains(.supportive), scores.stability >= 2, workDominant {
            bondDelta += 1
            resentmentDelta -= 1
        }
        if partner.flags.contains(.adventurous), scores.risk > 0 {
            bondDelta += min(2, scores.risk / 2)
            resentmentDelta -= min(2, scores.risk / 2)
        }
        if partner.flags.contains(.cautious) {
            bondDelta += scores.stability / 2
            resentmentDelta += scores.risk
        }
        bondDelta += min(1, max(-1, (partner.compatibility - 60) / 20))
        bondDelta = min(10, max(-12, bondDelta))
        resentmentDelta = min(12, max(-8, resentmentDelta))

        let beforeBond = partner.bond
        let beforeResentment = partner.resentment
        partner.bond += bondDelta
        partner.resentment += resentmentDelta
        partner.clamp()
        bondDelta = partner.bond - beforeBond
        resentmentDelta = partner.resentment - beforeResentment

        if attentive {
            partner.attentionStreak += 1
            partner.neglectStreak = 0
            partner.lastInteractionAge = state.character.age
        } else if workDominant || scores.family == 0 {
            partner.neglectStreak += 1
            partner.attentionStreak = 0
        } else {
            partner.attentionStreak = 0
            partner.neglectStreak = 0
        }
        let partnerImpulse = attentive
            ? PersonalityImpulse(empathy: 2, adaptability: 1)
            : (workDominant ? PersonalityImpulse(drive: 1, empathy: -1, sociability: -1) : .zero)
        PersonalitySystem.record(partnerImpulse, profile: &partner.personality)
        _ = PersonalitySystem.resolveYear(profile: &partner.personality, age: state.character.age)
        evolveLearnedFlags(partner: &partner)

        if partner.repairPromise, workDominant {
            partner.ruptureStage = .ultimatum
            partner.repairPromise = false
        }

        let deltas = DeltaSummary(bond: bondDelta, resentment: resentmentDelta)
        let note = minorNote(partner: partner, snapshot: snapshot, deltas: deltas)
        partner.lastNote = note
        state.partner = partner

        let situation = RelationshipSituationSystem.resolveYear(state: &state)
        if let headline = situation.milestoneHeadline {
            let detail = situation.milestoneDetail ?? headline
            return PartnerYearResolution(
                deltas: deltas,
                note: detail,
                event: PresentedEvent(
                    id: "relationship-situation-\(state.character.age)",
                    headline: headline,
                    detail: detail,
                    choices: [choice(.accept, "Carry it forward", "This chapter now belongs to the life behind you.", partner: PartnerEffect(), narrative: detail)],
                    yearDeltas: baseDeltas + deltas,
                    isPartnerEvent: true
                )
            )
        }

        if let event = majorEvent(state: &state, snapshot: snapshot, yearDeltas: baseDeltas + deltas) {
            return PartnerYearResolution(deltas: deltas, note: note, event: event)
        }
        return PartnerYearResolution(deltas: deltas, note: note, event: nil)
    }

    private func evolveLearnedFlags(partner: inout PartnerState) {
        if partner.attentionStreak >= 3 {
            partner.flags.removeAll { $0 == .guarded }
            if !partner.flags.contains(.secure) { partner.flags.append(.secure) }
        } else if partner.neglectStreak >= 3 {
            partner.flags.removeAll { $0 == .secure }
            if !partner.flags.contains(.guarded) { partner.flags.append(.guarded) }
        }
    }

    private func majorEvent(state: inout LifeState, snapshot: YearInfluenceSnapshot, yearDeltas: DeltaSummary) -> PresentedEvent? {
        guard var partner = state.partner else { return nil }
        let workDominant = snapshot.scores.work > snapshot.scores.family
        let yearsTogether = state.character.age - partner.startedAge

        if !partner.committed, yearsTogether >= 2, partner.bond >= 70, partner.resentment <= 20 {
            partner.lastMajorEventAge = state.character.age
            state.partner = partner
            return PresentedEvent(
                id: "partner-commitment",
                headline: "You Built Something Worth Naming",
                detail: "\(partner.name) wants to know whether this life is truly shared.",
                choices: [
                    choice(.accept, "Commit", "Choose the relationship deliberately.", partner: PartnerEffect(bond: 8, resentment: -4, committed: true, ruptureStage: .stable), narrative: "You named the future together, and the room felt steadier."),
                    choice(.decline, "Ask for more time", "Be honest about your uncertainty.", partner: PartnerEffect(bond: -6, resentment: 8), narrative: "Honesty kept the answer open, but it left a bruise.")
                ],
                yearDeltas: yearDeltas,
                isPartnerEvent: true
            )
        }

        let escalated = partner.ruptureStage == .ultimatum
            || ((partner.ruptureStage == .confronted || partner.ruptureStage == .promisedRepair)
                && workDominant && (partner.bond <= 30 || partner.resentment >= 70))
        if escalated {
            partner.ruptureStage = .ultimatum
            partner.lastMajorEventAge = state.character.age
            state.partner = partner
            return PresentedEvent(
                id: "partner-ultimatum",
                headline: "Work Keeps Winning at Home",
                detail: echo(for: snapshot, partner: partner, ending: "\(partner.name) will not keep waiting for a different life."),
                choices: [
                    choice(.prioritizeFamily, "Prioritize family", "Make a concrete break from the pattern.", love: 5...5, partner: PartnerEffect(bond: 12, resentment: -20, ruptureStage: .stable, repairPromise: false), narrative: "You changed the calendar before making another promise."),
                    choice(.compromise, "Build a compromise", "Set boundaries that both of you can measure.", love: 2...2, partner: PartnerEffect(bond: 6, resentment: -10, ruptureStage: .promisedRepair, repairPromise: true), narrative: "The agreement was practical. Now it has to survive the year."),
                    choice(.chooseWork, "Choose the work", "Stop asking them to wait.", love: -12 ... -12, health: -5 ... -5, partner: PartnerEffect(endRelationship: true), narrative: "\(partner.name) left. The work remained, exactly where you put it.")
                ],
                yearDeltas: yearDeltas,
                isPartnerEvent: true
            )
        }

        let cooldownPassed = partner.lastMajorEventAge.map { state.character.age - $0 >= 2 } ?? true
        if cooldownPassed, partner.bond <= 40 || partner.resentment >= 45 {
            partner.ruptureStage = .confronted
            partner.lastMajorEventAge = state.character.age
            state.partner = partner
            return PresentedEvent(
                id: "partner-confrontation",
                headline: "Your Partner Needs You Present",
                detail: echo(for: snapshot, partner: partner, ending: "\(partner.name) says the distance has become impossible to ignore."),
                choices: [
                    choice(.makeTime, "Make real time", "Change the pattern now.", love: 4...4, partner: PartnerEffect(bond: 10, resentment: -14, ruptureStage: .stable, repairPromise: false), narrative: "You made room before asking for forgiveness."),
                    choice(.negotiate, "Negotiate balance", "Agree on visible boundaries.", love: 2...2, partner: PartnerEffect(bond: 5, resentment: -7, ruptureStage: .promisedRepair, repairPromise: true), narrative: "You made a plan together. They are watching what happens next."),
                    choice(.dismiss, "Dismiss it", "Keep your current priorities.", partner: PartnerEffect(bond: -8, resentment: 12, ruptureStage: .confronted, repairPromise: false), narrative: "The conversation ended. The resentment did not.")
                ],
                yearDeltas: yearDeltas,
                isPartnerEvent: true
            )
        }
        return nil
    }

    private func minorNote(partner: PartnerState, snapshot: YearInfluenceSnapshot, deltas: DeltaSummary) -> String {
        if snapshot.scores.work > snapshot.scores.family {
            return echo(for: snapshot, partner: partner, ending: "Home felt emptier while \(partner.name) stopped asking when you would be back.")
        }
        if snapshot.scores.family >= 2 {
            return "The ordinary time with \(partner.name) made the relationship feel lived in, not managed."
        }
        if deltas.resentment > 0 {
            return "You and \(partner.name) moved around each other quietly. The silence kept its own score."
        }
        return "Life with \(partner.name) held steady without demanding the spotlight."
    }

    private func echo(for snapshot: YearInfluenceSnapshot, partner: PartnerState, ending: String) -> String {
        guard let actionID = snapshot.influentialAction else { return ending }
        let action = DomainActionRegistry.action(for: actionID).name.lowercased()
        return "After you kept choosing to \(action), the distance became harder to explain away. \(ending)"
    }

    private func choice(
        _ id: EventChoiceID,
        _ title: String,
        _ detail: String,
        love: ClosedRange<Int> = 0...0,
        health: ClosedRange<Int> = 0...0,
        partner: PartnerEffect,
        narrative: String
    ) -> EventChoice {
        EventChoice(
            id: id,
            title: title,
            detail: detail,
            effects: EffectRange(love: love, health: health),
            partnerEffect: partner,
            narrative: narrative
        )
    }

    mutating func contextualize(_ event: LifeEvent, state: inout LifeState) -> LifeEvent {
        let role: NPCRole?
        switch event.id {
        case "school-pressure", "teacher-stays-late", "recommendation-window", "mentor-referral", "second-chance-application",
             "discipline-office", "junior-future-pressure", "activity-injury", "activity-pushed-out": role = .teacher
        case "hallway-rumor", "friend-group-fracture", "activity-tryout", "school-reunion", "old-rumor-resurfaces",
             "freshman-lunch-table", "bullying-line-crossed", "sophomore-name-sticks", "school-date-invitation",
             "activity-leadership", "prom-cost", "senior-last-night": role = .friend
        case "skilled-work-setback": role = .boss
        default: role = nil
        }
        guard let role else { return event }
        let returnEvents: Set<String> = ["mentor-referral", "second-chance-application", "school-reunion", "old-rumor-resurfaces"]
        if returnEvents.contains(event.id) {
            guard EducationSystem.allowsPivotalReturn(role: role, eventID: event.id, state: state) else { return event }
        } else {
            guard role.isActive(in: state) else { return event }
            ensureNPC(role: role, state: &state)
        }
        guard let npc = state.npcs[role], npc.importance == .pivotal else { return event }
        let supportive = npc.coreFlags.contains(.encouraging) || npc.coreFlags.contains(.fair)
        let critical = npc.coreFlags.contains(.critical) || npc.coreFlags.contains(.ambitious)
        let choices = event.choices.map { choice -> EventChoice in
            var effects = choice.effects
            var narrative = choice.narrative
            if role == .teacher, choice.id == .focus, supportive {
                effects = effects.shifted(school: 2); narrative += " \(npc.name)'s support made the work feel possible."
            } else if role == .teacher, choice.id == .decline, critical {
                effects = effects.shifted(school: -2); narrative += " \(npc.name) noticed the work you left behind."
            } else if role == .boss, choice.id == .focus, supportive {
                effects = effects.shifted(rep: 2); narrative += " \(npc.name) backed the repair in the room."
            } else if role == .boss, choice.id == .decline, critical {
                effects = effects.shifted(rep: -2); narrative += " \(npc.name) did not let the deflection pass quietly."
            }
            return EventChoice(
                id: choice.id,
                title: choice.title,
                detail: choice.detail,
                effects: effects,
                partnerEffect: choice.partnerEffect,
                narrative: narrative,
                educationEffect: choice.educationEffect,
                educationTransitionEffect: choice.educationTransitionEffect,
                personalityImpulse: choice.personalityImpulse,
                relationshipRole: choice.relationshipRole,
                npcRapportDelta: choice.npcRapportDelta,
                propertyEffect: choice.propertyEffect,
                financeEffect: choice.financeEffect,
                financialPurpose: choice.financialPurpose
            )
        }
        return LifeEvent(id: event.id, headline: event.headline, detail: "\(npc.name) is watching how you handle this. \(event.detail)", weight: event.weight, choices: choices)
    }

    private mutating func ensureNPC(for action: DomainAction, state: inout LifeState) {
        guard let role = action.npcRole else { return }
        ensureNPC(role: role, state: &state)
    }

    private mutating func ensureNPC(role: NPCRole, state: inout LifeState) {
        if state.npcs[role] != nil {
            DynamicCastSystem.reactivate(role: role, state: &state)
            return
        }
        let importance: NPCImportance = role == .teacher ? .pivotal : (role == .boss && state.job.tier == .skilled ? .pivotal : .recurring)
        state.npcs[role] = LifeGenerationSystem.generatedNPC(role: role, importance: importance, state: state)
    }

}
