import Foundation

struct CombatRandomSource {
    private(set) var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let width = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int((state >> 32) % width)
    }
}

struct CombatCareerSystem {
    func handles(_ choiceID: ActionChoiceID) -> Bool {
        switch choiceID {
        case .startBoxingCareer, .startMMACareer,
             .acceptSafeFight, .acceptRankedFight, .acceptDangerousFight,
             .boxingPowerCamp, .boxingTechniqueCamp, .mmaStrikingCamp, .mmaGrapplingCamp,
             .combatConditioningCamp, .combatRecoveryCamp,
             .boxingPressureStrategy, .boxingCounterStrategy, .boxingOutsideStrategy,
             .mmaStrikeStrategy, .mmaWrestleStrategy, .mmaMixedStrategy,
             .crossoverCombatDiscipline, .retireFromCombat, .startFightEmpire,
             .recruitFightProspect, .buildFightCamp, .developFightProspect, .bookFightEvent,
             .negotiateBroadcastDeal, .protectFighterHealth, .promoteGrudgeMatch:
            return true
        default:
            return false
        }
    }

    func applyAction(
        _ choiceID: ActionChoiceID,
        player: inout Player,
        career: inout CareerState,
        specialCareer: inout SpecialCareerState,
        finance: FinanceState,
        dossier: ChildhoodDossier?
    ) -> DomainYearResult {
        var result = DomainYearResult()

        switch choiceID {
        case .startBoxingCareer:
            startCareer(.boxing, player: player, specialCareer: &specialCareer, dossier: dossier, result: &result)
        case .startMMACareer:
            startCareer(.mma, player: player, specialCareer: &specialCareer, dossier: dossier, result: &result)
        case .acceptSafeFight:
            acceptOffer(.safe, specialCareer: &specialCareer, result: &result)
        case .acceptRankedFight:
            acceptOffer(.ranked, specialCareer: &specialCareer, result: &result)
        case .acceptDangerousFight:
            acceptOffer(.dangerous, specialCareer: &specialCareer, result: &result)
        case .boxingPowerCamp:
            applyCamp(.boxingPower, specialCareer: &specialCareer, result: &result)
        case .boxingTechniqueCamp:
            applyCamp(.boxingTechnique, specialCareer: &specialCareer, result: &result)
        case .mmaStrikingCamp:
            applyCamp(.mmaStriking, specialCareer: &specialCareer, result: &result)
        case .mmaGrapplingCamp:
            applyCamp(.mmaGrappling, specialCareer: &specialCareer, result: &result)
        case .combatConditioningCamp:
            applyCamp(.conditioning, specialCareer: &specialCareer, result: &result)
        case .combatRecoveryCamp:
            applyCamp(.recovery, specialCareer: &specialCareer, result: &result)
        case .boxingPressureStrategy:
            setStrategy(.boxingPressure, specialCareer: &specialCareer, result: &result)
        case .boxingCounterStrategy:
            setStrategy(.boxingCounter, specialCareer: &specialCareer, result: &result)
        case .boxingOutsideStrategy:
            setStrategy(.boxingOutside, specialCareer: &specialCareer, result: &result)
        case .mmaStrikeStrategy:
            setStrategy(.mmaStrike, specialCareer: &specialCareer, result: &result)
        case .mmaWrestleStrategy:
            setStrategy(.mmaWrestle, specialCareer: &specialCareer, result: &result)
        case .mmaMixedStrategy:
            setStrategy(.mmaMixed, specialCareer: &specialCareer, result: &result)
        case .crossoverCombatDiscipline:
            crossover(player: player, specialCareer: &specialCareer, result: &result)
        case .retireFromCombat:
            retire(specialCareer: &specialCareer, result: &result)
        case .startFightEmpire:
            startFightEmpire(player: player, finance: finance, specialCareer: &specialCareer, result: &result)
        case .recruitFightProspect:
            guard specialCareer.track == .fightEmpire else { break }
            var empire = specialCareer.fightEmpire
            let discipline = empire.originDiscipline ?? .boxing
            let names = ["Mara Stone", "Dante Cross", "Luis Vale", "Nia Price", "Cole Mercer", "Imani Reed"]
            let seed = player.age * 31 + empire.prospects.count * 17 + empire.gymReputation
            var rng = CombatRandomSource(seed: UInt64(max(1, seed)))
            empire.prospects.append(
                FightProspect(
                    name: names[rng.nextInt(in: 0...(names.count - 1))],
                    discipline: discipline,
                    potential: rng.nextInt(in: 55...90),
                    readiness: rng.nextInt(in: 24...48),
                    trust: 58
                )
            )
            empire.operatingCashPressure += 7
            specialCareer.fightEmpire = empire
            result.financeEffects = FinanceEffects(cashDelta: -2_500)
            result.notes.append(DomainNote(title: "Prospect Signed", text: "A raw fighter put their future in your hands.", tags: [.career, .finance]))
        case .buildFightCamp:
            guard specialCareer.track == .fightEmpire else { break }
            specialCareer.fightEmpire.gymReputation += 8
            specialCareer.fightEmpire.fighterTrust += 5
            specialCareer.fightEmpire.operatingCashPressure += 5
            result.financeEffects = FinanceEffects(cashDelta: -6_000)
            result.notes.append(DomainNote(title: "Camp Upgraded", text: "The room now looks and feels like a place serious fighters can grow.", tags: [.career, .finance]))
        case .developFightProspect:
            guard specialCareer.track == .fightEmpire else { break }
            if let index = specialCareer.fightEmpire.prospects.indices.min(by: {
                specialCareer.fightEmpire.prospects[$0].readiness < specialCareer.fightEmpire.prospects[$1].readiness
            }) {
                specialCareer.fightEmpire.prospects[index].readiness += 9
                specialCareer.fightEmpire.prospects[index].trust += 4
            }
            specialCareer.fightEmpire.fighterTrust += 3
            result.notes.append(DomainNote(title: "Prospect Developed", text: "The hype slowed down and the fighter got better.", tags: [.career]))
        case .bookFightEvent:
            guard specialCareer.track == .fightEmpire else { break }
            specialCareer.fightEmpire.eventQuality += 8
            specialCareer.fightEmpire.promotionReach += 5
            specialCareer.fightEmpire.operatingCashPressure += 8
            result.financeEffects = FinanceEffects(cashDelta: -8_000)
            result.notes.append(DomainNote(title: "Event Booked", text: "The venue and card are committed. Now the promotion has to sell.", tags: [.career, .finance, .risk]))
        case .negotiateBroadcastDeal:
            guard specialCareer.track == .fightEmpire else { break }
            specialCareer.fightEmpire.promotionReach += 10
            specialCareer.fightEmpire.regulatoryPressure += 3
            specialCareer.fightEmpire.operatingCashPressure = max(0, specialCareer.fightEmpire.operatingCashPressure - 4)
            result.notes.append(DomainNote(title: "Broadcast Deal", text: "The cards travel farther now, along with the scrutiny.", tags: [.career, .finance]))
        case .protectFighterHealth:
            guard specialCareer.track == .fightEmpire else { break }
            specialCareer.fightEmpire.fighterTrust += 10
            specialCareer.fightEmpire.regulatoryPressure = max(0, specialCareer.fightEmpire.regulatoryPressure - 9)
            specialCareer.fightEmpire.eventQuality = max(0, specialCareer.fightEmpire.eventQuality - 2)
            result.notes.append(DomainNote(title: "Bad Bout Cancelled", text: "You protected the fighter and absorbed the business cost.", tags: [.career, .health]))
        case .promoteGrudgeMatch:
            guard specialCareer.track == .fightEmpire else { break }
            specialCareer.fightEmpire.promotionReach += 14
            specialCareer.fightEmpire.eventQuality += 5
            specialCareer.fightEmpire.fighterTrust -= 8
            specialCareer.fightEmpire.regulatoryPressure += 10
            result.notes.append(DomainNote(title: "Conflict Sold", text: "The clips traveled. So did the ugliness around the event.", tags: [.career, .risk, .finance]))
        default:
            break
        }

        specialCareer.clamp()
        return result
    }

    func advanceCombatYear(
        player: inout Player,
        specialCareer: inout SpecialCareerState,
        seed: UInt64? = nil
    ) -> DomainYearResult {
        var result = DomainYearResult()
        guard specialCareer.track == .athlete,
              specialCareer.athlete.sport == .combatSports,
              specialCareer.athlete.combat.discipline != nil else {
            return result
        }

        var combat = specialCareer.athlete.combat
        if combat.suspensionYears > 0 {
            combat.suspensionYears -= 1
            combat.careerWear = max(0, combat.careerWear - 2)
            combat.opponentOffers = generateOffers(for: combat, age: player.age)
            specialCareer.athlete.combat = combat
            result.notes.append(DomainNote(title: "Suspension Year", text: "The calendar moved without a sanctioned fight. The body recovered; the ranking did not.", tags: [.career, .health]))
            return result
        }

        guard let opponent = combat.scheduledOpponent else {
            applyDevelopmentYear(to: &combat, specialCareer: &specialCareer, player: player, result: &result)
            specialCareer.athlete.combat = combat
            return result
        }

        let ageSeed = player.age * 1_009
        let recordSeed = combat.wins * 97 + combat.losses * 53
        let opponentSeed = opponent.rating * 31
        let fallbackSeed = UInt64(max(1, ageSeed + recordSeed + opponentSeed))
        let fightSeed = seed ?? fallbackSeed
        var rng = CombatRandomSource(seed: fightSeed)
        let playerRating = rating(for: combat)
        let matchup = matchupModifier(combat: combat, opponent: opponent)
        let camp = campModifier(combat.campFocus)
        let strategy = strategyModifier(combat.fightStrategy, discipline: combat.discipline)
        let conditioning = combat.skills.conditioning / 5
        let wearPenalty = combat.careerWear / 3
        let roll = rng.nextInt(in: -18...18)
        let score = playerRating + matchup + camp + strategy + conditioning + roll - wearPenalty
        let margin = score - opponent.rating
        let draw = abs(margin) <= 2 && rng.nextInt(in: 0...100) < 12
        let won = !draw && margin >= 0
        let method = fightMethod(won: won, draw: draw, margin: margin, combat: combat, rng: &rng)
        let wasChampion = combat.isChampion

        if draw {
            combat.draws += 1
        } else if won {
            combat.wins += 1
            if method != "Decision" { combat.finishes += 1 }
            let gain = opponent.tier == .dangerous ? 9 : (opponent.tier == .ranked ? 6 : 3)
            combat.ranking = min(50, combat.ranking + gain)
            if opponent.titleOpportunity || combat.ranking >= 40 {
                combat.isChampion = true
                combat.stage = combat.titleDefenses > 0 ? .defendingChampion : .champion
                if wasChampion { combat.titleDefenses += 1 }
            } else if combat.ranking >= 24 {
                combat.stage = .rankedContender
            }
        } else {
            combat.losses += 1
            combat.ranking = max(0, combat.ranking - (opponent.tier == .safe ? 7 : 4))
            if combat.isChampion {
                combat.isChampion = false
                combat.stage = .rankedContender
            }
        }

        let purse = max(500, opponent.purse + (combat.isChampion ? opponent.purse / 2 : 0))
        combat.careerEarnings += purse
        combat.activeContract.fightsRemaining = max(0, combat.activeContract.fightsRemaining - 1)
        specialCareer.lastPayout = purse
        let fameDelta = draw ? 1 : (won ? (opponent.tier == .dangerous ? 14 : 7) : -4)
        specialCareer.fame = (specialCareer.fame + fameDelta).clamped(to: 0...100)
        specialCareer.audience = (specialCareer.audience + (won ? 8 : -3)).clamped(to: 0...100)

        let damageRoll = rng.nextInt(in: 0...100)
        let baseDamage = combat.discipline == .boxing ? 13 : 10
        let danger = opponent.tier == .dangerous ? 12 : (opponent.tier == .ranked ? 6 : 0)
        let lossRisk = won ? 0 : 10
        var injuryText: String?
        if damageRoll < baseDamage + danger + lossRisk + combat.careerWear / 5 {
            let injuries = combat.discipline == .boxing
                ? ["Cut requiring recovery", "Fractured hand", "Knockout suspension"]
                : ["Cut requiring recovery", "Joint sprain", "Knockout suspension"]
            injuryText = injuries[rng.nextInt(in: 0...(injuries.count - 1))]
            combat.suspensionYears = injuryText == "Knockout suspension" ? 1 : 0
            combat.careerWear += injuryText == "Fractured hand" || injuryText == "Joint sprain" ? 10 : 7
            result.healthEffects = HealthEffects(physical: -6, mental: -2, stressManagement: -2)
        } else {
            combat.careerWear += won ? 3 : 5
        }

        if combat.careerWear >= 88 || player.age >= (combat.discipline == .boxing ? 39 : 37) {
            combat.stage = .retired
            combat.scheduledOpponent = nil
            result.notes.append(DomainNote(title: "Forced Retirement", text: "The body and the commission agreed before your ambition did. The fighting career is over.", tags: [.career, .health, .progress]))
        }

        if won {
            let accolade = combat.isChampion
                ? "\(combat.discipline?.championshipOrganization ?? "World") Champion"
                : "\(combat.discipline?.promotionName ?? "Regional") Ranked Win"
            if !specialCareer.athlete.accolades.contains(accolade) {
                specialCareer.athlete.accolades.append(accolade)
            }
            specialCareer.athlete.careerHighlights.append("\(method) win over \(opponent.name)")
            if combat.isChampion, wasChampion {
                let defense = "Title Defense #\(combat.titleDefenses)"
                if !specialCareer.athlete.accolades.contains(defense) {
                    specialCareer.athlete.accolades.append(defense)
                }
            }
            if method == "Knockout" || method == "Technical Knockout" || method == "Submission" {
                let award = method == "Submission" ? "Submission of the Year Candidate" : "Knockout of the Year Candidate"
                if !specialCareer.athlete.accolades.contains(award) {
                    specialCareer.athlete.accolades.append(award)
                }
            }
        }

        let rankingText = combat.isChampion ? "Champion" : (combat.ranking >= 24 ? "#\(max(1, 51 - combat.ranking)) contender" : "Regional rank \(combat.ranking)")
        let causes = decisiveCauses(
            won: won,
            matchup: matchup,
            camp: combat.campFocus,
            strategy: combat.fightStrategy,
            conditioning: combat.skills.conditioning,
            opponent: opponent
        )
        let summary = CombatFightSummary(
            id: "combat-\(player.age)-\(combat.wins)-\(combat.losses)-\(combat.draws)",
            age: player.age,
            discipline: combat.discipline ?? .boxing,
            opponentName: opponent.name,
            result: draw ? "Draw" : (won ? "Win" : "Loss"),
            method: method,
            record: combat.recordLabel,
            rankingText: rankingText,
            purse: purse,
            fameDelta: fameDelta,
            injuryText: injuryText,
            suspensionYears: combat.suspensionYears,
            decisiveCauses: causes
        )

        combat.lastFightAge = player.age
        combat.scheduledOpponent = nil
        combat.campFocus = nil
        combat.fightStrategy = nil
        if combat.activeContract.fightsRemaining == 0, combat.stage != .retired {
            let organization = combat.isChampion
                ? combat.discipline?.championshipOrganization
                : combat.discipline?.promotionName
            combat.activeContract = CombatContract(
                promotionName: organization ?? "",
                fightsRemaining: 3,
                basePurse: max(1_000, combat.activeContract.basePurse + combat.ranking * 80)
            )
        }
        combat.opponentOffers = combat.stage == .retired ? [] : generateOffers(for: combat, age: player.age + 1)
        if combat.stage == .retired,
           (combat.titleDefenses >= 2 || combat.wins >= 16),
           !specialCareer.athlete.accolades.contains("Combat Sports Hall of Fame") {
            specialCareer.athlete.accolades.append("Combat Sports Hall of Fame")
        }
        combat.clamp()
        specialCareer.athlete.combat = combat
        specialCareer.athlete.peakPerformance = max(10, specialCareer.athlete.peakPerformance - combat.careerWear / 25)
        result.financeEffects = FinanceEffects(cashDelta: purse)
        result.combatFightSummary = summary
        result.notes.append(DomainNote(title: "\(summary.result) by \(summary.method)", text: "Against \(opponent.name), the record moved to \(summary.record). Purse: $\(purse).", tags: [.career, .finance, .health]))
        return result
    }

    func advanceFightEmpireYear(
        player: Player,
        specialCareer: inout SpecialCareerState,
        seed: UInt64? = nil
    ) -> DomainYearResult {
        var result = DomainYearResult()
        guard specialCareer.track == .fightEmpire else { return result }
        var empire = specialCareer.fightEmpire
        var rng = CombatRandomSource(seed: seed ?? UInt64(max(1, player.age * 811 + empire.gymReputation * 29 + empire.promotionReach)))

        for index in empire.prospects.indices {
            let gain = max(1, (empire.gymReputation + empire.fighterTrust) / 35)
            empire.prospects[index].readiness = min(empire.prospects[index].potential, empire.prospects[index].readiness + gain)
            empire.prospects[index].trust = (empire.prospects[index].trust + (empire.fighterTrust - 50) / 15).clamped(to: 0...100)
        }

        let rosterValue = empire.prospects.reduce(0) { $0 + $1.readiness + $1.potential / 2 }
        let eventScore = empire.eventQuality + empire.promotionReach + rosterValue / 10 + rng.nextInt(in: -12...12)
        let revenue = max(0, eventScore * 220 - empire.operatingCashPressure * 90)
        empire.lastEventProfit = revenue
        empire.gymReputation += eventScore >= 120 ? 6 : (eventScore >= 80 ? 2 : -3)
        empire.promotionReach += eventScore >= 110 ? 4 : 0
        empire.operatingCashPressure += empire.prospects.count * 2 + 3
        empire.regulatoryPressure += empire.fighterTrust < 35 ? 7 : -2

        if empire.regulatoryPressure >= 85 {
            if !empire.prospects.isEmpty { empire.prospects.removeLast() }
            empire.promotionReach -= 8
            result.notes.append(DomainNote(title: "Commission Intervention", text: "The promotion lost a fighter and a chunk of reach under regulatory pressure.", tags: [.career, .risk]))
        } else if revenue > 0 {
            result.notes.append(DomainNote(title: "Fight Business Paid", text: "The gym and promotion produced a $\(revenue) operating return this year.", tags: [.career, .finance]))
        }

        empire.clamp()
        specialCareer.fightEmpire = empire
        specialCareer.audience = min(100, specialCareer.audience + max(0, empire.promotionReach / 25))
        specialCareer.fame = min(100, specialCareer.fame + max(0, empire.gymReputation / 30))
        result.financeEffects = FinanceEffects(cashDelta: revenue)
        return result
    }

    static func qualifiesForFightEmpire(state: GameState) -> Bool {
        let combat = state.specialCareer.athlete.combat
        guard combat.stage == .retired, state.finance.cashOnHand >= 40_000 else { return false }
        return combat.isChampion || combat.titleDefenses > 0 || combat.wins >= 12 || state.specialCareer.athlete.personalBrand >= 70
    }

    private func startCareer(
        _ discipline: CombatDiscipline,
        player: Player,
        specialCareer: inout SpecialCareerState,
        dossier: ChildhoodDossier?,
        result: inout DomainYearResult
    ) {
        let physical = dossier?.aptitudes.physical ?? player.health
        guard player.age >= 18, player.health >= 45, physical >= 50 else { return }
        specialCareer.track = .athlete
        specialCareer.athlete.sport = .combatSports
        var combat = CombatCareerState()
        combat.discipline = discipline
        combat.stage = .amateurProspect
        combat.skills.conditioning = max(52, physical)
        if discipline == .boxing {
            combat.skills.power = max(50, physical - 4)
            combat.skills.handSpeed = max(48, player.looks / 2 + physical / 3)
            combat.skills.footwork = max(46, player.smarts / 2 + physical / 3)
            combat.skills.defense = max(45, player.smarts / 2 + 20)
        } else {
            combat.skills.striking = max(48, physical - 8)
            combat.skills.wrestling = max(47, physical - 7)
            combat.skills.submissions = max(44, player.smarts / 2 + 18)
            combat.skills.takedownDefense = max(45, (physical + player.smarts) / 2)
        }
        combat.activeContract = CombatContract(promotionName: discipline.promotionName, fightsRemaining: 3, basePurse: discipline == .boxing ? 1_200 : 1_000)
        combat.opponentOffers = generateOffers(for: combat, age: player.age)
        combat.clamp()
        specialCareer.athlete.combat = combat
        specialCareer.athlete.personalBrand = max(18, specialCareer.athlete.personalBrand)
        specialCareer.audience = max(10, specialCareer.audience)
        result.notes.append(DomainNote(title: discipline == .boxing ? "Boxing Career Started" : "MMA Career Started", text: "Three opponent offers are waiting. The career becomes real when you sign one.", tags: [.career, .health]))
    }

    private func acceptOffer(_ tier: CombatOpponentTier, specialCareer: inout SpecialCareerState, result: inout DomainYearResult) {
        guard specialCareer.track == .athlete,
              specialCareer.athlete.sport == .combatSports,
              specialCareer.athlete.combat.suspensionYears == 0,
              let offer = specialCareer.athlete.combat.opponentOffers.first(where: { $0.tier == tier }) else {
            return
        }
        specialCareer.athlete.combat.scheduledOpponent = offer
        result.notes.append(DomainNote(title: "Fight Accepted", text: "\(offer.name) is booked. Camp and strategy now decide how ready you arrive.", tags: [.career, .risk]))
    }

    private func applyCamp(_ focus: CombatCampFocus, specialCareer: inout SpecialCareerState, result: inout DomainYearResult) {
        guard specialCareer.track == .athlete, specialCareer.athlete.sport == .combatSports else { return }
        var combat = specialCareer.athlete.combat
        guard camp(focus, belongsTo: combat.discipline) else { return }
        combat.campFocus = focus
        switch focus {
        case .boxingPower: combat.skills.power += 6; combat.careerWear += 2
        case .boxingTechnique: combat.skills.handSpeed += 3; combat.skills.footwork += 3; combat.skills.defense += 3
        case .mmaStriking: combat.skills.striking += 6; combat.careerWear += 2
        case .mmaGrappling: combat.skills.wrestling += 4; combat.skills.submissions += 4
        case .conditioning: combat.skills.conditioning += 7; combat.careerWear += 2
        case .recovery: combat.careerWear = max(0, combat.careerWear - 7); specialCareer.burnout = max(0, specialCareer.burnout - 5)
        }
        combat.clamp()
        specialCareer.athlete.combat = combat
        result.notes.append(DomainNote(title: "Camp Focus Set", text: "The camp now has a clear priority. The fight will remember it.", tags: [.career, .health]))
    }

    private func setStrategy(_ strategy: CombatFightStrategy, specialCareer: inout SpecialCareerState, result: inout DomainYearResult) {
        guard specialCareer.track == .athlete, specialCareer.athlete.sport == .combatSports else { return }
        guard isStrategy(strategy, validFor: specialCareer.athlete.combat.discipline) else { return }
        specialCareer.athlete.combat.fightStrategy = strategy
        result.notes.append(DomainNote(title: "Game Plan Set", text: "The corner knows what the first answer will be when the fight changes.", tags: [.career]))
    }

    private func crossover(player: Player, specialCareer: inout SpecialCareerState, result: inout DomainYearResult) {
        guard specialCareer.track == .athlete,
              specialCareer.athlete.sport == .combatSports,
              var discipline = specialCareer.athlete.combat.discipline,
              !specialCareer.athlete.combat.crossoverUsed else {
            return
        }
        var combat = specialCareer.athlete.combat
        discipline = discipline == .boxing ? .mma : .boxing
        combat.discipline = discipline
        combat.crossoverUsed = true
        combat.ranking = 0
        combat.isChampion = false
        combat.titleDefenses = 0
        combat.stage = .regionalProfessional
        combat.scheduledOpponent = nil
        combat.campFocus = nil
        combat.fightStrategy = nil
        if discipline == .mma {
            combat.skills.striking = max(35, combat.skills.power * 3 / 5 + combat.skills.handSpeed / 5)
            combat.skills.takedownDefense = max(30, combat.skills.footwork * 3 / 5)
            combat.skills.wrestling = max(28, combat.skills.conditioning / 2)
            combat.skills.submissions = 28
        } else {
            combat.skills.power = max(35, combat.skills.striking * 3 / 5)
            combat.skills.handSpeed = max(32, combat.skills.striking * 3 / 5)
            combat.skills.footwork = max(30, combat.skills.takedownDefense * 3 / 5)
            combat.skills.defense = max(30, (combat.skills.wrestling + combat.skills.takedownDefense) * 3 / 10)
        }
        combat.activeContract = CombatContract(promotionName: discipline.promotionName, fightsRemaining: 3, basePurse: 1_500)
        combat.opponentOffers = generateOffers(for: combat, age: player.age)
        combat.clamp()
        specialCareer.athlete.combat = combat
        result.notes.append(DomainNote(title: "Combat Crossover", text: "The name traveled. The ranking did not. You are learning a new rule set in public.", tags: [.career, .progress]))
    }

    private func retire(specialCareer: inout SpecialCareerState, result: inout DomainYearResult) {
        guard specialCareer.track == .athlete, specialCareer.athlete.sport == .combatSports else { return }
        specialCareer.athlete.combat.stage = .retired
        specialCareer.athlete.combat.scheduledOpponent = nil
        specialCareer.athlete.combat.opponentOffers = []
        specialCareer.athlete.retirementOptionsUnlocked.insert(.coaching)
        result.notes.append(DomainNote(title: "Gloves Laid Down", text: "The record is final. What happens next will decide whether the name becomes a memory or an institution.", tags: [.career, .health, .progress]))
    }

    private func startFightEmpire(
        player: Player,
        finance: FinanceState,
        specialCareer: inout SpecialCareerState,
        result: inout DomainYearResult
    ) {
        var proxy = GameState()
        proxy.player = player
        proxy.finance = finance
        proxy.specialCareer = specialCareer
        guard Self.qualifiesForFightEmpire(state: proxy) else { return }
        let origin = specialCareer.athlete.combat.discipline
        specialCareer.track = .fightEmpire
        specialCareer.diamondOriginTrack = .athlete
        specialCareer.firstDiamondEntryAge = specialCareer.firstDiamondEntryAge ?? player.age
        specialCareer.diamondTransitions += 1
        specialCareer.fightEmpire.originDiscipline = origin
        specialCareer.fightEmpire.gymReputation = max(30, specialCareer.athlete.personalBrand / 2)
        specialCareer.fightEmpire.promotionReach = max(18, specialCareer.fame / 3)
        result.financeEffects = FinanceEffects(cashDelta: -40_000)
        result.notes.append(DomainNote(title: "Fight Empire", text: "The gym and promotion opened under your name. Other fighters now carry part of your legacy.", tags: [.career, .finance, .progress]))
    }

    private func applyDevelopmentYear(
        to combat: inout CombatCareerState,
        specialCareer: inout SpecialCareerState,
        player: Player,
        result: inout DomainYearResult
    ) {
        combat.skills.conditioning += 2
        combat.careerWear = max(0, combat.careerWear - 3)
        combat.ranking = max(0, combat.ranking - (combat.ranking > 0 ? 2 : 0))
        specialCareer.audience = max(0, specialCareer.audience - 3)
        combat.opponentOffers = generateOffers(for: combat, age: player.age + 1)
        result.financeEffects = FinanceEffects(cashDelta: -1_200)
        result.notes.append(DomainNote(title: "Development Year", text: "No fight was signed. The skills improved, the gym still cost money, and the ranking softened.", tags: [.career, .finance]))
    }

    private func generateOffers(for combat: CombatCareerState, age: Int) -> [CombatOpponentOffer] {
        guard let discipline = combat.discipline else { return [] }
        let base = max(42, rating(for: combat))
        let names = discipline == .boxing
            ? ["Mateo Velez", "Andre Knox", "Darius King", "Nico Salazar", "Eli Mercer", "Roman Vale"]
            : ["Jalen Cross", "Mika Torres", "Rory Stone", "Amir Voss", "Dante Reed", "Koa Mercer"]
        let styles = discipline == .boxing
            ? ["pressure puncher", "counter boxer", "outside technician"]
            : ["striker", "wrestler", "submission hunter"]
        let tiers: [CombatOpponentTier] = [.safe, .ranked, .dangerous]
        return tiers.enumerated().map { index, tier in
            let modifier = tier == .safe ? -8 : (tier == .ranked ? 2 : 10)
            let purseMultiplier = tier == .safe ? 1 : (tier == .ranked ? 2 : 4)
            return CombatOpponentOffer(
                id: "\(discipline.rawValue)-\(age)-\(tier.rawValue)",
                name: names[(age + index + combat.wins) % names.count],
                tier: tier,
                rating: (base + modifier).clamped(to: 35...98),
                style: styles[(age + index) % styles.count],
                purse: max(750, (combat.activeContract.basePurse + combat.ranking * 70) * purseMultiplier),
                titleOpportunity: tier == .dangerous && combat.ranking >= 28
            )
        }
    }

    private func rating(for combat: CombatCareerState) -> Int {
        if combat.discipline == .boxing {
            return (combat.skills.power + combat.skills.handSpeed + combat.skills.footwork + combat.skills.defense + combat.skills.conditioning) / 5
        }
        return (combat.skills.striking + combat.skills.wrestling + combat.skills.submissions + combat.skills.takedownDefense + combat.skills.conditioning) / 5
    }

    private func matchupModifier(combat: CombatCareerState, opponent: CombatOpponentOffer) -> Int {
        guard let strategy = combat.fightStrategy else { return -8 }
        switch (strategy, opponent.style) {
        case (.boxingPressure, "outside technician"), (.boxingCounter, "pressure puncher"), (.boxingOutside, "counter boxer"):
            return 7
        case (.boxingPressure, "counter boxer"), (.boxingCounter, "outside technician"), (.boxingOutside, "pressure puncher"):
            return -5
        case (.mmaStrike, "submission hunter"), (.mmaWrestle, "striker"), (.mmaMixed, "wrestler"):
            return 6
        case (.mmaStrike, "wrestler"), (.mmaWrestle, "submission hunter"):
            return -6
        default:
            return 1
        }
    }

    private func campModifier(_ camp: CombatCampFocus?) -> Int {
        guard camp != nil else { return -7 }
        return camp == .recovery ? 2 : 5
    }

    private func camp(_ focus: CombatCampFocus, belongsTo discipline: CombatDiscipline?) -> Bool {
        switch focus {
        case .conditioning, .recovery:
            return discipline != nil
        case .boxingPower, .boxingTechnique:
            return discipline == .boxing
        case .mmaStriking, .mmaGrappling:
            return discipline == .mma
        }
    }

    private func isStrategy(_ choice: CombatFightStrategy, validFor discipline: CombatDiscipline?) -> Bool {
        switch choice {
        case .boxingPressure, .boxingCounter, .boxingOutside:
            return discipline == .boxing
        case .mmaStrike, .mmaWrestle, .mmaMixed:
            return discipline == .mma
        }
    }

    private func strategyModifier(_ strategy: CombatFightStrategy?, discipline: CombatDiscipline?) -> Int {
        guard let strategy, let discipline else { return -8 }
        if discipline == .boxing {
            return [.boxingPressure, .boxingCounter, .boxingOutside].contains(strategy) ? 4 : -10
        }
        return [.mmaStrike, .mmaWrestle, .mmaMixed].contains(strategy) ? 4 : -10
    }

    private func fightMethod(
        won: Bool,
        draw: Bool,
        margin: Int,
        combat: CombatCareerState,
        rng: inout CombatRandomSource
    ) -> String {
        if draw { return "Draw" }
        let finishThreshold = combat.discipline == .boxing ? 12 : 9
        guard abs(margin) >= finishThreshold && rng.nextInt(in: 0...100) < 58 else { return "Decision" }
        if combat.discipline == .boxing {
            return rng.nextInt(in: 0...100) < 45 ? "Knockout" : "Technical Knockout"
        }
        if won && (combat.fightStrategy == .mmaWrestle || combat.fightStrategy == .mmaMixed) {
            return rng.nextInt(in: 0...100) < 55 ? "Submission" : "TKO"
        }
        return rng.nextInt(in: 0...100) < 45 ? "Knockout" : "Technical Knockout"
    }

    private func decisiveCauses(
        won: Bool,
        matchup: Int,
        camp: CombatCampFocus?,
        strategy: CombatFightStrategy?,
        conditioning: Int,
        opponent: CombatOpponentOffer
    ) -> [String] {
        var causes: [String] = []
        causes.append(matchup >= 4 ? "The game plan matched the opponent's style." : (matchup < 0 ? "The style matchup worked against the chosen plan." : "The matchup was close enough that execution decided it."))
        causes.append(camp == nil ? "Camp had no declared focus." : "Camp emphasis carried into the fight.")
        if conditioning < 48 {
            causes.append("Conditioning faded under the late pressure.")
        } else if conditioning >= 70 {
            causes.append("Conditioning preserved technique late.")
        } else {
            causes.append(opponent.tier == .dangerous ? "Opponent quality made every mistake expensive." : (won ? "Cleaner execution separated the fight." : "The opponent won the small exchanges."))
        }
        if strategy == nil { causes[0] = "No fight strategy was committed before the bell." }
        return Array(causes.prefix(3))
    }
}
