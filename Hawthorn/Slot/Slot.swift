import Foundation

/// One seat on the tin. `seq` is the tag event that filled it, so lists keep a stable id.
struct Slot: Codable, Equatable, Identifiable, Sendable {
    let seq: Int
    let bottleID: String

    var id: Int { seq }
}
