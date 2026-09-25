import Foundation

/// Launch keys are arguments, read once after onboarding. They are not tabs.
enum ReviewLaunch {
    enum Desk: Equatable, Sendable {
        case surprise
        case bar
        case discover
        case favorites
        case settings
    }

    /// Read once, after onboarding. today stays on Surprise.
    static func deskFromLaunch() -> Desk {
        desk(from: ProcessInfo.processInfo.arguments)
    }

    static func desk(from arguments: [String]) -> Desk {
        guard let index = arguments.firstIndex(of: "-ReviewScreen"),
              arguments.index(after: index) < arguments.endIndex else {
            return .surprise
        }
        switch arguments[arguments.index(after: index)] {
        case "log": return .bar
        case "goals": return .settings
        case "discover": return .discover
        case "favorites": return .favorites
        default: return .surprise
        }
    }
}
