import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct EducationPlannerTab: View {
    let state: GameState
    let isTeenExperience: Bool
    let whyItMatters: [PlannerInsight]
    let schoolClimateMetrics: [(String, String, PlannerTone)]
    let pressureSources: [String]
    let nextUnlocks: [String]
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    let comingUpItems: [String]
    let openDetail: (PlannerDetailDestination) -> Void

    init(
        state: GameState,
        isTeenExperience: Bool,
        whyItMatters: [PlannerInsight],
        schoolClimateMetrics: [(String, String, PlannerTone)],
        pressureSources: [String],
        nextUnlocks: [String],
        summaryItems: [YearlyOutcomeItem],
        recentHistory: [HistoryEntry],
        actionChoices: [ActionChoiceID],
        onSelectAction: @escaping (ActionChoiceID) -> Void,
        comingUpItems: [String],
        openDetail: @escaping (PlannerDetailDestination) -> Void
    ) {
        self.state = state
        self.isTeenExperience = isTeenExperience
        self.whyItMatters = whyItMatters
        self.schoolClimateMetrics = schoolClimateMetrics
        self.pressureSources = pressureSources
        self.nextUnlocks = nextUnlocks
        self.summaryItems = summaryItems
        self.recentHistory = recentHistory
        self.actionChoices = actionChoices
        self.onSelectAction = onSelectAction
        self.comingUpItems = comingUpItems
        self.openDetail = openDetail
    }

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Education",
                symbol: "book.closed.fill",
                status: educationStatus,
                tone: state.education.stage == .inactive && state.education.pathway == .graduate ? .positive : (state.education.burnoutRisk >= 55 || state.education.attendancePressure >= 55 ? .warning : .neutral),
                detailTitle: "Details",
                detailIdentifier: "education-overview-detail-button",
                detailAction: { openDetail(.educationOverview) }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    MetricRow(metrics: [
                        ("Standing", "\(state.education.schoolStanding)", state.education.schoolStanding >= 70 ? .positive : (state.education.schoolStanding < 40 ? .warning : .neutral)),
                        (isTeenExperience ? "Readiness" : "Campus Fit", isTeenExperience ? "\(state.education.applicationReadiness)" : "\(state.education.campusFit)", (isTeenExperience ? state.education.applicationReadiness : state.education.campusFit) >= 60 ? .positive : ((isTeenExperience ? state.education.applicationReadiness : state.education.campusFit) < 40 ? .warning : .neutral))
                    ])
                    Text(educationSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .accessibilityIdentifier("education-overview-header")

            AuditStrip(insights: auditInsights, identifier: "education-overview-audit")

            if !pressureSources.isEmpty || !comingUpItems.isEmpty {
                PlannerSectionCard(
                    title: "What Can Bite",
                    symbol: "exclamationmark.triangle.fill",
                    status: pressureSources.first ?? comingUpItems.first,
                    tone: pressureSources.isEmpty ? .neutral : .warning,
                    detailTitle: "Inspect",
                    detailIdentifier: "education-pressure-detail-button",
                    detailAction: { openDetail(.educationClimate) }
                ) {
                    ChipStrip(
                        title: "Live pressure",
                        items: Array((pressureSources + comingUpItems).prefix(4)),
                        tone: pressureSources.isEmpty ? .neutral : .warning,
                        identifier: "education-pressure-strip"
                    )
                }
                .accessibilityIdentifier("education-overview-pressure")
            }

            // Teen/early adult dossier immersion: your 14 wiring is already shaping the lane (sparks come through teenUnlocks)
            if (isTeenExperience || (state.player.age <= 22 && state.education.stage != .inactive)) && !nextUnlocks.filter({ $0.contains("edge") || $0.contains("instinct") || $0.contains("current") || $0.contains("mind") || $0.contains("Physical") || $0.contains("Hustle") || $0.contains("Creative") || $0.contains("Social") || $0.contains("Sharp") }).isEmpty {
                PlannerSectionCard(
                    title: "Wiring from 14",
                    symbol: "sparkles",
                    status: "Childhood shape showing up",
                    tone: .positive,
                    detailTitle: "See more",
                    detailIdentifier: "teen-wiring-detail",
                    detailAction: { openDetail(.educationOverview) }
                ) {
                    ChipStrip(
                        title: "Early edges",
                        items: Array(nextUnlocks.filter { $0.contains("edge") || $0.contains("instinct") || $0.contains("current") || $0.contains("mind") || $0.contains("Physical") || $0.contains("Hustle") || $0.contains("Creative") || $0.contains("Social") || $0.contains("Sharp") }.prefix(3)),
                        tone: .positive,
                        identifier: "teen-wiring-strip"
                    )
                }
            }

            ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
        }
        .accessibilityIdentifier("education-tab-content")
    }

    private var educationStatus: String {
        switch state.education.stage {
        case .secondary:
            switch state.education.pathway {
            case .graduate: return "Graduated"
            case .training: return "In training"
            case .dropout: return "Off track"
            case .student: return state.education.schoolStanding >= 70 ? "On track" : "School under pressure"
            default: return "On track"
            }
        case .university:
            return state.education.hasScholarship ? "University with aid" : "University under load"
        case .tradeTraining:
            return "Trade training"
        case .adultEd:
            return "Rebuilding path"
        case .inactive:
            if state.education.credentials.contains("Degree") {
                return "Degree earned"
            }
            if state.education.credentials.contains("Trade Certificate") {
                return "Trade certified"
            }
            return state.education.pathway == .graduate ? "Graduated" : "Inactive"
        }
    }

    private var educationSummary: String {
        if state.education.stage == .university {
            return state.education.hasScholarship
                ? "University is open, but expectations and debt pressure are now part of the equation."
                : "University is active, and the real question is whether fit, cost, and burnout can all hold."
        }
        if state.education.stage == .tradeTraining {
            return "Training is giving you a practical lane into adulthood, with less prestige and more immediate payoff. (D3: fast income handoff, credential decays slower if you stay hands-on.)"
        }
        if state.education.stage == .adultEd {
            return "This is a slower rebuilding route. It buys time, but it does not buy comfort."
        }
        if state.education.hasScholarship {
            return "Your school performance is opening doors and easing the financial burden."
        }
        if state.education.schoolBelonging < 40 || state.education.reputationRisk >= 55 || state.education.peerPressure >= 50 {
            return "School feels socially fragile right now, and your place in it is affecting everything else."
        }
        if state.education.attendancePressure >= 55 || state.education.burnoutRisk >= 55 {
            return "School is becoming fragile, and this year’s discipline could decide a lot."
        }
        return "Education is still shaping the floor under the rest of your life."
    }

    private var auditInsights: [PlannerInsight] {
        [
            PlannerInsight(
                title: "Problem",
                value: state.education.burnoutRisk >= 55 ? "burnout rising" : (state.education.reputationRisk >= 50 ? "social risk" : "manageable"),
                tone: state.education.burnoutRisk >= 55 || state.education.reputationRisk >= 50 ? .warning : .neutral
            ),
            PlannerInsight(
                title: "Opportunity",
                value: state.education.hasScholarship ? "scholarship live" : (state.education.mentorSupport >= 65 ? "adult support" : "still forming"),
                tone: state.education.hasScholarship || state.education.mentorSupport >= 65 ? .positive : .neutral
            ),
            PlannerInsight(
                title: "Momentum",
                value: state.education.applicationReadiness >= 55 ? "building" : (state.education.engagement < 40 ? "slipping" : "fragile"),
                tone: state.education.applicationReadiness >= 55 ? .positive : (state.education.engagement < 40 ? .warning : .neutral)
            )
        ]
    }
}

struct SchoolClimateModule: View {
    let metrics: [(String, String, PlannerTone)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("School Climate")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            MetricRow(metrics: metrics)
        }
        .accessibilityIdentifier("education-school-climate")
    }
}

struct CareerPlannerTab: View {
    let state: GameState
    let roleTitle: String
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    let crimeActionChoices: [ActionChoiceID]
    let onSelectCrimeAction: (ActionChoiceID) -> Void
    let legalActionChoices: [ActionChoiceID]
    let onSelectLegalAction: (ActionChoiceID) -> Void
    let comingUpItems: [String]
    let openDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Career",
                symbol: "briefcase.fill",
                status: roleTitle,
                tone: state.career.status == .unemployed ? .warning : (state.career.performance >= 75 ? .positive : .neutral),
                detailTitle: "Details",
                detailIdentifier: "career-overview-detail-button",
                detailAction: { openDetail(.careerOverview) }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    MetricRow(metrics: [
                        ("Performance", "\(state.career.performance)", state.career.performance >= 75 ? .positive : (state.career.performance < 35 ? .warning : .neutral)),
                        ("Income", "$\(state.career.annualIncome)", state.career.annualIncome > 0 ? .positive : .warning),
                        ("Years", "\(state.career.yearsWorked)", .neutral)
                    ])
                    Text(careerSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .accessibilityIdentifier("career-overview-header")

            AuditStrip(insights: auditInsights, identifier: "career-overview-audit")

            if let specialMetrics {
                let diamondTracks: Set<SpecialCareerTrack> = [.movieProducer, .recordLabelOwner, .sportsOwner, .shadowOperative, .trader, .ventureCapitalist, .corporateRaider, .fightEmpire]
                let isDiamond = diamondTracks.contains(state.specialCareer.track)
                PlannerSectionCard(
                    title: isDiamond ? "♦ Empire" : "Special Career",
                    symbol: isDiamond ? "crown.fill" : (state.specialCareer.track == .crime ? "flame.fill" : "sparkles"),
                    status: isDiamond ? "Institutional / Legacy tier" : (state.specialCareer.track == .crime ? "High volatility" : "Spotlight pressure"),
                    tone: isDiamond ? .positive : (state.specialCareer.burnout >= 70 || state.specialCareer.track == .crime ? .warning : .neutral)
                ) {
                    MetricRow(metrics: specialMetrics)
                }
            }

            // Fame Web F3: Recognition card with flavor and downside hints
            let f = state.fame
            if f.recognition > 24 {
                let label = f.isInfamous ? "Infamous" : (f.isHouseholdName ? "Household Name" : (f.recognition > 55 ? "Widely Known" : "Name Travels"))
                let tone: PlannerTone = f.isInfamous ? .warning : (f.culturalFame > f.notoriety ? .positive : .neutral)
                let recognitionItems: [(String, String, PlannerTone)] = {
                    var items: [(String, String, PlannerTone)] = [
                        ("Fame", "\(f.culturalFame)", f.culturalFame >= 55 ? .positive : .neutral),
                        ("Notoriety", "\(f.notoriety)", f.notoriety >= 45 ? .warning : .neutral)
                    ]
                    if f.isInfamous {
                        items.append(("Scrutiny", "High", .warning))
                    } else if f.isHouseholdName {
                        items.append(("Expectations", "Heavy", .neutral))
                    }
                    return items
                }()
                PlannerSectionCard(title: "Recognition", symbol: "star.fill", status: label, tone: tone) {
                    MetricRow(metrics: recognitionItems)
                }
            }

            if showsCrimeCareerSection {
                PlannerSectionCard(
                    title: "Crime",
                    symbol: "flame.fill",
                    status: crimeStatus,
                    tone: crimeTone
                ) {
                    MetricRow(metrics: [
                        ("Heat", "\(state.crime.heat)", state.crime.heat >= 65 ? .warning : .neutral),
                        ("Loyalty", "\(state.crime.loyalty)", state.crime.loyalty >= 55 ? .positive : .neutral),
                        ("Pressure", "\(state.crime.territoryPressure)", state.crime.territoryPressure >= 60 ? .warning : .neutral)
                    ])

                    ActionSelectionModule(actionChoices: crimeActionChoices, onSelectAction: onSelectCrimeAction)
                }
                .accessibilityIdentifier("crime-career-section")
            }

            if showsLegalSection {
                PlannerSectionCard(
                    title: state.legal.isInCustody ? "Custody" : "Legal Case",
                    symbol: "building.columns.fill",
                    status: legalStatus,
                    tone: state.legal.stage == .released ? .neutral : .warning
                ) {
                    MetricRow(metrics: legalMetrics)
                    if !legalActionChoices.isEmpty {
                        let legalLimit = state.legal.isInCustody ? 6 : 3
                        ActionSelectionModule(actionChoices: Array(legalActionChoices.prefix(legalLimit)), onSelectAction: onSelectLegalAction)
                    }
                }
                .accessibilityIdentifier("legal-career-section")
            }

            ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
        }
        .accessibilityIdentifier("career-tab-content")
    }

    private var showsCrimeCareerSection: Bool {
        state.crime.status != .inactive || !crimeActionChoices.isEmpty || state.specialCareer.track == .crime
    }

    private var showsLegalSection: Bool {
        state.legal.stage != .inactive || !state.legal.convictions.isEmpty || !legalActionChoices.isEmpty
    }

    private var legalStatus: String {
        switch state.legal.stage {
        case .inactive: return "No active case"
        case .investigation: return "Under investigation"
        case .charged: return "Charged"
        case .awaitingResolution: return "Awaiting resolution"
        case .supervision: return "Under supervision"
        case .custody: return "\(state.legal.yearsRemaining) years remaining"
        case .released: return "Released"
        }
    }

    private var legalMetrics: [(String, String, PlannerTone)] {
        if state.legal.isInCustody {
            let profile = state.legal.custodyProfile
            var metrics: [(String, String, PlannerTone)] = [
                ("Facility", profile.facility.displayName, .warning),
                ("Tier", profile.experienceTier.displayName, .neutral),
                ("Regime", profile.securityRegime.displayName, profile.securityRegime == .maximum ? .warning : .neutral),
                ("Served", "\(state.legal.effectiveTimeServed)", .neutral),
                ("Remaining", "\(state.legal.yearsRemaining)", .warning),
                ("Conduct", "\(profile.conductScore)", profile.conductScore >= 55 ? .positive : .warning),
                ("Choices Left", "\(profile.discretionaryActionsRemaining)", profile.discretionaryActionsRemaining <= 1 ? .warning : .neutral),
                ("Family Calls", "\(profile.lifetimeFamilyContactsMax - profile.totalFamilyCallsMade)", .neutral)
            ]
            if let faction = profile.faction {
                metrics.append(("Faction", faction.displayName, .neutral))
            }
            if profile.snitchRisk >= 25 {
                metrics.append(("Snitch Risk", "\(profile.snitchRisk)", profile.snitchRisk >= 50 ? .warning : .neutral))
            }
            if profile.programProgress > 0 {
                metrics.append(("Program", "\(profile.programProgress)%", profile.programProgress >= 75 ? .positive : .neutral))
            }
            return metrics
        }
        return [
            ("Evidence", "\(state.legal.evidenceStrength)", state.legal.evidenceStrength >= 65 ? .warning : .neutral),
            ("Counsel", "\(state.legal.counselQuality)", state.legal.counselQuality >= 45 ? .positive : .neutral),
            ("Record", "\(state.legal.convictions.count)", state.legal.convictions.isEmpty ? .neutral : .warning)
        ]
    }

    private var crimeStatus: String {
        switch state.crime.status {
        case .inactive:
            return "Dormant"
        case .active:
            return state.crime.crewID == nil ? "Operating solo" : "Crew active"
        case .layingLow:
            return "Laying low"
        }
    }

    private var crimeTone: PlannerTone {
        if state.crime.heat >= 65 || state.crime.territoryPressure >= 60 || state.crime.burnout >= 70 {
            return .warning
        }
        if state.crime.status != .inactive && state.crime.loyalty >= 55 {
            return .positive
        }
        return .neutral
    }

    private var careerSummary: String {
        switch state.specialCareer.track {
        case .entertainment:
            if state.specialCareer.burnout >= 72 {
                return "You are still getting noticed, but the grind behind it is starting to eat through your stability."
            }
            if state.specialCareer.lastPayout >= 4_000 {
                return "The spotlight finally paid this year, but entertainment money still looks volatile rather than safe."
            }
            return "You are pursuing attention-based work where visibility matters more than comfort and consistency."
        case .movieActor:
            return "You are building a screen career. Craft, auditions, credits, public image, and typecast risk decide whether the camera becomes income or just another expensive dream."
        case .recordLabelOwner:
            return "You own the music machine now. Roster trust, catalog depth, tour upside, and cashflow pressure decide whether the label becomes a home for artists or another extractive room with better furniture."
        case .coach:
            return "Special Career: you manage a sports program now. Recruiting, staff, scheme, locker room trust, boosters, and season results decide whether you climb or get fired."
        case .sportsOwner:
            return "Diamond Career: you own the franchise, not the playbook. Acquisitions, media deals, front-office quality, and portfolio margins decide whether billions become an empire or an expensive hobby."
        case .movieProducer:
            return "Diamond Career: you manage scripts, casts, budgets, distribution, and production chaos. The upside is bigger than acting work, but unfinished projects can burn cash fast."
        case .musicProducer:
            return "You are building the sound behind the artist. Credits, studio quality, network, royalties, and credit disputes decide whether your name becomes a tag, a catalog, or a cautionary story."
        case .inactive:
            break
        case .crime:
            break
        case .founder, .shadowOperative, .trader, .ventureCapitalist, .corporateRaider:
            return "You are building something from nothing. Vision and execution are your weapons. Every dollar raised, every key hire, every board meeting is a negotiation between control, growth, and your own sanity."
        case .contentCreator:
            return "You are farming attention in the attention economy. Every post is a bet. Algorithm favor, personal brand, and burnout are your real stats. One clip can change everything — or destroy it."
        case .politics:
            return "You are playing the longest game there is. Approval is oxygen. Scandals are poison. Every decision is a calculation between what is right, what is popular, and what keeps the money flowing."
        case .athlete:
            if state.specialCareer.athlete.sport == .combatSports {
                let combat = state.specialCareer.athlete.combat
                guard let discipline = combat.discipline else {
                    return "Combat sports is selected. Choose Boxing or MMA to begin the professional pipeline."
                }
                if combat.stage == .retired {
                    return "Your \(discipline == .boxing ? "boxing" : "MMA") record is final at \(combat.recordLabel). The next decision is whether the name becomes a Fight Empire."
                }
                return "\(discipline == .boxing ? "Boxing" : "MMA") career: \(combat.recordLabel), \(combat.isChampion ? "champion" : "ranking \(combat.ranking)"). Accept an opponent, shape camp, set strategy, then Age Up resolves the marquee fight."
            }
            return "Your body is the product. Peak Form is what you have today. Potential is the ceiling you were born with. Brand is what the world decides you are worth when the lights go out. Accolades are the only things that survive the decline."
        case .fightEmpire:
            return "Diamond Career: your gym, prospects, events, broadcast reach, fighter trust, and regulatory pressure now decide whether the fighting name becomes an institution."
        default:
            break
        }

        if state.career.status == .unemployed {
            return "Work stability is the pressure point right now, so the next year matters."
        }
        if state.career.performance >= 75 {
            return "Your work momentum is healthy and could convert into better opportunities."
        }
        return "Your career is moving, but it still needs steadier performance to feel secure."
    }

    private var specialMetrics: [(String, String, PlannerTone)]? {
        switch state.specialCareer.track {
        case .entertainment:
            return [
                ("Tier", "Special", .positive),
                ("Fame", "\(state.specialCareer.fame)", state.specialCareer.fame >= 60 ? .positive : .neutral),
                ("Audience", "\(state.specialCareer.audience)", state.specialCareer.audience >= 55 ? .positive : .neutral),
                ("Burnout", "\(state.specialCareer.burnout)", state.specialCareer.burnout >= 70 ? .warning : .neutral)
            ]
        case .movieActor:
            let actor = state.specialCareer.movieActor
            var metrics: [(String, String, PlannerTone)] = [
                ("Tier", "Special", .positive),
                ("Craft", "\(actor.actingSkill)", actor.actingSkill >= 60 ? .positive : .neutral),
                ("Credits", "\(actor.roleCredits)", actor.roleCredits >= 4 ? .positive : .neutral),
                ("Draw", "\(actor.boxOfficeDraw)", actor.boxOfficeDraw >= 45 ? .positive : .neutral),
                ("Agent", "\(actor.agentQuality)", actor.agentQuality >= 55 ? .positive : .neutral),
                ("Image", "\(actor.publicImage)", actor.publicImage < 35 ? .warning : .neutral)
            ]
            if actor.typecastRisk >= 35 {
                metrics.append(("Typecast", "\(actor.typecastRisk)", actor.typecastRisk >= 60 ? .warning : .neutral))
            }
            return metrics
        case .recordLabelOwner:
            let label = state.specialCareer.recordLabel
            var metrics: [(String, String, PlannerTone)] = [
                ("Tier", "Empire", .positive),
                ("Roster", "\(label.roster.count)", label.roster.count >= 3 ? .positive : .neutral),
                ("Catalog", "\(label.catalogStrength)", label.catalogStrength >= 55 ? .positive : .neutral),
                ("Prestige", "\(label.labelPrestige)", label.labelPrestige >= 55 ? .positive : .neutral),
                ("Artist Trust", "\(label.artistTrust)", label.artistTrust < 40 ? .warning : (label.artistTrust >= 70 ? .positive : .neutral)),
                ("Cashflow", "\(label.cashflowPressure)", label.cashflowPressure >= 65 ? .warning : .neutral)
            ]
            if label.industryHeat >= 35 {
                metrics.append(("Heat", "\(label.industryHeat)", label.industryHeat >= 60 ? .warning : .neutral))
            }
            if label.tourMachine >= 45 {
                metrics.append(("Tours", "\(label.tourMachine)", .positive))
            }
            return metrics
        case .coach:
            let coach = state.specialCareer.coaching
            var metrics: [(String, String, PlannerTone)] = [
                ("Tier", "Special", .positive),
                ("Record", "\(coach.seasonWins)-\(coach.seasonLosses)", coach.seasonWins >= 9 ? .positive : (coach.seasonWins <= 4 && coach.seasonLosses > 0 ? .warning : .neutral)),
                ("Roster", "\(coach.rosterTalent)", coach.rosterTalent >= 60 ? .positive : .neutral),
                ("Scheme", "\(coach.schemeFit)", coach.schemeFit >= 60 ? .positive : .neutral),
                ("Locker Room", "\(coach.lockerRoom)", coach.lockerRoom < 40 ? .warning : .neutral),
                ("Prestige", "\(coach.programPrestige)", coach.programPrestige >= 60 ? .positive : .neutral)
            ]
            if coach.boosterPressure >= 35 {
                metrics.append(("Boosters", "\(coach.boosterPressure)", coach.boosterPressure >= 65 ? .warning : .neutral))
            }
            return metrics
        case .sportsOwner:
            let owner = state.specialCareer.sportsOwner
            var metrics: [(String, String, PlannerTone)] = [
                ("Tier", "Diamond", .positive),
                ("Teams", "\(owner.portfolio.count)", owner.portfolio.count >= 2 ? .positive : .neutral),
                ("Valuation", MoneyFormatting.compact(owner.totalValuation), owner.totalValuation >= 5_000_000_000 ? .positive : .neutral),
                ("Last Profit", MoneyFormatting.compact(owner.lastPortfolioProfit), owner.lastPortfolioProfit > 0 ? .positive : (owner.lastPortfolioProfit < 0 ? .warning : .neutral)),
                ("Front Office", "\(owner.frontOfficeQuality)", owner.frontOfficeQuality >= 60 ? .positive : .neutral),
                ("Media", "\(owner.mediaLeverage)", owner.mediaLeverage >= 55 ? .positive : .neutral),
                ("Pressure", "\(owner.capitalPressure)", owner.capitalPressure >= 65 ? .warning : .neutral)
            ]
            if let top = owner.portfolio.max(by: { $0.lastYearProfit < $1.lastYearProfit }) {
                metrics.append(("\(top.league.displayName)", MoneyFormatting.compact(top.lastYearProfit), top.lastYearProfit >= 0 ? .positive : .warning))
            }
            return metrics
        case .movieProducer:
            let film = state.specialCareer.movieProducer
            var metrics: [(String, String, PlannerTone)] = [
                ("Empire", "Film", .positive),
                ("Slate", "\(film.slateCount)", film.slateCount >= 2 ? .positive : .neutral),
                ("Prestige", "\(film.prestige)", film.prestige >= 55 ? .positive : .neutral),
                ("Studio Trust", "\(film.studioTrust)", film.studioTrust < 35 ? .warning : .neutral),
                ("Backend", "\(film.backendCatalog)", film.backendCatalog >= 45 ? .positive : .neutral),
                ("Chaos", "\(film.productionChaos)", film.productionChaos >= 60 ? .warning : .neutral)
            ]
            if film.distributionLeverage >= 40 {
                metrics.append(("Distribution", "\(film.distributionLeverage)", .positive))
            }
            return metrics
        case .musicProducer:
            let producer = state.specialCareer.musicProducer
            var metrics: [(String, String, PlannerTone)] = [
                ("Credits", "\(producer.credits)", producer.credits >= 8 ? .positive : .neutral),
                ("Sound", "\(producer.sonicSignature)", producer.sonicSignature >= 60 ? .positive : .neutral),
                ("Studio", "\(producer.studioQuality)", producer.studioQuality >= 55 ? .positive : .neutral),
                ("Demand", "\(producer.demand)", producer.demand >= 55 ? .positive : .neutral),
                ("Royalties", "\(producer.royaltyCatalog)", producer.royaltyCatalog >= 45 ? .positive : .neutral)
            ]
            if producer.creditDisputes >= 30 {
                metrics.append(("Disputes", "\(producer.creditDisputes)", producer.creditDisputes >= 55 ? .warning : .neutral))
            }
            return metrics
        case .contentCreator:
            return [
                ("Tier", "Special", .warning),
                ("Fame", "\(state.specialCareer.fame)", state.specialCareer.fame >= 60 ? .positive : .neutral),
                ("Audience", "\(state.specialCareer.audience)", state.specialCareer.audience >= 55 ? .positive : .neutral),
                ("Burnout", "\(state.specialCareer.burnout)", state.specialCareer.burnout >= 70 ? .warning : .neutral)
            ]
        case .politics:
            let p = state.specialCareer.politics
            return [
                ("Tier", "Special", .warning),
                ("Approval", "\(p.approvalRating)", p.approvalRating >= 60 ? .positive : .neutral),
                ("Scandal", "\(p.scandalHeat)", p.scandalHeat >= 50 ? .warning : .neutral),
                ("Burnout", "\(p.burnout)", p.burnout >= 70 ? .warning : .neutral)
            ]
        case .inactive:
            return nil
        case .crime:
            return nil
        case .founder, .shadowOperative, .trader, .ventureCapitalist, .corporateRaider:
            let isDiamondEnt = [.shadowOperative, .trader, .ventureCapitalist, .corporateRaider].contains(state.specialCareer.track)
            var m: [(String, String, PlannerTone)] = [
                ("Tier", isDiamondEnt ? "Empire" : "Special", isDiamondEnt ? .positive : .warning),
                ("Reach", "\(state.specialCareer.audience)", state.specialCareer.audience >= 55 ? .positive : .neutral),
                ("Heat", "\(state.specialCareer.heat)", state.specialCareer.heat >= 60 ? .warning : .neutral),
                ("Burnout", "\(state.specialCareer.burnout)", state.specialCareer.burnout >= 70 ? .warning : .neutral)
            ]
            // CT4-1: Empire metrics for Diamond criminal enterprise
            if [.shadowOperative, .trader, .ventureCapitalist, .corporateRaider].contains(state.specialCareer.track) {
                let ent = state.specialCareer.enterprise
                m.append(("Network", "\(ent.networkStrength)", ent.networkStrength >= 70 ? .positive : .neutral))
                m.append(("Clean $", "\(ent.cleanMoneyRatio)%", ent.cleanMoneyRatio >= 70 ? .positive : .neutral))
                if ent.crewSize >= 8 {
                    m.append(("Crew", "\(ent.crewSize)", .positive))
                }
            }
            // Fame Web F1
            let fame = state.fame
            if fame.recognition > 22 {
                m.append(("Recognition", "\(fame.recognition)", fame.culturalFame > fame.notoriety ? .positive : .neutral))
            }
            // E4: Dedicated founder CEO dashboard (rich, glanceable)
            if state.specialCareer.track == .founder {
                let fd = state.specialCareer.founder
                m.append(("Vision", "\(fd.vision)", fd.vision >= 70 ? .positive : .neutral))
                m.append(("Execution", "\(fd.execution)", fd.execution >= 68 ? .positive : (fd.execution < 45 ? .warning : .neutral)))
                m.append(("Team", "\(fd.teamHealth)", fd.teamHealth >= 65 ? .positive : (fd.teamHealth < 40 ? .warning : .neutral)))
                m.append(("Stage", "\(fd.productStage)", fd.productStage >= 70 ? .positive : .neutral))
                if fd.founderMentalLoad > 55 {
                    m.append(("Mental Load", "\(fd.founderMentalLoad)", .warning))
                }
                if fd.control < 60 {
                    m.append(("Control", "\(fd.control)", .warning))
                }
                if fd.personalLegend >= 50 {
                    m.append(("Legend", "\(fd.personalLegend)", .positive))
                }
            }
            // C4: Dedicated creator dashboard (rich, glanceable)
            if state.specialCareer.track == .contentCreator {
                let c = state.specialCareer.creator
                m.append(("Audience", "\(c.audience)", c.audience >= 50 ? .positive : .neutral))
                m.append(("Algorithm", "\(c.algorithmFavor)", c.algorithmFavor >= 65 ? .positive : (c.algorithmFavor < 35 ? .warning : .neutral)))
                m.append(("Brand", "\(c.personalBrand)", c.personalBrand >= 60 ? .positive : (c.personalBrand < 30 ? .warning : .neutral)))
                if c.burnout > 50 {
                    m.append(("Burnout", "\(c.burnout)", .warning))
                }
                if c.cancellationRisk > 40 {
                    m.append(("Cancel Risk", "\(c.cancellationRisk)", .warning))
                }
                if c.brandDealValue > 40 {
                    m.append(("Deals", "\(c.brandDealValue)", .positive))
                }
                // Platform flavor
                let platformLabel = c.platform == .tiktokShorts ? "Shorts" : (c.platform == .youtube ? "YT" : c.platform.rawValue.capitalized)
                m.append((platformLabel, "", .neutral))
            }
            // P4: Dedicated politics dashboard (rich, glanceable)
            if state.specialCareer.track == .politics {
                let p = state.specialCareer.politics
                m.append(("Approval", "\(p.approvalRating)", p.approvalRating >= 55 ? .positive : (p.approvalRating < 35 ? .warning : .neutral)))
                if p.scandalHeat > 35 {
                    m.append(("Scandal", "\(p.scandalHeat)", .warning))
                }
                m.append(("Ethics", "\(p.ethics)", p.ethics >= 65 ? .positive : (p.ethics < 45 ? .warning : .neutral)))
                m.append(("Donors", "\(p.donorBase)", p.donorBase >= 50 ? .positive : .neutral))
                if p.burnout > 50 {
                    m.append(("Burnout", "\(p.burnout)", .warning))
                }
                if p.policyLegacy >= 45 {
                    m.append(("Legacy", "\(p.policyLegacy)", .positive))
                }
                if p.charisma >= 65 {
                    m.append(("Charisma", "\(p.charisma)", .positive))
                }
                // Econ1: Glanceable macro context
                let eraName = state.currentEra.displayName
                m.append(("Economy", eraName, state.currentEra.tone))
            }
            return m
        case .athlete:
            let a = state.specialCareer.athlete
            if a.sport == .combatSports {
                let combat = a.combat
                guard let discipline = combat.discipline else {
                    return [
                        ("Tier", "Special", .warning),
                        ("Discipline", "Choose Boxing or MMA", .warning)
                    ]
                }
                var metrics: [(String, String, PlannerTone)] = [
                    ("Career", discipline == .boxing ? "Boxing" : "MMA", .positive),
                    ("Record", combat.recordLabel, combat.wins > combat.losses ? .positive : .neutral),
                    ("Rank", combat.isChampion ? "Champion" : "\(combat.ranking)", combat.isChampion ? .positive : .neutral),
                    ("Readiness", combat.fightReady ? "Fight ready" : "Incomplete", combat.fightReady ? .positive : .warning),
                    ("Wear", "\(combat.careerWear)", combat.careerWear >= 70 ? .warning : .neutral),
                    ("Earnings", "$\(combat.careerEarnings)", .neutral)
                ]
                if combat.suspensionYears > 0 {
                    metrics.append(("Suspended", "\(combat.suspensionYears)y", .warning))
                }
                metrics.append(("Conditioning", "\(combat.skills.conditioning)", combat.skills.conditioning >= 70 ? .positive : .neutral))
                if discipline == .boxing {
                    metrics.append(("Power", "\(combat.skills.power)", combat.skills.power >= 70 ? .positive : .neutral))
                    metrics.append(("Defense", "\(combat.skills.defense)", combat.skills.defense < 45 ? .warning : .neutral))
                } else {
                    metrics.append(("Striking", "\(combat.skills.striking)", combat.skills.striking >= 70 ? .positive : .neutral))
                    metrics.append(("Grappling", "\(max(combat.skills.wrestling, combat.skills.submissions))", .neutral))
                }
                return metrics
            }
            var metrics: [(String, String, PlannerTone)] = [
                ("Tier", "Special", .warning),
                ("Peak Form", "\(a.peakPerformance)", a.peakPerformance >= 78 ? .positive : (a.peakPerformance < 50 ? .warning : .neutral)),
                ("Potential", "\(a.naturalPotential)", a.naturalPotential >= 82 ? .positive : (a.naturalPotential < 60 ? .warning : .neutral)),
                ("Durability", "\(a.durability)", a.durability >= 68 ? .positive : (a.durability < 42 ? .warning : .neutral)),
                ("Brand", "\(a.personalBrand)", a.personalBrand >= 65 ? .positive : (a.personalBrand < 35 ? .warning : .neutral)),
                ("Fan Loyalty", "\(a.fanLoyalty)", a.fanLoyalty >= 65 ? .positive : .neutral)
            ]
            if !a.accolades.isEmpty {
                let count = a.accolades.count
                let label = count == 1 ? "1 Accolade" : "\(count) Accolades"
                let tone: PlannerTone = count >= 3 ? .positive : .neutral
                metrics.append((label, a.accolades.last ?? "", tone))
            }
            // Show enhancement heat if active
            if a.enhancementHeat > 25 {
                metrics.append(("Edge Heat", "\(a.enhancementHeat)", a.enhancementHeat > 60 ? .warning : .neutral))
            }
            // Fame Web F1: unified recognition (the thing that actually travels outside your sport)
            let f = state.fame
            if f.recognition > 20 {
                let recLabel = f.isHouseholdName ? "Household Name" : (f.recognition > 55 ? "Widely Known" : "Rising Name")
                metrics.append((recLabel, "\(f.recognition)", f.culturalFame >= 60 ? .positive : .neutral))
            }
            // Econ1: Glanceable macro context (sponsorships & fan spending are economy-tied)
            metrics.append(("Economy", state.currentEra.displayName, state.currentEra.tone))
            return metrics
        case .fightEmpire:
            let empire = state.specialCareer.fightEmpire
            return [
                ("Tier", "Diamond", .positive),
                ("Gym", "\(empire.gymReputation)", empire.gymReputation >= 65 ? .positive : .neutral),
                ("Roster", "\(empire.prospects.count)", empire.prospects.count >= 3 ? .positive : .neutral),
                ("Events", "\(empire.eventQuality)", empire.eventQuality >= 60 ? .positive : .neutral),
                ("Reach", "\(empire.promotionReach)", empire.promotionReach >= 60 ? .positive : .neutral),
                ("Trust", "\(empire.fighterTrust)", empire.fighterTrust < 35 ? .warning : .neutral),
                ("Regulation", "\(empire.regulatoryPressure)", empire.regulatoryPressure >= 65 ? .warning : .neutral)
            ]
        default:
            return nil
        }
    }

    private var experienceLaneLabel: String {
        state.career.strongestExperienceTag?.shortLabel ?? "Unproven"
    }

    private var qualifiedRoleCount: Int {
        CareerCatalog.qualifiedRoles(for: state.player, career: state.career, education: state.education, childhoodDossier: state.childhoodDossier).count
    }

    private var specialCareerReadinessLabel: String {
        if state.specialCareer.track != .inactive {
            return state.specialCareer.track.rawValue.capitalized
        }
        if SpecialCareerSystem.qualificationIssue(for: .startCompany, state: state) == nil {
            return "Founder ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .startMovieActor, state: state) == nil {
            return "Actor ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .startMusicProducer, state: state) == nil {
            return "Producer ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .startMovieProducer, state: state) == nil {
            return "Diamond ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .startRecordLabel, state: state) == nil {
            return "Label ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .startCoachingCareer, state: state) == nil {
            return "Coach ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .startSportsOwnership, state: state) == nil {
            return "Owner ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .manageFund, state: state) == nil {
            return "Capital ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .gatherIntelligence, state: state) == nil {
            return "Access ready"
        }
        if state.player.age >= 18 {
            return "Building"
        }
        return "Locked"
    }

    private var specialCareerReadinessTone: PlannerTone {
        specialCareerReadinessLabel.contains("ready") || state.specialCareer.track != .inactive ? .positive : (state.player.age >= 18 ? .neutral : .warning)
    }

    private var auditInsights: [PlannerInsight] {
        [
            PlannerInsight(
                title: "Problem",
                value: state.career.status == .unemployed ? "no stable work" : (state.career.performance < 40 ? "performance weak" : "holding"),
                tone: state.career.status == .unemployed || state.career.performance < 40 ? .warning : .neutral
            ),
            PlannerInsight(
                title: "Opportunity",
                value: state.career.performance >= 78 ? "promotion range" : (state.specialCareer.track == .entertainment ? "creative upside" : "slow build"),
                tone: state.career.performance >= 78 || state.specialCareer.track == .entertainment ? .positive : .neutral
            ),
            PlannerInsight(
                title: "Momentum",
                value: state.career.burnout >= 68 ? "burnout carrying over" : (state.career.yearsWorked >= 2 ? "career stacking" : (state.career.performance < 35 ? "stalled" : "early")),
                tone: state.career.burnout >= 68 ? .warning : (state.career.yearsWorked >= 2 ? .positive : (state.career.performance < 35 ? .warning : .neutral))
            )
        ]
    }
}

struct FinancePlannerTab: View {
    let state: GameState
    let isTeenExperience: Bool
    let teenMetrics: [(String, String, PlannerTone)]
    let policyLabel: String
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    let comingUpItems: [String]
    let openDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Finance",
                symbol: "dollarsign.circle.fill",
                status: balanceStatus,
                tone: state.finance.lastYearBalanceDelta < 0 ? .warning : (state.finance.lastYearBalanceDelta > 5_000 ? .positive : .neutral),
                detailTitle: "Details",
                detailIdentifier: "finance-cashflow-detail-button",
                detailAction: { openDetail(.financeCashflow) }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    if isTeenExperience {
                        MetricRow(metrics: teenMetrics)
                    } else {
                        MetricRow(metrics: [
                            ("Cash", "$\(state.finance.cashOnHand)", state.finance.cashOnHand >= 0 ? .positive : .warning),
                            ("Net", "$\(state.finance.annualNetIncome)", state.finance.annualNetIncome > 0 ? .positive : .warning),
                            ("Stress", "\(state.finance.financialStress)", state.finance.financialStress >= 45 ? .warning : .neutral)
                        ])
                    }
                    Text(financeSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .accessibilityIdentifier("finance-overview-header")

            AuditStrip(insights: auditInsights, identifier: "finance-overview-audit")

            PlannerSectionCard(
                title: "Money Pressure",
                symbol: state.finance.lastYearBalanceDelta < 0 ? "arrow.down.circle.fill" : "chart.line.uptrend.xyaxis",
                status: policyLabel,
                tone: state.finance.financialStress >= 45 || state.finance.lastYearBalanceDelta < 0 ? .warning : .neutral,
                detailTitle: "Inspect",
                detailIdentifier: "finance-policy-detail-button",
                detailAction: { openDetail(.financePolicy) }
            ) {
                MetricRow(metrics: [
                    ("Housing", housingLabel, state.housing.housingStability < 40 ? .warning : .neutral),
                    ("Velocity", signedDollar(state.finance.lastYearBalanceDelta), state.finance.lastYearBalanceDelta < 0 ? .warning : (state.finance.lastYearBalanceDelta > 0 ? .positive : .neutral))
                ])
            }
            .accessibilityIdentifier("finance-overview-pressure")

            ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
        }
        .accessibilityIdentifier("finance-tab-content")
    }

    private var housingLabel: String {
        switch state.housing.livingArrangement {
        case .familyHome: return "Family home"
        case .roommates: return "Roommates"
        case .soloRenting: return "Solo rent"
        case .ownerOccupied: return "Owner occupied"
        case .couchSurfing: return "Unstable"
        }
    }

    private var balanceStatus: String {
        if state.assets.ownsHome && state.assets.primaryResidence?.status == .delinquent { return "Ownership under strain" }
        if state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 { return "Saving toward ownership" }
        if state.finance.lastYearBalanceDelta < 0 { return "Budget under strain" }
        if state.finance.lastYearBalanceDelta > 5_000 { return "Building surplus" }
        return "Cash flow holding"
    }

    private var financeSummary: String {
        if isTeenExperience {
            if state.finance.financialStress >= 40 {
                return "Money stress at home is already bleeding into what school and recovery feel like."
            }
            if state.finance.cashOnHand < 100 {
                return "You have a little cash, but not much margin for comfort or mistakes."
            }
            return "Early money is small, but it already changes freedom, stress, and how steady home feels."
        }
        if state.finance.financialStress >= 45 {
            return "Money pressure is actively shaping the rest of your life."
        }
        if state.assets.ownsHome {
            if state.assets.primaryResidence?.status == .delinquent {
                return "The house is no longer just stability. Debt, upkeep, and timing are all pushing back at once."
            }
            if state.finance.lastYearHousingGainLoss < 0 {
                return "Ownership is building equity slowly, but one repair-heavy year can still erase the emotional upside fast."
            }
            return "Homeownership is giving you a different kind of wealth: slower, heavier, and much less liquid."
        }
        if state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 {
            return "You are trying to buy your way into stability, which means sacrificing easy cash long before the house exists."
        }
        if state.finance.hasInvestments {
            if state.finance.lastYearInvestmentDelta < 0 {
                return "You are finally compounding money, but a bad market year can still tighten the whole household mood."
            }
            if state.finance.lastYearInvestmentDelta > 0 {
                return "Your money is starting to work for you, but it is still locked behind risk and patience."
            }
            return "You have started building invested wealth, which helps long-term but does not solve short-term cash pressure."
        }
        if state.housing.housingStability < 35 {
            return "Housing instability is now part of your money problem, not separate from it."
        }
        if state.finance.lastYearBalanceDelta < 0 {
            return "Your costs are still beating your income, so stability has not landed yet."
        }
        return "This year feels financially livable, even if it is not comfortable yet."
    }

    private var auditInsights: [PlannerInsight] {
        [
            PlannerInsight(
                title: "Problem",
                value: state.finance.financialStress >= 45 ? "stress bleeding out" : (state.finance.lastYearBalanceDelta < 0 ? "running deficit" : "contained"),
                tone: state.finance.financialStress >= 45 || state.finance.lastYearBalanceDelta < 0 ? .warning : .neutral
            ),
            PlannerInsight(
                title: "Opportunity",
                value: state.assets.ownsHome ? "equity building" : (state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 ? "house fund live" : (state.finance.hasInvestments ? "money compounding" : (state.finance.lastYearBalanceDelta > 0 ? "cash room" : (state.housing.livingArrangement == .familyHome ? "cheap housing" : "thin")))),
                tone: state.assets.ownsHome || state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 || state.finance.hasInvestments || state.finance.lastYearBalanceDelta > 0 ? .positive : .neutral
            ),
            PlannerInsight(
                title: "Momentum",
                value: homeownershipActive ? homeMomentum : (state.finance.hasInvestments ? portfolioMomentum : (state.finance.consecutiveDeficitYears == 0 ? "recovering" : "\(state.finance.consecutiveDeficitYears) bad year\(state.finance.consecutiveDeficitYears == 1 ? "" : "s")")),
                tone: homeownershipActive ? homeStatusTone : (state.finance.hasInvestments ? riskTone : (state.finance.consecutiveDeficitYears == 0 ? .positive : .warning))
            )
        ]
    }

    private var homeownershipActive: Bool {
        state.assets.ownsHome || state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 || state.finance.lastYearHomeValueDelta != 0
    }

    private var homeStatusLabel: String {
        if let home = state.assets.primaryResidence {
            switch home.status {
            case .current:
                return "Owned"
            case .delinquent:
                return "Delinquent"
            case .foreclosed:
                return "Lost"
            }
        }
        if state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 {
            return "Saving"
        }
        return "None"
    }

    private var homeStatusTone: PlannerTone {
        if let home = state.assets.primaryResidence {
            return home.status == .delinquent ? .warning : .positive
        }
        return (state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0) ? .neutral : .neutral
    }

    private var riskTone: PlannerTone {
        switch state.finance.investmentRiskProfile {
        case .defensive:
            return .neutral
        case .conservative:
            return .positive
        case .balanced:
            return .neutral
        case .speculative:
            return .warning
        }
    }

    private var portfolioMomentum: String {
        if state.finance.lastYearInvestmentDelta > 0 { return "portfolio up" }
        if state.finance.lastYearInvestmentDelta < 0 { return "portfolio hit" }
        return "just starting"
    }

    private var homeMomentum: String {
        if state.assets.ownsHome {
            if state.assets.primaryResidence?.status == .delinquent { return "mortgage slipping" }
            if state.finance.lastYearHousingGainLoss > 0 { return "equity rising" }
            if state.finance.lastYearHousingGainLoss < 0 { return "repairs hit" }
            return "ownership settling"
        }
        if state.finance.homeDownPaymentSavings > 0 { return "fund growing" }
        return "not started"
    }

    private func signedDollar(_ value: Int) -> String {
        value >= 0 ? "+$\(value)" : "-$\(abs(value))"
    }
}

struct RelationshipsPlannerTab: View {
    let state: GameState
    let isTeenExperience: Bool
    let teenMetrics: [(String, String, PlannerTone)]
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    let comingUpItems: [String]
    let openDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Relationships",
                symbol: "person.2.fill",
                status: relationshipStatus,
                tone: strainedRelationshipCount > 0 ? .warning : (connectionCount > 0 ? .positive : .neutral),
                detailTitle: "Details",
                detailIdentifier: "relationships-connections-detail-button",
                detailAction: { openDetail(.relationshipsConnections) }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    MetricRow(metrics: isTeenExperience ? teenMetrics : [
                        ("Connections", "\(connectionCount)", connectionCount > 0 ? .positive : .warning),
                        ("Social Climate", "\(state.relationships.publicReputation)", state.relationships.publicReputation >= 60 ? .positive : (state.relationships.publicReputation <= 40 ? .warning : .neutral))
                    ])
                    Text(relationshipSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .accessibilityIdentifier("relationships-overview-header")

            AuditStrip(insights: auditInsights, identifier: "relationships-overview-audit")

            ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
        }
        .accessibilityIdentifier("relationships-tab-content")
    }

    private var connectionCount: Int {
        state.relationships.friends.count + (state.relationships.hasPartner ? 1 : 0)
    }

    private var strainedRelationshipCount: Int {
        (state.relationships.friends + state.relationships.romanticPartners).filter { $0.status == .strained }.count
    }

    private var strongestBondTone: PlannerTone {
        let strongest = max(state.relationships.friends.strongestBond, state.relationships.partnerBond)
        if strongest >= 75 { return .positive }
        if strongest < 35 { return .warning }
        return .neutral
    }

    private var relationshipStatus: String {
        if let pregnancy = state.family.pregnancy {
            return "Pregnant with \(pregnancy.otherParentName)"
        }
        if let partner = state.relationships.primaryPartner {
            switch partner.stage {
            case .married:
                return "Married to \(partner.name)"
            case .engaged:
                return "Engaged to \(partner.name)"
            case .committed:
                return "Committed to \(partner.name)"
            case .dating:
                return "With \(partner.name)"
            }
        }
        if !state.relationships.friends.isEmpty {
            return "Friend network active"
        }
        return "Social life is thin"
    }

    private var relationshipSummary: String {
        if isTeenExperience {
            if state.relationships.activeRumorHeat >= 55 {
                return "Rumor is hot enough to spill into school, mood, and who feels safe to trust."
            }
            if strainedRelationshipCount > 0 {
                return "Teen social tension is spilling into the rest of your year faster than it looks."
            }
            if connectionCount == 0 {
                return "Belonging is thin right now, which makes school and stress hit harder."
            }
            return "The people around you are starting to shape who you become, not just how you feel."
        }
        if strainedRelationshipCount > 0 {
            return "At least one close connection is fraying and needs care."
        }
        if state.relationships.activeTensionCount > 0 {
            return state.relationships.strongestTension?.impactLine ?? "A loose end is still draining trust and emotional room from the year."
        }
        if state.family.isPregnant {
            return "Your relationship is now carrying physical, financial, and emotional consequence all at once."
        }
        if state.family.childCount > 0 {
            return "Family life is now shaping money, recovery, and relationship stability every year."
        }
        if connectionCount == 0 {
            return "Your support system is light right now, which makes hard years hit harder."
        }
        return "Your social life is carrying some warmth and stability."
    }

    private var familyStatusMetric: String {
        if state.family.isPregnant { return "Pregnant" }
        if state.family.childCount > 0 { return "\(state.family.childCount) kids" }
        return state.family.pregnancyIntent == .avoid ? "Avoiding" : (state.family.pregnancyIntent == .trying ? "Trying" : "Open")
    }

    private var familyStatusTone: PlannerTone {
        if state.family.isPregnant || state.family.childCount > 0 { return .warning }
        if state.relationships.hasPartner { return .neutral }
        return .neutral
    }

    private var connectionPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let partner = state.relationships.primaryPartner {
                connectionBadge(name: partner.name, status: partner.status, bond: partner.bond)
            }

            if let friend = state.relationships.friends.max(by: { $0.bond < $1.bond }) {
                connectionBadge(name: friend.name, status: friend.status, bond: friend.bond)
            }
        }
    }

    private func connectionBadge(name: String, status: RelationshipStatus, bond: Int) -> some View {
        let tone: PlannerTone = status == .strained ? .warning : .positive
        return HStack {
            Text(name)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text("\(bond)")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tone.fill)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var auditInsights: [PlannerInsight] {
        [
            PlannerInsight(
                title: "Problem",
                value: state.relationships.activeRumorHeat >= 55 ? "rumor is hot" : (state.relationships.activeTensionCount > 0 ? "loose ends active" : (connectionCount == 0 ? "socially thin" : "steady")),
                tone: state.relationships.activeRumorHeat >= 55 || state.relationships.activeTensionCount > 0 || connectionCount == 0 ? .warning : .neutral
            ),
            PlannerInsight(
                title: "Opportunity",
                value: state.relationships.futureAlignment.averageReadiness >= 60 ? "shared future" : (state.relationships.hasPartner ? "deeper commitment" : "new support"),
                tone: .positive
            ),
            PlannerInsight(
                title: "Momentum",
                value: max(state.relationships.friends.strongestBond, state.relationships.partnerBond) >= 70 ? "trust growing" : state.relationships.socialClimateLabel.lowercased(),
                tone: max(state.relationships.friends.strongestBond, state.relationships.partnerBond) >= 70 ? .positive : .neutral
            )
        ]
    }

    private var looseEnds: [String] {
        let items = state.relationships.tensions.prefix(3).map { "\($0.headline) • \($0.impactLine)" }
        return items.isEmpty ? [] : Array(items)
    }
}

struct HealthPlannerTab: View {
    let state: GameState
    let isTeenExperience: Bool
    let teenMetrics: [(String, String, PlannerTone)]
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    let comingUpItems: [String]
    let openDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Health",
                symbol: "heart.fill",
                status: healthStatus,
                tone: state.player.health < 40 ? .warning : (state.player.health >= 60 ? .positive : .neutral),
                detailTitle: "Details",
                detailIdentifier: "health-overview-detail-button",
                detailAction: { openDetail(.healthOverview) }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    if isTeenExperience {
                        MetricRow(metrics: teenMetrics)
                    } else {
                        MetricRow(metrics: [
                            ("Overall", "\(state.player.health)", state.player.health >= 60 ? .positive : (state.player.health < 40 ? .warning : .neutral)),
                            ("Physical", "\(state.healthProfile.physicalWellness)", state.healthProfile.physicalWellness >= 60 ? .positive : (state.healthProfile.physicalWellness < 40 ? .warning : .neutral)),
                            ("Mental", "\(state.healthProfile.mentalWellness)", state.healthProfile.mentalWellness >= 60 ? .positive : (state.healthProfile.mentalWellness < 40 ? .warning : .neutral))
                        ])
                    }
                    Text(healthSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .accessibilityIdentifier("health-overview-header")

            AuditStrip(insights: auditInsights, identifier: "health-overview-audit")

            ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
        }
        .accessibilityIdentifier("health-tab-content")
    }

    private var healthStatus: String {
        if state.isGameOver { return "Life ended" }
        if !state.healthProfile.activeConditions.isEmpty { return "Health under pressure" }
        if state.player.health >= 65 { return "Body holding steady" }
        return "Needs better recovery"
    }

    private var healthSummary: String {
        if isTeenExperience {
            if !state.healthProfile.activeConditions.isEmpty {
                return "Recovery is not optional anymore. Your body is already pushing back."
            }
            if state.healthProfile.mentalWellness < 45 {
                return "Stress and poor sleep are quietly making school and social life more fragile."
            }
            return "Your recovery habits are the difference between holding together and slipping."
        }
        if !state.healthProfile.activeConditions.isEmpty {
            return "Your health is asking for attention now, not later."
        }
        if state.healthProfile.mentalWellness < 45 {
            return "Stress is dragging your quality of life down even if you are still functioning."
        }
        return "Your habits are keeping life manageable, even if not effortless."
    }

    private func tone(for value: Int) -> PlannerTone {
        if value >= 60 { return .positive }
        if value < 40 { return .warning }
        return .neutral
    }

    private var auditInsights: [PlannerInsight] {
        [
            PlannerInsight(
                title: "Problem",
                value: !state.healthProfile.activeConditions.isEmpty ? "condition active" : (state.healthProfile.mentalWellness < 45 ? "stress load" : "contained"),
                tone: !state.healthProfile.activeConditions.isEmpty || state.healthProfile.mentalWellness < 45 ? .warning : .neutral
            ),
            PlannerInsight(
                title: "Opportunity",
                value: state.healthProfile.hasPrimaryCare ? "care access" : (state.healthProfile.habits.exercise >= 60 ? "habits working" : "routine needed"),
                tone: state.healthProfile.hasPrimaryCare || state.healthProfile.habits.exercise >= 60 ? .positive : .neutral
            ),
            PlannerInsight(
                title: "Momentum",
                value: state.player.health >= 65 ? "holding steady" : (state.player.health < 40 ? "slipping" : "fragile"),
                tone: state.player.health >= 65 ? .positive : (state.player.health < 40 ? .warning : .neutral)
            )
        ]
    }
}

struct AssetsPlannerTab: View {
    let state: GameState
    let onBuyFirearm: (Firearm, Int) -> Void
    let onUpgradeFirearm: (UUID, WeaponUpgrade) -> Void
    let onBuyVehicle: (Vehicle, Int) -> Void
    let onUpgradeVehicle: (UUID, VehicleUpgrade) -> Void
    let onUpgradeHouse: (HouseUpgrade) -> Void
    let onSellHouse: () -> Void
    let onBuyJewelry: (Jewelry) -> Void
    let onSellJewelry: (UUID) -> Void
    let onBuyAviation: (AviationAsset) -> Void
    let onSellAviation: (UUID) -> Void
    let onBuyMarine: (MarineAsset) -> Void
    let onSellMarine: (UUID) -> Void

    // Assets2
    let onBuySignature: (SignatureAsset) -> Void
    let onSellSignature: (UUID) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Very aggressive QoL: Rich visual portfolio + Lifestyle Score
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LIFESTYLE")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.secondary)
                            Text("\(state.assets.lifestyleScore)")
                                .font(.title.weight(.black))
                                .foregroundStyle(state.assets.lifestyleScore > 60 ? Color.purple : .primary)
                        }
                        
                        Spacer()
                        
                        Text("Portfolio Overview")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        AssetCategoryIcon(count: state.assets.vehicles.count, label: "Vehicles", symbol: "car.fill")
                        AssetCategoryIcon(count: state.assets.jewelry.count, label: "Jewelry", symbol: "sparkles")
                        AssetCategoryIcon(count: state.assets.aviation.count, label: "Aviation", symbol: "airplane")
                        AssetCategoryIcon(count: state.assets.marine.count, label: "Marine", symbol: "sailboat.fill")
                        AssetCategoryIcon(count: state.assets.firearms.count, label: "Armory", symbol: "shield.fill")
                        if !state.assets.signatureAssets.isEmpty {
                            AssetCategoryIcon(count: state.assets.signatureAssets.count, label: "Signature", symbol: "crown.fill")
                        }
                    }
                }
                .padding(.horizontal, 4)
                
                // Very aggressive QoL: Bulk sell low-value assets (UI hint)
                if !state.assets.jewelry.isEmpty || !state.assets.vehicles.isEmpty {
                    Text("Low-value items available to liquidate")
                        .font(.caption2.italic())
                        .foregroundStyle(.secondary)
                }
                
                // REAL ESTATE SECTION
                if let home = state.assets.primaryResidence {
                    PlannerSectionCard(
                        title: "Primary Residence",
                        symbol: "house.fill",
                        status: "Value: $\(home.totalValue)",
                        tone: .neutral
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Equity: $\(home.equity)")
                                        .font(.caption)
                                    Text("Maintenance: $\(home.totalMonthlyMaintenance)/mo")
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button {
                                    onSellHouse()
                                } label: {
                                    Text("SELL PROPERTY")
                                        .font(.system(size: 10, weight: .black))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(4)
                                }
                            }

                            if !home.upgrades.isEmpty {
                                Text("Luxury Upgrades")
                                    .font(.caption.weight(.bold))
                                
                                FlowLayout(home.upgrades, spacing: 4) { upgrade in
                                    Text(upgrade.rawValue.capitalized)
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                                Divider()
                            }
                            
                            Text("Property Market")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(HouseUpgrade.allCases, id: \.self) { upgrade in
                                        if !home.upgrades.contains(upgrade) {
                                            PropertyUpgradeCard(upgrade: upgrade, onUpgrade: onUpgradeHouse)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // JEWELRY SECTION
                PlannerSectionCard(
                    title: "Boutique",
                    symbol: "sparkles",
                    status: state.assets.jewelry.isEmpty ? "No jewelry" : "\(state.assets.jewelry.count) items",
                    tone: .neutral
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !state.assets.jewelry.isEmpty {
                            ForEach(state.assets.jewelry) { item in
                                JewelryRow(item: item, onSell: { onSellJewelry(item.id) })
                            }
                            Divider()
                        }

                        Text("Fine Jewelry")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                JewelryMarketCard(name: "Steel Watch", type: .watch, cost: 2500, resale: 1800, rarity: .common, onBuy: onBuyJewelry)
                                JewelryMarketCard(name: "Gold Chain", type: .chain, cost: 5500, resale: 4800, rarity: .rare, onBuy: onBuyJewelry)
                                JewelryMarketCard(name: "Diamond Studs", type: .earrings, cost: 12000, resale: 9000, rarity: .exotic, onBuy: onBuyJewelry)
                                JewelryMarketCard(name: "Bust-down AP", type: .watch, cost: 65000, resale: 45000, rarity: .exotic, onBuy: onBuyJewelry)
                                JewelryMarketCard(name: "Royal Crown Jewel", type: .pendant, cost: 150000, resale: 120000, rarity: .prototype, onBuy: onBuyJewelry)
                            }
                        }
                    }
                }

                // AVIATION SECTION
                PlannerSectionCard(
                    title: "Hangar",
                    symbol: "airplane",
                    status: state.assets.aviation.isEmpty ? "No aircraft" : "\(state.assets.aviation.count) aircraft owned",
                    tone: .neutral
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !state.assets.aviation.isEmpty {
                            ForEach(state.assets.aviation) { item in
                                AviationRow(item: item, onSell: { onSellAviation(item.id) })
                            }
                            Divider()
                        }

                        Text("Aviation Market")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                AviationMarketCard(name: "Used Cessna", type: .lightAircraft, cost: 150000, resale: 110000, maintenance: 1500, onBuy: onBuyAviation)
                                AviationMarketCard(name: "Executive Heli", type: .helicopter, cost: 1200000, resale: 950000, maintenance: 8500, onBuy: onBuyAviation)
                                AviationMarketCard(name: "Gulfstream G650", type: .privateJet, cost: 65000000, resale: 45000000, maintenance: 45000, onBuy: onBuyAviation)
                                AviationMarketCard(name: "BBJ 737", type: .heavyJet, cost: 120000000, resale: 95000000, maintenance: 120000, onBuy: onBuyAviation)
                            }
                        }
                    }
                }

                // MARINE SECTION
                PlannerSectionCard(
                    title: "Marina",
                    symbol: "sailboat.fill",
                    status: state.assets.marine.isEmpty ? "No vessels" : "\(state.assets.marine.count) vessels owned",
                    tone: .neutral
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !state.assets.marine.isEmpty {
                            ForEach(state.assets.marine) { item in
                                MarineRow(item: item, onSell: { onSellMarine(item.id) })
                            }
                            Divider()
                        }

                        Text("Marine Market")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                MarineMarketCard(name: "Racing Jet Ski", type: .jetSki, cost: 18000, resale: 12000, maintenance: 150, onBuy: onBuyMarine)
                                MarineMarketCard(name: "Powerboat", type: .speedboat, cost: 145000, resale: 95000, maintenance: 800, onBuy: onBuyMarine)
                                MarineMarketCard(name: "Luxury Yacht", type: .yacht, cost: 4500000, resale: 3200000, maintenance: 12000, onBuy: onBuyMarine)
                                MarineMarketCard(name: "Mega Yacht", type: .superYacht, cost: 150000000, resale: 110000000, maintenance: 85000, onBuy: onBuyMarine)
                            }
                        }
                    }
                }

                // ARMORY SECTION
                PlannerSectionCard(
                    title: "Armory",
                    symbol: "shield.fill",
                    status: state.assets.firearms.isEmpty ? "No defensive assets" : "\(state.assets.firearms.count) firearms",
                    tone: .neutral
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !state.assets.firearms.isEmpty {
                            ForEach(state.assets.firearms) { firearm in
                                FirearmRow(firearm: firearm, onUpgrade: { onUpgradeFirearm(firearm.id, $0) })
                            }
                        }

                        Text("Firearm Market")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        Text("Legal Hardware")
                            .font(.caption.weight(.bold))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                MarketCard(name: "9mm Handgun", type: .handgun, cost: 600, isLegal: true, power: 15, reliability: 90, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Pump Shotgun", type: .shotgun, cost: 1200, isLegal: true, power: 25, reliability: 85, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Precision Bolt-Action", type: .precisionRifle, cost: 3500, isLegal: true, power: 40, reliability: 95, onBuy: { onBuyFirearm($0, $1) })
                            }
                        }

                        Text("Black Market")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.red)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                MarketCard(name: "G-Series Handgun", type: .handgun, cost: 850, isLegal: false, power: 18, reliability: 85, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Modified SMG", type: .handgun, cost: 2500, isLegal: false, power: 35, reliability: 65, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Sawn-off Shotgun", type: .shotgun, cost: 1800, isLegal: false, power: 30, reliability: 60, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Tactical Carbine", type: .rifle, cost: 6500, isLegal: false, power: 55, reliability: 80, onBuy: { onBuyFirearm($0, $1) })
                            }
                        }

                        Text("Exotic & Rare")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.purple)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                MarketCard(name: "Gold-Plated Deagle", type: .handgun, cost: 15000, isLegal: true, power: 45, reliability: 70, rarity: .exotic, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Experimental Railgun", type: .precisionRifle, cost: 85000, isLegal: false, power: 120, reliability: 40, rarity: .prototype, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Antique Duelling Pistol", type: .handgun, cost: 12000, isLegal: true, power: 10, reliability: 30, rarity: .rare, onBuy: { onBuyFirearm($0, $1) })
                            }
                        }
                    }
                }

                // GARAGE SECTION
                PlannerSectionCard(
                    title: "Garage",
                    symbol: "car.fill",
                    status: state.assets.vehicles.isEmpty ? "No vehicles" : "\(state.assets.vehicles.count) vehicles",
                    tone: .neutral
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !state.assets.vehicles.isEmpty {
                            ForEach(state.assets.vehicles) { vehicle in
                                VehicleRow(vehicle: vehicle, onUpgrade: { onUpgradeVehicle(vehicle.id, $0) })
                            }
                        }

                        Text("Vehicle Market")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                VehicleMarketCard(name: "Used Hatchback", type: .compact, cost: 4500, speed: 30, handling: 40, onBuy: onBuyVehicle)
                                VehicleMarketCard(name: "Luxury Sedan", type: .sedan, cost: 45000, speed: 60, handling: 70, onBuy: onBuyVehicle)
                                VehicleMarketCard(name: "Sport Coupe", type: .sportsCar, cost: 85000, speed: 85, handling: 80, onBuy: onBuyVehicle)
                                VehicleMarketCard(name: "Hypercar", type: .supercar, cost: 250000, speed: 100, handling: 95, onBuy: onBuyVehicle)
                                VehicleMarketCard(name: "Exotic Hypercar", type: .hypercar, cost: 1800000, speed: 110, handling: 100, onBuy: onBuyVehicle)
                                VehicleMarketCard(name: "Limited Track Toy", type: .hypercar, cost: 3200000, speed: 115, handling: 105, onBuy: onBuyVehicle)
                            }
                        }
                    }
                }

                // Assets2: Signature Holdings — Career-specific high-status assets
                if state.specialCareer.track == .athlete ||
                   state.specialCareer.track == .founder ||
                   state.specialCareer.track == .contentCreator ||
                   state.specialCareer.track == .politics {

                    PlannerSectionCard(
                        title: "Signature Holdings",
                        symbol: "crown.fill",
                        status: state.assets.signatureAssets.isEmpty ? "No signature assets yet" : "\(state.assets.signatureAssets.count) major holdings",
                        tone: .positive
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            if !state.assets.signatureAssets.isEmpty {
                                ForEach(state.assets.signatureAssets) { item in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.name)
                                                .font(.headline)
                                            Text("Prestige +\(item.prestigeBonus)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Button("Sell") {
                                            onSellSignature(item.id)
                                        }
                                        .font(.caption.bold())
                                        .foregroundColor(.red)
                                    }
                                    .padding(.vertical, 4)
                                }
                                Divider()
                            }

                            Text("Available for Your Path")
                                .font(.headline)

                            // Career-specific signature asset market (Assets2)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    SignatureAssetMarketCards(
                                        currentTrack: state.specialCareer.track,
                                        onBuy: onBuySignature
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
}

// Assets2 helper: Career-specific signature asset market cards
struct SignatureAssetMarketCards: View {
    let currentTrack: SpecialCareerTrack
    let onBuy: (SignatureAsset) -> Void

    var body: some View {
        Group {
            switch currentTrack {
            case .athlete:
                SignatureMarketCard(name: "Minority Stake in Expansion Team", category: .athleteTeamStake, cost: 12_000_000, resale: 9_500_000, prestige: 22, track: .athlete, onBuy: onBuy)
                SignatureMarketCard(name: "Private Performance Institute", category: .athleteTrainingEmpire, cost: 4_800_000, resale: 3_200_000, prestige: 14, track: .athlete, onBuy: onBuy)

            case .founder:
                SignatureMarketCard(name: "Strategic Stake in AI Competitor", category: .founderStrategicStake, cost: 18_000_000, resale: 14_000_000, prestige: 25, track: .founder, onBuy: onBuy)
                SignatureMarketCard(name: "Founder Compound (Wyoming)", category: .founderCompound, cost: 9_500_000, resale: 7_800_000, prestige: 18, track: .founder, onBuy: onBuy)

            case .contentCreator:
                SignatureMarketCard(name: "Personal Production Studio", category: .creatorStudio, cost: 6_200_000, resale: 4_100_000, prestige: 19, track: .contentCreator, onBuy: onBuy)
                SignatureMarketCard(name: "Signature Content House Portfolio", category: .creatorBrandEstate, cost: 3_400_000, resale: 2_600_000, prestige: 13, track: .contentCreator, onBuy: onBuy)

            case .politics:
                SignatureMarketCard(name: "Major Donor Retreat Estate", category: .politicsInfluenceHold, cost: 7_800_000, resale: 5_900_000, prestige: 21, track: .politics, onBuy: onBuy)
                SignatureMarketCard(name: "Legacy Political Foundation HQ", category: .politicsLegacyEstate, cost: 5_100_000, resale: 3_800_000, prestige: 16, track: .politics, onBuy: onBuy)

            // CE3: Criminal/gray enterprise signature assets — prestige with teeth
            case .crime:
                SignatureMarketCard(name: "Discreet Waterfront Safehouse", category: .crimeSafehouse, cost: 4_200_000, resale: 3_100_000, prestige: 14, track: .crime, onBuy: onBuy)
                SignatureMarketCard(name: "Offshore Holdings Portfolio", category: .crimeOffshoreHoldings, cost: 11_500_000, resale: 9_800_000, prestige: 18, track: .crime, onBuy: onBuy)
                SignatureMarketCard(name: "Quietly Profitable Import Front", category: .crimeFrontBusiness, cost: 2_800_000, resale: 2_100_000, prestige: 11, track: .crime, onBuy: onBuy)
                SignatureMarketCard(name: "Proxy Luxury Penthouse", category: .crimeLuxuryFront, cost: 6_900_000, resale: 4_900_000, prestige: 17, track: .crime, onBuy: onBuy)

            default:
                EmptyView()
            }
        }
    }
}

struct SignatureMarketCard: View {
    let name: String
    let category: SignatureAssetCategory
    let cost: Int
    let resale: Int
    let prestige: Int
    let track: SpecialCareerTrack
    let onBuy: (SignatureAsset) -> Void

    var body: some View {
        Button {
            let asset = SignatureAsset(
                name: name,
                category: category,
                cost: cost,
                resaleValue: resale,
                monthlyMaintenance: cost / 120,
                prestigeBonus: prestige,
                associatedTrack: track
            )
            onBuy(asset)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                    .lineLimit(2)
                    .frame(width: 140, alignment: .leading)

                Text("$\(cost / 1_000_000)M")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)

                Text("+ \(prestige) Prestige")
                    .font(.caption2)
                    .foregroundStyle(.purple)
            }
            .padding(8)
            .background(Color.black.opacity(0.05))
            .cornerRadius(6)
            .frame(width: 150)
        }
        .buttonStyle(.plain)
    }
}

struct PropertyUpgradeCard: View {
    let upgrade: HouseUpgrade
    let onUpgrade: (HouseUpgrade) -> Void

    var body: some View {
        Button {
            onUpgrade(upgrade)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(upgrade.rawValue.capitalized)
                    .font(.caption.weight(.bold))
                Text("$\(upgrade.cost)")
                    .font(.caption2)
                Text("+\(upgrade.valueBoost) Value")
                    .font(.system(size: 8))
                    .foregroundColor(.green)
            }
            .frame(width: 110, height: 70)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct JewelryRow: View {
    let item: Jewelry
    let onSell: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.subheadline.weight(.bold))
                Text("\(item.type.rawValue.capitalized) • Resale: $\(item.resaleValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                onSell()
            } label: {
                Text("SELL")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// Very aggressive QoL: Reusable visual asset category badge
struct AssetCategoryIcon: View {
    let count: Int
    let label: String
    let symbol: String
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(count > 0 ? Color.purple.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(count > 0 ? Color.purple : .gray)
            }
            
            Text("\(count)")
                .font(.caption2.weight(.black))
                .foregroundStyle(count > 0 ? .primary : .secondary)
            
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

struct JewelryMarketCard: View {
    let name: String
    let type: JewelryType
    let cost: Int
    let resale: Int
    let rarity: FirearmRarity
    let onBuy: (Jewelry) -> Void

    var body: some View {
        Button {
            onBuy(Jewelry(name: name, type: type, rarity: rarity, cost: cost, resaleValue: resale))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                    .foregroundColor(rarityColor(rarity))
                Text("$\(cost)")
                    .font(.caption2)
                Text(rarity.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(rarityColor(rarity))
            }
            .frame(width: 120, height: 70)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func rarityColor(_ rarity: FirearmRarity) -> Color {
        switch rarity {
        case .rare: return .blue
        case .exotic: return .purple
        case .prototype: return .orange
        default: return .primary
        }
    }
}

struct AviationRow: View {
    let item: AviationAsset
    let onSell: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.subheadline.weight(.bold))
                Text("\(item.type.rawValue.capitalized) • Maint: $\(item.monthlyMaintenance)/mo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                onSell()
            } label: {
                Text("SELL ($\(item.resaleValue))")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct AviationMarketCard: View {
    let name: String
    let type: AviationType
    let cost: Int
    let resale: Int
    let maintenance: Int
    let onBuy: (AviationAsset) -> Void

    var body: some View {
        Button {
            onBuy(AviationAsset(name: name, type: type, cost: cost, resaleValue: resale, monthlyMaintenance: maintenance))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                Text("$\(cost)")
                    .font(.caption2)
                Text("\(type.rawValue.capitalized)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: 120, height: 70)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MarineRow: View {
    let item: MarineAsset
    let onSell: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.subheadline.weight(.bold))
                Text("\(item.type.rawValue.capitalized) • Maint: $\(item.monthlyMaintenance)/mo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                onSell()
            } label: {
                Text("SELL ($\(item.resaleValue))")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct MarineMarketCard: View {
    let name: String
    let type: MarineType
    let cost: Int
    let resale: Int
    let maintenance: Int
    let onBuy: (MarineAsset) -> Void

    var body: some View {
        Button {
            onBuy(MarineAsset(name: name, type: type, cost: cost, resaleValue: resale, monthlyMaintenance: maintenance))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                Text("$\(cost)")
                    .font(.caption2)
                Text("\(type.rawValue.capitalized)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: 120, height: 70)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VehicleRow: View {
    let vehicle: Vehicle
    let onUpgrade: (VehicleUpgrade) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(vehicle.name)
                        .font(.subheadline.weight(.bold))
                    Text(vehicle.type.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Spd: \(vehicle.totalSpeed) / Hnd: \(vehicle.totalHandling)")
                        .font(.caption.monospacedDigit())
                    if vehicle.totalSafety > 0 {
                        Text("Safety: +\(vehicle.totalSafety)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
            }

            if !vehicle.upgrades.isEmpty {
                Text("Mods: " + vehicle.upgrades.map { $0.rawValue.capitalized }.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(VehicleUpgrade.allCases, id: \.self) { upgrade in
                        if !vehicle.upgrades.contains(upgrade) {
                            Button {
                                onUpgrade(upgrade)
                            } label: {
                                Text("+ \(upgrade.rawValue.capitalized) ($\(upgrade.cost))")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct VehicleMarketCard: View {
    let name: String
    let type: VehicleType
    let cost: Int
    let speed: Int
    let handling: Int
    let onBuy: (Vehicle, Int) -> Void

    var body: some View {
        Button {
            onBuy(Vehicle(name: name, type: type, isLegal: true, baseSpeed: speed, baseHandling: handling), cost)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                Text("$\(cost)")
                    .font(.caption2)
                Text("\(type.rawValue.capitalized)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: 120, height: 70)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FirearmRow: View {
    let firearm: Firearm
    let onUpgrade: (WeaponUpgrade) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        Text(firearm.name)
                            .font(.subheadline.weight(.bold))
                        if firearm.rarity != .common {
                            Text(firearm.rarity.rawValue.uppercased())
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(rarityColor(firearm.rarity))
                                .foregroundColor(.white)
                                .cornerRadius(2)
                        }
                    }
                    Text("\(firearm.type.rawValue.capitalized) • \(firearm.isCurrentlyIllicit ? "ILLICIT" : "Legal")")
                        .font(.caption)
                        .foregroundColor(firearm.isCurrentlyIllicit ? .red : .secondary)
                }
                Spacer()
                Text("Pwr: \(firearm.totalPower) / Rel: \(firearm.totalReliability)")
                    .font(.caption.monospacedDigit())
            }

            if !firearm.upgrades.isEmpty {
                Text("Mods: " + firearm.upgrades.map { $0.rawValue.capitalized }.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(WeaponUpgrade.allCases, id: \.self) { upgrade in
                        if !firearm.upgrades.contains(upgrade) {
                            Button {
                                onUpgrade(upgrade)
                            } label: {
                                HStack(spacing: 4) {
                                    Text("+ \(upgrade.rawValue.capitalized) ($\(upgrade.cost))")
                                    if upgrade.isIllicit {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 8))
                                    }
                                }
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(upgrade.isIllicit ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                                .foregroundColor(upgrade.isIllicit ? .red : .accentColor)
                                .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private func rarityColor(_ rarity: FirearmRarity) -> Color {
        switch rarity {
        case .rare: return .blue
        case .exotic: return .purple
        case .prototype: return .orange
        default: return .gray
        }
    }
}

struct MarketCard: View {
    let name: String
    let type: FirearmType
    let cost: Int
    let isLegal: Bool
    let power: Int
    let reliability: Int
    var rarity: FirearmRarity = .common
    let onBuy: (Firearm, Int) -> Void

    var body: some View {
        Button {
            onBuy(Firearm(name: name, type: type, isLegal: isLegal, basePower: power, reliability: reliability, rarity: rarity), cost)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                    .foregroundColor(rarityColor(rarity))
                Text("$\(cost)")
                    .font(.caption2)
                if !isLegal {
                    Text("ILLICIT")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.red)
                } else if rarity != .common {
                    Text(rarity.rawValue.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(rarityColor(rarity))
                }
            }
            .frame(width: 120, height: 70)
            .padding(8)
            .background(isLegal ? Color.secondary.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func rarityColor(_ rarity: FirearmRarity) -> Color {
        switch rarity {
        case .rare: return .blue
        case .exotic: return .purple
        case .prototype: return .orange
        default: return .primary
        }
    }
}

struct ActivitiesPlannerTab: View {
    let state: GameState
    let categories: [ActivityCategory]
    let activitiesForCategory: (ActivityCategory) -> [ActivityDefinition]
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let statusLine: String
    let pushbackSummary: String
    let onPerformActivity: (String) -> Void

    @State private var selectedCategory: ActivityCategory = .mindBody

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Activities",
                symbol: "sparkles",
                status: statusLine,
                tone: state.activities.riskLoad >= 8 ? .warning : (state.activities.recoveryBalance >= 4 ? .positive : .neutral)
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: category.symbol)
                                    Text(category.title)
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(selectedCategory == category ? Color.white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(selectedCategory == category ? Color.black : Color.white.opacity(0.65))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                ForEach(activitiesForCategory(selectedCategory)) { activity in
                    Button {
                        onPerformActivity(activity.id)
                    } label: {
                        ActivityRow(activity: activity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("activity-\(activity.id)")
                }
            }
        }
        .accessibilityIdentifier("activities-tab-content")
    }
}

struct ActivityRow: View {
    let activity: ActivityDefinition

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: activity.category.symbol)
                .foregroundStyle(tone.color)
                .frame(width: 36, height: 36)
                .background(tone.fill)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(activity.costLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 10)
                    Text(activity.risk.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tone.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(tone.fill)
                        .clipShape(Capsule())
                }

                ChipStrip(title: "Effect", items: activity.previewTags, tone: tone, identifier: "activity-\(activity.id)-preview")
            }

            Image(systemName: "plus.circle.fill")
                .foregroundStyle(Color.black)
                .font(.title3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.72))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tone.fill, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var tone: PlannerTone {
        switch activity.risk {
        case .grounding:
            return .positive
        case .easy:
            return .neutral
        case .charged, .dangerous:
            return .warning
        }
    }
}

struct AssetsHousingLegacySection: View {
    let state: GameState
    let openDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Housing",
                symbol: "house.fill",
                status: housingStatus,
                tone: housingTone,
                detailTitle: "Details",
                detailIdentifier: "life-housing-detail-button",
                detailAction: { openDetail(.lifeHousing) }
            ) {
                MetricRow(metrics: [
                    ("Setup", housingLabel, housingTone),
                    ("Stability", "\(state.housing.housingStability)", housingTone)
                ])
            }

            PlannerSectionCard(
                title: "Legacy",
                symbol: state.progress.finalLifePath == nil ? "sparkles" : "flag.fill",
                status: legacyStatus,
                tone: .neutral
            ) {
                MetricRow(metrics: [
                    ("Score", "\(state.progress.legacyScore)", .neutral),
                    ("Milestones", "\(state.progress.unlockedMilestones.count)", state.progress.unlockedMilestones.isEmpty ? .warning : .positive)
                ])
            }
            
            // Very aggressive QoL: Lifestyle Score from assets visible in Life tab
            if state.assets.lifestyleScore > 15 {
                PlannerSectionCard(
                    title: "Lifestyle",
                    symbol: "crown.fill",
                    status: state.assets.lifestyleScore > 60 ? "High Society" : (state.assets.lifestyleScore > 35 ? "Comfortable" : "Rising"),
                    tone: state.assets.lifestyleScore > 50 ? .positive : .neutral
                ) {
                    Text("Your assets signal \(state.assets.lifestyleScore) prestige. People notice.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("assets-housing-legacy-section")
    }

    private var housingStatus: String {
        if state.assets.primaryResidence?.status == .delinquent { return "Mortgage under strain" }
        if state.assets.ownsHome { return "Owned home" }
        if state.finance.homeDownPaymentSavings > 0 { return "Saving for a home" }
        if state.housing.livingArrangement == .couchSurfing { return "Housing unstable" }
        if state.housing.housingStability < 40 { return "Housing pressure" }
        return "Housing holding"
    }

    private var housingTone: PlannerTone {
        if state.assets.primaryResidence?.status == .delinquent { return .warning }
        if state.assets.ownsHome { return .positive }
        if state.housing.housingStability < 40 || state.housing.livingArrangement == .couchSurfing { return .warning }
        return .neutral
    }

    private var housingLabel: String {
        switch state.housing.livingArrangement {
        case .familyHome: return "Family Home"
        case .roommates: return "Roommates"
        case .soloRenting: return "Solo Rent"
        case .ownerOccupied: return "Owner Occupied"
        case .couchSurfing: return "Couch Surfing"
        }
    }

    private var legacyStatus: String {
        if let finalPath = state.progress.finalLifePath {
            return LifePathCatalog.profile(for: finalPath).title
        }
        if let currentPath = state.progress.currentLifePath {
            return "Current path: \(LifePathCatalog.profile(for: currentPath).title)"
        }
        return "Legacy still forming"
    }
}

struct FamilyDetailCard: View {
    let state: GameState
    @State private var showAtHomeDetails = false
    @State private var showAdultDetails = false

    private var compact: Bool {
        state.player.age >= 40 || state.family.children.filter { !$0.livesAtHome }.count > 0
    }

    var body: some View {
        DetailCard(title: "Family", subtitle: state.family.isPregnant ? "Pregnancy active" : "Household load") {
            HStack(spacing: 16) {
                Label("\(state.family.childCount) kids", systemImage: "person.2.fill")
                    .font(.caption.weight(.semibold))
                if state.family.infantCount > 0 {
                    Label("\(state.family.infantCount) infants", systemImage: "baby.fill")
                        .font(.caption.weight(.semibold))
                }
                if state.family.postpartumYearsRemaining > 0 {
                    Label("Postpartum", systemImage: "heart.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
            .foregroundStyle(.secondary)

            if state.family.children.isEmpty {
                Text("No children yet").font(.caption).foregroundStyle(.secondary)
            } else {
                let atHome = state.family.children.filter { $0.livesAtHome }
                let adults = state.family.children.filter { !$0.livesAtHome }

                if !atHome.isEmpty {
                    familyChildSection(
                        title: "At Home",
                        count: atHome.count,
                        expanded: $showAtHomeDetails,
                        compact: compact
                    ) {
                        ForEach(atHome) { child in
                            Text("• \(child.name), age \(child.age)")
                                .font(.caption)
                        }
                    }
                }

                if !adults.isEmpty {
                    familyChildSection(
                        title: "Adult Children",
                        count: adults.count,
                        expanded: $showAdultDetails,
                        compact: compact
                    ) {
                        ForEach(adults) { child in
                            let vibe = child.adultProfile?.lifeVibe
                            let outcome = child.adultProfile?.outcome
                            VStack(alignment: .leading, spacing: 2) {
                                Text("• \(child.name) (\(child.age))")
                                    .font(.caption.weight(.semibold))
                                if let outcome {
                                    Text(outcome.rawValue.capitalized + (vibe.map { " — \($0)" } ?? ""))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(compact ? 2 : 4)
                                }
                            }
                        }
                        if compact {
                            Text("Outcomes grew from how you raised them — tap stories in the journal.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func familyChildSection<Content: View>(
        title: String,
        count: Int,
        expanded: Binding<Bool>,
        compact: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if compact {
                Button {
                    withAnimation { expanded.wrappedValue.toggle() }
                } label: {
                    HStack {
                        Text(title)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                        Text("\(count)")
                            .font(.caption2.weight(.bold))
                        Spacer()
                        Image(systemName: expanded.wrappedValue ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                if expanded.wrappedValue {
                    content()
                } else {
                    Text(summaryLine(title: title, count: count))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(title).font(.caption2.weight(.black)).foregroundStyle(.secondary)
                content()
            }
        }
    }

    private func summaryLine(title: String, count: Int) -> String {
        if title == "Adult Children" {
            return "\(count) adult \(count == 1 ? "child" : "children") — expand for outcomes"
        }
        return "\(count) at home — expand for names"
    }
}

struct DetailCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct DetailMetricRow: View {
    let items: [(String, String)]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack {
                    Text(item.0)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.1)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

struct DetailBulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.primary.opacity(0.7))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.footnote)
                }
            }
        }
    }
}

struct DetailBodyText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

struct DetailHistoryList: View {
    let entries: [HistoryEntry]

    var body: some View {
        DetailCard(title: "Recent Years", subtitle: entries.isEmpty ? "No history yet" : "\(entries.count) visible entries") {
            if entries.isEmpty {
                DetailBodyText(text: "Your history will fill out as years resolve.")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Age \(entry.age) • \(entry.title)")
                                .font(.subheadline.weight(.semibold))
                            Text(entry.text)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

func signedCurrency(_ value: Int) -> String {
    value >= 0 ? "+$\(value)" : "-$\(abs(value))"
}
