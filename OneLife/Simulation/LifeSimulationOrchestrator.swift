import Foundation

final class LifeSimulationOrchestrator {
    private let eventEngine: EventEngine
    private let originSystem: OriginSystem
    private let narrativeArcSystem: NarrativeArcSystem
    private let traitSystem: TraitSystem
    private let storyletSystem: StoryletSystem
    private let actionSystem: ActionSystem
    private let actionCorrelationSystem: ActionCorrelationSystem
    private let policySystem: PolicySystem
    private let trajectorySystem: TrajectorySystem
    private let educationSystem: EducationSystem
    private let careerSystem: CareerSystem
    private let specialCareerSystem: SpecialCareerSystem
    private let crimeSystem: CrimeSystem
    private let financeSystem: FinanceSystem
    private let investmentSystem: InvestmentSystem
    private let relationshipSystem: RelationshipSystem
    private let familySystem: FamilySystem
    private let healthSystem: HealthSystem
    private let housingSystem: HousingSystem
    private let homeOwnershipSystem: HomeOwnershipSystem
    private let progressSystem: ProgressSystem
    private let crossDomainPressureSystem: CrossDomainPressureSystem
    private let worldAutonomySystem: WorldAutonomySystem
    private let npcAutonomySystem: NPCAutonomySystem
    private let continuityThreadEngine: ContinuityThreadEngine
    private let silentYearEngine: SilentYearEngine
    private let yearlyOutcomeAggregator: YearlyOutcomeAggregator
    private let systemRegistry: SystemRegistry
    private let worldSnapshotBuilder: WorldSnapshotBuilder
    private let effectApplier: DomainEffectApplier
    private let domainCacheCoordinator: DomainCacheGenerationCoordinator
    #if DEBUG
    private(set) var latestTimingSnapshot: SimulationTimingSnapshot?
    private var currentTimingEntries: [SimulationTimingEntry] = []
    #endif
    private(set) var latestYearSummary: YearlyOutcomeSummary?
    private(set) var latestWorldSnapshot: WorldSnapshot?

    init(
        eventEngine: EventEngine = EventEngine(),
        originSystem: OriginSystem = OriginSystem(),
        narrativeArcSystem: NarrativeArcSystem = NarrativeArcSystem(),
        traitSystem: TraitSystem = TraitSystem(),
        storyletSystem: StoryletSystem = StoryletSystem(),
        actionSystem: ActionSystem = ActionSystem(),
        actionCorrelationSystem: ActionCorrelationSystem = ActionCorrelationSystem(),
        policySystem: PolicySystem = PolicySystem(),
        trajectorySystem: TrajectorySystem = TrajectorySystem(),
        educationSystem: EducationSystem = EducationSystem(),
        careerSystem: CareerSystem = CareerSystem(),
        specialCareerSystem: SpecialCareerSystem = SpecialCareerSystem(),
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
    }

    func initialize(state: inout GameState) -> GameEvent? {
        state = originSystem.makePreview(mode: .quickStart, templateID: nil, narrativeArcSystem: narrativeArcSystem, meta: MetaState())
        return activatePreview(state: &state)
    }

    func initialEvent(for state: GameState) -> GameEvent? {
        let world = rebuildWorldSnapshot(from: state)
        return eventEngine.pickEvent(for: state, preferredTagWeights: preferredEventWeights(for: world))
    }

    func previewStart(mode: StartMode, templateID: OriginTemplateID?, meta: MetaState) -> GameState {
        originSystem.makePreview(mode: mode, templateID: templateID, narrativeArcSystem: narrativeArcSystem, meta: meta)
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
        state.activeYearChapter = nil
        refreshGeneratedCaches(for: state)

        var cards: [InteractionCardPayload] = []
        if let summary = outcome.summary {
            cards.append(.yearSummary(summary))
        }
        if let event {
            cards.append(.event(event))
        }
        if let consequence = chapter.pendingConsequencePreview {
            cards.append(.consequence(consequence))
        }
        if let resolution = chapter.pendingResolution {
            cards.append(.resolution(resolution))
        }
        return YearAdvanceOutcome(summary: outcome.summary, cards: cards)
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
        state.activeYearChapter = nil // Instant resolution
        refreshGeneratedCaches(for: state)
        return YearAdvanceOutcome(summary: outcome.summary, cards: [])
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

    func applyImmediateAction(_ choiceID: ActionChoiceID, domain: ActionDomain, state: inout GameState) -> DomainYearResult {
        let action = PlayerYearAction(domain: domain, choiceID: choiceID)
        let world = rebuildWorldSnapshot(from: state)
        
        let result = actionSystem.apply(actions: [action], state: &state, world: world, clearsPendingActions: false)
        state.actionMemory.record(action: action, age: state.player.age)
        let pressureDeltas = applyActionDrivenConsequenceAdjustments([action], to: &state.consequences)
        actionCorrelationSystem.record(action: action, age: state.player.age, pressureDeltas: pressureDeltas, state: &state)
        
        for note in result.notes {
            state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags.isEmpty ? [.progress] : note.tags), at: 0)
        }
        enforceHistoryBudget(on: &state)
        refreshGeneratedCaches(for: state)
        
        return result
    }

    func completeLife(state: GameState, meta: inout MetaState) {
        progressSystem.harvestLegacy(from: state, meta: &meta)
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

        state.player.age = chapter.targetAge
        if let event, let choice {
            apply(choice: choice, event: event, state: &state)
            chapter.selectedChoiceText = choice.text
        }

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
                educationSystem.advanceYear(input: world.education, player: &state.player, education: &state.education, career: &state.career)
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
            // Trait Mutations
            let mutationNotes = traitSystem.processMutations(player: &state.player, specialCareer: state.specialCareer)
            if !mutationNotes.isEmpty {
                let mutationResult = DomainYearResult(notes: mutationNotes)
                record(mutationResult, in: &state, results: &yearResults)
            }
            
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
            let familyResult = measure("Family") {
                familySystem.advanceYear(input: world.family, family: &state.family)
            }
            apply(result: familyResult, to: &state)
            record(familyResult, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.finance, in: world) {
            let financeResult = measure("Finance") {
                financeSystem.advanceYear(input: world.finance, finance: &state.finance)
            }
            apply(result: financeResult, to: &state)
            record(financeResult, in: &state, results: &yearResults)
            world = rebuildWorldSnapshot(from: state)
        }
        if systemRegistry.isActive(.investments, in: world) {
            let investmentResult = measure("Investments") {
                investmentSystem.advanceYear(input: world.investment, plannedAction: plannedFinanceAction, finance: &state.finance)
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

        let checkpointResult = crossDomainPressureSystem.ageCheckpoint(for: world)
        record(checkpointResult, in: &state, results: &yearResults)
        world = rebuildWorldSnapshot(from: state)

        state.player.clampStats()
        state.specialCareer.clamp()
        state.pendingActions = []
        state.activities.rolloverIfNeeded(to: state.player.age)
        syncAmbientContacts(in: &state)
        
        state.isGameOver = state.player.health <= 0 || state.healthProfile.physicalWellness <= 0 || state.finance.totalWealth < -20_000
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
            state.history.insert(
                HistoryEntry(age: state.player.age, title: "Life Ended", text: "The consequences of that year were too much for your body to absorb.", tags: [.health, .progress]),
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
        
        // Log reactions to history instead of showing cards
        for reaction in reactions {
            state.history.insert(HistoryEntry(age: state.player.age, title: reaction.title, text: reaction.detail, tags: [.progress]), at: 0)
        }

        chapter.pendingSummary = latestYearSummary
        chapter.pendingConsequencePreview = dominantConsequence
        chapter.pendingResolution = buildResolutionPreview(
            for: state,
            dominantConsequence: dominantConsequence,
            summary: latestYearSummary
        )

        // Check if we have any interactive cards left to show
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
        state.yearlyStance.lastOutcomeLine = yearlyStanceOutcomeLine(stance: stance, before: before, after: state, repeatCount: state.yearlyStance.repeatCount)
    }

    private func yearlyStanceOutcomeLine(stance: YearlyStanceID, before: GameState, after: GameState, repeatCount: Int) -> String {
        let repeatTail = repeatCount >= 2 ? " Pattern repeated \(repeatCount)x." : ""
        switch stance {
        case .stabilizeMoney:
            let cashDelta = after.finance.cashOnHand - before.finance.cashOnHand
            let stressDelta = after.finance.financialStress - before.finance.financialStress
            return cashDelta >= 0 || stressDelta <= 0
                ? "Money stance helped contain the year.\(repeatTail)"
                : "Money stance delayed pressure more than it solved it.\(repeatTail)"
        case .protectHealth:
            let mentalDelta = after.healthProfile.mentalWellness - before.healthProfile.mentalWellness
            return mentalDelta >= 0
                ? "Health stance made the year more survivable.\(repeatTail)"
                : "Health stance could not fully offset the load.\(repeatTail)"
        case .repairPeople:
            let beforeBond = max(before.relationships.friends.strongestBond, before.relationships.partnerBond)
            let afterBond = max(after.relationships.friends.strongestBond, after.relationships.partnerBond)
            return afterBond >= beforeBond
                ? "People stance kept support alive.\(repeatTail)"
                : "People stance did not stop distance from building.\(repeatTail)"
        case .pushCareer:
            return after.career.performance >= before.career.performance
                ? "Career stance converted effort into traction.\(repeatTail)"
                : "Career stance raised the cost without a clean payoff.\(repeatTail)"
        case .letYearDrift:
            return "Drift left outside pressure with more say than intent.\(repeatTail)"
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
            return CrisisInteraction(
                id: "crisis-finance-\(state.player.age)",
                title: "Total Collapse",
                detail: "The numbers have finally caught up. You are deeper in debt than the systems will allow. Bankruptcy is no longer a choice; it's a reality.",
                choices: [
                    CrisisChoice(id: "finance-accept", text: "Accept Ruin", detail: "Losing everything. Moving back to square one.", costSummary: "Lose all Assets • Reset Life", isBuyBack: false),
                    CrisisChoice(id: "finance-buyback", text: "The Predatory Deal", detail: "A bailout from people you shouldn't know. The money is yours, but so is the shadow.", costSummary: "+$10k Cash • Permanent 70+ Financial Stress", isBuyBack: true)
                ]
            )
        }
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

        let anticipationTitle: String
        let anticipationDetail: String
        if scheduledEvent != nil {
            anticipationTitle = anticipation.title
            anticipationDetail = anticipation.detail
        } else {
            anticipationTitle = "Likely opening"
            anticipationDetail = "\(opportunity.detail) \(anticipation.detail)"
        }

        return YearForecastCard(
            id: "forecast-\(targetAge)",
            age: targetAge,
            title: "Age \(targetAge) Is Taking Shape",
            subtitle: event?.title ?? "The year is already leaning somewhere.",
            focusTitle: focus.title,
            focusDetail: "\(focus.detail) \(ignoredRisk.detail)\(synergyContextLine(for: plannedActions))",
            pressureLabel: "Main pressure",
            pressureDetail: "\(pressure.detail) \(spilloverRisk.detail)\(whyNowContextLine(for: state, domain: pressure.domain))",
            anticipationTitle: anticipationTitle,
            anticipationDetail: anticipationDetail,
            tone: pressure.tone
        )
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
        TurnStakesSnapshot(
            focus: buildFocusSignal(for: state, plannedActions: plannedActions),
            topPressure: buildPressureSignal(for: state),
            topOpportunity: buildOpportunitySignal(for: state),
            ignoredRisk: buildIgnoredRiskSignal(for: state, plannedActions: plannedActions, event: event),
            spilloverRisk: buildSpilloverRiskSignal(for: state, targetAge: targetAge, scheduledEvent: scheduledEvent)
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
        return TurnStakesSignal(
            id: "pressure-\(domain.rawValue)",
            label: pressure.label,
            title: "Pressure Read",
            detail: pressure.detail,
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

        return ("Nothing Is Fully Settled", "Even a quiet year is already leaning somewhere based on what you have been carrying.")
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
            crimeSystem: crimeSystem,
            financeSystem: financeSystem,
            relationshipSystem: relationshipSystem,
            healthSystem: healthSystem,
            housingSystem: housingSystem
        )
    }

    private func updateRelationshipMilestones(in relationships: inout RelationshipState) {
        guard var partner = relationships.romanticPartner else { return }
        if partner.stage == .married {
            partner.isCohabiting = true
        }
        relationships.romanticPartner = partner
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
            case .buildEmergencyFund, .cutSpending, .saveForDownPayment, .buildMaintenanceReserve:
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
        let snapshot = rebuildWorldSnapshot(from: state)
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
