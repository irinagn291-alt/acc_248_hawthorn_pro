import Foundation

/// Three bottle ids, compared as a set. Order on the tin does not matter.
struct PrimaryTriple: Codable, Equatable, Sendable {
    let bottleIDs: [String]

    var bottleSet: Set<String> { Set(bottleIDs) }

    var isWellFormed: Bool {
        bottleIDs.count == 3 && bottleSet.count == 3
    }
}

/// A bundled cocktail. The triple is the only match key Shake uses.
struct Recipe: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let method: String
    let primaryTriple: PrimaryTriple
}

/// How a catalog triple sits against bottles the bar actually owns.
struct TripleUnlock: Equatable, Identifiable, Sendable {
    let recipe: Recipe
    let ownedCount: Int

    var id: String { recipe.id }
    var isFull: Bool { ownedCount == 3 }
}

enum TinRefusal: Equatable, Error, Sendable {
    case notStowed
    case alreadySeated
    case tinFull
    case tagOnShaken
    case shakeNeedsThree
    case peelNeedsSlot
    case peelOnShaken
    case clearNeedsShaken
    case alreadyStowed
    case pinNeedsShake
    case notPinned
}

/// Closed fold of the three-slot tin. Views call this, never the log.
enum TinFold {
    static let capacity = 3

    static func tag(bottleID: String, tin: Tin, stowed: Set<String>) -> Result<Tin, TinRefusal> {
        if tin.phase == .shaken { return .failure(.tagOnShaken) }
        if !stowed.contains(bottleID) { return .failure(.notStowed) }
        if tin.slots.contains(where: { $0.bottleID == bottleID }) { return .failure(.alreadySeated) }
        if tin.slots.count >= capacity { return .failure(.tinFull) }
        return .success(tin)
    }

    static func shake(tin: Tin) -> Result<Void, TinRefusal> {
        if tin.phase == .bare || tin.slots.count < capacity { return .failure(.shakeNeedsThree) }
        if tin.phase == .shaken { return .failure(.shakeNeedsThree) }
        return .success(())
    }

    static func peel(tin: Tin) -> Result<Tin, TinRefusal> {
        if tin.phase == .shaken { return .failure(.peelOnShaken) }
        if tin.slots.isEmpty { return .failure(.peelNeedsSlot) }
        return .success(tin)
    }

    static func clear(tin: Tin) -> Result<Void, TinRefusal> {
        if tin.phase != .shaken { return .failure(.clearNeedsShaken) }
        return .success(())
    }

    /// Surprise only offers recipes whose bottles are all owned. A catalog roll is not a match.
    static func surprise(in recipes: [Recipe], owned: Set<String>) -> [Recipe] {
        recipes.filter { recipe in
            recipe.primaryTriple.isWellFormed && recipe.primaryTriple.bottleSet.isSubset(of: owned)
        }
    }

    /// Exact set match against owned stock. Lowest recipe id wins when several share a triple.
    static func sample(in recipes: [Recipe], tagged: Set<String>, owned: Set<String>) -> Recipe? {
        guard tagged.count == capacity, tagged.isSubset(of: owned) else { return nil }
        return recipes
            .filter { $0.primaryTriple.isWellFormed && $0.primaryTriple.bottleSet == tagged }
            .sorted { $0.id < $1.id }
            .first
    }

    static func unlocks(in recipes: [Recipe], owned: Set<String>) -> [TripleUnlock] {
        recipes.compactMap { recipe in
            guard recipe.primaryTriple.isWellFormed else { return nil }
            let ownedCount = recipe.primaryTriple.bottleSet.intersection(owned).count
            return TripleUnlock(recipe: recipe, ownedCount: ownedCount)
        }
    }
}

/// In-memory tin. Empty slots are Bare.
struct Tin: Codable, Equatable, Sendable {
    var phase: TinPhase
    var slots: [Slot]
    var shakenRecipeID: String?

    static let bare = Tin(phase: .bare, slots: [], shakenRecipeID: nil)

    var taggedBottleIDs: Set<String> {
        Set(slots.map(\.bottleID))
    }
}

enum TinPhase: String, Codable, Equatable, Sendable {
    case bare
    case tagged
    case shaken
}
