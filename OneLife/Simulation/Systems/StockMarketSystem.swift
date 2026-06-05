import Foundation

struct StockMarketSystem {
    let balanceProfile: SimulationBalanceProfile

    init(balanceProfile: SimulationBalanceProfile = .playableRealismV1) {
        self.balanceProfile = balanceProfile
    }

    /// Shifts the global economy state yearly.
    func advanceEconomy(_ economy: inout EconomyState, era: WorldEra) {
        // 1. Market Cycle Shift
        // Simple Markov-like transition influenced by WorldEra
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

        // 2. Update Multipliers based on cycle and era
        updateMultipliers(&economy, era: era)
    }

    private func updateMultipliers(_ economy: inout EconomyState, era: WorldEra) {
        // Base multipliers from balance profile
        var tech = 1.0
        var energy = 1.0
        var broad = 1.0
        
        let settings = balanceProfile.economy
        
        switch economy.marketCycle {
        case .boom:
            broad = settings.marketBoomMultiplier
            tech = broad + 0.05
            energy = broad - 0.07
        case .stable:
            broad = settings.marketStableMultiplier
            tech = broad + 0.01
            energy = broad - 0.02
        case .correction:
            broad = settings.marketCorrectionMultiplier
            tech = broad - 0.02
            energy = broad + 0.03
        case .recession:
            broad = settings.marketRecessionMultiplier
            tech = broad - 0.05
            energy = broad + 0.03
        }
        
        // Era overrides/boosts
        if era == .techBoom { tech += 0.15 }
        if era == .highInflation { broad -= 0.05; energy += 0.10 }
        if era == .recession { broad -= 0.05 }
        if era == .wartime { energy += 0.20; tech += 0.05; broad -= 0.10 }

        economy.techSectorMultiplier = tech
        economy.energySectorMultiplier = energy
        economy.broadMarketMultiplier = broad
        
        // Inflation
        economy.inflationRate = era == .highInflation ? 0.08 : (economy.marketCycle == .boom ? 0.04 : settings.baseInflationRate)
    }

    /// Resolves the yearly performance of the player's stock portfolio.
    func resolveYearlyPerformance(
        finance: inout FinanceState,
        economy: EconomyState,
        player: Player,
        fame: FameProfile? = nil,
        financeMomentum: Int = 0
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
        
        finance.lastYearInvestmentDelta = totalDelta
        
        if totalDelta > 10000 {
            notes.append(DomainNote(title: "Market Gains", text: "Your strategic positions paid off significantly this year.", tags: [.finance]))
        } else if totalDelta < -5000 {
            notes.append(DomainNote(title: "Market Correction", text: "A downturn in your sectors shaved value off your portfolio.", tags: [.finance]))
            finance.portfolio.lastVolatilityEventAge = player.age
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
            if roll > 80 {
                notes.append(DomainNote(title: "Alpha Found", text: "The data shows a divergence in Energy. This could be a window.", tags: [.finance, .progress]))
                state.instantMomentum.recordReaction(domain: .finance, strength: 25, currentAge: state.player.age)
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
        default: return economy.broadMarketMultiplier
        }
    }
}
