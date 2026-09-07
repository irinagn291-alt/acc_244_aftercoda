import Foundation

/// Store. Preference keys. Demo seed is Simulator-only and versioned.
enum PreferenceKey {
    static let demoSeed = "afc.demo.v1"
    static let onboardingComplete = "afc.onboarding.complete"
}

/// Store. Recoverable load outcome. Never crash on a corrupt day file.
enum DrumLoadWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Store. The only seam views may talk to. FileManager stays inside the actor.
protocol TraceStoring: Sendable {
    func load() async -> (days: [DayTrace], warning: DrumLoadWarning?)
    func day(forKey dayKey: Int64) async -> DayTrace?
    func save(_ day: DayTrace) async throws
    func note(_ day: DayTrace) async
    func flush() async throws
    func resetAllData() async throws
    func settings() async -> DrumSettings
    func saveSettings(_ settings: DrumSettings) async throws
    func seedDemoIfNeeded() async throws
}

/// Store. JSON per day under Application Support. In-memory days are the source of truth.
actor TraceStore: TraceStoring {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let writeDelayNanoseconds: UInt64
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    private var daysByKey: [Int64: DayTrace] = [:]
    private var pendingKeys: Set<Int64> = []
    private var writeTask: Task<Void, Never>?
    private var drumSettings: DrumSettings = .factory
    private(set) var warning: DrumLoadWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        writeDelayNanoseconds: UInt64 = 300_000_000,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.writeDelayNanoseconds = writeDelayNanoseconds
        self.calendar = calendar
        self.now = now
    }

    static func applicationSupportDirectory() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Aftercoda/Days", isDirectory: true)
    }

    var days: [DayTrace] {
        daysByKey.values.sorted { $0.dayKey < $1.dayKey }
    }

    func load() async -> (days: [DayTrace], warning: DrumLoadWarning?) {
        warning = nil
        daysByKey = [:]
        prepareDirectory()
        drumSettings = readSettings() ?? .factory
        let urls = dayURLs()
        if urls.isEmpty {
            return (days, warning)
        }
        var recovered = false
        var loadedAny = false
        for url in urls {
            if let day = decodeFile(url) {
                daysByKey[day.dayKey] = day
                loadedAny = true
                continue
            }
            if let day = decodeFile(backupURL(for: url)) {
                daysByKey[day.dayKey] = day
                recovered = true
                loadedAny = true
            }
        }
        if recovered {
            warning = .recoveredFromBackup
        } else if !loadedAny {
            warning = .startedEmpty
        }
        return (days, warning)
    }

    func day(forKey dayKey: Int64) async -> DayTrace? {
        daysByKey[dayKey]
    }

    func save(_ day: DayTrace) async throws {
        daysByKey[day.dayKey] = day
        try persist(day)
        pendingKeys.remove(day.dayKey)
    }

    func note(_ day: DayTrace) {
        daysByKey[day.dayKey] = day
        pendingKeys.insert(day.dayKey)
        scheduleFlush()
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        try persistPending()
        try persistSettings(drumSettings)
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        pendingKeys = []
        daysByKey = [:]
        drumSettings = .factory
        warning = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: PreferenceKey.demoSeed)
        defaults.removeObject(forKey: PreferenceKey.onboardingComplete)
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
        prepareDirectory()
    }

    func settings() async -> DrumSettings {
        drumSettings
    }

    func saveSettings(_ settings: DrumSettings) async throws {
        drumSettings = settings
        try persistSettings(settings)
    }

    func seedDemoIfNeeded() async throws {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        guard defaults.object(forKey: PreferenceKey.demoSeed) == nil else { return }
        let seeded = DrumSeed.day(on: now(), calendar: calendar)
        daysByKey[seeded.dayKey] = seeded
        try persist(seeded)
        defaults.set(true, forKey: PreferenceKey.demoSeed)
        defaults.set(true, forKey: PreferenceKey.onboardingComplete)
        #endif
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            try persistPending()
            lastWriteError = nil
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func persistPending() throws {
        let keys = pendingKeys
        pendingKeys = []
        for key in keys {
            if let day = daysByKey[key] {
                try persist(day)
            }
        }
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func persist(_ day: DayTrace) throws {
        prepareDirectory()
        let url = fileURL(for: day.dayKey)
        let data = try DayCodec.encode(day)
        let manager = FileManager.default
        if manager.fileExists(atPath: url.path) {
            let backup = backupURL(for: url)
            try? manager.removeItem(at: backup)
            try? manager.copyItem(at: url, to: backup)
        }
        try data.write(to: url, options: .atomic)
    }

    private func persistSettings(_ settings: DrumSettings) throws {
        prepareDirectory()
        let url = settingsURL()
        let data = try SettingsCodec.encode(settings)
        let manager = FileManager.default
        if manager.fileExists(atPath: url.path) {
            let backup = backupURL(for: url)
            try? manager.removeItem(at: backup)
            try? manager.copyItem(at: url, to: backup)
        }
        try data.write(to: url, options: .atomic)
    }

    private func readSettings() -> DrumSettings? {
        let url = settingsURL()
        if let data = try? Data(contentsOf: url), let settings = try? SettingsCodec.decode(data) {
            return settings
        }
        if let data = try? Data(contentsOf: backupURL(for: url)) {
            return try? SettingsCodec.decode(data)
        }
        return nil
    }

    private func decodeFile(_ url: URL) -> DayTrace? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? DayCodec.decode(data)
    }

    private func dayURLs() -> [URL] {
        let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        return (contents ?? []).filter { url in
            url.pathExtension == "json"
                && url.lastPathComponent != "settings.json"
                && !url.lastPathComponent.hasSuffix(".json.backup")
        }
    }

    private func fileURL(for dayKey: Int64) -> URL {
        directory.appendingPathComponent("\(dayKey).json")
    }

    private func settingsURL() -> URL {
        directory.appendingPathComponent("settings.json")
    }

    private func backupURL(for url: URL) -> URL {
        url.appendingPathExtension("backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareDirectory() {
        let manager = FileManager.default
        if !manager.fileExists(atPath: directory.path) {
            try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}
