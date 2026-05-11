import SwiftUI

// MARK: - Glass card

/// A frosted, lightly‑bordered container — the recurring surface for menus,
/// settings groups, stat tiles, onboarding panels. Subtle on purpose.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 28
    var padding: CGFloat = 28
    var tint: Color = .white
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(LinearGradient(colors: [tint.opacity(0.10), .clear],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(.white.opacity(0.10), lineWidth: 1)
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

// MARK: - Focusable card button style

/// tvOS focus feel: a gentle lift + soft glow, no chunky platform chrome.
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
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(accent.opacity(isFocused ? 0.18 : 0.04))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(.white.opacity(isFocused ? 0.30 : 0.10), lineWidth: 1)
                        }
                }
                .shadow(color: accent.opacity(isFocused ? 0.35 : 0), radius: isFocused ? 26 : 0, y: 8)
                .scaleEffect(isPressed ? 0.97 : (isFocused ? 1.06 : 1.0))
                .animation(.spring(response: 0.32, dampingFraction: 0.7), value: isFocused)
                .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isPressed)
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
                    Capsule().fill(isFocused ? AnyShapeStyle(accent) : AnyShapeStyle(.ultraThinMaterial))
                }
                .foregroundStyle(isFocused ? .black : .white)
                .overlay { Capsule().strokeBorder(.white.opacity(isFocused ? 0 : 0.18), lineWidth: 1) }
                .shadow(color: accent.opacity(isFocused ? 0.5 : 0), radius: isFocused ? 28 : 0, y: 10)
                .scaleEffect(isPressed ? 0.96 : (isFocused ? 1.08 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
    }
}

// MARK: - Stat tile

struct StatTile: View {
    var label: String
    var value: String
    var systemImage: String?
    var accent: Color = .white

    var body: some View {
        GlassCard(cornerRadius: 24, padding: 24, tint: accent) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(.title3, design: .rounded))
                            .foregroundStyle(accent.opacity(0.9))
                    }
                    Text(label.uppercased())
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(.secondary)
                }
                Text(value)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1))
    }
}
