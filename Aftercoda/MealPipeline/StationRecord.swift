import Foundation

/// Meal pipeline. One station on the meal stream after a comma or newline split.
struct StationRecord: Identifiable, Hashable, Sendable, Codable, Equatable {
    var id: UUID
    var label: String
    var stampedAt: Date

    init(id: UUID = UUID(), label: String, stampedAt: Date) {
        self.id = id
        self.label = label
        self.stampedAt = stampedAt
    }
}

/// Meal pipeline. Splits typed text into stations. Does not stamp pulses or score pairings.
enum MealPipeline {
    static func labels(from text: String) -> [String] {
        text.split { $0 == "," || $0.isNewline }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func stations(from text: String, at stampedAt: Date, makeID: () -> UUID = UUID.init) -> [StationRecord] {
        labels(from: text).map { StationRecord(id: makeID(), label: $0, stampedAt: stampedAt) }
    }
}
