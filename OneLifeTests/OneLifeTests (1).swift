import Foundation
import Testing
@testable import OneLife

@MainActor
struct OneLifeTests {
    private func temporaryPersistence() -> PersistenceCoordinator {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        return PersistenceCoordinator(
            directoryProvider: {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                return directory
            }
        )
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
    }

    @Test func yearlyFocusReplacesOlderPlanInsteadOfStackingDomains() async throws {
        let persistence = temporaryPersistence()
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        let viewModel = GameViewModel(persistence: persistence, defaults: defaults)

        viewModel.setAction(.studyConsistently, for: .education)
        #expect(viewModel.state.pendingActions.count == 1)
        #expect(viewModel.state.pendingActions.first?.domain == .education)

        viewModel.setAction(.smallHustle, for: .finance)
        #expect(viewModel.state.pendingActions.count == 1)
        #expect(viewModel.state.pendingActions.first?.domain == .finance)
        #expect(viewModel.state.pendingActions.first?.choiceID == .smallHustle)
    }

    @Test func adultMoneyPressureBuildsGraduallyBeforeHardFailure() async throws {
        var finance = FinanceState(cashOnHand: 500)
        finance.financialStress = 12
        let system = FinanceSystem()

        var player = Player()
        player.age = 24

        system.advanceYear(
            context: FinanceYearContext(
                age: 24,
                isSchoolAge: false,
                careerStatus: .partTime,
                grossIncome: 18_000,
                traits: [],
                educationPathway: .graduate,
                educationStage: .inactive,
                hasScholarship: false,
                housingCostBand: 45,
                housingArrangement: .roommates,
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

        #expect(finance.financialStress >= 30)
        #expect(finance.financialStress < 82)
        #expect(finance.cashOnHand < 500)
    }

    @Test func quietRunStaysSurvivableAndAvoidsRunawayWealth() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = orchestrator.previewStart(mode: .template, templateID: .stableHomeAverageMeans)
        _ = orchestrator.activatePreview(state: &state)

        for year in 0..<12 {
            state.pendingActions = [
                PlayerYearAction(
                    domain: year < 4 ? .education : (year < 8 ? .career : .health),
                    choiceID: year < 4 ? .studyConsistently : (year < 8 ? .protectYourEnergy : .rest)
                )
            ]
            _ = orchestrator.advanceYear(state: &state)
            if state.isGameOver {
                break
            }
        }

        #expect(!state.isGameOver)
        #expect(state.player.age >= 26)
        #expect(state.finance.totalWealth < 1_000_000)
        #expect(state.finance.financialStress < 85)
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

        #expect(finance.cashOnHand < 0)
        #expect(finance.financialStress >= 25)
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
        let preview = orchestrator.previewStart(mode: .template, templateID: .financialStrainToughenedEarly)

        #expect((2...5).contains(preview.narrativeArcs.candidates.count))
        #expect(preview.narrativeArcs.primaryArcID != nil)
        #expect(preview.narrativeArcs.secondaryArcID != nil)
        #expect(!preview.narrativeArcs.previewTensionLabels.isEmpty)
    }

    @Test func activatingPreviewAddsChapterPressureHistory() async throws {
        let orchestrator = LifeSimulationOrchestrator(eventEngine: EventEngine(events: []))
        var state = orchestrator.previewStart(mode: .template, templateID: .academicPromise)

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

        let generated = LocalArcSeedGenerator().generateCandidates(context: context)

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
        let preview = OriginSystem().makePreview(mode: .template, templateID: .financialStrainToughenedEarly, narrativeArcSystem: narrativeSystem)

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
        var state = OriginSystem().makePreview(mode: .template, templateID: .academicPromise, narrativeArcSystem: narrativeSystem)
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

        _ = system.applyAction(.chaseSpotlight, player: &player, career: &career, specialCareer: &specialCareer)

        #expect(specialCareer.track == .entertainment)
        #expect(specialCareer.fame > 0)
        #expect(specialCareer.audience > 0)
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

        var breakoutPlayer = Player()
        breakoutPlayer.age = 24
        breakoutPlayer.looks = 75
        breakoutPlayer.happiness = 66
        var breakoutCareer = CareerState()
        var breakoutSpecialCareer = SpecialCareerState(track: .entertainment, tier: 2, fame: 80, audience: 80, burnout: 0, yearsActive: 0, lastPayout: 0)

        let breakoutResult = system.advanceYear(
            player: &breakoutPlayer,
            career: &breakoutCareer,
            specialCareer: &breakoutSpecialCareer,
            health: HealthState(),
            relationships: RelationshipState()
        )

        #expect(breakoutSpecialCareer.lastPayout >= 4_000)
        #expect((breakoutResult.financeEffects?.cashDelta ?? 0) >= 4_000)

        var collapsePlayer = Player()
        collapsePlayer.age = 18
        collapsePlayer.looks = 20
        collapsePlayer.happiness = 20
        var collapseCareer = CareerState()
        var collapseSpecialCareer = SpecialCareerState(track: .entertainment, tier: 1, fame: 0, audience: 0, burnout: 96, yearsActive: 0, lastPayout: 0)

        _ = system.advanceYear(
            player: &collapsePlayer,
            career: &collapseCareer,
            specialCareer: &collapseSpecialCareer,
            health: HealthState(),
            relationships: RelationshipState()
        )

        #expect(collapseSpecialCareer.track == .inactive)
        #expect(collapseSpecialCareer.lastPayout == 0)
    }

    @Test func burnoutReducesEntertainmentOutcomeQuality() async throws {
        let system = SpecialCareerSystem()

        var restedPlayer = Player()
        restedPlayer.age = 24
        restedPlayer.looks = 75
        restedPlayer.happiness = 66
        var restedCareer = CareerState()
        var restedSpecialCareer = SpecialCareerState(track: .entertainment, tier: 2, fame: 80, audience: 80, burnout: 0, yearsActive: 0, lastPayout: 0)

        _ = system.advanceYear(
            player: &restedPlayer,
            career: &restedCareer,
            specialCareer: &restedSpecialCareer,
            health: HealthState(),
            relationships: RelationshipState()
        )

        var burnedOutPlayer = Player()
        burnedOutPlayer.age = 24
        burnedOutPlayer.looks = 75
        burnedOutPlayer.happiness = 66
        var burnedOutCareer = CareerState()
        var burnedOutSpecialCareer = SpecialCareerState(track: .entertainment, tier: 2, fame: 80, audience: 80, burnout: 60, yearsActive: 0, lastPayout: 0)

        _ = system.advanceYear(
            player: &burnedOutPlayer,
            career: &burnedOutCareer,
            specialCareer: &burnedOutSpecialCareer,
            health: HealthState(),
            relationships: RelationshipState()
        )

        #expect(burnedOutSpecialCareer.lastPayout < restedSpecialCareer.lastPayout)
    }

    @Test func highHeatCrimeYearCanTriggerForcedExitAndDownstreamDamage() async throws {
        let system = CrimeSystem()
        var player = Player()
        player.age = 18
        var career = CareerState(status: .fullTime, roleID: "office_assistant", level: 3, annualIncome: 24_000, performance: 62, yearsWorked: 1, unemployedYears: 0)
        var crime = CrimeState(status: .active, roleTier: 2, heat: 80, notoriety: 40, burnout: 10, crewID: "crew", loyalty: 45, territoryPressure: 35, yearsActive: 0, lastPayout: 0)
        let result = system.advanceYear(
            player: &player,
            career: &career,
            crime: &crime,
            finance: FinanceState(cashOnHand: 100),
            health: HealthState(physicalWellness: 60, mentalWellness: 20, habits: LifestyleHabits(), activeConditions: [], hasPrimaryCare: false),
            housing: HousingState(livingArrangement: .roommates, housingCostBand: 25, housingStability: 20, hasRoommate: true)
        )

        #expect(crime.status == .inactive)
        #expect(result.careerEffects?.loseJob == true)
        #expect((result.financeEffects?.cashDelta ?? 0) < 0)
        #expect((result.healthEffects?.mental ?? 0) < 0)
    }

    @Test func millionaireMilestoneReadsFinanceCash() async throws {
        let progressSystem = ProgressSystem()
        var state = GameState()
        state.finance.cashOnHand = 1_100_000

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

        let result = system.applyAction(.joinActivity, player: &player, education: &education)

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

        _ = system.advanceYear(
            player: &player,
            education: &education,
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

    @Test func contentPackBalancesAllPrimaryDomains() async throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("OneLife")
            .appendingPathComponent("SampleEvents.json")
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
        let system = EducationSystem()

        let result = system.advanceYear(
            player: &player,
            education: &education,
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

        _ = system.applyAction(.discussFuture, player: &player, relationships: &relationships, family: &family)

        #expect(relationships.romanticPartner?.stage == .married)
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

        _ = system.applyAction(.discussFuture, player: &player, relationships: &relationships, family: &family)

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
        let viewModel = GameViewModel(persistence: coordinator)
        viewModel.newLife()

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

        #expect(stateA == stateB)
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
        var resilientRelationships = RelationshipState()
        resilientRelationships.friends = [Relationship(name: "Ari", type: .friend, status: .active, bond: 72, yearsKnown: 2)]

        _ = system.advanceYear(
            player: &resilientPlayer,
            education: &resilientEducation,
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
        var fragileHealth = HealthState()
        fragileHealth.mentalWellness = 38

        _ = system.advanceYear(
            player: &fragilePlayer,
            education: &fragileEducation,
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

        _ = system.applyAction(.joinActivity, player: &player, education: &education)
        #expect(education.schoolBelonging > 48)
        #expect(education.reputationRisk < 22)

        education = EducationState()
        _ = system.applyAction(.layLow, player: &player, education: &education)
        #expect(education.attendancePressure < 18)
        #expect(education.schoolBelonging < 48)

        education = EducationState()
        _ = system.applyAction(.skipClass, player: &player, education: &education)
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
        #expect(summary.spillovers.contains(where: { $0.title == "Housing Spillover" }))
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
        let viewModel = GameViewModel(persistence: temporaryPersistence())

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

        _ = system.advanceYear(
            player: &player,
            education: &education,
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

    @Test func leanOnMentorBuildsAdultCoverWithoutTouchingFinance() async throws {
        let system = RelationshipSystem()
        var player = Player()
        player.age = 16
        var relationships = RelationshipState()
        var family = FamilyState()

        let result = system.applyAction(.leanOnMentor, player: &player, relationships: &relationships, family: &family)

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
        #expect(pregnancyPayload.state.family.childCount == 1)
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

        var finance = state.finance
        let result = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).investment,
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
        state.finance.indexFundBalance = 10_000
        state.finance.investedBalance = 10_000
        state.finance.costBasis = 10_000

        var firstYear = state.finance
        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).investment,
            plannedAction: .holdPositions,
            finance: &firstYear
        )

        state.finance = firstYear
        var secondYear = state.finance
        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).investment,
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
        state.finance.stockPortfolioBalance = 10_000
        state.finance.investedBalance = 10_000
        state.finance.costBasis = 10_000
        state.finance.financialStress = 22

        var finance = state.finance
        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).investment,
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
        state.finance.indexFundBalance = 6_000
        state.finance.stockPortfolioBalance = 4_000
        state.finance.investedBalance = 10_000
        state.finance.costBasis = 10_000

        var finance = state.finance
        _ = system.advanceYear(
            input: WorldSnapshotBuilder().build(from: state).investment,
            plannedAction: .sellToCover,
            finance: &finance
        )

        #expect(finance.cashOnHand > 1_200)
        #expect(finance.investedBalance < 10_000)
        #expect(finance.lastYearInvestmentDelta <= 0)
    }

    @Test func millionaireMilestoneCountsInvestedWealth() async throws {
        let progressSystem = ProgressSystem()
        var state = GameState()
        state.finance.cashOnHand = 420_000
        state.finance.indexFundBalance = 390_000
        state.finance.stockPortfolioBalance = 260_000
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
        state.finance.cashOnHand = 210_000
        state.finance.indexFundBalance = 240_000
        state.finance.stockPortfolioBalance = 130_000
        state.finance.normalizeInvestmentBalances()
        state.finance.homeEquity = 430_000

        _ = progressSystem.unlockNewMilestones(for: &state)

        #expect(state.progress.unlockedMilestones.contains(where: { $0.id == .millionaire }))
    }

    @Test func adultFinanceActionsSwitchToInvestmentChoicesOnceStable() async throws {
        let coordinator = temporaryPersistence()
        var state = GameState()
        state.player.age = 27
        state.finance.cashOnHand = 9_500
        state.finance.lastYearBalanceDelta = 2_400
        _ = try coordinator.save(state)

        let viewModel = GameViewModel(persistence: coordinator)
        let actions = viewModel.actionChoices(for: .finance)

        #expect(actions.contains(.buyIndexFund))
        #expect(actions.contains(.speculateStocks))
        #expect(actions.contains(.buildEmergencyFund))
    }

    @Test func crimeSystemApplyEffectClampsLegacyCrimeStateSafely() async throws {
        let system = CrimeSystem()
        var crime = CrimeState()

        system.apply(
            effect: CrimeEffects(
                setStatus: .active,
                roleTier: 4,
                heat: 120,
                notoriety: 90,
                burnout: 150,
                crewID: "legacy-crew",
                loyalty: 120,
                territoryPressure: 120,
                yearsActive: 3,
                lastPayout: 2_400,
                exitCrime: nil
            ),
            crime: &crime
        )

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
        coordinator = PersistenceCoordinator(directoryProvider: { tempDirectory })
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
