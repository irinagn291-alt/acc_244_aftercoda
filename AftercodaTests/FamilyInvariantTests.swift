import XCTest
@testable import Aftercoda

final class FamilyInvariantTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private var origin: Date {
        calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
    }

    func test_lookbackClampedToZeroThroughSixHours() {
        XCTAssertEqual(CodaWindow.clamp(-2), 0)
        XCTAssertEqual(CodaWindow.clamp(0), 0)
        XCTAssertEqual(CodaWindow.clamp(3), 3)
        XCTAssertEqual(CodaWindow.clamp(6), 6)
        XCTAssertEqual(CodaWindow.clamp(12), 6)
        XCTAssertEqual(BodyRegion.skin.requestedLookbackHours, 12)
        XCTAssertEqual(BodyRegion.skin.factoryLookbackHours, 6)
        XCTAssertEqual(BodyRegion.head.factoryLookbackHours, 6)
        XCTAssertEqual(BodyRegion.gut.factoryLookbackHours, 3)

        let pulseAt = origin.addingTimeInterval(12 * 3600)
        let window = CodaWindow(pulseAt: pulseAt, lookbackHours: 12)
        XCTAssertEqual(window.widthHours, 6)
        XCTAssertTrue(window.contains(origin.addingTimeInterval(6 * 3600)))
        XCTAssertFalse(window.contains(origin.addingTimeInterval(5 * 3600)))
    }

    func test_splitMealOnCommaAndNewline() {
        XCTAssertEqual(MealPipeline.labels(from: "eggs, toast\ncoffee"), ["eggs", "toast", "coffee"])
        XCTAssertEqual(MealPipeline.labels(from: "tea"), ["tea"])
        XCTAssertEqual(MealPipeline.labels(from: "  , \n "), [])
        XCTAssertEqual(MealPipeline.labels(from: ""), [])
        let stations = MealPipeline.stations(from: "oats, tea", at: origin)
        XCTAssertEqual(stations.map(\.label), ["oats", "tea"])
        XCTAssertEqual(stations[0].stampedAt, origin)
        XCTAssertEqual(stations[1].stampedAt, origin)
    }

    func test_scoreIsMatchedOverTotalSymptoms_dropsUnderTwo() throws {
        let oats = StationRecord(label: "oats", stampedAt: origin.addingTimeInterval(8 * 3600))
        let tea = StationRecord(label: "tea", stampedAt: origin.addingTimeInterval(8 * 3600))
        var day = DayTrace.empty(on: origin, calendar: calendar)
        day = day.adding(stations: [oats, tea])

        let first = EpicenterStamp.make(region: .head, at: origin.addingTimeInterval(10 * 3600))
        let second = EpicenterStamp.make(region: .head, at: origin.addingTimeInterval(13 * 3600))
        let third = EpicenterStamp.make(region: .head, at: origin.addingTimeInterval(16 * 3600))
        day = day.adding(first).adding(second).adding(third)

        day = try WindowJoin.bind(stationID: oats.id, pulseID: first.id, on: day, lookbackHours: 6)
        day = try WindowJoin.bind(stationID: oats.id, pulseID: second.id, on: day, lookbackHours: 6)
        day = try WindowJoin.bind(stationID: tea.id, pulseID: first.id, on: day, lookbackHours: 6)

        let lookbacks = DrumSettings.factory.lookbackHours
        let report = WindowJoin.pairings(on: day, lookbacks: lookbacks)
        XCTAssertEqual(report.count, 1)
        let oatsPair = try XCTUnwrap(report.first)
        XCTAssertEqual(oatsPair.region, .head)
        XCTAssertEqual(oatsPair.stationLabel, "oats")
        XCTAssertEqual(oatsPair.matched, 2)
        XCTAssertEqual(oatsPair.totalSymptoms, 3)
        XCTAssertEqual(oatsPair.score, 2.0 / 3.0, accuracy: 1e-9)
        XCTAssertFalse(report.contains { $0.stationLabel == "tea" })
    }
}
