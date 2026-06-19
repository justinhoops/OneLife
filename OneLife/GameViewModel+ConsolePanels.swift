import Foundation

extension GameViewModel {
    func lifeConsoleSnapshot() -> LifeConsoleSnapshot {
        LifeConsoleSnapshot(
            name: state.player.name,
            age: state.player.age,
            role: headerOccupationHighlight().title,
            cash: formattedCashOnHand(),
            cashTone: state.finance.cashOnHand >= 0 ? .positive : .warning,
            health: state.player.health,
            healthTone: state.player.health < 45 ? .warning : .positive,
            topPressures: Array(feedUrgencyItems().prefix(3)),
            selectedAction: pendingActionSummary(),
            ageUpRisk: ageUpRiskPreviewSignals(),
            eraName: state.currentEra.displayName,
            eraIcon: state.currentEra.icon,
            eraTone: state.currentEra.tone
        )
    }

    func domainPanel(for domain: ConsoleDomain) -> DomainPanelModel {
        if let panel = cachedConsolePresentation.panels[domain] {
            return panel
        }
        return buildDomainPanel(for: domain)
    }

    func buildDomainPanel(for domain: ConsoleDomain) -> DomainPanelModel {
        let registry = makeActionRegistry()
        let riskQuick = registry.isCrimeLaneActive() ? quickActionModels(for: .crime) : []
        let riskPlan = registry.isCrimeLaneActive() ? actionModels(for: .crime) : []
        let familyQuick = registry.familyPhaseIsActive() ? familyQuickActionModels(registry: registry) : []
        let familyPlan = registry.familyPhaseIsActive() ? familyYearPlanModels(registry: registry) : []

        switch domain {
        case .life:
            return DomainPanelModel(
                id: .life,
                title: "Life",
                icon: "figure.play",
                tone: feedUrgencyItems().contains(where: { $0.tone == .warning }) ? .warning : .neutral,
                status: chapterStatus(),
                velocity: nextDecisionPrompt().isEmpty ? pendingActionSummary() : nextDecisionPrompt(),
                metrics: [
                    ConsoleMetricModel(title: "Cash", value: formattedCashOnHand(), tone: state.finance.cashOnHand >= 0 ? .positive : .warning),
                    ConsoleMetricModel(title: "Health", value: "\(state.player.health)%", tone: bodyTone()),
                    ConsoleMetricModel(title: "Rep", value: "\(state.relationships.publicReputation)", tone: state.relationships.publicReputation < 35 ? .warning : .neutral)
                ],
                pressureLine: feedUrgencyItems().first(where: { $0.tone == .warning })?.value ?? "No loud pressure yet. Tap a right-now action or set a year stance.",
                quickActions: homeQuickActionModels(),
                actions: homeYearPlanModels(),
                actionSections: nil,
                riskQuickActions: riskQuick,
                riskActions: riskPlan,
                familyQuickActions: [],
                familyActions: [],
                detailDestination: nil,
                detailButtonIdentifier: nil,
                previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] }
            )
        case .work:
            if state.military.track != .inactive {
                return DomainPanelModel(
                    id: .work,
                    title: state.military.branch?.displayName ?? "Military",
                    icon: "shield.fill",
                    tone: state.military.isAWOL ? .warning : .neutral,
                    status: "\(state.military.rank) (\(state.military.specialty?.displayName ?? "Unspecialized"))",
                    velocity: state.military.isAWOL ? "You are AWOL! Desertion risk is high." : "Served: \(state.military.yearsServed)y. Contract: \(state.military.contractYearsRemaining)y. \(state.military.track.rawValue.capitalized).",
                    metrics: [
                        ConsoleMetricModel(title: "Fitness", value: "\(state.military.fitness)", tone: state.military.fitness < 40 ? .warning : .positive),
                        ConsoleMetricModel(title: "Discipline", value: "\(state.military.discipline)", tone: state.military.discipline < 40 ? .warning : .positive),
                        ConsoleMetricModel(title: "Trauma", value: "\(state.military.combatTrauma)", tone: state.military.combatTrauma > 40 ? .warning : .neutral)
                    ],
                    pressureLine: state.military.deploymentStatus == .activeCombat ? "ACTIVE COMBAT! Survival is the priority." : (state.military.combatTrauma > 50 ? "War trauma is bleeding into your daily stability." : "Duty and discipline are the backbone of your year."),
                    quickActions: quickActionModels(for: .military),
                    actions: actionModels(for: .military),
                    actionSections: nil,
                    riskQuickActions: riskQuick,
                    riskActions: riskPlan,
                    familyQuickActions: [],
                    familyActions: [],
                    detailDestination: .careerOverview,
                    detailButtonIdentifier: "military-overview-detail-button",
                    previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] }
                )
            }
            let actionDomain: ActionDomain = showingEducationAsPrimaryTab ? .education : .career
            let isAthleteTrack = !showingEducationAsPrimaryTab && state.specialCareer.track == .athlete
            let workMetrics: [ConsoleMetricModel]
            let workStatus: String
            let workVelocity: String
            let workPressure: String
            if showingEducationAsPrimaryTab {
                workMetrics = consoleMetrics(teenSchoolClimateMetrics())
                workStatus = educationStatusLine()
                workVelocity = "Applications, standing, and burnout decide what opens next."
                workPressure = teenPressureSources().first ?? "School is stable enough to plan deliberately."
            } else if isAthleteTrack {
                workMetrics = CohesionNarrative.athletePillarMetrics(from: state).map {
                    ConsoleMetricModel(title: $0.title, value: $0.value, tone: $0.tone)
                }
                workStatus = state.career.specializedTrack != nil ? state.career.professionalRank : roleTitle()
                workVelocity = CohesionNarrative.athletePillarPressureLine(from: state)
                workPressure = CohesionNarrative.athletePillarPressureLine(from: state)
            } else {
                workMetrics = [
                    ConsoleMetricModel(title: "Perf", value: "\(state.career.performance)", tone: state.career.performance >= 70 ? .positive : (state.career.performance < 45 ? .warning : .neutral)),
                    ConsoleMetricModel(title: "Income", value: "$\(state.career.annualIncome)", tone: state.career.annualIncome > 0 ? .positive : .warning),
                    ConsoleMetricModel(title: "Burnout", value: "\(state.career.burnout)", tone: state.career.burnout >= 58 ? .warning : .neutral)
                ]
                workStatus = state.career.specializedTrack != nil ? state.career.professionalRank : roleTitle()
                workVelocity = "Performance, income, and burnout decide whether work becomes stability or drag."
                workPressure = state.career.status == .unemployed ? "Stable work is missing." : "Work is active, but performance still has to survive the year."
            }
            return DomainPanelModel(
                id: .work,
                title: showingEducationAsPrimaryTab ? "Education" : "Career",
                icon: showingEducationAsPrimaryTab ? "book.closed.fill" : "briefcase.fill",
                tone: workTone(),
                status: workStatus,
                velocity: workVelocity,
                metrics: workMetrics,
                pressureLine: workPressure,
                quickActions: quickActionModels(for: actionDomain),
                actions: actionModels(for: actionDomain),
                actionSections: nil,
                riskQuickActions: riskQuick,
                riskActions: riskPlan,
                familyQuickActions: [],
                familyActions: [],
                detailDestination: showingEducationAsPrimaryTab ? .educationOverview : .careerOverview,
                detailButtonIdentifier: showingEducationAsPrimaryTab ? "education-overview-detail-button" : "career-overview-detail-button",
                previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] }
            )
        case .money:
            var moneyMetrics = [
                ConsoleMetricModel(title: "Cash", value: formattedCashOnHand(), tone: state.finance.cashOnHand >= 0 ? .positive : .warning),
                ConsoleMetricModel(title: "Portfolio", value: "$\(state.finance.portfolio.totalValue)", tone: .positive),
                ConsoleMetricModel(title: "Projected", value: "\(projectedNetFlow() >= 0 ? "+" : "")$\(projectedNetFlow())", tone: projectedNetFlow() < 0 ? .warning : .positive)
            ]
            if state.assets.effectiveLifestyleScore >= 40 {
                moneyMetrics[2] = ConsoleMetricModel(
                    title: "Lifestyle",
                    value: "\(state.assets.effectiveLifestyleScore)",
                    tone: state.assets.effectiveLifestyleScore >= 60 ? .positive : .neutral
                )
            }
            return DomainPanelModel(
                id: .money,
                title: "Money",
                icon: "dollarsign.circle.fill",
                tone: moneyTone(),
                status: state.finance.lastYearBalanceDelta < 0 ? "Deficit pressure" : "Cash flow holding",
                velocity: collectionGlanceItem().map { "\($0.label): \($0.subtitle)" }
                    ?? "Net last year: \(signedCurrency(state.finance.lastYearBalanceDelta)). Stress \(state.finance.financialStress).",
                metrics: moneyMetrics,
                pressureLine: state.finance.financialStress >= 45 || state.finance.lastYearBalanceDelta < 0 ? "Money is shaping the rest of life right now." : "Money is contained, but not comfortable enough to ignore.",
                quickActions: quickActionModels(for: .finance),
                actions: [],
                actionSections: nil,
                riskQuickActions: [],
                riskActions: [],
                familyQuickActions: [],
                familyActions: [],
                detailDestination: .financeCashflow,
                detailButtonIdentifier: "finance-cashflow-detail-button",
                previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] },
                secondaryAction: ("Liquidate Low-Value Assets", "bag.badge.minus", { [weak self] in self?.sellLowValueAssets() })
            )
        case .people:
            let familyActive = registry.familyPhaseIsActive()
            let household = cachedFamilyHouseholdSnapshot
            let peopleMetrics: [ConsoleMetricModel]
            let peopleStatus: String
            let peoplePressure: String
            if familyActive, state.family.childCount > 0 {
                var metrics = [
                    ConsoleMetricModel(
                        title: "At Home",
                        value: "\(household.atHomeCount)",
                        tone: household.atHomeCount == 0 ? .neutral : .positive
                    ),
                    ConsoleMetricModel(
                        title: "Adults",
                        value: "\(household.adultCount)",
                        tone: household.adultCount > 0 ? .neutral : .positive
                    )
                ]
                if state.relationships.hasPartner {
                    metrics.append(ConsoleMetricModel(
                        title: "Partner",
                        value: "\(state.relationships.partnerBond)",
                        tone: state.relationships.partnerBond < 45 ? .warning : .neutral
                    ))
                } else if let bondName = household.strongestBondChildName {
                    metrics.append(ConsoleMetricModel(
                        title: "Top Bond",
                        value: "\(bondName) \(household.strongestBondValue)",
                        tone: household.strongestBondValue >= 60 ? .positive : .warning
                    ))
                } else {
                    metrics.append(ConsoleMetricModel(
                        title: "Friends",
                        value: "\(state.relationships.friends.count)",
                        tone: state.relationships.friends.isEmpty ? .warning : .neutral
                    ))
                }
                peopleMetrics = metrics
                peopleStatus = household.pregnancyActive
                    ? "Pregnancy active · \(household.atHomeCount) at home"
                    : "\(household.atHomeCount) at home · \(household.adultCount) grown"
                peoplePressure = household.headlineChildLine
                    ?? household.topPressureLine
                    ?? npcAutonomyPulse()
                    ?? "Parenting choices stack into who they become."
            } else {
                peopleMetrics = [
                    ConsoleMetricModel(title: "Friends", value: "\(state.relationships.friends.count)", tone: state.relationships.friends.isEmpty ? .warning : .positive),
                    ConsoleMetricModel(title: "Partner", value: "\(state.relationships.partnerBond)", tone: state.relationships.partnerBond < 45 && state.relationships.hasPartner ? .warning : .neutral),
                    ConsoleMetricModel(title: "Tension", value: "\(state.relationships.activeTensionCount)", tone: state.relationships.activeTensionCount > 0 ? .warning : .neutral)
                ]
                peopleStatus = state.relationships.hasPartner ? "Partner active" : "\(state.relationships.friends.count) friends"
                peoplePressure = npcAutonomyPulse() ?? (state.relationships.activeTensionCount > 0 ? "Loose ends are making the year less stable." : "Relationships can absorb pressure if you keep them alive.")
            }
            return DomainPanelModel(
                id: .people,
                title: "People",
                icon: "person.2.fill",
                tone: peopleTone(),
                status: peopleStatus,
                velocity: familyActive
                    ? "Bond, household load, and adult outcomes decide how much support survives the year."
                    : "Bond, rumor heat, and family load decide how much support survives the year.",
                metrics: peopleMetrics,
                pressureLine: peoplePressure,
                quickActions: quickActionModels(for: .relationships),
                actions: [],
                actionSections: nil,
                riskQuickActions: [],
                riskActions: [],
                familyQuickActions: familyQuick,
                familyActions: familyPlan,
                detailDestination: state.family.isPregnant || state.family.childCount > 0 ? .relationshipsFamily : .relationshipsConnections,
                detailButtonIdentifier: state.family.isPregnant || state.family.childCount > 0 ? "relationships-family-detail-button" : "relationships-connections-detail-button",
                previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] }
            )
        case .body:
            return DomainPanelModel(
                id: .body,
                title: "Body",
                icon: "heart.fill",
                tone: bodyTone(),
                status: state.player.health < 45 ? "Fragile" : "Holding",
                velocity: "Health, sleep, stress, and active conditions set the pace for every other domain.",
                metrics: [
                    ConsoleMetricModel(title: "Health", value: "\(state.player.health)", tone: bodyTone()),
                    ConsoleMetricModel(title: "Mental", value: "\(state.healthProfile.mentalWellness)", tone: state.healthProfile.mentalWellness < 45 ? .warning : .neutral),
                    ConsoleMetricModel(title: "Stress", value: "\(100 - state.healthProfile.mentalWellness)", tone: state.healthProfile.mentalWellness < 45 ? .warning : .neutral)
                ],
                pressureLine: !state.healthProfile.activeConditions.isEmpty ? "Active conditions need attention before they compound." : "Recovery is playable, but neglect will leak into work and relationships.",
                quickActions: quickActionModels(for: .health),
                actions: [],
                actionSections: nil,
                riskQuickActions: [],
                riskActions: [],
                familyQuickActions: [],
                familyActions: [],
                detailDestination: .healthOverview,
                detailButtonIdentifier: "health-overview-detail-button",
                previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] }
            )
        case .activities:
            return DomainPanelModel(
                id: .activities,
                title: "Play",
                icon: "sparkles",
                tone: .positive,
                status: activityThisYearStatus(),
                velocity: "Instant hub — every flex resolves now.",
                metrics: [
                    ConsoleMetricModel(title: "Health", value: "\(state.player.health)", tone: bodyTone()),
                    ConsoleMetricModel(title: "Relief", value: "\(state.activities.recoveryBalance)", tone: .positive),
                    ConsoleMetricModel(title: "Risk", value: "\(state.activities.riskLoad)", tone: state.activities.riskLoad >= 8 ? .warning : .neutral)
                ],
                pressureLine: activityPushbackSummary(),
                quickActions: quickActionModels(for: .play),
                actions: [],
                actionSections: nil,
                riskQuickActions: [],
                riskActions: [],
                familyQuickActions: [],
                familyActions: [],
                detailDestination: nil,
                detailButtonIdentifier: nil,
                previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] }
            )
        case .log:
            return DomainPanelModel(
                id: .log,
                title: "Log",
                icon: "scroll.fill",
                tone: .neutral,
                status: "\(state.history.count) entries",
                velocity: state.history.first?.title ?? "Your story will build here after each year.",
                metrics: [
                    ConsoleMetricModel(title: "Years", value: "\(max(0, state.player.age - 14))", tone: .neutral),
                    ConsoleMetricModel(title: "Events", value: "\(state.history.count)", tone: .neutral),
                    ConsoleMetricModel(title: "Legacy", value: "\(state.progress.legacyScore)", tone: .neutral)
                ],
                pressureLine: "The log is for pattern recognition, not moment-to-moment play.",
                quickActions: [],
                actions: [],
                actionSections: nil,
                riskQuickActions: [],
                riskActions: [],
                familyQuickActions: [],
                familyActions: [],
                detailDestination: .lifeHistory,
                detailButtonIdentifier: "life-history-detail-button"
            )
        }
    }

    private func homeQuickActionModels() -> [ActionPresentationModel] {
        quickActionModels(for: .identity)
    }

    private func homeYearPlanModels() -> [ActionPresentationModel] {
        []
    }

    private func actionModels(for domain: ActionDomain, limit: Int = 12) -> [ActionPresentationModel] {
        let registry = makeActionRegistry()
        return actionChoices(for: domain)
            .filter { registry.resolutionTier(for: $0, domain: domain) == .committed }
            .prefix(limit)
            .map { actionPresentation(choiceID: $0, domain: domain) }
    }

    private func financeActionSectionModels(registry: DomainActionRegistry) -> [ActionSectionModel] {
        registry.financeActionSections().map { section in
            ActionSectionModel(
                id: section.id,
                title: "Year Plan — \(section.title)",
                actions: section.choices
                    .filter { registry.resolutionTier(for: $0, domain: .finance) == .committed }
                    .map { actionPresentation(choiceID: $0, domain: .finance) }
            )
        }
        .filter { !$0.actions.isEmpty }
    }

    private func familyQuickActionModels(registry: DomainActionRegistry) -> [ActionPresentationModel] {
        registry.familyPhaseQuickChoices().map { choiceID in
            let domain: ActionDomain = [.protectSleep, .rest, .seeDoctor, .pushThrough].contains(choiceID) ? .health : .relationships
            return quickActionPresentation(choiceID: choiceID, domain: domain)
        }
    }

    private func familyYearPlanModels(registry: DomainActionRegistry) -> [ActionPresentationModel] {
        registry.familyPhaseCommittedChoices().map { choiceID in
            let domain: ActionDomain = choiceID == .seeDoctor || choiceID == .protectSleep ? .health : .relationships
            return actionPresentation(choiceID: choiceID, domain: domain)
        }
    }

    private func quickActionModels(for domain: ActionDomain) -> [ActionPresentationModel] {
        quickActionChoices(for: domain).map { choiceID in
            quickActionPresentation(choiceID: choiceID, domain: domain)
        }
    }

    private func quickActionPresentation(choiceID: ActionChoiceID, domain: ActionDomain) -> ActionPresentationModel {
        var model = actionPresentation(choiceID: choiceID, domain: domain)
        model.title = QuickActionCatalog.title(for: choiceID)
        model.disabledReason = quickActionBlockReason(choiceID, domain: domain)
        model.isSelected = hasPerformedQuickAction(choiceID, domain: domain)
        return model
    }

    private func actionPresentation(choiceID: ActionChoiceID, domain: ActionDomain) -> ActionPresentationModel {
        let definition = ActionChoiceCatalog.definition(for: choiceID)
        let tone: PlannerTone = definition.baseFriction == .none ? .neutral : .warning
        return ActionPresentationModel(
            id: "\(domain)-\(choiceID.rawValue)",
            domain: domain,
            choiceID: choiceID,
            title: definition.title,
            subtitle: definition.subtitle,
            icon: actionIcon(for: definition),
            tone: tone,
            tags: Array(definition.previewTags.prefix(3)),
            disabledReason: definition.baseFriction == .locked ? "Locked right now" : nil,
            isSelected: selectedAction(for: domain) == choiceID
        )
    }

    private func consoleMetrics(_ items: [(String, String, PlannerTone)]) -> [ConsoleMetricModel] {
        items.prefix(3).map { ConsoleMetricModel(title: $0.0, value: $0.1, tone: $0.2) }
    }

    private func workTone() -> PlannerTone {
        if showingEducationAsPrimaryTab {
            return state.education.burnoutRisk >= 55 || state.education.attendancePressure >= 55 || state.education.schoolStanding < 40 ? .warning : .neutral
        }
        return state.career.status == .unemployed || state.career.performance < 45 || state.career.burnout >= 58 ? .warning : .neutral
    }

    private func moneyTone() -> PlannerTone {
        state.finance.financialStress >= 35 || state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < 0 ? .warning : .neutral
    }

    private func peopleTone() -> PlannerTone {
        state.relationships.activeTensionCount > 0 || (state.relationships.hasPartner && state.relationships.partnerBond < 45) || (state.relationships.friends.isEmpty && !state.relationships.hasPartner) ? .warning : .neutral
    }

    private func bodyTone() -> PlannerTone {
        state.player.health < 45 || state.healthProfile.mentalWellness < 45 || !state.healthProfile.activeConditions.isEmpty ? .warning : .positive
    }

    private func educationStatusLine() -> String {
        if state.education.stage == .university { return "University" }
        if state.education.stage == .tradeTraining { return "Trade training" }
        // D3: show branch
        if state.education.academicTrack == .honors { return "Honors track" }
        if state.education.academicTrack == .vocational { return "Trade/vocational" }
        return state.education.schoolStanding >= 70 ? "On track" : "Under pressure"
    }

    private func signedCurrency(_ value: Int) -> String {
        value >= 0 ? "$\(value)" : "-$\(abs(value))"
    }

    private func actionIcon(for definition: ActionChoiceDefinition) -> String {
        let tags = definition.previewTags.joined(separator: " ").lowercased()
        if tags.contains("money") || tags.contains("cash") || tags.contains("debt") { return "dollarsign.circle.fill" }
        if tags.contains("health") || tags.contains("sleep") || tags.contains("recovery") || tags.contains("stress") { return "heart.fill" }
        if tags.contains("friend") || tags.contains("bond") || tags.contains("belonging") || tags.contains("support") { return "person.2.fill" }
        if tags.contains("standing") || tags.contains("readiness") || tags.contains("school") { return "book.closed.fill" }
        if definition.baseFriction != .none { return "exclamationmark.triangle.fill" }
        return "bolt.fill"
    }

    var showsLuxurySuite: Bool {
        state.assets.lifestyleScore >= 50
            || state.finance.totalWealth >= 5_000_000
            || !state.assets.signatureAssets.isEmpty
            || state.fame.culturalFame >= 55
    }

    var luxurySuiteStatusLine: String {
        if !luxurySuiteActions().isEmpty {
            return "Lifestyle \(state.assets.lifestyleScore) · Fame \(state.fame.culturalFame)"
        }
        return "Elite tier locked · Lifestyle \(state.assets.lifestyleScore)"
    }

    func luxurySuiteActions() -> [ActionPresentationModel] {
        let luxuryIDs: [ActionChoiceID] = [
            .hostLuxuryEvent, .acquireLuxuryAsset, .indulgeInExcess, .displayWealth, .maintainLuxuryCollection,
            .flexLuxuryAsset, .liquidateLuxury, .upgradeCollection, .hostAtSignatureEstate
        ]
        return luxuryIDs.compactMap { choiceID in
            guard quickActionChoices(for: .finance).contains(choiceID) else { return nil }
            return quickActionPresentation(choiceID: choiceID, domain: .finance)
        }
    }
}
