import Foundation

struct StockMarketSystem {
    let balanceProfile: SimulationBalanceProfile

    init(balanceProfile: SimulationBalanceProfile = .playableRealismV1) {
        self.balanceProfile = balanceProfile
    }

    /// Shifts the global economy state yearly.
    func advanceEconomy(_ economy: inout EconomyState, era: WorldEra) {
        // 1. Market Cycle Shift
        let roll = Int.random(in: 0...100)
        switch era {
        case .bullMarket, .techBoom:
            if roll < 70 { economy.marketCycle = .boom }
            else if roll < 90 { economy.marketCycle = .stable }
            else { economy.marketCycle = .correction }
            
        case .recession:
            if roll < 60 { economy.marketCycle = .recession }
            else if roll < 90 { economy.marketCycle = .correction }
            else { economy.marketCycle = .stable }
            
        case .highInflation:
            if roll < 40 { economy.marketCycle = .correction }
            else if roll < 80 { economy.marketCycle = .stable }
            else { economy.marketCycle = .recession }
            
        default:
            if roll < 60 { economy.marketCycle = .stable }
            else if roll < 80 { economy.marketCycle = .boom }
            else if roll < 95 { economy.marketCycle = .correction }
            else { economy.marketCycle = .recession }
        }

        // 2. Generate Forecast for next year
        generateForecast(&economy, era: era)

        // 3. Update Multipliers based on cycle and era
        updateMultipliers(&economy, era: era)
    }

    private func generateForecast(_ economy: inout EconomyState, era: WorldEra) {
        // Simple logic to "peek" at likely future
        let roll = Int.random(in: 0...100)
        var msg = "Markets look steady for the coming year."

        if economy.marketCycle == .boom && roll < 40 {
            msg = "Analysts warn of overextension in Tech; a correction may be looming."
        } else if economy.marketCycle == .recession && roll < 50 {
            msg = "Indicators suggest the bottom is near. Recovery is expected soon."
        } else if era == .techBoom {
            msg = "The silicon gold rush shows no signs of stopping. Tech is king."
        } else if era == .highInflation {
            msg = "Bonds and cash are losing value daily. Tangible assets are the play."
        }

        economy.forecast = msg
    }

    private func updateMultipliers(_ economy: inout EconomyState, era: WorldEra) {
        // Base multipliers from balance profile
        var tech = 1.0
        var energy = 1.0
        var broad = 1.0
        var spec = 1.0
        var bond = 1.0
        
        let settings = balanceProfile.economy
        
        switch economy.marketCycle {
        case .boom:
            broad = settings.marketBoomMultiplier
            tech = broad + 0.05
            energy = broad - 0.07
            spec = broad + 0.15
            bond = 0.98
        case .stable:
            broad = settings.marketStableMultiplier
            tech = broad + 0.01
            energy = broad - 0.02
            spec = broad + 0.05
            bond = 1.02
        case .correction:
            broad = settings.marketCorrectionMultiplier
            tech = broad - 0.02
            energy = broad + 0.03
            spec = broad - 0.10
            bond = 1.04
        case .recession:
            broad = settings.marketRecessionMultiplier
            tech = broad - 0.05
            energy = broad + 0.03
            spec = broad - 0.25
            bond = 1.06
        }
        
        // Era overrides/boosts
        if era == .techBoom { tech += 0.15; spec += 0.10 }
        if era == .highInflation { broad -= 0.05; energy += 0.10; bond -= 0.08 }
        if era == .recession { broad -= 0.05; spec -= 0.15 }
        if era == .wartime { energy += 0.20; tech += 0.05; broad -= 0.10; spec -= 0.10 }

        economy.techSectorMultiplier = tech
        economy.energySectorMultiplier = energy
        economy.broadMarketMultiplier = broad
        economy.speculativeMultiplier = spec
        economy.bondMultiplier = bond
        
        // Inflation
        economy.inflationRate = era == .highInflation ? 0.08 : (economy.marketCycle == .boom ? 0.04 : settings.baseInflationRate)
    }

    /// Resolves the yearly performance of the player's stock portfolio.
    func resolveYearlyPerformance(
        finance: inout FinanceState,
        economy: EconomyState,
        player: Player,
        fame: FameProfile? = nil,
        financeMomentum: Int = 0,
        family: FamilyState? = nil,
        resilience: LifeResilience = .resilient
    ) -> [DomainNote] {
        var notes: [DomainNote] = []
        var totalDelta = 0
        
        let momentumMod = Double(financeMomentum) / 500.0 // up to 0.2 multiplier on gains or -0.2 on losses
        
        for i in finance.portfolio.stocks.indices {
            let holding = finance.portfolio.stocks[i]
            let sectorMult = multiplier(for: holding.tickerOrSector, in: economy)

            // Volatility roll
            let baseVol = 0.05 * holding.volatilityFactor
            var randomFluctuation = Double.random(in: -baseVol...baseVol)
            
            // Resilience divergence (E3)
            if resilience == .resilient {
                if randomFluctuation < 0 { randomFluctuation *= 0.8 } // Reduce downside variance
            } else if resilience == .grounded {
                randomFluctuation *= 1.2 // Amplify variance (wins and losses land harder)
            }

            // Momentum effect: reduce downside if player has been active
            if randomFluctuation < 0 {
                randomFluctuation *= (1.0 - (Double(financeMomentum) / 200.0)) // reduce downside by up to 50%
            }
            
            // Final return for this holding
            var totalReturn = (sectorMult - 1.0) + randomFluctuation
            
            // Fame/CEO/Athlete modifiers (E1: Basic tie-in)
            var modifier = 0.0
            if let fame = fame, fame.culturalFame > 70 {
                modifier += 0.02 // Small edge for high fame
            }
            
            // Momentum boost on total return
            if totalReturn > 0 {
                totalReturn *= (1.0 + momentumMod)
            }
            
            let finalValue = holding.sharesOrValue * (1.0 + totalReturn + modifier)
            let delta = Int(finalValue - holding.sharesOrValue)
            
            finance.portfolio.stocks[i].sharesOrValue = finalValue
            totalDelta += delta
        }

        finance.lastYearInvestmentDelta += totalDelta

        // 4. Narrative Pass (Echoes & Silence)
        notes.append(contentsOf: narrativePass(totalDelta: totalDelta, economy: economy, finance: finance, player: player))

        // 5. Family Spillover (E3)
        if let family = family {
            notes.append(contentsOf: generateFamilySpillover(totalDelta: totalDelta, family: family, finance: finance))
        }

        if totalDelta < -5000 {
            finance.portfolio.lastVolatilityEventAge = player.age
        }

        return notes
    }

    private func generateFamilySpillover(totalDelta: Int, family: FamilyState, finance: FinanceState) -> [DomainNote] {
        var notes: [DomainNote] = []

        if totalDelta > 50000 && !family.children.isEmpty {
            notes.append(DomainNote(title: "Family Fortune", text: "The kids noticed the change in mood—and the new gear. They're starting to ask about 'the big investment.'", tags: [.family, .finance]))
        } else if totalDelta < -30000 && family.childCount > 0 {
            notes.append(DomainNote(title: "Household Tension", text: "The market bloodbath wasn't just a number. It's a conversation at the dinner table that nobody wants to have.", tags: [.family, .finance, .relationships]))
        }
        
        return notes
    }

    private func narrativePass(totalDelta: Int, economy: EconomyState, finance: FinanceState, player: Player) -> [DomainNote] {
        var notes: [DomainNote] = []
        
        if totalDelta > 25000 {
            notes.append(DomainNote(title: "Windfall", text: "Your portfolio is screaming. The numbers on the screen feel like a different reality.", tags: [.finance, .progress]))
        } else if totalDelta < -15000 {
            notes.append(DomainNote(title: "Market Bloodbath", text: "You watched the red bars erase years of work in a single afternoon.", tags: [.finance, .risk]))
        } else if abs(totalDelta) < 1000 && finance.portfolio.totalValue > 50000 {
            notes.append(DomainNote(title: "Market Silence", text: "The markets were flat. Your capital just... existed. A quiet year for the money.", tags: [.finance]))
        }

        // Echoes (Vibe layer integration)
        if let lastEventAge = finance.portfolio.lastVolatilityEventAge, player.age - lastEventAge == 1 {
            if totalDelta > 0 {
                notes.append(DomainNote(title: "Recovery Echo", text: "The scars from last year's dip are finally fading as the green returns.", tags: [.finance]))
            } else {
                notes.append(DomainNote(title: "Lingering Pain", text: "Another tough year. The correction is starting to feel like a permanent shift.", tags: [.finance]))
            }
        }
        
        return notes
    }

    /// Synchronous reaction for stock market instant actions.
    func reactToStockAction(
        _ choiceID: ActionChoiceID,
        state: inout GameState
    ) -> [DomainNote] {
        var notes: [DomainNote] = []

        // Update exposure first to ensure reaction logic has fresh data
        updateExposure(finance: &state.finance)

        switch choiceID {
        case .checkPortfolio:
            break

        case .rebalancePortfolio:
            // Add momentum boost in finance
            state.instantMomentum.recordReaction(domain: .finance, strength: 15, currentAge: state.player.age)
            if state.finance.portfolio.totalMarketExposure > 0.7 {
                notes.append(DomainNote(title: "De-risking", text: "You trimmed the fat. It feels lighter, safer.", tags: [.finance]))
            }

        case .researchTip:
            let analyticsSkill = state.education.credentials.contains("STEM") || state.education.credentials.contains("Degree") ? 20 : 0
            let roll = Int.random(in: 0...100) + analyticsSkill
            if roll > 70 {
                notes.append(DomainNote(title: "Market Edge", text: "You found a lead: The data is noisy, but a shift is coming.", tags: [.finance, .progress]))
                state.instantMomentum.recordReaction(domain: .finance, strength: 25, currentAge: state.player.age)
            } else {
                notes.append(DomainNote(title: "Analysis Parity", text: "Your research matches the consensus. No clear edge found today.", tags: [.finance]))
            }

        case .buyIndex, .buyStocks:
            if state.economy.marketCycle == .boom {
                notes.append(DomainNote(title: "Market Pulse", text: "The cycle is with you. Every dollar feels like it's working double time.", tags: [.finance]))
            }

        default:
            break
        }

        // Volatility events (E2)
        if state.finance.portfolio.totalMarketExposure > 0.4 {
            let volRoll = Int.random(in: 0...100)
            if volRoll < 8 { // 8% chance of a "pulse" event during an instant action
                let baseRange = state.finance.portfolio.totalValue / 100 // 1% of portfolio
                let delta = Int.random(in: -baseRange...baseRange)
                if delta < -500 {
                    notes.append(DomainNote(title: "Market Dip", text: "A sudden dip shaved $\(abs(delta)) off your portfolio value.", tags: [.finance, .risk]))
                } else if delta > 500 {
                    notes.append(DomainNote(title: "Market Spike", text: "A brief rally added $\(delta) to your positions.", tags: [.finance]))
                }
                
                if abs(delta) > 10, let index = state.finance.portfolio.stocks.indices.randomElement() {
                    state.finance.portfolio.stocks[index].sharesOrValue += Double(delta)
                }
            }
        }

        return notes
    }

    /// Updates the total market exposure based on net worth.
    func updateExposure(finance: inout FinanceState) {
        let totalWealth = finance.totalWealth
        guard totalWealth > 0 else {
            finance.portfolio.totalMarketExposure = 0
            return
        }
        
        let investmentValue = finance.portfolio.totalValue
        finance.portfolio.totalMarketExposure = Double(investmentValue) / Double(totalWealth)
    }

    private func multiplier(for sector: String, in economy: EconomyState) -> Double {
        switch sector.uppercased() {
        case "TECH": return economy.techSectorMultiplier
        case "ENERGY": return economy.energySectorMultiplier
        case "SPECULATIVE": return economy.speculativeMultiplier
        case "BOND": return economy.bondMultiplier
        default: return economy.broadMarketMultiplier
        }
    }
}
