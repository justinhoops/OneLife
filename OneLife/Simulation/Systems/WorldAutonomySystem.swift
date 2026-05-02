import Foundation

struct WorldAutonomySystem {
    func advanceYear(state: inout GameState) -> DomainYearResult {
        var result = DomainYearResult()
        guard state.player.age >= 18 else { return result }

        state.eraYearsRemaining -= 1
        
        // 1. Era Shifting
        if state.eraYearsRemaining <= 0 {
            let oldEra = state.currentEra
            let newEra = shiftEra(from: oldEra)
            state.currentEra = newEra
            state.eraYearsRemaining = Int.random(in: 8...15)
            
            result.notes.append(DomainNote(
                title: "Macro Shift: \(eraName(for: newEra))",
                text: eraDescription(for: newEra),
                tags: [.finance, .career, .housing]
            ))
        }
        
        // 2. Apply Ongoing Era Effects
        applyEraEffects(era: state.currentEra, to: &state, result: &result)
        
        // 3. Corporate Actions (Career Autonomy)
        if state.career.status == .fullTime {
            applyCorporateAutonomy(era: state.currentEra, to: &state.career, finance: &state.finance, result: &result)
        }

        // 4. World Opportunities (Autonomous Popups)
        if let opportunity = generateWorldOpportunity(state: state) {
            result.events.append(opportunity)
        }

        // 5. Resolve Past Bets (Correlation)
        if let betAge = state.consequences.narrativeFlags["speculative_bet"], betAge > 0, state.player.age > betAge {
            resolvePastSpeculation(state: &state, result: &result)
        }

        // 6. Ghost Ships: Resolve Declined Opportunities (Regret System)
        resolveGhostShips(state: &state, result: &result)
        
        return result
    }

    private func resolveGhostShips(state: inout GameState, result: inout DomainYearResult) {
        // Find flags that start with "declined_"
        for (flag, ageSet) in state.consequences.narrativeFlags where flag.hasPrefix("declined_") && ageSet > 0 {
            let yearsSince = state.player.age - ageSet
            
            // Resolution window: 4-7 years later
            if yearsSince >= 4 && yearsSince <= 7 && Int.random(in: 0...100) > 80 {
                if let ghostEvent = makeGhostResolutionEvent(flag: flag, state: state) {
                    result.events.append(ghostEvent)
                    state.consequences.narrativeFlags[flag] = 0 // Clear flag
                }
            } else if yearsSince > 8 {
                // Fade away without resolution if too much time passed
                state.consequences.narrativeFlags[flag] = 0
            }
        }
    }

    private func makeGhostResolutionEvent(flag: String, state: GameState) -> GameEvent? {
        switch flag {
        case "declined_startup_bet":
            let success = Int.random(in: 0...100) > 40
            return GameEvent(
                id: "ghost_startup_resolution",
                category: .career,
                tags: ["career", "money", "ghost_ship"],
                severity: .consequential,
                title: "Ghost of a Startup",
                text: success 
                    ? "You see a headline: The local startup you almost joined years ago just went public. Your old contact is being hailed as a visionary. You can't help but calculate exactly how much your rejected equity would be worth today."
                    : "A former colleague mentions that the startup you almost joined years ago has finally shuttered its doors after burning through its runway. You dodged a bullet.",
                minAge: 18, maxAge: 100, weight: 10, cooldownYears: 99,
                requirements: [],
                choices: [
                    EventChoice(
                        text: success ? "Ouch. (Happiness -8)" : "Lucky me. (Happiness +5)",
                        effects: ChoiceEffects(core: CoreStatEffects(happiness: success ? -8 : 5)),
                        microBeat: success ? "What if..." : "Dodged it."
                    )
                ]
            )
        default:
            return nil
        }
    }

    private func resolvePastSpeculation(state: inout GameState, result: inout DomainYearResult) {
        let win = Int.random(in: 0...100) > 60 // 40% chance of a big win
        let amount = win ? 12000 : 0
        
        if win {
            state.finance.cashOnHand += amount
            result.notes.append(DomainNote(
                title: "Speculation Paid Off",
                text: "The risky index you bet on last year skyrocketed. You've cashed out with a massive $\(amount) profit.",
                tags: [.finance]
            ))
        } else {
            result.notes.append(DomainNote(
                title: "Speculation Collapsed",
                text: "The bubble burst. The index you invested in last year vanished overnight. Your $5,000 is gone.",
                tags: [.finance]
            ))
        }
        
        // Clear the flag so it doesn't trigger again
        state.consequences.narrativeFlags["speculative_bet"] = 0
    }

    private func generateWorldOpportunity(state: GameState) -> GameEvent? {
        let roll = Int.random(in: 0...100)
        guard roll > 88 else { return nil }

        switch state.currentEra {
        case .bullMarket, .techBoom:
            return GameEvent(
                id: "world_bull_opp",
                category: .finance,
                tags: ["money", "chance", "world_autonomy"],
                severity: .consequential,
                title: "Market Euphoria",
                text: "The markets are white-hot. Everyone is talking about a new speculative index. You have an opportunity to move a significant portion of your cash into this high-growth (but high-risk) vehicle.",
                minAge: 18, maxAge: 100, weight: 10, cooldownYears: 5,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Go big (Invest $5,000)",
                        effects: ChoiceEffects(
                            finance: FinanceEffects(cashDelta: -5000),
                            consequence: ConsequenceEffects(setFlags: ["speculative_bet"])
                        ),
                        microBeat: "Chips on the table.",
                        baseFriction: .warning
                    ),
                    EventChoice(
                        text: "Stay disciplined",
                        effects: ChoiceEffects(
                            consequence: ConsequenceEffects(setFlags: ["declined_startup_bet"])
                        ),
                        microBeat: "Avoiding the hype.",
                        baseFriction: .none
                    )
                ]
            )
        case .recession:
            return GameEvent(
                id: "world_recession_opp",
                category: .career,
                tags: ["career", "money", "world_autonomy"],
                severity: .consequential,
                title: "The Side Hustle Pivot",
                text: "With the main job market cooling, a freelance gig economy is booming for those willing to work the margins. It's a grind, but it could offset your financial stress.",
                minAge: 18, maxAge: 100, weight: 10, cooldownYears: 4,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Take the extra work",
                        effects: ChoiceEffects(
                            finance: FinanceEffects(cashDelta: 2000, financialStressDelta: -5),
                            health: HealthEffects(mental: -5, stressManagement: -5)
                        ),
                        microBeat: "Clocking in late.",
                        baseFriction: .none
                    ),
                    EventChoice(
                        text: "Protect your time",
                        effects: ChoiceEffects(),
                        microBeat: "Rest over cash.",
                        baseFriction: .none
                    )
                ]
            )
        case .highInflation:
             return GameEvent(
                id: "world_inflation_housing",
                category: .finance,
                tags: ["money", "housing", "world_autonomy"],
                severity: .critical,
                title: "Rent Renegotiation",
                text: "Inflation is hitting the property market. Your landlord has issued a notice that rent will increase significantly next year unless you sign a longer-term lease right now.",
                minAge: 18, maxAge: 100, weight: 10, cooldownYears: 5,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Sign the 2-year lease",
                        effects: ChoiceEffects(
                            finance: FinanceEffects(livingCostDelta: 100),
                            housing: HousingEffects(stabilityDelta: 10)
                        ),
                        microBeat: "Locked in.",
                        baseFriction: .none
                    ),
                    EventChoice(
                        text: "Refuse (Wait and see)",
                        effects: ChoiceEffects(
                            finance: FinanceEffects(livingCostDelta: 400),
                            housing: HousingEffects(stabilityDelta: -5)
                        ),
                        microBeat: "Gambling on rent.",
                        baseFriction: .warning
                    )
                ]
            )
        default:
            return nil
        }
    }
    
    private func shiftEra(from current: WorldEra) -> WorldEra {
        var weights: [WorldEra: Int] = [
            .stable: 50,
            .bullMarket: 20,
            .recession: 20,
            .highInflation: 10,
            .techBoom: 10
        ]
        
        // Prevent repeating the same era if possible
        weights[current] = 0
        
        // Adjust weights based on current state (e.g. boom followed by bust)
        if current == .bullMarket || current == .techBoom {
            weights[.recession]? += 30
            weights[.highInflation]? += 20
        } else if current == .recession {
            weights[.bullMarket]? += 30
            weights[.stable]? += 20
        }
        
        let total = weights.values.reduce(0, +)
        let roll = Int.random(in: 0..<total)
        
        var acc = 0
        for (era, weight) in weights {
            acc += weight
            if roll < acc { return era }
        }
        return .stable
    }
    
    private func eraName(for era: WorldEra) -> String {
        switch era {
        case .stable: return "Stable Economy"
        case .bullMarket: return "Bull Market"
        case .recession: return "Economic Recession"
        case .highInflation: return "High Inflation"
        case .techBoom: return "Tech Boom"
        }
    }
    
    private func eraDescription(for era: WorldEra) -> String {
        switch era {
        case .stable: return "The markets have settled. Job security is normal, and prices are predictable."
        case .bullMarket: return "Capital is flowing. Investments return more, and companies are hiring, but housing is creeping up."
        case .recession: return "The economy is contracting. Job security plummets, and hiring freezes. Cash is king."
        case .highInflation: return "The cost of everything is rising rapidly. Cash savings are losing value, and rent is spiking."
        case .techBoom: return "A massive innovation wave. Founder valuations skyrocket, but so does the cost of living."
        }
    }
    
    private func applyEraEffects(era: WorldEra, to state: inout GameState, result: inout DomainYearResult) {
        switch era {
        case .stable:
            break
        case .bullMarket:
            // Investments do better, housing costs rise slightly
            if state.finance.hasInvestments {
                state.finance.investedBalance += Int(Double(state.finance.investedBalance) * 0.05)
            }
            state.finance.annualLivingCost += Int(Double(state.finance.annualLivingCost) * 0.02)
        case .recession:
            // Job security tanks, investments bleed
            state.career.jobSecurity = max(10, state.career.jobSecurity - 10)
            if state.finance.hasInvestments {
                state.finance.investedBalance -= Int(Double(state.finance.investedBalance) * 0.08)
            }
        case .highInflation:
            // Massive living cost spikes, cash devaluation
            state.finance.annualLivingCost += Int(Double(state.finance.annualLivingCost) * 0.08)
            state.finance.financialStress += 5
        case .techBoom:
            // Special career (Founder) massive boost, high living costs
            if state.specialCareer.track == .founder {
                state.specialCareer.audience += 15 // Valuation spike
            }
            state.finance.annualLivingCost += Int(Double(state.finance.annualLivingCost) * 0.05)
        }
    }
    
    private func applyCorporateAutonomy(era: WorldEra, to career: inout CareerState, finance: inout FinanceState, result: inout DomainYearResult) {
        let actionRoll = Int.random(in: 0...100)
        
        var layoffThreshold = 95
        var bonusThreshold = 90
        
        switch era {
        case .recession:
            layoffThreshold = 80 // High chance of layoff
            bonusThreshold = 100 // Impossible
        case .bullMarket, .techBoom:
            layoffThreshold = 98 // Very rare
            bonusThreshold = 80 // More likely
        default:
            break
        }
        
        if actionRoll >= layoffThreshold {
            career.status = .unemployed
            career.jobSecurity = 10
            finance.financialStress += 20
            result.notes.append(DomainNote(title: "Corporate Restructuring", text: "The company announced sudden mass layoffs. Your role was eliminated without warning. You are unemployed.", tags: [.career, .finance]))
            result.careerEffects = CareerEffects(setStatus: .unemployed)
        } else if actionRoll >= bonusThreshold {
            let bonus = Int.random(in: 2000...8000)
            finance.cashOnHand += bonus
            result.notes.append(DomainNote(title: "Unexpected Bonus", text: "A strong quarter for the company resulted in a surprise $\(bonus) performance bonus.", tags: [.career, .finance]))
        }
    }
}
