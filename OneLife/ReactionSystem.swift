import Foundation

/// Stable identity adapter for the heterogeneous people stored by the life model.
enum PersonHandle: Codable, Equatable, Hashable, Comparable {
    case partner
    case npc(String)
    case family(String)
    case coworkers

    var stableKey: String {
        switch self {
        case .partner: "00-partner"
        case .npc(let id): "10-\(id)"
        case .family(let id): "20-\(id)"
        case .coworkers: "30-coworkers"
        }
    }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.stableKey < rhs.stableKey }
}

struct PersonView {
    let handle: PersonHandle
    let name: String
    let rapport: Int
    let bond: Int
    let personality: PersonalityProfile
    let tags: [CharacterTag]
}

enum ReactionTrigger: Equatable {
    case action(ActionID, target: PersonReference?)
    case eventChoice(String, subject: PersonHandle?)
    case crime(String, recorded: Bool)
    case gift(PersonHandle, value: Int)
    case yearClose
}

struct ActionContext {
    let trigger: ReactionTrigger
    let age: Int
    let sequence: UInt64
    let directTarget: PersonHandle?

    static func make(_ trigger: ReactionTrigger, state: LifeState) -> ActionContext {
        var target: PersonHandle?
        if case .action(_, let ref) = trigger, let ref {
            switch ref {
            case .partner: target = .partner
            case .cast(let id): target = .npc(id)
            case .family(let id): target = .family(id)
            }
        }
        return ActionContext(trigger: trigger, age: state.character.age, sequence: state.historySequence &+ 1, directTarget: target)
    }
}

enum ReactionTier: Int, Codable, Comparable { case silent, visible, deferred
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum DeferredReactionKind: String, Codable, CaseIterable { case partnerAbsence, bossSidelines, bossBacksRaise, familyDistance }

struct DeferredReaction: Codable, Equatable, Identifiable {
    var id: String { "\(kind.rawValue):\(person.stableKey)" }
    var kind: DeferredReactionKind
    var person: PersonHandle
    var pressure: Int
    var createdAge: Int
    var sourceAction: ActionID
    var visibleAtCreation: Bool
}

struct ReactionState: Codable, Equatable {
    var pending: [DeferredReaction] = []
    var recentLineIDs: [String] = []
    var reactedThisAge: Set<String> = []

    mutating func remember(_ id: String) {
        recentLineIDs.removeAll { $0 == id }
        recentLineIDs.insert(id, at: 0)
        recentLineIDs = Array(recentLineIDs.prefix(12))
    }

    mutating func enqueue(_ item: DeferredReaction) {
        if let index = pending.firstIndex(where: { $0.id == item.id }) {
            pending[index].pressure = min(8, pending[index].pressure + item.pressure)
            pending[index].createdAge = min(pending[index].createdAge, item.createdAge)
            pending[index].visibleAtCreation = pending[index].visibleAtCreation || item.visibleAtCreation
        } else if pending.count < 8 {
            pending.append(item)
        }
    }

    mutating func clamp() {
        pending = Array(Dictionary(grouping: pending, by: \.id).values.compactMap(\.first)
            .sorted { $0.id < $1.id }.prefix(ReactionTuning.pendingCap))
        recentLineIDs = Array(recentLineIDs.prefix(12))
        if reactedThisAge.count > 32 { reactedThisAge = Set(reactedThisAge.sorted().suffix(32)) }
    }
}

struct ReactionLineTemplate: Codable, Equatable, Identifiable {
    let id: String
    let action: ActionID?
    var trigger: String? = nil
    let audience: String
    let text: String
}

enum ReactionLineContent {
    static let allowedSlots: Set<String> = ["person"]
    static let templates: [ReactionLineTemplate] = {
        guard let url = Bundle.main.url(forResource: "ReactionLines", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ReactionLineTemplate].self, from: data),
              validate(decoded) == nil else { return [] }
        return decoded
    }()

    static func validate(_ lines: [ReactionLineTemplate]) -> String? {
        guard Set(lines.map(\.id)).count == lines.count else { return "Duplicate reaction line ID" }
        let reachableActions: [ActionID: Set<String>] = [
            .workShift: ["coworker", "partner"],
            .acceptOvertime: ["boss", "coworker", "partner"],
            .negotiateRaise: ["boss", "coworker", "partner"],
            .buildWorkplaceRelationship: ["boss", "coworker", "partner"],
            .familyDinner: ["family"]
        ]
        let reachableTriggers: [String: Set<String>] = [
            "eventChoice": ["partner", "family", "boss", "coworker"],
            "gift": ["partner", "family", "boss", "coworker"],
            "crime": ["family"]
        ]
        for line in lines {
            let expression = try! NSRegularExpression(pattern: "\\{([a-zA-Z]+)\\}")
            let range = NSRange(line.text.startIndex..., in: line.text)
            let slots = expression.matches(in: line.text, range: range).compactMap { match -> String? in
                guard let capture = Range(match.range(at: 1), in: line.text) else { return nil }
                return String(line.text[capture])
            }
            let withoutSlots = expression.stringByReplacingMatches(in: line.text, range: range, withTemplate: "")
            guard !withoutSlots.contains("{") && !withoutSlots.contains("}") else { return "Malformed slot in \(line.id)" }
            guard slots.allSatisfy(allowedSlots.contains) else { return "Invalid slot in \(line.id)" }
            if let action = line.action {
                guard line.trigger == nil, reachableActions[action]?.contains(line.audience) == true else { return "Unreachable action template \(line.id)" }
            } else if let trigger = line.trigger {
                guard reachableTriggers[trigger]?.contains(line.audience) == true else { return "Unreachable trigger template \(line.id)" }
            } else { return "Template \(line.id) has no trigger" }
        }
        guard lines.filter({ $0.action != nil }).count >= 30 else { return "At least 30 action lines are required" }
        for action in ReactionResolver.registeredActions where lines.filter({ $0.action == action }).count < 2 {
            return "Action \(action.rawValue) has fewer than two reaction lines"
        }
        return nil
    }

    static func render(action: ActionID, audience: String, person: String, avoiding: [String]) -> (String, String)? {
        render(where: { $0.action == action && $0.audience == audience }, person: person, avoiding: avoiding)
    }

    static func render(trigger: String, audience: String, person: String, avoiding: [String]) -> (String, String)? {
        render(where: { $0.trigger == trigger && $0.audience == audience }, person: person, avoiding: avoiding)
    }

    private static func render(where predicate: (ReactionLineTemplate) -> Bool, person: String, avoiding: [String]) -> (String, String)? {
        let candidates = templates.filter { predicate($0) && !$0.id.isEmpty }
        guard let choice = candidates.first(where: { !avoiding.contains($0.id) }) else { return nil }
        return (choice.id, choice.text.replacingOccurrences(of: "{person}", with: person))
    }
}

enum ReactionTuning {
    static let maxPeople = 6
    static let maxVisible = 2
    static let pendingCap = 8
    static let maturityPressure = 3
    static let maxVisibleMaturitiesPerYear = 2
}

struct ReactionPassResult: Equatable {
    var visibleLines: [String] = []
    var impact: ActionImpact?
    var evaluatedPeople = 0
}

struct ReactionCandidate {
    let person: PersonView
    let delta: Int
    let pressure: Int
    let kind: DeferredReactionKind
    let audience: String
    let impactLabel: String
    let tier: ReactionTier
    let salience: Int
}

struct ReactionProposal {
    let delta: Int
    let pressure: Int
    let kind: DeferredReactionKind
    let audience: String
    let impactLabel: String
}

enum WorkplaceReactor {
    static func linkedPeople(for action: ActionID, state: LifeState) -> [PersonHandle] {
        guard [.workShift, .acceptOvertime, .negotiateRaise, .buildWorkplaceRelationship].contains(action) else { return [] }
        let directRole = DomainActionRegistry.action(for: action).npcRole
        var people: [PersonHandle] = []
        if directRole != .boss, let boss = state.npcs[.boss] { people.append(.npc(boss.memberID)) }
        if [.workShift, .acceptOvertime, .negotiateRaise, .buildWorkplaceRelationship].contains(action) {
            people += state.npcs.all.filter { $0.connections.contains { $0.kind == .coworker && $0.isCurrent } }.map { .npc($0.memberID) }
            people.append(.coworkers)
        }
        return people
    }

    static func candidate(action: ActionID, person: PersonView, state: LifeState) -> ReactionProposal? {
        if case .npc(let id) = person.handle, let npc = state.npcs.member(id: id), npc.role == .boss {
            if action == .negotiateRaise, npc.coreFlags.contains(.fair), state.career.performance >= 60, state.career.workplace.managerRelationship >= 60 {
                return ReactionProposal(delta: 2, pressure: ReactionTuning.maturityPressure, kind: .bossBacksRaise, audience: "boss", impactLabel: "Boss rapport")
            }
            let delta = action == .buildWorkplaceRelationship ? 2 : (action == .negotiateRaise && person.tags.contains(.vindictive) ? -2 : -1)
            return ReactionProposal(delta: delta, pressure: action == .negotiateRaise ? 2 : 0, kind: .bossSidelines, audience: "boss", impactLabel: "Boss rapport")
        }
        if case .npc(let id) = person.handle,
           state.npcs.member(id: id)?.connections.contains(where: { $0.kind == .coworker && $0.isCurrent }) == true {
            return ReactionProposal(delta: action == .buildWorkplaceRelationship ? 1 : -1, pressure: 0, kind: .familyDistance, audience: "coworker", impactLabel: "Coworker rapport")
        }
        if person.handle == .coworkers {
            return ReactionProposal(delta: action == .buildWorkplaceRelationship ? 2 : -1, pressure: 0, kind: .familyDistance, audience: "coworker", impactLabel: "Coworker standing")
        }
        return nil
    }
}

enum HouseholdReactor {
    static func linkedPeople(for action: ActionID, target: PersonHandle?, state: LifeState) -> [PersonHandle] {
        var people: [PersonHandle] = []
        if let target, case .npc = target, state.partner != nil { people.append(.partner) }
        if action == .familyDinner { people += state.family.contacts.map { .family($0.id) } }
        return people
    }

    static func candidate(action: ActionID, person: PersonView) -> ReactionProposal? {
        if person.handle == .partner && (action == .workShift || action == .acceptOvertime) {
            return ReactionProposal(delta: -1, pressure: 0, kind: .partnerAbsence, audience: "partner", impactLabel: "Partner bond")
        }
        if case .family = person.handle, action == .familyDinner {
            return ReactionProposal(delta: person.personality.has(.empathetic) ? 2 : 1, pressure: 0, kind: .familyDistance, audience: "family", impactLabel: "Family bond")
        }
        return nil
    }
}

/// Registered-action propagation. Legacy SocialReactivitySystem remains the owner
/// of the direct target; this pass only considers other linked people and workplace ties.
enum ReactionResolver {
    static let registeredActions: Set<ActionID> = [.workShift, .acceptOvertime, .negotiateRaise, .buildWorkplaceRelationship, .familyDinner]

    static func run(_ trigger: ReactionTrigger, enabled: Bool = true, state: inout LifeState) -> ReactionPassResult {
        guard enabled else { return ReactionPassResult() }
        switch trigger {
        case .action(let action, _):
            guard registeredActions.contains(action) else { return ReactionPassResult() }
            return runAction(action, trigger: trigger, state: &state)
        case .eventChoice(_, let subject): return surface("eventChoice", person: subject, state: &state)
        case .gift(let person, _): return surface("gift", person: person, state: &state)
        case .crime(_, let recorded):
            guard recorded, let contact = state.family.contacts.sorted(by: {
                $0.bond == $1.bond ? $0.id < $1.id : $0.bond > $1.bond
            }).first else { return ReactionPassResult() }
            if let index = state.family.contacts.firstIndex(where: { $0.id == contact.id }) { state.family.contacts[index].bond = max(0, state.family.contacts[index].bond - 2); state.family.clamp() }
            return surface("crime", person: .family(contact.id), state: &state)
        case .yearClose: return ReactionPassResult()
        }
    }

    private static func runAction(_ action: ActionID, trigger: ReactionTrigger, state: inout LifeState) -> ReactionPassResult {
        let ctx = ActionContext.make(trigger, state: state)
        if action == .familyDinner {
            for index in state.reactions.pending.indices where state.reactions.pending[index].kind == .partnerAbsence {
                state.reactions.pending[index].pressure = max(0, state.reactions.pending[index].pressure - 2)
            }
            state.reactions.pending.removeAll { $0.kind == .partnerAbsence && $0.pressure == 0 }
        }
        if [.workShift, .acceptOvertime, .negotiateRaise, .buildWorkplaceRelationship].contains(action) {
            ensureWorkplaceCast(state: &state)
        }
        let linkedPeople = WorkplaceReactor.linkedPeople(for: action, state: state)
            + HouseholdReactor.linkedPeople(for: action, target: ctx.directTarget, state: state)
        let handles = Array(Set(linkedPeople)).sorted { lhs, rhs in
            let lp = priority(lhs, action: action, state: state), rp = priority(rhs, action: action, state: state)
            return lp == rp ? lhs < rhs : lp < rp
        }.prefix(ReactionTuning.maxPeople)

        var candidates: [ReactionCandidate] = handles.compactMap { handle in
            guard let person = view(handle, state: state) else { return nil }
            guard let proposal = WorkplaceReactor.candidate(action: action, person: person, state: state)
                    ?? HouseholdReactor.candidate(action: action, person: person) else { return nil }
            let relationshipWeight = abs(person.rapport) / 2 + person.bond / 4
            let actionStake = (proposal.pressure * 8) + abs(proposal.delta) * 3
            let tieBreak = priority(handle, action: action, state: state)
            let salience = max(0, min(100, relationshipWeight + actionStake + 12 - tieBreak * 3))
            return ReactionCandidate(
                person: person,
                delta: proposal.delta,
                pressure: proposal.pressure,
                kind: proposal.kind,
                audience: proposal.audience,
                impactLabel: proposal.impactLabel,
                tier: proposal.pressure > 0 ? .deferred : .visible,
                salience: salience
            )
        }
        candidates.sort {
            if $0.tier != $1.tier { return $0.tier > $1.tier }
            if $0.salience != $1.salience { return $0.salience > $1.salience }
            return $0.person.handle < $1.person.handle
        }
        var result = ReactionPassResult(evaluatedPeople: handles.count)
        var visibleCount = 0
        for candidate in candidates {
            let handle = candidate.person.handle
            ReactionEffectApplier.apply(candidate, action: action, state: &state)
            guard visibleCount < ReactionTuning.maxVisible,
                  let line = ReactionLineContent.render(action: action, audience: candidate.audience, person: candidate.person.name, avoiding: Array(state.reactions.recentLineIDs.prefix(3))) else { continue }
            state.reactions.remember(line.0)
            if case .npc(let id) = handle { state.reactions.reactedThisAge.insert("npc:\(id):\(ctx.age)") }
            result.visibleLines.append(line.1)
            visibleCount += 1
            if candidate.pressure > 0 {
                state.reactions.enqueue(DeferredReaction(kind: candidate.kind, person: handle, pressure: candidate.pressure, createdAge: ctx.age, sourceAction: action, visibleAtCreation: true))
            }
            if result.impact == nil {
                result.impact = ActionImpact(domain: .relationships, label: candidate.impactLabel, change: candidate.delta == 0 ? nil : candidate.delta)
            }
        }
        return result
    }

    private static func surface(_ trigger: String, person handle: PersonHandle?, state: inout LifeState) -> ReactionPassResult {
        guard let handle, let person = view(handle, state: state) else { return ReactionPassResult() }
        let audience: String
        switch handle {
        case .partner: audience = "partner"
        case .family: audience = "family"
        case .coworkers: audience = "coworker"
        case .npc(let id): audience = state.npcs.member(id: id)?.role == .boss ? "boss" : "coworker"
        }
        guard let line = ReactionLineContent.render(trigger: trigger, audience: audience, person: person.name, avoiding: Array(state.reactions.recentLineIDs.prefix(3))) else { return ReactionPassResult() }
        state.reactions.remember(line.0)
        if case .npc(let id) = handle { state.reactions.reactedThisAge.insert("npc:\(id):\(state.character.age)") }
        return ReactionPassResult(visibleLines: [line.1], impact: ActionImpact(domain: .relationships, label: "Relationship", change: nil))
    }

    static func matureYear(state: inout LifeState) -> [String] {
        state.reactions.reactedThisAge.removeAll()
        var bullets: [String] = []
        var retained: [DeferredReaction] = []
        for item in state.reactions.pending.sorted(by: { $0.id < $1.id }) {
            guard item.createdAge < state.character.age else { retained.append(item); continue }
            guard item.pressure >= ReactionTuning.maturityPressure else { continue }
            switch item.kind {
            case .partnerAbsence:
                if state.partner != nil, item.person == .partner {
                    RelationshipSystem.applyReaction(resentmentDelta: item.pressure, state: &state)
                    let partner = state.partner!
                    if item.visibleAtCreation { bullets.append("\(partner.name) stopped treating the missed time as a one-off.") }
                }
            case .bossSidelines:
                CareerSystem.applyReaction(managerDelta: -item.pressure, leverageDelta: -item.pressure * 2, state: &state)
                if case .npc(let id) = item.person, let boss = state.npcs.member(id: id) {
                    DynamicCastSystem.applyReactionRapport(-item.pressure, memberID: id, state: &state)
                    state.reactions.reactedThisAge.insert("npc:\(id):\(state.character.age)")
                    if item.visibleAtCreation { bullets.append("\(boss.name) passed you over after the raise talk.") }
                }
            case .bossBacksRaise:
                CareerSystem.applyReaction(managerDelta: item.pressure, leverageDelta: item.pressure * 2, state: &state)
                if case .npc(let id) = item.person, let boss = state.npcs.member(id: id) {
                    DynamicCastSystem.applyReactionRapport(item.pressure, memberID: id, state: &state)
                    state.reactions.reactedThisAge.insert("npc:\(id):\(state.character.age)")
                    if item.visibleAtCreation { bullets.append("\(boss.name) backed your raise after reviewing the year.") }
                }
            case .familyDistance:
                if case .family(let id) = item.person, let contact = state.family.contacts.first(where: { $0.id == id }) {
                    FamilySystem.applyReactionBond(-item.pressure, contactID: id, state: &state)
                    if item.visibleAtCreation { bullets.append("\(contact.name) stopped making the first call.") }
                }
            }
        }
        state.reactions.pending = Array(retained.prefix(ReactionTuning.pendingCap))
        return Array(bullets.prefix(ReactionTuning.maxVisibleMaturitiesPerYear))
    }

    private static func priority(_ handle: PersonHandle, action: ActionID, state: LifeState) -> Int {
        switch handle {
        case .npc(let id): state.npcs.member(id: id)?.role == .boss ? 0 : 2
        case .partner: 1
        case .family: action == .familyDinner ? 1 : 3
        case .coworkers: 4
        }
    }

    private static func view(_ handle: PersonHandle, state: LifeState) -> PersonView? {
        switch handle {
        case .partner: guard let p = state.partner else { return nil }; return PersonView(handle: handle, name: p.name, rapport: p.bond - p.resentment, bond: p.bond, personality: p.personality, tags: [])
        case .npc(let id): guard let p = state.npcs.member(id: id) else { return nil }; return PersonView(handle: handle, name: p.name, rapport: p.rapport, bond: p.bond, personality: p.personality, tags: p.stableTags)
        case .family(let id): guard let p = state.family.contacts.first(where: { $0.id == id }) else { return nil }; return PersonView(handle: handle, name: p.name, rapport: p.bond - 45, bond: p.bond, personality: p.personality, tags: [])
        case .coworkers: return PersonView(handle: handle, name: "Your coworkers", rapport: state.career.workplace.coworkerStanding - 45, bond: 45, personality: .neutral, tags: [])
        }
    }

    private static func ensureWorkplaceCast(state: inout LifeState) {
        guard state.career.level.isEmployed else { return }
        if state.npcs[.boss] == nil {
            let importance: NPCImportance = state.career.level == .senior ? .pivotal : .recurring
            state.npcs[.boss] = LifeGenerationSystem.generatedNPC(role: .boss, importance: importance, state: state)
        }
        let employerStartAge = state.character.age - state.career.workplace.yearsAtEmployer
        let employerID = "employer-\(state.career.workplace.employer.rawValue)-\(employerStartAge)"
        for var npc in state.npcs.all where npc.connections.contains(where: { $0.kind == .coworker && $0.isCurrent }) && !npc.memberID.contains(employerID) {
            for i in npc.connections.indices where npc.connections[i].kind == .coworker && npc.connections[i].isCurrent { npc.connections[i].endedAge = state.character.age }
            npc.activity = .dormant
            state.npcs.update(npc)
        }
        let existing = state.npcs.all.filter { $0.memberID.contains(employerID) && $0.connections.contains { $0.kind == .coworker && $0.isCurrent } }
        if existing.isEmpty {
            for index in 0..<3 {
                let id = "coworker-\(employerID)-\(index + 1)"
                var rng = SimulationRandomStreams.npcStream(runSeed: state.runSeed, identity: id)
                let names = ["Dana", "Marcus", "Elena", "Ravi", "Tess", "Owen"]
                let name = names[rng.next(in: 0...(names.count - 1))]
                let npc = NPCState(memberID: id, name: name, role: .friend, importance: .recurring, coreFlags: [], connections: [NPCConnection(kind: .coworker, startedAge: state.character.age)], lastInteractionAge: state.character.age)
                state.npcs.insert(npc)
            }
        }
    }

}

enum ReactionEffectApplier {
    static func apply(_ candidate: ReactionCandidate, action: ActionID, state: inout LifeState) {
        let person = candidate.person.handle
        switch candidate.kind {
        case .partnerAbsence:
            if action == .familyDinner || candidate.delta > 0 { RelationshipSystem.applyReaction(bondDelta: candidate.delta, resentmentDelta: -abs(candidate.delta) * 2, state: &state) }
            else { RelationshipSystem.applyReaction(resentmentDelta: abs(candidate.delta), state: &state) }
        case .bossSidelines, .bossBacksRaise:
            if case .npc(let id) = person { DynamicCastSystem.applyReactionRapport(candidate.delta, memberID: id, state: &state) }
            CareerSystem.applyReaction(managerDelta: candidate.delta, state: &state)
            if candidate.kind == .bossSidelines, action == .buildWorkplaceRelationship, let index = state.reactions.pending.firstIndex(where: { $0.kind == .bossSidelines }) {
                state.reactions.pending[index].pressure = max(0, state.reactions.pending[index].pressure - 2)
                if state.reactions.pending[index].pressure == 0 { state.reactions.pending.remove(at: index) }
            }
        case .familyDistance:
            if case .npc(let id) = person, let npc = state.npcs.member(id: id), npc.connections.contains(where: { $0.kind == .coworker && $0.isCurrent }) {
                DynamicCastSystem.applyReactionRapport(candidate.delta, memberID: id, state: &state)
            }
            if person == .coworkers { CareerSystem.applyReaction(coworkerDelta: candidate.delta, state: &state) }
            if action == .familyDinner, case .family(let id) = person { FamilySystem.applyReactionBond(candidate.delta, contactID: id, state: &state) }
        }
    }

}
