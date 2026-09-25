import SwiftUI

/// Full-page empty: cutout, one headline, one line, one bottom action.
struct EmptyTray: View {
    let art: String
    let headline: String
    let line: String
    let action: String
    let perform: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: StudioMeasure.unit * 2) {
            Image(art)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: StudioMeasure.unit * 28)
                .clipped()
                .accessibilityHidden(true)
            Text(headline)
                .font(StudioMeasure.title)
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(2)
            Text(line)
                .font(StudioMeasure.body)
                .foregroundStyle(DesignTokens.muted)
                .lineLimit(4)
            Spacer(minLength: StudioMeasure.unit * 2)
            Button(action, action: perform)
                .buttonStyle(SoftCardButtonStyle())
        }
        .padding(StudioMeasure.unit * 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DesignTokens.bg)
    }
}

/// Catalog or log failure with a way forward.
struct TrayError: View {
    let line: String
    let action: String
    let perform: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: StudioMeasure.unit * 2) {
            Text("Something stalled")
                .font(StudioMeasure.title)
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(2)
            Text(line)
                .font(StudioMeasure.body)
                .foregroundStyle(DesignTokens.muted)
                .lineLimit(6)
            Spacer(minLength: StudioMeasure.unit * 2)
            Button(action, action: perform)
                .buttonStyle(SoftCardButtonStyle(tone: .quiet))
        }
        .padding(StudioMeasure.unit * 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DesignTokens.bg)
    }
}
