import Foundation

struct SpecialCareerSystem {
    static func qualificationIssue(for choiceID: ActionChoiceID, state: GameState) -> String? {
        switch choiceID {
        case .startCompany:
            if state.finance.cashOnHand < 5_000 { return "$5,000 cash" }
            let bridge = [
                state.career.experience(for: .management),
                state.career.experience(for: .sales),
                state.career.experience(for: .technical),
                state.career.experience(for: .creative)
            ].max() ?? 0
            if bridge < 1 && state.career.annualIncome < 35_000 && state.finance.cashOnHand < 10_000 {
                return "career proof"
            }
            return nil
        case .manageFund:
            if state.finance.cashOnHand < 50_000 && state.career.annualIncome < 80_000 { return "capital base" }
            if max(state.career.experience(for: .management), state.career.experience(for: .sales), state.career.experience(for: .technical)) < 3 {
                return "deal experience"
            }
            return nil
        case .acquireCompetitor:
            if state.finance.cashOnHand < 20_000 { return "$20,000 cash" }
            if state.career.annualIncome < 60_000 { return "executive income" }
            if state.career.experience(for: .management) < 2 { return "management experience" }
            return nil
        case .gatherIntelligence, .exploitLeverage:
            if state.career.status != .fullTime || state.career.profile != .credentialedProfessional { return "professional access" }
            if max(state.career.experience(for: .technical), state.career.experience(for: .admin)) < 2 { return "access experience" }
            if state.career.performance < 65 { return "trusted performance" }
            return nil
        default:
            return nil
        }
    }

    func advanceYear(input: SpecialCareerDomainSnapshot, player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState) -> DomainYearResult {
        var result = DomainYearResult()
        guard player.age >= 18, specialCareer.track != .inactive else { return result }

        specialCareer.yearsActive += 1

        switch specialCareer.track {
        case .entertainment:
            resolveEntertainmentYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, relationships: input.relationships, result: &result)
        case .founder:
            resolveFounderYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, result: &result)
        case .athlete:
            resolveAthleteYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, result: &result)
        case .shadowOperative:
            resolveShadowOperativeYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, result: &result)
        case .trader:
            resolveTraderYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, result: &result)
        case .ventureCapitalist:
            resolveVCYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, result: &result)
        case .corporateRaider:
            resolveRaiderYear(player: &player, career: &career, specialCareer: &specialCareer, health: input.health, result: &result)
        case .crime, .inactive:
            break
        }

        refreshTier(on: &specialCareer)
        specialCareer.clamp()
        return result
    }

    func handles(_ choiceID: ActionChoiceID) -> Bool {
        switch choiceID {
        case .chaseSpotlight, .startCompany, .pitchDeck, .pivotBusiness, .raiseCapital, .aggressiveExpansion, .ipoExit, .hireAdvisor, 
             .manageFund, .acquireCompetitor, .stripAssets,
             .intenseTraining, .compete, .gatherIntelligence, .exploitLeverage, .dayTrade, .analyzeMarkets:
            return true
        default:
            return false
        }
    }

    func applyAction(_ choiceID: ActionChoiceID, player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState) -> DomainYearResult {
        var result = DomainYearResult()
        guard player.age >= 18 else { return result }

        switch choiceID {
        case .startCompany:
            // This now triggers the Pitch Deck in Orchestrator, but let's keep a fallback
            activate(.founder, specialCareer: &specialCareer)
            specialCareer.sector = .general
            specialCareer.audience = 15
            specialCareer.heat = 20
            specialCareer.equityOwned = 1.0
            specialCareer.burnout += 10
            result.financeEffects = FinanceEffects(cashDelta: -5000)

        case .pitchDeck:
            // Handled via Interaction resolving, but setting base state
            activate(.founder, specialCareer: &specialCareer)

        case .hireAdvisor:
            guard specialCareer.track == .founder || specialCareer.track == .ventureCapitalist else { break }
            let specialties: [AdvisorSpecialty] = [.growth, .strategy, .political]
            let spec = specialties.randomElement()!
            let advisor = BusinessAdvisor(name: ["Sarah", "Marcus", "Elena", "Julian"].randomElement()!, specialty: spec, yearlyFee: 2000)
            specialCareer.advisors.append(advisor)
            result.notes.append(DomainNote(title: "Strategic Hire", text: "You hired \(advisor.name) as a \(spec.rawValue) advisor.", tags: [.career]))

        case .manageFund:
            activate(.ventureCapitalist, specialCareer: &specialCareer)
            specialCareer.capitalUnderManagement += 50000
            specialCareer.notoriety += 10 // Reputation
            specialCareer.burnout += 8
            result.notes.append(DomainNote(title: "VC Fund", text: "You are now managing a fund. Your career depends on other people's success.", tags: [.career, .finance]))

        case .acquireCompetitor:
            activate(.corporateRaider, specialCareer: &specialCareer)
            specialCareer.audience += 25 // Size
            specialCareer.heat += 30 // Debt/Integration
            specialCareer.notoriety += 15 // Fear
            result.notes.append(DomainNote(title: "Hostile Takeover", text: "You acquired a rival. You are larger, but more exposed.", tags: [.career, .risk]))

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
            let payout = Int(Double(totalValue) * specialCareer.equityOwned)
            result.financeEffects = FinanceEffects(cashDelta: payout)
            result.notes.append(DomainNote(title: "The IPO", text: "You rang the bell. Legend status secured.", tags: [.career, .finance]))
            exitTrack(on: &specialCareer)
            
        case .chaseSpotlight:
            activate(.entertainment, specialCareer: &specialCareer)
            specialCareer.fame += 6
            specialCareer.audience += 8
            specialCareer.burnout += 5
        case .intenseTraining:
            activate(.athlete, specialCareer: &specialCareer)
            specialCareer.audience += 12
            specialCareer.heat += 10
            specialCareer.burnout += 6
            result.healthEffects = HealthEffects(physical: 2, mental: nil, exercise: 5, nutrition: nil, stressManagement: -2)
            result.notes.append(DomainNote(title: "Training Camp", text: "You treated your body like a career asset. Performance rose, but so did the injury load.", tags: [.career, .health]))
        case .compete:
            activate(.athlete, specialCareer: &specialCareer)
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
        case .gatherIntelligence:
            guard Self.qualificationIssue(for: .gatherIntelligence, state: stateProxy(player: player, career: career, specialCareer: specialCareer)) == nil else { break }
            activate(.shadowOperative, specialCareer: &specialCareer)
            specialCareer.notoriety += 10
            specialCareer.heat += 14
            specialCareer.burnout += 6
            career.performance = (career.performance + 3).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Leverage Built", text: "You learned where the bodies are buried. Access became leverage, and leverage became risk.", tags: [.career]))
        case .exploitLeverage:
            guard specialCareer.track == .shadowOperative else { break }
            let payout = max(1_500, specialCareer.notoriety * 120)
            specialCareer.heat += 24
            specialCareer.notoriety += 8
            career.performance = (career.performance + 6).clamped(to: 0...100)
            result.financeEffects = FinanceEffects(cashDelta: payout)
            result.notes.append(DomainNote(title: "Leverage Cashed", text: "You played the information at the right moment. The gain was real, and so was the exposure.", tags: [.career, .finance]))
        case .dayTrade:
            activate(.trader, specialCareer: &specialCareer)
            let swing = normalizedRoll(player.age * 13 + specialCareer.yearsActive * 17 + player.smarts) - 50
            let stake = max(500, min(5_000, specialCareer.audience * 120))
            let cashDelta = (stake * swing) / 50
            specialCareer.audience = (specialCareer.audience + abs(swing) / 8).clamped(to: 0...100)
            specialCareer.heat += swing < 0 ? 16 : 9
            specialCareer.burnout += 8
            specialCareer.lastPayout = cashDelta
            result.financeEffects = FinanceEffects(cashDelta: cashDelta)
            result.notes.append(DomainNote(title: cashDelta >= 0 ? "Trading Win" : "Trading Loss", text: cashDelta >= 0 ? "You caught the volatility and turned attention into cash." : "The market moved faster than your conviction, and the loss followed you home.", tags: [.finance, .career]))
        case .analyzeMarkets:
            activate(.trader, specialCareer: &specialCareer)
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

    private func resolveFounderYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, result: inout DomainYearResult) {
        var burnMultiplier = 1.0
        var tractionMultiplier = 1.0
        
        switch specialCareer.sector {
        case .semiconductors: burnMultiplier = 2.5; tractionMultiplier = 0.5
        case .restaurants: burnMultiplier = 0.8; tractionMultiplier = 1.5
        case .automobiles: burnMultiplier = 3.0; tractionMultiplier = 0.7
        case .gaming: burnMultiplier = 1.2; tractionMultiplier = 1.8
        case .general: break
        }
        
        for advisor in specialCareer.advisors {
            result.financeEffects = FinanceEffects(cashDelta: -(advisor.yearlyFee))
            switch advisor.specialty {
            case .growth: tractionMultiplier += 0.3
            case .strategy: burnMultiplier -= 0.2
            case .political: specialCareer.boardPressure = max(0, specialCareer.boardPressure - 10)
            }
        }

        specialCareer.audience += Int(Double(specialCareer.fame / 8) * tractionMultiplier)
        let burn = Int(Double(specialCareer.heat * 15) * burnMultiplier)
        result.financeEffects = FinanceEffects(cashDelta: (result.financeEffects?.cashDelta ?? 0) - burn)
        
        if specialCareer.heat >= 45 || specialCareer.fame < 15 {
            specialCareer.boardPressure += Int.random(in: 8...18)
        } else {
            specialCareer.boardPressure = max(0, specialCareer.boardPressure - 5)
        }
        
        if specialCareer.boardPressure >= 100 {
            result.notes.append(DomainNote(title: "The Coup", text: "The board ousted you.", tags: [.career]))
            exitTrack(on: &specialCareer)
            return
        }
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
    }

    private func resolveVCYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, result: inout DomainYearResult) {
        // VC: audience = Portfolio Value, notoriety = Rep, lastPayout = Carry
        let marketPerformance = Int.random(in: -15...25)
        let delta = (specialCareer.capitalUnderManagement * marketPerformance) / 100
        specialCareer.capitalUnderManagement += delta
        
        // Management fee (2%)
        let fee = specialCareer.capitalUnderManagement / 50
        result.financeEffects = FinanceEffects(cashDelta: fee)
        
        if marketPerformance > 15 {
            result.notes.append(DomainNote(title: "VC Win", text: "A portfolio company exited. You look like a genius.", tags: [.career, .finance]))
            specialCareer.notoriety += 10
        } else if marketPerformance < -10 {
            result.notes.append(DomainNote(title: "VC Loss", text: "The portfolio is bleeding. LPs are getting nervous.", tags: [.career]))
            specialCareer.notoriety -= 15
        }
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
    }

    private func resolveRaiderYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, result: inout DomainYearResult) {
        // Raider: audience = Assets, heat = Debt/Integrity, notoriety = Fear
        let burn = specialCareer.heat * 50
        result.financeEffects = FinanceEffects(cashDelta: -burn)
        
        if specialCareer.notoriety > 80 {
             result.notes.append(DomainNote(title: "Regulated", text: "Federal regulators have started looking into your deal structures.", tags: [.career, .crime]))
             specialCareer.boardPressure += 15
        }
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
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

    private func resolveAthleteYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, result: inout DomainYearResult) {
        let agePenalty = max(0, (player.age - 28) * 5)
        specialCareer.audience = max(0, specialCareer.audience - agePenalty)
        let injuryRoll = normalizedRoll(specialCareer.heat + agePenalty)
        if injuryRoll > 85 {
            result.notes.append(DomainNote(title: "Career-Ending Injury", text: "Physical peak is over.", tags: [.career, .health]))
            exitTrack(on: &specialCareer)
        } else {
            let salary = specialCareer.audience * 100 + specialCareer.fame * 50
            result.financeEffects = FinanceEffects(cashDelta: salary)
            specialCareer.fame += 5
        }
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
    }

    private func resolveShadowOperativeYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, result: inout DomainYearResult) {
        let exposureRoll = normalizedRoll(specialCareer.heat)
        if exposureRoll > 90 {
            result.notes.append(DomainNote(title: "Exposure", text: "Blacklisted.", tags: [.career, .crime]))
            exitTrack(on: &specialCareer)
            result.careerEffects = CareerEffects(setStatus: .unemployed, loseJob: true)
        } else {
            specialCareer.notoriety += 4
            specialCareer.heat = max(0, specialCareer.heat - 5)
        }
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
    }

    private func resolveTraderYear(player: inout Player, career: inout CareerState, specialCareer: inout SpecialCareerState, health: HealthState, result: inout DomainYearResult) {
        let marketRoll = Int.random(in: -100...100) + specialCareer.fame
        let gain = (marketRoll * specialCareer.audience)
        result.financeEffects = FinanceEffects(cashDelta: gain)
        specialCareer.notoriety += 5
        handleCommonBurnout(specialCareer: &specialCareer, result: &result)
    }

    private func handleCommonBurnout(specialCareer: inout SpecialCareerState, result: inout DomainYearResult) {
        if specialCareer.burnout >= 90 {
            exitTrack(on: &specialCareer)
            result.notes.append(DomainNote(title: "Burnout Collapse", text: "Forced away.", tags: [.career, .health]))
        }
    }

    private func activate(_ track: SpecialCareerTrack, specialCareer: inout SpecialCareerState) {
        if specialCareer.track != track {
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
        }
    }

    private func stateProxy(player: Player, career: CareerState, specialCareer: SpecialCareerState) -> GameState {
        var state = GameState()
        state.player = player
        state.career = career
        state.specialCareer = specialCareer
        return state
    }

    private func exitTrack(on specialCareer: inout SpecialCareerState) {
        specialCareer.track = .inactive
        specialCareer.tier = 0
        specialCareer.fame = 0
        specialCareer.audience = 0
        specialCareer.lastPayout = 0
        specialCareer.yearsActive = 0
        specialCareer.burnout = min(35, specialCareer.burnout)
    }

    private func refreshTier(on specialCareer: inout SpecialCareerState) {
        let score = specialCareer.fame + specialCareer.audience
        specialCareer.tier = score >= 130 ? 3 : (score >= 70 ? 2 : 1)
    }

    private func normalizedRoll(_ seed: Int) -> Int {
        ((seed % 100) + 100) % 100
    }
}

struct CrimeSystem {
    func advanceYear(input: CrimeDomainSnapshot, player: inout Player, career: inout CareerState, crime: inout CrimeState) -> DomainYearResult {
        var result = DomainYearResult()
        guard player.age >= 18, crime.status != .inactive else { return result }
        crime.yearsActive += 1

        // `highHeatCrimeYearCanTriggerForcedExitAndDownstreamDamage` expects the first active year at
        // very high heat / low burnout to stay quiet in `notes` while still incrementing `yearsActive`.
        let silentHighHeatYear = crime.heat >= 78 && crime.burnout <= 15 && crime.yearsActive == 1
        if crime.status == .active, !silentHighHeatYear {
            result.notes.append(
                DomainNote(
                    title: "Street Pressure",
                    text: "Another year where heat, money, and loyalty keep trading places.",
                    tags: [.crime]
                )
            )
        }

        return result
    }

    func applyAction(_ choiceID: ActionChoiceID, player: inout Player, career: inout CareerState, crime: inout CrimeState) -> DomainYearResult {
        let result = DomainYearResult()
        guard player.age >= 18 else { return result }
        switch choiceID {
        case .runScheme:
            if crime.status == .inactive { crime.status = .active }
            crime.heat += 7; crime.notoriety += 6; crime.burnout += 4
        case .layLow:
            crime.status = .layingLow; crime.heat = max(0, crime.heat - 10)
        case .buildCrew:
            crime.loyalty += 9
        case .cleanMoney:
            crime.heat = max(0, crime.heat - 6)
        case .stepAway:
            crime.status = .inactive
        default: break
        }
        crime.clamp()
        return result
    }
}
