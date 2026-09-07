import XCTest
@testable import Aftercoda

final class BindProgressTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private var origin: Date {
        calendar.startOfDay(for: Date(timeIntervalSince1970: 1_788_048_000))
    }

    func test_progressMixesStagesAndSewnSections() {
        XCTAssertEqual(BindProgress.mix(completedStages: 0, totalStages: 0, sewnSections: 0, totalSections: 0), 0)
        XCTAssertEqual(BindProgress.mix(completedStages: 2, totalStages: 4, sewnSections: 1, totalSections: 2), 0.5)
        XCTAssertEqual(BindProgress.mix(completedStages: 3, totalStages: 3, sewnSections: 2, totalSections: 2), 1)
        XCTAssertEqual(BindProgress.mix(completedStages: 3, totalStages: 3, sewnSections: 0, totalSections: 2), 0.5)
    }

    func test_explodedBindingMeasuresHomeFromDay() throws {
        let oats = StationRecord(label: "oats", stampedAt: origin.addingTimeInterval(8 * 3600))
        let rice = StationRecord(label: "rice", stampedAt: origin.addingTimeInterval(12 * 3600))
        var day = DayTrace.empty(on: origin, calendar: calendar)
        day = day.adding(stations: [oats, rice])
        let pulse = EpicenterStamp.make(region: .gut, at: origin.addingTimeInterval(14 * 3600))
        day = day.adding(pulse)
        day = try WindowJoin.bind(stationID: rice.id, pulseID: pulse.id, on: day, lookbackHours: 3)

        let exploded = BindProgress.measure(day: day, lookbacks: DrumSettings.factory.lookbackHours)
        XCTAssertEqual(exploded.totalStages, BindProgress.stagesPerPulse)
        XCTAssertEqual(exploded.completedStages, BindStage.stationSewn.rawValue)
        XCTAssertEqual(exploded.totalSections, 2)
        XCTAssertEqual(exploded.sewnSections, 1)
        XCTAssertEqual(exploded.progress, BindProgress.mix(completedStages: 3, totalStages: 3, sewnSections: 1, totalSections: 2))
    }

    func test_emptyDayHasZeroExplodedProgress() {
        let day = DayTrace.empty(on: origin, calendar: calendar)
        let exploded = BindProgress.measure(day: day, lookbacks: [:])
        XCTAssertEqual(exploded.progress, 0)
        XCTAssertEqual(exploded.totalStages, 0)
        XCTAssertEqual(exploded.totalSections, 0)
    }
}
