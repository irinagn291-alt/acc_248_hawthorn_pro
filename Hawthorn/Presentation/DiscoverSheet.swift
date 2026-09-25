import SwiftUI

/// Catalog triples against stowed bottles. Match is a word, not color alone.
struct DiscoverSheet: View {
    @Environment(BarSession.self) private var session

    var body: some View {
        NavigationStack {
            Group {
                if let error = session.catalogError {
                    TrayError(line: error, action: "Close") {
                        session.desk = .surprise
                    }
                } else if session.recipes.isEmpty {
                    EmptyTray(
                        art: "hwt_EmptyList",
                        headline: "No triples in the catalog",
                        line: "Hawthorn has nothing to match against the bar yet.",
                        action: "Close"
                    ) {
                        session.desk = .surprise
                    }
                } else {
                    let owned = Set(session.projection.stowed)
                    let rows = TinFold.unlocks(in: session.recipes, owned: owned)
                    List(rows) { unlock in
                        VStack(alignment: .leading, spacing: StudioMeasure.unit) {
                            Text(unlock.recipe.name)
                                .font(StudioMeasure.headline)
                                .foregroundStyle(DesignTokens.ink)
                                .lineLimit(2)
                            Text(matchWord(unlock))
                                .font(StudioMeasure.caption)
                                .foregroundStyle(DesignTokens.muted)
                                .lineLimit(2)
                            Text(unlock.recipe.primaryTriple.bottleIDs.map { session.name(for: $0) }.joined(separator: ", "))
                                .font(StudioMeasure.micro)
                                .foregroundStyle(DesignTokens.ink)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.vertical, StudioMeasure.unit)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(DesignTokens.bg)
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseDeskButton { session.desk = .surprise }
                }
            }
        }
    }

    private func matchWord(_ unlock: TripleUnlock) -> String {
        if unlock.isFull {
            return "Full match. All \(StudioMeasure.count(TinFold.capacity)) bottles are stowed."
        }
        if unlock.ownedCount == 0 {
            return "None of these bottles are on the bar."
        }
        return "Partial match. \(StudioMeasure.count(unlock.ownedCount)) of \(StudioMeasure.count(TinFold.capacity)) stowed."
    }
}

/// Named screen for the discover sheet.
struct DiscoverView: View {
    var body: some View { DiscoverSheet() }
}
