import SwiftUI

/// The deep "Customize" screen. Everything the brief asks to be tunable lives
/// here, grouped into readable sections. Changes flow straight into
/// `AppSettings`, which the screensaver observes and re‑applies live.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var audio: AudioController
    @State private var confirmingReset = false

    private static let backgroundPresets: [RGBA] = [
        RGBA(hex: "#05060A"), RGBA(hex: "#0B0B0D"), RGBA(hex: "#0A0E1C"),
        RGBA(hex: "#1A0E1E"), RGBA(hex: "#0A1A0F"), RGBA(hex: "#101014"), RGBA(hex: "#000000"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                ScreenTitle(title: "Customize", subtitle: "Make the bounce yours. Everything updates live.")

                // MARK: Display mode
                SettingSection(title: "Mode", caption: settings.displayMode.detail) {
                    ChipPickerRow(
                        title: "Display mode",
                        caption: "A starting point — tweak the sliders below however you like.",
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
                    SliderRow(title: "Motion blur", caption: "A short ghosting smear along the direction of travel.",
                              value: $settings.motionBlur, range: AppSettings.unitRange) { String(format: "%.0f%%", $0 * 100) }
                }

                // MARK: Look
                SettingSection(title: "Look") {
                    SliderRow(title: "Trail intensity", caption: "Length and density of the fading trail.",
                              value: $settings.trailIntensity, range: AppSettings.unitRange) { String(format: "%.0f%%", $0 * 100) }
                    SliderRow(title: "Glow intensity", value: $settings.glowIntensity, range: AppSettings.unitRange) { String(format: "%.0f%%", $0 * 100) }
                    SliderRow(title: "Screensaver density", caption: "Ambient particles and the puff on every bounce.",
                              value: $settings.particleDensity, range: AppSettings.unitRange) { String(format: "%.0f%%", $0 * 100) }
                    ToggleRow(title: "Custom background colour", caption: "Override the theme background with a flat colour.",
                              systemImage: "paintbrush.fill", isOn: $settings.customBackgroundEnabled)
                    if settings.customBackgroundEnabled {
                        ColorSwatchRow(title: "Background", selected: $settings.customBackgroundColor, presets: Self.backgroundPresets)
                    }
                }

                // MARK: Corner‑hit payoff
                SettingSection(title: "The Corner Hit", caption: "The emotional payoff. Tune the celebration.") {
                    ToggleRow(title: "Screen flash", caption: "A tasteful bloom from the corner that was struck.",
                              systemImage: "bolt.fill", isOn: $settings.cornerFlashEnabled)
                    ToggleRow(title: "Corner particles", systemImage: "sparkles", isOn: $settings.cornerParticlesEnabled)
                    ToggleRow(title: "Screen shake", caption: "A short pulse — Apple TV has no haptics, so the screen does the shaking.",
                              systemImage: "waveform", isOn: $settings.screenShakeEnabled)
                    ToggleRow(title: "Corner sound", systemImage: "speaker.wave.3.fill", isOn: $settings.cornerSoundEnabled)
                    ToggleRow(title: "Close‑call effects", caption: "Acknowledge the near misses, too.",
                              systemImage: "scope", isOn: $settings.closeCallEffectsEnabled)
                }

                // MARK: Audio
                SettingSection(title: "Audio") {
                    ToggleRow(title: "Sound effects", caption: "Soft collision sounds and the corner chime.",
                              systemImage: "speaker.wave.2.fill", isOn: $settings.soundEffectsEnabled)
                    ChipPickerRow(title: "Ambient bed", caption: settings.ambientMode.detail,
                                  selection: $settings.ambientMode,
                                  options: AmbientMode.allCases.map { ($0, $0.displayName) }) { _ in audio.playUIFocus() }
                    SliderRow(title: "Effects volume", value: $settings.sfxVolume, range: AppSettings.volumeRange) { String(format: "%.0f%%", $0 * 100) }
                    SliderRow(title: "Ambient volume", value: $settings.ambientVolume, range: AppSettings.volumeRange) { String(format: "%.0f%%", $0 * 100) }
                }

                // MARK: Experience
                SettingSection(title: "Experience") {
                    ToggleRow(title: "On‑screen counter", caption: "Show the corner counter and \u{201c}time since last perfect corner\u{201d}.",
                              systemImage: "number", isOn: $settings.hudEnabled)
                    ToggleRow(title: "Auto‑hide controls", systemImage: "eye.slash", isOn: $settings.autoHideUI)
                    SliderRow(title: "Auto‑hide delay", value: $settings.autoHideDelay, range: AppSettings.autoHideDelayRange, step: 1) { "\(Int($0)) s" }
                        .opacity(settings.autoHideUI ? 1 : 0.45)
                    ToggleRow(title: "Streamer / ambient mode", caption: "No flashes, no banners — just the bounce. Great as a stream background.",
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
                        Label(confirmingReset ? "Tap again to confirm" : "Reset all settings to defaults",
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
