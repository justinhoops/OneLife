import Foundation

// MARK: - Domains

enum Domain: String, Codable, CaseIterable, Identifiable {
    case school, cash, love, play, health

    var id: String { rawValue }

    var title: String {
        switch self {
        case .school: "School"
        case .cash: "Cash"
        case .love: "Love"
        case .play: "Play"
        case .health: "Health"
        }
    }

    /// Glance tab label — School becomes Skills after leaving education (Codex progressive disclosure).
    func displayTitle(attendsSchool: Bool) -> String {
        if self == .school && !attendsSchool { return "Skills" }
        return title
    }

    var symbol: String {
        switch self {
        case .school: "book.fill"
        case .cash: "dollarsign.circle.fill"
        case .love: "heart.fill"
        case .play: "gamecontroller.fill"
        case .health: "cross.case.fill"
        }
    }

    /// Primary bottom tabs (Health is cross-cutting via stat island / sheet).
    static var primaryTabs: [Domain] { [.school, .cash, .love, .play] }
}

// MARK: - Action identity

enum ActionID: String, Codable, CaseIterable, Identifiable {
    case study, attendClass, joinClub
    case focusGrades, findYourPeople, commitActivity, helpAtHome
    /// Post-school skills track (same domain tab, different chapter).
    case networkContacts, sideHustle, skillCourse, applyToCollege, returnToEducation
    case workShift, budget, applyForBetterWork
    case reachOut, goOnDate, repairConflict
    case seeFriends, pursueHobby, party
    case quietNight, familyDinner
    case exercise, rest, seekCare
    // Career depth (v7)
    case chooseOffice, chooseTrades, chooseCareService, chooseFreelance
    case chooseOfficeAdministrator, chooseAccountant, chooseHumanResourcesSpecialist, chooseSalesRepresentative
    case chooseElectrician, choosePlumber, chooseMechanic, chooseConstructionWorker
    case chooseTeacher, chooseNurse, chooseCaregiver, chooseRestaurantManager
    case chooseDesigner, chooseDeveloper, chooseConsultant, chooseIndependentContractor
    case jobSearch, changeCareer, pursuePromotion, developSkill, protectBoundaries
    case negotiateRaise, acceptOvertime, buildProfessionalNetwork, pursueCertification, takeCareerLeave
    case changeEmployer, buildWorkplaceRelationship, requestFlexibleSchedule
    case buildCareerPortfolio, requestReference, testJobMarket
    case specializeTechnical, specializeLeadership, specializeClientTrust, negotiateBenefits, usePaidLeave, mentorCoworker, prepareRetirement
    case takePartTimeWork, pursueSpecialCareer, buildDiamondCareer
    // Household finance and housing (v8)
    case payDebt, adjustRetirement, buyHome, sellOrDownsize, negotiateDebt
    // Partner and family lifecycle (v9)
    case deepenCommitment, marry, separate, chooseChildfree, familyPlanning, parentingPresence, caregiving
    // Canonical health and conditions (v10)
    case therapySupport, manageCondition, preventiveCare, cutBack

    var id: String { rawValue }
}

enum ActionCategory: String, Codable, CaseIterable, Identifiable {
    case education, career, money, housing, relationship, family, leisure, health

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

// MARK: - Requirements & effects

indirect enum ActionRequirement: Codable, Equatable {
    case minimumAge(Int)
    case minimumCash(Int)
    case minimumStat(Domain, Int)
    case schoolEnrollment(Bool)
    case credential
    case partner
    case employed
    case careerTrack(CareerTrack)
    case careerClass(CareerClass)
    case careerDirectionChosen
    case careerOccupationNotChosen
    case careerOccupation(CareerOccupation)
    case careerLevels([CareerLevel])
    case careerPaidLeave(Int)
    case specialCareerEligible
    case diamondCareerEligible
    case relationshipStages([RelationshipStage])
    case familyIntention([FamilyIntention])
    case noChildren
    case hasDependents
    case housing([HousingKind])
    case hasDebt
    case debtWorkoutEligible
    case hasCondition
    case schoolCommitmentOpen
    case schoolActivityOpen
    case collegeApplicationEligible
    case educationRecoveryEligible
    case stages([LifeStage])
    case all([ActionRequirement])
    case any([ActionRequirement])
}

/// Compatibility builder for the compact-core registry. New actions compose
/// `ActionRequirement` values directly; old declarations decode unchanged.
struct Requirement: Codable, Equatable {
    var values: [ActionRequirement]

    init(
        minimumAge: Int? = nil,
        minimumCash: Int? = nil,
        minimumStat: Int? = nil,
        statDomain: Domain? = nil,
        requiresSchool: Bool = false,
        requiresLeftSchool: Bool = false,
        requiresCredential: Bool = false,
        requiresPartner: Bool = false,
        requiresJob: Bool = false,
        allowedStages: [LifeStage]? = nil,
        values: [ActionRequirement] = []
    ) {
        var built = values
        if let minimumAge { built.append(.minimumAge(minimumAge)) }
        if let minimumCash { built.append(.minimumCash(minimumCash)) }
        if let minimumStat, let statDomain { built.append(.minimumStat(statDomain, minimumStat)) }
        if requiresSchool { built.append(.schoolEnrollment(true)) }
        if requiresLeftSchool { built.append(.schoolEnrollment(false)) }
        if requiresCredential { built.append(.credential) }
        if requiresPartner { built.append(.partner) }
        if requiresJob { built.append(.employed) }
        if let allowedStages { built.append(.stages(allowedStages)) }
        self.values = built
        self.minimumAge = minimumAge
        self.minimumCash = minimumCash
        self.minimumStat = minimumStat
        self.statDomain = statDomain
        self.requiresSchool = requiresSchool
        self.requiresLeftSchool = requiresLeftSchool
        self.requiresCredential = requiresCredential
        self.requiresPartner = requiresPartner
        self.requiresJob = requiresJob
        self.allowedStages = allowedStages
    }
    var minimumAge: Int?
    var minimumCash: Int?
    var minimumStat: Int?
    var statDomain: Domain?
    var requiresSchool = false
    /// Skills-track actions after leaving education.
    var requiresLeftSchool = false
    var requiresCredential = false
    var requiresPartner = false
    var requiresJob = false
    var allowedStages: [LifeStage]?

    /// Whether an action belongs on the current chapter's action surface.
    /// Numeric and relationship requirements remain visible as useful locks;
    /// mutually exclusive school/stage actions stay hibernated until relevant.
    func isRelevant(in state: LifeState) -> Bool {
        values.allSatisfy { RequirementEvaluator.isRelevant($0, in: state) }
    }

    func unmetReason(in state: LifeState) -> String? {
        values.compactMap { RequirementEvaluator.unmetReason($0, in: state) }.first
    }
}

enum RequirementEvaluator {
    static func isRelevant(_ requirement: ActionRequirement, in state: LifeState) -> Bool {
        switch requirement {
        case .debtWorkoutEligible: FinanceSystem.workoutEligible(state)
        case .schoolEnrollment(let enrolled): state.flags.attendsSchool == enrolled
        case .stages(let stages): stages.contains(state.lifeStage)
        case .all(let values): values.allSatisfy { isRelevant($0, in: state) }
        case .any(let values): values.contains { isRelevant($0, in: state) }
        case .collegeApplicationEligible: collegeApplicationReason(in: state) == nil
        case .educationRecoveryEligible: educationRecoveryReason(in: state) == nil
        case .specialCareerEligible: CareerOpportunitySystem.specialEligibilityIssue(in: state) == nil
        case .diamondCareerEligible: CareerOpportunitySystem.diamondEligibilityIssue(in: state) == nil
        case .careerOccupationNotChosen: state.career.track != .undecided && state.career.occupation == nil
        default: true
        }
    }

    static func unmetReason(_ requirement: ActionRequirement, in state: LifeState) -> String? {
        switch requirement {
        case .minimumAge(let age): state.character.age < age ? "Available at age \(age)" : nil
        case .minimumCash(let cash): state.cash < cash ? "Requires $\(cash)" : nil
        case .minimumStat(let domain, let value): state.stats[domain] < value ? "Requires \(domain.title) \(value)" : nil
        case .schoolEnrollment(let enrolled): state.flags.attendsSchool == enrolled ? nil : (enrolled ? "You are not enrolled in school" : "Available after you leave school")
        case .credential: state.education.credential ? nil : "Requires a credential"
        case .partner: state.partner == nil ? "Requires a partner" : nil
        case .employed: state.career.level.isEmployed ? nil : "Requires a job"
        case .careerTrack(let track): state.career.track == track ? nil : "Requires the \(track.title) track"
        case .careerClass(let careerClass): state.career.careerClass == careerClass ? nil : "Requires \(careerClass.title.lowercased())"
        case .careerDirectionChosen: state.career.track == .undecided ? "Choose a career direction first" : nil
        case .careerOccupationNotChosen: state.career.occupation == nil ? nil : "Choose a different career occupation"
        case .careerOccupation(let occupation): state.career.occupation == occupation ? nil : "Requires the (occupation.title) occupation"
        case .careerLevels(let levels): levels.contains(state.career.level) ? nil : "Requires a different career level"
        case .careerPaidLeave(let days): state.career.paidLeaveDays >= days ? nil : "Requires \(days) paid leave days"
        case .specialCareerEligible: CareerOpportunitySystem.specialEligibilityIssue(in: state)
        case .diamondCareerEligible: CareerOpportunitySystem.diamondEligibilityIssue(in: state)
        case .relationshipStages(let stages): state.partner.map { stages.contains($0.stage) } == true ? nil : "Requires a different relationship stage"
        case .familyIntention(let intentions): intentions.contains(state.family.intention) ? nil : "Change your family intention first"
        case .noChildren: state.family.children.isEmpty ? nil : "This choice is only available before parenthood"
        case .hasDependents: state.family.dependentLoad > 0 ? nil : "Requires a dependent child"
        case .housing(let kinds): kinds.contains(state.housingKind) ? nil : "Requires a different housing situation"
        case .debtWorkoutEligible: FinanceSystem.workoutEligible(state) ? nil : "Requires two shortfall years and unmanageable unsecured debt"
        case .hasDebt: state.finance.totalDebt > 0 ? nil : "No unsecured debt to pay"
        case .hasCondition: state.health.conditions.isEmpty ? "No active condition to manage" : nil
        case .schoolCommitmentOpen: state.education.commitment == nil ? nil : "This school year's focus is already set"
        case .schoolActivityOpen: state.education.activityStage == .ended ? "That school activity chapter has ended" : nil
        case .collegeApplicationEligible: collegeApplicationReason(in: state)
        case .educationRecoveryEligible: educationRecoveryReason(in: state)
        case .stages(let stages): stages.contains(state.lifeStage) ? nil : "Not available during \(state.lifeStage.title.lowercased())"
        case .all(let values): values.compactMap { unmetReason($0, in: state) }.first
        case .any(let values): values.allSatisfy { unmetReason($0, in: state) != nil } ? "Requirements not met" : nil
        }
    }

    private static func collegeApplicationReason(in state: LifeState) -> String? {
        if state.character.age > 24 { return "College applications close after age 24" }
        if !state.education.highSchoolDiploma, !state.education.hasAlternativeCredential {
            return "Requires a diploma or alternative credential"
        }
        if state.education.college.isEnrolled { return "You are already enrolled" }
        if state.education.college.status == .withdrawn { return "Return through your existing college record" }
        if state.education.credentialKind == .bachelorsDegree { return "You already hold a bachelor’s degree" }
        return nil
    }

    private static func educationRecoveryReason(in state: LifeState) -> String? {
        if state.character.age > 64 { return "Adult education closes after age 64" }
        if state.flags.attendsSchool || state.education.recovery.isActive { return "You are already enrolled" }
        if state.education.credentialKind == .bachelorsDegree { return "You already hold a bachelor’s degree" }
        return nil
    }
}

struct EffectRange: Equatable {
    var school: ClosedRange<Int> = 0...0
    var cash: ClosedRange<Int> = 0...0
    var love: ClosedRange<Int> = 0...0
    var play: ClosedRange<Int> = 0...0
    var health: ClosedRange<Int> = 0...0
    var looks: ClosedRange<Int> = 0...0
    var rep: ClosedRange<Int> = 0...0
    var gainsPartner = false
    var gainsJob = false

    /// Compact preview strings for long-press and action cards.
    var previewLines: [String] {
        [
            ("Smart", school), ("Cash", cash), ("Happy", love), ("Fun", play),
            ("Health", health), ("Looks", looks), ("Rep", rep)
        ].compactMap { label, range in
            guard range != 0...0 else { return nil }
            if range.lowerBound == range.upperBound {
                let v = range.lowerBound
                return "\(label) \(v > 0 ? "+" : "")\(v)"
            }
            let lo = range.lowerBound > 0 ? "+\(range.lowerBound)" : "\(range.lowerBound)"
            let hi = range.upperBound > 0 ? "+\(range.upperBound)" : "\(range.upperBound)"
            return "\(label) \(lo)…\(hi)"
        }
    }
}

extension EffectRange {
    func shifted(school: Int = 0, cash: Int = 0, love: Int = 0, play: Int = 0, health: Int = 0, looks: Int = 0, rep: Int = 0) -> EffectRange {
        var result = self
        func shift(_ range: ClosedRange<Int>, by amount: Int) -> ClosedRange<Int> { (range.lowerBound + amount)...(range.upperBound + amount) }
        result.school = shift(result.school, by: school)
        result.cash = shift(result.cash, by: cash)
        result.love = shift(result.love, by: love)
        result.play = shift(result.play, by: play)
        result.health = shift(result.health, by: health)
        result.looks = shift(result.looks, by: looks)
        result.rep = shift(result.rep, by: rep)
        return result
    }

    func shifted(by other: EffectRange) -> EffectRange {
        shifted(
            school: other.school.lowerBound,
            cash: other.cash.lowerBound,
            love: other.love.lowerBound,
            play: other.play.lowerBound,
            health: other.health.lowerBound,
            looks: other.looks.lowerBound,
            rep: other.rep.lowerBound
        )
    }
}

extension EffectRange: Codable {
    enum CodingKeys: String, CodingKey {
        case school, cash, love, play, health, looks, rep, gainsPartner, gainsJob
    }

    private static func decodeRange(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) throws -> ClosedRange<Int> {
        if let range = try c.decodeIfPresent(ClosedRange<Int>.self, forKey: key) { return range }
        return 0...0
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        school = try Self.decodeRange(c, .school)
        cash = try Self.decodeRange(c, .cash)
        love = try Self.decodeRange(c, .love)
        play = try Self.decodeRange(c, .play)
        health = try Self.decodeRange(c, .health)
        looks = try Self.decodeRange(c, .looks)
        rep = try Self.decodeRange(c, .rep)
        gainsPartner = try c.decodeIfPresent(Bool.self, forKey: .gainsPartner) ?? false
        gainsJob = try c.decodeIfPresent(Bool.self, forKey: .gainsJob) ?? false
    }
}

struct InfluenceVector: Codable, Equatable {
    var work = 0
    var family = 0
    var risk = 0
    var stability = 0

    var isEmpty: Bool { work == 0 && family == 0 && risk == 0 && stability == 0 }

    var dominantLabel: String {
        let pairs: [(String, Int)] = [
            ("career", work), ("connection", family), ("risk", risk), ("steady ground", stability)
        ]
        return pairs.max(by: { $0.1 < $1.1 })?.0 ?? "drift"
    }

    mutating func add(_ other: InfluenceVector, cap: Int = 6) {
        work = min(cap, work + other.work)
        family = min(cap, family + other.family)
        risk = min(cap, risk + other.risk)
        stability = min(cap, stability + other.stability)
    }
}

struct PartnerEffect: Codable, Equatable {
    var bond = 0
    var resentment = 0
    var committed: Bool?
    var endRelationship = false
    var ruptureStage: PartnerRuptureStage?
    var repairPromise: Bool?

    var isEmpty: Bool {
        bond == 0 && resentment == 0 && committed == nil && !endRelationship
            && ruptureStage == nil && repairPromise == nil
    }

    var previewLines: [String] {
        var lines: [String] = []
        if bond != 0 { lines.append("Bond \(bond > 0 ? "+" : "")\(bond)") }
        if resentment != 0 { lines.append("Resentment \(resentment > 0 ? "+" : "")\(resentment)") }
        if endRelationship { lines.append("May end the relationship") }
        if committed == true { lines.append("Deepens commitment") }
        return lines
    }
}

extension PartnerEffect {
    private enum CodingKeys: String, CodingKey {
        case bond, resentment, committed, endRelationship, ruptureStage, repairPromise
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bond = try c.decodeIfPresent(Int.self, forKey: .bond) ?? 0
        resentment = try c.decodeIfPresent(Int.self, forKey: .resentment) ?? 0
        committed = try c.decodeIfPresent(Bool.self, forKey: .committed)
        endRelationship = try c.decodeIfPresent(Bool.self, forKey: .endRelationship) ?? false
        ruptureStage = try c.decodeIfPresent(PartnerRuptureStage.self, forKey: .ruptureStage)
        repairPromise = try c.decodeIfPresent(Bool.self, forKey: .repairPromise)
    }
}

/// Declarative relationship metadata consumed by SocialReactivitySystem.
struct PersonalityBranch: Codable, Equatable, Identifiable {
    let id: String
    let requiredFlags: [PartnerFlag]
    let modifier: PartnerEffect
    let headline: String
    let narrative: String
    let previewHint: String
    let isLearned: Bool

    func matches(_ partner: PartnerState) -> Bool {
        requiredFlags.allSatisfy { partner.flags.contains($0) }
    }
}

struct SocialActionResolution: Equatable {
    let action: DomainAction
    let partnerEffect: PartnerEffect
    let headline: String
    let narrative: String
    let personalityContext: String?
    let previewHint: String?
    let appliedBranches: [PersonalityBranch]
    let npc: NPCState?
    let npcEffect: EffectRange
    let npcContext: String?
    let npcRapportDelta: Int
    let reactionRules: [ReactionRule]

    var hasPersonalityResponse: Bool { !appliedBranches.isEmpty || !reactionRules.isEmpty }

    static func hibernated(for action: DomainAction) -> SocialActionResolution {
        SocialActionResolution(
            action: action,
            partnerEffect: PartnerEffect(),
            headline: action.name,
            narrative: action.narrative,
            personalityContext: nil,
            previewHint: nil,
            appliedBranches: [],
            npc: nil,
            npcEffect: EffectRange(),
            npcContext: nil,
            npcRapportDelta: 0,
            reactionRules: []
        )
    }
}

struct NPCPersonalityBranch: Codable, Equatable, Identifiable {
    let id: String
    let role: NPCRole
    let requiredFlags: [NPCFlag]
    let modifier: EffectRange
    let rapportDelta: Int
    let headline: String
    let narrative: String
    let previewHint: String

    func matches(_ npc: NPCState) -> Bool {
        npc.role == role && requiredFlags.allSatisfy { npc.coreFlags.contains($0) }
    }
}

// MARK: - Deltas & outcomes

struct DeltaSummary: Equatable {
    var school = 0
    var cash = 0
    var love = 0
    var play = 0
    var health = 0
    var looks = 0
    var rep = 0
    var bond = 0
    var resentment = 0

    var isEmpty: Bool {
        school == 0 && cash == 0 && love == 0 && play == 0 && health == 0
            && looks == 0 && rep == 0 && bond == 0 && resentment == 0
    }

    var lines: [String] {
        [
            ("School", school), ("Cash", cash), ("Love", love), ("Play", play),
            ("Health", health), ("Looks", looks), ("Rep", rep), ("Bond", bond), ("Resentment", resentment)
        ].compactMap { $0.1 == 0 ? nil : "\($0.0) \($0.1 > 0 ? "+" : "")\($0.1)" }
    }

    var semanticLines: [SemanticDelta] {
        [
            SemanticDelta(label: "Smart", value: school, beneficial: school > 0),
            SemanticDelta(label: "Cash", value: cash, beneficial: cash > 0),
            SemanticDelta(label: "Happy", value: love, beneficial: love > 0),
            SemanticDelta(label: "Fun", value: play, beneficial: play > 0),
            SemanticDelta(label: "Health", value: health, beneficial: health > 0),
            SemanticDelta(label: "Looks", value: looks, beneficial: looks > 0),
            SemanticDelta(label: "Rep", value: rep, beneficial: rep > 0),
            SemanticDelta(label: "Bond", value: bond, beneficial: bond > 0),
            SemanticDelta(label: "Resentment", value: resentment, beneficial: resentment < 0)
        ].filter { $0.value != 0 }
    }

    static func + (lhs: DeltaSummary, rhs: DeltaSummary) -> DeltaSummary {
        DeltaSummary(
            school: lhs.school + rhs.school,
            cash: lhs.cash + rhs.cash,
            love: lhs.love + rhs.love,
            play: lhs.play + rhs.play,
            health: lhs.health + rhs.health,
            looks: lhs.looks + rhs.looks,
            rep: lhs.rep + rhs.rep,
            bond: lhs.bond + rhs.bond,
            resentment: lhs.resentment + rhs.resentment
        )
    }
}

extension DeltaSummary: Codable {
    enum CodingKeys: String, CodingKey {
        case school, cash, love, play, health, looks, rep, bond, resentment
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        school = try c.decodeIfPresent(Int.self, forKey: .school) ?? 0
        cash = try c.decodeIfPresent(Int.self, forKey: .cash) ?? 0
        love = try c.decodeIfPresent(Int.self, forKey: .love) ?? 0
        play = try c.decodeIfPresent(Int.self, forKey: .play) ?? 0
        health = try c.decodeIfPresent(Int.self, forKey: .health) ?? 0
        looks = try c.decodeIfPresent(Int.self, forKey: .looks) ?? 0
        rep = try c.decodeIfPresent(Int.self, forKey: .rep) ?? 0
        bond = try c.decodeIfPresent(Int.self, forKey: .bond) ?? 0
        resentment = try c.decodeIfPresent(Int.self, forKey: .resentment) ?? 0
    }
}

struct SemanticDelta: Identifiable, Equatable {
    var id: String { label }
    let label: String
    let value: Int
    let beneficial: Bool

    var text: String { "\(label) \(value > 0 ? "+" : "")\(value)" }
}

struct ActionOutcome: Equatable {
    let headline: String
    let narrative: String
    let deltas: DeltaSummary
    var isYearly: Bool = false
    var yearSummary: YearSummary? = nil
    var reactionNote: String? = nil
    var personalityContext: String? = nil
    var severity: OutcomeSeverity = .minor
    var actionKey: String? = nil
    var followUp: PresentedEvent? = nil
    var impacts: [ActionImpact] = []
}

struct ActionImpact: Equatable, Identifiable {
    let domain: ConsequenceDomain
    let label: String
    let change: Int?
    var id: String { "\(domain.rawValue):\(label)" }
    var text: String {
        guard let change else { return label }
        return "\(label) \(change > 0 ? "+" : "")\(change)"
    }
}

enum OutcomeSeverity: String, Codable, Equatable {
    case micro, minor, major, critical
}

/// Requests carry identity and context; the owning domain still calculates effects.
enum ActionRequest {
    case registered(ActionID, target: PersonReference? = nil)
    case contextual(ContextActionID, target: PersonReference? = nil)
    case domain(DomainCommandRequest)

    var key: String {
        switch self {
        case .registered(let id, _): id.rawValue
        case .contextual(let id, _): "context:\(id.rawValue)"
        case .domain(let command): "domain:\(String(describing: command))"
        }
    }
}

/// Typed adapters for state-changing detail actions. Legacy method names stay
/// available while views and tools move to this single request entry point.
enum DomainCommandRequest {
    case purchaseAsset(String), sellAsset(UInt64), giftAsset(UInt64, AssetGiftRecipient)
    case maintainVehicle(UInt64, VehicleMaintenanceKind), upgradeVehicle(UInt64, VehicleUpgradeID)
    case upgradeFirearm(UInt64, FirearmUpgradeID), manageFirearm(UInt64, FirearmManagementAction)
    case installAmenity(UInt64, PropertyAmenityID), rentProperty(UInt64, RentalStrategy)
    case changeRentalStrategy(UInt64, RentalStrategy), withdrawRental(UInt64)
    case repairProperty(UInt64, PropertyRepairKind), investigateAssetLoss(UInt64), liquidateAssets([UInt64])
    case soloCrime(CrimeOperationType), joinGang, workGangSpecialty, startDrugEnterprise
    case improveDrugFormula, manageDrugEnterprise, recruitDrugEnterpriseRole(DrugEnterpriseRole)
    case startOrganization, promoteCriminalLeader
    case prepareCrimePlan(String), executeCrimePlan(String), delegateCrime(String, CrimeOperationType)
    case recoverStolenAsset(UInt64), convertStolenAsset(UInt64, CriminalAssetConversionRoute)
    case purchaseKitEquipment(String, Int), buildSpecialistRelationship(String), rewardSpecialist(String)
    case saveCrimePlan(CrimeOperationType), setCrimePlanApproach(String, CrimeApproach)
    case setSoloCriminalKit(String?), assignCriminalKit(String, String?)
    case setCriminalKitAssets(String, [UInt64], [UInt64])
    case createCriminalKit(String)
    case upgradeCriminalSafehouse
    case negotiateRival(String), attackRival(String)
    case legalPlea(String), legalTrial(String), legalAppeal(String), legalBail(String)
    case legalDetention(String), supervisedRelease(String), pretrialViolation(String)
    case legalCooperation(String, Bool), enterpriseLegal(String, String, EnterpriseLegalAction)
    case hireDefenseLawyer(LegalLawyerSpecialty, Bool)
    case threatenEnterpriseSpecialist(String, String)
    case prison(PrisonActionKind, String?), prisonSupport, prisonCommand(PrisonOrganizationCommand, String?)
    case appointActingLeader(String)
    case venture(VentureCommand)
    case chooseGangSpecialty(CriminalSpecialty)
    case assignDefenseLawyer(String, String)
    case prisonInformant(Bool)
    case acquireCriminalSafehouse, acquireCriminalFrontBusiness, investCriminalEquipment
    case renameVehicle(UInt64, String), clearVehicleName(UInt64)
}

enum PersonReference: Codable, Equatable, Hashable {
    case partner
    case cast(String)
    case family(String)
}

enum ContextActionID: String, Codable, CaseIterable, Identifiable {
    case teacherHelp, hardshipExtension, makeAmends, friendInvitation, adjustCarePlan
    var id: String { rawValue }
}

struct ActionSuggestion: Identifiable {
    let request: ActionRequest
    let title: String
    let reason: String
    let score: Int
    var id: String { "\(request.key):\(String(describing: request))" }
}

struct ActionUseRecord: Codable, Equatable {
    var age: Int
    var count: Int
}

enum ActionRepeatPolicy: Equatable {
    case oncePerAge
    case repeatable(maxPerAge: Int)

    var maxPerAge: Int {
        switch self {
        case .oncePerAge: 1
        case .repeatable(let limit): limit
        }
    }
}

// MARK: - Domain action

struct DomainAction: Codable, Equatable, Identifiable {
    let id: ActionID
    let domain: Domain
    var category: ActionCategory = .leisure
    let name: String
    let shortDescription: String
    let requirements: Requirement
    let effects: EffectRange
    let influence: InfluenceVector
    let partnerEffect: PartnerEffect
    let narrative: String
    /// Static BitLife-style core actions always shown in the domain grid.
    var isStaticCore: Bool = true
    var previewTags: [String] = []
    var microBeat: String = ""
    var personalityBranches: [PersonalityBranch] = []
    var npcRole: NPCRole? = nil
    var npcPersonalityBranches: [NPCPersonalityBranch] = []
    var personalityImpulse: PersonalityImpulse? = nil
    var reactionRules: [ReactionRule] = []
    var domainEffects: DomainActionEffects? = nil

    var resolvedPersonalityImpulse: PersonalityImpulse {
        if let personalityImpulse { return personalityImpulse }
        var impulse = PersonalityImpulse(
            drive: min(3, influence.work),
            empathy: min(2, influence.family),
            riskTolerance: min(3, influence.risk) - min(2, influence.stability),
            adaptability: -min(2, influence.stability)
        )
        if domain == .love || domain == .play, influence.family > 0 { impulse.sociability += 2 }
        return impulse
    }

    var rippleHint: String {
        if !influence.isEmpty {
            return "Shapes your year toward \(influence.dominantLabel)."
        }
        if !partnerEffect.isEmpty {
            return "Ripples into your relationship."
        }
        return "Small move. Immediate feedback."
    }

    var effectPreviewLines: [String] {
        if !effects.previewLines.isEmpty { return effects.previewLines }
        guard let domainEffects else { return [] }
        if domainEffects.career != nil { return ["Changes career state"] }
        if domainEffects.finance != nil { return ["Changes household ledger"] }
        if domainEffects.family != nil { return ["Changes partner or family"] }
        if domainEffects.health != nil { return ["Changes health management"] }
        return []
    }
}

enum Availability: Equatable {
    case available
    case locked(String)
    var reason: String? { if case .locked(let reason) = self { return reason }; return nil }
}

// MARK: - Pressures (glance layer)

struct DomainPressure: Identifiable, Equatable {
    let id: String
    let label: String
    let symbol: String
    let level: PressureLevel
    let detail: String

    enum PressureLevel: String, Equatable {
        case low, medium, high

        var title: String {
            switch self {
            case .low: "Low"
            case .medium: "Med"
            case .high: "High"
            }
        }
    }
}

enum PressureResolver {
    static func pressures(for domain: Domain, in state: LifeState) -> [DomainPressure] {
        switch domain {
        case .school:
            if state.education.college.isEnrolled {
                return compact([
                    pressure("standing", "Standing", "chart.line.uptrend.xyaxis", level(for: 100 - state.education.college.academicStanding),
                             detail: "Academic standing \(state.education.college.academicStanding)."),
                    pressure("credits", "Credits", "checkmark.seal", state.education.college.credits >= state.education.college.creditTarget ? .low : (state.education.college.credits >= state.education.college.creditTarget / 2 ? .medium : .high),
                             detail: "\(state.education.college.credits)/\(state.education.college.creditTarget) toward \(state.education.college.institution == .communityCollege ? "an associate degree" : "a bachelor’s degree")."),
                    pressure("tuition", "Tuition", "dollarsign.circle", state.education.college.institution == .scholarshipUniversity ? .low : (state.education.college.institution == .communityCollege ? .medium : .high),
                             detail: "$\(state.education.college.institution?.annualDebt ?? 0) student debt each enrolled year.")
                ])
            }
            return compact([
                pressure("focus", "Focus", "brain.head.profile", level(for: 100 - state.stats.school),
                         detail: state.stats.school < 45 ? "Your footing at school feels thin." : "You can still push the work."),
                pressure("credential", "Credential", "rosette", state.education.credential ? .low : (state.education.progress >= 8 ? .medium : .high),
                         detail: state.education.credential ? "You already have something to show." : "Progress \(state.education.progress)/12 toward a credential."),
                pressure("energy", "Energy", "battery.50", level(for: 100 - state.stats.health),
                         detail: "Health \(state.stats.health) — grind burns recovery.")
            ])
        case .cash:
            return compact([
                pressure("runway", "Runway", "banknote", cashLevel(state.cash),
                         detail: "Cash \(MoneyText.exact(state.cash)) · debt \(MoneyText.exact(state.totalDebt))."),
                pressure("job", "Work", "briefcase.fill", state.job.tier == .skilled ? .low : (state.job.tier.isEmployed ? .medium : .high),
                         detail: "\(state.career.level.rawValue.capitalized) work · expected \(MoneyText.exact(EconomyCalculator.forecast(state).detail.expectedNet))/yr"),
                pressure("burn", "Burn", "flame.fill", state.finance.economy.shortfallYears > 0 ? .high : .low,
                         detail: "Essential costs \(MoneyText.exact(EconomyCalculator.forecast(state).detail.essentials)) each year.")
            ])
        case .love:
            if let partner = state.partner {
                return compact([
                    pressure("bond", "Bond", "heart.fill", level(for: 100 - partner.bond),
                             detail: "\(partner.name) · bond \(partner.bond)"),
                    pressure("tension", "Tension", "bolt.heart", level(for: partner.resentment),
                             detail: "Resentment \(partner.resentment) · \(partner.mood.title)"),
                    pressure("attention", "Attention", "calendar", partner.neglectStreak >= 2 ? .high : (partner.attentionStreak >= 2 ? .low : .medium),
                             detail: partner.neglectStreak >= 2 ? "They feel the absence." : "Show up between years.")
                ])
            }
            return compact([
                pressure("connection", "Connection", "person.2.fill", level(for: 100 - state.stats.love),
                         detail: state.stats.love < 45 ? "Your people feel far away." : "Room to reach out."),
                pressure("single", "Status", "heart.slash", .medium,
                         detail: "No partner yet — dates and reach-outs still matter."),
                pressure("energy", "Social energy", "sparkles", level(for: 100 - state.stats.play),
                         detail: "Play \(state.stats.play) fuels how open you feel.")
            ])
        case .play:
            return compact([
                pressure("joy", "Joy", "face.smiling", level(for: 100 - state.stats.play),
                         detail: state.stats.play < 40 ? "Everything feels like work." : "You still have spark."),
                pressure("balance", "Balance", "scale.3d", state.stats.play > 70 && state.stats.school < 40 ? .high : .low,
                         detail: "Fun without footing becomes a hangover."),
                pressure("health", "Body", "figure.walk", level(for: 100 - state.stats.health),
                         detail: "Nights out cost recovery.")
            ])
        case .health:
            return compact([
                state.lifeStage == .legacy ? pressure(
                    "mortality", "Mortality", "hourglass.bottomhalf.filled",
                    state.mortalityPressure == .critical ? .high : (state.mortalityPressure == .vulnerable ? .medium : .low),
                    detail: state.mortalityPressure == .stable ? "Your body is holding steady." : "Your risk is \(state.mortalityPressure.rawValue)."
                ) : nil,
                pressure("body", "Body", "heart.text.square", level(for: 100 - state.stats.health),
                         detail: "Health \(state.stats.health)."),
                pressure("looks", "Looks", "sparkle", level(for: 100 - state.stats.looks),
                         detail: "Looks \(state.stats.looks) — training shows."),
                pressure("cash", "Care cost", "cross.case", state.cash < 4_000 ? .high : .low,
                         detail: "Seeking care needs a little cash buffer.")
            ])
        }
    }

    private static func compact(_ items: [DomainPressure?]) -> [DomainPressure] {
        Array(items.compactMap { $0 }.prefix(4))
    }

    private static func pressure(
        _ id: String,
        _ label: String,
        _ symbol: String,
        _ level: DomainPressure.PressureLevel,
        detail: String
    ) -> DomainPressure {
        DomainPressure(id: id, label: label, symbol: symbol, level: level, detail: detail)
    }

    private static func level(for invertedScore: Int) -> DomainPressure.PressureLevel {
        if invertedScore >= 55 { return .high }
        if invertedScore >= 30 { return .medium }
        return .low
    }

    private static func cashLevel(_ cash: Int) -> DomainPressure.PressureLevel {
        if cash < 1_000 { return .high }
        if cash < 8_000 { return .medium }
        return .low
    }
}
