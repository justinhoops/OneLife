import Foundation

struct LegalRandomSource {
    private(set) var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xD1B54A32D192ED03 : seed
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let width = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int((state >> 32) % width)
    }
}

struct LegalExposureFactory {
    static func crimeExposure(from state: GameState) -> LegalExposure? {
        guard state.player.age >= 18,
              state.crime.status == .active,
              !state.legal.hasActiveCase,
              !state.legal.isInCustody,
              state.legal.pendingExposures.isEmpty else { return nil }

        let exposureScore = state.crime.heat
            + state.crime.personalRisk / 2
            + state.crime.betrayalPressure / 3
        guard exposureScore >= 82 else { return nil }

        let severity: LegalOffenseSeverity
        let offense: LegalOffenseKind
        switch state.crime.resolvedTier {
        case .street:
            severity = exposureScore >= 115 ? .moderate : .minor
            offense = .streetCrime
        case .organization:
            severity = exposureScore >= 125 ? .serious : .moderate
            offense = .organizedCrime
        case .enterprise:
            severity = exposureScore >= 140 ? .aggravated : .serious
            offense = .enterpriseCrime
        }

        return LegalExposure(
            source: "crime_heat",
            offense: offense,
            severity: severity,
            evidence: (35 + exposureScore / 3).clamped(to: 0...100)
        )
    }

    static func illegalAssetExposure(from state: GameState) -> LegalExposure? {
        guard state.player.age >= 18,
              !state.legal.hasActiveCase,
              !state.legal.isInCustody,
              state.legal.pendingExposures.isEmpty else { return nil }
        let illegalCount = state.assets.firearms.filter { $0.isCurrentlyIllicit }.count
        guard illegalCount > 0, state.crime.heat >= 45 else { return nil }
        return LegalExposure(
            source: "illegal_firearm",
            offense: .illegalWeapon,
            severity: illegalCount >= 3 ? .serious : .moderate,
            evidence: min(90, 42 + illegalCount * 12 + state.crime.heat / 5),
            involvesWeapon: true,
            immediateCharge: state.crime.heat >= 75
        )
    }
}

struct LegalSystem {
    private enum CustodyIncidentKind: String {
        case safety
        case debt
        case staff
        case program
        case family
        case transfer
        case contact
        case parole
    }

    private func enterpriseProxyEligible(legal: LegalState, notoriety: Int) -> Bool {
        legal.custodyProfile.experienceTier == .enterprise
            && (legal.custodyProfile.facility == .federalPen || notoriety >= 45
                || legal.convictions.contains(where: { $0.offense == .enterpriseCrime }))
    }

    private func canApplyCustodyAction(_ choiceID: ActionChoiceID, legal: LegalState, fame: FameProfile) -> Bool {
        guard legal.isInCustody else { return false }
        let profile = legal.custodyProfile
        switch choiceID {
        case .alignWithFaction, .payProtection, .prisonWorkDetail, .studyProgram:
            return profile.lockdownYearsRemaining == 0
        case .callFamily:
            return profile.totalFamilyCallsMade < profile.lifetimeFamilyContactsMax
                && profile.familyCallsThisYear < 2
        case .delegateFromInside, .callLieutenant, .authorizeOutsideMove:
            return enterpriseProxyEligible(legal: legal, notoriety: fame.notoriety)
        case .requestParoleHearing:
            return legal.paroleEligible && profile.paroleHearingDeniedYears == 0
        default:
            return true
        }
    }

    func applyAction(
        _ choiceID: ActionChoiceID,
        legal: inout LegalState,
        finance: inout FinanceState,
        fame: inout FameProfile
    ) -> DomainYearResult {
        var result = DomainYearResult()

        if legal.isInCustody {
            guard canApplyCustodyAction(choiceID, legal: legal, fame: fame) else { return result }
        }
        if legal.isInCustody, CustodyProfile.discretionaryActionIDs.contains(choiceID) {
            guard legal.custodyProfile.spendDiscretionaryAction(for: choiceID) else {
                result.notes.append(DomainNote(title: "No Moves Left", text: "You've used the meaningful choices this sentence allows. Time passes whether you act or not.", tags: [.legal, .progress]))
                return result
            }
        }

        switch choiceID {
        case .retainCounsel:
            guard legal.hasActiveCase, legal.counselQuality == 0 else { return result }
            let cost = min(max(1_500, finance.cashOnHand / 5), 12_000)
            legal.counselQuality += finance.cashOnHand >= cost ? 24 : 10
            result.financeEffects = FinanceEffects(cashDelta: -min(cost, max(0, finance.cashOnHand)))
            result.notes.append(DomainNote(title: "Counsel Retained", text: "A lawyer took control of the case strategy.", tags: [.legal, .finance]))
        case .cooperateWithInvestigation:
            guard legal.hasActiveCase else { return result }
            legal.pendingDecision = .cooperate
            legal.evidenceStrength += 8
            legal.stage = .awaitingResolution
        case .refuseInterview:
            guard legal.hasActiveCase else { return result }
            legal.pendingDecision = .refuseInterview
            legal.evidenceStrength -= 5
            legal.stage = .awaitingResolution
        case .negotiatePlea:
            guard legal.hasActiveCase else { return result }
            legal.pendingDecision = .negotiatePlea
            legal.stage = .awaitingResolution
        case .fightCharges:
            guard legal.hasActiveCase else { return result }
            legal.pendingDecision = .fightCharges
            legal.stage = .awaitingResolution
            result.financeEffects = FinanceEffects(cashDelta: -min(4_000, max(0, finance.cashOnHand)))
        case .postBail:
            guard legal.stage == .charged, legal.bailAmount > 0, !legal.bailPosted else { return result }
            guard finance.cashOnHand >= legal.bailAmount else {
                result.notes.append(DomainNote(title: "Bail Out Of Reach", text: "The bond amount exceeded the cash you could put up.", tags: [.legal, .finance]))
                return result
            }
            legal.bailPosted = true
            result.financeEffects = FinanceEffects(cashDelta: -legal.bailAmount)
            result.notes.append(DomainNote(title: "Released Before Trial", text: "Bail kept you outside while the case waited for a strategy.", tags: [.legal, .finance]))
        case .complyWithSupervision:
            guard legal.stage == .supervision else { return result }
            legal.pendingDecision = .comply
            legal.recordPressure -= 5
        case .requestEarlyRelease:
            guard legal.stage == .supervision, legal.supervisionYearsRemaining <= 1 else { return result }
            legal.pendingDecision = .requestEarlyRelease
        case .keepHeadDown:
            guard legal.isInCustody else { return result }
            legal.custodyProfile.conductScore += 6
            legal.custodyProfile.violenceRisk = max(0, legal.custodyProfile.violenceRisk - 5)
            result.healthEffects = HealthEffects(mental: -1)
            result.notes.append(DomainNote(title: "Quiet Year", text: "You gave them nothing to write up.", tags: [.legal, .progress]))
        case .standYourGround:
            guard legal.isInCustody else { return result }
            legal.custodyProfile.yardReputation += 10
            legal.custodyProfile.violenceRisk += 12
            legal.custodyProfile.conductScore = max(0, legal.custodyProfile.conductScore - 3)
            if let faction = legal.custodyProfile.faction {
                legal.custodyProfile.factionLoyalty += faction == .oldGuard ? 5 : 4
            }
            result.notes.append(DomainNote(title: "Respect Cost", text: "The yard noticed. So did the staff.", tags: [.legal, .crime, .risk]))
        case .alignWithFaction:
            guard legal.isInCustody, legal.custodyProfile.lockdownYearsRemaining == 0 else { return result }
            if legal.custodyProfile.faction == nil {
                legal.custodyProfile.faction = legal.custodyProfile.yardReputation >= 45 ? .oldGuard : .newBlood
            }
            legal.custodyProfile.factionLoyalty += 14
            legal.custodyProfile.protectionDebt += 10
            legal.custodyProfile.violenceRisk = max(0, legal.custodyProfile.violenceRisk - 8)
            result.notes.append(DomainNote(title: "Protection Owed", text: "Someone vouched for you. The favor is logged.", tags: [.legal, .crime]))
        case .payProtection:
            guard legal.isInCustody, legal.custodyProfile.lockdownYearsRemaining == 0 else { return result }
            let cost = 400 + legal.custodyProfile.protectionDebt * 35
            result.financeEffects = FinanceEffects(cashDelta: -min(cost, max(0, finance.cashOnHand)))
            legal.custodyProfile.violenceRisk = max(0, legal.custodyProfile.violenceRisk - 10)
            legal.custodyProfile.protectionDebt += 6
            result.notes.append(DomainNote(title: "Debt Paid", text: "Safety bought on credit inside.", tags: [.legal, .finance, .crime]))
        case .refuseSnitchDeal:
            guard legal.isInCustody else { return result }
            legal.custodyProfile.snitchRisk = max(0, legal.custodyProfile.snitchRisk - 8)
            legal.custodyProfile.yardReputation += 6
            if Int.random(in: 0...100) < 22 {
                legal.custodyProfile.infractions += 1
                legal.custodyProfile.conductScore = max(0, legal.custodyProfile.conductScore - 8)
                result.notes.append(DomainNote(title: "Write-Up", text: "Guards punished the silence. The yard noticed the spine.", tags: [.legal, .crime]))
            } else {
                result.notes.append(DomainNote(title: "Name Withheld", text: "You walked back to your cell without giving them paperwork.", tags: [.legal, .crime]))
            }
        case .cooperateWithGuards:
            guard legal.isInCustody else { return result }
            legal.custodyProfile.cooperatedWithAuthorities = true
            legal.custodyProfile.snitchRisk += 18
            legal.custodyProfile.factionLoyalty = max(0, legal.custodyProfile.factionLoyalty - 12)
            legal.custodyProfile.addGoodTimeProgress(45)
            result.fameEffects = FameEffects(notoriety: 5, addKnownFor: "Informant")
            result.notes.append(DomainNote(title: "Deal Made", text: "Information traded for time. Trust inside fractured.", tags: [.legal, .crime, .risk]))
        case .prisonWorkDetail:
            guard legal.isInCustody, legal.custodyProfile.lockdownYearsRemaining == 0 else { return result }
            legal.custodyProfile.conductScore += 5
            legal.custodyProfile.addGoodTimeProgress(30)
            result.financeEffects = FinanceEffects(cashDelta: 350)
            result.notes.append(DomainNote(title: "Shift Done", text: "Boring labor bought commissary money and a cleaner file.", tags: [.legal, .finance, .progress]))
        case .studyProgram:
            guard legal.isInCustody, legal.custodyProfile.lockdownYearsRemaining == 0 else { return result }
            legal.custodyProfile.programProgress += 12
            legal.custodyProfile.conductScore += 3
            legal.custodyProfile.addGoodTimeProgress(18)
            result.healthEffects = HealthEffects(mental: -2)
            result.notes.append(DomainNote(title: "Program Progress", text: "The parole board reads paperwork too.", tags: [.legal, .education]))
        case .callFamily:
            guard legal.isInCustody,
                  legal.custodyProfile.totalFamilyCallsMade < legal.custodyProfile.lifetimeFamilyContactsMax,
                  legal.custodyProfile.familyCallsThisYear < 2 else { return result }
            legal.custodyProfile.familyCallsThisYear += 1
            legal.custodyProfile.totalFamilyCallsMade += 1
            let salvage = 4 + legal.custodyProfile.programProgress / 25
            result.relationshipEffects = RelationshipEffects(friendChange: 2, partnerChange: salvage, privateReputationChange: -2)
            result.notes.append(DomainNote(title: "Call Ended", text: "The timer ran down before the shame did — but someone on the outside still picked up.", tags: [.legal, .relationships, .family]))
        case .delegateFromInside:
            guard legal.isInCustody, enterpriseProxyEligible(legal: legal, notoriety: fame.notoriety) else { return result }
            if var empire = legal.custodyProfile.outsideEmpireSnapshot {
                empire.loyalty = min(100, empire.loyalty + 8)
                empire.betrayalPressure = max(0, empire.betrayalPressure - 4)
                legal.custodyProfile.outsideEmpireSnapshot = empire
            }
            legal.custodyProfile.snitchRisk += 6
            legal.custodyProfile.violenceRisk += 4
            result.notes.append(DomainNote(title: "Orders Delegated", text: "A lieutenant held the line — for now.", tags: [.legal, .crime, .risk]))
        case .callLieutenant:
            guard legal.isInCustody, enterpriseProxyEligible(legal: legal, notoriety: fame.notoriety) else { return result }
            if var empire = legal.custodyProfile.outsideEmpireSnapshot {
                empire.networkStrength = min(100, empire.networkStrength + 6)
                legal.custodyProfile.outsideEmpireSnapshot = empire
            }
            result.fameEffects = FameEffects(notoriety: 3)
            result.notes.append(DomainNote(title: "Lieutenant Briefed", text: "The network remembered who signs the orders — and who is watching.", tags: [.legal, .crime, .fame]))
        case .authorizeOutsideMove:
            guard legal.isInCustody, enterpriseProxyEligible(legal: legal, notoriety: fame.notoriety) else { return result }
            if var empire = legal.custodyProfile.outsideEmpireSnapshot {
                empire.heat = min(100, empire.heat + 8)
                empire.cleanMoneyRatio = min(100, empire.cleanMoneyRatio + 4)
                legal.custodyProfile.outsideEmpireSnapshot = empire
            }
            result.financeEffects = FinanceEffects(cashDelta: 2_500 + (legal.custodyProfile.outsideEmpireSnapshot?.networkStrength ?? 0) * 20)
            if Int.random(in: 0...100) < 18 {
                legal.custodyProfile.infractions += 1
                legal.custodyProfile.conductScore = max(0, legal.custodyProfile.conductScore - 6)
                result.notes.append(DomainNote(title: "Move Flagged", text: "Money moved outside — so did scrutiny inside.", tags: [.legal, .crime, .finance]))
            } else {
                result.notes.append(DomainNote(title: "Outside Move", text: "Cash landed without your face on it.", tags: [.legal, .finance, .crime]))
            }
        case .requestParoleHearing:
            guard legal.isInCustody, legal.paroleEligible, legal.custodyProfile.paroleHearingDeniedYears == 0 else { return result }
            var rng = LegalRandomSource(seed: UInt64(max(1, legal.effectiveTimeServed * 991 + legal.custodyProfile.conductScore * 17)))
            result = resolveParoleHearing(playerAge: legal.custodyStartedAge ?? 0, legal: &legal, rng: &rng, initiatedByPlayer: true)
        case .fileAppeal:
            guard legal.isInCustody else { return result }
            let cost = 6_000 + legal.sentenceYears * 500
            result.financeEffects = FinanceEffects(cashDelta: -min(cost, max(0, finance.cashOnHand)))
            var rng = LegalRandomSource(seed: UInt64(max(1, legal.sentenceYears * 443 + legal.counselQuality * 11)))
            let roll = rng.nextInt(in: 0...100)
            let successThreshold = max(8, 22 + legal.counselQuality / 4)
            if roll < successThreshold {
                legal.sentenceYears = max(legal.timeServed + 1, legal.sentenceYears - 1)
                legal.paroleEligibleAfter = max(1, legal.paroleEligibleAfter - 1)
                result.notes.append(DomainNote(title: "Appeal Granted", text: "Paperwork shaved a year off the clock.", tags: [.legal, .progress]))
            } else {
                result.notes.append(DomainNote(title: "Appeal Denied", text: "The court kept the sentence intact.", tags: [.legal, .risk]))
            }
        default:
            return result
        }

        legal.clamp()
        fame.clamp()
        return result
    }

    func apply(effect: LegalEffects, legal: inout LegalState) {
        if legal.hasActiveCase, !effect.addExposures.isEmpty {
            legal.evidenceStrength += (effect.addExposures.map(\.evidence).max() ?? 0) / 5
            legal.caseSeverity = max(legal.caseSeverity, effect.addExposures.map(\.severity).max() ?? .minor)
            for offense in effect.addExposures.map(\.offense) where !legal.allegedOffenses.contains(offense) {
                legal.allegedOffenses.append(offense)
            }
            if effect.addExposures.contains(where: { $0.jurisdiction == .military }) {
                legal.jurisdiction = .military
            }
        } else {
            legal.pendingExposures.append(contentsOf: effect.addExposures)
        }
        if let decision = effect.setDecision {
            legal.pendingDecision = decision
        }
        if let delta = effect.counselQualityDelta {
            legal.counselQuality += delta
        }
        if let delta = effect.evidenceDelta {
            legal.evidenceStrength += delta
        }
        if let delta = effect.conductDelta {
            legal.custodyProfile.conductScore += delta
        }
        if let delta = effect.violenceRiskDelta {
            legal.custodyProfile.violenceRisk += delta
        }
        if let delta = effect.yardReputationDelta {
            legal.custodyProfile.yardReputation += delta
        }
        if let delta = effect.protectionDebtDelta {
            legal.custodyProfile.protectionDebt += delta
        }
        if let delta = effect.snitchRiskDelta {
            legal.custodyProfile.snitchRisk += delta
        }
        if let delta = effect.programProgressDelta {
            legal.custodyProfile.programProgress += delta
        }
        if let delta = effect.goodTimeProgressDelta {
            legal.custodyProfile.addGoodTimeProgress(delta)
        }
        if let delta = effect.lockdownYearsDelta {
            legal.custodyProfile.lockdownYearsRemaining += delta
        }
        if let delta = effect.infractionDelta {
            legal.custodyProfile.infractions += delta
        }
        if let delta = effect.familyCallsThisYearDelta {
            legal.custodyProfile.familyCallsThisYear += delta
        }
        if let delta = effect.totalFamilyCallsDelta {
            legal.custodyProfile.totalFamilyCallsMade += delta
        }
        if let targetID = effect.targetCustodyContactID,
           let index = legal.custodyProfile.contacts.firstIndex(where: { $0.id == targetID }) {
            legal.custodyProfile.contacts[index].trust += effect.contactTrustDelta ?? 0
            legal.custodyProfile.contacts[index].danger += effect.contactDangerDelta ?? 0
            legal.custodyProfile.contacts[index].leverage += effect.contactLeverageDelta ?? 0
            legal.custodyProfile.contacts[index].influence += effect.contactInfluenceDelta ?? 0
            if let status = effect.setContactStatus {
                legal.custodyProfile.contacts[index].status = status
            }
        }
        legal.clamp()
    }

    func advanceYear(
        player: Player,
        legal: inout LegalState,
        wasInCustodyAtYearStart: Bool,
        recentStances: [YearlyStanceID] = [],
        resilience: LifeResilience = .resilient,
        family: FamilyState = FamilyState(),
        fame: FameProfile = FameProfile(),
        crimeTier: CrimeTier? = nil,
        enterprise: CriminalEnterpriseState? = nil,
        seed: UInt64? = nil
    ) -> DomainYearResult {
        var result = DomainYearResult()
        guard legal.lastProcessedAge != player.age else { return result }
        legal.lastProcessedAge = player.age

        if legal.reentryYearsRemaining > 0, !legal.isInCustody {
            legal.reentryYearsRemaining = max(0, legal.reentryYearsRemaining - 1)
        }
        if var residue = legal.prisonResidue, residue.yearsRemaining > 0, !legal.isInCustody {
            residue.yearsRemaining = max(0, residue.yearsRemaining - 1)
            legal.prisonResidue = residue.yearsRemaining > 0 ? residue : nil
        }
        if !legal.isInCustody, legal.recordPressure > 0, let floor = legal.prisonResidue?.recordPressureFloor {
            legal.recordPressure = max(floor, legal.recordPressure)
        }

        if wasInCustodyAtYearStart, legal.stage == .custody {
            return advanceCustody(
                player: player,
                legal: &legal,
                family: family,
                fame: fame,
                enterprise: enterprise,
                recentStances: recentStances,
                resilience: resilience,
                seed: seed
            )
        }

        if legal.stage == .supervision {
            result = advanceSupervision(player: player, legal: &legal, recentStances: recentStances)
            legal.clamp()
            return result
        }

        if legal.stage == .awaitingResolution {
            let fallbackSeed = UInt64(max(1, player.age * 997 + legal.evidenceStrength * 31 + legal.convictions.count * 173))
            var rng = LegalRandomSource(seed: seed ?? fallbackSeed)
            result = resolveCase(
                player: player,
                legal: &legal,
                rng: &rng,
                fame: fame,
                crimeTier: crimeTier,
                enterprise: enterprise
            )
            legal.clamp()
            return result
        }

        guard !legal.pendingExposures.isEmpty else {
            if legal.stage == .released || legal.stage == .inactive {
                legal.cleanYears += 1
                legal.recordPressure = max(0, legal.recordPressure - (legal.cleanYears >= 3 ? 7 : 3))
            }
            legal.clamp()
            return result
        }

        let exposures = legal.pendingExposures
        legal.pendingExposures = []
        legal.allegedOffenses = Array(Set(exposures.map(\.offense)))
        legal.jurisdiction = exposures.contains(where: { $0.jurisdiction == .military }) ? .military : .civilian
        legal.caseSeverity = exposures.map(\.severity).max() ?? .minor
        legal.evidenceStrength = min(100, (exposures.map(\.evidence).max() ?? 0) + max(0, exposures.count - 1) * 6)
        legal.counselQuality = 0
        legal.stage = exposures.contains(where: \.immediateCharge) ? .charged : .investigation
        legal.bailAmount = legal.stage == .charged ? bailAmount(for: exposures) : 0
        legal.bailPosted = false
        legal.pendingDecision = .none
        legal.cleanYears = 0
        legal.recordPressure = max(legal.recordPressure, 18)

        let allegation = offenseLabel(legal.allegedOffenses.first ?? .streetCrime)
        result.legalCaseSummary = LegalCaseSummary(
            id: "legal-opened-\(player.age)",
            title: legal.stage == .charged ? "Charges Filed" : "Investigation Opened",
            allegation: allegation,
            evidence: legal.evidenceStrength,
            disposition: legal.stage == .charged ? "Awaiting response" : "Under investigation",
            consequence: legal.bailAmount > 0 ? "Bail set at $\(legal.bailAmount)" : "No sentence yet",
            decisiveCauses: exposures.prefix(3).map { causeLabel(for: $0) }
        )
        result.notes.append(DomainNote(title: "Legal Pressure", text: "Authorities opened a case involving \(allegation.lowercased()).", tags: [.legal, .crime, .risk]))
        legal.clamp()
        return result
    }

    private func resolveCase(
        player: Player,
        legal: inout LegalState,
        rng: inout LegalRandomSource,
        fame: FameProfile,
        crimeTier: CrimeTier?,
        enterprise: CriminalEnterpriseState?
    ) -> DomainYearResult {
        var result = DomainYearResult()
        let severity = resolvedSeverity(for: legal)
        var convictionScore = legal.evidenceStrength + legal.convictions.count * 8
        convictionScore += severity.rawValue * 5
        convictionScore -= legal.counselQuality / 3
        if legal.pendingDecision == .cooperate { convictionScore += 5 }
        if legal.pendingDecision == .fightCharges { convictionScore -= 6 }
        if legal.pendingDecision == .refuseInterview { convictionScore -= 3 }
        let roll = rng.nextInt(in: 0...100)
        let convicted = legal.pendingDecision == .negotiatePlea || roll < convictionScore

        if !convicted {
            let disposition: LegalDisposition = legal.evidenceStrength < 42 ? .dismissed : .acquitted
            legal.lastDisposition = disposition
            legal.stage = .released
            legal.allegedOffenses = []
            legal.caseSeverity = .minor
            legal.pendingDecision = .none
            legal.evidenceStrength = 0
            legal.recordPressure = max(0, legal.recordPressure - 8)
            result.legalCaseSummary = LegalCaseSummary(
                id: "legal-cleared-\(player.age)",
                title: disposition == .dismissed ? "Case Dismissed" : "Acquitted",
                allegation: "The pending case",
                evidence: convictionScore.clamped(to: 0...100),
                disposition: disposition == .dismissed ? "Dismissed" : "Not guilty",
                consequence: "No custodial sentence",
                decisiveCauses: dismissalCauses(legal: legal, roll: roll)
            )
            result.notes.append(DomainNote(title: "Case Cleared", text: "The case ended without a conviction.", tags: [.legal, .progress]))
            legal.clamp()
            return result
        }

        let sentence = sentenceYears(for: severity, legal: legal, rng: &rng)
        let fine = fineAmount(for: severity, legal: legal)
        let seizure = severity >= .serious ? fine / 2 : 0
        let offense = legal.allegedOffenses.first ?? .streetCrime
        let resolvingDecision = legal.pendingDecision
        let disposition: LegalDisposition = legal.pendingDecision == .negotiatePlea ? .pleaAgreement : .convicted
        legal.lastDisposition = sentence == 0 ? .probation : disposition
        legal.outstandingFines += fine
        legal.seizedAssetValue += seizure
        legal.sentenceYears = sentence
        legal.timeServed = 0
        legal.paroleEligibleAfter = sentence > 0 ? max(1, Int(ceil(Double(sentence) / 2.0))) : 0
        legal.supervisionYearsRemaining = sentence == 0 ? max(1, severity.rawValue) : 0
        legal.stage = sentence > 0 ? .custody : .supervision
        legal.custodyStartedAge = sentence > 0 ? player.age : nil
        legal.recordPressure = min(100, 28 + severity.rawValue * 14 + legal.convictions.count * 7)
        if sentence > 0 {
            legal.custodyProfile = initializeCustodyProfile(
                sentenceYears: sentence,
                severity: severity,
                offense: offense,
                priorConvictionCount: legal.convictions.count,
                fame: fame,
                crimeTier: crimeTier,
                enterprise: enterprise
            )
            legal.reentryYearsRemaining = max(2, sentence / 2)
            result.crimeEffects = CrimeEffects(setStatus: .layingLow)
        }
        legal.convictions.append(
            LegalConviction(
                age: player.age,
                offense: offense,
                severity: severity,
                jurisdiction: legal.jurisdiction,
                sentenceYears: sentence,
                fine: fine
            )
        )
        legal.pendingDecision = .none
        legal.allegedOffenses = []
        legal.caseSeverity = .minor
        result.financeEffects = FinanceEffects(cashDelta: -(fine + seizure))
        result.fameEffects = FameEffects(notoriety: severity.rawValue * 4)
        if legal.bailAmount > 0, !legal.bailPosted {
            result.healthEffects = HealthEffects(physical: -1, mental: -5, stressManagement: -3)
            result.relationshipEffects = RelationshipEffects(friendChange: -2, partnerChange: -4, privateReputationChange: -2)
            result.notes.append(DomainNote(title: "Held Before Trial", text: "You waited for resolution in custody, losing time and contact before the sentence was imposed.", tags: [.legal, .health, .relationships]))
        }
        result.legalCaseSummary = LegalCaseSummary(
            id: "legal-sentenced-\(player.age)",
            title: sentence > 0 ? "Custodial Sentence" : "Convicted",
            allegation: offenseLabel(offense),
            evidence: convictionScore.clamped(to: 0...100),
            disposition: disposition == .pleaAgreement ? "Plea agreement" : "Convicted",
            consequence: sentence > 0 ? "\(sentence) year\(sentence == 1 ? "" : "s") custody and $\(fine) fine" : "\(legal.supervisionYearsRemaining) year supervision and $\(fine) fine",
            decisiveCauses: convictionCauses(severity: severity, legal: legal, decision: resolvingDecision)
        )
        result.notes.append(DomainNote(title: "Sentence Imposed", text: sentence > 0 ? "The case ended in a \(sentence)-year custodial sentence." : "The conviction resulted in community supervision.", tags: [.legal, .crime, .risk]))
        legal.clamp()
        return result
    }

    private func initializeCustodyProfile(
        sentenceYears: Int,
        severity: LegalOffenseSeverity,
        offense: LegalOffenseKind,
        priorConvictionCount: Int,
        fame: FameProfile,
        crimeTier: CrimeTier?,
        enterprise: CriminalEnterpriseState?
    ) -> CustodyProfile {
        let tier = CustodyExperienceTier.resolve(offense: offense, crimeTier: crimeTier, notoriety: fame.notoriety)
        let facility = CustodyFacility.resolve(sentenceYears: sentenceYears, severity: severity, offense: offense)
        let regime = CustodySecurityRegime.resolve(
            priorConvictionCount: priorConvictionCount,
            severity: severity,
            offense: offense
        )

        var profile = CustodyProfile(
            facility: facility,
            experienceTier: tier,
            securityRegime: regime,
            maximumGoodTimeCredits: CustodyProfile.goodTimeCap(
                for: sentenceYears,
                severity: severity,
                offense: offense
            ),
            discretionaryActionsRemaining: CustodyProfile.sentenceBudget(for: sentenceYears),
            lifetimeFamilyContactsMax: CustodyProfile.familyContactCap(for: sentenceYears)
        )

        switch tier {
        case .street:
            profile.conductScore = 45
            profile.violenceRisk = severity >= .serious ? 38 : 32
            profile.yardReputation = 22
        case .organization:
            profile.conductScore = 48
            profile.violenceRisk = 30
            profile.yardReputation = 35
            profile.protectionDebt = 12
            profile.faction = PrisonFaction.oldGuard
            profile.factionLoyalty = 20
        case .enterprise:
            profile.conductScore = 52
            profile.violenceRisk = 26
            profile.yardReputation = min(85, 40 + fame.notoriety / 2)
            profile.snitchRisk = 15
            if let enterprise {
                profile.outsideEmpireSnapshot = OutsideEmpireSnapshot(
                    loyalty: enterprise.loyalty,
                    networkStrength: enterprise.networkStrength,
                    cleanMoneyRatio: enterprise.cleanMoneyRatio,
                    heat: enterprise.heat,
                    betrayalPressure: enterprise.betrayalPressure
                )
            }
        }

        switch regime {
        case .standard:
            break
        case .heightened:
            profile.violenceRisk += 6
            profile.conductScore = max(0, profile.conductScore - 4)
        case .maximum:
            profile.violenceRisk += 12
            profile.lockdownYearsRemaining = 1
            profile.conductScore = max(0, profile.conductScore - 8)
        }

        profile.contacts = initializeCustodyContacts(
            facility: facility,
            tier: tier,
            regime: regime,
            faction: profile.faction,
            notoriety: fame.notoriety
        )
        return profile
    }

    private func initializeCustodyContacts(
        facility: CustodyFacility,
        tier: CustodyExperienceTier,
        regime: CustodySecurityRegime,
        faction: PrisonFaction?,
        notoriety: Int
    ) -> [CustodyContact] {
        var contacts: [CustodyContact] = [
            CustodyContact(
                id: "custody-cellmate",
                name: facility == .federalPen ? "Darius Cole" : "Marcus Reed",
                role: .cellmate,
                trust: tier == .street ? 30 : 42,
                danger: regime == .maximum ? 48 : 30,
                influence: 28
            ),
            CustodyContact(
                id: "custody-officer",
                name: facility == .countyJail ? "Officer Ruiz" : "Officer Bennett",
                role: .officer,
                trust: 20,
                danger: 35,
                leverage: 18,
                influence: regime == .maximum ? 70 : 55
            )
        ]

        if let faction {
            contacts.append(CustodyContact(
                id: "custody-faction",
                name: faction == .oldGuard ? "Leon Price" : "Trey Maddox",
                role: .factionRepresentative,
                status: .protective,
                trust: 38,
                danger: 58,
                leverage: 30,
                influence: 65,
                releaseRelevant: tier != .street
            ))
        } else if tier == .street {
            contacts.append(CustodyContact(
                id: "custody-rival",
                name: "Calvin Shaw",
                role: .rival,
                status: .strained,
                trust: 8,
                danger: 55,
                leverage: 12,
                influence: 35
            ))
        }

        if facility != .countyJail {
            contacts.append(CustodyContact(
                id: "custody-counselor",
                name: "Ms. Holloway",
                role: .programCounselor,
                trust: 45,
                danger: 5,
                leverage: 22,
                influence: 48,
                releaseRelevant: true
            ))
        }

        if tier == .enterprise || notoriety >= 55 {
            contacts.append(CustodyContact(
                id: "custody-ally",
                name: "Victor Hale",
                role: .ally,
                status: .protective,
                trust: 50,
                danger: 42,
                leverage: 35,
                influence: 72,
                releaseRelevant: true
            ))
        }
        return Array(contacts.prefix(5))
    }

    private func advanceCustody(
        player: Player,
        legal: inout LegalState,
        family: FamilyState,
        fame: FameProfile,
        enterprise: CriminalEnterpriseState?,
        recentStances: [YearlyStanceID],
        resilience: LifeResilience,
        seed: UInt64?
    ) -> DomainYearResult {
        var result = DomainYearResult()
        var profile = legal.custodyProfile
        profile.resetYearlyCounters()
        if profile.lockdownYearsRemaining > 0 {
            profile.lockdownYearsRemaining -= 1
        }
        if profile.paroleHearingDeniedYears > 0 {
            profile.paroleHearingDeniedYears -= 1
        }

        legal.timeServed += 1
        legal.recordPressure = max(0, legal.recordPressure - 3)

        let shape = LifeShapeResolver.resolve(recentStances: recentStances) ?? .pragmatic
        applyCustodyShapeTuning(shape: shape, resilience: resilience, profile: &profile, result: &result)

        var rng = LegalRandomSource(seed: seed ?? UInt64(max(1, player.age * 811 + profile.violenceRisk * 23 + profile.conductScore * 7)))

        result.notes.append(facilityYearNote(for: profile.facility))
        result.notes.append(lostTimeNote(player: player, legal: legal, family: family, resilience: resilience))
        applyTierYearlyEvents(profile: &profile, legal: legal, rng: &rng, result: &result)

        if profile.faction != nil, profile.protectionDebt > 25 {
            profile.factionLoyalty += 2
            if rng.nextInt(in: 0...100) < profile.protectionDebt / 2 {
                profile.protectionDebt += 4
                result.notes.append(DomainNote(title: "Faction Pressure", text: "Your crew collected on an old favor.", tags: [.legal, .crime]))
            }
        }

        if profile.experienceTier == .enterprise, profile.outsideEmpireSnapshot != nil {
            let proxyResult = EnterpriseProxySystem().advanceYear(
                profile: &profile,
                enterprise: enterprise,
                playerAge: player.age
            )
            result.notes.append(contentsOf: proxyResult.notes)
            if let cash = proxyResult.financeEffects?.cashDelta, cash != 0 {
                result.financeEffects = FinanceEffects(cashDelta: (result.financeEffects?.cashDelta ?? 0) + cash)
            }
        }

        let violenceThreshold = profile.securityRegime == .maximum ? 45 : 55
        if profile.violenceRisk >= violenceThreshold, rng.nextInt(in: 0...100) < profile.violenceRisk / 2 {
            let injury = resilience == .grounded ? 4 : 2
            result.healthEffects = HealthEffects(physical: -injury, mental: -3)
            profile.infractions += 1
            profile.conductScore = max(0, profile.conductScore - 10)
            if rng.nextInt(in: 0...100) < 35 {
                profile.lockdownYearsRemaining = max(profile.lockdownYearsRemaining, 1)
                result.notes.append(DomainNote(title: "Lockdown", text: "Violence put the block on restriction.", tags: [.legal, .health, .risk]))
            } else {
                result.notes.append(DomainNote(title: "Yard Incident", text: "A fight cost conduct and body.", tags: [.legal, .health, .crime]))
            }
        }

        if profile.cooperatedWithAuthorities || profile.snitchRisk >= 50 {
            if rng.nextInt(in: 0...100) < max(12, profile.snitchRisk / 2) {
                profile.violenceRisk += 8
                profile.yardReputation = max(0, profile.yardReputation - 6)
                result.notes.append(DomainNote(title: "Retaliation Risk", text: "Word about your cooperation moved through the block.", tags: [.legal, .crime, .risk]))
            }
        }

        for milestone in [25, 50, 75, 100] where profile.programProgress >= milestone && profile.programProgress - 12 < milestone {
            result.notes.append(DomainNote(title: "Program Milestone", text: "You hit \(milestone)% on the inside program track.", tags: [.legal, .education, .progress]))
        }

        let completed = legal.effectiveTimeServed >= legal.sentenceYears
        if completed {
            releaseFromCustody(legal: &legal, profile: &profile, completed: true, result: &result)
        } else {
            result.notes.append(DomainNote(title: "Year In Custody", text: "\(legal.yearsRemaining) year\(legal.yearsRemaining == 1 ? "" : "s") remain at \(profile.facility.displayName).", tags: [.legal, .health, .relationships]))
        }

        legal.custodyProfile = profile
        legal.clamp()
        return result
    }

    func prepareCustodyIncident(playerAge: Int, legal: inout LegalState) -> GameEvent? {
        guard legal.isInCustody else { return nil }
        var profile = legal.custodyProfile
        let event = custodyIncident(playerAge: playerAge, legal: legal, profile: &profile)
        legal.custodyProfile = profile
        legal.clamp()
        return event
    }

    private func custodyIncident(
        playerAge: Int,
        legal: LegalState,
        profile: inout CustodyProfile
    ) -> GameEvent? {
        guard profile.lastIncidentAge != playerAge else { return nil }

        var candidates: [CustodyIncidentKind] = [.safety, .staff, .contact]
        if profile.faction != nil || profile.protectionDebt > 0 { candidates.append(.debt) }
        if profile.programProgress > 0 || profile.contacts.contains(where: { $0.role == .programCounselor }) {
            candidates.append(.program)
        }
        if profile.totalFamilyCallsMade < profile.lifetimeFamilyContactsMax { candidates.append(.family) }
        if profile.securityRegime != .standard || profile.lockdownYearsRemaining > 0 { candidates.append(.transfer) }
        if legal.paroleEligible { candidates.append(.parole) }

        let recent = Set(profile.incidentHistory.suffix(2))
        let fresh = candidates.filter { !recent.contains($0.rawValue) }
        let pool = fresh.isEmpty ? candidates : fresh
        let seed = abs(playerAge * 31 + legal.timeServed * 17 + profile.conductScore * 7 + profile.violenceRisk)
        let kind = pool[seed % pool.count]
        profile.lastIncidentAge = playerAge
        profile.incidentHistory.append(kind.rawValue)

        let contact = targetedContact(for: kind, profile: profile)
        let targetID = contact?.id
        let targetName = contact?.name ?? "someone on the block"

        switch kind {
        case .safety:
            return GameEvent(
                id: "custody-safety-\(playerAge)",
                category: .general,
                tags: ["legal", "risk", "health"],
                severity: .consequential,
                title: "The Yard Tests Your Nerve",
                text: "\(targetName) turns a routine movement into a public test. Everyone nearby waits to see what you tolerate.",
                minAge: playerAge,
                maxAge: playerAge,
                weight: 1,
                cooldownYears: 0,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "De-escalate without folding",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                conductDelta: 5,
                                violenceRiskDelta: -5,
                                targetCustodyContactID: targetID,
                                contactTrustDelta: 4,
                                contactDangerDelta: -4
                            )
                        ),
                        microBeat: "You leave them no clean opening."
                    ),
                    EventChoice(
                        text: "Make the threat expensive",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                conductDelta: -7,
                                violenceRiskDelta: 12,
                                yardReputationDelta: 9,
                                infractionDelta: 1,
                                targetCustodyContactID: targetID,
                                contactDangerDelta: 8,
                                setContactStatus: .hostile
                            ),
                            health: HealthEffects(physical: -3, mental: -2)
                        ),
                        microBeat: "The room learns your price.",
                        baseFriction: .warning
                    )
                ]
            )
        case .debt:
            return GameEvent(
                id: "custody-debt-\(playerAge)",
                category: .finance,
                tags: ["legal", "crime", "money"],
                severity: .consequential,
                title: "An Old Favor Comes Due",
                text: "\(targetName) reminds you that protection inside was never charity.",
                minAge: playerAge,
                maxAge: playerAge,
                weight: 1,
                cooldownYears: 0,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Pay what you can",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                violenceRiskDelta: -5,
                                protectionDebtDelta: -12,
                                targetCustodyContactID: targetID,
                                contactTrustDelta: 5
                            ),
                            finance: FinanceEffects(cashDelta: -900)
                        ),
                        microBeat: "The ledger gets a little lighter.",
                        baseFriction: .resistance
                    ),
                    EventChoice(
                        text: "Promise another favor",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                protectionDebtDelta: 10,
                                targetCustodyContactID: targetID,
                                contactLeverageDelta: 12,
                                contactInfluenceDelta: 4
                            )
                        ),
                        microBeat: "The debt changes shape.",
                        baseFriction: .warning
                    ),
                    EventChoice(
                        text: "Refuse the collection",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                violenceRiskDelta: 14,
                                yardReputationDelta: 7,
                                protectionDebtDelta: -5,
                                targetCustodyContactID: targetID,
                                contactTrustDelta: -12,
                                setContactStatus: .hostile
                            )
                        ),
                        microBeat: "The answer travels.",
                        baseFriction: .warning
                    )
                ]
            )
        case .staff:
            return GameEvent(
                id: "custody-staff-\(playerAge)",
                category: .general,
                tags: ["legal", "risk"],
                severity: .consequential,
                title: "Staff Offer A Quiet Bargain",
                text: "\(targetName) offers easier conditions in exchange for information that will not stay private.",
                minAge: playerAge,
                maxAge: playerAge,
                weight: 1,
                cooldownYears: 0,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Give them something small",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                snitchRiskDelta: 12,
                                goodTimeProgressDelta: 30,
                                targetCustodyContactID: targetID,
                                contactLeverageDelta: 10
                            ),
                            fame: FameEffects(notoriety: 2, addKnownFor: "Cooperator")
                        ),
                        microBeat: "The door closes softly.",
                        baseFriction: .warning
                    ),
                    EventChoice(
                        text: "Say nothing",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                conductDelta: -3,
                                yardReputationDelta: 5,
                                targetCustodyContactID: targetID,
                                contactTrustDelta: -5
                            )
                        ),
                        microBeat: "Silence becomes the answer."
                    )
                ]
            )
        case .program:
            return GameEvent(
                id: "custody-program-\(playerAge)",
                category: .education,
                tags: ["legal", "education", "progress"],
                severity: .consequential,
                title: "A Program Seat Opens Up",
                text: "\(targetName) can move your name onto a limited class roster, but the work will cost energy and status.",
                minAge: playerAge,
                maxAge: playerAge,
                weight: 1,
                cooldownYears: 0,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Take the seat",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                conductDelta: 4,
                                programProgressDelta: 20,
                                goodTimeProgressDelta: 20,
                                targetCustodyContactID: targetID,
                                contactTrustDelta: 8
                            ),
                            health: HealthEffects(mental: -2)
                        ),
                        microBeat: "Your name reaches the roster."
                    ),
                    EventChoice(
                        text: "Pass it to someone else",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                yardReputationDelta: 4,
                                targetCustodyContactID: targetID,
                                contactTrustDelta: 5
                            )
                        ),
                        microBeat: "Someone remembers the gesture."
                    )
                ]
            )
        case .family:
            return GameEvent(
                id: "custody-family-\(playerAge)",
                category: .relationships,
                tags: ["legal", "family", "relationships"],
                severity: .consequential,
                title: "The Outside World Stops Waiting",
                text: "A message from home makes clear that silence is becoming its own decision.",
                minAge: playerAge,
                maxAge: playerAge,
                weight: 1,
                cooldownYears: 0,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Use a precious call",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                conductDelta: 2,
                                familyCallsThisYearDelta: 1,
                                totalFamilyCallsDelta: 1
                            ),
                            relationship: RelationshipEffects(friendChange: 2, partnerChange: 6),
                            health: HealthEffects(mental: 2)
                        ),
                        microBeat: "The timer starts immediately."
                    ),
                    EventChoice(
                        text: "Write what you cannot say",
                        effects: ChoiceEffects(
                            relationship: RelationshipEffects(partnerChange: 3, privateReputationChange: 1),
                            health: HealthEffects(mental: -1)
                        ),
                        microBeat: "The page takes the weight."
                    ),
                    EventChoice(
                        text: "Leave them alone",
                        effects: ChoiceEffects(
                            relationship: RelationshipEffects(friendChange: -2, partnerChange: -5),
                            health: HealthEffects(mental: -2)
                        ),
                        microBeat: "Nothing goes out."
                    )
                ]
            )
        case .transfer:
            return GameEvent(
                id: "custody-transfer-\(playerAge)",
                category: .general,
                tags: ["legal", "risk"],
                severity: .consequential,
                title: "A Transfer List Starts Moving",
                text: "Rumor says the next bus could reset your routine, contacts, and access to programs.",
                minAge: playerAge,
                maxAge: playerAge,
                weight: 1,
                cooldownYears: 0,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Keep your name off it",
                        effects: ChoiceEffects(legal: LegalEffects(conductDelta: 5, lockdownYearsDelta: -1)),
                        microBeat: "You become administratively boring."
                    ),
                    EventChoice(
                        text: "Ask for the move",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                violenceRiskDelta: -8,
                                yardReputationDelta: -5,
                                programProgressDelta: -8
                            )
                        ),
                        microBeat: "A new block means starting over.",
                        baseFriction: .resistance
                    )
                ]
            )
        case .contact:
            return GameEvent(
                id: "custody-contact-\(playerAge)",
                category: .social,
                tags: ["legal", "social", "risk"],
                severity: .consequential,
                title: "Trust Breaks Inside The Block",
                text: "\(targetName) is caught telling two versions of the same story.",
                minAge: playerAge,
                maxAge: playerAge,
                weight: 1,
                cooldownYears: 0,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Confront them privately",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                targetCustodyContactID: targetID,
                                contactTrustDelta: -3,
                                contactDangerDelta: -4,
                                contactLeverageDelta: 7
                            )
                        ),
                        microBeat: "The truth gets smaller in private."
                    ),
                    EventChoice(
                        text: "Cut them loose",
                        effects: ChoiceEffects(
                            legal: LegalEffects(
                                violenceRiskDelta: 4,
                                targetCustodyContactID: targetID,
                                contactTrustDelta: -20,
                                setContactStatus: .strained
                            )
                        ),
                        microBeat: "Distance becomes policy."
                    )
                ]
            )
        case .parole:
            return GameEvent(
                id: "custody-parole-ready-\(playerAge)",
                category: .general,
                tags: ["legal", "progress", "family"],
                severity: .consequential,
                title: "Your Parole Window Finally Opens",
                text: "The board can now hear your case. Your conduct, programs, and record will all enter the room first.",
                minAge: playerAge,
                maxAge: playerAge,
                weight: 1,
                cooldownYears: 0,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Prepare the strongest file",
                        effects: ChoiceEffects(
                            legal: LegalEffects(conductDelta: 4, programProgressDelta: 8)
                        ),
                        microBeat: "Every page gets reviewed."
                    ),
                    EventChoice(
                        text: "Wait another year",
                        effects: ChoiceEffects(
                            legal: LegalEffects(conductDelta: 2, goodTimeProgressDelta: 10)
                        ),
                        microBeat: "Patience becomes strategy."
                    )
                ]
            )
        }
    }

    private func targetedContact(
        for kind: CustodyIncidentKind,
        profile: CustodyProfile
    ) -> CustodyContact? {
        let preferredRole: CustodyContactRole
        switch kind {
        case .debt: preferredRole = .factionRepresentative
        case .staff: preferredRole = .officer
        case .program: preferredRole = .programCounselor
        case .safety: preferredRole = .rival
        default: preferredRole = .cellmate
        }
        return profile.contacts.first(where: { $0.role == preferredRole })
            ?? profile.contacts.first(where: { $0.status == .active || $0.status == .strained })
    }

    private func resolveParoleHearing(
        playerAge: Int,
        legal: inout LegalState,
        rng: inout LegalRandomSource,
        initiatedByPlayer: Bool
    ) -> DomainYearResult {
        var result = DomainYearResult()
        var profile = legal.custodyProfile
        var conductThreshold = 55
        if profile.cooperatedWithAuthorities { conductThreshold -= 8 }
        if profile.snitchRisk >= 55 { conductThreshold += 6 }
        if profile.programProgress >= 75 { conductThreshold -= 6 }
        if profile.programProgress >= 50 { conductThreshold -= 3 }

        var paroleScore = profile.conductScore + profile.programProgress / 3
        paroleScore += profile.cooperatedWithAuthorities ? 8 : 0
        paroleScore -= profile.snitchRisk / 4
        paroleScore -= profile.infractions * 4
        paroleScore -= max(0, legal.recordPressure - 50) / 2
        if profile.faction != nil, profile.factionLoyalty < 30, profile.protectionDebt > 40 {
            paroleScore -= 12
        }

        let roll = rng.nextInt(in: 0...100)
        let granted = profile.conductScore >= conductThreshold && roll < paroleScore

        if granted {
            releaseFromCustody(legal: &legal, profile: &profile, completed: false, result: &result)
            result.legalCaseSummary = LegalCaseSummary(
                id: "legal-parole-\(playerAge)",
                title: "Parole Granted",
                allegation: "Custodial sentence",
                evidence: paroleScore.clamped(to: 0...100),
                disposition: "Released to supervision",
                consequence: "\(legal.supervisionYearsRemaining) year supervision",
                decisiveCauses: paroleCauses(profile: profile, cooperated: profile.cooperatedWithAuthorities)
            )
        } else {
            profile.paroleHearingDeniedYears = rng.nextInt(in: 1...2)
            profile.conductScore = max(0, profile.conductScore - 6)
            legal.custodyProfile = profile
            result.notes.append(DomainNote(
                title: "Parole Denied",
                text: initiatedByPlayer ? "The board said not yet. Conduct and programs need more weight." : "The hearing went badly.",
                tags: [.legal, .risk]
            ))
        }

        legal.clamp()
        return result
    }

    private func releaseFromCustody(
        legal: inout LegalState,
        profile: inout CustodyProfile,
        completed: Bool,
        result: inout DomainYearResult
    ) {
        legal.stage = completed ? .released : .supervision
        legal.lastDisposition = completed ? .released : .paroled
        legal.supervisionYearsRemaining = completed ? 0 : max(1, legal.yearsRemaining)
        legal.cleanYears = 0
        legal.reentryYearsRemaining = max(2, legal.sentenceYears / 2)
        if profile.programProgress >= 100 {
            legal.reentryYearsRemaining = max(1, legal.reentryYearsRemaining - 2)
        }
        if profile.cooperatedWithAuthorities {
            legal.recordPressure = min(100, legal.recordPressure + 6)
        }

        var residueTags: [String] = []
        if profile.yardReputation >= 60 || profile.experienceTier == .enterprise {
            residueTags.append("hardened")
        }
        if profile.programProgress >= 75 && profile.conductScore >= 65 {
            residueTags.append("straightPath")
        } else if profile.infractions >= 3 {
            residueTags.append("institutionalized")
        }
        if profile.snitchRisk >= 50 || profile.cooperatedWithAuthorities {
            residueTags.append("paranoid")
        }
        if profile.contacts.contains(where: { $0.status == .hostile && $0.danger >= 55 }) {
            residueTags.append("unfinishedInsideConflict")
        }
        let releaseContact = profile.contacts
            .filter { $0.releaseRelevant && $0.status != .hostile && $0.trust >= 45 }
            .max(by: { $0.influence < $1.influence })
            .map {
                AmbientContact(
                    id: "custody-release-\($0.id)",
                    name: $0.name,
                    role: $0.role == .programCounselor ? .mentor : .friend,
                    bond: $0.trust,
                    reliability: max(20, 100 - $0.danger),
                    cadence: .quiet,
                    memoryFlags: ["met_in_custody", $0.role.rawValue]
                )
            }
        if releaseContact != nil {
            residueTags.append("insideContactOutside")
        }
        let pressureFloor = min(60, 12 + legal.convictions.count * 8 + (profile.experienceTier == .enterprise ? 10 : 0))
        legal.prisonResidue = PrisonResidue(
            tags: residueTags,
            yearsRemaining: max(3, legal.sentenceYears / 2),
            experienceTier: profile.experienceTier,
            recordPressureFloor: pressureFloor,
            outsideContact: releaseContact
        )
        legal.recordPressure = max(legal.recordPressure, pressureFloor)

        if profile.experienceTier == .enterprise, profile.yardReputation >= 55 {
            result.fameEffects = FameEffects(notoriety: 4, addKnownFor: "Prison Legend")
        }

        if completed && profile.conductScore >= 70 {
            result.notes.append(DomainNote(title: "Earned Release", text: "You walked out with conduct that survived the full bid.", tags: [.legal, .progress]))
        }
        result.legalCaseSummary = LegalCaseSummary(
            id: "legal-release-\(legal.custodyStartedAge ?? 0)",
            title: completed ? "Released" : "Parole Granted",
            allegation: "Custodial sentence",
            evidence: profile.conductScore,
            disposition: completed ? "Sentence complete" : "Released to supervision",
            consequence: legal.supervisionYearsRemaining > 0 ? "\(legal.supervisionYearsRemaining) year supervision" : "Record pressure begins fading",
            decisiveCauses: completed
                ? ["The full sentence was served", "The conviction remains on record"]
                : paroleCauses(profile: profile, cooperated: profile.cooperatedWithAuthorities)
        )
        result.notes.append(DomainNote(title: "Release", text: "You left custody, but the conviction still follows you.", tags: [.legal, .progress]))
        if profile.programProgress >= 100 {
            result.careerEffects = CareerEffects(jobSecurity: 6)
            result.notes.append(DomainNote(title: "Program Bridge", text: "The cert you earned inside opens retraining doors.", tags: [.legal, .career, .education]))
        }
        if profile.yardReputation >= 55 || profile.experienceTier == .enterprise {
            result.crimeEffects = CrimeEffects(notoriety: 6, loyalty: 8)
        } else if profile.experienceTier == .street {
            result.crimeEffects = CrimeEffects(loyalty: -5, territoryPressure: -12)
        }
        legal.custodyProfile = profile
    }

    private func advanceSupervision(
        player: Player,
        legal: inout LegalState,
        recentStances: [YearlyStanceID] = []
    ) -> DomainYearResult {
        var result = DomainYearResult()
        legal.supervisionYearsRemaining = max(0, legal.supervisionYearsRemaining - 1)
        legal.cleanYears += 1
        let shape = LifeShapeResolver.resolve(recentStances: recentStances) ?? .pragmatic
        var decay = legal.pendingDecision == .comply ? 10 : 6
        if shape == .looseEdges { decay = max(2, decay - 4) }
        if shape == .carefulShape { decay += 2 }
        legal.recordPressure = max(legal.prisonResidue?.recordPressureFloor ?? 0, legal.recordPressure - decay)
        if legal.supervisionYearsRemaining == 0 || legal.pendingDecision == .requestEarlyRelease {
            legal.stage = .released
            legal.lastDisposition = .released
            legal.pendingDecision = .none
            result.legalCaseSummary = LegalCaseSummary(
                id: "legal-supervision-complete-\(player.age)",
                title: "Supervision Complete",
                allegation: "Post-conviction supervision",
                evidence: 0,
                disposition: "Released",
                consequence: "Record pressure will fade over clean years",
                decisiveCauses: ["Supervision terms were completed", "No new exposure was added"]
            )
        }
        legal.clamp()
        return result
    }

    private func applyCustodyShapeTuning(
        shape: LifeShape,
        resilience: LifeResilience,
        profile: inout CustodyProfile,
        result: inout DomainYearResult
    ) {
        switch shape {
        case .drivenCurrent:
            profile.yardReputation += 3
            profile.violenceRisk += 4
            profile.conductScore = max(0, profile.conductScore - 2)
        case .carefulShape:
            profile.conductScore += 4
            profile.addGoodTimeProgress(resilience == .grounded ? 8 : 16)
        case .looseEdges:
            profile.infractions += Int.random(in: 0...1)
            profile.programProgress = max(0, profile.programProgress - 4)
            profile.conductScore = max(0, profile.conductScore - 5)
            result.notes.append(DomainNote(title: "Slipped", text: "Loose habits cost program time and conduct.", tags: [.legal, .health]))
        case .pragmatic:
            profile.conductScore += 1
        }
    }

    private func lostTimeNote(player: Player, legal: LegalState, family: FamilyState, resilience: LifeResilience) -> DomainNote {
        let childAges = family.children.map { "\($0.name) (\($0.age))" }.joined(separator: ", ")
        let childLine = childAges.isEmpty ? "Life outside kept moving." : "While you were inside: \(childAges)."
        let mentalLine = resilience == .grounded ? " The silence hit harder than the sentence." : ""
        let careerLine = legal.timeServed >= 2 ? " Careers advanced without you." : ""
        return DomainNote(
            title: "Lost Time",
            text: "Age \(player.age). \(legal.yearsRemaining) year\(legal.yearsRemaining == 1 ? "" : "s") left. \(childLine)\(careerLine)\(mentalLine)",
            tags: [.legal, .family, .progress]
        )
    }

    private func applyTierYearlyEvents(
        profile: inout CustodyProfile,
        legal: LegalState,
        rng: inout LegalRandomSource,
        result: inout DomainYearResult
    ) {
        switch profile.experienceTier {
        case .street:
            if rng.nextInt(in: 0...100) < 28 {
                profile.infractions += 1
                profile.conductScore = max(0, profile.conductScore - 5)
                result.notes.append(DomainNote(title: "Exploitation", text: "Someone took advantage because you had nowhere to go.", tags: [.legal, .health, .risk]))
            }
        case .organization:
            if profile.protectionDebt > 20, rng.nextInt(in: 0...100) < 30 {
                profile.protectionDebt += 6
                result.notes.append(DomainNote(title: "Debt Called", text: "The crew collected inside what you owed outside.", tags: [.legal, .crime]))
            }
            if rng.nextInt(in: 0...100) < 18 {
                result.notes.append(DomainNote(title: "Crew Rumor", text: "Word reached the block that leadership shifted while you were gone.", tags: [.legal, .crime, .relationships]))
            }
        case .enterprise:
            if rng.nextInt(in: 0...100) < 24 {
                profile.snitchRisk += 4
                result.notes.append(DomainNote(title: "Federal Pressure", text: "Investigators tightened the net — even from outside the walls.", tags: [.legal, .crime, .risk]))
            }
            if var empire = profile.outsideEmpireSnapshot, rng.nextInt(in: 0...100) < 20 {
                empire.betrayalPressure = min(100, empire.betrayalPressure + 8)
                profile.outsideEmpireSnapshot = empire
                result.notes.append(DomainNote(title: "Betrayal Test", text: "Someone tested whether the empire still feared your name.", tags: [.legal, .crime]))
            }
        }

        if profile.securityRegime == .maximum, rng.nextInt(in: 0...100) < 22 {
            profile.lockdownYearsRemaining = max(profile.lockdownYearsRemaining, 1)
            result.notes.append(DomainNote(title: "Maximum Security", text: "Repeat history bought you a harder cell and fewer options.", tags: [.legal, .risk]))
        }
    }

    private func facilityYearNote(for facility: CustodyFacility) -> DomainNote {
        switch facility {
        case .countyJail:
            return DomainNote(title: "County Grind", text: "Overcrowding and short bids — every month feels like a year.", tags: [.legal, .health])
        case .statePrison:
            return DomainNote(title: "State Yard", text: "Faction lines and routine violence shape the calendar.", tags: [.legal, .crime])
        case .federalPen:
            return DomainNote(title: "Federal Isolation", text: "Long bids, distant family, and a yard that runs on old rules.", tags: [.legal, .relationships])
        }
    }

    private func paroleCauses(profile: CustodyProfile, cooperated: Bool) -> [String] {
        var causes = ["Conduct stayed above the board threshold"]
        if profile.programProgress >= 50 { causes.append("Program progress strengthened the file") }
        if cooperated { causes.append("Cooperation lowered the time bar") }
        if profile.infractions == 0 { causes.append("No major infractions on record") }
        return Array(causes.prefix(3))
    }

    private func resolvedSeverity(for legal: LegalState) -> LegalOffenseSeverity {
        legal.caseSeverity
    }

    private func sentenceYears(
        for severity: LegalOffenseSeverity,
        legal: LegalState,
        rng: inout LegalRandomSource
    ) -> Int {
        let range: ClosedRange<Int>
        if legal.jurisdiction == .military {
            range = 0...5
        } else {
            switch severity {
            case .minor: range = 0...1
            case .moderate: range = 1...3
            case .serious: range = 3...8
            case .aggravated: range = 6...15
            }
        }
        var years = rng.nextInt(in: range)
        if legal.pendingDecision == .negotiatePlea || legal.pendingDecision == .cooperate {
            years = max(range.lowerBound, years - 2)
        }
        if legal.convictions.count > 0 {
            years = min(range.upperBound, years + min(3, legal.convictions.count))
        }
        if legal.counselQuality >= 45 {
            years = max(range.lowerBound, years - 1)
        }
        return years
    }

    private func fineAmount(for severity: LegalOffenseSeverity, legal: LegalState) -> Int {
        let base = [0, 1_000, 4_000, 12_000, 30_000][severity.rawValue]
        return legal.pendingDecision == .negotiatePlea ? base * 3 / 4 : base
    }

    private func bailAmount(for exposures: [LegalExposure]) -> Int {
        let severity = exposures.map(\.severity).max() ?? .minor
        return severity.rawValue * 2_500 + (exposures.contains(where: \.involvesWeapon) ? 3_500 : 0)
    }

    private func offenseLabel(_ offense: LegalOffenseKind) -> String {
        switch offense {
        case .streetCrime: return "Street offense"
        case .organizedCrime: return "Organized criminal activity"
        case .enterpriseCrime: return "Criminal enterprise"
        case .illegalWeapon: return "Illegal weapon possession"
        case .militaryDesertion: return "Military desertion"
        }
    }

    private func causeLabel(for exposure: LegalExposure) -> String {
        if exposure.involvesWeapon { return "An illegal weapon increased the stakes" }
        switch exposure.severity {
        case .minor: return "Visible activity created a paper trail"
        case .moderate: return "Heat and evidence crossed the charging threshold"
        case .serious: return "Organization scale increased scrutiny"
        case .aggravated: return "Enterprise scale made the case a priority"
        }
    }

    private func dismissalCauses(legal: LegalState, roll: Int) -> [String] {
        var causes = ["The evidence did not clear the legal threshold"]
        if legal.counselQuality >= 35 { causes.append("Counsel weakened the case") }
        if roll >= 70 { causes.append("The contested facts broke in your favor") }
        return Array(causes.prefix(3))
    }

    private func convictionCauses(severity: LegalOffenseSeverity, legal: LegalState, decision: LegalDecision) -> [String] {
        var causes = ["Evidence strength held through resolution"]
        if severity >= .serious { causes.append("The scale of the conduct increased the sentence") }
        if legal.convictions.count > 1 { causes.append("Prior convictions increased the penalty") }
        if decision == .negotiatePlea { causes.append("The plea reduced uncertainty and exposure") }
        if legal.counselQuality >= 35 { causes.append("Counsel limited some of the damage") }
        return Array(causes.prefix(3))
    }
}

struct CustodyFinanceSystem {
    func advanceYear(career: inout CareerState, finance: inout FinanceState) -> DomainYearResult {
        career.status = .unemployed
        career.annualIncome = 0
        finance.annualGrossIncome = 0
        finance.annualNetIncome = 0
        finance.annualLivingCost = min(finance.annualLivingCost, 1_200)
        finance.annualDiscretionaryCost = 0
        return DomainYearResult(
            notes: [DomainNote(title: "Custody Finances", text: "Earned income stopped and basic outside costs fell, but legal obligations remained.", tags: [.legal, .finance])],
            financeEffects: FinanceEffects(
                cashDelta: -750,
                financialStressDelta: 8
            )
        )
    }
}

struct CustodyHealthSystem {
    func advanceYear(resilience: LifeResilience = .resilient) -> DomainYearResult {
        let mental = resilience == .grounded ? -7 : -5
        return DomainYearResult(healthEffects: HealthEffects(physical: -2, mental: mental, stressManagement: -4))
    }
}

struct CustodyRelationshipSystem {
    func advanceYear() -> DomainYearResult {
        DomainYearResult(
            relationshipEffects: RelationshipEffects(friendChange: -5, partnerChange: -7, privateReputationChange: -4)
        )
    }
}

struct CustodyFamilySpilloverSystem {
    func advanceYear(
        legal: LegalState,
        relationships: inout RelationshipState,
        family: inout FamilyState,
        resilience: LifeResilience
    ) -> DomainYearResult {
        var result = DomainYearResult()
        let profile = legal.custodyProfile
        let facilityMultiplier = profile.facility == .federalPen ? 1.35 : (profile.facility == .statePrison ? 1.15 : 1.0)
        let salvage = min(6, profile.totalFamilyCallsMade * 2 + profile.programProgress / 20)
        let partnerDrain = Int(Double(7 + legal.timeServed / 2) * facilityMultiplier) - salvage / 2

        if let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
            var partner = relationships.romanticPartners[index]
            partner.bond = max(0, partner.bond - partnerDrain)
            if partner.bond < 45 { partner.status = .strained }
            if legal.timeServed >= 3, partner.bond < 30, Int.random(in: 0...100) < 22 - salvage {
                partner.status = .strained
                result.notes.append(DomainNote(title: "Partner Strain", text: "Distance became the default setting.", tags: [.legal, .relationships]))
            }
            if legal.timeServed >= 4, partner.bond < 18, profile.totalFamilyCallsMade < 2, Int.random(in: 0...100) < 16 {
                partner.status = .strained
                partner.bond = max(0, partner.bond - 8)
                result.notes.append(DomainNote(title: "Separation Pressure", text: "They started building a life that didn't wait for collect calls.", tags: [.legal, .relationships, .family]))
            }
            if profile.totalFamilyCallsMade >= 3, profile.programProgress >= 40, partner.bond < 50 {
                partner.bond = min(95, partner.bond + 3)
            }
            relationships.romanticPartners[index] = partner
        }

        let childPenalty = resilience == .grounded ? 4 : 2
        for index in family.children.indices {
            var child = family.children[index]
            let milestone = [5, 13, 18].contains(child.age)
            let drift = (milestone ? 6 : 3) + childPenalty - salvage / 3
            child.bondWithPlayer = max(5, child.bondWithPlayer - drift)
            child.supportLoad = min(85, child.supportLoad + (resilience == .grounded ? 4 : 2))
            if milestone, profile.totalFamilyCallsMade == 0 {
                let note = "\(child.name) marked age \(child.age) with a parent behind glass and letters."
                if !child.developmentNotes.contains(note) {
                    child.developmentNotes.append(note)
                }
            }
            if child.age >= 10, legal.timeServed >= 2, Int.random(in: 0...100) < 24 {
                let note = "\(child.name) learned early that some years just disappear."
                if !child.developmentNotes.contains(note) {
                    child.developmentNotes.append(note)
                }
            }
            if child.developmentNotes.count > 5 { child.developmentNotes.removeFirst() }
            family.children[index] = child
        }

        return result
    }
}

struct EnterpriseProxySystem {
    func advanceYear(
        profile: inout CustodyProfile,
        enterprise: CriminalEnterpriseState?,
        playerAge: Int
    ) -> DomainYearResult {
        var result = DomainYearResult()
        guard var snapshot = profile.outsideEmpireSnapshot else { return result }

        snapshot.loyalty = max(0, snapshot.loyalty - 5)
        snapshot.networkStrength = max(0, snapshot.networkStrength - 3)
        snapshot.heat = min(100, snapshot.heat + 4)
        snapshot.betrayalPressure = min(100, snapshot.betrayalPressure + 3)

        if snapshot.loyalty < 35, Int.random(in: 0...100) < 20 {
            snapshot.loyalty = max(0, snapshot.loyalty - 10)
            result.notes.append(DomainNote(title: "Coup Rumor", text: "Someone inside your organization started counting votes.", tags: [.legal, .crime, .risk]))
        }
        if snapshot.networkStrength >= 50, Int.random(in: 0...100) < 18 {
            let cash = 1_500 + snapshot.networkStrength * 25
            result.financeEffects = FinanceEffects(cashDelta: cash)
            snapshot.heat = min(100, snapshot.heat + 6)
            result.notes.append(DomainNote(title: "Outside Revenue", text: "Money still moved through your name — and so did the heat.", tags: [.legal, .finance, .crime]))
        }
        if enterprise != nil, snapshot.betrayalPressure >= 55 {
            result.notes.append(DomainNote(title: "Lieutenant Test", text: "The machine kept running, but loyalty was being priced daily.", tags: [.legal, .crime]))
        }

        profile.outsideEmpireSnapshot = snapshot
        return result
    }
}
