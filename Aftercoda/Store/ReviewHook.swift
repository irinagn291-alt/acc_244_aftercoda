import Foundation

/// Store. Reads `-ReviewScreen` once after onboarding. The driver takes the PNG, not the app.
enum ReviewHook {
    enum Screen: String, Equatable, Sendable {
        case today
        case log
        case goals
    }

    static let argument = "-ReviewScreen"

    static func pending(in arguments: [String]) -> Screen? {
        guard let index = arguments.firstIndex(of: argument) else { return nil }
        let next = arguments.index(after: index)
        guard next < arguments.endIndex else { return nil }
        return Screen(rawValue: arguments[next])
    }
}
