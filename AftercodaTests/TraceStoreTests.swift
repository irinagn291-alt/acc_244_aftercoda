import XCTest
@testable import Aftercoda

final class TraceStoreTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "afc.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesStampAndBind() async throws {
        let store = makeStore()
        let origin = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
        let stations = MealPipeline.stations(from: "oats, tea", at: origin.addingTimeInterval(8 * 3600))
        var day = DayTrace.empty(on: origin, calendar: calendar)
        day = day.adding(stations: stations)
        let pulse = EpicenterStamp.make(region: .head, at: origin.addingTimeInterval(10 * 3600))
        day = day.adding(pulse)
        day = try WindowJoin.bind(stationID: stations[0].id, pulseID: pulse.id, on: day, lookbackHours: 6)
        try await store.save(day)
        try await store.saveSettings(DrumSettings.factory.retuning(.gut, hours: 2))

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.days.count, 1)
        let restored = try XCTUnwrap(loaded.days.first)
        XCTAssertEqual(restored.id, day.id)
        XCTAssertEqual(restored.dayKey, DayKey.milliseconds(for: origin, calendar: calendar))
        XCTAssertEqual(restored.stations.map(\.label), ["oats", "tea"])
        XCTAssertEqual(restored.pulses[0].region, .head)
        XCTAssertEqual(restored.pulses[0].boundStationIDs, [stations[0].id])
        let settings = await relaunched.settings()
        XCTAssertEqual(settings.hours(for: .gut), 2)
        XCTAssertEqual(settings.hours(for: .skin), 6)
    }

    func test_corruptFileFallsBackToBackup() async throws {
        let store = makeStore()
        let origin = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
        let day = DayTrace.empty(on: origin, calendar: calendar, id: DrumSeed.dayID)
        try await store.save(day)
        let url = directory.appendingPathComponent("\(day.dayKey).json")
        let backup = url.appendingPathExtension("backup")
        try FileManager.default.copyItem(at: url, to: backup)
        try Data("{not-json".utf8).write(to: url)

        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.days.first?.id, day.id)
    }

    func test_corruptFileWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("1.json")
        try Data("nope".utf8).write(to: url)
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.days.isEmpty)
    }

    func test_resetAllData_deletesDayFolder() async throws {
        let store = makeStore()
        let origin = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
        try await store.save(DayTrace.empty(on: origin, calendar: calendar))
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.days.isEmpty)
        let leftovers = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
        let settings = await store.settings()
        XCTAssertEqual(settings, .factory)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let origin = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
        let day = DayTrace.empty(on: origin, calendar: calendar)
        let data = try DayCodec.encode(day)
        let decoded = try DayCodec.decode(data)
        XCTAssertEqual(decoded.id, day.id)
        XCTAssertEqual(decoded.dayKey, day.dayKey)

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try DayCodec.decode(future)) { error in
            XCTAssertEqual(error as? DayCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try DayCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? DayCodec.Failure, .corrupt)
        }
        XCTAssertThrowsError(try SettingsCodec.decode(Data("{\"schemaVersion\":7}".utf8))) { error in
            XCTAssertEqual(error as? SettingsCodec.Failure, .unsupportedSchema(7))
        }
    }

    func test_noteThenFlushPersists() async throws {
        let store = makeStore()
        let origin = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
        let day = DayTrace.empty(on: origin, calendar: calendar)
        await store.note(day)
        try await store.flush()
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.days.first?.id, day.id)
    }

    func test_dayKeyIsStartOfDayMilliseconds() {
        let origin = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
        let later = origin.addingTimeInterval(20 * 3600)
        XCTAssertEqual(DayKey.milliseconds(for: origin, calendar: calendar), DayKey.milliseconds(for: later, calendar: calendar))
        XCTAssertEqual(DayKey.milliseconds(for: origin, calendar: calendar), Int64((origin.timeIntervalSince1970 * 1000).rounded()))
    }

    func test_settingsClampLookbackOnRetune() {
        let settings = DrumSettings.factory.retuning(.skin, hours: 12).retuning(.gut, hours: -4)
        XCTAssertEqual(settings.hours(for: .skin), 6)
        XCTAssertEqual(settings.hours(for: .gut), 0)
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOneDayOnce() async throws {
        let origin = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
        let store = TraceStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0,
            calendar: calendar,
            now: { origin }
        )
        try await store.seedDemoIfNeeded()
        try await store.seedDemoIfNeeded()
        let loaded = await store.load()
        XCTAssertEqual(loaded.days.count, 1)
        let day = try XCTUnwrap(loaded.days.first)
        XCTAssertEqual(day.id, DrumSeed.dayID)
        XCTAssertEqual(day.stations.count, 4)
        XCTAssertEqual(day.pulses.count, 3)
        let report = WindowJoin.pairings(on: day, lookbacks: DrumSettings.factory.lookbackHours)
        XCTAssertEqual(Set(report.map(\.stationLabel)), Set(["oats", "tea"]))
        XCTAssertTrue(report.allSatisfy { $0.matched >= 2 })
        XCTAssertTrue(defaults.bool(forKey: PreferenceKey.demoSeed))
        XCTAssertTrue(defaults.bool(forKey: PreferenceKey.onboardingComplete))
        let url = directory.appendingPathComponent("\(day.dayKey).json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
    #endif

    private func makeStore() -> TraceStore {
        TraceStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0,
            calendar: calendar
        )
    }
}
