import SwiftUI

// MARK: - Panel surface

/// A flat, hairline‑bordered container — the recurring surface for menu detail
/// screens, settings rows, stat blocks, onboarding panels. Deliberately *not*
/// frosted glass: the menu scrim already supplies the depth, so panels on top of
/// it read as solid, tinted a hair toward the active theme. Kept the name
/// `GlassCard` because every screen calls it.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 24
    var tint: Color = .white
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.42))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(0.05))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(.white.opacity(0.07), lineWidth: 1)
                    }
            }
    }
}

// MARK: - Section header

struct SectionHeader: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(.headline, design: .rounded).weight(.bold))
                .tracking(2.5)
                .foregroundStyle(.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Big title

struct ScreenTitle: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 56, weight: .heavy, design: .rounded))
            if let subtitle {
                Text(subtitle)
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Focusable card button

/// tvOS focus feel without the platform's chunky chrome: a solid dark panel that
/// gains an accent fill, an accent ring, a soft glow and a small lift on focus.
struct CardButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 22
    var accent: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        FocusAware(cornerRadius: cornerRadius, accent: accent, isPressed: configuration.isPressed) {
            configuration.label
        }
    }

    private struct FocusAware<Label: View>: View {
        var cornerRadius: CGFloat
        var accent: Color
        var isPressed: Bool
        @ViewBuilder var label: Label
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            label
                .padding(.vertical, 18)
                .padding(.horizontal, 26)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(0.40))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(accent.opacity(isFocused ? 0.18 : 0))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(isFocused ? accent.opacity(0.7) : .white.opacity(0.08),
                                              lineWidth: isFocused ? 2 : 1)
                        }
                }
                .shadow(color: accent.opacity(isFocused ? 0.30 : 0), radius: isFocused ? 20 : 0, y: 6)
                .scaleEffect(isPressed ? 0.97 : (isFocused ? 1.05 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.88), value: isFocused)
                .animation(.spring(response: 0.2, dampingFraction: 0.92), value: isPressed)
        }
    }
}

// MARK: - Primary CTA button style (onboarding, confirmations)

struct PrimaryButtonStyle: ButtonStyle {
    var accent: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        Inner(accent: accent, isPressed: configuration.isPressed) { configuration.label }
    }
    private struct Inner<Label: View>: View {
        var accent: Color
        var isPressed: Bool
        @ViewBuilder var label: Label
        @Environment(\.isFocused) private var isFocused
        var body: some View {
            label
                .font(.system(.title3, design: .rounded).weight(.bold))
                .padding(.vertical, 18)
                .padding(.horizontal, 40)
                .background {
                    Capsule().fill(isFocused ? AnyShapeStyle(accent) : AnyShapeStyle(Color.black.opacity(0.45)))
                }
                .foregroundStyle(isFocused ? .black : .white)
                .overlay { Capsule().strokeBorder(isFocused ? .clear : .white.opacity(0.16), lineWidth: 1) }
                .shadow(color: accent.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 22 : 0, y: 8)
                .scaleEffect(isPressed ? 0.96 : (isFocused ? 1.07 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.88), value: isFocused)
                .animation(.spring(response: 0.2, dampingFraction: 0.92), value: isPressed)
        }
    }
}

// MARK: - Pill / chip

struct InfoChip: View {
    var text: String
    var systemImage: String?
    var body: some View {
        HStack(spacing: 8) {
            if let systemImage { Image(systemName: systemImage) }
            Text(text)
        }
        .font(.system(.footnote, design: .rounded).weight(.semibold))
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(Capsule().fill(Color.black.opacity(0.42)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1))
    }
}
