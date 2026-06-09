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
    }
}

