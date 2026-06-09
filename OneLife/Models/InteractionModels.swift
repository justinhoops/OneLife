import Foundation

enum InteractionCardPayload: Equatable, Identifiable {
    case forecast(YearForecastCard)
    case yearSummary(YearlyOutcomeSummary)
    case event(GameEvent)
    case reaction(YearReactionCard)
    case combatFight(CombatFightSummary)
    case legalCase(LegalCaseSummary)
    case consequence(ConsequencePreview)
    case resolution(ResolutionPreview)
    case crisis(CrisisInteraction)
    case pitchDeck(PitchDeckInteraction)

    var id: String {
        switch self {
        case .forecast(let forecast):
            return forecast.id
        case .yearSummary(let summary):
            return "summary-\(summary.age)"
        case .event(let event):
            return "event-\(event.id)"
        case .reaction(let reaction):
            return reaction.id
        case .combatFight(let summary):
            return summary.id
        case .legalCase(let summary):
            return summary.id
        case .consequence(let preview):
            return preview.id
        case .resolution(let preview):
            return preview.id
        case .crisis(let crisis):
            return crisis.id
        case .pitchDeck(let pitch):
            return pitch.id
        }
    }
}

struct YearAdvanceOutcome: Equatable {
    var summary: YearlyOutcomeSummary? = nil
    var cards: [InteractionCardPayload] = []
}

