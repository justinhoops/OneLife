# Phase 0 Audit — 2026-07-10

## Archive and deletion approach

The legacy implementation was removed on `codex/phase0-core-simulator`; Git
history is the archive. There is no duplicate `archive-legacy/` source tree.
The initial removal completed as one batch before the revised wave instruction;
the audit below preserves the logical groups for review. The target now compiles
only the replacement core and console.

## Target-owned Swift inventory at audit time

The production inventory contained 100 Swift files (DerivedData excluded):

```text
AssetCatalog.swift; CharacterCreationPolish.swift; CharacterCreationView.swift; CharacterCreationViewModel.swift; ChildhoodGenerationEngine.swift; CohesionNarrative.swift; ConsoleNavigation.swift; ConsoleTabDashboards.swift; ContentView.swift; ContinuityThreadEngine.swift; DebugTestingCoordinator.swift; DomainActionRegistry.swift; DomainCacheArtifacts.swift; DomainEffectApplier.swift; EchoFlavorResolver.swift; EventEngine.swift; FeedbackCoordinator.swift; FrictionlessComponents.swift; GameChromeViews.swift; GameSessionChromeState.swift; GameViewModel+ConsolePanels.swift; GameViewModel+MetaProgression.swift; GameViewModel.swift; InstantReactionCoordinator.swift; InteractionCardCoordinator.swift; LifeConsoleView.swift; LifeGravityCatalog.swift; NameInputView.swift; NarrativeToneResolver.swift; NavigationTapAudit.swift; OneLifeApp.swift; OneLifeBaseApp.swift; Persistence.swift; PillTabBar.swift; PlannerComponentViews.swift; PlannerSheets.swift; PlannerTabViews.swift; PlannerUIModels.swift; RuntimePerformanceMonitor.swift; SilentYearEngine.swift; VisualPolishModifiers.swift; WorldSnapshot.swift.

Models/ActionChoiceCatalog.swift; Models/ActionChoiceEnums.swift; Models/ActionCorrelationSystem.swift; Models/ActionMemoryModels.swift; Models/ActivityDomainState.swift; Models/AssetDomainState.swift; Models/CareerDomainState.swift; Models/ConsequentialLifeModels.swift; Models/ConsoleUIModels.swift; Models/CoreProfileModels.swift; Models/CorrelationModels.swift; Models/DomainEffectModels.swift; Models/EducationModels.swift; Models/EventModels.swift; Models/FamilyDomainState.swift; Models/FeatureManifest.swift; Models/FinanceDomainState.swift; Models/GameState.swift; Models/HealthDomainState.swift; Models/InteractionModels.swift; Models/ModelHelpers.swift; Models/ModelLifecycleEnums.swift; Models/ModelsUI.swift; Models/NarrativeArcModels.swift; Models/ProgressDomainState.swift; Models/RelationshipDomainState.swift; Models/SessionUXState.swift; Models/SimulationMeta.swift; Models/TraitDomainModels.swift; Models/YearFlowModels.swift.

Simulation/LifeSimulationOrchestrator.swift; Simulation/YearlyConsequencePhase.swift; Simulation/YearlyFoundationPhase.swift; Simulation/YearlyStabilityPhase.swift; Simulation/Systems/AssetsBatch3Systems.swift; Simulation/Systems/CombatCareerSystem.swift; Simulation/Systems/ConsequentialLifeSystems.swift; Simulation/Systems/CrimeBatch2Systems.swift; Simulation/Systems/EducationCareerSystems.swift; Simulation/Systems/FameSystem.swift; Simulation/Systems/FinanceInvestmentSystems.swift; Simulation/Systems/LegalSystem.swift; Simulation/Systems/LuxurySystem.swift; Simulation/Systems/NPCAutonomySystem.swift; Simulation/Systems/NarrativeArcSystem.swift; Simulation/Systems/OriginSystem.swift; Simulation/Systems/PolicySystem.swift; Simulation/Systems/ProgressCoreSystems.swift; Simulation/Systems/RecoverySystem.swift; Simulation/Systems/RelationshipBatch1Systems.swift; Simulation/Systems/RelationshipFamilyHealthAssetSystems.swift; Simulation/Systems/SafetyNetSystem.swift; Simulation/Systems/SimulationLifecycleSystems.swift; Simulation/Systems/SpecialCareerCrimeSystems.swift; Simulation/Systems/StaticInstantActionFlavor.swift; Simulation/Systems/StockMarketSystem.swift; Simulation/Systems/StoryletSystem.swift; Simulation/Systems/WorldAutonomySystem.swift.
```

## Previous state and mutation map

The active path was `OneLifeApp → ContentView → GameViewModel → LifeSimulationOrchestrator`. `DomainActionRegistry` supplied action availability, while `EventEngine` and `DomainEffectApplier` formed parallel event/effect paths.

`Character` held creation-only identity, birth year, traits, appearance, background, starting statistics, and starter assets. `GameState` held `Player`, education, career/business/special career, crime/legal, location/military, finance, relationships/family, health, assets/housing, progress/narrative/consequences, activities/mortality, plus roughly two dozen memory, opportunity, social, and persistence slices.

Direct state mutations were split across:

- UI/session: `GameViewModel`, `DebugTestingCoordinator`, planner/view code, creation support, and session UX models.
- Primary simulation: `LifeSimulationOrchestrator`, yearly phase files, and `InstantReactionCoordinator`.
- Effect/event processing: `DomainEffectApplier`, `EventEngine`, and action correlation/memory models.
- Domain systems: education/career, finance/investment, relationships/family/health/assets, consequential life, progress, policy, NPC/world autonomy, recovery/safety net, and special-career/crime systems.

The replacement therefore keeps one `LifeState`, central action/event registries, and `LifeSimulator.execute` / `LifeSimulator.ageUp` as the only world-mutation entry points.

## Replacement simulation files

`LifeState.swift`, `DomainAction.swift`, `DomainActionRegistry.swift`, `LifeEvent.swift`, `LifeEventRegistry.swift`, `SeededRandom.swift`, and `LifeSimulator.swift` define the simulation. `LifePersistence.swift` owns JSON persistence; `LifeConsoleView.swift` is the manual test harness; `ContentView.swift` is the small start shell.
