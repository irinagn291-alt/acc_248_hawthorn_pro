import SwiftUI

/// Contact, onboarding replay, and a confirmed reset. The contact link is the review address.
struct SettingsSheet: View {
    @Environment(BarSession.self) private var session
    @State private var confirmReset = false

    private let contact = URL(string: "https://hawthorn-tin.pro/contact-us")

    var body: some View {
        NavigationStack {
            Form {
                if let error = session.actionError, error.hasPrefix("Reset") {
                    Section {
                        Text(error)
                            .font(StudioMeasure.body)
                            .foregroundStyle(DesignTokens.ink)
                        Button("Try reset again") {
                            confirmReset = true
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                }
                Section("Bar on this device") {
                    LabeledContent("Stowed") {
                        Text(StudioMeasure.count(session.projection.stowed.count))
                            .font(StudioMeasure.body)
                    }
                    LabeledContent("Shakes") {
                        Text(StudioMeasure.count(session.projection.shakeMarks.count))
                            .font(StudioMeasure.body)
                    }
                }
                Section("Introduction") {
                    Button("Replay introduction") {
                        session.showOnboarding = true
                        session.desk = .surprise
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                Section("Contact") {
                    if let contact {
                        Link("Contact Hawthorn", destination: contact)
                            .frame(minHeight: 44)
                    }
                }
                Section("Reset") {
                    Button("Reset all data") {
                        confirmReset = true
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .buttonStyle(SoftCardButtonStyle(tone: .destructive))
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignTokens.bg)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseDeskButton { session.desk = .surprise }
                }
            }
            .confirmationDialog(
                "Reset the bar on this device? Stowed bottles, tags, pins, and shake history are removed.",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset all data", role: .destructive) {
                    Task { await session.resetAllData() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

/// Named screen for the settings sheet.
struct SettingsView: View {
    var body: some View { SettingsSheet() }
}
