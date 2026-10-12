#if DEBUG
import SwiftUI

struct PlaytestFeedbackView: View {
    @ObservedObject var simulator: LifeSimulator
    @Environment(\.dismiss) private var dismiss
    @State private var kind: PlaytestAnnotationKind = .boring
    @State private var note = ""
    @State private var report: PlaytestRunReport?
    @State private var playStyle: PlaytestStyle?
    @State private var exportURLs: [URL] = []
    @State private var cohortURL: URL?
    @State private var cohort: PlaytestCohortAnalysis?
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Current run") {
                    LabeledContent("Seed", value: String(report?.runSeed ?? simulator.state.runSeed))
                    LabeledContent("Age", value: String(simulator.state.character.age))
                    LabeledContent("Recorded moments", value: String(report?.moments.count ?? 0))
                        .accessibilityIdentifier("Recorded Playtest Moments")
                    LabeledContent("Annotations", value: String(report?.annotations.count ?? 0))
                    if let playStyle {
                        LabeledContent("Recorded style") {
                            Text(playStyle.title)
                                .accessibilityIdentifier("Recorded Playtest Style Value")
                        }
                    }
                    Picker("Play style", selection: $playStyle) {
                        Text("Not selected").tag(nil as PlaytestStyle?)
                        ForEach(PlaytestStyle.allCases) { style in
                            Text(style.title).tag(Optional(style))
                        }
                    }
                    .onChange(of: playStyle) { _, selected in
                        guard let selected else { return }
                        simulator.setPlaytestStyle(selected)
                        refreshReport()
                    }
                }

                Section("Mark this moment") {
                    Picker("Observation", selection: $kind) {
                        ForEach(PlaytestAnnotationKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    TextField("Optional detail", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                    Button(saved ? "Saved" : "Save observation") {
                        simulator.addPlaytestAnnotation(kind: kind, note: note)
                        note = ""
                        saved = true
                        refresh()
                    }
                    .accessibilityIdentifier("Save Playtest Observation")
                }

                Section("Export") {
                    Text("Exports include the complete uncapped run timeline plus a readable summary. They stay on this device until you share them.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if exportURLs.isEmpty {
                        Button("Prepare report") { refreshExports() }
                    } else {
                        ShareLink(items: exportURLs) {
                            Label("Share JSON + Markdown", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("Export Playtest Report")
                    }
                }

                Section("Ten-life gate") {
                    LabeledContent("Completed lives", value: String(cohort?.completedReportCount ?? 0))
                    LabeledContent("Outcome explanations", value: String(cohort?.outcomeAssessmentCount ?? 0))
                    LabeledContent("Review agreements", value: String(cohort?.outcomeAgreementCount ?? 0))
                    LabeledContent("Phase 2 ready", value: cohort?.isReadyForPhase2 == true ? "Yes" : "No")
                    if let recommendation = cohort?.nextRecommendation {
                        LabeledContent("Next run target", value: recommendation.title)
                            .accessibilityIdentifier("Next Playtest Run Target")
                    }
                    if let missing = cohort?.missingRequirements, !missing.isEmpty {
                        ForEach(Array(missing.prefix(4)), id: \.self) { requirement in
                            Text(requirement)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if missing.count > 4 {
                            Text("Plus \(missing.count - 4) more requirement(s) in the cohort export.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let cohortURL {
                        ShareLink(item: cohortURL) {
                            Label("Share cohort summary", systemImage: "person.3.sequence.fill")
                        }
                        .accessibilityIdentifier("Export Playtest Cohort")
                    } else {
                        Button("Prepare cohort summary") { refreshCohort() }
                    }
                }
            }
            .navigationTitle("Playtest Notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { refresh() }
            .onChange(of: kind) { _, _ in saved = false }
            .onChange(of: note) { _, _ in saved = false }
        }
    }

    private func refresh() {
        refreshReport()
        refreshExports()
        refreshCohort()
    }

    private func refreshReport() {
        report = simulator.playtestReport()
        playStyle = report?.playStyle.flatMap(PlaytestStyle.init(rawValue:))
    }

    private func refreshExports() {
        exportURLs = simulator.playtestExportURLs()
    }

    private func refreshCohort() {
        cohort = simulator.playtestCohortAnalysis()
        cohortURL = simulator.playtestCohortExportURL()
    }
}
#endif
