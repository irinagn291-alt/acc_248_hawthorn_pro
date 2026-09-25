import SwiftUI

/// Three pages. Continue and Next sit full width at the bottom. Skip writes the same completion flag.
struct OnboardingCover: View {
    @Environment(BarSession.self) private var session
    @State private var page = 0

    private let pages: [(art: String, title: String, line: String)] = [
        ("hwt_Onboarding1", "Tonight comes from three bottles", "Hawthorn matches one cocktail to the trio you tag. The rest of the rail stays out of the shake."),
        ("hwt_Onboarding2", "Tag, then shake", "Seat three bottles you already own. Shake reads that set. A miss leaves the slots so you can peel and retag."),
        ("hwt_Onboarding3", "The bar stays on this device", "Stowed bottles are not emptied by a shake. Pin a recipe you will make again.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: StudioMeasure.unit * 2) {
            HStack {
                Spacer()
                Button("Skip") {
                    session.finishOnboarding()
                }
                .font(StudioMeasure.body)
                .foregroundStyle(DesignTokens.ink)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            let current = pages[page]
            VStack(alignment: .leading, spacing: StudioMeasure.unit * 2) {
                Image(current.art)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .accessibilityHidden(true)
                Text(current.title)
                    .font(StudioMeasure.title)
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(3)
                Text(current.line)
                    .font(StudioMeasure.body)
                    .foregroundStyle(DesignTokens.muted)
                    .lineLimit(5)
                Text(pageLine)
                    .font(StudioMeasure.micro)
                    .foregroundStyle(DesignTokens.muted)
            }
            .padding(.horizontal, StudioMeasure.unit * 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            Button(page == pages.count - 1 ? "Continue" : "Next") {
                if page == pages.count - 1 {
                    session.finishOnboarding()
                } else {
                    page += 1
                }
            }
            .buttonStyle(SoftCardButtonStyle())
            .padding(.horizontal, StudioMeasure.unit * 3)
            .padding(.bottom, StudioMeasure.unit * 2)
        }
        .background(DesignTokens.bg)
    }

    private var pageLine: String {
        let current = StudioMeasure.count(page + 1)
        let total = StudioMeasure.count(pages.count)
        return "\(current) of \(total)"
    }
}
