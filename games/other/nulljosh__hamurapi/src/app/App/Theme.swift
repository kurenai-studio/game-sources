import SwiftUI

enum Theme {
    static let sky = Color(red: 0.965, green: 0.965, blue: 0.957)
    static let ground = Color(red: 0.929, green: 0.929, blue: 0.918)
    static let furrow = Color(red: 0.886, green: 0.886, blue: 0.871)
    static let horizon = Color(red: 0.80, green: 0.80, blue: 0.78)
    static let river = Color(red: 0.651, green: 0.796, blue: 0.933)
    static let riverLine = Color.white
    static let ink = Color(red: 0.137, green: 0.149, blue: 0.176)
    static let muted = Color(red: 0.40, green: 0.42, blue: 0.46)
    static let accent = Color(red: 0.710, green: 0.314, blue: 0.173)  // #b5502c
    static let line = Color.black.opacity(0.10)
}

extension View {
    /// Liquid Glass where the OS has it, a thin material where it doesn't.
    @ViewBuilder func glass(_ radius: CGFloat = 24) -> some View {
        if #available(iOS 26, macOS 26, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: radius))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
                .overlay(RoundedRectangle(cornerRadius: radius).stroke(Theme.line))
        }
    }
}

struct PrimaryButton: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(enabled ? Theme.accent : Theme.muted.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct QuietButton: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
            .opacity(!enabled ? 0.4 : configuration.isPressed ? 0.7 : 1)
    }
}

func fmt(_ n: Int) -> String { n.formatted(.number) }
