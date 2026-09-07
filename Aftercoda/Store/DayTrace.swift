import Foundation

/// Store. In-memory day: stations and pulses only. Pairings and progress are computed.
struct DayTrace: Identifiable, Hashable, Sendable, Equatable {
    var id: UUID
    var dayKey: Int64
    var stations: [StationRecord]
    var pulses: [PulseTrace]

    init(
        id: UUID = UUID(),
        dayKey: Int64,
        stations: [StationRecord] = [],
        pulses: [PulseTrace] = []
    ) {
        self.id = id
        self.dayKey = dayKey
        self.stations = stations
        self.pulses = pulses
    }

    static func empty(on date: Date, calendar: Calendar = .current, id: UUID = UUID()) -> DayTrace {
        DayTrace(id: id, dayKey: DayKey.milliseconds(for: date, calendar: calendar))
    }

    func adding(stations incoming: [StationRecord]) -> DayTrace {
        var next = self
        next.stations.append(contentsOf: incoming)
        return next
    }

    func adding(_ pulse: PulseTrace) -> DayTrace {
        var next = self
        if let index = next.pulses.firstIndex(where: { $0.id == pulse.id }) {
            next.pulses[index] = pulse
        } else {
            next.pulses.append(pulse)
        }
        return next
    }

    func replacing(_ pulse: PulseTrace) -> DayTrace {
        adding(pulse)
    }
}
