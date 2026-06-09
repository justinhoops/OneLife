import Foundation

struct NPCAutonomySystem {
    func advanceYear(state: inout GameState) -> [GameEvent] {
        var generatedEvents: [GameEvent] = []
        
        // 1. Process Romantic Partners
        for i in 0..<state.relationships.romanticPartners.count {
            var partner = state.relationships.romanticPartners[i]
            if shouldProcessAutonomy(for: partner, currentAge: state.player.age) {
                let events = processAutonomy(for: &partner, type: .romantic, player: state.player, state: state)
                generatedEvents.append(contentsOf: events)
                if !events.isEmpty {
                    state.consequences.narrativeFlags["npc_autonomy_pulse", default: 0] = 1
                }
            }
            state.relationships.romanticPartners[i] = partner
        }
        
        // 2. Process Friends (Only those scheduled for this year)
        for i in 0..<state.relationships.friends.count {
            if shouldProcessAutonomy(for: state.relationships.friends[i], currentAge: state.player.age) {
                let events = processAutonomy(for: &state.relationships.friends[i], type: .friend, player: state.player, state: state)
                generatedEvents.append(contentsOf: events)
                if !events.isEmpty {
                    state.consequences.narrativeFlags["npc_autonomy_pulse", default: 0] = 1
                }
            }
        }

        // 3. System Interventions (Cross-Domain)
        if let intervention = checkForInterventions(state: state) {
            generatedEvents.append(intervention)
            state.correlationLedger.publish(CorrelationSignal(kind: .npcAutonomyPulse, domain: "relationships", strength: 14, age: state.player.age))
        }
        
        // 4. NPC Mortality (P5 Final Shine - Late Life Realism)
        if state.player.age >= 65 {
            let mortalityEvents = processMortality(state: &state)
            generatedEvents.append(contentsOf: mortalityEvents)
        }

        // D4: stance-reactive NPC autonomy (if last focus was protectHealth, softer interventions; drift -> more resentment spikes)
        if let stance = state.yearlyStance.lastCompletedStance {
            if stance == .protectHealth {
                // bias toward supportive rather than confrontational
                for i in 0..<state.relationships.romanticPartners.count {
                    var p = state.relationships.romanticPartners[i]
                    if p.hiddenResentment > 20 { p.hiddenResentment = max(0, p.hiddenResentment - 3) }
                    state.relationships.romanticPartners[i] = p
                }
            } else if stance == .letYearDrift {
                for i in 0..<state.relationships.friends.count {
                    if Int.random(in: 0...100) < 30 {
                        state.relationships.friends[i].hiddenResentment = min(100, state.relationships.friends[i].hiddenResentment + 4)
                    }
                }
            }
        }

        // Engine3: Make NPCs reactive to recent intense instant activity (low-overhead)
        let recentHeat = state.correlationLedger.recentActivityLevel
        if recentHeat >= 55 {
            // High recent instant/autonomous churn → seed relationship tension or interventions
            state.correlationLedger.publish(CorrelationSignal(kind: .npcAutonomyPulse, domain: "relationships", strength: 8, age: state.player.age))
            for i in 0..<state.relationships.romanticPartners.count {
                var partner = state.relationships.romanticPartners[i]
                if partner.bond < 60 && partner.status == .active {
                    partner.hiddenResentment = min(100, partner.hiddenResentment + (recentHeat / 8))
                    state.relationships.romanticPartners[i] = partner
                }
            }
            // Occasionally force an earlier autonomy check for friends
            for i in 0..<state.relationships.friends.count {
                if Int.random(in: 0...100) < 25 {
                    state.relationships.friends[i].nextAutonomyYear = min(
                        state.relationships.friends[i].nextAutonomyYear ?? state.player.age + 1,
                        state.player.age + 1
                    )
                }
            }
        }
        
        return generatedEvents
    }

    private func checkForInterventions(state: GameState) -> GameEvent? {
        let recentHeat = state.correlationLedger.recentActivityLevel

        // Engine3: Recent intense instant activity makes relationship interventions more likely
        let heatBonus = recentHeat / 10   // 0-10 extra chance/severity

        // D4: stance-reactive bias on intervention weight and flavor
        var weightBonus = heatBonus
        var stanceFlavor = ""
        if let stance = state.yearlyStance.lastCompletedStance {
            if stance == .protectHealth { weightBonus -= 6 } // care focus makes partners gentler
            if stance == .pushCareer { weightBonus += 5 }
            if stance == .letYearDrift { weightBonus += 8; stanceFlavor = " The years of coasting made this conversation inevitable." }
        }

        // Career Burnout Intervention (High Career + Low Health + Low Partner Bond)
        if state.career.performance >= 80 && state.healthProfile.mentalWellness <= 35 && state.relationships.partnerBond <= 45 && state.relationships.hasPartner {
            return GameEvent(
                id: "intervention_burnout",
                category: .health,
                tags: ["health", "relationships", "career", "intervention"],
                severity: .critical,
                title: "Breaking Point",
                text: (recentHeat >= 50 
                    ? "Your partner sits you down. 'You’ve been moving non-stop and I barely see you anymore. This pace is eating you alive.'"
                    : "Your partner sits you down. 'I barely see you, and when I do, you're a ghost,' they say. 'This job is eating you alive. Something has to change, or I can't stay.'") + stanceFlavor,
                minAge: 22, maxAge: 100, weight: 20 + weightBonus, cooldownYears: 10,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Commit to a 40-hour week",
                        effects: ChoiceEffects(
                            career: CareerEffects(performance: -15, schedulePressure: -20),
                            relationship: RelationshipEffects(partnerChange: 20),
                            health: HealthEffects(mental: 10)
                        ),
                        microBeat: "Prioritizing life."
                    ),
                    EventChoice(
                        text: "Dismiss their concerns",
                        effects: ChoiceEffects(
                            relationship: RelationshipEffects(partnerChange: -30),
                            health: HealthEffects(mental: -10)
                        ),
                        microBeat: "The grind continues."
                    )
                ]
            )
        }

        // New Engine3 intervention: "You're becoming someone I don't recognize" when heavy recent flexing + relationship
        if recentHeat >= 60 && state.assets.lifestyleScore >= 65 && state.relationships.partnerBond < 55 && state.relationships.hasPartner {
            return GameEvent(
                id: "intervention_lifestyle_drift",
                category: .relationships,
                tags: ["relationships", "lifestyle", "intervention"],
                severity: .critical,
                title: "The Person You're Becoming",
                text: "Your partner says quietly, 'Every time you show off the new thing or post about the win, I feel like I'm watching someone I used to know. Is this who we are now?'",
                minAge: 25, maxAge: 100, weight: 15 + heatBonus,
                cooldownYears: 8,
                requirements: [],
                choices: [
                    EventChoice(
                        text: "Slow down the flexing",
                        effects: ChoiceEffects(
                            relationship: RelationshipEffects(partnerChange: 18)
                            // lifestyleScoreDelta effect removed — AssetEffects no longer supports direct delta here
                        ),
                        microBeat: "Choosing the relationship over the performance."
                    ),
                    EventChoice(
                        text: "They just don't get it",
                        effects: ChoiceEffects(
                            relationship: RelationshipEffects(partnerChange: -25)
                        ),
                        microBeat: "The gap widens."
                    )
                ]
            )
        }

        return nil
    }
    
    private func shouldProcessAutonomy(for npc: Relationship, currentAge: Int) -> Bool {
        guard let nextYear = npc.nextAutonomyYear else { return true }
        return currentAge >= nextYear
    }

    private func processAutonomy(for npc: inout Relationship, type: RelationshipType, player: Player, state: GameState) -> [GameEvent] {
        var events: [GameEvent] = []
        
        // Age hidden states
        let yearsPassed = state.player.age - (npc.nextAutonomyYear.map { $0 - 3 } ?? state.player.age) // Approximation since last check
        let yearsToSimulate = max(1, yearsPassed)
        
        npc.hiddenNeedLevel += Int.random(in: 2...8) * yearsToSimulate
        if npc.bond < 40 { npc.hiddenResentment += Int.random(in: 1...5) * yearsToSimulate }
        applyCorrelationImpressions(to: &npc, state: state)
        
        // Assign Goal if none exists
        if npc.currentGoal == nil {
            npc.currentGoal = assignGoal(for: npc)
        }
        
        // Schedule next check (1 to 4 years based on personality/tension)
        npc.nextAutonomyYear = state.player.age + Int.random(in: 1...4)
        
        // Check Correlation: Did we help them before?
        let helpedKey = "helped_\(npc.id)"
        let hasHelped = state.consequences.narrativeFlags[helpedKey, default: 0] > 0
        
        if hasHelped && type == .friend {
            events.append(makeGratitudeEvent(for: npc))
            npc.nextAutonomyYear = state.player.age + 5 // Back off after gratitude
            return events // Gratitude replaces other actions this year
        }

        // The Grapevine: Does this NPC know about our 'heat'?
        let grapevineHeat = state.relationships.activeRumorHeat
        if grapevineHeat >= 50 && Int.random(in: 0...100) > 60 {
            events.append(makeGrapevineConfrontation(for: npc))
            npc.nextAutonomyYear = state.player.age + 2 // Immediate follow-up
            return events
        }

        // Goal-oriented action
        switch npc.currentGoal {
        case "borrow_money":
            if npc.hiddenNeedLevel >= 50 {
                events.append(makeFinancialAsk(for: npc))
                npc.hiddenNeedLevel = 0
                npc.currentGoal = assignGoal(for: npc)
            }
        case "start_drama":
            if npc.hiddenResentment >= 40 {
                events.append(makeConflictEvent(for: npc))
                npc.hiddenResentment /= 2
                npc.currentGoal = assignGoal(for: npc)
            }
        case "pitch_opportunity":
            events.append(makeOpportunityAsk(for: npc))
            npc.currentGoal = assignGoal(for: npc)
        case "betray":
            if npc.hiddenResentment >= 30 {
                events.append(makeBetrayalEvent(for: npc))
                npc.currentGoal = assignGoal(for: npc)
            }
        case "reconnect":
            if type == .friend {
                events.append(makeSocialInvite(for: npc))
                npc.currentGoal = assignGoal(for: npc)
            }
        case "move_in":
            if type == .romantic && state.player.age >= 20 && state.relationships.partnerBond >= 75 && !state.relationships.hasCohabitingPartner {
                events.append(makeMoveInAsk(for: npc))
                npc.currentGoal = assignGoal(for: npc)
            }
        default:
            npc.currentGoal = assignGoal(for: npc)
        }
        
        return events
    }

    private func applyCorrelationImpressions(to npc: inout Relationship, state: GameState) {
        // Temporarily disabled: old .npcImpressions API was on legacy CorrelationLedger.
        // SystemCorrelationLedger (Engine1+) uses a much smaller signal set. Feature can be re-mapped later.
        _ = state.correlationLedger.recentActivityLevel   // touch to avoid unused warning
    }
    
    private func assignGoal(for npc: Relationship) -> String {
        switch npc.personality {
        case .needy: return "borrow_money"
        case .unstable: return "start_drama"
        case .ambitious: return "pitch_opportunity"
        case .selfish: return npc.bond < 40 ? "betray" : "borrow_money"
        case .generous: return "reconnect"
        case .loyal: return "reconnect"
        }
    }
    
    private func makeGratitudeEvent(for npc: Relationship) -> GameEvent {
        return GameEvent(
            id: "npc_gratitude_\(npc.id)",
            category: .social,
            tags: ["social", "money", "npc_autonomy", "correlation"],
            severity: .consequential,
            title: "\(npc.name)'s Payback",
            text: "\(npc.name) reaches out. They've finally gotten their feet back under them after that rough patch. 'I haven't forgotten you helping me out,' they say. They want to treat you to something significant or just pay it forward.",
            minAge: 18, maxAge: 100, weight: 10, cooldownYears: 10,
            requirements: [],
            choices: [
                EventChoice(
                    text: "Accept the help (+$1,500)",
                    effects: ChoiceEffects(
                        finance: FinanceEffects(cashDelta: 1500),
                        relationship: RelationshipEffects(friendChange: 10)
                    ),
                    microBeat: "Karma returns.",
                    baseFriction: .none
                ),
                EventChoice(
                    text: "Tell them to keep it",
                    effects: ChoiceEffects(
                        relationship: RelationshipEffects(friendChange: 20)
                    ),
                    microBeat: "True friendship.",
                    baseFriction: .none
                )
            ]
        )
    }

    private func makeSocialInvite(for npc: Relationship) -> GameEvent {
        return GameEvent(
            id: "npc_invite_\(npc.id)",
            category: .social,
            tags: ["social", "npc_autonomy"],
            severity: .routine,
            title: "Exclusive Invite from \(npc.name)",
            text: "\(npc.name) is heading to a high-profile social gathering and wants you to join. It's a chance to build your network, but it'll cost some energy and money for the entry.",
            minAge: 18, maxAge: 100, weight: 10, cooldownYears: 2,
            requirements: [],
            choices: [
                EventChoice(
                    text: "Go along (-$200, -10 Energy)",
                    effects: ChoiceEffects(
                        core: CoreStatEffects(happiness: 5),
                        finance: FinanceEffects(cashDelta: -200),
                        relationship: RelationshipEffects(friendChange: 10, publicReputationChange: 2)
                    ),
                    microBeat: "Working the room.",
                    baseFriction: .none
                ),
                EventChoice(
                    text: "Stay home",
                    effects: ChoiceEffects(
                        relationship: RelationshipEffects(friendChange: -2)
                    ),
                    microBeat: "Quiet night.",
                    baseFriction: .none
                )
            ]
        )
    }

    private func makeMoveInAsk(for npc: Relationship) -> GameEvent {
        return GameEvent(
            id: "npc_move_in_\(npc.id)",
            category: .social,
            tags: ["social", "romance", "housing", "npc_autonomy"],
            severity: .critical,
            title: "\(npc.name) Wants to Move In",
            text: "During a quiet moment, \(npc.name) brings up the future. They think it's time you two shared a space. It would cut your living costs, but it's a massive commitment shift.",
            minAge: 20, maxAge: 100, weight: 10, cooldownYears: 99,
            requirements: [],
            choices: [
                EventChoice(
                    text: "Yes, let's do it",
                    effects: ChoiceEffects(
                        relationship: RelationshipEffects(partnerChange: 15, setPartnerStage: .committed, setCohabiting: true),
                        housing: HousingEffects(stabilityDelta: 10, setArrangement: nil) // Logic for cohabiting is handled in systems
                    ),
                    microBeat: "Keys exchanged.",
                    baseFriction: .none
                ),
                EventChoice(
                    text: "Not ready yet",
                    effects: ChoiceEffects(
                        relationship: RelationshipEffects(partnerChange: -15)
                    ),
                    microBeat: "Awkward silence.",
                    baseFriction: .resistance
                )
            ]
        )
    }

    private func makeGrapevineConfrontation(for npc: Relationship) -> GameEvent {
        return GameEvent(
            id: "npc_grapevine_\(npc.id)",
            category: .social,
            tags: ["social", "reputation", "npc_autonomy"],
            severity: .consequential,
            title: "Rumors Reach \(npc.name)",
            text: "\(npc.name) looks at you differently today. 'People are talking,' they say quietly. 'I heard some things about what you've been up to lately. Is it true?' The weight of your past decisions is suddenly in the room.",
            minAge: 16, maxAge: 100, weight: 10, cooldownYears: 5,
            requirements: [],
            choices: [
                EventChoice(
                    text: "Confess and apologize",
                    effects: ChoiceEffects(
                        relationship: RelationshipEffects(friendChange: -10),
                        consequence: ConsequenceEffects(pressureChanges: ["social": -10]) // Relieves pressure but loses bond
                    ),
                    microBeat: "Honesty hurts."
                ),
                EventChoice(
                    text: "Deny everything",
                    effects: ChoiceEffects(
                        relationship: RelationshipEffects(friendChange: -25, rumorHeatChange: 8),
                        consequence: ConsequenceEffects(pressureChanges: ["social": 15]) // Increases social pressure/paranoia
                    ),
                    microBeat: "Doubling down."
                )
            ]
        )
    }

    private func makeFinancialAsk(for npc: Relationship) -> GameEvent {
        let amount = Int.random(in: 500...2500)
        return GameEvent(
            id: "npc_ask_money_\(npc.id)",
            category: .social,
            tags: ["social", "money", "npc_autonomy"],
            severity: .consequential,
            title: "\(npc.name) Is Struggling",
            text: "\(npc.name) calls you, sounding exhausted. They've hit a rough patch and are short about $\(amount) for rent. They aren't explicitly asking, but the silence on the other end is heavy.",
            minAge: 18, maxAge: 100, weight: 10, cooldownYears: 5,
            requirements: [],
            choices: [
                EventChoice(
                    text: "Give them the $\(amount)",
                    effects: ChoiceEffects(
                        finance: FinanceEffects(cashDelta: -amount),
                        relationship: RelationshipEffects(friendChange: 15),
                        consequence: ConsequenceEffects(setFlags: ["helped_\(npc.id)"])
                    ),
                    microBeat: "Venmo sent.",
                    baseFriction: .none
                ),
                EventChoice(
                    text: "Apologize but decline",
                    effects: ChoiceEffects(
                        relationship: RelationshipEffects(friendChange: -12)
                    ),
                    microBeat: "A painful 'No'.",
                    baseFriction: .resistance
                )
            ]
        )
    }
    
    private func makeConflictEvent(for npc: Relationship) -> GameEvent {
        return GameEvent(
            id: "npc_conflict_\(npc.id)",
            category: .social,
            tags: ["social", "npc_autonomy"],
            severity: .consequential,
            title: "Tension with \(npc.name)",
            text: "\(npc.name) brings up a comment you made months ago. What started as a small disagreement is rapidly spiraling into a real argument.",
            minAge: 14, maxAge: 100, weight: 10, cooldownYears: 3,
            requirements: [],
            choices: [
                EventChoice(
                    text: "De-escalate and apologize",
                    effects: ChoiceEffects(
                        core: CoreStatEffects(happiness: -2),
                        relationship: RelationshipEffects(friendChange: 5)
                    ),
                    microBeat: "Swallowing your pride.",
                    baseFriction: .none
                ),
                EventChoice(
                    text: "Double down",
                    effects: ChoiceEffects(
                        relationship: RelationshipEffects(friendChange: -20)
                    ),
                    microBeat: "Bridge burned.",
                    baseFriction: .warning
                )
            ]
        )
    }
    
    private func makeOpportunityAsk(for npc: Relationship) -> GameEvent {
        return GameEvent(
            id: "npc_opp_\(npc.id)",
            category: .social,
            tags: ["social", "career", "npc_autonomy"],
            severity: .consequential,
            title: "\(npc.name)'s Big Move",
            text: "\(npc.name) is launching a new project and wants you to vouch for them or provide a connection. It's a lot of social capital to burn, but it could mean everything for them.",
            minAge: 22, maxAge: 100, weight: 10, cooldownYears: 5,
            requirements: [],
            choices: [
                EventChoice(
                    text: "Use your influence (Cost: 40 SC)",
                    effects: ChoiceEffects(
                        relationship: RelationshipEffects(friendChange: 20, publicReputationChange: -4)
                    ),
                    microBeat: "Making the call.",
                    baseFriction: .resistance
                ),
                EventChoice(
                    text: "Wish them luck (Do nothing)",
                    effects: ChoiceEffects(
                        relationship: RelationshipEffects(friendChange: -5)
                    ),
                    microBeat: "Polite distance.",
                    baseFriction: .none
                )
            ]
        )
    }
    
    private func makeBetrayalEvent(for npc: Relationship) -> GameEvent {
         return GameEvent(
             id: "npc_betrayal_\(npc.id)",
             category: .social,
             tags: ["social", "npc_autonomy"],
             severity: .critical,
             title: "\(npc.name)'s Departure",
             text: "You find out through a mutual contact that \(npc.name) has been talking behind your back, minimizing your successes to make themselves look better. The relationship feels different now.",
             minAge: 16, maxAge: 100, weight: 5, cooldownYears: 10,
             requirements: [],
             choices: [
                 EventChoice(
                     text: "Confront them",
                     effects: ChoiceEffects(
                         relationship: RelationshipEffects(friendChange: -30, loseFriend: true)
                     ),
                     microBeat: "Final words.",
                     baseFriction: .warning
                 ),
                 EventChoice(
                     text: "Distance yourself silently",
                     effects: ChoiceEffects(
                         relationship: RelationshipEffects(friendChange: -10)
                     ),
                     microBeat: "Ghosting.",
                     baseFriction: .none
                 )
             ]
         )
     }

    // MARK: - Frictionless Instant Reaction (the missing bridge)

    /// Lightweight, synchronous reaction when the player takes a social instant/quick action.
    /// This makes "Reach Out", "Repair Tension", etc. feel like the autonomous world
    /// responded *right now*, instead of only on the next Age Up.
    ///
    /// Returns DomainNotes that can be surfaced immediately in the activity pulse / history.
    mutating func reactToPlayerSocialAction(
        _ choiceID: ActionChoiceID,
        state: inout GameState
    ) -> [DomainNote] {
        var notes: [DomainNote] = []

        // Only react on high-signal social actions
        guard [.reachOut, .repairTension, .findYourCrowd, .protectYourEnergy].contains(choiceID) else {
            return notes
        }

        let isRepair = choiceID == .repairTension

        // Pick the most relevant contact (partner > best friend)
        var target: Relationship?
        var isPartner = false

        if state.relationships.hasPartner, let index = state.relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
            target = state.relationships.romanticPartners[index]
            isPartner = true
        } else if !state.relationships.friends.isEmpty {
            // Pick strongest bond friend for the "they noticed" feel
            if let idx = state.relationships.friends.indices.max(by: {
                state.relationships.friends[$0].bond < state.relationships.friends[$1].bond
            }) {
                target = state.relationships.friends[idx]
            }
        }

        guard var contact = target else { return notes }

        // Compute a small immediate autonomous "they responded" shift
        let baseShift = isRepair ? 8 : 5
        let moodBonus = max(0, (state.healthProfile.mentalWellness - 40) / 10) // Player mood affects reception
        let shift = baseShift + moodBonus

        if isPartner {
            contact.bond = (contact.bond + shift).clamped(to: 0...100)
            if let index = state.relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
                state.relationships.romanticPartners[index] = contact
            }

            notes.append(
                DomainNote(
                    title: "\(contact.name) Responded",
                    text: isRepair
                        ? "The conversation landed. They feel a little more seen."
                        : "They appreciated you reaching out. The thread between you tightened.",
                    tags: [.relationships, .progress]
                )
            )
        } else {
            // Update the friend in place
            if let idx = state.relationships.friends.firstIndex(where: { $0.id == contact.id }) {
                state.relationships.friends[idx].bond = (state.relationships.friends[idx].bond + shift).clamped(to: 0...100)

                notes.append(
                    DomainNote(
                        title: "\(contact.name) Texted Back",
                        text: "Your gesture registered. They seem warmer than they have in a while.",
                        tags: [.relationships]
                    )
                )
            }
        }

        // Small chance of a secondary autonomous ripple (very lightweight)
        if Int.random(in: 0...100) > 75 {
            state.consequences.narrativeFlags["recent_social_nudge", default: 0] = state.player.age
            notes.append(
                DomainNote(
                    title: "Word Spread",
                    text: "Someone else noticed you making the effort. Small social capital gained.",
                    tags: [.relationships, .progress]
                )
            )
        }

        return notes
    }

    private func processMortality(state: inout GameState) -> [GameEvent] {
        var events: [GameEvent] = []
        let age = state.player.age
        
        // Partner mortality check
        if state.relationships.hasPartner {
            for i in 0..<state.relationships.romanticPartners.count {
                var p = state.relationships.romanticPartners[i]
                guard p.status == .active else { continue }
                
                // Base risk starts low at 65 and climbs steeply after 80
                let baseRisk = age < 75 ? 2 : (age < 85 ? 6 : (age < 95 ? 15 : 25))
                if Int.random(in: 0...100) < baseRisk {
                    p.status = .ended
                    state.relationships.romanticPartners[i] = p
                    
                    events.append(GameEvent(
                        id: "npc_death_partner_\(p.id)",
                        category: .relationships,
                        tags: ["relationships", "life_event", "grief"],
                        severity: .critical,
                        title: "A Final Goodbye",
                        text: "Your partner, \(p.name), has passed away. The house feels impossibly large now. The routines you built together are suddenly just memories. You are the one left to carry the story.",
                        minAge: 65, maxAge: 120, weight: 100, cooldownYears: 99,
                        requirements: [],
                        choices: [
                            EventChoice(
                                text: "Mourn quietly",
                                effects: ChoiceEffects(
                                    core: CoreStatEffects(happiness: -25),
                                    health: HealthEffects(mental: -15)
                                ),
                                microBeat: "The silence is heavy."
                            )
                        ]
                    ))
                }
            }
        }
        
        // Close friend mortality check
        for i in 0..<state.relationships.friends.count {
            var f = state.relationships.friends[i]
            guard f.status == .active && f.bond >= 50 else { continue }
            
            let baseRisk = age < 75 ? 1 : (age < 85 ? 4 : (age < 95 ? 10 : 18))
            if Int.random(in: 0...100) < baseRisk {
                f.status = .ended
                state.relationships.friends[i] = f
                
                events.append(GameEvent(
                    id: "npc_death_friend_\(f.id)",
                    category: .social,
                    tags: ["social", "life_event", "grief"],
                    severity: .consequential,
                    title: "The Circle Narrows",
                    text: "Your friend, \(f.name), has passed away. Another thread of your history has been cut. You're becoming the last one who remembers the early days.",
                    minAge: 65, maxAge: 120, weight: 50, cooldownYears: 5,
                    requirements: [],
                    choices: [
                        EventChoice(
                            text: "A glass raised in their memory",
                            effects: ChoiceEffects(
                                core: CoreStatEffects(happiness: -10),
                                health: HealthEffects(mental: -5)
                            ),
                            microBeat: "One less chair at the table."
                        )
                    ]
                ))
            }
        }
        
        return events
    }
}
