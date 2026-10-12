import Foundation

enum SituationStage: String, Codable, CaseIterable {
    case opening, active, reckoning
}

enum SituationSignal: String, Codable, CaseIterable {
    case pursuedWork, protectedBoundaries, madeTime, repairedConflict, prioritizedFamily
}

struct ResolvedSituation: Codable, Equatable, Identifiable {
    var id: String { "\(kind)-\(startedAge)-\(resolvedAge)" }
    let kind: String
    let title: String
    let startedAge: Int
    let resolvedAge: Int
    let outcome: String
}

enum CareerSituationKind: String, Codable {
    case promotionTrack, workFollowsHome

    var title: String {
        switch self {
        case .promotionTrack: "The Promotion Track"
        case .workFollowsHome: "Work Follows You Home"
        }
    }
}

struct CareerSituation: Codable, Equatable {
    var kind: CareerSituationKind
    var stage: SituationStage = .opening
    var startedAge: Int
    var remainingYears: Int = 3
    var commitment = 0
    var pressure = 0
    var choices: [SituationSignal] = []

    var stakes: String {
        switch kind {
        case .promotionTrack: "Commitment \(commitment) · pressure \(pressure) · \(remainingYears)y left"
        case .workFollowsHome: "Work pull \(commitment) · home strain \(pressure) · \(remainingYears)y left"
        }
    }

    var suggestedAction: ActionID {
        switch kind {
        case .promotionTrack: pressure >= 6 ? .protectBoundaries : .pursuePromotion
        case .workFollowsHome: pressure >= commitment ? .familyDinner : .protectBoundaries
        }
    }
}

enum RelationshipSituationKind: String, Codable {
    case distance
    var title: String { "The Distance Between You" }
}

struct RelationshipSituation: Codable, Equatable {
    var kind: RelationshipSituationKind = .distance
    var stage: SituationStage = .opening
    var startedAge: Int
    var remainingYears: Int = 2
    var repairProgress = 0
    var strain = 0
    var choices: [SituationSignal] = []

    var stakes: String { "Repair \(repairProgress) · strain \(strain) · \(remainingYears)y left" }
    var suggestedAction: ActionID { strain >= repairProgress ? .repairConflict : .familyDinner }
}

struct SituationYearResolution: Equatable {
    var bullets: [String] = []
    var consequences: [DomainConsequence] = []
    var milestoneHeadline: String?
    var milestoneDetail: String?
}

enum SituationSignalResolver {
    static func signal(for action: ActionID) -> SituationSignal? {
        switch action {
        case .workShift, .pursuePromotion, .developSkill, .sideHustle: .pursuedWork
        case .protectBoundaries, .rest: .protectedBoundaries
        case .reachOut, .goOnDate, .familyDinner, .parentingPresence, .caregiving: .madeTime
        case .repairConflict, .therapySupport: .repairedConflict
        case .deepenCommitment, .marry, .familyPlanning: .prioritizedFamily
        default: nil
        }
    }
}

enum CareerSituationSystem {
    static func record(_ signal: SituationSignal, state: inout LifeState) {
        guard var situation = state.career.activeSituation else { return }
        situation.choices.append(signal)
        situation.choices = Array(situation.choices.suffix(8))
        switch signal {
        case .pursuedWork: situation.commitment += 2; situation.pressure += 1
        case .protectedBoundaries: situation.pressure = max(0, situation.pressure - 3); situation.commitment = max(0, situation.commitment - 1)
        case .madeTime, .repairedConflict, .prioritizedFamily:
            if situation.kind == .workFollowsHome { situation.pressure = max(0, situation.pressure - 2) }
        }
        state.career.activeSituation = situation
    }

    static func resolveYear(state: inout LifeState) -> SituationYearResolution {
        if state.career.activeSituation == nil { openIfEligible(state: &state) }
        guard var situation = state.career.activeSituation else { return SituationYearResolution() }
        situation.remainingYears -= 1
        situation.stage = situation.remainingYears <= 1 ? .reckoning : .active
        if situation.kind == .workFollowsHome, let partner = state.partner {
            situation.pressure += partner.neglectStreak + max(0, partner.resentment - 35) / 15
        }
        if situation.remainingYears > 0 {
            state.career.activeSituation = situation
            return SituationYearResolution(bullets: ["\(situation.kind.title): \(situation.stage.rawValue)"])
        }
        return resolve(situation, state: &state)
    }

    private static func openIfEligible(state: inout LifeState) {
        guard state.career.level.isEmployed, state.lifeStage != .legacy else { return }
        if let partner = state.partner,
           partner.committed,
           (state.career.burnout >= 55 || partner.neglectStreak >= 2) {
            state.career.activeSituation = CareerSituation(kind: .workFollowsHome, startedAge: state.character.age)
        } else if state.career.level == .established, state.career.performance >= 62 {
            state.career.activeSituation = CareerSituation(kind: .promotionTrack, startedAge: state.character.age)
        }
    }

    private static func resolve(_ situation: CareerSituation, state: inout LifeState) -> SituationYearResolution {
        let outcome: String
        var result = SituationYearResolution()
        switch situation.kind {
        case .promotionTrack:
            if situation.commitment >= 5, situation.pressure < 8, state.career.performance >= 68 {
                if state.career.level == .established { state.career.level = .senior }
                state.career.lastTransition = .promoted
                outcome = "You earned the role without letting the pursuit consume you."
                result.milestoneHeadline = "The Promotion Became Yours"
            } else if situation.pressure >= 8 {
                state.career.burnout += 10
                outcome = "The pursuit ended in withdrawal under accumulated burnout."
                result.milestoneHeadline = "The Promotion Cost Too Much"
                result.consequences.append(.init(source: .career, target: .health, kind: .burnout, magnitude: .major, openedAge: state.character.age, yearsRemaining: 3, headline: "The promotion chase depleted you", detail: "The body keeps the cost after the opportunity closes."))
            } else {
                state.career.security += 4
                outcome = "You kept a sustainable foothold but did not win the promotion."
                result.milestoneHeadline = "The Promotion Passed You By"
            }
        case .workFollowsHome:
            let familyChoices = situation.choices.filter { [.madeTime, .repairedConflict, .prioritizedFamily, .protectedBoundaries].contains($0) }.count
            if familyChoices >= 2, situation.pressure <= situation.commitment + 2 {
                state.career.burnout -= 8
                outcome = "Measured boundaries preserved trust without ending your work."
                result.milestoneHeadline = "Work Stopped Owning The House"
            } else if situation.commitment >= 5 {
                state.career.performance += 6
                outcome = "Work advanced while the household absorbed the cost."
                result.milestoneHeadline = "Work Won The Argument"
                result.consequences.append(.init(source: .career, target: .relationships, kind: .burnout, magnitude: .major, openedAge: state.character.age, yearsRemaining: 3, headline: "Work displaced the relationship", detail: "The gain at work left less trust at home."))
            } else {
                state.career.performance -= 4
                outcome = "You released the opportunity and protected what remained at home."
                result.milestoneHeadline = "You Chose The Life Outside Work"
            }
        }
        result.milestoneDetail = outcome
        state.career.resolvedSituations.insert(.init(kind: situation.kind.rawValue, title: situation.kind.title, startedAge: situation.startedAge, resolvedAge: state.character.age, outcome: outcome), at: 0)
        state.career.resolvedSituations = Array(state.career.resolvedSituations.prefix(4))
        state.career.activeSituation = nil
        state.career.clamp()
        return result
    }
}

enum RelationshipSituationSystem {
    static func record(_ signal: SituationSignal, state: inout LifeState) {
        guard var partner = state.partner, var situation = partner.activeSituation else { return }
        situation.choices.append(signal)
        situation.choices = Array(situation.choices.suffix(8))
        switch signal {
        case .madeTime, .prioritizedFamily: situation.repairProgress += 2; situation.strain = max(0, situation.strain - 1)
        case .repairedConflict: situation.repairProgress += 3; situation.strain = max(0, situation.strain - 2)
        case .pursuedWork: situation.strain += 2
        case .protectedBoundaries: situation.repairProgress += 1
        }
        partner.activeSituation = situation
        state.partner = partner
    }

    static func resolveYear(state: inout LifeState) -> SituationYearResolution {
        guard var partner = state.partner else { return SituationYearResolution() }
        if partner.activeSituation == nil,
           partner.committed,
           (partner.neglectStreak >= 2 || partner.resentment >= 45) {
            partner.activeSituation = RelationshipSituation(startedAge: state.character.age, strain: max(2, partner.neglectStreak))
        }
        guard var situation = partner.activeSituation else { state.partner = partner; return SituationYearResolution() }
        situation.remainingYears -= 1
        situation.strain += partner.neglectStreak > 0 ? 1 : 0
        situation.stage = situation.remainingYears <= 1 ? .reckoning : .active
        if situation.remainingYears > 0 {
            partner.activeSituation = situation
            state.partner = partner
            return SituationYearResolution(bullets: ["\(situation.kind.title): \(situation.stage.rawValue)"])
        }
        let outcome: String
        let headline: String
        if situation.repairProgress >= 5, situation.repairProgress > situation.strain {
            partner.bond += 10; partner.resentment -= 15; partner.ruptureStage = .stable; partner.repairPromise = false
            headline = "You Closed The Distance"
            outcome = "Follow-through rebuilt trust over time."
        } else if situation.repairProgress >= situation.strain {
            partner.bond += 3; partner.resentment -= 4
            headline = "The Relationship Found Uneasy Ground"
            outcome = "The relationship held, but the distance did not disappear."
        } else {
            let name = partner.name
            partner.activeSituation = nil
            state.partner = partner
            RelationshipSystem.endCurrent(.partnerLeftAfterRupture, state: &state)
            return finish(situation, headline: "The Distance Became The Ending", outcome: "\(name) left after two years without enough repair.", state: &state)
        }
        partner.clamp()
        partner.activeSituation = nil
        let record = ResolvedSituation(kind: situation.kind.rawValue, title: situation.kind.title, startedAge: situation.startedAge, resolvedAge: state.character.age, outcome: outcome)
        partner.resolvedSituations.insert(record, at: 0)
        partner.resolvedSituations = Array(partner.resolvedSituations.prefix(4))
        state.partner = partner
        remember(record, state: &state)
        return SituationYearResolution(milestoneHeadline: headline, milestoneDetail: outcome)
    }

    private static func finish(_ situation: RelationshipSituation, headline: String, outcome: String, state: inout LifeState) -> SituationYearResolution {
        remember(.init(kind: situation.kind.rawValue, title: situation.kind.title, startedAge: situation.startedAge, resolvedAge: state.character.age, outcome: outcome), state: &state)
        return SituationYearResolution(milestoneHeadline: headline, milestoneDetail: outcome)
    }

    private static func remember(_ record: ResolvedSituation, state: inout LifeState) {
        state.resolvedRelationshipSituations.insert(record, at: 0)
        state.resolvedRelationshipSituations = Array(state.resolvedRelationshipSituations.prefix(6))
    }
}

enum SituationActionCoordinator {
    static func record(action: ActionID, state: inout LifeState) {
        guard let signal = SituationSignalResolver.signal(for: action) else { return }
        CareerSituationSystem.record(signal, state: &state)
        RelationshipSituationSystem.record(signal, state: &state)
    }
}

// MARK: - Phase 1: passive family appraisal

/// Resolves lightweight relationship movement from the player's life rather
/// than requiring a maintenance action for every family member. It is only
/// active while family exists; contacts otherwise remain completely dormant.
struct FamilyAppraisalResolution: Equatable {
    var bullets: [String] = []
    var milestoneHeadline: String?
    var milestoneDetail: String?
}

enum FamilyAppraisalSystem {
    static func resolveYear(
        state: inout LifeState,
        snapshot: YearInfluenceSnapshot
    ) -> FamilyAppraisalResolution {
        var result = FamilyAppraisalResolution()
        let age = state.character.age
        let familyFocused = snapshot.scores.family >= 2
        let workDisplacedFamily = snapshot.scores.work >= 3 && snapshot.scores.family == 0

        // Children are always consequential, but never require a separate
        // relationship screen. Presence earns a small durable bond; a year
        // spent wholly at work makes absence visible without becoming a death
        // spiral.
        for index in state.family.children.indices where state.family.children[index].dependent {
            if familyFocused {
                state.family.children[index].bond += 2
            } else if workDisplacedFamily {
                state.family.children[index].bond -= 2
            }
        }

        for index in state.family.contacts.indices {
            var contact = state.family.contacts[index]
            var delta = 0
            var reason: String?

            // A legal break is an event, not a recurring annual punishment.
            if state.legal.isFelon, state.legal.lastFirearmConsequenceAge == age {
                delta -= 7
                if contact.personality.has(.cautious) || contact.personality.has(.steadfast) { delta -= 5 }
                if contact.personality.has(.empathetic) { delta -= 2 }
                reason = "the felony case"
            } else if familyFocused {
                delta += contact.personality.has(.empathetic) ? 4 : 2
                reason = "the care you made room for"
            } else if workDisplacedFamily, contact.personality.has(.empathetic) || contact.personality.has(.steadfast) {
                delta -= 3
                reason = "how little room family had this year"
            }

            guard delta != 0 else { continue }
            let previous = contact.stance
            contact.bond += delta
            contact.lastJudgementAge = age
            contact.lastJudgementReason = reason
            contact.stance = stance(for: contact.bond)
            state.family.contacts[index] = contact

            if contact.stance != previous {
                let direction = contact.stance == .warm ? "moved closer" : (contact.stance == .estranged ? "pulled away" : "grew guarded")
                result.bullets.append("\(contact.name) \(direction)")
                if contact.stance == .estranged {
                    result.milestoneHeadline = "\(contact.name) Pulled Away"
                    result.milestoneDetail = "Your \(contact.role.rawValue) could not make peace with \(reason ?? "the life taking shape")."
                }
            }
        }
        state.family.clamp()
        return result
    }

    private static func stance(for bond: Int) -> FamilyContactStance {
        switch bond {
        case 70...: .warm
        case ..<25: .estranged
        case ..<45: .strained
        default: .neutral
        }
    }
}

// MARK: - Phase 2: dynamic cast activation

/// The cast is identity-keyed and state-contingent. This system owns activity,
/// remembered interaction, and reactivation; it never resolves career, money,
/// legal, or health consequences itself.
struct CastYearResolution: Equatable {
    var bullets: [String] = []
}

enum PlayerIntent: String, Codable, CaseIterable {
    case protect, advance, hide, disclose, exploit, repair, withdraw, commit, postpone, challenge

    var title: String {
        switch self {
        case .protect: "Protect"
        case .advance: "Advance"
        case .hide: "Hide"
        case .disclose: "Disclose"
        case .exploit: "Exploit"
        case .repair: "Repair"
        case .withdraw: "Withdraw"
        case .commit: "Commit"
        case .postpone: "Postpone"
        case .challenge: "Challenge"
        }
    }
}

enum LifeSignalSource: String, Codable {
    case instantAction
    case eventChoice
    case yearlyResolution
}

enum LifeSignalCommitment: String, Codable {
    case availability, secrecy, repayment, care, loyalty, responsibility, ambition
}

enum LifeSignalExposure: String, Codable {
    case personal, household, network, publicFacing
}

enum LifeSignalKind: String, Codable, CaseIterable {
    case careerPromotion, careerLoss, financialCrisis, healthCrisis
    case graduation, newPartnership, separation, newChild, foreclosure
    case publicSuccess, recovery, playerDecision
}

enum LifeSignalMagnitude: Int, Codable, Comparable {
    case minor = 1, major = 2, critical = 3
    static func < (lhs: LifeSignalMagnitude, rhs: LifeSignalMagnitude) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Facts emitted by sovereign domains and interpreted by Social. They contain
/// no flavor text and never mutate another domain directly.
struct LifeSignal: Codable, Equatable, Identifiable {
    var kind: LifeSignalKind
    var magnitude: LifeSignalMagnitude
    var age: Int
    var sourceHeadline: String
    var source: LifeSignalSource = .yearlyResolution
    var intent: PlayerIntent? = nil
    var affectedDomains: [ConsequenceDomain] = []
    var affectedPeople: [String] = []
    var commitment: LifeSignalCommitment? = nil
    var exposure: LifeSignalExposure = .personal
    var unresolvedPressure: Int = 0
    var id: String { "\(age)-\(kind.rawValue)" }

    private enum CodingKeys: String, CodingKey {
        case kind, magnitude, age, sourceHeadline, source, intent, affectedDomains
        case affectedPeople, commitment, exposure, unresolvedPressure
    }

    init(
        kind: LifeSignalKind,
        magnitude: LifeSignalMagnitude,
        age: Int,
        sourceHeadline: String,
        source: LifeSignalSource = .yearlyResolution,
        intent: PlayerIntent? = nil,
        affectedDomains: [ConsequenceDomain] = [],
        affectedPeople: [String] = [],
        commitment: LifeSignalCommitment? = nil,
        exposure: LifeSignalExposure = .personal,
        unresolvedPressure: Int = 0
    ) {
        self.kind = kind
        self.magnitude = magnitude
        self.age = age
        self.sourceHeadline = sourceHeadline
        self.source = source
        self.intent = intent
        self.affectedDomains = affectedDomains
        self.affectedPeople = affectedPeople
        self.commitment = commitment
        self.exposure = exposure
        self.unresolvedPressure = unresolvedPressure
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(LifeSignalKind.self, forKey: .kind)
        magnitude = try c.decode(LifeSignalMagnitude.self, forKey: .magnitude)
        age = try c.decode(Int.self, forKey: .age)
        sourceHeadline = try c.decode(String.self, forKey: .sourceHeadline)
        source = try c.decodeIfPresent(LifeSignalSource.self, forKey: .source) ?? .yearlyResolution
        intent = try c.decodeIfPresent(PlayerIntent.self, forKey: .intent)
        affectedDomains = try c.decodeIfPresent([ConsequenceDomain].self, forKey: .affectedDomains) ?? []
        affectedPeople = try c.decodeIfPresent([String].self, forKey: .affectedPeople) ?? []
        commitment = try c.decodeIfPresent(LifeSignalCommitment.self, forKey: .commitment)
        exposure = try c.decodeIfPresent(LifeSignalExposure.self, forKey: .exposure) ?? .personal
        unresolvedPressure = try c.decodeIfPresent(Int.self, forKey: .unresolvedPressure) ?? 0
    }
}

enum PlayerDecisionSignalSystem {
    static func signal(for action: DomainAction, state: LifeState) -> LifeSignal {
        let intent = intent(for: action)
        return LifeSignal(
            kind: .playerDecision,
            magnitude: magnitude(for: action, state: state),
            age: state.character.age,
            sourceHeadline: action.name,
            source: .instantAction,
            intent: intent,
            affectedDomains: affectedDomains(for: action),
            affectedPeople: affectedPeople(for: action, state: state),
            commitment: commitment(for: action, intent: intent),
            exposure: exposure(for: action),
            unresolvedPressure: unresolvedPressure(for: action, state: state)
        )
    }

    static func intent(for action: DomainAction) -> PlayerIntent {
        switch action.id {
        case .protectBoundaries, .rest, .seekCare, .preventiveCare, .manageCondition, .cutBack, .quietNight: .protect
        case .pursuePromotion, .developSkill, .networkContacts, .skillCourse, .applyForBetterWork, .buildDiamondCareer: .advance
        case .budget, .payDebt, .negotiateDebt, .adjustRetirement, .sellOrDownsize: .protect
        case .repairConflict, .therapySupport, .reachOut, .familyDinner, .parentingPresence, .caregiving: .repair
        case .separate, .returnToEducation: .withdraw
        case .workShift, .sideHustle, .takePartTimeWork, .chooseOffice, .chooseTrades, .chooseCareService, .chooseFreelance: .commit
        case .party, .goOnDate, .pursueHobby, .seeFriends, .joinClub: .commit
        case .helpAtHome, .deepenCommitment, .marry, .familyPlanning, .chooseChildfree: .protect
        default: action.domain == .cash ? .protect : .commit
        }
    }

    private static func magnitude(for action: DomainAction, state: LifeState) -> LifeSignalMagnitude {
        if action.domainEffects != nil || !action.partnerEffect.isEmpty { return .major }
        if abs(action.influence.work) + abs(action.influence.family) + abs(action.influence.risk) >= 3 { return .major }
        return .minor
    }

    private static func affectedDomains(for action: DomainAction) -> [ConsequenceDomain] {
        var domains: [ConsequenceDomain] = []
        switch action.domain {
        case .school: domains.append(.education)
        case .cash: domains.append(.finance)
        case .love: domains.append(.relationships)
        case .play: domains.append(.relationships)
        case .health: domains.append(.health)
        }
        if action.influence.work != 0 { domains.append(.career) }
        if action.influence.family != 0 { domains.append(.family) }
        return Array(Set(domains))
    }

    private static func affectedPeople(for action: DomainAction, state: LifeState) -> [String] {
        var people: [String] = []
        if action.partnerEffect.isEmpty == false, let partner = state.partner { people.append(partner.name) }
        if let role = action.npcRole, let npc = state.npcs[role] { people.append(npc.name) }
        if action.influence.family != 0 { people.append(contentsOf: state.family.contacts.prefix(2).map(\.name)) }
        return people
    }

    private static func commitment(for action: DomainAction, intent: PlayerIntent) -> LifeSignalCommitment? {
        switch action.id {
        case .workShift, .pursuePromotion, .takePartTimeWork, .buildDiamondCareer: .availability
        case .budget, .payDebt, .negotiateDebt, .adjustRetirement: .repayment
        case .helpAtHome, .familyDinner, .parentingPresence, .caregiving: .care
        case .repairConflict, .reachOut, .deepenCommitment, .marry: .loyalty
        default: intent == .advance ? .ambition : nil
        }
    }

    private static func exposure(for action: DomainAction) -> LifeSignalExposure {
        if action.influence.work >= 3 || action.influence.risk >= 3 { return .network }
        if !action.partnerEffect.isEmpty || action.influence.family > 0 { return .household }
        return .personal
    }

    private static func unresolvedPressure(for action: DomainAction, state: LifeState) -> Int {
        let continuity = action.influence.work > 0
            ? state.career.burnout / 15
            : state.lifeThreads.filter { $0.resolution == .open }.reduce(0) { $0 + $1.intensity / 3 }
        return min(10, max(0, continuity))
    }
}

enum LifeSignalSystem {
    static func detect(
        before: LifeState,
        after: LifeState,
        careerMilestone: String?,
        educationMilestone: String?,
        financialCrisis: Bool,
        healthCrisis: Bool,
        foreclosedCount: Int
    ) -> [LifeSignal] {
        var signals: [LifeSignal] = []
        let age = after.character.age
        func append(_ kind: LifeSignalKind, _ magnitude: LifeSignalMagnitude, _ headline: String) {
            guard !signals.contains(where: { $0.kind == kind }) else { return }
            signals.append(LifeSignal(kind: kind, magnitude: magnitude, age: age, sourceHeadline: headline))
        }

        if careerMilestone?.localizedCaseInsensitiveContains("promotion") == true
            || after.career.lastTransition == .promoted && before.career.level != after.career.level {
            append(.careerPromotion, .major, careerMilestone ?? "Your career moved upward")
        }
        if before.career.level.isEmployed, !after.career.level.isEmployed {
            append(.careerLoss, .major, "Your work disappeared")
        }
        if financialCrisis || before.finance.financialStress < 70 && after.finance.financialStress >= 70 {
            append(.financialCrisis, financialCrisis ? .critical : .major, "Money became an immediate crisis")
        }
        if healthCrisis || before.stats.health >= 40 && after.stats.health < 40 {
            append(.healthCrisis, healthCrisis ? .critical : .major, "Your health became difficult to ignore")
        }
        if educationMilestone?.localizedCaseInsensitiveContains("graduat") == true {
            append(.graduation, .major, educationMilestone ?? "You completed an education chapter")
        }
        if before.partner == nil, after.partner != nil { append(.newPartnership, .major, "A relationship became part of your life") }
        if before.partner != nil, after.partner == nil { append(.separation, .major, "A relationship ended") }
        if after.family.children.count > before.family.children.count { append(.newChild, .major, "Your household grew") }
        if foreclosedCount > 0 { append(.foreclosure, .critical, "A home was lost") }
        if after.stats.rep - before.stats.rep >= 8 { append(.publicSuccess, .major, "Your reputation changed how people saw you") }
        if before.recovery != nil, after.recovery == nil { append(.recovery, .major, "You found a way through the crisis") }

        return signals.sorted {
            if $0.magnitude == $1.magnitude { return $0.kind.rawValue < $1.kind.rawValue }
            return $0.magnitude > $1.magnitude
        }
    }
}

enum NPCObservationSystem {
    static func record(
        personalityFlag: PersonalityFlag? = nil,
        stableTag: CharacterTag? = nil,
        strength: Int = 1,
        age: Int,
        reason: String,
        member: inout NPCState
    ) {
        guard personalityFlag != nil || stableTag != nil else { return }
        guard personalityFlag.map(member.personality.has) ?? true,
              stableTag.map(member.stableTags.contains) ?? true else { return }
        let normalizedStrength = min(3, max(1, strength))
        if let index = member.observationEvidence.firstIndex(where: {
            $0.personalityFlag == personalityFlag && $0.stableTag == stableTag && $0.age == age
        }) {
            member.observationEvidence[index].strength = min(3, member.observationEvidence[index].strength + normalizedStrength)
            member.observationEvidence[index].reason = reason
        } else {
            member.observationEvidence.insert(
                NPCObservationEvidence(
                    personalityFlag: personalityFlag,
                    stableTag: stableTag,
                    strength: normalizedStrength,
                    age: age,
                    reason: reason
                ),
                at: 0
            )
        }
        revealSupportedObservations(member: &member)
    }

    static func recordInteraction(_ action: ActionID, age: Int, member: inout NPCState) {
        let metadata = DomainActionRegistry.action(for: action)
        let impulse = metadata.resolvedPersonalityImpulse
        let relevantAxes = PersonalityAxis.allCases.filter { impulse[$0] != 0 }
        let fallbackAxes: [PersonalityAxis]
        switch metadata.domain {
        case .love: fallbackAxes = [.sociability, .empathy]
        case .school, .cash: fallbackAxes = [.drive]
        case .play: fallbackAxes = [.sociability, .adaptability]
        case .health: fallbackAxes = [.adaptability]
        }
        let axes = relevantAxes.isEmpty ? fallbackAxes : relevantAxes
        guard let flag = member.personality.salientFlags.first(where: { axes.contains($0.axis) }) else { return }
        record(
            personalityFlag: flag,
            age: age,
            reason: "Their response to \(metadata.name.lowercased()) revealed a pattern.",
            member: &member
        )
    }

    private static func revealSupportedObservations(member: inout NPCState) {
        for flag in PersonalityFlag.allCases where !member.discoveredTraits.contains(flag) {
            let strength = member.observationEvidence
                .filter { $0.personalityFlag == flag }
                .reduce(0) { $0 + $1.strength }
            if strength >= 2 { member.discoveredTraits.append(flag) }
        }
        for tag in CharacterTag.allCases where !member.discoveredTags.contains(tag) {
            let strength = member.observationEvidence
                .filter { $0.stableTag == tag }
                .reduce(0) { $0 + $1.strength }
            if strength >= 3 { member.discoveredTags.append(tag) }
        }
        member.discoveredTraits = Array(Set(member.discoveredTraits)).sorted { $0.rawValue < $1.rawValue }
        member.discoveredTags = Array(Set(member.discoveredTags)).sorted { $0.rawValue < $1.rawValue }
        member.observationEvidence = Array(member.observationEvidence.prefix(12))
    }
}

enum DynamicCastSystem {
    static func applyReactionRapport(_ delta: Int, memberID: String, state: inout LifeState) {
        guard var member = state.npcs.member(id: memberID) else { return }
        member.rapport += delta
        member.clamp()
        state.npcs.update(member)
    }

    static func reactivate(role: NPCRole, state: inout LifeState) {
        guard var member = state.npcs[role] else { return }
        catchUpIndependentLife(member: &member, through: state.character.age, runSeed: state.runSeed)
        guard member.activity == .dormant else {
            state.npcs.update(member)
            return
        }
        member.activity = member.rapport <= -25 ? .hostile : (member.importance == .pivotal ? .pivotal : .active)
        state.npcs.update(member)
    }

    static func recordInteraction(
        _ action: ActionID,
        member: inout NPCState,
        age: Int
    ) {
        member.bond += member.rapport < -15 ? 1 : 3
        let note: String
        if member.rapport <= -25 {
            note = "Conflict around \(DomainActionRegistry.action(for: action).name.lowercased()) hardened the distance."
            member.activity = .hostile
        } else if member.rapport >= 20 {
            note = "Repeated contact made the relationship consequential."
            member.activity = .pivotal
            member.importance = .pivotal
        } else {
            note = "You made time around \(DomainActionRegistry.action(for: action).name.lowercased())."
            member.activity = .active
        }
        member.memories.insert(CastMemory(age: age, actionID: action, note: note), at: 0)
        member.memories = Array(member.memories.prefix(6))
        NPCObservationSystem.recordInteraction(action, age: age, member: &member)
    }

    static func recordSituationChoice(
        _ choice: EventChoice,
        member: inout NPCState,
        age: Int
    ) {
        member.bond += 4
        let note = choice.narrative
        if member.rapport <= -25 { member.activity = .hostile }
        else if member.rapport >= 20 {
            member.activity = .pivotal
            member.importance = .pivotal
        } else {
            member.activity = .active
        }
        // The action field keeps old saves and compact review tooling stable;
        // the prose carries the distinct caused-event memory.
        member.memories.insert(CastMemory(age: age, actionID: .repairConflict, note: note), at: 0)
        member.memories = Array(member.memories.prefix(6))
        NPCObservationSystem.recordInteraction(.repairConflict, age: age, member: &member)
    }

    /// Dormant members are retained exactly so a later caused event can bring
    /// them back. This yearly pass only changes cast activity; it does not
    /// generate a narrative or consume RNG.
    static func resolveYear(
        state: inout LifeState,
        signals: [LifeSignal]
    ) -> CastYearResolution {
        var result = CastYearResolution()
        for member in state.npcs.all {
            var updated = member
            updated.circumstances.removeAll { $0.expiresAge < state.character.age }

            if updated.importance != .background, updated.activity != .dormant {
                let previousNote = updated.independentLife.currentNote
                catchUpIndependentLife(member: &updated, through: state.character.age, runSeed: state.runSeed)
                if previousNote != updated.independentLife.currentNote,
                   updated.importance == .pivotal || updated.activity == .pivotal {
                    result.bullets.append("\(updated.name): \(updated.independentLife.currentNote)")
                }
            }

            if updated.activity != .dormant,
               updated.lastInteractionAge >= state.character.age - 4 {
                for signal in signals.prefix(2) {
                    if state.reactions.reactedThisAge.contains("npc:\(updated.memberID):\(state.character.age)") { continue }
                    if let reaction = react(member: &updated, to: signal) {
                        result.bullets.append(reaction)
                        break
                    }
                }
            }

            if updated.activity != .dormant || updated.lastInteractionAge >= state.character.age - 4 {
                _ = PersonalitySystem.resolveYear(profile: &updated.personality, age: state.character.age)
            }

            if updated.activity == .active,
               updated.importance != .pivotal,
               state.character.age - updated.lastInteractionAge >= 3 {
                updated.activity = .dormant
            }
            updated.clamp()
            state.npcs.update(updated)
        }
        result.bullets = Array(result.bullets.prefix(2))
        return result
    }

    static func resolveYear(
        state: inout LifeState,
        careerMilestone: String? = nil
    ) -> CastYearResolution {
        let signals = careerMilestone.map {
            [LifeSignal(kind: .careerPromotion, magnitude: .major, age: state.character.age, sourceHeadline: $0)]
        } ?? []
        return resolveYear(state: &state, signals: signals)
    }

    private static func react(member: inout NPCState, to signal: LifeSignal) -> String? {
        switch signal.kind {
        case .playerDecision:
            guard let intent = signal.intent else { return nil }
            let familySensitive = member.stableTags.contains(.familyOriented)
                || member.stableTags.contains(.protective)
                || member.personality.has(.empathetic)
            let ambitious = member.stableTags.contains(.competitive)
                || member.personality.has(.driven)
            switch intent {
            case .advance, .commit:
                if familySensitive, signal.exposure == .household || signal.commitment == .availability {
                    member.rapport -= member.personality.has(.empathetic) ? 1 : 3
                    addCircumstance(.stressed, intensity: 1, duration: 2, age: signal.age, member: &member)
                    return "\(member.name) noticed that your \(signal.sourceHeadline.lowercased()) left less room for people around you."
                }
                if ambitious {
                    member.independentLife.careerStanding += 2
                    addCircumstance(.confident, intensity: 1, duration: 1, age: signal.age, member: &member)
                    return "\(member.name) read your \(signal.intent?.title.lowercased() ?? "ambition") as a reason to raise their own pace."
                }
            case .protect, .repair:
                if familySensitive {
                    member.rapport += 2
                    member.bond += 1
                    return "\(member.name) felt the room you made for someone else."
                }
            case .disclose:
                if member.personality.has(.empathetic) || member.stableTags.contains(.loyal) {
                    member.rapport += 2
                    return "\(member.name) trusted you more after you stopped managing the story."
                }
            case .hide:
                if member.stableTags.contains(.privatePerson) || member.personality.has(.cautious) {
                    member.rapport -= 2
                    addCircumstance(.stressed, intensity: 1, duration: 2, age: signal.age, member: &member)
                    return "\(member.name) noticed what you chose not to explain."
                }
            case .withdraw:
                if member.stableTags.contains(.loyal) || member.personality.has(.empathetic) {
                    member.rapport -= 1
                    return "\(member.name) gave you space, but did not mistake it for resolution."
                }
            case .exploit, .postpone, .challenge:
                break
            }
            return nil

        case .careerPromotion, .publicSuccess, .graduation:
            if (member.stableTags.contains(.competitive) || member.personality.has(.driven)),
               member.independentLife.careerStanding < 58 {
                member.rapport -= member.personality.has(.empathetic) ? 2 : 5
                addCircumstance(.jealous, intensity: 2, duration: 2, age: signal.age, member: &member)
                if member.stableTags.contains(.competitive) {
                    NPCObservationSystem.record(stableTag: .competitive, strength: 3, age: signal.age, reason: "Your success made comparison visible.", member: &member)
                } else {
                    NPCObservationSystem.record(personalityFlag: .driven, strength: 2, age: signal.age, reason: "Your success made their own ambition visible.", member: &member)
                }
                return "\(member.name) congratulated you, but comparison entered the relationship."
            }
            if member.stableTags.contains(.loyal) || member.personality.has(.empathetic) || member.personality.has(.content) {
                member.rapport += 3
                member.bond += 1
                if member.stableTags.contains(.loyal) {
                    NPCObservationSystem.record(stableTag: .loyal, strength: 2, age: signal.age, reason: "They made room for your success without competing with it.", member: &member)
                } else {
                    NPCObservationSystem.record(personalityFlag: member.personality.has(.empathetic) ? .empathetic : .content, strength: 2, age: signal.age, reason: "They celebrated without making the moment about them.", member: &member)
                }
                return "\(member.name) celebrated the change without making it about them."
            }
            addCircumstance(.confident, intensity: 1, duration: 2, age: signal.age, member: &member)
            member.independentLife.careerStanding += 4
            return "Your progress pushed \(member.name) to pursue their own next step."

        case .careerLoss, .financialCrisis, .healthCrisis, .foreclosure:
            if member.stableTags.contains(.loyal) || member.stableTags.contains(.protective)
                || member.stableTags.contains(.generous) || member.personality.has(.empathetic) {
                member.rapport += 3
                member.bond += 2
                let revealedTag = [CharacterTag.loyal, .protective, .generous].first(where: member.stableTags.contains)
                NPCObservationSystem.record(personalityFlag: revealedTag == nil ? .empathetic : nil, stableTag: revealedTag, strength: 3, age: signal.age, reason: "They stayed close when your life became difficult.", member: &member)
                return "\(member.name) stayed close when the situation became difficult."
            }
            if member.stableTags.contains(.materialistic) || member.stableTags.contains(.opportunistic) {
                member.rapport -= 4
                let tag: CharacterTag = member.stableTags.contains(.materialistic) ? .materialistic : .opportunistic
                NPCObservationSystem.record(stableTag: tag, strength: 3, age: signal.age, reason: "Their distance appeared when your position weakened.", member: &member)
                return "\(member.name) became harder to reach when your footing weakened."
            }
            return nil

        case .newPartnership, .newChild:
            guard member.stableTags.contains(.familyOriented) || member.stableTags.contains(.loyal) else { return nil }
            member.rapport += 2
            member.bond += 1
            let tag: CharacterTag = member.stableTags.contains(.familyOriented) ? .familyOriented : .loyal
            NPCObservationSystem.record(stableTag: tag, strength: 3, age: signal.age, reason: "They treated your changing household as something worth showing up for.", member: &member)
            return "\(member.name) made room for the change in your household."

        case .separation:
            if member.stableTags.contains(.vindictive) {
                member.rapport -= 3
                NPCObservationSystem.record(stableTag: .vindictive, strength: 3, age: signal.age, reason: "They used the rupture to reopen an old grievance.", member: &member)
                return "\(member.name) used the rupture to reopen an old grievance."
            }
            if member.stableTags.contains(.forgiving) || member.personality.has(.empathetic) {
                member.rapport += 2
                let tag = member.stableTags.contains(.forgiving) ? CharacterTag.forgiving : nil
                NPCObservationSystem.record(personalityFlag: tag == nil ? .empathetic : nil, stableTag: tag, strength: 3, age: signal.age, reason: "They listened without turning the breakup into a verdict.", member: &member)
                return "\(member.name) listened without turning the breakup into a verdict."
            }
            return nil

        case .recovery:
            guard member.stableTags.contains(.loyal) || member.personality.has(.empathetic) else { return nil }
            member.rapport += 1
            return "\(member.name) noticed that you had found your footing again."
        }
    }

    private static func catchUpIndependentLife(member: inout NPCState, through age: Int, runSeed: UInt64) {
        guard age > member.independentLife.lastResolvedAge else { return }
        let start = max(member.independentLife.lastResolvedAge + 1, age - 8)
        if start <= age {
            for resolvedAge in start...age where resolvedAge % 2 == 0 {
                resolveIndependentBeat(member: &member, age: resolvedAge, runSeed: runSeed)
            }
        }
        member.independentLife.lastResolvedAge = age
    }

    private static func resolveIndependentBeat(member: inout NPCState, age: Int, runSeed: UInt64) {
        var random = SeededRandom(seed: stableSeed(runSeed: runSeed, memberID: member.memberID, age: age))
        if let completedGoal = NPCGoalSystem.advance(member: &member, age: age, random: &random) {
            member.independentLife.currentNote = completedGoalNote(completedGoal)
            switch completedGoal {
            case .careerProgress, .status, .creativeAchievement:
                member.independentLife.careerStanding += 10
                member.independentLife.chapter = .established
            case .family, .belonging:
                member.independentLife.isPartnered = true
                member.independentLife.chapter = .partnered
            case .adventure:
                member.independentLife.movedAway = true
                member.independentLife.chapter = .relocated
            case .financialSecurity, .stability:
                member.independentLife.chapter = .established
            }
            addCircumstance(.thriving, intensity: 1, duration: 3, age: age, member: &member)
            member.independentLife.clamp()
            return
        }
        let drive = member.personality.current.drive
        let empathy = member.personality.current.empathy
        switch random.next(in: 0...9) {
        case 0 where drive >= 55, 1 where drive >= 55:
            member.independentLife.careerStanding += 7
            member.independentLife.chapter = member.independentLife.careerStanding >= 70 ? .established : .buildingCareer
            member.independentLife.currentNote = "Their work has started opening better doors."
            addCircumstance(.confident, intensity: 1, duration: 2, age: age, member: &member)
        case 2:
            member.independentLife.careerStanding -= 8
            member.independentLife.chapter = .setback
            member.independentLife.currentNote = "A setback has made their own future feel less certain."
            addCircumstance(.stressed, intensity: 2, duration: 2, age: age, member: &member)
        case 3 where !member.independentLife.isPartnered:
            member.independentLife.isPartnered = true
            member.independentLife.chapter = .partnered
            member.independentLife.currentNote = "They have begun building a serious relationship."
        case 4 where member.independentLife.isPartnered && member.independentLife.children < 2 && empathy >= 45:
            member.independentLife.children += 1
            member.independentLife.chapter = .raisingFamily
            member.independentLife.currentNote = "Their household has grown, changing what they can give."
        case 5 where !member.independentLife.movedAway:
            member.independentLife.movedAway = true
            member.independentLife.chapter = .relocated
            member.independentLife.currentNote = "They moved away and are rebuilding their routines elsewhere."
        case 6 where member.independentLife.careerStanding >= 60:
            member.independentLife.chapter = .established
            member.independentLife.currentNote = "They are doing well on terms that do not depend on you."
            addCircumstance(.thriving, intensity: 1, duration: 3, age: age, member: &member)
        default:
            break
        }
        member.independentLife.clamp()
    }

    private static func completedGoalNote(_ goal: NPCGoalKind) -> String {
        switch goal {
        case .careerProgress: "Their sustained work finally changed their professional standing."
        case .financialSecurity: "They built the financial margin they had been quietly pursuing."
        case .family: "They reached a family milestone that reorganized their priorities."
        case .status: "They gained the recognition they had been chasing."
        case .creativeAchievement: "A private creative ambition became something real."
        case .stability: "Their life settled into the stability they wanted."
        case .adventure: "They chose a larger change instead of preserving the familiar."
        case .belonging: "They found a community that now claims more of their time."
        }
    }

    private static func addCircumstance(
        _ kind: NPCCircumstanceKind,
        intensity: Int,
        duration: Int,
        age: Int,
        member: inout NPCState
    ) {
        member.circumstances.removeAll { $0.kind == kind }
        member.circumstances.insert(
            NPCCircumstance(kind: kind, intensity: intensity, startedAge: age, expiresAge: age + duration),
            at: 0
        )
    }

    private static func stableSeed(runSeed: UInt64, memberID: String, age: Int) -> UInt64 {
        var hash = runSeed ^ 14_695_981_039_346_656_037
        for byte in memberID.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        hash ^= UInt64(max(0, age)) &* 9_704_172_739
        return hash == 0 ? 1 : hash
    }
}

// MARK: - Phase 6: family domain hooks

/// Family opinion normally evolves passively. These rare moments turn a real
/// pressure point into a choice without requiring a separate relationship
/// management loop. Family owns its bond and stance; this selector only
/// controls when a contact becomes relevant enough to speak.
enum FamilySituationSystem {
    private enum Kind { case healthReachOut, legalBoundary }

    private struct Candidate {
        let contact: FamilyContact
        let kind: Kind
        let score: Int
    }

    static func select(state: LifeState) -> LifeEvent? {
        let age = state.character.age
        guard age >= 18 else { return nil }
        let candidates = state.family.contacts.compactMap { contact -> Candidate? in
            guard age - contact.lastSituationAge >= 4 else { return nil }
            if state.health.overall <= 38, contact.bond >= 52, contact.stance != .estranged {
                return Candidate(contact: contact, kind: .healthReachOut, score: 50 + contact.bond)
            }
            if state.legal.isFelon, contact.bond >= 38, contact.stance != .estranged {
                return Candidate(contact: contact, kind: .legalBoundary, score: 43 + contact.bond)
            }
            return nil
        }
        guard let candidate = candidates.sorted(by: { lhs, rhs in
            lhs.score == rhs.score ? lhs.contact.id < rhs.contact.id : lhs.score > rhs.score
        }).first else { return nil }
        return event(for: candidate, age: age)
    }

    private static func event(for candidate: Candidate, age: Int) -> LifeEvent {
        let contact = candidate.contact
        switch candidate.kind {
        case .healthReachOut:
            return LifeEvent(
                id: "family-health-\(contact.id)-\(age)",
                headline: "\(contact.name) Notices You Are Struggling",
                detail: "They cannot fix your health, but they are offering time and a concrete check-in.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(id: .accept, title: "Let them show up", detail: "Accept support without pretending the problem is solved.", effects: EffectRange(love: 2 ... 3, health: 1 ... 2), partnerEffect: PartnerEffect(), narrative: "Their presence made the hard stretch less isolated.", familyContactID: contact.id, familyBondDelta: 7),
                    EventChoice(id: .decline, title: "Keep it private", detail: "Protect your space for now.", effects: EffectRange(play: 1 ... 2), partnerEffect: PartnerEffect(), narrative: "They respected the boundary, though they worried from a distance.", familyContactID: contact.id, familyBondDelta: -2)
                ]
            )
        case .legalBoundary:
            return LifeEvent(
                id: "family-legal-\(contact.id)-\(age)",
                headline: "\(contact.name) Draws A Line",
                detail: "Your record has reached the family. They want accountability, not another promise that nothing is wrong.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(id: .talk, title: "Own the damage", detail: "Tell the truth without asking them to clean it up.", effects: EffectRange(love: -1 ... 1, rep: -1 ... 0), partnerEffect: PartnerEffect(), narrative: "The conversation was uncomfortable, but you stopped making them guess.", familyContactID: contact.id, familyBondDelta: 4),
                    EventChoice(id: .decline, title: "Shut it down", detail: "Refuse to explain yourself.", effects: EffectRange(play: 1 ... 2, rep: -2 ... -1), partnerEffect: PartnerEffect(), narrative: "You ended the conversation. The boundary became distance.", familyContactID: contact.id, familyBondDelta: -8)
                ]
            )
        }
    }
}

// MARK: - Phase 3 and 6: caused cast situations

/// Chooses at most one cast event only when a specific person, a remembered
/// relationship, and current life pressure make it plausible. The selector
/// controls pacing; applied effects remain in the ordinary event and domain
/// pipelines. There is intentionally no extra RNG lane here.
enum CastSituationSystem {
    private enum Kind: String {
        case hostileExposure
        case dormantSupport
        case jealousFallout
        case networkOpportunity
        case workplacePressure
        case specialCareerSponsor
        case diamondCareerPressure
        case legalAccountability
        case healthCheckIn
        case sharedIntroduction
    }

    private struct Candidate {
        let member: NPCState
        let kind: Kind
        let score: Int
        var counterpart: NPCState? = nil
    }

    static func select(state: inout LifeState) -> LifeEvent? {
        let age = state.character.age
        let candidates = state.npcs.all.compactMap { member -> Candidate? in
            guard age - member.lastSituationAge >= 4 else { return nil }
            if member.circumstances.contains(where: { $0.kind == .jealous }), member.bond >= 20 {
                return Candidate(member: member, kind: .jealousFallout, score: 55 + member.bond - max(0, member.rapport))
            }
            if member.activity == .hostile || member.rapport <= -25 {
                let pressure = (state.career.level.isEmployed ? 4 : 0)
                    + (state.stats.rep >= 55 ? 3 : 0)
                    + (state.legal.isFelon ? 2 : 0)
                guard pressure > 0 else { return nil }
                return Candidate(member: member, kind: .hostileExposure, score: 30 + pressure + abs(member.rapport))
            }
            if member.activity == .dormant,
               member.rapport >= 18,
               state.finance.financialStress >= 45 {
                return Candidate(member: member, kind: .dormantSupport, score: 20 + member.rapport + state.finance.financialStress / 5)
            }
            if member.activity == .dormant,
               member.rapport >= 10,
               member.independentLife.careerStanding >= 70,
               state.career.level != .senior {
                return Candidate(member: member, kind: .networkOpportunity, score: 18 + member.rapport + member.independentLife.careerStanding / 4)
            }
            if member.role == .boss,
               member.activity != .dormant,
               state.career.careerClass == .normal || state.career.careerClass == .partTime,
               state.career.level.isEmployed,
               state.career.security <= 42 || state.career.burnout >= 68 {
                return Candidate(member: member, kind: .workplacePressure, score: 38 + (100 - state.career.security) / 3 + state.career.burnout / 4)
            }
            if member.role == .boss,
               member.rapport >= 8,
               state.career.careerClass == .special,
               state.career.specialMomentum <= 45,
               state.career.level.isEmployed {
                return Candidate(member: member, kind: .specialCareerSponsor, score: 44 + member.rapport + (50 - state.career.specialMomentum))
            }
            if member.role == .boss,
               state.career.careerClass == .diamond,
               state.career.legacyLeverage <= 42 {
                return Candidate(member: member, kind: .diamondCareerPressure, score: 48 + (50 - state.career.legacyLeverage) + max(0, -member.rapport))
            }
            if member.role == .friend,
               member.rapport >= 7,
               member.activity != .dormant,
               state.legal.isFelon {
                return Candidate(member: member, kind: .legalAccountability, score: 46 + member.bond)
            }
            if member.role == .friend,
               member.rapport >= 8,
               member.activity != .dormant,
               state.health.overall <= 38 {
                return Candidate(member: member, kind: .healthCheckIn, score: 48 + member.bond)
            }
            if member.role == .friend,
               member.rapport >= 18,
               state.career.level.isEmployed,
               let boss = state.npcs.members(for: .boss).first,
               boss.rapport >= -4,
               boss.activity != .dormant {
                return Candidate(
                    member: member,
                    kind: .sharedIntroduction,
                    score: 35 + member.rapport + max(0, boss.rapport),
                    counterpart: boss
                )
            }
            return nil
        }
        guard let candidate = candidates.sorted(by: ordered).first else { return nil }
        var selected = candidate.member
        selected.lastSituationAge = age
        if selected.activity == .dormant { selected.activity = .active }
        state.npcs.update(selected)
        return event(for: candidate, age: age)
    }

    private nonisolated static func ordered(_ lhs: Candidate, _ rhs: Candidate) -> Bool {
        if lhs.score == rhs.score {
            if lhs.member.memberID == rhs.member.memberID { return lhs.kind.rawValue < rhs.kind.rawValue }
            return lhs.member.memberID < rhs.member.memberID
        }
        return lhs.score > rhs.score
    }

    private static func event(for candidate: Candidate, age: Int) -> LifeEvent {
        let member = candidate.member
        switch candidate.kind {
        case .hostileExposure:
            let detail = "\(member.name) has not forgotten the history between you. A chance to make your life harder just opened."
            return LifeEvent(
                id: "cast-hostile-\(member.memberID)-\(age)",
                headline: "\(member.name) Reopens An Old Grudge",
                detail: detail,
                weight: { _ in 0 },
                choices: [
                    EventChoice(
                        id: .talk,
                        title: "Address it directly",
                        detail: "Take the conversation before it spreads.",
                        effects: EffectRange(health: -2 ... -1, rep: -2 ... 1),
                        partnerEffect: PartnerEffect(),
                        narrative: "You met the conflict in the open. The damage stayed limited, but the relationship did not heal.",
                        castMemberID: member.memberID,
                        castRapportDelta: -1
                    ),
                    EventChoice(
                        id: .decline,
                        title: "Keep your distance",
                        detail: "Refuse to give the conflict more oxygen.",
                        effects: EffectRange(play: 1 ... 2, rep: -4 ... -2),
                        partnerEffect: PartnerEffect(),
                        narrative: "You protected your peace for now. \(member.name) took the silence as an answer.",
                        castMemberID: member.memberID,
                        castRapportDelta: -4
                    )
                ]
            )
        case .dormantSupport:
            let detail = "\(member.name) heard that the margins have narrowed. The relationship has been quiet, but not erased."
            return LifeEvent(
                id: "cast-return-\(member.memberID)-\(age)",
                headline: "\(member.name) Calls At A Tight Moment",
                detail: detail,
                weight: { _ in 0 },
                choices: [
                    EventChoice(
                        id: .accept,
                        title: "Take the introduction",
                        detail: "Let an old connection create a modest opening.",
                        effects: EffectRange(cash: 750 ... 1_500, rep: 1 ... 2),
                        partnerEffect: PartnerEffect(),
                        narrative: "The help was real but limited: a short bridge, not a rescued life.",
                        castMemberID: member.memberID,
                        castRapportDelta: 3
                    ),
                    EventChoice(
                        id: .decline,
                        title: "Handle it alone",
                        detail: "Keep the relationship warm without taking the help.",
                        effects: EffectRange(play: 1 ... 2),
                        partnerEffect: PartnerEffect(),
                        narrative: "You kept your independence. \(member.name) understood, but the distance remained.",
                        castMemberID: member.memberID,
                        castRapportDelta: -1
                    )
                ]
            )
        case .jealousFallout:
            return LifeEvent(
                id: "cast-jealous-\(member.memberID)-\(age)",
                headline: "Success Changed An Old Friendship",
                detail: "\(member.name) has been measuring their life against yours. The bond is real, but the current relationship has become harder to trust.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(
                        id: .talk,
                        title: "Name the tension",
                        detail: "Risk an honest conversation without shrinking your success.",
                        effects: EffectRange(love: 1 ... 2, health: -1 ... 0),
                        partnerEffect: PartnerEffect(),
                        narrative: "You named the comparison without humiliating them. The friendship became more honest, if not immediately easy.",
                        castMemberID: member.memberID,
                        castRapportDelta: 6
                    ),
                    EventChoice(
                        id: .decline,
                        title: "Let distance grow",
                        detail: "Protect the achievement and stop managing their reaction.",
                        effects: EffectRange(love: -2 ... -1, rep: 1 ... 2),
                        partnerEffect: PartnerEffect(),
                        narrative: "You stopped chasing their approval. Years of history remained, but warmth did not.",
                        castMemberID: member.memberID,
                        castRapportDelta: -8
                    )
                ]
            )
        case .networkOpportunity:
            return LifeEvent(
                id: "cast-network-\(member.memberID)-\(age)",
                headline: "An Old Contact Opens A Door",
                detail: "\(member.name)'s own career has advanced. They remembered enough of your history to put your name into a useful room.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(
                        id: .accept,
                        title: "Take the meeting",
                        detail: "Use the connection, then earn whatever follows.",
                        effects: EffectRange(cash: 500 ... 1_000, rep: 2 ... 4),
                        partnerEffect: PartnerEffect(),
                        narrative: "The introduction created access, not a guarantee. Your old connection mattered anyway.",
                        castMemberID: member.memberID,
                        castRapportDelta: 3
                    ),
                    EventChoice(
                        id: .decline,
                        title: "Stay on your path",
                        detail: "Keep the relationship separate from your work.",
                        effects: EffectRange(play: 1 ... 2),
                        partnerEffect: PartnerEffect(),
                        narrative: "You declined without closing the relationship. The door moved on to someone else.",
                        castMemberID: member.memberID,
                        castRapportDelta: 0
                    )
                ]
            )
        case .workplacePressure:
            return LifeEvent(
                id: "cast-workplace-\(member.memberID)-\(age)",
                headline: "\(member.name) Wants A Clear Answer",
                detail: "The pressure at work has become visible. This is a conversation about expectations, not a random punishment.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(id: .talk, title: "Set a workable boundary", detail: "Protect some recovery while staying accountable.", effects: EffectRange(health: 1 ... 2, rep: -1 ... 1), partnerEffect: PartnerEffect(), narrative: "You made the work sustainable enough to continue. The relationship became more direct.", castMemberID: member.memberID, castRapportDelta: 3),
                    EventChoice(id: .focus, title: "Promise more output", detail: "Buy short-term security with more of yourself.", effects: EffectRange(health: -3 ... -2, rep: 1 ... 2), partnerEffect: PartnerEffect(), narrative: "The immediate pressure eased, but the extra demand followed you home.", castMemberID: member.memberID, castRapportDelta: 1)
                ]
            )
        case .specialCareerSponsor:
            return LifeEvent(
                id: "cast-special-\(member.memberID)-\(age)",
                headline: "\(member.name) Offers A Public Bet",
                detail: "Your momentum has slipped. They can put their credibility behind one more visible opportunity, but they cannot make it land for you.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(id: .accept, title: "Take the opening", detail: "Use the platform and carry the pressure yourself.", effects: EffectRange(health: -2 ... -1, rep: 2 ... 4), partnerEffect: PartnerEffect(), narrative: "You got another real chance to be seen. What happens next is still on your work.", castMemberID: member.memberID, castRapportDelta: 4),
                    EventChoice(id: .decline, title: "Build quietly", detail: "Refuse the rescue and regain footing out of view.", effects: EffectRange(play: 1 ... 2, rep: 0 ... 1), partnerEffect: PartnerEffect(), narrative: "You kept the relationship intact without making them spend their credibility.", castMemberID: member.memberID, castRapportDelta: 1)
                ]
            )
        case .diamondCareerPressure:
            return LifeEvent(
                id: "cast-diamond-\(member.memberID)-\(age)",
                headline: "\(member.name) Questions The Institution",
                detail: "The venture is underperforming, and someone close enough to see it is asking for a concrete correction.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(id: .talk, title: "Open the books", detail: "Take scrutiny now instead of defending a story.", effects: EffectRange(health: -1 ... 0, rep: -1 ... 1), partnerEffect: PartnerEffect(), narrative: "The review was uncomfortable, but the problem became clearer and less isolating.", castMemberID: member.memberID, castRapportDelta: 4),
                    EventChoice(id: .decline, title: "Close ranks", detail: "Keep control of the decision and the consequences.", effects: EffectRange(play: 1 ... 2, rep: -3 ... -1), partnerEffect: PartnerEffect(), narrative: "You kept the decision private. The doubts did not disappear with the conversation.", castMemberID: member.memberID, castRapportDelta: -5)
                ]
            )
        case .legalAccountability:
            return LifeEvent(
                id: "cast-legal-\(member.memberID)-\(age)",
                headline: "\(member.name) Refuses To Cover For You",
                detail: "They care about you, but your legal situation has made one thing clear: they will not become part of the damage.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(id: .talk, title: "Respect the boundary", detail: "Keep the friendship separate from the legal fallout.", effects: EffectRange(love: 1 ... 2, rep: -1 ... 0), partnerEffect: PartnerEffect(), narrative: "You accepted the limit. Trust did not reset, but it had room to survive.", castMemberID: member.memberID, castRapportDelta: 3),
                    EventChoice(id: .decline, title: "Ask anyway", detail: "Make the friendship carry a cost it did not choose.", effects: EffectRange(love: -2 ... -1, rep: -3 ... -2), partnerEffect: PartnerEffect(), narrative: "They said no again. This time the relationship changed with it.", castMemberID: member.memberID, castRapportDelta: -9)
                ]
            )
        case .healthCheckIn:
            return LifeEvent(
                id: "cast-health-\(member.memberID)-\(age)",
                headline: "\(member.name) Checks In For Real",
                detail: "Your health has become hard to ignore. They are offering company and a practical check-in, not a cure.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(id: .accept, title: "Let them help", detail: "Accept support while you keep responsibility for your care.", effects: EffectRange(love: 2 ... 3, health: 1 ... 2), partnerEffect: PartnerEffect(), narrative: "The day did not solve everything, but you did not carry it alone.", castMemberID: member.memberID, castRapportDelta: 5),
                    EventChoice(id: .decline, title: "Keep it contained", detail: "Protect your privacy for now.", effects: EffectRange(play: 1 ... 2), partnerEffect: PartnerEffect(), narrative: "They gave you space. The concern remained.", castMemberID: member.memberID, castRapportDelta: -1)
                ]
            )
        case .sharedIntroduction:
            guard let boss = candidate.counterpart else {
                return LifeEvent(id: "cast-introduction-missing-\(member.memberID)-\(age)", headline: "A Connection Went Quiet", detail: "The timing for an introduction passed.", weight: { _ in 0 }, choices: [])
            }
            return LifeEvent(
                id: "cast-introduction-\(member.memberID)-\(boss.memberID)-\(age)",
                headline: "\(member.name) Puts Their Name On Yours",
                detail: "They are willing to vouch for you directly to \(boss.name). Taking it affects both relationships, not just your résumé.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(id: .accept, title: "Take the introduction", detail: "Let your friend risk social capital, then earn the trust yourself.", effects: EffectRange(rep: 1 ... 3), partnerEffect: PartnerEffect(), narrative: "The introduction created a real opening. Both people will remember what you did with it.", castMemberID: member.memberID, castRapportDelta: 3, secondaryCastMemberID: boss.memberID, secondaryCastRapportDelta: 5),
                    EventChoice(id: .decline, title: "Keep work separate", detail: "Do not make either relationship carry that obligation.", effects: EffectRange(play: 1 ... 2), partnerEffect: PartnerEffect(), narrative: "You passed without damaging the connection. The opportunity simply moved on.", castMemberID: member.memberID, castRapportDelta: 0, secondaryCastMemberID: boss.memberID, secondaryCastRapportDelta: 0)
                ]
            )
        }
    }
}

struct SimulationResolution: Equatable {
    var outcome: ActionOutcome?
    var pendingEvent: PresentedEvent?
    var yearSummary: YearSummary?
    var historyEntry: HistoryEntry?
    var terminalReason: EndReason?
}

struct InstantDomainResolution: Equatable {
    var resolution = DomainActionResolution()
    var pendingEvent: PresentedEvent?
}

struct InstantActionResolution: Equatable {
    let headline: String
    let detail: String
    let deltas: DeltaSummary
    let reactionNote: String?
    let personalityContext: String?
    let recoveryNote: String?
    let pendingEvent: PresentedEvent?
    let impacts: [ActionImpact]
}

enum InstantActionCoordinator {
    static func resolve(action: DomainAction, target: PersonReference? = nil, state: inout LifeState) -> InstantActionResolution {
        let before = state
        let activeSystems = SystemRegistry.activeInstantSystems(for: action, in: state)
        var social = SocialReactivitySystem()
        let socialResolution = activeSystems.contains(.social) || activeSystems.contains(.personality)
            ? social.resolve(action: action, target: target, state: &state)
            : SocialActionResolution.hibernated(for: action)

        let adjustedEffects = ActionCadenceSystem.adjusted(
            effects(for: action, state: state), for: action.id, state: &state
        )
        _ = EffectResolutionSystem.apply(
            adjustedEffects,
            state: &state,
            financialPurpose: action.domain == .school ? .education : (action.domain == .health ? .medical : .optionalPurchase)
        )
        if activeSystems.contains(.social) {
            social.createPartnerIfEligible(for: action, state: &state)
            _ = social.apply(socialResolution, state: &state)
            _ = social.applySchoolLegacy(for: action, state: &state)
        }
        var npcEffect = socialResolution.npcEffect
        applyNPCFinance(&npcEffect, action: action, state: &state)
        _ = EffectResolutionSystem.apply(npcEffect, state: &state)
        if activeSystems.contains(.influence) { InfluenceSystem.record(action: action, state: &state) }
        PersonalitySystem.record(PersonalitySystem.developmentImpulse(action.resolvedPersonalityImpulse, for: state.personality), profile: &state.personality)
        if TalentSystem.context(for: action, state: state) != nil { state.aggregates.talentUses += 1 }
        for rule in socialResolution.reactionRules {
            PersonalitySystem.record(rule.personalityImpulse, profile: &state.personality)
        }
        state.markActionUsed(action.id)
        SituationActionCoordinator.record(action: action.id, state: &state)
        state.rememberDecisionSignal(PlayerDecisionSignalSystem.signal(for: action, state: state))
        if activeSystems.contains(.progression) { ProgressionSystem.resolve(action: action, state: &state) }

        let domain = resolveDomain(action: action, state: &state)
        let reactionPass = ReactionResolver.run(.action(action.id, target: target), state: &state)
        let deltas = DeltaSummary(
            school: state.stats.school - before.stats.school,
            cash: state.cash - before.cash,
            love: state.stats.love - before.stats.love,
            play: state.stats.play - before.stats.play,
            health: state.stats.health - before.stats.health,
            looks: state.stats.looks - before.stats.looks,
            rep: state.stats.rep - before.stats.rep,
            bond: (state.partner?.bond ?? 0) - (before.partner?.bond ?? 0),
            resentment: (state.partner?.resentment ?? 0) - (before.partner?.resentment ?? 0)
        )
        let narrative = InstantNarrativeSystem.resolve(action: action, social: socialResolution, deltas: deltas, state: state)
        let combinedReactionNote = ([narrative.reaction] + reactionPass.visibleLines).compactMap { $0 }.joined(separator: " ")
        let recovery = activeSystems.contains(.recovery) ? HealthSystem.resolveRecoveryIfPossible(state: &state) : nil
        state.flags.seenInstantHint = true
        let personality = [narrative.personalityContext, TalentSystem.context(for: action, state: state)]
            .compactMap { $0 }
            .joined(separator: " · ")
        return InstantActionResolution(
            headline: domain.resolution.headline ?? socialResolution.headline,
            detail: ([domain.resolution.detail ?? narrative.detail] + reactionPass.visibleLines).joined(separator: " "),
            deltas: deltas,
            reactionNote: combinedReactionNote.isEmpty ? nil : combinedReactionNote,
            personalityContext: personality.isEmpty ? nil : personality,
            recoveryNote: recovery,
            pendingEvent: domain.pendingEvent,
            impacts: reactionPass.impact.map { [$0] } ?? []
        )
    }

    static func effects(for action: DomainAction, state: LifeState) -> EffectRange {
        var effects = TalentSystem.modifiedEffects(for: action, state: state)
        if action.domainEffects?.finance == .creditExtraWork || action.domainEffects?.finance == .creditSideHustle {
            effects.cash = 0...0
        }
        return effects
    }

    private static func resolveDomain(action: DomainAction, state: inout LifeState) -> InstantDomainResolution {
        var result = InstantDomainResolution()
        guard let effects = action.domainEffects else { return result }
        if let effect = effects.education {
            result.resolution = EducationSystem.resolve(effect, state: &state)
        }
        if let effect = effects.career {
            result.resolution = CareerSystem.resolve(effect, state: &state, world: WorldSystem.modifiers(for: state.world))
        }
        if let effect = effects.finance {
            result.resolution = HouseholdFinanceSystem.resolve(effect, state: &state)
        }
        if let effect = effects.family {
            result.resolution = FamilySystem.resolve(effect, state: &state)
        }
        if let effect = effects.health {
            result.resolution = ConditionHealthSystem.resolve(effect, state: &state, world: WorldSystem.modifiers(for: state.world))
        }
        result.pendingEvent = followUp(for: effects, state: state)
        return result
    }

    static func applyNPCFinance(_ effect: inout EffectRange, action: DomainAction, state: inout LifeState) {
        guard action.domainEffects?.finance == .creditExtraWork
                || action.domainEffects?.finance == .creditSideHustle
                || action.id == .helpAtHome,
              effect.cash != 0...0 else { return }
        let gross = state.randomStreams.finance.next(in: effect.cash)
        if gross >= 0 { FinanceSystem.creditExtra(gross, state: &state) }
        else { _ = FinanceSystem.transact(.init(amount: gross, purpose: .household), state: &state) }
        effect.cash = 0...0
    }

    private static func followUp(for effects: DomainActionEffects, state: LifeState) -> PresentedEvent? {
        if effects.finance == .openWorkout {
            return PresentedEvent(FinanceSystem.workoutEvent(state))
        }
        if effects.education == .openCollegeOffers {
            let offers = EducationSystem.collegeOffers(for: state)
            guard !offers.isEmpty else { return nil }
            return PresentedEvent(EducationSystem.offerEvent(
                id: "college-application-\(state.character.age)",
                headline: "Your College Answers Arrive",
                detail: "The diploma still opens a route. The cost and pace depend on which answer you accept.",
                offers: offers
            ))
        }
        if effects.education == .openRecoveryOffers {
            let offers = EducationSystem.recoveryOffers(for: state)
            guard !offers.isEmpty else { return nil }
            return PresentedEvent(EducationSystem.offerEvent(
                id: "education-recovery-\(state.character.age)",
                headline: "Your Education Record Opens Again",
                detail: "Choose one recoverable route. Credits and debt already earned remain exactly where they were.",
                offers: offers
            ))
        }
        return nil
    }
}

enum EventChoiceCoordinator {
    struct Resolution: Equatable {
        let headline: String
        let detail: String
        let deltas: DeltaSummary
        let isYearly: Bool
        let yearSummary: YearSummary?
        let pendingEvent: PresentedEvent?
        let reactionNote: String?
        let impacts: [ActionImpact]
    }

    static func resolve(choice: EventChoice, event: PresentedEvent, state: inout LifeState) -> Resolution {
        if BundledLifeContentRegistry.eventIDs.contains(event.id) {
            state.aggregates.personalityPivotalEvents += 1
            state.aggregates.lastPersonalityPivotalAge = state.character.age
        }
        let financeDelta = applyFinance(choice: choice, state: &state)
        var core = EffectResolutionSystem.apply(choice.effects, state: &state, financialPurpose: financialPurpose(choice: choice, eventID: event.id))
        if let financeDelta { core.cash = financeDelta }
        if let propertyEffect = choice.propertyEffect {
            AssetSystem.applyPropertyEventEffect(propertyEffect, assets: &state.assets, age: state.character.age)
        }
        if let vehicleEffect = choice.vehicleEffect {
            AssetSystem.applyVehicleEventEffect(vehicleEffect, assets: &state.assets, age: state.character.age)
        }
        if let assetLossEffect = choice.assetLossEffect {
            AssetSystem.applyAssetLossEffect(assetLossEffect, assets: &state.assets, age: state.character.age)
        }
        EducationSystem.apply(choice.educationEffect, state: &state)
        EducationSystem.recordSchoolChoice(event: event, choice: choice, state: &state)
        var transition = EducationTransitionOutcome()
        var transitionDeltas = DeltaSummary()
        if let effect = choice.educationTransitionEffect {
            transition = EducationSystem.resolve(effect, state: &state)
            CareerSystem.applySchoolTransition(transition.career, state: &state)
            transitionDeltas = FinanceSystem.applySchoolTransition(transition.finance, state: &state)
        }
        var social = SocialReactivitySystem()
        let partnerDeltas = social.applyPartnerEffect(choice.partnerEffect, state: &state)
        if let impulse = choice.personalityImpulse { PersonalitySystem.record(impulse, profile: &state.personality) }
        if let role = choice.relationshipRole?.npcRole,
           let rapportDelta = choice.npcRapportDelta,
           var npc = state.npcs[role] {
            npc.rapport += rapportDelta
            npc.lastInteractionAge = state.character.age
            npc.learnedStance = npc.rapport >= 6 ? .warm : (npc.rapport <= -6 ? .wary : npc.learnedStance)
            npc.clamp()
            state.npcs[role] = npc
        }
        if let memberID = choice.castMemberID,
           var member = state.npcs.member(id: memberID) {
            member.rapport += choice.castRapportDelta ?? 0
            member.lastInteractionAge = state.character.age
            member.lastSituationAge = state.character.age
            DynamicCastSystem.recordSituationChoice(choice, member: &member, age: state.character.age)
            member.clamp()
            state.npcs.update(member)
        }
        if let memberID = choice.secondaryCastMemberID,
           var member = state.npcs.member(id: memberID) {
            member.rapport += choice.secondaryCastRapportDelta ?? 0
            member.lastInteractionAge = state.character.age
            DynamicCastSystem.recordSituationChoice(choice, member: &member, age: state.character.age)
            member.clamp()
            state.npcs.update(member)
        }
        if choice.id == .accept,
           (event.id.hasPrefix("cast-network-") || event.id.hasPrefix("cast-introduction-")) {
            for memberID in [choice.castMemberID, choice.secondaryCastMemberID].compactMap({ $0 }) {
                guard var member = state.npcs.member(id: memberID) else { continue }
                if !member.connections.contains(where: { $0.kind == .professionalContact && $0.isCurrent }) {
                    member.connections.append(NPCConnection(
                        kind: .professionalContact,
                        startedAge: state.character.age,
                        endedAge: nil
                    ))
                }
                member.clamp()
                state.npcs.update(member)
            }
        }
        if let contactID = choice.familyContactID,
           let index = state.family.contacts.firstIndex(where: { $0.id == contactID }) {
            state.family.contacts[index].bond += choice.familyBondDelta ?? 0
            state.family.contacts[index].lastJudgementAge = state.character.age
            state.family.contacts[index].lastSituationAge = state.character.age
            state.family.contacts[index].lastJudgementReason = choice.narrative
            state.family.clamp()
        }
        let total = event.yearDeltas + core + transitionDeltas + partnerDeltas
        let headline = transition.headline ?? event.headline
        let isYearly = event.kind == .yearly
        var summary: YearSummary?
        if isYearly {
            let base = state.lastYearSummary ?? YearSummarySystem.compose(
                age: state.character.age,
                headline: headline,
                bullets: total.lines,
                deltas: total,
                stanceTitle: state.momentum.stance.title,
                shapeTitle: state.momentum.shape.title,
                focusNote: nil,
                silenceNote: nil,
                wasQuiet: false
            )
            summary = YearSummarySystem.finalize(base, headline: headline, deltas: total)
            state.lastYearSummary = summary
        }
        let followUp = transition.followUp.map {
            PresentedEvent(EducationSystem.followUpEvent($0, state: state), yearDeltas: isYearly ? total : DeltaSummary(), kind: event.kind)
        }
        let subject: PersonHandle? = {
            if let id = choice.familyContactID { return .family(id) }
            if let id = choice.castMemberID ?? choice.secondaryCastMemberID { return .npc(id) }
            if let role = choice.relationshipRole?.npcRole, let npc = state.npcs[role] { return .npc(npc.memberID) }
            if !choice.partnerEffect.isEmpty { return .partner }
            return nil
        }()
        let reaction = ReactionResolver.run(.eventChoice(choice.id.rawValue, subject: subject), state: &state)
        state.pendingEvent = followUp
        return Resolution(
            headline: headline,
            detail: ([transition.detail ?? choice.narrative] + reaction.visibleLines).joined(separator: " "),
            deltas: total,
            isYearly: isYearly,
            yearSummary: summary,
            pendingEvent: followUp,
            reactionNote: reaction.visibleLines.first,
            impacts: reaction.impact.map { [$0] } ?? []
        )
    }

    static func financialPurpose(choice: EventChoice, eventID: String) -> FinancialPurpose {
        choice.financialPurpose ?? FinanceSystem.eventPurpose(eventID)
    }

    static func applyFinance(choice: EventChoice, state: inout LifeState) -> Int? {
        guard choice.financeEffect == .startWorkout else { return nil }
        let before = state.cash
        for id in FinanceSystem.workoutAssets(state) { _ = AssetSystem.sell(ownershipID: id, state: &state) }
        FinanceSystem.startWorkout(state: &state)
        return state.cash - before
    }
}

enum YearlyTickCoordinator {
    static func resolveCareer(state: inout LifeState, world: WorldModifierSnapshot, isActive: Bool) -> SystemYearDeltas {
        guard isActive else { return SystemYearDeltas() }
        return CareerSystem.resolveYear(state: &state, world: world)
    }

    static func resolveRelationship(
        state: inout LifeState,
        baseDeltas: DeltaSummary,
        snapshot: YearInfluenceSnapshot,
        isActive: Bool
    ) -> PartnerYearResolution {
        guard isActive else { return PartnerYearResolution(deltas: DeltaSummary(), note: nil, event: nil) }
        var social = SocialReactivitySystem()
        return social.resolveYear(state: &state, baseDeltas: baseDeltas, snapshot: snapshot)
    }
}

enum SituationStoryletPolicy {
    static func allows(eventID: String, state: LifeState) -> Bool {
        if let career = state.career.activeSituation {
            switch career.kind {
            case .promotionTrack:
                if ["career-promotion-window", "promotion-or-plateau"].contains(eventID) { return false }
            case .workFollowsHome:
                if ["career-burnout-denial", "burnout-weekend", "relationship-audit", "family-marriage-strain"].contains(eventID) { return false }
            }
        }
        if state.partner?.activeSituation != nil,
           ["relationship-audit", "family-marriage-strain"].contains(eventID) {
            return false
        }
        return true
    }
}
