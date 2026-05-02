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
        result.notes.append(DomainNote(title: "Legacy", text: "This life will be remembered as a \(profile.title.lowercased()) life."))
        return result
    }

    /// Extracts meta-progression data from a finished game state.
    func harvestLegacy(from state: GameState, meta: inout MetaState) {
        meta.totalLivesPlayed += 1
        meta.totalYearsLived += state.player.age

        // Calculate legacy points based on milestones and age
        var pointsEarned = state.player.age / 10 // 1 point for every 10 years lived

        for definition in definitions {
            if definition.requirement(state) {
                pointsEarned += definition.legacyScore / 5 // Convert 5 score to 1 legacy point
            }
        }

        meta.legacyPoints += pointsEarned

        // Generation Flags
        if state.player.age >= 65 {
            meta.generationFlags.insert("reached_retirement")
        }

        if state.finance.totalWealth >= 1_000_000,
           state.player.age >= balanceProfile.wealth.millionaireMinimumAge,
           state.finance.hasMillionaireFoundation(using: balanceProfile) {
            meta.generationFlags.insert("wealthy_dynasty")
        }

        if state.education.pathway == .graduate && state.player.smarts >= 90 {
            meta.generationFlags.insert("academic_legend")
        }
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

struct CrossDomainPressureSystem {
    func financeSpillover(for world: WorldSnapshot) -> DomainYearResult {
        financeSpillover(for: world.state)
    }

    func financeSpillover(for state: GameState) -> DomainYearResult {
        var result = DomainYearResult()

        let deficitSeverity = max(0, abs(min(0, state.finance.cashOnHand)) / 600)
        let pressureSeverity = max(0, (state.finance.financialStress - 45) / 10)
        let severity = max(pressureSeverity, deficitSeverity)
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

        let educationPenalty = min(8, max(2, healthLoad / 4))
        let careerPenalty = min(8, max(2, healthLoad / 5))

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

        let severity = state.housing.livingArrangement == .couchSurfing ? 6 : max(2, (45 - state.housing.housingStability) / 6)
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
        switch state.narrativeArcs.currentMoodTone {
        case .guarded, .cornered:
            return "Money pressure tightened the whole mood of the year and leaked into recovery and relationships."
        case .hopeful:
            return "Even with some momentum, money pressure still leaked into recovery and relationships this year."
        default:
            return "Money pressure leaked into your recovery and relationships this year."
        }
    }

    private func healthSpilloverText(for state: GameState) -> String {
        switch state.narrativeArcs.currentMoodTone {
        case .focused:
            return "Low recovery turned a disciplined year into a harder climb at school and work."
        case .tense, .cornered:
            return "Low recovery dragged on school and work just as the year was already tightening."
        default:
            return "Low recovery dragged on your school and work momentum."
        }
    }

    private func housingSpilloverText(for state: GameState) -> String {
        switch state.narrativeArcs.currentMoodTone {
        case .guarded, .isolated:
            return "An unstable living setup kept the year feeling conditional, making money and recovery harder to hold together."
        default:
            return "An unstable living setup made money and recovery harder to hold together."
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
                YearlyOutcomeItem(
                    title: note.title,
                    detail: note.text,
                    domain: dominantDomain(for: note.tags, fallback: .lifeEvent),
                    tone: note.title.lowercased().contains("recovery") ? .positive : .warning,
                    impactScore: 5
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
            nextYearPressure: nextYearPressure
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
                title: "Focus Outcome",
                detail: "You left the year reactive, so outside pressure had more say than your own plan.",
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
        case .education, .career, .crime:
            let beforeScore = action.domain == .education ? before.education.schoolStanding : before.career.performance
            let afterScore = action.domain == .education ? after.education.schoolStanding : after.career.performance
            let delta = afterScore - beforeScore
            tone = delta >= 0 ? .positive : .warning
            impactScore = max(4, abs(delta))
            detail = delta >= 0
                ? "\(definition.title) gave the year a cleaner sense of direction."
                : "\(definition.title) raised the stakes without fully paying off."
        }

        return YearlyOutcomeItem(
            title: "Focus Outcome",
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
        case .finance: return .finance
        case .relationships: return .relationships
        case .health: return .health
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
    case crime
    case investments
    case housing
    case relationships
    case family
    case finance
    case health
    case assets
    case progress
    case world
    case npcAutonomy
}

struct SystemRegistry {
    func isActive(_ domain: SimulationDomain, in world: WorldSnapshot) -> Bool {
        let state = world.state
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
            return state.player.age >= 16 || state.career.roleID != nil || state.career.status != .student
        case .crime:
            return state.player.age >= 18 && (
                state.crime.status != .inactive ||
                state.pendingActions.contains(where: { $0.domain == .crime }) ||
                state.finance.cashOnHand < 600
            )
        case .investments:
            return state.player.age >= 18 && (
                state.finance.hasInvestments ||
                (state.finance.lastYearBalanceDelta >= 0 && state.finance.cashOnHand >= 6_000)
            )
        case .housing:
            return state.player.age >= 18 || state.housing.livingArrangement != .familyHome
        case .relationships:
            return state.player.age >= 12 || !state.relationships.friends.isEmpty || state.relationships.hasPartner
        case .family:
            return (state.player.age >= 18 && state.relationships.hasPartner) || state.family.isPregnant || state.family.childCount > 0 || state.family.postpartumYearsRemaining > 0
        case .finance:
            return state.player.age >= 14 || state.finance.cashOnHand != 250 || state.family.childCount > 0 || state.family.isPregnant
        case .health:
            return true
        case .assets:
            return state.player.age >= 18 && (
                state.assets.ownsHome ||
                state.assets.isSavingForHome ||
                state.finance.homeDownPaymentSavings > 0 ||
                state.finance.cashOnHand >= 12_000
            )
        case .progress:
            return true
        case .world:
            return state.player.age >= 18 && (
                state.currentEra != .stable ||
                state.eraYearsRemaining <= 0 ||
                state.consequences.narrativeFlags["world_autonomy_enabled", default: 0] > 0
            )
        case .npcAutonomy:
            return state.player.age >= 12 &&
                state.consequences.narrativeFlags["npc_autonomy_enabled", default: 0] > 0 &&
                (state.relationships.hasPartner || !state.relationships.friends.isEmpty)
        }
    }

    func isActive(_ domain: SimulationDomain, for state: GameState) -> Bool {
        isActive(domain, in: WorldSnapshotBuilder().build(from: state))
    }
}
