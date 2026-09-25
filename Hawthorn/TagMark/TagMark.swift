import Foundation

/// Record that a stowed bottle was seated. The tin fold does not consume stock.
struct TagMark: Codable, Equatable, Identifiable, Sendable {
    let seq: Int
    let daykey: Int
    let bottleID: String

    var id: Int { seq }
}
