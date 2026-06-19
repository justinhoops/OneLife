import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PlannerDetailSheet: View {
    let destination: PlannerDetailDestination
    let state: GameState
    let roleTitle: String
    let policyLabel: String
    let showingEducationAsPrimaryTab: Bool
    let historyDigest: HistoryDigest
    let latestYearSummary: YearlyOutcomeSummary?
    var onDismissAdultChildrenCoach: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if !detailCauseTrail.isEmpty {
                        DetailCard(title: "Why This Moved", subtitle: "Recent causes, not exact math") {
                            CauseTrailStrip(
                                title: "Cause Trail",
                                items: detailCauseTrail,
                                identifier: "detail-cause-trail-\(destination.rawValue)"
                            )
                        }
                    }
                    detailBody
                }
                .padding(20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("planner-detail-done-button")
                }
            }
            .accessibilityIdentifier("detail-sheet-\(destination.rawValue)")
        }
    }

    private var title: String {
        switch destination {
        case .careerOverview: return "Career Details"
        case .careerTrack: return "Track Details"
        case .careerHistory: return "Career History"
        case .educationOverview: return "Education Details"
        case .educationClimate: return "School Climate"
        case .educationHistory: return "Education History"
        case .financeCashflow: return "Cash Flow"
        case .financeInvesting: return "Investing"
        case .financePolicy: return "Policy And Housing"
        case .financeHistory: return "Finance History"
        case .relationshipsConnections: return "Connections"
        case .relationshipsFamily: return "Family Planning"
        case .relationshipsHistory: return "Relationship History"
        case .healthOverview: return "Health Details"
        case .healthConditions: return "Recovery Risks"
        case .healthHistory: return "Health History"
        case .lifeHousing: return "Housing Details"
        case .lifeLegacy: return "Legacy Details"
        case .lifeHistory: return "Life History"
        }
    }

    private var detailCauseTrail: [CauseTrailItem] {
        guard let latestYearSummary else { return [] }

        let domains: Set<HistoryDomainTag>
        switch destination {
        case .careerOverview, .careerTrack, .careerHistory:
            domains = showingEducationAsPrimaryTab ? [.education, .progress] : [.career, .crime, .progress]
        case .educationOverview, .educationClimate, .educationHistory:
            domains = [.education, .progress]
        case .financeCashflow, .financeInvesting, .financePolicy, .financeHistory, .lifeHousing:
            domains = [.finance, .housing, .assets, .progress]
        case .relationshipsConnections, .relationshipsFamily, .relationshipsHistory:
            domains = [.relationships, .lifeEvent, .progress]
        case .healthOverview, .healthConditions, .healthHistory:
            domains = [.health, .progress]
        case .lifeLegacy, .lifeHistory:
            domains = Set(HistoryDomainTag.allCases)
        }

        let pool = (
            latestYearSummary.headlines +
            latestYearSummary.spillovers +
            [
                latestYearSummary.focusOutcome,
                latestYearSummary.mainTradeoff,
                latestYearSummary.topProblem,
                latestYearSummary.topOpportunity,
                latestYearSummary.nextYearPressure
            ].compactMap { $0 }
        )
        .filter { domains.contains($0.domain) || $0.domain == .progress }
        .sorted { abs($0.impactScore) > abs($1.impactScore) }

        var seen: Set<String> = []
        return pool.compactMap { item in
            guard !item.detail.isEmpty, seen.insert(item.detail).inserted else { return nil }
            return CauseTrailItem(title: item.title, detail: item.detail, tone: PlannerTone(item.tone))
        }
        .prefix(3)
        .map { $0 }
    }

    @ViewBuilder
    private var detailBody: some View {
        switch destination {
        case .careerOverview:
            DetailCard(title: roleTitle, subtitle: "Current work position") {
                DetailMetricRow(items: [
                    ("Performance", "\(state.career.performance)"),
                    ("Income", "$\(state.career.annualIncome)"),
                    ("Years worked", "\(state.career.yearsWorked)")
                ])
                DetailMetricRow(items: [
                    ("Experience", state.career.strongestExperienceTag?.shortLabel ?? "Unproven"),
                    ("Qualified jobs", "\(qualifiedCareerRoles.count)"),
                    ("Special bridge", specialBridgeStatus)
                ])
                // D3: show regular archetype (when no deep special) with curve hint
                if state.specialCareer.track == .inactive, let arch = state.career.regularArchetype {
                    // CT1-2: Explicit Regular tier label for hierarchy clarity
                    let curve = arch == .corporateClimber ? "Steady security, political" :
                                arch == .gigFreelancer ? "Variance + freedom, faster fade" :
                                arch == .skilledTrades ? "Durable demand, low burnout" :
                                arch == .publicService ? "Pension security, mission" :
                                arch == .techEngineer ? "Skill ceiling, intensity" : "Network variance"
                    DetailMetricRow(items: [("Tier", "Regular"), ("Archetype", arch.displayName), ("Curve", curve)])
                }
                DetailBodyText(text: "Career remains the main stability engine for adult years. When performance and income drift apart, the planner starts flagging that strain early.")
            }
            DetailCard(title: "Qualified Regular Jobs", subtitle: "Passive income options") {
                DetailBulletList(items: qualifiedCareerRoles.prefix(5).map { "\($0.title): $\($0.annualIncome)/yr" })
            }
            DetailCard(title: "Locked Regular Jobs", subtitle: "What is still missing") {
                DetailBulletList(items: lockedCareerRoles.prefix(5).map { "\($0.0.title): \($0.1)" })
            }
        case .careerTrack:
            let isDiamondCrime = [.shadowOperative, .trader, .ventureCapitalist, .corporateRaider].contains(state.specialCareer.track)
            DetailCard(title: isDiamondCrime ? "♦ Empire (Criminal)" : (state.specialCareer.track == .crime ? "Risk Track" : "Attention Track"), subtitle: isDiamondCrime ? "Institutional power & legacy" : "Secondary pressure lane") {
                DetailMetricRow(items: [
                    ("Tier", state.specialCareer.track == .crime ? "Special" : "Special"),
                    ("Track", state.specialCareer.track.rawValue.capitalized),
                    ("Burnout", "\(state.specialCareer.burnout)"),
                    ("Payout", "$\(state.specialCareer.lastPayout)")
                ])
                DetailMetricRow(items: [
                    ("Crime status", state.crime.status.rawValue.capitalized),
                    ("Heat", "\(max(state.crime.heat, state.specialCareer.heat))"),
                    ("Audience / notoriety", "\(max(state.specialCareer.audience, state.crime.notoriety))")
                ])
                // CE2 / CT4: Empire metrics for Diamond criminal enterprise (or basic crime)
                if state.specialCareer.track == .crime || state.crime.status == .active || [.shadowOperative, .trader, .ventureCapitalist, .corporateRaider].contains(state.specialCareer.track) {
                    let ent = state.specialCareer.enterprise
                    DetailMetricRow(items: [
                        ("Loyalty", "\(ent.loyalty)"),
                        ("Clean $", "\(ent.cleanMoneyRatio)%"),
                        ("Network", "\(ent.networkStrength)")
                    ])
                }
                // CE4 / CT4: Subtype voice hint in the track (Diamond empire for sophisticated criminal)
                if state.specialCareer.track == .crime || [.shadowOperative, .trader, .ventureCapitalist, .corporateRaider].contains(state.specialCareer.track) {
                    let flavor = state.specialCareer.enterprise.subtype == .shadowOperative ? "Ghost work (Empire)" :
                                 state.specialCareer.enterprise.subtype == .streetCrime ? "Street arithmetic" :
                                 state.specialCareer.enterprise.subtype == .grayMarketTrader ? "Gray ledger (Empire)" :
                                 state.specialCareer.enterprise.subtype == .ventureCapitalist ? "Quiet capital (Empire)" : "Hostile precision (Empire)"
                    DetailMetricRow(items: [("Voice", flavor)])
                }
            }
        case .careerHistory:
            DetailHistoryList(entries: historyDigest.all)
        case .educationOverview:
            if showingEducationAsPrimaryTab || state.player.age <= 18 || state.education.seniorYearOutcome != .unresolved {
                DetailCard(title: "High School Shape", subtitle: state.education.seniorYearOutcome.displayLabel) {
                    DetailMetricRow(items: [
                        ("Future", state.education.highSchoolProfile.futureSeed.displayLabel),
                        ("Social", state.education.highSchoolProfile.socialShape.displayLabel),
                        ("Pressure", state.education.highSchoolProfile.pressureShape.displayLabel)
                    ])
                    DetailMetricRow(items: [
                        ("Academic", state.education.highSchoolProfile.academicShape.displayLabel),
                        ("Adults", state.education.highSchoolProfile.adultSupportShape.displayLabel),
                        ("Tags", "\(state.education.formativeSchoolTags.count)")
                    ])
                    if !state.education.highSchoolIdentityForces.isEmpty {
                        DetailMetricRow(items: state.education.highSchoolIdentityForces.prefix(3).map {
                            ($0.role.displayLabel, $0.name)
                        })
                    }
                    DetailBodyText(text: state.education.highSchoolLegacyLine)
                    DetailBulletList(items: highSchoolIdentityForceDetails)
                    DetailBulletList(items: highSchoolTagDetails)
                }
            }
            DetailCard(title: showingEducationAsPrimaryTab ? "Education is primary" : "Education context", subtitle: "School trajectory") {
                DetailMetricRow(items: [
                    ("Standing", "\(state.education.schoolStanding)"),
                    ("Readiness", "\(state.education.applicationReadiness)"),
                    ("Belonging", "\(state.education.schoolBelonging)")
                ])
                DetailMetricRow(items: [
                    ("Track", state.education.academicTrack.rawValue.capitalized),
                    ("Stage", state.education.stage.rawValue.capitalized),
                    ("Path", state.education.pathway.rawValue.capitalized)
                ])
                // D3: credential strength + decay status (trade decays slow via practice, honors lingers, standard faster fade)
                let cred = state.education.credentialStrength
                let yrs = state.education.yearsSinceCredential
                let decayNote: String = {
                    if state.education.academicTrack == .vocational { return "Trade: holds via use" }
                    if state.education.academicTrack == .honors { return "Honors: prestige lingers" }
                    if yrs > 5 { return "Fading — refresh or lose edge" }
                    return "Standard track"
                }()
                DetailMetricRow(items: [
                    ("Credential", "\(cred)"),
                    ("Age", "\(yrs)y"),
                    ("Value", decayNote)
                ])
            }
        case .educationClimate:
            DetailCard(title: "Pressure Sources", subtitle: "What is shaping the year") {
                DetailBulletList(items: educationPressureDetails)
            }
        case .educationHistory:
            DetailHistoryList(entries: historyDigest.education)
        case .financeCashflow:
            DetailCard(title: "Cash Flow", subtitle: policyLabel) {
                DetailMetricRow(items: [
                    ("Net income", "$\(state.finance.annualNetIncome)"),
                    ("Total expenses", "$\(state.finance.annualTotalExpenses)"),
                    ("Cash on hand", "$\(state.finance.cashOnHand)")
                ])
                DetailMetricRow(items: [
                    ("Stress", "\(state.finance.financialStress)"),
                    ("Tax rate", "\(state.finance.effectiveTaxRate)%"),
                    ("Balance delta", signedCurrency(state.finance.lastYearBalanceDelta))
                ])
                if state.finance.totalNonHousingDebt > 0 {
                    DetailMetricRow(items: [
                        ("Debt", "$\(state.finance.totalNonHousingDebt)"),
                        ("Debt pressure", state.finance.debtPressureBand.displayLabel),
                        ("Debt paid", "$\(state.finance.annualDebtPayments)")
                    ])
                }
                if state.assets.ownsHome || state.finance.homeDownPaymentSavings > 0 {
                    DetailMetricRow(items: [
                        ("Home fund", "$\(state.finance.homeDownPaymentSavings)"),
                        ("Equity", "$\(state.finance.homeEquity)"),
                        ("Housing burden", "$\(state.finance.housingDebtBurden)")
                    ])
                }
            }
        case .financeInvesting:
            DetailCard(title: "Investing", subtitle: state.finance.investmentRiskProfile.displayLabel) {
                DetailMetricRow(items: [
                    ("Invested", "$\(state.finance.investedBalance)"),
                    ("Index funds", "$\(state.finance.indexFundBalance)"),
                    ("Stocks", "$\(state.finance.stockPortfolioBalance)")
                ])
                DetailMetricRow(items: [
                    ("Last market year", signedCurrency(state.finance.lastYearInvestmentDelta)),
                    ("Cost basis", "$\(state.finance.costBasis)"),
                    ("Liquidity", "$\(state.finance.cashOnHand)")
                ])
                DetailBodyText(text: "Investing stays gated behind stability. This view makes the trade between liquidity and compounding explicit instead of burying it.")
            }
        case .financePolicy:
            DetailCard(title: policyLabel, subtitle: "Regional pressure") {
                DetailMetricRow(items: [
                    ("Housing setup", housingArrangementLabel(state.housing.livingArrangement)),
                    ("Housing stability", "\(state.housing.housingStability)"),
                    ("Education cost", "$\(state.finance.annualEducationCost)")
                ])
                DetailMetricRow(items: [
                    ("Living cost", "$\(state.finance.annualLivingCost)"),
                    ("Dependent cost", "$\(state.finance.annualDependentCost)"),
                    ("Stress", "\(state.finance.financialStress)")
                ])
                if state.finance.totalNonHousingDebt > 0 {
                    DetailMetricRow(items: [
                        ("Student debt", "$\(state.finance.studentDebt)"),
                        ("Credit debt", "$\(state.finance.creditDebt)"),
                        ("Medical debt", "$\(state.finance.medicalDebt)")
                    ])
                }
                if let home = state.assets.primaryResidence {
                    DetailMetricRow(items: [
                        ("Home value", "$\(home.homeValue)"),
                        ("Mortgage", "$\(home.mortgagePrincipal)"),
                        ("Status", home.status.rawValue.capitalized)
                    ])
                }
            }
        case .financeHistory:
            DetailHistoryList(entries: historyDigest.finance)
        case .relationshipsConnections:
            DetailCard(title: relationshipHeader, subtitle: "Closest social state") {
                DetailMetricRow(items: [
                    ("Friends", "\(state.relationships.friends.count)"),
                    ("Partner bond", "\(state.relationships.partnerBond)"),
                    ("Public rep", "\(state.relationships.publicReputation)")
                ])
                DetailMetricRow(items: [
                    ("Rumor heat", "\(state.relationships.activeRumorHeat)"),
                    ("Loose ends", "\(state.relationships.activeTensionCount)"),
                    ("Future align", "\(state.relationships.futureAlignment.averageReadiness)")
                ])
                DetailBulletList(items: topConnections)
                DetailBulletList(items: state.relationships.tensions.prefix(3).map { "\($0.headline) • \($0.impactLine)" }.isEmpty ? ["No loose ends are active right now."] : Array(state.relationships.tensions.prefix(3).map { "\($0.headline) • \($0.impactLine)" }))
            }
        case .relationshipsFamily:
            FamilyDetailCard(
                state: state,
                showAdultChildCoach: !state.discoverability.seenAdultChildrenCoach
                    && state.family.children.contains(where: { !$0.livesAtHome }),
                onDismissAdultChildCoach: onDismissAdultChildrenCoach
            )
        case .relationshipsHistory:
            DetailHistoryList(entries: historyDigest.relationships)
        case .healthOverview:
            DetailCard(title: "Body And Mind", subtitle: state.isGameOver ? "Life ended" : "Current stability") {
                DetailMetricRow(items: [
                    ("Overall", "\(state.player.health)"),
                    ("Physical", "\(state.healthProfile.physicalWellness)"),
                    ("Mental", "\(state.healthProfile.mentalWellness)")
                ])
                DetailMetricRow(items: [
                    ("Exercise", "\(state.healthProfile.habits.exercise)"),
                    ("Nutrition", "\(state.healthProfile.habits.nutrition)"),
                    ("Stress mgmt", "\(state.healthProfile.habits.stressManagement)")
                ])
            }
        case .healthConditions:
            DetailCard(title: "Recovery Risks", subtitle: state.healthProfile.activeConditions.isEmpty ? "No active conditions" : "Conditions active") {
                if state.healthProfile.activeConditions.isEmpty {
                    DetailBodyText(text: "There are no active conditions right now, but the recovery numbers above still determine whether your next years feel stable or brittle.")
                } else {
                    DetailBulletList(items: state.healthProfile.activeConditions.map { "\($0.name) • severity \($0.severity)" })
                }
            }
        case .healthHistory:
            DetailHistoryList(entries: historyDigest.health)
        case .lifeHousing:
            DetailCard(title: housingArrangementLabel(state.housing.livingArrangement), subtitle: "Housing details") {
                DetailMetricRow(items: [
                    ("Stability", "\(state.housing.housingStability)"),
                    ("Cost band", "\(state.housing.housingCostBand)"),
                    ("Owns home", state.assets.ownsHome ? "Yes" : "No")
                ])
                if let home = state.assets.primaryResidence {
                    DetailMetricRow(items: [
                        ("Home value", "$\(home.homeValue)"),
                        ("Equity", "$\(state.finance.homeEquity)"),
                        ("House reserve", "$\(home.maintenanceReserve)")
                    ])
                    DetailMetricRow(items: [
                        ("Mortgage rate", "\(home.mortgageRatePercent)%"),
                        ("Years left", "\(home.remainingMortgageYears)"),
                        ("Status", home.status.rawValue.capitalized)
                    ])
                } else if state.finance.homeDownPaymentSavings > 0 {
                    DetailMetricRow(items: [
                        ("Home fund", "$\(state.finance.homeDownPaymentSavings)"),
                        ("Target home", "$\(state.assets.targetHomeValue)"),
                        ("Status", "Saving")
                    ])
                }
                DetailBodyText(text: "Housing is the floor under the rest of the sim. When this slips, money and health usually start leaking soon after.")
            }
        case .lifeLegacy:
            let summary = LifeSummarySystem().build(from: state)
            DetailCard(title: legacyTitle, subtitle: "Life path and milestones") {
                DetailMetricRow(items: [
                    ("Legacy score", "\(state.progress.legacyScore)"),
                    ("Ending", summary.endgameMode),
                    ("Next life", "+\(summary.legacyPointsEarned)")
                ])
                DetailBodyText(text: summary.meaningLine)
                DetailBulletList(items: summary.legacyAxes.map { "\($0.title): \($0.value) — \($0.detail)" })
                if !state.progress.unlockedMilestones.isEmpty {
                    DetailBulletList(items: state.progress.unlockedMilestones.map { "\($0.id.rawValue.capitalized) at age \($0.unlockedAtAge)" })
                }
            }
        case .lifeHistory:
            DetailHistoryList(entries: historyDigest.life)
        }
    }

    private var educationPressureDetails: [String] {
        var items: [String] = []
        if state.education.attendancePressure >= 55 { items.append("Attendance pressure is high.") }
        if state.education.burnoutRisk >= 55 { items.append("Burnout risk is rising.") }
        if state.education.peerPressure >= 46 { items.append("Peer pressure is shaping behavior.") }
        if state.education.teacherSupport < 38 { items.append("Teacher support is thin.") }
        if items.isEmpty { items.append("School pressure is present, but there is still room to stabilize it.") }
        return items
    }

    private var highSchoolTagDetails: [String] {
        let tags = state.education.formativeSchoolTags
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(5)
            .map { "\(schoolTagLabel($0.key)): \($0.value)" }
        return tags.isEmpty ? ["No strong formative school residue yet."] : Array(tags)
    }

    private var highSchoolIdentityForceDetails: [String] {
        let forces = state.education.highSchoolIdentityForces.prefix(3).map {
            "\($0.name): \($0.storyLine)"
        }
        return forces.isEmpty ? ["No named school force is dominant yet."] : Array(forces)
    }

    private func schoolTagLabel(_ key: String) -> String {
        switch key {
        case "academic_strength": return "Academic strength"
        case "academic_strain": return "Academic strain"
        case "trade_seed": return "Trade seed"
        case "belonging": return "Belonging"
        case "isolation": return "Isolation"
        case "volatile_social": return "Volatile social"
        case "discipline_scar": return "Discipline scar"
        case "mentor_support": return "Mentor support"
        case "adult_friction": return "Adult friction"
        case "burnout": return "Burnout"
        case "survival_pressure": return "Survival pressure"
        case "mentor_anchor": return "Mentor anchor"
        case "peer_anchor": return "Peer anchor"
        case "rival_heat": return "Rival heat"
        case "home_pressure": return "Home pressure"
        case "coach_signal": return "Coach signal"
        case "academic_seed": return "Academic seed"
        case "athlete_seed": return "Athlete seed"
        case "founder_seed": return "Founder seed"
        case "creator_seed": return "Creator seed"
        case "politics_seed": return "Leadership seed"
        case "risk_seed": return "Risk seed"
        case "identity_reps": return "Identity reps"
        case "money_pressure": return "Money pressure"
        default: return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private var relationshipHeader: String {
        if let pregnancy = state.family.pregnancy {
            return "Pregnant with \(pregnancy.otherParentName)"
        }
        if let partner = state.relationships.partnerName {
            return "Closest partner: \(partner)"
        }
        return "Social network"
    }

    private var topConnections: [String] {
        var items: [String] = []
        if let partner = state.relationships.primaryPartner {
            items.append("\(partner.name) • bond \(partner.bond) • \(partner.status.rawValue)")
        }
        items.append(contentsOf: state.relationships.friends.prefix(4).map { "\($0.name) • bond \($0.bond) • \($0.status.rawValue)" })
        if items.isEmpty { items.append("No close connections are active right now.") }
        return items
    }

    private var legacyTitle: String {
        if let finalPath = state.progress.finalLifePath {
            return LifePathCatalog.profile(for: finalPath).title
        }
        if let currentPath = state.progress.currentLifePath {
            return LifePathCatalog.profile(for: currentPath).title
        }
        return "Legacy still forming"
    }

    private func housingArrangementLabel(_ arrangement: LivingArrangement) -> String {
        switch arrangement {
        case .familyHome: return "Family Home"
        case .roommates: return "Roommates"
        case .soloRenting: return "Solo Rent"
        case .ownerOccupied: return "Owner Occupied"
        case .couchSurfing: return "Couch Surfing"
        }
    }

    private var qualifiedCareerRoles: [CareerRoleDefinition] {
        CareerCatalog.qualifiedRoles(for: state.player, career: state.career, education: state.education, childhoodDossier: state.childhoodDossier)
            .sorted { $0.annualIncome > $1.annualIncome }
    }

    private var lockedCareerRoles: [(CareerRoleDefinition, String)] {
        CareerCatalog.lockedRoles(for: state.player, career: state.career, education: state.education, childhoodDossier: state.childhoodDossier)
            .sorted { lhs, rhs in
                if lhs.0.annualIncome == rhs.0.annualIncome {
                    return lhs.0.title < rhs.0.title
                }
                return lhs.0.annualIncome > rhs.0.annualIncome
            }
    }

    private var specialBridgeStatus: String {
        if state.specialCareer.track != .inactive {
            return state.specialCareer.track.rawValue.capitalized
        }
        if SpecialCareerSystem.qualificationIssue(for: .startCompany, state: state) == nil { return "Founder ready" }
        if SpecialCareerSystem.qualificationIssue(for: .manageFund, state: state) == nil { return "Capital ready" }
        if SpecialCareerSystem.qualificationIssue(for: .gatherIntelligence, state: state) == nil { return "Access ready" }
        return "Building proof"
    }
}

struct ChangeInsightSheet: View {
    let insight: ChangeInsightCard

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Label(insight.topic.title, systemImage: insight.topic.symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(insight.tone.color)

                    Text(insight.headline)
                        .font(.title3.weight(.bold))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Why This Changed")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        ForEach(insight.causes, id: \.self) { cause in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(insight.tone.color)
                                    .frame(width: 7, height: 7)
                                    .padding(.top, 6)
                                Text(cause)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let implication = insight.implication {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Next Year")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text(implication)
                                .font(.footnote)
                                .foregroundStyle(.primary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(insight.tone.fill)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Year Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .accessibilityIdentifier("change-insight-sheet-\(insight.topic.rawValue)")
        }
    }
}

struct SettingsSheet: View {
    @Binding var hapticsSetting: FeedbackIntensitySetting
    @Binding var animationSetting: FeedbackIntensitySetting
    @Binding var colorEmphasisSetting: ColorEmphasisSetting
    let startNewLife: () -> Void
    let resetSavedProgress: () -> Void
    let openDebugLab: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Feedback Pulse") {
                    Picker("Haptics", selection: $hapticsSetting) {
                        ForEach(FeedbackIntensitySetting.allCases) { setting in
                            Text(setting.title).tag(setting)
                        }
                    }

                    Picker("Animation", selection: $animationSetting) {
                        ForEach(FeedbackIntensitySetting.allCases) { setting in
                            Text(setting.title).tag(setting)
                        }
                    }

                    Picker("Color Emphasis", selection: $colorEmphasisSetting) {
                        ForEach(ColorEmphasisSetting.allCases) { setting in
                            Text(setting.title).tag(setting)
                        }
                    }
                }

                Section("Lifecycle") {
                    Button("Start New Life", role: .destructive) {
                        startNewLife()
                        dismiss()
                    }
                    Button("Reset Saved Progress", role: .destructive) {
                        resetSavedProgress()
                        dismiss()
                    }
                }

                #if DEBUG
                Section("QA") {
                    Button("Open QA Scenarios") {
                        openDebugLab()
                        dismiss()
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .accessibilityIdentifier("settings-sheet")
        }
    }
}

struct TraitStrip: View {
    let traits: [PersonalityTrait]

    var body: some View {
        if traits.isEmpty {
            Text("Traits are still settling into place.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(traits) { trait in
                        Text(TraitCatalog.profile(for: trait).name)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.06))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}


struct OriginPreviewCard: View {
    let state: GameState

    var body: some View {
        VStack(spacing: 14) {
            PlannerSectionCard(
                title: "Life Origin",
                symbol: "sparkles.rectangle.stack.fill",
                status: state.originProfile.map(originTitle(for:)) ?? "Teen setup ready",
                tone: previewTone
            ) {
                VStack(spacing: 10) {
                    originBlock(title: "Home", value: state.originProfile?.householdPressure ?? "Unknown", detail: state.originProfile?.homeSummary ?? "")
                    originBlock(title: "School", value: state.originProfile?.schoolStanding ?? "Unknown", detail: state.originProfile?.schoolSummary ?? "")
                    originBlock(title: "You", value: state.originProfile?.socialSupport ?? "Unknown", detail: state.originProfile?.selfSummary ?? "")
                }

                MetricRow(metrics: [
                    ("Cash", "$\(state.finance.cashOnHand)", state.finance.cashOnHand >= 500 ? .positive : (state.finance.cashOnHand <= 100 ? .warning : .neutral)),
                    ("Stress", "\(state.finance.financialStress)", state.finance.financialStress >= 28 ? .warning : .neutral),
                    ("Health", "\(state.player.health)", state.player.health < 50 ? .warning : .neutral)
                ])

                if let highlights = state.originProfile?.signalHighlights {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(highlights, id: \.self) { item in
                                Text(item)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.06))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                if !state.narrativeArcs.previewTensionLabels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(state.narrativeArcs.previewTensionLabels, id: \.self) { item in
                                Text(item)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(PlannerTone.neutral.fill)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                TraitStrip(traits: state.player.traits)

                if let openingSummary = state.openingSummary {
                    Text(openingSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                }
            }
        }
    }

    private var previewTone: PlannerTone {
        if state.finance.financialStress >= 28 || state.player.health < 50 {
            return .warning
        }
        if state.finance.cashOnHand >= 500 || state.player.smarts >= 62 {
            return .positive
        }
        return .neutral
    }

    private func originBlock(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func originTitle(for profile: OriginProfile) -> String {
        switch profile.templateID {
        case .some(let templateID):
            return OriginCatalog.definition(for: templateID).title
        case .none:
            return "Quick start"
        }
    }
}
struct YearSummarySheet: View {
    let summary: YearlyOutcomeSummary?
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    if let summary {
                        Text("Age \(summary.age) Review")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        Text("What Changed")
                            .font(.title2.weight(.bold))

                        if let checkpoint = summary.checkpoint {
                            summaryCard(item: checkpoint)
                        }

                        if let yearlyStanceOutcome = summary.yearlyStanceOutcome {
                            summaryCard(item: yearlyStanceOutcome, label: "Year Goal")
                        }

                        if let focusOutcome = summary.focusOutcome {
                            summaryCard(item: focusOutcome, label: "Pattern Outcome")
                        }

                        if let mainTradeoff = summary.mainTradeoff {
                            summaryCard(item: mainTradeoff, label: "Main Tradeoff")
                        }

                        if let nextYearPressure = summary.nextYearPressure {
                            summaryCard(item: nextYearPressure, label: "Still Active")
                        }

                        if let topProblem = summary.topProblem {
                            summaryCard(item: topProblem, label: "Top Problem")
                        }

                        if let topOpportunity = summary.topOpportunity {
                            summaryCard(item: topOpportunity, label: "Top Opportunity")
                        }

                        if let momentum = summary.momentum {
                            summaryCard(item: momentum, label: "Momentum")
                        }

                        if !summary.spillovers.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("What It Touched")
                                    .font(.headline)

                                ForEach(summary.spillovers) { item in
                                    summaryCard(item: item)
                                }
                            }
                        }

                        if !summary.headlines.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Coming Out Of The Year")
                                    .font(.headline)

                                ForEach(summary.headlines) { item in
                                    summaryCard(item: item)
                                }
                            }
                        }
                    } else {
                        Text("No year summary available.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: onContinue) {
                    Label("Continue to Event", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.ultraThinMaterial)
                .accessibilityIdentifier("year-summary-continue-button")
            }
            .navigationTitle("Year Review")
            .accessibilityIdentifier("year-summary-sheet")
        }
    }

    private func summaryCard(item: YearlyOutcomeItem, label: String? = nil) -> some View {
        let tone = PlannerTone(item.tone)
        return VStack(alignment: .leading, spacing: 6) {
            if let label {
                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tone.color)
            Text(item.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.fill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct EventSheet: View {
    let event: GameEvent?
    let state: GameState
    let onPick: (EventChoice) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if let event {
                    Text(event.category.rawValue.capitalized)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)

                    Text(event.title)
                        .font(.title2.weight(.bold))

                    Text(event.displayText(echoing: state))
                        .foregroundStyle(.secondary)

                    Divider()

                    VStack(spacing: 10) {
                        ForEach(Array(event.choices.enumerated()), id: \.element.id) { index, choice in
                            Button {
                                onPick(choice)
                                dismiss()
                            } label: {
                                Text(choice.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("event-choice-\(index)")
                        }
                    }

                    Spacer()
                } else {
                    Text("No event")
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Year Event")
            .accessibilityIdentifier("event-sheet")
        }
    }
}

struct FlowLayout: View {
    var spacing: CGFloat = 8
    var items: [AnyView]

    init<Data: RandomAccessCollection, Content: View>(
        _ data: Data,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.spacing = spacing
        self.items = data.map { AnyView(content($0)) }
    }

    var body: some View {
        // Simplified for this environment to use a wrapping HStack in a scrollview
        // to avoid complex geometry calculations in a single replacement
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(0..<items.count, id: \.self) { index in
                    items[index]
                }
            }
        }
    }
}
