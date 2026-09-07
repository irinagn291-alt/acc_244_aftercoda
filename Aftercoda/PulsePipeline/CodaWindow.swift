import Foundation

/// Pulse pipeline. Region-owned lookback opened at stamp time T. Width is always 0…6 hours.
struct CodaWindow: Equatable, Sendable {
    static let minimumHours: Double = 0
    static let maximumHours: Double = 6

    var pulseAt: Date
    var lookbackHours: Double

    var widthHours: Double {
        CodaWindow.clamp(lookbackHours)
    }

    var opensAt: Date {
        pulseAt.addingTimeInterval(-widthHours * 3600)
    }

    static func clamp(_ hours: Double) -> Double {
        min(maximumHours, max(minimumHours, hours))
    }

    func contains(_ stationAt: Date) -> Bool {
        stationAt >= opensAt && stationAt <= pulseAt
    }
}
