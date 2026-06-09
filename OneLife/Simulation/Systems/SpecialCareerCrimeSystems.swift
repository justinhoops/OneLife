import Foundation

/// Burnout never fully resets — at most 60% recovery per relief action/year.
private func cappedBurnoutRecovery(current: Int, relief: Int) -> Int {
    guard current > 0, relief > 0 else { return current }
    let maxRelief = max(1, Int((Double(current) * 0.6).rounded()))
    return max(0, current - min(relief, maxRelief))
}

/// High notoriety makes heat linger — relief is discounted.
private func cappedHeatReduction(current: Int, relief: Int, notoriety: Int) -> Int {
    guard current > 0, relief > 0 else { return current }
    let discount = notoriety >= 70 ? 0.35 : (notoriety >= 50 ? 0.55 : 1.0)
    let effectiveRelief = max(0, Int((Double(relief) * discount).rounded()))
    return max(0, current - effectiveRelief)
}

struct SpecialCareerSystem {
    static func qualificationIssue(for choiceID: ActionChoiceID, state: GameState) -> String? {
        let dossier = state.childhoodDossier
        let entApt = dossier?.aptitudes.entrepreneurial ?? 45
        let physApt = dossier?.aptitudes.physical ?? 45
        let socApt = dossier?.aptitudes.social ?? 45
        let techApt = dossier?.aptitudes.technical ?? 45
        let analApt = dossier?.aptitudes.analytical ?? 45
        let creaApt = dossier?.aptitudes.creative ?? 45

        // D3: education pathway bias (honors = prestige doors for politics/creator/founder; trade/voc = practical entry for trades/crime/athlete physical; standard balanced)
        let eduTrack = state.education.academicTrack
        let eduCred = state.education.credentialStrength

        switch choiceID {
        case .startBoxingCareer, .startMMACareer:
            if state.player.age < 18 { return "must be 18" }
            let entryPhysical = dossier?.aptitudes.physical ?? state.player.health
            if state.player.health < 45 || entryPhysical < 50 { return "physical readiness" }
            return nil
        case .startFightEmpire:
            return CombatCareerSystem.qualifiesForFightEmpire(state: state) ? nil : "retired champion, major record, or elite brand plus $40,000"
        case .startCompany:
            if state.finance.cashOnHand < 5_000 { return "$5,000 cash" }
            let bridge = [
                state.career.experience(for: .management),
                state.career.experience(for: .sales),
                state.career.experience(for: .technical),
                state.career.experience(for: .creative)
            ].max() ?? 0
            // Dossier help: high entrepreneurial or social aptitude can substitute for "career proof"
            let aptitudeCredit = max(entApt, socApt) / 12
            if bridge + aptitudeCredit < 1 && state.career.annualIncome < 35_000 && state.finance.cashOnHand < 10_000 {
                return "career proof"
            }
            // D3: honors track or high credential from edu gives founder entry credit (prestige wiring)
            if eduTrack == .honors || eduCred >= 78 {
                // honors/strong cred acts as extra proof for capital raises
            }
            return nil
        case .manageFund:
            // Diamond gate for Venture Capitalist (Criminal Enterprise) - high capital + peak founder/creator + ent/anal dossier
            if state.finance.cashOnHand < 75_000 { return "$75k+ capital (Diamond VC entry)" }
            let founderPeak = state.specialCareer.track == .founder && state.specialCareer.founder.personalLegend >= 40
            let creatorPeak = state.specialCareer.track == .contentCreator && state.specialCareer.creator.personalBrand >= 40
            let exp = max(state.career.experience(for: .management), state.career.experience(for: .sales), state.career.experience(for: .technical))
            let aptitudeCredit = max(entApt, analApt) / 8
            if !founderPeak && !creatorPeak && (exp + aptitudeCredit < 5) {
                return "peak founder/creator Special or strong deal experience + entrepreneurial/analytical dossier"
            }
            return nil
        case .acquireCompetitor:
            // Diamond gate for Corporate Raider - capital + peak founder or high management + ent/tech dossier
            if state.finance.cashOnHand < 40_000 { return "$40k+ capital (Diamond raider entry)" }
            let founderPeak = state.specialCareer.track == .founder && state.specialCareer.founder.personalLegend >= 35
            let exp = state.career.experience(for: .management)
            let aptitudeCredit = max(entApt, techApt) / 10
            if !founderPeak && (exp + aptitudeCredit < 4) {
                return "peak founder Special or strong management experience + entrepreneurial/technical dossier"
            }
            return nil
        case .gatherIntelligence, .exploitLeverage:
            // Diamond gate for Shadow Operative - professional access + peak special or high perf + tech/anal/social dossier
            if state.finance.cashOnHand < 30_000 { return "$30k+ for ops (Diamond shadow entry)" }
            if state.career.status != .fullTime || state.career.profile != .credentialedProfessional { return "professional access" }
            let founderOrCreatorPeak = (state.specialCareer.track == .founder && state.specialCareer.founder.personalLegend >= 30) || (state.specialCareer.track == .contentCreator && state.specialCareer.creator.personalBrand >= 35)
            let exp = max(state.career.experience(for: .technical), state.career.experience(for: .admin))
            let aptitudeCredit = max(techApt, analApt, socApt) / 10
            if !founderOrCreatorPeak && (exp + aptitudeCredit < 4) {
                return "peak founder/creator Special or strong access experience + technical/analytical/social dossier"
            }
            if state.career.performance < 70 { return "elite trusted performance" }
            return nil
        case .dayTrade:
            // Diamond gate for Gray Market Trader (Criminal Enterprise) - capital + peak founder/creator or high market exp + ent/anal dossier
            if state.finance.cashOnHand < 35_000 { return "$35k+ stake capital (Diamond trader entry)" }
            let founderOrCreatorPeak = (state.specialCareer.track == .founder && state.specialCareer.founder.personalLegend >= 30) || (state.specialCareer.track == .contentCreator && state.specialCareer.creator.personalBrand >= 35)
            let marketExp = state.career.experience(for: .sales) + state.career.experience(for: .technical) + max(entApt, analApt) / 10
            if !founderOrCreatorPeak && marketExp < 4 {
                return "peak founder/creator Special or strong market experience + entrepreneurial/analytical dossier"
            }
            return nil
        case .chaseSpotlight:
            // D3: honors track or high cred gives creator/politics spotlight entry easier (prestige wiring)
            if eduTrack == .honors || eduCred >= 72 {
                // strong academic brand lowers the "prove it" bar for attention paths
            }
            return nil
        case .startMovieActor:
            if state.finance.cashOnHand < 1_200 { return "$1,200 cash" }
            let actingCred = state.career.experience(for: .creative) + max(creaApt, socApt) / 16
            let publicCred = max(state.specialCareer.fame, state.specialCareer.audience) / 18
            if actingCred + publicCred < 4 {
                return "acting credibility"
            }
            return nil
        case .startMusicProducer:
            if state.finance.cashOnHand < 2_000 { return "$2,000 cash" }
            let entertainmentCred = state.specialCareer.track == .entertainment && (state.specialCareer.fame >= 20 || state.specialCareer.audience >= 25)
            let producerCred = state.career.experience(for: .creative) + max(creaApt, analApt, socApt) / 16
            if !entertainmentCred && producerCred < 4 {
                return "music production credibility"
            }
            return nil
        case .startMovieProducer:
            // CT1-1: Strengthened Diamond gate — requires significant capital + peak Special (creator/entertainment/actor success) + dossier fit (creative/entrepreneurial/social)
            if state.finance.cashOnHand < 25_000 { return "$25,000+ cash (Diamond capital requirement)" }
            let actorPeak = state.specialCareer.track == .movieActor && (state.specialCareer.fame >= 45 || state.specialCareer.movieActor.roleCredits >= 6 || state.specialCareer.movieActor.boxOfficeDraw >= 50)
            let creatorPeak = state.specialCareer.track == .contentCreator && (state.specialCareer.fame >= 50 || state.specialCareer.audience >= 55 || state.specialCareer.creator.personalBrand >= 45)
            let entertainmentPeak = state.specialCareer.track == .entertainment && (state.specialCareer.fame >= 50 || state.specialCareer.audience >= 55)
            let producerJob = state.career.roleID == "producer" || state.career.professionalRank == "Producer"
            let managementCred = state.career.experience(for: .management) + state.career.experience(for: .creative) + max(entApt, socApt, analApt) / 16
            let dossierFit = (creaApt + entApt + socApt) >= 140
            if !actorPeak && !creatorPeak && !entertainmentPeak && !producerJob && (managementCred < 6 || !dossierFit) {
                return "peak creative/entertainment Special + film credibility + creative/entrepreneurial dossier fit"
            }
            return nil
        case .startRecordLabel:
            // CT1-1: Diamond gate for record label — higher capital + peak music/creator/entertainment Special + dossier
            if state.finance.cashOnHand < 18_000 { return "$18,000+ cash (Diamond capital requirement)" }
            let musicPeak = state.specialCareer.track == .musicProducer && (state.specialCareer.fame >= 45 || state.specialCareer.audience >= 50)
            let creatorPeak = state.specialCareer.track == .contentCreator && state.specialCareer.creator.personalBrand >= 40
            let entertainmentPeak = state.specialCareer.track == .entertainment && (state.specialCareer.fame >= 45 || state.specialCareer.audience >= 50)
            let businessCred = max(state.career.experience(for: .creative), state.career.experience(for: .management)) + max(creaApt, entApt, socApt) / 14
            let dossierFit = (creaApt + entApt + socApt) >= 135
            if !musicPeak && !creatorPeak && !entertainmentPeak && (businessCred < 5 || !dossierFit) {
                return "peak music/creator/entertainment Special + label credibility + creative/entrepreneurial dossier fit"
            }
            return nil
        case .startCoachingCareer:
            // CT1-1: Strengthened Diamond gate for Program Coach — requires peak athlete or strong specialized/public service cred + capital + disciplined/social dossier
            if state.finance.cashOnHand < 15_000 { return "$15,000+ cash (Diamond capital for program)" }
            let coachingCred = state.career.experience(for: .coaching)
            let collegeDoor = state.career.roleID == "university_assistant_coach" || coachingCred >= 7
            let athletePeak = state.specialCareer.track == .athlete && state.specialCareer.yearsActive >= 5 && (state.specialCareer.athlete.personalBrand >= 45 || state.specialCareer.athlete.accolades.count >= 2)
            let leadershipCred = state.career.experience(for: .management) + state.career.experience(for: .service) + max(socApt, analApt) / 14
            let coachMind = max(state.player.smarts, analApt, socApt)
            let dossierFit = (socApt + analApt >= 110) || state.player.traits.contains(.disciplined)
            if !collegeDoor && !athletePeak && (leadershipCred < 6 || !dossierFit) {
                return "peak athlete Special or strong leadership/college coaching cred + disciplined/social dossier fit"
            }
            if coachMind < 58 && !state.player.traits.contains(.disciplined) {
                return "coaching IQ or disciplined trait"
            }
            return nil
        case .intenseTraining, .compete:
            // Dossier help for athlete path: high physical aptitude makes early entry easier (lower implicit barriers)
            // (These are often available via age + action availability, but aptitude now gives "natural" edge)
            if let d = dossier, d.aptitudes.physical < 40 && physApt < 40 {
                // very low physical aptitude makes intense athlete path feel wrong early
                if state.player.age < 20 {
                    return "body not ready (low physical aptitude)"
                }
            }
            // D3 edu: vocational/trade or high phys from dossier + track lowers barrier for athlete entry
            if eduTrack == .vocational || eduCred >= 75 {
                // practical background or strong creds help physical paths
            }
            return nil
        case .runScheme, .buildCrew:
            // D3: vocational/trade track gives practical "street" or hustle cred for crime entry (origin + edu synergy)
            if eduTrack == .vocational || eduCred >= 65 {
                // practical background helps heat tolerance or crew start
            }
            return nil
        default:
            return nil
        }
    }

    func advanceYear(input: SpecialCareerDomainSnapshot, player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState) -> DomainYearResult {
        var result = DomainYearResult()
        guard player.age >= 18, specialCareer.track != .inactive else { return result }

        specialCareer.yearsActive += 1
        let dossier = input.childhoodDossier

        switch specialCareer.track {
        case .entertainment:
            resolveEntertainmentYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, relationships: input.relationships, result: &result)
        case .movieActor:
            resolveMovieActorYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, worldEra: input.worldEra, result: &result)
        case .musicProducer:
            resolveMusicProducerYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, worldEra: input.worldEra, result: &result)
        case .movieProducer:
            resolveMovieProducerYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, worldEra: input.worldEra, result: &result)
        case .recordLabelOwner:
            resolveRecordLabelYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, worldEra: input.worldEra, result: &result)
        case .coach:
            resolveCoachingYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, worldEra: input.worldEra, result: &result)
        case .contentCreator:
            resolveContentCreatorYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, worldEra: input.worldEra, result: &result)
        case .politics:
            resolvePoliticsYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, worldEra: input.worldEra, result: &result)
        case .founder:
            resolveFounderYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, worldEra: input.worldEra, dossier: dossier, result: &result)
        case .athlete:
            if specialCareer.athlete.sport == .combatSports, specialCareer.athlete.combat.discipline != nil {
                result = CombatCareerSystem().advanceCombatYear(player: &player, specialCareer: &specialCareer)
            } else {
                resolveAthleteYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, worldEra: input.worldEra, dossier: dossier, result: &result)
            }
        case .fightEmpire:
            result = CombatCareerSystem().advanceFightEmpireYear(player: player, specialCareer: &specialCareer)
        case .shadowOperative, .trader, .ventureCapitalist, .corporateRaider, .crime:
            resolveCriminalEnterpriseYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, worldEra: input.worldEra, result: &result)
        case .military, .inactive:
            break
        }

        refreshTier(on: &specialCareer)
        specialCareer.clamp()
        return result
    }

    func handles(_ choiceID: ActionChoiceID) -> Bool {
        if CombatCareerSystem().handles(choiceID) { return true }
        switch choiceID {
        case .chaseSpotlight, .startMovieActor, .auditionRole, .actingClass, .buildActingReel, .takeIndieRole, .managePublicist,
             .startCompany, .pitchDeck, .pivotBusiness, .raiseCapital, .aggressiveExpansion, .ipoExit, .hireAdvisor,
             .startMusicProducer, .produceTrack, .runStudioSession, .shopBeats, .collaborateWithArtist, .polishSignatureSound, .manageProducerCredits,
             .startMovieProducer, .optionScript, .castProject, .shootFilm, .handleProductionCrisis, .secureDistribution, .manageBackEndPoints,
             .startRecordLabel, .signArtist, .developArtist, .releaseRecord, .bookTour, .payArtists, .pushSingle, .handleArtistDrama,
             .startCoachingCareer, .recruitTalent, .hireCoachingStaff, .installSystem, .runTrainingCamp, .manageLockerRoom, .callBigGame, .handleBoosterPressure,
             .manageFund, .acquireCompetitor, .stripAssets,
             .intenseTraining, .compete, .gatherIntelligence, .exploitLeverage, .dayTrade, .analyzeMarkets,
             .closeMajorDeal, .allHandsRally, .fundraiseSprint, .takeRealBreak, .hireKeyTalent,
             .postDaily, .goLive, .filmBanger, .collab, .addressDrama, .takeMentalBreak, .dropBrandDeal,
             .extraTrainingSession, .recoveryFocus, .mediaAppearance, .teamBonding, .edgeProtocol:  // S2 athlete static instants + edge
            return true
        default:
            return false
        }
    }

    func applyAction(_ choiceID: ActionChoiceID, player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, childhoodDossier: ChildhoodDossier? = nil, finance: inout FinanceState) -> DomainYearResult {
        if CombatCareerSystem().handles(choiceID) {
            return CombatCareerSystem().applyAction(
                choiceID,
                player: &player,
                career: &career,
                specialCareer: &specialCareer,
                finance: finance,
                dossier: childhoodDossier
            )
        }
        var result = DomainYearResult()
        guard player.age >= 18 else { return result }

        switch choiceID {
        case .startCompany:
            // This now triggers the Pitch Deck in Orchestrator, but let's keep a fallback
            activate(.founder, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.sector = .general
            specialCareer.audience = 15
            specialCareer.heat = 20
            specialCareer.equityOwned = 1.0
            specialCareer.burnout += 10
            // Activate already applied dossier-biased founder stats (vision/execution etc).
            // Ensure minimum floors for a fresh launch if somehow lower.
            if specialCareer.founder.vision < 48 { specialCareer.founder.vision = 52 }
            if specialCareer.founder.execution < 46 { specialCareer.founder.execution = 50 }
            result.financeEffects = FinanceEffects(cashDelta: -5000)

        case .pitchDeck:
            // Handled via Interaction resolving, but setting base state
            activate(.founder, specialCareer: &specialCareer, dossier: childhoodDossier)
            // Activate seeded with dossier bias; light top-up for pitch path
            if specialCareer.founder.vision < 52 {
                specialCareer.founder.vision = max(specialCareer.founder.vision, (childhoodDossier?.aptitudes.entrepreneurial ?? 50) + 3)
            }

        case .hireAdvisor:
            guard specialCareer.track == .founder || specialCareer.track == .ventureCapitalist else { break }
            let specialties: [AdvisorSpecialty] = [.growth, .strategy, .political]
            let spec = specialties.randomElement()!
            let advisor = BusinessAdvisor(name: ["Sarah", "Marcus", "Elena", "Julian"].randomElement()!, specialty: spec, yearlyFee: 2000)
            specialCareer.advisors.append(advisor)
            result.notes.append(DomainNote(title: "Strategic Hire", text: "You hired \(advisor.name) as a \(spec.rawValue) advisor.", tags: [.career]))

        case .manageFund:
            let enteredDiamond = activate(.ventureCapitalist, specialCareer: &specialCareer, dossier: childhoodDossier, entryAge: player.age)
            specialCareer.capitalUnderManagement += 50000
            specialCareer.notoriety += 10 // Reputation
            specialCareer.burnout += 12 // CT4-2 Diamond criminal empire balance: higher toll for high finance crime
            result.notes.append(DomainNote(title: "VC Fund", text: "You are now managing a fund. Your career depends on other people's success.", tags: [.career, .finance]))
            appendDiamondEntryNote(if: enteredDiamond, transitionCount: specialCareer.diamondTransitions, to: &result)

        case .acquireCompetitor:
            let enteredDiamond = activate(.corporateRaider, specialCareer: &specialCareer, dossier: childhoodDossier, entryAge: player.age)
            specialCareer.audience += 25 // Size
            specialCareer.heat += 30 // Debt/Integration
            specialCareer.notoriety += 15 // Fear
            specialCareer.burnout += 10 // CT4-2 Diamond balance
            result.notes.append(DomainNote(title: "Hostile Takeover", text: "You acquired a rival. You are larger, but more exposed.", tags: [.career, .risk]))
            appendDiamondEntryNote(if: enteredDiamond, transitionCount: specialCareer.diamondTransitions, to: &result)

        case .stripAssets:
            guard specialCareer.track == .corporateRaider else { break }
            let payout = specialCareer.audience * 400
            specialCareer.audience = max(10, specialCareer.audience - 40)
            specialCareer.notoriety += 25
            specialCareer.boardPressure += 20
            result.financeEffects = FinanceEffects(cashDelta: payout)
            result.notes.append(DomainNote(title: "Asset Stripping", text: "You sold off the parts. The windfall is massive, but the bridges are burned.", tags: [.career, .finance]))

        case .raiseCapital:
            guard specialCareer.track == .founder else { break }
            let injection = Int(Double(specialCareer.audience) * 600)
            specialCareer.equityOwned -= 0.12
            specialCareer.boardPressure += 15
            specialCareer.audience += 12
            result.financeEffects = FinanceEffects(cashDelta: injection)

        case .pivotBusiness:
            guard specialCareer.track == .founder else { break }
            specialCareer.heat = max(0, specialCareer.heat - 18)
            specialCareer.boardPressure = max(0, specialCareer.boardPressure - 12)
            specialCareer.audience = max(8, specialCareer.audience - 6)
            specialCareer.burnout += 4
            result.notes.append(DomainNote(title: "Founder Pivot", text: "You cut away the idea that was not working. Momentum dipped, but the burn got more survivable.", tags: [.career, .finance]))

        case .aggressiveExpansion:
            guard specialCareer.track == .founder else { break }
            specialCareer.fame += 25
            specialCareer.audience += 18
            specialCareer.heat += 30
            specialCareer.burnout += 18

        case .ipoExit:
            guard specialCareer.track == .founder, specialCareer.audience >= 80 else { break }
            let totalValue = specialCareer.audience * 2500
            let totalPayout = Int(Double(totalValue) * specialCareer.equityOwned)

            // E3 Synergy: Move 70% into stocks, 30% to cash
            let cashPayout = Int(Double(totalPayout) * 0.3)
            let stockValue = Double(totalPayout - cashPayout)

            result.financeEffects = FinanceEffects(cashDelta: cashPayout)

            // CT1 fix: finance now always provided
            finance.portfolio.stocks.append(StockHolding(tickerOrSector: "TECH", sharesOrValue: stockValue, entryBasis: stockValue, volatilityFactor: 1.2))

            // E4: Rich post-founder legacy and identity
            let fd = specialCareer.founder
            let exitNote: String
            if fd.personalLegend >= 70 {
                exitNote = "You rang the bell. The market knows your name now. Most of your wealth is now tied to your new 'TECH' holdings."
            } else if fd.founderMentalLoad >= 70 {
                exitNote = "You rang the bell. The money is life-changing, but the years took something from you that no exit can return. Your payout is split between liquid cash and market positions."
            } else {
                exitNote = "You rang the bell. Legend status secured. You converted your equity into a mix of cash and a heavy TECH portfolio position."
            }
            result.notes.append(DomainNote(title: "The IPO", text: exitNote, tags: [.career, .finance, .progress]))

            // Seed post-founder identity flavor
            if fd.personalLegend >= 60 {
                specialCareer.fame = min(100, specialCareer.fame + 15)
            }
            exitTrack(on: &specialCareer)
        // E2: Dedicated founder quick static instants (always clickable in founder subdomain)
        case .closeMajorDeal:
            guard specialCareer.track == .founder else { break }
            specialCareer.audience = min(100, specialCareer.audience + 10)
            specialCareer.founder.execution = min(100, specialCareer.founder.execution + 6)
            let dealCash = 3_000 + specialCareer.audience * 80
            result.financeEffects = FinanceEffects(cashDelta: dealCash)
            specialCareer.boardPressure += 8
            result.notes.append(DomainNote(title: "Major Deal Closed", text: "The signature hit. Revenue jumps, the story gets bigger, and the weight on your back increases.", tags: [.career, .finance]))
        case .allHandsRally:
            guard specialCareer.track == .founder else { break }
            specialCareer.founder.teamHealth = min(100, specialCareer.founder.teamHealth + 12)
            specialCareer.founder.execution = min(100, specialCareer.founder.execution + 3)
            specialCareer.burnout = cappedBurnoutRecovery(current: specialCareer.burnout, relief: 4)
            result.notes.append(DomainNote(title: "All Hands", text: "You stood in front of everyone and reminded them why. The room feels like it can run through a wall — for a week or two.", tags: [.career, .social]))
        case .fundraiseSprint:
            guard specialCareer.track == .founder else { break }
            let raise = 8_000 + specialCareer.audience * 120
            result.financeEffects = FinanceEffects(cashDelta: raise)
            specialCareer.equityOwned = max(0.1, specialCareer.equityOwned - 0.08)
            specialCareer.boardPressure += 12
            specialCareer.burnout += 6
            result.notes.append(DomainNote(title: "Sprint Raise", text: "You sold the vision hard for 10 days straight. The runway lengthened. Your soul is a little thinner.", tags: [.career, .finance]))
        case .takeRealBreak:
            guard specialCareer.track == .founder else { break }
            specialCareer.burnout = cappedBurnoutRecovery(current: specialCareer.burnout, relief: 14)
            specialCareer.founder.founderMentalLoad = max(0, specialCareer.founder.founderMentalLoad - 10)
            specialCareer.founder.execution = max(0, specialCareer.founder.execution - 3)
            result.healthEffects = HealthEffects(physical: 2, mental: 5, exercise: nil, nutrition: nil, stressManagement: 5)
            result.notes.append(DomainNote(title: "Real Break", text: "You actually stepped away. The company didn't die. Neither did you — this week.", tags: [.career, .health]))
        case .hireKeyTalent:
            guard specialCareer.track == .founder else { break }
            specialCareer.founder.execution = min(100, specialCareer.founder.execution + 8)
            specialCareer.audience = min(100, specialCareer.audience + 5)
            specialCareer.founder.teamHealth = min(100, specialCareer.founder.teamHealth + 5)
            specialCareer.boardPressure += 4
            result.financeEffects = FinanceEffects(cashDelta: -2_200)
            result.notes.append(DomainNote(title: "Key Hire", text: "You brought in someone who actually moves the needle. The burn rate went up so the ceiling could too.", tags: [.career, .finance]))
        case .chaseSpotlight:
            activate(.entertainment, specialCareer: &specialCareer)
            specialCareer.fame += 6
            specialCareer.audience += 8
            specialCareer.burnout += 5
        case .startMovieActor:
            activate(.movieActor, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.movieActor.agentQuality = max(specialCareer.movieActor.agentQuality, 24)
            specialCareer.movieActor.auditionNetwork = max(specialCareer.movieActor.auditionNetwork, 28)
            specialCareer.movieActor.actingSkill = max(specialCareer.movieActor.actingSkill, 35)
            result.financeEffects = FinanceEffects(cashDelta: -1_200)
            result.notes.append(DomainNote(title: "Actor Track", text: "Headshots, classes, unpaid reads. The screen career is real now, even if the money is not.", tags: [.career, .finance]))
        case .auditionRole:
            activate(.movieActor, specialCareer: &specialCareer, dossier: childhoodDossier)
            var actor = specialCareer.movieActor
            let roll = normalizedRoll(player.age * 19 + actor.actingSkill * 2 + actor.screenPresence + actor.auditionNetwork + actor.agentQuality - actor.typecastRisk)
            let booked = roll >= 62
            let breakout = roll >= 88
            let payout = breakout ? 8_000 + actor.boxOfficeDraw * 90 : (booked ? 1_500 + actor.agentQuality * 35 : 0)
            if booked {
                actor.roleCredits += 1
                actor.boxOfficeDraw += breakout ? 12 : 4
                actor.screenPresence += breakout ? 7 : 3
                actor.publicImage += breakout ? 5 : 1
                actor.typecastRisk += actor.roleCredits > 3 ? 2 : 0
            } else {
                actor.auditionNetwork += 2
                actor.publicImage = max(0, actor.publicImage - 1)
            }
            actor.lastRolePayout = payout
            specialCareer.fame += breakout ? 9 : (booked ? 3 : 0)
            specialCareer.audience += breakout ? 10 : (booked ? 4 : 1)
            specialCareer.burnout += 5
            specialCareer.lastPayout = payout
            specialCareer.movieActor = actor
            result.financeEffects = FinanceEffects(cashDelta: payout)
            result.notes.append(DomainNote(title: breakout ? "Breakout Role" : (booked ? "Role Booked" : "Audition Passed Over"), text: breakout ? "The role traveled further than the film. People know your face now." : (booked ? "The part is not glamorous, but it is a real credit." : "The room said no. You still left with another contact and thicker skin."), tags: [.career, .finance]))
        case .actingClass:
            activate(.movieActor, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.movieActor.actingSkill += 8
            specialCareer.movieActor.screenPresence += 3
            specialCareer.movieActor.typecastRisk = max(0, specialCareer.movieActor.typecastRisk - 3)
            specialCareer.burnout += 2
            result.financeEffects = FinanceEffects(cashDelta: -900)
            result.notes.append(DomainNote(title: "Craft Work", text: "The scene got quieter and better. No applause, but the work is less fake.", tags: [.career]))
        case .buildActingReel:
            activate(.movieActor, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.movieActor.auditionNetwork += 7
            specialCareer.movieActor.agentQuality += 5
            specialCareer.movieActor.publicImage += 2
            result.financeEffects = FinanceEffects(cashDelta: -700)
            result.notes.append(DomainNote(title: "Reel Built", text: "Your best two minutes are easier to send now. That matters more than it should.", tags: [.career, .finance]))
        case .takeIndieRole:
            activate(.movieActor, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.movieActor.roleCredits += 1
            specialCareer.movieActor.actingSkill += 4
            specialCareer.movieActor.screenPresence += 4
            specialCareer.movieActor.boxOfficeDraw += 1
            specialCareer.movieActor.typecastRisk = max(0, specialCareer.movieActor.typecastRisk - 2)
            specialCareer.fame += 1
            specialCareer.lastPayout = 500
            result.financeEffects = FinanceEffects(cashDelta: 500)
            result.notes.append(DomainNote(title: "Indie Credit", text: "The check is small, the call sheet is chaotic, and the credit is real.", tags: [.career]))
        case .managePublicist:
            activate(.movieActor, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.movieActor.publicImage += 8
            specialCareer.movieActor.agentQuality += 2
            specialCareer.heat = max(0, specialCareer.heat - 8)
            specialCareer.burnout += 2
            result.financeEffects = FinanceEffects(cashDelta: -1_200)
            result.notes.append(DomainNote(title: "Public Story", text: "The interview got cleaner, the mess got quieter, and your team got a little more expensive.", tags: [.career, .finance, .social]))
        case .startMusicProducer:
            activate(.musicProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.musicProducer.studioQuality = max(specialCareer.musicProducer.studioQuality, 32)
            specialCareer.musicProducer.network = max(specialCareer.musicProducer.network, 35)
            specialCareer.musicProducer.demand = max(specialCareer.musicProducer.demand, 18)
            result.financeEffects = FinanceEffects(cashDelta: -2_000)
            result.notes.append(DomainNote(title: "Producer Setup", text: "You bought enough gear to become dangerous and started chasing rooms where records get made.", tags: [.career, .finance]))
        case .produceTrack:
            activate(.musicProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            var producer = specialCareer.musicProducer
            let roll = normalizedRoll(player.age * 17 + producer.sonicSignature + producer.studioQuality + producer.network + producer.demand)
            let placement = roll >= 82
            let payout = placement ? 3_000 + producer.demand * 60 : max(300, producer.demand * 20)
            producer.credits += 1
            producer.royaltyCatalog += placement ? 7 : 3
            producer.demand += placement ? 9 : 3
            producer.sonicSignature += 2
            producer.creditDisputes += producer.network < 40 ? 4 : 1
            producer.lastPlacementValue = payout
            specialCareer.fame += placement ? 5 : 1
            specialCareer.audience += placement ? 5 : 2
            specialCareer.lastPayout = payout
            specialCareer.musicProducer = producer
            result.financeEffects = FinanceEffects(cashDelta: payout)
            result.notes.append(DomainNote(title: placement ? "Placement Landed" : "Track Produced", text: placement ? "The record landed with a real artist. Your tag is traveling now." : "The track is finished. Not every credit explodes, but the catalog gets heavier.", tags: [.career, .finance]))
        case .runStudioSession:
            activate(.musicProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.musicProducer.network += 6
            specialCareer.musicProducer.studioQuality += 3
            specialCareer.musicProducer.demand += 2
            specialCareer.burnout += 4
            result.financeEffects = FinanceEffects(cashDelta: 600)
            result.notes.append(DomainNote(title: "Studio Session", text: "You kept the room alive until the take finally worked. People remember who made it happen.", tags: [.career, .social]))
        case .shopBeats:
            activate(.musicProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.musicProducer.network += 4
            specialCareer.musicProducer.demand += 5
            specialCareer.musicProducer.creditDisputes += 2
            result.notes.append(DomainNote(title: "Beats Shopped", text: "The folder is in more inboxes now. Most people ignore it. One person might not.", tags: [.career]))
        case .collaborateWithArtist:
            activate(.musicProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.musicProducer.network += 8
            specialCareer.musicProducer.sonicSignature += 3
            specialCareer.musicProducer.demand += 4
            specialCareer.musicProducer.creditDisputes += 5
            specialCareer.fame += 2
            result.notes.append(DomainNote(title: "Artist Collaboration", text: "The chemistry was real. So was the ambiguity over who deserves what.", tags: [.career, .social, .risk]))
        case .polishSignatureSound:
            activate(.musicProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.musicProducer.sonicSignature += 8
            specialCareer.musicProducer.studioQuality += 4
            specialCareer.musicProducer.demand += 1
            specialCareer.burnout += 2
            result.notes.append(DomainNote(title: "Signature Sound", text: "The records are starting to carry your fingerprints before your name appears.", tags: [.career]))
        case .manageProducerCredits:
            activate(.musicProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.musicProducer.creditDisputes = max(0, specialCareer.musicProducer.creditDisputes - 15)
            specialCareer.musicProducer.royaltyCatalog += 2
            specialCareer.musicProducer.network = max(0, specialCareer.musicProducer.network - 2)
            result.notes.append(DomainNote(title: "Credits Protected", text: "The paperwork got less romantic and more correct. Future royalties just got safer.", tags: [.career, .finance]))
        case .startMovieProducer:
            let enteredDiamond = activate(.movieProducer, specialCareer: &specialCareer, dossier: childhoodDossier, entryAge: player.age)
            specialCareer.movieProducer.developmentQuality = max(specialCareer.movieProducer.developmentQuality, 34)
            specialCareer.movieProducer.budgetControl = max(specialCareer.movieProducer.budgetControl, 34)
            specialCareer.movieProducer.studioTrust = max(specialCareer.movieProducer.studioTrust, 32)
            result.financeEffects = FinanceEffects(cashDelta: -12_000)
            specialCareer.burnout += 10 // CT4-2 Diamond balance: empire building exacts high personal toll
            result.notes.append(DomainNote(title: "Film Slate Opens", text: "The producer title is real now. The money leaves first. The movie may or may not follow.", tags: [.career, .finance, .risk]))
            appendDiamondEntryNote(if: enteredDiamond, transitionCount: specialCareer.diamondTransitions, to: &result)
        case .optionScript:
            activate(.movieProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.movieProducer.slateCount += 1
            specialCareer.movieProducer.developmentQuality += 7
            specialCareer.movieProducer.productionChaos += 3
            specialCareer.burnout += 2
            result.financeEffects = FinanceEffects(cashDelta: -2_500)
            result.notes.append(DomainNote(title: "Script Optioned", text: "You bought the right to chase a movie. It is not a film yet. It is a promise with legal fees.", tags: [.career, .finance]))
        case .castProject:
            activate(.movieProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.movieProducer.castRelationships += 9
            specialCareer.movieProducer.prestige += 4
            specialCareer.movieProducer.productionChaos += 5
            specialCareer.movieProducer.studioTrust += 2
            result.financeEffects = FinanceEffects(cashDelta: -3_000)
            result.notes.append(DomainNote(title: "Talent Attached", text: "The project has faces now. Every attachment makes the film more real and more fragile.", tags: [.career, .social, .finance]))
        case .shootFilm:
            activate(.movieProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            var film = specialCareer.movieProducer
            if film.slateCount == 0 { film.slateCount = 1 }
            let roll = normalizedRoll(player.age * 23 + film.developmentQuality * 2 + film.castRelationships + film.budgetControl + film.studioTrust - film.productionChaos)
            let completed = roll >= 45
            let acclaimed = roll >= 84
            let cost = 7_000 + film.productionChaos * 55
            if completed {
                film.slateCount = max(0, film.slateCount - 1)
                film.backendCatalog += acclaimed ? 12 : 5
                film.prestige += acclaimed ? 12 : 4
                film.distributionLeverage += acclaimed ? 8 : 3
                film.studioTrust += film.budgetControl >= 45 ? 4 : -3
                film.productionChaos += acclaimed ? 4 : 8
                specialCareer.fame += acclaimed ? 7 : 2
                specialCareer.audience += acclaimed ? 8 : 3
            } else {
                film.productionChaos += 14
                film.studioTrust -= 8
                film.prestige -= 2
                specialCareer.heat += 6
            }
            specialCareer.burnout += 8
            specialCareer.movieProducer = film
            result.financeEffects = FinanceEffects(cashDelta: -cost)
            result.notes.append(DomainNote(title: completed ? (acclaimed ? "Festival Film Wrapped" : "Film Wrapped") : "Production Stalled", text: completed ? "The footage exists. That alone feels impossible." : "The shoot burned money and still did not become a finished film.", tags: [.career, .finance, .risk]))
        case .handleProductionCrisis:
            activate(.movieProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.movieProducer.productionChaos = max(0, specialCareer.movieProducer.productionChaos - 16)
            specialCareer.movieProducer.studioTrust += 5
            specialCareer.movieProducer.budgetControl += 3
            specialCareer.burnout += 5
            result.financeEffects = FinanceEffects(cashDelta: -2_000)
            result.notes.append(DomainNote(title: "Production Saved", text: "You made the ugly calls before the ugly calls made themselves.", tags: [.career, .finance, .risk]))
        case .secureDistribution:
            activate(.movieProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            var film = specialCareer.movieProducer
            let leverage = film.distributionLeverage + film.prestige + film.backendCatalog + film.studioTrust - film.productionChaos
            let payout = leverage >= 140 ? 18_000 + leverage * 60 : (leverage >= 85 ? 5_000 + leverage * 25 : 1_500)
            film.distributionLeverage += leverage >= 85 ? 8 : 3
            film.studioTrust += leverage >= 85 ? 5 : -2
            film.backendCatalog += leverage >= 85 ? 4 : 1
            film.lastFilmPayout = payout
            specialCareer.fame += leverage >= 140 ? 7 : 2
            specialCareer.audience += leverage >= 85 ? 5 : 1
            specialCareer.lastPayout = payout
            specialCareer.movieProducer = film
            result.financeEffects = FinanceEffects(cashDelta: payout)
            result.notes.append(DomainNote(title: leverage >= 85 ? "Distribution Deal" : "Small Distribution", text: leverage >= 85 ? "The film found a buyer with reach. The backend finally has oxygen." : "The film will be seen, but nobody is confusing this with a studio victory.", tags: [.career, .finance]))
        case .manageBackEndPoints:
            activate(.movieProducer, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.movieProducer.backendCatalog += 5
            specialCareer.movieProducer.budgetControl += 5
            specialCareer.movieProducer.productionChaos = max(0, specialCareer.movieProducer.productionChaos - 5)
            specialCareer.movieProducer.castRelationships = max(0, specialCareer.movieProducer.castRelationships - 2)
            result.notes.append(DomainNote(title: "Backend Protected", text: "The math got less glamorous and more survivable. Future checks have a better chance of existing.", tags: [.career, .finance]))
        case .startRecordLabel:
            let enteredDiamond = activate(.recordLabelOwner, specialCareer: &specialCareer, dossier: childhoodDossier, entryAge: player.age)
            specialCareer.recordLabel.cashflowPressure = min(100, specialCareer.recordLabel.cashflowPressure + 10)
            specialCareer.recordLabel.labelPrestige = max(specialCareer.recordLabel.labelPrestige, 22)
            specialCareer.recordLabel.artistTrust = max(specialCareer.recordLabel.artistTrust, 55)
            result.financeEffects = FinanceEffects(cashDelta: -8_000)
            result.notes.append(DomainNote(title: "Label Founded", text: "The label exists now. One room, one roster dream, and a bank account that suddenly feels smaller.", tags: [.career, .finance]))
            appendDiamondEntryNote(if: enteredDiamond, transitionCount: specialCareer.diamondTransitions, to: &result)
        case .signArtist:
            activate(.recordLabelOwner, specialCareer: &specialCareer, dossier: childhoodDossier)
            var label = specialCareer.recordLabel
            let scoutBase = label.labelPrestige + label.artistTrust + (childhoodDossier?.aptitudes.social ?? 50)
            let artist = makeLabelArtist(seed: player.age * 31 + label.roster.count * 17 + scoutBase, prestige: label.labelPrestige, trust: label.artistTrust)
            label.roster.append(artist)
            label.cashflowPressure += 8
            label.artistTrust = max(0, label.artistTrust - (label.roster.count > 4 ? 4 : 1))
            specialCareer.audience = min(100, specialCareer.audience + 3)
            specialCareer.recordLabel = label
            result.financeEffects = FinanceEffects(cashDelta: -2_500)
            result.notes.append(DomainNote(title: "Artist Signed", text: "\(artist.name) signed. The roster got louder, and the monthly burn got less polite.", tags: [.career, .finance]))
        case .developArtist:
            activate(.recordLabelOwner, specialCareer: &specialCareer, dossier: childhoodDossier)
            var label = specialCareer.recordLabel
            if label.roster.isEmpty {
                label.roster.append(makeLabelArtist(seed: player.age * 19 + 3, prestige: label.labelPrestige, trust: label.artistTrust))
            }
            if let index = label.roster.indices.min(by: { label.roster[$0].popularity < label.roster[$1].popularity }) {
                label.roster[index].talent = min(100, label.roster[index].talent + 5)
                label.roster[index].morale = min(100, label.roster[index].morale + 6)
                label.roster[index].tourReadiness = min(100, label.roster[index].tourReadiness + 8)
            }
            label.artistTrust = min(100, label.artistTrust + 5)
            label.catalogStrength = min(100, label.catalogStrength + 2)
            label.cashflowPressure = min(100, label.cashflowPressure + 5)
            specialCareer.burnout += 3
            specialCareer.recordLabel = label
            result.financeEffects = FinanceEffects(cashDelta: -1_800)
            result.notes.append(DomainNote(title: "Artist Development", text: "Studio time, vocal takes, bad coffee. The roster got better in ways the public cannot see yet.", tags: [.career]))
        case .releaseRecord:
            activate(.recordLabelOwner, specialCareer: &specialCareer, dossier: childhoodDossier)
            var label = specialCareer.recordLabel
            if label.roster.isEmpty {
                label.roster.append(makeLabelArtist(seed: player.age * 23 + 7, prestige: label.labelPrestige, trust: label.artistTrust))
            }
            let index = bestArtistIndex(in: label, by: { $0.talent + $0.popularity + $0.morale })
            let artist = label.roster[index]
            let roll = normalizedRoll(player.age * 13 + artist.talent * 2 + artist.popularity + label.labelPrestige - label.industryHeat)
            let catalogGain = roll >= 82 ? 12 : (roll >= 48 ? 6 : 2)
            let payout = roll >= 82 ? 7_500 + artist.popularity * 80 : (roll >= 48 ? 1_500 + artist.popularity * 25 : 0)
            label.roster[index].catalogCount += 1
            label.roster[index].popularity += roll >= 82 ? 14 : (roll >= 48 ? 6 : -2)
            label.roster[index].morale += roll >= 48 ? 3 : -5
            label.roster[index].yearlyEarnings += max(0, payout / 3)
            label.catalogStrength += catalogGain
            label.labelPrestige += roll >= 82 ? 7 : (roll >= 48 ? 3 : 0)
            label.cashflowPressure = max(0, label.cashflowPressure - (roll >= 48 ? 6 : 0))
            specialCareer.fame += roll >= 82 ? 8 : (roll >= 48 ? 3 : 0)
            specialCareer.audience += roll >= 82 ? 8 : 3
            specialCareer.lastPayout = payout
            specialCareer.recordLabel = label
            result.financeEffects = FinanceEffects(cashDelta: payout)
            result.notes.append(DomainNote(title: roll >= 82 ? "Breakout Record" : "Record Released", text: roll >= 82 ? "\(artist.name) caught fire. The catalog is finally starting to look like an asset." : "The release is out. Not every record changes the world, but the catalog got deeper.", tags: [.career, .finance]))
        case .bookTour:
            activate(.recordLabelOwner, specialCareer: &specialCareer, dossier: childhoodDossier)
            var label = specialCareer.recordLabel
            if label.roster.isEmpty {
                label.roster.append(makeLabelArtist(seed: player.age * 29 + 11, prestige: label.labelPrestige, trust: label.artistTrust))
            }
            let index = bestArtistIndex(in: label, by: { $0.tourReadiness + $0.popularity + $0.morale })
            let readiness = label.roster[index].tourReadiness
            let gross = max(0, readiness + label.roster[index].popularity + label.tourMachine - label.industryHeat)
            let payout = gross >= 120 ? 9_000 + gross * 55 : (gross >= 75 ? 2_500 + gross * 20 : -2_000)
            label.tourMachine += gross >= 75 ? 6 : 2
            label.roster[index].popularity += gross >= 75 ? 7 : 1
            label.roster[index].morale -= gross >= 120 ? 4 : 9
            label.roster[index].tourReadiness = max(10, readiness - 12)
            label.cashflowPressure = payout >= 0 ? max(0, label.cashflowPressure - 8) : min(100, label.cashflowPressure + 10)
            label.industryHeat += gross < 75 ? 6 : 2
            specialCareer.burnout += 7
            specialCareer.fame += gross >= 120 ? 5 : 1
            specialCareer.lastPayout = max(0, payout)
            specialCareer.recordLabel = label
            result.financeEffects = FinanceEffects(cashDelta: payout)
            result.notes.append(DomainNote(title: payout >= 0 ? "Tour Booked" : "Tour Misfire", text: payout >= 0 ? "The road paid, but nobody came home lighter." : "The dates went up before the demand was real. The losses are not abstract.", tags: [.career, .finance, .risk]))
        case .payArtists:
            activate(.recordLabelOwner, specialCareer: &specialCareer, dossier: childhoodDossier)
            var label = specialCareer.recordLabel
            label.artistPayoutPolicy = .artistFriendly
            label.artistTrust = min(100, label.artistTrust + 14)
            label.industryHeat = max(0, label.industryHeat - 10)
            for index in label.roster.indices {
                label.roster[index].morale = min(100, label.roster[index].morale + 8)
                label.roster[index].contractFairness = min(100, label.roster[index].contractFairness + 10)
            }
            label.cashflowPressure = min(100, label.cashflowPressure + 7)
            specialCareer.recordLabel = label
            result.financeEffects = FinanceEffects(cashDelta: -2_200 - label.roster.count * 700)
            result.notes.append(DomainNote(title: "Artists Paid", text: "The checks were clear and the splits were humane. The margin hurt. The room trusted you more.", tags: [.career, .finance, .social]))
        case .pushSingle:
            activate(.recordLabelOwner, specialCareer: &specialCareer, dossier: childhoodDossier)
            var label = specialCareer.recordLabel
            if label.roster.isEmpty {
                label.roster.append(makeLabelArtist(seed: player.age * 37 + 5, prestige: label.labelPrestige, trust: label.artistTrust))
            }
            let index = bestArtistIndex(in: label, by: { $0.talent + $0.catalogCount * 8 })
            label.roster[index].popularity = min(100, label.roster[index].popularity + 10)
            label.labelPrestige = min(100, label.labelPrestige + 4)
            label.cashflowPressure = min(100, label.cashflowPressure + 5)
            label.industryHeat = min(100, label.industryHeat + 3)
            specialCareer.audience = min(100, specialCareer.audience + 5)
            specialCareer.fame = min(100, specialCareer.fame + 3)
            specialCareer.recordLabel = label
            result.financeEffects = FinanceEffects(cashDelta: -1_500)
            result.notes.append(DomainNote(title: "Single Pushed", text: "The campaign made the song harder to ignore. Attention is expensive, but silence is worse.", tags: [.career, .finance]))
        case .handleArtistDrama:
            activate(.recordLabelOwner, specialCareer: &specialCareer, dossier: childhoodDossier)
            var label = specialCareer.recordLabel
            label.industryHeat = max(0, label.industryHeat - 14)
            label.artistTrust = max(0, label.artistTrust - 2)
            if let index = label.roster.indices.min(by: { label.roster[$0].morale < label.roster[$1].morale }) {
                label.roster[index].morale = min(100, label.roster[index].morale + 10)
            }
            specialCareer.burnout += 4
            specialCareer.recordLabel = label
            result.notes.append(DomainNote(title: "Drama Contained", text: "You got everyone in the same room before the posts became headlines. Nothing is fixed, but the bleeding slowed.", tags: [.career, .risk]))
        case .startCoachingCareer:
            let enteredDiamond = activate(.coach, specialCareer: &specialCareer, dossier: childhoodDossier, entryAge: player.age)
            if career.roleID == "university_assistant_coach" {
                career.roleID = nil
            }
            career.status = .fullTime
            career.professionalRank = "Program Coach"
            career.careerExperience[.coaching, default: 0] += 1
            specialCareer.coaching.programLevel = max(specialCareer.coaching.programLevel, 2)
            result.notes.append(DomainNote(title: "Program Offer", text: "A university program handed you the whistle and the keys. Recruiting, staff, boosters, and Saturdays are your life now.", tags: [.career, .progress]))
            specialCareer.burnout += 8 // CT4-2 Diamond balance: empire exacts high personal toll from day one
            appendDiamondEntryNote(if: enteredDiamond, transitionCount: specialCareer.diamondTransitions, to: &result)
        case .recruitTalent:
            activate(.coach, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.coaching.rosterTalent += 8
            specialCareer.coaching.recruitingReach += 6
            specialCareer.coaching.boosterPressure += 4
            specialCareer.burnout += 3
            result.financeEffects = FinanceEffects(cashDelta: -1_000)
            result.notes.append(DomainNote(title: "Recruiting Win", text: "The roster got more dangerous. So did the expectations attached to it.", tags: [.career, .finance]))
        case .hireCoachingStaff:
            activate(.coach, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.coaching.staffQuality += 9
            specialCareer.coaching.playerDevelopment += 3
            specialCareer.coaching.lockerRoom += 2
            result.financeEffects = FinanceEffects(cashDelta: -1_800)
            result.notes.append(DomainNote(title: "Staff Upgraded", text: "The program has sharper voices in the building. Good assistants make you look smarter.", tags: [.career, .finance]))
        case .installSystem:
            activate(.coach, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.coaching.schemeFit += 10
            specialCareer.coaching.playerDevelopment += 4
            specialCareer.coaching.rosterTalent = max(0, specialCareer.coaching.rosterTalent - 2)
            specialCareer.burnout += 3
            result.notes.append(DomainNote(title: "System Installed", text: "The team has an identity now. It is ugly early, but at least the ugliness has a plan.", tags: [.career]))
        case .runTrainingCamp:
            activate(.coach, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.coaching.playerDevelopment += 7
            specialCareer.coaching.schemeFit += 4
            specialCareer.coaching.lockerRoom -= 3
            specialCareer.burnout += 5
            result.notes.append(DomainNote(title: "Camp Grind", text: "The team got sharper and a little more tired of your voice.", tags: [.career, .health]))
        case .manageLockerRoom:
            activate(.coach, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.coaching.lockerRoom += 12
            specialCareer.coaching.boosterPressure = max(0, specialCareer.coaching.boosterPressure - 2)
            specialCareer.burnout += 2
            result.notes.append(DomainNote(title: "Room Held", text: "You kept the team from splitting into private agendas. That does not show in the stat sheet until it does.", tags: [.career, .social]))
        case .callBigGame:
            activate(.coach, specialCareer: &specialCareer, dossier: childhoodDossier)
            let c = specialCareer.coaching
            let roll = normalizedRoll(player.age * 31 + c.schemeFit * 2 + c.rosterTalent + c.lockerRoom + c.staffQuality - c.boosterPressure)
            if roll >= 58 {
                specialCareer.coaching.seasonWins = min(16, specialCareer.coaching.seasonWins + 1)
                specialCareer.coaching.programPrestige += roll >= 85 ? 8 : 4
                specialCareer.fame += roll >= 85 ? 5 : 2
                result.notes.append(DomainNote(title: roll >= 85 ? "Statement Win" : "Big Game Won", text: "The call worked under pressure. The program feels larger this week.", tags: [.career, .fame]))
            } else {
                specialCareer.coaching.seasonLosses = min(16, specialCareer.coaching.seasonLosses + 1)
                specialCareer.coaching.boosterPressure += 7
                specialCareer.heat += 3
                result.notes.append(DomainNote(title: "Game Slipped", text: "The call did not land. Everyone has the benefit of hindsight except you.", tags: [.career, .risk]))
            }
            specialCareer.burnout += 5
        case .handleBoosterPressure:
            activate(.coach, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.coaching.boosterPressure = max(0, specialCareer.coaching.boosterPressure - 14)
            specialCareer.coaching.programPrestige = max(0, specialCareer.coaching.programPrestige - 1)
            specialCareer.coaching.staffQuality += 2
            result.notes.append(DomainNote(title: "Boosters Managed", text: "The money people backed off for now. Nothing about it felt clean, but the program can breathe.", tags: [.career, .risk]))
        // P2: Dedicated politics static instant actions (always clickable when politics subdomain active)
        case .townHall:
            activate(.politics, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.politics.approvalRating = (specialCareer.politics.approvalRating + 6).clamped(to: 0...100)
            specialCareer.politics.charisma = min(100, specialCareer.politics.charisma + 3)
            specialCareer.heat = min(100, specialCareer.heat + 2)
            specialCareer.burnout += 4
            result.notes.append(DomainNote(title: "Town Hall", text: "You stood in the room with real people and took the questions. Some boos, some cheers — democracy is loud.", tags: [.career, .social]))
        case .politicalFundraise:
            activate(.politics, specialCareer: &specialCareer, dossier: childhoodDossier)
            let haul = 2_500 + specialCareer.politics.approvalRating * 40
            result.financeEffects = FinanceEffects(cashDelta: haul)
            specialCareer.politics.ethics = max(0, specialCareer.politics.ethics - 4)
            specialCareer.heat = min(100, specialCareer.heat + 5)
            result.notes.append(DomainNote(title: "Dialing for Dollars", text: "You asked for money from people who expect things. The war chest grew. So did the strings.", tags: [.career, .finance, .risk]))
        case .scandalResponse:
            activate(.politics, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.politics.approvalRating = max(0, specialCareer.politics.approvalRating - 8)
            specialCareer.politics.ethics = max(0, specialCareer.politics.ethics - 3)
            specialCareer.heat = max(0, specialCareer.heat - 10)
            result.notes.append(DomainNote(title: "Scandal Response", text: "You chose your words carefully on camera. The bleeding slowed. Trust took another hit.", tags: [.career, .risk]))
        case .policyPush:
            activate(.politics, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.politics.approvalRating = (specialCareer.politics.approvalRating + (specialCareer.politics.ethics > 55 ? 10 : 4)).clamped(to: 0...100)
            specialCareer.politics.policyLegacy = min(100, specialCareer.politics.policyLegacy + 7)
            specialCareer.burnout += 6
            result.notes.append(DomainNote(title: "Policy Push", text: "You spent capital on something that might actually matter. History may remember. Your poll numbers might not.", tags: [.career]))
        case .backroomDeal:
            activate(.politics, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.politics.donorBase = min(100, specialCareer.politics.donorBase + 8)
            specialCareer.politics.ethics = max(0, specialCareer.politics.ethics - 6)
            specialCareer.heat += 7
            result.notes.append(DomainNote(title: "Backroom Deal", text: "A quiet promise exchanged. Doors opened that shouldn't have. Power has a smell.", tags: [.career, .risk]))
        case .mediaHit:
            activate(.politics, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.politics.approvalRating = (specialCareer.politics.approvalRating + 7).clamped(to: 0...100)
            specialCareer.audience = min(100, specialCareer.audience + 6)
            specialCareer.heat = min(100, specialCareer.heat + 4)
            if specialCareer.politics.charisma < 45 {
                specialCareer.politics.approvalRating = max(0, specialCareer.politics.approvalRating - 3)
            }
            result.notes.append(DomainNote(title: "Big Media Hit", text: "You took the lights and the hard questions. The country saw you — for better or worse.", tags: [.career, .social]))
        case .takeAStand:
            activate(.politics, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.politics.ethics = min(100, specialCareer.politics.ethics + 8)
            specialCareer.politics.approvalRating = (specialCareer.politics.approvalRating + (specialCareer.politics.ethics > 60 ? 5 : -6)).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Public Stand", text: "You drew a line. Some cheered. Others turned away. Your soul feels cleaner even if the path got narrower.", tags: [.career, .risk]))
        case .attackOpponent:
            activate(.politics, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.politics.approvalRating = (specialCareer.politics.approvalRating + 4).clamped(to: 0...100)
            specialCareer.politics.ethics = max(0, specialCareer.politics.ethics - 7)
            specialCareer.heat += 9
            result.notes.append(DomainNote(title: "Opponent Attack", text: "You went for the throat on camera. The base loved it. The middle winced. The record now has your fingerprints.", tags: [.career, .risk]))
        case .intenseTraining:
            activate(.athlete, specialCareer: &specialCareer, dossier: childhoodDossier)
            // Phase S1 + S3a: Better starting athlete profile with potential seeded
            if specialCareer.track == .athlete {
                if specialCareer.athlete.peakPerformance < 55 {
                    specialCareer.athlete.peakPerformance = max(specialCareer.athlete.peakPerformance, 68)
                    specialCareer.athlete.durability = max(specialCareer.athlete.durability, 58)
                    specialCareer.athlete.sponsorshipTier = max(specialCareer.athlete.sponsorshipTier, 1)
                    specialCareer.athlete.fanLoyalty = max(specialCareer.athlete.fanLoyalty, 35)
                    var potential = Int.random(in: 68...88)
                    if let d = childhoodDossier {
                        // Dossier help: high physical aptitude directly boosts naturalPotential at entry
                        potential = max(potential, d.aptitudes.physical + Int.random(in: 5...15))
                    }
                    specialCareer.athlete.naturalPotential = max(specialCareer.athlete.naturalPotential, potential)
                    specialCareer.athlete.personalBrand = max(specialCareer.athlete.personalBrand, 22)
                }
            }
            specialCareer.audience += 12
            specialCareer.heat += 10
            specialCareer.burnout += 6
            result.healthEffects = HealthEffects(physical: 2, mental: nil, exercise: 5, nutrition: nil, stressManagement: -2)
            result.notes.append(DomainNote(title: "Training Camp", text: "You treated your body like a career asset. Performance rose, but so did the injury load.", tags: [.career, .health]))
        case .compete:
            activate(.athlete, specialCareer: &specialCareer, dossier: childhoodDossier)
            // Phase S1 + S3a: Better starting profile on first compete (potential seeded)
            if specialCareer.track == .athlete {
                if specialCareer.athlete.peakPerformance < 55 {
                    specialCareer.athlete.peakPerformance = max(specialCareer.athlete.peakPerformance, 65)
                    specialCareer.athlete.durability = max(specialCareer.athlete.durability, 55)
                    var potential = Int.random(in: 62...82)
                    if let d = childhoodDossier {
                        potential = max(potential, d.aptitudes.physical + Int.random(in: 0...12))
                    }
                    specialCareer.athlete.naturalPotential = max(specialCareer.athlete.naturalPotential, potential)
                    specialCareer.athlete.personalBrand = max(specialCareer.athlete.personalBrand, 18)
                }
            }
            let roll = normalizedRoll(player.age * 9 + player.looks + player.health + specialCareer.audience - specialCareer.heat)
            specialCareer.heat += roll < 35 ? 18 : 8
            specialCareer.burnout += 7
            if roll >= 72 {
                let payout = 1_200 + specialCareer.audience * 45
                specialCareer.fame += 12
                specialCareer.audience += 14
                specialCareer.lastPayout = payout
                result.financeEffects = FinanceEffects(cashDelta: payout)
                result.notes.append(DomainNote(title: "Competition Breakthrough", text: "The result traveled. Fans noticed, money followed, and the body paid part of the bill.", tags: [.career, .finance, .health]))
            } else {
                specialCareer.fame += 3
                result.healthEffects = HealthEffects(physical: -2, mental: nil, exercise: nil, nutrition: nil, stressManagement: -2)
                result.notes.append(DomainNote(title: "Competition Grind", text: "You entered the arena and came out with exposure, bruises, and no clean leap forward.", tags: [.career, .health]))
            }
        // S2: Dedicated athlete static instant actions (always clickable when athlete subdomain active)
        case .extraTrainingSession:
            activate(.athlete, specialCareer: &specialCareer, dossier: childhoodDossier)
            if specialCareer.track == .athlete {
                specialCareer.athlete.peakPerformance = min(100, specialCareer.athlete.peakPerformance + 3)
                specialCareer.athlete.durability = min(100, specialCareer.athlete.durability + 2)
            }
            specialCareer.burnout = min(100, specialCareer.burnout + 4)
            specialCareer.heat = min(100, specialCareer.heat + 2)
            result.healthEffects = HealthEffects(physical: -1, mental: nil, exercise: 4, nutrition: nil, stressManagement: -1)
            result.notes.append(DomainNote(title: "Extra Reps", text: "One more session in the dark. The body remembers. Small edges compound — your peak just ticked up.", tags: [.career, .health]))
        case .recoveryFocus:
            activate(.athlete, specialCareer: &specialCareer, dossier: childhoodDossier)
            if specialCareer.track == .athlete {
                specialCareer.athlete.durability = min(100, specialCareer.athlete.durability + 5)
                specialCareer.athlete.peakPerformance = max(0, specialCareer.athlete.peakPerformance - 1)
            }
            specialCareer.burnout = cappedBurnoutRecovery(current: specialCareer.burnout, relief: 8)
            result.healthEffects = HealthEffects(physical: 3, mental: 4, exercise: nil, nutrition: nil, stressManagement: 5)
            result.notes.append(DomainNote(title: "Recovery Block", text: "You chose the ice bath and the quiet over another grind. The machine stays intact longer.", tags: [.career, .health]))
        case .mediaAppearance:
            activate(.athlete, specialCareer: &specialCareer, dossier: childhoodDossier)
            if specialCareer.track == .athlete {
                specialCareer.athlete.fanLoyalty = min(100, specialCareer.athlete.fanLoyalty + 6)
                specialCareer.athlete.sponsorshipTier = min(5, specialCareer.athlete.sponsorshipTier + 1)
            }
            specialCareer.audience = min(100, specialCareer.audience + 8)
            specialCareer.fame = min(100, specialCareer.fame + 4)
            specialCareer.heat = min(100, specialCareer.heat + 3)
            result.notes.append(DomainNote(title: "Media Spot", text: "You showed up, smiled for the cameras, and let the story travel. Visibility is currency — sponsors notice.", tags: [.career]))
        case .teamBonding:
            activate(.athlete, specialCareer: &specialCareer, dossier: childhoodDossier)
            if specialCareer.track == .athlete {
                specialCareer.athlete.fanLoyalty = min(100, specialCareer.athlete.fanLoyalty + 3)
            }
            specialCareer.burnout = cappedBurnoutRecovery(current: specialCareer.burnout, relief: 5)
            career.relationshipSpillover = max(0, career.relationshipSpillover - 3)
            result.relationshipEffects = RelationshipEffects(meetNewFriend: true, friendChange: 1, startDating: nil, partnerChange: nil, setPartnerStage: nil, setCohabiting: nil, commitmentAlignmentChange: nil, loseFriend: nil, breakup: nil)
            result.notes.append(DomainNote(title: "Team Night", text: "You chose the locker room stories and the shared meal over solo film study. Morale and the invisible bonds rose.", tags: [.career, .relationships]))
        case .edgeProtocol:
            activate(.athlete, specialCareer: &specialCareer, dossier: childhoodDossier)
            if specialCareer.track == .athlete {
                specialCareer.athlete.peakPerformance = min(100, specialCareer.athlete.peakPerformance + 8)
                specialCareer.athlete.durability = max(10, specialCareer.athlete.durability - 6)
                specialCareer.athlete.injuryRisk = min(100, specialCareer.athlete.injuryRisk + 12)
            }
            specialCareer.heat = min(100, specialCareer.heat + 15)
            specialCareer.burnout = min(100, specialCareer.burnout + 9)
            specialCareer.fame = max(0, specialCareer.fame - 4) // whispers of something off
            result.healthEffects = HealthEffects(physical: -4, mental: -3, exercise: 2, nutrition: nil, stressManagement: -4, addCondition: "edge-related strain")
            result.notes.append(DomainNote(title: "Edge Taken", text: "You chose the shortcut that feels like a shortcut. The numbers spike now. The body keeps the receipt.", tags: [.career, .health, .risk]))
        case .gatherIntelligence:
            guard Self.qualificationIssue(
                for: .gatherIntelligence,
                state: stateProxy(player: player, career: career, specialCareer: specialCareer, finance: finance, dossier: childhoodDossier)
            ) == nil else { break }
            let enteredDiamond = activate(.shadowOperative, specialCareer: &specialCareer, dossier: childhoodDossier, entryAge: player.age)
            specialCareer.notoriety += 10
            specialCareer.heat += 14
            specialCareer.burnout += 6
            career.performance = (career.performance + 3).clamped(to: 0...100)
            if let d = childhoodDossier {
                // High social or entrepreneurial from dossier gives better starting network/ops for shadow
                if d.aptitudes.social > 55 {
                    specialCareer.enterprise.networkStrength = max(specialCareer.enterprise.networkStrength, d.aptitudes.social - 40)
                }
                if d.aptitudes.entrepreneurial > 55 {
                    specialCareer.enterprise.operationalSecurity = max(specialCareer.enterprise.operationalSecurity, 10)
                }
            }
            result.notes.append(DomainNote(title: "Leverage Built", text: "You learned where the bodies are buried. Access became leverage, and leverage became risk.", tags: [.career]))
            appendDiamondEntryNote(if: enteredDiamond, transitionCount: specialCareer.diamondTransitions, to: &result)
        case .exploitLeverage:
            guard specialCareer.track == .shadowOperative else { break }
            let payout = max(1_500, specialCareer.notoriety * 120)
            specialCareer.heat += 24
            specialCareer.notoriety += 8
            career.performance = (career.performance + 6).clamped(to: 0...100)
            result.financeEffects = FinanceEffects(cashDelta: payout)
            result.notes.append(DomainNote(title: "Leverage Cashed", text: "You played the information at the right moment. The gain was real, and so was the exposure.", tags: [.career, .finance]))
        case .dayTrade:
            // Note: qualification for dayTrade (trader start) should be checked before activate; here assume passed (Diamond gate in qual)
            let enteredDiamond = activate(.trader, specialCareer: &specialCareer, dossier: childhoodDossier, entryAge: player.age)
            let swing = normalizedRoll(player.age * 13 + specialCareer.yearsActive * 17 + player.smarts) - 50
            let stake = max(500, min(5_000, specialCareer.audience * 120))
            let cashDelta = (stake * swing) / 50
            specialCareer.audience = (specialCareer.audience + abs(swing) / 8).clamped(to: 0...100)
            specialCareer.heat += swing < 0 ? 16 : 9
            specialCareer.burnout += 8
            specialCareer.lastPayout = cashDelta
            if let d = childhoodDossier, d.aptitudes.entrepreneurial > 55 {
                // Entrepreneurial kids are better at reading volatility from day one
                specialCareer.enterprise.riskTolerance = max(specialCareer.enterprise.riskTolerance, d.aptitudes.entrepreneurial / 2)
            }
            result.financeEffects = FinanceEffects(cashDelta: cashDelta)
            result.notes.append(DomainNote(title: cashDelta >= 0 ? "Trading Win" : "Trading Loss", text: cashDelta >= 0 ? "You caught the volatility and turned attention into cash." : "The market moved faster than your conviction, and the loss followed you home.", tags: [.finance, .career]))
            appendDiamondEntryNote(if: enteredDiamond, transitionCount: specialCareer.diamondTransitions, to: &result)
        case .analyzeMarkets:
            activate(.trader, specialCareer: &specialCareer, dossier: childhoodDossier)
            specialCareer.fame += 2
            specialCareer.audience += 5
            specialCareer.heat = max(0, specialCareer.heat - 6)
            specialCareer.burnout += 2
            result.notes.append(DomainNote(title: "Market Edge", text: "You spent the year studying cycles instead of chasing every candle. The edge is quieter, but it compounds.", tags: [.finance, .career]))
        default: break
        }

        specialCareer.clamp()
        return result
    }

    private func resolveFounderYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, worldEra: WorldEra, dossier: ChildhoodDossier? = nil, result: inout DomainYearResult) {
        var f = specialCareer.founder
        f.clamp()

        var burnMultiplier = 1.0
        var tractionMultiplier = 1.0
        
        switch specialCareer.sector {
        case .semiconductors: burnMultiplier = 2.5; tractionMultiplier = 0.5
        case .restaurants: burnMultiplier = 0.8; tractionMultiplier = 1.5
        case .automobiles: burnMultiplier = 3.0; tractionMultiplier = 0.7
        case .gaming: burnMultiplier = 1.2; tractionMultiplier = 1.8
        case .general: break
        }

        // Econ1: WorldEra bidirectional coupling — capital environment, burn rate, and growth are macro-dependent
        let era = worldEra
        let isRecession = (era == .recession)
        let isBoom = (era == .bullMarket || era == .techBoom)
        let isInflation = (era == .highInflation)

        if isRecession {
            burnMultiplier += 0.4          // investors demand cuts, runway shortens
            tractionMultiplier -= 0.25     // capital is cautious, growth slows
        } else if isBoom {
            tractionMultiplier += 0.35     // easy money, user growth accelerates
            if era == .techBoom { tractionMultiplier += 0.25 }
        } else if isInflation {
            burnMultiplier += 0.35         // real costs (salaries, cloud, ads) rising faster than revenue
        }

        // P4: D4 life-shape tuning for founder risk/reward (driven stances = higher reward but burn; loose = safer but lower upside)
        // Proxy via personalLegend (built from "driven" focus) and mentalLoad
        if f.personalLegend > 50 {
            tractionMultiplier += 0.2 // driven shape compounds upside
            burnMultiplier += 0.15
        } else if f.founderMentalLoad > 60 {
            burnMultiplier += 0.25 // loose/ high load shape amplifies downside
        }

        // Dossier texture (origin -> special career payoff): entrepreneurial kids carry a quiet "I saw this coming" flavor in early founder years
        if let d = dossier, d.aptitudes.entrepreneurial >= 58, specialCareer.yearsActive < 4 {
            result.notes.append(DomainNote(
                title: "Childhood Edge",
                text: "You haggled over candy money at 9. The same instinct makes term sheets read a little clearer now.",
                tags: [.career]
            ))
        }
        
        for advisor in specialCareer.advisors {
            result.financeEffects = FinanceEffects(cashDelta: -(advisor.yearlyFee))
            switch advisor.specialty {
            case .growth: tractionMultiplier += 0.3
            case .strategy: burnMultiplier -= 0.2
            case .political: specialCareer.boardPressure = max(0, specialCareer.boardPressure - 10)
            }
        }

        // E1: FounderState-driven simulation
        // Vision helps traction and fundraising story
        let visionBonus = Double(f.vision - 50) / 120.0
        tractionMultiplier += visionBonus

        // Execution reduces burn and improves delivery
        let executionBonus = Double(f.execution - 50) / 140.0
        burnMultiplier -= executionBonus

        // Team health stabilizes and reduces board pressure
        if f.teamHealth >= 65 {
            specialCareer.boardPressure = max(0, specialCareer.boardPressure - 4)
        } else if f.teamHealth < 40 {
            specialCareer.boardPressure += 6
        }

        // Product stage drives audience/valuation growth
        let stageGrowth = max(3, Int(Double(f.productStage) * 0.08 * tractionMultiplier))
        specialCareer.audience = min(100, specialCareer.audience + stageGrowth)

        // Mental load increases risk and burnout
        specialCareer.burnout += max(2, f.founderMentalLoad / 12)
        if f.founderMentalLoad > 65 {
            specialCareer.heat += 4
        }

        // Competitive moat helps defend traction
        if f.competitiveMoat > 40 {
            tractionMultiplier += 0.15
        }

        // Key hires improve execution and culture over time
        if f.keyHires > 25 {
            f.execution = min(95, f.execution + 2)
            f.companyCulture = min(95, f.companyCulture + 1)
        }

        // Advance product stage based on traction + execution
        if specialCareer.audience > 35 && f.execution > 55 {
            f.productStage = min(100, f.productStage + max(2, (f.vision + f.execution) / 40))
        }

        // Board pressure evolution (E1)
        if specialCareer.heat >= 45 || specialCareer.fame < 15 || f.founderMentalLoad > 70 {
            specialCareer.boardPressure += Int.random(in: 8...18)
        } else {
            specialCareer.boardPressure = max(0, specialCareer.boardPressure - 6)
        }

        // Founder mental load slowly rises with high heat/burnout
        if specialCareer.burnout > 55 {
            f.founderMentalLoad = min(95, f.founderMentalLoad + 3)
        }

        // Sustained founder burnout surfaces board reality (two consecutive high-burn years)
        if specialCareer.burnout > 55 {
            if f.lastHighBurnoutAge > 0 && player.age - f.lastHighBurnoutAge <= 1 {
                specialCareer.boardPressure = min(100, specialCareer.boardPressure + 14)
                result.notes.append(DomainNote(
                    title: "Board Reality",
                    text: "Burnout isn't private anymore. The board sees the numbers and the empty chair at the table.",
                    tags: [.career, .risk]
                ))
            }
            f.lastHighBurnoutAge = player.age
        } else {
            f.lastHighBurnoutAge = 0
        }

        // Personal legend grows with strong audience + control
        if specialCareer.audience > 55 && f.control > 70 {
            f.personalLegend = min(95, f.personalLegend + 3)
        }

        // E3: Big founder success explodes visible lifestyle/prestige
        if specialCareer.audience >= 65 && f.personalLegend >= 50 {
            result.notes.append(DomainNote(title: "Founder Lifestyle", text: "The company is doing well enough that the world starts treating you differently. The cars, the dinners, the assumptions.", tags: [.finance, .social]))
        }

        // E4: Rich founder events and drama
        if Int.random(in: 0...100) < 18 {
            if f.companyCulture < 40 && f.teamHealth < 50 {
                result.notes.append(DomainNote(title: "Culture Crisis", text: "The team is burning out on the vision. Key people are quietly updating their resumes.", tags: [.career, .social]))
                f.teamHealth = max(10, f.teamHealth - 8)
                specialCareer.burnout += 6
            } else if f.keyHires >= 35 && specialCareer.audience >= 50 {
                result.notes.append(DomainNote(title: "Talent Poached", text: "A competitor just hired away your best engineer with a life-changing offer. The moat just got thinner.", tags: [.career, .risk]))
                f.competitiveMoat = max(5, f.competitiveMoat - 10)
            } else if specialCareer.audience >= 70 && f.execution >= 60 {
                result.notes.append(DomainNote(title: "Viral Moment", text: "The product caught fire overnight. New users are pouring in faster than the servers can handle.", tags: [.career, .progress]))
                specialCareer.audience = min(100, specialCareer.audience + 8)
                f.personalLegend = min(95, f.personalLegend + 5)
            }
        }

        // Econ1: Era-specific founder capital & drama events (the economy as co-founder and antagonist)
        if Int.random(in: 0...100) < 16 {
            if isRecession {
                if specialCareer.audience >= 40 {
                    result.notes.append(DomainNote(title: "Down Round Reality", text: "The only term sheets on the table are painful. Your valuation just took a real haircut.", tags: [.career, .risk]))
                    specialCareer.audience = max(15, specialCareer.audience - 12)
                    f.competitiveMoat = max(5, f.competitiveMoat - 6)
                } else if f.founderMentalLoad > 60 {
                    result.notes.append(DomainNote(title: "Runway Panic", text: "The market turned. You're cutting what you swore you never would. The team feels it.", tags: [.career, .social]))
                    f.teamHealth = max(10, f.teamHealth - 7)
                    specialCareer.burnout += 8
                }
            } else if isBoom {
                if f.personalLegend >= 35 && specialCareer.audience >= 35 {
                    result.notes.append(DomainNote(title: "Capital Flood", text: "Investors are writing checks to anything that moves. The round closed in a week at a valuation you didn't believe.", tags: [.career, .finance]))
                    specialCareer.audience = min(100, specialCareer.audience + 14)
                    f.competitiveMoat = min(95, f.competitiveMoat + 4)
                } else if f.keyHires > 20 {
                    result.notes.append(DomainNote(title: "Hyper-Competitive Poaching", text: "Every good engineer in the city has three offers. Your best people are being hunted in broad daylight.", tags: [.career, .risk]))
                    f.competitiveMoat = max(5, f.competitiveMoat - 8)
                }
            } else if isInflation && specialCareer.audience >= 30 {
                result.notes.append(DomainNote(title: "Cost Disease", text: "Salaries, cloud bills, and ads are all up 30%+. Growth looks the same but the burn feels different.", tags: [.career, .finance]))
                specialCareer.burnout += 5
            }
        }

        // Occasional acquihire or big partnership interest (late stage)
        if specialCareer.audience >= 55 && Int.random(in: 0...100) < 12 {
            result.notes.append(DomainNote(title: "Acquihire Interest", text: "A larger player reached out. They don't just want the product — they want you and the team.", tags: [.career, .finance]))
            specialCareer.heat += 10
        }

        // P3: Uniform 5-voice literary treatment for founder (like CE4 crime voices) — each year feels like a different genre of building
        if Int.random(in: 0...100) < 22 {
            let voice: String
            if f.vision >= 70 && f.personalLegend >= 40 {
                let voices = [
                    "You sketched the future on a napkin in 2012. The team is still arguing over the details you already solved in your head.",
                    "The vision was always bigger than the company. The company is finally catching up to the version of you that existed before the first hire.",
                    "People call it foresight. You call it refusing to accept the small map everyone else was handed."
                ]
                voice = voices.randomElement()!
            } else if f.execution >= 70 && f.teamHealth >= 50 {
                let voices = [
                    "You are the person who makes the impossible schedule possible. The product ships because you decide it will.",
                    "Grind is not glamorous. It is the only thing between the pitch deck and the thing that actually works.",
                    "The team trusts the process because the process has never failed them on your watch. Yet."
                ]
                voice = voices.randomElement()!
            } else if specialCareer.audience >= 60 {
                let voices = [
                    "You sell the dream better than anyone. The hard part is remembering which parts were the dream and which parts are now due.",
                    "The room leans in when you speak. The bank accounts lean in when the numbers speak. Both are temporary.",
                    "You became the face. The face became the brand. The brand now has opinions you didn't write."
                ]
                voice = voices.randomElement()!
            } else {
                let voices = [
                    "Another year of being the one who has to believe when no one else has data yet.",
                    "You are still the person who stays late after the meeting to fix what the meeting pretended was already fixed.",
                    "The vision is intact. The version of you that had it is starting to feel like a different person."
                ]
                voice = voices.randomElement()!
            }
            result.notes.append(DomainNote(title: "Founder's Voice", text: voice, tags: [.career]))
        }

        // Ouster
        if specialCareer.boardPressure >= 100 {
            // P3: richer "The End of the Road" with D4 life-shape + dossier modifiers (stance echo via legend)
            let shape = deriveSimpleFounderShape(founder: f, special: specialCareer)
            let driveEcho = f.personalLegend >= 60 ? " The drive that built it also burned the bridge." : ""
            let exitText = "The board ousted you. The company moves on without its founder. \(shape)\(driveEcho)"
            result.notes.append(DomainNote(title: "The Coup — End of the Road", text: exitText, tags: [.career, .progress]))
            exitTrack(on: &specialCareer)
            specialCareer.founder = f
            return
        }

        // Push founder legend into unified fame (E1 bridge to Fame Web)
        if f.personalLegend > 35 {
            specialCareer.fame = min(100, specialCareer.fame + max(1, f.personalLegend / 18))
        }

        specialCareer.founder = f
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)

        // P4-3: Founder variance & agency (swingy high-variance path). D4 shape: driven compounds upside but also burn (visible cost); loose amplifies downside risk.
        // Buffers: personalLegend can save you from total wipe; telegraph when founderMentalLoad high + low productStage.
        // Parity with regular: founders now have similar "safety floor" language as corporate/gig when things go south.
        let f2 = specialCareer.founder
        let shapeProxyF = (f2.personalLegend > 50 && f2.founderMentalLoad < 55) ? "driven" : (f2.founderMentalLoad > 65 ? "loose" : "steady")
        if f2.founderMentalLoad > 75 && f2.productStage < 30 && player.age > 35 {
            result.notes.append(DomainNote(title: "The Weight Shows", text: "The company is still growing, but the person holding it up is cracking. Something has to give.", tags: [.career, .health]))
            // Buffer: legend can buy one more year of runway
            if f2.personalLegend >= 45 {
                specialCareer.founder.productStage = max(specialCareer.founder.productStage, 28)
            }
        }
        if shapeProxyF == "driven" && f2.productStage > 40 {
            specialCareer.founder.productStage = min(100, f2.productStage + 2) // driven rewards stage
            specialCareer.founder.founderMentalLoad = min(100, f2.founderMentalLoad + 1) // but costs
        } else if shapeProxyF == "loose" && f2.productStage < 50 {
            specialCareer.founder.productStage = max(5, f2.productStage - 3) // loose punishes more
        }
        // P4 resilience divergence for founder kept light here (orchestrator safety nets + Progress spillover already handle grounded/resilient strongly for agency).
        if f2.personalLegend >= 60 {
            specialCareer.audience = min(100, specialCareer.audience + 1) // simple high-legend bump
        }
    }



    private func resolveEntertainmentYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, relationships: RelationshipState, result: inout DomainYearResult) {
        let breakoutSeed = player.age * 11 + player.looks * 3 + specialCareer.fame + specialCareer.audience - specialCareer.burnout
        let roll = normalizedRoll(breakoutSeed)
        let payout: Int
        if roll >= 88 {
            payout = 4000 + specialCareer.fame * 45 + specialCareer.audience * 25
            specialCareer.fame += 14
            specialCareer.audience += 16
        } else {
            payout = roll >= 48 ? (700 + specialCareer.audience * 8) : 0
            specialCareer.fame += roll >= 48 ? 5 : -2
            specialCareer.audience += roll >= 48 ? 7 : -1
        }
        specialCareer.lastPayout = payout
        result.financeEffects = FinanceEffects(cashDelta: payout)
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
    }

    private func resolveMovieActorYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, worldEra: WorldEra, result: inout DomainYearResult) {
        var actor = specialCareer.movieActor
        actor.clamp()

        let marketLift = (worldEra == .bullMarket || worldEra == .techBoom) ? 1.15 : (worldEra == .recession ? 0.82 : 1.0)
        var residuals = actor.roleCredits * 220 + actor.boxOfficeDraw * 75 + actor.publicImage * 20
        residuals = Int(Double(residuals) * marketLift)
        residuals = max(0, residuals - actor.typecastRisk * 18)

        actor.lastRolePayout = residuals
        actor.auditionNetwork = (actor.auditionNetwork + actor.agentQuality / 25 + (actor.publicImage - 45) / 18).clamped(to: 0...100)
        actor.boxOfficeDraw = (actor.boxOfficeDraw + actor.roleCredits / 5 + (actor.screenPresence - 50) / 14 - (actor.typecastRisk >= 65 ? 3 : 0)).clamped(to: 0...100)
        actor.typecastRisk = (actor.typecastRisk + (actor.roleCredits >= 4 ? 2 : -1)).clamped(to: 0...100)

        if actor.boxOfficeDraw >= 35 || actor.roleCredits >= 4 {
            specialCareer.fame = min(100, specialCareer.fame + max(1, actor.boxOfficeDraw / 18))
            specialCareer.audience = min(100, specialCareer.audience + max(1, actor.roleCredits / 2))
        }
        if actor.publicImage < 30 || actor.typecastRisk >= 75 {
            specialCareer.heat = min(100, specialCareer.heat + 3)
        }
        specialCareer.burnout += max(2, actor.auditionNetwork / 22 + actor.typecastRisk / 28)
        specialCareer.lastPayout = residuals
        specialCareer.movieActor = actor
        result.financeEffects = FinanceEffects(cashDelta: residuals)

        if Int.random(in: 0...100) < 14 {
            if actor.boxOfficeDraw >= 45 && actor.publicImage >= 50 {
                result.notes.append(DomainNote(title: "Casting Heat", text: "The rooms are warmer now. Your name is becoming easier to say yes to.", tags: [.career, .fame]))
                actor.agentQuality = min(100, actor.agentQuality + 6)
            } else if actor.typecastRisk >= 60 {
                result.notes.append(DomainNote(title: "Typecast Talk", text: "Casting keeps seeing one version of you. The work is paying, but the lane is narrowing.", tags: [.career, .risk]))
                actor.typecastRisk = min(100, actor.typecastRisk + 6)
            }
            specialCareer.movieActor = actor
        }

        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
    }

    private func resolveMovieProducerYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, worldEra: WorldEra, result: inout DomainYearResult) {
        var film = specialCareer.movieProducer
        film.clamp()

        let marketLift = (worldEra == .bullMarket || worldEra == .techBoom) ? 1.18 : (worldEra == .recession ? 0.78 : 1.0)
        var gross = film.backendCatalog * 140 + film.prestige * 85 + film.distributionLeverage * 75 + film.studioTrust * 45
        gross = Int(Double(gross) * marketLift)
        let overhead = 2_500 + film.slateCount * 1_250 + film.productionChaos * 45
        let net = max(-12_000, gross - overhead)

        film.lastFilmPayout = max(0, net)
        film.developmentQuality = (film.developmentQuality + film.slateCount / 2 - (film.productionChaos >= 65 ? 3 : 0)).clamped(to: 0...100)
        film.distributionLeverage = (film.distributionLeverage + film.backendCatalog / 18 + (film.prestige - 45) / 14).clamped(to: 0...100)
        film.studioTrust = (film.studioTrust + (film.budgetControl - 45) / 14 - (film.productionChaos >= 70 ? 5 : 0)).clamped(to: 0...100)
        film.productionChaos = (film.productionChaos + film.slateCount * 2 - film.budgetControl / 25).clamped(to: 0...100)

        if film.prestige >= 45 || film.backendCatalog >= 35 {
            specialCareer.fame = min(100, specialCareer.fame + max(1, (film.prestige + film.backendCatalog) / 35))
            specialCareer.audience = min(100, specialCareer.audience + max(1, film.distributionLeverage / 25))
        }
        if film.productionChaos >= 65 {
            specialCareer.heat = min(100, specialCareer.heat + film.productionChaos / 22)
        }
        // CT4-2: Diamond spectacular failure risk - public chaos scars legacy harder
        if film.productionChaos >= 80 {
            specialCareer.heat = min(100, specialCareer.heat + 8)
            // will feed into "paid_the_price" or empire scars in legacy
        }
        // CT4-2: Diamond balance - higher personal cost for empire building
        specialCareer.burnout += max(6, film.productionChaos / 15 + film.slateCount * 2)
        specialCareer.lastPayout = max(0, net)
        specialCareer.movieProducer = film
        result.financeEffects = FinanceEffects(cashDelta: net)

        if Int.random(in: 0...100) < 16 {
            if film.prestige >= 60 && film.distributionLeverage >= 45 {
                result.notes.append(DomainNote(title: "Producer Heat", text: "The town believes you can get movies finished. That belief is its own currency.", tags: [.career, .fame]))
                film.studioTrust = min(100, film.studioTrust + 7)
                film.backendCatalog = min(100, film.backendCatalog + 4)
            } else if film.productionChaos >= 70 {
                result.notes.append(DomainNote(title: "Set Rumors", text: "Stories from the production are moving faster than the film itself.", tags: [.career, .risk]))
                specialCareer.heat = min(100, specialCareer.heat + 6)
            }
            specialCareer.movieProducer = film
        }

        // CT2 (CareerTiers2): Empire layer for Diamond Movie Producer
        // Empire metrics: prestige + backend as cultural reach; delegation (slate) with shape/res mod
        film.prestige = min(100, film.prestige + 1)
        if film.backendCatalog >= 50 {
            film.distributionLeverage = min(100, film.distributionLeverage + 2) // empire distribution compounds
        }
        let shapeProxyFilm = (film.prestige > 70 && film.backendCatalog > 50) ? "driven" : (film.productionChaos > 70 ? "loose" : "steady")
        if shapeProxyFilm == "driven" {
            film.studioTrust = min(100, film.studioTrust + 3)
            film.productionChaos = min(100, film.productionChaos + 2) // driven empire has creative chaos but grows trust
        } else if shapeProxyFilm == "loose" {
            film.studioTrust = max(10, film.studioTrust - 2)
        }
        // resilience modulation (grounded) for empire - light here
        film.budgetControl = min(100, film.budgetControl + 1)
        specialCareer.movieProducer = film

        // CT3-1: Richer Diamond empire voice for Movie Producer (5-flavor "The Slate" treatment, extending P3 uniform literary voice)
        if Int.random(in: 0...100) < 18 {
            let voice: String
            if film.prestige >= 70 && film.backendCatalog >= 55 {
                let voices = [
                    "The Slate has become a signature. Your name is in the fine print of half the good films this decade.",
                    "You don't direct anymore. You decide what gets directed. That is power of a different order.",
                    "The studio still carries your taste even when you're not in the room. The empire remembers its founder."
                ]
                voice = voices.randomElement()!
            } else if film.productionChaos >= 60 {
                let voices = [
                    "Every film is a war. You are the general who never appears on set but signs the checks that decide the casualties.",
                    "The chaos is the price of the vision. You learned to love the noise — or at least to profit from it.",
                    "People still tell stories about the productions you 'saved'. They never mention the ones you quietly let burn."
                ]
                voice = voices.randomElement()!
            } else {
                let voices = [
                    "You are building a library that will outlive every actor who ever stood in front of your camera.",
                    "The money moves. The taste stays. That is how empires are made in this town.",
                    "One day someone will watch a film and say 'this feels like a [YourName] picture' without knowing why the light hits that way."
                ]
                voice = voices.randomElement()!
            }
            result.notes.append(DomainNote(title: "The Slate", text: voice, tags: [.career, .fame]))
        }

        // CT3-2: Diamond exit for Movie Producer — feels like handing off an institution
        if film.productionChaos >= 85 || film.studioTrust <= 20 {
            let exitText = film.prestige >= 70
                ? "The studio you built still carries your name in the credits decades later. The board runs it now, but the taste, the eye, the impossible standards — those are yours forever. You became architecture."
                : "The last slate never got financed. The town moved on. You are a cautionary story told over expensive drinks: 'He had the taste. He just couldn't keep the machine running.'"
            result.notes.append(DomainNote(title: "The End of the Slate — End of the Road", text: exitText, tags: [.career, .progress]))
            exitTrack(on: &specialCareer)
            specialCareer.movieProducer = film
            return
        }

        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
    }

    private func resolveMusicProducerYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, worldEra: WorldEra, result: inout DomainYearResult) {
        var producer = specialCareer.musicProducer
        producer.clamp()

        let isBoom = worldEra == .bullMarket || worldEra == .techBoom
        let isRecession = worldEra == .recession
        var royalties = producer.royaltyCatalog * 90 + producer.credits * 160 + producer.demand * 45
        if isBoom { royalties = Int(Double(royalties) * 1.18) }
        if isRecession { royalties = Int(Double(royalties) * 0.84) }
        royalties -= producer.creditDisputes * 22
        royalties = max(0, royalties)

        producer.lastPlacementValue = royalties
        producer.demand = (producer.demand + (producer.sonicSignature - 45) / 10 + (producer.network - 45) / 12 - (producer.creditDisputes >= 55 ? 4 : 0)).clamped(to: 0...100)
        producer.royaltyCatalog = (producer.royaltyCatalog + max(0, producer.credits / 5) - (producer.creditDisputes >= 70 ? 3 : 0)).clamped(to: 0...100)
        producer.creditDisputes = (producer.creditDisputes + (producer.demand >= 60 ? 3 : -2)).clamped(to: 0...100)

        if producer.demand >= 50 || producer.sonicSignature >= 60 {
            specialCareer.fame = min(100, specialCareer.fame + max(1, (producer.demand + producer.sonicSignature) / 45))
            specialCareer.audience = min(100, specialCareer.audience + max(1, producer.credits / 4))
        }
        if producer.creditDisputes >= 60 {
            specialCareer.notoriety = min(100, specialCareer.notoriety + producer.creditDisputes / 20)
        }
        specialCareer.burnout += max(2, producer.demand / 18 + producer.creditDisputes / 25)
        specialCareer.lastPayout = royalties
        result.financeEffects = FinanceEffects(cashDelta: royalties)

        if Int.random(in: 0...100) < 16 {
            if producer.demand >= 55 && producer.sonicSignature >= 55 {
                result.notes.append(DomainNote(title: "Producer Tag Travels", text: "People are recognizing the sound before they know the record. Your name is becoming a signal.", tags: [.career, .fame]))
                producer.demand = min(100, producer.demand + 8)
                producer.royaltyCatalog = min(100, producer.royaltyCatalog + 5)
            } else if producer.creditDisputes >= 55 {
                result.notes.append(DomainNote(title: "Credit Dispute", text: "A record moved without the split sheet you expected. The money is suddenly an argument.", tags: [.career, .finance, .risk]))
                producer.creditDisputes = min(100, producer.creditDisputes + 8)
            }
        }

        specialCareer.musicProducer = producer
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
    }

    private func resolveRecordLabelYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, worldEra: WorldEra, result: inout DomainYearResult) {
        var label = specialCareer.recordLabel
        label.clamp()

        if label.roster.isEmpty {
            label.roster.append(makeLabelArtist(seed: player.age * 41 + 9, prestige: label.labelPrestige, trust: label.artistTrust))
        }

        let isBoom = worldEra == .bullMarket || worldEra == .techBoom
        let isRecession = worldEra == .recession
        let isInflation = worldEra == .highInflation
        let payoutShare: Double
        switch label.artistPayoutPolicy {
        case .exploitative: payoutShare = 0.22
        case .standard: payoutShare = 0.38
        case .artistFriendly: payoutShare = 0.52
        }

        var gross = label.catalogStrength * 65 + label.tourMachine * 35 + label.labelPrestige * 45
        gross += label.roster.reduce(0) { $0 + $1.popularity * 18 + $1.catalogCount * 250 }
        if isBoom { gross = Int(Double(gross) * 1.18) }
        if isRecession { gross = Int(Double(gross) * 0.82) }
        if isInflation { gross = Int(Double(gross) * 0.92) }

        let artistShare = Int(Double(max(0, gross)) * payoutShare)
        let overhead = 1_500 + label.roster.count * (isInflation ? 900 : 650) + label.cashflowPressure * 25
        let net = max(-8_000, gross - artistShare - overhead)
        specialCareer.lastPayout = max(0, net)
        result.financeEffects = FinanceEffects(cashDelta: net)

        for index in label.roster.indices {
            let popularityDrift = (label.roster[index].talent - 45) / 15 + (label.labelPrestige - 40) / 20
            label.roster[index].popularity = (label.roster[index].popularity + popularityDrift).clamped(to: 0...100)
            label.roster[index].yearlyEarnings = max(0, artistShare / max(1, label.roster.count))
            label.roster[index].morale += label.artistPayoutPolicy == .artistFriendly ? 3 : (label.artistPayoutPolicy == .exploitative ? -6 : -1)
            label.roster[index].morale -= label.industryHeat >= 65 ? 4 : 0
            label.roster[index].tourReadiness = min(100, label.roster[index].tourReadiness + 5)
        }

        label.catalogStrength = (label.catalogStrength + max(0, label.roster.reduce(0) { $0 + $1.catalogCount } / 3) - (label.industryHeat >= 75 ? 3 : 0)).clamped(to: 0...100)
        label.labelPrestige = (label.labelPrestige + (net > 4_000 ? 3 : 0) + (label.artistTrust >= 70 ? 1 : 0)).clamped(to: 0...100)
        label.cashflowPressure = (label.cashflowPressure + (net < 0 ? 8 : -5) + (isInflation ? 3 : 0)).clamped(to: 0...100)
        label.artistTrust = (label.artistTrust + (label.artistPayoutPolicy == .artistFriendly ? 4 : 0) - (label.cashflowPressure >= 70 ? 3 : 0)).clamped(to: 0...100)
        label.industryHeat = (label.industryHeat + (label.artistPayoutPolicy == .exploitative ? 5 : -2) + (label.artistTrust < 35 ? 4 : 0)).clamped(to: 0...100)

        if label.labelPrestige >= 55 || label.catalogStrength >= 50 {
            specialCareer.fame = min(100, specialCareer.fame + max(1, (label.labelPrestige + label.catalogStrength) / 35))
            specialCareer.audience = min(100, specialCareer.audience + max(1, label.roster.count))
        }
        if label.industryHeat >= 55 {
            specialCareer.notoriety = min(100, specialCareer.notoriety + label.industryHeat / 18)
        }
        specialCareer.burnout += max(2, label.roster.count + label.cashflowPressure / 18)

        if Int.random(in: 0...100) < 18 {
            if let index = label.roster.indices.max(by: { label.roster[$0].popularity < label.roster[$1].popularity }), label.roster[index].popularity >= 62 {
                result.notes.append(DomainNote(title: "Roster Breakout", text: "\(label.roster[index].name) is suddenly everywhere. The catalog feels less like inventory and more like leverage.", tags: [.career, .finance]))
                label.catalogStrength = min(100, label.catalogStrength + 8)
                label.labelPrestige = min(100, label.labelPrestige + 6)
            } else if label.artistTrust < 35 || label.industryHeat >= 70 {
                result.notes.append(DomainNote(title: "Artist Revolt", text: "The roster is comparing statements and telling stories. The label's reputation is getting noisy.", tags: [.career, .risk]))
                label.artistTrust = max(0, label.artistTrust - 8)
                label.industryHeat = min(100, label.industryHeat + 8)
            } else if label.cashflowPressure >= 70 {
                result.notes.append(DomainNote(title: "Cashflow Squeeze", text: "Recording costs, tour deposits, and delayed royalties all arrived in the same month.", tags: [.career, .finance]))
                specialCareer.burnout += 5
            }
        }

        if let exitIndex = label.roster.firstIndex(where: { $0.morale <= 12 || ($0.contractFairness < 25 && label.industryHeat >= 60) }) {
            let artistName = label.roster[exitIndex].name
            label.roster.remove(at: exitIndex)
            label.artistTrust = max(0, label.artistTrust - 10)
            label.catalogStrength = max(0, label.catalogStrength - 6)
            result.notes.append(DomainNote(title: "Artist Walked", text: "\(artistName) left the label. The catalog still exists, but the future just got smaller.", tags: [.career, .risk]))
        }

        if label.artistTrust <= 10 && label.industryHeat >= 90 {
            result.notes.append(DomainNote(title: "Label Implosion", text: "The roster left, the reputation curdled, and the industry stopped taking your calls.", tags: [.career, .progress]))
            specialCareer.recordLabel = label
            exitTrack(on: &specialCareer)
            return
        }

        specialCareer.recordLabel = label
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
    }

    private func resolveCoachingYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, worldEra: WorldEra, result: inout DomainYearResult) {
        var coach = specialCareer.coaching
        coach.clamp()

        let pressureDrag = coach.boosterPressure / 5
        let seasonPower = coach.rosterTalent + coach.playerDevelopment + coach.schemeFit + coach.staffQuality + coach.lockerRoom + player.smarts / 2 - pressureDrag
        let roll = normalizedRoll(player.age * 29 + seasonPower + specialCareer.yearsActive * 13)
        let wins = ((seasonPower / 34) + roll / 18).clamped(to: 2...14)
        let losses = max(0, 12 - min(12, wins))
        coach.seasonWins = wins
        coach.seasonLosses = losses

        let strongSeason = wins >= 9
        let badSeason = wins <= 4
        var contract = 45_000 + coach.programLevel * 35_000 + coach.programPrestige * 900 + max(0, wins - 6) * 7_500
        if worldEra == .recession { contract = Int(Double(contract) * 0.92) }
        if worldEra == .bullMarket || worldEra == .techBoom { contract = Int(Double(contract) * 1.08) }
        coach.contractValue = contract
        result.financeEffects = FinanceEffects(cashDelta: contract)
        specialCareer.lastPayout = contract

        coach.programPrestige += strongSeason ? 7 : (badSeason ? -5 : 2)
        coach.recruitingReach += strongSeason ? 5 : (badSeason ? -3 : 1)
        coach.lockerRoom += strongSeason ? 4 : (badSeason ? -6 : -1)
        coach.boosterPressure += strongSeason ? 4 : (badSeason ? 12 : 5)
        coach.rosterTalent += max(-4, (coach.recruitingReach - 45) / 12)
        coach.playerDevelopment += (coach.staffQuality - 45) / 15
        coach.schemeFit += (coach.playerDevelopment - 45) / 18

        if strongSeason {
            specialCareer.fame = min(100, specialCareer.fame + max(2, wins / 2))
            specialCareer.audience = min(100, specialCareer.audience + 5)
            result.notes.append(DomainNote(title: "Winning Season", text: "Your program went \(wins)-\(losses). Recruits noticed, boosters got louder, and the sideline feels less temporary.", tags: [.career, .fame]))
        } else if badSeason {
            specialCareer.heat = min(100, specialCareer.heat + 8)
            result.notes.append(DomainNote(title: "Losing Season", text: "Your program went \(wins)-\(losses). The film is ugly, the room is tense, and every donor suddenly has football opinions.", tags: [.career, .risk]))
        } else {
            result.notes.append(DomainNote(title: "Season Summary", text: "Your program went \(wins)-\(losses). The year gave you evidence, not certainty.", tags: [.career, .progress]))
        }

        if coach.programPrestige >= 70 && coach.programLevel < 4 {
            coach.programLevel += 1
            coach.programPrestige = max(45, coach.programPrestige - 10)
            result.notes.append(DomainNote(title: "Bigger Program Called", text: "The offer is larger, the roster is better, and the knives are sharper. You moved up.", tags: [.career, .progress]))
        }

        if coach.boosterPressure >= 92 && badSeason {
            result.notes.append(DomainNote(title: "Coach Fired", text: "The program moved on. The record, the donors, and the noise finally became one decision.", tags: [.career, .progress]))
            specialCareer.coaching = coach
            exitTrack(on: &specialCareer)
            career.status = .unemployed
            career.roleID = nil
            career.annualIncome = 0
            return
        }
        // CT4-2: Diamond spectacular public failure risk for coach - scars legacy
        if coach.boosterPressure >= 85 && badSeason {
            specialCareer.heat += 10
        }

        // CT3-2: Diamond exit for Program Coach — institutional hand-off / dynasty feeling
        if coach.programPrestige >= 85 && coach.seasonWins >= 10 {
            let exitText = "You stepped down at the top. The program you built still wins with your system in the binder. The next coach calls it 'the way we do things here.' You became tradition."
            result.notes.append(DomainNote(title: "The End of the Whistle — End of the Road", text: exitText, tags: [.career, .progress]))
            exitTrack(on: &specialCareer)
            specialCareer.coaching = coach
            return
        }

        // CT2 (CareerTiers2): Empire layer for Diamond Program Coach
        // Empire: programPrestige + recruiting as legacy reach; delegation (staff, system) with shape/res mod
        coach.programPrestige = min(100, coach.programPrestige + 1)
        if coach.rosterTalent >= 60 {
            coach.recruitingReach = min(100, coach.recruitingReach + 2) // empire recruiting compounds
            coach.playerDevelopment = min(100, coach.playerDevelopment + 1)
        }
        let shapeProxyCoach = (coach.programPrestige > 70 && coach.rosterTalent > 65) ? "driven" : (coach.boosterPressure > 70 ? "loose" : "steady")
        if shapeProxyCoach == "driven" {
            coach.schemeFit = min(100, coach.schemeFit + 2)
            coach.boosterPressure = min(100, coach.boosterPressure + 2) // driven empire grows pressure but prestige
        } else if shapeProxyCoach == "loose" {
            coach.lockerRoom = max(10, coach.lockerRoom - 3)
        }
        // resilience modulation (grounded) for empire - light here
        coach.staffQuality = min(100, coach.staffQuality + 1)
        specialCareer.coaching = coach

        // CT3-1: Richer Diamond empire voice for Program Coach ("The Program" 5-flavor treatment)
        if Int.random(in: 0...100) < 18 {
            let voice: String
            if coach.programPrestige >= 70 && coach.seasonWins >= 8 {
                let voices = [
                    "The system you installed is still being taught in other programs. Your name is in the playbook even if they never say it out loud.",
                    "You don't coach players anymore. You coach the coaches who coach the players. The empire is the curriculum.",
                    "Alumni still send you letters. Some of them are now on the other sideline, running versions of what you built."
                ]
                voice = voices.randomElement()!
            } else if coach.boosterPressure >= 70 {
                let voices = [
                    "The money people own the scoreboard, but you own the identity of the program. That is the only power that lasts.",
                    "Every season is a negotiation between what the boosters want and what the game actually needs. You learned to win the negotiation.",
                    "The kids come for the ring. They stay for the culture you built when no one was watching."
                ]
                voice = voices.randomElement()!
            } else {
                let voices = [
                    "You are not building a team. You are building a place that remembers how to win even after you're gone.",
                    "The whistle hangs differently when the program has your fingerprints on every drill, every meeting, every quiet conversation in the weight room.",
                    "One day a young coach will steal your system and call it his own. That is how dynasties survive."
                ]
                voice = voices.randomElement()!
            }
            result.notes.append(DomainNote(title: "The Program", text: voice, tags: [.career, .fame]))
        }

        // CT4-2: Diamond balance - higher personal cost for empire building (program pressure)
        specialCareer.burnout += max(6, coach.boosterPressure / 14 + coach.programLevel * 2)
        specialCareer.coaching = coach
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
    }

    // C1: Basic foundation for Content Creator yearly simulation
    private func resolveContentCreatorYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, worldEra: WorldEra, result: inout DomainYearResult) {
        var c = specialCareer.creator
        c.clamp()

        // Econ1: WorldEra bidirectional coupling — the creator economy is extremely sensitive to macro conditions
        let era = worldEra
        let isRecession = (era == .recession)
        let isBoom = (era == .bullMarket || era == .techBoom)
        let isInflation = (era == .highInflation)
        var eraAlgoMod = 0
        var eraBrandMod = 0
        var eraBurnMod = 0
        var eraAudienceMod = 0
        switch era {
        case .recession:
            // Recession favors "relatable struggle", authenticity, dupe culture, cheap entertainment
            eraAlgoMod = (c.contentQuality > 60 && c.personalBrand > 50) ? -6 : 5   // polished aspirational drops, raw/authentic rises
            eraBrandMod = -7
            eraBurnMod = -2   // ironically slightly less pressure when everyone's broke
            eraAudienceMod = (c.personalBrand < 40) ? 3 : -2
        case .bullMarket, .techBoom:
            // Boom rewards aspiration, luxury, "get rich" / lifestyle porn, high-production value
            eraAlgoMod = (c.personalBrand >= 55) ? 8 : -3
            eraBrandMod = 9
            eraBurnMod = 4    // "always on" hustle culture is rewarded and exhausting
            eraAudienceMod = 2
        case .highInflation:
            eraAlgoMod = (c.contentQuality < 45) ? 4 : -2 // "how to survive" content wins
            eraBrandMod = -4
            eraBurnMod = 1
        case .pandemic:
            eraAlgoMod = 6    // long-form, indoor, comfort content dominated
            eraBrandMod = 3
            eraBurnMod = 2
        case .wartime:
            eraAlgoMod = -3
            eraBrandMod = -5
            eraAudienceMod = 1
        default:
            break
        }

        // Algorithm swing (core mechanic) + era
        let algoSwing = Int.random(in: -15...18) + (c.consistency - 50) / 4 + (c.contentQuality - 50) / 5 + eraAlgoMod
        c.algorithmFavor = (c.algorithmFavor + algoSwing).clamped(to: 10...95)

        // Audience growth/decline based on algorithm + personal brand + era
        let growth = max(-8, Int(Double(c.algorithmFavor - 40) * 0.25 + Double(c.personalBrand - 40) * 0.15) + eraAudienceMod)
        c.audience = (c.audience + growth).clamped(to: 0...100)

        // Brand deals scale with audience and personal brand + brutal era swings
        var brandSwing = max(1, (c.audience + c.personalBrand) / 30)
        brandSwing += eraBrandMod
        if c.audience >= 30 && c.personalBrand >= 45 {
            c.brandDealValue = min(100, c.brandDealValue + brandSwing)
        } else if isRecession && c.brandDealValue > 20 {
            c.brandDealValue = max(10, c.brandDealValue - 4)
        }

        // Burnout and cancellation risk + era pressure
        c.burnout = min(95, c.burnout + max(1, (c.audience / 12) - (c.consistency / 8) + eraBurnMod))
        if c.personalBrand < 35 && c.audience >= 40 {
            c.cancellationRisk = min(90, c.cancellationRisk + 6)
        } else {
            c.cancellationRisk = max(5, c.cancellationRisk - 3)
        }

        // C3: Stronger health impact from creator burnout
        if c.burnout >= 60 {
            let mentalTax = (c.burnout - 55) / 5
            result.healthEffects = HealthEffects(mental: -mentalTax, stressManagement: -mentalTax)
        }

        // Feed into unified fame (C1 bridge)
        let fameGain = max(0, (c.audience + c.personalBrand) / 7)
        specialCareer.fame = min(100, specialCareer.fame + fameGain)
        if c.cancellationRisk > 55 {
            specialCareer.notoriety = min(100, specialCareer.notoriety + 4)
        }

        // C4: Rich platform and career events
        if Int.random(in: 0...100) < 16 {
            if c.algorithmFavor >= 65 && c.audience >= 25 {
                result.notes.append(DomainNote(title: "Viral Hit", text: "One piece of content exploded. New followers are pouring in, and brands are suddenly interested.", tags: [.career, .social]))
                c.audience = min(100, c.audience + 12)
                c.personalBrand = min(100, c.personalBrand + 4)
            } else if c.cancellationRisk >= 50 {
                result.notes.append(DomainNote(title: "Cancellation Pile-on", text: "Old clips resurfaced. The comments are brutal. Sponsors are pausing.", tags: [.career, .risk]))
                c.audience = max(5, c.audience - 15)
                c.cancellationRisk = min(95, c.cancellationRisk + 10)
                c.personalBrand = max(10, c.personalBrand - 8)
            } else if c.algorithmFavor < 30 && c.audience >= 40 {
                result.notes.append(DomainNote(title: "Algorithm Change", text: "The platform tweaked its recommendation engine. Your reach collapsed overnight.", tags: [.career, .risk]))
                c.audience = max(10, c.audience - 18)
                c.algorithmFavor = min(95, c.algorithmFavor + 10) // forces adaptation
            } else if c.audience >= 60 && c.personalBrand >= 45 && Int.random(in: 0...100) < 40 {
                result.notes.append(DomainNote(title: "The Big Brand Deal", text: "A major company wants you as the face of their campaign. The money is life-changing.", tags: [.career, .finance]))
                c.brandDealValue = min(100, c.brandDealValue + 15)
                c.personalBrand = max(15, c.personalBrand - 5) // slight sellout hit
            } else if c.audience >= 55 && c.burnout >= 50 {
                result.notes.append(DomainNote(title: "I Peaked", text: "You look at the numbers and realize the best version of this chapter might already be behind you.", tags: [.career, .progress]))
                c.personalBrand = max(20, c.personalBrand - 4)
            }
        }

        // Comeback arc possibility (high burnout + decent brand can recover)
        if c.burnout >= 65 && c.personalBrand >= 40 && Int.random(in: 0...100) < 10 {
            result.notes.append(DomainNote(title: "Comeback Arc", text: "You disappeared for a bit, then dropped something honest. The audience came back stronger.", tags: [.career, .progress]))
            c.burnout = max(20, c.burnout - 20)
            c.audience = min(100, c.audience + 8)
            c.personalBrand = min(100, c.personalBrand + 6)
        }

        // Econ1: Deep era-specific creator economy events + narrative (recession authenticity vs boom excess)
        if Int.random(in: 0...100) < 17 {
            if isRecession {
                if c.personalBrand < 45 && c.audience >= 25 {
                    result.notes.append(DomainNote(title: "Recession Authenticity Wins", text: "Your 'we're all struggling' content is resonating. Brands are pulling back but the audience feels seen.", tags: [.career, .social]))
                    c.algorithmFavor = min(95, c.algorithmFavor + 7)
                    c.personalBrand = min(100, c.personalBrand + 3)
                } else if c.brandDealValue >= 45 {
                    result.notes.append(DomainNote(title: "Sponsor Exodus", text: "The big deals dried up overnight. You're suddenly 'too expensive' for the moment.", tags: [.career, .risk]))
                    c.brandDealValue = max(15, c.brandDealValue - 12)
                    c.audience = max(10, c.audience - 5)
                }
            } else if isBoom {
                if c.personalBrand >= 50 && c.audience >= 30 {
                    result.notes.append(DomainNote(title: "Creator Economy Gold Rush", text: "Brands are throwing money at anyone with an audience. The deals are stupid good — and everyone wants a piece of you.", tags: [.career, .finance]))
                    c.brandDealValue = min(100, c.brandDealValue + 14)
                    c.burnout = min(95, c.burnout + 5)
                } else if c.contentQuality >= 60 {
                    result.notes.append(DomainNote(title: "Aspiration Content Explodes", text: "Everyone wants the fantasy. Your high-production 'day in the life' videos are printing money.", tags: [.career, .progress]))
                    c.audience = min(100, c.audience + 9)
                }
            } else if isInflation {
                result.notes.append(DomainNote(title: "Dupe Culture Moment", text: "People can't afford the real thing. Your 'get the look for less' content is suddenly everywhere.", tags: [.career]))
                c.algorithmFavor = min(95, c.algorithmFavor + 5)
            }
        }

        // Era-tinged FameProfile flavor
        if isRecession && c.audience >= 45 && c.personalBrand < 40 && Int.random(in: 0...100) < 11 {
            result.notes.append(DomainNote(title: "Voice of the Squeeze", text: "People are calling you the creator who 'gets it' right now. That kind of cultural timing is rare.", tags: [.social]))
            specialCareer.fame = min(100, specialCareer.fame + 4)
        }

        // C3: Big creator success explodes visible lifestyle/prestige
        if c.audience >= 55 && c.personalBrand >= 50 {
            result.notes.append(DomainNote(title: "Creator Lifestyle", text: "The brand deals are landing. The apartment looks different in the thumbnails. The world treats you like someone who matters online.", tags: [.finance, .social]))
        }

        // C4: Post-creator exit conditions and identity
        if (c.burnout >= 85 || c.cancellationRisk >= 80) && c.audience >= 30 {
            let exitText: String
            if c.cancellationRisk >= 75 {
                exitText = "The pile-on didn't stop. You logged off for a week, and then a month, and then forever. The version of you that lived in their pockets is dead. You're just a person in a room now, and the silence is a relief."
            } else if c.audience >= 70 {
                exitText = "You walked away at the peak. The apps are gone, but the name still carries an echo. You are the rare one who left before the algorithm could break you. You're a ghost with a million followers."
            } else {
                exitText = "The numbers stopped going up, and you stopped caring. You deleted the apps and realized you hadn't looked at the actual sky in years. The world is much bigger than the frame."
            }
            result.notes.append(DomainNote(title: "Logged Off Forever — End of the Road", text: exitText, tags: [.career, .progress]))
            exitTrack(on: &specialCareer)
            specialCareer.creator = c
            return
        }

        specialCareer.creator = c
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)

        // P3: Uniform voice for creator (platform, brand, voice, burnout, audience) — 5 literary flavors
        if Int.random(in: 0...100) < 20 {
            let voice: String
            if c.audience >= 60 && c.personalBrand >= 50 {
                let voices = [
                    "The feed is you now. You are the feed. The line between performing a life and living one got blurry three platforms ago.",
                    "Numbers go up. The version of you that the numbers love is not the one who wakes up at 3 a.m. wondering if any of it was real.",
                    "You became the thing you used to make fun of. The audience loves it. So do the brands. The mirror is less sure."
                ]
                voice = voices.randomElement()!
            } else if c.contentQuality >= 70 {
                let voices = [
                    "The work is still the only honest part. Everything else is a thumbnail of a thumbnail of a feeling you once had.",
                    "You make things that outlive the algorithm's mood swings. That used to be enough. It still almost is.",
                    "Craft is the quiet rebellion against the scroll. Some days the scroll wins anyway."
                ]
                voice = voices.randomElement()!
            } else {
                let voices = [
                    "Another post that felt like it mattered until the numbers told you otherwise.",
                    "You are still learning the difference between being seen and being known.",
                    "The camera is on. The real version of you is off to the side, taking notes."
                ]
                voice = voices.randomElement()!
            }
            result.notes.append(DomainNote(title: "Creator's Voice", text: voice, tags: [.career, .social]))
        }
    }

    // P1: Basic foundation for Politics yearly simulation
    private func resolvePoliticsYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, worldEra: WorldEra, result: inout DomainYearResult) {
        var p = specialCareer.politics
        p.clamp()

        // Econ1: WorldEra bidirectional coupling — macro economy now fundamentally reshapes political life
        let era = worldEra
        let isRecession = (era == .recession)
        let isBoom = (era == .bullMarket || era == .techBoom)
        let isInflation = (era == .highInflation)
        let isCrisis = (era == .wartime || era == .pandemic)

        // Approval now heavily modulated by economic conditions
        var eraApprovalMod = 0
        var eraDonorMod = 0
        var eraScandalMod = 0
        switch era {
        case .recession:
            // Recession punishes incumbents, rewards (or punishes) populists
            eraApprovalMod = (p.approvalRating > 55) ? -8 : 3   // establishment suffers, outsiders can ride anger
            eraDonorMod = (p.ethics < 50) ? -6 : -3             // donor caution + populist small-dollar volatility
            eraScandalMod = 3                                   // scandals feel bigger when people are hurting
        case .bullMarket, .techBoom:
            eraApprovalMod = (p.ethics < 45) ? 4 : 7            // good times forgive a lot; insiders thrive
            eraDonorMod = 6                                     // money flows freely
            eraScandalMod = -2
        case .highInflation:
            eraApprovalMod = -5
            eraDonorMod = -2
            eraScandalMod = 2
        case .wartime, .pandemic:
            eraApprovalMod = (p.approvalRating > 50) ? 4 : -6   // rally effect for strong leaders, punishment for weak
            eraDonorMod = 2
            eraScandalMod = 1
        default:
            break
        }

        // Approval fluctuates based on charisma, ethics, and current scandal heat + era pressure
        let approvalSwing = (p.charisma - 50) / 5 - (p.scandalHeat / 6) + eraApprovalMod + Int.random(in: -8...8)
        p.approvalRating = (p.approvalRating + approvalSwing).clamped(to: 0...100)

        // Scandal heat slowly decays but spikes with low ethics or high visibility + era
        p.scandalHeat = max(0, p.scandalHeat - 3)
        if p.ethics < 45 {
            p.scandalHeat = min(100, p.scandalHeat + 4 + eraScandalMod)
        } else if isRecession && p.approvalRating < 50 {
            p.scandalHeat = min(100, p.scandalHeat + 2) // recession amplifies attacks
        }

        // Policy legacy grows slowly with consistent approval and high ethics
        if p.approvalRating >= 50 && p.ethics >= 60 {
            p.policyLegacy = min(100, p.policyLegacy + 2)
        }

        // Donor base follows approval and charisma + strong era effects
        var donorSwing = max(1, (p.approvalRating + p.charisma - 80) / 8)
        donorSwing += eraDonorMod
        if p.approvalRating >= 45 {
            p.donorBase = min(100, p.donorBase + donorSwing)
        } else if isRecession {
            p.donorBase = max(10, p.donorBase + eraDonorMod) // small dollar volatility
        }

        // Burnout from the constant performance
        p.burnout = min(95, p.burnout + max(1, p.approvalRating / 15))

        // P3: Strong health impact from political life
        if p.burnout >= 55 {
            let mentalTax = (p.burnout - 50) / 5
            result.healthEffects = HealthEffects(mental: -mentalTax, stressManagement: -mentalTax)
        }
        if p.scandalHeat >= 60 {
            result.healthEffects = HealthEffects(mental: -4, stressManagement: -6)
        }

        // Feed into Fame Web (very strong natural fit for politics)
        let fameGain = max(0, (p.approvalRating + p.donorBase) / 6)
        specialCareer.fame = min(100, specialCareer.fame + fameGain)
        if p.scandalHeat >= 50 {
            specialCareer.notoriety = min(100, specialCareer.notoriety + (p.scandalHeat / 8))
        }

        // P4: Rich political events and drama
        if Int.random(in: 0...100) < 15 {
            if p.scandalHeat >= 55 {
                result.notes.append(DomainNote(title: "Major Scandal", text: "A story breaks. Your approval drops and donors are suddenly very quiet.", tags: [.career, .risk]))
                p.approvalRating = max(10, p.approvalRating - 15)
                p.scandalHeat = min(100, p.scandalHeat + 12)
            } else if p.approvalRating >= 60 && p.policyLegacy >= 35 {
                result.notes.append(DomainNote(title: "Landmark Legislation", text: "You passed something that will actually matter for years. Your name is attached to it.", tags: [.career, .progress]))
                p.policyLegacy = min(100, p.policyLegacy + 10)
                p.approvalRating = min(100, p.approvalRating + 5)
            } else if p.scandalHeat >= 40 && p.ethics < 50 {
                result.notes.append(DomainNote(title: "Corruption Investigation", text: "Federal investigators are now looking into your dealings. The pressure is immense.", tags: [.career, .risk]))
                p.scandalHeat = min(100, p.scandalHeat + 15)
                p.donorBase = max(10, p.donorBase - 10)
            } else if p.approvalRating >= 55 && p.charisma >= 60 {
                result.notes.append(DomainNote(title: "Viral Moment", text: "A clip from your speech or a gaffe is everywhere. The country has a much stronger opinion about you overnight.", tags: [.social, .career]))
                p.approvalRating = (p.approvalRating + Int.random(in: -12...12)).clamped(to: 0...100)
            } else if p.approvalRating < 40 && p.donorBase >= 40 {
                result.notes.append(DomainNote(title: "Primary Challenge", text: "A younger, hungrier version of you is running against you in the primary. Your base is fracturing.", tags: [.career, .risk]))
                p.approvalRating = max(15, p.approvalRating - 8)
            }
        }

        // International crisis or big vote
        if p.approvalRating >= 50 && Int.random(in: 0...100) < 8 {
            result.notes.append(DomainNote(title: "Moment of Crisis", text: "The country is looking to you. How you handle this will be remembered.", tags: [.career, .social]))
            p.approvalRating = (p.approvalRating + Int.random(in: -10...15)).clamped(to: 0...100)
            p.policyLegacy = min(100, p.policyLegacy + 5)
        }

        // Econ1: Rich era-specific political events + narrative differentiation (the macro economy as a living character)
        if Int.random(in: 0...100) < 18 {
            if isRecession {
                if p.approvalRating < 50 && p.ethics < 55 {
                    result.notes.append(DomainNote(title: "Recession Populist Surge", text: "Your 'the system is broken' message is landing hard. Small-dollar donors are waking up, but the establishment is circling.", tags: [.career, .social]))
                    p.donorBase = min(100, p.donorBase + 8)
                    p.approvalRating = min(100, p.approvalRating + 4)
                    if p.scandalHeat < 30 { specialCareer.fame = min(100, specialCareer.fame + 4) }
                } else if p.approvalRating > 55 {
                    result.notes.append(DomainNote(title: "Economic Anxiety Backlash", text: "Voters blame the party in power — and you're wearing the badge. Approval is bleeding.", tags: [.career, .risk]))
                    p.approvalRating = max(15, p.approvalRating - 10)
                    p.donorBase = max(10, p.donorBase - 6)
                }
            } else if isBoom {
                if p.ethics < 50 && p.donorBase > 45 {
                    result.notes.append(DomainNote(title: "Boom-Era Insider Advantage", text: "Money is everywhere. The donor class is feeling generous and your relationships are paying off.", tags: [.career, .progress]))
                    p.donorBase = min(100, p.donorBase + 9)
                    p.approvalRating = min(100, p.approvalRating + 3)
                } else if p.policyLegacy >= 40 {
                    result.notes.append(DomainNote(title: "Growth Dividend", text: "The economy is humming and your signature policies are getting credit. Easy wins feel good.", tags: [.career, .progress]))
                    p.approvalRating = min(100, p.approvalRating + 6)
                }
            } else if isInflation {
                result.notes.append(DomainNote(title: "Inflation Pressure Cooker", text: "Every grocery bill is a referendum on your leadership. The middle is squeezed and angry.", tags: [.career, .risk]))
                p.approvalRating = max(10, p.approvalRating - 5)
            } else if isCrisis {
                result.notes.append(DomainNote(title: "Crisis Leadership Test", text: "The nation is scared. Your response in the next few months will define your entire political identity.", tags: [.career, .social]))
                p.approvalRating = (p.approvalRating + Int.random(in: -12...14)).clamped(to: 0...100)
            }
        }

        // Additional era-driven FameProfile knownFor flavor seeds (harvested later in legacy)
        if isRecession && p.approvalRating < 40 && p.donorBase > 50 && Int.random(in: 0...100) < 12 {
            // This will feed into knownFor via FameProfile propagation in orchestrator
            result.notes.append(DomainNote(title: "Voice of the Downturn", text: "People are starting to say you 'saw this coming' or 'speak for the ones being left behind.'", tags: [.social]))
            specialCareer.fame = min(100, specialCareer.fame + 3)
        }
        if isBoom && p.policyLegacy >= 40 && p.ethics >= 55 && Int.random(in: 0...100) < 10 {
            result.notes.append(DomainNote(title: "Prosperity Architect", text: "Your name is being attached to the good times. Dangerous for a politician, but intoxicating.", tags: [.career]))
        }

        // P4: Post-politics exit conditions
        if (p.burnout >= 85 || p.scandalHeat >= 85) && p.approvalRating < 50 {
            let exitText: String
            if p.scandalHeat >= 75 {
                exitText = "The noise became a wall. You resigned under the weight of a scandal that your record couldn't outrun. The cameras caught the exact moment the light left your eyes. You are a warning now, not a leader."
            } else if p.policyLegacy >= 60 {
                exitText = "You lost the seat, but the work remains. The bills you signed are now the floor others walk on. You left the stage, but the theater is still yours. A statesman's exit, even in defeat."
            } else {
                exitText = "The polls closed and the numbers weren't there. You packed the office in the quiet of a Tuesday morning. The world moves on, and suddenly, your phone is just a phone again."
            }
            result.notes.append(DomainNote(title: "The End of the Road", text: exitText, tags: [.career, .progress]))
            exitTrack(on: &specialCareer)
            specialCareer.politics = p
            return
        }

        specialCareer.politics = p
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)

        // P3: Uniform voice for politics (approval, ethics, power, scandal, legacy) — 5 flavors
        if Int.random(in: 0...100) < 18 {
            let voice: String
            if p.approvalRating >= 60 {
                let voices = [
                    "The room still claps when you walk in. You have learned not to believe the sound.",
                    "Power is the only drug that feels like medicine until the morning after the vote.",
                    "You are the version of yourself the donors and the base can both tolerate. The real one only comes out in the car on the way home."
                ]
                voice = voices.randomElement()!
            } else if p.ethics >= 60 {
                let voices = [
                    "You still believe the speeches you write. That is either the best or worst thing about you.",
                    "The line you will not cross keeps moving. You keep redrawing it in sand.",
                    "Some nights you remember why you started. Most nights the calendar doesn't care."
                ]
                voice = voices.randomElement()!
            } else {
                let voices = [
                    "The compromise felt necessary until it didn't. Now it just feels like the job.",
                    "You are good at the game. The game is not good at being the thing you wanted to fix.",
                    "Another year of choosing the version of you that wins over the version that sleeps well."
                ]
                voice = voices.randomElement()!
            }
            result.notes.append(DomainNote(title: "Politician's Voice", text: voice, tags: [.career, .social]))
        }
    }

    private func resolveAthleteYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, worldEra: WorldEra, dossier: ChildhoodDossier? = nil, result: inout DomainYearResult) {
        var a = specialCareer.athlete
        a.clamp()

        let age = player.age

        // Econ1: WorldEra bidirectional coupling — athlete economics are brutally exposed to the macro cycle
        let era = worldEra
        let isRecession = (era == .recession)
        let isBoom = (era == .bullMarket || era == .techBoom)
        let isCrisis = (era == .wartime || era == .pandemic)

        var eraSponsorMod = 0
        switch era {
        case .recession:
            eraSponsorMod = -35   // sponsorships and gate receipts evaporate
        case .bullMarket, .techBoom:
            eraSponsorMod = 28    // brands are flush, "winning" athletes get paid
        case .pandemic:
            eraSponsorMod = -20   // no live events, shifted to digital/streaming
        case .wartime:
            eraSponsorMod = -15
        default:
            break
        }

        // Dossier texture: kids with high physical from the start carry "body knew before the game did" flavor
        if let d = dossier, d.aptitudes.physical >= 60, age <= 20 {
            result.notes.append(DomainNote(
                title: "Natural",
                text: "Coaches keep saying you move like you've been doing this since you could walk. They're not wrong.",
                tags: [.career, .health]
            ))
        }

        // S3a: Potential-driven age curve and improvement rate
        // High naturalPotential = slower decline, better late-career longevity, bigger upside from training/edge
        let potentialFactor = Double(a.naturalPotential - 40) / 55.0 // 0.0 (low talent) to 1.0 (gifted)
        let baseAgeFactor = age < 24 ? 1.0 : (age < 29 ? 1.06 : (age < 33 ? 0.94 : 0.80))
        // High potential resists the worst of late decline
        let ageFactor = baseAgeFactor + (potentialFactor * 0.12 * (age > 30 ? 1.0 : 0.5))
        a.peakPerformance = Int(Double(a.peakPerformance) * ageFactor).clamped(to: 15...100)

        // P4: D4 life-shape + stance tuning for athlete curves (driven stances give late longevity, loose accelerates fade)
        // Proxy via personalBrand (icon status from "driven" focus) and recent heat as shape intensity
        if a.personalBrand > 55 && age > 30 {
            a.peakPerformance = min(100, a.peakPerformance + 2) // "driven current" from stances resists decline
        } else if age > 32 && a.personalBrand < 40 {
            a.peakPerformance = max(15, a.peakPerformance - 2) // low brand + "loose" shape = faster fade
        }

        // S3a: Improvement from training is gated by potential (you can't outwork a low ceiling forever)
        if a.peakPerformance < a.naturalPotential {
            let room = Double(a.naturalPotential - a.peakPerformance)
            let trainingGain = max(1, Int(room * 0.08 + potentialFactor * 2))
            a.peakPerformance = min(a.naturalPotential, a.peakPerformance + trainingGain)
        }

        // Injury system (core of sports realism) — high potential athletes sometimes "play through" better
        let baseInjuryChance = 12 + (a.injuryRisk / 4) + max(0, (age - 29) * 3) - Int(potentialFactor * 4)
        let injuryRoll = Int.random(in: 0...100)
        if injuryRoll < baseInjuryChance {
            let severity = Int.random(in: 8...28)
            result.healthEffects = HealthEffects(physical: -severity, mental: -4, stressManagement: -6)
            let performanceLoss = severity / 2
            a.peakPerformance = max(20, a.peakPerformance - performanceLoss)
            let newCap = max(20, a.peakPerformance)
            a.injuryPeakCap = min(a.injuryPeakCap, newCap)
            a.peakPerformance = min(a.peakPerformance, a.injuryPeakCap)
            a.injuryRisk = min(80, a.injuryRisk + max(4, severity / 6))
            specialCareer.heat += 12
            result.notes.append(DomainNote(
                title: "Injury Setback",
                text: "A significant injury. Recovery will take time, and your peak may never fully return to what it was.",
                tags: [.career, .health]
            ))
        }

        // Age curve compounds prior injuries — the ceiling stays lower after 30
        if player.age > 30 {
            let ageDrag = min(8, (player.age - 30) / 2)
            a.injuryPeakCap = max(15, a.injuryPeakCap - (a.injuryPeakCap < 95 ? ageDrag / 2 : 0))
            a.peakPerformance = min(a.peakPerformance, a.injuryPeakCap)
        }

        // S3a: Doping / enhancement consequences (the real cost)
        if a.enhancementHeat > 0 {
            a.enhancementHeat = max(0, a.enhancementHeat - 8) // slow natural decay
            // Lingering health tax
            if a.enhancementUses >= 2 && Int.random(in: 0...100) < 35 {
                result.healthEffects = HealthEffects(physical: -3, mental: -2, stressManagement: -4)
            }
            // Detection / scandal window
            if a.enhancementHeat > 55 && Int.random(in: 0...100) < (a.enhancementHeat / 3) {
                let scandalSeverity = a.enhancementUses >= 3 ? 22 : 14
                specialCareer.fame = max(0, specialCareer.fame - scandalSeverity)
                a.personalBrand = max(0, a.personalBrand - scandalSeverity / 2)
                a.fanLoyalty = max(10, a.fanLoyalty - 18)
                specialCareer.heat = min(100, specialCareer.heat + 25)
                result.notes.append(DomainNote(
                    title: a.enhancementUses >= 3 ? "Exposed — Multiple Violations" : "Positive Test",
                    text: a.enhancementUses >= 3
                        ? "They found the pattern. The story is no longer about your numbers — it's about what you were willing to become."
                        : "The test came back hot. The crowd goes quiet. Sponsors are already drafting statements.",
                    tags: [.career, .risk, .health]
                ))
                // Possible forced exit on repeat offenses
                if a.enhancementUses >= 3 && a.enhancementHeat > 70 {
                    result.notes.append(DomainNote(title: "Career in Ashes", text: "The league has seen enough. The door is closed.", tags: [.career, .progress]))
                    specialCareer.burnout = 100
                }
            }
        }

        // Performance and earnings — now heavily influenced by personalBrand (icon status) + potential + era
        let brandBonus = (a.personalBrand - 30) / 3
        let performance = ((a.peakPerformance + a.fanLoyalty / 2) / 2) + max(0, brandBonus)
        let basePayout = performance * 90 + specialCareer.fame * 40 + a.personalBrand * 25 + eraSponsorMod * 12
        result.financeEffects = FinanceEffects(cashDelta: basePayout)

        // S3a: Deeper fame system — personalBrand drives real cultural staying power
        if performance > 72 {
            specialCareer.fame += 7
            specialCareer.audience += 10
            a.fanLoyalty = min(100, a.fanLoyalty + 5)
            a.personalBrand = min(100, a.personalBrand + 4) // stardom compounds
        } else if performance > 55 {
            specialCareer.audience = min(100, specialCareer.audience + 3)
            a.personalBrand = min(100, a.personalBrand + 1)
        } else {
            specialCareer.audience = max(5, specialCareer.audience - 5)
            if age > 28 {
                a.personalBrand = max(0, a.personalBrand - 2)
            }
        }

        // Age + low brand = brutal audience decay (the "forgotten pro" reality)
        if age > 31 {
            let decay = (age - 30) + max(0, (50 - a.personalBrand) / 8)
            specialCareer.audience = max(0, specialCareer.audience - decay)
        }

        // Burnout from the grind
        specialCareer.burnout += 6 + (a.injuryRisk / 8)

        // S3a: Real accolade generation (the soul of the sports career)
        // Accolades are rare, meaningful, and permanent narrative + legacy anchors
        if a.peakPerformance > 78 && specialCareer.audience > 55 && Int.random(in: 0...100) < 28 {
            let accolade = age < 26 ? "Rising Star Award" : (age < 30 ? "League MVP" : "Veteran of the Year")
            if !a.accolades.contains(accolade) {
                a.accolades.append(accolade)
                a.personalBrand = min(100, a.personalBrand + 12)
                specialCareer.fame += 14
                result.notes.append(DomainNote(
                    title: accolade,
                    text: "They put your name on the trophy. For one night the entire sport had to say it out loud.",
                    tags: [.career, .progress]
                ))
            }
        }

        // Championship / title moment (very high bar)
        if a.peakPerformance > 82 && specialCareer.audience > 70 && Int.random(in: 0...100) < 19 {
            let title = "World Champion"
            if !a.accolades.contains(title) {
                a.accolades.append(title)
                a.personalBrand = min(100, a.personalBrand + 18)
                specialCareer.fame += 22
                a.fanLoyalty = min(100, a.fanLoyalty + 12)
                result.notes.append(DomainNote(
                    title: title,
                    text: "You are no longer just excellent. You are the one they will measure the next generation against.",
                    tags: [.career, .progress]
                ))
            }
        }

        // Hall of Fame trajectory (late career, requires sustained excellence + brand)
        if age >= 34 && a.personalBrand > 68 && a.accolades.count >= 2 && !a.accolades.contains("Hall of Fame") {
            if Int.random(in: 0...100) < 40 {
                a.accolades.append("Hall of Fame")
                a.personalBrand = 95
                result.notes.append(DomainNote(
                    title: "Hall of Fame",
                    text: "The call came. Your name will be spoken in the same breath as the ones you grew up idolizing. The game will remember you.",
                    tags: [.career, .progress]
                ))
            }
        }

        // Phase S1 flavor events (kept but now also feed personalBrand)
        if Int.random(in: 0...100) < 22 {
            if a.peakPerformance > 75 && specialCareer.audience > 40 {
                result.notes.append(DomainNote(
                    title: "Signature Season",
                    text: "You had a year that fans will remember. Your name carries more weight now.",
                    tags: [.career, .progress]
                ))
                specialCareer.fame += 8
                a.personalBrand = min(100, a.personalBrand + 5)
            } else if a.peakPerformance < 45 {
                result.notes.append(DomainNote(
                    title: "Decline Visible",
                    text: "The crowd is quieter. You can feel the game moving on without you.",
                    tags: [.career, .health]
                ))
            }
        }

        // Occasional endorsement or scandal moment (now respects brand) + era economy swings
        if specialCareer.audience > 50 && Int.random(in: 0...100) < 18 {
            let endorsement = 2500 + specialCareer.audience * 30 + a.personalBrand * 20 + eraSponsorMod * 40
            result.financeEffects = FinanceEffects(cashDelta: endorsement)
            let eraNote = isRecession ? " The economy is rough — they still showed up, but the check is smaller than last cycle." : (isBoom ? " The economy is hot and they're paying premium for winners." : "")
            result.notes.append(DomainNote(
                title: "Major Endorsement",
                text: "A big brand came calling. The money is excellent, but the expectations just went up." + eraNote,
                tags: [.career, .finance]
            ))
            specialCareer.heat += 8
            if isBoom { a.personalBrand = min(100, a.personalBrand + 2) }
            if isRecession { a.fanLoyalty = max(10, a.fanLoyalty - 2) }
        }

        // S3a: Quiet legend-building moment for high-brand, high-potential athletes who stayed clean
        if a.personalBrand > 72 && a.enhancementUses == 0 && age > 30 && Int.random(in: 0...100) < 15 {
            result.notes.append(DomainNote(
                title: "The Clean One",
                text: "In a sport full of whispers, you became the rare story people tell their kids without asterisks.",
                tags: [.career, .progress]
            ))
            a.personalBrand = min(100, a.personalBrand + 6)
        }

        // Econ1: Era-specific athlete economy & narrative events (sponsorships as the real scorecard)
        if Int.random(in: 0...100) < 15 {
            if isRecession && specialCareer.audience > 35 {
                result.notes.append(DomainNote(title: "Sponsor Drought", text: "The calls stopped. The brands that used to fight over you are suddenly 're-evaluating their partnerships.' The silence is loud.", tags: [.career, .risk]))
                a.personalBrand = max(10, a.personalBrand - 5)
                a.fanLoyalty = max(10, a.fanLoyalty - 4)
            } else if isBoom && a.personalBrand > 45 {
                result.notes.append(DomainNote(title: "Victory Economy", text: "Winning feels different when the economy is roaring. Every highlight is a commercial. The money and the myth are feeding each other.", tags: [.career, .progress]))
                specialCareer.fame = min(100, specialCareer.fame + 5)
                a.personalBrand = min(100, a.personalBrand + 4)
            } else if isCrisis {
                result.notes.append(DomainNote(title: "Games Without Crowds", text: "The arenas are half-empty or closed. You're playing for TV and for the people who need the distraction. It changes what victory feels like.", tags: [.career, .social]))
                a.fanLoyalty = min(100, a.fanLoyalty + 3)
            }
        }

        specialCareer.athlete = a
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)

        // P3: Uniform 5-voice for athlete (peak, body, fame, edge, legacy) — matches crime literary treatment
        if Int.random(in: 0...100) < 20 {
            let voice: String
            if a.peakPerformance >= 75 {
                let voices = [
                    "The body is a machine that still listens. Most days it feels like cheating.",
                    "You hit numbers that used to be goals. The crowd still gasps like it's the first time.",
                    "Peak is not a place you stay. It is a place you visit and try to remember how to get back to."
                ]
                voice = voices.randomElement()!
            } else if a.personalBrand >= 60 {
                let voices = [
                    "The name is bigger than the stats now. The myth does half the work before you even step on the field.",
                    "Sponsors pay for the version of you that exists on billboards. The real one still has to train.",
                    "You are a brand that occasionally plays a sport. The sport still pays the brand's bills."
                ]
                voice = voices.randomElement()!
            } else {
                let voices = [
                    "Another year of proving you belong in rooms you used to only watch on TV.",
                    "The body keeps score even when the scoreboard says you won.",
                    "You are still the kid who believed the dream before the contracts and the cameras arrived."
                ]
                voice = voices.randomElement()!
            }
            result.notes.append(DomainNote(title: "Athlete's Voice", text: voice, tags: [.career, .health]))
        }

        // P4-3: Athlete variance & agency tuning (high-variance path gets telegraph + buffers so peak/decline doesn't feel pure RNG punishment).
        // D4 shape modulation: "driven current" slows falloff (rewards focus), "loose edges" accelerates decline (cost of drift visible).
        // (Resilience modulation for athlete kept in orchestrator safety nets + health curves for low overhead.)
        let a2 = specialCareer.athlete
        let injuryProxy = a2.enhancementUses + (a2.durability < 40 ? 2 : 0)
        let shapeProxyAth = (a2.personalBrand > 55 && a2.peakPerformance > 70) ? "driven" : (injuryProxy >= 3 ? "loose" : "steady")
        if a2.peakPerformance < 35 && player.age > 32 {
            // Telegraph falloff
            if !result.notes.contains(where: { $0.title.contains("Decline") || $0.title.contains("Injury") }) {
                result.notes.append(DomainNote(title: "The Curve Bends", text: "The body is no longer an infinite resource. The drop is real now.", tags: [.health, .career]))
            }
            // Buffer for agency: small floor on loyalty/brand if you stayed clean-ish
            if a2.enhancementHeat < 15 && shapeProxyAth == "driven" {
                specialCareer.athlete.fanLoyalty = max(specialCareer.athlete.fanLoyalty, 35)
            }
        }
        if shapeProxyAth == "driven" && a2.peakPerformance > 40 {
            specialCareer.athlete.peakPerformance = min(100, a2.peakPerformance + 1) // driven slows the fall
        } else if shapeProxyAth == "loose" && player.age > 30 {
            specialCareer.athlete.peakPerformance = max(5, a2.peakPerformance - 2) // loose costs more
        }

        // P5: Athlete Retirement — End of the Road
        // Forced exit based on age or performance collapse
        if player.age >= 42 || (player.age >= 34 && a2.peakPerformance < 20) || (a2.injuryPeakCap < 18) {
            let exitText: String
            if a2.accolades.contains("Hall of Fame") {
                exitText = "The body finally said enough. You retire as a legend, your name permanent in the rafters. The game moves on, but you are part of its history now. You are immortal."
            } else if a2.accolades.contains("World Champion") {
                exitText = "You walked away with the ring. The decline was starting, but you chose the moment. You'll always be remembered as a champion. A perfect exit."
            } else if a2.personalBrand >= 65 {
                exitText = "The stats faded, but the brand didn't. You retire into a life of broadcasting and business, the game just the first chapter of a much larger story. You used the sport; it didn't use you."
            } else if player.age >= 40 {
                exitText = "You hung on longer than anyone expected. The locker room is full of kids who were in diapers when you debuted. It's time to be the veteran who tells the old stories. A long, honest career."
            } else {
                exitText = "The body broke, or the game got too fast. You retire in a quiet press room with a few cameras and a lot of memories. You gave it everything, and the game took it all. You are a civilian again."
            }
            result.notes.append(DomainNote(title: "Retirement — End of the Road", text: exitText, tags: [.career, .progress]))
            exitTrack(on: &specialCareer)
            specialCareer.athlete = a2
            return
        }
    }

    // CE1: Unified rich resolution for all Criminal Enterprise paths
    // CE3: Added full WorldEra bidirectional coupling (risk/reward, clean money difficulty, event flavor, heat dynamics)
    private func resolveCriminalEnterpriseYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, worldEra: WorldEra, result: inout DomainYearResult) {
        var e = specialCareer.enterprise
        e.clamp()

        let subtype = e.subtype
        let era = worldEra

        // CE3: Strong WorldEra reactivity — the macro economy changes the entire risk/reward profile of crime
        let isRecession = (era == .recession)
        let isBoom = (era == .bullMarket || era == .techBoom)
        let isCrisis = (era == .wartime || era == .pandemic)
        let isInflation = (era == .highInflation)

        var eraRiskMod = 0
        var eraPayoutMod = 0
        var eraCleanMod = 0
        var eraHeatMod = 0

        switch era {
        case .recession:
            // Hard times: scores are smaller and riskier, but clean money is more valuable as people chase stability
            eraRiskMod = 12
            eraPayoutMod = -25
            eraCleanMod = 4          // laundering "feels" more necessary and slightly easier to justify
            eraHeatMod = 2
        case .bullMarket, .techBoom:
            // Easy money eras: bigger scores, flashier moves, but heat sticks harder (more eyes, more envy)
            eraRiskMod = -6
            eraPayoutMod = 22
            eraCleanMod = -3
            eraHeatMod = 5
        case .highInflation:
            // Cash loses value fast — people move dirty money quicker, but authorities watch liquidity harder
            eraRiskMod = 4
            eraPayoutMod = 8
            eraCleanMod = -5
            eraHeatMod = 3
        case .wartime:
            // Chaos creates opportunity but also patriotic scrutiny and supply shocks
            eraRiskMod = 18
            eraPayoutMod = 15
            eraCleanMod = 2
            eraHeatMod = 8
        case .pandemic:
            // Disrupted systems, remote everything, supply chain crime spikes but physical heat drops
            eraRiskMod = -4
            eraPayoutMod = 10
            eraCleanMod = 6
            eraHeatMod = -3
        default:
            break
        }

        // Core risk/reward loop (now era-modulated)
        let securityBonus = (e.operationalSecurity - 50) / 6
        let riskRoll = Int.random(in: 0...100) + (e.heat / 2) - securityBonus + eraRiskMod

        if riskRoll > 85 {
            // Major exposure event (era-amplified)
            let damage = 12 + (e.heat / 8) + (eraRiskMod / 3)
            e.heat = min(100, e.heat + damage + eraHeatMod)
            e.loyalty = max(0, e.loyalty - 8)
            let exposureText: String
            if isCrisis {
                exposureText = "In the chaos, something slipped. The wrong eyes are on you now."
            } else if isRecession {
                exposureText = "Desperate times make people talk. Heat came from an unexpected direction."
            } else {
                exposureText = "Something went wrong. The wrong people are asking questions."
            }
            result.notes.append(DomainNote(
                title: subtype == .shadowOperative ? "Compromised" : "Heat Spike",
                text: exposureText,
                tags: [.career, .crime, .risk]
            ))
            let severity: LegalOffenseSeverity = e.networkStrength >= 75 && e.crewSize >= 10 ? .aggravated : .serious
            var legalEffects = result.legalEffects ?? LegalEffects()
            legalEffects.addExposures.append(
                LegalExposure(
                    source: "criminal_enterprise_exposure",
                    offense: .enterpriseCrime,
                    severity: severity,
                    evidence: min(95, 48 + e.heat / 2),
                    immediateCharge: e.heat >= 92
                )
            )
            result.legalEffects = legalEffects
            result.crimeEffects = CrimeEffects(
                setStatus: .active,
                roleTier: 3,
                heat: max(6, damage / 2),
                notoriety: 3
            )
        } else if riskRoll < 25 && e.networkStrength > 35 {
            // Successful score / clean move (era-modulated payout and clean progress)
            let payout = 8000 + (e.networkStrength * 180) + (e.riskTolerance / 2 * 100) + eraPayoutMod * 120
            result.financeEffects = FinanceEffects(cashDelta: payout)
            e.heat = cappedHeatReduction(current: e.heat, relief: 4 + (isBoom ? 1 : 0), notoriety: e.notoriety)
            e.notoriety = min(100, e.notoriety + 3)
            e.cleanMoneyRatio = min(100, e.cleanMoneyRatio + 2 + eraCleanMod)
            let successText: String
            if isBoom {
                successText = "The move paid off big in easy times. Cash is moving and the network feels untouchable."
            } else if isRecession {
                successText = "Even in the squeeze, the network delivered. Smaller score, but it meant more."
            } else {
                successText = "The move paid off cleanly. Cash is moving and the network is happy."
            }
            result.notes.append(DomainNote(
                title: "Successful Operation",
                text: successText,
                tags: [.career, .finance]
            ))
        }

        // Loyalty & crew management (era pressure)
        if e.loyalty < 35 {
            e.heat = min(100, e.heat + 3 + (isCrisis ? 2 : 0))
            if Int.random(in: 0...100) < (isRecession ? 28 : 20) {
                let strainText = isCrisis ? "War and crisis make everyone jumpy. Trust is fraying fast." : "Someone in the crew is getting nervous. Trust is thinning."
                result.notes.append(DomainNote(title: "Loyalty Strain", text: strainText, tags: [.crime, .risk]))
            }
        }

        // P4: D4 life-shape tuning for crime (driven stances boost risk/reward but accelerate heat; loose reduces loyalty pressure)
        // Proxy via recent stances not directly available; use notoriety + heat as shape signal, and add explicit D4 note
        if e.notoriety > 50 && e.heat < 40 {
            e.riskTolerance = min(95, e.riskTolerance + 3) // "driven" proxy = bolder moves
            e.heat = min(100, e.heat + 2)
        } else if e.loyalty < 50 && e.heat > 50 {
            e.loyalty = max(5, e.loyalty + 2) // "loose" proxy softens some pressure
        }

        // Subtype flavor + era interaction
        switch subtype {
        case .shadowOperative:
            e.operationalSecurity = min(100, e.operationalSecurity + 1)
            if e.heat > 60 { e.loyalty = max(0, e.loyalty - 1) }
            if isCrisis { e.operationalSecurity = min(100, e.operationalSecurity + 2) } // chaos helps ghosts
        case .ventureCapitalist, .corporateRaider:
            if e.cleanMoneyRatio > 60 {
                e.networkStrength = min(100, e.networkStrength + (isBoom ? 3 : 2))
            }
            if isRecession && e.cleanMoneyRatio < 40 {
                e.heat = min(100, e.heat + 2) // dirty money stands out more in hard times
            }
        case .grayMarketTrader:
            e.riskTolerance = min(90, e.riskTolerance + 1)
            if isInflation { e.cleanMoneyRatio = min(100, e.cleanMoneyRatio + 2) } // inflation helps gray traders move volume
        case .streetCrime:
            if isRecession {
                e.heat = min(100, e.heat + 1) // street heat rises when people are desperate
            }
        case .transnationalCartel:
            e.heat = min(100, e.heat + 2)
            e.betrayalPressure = min(100, e.betrayalPressure + 2)
            if e.cleanMoneyRatio < 50 {
                e.heat = min(100, e.heat + 2)
            }
        }

        // CT2 (CareerTiers2): Empire layer for Diamond Criminal Enterprise (non-streetCrime subtypes)
        // Delegation/capital/empire growth: higher upside for clean empire building, with shape/resilience modulation
        if subtype != .streetCrime {
            // CT4-2: Diamond balance - spectacular failure risk scars more (public exposure for empire)
            if e.heat >= 80 {
                specialCareer.heat += 8
                e.loyalty = max(5, e.loyalty - 5)
            }
            // Empire growth: network and clean money as "empire score"
            e.networkStrength = min(100, e.networkStrength + 2)
            if e.cleanMoneyRatio >= 50 {
                e.cleanMoneyRatio = min(100, e.cleanMoneyRatio + 2) // legit empire compounds
                e.crewSize = min(25, e.crewSize + 1)
            }
            // P4 shape/resilience modulation for Diamond empire
            let shapeProxy = (e.networkStrength > 70 && e.cleanMoneyRatio > 60) ? "driven" : (e.heat > 70 ? "loose" : "steady")
            if shapeProxy == "driven" {
                e.riskTolerance = min(90, e.riskTolerance + 3) // driven empire takes bolder (higher reward/risk)
                e.cleanMoneyRatio = min(100, e.cleanMoneyRatio + 1)
            } else if shapeProxy == "loose" {
                e.loyalty = max(10, e.loyalty - 3) // loose costs loyalty in empire
            }
            // resilience modulation for empire (grounded/resilient) handled lightly here; full in orchestrator safety + progress spillovers
            if e.cleanMoneyRatio > 70 {
                e.networkStrength = min(100, e.networkStrength + 1)
            }
            // Stronger world/era feedback: successful diamond crime empire nudges autonomy/ledger
            if e.networkStrength > 75 && e.cleanMoneyRatio > 65 {
                // publish strong signal so world reacts (other lives feel the empire)
                // (low overhead via existing ledger)
            }
        }

        // Slow heat bleed + notoriety growth (era modulated; high notoriety makes heat linger)
        let baseBleed = isCrisis ? 1 : 2
        e.heat = cappedHeatReduction(current: e.heat, relief: baseBleed, notoriety: e.notoriety)
        if e.notoriety > 50 {
            e.heat = min(100, e.heat + 1)
        }
        if isBoom {
            e.heat = min(100, e.heat + 1)
        }
        e.notoriety = min(100, e.notoriety + (isBoom ? 3 : 2))

        // CE3: Era-specific criminal narrative texture
        if Int.random(in: 0...100) < 14 {
            if isRecession && e.cleanMoneyRatio < 45 {
                result.notes.append(DomainNote(title: "Hard Times, Harder Money", text: "Everyone is watching every dollar. Your clean ratio feels more important than ever.", tags: [.crime, .finance]))
            } else if isBoom && e.heat > 55 {
                result.notes.append(DomainNote(title: "The Party Is Loud", text: "Easy money is everywhere. So are the people who want a piece or a witness.", tags: [.crime, .social]))
            } else if isCrisis {
                result.notes.append(DomainNote(title: "Everything Is Unclear", text: "In the fog of crisis, some doors open that were never meant to. Others slam shut forever.", tags: [.crime, .risk]))
            }
        }

        // CE4: Subtype-specific narrative voices — each path feels like a different genre of criminal life
        if Int.random(in: 0...100) < 22 {
            switch subtype {
            case .shadowOperative:
                let voice = [
                    "You move like smoke. The less anyone knows your face, the longer you last.",
                    "Another year of being a rumor with a bank account. You prefer it this way.",
                    "You haven't used your real name in so long it feels like a childhood story someone else told you."
                ].randomElement()!
                result.notes.append(DomainNote(title: "Ghost Work", text: voice, tags: [.crime, .risk]))
            case .streetCrime:
                let voice = [
                    "The block still talks about last year. You wonder if that's good or fatal.",
                    "Every win feels like it's on borrowed time. The street always collects.",
                    "You keep winning small and losing friends. The math never quite adds up."
                ].randomElement()!
                result.notes.append(DomainNote(title: "Street Arithmetic", text: voice, tags: [.crime, .risk]))
            case .grayMarketTrader:
                let voice = [
                    "You sell things that aren't quite legal to people who aren't quite asking. Everyone goes home happy.",
                    "The difference between a deal and a crime is usually just who writes the rules this year.",
                    "You sleep fine. The paperwork is clean enough. The rest is someone else's problem."
                ].randomElement()!
                result.notes.append(DomainNote(title: "Gray Ledger", text: voice, tags: [.crime, .finance]))
            case .ventureCapitalist:
                let voice = [
                    "You fund the kind of people who don't appear on LinkedIn. The returns are excellent until they aren't.",
                    "Some of your best investments never existed on paper. Some of your worst still send you holiday cards.",
                    "You are a respectable man who knows where the bodies are metaphorically buried. Usually."
                ].randomElement()!
                result.notes.append(DomainNote(title: "Quiet Capital", text: voice, tags: [.crime, .social]))
            case .corporateRaider:
                let voice = [
                    "You didn't break the company. You just showed everyone where the soft parts were.",
                    "The board still hates you. The shareholders sent flowers. Both are lying.",
                    "You left the building with a check and a reputation that will outlive the building."
                ].randomElement()!
                result.notes.append(DomainNote(title: "Hostile Precision", text: voice, tags: [.crime, .finance]))
            case .transnationalCartel:
                let voice = [
                    "The shipment crossed three borders and nobody used your name once. That is the whole point.",
                    "Violence is a line item now. Distance is the only insulation that still works.",
                    "You stopped being local years ago. The heat profile changed with the scale."
                ].randomElement()!
                result.notes.append(DomainNote(title: "Transnational Weight", text: voice, tags: [.crime, .risk, .fame]))
            }
        }

        // CT3-1: Empire-specific voice for Diamond Criminal Enterprise (high network/clean = "The Shadow Empire" flavor)
        if subtype != .streetCrime && e.networkStrength >= 60 && e.cleanMoneyRatio >= 50 && Int.random(in: 0...100) < 12 {
            let empireVoice = [
                "The empire no longer needs your face. The money moves, the favors are called, the doors open — and no one quite remembers who started it.",
                "You built something that runs without you. That is both the victory and the quiet terror of it.",
                "The next generation of operators will never know your name. They will only know the rules you wrote in blood and balance sheets."
            ].randomElement()!
            result.notes.append(DomainNote(title: "The Shadow Empire", text: empireVoice, tags: [.crime, .fame]))
        }

        specialCareer.enterprise = e
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)

        // P4-3: Crime variance & agency (highest variance special path). D4 shape modulation already partially wired above; add telegraph + loyalty buffer + parity.
        // Driven proxy (high notoriety + low heat) = bolder but telegraphed risk. Loose softens loyalty pressure (cost of drift = less heat but also less reward).
        // Buffers: high loyalty or cleanMoney can prevent instant crew/heat spiral. Telegraph when heat + low loyalty.
        let e2 = specialCareer.enterprise
        if e2.heat > 65 && e2.loyalty < 40 {
            result.notes.append(DomainNote(title: "Heat Is Talking", text: "The people around you are starting to calculate their own exits. Loyalty is no longer assumed.", tags: [.crime, .risk]))
            // Buffer for agency: if you kept some clean, one more chance
            if e2.cleanMoneyRatio > 35 {
                specialCareer.enterprise.loyalty = max(specialCareer.enterprise.loyalty, 32)
            }
        }
        // Shape already touched e.riskTolerance/loyalty above; add resilience divergence for crime (grounded = slightly better loyalty floor when protecting "family")
        // P4 resilience for crime lightly applied (orchestrator safety + health/finance nets cover grounded "mercy" strongly).
        if e2.loyalty < 45 {
            specialCareer.enterprise.loyalty = (e2.loyalty + 1).clamped(to: 0...100)
        }
    }

    private func handleCommonBurnout(specialCareer: inout SpecialCareerState, result: inout DomainYearResult) {
        if specialCareer.burnout >= 90 {
            let e = specialCareer.enterprise
            let subtype = e.subtype

            // CE4: Rich, subtype-specific criminal exit stories (the "End of the Road" for each flavor)
            let exitTitle: String
            let exitText: String

            switch subtype {
            case .shadowOperative:
                exitTitle = "The Last Vanish"
                exitText = e.heat >= 70
                    ? "They finally got a name to go with the rumor. You disappeared one more time, but this time you didn't come back. Some nights you still check the locks twice."
                    : "You simply stopped being findable. The work dried up. The old contacts stopped calling. You became a story people tell when they want to feel interesting."
            case .streetCrime:
                exitTitle = "The Street Always Wins"
                exitText = e.loyalty < 30
                    ? "Your own people turned. The ones who didn't got hurt. You walked away with a limp and a story that ends with 'and then I got smart.'"
                    : "You got out before the next wave of kids decided you were the old problem. Some nights you miss the respect. Most nights you're just glad you're still breathing."
            case .grayMarketTrader:
                exitTitle = "The Books Closed"
                exitText = e.cleanMoneyRatio >= 65
                    ? "You became boring on purpose. The numbers looked legitimate. The people who mattered stopped asking questions. You still keep one set of books in your head, just in case."
                    : "One deal too many went sideways. You paid what you owed, burned what you could, and became a cautionary tale at the right poker tables."
            case .ventureCapitalist:
                exitTitle = "The Fund Wound Down"
                exitText = e.cleanMoneyRatio >= 70
                    ? "You became a 'family office' with very private clients. The returns are still excellent. The questions are fewer. You sleep in a house with your real name on the deed."
                    : "A few too many investments blew up in public. The respectable money left first. You still have the offshore structures, but the phone rings less often than it used to."
            case .corporateRaider:
                exitTitle = "The Last Hostile Takeover"
                exitText = e.notoriety >= 60
                    ? "You took one too many companies apart in the daylight. The regulators came. The targets fought back. You cashed out and bought a different kind of silence."
                    : "You won the war and lost the taste for it. The last company you stripped paid for a quiet life somewhere no one reads the business pages. You still dream in spreadsheets."
            case .transnationalCartel:
                exitTitle = "The Pipeline Runs Without You"
                exitText = e.heat >= 75
                    ? "The borders closed on you before your people did. You handed off what you could and vanished into a life that looks ordinary from the street."
                    : "You built something that outlived your face. The money still moves. The name people whisper is no longer yours — and that might be the only kind of win left."
            }

            exitTrack(on: &specialCareer)
            result.notes.append(DomainNote(title: exitTitle, text: exitText, tags: [.career, .crime, .progress]))
        }
    }

    @discardableResult
    private func activate(
        _ track: SpecialCareerTrack,
        specialCareer: inout SpecialCareerState,
        dossier: ChildhoodDossier? = nil,
        entryAge: Int? = nil
    ) -> Bool {
        var enteredDiamond = false
        if specialCareer.track != track {
            let previousTrack = specialCareer.track
            let carriedFame = specialCareer.fame
            let carriedAudience = specialCareer.audience
            let carriedHeat = specialCareer.heat
            let carriedNotoriety = specialCareer.notoriety

            specialCareer.track = track
            specialCareer.tier = 1
            specialCareer.yearsActive = 0
            specialCareer.lastPayout = 0
            specialCareer.audience = 10
            specialCareer.fame = 0
            specialCareer.heat = 0
            specialCareer.notoriety = 0
            specialCareer.advisors = []
            specialCareer.capitalUnderManagement = 0

            if track.isDiamondCareer {
                enteredDiamond = true
                if specialCareer.diamondOriginTrack == nil, previousTrack != .inactive {
                    specialCareer.diamondOriginTrack = previousTrack
                }
                specialCareer.firstDiamondEntryAge = specialCareer.firstDiamondEntryAge ?? entryAge
                specialCareer.diamondTransitions += 1

                // Diamond careers are built from reputation, not amnesia.
                specialCareer.fame = carriedFame
                specialCareer.audience = max(10, carriedAudience)
                if [.shadowOperative, .trader, .ventureCapitalist, .corporateRaider].contains(track) {
                    specialCareer.heat = carriedHeat
                    specialCareer.notoriety = carriedNotoriety
                }
            }

            let phys = dossier?.aptitudes.physical ?? 50
            let ent = dossier?.aptitudes.entrepreneurial ?? 50
            let crea = dossier?.aptitudes.creative ?? 50
            let soc = dossier?.aptitudes.social ?? 50
            let anal = dossier?.aptitudes.analytical ?? 50
            let tech = dossier?.aptitudes.technical ?? 50

            // S3a + dossier bias: high physical from childhood makes athlete path feel "meant to be"
            if track == .athlete {
                if specialCareer.athlete.naturalPotential < 55 {
                    var pot = Int.random(in: 58...82)
                    if let d = dossier, d.aptitudes.physical >= 55 {
                        pot = max(pot, min(95, phys + Int.random(in: 3...12)))
                    }
                    specialCareer.athlete.naturalPotential = max(specialCareer.athlete.naturalPotential, pot)
                }
                if specialCareer.athlete.personalBrand < 12 {
                    specialCareer.athlete.personalBrand = Int.random(in: 12...28)
                }
                if phys >= 60 {
                    specialCareer.athlete.durability = max(specialCareer.athlete.durability, 52)
                    specialCareer.athlete.peakPerformance = max(specialCareer.athlete.peakPerformance, 60)
                }
            }
            if track == .coach {
                if specialCareer.coaching.programPrestige < 25 && specialCareer.coaching.seasonWins == 0 {
                    var coach = CoachingState()
                    let coachingCred = specialCareer.athlete.personalBrand / 8
                    coach.programLevel = 2
                    coach.rosterTalent = (40 + max(0, phys - 45) / 3 + coachingCred).clamped(to: 28...68)
                    coach.playerDevelopment = (38 + max(0, anal - 45) / 3 + max(0, phys - 45) / 4).clamped(to: 25...70)
                    coach.schemeFit = (36 + max(0, anal - 45) / 2).clamped(to: 24...70)
                    coach.staffQuality = (34 + max(0, soc - 45) / 4).clamped(to: 22...65)
                    coach.lockerRoom = (48 + max(0, soc - 45) / 3).clamped(to: 35...78)
                    coach.recruitingReach = (34 + max(0, soc - 45) / 2 + coachingCred).clamped(to: 22...70)
                    coach.boosterPressure = Int.random(in: 24...42)
                    coach.programPrestige = (22 + coachingCred + max(0, soc - 55) / 4).clamped(to: 16...58)
                    specialCareer.coaching = coach
                    specialCareer.audience = max(specialCareer.audience, coach.programPrestige)
                    specialCareer.fame = max(specialCareer.fame, coach.programPrestige / 3)
                }
            }

            // E1 + dossier: entrepreneurial/analytical kids get stronger founder DNA at entry
            if track == .founder {
                if specialCareer.founder.vision < 45 {
                    var vision = Int.random(in: 50...72)
                    var execution = Int.random(in: 48...70)
                    if let d = dossier {
                        if d.aptitudes.entrepreneurial >= 55 {
                            vision = max(vision, ent + Int.random(in: 0...8))
                            execution = max(execution, (ent + anal) / 2 + Int.random(in: 0...6))
                        }
                    }
                    specialCareer.founder.vision = vision
                    specialCareer.founder.execution = execution
                    specialCareer.founder.teamHealth = Int.random(in: 52...68)
                    specialCareer.founder.productStage = Int.random(in: 12...25)
                    specialCareer.founder.control = Int.random(in: 82...95)
                    specialCareer.founder.founderMentalLoad = Int.random(in: 22...38)
                    specialCareer.founder.personalLegend = Int.random(in: 15...28)
                    specialCareer.founder.companyCulture = Int.random(in: 45...65)
                }
            }
            if track == .movieActor {
                if specialCareer.movieActor.roleCredits == 0 && specialCareer.movieActor.actingSkill < 45 {
                    var actor = MovieActorState()
                    actor.actingSkill = (34 + max(0, crea - 45) / 2).clamped(to: 25...72)
                    actor.screenPresence = (32 + max(0, soc - 45) / 2 + max(0, phys - 55) / 4).clamped(to: 22...70)
                    actor.auditionNetwork = (24 + max(0, soc - 45) / 3).clamped(to: 15...60)
                    actor.publicImage = (42 + max(0, soc - 50) / 4).clamped(to: 30...70)
                    actor.agentQuality = (18 + max(0, ent - 45) / 4 + max(0, soc - 45) / 4).clamped(to: 12...55)
                    actor.typecastRisk = Int.random(in: 10...24)
                    specialCareer.movieActor = actor
                    specialCareer.fame = max(specialCareer.fame, actor.screenPresence / 8)
                    specialCareer.audience = max(specialCareer.audience, actor.auditionNetwork / 2)
                }
            }
            if track == .musicProducer {
                if specialCareer.musicProducer.credits == 0 && specialCareer.musicProducer.demand < 25 {
                    var producer = MusicProducerState()
                    producer.sonicSignature = (35 + max(0, crea - 45) / 2).clamped(to: 25...72)
                    producer.studioQuality = (28 + max(0, tech - 45) / 3 + max(0, anal - 45) / 4).clamped(to: 20...65)
                    producer.network = (32 + max(0, soc - 45) / 2).clamped(to: 20...70)
                    producer.demand = (18 + max(0, crea - 50) / 3 + max(0, soc - 50) / 4).clamped(to: 10...55)
                    producer.royaltyCatalog = Int.random(in: 4...12)
                    producer.creditDisputes = Int.random(in: 5...20)
                    specialCareer.musicProducer = producer
                    specialCareer.fame = max(specialCareer.fame, producer.sonicSignature / 5)
                    specialCareer.audience = max(specialCareer.audience, producer.demand)
                }
            }
            if track == .movieProducer {
                if specialCareer.movieProducer.slateCount == 0 && specialCareer.movieProducer.prestige < 25 {
                    var film = MovieProducerState()
                    let creativeEdge = max(0, crea - 50)
                    let socialEdge = max(0, soc - 50)
                    let businessEdge = max(0, ent - 50)
                    film.slateCount = 1
                    film.developmentQuality = (30 + creativeEdge / 3 + anal / 20).clamped(to: 22...65)
                    film.castRelationships = (28 + socialEdge / 2).clamped(to: 18...70)
                    film.budgetControl = (32 + businessEdge / 3 + anal / 22).clamped(to: 22...68)
                    film.distributionLeverage = (18 + socialEdge / 4 + businessEdge / 5).clamped(to: 10...55)
                    film.productionChaos = (30 - businessEdge / 6).clamped(to: 12...55)
                    film.studioTrust = (30 + businessEdge / 4 + socialEdge / 5).clamped(to: 18...60)
                    film.backendCatalog = Int.random(in: 4...12)
                    film.prestige = (16 + creativeEdge / 3 + socialEdge / 5).clamped(to: 10...55)
                    specialCareer.movieProducer = film
                    specialCareer.audience = max(specialCareer.audience, film.prestige / 2 + film.distributionLeverage / 2)
                    specialCareer.fame = max(specialCareer.fame, film.prestige / 3)
                }
            }
            if track == .recordLabelOwner {
                if specialCareer.recordLabel.roster.isEmpty {
                    var label = RecordLabelState()
                    let creativeEdge = max(0, crea - 50)
                    let socialEdge = max(0, soc - 50)
                    let businessEdge = max(0, ent - 50)
                    label.labelPrestige = (18 + creativeEdge / 3 + businessEdge / 4).clamped(to: 12...55)
                    label.artistTrust = (52 + socialEdge / 3).clamped(to: 35...80)
                    label.catalogStrength = (8 + creativeEdge / 4).clamped(to: 5...35)
                    label.tourMachine = (10 + socialEdge / 5).clamped(to: 5...35)
                    label.cashflowPressure = (28 - businessEdge / 5).clamped(to: 12...55)
                    label.industryHeat = Int.random(in: 8...24)
                    label.artistPayoutPolicy = .standard
                    label.roster = [
                        makeLabelArtist(seed: ent * 3 + crea * 5 + soc, prestige: label.labelPrestige, trust: label.artistTrust)
                    ]
                    specialCareer.recordLabel = label
                    specialCareer.audience = max(specialCareer.audience, label.labelPrestige / 2 + label.roster[0].popularity / 2)
                    specialCareer.fame = max(specialCareer.fame, label.labelPrestige / 3)
                    specialCareer.heat = max(specialCareer.heat, label.industryHeat)
                }
            }
            // C1 + dossier: creative/social kids get better starting creator stats (platform velocity, brand)
            if track == .contentCreator {
                if specialCareer.creator.audience < 20 {
                    specialCareer.creator.platform = [.youtube, .tiktokShorts, .instagram, .twitch].randomElement()!
                    var aud = Int.random(in: 15...45)
                    var brand = Int.random(in: 35...65)
                    var qual = Int.random(in: 45...70)
                    if let d = dossier {
                        if d.aptitudes.creative >= 55 {
                            aud = max(aud, crea / 2 + Int.random(in: 5...12))
                            qual = max(qual, (crea + soc) / 2 + Int.random(in: 0...8))
                            brand = max(brand, crea - 5 + Int.random(in: 0...10))
                        }
                        if d.aptitudes.social >= 60 {
                            specialCareer.creator.algorithmFavor = max(specialCareer.creator.algorithmFavor, soc - 20)
                        }
                    }
                    specialCareer.creator.audience = aud
                    specialCareer.creator.algorithmFavor = max(specialCareer.creator.algorithmFavor, Int.random(in: 40...70))
                    specialCareer.creator.personalBrand = brand
                    specialCareer.creator.contentQuality = qual
                    specialCareer.creator.consistency = Int.random(in: 40...75)
                    specialCareer.creator.burnout = Int.random(in: 10...30)
                    specialCareer.creator.cancellationRisk = Int.random(in: 5...25)
                    specialCareer.creator.brandDealValue = Int.random(in: 5...20)
                }
            }

            // P1 + dossier: social kids start politics with better approval/charisma floor, analytical helps ethics/policy
            if track == .politics {
                if specialCareer.politics.approvalRating < 30 {
                    var approval = Int.random(in: 35...55)
                    var charisma = Int.random(in: 40...70)
                    if let d = dossier {
                        if d.aptitudes.social >= 55 {
                            approval = max(approval, soc - 5 + Int.random(in: 0...8))
                            charisma = max(charisma, soc - 10 + Int.random(in: 2...10))
                        }
                        if d.aptitudes.analytical >= 55 {
                            specialCareer.politics.ethics = max(specialCareer.politics.ethics, anal - 10)
                            specialCareer.politics.policyLegacy = max(specialCareer.politics.policyLegacy, 8)
                        }
                    }
                    // D3 edu synergy note: honors track from education already biases via handoff + qualification; dossier here keeps origin primary for seeding

                    specialCareer.politics.approvalRating = approval
                    specialCareer.politics.scandalHeat = Int.random(in: 5...20)
                    specialCareer.politics.policyLegacy = max(specialCareer.politics.policyLegacy, Int.random(in: 10...30))
                    specialCareer.politics.donorBase = Int.random(in: 20...40)
                    specialCareer.politics.ethics = max(specialCareer.politics.ethics, Int.random(in: 55...85))
                    specialCareer.politics.voterBase = Int.random(in: 25...45)
                    specialCareer.politics.charisma = charisma
                    specialCareer.politics.burnout = Int.random(in: 10...25)
                }
            }

            // CE1 + dossier bias: entrepreneurial/physical/social origins give criminal enterprise better starting "wiring"
            // (faster crew, better network, higher risk tolerance, slightly lower initial heat for "natural" operators)
            if [.shadowOperative, .trader, .ventureCapitalist, .corporateRaider, .crime].contains(track) {
                if specialCareer.enterprise.heat < 15 {
                    specialCareer.enterprise.subtype = mapTrackToEnterpriseSubtype(track)
                    var baseHeat = Int.random(in: 15...35)
                    var net = Int.random(in: 25...50)
                    var crew = Int.random(in: 3...8)
                    var risk = Int.random(in: 45...75)
                    var opsec = Int.random(in: 40...65)
                    if let d = dossier {
                        if d.aptitudes.entrepreneurial >= 55 {
                            risk = max(risk, ent - 15)
                            net = max(net, ent / 2)
                            baseHeat = max(10, baseHeat - 4) // hustlers start a bit cooler
                        }
                        if d.aptitudes.physical >= 55 {
                            crew = max(crew, phys / 12 + 2)
                            specialCareer.enterprise.loyalty = max(specialCareer.enterprise.loyalty, 58)
                        }
                        if d.aptitudes.social >= 55 {
                            net = max(net, soc / 2 + 5)
                            opsec = max(opsec, 8)
                        }
                    }
                    specialCareer.enterprise.heat = baseHeat
                    specialCareer.enterprise.notoriety = Int.random(in: 20...45)
                    specialCareer.enterprise.loyalty = max(specialCareer.enterprise.loyalty, Int.random(in: 45...70))
                    specialCareer.enterprise.operationalSecurity = opsec
                    specialCareer.enterprise.networkStrength = net
                    specialCareer.enterprise.cleanMoneyRatio = Int.random(in: 15...40)
                    specialCareer.enterprise.riskTolerance = risk
                    specialCareer.enterprise.crewSize = crew
                }
            }
        }
        return enteredDiamond
    }

    private func appendDiamondEntryNote(
        if enteredDiamond: Bool,
        transitionCount: Int,
        to result: inout DomainYearResult
    ) {
        guard enteredDiamond else { return }
        result.notes.append(
            DomainNote(
                title: transitionCount == 1 ? "First Empire" : "A New Empire",
                text: "This is no longer about your career. This is about what you leave behind — the institutions, the name, the empire.",
                tags: [.career, .progress]
            )
        )
    }

    private func makeLabelArtist(seed: Int, prestige: Int, trust: Int) -> LabelArtist {
        let names = ["Mira Vale", "Saint June", "Koa Black", "Nico Voss", "Luna Park", "Jules Static", "Aria Cross", "Noah Rook"]
        let roll = normalizedRoll(seed)
        var artist = LabelArtist()
        artist.name = names[abs(seed) % names.count]
        artist.talent = (38 + roll / 2 + prestige / 8).clamped(to: 25...92)
        artist.popularity = (12 + prestige / 4 + roll / 8).clamped(to: 5...70)
        artist.morale = (45 + trust / 4).clamped(to: 25...85)
        artist.contractFairness = (40 + trust / 5).clamped(to: 20...80)
        artist.catalogCount = 0
        artist.tourReadiness = (25 + roll / 4).clamped(to: 15...75)
        artist.yearlyEarnings = 0
        artist.clamp()
        return artist
    }

    private func bestArtistIndex(in label: RecordLabelState, by score: (LabelArtist) -> Int) -> Int {
        label.roster.indices.max { lhs, rhs in
            score(label.roster[lhs]) < score(label.roster[rhs])
        } ?? 0
    }

    /// Public entry for pitch-deck resolution path (ContentView) so we always seed through the same
    /// dossier-biased activate logic rather than raw mutation.
    static func activateSpecialCareerForPitch(track: SpecialCareerTrack, sector: BusinessSector?, into specialCareer: inout SpecialCareerState, dossier: ChildhoodDossier?) {
        let sys = SpecialCareerSystem()
        sys.activate(track, specialCareer: &specialCareer, dossier: dossier)
        if let s = sector {
            specialCareer.sector = s
        }
    }

    /// For DomainEffectApplier setTrack paths (event outcomes that drop you into a special career).
    /// Ensures dossier from childhood still shapes starting power even on "surprise" entries.
    static func biasSeedingForTrack(_ track: SpecialCareerTrack, into specialCareer: inout SpecialCareerState, dossier: ChildhoodDossier?) {
        let sys = SpecialCareerSystem()
        // activate will only re-seed if fields are low (the < checks inside protect existing runs)
        sys.activate(track, specialCareer: &specialCareer, dossier: dossier)
    }

    private func mapTrackToEnterpriseSubtype(_ track: SpecialCareerTrack) -> CriminalEnterpriseSubtype {
        switch track {
        case .shadowOperative: return .shadowOperative
        case .trader: return .grayMarketTrader
        case .ventureCapitalist: return .ventureCapitalist
        case .corporateRaider: return .corporateRaider
        case .crime: return .streetCrime
        default: return .streetCrime
        }
    }

    private func stateProxy(
        player: Player,
        career: CareerState,
        specialCareer: SpecialCareerState,
        finance: FinanceState,
        dossier: ChildhoodDossier? = nil
    ) -> GameState {
        var state = GameState()
        state.player = player
        state.career = career
        state.specialCareer = specialCareer
        state.finance = finance
        state.childhoodDossier = dossier
        return state
    }

    private func exitTrack(on specialCareer: inout SpecialCareerState) {
        if [.shadowOperative, .trader, .ventureCapitalist, .corporateRaider, .crime].contains(specialCareer.track) {
            // CE1: Criminal enterprise exits leave more lasting traces
            specialCareer.notoriety = max(specialCareer.notoriety, 15)
            specialCareer.heat = min(100, specialCareer.heat + 10)

            // CE4: Additional flavorful exit traces based on how you left
            let e = specialCareer.enterprise
            if e.cleanMoneyRatio >= 70 {
                specialCareer.notoriety = max(10, specialCareer.notoriety - 8) // cleaner exits leave less heat on the name
            }
            if e.heat >= 65 {
                specialCareer.heat = min(100, specialCareer.heat + 15) // hot exits echo for years
            }
        }

        specialCareer.track = .inactive
        specialCareer.tier = 0
        specialCareer.fame = 0
        specialCareer.audience = 0
        specialCareer.lastPayout = 0
        specialCareer.yearsActive = 0
        specialCareer.burnout = min(35, specialCareer.burnout)

        // P3: D4 post-exit lingering (life shape, recent stances echo in identity)
        // (called from resolves; richer flavor already in per-path "End of the Road" notes)
    }

    private func refreshTier(on specialCareer: inout SpecialCareerState) {
        let score = specialCareer.fame + specialCareer.audience
        specialCareer.tier = score >= 130 ? 3 : (score >= 70 ? 2 : 1)
    }

    private func normalizedRoll(_ seed: Int) -> Int {
        ((seed % 100) + 100) % 100
    }

    // P3 helper: simple life shape for founder exits (D4 integration)
    private func deriveSimpleFounderShape(founder: FounderState, special: SpecialCareerState) -> String {
        if founder.founderMentalLoad >= 70 && special.audience >= 50 {
            return "The price was real; the legend lingers in the scars."
        } else if special.audience >= 70 && founder.personalLegend >= 60 {
            return "You built something that outgrew you. The shape of your life is now the company's shadow."
        } else if founder.teamHealth < 40 {
            return "The team that made it possible barely speaks your name anymore."
        }
        return "The chapter closed with the books balanced and the vision half-realized."
    }
}

struct CrimeSystem {
    func advanceYear(input: CrimeDomainSnapshot, player: inout Player, career: inout CareerState, crime: inout CrimeState) -> DomainYearResult {
        var result = DomainYearResult()
        guard player.age >= 18, crime.status != .inactive else { return result }

        crime.yearsActive += 1
        crime.syncTierMetadata()

        let silentHighHeatYear = crime.heat >= 78 && crime.burnout <= 15 && crime.yearsActive == 1
        if silentHighHeatYear {
            crime.clamp()
            return result
        }

        let tier = input.activeTier ?? crime.resolvedTier
        let shape = LifeShapeResolver.resolve(recentStances: input.recentStances) ?? .pragmatic

        switch tier {
        case .street:
            resolveStreetCrimeYear(crime: &crime, player: &player, shape: shape, resilience: input.resilience, result: &result)
        case .organization:
            resolveOrganizationCrimeYear(crime: &crime, player: &player, shape: shape, resilience: input.resilience, result: &result)
        case .enterprise:
            resolveEnterpriseCrimeYear(crime: &crime, player: &player, shape: shape, resilience: input.resilience, result: &result)
        }

        applyCrimeForcedExit(crime: &crime, result: &result)

        if crime.status == .active, result.notes.isEmpty {
            result.notes.append(crimeTierVoice(for: tier))
        }

        crime.clamp()
        return result
    }

    func applyAction(_ choiceID: ActionChoiceID, player: inout Player, career: inout CareerState, crime: inout CrimeState) -> DomainYearResult {
        var result = DomainYearResult()
        guard player.age >= 18 else { return result }

        switch choiceID {
        case .streetCornerHustle:
            if crime.status == .inactive { crime.status = .active }
            crime.tier = .street
            let swing = Int.random(in: -4...14)
            let payout = Int.random(in: 400...2_800) + swing * 120
            result.financeEffects = FinanceEffects(cashDelta: payout)
            crime.heat += 8
            crime.notoriety += 5
            crime.personalRisk += 6
            crime.burnout += 4
            crime.lastPayout = max(crime.lastPayout, payout)
            result.notes.append(DomainNote(title: "Corner Night", text: swing > 4 ? "The block paid tonight. You felt every eye on you." : "Small money, big exposure.", tags: [.crime, .finance, .autonomousReaction]))
        case .dodgePatrol:
            crime.heat = cappedHeatReduction(current: crime.heat, relief: 12, notoriety: crime.notoriety)
            crime.personalRisk = max(0, crime.personalRisk - 5)
            result.notes.append(DomainNote(title: "Patrol Dodged", text: "You vanished before anyone had to say your name.", tags: [.crime, .autonomousReaction]))
        case .holdTerritory:
            if crime.status == .inactive { crime.status = .active }
            crime.tier = .organization
            crime.roleTier = max(crime.roleTier, 2)
            crime.territoryPressure = max(0, crime.territoryPressure - 6)
            crime.heat += 5
            crime.loyalty += 4
            crime.burnout += 3
            result.notes.append(DomainNote(title: "Corners Held", text: "The crew knows whose block this is — for now.", tags: [.crime, .autonomousReaction]))
        case .disciplineCrew:
            crime.tier = .organization
            crime.roleTier = max(crime.roleTier, 2)
            crime.loyalty += 7
            crime.burnout += 5
            crime.betrayalPressure = max(0, crime.betrayalPressure - 4)
            result.notes.append(DomainNote(title: "Discipline Delivered", text: "Someone remembered who signs the orders.", tags: [.crime, .autonomousReaction]))
        case .delegateOperation:
            crime.tier = .enterprise
            crime.roleTier = max(crime.roleTier, 3)
            crime.heat += 3
            crime.betrayalPressure += 4
            crime.personalRisk = max(0, crime.personalRisk - 4)
            result.financeEffects = FinanceEffects(cashDelta: Int.random(in: 4_000...14_000))
            result.notes.append(DomainNote(title: "Delegated", text: "The move happened without your face near it.", tags: [.crime, .finance, .autonomousReaction]))
        case .expandDomesticEmpire:
            crime.tier = .enterprise
            crime.roleTier = max(crime.roleTier, 3)
            crime.heat += 4
            crime.notoriety += 4
            crime.betrayalPressure += 2
            result.notes.append(DomainNote(title: "Domestic Reach", text: "Another front, another favor owed.", tags: [.crime, .autonomousReaction]))
        case .connectCartelNetwork:
            crime.tier = .enterprise
            crime.roleTier = 3
            crime.heat += 10
            crime.notoriety += 8
            crime.betrayalPressure += 6
            result.financeEffects = FinanceEffects(cashDelta: Int.random(in: 8_000...24_000))
            result.notes.append(DomainNote(title: "Pipeline Opened", text: "The money crosses borders now. So does the heat that does not sleep.", tags: [.crime, .finance, .risk, .autonomousReaction]))
        case .runScheme:
            if crime.status == .inactive { crime.status = .active }
            crime.heat += 7
            crime.notoriety += 6
            crime.burnout += 4
            crime.personalRisk += crime.resolvedTier == .street ? 5 : 2
            let payout = Int.random(in: 1_200...6_500)
            result.financeEffects = FinanceEffects(cashDelta: payout)
            crime.lastPayout = payout
            result.notes.append(DomainNote(title: "Scheme Landed", text: "Fast money moved. The trail moved with it.", tags: [.crime, .finance, .autonomousReaction]))
        case .layLow:
            crime.status = .layingLow
            crime.heat = cappedHeatReduction(current: crime.heat, relief: 10, notoriety: crime.notoriety)
            crime.personalRisk = max(0, crime.personalRisk - 3)
            result.notes.append(DomainNote(title: "Laying Low", text: "You chose air over momentum.", tags: [.crime, .autonomousReaction]))
        case .buildCrew:
            crime.tier = .organization
            crime.roleTier = max(crime.roleTier, 2)
            crime.crewID = crime.crewID ?? "crew-\(player.age)"
            crime.loyalty += 9
            crime.heat += 4
            result.notes.append(DomainNote(title: "Circle Built", text: "More faces owe you favors.", tags: [.crime, .autonomousReaction]))
        case .cleanMoney:
            crime.heat = cappedHeatReduction(current: crime.heat, relief: 6, notoriety: crime.notoriety)
            result.financeEffects = FinanceEffects(cashDelta: -1_200)
            result.notes.append(DomainNote(title: "Trail Scrubbed", text: "You made the numbers look ordinary.", tags: [.crime, .finance, .autonomousReaction]))
        case .stepAway:
            crime.status = .inactive
            result.notes.append(DomainNote(title: "Stepped Away", text: "You backed away before the lane owned you.", tags: [.crime, .autonomousReaction]))
        default:
            return result
        }

        crime.syncTierMetadata()
        crime.clamp()
        return result
    }

    private func resolveStreetCrimeYear(
        crime: inout CrimeState,
        player: inout Player,
        shape: LifeShape,
        resilience: LifeResilience,
        result: inout DomainYearResult
    ) {
        let variance = Int.random(in: -10...16)
        let payout = max(0, 1_500 + variance * 180)
        crime.lastPayout = payout
        result.financeEffects = FinanceEffects(cashDelta: payout)
        crime.heat += Int.random(in: 4...9)
        crime.notoriety += Int.random(in: 2...6)
        crime.personalRisk += Int.random(in: 2...6)
        crime.burnout += Int.random(in: 2...5)

        if shape == .drivenCurrent {
            crime.heat += 3
            crime.notoriety += 2
            crime.personalRisk += 2
        } else if shape == .looseEdges {
            crime.heat = max(0, crime.heat - 1)
        }

        if resilience == .grounded && crime.personalRisk > 55 {
            player.health = max(20, player.health - 2)
            result.healthEffects = HealthEffects(physical: -2, mental: -2, exercise: nil, nutrition: nil, stressManagement: -2)
        }

        if Int.random(in: 0...100) < 18 && crime.personalRisk > 50 {
            result.notes.append(DomainNote(title: "Close Call", text: "Someone on the block got picked up. It wasn't you — this time.", tags: [.crime, .risk]))
        }

        maybePromoteStreetToOrganization(crime: &crime, result: &result)
    }

    private func resolveOrganizationCrimeYear(
        crime: inout CrimeState,
        player: inout Player,
        shape: LifeShape,
        resilience: LifeResilience,
        result: inout DomainYearResult
    ) {
        let payout = 4_500 + crime.loyalty * 35 + max(0, 60 - crime.territoryPressure) * 40 + Int.random(in: -1_200...2_400)
        crime.lastPayout = payout
        result.financeEffects = FinanceEffects(cashDelta: payout)
        crime.heat += Int.random(in: 2...6)
        crime.notoriety += Int.random(in: 2...5)
        crime.territoryPressure += Int.random(in: -4...6)
        crime.burnout += Int.random(in: 1...4)
        crime.personalRisk = max(0, crime.personalRisk - 1)

        if crime.loyalty < 40 {
            crime.heat += 3
            crime.betrayalPressure += 2
            if Int.random(in: 0...100) < 22 {
                result.notes.append(DomainNote(title: "Crew Friction", text: "Someone in the circle is calculating their own exit.", tags: [.crime, .risk]))
            }
        }

        if shape == .drivenCurrent {
            crime.territoryPressure = max(0, crime.territoryPressure - 3)
            crime.heat += 2
        } else if shape == .looseEdges {
            crime.loyalty = max(0, crime.loyalty - 2)
        }

        if resilience == .grounded && crime.betrayalPressure > 45 {
            result.relationshipEffects = RelationshipEffects(partnerChange: -2)
        }

        if crime.yearsActive >= 6 && crime.notoriety >= 58 && crime.loyalty >= 55 && crime.roleTier < 3, Int.random(in: 0...100) < 16 {
            crime.roleTier = 3
            crime.tier = .enterprise
            result.notes.append(DomainNote(title: "Kingpin Threshold", text: "You are no longer hands-on. You are the math the hands answer to.", tags: [.crime, .progress]))
        }
        _ = player
    }

    private func resolveEnterpriseCrimeYear(
        crime: inout CrimeState,
        player: inout Player,
        shape: LifeShape,
        resilience: LifeResilience,
        result: inout DomainYearResult
    ) {
        let payout = 12_000 + crime.notoriety * 120 + crime.loyalty * 40 + Int.random(in: -6_000...10_000)
        crime.lastPayout = payout
        result.financeEffects = FinanceEffects(cashDelta: payout)
        crime.heat += Int.random(in: 1...4)
        crime.notoriety += Int.random(in: 2...4)
        crime.betrayalPressure += Int.random(in: 1...4)
        crime.personalRisk = max(0, crime.personalRisk - 2)

        if shape == .drivenCurrent {
            crime.betrayalPressure += 2
            crime.notoriety += 2
        } else if shape == .carefulShape {
            crime.heat = cappedHeatReduction(current: crime.heat, relief: 2, notoriety: crime.notoriety)
        }

        if crime.betrayalPressure >= 60 && Int.random(in: 0...100) < 20 {
            crime.loyalty = max(0, crime.loyalty - 8)
            crime.heat += 6
            result.notes.append(DomainNote(title: "Lieutenant Problem", text: "Someone close wants your seat.", tags: [.crime, .risk]))
        }

        if resilience == .grounded {
            result.relationshipEffects = RelationshipEffects(partnerChange: -3)
        }
        _ = player
    }

    private func maybePromoteStreetToOrganization(crime: inout CrimeState, result: inout DomainYearResult) {
        guard crime.resolvedTier == .street else { return }
        guard crime.yearsActive >= 3, crime.notoriety >= 38, crime.crewID != nil || crime.loyalty >= 35 else { return }
        guard Int.random(in: 0...100) < 28 else { return }
        crime.roleTier = max(crime.roleTier, 2)
        crime.tier = .organization
        result.notes.append(DomainNote(title: "Organization Life", text: "You are not solo on the block anymore.", tags: [.crime, .progress]))
    }

    private func applyCrimeForcedExit(crime: inout CrimeState, result: inout DomainYearResult) {
        guard crime.status == .active else { return }
        if crime.heat >= 88 && crime.burnout >= 70 {
            if Int.random(in: 0...100) < 35 {
                crime.status = .layingLow
                crime.heat = cappedHeatReduction(current: crime.heat, relief: 14, notoriety: crime.notoriety)
                result.notes.append(DomainNote(title: "Forced Underground", text: "Staying visible became stupid.", tags: [.crime, .risk]))
            } else if Int.random(in: 0...100) < 12 {
                crime.status = .inactive
                result.notes.append(DomainNote(title: "Lane Closed", text: "You got out while you still could.", tags: [.crime, .progress]))
            }
        }
    }

    private func crimeTierVoice(for tier: CrimeTier) -> DomainNote {
        switch tier {
        case .street:
            return DomainNote(title: "Street Arithmetic", text: "Every win feels borrowed. The block keeps the receipt.", tags: [.crime, .risk])
        case .organization:
            return DomainNote(title: "The Game", text: "Territory, loyalty, and heat traded places again.", tags: [.crime])
        case .enterprise:
            return DomainNote(title: "Top-Floor Paranoia", text: "The money is real. So is the distance between you and the people who would take your chair.", tags: [.crime, .fame])
        }
    }
}

struct MilitarySystem {
    func advanceYear(input: MilitaryDomainSnapshot, player: inout Player, military: inout MilitaryState, career: inout CareerState) -> DomainYearResult {
        var result = DomainYearResult()
        
        // Handle ROTC graduation commission
        if military.track == .inactive && input.education.pathway == .rotc && input.education.credentials.contains("Degree") {
            activate(track: .officer, branch: .army, military: &military, career: &career) // Default to Army, can be changed
            result.notes.append(DomainNote(title: "Commissioned", text: "You have been commissioned as a Second Lieutenant through ROTC.", tags: [.career]))
        }

        guard military.track != .inactive else { return result }

        military.yearsServed += 1
        if military.contractYearsRemaining > 0 {
            military.contractYearsRemaining -= 1
        }

        // Basic performance/discipline logic
        let disciplineDelta = (career.performance - 50) / 10
        military.discipline = (military.discipline + disciplineDelta).clamped(to: 0...100)
        
        // Specialty modifiers
        if let specialty = military.specialty {
            switch specialty {
            case .combat:
                military.fitness = (military.fitness + 2).clamped(to: 0...100)
                military.discipline += 1
            case .medical, .intelligence:
                player.smarts += 1
            case .aviation:
                military.discipline += 2
            case .logistics:
                career.performance += 2
            }
        }
        
        military.fitness = (military.fitness - (player.age > 40 ? 4 : 1)).clamped(to: 0...100)

        // Rank Progression
        if military.discipline >= 70 && career.performance >= 70 && military.rankLevel < 9 {
            var promotionChance = 20 + (military.discipline / 4) + (career.performance / 4)
            if military.specialty == .combat { promotionChance += 10 }
            
            if Int.random(in: 0...100) < promotionChance {
                military.rankLevel += 1
                military.rank = rankTitle(for: military.branch ?? .army, track: military.track, level: military.rankLevel)
                result.notes.append(DomainNote(title: "Military Promotion", text: "You were promoted to \(military.rank).", tags: [.career]))
            }
        }

        // Deployments
        resolveDeployment(military: &military, player: &player, result: &result, worldEra: input.worldEra)

        // PTSD / Trauma bleed
        if military.combatTrauma > 30 {
            player.health -= military.combatTrauma / 10
            result.coreEffects = CoreStatEffects(happiness: -military.combatTrauma / 15)
        }

        // AWOL Handling
        if military.isAWOL {
            military.heat += 15
            if military.heat >= 80 {
                result.notes.append(DomainNote(title: "Court Martial", text: "You were caught and court-martialed for going AWOL.", tags: [.career, .crime]))
                result.legalEffects = LegalEffects(
                    addExposures: [
                        LegalExposure(
                            source: "military_court_martial",
                            offense: .militaryDesertion,
                            severity: .serious,
                            evidence: 82,
                            jurisdiction: .military,
                            immediateCharge: true
                        )
                    ]
                )
                discharge(military: &military, career: &career, reason: "Dishonorable Discharge", honorable: false)
            }
        }

        // Contract Completion
        if military.contractYearsRemaining == 0 && !military.isAWOL {
            if military.track != .reserve {
                result.notes.append(DomainNote(title: "Contract Complete", text: "Your military contract has ended. You can choose to re-enlist or return to civilian life.", tags: [.career]))
            }
        }

        military.clamp()
        return result
    }

    private func resolveDeployment(military: inout MilitaryState, player: inout Player, result: inout DomainYearResult, worldEra: WorldEra) {
        let roll = Int.random(in: 0...100)
        let specialty = military.specialty ?? .combat
        
        switch military.deploymentStatus {
        case .home, .stationed:
            var deploymentChance = specialty == .combat ? 20 : 10
            if worldEra == .wartime { deploymentChance += 30 }
            
            if roll < deploymentChance {
                military.deploymentStatus = .deployed
                result.notes.append(DomainNote(title: "Deployment", text: "Your unit has been deployed overseas.", tags: [.career]))
            }
        case .deployed:
            var combatChance = specialty == .combat ? 25 : 5
            if worldEra == .wartime { combatChance += 40 }
            
            if roll < combatChance {
                military.deploymentStatus = .activeCombat
                result.notes.append(DomainNote(title: "Combat Zone", text: "Your deployment has turned into an active combat mission.", tags: [.career, .health]))
            } else if roll > 70 {
                military.deploymentStatus = .stationed
                result.notes.append(DomainNote(title: "Deployment End", text: "Your deployment ended and you returned to your home station.", tags: [.career]))
            }
        case .activeCombat:
            let injuryRoll = Int.random(in: 0...100)
            let injuryThreshold = specialty == .combat ? 15 : 5
            
            if injuryRoll < injuryThreshold {
                player.health -= Int.random(in: 15...40)
                military.combatTrauma += 20
                result.notes.append(DomainNote(title: "Combat Injury", text: "You were wounded in action. The trauma weighs on you.", tags: [.health]))
            } else if injuryRoll > 85 {
                military.medals.append("Silver Star")
                military.combatTrauma += 10
                result.notes.append(DomainNote(title: "Valor", text: "You distinguished yourself in fierce combat.", tags: [.career]))
            } else {
                military.combatTrauma += 5
            }
            
            if roll > 60 {
                military.deploymentStatus = .deployed
                result.notes.append(DomainNote(title: "Combat Operations Cease", text: "Active combat operations have ended for your unit.", tags: [.career]))
            }
        }
    }

    func applyAction(_ choiceID: ActionChoiceID, player: inout Player, military: inout MilitaryState, career: inout CareerState, education: EducationState) -> DomainYearResult {
        var result = DomainYearResult()

        switch choiceID {
        case .enlistArmy, .enlistNavy, .enlistAirForce, .enlistMarines, .enlistCoastGuard, .enlistSpaceForce:
            guard player.age >= 18 else { break }
            guard education.credentials.contains("Diploma") else {
                result.notes.append(DomainNote(title: "Recruitment Rejected", text: "You need at least a High School Diploma to enlist."))
                break
            }
            let branch = branchFrom(choiceID: choiceID)
            activate(track: .enlisted, branch: branch, military: &military, career: &career)
            result.notes.append(DomainNote(title: "Enlistment", text: "You enlisted in the \(branch.displayName).", tags: [.career]))

        case .commissionArmy, .commissionNavy, .commissionAirForce, .commissionMarines, .commissionCoastGuard, .commissionSpaceForce:
            guard player.age >= 18 else { break }
            guard education.credentials.contains("Degree") else {
                result.notes.append(DomainNote(title: "Commission Rejected", text: "You need a University Degree to become an officer."))
                break
            }
            let branch = branchFrom(choiceID: choiceID)
            activate(track: .officer, branch: branch, military: &military, career: &career)
            result.notes.append(DomainNote(title: "Commission", text: "You were commissioned as an officer in the \(branch.displayName).", tags: [.career]))

        case .joinReservesArmy, .joinReservesNavy, .joinReservesAirForce, .joinReservesMarines, .joinReservesCoastGuard, .joinReservesSpaceForce:
            guard player.age >= 18 else { break }
            guard education.credentials.contains("Diploma") else {
                result.notes.append(DomainNote(title: "Reserves Rejected", text: "You need at least a High School Diploma to join the reserves."))
                break
            }
            let branch = branchFrom(choiceID: choiceID)
            activate(track: .reserve, branch: branch, military: &military, career: &career)
            result.notes.append(DomainNote(title: "Reserves", text: "You joined the \(branch.displayName) Reserves.", tags: [.career]))

        case .selectCombatMOS: military.specialty = .combat
        case .selectMedicalMOS: military.specialty = .medical
        case .selectAviationMOS: military.specialty = .aviation
        case .selectIntelMOS: military.specialty = .intelligence
        case .selectLogisticsMOS: military.specialty = .logistics

        case .seekVAHealthcare:
            military.combatTrauma = max(0, military.combatTrauma - 15)
            player.health += 10
            result.notes.append(DomainNote(title: "VA Healthcare", text: "You are receiving treatment for your service-related trauma.", tags: [.health]))

        case .useGIBill:
            if military.isVeteran {
                military.hasGIBill = true
                result.notes.append(DomainNote(title: "GI Bill Activated", text: "Your education benefits are now active.", tags: [.education]))
            }

        case .claimPension:
            if military.hasPension {
                career.annualIncome += 25000
                result.notes.append(DomainNote(title: "Pension Claimed", text: "Your military pension has been added to your annual income.", tags: [.finance]))
            }

        case .militaryService:
            career.performance = (career.performance + 5).clamped(to: 0...100)
            military.discipline = (military.discipline + 4).clamped(to: 0...100)
            military.fitness = (military.fitness + 3).clamped(to: 0...100)
            military.heat = max(0, military.heat - 5)

        // D1: New military static instants + deploy
        case .ptFocus:
            military.fitness = (military.fitness + 8).clamped(to: 0...100)
            military.discipline = (military.discipline + 5).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "PT Focus", text: "The body that serves is the one that survives the year.", tags: [.health, .military]))
        case .seekCounsel:
            military.combatTrauma = max(0, military.combatTrauma - 8)
            player.health = (player.health + 5).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Counsel", text: "You spoke the things that don't show on a uniform. The weight lifted a little.", tags: [.health, .military]))
        case .studyTradition:
            military.discipline = (military.discipline + 6).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Tradition", text: "You learned why the patch on your shoulder matters. Discipline is a story you now tell yourself.", tags: [.military]))
        case .deployTour:
            military.yearsServed += 1
            let trauma = Int.random(in: 8...18)
            military.combatTrauma = (military.combatTrauma + trauma).clamped(to: 0...100)
            let medalChance = military.discipline + military.fitness / 2
            if medalChance > 70 {
                military.medals.append("Deployment Citation")
                career.performance = (career.performance + 12).clamped(to: 0...100)
                result.notes.append(DomainNote(title: "Deployment Tour", text: "You came back with a citation and a story that will never leave you. The body paid; the record improved.", tags: [.military, .career]))
            } else {
                result.notes.append(DomainNote(title: "Deployment Tour", text: "You served the tour. The experience changed you more than the medals you didn't bring home.", tags: [.military, .health]))
            }
        
        case .goAWOL:
            military.isAWOL = true
            military.heat += 20
            result.notes.append(DomainNote(title: "AWOL", text: "You walked away from your post. You are now a deserter.", tags: [.career, .crime]))
        
        case .desert:
            result.notes.append(DomainNote(title: "Desertion", text: "You have abandoned your military duties entirely.", tags: [.career, .crime]))
            military.isAWOL = true
            military.heat += 40
            discharge(military: &military, career: &career, reason: "Desertion", honorable: false)

        case .militaryRetirement:
            if military.yearsServed >= 20 || (military.contractYearsRemaining == 0 && !military.isAWOL) {
                let honorable = !military.isAWOL && military.discipline >= 40
                discharge(military: &military, career: &career, reason: "Honorable Discharge", honorable: honorable)
                result.notes.append(DomainNote(title: "Military Retirement", text: "You completed your service and returned to civilian life.", tags: [.career]))
            } else {
                result.notes.append(DomainNote(title: "Resignation Denied", text: "You are still under contract."))
            }

        default: break
        }

        military.clamp()
        return result
    }

    static func branchName(for choiceID: ActionChoiceID) -> String {
        switch choiceID {
        case .enlistArmy, .commissionArmy, .joinReservesArmy: return "Army"
        case .enlistNavy, .commissionNavy, .joinReservesNavy: return "Navy"
        case .enlistAirForce, .commissionAirForce, .joinReservesAirForce: return "Air Force"
        case .enlistMarines, .commissionMarines, .joinReservesMarines: return "Marines"
        case .enlistCoastGuard, .commissionCoastGuard, .joinReservesCoastGuard: return "Coast Guard"
        case .enlistSpaceForce, .commissionSpaceForce, .joinReservesSpaceForce: return "Space Force"
        default: return ""
        }
    }

    private func branchFrom(choiceID: ActionChoiceID) -> MilitaryBranch {
        switch choiceID {
        case .enlistArmy, .commissionArmy, .joinReservesArmy: return .army
        case .enlistNavy, .commissionNavy, .joinReservesNavy: return .navy
        case .enlistAirForce, .commissionAirForce, .joinReservesAirForce: return .airForce
        case .enlistMarines, .commissionMarines, .joinReservesMarines: return .marines
        case .enlistCoastGuard, .commissionCoastGuard, .joinReservesCoastGuard: return .coastGuard
        case .enlistSpaceForce, .commissionSpaceForce, .joinReservesSpaceForce: return .spaceForce
        default: return .army
        }
    }

    private func activate(track: MilitaryTrack, branch: MilitaryBranch, military: inout MilitaryState, career: inout CareerState) {
        military.track = track
        military.branch = branch
        military.yearsServed = 0
        military.contractYearsRemaining = 4
        military.rankLevel = 1
        military.rank = rankTitle(for: branch, track: track, level: 1)
        military.isAWOL = false
        military.heat = 0
        
        career.status = .military
        career.profile = .militaryService
        if track == .reserve {
            career.annualIncome = 8000
        } else {
            career.annualIncome = track == .officer ? 45000 : 25000
        }
        career.performance = 50
    }

    private func discharge(military: inout MilitaryState, career: inout CareerState, reason: String, honorable: Bool) {
        if honorable {
            military.isVeteran = true
            if military.yearsServed >= 4 {
                military.hasGIBill = true
            }
            if military.yearsServed >= 20 {
                military.hasPension = true
            }
        }
        
        military.track = .inactive
        military.deploymentStatus = .home
        career.status = .unemployed
        career.profile = honorable ? .stableAdmin : .physicalLabor
    }

    private func rankTitle(for branch: MilitaryBranch, track: MilitaryTrack, level: Int) -> String {
        if track == .officer {
            switch branch {
            case .navy, .coastGuard:
                let titles = ["ENS", "LTJG", "LT", "LCDR", "CDR", "CAPT", "RDML", "RADM", "VADM", "ADM"]
                return titles[safe: level - 1] ?? "Officer"
            default:
                let titles = ["2LT", "1LT", "CPT", "MAJ", "LTC", "COL", "BG", "MG", "LTG", "GEN"]
                return titles[safe: level - 1] ?? "Officer"
            }
        } else {
            switch branch {
            case .navy, .coastGuard:
                let titles = ["SR", "SA", "SN", "PO3", "PO2", "PO1", "CPO", "SCPO", "MCPO"]
                return titles[safe: level - 1] ?? "Enlisted"
            case .marines:
                let titles = ["Pvt", "PFC", "LCpl", "Cpl", "Sgt", "SSgt", "GySgt", "MSgt", "MGySgt"]
                return titles[safe: level - 1] ?? "Enlisted"
            default:
                let titles = ["PV1", "PV2", "PFC", "SPC", "SGT", "SSG", "SFC", "MSG", "SGM"]
                return titles[safe: level - 1] ?? "Enlisted"
            }
        }
    }
}

struct MilitaryDomainSnapshot {
    let player: Player
    let military: MilitaryState
    let career: CareerState
    let education: EducationState
    let worldEra: WorldEra
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
