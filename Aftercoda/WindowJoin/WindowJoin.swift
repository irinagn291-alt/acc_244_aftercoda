import Foundation

/// Window join. Counted region×station pairing. Score is matched over total pulses, not calories.
struct PairingTrace: Hashable, Sendable, Equatable {
    var region: BodyRegion
    var stationLabel: String
    var matched: Int
    var totalSymptoms: Int

    var score: Double {
        guard totalSymptoms > 0 else { return 0 }
        return Double(matched) / Double(totalSymptoms)
    }

    var isReportable: Bool {
        matched >= 2
    }
}

/// Window join. Why a station cannot be sewn to a pulse.
enum BindFailure: Error, Equatable, Sendable {
    case stationMissing
    case pulseMissing
    case outsideCoda
    case alreadyBound
}

/// Window join. Meal stream ⋈ pulse stream. Lookback is the window. Views never call FileManager here.
enum WindowJoin {
    static func window(for pulse: PulseTrace, lookbackHours: Double) -> CodaWindow {
        CodaWindow(pulseAt: pulse.stampedAt, lookbackHours: lookbackHours)
    }

    static func canBind(
        station: StationRecord,
        to pulse: PulseTrace,
        lookbackHours: Double
    ) -> Bool {
        window(for: pulse, lookbackHours: lookbackHours).contains(station.stampedAt)
    }

    static func eligibleStations(
        for pulse: PulseTrace,
        in stations: [StationRecord],
        lookbackHours: Double
    ) -> [StationRecord] {
        let coda = window(for: pulse, lookbackHours: lookbackHours)
        return stations.filter { coda.contains($0.stampedAt) }
    }

    static func bind(
        station: StationRecord,
        onto pulse: PulseTrace,
        lookbackHours: Double
    ) throws -> PulseTrace {
        guard canBind(station: station, to: pulse, lookbackHours: lookbackHours) else {
            throw BindFailure.outsideCoda
        }
        guard !pulse.boundStationIDs.contains(station.id) else {
            throw BindFailure.alreadyBound
        }
        var next = pulse
        next.boundStationIDs.append(station.id)
        return next
    }

    static func bind(
        stationID: UUID,
        pulseID: UUID,
        on day: DayTrace,
        lookbackHours: Double
    ) throws -> DayTrace {
        guard let station = day.stations.first(where: { $0.id == stationID }) else {
            throw BindFailure.stationMissing
        }
        guard let pulse = day.pulses.first(where: { $0.id == pulseID }) else {
            throw BindFailure.pulseMissing
        }
        let sewn = try bind(station: station, onto: pulse, lookbackHours: lookbackHours)
        return day.replacing(sewn)
    }

    /// Pairings that survive the family drop rule. matched < 2 is omitted.
    static func pairings(on day: DayTrace, lookbacks: [BodyRegion: Double]) -> [PairingTrace] {
        let totals = Dictionary(grouping: day.pulses, by: \.region).mapValues(\.count)
        var matched: [PairingKey: Int] = [:]
        for pulse in day.pulses {
            let hours = CodaWindow.clamp(lookbacks[pulse.region] ?? pulse.region.factoryLookbackHours)
            let coda = window(for: pulse, lookbackHours: hours)
            for stationID in pulse.boundStationIDs {
                guard let station = day.stations.first(where: { $0.id == stationID }) else { continue }
                guard coda.contains(station.stampedAt) else { continue }
                let key = PairingKey(region: pulse.region, stationLabel: station.label)
                matched[key, default: 0] += 1
            }
        }
        return matched.compactMap { key, count in
            let pairing = PairingTrace(
                region: key.region,
                stationLabel: key.stationLabel,
                matched: count,
                totalSymptoms: totals[key.region] ?? 0
            )
            return pairing.isReportable ? pairing : nil
        }
        .sorted { lhs, rhs in
            if lhs.region != rhs.region { return lhs.region.rawValue < rhs.region.rawValue }
            return lhs.stationLabel < rhs.stationLabel
        }
    }
}

private struct PairingKey: Hashable {
    var region: BodyRegion
    var stationLabel: String
}
