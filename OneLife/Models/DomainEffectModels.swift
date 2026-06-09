import Foundation

struct ConsequenceState: Codable, Equatable {
    var narrativeFlags: [String: Int] = [:]
    var pressureByDomain: [String: Int] = [:]
    var scheduledEvents: [ScheduledConsequenceEvent] = []

    init() {}

    mutating func adjustPressure(domain: String, delta: Int) {
        let current = pressureByDomain[domain, default: 0]
        let nextValue = (current + delta).clamped(to: 0...100)
        if nextValue == 0 {
            pressureByDomain.removeValue(forKey: domain)
        } else {
            pressureByDomain[domain] = nextValue
        }
    }

    mutating func softenAllPressure(by amount: Int) {
        guard amount > 0 else { return }
        for key in pressureByDomain.keys {
            let nextValue = max(0, pressureByDomain[key, default: 0] - amount)
            if nextValue == 0 {
                pressureByDomain.removeValue(forKey: key)
            } else {
                pressureByDomain[key] = nextValue
            }
        }
    }
}

struct ScheduledConsequenceEvent: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var eventID: String
    var dueAge: Int
    var title: String? = nil
    var detail: String? = nil
    var sourceEventID: String? = nil
    var sourceEventTitle: String? = nil
    var sourceChoiceText: String? = nil
    var callbackFramingText: String? = nil
}

struct ConsequenceEffects: Codable, Equatable {
    var setFlags: [String] = []
    var clearFlags: [String] = []
    var pressureChanges: [String: Int] = [:]
    var scheduleEvents: [ScheduledEventTrigger] = []

    private enum CodingKeys: String, CodingKey {
        case setFlags
        case clearFlags
        case pressureChanges
        case scheduleEvents
    }

    init(
        setFlags: [String] = [],
        clearFlags: [String] = [],
        pressureChanges: [String: Int] = [:],
        scheduleEvents: [ScheduledEventTrigger] = []
    ) {
        self.setFlags = setFlags
        self.clearFlags = clearFlags
        self.pressureChanges = pressureChanges
        self.scheduleEvents = scheduleEvents
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        setFlags = try container.decodeIfPresent([String].self, forKey: .setFlags) ?? []
        clearFlags = try container.decodeIfPresent([String].self, forKey: .clearFlags) ?? []
        pressureChanges = try container.decodeIfPresent([String: Int].self, forKey: .pressureChanges) ?? [:]
        scheduleEvents = try container.decodeIfPresent([ScheduledEventTrigger].self, forKey: .scheduleEvents) ?? []
    }
}
struct CoreStatDelta: Equatable {
    var happiness: Int = 0
    var smarts: Int = 0
    var looks: Int = 0
    var health: Int = 0
}

struct FinanceDelta: Equatable {
    var cash: Int = 0
}
struct AssetEffects: Codable, Equatable {
    var addFirearm: Firearm? = nil
    var removeFirearmID: UUID? = nil
    var upgradeFirearmID: UUID? = nil
    var addUpgrade: WeaponUpgrade? = nil
    
    var addVehicle: Vehicle? = nil
    var removeVehicleID: UUID? = nil
    var upgradeVehicleID: UUID? = nil
    var addVehicleUpgrade: VehicleUpgrade? = nil

    var addHouseUpgrade: HouseUpgrade? = nil

    var addJewelry: Jewelry? = nil
    var removeJewelryID: UUID? = nil

    var addAviation: AviationAsset? = nil
    var removeAviationID: UUID? = nil
    
    var addMarine: MarineAsset? = nil
    var removeMarineID: UUID? = nil
}

struct MilitaryEffects: Codable, Equatable {
    var fitness: Int? = nil
    var discipline: Int? = nil
    var heat: Int? = nil
    var rankLevel: Int? = nil
    var contractYearsRemaining: Int? = nil
    var setDeploymentStatus: DeploymentStatus? = nil
    var isAWOL: Bool? = nil
    var addMedal: String? = nil
}

struct ChoiceEffects: Codable, Equatable {
    var core: CoreStatEffects? = nil
    var education: EducationEffects? = nil
    var career: CareerEffects? = nil
    var specialCareer: SpecialCareerEffects? = nil
    var military: MilitaryEffects? = nil
    var crime: CrimeEffects? = nil
    var legal: LegalEffects? = nil
    var finance: FinanceEffects? = nil
    var relationship: RelationshipEffects? = nil
    var health: HealthEffects? = nil
    var housing: HousingEffects? = nil
    var assets: AssetEffects? = nil
    var consequence: ConsequenceEffects? = nil
    var fame: FameEffects? = nil   // Fame Web F1
}

struct CoreStatEffects: Codable, Equatable {
    var happiness: Int? = nil
    var smarts: Int? = nil
    var looks: Int? = nil
    var health: Int? = nil
}

struct TrajectoryEffects: Codable, Equatable {
    var socioeconomicPressure: Int? = nil
    var familyStability: Int? = nil
    var educationalAccess: Int? = nil
    var socialCapital: Int? = nil
    var neighborhoodSafety: Int? = nil
    var resilience: Int? = nil
    var momentum: Int? = nil
    var setbackPressure: Int? = nil
    var luckWindow: Int? = nil
    var opportunityVisibility: Int? = nil
    var setLifePhase: LifePhase? = nil
    var setDirection: TrajectoryDirection? = nil
}

struct CareerEffects: Codable, Equatable {
    var performance: Int? = nil
    var yearsWorked: Int? = nil
    var setStatus: CareerStatus? = nil
    var setProfile: CareerProfile? = nil
    var setRoleID: String? = nil
    var incomeBonus: Int? = nil
    var promote: Bool? = nil
    var loseJob: Bool? = nil
    var burnout: Int? = nil
    var schedulePressure: Int? = nil
    var relationshipSpillover: Int? = nil
    var jobSecurity: Int? = nil
    var managerFriction: Int? = nil
    var scheduleControl: Int? = nil
    var retrainingProgress: Int? = nil
    var setRetrainingTargetProfile: CareerProfile? = nil
    var setOpenDoor: CareerOpportunityDoor? = nil
    var clearOpenDoor: Bool? = nil

    init(
        performance: Int? = nil,
        yearsWorked: Int? = nil,
        setStatus: CareerStatus? = nil,
        setProfile: CareerProfile? = nil,
        setRoleID: String? = nil,
        incomeBonus: Int? = nil,
        promote: Bool? = nil,
        loseJob: Bool? = nil,
        burnout: Int? = nil,
        schedulePressure: Int? = nil,
        relationshipSpillover: Int? = nil,
        jobSecurity: Int? = nil,
        managerFriction: Int? = nil,
        scheduleControl: Int? = nil,
        retrainingProgress: Int? = nil,
        setRetrainingTargetProfile: CareerProfile? = nil,
        setOpenDoor: CareerOpportunityDoor? = nil,
        clearOpenDoor: Bool? = nil
    ) {
        self.performance = performance
        self.yearsWorked = yearsWorked
        self.setStatus = setStatus
        self.setProfile = setProfile
        self.setRoleID = setRoleID
        self.incomeBonus = incomeBonus
        self.promote = promote
        self.loseJob = loseJob
        self.burnout = burnout
        self.schedulePressure = schedulePressure
        self.relationshipSpillover = relationshipSpillover
        self.jobSecurity = jobSecurity
        self.managerFriction = managerFriction
        self.scheduleControl = scheduleControl
        self.retrainingProgress = retrainingProgress
        self.setRetrainingTargetProfile = setRetrainingTargetProfile
        self.setOpenDoor = setOpenDoor
        self.clearOpenDoor = clearOpenDoor
    }
}

struct SpecialCareerEffects: Codable, Equatable {
    var setTrack: SpecialCareerTrack? = nil
    var tier: Int? = nil
    var fame: Int? = nil
    var audience: Int? = nil
    var heat: Int? = nil
    var notoriety: Int? = nil
    var burnout: Int? = nil
    var yearsActive: Int? = nil
    var lastPayout: Int? = nil
    var exitTrack: Bool? = nil
}

// Fame Web F1: Direct effects for the unified profile (used by actions, storylets, events)
struct FameEffects: Codable, Equatable {
    var culturalFame: Int? = nil
    var notoriety: Int? = nil
    var addKnownFor: String? = nil
}

struct CrimeEffects: Codable, Equatable {
    var setStatus: CrimeStatus? = nil
    var roleTier: Int? = nil
    var heat: Int? = nil
    var notoriety: Int? = nil
    var burnout: Int? = nil
    var crewID: String? = nil
    var loyalty: Int? = nil
    var territoryPressure: Int? = nil
    var yearsActive: Int? = nil
    var lastPayout: Int? = nil
    var exitCrime: Bool? = nil
}

struct LegalEffects: Codable, Equatable {
    var addExposures: [LegalExposure] = []
    var setDecision: LegalDecision? = nil
    var counselQualityDelta: Int? = nil
    var evidenceDelta: Int? = nil
}

struct EducationEffects: Codable, Equatable {
    var schoolStanding: Int? = nil
    var engagement: Int? = nil
    var attendancePressure: Int? = nil
    var activityMomentum: Int? = nil
    var schoolBelonging: Int? = nil
    var reputationRisk: Int? = nil
    var teacherSupport: Int? = nil
    var applicationReadiness: Int? = nil
    var campusFit: Int? = nil
    var burnoutRisk: Int? = nil
    var disciplineRecord: Int? = nil
    var mentorSupport: Int? = nil
    var peerPressure: Int? = nil
    var setPathway: EducationPathway? = nil
    var setStage: EducationStage? = nil
    var setAcademicTrack: AcademicTrack? = nil
    var yearsInStage: Int? = nil
    var setStudyFocus: StudyFocus? = nil
    var addCredential: String? = nil
    var hasScholarship: Bool? = nil
}

struct FinanceEffects: Codable, Equatable {
    var cashDelta: Int? = nil
    var annualIncomeDelta: Int? = nil
    var studentDebtDelta: Int? = nil
    var creditDebtDelta: Int? = nil
    var medicalDebtDelta: Int? = nil
    var livingCostDelta: Int? = nil
    var educationCostDelta: Int? = nil
    var dependentCostDelta: Int? = nil
    var discretionaryCostDelta: Int? = nil
    var financialStressDelta: Int? = nil
    var setRegionPolicyID: String? = nil
}

struct RelationshipEffects: Codable, Equatable {
    var meetNewFriend: Bool? = nil
    var friendChange: Int? = nil
    var startDating: Bool? = nil
    var partnerChange: Int? = nil
    var setPartnerStage: RelationshipStage? = nil
    var setCohabiting: Bool? = nil
    var commitmentAlignmentChange: Int? = nil
    var loseFriend: Bool? = nil
    var breakup: Bool? = nil
    var publicReputationChange: Int? = nil
    var privateReputationChange: Int? = nil
    var rumorHeatChange: Int? = nil
    var addKnownTag: String? = nil

    init(
        meetNewFriend: Bool? = nil,
        friendChange: Int? = nil,
        startDating: Bool? = nil,
        partnerChange: Int? = nil,
        setPartnerStage: RelationshipStage? = nil,
        setCohabiting: Bool? = nil,
        commitmentAlignmentChange: Int? = nil,
        loseFriend: Bool? = nil,
        breakup: Bool? = nil,
        publicReputationChange: Int? = nil,
        privateReputationChange: Int? = nil,
        rumorHeatChange: Int? = nil,
        addKnownTag: String? = nil
    ) {
        self.meetNewFriend = meetNewFriend
        self.friendChange = friendChange
        self.startDating = startDating
        self.partnerChange = partnerChange
        self.setPartnerStage = setPartnerStage
        self.setCohabiting = setCohabiting
        self.commitmentAlignmentChange = commitmentAlignmentChange
        self.loseFriend = loseFriend
        self.breakup = breakup
        self.publicReputationChange = publicReputationChange
        self.privateReputationChange = privateReputationChange
        self.rumorHeatChange = rumorHeatChange
        self.addKnownTag = addKnownTag
    }
}

struct FamilyEffects: Codable, Equatable {
    var atHomeBondDelta: Int? = nil
    var allChildrenBondDelta: Int? = nil
    var childBondDeltaByID: [UUID: Int]? = nil
    var pregnancyIntent: PregnancyIntent? = nil
}

struct HealthEffects: Codable, Equatable {
    var physical: Int? = nil
    var mental: Int? = nil
    var exercise: Int? = nil
    var nutrition: Int? = nil
    var stressManagement: Int? = nil
    var addCondition: String? = nil
    var removeCondition: String? = nil
    var hasPrimaryCare: Bool? = nil
}

struct HousingEffects: Codable, Equatable {
    var costBandDelta: Int? = nil
    var stabilityDelta: Int? = nil
    var setArrangement: LivingArrangement? = nil
    var hasRoommate: Bool? = nil
}

