import Foundation

enum EducationPathway: String, Codable, CaseIterable {
    case student
    case dropout
    case training
    case graduate
    case rotc
}

enum EducationStage: String, Codable, CaseIterable {
    case secondary
    case university
    case tradeTraining
    case adultEd
    case inactive
}

enum AcademicTrack: String, Codable, CaseIterable {
    case general
    case honors
    case struggling
    case vocational
}

enum StudyFocus: String, Codable, CaseIterable {
    case generalStudies
    case business
    case technology
    case medicine
    case law
    case computerScience
    case arts
    case health
    case trades
}

enum HighSchoolAcademicShape: String, Codable, CaseIterable {
    case honors
    case steady
    case struggling
    case vocational
    case dropoutRisk

    var displayLabel: String {
        switch self {
        case .honors: return "Honors"
        case .steady: return "Steady"
        case .struggling: return "Struggling"
        case .vocational: return "Vocational"
        case .dropoutRisk: return "Dropout risk"
        }
    }
}

enum HighSchoolSocialShape: String, Codable, CaseIterable {
    case connected
    case invisible
    case volatile
    case respected
    case isolated

    var displayLabel: String {
        switch self {
        case .connected: return "Connected"
        case .invisible: return "Invisible"
        case .volatile: return "Volatile"
        case .respected: return "Respected"
        case .isolated: return "Isolated"
        }
    }
}

enum HighSchoolAdultSupportShape: String, Codable, CaseIterable {
    case mentored
    case overlooked
    case protected
    case adversarial

    var displayLabel: String {
        switch self {
        case .mentored: return "Mentored"
        case .overlooked: return "Overlooked"
        case .protected: return "Protected"
        case .adversarial: return "Adversarial"
        }
    }
}

enum HighSchoolPressureShape: String, Codable, CaseIterable {
    case balanced
    case burnedOut
    case survivalMode
    case reckless

    var displayLabel: String {
        switch self {
        case .balanced: return "Balanced"
        case .burnedOut: return "Burned-out"
        case .survivalMode: return "Survival mode"
        case .reckless: return "Reckless"
        }
    }
}

enum HighSchoolFutureSeed: String, Codable, CaseIterable {
    case academic
    case trade
    case creator
    case athlete
    case founder
    case politics
    case riskLane
    case undecided

    var displayLabel: String {
        switch self {
        case .academic: return "Academic"
        case .trade: return "Trade"
        case .creator: return "Creator"
        case .athlete: return "Athlete"
        case .founder: return "Founder"
        case .politics: return "Leadership"
        case .riskLane: return "Risk lane"
        case .undecided: return "Undecided"
        }
    }
}

enum SeniorYearOutcome: String, Codable, CaseIterable {
    case unresolved
    case scholarshipRoute
    case commuterCollege
    case universityTrack
    case tradeTrack
    case adultEdRebuild
    case dropoutDrift
    case earlyWorkRoute
    case specialCareerSeed

    var displayLabel: String {
        switch self {
        case .unresolved: return "Still forming"
        case .scholarshipRoute: return "Scholarship route"
        case .commuterCollege: return "Commuter college"
        case .universityTrack: return "University track"
        case .tradeTrack: return "Trade track"
        case .adultEdRebuild: return "Adult-ed rebuild"
        case .dropoutDrift: return "Dropout drift"
        case .earlyWorkRoute: return "Early work route"
        case .specialCareerSeed: return "Special seed"
        }
    }
}

struct HighSchoolProfile: Codable, Equatable {
    var academicShape: HighSchoolAcademicShape = .steady
    var socialShape: HighSchoolSocialShape = .connected
    var adultSupportShape: HighSchoolAdultSupportShape = .overlooked
    var pressureShape: HighSchoolPressureShape = .balanced
    var futureSeed: HighSchoolFutureSeed = .undecided

    static let empty = HighSchoolProfile()
}

enum HighSchoolIdentityForceRole: String, Codable, CaseIterable {
    case mentorAdult
    case peerAlly
    case rivalHeatSource
    case activityCoachForce
    case homePressure

    var displayLabel: String {
        switch self {
        case .mentorAdult: return "Mentor"
        case .peerAlly: return "Ally"
        case .rivalHeatSource: return "Heat"
        case .activityCoachForce: return "Activity"
        case .homePressure: return "Home"
        }
    }
}

enum HighSchoolIdentityForceTone: String, Codable, CaseIterable {
    case supportive
    case tense
    case volatile
    case demanding
    case neutral

    var displayLabel: String {
        switch self {
        case .supportive: return "Support"
        case .tense: return "Tense"
        case .volatile: return "Volatile"
        case .demanding: return "Demanding"
        case .neutral: return "Neutral"
        }
    }
}

struct HighSchoolIdentityForce: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var role: HighSchoolIdentityForceRole
    var tone: HighSchoolIdentityForceTone
    var storyLine: String
    var strength: Int

    mutating func clamp() {
        if id.isEmpty { id = role.rawValue }
        if name.isEmpty { name = role.displayLabel }
        if storyLine.isEmpty { storyLine = "This part of school is shaping you." }
        strength = strength.clamped(to: 0...100)
    }
}

struct EducationState: Codable, Equatable {
    var pathway: EducationPathway = .student
    var stage: EducationStage = .secondary
    var academicTrack: AcademicTrack = .general
    var schoolStanding: Int = 56
    var engagement: Int = 55
    var attendancePressure: Int = 18
    var activityMomentum: Int = 20
    var schoolBelonging: Int = 48
    var reputationRisk: Int = 22
    var teacherSupport: Int = 44
    var applicationReadiness: Int = 24
    var campusFit: Int = 50
    var burnoutRisk: Int = 18
    var disciplineRecord: Int = 76
    var mentorSupport: Int = 32
    var peerPressure: Int = 26
    var yearsInStage: Int = 0
    var studyFocus: StudyFocus? = nil
    var credentials: [String] = []
    var hasScholarship: Bool = false
    /// D3: Education pathway differentiation support. credentialStrength starts higher for honors, decays over time unless refreshed (or trade track maintains via practice).
    /// Used for handoff income ramps, special entry bias, and long-term credential value in career.
    var credentialStrength: Int = 65
    var yearsSinceCredential: Int = 0
    var highSchoolProfile: HighSchoolProfile = .empty
    var formativeSchoolTags: [String: Int] = [:]
    var seniorYearOutcome: SeniorYearOutcome = .unresolved
    var highSchoolLegacyLine: String = "High school is still taking shape."
    var highSchoolIdentityForces: [HighSchoolIdentityForce] = []
    var lastHighSchoolIdentityBeatAge: Int? = nil
    var seniorLaunchPresentedAge: Int? = nil

    private enum CodingKeys: String, CodingKey {
        case pathway
        case stage
        case academicTrack
        case schoolStanding
        case engagement
        case attendancePressure
        case activityMomentum
        case schoolBelonging
        case reputationRisk
        case teacherSupport
        case applicationReadiness
        case campusFit
        case burnoutRisk
        case disciplineRecord
        case mentorSupport
        case peerPressure
        case yearsInStage
        case studyFocus
        case credentials
        case hasScholarship
        case credentialStrength  // D3
        case yearsSinceCredential
        case highSchoolProfile
        case formativeSchoolTags
        case seniorYearOutcome
        case highSchoolLegacyLine
        case highSchoolIdentityForces
        case lastHighSchoolIdentityBeatAge
        case seniorLaunchPresentedAge
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pathway = try container.decodeIfPresent(EducationPathway.self, forKey: .pathway) ?? .student
        stage = try container.decodeIfPresent(EducationStage.self, forKey: .stage) ?? .secondary
        academicTrack = try container.decodeIfPresent(AcademicTrack.self, forKey: .academicTrack) ?? .general
        schoolStanding = try container.decodeIfPresent(Int.self, forKey: .schoolStanding) ?? 56
        engagement = try container.decodeIfPresent(Int.self, forKey: .engagement) ?? 55
        attendancePressure = try container.decodeIfPresent(Int.self, forKey: .attendancePressure) ?? 18
        activityMomentum = try container.decodeIfPresent(Int.self, forKey: .activityMomentum) ?? 20
        schoolBelonging = try container.decodeIfPresent(Int.self, forKey: .schoolBelonging) ?? 48
        reputationRisk = try container.decodeIfPresent(Int.self, forKey: .reputationRisk) ?? 22
        teacherSupport = try container.decodeIfPresent(Int.self, forKey: .teacherSupport) ?? 44
        applicationReadiness = try container.decodeIfPresent(Int.self, forKey: .applicationReadiness) ?? 24
        campusFit = try container.decodeIfPresent(Int.self, forKey: .campusFit) ?? 50
        burnoutRisk = try container.decodeIfPresent(Int.self, forKey: .burnoutRisk) ?? 18
        disciplineRecord = try container.decodeIfPresent(Int.self, forKey: .disciplineRecord) ?? 76
        mentorSupport = try container.decodeIfPresent(Int.self, forKey: .mentorSupport) ?? 32
        peerPressure = try container.decodeIfPresent(Int.self, forKey: .peerPressure) ?? 26
        yearsInStage = try container.decodeIfPresent(Int.self, forKey: .yearsInStage) ?? 0
        studyFocus = try container.decodeIfPresent(StudyFocus.self, forKey: .studyFocus)
        credentials = try container.decodeIfPresent([String].self, forKey: .credentials) ?? []
        hasScholarship = try container.decodeIfPresent(Bool.self, forKey: .hasScholarship) ?? false
        credentialStrength = try container.decodeIfPresent(Int.self, forKey: .credentialStrength) ?? 65
        yearsSinceCredential = try container.decodeIfPresent(Int.self, forKey: .yearsSinceCredential) ?? 0
        highSchoolProfile = try container.decodeIfPresent(HighSchoolProfile.self, forKey: .highSchoolProfile) ?? .empty
        formativeSchoolTags = try container.decodeIfPresent([String: Int].self, forKey: .formativeSchoolTags) ?? [:]
        seniorYearOutcome = try container.decodeIfPresent(SeniorYearOutcome.self, forKey: .seniorYearOutcome) ?? .unresolved
        highSchoolLegacyLine = try container.decodeIfPresent(String.self, forKey: .highSchoolLegacyLine) ?? "High school is still taking shape."
        highSchoolIdentityForces = try container.decodeIfPresent([HighSchoolIdentityForce].self, forKey: .highSchoolIdentityForces) ?? []
        lastHighSchoolIdentityBeatAge = try container.decodeIfPresent(Int.self, forKey: .lastHighSchoolIdentityBeatAge)
        seniorLaunchPresentedAge = try container.decodeIfPresent(Int.self, forKey: .seniorLaunchPresentedAge)
        clamp()
    }

    mutating func clamp() {
        schoolStanding = schoolStanding.clamped(to: 0...100)
        engagement = engagement.clamped(to: 0...100)
        attendancePressure = attendancePressure.clamped(to: 0...100)
        activityMomentum = activityMomentum.clamped(to: 0...100)
        schoolBelonging = schoolBelonging.clamped(to: 0...100)
        reputationRisk = reputationRisk.clamped(to: 0...100)
        teacherSupport = teacherSupport.clamped(to: 0...100)
        applicationReadiness = applicationReadiness.clamped(to: 0...100)
        campusFit = campusFit.clamped(to: 0...100)
        burnoutRisk = burnoutRisk.clamped(to: 0...100)
        disciplineRecord = disciplineRecord.clamped(to: 0...100)
        mentorSupport = mentorSupport.clamped(to: 0...100)
        peerPressure = peerPressure.clamped(to: 0...100)
        yearsInStage = max(0, yearsInStage)
        credentialStrength = credentialStrength.clamped(to: 0...100)
        yearsSinceCredential = max(0, yearsSinceCredential)
        formativeSchoolTags = formativeSchoolTags.reduce(into: [:]) { partial, pair in
            let value = pair.value.clamped(to: 0...100)
            if value > 0 {
                partial[pair.key] = value
            }
        }
        highSchoolIdentityForces.indices.forEach { highSchoolIdentityForces[$0].clamp() }
        highSchoolIdentityForces = Array(highSchoolIdentityForces.filter { $0.strength > 0 }.sorted { $0.strength > $1.strength }.prefix(3))
    }
}
