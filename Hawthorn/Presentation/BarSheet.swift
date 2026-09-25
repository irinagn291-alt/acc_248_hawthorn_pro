import SwiftUI

/// Inventory sheet. Stow adds a bundled bottle. Tag never consumes it.
struct BarSheet: View {
    @Environment(BarSession.self) private var session

    var body: some View {
        NavigationStack {
            Group {
                if session.projection.stowed.isEmpty && session.catalogNotStowed.isEmpty && session.projection.recoveryNote == nil {
                    EmptyTray(
                        art: "hwt_EmptyList",
                        headline: "The bar is empty",
                        line: "Add a bottle, then pour.",
                        action: "Back to the tin"
                    ) {
                        session.desk = .surprise
                    }
                } else {
                    List {
                        if let note = session.projection.recoveryNote {
                            Section {
                                Text(note)
                                    .font(StudioMeasure.body)
                                    .foregroundStyle(DesignTokens.ink)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            }
                        }
                        if !session.projection.stowed.isEmpty {
                            Section("Stowed") {
                                ForEach(session.projection.stowed, id: \.self) { id in
                                    Text(session.name(for: id))
                                        .font(StudioMeasure.body)
                                        .foregroundStyle(DesignTokens.ink)
                                        .lineLimit(1)
                                        .frame(minHeight: 44)
                                }
                            }
                        }
                        if !session.catalogNotStowed.isEmpty {
                            Section("Still in the case") {
                                ForEach(session.catalogNotStowed) { bottle in
                                    Button(stowTitle(bottle.name)) {
                                        Task { await session.stow(bottle.id) }
                                    }
                                    .font(StudioMeasure.body)
                                    .foregroundStyle(DesignTokens.ink)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                            }
                        }
                        if let error = session.actionError {
                            Section {
                                Text(error)
                                    .font(StudioMeasure.caption)
                                    .foregroundStyle(DesignTokens.ink)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(DesignTokens.bg)
            .navigationTitle("Bar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseDeskButton { session.desk = .surprise }
                }
            }
        }
    }

    private func stowTitle(_ name: String) -> String { "Stow \(name)" }
}

/// Named screen for the bar sheet. The driver matches this type, not the sheet suffix.
struct BarView: View {
    var body: some View { BarSheet() }
}

/// Sheet dismiss. The mark is the symbol. The label is for VoiceOver.
struct CloseDeskButton: View {
    let dismiss: () -> Void

    var body: some View {
        Button(action: dismiss) {
            Image(systemName: "xmark")
                .font(StudioMeasure.body)
                .foregroundStyle(DesignTokens.ink)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(closeLabel)
    }

    private var closeLabel: String { "Close" }
}
