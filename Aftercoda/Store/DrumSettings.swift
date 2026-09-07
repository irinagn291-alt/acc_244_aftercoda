import Foundation

/// Store. Per-region lookbacks, clamped on write. Onboarding flag lives with the vault keys.
struct DrumSettings: Equatable, Sendable {
    var lookbackHours: [BodyRegion: Double]

    static var factory: DrumSettings {
        DrumSettings(
            lookbackHours: Dictionary(
                uniqueKeysWithValues: BodyRegion.allCases.map { ($0, $0.factoryLookbackHours) }
            )
        )
    }

    func hours(for region: BodyRegion) -> Double {
        CodaWindow.clamp(lookbackHours[region] ?? region.factoryLookbackHours)
    }

    func retuning(_ region: BodyRegion, hours: Double) -> DrumSettings {
        var next = self
        next.lookbackHours[region] = CodaWindow.clamp(hours)
        return next
    }
}

/// Store. Settings envelope. Decoder switches on schemaVersion.
enum SettingsCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    struct Document: Codable, Equatable, Sendable {
        var schemaVersion: Int
        var lookbackHours: [String: Double]
    }

    static func encode(_ settings: DrumSettings) throws -> Data {
        let document = Document(
            schemaVersion: currentSchema,
            lookbackHours: Dictionary(
                uniqueKeysWithValues: settings.lookbackHours.map { ($0.key.rawValue, CodaWindow.clamp($0.value)) }
            )
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document)
    }

    static func decode(_ data: Data) throws -> DrumSettings {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                let document = try decoder.decode(Document.self, from: data)
                var hours: [BodyRegion: Double] = DrumSettings.factory.lookbackHours
                for (raw, value) in document.lookbackHours {
                    guard let region = BodyRegion(rawValue: raw) else { continue }
                    hours[region] = CodaWindow.clamp(value)
                }
                return DrumSettings(lookbackHours: hours)
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
