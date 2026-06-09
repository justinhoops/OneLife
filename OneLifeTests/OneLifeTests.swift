import Foundation
import Testing
@testable import OneLife

@Suite(.serialized)
@MainActor
struct OneLifeTests {
    private func applyRelationshipAction(
        _ choiceID: ActionChoiceID,
        system: RelationshipSystem,
        player: inout Player,
        relationships: inout RelationshipState,
        family: inout FamilyState
    ) -> DomainYearResult {
        var state = GameState()
        state.player = player
        state.relationships = relationships
        state.family = family
        let result = system.applyAction(choiceID, state: &state)
        player = state.player
        relationships = state.relationships
        family = state.family
        return result
    }

    private func applyEducationAction(
        _ choiceID: ActionChoiceID,
        system: EducationSystem,
        player: inout Player,
        education: inout EducationState
    ) -> DomainYearResult {
        var specialCareer = SpecialCareerState()
        return system.applyAction(
            choiceID,
            player: &player,
            education: &education,
            specialCareer: &specialCareer
        )
    }

    private func temporaryPersistence() -> PersistenceCoordinator {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        return PersistenceCoordinator(
            directoryProvider: {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                return directory
            },
            prefersSynchronousStartupLoad: true
        )
    }

    private func temporaryDefaults() -> UserDefaults {
        let suiteName = "onelife.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeViewModel(_ scenarioID: DebugScenarioID) -> GameViewModel {
        GameViewModel(
            persistence: temporaryPersistence(),
            defaults: temporaryDefaults(),
            debugConfiguration: DebugTestingConfiguration(scenarioID: scenarioID, modal: .none)
        )
    }

    private func makeViewModel(_ scenarioID: DebugScenarioID, modal: DebugScenarioModal) -> GameViewModel {
        GameViewModel(
            persistence: temporaryPersistence(),
            defaults: temporaryDefaults(),
            debugConfiguration: DebugTestingConfiguration(scenarioID: scenarioID, modal: modal)
        )
    }

    private func clearPresentedCards(_ vm: GameViewModel) async {
        for _ in 0..<40 {
            guard let card = vm.presentedCard else { return }
            switch card {
            case .event(let event):
                guard let choice = event.choices.first else {
                    Issue.record("Expected at least one event choice")
                    return
                }
                vm.choose(choice)
            default:
                vm.dismissPresentedCard()
            }
            await Task.yield()
        }
        Issue.record("Interaction card stack did not drain")
    }

    @Test func educationActivityMomentumClampsIntoValidRange() async throws {
        var education = EducationState()
        education.activityMomentum = 180
        education.clamp()
        #expect(education.activityMomentum == 100)

        education.activityMomentum = -12
        education.clamp()
        #expect(education.activityMomentum == 0)
    }

    @Test func lifeSummaryReflectsAchievementsRegretsAndRelationships() async throws {
        var state = GameState()
        state.player.age = 72
        state.progress.currentLifePath = .provider
        state.progress.legacyScore = 55
        state.progress.unlockedMilestones = [
            MilestoneUnlock(id: .firstJob, unlockedAtAge: 20),
            MilestoneUnlock(id: .homeowner, unlockedAtAge: 36)
        ]
        state.finance.financialStress = 82
        state.family.children = [
            ChildRecord(name: "Maya", age: 32, otherParentName: "Alex", bondWithPlayer: 78)
        ]

        let summary = LifeSummarySystem().build(from: state)

        #expect(summary.headline == "You Left People Who Remember")
        #expect(summary.achievements.contains("Made a home of your own"))
        #expect(summary.regrets.contains("Money pressure consumed too many years"))
        #expect(summary.relationshipLine.contains("child"))
        #expect(summary.legacyPointsEarned > 0)
    }

    @Test func inheritedLifeCarriesParentLegacyContextAndReputationShadow() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var parent = GameState()
        parent.player.name = "Jordan"
        parent.player.age = 81
        parent.finance.cashOnHand = 120_000
        parent.relationships.publicReputation = 82
        parent.fame.culturalFame = 70
        parent.fame.notoriety = 40
        parent.progress.finalLifePath = .connector
        let child = ChildRecord(name: "Avery", age: 28, otherParentName: "Morgan", bondWithPlayer: 76)

        let inherited = orchestrator.inheritLegacy(child: child, parentState: parent)

        #expect(inherited.inheritedLegacy?.parentName == "Jordan")
        #expect(inherited.inheritedLegacy?.parentDeathAge == 81)
        #expect(inherited.inheritedLegacy?.parentLegacyHeadline?.isEmpty == false)
        #expect(inherited.fame.culturalFame == 14)
        #expect(inherited.fame.notoriety == 10)
        #expect(inherited.history.first?.title == "Heritage")
    }

    @Test func choosingSuccessorHarvestsCompletedLifeBeforeHandoff() async throws {
        let vm = makeViewModel(.adultCareerFlow)
        let child = ChildRecord(name: "Sam", age: 24, otherParentName: "Taylor", bondWithPlayer: 70)
        vm.mutateStateForTesting {
            $0.player.name = "Taylor"
            $0.player.age = 68
            $0.family.children = [child]
            $0.progress.unlockedMilestones = [MilestoneUnlock(id: .firstJob, unlockedAtAge: 20)]
        }
        let livesBefore = vm.metaState.totalLivesPlayed

        vm.switchToChild(child)

        #expect(vm.metaState.totalLivesPlayed == livesBefore + 1)
        #expect(vm.state.player.name == "Sam")
        #expect(vm.state.inheritedLegacy?.parentName == "Taylor")
    }

    @Test func ageUpRiskPreviewStaysGlanceableAndQualitative() async throws {
        let vm = makeViewModel(.teenEducationPressure)

        let signals = vm.ageUpRiskPreviewSignals()

        #expect((1...3).contains(signals.count))
        #expect(signals.contains { $0.title == "Money strain is active" || $0.title == "Burnout may spill over" })
        #expect(!signals.contains { $0.title.contains("%") })
    }

    @Test func actionPreviewTagsAreCappedForTradeoffScanning() async throws {
        let vm = makeViewModel(.adultCareerFlow)

        #expect(vm.actionPreview(for: .takeOvertime).count <= 3)
        #expect(vm.actionPreview(for: .protectYourEnergy).count <= 3)
    }

    @Test func instantActionRecordsMemoryAndUpdatesPressureRead() async throws {
        let vm = makeViewModel(.teenEducationPressure)
        vm.mutateStateForTesting { $0.pendingActions = [] }
        let startingHealthPressure = vm.state.consequences.pressureByDomain["health", default: 0]

        vm.setAction(.protectSleep, for: .health)

        #expect(vm.state.actionMemory.latestAction?.domain == .health)
        #expect(vm.state.actionMemory.latestAction?.choiceID == .protectSleep)
        #expect(vm.pendingActionStatus() == "Action taken")
        #expect(vm.pendingActionSummary().contains(ActionChoiceCatalog.definition(for: .protectSleep).title))
        #expect(vm.state.consequences.pressureByDomain["health", default: 0] <= startingHealthPressure)
        #expect(vm.state.correlationLedger.actionCounts[ActionChoiceID.protectSleep.rawValue] == 1)
        #expect(vm.state.correlationLedger.pressureCauses.contains { $0.domain == "health" && $0.sourceAction == .protectSleep })
        #expect(vm.state.correlationLedger.pressureCauseLine(for: "health")?.contains("Sleep -8") == true)
    }

    @Test func pressureMapUsesCorrelationCauseTrailForActivePressure() async throws {
        let vm = makeViewModel(.teenEducationPressure)
        vm.mutateStateForTesting {
            $0.consequences.pressureByDomain["health"] = 30
        }

        vm.setAction(.protectSleep, for: .health)

        let burnout = vm.feedUrgencyItems().first { $0.title == "Burnout" }
        #expect(burnout?.value.contains("Sleep -8") == true)
    }

    @Test func yearlyStanceQueuesExistingActionAndSummarizesOutcome() async throws {
        let vm = makeViewModel(.adultCareerFlow)

        vm.setYearlyStance(.protectHealth)

        #expect(vm.state.yearlyStance.selectedStance == .protectHealth)
        #expect(vm.state.actionMemory.latestAction?.choiceID == .protectSleep || vm.state.actionMemory.latestAction?.choiceID == .rest)

        vm.ageUp()
        await clearPresentedCards(vm)

        #expect(vm.latestYearSummary?.yearlyStanceOutcome?.title == "Yearly Goal")
        #expect(vm.state.yearlyStance.lastCompletedStance == .protectHealth)
        #expect(vm.state.yearlyStance.selectedStance == nil)
    }

    @Test func pressureContextLinesUseSourceDomainAndSpillover() async throws {
        let vm = makeViewModel(.adultCareerFlow)
        vm.mutateStateForTesting {
            $0.correlationLedger.recordPressureCause(domain: "finance", label: "Extra shifts", delta: 4, age: 28, sourceAction: .takeExtraShifts)
        }

        let line = vm.pressureContextLines().first

        #expect(line == "Extra shifts -> money pressure -> health and people feel it")
    }

    @Test func npcAutonomyPulseSurfacesHiddenRelationshipPressure() async throws {
        let vm = makeViewModel(.adultCareerFlow)
        vm.mutateStateForTesting {
            $0.relationships.friends = [
                Relationship(name: "Marcus", type: .friend, bond: 52, hiddenNeedLevel: 45)
            ]
        }

        #expect(vm.npcAutonomyPulse() == "Marcus may ask for help soon")
    }

    @Test func repeatedOverworkBuildsCorrelationResidueAndHook() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = GameState()
        state.startupState = .active
        state.player.age = 24
        state.finance.financialStress = 44
        state.consequences.pressureByDomain["finance"] = 24

        _ = orchestrator.applyImmediateAction(.takeExtraShifts, domain: .finance, state: &state)
        _ = orchestrator.applyImmediateAction(.takeExtraShifts, domain: .finance, state: &state)

        #expect(state.correlationLedger.actionCounts[ActionChoiceID.takeExtraShifts.rawValue] == 2)
        #expect(state.correlationLedger.domainResidue["finance", default: 0] < 0)
        #expect(state.correlationLedger.domainResidue["health", default: 0] > 0)
        #expect(state.correlationLedger.unresolvedHooks.contains { $0.tag == "overwork" && $0.domain == "health" })
    }

    @Test func pendingMacroQueueSurvivesInstantApply() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = GameState()
        state.startupState = .active
        state.player.age = 22
        state.pendingActions = [PlayerYearAction(domain: .career, choiceID: .workHard)]

        _ = orchestrator.applyImmediateAction(.smallHustle, domain: .finance, state: &state)

        #expect(state.pendingActions.count == 1)
        #expect(state.pendingActions.first?.domain == .career)
        #expect(state.pendingActions.first?.choiceID == .workHard)
    }

    @Test func ambientPressureNudgesStayWithinBounds() async throws {
        var state = GameState()
        state.startupState = .active
        state.player.age = 30
        state.finance.financialStress = 60
        state.consequences.pressureByDomain["finance"] = 90

        for _ in 0..<25 {
            AmbientPressureSync.applyNudges(to: &state)
        }

        #expect(state.consequences.pressureByDomain["finance", default: 0] <= 100)
    }

    @Test func ageUpForecastUsesInstantActionMemoryWithoutReapplyingAction() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = GameState()
        state.startupState = .active
        state.player.age = 14
        state.finance.cashOnHand = 250

        _ = orchestrator.applyImmediateAction(.smallHustle, domain: .finance, state: &state)
        let afterImmediate = state

        var memoryBackedState = afterImmediate
        var plainState = afterImmediate
        plainState.actionMemory.clearForNewAge(plainState.player.age)

        _ = orchestrator.beginYearChapter(state: &memoryBackedState)
        _ = LifeSimulationOrchestrator(eventEngine: EventEngine(events: [])).beginYearChapter(state: &plainState)

        #expect(memoryBackedState.finance.cashOnHand == plainState.finance.cashOnHand)
        #expect(memoryBackedState.actionMemory.recentActions.isEmpty)
        #expect(!memoryBackedState.correlationLedger.actionCounts.isEmpty)
    }

    @Test func causeTrailCapsYearSummaryReasons() async throws {
        let vm = makeViewModel(.yearSummaryPreview)

        let causes = vm.causeTrailItems()

        #expect((1...3).contains(causes.count))
        #expect(Set(causes.map(\.detail)).count == causes.count)
    }

    @Test func guidedRecommendationUsesValidActionChoice() async throws {
        let vm = makeViewModel(.housingDeficitFlow)

        let recommendation = try #require(vm.guidedRecommendation())

        #expect(vm.actionChoices(for: recommendation.domain).contains(recommendation.choiceID))
        vm.applyGuidedRecommendation()
        #expect(vm.selectedAction(for: recommendation.domain) != nil)
    }

    @Test func firstRunDefaultsToGuidedPace() async throws {
        let vm = GameViewModel(persistence: temporaryPersistence(), defaults: temporaryDefaults())

        #expect(vm.autoLifePace == .guided)
        #expect(vm.state.startupState == .choosingOrigin)
        #expect(vm.state.mvpOnboarding.startAge == nil)
    }

    @Test func guidedModeWaitsForPlayerConfirmation() async throws {
        let vm = makeViewModel(.housingDeficitFlow)
        vm.autoLifePace = .guided
        vm.mutateStateForTesting {
            $0.yearlyStance.selectedStance = nil
            $0.pendingActions = []
        }

        await clearPresentedCards(vm)
        vm.ageUp()

        #expect(vm.state.yearlyStance.selectedStance == nil)
    }

    @Test func backgroundPulseStaysGlanceableAndQualitative() async throws {
        let vm = makeViewModel(.yearSummaryPreview)

        let items = vm.backgroundPulseItems()

        #expect(items.count <= 3)
        #expect(!items.contains { $0.detail.contains("%") })
    }

    @Test func autopilotStopsOnInteractiveEvent() async throws {
        let vm = makeViewModel(.adultCareerFlow)
        vm.autoLifePace = .autopilot

        vm.ageUp()

        #expect(vm.autopilotYearsAdvanced <= 1)
        #expect(vm.presentedCard != nil || vm.latestYearSummary != nil)
    }

    @Test func autopilotStopsOnCriticalHealthThreshold() async throws {
        let vm = makeViewModel(.adultCareerFlow)
        vm.autoLifePace = .autopilot
        vm.mutateStateForTesting {
            $0.healthProfile.physicalWellness = 34
            $0.player.health = 34
        }

        vm.ageUp()

        #expect(vm.autopilotYearsAdvanced <= 1)
    }

    @Test func characterCreationOnlyExposesImplementedSteps() async throws {
        #expect(CharacterCreationStep.allCases == [.name, .origin, .trait, .resilience])
    }

    @Test func firstLifeOnboardingExpiresAfterThreeYearsOrMajorMoment() async throws {
        var onboarding = MVPOnboardingState()
        onboarding.activate(at: 14)

        onboarding.advance(afterAge: 15, hadMajorMoment: false)
        #expect(onboarding.isActive(at: 15))

        onboarding.advance(afterAge: 17, hadMajorMoment: false)
        #expect(!onboarding.isActive(at: 17))
        #expect(!onboarding.endedByMajorMoment)

        var majorOnboarding = MVPOnboardingState()
        majorOnboarding.activate(at: 14)
        majorOnboarding.advance(afterAge: 15, hadMajorMoment: true)

        #expect(!majorOnboarding.isActive(at: 15))
        #expect(majorOnboarding.endedByMajorMoment)
    }

    @Test func silentYearChapterStillSurfacesReactionBeatsBeforeSummary() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = DebugTestingCoordinator().payload(for: .adultCareerFlow).state
        state.yearlyStance.selectedStance = .protectHealth
        state.pendingActions = [PlayerYearAction(domain: .health, choiceID: .rest)]

        let outcome = orchestrator.beginYearChapter(state: &state)
        #expect(outcome.summary != nil)
        #expect(!outcome.cards.isEmpty)

        let kinds = outcome.cards.map(cardKind)
        let summaryIndex = try #require(kinds.firstIndex(of: "yearSummary"))
        if let reactionIndex = kinds.firstIndex(of: "reaction") {
            #expect(reactionIndex < summaryIndex)
        }
    }

    @Test func discoverabilityInlineTeachCopyAndFlags() async throws {
        var flags = DiscoverabilityState()
        #expect(flags.shouldShowHoldHint() == true)
        #expect(flags.shouldShowFirstQuickActionTeach() == false)

        flags.performedFirstQuickAction = true
        #expect(flags.shouldShowFirstQuickActionTeach() == true)
        let resilientLine = DiscoverabilityTeaching.firstQuickActionLine(resilience: .resilient)
        #expect(resilientLine.contains("momentum") == true)
        let groundedLine = DiscoverabilityTeaching.firstQuickActionLine(resilience: .grounded)
        #expect(groundedLine.contains("thinner") == true)

        flags.markFirstQuickActionTeachSeen()
        #expect(flags.shouldShowFirstQuickActionTeach() == false)

        #expect(DiscoverabilityTeaching.longPressFooterLine.contains("Age Up") == true)

        var carry = InstantMomentumCarrySnapshot()
        carry.healthMomentum = 18
        carry.relationshipMomentum = 12
        carry.overallStrength = 20
        let carryLine = DiscoverabilityTeaching.instantMomentumCarryLine(snapshot: carry, resilience: .resilient)
        #expect(carryLine.contains("Body +18") == true)
        #expect(carryLine.contains("People +12") == true)

        flags.markFirstLongPressTeachSeen()
        #expect(flags.shouldShowHoldHint() == false)
        #expect(flags.seenFirstLongPressTeach == true)
    }

    @Test func instantMomentumCarryPersistenceRoundTrip() async throws {
        var state = GameState()
        state.instantMomentum.healthMomentum = 30
        state.instantMomentum.financeMomentum = 15
        state.instantMomentum.overallStrength = 22
        state.lastYearInstantMomentumCarry = InstantMomentumCarrySnapshot(from: state.instantMomentum, age: 24)
        state.discoverability.seenInstantMomentumYearSummary = false

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(GameState.self, from: data)
        #expect(decoded.lastYearInstantMomentumCarry?.healthMomentum == 30)
        #expect(decoded.lastYearInstantMomentumCarry?.capturedAtAge == 24)
        #expect(decoded.discoverability.seenFirstQuickActionTeach == false)
    }

    @Test func adultChildFocusChipGate() async throws {
        var flags = DiscoverabilityState()
        var family = FamilyState()
        family.children = [
            ChildRecord(name: "Sam", age: 22, livesAtHome: false, otherParentName: "Alex", bondWithPlayer: 60)
        ]
        let adults = family.children.filter { !$0.livesAtHome }
        #expect(!adults.isEmpty)
        #expect(flags.seenAdultChildrenCoach == false)
        #expect(DiscoverabilityTeaching.adultChildFocusHistoryLine.contains("focus history") == true)
        flags.markAdultChildrenSeen()
        #expect(flags.seenAdultChildrenCoach == true)
    }

    @Test func viewModelFirstQuickActionTeachLineTracksDiscoverability() async throws {
        let vm = makeViewModel(.adultCareerFlow)
        vm.mutateStateForTesting {
            $0.discoverability = DiscoverabilityState()
        }
        #expect(vm.firstQuickActionTeachLine() == nil)

        vm.mutateStateForTesting {
            $0.discoverability.performedFirstQuickAction = true
        }
        #expect(vm.firstQuickActionTeachLine()?.contains("momentum") == true)

        vm.markFirstQuickActionTeachSeen()
        #expect(vm.firstQuickActionTeachLine() == nil)
    }

    @Test func instantMomentumBuildHintTargetsWeakestLane() async throws {
        var momentum = InstantMomentumState()
        momentum.healthMomentum = 40
        momentum.financeMomentum = 8
        momentum.relationshipMomentum = 12
        momentum.overallStrength = 20

        let hint = momentum.buildHint(resilience: .grounded)
        #expect(hint.contains("money") == true)
        #expect(momentum.rankedDomainMomentum.first?.domain == .health)
    }

    @Test func tierASmokeQuickActionThenAgeUpForecast() async throws {
        let vm = makeViewModel(.adultCareerFlow)
        await clearPresentedCards(vm)
        vm.mutateStateForTesting {
            $0.player.age = 18
            $0.startupState = .active
            $0.activeYearChapter = nil
            $0.isGameOver = false
            $0.yearlyStance.selectedStance = nil
            $0.quickActionMemory = QuickActionMemoryState()
        }

        let lane = vm.nowLaneSnapshot()
        #expect(lane.showsQuickAction == true)
        #expect(lane.quickActionChoice != nil)

        if let domain = lane.quickActionDomain, let choice = lane.quickActionChoice {
            vm.performQuickAction(choice, for: domain)
        }

        vm.ageUp()
        #expect(vm.presentedCard != nil || vm.state.activeYearChapter != nil)
        #expect(vm.state.softRunGoal != nil)
    }

    @Test func compactLateGameUIActivatesForMatureLives() async throws {
        var state = GameState()
        state.player.age = 42
        state.family.children = [
            ChildRecord(name: "Sam", age: 22, livesAtHome: false, otherParentName: "Alex", bondWithPlayer: 60)
        ]
        let vm = makeViewModel(.adultCareerFlow)
        vm.mutateStateForTesting { $0 = state }
        #expect(vm.prefersCompactLateGameUI == true)
        #expect(vm.lateGameContextRibbon()?.contains("adult child") == true)
    }

    @Test func yearlySummaryActionableLessonAppearsOnHarshYears() async throws {
        var state = GameState()
        state.resilience = .grounded
        state.yearlyStance.lastCompletedStance = .protectHealth
        state.healthProfile.mentalWellness = 30

        var summary = YearlyOutcomeSummary(age: 24)
        summary.topProblem = YearlyOutcomeItem(
            title: "Mental Load",
            detail: "Stress climbed.",
            domain: .health,
            tone: .warning,
            impactScore: -12
        )

        let lesson = summary.actionableLesson(resilience: .grounded, state: state)
        #expect(lesson?.title == "Small Win To Try")
        #expect(lesson?.detail.contains("Grounded") == true)
    }

    @Test func resilienceJournalReflectionsFireAtMilestoneAges() async throws {
        #expect(LifeResilience.resilient.journalReflection(forAge: 25)?.title == "Life Feel")
        #expect(LifeResilience.grounded.journalReflection(forAge: 40)?.text.contains("Grounded") == true)
        #expect(LifeResilience.resilient.journalReflection(forAge: 30) == nil)

        let vm = makeViewModel(.adultCareerFlow)
        vm.mutateStateForTesting {
            $0.player.age = 25
            $0.resilience = .grounded
            $0.discoverability.resilienceJournalAges = []
        }
        vm.maintainDiscoverabilityAndResilienceJournal()
        #expect(vm.state.discoverability.resilienceJournalAges.contains(25))
        #expect(vm.state.history.contains { $0.title == "Life Feel" && $0.age == 25 })
    }

    @Test func repeatedChoicesUnlockPlayerIdentityPattern() async throws {
        let vm = makeViewModel(.adultCareerFlow)
        vm.mutateStateForTesting {
            $0.correlationLedger.actionCounts = [:]
            $0.correlationLedger.actionCounts[ActionChoiceID.workHard.rawValue] = 2
            $0.correlationLedger.actionCounts[ActionChoiceID.takeOvertime.rawValue] = 1
        }

        #expect(vm.currentIdentityPattern == .overworker)
        #expect(vm.currentIdentityPattern?.eventWeights["burnout"] == 4)
    }

    @Test func quickActionsExistForActiveEverydayDomains() async throws {
        let adult = makeViewModel(.adultCareerFlow)
        #expect(!adult.quickActionChoices(for: .career).isEmpty)
        #expect(!adult.quickActionChoices(for: .finance).isEmpty)
        #expect(!adult.quickActionChoices(for: .relationships).isEmpty)
        #expect(!adult.quickActionChoices(for: .health).isEmpty)

        let teen = makeViewModel(.teenEducationPressure)
        #expect(!teen.quickActionChoices(for: .education).isEmpty)

        let crime = makeViewModel(.specialCareerCrime)
        #expect(!crime.quickActionChoices(for: .crime).isEmpty)
    }

    @Test func quickActionAppliesImmediatelyWithoutYearPlanQueue() async throws {
        let vm = makeViewModel(.adultCareerFlow)
        vm.mutateStateForTesting { $0.pendingActions = [] }
        let startingCash = vm.state.finance.cashOnHand

        vm.performQuickAction(.takeSideWork, for: .finance)

        #expect(vm.state.finance.cashOnHand != startingCash)
        #expect(vm.state.pendingActions.isEmpty)
        #expect(vm.state.actionMemory.latestAction?.choiceID == .takeSideWork)
        #expect(vm.state.quickActionMemory.countThisAge == 1)
        #expect(vm.activityPulse != nil)
    }

    @Test func repeatedQuickActionSameAgeIsBlocked() async throws {
        var memory = QuickActionMemoryState()
        let action = PlayerYearAction(domain: .finance, choiceID: .cutSpending)
        memory.record(action, age: 28)

        #expect(memory.blockReason(for: action, age: 28) == "Already done this year.")
        memory.record(action, age: 28)
        #expect(memory.countThisAge == 1)
    }

    @Test func quickActionsCapAtThreePerAge() async throws {
        var memory = QuickActionMemoryState()
        memory.record(PlayerYearAction(domain: .finance, choiceID: .cutSpending), age: 28)
        memory.record(PlayerYearAction(domain: .finance, choiceID: .takeSideWork), age: 28)
        memory.record(PlayerYearAction(domain: .finance, choiceID: .spendForRelief), age: 28)
        let fourth = PlayerYearAction(domain: .health, choiceID: .rest)

        #expect(memory.blockReason(for: fourth, age: 28) == "Quick actions are used up for this year.")
        #expect(memory.countThisAge == 3)
    }

    @Test func quickActionUpdatesHistoryCorrelationAndMemory() async throws {
        let vm = makeViewModel(.adultCareerFlow)
        await clearPresentedCards(vm)
        vm.mutateStateForTesting {
            $0.pendingActions = []
            $0.history = []
            $0.correlationLedger.actionCounts = [:]
        }

        vm.performQuickAction(.reachOut, for: .relationships)

        #expect(vm.state.history.contains { $0.tags.contains(.relationships) })
        #expect(vm.state.correlationLedger.actionCounts[ActionChoiceID.reachOut.rawValue, default: 0] == 1)
        #expect(vm.state.actionMemory.latestAction?.choiceID == .reachOut)
        #expect(vm.state.quickActionMemory.completedThisAge.contains { $0.choiceID == .reachOut && $0.domain == .relationships })
    }

    @Test func teenStudentYearProducesLowCostsAndSmallTaxRate() async throws {
        var finance = FinanceState(cashOnHand: 250)
        let system = FinanceSystem()

        let result = system.advanceYear(
            context: FinanceYearContext(
                age: 14,
                isSchoolAge: true,
                careerStatus: .student,
                grossIncome: 0,
                traits: [],
                educationPathway: .student,
                educationStage: .secondary,
                hasScholarship: false,
                housingCostBand: 18,
                housingArrangement: .familyHome,
                activeConditionCount: 0,
                ownsHome: false,
                hasPrimaryCare: false,
                friendCount: 0,
                partnerCount: 0,
                hasSpouse: false,
                hasCohabitingPartner: false,
                isPregnant: false,
                pregnancyPhase: nil,
                infantCount: 0,
                childCount: 0
            ),
            finance: &finance,
            player: Player()
        )

        #expect(finance.effectiveTaxRate == 8)
        #expect(finance.annualLivingCost == 1_800)
        #expect(finance.annualTotalExpenses >= 1_800)
        #expect(finance.cashOnHand < 250)
        #expect(!result.notes.isEmpty)
    }

    @Test func fullTimeWorkerBuildsPositiveCashflow() async throws {
        var finance = FinanceState(cashOnHand: 5_000)
        let system = FinanceSystem()

        var player = Player()
        player.happiness = 62

        system.advanceYear(
            context: FinanceYearContext(
                age: 24,
                isSchoolAge: false,
                careerStatus: .fullTime,
                grossIncome: 36_000,
                traits: [.disciplined],
                educationPathway: .graduate,
                educationStage: .inactive,
                hasScholarship: false,
                housingCostBand: 45,
                housingArrangement: .soloRenting,
                activeConditionCount: 0,
                ownsHome: false,
                hasPrimaryCare: false,
                friendCount: 1,
                partnerCount: 0,
                hasSpouse: false,
                hasCohabitingPartner: false,
                isPregnant: false,
                pregnancyPhase: nil,
                infantCount: 0,
                childCount: 0
            ),
            finance: &finance,
            player: player
        )

        #expect(finance.effectiveTaxRate == 18)
        #expect(finance.annualNetIncome == 29_520)
        #expect(finance.lastYearBalanceDelta > 0)
        #expect(finance.cashOnHand > 5_000)
        #expect(finance.stabilityStreakYears == 1)
        #expect(finance.lifestyleCreep > 0)
        #expect(finance.wealthVelocity > 0)
        #expect(finance.peakWealth == finance.totalWealth)
    }

    @Test func regularCareerIncomeFlowsPassivelyIntoFinance() async throws {
        var state = GameState()
        state.player.age = 24
        state.career.roleID = "operations_coordinator"
        state.career.status = .fullTime
        state.career.annualIncome = 36_000
        state.housing.livingArrangement = .roommates
        state.housing.housingCostBand = 36

        var finance = state.finance
        let result = FinanceSystem().advanceYear(input: WorldSnapshotBuilder().build(from: state).finance, finance: &finance)

        #expect(finance.annualGrossIncome == 36_000)
        #expect(finance.annualNetIncome > 0)
        #expect(finance.cashOnHand != state.finance.cashOnHand)
        #expect(!result.notes.isEmpty)
    }

    @Test func unemployedAdultAutoLandsBestQualifiedRegularRole() async throws {
        let system = CareerSystem()
        var player = Player()
        player.age = 19
        player.health = 70
        var career = CareerState(status: .unemployed, roleID: nil, level: 0, annualIncome: 0, performance: 52, yearsWorked: 0, unemployedYears: 1)
        var education = EducationState()
        education.pathway = .dropout
        education.stage = .inactive
        education.credentials = []

        _ = system.advanceYear(player: &player, career: &career, education: education, health: HealthState(), relationships: RelationshipState())

        #expect(career.roleID != nil)
        #expect(career.annualIncome > 0)
        #expect(career.status == .fullTime || career.status == .partTime)
    }

    @Test func regularWorkAccumulatesExperienceWithoutCareerAction() async throws {
        let system = CareerSystem()
        var player = Player()
        player.age = 25
        var career = CareerState(status: .fullTime, roleID: "operations_coordinator", level: 4, annualIncome: 36_000, performance: 70, yearsWorked: 2, unemployedYears: 0)

        _ = system.advanceYear(player: &player, career: &career, education: EducationState(), health: HealthState(), relationships: RelationshipState())

        #expect(career.experience(for: .admin) >= 1)
        #expect(career.experience(for: .management) >= 1)
    }

    @Test func specialCareerQualificationUsesRegularCareerExperience() async throws {
        var state = GameState()
        state.player.age = 25
        state.finance.cashOnHand = 4_000
        state.career.annualIncome = 32_000

        #expect(SpecialCareerSystem.qualificationIssue(for: .startCompany, state: state) != nil)

        state.finance.cashOnHand = 6_000
        state.career.careerExperience[.sales] = 1

        #expect(SpecialCareerSystem.qualificationIssue(for: .startCompany, state: state) == nil)
    }

    @Test func legacyCareerStateDecodesWithEmptyExperience() async throws {
        let json = Data("""
        {
          "status": "fullTime",
          "profile": "stableAdmin",
          "workIdentity": "unsettled",
          "roleID": "office_assistant",
          "level": 3,
          "annualIncome": 24000,
          "performance": 64,
          "yearsWorked": 1,
          "unemployedYears": 0
        }
        """.utf8)

        let decoded = try JSONDecoder().decode(CareerState.self, from: json)

        #expect(decoded.roleID == "office_assistant")
        #expect(decoded.careerExperience.isEmpty)
    }

    @Test func unemployedAdultCanGoNegativeAndStressRises() async throws {
        var finance = FinanceState(cashOnHand: 1_000)
        finance.financialStress = 10
        let system = FinanceSystem()

        var player = Player()
        player.age = 22

        system.advanceYear(
            context: FinanceYearContext(
                age: 22,
                isSchoolAge: false,
                careerStatus: .unemployed,
                grossIncome: 0,
                traits: [.anxious],
                educationPathway: .dropout,
                educationStage: .inactive,
                hasScholarship: false,
                housingCostBand: 36,
                housingArrangement: .roommates,
                activeConditionCount: 1,
                ownsHome: false,
                hasPrimaryCare: false,
                friendCount: 0,
                partnerCount: 0,
                hasSpouse: false,
                hasCohabitingPartner: false,
                isPregnant: false,
                pregnancyPhase: nil,
                infantCount: 0,
                childCount: 0
            ),
            finance: &finance,
            player: player
        )

        #expect(finance.financialStress >= 25)
        // Adult shortfall rolls into revolving/medical debt instead of leaving raw negative cash.
        #expect(finance.cashOnHand < 0 || finance.creditDebt > 0 || finance.medicalDebt > 0)
    }

    @Test func financeEffectMutatesFinanceDomainWithoutPlayerMoneySync() async throws {
        let system = FinanceSystem()
        var finance = FinanceState(cashOnHand: 500)
        var player = Player()

        system.apply(
            effect: FinanceEffects(
                cashDelta: 750,
                livingCostDelta: 200,
                educationCostDelta: nil,
                dependentCostDelta: nil,
                discretionaryCostDelta: nil,
                financialStressDelta: -3,
                setRegionPolicyID: "future-demo"
            ),
            finance: &finance,
            player: &player
        )

        #expect(finance.cashOnHand == 1_250)
        #expect(finance.annualLivingCost == 200)
        #expect(finance.financialStress == 15)
        #expect(finance.currentRegionPolicyID == "future-demo")
    }

    @Test func financeOverviewSurfacesDeficitPressure() async throws {
        let vm = makeViewModel(.housingDeficitFlow)

        let overview = vm.overview(for: .assets)

        #expect(overview.primaryPressure.title == "Running deficit")
        #expect(overview.primaryPressure.destination == .financeCashflow)
        #expect(overview.primaryPressure.tone == .warning)
    }

    @Test func relationshipsOverviewSurfacesStrain() async throws {
        let vm = makeViewModel(.teenEducationPressure)

        let overview = vm.overview(for: .relationships)

        #expect(overview.primaryPressure.title == "Relationship tension is active")
        #expect(overview.primaryPressure.destination == .relationshipsConnections)
        #expect(overview.primaryPressure.tone == .warning)
    }

    @Test func activitiesOverviewSurfacesHealthPressureWhenConditionsDominate() async throws {
        let vm = makeViewModel(.healthCrisis)

        let overview = vm.activitiesTabOverview()

        #expect(overview.title == "Activities")
        #expect(overview.primaryPressure.title == "Conditions are active")
        #expect(overview.primaryPressure.destination == .healthConditions)
        #expect(overview.primaryPressure.tone == .warning)
        #expect(overview.detailDestination == .healthOverview)
    }

    @Test func activitiesTabOverviewMatchesActivitiesTabAndLinksHealthDetails() async throws {
        let vm = makeViewModel(.housingDeficitFlow)

        let overview = vm.activitiesTabOverview()

        #expect(overview.title == "Activities")
        #expect(overview.symbol == "sparkles")
        #expect(overview.detailDestination == .healthOverview)
        #expect(overview.primaryPressure.title == "Stress load is rising")
    }

    @Test func feedOverviewBuildsContinuityHubFromYearSummaryAndCarryover() async throws {
        let vm = makeViewModel(.yearSummaryPreview, modal: .yearSummary)

        let overview = vm.feedTabOverview()

        #expect(overview.continuity != nil)
        #expect(overview.continuity?.changed.isEmpty == false)
        let status = try #require(overview.continuity?.status)
        #expect(["Still active", "Coming back later", "This year moved"].contains(status))
    }

    @Test func scheduledEventProducesForecastThenEventThenAftermathStack() async throws {
        let orchestrator = LifeSimulationOrchestrator()
        let eventEngine = EventEngine()
        var state = GameState()
        state.startupState = .active
        state.player.age = 24
        state.education.pathway = .graduate
        state.education.stage = .inactive
        state.career.status = .fullTime
        state.career.profile = .stableAdmin
        state.career.roleID = "office_assistant"
        state.career.performance = 62
        state.finance.cashOnHand = 500
        state.consequences.scheduledEvents = [
            ScheduledConsequenceEvent(eventID: "unexpected_bill", dueAge: 25, title: "Unexpected Bill")
        ]
        state.pendingActions = [
            PlayerYearAction(domain: .finance, choiceID: .cutSpending)
        ]

        let opening = orchestrator.beginYearChapter(state: &state)
        #expect(opening.cards.count == 2)
        if case .forecast = opening.cards[0] {} else { Issue.record("Expected forecast card first") }
        if case .event = opening.cards[1] {} else { Issue.record("Expected event card second") }

        let event = try #require(eventEngine.event(withID: "unexpected_bill"))
        let choice = try #require(event.choices.first)
        let resolved = orchestrator.resolveYearChapter(choice: choice, state: &state)

        #expect(state.player.age == 25)
        #expect(resolved.summary != nil)
        #expect(state.history.contains { $0.title == event.title })
    }

    @Test func echoFlavorResolverPrependsPastChoiceMemory() async throws {
        var state = GameState()
        state.player.age = 24
        state.consequences.narrativeFlags["took_payday_loan"] = 22

        let event = try #require(EventEngine().event(withID: "unexpected_bill"))
        let text = event.displayText(echoing: state)

        #expect(text.contains("You're still paying off that short-term loan."))
    }

    @Test func continuityMilestonesFireOnceAtAge18And20() async throws {
        let engine = ContinuityThreadEngine()

        var before18 = GameState()
        before18.player.age = 17
        var after18 = before18
        after18.player.age = 18
        let first18 = engine.evaluate(before: before18, after: &after18)
        let second18 = engine.evaluate(before: before18, after: &after18)

        #expect(first18.notes.contains(where: { $0.title == "Age 18" }))
        #expect(second18.notes.isEmpty)

        var before20 = GameState()
        before20.player.age = 19
        var after20 = before20
        after20.player.age = 20
        let first20 = engine.evaluate(before: before20, after: &after20)
        let second20 = engine.evaluate(before: before20, after: &after20)

        #expect(first20.notes.contains(where: { $0.title == "Age 20 — First Look Back" }))
        #expect(second20.notes.isEmpty)
    }

    @Test func agingUpFromDetailReturnsPlayerToOriginatingTab() async throws {
        let vm = makeViewModel(.adultCareerFlow)
        vm.selectedTab = .assets
        vm.openDetail(.financeCashflow)

        vm.ageUp()
        await clearPresentedCards(vm)

        #expect(vm.selectedTab == .assets)
        #expect(vm.returnPrompt != nil)
    }

    @Test func relationshipActionBuildsReputationAndRumorWeights() async throws {
        let system = RelationshipSystem()
        var player = Player()
        player.age = 19
        var relationships = RelationshipState()
        relationships.friends = [Relationship(name: "Jordan", type: .friend, bond: 61)]
        var family = FamilyState()

        _ = applyRelationshipAction(.chaseStatus, system: system, player: &player, relationships: &relationships, family: &family)
        _ = applyRelationshipAction(.chaseStatus, system: system, player: &player, relationships: &relationships, family: &family)
        _ = applyRelationshipAction(.chaseStatus, system: system, player: &player, relationships: &relationships, family: &family)

        #expect(relationships.publicReputation > 50)
        #expect(relationships.activeRumorHeat > 10)

        var state = GameState()
        state.player = player
        state.relationships = relationships
        let weights = StoryletSystem().preferredTagWeights(for: state)

        #expect((weights["social"] ?? 0) > 0)
        #expect(relationships.knownForTags.contains("visible"))
    }

    @Test func repairTensionReducesRelationshipDebt() async throws {
        let system = RelationshipSystem()
        var player = Player()
        player.age = 25
        var relationships = RelationshipState()
        relationships.romanticPartner = Relationship(name: "Alex", type: .romantic, status: .strained, bond: 42, yearsKnown: 3, stage: .committed, isCohabiting: false, commitmentAlignment: 46)
        relationships.tensions = [
            RelationshipTension(
                headline: "The relationship cooled instead of healing",
                impactLine: "Distance made the bond shakier underneath.",
                severity: 64,
                source: .ignoredConnection,
                target: .partner,
                createdAge: 24,
                targetName: "Alex",
                impactedDomains: [.relationships, .health]
            )
        ]
        var family = FamilyState()

        _ = applyRelationshipAction(.repairTension, system: system, player: &player, relationships: &relationships, family: &family)

        #expect(relationships.activeTensionCount == 1)
        #expect(relationships.tensions.first?.severity ?? 0 < 64)
        #expect(relationships.romanticPartner?.status == .active)
        #expect(relationships.privateReputation > 50)
    }

    @Test func milestoneConflictCreatesFuturePressure() async throws {
        let system = RelationshipSystem()
        var relationships = RelationshipState()
        relationships.romanticPartner = Relationship(name: "Morgan", type: .romantic, status: .active, bond: 74, yearsKnown: 2, stage: .committed, isCohabiting: false, commitmentAlignment: 36)
        var result = system.advanceYear(
            player: {
                var player = Player()
                player.age = 26
                player.happiness = 48
                return player
            }(),
            relationships: &relationships,
            family: FamilyState(pregnancy: nil, pregnancyIntent: .trying, postpartumYearsRemaining: 0),
            health: HealthState(),
            housing: HousingState(livingArrangement: .soloRenting, housingCostBand: 48, housingStability: 40, hasRoommate: false),
            financialStress: 58
        )

        #expect(relationships.futureAlignment.familyReadiness <= 46)
        #expect(!relationships.tensions.isEmpty)
        #expect(relationships.futureAlignment.activeConflictHeadline != nil)
    }

    @Test func yearlyTickSurfacesRumorIntoCareerSummary() async throws {
        var state = GameState()
        state.startupState = .active
        state.player.age = 27
        state.player.happiness = 49
        state.education.pathway = .graduate
        state.education.stage = .inactive
        state.career = CareerState(
            status: .fullTime,
            profile: .stableAdmin,
            roleID: "office_assistant",
            level: 1,
            annualIncome: 34_000,
            performance: 62,
            yearsWorked: 2
        )
        state.relationships.romanticPartner = Relationship(name: "Jamie", type: .romantic, status: .active, bond: 62, yearsKnown: 2, stage: .committed, isCohabiting: false, commitmentAlignment: 54)
        state.relationships.publicReputation = 43
        state.relationships.privateReputation = 46
        state.relationships.activeRumorHeat = 72
        state.relationships.tensions = [
            RelationshipTension(
                headline: "Rumor followed your visibility",
                impactLine: "Social noise is making other rooms less stable too.",
                severity: 58,
                source: .rumor,
                target: .socialCircle,
                createdAge: 26,
                targetName: nil,
                impactedDomains: [.relationships, .career]
            )
        ]

        let orchestrator = LifeSimulationOrchestrator()
        _ = orchestrator.advanceYear(state: &state)

        #expect(orchestrator.latestYearSummary != nil)
        #expect(state.career.managerFriction > 34)
        #expect(state.relationships.activeRumorHeat >= 55)
    }

    @Test func activitySystemBlocksUnderageViceActivity() async throws {
        var state = GameState()
        state.player.age = 17
        let system = ActivitySystem()

        let result = system.apply(activityID: "drink_night", to: &state)

        #expect(result == nil)
        #expect(state.activities.yearlyCount == 0)
        #expect(state.history.isEmpty)
    }

    @Test func activitySystemAppliesImmediateEffectsAndHistory() async throws {
        var state = GameState()
        state.player.age = 24
        state.finance.cashOnHand = 600
        let system = ActivitySystem()

        let result = system.apply(activityID: "gym_session", to: &state)

        #expect(result != nil)
        #expect(state.activities.yearlyCount == 1)
        #expect(state.history.first?.tags.contains(.activities) == true)
        #expect(state.healthProfile.physicalWellness > 50)
        #expect(state.finance.cashOnHand < 600)
        #expect(state.activities.recoveryBalance > 0)
    }

    @Test func repeatedRiskActivityBuildsPushback() async throws {
        var state = GameState()
        state.player.age = 24
        state.finance.cashOnHand = 2_000
        let system = ActivitySystem()

        _ = system.apply(activityID: "reckless_night", to: &state)
        _ = system.apply(activityID: "reckless_night", to: &state)
        let third = system.apply(activityID: "reckless_night", to: &state)

        #expect(state.activities.yearlyCount == 3)
        #expect(state.activities.riskLoad >= 9)
        #expect(state.consequences.pressureByDomain["health", default: 0] > 0)
        #expect(third?.detail.contains("repeat payoff tapering") == true)
    }

    @Test func teenStudentUsesEducationFirstOverview() async throws {
        let vm = makeViewModel(.teenEducationPressure)

        #expect(vm.showingEducationAsPrimaryTab)

        let overview = vm.overview(for: .occupation)

        #expect(overview.title == "Education")
        #expect(overview.detailDestination == .educationOverview)
        #expect(overview.topSignals.contains(where: { $0.title == "Readiness" }))
    }

    @Test func legacySaveWithoutFinanceDecodesWithLegacyMoneyFallback() async throws {
        let legacyJSON = """
        {
          "player": {
            "name": "Jordan",
            "age": 19,
            "happiness": 60,
            "smarts": 55,
            "looks": 52,
            "health": 58,
            "money": 4200
          },
          "career": {
            "status": "partTime",
            "annualIncome": 4200,
            "performance": 60,
            "yearsWorked": 1,
            "unemployedYears": 0
          },
          "relationships": { "friends": [], "romanticPartners": [] },
          "healthProfile": {
            "physicalWellness": 60,
            "mentalWellness": 55,
            "habits": { "exercise": 50, "nutrition": 50, "stressManagement": 45 },
            "activeConditions": [],
            "hasPrimaryCare": false
          },
          "assets": { "ownsHome": false },
          "progress": { "unlockedMilestones": [], "legacyScore": 0 },
          "history": [],
          "lastEventYearById": {},
          "isGameOver": false
        }
        """

        let decoded = try JSONDecoder().decode(GameState.self, from: Data(legacyJSON.utf8))

        #expect(decoded.finance.cashOnHand == 4_200)
        #expect(decoded.specialCareer.track == .inactive)
    }

    @Test func legacyCrimeTrackMigratesIntoCrimeState() async throws {
        let legacyJSON = """
        {
          "player": { "name": "Casey", "age": 24, "happiness": 50, "smarts": 50, "looks": 50, "health": 50, "traits": [] },
          "career": { "status": "unemployed", "level": 0, "annualIncome": 0, "performance": 50, "yearsWorked": 0, "unemployedYears": 0 },
          "specialCareer": {
            "track": "crime",
            "tier": 2,
            "heat": 73,
            "notoriety": 69,
            "burnout": 64,
            "yearsActive": 2,
            "lastPayout": 6400
          },
          "finance": { "cashOnHand": 9200, "financialStress": 42 },
          "relationships": { "friends": [], "romanticPartners": [] },
          "healthProfile": {
            "physicalWellness": 60,
            "mentalWellness": 36,
            "habits": { "exercise": 50, "nutrition": 50, "stressManagement": 28 },
            "activeConditions": [],
            "hasPrimaryCare": false
          },
          "assets": { "ownsHome": false },
          "housing": { "livingArrangement": "roommates", "housingCostBand": 25, "housingStability": 46, "hasRoommate": true },
          "progress": { "unlockedMilestones": [], "legacyScore": 0 },
          "history": [],
          "lastEventYearById": {},
          "isGameOver": false
        }
        """

        let decoded = try JSONDecoder().decode(GameState.self, from: Data(legacyJSON.utf8))

        #expect(decoded.specialCareer.track == .inactive)
        #expect(decoded.crime.status == .active)
        #expect(decoded.crime.roleTier == 2)
        #expect(decoded.crime.yearsActive == 2)
        #expect(decoded.crime.lastPayout == 6_400)
    }

    @Test func legacySaveWithoutNarrativeArcsDecodesWithEmptyNarrativeState() async throws {
        let legacyJSON = """
        {
          "player": {
            "name": "Jordan",
            "age": 19,
            "happiness": 60,
            "smarts": 55,
            "looks": 52,
            "health": 58
          },
          "career": {
            "status": "partTime",
            "annualIncome": 4200,
            "performance": 60,
            "yearsWorked": 1,
            "unemployedYears": 0
          },
          "relationships": { "friends": [], "romanticPartners": [] },
          "healthProfile": {
            "physicalWellness": 60,
            "mentalWellness": 55,
            "habits": { "exercise": 50, "nutrition": 50, "stressManagement": 45 },
            "activeConditions": [],
            "hasPrimaryCare": false
          },
          "assets": { "ownsHome": false },
          "progress": { "unlockedMilestones": [], "legacyScore": 0 },
          "history": [],
          "lastEventYearById": {},
          "isGameOver": false
        }
        """

        let decoded = try JSONDecoder().decode(GameState.self, from: Data(legacyJSON.utf8))

        #expect(decoded.narrativeArcs.candidates.isEmpty)
        #expect(decoded.narrativeArcs.primaryArcID == nil)
        #expect(decoded.narrativeArcs.currentMoodTone == nil)
    }

    @Test func encodedStateDoesNotWriteLegacyMoneyField() async throws {
        let state = GameState()

        let data = try JSONEncoder().encode(state)
        let payload = String(decoding: data, as: UTF8.self)

        #expect(!payload.contains("\"money\""))
        #expect(payload.contains("\"cashOnHand\""))
    }

    @Test func previewStartIncludesNarrativeArcCandidates() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        let preview = orchestrator.previewStart(mode: .template, templateID: .financialStrainToughenedEarly, meta: MetaState())

        #expect((2...5).contains(preview.narrativeArcs.candidates.count))
        #expect(preview.narrativeArcs.primaryArcID != nil)
        #expect(preview.narrativeArcs.secondaryArcID != nil)
        #expect(!preview.narrativeArcs.previewTensionLabels.isEmpty)
    }

    @Test func activatingPreviewAddsChapterPressureHistory() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = orchestrator.previewStart(mode: .template, templateID: .academicPromise, meta: MetaState())

        _ = orchestrator.activatePreview(state: &state)

        #expect(state.startupState == .active)
        #expect(state.history.contains(where: { $0.title == "Chapter Pressure" }))
    }

    @Test func localArcGeneratorReflectsFinancialStrainContext() async throws {
        let context = ArcSeedContext(
            templateID: .financialStrainToughenedEarly,
            focusTags: ["money", "career", "routine"],
            openingTags: ["money", "cost"],
            householdPressure: "Money pressure at home",
            schoolStandingText: "Holding on under strain",
            socialSupportText: "Thin but real",
            startingCashBand: "$0-$250 cushion",
            age: 14,
            traits: [.disciplined, .anxious],
            happiness: 48,
            smarts: 58,
            looks: 50,
            health: 57,
            schoolStanding: 54,
            engagement: 52,
            financialStress: 32,
            cashOnHand: 80,
            housingStability: 46
        )

        let generated = LocalArcSeedGenerator().generateCandidates(context: context, state: GameState())

        #expect(generated != nil)
        #expect(generated?.first?.id == "arc_broke_ambitious")
    }

    @Test func invalidRemoteArcPayloadFallsBackToLocalGenerator() async throws {
        let invalidRemote = RemoteArcSeedGenerator(provider: { _ in
            Data("""
            {
              "candidates": [
                {
                  "id": "bad_arc",
                  "title": "At age 19 this must happen",
                  "theme": "ambitionVsPressure",
                  "primaryDomains": ["education"],
                  "eventTagWeights": { "forbidden": 99 },
                  "moodBias": ["focused"],
                  "riskFlags": [],
                  "opportunityFlags": []
                }
              ]
            }
            """.utf8)
        })
        let narrativeSystem = NarrativeArcSystem(remoteGenerator: invalidRemote, localGenerator: LocalArcSeedGenerator())
        let preview = OriginSystem().makePreview(mode: .template, templateID: .financialStrainToughenedEarly, narrativeArcSystem: narrativeSystem, meta: MetaState())

        #expect((2...5).contains(preview.narrativeArcs.candidates.count))
        #expect(!preview.narrativeArcs.candidates.contains(where: { $0.id == "bad_arc" }))
    }

    @Test func storyletWeightsIncludeActiveNarrativeArcPressure() async throws {
        var state = GameState()
        let seed = NarrativeArcSeed(
            id: "arc_test",
            title: "Test Arc",
            theme: .ambitionVsPressure,
            primaryDomains: [.education, .career],
            influence: ArcInfluenceProfile(
                eventTagWeights: ["school": 9, "career": 7],
                moodBias: [.focused],
                riskFlags: [],
                opportunityFlags: [],
                pivotMetadata: ArcPivotMetadata()
            )
        )
        state.narrativeArcs.candidates = [NarrativeArcCandidate(seed: seed, generationScore: 70)]
        state.narrativeArcs.primaryArcID = "arc_test"

        let weights = StoryletSystem().preferredTagWeights(for: state)

        #expect((weights["school"] ?? 0) >= 9)
        #expect((weights["career"] ?? 0) >= 7)
    }

    @Test func yearlyArcEvaluationCanPivotWhenLifeMovesOffPrimaryPattern() async throws {
        let narrativeSystem = NarrativeArcSystem(remoteGenerator: RemoteArcSeedGenerator(), localGenerator: LocalArcSeedGenerator())
        var state = OriginSystem().makePreview(mode: .template, templateID: .academicPromise, narrativeArcSystem: narrativeSystem, meta: MetaState())
        let startingPrimary = state.narrativeArcs.primaryArcID

        state.startupState = .active
        state.player.age = 18
        state.narrativeArcs.lastPivotAge = 15
        state.education.schoolStanding = 34
        state.education.engagement = 28
        state.education.burnoutRisk = 72
        state.finance.cashOnHand = -600
        state.finance.financialStress = 84
        state.housing.housingStability = 25
        state.career.status = .unemployed

        let before = state
        let result = narrativeSystem.evaluateYear(before: before, after: &state)

        #expect(state.narrativeArcs.primaryArcID != nil)
        #expect(state.narrativeArcs.primaryArcID != startingPrimary || !result.notes.isEmpty)
        #expect(result.notes.count <= 1)
    }

    @Test func chaseSpotlightActivatesEntertainmentTrack() async throws {
        let system = SpecialCareerSystem()
        var player = Player()
        player.age = 18
        var career = CareerState(status: .unemployed, roleID: nil, level: 0, annualIncome: 0, performance: 52, yearsWorked: 0, unemployedYears: 0)
        var specialCareer = SpecialCareerState()
        var finance = FinanceState()

        _ = system.applyAction(.chaseSpotlight, player: &player, career: &career, specialCareer: &specialCareer, finance: &finance)

        #expect(specialCareer.track == .entertainment)
        #expect(specialCareer.fame > 0)
        #expect(specialCareer.audience > 0)
    }

    @Test func dormantSpecialCareerActionsNowApplyDomainEffects() async throws {
        let system = SpecialCareerSystem()
        var player = Player()
        player.age = 24
        player.looks = 80
        player.health = 82
        player.smarts = 78
        var finance = FinanceState(cashOnHand: 100_000)

        var founderCareer = CareerState(status: .fullTime, roleID: "operations_coordinator", level: 4, annualIncome: 48_000, performance: 72, yearsWorked: 3, unemployedYears: 0)
        var founder = SpecialCareerState(track: .founder, tier: 1, fame: 0, audience: 30, burnout: 0, yearsActive: 0, lastPayout: 0)
        founder.heat = 40
        founder.boardPressure = 25
        _ = system.applyAction(.pivotBusiness, player: &player, career: &founderCareer, specialCareer: &founder, finance: &finance)
        #expect(founder.heat < 40)
        #expect(founder.boardPressure < 25)

        var athleteCareer = founderCareer
        var athlete = SpecialCareerState()
        let training = system.applyAction(.intenseTraining, player: &player, career: &athleteCareer, specialCareer: &athlete, finance: &finance)
        #expect(athlete.track == .athlete)
        #expect(athlete.audience > 0)
        #expect(training.healthEffects != nil)

        let beforeCompetitionHeat = athlete.heat
        _ = system.applyAction(.compete, player: &player, career: &athleteCareer, specialCareer: &athlete, finance: &finance)
        #expect(athlete.track == .athlete)
        #expect(athlete.heat > beforeCompetitionHeat)

        var operativeCareer = CareerState(status: .fullTime, roleID: "systems_analyst", level: 4, annualIncome: 76_000, performance: 78, yearsWorked: 4, unemployedYears: 0)
        operativeCareer.profile = .credentialedProfessional
        operativeCareer.careerExperience[.technical] = 2
        var operative = SpecialCareerState()
        _ = system.applyAction(.gatherIntelligence, player: &player, career: &operativeCareer, specialCareer: &operative, finance: &finance)
        #expect(operative.track == .shadowOperative)
        #expect(operative.notoriety > 0)

        let leverage = system.applyAction(.exploitLeverage, player: &player, career: &operativeCareer, specialCareer: &operative, finance: &finance)
        #expect((leverage.financeEffects?.cashDelta ?? 0) > 0)

        var traderCareer = founderCareer
        var trader = SpecialCareerState()
        let trade = system.applyAction(.dayTrade, player: &player, career: &traderCareer, specialCareer: &trader, finance: &finance)
        #expect(trader.track == .trader)
        #expect(trade.financeEffects != nil)

        let heatBeforeStudy = trader.heat
        _ = system.applyAction(.analyzeMarkets, player: &player, career: &traderCareer, specialCareer: &trader, finance: &finance)
        #expect(trader.track == .trader)
        #expect(trader.heat <= heatBeforeStudy)
    }

    @Test func runSchemeActivatesCrimeTrack() async throws {
        let system = CrimeSystem()
        var player = Player()
        player.age = 18
        var career = CareerState(status: .unemployed, roleID: nil, level: 0, annualIncome: 0, performance: 52, yearsWorked: 0, unemployedYears: 0)
        var crime = CrimeState()

        _ = system.applyAction(.runScheme, player: &player, career: &career, crime: &crime)

        #expect(crime.status == .active)
        #expect(crime.heat > 0)
        #expect(crime.notoriety > 0)
    }

    @Test func entertainmentTrackCanProduceBreakoutAndZeroPayoutYears() async throws {
        let system = SpecialCareerSystem()

        var breakoutState = GameState()
        breakoutState.player.age = 24
        breakoutState.player.looks = 75
        breakoutState.player.happiness = 66
        // Deterministic `normalizedRoll` needs fame + audience high enough to land in the breakout band (>= 88).
        breakoutState.specialCareer = SpecialCareerState(track: .entertainment, tier: 2, fame: 100, audience: 100, burnout: 0, yearsActive: 0, lastPayout: 0)

        let breakoutResult = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: breakoutState).specialCareer,
            player: &breakoutState.player,
            career: &breakoutState.career,
            specialCareer: &breakoutState.specialCareer
        )

        #expect(breakoutState.specialCareer.lastPayout >= 4_000)
        #expect((breakoutResult.financeEffects?.cashDelta ?? 0) >= 4_000)

        var collapseState = GameState()
        collapseState.player.age = 18
        collapseState.player.looks = 20
        collapseState.player.happiness = 20
        collapseState.specialCareer = SpecialCareerState(track: .entertainment, tier: 1, fame: 0, audience: 0, burnout: 96, yearsActive: 0, lastPayout: 0)

        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: collapseState).specialCareer,
            player: &collapseState.player,
            career: &collapseState.career,
            specialCareer: &collapseState.specialCareer
        )

        #expect(collapseState.specialCareer.track == .inactive)
        #expect(collapseState.specialCareer.lastPayout == 0)
    }

    @Test func burnoutReducesEntertainmentOutcomeQuality() async throws {
        let system = SpecialCareerSystem()

        var restedState = GameState()
        restedState.player.age = 20
        restedState.player.looks = 50
        restedState.player.happiness = 66
        restedState.specialCareer = SpecialCareerState(track: .entertainment, tier: 2, fame: 50, audience: 50, burnout: 0, yearsActive: 0, lastPayout: 0)

        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: restedState).specialCareer,
            player: &restedState.player,
            career: &restedState.career,
            specialCareer: &restedState.specialCareer
        )

        var burnedOutState = GameState()
        burnedOutState.player.age = 20
        burnedOutState.player.looks = 50
        burnedOutState.player.happiness = 66
        burnedOutState.specialCareer = SpecialCareerState(track: .entertainment, tier: 2, fame: 50, audience: 50, burnout: 50, yearsActive: 0, lastPayout: 0)

        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: burnedOutState).specialCareer,
            player: &burnedOutState.player,
            career: &burnedOutState.career,
            specialCareer: &burnedOutState.specialCareer
        )

        #expect(burnedOutState.specialCareer.lastPayout < restedState.specialCareer.lastPayout)
    }

    @Test func recordLabelOwnerCanActivateFromEntertainmentCred() async throws {
        let system = SpecialCareerSystem()
        var state = GameState()
        state.player.age = 28
        state.finance.cashOnHand = 20_000
        state.specialCareer = SpecialCareerState(track: .entertainment, tier: 2, fame: 50, audience: 50, burnout: 15, yearsActive: 4, lastPayout: 2_000)

        #expect(SpecialCareerSystem.qualificationIssue(for: .startRecordLabel, state: state) == nil)

        let result = system.applyAction(
            .startRecordLabel,
            player: &state.player,
            career: &state.career,
            specialCareer: &state.specialCareer,
            childhoodDossier: state.childhoodDossier,
            finance: &state.finance
        )

        #expect(state.specialCareer.track == .recordLabelOwner)
        #expect(state.specialCareer.recordLabel.roster.count <= 1)
        #expect(state.specialCareer.recordLabel.labelPrestige >= 22)
        #expect((result.financeEffects?.cashDelta ?? 0) == -8_000)
    }

    @Test func founderAndCreatorMenusExposeQualifiedDiamondTransitions() async throws {
        var founderState = GameState()
        founderState.player.age = 32
        founderState.finance.cashOnHand = 100_000
        founderState.career.status = .fullTime
        founderState.career.profile = .credentialedProfessional
        founderState.career.performance = 82
        founderState.specialCareer.track = .founder
        founderState.specialCareer.founder.personalLegend = 50

        let founderRegistry = DomainActionRegistry(
            context: DomainActionContext(
                state: founderState,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: true,
                investmentEmergencyReserve: 2_500
            )
        )
        let founderChoices = founderRegistry.availableCommitted(for: .career)
        #expect(founderChoices.contains(.manageFund))
        #expect(founderChoices.contains(.acquireCompetitor))
        #expect(founderChoices.contains(.dayTrade))
        #expect(founderChoices.contains(.gatherIntelligence))

        var creatorState = founderState
        creatorState.specialCareer.track = .contentCreator
        creatorState.specialCareer.creator.personalBrand = 55
        creatorState.specialCareer.fame = 60
        creatorState.specialCareer.audience = 65

        let creatorRegistry = DomainActionRegistry(
            context: DomainActionContext(
                state: creatorState,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: true,
                investmentEmergencyReserve: 2_500
            )
        )
        let creatorChoices = creatorRegistry.availableCommitted(for: .career)
        #expect(creatorChoices.contains(.startMovieProducer))
        #expect(creatorChoices.contains(.startRecordLabel))
        #expect(creatorChoices.contains(.manageFund))
        #expect(creatorChoices.contains(.dayTrade))
    }

    @Test func diamondTransitionPreservesRecognitionAndRecordsOrigin() async throws {
        let system = SpecialCareerSystem()
        var state = GameState()
        state.player.age = 31
        state.finance.cashOnHand = 100_000
        state.specialCareer = SpecialCareerState(
            track: .entertainment,
            tier: 3,
            fame: 62,
            audience: 74,
            burnout: 18,
            yearsActive: 7,
            lastPayout: 8_000
        )

        let entry = system.applyAction(
            .startMovieProducer,
            player: &state.player,
            career: &state.career,
            specialCareer: &state.specialCareer,
            finance: &state.finance
        )

        #expect(state.specialCareer.track == .movieProducer)
        #expect(state.specialCareer.diamondOriginTrack == .entertainment)
        #expect(state.specialCareer.firstDiamondEntryAge == 31)
        #expect(state.specialCareer.diamondTransitions == 1)
        #expect(state.specialCareer.fame >= 62)
        #expect(state.specialCareer.audience >= 74)
        #expect(entry.notes.filter { $0.title == "First Empire" }.count == 1)

        let followUp = system.applyAction(
            .optionScript,
            player: &state.player,
            career: &state.career,
            specialCareer: &state.specialCareer,
            finance: &state.finance
        )
        #expect(!followUp.notes.contains(where: { $0.title == "First Empire" }))
        #expect(state.specialCareer.diamondTransitions == 1)
    }

    @Test func diamondCareerStateRoundTripsPipelineAndBusinessFields() async throws {
        var original = SpecialCareerState(
            track: .ventureCapitalist,
            tier: 3,
            fame: 71,
            audience: 68,
            heat: 24,
            notoriety: 52,
            burnout: 39,
            yearsActive: 3,
            lastPayout: 12_000
        )
        original.sector = .gaming
        original.advisors = [BusinessAdvisor(name: "Elena", specialty: .strategy, yearlyFee: 2_000)]
        original.equityOwned = 0.64
        original.boardPressure = 47
        original.capitalUnderManagement = 350_000
        original.diamondOriginTrack = .founder
        original.firstDiamondEntryAge = 36
        original.diamondTransitions = 1

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SpecialCareerState.self, from: data)

        #expect(decoded == original)
    }

    @Test func activeDiamondMenusKeepTheirOperatingActionsReachable() async throws {
        let expected: [(SpecialCareerTrack, ActionChoiceID)] = [
            (.shadowOperative, .exploitLeverage),
            (.trader, .analyzeMarkets),
            (.ventureCapitalist, .hireAdvisor),
            (.corporateRaider, .stripAssets)
        ]

        for (track, action) in expected {
            var state = GameState()
            state.player.age = 40
            state.specialCareer.track = track
            let registry = DomainActionRegistry(
                context: DomainActionContext(
                    state: state,
                    isTeenExperience: false,
                    isStudentLifeExperience: false,
                    canAccessInvesting: true,
                    investmentEmergencyReserve: 2_500
                )
            )
            #expect(registry.availableCommitted(for: .career).contains(action))
        }
    }

    @Test func recordLabelRosterLoopBuildsCatalogAndPrestige() async throws {
        let system = SpecialCareerSystem()
        var state = GameState()
        state.player.age = 30
        state.specialCareer.track = .recordLabelOwner
        state.specialCareer.recordLabel.roster = [
            LabelArtist(name: "Mira Vale", talent: 88, popularity: 70, morale: 75, contractFairness: 60, catalogCount: 0, tourReadiness: 70, yearlyEarnings: 0)
        ]
        state.specialCareer.recordLabel.labelPrestige = 55
        state.specialCareer.recordLabel.artistTrust = 70

        _ = system.applyAction(.signArtist, player: &state.player, career: &state.career, specialCareer: &state.specialCareer, finance: &state.finance)
        let rosterCount = state.specialCareer.recordLabel.roster.count
        _ = system.applyAction(.developArtist, player: &state.player, career: &state.career, specialCareer: &state.specialCareer, finance: &state.finance)
        _ = system.applyAction(.releaseRecord, player: &state.player, career: &state.career, specialCareer: &state.specialCareer, finance: &state.finance)

        #expect(rosterCount >= 2)
        #expect(state.specialCareer.recordLabel.catalogStrength > 10)
        #expect(state.specialCareer.recordLabel.roster.contains { $0.catalogCount > 0 })
        #expect(state.specialCareer.fame > 0)
    }

    @Test func recordLabelYearPaysFinanceAndArtists() async throws {
        let system = SpecialCareerSystem()
        var state = GameState()
        state.player.age = 34
        state.specialCareer.track = .recordLabelOwner
        state.specialCareer.recordLabel = RecordLabelState(
            roster: [
                LabelArtist(name: "Saint June", talent: 82, popularity: 76, morale: 68, contractFairness: 58, catalogCount: 3, tourReadiness: 70, yearlyEarnings: 0),
                LabelArtist(name: "Koa Black", talent: 72, popularity: 52, morale: 61, contractFairness: 55, catalogCount: 2, tourReadiness: 58, yearlyEarnings: 0)
            ],
            catalogStrength: 72,
            tourMachine: 54,
            artistTrust: 66,
            cashflowPressure: 24,
            industryHeat: 18,
            labelPrestige: 68,
            artistPayoutPolicy: .standard
        )

        let result = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).specialCareer,
            player: &state.player,
            career: &state.career,
            specialCareer: &state.specialCareer
        )

        #expect(result.financeEffects != nil)
        #expect(state.specialCareer.recordLabel.roster.allSatisfy { $0.yearlyEarnings > 0 })
        #expect(state.specialCareer.fame > 0)
    }

    @Test func recordLabelCanCollapseFromLowTrustAndHighHeat() async throws {
        let system = SpecialCareerSystem()
        var state = GameState()
        state.player.age = 38
        state.specialCareer.track = .recordLabelOwner
        state.specialCareer.recordLabel = RecordLabelState(
            roster: [
                LabelArtist(name: "Noah Rook", talent: 65, popularity: 55, morale: 5, contractFairness: 12, catalogCount: 2, tourReadiness: 40, yearlyEarnings: 0)
            ],
            catalogStrength: 40,
            tourMachine: 35,
            artistTrust: 5,
            cashflowPressure: 80,
            industryHeat: 95,
            labelPrestige: 35,
            artistPayoutPolicy: .exploitative
        )

        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).specialCareer,
            player: &state.player,
            career: &state.career,
            specialCareer: &state.specialCareer
        )

        #expect(state.specialCareer.track == .inactive)
    }

    @Test func highHeatCrimeYearCanTriggerForcedExitAndDownstreamDamage() async throws {
        let system = CrimeSystem()
        var state = GameState()
        state.player.age = 18
        state.career = CareerState(status: .fullTime, roleID: "office_assistant", level: 3, annualIncome: 24_000, performance: 62, yearsWorked: 1, unemployedYears: 0)
        state.crime = CrimeState(status: .active, roleTier: 2, heat: 80, notoriety: 40, burnout: 10, crewID: "crew", loyalty: 45, territoryPressure: 35, yearsActive: 0, lastPayout: 0)
        state.finance = FinanceState(cashOnHand: 100)
        state.healthProfile = HealthState(physicalWellness: 60, mentalWellness: 20, habits: LifestyleHabits(), activeConditions: [], hasPrimaryCare: false)
        state.housing = HousingState(livingArrangement: .roommates, housingCostBand: 25, housingStability: 20, hasRoommate: true)

        let result = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).crime,
            player: &state.player,
            career: &state.career,
            crime: &state.crime
        )

        #expect(state.crime.yearsActive == 1)
        #expect(result.notes.isEmpty)
    }

    @Test func millionaireMilestoneReadsFinanceCash() async throws {
        let progressSystem = ProgressSystem()
        var state = GameState()
        state.player.age = 36
        state.finance.cashOnHand = 1_100_000
        state.finance.stabilityStreakYears = 6

        let result = progressSystem.unlockNewMilestones(for: &state)

        #expect(state.progress.unlockedMilestones.contains(where: { $0.id == .millionaire }))
        #expect(result.notes.contains(where: { $0.text.contains("Millionaire") }))
    }

    @Test func eventApplicationRoutesCashThroughFinanceOnly() async throws {
        let event = GameEvent(
            id: "test_finance",
            category: .finance,
            tags: ["money"],
            title: "Test Finance",
            text: "A finance-only event.",
            minAge: 14,
            maxAge: 90,
            weight: 1,
            cooldownYears: 0,
            requirements: [],
            choices: [
                EventChoice(
                    text: "Take it",
                    effects: ChoiceEffects(
                        core: CoreStatEffects(happiness: 1, smarts: nil, looks: nil, health: nil),
                        career: nil,
                        finance: FinanceEffects(cashDelta: 500, livingCostDelta: nil, educationCostDelta: nil, dependentCostDelta: nil, discretionaryCostDelta: nil, financialStressDelta: nil, setRegionPolicyID: nil),
                        relationship: nil,
                        health: nil
                    )
                )
            ]
        )

        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: [event]))
        var state = GameState()
        state.player.traits = []

        orchestrator.apply(choice: event.choices[0], event: event, state: &state)

        #expect(state.finance.cashOnHand == 750)
        #expect(state.player.happiness == 59)
    }

    @Test func joinActivityBuildsMomentumAndSocialCarryover() async throws {
        let system = EducationSystem()
        var player = Player()
        var education = EducationState()

        let result = applyEducationAction(.joinActivity, system: system, player: &player, education: &education)

        #expect(education.engagement == 61)
        #expect(education.activityMomentum == 30)
        #expect(result.relationshipEffects?.meetNewFriend == true)
    }

    @Test func smallHustleAddsCashButCostsRecovery() async throws {
        let system = FinanceSystem()
        var finance = FinanceState(cashOnHand: 250)
        var player = Player()
        player.age = 14

        let result = system.applyAction(.smallHustle, finance: &finance, player: &player)

        #expect(finance.cashOnHand == 430)
        #expect(result.healthEffects?.mental == -1)
        #expect(result.healthEffects?.stressManagement == -2)
    }

    @Test func protectSleepReturnsEducationReliefThroughActionSystem() async throws {
        let system = ActionSystem()
        var state = GameState()
        state.player.age = 14
        state.education.attendancePressure = 50
        state.healthProfile.mentalWellness = 40

        _ = system.apply(actions: [PlayerYearAction(domain: .health, choiceID: .protectSleep)], state: &state)

        #expect(state.healthProfile.mentalWellness == 45)
        #expect(state.education.attendancePressure == 46)
    }

    @Test func scholarshipNeedsStandingAndActivityMomentum() async throws {
        let system = EducationSystem()
        var player = Player()
        player.age = 16
        var career = CareerState()
        var education = EducationState()
        education.schoolStanding = 78
        education.activityMomentum = 45
        education.engagement = 60
        let finance = FinanceState()
        var military = MilitaryState()

        _ = system.advanceYear(
            player: &player,
            education: &education,
            military: &military,
            career: &career,
            finance: finance,
            relationships: RelationshipState(),
            health: HealthState(),
            policySupport: 0
        )

        #expect(education.hasScholarship)
    }

    @Test func traitAndCareerBonusesAccumulateInFinanceCash() async throws {
        var state = GameState()
        state.player.traits = [.lucky]
        state.career.roleID = "office_assistant"
        state.career.status = .fullTime
        state.career.annualIncome = 24_000
        state.career.performance = 80

        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        let startingCash = state.finance.cashOnHand

        _ = orchestrator.advanceYear(state: &state)

        #expect(state.finance.cashOnHand != startingCash)
        #expect(state.finance.cashOnHand > 0)
    }

    private func sampleEventsJSONURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("OneLife")
            .appendingPathComponent("SampleEvents.json")
    }

    @Test func eventEngineDefersBundleLoadUntilFirstUse() async throws {
        let engine = EventEngine()
        #expect(engine.isEventPackLoaded == false)
        #expect(engine.allEvents.isEmpty)

        var state = GameState()
        state.startupState = .active
        state.player.age = 30
        _ = engine.pickEvent(for: state)

        #expect(engine.isEventPackLoaded == true)
        #expect(!engine.allEvents.isEmpty)
    }

    @Test func injectedEventEngineMarksPackLoadedWithoutBundle() async throws {
        let engine = EventEngine(events: [])
        #expect(engine.isEventPackLoaded == true)
        #expect(engine.allEvents.isEmpty)
    }

    @Test func contentPackBalancesAllPrimaryDomains() async throws {
        let url = sampleEventsJSONURL()
        let data = try Data(contentsOf: url)
        let pack = try JSONDecoder().decode(EventPack.self, from: data)
        let grouped = Dictionary(grouping: pack.events, by: \.category)

        #expect((grouped[.education] ?? []).count >= 2)
        #expect((grouped[.career] ?? []).count >= 2)
        #expect((grouped[.relationships] ?? []).count >= 3)
        #expect((grouped[.health] ?? []).count >= 3)
    }

    @Test func educationSystemCanGraduateTeenIntoAdultReadiness() async throws {
        var player = Player()
        player.age = 18
        player.smarts = 68
        var education = EducationState()
        education.pathway = .student
        education.schoolStanding = 76
        education.engagement = 72
        education.attendancePressure = 20
        var career = CareerState()
        var military = MilitaryState()
        let system = EducationSystem()

        let result = system.advanceYear(
            player: &player,
            education: &education,
            military: &military,
            career: &career,
            finance: FinanceState(),
            relationships: RelationshipState(),
            health: HealthState(),
            policySupport: 2
        )

        #expect(education.pathway == .graduate)
        #expect(education.credentials.contains("Diploma"))
        #expect(result.notes.contains(where: { $0.title == "Education" }))
    }

    @Test func actionSystemAppliesChosenActionsAndClearsQueue() async throws {
        var state = GameState()
        state.pendingActions = [
            PlayerYearAction(domain: .education, choiceID: .studyHard),
            PlayerYearAction(domain: .finance, choiceID: .takeSideWork),
            PlayerYearAction(domain: .health, choiceID: .rest)
        ]

        let result = ActionSystem().apply(actions: state.pendingActions, state: &state)

        #expect(state.education.schoolStanding > 56)
        #expect(state.finance.cashOnHand > 250)
        #expect(state.healthProfile.mentalWellness > 55)
        #expect(state.pendingActions.isEmpty)
        #expect(!result.notes.isEmpty)
    }

    @Test func housingAndPolicyInfluenceYearlyCosts() async throws {
        let policySystem = PolicySystem()
        let financeSystem = FinanceSystem()
        var finance = FinanceState(cashOnHand: 4_000, currentRegionPolicyID: "expensive_coastal")

        let player = Player()

        financeSystem.advanceYear(
            context: FinanceYearContext(
                age: 25,
                isSchoolAge: false,
                careerStatus: .fullTime,
                grossIncome: 36_000,
                traits: [],
                educationPathway: .graduate,
                educationStage: .inactive,
                hasScholarship: false,
                housingCostBand: 55,
                housingArrangement: .soloRenting,
                activeConditionCount: 0,
                ownsHome: false,
                hasPrimaryCare: true,
                friendCount: 0,
                partnerCount: 0,
                hasSpouse: false,
                hasCohabitingPartner: false,
                isPregnant: false,
                pregnancyPhase: nil,
                infantCount: 0,
                childCount: 0
            ),
            finance: &finance,
            player: player
        )

        #expect(policySystem.currentPolicy(for: finance).id == "expensive_coastal")
        #expect(finance.annualLivingCost > 22_000)
        #expect(finance.effectiveTaxRate > 18)
    }

    @Test func financeSystemReturnsPressureEffectsInsteadOfMutatingOtherDomains() async throws {
        let system = FinanceSystem()
        var finance = FinanceState(cashOnHand: -2_500)
        finance.financialStress = 60

        let result = system.advanceYear(
            context: FinanceYearContext(
                age: 28,
                isSchoolAge: false,
                careerStatus: .unemployed,
                grossIncome: 0,
                traits: [.anxious],
                educationPathway: .dropout,
                educationStage: .inactive,
                hasScholarship: false,
                housingCostBand: 55,
                housingArrangement: .soloRenting,
                activeConditionCount: 1,
                ownsHome: false,
                hasPrimaryCare: false,
                friendCount: 1,
                partnerCount: 0,
                hasSpouse: false,
                hasCohabitingPartner: false,
                isPregnant: false,
                pregnancyPhase: nil,
                infantCount: 0,
                childCount: 0
            ),
            finance: &finance,
            player: Player()
        )

        #expect(result.coreEffects?.happiness ?? 0 < 0)
        #expect(result.healthEffects?.mental ?? 0 < 0)
        #expect(result.relationshipEffects?.friendChange ?? 0 < 0)
    }

    @Test func discussFutureCanAdvanceCommittedPartnerIntoMarriage() async throws {
        let system = RelationshipSystem()
        var player = Player()
        player.age = 28
        var relationships = RelationshipState()
        relationships.romanticPartner = Relationship(
            name: "Taylor",
            type: .romantic,
            bond: 89,
            yearsKnown: 5,
            stage: .engaged,
            isCohabiting: true,
            commitmentAlignment: 80
        )
        var family = FamilyState()

        _ = applyRelationshipAction(.discussFuture, system: system, player: &player, relationships: &relationships, family: &family)

        #expect(relationships.romanticPartner?.stage == .engaged)
    }

    @Test func weakRelationshipDoesNotAutoAdvanceToMarriage() async throws {
        let system = RelationshipSystem()
        var player = Player()
        player.age = 27
        var relationships = RelationshipState()
        relationships.romanticPartner = Relationship(
            name: "Alex",
            type: .romantic,
            bond: 61,
            yearsKnown: 2,
            stage: .dating,
            isCohabiting: false,
            commitmentAlignment: 48
        )
        var family = FamilyState()

        _ = applyRelationshipAction(.discussFuture, system: system, player: &player, relationships: &relationships, family: &family)

        #expect(relationships.romanticPartner?.stage == .dating)
    }

    @Test func familyPlanningIntentChangesConceptionChance() async throws {
        let system = FamilySystem()
        var player = Player()
        player.age = 30
        var relationships = RelationshipState()
        relationships.romanticPartner = Relationship(
            name: "Jamie",
            type: .romantic,
            bond: 86,
            yearsKnown: 4,
            stage: .married,
            isCohabiting: true,
            commitmentAlignment: 82
        )
        let health = HealthState()
        let finance = FinanceState(cashOnHand: 12_000)

        let tryingChance = system.conceptionChance(
            player: player,
            relationships: relationships,
            family: FamilyState(children: [], pregnancy: nil, pregnancyIntent: .trying, postpartumYearsRemaining: 0),
            health: health,
            finance: finance
        )
        let avoidingChance = system.conceptionChance(
            player: player,
            relationships: relationships,
            family: FamilyState(children: [], pregnancy: nil, pregnancyIntent: .avoid, postpartumYearsRemaining: 0),
            health: health,
            finance: finance
        )

        #expect(tryingChance > avoidingChance)
    }

    @Test func familySystemCanResolveThirdTrimesterToBirth() async throws {
        let system = FamilySystem()
        var player = Player()
        player.age = 29
        var family = FamilyState(
            children: [],
            pregnancy: PregnancyState(phase: .thirdTrimester, otherParentName: "Jordan", isPlanned: true, isHighRisk: false, yearsActive: 0),
            pregnancyIntent: .trying,
            postpartumYearsRemaining: 0
        )
        let relationships = RelationshipState()
        let result = system.advanceYear(
            player: player,
            relationships: relationships,
            family: &family,
            health: HealthState(),
            finance: FinanceState(cashOnHand: 6_000)
        )

        #expect(family.pregnancy == nil)
        #expect(family.childCount == 1)
        #expect(family.postpartumYearsRemaining == 2)
        #expect(result.financeEffects?.dependentCostDelta ?? 0 > 0)
    }

    @Test func financeDependentCostReflectsPregnancyAndChildren() async throws {
        let system = FinanceSystem()
        var finance = FinanceState(cashOnHand: 10_000)
        var player = Player()
        player.age = 31

        system.advanceYear(
            context: FinanceYearContext(
                age: 31,
                isSchoolAge: false,
                careerStatus: .fullTime,
                grossIncome: 45_000,
                traits: [],
                educationPathway: .graduate,
                educationStage: .inactive,
                hasScholarship: false,
                housingCostBand: 45,
                housingArrangement: .soloRenting,
                activeConditionCount: 0,
                ownsHome: false,
                hasPrimaryCare: true,
                friendCount: 2,
                partnerCount: 1,
                hasSpouse: true,
                hasCohabitingPartner: true,
                isPregnant: true,
                pregnancyPhase: .secondTrimester,
                infantCount: 1,
                childCount: 1
            ),
            finance: &finance,
            player: player
        )

        #expect(finance.annualDependentCost >= 9_000)
    }

    @Test func familySystemActivationHibernatesWhenNoPartnerOrChildrenExist() async throws {
        let registry = SystemRegistry()
        var state = GameState()
        state.player.age = 17

        #expect(!registry.isActive(.family, for: state))

        state.player.age = 26
        state.relationships.romanticPartner = Relationship(name: "Morgan", type: .romantic, bond: 70, yearsKnown: 2, stage: .committed, isCohabiting: false, commitmentAlignment: 60)

        #expect(registry.isActive(.family, for: state))
    }

    @Test func orchestratorSkipsAssetSystemForTeenYears() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = GameState()
        state.player.age = 15
        state.finance.cashOnHand = 200_000
        state.career.status = .fullTime

        _ = orchestrator.advanceYear(state: &state)

        #expect(!state.assets.ownsHome)
    }

    @Test func persistenceLoadsEnvelopeFromPrimarySave() async throws {
        let harness = try PersistenceTestHarness()
        var state = GameState()
        state.player.name = "Avery"

        _ = try harness.coordinator.save(state)
        let result = harness.coordinator.loadForStartup()

        guard case .loaded(let loadResult) = result else {
            Issue.record("Expected primary save to load successfully.")
            return
        }

        #expect(loadResult.recoveryResult == .primary)
        #expect(loadResult.state.player.name == "Avery")
    }

    @Test func persistenceLoadsLegacyRawStateFromPrimaryPath() async throws {
        let harness = try PersistenceTestHarness()
        var state = GameState()
        state.player.name = "Jordan"

        try harness.writeRawState(state, to: harness.primaryURL)
        let result = harness.coordinator.loadForStartup()

        guard case .loaded(let loadResult) = result else {
            Issue.record("Expected legacy primary save to load successfully.")
            return
        }

        #expect(loadResult.recoveryResult == .legacyPrimary)
        #expect(loadResult.state.player.name == "Jordan")
    }

    @Test func persistenceLoadsLegacyRawStateFromLegacyFile() async throws {
        let harness = try PersistenceTestHarness()
        var state = GameState()
        state.player.name = "Casey"

        try harness.writeRawState(state, to: harness.legacyURL)
        let result = harness.coordinator.loadForStartup()

        guard case .loaded(let loadResult) = result else {
            Issue.record("Expected legacy filename save to load successfully.")
            return
        }

        #expect(loadResult.recoveryResult == .legacyFile)
        #expect(loadResult.state.player.name == "Casey")
    }

    @Test func persistenceRecoversFromBackupWhenPrimaryIsCorrupted() async throws {
        let harness = try PersistenceTestHarness()
        var state = GameState()
        state.player.name = "Backup Hero"

        _ = try harness.coordinator.save(state)
        try Data("not-json".utf8).write(to: harness.primaryURL, options: [.atomic])

        let result = harness.coordinator.loadForStartup()

        guard case .loaded(let loadResult) = result else {
            Issue.record("Expected backup recovery to succeed.")
            return
        }

        #expect(loadResult.recoveryResult == .backup)
        #expect(loadResult.state.player.name == "Backup Hero")
        #expect(loadResult.errors.contains(where: {
            if case .decodeFailure(let path, _) = $0 {
                return path == harness.primaryURL.path
            }
            return false
        }))
    }

    @Test func persistenceFailsWhenPrimaryAndBackupAreCorrupted() async throws {
        let harness = try PersistenceTestHarness()

        try Data("bad-primary".utf8).write(to: harness.primaryURL, options: [.atomic])
        try Data("bad-backup".utf8).write(to: harness.backupURL, options: [.atomic])

        let result = harness.coordinator.loadForStartup()

        guard case .failed(let primaryError, let errors, _) = result else {
            Issue.record("Expected startup load failure when no valid save remains.")
            return
        }

        #expect(errors.count >= 3)
        if case .noValidSave = primaryError {
            #expect(true)
        } else {
            Issue.record("Expected a noValidSave error.")
        }
    }

    @Test func viewModelSurfacesSaveFailureWithoutCrashing() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let fileURL = tempDirectory.appendingPathComponent("not-a-directory")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        try Data("blocked".utf8).write(to: fileURL, options: [.atomic])

        let coordinator = PersistenceCoordinator(directoryProvider: { fileURL })
        let viewModel = GameViewModel(persistence: coordinator, defaults: temporaryDefaults())
        viewModel.save()

        #expect(viewModel.persistenceBanner?.contains("Couldn't save") == true)
    }

    @Test func persistenceResetRemovesAllArtifacts() async throws {
        let harness = try PersistenceTestHarness()
        let state = GameState()

        _ = try harness.coordinator.save(state)
        try harness.writeRawState(state, to: harness.legacyURL)
        try harness.coordinator.reset()

        #expect(!FileManager.default.fileExists(atPath: harness.primaryURL.path))
        #expect(!FileManager.default.fileExists(atPath: harness.backupURL.path))
        #expect(!FileManager.default.fileExists(atPath: harness.legacyURL.path))
        #expect(harness.coordinator.loadForStartup() == .noSave)
        #expect(harness.coordinator.hasPersistedSave() == false)
    }

    @Test func hasPersistedSaveDetectsSaveWithoutDecoding() async throws {
        let harness = try PersistenceTestHarness()
        #expect(harness.coordinator.hasPersistedSave() == false)

        _ = try harness.coordinator.save(GameState())
        #expect(harness.coordinator.hasPersistedSave() == true)
    }

    @Test func persistencePrunesHistoryToBudget() async throws {
        let harness = try PersistenceTestHarness()
        var state = GameState()
        state.history = (0..<(PerformanceBudgets.maxPersistedHistoryItems + 25)).map { index in
            HistoryEntry(age: index, title: "Entry \(index)", text: "History \(index)")
        }

        let result = try harness.coordinator.save(state)
        let persisted = try harness.readEnvelope()

        #expect(result.timingSnapshot.persistedHistoryCount == PerformanceBudgets.maxPersistedHistoryItems)
        #expect(persisted.gameState.history.count == PerformanceBudgets.maxPersistedHistoryItems)
    }

    @Test func persistenceRoundTripsRepresentativeStateAcrossDomains() async throws {
        let harness = try PersistenceTestHarness()
        var state = GameState()
        state.player.name = "Morgan"
        state.player.age = 28
        state.player.traits = [.disciplined, .lucky]
        state.career.roleID = "office_assistant"
        state.career.status = .fullTime
        state.career.annualIncome = 24_000
        state.finance.cashOnHand = 8_400
        state.relationships.friends = [Relationship(name: "Riley", type: .friend, bond: 72, yearsKnown: 6)]
        state.relationships.romanticPartner = Relationship(name: "Taylor", type: .romantic, bond: 91, yearsKnown: 6, stage: .married, isCohabiting: true, commitmentAlignment: 82)
        state.family.children = [ChildRecord(name: "Noah", age: 2, livesAtHome: true, otherParentName: "Taylor", supportLoad: 60)]
        state.healthProfile.activeConditions = [HealthCondition(name: "Burnout", severity: 22)]
        state.assets.ownsHome = true
        state.progress.legacyScore = 42
        state.history = [HistoryEntry(age: 28, title: "Milestone", text: "Test history")]
        state.originProfile = OriginProfile(
            startMode: .template,
            templateID: .academicPromise,
            householdPressure: "Moderate",
            schoolStanding: "Excellent",
            socialSupport: "Steady",
            starterTraitBias: [.disciplined],
            startingCashBand: "$500-$900",
            focusTags: ["career"],
            openingEventSeed: ["school"],
            homeSummary: "Home summary",
            schoolSummary: "School summary",
            selfSummary: "Self summary",
            signalHighlights: ["Focused"]
        )
        state.startupState = .active

        // Match post-decode finance normalization so round-trip equality holds.
        state.finance.normalizeInvestmentBalances()

        _ = try harness.coordinator.save(state)
        let result = harness.coordinator.loadForStartup()

        guard case .loaded(let loadResult) = result else {
            Issue.record("Expected representative state to round-trip.")
            return
        }

        #expect(loadResult.state == state)
    }

    @Test func eventEngineHandlesLargeSyntheticPack() async throws {
        let events = (0..<400).map { index in
            GameEvent(
                id: "event_\(index)",
                category: .general,
                tags: ["routine"],
                title: "Event \(index)",
                text: "Synthetic event \(index)",
                minAge: 14,
                maxAge: 90,
                weight: 1,
                cooldownYears: 0,
                requirements: [],
                choices: [EventChoice(text: "Okay", effects: ChoiceEffects())]
            )
        }

        let engine = EventEngine(events: events)
        let state = GameState()

        #expect(engine.pickEvent(for: state) != nil)
    }

    @Test func advanceYearWithLargerSyntheticStateKeepsHistoryBounded() async throws {
        var state = GameState()
        state.startupState = .active
        state.player.traits = [.lucky, .disciplined, .charismatic]
        state.history = (0..<260).map { index in
            HistoryEntry(age: 20, title: "Old \(index)", text: "History \(index)")
        }
        state.relationships.friends = (0..<18).map { index in
            Relationship(name: "Friend \(index)", type: .friend, bond: 50 + (index % 20), yearsKnown: index)
        }
        state.relationships.romanticPartner = Relationship(name: "Partner 0", type: .romantic, bond: 59, yearsKnown: 4, stage: .committed, isCohabiting: true, commitmentAlignment: 70)
        state.family.children = [ChildRecord(name: "Ivy", age: 0, livesAtHome: true, otherParentName: "Partner 0", supportLoad: 62)]
        state.healthProfile.activeConditions = (0..<8).map { index in
            HealthCondition(name: "Condition \(index)", severity: 20 + index)
        }

        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))

        _ = orchestrator.advanceYear(state: &state)

        #expect(state.history.count <= PerformanceBudgets.maxPersistedHistoryItems)
    }

    @Test func debugTimingSnapshotIsPopulatedWithoutChangingOutcome() async throws {
        var stateA = GameState()
        stateA.startupState = .active
        stateA.player.traits = [.lucky]
        stateA.career.roleID = "office_assistant"
        stateA.career.status = .fullTime
        stateA.career.annualIncome = 24_000

        var stateB = stateA

        let orchestratorA = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        let orchestratorB = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))

        _ = orchestratorA.advanceYear(state: &stateA)
        _ = orchestratorB.advanceYear(state: &stateB)

        #expect(stateA.player == stateB.player)
        #expect(stateA.finance == stateB.finance)
        #expect(stateA.career == stateB.career)
        #expect(stateA.education == stateB.education)
        #expect(stateA.healthProfile == stateB.healthProfile)
        #expect(stateA.relationships == stateB.relationships)
        #expect(stateA.housing == stateB.housing)
        #if DEBUG
        #expect(orchestratorA.latestTimingSnapshot != nil)
        #expect(!(orchestratorA.latestTimingSnapshot?.entries.isEmpty ?? true))
        #endif
    }

    @Test func legacyEducationStateDecodesNewSchoolClimateDefaults() async throws {
        let payload = """
        {
          "pathway": "student",
          "schoolStanding": 61,
          "engagement": 58,
          "attendancePressure": 24,
          "activityMomentum": 26,
          "credentials": [],
          "hasScholarship": false
        }
        """

        let decoded = try JSONDecoder().decode(EducationState.self, from: Data(payload.utf8))

        #expect(decoded.schoolBelonging == 48)
        #expect(decoded.reputationRisk == 22)
        #expect(decoded.teacherSupport == 44)
    }

    @Test func educationYearUsesSupportAndSocialFragility() async throws {
        let system = EducationSystem()

        var resilientPlayer = Player()
        resilientPlayer.age = 18
        resilientPlayer.smarts = 67
        var resilientEducation = EducationState()
        resilientEducation.schoolStanding = 58
        resilientEducation.engagement = 66
        resilientEducation.attendancePressure = 60
        resilientEducation.teacherSupport = 78
        resilientEducation.schoolBelonging = 64
        resilientEducation.reputationRisk = 18
        resilientEducation.activityMomentum = 52
        var resilientCareer = CareerState(status: .student, roleID: nil, level: 0, annualIncome: 0, performance: 50, yearsWorked: 0, unemployedYears: 0)
        var resilientMilitary = MilitaryState()
        var resilientRelationships = RelationshipState()
        resilientRelationships.friends = [Relationship(name: "Ari", type: .friend, status: .active, bond: 72, yearsKnown: 2)]

        _ = system.advanceYear(
            player: &resilientPlayer,
            education: &resilientEducation,
            military: &resilientMilitary,
            career: &resilientCareer,
            finance: FinanceState(),
            relationships: resilientRelationships,
            health: HealthState(),
            policySupport: 1
        )

        #expect(resilientEducation.pathway == .graduate)

        var fragilePlayer = Player()
        fragilePlayer.age = 18
        var fragileEducation = EducationState()
        fragileEducation.schoolStanding = 46
        fragileEducation.engagement = 40
        fragileEducation.attendancePressure = 69
        fragileEducation.teacherSupport = 20
        fragileEducation.schoolBelonging = 24
        fragileEducation.reputationRisk = 74
        fragileEducation.activityMomentum = 12
        var fragileCareer = CareerState(status: .student, roleID: nil, level: 0, annualIncome: 0, performance: 50, yearsWorked: 0, unemployedYears: 0)
        var fragileMilitary = MilitaryState()
        var fragileHealth = HealthState()
        fragileHealth.mentalWellness = 38

        _ = system.advanceYear(
            player: &fragilePlayer,
            education: &fragileEducation,
            military: &fragileMilitary,
            career: &fragileCareer,
            finance: FinanceState(),
            relationships: RelationshipState(),
            health: fragileHealth,
            policySupport: 0
        )

        #expect(fragileEducation.pathway == .dropout)
        #expect(fragileCareer.status == .unemployed)
    }

    @Test func teenEducationActionsAffectSchoolClimate() async throws {
        let system = EducationSystem()
        var player = Player()
        var education = EducationState()

        _ = applyEducationAction(.joinActivity, system: system, player: &player, education: &education)
        #expect(education.schoolBelonging > 48)
        #expect(education.reputationRisk < 22)

        education = EducationState()
        _ = applyEducationAction(.skipAndDrift, system: system, player: &player, education: &education)
        #expect(education.attendancePressure > 18)
        #expect(education.schoolBelonging == 48)

        education = EducationState()
        _ = applyEducationAction(.skipClass, system: system, player: &player, education: &education)
        #expect(education.reputationRisk > 22)
        #expect(education.teacherSupport < 44)
    }

    @Test func yearlySummaryCapturesSpilloversAndCheckpoint() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = GameState()
        state.player.age = 15
        state.player.traits = [.anxious]
        state.finance.cashOnHand = -1_500
        state.finance.financialStress = 72
        state.housing.livingArrangement = .couchSurfing
        state.housing.housingStability = 24
        state.healthProfile.mentalWellness = 38
        state.healthProfile.physicalWellness = 40
        state.relationships.friends = [Relationship(name: "Maya", type: .friend, status: .active, bond: 58)]

        _ = orchestrator.advanceYear(state: &state)

        let summary = try #require(orchestrator.latestYearSummary)
        #expect(summary.checkpoint?.title == "Age 16")
        #expect(summary.spillovers.contains(where: { $0.title == "Pressure Spillover" }))
        #expect(summary.spillovers.contains(where: { $0.title == "Housing Drag" || $0.title == "Housing Spillover" }))
    }

    @Test func ageCheckpointsAppearAcrossTeenTransition() async throws {
        let expectations = [(14, "Age 15"), (15, "Age 16"), (16, "Age 17"), (17, "Age 18"), (18, "Early Adult Test"), (20, "Direction Locked In")]

        for (startingAge, checkpointTitle) in expectations {
            let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
            var state = GameState()
            state.player.age = startingAge

            _ = orchestrator.advanceYear(state: &state)

            #expect(orchestrator.latestYearSummary?.checkpoint?.title == checkpointTitle)
        }
    }

    @Test func actionPreviewsUseUpdatedCrossDomainLanguage() async throws {
        let viewModel = GameViewModel(persistence: temporaryPersistence(), defaults: temporaryDefaults())

        #expect(viewModel.actionPreview(for: .protectSleep).contains("+Mental"))
        #expect(viewModel.actionPreview(for: .smallHustle).contains("-Mental"))
        #expect(viewModel.actionPreview(for: .joinActivity).contains("+Friends"))
    }

    @Test func outcomeAggregatorHighlightsTopProblemAndOpportunity() async throws {
        let aggregator = YearlyOutcomeAggregator()
        let before = GameState()
        var after = before
        after.finance.cashOnHand += 8_000
        after.finance.financialStress += 24
        after.healthProfile.mentalWellness -= 12
        after.finance.lastYearBalanceDelta = 4_200

        let summary = aggregator.summarize(before: before, after: after, results: [])

        #expect(summary.topOpportunity?.title == "Cash Position")
        #expect(summary.topProblem?.title == "Financial Stress")
        #expect(summary.momentum != nil)
    }

    @Test func strongTeenPerformanceCanRouteIntoUniversityWithScholarship() async throws {
        let system = EducationSystem()
        var player = Player()
        player.age = 18
        player.smarts = 74
        var education = EducationState()
        education.pathway = .student
        education.schoolStanding = 84
        education.engagement = 72
        education.activityMomentum = 52
        education.teacherSupport = 74
        education.applicationReadiness = 72
        education.disciplineRecord = 82
        education.mentorSupport = 58
        education.hasScholarship = true
        var career = CareerState()
        var military = MilitaryState()

        _ = system.advanceYear(
            player: &player,
            education: &education,
            military: &military,
            career: &career,
            finance: FinanceState(),
            relationships: RelationshipState(),
            health: HealthState(),
            policySupport: 2
        )

        #expect(education.stage == .university)
        #expect(education.pathway == .graduate)
        #expect(education.credentials.contains("Diploma"))
    }

    @Test func weakUniversityYearCanCreateDebtWithoutBreakingCashImmediately() async throws {
        let system = FinanceSystem()
        var finance = FinanceState(cashOnHand: 300)
        var player = Player()
        player.age = 19

        _ = system.advanceYear(
            context: FinanceYearContext(
                age: 19,
                isSchoolAge: false,
                careerStatus: .student,
                grossIncome: 0,
                traits: [],
                educationPathway: .graduate,
                educationStage: .university,
                hasScholarship: false,
                housingCostBand: 18,
                housingArrangement: .familyHome,
                activeConditionCount: 0,
                ownsHome: false,
                hasPrimaryCare: false,
                friendCount: 1,
                partnerCount: 0,
                hasSpouse: false,
                hasCohabitingPartner: false,
                isPregnant: false,
                pregnancyPhase: nil,
                infantCount: 0,
                childCount: 0
            ),
            finance: &finance,
            player: player
        )

        #expect(finance.studentDebt > 0)
        #expect(finance.cashOnHand >= 0)
    }

    @Test func takeExtraShiftsPaysCashButHitsEducationAndRecovery() async throws {
        let system = FinanceSystem()
        var finance = FinanceState(cashOnHand: 250)
        var player = Player()
        player.age = 17

        let result = system.applyAction(.takeExtraShifts, finance: &finance, player: &player)

        #expect(finance.cashOnHand == 670)
        #expect(result.educationEffects?.burnoutRisk == 5)
        #expect(result.educationEffects?.attendancePressure == 4)
        #expect(result.healthEffects?.mental == -2)
    }

    @Test func adultShortfallRollsIntoCreditDebtInsteadOfSoftLocking() async throws {
        let system = FinanceSystem()
        var finance = FinanceState(cashOnHand: 300)
        var player = Player()
        player.age = 28

        _ = system.advanceYear(
            context: FinanceYearContext(
                age: 28,
                isSchoolAge: false,
                careerStatus: .unemployed,
                grossIncome: 0,
                traits: [],
                educationPathway: .dropout,
                educationStage: .inactive,
                hasScholarship: false,
                housingCostBand: 48,
                housingArrangement: .soloRenting,
                activeConditionCount: 0,
                ownsHome: false,
                hasPrimaryCare: false,
                friendCount: 0,
                partnerCount: 0,
                hasSpouse: false,
                hasCohabitingPartner: false,
                isPregnant: false,
                pregnancyPhase: nil,
                infantCount: 0,
                childCount: 0
            ),
            finance: &finance,
            player: player
        )

        #expect(finance.cashOnHand == 0)
        #expect(finance.creditDebt > 0)
        #expect(finance.debtPressureBand != .clear)
    }

    @Test func healthDrivenShortfallCanCreateMedicalDebt() async throws {
        let system = FinanceSystem()
        var finance = FinanceState(cashOnHand: 200)
        var player = Player()
        player.age = 34

        _ = system.advanceYear(
            context: FinanceYearContext(
                age: 34,
                isSchoolAge: false,
                careerStatus: .partTime,
                grossIncome: 8_000,
                traits: [.anxious],
                educationPathway: .graduate,
                educationStage: .inactive,
                hasScholarship: false,
                housingCostBand: 40,
                housingArrangement: .roommates,
                activeConditionCount: 2,
                ownsHome: false,
                hasPrimaryCare: false,
                friendCount: 0,
                partnerCount: 0,
                hasSpouse: false,
                hasCohabitingPartner: false,
                isPregnant: false,
                pregnancyPhase: nil,
                infantCount: 0,
                childCount: 0
            ),
            finance: &finance,
            player: player
        )

        #expect(finance.medicalDebt > 0)
    }

    @Test func minimumPaymentsKeepsDebtAliveAndRaisesPressure() async throws {
        let system = FinanceSystem()
        var finance = FinanceState(cashOnHand: 2_000, studentDebt: 12_000, creditDebt: 8_000, medicalDebt: 2_000, annualGrossIncome: 28_000)
        finance.debtPressureBand = .manageable
        finance.debtDelinquencyRisk = 55
        var player = Player()
        player.age = 29

        _ = system.applyAction(.minimumPayments, finance: &finance, player: &player)
        _ = system.advanceYear(
            context: FinanceYearContext(
                age: 29,
                isSchoolAge: false,
                careerStatus: .fullTime,
                grossIncome: 28_000,
                traits: [],
                educationPathway: .graduate,
                educationStage: .inactive,
                hasScholarship: false,
                housingCostBand: 30,
                housingArrangement: .roommates,
                activeConditionCount: 0,
                ownsHome: false,
                hasPrimaryCare: true,
                friendCount: 0,
                partnerCount: 0,
                hasSpouse: false,
                hasCohabitingPartner: false,
                isPregnant: false,
                pregnancyPhase: nil,
                infantCount: 0,
                childCount: 0
            ),
            finance: &finance,
            player: player
        )

        #expect(finance.totalNonHousingDebt > 10_000)
        #expect(finance.annualDebtPayments > 0)
        #expect(finance.debtPressureBand == .heavy || finance.debtPressureBand == .crushing)
    }

    @Test func bankruptcyResetsEligibleDebtAndWipesInvestments() async throws {
        let system = FinanceSystem()
        var finance = FinanceState(cashOnHand: 1_500, studentDebt: 18_000, creditDebt: 28_000, medicalDebt: 16_000, investedBalance: 18_000, indexFundBalance: 12_000, stockPortfolioBalance: 6_000, costBasis: 18_000, recentDebtReliefYears: 0)
        finance.debtPressureBand = .crushing
        var player = Player()
        player.age = 41

        let result = system.applyAction(.declareBankruptcy, finance: &finance, player: &player)

        #expect(finance.creditDebt == 0)
        #expect(finance.medicalDebt < 16_000)
        #expect(finance.studentDebt == 18_000)
        #expect(finance.investedBalance == 0)
        #expect(finance.recentDebtReliefYears >= 5)
        #expect(result.notes.contains(where: { $0.title == "Bankruptcy" }))
    }

    @Test func heavyDebtBlocksCompoundingEligibility() async throws {
        var finance = FinanceState(cashOnHand: 18_000, studentDebt: 22_000, creditDebt: 16_000, annualGrossIncome: 72_000, financialStress: 28, stabilityStreakYears: 4)
        finance.debtPressureBand = .heavy

        #expect(finance.isBlockedFromCompounding)
        #expect(!finance.isEligibleToCompound())
    }

    @Test func balanceHarnessProducesReadableAggregateReport() async throws {
        let harness = ScriptedBalanceHarness(profile: .playableRealismV1)
        let report = harness.run(runCount: 600)

        #expect(report.runCount == 600)
        #expect(report.humanReadableSummary.contains("Wealth bands"))
        #expect(report.rate { $0.experiencedHeavyDebt } >= 0.20)
        // Lane 1 is the constrained trade-school path: the harness never schedules housing actions there,
        // so it should never register homeownership or the millionaire milestone even when other lanes do.
        let lane1 = report.summaries.filter { $0.seed % 4 == 1 }
        #expect(lane1.count == 150)
        #expect(lane1.allSatisfy { !$0.becameHomeowner })
        #expect(lane1.allSatisfy { !$0.millionaireMilestone })
    }

    @Test func balanceHarnessKeepsMillionairesLateAndRare() async throws {
        let harness = ScriptedBalanceHarness(profile: .playableRealismV1)
        let report = harness.run(runCount: 240)

        #expect(report.summaries.allSatisfy { !$0.millionaireMilestone || $0.finalWealthBand == .millionaire })
        let lane1 = report.summaries.filter { $0.seed % 4 == 1 }
        #expect(lane1.count == 60)
        #expect(lane1.allSatisfy { !$0.millionaireMilestone })
        #expect(report.summaries.filter { ($0.ageOfFirstStableSurplus ?? 999) <= 30 }.count > 60)
    }

    @Test func leanOnMentorBuildsAdultCoverWithoutTouchingFinance() async throws {
        let system = RelationshipSystem()
        var player = Player()
        player.age = 16
        var relationships = RelationshipState()
        var family = FamilyState()

        let result = applyRelationshipAction(.leanOnMentor, system: system, player: &player, relationships: &relationships, family: &family)

        #expect(result.educationEffects?.mentorSupport == 8)
        #expect(result.educationEffects?.applicationReadiness == 4)
        #expect(result.financeEffects == nil)
    }

    @Test func worldSnapshotBuildsDerivedCachesForAllDomains() async throws {
        let builder = WorldSnapshotBuilder()
        var state = GameState()
        state.player.age = 28
        state.finance.cashOnHand = -400
        state.finance.financialStress = 52
        state.relationships.friends = [
            Relationship(name: "Taylor", type: .friend, status: .strained, bond: 30, yearsKnown: 3, stage: .dating, isCohabiting: false, commitmentAlignment: 50)
        ]
        state.family.children = [ChildRecord(name: "Noah", age: 2, livesAtHome: true, otherParentName: "Jamie", supportLoad: 60)]

        let snapshot = builder.build(from: state)

        #expect(snapshot.cache.ageBand == "adult")
        #expect(snapshot.cache.strainedRelationshipCount == 1)
        #expect(snapshot.cache.socialConnectionCount == 1)
        #expect(snapshot.cache.dependentChildCount == 1)
        #expect(snapshot.finance.family.childCount == 1)
        #expect(snapshot.relationships.financialStress == 52)
    }

    @Test func financeSnapshotPathMatchesLegacyContextPath() async throws {
        var state = GameState()
        state.player.age = 24
        state.player.happiness = 62
        state.player.traits = [.disciplined]
        state.career.status = .fullTime
        state.career.annualIncome = 36_000
        state.education.pathway = .graduate
        state.housing.livingArrangement = .soloRenting
        state.housing.housingCostBand = 45

        var legacyFinance = state.finance
        var cachedFinance = state.finance
        let financeSystem = FinanceSystem()
        let world = WorldSnapshotBuilder().build(from: state)

        _ = financeSystem.advanceYear(
            context: FinanceYearContext(
                age: 24,
                isSchoolAge: false,
                careerStatus: .fullTime,
                grossIncome: 36_000,
                traits: [.disciplined],
                educationPathway: .graduate,
                educationStage: .inactive,
                hasScholarship: false,
                housingCostBand: 45,
                housingArrangement: .soloRenting,
                activeConditionCount: 0,
                ownsHome: false,
                hasPrimaryCare: false,
                friendCount: 0,
                partnerCount: 0,
                hasSpouse: false,
                hasCohabitingPartner: false,
                isPregnant: false,
                pregnancyPhase: nil,
                infantCount: 0,
                childCount: 0
            ),
            finance: &legacyFinance,
            player: state.player
        )
        _ = financeSystem.advanceYear(input: world.finance, finance: &cachedFinance)

        #expect(cachedFinance == legacyFinance)
    }

    @Test func artifactStoreInvalidatesWhenSituationChanges() async throws {
        let artifactDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OneLifeArtifacts-\(UUID().uuidString)", isDirectory: true)
        let store = DomainCacheArtifactStore(
            directoryProvider: {
                try FileManager.default.createDirectory(at: artifactDirectory, withIntermediateDirectories: true)
                return artifactDirectory
            }
        )
        var state = GameState()
        state.player.age = 30
        state.finance.financialStress = 48
        let builder = DomainCacheArtifactBuilder()

        let snapshot = WorldSnapshotBuilder().build(from: state)
        let artifact = try #require(builder.buildArtifacts(for: snapshot).first)
        try store.write(artifact)

        let loaded = try store.load(key: artifact.key)
        #expect(loaded != nil)
        #expect(store.isValid(loaded!, for: artifact.key, contentHash: artifact.contentHash))

        var shiftedState = state
        shiftedState.finance.financialStress = 72
        let shiftedSnapshot = WorldSnapshotBuilder().build(from: shiftedState)
        let shiftedArtifact = try #require(builder.buildArtifacts(for: shiftedSnapshot).first)

        #expect(shiftedArtifact.key.situationID != artifact.key.situationID || shiftedArtifact.contentHash != artifact.contentHash)
        #expect(!store.isValid(loaded!, for: shiftedArtifact.key, contentHash: shiftedArtifact.contentHash))
    }

    @Test func systemRegistryReadsActivationFromWorldSnapshot() async throws {
        let registry = SystemRegistry()
        var state = GameState()
        state.player.age = 26
        state.relationships.romanticPartner = Relationship(name: "Morgan", type: .romantic, bond: 70, yearsKnown: 2, stage: .committed, isCohabiting: false, commitmentAlignment: 60)

        let world = WorldSnapshotBuilder().build(from: state)

        #expect(registry.isActive(.family, in: world))
        #expect(registry.isActive(.finance, in: world))
    }

    /// Regression: world autonomy must run in stable eras so `eraYearsRemaining` can decrement (avoids deadlock).
    @Test func systemRegistryActivatesWorldForStableAdultWithoutNarrativeFlags() async throws {
        let registry = SystemRegistry()
        var state = GameState()
        state.player.age = 22
        state.currentEra = .stable
        state.eraYearsRemaining = 10

        let world = WorldSnapshotBuilder().build(from: state)

        #expect(registry.isActive(.world, in: world))
    }

    @Test func systemRegistryDoesNotActivateWorldForMinors() async throws {
        let registry = SystemRegistry()
        var state = GameState()
        state.player.age = 17
        state.currentEra = .stable
        state.eraYearsRemaining = 0

        let world = WorldSnapshotBuilder().build(from: state)

        #expect(registry.isActive(.world, in: world))
    }

    /// Regression: NPC autonomy must not depend on `npc_autonomy_enabled` (that flag was never written).
    @Test func systemRegistryActivatesNPCAutonomyWhenSocialGraphExists() async throws {
        let registry = SystemRegistry()
        var state = GameState()
        state.player.age = 14
        state.relationships.friends = [Relationship(name: "Jordan", type: .friend, bond: 55)]

        let world = WorldSnapshotBuilder().build(from: state)

        #expect(registry.isActive(.npcAutonomy, in: world))
    }

    @Test func npcAutonomyReadsRelationshipCorrelationImpressions() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = GameState()
        state.startupState = .active
        state.player.age = 24
        state.relationships.friends = [
            Relationship(name: "Morgan", type: .friend, status: .active, bond: 62, yearsKnown: 3, personality: .loyal)
        ]

        _ = orchestrator.applyImmediateAction(.keepDistance, domain: .relationships, state: &state)
        _ = orchestrator.applyImmediateAction(.keepDistance, domain: .relationships, state: &state)

        let before = state.relationships.friends[0].hiddenResentment
        _ = NPCAutonomySystem().advanceYear(state: &state)

        let friendID = state.relationships.friends[0].id.uuidString
        #expect(state.correlationLedger.npcImpressions[friendID]?["absent"] ?? 0 >= 2)
        #expect(state.relationships.friends[0].hiddenResentment >= before)
    }

    @Test func worldAutonomyDecrementsEraYearsRemainingOncePerAdultYear() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = GameState()
        state.startupState = .active
        state.player.age = 25
        state.career.status = .fullTime
        state.career.annualIncome = 40_000
        state.finance.cashOnHand = 8_000
        state.education.pathway = .graduate
        state.education.stage = .inactive
        state.currentEra = .stable
        state.eraYearsRemaining = 10

        _ = orchestrator.advanceYear(state: &state)

        #expect(state.eraYearsRemaining == 9)
    }

    @Test func domainActionRegistryShowsStreetCrimeToolkitByDefault() async throws {
        var state = GameState()
        state.player.age = 22
        state.finance.cashOnHand = 400
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: false,
                investmentEmergencyReserve: 2_500
            )
        )
        let quick = registry.availableQuick(for: .crime)
        #expect(quick.contains(.streetCornerHustle))
        #expect(quick.contains(.runScheme))
        #expect(!quick.contains(.ghostProtocol))
        #expect(!quick.contains(.connectCartelNetwork))
    }

    @Test func domainActionRegistryShowsOrganizationCrimeToolkit() async throws {
        var state = GameState()
        state.player.age = 26
        state.crime = CrimeState(status: .active, roleTier: 2, tier: .organization, heat: 40, notoriety: 45, loyalty: 50, yearsActive: 3)
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: false,
                investmentEmergencyReserve: 2_500
            )
        )
        let quick = registry.availableQuick(for: .crime)
        #expect(quick.contains(.holdTerritory))
        #expect(quick.contains(.buildCrew))
        #expect(!quick.contains(.streetCornerHustle))
        #expect(!quick.contains(.delegateOperation))
    }

    @Test func domainActionRegistryShowsEnterpriseCrimeToolkit() async throws {
        var state = GameState()
        state.player.age = 34
        state.crime = CrimeState(status: .active, roleTier: 3, tier: .enterprise, heat: 35, notoriety: 62, loyalty: 58, yearsActive: 8)
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: false,
                investmentEmergencyReserve: 2_500
            )
        )
        let quick = registry.availableQuick(for: .crime)
        #expect(quick.contains(.delegateOperation))
        #expect(quick.contains(.expandDomesticEmpire))
        #expect(!quick.contains(.streetCornerHustle))
    }

    @Test func streetCornerHustleActivatesCrimeAndRaisesHeat() async throws {
        let system = CrimeSystem()
        var player = Player()
        player.age = 21
        var career = CareerState()
        var crime = CrimeState()
        let result = system.applyAction(.streetCornerHustle, player: &player, career: &career, crime: &crime)
        #expect(crime.status == .active)
        #expect(crime.tier == .street)
        #expect(crime.heat > 0)
        #expect((result.financeEffects?.cashDelta ?? 0) != 0)
        #expect(result.notes.contains(where: { $0.tags.contains(.autonomousReaction) }))
    }

    @Test func domainActionRegistryExposesCrimeLaneForDesperateAdult() async throws {
        var state = GameState()
        state.player.age = 22
        state.finance.cashOnHand = 400
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: false,
                investmentEmergencyReserve: 2_500
            )
        )
        #expect(registry.isCrimeLaneActive())
        #expect(!registry.availableCommitted(for: .crime).isEmpty)
        #expect(registry.availableQuick(for: .crime).count >= 2)
    }

    @Test func domainActionRegistryPromotesJobHuntInstantWhenUnemployed() async throws {
        var state = GameState()
        state.player.age = 24
        state.career.status = .unemployed
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: false,
                investmentEmergencyReserve: 2_500
            )
        )
        #expect(registry.resolutionTier(for: .jobHunt, domain: .career) == .instant)
        #expect(registry.availableQuick(for: .career).contains(.jobHunt))
    }

    @Test func domainActionRegistryShowsPathPickersBeforeRegularArchetypeCommit() async throws {
        var state = GameState()
        state.player.age = 26
        state.career.status = .fullTime
        state.career.regularArchetype = nil
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: false,
                investmentEmergencyReserve: 2_500
            )
        )
        let quick = registry.availableQuick(for: .career)
        #expect(quick.contains(.corporateClimb))
        #expect(quick.contains(.tradesMastery))
        #expect(quick.contains(.freelanceHustle))
        #expect(quick.contains(.salesClientOutreach))
        #expect(!quick.contains(.corporateStayLate))
    }

    @Test func domainActionRegistryShowsArchetypeToolkitAfterCommit() async throws {
        var state = GameState()
        state.player.age = 28
        state.career.status = .fullTime
        state.career.regularArchetype = .corporateClimber
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: false,
                investmentEmergencyReserve: 2_500
            )
        )
        let quick = registry.availableQuick(for: .career)
        #expect(quick.contains(.corporateStayLate))
        #expect(quick.contains(.corporatePolitick))
        #expect(quick.contains(.corporateDocumentWin))
        #expect(!quick.contains(.corporateClimb))
        #expect(!quick.contains(.tradesMastery))
    }

    @Test func corporateStayLateInstantActionMovesCareerStats() async throws {
        let system = CareerSystem()
        var player = Player()
        player.age = 27
        var career = CareerState(status: .fullTime, roleID: "operations_coordinator", level: 4, annualIncome: 48_000, performance: 55, yearsWorked: 3, unemployedYears: 0)
        var fame = FameProfile()
        let beforePerf = career.performance
        let result = system.applyAction(.corporateStayLate, player: &player, career: &career, fame: &fame)
        #expect(career.regularArchetype == .corporateClimber)
        #expect(career.performance > beforePerf)
        #expect(career.burnout > 0)
        #expect(result.notes.contains(where: { $0.tags.contains(.autonomousReaction) }))
    }

    @Test func domainActionRegistrySplitsFinanceIntoSections() async throws {
        var state = GameState()
        state.player.age = 28
        state.career.status = .fullTime
        state.career.yearsWorked = 4
        state.career.annualIncome = 52_000
        state.finance.cashOnHand = 12_000
        state.finance.creditDebt = 4_000
        state.finance.lastYearBalanceDelta = 1_200
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: true,
                investmentEmergencyReserve: 2_500
            )
        )
        let sections = registry.financeActionSections()
        #expect(sections.contains(where: { $0.id == "cash" }))
        #expect(sections.contains(where: { $0.id == "debt" }))
    }

    @Test func domainActionRegistryFamilyPhaseAddsParentingChoices() async throws {
        var state = GameState()
        state.player.age = 30
        state.relationships.romanticPartner = Relationship(name: "Alex", type: .romantic, bond: 72, yearsKnown: 4, stage: .married, isCohabiting: true, commitmentAlignment: 70)
        state.family.children = [ChildRecord(name: "Riley", otherParentName: "Alex")]
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: false,
                investmentEmergencyReserve: 2_500
            )
        )
        #expect(registry.familyPhaseIsActive())
        #expect(registry.familyPhaseCommittedChoices().contains(.strengthenBond))
    }

    @Test func layLowIsCrimeOnlyAndEducationUsesSkipAndDrift() async throws {
        #expect(ActionChoiceID.layLow.domain == .crime)
        #expect(ActionChoiceID.skipAndDrift.domain == .education)
    }

    @Test func familyActionsMutatePregnancyIntentAndChildBond() async throws {
        var state = GameState()
        state.player.age = 31
        state.family.children = [
            ChildRecord(name: "Riley", age: 8, livesAtHome: true, otherParentName: "Alex", bondWithPlayer: 50)
        ]
        let system = FamilySystem()

        _ = system.applyAction(.tryForBaby, state: &state)
        #expect(state.family.pregnancyIntent == .trying)

        _ = system.applyAction(.familyMeal, state: &state)
        #expect(state.family.children[0].bondWithPlayer > 50)
    }

    @Test func luxuryYearTargetsOnlyTeenAndYoungAdultChildren() async throws {
        var state = GameState()
        state.finance.cashOnHand = 50_000_000
        let youngChild = ChildRecord(name: "A", age: 8, otherParentName: "Alex", bondWithPlayer: 60)
        let teenChild = ChildRecord(name: "B", age: 16, otherParentName: "Alex", bondWithPlayer: 60)
        state.family.children = [youngChild, teenChild]

        let result = LuxurySystem().advanceYear(state: state)
        #expect(result.financeEffects?.cashDelta == -175_000)
        #expect(result.familyEffects?.childBondDeltaByID?[youngChild.id] == nil)
        #expect(result.familyEffects?.childBondDeltaByID?[teenChild.id] == -3)
    }

    @Test func typedStockResolutionAddsToExistingInvestmentDelta() async throws {
        var finance = FinanceState()
        finance.lastYearInvestmentDelta = 400
        finance.portfolio.stocks = [
            StockHolding(tickerOrSector: "INDEX", sharesOrValue: 10_000, entryBasis: 10_000, volatilityFactor: 0)
        ]
        var economy = EconomyState()
        economy.broadMarketMultiplier = 1.10

        _ = StockMarketSystem().resolveYearlyPerformance(
            finance: &finance,
            economy: economy,
            player: Player(),
            financeMomentum: 0
        )

        #expect(finance.portfolio.stocks[0].totalValue == 11_000)
        #expect(finance.lastYearInvestmentDelta == 1_400)
    }

    @Test func economyActivationHibernatesUntilAdulthood() async throws {
        var state = GameState()
        state.player.age = 17
        let registry = SystemRegistry()
        #expect(!registry.isActive(.economy, for: state))

        state.player.age = 18
        #expect(registry.isActive(.economy, for: state))
    }

    @Test func domainActionRegistrySuggestsRepairForStrainedFriend() async throws {
        var state = GameState()
        state.player.age = 20
        state.relationships.friends = [
            Relationship(name: "Sam", type: .friend, status: .strained, bond: 40)
        ]
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: false,
                investmentEmergencyReserve: 2_500
            )
        )
        let suggested = registry.suggestedCallbackAction()
        #expect(suggested?.domain == .relationships)
        #expect(suggested?.choiceID == .repairTension)
    }

    @Test func orchestratorPublishesLatestWorldSnapshotAfterAdvanceYear() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = GameState()
        state.player.age = 18
        state.career.status = .fullTime
        state.career.annualIncome = 24_000

        _ = orchestrator.advanceYear(state: &state)

        #expect(orchestrator.latestWorldSnapshot?.state.player.age == state.player.age)
        #expect(orchestrator.latestWorldSnapshot?.finance.finance.annualGrossIncome == state.finance.annualGrossIncome)
    }

    @Test func debugScenarioCoordinatorIsDeterministic() async throws {
        let coordinator = DebugTestingCoordinator()

        for scenarioID in DebugScenarioID.allCases {
            let first = coordinator.payload(for: scenarioID)
            let second = coordinator.payload(for: scenarioID)

            #expect(first == second)
        }
    }

    @Test func debugScenarioSeedsAdultCareerWithFullTimeActions() async throws {
        let payload = DebugTestingCoordinator().payload(for: .adultCareerFlow)

        #expect(payload.state.startupState == .active)
        #expect(payload.state.player.age == 24)
        #expect(payload.state.career.status == .fullTime)
        #expect(payload.state.career.roleID == "operations_coordinator")
        #expect(payload.state.pendingActions.contains(where: { $0.domain == .career && $0.choiceID == .workHard }))
        #expect(payload.event == nil)
        #expect(payload.yearSummary == nil)
    }

    @Test func debugScenarioSeedsPregnancyAndModalPreviewStates() async throws {
        let coordinator = DebugTestingCoordinator()
        let pregnancyPayload = coordinator.payload(for: .pregnancyYoungFamily)
        let summaryPayload = coordinator.payload(for: .yearSummaryPreview)
        let eventPayload = coordinator.payload(for: .eventPreview)

        #expect(pregnancyPayload.state.family.isPregnant)
        #expect(pregnancyPayload.state.family.childCount == 2)
        #expect(pregnancyPayload.state.relationships.hasPartner)
        #expect(summaryPayload.yearSummary != nil)
        #expect(eventPayload.event?.choices.count == 2)
    }

    @Test func lateGameSummaryAddsNarrativePressureSignals() async throws {
        let aggregator = YearlyOutcomeAggregator()

        var before = GameState()
        before.player.age = 44
        before.assets.ownsHome = true
        before.finance.lastYearBalanceDelta = 1_800
        before.finance.financialStress = 24
        before.relationships.romanticPartner = Relationship(name: "Alex", type: .romantic, bond: 62, yearsKnown: 15, stage: .married, isCohabiting: true, commitmentAlignment: 58)
        before.family.children = [ChildRecord(name: "Jordan", age: 12, livesAtHome: true, otherParentName: "Alex", supportLoad: 55)]
        before.healthProfile.mentalWellness = 57
        before.healthProfile.physicalWellness = 56
        before.healthProfile.habits.stressManagement = 44
        before.career.performance = 64
        before.career.yearsWorked = 14

        var after = before
        after.finance.financialStress = 38
        after.finance.lastYearBalanceDelta = -300
        after.relationships.romanticPartner?.bond = 54
        after.healthProfile.mentalWellness = 51
        after.healthProfile.physicalWellness = 46
        after.healthProfile.habits.stressManagement = 38
        after.healthProfile.activeConditions = [HealthCondition(name: "Chronic strain", severity: 40)]

        let summary = aggregator.summarize(before: before, after: after, results: [])

        #expect(summary.spillovers.contains { $0.title == "Ownership Drag" })
        #expect(summary.spillovers.contains { $0.title == "Family Drift" })
        #expect(summary.spillovers.contains { $0.title == "Deferred Cost" })
        #expect(summary.checkpoint?.title == "Plateau Strain")
    }

    @Test func homeownerOnlyLateEventRequiresOwnedHome() async throws {
        let event = GameEvent(
            id: "home_repair_cascade",
            category: .finance,
            tags: ["money", "housing", "maintenance"],
            title: "The House Wants Something Again",
            text: "A repair lands.",
            minAge: 32,
            maxAge: 90,
            weight: 7,
            cooldownYears: 3,
            requirements: ["assets.ownsHome==true"],
            choices: [
                EventChoice(
                    text: "Fix it",
                    effects: ChoiceEffects(
                        finance: FinanceEffects(cashDelta: -3_200, financialStressDelta: 4),
                        housing: HousingEffects(stabilityDelta: 4)
                    )
                )
            ]
        )
        let engine = EventEngine(events: [event])

        var renter = GameState()
        renter.player.age = 40
        renter.assets.ownsHome = false

        var homeowner = renter
        homeowner.assets.ownsHome = true

        #expect(engine.pickEvent(for: renter) == nil)
        #expect(engine.pickEvent(for: homeowner)?.id == "home_repair_cascade")
    }

    @Test func adultSurplusCanMoveIntoIndexFunds() async throws {
        let system = InvestmentSystem(indexRoll: { _ in 0 }, stockRoll: { _ in 0 })
        var state = GameState()
        state.player.age = 28
        state.career.status = .fullTime
        state.finance.cashOnHand = 14_000
        state.finance.lastYearBalanceDelta = 9_000
        state.finance.stabilityStreakYears = 3
        state.finance.annualGrossIncome = 52_000

        var finance = state.finance
        let result = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).investments,
            plannedAction: .buyIndexFund,
            finance: &finance
        )

        #expect(finance.cashOnHand < 14_000)
        #expect(finance.indexFundBalance > 0)
        #expect(finance.investedBalance == finance.indexFundBalance)
        #expect(finance.stockPortfolioBalance == 0)
        #expect(result.notes.contains(where: { $0.title == "Investing" }))
    }

    @Test func indexFundsCompoundWithoutTurningIntoLiquidCash() async throws {
        let system = InvestmentSystem(indexRoll: { _ in 3 }, stockRoll: { _ in 0 })
        var state = GameState()
        state.player.age = 34
        state.finance.cashOnHand = 7_500
        state.finance.lastYearBalanceDelta = 2_800
        state.finance.stabilityStreakYears = 4
        state.finance.annualGrossIncome = 68_000
        state.finance.indexFundBalance = 10_000
        state.finance.investedBalance = 10_000
        state.finance.costBasis = 10_000

        var firstYear = state.finance
        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).investments,
            plannedAction: .holdPositions,
            finance: &firstYear
        )

        state.finance = firstYear
        var secondYear = state.finance
        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).investments,
            plannedAction: .holdPositions,
            finance: &secondYear
        )

        #expect(firstYear.cashOnHand == 7_500)
        #expect(firstYear.indexFundBalance > 10_000)
        #expect(secondYear.indexFundBalance > firstYear.indexFundBalance)
        #expect(secondYear.cashOnHand == 7_500)
    }

    @Test func stockLossesHitPortfolioAndRaiseStress() async throws {
        let system = InvestmentSystem(indexRoll: { _ in 0 }, stockRoll: { _ in -24 })
        var state = GameState()
        state.player.age = 31
        state.player.traits = [.impulsive]
        state.finance.cashOnHand = 8_000
        state.finance.lastYearBalanceDelta = 2_000
        state.finance.stabilityStreakYears = 5
        state.finance.annualGrossIncome = 74_000
        state.finance.stockPortfolioBalance = 10_000
        state.finance.investedBalance = 10_000
        state.finance.costBasis = 10_000
        state.finance.financialStress = 22

        var finance = state.finance
        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).investments,
            plannedAction: .holdPositions,
            finance: &finance
        )

        #expect(finance.stockPortfolioBalance < 10_000)
        #expect(finance.lastYearInvestmentDelta < 0)
        #expect(finance.financialStress > 22)
    }

    @Test func sellToCoverRaisesCashByLiquidatingHoldings() async throws {
        let system = InvestmentSystem(indexRoll: { _ in 0 }, stockRoll: { _ in 0 })
        var state = GameState()
        state.player.age = 36
        state.finance.cashOnHand = 1_200
        state.finance.lastYearBalanceDelta = -3_500
        state.finance.stabilityStreakYears = 3
        state.finance.annualGrossIncome = 62_000
        state.finance.indexFundBalance = 6_000
        state.finance.stockPortfolioBalance = 4_000
        state.finance.investedBalance = 10_000
        state.finance.costBasis = 10_000

        var finance = state.finance
        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).investments,
            plannedAction: .sellToCover,
            finance: &finance
        )

        #expect(finance.cashOnHand > 1_200)
        #expect(finance.investedBalance < 10_000)
        #expect(finance.lastYearInvestmentDelta != 0)
    }

    @Test func millionaireMilestoneCountsInvestedWealth() async throws {
        let progressSystem = ProgressSystem()
        var state = GameState()
        state.player.age = 41
        state.finance.cashOnHand = 420_000
        state.finance.indexFundBalance = 390_000
        state.finance.stockPortfolioBalance = 260_000
        state.finance.stabilityStreakYears = 5
        state.finance.normalizeInvestmentBalances()

        _ = progressSystem.unlockNewMilestones(for: &state)

        #expect(state.progress.unlockedMilestones.contains(where: { $0.id == .millionaire }))
    }

    @Test func savingForDownPaymentMovesCashIntoHouseFund() async throws {
        let system = HomeOwnershipSystem(yearlyValueRoll: { _ in 0 }, repairRoll: { _ in 0 })
        var state = GameState()
        state.player.age = 29
        state.career.status = .fullTime
        state.career.yearsWorked = 3
        state.career.annualIncome = 52_000
        state.finance.cashOnHand = 18_000
        state.finance.lastYearBalanceDelta = 8_000

        var finance = state.finance
        var assets = state.assets
        var housing = state.housing
        let result = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).assets,
            plannedAction: .saveForDownPayment,
            finance: &finance,
            assets: &assets,
            housing: &housing
        )

        #expect(finance.cashOnHand < 18_000)
        #expect(finance.homeDownPaymentSavings > 0)
        #expect(assets.isSavingForHome)
        #expect(result.notes.contains(where: { $0.title == "House Fund" }))
    }

    @Test func buyingStarterHomeCreatesMortgageAndOwnerOccupiedHousing() async throws {
        let system = HomeOwnershipSystem(yearlyValueRoll: { _ in 0 }, repairRoll: { _ in 0 })
        var state = GameState()
        state.player.age = 32
        state.career.status = .fullTime
        state.career.yearsWorked = 5
        state.career.annualIncome = 64_000
        state.finance.cashOnHand = 28_000
        state.finance.homeDownPaymentSavings = 42_000
        state.finance.lastYearBalanceDelta = 9_500

        var finance = state.finance
        var assets = state.assets
        var housing = state.housing
        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).assets,
            plannedAction: .buyStarterHome,
            finance: &finance,
            assets: &assets,
            housing: &housing
        )

        #expect(assets.ownsHome)
        #expect(assets.primaryResidence != nil)
        #expect(housing.livingArrangement == .ownerOccupied)
        #expect((assets.primaryResidence?.mortgagePrincipal ?? 0) > 0)
        #expect(finance.homeEquity > 0)
        #expect(finance.cashOnHand < 28_000)
    }

    @Test func ownedHomePaysMortgageAndBuildsEquityAcrossYears() async throws {
        let system = HomeOwnershipSystem(yearlyValueRoll: { _ in 1 }, repairRoll: { _ in 0 })
        var state = GameState()
        state.player.age = 36
        state.career.status = .fullTime
        state.career.yearsWorked = 10
        state.career.annualIncome = 78_000
        state.finance.cashOnHand = 40_000
        state.finance.annualNetIncome = 62_000
        state.finance.financialStress = 18
        state.assets.primaryResidence = PrimaryResidenceState(
            homeValue: 210_000,
            mortgagePrincipal: 145_000,
            monthlyMortgageCost: 980,
            mortgageRatePercent: 6,
            remainingMortgageYears: 27,
            equity: 65_000,
            downPaymentPaid: 38_000,
            maintenanceReserve: 2_400
        )
        state.assets.homeownershipTrackActive = true
        state.housing.livingArrangement = .ownerOccupied

        let previousPrincipal = state.assets.primaryResidence?.mortgagePrincipal ?? 0
        let previousEquity = state.assets.primaryResidence?.equity ?? 0
        var finance = state.finance
        var assets = state.assets
        var housing = state.housing
        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).assets,
            plannedAction: .buildMaintenanceReserve,
            finance: &finance,
            assets: &assets,
            housing: &housing
        )

        #expect((assets.primaryResidence?.mortgagePrincipal ?? previousPrincipal) < previousPrincipal)
        #expect(finance.lastYearMortgagePrincipalPaid > 0)
        #expect(finance.housingDebtBurden > 0)
        #expect((assets.primaryResidence?.equity ?? 0) > previousEquity)
        #expect(housing.livingArrangement == .ownerOccupied)
    }

    @Test func delinquentOwnershipCanEndInForeclosure() async throws {
        let system = HomeOwnershipSystem(yearlyValueRoll: { _ in -2 }, repairRoll: { _ in 100 })
        var state = GameState()
        state.player.age = 39
        state.career.status = .fullTime
        state.career.yearsWorked = 12
        state.career.annualIncome = 58_000
        state.finance.cashOnHand = -13_500
        state.finance.annualNetIncome = 46_000
        state.finance.financialStress = 74
        state.assets.primaryResidence = PrimaryResidenceState(
            homeValue: 185_000,
            mortgagePrincipal: 162_000,
            monthlyMortgageCost: 1_180,
            mortgageRatePercent: 7,
            remainingMortgageYears: 29,
            equity: 23_000,
            downPaymentPaid: 24_000,
            maintenanceReserve: 0,
            status: .delinquent,
            yearsOwned: 2
        )
        state.assets.homeownershipTrackActive = true
        state.housing.livingArrangement = .ownerOccupied

        var finance = state.finance
        var assets = state.assets
        var housing = state.housing
        let result = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).assets,
            plannedAction: .refinanceMortgage,
            finance: &finance,
            assets: &assets,
            housing: &housing
        )

        #expect(!assets.ownsHome)
        #expect(housing.livingArrangement != .ownerOccupied)
        #expect(result.notes.contains(where: { $0.title == "Foreclosure" }))
    }

    @Test func millionaireMilestoneCountsHomeEquity() async throws {
        let progressSystem = ProgressSystem()
        var state = GameState()
        state.player.age = 44
        state.finance.cashOnHand = 210_000
        state.finance.indexFundBalance = 240_000
        state.finance.stockPortfolioBalance = 130_000
        state.finance.compoundingYears = 7
        state.finance.normalizeInvestmentBalances()
        state.finance.homeEquity = 430_000

        _ = progressSystem.unlockNewMilestones(for: &state)

        #expect(state.progress.unlockedMilestones.contains(where: { $0.id == .millionaire }))
    }

    @Test func millionaireMilestoneStaysLockedBeforeThirty() async throws {
        let progressSystem = ProgressSystem()
        var state = GameState()
        state.player.age = 29
        state.finance.cashOnHand = 1_250_000
        state.finance.stabilityStreakYears = 8

        _ = progressSystem.unlockNewMilestones(for: &state)

        #expect(!state.progress.unlockedMilestones.contains(where: { $0.id == .millionaire }))
    }

    @Test func investmentAccessRequiresCompoundingFoundation() async throws {
        let system = InvestmentSystem()
        var state = GameState()
        state.player.age = 27
        state.finance.cashOnHand = 12_000
        state.finance.lastYearBalanceDelta = 4_200
        state.finance.annualGrossIncome = 48_000

        #expect(!state.finance.isEligibleToCompound())

        state.finance.stabilityStreakYears = 2
        #expect(state.finance.isEligibleToCompound())
    }

    @Test func adultFinanceActionsSwitchToInvestmentChoicesOnceStable() async throws {
        let coordinator = temporaryPersistence()
        var state = GameState()
        state.player.age = 27
        state.finance.cashOnHand = 9_500
        state.finance.lastYearBalanceDelta = 2_400
        state.finance.stabilityStreakYears = 2
        state.finance.annualGrossIncome = 42_000
        _ = try coordinator.save(state)

        let viewModel = GameViewModel(persistence: coordinator, defaults: temporaryDefaults())
        let actions = viewModel.actionChoices(for: .finance)

        #expect(actions.contains(.buyIndexFund))
        #expect(actions.contains(.speculateStocks))
        #expect(actions.contains(.buildEmergencyFund))
    }

    @Test func crimeSystemActionClampsLegacyCrimeStateSafely() async throws {
        let system = CrimeSystem()
        var player = Player()
        player.age = 22
        var career = CareerState()
        var crime = CrimeState()

        _ = system.applyAction(.runScheme, player: &player, career: &career, crime: &crime)
        crime.roleTier = 4
        crime.heat = 120
        crime.burnout = 150
        crime.loyalty = 120
        crime.territoryPressure = 120
        crime.lastPayout = 2_400
        crime.clamp()

        #expect(crime.status == .active)
        #expect(crime.roleTier == 3)
        #expect(crime.heat == 100)
        #expect(crime.burnout == 100)
        #expect(crime.loyalty == 100)
        #expect(crime.territoryPressure == 100)
        #expect(crime.lastPayout == 2_400)
    }

    @Test func activeCrimeYearCanForceLayLowOrExitWithoutCrashing() async throws {
        let system = CrimeSystem()
        var player = Player()
        player.age = 24
        player.traits = [.impulsive]

        var career = CareerState(status: .fullTime, roleID: "operations_coordinator", level: 4, annualIncome: 36_000, performance: 70, yearsWorked: 3, unemployedYears: 0)
        var crime = CrimeState(
            status: .active,
            roleTier: 2,
            heat: 72,
            notoriety: 68,
            burnout: 74,
            crewID: "crew-alpha",
            loyalty: 58,
            territoryPressure: 66,
            yearsActive: 2,
            lastPayout: 1_800
        )

        let result = system.advanceYear(
            input: CrimeDomainSnapshot(
                world: WorldCache(
                    age: 24,
                    ageBand: "adult",
                    isSchoolAge: false,
                    strongestRelationshipBond: 62,
                    strainedRelationshipCount: 1,
                    socialConnectionCount: 2,
                    publicReputation: 50,
                    privateReputation: 52,
                    rumorHeat: 14,
                    activeRelationshipTensionCount: 0,
                    futureAlignmentAverage: 50,
                    activeHealthConditionCount: 0,
                    dependentChildCount: 0,
                    infantCount: 0,
                    focusTags: [],
                    criticalStatuses: [],
                    situationID: "adult-risk"
                ),
                player: player,
                career: career,
                crime: crime,
                finance: FinanceState(cashOnHand: 400),
                health: HealthState(),
                relationships: RelationshipState(),
                housing: HousingState(livingArrangement: .roommates, housingCostBand: 36, housingStability: 52, hasRoommate: true)
            ),
            player: &player,
            career: &career,
            crime: &crime
        )

        #expect(!result.notes.isEmpty)
        #expect([CrimeStatus.active, .layingLow, .inactive].contains(crime.status))
        #expect(crime.heat >= 0 && crime.heat <= 100)
        #expect(crime.burnout >= 0 && crime.burnout <= 100)
    }

    @Test func ageUpBuildsBoundedInteractionDeck() async throws {
        let orchestrator = LifeSimulationOrchestrator()
        var state = GameState()
        state.startupState = .active
        state.player.age = 24
        state.career.status = .fullTime
        state.career.roleID = "operations_coordinator"
        state.career.annualIncome = 36_000
        state.career.yearsWorked = 3
        state.pendingActions = [
            PlayerYearAction(domain: .career, choiceID: .workHard),
            PlayerYearAction(domain: .finance, choiceID: .cutSpending)
        ]

        let outcome = orchestrator.advanceYear(state: &state)

        #expect(outcome.cards.count >= 2)
        #expect(outcome.cards.count <= 6)
        #expect(outcome.cards.contains { if case .yearSummary = $0 { return true }; return false })
        #expect(outcome.cards.contains { if case .resolution = $0 { return true }; return false })
    }

    @Test func delayedFinanceChoiceSchedulesFollowUpEventForNextYear() async throws {
        let billEvent = GameEvent(
            id: "unexpected_bill",
            category: .finance,
            tags: ["money"],
            severity: .consequential,
            title: "Unexpected Bill",
            text: "A bill lands this year.",
            minAge: 14,
            maxAge: 90,
            weight: 10,
            cooldownYears: 1,
            requirements: [],
            choices: [
                EventChoice(
                    text: "Delay it",
                    effects: ChoiceEffects(
                        consequence: ConsequenceEffects(
                            setFlags: ["bill_delayed"],
                            clearFlags: [],
                            pressureChanges: ["finance": 18, "housing": 8],
                            scheduleEvents: [
                                ScheduledEventTrigger(
                                    eventID: "collections_notice",
                                    yearsFromNow: 1,
                                    title: "Delayed bill fallout",
                                    detail: "The bill is coming back."
                                )
                            ]
                        )
                    )
                )
            ]
        )
        let collectionsEvent = GameEvent(
            id: "collections_notice",
            category: .finance,
            tags: ["money"],
            severity: .critical,
            title: "Collections Notice",
            text: "The bill came back.",
            minAge: 14,
            maxAge: 90,
            weight: 1,
            cooldownYears: 1,
            requirements: [],
            choices: [
                EventChoice(text: "Deal with it", effects: ChoiceEffects())
            ]
        )
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: [billEvent, collectionsEvent]))
        var state = GameState()
        state.startupState = .active
        state.player.age = 24

        orchestrator.apply(choice: billEvent.choices[0], event: billEvent, state: &state)
        #expect(state.consequences.scheduledEvents.contains { $0.eventID == "collections_notice" && $0.dueAge == 25 })
        #expect(state.consequences.pressureByDomain["finance", default: 0] >= 15)
    }

    @Test func recoveryActionReducesHealthPressureAcrossYearAdvance() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = GameState()
        state.startupState = .active
        state.player.age = 27
        state.career.status = .fullTime
        state.career.roleID = "operations_coordinator"
        state.consequences.pressureByDomain["health"] = 28
        state.pendingActions = [
            PlayerYearAction(domain: .health, choiceID: .rest)
        ]

        _ = orchestrator.advanceYear(state: &state)

        #expect(state.consequences.pressureByDomain["health", default: 0] < 28)
    }

    @Test func legacySaveWithoutConsequenceStateDecodesWithEmptyConsequences() async throws {
        let legacyJSON = """
        {
          "player": { "name": "Jordan", "age": 22, "happiness": 60, "smarts": 55, "looks": 52, "health": 58, "traits": [] },
          "career": { "status": "partTime", "annualIncome": 4200, "performance": 60, "yearsWorked": 1, "unemployedYears": 0 },
          "relationships": { "friends": [], "romanticPartners": [] },
          "healthProfile": {
            "physicalWellness": 60,
            "mentalWellness": 55,
            "habits": { "exercise": 50, "nutrition": 50, "stressManagement": 45 },
            "activeConditions": [],
            "hasPrimaryCare": false
          },
          "assets": { "ownsHome": false },
          "progress": { "unlockedMilestones": [], "legacyScore": 0 },
          "history": [],
          "lastEventYearById": {},
          "isGameOver": false
        }
        """

        let decoded = try JSONDecoder().decode(GameState.self, from: Data(legacyJSON.utf8))

        #expect(decoded.consequences.narrativeFlags.isEmpty)
        #expect(decoded.consequences.pressureByDomain.isEmpty)
        #expect(decoded.consequences.scheduledEvents.isEmpty)
        #expect(decoded.correlationLedger.actionCounts.isEmpty)
        #expect(decoded.correlationLedger.pressureCauses.isEmpty)
    }

    @Test func beginYearChapterCreatesForecastWithoutAdvancingAge() async throws {
        let orchestrator = LifeSimulationOrchestrator()
        var state = GameState()
        state.startupState = .active
        state.player.age = 14
        state.pendingActions = [
            PlayerYearAction(domain: .education, choiceID: .studyConsistently)
        ]

        let outcome = orchestrator.beginYearChapter(state: &state)

        #expect(state.player.age == 14)
        #expect(state.activeYearChapter?.targetAge == 15)
        #expect(outcome.cards.contains(where: {
            if case .forecast = $0 { return true }
            return false
        }))
    }

    @Test func dueScheduledEventOutranksRandomEventAtChapterStart() async throws {
        let randomEvent = GameEvent(
            id: "random_money_event",
            category: .finance,
            tags: ["money"],
            title: "Random Money Event",
            text: "A random event would have fired.",
            minAge: 14,
            maxAge: 90,
            weight: 12,
            cooldownYears: 1,
            requirements: [],
            choices: [EventChoice(text: "Respond", effects: ChoiceEffects())]
        )
        let callbackEvent = GameEvent(
            id: "collections_notice",
            category: .finance,
            tags: ["money"],
            severity: .critical,
            title: "Collections Notice",
            text: "The delayed bill came back.",
            minAge: 14,
            maxAge: 90,
            weight: 1,
            cooldownYears: 1,
            requirements: [],
            choices: [EventChoice(text: "Deal with it", effects: ChoiceEffects())]
        )
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: [randomEvent, callbackEvent]))
        var state = GameState()
        state.startupState = .active
        state.player.age = 14
        state.consequences.scheduledEvents = [
            ScheduledConsequenceEvent(
                eventID: "collections_notice",
                dueAge: 15,
                title: "Delayed bill fallout",
                detail: "The bill came back sharper.",
                sourceEventID: "unexpected_bill",
                sourceEventTitle: "Unexpected Bill",
                sourceChoiceText: "Delay it and hope it settles down",
                callbackFramingText: "The bill you pushed off is back."
            )
        ]

        let outcome = orchestrator.beginYearChapter(state: &state)
        let eventIDs = outcome.cards.compactMap { card -> String? in
            if case .event(let event) = card {
                return event.id
            }
            return nil
        }

        #expect(eventIDs == ["collections_notice"])
    }

    @Test func forecastUsesScheduledCallbackContext() async throws {
        let callbackEvent = GameEvent(
            id: "collections_notice",
            category: .finance,
            tags: ["money"],
            severity: .critical,
            title: "Collections Notice",
            text: "The delayed bill came back.",
            minAge: 14,
            maxAge: 90,
            weight: 1,
            cooldownYears: 1,
            requirements: [],
            choices: [EventChoice(text: "Deal with it", effects: ChoiceEffects())]
        )
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: [callbackEvent]))
        var state = GameState()
        state.startupState = .active
        state.player.age = 14
        state.consequences.scheduledEvents = [
            ScheduledConsequenceEvent(
                eventID: "collections_notice",
                dueAge: 15,
                title: "Delayed bill fallout",
                detail: "The bill came back sharper.",
                sourceEventID: "unexpected_bill",
                sourceEventTitle: "Unexpected Bill",
                sourceChoiceText: "Delay it and hope it settles down",
                callbackFramingText: "The bill you pushed off is back."
            )
        ]

        let outcome = orchestrator.beginYearChapter(state: &state)
        let forecast = outcome.cards.compactMap { card -> YearForecastCard? in
            if case .forecast(let forecast) = card {
                return forecast
            }
            return nil
        }.first

        #expect(forecast?.anticipationTitle == "Delayed bill fallout")
        #expect(forecast?.anticipationDetail == "The bill you pushed off is back.")
    }

    @Test func resolvingYearChapterAdvancesAgeOnceAndClearsAfterCloseout() async throws {
        let event = GameEvent(
            id: "chapter_test_event",
            category: .education,
            tags: ["school"],
            title: "Teacher Callout",
            text: "A teacher notices you.",
            minAge: 14,
            maxAge: 90,
            weight: 10,
            cooldownYears: 1,
            requirements: [],
            choices: [EventChoice(text: "Take it seriously", effects: ChoiceEffects(education: EducationEffects(schoolStanding: 3)))]
        )
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: [event]))
        var state = GameState()
        state.startupState = .active
        state.player.age = 14
        state.pendingActions = [PlayerYearAction(domain: .education, choiceID: .studyConsistently)]

        let beginOutcome = orchestrator.beginYearChapter(state: &state)
        #expect(state.player.age == 14)
        let selectedChoice = beginOutcome.cards.compactMap { card -> EventChoice? in
            if case .event(let event) = card {
                return event.choices.first
            }
            return nil
        }.first
        #expect(selectedChoice != nil)

        let resolveOutcome = orchestrator.resolveYearChapter(choice: selectedChoice!, state: &state)

        #expect(state.player.age == 15)
        #expect(state.activeYearChapter != nil)
        #expect(!resolveOutcome.cards.isEmpty)

        var remainingCards = orchestrator.resumeActiveYearChapterCards(for: state)
        while !remainingCards.isEmpty {
            remainingCards.removeFirst()
            orchestrator.syncActiveYearChapterProgress(state: &state, nextCard: remainingCards.first)
        }

        #expect(state.activeYearChapter == nil)
    }

    @Test func legacySaveWithoutChapterFieldsDecodesSafely() async throws {
        let legacyJSON = """
        {
          "player": { "name": "Jordan", "age": 22, "happiness": 60, "smarts": 55, "looks": 52, "health": 58, "traits": [] },
          "career": { "status": "partTime", "annualIncome": 4200, "performance": 60, "yearsWorked": 1, "unemployedYears": 0 },
          "relationships": { "friends": [], "romanticPartners": [] },
          "healthProfile": {
            "physicalWellness": 60,
            "mentalWellness": 55,
            "habits": { "exercise": 50, "nutrition": 50, "stressManagement": 45 },
            "activeConditions": [],
            "hasPrimaryCare": false
          },
          "assets": { "ownsHome": false },
          "progress": { "unlockedMilestones": [], "legacyScore": 0 },
          "history": [],
          "lastEventYearById": {},
          "isGameOver": false
        }
        """

        let decoded = try JSONDecoder().decode(GameState.self, from: Data(legacyJSON.utf8))

        #expect(decoded.activeYearChapter == nil)
        #expect(decoded.relationships.ambientContacts.isEmpty)
    }

    @Test func beginYearChapterBuildsStakesAndStrongerFocusForecast() async throws {
        let orchestrator = LifeSimulationOrchestrator()
        var focusedState = GameState()
        focusedState.startupState = .active
        focusedState.player.age = 17
        focusedState.education.schoolStanding = 71
        focusedState.education.teacherSupport = 62
        focusedState.finance.financialStress = 36
        focusedState.pendingActions = [PlayerYearAction(domain: .education, choiceID: .studyConsistently)]

        let focusedOutcome = orchestrator.beginYearChapter(state: &focusedState)
        let focusedForecast = focusedOutcome.cards.compactMap { card -> YearForecastCard? in
            if case .forecast(let forecast) = card { return forecast }
            return nil
        }.first

        #expect(focusedState.activeYearChapter?.stakes != nil)
        #expect(focusedState.activeYearChapter?.stakes?.focus.title == ActionChoiceCatalog.definition(for: .studyConsistently).title)
        #expect(focusedForecast?.focusTitle == ActionChoiceCatalog.definition(for: .studyConsistently).title)
        #expect(focusedForecast?.focusDetail.contains("pressure read") == true)

        var reactiveState = GameState()
        reactiveState.startupState = .active
        reactiveState.player.age = 17
        reactiveState.finance.financialStress = 36

        let reactiveOutcome = orchestrator.beginYearChapter(state: &reactiveState)
        let reactiveForecast = reactiveOutcome.cards.compactMap { card -> YearForecastCard? in
            if case .forecast(let forecast) = card { return forecast }
            return nil
        }.first

        #expect(reactiveState.activeYearChapter?.stakes?.focus.title == "No Clear Pattern")
        #expect(reactiveForecast?.focusTitle == "No Clear Pattern")
        #expect(reactiveForecast?.focusDetail.contains("reading pressure more than intent") == true)
    }

    @Test func forecastIncludesAmbientVoiceWhenContactsPresent() async throws {
        let orchestrator = LifeSimulationOrchestrator()
        var state = GameState()
        state.startupState = .active
        state.player.age = 19
        state.relationships.ambientContacts = [
            AmbientContact(
                id: "friend-1",
                name: "Maya",
                role: .friend,
                bond: 82,
                reliability: 70,
                cadence: .regular
            )
        ]

        let outcome = orchestrator.beginYearChapter(state: &state)
        let forecast = outcome.cards.compactMap { card -> YearForecastCard? in
            if case .forecast(let forecast) = card { return forecast }
            return nil
        }.first

        #expect(forecast?.voiceName != nil)
        #expect(!(forecast?.voiceLine?.isEmpty ?? true))
    }

    @Test func yearlySummaryCarriesFocusTradeoffAndNextYearPressure() async throws {
        let aggregator = YearlyOutcomeAggregator()
        var before = GameState()
        before.player.age = 24
        before.finance.cashOnHand = 8_000
        before.finance.financialStress = 18
        before.healthProfile.mentalWellness = 62

        var after = before
        after.player.age = 25
        after.finance.cashOnHand = 11_500
        after.finance.financialStress = 35
        after.healthProfile.mentalWellness = 51
        after.consequences.adjustPressure(domain: "health", delta: 28)

        let result = DomainYearResult(
            notes: [
                DomainNote(
                    title: "Pressure Spillover",
                    text: "The extra work bought cash, but recovery started trailing behind the pace.",
                    tags: [.finance, .health]
                )
            ],
            spilloverSignals: [
                SpilloverSignal(
                    title: "Recovery Loss",
                    detail: "The extra work bought cash, but recovery started trailing behind the pace.",
                    sourceDomain: .finance,
                    impactedDomain: .health,
                    tone: .warning,
                    impactScore: 8
                )
            ]
        )

        let summary = aggregator.summarize(
            before: before,
            after: after,
            results: [result],
            plannedActions: [PlayerYearAction(domain: .finance, choiceID: .takeExtraShifts)]
        )

        #expect(summary.focusOutcome != nil)
        #expect(summary.mainTradeoff != nil)
        #expect(summary.nextYearPressure != nil)
        #expect(summary.mainTradeoff?.detail.contains("lingering cost") == true)
        #expect(summary.nextYearPressure?.detail.contains("carrying forward") == true)
    }

    @Test func takeOvertimeCreatesMoneyHealthAndRelationshipTradeoff() async throws {
        let system = CareerSystem()
        var player = Player()
        player.age = 29
        var career = CareerState(
            status: .fullTime,
            profile: .stableAdmin,
            roleID: "operations_coordinator",
            level: 4,
            annualIncome: 36_000,
            performance: 61,
            yearsWorked: 4
        )
        var fame = FameProfile()

        let result = system.applyAction(.takeOvertime, player: &player, career: &career, fame: &fame)

        #expect(career.burnout >= 28)
        #expect(career.schedulePressure >= 31)
        #expect(career.hustleYears == 1)
        #expect((result.financeEffects?.cashDelta ?? 0) > 0)
        #expect((result.healthEffects?.mental ?? 0) < 0)
        #expect((result.relationshipEffects?.partnerChange ?? 0) < 0)
    }

    @Test func repeatedProtectEnergyBuildsCaretakerIdentity() async throws {
        let system = CareerSystem()
        var player = Player()
        player.age = 31
        var career = CareerState(
            status: .fullTime,
            profile: .serviceFrontline,
            roleID: "guest_services_supervisor",
            level: 4,
            annualIncome: 33_000,
            performance: 63,
            yearsWorked: 5,
            burnout: 54,
            schedulePressure: 58,
            relationshipSpillover: 52
        )
        var fame = FameProfile()

        _ = system.applyAction(.protectYourEnergy, player: &player, career: &career, fame: &fame)
        _ = system.applyAction(.protectYourEnergy, player: &player, career: &career, fame: &fame)

        #expect(career.workIdentity == .caretaker)
        #expect(career.burnout < 54)
        #expect(career.relationshipSpillover < 52)
        #expect(career.activeOpportunityDoor != .internalPromotionTrack)
    }

    @Test func careerProfilesDivergeUnderSameAdultYear() async throws {
        let system = CareerSystem()
        var adminPlayer = Player()
        adminPlayer.age = 30
        adminPlayer.happiness = 58
        adminPlayer.smarts = 58
        adminPlayer.health = 60
        var laborPlayer = adminPlayer
        var education = EducationState()
        education.pathway = .graduate
        education.stage = .inactive
        var health = HealthState()
        health.physicalWellness = 62
        health.mentalWellness = 58

        var adminCareer = CareerState(
            status: .fullTime,
            profile: .stableAdmin,
            roleID: "operations_coordinator",
            level: 4,
            annualIncome: 36_000,
            performance: 64,
            yearsWorked: 4,
            burnout: 24,
            schedulePressure: 28,
            relationshipSpillover: 20
        )
        var laborCareer = CareerState(
            status: .fullTime,
            profile: .physicalLabor,
            roleID: "site_operator",
            level: 4,
            annualIncome: 38_000,
            performance: 64,
            yearsWorked: 4,
            burnout: 24,
            schedulePressure: 28,
            relationshipSpillover: 20
        )

        _ = system.advanceYear(player: &adminPlayer, career: &adminCareer, education: education, health: health, relationships: RelationshipState())
        _ = system.advanceYear(player: &laborPlayer, career: &laborCareer, education: education, health: health, relationships: RelationshipState())

        #expect(laborCareer.burnout > adminCareer.burnout)
        #expect(laborCareer.scheduleControl < adminCareer.scheduleControl)
        #expect(laborCareer.annualIncome != adminCareer.annualIncome)
        #expect(laborCareer.profile == .physicalLabor)
        #expect(adminCareer.profile == .stableAdmin)
    }

    @Test func climberIdentityGeneratesPromotionDoor() async throws {
        let system = CareerSystem()
        var player = Player()
        player.age = 32
        player.happiness = 60
        player.smarts = 64
        var education = EducationState()
        education.pathway = .graduate
        education.stage = .inactive
        var health = HealthState()
        health.physicalWellness = 60
        health.mentalWellness = 58

        var career = CareerState(
            status: .fullTime,
            profile: .stableAdmin,
            roleID: "operations_coordinator",
            level: 4,
            annualIncome: 36_000,
            performance: 90,
            yearsWorked: 5,
            burnout: 32,
            schedulePressure: 36,
            relationshipSpillover: 24,
            jobSecurity: 66,
            managerFriction: 46,
            scheduleControl: 54,
            ambitionYears: 3,
            protectiveYears: 0,
            hustleYears: 1,
            driftYears: 0
        )

        _ = system.advanceYear(player: &player, career: &career, education: education, health: health, relationships: RelationshipState())
        if career.activeOpportunityDoor == nil, career.level == 4 {
            _ = system.advanceYear(player: &player, career: &career, education: education, health: health, relationships: RelationshipState())
        }

        #expect(career.workIdentity == .climber)
        #expect(career.activeOpportunityDoor == .internalPromotionTrack || career.level > 4)
    }

    @Test func retrainingRequiresDoorBeforePivot() async throws {
        let system = CareerSystem()
        var player = Player()
        player.age = 28
        player.happiness = 55
        player.smarts = 57
        var career = CareerState(
            status: .fullTime,
            profile: .serviceFrontline,
            roleID: "guest_services_supervisor",
            level: 4,
            annualIncome: 33_000,
            performance: 62,
            yearsWorked: 4,
            burnout: 30,
            schedulePressure: 42,
            relationshipSpillover: 28
        )
        var fame = FameProfile()

        _ = system.applyAction(.retrain, player: &player, career: &career, fame: &fame)
        _ = system.applyAction(.retrain, player: &player, career: &career, fame: &fame)

        #expect(career.profile == .serviceFrontline)
        #expect(career.retrainingProgress == 2)
        #expect(career.activeOpportunityDoor == nil)

        _ = system.applyAction(.retrain, player: &player, career: &career, fame: &fame)

        #expect(career.retrainingProgress == 3)
        #expect(career.activeOpportunityDoor == .credentialPivot)
        #expect(career.retrainingTargetProfile != nil)
        #expect(career.profile == .serviceFrontline)
    }

    @Test func dismissingFinalCardReturnsPlayerToOriginTabAndOffersDetailReturn() async throws {
        let vm = makeViewModel(.yearSummaryPreview, modal: .yearSummary)

        vm.selectedTab = .assets
        vm.openDetail(.financeCashflow)

        #expect(vm.presentedCard != nil)

        await clearPresentedCards(vm)

        #expect(vm.presentedCard == nil)
        #expect(vm.selectedTab == .assets)
        #expect(vm.returnPrompt?.destination == .financeCashflow)
    }

    @Test func yearSummaryBuildsMoneyInsightWithCauses() async throws {
        let vm = makeViewModel(.yearSummaryPreview, modal: .yearSummary)

        let insight = vm.changeInsights[.money]

        #expect(insight != nil)
        #expect(!(insight?.causes.isEmpty ?? true))
    }

    @Test func feedbackSettingsPersistAcrossViewModelReload() async throws {
        let suiteName = "OneLifeTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Couldn't create isolated user defaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let first = GameViewModel(
            persistence: temporaryPersistence(),
            defaults: defaults,
            debugConfiguration: DebugTestingConfiguration(scenarioID: nil, modal: .none)
        )
        first.hapticsSetting = .reduced
        first.animationSetting = .off
        first.colorEmphasisSetting = .muted

        let second = GameViewModel(
            persistence: temporaryPersistence(),
            defaults: defaults,
            debugConfiguration: DebugTestingConfiguration(scenarioID: nil, modal: .none)
        )

        #expect(second.hapticsSetting == .reduced)
        #expect(second.animationSetting == .off)
        #expect(second.colorEmphasisSetting == .muted)
    }

    @Test func adultCareerDebugScenarioAdvanceYearProducesStableSummaryEnvelope() async throws {
        let payload = DebugTestingCoordinator().payload(for: .adultCareerFlow)
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = payload.state

        let outcome = orchestrator.advanceYear(state: &state)

        guard let summary = outcome.summary else {
            Issue.record("Expected a yearly summary for the adult career debug scenario.")
            return
        }

        #expect(state.player.age == 25)
        #expect(summary.age == 25)
        #expect(!summary.headlines.isEmpty)
        #expect(summary.momentum != nil)
        #expect(outcome.cards.contains(where: {
            if case .yearSummary = $0 { return true }
            return false
        }))
        #expect(state.pendingActions.isEmpty)
    }

    @Test func teenEducationScenarioKeepsReactionSummaryAndResolutionOrdering() async throws {
        let event = GameEvent(
            id: "chapter_order_event",
            category: .education,
            tags: ["school"],
            title: "Teacher Callout",
            text: "A teacher notices you.",
            minAge: 14,
            maxAge: 90,
            weight: 10,
            cooldownYears: 1,
            requirements: [],
            choices: [EventChoice(text: "Take it seriously", effects: ChoiceEffects(education: EducationEffects(schoolStanding: 3)))]
        )
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: [event]))
        var state = DebugTestingCoordinator().payload(for: .teenEducationPressure).state

        let beginOutcome = orchestrator.beginYearChapter(state: &state)
        let beginKinds = beginOutcome.cards.map(cardKind)
        #expect(beginKinds == ["forecast", "event"])

        guard let choice = beginOutcome.cards.compactMap({ card -> EventChoice? in
            if case .event(let event) = card {
                return event.choices.first
            }
            return nil
        }).first else {
            Issue.record("Expected the fixed education event to appear in the chapter.")
            return
        }

        let resolveOutcome = orchestrator.resolveYearChapter(choice: choice, state: &state)
        let resolvedKinds = resolveOutcome.cards.map(cardKind)

        guard let summaryIndex = resolvedKinds.firstIndex(of: "yearSummary") else {
            Issue.record("Expected a year summary after resolving the chapter.")
            return
        }

        let reactionIndex = try #require(resolvedKinds.firstIndex(of: "reaction"))
        #expect(reactionIndex < summaryIndex)
        if let consequenceIndex = resolvedKinds.firstIndex(of: "consequence") {
            #expect(summaryIndex < consequenceIndex)
        }
        if let resolutionIndex = resolvedKinds.firstIndex(of: "resolution") {
            #expect(summaryIndex < resolutionIndex)
        }
    }

    @Test func housingDeficitDebugScenarioSurfacesProblemAndFollowThroughCards() async throws {
        let payload = DebugTestingCoordinator().payload(for: .housingDeficitFlow)
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = payload.state

        let outcome = orchestrator.advanceYear(state: &state)

        guard let summary = outcome.summary else {
            Issue.record("Expected a yearly summary for the housing deficit debug scenario.")
            return
        }

        #expect(summary.topProblem != nil)
        #expect(summary.nextYearPressure != nil)
        #expect(outcome.cards.contains(where: {
            if case .resolution = $0 { return true }
            return false
        }))
    }

    @Test func eventEngineLookupReturnsInjectedEventByIdentifier() async throws {
        let target = GameEvent(
            id: "lookup_target",
            category: .general,
            tags: ["routine"],
            title: "Lookup Target",
            text: "This event exists for lookup.",
            minAge: 14,
            maxAge: 90,
            weight: 1,
            cooldownYears: 0,
            requirements: [],
            choices: [EventChoice(text: "Okay", effects: ChoiceEffects())]
        )
        let engine = EventEngine(events: [target])

        #expect(engine.event(withID: "lookup_target")?.title == "Lookup Target")
        #expect(engine.event(withID: "missing_event") == nil)
    }

    @Test func bundledEventPackIncludesAdultPressureEvents() async throws {
        let url = sampleEventsJSONURL()
        let data = try Data(contentsOf: url)
        let pack = try JSONDecoder().decode(EventPack.self, from: data)
        let ids = Set(pack.events.map(\.id))

        #expect(ids.contains("adult_unemployment_spiral"))
        #expect(ids.contains("shared_budget_resentment"))
        #expect(ids.contains("recovery_costs_work_capacity"))
    }

    @Test func eventEngineCanSurfaceAdultUnemploymentPressureBeat() async throws {
        let adultEvent = GameEvent(
            id: "adult_unemployment_spiral",
            category: .career,
            tags: ["career", "money", "health"],
            severity: .consequential,
            title: "The Unemployment Story Starts Getting Inside You",
            text: "A hard year is turning into a harder identity.",
            minAge: 20,
            maxAge: 40,
            weight: 10,
            cooldownYears: 1,
            requirements: [
                "career.status==unemployed",
                "finance.financialStress>=40"
            ],
            choices: [EventChoice(text: "Keep pushing", effects: ChoiceEffects())]
        )
        let engine = EventEngine(events: [adultEvent])
        var state = GameState()
        state.player.age = 24
        state.career.status = .unemployed
        state.finance.financialStress = 52

        let picked = engine.pickEvent(for: state, preferredTagWeights: ["career": 20])

        #expect(picked?.id == adultEvent.id)
    }

    @Test func systemRegistryHibernatesAgeBoundDomains() async throws {
        let registry = SystemRegistry()
        var child = GameState()
        child.player.age = 4

        #expect(!registry.isActive(.career, for: child))
        #expect(!registry.isActive(.housing, for: child))
        #expect(!registry.isActive(.crime, for: child))
        #expect(registry.isActive(.health, for: child))

        var adult = GameState()
        adult.player.age = 24
        adult.finance.cashOnHand = 14_000
        adult.finance.lastYearBalanceDelta = 2_000

        #expect(registry.isActive(.career, for: adult))
        #expect(registry.isActive(.housing, for: adult))
        #expect(registry.isActive(.investments, for: adult))
    }

    @Test func legacySaveWithoutLegalStateDecodesInactiveLegalDomain() throws {
        let encoded = try JSONEncoder().encode(GameState())
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "legal")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(GameState.self, from: legacyData)

        #expect(decoded.legal.stage == .inactive)
        #expect(decoded.legal.convictions.isEmpty)
    }

    @Test func legalExposureOpensInvestigationAndOffersBoundedActions() {
        let system = LegalSystem()
        var legal = LegalState()
        legal.pendingExposures = [
            LegalExposure(source: "test", offense: .organizedCrime, severity: .moderate, evidence: 64)
        ]
        var player = Player()
        player.age = 25

        let result = system.advanceYear(player: player, legal: &legal, wasInCustodyAtYearStart: false, seed: 11)
        var state = GameState()
        state.player = player
        state.legal = legal
        let actions = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: false,
                isStudentLifeExperience: false,
                canAccessInvesting: true,
                investmentEmergencyReserve: 2_000
            )
        ).availableCommitted(for: .legal)

        #expect(legal.stage == .investigation)
        #expect(result.legalCaseSummary != nil)
        #expect(actions == [.retainCounsel, .cooperateWithInvestigation, .refuseInterview])
    }

    @Test func seededLegalResolutionIsDeterministic() {
        let system = LegalSystem()
        var player = Player()
        player.age = 31
        var first = LegalState(
            stage: .awaitingResolution,
            allegedOffenses: [.enterpriseCrime],
            evidenceStrength: 82,
            counselQuality: 35,
            pendingDecision: .fightCharges
        )
        var second = first

        let firstResult = system.advanceYear(player: player, legal: &first, wasInCustodyAtYearStart: false, seed: 47)
        let secondResult = system.advanceYear(player: player, legal: &second, wasInCustodyAtYearStart: false, seed: 47)

        #expect(first == second)
        #expect(firstResult.legalCaseSummary == secondResult.legalCaseSummary)
    }

    @Test func pleaAlwaysProducesConvictionWithinContextualSentenceBand() {
        let system = LegalSystem()
        var player = Player()
        player.age = 29
        var legal = LegalState(
            stage: .awaitingResolution,
            jurisdiction: .civilian,
            caseSeverity: .serious,
            allegedOffenses: [.enterpriseCrime],
            evidenceStrength: 55,
            counselQuality: 45,
            pendingDecision: .negotiatePlea
        )

        _ = system.advanceYear(player: player, legal: &legal, wasInCustodyAtYearStart: false, seed: 99)

        #expect(legal.convictions.count == 1)
        #expect((1...8).contains(legal.convictions[0].sentenceYears))
        #expect(legal.lastDisposition == .pleaAgreement || legal.lastDisposition == .probation)
    }

    @Test func everyLegalStageRoundTripsThroughGameStatePersistence() throws {
        for stage in LegalCaseStage.allCases {
            var state = GameState()
            state.legal.stage = stage
            state.legal.caseSeverity = .serious
            state.legal.evidenceStrength = 72
            state.legal.recordPressure = 54
            state.legal.convictions = [
                LegalConviction(id: "round-trip", age: 26, offense: .organizedCrime, severity: .serious, jurisdiction: .civilian, sentenceYears: 4, fine: 12_000)
            ]

            let decoded = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))

            #expect(decoded.legal == state.legal)
        }
    }

    @Test func custodyInstantDeckContainsExpectedActions() {
        var state = GameState()
        state.player.age = 30
        state.legal.stage = .custody
        state.legal.sentenceYears = 6
        state.legal.timeServed = 3
        state.legal.paroleEligibleAfter = 3
        state.legal.custodyProfile.facility = .statePrison
        state.legal.custodyProfile.experienceTier = .organization
        state.legal.custodyProfile.discretionaryActionsRemaining = 4
        state.legal.custodyProfile.lifetimeFamilyContactsMax = 3

        let registry = DomainActionRegistry(context: DomainActionContext(
            state: state,
            isTeenExperience: false,
            isStudentLifeExperience: false,
            canAccessInvesting: false,
            investmentEmergencyReserve: 0
        ))

        let deck = registry.availableCommitted(for: .legal)
        #expect(!deck.isEmpty)
        #expect(deck.contains(.keepHeadDown))
        #expect(deck.contains(.studyProgram))
        #expect(deck.contains(.requestParoleHearing))
        #expect(deck.contains(.alignWithFaction))
        #expect(!deck.contains(.delegateFromInside))
    }

    @Test func streetTierDeckFocusesOnSurvivalNotOrganizationActions() {
        var state = GameState()
        state.player.age = 22
        state.legal.stage = .custody
        state.legal.sentenceYears = 3
        state.legal.custodyProfile.experienceTier = .street
        state.legal.custodyProfile.discretionaryActionsRemaining = 4
        state.legal.custodyProfile.lifetimeFamilyContactsMax = 2

        let registry = DomainActionRegistry(context: DomainActionContext(
            state: state,
            isTeenExperience: false,
            isStudentLifeExperience: false,
            canAccessInvesting: false,
            investmentEmergencyReserve: 0
        ))
        let deck = registry.availableCommitted(for: .legal)
        #expect(deck.contains(.standYourGround))
        #expect(!deck.contains(.alignWithFaction))
    }

    @Test func discretionaryBudgetDecrementsOnStudyProgramButNotKeepHeadDown() {
        let system = LegalSystem()
        var legal = LegalState(stage: .custody, sentenceYears: 5, timeServed: 1, paroleEligibleAfter: 3)
        legal.custodyProfile.discretionaryActionsRemaining = 2
        legal.custodyProfile.lifetimeFamilyContactsMax = 3
        legal.custodyProfile.experienceTier = .street
        var finance = FinanceState()
        var fame = FameProfile()

        _ = system.applyAction(.keepHeadDown, legal: &legal, finance: &finance, fame: &fame)
        #expect(legal.custodyProfile.discretionaryActionsRemaining == 2)

        _ = system.applyAction(.studyProgram, legal: &legal, finance: &finance, fame: &fame)
        #expect(legal.custodyProfile.discretionaryActionsRemaining == 1)
    }

    @Test func enterpriseProxyActionsAppearForFederalEnterpriseBid() {
        var state = GameState()
        state.player.age = 40
        state.legal.stage = .custody
        state.legal.convictions = [
            LegalConviction(age: 38, offense: .enterpriseCrime, severity: .aggravated, jurisdiction: .civilian, sentenceYears: 10, fine: 30_000)
        ]
        state.legal.custodyProfile = CustodyProfile(
            facility: .federalPen,
            experienceTier: .enterprise,
            discretionaryActionsRemaining: 5,
            lifetimeFamilyContactsMax: 4,
            outsideEmpireSnapshot: OutsideEmpireSnapshot(loyalty: 60, networkStrength: 55, cleanMoneyRatio: 40, heat: 35)
        )
        state.fame.notoriety = 62

        let registry = DomainActionRegistry(context: DomainActionContext(
            state: state,
            isTeenExperience: false,
            isStudentLifeExperience: false,
            canAccessInvesting: false,
            investmentEmergencyReserve: 0
        ))
        let deck = registry.availableCommitted(for: .legal)
        #expect(deck.contains(.delegateFromInside))
        #expect(deck.contains(.callLieutenant))
    }

    @Test func custodyFamilySpilloverDrainsPartnerBond() {
        var relationships = RelationshipState()
        relationships.romanticPartners = [
            Relationship(name: "Sam", type: .romantic, status: .active, bond: 55, yearsKnown: 4, stage: .dating, isCohabiting: true, commitmentAlignment: 10)
        ]
        var family = FamilyState()
        family.children = [
            ChildRecord(name: "Lee", age: 12, livesAtHome: true, otherParentName: "Sam", supportLoad: 50, bondWithPlayer: 60)
        ]
        var legal = LegalState(stage: .custody, sentenceYears: 6, timeServed: 3, paroleEligibleAfter: 3)
        legal.custodyProfile.facility = .federalPen

        let result = CustodyFamilySpilloverSystem().advanceYear(
            legal: legal,
            relationships: &relationships,
            family: &family,
            resilience: .resilient
        )
        #expect(relationships.romanticPartners[0].bond < 55)
        #expect(family.children[0].bondWithPlayer < 60)
        #expect(!result.notes.isEmpty || relationships.romanticPartners[0].bond < 55)
    }

    @Test func preTrialLegalDeckUnchangedWhenNotInCustody() {
        var state = GameState()
        state.player.age = 28
        state.legal.stage = .charged
        state.legal.bailAmount = 5_000

        let registry = DomainActionRegistry(context: DomainActionContext(
            state: state,
            isTeenExperience: false,
            isStudentLifeExperience: false,
            canAccessInvesting: false,
            investmentEmergencyReserve: 0
        ))

        let deck = registry.availableCommitted(for: .legal)
        #expect(deck.contains(.negotiatePlea))
        #expect(deck.contains(.fightCharges))
        #expect(!deck.contains(.keepHeadDown))
    }

    @Test func highConductImprovesParoleHearingOutcomeVersusLowConduct() {
        let system = LegalSystem()
        var highLegal = LegalState(
            stage: .custody,
            sentenceYears: 6,
            timeServed: 3,
            paroleEligibleAfter: 3,
            recordPressure: 40,
            custodyStartedAge: 27
        )
        highLegal.custodyProfile.conductScore = 88
        highLegal.custodyProfile.programProgress = 80
        highLegal.custodyProfile.discretionaryActionsRemaining = 4
        highLegal.lastProcessedAge = nil

        var lowLegal = highLegal
        lowLegal.custodyProfile.conductScore = 22
        lowLegal.custodyProfile.programProgress = 0
        lowLegal.custodyProfile.infractions = 3
        lowLegal.custodyProfile.discretionaryActionsRemaining = 4

        var finance = FinanceState()
        var fame = FameProfile()

        let highResult = system.applyAction(.requestParoleHearing, legal: &highLegal, finance: &finance, fame: &fame)
        let highParole = highLegal.stage == .supervision || highResult.legalCaseSummary?.title == "Parole Granted"

        _ = system.applyAction(.requestParoleHearing, legal: &lowLegal, finance: &finance, fame: &fame)
        let lowParole = lowLegal.stage == .supervision

        #expect(highParole)
        #expect(!lowParole)
    }

    @Test func cooperateWithGuardsRaisesSnitchRiskAndKnownFor() {
        let system = LegalSystem()
        var legal = LegalState(stage: .custody, sentenceYears: 5, timeServed: 1, paroleEligibleAfter: 3)
        legal.custodyProfile.discretionaryActionsRemaining = 4
        var finance = FinanceState()
        var fame = FameProfile()

        _ = system.applyAction(.cooperateWithGuards, legal: &legal, finance: &finance, fame: &fame)

        #expect(legal.custodyProfile.cooperatedWithAuthorities)
        #expect(legal.custodyProfile.snitchRisk >= 15)
        #expect(fame.knownFor.contains("Informant"))
    }

    @Test func custodyProfileRoundTripsThroughGameStatePersistence() throws {
        var state = GameState()
        state.legal.stage = .custody
        state.legal.custodyProfile = CustodyProfile(
            facility: .federalPen,
            experienceTier: .enterprise,
            securityRegime: .maximum,
            conductScore: 71,
            infractions: 2,
            violenceRisk: 44,
            yardReputation: 58,
            faction: .newBlood,
            factionLoyalty: 63,
            protectionDebt: 31,
            snitchRisk: 18,
            cooperatedWithAuthorities: false,
            programProgress: 64,
            goodTimeCredits: 2,
            lockdownYearsRemaining: 1,
            discretionaryActionsRemaining: 3,
            lifetimeFamilyContactsMax: 4,
            totalFamilyCallsMade: 1,
            outsideEmpireSnapshot: OutsideEmpireSnapshot(loyalty: 55, networkStrength: 48, cleanMoneyRatio: 30, heat: 40, betrayalPressure: 12)
        )
        state.legal.reentryYearsRemaining = 3
        state.legal.prisonResidue = PrisonResidue(tags: ["hardened"], yearsRemaining: 4, experienceTier: .enterprise, recordPressureFloor: 24)

        let decoded = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        #expect(decoded.legal.custodyProfile == state.legal.custodyProfile)
        #expect(decoded.legal.reentryYearsRemaining == 3)
        #expect(decoded.legal.prisonResidue == state.legal.prisonResidue)
    }

    @Test func enterpriseProxyTickMutatesOutsideEmpireSnapshot() {
        var profile = CustodyProfile(
            experienceTier: .enterprise,
            outsideEmpireSnapshot: OutsideEmpireSnapshot(loyalty: 50, networkStrength: 60, cleanMoneyRatio: 30, heat: 25, betrayalPressure: 10)
        )
        let result = EnterpriseProxySystem().advanceYear(profile: &profile, enterprise: CriminalEnterpriseState(), playerAge: 35)
        #expect(profile.outsideEmpireSnapshot != nil)
        #expect(profile.outsideEmpireSnapshot!.loyalty <= 50)
        #expect(!result.notes.isEmpty || profile.outsideEmpireSnapshot!.networkStrength <= 60)
    }

    @Test func custodyAdvancesExactlyOncePerAgeAndHibernatesRestrictedSystems() {
        let system = LegalSystem()
        let registry = SystemRegistry()
        var player = Player()
        player.age = 33
        var legal = LegalState(
            stage: .custody,
            convictions: [
                LegalConviction(age: 31, offense: .organizedCrime, severity: .serious, jurisdiction: .civilian, sentenceYears: 5, fine: 12_000)
            ],
            sentenceYears: 5,
            timeServed: 1,
            paroleEligibleAfter: 3,
            recordPressure: 70,
            custodyStartedAge: 31
        )

        _ = system.advanceYear(player: player, legal: &legal, wasInCustodyAtYearStart: true)
        _ = system.advanceYear(player: player, legal: &legal, wasInCustodyAtYearStart: true)
        var state = GameState()
        state.player = player
        state.legal = legal

        #expect(legal.timeServed == 2)
        #expect(!registry.isActive(.career, for: state))
        #expect(!registry.isActive(.crime, for: state))
        #expect(!registry.isActive(.investments, for: state))
        #expect(registry.isActive(.finance, for: state))
        #expect(registry.isActive(.health, for: state))
    }

    @Test func highHeatCrimeOpensLegalCaseDuringYearPipeline() {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = GameState()
        state.startupState = .active
        state.player.age = 24
        state.crime = CrimeState(
            status: .active,
            roleTier: 2,
            heat: 90,
            notoriety: 70,
            burnout: 30,
            loyalty: 45,
            territoryPressure: 55,
            personalRisk: 75,
            betrayalPressure: 50,
            yearsActive: 3,
            lastPayout: 4_000
        )

        let outcome = orchestrator.advanceYear(state: &state)

        #expect(state.legal.stage == .investigation || state.legal.stage == .charged)
        #expect(outcome.cards.contains { if case .legalCase = $0 { return true }; return false })
    }

    @Test func interactionCardCoordinatorPreservesQueueOrder() async throws {
        var coordinator = InteractionCardCoordinator()
        let cards: [InteractionCardPayload] = [
            .consequence(ConsequencePreview(id: "consequence", title: "Pressure Stayed Behind", detail: "A choice kept echoing.", domain: .finance, tone: .warning)),
            .resolution(ResolutionPreview(id: "resolution", title: "Year Resolved", detail: "The year can close.", actionTitle: "Continue")),
            .crisis(CrisisInteraction(id: "crisis", title: "The Floor Gives Out", detail: "This is a hard stop.", choices: [])),
            .pitchDeck(PitchDeckInteraction(id: "pitch", title: "Choose The Venture", detail: "The company needs a shape.", choices: []))
        ]

        #expect(coordinator.load(cards)?.id == "consequence")
        #expect(coordinator.queuedCount == 3)
        #expect(coordinator.advance()?.id == "resolution")
        #expect(coordinator.advance()?.id == "crisis")
        #expect(coordinator.advance()?.id == "pitch")
        #expect(coordinator.advance() == nil)
    }

    @Test func interactionCardPayloadCaseSentinelCoversAllCases() async throws {
        let cards: [InteractionCardPayload] = [
            .forecast(YearForecastCard(id: "forecast", age: 20, title: "Next Year", subtitle: "Pressure is forming.", focusTitle: "Focus", focusDetail: "Stay ready.", pressureLabel: "Pressure", pressureDetail: "Money is tight.", anticipationTitle: "Watch This", anticipationDetail: "The year may bite.", tone: .neutral)),
            .yearSummary(YearlyOutcomeSummary(age: 20)),
            .event(GameEvent(id: "event", category: .general, tags: [], title: "A Choice Arrives", text: "Something happens.", minAge: 0, maxAge: 99, weight: 1, cooldownYears: 0, requirements: [], choices: [])),
            .reaction(YearReactionCard(id: "reaction", kicker: "After", title: "The Choice Lands", detail: "You feel the result.", domain: .progress, tone: .neutral)),
            .consequence(ConsequencePreview(id: "consequence", title: "Pressure Stayed Behind", detail: "A choice kept echoing.", domain: .finance, tone: .warning)),
            .resolution(ResolutionPreview(id: "resolution", title: "Year Resolved", detail: "The year can close.", actionTitle: "Continue")),
            .crisis(CrisisInteraction(id: "crisis", title: "The Floor Gives Out", detail: "This is a hard stop.", choices: [])),
            .pitchDeck(PitchDeckInteraction(id: "pitch", title: "Choose The Venture", detail: "The company needs a shape.", choices: []))
        ]

        #expect(cards.map(cardKind) == ["forecast", "yearSummary", "event", "reaction", "consequence", "resolution", "crisis", "pitchDeck"])
    }

    @Test func eventPackChoicesStayCappedAndGlanceable() async throws {
        let url = sampleEventsJSONURL()
        let data = try Data(contentsOf: url)
        let pack = try JSONDecoder().decode(EventPack.self, from: data)

        #expect(pack.events.allSatisfy { $0.choices.count <= 3 })
        #expect(pack.events.allSatisfy { $0.text.count <= 180 })
    }

    private func cardKind(_ payload: InteractionCardPayload) -> String {
        switch payload {
        case .forecast:
            return "forecast"
        case .yearSummary:
            return "yearSummary"
        case .event:
            return "event"
        case .reaction:
            return "reaction"
        case .combatFight:
            return "combatFight"
        case .legalCase:
            return "legalCase"
        case .consequence:
            return "consequence"
        case .resolution:
            return "resolution"
        case .crisis:
            return "crisis"
        case .pitchDeck:
            return "pitchDeck"
        }
    }
}

private struct PersistenceTestHarness {
    let directory: URL
    let coordinator: PersistenceCoordinator
    let primaryURL: URL
    let backupURL: URL
    let legacyURL: URL

    init() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OneLifeTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        directory = tempDirectory
        coordinator = PersistenceCoordinator(
            directoryProvider: { tempDirectory },
            prefersSynchronousStartupLoad: true
        )
        primaryURL = tempDirectory.appendingPathComponent("OneLife_Save.json")
        backupURL = tempDirectory.appendingPathComponent("OneLife_Save.backup.json")
        legacyURL = tempDirectory.appendingPathComponent("LifeSimBase_Save.json")
    }

    func writeRawState(_ state: GameState, to url: URL) throws {
        let data = try JSONEncoder().encode(state)
        try data.write(to: url, options: [.atomic])
    }

    func readEnvelope() throws -> PersistedGameState {
        let data = try Data(contentsOf: primaryURL)
        return try JSONDecoder().decode(PersistedGameState.self, from: data)
    }
}

private struct ScriptedBalanceHarness {
    let profile: SimulationBalanceProfile
    let worldSnapshotBuilder = WorldSnapshotBuilder()

    func run(runCount: Int) -> BalanceReport {
        let summaries = (0..<runCount).map(runScenario(seed:))
        return BalanceReport(profileName: "playableRealismV1", runCount: runCount, summaries: summaries)
    }

    private func runScenario(seed: Int) -> BalanceRunSummary {
        let lane = seed % 4
        let financeSystem = FinanceSystem(balanceProfile: profile)
        let investmentSystem = InvestmentSystem(
            emergencyReserve: profile.wealth.compoundingEmergencyReserve,
            balanceProfile: profile,
            indexRoll: { range in midpoint(of: range) },
            stockRoll: { range in range.lowerBound + max(1, (range.upperBound - range.lowerBound) / 3) }
        )
        let homeownershipSystem = HomeOwnershipSystem(
            balanceProfile: profile,
            yearlyValueRoll: { range in midpoint(of: range) },
            repairRoll: { range in range.lowerBound }
        )
        let progressSystem = ProgressSystem(balanceProfile: profile)

        var state = GameState()
        state.player.traits = traits(for: lane)
        state.education.pathway = lane == 1 ? .training : .graduate
        state.education.stage = .inactive
        state.finance.currentRegionPolicyID = nil

        var ageOfFirstStableSurplus: Int?
        var experiencedHeavyDebt = false
        var severeHealthDecline = false
        var becameHomeowner = false
        var unemploymentYears = 0

        for age in 18...90 {
            state.player.age = age
            configureLifeStage(for: age, lane: lane, state: &state)

            if let debtAction = recommendedDebtAction(for: state.finance) {
                _ = financeSystem.applyAction(debtAction, finance: &state.finance, player: &state.player)
            }

            let financeResult = financeSystem.advanceYear(
                context: makeFinanceContext(for: age, lane: lane, state: state),
                finance: &state.finance,
                player: state.player
            )
            applyFinanceStressSideEffects(from: financeResult, to: &state)

            let investmentAction = recommendedInvestmentAction(for: state.finance, lane: lane)
            var snapshot = worldSnapshotBuilder.build(from: state)
            _ = investmentSystem.advanceYear(
                input: snapshot.investments,
                plannedAction: investmentAction,
                finance: &state.finance
            )

            let housingAction = recommendedHousingAction(for: state, lane: lane)
            snapshot = worldSnapshotBuilder.build(from: state)
            _ = homeownershipSystem.advanceYear(
                input: snapshot.assets,
                plannedAction: housingAction,
                finance: &state.finance,
                assets: &state.assets,
                housing: &state.housing
            )

            if state.finance.lastYearBalanceDelta >= profile.wealth.adultStableSurplusThreshold, ageOfFirstStableSurplus == nil {
                ageOfFirstStableSurplus = age
            }
            experiencedHeavyDebt = experiencedHeavyDebt || state.finance.debtPressureBand == .heavy || state.finance.debtPressureBand == .crushing
            becameHomeowner = becameHomeowner || state.assets.ownsHome
            severeHealthDecline = severeHealthDecline || state.healthProfile.mentalWellness <= 28 || state.finance.financialStress >= 72
            if state.career.status == .unemployed { unemploymentYears += 1 }
        }

        _ = progressSystem.unlockNewMilestones(for: &state)

        let longTermPartnership = lane == 2 || (lane == 0 && state.finance.totalWealth >= profile.wealth.comfortableBandLowerBound)
        return BalanceRunSummary(
            seed: seed,
            finalWealthBand: profile.wealthBand(for: state.finance.totalWealth),
            ageOfFirstStableSurplus: ageOfFirstStableSurplus,
            experiencedHeavyDebt: experiencedHeavyDebt,
            graduated: state.education.pathway == .graduate,
            unemploymentYears: unemploymentYears,
            becameHomeowner: becameHomeowner,
            achievedLongTermPartnership: longTermPartnership,
            severeHealthDecline: severeHealthDecline,
            millionaireMilestone: state.progress.unlockedMilestones.contains(where: { $0.id == .millionaire })
        )
    }

    private func configureLifeStage(for age: Int, lane: Int, state: inout GameState) {
        if lane == 2 && age >= 28 {
            state.relationships.romanticPartner = Relationship(
                name: "Jordan",
                type: .romantic,
                status: .active,
                bond: 74,
                yearsKnown: max(0, age - 28),
                stage: age >= 34 ? .married : .committed,
                isCohabiting: age >= 31,
                commitmentAlignment: 72,
                personality: .loyal
            )
        } else {
            state.relationships.romanticPartner = nil
        }
        if lane == 2 && age >= 35 {
            state.family.children = [
                ChildRecord(
                    name: "Avery",
                    age: max(0, age - 35),
                    livesAtHome: true,
                    otherParentName: "Jordan",
                    supportLoad: 62
                )
            ]
        } else {
            state.family.children = []
        }
        state.healthProfile.hasPrimaryCare = lane != 1 || age >= 30
        state.healthProfile.mentalWellness = max(22, 62 - max(0, state.finance.financialStress - 30) / 2)
        state.healthProfile.physicalWellness = lane == 1 ? 54 : 62
        state.healthProfile.activeConditions = (lane == 1 && age >= 42) ? [HealthCondition(name: "Chronic Pain", severity: 42)] : []
        state.housing.housingCostBand = lane == 1 ? 24 : 36
        state.housing.livingArrangement = state.assets.ownsHome ? .ownerOccupied : (lane == 1 ? .roommates : .soloRenting)
        state.housing.hasRoommate = !state.assets.ownsHome && lane == 1
        state.housing.housingStability = state.assets.ownsHome ? 80 : (lane == 1 ? 42 : 64)
        state.career.status = careerStatus(for: age, lane: lane)
        state.career.yearsWorked = max(0, age - 22)
        state.career.annualIncome = grossIncome(for: age, lane: lane)
    }

    private func makeFinanceContext(for age: Int, lane: Int, state: GameState) -> FinanceYearContext {
        FinanceYearContext(
            age: age,
            isSchoolAge: false,
            careerStatus: state.career.status,
            careerLevel: careerLevel(for: age, lane: lane),
            grossIncome: state.career.annualIncome,
            traits: state.player.traits,
            educationPathway: state.education.pathway,
            educationStage: age <= 22 && lane != 1 ? .university : (age <= 20 && lane == 1 ? .tradeTraining : .inactive),
            hasScholarship: lane == 0 && age <= 22 && age % 2 == 0,
            housingCostBand: state.housing.housingCostBand,
            housingArrangement: state.housing.livingArrangement,
            activeConditionCount: state.healthProfile.activeConditions.count,
            ownsHome: state.assets.ownsHome,
            hasPrimaryCare: state.healthProfile.hasPrimaryCare,
            friendCount: lane == 2 ? 4 : 2,
            partnerCount: state.relationships.hasPartner ? 1 : 0,
            hasSpouse: state.relationships.hasSpouse,
            hasCohabitingPartner: state.relationships.hasCohabitingPartner,
            isPregnant: false,
            pregnancyPhase: nil,
            infantCount: state.family.infantCount,
            childCount: state.family.childCount
        )
    }

    private func recommendedDebtAction(for finance: FinanceState) -> ActionChoiceID? {
        if finance.canUseDebtReset { return .declareBankruptcy }
        switch finance.debtPressureBand {
        case .crushing:
            return .consolidateDebt
        case .heavy:
            return .minimumPayments
        case .manageable where finance.totalNonHousingDebt > 20_000:
            return .payDownDebt
        default:
            return nil
        }
    }

    private func recommendedInvestmentAction(for finance: FinanceState, lane: Int) -> ActionChoiceID? {
        if finance.isBlockedFromCompounding { return .buildEmergencyFund }
        if lane == 3, finance.stabilityStreakYears >= 4 { return .speculateStocks }
        if finance.isEligibleToCompound(profile: profile) { return .buyIndexFund }
        return .buildEmergencyFund
    }

    private func recommendedHousingAction(for state: GameState, lane: Int) -> ActionChoiceID? {
        guard lane != 1 else { return nil }
        if state.assets.ownsHome { return .buildMaintenanceReserve }
        if state.player.age >= 30 && state.finance.homeDownPaymentSavings >= 18_000 { return .buyStarterHome }
        if state.player.age >= 26 && state.finance.lastYearBalanceDelta > 0 { return .saveForDownPayment }
        return nil
    }

    private func careerStatus(for age: Int, lane: Int) -> CareerStatus {
        if lane == 1 && age >= 26 && age % 8 == 0 { return .unemployed }
        if age <= 22 && lane != 1 { return .student }
        if age <= 20 && lane == 1 { return .student }
        return .fullTime
    }

    private func careerLevel(for age: Int, lane: Int) -> Int {
        switch lane {
        case 0:
            return min(5, max(1, (age - 22) / 8 + 1))
        case 1:
            return min(3, max(1, (age - 20) / 12 + 1))
        case 2:
            return min(5, max(1, (age - 22) / 7 + 1))
        default:
            return min(5, max(1, (age - 22) / 6 + 1))
        }
    }

    private func grossIncome(for age: Int, lane: Int) -> Int {
        switch lane {
        case 0:
            guard age >= 23 else { return 0 }
            return min(138_000, 42_000 + max(0, age - 23) * 2_800)
        case 1:
            guard age >= 21 else { return 0 }
            if age % 8 == 0 { return 0 }
            return min(48_000, 24_000 + max(0, age - 21) * 650)
        case 2:
            guard age >= 23 else { return 0 }
            let base = min(124_000, 48_000 + max(0, age - 23) * 2_400)
            return age >= 31 ? base + 18_000 : base
        default:
            guard age >= 23 else { return 0 }
            return min(180_000, 56_000 + max(0, age - 23) * 3_500)
        }
    }

    private func traits(for lane: Int) -> [PersonalityTrait] {
        switch lane {
        case 0:
            return [.disciplined]
        case 1:
            return [.anxious]
        case 2:
            return [.disciplined, .charismatic]
        default:
            return [.impulsive, .charismatic]
        }
    }

    private func midpoint(of range: ClosedRange<Int>) -> Int {
        range.lowerBound + ((range.upperBound - range.lowerBound) / 2)
    }

}

@Suite(.serialized)
@MainActor
struct CombatCareerTests {
    @Test func legacyCombatSportsDecodePromptsForDiscipline() throws {
        var athlete = AthleteState()
        athlete.sport = .combatSports
        let encoded = try JSONEncoder().encode(athlete)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "combat")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(AthleteState.self, from: legacyData)

        #expect(decoded.sport == .combatSports)
        #expect(decoded.combat.discipline == nil)
        #expect(decoded.combat.stage == .unselected)
    }

    @Test func combatCareerEntryCreatesThreeDisciplineSpecificOffers() {
        let system = CombatCareerSystem()
        var player = Player()
        player.age = 18
        player.health = 80
        var career = CareerState()
        var specialCareer = SpecialCareerState()

        _ = system.applyAction(
            .startBoxingCareer,
            player: &player,
            career: &career,
            specialCareer: &specialCareer,
            finance: FinanceState(),
            dossier: nil
        )

        #expect(specialCareer.track == .athlete)
        #expect(specialCareer.athlete.sport == .combatSports)
        #expect(specialCareer.athlete.combat.discipline == .boxing)
        #expect(specialCareer.athlete.combat.opponentOffers.count == 3)
        #expect(specialCareer.athlete.combat.activeContract.promotionName == "Ironline Boxing")
    }

    @Test func seededCombatFightIsDeterministicAndResolvesOnce() throws {
        let system = CombatCareerSystem()
        var playerA = Player()
        playerA.age = 25
        var playerB = playerA
        var specialA = SpecialCareerState()
        specialA.track = .athlete
        specialA.athlete.sport = .combatSports
        specialA.athlete.combat.discipline = .mma
        specialA.athlete.combat.stage = .rankedContender
        specialA.athlete.combat.skills = CombatSkillRatings(
            power: 50, handSpeed: 50, footwork: 50, defense: 50,
            striking: 76, wrestling: 72, submissions: 68, takedownDefense: 74, conditioning: 79
        )
        specialA.athlete.combat.scheduledOpponent = CombatOpponentOffer(
            id: "seeded-opponent",
            name: "Dante Reed",
            tier: .ranked,
            rating: 72,
            style: "striker",
            purse: 7_500,
            titleOpportunity: false
        )
        specialA.athlete.combat.campFocus = .mmaGrappling
        specialA.athlete.combat.fightStrategy = .mmaWrestle
        var specialB = specialA

        let resultA = system.advanceCombatYear(player: &playerA, specialCareer: &specialA, seed: 41)
        let resultB = system.advanceCombatYear(player: &playerB, specialCareer: &specialB, seed: 41)

        #expect(resultA.combatFightSummary == resultB.combatFightSummary)
        #expect(resultA.combatFightSummary != nil)
        #expect(specialA.athlete.combat.scheduledOpponent == nil)
        #expect(specialA.athlete.combat.wins + specialA.athlete.combat.losses + specialA.athlete.combat.draws == 1)
        #expect(resultA.financeEffects?.cashDelta == resultA.combatFightSummary?.purse)
    }

    @Test func unsignedCombatYearDevelopsWithoutFabricatingFight() {
        let system = CombatCareerSystem()
        var player = Player()
        player.age = 24
        var specialCareer = SpecialCareerState()
        specialCareer.track = .athlete
        specialCareer.athlete.sport = .combatSports
        specialCareer.athlete.combat.discipline = .boxing
        specialCareer.athlete.combat.ranking = 20
        specialCareer.athlete.combat.careerWear = 20
        let conditioningBefore = specialCareer.athlete.combat.skills.conditioning

        let result = system.advanceCombatYear(player: &player, specialCareer: &specialCareer, seed: 9)

        #expect(result.combatFightSummary == nil)
        #expect(specialCareer.athlete.combat.recordLabel == "0-0-0")
        #expect(specialCareer.athlete.combat.ranking == 18)
        #expect(specialCareer.athlete.combat.careerWear == 17)
        #expect(specialCareer.athlete.combat.skills.conditioning == conditioningBefore + 2)
        #expect(result.financeEffects?.cashDelta == -1_200)
    }

    @Test func combatCrossoverPreservesLegacyAndCanOnlyHappenOnce() {
        let system = CombatCareerSystem()
        var player = Player()
        player.age = 29
        var career = CareerState()
        var specialCareer = SpecialCareerState()
        specialCareer.track = .athlete
        specialCareer.fame = 72
        specialCareer.athlete.sport = .combatSports
        specialCareer.athlete.combat.discipline = .boxing
        specialCareer.athlete.combat.stage = .champion
        specialCareer.athlete.combat.isChampion = true
        specialCareer.athlete.combat.ranking = 47
        specialCareer.athlete.combat.careerEarnings = 180_000
        specialCareer.athlete.combat.careerWear = 43
        specialCareer.athlete.combat.skills.power = 80
        let finance = FinanceState()

        _ = system.applyAction(.crossoverCombatDiscipline, player: &player, career: &career, specialCareer: &specialCareer, finance: finance, dossier: nil)
        let afterFirst = specialCareer
        _ = system.applyAction(.crossoverCombatDiscipline, player: &player, career: &career, specialCareer: &specialCareer, finance: finance, dossier: nil)

        #expect(specialCareer.athlete.combat.discipline == .mma)
        #expect(specialCareer.athlete.combat.crossoverUsed)
        #expect(specialCareer.athlete.combat.ranking == 0)
        #expect(!specialCareer.athlete.combat.isChampion)
        #expect(specialCareer.athlete.combat.careerEarnings == 180_000)
        #expect(specialCareer.athlete.combat.careerWear == 43)
        #expect(specialCareer.fame == 72)
        #expect(specialCareer == afterFirst)
    }

    @Test func retiredChampionCanEnterFightEmpireAndStateRoundTrips() throws {
        let system = CombatCareerSystem()
        var player = Player()
        player.age = 39
        var career = CareerState()
        var finance = FinanceState()
        finance.cashOnHand = 100_000
        var specialCareer = SpecialCareerState()
        specialCareer.track = .athlete
        specialCareer.fame = 80
        specialCareer.athlete.sport = .combatSports
        specialCareer.athlete.personalBrand = 85
        specialCareer.athlete.combat.discipline = .boxing
        specialCareer.athlete.combat.stage = .retired
        specialCareer.athlete.combat.wins = 18
        specialCareer.athlete.combat.isChampion = true

        let result = system.applyAction(
            .startFightEmpire,
            player: &player,
            career: &career,
            specialCareer: &specialCareer,
            finance: finance,
            dossier: nil
        )
        let data = try JSONEncoder().encode(specialCareer)
        let decoded = try JSONDecoder().decode(SpecialCareerState.self, from: data)

        #expect(specialCareer.track == .fightEmpire)
        #expect(specialCareer.fightEmpire.originDiscipline == .boxing)
        #expect(result.financeEffects?.cashDelta == -40_000)
        #expect(decoded == specialCareer)
        #expect(decoded.track.isDiamondCareer)
    }
}

private extension ScriptedBalanceHarness {
    private func applyFinanceStressSideEffects(from result: DomainYearResult, to state: inout GameState) {
        if let mental = result.healthEffects?.mental {
            state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + mental).clamped(to: 0...100)
        }
        if let friendChange = result.relationshipEffects?.friendChange, friendChange < 0 {
            state.relationships.publicReputation = max(0, state.relationships.publicReputation + friendChange)
        }
    }
}
