import Foundation

/// YYYYMMDD taken from the start of the local day. Stored on the event, never recomputed later.
enum DayKey {
    static func make(from date: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }
}

/// One append-only line. Lines are never edited in place.
struct TinEvent: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var seq: Int
    var daykey: Int
    var kind: Kind
    var bottleID: String?
    var recipeID: String?

    enum Kind: String, Codable, Sendable {
        case stow, tag, peel, shake, split, clear, pin, unpin
    }

    static let currentSchema = 1
}

/// Folded memory written every 64 events so launch replays only the tail.
struct TinSnapshot: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var throughSeq: Int
    var stowed: [String]
    var tin: Tin
    var pins: [String]
    var tagMarks: [TagMark]
    var shakeMarks: [ShakeMark]
    var splitMarks: [SplitMark]

    static let currentSchema = 1
}

struct TinProjection: Equatable, Sendable {
    var stowed: [String]
    var tin: Tin
    var pins: [String]
    var tagMarks: [TagMark]
    var shakeMarks: [ShakeMark]
    var splitMarks: [SplitMark]
    var events: [TinEvent]
    var recoveryNote: String?

    static let empty = TinProjection(
        stowed: [],
        tin: .bare,
        pins: [],
        tagMarks: [],
        shakeMarks: [],
        splitMarks: [],
        events: [],
        recoveryNote: nil
    )
}

enum TinLogError: Equatable, Error, Sendable {
    case malformed
    case unsupportedSchema
    case cancelled
}

/// Disk seam. All reads and writes run on this actor, off the main thread.
actor TinLog {
    static let snapshotStride = 64
    static let corruptNote = "The tin log could not be read. Hawthorn opened an empty bar."

    private let directory: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    var eventsURL: URL { directory.appendingPathComponent("events.jsonl") }
    var backupURL: URL { directory.appendingPathComponent("events.jsonl.backup") }
    var snapshotURL: URL { directory.appendingPathComponent("snapshot.json") }

    func load() async -> TinProjection {
        if Task.isCancelled { return .empty }
        switch readText(at: eventsURL) {
        case .success(let text):
            switch parseLog(text) {
            case .success(let events):
                if Task.isCancelled { return .empty }
                if let projected = project(events: events, note: nil) {
                    return projected
                }
                return recoveredFromBackup()
            case .failure:
                return recoveredFromBackup()
            }
        case .failure:
            return recoveredFromBackup()
        }
    }

    /// Rewrites the log atomically and refreshes the backup from the previous good file.
    func commit(events: [TinEvent]) async throws {
        try Task.checkCancellation()
        try ensureDirectory()
        let body = try encodeLog(events)
        let previous = eventsURL
        if fileManager.fileExists(atPath: previous.path) {
            try replaceCopy(from: previous, to: backupURL)
        }
        let temp = directory.appendingPathComponent("events-\(UUID().uuidString).jsonl.tmp")
        try body.write(to: temp, options: .atomic)
        if fileManager.fileExists(atPath: eventsURL.path) {
            _ = try fileManager.replaceItemAt(eventsURL, withItemAt: temp)
        } else {
            try fileManager.moveItem(at: temp, to: eventsURL)
        }
        if events.count > 0, events.count.isMultiple(of: Self.snapshotStride) {
            try writeSnapshot(for: events)
        }
    }

    func flush() async {
        // Marks already rewrite the file before they return. Scene phase calls this so a
        // caller can wait until the last commit has finished on this actor.
    }

    func resetAllData() async throws {
        try Task.checkCancellation()
        for url in [eventsURL, backupURL, snapshotURL] {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }

    func parseLog(_ text: String?) -> Result<[TinEvent], TinLogError> {
        guard let text else { return .success([]) }
        if text.isEmpty { return .success([]) }
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if lines.last?.isEmpty == true { lines.removeLast() }
        guard !lines.isEmpty else { return .success([]) }
        var events: [TinEvent] = []
        events.reserveCapacity(lines.count)
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                return .failure(.malformed)
            }
            switch decodeEvent(line) {
            case .success(let event):
                events.append(event)
            case .failure(let error):
                let isLast = index == lines.count - 1
                if isLast, error == .malformed, !isCompleteJSON(line) {
                    break
                }
                return .failure(error)
            }
        }
        return .success(events)
    }

    private func project(events: [TinEvent], note: String?) -> TinProjection? {
        let snapshot = readSnapshot()
        let base: TinProjection
        let tail: ArraySlice<TinEvent>
        if let snapshot, snapshot.throughSeq >= 0, events.allSatisfy({ $0.seq > 0 }) {
            let prior = events.filter { $0.seq <= snapshot.throughSeq }
            if prior.count == snapshot.throughSeq, prior.last?.seq == snapshot.throughSeq || snapshot.throughSeq == 0 {
                base = TinProjection(
                    stowed: snapshot.stowed,
                    tin: snapshot.tin,
                    pins: snapshot.pins,
                    tagMarks: snapshot.tagMarks,
                    shakeMarks: snapshot.shakeMarks,
                    splitMarks: snapshot.splitMarks,
                    events: Array(events),
                    recoveryNote: note
                )
                tail = events.filter { $0.seq > snapshot.throughSeq }[...]
                var folded = base
                folded.events = Array(prior)
                if let replayed = apply(tail, onto: folded) {
                    var result = replayed
                    result.events = events
                    result.recoveryNote = note
                    return result
                }
            }
        }
        guard let folded = apply(events[...], onto: .empty) else {
            return nil
        }
        var result = folded
        result.events = events
        result.recoveryNote = note
        return result
    }

    private func apply(_ events: ArraySlice<TinEvent>, onto start: TinProjection) -> TinProjection? {
        var state = start
        for event in events {
            guard event.schemaVersion == TinEvent.currentSchema else { return nil }
            guard let next = TinReducer.apply(event, to: state) else { return nil }
            state = next
        }
        return state
    }

    private func writeSnapshot(for events: [TinEvent]) throws {
        guard let folded = apply(events[...], onto: .empty) else { return }
        let snapshot = TinSnapshot(
            schemaVersion: TinSnapshot.currentSchema,
            throughSeq: events.last?.seq ?? 0,
            stowed: folded.stowed,
            tin: folded.tin,
            pins: folded.pins,
            tagMarks: folded.tagMarks,
            shakeMarks: folded.shakeMarks,
            splitMarks: folded.splitMarks
        )
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: .atomic)
    }

    private func readSnapshot() -> TinSnapshot? {
        guard let data = try? Data(contentsOf: snapshotURL) else { return nil }
        let envelope: SchemaEnvelope
        do {
            envelope = try decoder.decode(SchemaEnvelope.self, from: data)
        } catch {
            return nil
        }
        switch envelope.schemaVersion {
        case TinSnapshot.currentSchema:
            return try? decoder.decode(TinSnapshot.self, from: data)
        default:
            return nil
        }
    }

    private func isCompleteJSON(_ line: String) -> Bool {
        guard let data = line.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    private func decodeEvent(_ line: String) -> Result<TinEvent, TinLogError> {
        guard let data = line.data(using: .utf8) else { return .failure(.malformed) }
        let envelope: SchemaEnvelope
        do {
            envelope = try decoder.decode(SchemaEnvelope.self, from: data)
        } catch {
            return .failure(.malformed)
        }
        switch envelope.schemaVersion {
        case TinEvent.currentSchema:
            do {
                return .success(try decoder.decode(TinEvent.self, from: data))
            } catch {
                return .failure(.malformed)
            }
        default:
            return .failure(.unsupportedSchema)
        }
    }

    private func encodeLog(_ events: [TinEvent]) throws -> Data {
        var lines: [String] = []
        lines.reserveCapacity(events.count)
        for event in events {
            let data = try encoder.encode(event)
            guard let line = String(data: data, encoding: .utf8) else {
                throw TinLogError.malformed
            }
            lines.append(line)
        }
        let text = lines.joined(separator: "\n") + (lines.isEmpty ? "" : "\n")
        guard let data = text.data(using: .utf8) else { throw TinLogError.malformed }
        return data
    }

    private func ensureDirectory() throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func replaceCopy(from source: URL, to destination: URL) throws {
        let temp = directory.appendingPathComponent("backup-\(UUID().uuidString).tmp")
        if fileManager.fileExists(atPath: temp.path) {
            try fileManager.removeItem(at: temp)
        }
        try fileManager.copyItem(at: source, to: temp)
        if fileManager.fileExists(atPath: destination.path) {
            _ = try fileManager.replaceItemAt(destination, withItemAt: temp)
        } else {
            try fileManager.moveItem(at: temp, to: destination)
        }
    }

    private func recoveredFromBackup() -> TinProjection {
        if Task.isCancelled { return .empty }
        let backup: String?
        switch readText(at: backupURL) {
        case .success(let text):
            backup = text
        case .failure:
            var empty = TinProjection.empty
            empty.recoveryNote = Self.corruptNote
            return empty
        }
        switch parseLog(backup) {
        case .success(let events):
            if let projected = project(events: events, note: Self.corruptNote) {
                return projected
            }
            var empty = TinProjection.empty
            empty.recoveryNote = Self.corruptNote
            return empty
        case .failure:
            var empty = TinProjection.empty
            empty.recoveryNote = Self.corruptNote
            return empty
        }
    }

    /// Missing file is an empty log. A present file that cannot be decoded is a failure.
    private func readText(at url: URL) -> Result<String?, TinLogError> {
        if !fileManager.fileExists(atPath: url.path) {
            return .success(nil)
        }
        guard let data = try? Data(contentsOf: url) else {
            return .failure(.malformed)
        }
        guard let text = String(data: data, encoding: .utf8) else {
            return .failure(.malformed)
        }
        return .success(text)
    }

    private struct SchemaEnvelope: Decodable {
        let schemaVersion: Int
    }
}

/// Applies one committed event. Returns nil when the line would break the fold.
enum TinReducer {
    static func apply(_ event: TinEvent, to state: TinProjection) -> TinProjection? {
        if let last = state.events.last, event.seq != last.seq + 1 { return nil }
        if state.events.isEmpty, event.seq != 1 { return nil }
        var next = state
        switch event.kind {
        case .stow:
            guard let bottleID = event.bottleID, !next.stowed.contains(bottleID) else { return nil }
            next.stowed.append(bottleID)
        case .tag:
            guard let bottleID = event.bottleID else { return nil }
            guard case .success = TinFold.tag(bottleID: bottleID, tin: next.tin, stowed: Set(next.stowed)) else {
                return nil
            }
            next.tin.slots.append(Slot(seq: event.seq, bottleID: bottleID))
            next.tin.phase = .tagged
            next.tin.shakenRecipeID = nil
            next.tagMarks.append(TagMark(seq: event.seq, daykey: event.daykey, bottleID: bottleID))
        case .peel:
            guard case .success = TinFold.peel(tin: next.tin) else { return nil }
            next.tin.slots.removeLast()
            next.tin.shakenRecipeID = nil
            next.tin.phase = next.tin.slots.isEmpty ? .bare : .tagged
        case .shake:
            guard case .success = TinFold.shake(tin: next.tin) else { return nil }
            guard let recipeID = event.recipeID else { return nil }
            next.tin.phase = .shaken
            next.tin.shakenRecipeID = recipeID
            next.shakeMarks.append(ShakeMark(seq: event.seq, daykey: event.daykey, recipeID: recipeID))
        case .split:
            guard case .success = TinFold.shake(tin: next.tin) else { return nil }
            next.tin.phase = .tagged
            next.tin.shakenRecipeID = nil
            next.splitMarks.append(SplitMark(seq: event.seq, daykey: event.daykey))
        case .clear:
            guard case .success = TinFold.clear(tin: next.tin) else { return nil }
            next.tin = .bare
        case .pin:
            guard let recipeID = event.recipeID else { return nil }
            guard next.shakeMarks.contains(where: { $0.recipeID == recipeID }) else { return nil }
            if !next.pins.contains(recipeID) {
                next.pins.append(recipeID)
            }
        case .unpin:
            guard let recipeID = event.recipeID, next.pins.contains(recipeID) else { return nil }
            next.pins.removeAll { $0 == recipeID }
        }
        next.events.append(event)
        return next
    }
}
