import Foundation

/// A catalog bottle the bar can stow. Identity is the stable id, never a row index.
struct Bottle: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
}

/// A bottle sitting in inventory. Tag and Shake never remove it.
struct Stowed: Equatable, Identifiable, Sendable {
    let bottle: Bottle

    var id: String { bottle.id }
}
