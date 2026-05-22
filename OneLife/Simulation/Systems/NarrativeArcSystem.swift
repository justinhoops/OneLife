import Foundation

protocol ArcSeedGenerating {
    func generateCandidates(context: ArcSeedContext, state: GameState) -> [NarrativeArcCandidate]?
}

struct RemoteArcSeedGenerator: ArcSeedGenerating {
    struct ResponseEnvelope: Decodable {
        var candidates: [ResponseCandidate]
    }

    struct ResponseCandidate: Decodable {
        var id: String
        var title: String
        var theme: ArcTheme
        var primaryDomains: [ArcDomain]
        var eventTagWeights: [String: Int]
        var moodBias: [ArcMoodTone]
        var riskFlags: [String]
        var opportunityFlags: [String]
        var chapterTrigger: String?
        var pivotThreshold: Int?
        var collapseThreshold: Int?
        var minimumYearsBetweenPivots: Int?
        var generationScore: Int?
    }

    let provider: ((ArcSeedContext) -> Data?)?

    init(provider: ((ArcSeedContext) -> Data?)? = nil) {
        self.provider = provider
    }

    func generateCandidates(context: ArcSeedContext, state: GameState) -> [NarrativeArcCandidate]? {
        guard let provider, let data = provider(context) else { return nil }
        guard let envelope = try? JSONDecoder().decode(ResponseEnvelope.self, from: data) else { return nil }

        let allowedTags = Set(["school", "routine", "career", "money", "cost", "social", "romance", "health", "risk", "spend", "chance", "family"])
        let normalized = envelope.candidates.compactMap { candidate -> NarrativeArcCandidate? in
            let sanitizedTags = candidate.eventTagWeights.reduce(into: [String: Int]()) { partial, entry in
                guard allowedTags.contains(entry.key) else { return }
                partial[entry.key] = entry.value.clamped(to: 0...20)
            }

            guard !sanitizedTags.isEmpty else { return nil }
            guard !candidate.primaryDomains.isEmpty else { return nil }

            let title = candidate.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty, title.count <= 48 else { return nil }
            guard !title.contains("age ") && !title.contains("must ") else { return nil }

            let seed = NarrativeArcSeed(
                id: candidate.id,
                title: title,
                theme: candidate.theme,
                primaryDomains: candidate.primaryDomains,
                influence: ArcInfluenceProfile(
                    eventTagWeights: sanitizedTags,
                    moodBias: Array(candidate.moodBias.prefix(3)),
                    riskFlags: Array(candidate.riskFlags.prefix(3)),
                    opportunityFlags: Array(candidate.opportunityFlags.prefix(3)),
                    pivotMetadata: ArcPivotMetadata(
                        chapterTrigger: candidate.chapterTrigger,
                        pivotThreshold: (candidate.pivotThreshold ?? 58).clamped(to: 45...80),
                        collapseThreshold: (candidate.collapseThreshold ?? 38).clamped(to: 20...55),
                        minimumYearsBetweenPivots: (candidate.minimumYearsBetweenPivots ?? 2).clamped(to: 1...5)
                    )
                )
            )

            return NarrativeArcCandidate(seed: seed, generationScore: (candidate.generationScore ?? 60).clamped(to: 1...100))
        }

        guard (2...5).contains(normalized.count) else { return nil }
        return normalized.sorted { $0.generationScore > $1.generationScore }
    }
}

struct LocalArcSeedGenerator: ArcSeedGenerating {
    func generateCandidates(context: ArcSeedContext, state: GameState) -> [NarrativeArcCandidate]? {
        let candidates = [
            candidate(
                id: "arc_academic_pressure",
                title: "High Promise Under Pressure",
                theme: .ambitionVsPressure,
                domains: [.education, .career, .health],
                influence: ArcInfluenceProfile(
                    eventTagWeights: ["school": 14, "career": 10, "routine": 8, "health": 5],
                    moodBias: [.focused, .tense, .exposed],
                    riskFlags: ["burnout", "expectation", "slip"],
                    opportunityFlags: ["recognition", "mentor", "breakthrough"],
                    pivotMetadata: ArcPivotMetadata(chapterTrigger: "early_adulthood", pivotThreshold: 60, collapseThreshold: 40, minimumYearsBetweenPivots: 2)
                ),
                score: scoreAcademicPressure(context)
            ),
            candidate(
                id: "arc_broke_ambitious",
                title: "Broke and Ambitious",
                theme: .scarcityVsEscape,
                domains: [.finance, .career, .housing],
                influence: ArcInfluenceProfile(
                    eventTagWeights: ["money": 16, "career": 11, "cost": 10, "risk": 5],
                    moodBias: [.guarded, .restless, .hopeful],
                    riskFlags: ["desperation", "shortcuts", "exhaustion"],
                    opportunityFlags: ["side_work", "escape_route", "unexpected_opening"],
                    pivotMetadata: ArcPivotMetadata(chapterTrigger: "job_entry", pivotThreshold: 57, collapseThreshold: 36, minimumYearsBetweenPivots: 2)
                ),
                score: scoreScarcityEscape(context)
            ),
            candidate(
                id: "arc_social_reckoning",
                title: "Charm with Loose Edges",
                theme: .charmVsImpulse,
                domains: [.relationships, .career, .finance],
                influence: ArcInfluenceProfile(
                    eventTagWeights: ["social": 14, "romance": 11, "risk": 8, "spend": 5],
                    moodBias: [.restless, .exposed, .hopeful],
                    riskFlags: ["drama", "status", "overreach"],
                    opportunityFlags: ["network_effect", "romance", "spotlight"],
                    pivotMetadata: ArcPivotMetadata(chapterTrigger: "visibility", pivotThreshold: 56, collapseThreshold: 35, minimumYearsBetweenPivots: 2)
                ),
                score: scoreSocialImpulse(context)
            ),
            candidate(
                id: "arc_discipline_drift",
                title: "Talent Against Drift",
                theme: .disciplineVsDrift,
                domains: [.education, .career, .identity],
                influence: ArcInfluenceProfile(
                    eventTagWeights: ["routine": 13, "school": 10, "career": 9, "chance": 4],
                    moodBias: [.focused, .steady, .restless],
                    riskFlags: ["drift", "inconsistency", "stall"],
                    opportunityFlags: ["lock_in", "routine", "late_surge"],
                    pivotMetadata: ArcPivotMetadata(chapterTrigger: "routine_reset", pivotThreshold: 55, collapseThreshold: 37, minimumYearsBetweenPivots: 2)
                ),
                score: scoreDisciplineDrift(context)
            ),
            candidate(
                id: "arc_stability_sacrifice",
                title: "Stability Bought Slowly",
                theme: .stabilityVsSacrifice,
                domains: [.finance, .family, .relationships],
                influence: ArcInfluenceProfile(
                    eventTagWeights: ["money": 10, "family": 9, "routine": 8, "cost": 8],
                    moodBias: [.steady, .guarded, .tense],
                    riskFlags: ["overload", "self_denial", "resentment"],
                    opportunityFlags: ["provider_role", "home_base", "earned_security"],
                    pivotMetadata: ArcPivotMetadata(chapterTrigger: "commitment", pivotThreshold: 58, collapseThreshold: 40, minimumYearsBetweenPivots: 3)
                ),
                score: scoreStabilitySacrifice(context)
            ),
            candidate(
                id: "arc_the_benefactor",
                title: "The Benefactor",
                theme: .belongingVsRisk,
                domains: [.relationships, .finance, .identity],
                influence: ArcInfluenceProfile(
                    eventTagWeights: ["social": 18, "money": 10, "chance": 8],
                    moodBias: [.hopeful, .steady, .tense],
                    riskFlags: ["overload", "drama"],
                    opportunityFlags: ["found_support", "recognition", "fast_move"],
                    pivotMetadata: ArcPivotMetadata(chapterTrigger: "generosity", pivotThreshold: 55, collapseThreshold: 35, minimumYearsBetweenPivots: 2)
                ),
                score: scoreBenefactor(context, state: state)
            ),
            candidate(
                id: "arc_health_momentum",
                title: "Recovery Against Momentum",
                theme: .healthVsMomentum,
                domains: [.health, .education, .career],
                influence: ArcInfluenceProfile(
                    eventTagWeights: ["health": 15, "routine": 10, "school": 5, "career": 5],
                    moodBias: [.guarded, .focused, .cornered],
                    riskFlags: ["setback", "fatigue", "burnout"],
                    opportunityFlags: ["recovery", "discipline", "stability"],
                    pivotMetadata: ArcPivotMetadata(chapterTrigger: "recovery_window", pivotThreshold: 56, collapseThreshold: 36, minimumYearsBetweenPivots: 2)
                ),
                score: scoreHealthMomentum(context)
            ),
            candidate(
                id: "arc_luck_restlessness",
                title: "Lucky Break, Unsettled Core",
                theme: .luckVsRestlessness,
                domains: [.career, .finance, .identity],
                influence: ArcInfluenceProfile(
                    eventTagWeights: ["chance": 14, "career": 8, "money": 7, "social": 4],
                    moodBias: [.hopeful, .restless, .exposed],
                    riskFlags: ["waste", "overconfidence", "drift"],
                    opportunityFlags: ["opening", "unexpected_help", "fast_move"],
                    pivotMetadata: ArcPivotMetadata(chapterTrigger: "luck_turn", pivotThreshold: 57, collapseThreshold: 35, minimumYearsBetweenPivots: 2)
                ),
                score: scoreLuckRestlessness(context)
            ),
            candidate(
                id: "arc_belonging_risk",
                title: "Belonging Under Pull",
                theme: .belongingVsRisk,
                domains: [.relationships, .health, .finance],
                influence: ArcInfluenceProfile(
                    eventTagWeights: ["social": 10, "romance": 9, "risk": 6, "money": 4],
                    moodBias: [.isolated, .hopeful, .tense],
                    riskFlags: ["bad_company", "dependency", "distance"],
                    opportunityFlags: ["found_support", "count_support", "commitment"],
                    pivotMetadata: ArcPivotMetadata(chapterTrigger: "social_turn", pivotThreshold: 55, collapseThreshold: 34, minimumYearsBetweenPivots: 2)
                ),
                score: scoreBelongingRisk(context)
            )
        ]
            .filter { $0.generationScore > 0 }
            .sorted { lhs, rhs in
                if lhs.generationScore == rhs.generationScore {
                    return lhs.seed.id < rhs.seed.id
                }
                return lhs.generationScore > rhs.generationScore
            }

        let selected = Array(candidates.prefix(3))
        if selected.count >= 2 {
            return selected
        }

        let fallback = candidate(
            id: "arc_default_pressure",
            title: "Pressure Taking Shape",
            theme: .disciplineVsDrift,
            domains: [.education, .finance, .health],
            influence: ArcInfluenceProfile(
                eventTagWeights: ["routine": 8, "school": 6, "money": 6],
                moodBias: [.steady, .tense],
                riskFlags: ["drift"],
                opportunityFlags: ["small_gain"],
                pivotMetadata: ArcPivotMetadata()
            ),
            score: 52
        )
        let padded = Array((selected + [fallback]).prefix(2))
        return padded
    }

    private func candidate(id: String, title: String, theme: ArcTheme, domains: [ArcDomain], influence: ArcInfluenceProfile, score: Int) -> NarrativeArcCandidate {
        NarrativeArcCandidate(
            seed: NarrativeArcSeed(id: id, title: title, theme: theme, primaryDomains: domains, influence: influence),
            generationScore: score.clamped(to: 0...100)
        )
    }

    private func hasAnyTag(_ tags: [String], in context: ArcSeedContext) -> Bool {
        !Set(tags).isDisjoint(with: context.focusTags + context.openingTags)
    }

    private func scoreAcademicPressure(_ context: ArcSeedContext) -> Int {
        var score = 18 + context.smarts / 3 + context.schoolStanding / 3
        if hasAnyTag(["school", "career"], in: context) { score += 12 }
        if context.traits.contains(.disciplined) { score += 10 }
        if context.traits.contains(.anxious) { score += 6 }
        if context.financialStress >= 24 { score += 6 }
        return score
    }

    private func scoreScarcityEscape(_ context: ArcSeedContext) -> Int {
        var score = 20 + context.financialStress + max(0, 30 - min(context.cashOnHand / 20, 30))
        if hasAnyTag(["money", "cost", "career"], in: context) { score += 12 }
        if context.housingStability < 58 { score += 8 }
        return score
    }

    private func scoreSocialImpulse(_ context: ArcSeedContext) -> Int {
        var score = 14 + context.looks / 4 + context.happiness / 5
        if hasAnyTag(["social", "romance"], in: context) { score += 12 }
        if context.traits.contains(.charismatic) { score += 12 }
        if context.traits.contains(.impulsive) { score += 10 }
        return score
    }

    private func scoreDisciplineDrift(_ context: ArcSeedContext) -> Int {
        var score = 16 + context.smarts / 4 + context.engagement / 4
        if context.traits.contains(.disciplined) { score += 14 }
        if context.traits.contains(.impulsive) { score += 4 }
        if hasAnyTag(["routine", "school"], in: context) { score += 10 }
        return score
    }

    private func scoreStabilitySacrifice(_ context: ArcSeedContext) -> Int {
        var score = 10 + max(0, 65 - context.financialStress)
        if context.age >= 18 { score += 8 }
        if hasAnyTag(["money", "family", "routine"], in: context) { score += 10 }
        if context.traits.contains(.disciplined) { score += 8 }
        return score
    }

    private func scoreBenefactor(_ context: ArcSeedContext, state: GameState) -> Int {
        let helpCount = state.consequences.narrativeFlags.filter { $0.key.hasPrefix("helped_") && $0.value > 0 }.count
        var score = 10 + (helpCount * 15)
        if hasAnyTag(["social", "money"], in: context) { score += 10 }
        if context.traits.contains(.charismatic) { score += 8 }
        return score
    }

    private func scoreHealthMomentum(_ context: ArcSeedContext) -> Int {
        var score = 14 + max(0, 60 - context.health) + max(0, 55 - context.housingStability) / 2
        if hasAnyTag(["health", "routine"], in: context) { score += 14 }
        if context.traits.contains(.anxious) { score += 6 }
        return score
    }

    private func scoreLuckRestlessness(_ context: ArcSeedContext) -> Int {
        var score = 12 + context.cashOnHand / 120 + context.happiness / 6
        if context.templateID == .luckyBreak { score += 24 }
        if hasAnyTag(["chance"], in: context) { score += 12 }
        if context.traits.contains(.lucky) { score += 12 }
        return score
    }

    private func scoreBelongingRisk(_ context: ArcSeedContext) -> Int {
        var score = 12 + context.happiness / 6
        if hasAnyTag(["social", "romance", "risk"], in: context) { score += 10 }
        if context.traits.contains(.charismatic) { score += 6 }
        if context.traits.contains(.anxious) || context.traits.contains(.impulsive) { score += 6 }
        if context.financialStress >= 20 { score += 4 }
        return score
    }
}

struct NarrativeArcSystem {
    private let remoteGenerator: any ArcSeedGenerating
    private let localGenerator: any ArcSeedGenerating

    init(
        remoteGenerator: any ArcSeedGenerating = RemoteArcSeedGenerator(),
        localGenerator: any ArcSeedGenerating = LocalArcSeedGenerator()
    ) {
        self.remoteGenerator = remoteGenerator
        self.localGenerator = localGenerator
    }

    func populatePreviewArcs(for state: inout GameState) {
        let context = makeContext(for: state)
        let generated = remoteGenerator.generateCandidates(context: context, state: state)
            ?? localGenerator.generateCandidates(context: context, state: state)
            ?? []

        state.narrativeArcs.candidates = Array(generated.prefix(5))
        state.narrativeArcs.arcAlignmentScores = Dictionary(uniqueKeysWithValues: state.narrativeArcs.candidates.map { ($0.id, $0.generationScore) })
        if state.narrativeArcs.primaryArcID == nil {
            if let templateID = state.originProfile?.templateID,
               let preferredID = preferredPrimaryArcID(for: templateID),
               state.narrativeArcs.candidates.contains(where: { $0.id == preferredID }) {
                state.narrativeArcs.primaryArcID = preferredID
            } else {
                state.narrativeArcs.primaryArcID = state.narrativeArcs.candidates.first?.id
            }
        }
        if state.narrativeArcs.secondaryArcID == nil {
            state.narrativeArcs.secondaryArcID = state.narrativeArcs.candidates.dropFirst().first?.id
        }
        if state.narrativeArcs.currentMoodTone == nil {
            state.narrativeArcs.currentMoodTone = state.narrativeArcs.primaryCandidate?.seed.influence.moodBias.first
        }
    }

    private func preferredPrimaryArcID(for templateID: OriginTemplateID) -> String? {
        switch templateID {
        case .academicPromise:
            return "arc_academic_pressure"
        case .financialStrainToughenedEarly:
            return "arc_broke_ambitious"
        case .socialMagnet:
            return "arc_social_reckoning"
        case .fragileHealthStart:
            return "arc_health_momentum"
        case .chaoticHomeSelfReliant:
            return "arc_belonging_risk"
        case .stableHomeAverageMeans, .luckyBreak, .wealthyDynasty, .academicLegacy, .ruralEscapist, .techProdigy, .artisticDrifter:
            return nil
        }
    }

    func activatePreview(for state: inout GameState) -> DomainYearResult {
        if state.narrativeArcs.candidates.isEmpty {
            populatePreviewArcs(for: &state)
        }

        var result = DomainYearResult()
        guard let primary = state.narrativeArcs.primaryCandidate?.seed else { return result }
        state.narrativeArcs.currentMoodTone = resolvedMood(for: primary, state: state, alignmentScore: state.narrativeArcs.arcAlignmentScores[primary.id] ?? 60)
        result.notes.append(
            DomainNote(
                title: "Chapter Pressure",
                text: openingNote(for: primary, secondary: state.narrativeArcs.secondaryCandidate?.seed),
                tags: [.progress, .lifeEvent]
            )
        )
        return result
    }

    func preferredTagWeights(for state: GameState) -> [String: Int] {
        state.narrativeArcs.activeCandidates.reduce(into: [String: Int]()) { partial, candidate in
            for (tag, weight) in candidate.seed.influence.eventTagWeights {
                partial[tag, default: 0] += weight
            }
        }
    }

    func evaluateYear(before: GameState, after state: inout GameState) -> DomainYearResult {
        if state.narrativeArcs.candidates.isEmpty {
            populatePreviewArcs(for: &state)
        }

        var result = DomainYearResult()
        guard !state.narrativeArcs.candidates.isEmpty else { return result }

        let scored = state.narrativeArcs.candidates.map { candidate in
            (candidate, alignmentScore(for: candidate.seed, state: state))
        }
        for (candidate, score) in scored {
            let previous = state.narrativeArcs.arcAlignmentScores[candidate.id] ?? candidate.generationScore
            state.narrativeArcs.arcAlignmentScores[candidate.id] = ((previous + score) / 2).clamped(to: 0...100)
        }

        let ranked = scored
            .filter { !state.narrativeArcs.suppressedArcIDs.contains($0.0.id) }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.generationScore > rhs.0.generationScore
                }
                return lhs.1 > rhs.1
            }

        guard let top = ranked.first else { return result }
        let currentPrimaryID = state.narrativeArcs.primaryArcID
        let currentPrimaryScore = currentPrimaryID.flatMap { id in
            state.narrativeArcs.arcAlignmentScores[id]
        } ?? top.1
        let currentPrimaryCandidate = currentPrimaryID.flatMap { state.narrativeArcs.candidate(for: $0) }
        let currentPrimaryFreshScore = currentPrimaryCandidate.map { alignmentScore(for: $0.seed, state: state) } ?? currentPrimaryScore
        let yearsSincePivot = state.narrativeArcs.lastPivotAge.map { max(0, state.player.age - $0) } ?? Int.max
        let severeMismatch = currentPrimaryFreshScore <= max(28, currentPrimaryScore - 18)

        if let primary = state.narrativeArcs.primaryCandidate?.seed {
            state.narrativeArcs.currentMoodTone = resolvedMood(for: primary, state: state, alignmentScore: currentPrimaryScore)
        }

        if let currentPrimaryID,
           top.0.id != currentPrimaryID,
           top.1 >= max(top.0.seed.influence.pivotMetadata.pivotThreshold, severeMismatch ? currentPrimaryScore + 4 : currentPrimaryScore + 8),
           yearsSincePivot >= top.0.seed.influence.pivotMetadata.minimumYearsBetweenPivots {
            state.narrativeArcs.primaryArcID = top.0.id
            state.narrativeArcs.secondaryArcID = ranked.dropFirst().first?.0.id
            state.narrativeArcs.lastPivotAge = state.player.age
            state.narrativeArcs.currentMoodTone = resolvedMood(for: top.0.seed, state: state, alignmentScore: top.1)
            result.notes.append(
                DomainNote(
                    title: "Chapter Pressure",
                    text: pivotNote(from: state.narrativeArcs.candidate(for: currentPrimaryID)?.seed, to: top.0.seed),
                    tags: [.progress, .lifeEvent]
                )
            )
            return result
        }

        if let currentPrimaryID,
           currentPrimaryFreshScore <= (currentPrimaryCandidate?.seed.influence.pivotMetadata.collapseThreshold ?? 38),
           yearsSincePivot >= 2 {
            state.narrativeArcs.suppressedArcIDs.append(currentPrimaryID)
            state.narrativeArcs.suppressedArcIDs = Array(Set(state.narrativeArcs.suppressedArcIDs))
            state.narrativeArcs.primaryArcID = top.0.id == currentPrimaryID ? ranked.dropFirst().first?.0.id : top.0.id
            state.narrativeArcs.secondaryArcID = ranked.first(where: { $0.0.id != state.narrativeArcs.primaryArcID })?.0.id
            state.narrativeArcs.lastPivotAge = state.player.age
            if let nextPrimary = state.narrativeArcs.primaryCandidate?.seed {
                state.narrativeArcs.currentMoodTone = resolvedMood(for: nextPrimary, state: state, alignmentScore: top.1)
            }
            result.notes.append(
                DomainNote(
                    title: "Chapter Pressure",
                    text: collapseNote(before: before, after: state),
                    tags: [.progress, .lifeEvent]
                )
            )
        }

        if result.notes.isEmpty,
           let currentPrimaryID,
           top.0.id != currentPrimaryID,
           severeMismatch,
           yearsSincePivot >= 1 {
            result.notes.append(
                DomainNote(
                    title: "Chapter Pressure",
                    text: "The old pattern is slipping, even if the next one has not fully taken over yet.",
                    tags: [.progress, .lifeEvent]
                )
            )
        }

        let explicitStrainState =
            state.finance.financialStress >= 70 ||
            state.housing.housingStability <= 30 ||
            (state.education.schoolStanding <= 40 && state.education.burnoutRisk >= 70)

        if result.notes.isEmpty, explicitStrainState {
            result.notes.append(
                DomainNote(
                    title: "Chapter Pressure",
                    text: "This life is carrying enough visible strain that the current chapter no longer feels stable, even if its next shape is still forming.",
                    tags: [.progress, .lifeEvent]
                )
            )
        }

        return result
    }

    private func makeContext(for state: GameState) -> ArcSeedContext {
        ArcSeedContext(
            templateID: state.originProfile?.templateID,
            focusTags: state.originProfile?.focusTags ?? [],
            openingTags: state.originProfile?.openingEventSeed ?? [],
            householdPressure: state.originProfile?.householdPressure ?? "",
            schoolStandingText: state.originProfile?.schoolStanding ?? "",
            socialSupportText: state.originProfile?.socialSupport ?? "",
            startingCashBand: state.originProfile?.startingCashBand ?? "",
            age: state.player.age,
            traits: state.player.traits,
            happiness: state.player.happiness,
            smarts: state.player.smarts,
            looks: state.player.looks,
            health: state.player.health,
            schoolStanding: state.education.schoolStanding,
            engagement: state.education.engagement,
            financialStress: state.finance.financialStress,
            cashOnHand: state.finance.cashOnHand,
            housingStability: state.housing.housingStability
        )
    }

    private func alignmentScore(for seed: NarrativeArcSeed, state: GameState) -> Int {
        let domainScores = seed.primaryDomains.map { domainScore(for: $0, state: state) }
        let base = domainScores.isEmpty ? 50 : domainScores.reduce(0, +) / domainScores.count

        let tagWeightSignal = seed.influence.eventTagWeights.keys.reduce(0) { partial, tag in
            partial + self.tagSignal(for: tag, state: state)
        }
        let riskLoad = seed.influence.riskFlags.reduce(0) { partial, risk in
            partial + riskSignal(for: risk, state: state)
        }

        return (base + min(18, tagWeightSignal / 2) + min(12, riskLoad / 3)).clamped(to: 0...100)
    }

    private func domainScore(for domain: ArcDomain, state: GameState) -> Int {
        switch domain {
        case .education:
            return ((state.education.schoolStanding + state.education.engagement + state.education.teacherSupport) / 3 - state.education.burnoutRisk / 4).clamped(to: 0...100)
        case .career:
            let incomeScore = min(100, max(0, state.career.annualIncome / 800))
            let employmentBonus = state.career.status == .fullTime ? 12 : (state.career.status == .partTime ? 6 : 0)
            return (state.career.performance + incomeScore + employmentBonus).clamped(to: 0...100)
        case .finance:
            let stability = 60 - state.finance.financialStress + min(24, max(0, state.finance.cashOnHand) / 2_000)
            return stability.clamped(to: 0...100)
        case .relationships:
            let strongestBond = max(state.relationships.friends.strongestBond, state.relationships.partnerBond)
            return (strongestBond + min(20, state.relationships.friends.count * 4) + (state.relationships.hasPartner ? 10 : 0)).clamped(to: 0...100)
        case .health:
            return ((state.player.health + state.healthProfile.physicalWellness + state.healthProfile.mentalWellness) / 3).clamped(to: 0...100)
        case .housing:
            return state.housing.housingStability.clamped(to: 0...100)
        case .family:
            let bond = state.relationships.partnerBond
            let loadPenalty = state.family.childCount > 0 ? min(16, state.finance.financialStress / 3) : 0
            return (bond + (state.relationships.hasPartner ? 10 : 0) - loadPenalty).clamped(to: 0...100)
        case .identity:
            return ((state.player.happiness + state.player.smarts + state.player.looks) / 3).clamped(to: 0...100)
        }
    }

    private func tagSignal(for tag: String, state: GameState) -> Int {
        switch tag {
        case "school":
            return state.education.schoolStanding / 10
        case "routine":
            return (state.healthProfile.habits.stressManagement + state.healthProfile.habits.exercise) / 25
        case "career":
            return state.career.performance / 10
        case "money":
            return max(0, 8 - state.finance.financialStress / 8) + min(8, max(0, state.finance.cashOnHand) / 4_000)
        case "cost":
            return state.finance.financialStress / 12
        case "social":
            return min(8, state.relationships.friends.count * 2) + max(0, state.relationships.friends.strongestBond / 20)
        case "romance":
            return state.relationships.hasPartner ? 8 + state.relationships.partnerBond / 18 : 0
        case "health":
            return max(0, (100 - min(state.healthProfile.mentalWellness, state.healthProfile.physicalWellness)) / 10)
        case "risk":
            return state.player.traits.contains(.impulsive) ? 8 : 2
        case "spend":
            return max(0, state.finance.annualDiscretionaryCost / 1_000)
        case "chance":
            return state.player.traits.contains(.lucky) ? 8 : 3
        case "family":
            return state.family.childCount > 0 || state.family.isPregnant ? 8 : (state.relationships.hasPartner ? 4 : 0)
        default:
            return 0
        }
    }

    private func riskSignal(for risk: String, state: GameState) -> Int {
        switch risk {
        case "burnout":
            return state.education.burnoutRisk / 12
        case "expectation":
            return max(0, state.education.schoolStanding - 60) / 10
        case "shortcuts", "overreach":
            return state.player.traits.contains(.impulsive) ? 8 : 2
        case "exhaustion", "fatigue", "setback":
            return max(0, 55 - state.player.health) / 10
        case "drama", "distance", "dependency":
            return max(0, 55 - max(state.relationships.friends.strongestBond, state.relationships.partnerBond)) / 12
        case "overload", "self_denial":
            return state.finance.financialStress / 12
        case "drift", "stall":
            return max(0, 55 - state.education.engagement) / 10
        case "waste", "overconfidence":
            return state.player.traits.contains(.lucky) || state.player.traits.contains(.impulsive) ? 6 : 2
        case "bad_company":
            return state.player.traits.contains(.impulsive) && state.relationships.friends.count > 0 ? 7 : 2
        default:
            return 0
        }
    }

    private func resolvedMood(for seed: NarrativeArcSeed, state: GameState, alignmentScore: Int) -> ArcMoodTone? {
        let moods = seed.influence.moodBias
        guard !moods.isEmpty else { return nil }
        if alignmentScore >= 68 {
            return moods.first
        }
        if alignmentScore <= 42 {
            return moods.last
        }
        return moods.dropFirst().first ?? moods.first
    }

    private func openingNote(for primary: NarrativeArcSeed, secondary: NarrativeArcSeed?) -> String {
        let lead = primary.theme.previewLabel.lowercased()
        if let secondary {
            return "A pattern is already forming around \(lead), with a second pull toward \(secondary.theme.previewLabel.lowercased())."
        }
        return "A pattern is already forming around \(lead), and the next few years will keep testing it."
    }

    private func pivotNote(from: NarrativeArcSeed?, to: NarrativeArcSeed) -> String {
        if let from {
            return "The pressure in this life shifted away from \(from.theme.previewLabel.lowercased()) and toward \(to.theme.previewLabel.lowercased())."
        }
        return "A new pressure pattern is taking shape around \(to.theme.previewLabel.lowercased())."
    }

    private func collapseNote(before: GameState, after: GameState) -> String {
        if after.finance.financialStress > before.finance.financialStress && after.healthProfile.mentalWellness < before.healthProfile.mentalWellness {
            return "The previous shape of this life broke under stacked pressure, and a harsher pattern is starting to replace it."
        }
        return "The old pattern lost its grip. This life is bending in a different direction now."
    }
}
