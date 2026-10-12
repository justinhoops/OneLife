import SwiftUI

struct SituationStatusView: View {
    let title: String
    let stage: SituationStage
    let stakes: String
    let suggestedAction: ActionID

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.headline)
            Text(stage.rawValue.capitalized)
                .font(.caption.bold())
                .foregroundStyle(.orange)
            Text(stakes)
                .font(.caption)
                .foregroundStyle(.secondary)
            Label("Try: \(suggestedActionName)", systemImage: "arrow.right.circle.fill")
                .font(.caption.bold())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Active situation, \(title), \(stage.rawValue), \(stakes). Suggested action: \(suggestedActionName)")
        .accessibilityIdentifier("Active Situation \(title)")
    }

    private var suggestedActionName: String {
        DomainActionRegistry.action(for: suggestedAction).name
    }
}
