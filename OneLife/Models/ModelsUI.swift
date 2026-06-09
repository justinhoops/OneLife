import SwiftUI

import SwiftUI

/// OneLife Design System
/// Based on Codex IV (The UI/UX Manifesto) and Codex VII (The Summary-to-Action Pipeline).
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Visual Polish V1: Warm Palette
        static let backgroundLight = Color(red: 0.98, green: 0.97, blue: 0.95) // Warm Cream (#F9F8F3)
        static let backgroundDark = Color(red: 0.08, green: 0.07, blue: 0.13)  // Warm Dark Midnight (#141120)
        
        static let background = Color.black // Legacy fallback
        static let secondaryBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
        static let surface = Color(red: 0.18, green: 0.18, blue: 0.18)
        
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.45)
        
        // Semantic Colors (Codex IV: Color as Data)
        static let positive = Color(red: 0.17, green: 0.48, blue: 0.27)
        static let neutral = Color(red: 0.23, green: 0.29, blue: 0.36)
        static let warning = Color(red: 0.68, green: 0.22, blue: 0.18)
        
        // Glassmorphism Highlights
        static let glassHighlightLight = Color.white.opacity(0.4)
        static let glassHighlightDark = Color.white.opacity(0.12)
        
        // Background Gradients
        static let lightBackgroundStart = Color(red: 0.98, green: 0.97, blue: 0.95)
        static let lightBackgroundEnd = Color(red: 0.94, green: 0.93, blue: 0.88)
        
        static let accent = Color.blue // Default Accent
    }
    
    // MARK: - Spacing (Codex VII)
    struct Spacing {
        static let micro: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        
        /// Natural Thumb Zone padding
        static let screenEdge: CGFloat = 20
    }
    
    // MARK: - Corner Radius
    struct Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 28 // Friendly, Wii-era rounding
        static let capsule: CGFloat = 999
    }
    
    // MARK: - Typography (Codex IV: Readability)
    struct Typography {
        static let titleLarge = Font.largeTitle.weight(.bold)
        static let titleMain = Font.title.weight(.bold)
        static let titleSecondary = Font.title2.weight(.bold)
        static let titleTertiary = Font.title3.weight(.bold)
        
        static let headline = Font.headline
        static let subheadline = Font.subheadline.weight(.semibold)
        
        static let body = Font.body
        static let bodyBold = Font.body.weight(.bold)
        
        static let footnote = Font.footnote
        static let caption = Font.caption.weight(.semibold)
        static let captionBold = Font.caption.weight(.bold)
        static let caption2 = Font.caption2
    }
}

// MARK: - PlannerTone (Relocated from ContentView)
enum PlannerTone: Equatable {
    case positive
    case neutral
    case warning
    
    var color: Color {
        switch self {
        case .positive: return DesignSystem.Colors.positive
        case .neutral: return DesignSystem.Colors.neutral
        case .warning: return DesignSystem.Colors.warning
        }
    }
    
    var fill: Color {
        color.opacity(0.12)
    }
}

extension PlannerTone {
    init(_ tone: YearlyOutcomeTone) {
        switch tone {
        case .positive:
            self = .positive
        case .neutral:
            self = .neutral
        case .warning:
            self = .warning
        }
    }
}

