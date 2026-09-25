import SwiftUI

/// Root chrome. Surprise never pushes. Bar, Discover, Favorites, and Settings are sheets.
struct ContentView: View {
    @State private var session = BarSession()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            if session.showOnboarding {
                OnboardingCover()
            } else if session.isLoading && session.showSpinner {
                ProgressView("Opening the tin")
                    .font(StudioMeasure.body)
                    .tint(DesignTokens.accent)
            } else {
                SurpriseView()
            }
        }
        .environment(session)
        .tint(DesignTokens.accent)
        .sheet(isPresented: sheetPresented) {
            sheetBody
                .environment(session)
                .presentationCornerRadius(StudioMeasure.card)
                .presentationBackground(DesignTokens.surface)
        }
        .task { await session.prepare() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                Task { await session.store.flushForScenePhase() }
            }
        }
    }

    @ViewBuilder
    private var sheetBody: some View {
        switch session.desk {
        case .bar: BarView()
        case .discover: DiscoverView()
        case .favorites: FavoritesView()
        case .settings: SettingsView()
        case .surprise: EmptyView()
        }
    }

    private var sheetPresented: Binding<Bool> {
        Binding(
            get: { session.desk != .surprise && !session.showOnboarding },
            set: { presented in
                if !presented { session.desk = .surprise }
            }
        )
    }
}

#Preview {
    ContentView()
}
