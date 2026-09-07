import XCTest
@testable import Aftercoda

final class WindowJoinTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private var origin: Date {
        calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
    }

    func test_stampBind_emptyPopulatedInvalid() throws {
        let empty = DayTrace.empty(on: origin, calendar: calendar)
        XCTAssertTrue(empty.stations.isEmpty)
        XCTAssertTrue(empty.pulses.isEmpty)
        XCTAssertTrue(WindowJoin.pairings(on: empty, lookbacks: [:]).isEmpty)

        let stations = MealPipeline.stations(from: "oats, tea", at: origin.addingTimeInterval(8 * 3600))
        var day = empty.adding(stations: stations)
        let pulse = EpicenterStamp.make(region: .head, at: origin.addingTimeInterval(10 * 3600))
        day = day.adding(pulse)
        XCTAssertEqual(day.pulses.count, 1)
        XCTAssertEqual(day.stations.count, 2)

        let oats = try XCTUnwrap(day.stations.first)
        day = try WindowJoin.bind(stationID: oats.id, pulseID: pulse.id, on: day, lookbackHours: 6)
        XCTAssertEqual(day.pulses[0].boundStationIDs, [oats.id])

        let late = StationRecord(label: "late", stampedAt: origin.addingTimeInterval(11 * 3600))
        XCTAssertThrowsError(
            try WindowJoin.bind(station: late, onto: day.pulses[0], lookbackHours: 6)
        ) { error in
            XCTAssertEqual(error as? BindFailure, .outsideCoda)
        }
        XCTAssertThrowsError(
            try WindowJoin.bind(stationID: oats.id, pulseID: pulse.id, on: day, lookbackHours: 6)
        ) { error in
            XCTAssertEqual(error as? BindFailure, .alreadyBound)
        }
        XCTAssertThrowsError(
            try WindowJoin.bind(stationID: UUID(), pulseID: pulse.id, on: day, lookbackHours: 6)
        ) { error in
            XCTAssertEqual(error as? BindFailure, .stationMissing)
        }
        XCTAssertTrue(MealPipeline.stations(from: " , \n", at: origin).isEmpty)
    }

    func test_stationOutsideCodaCannotJoin() {
        let station = StationRecord(label: "oats", stampedAt: origin.addingTimeInterval(2 * 3600))
        let pulse = EpicenterStamp.make(region: .gut, at: origin.addingTimeInterval(10 * 3600))
        XCTAssertFalse(WindowJoin.canBind(station: station, to: pulse, lookbackHours: 3))
        XCTAssertTrue(
            WindowJoin.eligibleStations(for: pulse, in: [station], lookbackHours: 3).isEmpty
        )
        let inside = StationRecord(label: "broth", stampedAt: origin.addingTimeInterval(8 * 3600))
        XCTAssertEqual(
            WindowJoin.eligibleStations(for: pulse, in: [station, inside], lookbackHours: 3).map(\.label),
            ["broth"]
        )
    }

    func test_joinSidesStaySeparate() throws {
        let stampedAt = origin.addingTimeInterval(8 * 3600)
        let stations = MealPipeline.stations(from: "tea", at: stampedAt)
        XCTAssertEqual(stations.count, 1)
        XCTAssertTrue(stations[0].label == "tea")

        let pulse = EpicenterStamp.make(region: .head, at: origin.addingTimeInterval(9 * 3600))
        XCTAssertTrue(pulse.boundStationIDs.isEmpty)

        var day = DayTrace.empty(on: origin, calendar: calendar)
        day = day.adding(stations: stations).adding(pulse)
        day = try WindowJoin.bind(stationID: stations[0].id, pulseID: pulse.id, on: day, lookbackHours: 6)
        XCTAssertEqual(day.pulses[0].boundStationIDs, [stations[0].id])
        XCTAssertTrue(WindowJoin.pairings(on: day, lookbacks: [.head: 6]).isEmpty)

        let second = EpicenterStamp.make(region: .head, at: origin.addingTimeInterval(11 * 3600))
        day = day.adding(second)
        day = try WindowJoin.bind(stationID: stations[0].id, pulseID: second.id, on: day, lookbackHours: 6)
        let report = WindowJoin.pairings(on: day, lookbacks: [.head: 6])
        XCTAssertEqual(report.count, 1)
        XCTAssertEqual(report[0].score, 1)
        XCTAssertEqual(RingHour.of(pulse.stampedAt, calendar: calendar).value, 9, accuracy: 1e-9)
    }

    func test_figuresUseNumberFormatter() {
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(TraceFigures.score(2.0 / 3.0, locale: locale), "0.67")
        XCTAssertFalse(TraceFigures.hours(3, locale: locale).isEmpty)
    }
}
