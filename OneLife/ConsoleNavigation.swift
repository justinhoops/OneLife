import Foundation

// MARK: - Console Navigation (Phase 0)
//
// Single source of truth for domain/sub-domain navigation.
// See Docs/NAVIGATION-AND-TAB-PATTERN.md

/// Top-level console domains aligned with player-facing dock labels.
enum ConsoleMainDomain: String, CaseIterable, Codable, Identifiable {
    case life
    case school
    case cash
    case love
    case play

    var id: String { rawValue }

    var title: String {
        switch self {
        case .life: return "Life"
        case .school: return "School"
        case .cash: return "Cash"
        case .love: return "Love"
        case .play: return "Play"
        }
    }

    var gameTab: GameViewModel.Tab {
        switch self {
        case .life: return .home
        case .school: return .occupation
        case .cash: return .assets
        case .love: return .relationships
        case .play: return .activities
        }
    }

    static func from(gameTab: GameViewModel.Tab) -> ConsoleMainDomain? {
        switch gameTab {
        case .home: return .life
        case .occupation: return .school
        case .assets: return .cash
        case .relationships: return .love
        case .activities: return .play
        case .history: return nil
        }
    }
}

/// Assets sub-tabs — first tab is always Overview.
enum AssetsSubTab: String, CaseIterable, Codable, Identifiable {
    case overview
    case vehicles
    case property
    case jewelry
    case weapons

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .vehicles: return "Vehicles"
        case .property: return "Property"
        case .jewelry: return "Jewelry"
        case .weapons: return "Weapons"
        }
    }

    var symbol: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .vehicles: return "car.fill"
        case .property: return "house.fill"
        case .jewelry: return "sparkles"
        case .weapons: return "shield.fill"
        }
    }

    static func parse(_ token: String) -> AssetsSubTab? {
        switch token.lowercased() {
        case "overview": return .overview
        case "vehicles", "vehicle", "garage", "cars": return .vehicles
        case "property", "properties", "home", "realestate", "real-estate": return .property
        case "jewelry", "jewellery", "valuables", "boutique", "ice": return .jewelry
        case "weapons", "weapon", "armory", "guns", "gear": return .weapons
        default: return AssetsSubTab(rawValue: token.lowercased())
        }
    }
}

/// Careers sub-tabs — Phase 3 scaffold.
enum CareersSubTab: String, CaseIterable, Codable, Identifiable {
    case overview
    case currentJob
    case opportunities
    case skills
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .currentJob: return "Current Job"
        case .opportunities: return "Opportunities"
        case .skills: return "Skills"
        case .history: return "History"
        }
    }

    var symbol: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .currentJob: return "briefcase.fill"
        case .opportunities: return "door.left.hand.open"
        case .skills: return "chart.line.uptrend.xyaxis"
        case .history: return "clock.arrow.circlepath"
        }
    }

    static func parse(_ token: String) -> CareersSubTab? {
        switch token.lowercased() {
        case "overview": return .overview
        case "current", "job", "currentjob", "work": return .currentJob
        case "opportunities", "offers", "applications": return .opportunities
        case "skills", "progress", "skill": return .skills
        case "history", "log": return .history
        default: return CareersSubTab(rawValue: token.lowercased())
        }
    }
}

struct ConsoleNavigationState: Equatable, Codable {
    var assetsSubTab: AssetsSubTab = .overview
    var careersSubTab: CareersSubTab = .overview

    mutating func resetToRoot() {
        assetsSubTab = .overview
        careersSubTab = .overview
    }
}

struct ConsoleNavigationCommand: Equatable {
    var message: String
    var targetTab: GameViewModel.Tab?
    var resetToRoot: Bool = false
    var assetsSubTab: AssetsSubTab?
    var careersSubTab: CareersSubTab?

    mutating func apply(to navigation: inout ConsoleNavigationState) {
        if resetToRoot {
            navigation.resetToRoot()
        }
        if let assetsSubTab {
            navigation.assetsSubTab = assetsSubTab
        }
        if let careersSubTab {
            navigation.careersSubTab = careersSubTab
        }
    }
}

enum ConsoleNavigationCoordinator {

    static func parse(command raw: String) -> ConsoleNavigationCommand? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(separator: " ").map(String.init)
        guard let verb = parts.first else { return nil }

        switch verb {
        case "nav", "navigation":
            guard parts.count >= 2 else { return nil }
            if parts[1] == "root" || parts[1] == "home" || parts[1] == "life" {
                return ConsoleNavigationCommand(
                    message: "Navigation: root (Life tab, sub-tabs reset)",
                    targetTab: .home,
                    resetToRoot: true
                )
            }
            return nil

        case "enter", "go", "open":
            guard parts.count >= 2 else { return nil }
            let domainToken = parts[1]
            let subToken = parts.count >= 3 ? parts[2] : "overview"

            switch domainToken {
            case "assets", "asset", "money", "cash", "finance":
                guard let sub = AssetsSubTab.parse(subToken) else {
                    return ConsoleNavigationCommand(message: "Unknown assets sub-tab: \(subToken)", targetTab: .assets)
                }
                return ConsoleNavigationCommand(
                    message: "Navigation: assets → \(sub.title)",
                    targetTab: .assets,
                    assetsSubTab: sub
                )

            case "careers", "career", "work", "jobs", "school", "occupation":
                guard let sub = CareersSubTab.parse(subToken) else {
                    return ConsoleNavigationCommand(message: "Unknown careers sub-tab: \(subToken)", targetTab: .occupation)
                }
                return ConsoleNavigationCommand(
                    message: "Navigation: careers → \(sub.title)",
                    targetTab: .occupation,
                    careersSubTab: sub
                )

            case "life", "home":
                return ConsoleNavigationCommand(
                    message: "Navigation: life (root)",
                    targetTab: .home,
                    resetToRoot: true
                )

            case "love", "social", "relationships":
                return ConsoleNavigationCommand(message: "Navigation: social", targetTab: .relationships)

            case "play", "activities":
                return ConsoleNavigationCommand(message: "Navigation: play", targetTab: .activities)

            default:
                return nil
            }

        default:
            return nil
        }
    }
}

// MARK: - DomainActionRegistry navigation helpers

extension DomainActionRegistry {
    /// Maps assets sub-tab to relevant finance/asset action IDs for quick surfacing.
    func quickActionsForAssetsSubTab(_ subTab: AssetsSubTab) -> [ActionChoiceID] {
        let financeQuick = availableQuick(for: .finance)
        switch subTab {
        case .overview:
            return [.flexLuxuryAsset, .curateCollection, .maintainAsset].filter { financeQuick.contains($0) }
        case .vehicles:
            return financeQuick.filter { [.maintainAsset, .upgradeCollection].contains($0) }
        case .property:
            return financeQuick.filter { [.hostAtSignatureEstate, .hostSignatureEvent, .topUpHouseReserve].contains($0) }
        case .jewelry:
            return financeQuick.filter { [.flexLuxuryAsset, .displayWealth].contains($0) }
        case .weapons:
            return []
        }
    }

    func consoleDomainLabel(for tab: GameViewModel.Tab, showingEducation: Bool) -> String {
        switch tab {
        case .home: return "life"
        case .occupation: return showingEducation ? "school" : "careers"
        case .assets: return "assets"
        case .relationships: return "love"
        case .activities: return "play"
        case .history: return "journal"
        }
    }

    func quickActionsForCareersSubTab(_ subTab: CareersSubTab) -> [ActionChoiceID] {
        let careerQuick = availableQuick(for: .career)
        switch subTab {
        case .overview:
            return Array(careerQuick.prefix(3))
        case .currentJob:
            return careerQuick
        case .opportunities:
            return careerQuick.filter { [.workHard, .takeOvertime, .takeExtraShifts].contains($0) }
        case .skills:
            return careerQuick.filter { [.workHard, .takeExtraShifts].contains($0) }
        case .history:
            return []
        }
    }
}
