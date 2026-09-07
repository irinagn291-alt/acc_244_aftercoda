import Foundation

/// Dial. Maps a stamp onto the 24h ring. No UIKit; the polar control reads this later.
struct RingHour: Equatable, Sendable {
    var value: Double

    static func of(_ date: Date, calendar: Calendar = .current) -> RingHour {
        let origin = calendar.startOfDay(for: date)
        return RingHour(value: date.timeIntervalSince(origin) / 3600)
    }
}
