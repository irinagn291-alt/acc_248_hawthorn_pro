import Foundation
import Observation
import UIKit

/// Presentation seam over TinLog. Screens fold the tin. They never append events themselves.
@MainActor
@Observable
final class BarSession {
    var projection: TinProjection = .empty
    var bottles: [Bottle] = []
    var recipes: [Recipe] = []
    var catalogError: String?
    var actionError: String?
    var isLoading = true
    var showSpinner = false
    var isShaking = false
    var showOnboarding: Bool
    var desk: ReviewLaunch.Desk = .surprise
    var didReadLaunch = false

    let store: TinStore
    private let defaults: UserDefaults

    init(store: TinStore? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let store {
            self.store = store
        } else {
            let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            let directory = root.appendingPathComponent("Hawthorn", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            self.store = TinStore(log: TinLog(directory: directory))
        }
        showOnboarding = !defaults.bool(forKey: DemoSeed.onboardingKey)
    }

    func prepare() async {
        let spinner = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled, isLoading else { return }
            showSpinner = true
        }
        await store.load()
        if Task.isCancelled {
            spinner.cancel()
            return
        }
        #if targetEnvironment(simulator)
        try? await store.applyDemoSeedIfNeeded(defaults: defaults, isSimulator: true)
        #endif
        if defaults.bool(forKey: DemoSeed.onboardingKey) {
            showOnboarding = false
        }
        projection = store.projection
        loadCatalog()
        spinner.cancel()
        isLoading = false
        showSpinner = false
        if !showOnboarding {
            readLaunchOnce()
        }
    }

    func finishOnboarding() {
        defaults.set(true, forKey: DemoSeed.onboardingKey)
        showOnboarding = false
        readLaunchOnce()
    }

    func bottle(id: String) -> Bottle? {
        bottles.first { $0.id == id }
    }

    func name(for id: String) -> String {
        bottle(id: id)?.name ?? id
    }

    var unseatedStowed: [Bottle] {
        let seated = projection.tin.taggedBottleIDs
        return projection.stowed.compactMap { id in
            guard !seated.contains(id) else { return nil }
            return bottle(id: id)
        }
    }

    /// The bottle the accent Tag seats next. Nil once Shake is legal or the tin is shaken.
    var nextTagBottle: Bottle? {
        guard projection.tin.phase != .shaken, projection.tin.slots.count < TinFold.capacity else { return nil }
        let seated = projection.tin.taggedBottleIDs
        let open = unseatedStowed
        if let completing = open.first(where: { bottle in
            let proposed = seated.union([bottle.id])
            return recipes.contains { recipe in
                recipe.primaryTriple.isWellFormed && proposed.isSubset(of: recipe.primaryTriple.bottleSet)
            }
        }) {
            return completing
        }
        return open.first
    }

    var catalogNotStowed: [Bottle] {
        let owned = Set(projection.stowed)
        return bottles.filter { !owned.contains($0.id) }
    }

    var shakeEnabled: Bool {
        if case .success = TinFold.shake(tin: projection.tin) { return true }
        return false
    }

    var nextLine: String {
        switch projection.tin.phase {
        case .bare:
            return "Tag a bottle from the tray. Three tags, then shake."
        case .tagged:
            let open = TinFold.capacity - projection.tin.slots.count
            if open == 0 {
                return "Shake this trio. A miss stays on the tin so you can peel one slot."
            }
            return "Tag \(StudioMeasure.count(open)) more. Then shake the tin."
        case .shaken:
            return "Clear the tin when you want a fresh triple."
        }
    }

    func tag(_ id: String) async {
        actionError = nil
        do {
            projection = try await store.tag(bottleID: id)
        } catch {
            actionError = message(for: error)
        }
    }

    func peel() async {
        actionError = nil
        do {
            projection = try await store.peel()
        } catch {
            actionError = message(for: error)
        }
    }

    func shake() async {
        actionError = nil
        isShaking = true
        let before = projection.shakeMarks.count
        do {
            projection = try await store.shake(recipes: recipes)
            if projection.shakeMarks.count > before {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } catch {
            actionError = message(for: error)
        }
        isShaking = false
    }

    func clear() async {
        actionError = nil
        do {
            projection = try await store.clear()
        } catch {
            actionError = message(for: error)
        }
    }

    func stow(_ id: String) async {
        actionError = nil
        do {
            projection = try await store.stow(bottleID: id)
        } catch {
            actionError = message(for: error)
        }
    }

    func pin(_ id: String) async {
        actionError = nil
        do {
            projection = try await store.pin(recipeID: id)
        } catch {
            actionError = message(for: error)
        }
    }

    func unpin(_ id: String) async {
        actionError = nil
        do {
            projection = try await store.unpin(recipeID: id)
        } catch {
            actionError = message(for: error)
        }
    }

    func resetAllData() async {
        actionError = nil
        do {
            try await store.resetAllData()
            projection = store.projection
        } catch {
            actionError = "Reset failed. The tin log is still on this device."
        }
    }

    func recipe(id: String) -> Recipe? {
        recipes.first { $0.id == id }
    }

    private func readLaunchOnce() {
        guard !didReadLaunch else { return }
        didReadLaunch = true
        desk = ReviewLaunch.deskFromLaunch()
    }

    private func loadCatalog() {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            catalogError = "The bundled catalog is missing. Hawthorn cannot match a triple until it is restored."
            return
        }
        switch RecipeCatalog.load(from: data) {
        case .success(let document):
            bottles = document.bottles
            recipes = document.recipes
            catalogError = nil
        case .failure:
            catalogError = "The bundled catalog could not be read. Your bar is unchanged."
        }
    }

    private func message(for error: Error) -> String {
        guard let refusal = error as? TinRefusal else {
            return "That step did not land. Try it once more."
        }
        switch refusal {
        case .notStowed:
            return "Stow that bottle on the bar before you tag it."
        case .alreadySeated:
            return "That bottle is already in a slot."
        case .tinFull:
            return "The tin holds three. Peel a slot to tag another."
        case .tagOnShaken:
            return "Clear the shaken tin before you tag again."
        case .shakeNeedsThree:
            return "Shake waits for three tagged bottles."
        case .peelNeedsSlot:
            return "There is no slot to peel."
        case .peelOnShaken:
            return "Clear a shaken tin. Peel is for a tagged tin."
        case .clearNeedsShaken:
            return "Clear is ready after a shake lands."
        case .alreadyStowed:
            return "That bottle is already on the bar."
        case .pinNeedsShake:
            return "Pin a recipe after a shake writes it."
        case .notPinned:
            return "That recipe is not pinned."
        }
    }
}
