import Foundation

enum CrimeSeverity: String, Codable, CaseIterable, Identifiable {
    case petty, serious, violent, heinous
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var baseYears: Int {
        switch self { case .petty: 0; case .serious: 2; case .violent: 6; case .heinous: 12 }
    }
}

enum LegalCaseOrigin: String, Codable, CaseIterable, Identifiable {
    case solo, gangMember, gangLeader, enterprise
    var id: String { rawValue }
    var title: String {
        switch self { case .solo: "Solo"; case .gangMember: "Gang member"; case .gangLeader: "Gang leader"; case .enterprise: "Enterprise" }
    }
}

enum LegalCaseStatus: String, Codable, CaseIterable, Identifiable {
    case investigation, pretrial, pleaOffered, trial, convicted, acquitted, appealPending, appealResolved
    var id: String { rawValue }
    var title: String { rawValue == "pleaOffered" ? "Plea offered" : rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).capitalized }
}

enum InvestigationAgency: String, Codable, CaseIterable, Identifiable {
    case local, state, federal, financialCrimes, taskForce

    var id: String { rawValue }
    var title: String {
        switch self {
        case .local: "Local police"
        case .state: "State investigators"
        case .federal: "Federal investigators"
        case .financialCrimes: "Financial crimes unit"
        case .taskForce: "Joint task force"
        }
    }
}

enum PretrialStatus: String, Codable, CaseIterable, Identifiable {
    case none, released, detained, restricted, electronicMonitoring

    var id: String { rawValue }
    var title: String {
        switch self {
        case .none: "Not in pretrial"
        case .released: "Released on bail"
        case .detained: "Detained"
        case .restricted: "Supervised release"
        case .electronicMonitoring: "Electronic monitoring"
        }
    }
}

enum LegalTargetType: String, Codable, CaseIterable, Identifiable {
    case player, organization, specialist, frontBusiness
    var id: String { rawValue }
    var title: String { rawValue == "frontBusiness" ? "Front business" : rawValue.capitalized }
}

enum LegalTargetStatus: String, Codable, CaseIterable, Identifiable {
    case exposed, questioned, arrested, cooperating, protected, cleared
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum LegalCooperationStatus: String, Codable, CaseIterable, Identifiable {
    case none, offerAvailable, accepted, declined
    var id: String { rawValue }
    var title: String {
        switch self {
        case .none: "No cooperation offer"
        case .offerAvailable: "Cooperation offer"
        case .accepted: "Cooperation accepted"
        case .declined: "Offer declined"
        }
    }
}

struct LegalCooperationOffer: Equatable, Identifiable {
    var id: String { "\(caseID):\(targetID)" }
    let caseID: String
    let targetID: String
    let targetType: LegalTargetType
    let sentenceReduction: Int
    let headline: String
    let detail: String
}

enum EnterpriseLegalAction: String, Codable, CaseIterable, Identifiable {
    case protect, cutLoose, threaten, provideLegalSupport
    var id: String { rawValue }
    var title: String {
        switch self {
        case .protect: "Protect specialist"
        case .cutLoose: "Cut specialist loose"
        case .threaten: "Threaten specialist"
        case .provideLegalSupport: "Provide legal support"
        }
    }
}

struct LegalTargetState: Codable, Equatable, Identifiable {
    var id: String
    var type: LegalTargetType
    var evidenceStrength = 0
    var exposure = 0
    var cooperationRisk = 0
    var status: LegalTargetStatus = .exposed
    var carryingEnterpriseEvidence = false
    var lastActionAge: Int?

    mutating func clamp() {
        evidenceStrength = min(100, max(0, evidenceStrength))
        exposure = min(100, max(0, exposure))
        cooperationRisk = min(100, max(0, cooperationRisk))
    }
}

struct EnterpriseLegalImpact: Equatable {
    var organizationMoraleDelta = 0
    var organizationCashFlowDelta = 0
    var organizationHeatDelta = 0
    var specialistLoyaltyDelta = 0
    var unavailableSpecialistIDs: [String] = []
    var frontBusinessClosureYears = 0
    var frontBusinessScrutinyDelta = 0
    var frontBusinessRestricted = false
}

struct CriminalLegalActionOutcome: Equatable {
    var headline: String
    var detail: String
    var cashDelta = 0
    var impact = EnterpriseLegalImpact()
    var consequences: [DomainConsequence] = []
}

enum LegalLawyerSpecialty: String, Codable, CaseIterable, Identifiable {
    case general, violentCrime, organizedCrime, financialCrime, appeals
    var id: String { rawValue }
    var title: String { rawValue == "violentCrime" ? "Violent crime" : rawValue == "organizedCrime" ? "Organized crime" : rawValue == "financialCrime" ? "Financial crime" : rawValue.capitalized }
}

struct DefenseLawyerState: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var specialty: LegalLawyerSpecialty
    var defenseSkill: Int
    var trialSkill: Int
    var pleaSkill: Int
    var appealSkill: Int
    var relationship: Int = 0
    var retainer = 0

    mutating func clamp() {
        defenseSkill = min(100, max(0, defenseSkill)); trialSkill = min(100, max(0, trialSkill))
        pleaSkill = min(100, max(0, pleaSkill)); appealSkill = min(100, max(0, appealSkill))
        relationship = min(100, max(-100, relationship)); retainer = max(0, retainer)
    }
}

struct LegalCaseState: Codable, Equatable, Identifiable {
    var id: String
    var operation: CrimeOperationType
    var severity: CrimeSeverity
    var origin: LegalCaseOrigin
    var status: LegalCaseStatus = .investigation
    var agency: InvestigationAgency = .local
    var evidenceStrength = 0
    var enterpriseEvidence = 0
    var investigationVisibility = 0
    var financialTrailStrength = 0
    var witnessPressure = 0
    var searchWarrantCount = 0
    var yearsUnderInvestigation = 0
    var repeatOffenderCount = 0
    var victimHarm = 0
    var yearsOpen = 0
    var trialProgress = 0
    var pleaYears: Int?
    var assignedLawyerID: String?
    var convictionIsFelony = false
    var sentenceYears = 0
    var security: PrisonSecurityLevel = .jail
    var appealCount = 0
    var pretrialStatus: PretrialStatus = .none
    var bailAmount = 0
    var postedBailAmount = 0
    var travelRestricted = false
    var noContactRestricted = false
    var pretrialViolationCount = 0
    var targets: [LegalTargetState] = []
    var cooperationStatus: LegalCooperationStatus = .none
    var cooperationTargetID: String?
    var cooperationOfferAge: Int?
    var cooperationDecisionAge: Int?
    var playerCooperated = false
    var cooperationRecordPermanent = false
    var cooperationSentenceReduction = 0

    var isOpen: Bool { status == .investigation || status == .pretrial || status == .pleaOffered || status == .trial || status == .appealPending }

    mutating func clamp() {
        evidenceStrength = min(100, max(0, evidenceStrength)); enterpriseEvidence = min(100, max(0, enterpriseEvidence))
        investigationVisibility = min(100, max(0, investigationVisibility))
        financialTrailStrength = min(100, max(0, financialTrailStrength))
        witnessPressure = min(100, max(0, witnessPressure))
        searchWarrantCount = min(20, max(0, searchWarrantCount))
        yearsUnderInvestigation = max(0, yearsUnderInvestigation)
        repeatOffenderCount = max(0, repeatOffenderCount); victimHarm = min(100, max(0, victimHarm))
        yearsOpen = max(0, yearsOpen); trialProgress = min(3, max(0, trialProgress)); sentenceYears = max(0, sentenceYears)
        appealCount = max(0, appealCount)
        bailAmount = max(0, bailAmount); postedBailAmount = min(bailAmount, max(0, postedBailAmount))
        pretrialViolationCount = max(0, pretrialViolationCount)
        cooperationSentenceReduction = min(10, max(0, cooperationSentenceReduction))
        targets = Array(targets.prefix(9)); targets.indices.forEach { targets[$0].clamp() }
        if status != .pretrial { pretrialStatus = .none; travelRestricted = false; noContactRestricted = false }
    }
}

extension LegalCaseState {
    private enum CodingKeys: String, CodingKey {
        case id, operation, severity, origin, status, agency, evidenceStrength, enterpriseEvidence
        case investigationVisibility, financialTrailStrength, witnessPressure, searchWarrantCount, yearsUnderInvestigation
        case repeatOffenderCount, victimHarm, yearsOpen, trialProgress, pleaYears, assignedLawyerID
        case convictionIsFelony, sentenceYears, security, appealCount, pretrialStatus, bailAmount, postedBailAmount
        case travelRestricted, noContactRestricted, pretrialViolationCount
        case targets, cooperationStatus, cooperationTargetID, cooperationOfferAge, cooperationDecisionAge
        case playerCooperated, cooperationRecordPermanent, cooperationSentenceReduction
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        operation = try c.decode(CrimeOperationType.self, forKey: .operation)
        severity = try c.decode(CrimeSeverity.self, forKey: .severity)
        origin = try c.decode(LegalCaseOrigin.self, forKey: .origin)
        status = try c.decodeIfPresent(LegalCaseStatus.self, forKey: .status) ?? .investigation
        agency = try c.decodeIfPresent(InvestigationAgency.self, forKey: .agency) ?? .local
        evidenceStrength = try c.decodeIfPresent(Int.self, forKey: .evidenceStrength) ?? 0
        enterpriseEvidence = try c.decodeIfPresent(Int.self, forKey: .enterpriseEvidence) ?? 0
        investigationVisibility = try c.decodeIfPresent(Int.self, forKey: .investigationVisibility) ?? 0
        financialTrailStrength = try c.decodeIfPresent(Int.self, forKey: .financialTrailStrength) ?? 0
        witnessPressure = try c.decodeIfPresent(Int.self, forKey: .witnessPressure) ?? 0
        searchWarrantCount = try c.decodeIfPresent(Int.self, forKey: .searchWarrantCount) ?? 0
        yearsUnderInvestigation = try c.decodeIfPresent(Int.self, forKey: .yearsUnderInvestigation) ?? 0
        repeatOffenderCount = try c.decodeIfPresent(Int.self, forKey: .repeatOffenderCount) ?? 0
        victimHarm = try c.decodeIfPresent(Int.self, forKey: .victimHarm) ?? 0
        yearsOpen = try c.decodeIfPresent(Int.self, forKey: .yearsOpen) ?? 0
        trialProgress = try c.decodeIfPresent(Int.self, forKey: .trialProgress) ?? 0
        pleaYears = try c.decodeIfPresent(Int.self, forKey: .pleaYears)
        assignedLawyerID = try c.decodeIfPresent(String.self, forKey: .assignedLawyerID)
        convictionIsFelony = try c.decodeIfPresent(Bool.self, forKey: .convictionIsFelony) ?? false
        sentenceYears = try c.decodeIfPresent(Int.self, forKey: .sentenceYears) ?? 0
        security = try c.decodeIfPresent(PrisonSecurityLevel.self, forKey: .security) ?? .jail
        appealCount = try c.decodeIfPresent(Int.self, forKey: .appealCount) ?? 0
        pretrialStatus = try c.decodeIfPresent(PretrialStatus.self, forKey: .pretrialStatus) ?? .none
        bailAmount = try c.decodeIfPresent(Int.self, forKey: .bailAmount) ?? 0
        postedBailAmount = try c.decodeIfPresent(Int.self, forKey: .postedBailAmount) ?? 0
        travelRestricted = try c.decodeIfPresent(Bool.self, forKey: .travelRestricted) ?? false
        noContactRestricted = try c.decodeIfPresent(Bool.self, forKey: .noContactRestricted) ?? false
        pretrialViolationCount = try c.decodeIfPresent(Int.self, forKey: .pretrialViolationCount) ?? 0
        targets = try c.decodeIfPresent([LegalTargetState].self, forKey: .targets) ?? []
        cooperationStatus = try c.decodeIfPresent(LegalCooperationStatus.self, forKey: .cooperationStatus) ?? .none
        cooperationTargetID = try c.decodeIfPresent(String.self, forKey: .cooperationTargetID)
        cooperationOfferAge = try c.decodeIfPresent(Int.self, forKey: .cooperationOfferAge)
        cooperationDecisionAge = try c.decodeIfPresent(Int.self, forKey: .cooperationDecisionAge)
        playerCooperated = try c.decodeIfPresent(Bool.self, forKey: .playerCooperated) ?? false
        cooperationRecordPermanent = try c.decodeIfPresent(Bool.self, forKey: .cooperationRecordPermanent) ?? false
        cooperationSentenceReduction = try c.decodeIfPresent(Int.self, forKey: .cooperationSentenceReduction) ?? 0
        clamp()
    }
}

struct CriminalLegalYearOutcome: Equatable {
    var bullets: [String] = []
    var notes: [String] = []
    var cashDelta = 0
    var openedCaseID: String?
    var convictedCaseID: String?
    var pretrialCaseID: String?
    var consequences: [DomainConsequence] = []
    var enterpriseImpact = EnterpriseLegalImpact()
    var targetEventHeadline: String?
}

enum CriminalLegalSystem {
    static func severity(for operation: CrimeOperationType) -> CrimeSeverity {
        switch operation {
        case .burglary, .vehicleTheft: .petty
        case .fraud, .smuggling, .robbery, .extortion: .serious
        case .territoryAttack, .kidnapping: .violent
        case .murder: .heinous
        }
    }

    static func origin(for path: CriminalPathState) -> LegalCaseOrigin {
        switch path.mode { case .solo: .solo; case .gangMember: .gangMember; case .gangLeader: .gangLeader; case .enterprise: .enterprise }
    }

    static func registerCrime(operation: CrimeOperationType, risk: CrimeRiskBreakdown, state: inout LifeState) -> CriminalLegalYearOutcome {
        guard let path = state.career.criminalPath else { return CriminalLegalYearOutcome() }
        let severity = severity(for: operation)
        let repeatCount = path.repeatedOperations[operation.rawValue, default: 0]
        let organizationBonus = path.isOrganization ? path.heat / 3 + path.notoriety / 5 : 0
        let detection = min(92, max(3, risk.total + path.heat / 3 + repeatCount * 3 + organizationBonus))
        guard state.legal.legalRandom.next(in: 1...100) <= detection else { return CriminalLegalYearOutcome(notes: ["The investigation did not close around you."]) }

        let origin = origin(for: path)
        if severity == .petty && repeatCount == 1 && origin == .solo {
            let fine = 150 + path.heat * 3
            state.legal.misdemeanorConvictions += 1
            return CriminalLegalYearOutcome(bullets: ["A petty conviction became a $\(fine) fine"], cashDelta: -fine)
        }

        let id = "case-\(state.character.age)-\(operation.rawValue)-\(state.legal.caseSequence)"
        state.legal.caseSequence += 1
        var legalCase = LegalCaseState(
            id: id, operation: operation, severity: severity, origin: origin,
            status: .investigation,
            agency: investigationAgency(for: operation, origin: origin),
            evidenceStrength: min(100, detection + (risk.informant * 4)),
            enterpriseEvidence: origin == .enterprise ? min(100, path.heat + path.notoriety / 2 + path.specialists.count * 3) : 0,
            investigationVisibility: min(100, max(8, detection / 2 + path.notoriety / 3)),
            financialTrailStrength: min(100, (operation == .fraud ? 32 : operation == .smuggling ? 22 : 8) + (origin == .enterprise ? 12 : 0)),
            witnessPressure: min(100, risk.informant * 8 + (origin == .enterprise ? 8 : 0)),
            repeatOffenderCount: repeatCount,
            victimHarm: operation == .murder ? 100 : operation == .kidnapping ? 75 : operation == .territoryAttack ? 55 : 0,
            pleaYears: nil,
            assignedLawyerID: nil,
            convictionIsFelony: severity != .petty || repeatCount > 1,
            sentenceYears: max(1, severity.baseYears + repeatCount + (origin == .gangLeader ? 2 : 0) + (origin == .enterprise ? 4 : 0)),
            security: security(for: severity, origin: origin)
        )
        legalCase.targets = buildTargets(for: legalCase, path: path)
        legalCase.clamp()
        state.legal.cases.append(legalCase)
        state.legal.activeCaseID = id
        state.legal.clamp()
        return CriminalLegalYearOutcome(
            bullets: [origin == .enterprise ? "Federal investigators opened an enterprise case" : "You were charged with \(severity.title.lowercased()) criminal conduct"],
            openedCaseID: id
        )
    }

    static func resolveYear(state: inout LifeState) -> CriminalLegalYearOutcome {
        var result = CriminalLegalYearOutcome()
        guard var path = state.career.criminalPath else { return result }
        for index in state.legal.cases.indices {
            guard state.legal.cases[index].isOpen else { continue }
            var legalCase = state.legal.cases[index]
            legalCase.yearsOpen += 1
            let defense = defenseStrength(for: legalCase, path: path, legal: state.legal)
            switch legalCase.status {
            case .investigation:
                legalCase.yearsUnderInvestigation += 1
                if legalCase.origin == .enterprise, legalCase.targets.isEmpty {
                    // Enterprise cases from v45 remain readable after migration;
                    // attach their bounded target roster at the next legal tick.
                    legalCase.targets = buildTargets(for: legalCase, path: path)
                }
                let growth = max(2, path.heat / 6 + path.notoriety / 14 + legalCase.witnessPressure / 18 + legalCase.financialTrailStrength / 20 + (path.organizationAbsent ? 2 : 0))
                legalCase.enterpriseEvidence = min(100, legalCase.enterpriseEvidence + growth)
                legalCase.evidenceStrength = min(100, legalCase.evidenceStrength + growth / 2)
                legalCase.investigationVisibility = min(100, legalCase.investigationVisibility + max(1, growth / 2))
                if legalCase.origin == .enterprise {
                    resolveEnterpriseTargets(legalCase: &legalCase, path: path, state: &state, result: &result)
                }
                if legalCase.origin == .enterprise,
                   state.legal.legalRandom.next(in: 1...100) <= min(24, max(3, legalCase.investigationVisibility / 7)) {
                    legalCase.searchWarrantCount = min(20, legalCase.searchWarrantCount + 1)
                    legalCase.evidenceStrength = min(100, legalCase.evidenceStrength + 4)
                    result.bullets.append(legalCase.financialTrailStrength >= 25 ? "Investigators subpoenaed enterprise financial records" : "Investigators searched an organization location")
                }
                if legalCase.origin == .enterprise,
                   state.legal.legalRandom.next(in: 1...100) <= min(18, legalCase.enterpriseEvidence / 8),
                   let specialistIndex = path.specialists.firstIndex(where: { $0.isAvailable }) {
                    path.specialists[specialistIndex].isArrested = true
                    if let targetIndex = legalCase.targets.firstIndex(where: { $0.id == "specialist:\(path.specialists[specialistIndex].id)" }) {
                        legalCase.targets[targetIndex].status = .arrested
                        legalCase.targets[targetIndex].exposure = min(100, legalCase.targets[targetIndex].exposure + 18)
                    }
                    legalCase.evidenceStrength = min(100, legalCase.evidenceStrength + 8)
                    result.bullets.append("An organization specialist was arrested in the investigation")
                }
                let chargingThreshold = legalCase.origin == .enterprise ? 62 : 48
                if legalCase.evidenceStrength + legalCase.enterpriseEvidence / 2 >= chargingThreshold || legalCase.yearsUnderInvestigation >= 4 {
                    legalCase.status = .pretrial
                    legalCase.pretrialStatus = .detained
                    legalCase.bailAmount = bailAmount(for: legalCase)
                    legalCase.travelRestricted = legalCase.origin == .enterprise || legalCase.severity == .violent || legalCase.severity == .heinous
                    legalCase.noContactRestricted = legalCase.origin == .enterprise
                    legalCase.pleaYears = max(2, legalCase.sentenceYears - defense / 20)
                    result.pretrialCaseID = legalCase.id
                    result.bullets.append("The case reached court and pretrial conditions were imposed")
                } else {
                    result.bullets.append(legalCase.origin == .enterprise ? "The enterprise investigation kept building" : "The investigation remained open")
                }
            case .pretrial:
                resolvePretrial(legalCase: &legalCase, path: path, state: &state, result: &result)
            case .trial:
                legalCase.trialProgress += 1
                if legalCase.trialProgress < (legalCase.origin == .enterprise ? 2 : 1) {
                    result.bullets.append("The criminal case moved through another court stage")
                } else {
                    let acquittalChance = min(65, max(8, defense + 45 - legalCase.evidenceStrength / 2 - legalCase.enterpriseEvidence / 4))
                    if state.legal.legalRandom.next(in: 1...100) <= acquittalChance {
                        legalCase.status = .acquitted
                        releaseBail(for: &legalCase, state: &state)
                        result.bullets.append("The court acquitted you")
                    } else {
                        convict(legalCase: &legalCase, path: &path, state: &state)
                        result.convictedCaseID = legalCase.id
                        result.bullets.append("The court found you guilty")
                    }
                }
            case .appealPending:
                let appealChance = min(55, max(5, defense + legalCase.appealCount * 5 - legalCase.evidenceStrength / 3))
                legalCase.status = .appealResolved
                if state.legal.legalRandom.next(in: 1...100) <= appealChance {
                    legalCase.status = .acquitted
                    legalCase.sentenceYears = 0
                    releaseBail(for: &legalCase, state: &state)
                    result.bullets.append("Your appeal overturned the conviction")
                } else {
                    legalCase.sentenceYears = max(1, legalCase.sentenceYears - 1)
                    result.bullets.append("Your appeal reduced the sentence by one year")
                    if legalCase.sentenceYears > 0 {
                        convict(legalCase: &legalCase, path: &path, state: &state)
                    }
                }
            case .pleaOffered, .convicted, .acquitted, .appealResolved:
                break
            }
            state.legal.cases[index] = legalCase
        }
        path.clamp(); state.career.criminalPath = path
        state.legal.clamp()
        return result
    }

    static func acceptPlea(caseID: String, state: inout LifeState) -> Bool {
        guard let index = state.legal.cases.firstIndex(where: { $0.id == caseID }), [.pleaOffered, .pretrial].contains(state.legal.cases[index].status) else { return false }
        let hadCriminalPath = state.career.criminalPath != nil
        var path = state.career.criminalPath ?? CriminalPathState()
        var legalCase = state.legal.cases[index]
        legalCase.sentenceYears = legalCase.pleaYears ?? legalCase.sentenceYears
        convict(legalCase: &legalCase, path: &path, state: &state)
        path.clamp()
        if hadCriminalPath { state.career.criminalPath = path }
        state.legal.cases[index] = legalCase
        state.legal.clamp()
        return true
    }

    static func cooperationOffer(caseID: String, state: LifeState) -> LegalCooperationOffer? {
        guard let legalCase = state.legal.cases.first(where: { $0.id == caseID }),
              legalCase.origin == .enterprise,
              [.pretrial, .pleaOffered].contains(legalCase.status),
              legalCase.cooperationStatus == .offerAvailable,
              let targetID = legalCase.cooperationTargetID else { return nil }
        let target = legalCase.targets.first(where: { $0.id == targetID })
        if let target, target.type == .specialist,
           ![.questioned, .arrested, .cooperating].contains(target.status) { return nil }
        let targetType = target?.type ?? (legalCase.playerCooperated ? .player : .specialist)
        return LegalCooperationOffer(
            caseID: caseID,
            targetID: targetID,
            targetType: targetType,
            sentenceReduction: legalCase.cooperationSentenceReduction,
            headline: targetType == .player ? "Prosecutors Pressed You To Cooperate" : "A Specialist Offered Testimony",
            detail: targetType == .player
                ? "Cooperation could reduce the expected sentence, but the organization and people around you will know what it cost."
                : "The specialist can trade testimony for a narrower personal exposure. The enterprise case will become stronger."
        )
    }

    static func declineCooperation(caseID: String, state: inout LifeState) -> CriminalLegalActionOutcome? {
        guard let index = state.legal.cases.firstIndex(where: { $0.id == caseID }),
              state.legal.cases[index].cooperationStatus == .offerAvailable else { return nil }
        state.legal.cases[index].cooperationStatus = .declined
        state.legal.cases[index].cooperationDecisionAge = state.character.age
        state.legal.cases[index].clamp()
        return CriminalLegalActionOutcome(headline: "The Cooperation Window Closed", detail: "You declined the offer. The case will continue on its existing evidence and sentence position.")
    }

    static func acceptCooperation(caseID: String, state: inout LifeState) -> CriminalLegalActionOutcome? {
        guard let caseIndex = state.legal.cases.firstIndex(where: { $0.id == caseID }),
              let offer = cooperationOffer(caseID: caseID, state: state),
              !state.legal.cases[caseIndex].playerCooperated else { return nil }

        var legalCase = state.legal.cases[caseIndex]
        legalCase.cooperationStatus = .accepted
        legalCase.cooperationDecisionAge = state.character.age
        legalCase.cooperationRecordPermanent = true
        legalCase.cooperationSentenceReduction = max(1, min(10, legalCase.cooperationSentenceReduction))
        legalCase.sentenceYears = max(1, legalCase.sentenceYears - legalCase.cooperationSentenceReduction)
        legalCase.pleaYears = max(1, (legalCase.pleaYears ?? legalCase.sentenceYears) - legalCase.cooperationSentenceReduction)

        var outcome: CriminalLegalActionOutcome
        if offer.targetType == .player {
            legalCase.playerCooperated = true
            legalCase.evidenceStrength = min(100, legalCase.evidenceStrength + 20)
            legalCase.enterpriseEvidence = min(100, legalCase.enterpriseEvidence + 20)
            if let targetIndex = legalCase.targets.firstIndex(where: { $0.type == .player }) {
                legalCase.targets[targetIndex].status = .cooperating
                legalCase.targets[targetIndex].carryingEnterpriseEvidence = true
                legalCase.targets[targetIndex].evidenceStrength = min(100, legalCase.targets[targetIndex].evidenceStrength + 20)
            }
            outcome = CriminalLegalActionOutcome(
                headline: "Your Cooperation Became Public",
                detail: "The sentence position improved, but the organization now has to live with your testimony.",
                impact: EnterpriseLegalImpact(organizationMoraleDelta: -20, organizationHeatDelta: 20, specialistLoyaltyDelta: -8),
                consequences: [
                    DomainConsequence(source: .legal, target: .relationships, kind: .legalTrouble, magnitude: .major, openedAge: state.character.age, yearsRemaining: 4, headline: "Trust broke over your cooperation", detail: "People close to the enterprise are carrying the knowledge that you protected yourself by exposing it.")
                ]
            )
        } else {
            legalCase.enterpriseEvidence = min(100, legalCase.enterpriseEvidence + 10)
            legalCase.evidenceStrength = min(100, legalCase.evidenceStrength + 8)
            if let targetIndex = legalCase.targets.firstIndex(where: { $0.id == offer.targetID }) {
                legalCase.targets[targetIndex].status = .cooperating
                legalCase.targets[targetIndex].carryingEnterpriseEvidence = true
                legalCase.targets[targetIndex].evidenceStrength = min(100, legalCase.targets[targetIndex].evidenceStrength + 18)
            }
            outcome = CriminalLegalActionOutcome(
                headline: "A Specialist Began Cooperating",
                detail: "The specialist traded testimony for a narrower personal exposure. The enterprise case is stronger now.",
                impact: EnterpriseLegalImpact(organizationMoraleDelta: -12, organizationCashFlowDelta: -25, organizationHeatDelta: 12, specialistLoyaltyDelta: -4, unavailableSpecialistIDs: [String(offer.targetID.dropFirst("specialist:".count))]),
                consequences: [
                    DomainConsequence(source: .legal, target: .career, kind: .legalTrouble, magnitude: .major, openedAge: state.character.age, yearsRemaining: 3, headline: "A specialist became a prosecution witness", detail: "The enterprise has less capacity and less privacy while the case moves forward.")
                ]
            )
        }
        state.legal.cases[caseIndex] = legalCase
        state.legal.clamp()
        return outcome
    }

    static func chooseTrial(caseID: String, state: inout LifeState) -> Bool {
        guard let index = state.legal.cases.firstIndex(where: { $0.id == caseID }), [.pleaOffered, .pretrial].contains(state.legal.cases[index].status) else { return false }
        state.legal.cases[index].status = .trial
        state.legal.cases[index].pleaYears = nil
        return true
    }

    static func appeal(caseID: String, state: inout LifeState) -> Bool {
        guard let index = state.legal.cases.firstIndex(where: { $0.id == caseID }), state.legal.cases[index].status == .convicted, state.legal.cases[index].appealCount < 2 else { return false }
        state.legal.cases[index].status = .appealPending
        state.legal.cases[index].appealCount += 1
        return true
    }

    static func hireLawyer(specialty: LegalLawyerSpecialty, forOrganization: Bool, state: inout LifeState) -> DefenseLawyerState? {
        let cost = specialty == .general ? 4_000 : 7_500
        guard state.cash >= cost else { return nil }
        if forOrganization {
            guard var path = state.career.criminalPath, path.isOrganization, path.defenseTeam.count < 3 else { return nil }
            let lawyer = makeLawyer(specialty: specialty, sequence: path.defenseTeam.count + 1, retainer: cost)
            path.defenseTeam.append(lawyer); path.clamp(); state.career.criminalPath = path
            state.cash -= cost
            return lawyer
        }
        guard state.legal.personalLawyers.count < 3 else { return nil }
        let lawyer = makeLawyer(specialty: specialty, sequence: state.legal.personalLawyers.count + 1, retainer: cost)
        state.legal.personalLawyers.append(lawyer); state.legal.clamp(); state.cash -= cost
        return lawyer
    }

    static func assignLawyer(caseID: String, lawyerID: String, state: inout LifeState) -> Bool {
        guard let index = state.legal.cases.firstIndex(where: { $0.id == caseID }) else { return false }
        let lawyers = (state.career.criminalPath?.defenseTeam ?? []) + state.legal.personalLawyers
        guard lawyers.contains(where: { $0.id == lawyerID }) else { return false }
        state.legal.cases[index].assignedLawyerID = lawyerID
        return true
    }

    static func enterpriseTargets(caseID: String, state: LifeState) -> [LegalTargetState] {
        state.legal.cases.first(where: { $0.id == caseID })?.targets ?? []
    }

    static func availableEnterpriseActions(caseID: String, targetID: String, state: LifeState) -> [EnterpriseLegalAction] {
        guard let legalCase = state.legal.cases.first(where: { $0.id == caseID }), legalCase.origin == .enterprise,
              legalCase.isOpen,
              let target = legalCase.targets.first(where: { $0.id == targetID }),
              target.type == .specialist,
              target.status != .cooperating,
              target.lastActionAge != state.character.age,
              target.status == .questioned || target.status == .arrested || target.cooperationRisk >= 55 else { return [] }
        let hasOrganizationCounsel = !(state.career.criminalPath?.defenseTeam ?? []).isEmpty
        if hasOrganizationCounsel && state.cash >= 5_000 {
            return [.protect, .cutLoose, .provideLegalSupport]
        }
        return [.protect, .cutLoose, .threaten]
    }

    static func applyEnterpriseAction(caseID: String, targetID: String, action: EnterpriseLegalAction, state: inout LifeState) -> CriminalLegalActionOutcome? {
        guard let caseIndex = state.legal.cases.firstIndex(where: { $0.id == caseID }),
              state.legal.cases[caseIndex].origin == .enterprise,
              state.legal.cases[caseIndex].isOpen,
              let targetIndex = state.legal.cases[caseIndex].targets.firstIndex(where: { $0.id == targetID }),
              state.legal.cases[caseIndex].targets[targetIndex].type == .specialist,
              availableEnterpriseActions(caseID: caseID, targetID: targetID, state: state).contains(action) else { return nil }

        var target = state.legal.cases[caseIndex].targets[targetIndex]
        target.lastActionAge = state.character.age
        var outcome: CriminalLegalActionOutcome
        switch action {
        case .protect:
            target.status = .protected
            target.cooperationRisk = max(0, target.cooperationRisk - 15)
            outcome = CriminalLegalActionOutcome(headline: "A Specialist Was Protected", detail: "You spent money and organizational goodwill to keep the specialist from becoming a prosecution asset.", cashDelta: -2_500)
            outcome.impact.organizationMoraleDelta = 3
        case .cutLoose:
            target.status = .exposed
            target.cooperationRisk = min(100, target.cooperationRisk + 20)
            outcome = CriminalLegalActionOutcome(headline: "You Cut A Specialist Loose", detail: "The organization preserved distance, but the specialist no longer has a reason to protect it.")
            outcome.impact.organizationMoraleDelta = -10
            outcome.impact.unavailableSpecialistIDs = [String(target.id.dropFirst("specialist:".count))]
        case .threaten:
            target.status = .questioned
            target.cooperationRisk = max(0, target.cooperationRisk - 10)
            target.exposure = min(100, target.exposure + 8)
            state.legal.cases[caseIndex].investigationVisibility = min(100, state.legal.cases[caseIndex].investigationVisibility + 8)
            outcome = CriminalLegalActionOutcome(headline: "The Specialist Was Threatened", detail: "Fear bought time, but the legal system noticed the pressure around the witness.")
        case .provideLegalSupport:
            target.status = .protected
            target.cooperationRisk = max(0, target.cooperationRisk - 20)
            outcome = CriminalLegalActionOutcome(headline: "Counsel Reached The Specialist", detail: "Organization counsel reduced the immediate cooperation risk, at a steep operating cost.", cashDelta: -5_000)
            outcome.impact.organizationMoraleDelta = 2
            outcome.impact.organizationCashFlowDelta = -25
        }
        state.legal.cases[caseIndex].targets[targetIndex] = target
        state.legal.clamp()
        return outcome
    }

    static func postBail(caseID: String, state: inout LifeState) -> Int? {
        guard let index = state.legal.cases.firstIndex(where: { $0.id == caseID }),
              state.legal.cases[index].status == .pretrial,
              state.legal.cases[index].pretrialStatus == .detained else { return nil }
        let amount = state.legal.cases[index].bailAmount
        guard amount > 0, state.cash >= amount else { return nil }
        state.cash -= amount
        state.legal.cases[index].postedBailAmount = amount
        state.legal.cases[index].pretrialStatus = state.legal.cases[index].noContactRestricted ? .restricted : .released
        return amount
    }

    static func acceptDetention(caseID: String, state: inout LifeState) -> Bool {
        guard let index = state.legal.cases.firstIndex(where: { $0.id == caseID }), state.legal.cases[index].status == .pretrial else { return false }
        state.legal.cases[index].pretrialStatus = .detained
        return true
    }

    static func requestSupervisedRelease(caseID: String, state: inout LifeState) -> Bool {
        guard let index = state.legal.cases.firstIndex(where: { $0.id == caseID }),
              state.legal.cases[index].status == .pretrial,
              state.legal.cases[index].pretrialStatus == .detained,
              state.cash >= 1_500,
              !(state.legal.personalLawyers + (state.career.criminalPath?.defenseTeam ?? [])).isEmpty else { return false }
        state.cash -= 1_500
        state.legal.cases[index].pretrialStatus = .electronicMonitoring
        state.legal.cases[index].travelRestricted = true
        return true
    }

    static func resolvePretrialViolation(caseID: String, state: inout LifeState) -> Bool {
        guard let index = state.legal.cases.firstIndex(where: { $0.id == caseID }),
              state.legal.cases[index].status == .pretrial,
              state.legal.cases[index].pretrialStatus != .detained else { return false }
        state.legal.cases[index].pretrialViolationCount += 1
        state.legal.cases[index].evidenceStrength = min(100, state.legal.cases[index].evidenceStrength + 8)
        state.legal.cases[index].pretrialStatus = .detained
        state.legal.cases[index].postedBailAmount = 0
        return true
    }

    static func isCrimeRestricted(state: LifeState, requiresOrganizationContact: Bool = false) -> Bool {
        guard let legalCase = state.legal.cases.first(where: { $0.status == .pretrial }) else { return false }
        if legalCase.pretrialStatus == .detained { return true }
        if requiresOrganizationContact && legalCase.noContactRestricted { return true }
        return legalCase.travelRestricted
    }

    private static func buildTargets(for legalCase: LegalCaseState, path: CriminalPathState) -> [LegalTargetState] {
        var targets = [LegalTargetState(
            id: "player",
            type: .player,
            evidenceStrength: legalCase.evidenceStrength,
            exposure: legalCase.investigationVisibility,
            cooperationRisk: 0,
            status: .exposed,
            carryingEnterpriseEvidence: true
        )]
        guard legalCase.origin == .enterprise else { return targets }
        targets.append(LegalTargetState(
            id: "organization",
            type: .organization,
            evidenceStrength: legalCase.enterpriseEvidence,
            exposure: min(100, legalCase.investigationVisibility + path.heat / 3),
            cooperationRisk: 0,
            status: .exposed,
            carryingEnterpriseEvidence: true
        ))
        targets += path.specialists.filter(\.isAvailable).prefix(6).map { specialist in
            LegalTargetState(
                id: "specialist:\(specialist.id)",
                type: .specialist,
                evidenceStrength: min(100, legalCase.enterpriseEvidence / 2 + specialist.operationExperience.values.reduce(0, +) * 3),
                exposure: min(100, path.heat / 2 + max(0, 50 - specialist.loyalty) / 2),
                cooperationRisk: min(100, max(5, 55 - specialist.loyalty + specialist.poachingRisk / 2)),
                status: .exposed,
                carryingEnterpriseEvidence: specialist.role == .planner || specialist.role == .lieutenant
            )
        }
        if let front = path.frontBusiness {
            targets.append(LegalTargetState(
                id: "front:\(front.linkedBusinessID ?? front.name)",
                type: .frontBusiness,
                evidenceStrength: legalCase.financialTrailStrength,
                exposure: front.inspectionPressure,
                cooperationRisk: 0,
                status: .exposed,
                carryingEnterpriseEvidence: true
            ))
        }
        return Array(targets.prefix(9))
    }

    private static func resolveEnterpriseTargets(legalCase: inout LegalCaseState, path: CriminalPathState, state: inout LifeState, result: inout CriminalLegalYearOutcome) {
        guard let organizationIndex = legalCase.targets.firstIndex(where: { $0.type == .organization }) else { return }
        legalCase.targets[organizationIndex].exposure = min(100, legalCase.targets[organizationIndex].exposure + max(2, path.heat / 10 + path.notoriety / 18))
        legalCase.targets[organizationIndex].evidenceStrength = min(100, legalCase.targets[organizationIndex].evidenceStrength + max(1, path.heat / 12 + path.notoriety / 25))
        legalCase.enterpriseEvidence = max(legalCase.enterpriseEvidence, legalCase.targets[organizationIndex].evidenceStrength)

        for index in legalCase.targets.indices where legalCase.targets[index].type == .specialist {
            let specialistID = String(legalCase.targets[index].id.dropFirst("specialist:".count))
            guard let specialist = path.specialists.first(where: { $0.id == specialistID }) else { continue }
            legalCase.targets[index].exposure = min(100, legalCase.targets[index].exposure + max(1, path.heat / 16 + (specialist.isArrested ? 8 : 0)))
            legalCase.targets[index].cooperationRisk = min(100, max(0, legalCase.targets[index].cooperationRisk + (specialist.isArrested ? 10 : 0) + (specialist.loyalty < 30 ? 5 : 0)))
        }

        if let frontIndex = legalCase.targets.firstIndex(where: { $0.type == .frontBusiness }), let front = path.frontBusiness {
            legalCase.targets[frontIndex].exposure = min(100, legalCase.targets[frontIndex].exposure + max(1, front.inspectionPressure / 20))
            legalCase.targets[frontIndex].evidenceStrength = min(100, legalCase.targets[frontIndex].evidenceStrength + front.inspectionPressure / 20)
        }

        let eventRoll = state.legal.legalRandom.next(in: 1...100)
        if let frontIndex = legalCase.targets.firstIndex(where: { $0.type == .frontBusiness }), eventRoll <= 22 {
            legalCase.targets[frontIndex].status = .questioned
            legalCase.searchWarrantCount = min(20, legalCase.searchWarrantCount + 1)
            result.targetEventHeadline = "The Front Business Was Searched"
            result.bullets.append(result.targetEventHeadline!)
            result.enterpriseImpact.frontBusinessScrutinyDelta = 12
            if legalCase.targets[frontIndex].exposure >= 60 {
                result.enterpriseImpact.frontBusinessClosureYears = 2
                result.enterpriseImpact.frontBusinessRestricted = true
                result.bullets.append("The business was ordered to close temporarily")
            }
        } else if let targetIndex = legalCase.targets.firstIndex(where: { $0.type == .specialist && ($0.status == .exposed || $0.status == .questioned || $0.status == .arrested) && $0.cooperationRisk >= 45 }), eventRoll <= 70 {
            let risk = legalCase.targets[targetIndex].cooperationRisk
            if risk >= 70 && state.legal.legalRandom.next(in: 1...100) <= risk / 2 {
                legalCase.targets[targetIndex].status = .cooperating
                legalCase.targets[targetIndex].carryingEnterpriseEvidence = true
                legalCase.targets[targetIndex].evidenceStrength = min(100, legalCase.targets[targetIndex].evidenceStrength + 18)
                legalCase.enterpriseEvidence = min(100, legalCase.enterpriseEvidence + 12)
                result.targetEventHeadline = "A Specialist Began Cooperating"
                result.bullets.append(result.targetEventHeadline!)
                result.enterpriseImpact.organizationMoraleDelta = -8
                result.enterpriseImpact.organizationCashFlowDelta = -25
                result.enterpriseImpact.unavailableSpecialistIDs = [String(legalCase.targets[targetIndex].id.dropFirst("specialist:".count))]
            } else {
                legalCase.targets[targetIndex].status = .questioned
                result.targetEventHeadline = "A Specialist Was Questioned"
                result.bullets.append(result.targetEventHeadline!)
            }
        } else {
            legalCase.targets[organizationIndex].status = .questioned
            legalCase.targets[organizationIndex].evidenceStrength = min(100, legalCase.targets[organizationIndex].evidenceStrength + 6)
            result.targetEventHeadline = "The Organization Became The Target"
            result.bullets.append(result.targetEventHeadline!)
        }
    }

    private static func investigationAgency(for operation: CrimeOperationType, origin: LegalCaseOrigin) -> InvestigationAgency {
        if operation == .fraud { return .financialCrimes }
        if origin == .enterprise { return .federal }
        if origin == .gangLeader { return .taskForce }
        if operation == .murder || operation == .kidnapping { return .state }
        return .local
    }

    private static func bailAmount(for legalCase: LegalCaseState) -> Int {
        let base: Int
        switch legalCase.severity {
        case .heinous: base = 25_000
        case .violent: base = 12_000
        case .serious: base = 5_000
        case .petty: base = 1_000
        }
        return base + legalCase.sentenceYears * 750 + (legalCase.origin == .enterprise ? 7_500 : 0)
    }

    private static func resolvePretrial(legalCase: inout LegalCaseState, path: CriminalPathState, state: inout LifeState, result: inout CriminalLegalYearOutcome) {
        resolveCooperationPressure(legalCase: &legalCase, path: path, state: &state, result: &result)
        if legalCase.pretrialStatus != .detained && legalCase.travelRestricted && path.isOrganization && state.legal.legalRandom.next(in: 1...100) <= 14 {
            legalCase.pretrialViolationCount += 1
            legalCase.evidenceStrength = min(100, legalCase.evidenceStrength + 6)
            legalCase.pretrialStatus = .detained
            result.bullets.append("Pretrial restrictions were violated and detention followed")
        } else if legalCase.pretrialStatus == .detained {
            result.bullets.append("You remained detained while the case moved toward a plea")
        } else {
            result.bullets.append("Pretrial conditions remained in place")
        }
        result.consequences.append(DomainConsequence(
            source: .legal,
            target: .career,
            kind: .legalTrouble,
            magnitude: legalCase.pretrialStatus == .detained ? .major : .minor,
            openedAge: state.character.age,
            yearsRemaining: 1,
            headline: legalCase.pretrialStatus == .detained ? "Detention interrupted your working life" : "Pretrial restrictions narrowed your working life",
            detail: "The case is affecting attendance, mobility, and the amount of trust ordinary work can place in you."
        ))
        if legalCase.yearsOpen >= 2 || legalCase.evidenceStrength >= 65 {
            legalCase.status = .pleaOffered
            legalCase.pleaYears = max(2, legalCase.sentenceYears - defenseStrength(for: legalCase, path: path, legal: state.legal) / 20)
            result.bullets.append("The prosecution made a plea offer")
        }
    }

    private static func resolveCooperationPressure(legalCase: inout LegalCaseState, path: CriminalPathState, state: inout LifeState, result: inout CriminalLegalYearOutcome) {
        guard legalCase.origin == .enterprise,
              legalCase.cooperationStatus == .none,
              legalCase.status == .pretrial else { return }
        let defense = defenseStrength(for: legalCase, path: path, legal: state.legal)
        let specialist = legalCase.targets.first(where: {
            $0.type == .specialist && ($0.status == .questioned || $0.status == .arrested || $0.status == .cooperating)
        })
        let playerPressure = legalCase.evidenceStrength >= 78 || legalCase.enterpriseEvidence >= 78 || defense < 45 || legalCase.pretrialViolationCount > 0
        let roll = state.legal.legalRandom.next(in: 1...100)
        if let specialist, roll <= 18 {
            legalCase.cooperationStatus = .offerAvailable
            legalCase.cooperationTargetID = specialist.id
            legalCase.cooperationOfferAge = state.character.age
            legalCase.cooperationSentenceReduction = max(1, min(3, legalCase.sentenceYears / 5))
            result.targetEventHeadline = "A Specialist Offered Testimony"
            result.bullets.append(result.targetEventHeadline!)
        } else if playerPressure && roll <= 34 {
            legalCase.cooperationStatus = .offerAvailable
            legalCase.cooperationTargetID = legalCase.targets.first(where: { $0.type == .player })?.id ?? "player"
            legalCase.cooperationOfferAge = state.character.age
            legalCase.cooperationSentenceReduction = max(1, min(10, legalCase.sentenceYears * 30 / 100))
            result.targetEventHeadline = "Prosecutors Pressed You To Cooperate"
            result.bullets.append(result.targetEventHeadline!)
        }
    }

    private static func makeLawyer(specialty: LegalLawyerSpecialty, sequence: Int, retainer: Int) -> DefenseLawyerState {
        let base = specialty == .general ? 52 : 62
        return DefenseLawyerState(
            id: "lawyer-\(specialty.rawValue)-\(sequence)-\(retainer)",
            name: specialty == .organizedCrime ? "Mara Ellis" : specialty == .violentCrime ? "Darius Cole" : specialty == .appeals ? "Nina Shaw" : "Avery Grant",
            specialty: specialty,
            defenseSkill: base,
            trialSkill: min(95, base + (specialty == .violentCrime ? 12 : 4)),
            pleaSkill: min(95, base + (specialty == .general ? 10 : 5)),
            appealSkill: min(95, base + (specialty == .appeals ? 18 : 2)),
            relationship: 5,
            retainer: retainer
        )
    }

    private static func convict(legalCase: inout LegalCaseState, path: inout CriminalPathState, state: inout LifeState) {
        releaseBail(for: &legalCase, state: &state)
        legalCase.status = .convicted
        if legalCase.convictionIsFelony { state.legal.felonyConvictions += 1 }
        else { state.legal.misdemeanorConvictions += 1 }
        if legalCase.sentenceYears > 0 {
            PrisonSystem.sentence(level: legalCase.security, years: legalCase.sentenceYears, role: prisonRole(for: state), state: &state)
        }
        if legalCase.origin == .enterprise {
            let seizure = min(state.cash, max(500, state.cash / 4))
            state.cash -= seizure
            path.cashFlow = max(0, path.cashFlow - 75)
            path.organizationMorale = max(0, path.organizationMorale - 12)
            path.heat = min(100, path.heat + 8)
        }
        state.career.security = max(0, state.career.security - (legalCase.convictionIsFelony ? 18 : 4))
    }

    private static func releaseBail(for legalCase: inout LegalCaseState, state: inout LifeState) {
        guard legalCase.postedBailAmount > 0 else { return }
        state.cash += legalCase.postedBailAmount
        FinanceSystem.observeCash(state: &state)
        legalCase.postedBailAmount = 0
    }

    private static func prisonRole(for state: LifeState) -> PrisonGangRole {
        guard let path = state.career.criminalPath else { return .none }
        switch path.rank.authority {
        case 0: return .none
        case 1...2: return .member
        case 3...4: return .lieutenant
        default: return .leader
        }
    }

    private static func security(for severity: CrimeSeverity, origin: LegalCaseOrigin) -> PrisonSecurityLevel {
        if origin == .enterprise { return severity == .heinous ? .highMaxSecurity : .high }
        switch severity {
        case .petty: return .jail
        case .serious: return .low
        case .violent: return .medium
        case .heinous: return .high
        }
    }

    private static func defenseStrength(for legalCase: LegalCaseState, path: CriminalPathState, legal: LegalState) -> Int {
        let lawyers = path.defenseTeam + legal.personalLawyers
        guard !lawyers.isEmpty else { return 8 }
        let assigned = legalCase.assignedLawyerID.flatMap { id in lawyers.first { $0.id == id } }
        let relevant = assigned.map { [$0] } ?? lawyers
        return min(80, relevant.map { $0.defenseSkill + (legalCase.origin == .enterprise && $0.specialty == .organizedCrime ? 15 : 0) }.max() ?? 8)
    }
}
