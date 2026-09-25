import Foundation

/// A successful shake. Pour counts are derived by grouping these marks on daykey.
struct ShakeMark: Codable, Equatable, Identifiable, Sendable {
    let seq: Int
    let daykey: Int
    let recipeID: String

    init(seq: Int, daykey: Int, recipeID: String) {
        self.seq = seq
        self.daykey = daykey
        self.recipeID = recipeID
    }

    var id: Int { seq }
}
