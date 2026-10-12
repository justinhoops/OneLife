import Foundation

// MARK: - Character & stats

struct Character: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var age: Int

    init(id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: String, age: Int = 18) {
        self.id = id
        self.name = name
        self.age = age
    }
}

struct LifeStats: Equatable {
    var school = 50
    var love = 50
    var play = 50
    var health = 60
    var looks = 52
    var rep = 48

    init(school: Int = 50, love: Int = 50, play: Int = 50, health: Int = 60, looks: Int = 52, rep: Int = 48) {
        self.school = school
        self.love = love
        self.play = play
        self.health = health
        self.looks = looks
        self.rep = rep
    }

    /// Glance island: Happy blends connection + joy.
    var happy: Int { ((love + play) / 2).clamped }

    subscript(domain: Domain) -> Int {
        get {
            switch domain {
            case .school: school
            case .cash: 0
            case .love: love
            case .play: play
            case .health: health
            }
        }
        set {
            switch domain {
            case .school: school = newValue
            case .cash: break
            case .love: love = newValue
            case .play: play = newValue
            case .health: health = newValue
            }
        }
    }

    mutating func clamp() {
        school = school.clamped
        love = love.clamped
        play = play.clamped
        health = health.clamped
        looks = looks.clamped
        rep = rep.clamped
    }
}

extension LifeStats: Codable {
    enum CodingKeys: String, CodingKey {
        case school, love, play, health, looks, rep
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        school = try c.decodeIfPresent(Int.self, forKey: .school) ?? 50
        love = try c.decodeIfPresent(Int.self, forKey: .love) ?? 50
        play = try c.decodeIfPresent(Int.self, forKey: .play) ?? 50
        health = try c.decodeIfPresent(Int.self, forKey: .health) ?? 60
        looks = try c.decodeIfPresent(Int.self, forKey: .looks) ?? 52
        rep = try c.decodeIfPresent(Int.self, forKey: .rep) ?? 48
    }
}

struct LifeFlags: Equatable {
    var attendsSchool = true
    var hasPartner = false
    var hasJob = true
    /// First-time teaching chips (session-safe; also persisted lightly).
    var seenInstantHint = false
    var seenAgeUpHint = false
    var seenLongPressHint = false
}

extension LifeFlags: Codable {
    enum CodingKeys: String, CodingKey {
        case attendsSchool, hasPartner, hasJob, seenInstantHint, seenAgeUpHint, seenLongPressHint
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        attendsSchool = try c.decodeIfPresent(Bool.self, forKey: .attendsSchool) ?? true
        hasPartner = try c.decodeIfPresent(Bool.self, forKey: .hasPartner) ?? false
        hasJob = try c.decodeIfPresent(Bool.self, forKey: .hasJob) ?? true
        seenInstantHint = try c.decodeIfPresent(Bool.self, forKey: .seenInstantHint) ?? false
        seenAgeUpHint = try c.decodeIfPresent(Bool.self, forKey: .seenAgeUpHint) ?? false
        seenLongPressHint = try c.decodeIfPresent(Bool.self, forKey: .seenLongPressHint) ?? false
    }
}

enum EducationPhase: String, Codable {
    case highSchool, awaitingDecision, postsecondary, leftSchool
}

enum HighSchoolYear: String, Codable, CaseIterable {
    case freshman, sophomore, junior, senior

    var title: String {
        rawValue.capitalized
    }

    init(age: Int) {
        switch age {
        case ...14: self = .freshman
        case 15: self = .sophomore
        case 16: self = .junior
        default: self = .senior
        }
    }
}

enum SchoolCommitment: String, Codable, CaseIterable, Identifiable {
    case academics, belonging, activity, home

    var id: String { rawValue }
    var title: String {
        switch self {
        case .academics: "Chasing grades"
        case .belonging: "Finding your people"
        case .activity: "Committing to an activity"
        case .home: "Helping at home"
        }
    }
}

enum SchoolEnvironment: String, Codable, CaseIterable {
    case competitive, underfunded, closeKnit, affluent, chaotic

    var title: String {
        switch self {
        case .competitive: "Competitive"
        case .underfunded: "Underfunded"
        case .closeKnit: "Close-knit"
        case .affluent: "Affluent"
        case .chaotic: "Chaotic"
        }
    }
}

enum SchoolActivity: String, Codable, CaseIterable {
    case none, club, athletics, arts, service, academicTeam

    var title: String {
        switch self {
        case .none: "No activity"
        case .club: "School club"
        case .athletics: "Athletics"
        case .arts: "Arts program"
        case .service: "Service group"
        case .academicTeam: "Academic team"
        }
    }
}

enum SchoolActivityStage: String, Codable {
    case none, joined, committed, leader, ended

    var title: String {
        switch self {
        case .none: "Not joined"
        case .joined: "New member"
        case .committed: "Committed"
        case .leader: "Leader"
        case .ended: "Ended"
        }
    }
}

enum SchoolMemoryKind: String, Codable {
    case belonging, reputation, mentor, activity, responsibility, setback, ending
}

struct SchoolMemory: Codable, Equatable, Identifiable {
    var id: String { "\(eventID)-\(age)-\(choiceID.rawValue)" }
    let eventID: String
    let headline: String
    let choiceID: EventChoiceID
    let choiceTitle: String
    let age: Int
    let kind: SchoolMemoryKind
    let significance: Int

    var reviewLine: String {
        "At \(age), \(headline.lowercased()). You chose to \(choiceTitle.lowercased())."
    }
}

enum SchoolLegacyFlag: String, Codable, CaseIterable, Hashable {
    case mentorBacked
    case sociallyRooted
    case financiallyExcluded
    case carriedHomeLoad
    case rumorScar
    case activityIdentity
    case recommendationEarned
    case academicBurnout

    var memoryLine: String {
        switch self {
        case .mentorBacked: "A teacher once made time when you were slipping."
        case .sociallyRooted: "You learned that belonging could be built."
        case .financiallyExcluded: "Money decided which school memories you could afford."
        case .carriedHomeLoad: "You carried adult responsibility before adulthood arrived."
        case .rumorScar: "You remember how quickly a hallway could decide who you were."
        case .activityIdentity: "One after-school commitment gave you a place to matter."
        case .recommendationEarned: "Someone at school put their name behind your future."
        case .academicBurnout: "Achievement taught you how easy it was to disappear inside the work."
        }
    }
}

enum PostSchoolPath: String, Codable {
    case undecided, scholarship, college, training, work, alternativeCredential

    var title: String {
        switch self {
        case .undecided: "Uncertain"
        case .scholarship: "Scholarship"
        case .college: "Further education"
        case .training: "Practical training"
        case .work: "Work"
        case .alternativeCredential: "Alternative credential"
        }
    }
}

enum CollegeStatus: String, Codable {
    case none, awaitingField, enrolled, probation, completed, withdrawn
}

enum CollegeInstitution: String, Codable, CaseIterable {
    case scholarshipUniversity, publicUniversity, communityCollege

    var title: String {
        switch self {
        case .scholarshipUniversity: "Scholarship university"
        case .publicUniversity: "Public university"
        case .communityCollege: "Community college"
        }
    }

    var annualDebt: Int {
        switch self {
        case .scholarshipUniversity: 500
        case .publicUniversity: 4500
        case .communityCollege: 2000
        }
    }

    var creditTarget: Int { self == .communityCollege ? 8 : 12 }
}

enum CollegeField: String, Codable, CaseIterable {
    case appliedTechnical, business, peopleCreative, generalStudies

    static let playerChoices: [CollegeField] = [.appliedTechnical, .business, .peopleCreative]

    var title: String {
        switch self {
        case .appliedTechnical: "Applied & technical"
        case .business: "Business & organizations"
        case .peopleCreative: "People & creative work"
        case .generalStudies: "General studies"
        }
    }
}

enum EducationCredentialKind: String, Codable {
    case none, associateDegree, bachelorsDegree, professionalCertificate, alternativeCredential, legacyCredential

    var title: String {
        switch self {
        case .none: "No credential"
        case .associateDegree: "Associate degree"
        case .bachelorsDegree: "Bachelor’s degree"
        case .professionalCertificate: "Professional certificate"
        case .alternativeCredential: "Alternative credential"
        case .legacyCredential: "General credential"
        }
    }
}

struct CollegeState: Codable, Equatable {
    var status: CollegeStatus = .none
    var institution: CollegeInstitution?
    var field: CollegeField?
    var credits = 0
    var academicStanding = 50
    var campusBelonging = 50
    var yearsEnrolled = 0
    var lastTuitionAge: Int?
    var adultReentryAge: Int?

    var isEnrolled: Bool { status == .awaitingField || status == .enrolled || status == .probation }
    var creditTarget: Int { institution?.creditTarget ?? 12 }

    mutating func clamp() {
        credits = max(0, credits)
        academicStanding = min(100, max(0, academicStanding))
        campusBelonging = min(100, max(0, campusBelonging))
        yearsEnrolled = max(0, yearsEnrolled)
    }
}

enum EducationRecoveryStatus: String, Codable {
    case inactive, active, completed
}

enum EducationRecoveryKind: String, Codable {
    case alternativeCredential, technicalCertificate

    var title: String {
        switch self {
        case .alternativeCredential: "Alternative credential"
        case .technicalCertificate: "Technical certificate"
        }
    }

    var target: Int { 6 }
    var annualDebt: Int { self == .technicalCertificate ? 1_000 : 0 }
}

struct EducationRecoveryState: Codable, Equatable {
    var status: EducationRecoveryStatus = .inactive
    var kind: EducationRecoveryKind?
    var progress = 0
    var startedAge: Int?
    var lastCostAge: Int?

    var isActive: Bool { status == .active && kind != nil }
    var target: Int { kind?.target ?? 6 }

    mutating func clamp() {
        progress = min(target, max(0, progress))
    }
}

struct EducationState: Codable, Equatable {
    var progress = 0
    var credential = false
    var phase: EducationPhase = .highSchool
    var academicStanding = 52
    var schoolBelonging = 50
    var teacherSupport = 40
    var futureReadiness = 35
    var commitment: SchoolCommitment?
    var activity: SchoolActivity = .none
    var schoolEnvironment: SchoolEnvironment = .closeKnit
    var schoolReputation = 50
    var activityStage: SchoolActivityStage = .none
    var schoolMemories: [SchoolMemory] = []
    var frozenDefiningMemory: SchoolMemory?
    var highSchoolDiploma = false
    var postSchoolPath: PostSchoolPath = .undecided
    var commitmentYears: [SchoolCommitment: Int] = [:]
    var legacyFlags: Set<SchoolLegacyFlag> = []
    var launchInfluenceYearsRemaining = 0
    var legacySnapshot: SchoolLegacyModifiers?
    var college = CollegeState()
    var credentialKind: EducationCredentialKind = .none
    var credentialField: CollegeField?
    var recovery = EducationRecoveryState()

    mutating func clamp() {
        academicStanding = min(100, max(0, academicStanding))
        schoolBelonging = min(100, max(0, schoolBelonging))
        teacherSupport = min(100, max(0, teacherSupport))
        futureReadiness = min(100, max(0, futureReadiness))
        schoolReputation = min(100, max(0, schoolReputation))
        progress = max(0, progress)
        commitmentYears = commitmentYears.reduce(into: [:]) { result, pair in
            result[pair.key] = min(4, max(0, pair.value))
        }
        launchInfluenceYearsRemaining = min(7, max(0, launchInfluenceYearsRemaining))
        college.clamp()
        recovery.clamp()
        schoolMemories = Array(schoolMemories
            .sorted {
                if $0.significance == $1.significance { return $0.age > $1.age }
                return $0.significance > $1.significance
            }
            .prefix(6))
        if credential, credentialKind == .none { credentialKind = .legacyCredential }
    }

    func schoolYearTitle(for age: Int) -> String {
        highSchoolYear(for: age).title
    }

    func highSchoolYear(for age: Int) -> HighSchoolYear {
        HighSchoolYear(age: age)
    }

    var dominantCommitment: SchoolCommitment? {
        var best: SchoolCommitment?
        var bestCount = 0
        for commitment in SchoolCommitment.allCases {
            let count = commitmentYears[commitment, default: 0]
            if count > bestCount {
                best = commitment
                bestCount = count
            }
        }
        return best
    }

    var definingHighSchoolMemory: String? {
        if let frozenDefiningMemory { return frozenDefiningMemory.reviewLine }
        let priority: [SchoolLegacyFlag] = [
            .recommendationEarned, .mentorBacked, .carriedHomeLoad, .rumorScar,
            .financiallyExcluded, .activityIdentity, .academicBurnout, .sociallyRooted
        ]
        return priority.first(where: legacyFlags.contains)?.memoryLine
    }

    var hasSchoolLegacy: Bool {
        launchInfluenceYearsRemaining > 0 || !commitmentYears.isEmpty || !legacyFlags.isEmpty
    }

    var hasAlternativeCredential: Bool {
        credentialKind == .alternativeCredential
            || (recovery.status == .completed && recovery.kind == .alternativeCredential)
    }
}

extension EducationState {
    enum CodingKeys: String, CodingKey {
        case progress, credential, phase, academicStanding, schoolBelonging, teacherSupport
        case futureReadiness, commitment, activity, highSchoolDiploma, postSchoolPath
        case commitmentYears, legacyFlags, launchInfluenceYearsRemaining, legacySnapshot
        case college, credentialKind, credentialField, recovery
        case schoolEnvironment, schoolReputation, activityStage, schoolMemories, frozenDefiningMemory
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        progress = try c.decodeIfPresent(Int.self, forKey: .progress) ?? 0
        credential = try c.decodeIfPresent(Bool.self, forKey: .credential) ?? false
        phase = try c.decodeIfPresent(EducationPhase.self, forKey: .phase) ?? .postsecondary
        academicStanding = try c.decodeIfPresent(Int.self, forKey: .academicStanding) ?? 52
        schoolBelonging = try c.decodeIfPresent(Int.self, forKey: .schoolBelonging) ?? 50
        teacherSupport = try c.decodeIfPresent(Int.self, forKey: .teacherSupport) ?? 40
        futureReadiness = try c.decodeIfPresent(Int.self, forKey: .futureReadiness) ?? 35
        commitment = try c.decodeIfPresent(SchoolCommitment.self, forKey: .commitment)
        activity = try c.decodeIfPresent(SchoolActivity.self, forKey: .activity) ?? .none
        schoolEnvironment = try c.decodeIfPresent(SchoolEnvironment.self, forKey: .schoolEnvironment) ?? .closeKnit
        schoolReputation = try c.decodeIfPresent(Int.self, forKey: .schoolReputation) ?? 50
        activityStage = try c.decodeIfPresent(SchoolActivityStage.self, forKey: .activityStage)
            ?? (activity == .none ? .none : .committed)
        schoolMemories = try c.decodeIfPresent([SchoolMemory].self, forKey: .schoolMemories) ?? []
        frozenDefiningMemory = try c.decodeIfPresent(SchoolMemory.self, forKey: .frozenDefiningMemory)
        highSchoolDiploma = try c.decodeIfPresent(Bool.self, forKey: .highSchoolDiploma) ?? true
        postSchoolPath = try c.decodeIfPresent(PostSchoolPath.self, forKey: .postSchoolPath) ?? .undecided
        commitmentYears = try c.decodeIfPresent([SchoolCommitment: Int].self, forKey: .commitmentYears) ?? [:]
        legacyFlags = try c.decodeIfPresent(Set<SchoolLegacyFlag>.self, forKey: .legacyFlags) ?? []
        launchInfluenceYearsRemaining = try c.decodeIfPresent(Int.self, forKey: .launchInfluenceYearsRemaining) ?? 0
        legacySnapshot = try c.decodeIfPresent(SchoolLegacyModifiers.self, forKey: .legacySnapshot)
        college = try c.decodeIfPresent(CollegeState.self, forKey: .college) ?? CollegeState()
        credentialKind = try c.decodeIfPresent(EducationCredentialKind.self, forKey: .credentialKind) ?? (credential ? .legacyCredential : .none)
        credentialField = try c.decodeIfPresent(CollegeField.self, forKey: .credentialField)
        recovery = try c.decodeIfPresent(EducationRecoveryState.self, forKey: .recovery) ?? EducationRecoveryState()
        clamp()
    }
}

// MARK: - Partner

enum PartnerFlag: String, Codable, CaseIterable, Identifiable {
    case demanding, loyal, independent, supportive, adventurous, cautious
    case secure, guarded

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var isLearned: Bool { self == .secure || self == .guarded }

    static let coreCases: [PartnerFlag] = [.demanding, .loyal, .independent, .supportive, .adventurous, .cautious]
}

enum PartnerRuptureStage: String, Codable {
    case stable, confronted, promisedRepair, ultimatum
}

enum PartnerMood: String, Codable {
    case close, steady, uneasy, fractured

    var title: String { rawValue.capitalized }
}

enum RelationshipEndReason: String, Codable {
    case playerSeparated
    case partnerLeftAfterRupture

    var reviewText: String {
        switch self {
        case .playerSeparated: "you chose to leave"
        case .partnerLeftAfterRupture: "the relationship broke under unresolved strain"
        }
    }
}

struct FormerRelationship: Codable, Equatable, Identifiable {
    var id: String { "\(name)-\(startedAge)-\(endedAge)" }
    var name: String
    var startedAge: Int
    var endedAge: Int
    var finalStage: RelationshipStage
    var finalBond: Int
    var finalResentment: Int
    var reason: RelationshipEndReason

    var yearsTogether: Int { max(0, endedAge - startedAge) }
}

struct PartnerState: Codable, Equatable {
    var name: String
    var startedAge: Int
    var compatibility: Int
    var bond = 55
    var resentment = 0
    var lastInteractionAge: Int
    var committed = false
    var stage: RelationshipStage = .dating
    var ruptureStage: PartnerRuptureStage = .stable
    var lastMajorEventAge: Int?
    var attentionStreak = 0
    var neglectStreak = 0
    var flags: [PartnerFlag]
    var personality: PersonalityProfile
    var repairPromise = false
    var lastNote: String?
    /// Action raw value -> age when its personality response was last used.
    var personalityActionUsage: [String: Int] = [:]
    var activeSituation: RelationshipSituation?
    var resolvedSituations: [ResolvedSituation] = []

    init(
        name: String = "Morgan",
        startedAge: Int = 18,
        compatibility: Int,
        bond: Int = 55,
        resentment: Int = 0,
        lastInteractionAge: Int? = nil,
        committed: Bool = false,
        stage: RelationshipStage? = nil,
        ruptureStage: PartnerRuptureStage = .stable,
        lastMajorEventAge: Int? = nil,
        attentionStreak: Int = 0,
        neglectStreak: Int = 0,
        flags: [PartnerFlag] = [.supportive, .loyal],
        personality: PersonalityProfile? = nil,
        repairPromise: Bool = false,
        lastNote: String? = nil,
        personalityActionUsage: [String: Int] = [:]
    ) {
        self.name = name
        self.startedAge = startedAge
        self.compatibility = compatibility
        self.bond = bond
        self.resentment = resentment
        self.lastInteractionAge = lastInteractionAge ?? startedAge
        self.committed = committed
        self.stage = stage ?? (committed ? .committed : .dating)
        self.ruptureStage = ruptureStage
        self.lastMajorEventAge = lastMajorEventAge
        self.attentionStreak = attentionStreak
        self.neglectStreak = neglectStreak
        self.flags = flags
        self.personality = personality ?? PersonalitySystem.legacyPartner(flags: flags)
        self.repairPromise = repairPromise
        self.lastNote = lastNote
        self.personalityActionUsage = personalityActionUsage
    }

    var mood: PartnerMood {
        if bond >= 75 && resentment <= 20 { return .close }
        if bond >= 50 && resentment < 45 { return .steady }
        if bond >= 30 && resentment < 70 { return .uneasy }
        return .fractured
    }

    var coreFlags: [PartnerFlag] { flags.filter { !$0.isLearned } }
    var learnedFlags: [PartnerFlag] { flags.filter(\.isLearned) }

    func usedPersonalityResponse(for action: ActionID, at age: Int) -> Bool {
        personalityActionUsage[action.rawValue] == age
    }

    mutating func markPersonalityResponseUsed(for action: ActionID, at age: Int) {
        personalityActionUsage[action.rawValue] = age
    }

    mutating func clamp() {
        bond = min(100, max(0, bond))
        resentment = min(100, max(0, resentment))
        resolvedSituations = Array(resolvedSituations.prefix(4))
    }
}

// MARK: - Lightweight contextual NPCs

enum NPCRole: String, Codable, CaseIterable, Identifiable {
    case friend, teacher, boss

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    func isActive(in state: LifeState) -> Bool {
        switch self {
        case .friend: true
        case .teacher: state.flags.attendsSchool
        case .boss: state.job.tier.isEmployed
        }
    }
}

enum NPCImportance: String, Codable { case background, recurring, pivotal }

/// Activity is independent from importance: a pivotal person can sleep until
/// context wakes them, while a recent enemy can be immediately relevant.
enum CastActivity: String, Codable, Equatable {
    case active, dormant, pivotal, hostile
}

struct CastMemory: Codable, Equatable, Identifiable {
    var id: String { "\(age)-\(actionID.rawValue)" }
    let age: Int
    let actionID: ActionID
    let note: String
}

enum NPCFlag: String, Codable, CaseIterable, Identifiable {
    case sociable, dependable, critical, encouraging, ambitious, fair
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

/// Stable values and social dispositions that are not duplicates of the five
/// continuous personality axes. These remain private until behavior supplies
/// enough evidence for the player to recognize them.
enum CharacterTag: String, Codable, CaseIterable, Identifiable {
    case loyal, competitive, materialistic, familyOriented, honest
    case forgiving, vindictive, statusSeeking, principled, opportunistic
    case patient, impulsive, protective, generous, approvalSeeking
    case controlling, curious, creative, dutyBound, privatePerson

    var id: String { rawValue }
    var title: String {
        switch self {
        case .familyOriented: "Family-oriented"
        case .statusSeeking: "Status-seeking"
        case .approvalSeeking: "Approval-seeking"
        case .dutyBound: "Duty-bound"
        case .privatePerson: "Private"
        default: rawValue.capitalized
        }
    }

    var incompatibleTags: Set<CharacterTag> {
        switch self {
        case .forgiving: [.vindictive]
        case .vindictive: [.forgiving]
        case .principled: [.opportunistic]
        case .opportunistic: [.principled]
        case .patient: [.impulsive]
        case .impulsive: [.patient]
        case .honest: [.controlling]
        case .controlling: [.honest]
        default: []
        }
    }
}

enum NPCGoalKind: String, Codable, CaseIterable, Identifiable {
    case careerProgress, financialSecurity, family, status
    case creativeAchievement, stability, adventure, belonging

    var id: String { rawValue }
    var title: String {
        switch self {
        case .careerProgress: "Career progress"
        case .financialSecurity: "Financial security"
        case .creativeAchievement: "Creative achievement"
        default: rawValue.capitalized
        }
    }
}

struct NPCGoalState: Codable, Equatable, Identifiable {
    var kind: NPCGoalKind
    var progress = 20
    var momentum = 0
    var lastResolvedAge = 0
    var id: NPCGoalKind { kind }

    mutating func clamp() {
        progress = min(100, max(0, progress))
        momentum = min(20, max(-20, momentum))
    }
}

/// A person may enter the player's life through several connections over
/// time. The operational role still determines which domain wakes them.
enum NPCConnectionKind: String, Codable, CaseIterable, Identifiable {
    case friend, classmate, coworker, manager, neighbor, relative
    case formerPartner, professionalContact, mentor

    var id: String { rawValue }
    var title: String {
        switch self {
        case .formerPartner: "Former partner"
        case .professionalContact: "Professional contact"
        default: rawValue.capitalized
        }
    }
}

struct NPCConnection: Codable, Equatable, Identifiable {
    var kind: NPCConnectionKind
    var startedAge: Int
    var endedAge: Int?
    var id: String { "\(kind.rawValue)-\(startedAge)" }
    var isCurrent: Bool { endedAge == nil }
}

/// Internal evidence is intentionally richer than the UI. The player sees a
/// qualitative observation only after repeated or especially revealing acts.
struct NPCObservationEvidence: Codable, Equatable, Identifiable {
    var personalityFlag: PersonalityFlag?
    var stableTag: CharacterTag?
    var strength: Int
    var age: Int
    var reason: String
    var id: String {
        let trait = personalityFlag?.rawValue ?? stableTag?.rawValue ?? "unknown"
        return "\(age)-\(trait)-\(reason)"
    }

    mutating func clamp() { strength = min(3, max(1, strength)) }
}

enum NPCLearnedStance: String, Codable { case warm, wary }

enum NPCRelationshipTone: String, Codable {
    case close, warm, neutral, strained, hostile

    var title: String { rawValue.capitalized }
}

enum NPCCircumstanceKind: String, Codable, CaseIterable, Identifiable {
    case stressed, grieving, financiallyStrained, jealous, burnedOut, confident, thriving

    var id: String { rawValue }
    var title: String {
        switch self {
        case .financiallyStrained: "Financially strained"
        case .burnedOut: "Burned out"
        default: rawValue.capitalized
        }
    }
}

struct NPCCircumstance: Codable, Equatable, Identifiable {
    var id: String { "\(kind.rawValue)-\(startedAge)" }
    let kind: NPCCircumstanceKind
    var intensity: Int
    let startedAge: Int
    var expiresAge: Int

    mutating func clamp() { intensity = min(3, max(1, intensity)) }
}

enum NPCLifeChapter: String, Codable {
    case findingDirection, buildingCareer, established, setback, partnered, raisingFamily, relocated

    var title: String {
        switch self {
        case .findingDirection: "Finding direction"
        case .buildingCareer: "Building a career"
        case .established: "Established"
        case .setback: "In transition"
        case .partnered: "Building a relationship"
        case .raisingFamily: "Raising a family"
        case .relocated: "Living elsewhere"
        }
    }
}

/// A compressed independent life. It advances only for relevant people; a
/// dormant person catches up deterministically when context brings them back.
struct NPCIndependentLife: Codable, Equatable {
    var chapter: NPCLifeChapter = .findingDirection
    var careerStanding = 35
    var isPartnered = false
    var children = 0
    var movedAway = false
    var lastResolvedAge = 14
    var currentNote = "Their life is still taking shape."

    mutating func clamp() {
        careerStanding = min(100, max(0, careerStanding))
        children = min(6, max(0, children))
        lastResolvedAge = max(14, lastResolvedAge)
    }
}

struct NPCState: Codable, Equatable, Identifiable {
    /// Stable identity is deliberately separate from the role through which
    /// this person currently enters the player's life.
    var memberID = ""
    var id: String { memberID }
    var name: String
    var role: NPCRole
    var importance: NPCImportance
    var coreFlags: [NPCFlag]
    var personality: PersonalityProfile = .neutral
    var stableTags: [CharacterTag] = []
    var discoveredTags: [CharacterTag] = []
    var observationEvidence: [NPCObservationEvidence] = []
    var goals: [NPCGoalState] = []
    var connections: [NPCConnection] = []
    /// Bond is durable shared history. Rapport is the present relationship;
    /// they can move in opposite directions after a rupture.
    var bond = 18
    var rapport = 0
    var lastInteractionAge: Int
    var learnedStance: NPCLearnedStance?
    var personalityActionUsage: [String: Int] = [:]
    var activity: CastActivity = .active
    var memories: [CastMemory] = []
    /// Personality remains hidden until repeated contact or a revealing
    /// circumstance supplies evidence.
    var discoveredTraits: [PersonalityFlag] = []
    var circumstances: [NPCCircumstance] = []
    var independentLife = NPCIndependentLife()
    /// Bounded pacing guard for caused cast situations. This is not a random
    /// event cooldown: it belongs to the person whose history generated it.
    var lastSituationAge = 0

    var relationshipTone: NPCRelationshipTone {
        switch rapport {
        case 24...: .close
        case 7...: .warm
        case -7...6: .neutral
        case -24 ... -8: .strained
        default: .hostile
        }
    }

    var currentCircumstance: NPCCircumstance? {
        circumstances.sorted {
            if $0.intensity == $1.intensity { return $0.startedAge > $1.startedAge }
            return $0.intensity > $1.intensity
        }.first
    }

    var primaryGoal: NPCGoalState? {
        goals.max {
            if $0.progress == $1.progress { return $0.kind.rawValue > $1.kind.rawValue }
            return $0.progress < $1.progress
        }
    }

    func usedPersonalityResponse(for action: ActionID, at age: Int) -> Bool {
        personalityActionUsage[action.rawValue] == age
    }

    mutating func markPersonalityResponseUsed(for action: ActionID, at age: Int) {
        personalityActionUsage[action.rawValue] = age
    }

    mutating func clamp() {
        if memberID.isEmpty { memberID = role.rawValue }
        bond = min(100, max(0, bond))
        rapport = min(100, max(-100, rapport))
        memories = Array(memories.prefix(6))
        discoveredTraits = Array(Set(discoveredTraits)).sorted { $0.rawValue < $1.rawValue }
        stableTags = Array(Set(stableTags).sorted { $0.rawValue < $1.rawValue }.prefix(4))
        discoveredTags = Array(
            Set(discoveredTags.filter(stableTags.contains))
                .sorted { $0.rawValue < $1.rawValue }
                .prefix(4)
        )
            .sorted { $0.rawValue < $1.rawValue }
        observationEvidence = Array(observationEvidence.prefix(12)).map {
            var evidence = $0
            evidence.clamp()
            return evidence
        }
        goals = Array(Dictionary(grouping: goals, by: \.kind).values.compactMap(\.first)
            .sorted { $0.kind.rawValue < $1.kind.rawValue }.prefix(2)).map {
            var goal = $0
            goal.clamp()
            return goal
        }
        connections = Array(Dictionary(grouping: connections, by: \.kind).values.compactMap(\.first)
            .sorted { $0.kind.rawValue < $1.kind.rawValue }.prefix(6))
        circumstances = Array(circumstances.prefix(3)).map {
            var circumstance = $0
            circumstance.clamp()
            return circumstance
        }
        independentLife.clamp()
    }
}

struct NPCDirectory: Codable, Equatable {
    private var entries: [String: NPCState] = [:]

    subscript(_ role: NPCRole) -> NPCState? {
        get {
            entries.values
                .filter { $0.role == role }
                .sorted(by: Self.primaryOrder)
                .first
        }
        set {
            guard var member = newValue else {
                if let key = entries.first(where: { $0.value.role == role })?.key { entries[key] = nil }
                return
            }
            member.clamp()
            upsert(member)
        }
    }

    var all: [NPCState] { entries.values.sorted(by: Self.primaryOrder) }

    func members(for role: NPCRole) -> [NPCState] {
        entries.values.filter { $0.role == role }.sorted(by: Self.primaryOrder)
    }

    func member(id: String) -> NPCState? {
        entries.values.first { $0.memberID == id }
    }

    mutating func insert(_ member: NPCState) {
        var normalized = member
        if normalized.memberID.isEmpty {
            normalized.memberID = "\(normalized.role.rawValue)-\(entries.count + 1)"
        }
        normalized.clamp()
        upsert(normalized)
    }

    mutating func update(_ member: NPCState) { insert(member) }

    private mutating func upsert(_ member: NPCState) {
        if let key = entries.first(where: { $0.value.memberID == member.memberID })?.key, key != member.memberID {
            entries[key] = nil
        }
        entries[member.memberID] = member
    }

    private nonisolated static func primaryOrder(_ lhs: NPCState, _ rhs: NPCState) -> Bool {
        func score(_ member: NPCState) -> Int {
            let activity = switch member.activity { case .pivotal: 40; case .hostile: 35; case .active: 20; case .dormant: 0 }
            let importance = switch member.importance { case .pivotal: 8; case .recurring: 4; case .background: 0 }
            return activity + importance + min(10, abs(member.rapport) / 10)
        }
        if score(lhs) == score(rhs) {
            if lhs.lastInteractionAge == rhs.lastInteractionAge { return lhs.memberID < rhs.memberID }
            return lhs.lastInteractionAge > rhs.lastInteractionAge
        }
        return score(lhs) > score(rhs)
    }

    mutating func pruneInactiveBackground(in state: LifeState) {
        for member in all where !member.role.isActive(in: state) && member.importance == .background {
            entries[member.memberID] = nil
        }
    }
}

extension PartnerState {
    enum CodingKeys: String, CodingKey {
        case name, startedAge, compatibility, bond, resentment, lastInteractionAge, committed, stage
        case ruptureStage, lastMajorEventAge, attentionStreak, neglectStreak, flags
        case repairPromise, lastNote, personalityActionUsage, personality, activeSituation, resolvedSituations
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        startedAge = try c.decode(Int.self, forKey: .startedAge)
        compatibility = try c.decode(Int.self, forKey: .compatibility)
        bond = try c.decodeIfPresent(Int.self, forKey: .bond) ?? 55
        resentment = try c.decodeIfPresent(Int.self, forKey: .resentment) ?? 0
        lastInteractionAge = try c.decodeIfPresent(Int.self, forKey: .lastInteractionAge) ?? startedAge
        committed = try c.decodeIfPresent(Bool.self, forKey: .committed) ?? false
        stage = try c.decodeIfPresent(RelationshipStage.self, forKey: .stage) ?? (committed ? .committed : .dating)
        ruptureStage = try c.decodeIfPresent(PartnerRuptureStage.self, forKey: .ruptureStage) ?? .stable
        lastMajorEventAge = try c.decodeIfPresent(Int.self, forKey: .lastMajorEventAge)
        attentionStreak = try c.decodeIfPresent(Int.self, forKey: .attentionStreak) ?? 0
        neglectStreak = try c.decodeIfPresent(Int.self, forKey: .neglectStreak) ?? 0
        flags = try c.decodeIfPresent([PartnerFlag].self, forKey: .flags) ?? [.supportive, .loyal]
        personality = try c.decodeIfPresent(PersonalityProfile.self, forKey: .personality)
            ?? PersonalitySystem.legacyPartner(flags: flags)
        repairPromise = try c.decodeIfPresent(Bool.self, forKey: .repairPromise) ?? false
        lastNote = try c.decodeIfPresent(String.self, forKey: .lastNote)
        personalityActionUsage = try c.decodeIfPresent([String: Int].self, forKey: .personalityActionUsage) ?? [:]
        activeSituation = try c.decodeIfPresent(RelationshipSituation.self, forKey: .activeSituation)
        resolvedSituations = try c.decodeIfPresent([ResolvedSituation].self, forKey: .resolvedSituations) ?? []
        clamp()
    }
}

extension NPCState {
    enum CodingKeys: String, CodingKey {
        case memberID, name, role, importance, coreFlags, personality, stableTags, discoveredTags
        case observationEvidence, goals, connections, bond, rapport, lastInteractionAge
        case learnedStance, personalityActionUsage, activity, memories, discoveredTraits
        case circumstances, independentLife, lastSituationAge
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        role = try c.decode(NPCRole.self, forKey: .role)
        memberID = try c.decodeIfPresent(String.self, forKey: .memberID) ?? role.rawValue
        name = try c.decode(String.self, forKey: .name)
        importance = try c.decodeIfPresent(NPCImportance.self, forKey: .importance) ?? .background
        coreFlags = try c.decodeIfPresent([NPCFlag].self, forKey: .coreFlags) ?? []
        personality = try c.decodeIfPresent(PersonalityProfile.self, forKey: .personality)
            ?? PersonalitySystem.legacyNPC(flags: coreFlags)
        stableTags = try c.decodeIfPresent([CharacterTag].self, forKey: .stableTags) ?? []
        discoveredTags = try c.decodeIfPresent([CharacterTag].self, forKey: .discoveredTags) ?? []
        observationEvidence = try c.decodeIfPresent([NPCObservationEvidence].self, forKey: .observationEvidence) ?? []
        goals = try c.decodeIfPresent([NPCGoalState].self, forKey: .goals) ?? []
        connections = try c.decodeIfPresent([NPCConnection].self, forKey: .connections) ?? []
        rapport = try c.decodeIfPresent(Int.self, forKey: .rapport) ?? 0
        bond = try c.decodeIfPresent(Int.self, forKey: .bond) ?? max(12, min(70, 18 + max(0, rapport) / 2))
        lastInteractionAge = try c.decodeIfPresent(Int.self, forKey: .lastInteractionAge) ?? 14
        learnedStance = try c.decodeIfPresent(NPCLearnedStance.self, forKey: .learnedStance)
        personalityActionUsage = try c.decodeIfPresent([String: Int].self, forKey: .personalityActionUsage) ?? [:]
        activity = try c.decodeIfPresent(CastActivity.self, forKey: .activity)
            ?? (importance == .pivotal ? .pivotal : .active)
        memories = try c.decodeIfPresent([CastMemory].self, forKey: .memories) ?? []
        discoveredTraits = try c.decodeIfPresent([PersonalityFlag].self, forKey: .discoveredTraits) ?? []
        circumstances = try c.decodeIfPresent([NPCCircumstance].self, forKey: .circumstances) ?? []
        independentLife = try c.decodeIfPresent(NPCIndependentLife.self, forKey: .independentLife)
            ?? NPCIndependentLife(lastResolvedAge: lastInteractionAge)
        lastSituationAge = try c.decodeIfPresent(Int.self, forKey: .lastSituationAge) ?? 0
        clamp()
    }
}

// MARK: - Influence, stance, life-shape

struct YearInfluenceSnapshot: Codable, Equatable {
    let age: Int
    let scores: InfluenceVector
    let influentialAction: ActionID?
}

struct PlayerInfluenceLedger: Codable, Equatable {
    var current = InfluenceVector()
    var mostRecentInfluentialAction: ActionID?
    var recentYears: [YearInfluenceSnapshot] = []

    mutating func record(action: DomainAction, partnerExists: Bool) {
        var influence = action.influence
        if !partnerExists { influence.family = 0 }
        guard !influence.isEmpty else { return }
        current.add(influence)
        mostRecentInfluentialAction = action.id
    }

    mutating func closeYear(age: Int) -> YearInfluenceSnapshot {
        let snapshot = YearInfluenceSnapshot(age: age, scores: current, influentialAction: mostRecentInfluentialAction)
        recentYears.insert(snapshot, at: 0)
        recentYears = Array(recentYears.prefix(3))
        current = InfluenceVector()
        mostRecentInfluentialAction = nil
        return snapshot
    }
}

/// Lightweight D4 stance derived from this year's influence.
enum LifeStance: String, Codable, CaseIterable, Identifiable {
    case pushCareer, protectHealth, connect, stabilize, drift

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pushCareer: "Push career"
        case .protectHealth: "Protect health"
        case .connect: "Connect"
        case .stabilize: "Stabilize"
        case .drift: "Drift"
        }
    }

    var shortLabel: String {
        switch self {
        case .pushCareer: "career"
        case .protectHealth: "health"
        case .connect: "people"
        case .stabilize: "steady ground"
        case .drift: "drift"
        }
    }
}

/// Residue shape of recent years — biases quiet flavor and year summary.
enum LifeShape: String, Codable, CaseIterable, Identifiable {
    case driven, connected, careful, loose, pragmatic, balanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .driven: "Driven current"
        case .connected: "People-centered"
        case .careful: "Careful edges"
        case .loose: "Loose edges"
        case .pragmatic: "Pragmatic"
        case .balanced: "Balanced"
        }
    }

    var accentName: String {
        switch self {
        case .driven: "orange"
        case .connected: "pink"
        case .careful: "blue"
        case .loose: "purple"
        case .pragmatic: "gray"
        case .balanced: "green"
        }
    }
}

struct MomentumState: Codable, Equatable {
    var stance: LifeStance = .drift
    var shape: LifeShape = .balanced
    /// 0–5 strength of current momentum.
    var intensity: Int = 0
    var recentStances: [LifeStance] = []

    var isActive: Bool { intensity > 0 || shape != .balanced }

    var stripLabel: String {
        if intensity == 0 && shape == .balanced { return "Shape: open" }
        return "Shape: \(shape.title.lowercased()) · \(stance.shortLabel)"
    }

    mutating func absorb(snapshot: YearInfluenceSnapshot) {
        let scores = snapshot.scores
        let stance: LifeStance
        if scores.work >= scores.family && scores.work >= scores.stability && scores.work >= scores.risk && scores.work > 0 {
            stance = .pushCareer
        } else if scores.family >= scores.work && scores.family >= scores.stability && scores.family > 0 {
            stance = .connect
        } else if scores.stability >= scores.work && scores.stability >= scores.risk && scores.stability > 0 {
            stance = .stabilize
        } else if scores.risk > scores.work && scores.risk > scores.family {
            stance = .drift
        } else if scores.stability > 0 || scores.work == 0 && scores.family == 0 {
            stance = scores.stability > 0 ? .protectHealth : .drift
        } else {
            stance = .drift
        }
        self.stance = stance
        recentStances.insert(stance, at: 0)
        recentStances = Array(recentStances.prefix(4))
        intensity = min(5, max(scores.work, scores.family, scores.stability, scores.risk))
        shape = Self.deriveShape(from: recentStances)
    }

    private static func deriveShape(from stances: [LifeStance]) -> LifeShape {
        guard !stances.isEmpty else { return .balanced }
        let career = stances.filter { $0 == .pushCareer }.count
        let care = stances.filter { $0 == .protectHealth || $0 == .stabilize }.count
        let connect = stances.filter { $0 == .connect }.count
        let drift = stances.filter { $0 == .drift }.count
        if career >= 2 && career > care { return .driven }
        if care >= 2 && care > career { return .careful }
        if drift >= 2 { return .loose }
        if career >= 1 && care >= 1 { return .pragmatic }
        if connect >= 2 { return .connected }
        return .balanced
    }
}

enum YearSummaryImportance: String, Codable, Equatable, Comparable {
    case quiet
    case notable
    case major
    case critical

    nonisolated private var rank: Int {
        switch self {
        case .quiet: 0
        case .notable: 1
        case .major: 2
        case .critical: 3
        }
    }

    nonisolated static func < (lhs: YearSummaryImportance, rhs: YearSummaryImportance) -> Bool {
        lhs.rank < rhs.rank
    }
}

struct YearDevelopment: Codable, Equatable, Identifiable {
    enum Kind: String, Codable {
        case development
        case chapter
        case warning
        case world
    }

    let id: String
    let text: String
    var kind: Kind = .development
    var domain: ConsequenceDomain? = nil
}

struct YearSummary: Codable, Equatable {
    var age: Int
    var headline: String
    var deltas: DeltaSummary
    var developments: [YearDevelopment]
    var importance: YearSummaryImportance
    var stanceTitle: String?
    var shapeTitle: String?
    var focusNote: String?
    var silenceNote: String?
    var wasQuiet: Bool
    var stageTransition: String? = nil
    var mortalityWarning: String? = nil
    var worldNews: WorldNews? = nil

    var bullets: [String] {
        get { developments.map(\.text) }
        set { developments = Self.developments(from: newValue) }
    }

    var isEmpty: Bool {
        developments.isEmpty && stanceTitle == nil && shapeTitle == nil && focusNote == nil
            && silenceNote == nil && worldNews == nil
    }

    init(
        bullets: [String],
        stanceTitle: String?,
        shapeTitle: String?,
        focusNote: String?,
        silenceNote: String?,
        wasQuiet: Bool,
        stageTransition: String? = nil,
        mortalityWarning: String? = nil,
        worldNews: WorldNews? = nil,
        age: Int = 0,
        headline: String = "Year Summary",
        deltas: DeltaSummary = DeltaSummary(),
        importance: YearSummaryImportance? = nil
    ) {
        self.age = age
        self.headline = headline
        self.deltas = deltas
        developments = Self.developments(from: bullets)
        self.importance = importance ?? (wasQuiet ? .quiet : .notable)
        self.stanceTitle = stanceTitle
        self.shapeTitle = shapeTitle
        self.focusNote = focusNote
        self.silenceNote = silenceNote
        self.wasQuiet = wasQuiet
        self.stageTransition = stageTransition
        self.mortalityWarning = mortalityWarning
        self.worldNews = worldNews
    }

    private enum CodingKeys: String, CodingKey {
        case age, headline, deltas, developments, importance
        case bullets, stanceTitle, shapeTitle, focusNote, silenceNote, wasQuiet
        case stageTransition, mortalityWarning, worldNews
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 0
        headline = try container.decodeIfPresent(String.self, forKey: .headline) ?? "Year Summary"
        deltas = try container.decodeIfPresent(DeltaSummary.self, forKey: .deltas) ?? DeltaSummary()
        if let decoded = try container.decodeIfPresent([YearDevelopment].self, forKey: .developments) {
            developments = decoded
        } else {
            developments = Self.developments(
                from: try container.decodeIfPresent([String].self, forKey: .bullets) ?? []
            )
        }
        stanceTitle = try container.decodeIfPresent(String.self, forKey: .stanceTitle)
        shapeTitle = try container.decodeIfPresent(String.self, forKey: .shapeTitle)
        focusNote = try container.decodeIfPresent(String.self, forKey: .focusNote)
        silenceNote = try container.decodeIfPresent(String.self, forKey: .silenceNote)
        wasQuiet = try container.decodeIfPresent(Bool.self, forKey: .wasQuiet) ?? false
        stageTransition = try container.decodeIfPresent(String.self, forKey: .stageTransition)
        mortalityWarning = try container.decodeIfPresent(String.self, forKey: .mortalityWarning)
        worldNews = try container.decodeIfPresent(WorldNews.self, forKey: .worldNews)
        importance = try container.decodeIfPresent(YearSummaryImportance.self, forKey: .importance)
            ?? (wasQuiet ? .quiet : .notable)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(age, forKey: .age)
        try container.encode(headline, forKey: .headline)
        try container.encode(deltas, forKey: .deltas)
        try container.encode(developments, forKey: .developments)
        try container.encode(importance, forKey: .importance)
        try container.encodeIfPresent(stanceTitle, forKey: .stanceTitle)
        try container.encodeIfPresent(shapeTitle, forKey: .shapeTitle)
        try container.encodeIfPresent(focusNote, forKey: .focusNote)
        try container.encodeIfPresent(silenceNote, forKey: .silenceNote)
        try container.encode(wasQuiet, forKey: .wasQuiet)
        try container.encodeIfPresent(stageTransition, forKey: .stageTransition)
        try container.encodeIfPresent(mortalityWarning, forKey: .mortalityWarning)
        try container.encodeIfPresent(worldNews, forKey: .worldNews)
    }

    private static func developments(from lines: [String]) -> [YearDevelopment] {
        lines.enumerated().map { index, line in
            YearDevelopment(id: "development-\(index)-\(line)", text: line)
        }
    }
}

// MARK: - Recovery & history

enum RecoveryKind: String, Codable { case financial, health }

enum LifeStage: String, Codable, CaseIterable, Identifiable {
    case adolescence, launch, build, pressure, legacy

    var id: String { rawValue }

    static func stage(for age: Int) -> LifeStage {
        if age < 18 { return .adolescence }
        if age < 25 { return .launch }
        if age < 45 { return .build }
        if age < 65 { return .pressure }
        return .legacy
    }

    var title: String {
        switch self {
        case .adolescence: "High School"
        case .launch: "Launch"
        case .build: "Build"
        case .pressure: "Pressure"
        case .legacy: "Legacy"
        }
    }

    var ageBand: String {
        switch self {
        case .adolescence: "14–17"
        case .launch: "18–24"
        case .build: "25–44"
        case .pressure: "45–64"
        case .legacy: "65+"
        }
    }

    var focusLine: String {
        switch self {
        case .adolescence: "Grades, belonging, and who you are becoming."
        case .launch: "Education, entry work, dating, thin runway."
        case .build: "Skilled work, commitment, rising costs."
        case .pressure: "Plateau, consequences, harder trade-offs."
        case .legacy: "Health, relationships, what you leave."
        }
    }

    var transitionHeadline: String {
        switch self {
        case .adolescence: "High School Begins"
        case .launch: "You Are Launching"
        case .build: "The Building Years Begin"
        case .pressure: "Pressure Arrives"
        case .legacy: "The Legacy Chapter Opens"
        }
    }

    var transitionDetail: String {
        switch self {
        case .adolescence: "The halls are small enough for every choice to follow you."
        case .launch: "These years are for footing — school, first work, first real risks."
        case .build: "The next stretch rewards direction. Work, relationships, and money compound."
        case .pressure: "Trade-offs get louder. Health, career plateau, and home all keep score."
        case .legacy: "Work slows. The body speaks first. What you kept and who you kept matter most."
        }
    }
}

enum MortalityPressure: String, Codable, Equatable {
    case stable, vulnerable, critical

    var title: String { rawValue.capitalized }

    var detail: String {
        switch self {
        case .stable: "Your body is holding."
        case .vulnerable: "A hard year could change everything."
        case .critical: "You need care now — not later."
        }
    }
}

// MARK: - Derived narrative vibe

enum NarrativeVibe: String, Equatable {
    case grounded, driven, connected, strained, crisis

    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .grounded: "circle.dotted"
        case .driven: "arrow.up.right"
        case .connected: "person.2.fill"
        case .strained: "waveform.path.ecg"
        case .crisis: "exclamationmark.triangle.fill"
        }
    }

}

enum NarrativeVibeResolver {
    static func resolve(_ state: LifeState) -> NarrativeVibe {
        if state.recovery != nil
            || state.mortalityPressure == .critical
            || state.stats.health <= 15
            || state.finance.economy.shortfallYears >= 2 {
            return .crisis
        }

        let relationshipStrain = state.partner.map { $0.resentment >= 55 || $0.bond <= 30 } ?? false
        if state.cash < 5_000 || state.stats.health < 40 || state.stats.play < 30 || relationshipStrain {
            return .strained
        }

        let connectionStrong = state.partner.map { $0.bond >= 70 && $0.resentment <= 25 } ?? false
        if state.momentum.stance == .connect || state.influenceLedger.current.family >= 2 || connectionStrong {
            return .connected
        }

        if state.momentum.shape == .driven || state.influenceLedger.current.work >= 3 {
            return .driven
        }
        return .grounded
    }

    static func flavor(_ text: String, state: LifeState) -> String {
        let sentences = contextSentences(for: state)
        guard !sentences.isEmpty, !sentences.contains(where: text.contains) else { return text }
        let index = stableIndex(for: text, state: state, count: sentences.count)
        let sentence = sentences[index]
        return "\(text) \(sentence)"
    }

    /// Presentation-only variation derived from immutable run identity. It never
    /// consumes simulation RNG, so flavor cannot change gameplay or replay order.
    private static func stableIndex(for text: String, state: LifeState, count: Int) -> Int {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        hash ^= state.runSeed
        hash = hash &* 1_099_511_628_211
        hash ^= UInt64(state.character.age)
        return Int(hash % UInt64(count))
    }

    private static func contextSentences(for state: LifeState) -> [String] {
        switch resolve(state) {
        case .grounded:
            return []
        case .driven:
            if state.influenceLedger.current.work >= 3 {
                return [
                    "Work has started setting the rhythm for everything else.",
                    "The ambition is real; so is what it keeps asking from you.",
                    "Even away from the job, part of you is still on the clock."
                ]
            }
            return [
                "You keep choosing momentum, and your life is beginning to show it.",
                "The harder direction has become a habit now.",
                "Standing still feels less natural than pushing again."
            ]
        case .connected:
            if let partner = state.partner, partner.bond >= 70 {
                return [
                    "You are not carrying this season alone.",
                    "What happens to you now lands in a shared life.",
                    "There is someone close enough to feel the shift with you."
                ]
            }
            return [
                "The people around you are part of how this moment lands.",
                "Connection has become more than background noise in your life.",
                "This choice reaches farther than you alone."
            ]
        case .strained:
            if let partner = state.partner, partner.resentment >= 55 || partner.bond <= 30 {
                return [
                    "At home, even small choices now carry old weight.",
                    "The distance between you changes how this lands.",
                    "Your relationship has stopped absorbing the strain quietly."
                ]
            }
            if state.cash < 5_000 {
                return [
                    "There is not much margin left for a bad turn.",
                    "Money pressure follows the choice into the rest of your day.",
                    "Every decision feels louder when the account is this thin."
                ]
            }
            if state.stats.health < 40 {
                return [
                    "Your body is making the cost harder to ignore.",
                    "Whatever you choose, your health is already in the room.",
                    "You have less physical margin than the moment demands."
                ]
            }
            return [
                "The life around this choice is already running low on room.",
                "You can feel how little slack remains in the week.",
                "Even relief arrives with something else waiting behind it."
            ]
        case .crisis:
            if state.recovery?.kind == .financial || state.finance.economy.shortfallYears >= 2 {
                return [
                    "Right now, every dollar is tied to staying afloat.",
                    "The financial emergency makes everything else feel temporary.",
                    "There is no clean choice while the account is underwater."
                ]
            }
            if state.recovery?.kind == .health || state.mortalityPressure == .critical || state.stats.health <= 15 {
                return [
                    "Your body has turned the rest of life into a shorter conversation.",
                    "Until your health stabilizes, every other plan is provisional.",
                    "The immediate question is whether your body can keep carrying you."
                ]
            }
            return [
                "The crisis has narrowed your world to what happens next.",
                "Everything beyond the immediate danger feels provisional.",
                "There is almost no margin left between pressure and consequence."
            ]
        }
    }
}

// MARK: - Derived narrative context and timeline

/// Read-only narrative framing for the dashboard. It interprets existing,
/// domain-owned state; it never creates consequences or changes a simulation.
struct CurrentLifeNarrative: Equatable {
    let chapter: String
    let context: String
    let symbol: String
    let vibe: NarrativeVibe
}

enum CurrentLifeNarrativeResolver {
    static func resolve(for state: LifeState) -> CurrentLifeNarrative {
        let vibe = NarrativeVibeResolver.resolve(state)
        if let thread = state.lifeThreads
            .filter({ $0.resolution != .resolved })
            .sorted(by: { $0.intensity == $1.intensity ? $0.openedAge < $1.openedAge : $0.intensity > $1.intensity })
            .first {
            return CurrentLifeNarrative(
                chapter: thread.headline,
                context: contextualized(thread.detail, state: state),
                symbol: symbol(for: thread.kind),
                vibe: vibe
            )
        }

        if state.recovery?.kind == .financial {
            return CurrentLifeNarrative(chapter: "Holding the financial line", context: "Stabilize the household before the next year closes in.", symbol: "banknote.fill", vibe: vibe)
        }
        if state.recovery?.kind == .health {
            return CurrentLifeNarrative(chapter: "Recovery comes first", context: "Your body needs enough margin before life can move forward again.", symbol: "cross.case.fill", vibe: vibe)
        }
        if let partner = state.partner, partner.resentment >= 40 || partner.bond < 40 {
            return CurrentLifeNarrative(chapter: "Home needs your attention", context: "\(partner.name) is feeling the weight of this season. What you do next will be remembered.", symbol: "heart.fill", vibe: vibe)
        }
        if state.lifeStage == .adolescence {
            return CurrentLifeNarrative(chapter: "Becoming someone", context: "The habits you build in school are beginning to decide which adult doors open.", symbol: "book.closed.fill", vibe: vibe)
        }
        if state.job.tier == .unemployed {
            return CurrentLifeNarrative(chapter: "Finding your footing", context: "Work is not settled yet. The next practical move can reopen the life around it.", symbol: "briefcase.fill", vibe: vibe)
        }
        if state.lifeStage == .legacy {
            return CurrentLifeNarrative(chapter: "Living with what lasted", context: "This chapter is less about speed and more about what your choices have made durable.", symbol: "clock.arrow.circlepath", vibe: vibe)
        }
        return CurrentLifeNarrative(
            chapter: defaultChapter(for: state),
            context: defaultContext(for: vibe, state: state),
            symbol: vibe.symbol,
            vibe: vibe
        )
    }

    private static func defaultChapter(for state: LifeState) -> String {
        switch state.lifeStage {
        case .launch: "Starting to choose a direction"
        case .build: "Building a life that can hold"
        case .pressure: "Deciding what is worth carrying"
        case .adolescence, .legacy: state.lifeStage.title
        }
    }

    private static func defaultContext(for vibe: NarrativeVibe, state: LifeState) -> String {
        switch vibe {
        case .grounded: "Nothing is forcing the next move. That makes this a chance to choose what you want to grow."
        case .driven: "Momentum is building. The question is whether the rest of your life can move at the same pace."
        case .connected: "The people around you are part of how this season lands, not background to it."
        case .strained: "There is less room for an unexamined choice than there used to be."
        case .crisis: "The immediate task is to create enough stability for a future choice to matter."
        }
    }

    private static func contextualized(_ detail: String, state: LifeState) -> String {
        guard !detail.isEmpty else { return defaultContext(for: NarrativeVibeResolver.resolve(state), state: state) }
        return detail
    }

    private static func symbol(for kind: LifeThreadKind) -> String {
        switch kind {
        case .layoff: "briefcase.fill"
        case .debt: "banknote.fill"
        case .burnout: "flame.fill"
        case .familyConflict: "heart.fill"
        case .illness: "cross.case.fill"
        case .legalTrouble: "exclamationmark.shield.fill"
        case .majorDecision: "arrow.triangle.branch"
        }
    }
}

enum LifeContextDomain: String, CaseIterable, Identifiable {
    case relationships, family, career, finances, health
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .relationships: "person.2.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .career: "briefcase.fill"
        case .finances: "banknote.fill"
        case .health: "heart.text.square.fill"
        }
    }
}

struct LifeContextSignal: Identifiable, Equatable {
    let domain: LifeContextDomain
    let headline: String
    let detail: String
    let urgency: Int
    var id: String { domain.rawValue }
}

/// Distills sovereign domain state into the three facts a player should grasp
/// first. This is presentation-only: no domain logic or mutation lives here.
enum LifeContextResolver {
    static func topSignals(for state: LifeState, limit: Int = 3) -> [LifeContextSignal] {
        Array(allSignals(for: state).sorted {
            if $0.urgency == $1.urgency { return $0.domain.rawValue < $1.domain.rawValue }
            return $0.urgency > $1.urgency
        }.prefix(limit))
    }

    static func allSignals(for state: LifeState) -> [LifeContextSignal] {
        let relationship: LifeContextSignal
        if let partner = state.partner {
            let strained = partner.resentment >= 45 || partner.bond < 40
            relationship = LifeContextSignal(
                domain: .relationships,
                headline: "\(partner.name) · \(partner.mood.title)",
                detail: strained ? "The relationship needs visible repair." : "Your shared life is holding.",
                urgency: strained ? 90 : 35
            )
        } else if let person = state.npcs.all.first(where: { $0.bond >= 25 }) {
            relationship = LifeContextSignal(
                domain: .relationships,
                headline: "\(person.name) · \(person.relationshipTone.title)",
                detail: "Bond \(person.bond) keeps this person relevant.",
                urgency: person.relationshipTone == .hostile || person.relationshipTone == .strained ? 75 : 30
            )
        } else {
            relationship = LifeContextSignal(domain: .relationships, headline: "Few close ties", detail: "Your wider network remains lightly connected.", urgency: 28)
        }

        let estranged = state.family.contacts.filter { $0.stance == .estranged }.count
        let family = LifeContextSignal(
            domain: .family,
            headline: state.family.children.isEmpty ? "No children" : "\(state.family.children.count) child\(state.family.children.count == 1 ? "" : "ren")",
            detail: estranged > 0 ? "\(estranged) family relationship\(estranged == 1 ? " is" : "s are") estranged." : "Care load \(state.family.caregivingLoad).",
            urgency: estranged > 0 ? 78 : min(65, 25 + state.family.caregivingLoad)
        )

        let career = LifeContextSignal(
            domain: .career,
            headline: "\(state.career.careerClass.title) · \(state.career.level.rawValue.capitalized)",
            detail: state.career.level == .unemployed ? "Work is unsettled." : "Performance \(state.career.performance) · burnout \(state.career.burnout).",
            urgency: state.career.level == .unemployed ? 88 : max(32, state.career.burnout)
        )

        let monthlyNet = state.finance.annualLedger.net / 12
        let finances = LifeContextSignal(
            domain: .finances,
            headline: "\(monthlyNet >= 0 ? "+" : "")$\(monthlyNet)/mo",
            detail: state.totalDebt > 0 ? "$\(state.totalDebt) total debt." : "No outstanding debt.",
            urgency: state.finance.financialStress >= 60 || monthlyNet < 0 ? 92 : max(30, state.finance.financialStress)
        )

        let health = LifeContextSignal(
            domain: .health,
            headline: "Health \(state.stats.health)%",
            detail: state.health.conditions.isEmpty ? "No active diagnosed condition." : "\(state.health.conditions.count) condition\(state.health.conditions.count == 1 ? "" : "s") needs attention.",
            urgency: max(25, 100 - state.stats.health)
        )
        return [relationship, family, career, finances, health]
    }
}

struct LifeTimelineEntry: Codable, Identifiable, Equatable {
    let id: UInt64
    let age: Int
    let headline: String
    let detail: String
}

/// A compact, chronological memory of defining moments. The complete journal
/// remains available separately; ordinary action feedback does not crowd this view.
enum LifeTimelineResolver {
    nonisolated static func milestones(for state: LifeState, limit: Int = 12) -> [LifeTimelineEntry] {
        if !state.timeline.isEmpty {
            return Array(state.timeline.suffix(limit))
        }
        let entries = state.history.reversed().filter(isMilestone)
        return Array(entries.suffix(limit)).map {
            LifeTimelineEntry(id: $0.id, age: $0.age, headline: $0.headline, detail: $0.detail)
        }
    }

    nonisolated static func isMilestone(_ entry: HistoryEntry) -> Bool {
        if let summary = entry.yearSummary {
            return summary.importance >= .major || summary.stageTransition != nil || summary.mortalityWarning != nil
        }
        let headline = entry.headline.lowercased()
        return ["graduat", "promotion", "retire", "separation", "foreclosure", "recovery", "ended", "complete", "died"].contains {
            headline.contains($0)
        }
    }
}

enum EndReason: String, Codable, Equatable {
    case naturalCauses, unresolvedHealthCrisis, unresolvedFinancialCrisis, prisonKilling, maximumAge

    var title: String {
        switch self {
        case .naturalCauses: "Natural causes"
        case .unresolvedHealthCrisis: "Unresolved health crisis"
        case .unresolvedFinancialCrisis: "Unresolved financial crisis"
        case .prisonKilling: "Killed in prison"
        case .maximumAge: "A long life, completed"
        }
    }
}

/// Hard ceiling so every run terminates.
enum LifeLimits {
    static let maximumAge = 92
    static let lateLifeStart = 65
}

struct RecoveryWindow: Codable, Equatable {
    var kind: RecoveryKind
    var openedAge: Int
}

struct HistoryEntry: Equatable, Identifiable {
    let id: UInt64
    let age: Int
    let headline: String
    let detail: String
    let deltas: DeltaSummary
    var isSilence: Bool = false
    var yearSummary: YearSummary? = nil

    init(
        id: UInt64,
        age: Int,
        headline: String,
        detail: String,
        deltas: DeltaSummary,
        isSilence: Bool = false,
        yearSummary: YearSummary? = nil
    ) {
        self.id = id
        self.age = age
        self.headline = headline
        self.detail = detail
        self.deltas = deltas
        self.isSilence = isSilence
        self.yearSummary = yearSummary
    }
}

extension HistoryEntry: Codable {
    enum CodingKeys: String, CodingKey {
        case id, age, headline, detail, deltas, isSilence, yearSummary
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UInt64.self, forKey: .id)
        age = try c.decode(Int.self, forKey: .age)
        headline = try c.decode(String.self, forKey: .headline)
        detail = try c.decode(String.self, forKey: .detail)
        deltas = try c.decodeIfPresent(DeltaSummary.self, forKey: .deltas) ?? DeltaSummary()
        isSilence = try c.decodeIfPresent(Bool.self, forKey: .isSilence) ?? false
        yearSummary = try c.decodeIfPresent(YearSummary.self, forKey: .yearSummary)
    }
}

// MARK: - LifeState

/// Named lifetime counters shared by domain systems. The JSON keys retain
/// their historical names so existing saves still load.
enum IncomeSource: String, Codable, CaseIterable, Hashable {
    case salary, sideWork, crime, enterprise, rent, assetSale, investment, inheritance, special, diamond
}

private struct IncomeSourceTotal: Codable {
    var source: IncomeSource
    var amount: Int
}

struct LifeAggregateState: Codable, Equatable {
    var annualNet = 0
    var lifetimeIncome = 0
    var lifetimeNet = 0
    var peakCash = 0
    var yearsWorked = 0
    var soloCrimeAttempts = 0
    var soloCrimeSuccesses = 0
    var personalityPivotalEvents = 0
    var lastPersonalityPivotalAge = -100
    var talentUses = 0
    var assetReciprocityUsed = 0
    var lifetimeIncomeBySource: [IncomeSource: Int] = [:]
    var ageAtFirstMillionNetWorth: Int?
    var ageAtFirstTenMillionNetWorth: Int?
    var prisonYearsServed = 0

    private enum CodingKeys: String, CodingKey {
        case annualNet, lifetimeIncome, lifetimeNet, peakCash, yearsWorked
        case soloCrimeAttempts, soloCrimeSuccesses, personalityPivotalEvents
        case lastPersonalityPivotalAge, talentUses, assetReciprocityUsed, lifetimeIncomeBySource
        case ageAtFirstMillionNetWorth, ageAtFirstTenMillionNetWorth, prisonYearsServed
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        annualNet = try c.decodeIfPresent(Int.self, forKey: .annualNet) ?? 0
        lifetimeIncome = try c.decodeIfPresent(Int.self, forKey: .lifetimeIncome) ?? 0
        if let savedLifetimeNet = try c.decodeIfPresent(Int.self, forKey: .lifetimeNet) {
            lifetimeNet = savedLifetimeNet
        } else {
            lifetimeNet = try c.decodeIfPresent(Int.self, forKey: .annualNet) ?? 0
        }
        peakCash = try c.decodeIfPresent(Int.self, forKey: .peakCash) ?? 0
        yearsWorked = try c.decodeIfPresent(Int.self, forKey: .yearsWorked) ?? 0
        soloCrimeAttempts = try c.decodeIfPresent(Int.self, forKey: .soloCrimeAttempts) ?? 0
        soloCrimeSuccesses = try c.decodeIfPresent(Int.self, forKey: .soloCrimeSuccesses) ?? 0
        personalityPivotalEvents = try c.decodeIfPresent(Int.self, forKey: .personalityPivotalEvents) ?? 0
        lastPersonalityPivotalAge = try c.decodeIfPresent(Int.self, forKey: .lastPersonalityPivotalAge) ?? -100
        talentUses = try c.decodeIfPresent(Int.self, forKey: .talentUses) ?? 0
        assetReciprocityUsed = try c.decodeIfPresent(Int.self, forKey: .assetReciprocityUsed) ?? 0
        if let totals = try? c.decode([IncomeSourceTotal].self, forKey: .lifetimeIncomeBySource) {
            lifetimeIncomeBySource = Dictionary(uniqueKeysWithValues: totals.map { ($0.source, $0.amount) })
        } else {
            lifetimeIncomeBySource = try c.decodeIfPresent([IncomeSource: Int].self, forKey: .lifetimeIncomeBySource) ?? [:]
        }
        ageAtFirstMillionNetWorth = try c.decodeIfPresent(Int.self, forKey: .ageAtFirstMillionNetWorth)
        ageAtFirstTenMillionNetWorth = try c.decodeIfPresent(Int.self, forKey: .ageAtFirstTenMillionNetWorth)
        prisonYearsServed = try c.decodeIfPresent(Int.self, forKey: .prisonYearsServed) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(annualNet, forKey: .annualNet)
        try c.encode(lifetimeIncome, forKey: .lifetimeIncome)
        try c.encode(lifetimeNet, forKey: .lifetimeNet)
        try c.encode(peakCash, forKey: .peakCash)
        try c.encode(yearsWorked, forKey: .yearsWorked)
        try c.encode(soloCrimeAttempts, forKey: .soloCrimeAttempts)
        try c.encode(soloCrimeSuccesses, forKey: .soloCrimeSuccesses)
        try c.encode(personalityPivotalEvents, forKey: .personalityPivotalEvents)
        try c.encode(lastPersonalityPivotalAge, forKey: .lastPersonalityPivotalAge)
        try c.encode(talentUses, forKey: .talentUses)
        try c.encode(assetReciprocityUsed, forKey: .assetReciprocityUsed)
        let totals = lifetimeIncomeBySource
            .map { IncomeSourceTotal(source: $0.key, amount: $0.value) }
            .sorted { $0.source.rawValue < $1.source.rawValue }
        try c.encode(totals, forKey: .lifetimeIncomeBySource)
        try c.encodeIfPresent(ageAtFirstMillionNetWorth, forKey: .ageAtFirstMillionNetWorth)
        try c.encodeIfPresent(ageAtFirstTenMillionNetWorth, forKey: .ageAtFirstTenMillionNetWorth)
        try c.encode(prisonYearsServed, forKey: .prisonYearsServed)
    }

    mutating func recordIncome(_ amount: Int, source: IncomeSource) {
        guard amount > 0 else { return }
        lifetimeIncomeBySource[source, default: 0] = EconomyPolicy.checkedAdd(lifetimeIncomeBySource[source, default: 0], amount)
    }

    mutating func observe(netWorth: Int, age: Int) {
        if netWorth >= 1_000_000, ageAtFirstMillionNetWorth == nil { ageAtFirstMillionNetWorth = age }
        if netWorth >= 10_000_000, ageAtFirstTenMillionNetWorth == nil { ageAtFirstTenMillionNetWorth = age }
    }
}

struct LifeState: Equatable {
    static let currentSaveVersion = 52

    var saveVersion = currentSaveVersion
    var character: Character
    var stats = LifeStats()
    var cash = 250
    var flags = LifeFlags()
    var education = EducationState()
    var career = CareerState()
    var finance = FinanceState()
    var assets = AssetState()
    var legal = LegalSystem.initialize(runSeed: 1)
    var prison = PrisonState()
    var world = WorldSystem.neutral(runSeed: 1, age: 14)
    var family = FamilyState()
    var health = HealthState()
    var startingContext: StartingContext = .ordinary
    var coreTrait: CoreTrait = .adaptable
    var personality: PersonalityProfile = .neutral
    var lifeThreads: [LifeThread] = []
    var partner: PartnerState?
    var formerRelationships: [FormerRelationship] = []
    var resolvedRelationshipSituations: [ResolvedSituation] = []
    var npcs = NPCDirectory()
    var influenceLedger = PlayerInfluenceLedger()
    var momentum = MomentumState()
    var recovery: RecoveryWindow?
    var isGameOver = false
    var lifeStage: LifeStage = .adolescence
    var mortalityPressure: MortalityPressure = .stable
    var endReason: EndReason?
    var actionUsage: [String: Int] = [:]
    var actionUseRecords: [String: ActionUseRecord] = [:]
    var recentFlavorIDs: [String] = []
    var reactions = ReactionState()
    var aggregates = LifeAggregateState()
    var history: [HistoryEntry] = []
    /// Biography-grade moments are stored independently from the bounded
    /// journal so a long life does not forget its beginning.
    var timeline: [LifeTimelineEntry] = []
    var historySequence: UInt64 = 0
    var recentEventIDs: [String] = []
    /// Recent player-created signals give the world causal memory without
    /// turning every action into a permanent scripted event.
    var recentDecisionSignals: [LifeSignal] = []
    var pendingEvent: PresentedEvent?
    var queuedYearEvents: [PresentedEvent] = []
    var yearChoicesResolved = 0
    var lastYearSummary: YearSummary?
    /// Immutable run identity; the mutable RNG state advances independently.
    var runSeed: UInt64 = 1
    var random = SeededRandom(seed: 1)
    var randomStreams = SimulationRandomStreams(runSeed: 1)

    /// Transitional source compatibility for compact-core callers and v3–v6
    /// fixtures. The stored source of truth is `career`.
    var job: JobState {
        get { career.legacyJob }
        set { career = CareerState(legacy: newValue) }
    }

    init(
        name: String,
        seed: UInt64 = UInt64.random(in: 1...UInt64.max),
        origin: OriginPreset = .balanced,
        context: StartingContext = .ordinary,
        trait: CoreTrait = .adaptable,
        startingAge: Int = 18
    ) {
        character = Character(name: name, age: startingAge)
        runSeed = seed
        random = SeededRandom(seed: seed)
        randomStreams = SimulationRandomStreams(runSeed: seed)
        assets = AssetSystem.initialize(runSeed: seed)
        legal = LegalSystem.initialize(runSeed: seed)
        prison = PrisonState(prisonRandom: SeededRandom(seed: seed ^ 0x505249534F4E))
        world = WorldSystem.initialize(runSeed: seed)
        education.schoolEnvironment = EducationSystem.schoolEnvironment(for: seed)
        if startingAge < 18 {
            career.level = .unemployed
            career.lastTransition = .started
            education.phase = .highSchool
        } else {
            education.phase = .postsecondary
        }
        startingContext = context
        coreTrait = trait
        personality = PersonalitySystem.legacyPlayer(trait: trait)
        origin.apply(to: &self)
        applyIdentityTradeoffs()
        cash = context == .supported ? 1_500 : (context == .precarious ? 100 : 500)
        aggregates.peakCash = cash
        lifeStage = .stage(for: character.age)
    }

    mutating func applyIdentityTradeoffs() {
        switch startingContext {
        case .supported: stats.rep -= 4; finance.financialStress -= 8
        case .ordinary: break
        case .precarious: stats.school += 5; finance.financialStress += 18
        }
        switch coreTrait {
        case .driven: career.performance += 10; stats.play -= 8; career.burnout += 7
        case .empathetic: stats.love += 9; stats.rep += 4
        case .adaptable: career.security += 5; stats.school += 4; stats.rep -= 2
        }
        health = HealthState(physicalWellbeing: stats.health, mentalWellbeing: stats.health)
        clamp()
    }

    mutating func syncHealthCompatibility() { stats.health = health.overall }
    mutating func adoptHealthCompatibility() {
        guard stats.health != health.overall else { return }
        health.physicalWellbeing = stats.health
        health.mentalWellbeing = stats.health
        health.bodyLoad = 0
        health.clamp()
        personality.clamp()
        if var currentPartner = partner {
            currentPartner.personality.clamp()
            partner = currentPartner
        }
    }

    mutating func clamp() {
        stats.clamp()
        personality.clamp()
        career.clamp()
        finance.clamp()
        assets.normalize()
        legal.clamp()
        prison.clamp()
        world.clamp()
        family.clamp()
        reactions.clamp()
        health.clamp()
        syncHealthCompatibility()
        partner?.clamp()
        formerRelationships = Array(formerRelationships.prefix(4))
        resolvedRelationshipSituations = Array(resolvedRelationshipSituations.prefix(6))
        flags.hasPartner = partner != nil
        flags.hasJob = career.level.isEmployed
        if saveVersion >= 33 && cash < 0 { finance.consumerDebt = EconomyPolicy.checkedAdd(finance.consumerDebt, -cash); cash = 0 }
        education.clamp()
        character.age = max(14, character.age)
        history = Array(history.prefix(40))
        timeline = Array(timeline.suffix(32))
        lifeThreads = Array(lifeThreads
            .filter { $0.resolution == .permanent || ($0.resolution != .resolved && $0.yearsRemaining > 0 && $0.intensity > 0) }
            .sorted {
                if $0.intensity == $1.intensity { return $0.openedAge > $1.openedAge }
                return $0.intensity > $1.intensity
            }
            .prefix(3))
        recentFlavorIDs = Array(recentFlavorIDs.prefix(8))
        queuedYearEvents = Array(queuedYearEvents.prefix(1))
        yearChoicesResolved = min(2, max(0, yearChoicesResolved))
        actionUseRecords = actionUseRecords.filter { $0.value.age >= character.age - 1 }
    }

    var isValidSave: Bool {
        character.age >= 14 && (saveVersion < 33 || cash >= 0)
            && [stats.school, stats.love, stats.play, stats.health, stats.looks, stats.rep].allSatisfy { (0...100).contains($0) }
            && history.count <= 40
            && timeline.count <= 32
    }

    var lifetimeNet: Int { aggregates.lifetimeNet }
    var lifetimeIncome: Int { aggregates.lifetimeIncome }
    var totalDebt: Int { finance.totalDebt + assets.totalMortgageDebt + assets.properties.reduce(0) { $0 + $1.operatingArrears } }
    var netWorth: Int { cash + finance.netWorthExcludingCash + assets.totalValue }
    var housingKind: HousingKind {
        if assets.primaryProperty == nil { return .renting }
        return assets.hasDelinquentProperty ? .delinquent : .owning
    }

    var lifeSummary: String {
        LifeReviewModel.build(from: self).legacySummary
    }

    func usedActionThisAge(_ id: ActionID) -> Bool {
        actionUseCount(for: id.rawValue) > 0
    }

    mutating func markActionUsed(_ id: ActionID) {
        markActionUsed(key: id.rawValue)
    }

    func actionUseCount(for key: String) -> Int {
        if let record = actionUseRecords[key], record.age == character.age { return record.count }
        return actionUsage[key] == character.age ? 1 : 0
    }

    mutating func markActionUsed(key: String) {
        let count = actionUseCount(for: key) + 1
        actionUseRecords[key] = ActionUseRecord(age: character.age, count: count)
        actionUsage[key] = character.age
    }

    mutating func rememberFlavor(_ id: String) {
        recentFlavorIDs.removeAll { $0 == id }
        recentFlavorIDs.insert(id, at: 0)
        recentFlavorIDs = Array(recentFlavorIDs.prefix(8))
    }

    mutating func rememberEvent(_ id: String) {
        recentEventIDs.removeAll { $0 == id }
        recentEventIDs.insert(id, at: 0)
        recentEventIDs = Array(recentEventIDs.prefix(6))
    }

    mutating func rememberDecisionSignal(_ signal: LifeSignal) {
        recentDecisionSignals.removeAll {
            $0.age == signal.age && $0.sourceHeadline == signal.sourceHeadline
        }
        recentDecisionSignals.insert(signal, at: 0)
        recentDecisionSignals = Array(recentDecisionSignals.prefix(6))
    }
}

/// Terminal payoff model for the life-review sheet.
struct LifeReviewModel: Equatable {
    let age: Int
    let endReason: EndReason
    let lifeShape: LifeShape
    let dominantStance: LifeStance
    let educationLine: String
    let workLine: String
    let financialLine: String
    let relationshipLine: String
    let healthLine: String
    let housingLine: String
    let assetLine: String
    let legalLine: String
    let continuityLine: String
    let personalityLine: String
    let talentLine: String
    let worldLine: String
    let pivotal: [HistoryEntry]
    let personalityPivotal: [HistoryEntry]
    let legacyHeadline: String
    let legacySummary: String

    static func build(from state: LifeState) -> LifeReviewModel {
        let reason = state.endReason ?? .naturalCauses
        let adultEducation: String
        if state.education.credential {
            let field = state.education.credentialField.map { " in \($0.title.lowercased())" } ?? ""
            adultEducation = "Earned a \(state.education.credentialKind.title.lowercased())\(field)."
        } else if state.education.college.credits > 0 {
            adultEducation = "Left college with \(state.education.college.credits) credits and no invented degree."
        } else if state.education.progress > 0 {
            adultEducation = "Studied without finishing a credential (progress \(state.education.progress))."
        } else {
            adultEducation = "Left further education largely behind."
        }
        let diploma = state.education.highSchoolDiploma ? "diploma earned" : "no standard diploma"
        let commitment = state.education.dominantCommitment.map { ", centered on \($0.title.lowercased())" } ?? ""
        let memory = state.education.definingHighSchoolMemory.map { " \($0)" } ?? ""
        let edu = "High school: \(diploma), \(state.education.postSchoolPath.title.lowercased()) path\(commitment). \(adultEducation)\(memory)"

        let work: String
        switch state.job.tier {
        case .retired: work = "Retired after years of \(state.aggregates.yearsWorked > 20 ? "long" : "steady") work."
        case .skilled: work = "Reached skilled work and held it."
        case .entry: work = "Stayed in entry-level work."
        case .unemployed: work = "Ended without steady work."
        }
        let workSituation = state.career.resolvedSituations.first.map { " \($0.title): \($0.outcome)" } ?? ""

        let net = state.lifetimeNet
        let cash = state.cash
        let financial: String
        if cash >= 80_000 && net >= 0 && state.finance.economy.shortfallYears == 0 {
            financial = "Finished with a positive financial run ($\(cash); lifetime net $\(net))."
        } else if state.finance.economy.shortfallYears == 0 && state.netWorth >= 0 {
            financial = "Finished solvent after a workable financial run ($\(cash); lifetime net $\(net))."
        } else {
            financial = "Finished under pressure after a difficult financial run ($\(cash); lifetime net $\(net))."
        }

        let relationship: String
        if let p = state.partner {
            let years = max(0, state.character.age - p.startedAge)
            let secure = p.flags.contains(.secure) ? " with hard-won security" : ""
            let commit = p.committed ? "committed" : "uncommitted"
            let earlier = state.formerRelationships.first.map { " Earlier, a \($0.yearsTogether)-year relationship with \($0.name) ended." } ?? ""
            let situation = state.resolvedRelationshipSituations.first.map { " \($0.title): \($0.outcome)" } ?? ""
            relationship = "A relationship with \(p.name): \(commit), bond \(p.bond), resentment \(p.resentment), \(years) years\(secure).\(earlier)\(situation)"
        } else if let former = state.formerRelationships.first {
            let situation = state.resolvedRelationshipSituations.first.map { " \($0.title): \($0.outcome)" } ?? ""
            relationship = "A \(former.yearsTogether)-year relationship with \(former.name) ended when \(former.reason.reviewText); final bond \(former.finalBond), resentment \(former.finalResentment).\(situation)"
        } else {
            relationship = "A life without a lasting relationship."
        }

        let activeConditions = state.health.conditions.filter { $0.status == .active }
        let stableConditions = state.health.conditions.filter { $0.status == .stable }
        let health: String
        if state.health.conditions.isEmpty {
            health = "Ended at health \(state.health.overall) without a diagnosed chronic condition."
        } else if activeConditions.isEmpty {
            health = "Ended at health \(state.health.overall) with \(stableConditions.count) chronic condition\(stableConditions.count == 1 ? "" : "s") stable through ongoing care."
        } else {
            health = "Ended at health \(state.health.overall) with \(activeConditions.count) active and \(stableConditions.count) stable chronic condition\(state.health.conditions.count == 1 ? "" : "s")."
        }

        let currentHomes = state.assets.properties.count
        let housing: String
        if currentHomes > 0 {
            let earlierLosses = state.assets.propertyHistory.filter { $0.reason == .foreclosed }.count
            let history = earlierLosses > 0 ? " Earlier foreclosure losses: \(earlierLosses)." : ""
            let rentals = state.assets.occupiedRentalCount + state.assets.vacantRentalCount
            let rentalLine = rentals > 0 ? " \(rentals) ended as rental propert\(rentals == 1 ? "y" : "ies"), with $\(state.assets.lastRentalIncome) collected in the final year." : ""
            let upkeep = state.assets.properties.reduce(0) { $0 + $1.totalAnnualCost }
            housing = "Ended owning \(currentHomes) propert\(currentHomes == 1 ? "y" : "ies") with $\(state.assets.propertyEquity) in equity and $\(state.assets.totalMortgageDebt) in mortgage debt. Housing upkeep was about $\(upkeep)/year.\(rentalLine)\(history)"
        } else if let latest = state.assets.propertyHistory.first {
            housing = "No property remained; \(latest.name) was \(latest.reason.reviewText) at age \(latest.exitAge), returning $\(latest.cashRecovered)."
        } else {
            housing = "Rented throughout the recorded life without taking on a mortgage."
        }

        let legal: String
        if !state.legal.isFelon {
            legal = "Ended without a felony record."
        } else if state.legal.isUnderSupervision {
            legal = "A felony record remained, with \(state.legal.supervisionYearsRemaining) year\(state.legal.supervisionYearsRemaining == 1 ? "" : "s") of active supervision left."
        } else {
            legal = "A felony record remained after active supervision was completed."
        }

        let assetLine: String
        let assetParts = [
            state.assets.giftHistory.contains(where: { $0.major }) ? "Gave away significant assets to people close to them." : nil,
            state.assets.movableAssetsLost >= 2 ? "Lost multiple movable assets during pressure or bad luck." : nil,
            state.assets.movableAssetsAcquired > 0 && state.assets.movableAssets.count == 1 && state.assets.movableAssets.first?.vehicle != nil ? "Held one practical vehicle for most of adulthood." : nil,
            state.assets.reciprocity.usedEventKeys.isEmpty == false ? "Used support created by an earlier gift when pressure arrived." : nil,
            state.assets.movableAssetsSold > 0 ? "Used emergency sales to create cash when the ledger tightened." : nil
        ].compactMap { $0 }
        if assetParts.isEmpty {
            assetLine = "Kept a compact movable-asset portfolio with \(state.assets.movableAssets.count) asset\(state.assets.movableAssets.count == 1 ? "" : "s") remaining."
        } else {
            assetLine = assetParts.joined(separator: " ")
        }

        let continuity: String
        if state.lifeThreads.isEmpty {
            continuity = "No cross-domain pressure remained unresolved."
        } else {
            let burdens = state.lifeThreads.prefix(3).map { thread in
                let destination = thread.target?.rawValue.capitalized ?? "Life"
                return "\(thread.headline) (\(destination), \(thread.yearsRemaining)y)"
            }
            continuity = "\(burdens.count) unresolved burden\(burdens.count == 1 ? "" : "s") remained: \(burdens.joined(separator: "; "))."
        }

        let familyLine: String
        if state.family.children.isEmpty {
            familyLine = state.family.intention == .childfree ? " Chose a childfree life." : ""
        } else {
            let adults = state.family.children.filter { !$0.dependent }
            let dependents = state.family.dependentLoad
            let outcomes = Dictionary(grouping: adults.compactMap(\.adultOutcome), by: { $0 })
            let adultSummary = outcomes.isEmpty ? "" : " Adult outcomes: \(outcomes.map { "\($0.key.rawValue) \($0.value.count)" }.sorted().joined(separator: ", "))."
            familyLine = " Raised \(state.family.children.count) child\(state.family.children.count == 1 ? "" : "ren"); \(dependents) still dependent.\(adultSummary)"
        }

        var startingProfile = PersonalityProfile(
            baseline: state.personality.baseline,
            current: state.personality.baseline,
            definingTrait: state.personality.definingTrait,
            talent: state.personality.talent
        )
        startingProfile.refreshEstablishedFlags()
        let startingFlags = startingProfile.salientFlags
        let endingFlags = state.personality.salientFlags
        let startLabel = startingFlags.isEmpty ? "without a strong tendency" : startingFlags.map(\.title).joined(separator: " + ")
        let endLabel = endingFlags.isEmpty ? "without a strong tendency" : endingFlags.map(\.title).joined(separator: " + ")
        let personality = "Started as \(startingProfile.identitySignature.title) (\(startLabel)); ended as \(state.personality.identitySignature.title) (\(endLabel))."
        let talent = state.personality.talent.map {
            let realized = talentWasRealized($0, state: state) ? "shaped the life" : "remained mostly unrealized"
            return "\($0.title) talent \(realized)."
        } ?? "No special talent defined this life."
        let recordedWorldShifts = state.world.recentEventIDs.count + state.world.publicHealth.recentEventIDs.count
        let price = state.world.conditions.price.map { ", with \($0.rawValue) still active" } ?? ""
        let world = "Lived through a \(state.world.profile.costEnvironment.rawValue) cost environment, \(state.world.profile.laborStructure.rawValue) labor, and a \(state.world.profile.safetyNet.rawValue) safety net. Recorded \(recordedWorldShifts) major world shift\(recordedWorldShifts == 1 ? "" : "s"); ended during \(state.world.conditions.macro.rawValue) conditions and \(state.world.publicHealth.condition.rawValue) public health\(price)."

        let pivotal = Array(state.history.filter { entry in
            entry.yearSummary?.stageTransition != nil
                || entry.yearSummary?.mortalityWarning != nil
                || entry.headline.contains("Life Ended")
                || entry.headline.contains("Recovery")
                || entry.headline.contains("Partner")
                || entry.headline.contains("Work")
                || entry.headline.contains("Graduate")
                || entry.headline.contains("Retire")
                || entry.headline.contains("Building")
                || entry.headline.contains("Pressure")
                || entry.headline.contains("Legacy")
                || entry.headline.contains("Commit")
                || !entry.deltas.isEmpty && abs(entry.deltas.cash) >= 8_000
        }.prefix(5))
        let picks = pivotal.isEmpty ? Array(state.history.prefix(5)) : pivotal
        let personalityPivotal = Array(state.history.filter {
            $0.detail.contains("Identity:") || $0.detail.contains("Relationship:")
                || BundledLifeContentRegistry.headlines.contains($0.headline)
        }.prefix(3))

        let headline: String
        switch (state.momentum.shape, reason) {
        case (.driven, _): headline = "A driven life that kept pushing"
        case (.connected, _): headline = "A connected life built around people"
        case (.careful, _): headline = "A careful life that protected its edges"
        case (.loose, _): headline = "A loose life that left room for chance"
        case (.pragmatic, _): headline = "A pragmatic life of workable trades"
        case (.balanced, .unresolvedHealthCrisis): headline = "A life cut short by the body"
        case (.balanced, .unresolvedFinancialCrisis): headline = "A life undone by the ledger"
        case (.balanced, _): headline = "An ordinary life, fully lived"
        }

        let schoolLegacy = state.education.definingHighSchoolMemory.map { " High school: \($0)" } ?? ""
        let workout = state.finance.economy.workoutStartedAge.map { " Debt workout began at age \($0); forgiven debt $\(state.finance.economy.forgivenDebt)." } ?? ""
        let summary = workout + "Ended at \(state.character.age) — \(reason.title). Relationship: \(relationship)\(familyLine) \(work) Financial run: \(financial) Housing: \(housing) Assets: \(assetLine) Health: \(health) Legal: \(legal) Continuity: \(continuity) Shape: \(state.momentum.shape.title.lowercased()).\(schoolLegacy)"

        return LifeReviewModel(
            age: state.character.age,
            endReason: reason,
            lifeShape: state.momentum.shape,
            dominantStance: state.momentum.stance,
            educationLine: edu,
            workLine: work + workSituation,
            financialLine: financial,
            relationshipLine: relationship,
            healthLine: health,
            housingLine: housing,
            assetLine: assetLine,
            legalLine: legal,
            continuityLine: continuity,
            personalityLine: personality,
            talentLine: talent,
            worldLine: world,
            pivotal: picks,
            personalityPivotal: personalityPivotal,
            legacyHeadline: headline,
            legacySummary: summary
        )
    }

    private static func talentWasRealized(_ talent: SpecialTalent, state: LifeState) -> Bool {
        if state.aggregates.talentUses >= 3 { return true }
        return switch talent {
        case .athletic: state.stats.health >= 70
        case .entrepreneurial: state.career.track == .freelance || state.aggregates.lifetimeIncome >= 400_000
        case .publicLeadership: state.stats.rep >= 70 || state.stats.love >= 75
        case .survivalInstinct: state.character.age >= 65 || state.recovery == nil && state.health.conditions.count > 0
        }
    }
}

extension LifeState: Codable {
    enum CodingKeys: String, CodingKey {
        case saveVersion, character, stats, cash, flags, education, career, finance, assets, legal, prison, world, family, health, partner, formerRelationships, resolvedRelationshipSituations
        case startingContext, coreTrait, personality, lifeThreads
        case npcs, influenceLedger, momentum, recovery, isGameOver, aggregates
        case history, timeline, historySequence, recentEventIDs, recentDecisionSignals, pendingEvent, lastYearSummary, runSeed, random, randomStreams
        case lifeStage, mortalityPressure, endReason, actionUsage, actionUseRecords, recentFlavorIDs, reactions, queuedYearEvents, yearChoicesResolved
    }

    private enum LegacyCodingKeys: String, CodingKey { case job }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        saveVersion = try c.decodeIfPresent(Int.self, forKey: .saveVersion) ?? 1
        character = try c.decode(Character.self, forKey: .character)
        stats = try c.decodeIfPresent(LifeStats.self, forKey: .stats) ?? LifeStats()
        cash = try c.decodeIfPresent(Int.self, forKey: .cash) ?? 250
        flags = try c.decodeIfPresent(LifeFlags.self, forKey: .flags) ?? LifeFlags()
        education = try c.decodeIfPresent(EducationState.self, forKey: .education) ?? EducationState()
        if let decodedCareer = try c.decodeIfPresent(CareerState.self, forKey: .career) {
            career = decodedCareer
        } else {
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            career = CareerState(legacy: try legacy.decodeIfPresent(JobState.self, forKey: .job) ?? JobState())
        }
        finance = try c.decodeIfPresent(FinanceState.self, forKey: .finance) ?? FinanceState()
        assets = try c.decodeIfPresent(AssetState.self, forKey: .assets) ?? AssetState()
        family = try c.decodeIfPresent(FamilyState.self, forKey: .family) ?? FamilyState()
        let legacyHealth = stats.health
        health = try c.decodeIfPresent(HealthState.self, forKey: .health)
            ?? HealthState(physicalWellbeing: legacyHealth, mentalWellbeing: legacyHealth)
        startingContext = try c.decodeIfPresent(StartingContext.self, forKey: .startingContext) ?? .ordinary
        coreTrait = try c.decodeIfPresent(CoreTrait.self, forKey: .coreTrait) ?? .adaptable
        personality = try c.decodeIfPresent(PersonalityProfile.self, forKey: .personality)
            ?? PersonalitySystem.legacyPlayer(trait: coreTrait)
        lifeThreads = Array((try c.decodeIfPresent([LifeThread].self, forKey: .lifeThreads) ?? []).prefix(3))
        partner = try c.decodeIfPresent(PartnerState.self, forKey: .partner)
        formerRelationships = try c.decodeIfPresent([FormerRelationship].self, forKey: .formerRelationships) ?? []
        resolvedRelationshipSituations = try c.decodeIfPresent([ResolvedSituation].self, forKey: .resolvedRelationshipSituations) ?? []
        npcs = try c.decodeIfPresent(NPCDirectory.self, forKey: .npcs) ?? NPCDirectory()
        influenceLedger = try c.decodeIfPresent(PlayerInfluenceLedger.self, forKey: .influenceLedger) ?? PlayerInfluenceLedger()
        momentum = try c.decodeIfPresent(MomentumState.self, forKey: .momentum) ?? MomentumState()
        recovery = try c.decodeIfPresent(RecoveryWindow.self, forKey: .recovery)
        isGameOver = try c.decodeIfPresent(Bool.self, forKey: .isGameOver) ?? false
        lifeStage = try c.decodeIfPresent(LifeStage.self, forKey: .lifeStage) ?? .stage(for: character.age)
        mortalityPressure = try c.decodeIfPresent(MortalityPressure.self, forKey: .mortalityPressure) ?? .stable
        endReason = try c.decodeIfPresent(EndReason.self, forKey: .endReason)
        actionUsage = try c.decodeIfPresent([String: Int].self, forKey: .actionUsage) ?? [:]
        actionUseRecords = try c.decodeIfPresent([String: ActionUseRecord].self, forKey: .actionUseRecords) ?? [:]
        recentFlavorIDs = try c.decodeIfPresent([String].self, forKey: .recentFlavorIDs) ?? []
        reactions = try c.decodeIfPresent(ReactionState.self, forKey: .reactions) ?? ReactionState()
        aggregates = try c.decodeIfPresent(LifeAggregateState.self, forKey: .aggregates) ?? LifeAggregateState()
        history = try c.decodeIfPresent([HistoryEntry].self, forKey: .history) ?? []
        timeline = try c.decodeIfPresent([LifeTimelineEntry].self, forKey: .timeline)
            ?? history.reversed().filter(LifeTimelineResolver.isMilestone).map {
                LifeTimelineEntry(id: $0.id, age: $0.age, headline: $0.headline, detail: $0.detail)
            }
        historySequence = try c.decodeIfPresent(UInt64.self, forKey: .historySequence) ?? 0
        recentEventIDs = try c.decodeIfPresent([String].self, forKey: .recentEventIDs) ?? []
        recentDecisionSignals = Array((try c.decodeIfPresent([LifeSignal].self, forKey: .recentDecisionSignals) ?? []).prefix(6))
        pendingEvent = try c.decodeIfPresent(PresentedEvent.self, forKey: .pendingEvent)
        queuedYearEvents = try c.decodeIfPresent([PresentedEvent].self, forKey: .queuedYearEvents) ?? []
        yearChoicesResolved = try c.decodeIfPresent(Int.self, forKey: .yearChoicesResolved) ?? 0
        lastYearSummary = try c.decodeIfPresent(YearSummary.self, forKey: .lastYearSummary)
        random = try c.decodeIfPresent(SeededRandom.self, forKey: .random) ?? SeededRandom(seed: 1)
        runSeed = try c.decodeIfPresent(UInt64.self, forKey: .runSeed) ?? random.seed
        randomStreams = try c.decodeIfPresent(SimulationRandomStreams.self, forKey: .randomStreams)
            ?? SimulationRandomStreams(runSeed: runSeed)
        legal = try c.decodeIfPresent(LegalState.self, forKey: .legal)
            ?? LegalSystem.initialize(runSeed: runSeed)
        prison = try c.decodeIfPresent(PrisonState.self, forKey: .prison)
            ?? PrisonState(prisonRandom: SeededRandom(seed: runSeed ^ 0x505249534F4E))
        world = try c.decodeIfPresent(WorldState.self, forKey: .world)
            ?? WorldSystem.neutral(runSeed: runSeed, age: character.age)
        // Canonical domain state owns these compatibility flags.
        flags.hasPartner = partner != nil
        flags.hasJob = career.level.isEmployed
        syncHealthCompatibility()
    }
}

enum OriginPreset: String, CaseIterable, Identifiable {
    case balanced, academic, social

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var detail: String {
        switch self {
        case .balanced: "No changes — a middling start."
        case .academic: "Smart +15 · Fun −12 · Cash −100"
        case .social: "Happy +15 · Looks +12 · Smart −10 · Cash −100"
        }
    }

    func apply(to state: inout LifeState) {
        switch self {
        case .balanced: break
        case .academic:
            state.stats.school += 15; state.stats.play -= 12
        case .social:
            state.stats.love += 15; state.stats.looks += 12; state.stats.school -= 10
        }
        state.clamp()
    }
}

// MARK: - Silence (quiet years)

enum SilentYearEngine {
    static func note(state: LifeState, snapshot: YearInfluenceSnapshot, partnerNote: String?) -> String {
        if let partnerNote { return partnerNote }
        let shape = state.momentum.shape
        let scores = snapshot.scores
        if state.cash < 4_000 {
            return "Another month of watching the balance. You count what is left before you count what is possible."
        }
        if state.stats.health < 40 {
            return "Your body keeps the score even when the calendar does not. Quiet does not mean recovered."
        }
        if scores.work >= 3 {
            return silenceForShape(shape, driven: "The work filled the year. Nobody called it a crisis, and still you felt thinner at the edges.")
        }
        if scores.family >= 2 {
            return silenceForShape(shape, driven: "The year was ordinary on purpose — texts answered, dinners kept, nothing dramatic enough to name.")
        }
        if scores.stability >= 2 {
            return "You protected the quiet. No fireworks. Just enough structure to keep the floor under you."
        }
        if state.stats.play < 35 {
            return "The weeks stacked without a night that felt like yours. You noticed only after it was already a pattern."
        }
        return silenceForShape(shape, driven: "The year passed without a major turn. Still, the shape of how you spent it stayed with you.")
    }

    private static func silenceForShape(_ shape: LifeShape, driven: String) -> String {
        switch shape {
        case .driven:
            return "The looseness you refused is still gone. \(driven)"
        case .connected:
            return "The people you kept showing up for became the shape of the year."
        case .loose:
            return "The looseness you allowed is still coloring what the world brings to your door."
        case .careful:
            return "You kept the edges neat. \(driven)"
        case .pragmatic:
            return "You traded drama for workable days. \(driven)"
        case .balanced:
            return driven
        }
    }
}

private extension Int {
    var clamped: Int { Swift.min(100, Swift.max(0, self)) }
}
