import Foundation

/// Store. On-disk envelope for one calendar day. Domain types never decode this directly.
struct DayDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var id: UUID
    var dayKey: Int64
    var stations: [StationRecord]
    var pulses: [PulseTrace]
}

/// Store. schemaVersion switch and DayTrace ↔ document mapping. No FileManager.
enum DayCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func document(from day: DayTrace) -> DayDocument {
        DayDocument(
            schemaVersion: currentSchema,
            id: day.id,
            dayKey: day.dayKey,
            stations: day.stations,
            pulses: day.pulses
        )
    }

    static func day(from document: DayDocument) -> DayTrace {
        DayTrace(
            id: document.id,
            dayKey: document.dayKey,
            stations: document.stations,
            pulses: document.pulses
        )
    }

    static func encode(_ day: DayTrace) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(document(from: day))
    }

    static func decode(_ data: Data) throws -> DayTrace {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let probe: DaySchemaProbe
        do {
            probe = try decoder.decode(DaySchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return day(from: try decoder.decode(DayDocument.self, from: data))
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct DaySchemaProbe: Decodable {
    var schemaVersion: Int
}
