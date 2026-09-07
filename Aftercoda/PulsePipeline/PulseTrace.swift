import Foundation

/// Pulse pipeline. A region-stamped event on the pulse stream. Holds sewn station ids only.
struct PulseTrace: Identifiable, Hashable, Sendable, Codable, Equatable {
    var id: UUID
    var region: BodyRegion
    var stampedAt: Date
    var boundStationIDs: [UUID]

    init(
        id: UUID = UUID(),
        region: BodyRegion,
        stampedAt: Date,
        boundStationIDs: [UUID] = []
    ) {
        self.id = id
        self.region = region
        self.stampedAt = stampedAt
        self.boundStationIDs = boundStationIDs
    }
}

/// Pulse pipeline. Primary home verb: stamp the epicenter. Does not split meals or join streams.
enum EpicenterStamp {
    static func make(region: BodyRegion, at stampedAt: Date, id: UUID = UUID()) -> PulseTrace {
        PulseTrace(id: id, region: region, stampedAt: stampedAt)
    }
}
