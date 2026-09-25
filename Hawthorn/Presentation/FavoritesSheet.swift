import SwiftUI

/// Pinned recipes and pour counts grouped by daykey.
struct FavoritesSheet: View {
    @Environment(BarSession.self) private var session

    var body: some View {
        NavigationStack {
            Group {
                if let error = session.catalogError, session.projection.pins.isEmpty {
                    TrayError(line: error, action: "Close") {
                        session.desk = .surprise
                    }
                } else if session.projection.pins.isEmpty && session.projection.shakeMarks.isEmpty {
                    EmptyTray(
                        art: "hwt_EmptyList",
                        headline: "Nothing pinned yet",
                        line: "Shake a matching trio on Surprise, then pin the recipe you will make again.",
                        action: "Back to the tin"
                    ) {
                        session.desk = .surprise
                    }
                } else {
                    List {
                        if !session.projection.pins.isEmpty {
                            Section("Pinned") {
                                ForEach(session.projection.pins, id: \.self) { id in
                                    VStack(alignment: .leading, spacing: StudioMeasure.unit) {
                                        Text(session.recipe(id: id)?.name ?? id)
                                            .font(StudioMeasure.headline)
                                            .foregroundStyle(DesignTokens.ink)
                                            .lineLimit(2)
                                        Text(methodLine(id))
                                            .font(StudioMeasure.caption)
                                            .foregroundStyle(DesignTokens.muted)
                                            .lineLimit(3)
                                        Button("Unpin") {
                                            Task { await session.unpin(id) }
                                        }
                                        .font(StudioMeasure.body)
                                        .frame(minHeight: 44)
                                        .contentShape(Rectangle())
                                    }
                                    .padding(.vertical, StudioMeasure.unit)
                                }
                            }
                        }
                        Section("Pours by day") {
                            let groups = Dictionary(grouping: session.projection.shakeMarks, by: \.daykey)
                            if groups.isEmpty {
                                Text("No shakes recorded yet.")
                                    .font(StudioMeasure.body)
                                    .foregroundStyle(DesignTokens.muted)
                            } else {
                                ForEach(groups.keys.sorted(by: >), id: \.self) { day in
                                    HStack {
                                        Text(StudioMeasure.dayKey(day))
                                            .font(StudioMeasure.body)
                                            .foregroundStyle(DesignTokens.ink)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(StudioMeasure.count(groups[day]?.count ?? 0))
                                            .font(StudioMeasure.headline)
                                            .foregroundStyle(DesignTokens.accent)
                                            .lineLimit(1)
                                    }
                                    .frame(minHeight: 44)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(DesignTokens.bg)
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseDeskButton { session.desk = .surprise }
                }
            }
        }
    }

    private func methodLine(_ id: String) -> String {
        session.recipe(id: id)?.method ?? "Pinned from a shake."
    }
}

/// Named screen for the favorites sheet.
struct FavoritesView: View {
    var body: some View { FavoritesSheet() }
}
