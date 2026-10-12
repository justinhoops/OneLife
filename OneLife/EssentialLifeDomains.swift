import Foundation

private func essentialBound(_ value: Int) -> Int { min(100, max(0, value)) }

// MARK: - Phase 1: ordinary career

enum CareerTrack: String, Codable, CaseIterable, Identifiable {
    case undecided, office, trades, careService, freelance
    var id: String { rawValue }
    var title: String {
        switch self {
        case .undecided: "Undecided"
        case .office: "Office"
        case .trades: "Trades"
        case .careService: "Care / Service"
        case .freelance: "Freelance"
        }
    }
}

enum CareerRank: String, Codable, CaseIterable {
    case unranked, entry, established, senior, retired
}

enum CareerFocus: String, Codable, CaseIterable, Identifiable {
    case technicalDepth, peopleLeadership, clientTrust

    var id: String { rawValue }
    var title: String {
        switch self {
        case .technicalDepth: "Technical depth"
        case .peopleLeadership: "People leadership"
        case .clientTrust: "Client trust"
        }
    }
}

struct CareerPromotionRequirements: Equatable {
    let performance: Int
    let skill: Int
    let credentialProgress: Int
}

enum EmployerType: String, Codable, CaseIterable, Identifiable {
    case smallBusiness, corporation, government, hospital, school, nonprofit, unionWorkplace, selfEmployed

    var id: String { rawValue }
    var title: String {
        switch self {
        case .smallBusiness: "Small business"
        case .corporation: "Corporation"
        case .government: "Government"
        case .hospital: "Hospital system"
        case .school: "School district"
        case .nonprofit: "Nonprofit"
        case .unionWorkplace: "Union workplace"
        case .selfEmployed: "Self-employed"
        }
    }
}

enum WorkplaceCulture: String, Codable, CaseIterable, Identifiable {
    case supportive, demanding, political, unstable, missionDriven, transactional

    var id: String { rawValue }
    var title: String {
        switch self {
        case .supportive: "Supportive"
        case .demanding: "Demanding"
        case .political: "Political"
        case .unstable: "Unstable"
        case .missionDriven: "Mission-driven"
        case .transactional: "Transactional"
        }
    }
}

struct WorkplaceState: Codable, Equatable {
    var employer: EmployerType = .corporation
    var culture: WorkplaceCulture = .transactional
    var managerRelationship = 45
    var coworkerStanding = 45
    var flexibility = 25
    var stability = 50
    var yearsAtEmployer = 0

    mutating func clamp() {
        managerRelationship = essentialBound(managerRelationship)
        coworkerStanding = essentialBound(coworkerStanding)
        flexibility = essentialBound(flexibility)
        stability = essentialBound(stability)
        yearsAtEmployer = max(0, yearsAtEmployer)
    }

    static func starting(for track: CareerTrack) -> WorkplaceState {
        switch track {
        case .office: WorkplaceState(employer: .corporation, culture: .transactional, flexibility: 28, stability: 52)
        case .trades: WorkplaceState(employer: .smallBusiness, culture: .demanding, flexibility: 38, stability: 62)
        case .careService: WorkplaceState(employer: .nonprofit, culture: .missionDriven, flexibility: 22, stability: 50)
        case .freelance: WorkplaceState(employer: .selfEmployed, culture: .transactional, flexibility: 72, stability: 30)
        case .undecided: WorkplaceState()
        }
    }
}

/// A specific occupation within a broad career family. Pass 0 keeps the
/// existing family/level simulation authoritative; occupations are metadata
/// and save-compatible identity until later career passes add progression.
enum CareerOccupation: String, Codable, CaseIterable, Identifiable {
    case officeAdministrator, accountant, humanResourcesSpecialist, salesRepresentative
    case electrician, plumber, mechanic, constructionWorker
    case teacher, nurse, caregiver, restaurantManager
    case designer, developer, consultant, independentContractor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .officeAdministrator: "Office Administrator"
        case .accountant: "Accountant"
        case .humanResourcesSpecialist: "Human Resources Specialist"
        case .salesRepresentative: "Sales Representative"
        case .electrician: "Electrician"
        case .plumber: "Plumber"
        case .mechanic: "Automotive Mechanic"
        case .constructionWorker: "Construction Worker"
        case .teacher: "Teacher"
        case .nurse: "Nurse"
        case .caregiver: "Caregiver"
        case .restaurantManager: "Restaurant Manager"
        case .designer: "Freelance Designer"
        case .developer: "Freelance Developer"
        case .consultant: "Independent Consultant"
        case .independentContractor: "Independent Contractor"
        }
    }

    var track: CareerTrack {
        switch self {
        case .officeAdministrator, .accountant, .humanResourcesSpecialist, .salesRepresentative: .office
        case .electrician, .plumber, .mechanic, .constructionWorker: .trades
        case .teacher, .nurse, .caregiver, .restaurantManager: .careService
        case .designer, .developer, .consultant, .independentContractor: .freelance
        }
    }

    var rankTitles: [String] {
        switch self {
        case .officeAdministrator: ["Administrative Assistant", "Senior Administrator", "Operations Manager", "Retired Administrator"]
        case .accountant: ["Junior Accountant", "Staff Accountant", "Controller", "Retired Accountant"]
        case .humanResourcesSpecialist: ["HR Coordinator", "HR Specialist", "People Operations Manager", "Retired HR Specialist"]
        case .salesRepresentative: ["Sales Representative", "Account Executive", "Sales Director", "Retired Salesperson"]
        case .electrician: ["Apprentice Electrician", "Licensed Electrician", "Electrical Foreman", "Retired Electrician"]
        case .plumber: ["Plumbing Apprentice", "Licensed Plumber", "Master Plumber", "Retired Plumber"]
        case .mechanic: ["Junior Mechanic", "Automotive Technician", "Shop Lead", "Retired Mechanic"]
        case .constructionWorker: ["Construction Laborer", "Skilled Builder", "Site Foreman", "Retired Builder"]
        case .teacher: ["Classroom Teacher", "Lead Teacher", "Department Chair", "Retired Teacher"]
        case .nurse: ["Staff Nurse", "Charge Nurse", "Nurse Manager", "Retired Nurse"]
        case .caregiver: ["Care Assistant", "Senior Caregiver", "Care Coordinator", "Retired Caregiver"]
        case .restaurantManager: ["Shift Supervisor", "Restaurant Manager", "Area Manager", "Retired Manager"]
        case .designer: ["Contract Designer", "Independent Designer", "Creative Lead", "Retired Designer"]
        case .developer: ["Contract Developer", "Independent Developer", "Technical Lead", "Retired Developer"]
        case .consultant: ["Associate Consultant", "Independent Consultant", "Principal Consultant", "Retired Consultant"]
        case .independentContractor: ["New Contractor", "Established Contractor", "Lead Contractor", "Retired Contractor"]
        }
    }

    func rankTitle(for level: CareerLevel) -> String {
        return switch level {
        case .entry: rankTitles[0]
        case .established: rankTitles[1]
        case .senior: rankTitles[2]
        case .retired: rankTitles[3]
        case .unemployed: "Unranked"
        }
    }
}

struct CareerOccupationDefinition: Equatable {
    let occupation: CareerOccupation
    let track: CareerTrack
    let startingSalary: Int
    let establishedSalary: Int
    let seniorSalary: Int
    let startingSecurity: Int
    let burnoutPressure: Int
    let physicalPressure: Int
    let socialPressure: Int

    var title: String { occupation.title }
}

/// The authored occupation catalog is deliberately pure data. CareerSystem
/// can consume it in later passes without gaining responsibility for content
/// authoring or occupation-specific progression rules.
enum CareerCatalog {
    static let definitions: [CareerOccupationDefinition] = [
        .init(occupation: .officeAdministrator, track: .office, startingSalary: 42_000, establishedSalary: 58_000, seniorSalary: 76_000, startingSecurity: 50, burnoutPressure: 4, physicalPressure: 1, socialPressure: 2),
        .init(occupation: .accountant, track: .office, startingSalary: 46_000, establishedSalary: 68_000, seniorSalary: 96_000, startingSecurity: 56, burnoutPressure: 4, physicalPressure: 1, socialPressure: 2),
        .init(occupation: .humanResourcesSpecialist, track: .office, startingSalary: 44_000, establishedSalary: 63_000, seniorSalary: 88_000, startingSecurity: 52, burnoutPressure: 5, physicalPressure: 1, socialPressure: 4),
        .init(occupation: .salesRepresentative, track: .office, startingSalary: 38_000, establishedSalary: 64_000, seniorSalary: 105_000, startingSecurity: 38, burnoutPressure: 5, physicalPressure: 1, socialPressure: 5),
        .init(occupation: .electrician, track: .trades, startingSalary: 45_000, establishedSalary: 70_000, seniorSalary: 96_000, startingSecurity: 70, burnoutPressure: 3, physicalPressure: 5, socialPressure: 1),
        .init(occupation: .plumber, track: .trades, startingSalary: 44_000, establishedSalary: 68_000, seniorSalary: 94_000, startingSecurity: 68, burnoutPressure: 3, physicalPressure: 5, socialPressure: 1),
        .init(occupation: .mechanic, track: .trades, startingSalary: 40_000, establishedSalary: 58_000, seniorSalary: 78_000, startingSecurity: 62, burnoutPressure: 3, physicalPressure: 4, socialPressure: 2),
        .init(occupation: .constructionWorker, track: .trades, startingSalary: 42_000, establishedSalary: 64_000, seniorSalary: 86_000, startingSecurity: 58, burnoutPressure: 4, physicalPressure: 6, socialPressure: 1),
        .init(occupation: .teacher, track: .careService, startingSalary: 39_000, establishedSalary: 54_000, seniorSalary: 72_000, startingSecurity: 58, burnoutPressure: 6, physicalPressure: 1, socialPressure: 6),
        .init(occupation: .nurse, track: .careService, startingSalary: 52_000, establishedSalary: 70_000, seniorSalary: 88_000, startingSecurity: 64, burnoutPressure: 7, physicalPressure: 4, socialPressure: 6),
        .init(occupation: .caregiver, track: .careService, startingSalary: 32_000, establishedSalary: 42_000, seniorSalary: 56_000, startingSecurity: 48, burnoutPressure: 7, physicalPressure: 3, socialPressure: 7),
        .init(occupation: .restaurantManager, track: .careService, startingSalary: 36_000, establishedSalary: 52_000, seniorSalary: 70_000, startingSecurity: 42, burnoutPressure: 6, physicalPressure: 2, socialPressure: 6),
        .init(occupation: .designer, track: .freelance, startingSalary: 36_000, establishedSalary: 62_000, seniorSalary: 96_000, startingSecurity: 28, burnoutPressure: 3, physicalPressure: 1, socialPressure: 3),
        .init(occupation: .developer, track: .freelance, startingSalary: 52_000, establishedSalary: 82_000, seniorSalary: 130_000, startingSecurity: 34, burnoutPressure: 4, physicalPressure: 1, socialPressure: 2),
        .init(occupation: .consultant, track: .freelance, startingSalary: 48_000, establishedSalary: 78_000, seniorSalary: 125_000, startingSecurity: 30, burnoutPressure: 5, physicalPressure: 1, socialPressure: 5),
        .init(occupation: .independentContractor, track: .freelance, startingSalary: 40_000, establishedSalary: 68_000, seniorSalary: 105_000, startingSecurity: 24, burnoutPressure: 3, physicalPressure: 3, socialPressure: 2)
    ]

    static func definition(for occupation: CareerOccupation) -> CareerOccupationDefinition {
        guard let definition = definitions.first(where: { $0.occupation == occupation }) else {
            preconditionFailure("Missing career occupation definition: \(occupation.rawValue)")
        }
        return definition
    }

    static func defaultOccupation(for track: CareerTrack) -> CareerOccupation? {
        definitions.first(where: { $0.track == track })?.occupation
    }

    static func occupations(for track: CareerTrack) -> [CareerOccupationDefinition] {
        definitions.filter { $0.track == track }
    }

    static func promotionRequirements(for occupation: CareerOccupation, advancingFrom level: CareerLevel) -> CareerPromotionRequirements {
        let seniorCredentialRequirement: Int = switch occupation {
        case .accountant, .humanResourcesSpecialist, .electrician, .plumber, .teacher, .nurse: 35
        default: 0
        }
        return switch level {
        case .entry: CareerPromotionRequirements(performance: 70, skill: 45, credentialProgress: 0)
        case .established: CareerPromotionRequirements(performance: 82, skill: 60, credentialProgress: seniorCredentialRequirement)
        default: CareerPromotionRequirements(performance: 100, skill: 100, credentialProgress: 100)
        }
    }
}

enum CareerLevel: String, Codable, CaseIterable {
    case unemployed, entry, established, senior, retired
    var isEmployed: Bool { self == .entry || self == .established || self == .senior }
}

enum CareerTransition: String, Codable {
    case started, hired, promoted, laidOff, pivoted, retired
}

enum CareerClass: String, Codable, CaseIterable, Identifiable {
    case normal, partTime, special, diamond

    var id: String { rawValue }
    var title: String {
        switch self {
        case .normal: "Normal career"
        case .partTime: "Part-time work"
        case .special: "Special career"
        case .diamond: "Diamond career"
        }
    }
}

/// Career policy values belong to the career domain, while still remaining
/// centralized and tunable. Systems should read these values instead of
/// embedding progression gates in action handlers.
enum CareerPolicy {
    static let specialMinimumPerformance = 68
    static let specialMinimumReputation = 55
    static let specialProvenPerformance = 82
    static let specialProvenReputation = 70
    static let diamondMinimumMomentum = 60
    static let diamondMinimumReputation = 80
    static let diamondCapitalThreshold = 100_000
}

enum SpecialCareerID: String, Codable, CaseIterable, Identifiable {
    case entrepreneurship
    case politics
    case performance
    case criminalSpecialist

    var id: String { rawValue }
    var title: String {
        switch self {
        case .entrepreneurship: "Entrepreneurship"
        case .politics: "Politics"
        case .performance: "Performance"
        case .criminalSpecialist: "Criminal specialization"
        }
    }
}

enum VentureStage: String, Codable, CaseIterable { case idea, prototype, seed, growth, scale, exited, failed }
struct VentureOffer: Codable, Equatable, Identifiable {
    var id: String
    var headline: String
    var amount: Int
    var expiresAtAge: Int
}
struct VentureState: Codable, Equatable {
    var stage: VentureStage = .idea
    var companyCash = 10_000
    var annualBurn = 3_000
    var traction = 5
    var teamTrust = 50
    var founderEquity = 100
    var valuation = 15_000
    var pendingOffer: VentureOffer?
    var decisionsThisYear = 0
    var decisionAge = -1
    var random: SeededRandom
    init(seed: UInt64) { random = SeededRandom(seed: seed) }
    mutating func clamp() {
        companyCash = max(0, companyCash); annualBurn = min(20_000, max(500, annualBurn))
        traction = min(100, max(0, traction)); teamTrust = min(100, max(0, teamTrust))
        founderEquity = min(100, max(0, founderEquity)); valuation = max(0, valuation)
        decisionsThisYear = min(2, max(0, decisionsThisYear))
    }
}
enum VentureCommand: Equatable { case pivot, hireAdvisor, cutBurn, acceptOffer, declineOffer }
struct VentureYearOutcome: Equatable {
    var headline: String
    var detail: String
    var health: Int = 0
    var relationship: Int = 0
}
enum VentureSystem {
    static func decide(_ command: VentureCommand, venture: inout VentureState, age: Int) -> VentureYearOutcome? {
        if venture.decisionAge != age { venture.decisionAge = age; venture.decisionsThisYear = 0 }
        guard venture.decisionsThisYear < 2 else { return nil }
        venture.decisionsThisYear += 1
        switch command {
        case .pivot:
            guard venture.stage != .failed && venture.stage != .exited else { return nil }
            venture.traction = min(100, venture.traction + 12); venture.teamTrust = max(0, venture.teamTrust - 5)
            return .init(headline: "You Changed The Product", detail: "The pivot bought another chance, while the team had to absorb another reset.", health: -2, relationship: -1)
        case .hireAdvisor:
            guard venture.companyCash >= 2_000, venture.stage != .failed else { return nil }
            venture.companyCash -= 2_000; venture.traction = min(100, venture.traction + 8); venture.teamTrust = min(100, venture.teamTrust + 4)
            return .init(headline: "You Bought Experienced Advice", detail: "An advisor helped sharpen the next move, at a cost to runway.", health: -1)
        case .cutBurn:
            guard venture.stage != .failed else { return nil }
            venture.annualBurn = max(500, venture.annualBurn * 3 / 4); venture.teamTrust = max(0, venture.teamTrust - 8)
            return .init(headline: "You Cut The Company Burn", detail: "The runway lengthened. The remaining team felt the loss of support.", relationship: -1)
        case .acceptOffer:
            guard let offer = venture.pendingOffer, age <= offer.expiresAtAge else { return nil }
            venture.companyCash += offer.amount; venture.founderEquity = 0; venture.stage = .exited; venture.pendingOffer = nil
            return .init(headline: "You Sold Your Company", detail: "The exit was modest. The work is over, and your share is now yours.")
        case .declineOffer:
            guard venture.pendingOffer != nil else { return nil }; venture.pendingOffer = nil
            return .init(headline: "You Turned Down The Offer", detail: "You kept control and accepted the risk of continuing.")
        }
    }
    static func resolveYear(venture: inout VentureState, age: Int, talent: SpecialTalent?, drive: Int = 50, riskTolerance: Int = 50, policy: WorldModifierSnapshot) -> VentureYearOutcome? {
        guard venture.stage != .failed && venture.stage != .exited else { return nil }
        if let offer = venture.pendingOffer, age > offer.expiresAtAge { venture.pendingOffer = nil }
        venture.companyCash = max(0, venture.companyCash - Int((Double(venture.annualBurn) * policy.livingCostMultiplier).rounded()))
        let skill = talent == .entrepreneurial ? 12 : 0
        let roll = venture.random.next(in: 0...99)
        let opportunity = 42 + skill + (drive - 50) / 10 + Int((policy.incomeMultiplier - 1) * 50)
        venture.traction = min(100, max(0, venture.traction + (roll < opportunity ? 7 : -3)))
        if venture.companyCash == 0 { venture.stage = .failed; return .init(headline: "The Company Ran Out Of Cash", detail: "The runway ended before the business could support itself.", health: -5, relationship: -3) }
        if venture.traction >= 25 && venture.stage == .idea { venture.stage = .prototype }
        else if venture.traction >= 42 && venture.stage == .prototype { venture.stage = .seed }
        else if venture.traction >= 60 && venture.stage == .seed { venture.stage = .growth }
        else if venture.traction >= 78 && venture.stage == .growth { venture.stage = .scale }
        venture.valuation = max(0, venture.companyCash + venture.traction * venture.traction * 600)
        if venture.stage == .growth && roll < max(2, 7 + (riskTolerance - 50) / 10) {
            let amount = max(25_000, venture.valuation * venture.founderEquity / 100)
            venture.pendingOffer = VentureOffer(id: "venture-\(age)-\(roll)", headline: "An Acquisition Offer Arrived", amount: amount, expiresAtAge: age + 1)
            venture.clamp(); return .init(headline: "An Acquisition Offer Arrived", detail: "A buyer offered $\(amount). Accept it or let the offer expire.", health: -2, relationship: -1)
        }
        venture.clamp()
        return .init(headline: "The Venture Year Closed", detail: "Traction \(venture.traction) · runway \(venture.companyCash / max(1, venture.annualBurn)) years · value estimate $\(venture.valuation)", health: -1, relationship: -1)
    }
}

/// Special careers are interactive systems, not premium occupation entries.
/// The system key allows each future career to own its mechanics without
/// turning CareerSystem into a cross-domain god object.
struct SpecialCareerDefinition: Equatable {
    let id: SpecialCareerID
    let systemKey: String
    let entryDescription: String
}

enum DiamondCareerID: String, Codable, CaseIterable, Identifiable {
    case institutionBuilder
    case capitalOperator

    var id: String { rawValue }
    var title: String {
        switch self {
        case .institutionBuilder: "Institution builder"
        case .capitalOperator: "Capital operator"
        }
    }
}

enum DiamondGate: Equatable {
    case specialCareer
    case capital(Int)
    case reputation(Int)
    case specialMomentum(Int)
}

struct DiamondCareerDefinition: Equatable {
    let id: DiamondCareerID
    let systemKey: String
    let gates: [DiamondGate]
    let entryDescription: String
}

enum CareerOpportunityCatalog {
    static let specialCareers: [SpecialCareerDefinition] = [
        .init(id: .entrepreneurship, systemKey: "entrepreneurship", entryDescription: "Build, fund, and risk something that can outgrow your labor."),
    ]

    static let diamondCareers: [DiamondCareerDefinition] = [
        .init(
            id: .institutionBuilder,
            systemKey: "institution-builder",
            gates: [.specialCareer, .capital(CareerPolicy.diamondCapitalThreshold), .reputation(CareerPolicy.diamondMinimumReputation), .specialMomentum(CareerPolicy.diamondMinimumMomentum)],
            entryDescription: "Put serious capital and public credibility behind an institution."
        ),
        .init(
            id: .capitalOperator,
            systemKey: "capital-operator",
            gates: [.capital(CareerPolicy.diamondCapitalThreshold), .reputation(65)],
            entryDescription: "Enter an ownership-scale career through capital and financial credibility."
        ),
    ]

    static func diamondDefinition(for id: DiamondCareerID) -> DiamondCareerDefinition {
        guard let definition = diamondCareers.first(where: { $0.id == id }) else {
            preconditionFailure("Missing Diamond career definition: \(id.rawValue)")
        }
        return definition
    }
}

struct CareerState: Codable, Equatable {
    var careerClass: CareerClass = .normal
    var track: CareerTrack = .undecided
    /// Optional during migration so an undecided legacy character remains
    /// undecided. Employed legacy characters receive a catalog default.
    var occupation: CareerOccupation? = nil
    var level: CareerLevel = .entry
    var performance = 45
    var skill = 45
    var credentialProgress = 0
    var promotionProgress = 0
    var negotiationLeverage = 0
    var workload = 20
    var focus: CareerFocus?
    var focusProgress = 0
    var benefits = 50
    var paidLeaveDays = 20
    var mentorship = 0
    var retirementReadiness = 0
    var careerReputation = 0
    var referenceStrength = 0
    var workplace = WorkplaceState()
    var security = 50
    var burnout = 10
    var tenure = 0
    var unemploymentDuration = 0
    var specialMomentum = 0
    var legacyLeverage = 0
    /// The selected interactive pathway is separate from the normal
    /// occupation ladder. It remains optional for save compatibility while
    /// existing Special careers are migrated to the generic pathway.
    var specialCareerID: SpecialCareerID?
    var diamondCareerID: DiamondCareerID?
    var lastTransition: CareerTransition = .started
    var activeSituation: CareerSituation?
    var resolvedSituations: [ResolvedSituation] = []
    /// Crime remains a Career specialization rather than a new top-level tab.
    var criminalPath: CriminalPathState?
    var venture: VentureState?

    var annualIncome: Int { EconomyPolicy.salary(self) }
    var rank: CareerRank {
        switch level {
        case .unemployed: .unranked
        case .entry: .entry
        case .established: .established
        case .senior: .senior
        case .retired: .retired
        }
    }
    var rankTitle: String { occupation?.rankTitle(for: level) ?? level.rawValue.capitalized }

    mutating func clamp() {
        performance = essentialBound(performance)
        skill = essentialBound(skill)
        credentialProgress = essentialBound(credentialProgress)
        promotionProgress = essentialBound(promotionProgress)
        negotiationLeverage = essentialBound(negotiationLeverage)
        workload = essentialBound(workload)
        focusProgress = essentialBound(focusProgress)
        benefits = essentialBound(benefits)
        paidLeaveDays = min(40, max(0, paidLeaveDays))
        mentorship = essentialBound(mentorship)
        retirementReadiness = essentialBound(retirementReadiness)
        careerReputation = essentialBound(careerReputation)
        referenceStrength = essentialBound(referenceStrength)
        workplace.clamp()
        security = essentialBound(security)
        burnout = essentialBound(burnout)
        tenure = max(0, tenure)
        unemploymentDuration = max(0, unemploymentDuration)
        specialMomentum = essentialBound(specialMomentum)
        legacyLeverage = essentialBound(legacyLeverage)
        venture?.clamp()
        resolvedSituations = Array(resolvedSituations.prefix(4))
    }
}

extension CareerState {
    enum CodingKeys: String, CodingKey {
        case careerClass, track, occupation, level, performance, skill, credentialProgress, promotionProgress, negotiationLeverage, workload, focus, focusProgress, benefits, paidLeaveDays, mentorship, retirementReadiness, careerReputation, referenceStrength, workplace, security, burnout, tenure, unemploymentDuration, specialMomentum, legacyLeverage, specialCareerID, diamondCareerID, lastTransition
        case activeSituation, resolvedSituations, criminalPath, venture
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        careerClass = try c.decodeIfPresent(CareerClass.self, forKey: .careerClass) ?? .normal
        track = try c.decodeIfPresent(CareerTrack.self, forKey: .track) ?? .undecided
        occupation = try c.decodeIfPresent(CareerOccupation.self, forKey: .occupation)
            ?? CareerCatalog.defaultOccupation(for: track)
        level = try c.decodeIfPresent(CareerLevel.self, forKey: .level) ?? .entry
        performance = try c.decodeIfPresent(Int.self, forKey: .performance) ?? 45
        skill = try c.decodeIfPresent(Int.self, forKey: .skill) ?? 45
        credentialProgress = try c.decodeIfPresent(Int.self, forKey: .credentialProgress) ?? 0
        promotionProgress = try c.decodeIfPresent(Int.self, forKey: .promotionProgress) ?? 0
        negotiationLeverage = try c.decodeIfPresent(Int.self, forKey: .negotiationLeverage) ?? 0
        workload = try c.decodeIfPresent(Int.self, forKey: .workload) ?? 20
        focus = try c.decodeIfPresent(CareerFocus.self, forKey: .focus)
        focusProgress = try c.decodeIfPresent(Int.self, forKey: .focusProgress) ?? 0
        benefits = try c.decodeIfPresent(Int.self, forKey: .benefits) ?? 50
        paidLeaveDays = try c.decodeIfPresent(Int.self, forKey: .paidLeaveDays) ?? 20
        mentorship = try c.decodeIfPresent(Int.self, forKey: .mentorship) ?? 0
        retirementReadiness = try c.decodeIfPresent(Int.self, forKey: .retirementReadiness) ?? 0
        careerReputation = try c.decodeIfPresent(Int.self, forKey: .careerReputation) ?? 0
        referenceStrength = try c.decodeIfPresent(Int.self, forKey: .referenceStrength) ?? 0
        workplace = try c.decodeIfPresent(WorkplaceState.self, forKey: .workplace) ?? WorkplaceState.starting(for: track)
        security = try c.decodeIfPresent(Int.self, forKey: .security) ?? 50
        burnout = try c.decodeIfPresent(Int.self, forKey: .burnout) ?? 10
        tenure = try c.decodeIfPresent(Int.self, forKey: .tenure) ?? 0
        unemploymentDuration = try c.decodeIfPresent(Int.self, forKey: .unemploymentDuration) ?? 0
        specialMomentum = try c.decodeIfPresent(Int.self, forKey: .specialMomentum) ?? 0
        legacyLeverage = try c.decodeIfPresent(Int.self, forKey: .legacyLeverage) ?? 0
        specialCareerID = try c.decodeIfPresent(SpecialCareerID.self, forKey: .specialCareerID)
        diamondCareerID = try c.decodeIfPresent(DiamondCareerID.self, forKey: .diamondCareerID)
        lastTransition = try c.decodeIfPresent(CareerTransition.self, forKey: .lastTransition) ?? .started
        activeSituation = try c.decodeIfPresent(CareerSituation.self, forKey: .activeSituation)
        resolvedSituations = try c.decodeIfPresent([ResolvedSituation].self, forKey: .resolvedSituations) ?? []
        criminalPath = try c.decodeIfPresent(CriminalPathState.self, forKey: .criminalPath)
        venture = try c.decodeIfPresent(VentureState.self, forKey: .venture)
        clamp()
    }
}

// Legacy source/adapter. CareerState is canonical in LifeState.
enum JobTier: String, Codable { case unemployed, entry, skilled, retired; var isEmployed: Bool { self == .entry || self == .skilled } }
struct JobState: Codable, Equatable {
    var tier: JobTier = .entry
    var annualIncome: Int { tier == .skilled ? 600 : tier == .entry ? 350 : tier == .retired ? 240 : 0 }
    var livingCost: Int { tier == .skilled ? 420 : tier == .entry ? 300 : tier == .retired ? 300 : 220 }
}

extension CareerState {
    init(legacy job: JobState) {
        level = switch job.tier {
        case .unemployed: .unemployed
        case .entry: .entry
        case .skilled: .established
        case .retired: .retired
        }
        lastTransition = level == .retired ? .retired : .started
        occupation = CareerCatalog.defaultOccupation(for: track)
    }

    var legacyJob: JobState {
        let tier: JobTier = switch level {
        case .unemployed: .unemployed
        case .entry: .entry
        case .established, .senior: .skilled
        case .retired: .retired
        }
        return JobState(tier: tier)
    }
}

// MARK: - Phase 2: household finance and housing

enum HousingKind: String, Codable, CaseIterable { case renting, owning, delinquent }

struct HousingState: Codable, Equatable {
    var kind: HousingKind = .renting
    var homeValue = 0
    var mortgageBalance = 0
    var annualCost = 90
    var maintenanceReserve = 0
    var delinquentYears = 0
    var equity: Int { max(0, homeValue - mortgageBalance) }
}

struct AnnualLedger: Codable, Equatable {
    var income = 0
    var rentalIncome = 0
    var taxes = 0
    var rentalTaxes = 0
    var livingCosts = 0
    var debtInterest = 0
    var housingCosts = 0
    var propertyOperatingCosts = 0
    var retirementContribution = 0
    var net = 0
    var economy: EconomyAnnualDetail? = nil
}

extension AnnualLedger {
    enum CodingKeys: String, CodingKey {
        case income, rentalIncome, taxes, rentalTaxes, livingCosts, debtInterest
        case housingCosts, propertyOperatingCosts, retirementContribution, net, economy
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        income = try c.decodeIfPresent(Int.self, forKey: .income) ?? 0
        rentalIncome = try c.decodeIfPresent(Int.self, forKey: .rentalIncome) ?? 0
        taxes = try c.decodeIfPresent(Int.self, forKey: .taxes) ?? 0
        rentalTaxes = try c.decodeIfPresent(Int.self, forKey: .rentalTaxes) ?? 0
        livingCosts = try c.decodeIfPresent(Int.self, forKey: .livingCosts) ?? 0
        debtInterest = try c.decodeIfPresent(Int.self, forKey: .debtInterest) ?? 0
        housingCosts = try c.decodeIfPresent(Int.self, forKey: .housingCosts) ?? 0
        propertyOperatingCosts = try c.decodeIfPresent(Int.self, forKey: .propertyOperatingCosts) ?? housingCosts
        retirementContribution = try c.decodeIfPresent(Int.self, forKey: .retirementContribution) ?? 0
        net = try c.decodeIfPresent(Int.self, forKey: .net) ?? 0
        economy = try c.decodeIfPresent(EconomyAnnualDetail.self, forKey: .economy)
    }
}

struct FinanceState: Codable, Equatable {
    var studentDebt = 0
    var consumerDebt = 0
    var medicalDebt = 0
    var annualLedger = AnnualLedger()
    var retirementBalance = 0
    var retirementContributionPercent = 0
    var financialStress = 15
    var hardshipExtensionAge: Int? = nil
    var housing = HousingState()
    var economy = EconomyState()
    var totalDebt: Int { studentDebt + consumerDebt + medicalDebt }
    var netWorthExcludingCash: Int { retirementBalance - studentDebt - consumerDebt - medicalDebt }
    mutating func clamp() {
        studentDebt = max(0, studentDebt); consumerDebt = max(0, consumerDebt); medicalDebt = max(0, medicalDebt)
        retirementBalance = max(0, retirementBalance)
        retirementContributionPercent = min(15, max(0, retirementContributionPercent))
        financialStress = essentialBound(financialStress)
        housing.homeValue = max(0, housing.homeValue); housing.mortgageBalance = max(0, housing.mortgageBalance)
    }
}

// MARK: - Phase 3: partner and family lifecycle

enum RelationshipStage: String, Codable, CaseIterable { case dating, committed, married, separated, former }
enum FamilyIntention: String, Codable, CaseIterable, Identifiable {
    case childfree, openToChildren, buildingFamily
    var id: String { rawValue }
    var title: String {
        switch self { case .childfree: "Childfree"; case .openToChildren: "Open to Children"; case .buildingFamily: "Building a Family" }
    }
}
enum ChildTemperament: String, Codable, CaseIterable { case calm, intense, curious, social }
enum AdultChildOutcome: String, Codable { case independent, findingFooting, needsSupport }

struct ChildState: Codable, Equatable, Identifiable {
    var lineageIndex = 0
    var id: String { "\(lineageIndex)-\(name)" }
    var name: String
    var age = 0
    var temperament: ChildTemperament
    var bond = 55
    var dependent = true
    var livesAtHome = true
    var adultOutcome: AdultChildOutcome?
}

struct FamilyContact: Codable, Equatable, Identifiable {
    enum Role: String, Codable { case parent, sibling, relative }
    var id: String { "\(role.rawValue)-\(name)" }
    var name: String
    var role: Role
    var bond = 45
    var lastResolvedAge: Int
    /// Family is not a second set of buttons. Contacts form opinions from the
    /// life the player is already living, with their own personality shaping
    /// what they notice and what they forgive.
    var personality: PersonalityProfile = .neutral
    var stance: FamilyContactStance = .neutral
    var lastJudgementAge: Int = 0
    var lastJudgementReason: String?
    /// Independent of passive appraisal. A contact can keep forming opinions
    /// every year without starving a rare, caused family moment.
    var lastSituationAge: Int = 0

    init(
        name: String,
        role: Role,
        bond: Int = 45,
        lastResolvedAge: Int,
        personality: PersonalityProfile = .neutral,
        stance: FamilyContactStance = .neutral,
        lastJudgementAge: Int = 0,
        lastJudgementReason: String? = nil,
        lastSituationAge: Int = 0
    ) {
        self.name = name
        self.role = role
        self.bond = bond
        self.lastResolvedAge = lastResolvedAge
        self.personality = personality
        self.stance = stance
        self.lastJudgementAge = lastJudgementAge
        self.lastJudgementReason = lastJudgementReason
        self.lastSituationAge = lastSituationAge
    }

    enum CodingKeys: String, CodingKey {
        case name, role, bond, lastResolvedAge, personality, stance, lastJudgementAge, lastJudgementReason, lastSituationAge
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        role = try c.decode(Role.self, forKey: .role)
        bond = try c.decodeIfPresent(Int.self, forKey: .bond) ?? 45
        lastResolvedAge = try c.decodeIfPresent(Int.self, forKey: .lastResolvedAge) ?? 0
        personality = try c.decodeIfPresent(PersonalityProfile.self, forKey: .personality) ?? .neutral
        stance = try c.decodeIfPresent(FamilyContactStance.self, forKey: .stance) ?? .neutral
        lastJudgementAge = try c.decodeIfPresent(Int.self, forKey: .lastJudgementAge) ?? 0
        lastJudgementReason = try c.decodeIfPresent(String.self, forKey: .lastJudgementReason)
        lastSituationAge = try c.decodeIfPresent(Int.self, forKey: .lastSituationAge) ?? 0
    }
}

enum FamilyContactStance: String, Codable, Equatable {
    case warm, neutral, strained, estranged
}

struct FamilyState: Codable, Equatable {
    var intention: FamilyIntention = .openToChildren
    var children: [ChildState] = []
    var contacts: [FamilyContact] = []
    var caregivingLoad = 0
    var dependentLoad: Int { children.filter(\.dependent).count }
    mutating func clamp() {
        caregivingLoad = essentialBound(caregivingLoad)
        for index in children.indices { children[index].bond = essentialBound(children[index].bond) }
        for index in contacts.indices {
            contacts[index].bond = essentialBound(contacts[index].bond)
            contacts[index].personality.clamp()
        }
        children = Array(children.prefix(6))
        contacts = Array(contacts.prefix(6))
    }
}

// MARK: - Phase 4: canonical health

enum CareAccess: String, Codable { case limited, basic, reliable }
enum ConditionKind: String, Codable, CaseIterable {
    case depression, chronicPain, cardiovascularStrain, metabolicIllness, addiction

    var title: String {
        switch self {
        case .depression: "Depression"
        case .chronicPain: "Chronic pain"
        case .cardiovascularStrain: "Cardiovascular strain"
        case .metabolicIllness: "Metabolic illness"
        case .addiction: "Addiction"
        }
    }
}
enum ConditionStatus: String, Codable {
    case active, stable

    var title: String { rawValue.capitalized }
}

struct ChronicCondition: Codable, Equatable, Identifiable {
    var id: ConditionKind { kind }
    var kind: ConditionKind
    var severity: Int
    var management: Int
    var status: ConditionStatus = .active

    enum CodingKeys: String, CodingKey { case kind, severity, management, status }

    init(kind: ConditionKind, severity: Int, management: Int, status: ConditionStatus = .active) {
        self.kind = kind
        self.severity = severity
        self.management = management
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(ConditionKind.self, forKey: .kind)
        severity = try c.decode(Int.self, forKey: .severity)
        management = try c.decode(Int.self, forKey: .management)
        status = try c.decodeIfPresent(ConditionStatus.self, forKey: .status) ?? .active
    }
}

struct HealthState: Codable, Equatable {
    var physicalWellbeing = 60
    var mentalWellbeing = 60
    var bodyLoad = 0
    var careAccess: CareAccess = .basic
    var addictionPressure = 0
    var conditions: [ChronicCondition] = []
    var overall: Int { essentialBound((physicalWellbeing + mentalWellbeing) / 2 - bodyLoad / 5) }
    mutating func clamp() {
        physicalWellbeing = essentialBound(physicalWellbeing); mentalWellbeing = essentialBound(mentalWellbeing)
        bodyLoad = essentialBound(bodyLoad); addictionPressure = essentialBound(addictionPressure)
        for index in conditions.indices {
            conditions[index].severity = essentialBound(conditions[index].severity)
            conditions[index].management = essentialBound(conditions[index].management)
        }
        conditions = Array(conditions.prefix(3))
    }
}

// MARK: - Phase 5: identity, continuity and legacy

enum StartingContext: String, Codable, CaseIterable, Identifiable {
    case supported, ordinary, precarious
    var id: String { rawValue }; var title: String { rawValue.capitalized }
}
enum CoreTrait: String, Codable, CaseIterable, Identifiable {
    case driven, empathetic, adaptable
    var id: String { rawValue }; var title: String { rawValue.capitalized }
}
enum LifeThreadKind: String, Codable { case layoff, debt, burnout, familyConflict, illness, legalTrouble, majorDecision }

enum ConsequenceDomain: String, Codable, CaseIterable {
    case education, career, finance, relationships, family, health, assets, legal, world, identity
}

enum ConsequenceMagnitude: String, Codable, CaseIterable {
    case minor, major, critical

    var defaultIntensity: Int {
        switch self {
        case .minor: 2
        case .major: 4
        case .critical: 6
        }
    }
}

enum ConsequenceResolution: String, Codable {
    case open, stabilizing, resolved, permanent
}

/// Typed hand-off between sovereign domains. The emitting system describes the
/// consequence; the receiving system decides how that pressure changes its own state.
struct DomainConsequence: Codable, Equatable, Identifiable {
    var id: String { "\(source.rawValue)-\(target.rawValue)-\(kind.rawValue)-\(openedAge)-\(headline)" }
    var source: ConsequenceDomain
    var target: ConsequenceDomain
    var kind: LifeThreadKind
    var magnitude: ConsequenceMagnitude
    var openedAge: Int
    var yearsRemaining: Int
    var headline: String
    var detail: String

    func asThread() -> LifeThread {
        LifeThread(
            kind: kind,
            headline: headline,
            intensity: magnitude.defaultIntensity,
            openedAge: openedAge,
            yearsRemaining: max(1, yearsRemaining),
            source: source,
            target: target,
            detail: detail
        )
    }
}

struct LifeThread: Codable, Equatable, Identifiable {
    var id: String { "\(kind.rawValue)-\(openedAge)-\(headline)" }
    var kind: LifeThreadKind
    var headline: String
    var intensity: Int
    var openedAge: Int
    var yearsRemaining: Int
    var source: ConsequenceDomain? = nil
    var target: ConsequenceDomain? = nil
    var detail = ""
    var resolution: ConsequenceResolution = .open
}

extension LifeThread {
    private enum CodingKeys: String, CodingKey {
        case kind, headline, intensity, openedAge, yearsRemaining, source, target, detail, resolution
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(LifeThreadKind.self, forKey: .kind)
        headline = try c.decode(String.self, forKey: .headline)
        intensity = try c.decode(Int.self, forKey: .intensity)
        openedAge = try c.decode(Int.self, forKey: .openedAge)
        yearsRemaining = try c.decode(Int.self, forKey: .yearsRemaining)
        source = try c.decodeIfPresent(ConsequenceDomain.self, forKey: .source)
        target = try c.decodeIfPresent(ConsequenceDomain.self, forKey: .target)
        detail = try c.decodeIfPresent(String.self, forKey: .detail) ?? ""
        resolution = try c.decodeIfPresent(ConsequenceResolution.self, forKey: .resolution) ?? .open
    }
}

struct LegacyEcho: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var endingAge: Int
    var headline: String
    var completedAt: Date
}

struct LegacyArchive: Codable, Equatable {
    var echoes: [LegacyEcho] = []
    mutating func add(_ echo: LegacyEcho) { echoes.insert(echo, at: 0); echoes = Array(echoes.prefix(3)) }
}

final class LegacyArchiveStore {
    private let url: URL?
    init(fileManager: FileManager = .default) {
        url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("OneLife", isDirectory: true)
            .appendingPathComponent("legacy-v1.json")
    }
    func load() -> LegacyArchive {
        guard let url, let data = try? Data(contentsOf: url) else { return LegacyArchive() }
        return (try? JSONDecoder().decode(LegacyArchive.self, from: data)) ?? LegacyArchive()
    }
    func recordCompleted(_ state: LifeState) {
        guard state.isGameOver, state.endReason != nil, let url else { return }
        var archive = load()
        guard !archive.echoes.contains(where: { $0.name == state.character.name && $0.endingAge == state.character.age && $0.headline == state.lifeSummary }) else { return }
        archive.add(LegacyEcho(name: state.character.name, endingAge: state.character.age, headline: LifeReviewModel.build(from: state).legacyHeadline, completedAt: Date()))
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(archive).write(to: url, options: .atomic)
        } catch { /* Legacy is optional and never risks the active save. */ }
    }
}

// MARK: - Domain-owned action metadata

enum CareerActionEffect: String, Codable {
    case chooseOffice, chooseTrades, chooseCareService, chooseFreelance, search, pivot, promote, skill, boundaries
    case negotiateRaise, overtime, professionalNetwork, certification, careerLeave
    case changeEmployer, workplaceRelationship, flexibleSchedule, buildCareerPortfolio, requestReference, testJobMarket
    case specializeTechnical, specializeLeadership, specializeClientTrust, negotiateBenefits, usePaidLeave, mentorCoworker, prepareRetirement
    case chooseOfficeAdministrator, chooseAccountant, chooseHumanResourcesSpecialist, chooseSalesRepresentative
    case chooseElectrician, choosePlumber, chooseMechanic, chooseConstructionWorker
    case chooseTeacher, chooseNurse, chooseCaregiver, chooseRestaurantManager
    case chooseDesigner, chooseDeveloper, chooseConsultant, chooseIndependentContractor
    case partTime, enterSpecial, enterDiamond
}
enum FinanceActionEffect: String, Codable {
    case budget, payDebt, retirement, buyHome, sellOrDownsize, previewWorkout
    case creditExtraWork, creditSideHustle, openWorkout
}
enum FamilyActionEffect: String, Codable { case commit, marry, separate, chooseChildfree, planFamily, parent, caregive }
enum HealthActionEffect: String, Codable { case seekCare, therapy, manage, preventive, cutBack }
enum EducationActionEffect: String, Codable {
    case focusGrades, findYourPeople, commitActivity, helpAtHome
    case openCollegeOffers, openRecoveryOffers
}

struct DomainActionEffects: Codable, Equatable {
    var education: EducationActionEffect? = nil
    var career: CareerActionEffect?
    var finance: FinanceActionEffect?
    var family: FamilyActionEffect?
    var health: HealthActionEffect?
}

struct DomainActionResolution: Equatable {
    var deltas = DeltaSummary()
    var headline: String?
    var detail: String?
}

enum CareerOpportunitySystem {
    static func specialEligibilityIssue(in state: LifeState) -> String? {
        guard state.career.careerClass == .normal else { return "Requires a normal career foundation" }
        guard state.career.level == .established || state.career.level == .senior else { return "Requires an established career" }
        guard state.career.performance >= CareerPolicy.specialMinimumPerformance else { return "Requires performance \(CareerPolicy.specialMinimumPerformance)" }
        guard state.stats.rep >= CareerPolicy.specialMinimumReputation else { return "Requires reputation \(CareerPolicy.specialMinimumReputation)" }
        let provenWithoutTalent = state.career.performance >= CareerPolicy.specialProvenPerformance
            && state.stats.rep >= CareerPolicy.specialProvenReputation
        guard state.personality.talent != nil || provenWithoutTalent else { return "Requires a matching talent or an exceptional record" }
        guard state.cash >= 10_000 else { return "Entrepreneurship requires $10,000 in founder capital" }
        return nil
    }

    static func diamondEligibilityIssue(in state: LifeState) -> String? {
        let definition = CareerOpportunityCatalog.diamondDefinition(for: .institutionBuilder)
        for gate in definition.gates {
            switch gate {
            case .specialCareer:
                guard state.career.careerClass == .special else { return "Requires a proven Special career" }
                guard state.career.level == .established || state.career.level == .senior else { return "Requires an established Special career" }
            case .capital(let amount):
                guard state.cash >= amount else { return "Requires $\(amount) in capital" }
            case .reputation(let amount):
                guard state.stats.rep >= amount else { return "Requires reputation \(amount)" }
            case .specialMomentum(let amount):
                guard state.career.specialMomentum >= amount else { return "Requires Special momentum \(amount)" }
            }
        }
        return nil
    }
}

enum CareerSystem {
    static func applyReaction(managerDelta: Int = 0, coworkerDelta: Int = 0, leverageDelta: Int = 0, state: inout LifeState) {
        state.career.workplace.managerRelationship += managerDelta
        state.career.workplace.coworkerStanding += coworkerDelta
        state.career.negotiationLeverage += leverageDelta
        state.career.workplace.clamp()
        state.career.clamp()
    }

    static func applySchoolTransition(_ transition: SchoolCareerTransition, state: inout LifeState) {
        if transition.beginsEntryWork, state.career.level == .unemployed {
            state.career.level = .entry
            state.career.lastTransition = .hired
        }
        state.career.performance += transition.performanceDelta
        state.career.security += transition.securityDelta
        state.career.clamp()
        state.flags.hasJob = state.career.level.isEmployed
    }

    static func resolve(
        _ effect: CareerActionEffect,
        state: inout LifeState,
        world: WorldModifierSnapshot? = nil
    ) -> DomainActionResolution {
        var result = DomainActionResolution()
        switch effect {
        case .chooseOffice: choose(.office, state: &state, result: &result)
        case .chooseTrades: choose(.trades, state: &state, result: &result)
        case .chooseCareService: choose(.careService, state: &state, result: &result)
        case .chooseFreelance: choose(.freelance, state: &state, result: &result)
        case .chooseOfficeAdministrator: choose(.officeAdministrator, state: &state, result: &result)
        case .chooseAccountant: choose(.accountant, state: &state, result: &result)
        case .chooseHumanResourcesSpecialist: choose(.humanResourcesSpecialist, state: &state, result: &result)
        case .chooseSalesRepresentative: choose(.salesRepresentative, state: &state, result: &result)
        case .chooseElectrician: choose(.electrician, state: &state, result: &result)
        case .choosePlumber: choose(.plumber, state: &state, result: &result)
        case .chooseMechanic: choose(.mechanic, state: &state, result: &result)
        case .chooseConstructionWorker: choose(.constructionWorker, state: &state, result: &result)
        case .chooseTeacher: choose(.teacher, state: &state, result: &result)
        case .chooseNurse: choose(.nurse, state: &state, result: &result)
        case .chooseCaregiver: choose(.caregiver, state: &state, result: &result)
        case .chooseRestaurantManager: choose(.restaurantManager, state: &state, result: &result)
        case .chooseDesigner: choose(.designer, state: &state, result: &result)
        case .chooseDeveloper: choose(.developer, state: &state, result: &result)
        case .chooseConsultant: choose(.consultant, state: &state, result: &result)
        case .chooseIndependentContractor: choose(.independentContractor, state: &state, result: &result)
        case .search:
            let policy = world ?? WorldSystem.modifiers(for: state.world)
            let chance = jobSearchChance(state: state, world: policy)
            if state.randomStreams.career.next(in: 1...100) <= chance {
                state.career.level = .entry; state.career.security = 40; state.career.unemploymentDuration = 0; state.career.lastTransition = .hired
                if state.career.occupation == nil {
                    state.career.occupation = CareerCatalog.defaultOccupation(for: state.career.track)
                }
                LifeThreadSystem.stabilize(kind: .layoff, source: .career, amount: 4, state: &state)
                result.headline = "Work Found A Foothold"; result.detail = "You found ordinary work and a little room to build."
            } else {
                state.career.security -= 2
                result.headline = "The Search Did Not Land"
                result.detail = "You did the work of looking. The market still closed the door this time."
            }
        case .pivot:
            state.career.careerClass = .normal
            state.career.specialMomentum = 0
            state.career.legacyLeverage = 0
            state.career.track = .undecided
            state.career.level = .unemployed
            state.career.performance = 35
            state.career.unemploymentDuration = 0
            state.career.lastTransition = .pivoted
            // Cash is owned by the registry effect. Applying it here as well
            // charged the displayed transition cost twice.
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(play: 2, rep: -1), state: &state)
            result.headline = "You Left The Known Career Path"
            result.detail = "The old role is gone. Choose a direction, then convince a workplace to let you begin again."
        case .promote:
            let leadershipBonus = state.personality.talent == .publicLeadership ? 4 : 0
            state.career.performance += 12 + EducationSystem.credentialModifiers(for: state).promotionDelta + leadershipBonus
            state.career.burnout += 6
            state.career.promotionProgress += 18
            let requirements = state.career.occupation.map {
                CareerCatalog.promotionRequirements(for: $0, advancingFrom: state.career.level)
            } ?? CareerCatalog.promotionRequirements(for: .officeAdministrator, advancingFrom: state.career.level)
            let qualified = state.career.performance >= requirements.performance
                && state.career.skill >= requirements.skill
                && state.career.credentialProgress >= requirements.credentialProgress
            if qualified, state.career.level == .entry {
                state.career.level = .established
                state.career.promotionProgress = 0
                state.career.lastTransition = .promoted
                result.headline = "You Earned The Next Title"
                result.detail = "Your record, skill, and preparation carried you into \(state.career.rankTitle)."
            } else if qualified, state.career.level == .established {
                state.career.level = .senior
                state.career.promotionProgress = 0
                state.career.lastTransition = .promoted
                result.headline = "Your Career Moved Up A Tier"
                result.detail = "The next title came with more authority and less room to hide from the work."
            } else {
                result.headline = "The Promotion Is Still A Reach"
                result.detail = "You pushed the case forward, but the record still needs \(promotionGap(for: state.career, requirements: requirements))."
            }
        case .skill:
            state.career.performance += 8 + (state.personality.talent == .entrepreneurial ? 2 : 0)
            state.career.skill += 8
            state.career.promotionProgress += 12
            state.career.credentialProgress += state.education.credential ? 8 : 4
            state.career.security += 5
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(school: 3, cash: -2500), state: &state)
        case .negotiateRaise:
            state.career.negotiationLeverage += 18
            state.career.performance += 3
            state.career.burnout += 4
            result.headline = "You Put A Number On Your Work"
            result.detail = "The conversation did not guarantee a raise, but it made your leverage visible."
        case .overtime:
            FinanceSystem.creditExtra(EconomyPolicy.rate(state.career.annualIncome, 500), state: &state)
            state.career.performance += 4
            state.career.promotionProgress += 8
            state.career.burnout += 10
            state.career.workload += 12
            result.headline = "You Bought Progress With Hours"
            result.detail = "The extra money arrived. So did the extra weight."
        case .professionalNetwork:
            state.career.negotiationLeverage += 12
            state.career.security += 2
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(cash: -500, play: -1, rep: 2), state: &state)
            result.headline = "Your Name Entered More Rooms"
            result.detail = "A professional connection is not a promotion, but it can keep the next door from being invisible."
        case .certification:
            state.career.skill += 10
            state.career.credentialProgress += 20
            state.career.promotionProgress += 10
            state.career.burnout += 2
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(school: 2, cash: -2500), state: &state)
            result.headline = "You Bought A Better Credential"
            result.detail = "The certificate cost time and money. It also made the next title more plausible."
        case .careerLeave:
            state.career.burnout -= 20
            state.career.workload -= 30
            state.career.performance -= 5
            state.career.security -= 4
            LifeThreadSystem.stabilize(kind: .burnout, source: .career, amount: 3, state: &state)
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(play: 3), state: &state)
            result.headline = "You Stepped Away Before Breaking"
            result.detail = "The leave slowed the climb, but it gave your body and the rest of your life some room back."
        case .changeEmployer:
            let employer = nextEmployer(after: state.career.workplace.employer)
            state.career.workplace = workplace(for: employer, track: state.career.track)
            state.career.workplace.yearsAtEmployer = 0
            state.career.workload -= 10
            state.career.burnout -= 5
            state.career.security = min(state.career.security, state.career.workplace.stability)
            state.career.negotiationLeverage = max(0, state.career.negotiationLeverage - 8)
            result.headline = "You Changed Who Signed The Paychecks"
            result.detail = "The occupation stayed the same. The manager, culture, and risks around it did not."
        case .workplaceRelationship:
            state.career.workplace.managerRelationship += 15
            state.career.workplace.coworkerStanding += 8
            state.career.negotiationLeverage += 4
            state.career.burnout += 2
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(play: -1, rep: 1), state: &state)
            result.headline = "You Became Easier To Back"
            result.detail = "A better working relationship does not remove pressure, but it changes who carries it with you."
        case .flexibleSchedule:
            state.career.workplace.flexibility += 20
            state.career.workload -= 10
            state.career.performance -= 2
            state.career.security -= 1
            result.headline = "You Negotiated A Little More Air"
            result.detail = "The schedule opened up. The trade was a little less visibility and a little less momentum."
        case .specializeTechnical:
            state.career.focus = .technicalDepth
            state.career.focusProgress += 20
            state.career.skill += 8
            state.career.performance += 2
            result.headline = "You Chose To Go Deeper"
            result.detail = "You became harder to replace by becoming more specific."
        case .specializeLeadership:
            state.career.focus = .peopleLeadership
            state.career.focusProgress += 20
            state.career.workplace.managerRelationship += 5
            state.career.mentorship += 8
            state.career.performance += 2
            state.career.workload += 4
            result.headline = "You Chose To Carry More People"
            result.detail = "Leadership widened your influence and your responsibility at the same time."
        case .specializeClientTrust:
            state.career.focus = .clientTrust
            state.career.focusProgress += 20
            state.career.careerReputation += 8
            state.career.negotiationLeverage += 5
            state.career.workload += 2
            result.headline = "You Made Trust The Product"
            result.detail = "Your name started doing some of the work before you arrived."
        case .negotiateBenefits:
            state.career.benefits += 15
            state.career.paidLeaveDays += 5
            state.career.negotiationLeverage -= 3
            result.headline = "You Negotiated The Rest Of The Offer"
            result.detail = "Compensation is more than salary. The safer terms still had a cost."
        case .usePaidLeave:
            guard state.career.paidLeaveDays >= 5 else { break }
            state.career.paidLeaveDays -= 5
            state.career.burnout -= 12
            state.career.workload -= 12
            state.career.performance -= 1
            result.headline = "You Used The Time You Earned"
            result.detail = "The job kept moving. You returned with more of yourself available."
        case .mentorCoworker:
            state.career.mentorship += 15
            state.career.careerReputation += 5
            state.career.referenceStrength += 4
            state.career.workload += 3
            result.headline = "You Left Someone Better Equipped"
            result.detail = "The work mattered beyond your own title, even if it added to your week."
        case .prepareRetirement:
            state.career.retirementReadiness += 20
            state.career.workload -= 10
            state.career.performance -= 3
            state.career.security += 2
            result.headline = "You Started Making An Exit Plan"
            result.detail = "Retirement became a transition to prepare for, not a cliff to fall off."
        case .buildCareerPortfolio:
            state.career.careerReputation += 12
            state.career.skill += 4
            state.career.performance += 2
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(cash: -250, play: -1, rep: 2), state: &state)
            result.headline = "Your Work Became Portable"
            result.detail = "You documented what you can do. A career is safer when its proof can leave the building with you."
        case .requestReference:
            state.career.referenceStrength += 18
            state.career.careerReputation += 4
            state.career.workplace.managerRelationship -= 1
            result.headline = "You Asked Someone To Vouch"
            result.detail = "A reference turns private effort into a claim another person is willing to make out loud."
        case .testJobMarket:
            state.career.negotiationLeverage += 10
            state.career.careerReputation += 6
            state.career.security += 4
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(play: -1), state: &state)
            result.headline = "You Checked What Else Was Out There"
            result.detail = "You did not have to leave. Knowing your options changed how trapped the current job felt."
        case .boundaries:
            state.career.burnout -= 14
            state.career.workload -= 15
            state.career.performance -= 3
            LifeThreadSystem.stabilize(kind: .burnout, source: .career, amount: 2, state: &state)
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(play: 4), state: &state)
        case .partTime:
            state.career.careerClass = .partTime
            state.career.specialCareerID = nil
            state.career.diamondCareerID = nil
            state.career.level = .entry
            state.career.performance = max(35, state.career.performance - 8)
            state.career.security = 42
            state.career.burnout -= 10
            state.career.lastTransition = .pivoted
            result.headline = "You Chose A Smaller Workweek"
            result.detail = "The pay narrowed with the hours. The rest of your life gained room."
        case .enterSpecial:
            guard CareerOpportunitySystem.specialEligibilityIssue(in: state) == nil else { break }
            state.career.careerClass = .special
            state.career.specialCareerID = .entrepreneurship
            _ = FinanceSystem.transact(.init(amount: -10_000, purpose: .optionalPurchase), state: &state)
            state.career.venture = VentureState(seed: state.runSeed ^ UInt64(state.character.age))
            state.career.diamondCareerID = nil
            state.career.specialMomentum = 15
            state.career.security = min(state.career.security, 40)
            state.career.burnout += 8
            result.headline = "Your Career Became The Arena"
            result.detail = "Talent and record earned entry. Results still decide whether the opening lasts."
        case .enterDiamond:
            // The registry commits the required capital before domain effects
            // resolve, so only re-check the career record here. Availability
            // already verifies the pre-action cash balance.
            guard CareerOpportunitySystem.diamondEligibilityIssue(in: state) == nil else { break }
            state.career.careerClass = .diamond
            state.career.diamondCareerID = .institutionBuilder
            state.career.legacyLeverage = 10
            state.career.burnout += 15
            result.headline = "You Began Building An Institution"
            result.detail = "This is no longer only a job. Capital, reputation, and the life around the work are now at risk."
        }
        state.career.clamp()
        state.flags.hasJob = state.career.level.isEmployed
        return result
    }

    static func jobSearchChance(state: LifeState, world: WorldModifierSnapshot) -> Int {
        let school = EducationSystem.legacyModifiers(for: state)
        let credential = EducationSystem.credentialModifiers(for: state)
        let educationPressure = YearContext(state: state, world: world).pressure(on: .career, from: .education)
        return min(90, max(20, 65 + state.career.performance / 10 + world.hiringModifier
            + school.jobSearchChanceDelta + school.opportunityAccess + credential.jobSearchDelta(for: state.career.track)
            + TalentSystem.careerChanceBonus(state: state) - min(8, educationPressure)))
    }

    static func resolveYear(
        state: inout LifeState,
        world: WorldModifierSnapshot? = nil
    ) -> SystemYearDeltas {
        var result = SystemYearDeltas()
        let policy = world ?? WorldSystem.modifiers(for: state.world)
        let legalPressure = YearContext(state: state, world: policy).pressure(on: .career, from: .legal)
        let illnessPressure = YearContext(state: state, world: policy).pressure(on: .career, from: .health)
        let familyPressure = YearContext(state: state, world: policy).pressure(on: .career, from: .family)
        if state.lifeStage == .legacy, state.career.level.isEmployed {
            state.career.level = .retired
            state.career.lastTransition = .retired
            state.flags.hasJob = false
            result.bullets.append("Retired")
            result.milestoneHeadline = "You Retired From The Daily Grind"
            result.milestoneDetail = "The badge comes off. Income thins. The calendar finally has holes in it."
            state.career.clamp()
            let crime = CrimeSystem.resolveYear(state: &state)
            result.deltas = result.deltas + crime.deltas
            result.bullets += crime.bullets
            result.notes += crime.notes
            result.consequences += crime.consequences
            return result
        }
        if state.career.level.isEmployed {
            state.career.tenure += 1; state.career.performance -= 2
            state.career.skill += state.career.performance >= 55 ? 2 : 1
            state.career.promotionProgress += max(1, state.career.performance / 12)
            state.career.workplace.yearsAtEmployer += 1
            state.career.workplace.managerRelationship -= state.career.workplace.culture == .political ? 1 : 0
            state.career.workplace.coworkerStanding += state.career.workplace.culture == .supportive ? 1 : 0
            state.career.careerReputation += state.career.workplace.coworkerStanding >= 70 ? 1 : 0
            state.career.focusProgress += state.career.focus == nil ? 0 : 4
            state.career.paidLeaveDays = min(40, state.career.paidLeaveDays + 2)
            state.career.retirementReadiness += state.character.age >= 50 ? 2 : 0
            state.career.workload += max(1, 4 - state.career.workplace.flexibility / 25)
            state.career.security += (state.career.workplace.stability - 50) / 20
            if legalPressure > 0 {
                state.career.security -= min(6, legalPressure)
                result.notes.append("Your legal record narrowed your footing at work.")
            }
            if illnessPressure > 0 {
                state.career.performance -= min(4, max(1, illnessPressure / 2))
                result.notes.append("Illness reduced the capacity available for work.")
            }
            if familyPressure > 0 {
                state.career.performance -= min(3, max(1, familyPressure / 2))
                result.notes.append("Care responsibilities narrowed your work margin.")
            }
            state.aggregates.yearsWorked += 1
            state.career.security += policy.securityDrift
            let burnout: Int = switch state.career.track { case .office: 4; case .trades: 3; case .careService: 5; case .freelance: 2; case .undecided: 2 }
            state.career.burnout += burnout
            switch state.career.careerClass {
            case .normal:
                break
            case .partTime:
                state.career.burnout -= 4
                state.career.performance -= 1
                result.bullets.append("Part-time work left room outside the job")
            case .special:
                let landed = state.randomStreams.career.next(in: 1...100) <= max(25, state.career.performance)
                state.career.specialMomentum += landed ? 8 : -6
                state.career.security += landed ? 1 : -4
                state.career.burnout += 4
                result.deltas.rep += landed ? 2 : -1
                result.bullets.append(landed ? "Special career momentum grew" : "Special career momentum slipped")
            case .diamond:
                let held = state.randomStreams.career.next(in: 1...100) <= max(20, state.career.performance - state.career.burnout / 4)
                state.career.legacyLeverage += held ? 7 : -9
                state.career.security += held ? 1 : -7
                state.career.burnout += 7
                result.deltas.rep += held ? 3 : -4
                result.bullets.append(held ? "The institution gained leverage" : "The institution absorbed a public setback")
            }
            if state.career.track == .trades { result.deltas.health -= 2 }
            if state.career.track == .careService { result.deltas.love += 1; result.deltas.rep += 1 }
            if state.career.track == .freelance { state.career.security -= 4 }
            if state.career.burnout >= 75 {
                result.consequences.append(contentsOf: [
                    DomainConsequence(
                        source: .career, target: .health, kind: .burnout, magnitude: .major,
                        openedAge: state.character.age, yearsRemaining: 3,
                        headline: "Work is consuming your recovery",
                        detail: "Sustained burnout is wearing down your health until work changes or you protect some margin."
                    ),
                    DomainConsequence(
                        source: .career, target: .relationships, kind: .burnout, magnitude: .minor,
                        openedAge: state.character.age, yearsRemaining: 3,
                        headline: "Work keeps arriving home",
                        detail: "The hours and exhaustion are reducing what remains for the people closest to you."
                    )
                ])
                result.notes.append("Burnout followed you home.")
            }
            if state.lifeStage == .pressure, state.career.level != .entry, state.character.age % 7 == 0 {
                result.bullets.append("Career plateau pressure")
                result.deltas.play -= 1
                result.deltas.rep += state.stats.rep >= 70 ? 0 : 1
            }
            let baseRisk = max(0, 6 - state.career.security / 20)
                + max(0, 5 - state.career.workplace.stability / 20)
                + (state.career.track == .freelance ? 4 : 0)
            let layoffRisk = min(35, max(0, Int((Double(baseRisk) * policy.layoffRiskMultiplier).rounded())))
            if state.character.age >= 30, state.career.tenure >= 3, state.randomStreams.career.next(in: 1...100) <= layoffRisk {
                state.career.level = .unemployed; state.career.lastTransition = .laidOff; state.career.unemploymentDuration = 1
                result.consequences.append(DomainConsequence(
                    source: .career, target: .finance, kind: .layoff, magnitude: .major,
                    openedAge: state.character.age, yearsRemaining: 3,
                    headline: "The layoff still shapes your choices",
                    detail: "Lost income raises household pressure until work or savings restore your footing."
                ))
                result.bullets.append("Laid off"); result.deltas.love -= 2; result.deltas.rep -= 2
                result.milestoneHeadline = "The Job Let You Go"
                result.milestoneDetail = "A quiet meeting. A thinner account. The market did not ask how hard you tried."
            }
        } else if state.career.level == .unemployed { state.career.unemploymentDuration += 1 }
        let situation = CareerSituationSystem.resolveYear(state: &state)
        result.bullets += situation.bullets
        result.consequences += situation.consequences
        if let headline = situation.milestoneHeadline {
            result.milestoneHeadline = headline
            result.milestoneDetail = situation.milestoneDetail
        }
        let crime = CrimeSystem.resolveYear(state: &state)
        result.deltas = result.deltas + crime.deltas
        result.bullets += crime.bullets
        result.notes += crime.notes
        result.consequences += crime.consequences
        state.career.clamp(); return result
    }

    private static func choose(_ track: CareerTrack, state: inout LifeState, result: inout DomainActionResolution) {
        if state.legal.isFelon && (track == .office || track == .careService) {
            result.headline = "The Record Closed That Door"
            result.detail = "A felony conviction blocks this high-trust career category. Other work remains available."
            return
        }
        let needsJobSearch = state.career.level == .unemployed
        state.career.careerClass = .normal
        state.career.track = track
        state.career.occupation = nil
        state.career.workplace = WorkplaceState.starting(for: track)
        state.career.security = track == .trades ? 68 : (track == .freelance ? 28 : 50)
        if needsJobSearch {
            result.headline = "\(track.title) Became The Next Direction"
            result.detail = "The direction is real. A job still has to say yes."
        } else {
            state.career.lastTransition = .hired
            result.headline = "You Chose \(track.title) Work"
            result.detail = "The path gives you a direction, not a guarantee."
        }
    }

    private static func choose(
        _ occupation: CareerOccupation,
        state: inout LifeState,
        result: inout DomainActionResolution
    ) {
        guard state.career.track == occupation.track else { return }
        state.career.careerClass = .normal
        state.career.occupation = occupation
        state.career.workplace = WorkplaceState.starting(for: occupation.track)
        if state.education.credential {
            state.career.credentialProgress = max(state.career.credentialProgress, 35)
        }
        result.headline = "You Chose \(occupation.title)"
        result.detail = "The broad direction became a real occupation. The work still has to prove itself over time."
    }

    private static func promotionGap(for career: CareerState, requirements: CareerPromotionRequirements) -> String {
        var gaps: [String] = []
        if career.performance < requirements.performance { gaps.append("performance") }
        if career.skill < requirements.skill { gaps.append("skill") }
        if career.credentialProgress < requirements.credentialProgress { gaps.append("credentials") }
        return gaps.isEmpty ? "time" : gaps.joined(separator: ", ")
    }

    private static func nextEmployer(after current: EmployerType) -> EmployerType {
        let choices = EmployerType.allCases
        guard let index = choices.firstIndex(of: current) else { return choices[0] }
        return choices[(index + 1) % choices.count]
    }

    private static func workplace(for employer: EmployerType, track: CareerTrack) -> WorkplaceState {
        let culture: WorkplaceCulture = switch employer {
        case .smallBusiness: .demanding
        case .corporation: .political
        case .government: .transactional
        case .hospital: .demanding
        case .school: .missionDriven
        case .nonprofit: .missionDriven
        case .unionWorkplace: .supportive
        case .selfEmployed: .unstable
        }
        let stability: Int = switch employer {
        case .smallBusiness: 48
        case .corporation: 52
        case .government: 72
        case .hospital: 62
        case .school: 65
        case .nonprofit: 44
        case .unionWorkplace: 74
        case .selfEmployed: 30
        }
        let flexibility: Int = employer == .selfEmployed ? 80 : (track == .freelance ? 55 : 25)
        return WorkplaceState(employer: employer, culture: culture, flexibility: flexibility, stability: stability)
    }
}

enum HouseholdFinanceSystem {
    static func resolve(_ effect: FinanceActionEffect, state: inout LifeState) -> DomainActionResolution {
        var result = DomainActionResolution()
        switch effect {
        case .previewWorkout, .openWorkout: break
        case .creditExtraWork:
            let gross = EconomyPolicy.rate(EconomyPolicy.salary(state.career), 500)
            FinanceSystem.creditExtra(ActionCadenceSystem.adjustedIncome(gross, for: .workShift, state: &state), state: &state)
        case .creditSideHustle:
            let gross = state.randomStreams.finance.next(in: 1_500...4_000)
            FinanceSystem.creditExtra(ActionCadenceSystem.adjustedIncome(gross, for: .sideHustle, state: &state), state: &state)
        case .budget:
            state.finance.financialStress -= 6
            LifeThreadSystem.stabilize(kind: .debt, amount: 1, state: &state)
            state.finance.economy.budgetAge = state.character.age
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(play: -1), state: &state)
            result.detail = "Discretionary spending is limited to $600 for this year. No cash is created."
        case .payDebt:
            _ = FinanceSystem.transact(.init(amount: -10_000, purpose: .debtPayment), state: &state)
            state.finance.financialStress -= 5
            LifeThreadSystem.stabilize(kind: .debt, amount: 2, state: &state)
        case .retirement: state.finance.retirementContributionPercent = (state.finance.retirementContributionPercent + 5) % 20
        case .buyHome:
            if let transaction = AssetSystem.purchase(listingID: "house-starter-condo", state: &state) {
                result.headline = transaction.headline
                result.detail = transaction.detail
            }
        case .sellOrDownsize:
            if let primary = state.assets.primaryProperty,
               let transaction = AssetSystem.sell(ownershipID: primary.id, state: &state) {
                state.finance.financialStress -= 8
                result.headline = transaction.headline
                result.detail = transaction.detail
            }
        }
        state.finance.clamp()
        if state.cash < 0 { state.finance.consumerDebt = EconomyPolicy.checkedAdd(state.finance.consumerDebt, -state.cash); state.cash = 0 }
        return result
    }
}

enum FamilySystem {
    static func applyReactionBond(_ delta: Int, contactID: String, state: inout LifeState) {
        guard let index = state.family.contacts.firstIndex(where: { $0.id == contactID }) else { return }
        state.family.contacts[index].bond += delta
        state.family.clamp()
    }

    static func resolve(_ effect: FamilyActionEffect, state: inout LifeState) -> DomainActionResolution {
        var result = DomainActionResolution()
        switch effect {
        case .commit: state.partner?.stage = .committed; state.partner?.committed = true; state.partner?.bond += 6
        case .marry: state.partner?.stage = .married; state.partner?.committed = true; state.partner?.bond += 8; _ = FinanceSystem.transact(.init(amount: -8_000, purpose: .household), state: &state)
        case .separate:
            RelationshipSystem.endCurrent(.playerSeparated, state: &state)
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(cash: -12000, love: -8), state: &state)
            result.headline = "You Ended The Shared Future"
            result.detail = "The relationship is over. The years it shaped still belong to this life."
        case .chooseChildfree:
            state.family.intention = .childfree
            result.headline = "You Chose A Childfree Life"
            result.detail = "The choice is deliberate, not an absence the game will score against you."
        case .planFamily:
            if state.family.intention == .childfree { state.family.intention = .openToChildren }
            else if state.family.intention == .openToChildren { state.family.intention = .buildingFamily }
            else if state.family.children.count < 6 {
                let names = ["Alex", "Sam", "River", "Jamie"]
                let temperament = ChildTemperament.allCases[state.randomStreams.family.next(in: 0...(ChildTemperament.allCases.count - 1))]
                state.family.children.append(ChildState(lineageIndex: state.family.children.count, name: names[state.family.children.count % names.count], temperament: temperament))
                state.family.intention = .openToChildren; _ = FinanceSystem.transact(.init(amount: -9_000, purpose: .household), state: &state)
            }
        case .parent:
            for index in state.family.children.indices where state.family.children[index].dependent {
                state.family.children[index].bond += 7
            }
            LifeThreadSystem.stabilize(kind: .illness, target: .family, amount: 1, state: &state)
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(love: 4, play: -2), state: &state)
        case .caregive:
            if state.family.contacts.isEmpty {
                let names = ["Robin", "Dana", "Lee", "Ari"]
                let name = names[state.randomStreams.family.next(in: 0...(names.count - 1))]
                let personality = PersonalitySystem.generated(random: &state.randomStreams.family)
                state.family.contacts.append(FamilyContact(
                    name: name,
                    role: .relative,
                    lastResolvedAge: state.character.age,
                    personality: personality
                ))
            }
            if !state.family.contacts.isEmpty {
                state.family.contacts[0].bond += 5
                state.family.contacts[0].lastResolvedAge = state.character.age
                result.headline = "Care Became Part Of The Week"
                result.detail = "\(state.family.contacts[0].name) needed real help. Love gained weight and the calendar lost room."
            }
            state.family.caregivingLoad += 8
            LifeThreadSystem.stabilize(kind: .illness, target: .family, amount: 1, state: &state)
            result.deltas = EffectResolutionSystem.apply(DeltaSummary(cash: -3000, love: 3, health: -2), state: &state)
        }
        state.partner?.clamp()
        state.family.clamp()
        state.flags.hasPartner = state.partner != nil
        if state.cash < 0 { state.finance.consumerDebt = EconomyPolicy.checkedAdd(state.finance.consumerDebt, -state.cash); state.cash = 0 }
        return result
    }

    static func resolveYear(state: inout LifeState) -> SystemYearDeltas {
        var result = SystemYearDeltas()
        guard state.partner != nil || !state.family.children.isEmpty || !state.family.contacts.isEmpty || state.family.caregivingLoad > 0 else { return result }
        let householdPressure = LifeThreadSystem.pressure(on: .relationships, state: state)
        let illnessPressure = LifeThreadSystem.pressure(on: .family, state: state)
        if householdPressure > 0 {
            result.deltas.love -= min(3, max(1, householdPressure / 3))
            state.partner?.resentment += min(3, max(1, householdPressure / 4))
            result.notes.append("Money pressure followed the household into its relationships.")
        }
        if illnessPressure > 0 {
            state.family.caregivingLoad += min(3, max(1, illnessPressure / 2))
            result.deltas.play -= min(2, max(1, illnessPressure / 3))
            result.notes.append("Illness shifted more care into the household.")
        }
        for index in state.family.children.indices {
            let wasDependent = state.family.children[index].dependent
            let livedAtHome = state.family.children[index].livesAtHome
            state.family.children[index].age += 1
            if state.family.children[index].age >= 18 {
                state.family.children[index].dependent = false
                if state.family.children[index].age >= 22 { state.family.children[index].livesAtHome = false }
                if state.family.children[index].adultOutcome == nil {
                    let bond = state.family.children[index].bond
                    state.family.children[index].adultOutcome = bond >= 65 ? .independent : (bond >= 40 ? .findingFooting : .needsSupport)
                }
            }
            if wasDependent, !state.family.children[index].dependent, let outcome = state.family.children[index].adultOutcome {
                result.bullets.append("\(state.family.children[index].name) reached adulthood · \(outcome.rawValue)")
            }
            if livedAtHome, !state.family.children[index].livesAtHome {
                result.bullets.append("\(state.family.children[index].name) moved out")
            }
        }
        let activeCareThisYear = state.family.contacts.contains { $0.lastResolvedAge >= state.character.age - 1 }
        if state.family.caregivingLoad > 0, !activeCareThisYear, illnessPressure == 0 {
            let before = state.family.caregivingLoad
            state.family.caregivingLoad = max(0, before - 8)
            if state.family.caregivingLoad == 0 {
                result.bullets.append("The caregiving season eased")
            }
        }
        let load = state.family.dependentLoad
        if load > 0 {
            // Finance owns the annual dependent cost in its ledger. Family owns
            // the time pressure and milestones; charging cash here duplicated it.
            result.deltas.play -= min(3, load)
            result.bullets.append("Dependents \(load)")
        }
        if state.family.caregivingLoad >= 60 {
            result.consequences.append(contentsOf: [
                DomainConsequence(
                    source: .family, target: .health, kind: .familyConflict, magnitude: .major,
                    openedAge: state.character.age, yearsRemaining: 3,
                    headline: "Caregiving is consuming your margin",
                    detail: "Family loyalty is now competing with rest, work, and your own care."
                ),
                DomainConsequence(
                    source: .family, target: .career, kind: .familyConflict, magnitude: .minor,
                    openedAge: state.character.age, yearsRemaining: 3,
                    headline: "Care is competing with work",
                    detail: "Unpredictable care responsibilities are reducing the attention available to your job."
                ),
                DomainConsequence(
                    source: .family, target: .finance, kind: .familyConflict, magnitude: .minor,
                    openedAge: state.character.age, yearsRemaining: 3,
                    headline: "Care is consuming household margin",
                    detail: "The care season is adding ordinary costs and reducing room for financial recovery."
                )
            ])
        }
        state.family.clamp(); return result
    }
}

enum ConditionHealthSystem {
    private struct ProfessionalCarePlan {
        var cost: ClosedRange<Int>
        var effectiveness: ClosedRange<Int>
        var effectLabel: String
    }

    static func discoverIfNeeded(
        state: inout LifeState,
        world: WorldModifierSnapshot? = nil
    ) -> DomainConsequence? {
        guard state.health.conditions.count < 3 else { return nil }
        let candidate: ConditionKind?
        if state.health.addictionPressure >= 55 { candidate = .addiction }
        else if state.career.burnout >= 75 && state.health.mentalWellbeing < 55 { candidate = .depression }
        else if state.career.track == .trades && state.character.age >= 38 && state.health.bodyLoad >= 25 { candidate = .chronicPain }
        else if state.character.age >= 52 && state.health.physicalWellbeing < 55 { candidate = .cardiovascularStrain }
        else if state.character.age >= 60 && state.health.bodyLoad >= 45 { candidate = .metabolicIllness }
        else { candidate = nil }
        guard let candidate, !state.health.conditions.contains(where: { $0.kind == candidate }) else { return nil }
        let policy = world ?? WorldSystem.modifiers(for: state.world)
        let discoveryChance = min(60, max(20, 35 + policy.conditionDiscoveryModifier))
        if state.randomStreams.health.next(in: 1...100) <= discoveryChance {
            state.health.conditions.append(ChronicCondition(kind: candidate, severity: 28, management: 0))
            return DomainConsequence(
                source: .health, target: .health, kind: .illness, magnitude: .major,
                openedAge: state.character.age, yearsRemaining: 4,
                headline: "A condition now needs management",
                detail: "Care can stabilize the condition; neglect lets it compound into the rest of your life."
            )
        }
        return nil
    }
    static func resolve(
        _ effect: HealthActionEffect,
        state: inout LifeState,
        world: WorldModifierSnapshot? = nil
    ) -> DomainActionResolution {
        var result = DomainActionResolution()
        let policy = world ?? WorldSystem.modifiers(for: state.world)
        switch effect {
        case .cutBack:
            state.health.addictionPressure -= 15
            state.health.mentalWellbeing += 4
            state.health.bodyLoad -= 4
        case .seekCare, .therapy, .manage, .preventive:
            let plan = adjustedPlan(for: effect, state: state, world: policy)
            let cost = state.randomStreams.health.next(in: plan.cost)
            let effectiveness = state.randomStreams.health.next(in: plan.effectiveness)
            _ = FinanceSystem.transact(.init(amount: -cost, purpose: .medical), state: &state)
            switch effect {
            case .seekCare:
                state.health.physicalWellbeing += effectiveness
                state.health.mentalWellbeing += effectiveness
                state.health.bodyLoad -= max(1, effectiveness / 3)
                LifeThreadSystem.stabilize(kind: .illness, target: .health, amount: 2, state: &state)
                LifeThreadSystem.stabilize(kind: .burnout, target: .health, amount: 1, state: &state)
                LifeThreadSystem.stabilize(kind: .debt, target: .health, amount: 1, state: &state)
                result.headline = "Professional Care Made Room"
            case .therapy:
                state.health.mentalWellbeing += effectiveness
                state.health.bodyLoad -= max(1, effectiveness / 3)
                LifeThreadSystem.stabilize(kind: .burnout, target: .health, amount: 2, state: &state)
                LifeThreadSystem.stabilize(kind: .debt, target: .health, amount: 1, state: &state)
                result.headline = "Support Lightened The Load"
            case .manage:
                for index in state.health.conditions.indices {
                    state.health.conditions[index].management += effectiveness
                    state.health.conditions[index].severity -= max(1, effectiveness / 3)
                    if state.health.conditions[index].severity <= 12,
                       state.health.conditions[index].management >= 20 {
                        state.health.conditions[index].status = .stable
                    }
                }
                LifeThreadSystem.stabilize(kind: .illness, amount: 2, state: &state)
                result.headline = "Care Made The Condition Manageable"
            case .preventive:
                state.health.physicalWellbeing += effectiveness
                state.health.bodyLoad -= max(1, effectiveness - 1)
                result.headline = "Prevention Bought You Margin"
            case .cutBack:
                break
            }
            result.detail = "Professional care cost $\(cost) under the access available to you."
        }
        state.health.clamp(); state.syncHealthCompatibility(); return result
    }

    static func resolveYear(
        state: inout LifeState,
        world: WorldModifierSnapshot? = nil
    ) -> SystemYearDeltas {
        var result = SystemYearDeltas()
        guard !state.health.conditions.isEmpty || state.health.addictionPressure >= 40 else { return result }
        let healthBefore = state.health.overall
        for index in state.health.conditions.indices {
            if state.health.conditions[index].status == .stable {
                state.health.bodyLoad -= 1
                state.health.conditions[index].management = max(0, state.health.conditions[index].management - 4)
                if state.health.conditions[index].management < 12 {
                    state.health.conditions[index].status = .active
                    state.health.conditions[index].severity = max(18, state.health.conditions[index].severity + 6)
                    let kind = state.health.conditions[index].kind.title
                    result.bullets.append("\(kind) became active again")
                    result.consequences.append(DomainConsequence(
                        source: .health, target: .health, kind: .illness, magnitude: .minor,
                        openedAge: state.character.age, yearsRemaining: 2,
                        headline: "A managed condition returned",
                        detail: "The condition needs renewed attention before it compounds."
                    ))
                }
            } else {
                let unmanaged = max(0, state.health.conditions[index].severity - state.health.conditions[index].management)
                state.health.bodyLoad += max(1, unmanaged / 18)
                state.health.conditions[index].management = max(0, state.health.conditions[index].management - 4)
            }
        }
        if state.health.addictionPressure >= 60 {
            state.health.mentalWellbeing -= 3
            result.medicalImpact = MedicalFinanceImpact(
                requestedDebtCharge: 1500,
                reason: "Untreated addiction-related care"
            )
        }
        state.health.clamp()
        state.syncHealthCompatibility()
        result.deltas.health = state.health.overall - healthBefore
        let activeCount = state.health.conditions.filter { $0.status == .active }.count
        let stableCount = state.health.conditions.count - activeCount
        if activeCount > 0 { result.bullets.append("Active conditions \(activeCount)") }
        if stableCount > 0 { result.bullets.append("Stable conditions \(stableCount)") }
        return result
    }

    static func professionalCareLockReason(
        effect: HealthActionEffect,
        state: LifeState,
        world: WorldModifierSnapshot
    ) -> String? {
        nil // Necessary care can leave an explicit medical balance.
    }

    static func professionalCarePreview(
        effect: HealthActionEffect,
        state: LifeState,
        world: WorldModifierSnapshot
    ) -> [String] {
        guard effect != .cutBack else { return [] }
        let plan = adjustedPlan(for: effect, state: state, world: world)
        return [
            "Projected care cost $\(rangeText(plan.cost))",
            "Projected \(plan.effectLabel) +\(rangeText(plan.effectiveness))"
        ]
    }

    private static func adjustedPlan(
        for effect: HealthActionEffect,
        state: LifeState,
        world: WorldModifierSnapshot
    ) -> ProfessionalCarePlan {
        let base: ProfessionalCarePlan = switch effect {
        case .seekCare: .init(cost: 4_000...6_000, effectiveness: 7...11, effectLabel: "health")
        case .therapy: .init(cost: 4_500...4_500, effectiveness: 10...10, effectLabel: "mental health")
        case .manage: .init(cost: 5_000...5_000, effectiveness: 12...12, effectLabel: "management")
        case .preventive: .init(cost: 3_500...3_500, effectiveness: 7...7, effectLabel: "physical health")
        case .cutBack: .init(cost: 0...0, effectiveness: 0...0, effectLabel: "health")
        }
        let personalCost: Double = switch state.health.careAccess {
        case .limited: 1.15
        case .basic: 1.0
        case .reliable: 0.90
        }
        let personalEffect: Double = switch state.health.careAccess {
        case .limited: 0.90
        case .basic: 1.0
        case .reliable: 1.10
        }
        let costMultiplier = min(1.35, max(0.85, world.careCostMultiplier * personalCost))
        let effectMultiplier = min(1.15, max(0.75, world.careEffectivenessMultiplier * personalEffect))
        return ProfessionalCarePlan(
            cost: scaled(base.cost, by: costMultiplier, minimum: 0),
            effectiveness: scaled(base.effectiveness, by: effectMultiplier, minimum: effect == .cutBack ? 0 : 1),
            effectLabel: base.effectLabel
        )
    }

    private static func scaled(_ range: ClosedRange<Int>, by multiplier: Double, minimum: Int) -> ClosedRange<Int> {
        let lower = max(minimum, Int((Double(range.lowerBound) * multiplier).rounded()))
        let upper = max(lower, Int((Double(range.upperBound) * multiplier).rounded()))
        return lower...upper
    }

    private static func rangeText(_ range: ClosedRange<Int>) -> String {
        range.lowerBound == range.upperBound ? "\(range.lowerBound)" : "\(range.lowerBound)–\(range.upperBound)"
    }
}

enum LifeThreadSystem {
    static func open(_ consequences: [DomainConsequence], state: inout LifeState) {
        for consequence in consequences {
            if let index = state.lifeThreads.firstIndex(where: {
                $0.kind == consequence.kind && $0.source == consequence.source && $0.target == consequence.target
            }) {
                state.lifeThreads[index].intensity = max(state.lifeThreads[index].intensity, consequence.magnitude.defaultIntensity)
                state.lifeThreads[index].yearsRemaining = max(state.lifeThreads[index].yearsRemaining, consequence.yearsRemaining)
                state.lifeThreads[index].headline = consequence.headline
                state.lifeThreads[index].detail = consequence.detail
                state.lifeThreads[index].resolution = .open
            } else {
                state.lifeThreads.insert(consequence.asThread(), at: 0)
            }
        }
        state.lifeThreads.sort {
            if $0.intensity == $1.intensity { return $0.openedAge > $1.openedAge }
            return $0.intensity > $1.intensity
        }
        state.lifeThreads = Array(state.lifeThreads.prefix(3))
    }

    static func stabilize(
        kind: LifeThreadKind,
        source: ConsequenceDomain? = nil,
        target: ConsequenceDomain? = nil,
        amount: Int,
        state: inout LifeState
    ) {
        guard amount > 0 else { return }
        for index in state.lifeThreads.indices where state.lifeThreads[index].kind == kind
            && (source == nil || state.lifeThreads[index].source == source)
            && (target == nil || state.lifeThreads[index].target == target) {
            state.lifeThreads[index].intensity = max(0, state.lifeThreads[index].intensity - amount)
            state.lifeThreads[index].resolution = state.lifeThreads[index].intensity == 0 ? .resolved : .stabilizing
        }
        state.lifeThreads.removeAll { $0.resolution == .resolved }
    }

    static func pressure(on domain: ConsequenceDomain, state: LifeState) -> Int {
        YearContext(state: state).pressure(on: domain)
    }

    static func resolveYear(state: inout LifeState) -> SystemYearDeltas {
        var result = SystemYearDeltas()
        for index in state.lifeThreads.indices where state.lifeThreads[index].openedAge < state.character.age
            && state.lifeThreads[index].resolution != .permanent {
            state.lifeThreads[index].yearsRemaining -= 1
            if state.lifeThreads[index].resolution == .stabilizing {
                state.lifeThreads[index].intensity = max(0, state.lifeThreads[index].intensity - 1)
            }
        }
        state.lifeThreads.removeAll {
            $0.resolution == .resolved
                || ($0.resolution != .permanent && ($0.yearsRemaining <= 0 || $0.intensity <= 0))
        }
        state.lifeThreads = Array(state.lifeThreads.prefix(3))
        if !state.lifeThreads.isEmpty { result.bullets.append("\(state.lifeThreads.count) unresolved thread\(state.lifeThreads.count == 1 ? "" : "s")") }
        return result
    }
}

// MARK: - Collision storylets (six per expanded domain phase)

enum EssentialStoryletRegistry {
    static let all: [LifeEvent] = career + finance + family + health

    private static let career: [LifeEvent] = [
        event("career-bad-manager", "Your Manager Moves Every Goalpost", "The target changes after you hit it.", weight: { $0.career.level.isEmployed && $0.career.security < 55 ? 5 : 0 }, accept: EffectRange(cash: 2000...3500, health: -4 ... -2, rep: 1...2), decline: EffectRange(play: 2...4, rep: -2 ... -1)),
        event("career-promotion-window", "A Promotion Window Opens Briefly", "The role is real; so is the extra load.", weight: { ($0.career.level == .entry || $0.career.level == .established) && $0.career.performance >= 60 ? 5 : 0 }, accept: EffectRange(cash: 4500...7500, health: -3 ... -1, rep: 2...4), decline: EffectRange(play: 2...4)),
        event("career-burnout-denial", "Burnout Stops Staying Quiet", "Sleep no longer repairs the week.", weight: { $0.career.burnout >= 65 ? 7 : 0 }, accept: EffectRange(cash: -3500 ... -2000, play: 3...5, health: 5...8), decline: EffectRange(cash: 3000...5500, health: -6 ... -4)),
        event("career-trade-body", "The Trade Reaches Your Body", "Reliable work leaves an unreliable ache.", weight: { $0.career.track == .trades && $0.character.age >= 38 ? 5 : 0 }, accept: EffectRange(cash: -4000 ... -2500, health: 4...7), decline: EffectRange(cash: 3500...5500, health: -5 ... -3)),
        event("career-care-compassion", "Compassion Fatigue Follows You Home", "Everyone needed something before you clocked out.", weight: { $0.career.track == .careService && $0.career.burnout >= 45 ? 5 : 0 }, accept: EffectRange(play: 3...5, health: 2...4), decline: EffectRange(cash: 2000...3500, love: -4 ... -2)),
        event("career-freelance-dry", "The Freelance Calendar Goes Quiet", "Three clients postpone in the same afternoon.", weight: { $0.career.track == .freelance ? 4 : 0 }, accept: EffectRange(cash: -4500 ... -2500, play: 2...3), decline: EffectRange(cash: 3500...6500, health: -4 ... -2))
    ]

    private static let finance: [LifeEvent] = [
        event("finance-interest", "Interest Eats Another Good Month", "The balance barely notices your payment.", weight: { $0.totalDebt >= 20_000 ? 6 : 0 }, accept: EffectRange(cash: -5500 ... -3500, play: -2 ... -1), decline: EffectRange(cash: 1500...3000, health: -3 ... -1)),
        event("finance-repair", "The House Makes A Demand", "Water finds the one place you ignored.", weight: { !$0.assets.properties.isEmpty ? 5 : 0 }, accept: EffectRange(cash: -9000 ... -5500, health: 1...2), decline: EffectRange(cash: -2500 ... -1000, health: -4 ... -2)),
        event("finance-delinquency", "The Mortgage Letter Turns Red", "The grace period is over.", weight: { $0.assets.hasDelinquentProperty ? 8 : 0 }, accept: EffectRange(cash: -10000 ... -7000, play: -2 ... -1), decline: EffectRange(love: -4 ... -2, health: -5 ... -3)),
        event("finance-retirement", "Later Finally Competes With Now", "A contribution increase would make this month tighter.", weight: { $0.career.level.isEmployed && $0.character.age >= 35 ? 3 : 0 }, accept: EffectRange(cash: -3500 ... -2000, rep: 1...2), decline: EffectRange(play: 1...3)),
        event("finance-medical-bill", "A Medical Bill Arrives Late", "Care helped; the invoice did not.", weight: { $0.finance.medicalDebt > 0 ? 6 : 0 }, accept: EffectRange(cash: -6000 ... -3500, health: 1...2), decline: EffectRange(cash: 1000...2000, health: -3 ... -1)),
        event("finance-downsize", "Your Home Outgrows Your Margin", "Review selling or downsizing in Assets. Any sale will use actual equity after the mortgage and closing costs.", weight: { !$0.assets.properties.isEmpty && $0.finance.financialStress >= 55 ? 6 : 0 }, accept: EffectRange(love: -2 ... -1), decline: EffectRange(love: 1...2))
    ]

    private static let family: [LifeEvent] = [
        event("family-sleepless", "A Child Needs The Whole Night", "Morning arrives without anyone being ready.", weight: { $0.family.dependentLoad > 0 ? 5 : 0 }, accept: EffectRange(love: 3...5, play: -3 ... -2, health: -3 ... -1), decline: EffectRange(love: -4 ... -2, play: 1...2)),
        event("family-school-call", "The School Calls During Work", "Your child needs someone now.", weight: { $0.family.children.contains(where: { $0.dependent && $0.age >= 6 }) ? 5 : 0 }, accept: EffectRange(cash: -3000 ... -1500, love: 3...5), decline: EffectRange(cash: 2000...3500, love: -4 ... -2)),
        event("family-care-load", "Caregiving Quietly Becomes Your Schedule", "A relative's needs stop fitting around the edges.", weight: { $0.family.caregivingLoad >= 30 ? 6 : 0 }, accept: EffectRange(love: 3...5, health: -4 ... -2), decline: EffectRange(love: -3 ... -1, play: 2...4)),
        event("family-adult-return", "An Adult Child Comes Home", "They need a room and time to reset.", weight: { $0.family.children.contains(where: { !$0.dependent && $0.adultOutcome == .needsSupport }) ? 6 : 0 }, accept: EffectRange(cash: -5500 ... -3500, love: 3...5), decline: EffectRange(cash: 1000...2500, love: -4 ... -2)),
        event("family-marriage-strain", "Marriage Stops Absorbing The Strain", "The same argument has learned new words.", weight: { $0.partner?.stage == .married && ($0.partner?.resentment ?? 0) >= 45 ? 7 : 0 }, accept: EffectRange(health: -1 ... 0), decline: EffectRange(love: -5 ... -3, play: 1...2)),
        event("family-bereavement", "A Family Voice Goes Missing", "The call changes the shape of the week.", weight: { $0.lifeStage == .legacy && !$0.family.contacts.isEmpty ? 3 : 0 }, accept: EffectRange(love: 2...4, play: -3 ... -1), decline: EffectRange(health: -4 ... -2))
    ]

    private static let health: [LifeEvent] = [
        event("health-depression", "The Morning Feels Heavier Again", "Getting upright takes more than sleep.", weight: { $0.health.conditions.contains(where: { $0.kind == .depression && $0.status == .active }) ? 7 : 0 }, accept: EffectRange(cash: -3500 ... -2000, health: 4...7), decline: EffectRange(play: -4 ... -2, health: -3 ... -1)),
        event("health-pain", "Pain Rewrites The Day's Plan", "The body vetoes what the calendar promised.", weight: { $0.health.conditions.contains(where: { $0.kind == .chronicPain && $0.status == .active }) ? 7 : 0 }, accept: EffectRange(cash: -4000 ... -2500, health: 3...5), decline: EffectRange(cash: 2000...3500, health: -4 ... -2)),
        event("health-cardio", "The Stairs Change The Conversation", "Your pulse stays loud at the landing.", weight: { $0.health.conditions.contains(where: { $0.kind == .cardiovascularStrain && $0.status == .active }) ? 7 : 0 }, accept: EffectRange(cash: -4500 ... -3000, health: 4...7), decline: EffectRange(health: -5 ... -3)),
        event("health-metabolic", "Routine Numbers Refuse To Cooperate", "The ordinary checkup becomes a warning.", weight: { $0.health.conditions.contains(where: { $0.kind == .metabolicIllness && $0.status == .active }) ? 7 : 0 }, accept: EffectRange(cash: -3500 ... -2000, health: 3...6), decline: EffectRange(play: 1...2, health: -4 ... -2)),
        event("health-addiction", "One Drink Keeps Becoming Several", "Relief arrives fast and charges interest.", weight: { $0.health.addictionPressure >= 55 ? 7 : 0 }, accept: EffectRange(play: -2 ... -1, health: 4...6), decline: EffectRange(play: 3...5, health: -6 ... -3)),
        event("health-care-access", "Care Exists Beyond Your Reach", "The appointment is available; the bill is not kind.", weight: { $0.health.careAccess == .limited && $0.health.overall < 55 ? 6 : 0 }, accept: EffectRange(cash: -6500 ... -4500, health: 5...8), decline: EffectRange(cash: 1000...2000, health: -4 ... -2))
    ]

    private static func event(
        _ id: String, _ headline: String, _ detail: String,
        weight: @escaping (LifeState) -> Int,
        accept: EffectRange, decline: EffectRange
    ) -> LifeEvent {
        LifeEvent(id: id, headline: headline, detail: detail, weight: weight, choices: [
            EventChoice(id: .accept, title: "Face it", detail: "Take the direct cost.", effects: accept, partnerEffect: PartnerEffect(), narrative: "You deal with what is in front of you."),
            EventChoice(id: .decline, title: "Defer it", detail: "Protect today and carry the consequence.", effects: decline, partnerEffect: PartnerEffect(), narrative: "You buy time. The problem keeps the receipt.")
        ])
    }
}
