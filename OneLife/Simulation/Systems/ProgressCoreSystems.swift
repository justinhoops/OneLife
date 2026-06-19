import Foundation

struct TrajectorySystem {
    func advanceYear(input: TrajectoryDomainSnapshot, trajectory: inout TrajectoryState) -> DomainYearResult {
        var result = DomainYearResult()

        trajectory.lifePhase = resolvedLifePhase(for: input.player.age, family: input.family)

        let supportBase = (
            input.relationships.friends.strongestBond +
            input.relationships.partnerBond +
            input.education.teacherSupport +
            input.education.mentorSupport
        ) / 4
        let householdStrain = max(0, input.finance.financialStress - 40)
        let relationshipStrain = input.relationships.activeTensionCount * 8
        let healthDrag = max(0, 50 - input.health.mentalWellness)
        let careerStability = max(0, input.career.jobSecurity - 45)
        let educationLift = (
            input.education.schoolStanding +
            input.education.applicationReadiness +
            (input.education.hasScholarship ? 16 : 0)
        ) / 3

        trajectory.familyStability = (
            trajectory.familyStability +
            ((supportBase - 50) / 6) -
            (relationshipStrain / 5) -
            (householdStrain / 10) +
            (input.family.childCount > 0 && input.relationships.hasPartner ? 2 : 0)
        ).clamped(to: 0...100)

        trajectory.educationalAccess = (
            trajectory.educationalAccess +
            ((educationLift - 50) / 5) +
            ((input.player.smarts - 50) / 9) -
            (householdStrain / 12)
        ).clamped(to: 0...100)

        trajectory.socialCapital = (
            trajectory.socialCapital +
            ((supportBase - 50) / 5) +
            ((input.relationships.publicReputation - 50) / 8) -
            (input.relationships.activeRumorHeat / 18)
        ).clamped(to: 0...100)

        trajectory.socioeconomicPressure = (
            trajectory.socioeconomicPressure +
            (householdStrain / 5) +
            (input.finance.cashOnHand < 0 ? 8 : 0) +
            (input.family.dependentChildCount > 0 ? min(10, input.family.dependentChildCount * 2) : 0) -
            (max(0, input.finance.lastYearBalanceDelta) / 2_500) -
            (careerStability / 8)
        ).clamped(to: 0...100)

        trajectory.neighborhoodSafety = (
            trajectory.neighborhoodSafety +
            ((input.originProfile?.templateID == .chaoticHomeSelfReliant) ? -3 : 0) +
            ((input.finance.cashOnHand >= 8_000 || input.housing.housingStability >= 65) ? 2 : -1)
        ).clamped(to: 0...100)

        let recoveryLift = max(0, input.health.habits.stressManagement - 50) / 6
        trajectory.resilience = (
            trajectory.resilience +
            ((trajectory.familyStability - 50) / 10) +
            recoveryLift -
            (healthDrag / 7) -
            (householdStrain / 14)
        ).clamped(to: 0...100)

        let momentumGain =
            (input.finance.lastYearBalanceDelta > 0 ? 4 : -3) +
            ((input.career.performance - 50) / 8) +
            ((input.health.mentalWellness - 50) / 10) +
            ((trajectory.socialCapital - 50) / 12) +
            max(-3, trajectory.luckWindow / 4)
        trajectory.momentum = (trajectory.momentum + momentumGain).clamped(to: 0...100)

        let setbackShift =
            (input.finance.lastYearBalanceDelta < 0 ? 4 : -2) +
            (input.career.status == .unemployed ? 6 : 0) +
            (input.health.activeConditions.isEmpty ? 0 : input.health.activeConditions.count * 3) +
            (relationshipStrain / 8) -
            (trajectory.resilience / 18)
        trajectory.setbackPressure = (trajectory.setbackPressure + setbackShift).clamped(to: 0...100)

        let opportunityBase =
            (trajectory.educationalAccess + trajectory.socialCapital + max(0, input.career.performance)) / 3
        trajectory.opportunityVisibility = (
            trajectory.opportunityVisibility +
            ((opportunityBase - 50) / 6) +
            max(-4, trajectory.luckWindow / 3) -
            (trajectory.socioeconomicPressure / 16)
        ).clamped(to: 0...100)

        trajectory.luckWindow = updatedLuckWindow(for: input, trajectory: trajectory)
        trajectory.direction = resolvedDirection(for: trajectory)
        trajectory.clamp()

        if trajectory.direction == .rising && trajectory.momentum >= 62 {
            result.notes.append(
                DomainNote(
                    title: "Trajectory",
                    text: "Things are starting to compound. The year did not just go well; it made the next one easier to imagine.",
                    tags: [.progress, .career]
                )
            )
        } else if trajectory.direction == .sliding && trajectory.setbackPressure >= 55 {
            result.notes.append(
                DomainNote(
                    title: "Trajectory",
                    text: "The strain is turning into a pattern now. Bad years are starting to reinforce each other.",
                    tags: [.finance, .health]
                )
            )
        }

        return result
    }

    func apply(effect: TrajectoryEffects, trajectory: inout TrajectoryState) {
        trajectory.socioeconomicPressure += effect.socioeconomicPressure ?? 0
        trajectory.familyStability += effect.familyStability ?? 0
        trajectory.educationalAccess += effect.educationalAccess ?? 0
        trajectory.socialCapital += effect.socialCapital ?? 0
        trajectory.neighborhoodSafety += effect.neighborhoodSafety ?? 0
        trajectory.resilience += effect.resilience ?? 0
        trajectory.momentum += effect.momentum ?? 0
        trajectory.setbackPressure += effect.setbackPressure ?? 0
        trajectory.luckWindow += effect.luckWindow ?? 0
        trajectory.opportunityVisibility += effect.opportunityVisibility ?? 0
        if let phase = effect.setLifePhase {
            trajectory.lifePhase = phase
        }
        if let direction = effect.setDirection {
            trajectory.direction = direction
        }
        trajectory.clamp()
    }

    private func resolvedLifePhase(for age: Int, family: FamilyState) -> LifePhase {
        switch age {
        case ..<18:
            return .adolescence
        case 18...24:
            return .launch
        case 25...34:
            return family.childCount > 0 || family.isPregnant ? .familyBuilder : .earlyCareer
        case 35...54:
            return .midlife
        default:
            return .laterLife
        }
    }

    private func resolvedDirection(for trajectory: TrajectoryState) -> TrajectoryDirection {
        if trajectory.momentum >= 64 && trajectory.setbackPressure <= 32 && trajectory.socioeconomicPressure <= 54 {
            return .rising
        }
        if trajectory.setbackPressure >= 62 || (trajectory.socioeconomicPressure >= 68 && trajectory.momentum <= 42) {
            return .sliding
        }
        if trajectory.setbackPressure >= 42 || trajectory.socioeconomicPressure >= 58 || trajectory.opportunityVisibility <= 38 {
            return .fragile
        }
        return .stable
    }

    private func updatedLuckWindow(for input: TrajectoryDomainSnapshot, trajectory: TrajectoryState) -> Int {
        var value = trajectory.luckWindow
        if value > 0 {
            value -= 2
        } else if value < 0 {
            value += 2
        }

        let ageSeed = (input.player.age * 11) + input.player.smarts + input.relationships.publicReputation
        if ageSeed % 9 == 0 {
            value += 4
        } else if ageSeed % 11 == 0 {
            value -= 3
        }

        if input.player.traits.contains(.lucky) {
            value += 2
        }

        return value.clamped(to: -20...20)
    }
}

struct ProgressMilestoneDefinition {
    var id: MilestoneID
    var title: String
    var legacyScore: Int
    var requirement: (GameState) -> Bool
}

struct LifePathDefinition {
    var id: LifePathID
    var minimumScore: Int
    var score: (GameState) -> Int
}

struct PublicIdentitySnapshot: Codable, Equatable {
    var label: String
    var score: Int
    var tone: PlannerTone
    var detail: String
    var consequences: [String]
}

struct PublicIdentitySystem {
    func snapshot(for state: GameState) -> PublicIdentitySnapshot {
        let legalDrag = state.legal.convictions.isEmpty ? 0 : 16
        let wealthVisibility = min(22, max(0, state.finance.totalWealth) / 250_000)
        let careerVisibility = state.specialCareer.track == .inactive ? min(10, state.career.yearsWorked / 2) : 18
        let scandalHeat = max(state.fame.notoriety, state.relationships.activeRumorHeat, state.crime.heat + legalDrag)
        let cleanReach = max(state.fame.culturalFame, state.relationships.publicReputation + wealthVisibility + careerVisibility)
        let score = max(cleanReach, scandalHeat).clamped(to: 0...100)
        let isDark = scandalHeat >= max(45, cleanReach - 4)

        let label: String
        let tone: PlannerTone
        if isDark && scandalHeat >= 70 {
            label = "Infamous Name"
            tone = .warning
        } else if isDark && scandalHeat >= 45 {
            label = "Complicated Name"
            tone = .warning
        } else if cleanReach >= 78 {
            label = "Household Name"
            tone = .positive
        } else if cleanReach >= 55 {
            label = "Public Figure"
            tone = .positive
        } else {
            label = "Local Reputation"
            tone = .neutral
        }

        var consequences: [String] = []
        if cleanReach >= 55 { consequences.append("Doors open faster") }
        if scandalHeat >= 45 { consequences.append("Scrutiny follows choices") }
        if state.family.childCount > 0 && scandalHeat >= 55 { consequences.append("Family carries the shadow") }
        if wealthVisibility >= 12 { consequences.append("Money is visible") }
        if state.legal.stage != .inactive { consequences.append("Legal exposure colors the name") }
        if consequences.isEmpty { consequences.append("Mostly private life") }

        return PublicIdentitySnapshot(
            label: label,
            score: score,
            tone: tone,
            detail: isDark ? "Attention is carrying heat more than warmth." : "Recognition is becoming useful, and harder to put down.",
            consequences: Array(consequences.prefix(3))
        )
    }
}

struct LegacySignalSystem {
    func axes(for state: GameState) -> [LifeSummarySnapshot.LegacyAxis] {
        let familyAxis = familyMemoryAxis(state)
        let publicAxis = publicNameAxis(state)
        let wealthAxis = wealthFootprintAxis(state)
        let scarsAxis = harmAndScarsAxis(state)
        let unfinishedAxis = unfinishedBusinessAxis(state)
        return [familyAxis, publicAxis, wealthAxis, scarsAxis, unfinishedAxis]
    }

    func compactSignals(for state: GameState) -> [String] {
        axes(for: state).map { "\($0.title): \($0.value)" }
    }

    private func familyMemoryAxis(_ state: GameState) -> LifeSummarySnapshot.LegacyAxis {
        let adults = state.family.children.compactMap(\.adultProfile)
        let strong = adults.filter { $0.relationshipQuality >= 60 && ($0.outcome == .thriving || $0.outcome == .stable) }.count
        let strained = adults.filter { $0.relationshipQuality < 40 || $0.outcome == .distant }.count
        if strong >= 2 {
            return axis("family", "Family Memory", "Held", .positive, "The people closest to you had something solid to inherit emotionally.")
        }
        if strained > 0 {
            return axis("family", "Family Memory", "Strained", .warning, "Some relationships survived as facts more than warmth.")
        }
        if state.family.childCount > 0 {
            return axis("family", "Family Memory", "Mixed", .neutral, "The family story is still complicated, but present.")
        }
        return axis("family", "Family Memory", "Branch Ends", .neutral, "No children carried the line forward.")
    }

    private func publicNameAxis(_ state: GameState) -> LifeSummarySnapshot.LegacyAxis {
        let publicIdentity = PublicIdentitySystem().snapshot(for: state)
        return axis("public", "Public Name", publicIdentity.label, publicIdentity.tone, publicIdentity.consequences.joined(separator: " · "))
    }

    private func wealthFootprintAxis(_ state: GameState) -> LifeSummarySnapshot.LegacyAxis {
        if state.finance.totalWealth >= 5_000_000 {
            return axis("wealth", "Wealth Footprint", "Dynastic", .positive, "The estate can change the next life, even after friction.")
        }
        if state.finance.totalWealth >= 500_000 || state.assets.ownsHome {
            return axis("wealth", "Wealth Footprint", "Anchored", .positive, "Property or savings left a real floor behind.")
        }
        if state.finance.totalWealth < 0 {
            return axis("wealth", "Wealth Footprint", "Debt Shadow", .warning, "The ending leaves paperwork and pressure.")
        }
        return axis("wealth", "Wealth Footprint", "Modest", .neutral, "There is something to settle, but not enough to define the next life.")
    }

    private func harmAndScarsAxis(_ state: GameState) -> LifeSummarySnapshot.LegacyAxis {
        let load = max(state.healthProfile.bodyLoad.totalLoad, state.correlationLedger.recentActivityLevel, state.legal.convictions.isEmpty ? 0 : 55, state.crime.heat)
        if load >= 75 {
            return axis("scars", "Harm & Scars", "Heavy", .warning, "The life cost more than it looked like from outside.")
        }
        if load >= 45 {
            return axis("scars", "Harm & Scars", "Visible", .warning, "Stress, record, health, or heat left marks.")
        }
        return axis("scars", "Harm & Scars", "Contained", .neutral, "The damage stayed survivable.")
    }

    private func unfinishedBusinessAxis(_ state: GameState) -> LifeSummarySnapshot.LegacyAxis {
        var unresolved = 0
        if state.relationships.activeTensionCount > 0 { unresolved += 1 }
        if state.finance.financialStress >= 55 { unresolved += 1 }
        if state.healthProfile.activeConditions.contains(where: { $0.severity >= 55 }) { unresolved += 1 }
        if state.legal.stage != .inactive && state.legal.stage != .released { unresolved += 1 }
        if state.family.children.contains(where: { ($0.adultProfile?.relationshipQuality ?? $0.bondWithPlayer) < 40 }) { unresolved += 1 }

        if unresolved >= 3 {
            return axis("unfinished", "Unfinished", "Loud", .warning, "Several parts of the life still wanted attention at the end.")
        }
        if unresolved > 0 {
            return axis("unfinished", "Unfinished", "Present", .neutral, "A few loose ends remain visible.")
        }
        return axis("unfinished", "Unfinished", "Quiet", .positive, "The major loose ends were mostly settled.")
    }

    private func axis(_ id: String, _ title: String, _ value: String, _ tone: PlannerTone, _ detail: String) -> LifeSummarySnapshot.LegacyAxis {
        LifeSummarySnapshot.LegacyAxis(id: id, title: title, value: value, tone: tone, detail: detail)
    }
}

struct CareLoadSystem {
    func resolveYear(state: inout GameState) -> DomainYearResult {
        seedCareNeedsIfNeeded(state: &state)
        guard state.relationships.careLoad.isActive else { return DomainYearResult() }

        var result = DomainYearResult()
        state.relationships.careLoad.records.indices.forEach {
            state.relationships.careLoad.records[$0].yearsActive += 1
            state.relationships.careLoad.records[$0].intensity = max(0, state.relationships.careLoad.records[$0].intensity - 3)
        }
        state.relationships.careLoad.clamp()

        let intensity = state.relationships.careLoad.totalIntensity
        state.healthProfile.mentalWellness = max(0, state.healthProfile.mentalWellness - max(1, intensity / 18))
        state.relationships.privateReputation = min(100, state.relationships.privateReputation + max(1, intensity / 25))
        state.finance.cashOnHand -= max(0, intensity * 35)
        state.consequences.pressureByDomain["relationships", default: 0] = min(100, state.consequences.pressureByDomain["relationships", default: 0] + max(2, intensity / 12))
        state.consequences.pressureByDomain["health", default: 0] = min(100, state.consequences.pressureByDomain["health", default: 0] + max(1, intensity / 18))
        result.notes.append(DomainNote(title: "Care Load", text: state.relationships.careLoad.topLine, tags: [.relationships, .family, .health]))
        return result
    }

    private func seedCareNeedsIfNeeded(state: inout GameState) {
        guard state.player.age >= 45 else { return }
        guard state.relationships.careLoad.records.isEmpty else { return }

        if let partner = state.relationships.primaryPartner, partner.bond >= 35, state.player.age >= 62 {
            state.relationships.careLoad.records.append(CareLoadRecord(source: .sickPartner, personName: partner.name, intensity: 34, storyLine: "\(partner.name) needs more care than last year."))
        } else if let adult = state.family.children.first(where: { !$0.livesAtHome && (($0.adultProfile?.outcome == .struggling) || ($0.adultProfile?.relationshipQuality ?? $0.bondWithPlayer) < 42) }) {
            state.relationships.careLoad.records.append(CareLoadRecord(source: .dependentAdultChild, personName: adult.name, intensity: 30, storyLine: "\(adult.name) is grown, but not fully steady."))
        } else if state.player.age >= 55 && state.relationships.privateReputation >= 45 {
            state.relationships.careLoad.records.append(CareLoadRecord(source: .agingParent, personName: "Family", intensity: 24, storyLine: "An older relative starts needing practical help."))
        }
        state.relationships.careLoad.clamp()
    }
}

struct BodyLoadSystem {
    func update(state: inout GameState) -> DomainYearResult {
        let ageLoad = max(0, state.player.age - 42)
        let conditionLoad = min(45, state.healthProfile.activeConditions.reduce(0) { $0 + $1.severity / 4 })
        let addictionLoad = state.healthProfile.addiction / 3
        let mentalLoad = max(0, 55 - state.healthProfile.mentalWellness)
        let careLoad = state.relationships.careLoad.totalIntensity / 3
        let habitProtection = (state.healthProfile.habits.exercise + state.healthProfile.habits.nutrition + state.healthProfile.habits.stressManagement) / 9

        state.healthProfile.bodyLoad.mobilityStrain = (ageLoad + conditionLoad - habitProtection).clamped(to: 0...100)
        state.healthProfile.bodyLoad.cognitiveStrain = (ageLoad / 2 + mentalLoad + addictionLoad).clamped(to: 0...100)
        state.healthProfile.bodyLoad.recoveryDrag = (ageLoad + conditionLoad + careLoad - (state.healthProfile.hasPrimaryCare ? 10 : 0)).clamped(to: 0...100)
        state.healthProfile.bodyLoad.stressDebt = (mentalLoad + careLoad + state.career.burnout / 2).clamped(to: 0...100)
        state.healthProfile.bodyLoad.preventiveCare = (state.healthProfile.hasPrimaryCare ? 62 : 34) + habitProtection

        let total = state.healthProfile.bodyLoad.totalLoad
        if total >= 65 {
            state.healthProfile.bodyLoad.summaryLine = "Body load is shaping every year now."
            state.consequences.pressureByDomain["health", default: 0] = min(100, state.consequences.pressureByDomain["health", default: 0] + 8)
            return DomainYearResult(notes: [DomainNote(title: "Body Load", text: state.healthProfile.bodyLoad.summaryLine, tags: [.health])])
        }
        if total >= 35 {
            state.healthProfile.bodyLoad.summaryLine = "Recovery is slower than it used to be."
        } else {
            state.healthProfile.bodyLoad.summaryLine = "Body load is quiet."
        }
        return DomainYearResult()
    }
}

struct HousingClassSystem {
    func update(state: inout GameState) {
        state.housing.lifeStage = housingStage(for: state)
        state.housing.socialClassBand = socialClass(for: state)
        state.housing.stabilityHistory.append(state.housing.housingStability)
        state.housing.clamp()
    }

    private func housingStage(for state: GameState) -> HousingState.HousingLifeStage {
        if let home = state.assets.primaryResidence, home.status == .foreclosed { return .foreclosed }
        if state.inheritedLegacy?.inheritedProperty != nil && state.assets.ownsHome { return .inheritedHome }
        if state.assets.lifestyleScore >= 75 && state.assets.ownsHome { return .luxuryEstate }
        if state.assets.ownsHome && state.finance.financialStress >= 60 { return .housePoor }
        if state.assets.ownsHome { return .ownerOccupied }
        if state.housing.housingStability < 30 { return .unsafeRental }
        switch state.housing.livingArrangement {
        case .familyHome: return .familyHome
        case .roommates: return .roommates
        case .soloRenting: return .soloRenting
        case .ownerOccupied: return .ownerOccupied
        case .couchSurfing: return .unsafeRental
        }
    }

    private func socialClass(for state: GameState) -> HousingState.SocialClassBand {
        let wealth = state.finance.totalWealth
        if wealth >= 100_000_000 || state.fame.recognition >= 90 { return .untouchable }
        if wealth >= 10_000_000 || state.assets.lifestyleScore >= 85 { return .elite }
        if wealth >= 1_000_000 || state.career.annualIncome >= 220_000 { return .affluent }
        if wealth >= 80_000 && state.housing.housingStability >= 55 && state.finance.financialStress < 45 { return .stableMiddle }
        if state.finance.cashOnHand < 0 || state.housing.housingStability < 35 { return .precarious }
        return .working
    }
}

struct EndgameSummarySystem {
    func mode(for state: GameState) -> String {
        if state.legal.isInCustody { return "Prison Ending" }
        if state.fame.notoriety >= 75 || state.crime.heat >= 80 { return "Scandal Collapse" }
        if state.player.age >= 78 && state.relationships.privateReputation >= 60 && state.finance.totalWealth < 1_000_000 { return "Broke But Loved" }
        if state.finance.totalWealth >= 5_000_000 && state.relationships.privateReputation < 45 { return "Rich And Alone" }
        if state.specialCareer.track != .inactive && state.progress.legacyScore >= 120 { return "Empire Handoff" }
        if state.player.age >= 78 { return "Quiet Old Age" }
        if state.player.health <= 0 || state.healthProfile.physicalWellness <= 0 || state.healthProfile.bodyLoad.totalLoad >= 70 { return "Medical Decline" }
        if state.family.childCount == 0 && state.player.age >= 60 { return "Branch Ends" }
        if state.family.children.contains(where: { ($0.adultProfile?.relationshipQuality ?? $0.bondWithPlayer) >= 70 }) { return "Family Reconciliation" }
        return "Unfinished Life"
    }

    func meaningLine(for state: GameState, axes: [LifeSummarySnapshot.LegacyAxis]) -> String {
        if axes.contains(where: { $0.id == "family" && $0.value == "Held" }) {
            return "The clearest proof of the life is in the people who still answer."
        }
        if state.finance.totalWealth >= 5_000_000 {
            return "The money lasted; the question is what it cost to make it."
        }
        if state.fame.notoriety >= 70 {
            return "Being remembered is not the same as being forgiven."
        }
        if state.progress.currentLifePath == .survivor {
            return "Survival became its own kind of authorship."
        }
        return "The meaning is not clean, but it is traceable."
    }
}

struct ProgressSystem {
    private let balanceProfile: SimulationBalanceProfile

    init(balanceProfile: SimulationBalanceProfile = .playableRealismV1) {
        self.balanceProfile = balanceProfile
    }

    private let definitions: [ProgressMilestoneDefinition] = [
        ProgressMilestoneDefinition(id: .graduate, title: "Graduate", legacyScore: 10) {
            $0.education.pathway == .graduate || $0.education.credentials.contains("Diploma")
        },
        ProgressMilestoneDefinition(id: .firstJob, title: "First Job", legacyScore: 15) {
            $0.career.roleID != nil || $0.career.yearsWorked > 0
        },
        ProgressMilestoneDefinition(id: .homeowner, title: "Home Owner", legacyScore: 25) {
            $0.assets.ownsHome
        },
        ProgressMilestoneDefinition(id: .married, title: "Married", legacyScore: 25) {
            $0.relationships.hasSpouse
        },
        ProgressMilestoneDefinition(id: .millionaire, title: "Millionaire", legacyScore: 40) {
            $0.finance.totalWealth >= 1_000_000 &&
            $0.player.age >= SimulationBalanceProfile.playableRealismV1.wealth.millionaireMinimumAge &&
            $0.finance.hasMillionaireFoundation(using: .playableRealismV1)
        },
        ProgressMilestoneDefinition(id: .longLived, title: "90+ Lifespan", legacyScore: 30) {
            $0.player.age >= 90
        },
        // Phase 2.3: Family legacy
        ProgressMilestoneDefinition(id: .raisedGoodKids, title: "Raised Children Who Turned Out Okay", legacyScore: 25) {
            $0.family.children.contains { child in
                guard let p = child.adultProfile else { return false }
                return p.outcome == .thriving || (p.outcome == .stable && p.relationshipQuality >= 50)
            }
        },
        // Fame Web F3: Legacy recognition milestones
        ProgressMilestoneDefinition(id: .culturalIcon, title: "Cultural Icon", legacyScore: 45) {
            $0.fame.culturalFame >= 70 && $0.fame.knownFor.count >= 3
        },
        ProgressMilestoneDefinition(id: .infamous, title: "Infamous Figure", legacyScore: 40) {
            $0.fame.notoriety >= 70
        },
        ProgressMilestoneDefinition(id: .householdName, title: "Household Name", legacyScore: 50) {
            $0.fame.culturalFame >= 85 || $0.fame.recognition >= 90
        }
    ]
    private let lifePaths: [LifePathDefinition] = [
        LifePathDefinition(id: .scholar, minimumScore: 74) { state in
            var score = state.education.schoolStanding + state.player.smarts
            if state.education.pathway == .graduate { score += 24 }
            if state.education.pathway == .training { score += 12 }
            if state.education.hasScholarship { score += 12 }
            if state.player.traits.contains(.disciplined) { score += 8 }
            score -= max(0, state.finance.financialStress - 40) / 2
            return score
        },
        LifePathDefinition(id: .striver, minimumScore: 76) { state in
            var score = state.career.performance + min(30, state.career.annualIncome / 1_500)
            score += state.career.yearsWorked * 4
            if state.career.status == .fullTime { score += 14 }
            if state.career.roleID != nil { score += 8 }
            return score
        },
        LifePathDefinition(id: .provider, minimumScore: 78) { state in
            var score = min(38, max(0, state.finance.totalWealth) / 2_000)
            score += min(24, max(0, state.finance.lastYearBalanceDelta) / 1_200)
            if state.assets.ownsHome { score += 22 }
            if state.relationships.hasSpouse { score += 10 }
            score += min(12, state.family.childCount * 4)
            if state.housing.housingStability >= 70 { score += 8 }
            return score
        },
        LifePathDefinition(id: .connector, minimumScore: 72) { state in
            let strongestBond = max(state.relationships.friends.strongestBond, state.relationships.partnerBond)
            var score = strongestBond
            score += (state.relationships.friends.count + (state.relationships.hasPartner ? 1 : 0)) * 8
            if state.relationships.hasSpouse { score += 20 }
            if state.player.traits.contains(.charismatic) { score += 6 }
            return score
        },
        LifePathDefinition(id: .survivor, minimumScore: 80) { state in
            var score = state.finance.financialStress
            score += state.healthProfile.activeConditions.count * 18
            score += max(0, 70 - state.housing.housingStability)
            if state.finance.cashOnHand < 0 { score += 18 }
            if state.player.age >= 25 { score += 10 }
            if !state.isGameOver { score += 8 }
            return score
        }
    ]

    func unlockNewMilestones(input: ProgressDomainSnapshot, progress: inout ProgressState) -> DomainYearResult {
        var state = input.state
        state.progress = progress
        let result = unlockNewMilestones(for: &state)
        progress = state.progress
        return result
    }

    func unlockNewMilestones(for state: inout GameState) -> DomainYearResult {
        var result = DomainYearResult()
        let unlockedIDs = Set(state.progress.unlockedMilestones.map(\.id))

        for definition in definitions where !unlockedIDs.contains(definition.id) && definition.requirement(state) {
            state.progress.unlockedMilestones.append(MilestoneUnlock(id: definition.id, unlockedAtAge: state.player.age))
            state.progress.legacyScore += definition.legacyScore
            result.notes.append(DomainNote(title: "Milestone", text: "You reached \(definition.title), adding \(definition.legacyScore) legacy points."))
        }

        state.progress.unlockedMilestones.sort { $0.unlockedAtAge < $1.unlockedAtAge }
        return result
    }

    func updateLifePath(input: ProgressDomainSnapshot, progress: inout ProgressState) -> DomainYearResult {
        var state = input.state
        state.progress = progress
        let result = updateLifePath(for: &state)
        progress = state.progress
        return result
    }

    func updateLifePath(for state: inout GameState) -> DomainYearResult {
        var result = DomainYearResult()
        let currentPath = state.progress.currentLifePath
        guard let resolvedPath = strongestLifePath(for: state) else { return result }

        if currentPath == resolvedPath {
            return result
        }

        state.progress.currentLifePath = resolvedPath

        if !state.progress.unlockedLifePaths.contains(where: { $0.id == resolvedPath }) {
            state.progress.unlockedLifePaths.append(LifePathUnlock(id: resolvedPath, unlockedAtAge: state.player.age))
            state.progress.legacyScore += 8
            let note = lifePathCrystallizationNote(path: resolvedPath, state: state, isNew: true)
            result.notes.append(DomainNote(title: "Life Path", text: note, tags: [.progress, .lifeEvent]))
        } else {
            let note = lifePathCrystallizationNote(path: resolvedPath, state: state, isNew: false)
            result.notes.append(DomainNote(title: "Life Path", text: note, tags: [.progress]))
        }

        state.progress.unlockedLifePaths.sort { $0.unlockedAtAge < $1.unlockedAtAge }
        return result
    }

    func finalizeLifePath(input: ProgressDomainSnapshot, progress: inout ProgressState) -> DomainYearResult {
        var state = input.state
        state.progress = progress
        let result = finalizeLifePath(for: &state)
        progress = state.progress
        return result
    }

    func finalizeLifePath(for state: inout GameState) -> DomainYearResult {
        var result = DomainYearResult()

        if state.progress.currentLifePath == nil {
            state.progress.currentLifePath = strongestLifePath(for: state)
        }

        guard let finalPath = state.progress.currentLifePath else { return result }
        guard state.progress.finalLifePath != finalPath else { return result }

        state.progress.finalLifePath = finalPath
        let profile = LifePathCatalog.profile(for: finalPath)
        
        // P5: More poetic and path-aware handoff
        let legacyIntro: String
        switch finalPath {
        case .scholar: legacyIntro = "You leaves behind a legacy of quiet inquiry and documented mastery."
        case .striver: legacyIntro = "You are remembered as someone who never stopped pushing the world back."
        case .provider: legacyIntro = "Your legacy is one of built walls and steady roofs; a life that anchored others."
        case .connector: legacyIntro = "You are remembered through the people you held together."
        case .survivor: legacyIntro = "Your story is a monument to what can be endured. You survived."
        }
        
        result.notes.append(DomainNote(title: "Legacy", text: legacyIntro))

        // P5 Cohesion Gate: composed closer from unified narrative router
        let closer = CohesionNarrative.legacyCloserText(state: state)
        if !closer.isEmpty {
            result.notes.append(DomainNote(title: "The End", text: "The final chapter wrote itself.\(closer)", tags: [.progress]))
        }
        return result
    }

    /// Extracts meta-progression data from a finished game state.
    func harvestLegacy(from state: GameState, meta: inout MetaState) {
        meta.totalLivesPlayed += 1
        meta.totalYearsLived += state.player.age

        meta.legacyPoints += legacyPointsEarned(from: state)

        // Generation Flags
        if state.player.age >= 65 {
            meta.generationFlags.insert("reached_retirement")
        }
        if state.player.age >= 100 {
            meta.generationFlags.insert("centenarian_memory")
        }

        if state.finance.totalWealth >= 1_000_000,
           state.player.age >= balanceProfile.wealth.millionaireMinimumAge,
           state.finance.hasMillionaireFoundation(using: balanceProfile) {
            meta.generationFlags.insert("wealthy_dynasty")
        }

        if state.education.pathway == .graduate && state.player.smarts >= 90 {
            meta.generationFlags.insert("academic_legend")
        }

        // Phase 2.3: Adult children legacy flag
        let goodKids = state.family.children.filter { child in
            guard let p = child.adultProfile else { return false }
            return p.outcome == .thriving || (p.outcome == .stable && p.relationshipQuality >= 55)
        }
        if !goodKids.isEmpty {
            meta.generationFlags.insert("raised_solid_kids")
        }
        if goodKids.count >= 2 {
            meta.generationFlags.insert("family_that_held")
        }
        if state.family.childCount == 0 && state.player.age >= 60 {
            meta.generationFlags.insert("the_branch_ends")
        }

        // P5: Cycle breaking legacy flag
        if let d = state.childhoodDossier, d.aptitudes.social < 40 {
            if state.finance.totalWealth >= 500_000 || state.healthProfile.mentalWellness >= 65 {
                meta.generationFlags.insert("broke_the_cycle")
            }
        }

        // Fame Web F3: Legacy recognition flags for meta progression
        if state.fame.culturalFame >= 70 && state.fame.knownFor.count >= 2 {
            meta.generationFlags.insert("cultural_icon")
        }
        if state.fame.notoriety >= 70 {
            meta.generationFlags.insert("infamous")
        }
        if state.fame.recognition >= 85 {
            meta.generationFlags.insert("household_name")
        }
        if state.fame.culturalFame >= 60 && state.fame.notoriety < 30 {
            meta.generationFlags.insert("clean_legacy")
        }

        // CE3: Criminal enterprise legacy flags (dark path differentiation)
        let ent = state.specialCareer.enterprise
        if state.specialCareer.track == .crime || state.crime.status == .active {
            if ent.notoriety >= 65 {
                meta.generationFlags.insert("lived_in_the_shadows")
            }
            if ent.cleanMoneyRatio >= 75 && ent.notoriety >= 50 {
                meta.generationFlags.insert("built_a_criminal_empire_then_washed_it")
            }
            if state.crime.heat >= 80 && state.player.age < 55 {
                meta.generationFlags.insert("went_down_in_flames")
            }
            if ent.crewSize >= 10 && ent.networkStrength >= 70 {
                meta.generationFlags.insert("ruled_a_silent_kingdom")
            }
        }
        if !state.legal.convictions.isEmpty {
            meta.generationFlags.insert("carried_a_criminal_record")
            if state.legal.convictions.contains(where: { $0.sentenceYears >= 3 }) {
                meta.generationFlags.insert("served_time")
            }
        }

        // Engine4: Correlation / Intensity legacy flags
        let maxHeat = state.correlationLedger.recentActivityLevel
        if maxHeat >= 75 {
            meta.generationFlags.insert("burned_bright")
        }
        if maxHeat >= 85 {
            meta.generationFlags.insert("legendary_run")
        }
        // Check if the player had consistently high correlation across many years (rough proxy)
        if state.correlationLedger.recentActivityLevel >= 60 && state.player.age >= 40 {
            meta.generationFlags.insert("echo_life")
        }

        // Assets4: Asset-driven legacy flags
        if state.assets.lifestyleScore >= 75 && state.player.age >= 50 {
            meta.generationFlags.insert("left_behind_real_wealth")
        }
        if state.assets.signatureAssets.count >= 2 {
            meta.generationFlags.insert("built_the_collection")
        }
        if state.assets.marine.count >= 1 || state.assets.aviation.count >= 1 {
            if state.assets.lifestyleScore >= 70 {
                meta.generationFlags.insert("lived_the_high_life")
            }
        }
        if state.assets.vehicles.count >= 5 && state.assets.lifestyleScore >= 60 {
            meta.generationFlags.insert("car_collector_legacy")
        }

        // E4: Founder-specific legacy flags
        if state.specialCareer.track == .founder || state.specialCareer.founder.personalLegend >= 50 {
            if state.specialCareer.founder.personalLegend >= 70 {
                meta.generationFlags.insert("legendary_founder")
            }
            if state.specialCareer.audience >= 70 {
                meta.generationFlags.insert("built_something_real")
            }
            if state.specialCareer.founder.founderMentalLoad >= 70 && state.specialCareer.audience >= 50 {
                meta.generationFlags.insert("paid_the_price")
            }
        }

        // CT3-3: Diamond empire legacy flags (new strong meta for richest lives)
        let isDiamond = [.movieProducer, .recordLabelOwner, .sportsOwner, .shadowOperative, .trader, .ventureCapitalist, .corporateRaider, .fightEmpire].contains(state.specialCareer.track)
        if state.specialCareer.track == .coach || state.specialCareer.coaching.programPrestige >= 70 {
            let coach = state.specialCareer.coaching
            if coach.programPrestige >= 70 && coach.seasonWins >= 8 {
                meta.generationFlags.insert("program_builder")
            }
            if coach.programLevel >= 3 {
                meta.generationFlags.insert("dynasty_builder")
            }
        }
        if isDiamond {
            if state.specialCareer.track == .movieProducer {
                let film = state.specialCareer.movieProducer
                if film.prestige >= 70 && film.backendCatalog >= 50 {
                    meta.generationFlags.insert("built_a_studio")
                }
                if film.distributionLeverage >= 70 {
                    meta.generationFlags.insert("cultural_monument")
                }
            }
            if state.specialCareer.track == .sportsOwner {
                let owner = state.specialCareer.sportsOwner
                if owner.portfolio.count >= 2 && owner.totalValuation >= 5_000_000_000 {
                    meta.generationFlags.insert("franchise_mogul")
                }
                if owner.totalValuation >= 10_000_000_000 {
                    meta.generationFlags.insert("owned_the_league")
                }
            }
            if state.specialCareer.track == .recordLabelOwner {
                // assume recordLabel state has similar prestige
                meta.generationFlags.insert("built_a_label_empire")
            }
            if state.specialCareer.track == .fightEmpire {
                let empire = state.specialCareer.fightEmpire
                if empire.gymReputation >= 70 {
                    meta.generationFlags.insert("built_a_fight_gym")
                }
                if empire.promotionReach >= 70 && empire.fighterTrust >= 60 {
                    meta.generationFlags.insert("built_a_fight_promotion")
                }
            }
            // Criminal Enterprise as Diamond
            if [.shadowOperative, .trader, .ventureCapitalist, .corporateRaider].contains(state.specialCareer.track) {
                let ent = state.specialCareer.enterprise
                if ent.networkStrength >= 70 && ent.cleanMoneyRatio >= 60 {
                    meta.generationFlags.insert("built_a_dark_empire")
                }
                if ent.cleanMoneyRatio >= 80 {
                    meta.generationFlags.insert("washed_the_empire_clean")
                }
            }
            meta.generationFlags.insert("empire_builder") // general diamond flag
        }

        // P4: stronger resilience divergence in legacy/meta (grounded: bigger comeback flags; resilient: scar + compound flags)
        if state.resilience == .grounded {
            if state.player.age > 55 && state.healthProfile.mentalWellness > 55 {
                meta.generationFlags.insert("fought_back_late_and_won")
            }
            meta.legacyPoints += max(0, (70 - state.correlationLedger.recentActivityLevel) / 3) // recovery from low intensity
        } else {
            if state.correlationLedger.recentActivityLevel > 75 {
                meta.generationFlags.insert("scars_from_the_fast_lane")
            }
            meta.legacyPoints += state.finance.totalWealth / 15000 // compounds the high-intensity advantages
        }

        // P3: D4 life-shape + stance + focus residue legacy flags (makes every life tell a different story in next gen)
        let recentStances = state.yearlyStance.recentStances
        if recentStances.count >= 3 {
            let driftCount = recentStances.filter { $0 == .letYearDrift }.count
            if driftCount >= 2 {
                meta.generationFlags.insert("drifted_through_life")
            }
            let pushCount = recentStances.filter { $0 == .pushCareer || $0 == .soldierStance }.count
            if pushCount >= 2 {
                meta.generationFlags.insert("lived_driven")
            }
        }
        // Life shape from D4 (reuse simple tally)
        switch LifeShapeResolver.resolve(from: state) {
        case .looseEdges:
            meta.generationFlags.insert("left_loose_ends")
        case .drivenCurrent:
            meta.generationFlags.insert("passed_on_the_drive")
        case .carefulShape:
            meta.generationFlags.insert("modeled_steady_care")
        default:
            break
        }
        // Stance residue echo
        if state.yearlyStance.repeatCount >= 3 {
            meta.generationFlags.insert("stuck_in_a_rut_once")
        }
    }

    func legacyPointsEarned(from state: GameState) -> Int {
        var pointsEarned = state.player.age / 10
        for definition in definitions where definition.requirement(state) {
            pointsEarned += definition.legacyScore / 5
        }
        return pointsEarned
    }

    // MARK: - Life Path Crystallization (Codex IX — Continuity Thread)

    private func lifePathCrystallizationNote(path: LifePathID, state: GameState, isNew: Bool) -> String {
        let trait = state.player.traits.first
        let age = state.player.age

        if isNew {
            return newLifePathNote(path: path, trait: trait, age: age)
        } else {
            return returningLifePathNote(path: path)
        }
    }

    private func newLifePathNote(path: LifePathID, trait: PersonalityTrait?, age: Int) -> String {
        // Main crystallization line — specific to the path
        let mainLine: String
        switch path {
        case .scholar:
            mainLine = "The pattern is clear: you keep going back to learning. The credentials are stacking. This is a scholar's life."
        case .striver:
            mainLine = "You keep showing up and grinding forward. The work is the constant. This is a striver's life."
        case .provider:
            mainLine = "Stability is the thing you keep building toward. The money, the housing, the structure. This is a provider's life."
        case .connector:
            mainLine = "The relationships are the main story. People in, people out, but always people. This is a connector's life."
        case .survivor:
            mainLine = "The pressure has been real and you are still here. That counts. This is a survivor's life."
        }

        // Trait resonance — a sentence that notices the connection between trait and path
        let traitLine: String
        if let trait {
            traitLine = traitLifePathResonance(trait: trait, path: path)
        } else {
            traitLine = ""
        }

        return traitLine.isEmpty ? mainLine : "\(mainLine) \(traitLine)"
    }

    private func returningLifePathNote(path: LifePathID) -> String {
        switch path {
        case .scholar:   return "The year pulled you back to the scholar path. The books and the grind — still the main thing."
        case .striver:   return "Another year of pushing. The striver path is asserting itself again."
        case .provider:  return "The focus on stability is back. The provider instinct won this year."
        case .connector: return "The people came first again. The connector thread is back."
        case .survivor:  return "You made it through another year under pressure. Still here. Still a survivor."
        }
    }

    private func traitLifePathResonance(trait: PersonalityTrait, path: LifePathID) -> String {
        switch (trait, path) {
        case (.disciplined, .scholar):   return "The discipline that started early made this almost inevitable."
        case (.disciplined, .striver):   return "You were always going to grind. The discipline just made it efficient."
        case (.disciplined, .provider):  return "The structure you built around yourself is paying off in stability."
        case (.impulsive, .striver):     return "The impulsive energy found an outlet in hustle. That's something."
        case (.impulsive, .connector):   return "The impulsive streak kept you in the room with people. That's what built this."
        case (.impulsive, .survivor):    return "Some of the pressure came from the quick decisions. You survived those too."
        case (.charismatic, .connector): return "This was always where the charisma was going to lead."
        case (.charismatic, .striver):   return "The charm opened doors. The work kept them open."
        case (.anxious, .scholar):       return "The anxiety that made you overthink everything also made you study everything."
        case (.anxious, .survivor):      return "The anxiety that warned you about everything also kept you cautious enough to make it."
        case (.anxious, .provider):      return "The constant worry about stability is exactly what built the stability."
        case (.lucky, .striver):         return "The lucky breaks gave you runway. The work is what you did with it."
        case (.lucky, .provider):        return "A few things broke your way financially. You were smart enough to hold onto them."
        case (.lucky, .survivor):        return "The luck ran out in places. You survived the gaps."
        default:                         return ""
        }
    }

    private func strongestLifePath(for state: GameState) -> LifePathID? {
        let ranked = lifePaths
            .map { definition in
                (definition.id, definition.score(state), definition.minimumScore)
            }
            .filter { $0.1 >= $0.2 }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.2 > rhs.2
                }
                return lhs.1 > rhs.1
            }

        return ranked.first?.0
    }
}

struct LifeSummarySystem {
    private let progressSystem = ProgressSystem()
    private let legacySignalSystem = LegacySignalSystem()
    private let endgameSystem = EndgameSummarySystem()

    func build(from state: GameState) -> LifeSummarySnapshot {
        let path = state.progress.finalLifePath ?? state.progress.currentLifePath
        let pathTitle = path.map { LifePathCatalog.profile(for: $0).title } ?? "Unfinished"
        let achievements = achievementLines(from: state)
        let regrets = regretLines(from: state)
        let axes = legacySignalSystem.axes(for: state)

        return LifeSummarySnapshot(
            headline: headline(for: state, pathTitle: pathTitle),
            closingLine: closingLine(for: state, achievements: achievements, regrets: regrets),
            lifePathTitle: pathTitle,
            relationshipLine: relationshipLine(for: state),
            reputationLine: reputationLine(for: state),
            achievements: Array(achievements.prefix(3)),
            regrets: Array(regrets.prefix(3)),
            legacyScore: state.progress.legacyScore,
            legacyPointsEarned: progressSystem.legacyPointsEarned(from: state),
            legacyAxes: axes,
            legacySignals: legacySignalSystem.compactSignals(for: state),
            endgameMode: endgameSystem.mode(for: state),
            meaningLine: endgameSystem.meaningLine(for: state, axes: axes),
            inheritedPressureSummary: inheritancePressureSummary(for: state, axes: axes)
        )
    }

    private func inheritancePressureSummary(for state: GameState, axes: [LifeSummarySnapshot.LegacyAxis]) -> String {
        let warningAxes = axes.filter { $0.tone == .warning }.map(\.title)
        if !warningAxes.isEmpty {
            return "Inherited pressure: \(warningAxes.prefix(2).joined(separator: ", "))"
        }
        if state.finance.totalWealth >= 500_000 {
            return "Inherited floor: estate and reputation"
        }
        if state.relationships.privateReputation >= 65 {
            return "Inherited warmth: people still answer"
        }
        return "Inherited pressure is light"
    }

    private func headline(for state: GameState, pathTitle: String) -> String {
        // P5: Higher resolution headlines for edge cases
        if state.player.age >= 100 { return "A Century of Change and Survival" }
        if state.fame.notoriety >= 85 { return "An Infamy That Outlives the Man" }
        if state.fame.culturalFame >= 85 { return "A Name etched into the Culture" }
        if state.fame.notoriety >= 70 { return "A Name Nobody Could Ignore" }
        if state.fame.culturalFame >= 70 { return "The World Learned Your Name" }
        
        if state.assets.lifestyleScore >= 95 { return "The Architect of a High Life" }
        if state.assets.lifestyleScore >= 80 { return "A Titan of the High Life" }
        if state.finance.portfolio.totalValue >= 1_000_000 { return "A Titan of the Markets" }
        
        let closeChildren = state.family.children.filter { $0.bondWithPlayer >= 75 }
        if closeChildren.count >= 3 { return "A Foundation Built of Family" }
        if !closeChildren.isEmpty { return "You Left People Who Remember" }
        
        if state.specialCareer.sportsOwner.portfolio.count >= 2 && state.specialCareer.sportsOwner.totalValuation >= 10_000_000_000 {
            return "You Owned the League"
        }
        if state.finance.totalWealth >= 2_000_000_000 { return "You Owned the League" }
        if state.finance.totalWealth >= 2_000_000 { return "You Built an Empire That Lasted" }
        if state.finance.totalWealth >= 1_000_000 { return "You Built Something That Lasted" }
        
        if state.player.age >= 90 { return "A Master of the Long Game" }
        if state.player.age >= 80 { return "A Long Life, Fully Lived" }
        
        if state.resilience == .grounded && state.player.age >= 75 { return "A Grounded Life, Fought and Won" }
        
        return "The End of a \(pathTitle) Life"
    }

    private func closingLine(for state: GameState, achievements: [String], regrets: [String]) -> String {
        let shape = LifeShapeResolver.resolveOrPragmatic(from: state)
        
        if achievements.isEmpty, regrets.isEmpty {
            return "The years passed quietly. The life was still yours."
        }
        
        if state.family.childCount > 0 {
            let closeKids = state.family.children.filter { $0.bondWithPlayer >= 60 }.count
            if closeKids > 0 {
                return "Your life ends here. Its consequences live on in the ones you raised."
            }
            return "Your life ends here. Its consequences do not."
        }
        
        switch shape {
        case .drivenCurrent:
            return "The race is over. You finished exactly where you were aiming."
        case .looseEdges:
            return "The final chapter was quiet, the edges finally softening."
        default:
            if regrets.count > achievements.count {
                return "What hurt mattered. So did the fact that you kept going."
            }
            return "The choices are over. The shape they made remains."
        }
    }

    private func relationshipLine(for state: GameState) -> String {
        let closeChildren = state.family.children.filter { $0.bondWithPlayer >= 65 }.count
        let familyCount = state.family.childCount
        
        if state.relationships.hasSpouse, closeChildren > 0 {
            return "You leave a partner and \(closeChildren) close \(closeChildren == 1 ? "child" : "children") behind."
        }
        if state.relationships.hasSpouse {
            return "Your partner was still beside you at the end."
        }
        if closeChildren > 0 {
            return "\(closeChildren) \(closeChildren == 1 ? "child carries" : "children carry") a close memory of you."
        }
        if familyCount > 0 {
            return "The children are still there, even if the distance was never fully closed."
        }
        
        if state.relationships.friends.strongestBond >= 70 {
            return "The friends you chose became the family that stayed."
        }
        if state.relationships.friends.strongestBond >= 50 {
            return "At least one friendship held when it mattered."
        }
        
        if state.finance.totalWealth >= 500_000 {
            return "Your legacy lives in the empire you built, rather than the people you left."
        }
        
        return "The final years were mostly yours to carry."
    }

    private func reputationLine(for state: GameState) -> String {
        if state.fame.notoriety >= 80 { return "Your name survives as a warning to those who follow." }
        if state.fame.notoriety >= 60 { return "Your name survives as a dark legend." }
        if state.fame.culturalFame >= 80 { return "Your name has become a permanent part of the culture." }
        if state.fame.culturalFame >= 60 { return "Your name outlives the person behind it." }
        
        if state.relationships.publicReputation >= 75 { return "The community remembers you with genuine generosity." }
        if state.relationships.publicReputation >= 60 { return "People remember you generously." }
        
        if state.relationships.privateReputation <= 30 { return "Those who knew you best remember the difficult, unvarnished parts." }
        if state.relationships.privateReputation <= 45 { return "The people closest to you remember the difficult parts." }
        
        return "Most people remember a complicated, ordinary human life."
    }


    private func achievementLines(from state: GameState) -> [String] {
        var lines = state.progress.unlockedMilestones.reversed().map { milestoneTitle($0.id) }
        if let highlight = state.specialCareer.athlete.careerHighlights.last {
            lines.insert(highlight, at: 0)
        }
        if state.specialCareer.founder.personalLegend >= 60 {
            lines.insert("Built a company people remembered", at: 0)
        }
        if state.assets.lifestyleScore >= 85 {
            lines.insert("Acquired world-class statement pieces", at: 0)
        }
        if state.finance.portfolio.stocks.contains(where: { $0.tickerOrSector == "TECH" && $0.totalValue > 250_000 }) {
            lines.insert("Rode the wave of the tech boom", at: 0)
        }
        if state.family.children.contains(where: { $0.adultProfile?.outcome == .thriving }) {
            lines.insert("Helped a child build a thriving life", at: 0)
        }
        if lines.isEmpty, state.player.age >= 65 {
            lines.append("Made it through \(state.player.age) years")
        }
        return unique(lines)
    }

    private func regretLines(from state: GameState) -> [String] {
        var lines: [String] = []
        if state.relationships.partnerBond > 0, state.relationships.partnerBond < 40 {
            lines.append("A close relationship was left strained")
        }
        if state.assets.lifestyleScore >= 80 && state.family.children.contains(where: { $0.bondWithPlayer < 45 }) {
            lines.append("The high life came at the cost of family distance")
        }
        if state.family.children.contains(where: { $0.bondWithPlayer < 40 }) {
            lines.append("At least one child grew up feeling the distance")
        }
        if state.finance.portfolio.lastVolatilityEventAge != nil && state.finance.totalWealth < 50_000 {
            lines.append("A market collapse stole your security")
        }
        if state.finance.financialStress >= 70 || state.finance.totalWealth < 0 {
            lines.append("Money pressure consumed too many years")
        }
        if state.healthProfile.activeConditions.count >= 2 {
            lines.append("Your body carried costs that never fully healed")
        }
        if state.specialCareer.burnout >= 70 || state.healthProfile.mentalWellness < 35 {
            lines.append("Ambition took more than you meant to give")
        }
        if state.fame.notoriety >= 65 {
            lines.append("The worst stories became part of your name")
        }
        if lines.isEmpty {
            lines.append("Some unlived versions of you remain")
        }
        return unique(lines)
    }

    private func milestoneTitle(_ id: MilestoneID) -> String {
        switch id {
        case .graduate: return "Earned an education"
        case .firstJob: return "Built a working life"
        case .homeowner: return "Made a home of your own"
        case .married: return "Chose a life with someone"
        case .millionaire: return "Built lasting wealth"
        case .longLived: return "Lived beyond ninety"
        case .raisedGoodKids: return "Raised children who found their footing"
        case .culturalIcon: return "Became a cultural icon"
        case .infamous: return "Became impossible to forget"
        case .householdName: return "Became a household name"
        }
    }

    private func unique(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values.filter { seen.insert($0).inserted }
    }
}

struct CrossDomainPressureSystem {
    func financeSpillover(for world: WorldSnapshot) -> DomainYearResult {
        financeSpillover(for: world.state)
    }

    func financeSpillover(for state: GameState) -> DomainYearResult {
        var result = DomainYearResult()

        let deficitSeverity = max(0, abs(min(0, state.finance.cashOnHand)) / 600)
        let pressureSeverity = max(0, (state.finance.financialStress - 45) / 10)
        var severity = max(pressureSeverity, deficitSeverity)

        // Resilience scaling: reduces the bite of finance → health/relationship spirals
        let scale = state.resilience.scaling.spilloverSeverityMultiplier
        severity = Int(Double(severity) * scale)

        guard state.finance.financialStress >= 45 || state.finance.cashOnHand < 0 else { return result }

        result.healthEffects = HealthEffects(
            physical: nil,
            mental: -min(7, max(1, severity) * 2),
            exercise: nil,
            nutrition: nil,
            stressManagement: -min(6, max(1, severity)),
            addCondition: nil,
            removeCondition: nil,
            hasPrimaryCare: nil
        )
        result.relationshipEffects = RelationshipEffects(
            meetNewFriend: nil,
            friendChange: -min(5, max(1, severity) * 2),
            startDating: nil,
            partnerChange: state.relationships.hasPartner ? -min(4, max(1, severity)) : nil,
            loseFriend: nil,
            breakup: nil
        )
        result.notes.append(
            DomainNote(
                title: "Pressure Spillover",
                text: financeSpilloverText(for: state),
                tags: [.finance, .health, .relationships]
            )
        )
        return result
    }

    func healthSpillover(for world: WorldSnapshot) -> DomainYearResult {
        healthSpillover(for: world.state)
    }

    func healthSpillover(for state: GameState) -> DomainYearResult {
        var result = DomainYearResult()

        let healthLoad = max(0, 48 - min(state.healthProfile.mentalWellness, state.healthProfile.physicalWellness))
        guard healthLoad > 0 else { return result }

        // Resilience scaling softens the education/career performance tax from poor health
        let scale = state.resilience.scaling.spilloverSeverityMultiplier
        let educationPenalty = min(8, max(2, Int(Double(healthLoad) * scale / 4.0)))
        let careerPenalty = min(8, max(2, Int(Double(healthLoad) * scale / 5.0)))

        if state.player.age <= 22 || state.education.pathway == .student || state.education.pathway == .training {
            result.educationEffects = EducationEffects(
                schoolStanding: -educationPenalty,
                engagement: -max(2, educationPenalty - 1),
                attendancePressure: 2,
                activityMomentum: nil,
                schoolBelonging: nil,
                reputationRisk: nil,
                teacherSupport: nil,
                setPathway: nil,
                addCredential: nil,
                hasScholarship: nil
            )
        }

        if state.player.age >= 16 && (state.career.roleID != nil || state.career.status != .student) {
            result.careerEffects = CareerEffects(
                performance: -careerPenalty,
                yearsWorked: nil,
                setStatus: nil,
                setRoleID: nil,
                incomeBonus: nil,
                promote: nil,
                loseJob: nil
            )
        }

        if result.educationEffects != nil || result.careerEffects != nil {
            result.notes.append(
                DomainNote(
                    title: "Health Spillover",
                    text: healthSpilloverText(for: state),
                    tags: [.health, .education, .career]
                )
            )
            result.spilloverSignals.append(
                SpilloverSignal(
                    title: "Recovery Loss",
                    detail: healthSpilloverText(for: state),
                    sourceDomain: .health,
                    impactedDomain: state.player.age >= 16 && (state.career.roleID != nil || state.career.status != .student) ? .career : .education,
                    tone: .warning,
                    impactScore: 7
                )
            )
        }

        return result
    }

    func housingSpillover(for world: WorldSnapshot) -> DomainYearResult {
        housingSpillover(for: world.state)
    }

    func housingSpillover(for state: GameState) -> DomainYearResult {
        var result = DomainYearResult()

        guard state.housing.housingStability < 42 || state.housing.livingArrangement == .couchSurfing else { return result }

        var severity = state.housing.livingArrangement == .couchSurfing ? 6 : max(2, (45 - state.housing.housingStability) / 6)

        // Resilience scaling: bad housing hurts less hard in resilient mode
        let scale = state.resilience.scaling.spilloverSeverityMultiplier
        severity = Int(Double(severity) * scale)
        result.financeEffects = FinanceEffects(
            cashDelta: nil,
            livingCostDelta: 250 * severity,
            educationCostDelta: nil,
            dependentCostDelta: nil,
            discretionaryCostDelta: nil,
            financialStressDelta: min(8, severity),
            setRegionPolicyID: nil
        )
        result.healthEffects = HealthEffects(
            physical: nil,
            mental: -min(6, severity),
            exercise: nil,
            nutrition: nil,
            stressManagement: -min(5, severity - 1),
            addCondition: nil,
            removeCondition: nil,
            hasPrimaryCare: nil
        )
        result.notes.append(
            DomainNote(
                title: "Housing Spillover",
                text: housingSpilloverText(for: state),
                tags: [.housing, .finance, .health]
            )
        )
        result.spilloverSignals.append(
            SpilloverSignal(
                title: "Housing Drag",
                detail: housingSpilloverText(for: state),
                sourceDomain: .housing,
                impactedDomain: .finance,
                tone: .warning,
                impactScore: 7
            )
        )
        return result
    }

    func ageCheckpoint(for world: WorldSnapshot) -> DomainYearResult {
        ageCheckpoint(for: world.state)
    }

    func ageCheckpoint(for state: GameState) -> DomainYearResult {
        var result = DomainYearResult()

        switch state.player.age {
        case 15:
            result.notes.append(
                DomainNote(
                    title: "Age 15",
                    text: "Age 15 brought your first real taste of independence pressure. Money, image, and future direction started sticking to each other.",
                    tags: [.progress, .education, .relationships]
                )
            )
        case 16:
            result.notes.append(
                DomainNote(
                    title: "Age 16",
                    text: "Age 16 opened real work search and stronger side-income pressure. Childhood is already narrowing.",
                    tags: [.progress, .career, .finance]
                )
            )
        case 17:
            result.notes.append(
                DomainNote(
                    title: "Age 17",
                    text: "Age 17 opened the training escape hatch. The shape of adulthood is getting harder to delay.",
                    tags: [.progress, .education, .career]
                )
            )
        case 18:
            result.notes.append(
                DomainNote(
                    title: "Age 18",
                    text: "Age 18 forced the school-to-adult transition. Work, debt, and consequence now land harder.",
                    tags: [.progress, .education, .career, .finance]
                )
            )
        case 19, 20:
            result.notes.append(
                DomainNote(
                    title: "Early Adult Test",
                    text: "This was a proving year. Your education path now has to survive money pressure, fatigue, and the first real test of fit.",
                    tags: [.progress, .education, .finance, .health]
                )
            )
        case 21, 22:
            result.notes.append(
                DomainNote(
                    title: "Direction Locked In",
                    text: "The cushion is mostly gone now. Completion, stall-out, or redirection will start defining the next chapter.",
                    tags: [.progress, .education, .career]
                )
            )
        default:
            break
        }

        return result
    }

    private func financeSpilloverText(for state: GameState) -> String {
        let base: String
        switch state.narrativeArcs.currentMoodTone {
        case .guarded, .cornered:
            base = "Money pressure tightened the whole mood of the year and leaked into recovery and relationships."
        case .hopeful:
            base = "Even with some momentum, money pressure still leaked into recovery and relationships this year."
        default:
            base = "Money pressure leaked into your recovery and relationships this year."
        }

        // Side addition for immersion: dossier + ledger heat makes pressure feel personal (not main focus, just texture)
        if let d = state.childhoodDossier, state.player.age <= 22 {
            if d.aptitudes.entrepreneurial >= 55 {
                return base + " Your early wiring turns the squeeze into something that also sharpens your edge."
            }
            if d.aptitudes.physical >= 55 {
                return base + " The body you brought from childhood knows this kind of load."
            }
        }
        let recentAutonomy = state.correlationLedger.recentSignals(kind: .npcAutonomyPulse).count + state.correlationLedger.recentSignals(kind: .worldAutonomyPulse).count
        if recentAutonomy > 0 {
            return base + " The outside world kept moving too."
        }

        // Phase 5: Visceral differentiation by Life Feel
        if state.resilience == .grounded {
            return base + " It hit harder than it might have in a more forgiving run. The fight back, when it came, felt bigger."
        } else {
            return base + " You absorbed some of the worst of it. The advantages compounded, but the scars stayed visible longer."
        }
    }

    private func healthSpilloverText(for state: GameState) -> String {
        let base: String
        switch state.narrativeArcs.currentMoodTone {
        case .focused:
            base = "Low recovery turned a disciplined year into a harder climb at school and work."
        case .tense, .cornered:
            base = "Low recovery dragged on school and work just as the year was already tightening."
        default:
            base = "Low recovery dragged on your school and work momentum."
        }

        // Side addition: dossier makes health spillover feel like continuation of early wiring
        if let d = state.childhoodDossier, state.player.age <= 22 {
            if d.aptitudes.physical >= 55 {
                return base + " The physical shape you arrived with at 14 makes the drag feel almost familiar."
            }
        }

        if state.resilience == .grounded {
            let shape = LifeShapeResolver.resolveOrPragmatic(from: state)
            let shapeTail = shape == .drivenCurrent ? " The drive that kept you going also made the recovery feel harder-won." : (shape == .looseEdges ? " The looseness you allowed made the drag linger." : "")
            return base + " In a Grounded run, the body and mind remember the cost longer. The fight back, when it comes, feels bigger." + shapeTail
        } else {
            // P4-5: resilient compounds but scars visible
            return base + " You absorbed it and kept moving. The scars stayed visible in how the next year started."
        }
    }

    private func housingSpilloverText(for state: GameState) -> String {
        let base: String
        switch state.narrativeArcs.currentMoodTone {
        case .guarded, .isolated:
            base = "An unstable living setup kept the year feeling conditional, making money and recovery harder to hold together."
        default:
            base = "An unstable living setup made money and recovery harder to hold together."
        }

        if state.resilience == .grounded {
            // P4-5: grounded vs resilient housing divergence
            return base + " Grounded lives leave less margin for a bad roof over your head. When it finally stabilizes, the win feels earned."
        } else {
            return base + " You found ways to keep it from unraveling everything — but the instability left a quiet tax on the years after."
        }
    }
}

struct YearlyOutcomeAggregator {
    func summarize(
        before: GameState,
        after: GameState,
        results: [DomainYearResult],
        plannedActions: [PlayerYearAction] = []
    ) -> YearlyOutcomeSummary {
        let deltaItems = buildDeltaItems(before: before, after: after)
        let structuredSpillovers = results
            .flatMap(\.spilloverSignals)
            .sorted { lhs, rhs in
                abs(lhs.impactScore) > abs(rhs.impactScore)
            }
            .prefix(3)
            .map {
                YearlyOutcomeItem(
                    title: $0.title,
                    detail: $0.detail,
                    domain: $0.impactedDomain,
                    tone: $0.tone,
                    impactScore: $0.impactScore
                )
            }
        let resultSpillovers = results
            .flatMap(\.notes)
            .filter { note in
                let tagSet = Set(note.tags)
                return tagSet.contains(.finance) && tagSet.contains(.health)
                    || tagSet.contains(.finance) && tagSet.contains(.relationships)
                    || tagSet.contains(.housing) && tagSet.contains(.health)
                    || tagSet.contains(.education) && tagSet.contains(.career)
            }
            .sorted { lhs, rhs in
                spilloverPriority(for: lhs) > spilloverPriority(for: rhs)
            }
            .prefix(max(0, 3 - structuredSpillovers.count))
            .map { note in
                let fightingBack = note.title == "Fighting Back"
                return YearlyOutcomeItem(
                    title: note.title,
                    detail: note.text,
                    domain: dominantDomain(for: note.tags, fallback: .lifeEvent),
                    tone: fightingBack || note.title.lowercased().contains("recovery") ? .positive : .warning,
                    impactScore: fightingBack ? 8 : 5
                )
            }

        let resultCheckpointTitles: Set<String> = [
            "Early Adult Test",
            "Direction Locked In"
        ]
        let resultCheckpoint = results
            .flatMap(\.notes)
            .first(where: { $0.title.hasPrefix("Age ") || resultCheckpointTitles.contains($0.title) })
            .map {
                YearlyOutcomeItem(
                    title: $0.title,
                    detail: $0.text,
                    domain: .progress,
                    tone: .neutral,
                    impactScore: 4
                )
            }
        let lateGameNarrative = lateGameNarrativeItems(before: before, after: after)
        let spillovers = Array((structuredSpillovers + resultSpillovers + lateGameNarrative.spillovers).prefix(3))
        let checkpoint = resultCheckpoint ?? lateGameNarrative.checkpoint

        let sorted = deltaItems.sorted { abs($0.impactScore) > abs($1.impactScore) }
        let headlines = Array(sorted.prefix(3))
        let topProblem = sorted.filter { $0.tone == .warning }.max { abs($0.impactScore) < abs($1.impactScore) }
        let topOpportunity = sorted.filter { $0.tone == .positive }.max { abs($0.impactScore) < abs($1.impactScore) }
        let momentum = momentumItem(before: before, after: after)
        let focusOutcome = focusOutcomeItem(before: before, after: after, plannedActions: plannedActions)
        let mainTradeoff = mainTradeoffItem(summaryHeadlines: sorted, spillovers: spillovers)
        let nextYearPressure = nextYearPressureItem(after: after, topProblem: topProblem, spillovers: spillovers)
        let yearlyStanceOutcome = yearlyStanceOutcomeItem(after: after)

        return YearlyOutcomeSummary(
            age: after.player.age,
            headlines: headlines,
            topProblem: topProblem,
            topOpportunity: topOpportunity,
            momentum: momentum,
            spillovers: spillovers,
            checkpoint: checkpoint,
            focusOutcome: focusOutcome,
            mainTradeoff: mainTradeoff,
            nextYearPressure: nextYearPressure,
            yearlyStanceOutcome: yearlyStanceOutcome
        )
    }

    private func yearlyStanceOutcomeItem(after: GameState) -> YearlyOutcomeItem? {
        guard let stance = after.yearlyStance.lastCompletedStance,
              let detail = after.yearlyStance.lastOutcomeLine else { return nil }

        let tone: YearlyOutcomeTone = detail.contains("could not") || detail.contains("delayed") || detail.contains("Drift") || detail.contains("without")
            ? .warning
            : .positive
        return YearlyOutcomeItem(
            title: "Yearly Goal",
            detail: "\(stance.title): \(detail)",
            domain: domainTag(for: stance.domain ?? .health),
            tone: tone,
            impactScore: tone == .positive ? 5 : -5
        )
    }

    private func buildDeltaItems(before: GameState, after: GameState) -> [YearlyOutcomeItem] {
        var items: [YearlyOutcomeItem] = []

        appendDelta(
            title: "Cash Position",
            before: before.finance.cashOnHand,
            after: after.finance.cashOnHand,
            domain: .finance,
            items: &items,
            formatter: { $0 >= 0 ? "+$\($0)" : "-$\(abs($0))" },
            positiveWhenIncrease: true
        )
        appendDelta(
            title: "Invested Wealth",
            before: before.finance.investedBalance,
            after: after.finance.investedBalance,
            domain: .finance,
            items: &items,
            formatter: { "$\($0)" },
            positiveWhenIncrease: true
        )
        appendDelta(title: "Financial Stress", before: before.finance.financialStress, after: after.finance.financialStress, domain: .finance, items: &items, formatter: { "\($0)" }, positiveWhenIncrease: false)
        appendDelta(title: "School Standing", before: before.education.schoolStanding, after: after.education.schoolStanding, domain: .education, items: &items, formatter: { "\($0)" }, positiveWhenIncrease: true)
        appendDelta(title: "Career Performance", before: before.career.performance, after: after.career.performance, domain: .career, items: &items, formatter: { "\($0)" }, positiveWhenIncrease: true)
        appendDelta(title: "Mental Health", before: before.healthProfile.mentalWellness, after: after.healthProfile.mentalWellness, domain: .health, items: &items, formatter: { "\($0)" }, positiveWhenIncrease: true)
        appendDelta(title: "Overall Health", before: before.player.health, after: after.player.health, domain: .health, items: &items, formatter: { "\($0)" }, positiveWhenIncrease: true)
        appendDelta(title: "Housing Stability", before: before.housing.housingStability, after: after.housing.housingStability, domain: .housing, items: &items, formatter: { "\($0)" }, positiveWhenIncrease: true)
        appendDelta(title: "Closest Bond", before: max(before.relationships.friends.strongestBond, before.relationships.partnerBond), after: max(after.relationships.friends.strongestBond, after.relationships.partnerBond), domain: .relationships, items: &items, formatter: { "\($0)" }, positiveWhenIncrease: true)

        if before.education.pathway != after.education.pathway {
            items.append(
                YearlyOutcomeItem(
                    title: "Education Path",
                    detail: "\(before.education.pathway.rawValue.capitalized) -> \(after.education.pathway.rawValue.capitalized)",
                    domain: .education,
                    tone: after.education.pathway == .graduate || after.education.pathway == .training ? .positive : .warning,
                    impactScore: after.education.pathway == .graduate || after.education.pathway == .training ? 10 : -10
                )
            )
        }

        if before.housing.livingArrangement != after.housing.livingArrangement {
            let movedToSaferHousing = after.housing.livingArrangement != .couchSurfing && after.housing.housingStability >= before.housing.housingStability
            items.append(
                YearlyOutcomeItem(
                    title: "Living Situation",
                    detail: "\(housingLabel(before.housing.livingArrangement)) -> \(housingLabel(after.housing.livingArrangement))",
                    domain: .housing,
                    tone: movedToSaferHousing ? .positive : .warning,
                    impactScore: movedToSaferHousing ? 8 : -8
                )
            )
        }

        return items
    }

    private func appendDelta(
        title: String,
        before: Int,
        after: Int,
        domain: HistoryDomainTag,
        items: inout [YearlyOutcomeItem],
        formatter: (Int) -> String,
        positiveWhenIncrease: Bool
    ) {
        let delta = after - before
        guard abs(delta) >= 3 else { return }

        let isPositive = positiveWhenIncrease ? delta > 0 : delta < 0
        items.append(
            YearlyOutcomeItem(
                title: title,
                detail: "\(formatter(before)) -> \(formatter(after))",
                domain: domain,
                tone: isPositive ? .positive : .warning,
                impactScore: isPositive ? abs(delta) : -abs(delta)
            )
        )
    }

    private func momentumItem(before: GameState, after: GameState) -> YearlyOutcomeItem? {
        let moodSuffix = after.narrativeArcs.currentSignalLine.map { " " + $0 } ?? ""
        if after.finance.lastYearBalanceDelta > 0 && after.career.performance >= before.career.performance && after.healthProfile.mentalWellness >= before.healthProfile.mentalWellness {
            return YearlyOutcomeItem(
                title: "Momentum",
                detail: "This year held together across work, money, and recovery.\(moodSuffix)",
                domain: .progress,
                tone: .positive,
                impactScore: 6
            )
        }

        if after.finance.financialStress > before.finance.financialStress && after.healthProfile.mentalWellness < before.healthProfile.mentalWellness {
            return YearlyOutcomeItem(
                title: "Momentum",
                detail: "Pressure stacked up faster than your systems could absorb it.\(moodSuffix)",
                domain: .progress,
                tone: .warning,
                impactScore: -6
            )
        }

        return YearlyOutcomeItem(
            title: "Momentum",
            detail: "The year moved, but it did not settle cleanly in either direction.\(moodSuffix)",
            domain: .progress,
            tone: .neutral,
            impactScore: 3
        )
    }

    private func focusOutcomeItem(
        before: GameState,
        after: GameState,
        plannedActions: [PlayerYearAction]
    ) -> YearlyOutcomeItem? {
        guard let action = plannedActions.first else {
            return YearlyOutcomeItem(
                title: "Pattern Outcome",
                detail: "You left the year reactive, so outside pressure had more say than your lived pattern.",
                domain: .progress,
                tone: .neutral,
                impactScore: 2
            )
        }

        let definition = ActionChoiceCatalog.definition(for: action.choiceID)
        let detail: String
        let tone: YearlyOutcomeTone
        let impactScore: Int

        switch action.domain {
        case .finance:
            let delta = after.finance.cashOnHand - before.finance.cashOnHand
            tone = delta >= 0 ? .positive : .warning
            impactScore = max(4, abs(delta / 500))
            detail = delta >= 0
                ? "\(definition.title) gave the year more financial control."
                : "\(definition.title) still left the money pressure ahead of you."
        case .health:
            let delta = after.healthProfile.mentalWellness - before.healthProfile.mentalWellness
            tone = delta >= 0 ? .positive : .warning
            impactScore = max(4, abs(delta))
            detail = delta >= 0
                ? "\(definition.title) made the year more survivable for your body."
                : "\(definition.title) did not stop recovery from slipping."
        case .relationships:
            let beforeBond = max(before.relationships.friends.strongestBond, before.relationships.partnerBond)
            let afterBond = max(after.relationships.friends.strongestBond, after.relationships.partnerBond)
            let delta = afterBond - beforeBond
            tone = delta >= 0 ? .positive : .warning
            impactScore = max(4, abs(delta))
            detail = delta >= 0
                ? "\(definition.title) made closeness feel more intentional."
                : "\(definition.title) still let distance build where it mattered."
        case .education, .career, .crime, .military:
            let beforeScore = (action.domain == .education) ? before.education.schoolStanding : (action.domain == .military ? before.military.discipline : before.career.performance)
            let afterScore = (action.domain == .education) ? after.education.schoolStanding : (action.domain == .military ? after.military.discipline : after.career.performance)
            let delta = afterScore - beforeScore
            tone = delta >= 0 ? .positive : .warning
            impactScore = max(4, abs(delta))
            detail = delta >= 0
                ? "\(definition.title) gave the year a cleaner sense of direction."
                : "\(definition.title) raised the stakes without fully paying off."
        case .legal:
            let changed = before.legal.stage != after.legal.stage
            tone = after.legal.isInCustody ? .warning : (changed ? .neutral : .warning)
            impactScore = after.legal.isInCustody ? 10 : 6
            detail = "\(definition.title) shaped how the case moved."
        case .family, .identity:
            tone = .neutral
            impactScore = 5
            detail = "\(definition.title) shaped your personal path."
        case .play:
            let delta = after.activities.recoveryBalance - before.activities.recoveryBalance
            tone = delta >= 0 ? .positive : .neutral
            impactScore = max(4, abs(delta / 2))
            detail = "\(definition.title) made the year feel a little more alive."
        }

        return YearlyOutcomeItem(
            title: "Pattern Outcome",
            detail: detail,
            domain: domainTag(for: action.domain),
            tone: tone,
            impactScore: tone == .warning ? -impactScore : impactScore
        )
    }

    private func mainTradeoffItem(
        summaryHeadlines: [YearlyOutcomeItem],
        spillovers: [YearlyOutcomeItem]
    ) -> YearlyOutcomeItem? {
        guard let gain = summaryHeadlines.first(where: { $0.tone == .positive }) else {
            return spillovers.first.map {
                YearlyOutcomeItem(
                    title: "Main Tradeoff",
                    detail: "The year stayed survivable, but \($0.title.lowercased()) kept charging rent in the background.",
                    domain: $0.domain,
                    tone: $0.tone,
                    impactScore: $0.impactScore
                )
            }
        }
        guard let cost = spillovers.first ?? summaryHeadlines.first(where: { $0.tone == .warning }) else {
            return nil
        }
        return YearlyOutcomeItem(
            title: "Main Tradeoff",
            detail: "\(gain.title) improved, but \(cost.title.lowercased()) became the lingering cost that made the gain feel earned.",
            domain: cost.domain,
            tone: .warning,
            impactScore: -max(5, abs(cost.impactScore))
        )
    }

    private func nextYearPressureItem(
        after: GameState,
        topProblem: YearlyOutcomeItem?,
        spillovers: [YearlyOutcomeItem]
    ) -> YearlyOutcomeItem? {
        if let strongest = after.consequences.pressureByDomain.max(by: { $0.value < $1.value }), strongest.value >= 18 {
            let domain = dominantDomain(for: strongest.key)
            let detailSource = spillovers.first(where: { $0.domain == domain }) ?? topProblem
            return YearlyOutcomeItem(
                title: "Next-Year Pressure",
                detail: detailSource.map { "\(dominantPressureLabel(for: strongest.key)) is still carrying forward. \($0.detail)" }
                    ?? "\(dominantPressureLabel(for: strongest.key)) is the part of the year that did not close cleanly.",
                domain: domain,
                tone: strongest.value >= 30 ? .warning : .neutral,
                impactScore: strongest.value >= 30 ? -8 : -4
            )
        }

        return topProblem.map {
            YearlyOutcomeItem(
                title: "Next-Year Pressure",
                detail: "If nothing changes, \($0.title.lowercased()) is the most likely place next year tightens first.",
                domain: $0.domain,
                tone: .neutral,
                impactScore: -3
            )
        }
    }

    private func lateGameNarrativeItems(before: GameState, after: GameState) -> (spillovers: [YearlyOutcomeItem], checkpoint: YearlyOutcomeItem?) {
        guard after.player.age >= 30 else {
            return ([], nil)
        }

        var spillovers: [YearlyOutcomeItem] = []
        var checkpoint: YearlyOutcomeItem?

        if after.assets.ownsHome
            && after.finance.financialStress >= 34
            && after.housing.housingStability >= 55 {
            spillovers.append(
                YearlyOutcomeItem(
                    title: "Ownership Drag",
                    detail: "Staying housed still worked, but ownership felt more like maintenance than relief.",
                    domain: .housing,
                    tone: .warning,
                    impactScore: -7
                )
            )
        }

        if after.family.childCount > 0
            && after.relationships.hasPartner
            && after.relationships.partnerBond < before.relationships.partnerBond
            && after.finance.financialStress >= 28 {
            spillovers.append(
                YearlyOutcomeItem(
                    title: "Family Drift",
                    detail: "Practical life kept moving, but emotional closeness started losing ground inside the family.",
                    domain: .relationships,
                    tone: .warning,
                    impactScore: -8
                )
            )
        }

        if (after.healthProfile.activeConditions.count > before.healthProfile.activeConditions.count
            || after.healthProfile.physicalWellness <= 48)
            && (after.healthProfile.habits.stressManagement <= 42 || after.healthProfile.mentalWellness <= 48) {
            spillovers.append(
                YearlyOutcomeItem(
                    title: "Deferred Cost",
                    detail: "Older strain stopped feeling temporary and started showing up as a more durable health bill.",
                    domain: .health,
                    tone: .warning,
                    impactScore: -9
                )
            )
        }

        if after.player.age >= 35
            && after.career.yearsWorked >= 8
            && after.finance.lastYearBalanceDelta >= -1_500
            && after.healthProfile.mentalWellness <= 56
            && after.career.performance >= 55 {
            checkpoint = YearlyOutcomeItem(
                title: "Plateau Strain",
                detail: "Adult life was still functioning, but more of it felt like maintenance than momentum.",
                domain: .progress,
                tone: .neutral,
                impactScore: -4
            )
        } else if after.player.age >= 30
            && before.finance.lastYearBalanceDelta > 0
            && after.finance.lastYearBalanceDelta <= 0
            && before.finance.financialStress < after.finance.financialStress {
            checkpoint = YearlyOutcomeItem(
                title: "Regional Squeeze",
                detail: "The environment around your life got more expensive or less forgiving, even without a single dramatic collapse.",
                domain: .finance,
                tone: .warning,
                impactScore: -6
            )
        }

        return (spillovers, checkpoint)
    }

    private func dominantDomain(for tags: [HistoryDomainTag], fallback: HistoryDomainTag) -> HistoryDomainTag {
        tags.first(where: { $0 != .lifeEvent && $0 != .system }) ?? fallback
    }

    private func domainTag(for actionDomain: ActionDomain) -> HistoryDomainTag {
        switch actionDomain {
        case .education: return .education
        case .career: return .career
        case .crime: return .career
        case .legal: return .legal
        case .military: return .military
        case .finance: return .finance
        case .relationships: return .relationships
        case .health: return .health
        case .family: return .family
        case .identity: return .lifeEvent
        case .play: return .lifeEvent
        }
    }

    private func dominantDomain(for consequenceKey: String) -> HistoryDomainTag {
        switch consequenceKey {
        case "education": return .education
        case "career": return .career
        case "finance": return .finance
        case "relationships": return .relationships
        case "health": return .health
        case "housing": return .housing
        default: return .lifeEvent
        }
    }

    private func dominantPressureLabel(for consequenceKey: String) -> String {
        switch consequenceKey {
        case "education": return "School pressure"
        case "career": return "Career pressure"
        case "finance": return "Money pressure"
        case "relationships": return "Relationship pressure"
        case "health": return "Health pressure"
        case "housing": return "Housing pressure"
        default: return "Unresolved pressure"
        }
    }

    private func spilloverPriority(for note: DomainNote) -> Int {
        switch note.title {
        case "Fighting Back":
            return 6
        case "Pressure Spillover":
            return 4
        case "Housing Spillover":
            return 3
        case "Health Spillover":
            return 2
        default:
            return 1
        }
    }

    private func housingLabel(_ arrangement: LivingArrangement) -> String {
        switch arrangement {
        case .familyHome: return "Family Home"
        case .roommates: return "Roommates"
        case .soloRenting: return "Solo Rent"
        case .ownerOccupied: return "Owner Occupied"
        case .couchSurfing: return "Couch Surfing"
        }
    }
}

enum SimulationDomain {
    case actions
    case traits
    case trajectory
    case education
    case career
    case specialCareer
    case military
    case crime
    case legal
    case economy
    case investments
    case housing
    case relationships
    case family
    case finance
    case health
    case assets
    case luxury
    case progress
    case world
    case npcAutonomy
}

struct SystemRegistry {
    func isActive(_ domain: SimulationDomain, in world: WorldSnapshot) -> Bool {
        let state = world.state
        let custodyRestrictionsActive = state.legal.isInCustody
            && (state.legal.custodyStartedAge ?? state.player.age) < state.player.age
        switch domain {
        case .actions:
            return !state.pendingActions.isEmpty
        case .traits:
            return !state.player.traits.isEmpty
        case .trajectory:
            return true
        case .education:
            return state.player.age <= 22 || state.education.pathway == .student || state.education.pathway == .training
        case .career:
            return !custodyRestrictionsActive && (state.player.age >= 16 || state.career.roleID != nil || state.career.status != .student)
        case .specialCareer:
            return !custodyRestrictionsActive && state.player.age >= 18
        case .military:
            return !custodyRestrictionsActive && (state.military.track != .inactive || state.player.age >= 18)
        case .crime:
            return !custodyRestrictionsActive && state.player.age >= 18 && (
                state.crime.status != .inactive ||
                state.pendingActions.contains(where: { $0.domain == .crime }) ||
                state.finance.cashOnHand < 600
            )
        case .legal:
            return state.player.age >= 18 && (
                state.legal.stage != .inactive ||
                !state.legal.pendingExposures.isEmpty ||
                !state.legal.convictions.isEmpty ||
                state.pendingActions.contains(where: { $0.domain == .legal })
            )
        case .economy:
            return state.player.age >= 18
        case .investments:
            return !custodyRestrictionsActive && state.player.age >= 18 && (
                state.finance.hasInvestments ||
                (state.finance.lastYearBalanceDelta >= 0 && state.finance.cashOnHand >= 6_000)
            )
        case .housing:
            return !custodyRestrictionsActive && (state.player.age >= 18 || state.housing.livingArrangement != .familyHome)
        case .relationships:
            return state.player.age >= 12 || !state.relationships.friends.isEmpty || state.relationships.hasPartner
        case .family:
            return (state.player.age >= 18 && state.relationships.hasPartner) || state.family.isPregnant || state.family.childCount > 0 || state.family.postpartumYearsRemaining > 0
        case .finance:
            return state.player.age >= 14 || state.finance.cashOnHand != 250 || state.family.childCount > 0 || state.family.isPregnant
        case .health:
            return true
        case .assets:
            return !custodyRestrictionsActive && (state.player.age >= 18 || state.assets.ownsHome || state.assets.isSavingForHome || !state.finance.portfolio.rentals.isEmpty)
        case .luxury:
            return !custodyRestrictionsActive && (state.assets.lifestyleScore >= 75 || state.finance.totalWealth >= 50_000_000)
        case .progress:
            return true
        case .world:
            return true
        case .npcAutonomy:
            return state.player.age >= 4 && (state.relationships.hasPartner || !state.relationships.friends.isEmpty)
        }
    }

    func isActive(_ domain: SimulationDomain, for state: GameState) -> Bool {
        isActive(domain, in: WorldSnapshotBuilder().build(from: state))
    }
}
