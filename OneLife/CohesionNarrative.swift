import Foundation

// MARK: - P5 Cohesion Gate
//
// Single narrative router for post-Family systems. Each feature has exactly one echo
// per surface channel (year summary, forecast, quiet note, legacy closer).

enum CohesionSurface {
    case yearSummary
    case forecast
    case quietNote
    case legacyCloser
}

struct CohesionResilienceContext: Equatable {
    var hadRecovery: Bool = false
    var momentumCarried: Bool = false
    var harshYear: Bool = false
}

enum CohesionNarrative {

    // MARK: - Recognition / Fame Web

    static func recognitionEcho(state: GameState, surface: CohesionSurface) -> String? {
        let fame = state.fame
        guard fame.recognition >= 40 || fame.culturalFame >= 45 || fame.notoriety >= 45 else { return nil }

        switch surface {
        case .yearSummary:
            if fame.isInfamous {
                return "Infamy travels ahead of you — rooms react before you speak."
            }
            if let knownFor = fame.knownFor.first, !knownFor.isEmpty {
                return "Known for \(knownFor). Recognition opens doors and adds scrutiny."
            }
            if fame.isHouseholdName {
                return "Household name — the public version of you enters first."
            }
            return "Your name is starting to travel on its own."
        case .forecast:
            if fame.isInfamous {
                return "Your name carries weight (and risk)"
            }
            if fame.isHouseholdName {
                return "The world already has expectations of you"
            }
            if fame.culturalFame >= 45 {
                return "Recognition is opening (and closing) paths"
            }
            return nil
        case .quietNote:
            if fame.isInfamous || fame.notoriety >= 65 {
                return "Even in a quiet stretch, the shadow of your name follows you into rooms."
            }
            if fame.isHouseholdName {
                return "The world has decided who you are. Even silence carries your reputation now."
            }
            if fame.recognition >= 55 {
                return "Your name is starting to open doors (and close others) without you lifting a finger."
            }
            return nil
        case .legacyCloser:
            if fame.isInfamous {
                return " The heat finally caught up with the name."
            }
            if fame.isHouseholdName || fame.recognition >= 70 {
                return " The name outlived the person who wore it."
            }
            if fame.culturalFame >= 50 {
                return " Recognition followed you to the close."
            }
            return nil
        }
    }

    // MARK: - D4 Life Shape

    static func lifeShapeEcho(state: GameState, surface: CohesionSurface) -> String? {
        let label = LifeShapeResolver.label(from: state, includeActivityHeat: surface == .quietNote)
        guard !label.isEmpty else { return nil }

        switch surface {
        case .yearSummary:
            let recent = state.yearlyStance.recentStances.prefix(2).map(\.title).joined(separator: " → ")
            if recent.isEmpty {
                return "Life shape: \(label) — your focus residue is writing quiet years."
            }
            return "Life shape: \(label). Recent: \(recent)."
        case .forecast:
            return "Your \(label) is still writing what the world offers"
        case .quietNote:
            if let streak = LifeShapeResolver.stanceStreak(in: state, minimum: 3) {
                return "Three years of \(streak.title) — the pattern is obvious now (\(label))."
            }
            if state.correlationLedger.recentActivityLevel < 20 && label.contains("loose") {
                return "The \(label) feels diffuse; doors stayed closed without drama."
            }
            return "The \(label) is still audible in the quiet."
        case .legacyCloser:
            switch LifeShapeResolver.resolveOrPragmatic(from: state) {
            case .drivenCurrent:
                return " You ended the race at full speed, still chasing the horizon."
            case .looseEdges:
                return " You let the edges fray at the end, finding a quiet, unscripted peace."
            case .carefulShape:
                return " Every choice was weighed; you finished exactly as you intended."
            case .pragmatic:
                return " You settled the accounts and met the end with a steady eye."
            }
        }
    }

    // MARK: - Resilience

    static func resilienceEcho(state: GameState, surface: CohesionSurface, context: CohesionResilienceContext = .init()) -> String? {
        switch surface {
        case .yearSummary:
            return DiscoverabilityTeaching.resilienceYearSummaryLine(
                resilience: state.resilience,
                hadRecovery: context.hadRecovery,
                momentumCarried: context.momentumCarried
            )
        case .forecast:
            return DiscoverabilityTeaching.resilienceForecastLine(
                resilience: state.resilience,
                momentumVisible: context.momentumCarried || state.instantMomentum.isVisible,
                recoveryTone: context.hadRecovery
            )
        case .quietNote:
            guard context.harshYear || state.healthProfile.mentalWellness < 40 || state.career.burnout >= 70 else {
                return nil
            }
            switch state.resilience {
            case .grounded:
                return "Grounded years make the quiet feel heavier — but comebacks hit harder when they land."
            case .resilient:
                return "Resilient room let the year bend without breaking, even when it stayed quiet."
            }
        case .legacyCloser:
            if state.resilience == .grounded {
                return " You fought it all the way."
            }
            if state.resilience == .resilient, state.correlationLedger.recentActivityLevel > 75 {
                return " The fast lane left its scars, but you kept moving."
            }
            return nil
        }
    }

    // MARK: - Athlete Pillars

    static func athletePillarEcho(state: GameState, surface: CohesionSurface) -> String? {
        guard state.specialCareer.track == .athlete else { return nil }
        let a = state.specialCareer.athlete

        switch surface {
        case .yearSummary:
            if a.personalBrand >= a.peakPerformance + 15 {
                return "Brand outruns peak form — the world pays for who you are, not what you have left."
            }
            if a.peakPerformance >= 78 && a.naturalPotential >= 82 {
                return "Peak form and potential aligned — the body and ceiling are speaking the same language."
            }
            if !a.accolades.isEmpty {
                return "Accolades stack: \(a.accolades.last ?? "milestone") — the only things that survive the decline."
            }
            return "Peak \(a.peakPerformance) · Potential \(a.naturalPotential) · Brand \(a.personalBrand)."
        case .forecast:
            let era = state.currentEra
            switch era {
            case .recession:
                return "Sponsorships are drying up. The economy just made your body worth less on the open market."
            case .bullMarket, .techBoom:
                return "Winning feels louder when the economy is celebrating winners."
            default:
                if a.peakPerformance < 55 && a.personalBrand >= 50 {
                    return "The brand is carrying what the body can't — decline with an audience still watching."
                }
                return nil
            }
        case .quietNote:
            if a.enhancementHeat > 40 {
                return "The edge protocol hums even in quiet years — peak form bought on borrowed time."
            }
            if a.peakPerformance < 50 && !a.accolades.isEmpty {
                return "The body cooled; the accolades still echo in empty arenas."
            }
            return nil
        case .legacyCloser:
            if a.accolades.contains(where: { $0.localizedCaseInsensitiveContains("Hall of Fame") }) {
                return " The accolades outlasted the athlete."
            }
            if a.personalBrand >= 70 {
                return " The brand survived the body."
            }
            return nil
        }
    }

    // MARK: - Adult Child Outcomes

    static func adultChildEcho(state: GameState, surface: CohesionSurface) -> String? {
        let adults = state.family.children.filter { !$0.livesAtHome }
        guard !adults.isEmpty else { return nil }

        let worried = adults.filter { ($0.adultProfile?.relationshipQuality ?? 55) < 40 }
        let thriving = adults.filter { $0.adultProfile?.outcome == .thriving }

        switch surface {
        case .yearSummary:
            if let name = worried.first?.name {
                return "\(name) feels distant this year — the grown-child thread still pulls."
            }
            if thriving.count >= 2 {
                return "Your grown children are thriving — pride sits in the year even without drama."
            }
            return "\(adults.count) adult \(adults.count == 1 ? "child" : "children") — their outcomes are part of your story now."
        case .forecast:
            if !worried.isEmpty {
                return "A grown child is on your mind — distance or worry may surface this year"
            }
            return "Your adult children carry forward what you modeled"
        case .quietNote:
            if let child = worried.first, let vibe = child.adultProfile?.lifeVibe, !vibe.isEmpty {
                return "\(child.name) is \(vibe) — the worry travels quietly."
            }
            if let child = thriving.first {
                return "You think of \(child.name) doing well — quiet pride in an uneventful year."
            }
            return "The grown kids live their own arcs now; you feel it even when nothing happens."
        case .legacyCloser:
            let goodKids = adults.filter {
                guard let p = $0.adultProfile else { return false }
                return p.outcome == .thriving || (p.outcome == .stable && p.relationshipQuality >= 55)
            }
            if goodKids.count >= 2 {
                return " The family held — your children carried something forward."
            }
            if !goodKids.isEmpty {
                return " At least one child found solid ground after your roof."
            }
            if !worried.isEmpty {
                return " Distance with grown children became part of the final ledger."
            }
            return nil
        }
    }

    // MARK: - Collection / Lifestyle Identity

    static func collectionEcho(state: GameState, surface: CohesionSurface) -> String? {
        guard let identity = AssetCatalog.collectionIdentity(from: state.assets) else { return nil }

        switch surface {
        case .yearSummary:
            if let showpiece = identity.showpiece {
                return "Collection identity: \(identity.label) — the \(showpiece.name) is the piece people remember."
            }
            return "Collection identity: \(identity.label) — lifestyle \(identity.lifestyleScore) from what you own."
        case .forecast:
            if identity.completedSets.count >= 2 {
                return "Your collection is starting to tell a story on its own"
            }
            if identity.lifestyleScore >= 55 {
                return "What you own is shaping how rooms receive you"
            }
            return nil
        case .quietNote:
            if let showcased = state.assets.lastShowcasedPieceName, !showcased.isEmpty {
                return "People are still talking about the \(showcased) — the flex landed harder than the year did."
            }
            if identity.lifestyleScore >= 70 {
                return "The toys in the garage and the ice on your wrist are louder than this quiet year."
            }
            return nil
        case .legacyCloser:
            if identity.completedSets.count >= 3 {
                return " The collection became legend — pieces outlived the person who curated them."
            }
            if identity.lifestyleScore >= 80 {
                return " The high life left artifacts that outlasted the spending."
            }
            return nil
        }
    }

    static func forecastCollectionClause(state: GameState) -> String? {
        guard let identity = AssetCatalog.collectionIdentity(from: state.assets),
              identity.lifestyleScore >= 50 else { return nil }
        if identity.completedSets.count >= 2 {
            return "Collector sets are compounding your lifestyle signal"
        }
        return "Asset holdings are shaping social options"
    }

    // MARK: - Quiet year — pick one cohesion echo (priority order)

    static func quietNoteEcho(state: GameState, tone: NarrativeTone) -> String? {
        let harsh = tone == .cornered || tone == .burnedOut || tone == .grinding
        let resilienceCtx = CohesionResilienceContext(harshYear: harsh)

        if let line = recognitionEcho(state: state, surface: .quietNote),
           state.fame.isInfamous || state.fame.notoriety >= 65 {
            return line
        }
        if let line = adultChildEcho(state: state, surface: .quietNote),
           state.family.children.contains(where: { !$0.livesAtHome && ($0.adultProfile?.relationshipQuality ?? 55) < 40 }) {
            return line
        }
        if let line = lifeShapeEcho(state: state, surface: .quietNote),
           LifeShapeResolver.stanceStreak(in: state, minimum: 3) != nil
            || !LifeShapeResolver.label(from: state, includeActivityHeat: true).isEmpty {
            return line
        }
        if let line = athletePillarEcho(state: state, surface: .quietNote) {
            return line
        }
        if let line = collectionEcho(state: state, surface: .quietNote),
           state.assets.effectiveLifestyleScore >= 65 {
            return line
        }
        if let line = resilienceEcho(state: state, surface: .quietNote, context: resilienceCtx) {
            return line
        }
        if let line = recognitionEcho(state: state, surface: .quietNote) {
            return line
        }
        return adultChildEcho(state: state, surface: .quietNote)
    }

    // MARK: - Legacy closer (composed block)

    static func legacyCloserText(state: GameState) -> String {
        var closer = lifeShapeEcho(state: state, surface: .legacyCloser) ?? ""
        closer += resilienceEcho(state: state, surface: .legacyCloser) ?? ""
        closer += recognitionEcho(state: state, surface: .legacyCloser) ?? ""
        closer += adultChildEcho(state: state, surface: .legacyCloser) ?? ""
        closer += athletePillarEcho(state: state, surface: .legacyCloser) ?? ""
        closer += collectionEcho(state: state, surface: .legacyCloser) ?? ""

        if closer.isEmpty {
            switch state.resilience {
            case .grounded:
                closer = " You met the end with steady eyes."
            case .resilient:
                closer = " You kept bending until the line stopped."
            }
        }

        if state.currentEra == .recession || state.currentEra == .highInflation,
           !closer.contains("times") {
            closer += " The times were against you at the close, but the record stands."
        }

        return closer
    }

    // MARK: - Forecast clauses (subtitle appendees)

    static func forecastRecognitionClause(state: GameState) -> String? {
        recognitionEcho(state: state, surface: .forecast)
    }

    static func forecastAthleteClause(state: GameState) -> String? {
        athletePillarEcho(state: state, surface: .forecast)
    }

    static func forecastLifeShapeClause(state: GameState) -> String? {
        lifeShapeEcho(state: state, surface: .forecast)
    }

    static func forecastAdultChildClause(state: GameState) -> String? {
        adultChildEcho(state: state, surface: .forecast)
    }

    // MARK: - Athlete console metrics (Work tab pillar strip)

    static func athletePillarMetrics(from state: GameState) -> [(title: String, value: String, tone: PlannerTone)] {
        let a = state.specialCareer.athlete
        var metrics: [(String, String, PlannerTone)] = [
            ("Peak", "\(a.peakPerformance)", a.peakPerformance >= 78 ? .positive : (a.peakPerformance < 50 ? .warning : .neutral)),
            ("Potential", "\(a.naturalPotential)", a.naturalPotential >= 82 ? .positive : (a.naturalPotential < 60 ? .warning : .neutral)),
            ("Brand", "\(a.personalBrand)", a.personalBrand >= 65 ? .positive : (a.personalBrand < 35 ? .warning : .neutral))
        ]
        if !a.accolades.isEmpty {
            let count = a.accolades.count
            let label = count == 1 ? "Accolade" : "Accolades"
            metrics.append((label, "\(count)", count >= 3 ? .positive : .neutral))
        } else {
            metrics.append(("Accolades", "0", .neutral))
        }
        return metrics
    }

    static func athletePillarPressureLine(from state: GameState) -> String {
        let a = state.specialCareer.athlete
        if a.personalBrand >= a.peakPerformance + 10 {
            return "Brand is outpacing peak form — the market pays for the name now."
        }
        if a.peakPerformance >= 75 {
            return "Peak form, potential, brand, and accolades — four pillars holding the career up."
        }
        return "Peak Form is what you have today. Brand is what survives when the body fades."
    }
}
