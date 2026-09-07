import Foundation

/// Store. Day file key = Unix milliseconds of Calendar.startOfDay.
enum DayKey {
    static func milliseconds(for date: Date, calendar: Calendar = .current) -> Int64 {
        let origin = calendar.startOfDay(for: date)
        return Int64((origin.timeIntervalSince1970 * 1000).rounded())
    }
}
