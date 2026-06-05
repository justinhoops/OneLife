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
            // Low-overhead cross-engine signal: other engines (Silent/Continuity) can react to world movement
            state.correlationLedger.publish(CorrelationSignal(kind: .worldAutonomyPulse, domain: "world", strength: 12, age: state.player.age))
        }

        // Engine3: Recent intense instant activity biases world opportunities
        let recentHeat = state.correlationLedger.recentActivityLevel
        if recentHeat >= 50 && Int.random(in: 0...100) < 18 {
            // High recent churn → more "regret" or "second chance" style opportunities
            if let regretOpportunity = generateRegretOpportunity(state: state) {
                result.events.append(regretOpportunity)
                state.correlationLedger.publish(CorrelationSignal(kind: .worldAutonomyPulse, domain: "world", strength: 18, age: state.player.age))
            }
        }

        // 5. Resolve Past Bets (Correlation)
        if let betAge = state.consequences.narrativeFlags["speculative_bet"], betAge > 0, state.player.age > betAge {
            resolvePastSpeculation(state: &state, result: &result)
            state.correlationLedger.publish(CorrelationSignal(kind: .worldAutonomyPulse, domain: "world", strength: 8, age: state.player.age))
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

    // Engine3: Lightweight regret/echo opportunity seeded by recent intense instant activity
    private func generateRegretOpportunity(state: GameState) -> GameEvent? {
        let recentHeat = state.correlationLedger.recentActivityLevel
        if recentHeat < 45 { return nil }

        return GameEvent(
            id: "regret_echo_\(state.player.age)",
            category: .career,
            tags: ["opportunity", "regret", "echo"],
            severity: .consequential,
            title: "An Old Door Cracks Open",
            text: "Someone from your recent aggressive period reaches out. The timing feels like the universe noticed how hard you were pushing.",
            minAge: 25, maxAge: 100, weight: 10,
            cooldownYears: 6,
            requirements: [],
            choices: [
                EventChoice(text: "See what they want", effects: ChoiceEffects(), microBeat: "Maybe not everything is finished."),
                EventChoice(text: "Let it go", effects: ChoiceEffects(), microBeat: "Some chapters are better left closed.")
            ]
        )
    }

    private func generateWorldOpportunity(state: GameState) -> GameEvent? {
        let roll = Int.random(in: 0...100)
        var threshold: Int = 88

        // D4: stance-reactive autonomy bias (highest leverage for making focus feel alive to the world)
        if let stance = state.yearlyStance.lastCompletedStance {
            switch stance {
            case .stabilizeMoney:
                threshold -= 6 // more world finance chances after money focus
            case .letYearDrift:
                threshold += 4 // drift makes world feel more punishing / missed chances
            case .protectHealth:
                threshold -= 3 // health focus slightly more "second chance" style world events
            default:
                break
            }
        }
        guard roll > threshold else { return nil }

        switch state.currentEra {
        case .bullMarket, .techBoom:
            return GameEvent(
                id: "world_bull_opp",
                category: .finance,
                tags: ["money", "chance", "world_autonomy"],
                severity: .consequential,
                title: "Market Euphoria",
                text: "The markets are white-hot. Everyone is talking about a new speculative index. You have an opportunity to move a significant portion of your cash into this high-growth (but high-risk) vehicle." + (state.yearlyStance.lastCompletedStance == .stabilizeMoney ? " After all that stabilizing, the itch to swing feels sharper." : ""),
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
                text: "With the main job market cooling, a freelance gig economy is booming for those willing to work the margins. It's a grind, but it could offset your financial stress." + (state.yearlyStance.lastCompletedStance == .letYearDrift ? " The years of letting things slide make this feel like a last rope." : ""),
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
            .techBoom: 10,
            .wartime: 5,
            .pandemic: 5
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
            weights[.wartime]? += 10
        } else if current == .pandemic {
            weights[.recession]? += 40
            weights[.highInflation]? += 10
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
        case .wartime: return "Geopolitical Conflict"
        case .pandemic: return "Global Pandemic"
        }
    }
    
    private func eraDescription(for era: WorldEra) -> String {
        switch era {
        case .stable: return "The markets have settled. Job security is normal, and prices are predictable."
        case .bullMarket: return "Capital is flowing. Investments return more, and companies are hiring, but housing is creeping up."
        case .recession: return "The economy is contracting. Job security plummets, and hiring freezes. Cash is king."
        case .highInflation: return "The cost of everything is rising rapidly. Cash savings are losing value, and rent is spiking."
        case .techBoom: return "A massive innovation wave. Founder valuations skyrocket, but so does the cost of living."
        case .wartime: return "International tensions have boiled over. The military is on high alert. Industry is pivoting to defense."
        case .pandemic: return "A global health crisis has stalled movement. Healthcare is under pressure, and isolation is the new norm."
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

            // Econ1: Bull market effects on deep special careers
            if state.specialCareer.track == .founder {
                state.specialCareer.audience = min(100, state.specialCareer.audience + 8)
                state.specialCareer.founder.personalLegend = min(95, state.specialCareer.founder.personalLegend + 3)
            }
            if state.specialCareer.track == .contentCreator {
                state.specialCareer.creator.audience = min(100, state.specialCareer.creator.audience + 7)
                state.specialCareer.creator.brandDealValue = min(100, state.specialCareer.creator.brandDealValue + 6)
            }
            if state.specialCareer.track == .politics {
                state.specialCareer.politics.donorBase = min(100, state.specialCareer.politics.donorBase + 5)
                state.specialCareer.politics.approvalRating = min(100, state.specialCareer.politics.approvalRating + 3)
            }
            if state.specialCareer.track == .athlete {
                state.specialCareer.fame = min(100, state.specialCareer.fame + 6)
                state.specialCareer.athlete.personalBrand = min(100, state.specialCareer.athlete.personalBrand + 4)
            }

        case .recession:
            // Job security tanks, investments bleed
            state.career.jobSecurity = max(10, state.career.jobSecurity - 10)
            if state.finance.hasInvestments {
                state.finance.investedBalance -= Int(Double(state.finance.investedBalance) * 0.08)
            }

            // Econ1: Recession hits deep special careers hard (differentiated pain)
            if state.specialCareer.track == .founder {
                state.specialCareer.audience = max(5, state.specialCareer.audience - 12)
                state.specialCareer.founder.founderMentalLoad = min(95, state.specialCareer.founder.founderMentalLoad + 8)
                state.specialCareer.founder.teamHealth = max(10, state.specialCareer.founder.teamHealth - 6)
            }
            if state.specialCareer.track == .contentCreator {
                state.specialCareer.creator.audience = max(5, state.specialCareer.creator.audience - 10)
                state.specialCareer.creator.brandDealValue = max(0, state.specialCareer.creator.brandDealValue - 12)
                state.specialCareer.creator.burnout = min(95, state.specialCareer.creator.burnout + 7)
            }
            if state.specialCareer.track == .politics {
                state.specialCareer.politics.approvalRating = max(10, state.specialCareer.politics.approvalRating - 8)
                state.specialCareer.politics.donorBase = max(5, state.specialCareer.politics.donorBase - 10)
                state.specialCareer.politics.scandalHeat = min(100, state.specialCareer.politics.scandalHeat + 6)
            }
            if state.specialCareer.track == .athlete {
                state.specialCareer.fame = max(0, state.specialCareer.fame - 8)
                state.specialCareer.athlete.personalBrand = max(5, state.specialCareer.athlete.personalBrand - 6)
                state.specialCareer.athlete.fanLoyalty = max(10, state.specialCareer.athlete.fanLoyalty - 5)
            }

        case .highInflation:
            // Massive living cost spikes, cash devaluation
            state.finance.annualLivingCost += Int(Double(state.finance.annualLivingCost) * 0.08)
            state.finance.financialStress += 5

            // Econ1: Inflation pressure on high-burn paths
            if state.specialCareer.track == .founder {
                state.specialCareer.founder.founderMentalLoad = min(95, state.specialCareer.founder.founderMentalLoad + 5)
            }
            if state.specialCareer.track == .contentCreator {
                state.specialCareer.creator.burnout = min(95, state.specialCareer.creator.burnout + 4)
            }
            if state.specialCareer.track == .politics {
                state.specialCareer.politics.burnout = min(95, state.specialCareer.politics.burnout + 4)
            }

        case .techBoom:
            // Special career (Founder) massive boost, high living costs
            if state.specialCareer.track == .founder {
                state.specialCareer.audience += 15 // Valuation spike
                state.specialCareer.founder.personalLegend = min(95, state.specialCareer.founder.personalLegend + 5)
            }
            state.finance.annualLivingCost += Int(Double(state.finance.annualLivingCost) * 0.05)

            // Econ1: Tech boom also lifts creators and certain politicians/athletes
            if state.specialCareer.track == .contentCreator {
                state.specialCareer.creator.audience = min(100, state.specialCareer.creator.audience + 10)
                state.specialCareer.creator.brandDealValue = min(100, state.specialCareer.creator.brandDealValue + 8)
            }
            if state.specialCareer.track == .politics {
                state.specialCareer.politics.donorBase = min(100, state.specialCareer.politics.donorBase + 6)
            }
            if state.specialCareer.track == .athlete {
                state.specialCareer.fame = min(100, state.specialCareer.fame + 7)
                state.specialCareer.athlete.personalBrand = min(100, state.specialCareer.athlete.personalBrand + 5)
            }

        case .wartime:
            // Military deployments are forced or spiked
            if state.military.track != .inactive && state.military.deploymentStatus != .activeCombat {
                let deploymentRoll = Int.random(in: 0...100)
                if deploymentRoll < 40 {
                    state.military.deploymentStatus = .activeCombat
                    result.notes.append(DomainNote(title: "Drafted/Deployed", text: "Due to the global conflict, your unit has been sent directly to the front lines.", tags: [.career, .military]))
                }
            }
            state.finance.annualLivingCost += Int(Double(state.finance.annualLivingCost) * 0.04)

            // Econ1: Wartime boosts certain politicians and athletes (national pride)
            if state.specialCareer.track == .politics {
                state.specialCareer.politics.approvalRating = min(100, state.specialCareer.politics.approvalRating + 6)
                state.specialCareer.politics.charisma = min(95, state.specialCareer.politics.charisma + 3)
            }
            if state.specialCareer.track == .athlete {
                state.specialCareer.fame = min(100, state.specialCareer.fame + 5)
            }

        case .pandemic:
            // Health risks up, mental wellness down, work from home
            state.healthProfile.physicalWellness -= 5
            state.healthProfile.mentalWellness -= 8
            if state.healthProfile.physicalWellness < 40 && Int.random(in: 0...100) < 30 {
                state.healthProfile.activeConditions.append(HealthCondition(name: "Viral Infection", severity: 45))
                result.notes.append(DomainNote(title: "Pandemic Illness", text: "You caught the virus. The recovery will be long and expensive.", tags: [.health, .finance]))
            }

            // Econ1: Pandemic crushes creators and live-event politicians/athletes
            if state.specialCareer.track == .contentCreator {
                state.specialCareer.creator.audience = max(5, state.specialCareer.creator.audience - 8)
                state.specialCareer.creator.burnout = min(95, state.specialCareer.creator.burnout + 6)
            }
            if state.specialCareer.track == .politics {
                state.specialCareer.politics.approvalRating = max(10, state.specialCareer.politics.approvalRating - 5)
            }
            if state.specialCareer.track == .athlete {
                state.specialCareer.athlete.fanLoyalty = max(10, state.specialCareer.athlete.fanLoyalty - 6)
            }
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
