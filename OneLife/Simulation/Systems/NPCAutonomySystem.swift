import Foundation

struct NPCAutonomySystem {
    func advanceYear(state: inout GameState) -> [GameEvent] {
        var generatedEvents: [GameEvent] = []
        
        // 1. Process Romantic Partner
        if var partner = state.relationships.romanticPartner {
            let events = processAutonomy(for: &partner, type: .romantic, player: state.player, state: state)
            generatedEvents.append(contentsOf: events)
            state.relationships.romanticPartner = partner
        }
        
        // 2. Process Friends
        for i in 0..<state.relationships.friends.count {
            let events = processAutonomy(for: &state.relationships.friends[i], type: .friend, player: state.player, state: state)
            generatedEvents.append(contentsOf: events)
        }

        // 3. System Interventions (Cross-Domain)
        if let intervention = checkForInterventions(state: state) {
            generatedEvents.append(intervention)
        }
        
        return generatedEvents
    }

    private func checkForInterventions(state: GameState) -> GameEvent? {
        // Career Burnout Intervention (High Career + Low Health + Low Partner Bond)
        if state.career.performance >= 80 && state.healthProfile.mentalWellness <= 35 && state.relationships.partnerBond <= 45 && state.relationships.hasPartner {
            return GameEvent(
                id: "intervention_burnout",
                category: .health,
                tags: ["health", "relationships", "career", "intervention"],
                severity: .critical,
                title: "Breaking Point",
                text: "Your partner sits you down. 'I barely see you, and when I do, you're a ghost,' they say. 'This job is eating you alive. Something has to change, or I can't stay.' You realize your physical and mental health are at a critical low despite your career success.",
                minAge: 22, maxAge: 100, weight: 20, cooldownYears: 10,
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
        return nil
    }
    
    private func processAutonomy(for npc: inout Relationship, type: RelationshipType, player: Player, state: GameState) -> [GameEvent] {
        var events: [GameEvent] = []
        
        // Age hidden states
        npc.hiddenNeedLevel += Int.random(in: 2...8)
        if npc.bond < 40 { npc.hiddenResentment += Int.random(in: 1...5) }
        
        // Roll for Autonomous Action
        let actionRoll = Int.random(in: 0...100)
        
        // Check Correlation: Did we help them before?
        let helpedKey = "helped_\(npc.id)"
        let hasHelped = state.consequences.narrativeFlags[helpedKey, default: 0] > 0
        
        if hasHelped && actionRoll > 85 && type == .friend {
            events.append(makeGratitudeEvent(for: npc))
            return events // Gratitude replaces other actions this year
        }

        // The Grapevine: Does this NPC know about our 'heat'?
        let grapevineHeat = state.relationships.activeRumorHeat
        if grapevineHeat >= 50 && actionRoll > 75 {
            events.append(makeGrapevineConfrontation(for: npc))
            return events
        }

        // Thresholds based on personality
        switch npc.personality {
        case .needy:
            if npc.hiddenNeedLevel >= 60 && actionRoll > 70 {
                events.append(makeFinancialAsk(for: npc))
                npc.hiddenNeedLevel = 0
            }
        case .unstable:
            if npc.hiddenResentment >= 50 && actionRoll > 80 {
                events.append(makeConflictEvent(for: npc))
                npc.hiddenResentment /= 2
            }
        case .ambitious:
            if actionRoll > 90 {
                events.append(makeOpportunityAsk(for: npc))
            }
        case .selfish:
            if npc.hiddenResentment >= 40 && actionRoll > 75 {
                events.append(makeBetrayalEvent(for: npc))
            }
        case .generous:
            if actionRoll > 85 && type == .friend {
                events.append(makeSocialInvite(for: npc))
            }
        default:
            break
        }
        
        // Relationship Milestones (Autonomous)
        if type == .romantic && state.player.age >= 20 {
            if state.relationships.partnerBond >= 75 && !state.relationships.hasCohabitingPartner && actionRoll > 92 {
                events.append(makeMoveInAsk(for: npc))
            }
        }
        
        return events
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
}
