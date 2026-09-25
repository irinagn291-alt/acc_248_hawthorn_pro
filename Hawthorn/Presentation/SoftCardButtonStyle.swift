import SwiftUI

/// Soft card for the live verb. Destructive reset does not wear the accent.
struct SoftCardButtonStyle: ButtonStyle {
    enum Tone {
        case primary
        case quiet
        case destructive
    }

    var tone: Tone = .primary
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        SoftCardFace(configuration: configuration, tone: tone, isLoading: isLoading)
    }
}

private struct SoftCardFace: View {
    let configuration: ButtonStyleConfiguration
    let tone: SoftCardButtonStyle.Tone
    let isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(StudioMeasure.headline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, StudioMeasure.unit * 2)
            .padding(.vertical, StudioMeasure.unit)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: StudioMeasure.card, style: .continuous))
            .opacity(isLoading ? 0.7 : 1)
            .overlay {
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: StudioMeasure.card, style: .continuous))
            .shadow(color: DesignTokens.ink.opacity(0.12), radius: StudioMeasure.shadowBlur, y: StudioMeasure.shadowY)
    }

    private var foreground: Color {
        if !isEnabled { return DesignTokens.muted }
        switch tone {
        case .primary, .destructive: return DesignTokens.surface
        case .quiet: return DesignTokens.ink
        }
    }

    private var background: Color {
        if !isEnabled { return DesignTokens.surface }
        let base: Color
        switch tone {
        case .primary: base = DesignTokens.accent
        case .quiet: base = DesignTokens.surface
        case .destructive: base = DesignTokens.ink
        }
        return configuration.isPressed ? base.opacity(0.72) : base
    }
}

