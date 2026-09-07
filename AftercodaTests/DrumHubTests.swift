import XCTest
@testable import Aftercoda

final class DrumHubTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    override func setUpWithError() throws {
        suiteName = "afc.hub.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        suiteName = nil
        defaults = nil
    }

    @MainActor
    func test_stampBind_emptyPopulatedInvalid() async throws {
        let origin = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
        let hub = makeHub(now: origin)
        await hub.bootstrap()
        XCTAssertTrue(hub.isEmpty)
        XCTAssertTrue(hub.pairings.isEmpty)
        XCTAssertEqual(hub.exploded.progress, 0)

        hub.select(region: .head)
        hub.scrubHour = 10
        await hub.stampSelected()
        XCTAssertEqual(hub.day.pulses.count, 1)
        XCTAssertEqual(hub.day.pulses[0].region, .head)
        XCTAssertNotNil(hub.selectedPulse)

        hub.bindDraft = "oats, tea"
        hub.scrubHour = 8
        await hub.sewDraft()
        XCTAssertEqual(hub.day.stations.map(\.label), ["oats", "tea"])
        XCTAssertEqual(hub.day.pulses[0].boundStationIDs.count, 2)
        XCTAssertTrue(hub.pairings.isEmpty)

        hub.scrubHour = 13
        await hub.stampSelected()
        let oats = try XCTUnwrap(hub.day.stations.first { $0.label == "oats" })
        await hub.sew(stationID: oats.id)
        let report = hub.pairings
        XCTAssertEqual(report.count, 1)
        XCTAssertEqual(report[0].stationLabel, "oats")
        XCTAssertEqual(report[0].matched, 2)
        XCTAssertEqual(report[0].totalSymptoms, 2)
        XCTAssertEqual(report[0].score, 1, accuracy: 1e-9)

        let late = try XCTUnwrap(hub.day.stations.first { $0.label == "tea" })
        hub.selectedPulseID = hub.day.pulses[1].id
        hub.settings = hub.settings.retuning(.head, hours: 1)
        await hub.sew(stationID: late.id)
        XCTAssertEqual(hub.bindFailure, .outsideCoda)
    }

    @MainActor
    func test_lookbackRetuneClampsToSix() async {
        let hub = makeHub()
        await hub.bootstrap()
        hub.retune(.skin, hours: 12)
        XCTAssertEqual(hub.settings.hours(for: .skin), 6)
        hub.retune(.gut, hours: -2)
        XCTAssertEqual(hub.settings.hours(for: .gut), 0)
    }

    @MainActor
    func test_reviewLogOpensReportAfterOnboarding() async {
        let hub = makeHub(arguments: [ReviewHook.argument, "log"])
        await hub.bootstrap()
        XCTAssertTrue(hub.showsOnboarding)
        XCTAssertNil(hub.sheet)
        await hub.completeOnboarding()
        XCTAssertFalse(hub.showsOnboarding)
        XCTAssertEqual(hub.sheet, .report)
    }

    @MainActor
    func test_reviewGoalsOpensSettingsAfterOnboarding() async {
        let hub = makeHub(arguments: [ReviewHook.argument, "goals"])
        await hub.bootstrap()
        await hub.completeOnboarding()
        XCTAssertEqual(hub.sheet, .settings)
    }

    @MainActor
    func test_reviewTodayStaysOnTimeline() async {
        let hub = makeHub(arguments: [ReviewHook.argument, "today"])
        await hub.bootstrap()
        await hub.completeOnboarding()
        XCTAssertNil(hub.sheet)
    }

    @MainActor
    func test_reviewHookFiresOnce() async {
        let hub = makeHub(arguments: [ReviewHook.argument, "log"])
        await hub.bootstrap()
        await hub.completeOnboarding()
        XCTAssertEqual(hub.sheet, .report)
        hub.sheet = nil
        hub.applyReviewHookOnce()
        XCTAssertNil(hub.sheet)
    }

    @MainActor
    func test_explodedBindingIsHomeMeasure() async throws {
        let origin = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
        let hub = makeHub(now: origin)
        await hub.bootstrap()
        hub.select(region: .gut)
        hub.scrubHour = 14
        await hub.stampSelected()
        hub.bindDraft = "rice"
        hub.scrubHour = 12
        await hub.sewDraft()
        XCTAssertEqual(hub.exploded.completedStages, BindStage.stationSewn.rawValue)
        XCTAssertEqual(hub.exploded.sewnSections, 1)
        XCTAssertGreaterThan(hub.exploded.progress, 0)
    }

    @MainActor
    func test_screensConstructWithNoArguments() {
        XCTAssertFalse(TimelineView().hub.isEmpty)
        XCTAssertFalse(ReportView().pairings.isEmpty)
        XCTAssertEqual(SettingsView().hub.settings.hours(for: .head), 6)
        XCTAssertEqual(BodyMapView().pulses.count, 3)
        XCTAssertEqual(RegionCodaView().lookbacks[.gut], 3)
    }

    @MainActor
    private func makeHub(
        now: Date? = nil,
        arguments: [String] = []
    ) -> DrumHub {
        let stamp = now ?? calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
        return DrumHub(
            store: MemoryTraceStore(),
            defaults: defaults,
            calendar: calendar,
            now: { stamp },
            arguments: arguments
        )
    }
}
