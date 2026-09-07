import Foundation

/// Pulse pipeline. A body region owns its coda lookback. Not a calorie slot.
enum BodyRegion: String, CaseIterable, Sendable, Codable, Hashable {
    case head
    case gut
    case skin

    /// Requested factory hours before the 0…6 clamp. Skin asks for 12h and is clipped.
    var requestedLookbackHours: Double {
        switch self {
        case .head: 6
        case .gut: 3
        case .skin: 12
        }
    }

    var factoryLookbackHours: Double {
        CodaWindow.clamp(requestedLookbackHours)
    }
}
