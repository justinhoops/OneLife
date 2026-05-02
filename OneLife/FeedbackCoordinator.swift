import Foundation

struct FeedbackCoordinator {
    struct Response: Equatable {
        var microBeat: String?
        var jitterDuration: TimeInterval?
        var shouldReturnEarly: Bool = false
    }

    func ageUpResponse(for tone: NarrativeTone) -> Response {
        switch tone {
        case .grinding, .burnedOut:
            AppFeedback.impact(.medium)
            return Response(microBeat: "You drag yourself into the next year.", jitterDuration: 0.2)
        case .isolated, .cornered:
            AppFeedback.impact(.medium)
            return Response(microBeat: "Another year, carefully navigated.")
        case .holding:
            AppFeedback.impact(.light)
            return Response(microBeat: "The calendar turns quietly.")
        case .hopeful, .clear:
            AppFeedback.impact(.light)
            return Response(microBeat: "You step confidently into the next chapter.")
        }
    }

    func actionResponse(for friction: ActionFrictionLevel, microBeat: String?) -> Response {
        switch friction {
        case .resistance:
            AppFeedback.impact(.medium)
            return Response(microBeat: microBeat, jitterDuration: 0.15)
        case .warning:
            AppFeedback.notify(.warning)
            return Response(microBeat: microBeat, jitterDuration: 0.25)
        case .locked:
            AppFeedback.notify(.warning)
            return Response(shouldReturnEarly: true)
        case .none:
            AppFeedback.impact(.light)
            return Response(microBeat: microBeat)
        }
    }
}
