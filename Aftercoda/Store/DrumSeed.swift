import Foundation

/// Store. Simulator-only demo day. Device builds keep the type but never write it.
enum DrumSeed {
    static let dayID = literal("11111111-1111-4111-8111-111111111111")
    static let oatsID = literal("22222222-2222-4222-8222-222222222222")
    static let teaID = literal("33333333-3333-4333-8333-333333333333")
    static let riceID = literal("44444444-4444-4444-8444-444444444444")
    static let brothID = literal("55555555-5555-4555-8555-555555555555")
    static let headMorningID = literal("66666666-6666-4666-8666-666666666666")
    static let headNoonID = literal("77777777-7777-4777-8777-777777777777")
    static let gutAfternoonID = literal("88888888-8888-4888-8888-888888888888")

    /// Seed identities are literals. Failure here is a programmer error.
    private static func literal(_ raw: String) -> UUID {
        guard let value = UUID(uuidString: raw) else {
            fatalError("Drum seed UUID literal is invalid")
        }
        return value
    }

    static func day(on date: Date, calendar: Calendar = .current) -> DayTrace {
        let origin = calendar.startOfDay(for: date)
        func at(_ hour: Double) -> Date {
            origin.addingTimeInterval(hour * 3600)
        }
        let stations = [
            StationRecord(id: oatsID, label: "oats", stampedAt: at(8)),
            StationRecord(id: teaID, label: "tea", stampedAt: at(8)),
            StationRecord(id: riceID, label: "rice", stampedAt: at(12.5)),
            StationRecord(id: brothID, label: "broth", stampedAt: at(12.5)),
        ]
        let headMorning = PulseTrace(
            id: headMorningID,
            region: .head,
            stampedAt: at(10),
            boundStationIDs: [oatsID, teaID]
        )
        let headNoon = PulseTrace(
            id: headNoonID,
            region: .head,
            stampedAt: at(13),
            boundStationIDs: [oatsID, teaID]
        )
        let gutAfternoon = PulseTrace(
            id: gutAfternoonID,
            region: .gut,
            stampedAt: at(15),
            boundStationIDs: [riceID, brothID]
        )
        return DayTrace(
            id: dayID,
            dayKey: DayKey.milliseconds(for: date, calendar: calendar),
            stations: stations,
            pulses: [headMorning, headNoon, gutAfternoon]
        )
    }
}
