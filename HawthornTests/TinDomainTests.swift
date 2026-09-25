import XCTest
@testable import Hawthorn

@MainActor
final class TinDomainTests: XCTestCase {
    private let negroni = Recipe(
        id: "negroni",
        name: "Negroni",
        method: "Stir.",
        primaryTriple: PrimaryTriple(bottleIDs: ["gin", "sweet-vermouth", "campari"])
    )
    private let manhattan = Recipe(
        id: "manhattan",
        name: "Manhattan",
        method: "Stir.",
        primaryTriple: PrimaryTriple(bottleIDs: ["rye", "sweet-vermouth", "orange-bitters"])
    )

    func testSurpriseFiltersRecipesByOwnedBottles() {
        let owned: Set<String> = ["gin", "sweet-vermouth", "campari", "bourbon"]
        let visible = TinFold.surprise(in: [negroni, manhattan], owned: owned)
        XCTAssertEqual(visible.map(\.id), ["negroni"])
        XCTAssertNil(TinFold.sample(in: [negroni, manhattan], tagged: ["rye", "sweet-vermouth", "orange-bitters"], owned: owned))
    }

    func testEmptyTinRefusesShakeAndIsBare() async throws {
        let store = try makeStore()
        await store.load()
        XCTAssertEqual(store.projection.tin, .bare)
        do {
            try await store.shake(recipes: [negroni])
            XCTFail("Shake on a bare tin should be refused")
        } catch TinRefusal.shakeNeedsThree {
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testTagThenShakeMatchesTripleWithoutEmptyingStock() async throws {
        let store = try makeStore()
        await store.load()
        for id in ["gin", "sweet-vermouth", "campari", "bourbon"] {
            try await store.stow(bottleID: id)
        }
        try await store.tag(bottleID: "campari")
        try await store.tag(bottleID: "gin")
        XCTAssertEqual(store.projection.tin.phase, .tagged)
        do {
            try await store.shake(recipes: [negroni])
            XCTFail("Two tags cannot shake")
        } catch TinRefusal.shakeNeedsThree {
        } catch {
            XCTFail("Unexpected error \(error)")
        }
        try await store.tag(bottleID: "sweet-vermouth")
        try await store.shake(recipes: [negroni])
        XCTAssertEqual(store.projection.tin.phase, .shaken)
        XCTAssertEqual(store.projection.tin.shakenRecipeID, "negroni")
        XCTAssertEqual(store.projection.stowed, ["gin", "sweet-vermouth", "campari", "bourbon"])
        XCTAssertEqual(store.projection.shakeMarks.count, 1)
    }

    func testMissWritesSplitAndKeepsSlotsPeelable() async throws {
        let store = try makeStore()
        await store.load()
        for id in ["gin", "bourbon", "lemon"] {
            try await store.stow(bottleID: id)
            try await store.tag(bottleID: id)
        }
        try await store.shake(recipes: [negroni])
        XCTAssertEqual(store.projection.tin.phase, .tagged)
        XCTAssertEqual(store.projection.tin.slots.count, 3)
        XCTAssertEqual(store.projection.splitMarks.count, 1)
        XCTAssertTrue(store.projection.shakeMarks.isEmpty)
        try await store.peel()
        XCTAssertEqual(store.projection.tin.slots.map(\.bottleID), ["gin", "bourbon"])
    }

    func testRefusalsForShakenTinDuplicateSeatAndClear() async throws {
        let store = try makeStore()
        await store.load()
        for id in ["gin", "sweet-vermouth", "campari"] {
            try await store.stow(bottleID: id)
            try await store.tag(bottleID: id)
        }
        do {
            try await store.tag(bottleID: "gin")
            XCTFail("A bottle cannot take two slots")
        } catch TinRefusal.alreadySeated {
        } catch {
            XCTFail("Unexpected error \(error)")
        }
        try await store.shake(recipes: [negroni])
        do {
            try await store.tag(bottleID: "gin")
            XCTFail("Tag on Shaken is refused")
        } catch TinRefusal.tagOnShaken {
        } catch {
            XCTFail("Unexpected error \(error)")
        }
        do {
            try await store.peel()
            XCTFail("Peel on Shaken is refused")
        } catch TinRefusal.peelOnShaken {
        } catch {
            XCTFail("Unexpected error \(error)")
        }
        try await store.clear()
        XCTAssertEqual(store.projection.tin, .bare)
        XCTAssertEqual(store.projection.stowed.count, 3)
        do {
            try await store.clear()
            XCTFail("Clear on Bare is refused")
        } catch TinRefusal.clearNeedsShaken {
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testFoldRoundTripAndBackupRecovery() async throws {
        let directory = try makeDirectory()
        let log = TinLog(directory: directory)
        let stamped = fixedDate
        let store = TinStore(log: log, calendar: fixedCalendar, now: { stamped })
        await store.load()
        try await store.stow(bottleID: "gin")
        try await store.stow(bottleID: "campari")
        let reloaded = TinStore(log: TinLog(directory: directory), calendar: fixedCalendar, now: { stamped })
        await reloaded.load()
        XCTAssertEqual(reloaded.projection.stowed, ["gin", "campari"])
        XCTAssertNil(reloaded.projection.recoveryNote)
        XCTAssertEqual(reloaded.projection.events.first?.daykey, 20260922)

        let eventsURL = directory.appendingPathComponent("events.jsonl")
        try Data("{\"schemaVersion\":1,\"seq\":1}\n".utf8).write(to: eventsURL, options: .atomic)
        let recovered = TinStore(log: TinLog(directory: directory))
        await recovered.load()
        XCTAssertEqual(recovered.projection.stowed, ["gin"])
        XCTAssertEqual(recovered.projection.recoveryNote, TinLog.corruptNote)

        try Data("{".utf8).write(to: directory.appendingPathComponent("events.jsonl.backup"), options: .atomic)
        let emptied = TinStore(log: TinLog(directory: directory))
        await emptied.load()
        XCTAssertEqual(emptied.projection.tin, .bare)
        XCTAssertEqual(emptied.projection.recoveryNote, TinLog.corruptNote)
        try await emptied.resetAllData()
        XCTAssertFalse(FileManager.default.fileExists(atPath: eventsURL.path))
    }

    func testPartialLastLineIsDropped() async throws {
        let directory = try makeDirectory()
        let log = TinLog(directory: directory)
        let raw = """
        {"bottleID":"gin","daykey":20260922,"kind":"stow","schemaVersion":1,"seq":1}
        {"bottleID":"cam
        """
        let parsed = await log.parseLog(raw)
        guard case .success(let events) = parsed else {
            XCTFail("Partial tail should be dropped")
            return
        }
        XCTAssertEqual(events.map(\.bottleID), ["gin"])
    }

    func testSnapshotReplaysOnlyTheTail() async throws {
        let directory = try makeDirectory()
        let log = TinLog(directory: directory)
        var events: [TinEvent] = []
        for index in 1...65 {
            events.append(TinEvent(
                schemaVersion: 1,
                seq: index,
                daykey: 20260922,
                kind: .stow,
                bottleID: "bottle-\(index)",
                recipeID: nil
            ))
        }
        try await log.commit(events: Array(events.prefix(64)))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("snapshot.json").path))
        try await log.commit(events: events)
        let store = TinStore(log: TinLog(directory: directory))
        await store.load()
        XCTAssertEqual(store.projection.stowed.count, 65)
        XCTAssertEqual(store.projection.stowed.last, "bottle-65")
        XCTAssertNil(store.projection.recoveryNote)
    }

    func testDemoSeedRunsOnceOnSimulatorOnly() async throws {
        let directory = try makeDirectory()
        let suite = "hwt-tests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not open a defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suite)
        let store = TinStore(log: TinLog(directory: directory))
        await store.load()
        try await store.applyDemoSeedIfNeeded(defaults: defaults, isSimulator: false)
        XCTAssertTrue(store.projection.stowed.isEmpty)
        XCTAssertFalse(defaults.bool(forKey: DemoSeed.defaultsKey))
        try await store.applyDemoSeedIfNeeded(defaults: defaults, isSimulator: true)
        XCTAssertEqual(store.projection.stowed.count, 6)
        XCTAssertEqual(store.projection.tin.slots.map(\.bottleID), ["gin", "sweet-vermouth"])
        XCTAssertTrue(defaults.bool(forKey: DemoSeed.onboardingKey))
        let before = store.projection.events.count
        try await store.applyDemoSeedIfNeeded(defaults: defaults, isSimulator: true)
        XCTAssertEqual(store.projection.events.count, before)
        defaults.removePersistentDomain(forName: suite)
    }

    func testCatalogDecodesVersionOneAndRejectsGarbage() {
        let json = """
        {"schemaVersion":1,"bottles":[{"id":"gin","name":"London Dry Gin"}],"recipes":[]}
        """
        guard let data = json.data(using: .utf8) else {
            XCTFail("UTF-8")
            return
        }
        guard case .success(let document) = RecipeCatalog.load(from: data) else {
            XCTFail("Catalog should decode")
            return
        }
        XCTAssertEqual(document.bottles.map(\.id), ["gin"])
        let broken = Data("{".utf8)
        guard case .failure(.malformed) = RecipeCatalog.load(from: broken) else {
            XCTFail("Malformed catalog is an error")
            return
        }
    }

    func testDayKeyUsesStartOfDay() {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 9
        parts.day = 22
        parts.hour = 23
        parts.minute = 30
        guard let date = fixedCalendar.date(from: parts) else {
            XCTFail("Date")
            return
        }
        XCTAssertEqual(DayKey.make(from: date, calendar: fixedCalendar), 20260922)
    }

    private var fixedCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }

    private var fixedDate: Date {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 9
        parts.day = 22
        parts.hour = 15
        return fixedCalendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }

    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("hwt-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeStore() throws -> TinStore {
        let stamped = fixedDate
        return TinStore(log: TinLog(directory: try makeDirectory()), calendar: fixedCalendar, now: { stamped })
    }
}
