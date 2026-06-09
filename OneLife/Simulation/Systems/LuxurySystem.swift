import Foundation

struct LuxurySystem {
    let balanceProfile: SimulationBalanceProfile

    init(balanceProfile: SimulationBalanceProfile = .playableRealismV1) {
        self.balanceProfile = balanceProfile
    }

    /// Yearly resolution for the luxury lifestyle.
    func advanceYear(state: GameState) -> DomainYearResult {
        var result = DomainYearResult()
        
        let isElite = state.assets.lifestyleScore >= 75 || state.finance.totalWealth >= 50_000_000
        guard isElite else { return result }
        
        // 1. Financial Maintenance
        // Base cost + percentage of net worth to maintain the image
        let baseCost = 75_000
        let wealthTax = Double(state.finance.totalWealth) * 0.002 // 0.2% wealth tax for high society
        let totalCost = Int(Double(baseCost) + wealthTax)
        
        var financeEffects = FinanceEffects(cashDelta: -totalCost)
        result.notes.append(DomainNote(title: "Elite Upkeep", text: "Maintaining your standing in the world's highest circles cost $\(totalCost) this year. The gloss has a price.", tags: [.finance, .assets]))
        
        // 2. Asset Decay / Maintenance Checks
        if state.assets.lifestyleScore > 85 && Int.random(in: 0...100) < 15 {
            let repairCost = Int.random(in: 25_000...100_000)
            financeEffects.cashDelta = (financeEffects.cashDelta ?? 0) - repairCost
            result.notes.append(DomainNote(title: "Asset Restoration", text: "A specialized restoration was required for one of your signature pieces. It cost $\(repairCost) to preserve the value.", tags: [.assets, .finance]))
        }
        result.financeEffects = financeEffects
        
        // 3. Family & Legacy Spillover (E3)
        // High luxury parents create specific pressures on children
        if !state.family.children.isEmpty {
            let affectedChildren = state.family.children.filter { $0.age > 12 && $0.age < 22 }
            if !affectedChildren.isEmpty {
                result.familyEffects = FamilyEffects(
                    childBondDeltaByID: Dictionary(uniqueKeysWithValues: affectedChildren.map { ($0.id, -3) })
                )
            }
            if let child = affectedChildren.randomElement(), Int.random(in: 0...100) < 20 {
                result.notes.append(DomainNote(title: "Golden Cage", text: "\(child.name) is struggling with the expectations of being your child. The luxury feels like a shadow to them.", tags: [.family, .relationships]))
            }
        }
        
        // 4. Fame/Notoriety Decay or Reinforcement
        // Without active maintenance (via actions), prestige dips slightly
        if state.fame.culturalFame > 50 {
            result.fameEffects = FameEffects(culturalFame: -1)
        }
        
        return result
    }

    /// Primary entry point for applying luxury-specific actions.
    func applyAction(_ choiceID: ActionChoiceID, state: GameState) -> DomainYearResult {
        var result = DomainYearResult()
        let resilience = state.resilience
        
        switch choiceID {
        case .hostLuxuryEvent:
            let cost = 250_000 + Int.random(in: 0...500_000)
            result.financeEffects = FinanceEffects(cashDelta: -cost)
            result.fameEffects = FameEffects(culturalFame: 8, notoriety: 2)
            result.familyEffects = FamilyEffects(allChildrenBondDelta: -2)
            
            result.notes.append(DomainNote(title: "Grand Gala", text: "You hosted a night the world will talk about. It cost $\(cost), but your name now carries a new weight in the highest circles.", tags: [.social, .finance, .fame]))

        case .acquireLuxuryAsset:
            let cost = 1_500_000 + Int.random(in: 0...5_000_000)
            result.financeEffects = FinanceEffects(cashDelta: -cost)
            result.fameEffects = FameEffects(culturalFame: 5)
            
            result.notes.append(DomainNote(title: "Statement Piece", text: "You acquired a rare artifact of extreme success for $\(cost). It's not just an object; it's a pillar of your legacy.", tags: [.assets, .finance]))

        case .indulgeInExcess:
            let cost = 50_000
            result.financeEffects = FinanceEffects(cashDelta: -cost)
            result.coreEffects = CoreStatEffects(happiness: 12)
            
            // Health cost: luxury is rarely healthy
            let healthPenalty = resilience == .grounded ? -6 : -4
            result.healthEffects = HealthEffects(physical: healthPenalty, mental: 8)
            
            result.notes.append(DomainNote(title: "Peak Sensation", text: "You spent $\(cost) for a week of pure perfection. Your body feels the cost, but for a moment, the world felt like it belonged to you.", tags: [.health, .finance]))

        case .displayWealth:
            let heatGain = Int.random(in: 5...12)
            result.fameEffects = FameEffects(culturalFame: 4, notoriety: 3)
            result.crimeEffects = CrimeEffects(heat: heatGain)
            
            result.notes.append(DomainNote(title: "Signaling", text: "You made sure the world saw the gloss. The spotlight feels warmer, but it also brings more scrutiny.", tags: [.social, .fame, .risk]))

        case .maintainLuxuryCollection:
            let cost = max(15_000, state.finance.totalWealth / 500)
            result.financeEffects = FinanceEffects(cashDelta: -cost)
            
            result.notes.append(DomainNote(title: "Elite Maintenance", text: "You approved the invoices for hangar fees and detailing. The collection remains pristine.", tags: [.assets, .finance]))

        default:
            break
        }
        
        return result
    }

    /// Autonomous reactions specific to luxury play.
    func reactToLuxuryAction(_ choiceID: ActionChoiceID, state: inout GameState) -> [DomainNote] {
        var notes: [DomainNote] = []
        let roll = Int.random(in: 0...100)
        
        switch choiceID {
        case .hostLuxuryEvent:
            if roll < 35 {
                notes.append(DomainNote(title: "Elite Circle", text: "A billionaire tech mogul pulled you aside. The doors to a higher tier are swinging open.", tags: [.social, .career]))
                state.instantMomentum.recordReaction(domain: .relationships, strength: 18, currentAge: state.player.age)
            } else if roll < 60 {
                notes.append(DomainNote(title: "Paparazzi Surge", text: "Photos of your gala are all over the feeds. Your visibility is peaking.", tags: [.fame]))
                state.fame.culturalFame = min(100, state.fame.culturalFame + 3)
            } else if roll > 92 && state.relationships.hasPartner {
                notes.append(DomainNote(title: "Partner Neglect", text: "Your spouse watched you work the room all night. The luxury felt like a barrier.", tags: [.relationships, .risk]))
                if var partner = state.relationships.romanticPartner {
                    partner.bond = max(5, partner.bond - 5)
                    state.relationships.romanticPartner = partner
                }
            }

        case .displayWealth:
            if state.fame.culturalFame > 60 && roll < 30 {
                notes.append(DomainNote(title: "Public Scrutiny", text: "The local press is digging into your tax filings. The gloss is inviting questions.", tags: [.fame, .risk, .crime]))
                state.fame.notoriety = min(100, state.fame.notoriety + 6)
                state.crime.heat = min(100, state.crime.heat + 8)
            } else if roll > 80 {
                notes.append(DomainNote(title: "Envy Factor", text: "Old friends are distancing themselves. You're becoming a headline, not a person.", tags: [.relationships]))
                state.relationships.privateReputation = max(0, state.relationships.privateReputation - 4)
            }

        case .acquireLuxuryAsset:
            if roll < 25 {
                notes.append(DomainNote(title: "Collector's Respect", text: "The acquisition was noticed by the right galleries. Your taste is now a benchmark.", tags: [.assets, .fame]))
                state.fame.culturalFame = min(100, state.fame.culturalFame + 2)
            }

        case .indulgeInExcess:
            if state.resilience == .grounded && roll < 40 {
                notes.append(DomainNote(title: "Heavy Morning", text: "Grounded reality: the excess cost more than the bill. Your body is demanding a reset.", tags: [.health]))
                state.healthProfile.physicalWellness = max(5, state.healthProfile.physicalWellness - 4)
            } else if roll > 85 {
                notes.append(DomainNote(title: "Momentary Peace", text: "For one night, the pressure felt like a choice, not a cage. You feel centered.", tags: [.health, .progress]))
                state.healthProfile.mentalWellness = min(100, state.healthProfile.mentalWellness + 5)
            }

        default:
            break
        }
        
        return notes
    }
}
