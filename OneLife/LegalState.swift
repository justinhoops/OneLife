import Foundation

enum LegalRecordStatus: String, Codable {
    case clear
    case felony
}

struct LegalState: Codable, Equatable {
    var record: LegalRecordStatus = .clear
    var firearmHeat = 0
    var lastFirearmConsequenceAge: Int?
    var supervisionYearsRemaining = 0
    var cleanYears = 0
    var cases: [LegalCaseState] = []
    var activeCaseID: String?
    var caseSequence = 0
    var misdemeanorConvictions = 0
    var felonyConvictions = 0
    var personalLawyers: [DefenseLawyerState] = []
    var legalRandom: SeededRandom

    var isFelon: Bool { record == .felony }
    var isUnderSupervision: Bool { supervisionYearsRemaining > 0 }

    mutating func clamp() {
        firearmHeat = min(100, max(0, firearmHeat))
        supervisionYearsRemaining = max(0, supervisionYearsRemaining)
        cleanYears = max(0, cleanYears)
        cases = Array(cases.suffix(12))
        cases.indices.forEach { cases[$0].clamp() }
        caseSequence = max(0, caseSequence)
        misdemeanorConvictions = max(0, misdemeanorConvictions)
        felonyConvictions = max(0, felonyConvictions)
        personalLawyers = Array(personalLawyers.prefix(3))
        personalLawyers.indices.forEach { personalLawyers[$0].clamp() }
        if felonyConvictions > 0 { record = .felony }
    }
}

extension LegalState {
    enum CodingKeys: String, CodingKey {
        case record, firearmHeat, lastFirearmConsequenceAge
        case supervisionYearsRemaining, cleanYears, legalRandom, cases, activeCaseID, caseSequence
        case misdemeanorConvictions, felonyConvictions, personalLawyers
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        record = try c.decodeIfPresent(LegalRecordStatus.self, forKey: .record) ?? .clear
        firearmHeat = try c.decodeIfPresent(Int.self, forKey: .firearmHeat) ?? 0
        lastFirearmConsequenceAge = try c.decodeIfPresent(Int.self, forKey: .lastFirearmConsequenceAge)
        supervisionYearsRemaining = try c.decodeIfPresent(Int.self, forKey: .supervisionYearsRemaining) ?? 0
        cleanYears = try c.decodeIfPresent(Int.self, forKey: .cleanYears) ?? 0
        cases = try c.decodeIfPresent([LegalCaseState].self, forKey: .cases) ?? []
        activeCaseID = try c.decodeIfPresent(String.self, forKey: .activeCaseID)
        caseSequence = try c.decodeIfPresent(Int.self, forKey: .caseSequence) ?? 0
        misdemeanorConvictions = try c.decodeIfPresent(Int.self, forKey: .misdemeanorConvictions) ?? 0
        felonyConvictions = try c.decodeIfPresent(Int.self, forKey: .felonyConvictions) ?? 0
        personalLawyers = try c.decodeIfPresent([DefenseLawyerState].self, forKey: .personalLawyers) ?? []
        legalRandom = try c.decode(SeededRandom.self, forKey: .legalRandom)
        clamp()
    }
}

struct FirearmExposureItem: Equatable {
    let ownershipID: UInt64
    let risk: Int
}

struct FirearmExposureSnapshot: Equatable {
    let lawfulCount: Int
    let illicitCount: Int
    let totalRisk: Int
    let items: [FirearmExposureItem]

    static let empty = FirearmExposureSnapshot(lawfulCount: 0, illicitCount: 0, totalRisk: 0, items: [])
}

struct LegalYearOutcome: Equatable {
    var bullets: [String] = []
    var notes: [String] = []
    var confiscatedOwnershipID: UInt64?
    var completedSupervision = false
    var consequences: [DomainConsequence] = []
}

enum LegalSystem {
    private static let seedSalt: UInt64 = 0x4C45_4741_4C5F_524E

    static func initialize(runSeed: UInt64) -> LegalState {
        LegalState(legalRandom: SeededRandom(seed: derivedSeed(from: runSeed)))
    }

    static func apply(transaction: AssetTransaction, legal: inout LegalState) {
        legal.firearmHeat += transaction.legalHeatDelta
        legal.clamp()
    }

    static func resolveYear(
        legal: inout LegalState,
        exposure: FirearmExposureSnapshot,
        age: Int
    ) -> LegalYearOutcome {
        var result = LegalYearOutcome()
        guard exposure.totalRisk > 0 else {
            legal.firearmHeat = max(0, legal.firearmHeat - 8)
            if legal.supervisionYearsRemaining > 0 {
                legal.supervisionYearsRemaining -= 1
                legal.cleanYears += 1
                if legal.supervisionYearsRemaining == 0 {
                    result.completedSupervision = true
                    result.bullets.append("Legal supervision completed")
                    result.notes.append("The felony record remains, but the active supervision period ended.")
                } else {
                    result.bullets.append("Legal supervision \(legal.supervisionYearsRemaining)y remaining")
                }
            }
            return result
        }

        legal.cleanYears = 0
        legal.firearmHeat += min(12, max(1, exposure.totalRisk / 5))
        legal.clamp()
        let consequenceChance = min(65, legal.firearmHeat / 2 + exposure.totalRisk / 3)
        guard legal.legalRandom.next(in: 1...100) <= consequenceChance else {
            result.bullets.append("Firearm heat \(legal.firearmHeat)")
            return result
        }

        legal.record = .felony
        legal.lastFirearmConsequenceAge = age
        legal.supervisionYearsRemaining = max(6, legal.supervisionYearsRemaining)
        legal.cleanYears = 0
        legal.firearmHeat = min(100, legal.firearmHeat + 10)
        result.confiscatedOwnershipID = exposure.items.max {
            ($0.risk, $0.ownershipID) < ($1.risk, $1.ownershipID)
        }?.ownershipID
        result.bullets.append("Illegal firearm scrutiny became a felony case")
        result.notes.append("The highest-risk firearm was confiscated.")
        result.consequences.append(contentsOf: [
            DomainConsequence(
                source: .legal, target: .career, kind: .legalTrouble, magnitude: .critical,
                openedAge: age, yearsRemaining: 6,
                headline: "A felony now shadows your work",
                detail: "The record restricts future opportunities even after the immediate case is over."
            ),
            DomainConsequence(
                source: .legal, target: .finance, kind: .legalTrouble, magnitude: .major,
                openedAge: age, yearsRemaining: 4,
                headline: "The case consumed financial margin",
                detail: "The legal aftermath is adding costs and narrowing the household's room to recover."
            ),
            DomainConsequence(
                source: .legal, target: .relationships, kind: .legalTrouble, magnitude: .major,
                openedAge: age, yearsRemaining: 4,
                headline: "The case followed you home",
                detail: "Trust and ordinary household stability are carrying part of the legal aftermath."
            )
        ])
        return result
    }

    private static func derivedSeed(from runSeed: UInt64) -> UInt64 {
        var value = runSeed ^ seedSalt
        value &+= 0x9E37_79B9_7F4A_7C15
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
