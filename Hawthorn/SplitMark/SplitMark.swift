import Foundation

/// A shake that missed every PrimaryTriple. Slots stay seated so one can be peeled.
struct SplitMark: Codable, Equatable, Identifiable, Sendable {
    let seq: Int
    let daykey: Int

    var id: Int { seq }
}
