import Foundation

// Phase 1 bridge temporarily disabled during active Phase 2 work to avoid name collision
// during development. See IMPLEMENTATION_PLAN.md for the documented steps to restore
// the clean promoted state (add Systems/ file to target, delete this bridge).

// MARK: - Top Level Entities

/// Lightweight pressure nudges so the map moves between Age Ups without a full yearly sim.
enum AmbientPressureSync {
    static func applyNudges(to state: inout GameState) {
        if state.finance.financialStress >= 45 {
            state.consequences.adjustPressure(domain: "finance", delta: 1)
        } else if state.finance.financialStress <= 18, state.finance.cashOnHand >= 8_000 {
            state.consequences.adjustPressure(domain: "finance", delta: -1)
        }

        if state.player.health < 42 {
            state.consequences.adjustPressure(domain: "health", delta: 1)
        } else if state.player.health >= 72, state.healthProfile.activeConditions.isEmpty {
            state.consequences.adjustPressure(domain: "health", delta: -1)
        }

        if state.career.status == .unemployed || state.career.jobSecurity < 38 {
            state.consequences.adjustPressure(domain: "career", delta: 1)
        }

        if state.crime.heat >= 42 {
            state.consequences.adjustPressure(domain: "career", delta: 1)
        }

        let strained = (state.relationships.friends + state.relationships.romanticPartners).filter { $0.status == .strained }.count
        if strained >= 2 || state.relationships.partnerBond < 40 {
            state.consequences.adjustPressure(domain: "relationships", delta: 1)
        }

        if educationPressure(state) {
            state.consequences.adjustPressure(domain: "education", delta: 1)
        }
    }

    private static func educationPressure(_ state: GameState) -> Bool {
        guard state.player.age < 22 else { return false }
        return state.education.stage != .inactive && (state.education.burnoutRisk >= 52 || state.education.attendancePressure >= 52)
    }
}

// MARK: - LifeSimulationOrchestrator

final class LifeSimulationOrchestrator {
    private let eventEngine: EventEngine
    private let originSystem: OriginSystem
    private let narrativeArcSystem: NarrativeArcSystem
    private let traitSystem: TraitSystem
    private let storyletSystem: StoryletSystem
    private var actionSystem: ActionSystem
    private let actionCorrelationSystem: ActionCorrelationSystem
    private let policySystem: PolicySystem
    private let trajectorySystem: TrajectorySystem
    private let educationSystem: EducationSystem
    private let careerSystem: CareerSystem
    private let specialCareerSystem: SpecialCareerSystem
    private let militarySystem: MilitarySystem
    private let crimeSystem: CrimeSystem
    private var financeSystem: FinanceSystem
    private let investmentSystem: InvestmentSystem
    private let relationshipSystem: RelationshipSystem
    private let familySystem: FamilySystem
    private var healthSystem: HealthSystem
    private let housingSystem: HousingSystem
    private let homeOwnershipSystem: HomeOwnershipSystem
    private let progressSystem: ProgressSystem
    private let crossDomainPressureSystem: CrossDomainPressureSystem
    private let worldAutonomySystem: WorldAutonomySystem
    private var npcAutonomySystem: NPCAutonomySystem
    private let continuityThreadEngine: ContinuityThreadEngine
    private let silentYearEngine: SilentYearEngine
    private let yearlyOutcomeAggregator: YearlyOutcomeAggregator
    private let systemRegistry: SystemRegistry
    private let worldSnapshotBuilder: WorldSnapshotBuilder
    private let effectApplier: DomainEffectApplier
    private let domainCacheCoordinator: DomainCacheGenerationCoordinator

    private var instantReactionCoordinator: InstantReactionCoordinator

    #if DEBUG
    private(set) var latestTimingSnapshot: SimulationTimingSnapshot?
    private var currentTimingEntries: [SimulationTimingEntry] = []
    #endif
    private(set) var latestYearSummary: YearlyOutcomeSummary?
    private(set) var latestWorldSnapshot: WorldSnapshot?

    // Phase 1 optimization: Cache last snapshot for faster instant actions
    private var lastInstantSnapshot: WorldSnapshot?

    init(
        eventEngine: EventEngine = EventEngine(),
        originSystem: OriginSystem = OriginSystem(),
        narrativeArcSystem: NarrativeArcSystem = NarrativeArcSystem(),
        traitSystem: TraitSystem = TraitSystem(),
        storyletSystem: StoryletSystem = StoryletSystem(),
        actionSystem: ActionSystem = ActionSystem(
            militarySystem: MilitarySystem()
        ),
        actionCorrelationSystem: ActionCorrelationSystem = ActionCorrelationSystem(),
        policySystem: PolicySystem = PolicySystem(),
        trajectorySystem: TrajectorySystem = TrajectorySystem(),
        educationSystem: EducationSystem = EducationSystem(),
        careerSystem: CareerSystem = CareerSystem(),
        specialCareerSystem: SpecialCareerSystem = SpecialCareerSystem(),
        militarySystem: MilitarySystem = MilitarySystem(),
        crimeSystem: CrimeSystem = CrimeSystem(),
        relationshipSystem: RelationshipSystem = RelationshipSystem(),
        familySystem: FamilySystem = FamilySystem(),
        financeSystem: FinanceSystem = FinanceSystem(),
        investmentSystem: InvestmentSystem = InvestmentSystem(),
        healthSystem: HealthSystem = HealthSystem(),
        housingSystem: HousingSystem = HousingSystem(),
        homeOwnershipSystem: HomeOwnershipSystem = HomeOwnershipSystem(),
        progressSystem: ProgressSystem = ProgressSystem(),
        crossDomainPressureSystem: CrossDomainPressureSystem = CrossDomainPressureSystem(),
        worldAutonomySystem: WorldAutonomySystem = WorldAutonomySystem(),
        npcAutonomySystem: NPCAutonomySystem = NPCAutonomySystem(),
        yearlyOutcomeAggregator: YearlyOutcomeAggregator = YearlyOutcomeAggregator(),
        systemRegistry: SystemRegistry = SystemRegistry(),
        worldSnapshotBuilder: WorldSnapshotBuilder = WorldSnapshotBuilder(),
        effectApplier: DomainEffectApplier = DomainEffectApplier(),
        domainCacheCoordinator: DomainCacheGenerationCoordinator = DomainCacheGenerationCoordinator()
    ) {
        self.eventEngine = eventEngine
        self.originSystem = originSystem
        self.narrativeArcSystem = narrativeArcSystem
        self.traitSystem = traitSystem
        self.storyletSystem = storyletSystem
        self.actionSystem = actionSystem
        self.actionCorrelationSystem = actionCorrelationSystem
        self.policySystem = policySystem
        self.trajectorySystem = trajectorySystem
        self.educationSystem = educationSystem
        self.careerSystem = careerSystem
        self.specialCareerSystem = specialCareerSystem
        self.militarySystem = militarySystem
        self.crimeSystem = crimeSystem
        self.relationshipSystem = relationshipSystem
        self.familySystem = familySystem
        self.financeSystem = financeSystem
        self.investmentSystem = investmentSystem
        self.healthSystem = healthSystem
        self.housingSystem = housingSystem
        self.homeOwnershipSystem = homeOwnershipSystem
        self.progressSystem = progressSystem
        self.crossDomainPressureSystem = crossDomainPressureSystem
        self.worldAutonomySystem = worldAutonomySystem
        self.npcAutonomySystem = npcAutonomySystem
        self.continuityThreadEngine = ContinuityThreadEngine()
        self.silentYearEngine = SilentYearEngine()
        self.yearlyOutcomeAggregator = yearlyOutcomeAggregator
        self.systemRegistry = systemRegistry
        self.worldSnapshotBuilder = worldSnapshotBuilder
        self.effectApplier = effectApplier
        self.domainCacheCoordinator = domainCacheCoordinator
        self.instantReactionCoordinator = InstantReactionCoordinator(
            npcAutonomySystem: npcAutonomySystem,
            healthSystem: healthSystem,
            financeSystem: financeSystem,
            stockMarketSystem: stockMarketSystem
        )
        }

        // Sync systems into ActionSystem for correct routing
        self.actionSystem = ActionSystem(
            educationSystem: educationSystem,
            careerSystem: careerSystem,
            specialCareerSystem: specialCareerSystem,
            militarySystem: militarySystem,
            crimeSystem: crimeSystem,
            familySystem: familySystem,
            financeSystem: financeSystem,
            relationshipSystem: relationshipSystem,
            healthSystem: healthSystem,
            effectApplier: effectApplier
        )

        // (Phase 1 bridge temporarily using simple internal _InstantReactionCoordinator during Phase 2 work.
        // Reassignment skipped — the property default initializer is sufficient for now.)
    }

    func initialize(state: inout GameState) -> GameEvent? {
        state = originSystem.makePreview(mode: .quickStart, templateID: nil, narrativeArcSystem: narrativeArcSystem, meta: MetaState())
        return activatePreview(state: &state)
    }

    func initialEvent(for state: GameState) -> GameEvent? {
        let world = rebuildWorldSnapshot(from: state)
        return eventEngine.pickEvent(for: state, preferredTagWeights: preferredEventWeights(for: world))
    }

    func previewStart(mode: StartMode, templateID: OriginTemplateID?, meta: MetaState, resilience: LifeResilience = .resilient) -> GameState {
        originSystem.makePreview(mode: mode, templateID: templateID, narrativeArcSystem: narrativeArcSystem, meta: meta, resilience: resilience)
    }

    /// Exposes dossier regen for live creation preview updates (trait picks etc) without making the system public.
    func regenerateDossierInPreview(_ preview: inout GameState, templateID: OriginTemplateID, deterministic: Bool) {
        originSystem.regenerateDossier(for: &preview, templateID: templateID, deterministic: deterministic)
    }

    func hydrateRuntimeCaches(for state: GameState) {
        refreshGeneratedCaches(for: state)
    }

    func activatePreview(state: inout GameState) -> GameEvent? {
        guard state.startupState != .active else {
            return initialEvent(for: state)
        }

        state.startupState = .active
        if state.history.isEmpty, let openingSummary = state.openingSummary {
            state.history.insert(
                HistoryEntry(age: state.player.age, title: "Early Years", text: openingSummary, tags: [.progress, .lifeEvent]),
                at: 0
            )
        }
        append(narrativeArcSystem.activatePreview(for: &state), to: &state)
        let world = rebuildWorldSnapshot(from: state)
        append(progressSystem.updateLifePath(input: world.progress, progress: &state.progress), to: &state)
        let refreshedWorld = rebuildWorldSnapshot(from: state)
        append(progressSystem.unlockNewMilestones(input: refreshedWorld.progress, progress: &state.progress), to: &state)
        syncAmbientContacts(in: &state)
        refreshGeneratedCaches(for: state)
        return initialEvent(for: state)
    }

    func advanceYear(state: inout GameState) -> YearAdvanceOutcome {
        guard !state.isGameOver else {
            return beginYearChapter(state: &state)
        }

        syncAmbientContacts(in: &state)

        // Phase 2: Decay instant momentum as time passes (prevents it from lasting forever)
        state.instantMomentum.decay()

        let targetAge = state.player.age + 1
        let plannedActions = forecastActions(for: state)
        var selectionState = state
        selectionState.player.age = targetAge
        let selectionWorld = rebuildWorldSnapshot(from: selectionState)
        let scheduledEvent = consumeDueConsequenceEvent(from: &state, dueBy: targetAge)
        let actionWeights = committedActionWeights(
            from: ActionChoiceCatalog.preferredEventWeights(for: plannedActions),
            plannedActions: plannedActions
        )
        let preferredWeights = preferredEventWeights(
            for: selectionWorld,
            extraTags: state.originProfile?.focusTags ?? [],
            extraWeights: actionWeights
        )
        let event = scheduledEvent?.1 ?? eventEngine.pickEvent(for: selectionState, preferredTagWeights: preferredWeights)
        let stakes = buildTurnStakesSnapshot(
            for: state,
            targetAge: targetAge,
            plannedActions: plannedActions,
            scheduledEvent: scheduledEvent?.0,
            event: event
        )
        let forecast = buildForecastCard(
            for: state,
            targetAge: targetAge,
            plannedActions: plannedActions,
            scheduledEvent: scheduledEvent?.0,
            event: event,
            stakes: stakes
        )
        var chapter = ActiveYearChapter(
            targetAge: targetAge,
            plannedActions: plannedActions,
            forecast: forecast,
            stakes: stakes,
            eventID: event?.id
        )

        let selectedChoice = event?.choices.first
        let outcome = resolvePreparedYearChapter(state: &state, chapter: &chapter, event: event, choice: selectedChoice)
        refreshGeneratedCaches(for: state)

        if state.activeYearChapter != nil {
            return YearAdvanceOutcome(summary: outcome.summary, cards: resumeActiveYearChapterCards(for: state))
        }
        return YearAdvanceOutcome(summary: outcome.summary, cards: outcome.cards)
    }

    func beginYearChapter(state: inout GameState) -> YearAdvanceOutcome {
        guard !state.isGameOver else {
            return YearAdvanceOutcome(
                summary: latestYearSummary,
                cards: [
                    .resolution(
                        ResolutionPreview(
                            id: "resolution-game-over-\(state.player.age)",
                            title: "Life Ended",
                            detail: "This life is already complete. Start a new one to keep playing.",
                            actionTitle: "Back to Feed"
                        )
                    )
                ]
            )
        }

        if state.activeYearChapter != nil {
            return YearAdvanceOutcome(summary: latestYearSummary, cards: resumeActiveYearChapterCards(for: state))
        }

        syncAmbientContacts(in: &state)

        // Phase 2: Decay instant momentum as time passes (prevents it from lasting forever)
        state.instantMomentum.decay()

        let targetAge = state.player.age + 1
        let plannedActions = forecastActions(for: state)
        var selectionState = state
        selectionState.player.age = targetAge
        let selectionWorld = rebuildWorldSnapshot(from: selectionState)
        let scheduledEvent = consumeDueConsequenceEvent(from: &state, dueBy: targetAge)
        let actionWeights = committedActionWeights(
            from: ActionChoiceCatalog.preferredEventWeights(for: plannedActions),
            plannedActions: plannedActions
        )
        let preferredWeights = preferredEventWeights(
            for: selectionWorld,
            extraTags: state.originProfile?.focusTags ?? [],
            extraWeights: actionWeights
        )
        let event = scheduledEvent?.1 ?? eventEngine.pickEvent(for: selectionState, preferredTagWeights: preferredWeights)
        let stakes = buildTurnStakesSnapshot(
            for: state,
            targetAge: targetAge,
            plannedActions: plannedActions,
            scheduledEvent: scheduledEvent?.0,
            event: event
        )
        let forecast = buildForecastCard(
            for: state,
            targetAge: targetAge,
            plannedActions: plannedActions,
            scheduledEvent: scheduledEvent?.0,
            event: event,
            stakes: stakes
        )
        var chapter = ActiveYearChapter(
            targetAge: targetAge,
            plannedActions: plannedActions,
            forecast: forecast,
            stakes: stakes,
            eventID: event?.id
        )

        if let event {
            state.activeYearChapter = chapter
            refreshGeneratedCaches(for: state)
            return YearAdvanceOutcome(summary: nil, cards: [.forecast(forecast), .event(event)])
        }

        let outcome = resolvePreparedYearChapter(state: &state, chapter: &chapter, event: nil, choice: nil)
        refreshGeneratedCaches(for: state)
        if state.activeYearChapter != nil {
            return YearAdvanceOutcome(summary: outcome.summary, cards: resumeActiveYearChapterCards(for: state))
        }
        return YearAdvanceOutcome(summary: outcome.summary, cards: outcome.cards)
    }

    func resolveYearChapter(choice: EventChoice, state: inout GameState) -> YearAdvanceOutcome {
        guard var chapter = state.activeYearChapter else {
            return YearAdvanceOutcome(summary: latestYearSummary, cards: [])
        }
        let event = chapter.eventID.flatMap(eventEngine.event(withID:))
        let outcome = resolvePreparedYearChapter(state: &state, chapter: &chapter, event: event, choice: choice)
        state.activeYearChapter = chapter
        refreshGeneratedCaches(for: state)
        return YearAdvanceOutcome(summary: outcome.summary, cards: resumeActiveYearChapterCards(for: state))
    }

    func resumeActiveYearChapterCards(for state: GameState) -> [InteractionCardPayload] {
        guard let chapter = state.activeYearChapter else { return [] }

        var cards: [InteractionCardPayload] = []

        // Interactive event: only while the player has not yet committed a choice for this chapter.
        if chapter.selectedChoiceText == nil,
           let event = chapter.eventID.flatMap(eventEngine.event(withID:)) {
            cards.append(.event(event))
        }

        // Priority 2: Systemic Crisis
        if let crisis = chapter.pendingCrisis {
            cards.append(.crisis(crisis))
        }

        // Priority 3: Pitch Decks
        if let pitch = chapter.pendingPitchDeck {
            cards.append(.pitchDeck(pitch))
        }

        // Y1: Autonomous / ambient reaction beats play before the year summary (immersive year arc).
        if chapter.currentReactionIndex < chapter.reactionCards.count {
            for reaction in chapter.reactionCards[chapter.currentReactionIndex...] {
                cards.append(.reaction(reaction))
            }
        }

        if let summary = chapter.pendingSummary {
            cards.append(.yearSummary(summary))
        }

        if let consequence = chapter.pendingConsequencePreview {
            cards.append(.consequence(consequence))
        }

        if let resolution = chapter.pendingResolution {
            cards.append(.resolution(resolution))
        }

        return cards
    }

    func syncActiveYearChapterProgress(state: inout GameState, nextCard: InteractionCardPayload?) {
        guard var chapter = state.activeYearChapter else { return }
        guard let nextCard else {
            state.activeYearChapter = nil
            return
        }

        switch nextCard {
        case .forecast(_):
            chapter.phase = .forecast
        case .yearSummary(_):
            chapter.phase = .summary
            chapter.currentReactionIndex = chapter.reactionCards.count
        case .event(_):
            chapter.phase = .event
        case .reaction(let reaction):
            chapter.phase = .reaction
            chapter.currentReactionIndex = chapter.reactionCards.firstIndex(where: { $0.id == reaction.id }) ?? 0
        case .consequence(_):
            chapter.phase = .resolution
            chapter.resolutionCardIndex = 0
        case .resolution(_):
            chapter.phase = .resolution
            chapter.resolutionCardIndex = chapter.pendingConsequencePreview == nil ? 0 : 1
        case .crisis(_):
            chapter.phase = .crisis
        case .pitchDeck(_):
            chapter.phase = .event
        }

        state.activeYearChapter = chapter
    }

    func apply(choice: EventChoice, event: GameEvent, state: inout GameState) {
        effectApplier.applyCoreEffects(choice.effects.core, to: &state.player)

        if let educationEffects = choice.effects.education {
            educationSystem.apply(effect: educationEffects, education: &state.education)
        }

        if let careerEffects = choice.effects.career {
            careerSystem.apply(effect: careerEffects, player: &state.player, career: &state.career, finance: &state.finance)
        }

        if let specialCareerEffects = choice.effects.specialCareer {
            effectApplier.apply(
                result: DomainYearResult(specialCareerEffects: specialCareerEffects),
                to: &state,
                trajectorySystem: trajectorySystem,
                educationSystem: educationSystem,
                careerSystem: careerSystem,
                specialCareerSystem: specialCareerSystem,
                militarySystem: militarySystem,
                crimeSystem: crimeSystem,
                financeSystem: financeSystem,
                relationshipSystem: relationshipSystem,
                healthSystem: healthSystem,
                housingSystem: housingSystem
            )
        }

        if let crimeEffects = choice.effects.crime {
            effectApplier.apply(
                result: DomainYearResult(crimeEffects: crimeEffects),
                to: &state,
                trajectorySystem: trajectorySystem,
                educationSystem: educationSystem,
                careerSystem: careerSystem,
                specialCareerSystem: specialCareerSystem,
                militarySystem: militarySystem,
                crimeSystem: crimeSystem,
                financeSystem: financeSystem,
                relationshipSystem: relationshipSystem,
                healthSystem: healthSystem,
                housingSystem: housingSystem
            )
        }

        if let financeEffects = choice.effects.finance {
            financeSystem.apply(effect: financeEffects, finance: &state.finance, player: &state.player)
        }

        if let relationshipEffects = choice.effects.relationship {
            relationshipSystem.apply(effect: relationshipEffects, to: &state.relationships)
        }

        if let healthEffects = choice.effects.health {
            healthSystem.apply(effect: healthEffects, player: &state.player, health: &state.healthProfile)
        }

        if let housingEffects = choice.effects.housing {
            housingSystem.apply(effect: housingEffects, housing: &state.housing)
        }

        if let assetEffects = choice.effects.assets {
            effectApplier.applyAssetEffects(assetEffects, to: &state.assets)
        }

        if let consequenceEffects = choice.effects.consequence {
            applyConsequenceEffects(consequenceEffects, event: event, choice: choice, to: &state)
        } else if let firstFollowUpID = event.followUpEventIDs.first {
            state.consequences.scheduledEvents.append(
                ScheduledConsequenceEvent(
                    eventID: firstFollowUpID,
                    dueAge: state.player.age + 1,
                    title: event.title,
                    detail: "Last year's choice in \(event.title) is still unfolding.",
                    sourceEventID: event.id,
                    sourceEventTitle: event.title,
                    sourceChoiceText: choice.text,
                    callbackFramingText: "What you decided in \(event.title) is still echoing into the next year."
                )
            )
        }

        traitSystem.applyEventOutcomeInfluence(for: event, player: &state.player, finance: &state.finance)
        updateRelationshipMilestones(in: &state.relationships)
        let worldAfterChoice = rebuildWorldSnapshot(from: state)
        append(progressSystem.updateLifePath(input: worldAfterChoice.progress, progress: &state.progress), to: &state)

        state.lastEventYearById[event.id] = state.player.age
        state.player.clampStats()
        state.career.clamp()
        state.specialCareer.clamp()
        state.crime.clamp()
        state.isGameOver = state.player.health <= 0 || state.healthProfile.physicalWellness <= 0

        state.history.insert(
            HistoryEntry(
                age: state.player.age,
                title: event.title,
                text: "\(event.text)\n\nYou chose: \(choice.text)",
                tags: historyTags(for: event.category)
            ),
            at: 0
        )
        enforceHistoryBudget(on: &state)

        if state.isGameOver {
            let finalWorld = rebuildWorldSnapshot(from: state)
            append(progressSystem.finalizeLifePath(input: finalWorld.progress, progress: &state.progress), to: &state)
            state.history.insert(
                HistoryEntry(age: state.player.age, title: "Life Ended", text: "The consequences of that year were too much for your body to absorb.", tags: [.health, .progress]),
                at: 0
            )
            enforceHistoryBudget(on: &state)
        }

        let progressWorld = rebuildWorldSnapshot(from: state)
        append(progressSystem.unlockNewMilestones(input: progressWorld.progress, progress: &state.progress), to: &state)
        syncAmbientContacts(in: &state)
        refreshGeneratedCaches(for: state)
    }

    func roleTitle(for career: CareerState) -> String {
        careerSystem.roleTitle(for: career)
    }

    // =========================================================================
    // INSTANT / FRICTIONLESS MICRO-MOVE PATH (Phase 1 Orchestrator Cleanup – COMPLETE)
    // =========================================================================
    //
    // "Player Micro Move" vs "Year Commitment" – the central mental model.
    //
    // These methods implement the fast, responsive, "I did something and the world
    // answered immediately" layer. They are deliberately thin, cache-aware, and
    // delegate reaction logic to InstantReactionCoordinator.
    //
    // See the long comment block inside resolvePreparedYearChapter for the full
    // boundary documentation and why the two paths must stay architecturally distinct.
    //
    // Design goals (Phase 1):
    // - Zero unnecessary rebuildWorldSnapshot calls between chained quick actions
    // - previewInstantAction is a pure function (reads cache, never writes)
    // - refreshGeneratedCaches (disk artifact work) is excluded from the instant path
    // - Coordinator is the single home for autonomous reaction dispatch + momentum
    //
    // Related file: Simulation/Systems/InstantReactionCoordinator.swift

    func applyImmediateAction(_ choiceID: ActionChoiceID, domain: ActionDomain, state: inout GameState, refreshCaches: Bool = true) -> DomainYearResult {
        let action = PlayerYearAction(domain: domain, choiceID: choiceID)

        // Phase 1 (Orchestrator Cleanup): Snapshot caching for the instant path
        // Goal: Avoid repeated expensive rebuildWorldSnapshot calls during quick actions.
        let world: WorldSnapshot
        if let cached = lastInstantSnapshot, !refreshCaches {
            world = cached
        } else {
            world = rebuildWorldSnapshot(from: state)
            lastInstantSnapshot = world
        }

        let result = actionSystem.apply(actions: [action], state: &state, world: world, clearsPendingActions: false)
        state.actionMemory.record(action: action, age: state.player.age)
        let pressureDeltas = applyActionDrivenConsequenceAdjustments([action], to: &state.consequences)
        actionCorrelationSystem.record(action: action, age: state.player.age, pressureDeltas: pressureDeltas, state: &state)

        for note in result.notes {
            state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags.isEmpty ? [.progress] : note.tags), at: 0)
        }
        enforceHistoryBudget(on: &state)

        if refreshCaches {
            // Only heavy paths (yearly resolution entry points) request full cache refresh.
            // The frictionless instant path deliberately skips this for responsiveness.
            refreshGeneratedCaches(for: state, snapshot: lastInstantSnapshot)
            lastInstantSnapshot = nil // Invalidate only after explicit heavy work
        }

        return result
    }

    /// Frictionless / Instant path (the "press button → world reacts now" experience).
    ///
    /// Phase 1 (Orchestrator Cleanup): This method is intentionally thin.
    /// - Base action + snapshot caching happens in applyImmediateAction.
    /// - Reaction enrichment + momentum is fully delegated to the coordinator.
    /// - We avoid heavy cache work unless necessary.
    func applyInstantActionWithAutonomousReaction(_ choiceID: ActionChoiceID, domain: ActionDomain, state: inout GameState) -> DomainYearResult {
        // Use the lightest possible path for the base action
        var baseResult = applyImmediateAction(choiceID, domain: domain, state: &state, refreshCaches: false)

        // All reaction logic, history injection, and momentum recording lives in the coordinator
        instantReactionCoordinator.enrichWithAutonomousReactions(
            choiceID: choiceID,
            domain: domain,
            baseResult: &baseResult,
            state: &state
        )

        // Phase 1 (thinner instant path): Do NOT call refreshGeneratedCaches here.
        // The DomainCacheGenerationCoordinator work (disk artifacts + event hints) is heavyweight
        // and only needed before yearly resolution. Leaving lastInstantSnapshot warm allows
        // rapid chaining of multiple quick actions with zero snapshot rebuilds between them.
        // The ViewModel calls refreshDerivedState() after each action for UI concerns.
        //
        // Snapshot is only cleared on explicit heavy paths (see applyImmediateAction + refreshCaches:true
        // and the yearly chapter resolution methods).

        return baseResult
    }

    /// Pure preview for frictionless UI: instantly computes what an instant action would do
    /// without committing the full side effects. Perfect for tap previews, tooltips, or optimistic UI.
    ///
    /// Phase 1 (snapshot hygiene): This is a *pure query*. It may read the warm lastInstantSnapshot
    /// for speed but **never mutates** it. Previews must not pollute the cache used by real instant actions.
    func previewInstantAction(_ choiceID: ActionChoiceID, domain: ActionDomain, state: GameState) -> [String] {
        var previewState = state

        // Read-only use of the warm cache when present. Never write to lastInstantSnapshot.
        // If no cache, build a transient snapshot that is discarded after the preview.
        let world: WorldSnapshot
        if let cached = lastInstantSnapshot {
            world = cached
        } else {
            world = rebuildWorldSnapshot(from: previewState)
            // semantics owned exclusively by the mutating instant action paths.
        }

        let result = actionSystem.apply(actions: [PlayerYearAction(domain: domain, choiceID: choiceID)], state: &previewState, world: world, clearsPendingActions: false)

        return result.notes.map { "\($0.title): \($0.text)" }
    }

    func previewAction(_ choiceID: ActionChoiceID, state: GameState) -> DomainYearResult {
        var previewState = state
        return actionSystem.apply(
            actions: [PlayerYearAction(domain: choiceID.domain, choiceID: choiceID)],
            state: &previewState,
            clearsPendingActions: false
        )
    }

    func completeLife(state: GameState, meta: inout MetaState) {
        progressSystem.harvestLegacy(from: state, meta: &meta)
    }

    func inheritLegacy(child: ChildRecord, parentState: GameState) -> GameState {
        var newState = GameState()
        let lifeSummary = LifeSummarySystem().build(from: parentState)

        // 1. Core Identity
        newState.player.name = child.name
        newState.player.age = child.age

        // Map temperament to traits
        let traitSystem = TraitSystem()
        let preferredTraits: [PersonalityTrait]
        switch child.temperament {
        case .easygoing: preferredTraits = [.charismatic]
        case .spirited: preferredTraits = [.disciplined]
        case .intense: preferredTraits = [.anxious]
        case .independent: preferredTraits = [.disciplined]
        case .sensitive: preferredTraits = [.anxious]
        }
        newState.player.traits = traitSystem.generateInitialTraits(count: 3, preferredTraits: preferredTraits)

        // 2. Financial Inheritance (50% of total wealth)
        let totalLegacyWealth = parentState.finance.totalWealth
        let inheritanceAmount = totalLegacyWealth / 2
        newState.finance.cashOnHand = 5000 + inheritanceAmount // Base + inheritance

        // 3. Property Inheritance
        if let parentHome = parentState.assets.primaryResidence {
            var inheritedHome = parentHome
            inheritedHome.mortgagePrincipal = 0 // Assume it's passed down free and clear or sold/settled
            newState.assets.primaryResidence = inheritedHome
            newState.housing.livingArrangement = .ownerOccupied
        }

        // 4. Social Inheritance
        newState.relationships.socialCapital = parentState.relationships.socialCapital / 3
        newState.relationships.publicReputation = (50 + parentState.relationships.publicReputation) / 2
        newState.fame.culturalFame = parentState.fame.culturalFame / 5
        newState.fame.notoriety = parentState.fame.notoriety / 4

        // 5. Narrative Start
        newState.inheritedLegacy = LegacyInheritanceSnapshot(
            parentName: parentState.player.name,
            childName: child.name,
            childAge: child.age,
            inheritedCash: inheritanceAmount,
            inheritedProperty: newState.assets.primaryResidence,
            inheritedReputation: newState.relationships.publicReputation,
            parentDeathAge: parentState.player.age,
            parentLegacyHeadline: lifeSummary.headline
        )
        newState.openingSummary = "\(lifeSummary.headline). You buried \(parentState.player.name) and inherited $\(inheritanceAmount), along with the parts of their name that money cannot settle."
        newState.startupState = .active

        newState.history.append(HistoryEntry(
            age: child.age,
            title: "Heritage",
            text: "You begin as \(parentState.player.name)'s successor. \(lifeSummary.reputationLine)",
            tags: [.lifeEvent, .progress]
        ))

        return newState
    }

    private func resolvePreparedYearChapter(
        state: inout GameState,
        chapter: inout ActiveYearChapter,
        event: GameEvent?,
        choice: EventChoice?
    ) -> YearAdvanceOutcome {
        #if DEBUG
        var snapshot = SimulationTimingSnapshot()
        currentTimingEntries = []
        let overallStart = CFAbsoluteTimeGetCurrent()
        #endif
        let startingState = state
        var yearResults: [DomainYearResult] = []
        let plannedActions = chapter.plannedActions
        let actionsToApply = state.pendingActions
        let plannedFinanceAction = plannedActions.first(where: { $0.domain == .finance })?.choiceID

        // =====================================================================
        // YEAR COMMITMENT SIMULATION (Heavy Yearly Tick)
        // Popup buttons (event choices, "Continue" on summaries/resolutions) that trigger
        // this path now set isResolvingInteraction + use Task.yield before calling into here
        // (see ContentView choose/dismiss etc). This makes the popup show "processing" UI
        // immediately instead of appearing frozen while the heavy work (rebuilds, 15+ systems,
        // refreshDerived, save) runs on main.
        // =====================================================================
        //
        // MENTAL MODEL BOUNDARY – READ THIS WHEN MODIFYING:
        //
        // There are two distinct execution speeds in OneLife:
        //
        // 1. INSTANT / MICRO MOVE PATH (frictionless, player agency in the moment)
        //    - applyImmediateAction (with refreshCaches: false)
        //    - applyInstantActionWithAutonomousReaction (thin delegator)
        //    - previewInstantAction (pure, never mutates orchestrator caches)
        //    - InstantReactionCoordinator.enrichWithAutonomousReactions
        //    - Uses warm lastInstantSnapshot aggressively; deliberately skips
        //      refreshGeneratedCaches and most heavy work.
        //    - Goal: "I pressed the button and the world reacted *now*."
        //
        // 2. YEAR COMMITMENT PATH (serious simulation, consequences compound)
        //    - beginYearChapter / resolveYearChapter / resolvePreparedYearChapter
        //    - This method + the 20+ system.advanceYear calls below.
        //    - Rebuilds WorldSnapshot *frequently* because each system mutates
        //      GameState and later systems need a fresh view of the world.
        //    - Runs the full DomainCacheGenerationCoordinator, event engines,
        //      cross-domain pressure, narrative arcs, etc.
        //    - Goal: "This year of my life actually mattered."
        //
        // The instant path must NEVER grow to resemble this method.
        // The yearly path must never become the only way the player feels agency.
        //
        // Recent Phase 1 work (snapshot caching, coordinator extraction, cache
        // refresh removal from instant, preview purity) exists to keep these two
        // modes feeling like one cohesive game while preserving their different
        // performance and narrative contracts.
        //
        // When adding new systems (especially Family in Phase 2), decide early:
        // Does this need instant reaction hooks? → Add to coordinator + cheap reactor.
        // Is it purely a yearly evolution? → Keep it here.
        // =====================================================================

        state.syncResilienceToPlayer()
        state.player.age = chapter.targetAge
        if let event, let choice {
            apply(choice: choice, event: event, state: &state)
            chapter.selectedChoiceText = choice.text
        }

        // Phase 2: Apply mechanical benefits from recent instant momentum at the start of the year
        applyInstantMomentumBenefits(to: &state)

        policySystem.ensureDefaultPolicy(finance: &state.finance)
        state.consequences.softenAllPressure(by: 1)
        for action in actionsToApply {
            let pressureDeltas = applyActionDrivenConsequenceAdjustments([action], to: &state.consequences)
            actionCorrelationSystem.record(action: action, age: state.player.age, pressureDeltas: pressureDeltas, state: &state)
        }
        var world = rebuildWorldSnapshot(from: state)

        if !actionsToApply.isEmpty {
            let result = measure("Actions") {
                actionSystem.apply(actions: actionsToApply, state: &state, world: world)
            }
            record(result, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if plannedActions.contains(where: { $0.choiceID == .pitchDeck }) {
            chapter.pendingPitchDeck = buildPitchDeckInteraction(for: state)
        }

        if systemRegistry.isActive(.traits, in: world) {
            let result = measure("Traits") {
                traitSystem.applyYearlyInfluence(to: &state.player, finance: &state.finance)
            }
            record(result, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.trajectory, in: world) {
            let result = measure("Trajectory") {
                trajectorySystem.advanceYear(input: world.trajectory, trajectory: &state.trajectory)
            }
            record(result, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.education, in: world) {
            let result = measure("Education") {
                educationSystem.advanceYear(input: world.education, player: &state.player, education: &state.education, military: &state.military, career: &state.career)
            }
            record(result, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.career, in: world) {
            let careerResult = measure("Career") {
                careerSystem.advanceYear(input: world.career, player: &state.player, career: &state.career)
            }
            record(careerResult, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)

            if systemRegistry.isActive(.specialCareer, in: world) {
                let specialCareerResult = measure("Special Career") {
                    specialCareerSystem.advanceYear(input: world.specialCareer, player: &state.player, career: &state.career, specialCareer: &state.specialCareer)
                }
                apply(result: specialCareerResult, to: &state)
                record(specialCareerResult, in: &state, results: &yearResults)
            }

            // Assets3: WorldEra reactivity on luxury and signature assets (maintenance pain, value swing, prestige)
            // Temporarily stubbed for build stability — full implementation can be restored.
            // applyEraLuxuryAssetEffects(to: &state)
        }

        if systemRegistry.isActive(.military, in: world) {
            let militaryResult = measure("Military") {
                militarySystem.advanceYear(input: MilitaryDomainSnapshot(player: state.player, military: state.military, career: state.career, education: state.education, worldEra: state.currentEra), player: &state.player, military: &state.military, career: &state.career)
            }
            record(militaryResult, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }

        if systemRegistry.isActive(.crime, in: world) {
            let crimeResult = measure("Crime") {
                crimeSystem.advanceYear(input: world.crime, player: &state.player, career: &state.career, crime: &state.crime)
            }
            apply(result: crimeResult, to: &state)
            record(crimeResult, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.housing, in: world) {
            let result = measure("Housing") {
                housingSystem.advanceYear(input: world.housing, housing: &state.housing)
            }
            record(result, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.relationships, in: world) {
            let result = measure("Relationships") {
                relationshipSystem.advanceYear(input: world.relationships, relationships: &state.relationships)
            }
            record(result, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.family, in: world) {
            let result = measure("Family") {
                familySystem.advanceYear(input: world.family, family: &state.family)
            }
            record(result, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.finance, in: world) {
            let financeResult = measure("Finance") {
                financeSystem.advanceYear(input: world.finance, finance: &state.finance)
            }
            apply(result: financeResult, to: &state)
            record(financeResult, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)

            // P4-4: Era/economy reward tuning side pass (reinforces bidirectional from Econ1; cheap, visible).
            // Different eras now more clearly change the "feel" of money outcomes for both regular and special paths.
            if state.currentEra == .recession && state.finance.lastYearBalanceDelta < 0 {
                state.finance.financialStress = min(100, state.finance.financialStress + 2)
                // no new note here (finance already emits); just pressure accent
            } else if (state.currentEra == .bullMarket || state.currentEra == .techBoom) && state.finance.lastYearBalanceDelta > 2000 {
                if Int.random(in: 0...100) < 12 {
                    // occasional extra note for boom reward feel
                    record(DomainYearResult(notes: [DomainNote(title: "Boom Tailwind", text: "The rising tide lifted more boats than usual this year. Your timing caught some of it.", tags: [.finance])]), in: &state, results: &yearResults)
                }
            }
        }

        if systemRegistry.isActive(.investments, in: world) {
            let investmentResult = measure("Investments") {
                investmentSystem.advanceYear(input: world.investments, plannedAction: plannedFinanceAction, finance: &state.finance)
            }
            record(investmentResult, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.assets, in: world) {
            let result = measure("Home Ownership") {
                homeOwnershipSystem.advanceYear(input: world.assets, plannedAction: plannedFinanceAction, finance: &state.finance, assets: &state.assets, housing: &state.housing)
            }
            record(result, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.health, in: world) {
            let result = measure("Health") {
                healthSystem.advanceYear(input: world.health, player: &state.player, health: &state.healthProfile)
            }
            record(result, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }

        // P4-1: Safety nets — prevent one-bad-year death spirals for health/cash so players keep agency and can fight back or recover.
        // Low overhead (simple clamps + 1-2 notes + cheap ledger pulse). Modulated lightly by resilience (grounded gets a bit more "mercy/fight" recovery volume).
        // Also telegraphs risk when curves are dangerous (high age + low health + high stress + variance paths).
        if systemRegistry.isActive(.health, in: world) || systemRegistry.isActive(.finance, in: world) {
            let safetyNotes = applyP4SafetyNets(to: &state)
            if !safetyNotes.isEmpty {
                record(DomainYearResult(notes: safetyNotes), in: &state, results: &yearResults)
                world = rebuildWorldSnapshot(from: state)
            }
        }

        if systemRegistry.isActive(.progress, in: world) {
            let lifePathResult = measure("Life Path") {
                progressSystem.updateLifePath(input: world.progress, progress: &state.progress)
            }
            record(lifePathResult, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
            let milestoneResult = measure("Milestones") {
                progressSystem.unlockNewMilestones(input: world.progress, progress: &state.progress)
            }
            record(milestoneResult, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.world, in: world) {
            let result = measure("World Autonomy") {
                worldAutonomySystem.advanceYear(state: &state)
            }
            record(result, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.npcAutonomy, in: world) {
            let result = measure("NPC Autonomy") {
                DomainYearResult(events: npcAutonomySystem.advanceYear(state: &state))
            }
            if !result.events.isEmpty {
                record(result, in: &state, results: &yearResults)
                world = rebuildWorldSnapshot(from: state)
            }
        }

        let narrativeResult = measure("Narrative Arcs") {
            narrativeArcSystem.evaluateYear(before: startingState, after: &state)
        }
        record(narrativeResult, in: &state, results: &yearResults)
        world = rebuildWorldSnapshot(from: state)

        // Continuity Thread (Codex IX) — age 18 beat, age 20 lookback, first job callback
        let continuityResult = continuityThreadEngine.evaluate(before: startingState, after: &state)
        record(continuityResult, in: &state, results: &yearResults)
        world = rebuildWorldSnapshot(from: state)

        // Silent Year (Codex IX, Layer 3) — when no event fired, give the year texture
        if event == nil, let silentEntry = silentYearEngine.silentYearEntry(for: state) {
            state.history.insert(silentEntry, at: 0)
        }

        let financeSpillover = crossDomainPressureSystem.financeSpillover(for: world)
        apply(result: financeSpillover, to: &state)
        record(financeSpillover, in: &state, results: &yearResults)
        world = rebuildWorldSnapshot(from: state)

        let healthSpillover = crossDomainPressureSystem.healthSpillover(for: world)
        apply(result: healthSpillover, to: &state)
        record(healthSpillover, in: &state, results: &yearResults)
        world = rebuildWorldSnapshot(from: state)

        let housingSpillover = crossDomainPressureSystem.housingSpillover(for: world)
        apply(result: housingSpillover, to: &state)
        record(housingSpillover, in: &state, results: &yearResults)
        world = rebuildWorldSnapshot(from: state)

        // Fighting Back Bonus — rewards consistent stabilizing effort under pressure.
        // Big for replayability: players feel their small good choices actually matter.
        let fightingBack = applyFightingBackRecoveryBonus(to: &state)
        if !fightingBack.isEmpty {
            record(DomainYearResult(notes: fightingBack), in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }

        let checkpointResult = crossDomainPressureSystem.ageCheckpoint(for: world)
        record(checkpointResult, in: &state, results: &yearResults)
        world = rebuildWorldSnapshot(from: state)

        state.player.clampStats()
        state.specialCareer.clamp()
        state.fame.clamp()
        state.pendingActions = []
        state.activities.rolloverIfNeeded(to: state.player.age)
        syncAmbientContacts(in: &state)

        // Fame Web F1: Connect every avenue that can make you known.
        // Runs after special career, military, assets, relationships, and world autonomy have all contributed.
        propagateFameForYear(to: &state)

        // Engine1: Decay old correlation signals (very cheap operation)
        state.correlationLedger.decay(oldAge: state.player.age)

        // Engine4: Resolve correlation echoes (high-intensity periods create delayed consequences)
        let pendingEchoes = state.correlationLedger.pendingEchoes(currentAge: state.player.age)
        for echo in pendingEchoes {
            if echo.tag == "intense_stretch_echo" {
                let note = echo.strength >= 80
                    ? "The intensity of the last few years is finally catching up. You feel it in your body and your relationships."
                    : "The long stretch of focused action is still reverberating. Some doors that were open before feel harder to reach now."

                state.history.insert(HistoryEntry(age: state.player.age, title: "Echo", text: note, tags: [.progress]), at: 0)

                if echo.domain == "relationships" || echo.domain == "finance" {
                    state.relationships.activeRumorHeat = min(100, state.relationships.activeRumorHeat + 8)
                }
            }
            state.correlationLedger.consumeEcho(echo)
        }

        // Engine4: Long-term reflection on lives that had extremely high correlation periods
        if state.correlationLedger.recentActivityLevel >= 80 && state.player.age >= 45 && !state.history.prefix(4).contains(where: { $0.title.contains("Burned") || $0.title.contains("Intensity") }) {
            let reflection = "There was a stretch, years ago, where everything felt accelerated. Looking back, it was both the most alive and the most expensive period of your life."
            state.history.insert(HistoryEntry(age: state.player.age, title: "Burned Bright", text: reflection, tags: [.progress]), at: 0)
        }

        // Phase 2: Clear momentum after it has influenced this year's simulation
        state.instantMomentum.clear()

        let wealthFloor = state.resilience.scaling.wealthGameOverFloor
        state.isGameOver = state.player.health <= 0 || state.healthProfile.physicalWellness <= 0 || state.finance.totalWealth < wealthFloor
        updateYearlyStanceMemory(before: startingState, after: &state)

        latestYearSummary = yearlyOutcomeAggregator.summarize(
            before: startingState,
            after: state,
            results: yearResults,
            plannedActions: plannedActions
        )
        state.actionMemory.clearForNewAge(state.player.age)
        state.yearlyStance.selectedStance = nil

        // Push summary into History Log (BitLife style)
        if let summary = latestYearSummary {
            if let stanceOutcome = summary.yearlyStanceOutcome {
                state.history.insert(HistoryEntry(age: state.player.age, title: stanceOutcome.title, text: stanceOutcome.detail, tags: [stanceOutcome.domain]), at: 0)
            }
            for item in summary.headlines {
                state.history.insert(HistoryEntry(age: state.player.age, title: item.title, text: item.detail, tags: [item.domain]), at: 0)
            }
            for item in summary.spillovers {
                state.history.insert(HistoryEntry(age: state.player.age, title: item.title, text: item.detail, tags: [item.domain]), at: 0)
            }
        }

        if state.isGameOver {
            let finalizeWorld = rebuildWorldSnapshot(from: state)
            let finalizeResult = progressSystem.finalizeLifePath(input: finalizeWorld.progress, progress: &state.progress)
            record(finalizeResult, in: &state, results: &yearResults)

            // P5-1: Edge-aware "Life Ended" text (long lives, wealth floor, high notoriety, health, zero kids flavor)
            let endText: String
            let causeHealth = state.player.health <= 0 || state.healthProfile.physicalWellness <= 0
            let causeWealth = state.finance.totalWealth < state.resilience.scaling.wealthGameOverFloor
            let highNotoriety = state.fame.notoriety >= 70 || state.crime.heat >= 70
            let longLife = state.player.age >= 78
            let noKids = state.family.children.isEmpty

            if causeWealth && highNotoriety {
                endText = "The money ran out and the heat finally caught up. The life you built in the shadows left nothing to fall back on."
            } else if causeWealth {
                endText = "The accounts finally hit zero. There was no more room to maneuver."
            } else if highNotoriety && causeHealth {
                endText = "The body gave out under the weight of everything you carried — and everything that was chasing you."
            } else if highNotoriety {
                endText = "The notoriety that made you powerful also made the end inevitable. No quiet retirement for this life."
            } else if longLife && noKids {
                endText = "A long life, lived to the end. The line stops here with you."
            } else if longLife {
                endText = "You made it further than most. The years were many, and they took their toll in the end."
            } else if causeHealth {
                endText = "The consequences of that year were too much for your body to absorb."
            } else {
                endText = "The life you lived finally asked for more than you had left to give."
            }

            state.history.insert(
                HistoryEntry(age: state.player.age, title: "Life Ended", text: endText, tags: [.health, .progress]),
                at: 0
            )
            enforceHistoryBudget(on: &state)
        }

        let dominantConsequence = buildConsequencePreview(for: state, summary: latestYearSummary)
        let reactions = buildReactionCards(
            before: startingState,
            after: state,
            event: event,
            choice: choice,
            summary: latestYearSummary,
            scheduledConsequencePreview: dominantConsequence,
            stakes: chapter.stakes
        )

        chapter.reactionCards = reactions
        chapter.currentReactionIndex = 0

        chapter.pendingSummary = latestYearSummary
        chapter.pendingConsequencePreview = dominantConsequence
        chapter.pendingResolution = buildResolutionPreview(
            for: state,
            dominantConsequence: dominantConsequence,
            summary: latestYearSummary
        )

        state.activeYearChapter = chapter
        let cards = resumeActiveYearChapterCards(for: state)
        if cards.isEmpty {
            state.activeYearChapter = nil
        }

        #if DEBUG
        snapshot.totalAdvanceYearMilliseconds = millisecondsSince(overallStart)
        snapshot.entries = currentTimingEntries
        snapshot.persistedHistoryCount = state.history.count
        latestTimingSnapshot = snapshot
        #endif
        refreshGeneratedCaches(for: state)
        return YearAdvanceOutcome(summary: latestYearSummary, cards: cards)
    }

    private func updateYearlyStanceMemory(before: GameState, after state: inout GameState) {
        guard let stance = before.yearlyStance.selectedStance else {
            state.yearlyStance.lastOutcomeLine = nil
            return
        }

        let repeated = before.yearlyStance.lastCompletedStance == stance
        state.yearlyStance.lastCompletedStance = stance
        state.yearlyStance.repeatCount = repeated ? before.yearlyStance.repeatCount + 1 : 1

        // P4-6: Long-run variance dampener — very long lives (80+) or extreme repeat counts don't snowball into unplayable states.
        // Reuses capped recentStances (4); here we just soften repeatCount strength and rut flags for longevity.
        if state.player.age >= 75 && state.yearlyStance.repeatCount > 2 {
            state.yearlyStance.repeatCount = min(state.yearlyStance.repeatCount, 3) // cap visible rut for very old characters
        }

        var line = yearlyStanceOutcomeLine(stance: stance, before: before, after: state, repeatCount: state.yearlyStance.repeatCount)
        if let voice = stanceSpecialVoice(stance: stance, state: state) {
            line += voice
        }
        state.yearlyStance.lastOutcomeLine = line

        // D4: residue + focus echo tracking (capped recent list for ruts, autonomy, silent/continuity, life shape)
        var recent = state.yearlyStance.recentStances
        recent.insert(stance, at: 0)
        if recent.count > 4 { recent = Array(recent.prefix(4)) }
        state.yearlyStance.recentStances = recent

        // Publish cheap signal so autonomy, silent, continuity, echoes can react (low overhead bus)
        let strength = 18 + min(12, state.yearlyStance.repeatCount * 4)
        state.correlationLedger.publish(CorrelationSignal(kind: .focusStance, domain: stance.domain?.rawValue, strength: strength, age: state.player.age))

        // D4: focus scars / residue flags for legacy, reflections, adult child notes (e.g. repeated drift leaves "looseness")
        if stance == .letYearDrift && state.yearlyStance.repeatCount >= 2 {
            state.consequences.narrativeFlags["focus_drift_repeated", default: 0] = state.player.age
        }
        if repeated && state.yearlyStance.repeatCount >= 3 {
            let key = "focus_rut_\(stance.rawValue)"
            state.consequences.narrativeFlags[key, default: 0] = state.player.age
        }
    }

    private func yearlyStanceOutcomeLine(stance: YearlyStanceID, before: GameState, after: GameState, repeatCount: Int) -> String {
        let repeatTail = repeatCount >= 2 ? " Pattern repeated \(repeatCount)x." : ""
        let feelTail = after.resilience == .grounded ? " (Grounded weight)" : ""
        // D4: residue tail from recent stances (focus history echo)
        let recent = after.yearlyStance.recentStances
        let residueTail = recent.count >= 2 ? " The shape of recent years is still with you." : ""
        switch stance {
        case .stabilizeMoney:
            let cashDelta = after.finance.cashOnHand - before.finance.cashOnHand
            let stressDelta = after.finance.financialStress - before.finance.financialStress
            return cashDelta >= 0 || stressDelta <= 0
                ? "Money stance helped contain the year.\(repeatTail)\(feelTail)\(residueTail)"
                : "Money stance delayed pressure more than it solved it.\(repeatTail)\(feelTail)\(residueTail)"
        case .protectHealth:
            let mentalDelta = after.healthProfile.mentalWellness - before.healthProfile.mentalWellness
            return mentalDelta >= 0
                ? "Health stance made the year more survivable.\(repeatTail)\(feelTail)\(residueTail)"
                : "Health stance could not fully offset the load.\(repeatTail)\(feelTail)\(residueTail)"
        case .repairPeople:
            let beforeBond = max(before.relationships.friends.strongestBond, before.relationships.partnerBond)
            let afterBond = max(after.relationships.friends.strongestBond, after.relationships.partnerBond)
            return afterBond >= beforeBond
                ? "People stance kept support alive.\(repeatTail)\(residueTail)"
                : "People stance did not stop distance from building.\(repeatTail)\(residueTail)"
        case .pushCareer:
            return after.career.performance >= before.career.performance
                ? "Career stance converted effort into traction.\(repeatTail)\(residueTail)"
                : "Career stance raised the cost without a clean payoff.\(repeatTail)\(residueTail)"
        case .soldierStance:
            return "Military duty shaped the entire year.\(repeatTail)\(residueTail)"
        case .studentStance:
            return "Academic focus was the baseline for everything.\(repeatTail)\(residueTail)"
        case .letYearDrift:
            return "Drift left outside pressure with more say than intent.\(repeatTail)\(residueTail)"
        }
    }

    // D4 helper: special career voice flavor for stance outcomes (cross-domain immersion)
    private func stanceSpecialVoice(stance: YearlyStanceID, state: GameState) -> String? {
        guard state.specialCareer.track != .inactive else { return nil }
        switch (state.specialCareer.track, stance) {
        case (.athlete, .protectHealth):
            return " The body that got you here demanded the same discipline off the field."
        case (.founder, .pushCareer):
            return " You ran the year like a board meeting — vision first, details later."
        case (.contentCreator, .pushCareer):
            return " The feed didn't pause; your focus just became content."
        case (.politics, .repairPeople):
            return " The rooms you chose to be in are starting to remember your name."
        case (.crime, .stabilizeMoney), (.shadowOperative, .stabilizeMoney):
            return " Clean numbers are the best camouflage."
        default:
            return nil
        }
    }

    private func buildPitchDeckInteraction(for state: GameState) -> PitchDeckInteraction {
        PitchDeckInteraction(
            id: "pitch-deck-\(state.player.age)",
            title: "Choose Your Industry",
            detail: "You are standing before a room of investors. What story are you telling?",
            choices: [
                PitchDeckChoice(id: "pd-semi", text: "Semiconductors", detail: "High capital, high burn, massive long-term upside.", sector: .semiconductors),
                PitchDeckChoice(id: "pd-rest", text: "Restaurant Group", detail: "Low entry cost, high burnout, quick cash flow.", sector: .restaurants),
                PitchDeckChoice(id: "pd-auto", text: "Automotive", detail: "High prestige, high debt, massive scale.", sector: .automobiles),
                PitchDeckChoice(id: "pd-game", text: "Gaming Studio", detail: "High volatility, high traction potential, low burn.", sector: .gaming)
            ]
        )
    }

    private func applyInstantMomentumBenefits(to state: inout GameState) {
        let momentum = state.instantMomentum
        guard momentum.overallStrength >= 25 else { return }

        let strength = momentum.overallStrength
        let dampener = max(1, strength / 22)   // Phase 3: stronger carry-over

        // Health domain momentum
        if momentum.healthMomentum >= 22 {
            state.healthProfile.mentalWellness = min(100, state.healthProfile.mentalWellness + (strength / 9))
            state.healthProfile.physicalWellness = min(100, state.healthProfile.physicalWellness + (strength / 14))
            // Reduce health-related pressure
            if let current = state.consequences.pressureByDomain["health"] {
                state.consequences.pressureByDomain["health"] = max(0, current - dampener)
            }
        }

        // Finance domain momentum
        if momentum.financeMomentum >= 22 {
            state.finance.financialStress = max(0, state.finance.financialStress - (strength / 7))
            if let current = state.consequences.pressureByDomain["finance"] {
                state.consequences.pressureByDomain["finance"] = max(0, current - dampener)
            }
        }

        // Relationships domain momentum
        if momentum.relationshipMomentum >= 22 {
            if let index = state.relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
                state.relationships.romanticPartners[index].bond = min(100, state.relationships.romanticPartners[index].bond + (strength / 12))
            }
            if let current = state.consequences.pressureByDomain["relationships"] {
                state.consequences.pressureByDomain["relationships"] = max(0, current - (dampener + 1))
            }
        }

        // Phase 3: High momentum meaningfully reduces cross-domain spillover severity
        if strength >= 45 {
            state.consequences.softenAllPressure(by: max(2, strength / 18))
            // Extra dampening on the strongest current pressure
            if let (domain, value) = state.consequences.pressureByDomain.max(by: { $0.value < $1.value }) {
                state.consequences.pressureByDomain[domain] = max(0, value - max(2, strength / 20))
            }
        } else {
            state.consequences.softenAllPressure(by: max(1, strength / 25))
        }

        // Phase S2: Sports momentum carry-over — high instant momentum boosts athlete performance
        if state.specialCareer.track == .athlete {
            let m = state.instantMomentum
            if m.overallStrength >= 30 {
                if m.healthMomentum >= 25 || m.overallStrength >= 50 {
                    let boost = max(3, m.overallStrength / 15)
                    state.specialCareer.athlete.peakPerformance = min(100, state.specialCareer.athlete.peakPerformance + boost)
                    state.specialCareer.athlete.injuryRisk = max(5, state.specialCareer.athlete.injuryRisk - (boost / 2))
                }
            }
            // S3a: Doping + momentum interaction — high momentum after edge use can suppress detection (temporarily)
            if state.specialCareer.athlete.enhancementHeat > 0 && m.overallStrength >= 35 {
                let suppression = min(12, m.overallStrength / 6)
                state.specialCareer.athlete.enhancementHeat = max(0, state.specialCareer.athlete.enhancementHeat - suppression)
                if state.specialCareer.athlete.personalBrand < 55 {
                    state.specialCareer.athlete.personalBrand = min(100, state.specialCareer.athlete.personalBrand + 2)
                }
            }
        }

        // Fame Web F3: Stronger downsides + benefits for high recognition
        let fameWeb = state.fame
        if fameWeb.recognition >= 40 {
            // High cultural fame = better opportunities, but real scrutiny
            if fameWeb.culturalFame >= 50 {
                state.career.opportunityDoorYearsRemaining = min(3, state.career.opportunityDoorYearsRemaining + 1)
                state.specialCareer.heat = min(100, state.specialCareer.heat + (fameWeb.culturalFame >= 70 ? 4 : 2))
                if fameWeb.culturalFame >= 70 {
                    state.specialCareer.burnout = min(100, state.specialCareer.burnout + 2)
                }
            }
            // High notoriety = amplified heat and risk
            if fameWeb.notoriety >= 50 {
                state.specialCareer.heat = min(100, state.specialCareer.heat + (fameWeb.notoriety >= 70 ? 8 : 4))
                if state.specialCareer.track == .crime || state.crime.status == .active {
                    state.crime.notoriety = min(100, state.crime.notoriety + 4)
                }
                if fameWeb.notoriety >= 70 {
                    state.specialCareer.burnout = min(100, state.specialCareer.burnout + 3)
                }
            }
        }

        // E2: Founder-specific momentum carry-over
        if state.specialCareer.track == .founder {
            let m = state.instantMomentum
            let fd = state.specialCareer.founder
            if m.overallStrength >= 30 {
                if m.overallStrength >= 50 {
                    // Strong momentum after founder actions gives real CEO buffs
                    state.specialCareer.founder.vision = min(95, fd.vision + max(2, m.overallStrength / 12))
                    state.specialCareer.founder.execution = min(95, fd.execution + max(2, m.overallStrength / 14))
                    state.specialCareer.founder.founderMentalLoad = max(5, fd.founderMentalLoad - max(3, m.overallStrength / 10))
                }
                if m.relationshipMomentum >= 25 {
                    // Team-focused momentum helps culture and reduces board pressure
                    state.specialCareer.founder.teamHealth = min(95, fd.teamHealth + 4)
                    state.specialCareer.boardPressure = max(0, state.specialCareer.boardPressure - 5)
                }
            }
        }

        // C2: Creator-specific momentum carry-over
        if state.specialCareer.track == .contentCreator {
            let m = state.instantMomentum
            let c = state.specialCareer.creator
            if m.overallStrength >= 30 {
                if m.overallStrength >= 45 {
                    // Consistent posting momentum improves algorithm and reduces burnout
                    state.specialCareer.creator.algorithmFavor = min(95, c.algorithmFavor + max(3, m.overallStrength / 10))
                    state.specialCareer.creator.burnout = max(5, c.burnout - max(2, m.overallStrength / 12))
                }
                if m.relationshipMomentum >= 25 {
                    // High social momentum helps personal brand and brand deals
                    state.specialCareer.creator.personalBrand = min(100, c.personalBrand + 4)
                    state.specialCareer.creator.brandDealValue = min(100, c.brandDealValue + 3)
                }
            }
        }

        // P2: Politics-specific momentum carry-over
        if state.specialCareer.track == .politics {
            let m = state.instantMomentum
            let p = state.specialCareer.politics
            if m.overallStrength >= 30 {
                if m.overallStrength >= 45 {
                    // Strong momentum stabilizes approval and reduces scandal heat
                    state.specialCareer.politics.approvalRating = min(100, p.approvalRating + max(2, m.overallStrength / 12))
                    state.specialCareer.politics.scandalHeat = max(0, p.scandalHeat - max(2, m.overallStrength / 10))
                }
                if m.relationshipMomentum >= 25 {
                    // High social momentum boosts charisma and donor base
                    state.specialCareer.politics.charisma = min(95, p.charisma + 4)
                    state.specialCareer.politics.donorBase = min(100, p.donorBase + 3)
                }
            }
        }

        // CE2: Criminal Enterprise momentum carry-over (heat, loyalty, clean money, network)
        if state.crime.status == .active || state.specialCareer.track == .crime {
            let m = state.instantMomentum
            let ent = state.specialCareer.enterprise
            if m.overallStrength >= 28 {
                if m.overallStrength >= 42 {
                    // Strong aggressive momentum reduces heat and improves operational security
                    state.crime.heat = max(0, state.crime.heat - max(2, m.overallStrength / 11))
                    state.specialCareer.enterprise.operationalSecurity = min(100, ent.operationalSecurity + max(2, m.overallStrength / 14))
                    // Clean money progress sticks better after focused runs
                    state.specialCareer.enterprise.cleanMoneyRatio = min(100, ent.cleanMoneyRatio + max(1, m.overallStrength / 18))
                }
                if m.overallStrength >= 55 || m.financeMomentum >= 30 {
                    // High financial or overall momentum from crime actions strengthens the network and loyalty
                    state.specialCareer.enterprise.networkStrength = min(100, ent.networkStrength + 4)
                    state.specialCareer.enterprise.loyalty = min(100, ent.loyalty + 3)
                    // But sustained heat also creeps up if you stay aggressive
                    if m.overallStrength >= 65 {
                        state.specialCareer.heat = min(100, state.specialCareer.heat + 3)
                    }
                }
            }
        }

        // Phase 5: Make LifeResilience feel viscerally different through narrative texture
        if strength >= 40 {
            let flavor: String
            if state.resilience == .grounded {
                flavor = "In a Grounded life, those focused actions stood out even more against the weight."
            } else {
                flavor = "Your resilience let those small wins compound into something that actually held."
            }
            if state.history.prefix(3).allSatisfy({ !$0.title.contains("Focus") && !$0.title.contains("Momentum") }) {
                state.history.insert(
                    HistoryEntry(age: state.player.age, title: "Quiet Momentum", text: flavor, tags: [.progress]),
                    at: 0
                )
            }
        }

        // Fame Web F3: Fame flavor in quiet momentum notes
        let fameRecord = state.fame
        if fameRecord.recognition >= 55 && state.history.prefix(2).allSatisfy({ !$0.title.contains("Recognition") && !$0.title.contains("Name") }) {
            let fameFlavor: String
            if fameRecord.isInfamous {
                fameFlavor = "Even in a quiet stretch, the shadow of your name follows you into rooms."
            } else if fameRecord.isHouseholdName {
                fameFlavor = "The world has decided who you are. Even silence carries your reputation now."
            } else {
                fameFlavor = "Your name is starting to open doors (and close others) without you lifting a finger."
            }
            state.history.insert(HistoryEntry(age: state.player.age, title: "Recognition Echo", text: fameFlavor, tags: [.progress]), at: 0)
        }

        // Engine1: Correlation ledger gives quiet years texture based on recent instant/autonomous activity
        let recentHeat = state.correlationLedger.recentActivityLevel
        if recentHeat >= 40 && state.instantMomentum.overallStrength < 15 {
            if !state.history.prefix(2).contains(where: { $0.title.contains("Aftermath") || $0.title.contains("Echo") || $0.title.contains("Action") }) {
                let note = recentHeat >= 70
                    ? "The last stretch of focused actions is still reverberating. Even silence feels busy."
                    : "Recent choices left a mark. This quiet year doesn't feel quite as empty as it should."
                state.history.insert(HistoryEntry(age: state.player.age, title: "Action Echo", text: note, tags: [.progress]), at: 0)
            }
        }
    }

    private func buildCrisisInteraction(for state: GameState) -> CrisisInteraction {
        if state.player.health <= 0 || state.healthProfile.physicalWellness <= 0 {
            return CrisisInteraction(
                id: "crisis-health-\(state.player.age)",
                title: "The Golden Hour",
                detail: "Your body has reached its absolute limit. The world is fading. You can feel the thread snapping.",
                choices: [
                    CrisisChoice(id: "health-accept", text: "Let Go", detail: "Accept the end. Your legacy is written.", costSummary: "+2x Legacy Points", isBuyBack: false),
                    CrisisChoice(id: "health-buyback", text: "Fight For Every Breath", detail: "Call in every favor, spend every cent. Pull yourself back.", costSummary: "-80 Social Capital / -$15k Cash • Permanent 'Fragile' trait", isBuyBack: true)
                ]
            )
        } else {
            let financeCrisisDetail: String = {
                if state.resilience == .resilient {
                    return "The numbers have caught up hard. This is a deep hole, but not necessarily the end of the story — if you're willing to fight ugly for it."
                } else {
                    return "The numbers have finally caught up. You are deeper in debt than the systems will allow. Bankruptcy is no longer a choice; it's a reality."
                }
            }()
            return CrisisInteraction(
                id: "crisis-finance-\(state.player.age)",
                title: "Total Collapse",
                detail: financeCrisisDetail,
                choices: [
                    CrisisChoice(id: "finance-accept", text: "Accept Ruin", detail: "Losing everything. Moving back to square one.", costSummary: "Lose all Assets • Reset Life", isBuyBack: false),
                    CrisisChoice(id: "finance-buyback", text: "The Predatory Deal", detail: "A bailout from people you shouldn't know. The money is yours, but so is the shadow.", costSummary: "+$10k Cash • Permanent 70+ Financial Stress", isBuyBack: true)
                ]
            )
        }
    }

    // MARK: - Fame Web (F1)

    /// Yearly propagation that connects every major fame avenue into a single unified profile.
    /// This is the heart of F1: special careers, athlete personalBrand, military medals,
    /// lifestyle/wealth signals, and social reputation all now contribute to "how known you are."
    private func propagateFameForYear(to state: inout GameState) {
        var f = state.fame
        f.clamp()

        let sc = state.specialCareer
        let a = sc.athlete
        let rel = state.relationships
        let mil = state.military
        let assets = state.assets

        // 1. Special career (entertainment, founder, athlete-generic, crime, etc.)
        if sc.track != .inactive {
            let fameLeak = max(0, (sc.fame + sc.audience / 2) / 5)
            f.culturalFame = min(100, f.culturalFame + fameLeak)

            let notoLeak = max(0, (sc.notoriety + sc.heat / 3) / 6)
            f.notoriety = min(100, f.notoriety + notoLeak)
        }

        // 2. Athlete personalBrand + accolades (strong S3a integration)
        if sc.track == .athlete {
            let brandContribution = max(0, (a.personalBrand - 15) / 3)
            f.culturalFame = min(100, f.culturalFame + brandContribution)

            for accolade in a.accolades where !f.knownFor.contains(accolade) {
                f.knownFor.append(accolade)
            }
            if a.personalBrand >= 68 && !f.knownFor.contains("Icon") {
                f.knownFor.append("Icon")
            }
            if a.accolades.contains("Hall of Fame") && !f.knownFor.contains("Legend") {
                f.knownFor.append("Legend")
            }
        }

        // E3: Strong founder / CEO legend integration with Fame Web
        if sc.track == .founder {
            let fd = sc.founder
            // Personal legend is the founder-specific fame driver
            let legendBoost = max(0, (fd.personalLegend - 20) / 4)
            f.culturalFame = min(100, f.culturalFame + legendBoost)

            // Big valuation (audience) as founder = serious cultural impact
            if sc.audience >= 60 {
                let valuationFame = (sc.audience - 50) / 3
                f.culturalFame = min(100, f.culturalFame + valuationFame)
            }

            // Successful founder generates specific knownFor
            if fd.personalLegend >= 50 && !f.knownFor.contains("Founder") {
                f.knownFor.append("Founder")
            }
            if sc.audience >= 75 && fd.personalLegend >= 60 && !f.knownFor.contains("Serial Entrepreneur") {
                f.knownFor.append("Serial Entrepreneur")
            }
            if fd.keyHires >= 40 && fd.companyCulture >= 70 && !f.knownFor.contains("Culture Builder") {
                f.knownFor.append("Culture Builder")
            }

            // High mental load + success = "tortured genius" notoriety flavor
            if fd.founderMentalLoad >= 65 && sc.audience >= 50 {
                f.notoriety = min(100, f.notoriety + 3)
            }
        }

        if sc.track == .recordLabelOwner {
            let label = sc.recordLabel
            let catalogBoost = max(0, (label.catalogStrength + label.labelPrestige - 45) / 5)
            f.culturalFame = min(100, f.culturalFame + catalogBoost)
            if label.labelPrestige >= 40 && !f.knownFor.contains("Record Label Owner") {
                f.knownFor.append("Record Label Owner")
            }
            if label.catalogStrength >= 65 && label.labelPrestige >= 55 && !f.knownFor.contains("Hitmaker") {
                f.knownFor.append("Hitmaker")
            }
            if label.artistTrust >= 75 && !f.knownFor.contains("Artist-Friendly Mogul") {
                f.knownFor.append("Artist-Friendly Mogul")
            }
            if label.industryHeat >= 65 || label.artistPayoutPolicy == .exploitative {
                f.notoriety = min(100, f.notoriety + max(2, label.industryHeat / 12))
            }
        }

        if sc.track == .movieActor {
            let actor = sc.movieActor
            let actorBoost = max(0, (actor.roleCredits * 3 + actor.boxOfficeDraw + actor.screenPresence - 55) / 6)
            f.culturalFame = min(100, f.culturalFame + actorBoost)
            if actor.roleCredits >= 2 && !f.knownFor.contains("Movie Actor") {
                f.knownFor.append("Movie Actor")
            }
            if actor.boxOfficeDraw >= 55 && !f.knownFor.contains("Box Office Draw") {
                f.knownFor.append("Box Office Draw")
            }
            if actor.actingSkill >= 70 && actor.roleCredits >= 4 && !f.knownFor.contains("Serious Actor") {
                f.knownFor.append("Serious Actor")
            }
            if actor.publicImage < 30 || sc.heat >= 60 {
                f.notoriety = min(100, f.notoriety + max(2, sc.heat / 18))
            }
        }

        if sc.track == .musicProducer {
            let producer = sc.musicProducer
            let producerBoost = max(0, (producer.credits * 2 + producer.sonicSignature + producer.demand - 70) / 6)
            f.culturalFame = min(100, f.culturalFame + producerBoost)
            if producer.credits >= 4 && !f.knownFor.contains("Music Producer") {
                f.knownFor.append("Music Producer")
            }
            if producer.credits >= 10 && producer.demand >= 60 && !f.knownFor.contains("Hit Producer") {
                f.knownFor.append("Hit Producer")
            }
            if producer.creditDisputes >= 60 {
                f.notoriety = min(100, f.notoriety + producer.creditDisputes / 15)
            }
        }

        if sc.track == .movieProducer {
            let film = sc.movieProducer
            let producerBoost = max(0, (film.prestige + film.backendCatalog + film.distributionLeverage - 50) / 5)
            f.culturalFame = min(100, f.culturalFame + producerBoost)
            if film.prestige >= 35 && !f.knownFor.contains("Film Producer") {
                f.knownFor.append("Film Producer")
            }
            if film.backendCatalog >= 45 && film.distributionLeverage >= 45 && !f.knownFor.contains("Studio Rainmaker") {
                f.knownFor.append("Studio Rainmaker")
            }
            if film.prestige >= 65 && !f.knownFor.contains("Award Producer") {
                f.knownFor.append("Award Producer")
            }
            if film.productionChaos >= 70 || sc.heat >= 65 {
                f.notoriety = min(100, f.notoriety + max(2, film.productionChaos / 15))
            }
        }

        if sc.track == .coach {
            let coach = sc.coaching
            let coachBoost = max(0, (coach.programPrestige + coach.seasonWins * 4 + coach.recruitingReach - 45) / 5)
            f.culturalFame = min(100, f.culturalFame + coachBoost)
            if coach.programPrestige >= 35 && !f.knownFor.contains("Program Coach") {
                f.knownFor.append("Program Coach")
            }
            if coach.seasonWins >= 10 && !f.knownFor.contains("Winning Coach") {
                f.knownFor.append("Winning Coach")
            }
            if coach.programPrestige >= 75 && coach.seasonWins >= 10 && !f.knownFor.contains("Championship Coach") {
                f.knownFor.append("Championship Coach")
            }
            if coach.boosterPressure >= 75 || sc.heat >= 65 {
                f.notoriety = min(100, f.notoriety + max(2, coach.boosterPressure / 16))
            }
        }

        // C3: Strong Content Creator legend integration with Fame Web
        if sc.track == .contentCreator {
            let c = sc.creator
            // personalBrand is the core creator fame driver (authenticity vs virality)
            let brandBoost = max(0, (c.personalBrand - 25) / 3)
            f.culturalFame = min(100, f.culturalFame + brandBoost)

            // High audience + algorithm success = massive cultural impact
            if c.audience >= 50 && c.algorithmFavor >= 60 {
                let viralityFame = (c.audience + c.algorithmFavor - 80) / 4
                f.culturalFame = min(100, f.culturalFame + max(0, viralityFame))
            }

            // Generate creator-specific knownFor
            if c.audience >= 60 && c.personalBrand >= 50 && !f.knownFor.contains("Went Viral") {
                f.knownFor.append("Went Viral")
            }
            if c.cancellationRisk >= 50 && c.audience >= 40 && !f.knownFor.contains("Canceled") {
                f.knownFor.append("Canceled")
            }
            if c.personalBrand >= 70 && c.audience >= 55 && !f.knownFor.contains("Cult Following") {
                f.knownFor.append("Cult Following")
            }
            if c.brandDealValue >= 60 && c.personalBrand >= 45 && !f.knownFor.contains("Influencer") {
                f.knownFor.append("Influencer")
            }

            // High burnout + success = "burnt out creator" notoriety flavor
            if c.burnout >= 60 && c.audience >= 45 {
                f.notoriety = min(100, f.notoriety + 2)
            }
        }

        // P3: Strong Politics integration with Fame Web
        if sc.track == .politics {
            let p = sc.politics
            // Approval is the primary political fame driver
            let approvalBoost = max(0, (p.approvalRating - 30) / 3)
            f.culturalFame = min(100, f.culturalFame + approvalBoost)

            // Scandals drive notoriety hard
            if p.scandalHeat >= 40 {
                let scandalNotoriety = (p.scandalHeat - 30) / 4
                f.notoriety = min(100, f.notoriety + scandalNotoriety)
            }

            // Generate politician-specific knownFor
            if p.policyLegacy >= 50 && p.approvalRating >= 45 && !f.knownFor.contains("Passed Major Reform") {
                f.knownFor.append("Passed Major Reform")
            }
            if p.scandalHeat >= 70 && !f.knownFor.contains("Resigned in Disgrace") {
                f.knownFor.append("Resigned in Disgrace")
            }
            if p.approvalRating >= 65 && p.policyLegacy >= 40 && !f.knownFor.contains("Longtime Senator") {
                f.knownFor.append("Longtime Senator")
            }
            if p.ethics < 40 && p.donorBase >= 50 && !f.knownFor.contains("Machine Politician") {
                f.knownFor.append("Machine Politician")
            }
            if p.ethics >= 75 && p.policyLegacy >= 50 && !f.knownFor.contains("Principled Reformer") {
                f.knownFor.append("Principled Reformer")
            }
        }

        // CE3: Deep Fame Web for Criminal Enterprise — notoriety as first-class dark fame path
        if sc.track == .crime || state.crime.status == .active {
            let ent = sc.enterprise
            // High enterprise notoriety + heat = serious shadow reputation
            let crimeNotoriety = max(0, (ent.notoriety - 25) / 3 + (sc.heat / 5))
            f.notoriety = min(100, f.notoriety + crimeNotoriety)

            // Heat without clean money creates dangerous public "whispers" notoriety
            if sc.heat >= 55 && ent.cleanMoneyRatio < 45 {
                f.notoriety = min(100, f.notoriety + 4)
            }

            // Successful clean empire still leaks dark fame
            if ent.cleanMoneyRatio >= 70 && ent.networkStrength >= 60 {
                f.notoriety = min(100, f.notoriety + 2)
            }

            // Criminal-specific knownFor tags (the dark legendarium)
            if ent.notoriety >= 70 && !f.knownFor.contains("Shadow Reputation") {
                f.knownFor.append("Shadow Reputation")
            }
            if ent.notoriety >= 85 && ent.crewSize >= 8 && !f.knownFor.contains("Kingpin") {
                f.knownFor.append("Kingpin")
            }
            if ent.subtype == .ventureCapitalist && ent.cleanMoneyRatio >= 65 && ent.networkStrength >= 55 && !f.knownFor.contains("Gray Market Financier") {
                f.knownFor.append("Gray Market Financier")
            }
            if ent.subtype == .corporateRaider && ent.notoriety >= 65 && !f.knownFor.contains("Raider Who Walked") {
                f.knownFor.append("Raider Who Walked")
            }
            if ent.heat >= 75 && ent.cleanMoneyRatio < 30 && !f.knownFor.contains("Heat That Won't Die") {
                f.knownFor.append("Heat That Won't Die")
            }
            if ent.cleanMoneyRatio >= 80 && ent.notoriety >= 50 && !f.knownFor.contains("The One Who Got Clean") {
                f.knownFor.append("The One Who Got Clean")
            }
            if sc.heat >= 80 && !f.knownFor.contains("Marked") {
                f.knownFor.append("Marked")
            }

            // High dark fame creates real downsides in the wider world (CE3)
            if f.notoriety >= 60 {
                state.specialCareer.heat = min(100, state.specialCareer.heat + (f.notoriety >= 80 ? 5 : 2))
                if state.relationships.hasPartner {
                    // Partners feel the weight of a notorious name
                    for i in state.relationships.romanticPartners.indices {
                        if !state.relationships.romanticPartners[i].isSecret {
                            state.relationships.romanticPartners[i].bond = max(5, state.relationships.romanticPartners[i].bond - 2)
                        }
                    }
                }
            }
        }

        // 3. Military medals + rank (valor path)
        if mil.track != .inactive {
            let militaryFame = (mil.rankLevel * 5) + (mil.medals.count * 9)
            f.culturalFame = min(100, f.culturalFame + max(0, militaryFame / 4))

            for medal in mil.medals where !f.knownFor.contains(medal) {
                f.knownFor.append(medal)
            }
            if mil.rankLevel >= 6 && !f.knownFor.contains("Decorated") {
                f.knownFor.append("Decorated")
            }
        }

        // 4. Visible wealth / High Society lifestyle (assets already tease this)
        if assets.lifestyleScore >= 40 {
            let lifestyleFame = (assets.lifestyleScore - 35) / 3
            f.culturalFame = min(100, f.culturalFame + lifestyleFame)
            if assets.lifestyleScore >= 65 && !f.knownFor.contains("High Society") {
                f.knownFor.append("High Society")
            }

            // Assets2 + Assets4: Signature + luxury asset knownFor and fame
            for sig in assets.signatureAssets {
                if !f.knownFor.contains(sig.name) {
                    f.knownFor.append(sig.name)
                }
                f.culturalFame = min(100, f.culturalFame + (sig.prestigeBonus / 4))
            }

            // Collector flavor
            if assets.vehicles.count >= 4 && !f.knownFor.contains("Car Collector") {
                f.knownFor.append("Car Collector")
                f.culturalFame = min(100, f.culturalFame + 3)
            }
            if assets.marine.count >= 2 && !f.knownFor.contains("Yacht Owner") {
                f.knownFor.append("Yacht Owner")
            }
            if assets.aviation.count >= 1 && assets.lifestyleScore >= 70 && !f.knownFor.contains("Private Aviation") {
                f.knownFor.append("Private Aviation")
            }
        }

        // 5. Social reputation slowly feeds cultural recognition (the "well-regarded" path)
        let repAboveBaseline = max(0, rel.publicReputation - 52)
        if repAboveBaseline > 0 {
            f.culturalFame = min(100, f.culturalFame + repAboveBaseline / 10)
        }

        // Merge relationship knownForTags
        for tag in rel.knownForTags where !f.knownFor.contains(tag) {
            f.knownFor.append(tag)
        }

        // 6. Peak tracking for legacy texture
        let currentRec = f.recognition
        if currentRec > 35 {
            if f.peakFameAge == nil || currentRec >= (state.fame.recognition + 8) {
                f.peakFameAge = state.player.age
            }
        }

        // 7. Gentle decay when fame is high but this year was quiet (realistic "fame fades")
        if currentRec > 28 && state.instantMomentum.overallStrength < 18 {
            let decay = max(1, currentRec / 22)
            f.culturalFame = max(0, f.culturalFame - decay / 2)
            f.notoriety = max(0, f.notoriety - decay / 2)
        }

        // F2: Regular career peaks (especially creative/sales/management/public roles)
        let c = state.career
        if c.performance >= 72 && c.yearsWorked >= 3 && c.status == .fullTime {
            var careerFame = (c.performance - 68) / 5 + (c.level * 1)
            if ["creative", "sales", "management"].contains(c.profile.rawValue) {
                careerFame = Int(Double(careerFame) * 1.5)  // Public/influential profiles move fame faster
            }
            f.culturalFame = min(100, f.culturalFame + max(0, careerFame))

            if c.performance >= 85 && c.level >= 3 && !f.knownFor.contains("Industry Name") {
                f.knownFor.append("Industry Name")
            }
        }

        // F2: Stronger social/dating scene contribution (being seen, high-status circles)
        if rel.publicReputation >= 65 {
            let socialFame = (rel.publicReputation - 60) / 4
            f.culturalFame = min(100, f.culturalFame + socialFame)
        }
        if rel.activeRumorHeat >= 50 {
            // Rumors cut both ways
            f.notoriety = min(100, f.notoriety + (rel.activeRumorHeat - 45) / 5)
        }

        // Econ2: Deep economic character knownFor + Fame Web narrative layer
        // The era you lived through while on a high-variance path becomes permanent legend texture.
        let era_e = state.currentEra
        let sc_e = state.specialCareer
        let isRecession_e = (era_e == .recession)
        let isBoom_e = (era_e == .bullMarket || era_e == .techBoom)
        let isTechBoom_e = (era_e == .techBoom)
        let isCrisis_e = (era_e == .wartime || era_e == .pandemic)
        let isInflation_e = (era_e == .highInflation)

        // POLITICS — economic character is destiny for politicians
        if sc_e.track == .politics {
            let p = sc_e.politics
            if isRecession_e && p.approvalRating < 50 && p.donorBase > 40 {
                if !f.knownFor.contains("Recession Voice") { f.knownFor.append("Recession Voice") }
            }
            if isRecession_e && p.approvalRating < 35 && p.ethics < 50 {
                if !f.knownFor.contains("Populist in the Storm") { f.knownFor.append("Populist in the Storm") }
            }
            if isBoom_e && p.ethics < 45 && p.donorBase > 55 {
                if !f.knownFor.contains("Boom-Era Insider") { f.knownFor.append("Boom-Era Insider") }
            }
            if isBoom_e && p.policyLegacy >= 45 && p.approvalRating >= 60 {
                if !f.knownFor.contains("Prosperity Politician") { f.knownFor.append("Prosperity Politician") }
            }
            if isInflation_e && p.approvalRating < 45 {
                if !f.knownFor.contains("Inflation Scapegoat") { f.knownFor.append("Inflation Scapegoat") }
            }
            if isCrisis_e && p.approvalRating >= 60 {
                if !f.knownFor.contains("Crisis Steward") { f.knownFor.append("Crisis Steward") }
            }
        }

        // CREATOR — the attention economy is brutally era-dependent
        if sc_e.track == .contentCreator {
            let c_cr = sc_e.creator
            if isRecession_e && c_cr.audience >= 35 && c_cr.personalBrand < 50 {
                if !f.knownFor.contains("Authenticity in the Squeeze") { f.knownFor.append("Authenticity in the Squeeze") }
            }
            if isRecession_e && c_cr.brandDealValue < 25 && c_cr.audience >= 45 {
                if !f.knownFor.contains("Recession Creator") { f.knownFor.append("Recession Creator") }
            }
            if isBoom_e && c_cr.personalBrand >= 55 && c_cr.brandDealValue >= 50 {
                if !f.knownFor.contains("Boom-Era Influencer") { f.knownFor.append("Boom-Era Influencer") }
            }
            if isBoom_e && c_cr.contentQuality >= 60 && c_cr.audience >= 50 {
                if !f.knownFor.contains("Aspiration Merchant") { f.knownFor.append("Aspiration Merchant") }
            }
            if isInflation_e && c_cr.audience >= 40 && c_cr.personalBrand < 45 {
                if !f.knownFor.contains("Dupe Culture Voice") { f.knownFor.append("Dupe Culture Voice") }
            }
            if isCrisis_e && c_cr.audience >= 35 {
                if !f.knownFor.contains("Pandemic Era Creator") { f.knownFor.append("Pandemic Era Creator") }
            }
            if c_cr.cancellationRisk >= 55 && isRecession_e {
                if !f.knownFor.contains("Canceled in the Downturn") { f.knownFor.append("Canceled in the Downturn") }
            }
        }

        // FOUNDER — your economic timing becomes your origin myth or cautionary tale
        if sc_e.track == .founder {
            let fd = sc_e.founder
            if isRecession_e && sc_e.audience >= 40 {
                if !f.knownFor.contains("Down Round Founder") { f.knownFor.append("Down Round Founder") }
            }
            if isRecession_e && fd.founderMentalLoad >= 70 && sc_e.audience >= 30 {
                if !f.knownFor.contains("Recession Survivor CEO") { f.knownFor.append("Recession Survivor CEO") }
            }
            if isBoom_e && sc_e.audience >= 55 {
                if !f.knownFor.contains("Boom Builder") { f.knownFor.append("Boom Builder") }
            }
            if isBoom_e && fd.personalLegend >= 55 && sc_e.audience >= 60 {
                if !f.knownFor.contains("Paper Millionaire") { f.knownFor.append("Paper Millionaire") } // can be positive or ironic depending on later exit
            }
            if isTechBoom_e && fd.personalLegend >= 50 {
                if !f.knownFor.contains("Tech Boom Legend") { f.knownFor.append("Tech Boom Legend") }
            }
            if isInflation_e && sc_e.audience >= 35 && fd.execution >= 50 {
                if !f.knownFor.contains("Inflation Operator") { f.knownFor.append("Inflation Operator") }
            }
            if fd.founderMentalLoad >= 75 && isRecession_e {
                if !f.knownFor.contains("Burned Through the Crash") { f.knownFor.append("Burned Through the Crash") }
            }
        }

        // ATHLETE — sponsorships and myth are pure economic weather vanes
        if sc_e.track == .athlete {
            let a = sc_e.athlete
            if isRecession_e && sc_e.audience < 45 && a.personalBrand >= 40 {
                if !f.knownFor.contains("Survived the Lean Years") { f.knownFor.append("Survived the Lean Years") }
            }
            if isRecession_e && a.personalBrand < 35 && sc_e.audience >= 30 {
                if !f.knownFor.contains("Sponsor Drought Athlete") { f.knownFor.append("Sponsor Drought Athlete") }
            }
            if isBoom_e && a.personalBrand >= 50 {
                if !f.knownFor.contains("Victory Economy Star") { f.knownFor.append("Victory Economy Star") }
            }
            if isBoom_e && sc_e.audience >= 55 && a.personalBrand >= 60 {
                if !f.knownFor.contains("Boom Market Icon") { f.knownFor.append("Boom Market Icon") }
            }
            if isCrisis_e && sc_e.audience >= 40 {
                if !f.knownFor.contains("Played Through the Silence") { f.knownFor.append("Played Through the Silence") }
            }
            if a.accolades.count >= 2 && isRecession_e {
                if !f.knownFor.contains("Champion in Hard Times") { f.knownFor.append("Champion in Hard Times") }
            }
        }

        f.clamp()
        state.fame = f
    }

    /// Small but meaningful recovery signal when the player actively fights back
    /// while under pressure. This is one of the biggest levers for "I can still turn this around"
    /// feelings that drive replayability in a Life Killer game.
    private func applyFightingBackRecoveryBonus(to state: inout GameState) -> [DomainNote] {
        guard !state.isGameOver else { return [] }

        let highPressureDomains = state.consequences.pressureByDomain.filter { $0.value >= 28 }.keys
        guard !highPressureDomains.isEmpty else { return [] }

        let stabilizingChoices: Set<ActionChoiceID> = [
            .cutSpending, .minimumPayments, .payDownDebt,
            .protectSleep, .rest, .protectYourEnergy,
            .repairTension, .reachOut,
            .studyConsistently, .lockInRoutine
        ]

        let recentActions = state.actionMemory.actionsThisAge.map { $0.choiceID }
        let usedStabilizing = recentActions.contains { stabilizingChoices.contains($0) }

        // Also count stance if it was a stabilizing one
        let stanceHelped = state.yearlyStance.selectedStance != .letYearDrift

        guard usedStabilizing || stanceHelped else { return [] }

        var notes: [DomainNote] = []

        // Grounded runs: repair under pressure is rarer but more visceral when it lands.
        let mentalGain = state.resilience == .grounded ? 8 : 5
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + mentalGain).clamped(to: 0...100)
        state.healthProfile.physicalWellness = (state.healthProfile.physicalWellness + (state.resilience == .grounded ? 3 : 1)).clamped(to: 0...100)
        state.player.health = ((state.healthProfile.physicalWellness * 2) + state.healthProfile.mentalWellness) / 3
        state.player.clampStats()

        let tone: String
        if state.resilience == .grounded {
            tone = "In a Grounded run, choosing repair while everything was loud actually moved the needle. That is rare — and it mattered."
        } else {
            tone = "You kept choosing the smaller repair. It added up."
        }
        notes.append(
            DomainNote(
                title: "Fighting Back",
                text: "\(tone) A little breathing room returned.",
                tags: [.health, .progress]
            )
        )

        let pressureRelief = state.resilience == .grounded ? 6 : 4
        if let firstHigh = highPressureDomains.first, let current = state.consequences.pressureByDomain[firstHigh] {
            state.consequences.pressureByDomain[firstHigh] = max(0, current - pressureRelief)
        }

        return notes
    }

    // P4-1: Safety nets + risk telegraphing. Prevents hard spirals from single bad years while preserving stakes.
    // Called after finance/health advance in resolvePreparedYearChapter.
    // Reuses resilience (grounded gets slightly stronger recovery volume for "fighting back" feel), era, and D4 life shape proxy.
    // Publishes cheap ledger signal so Silent/Continuity/autonomy can react ("you caught a break").
    private func applyP4SafetyNets(to state: inout GameState) -> [DomainNote] {
        guard !state.isGameOver else { return [] }
        var notes: [DomainNote] = []

        // Health safety net
        let phys = state.healthProfile.physicalWellness
        let ment = state.healthProfile.mentalWellness
        let lowHealth = phys < 22 || ment < 18 || state.player.health < 25
        if lowHealth {
            // Base recovery small but meaningful; grounded gets more "mercy" to match fighting-back theme from D4/P1.
            let physGain = state.resilience == .grounded ? 9 : 6
            let mentGain = state.resilience == .grounded ? 7 : 4
            state.healthProfile.physicalWellness = (phys + physGain).clamped(to: 0...100)
            state.healthProfile.mentalWellness = (ment + mentGain).clamped(to: 0...100)
            state.player.health = ((state.healthProfile.physicalWellness * 2) + state.healthProfile.mentalWellness) / 3
            state.player.clampStats()

            let shape = deriveLifeShapeProxy(for: state) // cheap local tally, reuses D4 recentStances
            let eraNote = state.currentEra == .recession ? " even in a tight economy" : ""
            let shapeNote = shape == "driven current" ? " The same drive that got you here kept you upright." : (shape == "loose edges" ? " You let some things slide, but the year didn't take everything." : "")
            notes.append(DomainNote(
                title: "A Narrow Mercy",
                text: "Your body found a way to keep going this year\(eraNote).\(shapeNote)",
                tags: [.health, .progress]
            ))

            // Cheap ledger pulse so background engines notice "near miss but survived"
            state.correlationLedger.publish(CorrelationSignal(kind: .focusStance, domain: "health", strength: 8, age: state.player.age))
        }

        // Cash safety net (prevents instant finance death spiral into wealth floor game-over)
        if state.finance.cashOnHand < 350 || (state.finance.cashOnHand < 800 && state.finance.financialStress >= 72) {
            let cashBump = state.resilience == .grounded ? 420 : 280
            state.finance.cashOnHand = min(1200, state.finance.cashOnHand + cashBump) // keep it a "breather", not windfall
            state.finance.financialStress = max(0, state.finance.financialStress - (state.resilience == .grounded ? 9 : 5))

            let shape = deriveLifeShapeProxy(for: state)
            let eraNote = state.currentEra == .recession ? " (the margins were brutal)" : ""
            let shapeNote = shape == "driven current" ? " Hustle and stubbornness turned a corner." : (shape == "careful shape" ? " Steady habits caught the fall." : "")
            notes.append(DomainNote(
                title: "Unexpected Breather",
                text: "Something gave just enough to keep the lights on\(eraNote).\(shapeNote)",
                tags: [.finance, .progress]
            ))

            state.correlationLedger.publish(CorrelationSignal(kind: .focusStance, domain: "finance", strength: 8, age: state.player.age))
        }

        // Risk telegraph (P4-1): when curves are dangerous, surface it so player feels the stakes without instant death.
        let age = state.player.age
        let highRiskFactors = (phys < 35 ? 1 : 0) + (state.finance.financialStress >= 65 ? 1 : 0) + (state.crime.heat >= 55 ? 1 : 0) + (age > 62 ? 1 : 0)
        if highRiskFactors >= 2 && !notes.contains(where: { $0.title.contains("Mercy") || $0.title.contains("Breather") }) {
            let riskText: String
            if age > 62 && phys < 35 {
                riskText = "At this age, the body keeps a stricter ledger. One more hard year could be the last."
            } else if state.crime.heat >= 55 {
                riskText = "The heat around you is no longer background noise. A single mistake now carries different weight."
            } else {
                riskText = "The margins are thin. The next year will test whether the shape you've built can hold."
            }
            notes.append(DomainNote(title: "Risk Accumulating", text: riskText, tags: [.health, .finance, .progress]))
        }

        return notes
    }

    // Cheap D4 life shape proxy for P4 balance (no new state, just tally recentStances like deriveLifeShapeForLegacy).
    private func deriveLifeShapeProxy(for state: GameState) -> String {
        let recent = state.yearlyStance.recentStances
        guard !recent.isEmpty else { return "pragmatic" }
        var pragmatic = 0, careful = 0, loose = 0, driven = 0
        for s in recent {
            switch s {
            case .stabilizeMoney: pragmatic += 1
            case .protectHealth: careful += 1
            case .letYearDrift: loose += 1
            case .pushCareer, .soldierStance, .studentStance: driven += 1
            default: pragmatic += 1
            }
        }
        if loose > max(pragmatic, careful, driven) { return "loose edges" }
        if careful > max(pragmatic, loose, driven) { return "careful shape" }
        if driven > max(pragmatic, careful, loose) { return "driven current" }
        return "pragmatic"
    }

    private func buildForecastCard(
        for state: GameState,
        targetAge: Int,
        plannedActions: [PlayerYearAction],
        scheduledEvent: ScheduledConsequenceEvent?,
        event: GameEvent?,
        stakes: TurnStakesSnapshot?
    ) -> YearForecastCard {
        let focus = stakes?.focus ?? buildFocusSignal(for: state, plannedActions: plannedActions)
        let pressure = stakes?.topPressure ?? buildPressureSignal(for: state)
        let opportunity = stakes?.topOpportunity ?? buildOpportunitySignal(for: state)
        let anticipation = anticipationDescriptor(for: state, targetAge: targetAge, scheduledEvent: scheduledEvent, event: event)
        let ignoredRisk = stakes?.ignoredRisk ?? buildIgnoredRiskSignal(for: state, plannedActions: plannedActions, event: event)
        let spilloverRisk = stakes?.spilloverRisk ?? buildSpilloverRiskSignal(for: state, targetAge: targetAge, scheduledEvent: scheduledEvent)
        let momentum = stakes?.momentum

        let anticipationTitle: String
        let anticipationDetail: String
        if scheduledEvent != nil {
            anticipationTitle = anticipation.title
            anticipationDetail = anticipation.detail
        } else {
            anticipationTitle = "Likely opening"
            anticipationDetail = "\(opportunity.detail) \(anticipation.detail)"
        }

        // Phase 3: Stronger, more specific Instant Momentum surface in forecasts
        var momentumPressureDetail = "\(pressure.detail) \(spilloverRisk.detail)\(whyNowContextLine(for: state, domain: pressure.domain))"
        let m = state.instantMomentum
        if m.overallStrength >= 35 {
            var carryText = " Recent focused actions are still carrying weight"
            if m.healthMomentum >= 35 { carryText += " on your health" }
            else if m.financeMomentum >= 35 { carryText += " around money" }
            else if m.relationshipMomentum >= 35 { carryText += " in your relationships" }
            carryText += "."
            momentumPressureDetail += carryText
        }

        // Phase 3: More prominent and domain-aware momentum in subtitle
        var finalSubtitle = event?.title ?? "The year is already leaning somewhere."
        if m.overallStrength >= 30 {
            let domainHint: String
            if m.overallStrength >= 60 {
                domainHint = m.healthMomentum >= 40 ? "Health momentum" : m.financeMomentum >= 40 ? "Financial momentum" : m.relationshipMomentum >= 40 ? "Relationship momentum" : "Strong recent focus"
            } else {
                domainHint = "Recent focus"
            }
            finalSubtitle += " • \(domainHint) helping"
        }

        // Fame Web F3: Fame changes the forecast tone
        let f = state.fame
        if f.recognition >= 50 {
            if f.isInfamous {
                finalSubtitle += " • Your name carries weight (and risk)"
            } else if f.isHouseholdName {
                finalSubtitle += " • The world already has expectations of you"
            } else if f.culturalFame >= 45 {
                finalSubtitle += " • Recognition is opening (and closing) paths"
            }
        } else if let momentum = momentum {
            finalSubtitle += " • \(momentum.title)"
        }

        // Econ2: Economic character in forecast subtitles — the macro era now explicitly comments on your special career identity
        let era = state.currentEra
        let scTrack = state.specialCareer.track
        if scTrack != .inactive {
            switch era {
            case .recession:
                if scTrack == .politics {
                    let p = state.specialCareer.politics
                    if p.approvalRating < 45 {
                        finalSubtitle += " • Recession is turning you into either a voice or a target"
                    } else {
                        finalSubtitle += " • The economy is making every promise harder to keep"
                    }
                } else if scTrack == .contentCreator {
                    let c = state.specialCareer.creator
                    if c.personalBrand < 50 {
                        finalSubtitle += " • In a downturn, authenticity is suddenly in demand"
                    } else {
                        finalSubtitle += " • The brands are quiet. The audience is scared. Your next post carries different weight."
                    }
                } else if scTrack == .founder {
                    finalSubtitle += " • Capital winter is here. Every decision is now a runway decision."
                } else if scTrack == .athlete {
                    finalSubtitle += " • Sponsorships are drying up. The economy just made your body worth less on the open market."
                }
            case .bullMarket, .techBoom:
                if scTrack == .founder {
                    finalSubtitle += " • The money is flowing. The question is what it will turn you into."
                } else if scTrack == .athlete {
                    finalSubtitle += " • Winning feels louder when the economy is celebrating winners."
                } else if scTrack == .contentCreator {
                    let c = state.specialCareer.creator
                    if c.brandDealValue >= 45 {
                        finalSubtitle += " • The economy is hot and the brands want your face. The party has a price."
                    }
                } else if scTrack == .politics && state.specialCareer.politics.ethics < 50 {
                    finalSubtitle += " • Good times make compromise feel almost reasonable."
                }
            case .highInflation:
                finalSubtitle += " • Everything costs more and the middle is being squeezed. Your path feels it differently than most."
            case .pandemic, .wartime:
                finalSubtitle += " • The world is in crisis. Your special career now exists inside a national story you didn't choose."
            default:
                break
            }
        }

        // Phase 5: Subtle but visceral tone difference based on Life Feel
        if state.resilience == .grounded && m.overallStrength >= 30 {
            finalSubtitle += " • Full weight on every carry-over"
        } else if state.resilience == .resilient && m.overallStrength >= 30 {
            finalSubtitle += " • Recovery room from recent focus"
        } else if state.resilience == .grounded {
            finalSubtitle += " • Grounded: thin margins"
        }

        var voiceName: String?
        var voiceLine: String?
        if let contact = preferredAmbientContact(for: state, event: event) {
            voiceName = contact.name
            voiceLine = forecastVoiceLine(for: contact, targetAge: targetAge, state: state, stakes: stakes)
        }

        return YearForecastCard(
            id: "forecast-\(targetAge)",
            age: targetAge,
            title: "Age \(targetAge) Is Taking Shape",
            subtitle: finalSubtitle,
            focusTitle: focus.title,
            focusDetail: "\(focus.detail) \(ignoredRisk.detail)\(synergyContextLine(for: plannedActions))",
            pressureLabel: "Main pressure",
            pressureDetail: momentumPressureDetail,
            anticipationTitle: anticipationTitle,
            anticipationDetail: anticipationDetail,
            tone: pressure.tone,
            voiceName: voiceName,
            voiceLine: voiceLine
        )
    }

    private func forecastVoiceLine(
        for contact: AmbientContact,
        targetAge: Int,
        state: GameState,
        stakes: TurnStakesSnapshot?
    ) -> String {
        let pressure = stakes?.topPressure.title ?? "the pressure you are carrying"
        switch contact.role {
        case .partner:
            return "\(contact.name) can already feel \(pressure.lowercased()) before you turn \(targetAge). Whatever you commit to this year, they will notice."
        case .mentor:
            return "\(contact.name) thinks the next year hinges on whether you respect the cost of \(pressure.lowercased())."
        case .guardian:
            return "At home, \(contact.name) is watching whether \(targetAge) becomes relief or another hard chapter."
        case .friend:
            return "\(contact.name) has been tracking your mood. Age \(targetAge) is when people usually show what they are made of."
        }
    }

    private func whyNowContextLine(for state: GameState, domain: HistoryDomainTag) -> String {
        let key = pressureKey(for: domain)
        if let cause = state.correlationLedger.pressureCauseLine(for: key, limit: 1) {
            return " Why now: \(cause)."
        }
        if let scheduled = state.consequences.scheduledEvents.sorted(by: { $0.dueAge < $1.dueAge }).first {
            return " Why now: \(scheduled.title ?? "a past choice") is coming back."
        }
        if let action = state.actionMemory.latestAction {
            return " Why now: \(ActionChoiceCatalog.definition(for: action.choiceID).title) is still shaping the read."
        }
        return ""
    }

    private func pressureKey(for domain: HistoryDomainTag) -> String {
        switch domain {
        case .education: return "education"
        case .career: return "career"
        case .finance: return "finance"
        case .relationships: return "relationships"
        case .health: return "health"
        case .housing: return "housing"
        default: return "progress"
        }
    }

    private func buildReactionCards(
        before: GameState,
        after: GameState,
        event: GameEvent?,
        choice: EventChoice?,
        summary: YearlyOutcomeSummary?,
        scheduledConsequencePreview: ConsequencePreview?,
        stakes: TurnStakesSnapshot?
    ) -> [YearReactionCard] {
        var cards: [YearReactionCard] = []
        let rememberedActions = before.actionMemory.actionsThisAge
        let chapterActions = after.activeYearChapter?.plannedActions ?? rememberedActions
        let focusChoiceID = choice.flatMap {
            choiceIDFor(choice: $0, in: chapterActions)
        } ?? chapterActions.first?.choiceID ?? .rest
        let focusDefinition = ActionChoiceCatalog.definition(for: focusChoiceID)
        if let contact = preferredAmbientContact(for: after, event: event), choice != nil {
            cards.append(
                YearReactionCard(
                    id: "reaction-contact-\(after.player.age)-\(contact.id)",
                    kicker: contactKicker(for: contact.role),
                    title: "\(contact.name) feels the shift",
                    detail: reactionDetail(for: contact, focus: focusDefinition, state: after, event: event),
                    domain: domainFor(contact.role),
                    tone: contact.bond >= 60 ? .positive : .neutral
                )
            )
        }

        if let focusOutcome = summary?.focusOutcome {
            cards.append(
                YearReactionCard(
                    id: "reaction-focus-\(after.player.age)",
                    kicker: "What your focus bought",
                    title: focusOutcome.title,
                    detail: focusOutcome.detail,
                    domain: focusOutcome.domain,
                    tone: focusOutcome.tone
                )
            )
        }

        if let mainTradeoff = summary?.mainTradeoff {
            cards.append(
                YearReactionCard(
                    id: "reaction-tradeoff-\(after.player.age)",
                    kicker: "What the year charged you",
                    title: mainTradeoff.title,
                    detail: mainTradeoff.detail,
                    domain: mainTradeoff.domain,
                    tone: .warning
                )
            )
        } else if let topProblem = summary?.topProblem {
            cards.append(
                YearReactionCard(
                    id: "reaction-problem-\(after.player.age)",
                    kicker: "What the year took back",
                    title: topProblem.title,
                    detail: topProblem.detail,
                    domain: topProblem.domain,
                    tone: .warning
                )
            )
        } else if let scheduledConsequencePreview {
            cards.append(
                YearReactionCard(
                    id: "reaction-fallout-\(after.player.age)",
                    kicker: "What is still moving",
                    title: scheduledConsequencePreview.title,
                    detail: scheduledConsequencePreview.detail,
                    domain: scheduledConsequencePreview.domain,
                    tone: scheduledConsequencePreview.tone
                )
            )
        }

        if let adultPressureCard = adultPressureReactionCard(after: after, summary: summary),
           !cards.contains(where: { $0.title == adultPressureCard.title }) {
            cards.append(adultPressureCard)
        }

        if cards.isEmpty, let stakes {
            cards.append(
                YearReactionCard(
                    id: "reaction-stakes-\(after.player.age)",
                    kicker: "What the year made obvious",
                    title: stakes.topPressure.title,
                    detail: stakes.ignoredRisk.detail,
                    domain: stakes.topPressure.domain,
                    tone: stakes.topPressure.tone
                )
            )
        }

        if !cards.contains(where: { $0.kicker == "What stays active" }) {
            if let nextYearPressure = summary?.nextYearPressure {
                cards.append(
                    YearReactionCard(
                        id: "reaction-carryover-\(after.player.age)",
                        kicker: "What stays active",
                        title: nextYearPressure.title,
                        detail: nextYearPressure.detail,
                        domain: nextYearPressure.domain,
                        tone: nextYearPressure.tone
                    )
                )
            } else if let scheduledConsequencePreview {
                cards.append(
                    YearReactionCard(
                        id: "reaction-scheduled-\(after.player.age)",
                        kicker: "What stays active",
                        title: scheduledConsequencePreview.title,
                        detail: scheduledConsequencePreview.detail,
                        domain: scheduledConsequencePreview.domain,
                        tone: scheduledConsequencePreview.tone
                    )
                )
            }
        }

        if let carryoverIndex = cards.firstIndex(where: { $0.kicker == "What stays active" }), carryoverIndex >= 3 {
            cards.remove(at: 2)
            cards.insert(cards.remove(at: carryoverIndex - 1), at: 2)
        }

        return Array(cards.prefix(3))
    }

    private func buildResolutionPreview(
        for state: GameState,
        dominantConsequence: ConsequencePreview?,
        summary: YearlyOutcomeSummary?
    ) -> ResolutionPreview {
        let pendingCallback = state.consequences.scheduledEvents
            .filter { $0.dueAge <= (state.player.age + 2) }
            .sorted { $0.dueAge < $1.dueAge }
            .first
        let pressureCount = state.consequences.pressureByDomain.values.filter { $0 >= 25 }.count
        let pendingCallbackLine = pendingCallback.map { "Coming back: \($0.title ?? "A past choice") at age \($0.dueAge)." }
        let unresolvedLine = summary?.nextYearPressure.map { "Still active: \($0.detail)" }
        let detail: String
        if state.isGameOver {
            let definingPattern = (state.progress.finalLifePath ?? state.progress.currentLifePath)?.rawValue
                .replacingOccurrences(of: "_", with: " ")
                .capitalized ?? "Unfinished"
            let strongestDomainKey = state.consequences.pressureByDomain.max(by: { $0.value < $1.value })?.key
            let strongestDomain = strongestDomainKey.map { dominantPressureLabel(for: $0) } ?? "Life pressure"
            let carriedForward = state.progress.unlockedMilestones.last?.id.rawValue
                ?? state.yearlyStance.lastCompletedStance?.title
                ?? "the years you survived"
            let identityLine = state.currentIdentityPattern.map { " Identity pattern: \($0.title). \($0.legacyLine)" } ?? ""
            detail = "Legacy estimate: \(max(1, state.player.age / 10)) points. Defining pattern: \(definingPattern). Hardest domain: \(strongestDomain). Carried forward: \(carriedForward).\(identityLine)"
        } else if let dominantConsequence {
            detail = [
                "What changed: \(dominantConsequence.title). \(dominantConsequence.detail)",
                unresolvedLine,
                pendingCallbackLine
            ]
                .compactMap { $0 }
                .joined(separator: " ")
        } else if let pendingCallback {
            detail = [
                unresolvedLine,
                "Coming back: \(pendingCallback.title ?? "A past choice") at age \(pendingCallback.dueAge)."
            ]
                .compactMap { $0 }
                .joined(separator: " ")
        } else if pressureCount > 0 {
            detail = unresolvedLine ?? "\(pressureCount) unresolved pressure point\(pressureCount == 1 ? "" : "s") are still shaping the next year."
        } else {
            detail = "The year is closed. Your feed is updated and the next decision is ready."
        }

        return ResolutionPreview(
            id: "resolution-\(state.player.age)",
            title: state.isGameOver ? "Life Closed" : "Return to Feed",
            detail: detail,
            actionTitle: "Back to Feed"
        )
    }

    private func adultPressureReactionCard(
        after state: GameState,
        summary: YearlyOutcomeSummary?
    ) -> YearReactionCard? {
        guard (18...35).contains(state.player.age) else { return nil }

        if state.career.status == .unemployed && state.finance.financialStress >= 45 {
            return YearReactionCard(
                id: "reaction-adult-work-\(state.player.age)",
                kicker: "What adulthood made immediate",
                title: "Work instability became a life problem",
                detail: "Unemployment is no longer isolated to career. It is now changing how rent, recovery, and confidence land year to year.",
                domain: .career,
                tone: .warning
            )
        }

        if state.relationships.hasPartner,
           state.finance.financialStress >= 48,
           state.relationships.partnerBond < 62 {
            return YearReactionCard(
                id: "reaction-adult-relationship-\(state.player.age)",
                kicker: "What adulthood made personal",
                title: "Money pressure is entering the relationship",
                detail: "The strain is no longer abstract budgeting. It is showing up in patience, trust, and how safe the future feels together.",
                domain: .relationships,
                tone: .warning
            )
        }

        if !state.healthProfile.activeConditions.isEmpty,
           state.career.status != .student,
           (state.finance.financialStress >= 35 || state.career.jobSecurity < 55) {
            return YearReactionCard(
                id: "reaction-adult-health-\(state.player.age)",
                kicker: "What the body changed",
                title: "Recovery is setting the pace now",
                detail: "Health is no longer background maintenance. It is affecting work reliability, money resilience, and how much strain the year can absorb.",
                domain: .health,
                tone: .warning
            )
        }

        if summary?.momentum == nil {
            return YearReactionCard(
                id: "reaction-adult-baseline-\(state.player.age)",
                kicker: "What the year made clear",
                title: "Adult life kept compounding quietly",
                detail: "Nothing exploded, but work, money, and recovery still moved together in ways that will matter next year.",
                domain: .progress,
                tone: .neutral
            )
        }

        return nil
    }

    private func syncAmbientContacts(in state: inout GameState) {
        func upsert(_ contact: AmbientContact) {
            if let index = state.relationships.ambientContacts.firstIndex(where: { $0.id == contact.id }) {
                state.relationships.ambientContacts[index] = contact
            } else {
                state.relationships.ambientContacts.append(contact)
            }
        }

        upsert(
            AmbientContact(
                id: "guardian",
                name: "Renee",
                role: .guardian,
                bond: max(45, 72 - state.finance.financialStress / 2),
                reliability: 70,
                cadence: state.player.age < 19 ? .frequent : .regular,
                lastInteractionAge: state.player.age
            )
        )

        let defaultFriendName = state.relationships.friends.first?.name ?? "Maya"
        upsert(
            AmbientContact(
                id: "friend",
                name: defaultFriendName,
                role: .friend,
                bond: max(35, max(state.relationships.friends.strongestBond, state.relationships.partnerBond / 2)),
                reliability: 55,
                cadence: state.player.age < 22 ? .frequent : .regular,
                lastInteractionAge: state.player.age
            )
        )

        if state.education.teacherSupport >= 50 || state.education.mentorSupport >= 40 || state.career.performance >= 70 {
            upsert(
                AmbientContact(
                    id: "mentor",
                    name: state.player.age <= 18 ? "Mr. Alvarez" : "Nadia",
                    role: .mentor,
                    bond: max(state.education.teacherSupport, state.education.mentorSupport, min(80, state.career.performance)),
                    reliability: 78,
                    cadence: .regular,
                    lastInteractionAge: state.player.age
                )
            )
        } else {
            state.relationships.ambientContacts.removeAll { $0.id == "mentor" }
        }

        if let partnerName = state.relationships.partnerName {
            upsert(
                AmbientContact(
                    id: "partner",
                    name: partnerName,
                    role: .partner,
                    bond: state.relationships.partnerBond,
                    reliability: max(45, state.relationships.partnerBond),
                    cadence: .frequent,
                    lastInteractionAge: state.player.age
                )
            )
        } else {
            state.relationships.ambientContacts.removeAll { $0.id == "partner" }
        }
    }

    private func dominantPressureDescriptor(for state: GameState) -> (label: String, detail: String, tone: YearlyOutcomeTone) {
        let money = state.finance.financialStress
        let burnout = max(state.education.burnoutRisk, 100 - state.healthProfile.mentalWellness)
        let schoolMomentum = state.education.schoolStanding + state.education.applicationReadiness - state.education.attendancePressure
        let socialLoad = max((state.relationships.friends + state.relationships.romanticPartners).filter { $0.status == .strained }.count * 20, state.consequences.pressureByDomain["relationships"] ?? 0)

        if money >= max(burnout, schoolMomentum, socialLoad) {
            let label = money >= 55 ? "Money Pressure: Acute" : (money >= 35 ? "Money Pressure: Rising" : "Money Pressure: Stable")
            let detail = money >= 55 ? "Cash strain is shaping the mood of the year before anything else gets a vote." : "The budget still has room, but it no longer feels loose."
            return (label, detail, money >= 35 ? .warning : .neutral)
        }

        if burnout >= max(money, schoolMomentum, socialLoad) {
            let label = burnout >= 60 ? "Burnout: High" : (burnout >= 40 ? "Burnout: Building" : "Burnout: Low")
            let detail = burnout >= 60 ? "Recovery is becoming the thing that decides what the rest of life can absorb." : "You can still steady yourself, but the strain is real."
            return (label, detail, burnout >= 40 ? .warning : .neutral)
        }

        if schoolMomentum <= 80 {
            let label = schoolMomentum < 40 ? "School Momentum: Sliding" : "School Momentum: Shaky"
            let detail = schoolMomentum < 40 ? "The year could close doors if you keep drifting." : "You still have room to stabilize school before it hardens into direction."
            return (label, detail, .warning)
        }

        let label = socialLoad >= 40 ? "Social Life: Unstable" : (socialLoad >= 18 ? "Social Life: Fragile" : "Social Life: Grounded")
        let detail = socialLoad >= 40 ? "People around you are carrying more tension into the year than they are saying out loud." : "Your close life can still support you if you stay present."
        return (label, detail, socialLoad >= 18 ? .warning : .positive)
    }

    private func buildTurnStakesSnapshot(
        for state: GameState,
        targetAge: Int,
        plannedActions: [PlayerYearAction],
        scheduledEvent: ScheduledConsequenceEvent?,
        event: GameEvent?
    ) -> TurnStakesSnapshot {
        let momentumSignal = buildMomentumSignal(for: state)

        return TurnStakesSnapshot(
            focus: buildFocusSignal(for: state, plannedActions: plannedActions),
            topPressure: buildPressureSignal(for: state),
            topOpportunity: buildOpportunitySignal(for: state),
            ignoredRisk: buildIgnoredRiskSignal(for: state, plannedActions: plannedActions, event: event),
            spilloverRisk: buildSpilloverRiskSignal(for: state, targetAge: targetAge, scheduledEvent: scheduledEvent),
            momentum: momentumSignal   // Phase 2 integration
        )
    }

    private func buildMomentumSignal(for state: GameState) -> TurnStakesSignal? {
        let m = state.instantMomentum
        guard m.overallStrength >= 25 else { return nil }

        let strength = m.overallStrength
        let label: String
        if strength >= 65 {
            label = "Powerful Recent Momentum"
        } else if strength >= 50 {
            label = "Strong Recent Focus"
        } else if strength >= 35 {
            label = "Solid Recent Focus"
        } else {
            label = "Recent Focus"
        }

        let detail: String
        if strength >= 60 {
            detail = "Your recent deliberate actions (and the world's reactions) have built real positive momentum heading into this year."
        } else if strength >= 45 {
            detail = "Consistent recent effort is giving this year a noticeably better starting point."
        } else {
            detail = "Some recent focused actions are providing a helpful tailwind."
        }

        return TurnStakesSignal(
            id: "momentum-instant",
            label: "Instant Momentum",
            title: label,
            detail: detail,
            domain: .progress,
            tone: .positive
        )
    }

    private func buildFocusSignal(for state: GameState, plannedActions: [PlayerYearAction]) -> TurnStakesSignal {
        guard let action = plannedActions.first else {
            return TurnStakesSignal(
                id: "focus-unscripted",
                label: "Intent read",
                title: "No Clear Pattern",
                detail: "No lived action stood out this year, so the forecast is reading pressure more than intent.",
                domain: .progress,
                tone: .neutral
            )
        }

        let definition = ActionChoiceCatalog.definition(for: action.choiceID)
        return TurnStakesSignal(
            id: "focus-\(action.choiceID.rawValue)",
            label: "Intent read",
            title: definition.title,
            detail: "\(definition.identityLine) The pressure read treats this as one signal inside a larger pattern.",
            domain: dominantHistoryDomain(for: action.domain.rawValue),
            tone: .neutral
        )
    }

    private func buildPressureSignal(for state: GameState) -> TurnStakesSignal {
        let pressure = dominantPressureDescriptor(for: state)
        let domain = dominantPressureDomain(for: state)

        var finalDetail = pressure.detail

        // Phase 2 (future): Instant momentum can soften pressure reads in the forecast.
        // Currently the bias lives in preferredEventWeights + applyInstantMomentumBenefits.
        if state.instantMomentum.overallStrength >= 35 {
            finalDetail += " Recent focused action has taken some of the edge off."
        }

        return TurnStakesSignal(
            id: "pressure-\(domain.rawValue)",
            label: pressure.label,
            title: "Pressure Read",
            detail: finalDetail,
            domain: domain,
            tone: pressure.tone
        )
    }

    private func buildOpportunitySignal(for state: GameState) -> TurnStakesSignal {
        if state.finance.cashOnHand > 7_500 && state.finance.financialStress < 32 && state.finance.lastYearBalanceDelta >= 0 {
            return TurnStakesSignal(
                id: "opportunity-finance",
                label: "Opening",
                title: "The budget can absorb a measured move",
                detail: "You have enough margin for a practical step that could turn into steadier breathing room, not fantasy upside.",
                domain: .finance,
                tone: .positive
            )
        }
        if state.education.schoolStanding >= 68 || state.career.performance >= 68 {
            return TurnStakesSignal(
                id: "opportunity-direction",
                label: "Opening",
                title: "Effort can still convert",
                detail: "You have enough standing that this year could open a better door if you stay deliberate.",
                domain: state.player.age < 18 ? .education : .career,
                tone: .positive
            )
        }
        return TurnStakesSignal(
            id: "opportunity-survival",
            label: "Opening",
            title: "The year is still recoverable",
            detail: "Nothing is easy, but there is still room to convert pressure into stability before it hardens into a worse pattern.",
            domain: .progress,
            tone: .neutral
        )
    }

    private func buildIgnoredRiskSignal(
        for state: GameState,
        plannedActions: [PlayerYearAction],
        event: GameEvent?
    ) -> TurnStakesSignal {
        guard let action = plannedActions.first else {
            return TurnStakesSignal(
                id: "risk-drift",
                label: "If ignored",
                title: "Drift gets a vote",
                detail: "Without a clear recent action, the next event is more likely to follow the strongest pressure already on the board.",
                domain: .progress,
                tone: .warning
            )
        }

        let definition = ActionChoiceCatalog.definition(for: action.choiceID)
        return TurnStakesSignal(
            id: "risk-\(action.choiceID.rawValue)",
            label: "If ignored",
            title: "This action can still miss",
            detail: "If \(definition.title.lowercased()) does not hold, the cost is most likely to show up in \(dominantHistoryDomain(for: action.domain.rawValue).rawValue). \(event.map { "\($0.title) is likely to hit that weak spot early." } ?? "")",
            domain: dominantHistoryDomain(for: action.domain.rawValue),
            tone: .warning
        )
    }

    private func buildSpilloverRiskSignal(
        for state: GameState,
        targetAge: Int,
        scheduledEvent: ScheduledConsequenceEvent?
    ) -> TurnStakesSignal {
        if let scheduledEvent {
            return TurnStakesSignal(
                id: "spillover-callback-\(scheduledEvent.id)",
                label: "Likely spillover",
                title: scheduledEvent.title ?? "A past choice is already coming back",
                detail: scheduledEvent.callbackFramingText ?? scheduledEvent.detail ?? "A previous decision already has unfinished business waiting at age \(scheduledEvent.dueAge).",
                domain: .lifeEvent,
                tone: .warning
            )
        }

        if let strongest = state.consequences.pressureByDomain.max(by: { $0.value < $1.value }), strongest.value >= 18 {
            return TurnStakesSignal(
                id: "spillover-\(strongest.key)",
                label: "Likely spillover",
                title: dominantPressureLabel(for: strongest.key),
                detail: "What happens here is likely to leak into another part of life before age \(targetAge).",
                domain: dominantHistoryDomain(for: strongest.key),
                tone: strongest.value >= 30 ? .warning : .neutral
            )
        }

        return TurnStakesSignal(
            id: "spillover-none",
            label: "Likely spillover",
            title: "No single crack is dominant yet",
            detail: "The year can still get more expensive elsewhere if one pressure point goes ignored for too long.",
            domain: .progress,
            tone: .neutral
        )
    }

    private func dominantPressureDomain(for state: GameState) -> HistoryDomainTag {
        if let strongest = state.consequences.pressureByDomain.max(by: { $0.value < $1.value }), strongest.value >= 18 {
            return dominantHistoryDomain(for: strongest.key)
        }

        let money = state.finance.financialStress
        let burnout = max(state.education.burnoutRisk, 100 - state.healthProfile.mentalWellness)
        let schoolMomentum = state.education.schoolStanding + state.education.applicationReadiness - state.education.attendancePressure
        let socialLoad = max((state.relationships.friends + state.relationships.romanticPartners).filter { $0.status == .strained }.count * 20, state.consequences.pressureByDomain["relationships"] ?? 0)

        if money >= max(burnout, schoolMomentum, socialLoad) { return .finance }
        if burnout >= max(money, schoolMomentum, socialLoad) { return .health }
        if schoolMomentum <= 80 { return .education }
        return .relationships
    }

    private func anticipationDescriptor(
        for state: GameState,
        targetAge: Int,
        scheduledEvent: ScheduledConsequenceEvent?,
        event: GameEvent?
    ) -> (title: String, detail: String) {
        if let scheduledEvent {
            return (
                scheduledEvent.title ?? "A past choice is coming back",
                scheduledEvent.callbackFramingText ?? scheduledEvent.detail ?? "Something from last year is still moving toward you."
            )
        }

        switch targetAge {
        case 15:
            return ("Independence Pressure Is Rising", "Money, image, and belonging start sticking to each other more at fifteen.")
        case 16:
            return ("Work Search Opens", "Cash and time start competing with school more directly now.")
        case 17:
            return ("Adult Direction Tightens", "Applications, training exits, and drift all get harder to ignore.")
        case 18:
            return ("The School-To-Adult Split Is Here", "Debt, work, and consequence now land harder and stick longer.")
        case 19...22:
            return ("Early Adulthood Will Test The Build", "The year ahead wants proof that your direction can survive pressure.")
        default:
            break
        }

        if state.education.schoolStanding >= 72 && state.education.teacherSupport >= 60 && targetAge <= 18 {
            return ("A Recommendation Window Is Nearby", "If you stay visible and steady, adults at school may turn effort into a real door.")
        }
        if state.finance.cashOnHand < 0 || state.finance.financialStress >= 45 {
            return ("The Margin Is Getting Tighter", "The next bill or bad week could turn strain into a visible squeeze.")
        }
        if state.relationships.hasPartner && state.relationships.partnerBond < 55 {
            return ("The Relationship Needs A Clearer Read", "Distance is easier to create than to undo once the year gets busy.")
        }
        if state.healthProfile.mentalWellness < 48 || !state.healthProfile.activeConditions.isEmpty {
            return ("Your Body Is Not Starting Fresh", "The next year will inherit more strain than it can hide.")
        }
        if let event {
            return ("The World Already Has A Lead", "The next live beat is \(event.title.lowercased()), and it is likely to shape the tone early.")
        }

        let base = "Even a quiet year is already leaning somewhere based on what you have been carrying."
        // Phase 5: Subtle but visceral tone difference based on Life Feel
        if state.resilience == .grounded {
            return ("Nothing Is Fully Settled", base + " Grounded lives rarely stay quiet for long.")
        }
        return ("Nothing Is Fully Settled", base)
    }

    private func preferredAmbientContact(for state: GameState, event: GameEvent?) -> AmbientContact? {
        if let event, event.tags.contains("romance"), let partner = state.relationships.ambientContacts.first(where: { $0.role == .partner }) {
            return partner
        }
        if let event, (event.tags.contains("school") || event.tags.contains("career")), let mentor = state.relationships.ambientContacts.first(where: { $0.role == .mentor }) {
            return mentor
        }
        if let event, (event.tags.contains("money") || event.tags.contains("cost")), let guardian = state.relationships.ambientContacts.first(where: { $0.role == .guardian }) {
            return guardian
        }
        return state.relationships.strongestAmbientContact
    }

    private func contactKicker(for role: AmbientContactRole) -> String {
        switch role {
        case .friend:
            return "From your circle"
        case .guardian:
            return "At home"
        case .mentor:
            return "From someone older"
        case .partner:
            return "In your relationship"
        }
    }

    private func domainFor(_ role: AmbientContactRole) -> HistoryDomainTag {
        switch role {
        case .guardian, .friend, .partner:
            return .relationships
        case .mentor:
            return .education
        }
    }

    private func reactionDetail(
        for contact: AmbientContact,
        focus: ActionChoiceDefinition,
        state: GameState,
        event: GameEvent?
    ) -> String {
        switch contact.role {
        case .friend:
            return "\(contact.name) can tell you are living differently now. \(focus.identityLine)"
        case .guardian:
            return "\(contact.name) is reading the year through money, stability, and whether you still seem reachable."
        case .mentor:
            return "\(contact.name) notices the pattern behind your choices more than the headline. \(event?.title ?? "This year") is making your direction easier to read."
        case .partner:
            return "\(contact.name) is starting to interpret your pace as part of the relationship, not just your private struggle."
        }
    }

    private func choiceIDFor(choice: EventChoice, in plannedActions: [PlayerYearAction]) -> ActionChoiceID? {
        plannedActions.first?.choiceID
    }

    private func forecastActions(for state: GameState) -> [PlayerYearAction] {
        // Committed (macro) choices win per domain; instant taps this age fill gaps for event-weight synergy.
        var byDomain: [ActionDomain: PlayerYearAction] = [:]
        for action in state.actionMemory.actionsThisAge {
            byDomain[action.domain] = action
        }
        for action in state.pendingActions {
            byDomain[action.domain] = action
        }
        return ActionDomain.allCases.compactMap { byDomain[$0] }
    }

    private func append(_ result: DomainYearResult, to state: inout GameState) {
        guard !result.notes.isEmpty else { return }
        for note in result.notes.reversed() {
            state.history.insert(
                HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: resolvedHistoryTags(for: note)),
                at: 0
            )
        }
        enforceHistoryBudget(on: &state)
    }

    private func record(_ result: DomainYearResult, in state: inout GameState, results: inout [DomainYearResult]) {
        results.append(result)
        var modifiedResult = result
        var autoResolvedTexts: [String] = []

        for event in result.events {
            // Friction Budget: Auto-resolve routine events
            if event.severity == .routine {
                if let firstChoice = event.choices.first {
                    applyEventChoice(firstChoice, event: event, state: &state)
                    autoResolvedTexts.append("• **\(event.title)**: \(event.text) (You chose: \(firstChoice.text))")
                }
            } else {
                eventEngine.registerDynamicEvent(event)
            }
        }

        if !autoResolvedTexts.isEmpty {
            let digestNote = DomainNote(
                title: "Minor Events Digest",
                text: autoResolvedTexts.joined(separator: "\n\n"),
                tags: [.lifeEvent, .relationships]
            )
            modifiedResult.notes.append(digestNote)
        }

        append(modifiedResult, to: &state)
    }

    private func applyEventChoice(_ choice: EventChoice, event: GameEvent, state: inout GameState) {
        effectApplier.applyCoreEffects(choice.effects.core, to: &state.player)

        if let educationEffects = choice.effects.education {
            educationSystem.apply(effect: educationEffects, education: &state.education)
        }

        if let careerEffects = choice.effects.career {
            careerSystem.apply(effect: careerEffects, player: &state.player, career: &state.career, finance: &state.finance)
        }

        if let specialCareerEffects = choice.effects.specialCareer {
            effectApplier.apply(
                result: DomainYearResult(specialCareerEffects: specialCareerEffects),
                to: &state,
                trajectorySystem: trajectorySystem,
                educationSystem: educationSystem,
                careerSystem: careerSystem,
                specialCareerSystem: specialCareerSystem,
                militarySystem: militarySystem,
                crimeSystem: crimeSystem,
                financeSystem: financeSystem,
                relationshipSystem: relationshipSystem,
                healthSystem: healthSystem,
                housingSystem: housingSystem
            )
        }

        if let crimeEffects = choice.effects.crime {
            effectApplier.apply(
                result: DomainYearResult(crimeEffects: crimeEffects),
                to: &state,
                trajectorySystem: trajectorySystem,
                educationSystem: educationSystem,
                careerSystem: careerSystem,
                specialCareerSystem: specialCareerSystem,
                militarySystem: militarySystem,
                crimeSystem: crimeSystem,
                financeSystem: financeSystem,
                relationshipSystem: relationshipSystem,
                healthSystem: healthSystem,
                housingSystem: housingSystem
            )
        }

        if let financeEffects = choice.effects.finance {
            financeSystem.apply(effect: financeEffects, finance: &state.finance, player: &state.player)
        }

        if let relationshipEffects = choice.effects.relationship {
            relationshipSystem.apply(effect: relationshipEffects, to: &state.relationships)
        }

        if let healthEffects = choice.effects.health {
            healthSystem.apply(effect: healthEffects, player: &state.player, health: &state.healthProfile)
        }

        if let housingEffects = choice.effects.housing {
            housingSystem.apply(effect: housingEffects, housing: &state.housing)
        }

        if let assetEffects = choice.effects.assets {
            effectApplier.applyAssetEffects(assetEffects, to: &state.assets)
        }

        if let consequenceEffects = choice.effects.consequence {
            applyConsequenceEffects(consequenceEffects, event: event, choice: choice, to: &state)
        } else if let firstFollowUpID = event.followUpEventIDs.first {
            state.consequences.scheduledEvents.append(
                ScheduledConsequenceEvent(
                    eventID: firstFollowUpID,
                    dueAge: state.player.age + 1,
                    title: event.title,
                    detail: "Last year's choice in \(event.title) is still unfolding.",
                    sourceEventID: event.id,
                    sourceEventTitle: event.title,
                    sourceChoiceText: choice.text,
                    callbackFramingText: "What you decided in \(event.title) is still echoing into the next year."
                )
            )
        }
    }

    private func apply(result: DomainYearResult, to state: inout GameState) {
        effectApplier.apply(
            result: result,
            to: &state,
            trajectorySystem: trajectorySystem,
            educationSystem: educationSystem,
            careerSystem: careerSystem,
            specialCareerSystem: specialCareerSystem,
            militarySystem: militarySystem,
            crimeSystem: crimeSystem,
            financeSystem: financeSystem,
            relationshipSystem: relationshipSystem,
            healthSystem: healthSystem,
            housingSystem: housingSystem
        )
    }

    private func updateRelationshipMilestones(in relationships: inout RelationshipState) {
        if let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
            var partner = relationships.romanticPartners[index]
            if partner.stage == .married {
                partner.isCohabiting = true
            }
            relationships.romanticPartners[index] = partner
        }
    }

    private func buildYearCards(
        summary: YearlyOutcomeSummary?,
        primaryEvent: GameEvent?,
        consequencePreview: ConsequencePreview?,
        state: GameState
    ) -> [InteractionCardPayload] {
        var cards: [InteractionCardPayload] = []
        if let summary {
            cards.append(.yearSummary(summary))
        }
        if let primaryEvent {
            cards.append(.event(primaryEvent))
        }
        if let consequencePreview, cards.count < 3 {
            cards.append(.consequence(consequencePreview))
        }

        let pendingCount = state.consequences.scheduledEvents.filter { $0.dueAge <= (state.player.age + 2) }.count
        let pressureCount = state.consequences.pressureByDomain.values.filter { $0 >= 25 }.count
        let resolutionDetail: String
        if state.isGameOver {
            resolutionDetail = "Your body finally gave out under the weight of the years behind you."
        } else if pendingCount > 0 || pressureCount > 0 {
            resolutionDetail = "\(pressureCount) unresolved pressure point\(pressureCount == 1 ? "" : "s") and \(pendingCount) pending callback\(pendingCount == 1 ? "" : "s") are still shaping the next year."
        } else {
            resolutionDetail = "The year is closed. Your feed is updated and the next decision is ready."
        }
        cards.append(
            .resolution(
                ResolutionPreview(
                    id: "resolution-\(state.player.age)",
                    title: state.isGameOver ? "Life Closed" : "Return to Feed",
                    detail: resolutionDetail,
                    actionTitle: "Back to Feed"
                )
            )
        )
        return Array(cards.prefix(4))
    }

    private func consumeDueConsequenceEvent(from state: inout GameState, dueBy age: Int) -> (ScheduledConsequenceEvent, GameEvent)? {
        guard let dueIndex = state.consequences.scheduledEvents
            .enumerated()
            .filter({ $0.element.dueAge <= age })
            .sorted(by: { $0.element.dueAge < $1.element.dueAge })
            .map(\.offset)
            .first else {
            return nil
        }

        let scheduled = state.consequences.scheduledEvents.remove(at: dueIndex)
        guard let event = eventEngine.event(withID: scheduled.eventID) else { return nil }
        return (scheduled, event)
    }

    private func buildConsequencePreview(for state: GameState, summary: YearlyOutcomeSummary?) -> ConsequencePreview? {
        guard let strongest = state.consequences.pressureByDomain.max(by: { $0.value < $1.value }), strongest.value >= 18 else {
            return nil
        }

        let domain = dominantHistoryDomain(for: strongest.key)
        let detailSuffix = summary?.topProblem?.detail ?? "Something you set in motion is still shaping the next year."
        let (title, detail): (String, String)
        switch strongest.key {
        case "finance":
            title = "Money Pressure Is Lingering"
            detail = strongest.value >= 35
                ? "Short-term fixes still haven't fully absorbed the cash strain. \(detailSuffix)"
                : "Your budget got through the year, but the margin still feels thin. \(detailSuffix)"
        case "health":
            title = "Your Body Is Keeping Score"
            detail = strongest.value >= 35
                ? "The pace you've been carrying is starting to feel durable instead of temporary. \(detailSuffix)"
                : "Recovery is helping, but some strain is still traveling with you. \(detailSuffix)"
        case "relationships":
            title = "Close Life Needs Attention"
            detail = strongest.value >= 35
                ? "Neglect or tension is starting to harden into distance. \(detailSuffix)"
                : "Things are still workable, but they no longer feel fully settled. \(detailSuffix)"
        case "career", "education":
            title = "Momentum Has A Price"
            detail = strongest.value >= 35
                ? "What looked like progress is starting to come bundled with more pressure. \(detailSuffix)"
                : "The upside is real, but it is beginning to ask something back from you. \(detailSuffix)"
        default:
            title = "Consequences Are Still Moving"
            detail = detailSuffix
        }

        return ConsequencePreview(
            id: "consequence-\(strongest.key)-\(state.player.age)",
            title: title,
            detail: detail,
            domain: domain,
            tone: strongest.value >= 30 ? .warning : .neutral
        )
    }

    private func dominantHistoryDomain(for key: String) -> HistoryDomainTag {
        switch key {
        case "education": return .education
        case "career": return .career
        case "finance": return .finance
        case "relationships": return .relationships
        case "health": return .health
        case "housing": return .housing
        default: return .lifeEvent
        }
    }

    private func dominantPressureLabel(for key: String) -> String {
        switch key {
        case "education": return "School pressure"
        case "career": return "Career pressure"
        case "finance": return "Money pressure"
        case "relationships": return "Relationship pressure"
        case "health": return "Health pressure"
        case "housing": return "Housing pressure"
        default: return "Unresolved pressure"
        }
    }

    @discardableResult
    private func applyActionDrivenConsequenceAdjustments(_ actions: [PlayerYearAction], to consequences: inout ConsequenceState) -> [String: Int] {
        var deltas: [String: Int] = [:]

        func adjust(_ domain: String, _ delta: Int) {
            consequences.adjustPressure(domain: domain, delta: delta)
            deltas[domain, default: 0] += delta
        }

        for action in actions {
            switch action.choiceID {
            case .buildEmergencyFund, .cutSpending, .saveForDownPayment, .buildMaintenanceReserve, .depositToHouseFund, .topUpHouseReserve:
                adjust("finance", -6)
            case .spendForRelief, .spendToCope:
                adjust("finance", 4)
            case .takeExtraShifts, .takeSideWork, .smallHustle:
                adjust("finance", -3)
                adjust("health", 4)
            case .rest, .protectSleep, .seeDoctor:
                adjust("health", -8)
            case .pushThrough:
                adjust("health", 7)
                adjust("career", 2)
            case .repairTension, .strengthenBond, .discussFuture:
                adjust("relationships", -8)
            case .keepDistance, .stayInvisible:
                adjust("relationships", 5)
            case .workHard, .network, .retrain, .chaseSpotlight, .studyConsistently, .buildPortfolio:
                adjust("career", 4)
                adjust("health", 2)
            case .protectYourEnergy:
                adjust("career", -1)
                adjust("health", -6)
                adjust("relationships", -3)
            case .coast, .layLow:
                adjust("career", -2)
            case .takeOvertime:
                adjust("finance", -4)
                adjust("relationships", 6)
            case .jobHunt:
                adjust("career", -5)
            default:
                break
            }
        }

        return deltas
    }

    private func applyConsequenceEffects(_ effects: ConsequenceEffects, event: GameEvent, choice: EventChoice, to state: inout GameState) {
        for flag in effects.setFlags {
            state.consequences.narrativeFlags[flag] = state.player.age
        }
        for flag in effects.clearFlags {
            state.consequences.narrativeFlags.removeValue(forKey: flag)
        }
        for (domain, delta) in effects.pressureChanges {
            state.consequences.adjustPressure(domain: domain, delta: delta)
        }
        for scheduled in effects.scheduleEvents {
            state.consequences.scheduledEvents.append(
                ScheduledConsequenceEvent(
                    eventID: scheduled.eventID,
                    dueAge: state.player.age + max(1, scheduled.yearsFromNow),
                    title: scheduled.title,
                    detail: scheduled.detail,
                    sourceEventID: event.id,
                    sourceEventTitle: event.title,
                    sourceChoiceText: choice.text,
                    callbackFramingText: scheduled.detail ?? "The consequences of \(choice.text.lowercased()) are still moving."
                )
            )
        }
    }

    private func enforceHistoryBudget(on state: inout GameState) {
        guard state.history.count > PerformanceBudgets.maxPersistedHistoryItems else { return }
        state.history = Array(state.history.prefix(PerformanceBudgets.maxPersistedHistoryItems))
    }

    private func measure(_ label: String, _ block: () -> DomainYearResult) -> DomainYearResult {
        #if DEBUG
        let start = CFAbsoluteTimeGetCurrent()
        let result = block()
        let duration = millisecondsSince(start)
        currentTimingEntries.removeAll { $0.label == label }
        currentTimingEntries.append(SimulationTimingEntry(label: label, durationMilliseconds: duration))
        return result
        #else
        return block()
#endif
    }

    private func millisecondsSince(_ start: CFAbsoluteTime) -> Double {
        ((CFAbsoluteTimeGetCurrent() - start) * 1_000).rounded()
    }

    private func preferredEventWeights(
        for world: WorldSnapshot,
        extraTags: [String] = [],
        extraWeights: [String: Int] = [:]
    ) -> [String: Int] {
        var weights = storyletSystem.preferredTagWeights(for: world)
        for tag in extraTags {
            weights[tag, default: 0] += 4
        }
        for (tag, weight) in extraWeights {
            weights[tag, default: 0] += weight
        }
        for (tag, weight) in consequenceEventWeights(for: world.state) {
            weights[tag, default: 0] += weight
        }
        for (tag, weight) in world.state.activities.preferredEventWeights() {
            weights[tag, default: 0] += weight
        }
        if let pattern = world.state.currentIdentityPattern {
            for (tag, weight) in pattern.eventWeights {
                weights[tag, default: 0] += weight
            }
        }

        // Phase 3: Stronger Instant ↔ Yearly Integration
        // Domain-specific momentum now meaningfully shapes the year's event pool and reduces bad luck.
        let m = world.state.instantMomentum
        if m.overallStrength >= 30 {
            // General positive tailwind
            weights["positive", default: 0] += max(2, m.overallStrength / 18)
            weights["opportunity", default: 0] += max(1, m.overallStrength / 22)

            // Per-domain bias (the heart of Phase 3)
            if m.healthMomentum >= 28 {
                weights["health", default: 0] += m.healthMomentum / 10
                weights["recovery", default: 0] += m.healthMomentum / 14
            }
            if m.financeMomentum >= 28 {
                weights["money", default: 0] += m.financeMomentum / 9
                weights["opportunity", default: 0] += m.financeMomentum / 16
            }
            if m.relationshipMomentum >= 28 {
                weights["family", default: 0] += m.relationshipMomentum / 9
                weights["social", default: 0] += m.relationshipMomentum / 12
                weights["romance", default: 0] += m.relationshipMomentum / 15
            }

            // High overall momentum dampens crisis/risk pull
            if m.overallStrength >= 50 {
                weights["risk", default: 0] = max(0, (weights["risk"] ?? 6) - max(2, m.overallStrength / 20))
                weights["crisis", default: 0] = max(0, (weights["crisis"] ?? 4) - max(1, m.overallStrength / 25))
            }
        }

        // Fame Web F2: High recognition changes the event pool (scrutiny + opportunity)
        let worldFame = world.state.fame
        if worldFame.recognition >= 40 {
            if worldFame.culturalFame >= 50 {
                weights["opportunity", default: 0] += 6
                weights["social", default: 0] += 4
                weights["career", default: 0] += 3
            }
            if worldFame.notoriety >= 50 {
                weights["risk", default: 0] += 8
                weights["crisis", default: 0] += 5
                weights["scandal", default: 0] += 6
            }
            if worldFame.recognition >= 65 {
                // Very famous people attract bigger swings (good and bad)
                weights["positive", default: 0] += 3
                weights["negative", default: 0] += 3
            }
        }

        // Econ2: Deep economic character bias in the event pool + path-specific storytelling gravity
        // The economy doesn't just change numbers — it changes what stories feel possible and inevitable.
        let worldEra = world.state.currentEra
        let worldSCTrack = world.state.specialCareer.track
        let worldSC = world.state.specialCareer

        switch worldEra {
        case .recession:
            weights["risk", default: 0] += 7
            weights["crisis", default: 0] += 5
            weights["money", default: 0] += 5
            weights["negative", default: 0] += 4
            weights["scandal", default: 0] += 2

            // Politics in recession = populist rise or establishment scapegoating
            if worldSCTrack == .politics {
                weights["social", default: 0] += 7
                weights["career", default: 0] += 5
                if worldSC.politics.approvalRating < 45 { weights["opportunity", default: 0] += 3 } // outsider opening
            }
            // Creators in recession = authenticity wins or brutal sponsor flight
            if worldSCTrack == .contentCreator {
                weights["social", default: 0] += 6
                if worldSC.creator.personalBrand < 45 { weights["positive", default: 0] += 3 }
            }
            // Founders feel the capital winter
            if worldSCTrack == .founder {
                weights["risk", default: 0] += 4
                weights["negative", default: 0] += 3
            }
            // Athletes lose the commercial layer
            if worldSCTrack == .athlete {
                weights["money", default: 0] += 4
                weights["negative", default: 0] += 2
            }

        case .bullMarket, .techBoom:
            weights["opportunity", default: 0] += 8
            weights["positive", default: 0] += 5
            weights["money", default: 0] += 6
            weights["career", default: 0] += 5

            if worldSCTrack == .founder {
                weights["social", default: 0] += 5
                weights["opportunity", default: 0] += 4 // capital chases founders
            }
            if worldSCTrack == .athlete {
                weights["social", default: 0] += 4
                weights["positive", default: 0] += 3 // winners get mythologized
            }
            if worldSCTrack == .contentCreator && worldSC.creator.personalBrand >= 50 {
                weights["positive", default: 0] += 4 // aspiration content performs
            }
            if worldSCTrack == .politics && worldSC.politics.ethics < 50 {
                weights["money", default: 0] += 4 // donor class is feeling generous
            }

        case .highInflation:
            weights["risk", default: 0] += 5
            weights["money", default: 0] += 7
            weights["negative", default: 0] += 4
            weights["crisis", default: 0] += 2
            // Everyone feels squeezed; creators and politicians get specific pressure
            if worldSCTrack == .contentCreator {
                weights["social", default: 0] += 4
            }
            if worldSCTrack == .politics {
                weights["career", default: 0] += 4
            }

        case .pandemic, .wartime:
            weights["crisis", default: 0] += 8
            weights["health", default: 0] += 6
            weights["social", default: 0] += 4
            weights["negative", default: 0] += 5
            weights["risk", default: 0] += 3
            // All special careers get narrative gravity in national crisis
            if worldSCTrack != .inactive {
                weights["career", default: 0] += 4
                weights["social", default: 0] += 3
            }

        default:
            break
        }

        return weights
    }

    private func consequenceEventWeights(for state: GameState) -> [String: Int] {
        let mapping: [String: [String: Int]] = [
            "career": ["career": 8, "money": 4, "routine": 3],
            "finance": ["money": 8, "housing": 5, "health": 2],
            "health": ["health": 8, "routine": 4, "career": 3],
            "relationships": ["relationships": 8, "romance": 6, "family": 4],
            "housing": ["housing": 8, "money": 5, "health": 2],
            "education": ["school": 8, "routine": 4, "career": 3]
        ]

        var weights: [String: Int] = [:]
        for (domain, pressure) in state.consequences.pressureByDomain where pressure >= 20 {
            guard let tagWeights = mapping[domain] else { continue }
            let multiplier = max(1, pressure / 20)
            for (tag, baseWeight) in tagWeights {
                weights[tag, default: 0] += baseWeight * multiplier
            }
        }
        return weights
    }

    private func committedActionWeights(
        from actionWeights: [String: Int],
        plannedActions: [PlayerYearAction]
    ) -> [String: Int] {
        guard !plannedActions.isEmpty else {
            return actionWeights.merging(["chance": 2, "risk": 1]) { lhs, rhs in lhs + rhs }
        }

        return actionWeights.reduce(into: [String: Int]()) { partial, pair in
            partial[pair.key, default: 0] += pair.value + 3
        }
    }

    private func rebuildWorldSnapshot(from state: GameState) -> WorldSnapshot {
        let snapshot = worldSnapshotBuilder.build(from: state)
        latestWorldSnapshot = snapshot
        return snapshot
    }

    private func refreshGeneratedCaches(for state: GameState) {
        refreshGeneratedCaches(for: state, snapshot: nil)
    }

    /// Phase 1 optimization: Allow passing a pre-built snapshot to avoid extra rebuilds during instant actions.
    private func refreshGeneratedCaches(for state: GameState, snapshot: WorldSnapshot? = nil) {
        let snapshot = snapshot ?? rebuildWorldSnapshot(from: state)
        domainCacheCoordinator.refreshArtifacts(for: snapshot)
        domainCacheCoordinator.refreshOnIdle(for: snapshot)
    }

    private func historyTags(for category: EventCategory) -> [HistoryDomainTag] {
        switch category {
        case .general:
            return [.lifeEvent]
        case .education:
            return [.lifeEvent, .education]
        case .career:
            return [.lifeEvent, .career]
        case .finance:
            return [.lifeEvent, .finance]
        case .relationships:
            return [.lifeEvent, .relationships]
        case .social:
            return [.lifeEvent, .relationships]
        case .health:
            return [.lifeEvent, .health]
        }
    }

    private func resolvedHistoryTags(for note: DomainNote) -> [HistoryDomainTag] {
        if !note.tags.isEmpty {
            return note.tags
        }

        let title = note.title.lowercased()
        var tags: [HistoryDomainTag] = []

        if title.contains("education") || title.contains("school") || title.contains("training") {
            tags.append(.education)
        }
        if title.contains("career") || title.contains("promotion") {
            tags.append(.career)
        }
        if title.contains("finance") || title.contains("stress") {
            tags.append(.finance)
        }
        if title.contains("relationship") {
            tags.append(.relationships)
        }
        if title.contains("health") {
            tags.append(.health)
        }
        if title.contains("housing") || title.contains("home") {
            tags.append(.housing)
        }
        if title.contains("milestone") || title.contains("legacy") {
            tags.append(.progress)
        }

        return tags
    }

    private func synergyContextLine(for plannedActions: [PlayerYearAction]) -> String {
        guard plannedActions.count >= 2 else { return "" }
        let first = ActionChoiceCatalog.definition(for: plannedActions[0].choiceID).title
        let second = ActionChoiceCatalog.definition(for: plannedActions[1].choiceID).title
        return " Mix thread: \(first) plus \(second) is bending which headline finds you."
    }

    /// Lightweight pressure nudges so the map moves between Age Ups without a full yearly sim.
    func applyAmbientPressureSync(state: inout GameState) {
        AmbientPressureSync.applyNudges(to: &state)
    }
}
