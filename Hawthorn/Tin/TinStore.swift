import Foundation

/// In-memory fold the UI reads. The file is a projection written by `TinLog`.
@MainActor
final class TinStore {
    private(set) var projection: TinProjection
    private let log: TinLog
    private let calendar: Calendar
    private let now: () -> Date

    init(log: TinLog, calendar: Calendar = .current, now: @escaping @Sendable () -> Date = { Date() }) {
        self.log = log
        self.calendar = calendar
        self.now = now
        self.projection = .empty
    }

    func load() async {
        let loaded = await log.load()
        if Task.isCancelled { return }
        projection = loaded
    }

    func flushForScenePhase() async {
        await log.flush()
    }

    func resetAllData() async throws {
        try await log.resetAllData()
        projection = .empty
    }

    @discardableResult
    func stow(bottleID: String) async throws -> TinProjection {
        guard !projection.stowed.contains(bottleID) else { throw TinRefusal.alreadyStowed }
        return try await commit(kind: .stow, bottleID: bottleID, recipeID: nil)
    }

    @discardableResult
    func tag(bottleID: String) async throws -> TinProjection {
        switch TinFold.tag(bottleID: bottleID, tin: projection.tin, stowed: Set(projection.stowed)) {
        case .failure(let reason):
            throw reason
        case .success:
            return try await commit(kind: .tag, bottleID: bottleID, recipeID: nil)
        }
    }

    @discardableResult
    func peel() async throws -> TinProjection {
        switch TinFold.peel(tin: projection.tin) {
        case .failure(let reason):
            throw reason
        case .success:
            return try await commit(kind: .peel, bottleID: nil, recipeID: nil)
        }
    }

    /// Samples one owned PrimaryTriple. A miss writes SplitMark and leaves the slots seated.
    @discardableResult
    func shake(recipes: [Recipe]) async throws -> TinProjection {
        guard case .success = TinFold.shake(tin: projection.tin) else {
            throw TinRefusal.shakeNeedsThree
        }
        let owned = Set(projection.stowed)
        if let recipe = TinFold.sample(in: recipes, tagged: projection.tin.taggedBottleIDs, owned: owned) {
            return try await commit(kind: .shake, bottleID: nil, recipeID: recipe.id)
        }
        return try await commit(kind: .split, bottleID: nil, recipeID: nil)
    }

    @discardableResult
    func clear() async throws -> TinProjection {
        guard case .success = TinFold.clear(tin: projection.tin) else {
            throw TinRefusal.clearNeedsShaken
        }
        return try await commit(kind: .clear, bottleID: nil, recipeID: nil)
    }

    @discardableResult
    func pin(recipeID: String) async throws -> TinProjection {
        guard projection.shakeMarks.contains(where: { $0.recipeID == recipeID }) else {
            throw TinRefusal.pinNeedsShake
        }
        return try await commit(kind: .pin, bottleID: nil, recipeID: recipeID)
    }

    @discardableResult
    func unpin(recipeID: String) async throws -> TinProjection {
        guard projection.pins.contains(recipeID) else { throw TinRefusal.notPinned }
        return try await commit(kind: .unpin, bottleID: nil, recipeID: recipeID)
    }

    /// Simulator only, once, behind `hwt.demo.v1`. Stows a bar and pre-tags two of a known triple.
    func applyDemoSeedIfNeeded(defaults: UserDefaults, isSimulator: Bool) async throws {
        guard DemoSeed.shouldApply(isSimulator: isSimulator, alreadyApplied: defaults.bool(forKey: DemoSeed.defaultsKey)) else {
            return
        }
        for command in DemoSeed.commands {
            switch command {
            case .stow(let id):
                try await stow(bottleID: id)
            case .tag(let id):
                try await tag(bottleID: id)
            }
        }
        defaults.set(true, forKey: DemoSeed.onboardingKey)
        defaults.set(true, forKey: DemoSeed.defaultsKey)
    }

    private func commit(kind: TinEvent.Kind, bottleID: String?, recipeID: String?) async throws -> TinProjection {
        let event = TinEvent(
            schemaVersion: TinEvent.currentSchema,
            seq: (projection.events.last?.seq ?? 0) + 1,
            daykey: DayKey.make(from: now(), calendar: calendar),
            kind: kind,
            bottleID: bottleID,
            recipeID: recipeID
        )
        guard let next = TinReducer.apply(event, to: projection) else {
            throw TinLogError.malformed
        }
        let previous = projection
        projection = next
        do {
            try await log.commit(events: next.events)
        } catch {
            projection = previous
            throw error
        }
        return projection
    }
}

enum DemoSeed {
    static let defaultsKey = "hwt.demo.v1"
    static let onboardingKey = "hwt.onboarding.complete"
    static let knownTriple = ["gin", "sweet-vermouth", "campari"]

    enum Command: Equatable, Sendable {
        case stow(String)
        case tag(String)
    }

    static func shouldApply(isSimulator: Bool, alreadyApplied: Bool) -> Bool {
        isSimulator && !alreadyApplied
    }

    /// Several stows, then two tags from the Negroni triple so the next Tag and Shake can land.
    static let commands: [Command] = [
        .stow("gin"),
        .stow("sweet-vermouth"),
        .stow("campari"),
        .stow("bourbon"),
        .stow("lemon"),
        .stow("simple"),
        .tag("gin"),
        .tag("sweet-vermouth")
    ]
}
