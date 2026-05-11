import SwiftUI

/// The deep "Customize" screen. Everything the brief asks to be tunable lives
/// here, grouped into readable sections. Changes flow straight into
/// `AppSettings`, which the screensaver observes and re‑applies live.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var confirmingReset = false

    private static let backgroundPresets: [RGBA] = [
        RGBA(hex: "#05060A"), RGBA(hex: "#0B0B0D"), RGBA(hex: "#0A0E1C"),
        RGBA(hex: "#1A0E1E"), RGBA(hex: "#0A1A0F"), RGBA(hex: "#101014"), RGBA(hex: "#020203"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                ScreenTitle(title: "Customize", subtitle: "Make the bounce yours. Everything updates live.")

                // MARK: Logo text
                SettingSection(title: "Logo") {
                    GlassCard(cornerRadius: 22, padding: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top, spacing: 24) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Logo text").font(.system(.title3, design: .rounded).weight(.semibold))
                                    Text("The word in the bouncing badge on most themes. Your name, your channel, anything.")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                                DiscBadgeMark(text: settings.customLogoText,
                                              tint: settings.resolvedTheme.collisionColor(at: 1).color,
                                              scale: 1.4)
                                    .frame(height: 64, alignment: .center)
                            }
                            TextField("Your name", text: $settings.customLogoText)
                                .font(.system(.title2, design: .rounded).weight(.bold))
                        }
                    }
                }

                // MARK: Display mode
                SettingSection(title: "Mode", caption: settings.displayMode.detail) {
                    ChipPickerRow(
                        title: "Display mode",
                        caption: "A starting point. Tweak the sliders below however you like.",
                        selection: Binding(get: { settings.displayMode }, set: { settings.applyMode($0) }),
                        options: DisplayMode.allCases.map { ($0, $0.displayName) }
                    )
                }

                // MARK: Motion
                SettingSection(title: "Motion") {
                    SliderRow(title: "Speed", caption: "How fast the logo crosses the screen.",
                              value: $settings.speed, range: AppSettings.speedRange) { String(format: "%.2f×", $0) }
                    SliderRow(title: "Logo size", value: $settings.logoScale, range: AppSettings.logoScaleRange) { String(format: "%.0f%%", $0 * 100) }
                    IntSliderRow(title: "Logo count", caption: "More logos = more chances at a corner.",
                                 value: $settings.logoCount, range: AppSettings.logoCountRange, unit: "logo")
                    ToggleRow(title: "Logos collide with each other", caption: "Bounce off one another instead of passing through.",
                              systemImage: "circle.grid.cross", isOn: $settings.interLogoCollisions, enabled: settings.logoCount > 1)
                }

                // MARK: Background
                SettingSection(title: "Background") {
                    ToggleRow(title: "Custom background colour", caption: "Override the theme's background with a flat colour.",
                              isOn: $settings.customBackgroundEnabled)
                    if settings.customBackgroundEnabled {
                        ColorSwatchRow(title: "Colour", selected: $settings.customBackgroundColor, presets: Self.backgroundPresets)
                    }
                }

                // MARK: Corner‑hit payoff
                SettingSection(title: "The Corner Hit", caption: "The payoff. Tune the celebration.") {
                    ToggleRow(title: "Screen flash", caption: "A tasteful bloom from the corner that was struck.",
                              isOn: $settings.cornerFlashEnabled)
                    ToggleRow(title: "Corner particles", isOn: $settings.cornerParticlesEnabled)
                    ToggleRow(title: "Screen shake", caption: "A short pulse. Apple TV has no haptics, so the screen does the shaking.",
                              isOn: $settings.screenShakeEnabled)
                    ToggleRow(title: "Close‑call effects", caption: "Acknowledge the near misses, too.",
                              isOn: $settings.closeCallEffectsEnabled)
                }

                // MARK: Experience
                SettingSection(title: "Experience") {
                    ToggleRow(title: "On‑screen counter", caption: "Show the corner counter and \u{201c}time since last perfect corner\u{201d}.",
                              systemImage: "number", isOn: $settings.hudEnabled)
                    ToggleRow(title: "Auto‑hide controls", systemImage: "eye.slash", isOn: $settings.autoHideUI)
                    SliderRow(title: "Auto‑hide delay", value: $settings.autoHideDelay, range: AppSettings.autoHideDelayRange, step: 1) { "\(Int($0)) s" }
                        .opacity(settings.autoHideUI ? 1 : 0.45)
                    ToggleRow(title: "Streamer / ambient mode", caption: "No flashes, no banners: just the bounce. Great as a stream background.",
                              systemImage: "dot.radiowaves.left.and.right", isOn: $settings.streamerModeEnabled)
                    ToggleRow(title: "Reduce motion", caption: "Slower movement, gentler effects. Also follows the system setting.",
                              systemImage: "tortoise.fill", isOn: $settings.reduceMotion)
                }

                // MARK: Reset
                HStack {
                    Button(role: confirmingReset ? .destructive : nil) {
                        if confirmingReset { settings.resetToDefaults(); confirmingReset = false }
                        else {
                            confirmingReset = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { confirmingReset = false }
                        }
                    } label: {
                        Label(confirmingReset ? "Press again to confirm" : "Reset all settings to defaults",
                              systemImage: confirmingReset ? "exclamationmark.triangle.fill" : "arrow.counterclockwise")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                    }
                    .buttonStyle(CardButtonStyle(cornerRadius: 18, accent: confirmingReset ? .red : .white))
                    Spacer()
                }
                .padding(.top, 8)

                Color.clear.frame(height: 60)
            }
            .padding(.horizontal, 90)
            .padding(.vertical, 70)
            .frame(maxWidth: 1300, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview("Customize") {
    SettingsView().injecting(.preview(themeID: .retroCRT))
}
