import Foundation

enum PrisonSecurityLevel: String, Codable, CaseIterable, Identifiable {
    case jail
    case low
    case medium
    case high
    case highMaxSecurity

    var id: String { rawValue }
    var title: String {
        switch self {
        case .jail: "Jail"
        case .low: "Low security"
        case .medium: "Medium security"
        case .high: "High security"
        case .highMaxSecurity: "High max security"
        }
    }
    var severity: Int {
        switch self { case .jail: 1; case .low: 2; case .medium: 3; case .high: 4; case .highMaxSecurity: 5 }
    }
    var contactAccess: String {
        switch self {
        case .jail: "Limited calls and visits"
        case .low: "Restricted calls and visits"
        case .medium: "Scheduled contact only"
        case .high: "Rare, monitored contact"
        case .highMaxSecurity: "Almost no direct contact"
        }
    }
    var canManageGang: Bool { self != .highMaxSecurity }
    var canReceiveConjugalVisit: Bool { self == .jail || self == .low || self == .medium }
    var medicalAccess: CareAccess {
        switch self { case .jail, .low: .basic; case .medium, .high: .limited; case .highMaxSecurity: .limited }
    }
}

enum PrisonGangRole: String, Codable, CaseIterable, Identifiable {
    case none, member, lieutenant, leader
    var id: String { rawValue }
    var title: String { rawValue == "none" ? "No gang role" : rawValue.capitalized }
    var authority: Int {
        switch self { case .none: 0; case .member: 1; case .lieutenant: 2; case .leader: 3 }
    }
}

enum PrisonInmateDisposition: String, Codable { case neutral, friend, rival, protector, debtor }

struct PrisonInmateState: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var gangName: String?
    var disposition: PrisonInmateDisposition = .neutral
    var rapport = 0
    var hostility = 20
    var debt = 0
    var alive = true
}

enum PrisonActionKind: String, CaseIterable, Identifiable {
    case fight, buildFriendship, recruit, extort, putMoneyOnBooks, payForProtection, askForProtection
    case takePrisonJob, requestMedicalCare, contactFamily, conjugalVisit
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fight: "Fight"
        case .buildFriendship: "Build friendship"
        case .recruit: "Recruit"
        case .extort: "Extort"
        case .putMoneyOnBooks: "Put money on books"
        case .payForProtection: "Pay for protection"
        case .askForProtection: "Ask for protection"
        case .takePrisonJob: "Take prison work"
        case .requestMedicalCare: "Request medical care"
        case .contactFamily: "Make a family contact"
        case .conjugalVisit: "Request conjugal visit"
        }
    }
}

enum PrisonOrganizationCommand: String, CaseIterable, Identifiable {
    case reassureCrew
    case fundOrganization
    case authorizePlan

    var id: String { rawValue }
    var title: String {
        switch self {
        case .reassureCrew: "Reassure the crew"
        case .fundOrganization: "Fund the organization"
        case .authorizePlan: "Authorize saved plan"
        }
    }
}

struct PrisonState: Codable, Equatable {
    var security: PrisonSecurityLevel?
    var sentenceYearsRemaining = 0
    var originalSentenceYears = 0
    var gangRole: PrisonGangRole = .none
    var gangLoyalty = 50
    var gangInfluence = 0
    var prisonInfluence = 0
    var prisonGangMember = false
    var prisonGangLoyalty = 50
    var hasFlippedOnPlayer = false
    var informantOffered = false
    var isInformant = false
    var informantExposed = false
    var informantDiscoveryRisk = 0
    var prisonNotoriety = 0
    var prisonDebt = 0
    var inmates: [PrisonInmateState] = []
    var protectedByInmateID: String?
    var protectionYearsRemaining = 0
    var retainedPrisonGangAffiliation = false
    var gangDisavowed = false
    var prisonJob: String?
    var mentalStrain = 0
    var medicalDebt = 0
    var commandUsesThisYear = 0
    var ordersSent = 0
    var ordersIntercepted = 0
    var communicationSecurity = 50
    var prisonRandom: SeededRandom

    init(prisonRandom: SeededRandom = SeededRandom(seed: 1)) { self.prisonRandom = prisonRandom }
    var isIncarcerated: Bool { security != nil && sentenceYearsRemaining > 0 }
    var contactAccess: String { security?.contactAccess ?? "Open contact" }
    var canManageGang: Bool { isIncarcerated && security?.canManageGang == true && gangRole.authority > 0 && !hasFlippedOnPlayer }
    var commandCapacity: Int {
        guard canManageGang else { return 0 }
        return max(0, 1 + gangRole.authority - (security?.severity ?? 1) / 2)
    }
    var commandsRemaining: Int { max(0, commandCapacity - commandUsesThisYear) }

    mutating func clamp() {
        sentenceYearsRemaining = max(0, sentenceYearsRemaining)
        originalSentenceYears = max(originalSentenceYears, sentenceYearsRemaining)
        gangLoyalty = min(100, max(0, gangLoyalty))
        gangInfluence = min(100, max(0, gangInfluence))
        prisonInfluence = min(100, max(0, prisonInfluence))
        prisonGangLoyalty = min(100, max(0, prisonGangLoyalty))
        informantDiscoveryRisk = min(100, max(0, informantDiscoveryRisk))
        prisonNotoriety = min(100, max(0, prisonNotoriety))
        prisonDebt = max(0, prisonDebt)
        mentalStrain = min(100, max(0, mentalStrain))
        medicalDebt = max(0, medicalDebt)
        commandUsesThisYear = max(0, commandUsesThisYear)
        ordersSent = max(0, ordersSent)
        ordersIntercepted = max(0, ordersIntercepted)
        communicationSecurity = min(100, max(0, communicationSecurity))
        protectionYearsRemaining = max(0, protectionYearsRemaining)
        inmates = Array(inmates.prefix(24))
        if sentenceYearsRemaining == 0 { security = nil; gangRole = .none }
    }

    enum CodingKeys: String, CodingKey {
        case security, sentenceYearsRemaining, originalSentenceYears, gangRole, gangLoyalty, gangInfluence, prisonInfluence, prisonGangMember, prisonGangLoyalty, hasFlippedOnPlayer, informantOffered, isInformant, informantExposed, informantDiscoveryRisk, prisonNotoriety, prisonDebt, inmates, protectedByInmateID, protectionYearsRemaining, retainedPrisonGangAffiliation, gangDisavowed, prisonJob, mentalStrain, medicalDebt, commandUsesThisYear, ordersSent, ordersIntercepted, communicationSecurity, prisonRandom
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        security = try c.decodeIfPresent(PrisonSecurityLevel.self, forKey: .security)
        sentenceYearsRemaining = try c.decodeIfPresent(Int.self, forKey: .sentenceYearsRemaining) ?? 0
        originalSentenceYears = try c.decodeIfPresent(Int.self, forKey: .originalSentenceYears) ?? sentenceYearsRemaining
        gangRole = try c.decodeIfPresent(PrisonGangRole.self, forKey: .gangRole) ?? .none
        gangLoyalty = try c.decodeIfPresent(Int.self, forKey: .gangLoyalty) ?? 50
        gangInfluence = try c.decodeIfPresent(Int.self, forKey: .gangInfluence) ?? 0
        prisonInfluence = try c.decodeIfPresent(Int.self, forKey: .prisonInfluence) ?? 0
        prisonGangMember = try c.decodeIfPresent(Bool.self, forKey: .prisonGangMember) ?? false
        prisonGangLoyalty = try c.decodeIfPresent(Int.self, forKey: .prisonGangLoyalty) ?? 50
        hasFlippedOnPlayer = try c.decodeIfPresent(Bool.self, forKey: .hasFlippedOnPlayer) ?? false
        informantOffered = try c.decodeIfPresent(Bool.self, forKey: .informantOffered) ?? false
        isInformant = try c.decodeIfPresent(Bool.self, forKey: .isInformant) ?? false
        informantExposed = try c.decodeIfPresent(Bool.self, forKey: .informantExposed) ?? hasFlippedOnPlayer
        informantDiscoveryRisk = try c.decodeIfPresent(Int.self, forKey: .informantDiscoveryRisk) ?? 0
        prisonNotoriety = try c.decodeIfPresent(Int.self, forKey: .prisonNotoriety) ?? 0
        prisonDebt = try c.decodeIfPresent(Int.self, forKey: .prisonDebt) ?? 0
        inmates = try c.decodeIfPresent([PrisonInmateState].self, forKey: .inmates) ?? []
        protectedByInmateID = try c.decodeIfPresent(String.self, forKey: .protectedByInmateID)
        protectionYearsRemaining = try c.decodeIfPresent(Int.self, forKey: .protectionYearsRemaining) ?? 0
        retainedPrisonGangAffiliation = try c.decodeIfPresent(Bool.self, forKey: .retainedPrisonGangAffiliation) ?? prisonGangMember
        gangDisavowed = try c.decodeIfPresent(Bool.self, forKey: .gangDisavowed) ?? false
        prisonJob = try c.decodeIfPresent(String.self, forKey: .prisonJob)
        mentalStrain = try c.decodeIfPresent(Int.self, forKey: .mentalStrain) ?? 0
        medicalDebt = try c.decodeIfPresent(Int.self, forKey: .medicalDebt) ?? 0
        commandUsesThisYear = try c.decodeIfPresent(Int.self, forKey: .commandUsesThisYear) ?? 0
        ordersSent = try c.decodeIfPresent(Int.self, forKey: .ordersSent) ?? 0
        ordersIntercepted = try c.decodeIfPresent(Int.self, forKey: .ordersIntercepted) ?? 0
        communicationSecurity = try c.decodeIfPresent(Int.self, forKey: .communicationSecurity) ?? 50
        prisonRandom = try c.decodeIfPresent(SeededRandom.self, forKey: .prisonRandom) ?? SeededRandom(seed: 1)
    }
}

struct PrisonYearOutcome: Equatable {
    var bullets: [String] = []
    var notes: [String] = []
    var partnerBondDelta = 0
    var familyBondDelta = 0
    var childBondDelta = 0
    var healthDelta = 0
    var cashDelta = 0
    var killed = false
    var released = false
    var consequences: [DomainConsequence] = []
}

struct PrisonActionOutcome: Equatable {
    var bullets: [String] = []
    var healthDelta = 0
    var cashDelta = 0
    var prisonNotorietyDelta = 0
    var prisonInfluenceDelta = 0
    var killed = false
    var consequences: [DomainConsequence] = []
}

struct PrisonCommandOutcome: Equatable {
    var bullets: [String] = []
    var cashDelta = 0
    var intercepted = false
    var operation: CrimeOperationResult?
}

enum PrisonSystem {
    static func sentence(level: PrisonSecurityLevel, years: Int, role: PrisonGangRole, state: inout LifeState) {
        state.prison.security = level
        state.prison.sentenceYearsRemaining = max(1, years)
        state.prison.originalSentenceYears = max(1, years)
        state.prison.gangRole = role
        state.prison.prisonGangMember = role != .none || state.prison.retainedPrisonGangAffiliation
        state.prison.retainedPrisonGangAffiliation = state.prison.prisonGangMember
        state.prison.gangDisavowed = false
        state.prison.hasFlippedOnPlayer = false
        state.prison.informantOffered = false
        state.prison.isInformant = false
        state.prison.informantExposed = false
        state.prison.informantDiscoveryRisk = 0
        state.prison.commandUsesThisYear = 0
        state.prison.communicationSecurity = min(100, 45 + state.prison.prisonInfluence / 2)
        if state.prison.inmates.isEmpty {
            state.prison.inmates = [
                PrisonInmateState(id: "inmate-rivera", name: "Rivera", gangName: "North Block", rapport: 4, hostility: 18),
                PrisonInmateState(id: "inmate-cole", name: "Cole", gangName: nil, rapport: 0, hostility: 24),
                PrisonInmateState(id: "inmate-banks", name: "Banks", gangName: "South Block", rapport: 2, hostility: 30)
            ]
        }
        state.prison.clamp()
        CrimeSystem.syncAbsenceWithPrison(state: &state)
    }

    static func acceptInformant(state: inout LifeState) {
        guard state.prison.informantOffered else { return }
        state.prison.isInformant = true
        state.prison.informantOffered = false
        state.prison.informantExposed = false
        state.prison.hasFlippedOnPlayer = false
        state.prison.informantDiscoveryRisk = min(60, 15 + (state.prison.security?.severity ?? 1) * 8)
        state.prison.gangInfluence = max(0, state.prison.gangInfluence - 20)
        if var path = state.career.criminalPath {
            path.organizationMorale = max(0, path.organizationMorale - 15)
            state.career.criminalPath = path
        }
    }

    static func resolveYear(state: inout LifeState) -> PrisonYearOutcome {
        guard state.prison.isIncarcerated, let level = state.prison.security else { return PrisonYearOutcome() }
        CrimeSystem.syncAbsenceWithPrison(state: &state)
        var result = PrisonYearOutcome()
        state.prison.commandUsesThisYear = 0
        state.prison.communicationSecurity = min(100, state.prison.communicationSecurity + (state.prison.prisonInfluence >= 40 ? 5 : -3))
        let wasLongSentence = state.prison.originalSentenceYears - state.prison.sentenceYearsRemaining >= 2
        let hadProtection = state.prison.protectionYearsRemaining > 0
        if hadProtection { state.prison.protectionYearsRemaining -= 1 }
        if hadProtection && state.prison.protectionYearsRemaining == 0 { result.notes.append("Your protection arrangement expired.") }
        if !hadProtection && state.prison.prisonGangMember && state.prison.sentenceYearsRemaining > 1 { state.prison.prisonDebt += 25 }
        state.prison.sentenceYearsRemaining -= 1
        result.bullets.append(level.title + " · " + String(state.prison.sentenceYearsRemaining) + "y remaining")

        let notoriety = state.career.criminalPath?.notoriety ?? state.assets.notoriety.score
        let influenceGain = max(1, 4 + notoriety / 20 + state.prison.prisonInfluence / 25)
        state.prison.prisonInfluence = min(100, state.prison.prisonInfluence + influenceGain)
        if state.prison.prisonGangMember { result.bullets.append("Prison influence " + String(state.prison.prisonInfluence)) }

        if state.prison.canManageGang {
            state.prison.gangInfluence = max(0, state.prison.gangInfluence - (level.severity > 3 ? 2 : 1))
            result.notes.append("Your gang can still hear from you, but the line is narrowing.")
        } else {
            state.prison.gangInfluence = max(0, state.prison.gangInfluence - 5)
            result.bullets.append("Gang contact is nearly gone")
        }

        // Outside family and partner domains own relationship decay. Prison only emits pressure.
        if level.severity >= 4 && wasLongSentence { result.notes.append("Outside relationships are carrying the cost of the separation.") }
        if level.severity >= 4 && wasLongSentence {
            result.consequences.append(DomainConsequence(source: .legal, target: .relationships, kind: .legalTrouble, magnitude: .major, openedAge: state.character.age, yearsRemaining: 3, headline: "Prison widened the distance", detail: "Long, restrictive incarceration is putting sustained pressure on the relationships outside the facility."))
            result.consequences.append(DomainConsequence(source: .legal, target: .family, kind: .familyConflict, magnitude: .major, openedAge: state.character.age, yearsRemaining: 3, headline: "Family carried the sentence", detail: "The household is adapting around absence, limited contact, and the consequences of the conviction."))
        }
        result.healthDelta -= level.severity + (state.prison.isInformant ? 1 : 0)
        result.cashDelta -= min(300, 35 * level.severity)
        state.prison.mentalStrain = min(100, state.prison.mentalStrain + level.severity + (state.prison.informantExposed ? 5 : 0))
        result.healthDelta -= state.prison.mentalStrain / 25
        if state.prison.medicalDebt > 0 {
            let payment = min(state.prison.medicalDebt, 150)
            state.prison.medicalDebt -= payment
            result.cashDelta -= payment
        }
        if state.prison.prisonJob != nil { result.cashDelta += max(25, 140 - level.severity * 15) }

        if state.prison.isInformant && !state.prison.informantExposed {
            let discovery = min(92, state.prison.informantDiscoveryRisk + level.severity * 6 + (state.prison.prisonGangMember ? 5 : 0) + state.prison.prisonDebt / 100)
            state.prison.informantDiscoveryRisk = discovery
            if state.prison.prisonRandom.next(in: 1...100) <= discovery {
                state.prison.informantExposed = true
                state.prison.hasFlippedOnPlayer = true
                state.prison.gangDisavowed = state.prison.prisonGangMember
                state.prison.prisonGangMember = false
                state.prison.gangRole = .none
                state.prison.prisonNotoriety = min(100, state.prison.prisonNotoriety + 20)
                result.bullets.append("Your cooperation was discovered inside")
                result.consequences.append(DomainConsequence(source: .legal, target: .health, kind: .legalTrouble, magnitude: .critical, openedAge: state.character.age, yearsRemaining: 2, headline: "The prison learned you cooperated", detail: "Exposure increases the danger of assault, extortion, and severe mental strain inside."))
            }
        }
        if state.prison.prisonGangMember && !state.prison.gangDisavowed && state.prison.gangRole != .none,
           (state.prison.gangLoyalty < 25 || state.prison.gangInfluence < 15),
           state.prison.prisonRandom.next(in: 1...100) <= 10 {
            state.prison.gangDisavowed = true
            state.prison.prisonGangMember = false
            state.prison.gangRole = .none
            state.prison.retainedPrisonGangAffiliation = false
            state.prison.gangInfluence = 0
            result.bullets.append("The organization disavowed you inside")
            result.consequences.append(DomainConsequence(source: .legal, target: .identity, kind: .legalTrouble, magnitude: .major, openedAge: state.character.age, yearsRemaining: 2, headline: "Your prison standing collapsed", detail: "The organization no longer recognizes your authority, changing who will protect or answer to you."))
        }
        let threat = max(2, 18 - state.prison.prisonInfluence / 7 - notoriety / 12 + (state.prison.hasFlippedOnPlayer ? 12 : 0) - (state.prison.protectionYearsRemaining > 0 ? 8 : 0))
        if state.prison.prisonGangMember && state.prison.prisonRandom.next(in: 1...100) <= threat {
            let incident = state.prison.prisonRandom.next(in: 1...100)
            if incident <= 5 && level.severity >= 3 {
                result.killed = true
                result.bullets.append("A rival found you in the institution")
            } else if incident <= 35 {
                result.healthDelta -= level.severity + 2
                result.bullets.append("You were harmed inside")
            } else {
                result.cashDelta -= 50 * level.severity
                result.bullets.append("You were extorted inside")
            }
        }

        if level.severity >= 4 && !state.prison.isInformant && !state.prison.informantOffered && state.prison.sentenceYearsRemaining >= 2,
           state.prison.prisonRandom.next(in: 1...100) <= 8 {
            state.prison.informantOffered = true
            result.bullets.append("Federal agents offered you a way out")
        }
        if state.prison.sentenceYearsRemaining == 0 {
            state.prison.security = nil
            state.prison.gangRole = .none
            result.released = true
            state.prison.retainedPrisonGangAffiliation = state.prison.prisonGangMember && !state.prison.gangDisavowed
            result.bullets.append("You left prison")
        }
        state.prison.clamp()
        CrimeSystem.syncAbsenceWithPrison(state: &state)
        return result
    }

    static func perform(_ action: PrisonActionKind, targetID: String?, state: inout LifeState) -> PrisonActionOutcome {
        guard state.prison.isIncarcerated else { return PrisonActionOutcome(bullets: ["You are not incarcerated."]) }
        var result = PrisonActionOutcome()
        let targetIndex = targetID.flatMap { id in state.prison.inmates.firstIndex { $0.id == id } }
        switch action {
        case .fight:
            state.prison.prisonInfluence = min(100, state.prison.prisonInfluence + 3)
            state.prison.prisonNotoriety = min(100, state.prison.prisonNotoriety + 5)
            result.healthDelta = -state.prison.security!.severity
            result.bullets = ["You fought for position inside."]
        case .buildFriendship:
            guard let index = targetIndex else { return PrisonActionOutcome(bullets: ["Choose an inmate first."]) }
            state.prison.inmates[index].rapport += 12; state.prison.inmates[index].hostility = max(0, state.prison.inmates[index].hostility - 8)
            result.prisonInfluenceDelta = 2; result.bullets = ["A relationship inside strengthened."]
        case .recruit:
            guard let index = targetIndex else { return PrisonActionOutcome(bullets: ["Choose an inmate first."]) }
            guard state.prison.prisonGangMember || state.prison.prisonInfluence >= 35 else { return PrisonActionOutcome(bullets: ["You do not have enough standing to recruit."]) }
            state.prison.inmates[index].disposition = .friend; result.prisonInfluenceDelta = 5; result.bullets = ["An inmate joined your prison network."]
        case .extort:
            guard let index = targetIndex else { return PrisonActionOutcome(bullets: ["Choose an inmate first."]) }
            state.prison.inmates[index].debt += 100; state.prison.inmates[index].hostility += 15; result.cashDelta = 100; result.prisonNotorietyDelta = 6; result.bullets = ["You collected a debt and made an enemy."]
        case .putMoneyOnBooks:
            guard let index = targetIndex, state.cash >= 100 else { return PrisonActionOutcome(bullets: ["You need $100 and an inmate target."]) }
            state.prison.inmates[index].rapport += 8; result.cashDelta = -100; result.bullets = ["You put money on an inmate's books."]
        case .payForProtection:
            let cost = state.prison.prisonGangMember ? 180 : 300
            guard state.cash >= cost else { return PrisonActionOutcome(bullets: ["You cannot afford protection this year."]) }
            result.cashDelta = -cost; state.prison.protectionYearsRemaining = 1; state.prison.prisonDebt = max(0, state.prison.prisonDebt - 100); result.prisonNotorietyDelta = state.prison.prisonGangMember ? -8 : -4; result.bullets = ["Protection bought time, not safety."]
        case .askForProtection:
            guard let index = targetIndex else { return PrisonActionOutcome(bullets: ["Choose an inmate first."]) }
            guard state.prison.inmates[index].rapport >= 10 || state.prison.prisonInfluence >= 40 else { return PrisonActionOutcome(bullets: ["Nobody inside owes you protection yet."]) }
            state.prison.protectedByInmateID = state.prison.inmates[index].id; state.prison.protectionYearsRemaining = 1; result.prisonNotorietyDelta = -3; result.bullets = ["An inmate agreed to protect you—for now."]
        case .takePrisonJob:
            state.prison.prisonJob = state.prison.prisonJob == nil ? "Kitchen detail" : nil
            result.prisonInfluenceDelta = state.prison.prisonJob == nil ? 0 : 1
            result.bullets = [state.prison.prisonJob == nil ? "You left your prison job." : "You took a prison job for structure and a small income."]
        case .requestMedicalCare:
            let cost = state.prison.security?.medicalAccess == .basic ? 40 : 90
            state.prison.medicalDebt += cost
            state.prison.mentalStrain = max(0, state.prison.mentalStrain - 8)
            result.healthDelta = state.prison.security?.medicalAccess == .basic ? 2 : 1
            result.bullets = ["You requested medical care; the cost was added to your prison debt."]
        case .contactFamily:
            result.prisonNotorietyDelta = -1
            result.bullets = ["You made a monitored family contact."]
            result.consequences.append(DomainConsequence(source: .legal, target: .family, kind: .familyConflict, magnitude: .minor, openedAge: state.character.age, yearsRemaining: 1, headline: "A prison call reached home", detail: "Contact helped maintain the connection, but the limits of the facility were still present.") )
        case .conjugalVisit:
            guard state.prison.security?.canReceiveConjugalVisit == true else { return PrisonActionOutcome(bullets: ["This facility does not allow conjugal visits."]) }
            state.prison.mentalStrain = max(0, state.prison.mentalStrain - 10)
            result.healthDelta = 1
            result.bullets = ["A conjugal visit gave the relationship a little room to breathe."]
            result.consequences.append(DomainConsequence(source: .legal, target: .relationships, kind: .legalTrouble, magnitude: .minor, openedAge: state.character.age, yearsRemaining: 1, headline: "Contact softened the sentence", detail: "A rare private visit helped preserve connection during incarceration.") )
        }
        state.prison.prisonInfluence = min(100, max(0, state.prison.prisonInfluence + result.prisonInfluenceDelta))
        state.prison.prisonNotoriety = min(100, max(0, state.prison.prisonNotoriety + result.prisonNotorietyDelta))
        state.prison.clamp()
        return result
    }

    static func issueOrganizationCommand(_ command: PrisonOrganizationCommand, planID: String? = nil, state: inout LifeState) -> PrisonCommandOutcome {
        guard state.prison.canManageGang,
              state.prison.commandsRemaining > 0,
              var path = state.career.criminalPath,
              path.isOrganization else {
            return PrisonCommandOutcome(bullets: ["The organization cannot receive a reliable order right now."])
        }
        if command == .fundOrganization && state.cash < 500 {
            return PrisonCommandOutcome(bullets: ["You need $500 available outside the prison to fund the organization."])
        }
        if command == .authorizePlan && (planID == nil || !path.plans.contains(where: { $0.id == planID })) {
            return PrisonCommandOutcome(bullets: ["Choose a saved plan to authorize."])
        }

        state.prison.commandUsesThisYear += 1
        state.prison.ordersSent += 1
        let severity = state.prison.security?.severity ?? 1
        let interceptionRisk = min(70, max(5, severity * 12 + path.heat / 8 + (state.prison.isInformant ? 20 : 0) - state.prison.communicationSecurity / 3))
        if state.prison.prisonRandom.next(in: 1...100) <= interceptionRisk {
            state.prison.ordersIntercepted += 1
            path.organizationMorale = max(0, path.organizationMorale - 8)
            path.gangTrust = max(0, path.gangTrust - 5)
            path.heat = min(100, path.heat + 8)
            state.career.criminalPath = path
            return PrisonCommandOutcome(bullets: ["The message was intercepted before the crew could act."], intercepted: true)
        }

        var result = PrisonCommandOutcome()
        switch command {
        case .reassureCrew:
            path.organizationMorale = min(100, path.organizationMorale + 5)
            path.gangTrust = min(100, path.gangTrust + 3)
            result.bullets = ["Your message reached the crew and steadied the chain of command."]
        case .fundOrganization:
            path.organizationMorale = min(100, path.organizationMorale + 8)
            path.gangTrust = min(100, path.gangTrust + 4)
            result.cashDelta = -500
            result.bullets = ["Money reached the organization through trusted channels."]
        case .authorizePlan:
            guard let planID, let operation = CrimeSystem.executePlan(id: planID, state: &state) else {
                state.career.criminalPath = path
                return PrisonCommandOutcome(bullets: ["The acting leader could not prepare that plan."])
            }
            result.operation = operation
            result.cashDelta = operation.payout
            result.bullets = ["The acting leader received authorization and executed the saved plan."]
        }
        if command != .authorizePlan { state.career.criminalPath = path }
        return result
    }

    static func sendOrganizationSupport(state: inout LifeState) -> Bool {
        guard state.prison.canManageGang, var path = state.career.criminalPath, path.isOrganization else { return false }
        path.organizationMorale = min(100, path.organizationMorale + 4)
        path.gangTrust = min(100, path.gangTrust + 2)
        state.career.criminalPath = path
        state.prison.gangInfluence = min(100, state.prison.gangInfluence + 4)
        return true
    }
}
