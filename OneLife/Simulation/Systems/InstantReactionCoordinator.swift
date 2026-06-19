import Foundation

/// Phase 1 (Orchestrator Cleanup – Complete): Dedicated coordinator for the fast "instant action + autonomous world reaction" path.
///
/// This is the single home for the frictionless reactive layer.
/// It was fully extracted and promoted; the orchestrator no longer contains a copy of this logic.
///
/// Responsibilities:
/// - Enrich an already-applied instant action with immediate autonomous reactions (NPC, Health, Finance, etc.)
/// - Record `InstantMomentum` so recent focused play can influence the next yearly simulation (Phase 2/3 bridge)
/// - Keep history injection and light side effects clean
///
/// The orchestrator (LifeSimulationOrchestrator) owns the heavy yearly tick (resolvePreparedYearChapter and friends).
/// This coordinator owns only the "press button → world reacts *now*" enrichment.
///
/// See LifeSimulationOrchestrator.swift for the "Player Micro Move vs Year Commitment" mental model documentation.
struct InstantReactionCoordinator {

    private static let financeStaticInstantCore: Set<ActionChoiceID> = [
        .curateCollection, .hostSignatureEvent, .maintainAsset, .negotiateBetterTerms,
        .quietlyBuildCushion, .reviewNumbersRuthlessly
    ]

    private static let relationshipsStaticInstantCore: Set<ActionChoiceID> = [
        .deepenSpecificBond, .fuelRivalry, .splitReputation, .realConversation,
        .setBoundary, .networkWithoutMask, .checkInOnChild
    ]

    private static let playStaticInstantCore: Set<ActionChoiceID> = [
        .hobbySession, .socialOuting, .creativeOutlet, .adventure, .relaxRoutine
    ]

    private static let careerStaticInstantCore: Set<ActionChoiceID> = [
        .putYourHeadDown, .protectWorkLifeLine
    ]

    private static let healthStaticInstantCore: Set<ActionChoiceID> = [
        .bodyConditioning, .recurringTherapy, .manageMeds, .seeDoctor, .sleepLikeItMatters, .coldExposureDrill,
        .improveSleep
    ]

    private static let identityStaticInstantCore: Set<ActionChoiceID> = [
        .morningReflection, .reconcileWithPast, .protectYourEnergy, .tryNewPersona, .processCrisis,
        .journalTheShape, .quietTheNoise
    ]

    private var npcAutonomySystem: NPCAutonomySystem
    private var healthSystem: HealthSystem
    private var financeSystem: FinanceSystem
    private var stockMarketSystem: StockMarketSystem
    private var luxurySystem: LuxurySystem

    init(
        npcAutonomySystem: NPCAutonomySystem = NPCAutonomySystem(),
        healthSystem: HealthSystem = HealthSystem(),
        financeSystem: FinanceSystem = FinanceSystem(),
        stockMarketSystem: StockMarketSystem = StockMarketSystem(),
        luxurySystem: LuxurySystem = LuxurySystem()
    ) {
        self.npcAutonomySystem = npcAutonomySystem
        self.healthSystem = healthSystem
        self.financeSystem = financeSystem
        self.stockMarketSystem = stockMarketSystem
        self.luxurySystem = luxurySystem
    }

    /// The main enrichment method for the frictionless instant path.
    /// Call this after `applyImmediateAction` to add autonomous reactions + momentum.
    mutating func enrichWithAutonomousReactions(
        choiceID: ActionChoiceID,
        domain: ActionDomain,
        baseResult: inout DomainYearResult,
        state: inout GameState
    ) {
        var autonomousNotes: [DomainNote] = []

        switch domain {
        case .relationships:
            let notes = npcAutonomySystem.reactToPlayerSocialAction(choiceID, state: &state)
            autonomousNotes.append(contentsOf: notes)
            for note in notes {
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }
            if Self.relationshipsStaticInstantCore.contains(choiceID) {
                state.instantMomentum.recordReaction(domain: .relationships, strength: 13, currentAge: state.player.age)
            }

        case .health:
            let notes = healthSystem.reactToPlayerHealthAction(choiceID, state: &state)
            autonomousNotes.append(contentsOf: notes)
            for note in notes {
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }
            if Self.healthStaticInstantCore.contains(choiceID) {
                state.activities.recoveryBalance = (state.activities.recoveryBalance + 4).clamped(to: 0...100)
                state.correlationLedger.publish(
                    CorrelationSignal(kind: .instantActionPulse, domain: "health", strength: 16, age: state.player.age)
                )
                state.instantMomentum.recordReaction(domain: .health, strength: 14, currentAge: state.player.age)
            }

        case .identity:
            if Self.identityStaticInstantCore.contains(choiceID) {
                state.correlationLedger.publish(
                    CorrelationSignal(kind: .instantActionPulse, domain: "identity", strength: 18, age: state.player.age)
                )
                state.instantMomentum.recordReaction(domain: .identity, strength: 12, currentAge: state.player.age)
            }

        case .finance:
            let notes = financeSystem.reactToPlayerFinanceAction(choiceID, state: &state)
            autonomousNotes.append(contentsOf: notes)

            // Econ1/2: Stock Market reactions
            let stockNotes = stockMarketSystem.reactToStockAction(choiceID, state: &state)
            autonomousNotes.append(contentsOf: stockNotes)

            // Luxury L1/L2: Luxury reactions
            let luxuryNotes = luxurySystem.reactToLuxuryAction(choiceID, state: &state)
            autonomousNotes.append(contentsOf: luxuryNotes)

            // D2 Collector loops + core finance statics: generic momentum and texture
            if Self.financeStaticInstantCore.contains(choiceID) {
                state.instantMomentum.recordReaction(domain: .finance, strength: 12, currentAge: state.player.age)
                if choiceID == .hostSignatureEvent {
                    state.fame.culturalFame = min(100, state.fame.culturalFame + 3)
                    autonomousNotes.append(DomainNote(title: "Status Pulse", text: "You were seen in the right places. The reputation holds.", tags: [.social, .fame]))
                }
            }
            
            let allFinanceNotes = notes + stockNotes + luxuryNotes + (autonomousNotes.filter { $0.tags.contains(.finance) || $0.tags.contains(.assets) })
            for note in allFinanceNotes {
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }

        case .family:
            if [.spendTimeWithKids, .checkInOnChild, .enforceRoutine, .encourageIndependence].contains(choiceID) {
                // Light instant family reaction — small immediate bond/mood bump so the button press feels alive
                if !state.family.children.filter({ $0.livesAtHome }).isEmpty {
                    for i in state.family.children.indices where state.family.children[i].livesAtHome {
                        let quickGain = Int.random(in: 2...5)
                        state.family.children[i].bondWithPlayer = (state.family.children[i].bondWithPlayer + quickGain).clamped(to: 5...95)
                    }
                    let note = DomainNote(title: "Kids Noticed", text: "They felt the attention right away. The evening was a little lighter.", tags: [.family, .relationships])
                    autonomousNotes.append(note)
                    state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
                }
            }

        case .career:
            if Self.careerStaticInstantCore.contains(choiceID) {
                state.instantMomentum.recordReaction(domain: .career, strength: 14, currentAge: state.player.age)
            }

        case .play:
            if Self.playStaticInstantCore.contains(choiceID) {
                state.activities.recoveryBalance = (state.activities.recoveryBalance + 3).clamped(to: 0...100)
                state.instantMomentum.recordReaction(domain: .play, strength: 12, currentAge: state.player.age)
            }

        default:
            break
        }

        // Phase S2: Athlete-specific instant reactions for frictionless sports experience
        if state.specialCareer.track == .athlete {
            var athleteNote: DomainNote? = nil
            switch choiceID {
            case .extraTrainingSession:
                state.specialCareer.athlete.peakPerformance = min(100, state.specialCareer.athlete.peakPerformance + 4)
                state.specialCareer.athlete.injuryRisk = min(80, state.specialCareer.athlete.injuryRisk + 5)
                athleteNote = DomainNote(title: "Body Pushed", text: "The extra session left you stronger but more fragile. The machine is being tested.", tags: [.health, .career])
            case .mediaAppearance:
                state.specialCareer.fame = min(100, state.specialCareer.fame + 5)
                state.specialCareer.heat = min(100, state.specialCareer.heat + 8)
                // Fame Web F1: instant actions now also move the unified profile
                state.fame.culturalFame = min(100, state.fame.culturalFame + 4)
                athleteNote = DomainNote(title: "Spotlight Hit", text: "The cameras loved you. Your name travels further tonight.", tags: [.career, .social])
            case .recoveryFocus:
                state.specialCareer.athlete.durability = min(95, state.specialCareer.athlete.durability + 6)
                state.specialCareer.athlete.injuryRisk = max(5, state.specialCareer.athlete.injuryRisk - 8)
                state.specialCareer.burnout = max(0, state.specialCareer.burnout - 5)
                athleteNote = DomainNote(title: "Body Listened", text: "The physio and ice worked. You feel a little more durable heading into the next stretch.", tags: [.health])
            case .teamBonding:
                state.specialCareer.athlete.fanLoyalty = min(100, state.specialCareer.athlete.fanLoyalty + 5)
                athleteNote = DomainNote(title: "Locker Room Bond", text: "The team feels tighter. The fans can sense it too.", tags: [.social, .career])
            // S3a: Edge Protocol (doping) — instant reaction, the moment you cross the line
            case .edgeProtocol:
                let potency = max(6, state.specialCareer.athlete.naturalPotential / 12)
                state.specialCareer.athlete.peakPerformance = min(100, state.specialCareer.athlete.peakPerformance + potency)
                state.specialCareer.athlete.injuryRisk = min(90, state.specialCareer.athlete.injuryRisk + 14)
                state.specialCareer.athlete.enhancementUses += 1
                state.specialCareer.athlete.enhancementHeat = min(100, state.specialCareer.athlete.enhancementHeat + 35)
                state.specialCareer.athlete.lastEnhancementAge = state.player.age
                // Personal brand takes a quiet hit even before detection — the "something's off" feeling
                state.specialCareer.athlete.personalBrand = max(5, state.specialCareer.athlete.personalBrand - 3)
                state.specialCareer.heat = min(100, state.specialCareer.heat + 18)
                // Fame Web F1 — doping moves notoriety (dark fame) immediately
                state.fame.notoriety = min(100, state.fame.notoriety + 6)
                state.fame.culturalFame = max(0, state.fame.culturalFame - 2)
                athleteNote = DomainNote(title: "Line Crossed", text: "The edge is real. Your body feels superhuman tonight. The cost is already written in your blood and your name.", tags: [.career, .health, .risk])
            default:
                break
            }
            if let note = athleteNote {
                autonomousNotes.append(note)
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }
        }

        // E2: Founder-specific instant reactions for frictionless entrepreneur experience
        if state.specialCareer.track == .founder {
            var founderNote: DomainNote? = nil
            switch choiceID {
            case .closeMajorDeal:
                state.specialCareer.founder.execution = min(95, state.specialCareer.founder.execution + 5)
                state.specialCareer.audience = min(100, state.specialCareer.audience + 6)
                state.specialCareer.heat += 8
                founderNote = DomainNote(title: "Deal Closed", text: "The partnership lands. Momentum shifts. The pressure just went up a notch.", tags: [.career, .finance])
            case .allHandsRally:
                state.specialCareer.founder.teamHealth = min(95, state.specialCareer.founder.teamHealth + 7)
                state.specialCareer.founder.companyCulture = min(95, state.specialCareer.founder.companyCulture + 4)
                state.specialCareer.founder.founderMentalLoad = max(5, state.specialCareer.founder.founderMentalLoad - 5)
                founderNote = DomainNote(title: "Room Lit Up", text: "You reminded everyone why they joined. The energy in the building changed.", tags: [.career, .social])
            case .fundraiseSprint:
                let raise = max(8, state.specialCareer.founder.vision / 6)
                state.specialCareer.audience = min(100, state.specialCareer.audience + raise)
                state.specialCareer.equityOwned = max(0.4, state.specialCareer.equityOwned - 0.08)
                state.specialCareer.founder.founderMentalLoad = min(95, state.specialCareer.founder.founderMentalLoad + 9)
                founderNote = DomainNote(title: "Capital Raised", text: "The round closes. You gave up more of the company, but the runway just got longer.", tags: [.career, .finance])
            case .takeRealBreak:
                state.specialCareer.founder.founderMentalLoad = max(5, state.specialCareer.founder.founderMentalLoad - 12)
                state.specialCareer.founder.execution = max(25, state.specialCareer.founder.execution - 4)
                state.specialCareer.burnout = max(0, state.specialCareer.burnout - 8)
                founderNote = DomainNote(title: "Batteries Recharged", text: "You stepped away. The company didn't collapse. You remember what a full night of sleep feels like.", tags: [.health])
            case .hireKeyTalent:
                state.specialCareer.founder.keyHires = min(100, state.specialCareer.founder.keyHires + 8)
                state.specialCareer.founder.teamHealth = min(95, state.specialCareer.founder.teamHealth + 3)
                state.specialCareer.heat += 6
                founderNote = DomainNote(title: "Star Signed", text: "The right person said yes. Everything just got a little more possible.", tags: [.career, .social])
            default:
                break
            }
            if let note = founderNote {
                autonomousNotes.append(note)
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }
        }

        // C2: Content Creator specific instant reactions
        if state.specialCareer.track == .contentCreator {
            var creatorNote: DomainNote? = nil
            switch choiceID {
            case .postDaily:
                let gain = max(1, state.specialCareer.creator.consistency / 10)
                state.specialCareer.creator.audience = min(100, state.specialCareer.creator.audience + gain)
                state.specialCareer.creator.algorithmFavor = min(95, state.specialCareer.creator.algorithmFavor + 3)
                state.specialCareer.creator.burnout = min(95, state.specialCareer.creator.burnout + 2)
                creatorNote = DomainNote(title: "Posted", text: "Another day, another piece of you fed to the machine. The numbers moved a little.", tags: [.career, .social])
            case .goLive:
                state.specialCareer.creator.algorithmFavor = min(95, state.specialCareer.creator.algorithmFavor + 6)
                state.specialCareer.creator.personalBrand = min(100, state.specialCareer.creator.personalBrand + 4)
                state.specialCareer.creator.burnout = min(95, state.specialCareer.creator.burnout + 5)
                state.specialCareer.creator.cancellationRisk = min(90, state.specialCareer.creator.cancellationRisk + 3)
                creatorNote = DomainNote(title: "Went Live", text: "Raw, unfiltered, and real. The chat went crazy. You feel both more connected and more exposed.", tags: [.social, .risk])
            case .filmBanger:
                let quality = state.specialCareer.creator.contentQuality
                let swing = (quality - 40) / 3
                state.specialCareer.creator.audience = min(100, state.specialCareer.creator.audience + max(3, swing))
                state.specialCareer.creator.personalBrand = min(100, state.specialCareer.creator.personalBrand + 2)
                state.specialCareer.creator.burnout = min(95, state.specialCareer.creator.burnout + 8)
                creatorNote = DomainNote(title: "Banger Filmed", text: "You poured everything into this one. It might be the one that changes everything. Or it might disappear.", tags: [.career, .risk])
            case .collab:
                state.specialCareer.creator.audience = min(100, state.specialCareer.creator.audience + 5)
                state.specialCareer.creator.personalBrand = max(15, state.specialCareer.creator.personalBrand - 3)
                state.specialCareer.creator.brandDealValue = min(100, state.specialCareer.creator.brandDealValue + 6)
                creatorNote = DomainNote(title: "Collab Dropped", text: "You borrowed someone else's audience. It worked. It also cost a little piece of what made you you.", tags: [.social, .career])
            case .addressDrama:
                state.specialCareer.creator.cancellationRisk = max(5, state.specialCareer.creator.cancellationRisk - 12)
                state.specialCareer.creator.personalBrand = max(15, state.specialCareer.creator.personalBrand - 5)
                state.specialCareer.creator.burnout = min(95, state.specialCareer.creator.burnout + 4)
                creatorNote = DomainNote(title: "Statement Made", text: "You looked straight into the camera and said your piece. Some people believed you. Some never will.", tags: [.social, .risk])
            case .takeMentalBreak:
                state.specialCareer.creator.burnout = max(5, state.specialCareer.creator.burnout - 15)
                state.specialCareer.creator.algorithmFavor = max(10, state.specialCareer.creator.algorithmFavor - 8)
                state.specialCareer.creator.audience = max(5, state.specialCareer.creator.audience - 4)
                creatorNote = DomainNote(title: "Logged Off", text: "You disappeared. The numbers dipped. Your nervous system finally exhaled.", tags: [.health])
            case .dropBrandDeal:
                state.specialCareer.creator.brandDealValue = min(100, state.specialCareer.creator.brandDealValue + 10)
                state.specialCareer.creator.personalBrand = max(10, state.specialCareer.creator.personalBrand - 6)
                state.specialCareer.creator.burnout = min(95, state.specialCareer.creator.burnout + 3)
                creatorNote = DomainNote(title: "Deal Signed", text: "The money is real. So is the quiet voice asking if this was worth it.", tags: [.finance, .career])
            default:
                break
            }
            if let note = creatorNote {
                autonomousNotes.append(note)
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }
        }

        // P2: Politics specific instant reactions
        if state.specialCareer.track == .politics {
            var politicsNote: DomainNote? = nil
            switch choiceID {
            case .townHall:
                let swing = (state.specialCareer.politics.charisma - 40) / 4
                state.specialCareer.politics.approvalRating = (state.specialCareer.politics.approvalRating + swing).clamped(to: 0...100)
                state.specialCareer.politics.burnout = min(95, state.specialCareer.politics.burnout + 4)
                politicsNote = DomainNote(title: "Town Hall Held", text: "You stood in front of real people. Some loved you. Some hated you. You feel more human and more exposed.", tags: [.social, .career])
            case .politicalFundraise:
                state.specialCareer.politics.donorBase = min(100, state.specialCareer.politics.donorBase + 6)
                state.specialCareer.politics.ethics = max(15, state.specialCareer.politics.ethics - 4)
                state.specialCareer.politics.burnout = min(95, state.specialCareer.politics.burnout + 3)
                politicsNote = DomainNote(title: "Fundraising Haul", text: "The checks cleared. Your war chest is fatter, and your soul feels a little lighter in the wrong direction.", tags: [.finance, .career])
            case .scandalResponse:
                state.specialCareer.politics.scandalHeat = max(5, state.specialCareer.politics.scandalHeat - 10)
                state.specialCareer.politics.approvalRating = max(5, state.specialCareer.politics.approvalRating - 6)
                state.specialCareer.politics.ethics = max(15, state.specialCareer.politics.ethics - 3)
                politicsNote = DomainNote(title: "Damage Controlled", text: "You faced the music. Some believed the story. Others believed your response. The bleeding stopped — for now.", tags: [.social, .risk])
            case .policyPush:
                state.specialCareer.politics.policyLegacy = min(100, state.specialCareer.politics.policyLegacy + 8)
                state.specialCareer.politics.approvalRating = max(5, state.specialCareer.politics.approvalRating - 5)
                state.specialCareer.politics.burnout = min(95, state.specialCareer.politics.burnout + 5)
                politicsNote = DomainNote(title: "Policy Pushed", text: "You spent real capital on something that might actually matter. History might remember it. Your poll numbers might not.", tags: [.career, .progress])
            case .backroomDeal:
                state.specialCareer.politics.donorBase = min(100, state.specialCareer.politics.donorBase + 5)
                state.specialCareer.politics.ethics = max(15, state.specialCareer.politics.ethics - 6)
                state.specialCareer.politics.approvalRating = (state.specialCareer.politics.approvalRating + 3).clamped(to: 0...100)
                politicsNote = DomainNote(title: "Deal Cut", text: "You traded something today for power tomorrow. The room felt smaller afterward.", tags: [.career, .risk])
            case .mediaHit:
                let swing = (state.specialCareer.politics.charisma - 35) / 3
                state.specialCareer.politics.approvalRating = (state.specialCareer.politics.approvalRating + swing).clamped(to: 0...100)
                state.specialCareer.politics.scandalHeat = min(100, state.specialCareer.politics.scandalHeat + 4)
                politicsNote = DomainNote(title: "Media Hit", text: "You owned the room. Or you stumbled. Either way, millions of people now have a stronger opinion about you.", tags: [.social, .career])
            case .takeAStand:
                state.specialCareer.politics.ethics = min(100, state.specialCareer.politics.ethics + 8)
                state.specialCareer.politics.approvalRating = max(5, state.specialCareer.politics.approvalRating - 7)
                state.specialCareer.politics.policyLegacy = min(100, state.specialCareer.politics.policyLegacy + 4)
                politicsNote = DomainNote(title: "Line in the Sand", text: "You drew a line. Some people respect you more. Others will never forgive you. It felt right.", tags: [.career, .progress])
            case .attackOpponent:
                state.specialCareer.politics.approvalRating = (state.specialCareer.politics.approvalRating + 6).clamped(to: 0...100)
                state.specialCareer.politics.ethics = max(10, state.specialCareer.politics.ethics - 7)
                state.specialCareer.politics.scandalHeat = min(100, state.specialCareer.politics.scandalHeat + 5)
                politicsNote = DomainNote(title: "Attack Landed", text: "You went for the throat. It hurt them. It also hurt something in you.", tags: [.social, .risk])
            default:
                break
            }
            if let note = politicsNote {
                autonomousNotes.append(note)
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }
        }

        // CE2: Criminal Enterprise specific instant reactions (shadow vs enterprise flavor + era reactivity)
        if state.crime.status == .active || state.specialCareer.track == .crime {
            var crimeNote: DomainNote? = nil
            let ent = state.specialCareer.enterprise
            let era = state.currentEra

            switch choiceID {
            case .ghostProtocol:
                // Disappear — strong heat reduction, costs network/visibility
                state.crime.heat = max(0, state.crime.heat - 18)
                state.specialCareer.heat = max(0, state.specialCareer.heat - 10)
                state.specialCareer.enterprise.networkStrength = max(10, ent.networkStrength - 4)
                if ent.subtype == .shadowOperative || ent.subtype == .grayMarketTrader {
                    state.specialCareer.enterprise.operationalSecurity = min(100, ent.operationalSecurity + 6)
                }
                crimeNote = DomainNote(title: "Gone Dark", text: "You vanished for a while. The heat dropped, but so did your reach.", tags: [.crime, .risk])

            case .burnEvidence:
                // Irreversible cleanup — heat down, cash/option cost
                state.crime.heat = max(0, state.crime.heat - 12)
                state.finance.cashOnHand = max(0, state.finance.cashOnHand - 2800)
                state.specialCareer.enterprise.loyalty = max(10, ent.loyalty - 3)
                crimeNote = DomainNote(title: "Evidence Destroyed", text: "You burned what could be used against you. It cost money and options.", tags: [.crime, .risk])

            case .payTheFixer:
                // Pay to make problems smaller
                let cost = 3500 + (state.crime.heat * 28)
                state.finance.cashOnHand = max(0, state.finance.cashOnHand - cost)
                state.crime.heat = max(0, state.crime.heat - 16)
                state.specialCareer.enterprise.operationalSecurity = min(100, ent.operationalSecurity + 3)
                if era == .wartime || era == .pandemic {
                    // Fixers are busier / more expensive in chaotic eras
                    state.specialCareer.enterprise.loyalty = max(5, ent.loyalty - 2)
                }
                crimeNote = DomainNote(title: "Fixer Paid", text: "The right person made some problems smaller. For now.", tags: [.crime, .finance])

            case .launderThroughShell:
                // Move dirty money toward clean
                let gain = (era == .recession || era == .highInflation) ? 5 : 9
                state.specialCareer.enterprise.cleanMoneyRatio = min(100, ent.cleanMoneyRatio + gain)
                state.finance.cashOnHand = max(0, state.finance.cashOnHand - 2200)
                state.specialCareer.heat = max(0, state.specialCareer.heat - 5)
                if ent.subtype == .ventureCapitalist || ent.subtype == .corporateRaider {
                    state.specialCareer.enterprise.networkStrength = min(100, ent.networkStrength + 3)
                }
                crimeNote = DomainNote(title: "Money Cleaned", text: "The cash looks a little more legitimate. The process was expensive and slow.", tags: [.finance, .crime])

            case .hostStrategicGala:
                // Social cover + network
                state.specialCareer.enterprise.networkStrength = min(100, ent.networkStrength + 8)
                state.specialCareer.heat = max(0, state.specialCareer.heat - 3)
                state.specialCareer.enterprise.loyalty = min(100, ent.loyalty + 4)
                if era == .techBoom || era == .bullMarket {
                    // High-society events easier to hide in boom times
                    state.fame.notoriety = min(100, state.fame.notoriety + 3)
                }
                crimeNote = DomainNote(title: "Strategic Gathering", text: "You hosted the right people. Deals were discussed. Alibis were established.", tags: [.social, .crime])

            case .aggressiveTakeover:
                // High-risk high-reward swing
                let gain = 14000 + ent.riskTolerance * 180
                baseResult.financeEffects = FinanceEffects(cashDelta: gain)
                state.specialCareer.heat += 14
                state.crime.heat = min(100, state.crime.heat + 10)
                state.specialCareer.enterprise.loyalty = max(0, ent.loyalty - 9)
                state.specialCareer.enterprise.riskTolerance = min(90, ent.riskTolerance + 4)
                if ent.subtype == .streetCrime || ent.subtype == .corporateRaider {
                    state.specialCareer.enterprise.notoriety = min(100, ent.notoriety + 6)
                }
                crimeNote = DomainNote(title: "Aggressive Move", text: "You took what you wanted. The money is real. So is the new heat.", tags: [.finance, .crime, .risk])

            case .runScheme:
                // Shared fast-money play — risk/reward
                let schemeGain = 6000 + (ent.riskTolerance / 3 * 200)
                baseResult.financeEffects = FinanceEffects(cashDelta: schemeGain)
                state.crime.heat = min(100, state.crime.heat + 8)
                state.specialCareer.enterprise.loyalty = max(10, ent.loyalty - 3)
                crimeNote = DomainNote(title: "Scheme Ran", text: "Fast money moved. Some of it stuck. The rest left a trail.", tags: [.finance, .crime])

            case .buildCrew:
                // Loyalty and reach play
                state.specialCareer.enterprise.crewSize = min(22, ent.crewSize + 1)
                state.specialCareer.enterprise.loyalty = min(100, ent.loyalty + 7)
                state.crime.heat = min(100, state.crime.heat + 5)
                crimeNote = DomainNote(title: "Circle Expanded", text: "New faces owe you favors. More mouths to feed, more eyes watching your back.", tags: [.social, .crime])

            case .cleanMoney:
                // Shared heat-reduction via legit channels
                state.specialCareer.enterprise.cleanMoneyRatio = min(100, ent.cleanMoneyRatio + 6)
                state.crime.heat = max(0, state.crime.heat - 6)
                state.finance.cashOnHand = max(0, state.finance.cashOnHand - 1800)
                crimeNote = DomainNote(title: "Trail Scrubbed", text: "You spent real effort making the numbers look ordinary.", tags: [.finance, .crime])

            case .layLow, .stepAway:
                // Defensive breathing room
                state.crime.heat = max(0, state.crime.heat - 9)
                state.specialCareer.heat = max(0, state.specialCareer.heat - 5)
                state.specialCareer.enterprise.operationalSecurity = min(100, ent.operationalSecurity + 4)
                crimeNote = DomainNote(title: "Pulled Back", text: "You chose air over momentum. The pressure eased a little.", tags: [.crime, .health])

            case .streetCornerHustle, .dodgePatrol, .holdTerritory, .disciplineCrew, .delegateOperation:
                break

            case .expandDomesticEmpire:
                state.specialCareer.enterprise.subtype = ent.subtype == .streetCrime ? .ventureCapitalist : ent.subtype
                state.specialCareer.enterprise.empireBranch = .domesticKingpin
                state.specialCareer.enterprise.cleanMoneyRatio = min(100, ent.cleanMoneyRatio + 8)
                state.specialCareer.enterprise.networkStrength = min(100, ent.networkStrength + 5)
                state.specialCareer.heat += 4
                crimeNote = DomainNote(title: "Domestic Empire", text: "Another legitimate front. Another door that opens because you own the hinge.", tags: [.crime, .finance])

            case .connectCartelNetwork:
                state.specialCareer.enterprise.subtype = .transnationalCartel
                state.specialCareer.enterprise.empireBranch = .transnationalCartel
                state.specialCareer.enterprise.networkStrength = min(100, ent.networkStrength + 10)
                state.specialCareer.enterprise.riskTolerance = min(90, ent.riskTolerance + 6)
                state.specialCareer.heat += 12
                state.crime.heat = min(100, state.crime.heat + 8)
                baseResult.financeEffects = FinanceEffects(cashDelta: 12_000 + ent.networkStrength * 120)
                crimeNote = DomainNote(title: "Cartel Pipeline", text: "The money crosses borders now. The exposure changed shape — and scale.", tags: [.crime, .finance, .risk])

            default:
                break
            }

            if let note = crimeNote {
                autonomousNotes.append(note)
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }

            // CE2 Fame Web: Criminal instant actions meaningfully feed notoriety (the dark fame track)
            // Aggressive or high-heat moves create real cultural "shadow reputation"
            if [.aggressiveTakeover, .runScheme, .buildCrew, .ghostProtocol].contains(choiceID) {
                let notoGain = choiceID == .aggressiveTakeover ? 5 : 2
                state.fame.notoriety = min(100, state.fame.notoriety + notoGain)
                if state.fame.culturalFame >= 25 {
                    state.fame.culturalFame = max(0, state.fame.culturalFame - 1) // slight cultural cost for dark moves
                }
            }
        }

        // PC1: Custody instant reactions — conduct, violence, snitch, faction texture
        if state.legal.isInCustody {
            var custodyNote: DomainNote? = nil
            var profile = state.legal.custodyProfile
            switch choiceID {
            case .keepHeadDown:
                profile.conductScore += 2
                custodyNote = DomainNote(title: "Eyes Down", text: "Staff logged another quiet week. The block barely noticed you.", tags: [.legal, .autonomousReaction])
            case .standYourGround:
                profile.yardReputation += 4
                profile.violenceRisk += 3
                custodyNote = DomainNote(title: "Yard Shift", text: "Someone tested you. The test ended without a write-up — this time.", tags: [.legal, .crime, .autonomousReaction])
            case .alignWithFaction:
                profile.protectionDebt += 3
                custodyNote = DomainNote(title: "Crew Signal", text: "Your name moved through the faction channel before lights-out.", tags: [.legal, .crime, .autonomousReaction])
            case .payProtection:
                custodyNote = DomainNote(title: "Ledger Updated", text: "The debt was acknowledged. Pressure eased for a few days.", tags: [.legal, .finance, .autonomousReaction])
            case .refuseSnitchDeal:
                profile.snitchRisk = max(0, profile.snitchRisk - 3)
                custodyNote = DomainNote(title: "Silence Held", text: "Guards filed frustration. Inmates filed respect.", tags: [.legal, .crime, .autonomousReaction])
            case .cooperateWithGuards:
                profile.factionLoyalty = max(0, profile.factionLoyalty - 5)
                state.fame.notoriety = min(100, state.fame.notoriety + 3)
                custodyNote = DomainNote(title: "Whisper Network", text: "Word about your cooperation moved before you reached your cell.", tags: [.legal, .crime, .risk, .autonomousReaction])
            case .prisonWorkDetail:
                profile.goodTimeCredits += 1
                custodyNote = DomainNote(title: "Shift Credit", text: "Supervisor logged reliable work. Good-time paperwork ticked forward.", tags: [.legal, .progress, .autonomousReaction])
            case .studyProgram:
                profile.programProgress += 3
                custodyNote = DomainNote(title: "Lesson Landed", text: "An instructor marked progress. The file got a little thicker.", tags: [.legal, .education, .autonomousReaction])
            case .callFamily:
                custodyNote = DomainNote(title: "Line Clicked Off", text: "The call ended before the apology did.", tags: [.legal, .family, .autonomousReaction])
            case .requestParoleHearing:
                custodyNote = DomainNote(title: "Board Packet", text: "Your file moved to the parole queue. The yard watched who got hopeful.", tags: [.legal, .progress, .autonomousReaction])
            case .fileAppeal:
                custodyNote = DomainNote(title: "Paper Trail", text: "Legal mail left the block. Hope and cost traveled together.", tags: [.legal, .finance, .autonomousReaction])
            case .delegateFromInside:
                profile.protectionDebt += 2
                custodyNote = DomainNote(title: "Chain Of Command", text: "Orders left the cell. Someone outside saluted — and someone else listened.", tags: [.legal, .crime, .autonomousReaction])
            case .callLieutenant:
                state.fame.notoriety = min(100, state.fame.notoriety + 2)
                custodyNote = DomainNote(title: "Line Tapped", text: "The call was logged. The network still answered.", tags: [.legal, .crime, .fame, .autonomousReaction])
            case .authorizeOutsideMove:
                custodyNote = DomainNote(title: "Remote Authorization", text: "Cash moved on your signature. The block felt the ripple.", tags: [.legal, .finance, .crime, .autonomousReaction])
            default:
                break
            }
            state.legal.custodyProfile = profile
            state.legal.clamp()
            if let note = custodyNote {
                autonomousNotes.append(note)
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }
        }

        // CE4: Lingering shadow after leaving criminal life (real coordinator)
        if state.specialCareer.track != .crime && state.crime.status != .active && (state.specialCareer.heat >= 25 || state.fame.notoriety >= 35) {
            if state.player.age % 3 == 0 && Int.random(in: 0...100) < 18 {
                let shadowNote: String
                if state.fame.notoriety >= 60 {
                    shadowNote = "Someone still uses your old name when they want to scare people. You pretend not to hear it."
                } else if state.specialCareer.heat >= 40 {
                    shadowNote = "Old heat doesn't fully cool. You still check the rearview more than you need to."
                } else {
                    shadowNote = "Most days you are just another person. Some days the old life sends a postcard in the form of a strange look from a stranger."
                }
                state.history.insert(HistoryEntry(age: state.player.age, title: "Old Gravity", text: shadowNote, tags: [.crime, .progress]), at: 0)
            }
        }

        // Fame Web F2: Public/social actions (networking, being seen) feed unified fame
        if [.network, .reachOut, .joinClub, .joinActivity].contains(choiceID) {
            state.fame.culturalFame = min(100, state.fame.culturalFame + 2)
        }

        baseResult.notes.append(contentsOf: autonomousNotes)

        // Record momentum so it can influence the next year's simulation
        if !autonomousNotes.isEmpty {
            let strength = min(25, autonomousNotes.count * 8 + 10)
            state.instantMomentum.recordReaction(domain: domain, strength: strength, currentAge: state.player.age)
        }

        // Light history budget
        if state.history.count > 120 {
            state.history = Array(state.history.prefix(120))
        }
    }
}
