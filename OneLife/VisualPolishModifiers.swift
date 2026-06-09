import SwiftUI

struct GlassCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = DesignSystem.Radius.large
    var blurRadius: CGFloat = 20
    var opacity: Double = 0.55
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if colorScheme == .light {
                        Color.white.opacity(0.45)
                            .background(Blur(radius: blurRadius))
                    } else {
                        Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.65)
                            .background(Blur(radius: blurRadius))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                colorScheme == .light ? .white.opacity(0.6) : .white.opacity(0.2),
                                colorScheme == .light ? .white.opacity(0.2) : .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(colorScheme == .light ? 0.08 : 0.25), radius: 24, y: 12)
    }
}

/// Simple Blur wrapper for SwiftUI (since .blur is content-only)
struct Blur: View {
    var radius: CGFloat = 20
    var style: UIBlurEffect.Style = .systemUltraThinMaterial
    
    var body: some View {
        BackdropBlur(radius: radius)
    }
}

struct BackdropBlur: UIViewRepresentable {
    var radius: CGFloat
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

extension View {
    func glassCard(radius: CGFloat = DesignSystem.Radius.large) -> some View {
        self.modifier(GlassCard(cornerRadius: radius))
    }
}
