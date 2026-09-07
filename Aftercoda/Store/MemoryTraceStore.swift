import Foundation

/// Store. In-memory TraceStoring for previews and presentation tests. No FileManager.
actor MemoryTraceStore: TraceStoring {
    private var daysByKey: [Int64: DayTrace]
    private var drumSettings: DrumSettings
    private var warning: DrumLoadWarning?

    init(
        days: [DayTrace] = [],
        settings: DrumSettings = .factory,
        warning: DrumLoadWarning? = nil
    ) {
        self.daysByKey = Dictionary(uniqueKeysWithValues: days.map { ($0.dayKey, $0) })
        self.drumSettings = settings
        self.warning = warning
    }

    func load() async -> (days: [DayTrace], warning: DrumLoadWarning?) {
        let days = daysByKey.values.sorted { $0.dayKey < $1.dayKey }
        return (days, warning)
    }

    func day(forKey dayKey: Int64) async -> DayTrace? {
        daysByKey[dayKey]
    }

    func save(_ day: DayTrace) async throws {
        daysByKey[day.dayKey] = day
    }

    func note(_ day: DayTrace) async {
        daysByKey[day.dayKey] = day
    }

    func flush() async throws {}

    func resetAllData() async throws {
        daysByKey = [:]
        drumSettings = .factory
        warning = nil
    }

    func settings() async -> DrumSettings {
        drumSettings
    }

    func saveSettings(_ settings: DrumSettings) async throws {
        drumSettings = settings
    }

    func seedDemoIfNeeded() async throws {}
}
