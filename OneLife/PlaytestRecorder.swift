import Foundation

nonisolated enum PlaytestAnnotationKind: String, Codable, CaseIterable, Identifiable {
    case boring
    case weakChoice
    case confusingSystem

    var id: String { rawValue }

    var title: String {
        switch self {
        case .boring: "Boring year"
        case .weakChoice: "Weak choice"
        case .confusingSystem: "Confusing system"
        }
    }
}

nonisolated enum PlaytestRunStatus: String, Codable {
    case active, completed, abandoned
}

nonisolated enum PlaytestStyle: String, Codable, CaseIterable, Identifiable {
    case grind, social, survival, mixed

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

nonisolated struct PlaytestSource: Codable, Equatable {
    nonisolated enum Kind: String, Codable {
        case instantAction, yearlyTick, eventPresented, eventChoice, assetTransaction, recovery, ending
    }

    let kind: Kind
    let identifier: String?
    /// Captured when the input is recorded so report analysis stays detached
    /// from the live action registry and remains readable across app versions.
    let domain: String?

    @MainActor static func action(_ id: ActionID) -> Self {
        Self(
            kind: .instantAction,
            identifier: id.rawValue,
            domain: DomainActionRegistry.action(for: id).domain.rawValue
        )
    }

    @MainActor static func contextual(_ id: ContextActionID) -> Self {
        Self(kind: .instantAction, identifier: "context:\(id.rawValue)", domain: ContextActionSystem.domain(for: id).rawValue)
    }

    static func event(_ id: String) -> Self {
        Self(kind: .eventPresented, identifier: id, domain: nil)
    }

    @MainActor static func choice(eventID: String, choiceID: EventChoiceID) -> Self {
        Self(kind: .eventChoice, identifier: "\(eventID):\(choiceID.rawValue)", domain: nil)
    }

    static let yearly = Self(kind: .yearlyTick, identifier: nil, domain: nil)
    static func assetTransaction(_ identifier: String) -> Self {
        Self(kind: .assetTransaction, identifier: identifier, domain: Domain.cash.rawValue)
    }
    static let recovery = Self(kind: .recovery, identifier: nil, domain: nil)
    static let ending = Self(kind: .ending, identifier: nil, domain: nil)
}

nonisolated struct PlaytestStateSnapshot: Codable, Equatable {
    let age: Int
    let stage: String
    let cash: Int
    let school: Int
    let love: Int
    let play: Int
    let health: Int
    let looks: Int
    let reputation: Int
    let jobTier: String
    let partnerBond: Int?
    let partnerResentment: Int?
    let recovery: String?
    let mortalityPressure: String
    let isGameOver: Bool
    let worldProfile: [String]?
    let worldConditions: [String]?
    let worldHeadline: String?
    let publicHealthProfile: [String]?
    let publicHealthCondition: String?
    let assetCounts: [String: Int]?
    let movableAssetResaleValue: Int?
    let propertyEquity: Int?
    let propertyDebt: Int?
    let propertyAmenityCount: Int?
    let propertyImprovementValue: Int?
    let propertyAmenityUpkeep: Int?
    let propertyMarketValue: Int?
    let occupiedRentalCount: Int?
    let vacantRentalCount: Int?
    let rentalIncome: Int?
    let averagePropertyCondition: Int?
    let vehicleCounts: [String: Int]?
    let vehicleResaleValue: Int?
    let legalStatus: String?
    let firearmHeat: Int?
    let lawfulFirearms: Int?
    let illicitFirearms: Int?

    @MainActor init(state: LifeState) {
        age = state.character.age
        stage = state.lifeStage.rawValue
        cash = state.cash
        school = state.stats.school
        love = state.stats.love
        play = state.stats.play
        health = state.stats.health
        looks = state.stats.looks
        reputation = state.stats.rep
        jobTier = state.job.tier.rawValue
        partnerBond = state.partner?.bond
        partnerResentment = state.partner?.resentment
        recovery = state.recovery?.kind.rawValue
        mortalityPressure = state.mortalityPressure.rawValue
        isGameOver = state.isGameOver
        worldProfile = [
            state.world.profile.costEnvironment.rawValue,
            state.world.profile.laborStructure.rawValue,
            state.world.profile.safetyNet.rawValue
        ]
        worldConditions = [state.world.conditions.macro.rawValue]
            + [state.world.conditions.price?.rawValue].compactMap { $0 }
        worldHeadline = state.lastYearSummary?.worldNews?.headline
        publicHealthProfile = [
            state.world.publicHealth.healthcareCapacity.rawValue,
            state.world.publicHealth.diseaseBurden.rawValue
        ]
        publicHealthCondition = state.world.publicHealth.condition.rawValue
        assetCounts = Dictionary(uniqueKeysWithValues: AssetCategory.allCases.map {
            ($0.rawValue, state.assets.count(in: $0))
        })
        movableAssetResaleValue = state.assets.movableResaleValue
        propertyEquity = state.assets.propertyEquity
        propertyDebt = state.assets.totalMortgageDebt
        propertyAmenityCount = state.assets.properties.reduce(0) { $0 + $1.amenities.count }
        propertyImprovementValue = state.assets.properties.reduce(0) { $0 + $1.improvementValue }
        propertyAmenityUpkeep = state.assets.properties.reduce(0) { $0 + $1.amenityUpkeep }
        propertyMarketValue = state.assets.propertyMarketValue
        occupiedRentalCount = state.assets.occupiedRentalCount
        vacantRentalCount = state.assets.vacantRentalCount
        rentalIncome = state.assets.lastRentalIncome
        averagePropertyCondition = state.assets.properties.isEmpty
            ? nil
            : state.assets.properties.reduce(0) { $0 + $1.condition } / state.assets.properties.count
        vehicleCounts = Dictionary(uniqueKeysWithValues: VehicleKind.allCases.map {
            ($0.rawValue, state.assets.vehicleCount(of: $0))
        })
        vehicleResaleValue = VehicleKind.allCases.reduce(0) { $0 + state.assets.vehicleValue(of: $1) }
        let exposure = AssetSystem.firearmExposure(assets: state.assets, legal: state.legal)
        legalStatus = state.legal.record.rawValue
        firearmHeat = state.legal.firearmHeat
        lawfulFirearms = exposure.lawfulCount
        illicitFirearms = exposure.illicitCount
    }
}

nonisolated struct PlaytestDeltas: Codable, Equatable {
    let school: Int
    let cash: Int
    let love: Int
    let play: Int
    let health: Int
    let looks: Int
    let reputation: Int
    let bond: Int
    let resentment: Int

    @MainActor init(_ deltas: DeltaSummary) {
        school = deltas.school
        cash = deltas.cash
        love = deltas.love
        play = deltas.play
        health = deltas.health
        looks = deltas.looks
        reputation = deltas.rep
        bond = deltas.bond
        resentment = deltas.resentment
    }
}

nonisolated struct PlaytestMoment: Codable, Equatable, Identifiable {
    var id: Int { sequence }
    let sequence: Int
    let elapsedSeconds: TimeInterval
    let source: PlaytestSource
    let headline: String
    let narrative: String
    let deltas: PlaytestDeltas
    let isYearly: Bool
    let state: PlaytestStateSnapshot
}

nonisolated struct PlaytestAnnotation: Codable, Equatable, Identifiable {
    let id: UUID
    let elapsedSeconds: TimeInterval
    let age: Int
    let momentSequence: Int?
    let headline: String?
    let kind: PlaytestAnnotationKind
    let note: String
}

nonisolated struct PlaytestOutcomeAssessment: Codable, Equatable {
    let explanation: String
    let reviewAgrees: Bool
    let recordedAt: Date
}

nonisolated struct PlaytestSandboxDiagnostics {
    let proactiveActionCount: Int
    let uniqueActionCount: Int
    let topAction: String?
    let topActionShare: Double
    let longestRepeatedAction: String?
    let longestRepeatedActionStreak: Int
    let actionCountsByDomain: [(domain: String, count: Int)]
    let untouchedDomains: [String]
    let advancedYearCount: Int
    let yearsWithoutProactiveAction: [Int]
    let recoveryArcsStarted: Int
    let recoveryArcsResolved: Int

    var warnings: [String] {
        var values: [String] = []
        if proactiveActionCount >= 12, topActionShare >= 0.35, let topAction {
            values.append("Dominant loop: \(topAction) is \(Self.percent(topActionShare)) of proactive actions.")
        }
        if longestRepeatedActionStreak >= 4 {
            let action = longestRepeatedAction.map { "\($0) was" } ?? "One action was"
            values.append("Repetition: \(action) chosen \(longestRepeatedActionStreak) times in succession.")
        }
        if !untouchedDomains.isEmpty {
            values.append("Untouched domains: \(untouchedDomains.joined(separator: ", ")).")
        }
        if advancedYearCount >= 5,
           Double(yearsWithoutProactiveAction.count) / Double(advancedYearCount) >= 0.20 {
            values.append("Passive years: \(yearsWithoutProactiveAction.count) of \(advancedYearCount) years advanced without a proactive action.")
        }
        if recoveryArcsStarted > recoveryArcsResolved {
            values.append("Unresolved recovery: \(recoveryArcsStarted - recoveryArcsResolved) recovery arc(s) did not stabilize during the recorded life.")
        }
        return values
    }

    var markdown: String {
        let domains = actionCountsByDomain.isEmpty
            ? "- None"
            : actionCountsByDomain.map { "- \($0.domain): \($0.count)" }.joined(separator: "\n")
        let passiveYears = yearsWithoutProactiveAction.isEmpty
            ? "None"
            : yearsWithoutProactiveAction.map(String.init).joined(separator: ", ")
        let warningLines = warnings.isEmpty
            ? "- No automatic sandbox warnings"
            : warnings.map { "- \($0)" }.joined(separator: "\n")
        let top = topAction.map { "\($0) (\(Self.percent(topActionShare)))" } ?? "None"

        return """
        ## Sandbox Health

        - Proactive actions: \(proactiveActionCount)
        - Unique actions: \(uniqueActionCount)
        - Most-used action: \(top)
        - Longest repeated-action streak: \(longestRepeatedAction ?? "None") × \(longestRepeatedActionStreak)
        - Years advanced: \(advancedYearCount)
        - Years without a proactive action: \(passiveYears)
        - Recovery arcs: \(recoveryArcsResolved)/\(recoveryArcsStarted) resolved

        ### Domain Engagement

        \(domains)

        ### Automatic Warnings

        \(warningLines)
        """
    }

    private static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

nonisolated struct PlaytestCohortCount: Equatable {
    let label: String
    let count: Int
}

nonisolated struct PlaytestCohortRecommendation: Equatable {
    let origin: OriginPreset
    let style: PlaytestStyle

    var title: String { "\(origin.rawValue.capitalized) · \(style.title)" }
}

nonisolated struct PlaytestCohortSignal: Equatable {
    let id: String
    let title: String
    let domain: String?
    let seeds: [UInt64]
    let ages: [Int]
    let examples: [String]

    var runCount: Int { seeds.count }
}

nonisolated private struct PlaytestSignalAccumulator {
    let id: String
    let title: String
    let domain: String?
    var seeds: Set<UInt64> = []
    var ages: Set<Int> = []
    var examples: Set<String> = []
}

nonisolated struct PlaytestCohortAnalysis {
    let completedReportCount: Int
    let outcomeAssessmentCount: Int
    let outcomeAgreementCount: Int
    let originCounts: [PlaytestCohortCount]
    let styleCounts: [PlaytestCohortCount]
    let medianDurationMinutes: Int?
    let recurringSignals: [PlaytestCohortSignal]
    let nextRecommendation: PlaytestCohortRecommendation?
    let missingRequirements: [String]

    var isReadyForPhase2: Bool { missingRequirements.isEmpty }

    init(reports: [PlaytestRunReport]) {
        var newestBySeed: [UInt64: PlaytestRunReport] = [:]
        for report in reports where report.status == .completed {
            if let existing = newestBySeed[report.runSeed], existing.updatedAt >= report.updatedAt { continue }
            newestBySeed[report.runSeed] = report
        }
        let completed = newestBySeed.values.sorted { $0.runSeed < $1.runSeed }
        completedReportCount = completed.count
        let assessments = completed.compactMap(\.outcomeAssessment).filter {
            !$0.explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        outcomeAssessmentCount = assessments.count
        outcomeAgreementCount = assessments.filter(\.reviewAgrees).count

        let originMap = Dictionary(grouping: completed.compactMap { $0.origin?.lowercased() }, by: { $0 })
            .mapValues(\.count)
        originCounts = OriginPreset.allCases.map {
            PlaytestCohortCount(label: $0.rawValue, count: originMap[$0.rawValue, default: 0])
        }
        let styleMap = Dictionary(grouping: completed.compactMap { $0.playStyle?.lowercased() }, by: { $0 })
            .mapValues(\.count)
        styleCounts = PlaytestStyle.allCases.map {
            PlaytestCohortCount(label: $0.rawValue, count: styleMap[$0.rawValue, default: 0])
        }

        let originTargets: [OriginPreset: Int] = [.balanced: 3, .academic: 3, .social: 3]
        let requiredStyles: [PlaytestStyle] = [.grind, .social, .survival]
        let needsAnotherRun = completed.count < 10
            || originTargets.contains { originMap[$0.key.rawValue, default: 0] < $0.value }
            || requiredStyles.contains { styleMap[$0.rawValue, default: 0] == 0 }
        if needsAnotherRun {
            let recommendedOrigin = OriginPreset.allCases.max { lhs, rhs in
                let lhsDeficit = max(0, originTargets[lhs, default: 3] - originMap[lhs.rawValue, default: 0])
                let rhsDeficit = max(0, originTargets[rhs, default: 3] - originMap[rhs.rawValue, default: 0])
                if lhsDeficit == rhsDeficit {
                    return originMap[lhs.rawValue, default: 0] > originMap[rhs.rawValue, default: 0]
                }
                return lhsDeficit < rhsDeficit
            } ?? .balanced
            let recommendedStyle = requiredStyles.first {
                styleMap[$0.rawValue, default: 0] == 0
            } ?? requiredStyles.min {
                let lhsCount = styleMap[$0.rawValue, default: 0]
                let rhsCount = styleMap[$1.rawValue, default: 0]
                return lhsCount == rhsCount
                    ? requiredStyles.firstIndex(of: $0)! < requiredStyles.firstIndex(of: $1)!
                    : lhsCount < rhsCount
            } ?? .grind
            nextRecommendation = PlaytestCohortRecommendation(
                origin: recommendedOrigin,
                style: recommendedStyle
            )
        } else {
            nextRecommendation = nil
        }

        let durations = completed.map { Int(($0.elapsedSeconds / 60).rounded()) }.sorted()
        if durations.isEmpty {
            medianDurationMinutes = nil
        } else if durations.count.isMultiple(of: 2) {
            medianDurationMinutes = (durations[durations.count / 2 - 1] + durations[durations.count / 2]) / 2
        } else {
            medianDurationMinutes = durations[durations.count / 2]
        }

        var accumulators: [String: PlaytestSignalAccumulator] = [:]
        func addSignal(
            id: String,
            title: String,
            domain: String?,
            seed: UInt64,
            ages: [Int] = [],
            example: String? = nil
        ) {
            var value = accumulators[id]
                ?? PlaytestSignalAccumulator(id: id, title: title, domain: domain)
            value.seeds.insert(seed)
            value.ages.formUnion(ages)
            if let example, !example.isEmpty { value.examples.insert(example) }
            accumulators[id] = value
        }

        for report in completed {
            let diagnostics = report.sandboxDiagnostics
            if diagnostics.proactiveActionCount >= 12,
               diagnostics.topActionShare >= 0.35,
               let action = diagnostics.topAction {
                let domain = report.moments.first { $0.source.identifier == action }?.source.domain
                addSignal(
                    id: "dominant:\(action)",
                    title: "Dominant action: \(action)",
                    domain: domain,
                    seed: report.runSeed
                )
            }
            if diagnostics.longestRepeatedActionStreak >= 4,
               let action = diagnostics.longestRepeatedAction {
                let domain = report.moments.first { $0.source.identifier == action }?.source.domain
                addSignal(
                    id: "repetition:\(action)",
                    title: "Repeated action streak: \(action)",
                    domain: domain,
                    seed: report.runSeed
                )
            }
            for domain in diagnostics.untouchedDomains {
                addSignal(
                    id: "untouched:\(domain)",
                    title: "Untouched domain: \(domain)",
                    domain: domain,
                    seed: report.runSeed
                )
            }
            if diagnostics.advancedYearCount >= 5,
               Double(diagnostics.yearsWithoutProactiveAction.count) / Double(diagnostics.advancedYearCount) >= 0.20 {
                addSignal(
                    id: "passive-years",
                    title: "Frequent passive years",
                    domain: nil,
                    seed: report.runSeed,
                    ages: diagnostics.yearsWithoutProactiveAction
                )
            }
            if diagnostics.recoveryArcsStarted > diagnostics.recoveryArcsResolved {
                let recovery = report.moments.last?.state.recovery
                addSignal(
                    id: "unresolved-recovery:\(recovery ?? "unknown")",
                    title: "Unresolved \(recovery ?? "unknown") recovery",
                    domain: recovery == RecoveryKind.health.rawValue ? Domain.health.rawValue : Domain.cash.rawValue,
                    seed: report.runSeed
                )
            }
            for annotation in report.annotations {
                let moment = annotation.momentSequence.flatMap { sequence in
                    report.moments.first { $0.sequence == sequence }
                }
                let domain = moment?.source.domain
                let domainKey = domain ?? "unknown"
                let text = annotation.note.isEmpty ? (annotation.headline ?? "No note") : annotation.note
                addSignal(
                    id: "annotation:\(annotation.kind.rawValue):\(domainKey)",
                    title: "Repeated \(annotation.kind.title.lowercased()) observation",
                    domain: domain,
                    seed: report.runSeed,
                    ages: [annotation.age],
                    example: text
                )
            }
        }

        recurringSignals = accumulators.values
            .filter { $0.seeds.count >= 2 }
            .map {
                PlaytestCohortSignal(
                    id: $0.id,
                    title: $0.title,
                    domain: $0.domain,
                    seeds: $0.seeds.sorted(),
                    ages: $0.ages.sorted(),
                    examples: Array($0.examples.sorted().prefix(3))
                )
            }
            .sorted { lhs, rhs in
                lhs.runCount == rhs.runCount ? lhs.id < rhs.id : lhs.runCount > rhs.runCount
            }

        var missing: [String] = []
        if completed.count < 10 { missing.append("Complete \(10 - completed.count) more reviewed life/lives.") }
        for origin in OriginPreset.allCases {
            let count = originMap[origin.rawValue, default: 0]
            if count < 3 { missing.append("Add \(3 - count) more \(origin.rawValue.capitalized) origin run(s).") }
        }
        for style in requiredStyles where styleMap[style.rawValue, default: 0] == 0 {
            missing.append("Add one declared \(style.title) play-style run.")
        }
        if let medianDurationMinutes {
            if !(30...45).contains(medianDurationMinutes) {
                missing.append("Tune or validate the median duration; current median is \(medianDurationMinutes) minutes.")
            }
        } else {
            missing.append("Record complete-life durations.")
        }
        if outcomeAssessmentCount < completed.count {
            missing.append("Capture outcome explanations for \(completed.count - outcomeAssessmentCount) completed life/lives.")
        }
        if outcomeAgreementCount < outcomeAssessmentCount {
            missing.append("Resolve or validate \(outcomeAssessmentCount - outcomeAgreementCount) Life Review mismatch(es).")
        }
        missingRequirements = missing
    }

    var markdown: String {
        func countLines(_ values: [PlaytestCohortCount]) -> String {
            values.map { "- \($0.label.capitalized): \($0.count)" }.joined(separator: "\n")
        }
        let signalLines = recurringSignals.isEmpty ? "- None yet" : recurringSignals.map { signal in
            let domain = signal.domain.map { " · domain \($0)" } ?? ""
            let ages = signal.ages.isEmpty ? "" : " · ages \(signal.ages.map(String.init).joined(separator: ", "))"
            let examples = signal.examples.isEmpty ? "" : " · examples: \(signal.examples.joined(separator: " / "))"
            return "- \(signal.title): \(signal.runCount) lives · seeds \(signal.seeds.map(String.init).joined(separator: ", "))\(domain)\(ages)\(examples)"
        }.joined(separator: "\n")
        let missingLines = missingRequirements.isEmpty
            ? "- All Phase 1 evidence requirements pass."
            : missingRequirements.map { "- \($0)" }.joined(separator: "\n")

        return """
        # One Life Sandbox Cohort

        - Unique completed lives: \(completedReportCount)
        - Median duration: \(medianDurationMinutes.map { "\($0) minutes" } ?? "Not available")
        - Outcome explanations captured: \(outcomeAssessmentCount)/\(completedReportCount)
        - Life Review agreements: \(outcomeAgreementCount)/\(outcomeAssessmentCount)
        - Phase 2 ready: \(isReadyForPhase2 ? "Yes" : "No")
        - Next run target: \(nextRecommendation?.title ?? "No additional coverage run required")

        ## Origins

        \(countLines(originCounts))

        ## Declared Play Styles

        \(countLines(styleCounts))

        ## Recurring Evidence

        \(signalLines)

        ## Remaining Gate

        \(missingLines)
        """
    }
}

nonisolated struct PlaytestRunReport: Codable, Equatable {
    static let schemaVersion = 10

    var schemaVersion = Self.schemaVersion
    let runSeed: UInt64
    var origin: String?
    var playStyle: String? = nil
    let startedAt: Date
    var updatedAt: Date
    var endedAt: Date?
    var status: PlaytestRunStatus
    var moments: [PlaytestMoment]
    var annotations: [PlaytestAnnotation]
    var endReason: String?
    var finalTrajectory: String?
    var outcomeAssessment: PlaytestOutcomeAssessment? = nil

    var elapsedSeconds: TimeInterval {
        max(0, (endedAt ?? updatedAt).timeIntervalSince(startedAt))
    }

    var firstBoringAnnotation: PlaytestAnnotation? {
        annotations
            .filter { $0.kind == .boring }
            .min { ($0.age, $0.elapsedSeconds) < ($1.age, $1.elapsedSeconds) }
    }

    func counts(for kind: PlaytestSource.Kind) -> [(String, Int)] {
        let identifiers = moments.compactMap { moment -> String? in
            guard moment.source.kind == kind else { return nil }
            return moment.source.identifier ?? moment.headline
        }
        return Dictionary(grouping: identifiers, by: { $0 })
            .map { ($0.key, $0.value.count) }
            .sorted { lhs, rhs in lhs.1 == rhs.1 ? lhs.0 < rhs.0 : lhs.1 > rhs.1 }
    }

    var sandboxDiagnostics: PlaytestSandboxDiagnostics {
        let proactive = moments.filter {
            $0.source.kind == .instantAction || $0.source.kind == .assetTransaction
        }
        let actionCounts = Dictionary(grouping: proactive.compactMap(\.source.identifier), by: { $0 })
            .mapValues(\.count)
        let orderedActions = actionCounts.sorted {
            $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value
        }
        let top = orderedActions.first

        var longestStreak = 0
        var longestAction: String?
        var currentStreak = 0
        var previousAction: String?
        for moment in proactive {
            if moment.source.identifier == previousAction {
                currentStreak += 1
            } else {
                previousAction = moment.source.identifier
                currentStreak = 1
            }
            if currentStreak > longestStreak {
                longestStreak = currentStreak
                longestAction = moment.source.identifier
            }
        }

        var domainCountMap: [String: Int] = [:]
        for moment in proactive {
            if let domain = moment.source.domain {
                domainCountMap[domain, default: 0] += 1
            }
        }
        let domainCounts: [(domain: String, count: Int)] = domainCountMap
            .map { (domain: $0.key, count: $0.value) }
            .sorted { $0.count == $1.count ? $0.domain < $1.domain : $0.count > $1.count }
        let touchedDomains = Set(domainCounts.map { $0.domain })
        let untouchedDomains = Domain.allCases.map(\.rawValue).filter { !touchedDomains.contains($0) }

        let advancedAges = Set(moments.compactMap { moment -> Int? in
            guard moment.source.kind == .yearlyTick else { return nil }
            return max(0, moment.state.age - 1)
        })
        let proactiveAges = Set(proactive.map(\.state.age))
        let passiveAges = advancedAges.subtracting(proactiveAges).sorted()

        var recoveryStarts = 0
        var recoveryResolutions = 0
        var previousRecovery: String?
        for moment in moments {
            let current = moment.state.recovery
            if current != previousRecovery {
                if previousRecovery != nil { recoveryResolutions += 1 }
                if current != nil { recoveryStarts += 1 }
                previousRecovery = current
            }
        }

        return PlaytestSandboxDiagnostics(
            proactiveActionCount: proactive.count,
            uniqueActionCount: actionCounts.count,
            topAction: top?.key,
            topActionShare: proactive.isEmpty ? 0 : Double(top?.value ?? 0) / Double(proactive.count),
            longestRepeatedAction: longestAction,
            longestRepeatedActionStreak: longestStreak,
            actionCountsByDomain: domainCounts,
            untouchedDomains: untouchedDomains,
            advancedYearCount: advancedAges.count,
            yearsWithoutProactiveAction: passiveAges,
            recoveryArcsStarted: recoveryStarts,
            recoveryArcsResolved: recoveryResolutions
        )
    }

    var markdown: String {
        let durationMinutes = Int((elapsedSeconds / 60).rounded())
        let ages = moments.map(\.state.age)
        let ageRange = ages.isEmpty ? "No recorded ages" : "\(ages.min()!)–\(ages.max()!)"
        let firstBoring = firstBoringAnnotation.map { "Age \($0.age): \($0.note.isEmpty ? ($0.headline ?? "No note") : $0.note)" } ?? "Not marked"
        let weak = annotations.filter { $0.kind == .weakChoice }
        let confusing = annotations.filter { $0.kind == .confusingSystem }
        let latestWorld = moments.last?.state
        let worldProfile = latestWorld?.worldProfile?.joined(separator: " · ") ?? "Not recorded"
        let worldConditions = latestWorld?.worldConditions?.joined(separator: " · ") ?? "Not recorded"
        let publicHealthProfile = latestWorld?.publicHealthProfile?.joined(separator: " · ") ?? "Not recorded"
        let publicHealthCondition = latestWorld?.publicHealthCondition ?? "Not recorded"
        let assetCounts = latestWorld?.assetCounts?.sorted { $0.key < $1.key }
            .map { "\($0.key) \($0.value)" }
            .joined(separator: " · ") ?? "Not recorded"

        func countLines(_ values: [(String, Int)]) -> String {
            guard !values.isEmpty else { return "- None" }
            return values.prefix(12).map { "- \($0.0): \($0.1)" }.joined(separator: "\n")
        }

        func annotationLines(_ values: [PlaytestAnnotation]) -> String {
            guard !values.isEmpty else { return "- None" }
            return values.map {
                let text = $0.note.isEmpty ? ($0.headline ?? "No note") : $0.note
                return "- Age \($0.age): \(text)"
            }.joined(separator: "\n")
        }

        return """
        # One Life Playtest Report

        - Seed: \(runSeed)
        - Origin: \(origin ?? "Unknown")
        - Declared play style: \(playStyle?.capitalized ?? "Not selected")
        - Status: \(status.rawValue)
        - Duration: \(durationMinutes) minutes
        - Ages recorded: \(ageRange)
        - Ending: \(endReason ?? "In progress")
        - Moments: \(moments.count)

        ## Outcome Explanation

        - Player explanation: \(outcomeAssessment?.explanation ?? "Not recorded")
        - Life Review agrees: \(outcomeAssessment.map { $0.reviewAgrees ? "Yes" : "No" } ?? "Not recorded")

        ## First Boring Year

        \(firstBoring)

        ## Weak Choices

        \(annotationLines(weak))

        ## Confusing Systems

        \(annotationLines(confusing))

        ## Repeated Actions

        \(countLines(counts(for: .instantAction)))

        ## Repeated Events

        \(countLines(counts(for: .eventPresented)))

        \(sandboxDiagnostics.markdown)

        ## World Context

        - Profile: \(worldProfile)
        - Conditions: \(worldConditions)
        - Healthcare capacity / disease burden: \(publicHealthProfile)
        - Public-health condition: \(publicHealthCondition)

        ## Assets

        - Owned: \(assetCounts)
        - Movable resale value: $\(latestWorld?.movableAssetResaleValue ?? 0)
        - Property equity: $\(latestWorld?.propertyEquity ?? 0)
        - Property debt: $\(latestWorld?.propertyDebt ?? 0)
        - Property amenities: \(latestWorld?.propertyAmenityCount ?? 0)
        - Improvement value: $\(latestWorld?.propertyImprovementValue ?? 0)
        - Amenity upkeep: $\(latestWorld?.propertyAmenityUpkeep ?? 0)/year
        - Property market value: $\(latestWorld?.propertyMarketValue ?? 0)
        - Rentals: \(latestWorld?.occupiedRentalCount ?? 0) occupied / \(latestWorld?.vacantRentalCount ?? 0) vacant
        - Rental income: $\(latestWorld?.rentalIncome ?? 0)
        - Average property condition: \(latestWorld?.averagePropertyCondition.map(String.init) ?? "Not recorded")
        - Vehicles: \(latestWorld?.vehicleCounts?.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: " · ") ?? "Not recorded")
        - Vehicle resale value: $\(latestWorld?.vehicleResaleValue ?? 0)
        - Firearms: \(latestWorld?.lawfulFirearms ?? 0) legal / \(latestWorld?.illicitFirearms ?? 0) illegal
        - Legal status / heat: \(latestWorld?.legalStatus ?? "clear") / \(latestWorld?.firearmHeat ?? 0)

        ## Final Trajectory

        \(finalTrajectory ?? "Life still in progress.")
        """
    }
}

protocol PlaytestRecording: AnyObject {
    func startOrResume(seed: UInt64, origin: String?, initialState: LifeState)
    func record(source: PlaytestSource, outcome: ActionOutcome, state: LifeState)
    func annotate(kind: PlaytestAnnotationKind, note: String, state: LifeState)
    func setPlayStyle(_ style: PlaytestStyle)
    func assessOutcome(explanation: String, reviewAgrees: Bool)
    func finalize(status: PlaytestRunStatus, state: LifeState)
    func currentReport() -> PlaytestRunReport?
    func exportURLs() -> [URL]
    func cohortAnalysis() -> PlaytestCohortAnalysis
    func exportCohortURL() -> URL?
}

final class NoopPlaytestRecorder: PlaytestRecording {
    static let shared = NoopPlaytestRecorder()
    private init() {}

    func startOrResume(seed: UInt64, origin: String?, initialState: LifeState) {}
    func record(source: PlaytestSource, outcome: ActionOutcome, state: LifeState) {}
    func annotate(kind: PlaytestAnnotationKind, note: String, state: LifeState) {}
    func setPlayStyle(_ style: PlaytestStyle) {}
    func assessOutcome(explanation: String, reviewAgrees: Bool) {}
    func finalize(status: PlaytestRunStatus, state: LifeState) {}
    func currentReport() -> PlaytestRunReport? { nil }
    func exportURLs() -> [URL] { [] }
    func cohortAnalysis() -> PlaytestCohortAnalysis { PlaytestCohortAnalysis(reports: []) }
    func exportCohortURL() -> URL? { nil }
}

final class FilePlaytestRecorder: PlaytestRecording {
    private let fileManager: FileManager
    private let baseURL: URL
    private let now: () -> Date
    private let persistenceQueue = DispatchQueue(label: "OneLife.playtest-recorder", qos: .utility)
    private var report: PlaytestRunReport?

    init(
        fileManager: FileManager = .default,
        baseURL: URL? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.fileManager = fileManager
        self.now = now
        if let baseURL {
            self.baseURL = baseURL
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.baseURL = support.appendingPathComponent("OneLifePlaytests", isDirectory: true)
        }
    }

    func startOrResume(seed: UInt64, origin: String?, initialState: LifeState) {
        let url = activeURL(seed: seed)
        if let data = try? Data(contentsOf: url),
           var decoded = try? decoder().decode(PlaytestRunReport.self, from: data),
           decoded.status == .active {
            decoded.schemaVersion = PlaytestRunReport.schemaVersion
            if decoded.origin == nil { decoded.origin = origin }
            decoded.updatedAt = now()
            report = decoded
            persistActive()
            return
        }

        let timestamp = now()
        report = PlaytestRunReport(
            runSeed: seed,
            origin: origin,
            startedAt: timestamp,
            updatedAt: timestamp,
            endedAt: nil,
            status: .active,
            moments: [],
            annotations: [],
            endReason: nil,
            finalTrajectory: nil
        )
        persistActive()
    }

    func record(source: PlaytestSource, outcome: ActionOutcome, state: LifeState) {
        guard var report, report.status == .active else { return }
        let timestamp = now()
        let moment = PlaytestMoment(
            sequence: report.moments.count + 1,
            elapsedSeconds: max(0, timestamp.timeIntervalSince(report.startedAt)),
            source: source,
            headline: outcome.headline,
            narrative: outcome.narrative,
            deltas: PlaytestDeltas(outcome.deltas),
            isYearly: outcome.isYearly,
            state: PlaytestStateSnapshot(state: state)
        )
        report.moments.append(moment)
        report.updatedAt = timestamp
        self.report = report
        persistActive()
    }

    func annotate(kind: PlaytestAnnotationKind, note: String, state: LifeState) {
        guard var report, report.status == .active else { return }
        let timestamp = now()
        let latest = report.moments.last
        report.annotations.append(
            PlaytestAnnotation(
                id: UUID(),
                elapsedSeconds: max(0, timestamp.timeIntervalSince(report.startedAt)),
                age: state.character.age,
                momentSequence: latest?.sequence,
                headline: latest?.headline,
                kind: kind,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        report.updatedAt = timestamp
        self.report = report
        persistActive()
    }

    func setPlayStyle(_ style: PlaytestStyle) {
        guard var report, report.status == .active else { return }
        report.playStyle = style.rawValue
        report.updatedAt = now()
        self.report = report
        persistActive()
    }

    func assessOutcome(explanation: String, reviewAgrees: Bool) {
        guard var report, report.status == .completed else { return }
        let normalized = explanation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let timestamp = now()
        report.outcomeAssessment = PlaytestOutcomeAssessment(
            explanation: normalized,
            reviewAgrees: reviewAgrees,
            recordedAt: timestamp
        )
        report.updatedAt = timestamp
        self.report = report

        persistenceQueue.async { [self] in
            do {
                try ensureDirectories()
                try encoder().encode(report).write(to: completedURL(report: report), options: .atomic)
                pruneCompletedReports()
            } catch {
                // Diagnostic recording must never affect gameplay.
            }
        }
    }

    func finalize(status: PlaytestRunStatus, state: LifeState) {
        guard var report, report.status == .active else { return }
        let timestamp = now()
        report.status = status
        report.updatedAt = timestamp
        report.endedAt = timestamp
        report.endReason = state.endReason?.rawValue
        report.finalTrajectory = LifeReviewModel.build(from: state).legacySummary
        self.report = report

        persistenceQueue.async { [self] in
            do {
                try ensureDirectories()
                let destination = completedURL(report: report)
                try encoder().encode(report).write(to: destination, options: .atomic)
                try? fileManager.removeItem(at: activeURL(seed: report.runSeed))
                pruneCompletedReports()
            } catch {
                // Diagnostic recording must never affect gameplay.
            }
        }
    }

    func currentReport() -> PlaytestRunReport? { report }

    func exportURLs() -> [URL] {
        guard let report else { return [] }
        return persistenceQueue.sync {
            do {
                try ensureDirectories()
                let stem = "playtest-\(report.runSeed)"
                let jsonURL = exportsDirectory.appendingPathComponent(stem).appendingPathExtension("json")
                let markdownURL = exportsDirectory.appendingPathComponent(stem).appendingPathExtension("md")
                try encoder().encode(report).write(to: jsonURL, options: .atomic)
                try Data(report.markdown.utf8).write(to: markdownURL, options: .atomic)
                return [jsonURL, markdownURL]
            } catch {
                return []
            }
        }
    }

    func cohortAnalysis() -> PlaytestCohortAnalysis {
        persistenceQueue.sync { PlaytestCohortAnalysis(reports: loadCompletedReports()) }
    }

    func exportCohortURL() -> URL? {
        persistenceQueue.sync {
            do {
                try ensureDirectories()
                let analysis = PlaytestCohortAnalysis(reports: loadCompletedReports())
                let url = exportsDirectory.appendingPathComponent("sandbox-cohort").appendingPathExtension("md")
                try Data(analysis.markdown.utf8).write(to: url, options: .atomic)
                return url
            } catch {
                return nil
            }
        }
    }

    private var completedDirectory: URL {
        baseURL.appendingPathComponent("Completed", isDirectory: true)
    }

    private var exportsDirectory: URL {
        baseURL.appendingPathComponent("Exports", isDirectory: true)
    }

    private func activeURL(seed: UInt64) -> URL {
        baseURL.appendingPathComponent("active-\(seed).json")
    }

    private func completedURL(report: PlaytestRunReport) -> URL {
        let seconds = Int((report.endedAt ?? report.updatedAt).timeIntervalSince1970)
        return completedDirectory.appendingPathComponent("playtest-\(report.runSeed)-\(seconds).json")
    }

    private func ensureDirectories() throws {
        try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: completedDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
    }

    private func persistActive() {
        guard let report, report.status == .active else { return }
        persistenceQueue.async { [self] in
            do {
                try ensureDirectories()
                try encoder().encode(report).write(to: activeURL(seed: report.runSeed), options: .atomic)
            } catch {
                // Diagnostic recording must never affect gameplay.
            }
        }
    }

    private func pruneCompletedReports() {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: completedDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        let sorted = urls.sorted {
            let lhs = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rhs = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return lhs > rhs
        }
        for url in sorted.dropFirst(20) {
            try? fileManager.removeItem(at: url)
        }
    }

    private func loadCompletedReports() -> [PlaytestRunReport] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: completedDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return urls.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder().decode(PlaytestRunReport.self, from: data)
        }
    }

    private func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

enum PlaytestEnvironment {
    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-playtest")
        #else
        false
        #endif
    }

    static func recorder() -> any PlaytestRecording {
        isEnabled ? FilePlaytestRecorder() : NoopPlaytestRecorder.shared
    }

    static func cohortAnalysis() -> PlaytestCohortAnalysis {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestEmptyPlaytestCohort") {
            return PlaytestCohortAnalysis(reports: [])
        }
        #endif
        return isEnabled ? FilePlaytestRecorder().cohortAnalysis() : PlaytestCohortAnalysis(reports: [])
    }
}
