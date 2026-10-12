import SwiftUI
import UIKit

/// Privacy: One Life makes no network calls, uses no analytics or tracking identifiers,
/// and keeps life data only in this app's local container.
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var simulator: LifeSimulator?
    @State private var invalidationMessage: String?

    init() {
        let store = LifePersistence()
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") { store.clear() }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestEconomy") {
            var state = LifeState(name: "Avery", seed: 90_033)
            state.character.age = 30
            state.lifeStage = LifeStage.stage(for: 30)
            state.flags.attendsSchool = false
            state.flags.seenInstantHint = true
            state.flags.seenAgeUpHint = true
            state.career.track = .office
            state.career.level = .entry
            state.cash = 5_000
            if ProcessInfo.processInfo.arguments.contains("-uiTestWorkout") {
                state.finance.consumerDebt = 80_000
                state.finance.economy.shortfallYears = 2
            }
            if ProcessInfo.processInfo.arguments.contains("-uiTestConversion") {
                state.saveVersion = 32
                state.cash = 50
                state = (try? EconomyMigration.convert(state)) ?? state
            }
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestPartnerConfrontation") {
            var state = LifeState(name: "Avery", seed: 777)
            state.flags.hasPartner = true
            state.partner = PartnerState(
                name: "Morgan",
                startedAge: 18,
                compatibility: 60,
                bond: 43,
                resentment: 44,
                flags: [.demanding, .cautious]
            )
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestQuietRecap") {
            var state = LifeState(name: "Avery", seed: 7_190)
            state.character.age = 33
            state.lifeStage = .build
            state.flags.attendsSchool = false
            state.flags.seenInstantHint = true
            state.flags.seenAgeUpHint = true
            state.lastYearSummary = YearSummarySystem.compose(
                age: 33,
                headline: "Another Year",
                bullets: [],
                deltas: DeltaSummary(),
                stanceTitle: "Drift",
                shapeTitle: "Balanced",
                focusNote: nil,
                silenceNote: "Life moved without asking for a verdict.",
                wasQuiet: true
            )
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestYearlyDecisionFlow") {
            var state = LifeState(name: "Avery", seed: 7_191)
            state.character.age = 33
            state.lifeStage = .build
            state.flags.attendsSchool = false
            let event = LifeEvent(
                id: "ui-yearly-decision",
                headline: "Work Followed You Home Again",
                detail: "The promotion paid more and took more than it promised.",
                weight: { _ in 0 },
                choices: [
                    EventChoice(
                        id: .accept,
                        title: "Keep carrying it",
                        detail: "Let the pressure remain unnamed.",
                        effects: EffectRange(cash: 10...10, health: -4 ... -4),
                        partnerEffect: PartnerEffect(),
                        narrative: "You kept carrying the work home."
                    )
                ]
            )
            let yearDeltas = DeltaSummary(cash: 20, health: -2)
            state.lastYearSummary = YearSummarySystem.compose(
                age: 33,
                headline: event.headline,
                bullets: [event.headline],
                deltas: yearDeltas,
                stanceTitle: "Push Career",
                shapeTitle: "Driven",
                focusNote: nil,
                silenceNote: nil,
                wasQuiet: false
            )
            state.pendingEvent = PresentedEvent(event, yearDeltas: yearDeltas, kind: .yearly)
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestTwoYearlyChoices") {
            var state = LifeState(name: "Avery", seed: 7_192)
            state.character.age = 33
            state.lifeStage = .build
            state.flags.attendsSchool = false
            state.lastYearSummary = YearSummary(
                bullets: ["A demanding year"], stanceTitle: nil, shapeTitle: nil,
                focusNote: nil, silenceNote: nil, wasQuiet: false, age: 33,
                headline: "A Demanding Year"
            )
            let choice = EventChoice(
                id: .accept, title: "Keep going", detail: "Make the choice.",
                effects: EffectRange(), partnerEffect: PartnerEffect(), narrative: "You kept going."
            )
            state.pendingEvent = PresentedEvent(
                id: "ui-first-yearly", headline: "Work Asked For Another Sacrifice",
                detail: "The pressure needed an answer.", choices: [choice],
                yearDeltas: DeltaSummary(), isPartnerEvent: false, kind: .yearly
            )
            state.queuedYearEvents = [PresentedEvent(
                id: "ui-second-yearly", headline: "A Friend Offered Another Way",
                detail: "The invitation arrived at the right time.", choices: [choice],
                yearDeltas: DeltaSummary(), isPartnerEvent: false, kind: .yearly
            )]
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestForceEnding") {
            var state = LifeState(name: "Avery", seed: 1)
            state.character.age = LifeLimits.maximumAge - 1
            state.lifeStage = .legacy
            state.stats.health = 18
            state.mortalityPressure = .critical
            state.job.tier = .retired
            state.flags.attendsSchool = false
            state.flags.seenInstantHint = true
            state.flags.seenAgeUpHint = true
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestCollegeOffers") {
            var state = LifeState(name: "Avery", seed: 7_180, startingAge: 14)
            state.character.age = 18
            state.lifeStage = .launch
            state.education.academicStanding = 82
            state.education.futureReadiness = 78
            state.education.teacherSupport = 65
            state.education.legacyFlags = [.recommendationEarned]
            let outcome = EducationSystem.resolveYear(state: &state)
            state.pendingEvent = PresentedEvent(EducationSystem.offerEvent(
                id: "ui-college-offers",
                headline: outcome.milestoneHeadline ?? "High School Is Behind You",
                detail: outcome.milestoneDetail ?? "Your record created real options.",
                offers: outcome.graduationOffers
            ))
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestCollegeTransfer") {
            var state = LifeState(name: "Avery", seed: 7_182, startingAge: 14)
            state.character.age = 20
            state.lifeStage = .launch
            state.education.phase = .leftSchool
            state.education.highSchoolDiploma = true
            state.education.credential = true
            state.education.credentialKind = .associateDegree
            state.education.credentialField = .business
            state.education.college = CollegeState(status: .completed, institution: .communityCollege, field: .business, credits: 8, academicStanding: 65, campusBelonging: 55, yearsEnrolled: 2, lastTuitionAge: 20)
            state.flags.attendsSchool = false
            state.pendingEvent = PresentedEvent(EducationSystem.followUpEvent(.communityCompletion, state: state))
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestCollege") {
            var state = LifeState(name: "Avery", seed: 7_183, startingAge: 14)
            state.character.age = 20
            state.lifeStage = .launch
            state.education.phase = .postsecondary
            state.education.highSchoolDiploma = true
            state.education.postSchoolPath = .college
            state.education.college = CollegeState(status: .enrolled, institution: .publicUniversity, field: .appliedTechnical, credits: 5, academicStanding: 62, campusBelonging: 54, yearsEnrolled: 1, lastTuitionAge: 20)
            state.education.launchInfluenceYearsRemaining = 5
            state.flags.attendsSchool = true
            state.flags.seenInstantHint = true
            state.flags.seenAgeUpHint = true
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestEducationRecovery") {
            var state = LifeState(name: "Avery", seed: 7_184)
            state.character.age = 30
            state.lifeStage = .build
            state.flags.attendsSchool = false
            state.education.phase = .leftSchool
            state.education.highSchoolDiploma = false
            state.education.credential = false
            state.education.credentialKind = .none
            state.flags.seenInstantHint = true
            state.flags.seenAgeUpHint = true
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestSchoolLegacy") {
            var state = LifeState(name: "Avery", seed: 7_181, startingAge: 14)
            state.character.age = 24
            state.lifeStage = .launch
            state.flags.attendsSchool = false
            state.education.phase = .leftSchool
            state.education.highSchoolDiploma = true
            state.education.postSchoolPath = .training
            state.education.commitmentYears = [.activity: 3]
            state.education.legacyFlags = [.activityIdentity, .mentorBacked]
            state.education.launchInfluenceYearsRemaining = 1
            state.flags.seenInstantHint = true
            state.flags.seenAgeUpHint = true
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestHighSchoolIdentity") {
            var state = LifeGenerationSystem.customPreview(
                name: "Avery", seed: 7_185, origin: .social, context: .ordinary,
                definingTrait: .outgoing, talent: .publicLeadership
            ).state
            state.character.age = 16
            state.education.commitment = .activity
            state.education.activity = .service
            state.education.activityStage = .committed
            state.education.schoolReputation = 67
            state.npcs[.friend]?.rapport = 14
            state.flags.seenInstantHint = true
            state.flags.seenAgeUpHint = true
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestPostSchool") {
            var state = LifeState(name: "Avery", seed: 2)
            state.character.age = 26
            state.lifeStage = .build
            state.flags.attendsSchool = false
            state.education.credential = true
            state.education.progress = 12
            state.flags.seenInstantHint = true
            state.flags.seenAgeUpHint = true
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestWorldNews") {
            var state = LifeState(name: "Avery", seed: 9_001)
            state.world.profileDisclosed = true
            state.world.conditions.price = .inflationShock
            state.world.conditions.priceYearsRemaining = 1
            let world = WorldSystem.resolveYear(world: &state.world, age: 19)
            state.lastYearSummary = YearSummary(
                bullets: ["Age 19", "Stage Launch"],
                stanceTitle: nil,
                shapeTitle: nil,
                focusNote: nil,
                silenceNote: nil,
                wasQuiet: false,
                worldNews: world.news,
                age: 19,
                headline: world.news?.headline ?? "The World Shifted"
            )
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestPublicHealth") {
            var state = LifeState(name: "Avery", seed: 9_002)
            state.cash = 50_000
            state.world.profileDisclosed = true
            state.world.publicHealth.profileDisclosed = true
            state.world.publicHealth.healthcareCapacity = .constrained
            state.world.publicHealth.diseaseBurden = .high
            state.world.publicHealth.condition = .outbreak
            state.lastYearSummary = YearSummary(
                bullets: ["Age 19", "Stage Launch"],
                stanceTitle: nil,
                shapeTitle: nil,
                focusNote: nil,
                silenceNote: nil,
                wasQuiet: false,
                worldNews: WorldNews(
                    id: "world-health-outbreak",
                    headline: "A Public-Health Outbreak Escalates",
                    detail: "Widespread illness stretches care capacity.",
                    severity: .danger,
                    impactLines: ["Health −2/year", "Care costs rise sharply"]
                ),
                age: 19,
                headline: "A Public-Health Outbreak Escalates"
            )
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestContinuity") {
            var state = LifeState(name: "Avery", seed: 9_004)
            state.character.age = 32
            state.lifeStage = .build
            state.flags.attendsSchool = false
            state.flags.seenInstantHint = true
            state.flags.seenAgeUpHint = true
            LifeThreadSystem.open([
                DomainConsequence(
                    source: .career, target: .finance, kind: .layoff, magnitude: .major,
                    openedAge: 32, yearsRemaining: 3,
                    headline: "The layoff still shapes your choices",
                    detail: "Lost income is narrowing the household."
                )
            ], state: &state)
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestLateLifeDensity") {
            var state = LifeState(name: "Avery", seed: 9_005)
            state.character.age = 72
            state.lifeStage = .legacy
            state.cash = 5_400
            state.stats.health = 38
            state.stats.play = 42
            state.health.physicalWellbeing = 34
            state.health.mentalWellbeing = 49
            state.health.bodyLoad = 28
            state.health.careAccess = .basic
            state.finance.retirementBalance = 48_000
            state.finance.medicalDebt = 3_200
            state.finance.financialStress = 77
            state.family.caregivingLoad = 64
            state.mortalityPressure = .vulnerable
            state.job.tier = .retired
            state.flags.attendsSchool = false
            state.flags.seenInstantHint = true
            state.flags.seenAgeUpHint = true
            LifeThreadSystem.open([
                DomainConsequence(
                    source: .health, target: .family, kind: .illness, magnitude: .major,
                    openedAge: 71, yearsRemaining: 3,
                    headline: "Care needs reshaped the household",
                    detail: "Declining health is asking more of the people closest to you."
                ),
                DomainConsequence(
                    source: .finance, target: .health, kind: .debt, magnitude: .major,
                    openedAge: 70, yearsRemaining: 2,
                    headline: "Medical debt narrowed your options",
                    detail: "Care costs are competing with a limited retirement cushion."
                )
            ], state: &state)
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestAssets") {
            var state = LifeState(name: "Avery", seed: 9_003)
            let expandedAssetFixture = ProcessInfo.processInfo.arguments.contains("-uiTestAssetGuns")
                || ProcessInfo.processInfo.arguments.contains("-uiTestVehicles")
            state.character.age = expandedAssetFixture ? 25 : 20
            state.lifeStage = LifeStage.stage(for: state.character.age)
            state.cash = ProcessInfo.processInfo.arguments.contains("-uiTestVehicles") ? 20_000_000 : 500_000
            state.career.level = .senior
            state.career.track = .office
            state.assets.lastRentalIncome = 0
            state.flags.attendsSchool = false
            state.flags.seenInstantHint = true
            state.flags.seenAgeUpHint = true
            _simulator = State(initialValue: Self.makeSimulator(state: state))
            _invalidationMessage = State(initialValue: nil)
            return
        }
        #endif
        switch store.load() {
        case .loaded(let state):
            _simulator = State(initialValue: Self.makeSimulator(state: state))
        case .freshStart(let message):
            _simulator = State(initialValue: nil)
            _invalidationMessage = State(initialValue: message)
        }
    }

    var body: some View {
        Group {
            if let simulator {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-debugConsole") {
                    LifeConsoleView(
                        simulator: simulator,
                        onNew: { name, seed in
                            newLife(LifeGenerationSystem.customPreview(
                                name: name,
                                seed: seed,
                                origin: .balanced,
                                context: .ordinary,
                                definingTrait: .adaptable,
                                talent: nil
                            ))
                        },
                        onLoad: loadLife,
                        onQuit: { self.simulator = nil }
                    )
                } else {
                    LifeDashboardView(simulator: simulator, onNewLife: {
                        simulator.abandonLife()
                        self.simulator = nil
                    })
                }
                #else
                LifeDashboardView(simulator: simulator, onNewLife: {
                    simulator.abandonLife()
                    self.simulator = nil
                })
                #endif
            } else {
                StartLifeView(
                    message: invalidationMessage,
                    playtestRecommendation: PlaytestEnvironment.isEnabled
                        ? PlaytestEnvironment.cohortAnalysis().nextRecommendation
                        : nil,
                    start: { preview, style in
                        newLife(preview, playtestStyle: style)
                    }
                )
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive { simulator?.saveForLifecycle() }
        }
    }

    private func newLife(_ preview: LifeGenerationPreview, playtestStyle: PlaytestStyle? = nil) {
        simulator?.abandonLife()
        let committed = Self.makeSimulator(state: preview.state, origin: preview.origin)
        if let playtestStyle { committed.setPlaytestStyle(playtestStyle) }
        committed.saveForLifecycle()
        simulator = committed
        invalidationMessage = nil
    }

    private func loadLife() {
        if case .loaded(let state) = LifePersistence().load() {
            simulator = Self.makeSimulator(state: state)
        }
    }

    private static func makeSimulator(state: LifeState, origin: OriginPreset? = nil) -> LifeSimulator {
        LifeSimulator(
            state: state,
            playtestRecorder: PlaytestEnvironment.recorder(),
            playtestOrigin: origin
        )
    }
}

// MARK: - Start life

private struct StartLifeView: View {
    let message: String?
    let playtestRecommendation: PlaytestCohortRecommendation?
    let start: (LifeGenerationPreview, PlaytestStyle?) -> Void
    @State private var mode: CreationMode
    @State private var randomPreview: LifeGenerationPreview?
    @State private var name = ""
    @State private var origin: OriginPreset
    @State private var playtestStyle: PlaytestStyle?
    @State private var context: StartingContext = .ordinary
    @State private var definingTrait: PersonalityFlag = .adaptable
    @State private var talent: SpecialTalent?
    @State private var customSeed = UInt64.random(in: 1...UInt64.max)

    init(
        message: String?,
        playtestRecommendation: PlaytestCohortRecommendation?,
        start: @escaping (LifeGenerationPreview, PlaytestStyle?) -> Void
    ) {
        self.message = message
        self.playtestRecommendation = playtestRecommendation
        self.start = start
        _mode = State(initialValue: playtestRecommendation == nil ? .random : .custom)
        _origin = State(initialValue: playtestRecommendation?.origin ?? .balanced)
        _playtestStyle = State(initialValue: playtestRecommendation?.style)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image("OneLifeIcon")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
                        .accessibilityHidden(true)
                    Text("One Life").font(.largeTitle.bold())
                    Text("Start at 14. Make the choices. Carry the consequences.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 2)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        CreationPromise(symbol: "hand.tap.fill", title: "Choose")
                        CreationPromise(symbol: "calendar.badge.clock", title: "Live")
                        CreationPromise(symbol: "arrow.trianglehead.2.clockwise.rotate.90", title: "Remember")
                    }
                    VStack(spacing: 8) {
                        CreationPromise(symbol: "hand.tap.fill", title: "Choose")
                        CreationPromise(symbol: "calendar.badge.clock", title: "Live")
                        CreationPromise(symbol: "arrow.trianglehead.2.clockwise.rotate.90", title: "Remember")
                    }
                }
                if let message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }
                if let playtestRecommendation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cohort Run Target")
                            .font(.headline)
                        Text(playtestRecommendation.title)
                            .font(.title3.bold())
                            .accessibilityIdentifier("Playtest Cohort Target")
                        Picker("Play style", selection: $playtestStyle) {
                            ForEach(PlaytestStyle.allCases) { style in
                                Text(style.title).tag(Optional(style))
                            }
                        }
                        Text("This target fills the next missing ten-life evidence slot. It affects the report only, never the simulation.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                Picker("Creation mode", selection: $mode) {
                    ForEach(CreationMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                if mode == .random {
                    if let randomPreview {
                        GeneratedLifePreviewCard(preview: randomPreview)
                        Button("Reroll Life", systemImage: "dice") { reroll() }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("Reroll Life")
                    }
                } else {
                    customControls
                    if let preview = customPreview { GeneratedLifePreviewCard(preview: preview) }
                }
            }
            .padding(28)
            .padding(.bottom, 72)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            Button(mode == .random ? "Start This Life" : "Start Custom Life") {
                    if let selectedPreview { start(selectedPreview, playtestStyle) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(selectedPreview == nil)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(.bar)
        }
        .onAppear { if randomPreview == nil { reroll() } }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var customControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Your name", text: $name)
                .accessibilityIdentifier("Your name")
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
            Text("Starting point").font(.headline)
            ForEach(OriginPreset.allCases) { preset in
                Button { origin = preset } label: {
                    HStack(alignment: .top) {
                        Image(systemName: origin == preset ? "checkmark.circle.fill" : "circle")
                        VStack(alignment: .leading) {
                            Text(preset.title)
                            Text(preset.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("Origin \(preset.title)")
            }
            Picker("Starting context", selection: $context) {
                ForEach(StartingContext.allCases) { Text($0.title).tag($0) }
            }
            Text(contextTradeoff).font(.caption).foregroundStyle(.secondary)
            Picker("Defining trait", selection: $definingTrait) {
                ForEach(PersonalityFlag.allCases) { Text($0.title).tag($0) }
            }
            Picker("Special talent", selection: $talent) {
                Text("None").tag(Optional<SpecialTalent>.none)
                ForEach(SpecialTalent.allCases) { Text($0.title).tag(Optional($0)) }
            }
            Text(talent?.detail ?? "No special edge. The life is shaped by context, choices, and luck.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var customPreview: LifeGenerationPreview? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return LifeGenerationSystem.customPreview(
            name: trimmed,
            seed: customSeed,
            origin: origin,
            context: context,
            definingTrait: definingTrait,
            talent: talent
        )
    }

    private var selectedPreview: LifeGenerationPreview? {
        mode == .random ? randomPreview : customPreview
    }

    private func reroll() {
        randomPreview = LifeGenerationSystem.randomPreview(seed: UInt64.random(in: 1...UInt64.max))
    }

    private var contextTradeoff: String {
        switch context {
        case .supported: "More runway · less earned reputation"
        case .ordinary: "No strong advantage · no special protection"
        case .precarious: "Less cash · sharper resourcefulness"
        }
    }

}

private struct CreationPromise: View {
    let symbol: String
    let title: String

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: Capsule())
    }
}

private enum CreationMode: String, CaseIterable, Identifiable {
    case random, custom
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

private struct GeneratedLifePreviewCard: View {
    let preview: LifeGenerationPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(preview.state.character.name).font(.title3.bold())
                    Text("Seed \(preview.seed)").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text(preview.state.personality.talent?.title ?? "No special talent")
                    .font(.caption.bold())
            }
            Text("\(preview.context.title) · \(preview.origin.title)")
                .font(.subheadline)
            PersonalityProfileSummaryView(profile: preview.state.personality)
            Text("Smart \(preview.state.stats.school) · Happy \(preview.state.stats.happy) · Health \(preview.state.stats.health) · Cash $\(preview.state.cash)")
                .font(.caption)
            Text("World: \(preview.state.world.profile.costEnvironment.rawValue) costs · \(preview.state.world.profile.laborStructure.rawValue) labor · \(preview.state.world.profile.safetyNet.rawValue) safety net")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Dashboard (Glance → Act)

private struct LifeDashboardView: View {
    @ObservedObject var simulator: LifeSimulator
    var onNewLife: () -> Void
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.uiTestReduceMotion) private var uiTestReduceMotion
    @State private var domain: Domain = .school
    @State private var sheet: DashboardSheet?
    @State private var moment: DashboardMoment?
    @State private var selectedPerson: PersonReference?
    @State private var lastObservedHistorySequence: UInt64 = 0
    @State private var floatingDeltas: [FloatingDelta] = []
    @State private var previewAction: DomainAction?
    private let domainActionsAnchor = "domain-actions"
    private var reduceMotion: Bool { accessibilityReduceMotion || uiTestReduceMotion }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                    StatIsland(state: simulator.state) { sheet = .health }

                    if simulator.state.momentum.isActive || simulator.state.influenceLedger.current.isEmpty == false {
                        MomentumStrip(momentum: simulator.state.momentum, ledger: simulator.state.influenceLedger)
                    }

                    StageContextStrip(state: simulator.state)

                    if simulator.state.prison.isIncarcerated {
                        PrisonGlanceCard(state: simulator.state) { sheet = .prison }
                    }

                    CurrentLifeNarrativeCard(narrative: CurrentLifeNarrativeResolver.resolve(for: simulator.state))

                    LifeContextCard(signals: LifeContextResolver.topSignals(for: simulator.state))

                    if let recovery = simulator.state.recovery {
                        RecoveryCard(recovery: recovery) {
                            let id: ActionID = recovery.kind == .financial ? .workShift : .rest
                            simulator.execute(id)
                            pulse(.medium)
                            spawnFloating(from: simulator.lastOutcome)
                            showFeedback()
                        }
                    }

                    WhatMattersCard(items: simulator.whatMatters()) { item in
                        domain = item.domain
                        if item.domain == .health {
                            sheet = .health
                        }
                        if let actionID = item.suggestedAction {
                            let action = DomainActionRegistry.action(for: actionID)
                            if simulator.availability(for: action) == .available {
                                simulator.execute(actionID)
                                pulse(.light)
                                spawnFloating(from: simulator.lastOutcome)
                                showFeedback()
                            }
                        }
                    }

                    if !simulator.state.lifeThreads.isEmpty {
                        ContinuityCard(threads: simulator.state.lifeThreads)
                    }

                    Color.clear.frame(height: 0).id(domainActionsAnchor)

                    if domain == .cash {
                        CashGlanceCards(
                            state: simulator.state,
                            openWork: { sheet = .work },
                            openHousehold: { sheet = .household },
                            openAssets: { sheet = .assets }
                        )
                    } else if domain == .love, simulator.state.prison.isIncarcerated {
                        PrisonContactAccessCard(state: simulator.state) { sheet = .prison }
                    } else if domain == .love {
                        LoveGlanceCards(
                            state: simulator.state,
                            openPartner: { sheet = .partner },
                            openFamily: { sheet = .family },
                            openPeople: { sheet = .people }
                        )
                    } else if domain == .school, simulator.state.education.college.isEnrolled {
                        CollegeFoundationView(state: simulator.state)
                    } else if domain == .school, simulator.state.education.recovery.isActive {
                        EducationRecoveryFoundationView(state: simulator.state)
                    } else if domain == .school,
                              simulator.state.lifeStage == .launch,
                              simulator.state.education.hasSchoolLegacy {
                        HighSchoolFoundationView(state: simulator.state)
                    }

                    // Summary-to-action: keep the current action surface ahead
                    // of supporting pressure detail and first-run teaching.
                    DomainActionHeader(
                        title: domainDisplayTitle(domain),
                        symbol: domain.symbol,
                        readyCount: readyActionCount(in: domain),
                        totalCount: simulator.visibleActions(in: domain).count
                    )

                    if domain == .love || domain == .play {
                        personFocusPicker
                    }

                    let suggestions = simulator.suggestedActions(in: domain, focus: selectedPerson)
                    if !suggestions.isEmpty {
                        SuggestedActionsRow(suggestions: suggestions) { suggestion in
                            _ = simulator.execute(suggestion.request)
                            spawnFloating(from: simulator.lastOutcome)
                            showFeedback()
                        }
                    }

                    InstantActionGrid(
                        domain: domain,
                        simulator: simulator,
                        onTap: { action in
                            let target: PersonReference? = {
                                guard domain == .love || domain == .play else { return nil }
                                switch selectedPerson {
                                case .some(.partner): return .partner
                                case .some(.cast) where action.id == .reachOut || action.id == .seeFriends: return selectedPerson
                                default: return nil
                                }
                            }()
                            _ = simulator.execute(.registered(action.id, target: target))
                            pulse(.light)
                            spawnFloating(from: simulator.lastOutcome)
                            showFeedback()
                        },
                        onLongPress: { action in
                            simulator.markLongPressSeen()
                            previewAction = action
                        }
                    )

                    if domain == .school, simulator.state.education.phase == .highSchool {
                        HighSchoolOverview(state: simulator.state)
                    }

                    PressuresRow(pressures: simulator.pressures(for: domain)) { pressure in
                        sheet = .pressure(pressure, domain)
                    }

                    if !simulator.state.flags.seenInstantHint || !simulator.state.flags.seenAgeUpHint {
                        FirstTimeHints(flags: simulator.state.flags)
                    }

                    if let outcome = simulator.lastOutcome, !outcome.isYearly {
                        // Compact last instant line under grid
                        Text(outcome.narrative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("Last Action Outcome")
                    }
                }
                    .padding()
                    .padding(.bottom, 8)
                }
                .onChange(of: domain) { _, _ in
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                        proxy.scrollTo(domainActionsAnchor, anchor: .top)
                    }
                }
                .navigationTitle(simulator.state.character.name)
                .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Identity", systemImage: "person.text.rectangle") { sheet = .identity }
                        Button("Journal", systemImage: "book.closed") { sheet = .journal }
                        #if DEBUG
                        if PlaytestEnvironment.isEnabled {
                            Button("Playtest Notes", systemImage: "checklist") { sheet = .playtest }
                                .accessibilityIdentifier("Playtest Notes Menu Item")
                        }
                        #endif
                        Button("New Life…", systemImage: "arrow.counterclockwise", role: .destructive) {
                            sheet = .confirmNewLife
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Menu")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Health", systemImage: "cross.case.fill") { sheet = .health }
                        .accessibilityLabel("Health actions")
                }
            }
                .safeAreaInset(edge: .bottom) {
                BottomControls(
                    domain: $domain,
                    simulator: simulator,
                    selectDomain: { selected in
                        domain = selected
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                            proxy.scrollTo(domainActionsAnchor, anchor: .top)
                        }
                    },
                    ageUp: ageUp
                )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .background(.bar)
            }
                .overlay {
                // Floating delta particles
                ZStack {
                    ForEach(floatingDeltas) { delta in
                        Text(delta.text)
                            .font(.caption.bold())
                            .foregroundStyle(delta.beneficial ? .green : .red)
                            .offset(x: delta.x, y: delta.y)
                            .opacity(delta.opacity)
                    }
                }
                .allowsHitTesting(false)
                #if DEBUG
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Floating Delta Layer")
                .accessibilityValue("\(floatingDeltas.count)")
                .accessibilityIdentifier("Floating Delta Layer")
                .accessibilityHidden(
                    !ProcessInfo.processInfo.arguments.contains("-uiTestMotionDiagnostics")
                )
                #else
                .accessibilityHidden(true)
                #endif
                }
                #if DEBUG
                .overlay(alignment: .topLeading) {
                    if ProcessInfo.processInfo.arguments.contains("-uiTestMotionDiagnostics") {
                        Text("Motion diagnostics")
                            .accessibilityLabel("Motion Diagnostics")
                            .accessibilityValue(reduceMotion ? "Reduced motion" : "Standard motion")
                            .accessibilityIdentifier("Motion Diagnostics")
                            .font(.system(size: 1))
                            .frame(width: 1, height: 1)
                            .opacity(0.01)
                            .allowsHitTesting(false)
                    }
                }
                #endif
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .alert("Save needs attention", isPresented: Binding(
            get: { simulator.saveErrorMessage != nil },
            set: { _ in }
        )) {
            Button("Try Again") { simulator.saveForLifecycle() }
            Button("Continue", role: .cancel) {}
        } message: {
            Text(simulator.saveErrorMessage ?? "")
        }
        .sheet(item: $sheet) { destination in
            switch destination {
            case .health:
                HealthSheet(simulator: simulator, completed: {
                    spawnFloating(from: simulator.lastOutcome)
                    showFeedback()
                })
            case .review:
                LifeReviewView(
                    review: simulator.lifeReview(),
                    state: simulator.state,
                    playtestExportURLs: simulator.playtestExportURLs(),
                    playtestOutcomeAssessment: simulator.playtestReport()?.outcomeAssessment,
                    onAssessPlaytestOutcome: { explanation, agrees in
                        simulator.assessPlaytestOutcome(explanation: explanation, reviewAgrees: agrees)
                        _ = simulator.playtestExportURLs()
                    },
                    onNewLife: {
                        simulator.archiveCompletedLife()
                        sheet = nil
                        onNewLife()
                    }
                )
            case .journal:
                JournalView(state: simulator.state)
            case .identity:
                IdentityProfileView(state: simulator.state)
            case .work:
                WorkDetailView(simulator: simulator)
            case .economyConversion:
                EconomyConversionView(simulator: simulator)
            case .household:
                EconomyHouseholdView(simulator: simulator)
            case .assets:
                AssetShopView(simulator: simulator)
            case .partner:
                PartnerDetailView(state: simulator.state)
            case .family:
                FamilyDetailView(state: simulator.state)
            case .people:
                PeopleDetailView(state: simulator.state)
            case .prison:
                PrisonDetailView(simulator: simulator)
            case .pressure(let pressure, let domain):
                PressureDetailView(
                    pressure: pressure,
                    domain: domain,
                    simulator: simulator,
                    completed: {
                        spawnFloating(from: simulator.lastOutcome)
                        showFeedback()
                    }
                )
            #if DEBUG
            case .playtest:
                PlaytestFeedbackView(simulator: simulator)
            #endif
            case .confirmNewLife:
                NavigationStack {
                    VStack(spacing: 16) {
                        Text("Start a new life?").font(.title2.bold())
                        Text("This abandons the current run and clears the save.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Start New Life", role: .destructive) {
                            sheet = nil
                            onNewLife()
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Keep Playing") { sheet = nil }
                    }
                    .padding()
                }
                .presentationDetents([.medium])
            }
        }
        .sheet(item: $previewAction) { action in
            ActionPreviewSheet(action: action, availability: simulator.availability(for: action), simulator: simulator)
        }
        .onReceive(simulator.$state) { state in
            if state.finance.economy.conversionNotice { sheet = .economyConversion }
            else if state.isGameOver { sheet = .review }
            else if let event = state.pendingEvent, moment == nil { moment = .event(event) }
        }
        .onReceive(simulator.$lastOutcome) { outcome in
            guard let outcome, !outcome.isYearly else { return }
            let sequence = simulator.state.historySequence
            guard sequence > lastObservedHistorySequence else { return }
            lastObservedHistorySequence = sequence
            guard sheet != nil else { return }
            sheet = nil
            if let event = simulator.state.pendingEvent { moment = .event(event) }
            else { moment = .outcome(outcome) }
        }
        .onChange(of: sheet?.id) { _, _ in
            lastObservedHistorySequence = simulator.state.historySequence
        }
        .onAppear {
            lastObservedHistorySequence = simulator.state.historySequence
            if simulator.state.finance.economy.conversionNotice { sheet = .economyConversion; return }
            let arguments = ProcessInfo.processInfo.arguments
            if (arguments.contains("-uiTestWorldNews")
                || arguments.contains("-uiTestPublicHealth")
                || arguments.contains("-uiTestQuietRecap")),
               let summary = simulator.state.lastYearSummary {
                moment = .recap(summary)
            }
            if let event = simulator.state.pendingEvent { moment = .event(event) }
        }
        .overlay {
            if moment != nil {
                CenteredLifeMomentCard(moment: $moment, simulator: simulator)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: simulator.state.character.age)
    }

    private func ageUp() {
        simulator.ageUp()
        pulse(.medium)
        if simulator.state.isGameOver {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            sheet = .review
        } else if let event = simulator.state.pendingEvent {
            pulse(event.isPartnerEvent ? .heavy : .medium)
            moment = .event(event)
        } else if let summary = simulator.state.lastYearSummary {
            if summary.importance == .critical { pulse(.heavy) }
            moment = .recap(summary)
        }
    }

    private func showFeedback() {
        if let event = simulator.state.pendingEvent { moment = .event(event); return }
        guard let outcome = simulator.lastOutcome else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { moment = .outcome(outcome) }
        if UIAccessibility.isVoiceOverRunning {
            let deltas = outcome.deltas.semanticLines.prefix(4).map(\.text).joined(separator: ", ")
            let announcement = deltas.isEmpty ? "\(outcome.headline). \(outcome.narrative)" : "\(outcome.headline). \(deltas)"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    private var personFocusPicker: some View {
        Menu {
            Button("General") { selectedPerson = nil }
            if simulator.state.partner != nil {
                Button(simulator.state.partner?.name ?? "Partner") { selectedPerson = .partner }
            }
            ForEach(simulator.state.npcs.all) { person in
                Button("\(person.name) · \(person.role.title)") { selectedPerson = .cast(person.memberID) }
            }
            ForEach(simulator.state.family.contacts) { contact in
                Button("\(contact.name) · Family") { selectedPerson = .family(contact.id) }
            }
        } label: {
            HStack {
                Label("Focus", systemImage: "person.crop.circle")
                Spacer()
                Text(selectedPerson.flatMap { simulator.state.name(for: $0) } ?? "General")
                Image(systemName: "chevron.down")
            }
            .font(.subheadline)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityIdentifier("Person Focus")
    }

    private func spawnFloating(from outcome: ActionOutcome?) {
        guard !reduceMotion else {
            floatingDeltas = []
            return
        }
        guard let outcome, !outcome.deltas.semanticLines.isEmpty else { return }
        let lines = Array(outcome.deltas.semanticLines.prefix(4))
        var items: [FloatingDelta] = []
        for (i, line) in lines.enumerated() {
            items.append(FloatingDelta(
                id: UUID(),
                text: line.text,
                beneficial: line.beneficial,
                x: CGFloat([-40, 0, 40, 20][i % 4]),
                y: 80,
                opacity: 1
            ))
        }
        floatingDeltas = items
        withAnimation(.easeOut(duration: 1.1)) {
            floatingDeltas = items.map {
                var d = $0
                d.y = -20
                d.opacity = 0
                return d
            }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.15))
            floatingDeltas = []
        }
    }

    private func pulse(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func domainDisplayTitle(_ domain: Domain) -> String {
        domain.displayTitle(attendsSchool: simulator.state.flags.attendsSchool)
    }

    private func readyActionCount(in domain: Domain) -> Int {
        simulator.visibleActions(in: domain).filter {
            simulator.availability(for: $0) == .available
        }.count
    }
}

// MARK: - Sheets

private enum DashboardSheet: Identifiable {
    case health, review, journal, identity, work, household, economyConversion, assets, partner, family, people, prison, pressure(DomainPressure, Domain), confirmNewLife
    #if DEBUG
    case playtest
    #endif
    var id: String {
        switch self {
        case .health: "health"
        case .review: "review"
        case .journal: "journal"
        case .identity: "identity"
        case .work: "work"
        case .economyConversion: "economyConversion"
        case .household: "household"
        case .assets: "assets"
        case .partner: "partner"
        case .family: "family"
        case .people: "people"
        case .prison: "prison"
        case .pressure(let pressure, let domain): "pressure-\(domain.rawValue)-\(pressure.id)"
        case .confirmNewLife: "new-life"
        #if DEBUG
        case .playtest: "playtest"
        #endif
        }
    }

}

private enum DashboardMoment {
    case event(PresentedEvent)
    case recap(YearSummary)
    case outcome(ActionOutcome)
}

private struct SuggestedActionsRow: View {
    let suggestions: [ActionSuggestion]
    let choose: (ActionSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(suggestions) { suggestion in
                Button { choose(suggestion) } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title).font(.subheadline.bold())
                            Text(suggestion.reason).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(11)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("Suggested Action \(suggestion.request.key)")
            }
        }
        .accessibilityIdentifier("Suggested Actions")
    }
}

private struct CenteredLifeMomentCard: View {
    @Binding var moment: DashboardMoment?
    @ObservedObject var simulator: LifeSimulator

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.34).ignoresSafeArea()
                    .accessibilityHidden(true)
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let moment {
                            switch moment {
                            case .event(let event): eventContent(event)
                            case .recap(let summary): recapContent(summary)
                            case .outcome(let outcome): outcomeContent(outcome)
                            }
                        }
                    }
                    .padding(18)
                }
                .frame(maxWidth: min(420, geometry.size.width - 32))
                .frame(maxHeight: geometry.size.height * 0.76)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 22, y: 8)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("Life Moment Popup")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func eventContent(_ event: PresentedEvent) -> some View {
        Text(event.kind == .yearly ? "THIS YEAR" : "RIGHT NOW")
            .font(.caption.bold()).foregroundStyle(.secondary)
        Text(event.headline).font(.title2.bold())
        Text(event.detail).font(.subheadline).foregroundStyle(.secondary)
        let impacts = YearSummarySystem.rankedImpacts(event.yearDeltas, limit: 3)
        if !impacts.isEmpty { AdaptiveDeltaRow(deltas: impacts) }
        VStack(spacing: 8) {
            ForEach(event.choices.prefix(3)) { choice in
                let available = simulator.choiceAvailability(choice, eventID: event.id)
                Button { resolve(choice.id) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(choice.title).font(.subheadline.bold())
                            Text(available.reason ?? choice.detail)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(available != .available)
                .accessibilityIdentifier("Event Choice \(choice.id.rawValue)")
                .accessibilityLabel("\(choice.title). \(available.reason ?? choice.detail)")
            }
        }
    }

    @ViewBuilder
    private func recapContent(_ summary: YearSummary) -> some View {
        Text("AGE \(max(14, summary.age - 1)) → \(summary.age)")
            .font(.caption.bold()).foregroundStyle(.secondary)
        Text(summary.importance == .quiet ? "Quiet year" : "Year resolved")
            .font(.caption.bold()).foregroundStyle(.secondary)
            .accessibilityIdentifier("Year Summary")
        Text(summary.headline).font(.title2.bold())
        let impacts = YearSummarySystem.rankedImpacts(summary.deltas, limit: 3)
        if !impacts.isEmpty { AdaptiveDeltaRow(deltas: impacts) }
        ForEach(summary.developments.prefix(2)) { development in
            Label(development.text, systemImage: "circle.fill")
                .font(.subheadline)
        }
        if let silence = summary.silenceNote {
            Text(silence).font(.subheadline).foregroundStyle(.secondary)
        }
        Button("Continue") { moment = nil }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("Year Recap Continue")
    }

    @ViewBuilder
    private func outcomeContent(_ outcome: ActionOutcome) -> some View {
        Text("RIGHT NOW").font(.caption.bold()).foregroundStyle(.secondary)
        Text(outcome.headline).font(.title2.bold())
        Text(outcome.narrative).font(.subheadline).foregroundStyle(.secondary)
        let impacts = YearSummarySystem.rankedImpacts(outcome.deltas, limit: 3)
        if !impacts.isEmpty { AdaptiveDeltaRow(deltas: impacts) }
        ForEach(outcome.impacts.prefix(3)) { impact in
            Text(impact.text).font(.caption.bold())
        }
        Button("Continue") { moment = nil }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("Outcome Continue")
    }

    private func resolve(_ choiceID: EventChoiceID) {
        guard case .some(.event(let event)) = moment else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        simulator.execute(choiceID)
        if let next = simulator.state.pendingEvent {
            moment = .event(next)
        } else if event.kind == .yearly, let summary = simulator.state.lastYearSummary {
            moment = .recap(summary)
        } else if let outcome = simulator.lastOutcome {
            moment = .outcome(outcome)
        } else {
            moment = nil
        }
    }
}

private struct FloatingDelta: Identifiable {
    let id: UUID
    let text: String
    let beneficial: Bool
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}

// MARK: - Essential-life glance and disclosure

private struct ContinuityCard: View {
    let threads: [LifeThread]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label("Still shaping this life", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.headline)
                Spacer()
                Text("\(threads.count) active")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ForEach(threads.prefix(3)) { thread in
                HStack(alignment: .top, spacing: 9) {
                    Circle()
                        .fill(thread.intensity >= 5 ? Color.red : Color.orange)
                        .frame(width: 8, height: 8)
                        .padding(.top, 5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(thread.headline)
                            .font(.subheadline.weight(.semibold))
                        Text(threadLine(thread))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Continuity Card")
    }

    private func threadLine(_ thread: LifeThread) -> String {
        let destination = thread.target.map(domainTitle) ?? "Life"
        let status = thread.resolution == .stabilizing ? "stabilizing" : "active"
        return "\(destination) · \(status) · \(thread.yearsRemaining)y window"
    }

    private func domainTitle(_ domain: ConsequenceDomain) -> String {
        switch domain {
        case .education: "Education"
        case .career: "Career"
        case .finance: "Money"
        case .relationships: "Relationships"
        case .family: "Family"
        case .health: "Health"
        case .assets: "Assets"
        case .legal: "Legal"
        case .world: "World"
        case .identity: "Identity"
        }
    }
}

private struct EssentialGlanceCard: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("\(title): \(value)", systemImage: symbol)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        Label(title, systemImage: symbol).font(.caption.bold()).foregroundStyle(.secondary)
                        Text(value).font(.headline).foregroundStyle(.primary)
                        Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                    }
                }
            }
            .padding(12)
            .frame(
                maxWidth: .infinity,
                minHeight: dynamicTypeSize.isAccessibilitySize ? 72 : 92,
                alignment: .topLeading
            )
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(title) Glance Card")
    }
}

private struct PrisonGlanceCard: View {
    let state: LifeState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "lock.square.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Inside: \(state.prison.security?.title ?? "Prison")")
                        .font(.headline)
                    Text("\(state.prison.sentenceYearsRemaining)y left · \(state.prison.contactAccess)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if state.prison.informantOffered {
                        Text("Federal offer waiting")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("Prison Glance Card")
    }
}

private struct PrisonContactAccessCard: View {
    let state: LifeState
    let openPrison: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Contact is restricted", systemImage: "phone.down.fill")
                .font(.headline)
            Text(state.prison.contactAccess + ". Family, partner, and outside contacts are no longer a normal action surface.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Review prison access", action: openPrison)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("Prison Contact Restriction")
    }
}

private struct PrisonDetailView: View {
    @ObservedObject var simulator: LifeSimulator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let security = simulator.state.prison.security {
                    Section("Sentence") {
                        LabeledContent("Facility", value: security.title)
                        LabeledContent("Time left", value: "\(simulator.state.prison.sentenceYearsRemaining) years")
                        LabeledContent("Medical access", value: security.medicalAccess.rawValue.capitalized)
                        LabeledContent("Conjugal visits", value: security.canReceiveConjugalVisit ? "Available when approved" : "Not available")
                    }
                }
                Section("Power inside") {
                    LabeledContent("Gang role", value: simulator.state.prison.gangRole.title)
                    LabeledContent("Gang influence", value: "\(simulator.state.prison.gangInfluence)")
                    LabeledContent("Prison influence", value: "\(simulator.state.prison.prisonInfluence)")
                    LabeledContent("Gang loyalty", value: "\(simulator.state.prison.gangLoyalty)")
                    Text(simulator.state.prison.canManageGang
                         ? "Your role still gives you a narrow line to the gang. Every year inside tests that line."
                         : "The institution has cut most of your outside authority.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Inside network") {
                    LabeledContent("Prison notoriety", value: "\(simulator.state.prison.prisonNotoriety)")
                    LabeledContent("Mental strain", value: "\(simulator.state.prison.mentalStrain)")
                    LabeledContent("Medical debt", value: "$\(simulator.state.prison.medicalDebt)")
                    LabeledContent("Prison work", value: simulator.state.prison.prisonJob ?? "None")
                    LabeledContent("Protection", value: simulator.state.prison.protectionYearsRemaining > 0 ? "Active" : "None")
                    if simulator.state.prison.isInformant {
                        LabeledContent("Informant status", value: simulator.state.prison.informantExposed ? "Exposed" : "Hidden")
                    }
                    HStack {
                        Button("Fight") { _ = simulator.execute(.domain(.prison(.fight, nil))) }
                        Button("Pay protection") { _ = simulator.execute(.domain(.prison(.payForProtection, nil))) }
                            .disabled(simulator.state.cash < (simulator.state.prison.prisonGangMember ? 180 : 300))
                    }
                    HStack {
                        Button(simulator.state.prison.prisonJob == nil ? "Take prison job" : "Leave prison job") { _ = simulator.execute(.domain(.prison(.takePrisonJob, nil))) }
                        Button("Medical care") { _ = simulator.execute(.domain(.prison(.requestMedicalCare, nil))) }
                        Button("Call family") { _ = simulator.execute(.domain(.prison(.contactFamily, nil))) }
                    }
                    if simulator.state.prison.security?.canReceiveConjugalVisit == true {
                        Button("Request conjugal visit") { _ = simulator.execute(.domain(.prison(.conjugalVisit, nil))) }
                    }
                    ForEach(simulator.state.prison.inmates) { inmate in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(inmate.name).font(.headline)
                            Text("\(inmate.disposition.rawValue.capitalized) · rapport \(inmate.rapport) · hostility \(inmate.hostility)")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Button("Friend") { _ = simulator.execute(.domain(.prison(.buildFriendship, inmate.id))) }
                                Button("Recruit") { _ = simulator.execute(.domain(.prison(.recruit, inmate.id))) }
                                Button("Protect me") { _ = simulator.execute(.domain(.prison(.askForProtection, inmate.id))) }
                            }
                            .font(.caption)
                        }
                    }
                }
                if let path = simulator.state.career.criminalPath, path.isOrganization {
                    Section("Organization continuity") {
                        LabeledContent("Organization", value: path.gangName ?? "Unnamed crew")
                        LabeledContent("Acting leader", value: path.specialists.first(where: { $0.id == path.actingLeaderID })?.name ?? "Being selected")
                        LabeledContent("Outside morale", value: "\(path.organizationMorale)")
                        LabeledContent("Prison orders", value: "\(simulator.state.prison.commandsRemaining)/\(simulator.state.prison.commandCapacity) remaining")
                        LabeledContent("Communication security", value: "\(simulator.state.prison.communicationSecurity)%")
                        Text(path.organizationAbsent
                             ? "The organization is running from saved plans while you are inside. Leadership competence changes cash flow and stability."
                             : "The organization is not currently marked absent.")
                            .font(.caption).foregroundStyle(.secondary)
                        if simulator.state.prison.canManageGang {
                            HStack {
                                Button("Reassure crew") {
                                    _ = simulator.execute(.domain(.prisonCommand(.reassureCrew, nil)))
                                }
                                Button("Fund $500") {
                                    _ = simulator.execute(.domain(.prisonCommand(.fundOrganization, nil)))
                                }
                                .disabled(simulator.state.cash < 500)
                            }
                            ForEach(path.plans) { plan in
                                Button("Authorize \(plan.operation.title)") {
                                _ = simulator.execute(.domain(.prisonCommand(.authorizePlan, plan.id)))
                                }
                            }
                            Button("Send $200 support outside") {
                                _ = simulator.execute(.domain(.prisonSupport))
                            }
                            .disabled(simulator.state.cash < 200)
                            ForEach(path.specialists.filter(\.isAvailable)) { specialist in
                                Button("Appoint \(specialist.name) as acting leader") {
                                    _ = simulator.execute(.domain(.appointActingLeader(specialist.id)))
                                }
                            }
                        }
                    }
                }
                if simulator.state.prison.informantOffered {
                    Section("A dangerous choice") {
                        Text("Federal agents are offering protection and information in exchange for cooperation. Taking it may save you inside, but your gang will see the move as a flip.")
                            .font(.subheadline)
                        Button("Become a federal informant", role: .destructive) {
                            simulator.execute(.domain(.prisonInformant(true)))
                        }
                        Button("Refuse for now") { simulator.execute(.domain(.prisonInformant(false))) }
                    }
                }
            }
            .navigationTitle("Prison")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

private struct CashGlanceCards: View {
    let state: LifeState
    let openWork: () -> Void
    let openHousehold: () -> Void
    let openAssets: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) {
                    AccessibleEssentialGlanceRow(
                        title: "Work",
                        value: "\(state.career.careerClass.title) · \(state.career.level.rawValue.capitalized)",
                        detail: "$\(state.career.annualIncome)/yr · burnout \(state.career.burnout)",
                        symbol: "briefcase.fill",
                        action: openWork
                    )
                    AccessibleEssentialGlanceRow(
                        title: "Household",
                        value: "Expected \(MoneyText.compact(EconomyCalculator.forecast(state).detail.expectedNet / 12))/mo",
                        detail: "Cash \(MoneyText.compact(state.cash)) · debt \(MoneyText.compact(state.totalDebt))",
                        symbol: "house.fill",
                        action: openHousehold
                    )
                    AccessibleEssentialGlanceRow(
                        title: "Assets",
                        value: "$\(state.assets.totalValue) value",
                        detail: "\(state.assets.ownedCount) owned · \(state.assets.properties.count) properties",
                        symbol: "shippingbox.fill",
                        action: openAssets
                    )
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) { cards }
            }
        }
    }

    @ViewBuilder private var cards: some View {
        EssentialGlanceCard(title: "Work", value: state.career.rankTitle, detail: "\(state.career.occupation?.title ?? "Choose an occupation") · $\(state.career.annualIncome)/yr · burnout \(state.career.burnout)", symbol: "briefcase.fill", action: openWork)
        EssentialGlanceCard(title: "Household", value: "Expected \(MoneyText.compact(EconomyCalculator.forecast(state).detail.expectedNet / 12))/mo", detail: "Cash \(MoneyText.compact(state.cash)) · debt \(MoneyText.compact(state.totalDebt))", symbol: "house.fill", action: openHousehold)
        EssentialGlanceCard(title: "Assets", value: "$\(state.assets.totalValue) value", detail: "\(state.assets.ownedCount) owned · \(state.assets.properties.count) properties", symbol: "shippingbox.fill", action: openAssets)
    }
}

private struct AccessibleEssentialGlanceRow: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Label(title, systemImage: symbol)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue("\(value). \(detail)")
        .accessibilityIdentifier("\(title) Glance Card")
    }
}

private struct LoveGlanceCards: View {
    let state: LifeState
    let openPartner: () -> Void
    let openFamily: () -> Void
    let openPeople: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var activePeople: [NPCState] {
        state.npcs.all.filter { $0.activity != .dormant }
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize { VStack(spacing: 10) { cards } }
            else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 10) {
                    cards
                }
            }
        }
    }

    @ViewBuilder private var cards: some View {
        EssentialGlanceCard(title: "Partner", value: state.partner.map { "\($0.name) · \($0.stage.rawValue.capitalized)" } ?? "No partner", detail: state.partner.map { "Bond \($0.bond) · tension \($0.resentment)" } ?? state.formerRelationships.first.map { "\($0.name) · \($0.yearsTogether)y relationship ended" } ?? "Dating remains available.", symbol: "heart.fill", action: openPartner)
        EssentialGlanceCard(title: "Family", value: "\(state.family.dependentLoad) dependent", detail: "\(state.family.intention.title) · care \(state.family.caregivingLoad)", symbol: "figure.2.and.child.holdinghands", action: openFamily)
        EssentialGlanceCard(
            title: "People",
            value: activePeople.isEmpty ? "Circle is quiet" : "\(activePeople.count) active",
            detail: activePeople.isEmpty
                ? "Connections can return when life makes them relevant."
                : activePeople.prefix(2).map { "\($0.name) · \($0.relationshipTone.title.lowercased())" }.joined(separator: " · "),
            symbol: "person.2.fill",
            action: openPeople
        )
    }
}

private struct WorkDetailView: View {
    @ObservedObject var simulator: LifeSimulator
    @Environment(\.dismiss) private var dismiss
    @State private var crimeFeedback: String?
    @State private var organizationFeedback: String?
    private var state: LifeState { simulator.state }
    var body: some View {
        NavigationStack { List {
            if let situation = state.career.activeSituation {
                Section("Active situation") {
                    SituationStatusView(title: situation.kind.title, stage: situation.stage, stakes: situation.stakes, suggestedAction: situation.suggestedAction)
                }
            }
            Section("Track") { LabeledContent("Class", value: state.career.careerClass.title); LabeledContent("Path", value: state.career.track.title); LabeledContent("Occupation", value: state.career.occupation?.title ?? "Choose an occupation"); LabeledContent("Rank", value: state.career.rankTitle); LabeledContent("Tenure", value: "\(state.career.tenure) years") }
            Section("Workplace") { LabeledContent("Employer", value: state.career.workplace.employer.title); LabeledContent("Culture", value: state.career.workplace.culture.title); LabeledContent("Manager relationship", value: "\(state.career.workplace.managerRelationship)"); LabeledContent("Coworker standing", value: "\(state.career.workplace.coworkerStanding)"); LabeledContent("Flexibility", value: "\(state.career.workplace.flexibility)"); LabeledContent("Years here", value: "\(state.career.workplace.yearsAtEmployer)") }
            Section("Progress") { LabeledContent("Performance", value: "\(state.career.performance)"); LabeledContent("Skill", value: "\(state.career.skill)"); LabeledContent("Focus", value: state.career.focus?.title ?? "Undeclared"); LabeledContent("Focus progress", value: "\(state.career.focusProgress)%"); LabeledContent("Credentials", value: "\(state.career.credentialProgress)"); LabeledContent("Promotion", value: "\(state.career.promotionProgress)%"); LabeledContent("Leverage", value: "\(state.career.negotiationLeverage)"); LabeledContent("Career reputation", value: "\(state.career.careerReputation)"); LabeledContent("References", value: "\(state.career.referenceStrength)") }
            Section("Capacity") { LabeledContent("Security", value: "\(state.career.security)"); LabeledContent("Benefits", value: "\(state.career.benefits)"); LabeledContent("Paid leave", value: "\(state.career.paidLeaveDays) days"); LabeledContent("Mentorship", value: "\(state.career.mentorship)"); LabeledContent("Workload", value: "\(state.career.workload)"); LabeledContent("Burnout", value: "\(state.career.burnout)"); LabeledContent("Retirement readiness", value: "\(state.career.retirementReadiness)") }
            if state.career.careerClass == .special || state.career.careerClass == .diamond {
                Section(state.career.careerClass == .diamond ? "Institution" : "Special career") {
                    if state.career.careerClass == .special { LabeledContent("Momentum", value: "\(state.career.specialMomentum)") }
                    if state.career.careerClass == .diamond { LabeledContent("Legacy leverage", value: "\(state.career.legacyLeverage)") }
                }
            }
            if let venture = state.career.venture {
                Section("Entrepreneurship") {
                    LabeledContent("Stage", value: venture.stage.rawValue.capitalized)
                    LabeledContent("Company cash", value: "$\(venture.companyCash)")
                    LabeledContent("Runway", value: "\(venture.companyCash / max(1, venture.annualBurn)) years")
                    LabeledContent("Traction", value: "\(venture.traction) · Team trust \(venture.teamTrust)")
                    LabeledContent("Estimated value", value: "$\(venture.valuation)")
                    if let offer = venture.pendingOffer {
                        Text(offer.headline).font(.headline)
                        Text("$\(offer.amount) · Expires after age \(offer.expiresAtAge)").font(.caption).foregroundStyle(.secondary)
                        Button("Accept offer") { _ = simulator.execute(.domain(.venture(.acceptOffer))) }
                            .disabled(venture.decisionAge == state.character.age && venture.decisionsThisYear >= 2)
                        Button("Decline offer") { _ = simulator.execute(.domain(.venture(.declineOffer))) }
                            .disabled(venture.decisionAge == state.character.age && venture.decisionsThisYear >= 2)
                    }
                    HStack {
                        Button("Pivot") { _ = simulator.execute(.domain(.venture(.pivot))) }
                        Button("Hire advisor · $2,000") { _ = simulator.execute(.domain(.venture(.hireAdvisor))) }
                        Button("Cut burn") { _ = simulator.execute(.domain(.venture(.cutBurn))) }
                    }
                    .disabled(venture.decisionAge == state.character.age && venture.decisionsThisYear >= 2)
                }
            }
            if state.character.age >= 14 {
                let criminalSummary = simulator.criminalCareerSnapshot()
                Section("Criminal career") {
                    LabeledContent("Path", value: "\(criminalSummary.pathTitle) · \(criminalSummary.rankTitle)")
                    LabeledContent("Cash flow", value: "$\(criminalSummary.cashFlow)/year")
                    LabeledContent("Heat", value: "\(criminalSummary.heat)")
                    LabeledContent("Notoriety", value: "\(criminalSummary.notoriety)")
                    LabeledContent("Next operation", value: criminalSummary.nextOperationTitle)
                    if let blocker = criminalSummary.blocker {
                        Text(blocker)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Starter operations") {
                    Text("Available without a gang. Skill, notoriety, and heat carry forward into later criminal paths.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(simulator.availableSoloCrimeOperations()) { operation in
                        let risk = simulator.soloCrimeRisk(operation)
                        Button {
                            if let outcome = simulator.execute(.domain(.soloCrime(operation))) {
                                crimeFeedback = "\(outcome.headline). \(outcome.narrative)"
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(operation.title)
                                    Text("Risk \(risk.total)% · \(risk.lines.prefix(2).joined(separator: " · "))")
                                        .font(.caption)
                                        .foregroundStyle(risk.total >= 65 ? .red : .secondary)
                                }
                                Spacer()
                                Image(systemName: "bolt.shield.fill")
                                    .foregroundStyle(risk.total >= 65 ? .red : .orange)
                            }
                        }
                        .disabled(!simulator.canExecuteSoloCrime(operation))
                    }
                    if let crimeFeedback { Text(crimeFeedback).font(.caption) }
                }
            }
            if state.career.criminalPath != nil {
                criminalKitSection
            }
            criminalOrganizationSection
            if !state.legal.cases.isEmpty {
                Section("Legal cases") {
                    let availableLawyers = (state.career.criminalPath?.defenseTeam ?? []) + state.legal.personalLawyers
                    HStack {
                        Menu("Hire counsel") {
                            ForEach(LegalLawyerSpecialty.allCases) { specialty in
                                Button("Personal · \(specialty.title) · $\(specialty == .general ? 4_000 : 7_500)") {
                                    _ = simulator.execute(.domain(.hireDefenseLawyer(specialty, false)))
                                }
                            }
                            if state.career.criminalPath?.isOrganization == true {
                                Divider()
                                ForEach(LegalLawyerSpecialty.allCases) { specialty in
                                    Button("Organization · \(specialty.title)") {
                                        _ = simulator.execute(.domain(.hireDefenseLawyer(specialty, true)))
                                    }
                                }
                            }
                        }
                        .disabled(state.cash < 4_000 || (state.legal.personalLawyers.count >= 3 && (state.career.criminalPath?.defenseTeam.count ?? 0) >= 3))
                        Spacer()
                        Text("\(availableLawyers.count)/\(state.career.criminalPath?.isOrganization == true ? 6 : 3) counsel")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(availableLawyers) { lawyer in
                        Text("\(lawyer.name) · \(lawyer.specialty.title) · defense \(lawyer.defenseSkill)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(state.legal.cases) { legalCase in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(legalCase.operation.title + " · " + legalCase.severity.rawValue.capitalized).font(.headline)
                            Text("\(legalCase.status.title) · \(legalCase.agency.title) · evidence \(legalCase.evidenceStrength)%")
                                .font(.caption).foregroundStyle(.secondary)
                            if legalCase.status == .investigation {
                                Text("Visibility \(legalCase.investigationVisibility)% · financial trail \(legalCase.financialTrailStrength)% · warrants \(legalCase.searchWarrantCount) · year \(legalCase.yearsUnderInvestigation)")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            if legalCase.status == .pretrial {
                                Text("\(legalCase.pretrialStatus.title) · bail $\(legalCase.bailAmount) · sentence estimate \(legalCase.sentenceYears)y")
                                    .font(.caption2).foregroundStyle(legalCase.pretrialStatus == .detained ? .red : .orange)
                                if legalCase.travelRestricted || legalCase.noContactRestricted {
                                    Text([legalCase.travelRestricted ? "Travel restricted" : nil, legalCase.noContactRestricted ? "No contact with organization" : nil].compactMap { $0 }.joined(separator: " · "))
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            if legalCase.origin == .enterprise {
                                enterpriseTargetsSection(for: legalCase)
                                cooperationSection(for: legalCase)
                            }
                            HStack {
                                if !availableLawyers.isEmpty {
                                    Menu("Counsel") {
                                        ForEach(availableLawyers) { lawyer in
                                            Button(lawyer.name) { _ = simulator.execute(.domain(.assignDefenseLawyer(lawyer.id, legalCase.id))) }
                                        }
                                    }
                                }
                                if legalCase.status == .pleaOffered { Button("Accept plea") { _ = simulator.execute(.domain(.legalPlea(legalCase.id))) } }
                                if legalCase.status == .pleaOffered { Button("Go to trial") { _ = simulator.execute(.domain(.legalTrial(legalCase.id))) } }
                                if legalCase.status == .pretrial {
                                    if legalCase.pretrialStatus == .detained {
                                        Button("Post bail · $\(legalCase.bailAmount)") { _ = simulator.execute(.domain(.legalBail(legalCase.id))) }
                                            .disabled(state.cash < legalCase.bailAmount)
                                        Button("Seek supervised release") { _ = simulator.execute(.domain(.supervisedRelease(legalCase.id))) }
                                    } else {
                                        Button("Accept detention") { _ = simulator.execute(.domain(.legalDetention(legalCase.id))) }
                                        Button("Report violation") { _ = simulator.execute(.domain(.pretrialViolation(legalCase.id))) }
                                    }
                                    Button("Accept plea") { _ = simulator.execute(.domain(.legalPlea(legalCase.id))) }
                                    Button("Go to trial") { _ = simulator.execute(.domain(.legalTrial(legalCase.id))) }
                                }
                                if legalCase.status == .convicted { Button("Appeal") { _ = simulator.execute(.domain(.legalAppeal(legalCase.id))) } }
                            }.font(.caption)
                        }
                    }
                }
            }
            Section("Last transition") { Text(state.career.lastTransition.rawValue.capitalized) }
        }.navigationTitle("Work").toolbar { Button("Done") { dismiss() } } }
    }

    @ViewBuilder
    private func enterpriseTargetsSection(for legalCase: LegalCaseState) -> some View {
        let targets = simulator.enterpriseLegalTargets(for: legalCase.id)
        VStack(alignment: .leading, spacing: 4) {
            Text("Enterprise targets")
                .font(.caption.weight(.semibold))
            ForEach(targets) { target in
                HStack(alignment: .top, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(targetName(target)) · \(target.status.title)")
                            .font(.caption)
                        Text("Evidence \(target.evidenceStrength)% · exposure \(target.exposure)% · cooperation risk \(target.cooperationRisk)%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    let actions = simulator.enterpriseLegalActions(for: legalCase.id, targetID: target.id)
                    if !actions.isEmpty {
                        Menu("Respond") {
                            ForEach(actions) { action in
                                Button(action.title) {
                                    switch action {
                                    case .protect: _ = simulator.execute(.domain(.enterpriseLegal(legalCase.id, target.id, .protect)))
                                    case .cutLoose: _ = simulator.execute(.domain(.enterpriseLegal(legalCase.id, target.id, .cutLoose)))
                                    case .threaten: _ = simulator.execute(.domain(.threatenEnterpriseSpecialist(legalCase.id, target.id)))
                                    case .provideLegalSupport: _ = simulator.execute(.domain(.enterpriseLegal(legalCase.id, target.id, .provideLegalSupport)))
                                    }
                                }
                            }
                        }
                        .font(.caption2)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func targetName(_ target: LegalTargetState) -> String {
        switch target.type {
        case .player: "You"
        case .organization: "Organization"
        case .frontBusiness: "Front business"
        case .specialist: target.id.replacingOccurrences(of: "specialist:", with: "Specialist ")
        }
    }

    @ViewBuilder
    private func cooperationSection(for legalCase: LegalCaseState) -> some View {
        if let offer = simulator.cooperationOffer(for: legalCase.id) {
            VStack(alignment: .leading, spacing: 4) {
                Text(offer.headline)
                    .font(.caption.weight(.semibold))
                Text("\(offer.detail) Sentence reduction: \(offer.sentenceReduction)y.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack {
                    Button(offer.targetType == .player ? "Accept cooperation" : "Accept specialist deal") {
                        _ = simulator.execute(.domain(.legalCooperation(legalCase.id, true)))
                    }
                    Button("Decline") {
                        _ = simulator.execute(.domain(.legalCooperation(legalCase.id, false)))
                    }
                }
                .font(.caption)
            }
            .padding(.vertical, 2)
        } else if legalCase.cooperationStatus == .accepted {
            Text(legalCase.playerCooperated ? "Cooperation record: you testified" : "Cooperation record: specialist testified")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private var criminalOrganizationSection: some View {
        if let path = state.career.criminalPath, path.isOrganization {
            Section("Criminal organization") {
                LabeledContent("Organization", value: path.gangName ?? "Unnamed crew")
                LabeledContent("Rank", value: path.rank.title)
                LabeledContent("Notoriety", value: "\(path.notoriety)")
                LabeledContent("Heat", value: "\(path.heat)")
                LabeledContent("Cash flow", value: "$\(path.cashFlow)/year")
                LabeledContent("Specialists", value: "\(path.specialists.count)/6")
                if path.mode == .gangMember {
                    if let specialty = path.gangSpecialty {
                        LabeledContent("Assigned specialty", value: "\(specialty.title) · skill \(path.gangSpecialtySkill)")
                        Text(specialty.detail)
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Work your specialty") {
                            if let outcome = simulator.execute(.domain(.workGangSpecialty)) {
                                organizationFeedback = "\(outcome.headline). \(outcome.narrative)"
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(path.lastSpecialtyWorkAge == state.character.age)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Choose your assigned specialty")
                                .font(.headline)
                            Text("The gang appoints your rank. This choice defines your street-level work and its risks.")
                                .font(.caption).foregroundStyle(.secondary)
                            ForEach(CriminalSpecialty.allCases) { specialty in
                                Button {
                                    if simulator.execute(.domain(.chooseGangSpecialty(specialty))) != nil {
                                        organizationFeedback = "You were assigned as a \(specialty.title.lowercased())."
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(specialty.title)
                                            Text(specialty.detail).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                }
                            }
                        }
                    }
                }
                if let organizationFeedback { Text(organizationFeedback).font(.caption) }
            }
            if path.canManageDrugEnterprise {
                Section("Syndicate drug enterprise") {
                    if let enterprise = path.drugEnterprise, enterprise.active {
                        LabeledContent("Product quality", value: "\(enterprise.productQuality)")
                        LabeledContent("Demand", value: "\(enterprise.demand)")
                        LabeledContent("Supply reliability", value: "\(enterprise.supplyReliability)")
                        LabeledContent("Network coverage", value: "\(enterprise.networkCoverage)")
                        LabeledContent("Network roles", value: "\(enterprise.mules) mules · \(enterprise.runners) runners · \(enterprise.supplyRetrievers) retrievers")
                        LabeledContent("Total revenue", value: "$\(enterprise.totalRevenue)")
                        Button("Manage enterprise") {
                            if let outcome = simulator.execute(.domain(.manageDrugEnterprise)) {
                                organizationFeedback = "\(outcome.headline). \(outcome.narrative)"
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(enterprise.lastManagedAge == state.character.age)
                        Button("Improve formula ($500)") {
                            if simulator.execute(.domain(.improveDrugFormula)) != nil { organizationFeedback = "The formula improved, but visibility rose." }
                        }
                        .disabled(state.cash < 500 || enterprise.productQuality >= 100)
                        ForEach(DrugEnterpriseRole.allCases) { role in
                            Button("Recruit \(role.title.lowercased()) ($\(role.cost))") {
                                if simulator.execute(.domain(.recruitDrugEnterpriseRole(role))) != nil { organizationFeedback = "The network gained \(role.title.lowercased())." }
                            }
                            .disabled(state.cash < role.cost)
                        }
                    } else {
                        Text("Optional organization branch. Syndicate leadership manages the network; street careers perform assigned jobs.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Open drug enterprise ($3,000)") {
                            if simulator.execute(.domain(.startDrugEnterprise)) != nil { organizationFeedback = "The optional drug enterprise is open." }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(state.cash < 3_000)
                    }
                }
            }
            Section("Saved operation plans") {
                Text("Plans preserve your crew, equipment, preparation, mastery, and exposure. Edit them as the organization changes.")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(CrimeSystem.starterOperations + [.robbery, .extortion, .territoryAttack]) { operation in
                    Button("Save \(operation.title) plan") {
                        _ = simulator.execute(.domain(.saveCrimePlan(operation)))
                        organizationFeedback = "\(operation.title) plan saved with individual tasks assigned."
                    }
                }
                ForEach(path.plans) { plan in
                    let definition = CrimeOperationDefinition.definition(for: plan.operation)
                    let risk = simulator.crimePlanRisk(plan)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(plan.operation.title)
                        Text("\(plan.approach.title) · Risk \(risk.total)% · Prep \(plan.preparation)/20 · Mastery \(plan.mastery)")
                                .font(.caption).foregroundStyle(risk.total >= 65 ? .red : .secondary)
                            Text("Best: \(definition.preferredApproaches.map(\.title).joined(separator: ", ")) · \(definition.detail)")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Menu("Approach") {
                            ForEach(CrimeApproach.allCases) { approach in
                                Button("\(approach.title) (risk \(approach.riskAdjustment >= 0 ? "+" : "")\(approach.riskAdjustment))") {
                                    _ = simulator.execute(.domain(.setCrimePlanApproach(plan.id, approach)))
                                }
                            }
                        }
                        Button("Prepare $\(250 + plan.preparation * 50)") {
                            if let outcome = simulator.execute(.domain(.prepareCrimePlan(plan.id))) {
                                organizationFeedback = "\(outcome.headline). \(outcome.narrative)"
                            }
                        }
                        .disabled(plan.preparation >= 20 || state.cash < 250 + plan.preparation * 50)
                        Menu("Kit") {
                            Button("No custom kit") { _ = simulator.execute(.domain(.assignCriminalKit(plan.id, nil))) }
                            ForEach(path.customKits) { kit in
                                Button(kit.name) { _ = simulator.execute(.domain(.assignCriminalKit(plan.id, kit.id))) }
                            }
                        }
                        Button("Execute") {
                            if let outcome = simulator.execute(.domain(.executeCrimePlan(plan.id))) {
                                organizationFeedback = "\(outcome.headline). \(outcome.narrative)"
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            Section("Specialists") {
                ForEach(path.specialists) { specialist in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(specialist.name)
                            Spacer()
                            Text(specialist.role.title)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Text("Competence \(specialist.knownFacts.contains("competence") ? String(specialist.competence) : "Unknown") · Loyalty \(specialist.knownFacts.contains("loyalty") ? String(specialist.loyalty) : "Unknown") · Relationship \(specialist.relationship)")
                            .font(.caption).foregroundStyle(.secondary)
                        if !specialist.knownFacts.isEmpty {
                            Text("Known: \(specialist.knownFacts.sorted().joined(separator: ", "))")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        HStack {
                            Button("Build relationship") {
                                if let outcome = simulator.execute(.domain(.buildSpecialistRelationship(specialist.id))) {
                                    organizationFeedback = "\(outcome.headline). \(outcome.narrative)"
                                }
                            }
                            Button("Reward $500") {
                                if let outcome = simulator.execute(.domain(.rewardSpecialist(specialist.id))) {
                                    organizationFeedback = "\(outcome.headline). \(outcome.narrative)"
                                }
                            }
                            .disabled(state.cash < 500)
                        }
                        Menu("Delegate work to \(specialist.name)") {
                            ForEach(CrimeSystem.starterOperations + [.robbery]) { operation in
                                Button(operation.title) {
                                    if let outcome = simulator.execute(.domain(.delegateCrime(specialist.id, operation))) {
                                        organizationFeedback = "\(outcome.headline). \(outcome.narrative)"
                                    }
                                }
                            }
                        }
                        .disabled(!specialist.isAvailable)
                    }
                }
            }
            if !path.rivals.isEmpty {
                Section("Rivals and territory") {
                    LabeledContent("Territory", value: "\(path.territory)")
                    ForEach(path.rivals) { rival in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(rival.name)
                                Spacer()
                                Text("Strength \(rival.strength)").font(.caption).foregroundStyle(.secondary)
                            }
                            Text("Relationship \(rival.relationship) · Hatred \(rival.hatred) · Territory \(rival.territory)")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Button("Negotiate") { _ = simulator.execute(.domain(.negotiateRival(rival.id))) }
                                Button("Attack", role: .destructive) { _ = simulator.execute(.domain(.attackRival(rival.id))) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            Section("Infrastructure") {
                LabeledContent("Equipment", value: "\(path.equipment.effectiveness)% effective")
                LabeledContent("Equipment condition", value: "\(path.equipment.condition)%")
                LabeledContent("Safehouses", value: "\(path.safehouses.count)")
                LabeledContent("Front business", value: path.frontBusiness?.name ?? "None")
                Button("Invest $1,000 in equipment") {
                    simulator.execute(.domain(.investCriminalEquipment))
                }
                .disabled(state.cash < 1_000)
                Button(path.safehouses.isEmpty ? "Acquire safehouse" : "Add safehouse") {
                    simulator.execute(.domain(.acquireCriminalSafehouse))
                }
                if !path.safehouses.isEmpty {
                    Button("Upgrade latest safehouse ($750)") {
                        _ = simulator.execute(.domain(.upgradeCriminalSafehouse))
                    }
                    .disabled(state.cash < 750)
                }
                if path.frontBusiness == nil {
                    Button("Start optional front business") {
                        simulator.execute(.domain(.acquireCriminalFrontBusiness))
                    }
                }
            }
        } else if state.character.age >= 14 {
            Section("Criminal path") {
                Text("Solo crime can become a gang career. Joining is cheaper and gives you infrastructure; starting an organization takes more capital and notoriety but gives you control.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Join an existing gang") {
                    if let outcome = simulator.execute(.domain(.joinGang)) { organizationFeedback = outcome.narrative }
                }
                .disabled(state.cash < CrimeSystem.gangStartupCost || (state.career.criminalPath?.notoriety ?? 0) < 5)
                Button("Start an independent organization") {
                    if let outcome = simulator.execute(.domain(.startOrganization)) { organizationFeedback = outcome.narrative }
                }
                .disabled(state.character.age < 18 || state.cash < CrimeSystem.organizationStartupCost || (state.career.criminalPath?.notoriety ?? 0) < 20)
                if let organizationFeedback { Text(organizationFeedback).font(.caption) }
            }
        }
    }

    @ViewBuilder
    private var criminalKitSection: some View {
        let path = state.career.criminalPath ?? CriminalPathState()
        let eligible = state.assets.movableAssets.filter { $0.firearm != nil || $0.vehicle != nil }
        let stolen = path.stolenAssets
        Section("Custom operation kits") {
            Text("Personal and recovered items can support solo or gang plans. Personal ownership stays in Assets; recovered items remain criminal inventory.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Create personal kit") {
                _ = simulator.execute(.domain(.createCriminalKit("")))
            }
            Menu("Solo operation kit: \(path.customKits.first(where: { $0.id == path.soloKitID })?.name ?? "None")") {
                Button("No custom kit") { _ = simulator.execute(.domain(.setSoloCriminalKit(nil))) }
                ForEach(path.customKits) { kit in
                    Button(kit.name) { _ = simulator.execute(.domain(.setSoloCriminalKit(kit.id))) }
                }
            }
            ForEach(path.customKits) { kit in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(kit.name).font(.headline)
                        Spacer()
                        Text("\(kit.assetCount) items").font(.caption).foregroundStyle(.secondary)
                    }
                    Text(kit.personalAssetIDs.compactMap { id in state.assets.movableAssets.first(where: { $0.id == id })?.displayName }.joined(separator: ", ").isEmpty ? "No personal items assigned" : kit.personalAssetIDs.compactMap { id in state.assets.movableAssets.first(where: { $0.id == id })?.displayName }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    let stolenNames = kit.stolenAssetIDs.compactMap { id in stolen.first(where: { $0.id == id })?.name }.joined(separator: ", ")
                    if !stolenNames.isEmpty {
                        Text("Recovered: \(stolenNames)").font(.caption).foregroundStyle(.orange)
                    }
                    let readiness = simulator.crimePlanRisk(CrimePlan(id: "kit-preview-\(kit.id)", operation: .vehicleTheft, kitID: kit.id))
                    Text("Supplies $\(kit.purchasedEquipment) · Vehicle-theft risk \(readiness.total)%")
                        .font(.caption2).foregroundStyle(readiness.total >= 65 ? .red : .secondary)
                    HStack {
                        Button("Buy $1,000 supplies") { _ = simulator.execute(.domain(.purchaseKitEquipment(kit.id, 1_000))) }
                            .buttonStyle(.bordered)
                            .disabled(state.cash < 1_000)
                        Menu("Recover") {
                            ForEach(stolen.filter { kit.stolenAssetIDs.contains($0.id) }) { item in
                                Button("Fence \(item.name)") { _ = simulator.execute(.domain(.convertStolenAsset(item.id, .fence))) }
                                if path.isOrganization, path.frontBusiness != nil {
                                    Button("Front business: \(item.name)") { _ = simulator.execute(.domain(.convertStolenAsset(item.id, .frontBusiness))) }
                                }
                            }
                        }
                        .disabled(stolen.filter { kit.stolenAssetIDs.contains($0.id) }.isEmpty)
                    }
                    Button(kit.personalAssetIDs.count == eligible.count ? "Refresh personal items" : "Use eligible personal items") {
                        _ = simulator.execute(.domain(.setCriminalKitAssets(kit.id, eligible.map(\.id), stolen.map(\.id))))
                    }
                    .buttonStyle(.bordered)
                }
            }
            if !stolen.isEmpty {
                ForEach(stolen) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("$\(item.estimatedValue * item.condition / 100)").font(.caption).foregroundStyle(.secondary)
                        Button("Move value") { _ = simulator.execute(.domain(.recoverStolenAsset(item.id))) }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
}

private enum PendingAssetShopTransaction: Identifiable {
    case purchase(AssetListing)
    case upgrade(OwnedAsset, FirearmUpgradeDefinition)
    case saleAsset(OwnedAsset)
    case saleProperty(OwnedProperty)

    var id: String {
        switch self {
        case .purchase(let listing): "purchase-\(listing.id)"
        case .upgrade(let owned, let upgrade): "upgrade-\(owned.id)-\(upgrade.id.rawValue)"
        case .saleAsset(let owned): "sale-\(owned.id)"
        case .saleProperty(let owned): "sale-property-\(owned.id)"
        }
    }

    var title: String {
        switch self {
        case .purchase(let listing): "Buy \(listing.name)?"
        case .upgrade(_, let upgrade): "Add \(upgrade.name)?"
        case .saleAsset(let owned): "Sell \(owned.displayName)?"
        case .saleProperty(let owned): "Sell \(owned.name)?"
        }
    }

    var confirmationLabel: String {
        switch self {
        case .purchase: "Confirm purchase"
        case .upgrade: "Confirm upgrade"
        case .saleAsset, .saleProperty: "Confirm sale"
        }
    }

    var message: String {
        switch self {
        case .purchase(let listing):
            switch listing.terms {
            case .cash(let price): "Pay $\(price) now. Immediate resale would return $\(price * 65 / 100)."
            case .mortgage(let value, let down, let annual, _): "Pay $\(down) now for a $\(value) property, with a $\(value - down) mortgage. Annual mortgage payments $\(EconomyPolicy.monthlyMortgage(value - down) * 12), plus $\(annual) operating costs."
            }
        case .upgrade(_, let upgrade):
            upgrade.market == .illicit
                ? "Pay $\(upgrade.price). This prohibited modification adds \(upgrade.heat) heat."
                : "Pay $\(upgrade.price). This lawful accessory adds no heat."
        case .saleAsset(let owned):
            "The sale returns $\(owned.resaleValue)."
        case .saleProperty(let owned):
            "The improved value is $\(owned.currentValue). After the $\(owned.mortgageBalance) mortgage and $\(owned.closingCost) closing cost, the sale returns $\(owned.saleProceeds)."
        }
    }
}

private enum AssetShopSheet: Identifiable {
    case manageProperty(UInt64)
    case manageVehicle(UInt64)
    case manageFirearm(UInt64)
    case renameVehicle(UInt64)
    case gift(UInt64)
    case liquidation

    var id: String {
        switch self {
        case .manageProperty(let id): "manage-property-\(id)"
        case .manageVehicle(let id): "manage-vehicle-\(id)"
        case .manageFirearm(let id): "manage-firearm-\(id)"
        case .renameVehicle(let id): "rename-vehicle-\(id)"
        case .gift(let id): "gift-\(id)"
        case .liquidation: "liquidation"
        }
    }
}

private struct AssetShopView: View {
    @ObservedObject var simulator: LifeSimulator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var category: AssetCategory = .cars
    @State private var firearmMarket: FirearmMarket = .legal
    @State private var vehicleKind: VehicleKind = .car
    @State private var carGroup: CarCatalogGroup = .everyday
    @State private var pending: PendingAssetShopTransaction?
    @State private var presentedSheet: AssetShopSheet?
    @State private var transactionMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categorySelector
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.bar)

                List {
                Section("Portfolio") {
                    LabeledContent("Cash", value: "$\(simulator.state.cash)")
                    LabeledContent("Asset value", value: "$\(simulator.state.assets.totalValue)")
                    LabeledContent("Owned", value: "\(simulator.state.assets.ownedCount)")
                    LabeledContent("Resale value", value: "$\(simulator.state.assets.currentResaleValue)")
                    LabeledContent("Gifts made", value: "\(simulator.state.assets.movableAssetsGifted)")
                    LabeledContent("Assets lost", value: "\(simulator.state.assets.movableAssetsLost)")
                    LabeledContent("Notoriety", value: "\(simulator.state.assets.notoriety.score)")
                    if !simulator.state.assets.recoveryCases.isEmpty {
                        Section("Open recovery cases") {
                            ForEach(simulator.state.assets.recoveryCases) { recoveryCase in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(recoveryCase.assetName)
                                        Text("Evidence \(recoveryCase.evidence)% · estimated value $\(recoveryCase.estimatedValue)")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button("Investigate") { _ = simulator.execute(.domain(.investigateAssetLoss(recoveryCase.id))) }
                                        .buttonStyle(.bordered)
                                        .disabled(simulator.state.cash < max(250, recoveryCase.estimatedValue * 10 / 100))
                                }
                            }
                        }
                    }
                    LabeledContent("\(category.title) value", value: "$\(categoryValue)")
                    LabeledContent("Mortgage debt", value: "$\(simulator.state.assets.totalMortgageDebt)")
                    Button("Emergency liquidation") { presentedSheet = .liquidation }
                        .disabled(simulator.state.assets.movableAssets.isEmpty || simulator.state.pendingEvent != nil)
                    if category == .houses {
                        LabeledContent("Market value", value: "$\(simulator.state.assets.propertyMarketValue)")
                        LabeledContent("Rentals", value: "\(simulator.state.assets.occupiedRentalCount) occupied · \(simulator.state.assets.vacantRentalCount) vacant")
                        LabeledContent("Last rent", value: "$\(simulator.state.assets.lastRentalIncome)")
                    }
                    if category == .guns {
                        LabeledContent("Legal status", value: simulator.state.legal.record.rawValue.capitalized)
                        LabeledContent("Firearm heat", value: "\(simulator.state.legal.firearmHeat)")
                        if simulator.state.legal.isUnderSupervision {
                            LabeledContent("Supervision", value: "\(simulator.state.legal.supervisionYearsRemaining)y remaining")
                        }
                    }
                }

                if category == .guns {
                    Section("Firearm market") {
                        Picker("Market", selection: $firearmMarket) {
                            ForEach(FirearmMarket.allCases) { market in Text(market.title).tag(market) }
                        }
                        .pickerStyle(.segmented)
                        if firearmMarket == .illicit {
                            Text("Illegal purchases and prohibited upgrades create persistent heat, confiscation risk, and felony exposure.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                if category == .cars {
                    Section("Vehicle class") {
                        Menu {
                            ForEach(VehicleKind.allCases) { kind in
                                Button {
                                    vehicleKind = kind
                                } label: {
                                    Label(kind.title, systemImage: kind.symbol)
                                }
                            }
                        } label: {
                            LabeledContent("Vehicle class", value: vehicleKind.title)
                        }
                        .accessibilityIdentifier("Vehicle Class Menu")
                        if vehicleKind == .car {
                            if dynamicTypeSize.isAccessibilitySize {
                                Menu {
                                    ForEach(CarCatalogGroup.allCases) { group in
                                        Button(group.title) { carGroup = group }
                                            .accessibilityIdentifier("Car Group Choice \(group.title)")
                                    }
                                } label: {
                                    LabeledContent("Car group", value: carGroup.title)
                                }
                                .accessibilityIdentifier("Car Group Menu")
                            } else {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(CarCatalogGroup.allCases) { group in
                                        Button(group.title) { carGroup = group }
                                            .buttonStyle(.bordered)
                                            .tint(carGroup == group ? .accentColor : .secondary)
                                            .frame(maxWidth: .infinity)
                                            .accessibilityIdentifier("Car Group \(group.title)")
                                            .accessibilityAddTraits(carGroup == group ? .isSelected : [])
                                    }
                                }
                            }
                        }
                        Text("Phase 1 covers ownership and resale only. Operation, licensing, maintenance, and travel effects arrive in the depth pass.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Shop") {
                    ForEach(visibleListings) { listing in
                        shopRow(listing)
                    }
                }

                Section("Owned · \(ownedCount)") {
                    if category == .houses {
                        if simulator.state.assets.properties.isEmpty {
                            Text("No houses owned.").foregroundStyle(.secondary)
                        } else {
                            ForEach(simulator.state.assets.properties) { property in propertyRow(property) }
                        }
                    } else {
                        let owned = simulator.state.assets.movableAssets.filter {
                            $0.category == category && (category != .cars || $0.vehicle?.kind == vehicleKind)
                        }
                        if owned.isEmpty {
                            Text("Nothing owned in this category.").foregroundStyle(.secondary)
                        } else {
                            ForEach(owned) { item in assetRow(item) }
                        }
                    }
                }

                if category == .houses, !simulator.state.assets.propertyHistory.isEmpty {
                    Section("Property history") {
                        ForEach(simulator.state.assets.propertyHistory) { record in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(record.name).font(.headline)
                                Text("\(record.reason.reviewText.capitalized) at age \(record.exitAge) · cash returned $\(record.cashRecovered)")
                                    .font(.caption)
                                    .foregroundStyle(record.reason == .foreclosed ? .red : .secondary)
                            }
                        }
                    }
                }

                if let transactionMessage {
                    Section("Latest transaction") {
                        Text(transactionMessage).accessibilityIdentifier("Asset Transaction Feedback")
                    }
                }
                }
                .id("\(category.rawValue)-\(firearmMarket.rawValue)-\(vehicleKind.rawValue)")
            }
            .navigationTitle("Assets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .confirmationDialog(
                pending?.title ?? "Confirm transaction",
                isPresented: Binding(
                    get: { pending != nil },
                    set: { if !$0 { pending = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button(pending?.confirmationLabel ?? "Confirm") { commitPendingTransaction() }
                Button("Cancel", role: .cancel) { pending = nil }
            } message: {
                Text(pending?.message ?? "")
            }
            .sheet(item: $presentedSheet) { destination in
                switch destination {
                case .manageProperty(let propertyID):
                    PropertyManagerView(simulator: simulator, propertyID: propertyID)
                case .manageVehicle(let ownershipID):
                    VehicleManagerView(simulator: simulator, ownershipID: ownershipID)
                case .manageFirearm(let ownershipID):
                    FirearmManagerView(simulator: simulator, ownershipID: ownershipID)
                case .renameVehicle(let ownershipID):
                    VehicleRenameView(simulator: simulator, ownershipID: ownershipID)
                case .gift(let ownershipID):
                    GiftAssetView(simulator: simulator, ownershipID: ownershipID)
                case .liquidation:
                    AssetLiquidationView(simulator: simulator)
                }
            }
        }
    }

    @ViewBuilder
    private var categorySelector: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("Asset category", selection: $category) {
                ForEach(AssetCategory.allCases) { item in
                    Label(item.title, systemImage: item.symbol).tag(item)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("Asset Category Menu")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AssetCategory.allCases) { item in
                        Button {
                            category = item
                        } label: {
                            Label(item.title, systemImage: item.symbol)
                                .font(.subheadline.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(
                                    category == item ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.10),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("Asset Category \(item.title)")
                        .accessibilityAddTraits(category == item ? .isSelected : [])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func shopRow(_ listing: AssetListing) -> some View {
        let availability = simulator.assetAvailability(for: listing)
        VStack(alignment: .leading, spacing: 8) {
            Label(listing.name, systemImage: symbolName(for: listing)).font(.headline)
            Text(listing.detail).font(.caption).foregroundStyle(.secondary)
            if let firearm = listing.firearm {
                Text("\(firearm.rarity.rawValue.capitalized) · \(firearm.market.title)\(firearm.heat > 0 ? " · heat +\(firearm.heat)" : " · no heat")")
                    .font(.caption.bold())
                    .foregroundStyle(firearm.heat > 0 ? .orange : .secondary)
            }
            if let property = listing.property {
                Text("\(property.tier.rawValue.capitalized) \(property.type.rawValue.capitalized)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            if let vehicle = listing.vehicle {
                Text(vehicle.bodyStyle.map { "\(vehicle.carGroup?.title ?? vehicle.kind.title) · \($0.title)" } ?? vehicle.kind.title)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            Text(termsText(listing.terms)).font(.subheadline)
            if listing.category == .guns {
                Text("Ownership only · secure storage required")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if case .locked(let reason) = availability {
                Text(reason).font(.caption.bold()).foregroundStyle(.red)
            }
            Button("Buy") { pending = .purchase(listing) }
                .buttonStyle(.borderedProminent)
                .disabled(availability != .available)
                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, alignment: .leading)
                .accessibilityIdentifier("Buy \(listing.name)")
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func assetRow(_ owned: OwnedAsset) -> some View {
        let committedToKit = AssetSystem.committedCriminalAssetIDs(state: simulator.state).contains(owned.id)
        VStack(alignment: .leading, spacing: 7) {
            Label(owned.displayName, systemImage: symbolName(for: owned)).font(.headline)
            if owned.vehicle?.customName != nil {
                Text("Originally \(owned.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Bought age \(owned.purchaseAge) · paid $\(owned.purchasePrice)").font(.caption).foregroundStyle(.secondary)
            if let firearm = owned.firearm {
                Text("\(firearm.rarity.rawValue.capitalized) · \(firearm.market.title) · exposure \(firearm.totalHeat + firearm.storageRisk + firearm.conditionRisk)")
                    .font(.caption.bold())
                    .foregroundStyle(firearm.totalHeat + firearm.storageRisk + firearm.conditionRisk > 0 ? Color.orange : Color.secondary)
                Text("Condition \(firearm.condition)% · \(firearm.secureStorage ? "secure storage" : "unsecured storage")")
                    .font(.caption2)
                    .foregroundStyle(firearm.secureStorage ? Color.secondary : Color.orange)
                Button("Manage Firearm") { presentedSheet = .manageFirearm(owned.id) }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("Manage Firearm \(owned.id)")
                if !firearm.upgrades.isEmpty {
                    Text("Upgrades: \(firearm.upgrades.map { FirearmUpgradeCatalog.definition(for: $0).name }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(FirearmUpgradeCatalog.all.filter { !firearm.upgrades.contains($0.id) }) { upgrade in
                    let availability = simulator.firearmUpgradeAvailability(upgrade, ownershipID: owned.id)
                    VStack(alignment: .leading, spacing: 3) {
                        Button("Add \(upgrade.name) · $\(upgrade.price)") { pending = .upgrade(owned, upgrade) }
                            .buttonStyle(.bordered)
                            .disabled(availability != .available)
                            .accessibilityIdentifier("Upgrade \(owned.id) \(upgrade.id.rawValue)")
                        if case .locked(let reason) = availability {
                            Text(reason).font(.caption2).foregroundStyle(.red)
                        }
                    }
                }
            }
            if let vehicle = owned.vehicle {
                Text(vehicle.kind.singularTitle)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("Condition \(vehicle.condition)% · value $\(vehicle.currentValue) · reliability \(vehicle.reliability)%")
                    .font(.caption2)
                    .foregroundStyle(vehicle.repairState == .healthy ? Color.secondary : Color.orange)
                if vehicle.repairState == .needsRepair {
                    Text("Breakdown repair needed").font(.caption.bold()).foregroundStyle(.orange)
                } else if vehicle.repairState == .totaled {
                    Text("Totaled").font(.caption.bold()).foregroundStyle(.red)
                }
                Button("Manage Vehicle") { presentedSheet = .manageVehicle(owned.id) }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("Manage Vehicle \(owned.id)")
                Button("Rename") { presentedSheet = .renameVehicle(owned.id) }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("Rename Vehicle \(owned.id)")
            }
            if let jewelry = owned.jewelry {
                Text("Market value $\(jewelry.marketValue) · condition \(jewelry.condition)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Sale value $\(owned.resaleValue)").font(.subheadline.bold()).foregroundStyle(.green)
            if committedToKit {
                Text("Committed to an active criminal kit").font(.caption.bold()).foregroundStyle(.orange)
            }
            Button("Gift") { presentedSheet = .gift(owned.id) }
                .buttonStyle(.bordered)
                .disabled(committedToKit || simulator.state.finance.economy.workoutYearsRemaining > 0 || simulator.state.partner == nil && simulator.state.family.contacts.isEmpty && simulator.state.npcs.all.isEmpty)
            Button("Sell") { pending = .saleAsset(owned) }
                .buttonStyle(.bordered)
                .disabled(committedToKit)
                .accessibilityIdentifier("Sell \(owned.displayName) \(owned.id)")
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private func propertyRow(_ owned: OwnedProperty) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(owned.name).font(.headline)
                Text(owned.use.title).font(.caption.bold()).foregroundStyle(.secondary)
            }
            if let type = owned.propertyType, let tier = owned.propertyTier {
                Text("\(tier.rawValue.capitalized) \(type.rawValue.capitalized)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            Text("Value $\(owned.currentValue) · equity $\(owned.equity) · mortgage $\(owned.mortgageBalance)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("$\(owned.totalAnnualCost)/yr · \(owned.amenities.count) amenit\(owned.amenities.count == 1 ? "y" : "ies")")
                .font(.caption)
                .foregroundStyle(.secondary)
            if owned.improvementValue > 0 {
                Text("Improvement value +$\(owned.improvementValue) · upkeep $\(owned.amenityUpkeep)/yr")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
            if owned.delinquentYears >= 2 {
                Text("Mortgage delinquent").font(.caption.bold()).foregroundStyle(.red)
            }
            Text("Condition \(owned.condition)% · \(owned.conditionBand.title)")
                .font(.caption.bold())
                .foregroundStyle(owned.condition < 40 ? Color.red : Color.secondary)
            if owned.use == .rental {
                Text("Expected rent $\(owned.expectedMarketRent)/yr · \(owned.rental?.tenant?.name ?? "searching")")
                    .font(.caption)
                    .foregroundStyle(owned.rental?.tenant == nil ? Color.secondary : Color.green)
            }
            Button("Manage Property") { presentedSheet = .manageProperty(owned.id) }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("Manage Property \(owned.id)")
            Text("Sale proceeds $\(owned.saleProceeds)").font(.subheadline.bold()).foregroundStyle(.green)
            Button("Sell") { pending = .saleProperty(owned) }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("Sell \(owned.name) \(owned.id)")
        }
        .padding(.vertical, 3)
    }

    private func termsText(_ terms: AssetPurchaseTerms) -> String {
        switch terms {
        case .cash(let price): "$\(price) cash · sells for $\(price * 65 / 100)"
        case .mortgage(let value, let down, let annual, _): "$\(value) value · $\(down) down · $\(annual)/yr"
        }
    }

    private var categoryValue: Int {
        if category == .houses { return simulator.state.assets.propertyEquity }
        if category == .cars { return simulator.state.assets.vehicleValue(of: vehicleKind) }
        return simulator.state.assets.movableAssets
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.resaleValue }
    }

    private var visibleListings: [AssetListing] {
        if category == .guns { return AssetCatalog.firearmListings(in: firearmMarket) }
        if category == .cars {
            return vehicleKind == .car
                ? AssetCatalog.carListings(in: carGroup)
                : AssetCatalog.vehicleListings(of: vehicleKind)
        }
        return AssetCatalog.listings(in: category)
    }

    private func symbolName(for listing: AssetListing) -> String {
        let candidate = listing.vehicle?.symbolName ?? listing.category.symbol
        return UIImage(systemName: candidate) == nil ? "car.fill" : candidate
    }

    private func symbolName(for owned: OwnedAsset) -> String {
        let candidate = AssetCatalog.listing(for: owned.listingID)?.vehicle?.symbolName
            ?? owned.vehicle?.kind.symbol
            ?? owned.category.symbol
        return UIImage(systemName: candidate) == nil ? "car.fill" : candidate
    }

    private var ownedCount: Int {
        category == .cars
            ? simulator.state.assets.vehicleCount(of: vehicleKind)
            : simulator.state.assets.count(in: category)
    }

    private func commitPendingTransaction() {
        guard let pending else { return }
        let outcome: ActionOutcome?
        let major: Bool
        switch pending {
        case .purchase(let listing):
            outcome = simulator.execute(.domain(.purchaseAsset(listing.id)))
            major = listing.category == .houses
        case .upgrade(let owned, let upgrade):
            outcome = simulator.execute(.domain(.upgradeFirearm(owned.id, upgrade.id)))
            major = upgrade.heat >= 10
        case .saleAsset(let owned):
            outcome = simulator.execute(.domain(.sellAsset(owned.id)))
            major = false
        case .saleProperty(let owned):
            outcome = simulator.execute(.domain(.sellAsset(owned.id)))
            major = true
        }
        transactionMessage = outcome.map { "\($0.headline). \($0.narrative)" }
        UIImpactFeedbackGenerator(style: major ? .medium : .light).impactOccurred()
        self.pending = nil
    }
}

private struct GiftAssetView: View {
    @ObservedObject var simulator: LifeSimulator
    let ownershipID: UInt64
    @Environment(\.dismiss) private var dismiss
    @State private var pendingRecipient: AssetGiftRecipient?

    private var recipients: [(AssetGiftRecipient, String)] {
        var result: [(AssetGiftRecipient, String)] = []
        if let partner = simulator.state.partner { result.append((.partner, "Partner · \(partner.name)")) }
        result += simulator.state.family.contacts.map { (.family(contactID: $0.id), "Family · \($0.name)") }
        result += simulator.state.npcs.all.map { (.cast(memberID: $0.memberID), "\($0.name) · \($0.role.title)") }
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Give this asset") {
                    Text(simulator.state.assets.movableAssets.first(where: { $0.id == ownershipID })?.displayName ?? "Asset unavailable")
                        .font(.headline)
                    Text("The asset leaves your portfolio. The recipient relationship improves based on its current resale value.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Recipient") {
                    ForEach(recipients, id: \.0.id) { recipient, label in
                        Button(label) {
                            pendingRecipient = recipient
                        }
                    }
                }
            }
            .navigationTitle("Gift Asset")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .confirmationDialog(
                "Confirm gift",
                isPresented: Binding(get: { pendingRecipient != nil }, set: { if !$0 { pendingRecipient = nil } }),
                titleVisibility: .visible
            ) {
                Button("Confirm gift") {
                    if let recipient = pendingRecipient {
                        _ = simulator.execute(.domain(.giftAsset(ownershipID, recipient)))
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) { pendingRecipient = nil }
            } message: {
                if let recipient = pendingRecipient,
                   let preview = AssetSystem.giftPreview(ownershipID: ownershipID, recipient: recipient, state: simulator.state) {
                    Text("Give \(preview.assetName) (resale $\(preview.resaleValue)) to \(preview.recipientName). Bond/rapport +\(preview.relationshipDelta); future support $\(preview.reciprocityValue). The asset leaves your portfolio and the gift is cash-neutral.")
                }
            }
        }
    }
}

private struct AssetLiquidationView: View {
    @ObservedObject var simulator: LifeSimulator
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIDs: Set<UInt64> = []

    private var assets: [OwnedAsset] { AssetSystem.selectableLiquidationAssets(state: simulator.state) }
    private var proceeds: Int { assets.filter { selectedIDs.contains($0.id) }.reduce(0) { $0 + $1.resaleValue } }

    var body: some View {
        NavigationStack {
            List {
                Section("Select movable assets") {
                    ForEach(assets) { asset in
                        Button {
                            if selectedIDs.contains(asset.id) { selectedIDs.remove(asset.id) } else { selectedIDs.insert(asset.id) }
                        } label: {
                            HStack {
                                Image(systemName: selectedIDs.contains(asset.id) ? "checkmark.circle.fill" : "circle")
                                VStack(alignment: .leading) {
                                    Text(asset.displayName)
                                    Text("Resale $\(asset.resaleValue)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                Section("Release cash") {
                    LabeledContent("Selected proceeds", value: "$\(proceeds)")
                    Button("Sell selected assets") {
                        _ = simulator.execute(.domain(.liquidateAssets(Array(selectedIDs))))
                        dismiss()
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
            .navigationTitle("Emergency Liquidation")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

private struct FirearmManagerView: View {
    @ObservedObject var simulator: LifeSimulator
    let ownershipID: UInt64
    @Environment(\.dismiss) private var dismiss
    @State private var feedback: String?

    private var owned: OwnedAsset? {
        simulator.state.assets.movableAssets.first(where: { $0.id == ownershipID && $0.firearm != nil })
    }

    var body: some View {
        NavigationStack {
            List {
                if let firearm = owned?.firearm {
                    Section("Firearm") {
                        LabeledContent("Market", value: firearm.market.title)
                        LabeledContent("Rarity", value: firearm.rarity.rawValue.capitalized)
                        LabeledContent("Condition", value: "\(firearm.condition)%")
                        LabeledContent("Legal exposure", value: "\(firearm.totalHeat + firearm.storageRisk + firearm.conditionRisk)")
                        LabeledContent("Storage", value: firearm.secureStorage ? "Secure" : "Unsecured")
                        Text("Ownership effects are limited to legal exposure and storage status; no operational use is simulated.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Section("Management") {
                        ForEach(FirearmManagementAction.allCases) { action in
                            let availability = simulator.firearmManagementAvailability(action, ownershipID: ownershipID)
                            Button {
                                if let outcome = simulator.execute(.domain(.manageFirearm(ownershipID, action))) {
                                    feedback = "\(outcome.headline). \(outcome.narrative)"
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(action.title) · $\(action.price)")
                                    if case .locked(let reason) = availability {
                                        Text(reason).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .disabled(availability != .available)
                        }
                    }
                    if let feedback {
                        Section("Latest") { Text(feedback) }
                    }
                } else {
                    ContentUnavailableView("Firearm unavailable", systemImage: "scope")
                }
            }
            .navigationTitle(owned?.displayName ?? "Firearm")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

private struct VehicleManagerView: View {
    @ObservedObject var simulator: LifeSimulator
    let ownershipID: UInt64
    @Environment(\.dismiss) private var dismiss
    @State private var feedback: String?

    private var owned: OwnedAsset? {
        simulator.state.assets.movableAssets.first(where: { $0.id == ownershipID && $0.vehicle != nil })
    }

    var body: some View {
        NavigationStack {
            List {
                if let owned, let vehicle = owned.vehicle {
                    Section("Vehicle") {
                        LabeledContent("Type", value: vehicle.kind.singularTitle)
                        LabeledContent("Age", value: "\(max(0, simulator.state.character.age - owned.purchaseAge)) years")
                        LabeledContent("Condition", value: "\(vehicle.condition)%")
                        LabeledContent("Reliability", value: "\(vehicle.reliability)%")
                        LabeledContent("Current value", value: "$\(vehicle.currentValue)")
                        LabeledContent("Estimated resale", value: "$\(owned.resaleValue)")
                        if vehicle.repairState == .needsRepair {
                            Text("This vehicle needs a breakdown repair.").foregroundStyle(.orange)
                        }
                        if !vehicle.upgrades.isEmpty {
                            Text("Modifications: \(vehicle.upgrades.map { VehicleUpgradeCatalog.definition(for: $0).name }.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            LabeledContent("Performance", value: "+\(vehicle.performance)")
                            LabeledContent("Protection", value: "+\(vehicle.protection)")
                        }
                    }

                    Section("Management") {
                        ForEach(VehicleMaintenanceKind.allCases) { kind in
                            let availability = simulator.vehicleMaintenanceAvailability(kind, ownershipID: ownershipID)
                            Button {
                                if let outcome = simulator.execute(.domain(.maintainVehicle(ownershipID, kind))) {
                                    feedback = "\(outcome.headline). \(outcome.narrative)"
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(kind.title) · $\(AssetSystem.maintenanceCost(kind, vehicle: vehicle))")
                                    if case .locked(let reason) = availability {
                                        Text(reason).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .disabled(availability != .available)
                        }
                    }
                    Section("Vehicle modifications") {
                        ForEach(VehicleUpgradeCatalog.all) { upgrade in
                            let availability = simulator.vehicleUpgradeAvailability(upgrade, ownershipID: ownershipID)
                            Button {
                                _ = simulator.execute(.domain(.upgradeVehicle(ownershipID, upgrade.id)))
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(upgrade.name) · $\(upgrade.price)")
                                    Text("Performance +\(upgrade.performance) · protection +\(upgrade.protection)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if case .locked(let reason) = availability {
                                        Text(reason).font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .disabled(availability != .available)
                        }
                    }
                    Section("Replacement") {
                        if simulator.state.assets.vehicleReplacementBudget > 0 {
                            let replacement = simulator.state.assets.vehicleReplacementBudget
                            Text("Replacement budget available: $\(replacement). Visit the vehicle shop to replace the totaled vehicle.")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    if let feedback {
                        Section("Latest") { Text(feedback) }
                    }
                } else {
                    ContentUnavailableView("Vehicle unavailable", systemImage: "car.slash")
                }
            }
            .navigationTitle(owned?.displayName ?? "Vehicle")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

private struct VehicleRenameView: View {
    @ObservedObject var simulator: LifeSimulator
    let ownershipID: UInt64
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var draft: String
    @State private var errorMessage: String?

    init(simulator: LifeSimulator, ownershipID: UInt64) {
        self.simulator = simulator
        self.ownershipID = ownershipID
        let currentName = simulator.state.assets.movableAssets
            .first(where: { $0.id == ownershipID })?
            .vehicle?.customName ?? ""
        _draft = State(initialValue: currentName)
    }

    private var owned: OwnedAsset? {
        simulator.state.assets.movableAssets.first(where: { $0.id == ownershipID && $0.vehicle != nil })
    }

    private var validationMessage: String? {
        if case .invalid(let message) = PlayerAssignedNamePolicy.validate(draft) { return message }
        return nil
    }

    private var symbolName: String {
        let candidate = owned.flatMap { AssetCatalog.listing(for: $0.listingID)?.vehicle?.symbolName }
            ?? owned?.vehicle?.kind.symbol
            ?? "car.fill"
        return UIImage(systemName: candidate) == nil ? "car.fill" : candidate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    Label(owned?.name ?? "Vehicle unavailable", systemImage: symbolName)
                    if let customName = owned?.vehicle?.customName {
                        LabeledContent("Current name", value: customName)
                    }
                }

                Section("Custom name") {
                    TextField("Vehicle name", text: $draft)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("Vehicle Name Field")
                    HStack {
                        Text("Private and stored only with this life.")
                        Spacer()
                        Text("\(draft.count)/\(PlayerAssignedNamePolicy.maximumLength)")
                            .foregroundStyle(draft.count > PlayerAssignedNamePolicy.maximumLength ? .red : .secondary)
                    }
                    .font(.caption)
                    if let message = errorMessage ?? validationMessage {
                        Text(message).font(.caption.bold()).foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Reset to Default") { reset() }
                        .foregroundStyle(.red)
                        .disabled(owned?.vehicle?.customName == nil)
                        .accessibilityIdentifier("Reset Vehicle Name")
                }
            }
            .navigationTitle("Rename Vehicle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(owned == nil || validationMessage != nil)
                        .accessibilityIdentifier("Save Vehicle Name")
                }
            }
        }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
    }

    private func save() {
        if simulator.execute(.domain(.renameVehicle(ownershipID, draft))) != nil {
            dismiss()
        } else {
            errorMessage = "That vehicle could not be renamed."
        }
    }

    private func reset() {
        guard simulator.execute(.domain(.clearVehicleName(ownershipID))) != nil else {
            errorMessage = "That vehicle is no longer owned."
            return
        }
        dismiss()
    }
}

private enum PendingPropertyManagement: Identifiable {
    case list(RentalStrategy), change(RentalStrategy), withdraw, repair(PropertyRepairKind)

    var id: String {
        switch self {
        case .list(let strategy): "list-\(strategy.rawValue)"
        case .change(let strategy): "change-\(strategy.rawValue)"
        case .withdraw: "withdraw"
        case .repair(let kind): "repair-\(kind.rawValue)"
        }
    }
}

private struct PropertyManagerView: View {
    @ObservedObject var simulator: LifeSimulator
    let propertyID: UInt64
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedStrategy = RentalStrategy.market
    @State private var pending: PendingPropertyManagement?
    @State private var feedback: String?

    private var property: OwnedProperty? {
        simulator.state.assets.properties.first(where: { $0.id == propertyID })
    }

    var body: some View {
        NavigationStack {
            List {
                if let property {
                    Section("Glance") {
                        LabeledContent("Use", value: property.use.title)
                        LabeledContent("Annual mortgage payment", value: MoneyText.exact(property.mortgageMonthlyPayment * 12))
                        LabeledContent("Operating arrears", value: MoneyText.exact(property.operatingArrears))
                        if property.use == .rental {
                            LabeledContent("Expected rent after costs", value: MoneyText.exact(property.expectedMarketRent - property.totalAnnualCost - property.mortgageMonthlyPayment * 12))
                            LabeledContent("Restricted deposit", value: MoneyText.exact(property.rental?.restrictedDeposit ?? 0))
                        }
                        LabeledContent("Condition", value: "\(property.condition)% · \(property.conditionBand.title)")
                            .foregroundStyle(property.condition < 40 ? Color.red : Color.primary)
                        LabeledContent("Current value", value: "$\(property.currentValue)")
                            .foregroundStyle(.green)
                        LabeledContent("Equity", value: "$\(property.equity)")
                        LabeledContent("Mortgage", value: "$\(property.mortgageBalance)")
                        LabeledContent("Yearly cost", value: "$\(property.totalAnnualCost)")
                    }

                    Section("Rental") {
                        if property.isPrimaryResidence {
                            Text("The primary residence cannot be listed. Buy another property to build a rental portfolio.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if property.use == .vacant {
                            Picker("Rent strategy", selection: $selectedStrategy) {
                                ForEach(RentalStrategy.allCases) { strategy in Text(strategy.title).tag(strategy) }
                            }
                            .pickerStyle(.segmented)
                            LabeledContent("Projected rent", value: "$\(projectedRent(property, strategy: selectedStrategy))/yr")
                            Button("List for Rent") { pending = .list(selectedStrategy) }
                                .buttonStyle(.borderedProminent)
                                .disabled(simulator.rentalAvailability(propertyID: propertyID) != .available)
                                .accessibilityIdentifier("List Property for Rent")
                        } else if let rental = property.rental {
                            LabeledContent("Strategy", value: rental.strategy.title)
                            LabeledContent("Expected rent", value: "$\(property.expectedMarketRent)/yr")
                                .foregroundStyle(.green)
                            if let tenant = rental.tenant {
                                tenantDetails(tenant)
                            } else {
                                LabeledContent("Status", value: "Searching · \(rental.vacancyYears)y vacant")
                                    .foregroundStyle(.secondary)
                            }
                            if dynamicTypeSize.isAccessibilitySize {
                                Picker("New strategy", selection: $selectedStrategy) {
                                    ForEach(RentalStrategy.allCases) { strategy in Text(strategy.title).tag(strategy) }
                                }
                                .pickerStyle(.menu)
                            } else {
                                Picker("New strategy", selection: $selectedStrategy) {
                                    ForEach(RentalStrategy.allCases) { strategy in Text(strategy.title).tag(strategy) }
                                }
                                .pickerStyle(.segmented)
                            }
                            Button("Change Strategy") { pending = .change(selectedStrategy) }
                                .buttonStyle(.bordered)
                                .disabled(property.lastRentStrategyAge == simulator.state.character.age || selectedStrategy == rental.strategy)
                                .accessibilityIdentifier("Change Rental Strategy")
                            if rental.tenant == nil {
                                Button("Withdraw Listing") { pending = .withdraw }
                                    .buttonStyle(.bordered)
                                    .accessibilityIdentifier("Withdraw Rental Listing")
                            }
                        }
                    }

                    Section("Repairs") {
                        ForEach(PropertyRepairKind.allCases) { kind in
                            let availability = simulator.propertyRepairAvailability(kind, propertyID: propertyID)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(kind.title).font(.headline)
                                Text("$\(AssetSystem.repairCost(kind, property: property)) · condition +\(kind.conditionGain)")
                                    .font(.caption)
                                if case .locked(let reason) = availability {
                                    Text(reason).font(.caption2).foregroundStyle(.red)
                                }
                                Button("Start \(kind.title)") { pending = .repair(kind) }
                                    .buttonStyle(.bordered)
                                    .disabled(availability != .available)
                                    .accessibilityIdentifier("Repair Property \(kind.rawValue)")
                            }
                        }
                    }

                    Section("Upgrades") {
                        NavigationLink("Manage Amenities") {
                            PropertyAmenityView(simulator: simulator, propertyID: propertyID)
                        }
                        .accessibilityIdentifier("Manage Amenities \(propertyID)")
                    }

                    if let feedback {
                        Section("Latest") { Text(feedback).accessibilityIdentifier("Property Management Feedback") }
                    }
                } else {
                    ContentUnavailableView("Property unavailable", systemImage: "house.slash")
                }
            }
            .navigationTitle(property?.name ?? "Property")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .onAppear { selectedStrategy = property?.rental?.strategy ?? .market }
            .confirmationDialog(
                "Confirm property decision",
                isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }),
                titleVisibility: .visible
            ) {
                Button("Confirm") { commit() }
                Button("Cancel", role: .cancel) { pending = nil }
            } message: {
                Text(confirmationMessage)
            }
        }
    }

    private func projectedRent(_ property: OwnedProperty, strategy: RentalStrategy) -> Int {
        AssetSystem.projectedAnnualRent(for: property, strategy: strategy)
    }

    @ViewBuilder
    private func tenantDetails(_ tenant: RentalTenantProfile) -> some View {
        LabeledContent("Tenant", value: tenant.name)
        LabeledContent("Household", value: tenant.householdType.title)
        LabeledContent("Reliability", value: String(tenant.reliability))
        LabeledContent("Property care", value: String(tenant.care))
        LabeledContent("Lease", value: "\(tenant.leaseYearsRemaining)y")
    }

    private var confirmationMessage: String {
        guard let pending, let property else { return "" }
        return switch pending {
        case .list(let strategy): "List at about $\(projectedRent(property, strategy: strategy)) per year using the \(strategy.title.lowercased()) strategy."
        case .change(let strategy): "Change future rent and tenant odds to the \(strategy.title.lowercased()) strategy."
        case .withdraw: "Stop searching for a tenant and leave the property vacant."
        case .repair(let kind): "Pay $\(AssetSystem.repairCost(kind, property: property)) for +\(kind.conditionGain) condition."
        }
    }

    private func commit() {
        guard let pending else { return }
        let outcome: ActionOutcome? = switch pending {
        case .list(let strategy): simulator.execute(.domain(.rentProperty(propertyID, strategy)))
        case .change(let strategy): simulator.execute(.domain(.changeRentalStrategy(propertyID, strategy)))
        case .withdraw: simulator.execute(.domain(.withdrawRental(propertyID)))
        case .repair(let kind): simulator.execute(.domain(.repairProperty(propertyID, kind)))
        }
        feedback = outcome.map { "\($0.headline). \($0.narrative)" } ?? "The property decision could not be completed."
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        self.pending = nil
    }
}

private struct PropertyAmenityView: View {
    @ObservedObject var simulator: LifeSimulator
    let propertyID: UInt64
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var pendingAmenity: PropertyAmenityDefinition?
    @State private var transactionMessage: String?

    private var property: OwnedProperty? {
        simulator.state.assets.properties.first(where: { $0.id == propertyID })
    }

    var body: some View {
        List {
                if let property {
                    Section("Property") {
                        LabeledContent("Cash", value: "$\(simulator.state.cash)")
                        LabeledContent("Tier", value: (property.propertyTier ?? .standard).rawValue.capitalized)
                        LabeledContent("Current value", value: "$\(property.currentValue)")
                        LabeledContent("Improvement value", value: "+$\(property.improvementValue)")
                            .foregroundStyle(property.improvementValue > 0 ? .green : .secondary)
                            .accessibilityIdentifier("Property Amenity Improvement Value")
                        LabeledContent("Total yearly cost", value: "$\(property.totalAnnualCost)")
                        LabeledContent("Amenity upkeep", value: "$\(property.amenityUpkeep)")
                            .accessibilityIdentifier("Property Amenity Upkeep")
                    }

                    Section("Installed · \(property.amenities.count)") {
                        if property.amenities.isEmpty {
                            Text("No amenities installed.").foregroundStyle(.secondary)
                        } else {
                            ForEach(property.amenities) { installed in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(PropertyAmenityCatalog.definition(for: installed.amenityID)?.name ?? installed.amenityID.rawValue)
                                        .font(.headline)
                                    Text("Installed age \(installed.installedAge) · value +$\(installed.valueContribution) · $\(installed.annualUpkeep)/yr")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section("Available upgrades") {
                        ForEach(PropertyAmenityCatalog.all) { amenity in
                            amenityRow(amenity)
                        }
                    }

                    if let transactionMessage {
                        Section("Latest upgrade") {
                            Text(transactionMessage)
                                .accessibilityIdentifier("Property Amenity Feedback")
                        }
                    }
                } else {
                    ContentUnavailableView("Property unavailable", systemImage: "house.slash")
                }
            }
            .navigationTitle("Amenities")
            .confirmationDialog(
                pendingAmenity.map { "Add \($0.name)?" } ?? "Confirm upgrade",
                isPresented: Binding(
                    get: { pendingAmenity != nil },
                    set: { if !$0 { pendingAmenity = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Confirm amenity") { installPendingAmenity() }
                Button("Cancel", role: .cancel) { pendingAmenity = nil }
            } message: {
                if let amenity = pendingAmenity {
                    Text("Pay $\(amenity.installationPrice) now. Property value rises $\(amenity.valueContribution), with $\(amenity.annualUpkeep) in yearly upkeep.")
                }
            }
    }

    @ViewBuilder
    private func amenityRow(_ amenity: PropertyAmenityDefinition) -> some View {
        let availability = simulator.propertyAmenityAvailability(amenity, propertyID: propertyID)
        VStack(alignment: .leading, spacing: 7) {
            Label(amenity.name, systemImage: amenitySymbol(amenity.id)).font(.headline)
            Text(amenity.detail).font(.caption).foregroundStyle(.secondary)
            Text("\(amenity.minimumTier.rawValue.capitalized) tier · $\(amenity.installationPrice) cash")
                .font(.caption.bold())
            Text("Value +$\(amenity.valueContribution) · upkeep $\(amenity.annualUpkeep)/yr")
                .font(.caption)
                .foregroundStyle(.green)
            if case .locked(let reason) = availability {
                Text(reason).font(.caption.bold()).foregroundStyle(.red)
            }
            Button("Install \(amenity.name)") { pendingAmenity = amenity }
                .buttonStyle(.borderedProminent)
                .disabled(availability != .available)
                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, alignment: .leading)
                .accessibilityIdentifier("Install \(amenity.id.rawValue)")
        }
        .padding(.vertical, 3)
    }

    private func installPendingAmenity() {
        guard let amenity = pendingAmenity else { return }
        let outcome = simulator.execute(.domain(.installAmenity(propertyID, amenity.id)))
        transactionMessage = outcome.map { "\($0.headline). \($0.narrative)" }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        pendingAmenity = nil
    }

    private func amenitySymbol(_ id: PropertyAmenityID) -> String {
        switch id {
        case .homeGym: "dumbbell.fill"
        case .basketballCourt: "basketball.fill"
        case .sauna: "humidity.fill"
        case .hotTub: "drop.fill"
        case .swimmingPool: "figure.pool.swim"
        case .tennisCourt: "tennis.racket"
        case .landscaping: "leaf.fill"
        case .bioluminescentLandscaping: "sparkles"
        }
    }
}

private struct PartnerDetailView: View {
    let state: LifeState
    @Environment(\.dismiss) private var dismiss
    var body: some View { NavigationStack { List {
        if let situation = state.partner?.activeSituation {
            Section("Active situation") {
                SituationStatusView(title: situation.kind.title, stage: situation.stage, stakes: situation.stakes, suggestedAction: situation.suggestedAction)
            }
        }
        if let partner = state.partner { Section(partner.name) { LabeledContent("Stage", value: partner.stage.rawValue.capitalized); LabeledContent("Bond", value: "\(partner.bond)"); LabeledContent("Tension", value: "\(partner.resentment)"); PersonalityProfileSummaryView(profile: partner.personality); Text(partner.lastNote ?? "The relationship is still being written.").foregroundStyle(.secondary) } }
        else { ContentUnavailableView("No current partner", systemImage: "heart", description: Text(state.formerRelationships.isEmpty ? "Use relationship actions to let a connection develop." : "An ended relationship still belongs to this life.")) }
        if !state.formerRelationships.isEmpty {
            Section("Past relationships") {
                ForEach(state.formerRelationships) { former in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(former.name).font(.subheadline.bold())
                        Text("\(former.yearsTogether) years · \(former.finalStage.rawValue.capitalized)")
                        Text(former.reason.reviewText.capitalized).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }.navigationTitle("Partner").toolbar { Button("Done") { dismiss() } } }
    }
}

private struct IdentityProfileView: View {
    let state: LifeState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Your personality") {
                    PersonalityProfileSummaryView(profile: state.personality)
                    LabeledContent("Core trait", value: state.personality.definingTrait.title)
                    LabeledContent("Special talent", value: state.personality.talent?.title ?? "None")
                }
                Section("How it plays") {
                    ForEach(Array((state.personality.salientFlags.isEmpty ? [state.personality.definingTrait] : state.personality.salientFlags).prefix(2))) { flag in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(flag.title).font(.subheadline.bold())
                            Text("Helps: \(flag.strategicHelp)").font(.caption)
                            Text("Strains: \(flag.strategicStrain)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                if !state.personality.development.isEmpty {
                    Section("Development") {
                        ForEach(state.personality.development) { change in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Age \(change.age) · \(change.axis.title)").font(.subheadline.bold())
                                    Spacer()
                                    if change.amount != 0 {
                                        Text("\(change.amount > 0 ? "+" : "")\(change.amount)")
                                            .font(.caption.monospacedDigit().bold())
                                            .foregroundStyle(change.amount > 0 ? .green : .orange)
                                    }
                                }
                                Text(change.note).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("People") {
                    ForEach(state.npcs.all) { npc in
                        NPCIdentitySummaryView(npc: npc)
                    }
                }
            }
            .navigationTitle("Identity")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

private struct NPCIdentitySummaryView: View {
    let npc: NPCState

    private var observations: [String] {
        npc.discoveredTraits.map(\.title) + npc.discoveredTags.map(\.title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(npc.name).font(.headline)
                Spacer()
                Text(npc.role.title).font(.caption).foregroundStyle(.secondary)
            }
            Text("\(npc.relationshipTone.title) now · bond \(npc.bond)")
                .font(.caption.bold())
            Text(npc.independentLife.currentNote)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let circumstance = npc.currentCircumstance {
                Label(circumstance.kind.title, systemImage: "waveform.path.ecg")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if observations.isEmpty {
                Text("You do not know them well enough yet.")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
            } else {
                Text("Observed: \(observations.joined(separator: " · "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(npc.name), \(npc.role.title). \(npc.relationshipTone.title) relationship, bond \(npc.bond). \(npc.independentLife.currentNote)")
    }
}

private struct PersonalityProfileSummaryView: View {
    let profile: PersonalityProfile
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 7) {
            Text(profile.identitySignature.title)
                .font(compact ? .caption.bold() : .subheadline.bold())
                .accessibilityIdentifier(compact ? "Compact Identity Signature" : "Identity Signature")
            if !compact {
                Text(profile.identitySignature.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(profile.salientFlags.isEmpty ? "No strong current tendency" : profile.salientFlags.map(\.title).joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(PersonalityAxis.allCases) { axis in
                PersonalityAxisRow(profile: profile, axis: axis, compact: compact)
            }
        }
    }
}

private struct PersonalityAxisRow: View {
    let profile: PersonalityProfile
    let axis: PersonalityAxis
    let compact: Bool

    private var delta: Int { profile.current[axis] - profile.baseline[axis] }

    var body: some View {
        HStack(spacing: 8) {
            Text(axis.title).font(.caption2).frame(width: compact ? 72 : 88, alignment: .leading)
            ProgressView(value: Double(profile.current[axis]), total: 100)
                .tint(profile.activeFlags.contains(where: { $0.axis == axis }) ? .accentColor : .secondary)
            Text("\(profile.current[axis])").font(.caption2.monospacedDigit()).frame(width: 24, alignment: .trailing)
            if !compact, delta != 0 {
                Image(systemName: delta > 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2.bold())
                    .foregroundStyle(delta > 0 ? .green : .orange)
                    .frame(width: 12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(axis.title) \(profile.current[axis]) out of 100, \(delta == 0 ? "unchanged" : "\(abs(delta)) points \(delta > 0 ? "higher" : "lower") than the start")")
    }
}

private struct FamilyDetailView: View {
    let state: LifeState
    @Environment(\.dismiss) private var dismiss
    var body: some View { NavigationStack { List {
        Section("Intention") { Text(state.family.intention.title); LabeledContent("Dependent load", value: "\(state.family.dependentLoad)"); LabeledContent("Caregiving load", value: "\(state.family.caregivingLoad)") }
        Section("Children") { if state.family.children.isEmpty { Text(state.family.intention == .childfree ? "Childfree by choice" : "No children").foregroundStyle(.secondary) } else { ForEach(state.family.children) { child in VStack(alignment: .leading) { Text("\(child.name), \(child.age)"); Text("\(child.temperament.rawValue.capitalized) · bond \(child.bond)\(child.dependent ? " · dependent" : child.adultOutcome.map { " · \($0.rawValue)" } ?? "")").font(.caption).foregroundStyle(.secondary) } } } }
        if !state.family.contacts.isEmpty { Section("Care circle") { ForEach(state.family.contacts) { contact in LabeledContent(contact.name, value: "Bond \(contact.bond)") } } }
    }.navigationTitle("Family").toolbar { Button("Done") { dismiss() } } }
    }
}

private struct PeopleDetailView: View {
    let state: LifeState
    @Environment(\.dismiss) private var dismiss

    private var people: [NPCState] { state.npcs.all }
    private var currentPeople: [NPCState] { people.filter { $0.activity != .dormant } }
    private var offstagePeople: [NPCState] { people.filter { $0.activity == .dormant } }

    var body: some View {
        NavigationStack {
            List {
                if people.isEmpty {
                    ContentUnavailableView(
                        "Your circle is still forming",
                        systemImage: "person.2",
                        description: Text("School, work, and social choices introduce people without creating a relationship chore list.")
                    )
                } else {
                    Section {
                        if currentPeople.isEmpty {
                            Text("No one is actively shaping this chapter right now.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(currentPeople.prefix(3)) { person in
                                NavigationLink {
                                    CastMemberDetailView(person: person)
                                } label: {
                                    NPCIdentitySummaryView(npc: person)
                                }
                            }
                        }
                    } header: {
                        Text("Current connections")
                    } footer: {
                        Text("Only the people most relevant to this chapter stay active.")
                    }

                    if currentPeople.count > 3 || !offstagePeople.isEmpty {
                        Section("Wider circle") {
                            ForEach(Array(currentPeople.dropFirst(3)) + offstagePeople) { person in
                                NavigationLink {
                                    CastMemberDetailView(person: person)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(person.name)
                                            Text("\(person.role.title) · \(activityTitle(person.activity))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(person.relationshipTone.title)
                                            .font(.caption.bold())
                                            .foregroundStyle(toneColor(person.relationshipTone))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("People")
            .accessibilityIdentifier("People Detail")
            .toolbar { Button("Done") { dismiss() } }
        }
    }

    private func activityTitle(_ activity: CastActivity) -> String {
        switch activity {
        case .active: "Active"
        case .dormant: "Offstage"
        case .pivotal: "Pivotal"
        case .hostile: "In conflict"
        }
    }

    private func toneColor(_ tone: NPCRelationshipTone) -> Color {
        switch tone {
        case .close, .warm: .green
        case .neutral: .secondary
        case .strained: .orange
        case .hostile: .red
        }
    }
}

private struct CastMemberDetailView: View {
    let person: NPCState

    var body: some View {
        List {
            Section("Now") {
                LabeledContent("Role", value: person.role.title)
                LabeledContent("Connection", value: person.relationshipTone.title)
                LabeledContent("Shared history", value: "\(person.bond)")
                LabeledContent("Their chapter", value: person.independentLife.chapter.title)
                Text(person.independentLife.currentNote)
                    .foregroundStyle(.secondary)
                if let circumstance = person.currentCircumstance {
                    Label(circumstance.kind.title, systemImage: "waveform.path.ecg")
                        .foregroundStyle(.orange)
                }
            }

            Section("What you know") {
                if person.discoveredTraits.isEmpty && person.discoveredTags.isEmpty {
                    Text("More of who they are will become visible through meaningful interaction.")
                        .foregroundStyle(.secondary)
                } else {
                    if !person.discoveredTraits.isEmpty {
                        LabeledContent("Observed", value: person.discoveredTraits.map(\.title).joined(separator: " · "))
                    }
                    if !person.discoveredTags.isEmpty {
                        LabeledContent("Recognized", value: person.discoveredTags.map(\.title).joined(separator: " · "))
                    }
                }
            }

            Section("Remembered moments") {
                if person.memories.isEmpty {
                    Text("No defining moment yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(person.memories) { memory in
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Age \(memory.age)")
                                .font(.caption.bold())
                            Text(memory.note)
                                .font(.subheadline)
                        }
                    }
                }
            }

            if !person.connections.isEmpty {
                Section("How your lives connect") {
                    ForEach(person.connections) { connection in
                        LabeledContent(
                            connection.kind.title,
                            value: connection.endedAge.map { "Ages \(connection.startedAge)–\($0)" }
                                ?? "Since age \(connection.startedAge)"
                        )
                    }
                }
            }
        }
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Stat Island (Glance Rule)

private struct StatIsland: View {
    let state: LifeState
    let openHealth: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Age \(state.character.age)")
                    .font(.title.bold())
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(state.lifeStage.title)
                        .font(.caption.bold())
                    Text(state.lifeStage == .adolescence
                        ? "\(state.education.schoolYearTitle(for: state.character.age)) year"
                        : state.job.tier.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                StatChip(title: "Happy", value: state.stats.happy, color: .pink)
                Button(action: openHealth) {
                    StatChip(title: "Health", value: state.stats.health, color: .red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Health \(state.stats.health)")
                .accessibilityHint("Opens health pressures and actions")
                StatChip(title: "Smart", value: state.stats.school, color: .blue)
                StatChip(title: "Looks", value: state.stats.looks, color: .purple)
                StatChip(title: "Rep", value: state.stats.rep, color: .orange)
                StatChip(title: "Cash", value: state.cash, color: state.cash < 0 ? .red : .green, isCurrency: true)
            }
            if state.mortalityPressure != .stable {
                Label("Mortality: \(state.mortalityPressure.title)", systemImage: "heart.circle")
                    .font(.caption.bold())
                    .foregroundStyle(state.mortalityPressure == .critical ? .red : .orange)
                    .accessibilityIdentifier("Mortality Pressure")
            }
            if let partner = state.partner {
                Text("\(partner.name): \(partner.mood.title)")
                    .font(.caption)
                    .foregroundStyle(partnerMoodColor(partner.mood))
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Stat Island")
    }

    private func partnerMoodColor(_ mood: PartnerMood) -> Color {
        switch mood {
        case .close: .green
        case .steady: .secondary
        case .uneasy: .orange
        case .fractured: .red
        }
    }
}

private struct StatChip: View {
    let title: String
    let value: Int
    let color: Color
    var isCurrency: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(title).font(.caption2).foregroundStyle(.secondary)
            }
            Text(isCurrency ? "$\(value)" : "\(value)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(tone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(isCurrency ? "$\(value)" : "\(value)")")
    }

    private var tone: Color {
        if isCurrency { return value < 0 ? .red : color }
        if value < 30 { return .red }
        if value < 50 { return .orange }
        return .primary
    }
}

// MARK: - Stage + what matters

private struct StageContextStrip: View {
    let state: LifeState
    var body: some View {
        let vibe = NarrativeVibeResolver.resolve(state)
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 10) {
                stageContext
                Spacer()
                vibeLabel(vibe)
            }
            VStack(alignment: .leading, spacing: 8) {
                stageContext
                vibeLabel(vibe)
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("Stage Strip")
    }

    @ViewBuilder private var stageContext: some View {
        Image(systemName: "chart.line.uptrend.xyaxis")
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 2) {
            Text("\(state.lifeStage.title) · \(state.lifeStage.ageBand)")
                .font(.caption.bold())
            Text(state.lifeStage.focusLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func vibeLabel(_ vibe: NarrativeVibe) -> some View {
        Label(vibe.title, systemImage: vibe.symbol)
            .font(.caption2.bold())
            .foregroundStyle(vibeColor(vibe))
            .accessibilityLabel("Life vibe: \(vibe.title)")
    }

    private func vibeColor(_ vibe: NarrativeVibe) -> Color {
        switch vibe {
        case .grounded: .secondary
        case .driven: .blue
        case .connected: .pink
        case .strained: .orange
        case .crisis: .red
        }
    }
}

private struct CurrentLifeNarrativeCard: View {
    let narrative: CurrentLifeNarrative

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: narrative.symbol)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.13), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT CHAPTER")
                    .font(.caption2.bold())
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                Text(narrative.chapter)
                    .font(.subheadline.bold())
                Text(narrative.context)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current chapter: \(narrative.chapter). \(narrative.context)")
        .accessibilityIdentifier("Current Life Narrative")
    }

    private var color: Color {
        switch narrative.vibe {
        case .grounded: .secondary
        case .driven: .blue
        case .connected: .pink
        case .strained: .orange
        case .crisis: .red
        }
    }
}

private struct LifeContextCard: View {
    let signals: [LifeContextSignal]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("LIFE RIGHT NOW")
                .font(.caption2.bold())
                .tracking(0.8)
                .foregroundStyle(.secondary)
            ForEach(signals) { signal in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: signal.domain.symbol)
                        .foregroundStyle(color(for: signal))
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(signal.headline).font(.caption.bold())
                        Text(signal.detail).font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("Life Right Now")
    }

    private func color(for signal: LifeContextSignal) -> Color {
        if signal.urgency >= 80 { return .red }
        if signal.urgency >= 60 { return .orange }
        return .secondary
    }
}

private struct WhatMattersCard: View {
    let items: [WhatMattersItem]
    var onSelect: (WhatMattersItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What matters this year")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if items.isEmpty {
                Text("No urgent pressures — push a direction or Age Up.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(item.pressureLabel) → \(item.actionName)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.primary)
                                Text(item.reason)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("Tap to act")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.orange)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("What Matters \(item.id)")
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityIdentifier("What Matters")
    }
}

// MARK: - Momentum / life-shape strip

private struct MomentumStrip: View {
    let momentum: MomentumState
    let ledger: PlayerInfluenceLedger

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wind")
                .foregroundStyle(shapeColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(momentum.stripLabel)
                    .font(.caption.bold())
                if !ledger.current.isEmpty {
                    Text("This year so far: \(ledger.current.dominantLabel)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if momentum.intensity > 0 {
                Text(String(repeating: "●", count: momentum.intensity))
                    .font(.caption2)
                    .foregroundStyle(shapeColor)
            }
        }
        .padding(10)
        .background(shapeColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("Momentum Strip")
    }

    private var shapeColor: Color {
        switch momentum.shape {
        case .driven: .orange
        case .connected: .pink
        case .careful: .blue
        case .loose: .purple
        case .pragmatic: .gray
        case .balanced: .green
        }
    }
}

// MARK: - Hints

private struct FirstTimeHints: View {
    let flags: LifeFlags

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !flags.seenInstantHint {
                HintChip(
                    icon: "bolt.fill",
                    text: "Instant actions change stats now — no year cost. Long-press any card for a preview."
                )
            }
            if !flags.seenAgeUpHint {
                HintChip(
                    icon: "calendar",
                    text: "Age Up commits the year: job pay, events, quiet notes, and life-shape residue."
                )
            }
        }
    }
}

private struct HintChip: View {
    let icon: String
    let text: String
    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier("Hint Chip")
    }
}

// MARK: - Pressures

private struct DomainActionHeader: View {
    let title: String
    let symbol: String
    let readyCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: symbol)
                    .font(.title2.bold())
                Spacer()
                Text(readyCount == 0 ? "NO MOVES" : "\(readyCount) READY")
                    .font(.caption2.bold())
                    .foregroundStyle(readyCount == 0 ? Color.secondary : Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }
            Text(totalCount == 1 ? "One move this year · hold for the full ripple" : "Choose a move · each refreshes after Age Up")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("Domain Action Header")
    }
}

private struct PressuresRow: View {
    let pressures: [DomainPressure]
    var onSelect: ((DomainPressure) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Current Pressures")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if onSelect != nil {
                    Text("Tap to inspect")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(pressures) { pressure in
                        if let onSelect {
                            Button { onSelect(pressure) } label: {
                                PressureChip(pressure: pressure, showsDisclosure: true)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens pressure details and response options")
                        } else {
                            PressureChip(pressure: pressure)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("Pressures Row")
    }
}

private struct PressureChip: View {
    let pressure: DomainPressure
    var showsDisclosure = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: pressure.symbol)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(pressure.label).font(.caption.bold())
                Text(pressure.level.title)
                    .font(.caption2)
                    .foregroundStyle(levelColor)
            }
            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(levelColor.opacity(0.14), in: Capsule())
        .help(pressure.detail)
        .accessibilityLabel("\(pressure.label) \(pressure.level.title). \(pressure.detail)")
        .accessibilityIdentifier("Pressure \(pressure.label)")
    }

    private var levelColor: Color {
        switch pressure.level {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }
}

private struct PressureDetailView: View {
    let pressure: DomainPressure
    let domain: Domain
    @ObservedObject var simulator: LifeSimulator
    let completed: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var actions: [DomainAction] {
        Array(simulator.visibleActions(in: domain).prefix(3))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: pressure.symbol)
                            .font(.title2)
                            .foregroundStyle(levelColor)
                            .frame(width: 42, height: 42)
                            .background(levelColor.opacity(0.12), in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pressure.level == .low ? "Under control" : "Needs attention")
                                .font(.headline)
                            Text(pressure.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Ways to respond") {
                    ForEach(actions) { action in
                        let availability = simulator.availability(for: action)
                        Button {
                            guard availability == .available else { return }
                            simulator.execute(action.id)
                            completed()
                            if simulator.state.pendingEvent == nil { dismiss() }
                        } label: {
                            PressureActionLabel(action: action, availability: availability)
                        }
                        .disabled(availability != .available)
                        .accessibilityIdentifier("Pressure Action \(action.name)")
                    }
                }

                Section {
                    Text("This is a signal, not a separate chore. You can respond now or accept what the next year may do with it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(pressure.label)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("Pressure Detail")
    }

    private var levelColor: Color {
        switch pressure.level {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }
}

private struct PressureActionLabel: View {
    let action: DomainAction
    let availability: Availability

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: action.category.symbol)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(action.name).font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(availability == .available ? Color.secondary : Color.orange)
                if let effect = action.effectPreviewLines.first {
                    Text(effect)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: availability == .available ? "arrow.right.circle.fill" : "lock.fill")
                .foregroundStyle(availability == .available ? Color.accentColor : Color.secondary)
        }
    }

    private var detail: String {
        availability.reason ?? action.shortDescription
    }
}

// MARK: - Instant action grid

private struct InstantActionGrid: View {
    let domain: Domain
    @ObservedObject var simulator: LifeSimulator
    let onTap: (DomainAction) -> Void
    let onLongPress: (DomainAction) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedCategory: ActionCategory?

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    var body: some View {
        let actions = simulator.visibleActions(in: domain)
        let categories = ActionCategory.allCases.filter { category in actions.contains { $0.category == category } }
        let active = selectedCategory.flatMap { categories.contains($0) ? $0 : nil } ?? defaultCategory
        VStack(alignment: .leading, spacing: 8) {
            if categories.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories) { category in
                            Button { selectedCategory = category } label: {
                                Label(category.title, systemImage: category.symbol)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .foregroundStyle(active == category ? Color.accentColor : .secondary)
                                    .background(
                                        active == category ? Color.accentColor.opacity(0.12) : Color.clear,
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule().strokeBorder(
                                            active == category ? Color.accentColor.opacity(0.4) : Color.secondary.opacity(0.2)
                                        )
                                    )
                            }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(active == category ? .isSelected : [])
                        }
                    }
                }
                .accessibilityIdentifier("Action Categories")
            }
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(actions.filter { $0.category == active }) { action in
                    let availability = simulator.availability(for: action)
                    InstantActionCard(
                        action: action,
                        availability: availability,
                        disabled: simulator.state.pendingEvent != nil || simulator.state.isGameOver
                    ) {
                        if case .available = availability {
                            onTap(action)
                        } else {
                            onLongPress(action)
                        }
                    } onLongPress: {
                        onLongPress(action)
                    }
                }
            }
        }
        .onChange(of: domain) { _, _ in selectedCategory = nil }
    }

    private var defaultCategory: ActionCategory {
        switch domain {
        case .school: simulator.state.lifeStage == .adolescence ? .education : .career
        case .cash: .money
        case .love: .relationship
        case .play: .leisure
        case .health: .health
        }
    }
}

private struct HighSchoolOverview: View {
    let state: LifeState

    var body: some View {
        ThisYearAtSchoolCard(state: state)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("High School Overview")
    }
}

private struct ThisYearAtSchoolCard: View {
    let state: LifeState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("This Year at School", systemImage: "building.2.fill")
                    .font(.caption.bold())
                Spacer()
                Text(state.education.schoolEnvironment.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            schoolLine("Year", "\(state.education.schoolYearTitle(for: state.character.age)) · \(state.education.commitment?.title ?? "Focus not chosen")")
            schoolLine("Person", EducationSystem.primarySchoolRelationship(for: state))
            schoolLine("Pressure", EducationSystem.currentSchoolPressure(for: state))
            schoolLine("Activity", activityLine)
            HStack(spacing: 8) {
                SchoolStatusCard(title: "Grades", value: state.education.academicStanding, symbol: "text.book.closed.fill")
                SchoolStatusCard(title: "Belonging", value: state.education.schoolBelonging, symbol: "person.2.fill")
                SchoolStatusCard(title: "Future", value: state.education.futureReadiness, symbol: "arrow.up.right.circle.fill")
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("This Year at School")
    }

    private var activityLine: String {
        guard state.education.activity != .none else { return "No activity yet" }
        return "\(state.education.activity.title) · \(state.education.activityStage.title)"
    }

    private func schoolLine(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.caption)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}

private struct HighSchoolFoundationView: View {
    let state: LifeState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("School / Skills", systemImage: "building.columns.fill")
                    .font(.caption.bold())
                Spacer()
                Text(influenceLine)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(state.education.postSchoolPath.title)
                .font(.headline)
            if let commitment = state.education.dominantCommitment {
                Text("Foundation · \(commitment.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let memory = state.education.definingHighSchoolMemory {
                Text(memory)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("High School Foundation")
    }

    private var influenceLine: String {
        let years = state.education.launchInfluenceYearsRemaining
        return years > 0 ? "Early influence · \(years)y" : "History only"
    }
}

private struct CollegeFoundationView: View {
    let state: LifeState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("College foundation", systemImage: "graduationcap.fill")
                    .font(.caption.bold())
                Spacer()
                Text("$\(state.education.college.institution?.annualDebt ?? 0)/yr debt")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(state.education.college.institution?.title ?? "College")
                .font(.headline)
            Text(state.education.college.field?.title ?? "Choose a field")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                CollegeStatusValue(
                    title: "Credits",
                    value: "\(state.education.college.credits)/\(state.education.college.creditTarget)",
                    symbol: "checkmark.seal.fill"
                )
                CollegeStatusValue(
                    title: "Standing",
                    value: "\(state.education.college.academicStanding)",
                    symbol: "chart.line.uptrend.xyaxis"
                )
                CollegeStatusValue(
                    title: "Belonging",
                    value: "\(state.education.college.campusBelonging)",
                    symbol: "person.2.fill"
                )
            }
            if state.education.launchInfluenceYearsRemaining > 0 {
                Text("School influence · \(state.education.launchInfluenceYearsRemaining)y remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("College Foundation")
    }
}

private struct CollegeStatusValue: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: symbol)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct EducationRecoveryFoundationView: View {
    let state: LifeState

    var body: some View {
        let recovery = state.education.recovery
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Education recovery", systemImage: "arrow.uturn.up.circle.fill")
                    .font(.caption.bold())
                Spacer()
                Text("$\(recovery.kind?.annualDebt ?? 0)/yr debt")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(recovery.kind?.title ?? "Second-chance education")
                .font(.headline)
            HStack {
                CollegeStatusValue(
                    title: "Progress",
                    value: "\(recovery.progress)/\(recovery.target)",
                    symbol: "checkmark.seal.fill"
                )
                CollegeStatusValue(
                    title: "Started",
                    value: recovery.startedAge.map(String.init) ?? "—",
                    symbol: "calendar"
                )
            }
            Text("Study or attend class advances this single track.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Education Recovery Foundation")
    }
}

private struct SchoolStatusCard: View {
    let title: String
    let value: Int
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("\(value)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(tone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(tone.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(value)")
    }

    private var tone: Color {
        if value < 35 { return .red }
        if value < 55 { return .orange }
        return .green
    }
}

private struct InstantActionCard: View {
    let action: DomainAction
    let availability: Availability
    let disabled: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        Button(action: onTap) {
            InstantActionCardLabel(
                action: action,
                availability: availability,
                statusTitle: statusTitle,
                statusColor: statusColor
            )
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(availability == .available ? 0.06 : 0), radius: 7, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity({
            if case .locked = availability { return 0.55 }
            return disabled ? 0.5 : 1
        }())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45).onEnded { _ in onLongPress() }
        )
        .accessibilityLabel(action.name)
        .accessibilityValue(accessibilityValue)
        .accessibilityIdentifier(action.name)
        .accessibilityHint(accessibilityHint)
        .accessibilityAction(named: "Show preview") { onLongPress() }
    }

    private var statusTitle: String {
        switch availability {
        case .available: "READY"
        case .locked(let reason): reason.hasPrefix("Already used") ? "USED" : "LOCKED"
        }
    }

    private var statusColor: Color {
        switch availability {
        case .available: .accentColor
        case .locked(let reason): reason.hasPrefix("Already used") ? .secondary : .orange
        }
    }

    private var borderColor: Color {
        availability == .available ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.05)
    }

    private var accessibilityValue: String {
        let effects = action.effectPreviewLines.joined(separator: ", ")
        if case .locked(let reason) = availability {
            return effects.isEmpty ? "Locked. \(reason)" : "Locked. \(reason). \(effects)"
        }
        return effects.isEmpty ? "Available" : "Available. \(effects)"
    }

    private var accessibilityHint: String {
        if case .locked = availability {
            return "Opens requirements and ripple details"
        }
        return "Activates immediately. Use the Show preview action for details"
    }
}

private struct InstantActionCardLabel: View {
    let action: DomainAction
    let availability: Availability
    let statusTitle: String
    let statusColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: action.category.symbol)
                    .font(.caption.bold())
                    .foregroundStyle(.tint)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
                Text(action.name)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                Spacer(minLength: 0)
                Text(statusTitle)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.11), in: Capsule())
            }
            Text(action.shortDescription)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if let preview = action.effectPreviewLines.first {
                Label(preview, systemImage: "waveform.path.ecg")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
            if case .locked(let reason) = availability {
                Text(reason)
                    .font(.caption2)
                    .foregroundStyle(reason.hasPrefix("Already used") ? Color.secondary : Color.orange)
                    .lineLimit(2)
            }
        }
    }
}

private extension ActionCategory {
    var symbol: String {
        switch self {
        case .education: "graduationcap.fill"
        case .career: "briefcase.fill"
        case .money: "banknote.fill"
        case .housing: "house.fill"
        case .relationship: "heart.fill"
        case .family: "person.3.fill"
        case .leisure: "sparkles"
        case .health: "heart.text.square.fill"
        }
    }
}

private struct ActionPreviewSheet: View {
    let action: DomainAction
    let availability: Availability
    @ObservedObject var simulator: LifeSimulator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let resolved = SocialReactivitySystem().preview(action: action, state: simulator.state)
        NavigationStack {
            List {
                Section {
                    Text(action.shortDescription)
                    if !action.microBeat.isEmpty {
                        Text(action.microBeat).foregroundStyle(.secondary)
                    }
                }
                Section("Effects") {
                    let talentEffects = TalentSystem.modifiedEffects(for: action, state: simulator.state)
                    ForEach(talentEffects.previewLines, id: \.self) { Text($0) }
                    if action.effectPreviewLines.isEmpty {
                        Text("No direct stat range — narrative / flags only.")
                    }
                }
                Section("Identity") {
                    Text(simulator.state.personality.identitySignature.title).font(.headline)
                    Text(simulator.state.personality.identitySignature.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(simulator.state.personality.salientFlags.isEmpty
                        ? "No strong current tendency"
                        : simulator.state.personality.salientFlags.map(\.title).joined(separator: " · "))
                    if let partnerFlag = simulator.state.partner?.personality.salientFlags.first {
                        Text("\(partnerFlag.title) partner")
                    }
                    if let talentContext = TalentSystem.context(for: action, state: simulator.state) {
                        Text(talentContext).foregroundStyle(.green)
                    }
                }
                if !resolved.npcEffect.previewLines.isEmpty {
                    Section("Identity effect") {
                        ForEach(resolved.npcEffect.previewLines, id: \.self) { Text($0) }
                        if let cause = resolved.personalityContext { Text("Because: \(cause)").font(.caption).foregroundStyle(.secondary) }
                    }
                }
                if !resolved.partnerEffect.previewLines.isEmpty {
                    Section("Relationship") {
                        ForEach(resolved.partnerEffect.previewLines, id: \.self) { Text($0) }
                    }
                }
                if let hint = resolved.previewHint {
                    Section("How this may land") {
                        Text(hint)
                    }
                }
                let worldLines = simulator.worldPreviewLines(for: action)
                if !worldLines.isEmpty {
                    Section("Current world") {
                        ForEach(worldLines, id: \.self) { Text($0) }
                    }
                }
                if let npc = resolved.npc {
                    Section("Active contact") {
                        Text("\(npc.name) · \(npc.role.title)")
                        Text(npc.personality.salientFlags.map(\.title).joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Ripple") {
                    Text(action.rippleHint)
                    if !action.previewTags.isEmpty {
                        Text(action.previewTags.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if case .locked(let reason) = availability {
                    Section("Locked") { Text(reason).foregroundStyle(.orange) }
                }
            }
            .navigationTitle(action.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Year recap

private struct YearRecapView: View {
    let summary: YearSummary
    let continueAction: () -> Void

    private var impacts: [SemanticDelta] {
        YearSummarySystem.rankedImpacts(summary.deltas)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    Text("AGE \(max(0, summary.age - 1)) → \(summary.age)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(LifeStage.stage(for: summary.age).title.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        summary.importance == .quiet ? "Quiet year" : "Year resolved",
                        systemImage: summary.importance == .quiet ? "moon.stars" : "clock.arrow.circlepath"
                    )
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("Year Summary")
                    Text(summary.headline)
                        .font(.largeTitle.bold())
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let hero = impacts.first {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(hero.text)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(hero.beneficial ? .green : .red)
                        Text("Strongest change")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if impacts.count > 1 {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(Array(impacts.dropFirst())) { impact in
                            YearImpactChip(impact: impact)
                        }
                    }
                }

                if !summary.developments.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("WHAT CHANGED")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        ForEach(summary.developments.prefix(3)) { development in
                            Label(development.text, systemImage: "circle.fill")
                                .font(.subheadline)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }

                if let stage = summary.stageTransition {
                    RecapInsert(symbol: "flag.fill", title: "New chapter", detail: stage, tone: .secondary)
                }
                if let news = summary.worldNews {
                    RecapInsert(
                        symbol: "newspaper.fill",
                        title: news.headline,
                        detail: ([news.detail] + news.impactLines).joined(separator: " · "),
                        tone: worldNewsColor(news.severity)
                    )
                }
                if let warning = summary.mortalityWarning {
                    RecapInsert(symbol: "heart.circle.fill", title: "Health warning", detail: warning, tone: .red)
                }

                if let stance = summary.stanceTitle, let shape = summary.shapeTitle {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LIFE DIRECTION")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text("\(stance) · \(shape)")
                            .font(.headline)
                    }
                }
                if let focus = summary.focusNote {
                    Text(focus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if let silence = summary.silenceNote {
                    Text(silence)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Continue", action: continueAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, minHeight: 54)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)
                .accessibilityIdentifier("Year Recap Continue")
        }
        .accessibilityElement(children: .contain)
    }

    private func worldNewsColor(_ severity: WorldNewsSeverity) -> Color {
        switch severity {
        case .neutral: .secondary
        case .pressure: .orange
        case .danger: .red
        }
    }
}

private struct YearImpactChip: View {
    let impact: SemanticDelta

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
            Text(impact.text)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
        }
        .foregroundStyle(impact.beneficial ? .green : .red)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        switch impact.label {
        case "Cash": "dollarsign.circle.fill"
        case "Health": "cross.case.fill"
        case "Bond", "Happy": "heart.fill"
        case "Smart": "brain.head.profile"
        case "Rep": "person.crop.circle.badge.checkmark"
        default: "arrow.up.arrow.down.circle.fill"
        }
    }
}

private struct RecapInsert: View {
    let symbol: String
    let title: String
    let detail: String
    let tone: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(tone)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Feedback / recovery

private struct FeedbackBannerModel: Identifiable {
    let id: UInt64
    let outcome: ActionOutcome
}

private struct FeedbackBanner: View {
    let model: FeedbackBannerModel
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.outcome.headline).font(.subheadline.bold())
            if !model.outcome.deltas.semanticLines.isEmpty {
                AdaptiveDeltaRow(deltas: Array(model.outcome.deltas.semanticLines.prefix(4)))
            } else {
                Text(model.outcome.narrative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let context = model.outcome.personalityContext {
                Text(context)
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 8, y: 3)
        .accessibilityIdentifier("Feedback Banner")
    }
}

private struct AdaptiveDeltaRow: View {
    let deltas: [SemanticDelta]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { deltaLabels }
            VStack(alignment: .leading, spacing: 4) { deltaLabels }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var deltaLabels: some View {
        ForEach(deltas) { delta in
            Text(delta.text)
                .font(.caption.bold())
                .foregroundStyle(delta.beneficial ? .green : .red)
        }
    }
}

private struct RecoveryCard: View {
    let recovery: RecoveryWindow
    var onStabilize: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                "\(recovery.kind.rawValue.capitalized) recovery required",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.subheadline.bold())
            .foregroundStyle(.red)
            Text(
                recovery.kind == .financial
                    ? "Work a shift or budget hard before you Age Up again — another year ends the life."
                    : "Rest or seek care before you Age Up again — another year ends the life."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            Button(recovery.kind == .financial ? "Work a shift now" : "Rest now") {
                onStabilize()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .accessibilityIdentifier("Recovery Stabilize")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityIdentifier("Recovery Card")
    }
}

// MARK: - Bottom thumb zone

private struct BottomControls: View {
    @Binding var domain: Domain
    @ObservedObject var simulator: LifeSimulator
    let selectDomain: (Domain) -> Void
    let ageUp: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: 6) {
                ForEach(Domain.primaryTabs) { item in
                    let label = item.displayTitle(attendsSchool: simulator.state.flags.attendsSchool)
                    Button { selectDomain(item) } label: {
                        VStack(spacing: 3) {
                            Image(systemName: item.symbol)
                                .symbolVariant(domain == item ? .fill : .none)
                            Text(label)
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .fontWeight(domain == item ? .semibold : .regular)
                        .foregroundStyle(domain == item ? Color.accentColor : .secondary)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(
                            domain == item ? Color.accentColor.opacity(0.13) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(label)
                    .accessibilityIdentifier("Domain \(item.title)")
                    .accessibilityAddTraits(domain == item ? .isSelected : [])
                }
            }
            Button(action: ageUp) {
                VStack(spacing: 2) {
                    Text("AGE UP")
                    Text(ageUpContext)
                        .font(.caption2.weight(.medium))
                        .opacity(0.86)
                }
            }
                .buttonStyle(AgeUpButtonStyle())
                .frame(maxWidth: .infinity, minHeight: 56)
                .disabled(ageUpDisabled)
                .accessibilityIdentifier("Age Up")
                .accessibilityLabel("Age Up")
                .accessibilityValue(ageUpContext)
        }
    }

    private var ageUpDisabled: Bool {
        simulator.state.pendingEvent != nil
            || simulator.state.isGameOver
            || simulator.state.recovery != nil
    }

    private var ageUpContext: String {
        if simulator.state.isGameOver { return "Life complete" }
        if simulator.state.pendingEvent != nil { return "Resolve the current moment first" }
        if simulator.state.recovery != nil { return "Stabilize this crisis first" }
        let expected = EconomyCalculator.forecast(simulator.state).detail.expectedNet
        let signed = expected > 0 ? "+\(MoneyText.compact(expected))" : MoneyText.compact(expected)
        return "To age \(simulator.state.character.age + 1) · year forecast \(signed)"
    }
}

private struct AgeUpButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.uiTestReduceMotion) private var uiTestReduceMotion
    @Environment(\.isEnabled) private var isEnabled
    private var reduceMotion: Bool { accessibilityReduceMotion || uiTestReduceMotion }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.7))
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                isEnabled
                    ? (configuration.isPressed ? Color.accentColor.opacity(0.75) : Color.accentColor)
                    : Color.secondary.opacity(0.35),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .scaleEffect(configuration.isPressed && isEnabled && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Event / health / journal / review

private struct LifeMomentSheet: View {
    private enum Phase: Equatable {
        case decision(PresentedEvent)
        case recap(YearSummary)

        var isDecision: Bool {
            if case .decision = self { return true }
            return false
        }
    }

    @ObservedObject var simulator: LifeSimulator
    let instantCompleted: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.uiTestReduceMotion) private var uiTestReduceMotion
    @State private var phase: Phase
    private var reduceMotion: Bool { accessibilityReduceMotion || uiTestReduceMotion }

    init(
        event: PresentedEvent,
        simulator: LifeSimulator,
        instantCompleted: @escaping () -> Void = {}
    ) {
        self.simulator = simulator
        self.instantCompleted = instantCompleted
        _phase = State(initialValue: .decision(event))
    }

    init(
        summary: YearSummary,
        simulator: LifeSimulator,
        instantCompleted: @escaping () -> Void = {}
    ) {
        self.simulator = simulator
        self.instantCompleted = instantCompleted
        _phase = State(initialValue: .recap(summary))
    }

    var body: some View {
        Group {
            switch phase {
            case .decision(let event):
                DecisionMomentView(
                    event: event,
                    age: simulator.state.character.age,
                    stage: simulator.state.lifeStage,
                    availability: { simulator.choiceAvailability($0, eventID: event.id) }
                ) { resolve($0, in: event) }
            case .recap(let summary):
                YearRecapView(summary: summary) { dismiss() }
            }
        }
        .presentationDetents(detents)
        .presentationDragIndicator(phase.isDecision ? .hidden : .visible)
        .interactiveDismissDisabled(phase.isDecision)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: phase)
    }

    private var detents: Set<PresentationDetent> {
        switch phase {
        case .decision:
            [.large]
        case .recap(let summary):
            summary.importance == .quiet ? [.medium, .large] : [.large]
        }
    }

    private func resolve(_ choice: EventChoiceID, in event: PresentedEvent) {
        UISelectionFeedbackGenerator().selectionChanged()
        simulator.execute(choice)

        if let next = simulator.state.pendingEvent {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                phase = .decision(next)
            }
            announce(next.headline)
            return
        }

        if event.kind == .yearly, let summary = simulator.state.lastYearSummary {
            let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = summary.importance == .critical ? .heavy : .medium
            UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                phase = .recap(summary)
            }
            let impacts = YearSummarySystem.rankedImpacts(summary.deltas).map(\.text).joined(separator: ", ")
            announce(impacts.isEmpty ? summary.headline : "\(summary.headline). \(impacts)")
        } else {
            dismiss()
            Task { @MainActor in instantCompleted() }
        }
    }

    private func announce(_ message: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

private struct DecisionMomentView: View {
    let event: PresentedEvent
    let age: Int
    let stage: LifeStage
    let availability: (EventChoice) -> Availability
    let choose: (EventChoiceID) -> Void

    private var scene: LifeMomentSceneStyle {
        LifeMomentSceneStyle(style: LifeMomentPresentationStyle.resolve(for: event))
    }

    private var yearImpacts: [SemanticDelta] {
        YearSummarySystem.rankedImpacts(event.yearDeltas)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LifeMomentSceneHeader(scene: scene, age: age, stage: stage)
                    .accessibilityIdentifier("Life Moment Scene Header")

                Text(event.headline)
                    .font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)

                Text(event.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(event.id == "economy-debt-workout" ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)

                if !yearImpacts.isEmpty {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("THIS YEAR")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        AdaptiveDeltaRow(deltas: yearImpacts)
                    }
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                Text("CHOOSE")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                ForEach(event.choices.prefix(3)) { choice in
                    let choiceAvailability = availability(choice)
                    Button { choose(choice.id) } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(choice.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(choiceAvailability.reason ?? choice.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(choiceAvailability == .available ? scene.accent : Color.secondary.opacity(0.45))
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
                    }
                    .buttonStyle(LifeMomentChoiceButtonStyle(accent: scene.accent, isAvailable: choiceAvailability == .available))
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("Event Choice \(choice.id.rawValue)")
                    .accessibilityLabel("\(choice.title). \(choiceAvailability.reason ?? choice.detail)")
                    .disabled(choiceAvailability != .available)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)
        }
    }
}

private struct LifeMomentSceneStyle {
    let style: LifeMomentPresentationStyle

    var contextTitle: String {
        switch style {
        case .relationship: "RELATIONSHIP"
        case .finance: "FINANCIAL PRESSURE"
        case .recovery: "RECOVERY"
        case .school: "SCHOOL MOMENT"
        case .play: "SOCIAL MOMENT"
        case .yearly: "YEARLY DECISION"
        case .general: "LIFE MOMENT"
        }
    }

    var symbol: String {
        switch style {
        case .relationship: "heart.fill"
        case .finance: "banknote.fill"
        case .recovery: "cross.case.fill"
        case .school: "book.closed.fill"
        case .play: "sparkles"
        case .yearly: "clock.arrow.circlepath"
        case .general: "arrow.triangle.branch"
        }
    }

    var accent: Color {
        switch style {
        case .relationship: .pink
        case .finance: .green
        case .recovery: .orange
        case .school: .blue
        case .play: .purple
        case .yearly: .accentColor
        case .general: .indigo
        }
    }

    var colors: [Color] {
        [accent.opacity(0.90), accent.opacity(0.48)]
    }
}

private struct LifeMomentSceneHeader: View {
    let scene: LifeMomentSceneStyle
    let age: Int
    let stage: LifeStage

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: scene.symbol)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.white.opacity(0.20), in: Circle())

            VStack(alignment: .leading, spacing: 7) {
                Text(scene.contextTitle)
                    .font(.caption.bold())
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.88))
                Text("Age \(age) · \(stage.title)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("A choice will shape what comes next.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.84))
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .background(
            LinearGradient(colors: scene.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scene.contextTitle). Age \(age), \(stage.title). A choice will shape what comes next.")
    }
}

private struct LifeMomentChoiceButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let accent: Color
    let isAvailable: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                isAvailable ? accent.opacity(configuration.isPressed ? 0.16 : 0.09) : Color.secondary.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isAvailable ? accent.opacity(configuration.isPressed ? 0.70 : 0.30) : Color.secondary.opacity(0.14), lineWidth: 1)
            }
            .opacity(isAvailable ? 1 : 0.62)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct HealthSheet: View {
    @ObservedObject var simulator: LifeSimulator
    let completed: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var previewAction: DomainAction?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        EssentialGlanceCard(title: "Physical", value: "\(simulator.state.health.physicalWellbeing)", detail: "Body load \(simulator.state.health.bodyLoad)", symbol: "figure.walk", action: {})
                        EssentialGlanceCard(title: "Mental", value: "\(simulator.state.health.mentalWellbeing)", detail: "Care \(simulator.state.health.careAccess.rawValue)", symbol: "brain.head.profile", action: {})
                    }
                    if !simulator.state.health.conditions.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Active conditions").font(.caption.bold()).foregroundStyle(.secondary)
                            ForEach(simulator.state.health.conditions) { condition in
                                Text("\(condition.kind.title) · \(condition.status.title) · severity \(condition.severity) · managed \(condition.management)")
                                    .font(.caption)
                            }
                        }
                    }
                    PressuresRow(pressures: simulator.pressures(for: .health))
                    InstantActionGrid(
                        domain: .health,
                        simulator: simulator,
                        onTap: { action in
                            simulator.execute(action.id)
                            dismiss()
                            completed()
                        },
                        onLongPress: { action in previewAction = action }
                    )
                }
                .padding()
            }
            .navigationTitle("Health")
        }
        .sheet(item: $previewAction) { action in
            ActionPreviewSheet(
                action: action,
                availability: simulator.availability(for: action),
                simulator: simulator
            )
        }
    }
}

private struct JournalView: View {
    let state: LifeState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                let timeline = LifeTimelineResolver.milestones(for: state)
                if !timeline.isEmpty {
                    Section("Life timeline") {
                        ForEach(timeline) { entry in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(entry.age)")
                                    .font(.caption.bold().monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 26, alignment: .leading)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entry.headline).font(.subheadline.bold())
                                    Text(entry.detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Age \(entry.age). \(entry.headline). \(entry.detail)")
                        }
                    }
                }
                if let summary = state.lastYearSummary {
                    Section("Latest year") {
                        ForEach(summary.bullets, id: \.self) { Text($0) }
                        if let silence = summary.silenceNote {
                            Text(silence).font(.caption).italic().foregroundStyle(.secondary)
                        }
                        if let focus = summary.focusNote {
                            Text(focus).font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
                if state.finance.economy.conversionAge != nil { Text("Entries before the economy update keep their original money amounts.").font(.caption) }
                Section("Full history") {
                    ForEach(state.history) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                if let cutoff = state.finance.economy.historicalSequence, entry.id <= cutoff { Text("Before economy update").font(.caption2).foregroundStyle(.secondary) }
                                Text("Age \(entry.age): \(entry.headline)").font(.subheadline.bold())
                                if entry.isSilence {
                                    Image(systemName: "moon.stars").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            Text(entry.detail).font(.caption).foregroundStyle(.secondary)
                            if !entry.deltas.lines.isEmpty {
                                Text(entry.deltas.lines.joined(separator: " · "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct LifeReviewView: View {
    let review: LifeReviewModel
    let state: LifeState
    let playtestExportURLs: [URL]
    let playtestOutcomeAssessment: PlaytestOutcomeAssessment?
    var onAssessPlaytestOutcome: (String, Bool) -> Void
    var onNewLife: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var outcomeExplanation: String
    @State private var reviewAgrees: Bool
    @State private var assessmentSaved: Bool
    @FocusState private var outcomeExplanationFocused: Bool

    init(
        review: LifeReviewModel,
        state: LifeState,
        playtestExportURLs: [URL],
        playtestOutcomeAssessment: PlaytestOutcomeAssessment?,
        onAssessPlaytestOutcome: @escaping (String, Bool) -> Void,
        onNewLife: @escaping () -> Void
    ) {
        self.review = review
        self.state = state
        self.playtestExportURLs = playtestExportURLs
        self.playtestOutcomeAssessment = playtestOutcomeAssessment
        self.onAssessPlaytestOutcome = onAssessPlaytestOutcome
        self.onNewLife = onNewLife
        _outcomeExplanation = State(initialValue: playtestOutcomeAssessment?.explanation ?? "")
        _reviewAgrees = State(initialValue: playtestOutcomeAssessment?.reviewAgrees ?? true)
        _assessmentSaved = State(initialValue: playtestOutcomeAssessment != nil)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(review.legacyHeadline).font(.title3.bold())
                    Text(review.legacySummary).font(.subheadline)
                }
                Section("End") {
                    Text("Age \(review.age)")
                    Text(review.endReason.title)
                    Text(state.history.first?.detail ?? "Your life reached its end.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Shape & stance") {
                    Text(review.lifeShape.title)
                    Text("Dominant stance: \(review.dominantStance.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Personality & world") {
                    Text(review.personalityLine)
                    Text(review.talentLine)
                    Text(review.worldLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Trajectory") {
                    Text(review.educationLine)
                    Text(review.workLine)
                    Text(review.financialLine)
                    Text(review.relationshipLine)
                    Text(review.healthLine)
                    Text(review.housingLine)
                    Text(review.legalLine)
                    Text(review.continuityLine)
                }
                Section("Final vitals") {
                    Text(
                        "Happy \(state.stats.happy) · Health \(state.stats.health) · Smart \(state.stats.school) · Looks \(state.stats.looks) · Rep \(state.stats.rep) · Cash $\(state.cash)"
                    )
                    Text("Lifetime net $\(state.lifetimeNet) · peak cash $\(state.aggregates.peakCash)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Pivotal moments") {
                    ForEach(review.pivotal) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Age \(entry.age): \(entry.headline)").font(.subheadline.bold())
                            Text(entry.detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                }
                if !review.personalityPivotal.isEmpty {
                    Section("Identity turning points") {
                        ForEach(review.personalityPivotal) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Age \(entry.age): \(entry.headline)").font(.subheadline.bold())
                                Text(entry.detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                    }
                }
                #if DEBUG
                if PlaytestEnvironment.isEnabled {
                    Section("Playtest") {
                        Text("What most shaped this outcome?")
                            .font(.caption.bold())
                        TextField("Explain the ending in your own words", text: $outcomeExplanation, axis: .vertical)
                            .lineLimit(2...5)
                            .focused($outcomeExplanationFocused)
                            .accessibilityIdentifier("Outcome Explanation")
                        Toggle("Life Review matches my explanation", isOn: $reviewAgrees)
                        Button(assessmentSaved ? "Outcome check saved" : "Save outcome check") {
                            onAssessPlaytestOutcome(outcomeExplanation, reviewAgrees)
                            assessmentSaved = true
                            outcomeExplanationFocused = false
                        }
                        .disabled(outcomeExplanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("Save Outcome Check")
                        if !playtestExportURLs.isEmpty {
                            ShareLink(items: playtestExportURLs) {
                                Label("Export Playtest Report", systemImage: "square.and.arrow.up")
                            }
                            .accessibilityIdentifier("Export Terminal Playtest Report")
                        }
                    }
                    .onChange(of: outcomeExplanation) { _, _ in assessmentSaved = false }
                    .onChange(of: reviewAgrees) { _, _ in assessmentSaved = false }
                }
                #endif
            }
            .navigationTitle("Your Life")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("New Life") {
                        dismiss()
                        onNewLife()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("New Life")
                }
            }
        }
        .interactiveDismissDisabled(true)
    }
}

// DomainAction Identifiable for sheet
extension DomainAction: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
