import SwiftUI

/// Primary simulator harness: intentionally plain so actions and annual events are quick to exercise.
struct LifeConsoleView: View {
    @ObservedObject var simulator: LifeSimulator
    let onNew: (String, UInt64) -> Void
    let onLoad: () -> Void
    let onQuit: () -> Void
    @State private var selectedDomain: Domain = .school
    @State private var command = ""
    @State private var transcript: [String] = []

    var body: some View {
        NavigationStack {
            List {
                Section("\(simulator.state.character.name), age \(simulator.state.character.age)") {
                    Text("School \(simulator.state.stats.school) · Cash $\(simulator.state.cash) · Looks \(simulator.state.stats.looks)")
                    Text("Love \(simulator.state.stats.love) · Play \(simulator.state.stats.play) · Health \(simulator.state.stats.health) · \(simulator.state.job.tier.rawValue.capitalized)")
                    Text("Identity \(simulator.state.personality.identitySignature.title) · \(simulator.state.personality.salientFlags.map(\.title).joined(separator: ", "))")
                        .font(.caption).foregroundStyle(.secondary)
                    if let partner = simulator.state.partner {
                        Text("Partner \(partner.name) · Bond \(partner.bond) · Resentment \(partner.resentment) · \(partner.ruptureStage.rawValue)")
                        Text("Flags \(partner.flags.map(\.rawValue).joined(separator: ", "))").font(.caption).foregroundStyle(.secondary)
                    }
                    let influence = simulator.state.influenceLedger.current
                    Text("Influence W\(influence.work) F\(influence.family) R\(influence.risk) S\(influence.stability)").font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                if !transcript.isEmpty { Section("Console") { ForEach(transcript.suffix(8), id: \.self) { Text($0).font(.caption.monospaced()) } } }
                Section("Actions") {
                    Picker("Domain", selection: $selectedDomain) {
                        ForEach(Domain.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.segmented)
                    ForEach(DomainActionRegistry.actions(in: selectedDomain)) { action in
                        Button {
                            simulator.execute(action.id)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(action.name)
                                Text(action.shortDescription).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .disabled(simulator.availability(for: action) != .available || simulator.state.pendingEvent != nil)
                    }
                }
                if let outcome = simulator.lastOutcome {
                    Section(outcome.headline) {
                        Text(outcome.narrative)
                        if !outcome.deltas.lines.isEmpty { Text(outcome.deltas.lines.joined(separator: " · ")).foregroundStyle(.secondary) }
                    }
                }
                Section("Recent history") {
                    ForEach(simulator.state.history.prefix(8)) { entry in
                        VStack(alignment: .leading) {
                            Text("Age \(entry.age): \(entry.headline)")
                            Text(entry.detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Life Console")
            .safeAreaInset(edge: .bottom) {
                VStack { HStack { TextField("help · actions · do study · age", text: $command).textFieldStyle(.roundedBorder).onSubmit(runCommand); Button("Run") { runCommand() } }; Button("AGE UP") { simulator.ageUp(); transcript.append("AGE \(simulator.state.character.age) · seed \(simulator.state.runSeed)") }.buttonStyle(.borderedProminent).disabled(simulator.state.pendingEvent != nil).padding(.top, 4) }.padding()
            }
            .sheet(item: Binding(get: { simulator.state.pendingEvent }, set: { _ in })) { event in
                NavigationStack {
                    List(event.choices) { choice in
                        Button(choice.title) { simulator.execute(choice.id) }
                    }
                    .navigationTitle(event.headline)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Text(event.detail).font(.caption) } }
                }
            }
        }
    }

    private func runCommand() {
        let parts = command.lowercased().split(separator: " ").map(String.init); defer { command = "" }
        guard let head = parts.first else { return }
        switch head {
        case "age": simulator.ageUp(); transcript.append("AGE \(simulator.state.character.age)")
        case "actions": transcript.append(simulator.availableActions(in: selectedDomain).map(\.id.rawValue).joined(separator: ", "))
        case "help": transcript.append(parts.count > 1 ? "Requirements are shown for unavailable actions." : "age | actions | do <action> | partner | branches [action|domain] | simulate <years> [policy]")
        case "status": transcript.append(simulator.statusLine())
        case "history": transcript.append(simulator.state.history.prefix(parts.count > 1 ? Int(parts[1]) ?? 4 : 4).map { "\($0.age): \($0.headline)" }.joined(separator: " | "))
        case "domain": if parts.count > 1, let domain = Domain(rawValue: parts[1]) { selectedDomain = domain; transcript.append("DOMAIN \(domain.rawValue)") } else { transcript.append("Unknown domain") }
        case "simulate": let years = parts.count > 1 ? Int(parts[1]) ?? 1 : 1; let policy = parts.count > 2 ? parts[2] : "balanced"; transcript.append(simulator.simulate(years: years, policy: policy))
        case "personality":
            let profile = simulator.state.personality
            transcript.append("\(profile.identitySignature.title) | core: \(profile.definingTrait.title) | current: \(profile.salientFlags.map(\.title).joined(separator: ",")) | D\(profile.current.drive) E\(profile.current.empathy) S\(profile.current.sociability) R\(profile.current.riskTolerance) A\(profile.current.adaptability)")
        case "partner":
            guard let partner = simulator.state.partner else { transcript.append("No partner"); return }
            let usage = partner.personalityActionUsage.map { "\($0.key)@\($0.value)" }.sorted().joined(separator: ", ")
            transcript.append("\(partner.name) | \(partner.personality.identitySignature.title) | current: \(partner.personality.salientFlags.map(\.title).joined(separator: ",")) | bond \(partner.bond) resentment \(partner.resentment) | used: \(usage.isEmpty ? "none" : usage)")
        case "npcs":
            let summary = simulator.state.npcs.all.map { "\($0.role.rawValue): \($0.name) [\($0.importance.rawValue)] rapport \($0.rapport)" }.joined(separator: " | ")
            transcript.append(summary.isEmpty ? "No contextual NPCs" : summary)
        case "npc":
            guard parts.count > 1, let role = NPCRole(rawValue: parts[1]), let npc = simulator.state.npcs[role] else { transcript.append("Unknown or inactive NPC"); return }
            let used = npc.personalityActionUsage.map { "\($0.key)@\($0.value)" }.sorted().joined(separator: ",")
            transcript.append("\(npc.name) | \(npc.role.rawValue) / \(npc.importance.rawValue) | \(npc.personality.identitySignature.title): \(npc.personality.salientFlags.map(\.title).joined(separator: ",")) | rapport \(npc.rapport) | stance \(npc.learnedStance?.rawValue ?? "none") | used: \(used.isEmpty ? "none" : used)")
        case "branches":
            let target = parts.dropFirst().first
            let actions: [DomainAction]
            if let target, let id = ActionID(rawValue: target) { actions = [DomainActionRegistry.action(for: id)] }
            else if let target, let domain = Domain(rawValue: target) { actions = DomainActionRegistry.actions(in: domain) }
            else { actions = DomainActionRegistry.all }
            let partner = simulator.state.partner
            let output = actions.compactMap { action -> String? in
                let labels = action.personalityBranches.map { branch in
                    let match = partner.map(branch.matches) ?? false
                    return "\(branch.id)\(match ? "*" : "")"
                } + action.npcPersonalityBranches.map { branch in
                    let match = simulator.state.npcs[branch.role].map(branch.matches) ?? false
                    return "\(branch.id)\(match ? "*" : "")"
                } + UnifiedReactionRegistry.rules.filter {
                    $0.matches(action: action.id, signals: SimulationSignalSnapshot(state: simulator.state))
                }.map { "\($0.id)*" }
                return labels.isEmpty ? nil : "\(action.id.rawValue): \(labels.joined(separator: ","))"
            }.joined(separator: " | ")
            transcript.append(output.isEmpty ? "No personality branches" : output)
        case "save": transcript.append(LifePersistence().saveNow(simulator.state))
        case "load": onLoad(); transcript.append("Loaded saved life.")
        case "quit": onQuit()
        case "new": let name = parts.count > 1 ? parts[1] : "Player"; let seed = parts.count > 2 ? UInt64(parts[2]) ?? 1 : UInt64.random(in: 1...UInt64.max); onNew(name, seed); transcript.append("New life: \(name), seed \(seed)")
        case "choose": if parts.count > 1, let id = EventChoiceID(rawValue: parts[1]) { simulator.execute(id); transcript.append("CHOOSE \(id.rawValue)") } else { transcript.append("Unknown choice") }
        case "do": if parts.count > 1, let id = ActionID(rawValue: parts[1]) { simulator.execute(id); transcript.append("DO \(id.rawValue)") } else { transcript.append("Unknown action") }
        default: transcript.append("Unknown command: \(head)")
        }
    }
}
