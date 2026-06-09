import Foundation

struct GameState: Codable, Equatable {
    var player: Player = Player()
    var trajectory: TrajectoryState = TrajectoryState()
    var education: EducationState = EducationState()
    var career: CareerState = CareerState()
    var specialCareer: SpecialCareerState = SpecialCareerState()
    var crime: CrimeState = CrimeState()
    var legal: LegalState = LegalState()
    var military: MilitaryState = MilitaryState()
    var finance: FinanceState = FinanceState()
    var relationships: RelationshipState = RelationshipState()
    var family: FamilyState = FamilyState()
    var healthProfile: HealthState = HealthState()
    var assets: AssetState = AssetState()
    var housing: HousingState = HousingState()
    var progress: ProgressState = ProgressState()
    var narrativeArcs: NarrativeArcState = NarrativeArcState()
    var consequences: ConsequenceState = ConsequenceState()
    var activities: ActivityState = ActivityState()
    // D1: Light identity coherence — 0-100, starts neutral. Self actions move it; low values create subtle pressure/crisis flavor.
    var identityCoherence: Int = 55
    
    // var correlationLedger: CorrelationLedger = CorrelationLedger()  // legacy duplicate — SystemCorrelationLedger (Engine1) is the active one below
    
    var economy: EconomyState = EconomyState()
    // Macro Autonomy
    var currentEra: WorldEra = .stable
    var eraYearsRemaining: Int = 10

    var activeYearChapter: ActiveYearChapter? = nil
    var pendingActions: [PlayerYearAction] = []
    var actionMemory: ActionMemoryState = ActionMemoryState()
    var quickActionMemory: QuickActionMemoryState = QuickActionMemoryState()
    var suggestedPlayerAction: SuggestedPlayerAction? = nil
    var yearlyStance: YearlyStanceMemory = YearlyStanceMemory()
    var mvpOnboarding: MVPOnboardingState = MVPOnboardingState()
    var softRunGoal: SoftRunGoal? = nil
    var discoverability: DiscoverabilityState = DiscoverabilityState()
    var history: [HistoryEntry] = []
    var lastEventYearById: [String: Int] = [:]
    var startupState: StartupState = .choosingOrigin
    var originProfile: OriginProfile? = nil
    var openingSummary: String? = nil
    var inheritedLegacy: LegacyInheritanceSnapshot? = nil
    var isGameOver: Bool = false
    var hasUsedCrisisBuyBack: Bool = false // One-time safety net
    /// Procedural childhood backstory + career aptitude DNA. Set by ChildhoodGenerationEngine at character creation.
    var childhoodDossier: ChildhoodDossier? = nil

    /// Controls how forgiving the simulation is of setbacks. Defaults to .resilient for better replayability.
    var resilience: LifeResilience = .resilient

    /// Tracks the strength of recent instant/quick actions and their autonomous reactions.
    /// This is the bridge for Phase 2: making micro-actions influence the next year's simulation.
    var instantMomentum: InstantMomentumState = InstantMomentumState()
    /// Captured at Age Up when momentum was visible — shown once on year summary.
    var lastYearInstantMomentumCarry: InstantMomentumCarrySnapshot? = nil
    
    // Using rich CorrelationLedger with Engine shims for full build compatibility
    var correlationLedger: CorrelationLedger = CorrelationLedger()
    
    // Fame Web F1: Unified recognition profile. Every fame-adjacent avenue (special careers,
    // athlete personalBrand, military medals, lifestyle/wealth, social rep, events) will feed here.
    var fame: FameProfile = FameProfile()

    private enum CodingKeys: String, CodingKey {
        case player
        case trajectory
        case education
        case career
        case specialCareer
        case crime
        case legal
        case military
        case finance
        case relationships
        case family
        case healthProfile
        case assets
        case housing
        case progress
        case narrativeArcs
        case consequences
        case activities
        case identityCoherence
        case correlationLedger
        case currentEra
        case eraYearsRemaining
        case activeYearChapter
        case pendingActions
        case actionMemory
        case quickActionMemory
        case suggestedPlayerAction
        case yearlyStance
        case mvpOnboarding
        case softRunGoal
        case discoverability
        case history
        case lastEventYearById
        case startupState
        case originProfile
        case openingSummary
        case inheritedLegacy
        case isGameOver
        case hasUsedCrisisBuyBack
        case childhoodDossier
        case resilience
        case instantMomentum
        case lastYearInstantMomentumCarry
        case fame
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        player = try container.decodeIfPresent(Player.self, forKey: .player) ?? Player()
        trajectory = try container.decodeIfPresent(TrajectoryState.self, forKey: .trajectory) ?? TrajectoryState()
        education = try container.decodeIfPresent(EducationState.self, forKey: .education) ?? EducationState()
        career = try container.decodeIfPresent(CareerState.self, forKey: .career) ?? CareerState()
        specialCareer = try container.decodeIfPresent(SpecialCareerState.self, forKey: .specialCareer) ?? SpecialCareerState()
        crime = try container.decodeIfPresent(CrimeState.self, forKey: .crime) ?? CrimeState()
        legal = try container.decodeIfPresent(LegalState.self, forKey: .legal) ?? LegalState()
        military = try container.decodeIfPresent(MilitaryState.self, forKey: .military) ?? MilitaryState()
        if crime.status == .inactive, specialCareer.track == .crime {
            crime = CrimeState.migratingFromLegacySpecialCareer(specialCareer)
            specialCareer = SpecialCareerState()
        }
        let legacyMoney = try Self.decodeLegacyMoney(from: container)
        finance = try container.decodeIfPresent(FinanceState.self, forKey: .finance) ?? FinanceState(cashOnHand: legacyMoney ?? 250)
        relationships = try container.decodeIfPresent(RelationshipState.self, forKey: .relationships) ?? RelationshipState()
        family = try container.decodeIfPresent(FamilyState.self, forKey: .family) ?? FamilyState()
        healthProfile = try container.decodeIfPresent(HealthState.self, forKey: .healthProfile) ?? HealthState()
        assets = try container.decodeIfPresent(AssetState.self, forKey: .assets) ?? AssetState()
        housing = try container.decodeIfPresent(HousingState.self, forKey: .housing) ?? HousingState()
        progress = try container.decodeIfPresent(ProgressState.self, forKey: .progress) ?? ProgressState()
        narrativeArcs = try container.decodeIfPresent(NarrativeArcState.self, forKey: .narrativeArcs) ?? NarrativeArcState()
        consequences = try container.decodeIfPresent(ConsequenceState.self, forKey: .consequences) ?? ConsequenceState()
        activities = try container.decodeIfPresent(ActivityState.self, forKey: .activities) ?? ActivityState(currentYearAge: player.age)
        identityCoherence = try container.decodeIfPresent(Int.self, forKey: .identityCoherence) ?? 55
        correlationLedger = try container.decodeIfPresent(CorrelationLedger.self, forKey: .correlationLedger) ?? CorrelationLedger()

        currentEra = try container.decodeIfPresent(WorldEra.self, forKey: .currentEra) ?? .stable
        eraYearsRemaining = try container.decodeIfPresent(Int.self, forKey: .eraYearsRemaining) ?? 10

        activeYearChapter = try container.decodeIfPresent(ActiveYearChapter.self, forKey: .activeYearChapter)
        pendingActions = try container.decodeIfPresent([PlayerYearAction].self, forKey: .pendingActions) ?? []
        actionMemory = try container.decodeIfPresent(ActionMemoryState.self, forKey: .actionMemory) ?? ActionMemoryState()
        quickActionMemory = try container.decodeIfPresent(QuickActionMemoryState.self, forKey: .quickActionMemory) ?? QuickActionMemoryState()
        suggestedPlayerAction = try container.decodeIfPresent(SuggestedPlayerAction.self, forKey: .suggestedPlayerAction)
        yearlyStance = try container.decodeIfPresent(YearlyStanceMemory.self, forKey: .yearlyStance) ?? YearlyStanceMemory()
        mvpOnboarding = try container.decodeIfPresent(MVPOnboardingState.self, forKey: .mvpOnboarding) ?? MVPOnboardingState()
        softRunGoal = try container.decodeIfPresent(SoftRunGoal.self, forKey: .softRunGoal)
        discoverability = try container.decodeIfPresent(DiscoverabilityState.self, forKey: .discoverability) ?? DiscoverabilityState()
        history = try container.decodeIfPresent([HistoryEntry].self, forKey: .history) ?? []
        lastEventYearById = try container.decodeIfPresent([String: Int].self, forKey: .lastEventYearById) ?? [:]
        startupState = try container.decodeIfPresent(StartupState.self, forKey: .startupState) ?? (player.traits.isEmpty ? .choosingOrigin : .active)
        originProfile = try container.decodeIfPresent(OriginProfile.self, forKey: .originProfile)
        openingSummary = try container.decodeIfPresent(String.self, forKey: .openingSummary)
        inheritedLegacy = try container.decodeIfPresent(LegacyInheritanceSnapshot.self, forKey: .inheritedLegacy)
        isGameOver = try container.decodeIfPresent(Bool.self, forKey: .isGameOver) ?? false
        hasUsedCrisisBuyBack = try container.decodeIfPresent(Bool.self, forKey: .hasUsedCrisisBuyBack) ?? false
        childhoodDossier = try container.decodeIfPresent(ChildhoodDossier.self, forKey: .childhoodDossier)
        resilience = try container.decodeIfPresent(LifeResilience.self, forKey: .resilience) ?? .resilient
        instantMomentum = try container.decodeIfPresent(InstantMomentumState.self, forKey: .instantMomentum) ?? InstantMomentumState()
        lastYearInstantMomentumCarry = try container.decodeIfPresent(InstantMomentumCarrySnapshot.self, forKey: .lastYearInstantMomentumCarry)
        correlationLedger = try container.decodeIfPresent(CorrelationLedger.self, forKey: .correlationLedger) ?? CorrelationLedger()
        fame = try container.decodeIfPresent(FameProfile.self, forKey: .fame) ?? FameProfile()
    }

    private static func decodeLegacyMoney(from container: KeyedDecodingContainer<CodingKeys>) throws -> Int? {
        guard container.contains(.player) else { return nil }
        let playerContainer = try container.nestedContainer(keyedBy: LegacyPlayerCodingKeys.self, forKey: .player)
        return try playerContainer.decodeIfPresent(Int.self, forKey: .money)
    }

    private enum LegacyPlayerCodingKeys: String, CodingKey {
        case money
    }

    // MARK: - Vibe Layer (Codex IX)

    /// The current emotional register of this life, derived from state.
    /// Used by the UI to adjust visual treatment and by narrative systems
    /// to calibrate prose register. Never stored — always computed.
    var narrativeTone: NarrativeTone {
        NarrativeToneResolver().resolve(for: self)
    }

    var currentIdentityPattern: PlayerPattern? {
        PlayerPattern.resolve(from: self)
    }

    /// Keeps the Player's mirrored resilience in sync so domain systems can read it easily.
    mutating func syncResilienceToPlayer() {
        player._resilience = resilience
    }
}

