import Combine
import Foundation

private final class NullPersistence: LifePersisting, @unchecked Sendable {
    let automaticallyPersistsCommits = false
    func save(_ state: LifeState) -> Result<Void, Error> { .success(()) }
    func clear() {}
}

private final class BenchmarkPersistence: LifePersisting, @unchecked Sendable {
    func save(_ state: LifeState) -> Result<Void, Error> { .success(()) }
    func clear() {}
}

@main
@MainActor
struct CoreRuntimeProbe {
    private struct Aggregate {
        var runs = 0
        var ended = 0
        var maxPeakCash = Int.min
        var minPeakCash = Int.max
        var totalPeakCash = 0
        var totalAge = 0
        var partnered = 0
        var netWorths: [Int] = []
        var endingAges: [Int] = []
        var specialCareers = 0
        var diamondCareers = 0
        var criminalPaths = 0

        mutating func include(_ state: LifeState) {
            precondition(state.cash >= 0, "Negative available cash")
            if let d = state.finance.annualLedger.economy {
                let receipts = d.earnings + d.partnerEarnings + d.support + d.pension + d.rentalIncome + d.retirementDraw
                let taxPaid = min(d.openingCash + receipts, d.taxReconciliation)
                let secured = d.receipts.reduce(0) { $0 + $1.principal + $1.interest }
                let unsecured = d.principal + d.interest - secured
                let payments = taxPaid + (d.essentialPaid ?? d.essentials) + d.primaryHousing + d.secondaryHousing + unsecured + d.discretionary + d.retirementContribution
                precondition(d.openingCash + receipts - payments == d.closingCash, "Annual cash does not reconcile")
            }
            runs += 1
            if state.isGameOver { ended += 1 }
            let peak = state.aggregates.peakCash
            maxPeakCash = max(maxPeakCash, peak)
            minPeakCash = min(minPeakCash, peak)
            totalPeakCash += peak
            totalAge += state.character.age
            if state.partner != nil { partnered += 1 }
            netWorths.append(state.netWorth)
            endingAges.append(state.character.age)
            if state.career.careerClass == .special { specialCareers += 1 }
            if state.career.careerClass == .diamond { diamondCareers += 1 }
            if state.career.criminalPath != nil { criminalPaths += 1 }
        }

        var summary: String {
            let meanPeak = runs == 0 ? 0 : totalPeakCash / runs
            let meanAge = runs == 0 ? 0 : totalAge / runs
            return "runs=\(runs) ended=\(ended) peak[min/mean/max]=\(minPeakCash)/\(meanPeak)/\(maxPeakCash) netWorth[p50/p90/p99]=\(percentile(netWorths, 50))/\(percentile(netWorths, 90))/\(percentile(netWorths, 99)) endingAge[p50/p90]=\(percentile(endingAges, 50))/\(percentile(endingAges, 90)) career[special/diamond/crime]=\(specialCareers)/\(diamondCareers)/\(criminalPaths) partnered=\(partnered)"
        }

        private func percentile(_ values: [Int], _ percentile: Int) -> Int {
            guard !values.isEmpty else { return 0 }
            let sorted = values.sorted()
            let index = min(sorted.count - 1, (sorted.count - 1) * percentile / 100)
            return sorted[index]
        }
    }

    static func main() {
        if CommandLine.arguments.contains("--performance-only") {
            measurePerformance()
            return
        }

        var worker = LifeState(name: "Purchasing power", seed: 33, startingAge: 30)
        worker.career.track = .office; worker.career.level = .entry
        worker.flags.attendsSchool = false; worker.cash = 0
        let ordinary = EconomyCalculator.calculate(worker, world: WorldModifierSnapshot(), earned: 42_000, rent: 0)
        precondition((4_200...8_400).contains(ordinary.detail.expectedNet), "Office savings left the 10–20% band")
        let service = EconomyCalculator.calculate(worker, world: WorldModifierSnapshot(), earned: 34_000, rent: 0)
        precondition(service.detail.expectedNet >= 0, "Entry care/service cannot cover basic costs")
        if CommandLine.arguments.contains("--economy-only") {
            let policies = ["balanced", "grind", "social", "survival", "criminal", "landlord", "specialist", "diamond-seeking", "drifter"]
            let talents: [SpecialTalent?] = [nil] + SpecialTalent.allCases.map(Optional.some)
            let seedCount = max(1, Int(ProcessInfo.processInfo.environment["ONELIFE_PROBE_SEEDS"] ?? "1") ?? 1)
            var rows: [[String: Any]] = []
            var lives: [(Int, LifeState)] = []
            for origin in OriginPreset.allCases {
                for context in StartingContext.allCases {
                    for talent in talents {
                        for seed in 1...seedCount {
                            let initial = LifeGenerationSystem.customPreview(name: "Economy", seed: UInt64(seed + originIndex(origin) * 10_000), origin: origin, context: context, definingTrait: .adaptable, talent: talent).state
                            for policy in policies {
                                let final = run(state: initial, policy: policy)
                                lives.append((final.netWorth, final))
                                var row: [String: Any] = ["seed": seed, "origin": origin.rawValue, "context": context.rawValue, "talent": talent?.rawValue ?? "none", "strategy": policy, "netWorth": final.netWorth, "endingCash": final.cash, "reputation": final.stats.rep, "careerLevel": final.career.level.rawValue, "specialMomentum": final.career.specialMomentum, "ageAtDeath": final.character.age, "ended": final.isGameOver, "specialEntry": final.career.careerClass == .special, "diamondEntry": final.career.careerClass == .diamond, "criminalPathEntry": final.career.criminalPath != nil, "convictions": final.legal.felonyConvictions + final.legal.misdemeanorConvictions, "prisonYears": final.aggregates.prisonYearsServed, "yearsToMillion": final.aggregates.ageAtFirstMillionNetWorth.map { ($0 - initial.character.age) as Any } ?? NSNull(), "yearsToTenMillion": final.aggregates.ageAtFirstTenMillionNetWorth.map { ($0 - initial.character.age) as Any } ?? NSNull()]
                                row["incomeSources"] = Dictionary(uniqueKeysWithValues: IncomeSource.allCases.map { ($0.rawValue, final.aggregates.lifetimeIncomeBySource[$0, default: 0]) })
                                rows.append(row)
                            }
                        }
                    }
                }
            }
            let sorted = lives.sorted { $0.0 < $1.0 }
            let topCount = max(1, (lives.count + 99) / 100)
            let top = sorted.suffix(topCount).map(\.1)
            let concentrated = top.filter { state in
                let total = state.aggregates.lifetimeIncomeBySource.values.reduce(0, +)
                return total > 0 && (state.aggregates.lifetimeIncomeBySource.values.max() ?? 0) * 100 > total * 60
            }.count
            let diamondRate = lives.isEmpty ? 0 : Double(lives.filter { $0.1.career.careerClass == .diamond }.count) / Double(lives.count)
            let concentrationRate = top.isEmpty ? 0 : Double(concentrated) / Double(top.count)
            let diamondGate = (0.01...0.03).contains(diamondRate)
            let concentrationGate = concentrationRate <= 0.70
            let netWorthPercentiles: [String: Int] = [
                "p50": percentile(sorted.map { $0.0 }, 50),
                "p90": percentile(sorted.map { $0.0 }, 90),
                "p99": percentile(sorted.map { $0.0 }, 99),
            ]
            let metrics: [String: Any] = [
                "lives": lives.count,
                "netWorthPercentiles": netWorthPercentiles,
                "specialEntryRate": Double(lives.filter { $0.1.career.careerClass == .special }.count) / Double(max(1, lives.count)),
                "criminalPathEntryRate": Double(lives.filter { $0.1.career.criminalPath != nil }.count) / Double(max(1, lives.count)),
                "diamondEntryRate": diamondRate,
                "topOnePercentSingleSourceOver60Rate": concentrationRate,
            ]
            let gates: [String: Bool] = [
                "diamondRateOneToThreePercent": diamondGate,
                "topOnePercentIncomeConcentration": concentrationGate,
            ]
            let report: [String: Any] = [
                "schemaVersion": 1,
                "seedCount": seedCount,
                "origins": OriginPreset.allCases.map(\.rawValue),
                "contexts": StartingContext.allCases.map(\.rawValue),
                "talents": talents.map { $0?.rawValue ?? "none" },
                "strategies": policies,
                "metrics": metrics,
                "gates": gates,
                "livesData": rows,
            ]
            let data = try! JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            if let output = ProcessInfo.processInfo.environment["ONELIFE_PROBE_OUTPUT"] {
                try! data.write(to: URL(fileURLWithPath: output), options: .atomic)
                print("ECONOMY_PROBE_JSON \(output)")
            } else { print(String(decoding: data, as: UTF8.self)) }
            precondition(diamondGate, "Diamond entry rate must remain between 1% and 3%")
            precondition(concentrationGate, "Top-1% single-source income concentration exceeded 70%")
            return
        }

        let policies = ["balanced", "grind", "social", "survival", "criminal", "landlord", "specialist", "diamond-seeking", "drifter"]
        var overall = Aggregate()
        var byPolicy = Dictionary(uniqueKeysWithValues: policies.map { ($0, Aggregate()) })
        var divergentPairs = 0
        var comparedPairs = 0
        var replayFailures = 0
        var personalityDivergence = 0
        var talentDivergence = 0
        var worldDivergence = 0
        var balanceScores: [PersonalityFlag: [Int]] = [:]
        var balanceOutcomes = Aggregate()
        var retainedDefiningTraits = 0
        var personalityEventCounts: [Int] = []
        var personalityEventsByFlag: [PersonalityFlag: Int] = [:]

        for origin in OriginPreset.allCases {
            for seed in 1...30 {
                var policyStates: [String: LifeState] = [:]
                for policy in policies {
                    let runSeed = UInt64(seed) &+ UInt64(originIndex(origin) * 10_000)
                    let state = run(seed: runSeed, origin: origin, policy: policy)
                    overall.include(state)
                    byPolicy[policy, default: Aggregate()].include(state)
                    policyStates[policy] = state
                    if run(seed: runSeed, origin: origin, policy: policy) != state {
                        replayFailures += 1
                    }
                }
                if let baseline = policyStates["balanced"] {
                    for policy in policies.dropFirst() {
                        comparedPairs += 1
                        if policyStates[policy] != baseline { divergentPairs += 1 }
                    }
                }
            }
        }

        for seed in 1...30 {
            let runSeed = UInt64(seed + 90_000)
            let driven = LifeGenerationSystem.customPreview(
                name: "Probe", seed: runSeed, origin: .balanced, context: .ordinary,
                definingTrait: .driven, talent: nil
            ).state
            let reserved = LifeGenerationSystem.customPreview(
                name: "Probe", seed: runSeed, origin: .balanced, context: .ordinary,
                definingTrait: .reserved, talent: nil
            ).state
            if run(state: driven, policy: "balanced").personality != run(state: reserved, policy: "balanced").personality {
                personalityDivergence += 1
            }

            let talented = LifeGenerationSystem.customPreview(
                name: "Probe", seed: runSeed, origin: .balanced, context: .ordinary,
                definingTrait: .adaptable, talent: .athletic
            ).state
            let ordinary = LifeGenerationSystem.customPreview(
                name: "Probe", seed: runSeed, origin: .balanced, context: .ordinary,
                definingTrait: .adaptable, talent: nil
            ).state
            if run(state: talented, policy: "survival") != run(state: ordinary, policy: "survival") {
                talentDivergence += 1
            }

            let firstWorld = LifeGenerationSystem.randomPreview(seed: runSeed).state.world
            let secondWorld = LifeGenerationSystem.randomPreview(seed: runSeed + 1).state.world
            if firstWorld != secondWorld { worldDivergence += 1 }

            let generated = LifeGenerationSystem.randomPreview(seed: runSeed).state
            if run(state: generated, policy: "balanced") != run(state: generated, policy: "balanced") {
                replayFailures += 1
            }
        }

        let balanceSeedCount = max(1, Int(ProcessInfo.processInfo.environment["ONELIFE_BALANCE_SEEDS"] ?? "1000") ?? 1_000)
        let balanceLifeCount = balanceSeedCount * PersonalityFlag.allCases.count
        // Ten defining traits across 1,000 shared seeds by default: 10,000 complete,
        // deterministic lives for the personality balance gate.
        for flag in PersonalityFlag.allCases {
            for seed in 1...balanceSeedCount {
                let initial = LifeGenerationSystem.customPreview(
                    name: "Balance", seed: UInt64(200_000 + seed), origin: .balanced,
                    context: .ordinary, definingTrait: flag, talent: nil
                ).state
                let final = run(state: initial, policy: "balanced")
                balanceOutcomes.include(final)
                balanceScores[flag, default: []].append(compositeScore(final))
                if final.personality.has(flag) { retainedDefiningTraits += 1 }
                let eventCount = final.aggregates.personalityPivotalEvents
                personalityEventCounts.append(eventCount)
                personalityEventsByFlag[flag, default: 0] += eventCount
            }
        }
        let medians = Dictionary(uniqueKeysWithValues: PersonalityFlag.allCases.map { flag in
            (flag, median(balanceScores[flag, default: []]))
        })
        let overallMedian = median(Array(medians.values))
        let largestMedianGap = medians.values.map { abs($0 - overallMedian) }.max() ?? 0
        let potentialGap = overallMedian == 0 ? 0 : Double(largestMedianGap) / Double(abs(overallMedian))
        let retentionRate = Double(retainedDefiningTraits) / Double(balanceLifeCount)
        let inCadence = personalityEventCounts.filter { (3...6).contains($0) }.count
        let cadenceRate = Double(inCadence) / Double(balanceLifeCount)
        let meanExposureByFlag = Dictionary(uniqueKeysWithValues: PersonalityFlag.allCases.map { flag in
            (flag, Double(personalityEventsByFlag[flag, default: 0]) / Double(balanceSeedCount))
        })
        let minimumExposure = meanExposureByFlag.values.min() ?? 0
        let maximumExposure = meanExposureByFlag.values.max() ?? 0
        let exposureSpread = minimumExposure == 0 ? 1 : (maximumExposure - minimumExposure) / minimumExposure

        let preferredActions = Dictionary(uniqueKeysWithValues: PersonalityFlag.allCases.compactMap { flag -> (PersonalityFlag, ActionID)? in
            var state = LifeState(name: "Preference", seed: 1)
            state.personality.current = PersonalityVector()
            state.personality.current[flag.axis] = flag.favorsHighValue ? 80 : 20
            state.personality.refreshEstablishedFlags()
            let signals = SimulationSignalSnapshot(state: state)
            guard let rule = UnifiedReactionRegistry.rules.first(where: {
                $0.channel == .playerPersonality && $0.predicate.playerFlags.contains(flag)
                    && $0.matches(action: $0.actionIDs.first ?? .rest, signals: signals)
            }), let action = rule.actionIDs.first else { return nil }
            return (flag, action)
        })
        var differentPreferences = 0
        var preferencePairs = 0
        for (index, first) in PersonalityFlag.allCases.enumerated() {
            for second in PersonalityFlag.allCases.dropFirst(index + 1) {
                preferencePairs += 1
                if preferredActions[first] != preferredActions[second] { differentPreferences += 1 }
            }
        }
        let preferenceDivergence = preferencePairs == 0 ? 0 : Double(differentPreferences) / Double(preferencePairs)

        var maximumCombinedBenefit = 0
        for (index, signature) in IdentitySignatureID.allCases.enumerated() {
            var state = LifeState(name: "Budget", seed: UInt64(index + 1))
            state.personality.current = PersonalityVector()
            for flag in PersonalitySystem.requiredFlags(for: signature) {
                state.personality.current[flag.axis] = flag.favorsHighValue ? 80 : 20
            }
            state.personality.refreshEstablishedFlags()
            state.partner = PartnerState(name: "Morgan", startedAge: 20, compatibility: 60)
            for action in DomainActionRegistry.all {
                let resolution = SocialReactivitySystem().preview(action: action, state: state)
                maximumCombinedBenefit = max(maximumCombinedBenefit, resolution.reactionRules.reduce(0) { $0 + $1.impact.benefitUnits })
            }
        }

        print("CORE_PROBE overall \(overall.summary)")
        print("CORE_PROBE balance_outcomes \(balanceOutcomes.summary)")
        for policy in policies {
            print("CORE_PROBE policy=\(policy) \(byPolicy[policy, default: Aggregate()].summary)")
        }
        print("CORE_PROBE divergence=\(divergentPairs)/\(comparedPairs) replayFailures=\(replayFailures)")
        print("CORE_PROBE life_axes personality=\(personalityDivergence)/30 talent=\(talentDivergence)/30 world=\(worldDivergence)/30")
        let balanceLine = "CORE_PROBE personality_balance lives=\(balanceLifeCount) medians=\(medians.map { "\($0.key.rawValue):\($0.value)" }.sorted().joined(separator: ",")) gap=\(potentialGap) retention=\(retentionRate) cadence=\(cadenceRate) exposureSpread=\(exposureSpread) preferenceDivergence=\(preferenceDivergence) maxCombinedBenefit=\(maximumCombinedBenefit)"
        print(balanceLine)
        FileHandle.standardError.write(Data("\(balanceLine)\n".utf8))

        measurePerformance()

        guard overall.ended == overall.runs else { fatalError("Not every complete life terminated") }
        guard overall.minPeakCash >= 0 else { fatalError("Negative liquid cash escaped settlement") }
        guard replayFailures == 0 else { fatalError("Seeded replay diverged") }
        guard divergentPairs == comparedPairs else { fatalError("At least one strategy pair did not diverge") }
        guard personalityDivergence == 30 else { fatalError("Personality profiles did not diverge") }
        guard talentDivergence == 30 else { fatalError("Talent and no-talent lives did not diverge") }
        guard worldDivergence >= 20 else { fatalError("World profiles did not diverge enough") }
        guard potentialGap <= 0.05 else { fatalError("Personality lifetime potential exceeded five-percent median gap") }
        guard preferenceDivergence >= 0.35 else { fatalError("Personality strategies did not diverge enough") }
        guard (0.70...0.85).contains(retentionRate) else { fatalError("Defining-trait retention left its target band") }
        guard cadenceRate >= 0.80 else { fatalError("Personality events missed the three-to-six cadence too often") }
        guard exposureSpread <= 0.20 else { fatalError("Personality event exposure differed by more than twenty percent") }
        guard maximumCombinedBenefit <= ReactionBalancePolicy.combinedBenefitBudget else { fatalError("Combined reaction benefit exceeded its budget") }
        guard byPolicy["social"]?.partnered == byPolicy["social"]?.runs else {
            fatalError("Social policy did not traverse relationship formation")
        }
    }

    private static func measurePerformance() {
        let actionSampleCount = max(
            20,
            Int(ProcessInfo.processInfo.environment["ONELIFE_PERF_ACTION_SAMPLES"] ?? "100") ?? 100
        )
        let yearSampleCount = max(
            50,
            Int(ProcessInfo.processInfo.environment["ONELIFE_PERF_YEAR_SAMPLES"] ?? "250") ?? 250
        )

        // Prime every action's simulator/persistence lane before timing. Each
        // measured commit is drained outside the interval so one sample cannot
        // leave background work that distorts the actions that follow it.
        for (index, action) in DomainActionRegistry.all.enumerated() {
            let simulator = LifeSimulator(
                state: executableState(for: action, seed: UInt64(index + 50_000)),
                store: BenchmarkPersistence()
            )
            simulator.saveForLifecycle()
            _ = simulator.execute(action.id)
            simulator.saveForLifecycle()
        }

        var durations: [UInt64] = []
        var durationsByAction: [ActionID: [UInt64]] = [:]
        durations.reserveCapacity(DomainActionRegistry.all.count * actionSampleCount)
        for (actionIndex, action) in DomainActionRegistry.all.enumerated() {
            for sample in 0..<actionSampleCount {
                let simulator = LifeSimulator(
                    state: executableState(
                        for: action,
                        seed: UInt64(100_000 + actionIndex * actionSampleCount + sample)
                    ),
                    store: BenchmarkPersistence()
                )
                simulator.saveForLifecycle()
                let start = DispatchTime.now().uptimeNanoseconds
                guard simulator.execute(action.id) != nil else {
                    fatalError("\(action.id.rawValue) did not return synchronously")
                }
                let duration = DispatchTime.now().uptimeNanoseconds - start
                simulator.saveForLifecycle()
                durations.append(duration)
                durationsByAction[action.id, default: []].append(duration)
            }
        }
        durations.sort()
        let p50 = durations[durations.count / 2]
        let p95 = durations[(durations.count * 95) / 100]
        let p99 = durations[(durations.count * 99) / 100]
        print("CORE_PROBE action_ns samples=\(durations.count) p50=\(p50) p95=\(p95) p99=\(p99) max=\(durations.last ?? 0)")
        let slowest = durationsByAction.map { id, samples -> (ActionID, UInt64) in
            let sorted = samples.sorted()
            return (id, sorted[(sorted.count * 95) / 100])
        }.max { $0.1 < $1.1 }
        if let slowest {
            print("CORE_PROBE slowest_action_p95 id=\(slowest.0.rawValue) ns=\(slowest.1)")
        }

        for sample in 0..<20 {
            let simulator = yearlySimulator(seed: UInt64(sample + 60_000))
            simulator.saveForLifecycle()
            simulator.ageUp()
            simulator.saveForLifecycle()
        }
        var yearlyDurations: [UInt64] = []
        yearlyDurations.reserveCapacity(yearSampleCount)
        for sample in 0..<yearSampleCount {
            let simulator = yearlySimulator(seed: UInt64(sample + 70_000))
            simulator.saveForLifecycle()
            let start = DispatchTime.now().uptimeNanoseconds
            simulator.ageUp()
            yearlyDurations.append(DispatchTime.now().uptimeNanoseconds - start)
            simulator.saveForLifecycle()
        }
        yearlyDurations.sort()
        print(
            "CORE_PROBE year_ns samples=\(yearlyDurations.count) "
                + "p50=\(yearlyDurations[yearlyDurations.count / 2]) "
                + "p95=\(yearlyDurations[(yearlyDurations.count * 95) / 100]) "
                + "max=\(yearlyDurations.last ?? 0)"
        )
    }

    private static func run(seed: UInt64, origin: OriginPreset, policy: String) -> LifeState {
        let simulator = LifeSimulator(
            state: LifeState(name: "Probe", seed: seed, origin: origin),
            store: NullPersistence()
        )
        _ = simulator.simulate(years: 120, policy: policy)
        return simulator.state
    }

    private static func percentile(_ values: [Int], _ percentile: Int) -> Int {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        return sorted[min(sorted.count - 1, (sorted.count - 1) * percentile / 100)]
    }

    private static func run(state: LifeState, policy: String) -> LifeState {
        let simulator = LifeSimulator(state: state, store: NullPersistence())
        _ = simulator.simulate(years: 120, policy: policy)
        return simulator.state
    }

    private static func executableState(for action: DomainAction, seed: UInt64) -> LifeState {
        var state = LifeState(name: "Latency", seed: seed)
        state.character.age = action.requirements.minimumAge ?? 30
        if let stage = action.requirements.allowedStages?.first {
            state.character.age = switch stage {
            case .adolescence: 14
            case .launch: max(18, action.requirements.minimumAge ?? 18)
            case .build: 30
            case .pressure: 50
            case .legacy: 70
            }
        }
        state.lifeStage = LifeStage.stage(for: state.character.age)
        state.cash = max(100_000, action.requirements.minimumCash ?? 0)
        if let minimumStat = action.requirements.minimumStat,
           let domain = action.requirements.statDomain {
            state.stats[domain] = minimumStat
        }
        state.flags.attendsSchool = action.requirements.requiresSchool
        if action.requirements.requiresLeftSchool { state.flags.attendsSchool = false }
        if action.requirements.requiresCredential { state.education.credential = true }
        if action.requirements.requiresJob {
            state.job.tier = .entry
            state.flags.hasJob = true
        }
        if action.requirements.requiresPartner {
            state.partner = PartnerState(
                name: "Morgan",
                startedAge: state.character.age,
                compatibility: 60,
                bond: 50,
                resentment: 35,
                flags: [.supportive, .loyal]
            )
            state.flags.hasPartner = true
        }
        for requirement in action.requirements.values { satisfy(requirement, state: &state) }
        state.clamp()
        return state
    }

    private static func satisfy(_ requirement: ActionRequirement, state: inout LifeState) {
        switch requirement {
        case .minimumAge(let age): state.character.age = max(state.character.age, age)
        case .minimumCash(let cash): state.cash = max(state.cash, cash)
        case .minimumStat(let domain, let value): state.stats[domain] = max(state.stats[domain], value)
        case .schoolEnrollment(let enrolled): state.flags.attendsSchool = enrolled
        case .credential: state.education.credential = true
        case .partner: if state.partner == nil { state.partner = PartnerState(startedAge: state.character.age, compatibility: 60) }
        case .employed: state.career.level = .entry
        case .careerTrack(let track): state.career.track = track
        case .careerClass(let careerClass): state.career.careerClass = careerClass
        case .careerDirectionChosen: state.career.track = .office
        case .careerOccupationNotChosen:
            state.career.track = .office
            state.career.occupation = nil
        case .careerOccupation(let occupation):
            state.career.track = occupation.track
            state.career.occupation = occupation
        case .careerLevels(let levels): state.career.level = levels.first ?? .entry
        case .careerPaidLeave(let amount): state.career.paidLeaveDays = max(state.career.paidLeaveDays, amount)
        case .specialCareerEligible:
            state.career.careerClass = .normal
            state.career.level = .established
            state.career.performance = 100
            state.stats.rep = 100
        case .diamondCareerEligible:
            state.career.careerClass = .special
            state.career.level = .senior
            state.career.specialMomentum = 100
            state.stats.rep = 100
            state.cash = max(state.cash, 1_000_000)
        case .relationshipStages(let stages):
            if state.partner == nil { state.partner = PartnerState(startedAge: state.character.age, compatibility: 60) }
            let stage = stages.first ?? .dating; state.partner?.stage = stage; state.partner?.committed = stage != .dating
        case .familyIntention(let intentions): state.family.intention = intentions.first ?? .openToChildren
        case .noChildren: state.family.children = []
        case .hasDependents: state.family.children = [ChildState(name: "Alex", age: 8, temperament: .curious)]
        case .housing(let kinds):
            let kind = kinds.first ?? .renting
            state.assets = kind == .renting
                ? AssetState()
                : AssetSystem.migrateLegacyHousing(
                    HousingState(kind: kind, homeValue: 1_500, mortgageBalance: 900, annualCost: 220),
                    age: state.character.age
                )
        case .debtWorkoutEligible: state.finance.consumerDebt = 100_000; state.finance.economy.shortfallYears = 2
        case .hasDebt: state.finance.consumerDebt = 10_000
        case .hasCondition: state.health.conditions = [ChronicCondition(kind: .chronicPain, severity: 35, management: 5)]
        case .schoolCommitmentOpen: state.education.commitment = nil
        case .schoolActivityOpen: state.education.activityStage = .none
        case .collegeApplicationEligible:
            state.character.age = min(24, max(18, state.character.age))
            state.lifeStage = .launch
            state.education.highSchoolDiploma = true
            state.education.phase = .leftSchool
            state.education.college = CollegeState()
        case .educationRecoveryEligible:
            state.character.age = min(64, max(18, state.character.age))
            state.flags.attendsSchool = false
            state.education.phase = .leftSchool
            state.education.college = CollegeState()
            state.education.recovery = EducationRecoveryState()
            state.education.credentialKind = .none
        case .stages(let stages):
            if let stage = stages.first { state.character.age = switch stage { case .adolescence: 14; case .launch: 20; case .build: 30; case .pressure: 50; case .legacy: 70 }; state.lifeStage = stage }
        case .all(let values): for value in values { satisfy(value, state: &state) }
        case .any(let values): if let first = values.first { satisfy(first, state: &state) }
        }
    }

    private static func yearlySimulator(seed: UInt64) -> LifeSimulator {
        var state = LifeState(name: "Year Latency", seed: seed)
        state.character.age = 30
        state.lifeStage = .build
        state.flags.attendsSchool = false
        return LifeSimulator(state: state, store: BenchmarkPersistence())
    }

    private static func originIndex(_ origin: OriginPreset) -> Int {
        switch origin {
        case .balanced: 0
        case .academic: 1
        case .social: 2
        }
    }

    private static func median(_ values: [Int]) -> Int {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }

    private static func compositeScore(_ state: LifeState) -> Int {
        state.stats.school + state.stats.love + state.stats.play + state.stats.health + state.stats.rep
            + max(-100, min(100, state.cash / 1_000))
            + (state.partner?.bond ?? 50) / 2
            - min(50, state.finance.totalDebt / 1_000)
            - state.career.burnout / 2
    }
}
