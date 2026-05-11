import SwiftUI

/// Reusable, large‑readability control rows for the Customize screen. SwiftUI's
/// `Slider` and `Stepper` aren't available on tvOS, so the value rows use a
/// purpose‑built `RemoteSlider` driven by Siri Remote left/right moves.

struct SettingSection<Content: View>: View {
    var title: String
    var caption: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: title, subtitle: caption)
            VStack(spacing: 16) { content }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Remote‑driven slider

/// A focusable bar: focus it, then swipe / press left or right to adjust. Each
/// move changes the value by `step` (or 1/20th of the range if `step == 0`).
struct RemoteSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 0
    var accent: Color = .accentColor
    var onChange: ((Double) -> Void)? = nil

    @FocusState private var isFocused: Bool

    private var fraction: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat((value - range.lowerBound) / span).clamped(to: 0...1)
    }
    private var increment: Double { step > 0 ? step : (range.upperBound - range.lowerBound) / 20 }

    var body: some View {
        GeometryReader { geo in
            let trackHeight: CGFloat = isFocused ? 16 : 10
            let thumb: CGFloat = isFocused ? 32 : 22
            let usable = max(0, geo.size.width - thumb)
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.10)).frame(height: trackHeight)
                Capsule().fill(isFocused ? AnyShapeStyle(accent) : AnyShapeStyle(.white.opacity(0.55)))
                    .frame(width: thumb + usable * fraction, height: trackHeight)
                Circle()
                    .fill(.white)
                    .frame(width: thumb, height: thumb)
                    .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1))
                    .shadow(color: accent.opacity(isFocused ? 0.5 : 0), radius: isFocused ? 14 : 0)
                    .offset(x: usable * fraction)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 34)
        .focusable()
        .focused($isFocused)
        .onMoveCommand { direction in
            switch direction {
            case .left:  set(value - increment)
            case .right: set(value + increment)
            default:     break
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: isFocused)
        .animation(.easeOut(duration: 0.12), value: value)
    }

    private func set(_ raw: Double) {
        let clamped = raw.clamped(to: range)
        let snapped = step > 0 ? (clamped / step).rounded() * step : clamped
        value = snapped.clamped(to: range)
        onChange?(value)
    }
}

struct SliderRow: View {
    var title: String
    var caption: String?
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 0
    var format: (Double) -> String

    var body: some View {
        GlassCard(cornerRadius: 22, padding: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).font(.system(.title3, design: .rounded).weight(.semibold))
                    Spacer(minLength: 24)
                    Text(format(value))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.65))
                }
                if let caption {
                    Text(caption)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                RemoteSlider(value: $value, range: range, step: step)
                    .padding(.top, 2)
            }
        }
    }
}

struct IntSliderRow: View {
    var title: String
    var caption: String?
    @Binding var value: Int
    var range: ClosedRange<Int>
    var unit: String = ""

    var body: some View {
        SliderRow(title: title, caption: caption,
                  value: Binding(get: { Double(value) }, set: { value = Int($0.rounded()) }),
                  range: Double(range.lowerBound)...Double(range.upperBound),
                  step: 1) { v in
            let n = Int(v.rounded())
            return unit.isEmpty ? "\(n)" : "\(n) \(unit)\(n == 1 ? "" : "s")"
        }
    }
}

/// A whole‑row toggle. The native tvOS `Toggle` recolours its label with the
/// focus tint (blue), which clashes with the rest of the screen — so this is a
/// plain focusable button with an "On / Off" pill, styled like every other row.
struct ToggleRow: View {
    var title: String
    var caption: String?
    var systemImage: String?
    @Binding var isOn: Bool
    var enabled: Bool = true

    var body: some View {
        Button {
            guard enabled else { return }
            isOn.toggle()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.system(.title3, design: .rounded).weight(.semibold))
                    if let caption {
                        Text(caption)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                StatePill(on: isOn)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(CardButtonStyle(cornerRadius: 22))
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
}

private struct StatePill: View {
    var on: Bool
    var body: some View {
        Text(on ? "On" : "Off")
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(on ? Color.black : .white.opacity(0.55))
            .frame(minWidth: 40)
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(Capsule().fill(on ? AnyShapeStyle(.white.opacity(0.9)) : AnyShapeStyle(Color.clear)))
            .overlay(Capsule().strokeBorder(.white.opacity(on ? 0 : 0.25), lineWidth: 1.5))
            .animation(.easeOut(duration: 0.15), value: on)
    }
}

/// A horizontal picker rendered as a row of focusable chips (a segmented `Picker`
/// is cramped on tvOS; this reads better from the couch).
struct ChipPickerRow<T: Hashable>: View {
    var title: String
    var caption: String?
    @Binding var selection: T
    var options: [(value: T, label: String)]
    var onSelect: ((T) -> Void)? = nil

    var body: some View {
        GlassCard(cornerRadius: 22, padding: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text(title).font(.system(.title3, design: .rounded).weight(.semibold))
                if let caption {
                    Text(caption)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 12) {
                    ForEach(options, id: \.value) { option in
                        Button {
                            selection = option.value
                            onSelect?(option.value)
                        } label: {
                            Text(option.label)
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .padding(.vertical, 8)
                                .frame(minWidth: 80)
                        }
                        .buttonStyle(ChipButtonStyle(selected: option.value == selection))
                    }
                }
                .padding(.top, 2)
            }
        }
    }
}

struct ChipButtonStyle: ButtonStyle {
    var selected: Bool
    func makeBody(configuration: Configuration) -> some View {
        Inner(selected: selected, isPressed: configuration.isPressed) { configuration.label }
    }
    private struct Inner<Label: View>: View {
        var selected: Bool
        var isPressed: Bool
        @ViewBuilder var label: Label
        @Environment(\.isFocused) private var isFocused
        var body: some View {
            label
                .padding(.horizontal, 18)
                .background {
                    Capsule().fill(selected ? AnyShapeStyle(.white.opacity(0.92)) : AnyShapeStyle(Color.black.opacity(0.40)))
                }
                .foregroundStyle(selected ? Color.black : Color.white)
                .overlay { Capsule().strokeBorder(.white.opacity(isFocused ? 0.6 : (selected ? 0 : 0.12)), lineWidth: isFocused ? 2 : 1) }
                .scaleEffect(isPressed ? 0.95 : (isFocused ? 1.08 : 1.0))
                .animation(.spring(response: 0.28, dampingFraction: 0.88), value: isFocused)
                .animation(.spring(response: 0.18, dampingFraction: 0.9), value: isPressed)
        }
    }
}

/// A row of preset background colour swatches.
struct ColorSwatchRow: View {
    var title: String
    var caption: String?
    @Binding var selected: RGBA
    var presets: [RGBA]

    var body: some View {
        GlassCard(cornerRadius: 22, padding: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text(title).font(.system(.title3, design: .rounded).weight(.semibold))
                if let caption {
                    Text(caption)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 14) {
                    ForEach(presets.indices, id: \.self) { i in
                        let color = presets[i]
                        Button { selected = color } label: {
                            Circle()
                                .fill(color.color)
                                .frame(width: 56, height: 56)
                                .overlay { Circle().strokeBorder(.white.opacity(color.luminance < 0.5 ? 0.18 : 0.4), lineWidth: 1) }
                        }
                        .buttonStyle(SwatchButtonStyle(selected: closeEnough(color, selected)))
                    }
                }
            }
        }
    }

    private func closeEnough(_ a: RGBA, _ b: RGBA) -> Bool {
        abs(a.red - b.red) < 0.02 && abs(a.green - b.green) < 0.02 && abs(a.blue - b.blue) < 0.02
    }
}

struct SwatchButtonStyle: ButtonStyle {
    var selected: Bool
    func makeBody(configuration: Configuration) -> some View {
        Inner(selected: selected, isPressed: configuration.isPressed) { configuration.label }
    }
    private struct Inner<Label: View>: View {
        var selected: Bool
        var isPressed: Bool
        @ViewBuilder var label: Label
        @Environment(\.isFocused) private var isFocused
        var body: some View {
            label
                .padding(6)
                .overlay {
                    Circle().strokeBorder(.white.opacity(isFocused ? 0.9 : (selected ? 0.6 : 0)), lineWidth: isFocused ? 3 : 2)
                }
                .scaleEffect(isPressed ? 0.92 : (isFocused ? 1.18 : (selected ? 1.06 : 1.0)))
                .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isFocused)
                .animation(.spring(response: 0.18, dampingFraction: 0.9), value: isPressed)
        }
    }
}
