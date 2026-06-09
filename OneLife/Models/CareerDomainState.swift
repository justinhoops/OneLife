import Foundation

// MARK: - Career Domain

enum CareerStatus: String, Codable, CaseIterable {
    case student
    case partTime
    case fullTime
    case military
    case unemployed
}

enum CareerProfile: String, Codable, CaseIterable {
    case stableAdmin
    case physicalLabor
    case serviceFrontline
    case creativeFreelance
    case credentialedProfessional
    case militaryService
    case medicalProfessional
    case legalProfessional
    case techSpecialist
    case financialExpert

    var shortLabel: String {
        switch self {
        case .stableAdmin: return "Stable Admin"
        case .physicalLabor: return "Physical Labor"
        case .serviceFrontline: return "Service Frontline"
        case .creativeFreelance: return "Creative Freelance"
        case .credentialedProfessional: return "Credentialed Pro"
        case .militaryService: return "Military Service"
        case .medicalProfessional: return "Medical"
        case .legalProfessional: return "Legal"
        case .techSpecialist: return "Tech"
        case .financialExpert: return "Finance"
        }
    }
}

enum SpecializedCareerTrack: String, Codable, CaseIterable {
    case medical
    case law
    case tech
    case corporateFinance
}

enum MilitaryBranch: String, Codable, CaseIterable {
    case army
    case navy
    case airForce
    case marines
    case coastGuard
    case spaceForce

    var displayName: String {
        switch self {
        case .army: return "Army"
        case .navy: return "Navy"
        case .airForce: return "Air Force"
        case .marines: return "Marines"
        case .coastGuard: return "Coast Guard"
        case .spaceForce: return "Space Force"
        }
    }
}

enum MilitaryTrack: String, Codable, CaseIterable {
    case inactive
    case enlisted
    case officer
    case reserve
}

enum DeploymentStatus: String, Codable, CaseIterable {
    case home
    case stationed
    case deployed
    case activeCombat
}

enum MilitarySpecialty: String, Codable, CaseIterable {
    case combat
    case medical
    case aviation
    case intelligence
    case logistics
    
    var displayName: String {
        switch self {
        case .combat: return "Combat Operations"
        case .medical: return "Medical Services"
        case .aviation: return "Aviation"
        case .intelligence: return "Intelligence"
        case .logistics: return "Logistics"
        }
    }
}

struct MilitaryState: Codable, Equatable {
    var track: MilitaryTrack = .inactive
    var branch: MilitaryBranch? = nil
    var specialty: MilitarySpecialty? = nil
    var rank: String = "Private"
    var rankLevel: Int = 1
    var yearsServed: Int = 0
    var contractYearsRemaining: Int = 0
    var deploymentStatus: DeploymentStatus = .home
    var fitness: Int = 60
    var discipline: Int = 80
    var heat: Int = 0 // AWOL/Trouble
    var isAWOL: Bool = false
    var medals: [String] = []
    
    // V2 additions
    var isVeteran: Bool = false
    var hasGIBill: Bool = false
    var hasPension: Bool = false
    var combatTrauma: Int = 0 // PTSD tracking

    mutating func clamp() {
        fitness = fitness.clamped(to: 0...100)
        discipline = discipline.clamped(to: 0...100)
        heat = heat.clamped(to: 0...100)
        combatTrauma = combatTrauma.clamped(to: 0...100)
    }
}

enum CareerExperienceTag: String, Codable, CaseIterable, Hashable {
    case service
    case labor
    case admin
    case technical
    case healthcare
    case sales
    case creative
    case management
    case coaching

    var shortLabel: String {
        switch self {
        case .service: return "Service"
        case .labor: return "Labor"
        case .admin: return "Admin"
        case .technical: return "Technical"
        case .healthcare: return "Healthcare"
        case .sales: return "Sales"
        case .creative: return "Creative"
        case .management: return "Management"
        case .coaching: return "Coaching"
        }
    }
}

enum WorkIdentity: String, Codable, CaseIterable {
    case unsettled
    case climber
    case caretaker
    case drifter
    case hustler
    case burnedOutProvider

    var shortLabel: String {
        switch self {
        case .unsettled: return "Unsettled"
        case .climber: return "Climber"
        case .caretaker: return "Caretaker"
        case .drifter: return "Drifter"
        case .hustler: return "Hustler"
        case .burnedOutProvider: return "Burned-Out Provider"
        }
    }
}

enum CareerOpportunityDoor: String, Codable, CaseIterable {
    case internalPromotionTrack
    case lateralEscapeRoute
    case credentialPivot
    case contractWindfall
    case unionStability
    case burnoutExit

    var shortLabel: String {
        switch self {
        case .internalPromotionTrack: return "Promotion Track"
        case .lateralEscapeRoute: return "Escape Route"
        case .credentialPivot: return "Credential Pivot"
        case .contractWindfall: return "Contract Windfall"
        case .unionStability: return "Union Stability"
        case .burnoutExit: return "Burnout Exit"
        }
    }
}

/// D3: Regular (non-special) career archetypes for mechanical parity with deep paths.
/// Different curves for performance, burnout, security, income ramp, aging resilience.
/// Set by static instant actions; used in advanceYear + UI + handoff flavor.
enum CareerArchetype: String, Codable, CaseIterable {
    case corporateClimber
    case gigFreelancer
    case skilledTrades
    case publicService
    case techEngineer
    case salesNetworker
    case creativeProfessional
    case careLabor

    var displayName: String {
        switch self {
        case .corporateClimber: return "Corporate Professional"
        case .gigFreelancer: return "Gig / Service"
        case .skilledTrades: return "Skilled Trades"
        case .publicService: return "Public Sector"
        case .techEngineer: return "Tech Specialist"
        case .salesNetworker: return "Sales / Commission"
        case .creativeProfessional: return "Creative Professional"
        case .careLabor: return "Care / Emotional Labor"
        }
    }

    /// One-tap path commits shown before an archetype is chosen.
    static let pathPickerActions: [ActionChoiceID] = [
        .corporateClimb, .tradesMastery, .freelanceHustle, .salesClientOutreach
    ]

    /// Native Right Now toolkit once the path is committed (3–4 actions).
    var instantToolkit: [ActionChoiceID] {
        switch self {
        case .corporateClimber:
            return [.corporateStayLate, .corporatePolitick, .corporateDocumentWin, .network]
        case .skilledTrades:
            return [.tradesExtraFocus, .tradesMaintainTools, .tradesSafetyPush, .protectYourEnergy]
        case .salesNetworker:
            return [.salesClientOutreach, .salesPipelineGrind, .salesRecoveryCall, .chaseSpotlight]
        case .gigFreelancer:
            return [.gigAcceptSurge, .gigMaintainRating, .gigRestDay, .workHard]
        case .techEngineer:
            return [.techDeepWork, .protectYourEnergy, .network, .workHard]
        case .publicService:
            return [.publicServiceGrind, .protectYourEnergy, .network, .workHard]
        case .creativeProfessional:
            return [.chaseSpotlight, .network, .protectYourEnergy, .workHard]
        case .careLabor:
            return [.protectYourEnergy, .workHard, .network]
        }
    }

    /// Fame leak strength for unified FameProfile (0 = none, 3 = high).
    var fameLeakTier: Int {
        switch self {
        case .salesNetworker, .creativeProfessional: return 3
        case .corporateClimber, .techEngineer, .gigFreelancer: return 2
        case .careLabor, .publicService: return 1
        case .skilledTrades: return 0
        }
    }

    static func committed(by action: ActionChoiceID) -> CareerArchetype? {
        switch action {
        case .corporateClimb: return .corporateClimber
        case .freelanceHustle, .pivotToGig: return .gigFreelancer
        case .tradesMastery: return .skilledTrades
        case .salesClientOutreach, .salesPipelineGrind: return .salesNetworker
        case .publicServiceGrind: return .publicService
        case .techDeepWork: return .techEngineer
        default: return nil
        }
    }
}

enum SpecialCareerTrack: String, Codable, CaseIterable {
    case inactive
    case entertainment
    case movieActor
    case musicProducer
    case movieProducer
    case recordLabelOwner
    case coach
    case contentCreator   // C1: New dedicated track for modern attention economy creators
    case politics         // P1: New dedicated track for political life
    case crime
    case founder
    case athlete
    case shadowOperative
    case trader
    case ventureCapitalist
    case corporateRaider
    case fightEmpire
    case military

    var isDiamondCareer: Bool {
        switch self {
        case .movieProducer, .recordLabelOwner, .coach,
             .shadowOperative, .trader, .ventureCapitalist, .corporateRaider, .fightEmpire:
            return true
        default:
            return false
        }
    }
}

/// Dedicated state for the Athlete special career path.
/// This is the foundation for a real sports pipeline.
struct AthleteState: Codable, Equatable {
    var sport: AthleteSport = .general
    var peakPerformance: Int = 65          // 0-100, peaks in mid-late 20s, declines with age/injury
    var durability: Int = 60               // Resistance to injury
    var sponsorshipTier: Int = 1           // 1-5, affects income and fame
    var fanLoyalty: Int = 40               // How much fans stick with you through slumps/scandals
    var injuryRisk: Int = 25               // Current season injury chance modifier
    /// Post-injury performance ceiling — never fully restores to pre-injury peak.
    var injuryPeakCap: Int = 100

    // S3a: Potential / Talent ceiling — the "gift" that determines how high you can realistically climb
    var naturalPotential: Int = 72         // 40-95. Higher = better ceiling, slower age decline, bigger doping upside
    
    // S3a: Athlete-specific fame / icon status (separate from generic specialCareer.fame)
    var personalBrand: Int = 25            // 0-100. "Pro" < 45, "Star" 45-70, "Legend" > 70. Resists audience decay, boosts endorsements.
    
    // S3a: Real accolades and legacy markers
    var accolades: [String] = []           // e.g. "League MVP", "World Champion", "Hall of Fame Inductee"
    
    // S3a: Doping / edge state (high-risk, high-reward temptation)
    var enhancementUses: Int = 0           // How many times you've crossed the line
    var enhancementHeat: Int = 0           // Lingering detection risk (decays slowly)
    var lastEnhancementAge: Int = 0        // For narrative + detection window logic
    
    var careerHighlights: [String] = []    // Memorable moments for narrative and legacy
    var retirementOptionsUnlocked: Set<AthleteRetirementPath> = []
    var combat: CombatCareerState = CombatCareerState()

    private enum CodingKeys: String, CodingKey {
        case sport, peakPerformance, durability, sponsorshipTier, fanLoyalty, injuryRisk, injuryPeakCap
        case naturalPotential, personalBrand, accolades, enhancementUses, enhancementHeat
        case lastEnhancementAge, careerHighlights, retirementOptionsUnlocked, combat
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sport = try container.decodeIfPresent(AthleteSport.self, forKey: .sport) ?? .general
        peakPerformance = try container.decodeIfPresent(Int.self, forKey: .peakPerformance) ?? 65
        durability = try container.decodeIfPresent(Int.self, forKey: .durability) ?? 60
        sponsorshipTier = try container.decodeIfPresent(Int.self, forKey: .sponsorshipTier) ?? 1
        fanLoyalty = try container.decodeIfPresent(Int.self, forKey: .fanLoyalty) ?? 40
        injuryRisk = try container.decodeIfPresent(Int.self, forKey: .injuryRisk) ?? 25
        injuryPeakCap = try container.decodeIfPresent(Int.self, forKey: .injuryPeakCap) ?? 100
        naturalPotential = try container.decodeIfPresent(Int.self, forKey: .naturalPotential) ?? 72
        personalBrand = try container.decodeIfPresent(Int.self, forKey: .personalBrand) ?? 25
        accolades = try container.decodeIfPresent([String].self, forKey: .accolades) ?? []
        enhancementUses = try container.decodeIfPresent(Int.self, forKey: .enhancementUses) ?? 0
        enhancementHeat = try container.decodeIfPresent(Int.self, forKey: .enhancementHeat) ?? 0
        lastEnhancementAge = try container.decodeIfPresent(Int.self, forKey: .lastEnhancementAge) ?? 0
        careerHighlights = try container.decodeIfPresent([String].self, forKey: .careerHighlights) ?? []
        retirementOptionsUnlocked = try container.decodeIfPresent(Set<AthleteRetirementPath>.self, forKey: .retirementOptionsUnlocked) ?? []
        combat = try container.decodeIfPresent(CombatCareerState.self, forKey: .combat) ?? CombatCareerState()
        clamp()
    }
    
    mutating func clamp() {
        peakPerformance = peakPerformance.clamped(to: 10...100)
        durability = durability.clamped(to: 10...95)
        sponsorshipTier = sponsorshipTier.clamped(to: 1...5)
        fanLoyalty = fanLoyalty.clamped(to: 0...100)
        injuryRisk = injuryRisk.clamped(to: 5...80)
        injuryPeakCap = injuryPeakCap.clamped(to: 10...100)
        peakPerformance = min(peakPerformance, injuryPeakCap)
        naturalPotential = naturalPotential.clamped(to: 40...95)
        personalBrand = personalBrand.clamped(to: 0...100)
        enhancementHeat = enhancementHeat.clamped(to: 0...100)
        enhancementUses = max(0, enhancementUses)
        combat.clamp()
    }
}

/// Dedicated state for the Founder / CEO / Entrepreneur special career path.
/// E1 foundation: real CEO mechanics with vision, execution, team, stage, control, and mental load.
struct FounderState: Codable, Equatable {
    var vision: Int = 55                   // Big picture, storytelling, fundraising
    var execution: Int = 55                // Operational delivery and discipline
    var teamHealth: Int = 60               // Morale, retention, culture strength
    var productStage: Int = 20             // 0-100: idea → mvp → early traction → scale → mature
    var control: Int = 85                  // Founder power / influence (synergizes with equityOwned)
    var founderMentalLoad: Int = 30        // Stress, burnout risk, decision fatigue
    var companyCulture: Int = 50           // Values, identity, "how we do things"
    var keyHires: Int = 10                 // Quality and number of critical hires made
    var competitiveMoat: Int = 15          // Differentiation and defensibility
    var personalLegend: Int = 20           // Founder-specific reputation (feeds FameProfile strongly)
    /// Tracks consecutive high-burnout years for board-pressure events.
    var lastHighBurnoutAge: Int = 0

    mutating func clamp() {
        vision = vision.clamped(to: 15...95)
        execution = execution.clamped(to: 15...95)
        teamHealth = teamHealth.clamped(to: 10...95)
        productStage = productStage.clamped(to: 0...100)
        control = control.clamped(to: 10...100)
        founderMentalLoad = founderMentalLoad.clamped(to: 5...95)
        companyCulture = companyCulture.clamped(to: 10...95)
        keyHires = keyHires.clamped(to: 0...100)
        competitiveMoat = competitiveMoat.clamped(to: 0...100)
        personalLegend = personalLegend.clamped(to: 0...100)
    }
}

struct MovieActorState: Codable, Equatable {
    var actingSkill: Int = 35
    var screenPresence: Int = 35
    var auditionNetwork: Int = 25
    var roleCredits: Int = 0
    var boxOfficeDraw: Int = 5
    var publicImage: Int = 45
    var typecastRisk: Int = 15
    var agentQuality: Int = 20
    var lastRolePayout: Int = 0

    init(
        actingSkill: Int = 35,
        screenPresence: Int = 35,
        auditionNetwork: Int = 25,
        roleCredits: Int = 0,
        boxOfficeDraw: Int = 5,
        publicImage: Int = 45,
        typecastRisk: Int = 15,
        agentQuality: Int = 20,
        lastRolePayout: Int = 0
    ) {
        self.actingSkill = actingSkill
        self.screenPresence = screenPresence
        self.auditionNetwork = auditionNetwork
        self.roleCredits = roleCredits
        self.boxOfficeDraw = boxOfficeDraw
        self.publicImage = publicImage
        self.typecastRisk = typecastRisk
        self.agentQuality = agentQuality
        self.lastRolePayout = lastRolePayout
        clamp()
    }

    mutating func clamp() {
        actingSkill = actingSkill.clamped(to: 0...100)
        screenPresence = screenPresence.clamped(to: 0...100)
        auditionNetwork = auditionNetwork.clamped(to: 0...100)
        roleCredits = max(0, roleCredits)
        boxOfficeDraw = boxOfficeDraw.clamped(to: 0...100)
        publicImage = publicImage.clamped(to: 0...100)
        typecastRisk = typecastRisk.clamped(to: 0...100)
        agentQuality = agentQuality.clamped(to: 0...100)
        lastRolePayout = max(0, lastRolePayout)
    }
}

struct MovieProducerState: Codable, Equatable {
    var slateCount: Int = 0
    var developmentQuality: Int = 30
    var castRelationships: Int = 30
    var budgetControl: Int = 35
    var distributionLeverage: Int = 20
    var productionChaos: Int = 25
    var studioTrust: Int = 35
    var backendCatalog: Int = 5
    var prestige: Int = 15
    var lastFilmPayout: Int = 0

    init(
        slateCount: Int = 0,
        developmentQuality: Int = 30,
        castRelationships: Int = 30,
        budgetControl: Int = 35,
        distributionLeverage: Int = 20,
        productionChaos: Int = 25,
        studioTrust: Int = 35,
        backendCatalog: Int = 5,
        prestige: Int = 15,
        lastFilmPayout: Int = 0
    ) {
        self.slateCount = slateCount
        self.developmentQuality = developmentQuality
        self.castRelationships = castRelationships
        self.budgetControl = budgetControl
        self.distributionLeverage = distributionLeverage
        self.productionChaos = productionChaos
        self.studioTrust = studioTrust
        self.backendCatalog = backendCatalog
        self.prestige = prestige
        self.lastFilmPayout = lastFilmPayout
        clamp()
    }

    mutating func clamp() {
        slateCount = slateCount.clamped(to: 0...12)
        developmentQuality = developmentQuality.clamped(to: 0...100)
        castRelationships = castRelationships.clamped(to: 0...100)
        budgetControl = budgetControl.clamped(to: 0...100)
        distributionLeverage = distributionLeverage.clamped(to: 0...100)
        productionChaos = productionChaos.clamped(to: 0...100)
        studioTrust = studioTrust.clamped(to: 0...100)
        backendCatalog = backendCatalog.clamped(to: 0...100)
        prestige = prestige.clamped(to: 0...100)
        lastFilmPayout = max(0, lastFilmPayout)
    }
}

struct CoachingState: Codable, Equatable {
    var programLevel: Int = 1
    var rosterTalent: Int = 42
    var playerDevelopment: Int = 40
    var schemeFit: Int = 38
    var staffQuality: Int = 35
    var lockerRoom: Int = 50
    var recruitingReach: Int = 35
    var boosterPressure: Int = 25
    var programPrestige: Int = 20
    var seasonWins: Int = 0
    var seasonLosses: Int = 0
    var contractValue: Int = 0

    init(
        programLevel: Int = 1,
        rosterTalent: Int = 42,
        playerDevelopment: Int = 40,
        schemeFit: Int = 38,
        staffQuality: Int = 35,
        lockerRoom: Int = 50,
        recruitingReach: Int = 35,
        boosterPressure: Int = 25,
        programPrestige: Int = 20,
        seasonWins: Int = 0,
        seasonLosses: Int = 0,
        contractValue: Int = 0
    ) {
        self.programLevel = programLevel
        self.rosterTalent = rosterTalent
        self.playerDevelopment = playerDevelopment
        self.schemeFit = schemeFit
        self.staffQuality = staffQuality
        self.lockerRoom = lockerRoom
        self.recruitingReach = recruitingReach
        self.boosterPressure = boosterPressure
        self.programPrestige = programPrestige
        self.seasonWins = seasonWins
        self.seasonLosses = seasonLosses
        self.contractValue = contractValue
        clamp()
    }

    mutating func clamp() {
        programLevel = programLevel.clamped(to: 1...4)
        rosterTalent = rosterTalent.clamped(to: 0...100)
        playerDevelopment = playerDevelopment.clamped(to: 0...100)
        schemeFit = schemeFit.clamped(to: 0...100)
        staffQuality = staffQuality.clamped(to: 0...100)
        lockerRoom = lockerRoom.clamped(to: 0...100)
        recruitingReach = recruitingReach.clamped(to: 0...100)
        boosterPressure = boosterPressure.clamped(to: 0...100)
        programPrestige = programPrestige.clamped(to: 0...100)
        seasonWins = seasonWins.clamped(to: 0...16)
        seasonLosses = seasonLosses.clamped(to: 0...16)
        contractValue = max(0, contractValue)
    }
}

enum ArtistPayoutPolicy: String, Codable, CaseIterable {
    case exploitative
    case standard
    case artistFriendly
}

struct LabelArtist: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var name: String = "New Artist"
    var talent: Int = 50
    var popularity: Int = 20
    var morale: Int = 55
    var contractFairness: Int = 50
    var catalogCount: Int = 0
    var tourReadiness: Int = 30
    var yearlyEarnings: Int = 0

    init(
        id: String = UUID().uuidString,
        name: String = "New Artist",
        talent: Int = 50,
        popularity: Int = 20,
        morale: Int = 55,
        contractFairness: Int = 50,
        catalogCount: Int = 0,
        tourReadiness: Int = 30,
        yearlyEarnings: Int = 0
    ) {
        self.id = id
        self.name = name
        self.talent = talent
        self.popularity = popularity
        self.morale = morale
        self.contractFairness = contractFairness
        self.catalogCount = catalogCount
        self.tourReadiness = tourReadiness
        self.yearlyEarnings = yearlyEarnings
        clamp()
    }

    mutating func clamp() {
        talent = talent.clamped(to: 10...100)
        popularity = popularity.clamped(to: 0...100)
        morale = morale.clamped(to: 0...100)
        contractFairness = contractFairness.clamped(to: 0...100)
        catalogCount = max(0, catalogCount)
        tourReadiness = tourReadiness.clamped(to: 0...100)
        yearlyEarnings = max(0, yearlyEarnings)
    }
}

struct RecordLabelState: Codable, Equatable {
    var roster: [LabelArtist] = []
    var catalogStrength: Int = 10
    var tourMachine: Int = 10
    var artistTrust: Int = 55
    var cashflowPressure: Int = 25
    var industryHeat: Int = 10
    var labelPrestige: Int = 15
    var artistPayoutPolicy: ArtistPayoutPolicy = .standard

    init(
        roster: [LabelArtist] = [],
        catalogStrength: Int = 10,
        tourMachine: Int = 10,
        artistTrust: Int = 55,
        cashflowPressure: Int = 25,
        industryHeat: Int = 10,
        labelPrestige: Int = 15,
        artistPayoutPolicy: ArtistPayoutPolicy = .standard
    ) {
        self.roster = roster
        self.catalogStrength = catalogStrength
        self.tourMachine = tourMachine
        self.artistTrust = artistTrust
        self.cashflowPressure = cashflowPressure
        self.industryHeat = industryHeat
        self.labelPrestige = labelPrestige
        self.artistPayoutPolicy = artistPayoutPolicy
        clamp()
    }

    mutating func clamp() {
        roster = roster.map { artist in
            var copy = artist
            copy.clamp()
            return copy
        }
        if roster.count > 8 {
            roster = Array(roster.prefix(8))
        }
        catalogStrength = catalogStrength.clamped(to: 0...100)
        tourMachine = tourMachine.clamped(to: 0...100)
        artistTrust = artistTrust.clamped(to: 0...100)
        cashflowPressure = cashflowPressure.clamped(to: 0...100)
        industryHeat = industryHeat.clamped(to: 0...100)
        labelPrestige = labelPrestige.clamped(to: 0...100)
    }
}

struct MusicProducerState: Codable, Equatable {
    var credits: Int = 0
    var sonicSignature: Int = 35
    var studioQuality: Int = 30
    var network: Int = 35
    var demand: Int = 20
    var royaltyCatalog: Int = 5
    var creditDisputes: Int = 10
    var lastPlacementValue: Int = 0

    init(
        credits: Int = 0,
        sonicSignature: Int = 35,
        studioQuality: Int = 30,
        network: Int = 35,
        demand: Int = 20,
        royaltyCatalog: Int = 5,
        creditDisputes: Int = 10,
        lastPlacementValue: Int = 0
    ) {
        self.credits = credits
        self.sonicSignature = sonicSignature
        self.studioQuality = studioQuality
        self.network = network
        self.demand = demand
        self.royaltyCatalog = royaltyCatalog
        self.creditDisputes = creditDisputes
        self.lastPlacementValue = lastPlacementValue
        clamp()
    }

    mutating func clamp() {
        credits = max(0, credits)
        sonicSignature = sonicSignature.clamped(to: 0...100)
        studioQuality = studioQuality.clamped(to: 0...100)
        network = network.clamped(to: 0...100)
        demand = demand.clamped(to: 0...100)
        royaltyCatalog = royaltyCatalog.clamped(to: 0...100)
        creditDisputes = creditDisputes.clamped(to: 0...100)
        lastPlacementValue = max(0, lastPlacementValue)
    }
}

// C1: Dedicated state for the Content Creator / Influencer special career path.
enum CreatorPlatform: String, Codable, CaseIterable {
    case youtube
    case tiktokShorts
    case instagram
    case twitch
    case podcast
    case newsletter
    case generalSocial
}

struct CreatorState: Codable, Equatable {
    var platform: CreatorPlatform = .generalSocial
    var audience: Int = 25              // Followers / subscribers (core "valuation" equivalent)
    var algorithmFavor: Int = 50        // 0-100, swings with consistency, scandals, trends
    var personalBrand: Int = 40         // Authenticity vs sell-out tension (feeds FameProfile strongly)
    var contentQuality: Int = 50
    var consistency: Int = 55
    var burnout: Int = 20
    var cancellationRisk: Int = 15      // "Heat" equivalent for creators
    var brandDealValue: Int = 10        // Current sponsorship strength

    mutating func clamp() {
        audience = audience.clamped(to: 0...100)
        algorithmFavor = algorithmFavor.clamped(to: 0...100)
        personalBrand = personalBrand.clamped(to: 0...100)
        contentQuality = contentQuality.clamped(to: 10...95)
        consistency = consistency.clamped(to: 5...95)
        burnout = burnout.clamped(to: 0...95)
        cancellationRisk = cancellationRisk.clamped(to: 0...100)
        brandDealValue = brandDealValue.clamped(to: 0...100)
    }
}

// P1: Dedicated state for the Politics special career path.
struct PoliticsState: Codable, Equatable {
    var approvalRating: Int = 45           // Core "audience" equivalent — how much the public likes you
    var scandalHeat: Int = 10              // Current risk of damaging revelations (like heat/cancellation)
    var policyLegacy: Int = 20             // Long-term impact of your actual work
    var donorBase: Int = 25                // Financial power base
    var ethics: Int = 70                   // Personal integrity (affects options and reputation)
    var voterBase: Int = 30                // Strength of core supporters
    var charisma: Int = 50                 // Natural political talent
    var burnout: Int = 15                  // The grind of constant performance and scrutiny

    mutating func clamp() {
        approvalRating = approvalRating.clamped(to: 0...100)
        scandalHeat = scandalHeat.clamped(to: 0...100)
        policyLegacy = policyLegacy.clamped(to: 0...100)
        donorBase = donorBase.clamped(to: 0...100)
        ethics = ethics.clamped(to: 10...100)
        voterBase = voterBase.clamped(to: 0...100)
        charisma = charisma.clamped(to: 15...95)
        burnout = burnout.clamped(to: 0...95)
    }
}

// CE1: Dedicated state for the Crime & Enterprise paths (shadow operative, crime, trader, VC, raider)
enum CriminalEnterpriseSubtype: String, Codable, CaseIterable {
    case shadowOperative
    case streetCrime
    case grayMarketTrader
    case ventureCapitalist
    case corporateRaider
    /// Diamond-only branch: transnational logistics, industrial laundering, extreme exposure.
    case transnationalCartel
}

/// CT5: Three distinct crime experiences — street survival, crew organization, kingpin enterprise.
enum CrimeTier: String, Codable, CaseIterable {
    case street
    case organization
    case enterprise

    var displayName: String {
        switch self {
        case .street: return "Street / Independent"
        case .organization: return "Crew / Organization"
        case .enterprise: return "Enterprise / Kingpin"
        }
    }

    var heatProfile: CrimeHeatProfile {
        switch self {
        case .street: return .streetPatrol
        case .organization: return .organizedTaskForce
        case .enterprise: return .federalRICO
        }
    }

    func instantToolkit(cartelBranch: Bool = false) -> [ActionChoiceID] {
        switch self {
        case .street:
            return [.streetCornerHustle, .runScheme, .dodgePatrol, .layLow, .stepAway]
        case .organization:
            return [.holdTerritory, .buildCrew, .disciplineCrew, .runScheme, .payTheFixer, .burnEvidence, .cleanMoney, .layLow]
        case .enterprise:
            var tools: [ActionChoiceID] = [.delegateOperation, .launderThroughShell, .hostStrategicGala, .aggressiveTakeover, .ghostProtocol, .payTheFixer, .layLow]
            if cartelBranch {
                tools.insert(.connectCartelNetwork, at: 0)
            } else {
                tools.insert(.expandDomesticEmpire, at: 0)
            }
            return tools
        }
    }

    static func resolve(crime: CrimeState, specialCareer: SpecialCareerState) -> CrimeTier? {
        if specialCareer.track.isDiamondCareer
            || [.shadowOperative, .trader, .ventureCapitalist, .corporateRaider].contains(specialCareer.track) {
            return .enterprise
        }
        if specialCareer.track == .crime {
            return specialCareer.enterprise.subtype == .streetCrime ? .organization : .enterprise
        }
        guard crime.status != .inactive else { return nil }
        return crime.resolvedTier
    }
}

enum CrimeHeatProfile: String, Codable, CaseIterable {
    case streetPatrol
    case organizedTaskForce
    case federalRICO

    var label: String {
        switch self {
        case .streetPatrol: return "Street patrol & busts"
        case .organizedTaskForce: return "Organized crime task force"
        case .federalRICO: return "Federal / RICO pressure"
        }
    }
}

/// Diamond kingpin fork: domestic empire vs transnational cartel structures.
enum CrimeEmpireBranch: String, Codable, CaseIterable {
    case domesticKingpin
    case transnationalCartel
}

struct CriminalEnterpriseState: Codable, Equatable {
    var subtype: CriminalEnterpriseSubtype = .streetCrime
    var empireBranch: CrimeEmpireBranch? = nil
    var heat: Int = 20                    // Law enforcement / external scrutiny
    var notoriety: Int = 25               // Reputation in the underworld / gray economy
    var loyalty: Int = 50                 // Crew / key allies loyalty and trust
    var operationalSecurity: Int = 55     // How well you cover your tracks
    var networkStrength: Int = 30         // Quality and reach of connections
    var cleanMoneyRatio: Int = 25         // Percentage of wealth that appears legitimate (0-100)
    var riskTolerance: Int = 50           // Willingness to take bigger, riskier moves
    var crewSize: Int = 4
    var lastMajorScoreAge: Int = 0        // For narrative and cooldown logic
    var betrayalPressure: Int = 0         // Enterprise-tier lieutenant / succession risk

    mutating func clamp() {
        heat = heat.clamped(to: 0...100)
        notoriety = notoriety.clamped(to: 0...100)
        loyalty = loyalty.clamped(to: 0...100)
        operationalSecurity = operationalSecurity.clamped(to: 0...100)
        networkStrength = networkStrength.clamped(to: 0...100)
        cleanMoneyRatio = cleanMoneyRatio.clamped(to: 0...100)
        riskTolerance = riskTolerance.clamped(to: 10...90)
        crewSize = crewSize.clamped(to: 1...25)
        betrayalPressure = betrayalPressure.clamped(to: 0...100)
    }
}

enum AthleteSport: String, Codable, CaseIterable {
    case general
    case basketball
    case football
    case soccer
    case tennis
    case olympic
    case combatSports
}

enum CombatDiscipline: String, Codable, CaseIterable {
    case boxing
    case mma

    var promotionName: String {
        switch self {
        case .boxing: return "Ironline Boxing"
        case .mma: return "Cagefront MMA"
        }
    }

    var championshipOrganization: String {
        switch self {
        case .boxing: return "Continental Boxing Association"
        case .mma: return "Global Combat League"
        }
    }
}

enum CombatCareerStage: String, Codable, CaseIterable {
    case unselected
    case amateurProspect
    case regionalProfessional
    case rankedContender
    case champion
    case defendingChampion
    case retired
}

enum CombatWeightClass: String, Codable, CaseIterable {
    case flyweight
    case lightweight
    case welterweight
    case middleweight
    case heavyweight
}

enum CombatOpponentTier: String, Codable, CaseIterable {
    case safe
    case ranked
    case dangerous
}

enum CombatCampFocus: String, Codable, CaseIterable {
    case boxingPower
    case boxingTechnique
    case mmaStriking
    case mmaGrappling
    case conditioning
    case recovery
}

enum CombatFightStrategy: String, Codable, CaseIterable {
    case boxingPressure
    case boxingCounter
    case boxingOutside
    case mmaStrike
    case mmaWrestle
    case mmaMixed
}

struct CombatContract: Codable, Equatable {
    var promotionName: String = ""
    var fightsRemaining: Int = 0
    var basePurse: Int = 0
}

struct CombatOpponentOffer: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var tier: CombatOpponentTier
    var rating: Int
    var style: String
    var purse: Int
    var titleOpportunity: Bool
}

struct CombatSkillRatings: Codable, Equatable {
    var power: Int = 50
    var handSpeed: Int = 50
    var footwork: Int = 50
    var defense: Int = 50
    var striking: Int = 50
    var wrestling: Int = 50
    var submissions: Int = 50
    var takedownDefense: Int = 50
    var conditioning: Int = 55

    mutating func clamp() {
        power = power.clamped(to: 10...100)
        handSpeed = handSpeed.clamped(to: 10...100)
        footwork = footwork.clamped(to: 10...100)
        defense = defense.clamped(to: 10...100)
        striking = striking.clamped(to: 10...100)
        wrestling = wrestling.clamped(to: 10...100)
        submissions = submissions.clamped(to: 10...100)
        takedownDefense = takedownDefense.clamped(to: 10...100)
        conditioning = conditioning.clamped(to: 10...100)
    }
}

struct CombatCareerState: Codable, Equatable {
    var discipline: CombatDiscipline?
    var stage: CombatCareerStage = .unselected
    var weightClass: CombatWeightClass = .welterweight
    var wins: Int = 0
    var losses: Int = 0
    var draws: Int = 0
    var finishes: Int = 0
    var ranking: Int = 0
    var isChampion: Bool = false
    var titleDefenses: Int = 0
    var careerEarnings: Int = 0
    var activeContract: CombatContract = CombatContract()
    var suspensionYears: Int = 0
    var careerWear: Int = 0
    var opponentOffers: [CombatOpponentOffer] = []
    var scheduledOpponent: CombatOpponentOffer?
    var campFocus: CombatCampFocus?
    var fightStrategy: CombatFightStrategy?
    var crossoverUsed: Bool = false
    var lastFightAge: Int?
    var skills: CombatSkillRatings = CombatSkillRatings()

    var recordLabel: String { "\(wins)-\(losses)-\(draws)" }
    var fightReady: Bool {
        scheduledOpponent != nil && campFocus != nil && fightStrategy != nil && suspensionYears == 0 && stage != .retired
    }

    mutating func clamp() {
        wins = max(0, wins)
        losses = max(0, losses)
        draws = max(0, draws)
        finishes = max(0, min(finishes, wins))
        ranking = ranking.clamped(to: 0...50)
        titleDefenses = max(0, titleDefenses)
        careerEarnings = max(0, careerEarnings)
        activeContract.fightsRemaining = max(0, activeContract.fightsRemaining)
        activeContract.basePurse = max(0, activeContract.basePurse)
        suspensionYears = suspensionYears.clamped(to: 0...3)
        careerWear = careerWear.clamped(to: 0...100)
        opponentOffers = Array(opponentOffers.prefix(3))
        skills.clamp()
    }
}

struct FightProspect: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var discipline: CombatDiscipline
    var potential: Int
    var readiness: Int
    var trust: Int
}

struct FightEmpireState: Codable, Equatable {
    var originDiscipline: CombatDiscipline?
    var gymReputation: Int = 25
    var prospects: [FightProspect] = []
    var eventQuality: Int = 20
    var promotionReach: Int = 15
    var fighterTrust: Int = 55
    var regulatoryPressure: Int = 12
    var operatingCashPressure: Int = 25
    var lastEventProfit: Int = 0

    mutating func clamp() {
        gymReputation = gymReputation.clamped(to: 0...100)
        prospects = Array(prospects.prefix(8))
        eventQuality = eventQuality.clamped(to: 0...100)
        promotionReach = promotionReach.clamped(to: 0...100)
        fighterTrust = fighterTrust.clamped(to: 0...100)
        regulatoryPressure = regulatoryPressure.clamped(to: 0...100)
        operatingCashPressure = operatingCashPressure.clamped(to: 0...100)
    }
}

struct CombatFightSummary: Codable, Equatable, Identifiable {
    var id: String
    var age: Int
    var discipline: CombatDiscipline
    var opponentName: String
    var result: String
    var method: String
    var record: String
    var rankingText: String
    var purse: Int
    var fameDelta: Int
    var injuryText: String?
    var suspensionYears: Int
    var decisiveCauses: [String]
}

enum AthleteRetirementPath: String, Codable, CaseIterable {
    case coaching
    case business
    case media
    case philanthropy
    case politics
}

// MARK: - Fame Unification (Fame Web F1 foundation)

/// Unified fame / recognition profile. Every avenue that can make you "known" (athlete, entertainment,
/// crime, military, wealth, social, career peaks, events) should eventually feed this.
/// This replaces the previous total fragmentation between specialCareer.fame, athlete.personalBrand,
/// relationships.publicReputation, crime.notoriety, military medals, etc.
struct FameProfile: Codable, Equatable {
    /// Positive cultural recognition / household name status (0-100).
    /// "Pro athlete" or "local founder" sits low. "World champion / cultural icon" sits high.
    var culturalFame: Int = 0
    
    /// Dark / controversial recognition (fear, infamy, "that guy from the scandal").
    /// High notoriety creates different opportunities and much harsher downsides than culturalFame.
    var notoriety: Int = 0
    
    /// What the world associates you with. Merged from athlete accolades, career highlights,
    /// relationship knownForTags, military medals, viral moments, etc.
    var knownFor: [String] = []
    
    /// Age at which your fame peaked (for legacy narratives and "has-been" texture).
    var peakFameAge: Int? = nil
    
    /// Last age a major scandal or exposure hit (affects decay rate and "tainted" flavor).
    var lastScandalAge: Int? = nil
    
    mutating func clamp() {
        culturalFame = culturalFame.clamped(to: 0...100)
        notoriety = notoriety.clamped(to: 0...100)
        knownFor = Array(NSOrderedSet(array: knownFor.compactMap { $0.isEmpty ? nil : $0 }).array as? [String] ?? []).prefix(6).map { $0 }
        if culturalFame == 0 && notoriety == 0 {
            peakFameAge = nil
        }
    }
    
    /// Combined "how known are you?" signal used for many cross-domain rolls.
    var recognition: Int {
        max(culturalFame, notoriety)
    }
    
    var isPublicFigure: Bool { recognition >= 45 }
    var isHouseholdName: Bool { culturalFame >= 70 }
    var isInfamous: Bool { notoriety >= 65 }
}

struct CareerState: Codable, Equatable {
    var status: CareerStatus = .student
    var profile: CareerProfile = .stableAdmin
    var specializedTrack: SpecializedCareerTrack? = nil
    /// D3: Regular career archetype set by static always-instant actions (corporateClimb etc).
    /// Drives differentiated curves (perf/burnout/security/income/aging) + flavor + handoff.
    /// Nil for special-track lives (they use their deep state instead).
    var regularArchetype: CareerArchetype? = nil
    var professionalRank: String = "Entry Level"
    var workIdentity: WorkIdentity = .unsettled
    var roleID: String? = nil
    var level: Int = 0
    var annualIncome: Int = 0
    var performance: Int = 52
    var yearsWorked: Int = 0
    var unemployedYears: Int = 0
    var burnout: Int = 18
    var schedulePressure: Int = 22
    var relationshipSpillover: Int = 16
    var jobSecurity: Int = 52
    var managerFriction: Int = 34
    var scheduleControl: Int = 50
    var retrainingProgress: Int = 0
    var retrainingTargetProfile: CareerProfile? = nil
    var activeOpportunityDoor: CareerOpportunityDoor? = nil
    var opportunityDoorYearsRemaining: Int = 0
    var ambitionYears: Int = 0
    var protectiveYears: Int = 0
    var hustleYears: Int = 0
    var driftYears: Int = 0
    var careerExperience: [CareerExperienceTag: Int] = [:]

    private enum CodingKeys: String, CodingKey {
        case status
        case profile
        case specializedTrack
        case regularArchetype  // D3
        case professionalRank
        case workIdentity
        case roleID
        case level
        case annualIncome
        case performance
        case yearsWorked
        case unemployedYears
        case burnout
        case schedulePressure
        case relationshipSpillover
        case jobSecurity
        case managerFriction
        case scheduleControl
        case retrainingProgress
        case retrainingTargetProfile
        case activeOpportunityDoor
        case opportunityDoorYearsRemaining
        case ambitionYears
        case protectiveYears
        case hustleYears
        case driftYears
        case careerExperience
    }

    init() {}

    init(
        status: CareerStatus = .student,
        profile: CareerProfile = .stableAdmin,
        workIdentity: WorkIdentity = .unsettled,
        roleID: String? = nil,
        level: Int = 0,
        annualIncome: Int = 0,
        performance: Int = 52,
        yearsWorked: Int = 0,
        unemployedYears: Int = 0,
        burnout: Int = 18,
        schedulePressure: Int = 22,
        relationshipSpillover: Int = 16,
        jobSecurity: Int = 52,
        managerFriction: Int = 34,
        scheduleControl: Int = 50,
        retrainingProgress: Int = 0,
        retrainingTargetProfile: CareerProfile? = nil,
        activeOpportunityDoor: CareerOpportunityDoor? = nil,
        opportunityDoorYearsRemaining: Int = 0,
        ambitionYears: Int = 0,
        protectiveYears: Int = 0,
        hustleYears: Int = 0,
        driftYears: Int = 0,
        careerExperience: [CareerExperienceTag: Int] = [:],
        regularArchetype: CareerArchetype? = nil  // D3
    ) {
        self.status = status
        self.profile = profile
        self.workIdentity = workIdentity
        self.roleID = roleID
        self.level = level
        self.annualIncome = annualIncome
        self.performance = performance
        self.yearsWorked = yearsWorked
        self.unemployedYears = unemployedYears
        self.burnout = burnout
        self.schedulePressure = schedulePressure
        self.relationshipSpillover = relationshipSpillover
        self.jobSecurity = jobSecurity
        self.managerFriction = managerFriction
        self.scheduleControl = scheduleControl
        self.retrainingProgress = retrainingProgress
        self.retrainingTargetProfile = retrainingTargetProfile
        self.activeOpportunityDoor = activeOpportunityDoor
        self.opportunityDoorYearsRemaining = opportunityDoorYearsRemaining
        self.ambitionYears = ambitionYears
        self.protectiveYears = protectiveYears
        self.hustleYears = hustleYears
        self.driftYears = driftYears
        self.careerExperience = careerExperience
        self.regularArchetype = regularArchetype
        clamp()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(CareerStatus.self, forKey: .status) ?? .student
        profile = try container.decodeIfPresent(CareerProfile.self, forKey: .profile) ?? .stableAdmin
        specializedTrack = try container.decodeIfPresent(SpecializedCareerTrack.self, forKey: .specializedTrack)
        regularArchetype = try container.decodeIfPresent(CareerArchetype.self, forKey: .regularArchetype)
        professionalRank = try container.decodeIfPresent(String.self, forKey: .professionalRank) ?? "Entry Level"
        workIdentity = try container.decodeIfPresent(WorkIdentity.self, forKey: .workIdentity) ?? .unsettled
        roleID = try container.decodeIfPresent(String.self, forKey: .roleID)
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 0
        annualIncome = try container.decodeIfPresent(Int.self, forKey: .annualIncome) ?? 0
        performance = try container.decodeIfPresent(Int.self, forKey: .performance) ?? 52
        yearsWorked = try container.decodeIfPresent(Int.self, forKey: .yearsWorked) ?? 0
        unemployedYears = try container.decodeIfPresent(Int.self, forKey: .unemployedYears) ?? 0
        burnout = try container.decodeIfPresent(Int.self, forKey: .burnout) ?? 18
        schedulePressure = try container.decodeIfPresent(Int.self, forKey: .schedulePressure) ?? 22
        relationshipSpillover = try container.decodeIfPresent(Int.self, forKey: .relationshipSpillover) ?? 16
        jobSecurity = try container.decodeIfPresent(Int.self, forKey: .jobSecurity) ?? 52
        managerFriction = try container.decodeIfPresent(Int.self, forKey: .managerFriction) ?? 34
        scheduleControl = try container.decodeIfPresent(Int.self, forKey: .scheduleControl) ?? 50
        retrainingProgress = try container.decodeIfPresent(Int.self, forKey: .retrainingProgress) ?? 0
        retrainingTargetProfile = try container.decodeIfPresent(CareerProfile.self, forKey: .retrainingTargetProfile)
        activeOpportunityDoor = try container.decodeIfPresent(CareerOpportunityDoor.self, forKey: .activeOpportunityDoor)
        opportunityDoorYearsRemaining = try container.decodeIfPresent(Int.self, forKey: .opportunityDoorYearsRemaining) ?? 0
        ambitionYears = try container.decodeIfPresent(Int.self, forKey: .ambitionYears) ?? 0
        protectiveYears = try container.decodeIfPresent(Int.self, forKey: .protectiveYears) ?? 0
        hustleYears = try container.decodeIfPresent(Int.self, forKey: .hustleYears) ?? 0
        driftYears = try container.decodeIfPresent(Int.self, forKey: .driftYears) ?? 0
        careerExperience = try container.decodeIfPresent([CareerExperienceTag: Int].self, forKey: .careerExperience) ?? [:]
        clamp()
    }

    mutating func clamp() {
        level = max(0, level)
        annualIncome = max(0, annualIncome)
        performance = performance.clamped(to: 0...100)
        yearsWorked = max(0, yearsWorked)
        unemployedYears = max(0, unemployedYears)
        burnout = burnout.clamped(to: 0...100)
        schedulePressure = schedulePressure.clamped(to: 0...100)
        relationshipSpillover = relationshipSpillover.clamped(to: 0...100)
        jobSecurity = jobSecurity.clamped(to: 0...100)
        managerFriction = managerFriction.clamped(to: 0...100)
        scheduleControl = scheduleControl.clamped(to: 0...100)
        retrainingProgress = retrainingProgress.clamped(to: 0...3)
        opportunityDoorYearsRemaining = opportunityDoorYearsRemaining.clamped(to: 0...2)
        if opportunityDoorYearsRemaining == 0 {
            activeOpportunityDoor = nil
        }
        ambitionYears = max(0, ambitionYears)
        protectiveYears = max(0, protectiveYears)
        hustleYears = max(0, hustleYears)
        driftYears = max(0, driftYears)
        careerExperience = careerExperience.mapValues { max(0, $0) }.filter { $0.value > 0 }
    }

    func experience(for tag: CareerExperienceTag) -> Int {
        careerExperience[tag] ?? 0
    }

    var strongestExperienceTag: CareerExperienceTag? {
        careerExperience.max { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.rawValue < rhs.key.rawValue
            }
            return lhs.value < rhs.value
        }?.key
    }
}

struct SpecialCareerState: Codable, Equatable {
    var track: SpecialCareerTrack = .inactive
    var sector: BusinessSector = .general
    var advisors: [BusinessAdvisor] = []
    var tier: Int = 0
    var fame: Int = 0
    var audience: Int = 0
    var heat: Int = 0
    var notoriety: Int = 0
    var burnout: Int = 0
    var yearsActive: Int = 0
    var lastPayout: Int = 0

    // Diamond pipeline provenance. Optional/defaulted fields preserve legacy saves.
    var diamondOriginTrack: SpecialCareerTrack?
    var firstDiamondEntryAge: Int?
    var diamondTransitions: Int = 0
    
    // Entrepreneur/VC/Raider Extension
    var equityOwned: Double = 1.0 // 0.0 to 1.0
    var boardPressure: Int = 0 // 0-100, if 100, you are ousted
    var capitalUnderManagement: Int = 0 // For VC/Raider

    // Phase S1: Athlete dedicated state (only used when track == .athlete)
    var athlete: AthleteState = AthleteState()

    // E1: Dedicated Founder / CEO state (only used when track == .founder or related)
    var founder: FounderState = FounderState()

    // Film business: Dedicated Movie Actor state
    var movieActor: MovieActorState = MovieActorState()

    // Music business: Dedicated Music Producer state
    var musicProducer: MusicProducerState = MusicProducerState()

    // Film business: Dedicated Movie Producer state
    var movieProducer: MovieProducerState = MovieProducerState()

    // Music business: Dedicated Record Label Owner state
    var recordLabel: RecordLabelState = RecordLabelState()

    // Sports management: Dedicated Program Coach state
    var coaching: CoachingState = CoachingState()

    // C1: Dedicated Content Creator / Influencer state
    var creator: CreatorState = CreatorState()

    // P1: Dedicated Politics state
    var politics: PoliticsState = PoliticsState()

    // CE1: Dedicated Criminal Enterprise state (shadow operative, crime, trader, VC, raider)
    var enterprise: CriminalEnterpriseState = CriminalEnterpriseState()

    // Combat Diamond: gym and promotion ownership after elite fighting.
    var fightEmpire: FightEmpireState = FightEmpireState()

    private enum CodingKeys: String, CodingKey {
        case track
        case tier
        case fame
        case audience
        case heat
        case notoriety
        case burnout
        case yearsActive
        case lastPayout
        case sector
        case advisors
        case equityOwned
        case boardPressure
        case capitalUnderManagement
        case diamondOriginTrack
        case firstDiamondEntryAge
        case diamondTransitions
        case athlete
        case founder     // E1
        case movieActor
        case musicProducer
        case movieProducer
        case recordLabel
        case coaching
        case creator     // C1
        case politics    // P1
        case enterprise  // CE1
        case fightEmpire
    }

    init() {}

    init(
        track: SpecialCareerTrack = .inactive,
        tier: Int = 0,
        fame: Int = 0,
        audience: Int = 0,
        heat: Int = 0,
        notoriety: Int = 0,
        burnout: Int = 0,
        yearsActive: Int = 0,
        lastPayout: Int = 0
    ) {
        self.track = track
        self.tier = tier
        self.fame = fame
        self.audience = audience
        self.heat = heat
        self.notoriety = notoriety
        self.burnout = burnout
        self.yearsActive = yearsActive
        self.lastPayout = lastPayout
        clamp()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        track = try container.decodeIfPresent(SpecialCareerTrack.self, forKey: .track) ?? .inactive
        tier = try container.decodeIfPresent(Int.self, forKey: .tier) ?? 0
        fame = try container.decodeIfPresent(Int.self, forKey: .fame) ?? 0
        audience = try container.decodeIfPresent(Int.self, forKey: .audience) ?? 0
        heat = try container.decodeIfPresent(Int.self, forKey: .heat) ?? 0
        notoriety = try container.decodeIfPresent(Int.self, forKey: .notoriety) ?? 0
        burnout = try container.decodeIfPresent(Int.self, forKey: .burnout) ?? 0
        yearsActive = try container.decodeIfPresent(Int.self, forKey: .yearsActive) ?? 0
        lastPayout = try container.decodeIfPresent(Int.self, forKey: .lastPayout) ?? 0
        sector = try container.decodeIfPresent(BusinessSector.self, forKey: .sector) ?? .general
        advisors = try container.decodeIfPresent([BusinessAdvisor].self, forKey: .advisors) ?? []
        equityOwned = try container.decodeIfPresent(Double.self, forKey: .equityOwned) ?? 1.0
        boardPressure = try container.decodeIfPresent(Int.self, forKey: .boardPressure) ?? 0
        capitalUnderManagement = try container.decodeIfPresent(Int.self, forKey: .capitalUnderManagement) ?? 0
        diamondOriginTrack = try container.decodeIfPresent(SpecialCareerTrack.self, forKey: .diamondOriginTrack)
        firstDiamondEntryAge = try container.decodeIfPresent(Int.self, forKey: .firstDiamondEntryAge)
        diamondTransitions = try container.decodeIfPresent(Int.self, forKey: .diamondTransitions) ?? 0
        athlete = try container.decodeIfPresent(AthleteState.self, forKey: .athlete) ?? AthleteState()
        founder = try container.decodeIfPresent(FounderState.self, forKey: .founder) ?? FounderState()
        movieActor = try container.decodeIfPresent(MovieActorState.self, forKey: .movieActor) ?? MovieActorState()
        musicProducer = try container.decodeIfPresent(MusicProducerState.self, forKey: .musicProducer) ?? MusicProducerState()
        movieProducer = try container.decodeIfPresent(MovieProducerState.self, forKey: .movieProducer) ?? MovieProducerState()
        recordLabel = try container.decodeIfPresent(RecordLabelState.self, forKey: .recordLabel) ?? RecordLabelState()
        coaching = try container.decodeIfPresent(CoachingState.self, forKey: .coaching) ?? CoachingState()
        creator = try container.decodeIfPresent(CreatorState.self, forKey: .creator) ?? CreatorState()
        politics = try container.decodeIfPresent(PoliticsState.self, forKey: .politics) ?? PoliticsState()
        enterprise = try container.decodeIfPresent(CriminalEnterpriseState.self, forKey: .enterprise) ?? CriminalEnterpriseState()
        fightEmpire = try container.decodeIfPresent(FightEmpireState.self, forKey: .fightEmpire) ?? FightEmpireState()
        clamp()
    }

    mutating func clamp() {
        tier = tier.clamped(to: 0...3)
        fame = fame.clamped(to: 0...100)
        audience = audience.clamped(to: 0...100)
        heat = heat.clamped(to: 0...100)
        notoriety = notoriety.clamped(to: 0...100)
        burnout = burnout.clamped(to: 0...100)
        yearsActive = max(0, yearsActive)
        lastPayout = max(0, lastPayout)
        diamondTransitions = max(0, diamondTransitions)
        boardPressure = boardPressure.clamped(to: 0...100)
        equityOwned = equityOwned.clamped(to: 0...1)
        capitalUnderManagement = max(0, capitalUnderManagement)
        founder.clamp()
        movieActor.clamp()
        musicProducer.clamp()
        movieProducer.clamp()
        recordLabel.clamp()
        coaching.clamp()
        creator.clamp()
        politics.clamp()
        enterprise.clamp()
        fightEmpire.clamp()
    }
}

enum CrimeStatus: String, Codable, CaseIterable {
    case inactive
    case active
    case layingLow
}

struct CrimeState: Codable, Equatable {
    var status: CrimeStatus = .inactive
    var roleTier: Int = 0
    var tier: CrimeTier = .street
    var heatProfile: CrimeHeatProfile = .streetPatrol
    var heat: Int = 0
    var notoriety: Int = 0
    var burnout: Int = 0
    var crewID: String? = nil
    var loyalty: Int = 0
    var territoryPressure: Int = 0
    var personalRisk: Int = 0
    var betrayalPressure: Int = 0
    var yearsActive: Int = 0
    var lastPayout: Int = 0

    var resolvedTier: CrimeTier {
        switch roleTier {
        case 3: return .enterprise
        case 2: return .organization
        default: return tier
        }
    }

    private enum CodingKeys: String, CodingKey {
        case status
        case roleTier
        case tier
        case heatProfile
        case heat
        case notoriety
        case burnout
        case crewID
        case loyalty
        case territoryPressure
        case personalRisk
        case betrayalPressure
        case yearsActive
        case lastPayout
    }

    init() {}

    init(
        status: CrimeStatus = .inactive,
        roleTier: Int = 0,
        tier: CrimeTier = .street,
        heatProfile: CrimeHeatProfile = .streetPatrol,
        heat: Int = 0,
        notoriety: Int = 0,
        burnout: Int = 0,
        crewID: String? = nil,
        loyalty: Int = 0,
        territoryPressure: Int = 0,
        personalRisk: Int = 0,
        betrayalPressure: Int = 0,
        yearsActive: Int = 0,
        lastPayout: Int = 0
    ) {
        self.status = status
        self.roleTier = roleTier
        self.tier = tier
        self.heatProfile = heatProfile
        self.heat = heat
        self.notoriety = notoriety
        self.burnout = burnout
        self.crewID = crewID
        self.loyalty = loyalty
        self.territoryPressure = territoryPressure
        self.personalRisk = personalRisk
        self.betrayalPressure = betrayalPressure
        self.yearsActive = yearsActive
        self.lastPayout = lastPayout
        clamp()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(CrimeStatus.self, forKey: .status) ?? .inactive
        roleTier = try container.decodeIfPresent(Int.self, forKey: .roleTier) ?? 0
        tier = try container.decodeIfPresent(CrimeTier.self, forKey: .tier) ?? .street
        heatProfile = try container.decodeIfPresent(CrimeHeatProfile.self, forKey: .heatProfile) ?? .streetPatrol
        heat = try container.decodeIfPresent(Int.self, forKey: .heat) ?? 0
        notoriety = try container.decodeIfPresent(Int.self, forKey: .notoriety) ?? 0
        burnout = try container.decodeIfPresent(Int.self, forKey: .burnout) ?? 0
        crewID = try container.decodeIfPresent(String.self, forKey: .crewID)
        loyalty = try container.decodeIfPresent(Int.self, forKey: .loyalty) ?? 0
        territoryPressure = try container.decodeIfPresent(Int.self, forKey: .territoryPressure) ?? 0
        personalRisk = try container.decodeIfPresent(Int.self, forKey: .personalRisk) ?? 0
        betrayalPressure = try container.decodeIfPresent(Int.self, forKey: .betrayalPressure) ?? 0
        yearsActive = try container.decodeIfPresent(Int.self, forKey: .yearsActive) ?? 0
        lastPayout = try container.decodeIfPresent(Int.self, forKey: .lastPayout) ?? 0
        clamp()
    }

    mutating func syncTierMetadata() {
        let resolved = resolvedTier
        tier = resolved
        heatProfile = resolved.heatProfile
    }

    mutating func clamp() {
        roleTier = roleTier.clamped(to: 0...3)
        heat = heat.clamped(to: 0...100)
        notoriety = notoriety.clamped(to: 0...100)
        burnout = burnout.clamped(to: 0...100)
        loyalty = loyalty.clamped(to: 0...100)
        territoryPressure = territoryPressure.clamped(to: 0...100)
        personalRisk = personalRisk.clamped(to: 0...100)
        betrayalPressure = betrayalPressure.clamped(to: 0...100)
        yearsActive = max(0, yearsActive)
        lastPayout = max(0, lastPayout)
        if status != .inactive {
            syncTierMetadata()
        }
        if status == .inactive {
            roleTier = 0
            tier = .street
            heatProfile = .streetPatrol
            heat = 0
            notoriety = 0
            crewID = nil
            loyalty = 0
            territoryPressure = 0
            personalRisk = 0
            betrayalPressure = 0
            yearsActive = 0
            lastPayout = 0
            burnout = min(35, burnout)
        }
    }

    static func migratingFromLegacySpecialCareer(_ specialCareer: SpecialCareerState) -> CrimeState {
        let mappedTier: CrimeTier = specialCareer.tier >= 3 ? .enterprise : (specialCareer.tier >= 2 ? .organization : .street)
        return CrimeState(
            status: .active,
            roleTier: specialCareer.tier,
            tier: mappedTier,
            heatProfile: mappedTier.heatProfile,
            heat: 40,
            notoriety: 35,
            burnout: specialCareer.burnout,
            crewID: nil,
            loyalty: 30,
            territoryPressure: 20,
            personalRisk: mappedTier == .street ? 55 : 25,
            betrayalPressure: mappedTier == .enterprise ? 20 : 0,
            yearsActive: specialCareer.yearsActive,
            lastPayout: specialCareer.lastPayout
        )
    }
}

enum CustodyFacility: String, Codable, CaseIterable {
    case countyJail
    case statePrison
    case federalPen

    var displayName: String {
        switch self {
        case .countyJail: return "County Jail"
        case .statePrison: return "State Prison"
        case .federalPen: return "Federal Penitentiary"
        }
    }

    static func resolve(sentenceYears: Int, severity: LegalOffenseSeverity, offense: LegalOffenseKind) -> CustodyFacility {
        if offense == .enterpriseCrime || severity == .aggravated || sentenceYears >= 8 {
            return .federalPen
        }
        if sentenceYears <= 1 || severity <= .moderate {
            return .countyJail
        }
        return .statePrison
    }
}

enum PrisonFaction: String, Codable, CaseIterable {
    case oldGuard
    case newBlood

    var displayName: String {
        switch self {
        case .oldGuard: return "Old Guard"
        case .newBlood: return "New Blood"
        }
    }
}

enum CustodyExperienceTier: String, Codable, CaseIterable {
    case street
    case organization
    case enterprise

    var displayName: String {
        switch self {
        case .street: return "Street Bid"
        case .organization: return "Organization Bid"
        case .enterprise: return "Enterprise Bid"
        }
    }

    static func resolve(
        offense: LegalOffenseKind,
        crimeTier: CrimeTier?,
        notoriety: Int
    ) -> CustodyExperienceTier {
        if offense == .enterpriseCrime || notoriety >= 55 || crimeTier == .enterprise {
            return .enterprise
        }
        if offense == .organizedCrime || crimeTier == .organization {
            return .organization
        }
        return .street
    }
}

enum CustodySecurityRegime: String, Codable, CaseIterable {
    case standard
    case heightened
    case maximum

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .heightened: return "Heightened Security"
        case .maximum: return "Maximum Security"
        }
    }

    static func resolve(
        priorConvictionCount: Int,
        severity: LegalOffenseSeverity,
        offense: LegalOffenseKind,
        cooperated: Bool = false,
        snitchRisk: Int = 0
    ) -> CustodySecurityRegime {
        if priorConvictionCount >= 3 || offense == .enterpriseCrime || (cooperated && snitchRisk >= 40) {
            return .maximum
        }
        if priorConvictionCount >= 2 || severity >= .serious {
            return .heightened
        }
        return .standard
    }
}

struct OutsideEmpireSnapshot: Codable, Equatable {
    var loyalty: Int = 50
    var networkStrength: Int = 30
    var cleanMoneyRatio: Int = 25
    var heat: Int = 20
    var betrayalPressure: Int = 0
}

struct PrisonResidue: Codable, Equatable {
    var tags: [String] = []
    var yearsRemaining: Int = 0
    var experienceTier: CustodyExperienceTier = .street
    var recordPressureFloor: Int = 0
}

struct CustodyProfile: Codable, Equatable {
    var facility: CustodyFacility = .countyJail
    var experienceTier: CustodyExperienceTier = .street
    var securityRegime: CustodySecurityRegime = .standard
    var conductScore: Int = 50
    var infractions: Int = 0
    var violenceRisk: Int = 20
    var yardReputation: Int = 30
    var faction: PrisonFaction? = nil
    var factionLoyalty: Int = 0
    var protectionDebt: Int = 0
    var snitchRisk: Int = 0
    var cooperatedWithAuthorities: Bool = false
    var programProgress: Int = 0
    var goodTimeCredits: Int = 0
    var lockdownYearsRemaining: Int = 0
    var paroleHearingDeniedYears: Int = 0
    var familyCallsThisYear: Int = 0
    var discretionaryActionsRemaining: Int = 0
    var lifetimeFamilyContactsMax: Int = 0
    var totalFamilyCallsMade: Int = 0
    var outsideEmpireSnapshot: OutsideEmpireSnapshot? = nil

    static let discretionaryActionIDs: Set<ActionChoiceID> = [
        .standYourGround, .alignWithFaction, .payProtection, .refuseSnitchDeal, .cooperateWithGuards,
        .prisonWorkDetail, .studyProgram, .fileAppeal,
        .delegateFromInside, .callLieutenant, .authorizeOutsideMove
    ]

    static func sentenceBudget(for sentenceYears: Int) -> Int {
        min(6, max(4, sentenceYears))
    }

    static func familyContactCap(for sentenceYears: Int) -> Int {
        min(4, max(2, sentenceYears / 2 + 1))
    }

    func instantToolkit(
        paroleEligible: Bool,
        lockdown: Bool,
        enterpriseProxyEligible: Bool
    ) -> [ActionChoiceID] {
        if lockdown {
            var lockdownTools: [ActionChoiceID] = [.keepHeadDown]
            if totalFamilyCallsMade < lifetimeFamilyContactsMax {
                lockdownTools.append(.callFamily)
            }
            return lockdownTools
        }

        var tools: [ActionChoiceID] = [.keepHeadDown]

        switch experienceTier {
        case .street:
            tools.append(contentsOf: [.standYourGround, .prisonWorkDetail, .studyProgram])
        case .organization:
            tools.append(contentsOf: [.alignWithFaction, .payProtection, .studyProgram])
        case .enterprise:
            tools.append(contentsOf: [.studyProgram, .refuseSnitchDeal])
            if enterpriseProxyEligible {
                tools.append(contentsOf: [.delegateFromInside, .callLieutenant, .authorizeOutsideMove])
            }
        }

        if discretionaryActionsRemaining > 0, experienceTier != .enterprise {
            tools.append(.fileAppeal)
        }

        if totalFamilyCallsMade < lifetimeFamilyContactsMax {
            tools.append(.callFamily)
        }
        if paroleEligible {
            tools.append(.requestParoleHearing)
        }

        return Array(NSOrderedSet(array: tools).array as? [ActionChoiceID] ?? tools).prefix(7).map { $0 }
    }

    mutating func clamp() {
        conductScore = conductScore.clamped(to: 0...100)
        infractions = max(0, infractions)
        violenceRisk = violenceRisk.clamped(to: 0...100)
        yardReputation = yardReputation.clamped(to: 0...100)
        factionLoyalty = factionLoyalty.clamped(to: 0...100)
        protectionDebt = protectionDebt.clamped(to: 0...100)
        snitchRisk = snitchRisk.clamped(to: 0...100)
        programProgress = programProgress.clamped(to: 0...100)
        goodTimeCredits = max(0, goodTimeCredits)
        lockdownYearsRemaining = max(0, lockdownYearsRemaining)
        paroleHearingDeniedYears = max(0, paroleHearingDeniedYears)
        familyCallsThisYear = max(0, familyCallsThisYear)
        discretionaryActionsRemaining = max(0, discretionaryActionsRemaining)
        lifetimeFamilyContactsMax = max(0, lifetimeFamilyContactsMax)
        totalFamilyCallsMade = max(0, totalFamilyCallsMade)
    }

    mutating func resetYearlyCounters() {
        familyCallsThisYear = 0
    }

    mutating func spendDiscretionaryAction(for choiceID: ActionChoiceID) -> Bool {
        guard Self.discretionaryActionIDs.contains(choiceID) else { return true }
        guard discretionaryActionsRemaining > 0 else { return false }
        discretionaryActionsRemaining -= 1
        return true
    }
}

enum LegalCaseStage: String, Codable, CaseIterable {
    case inactive
    case investigation
    case charged
    case awaitingResolution
    case supervision
    case custody
    case released
}

enum LegalJurisdiction: String, Codable, CaseIterable {
    case civilian
    case military
}

enum LegalOffenseSeverity: Int, Codable, CaseIterable, Comparable {
    case minor = 1
    case moderate = 2
    case serious = 3
    case aggravated = 4

    static func < (lhs: LegalOffenseSeverity, rhs: LegalOffenseSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum LegalOffenseKind: String, Codable, CaseIterable {
    case streetCrime
    case organizedCrime
    case enterpriseCrime
    case illegalWeapon
    case militaryDesertion
}

enum LegalDecision: String, Codable, CaseIterable {
    case none
    case retainCounsel
    case cooperate
    case refuseInterview
    case negotiatePlea
    case fightCharges
    case postBail
    case comply
    case requestEarlyRelease
}

enum LegalDisposition: String, Codable, CaseIterable {
    case none
    case dismissed
    case acquitted
    case pleaAgreement
    case convicted
    case probation
    case paroled
    case released
}

struct LegalExposure: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var source: String
    var offense: LegalOffenseKind
    var severity: LegalOffenseSeverity
    var evidence: Int
    var jurisdiction: LegalJurisdiction = .civilian
    var involvesWeapon: Bool = false
    var immediateCharge: Bool = false

    mutating func clamp() {
        evidence = evidence.clamped(to: 0...100)
    }
}

struct LegalConviction: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var age: Int
    var offense: LegalOffenseKind
    var severity: LegalOffenseSeverity
    var jurisdiction: LegalJurisdiction
    var sentenceYears: Int
    var fine: Int
}

struct LegalState: Codable, Equatable {
    var stage: LegalCaseStage = .inactive
    var jurisdiction: LegalJurisdiction = .civilian
    var caseSeverity: LegalOffenseSeverity = .minor
    var allegedOffenses: [LegalOffenseKind] = []
    var pendingExposures: [LegalExposure] = []
    var evidenceStrength: Int = 0
    var counselQuality: Int = 0
    var bailAmount: Int = 0
    var bailPosted: Bool = false
    var pendingDecision: LegalDecision = .none
    var lastDisposition: LegalDisposition = .none
    var convictions: [LegalConviction] = []
    var outstandingFines: Int = 0
    var seizedAssetValue: Int = 0
    var sentenceYears: Int = 0
    var timeServed: Int = 0
    var paroleEligibleAfter: Int = 0
    var supervisionYearsRemaining: Int = 0
    var cleanYears: Int = 0
    var recordPressure: Int = 0
    var custodyStartedAge: Int? = nil
    var lastProcessedAge: Int? = nil
    var custodyProfile: CustodyProfile = CustodyProfile()
    var reentryYearsRemaining: Int = 0
    var prisonResidue: PrisonResidue? = nil

    var isInCustody: Bool { stage == .custody }
    var hasActiveCase: Bool {
        [.investigation, .charged, .awaitingResolution].contains(stage)
    }
    var yearsRemaining: Int { max(0, sentenceYears - effectiveTimeServed) }
    var effectiveTimeServed: Int { timeServed + custodyProfile.goodTimeCredits }
    var paroleEligible: Bool { effectiveTimeServed >= paroleEligibleAfter && paroleEligibleAfter > 0 }

    mutating func clamp() {
        evidenceStrength = evidenceStrength.clamped(to: 0...100)
        counselQuality = counselQuality.clamped(to: 0...100)
        bailAmount = max(0, bailAmount)
        outstandingFines = max(0, outstandingFines)
        seizedAssetValue = max(0, seizedAssetValue)
        sentenceYears = max(0, sentenceYears)
        timeServed = timeServed.clamped(to: 0...sentenceYears)
        paroleEligibleAfter = paroleEligibleAfter.clamped(to: 0...sentenceYears)
        supervisionYearsRemaining = max(0, supervisionYearsRemaining)
        cleanYears = max(0, cleanYears)
        recordPressure = recordPressure.clamped(to: 0...100)
        reentryYearsRemaining = max(0, reentryYearsRemaining)
        if var residue = prisonResidue {
            residue.yearsRemaining = max(0, residue.yearsRemaining)
            prisonResidue = residue
        }
        custodyProfile.clamp()
        pendingExposures = pendingExposures.map {
            var exposure = $0
            exposure.clamp()
            return exposure
        }
    }
}

struct CareerRoleDefinition: Equatable {
    var id: String
    var title: String
    var profile: CareerProfile
    var status: CareerStatus
    var level: Int
    var annualIncome: Int
    var minAge: Int
    var nextRoleID: String?
    var requiredCredentials: [String] = []
    var minimumYearsWorked: Int = 0
    var primaryExperienceTag: CareerExperienceTag = .admin
    var secondaryExperienceTags: [CareerExperienceTag] = []
    var bridgeTags: [CareerExperienceTag] = []
    var isManagementRole: Bool = false
}

