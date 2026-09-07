import Foundation

/// Window join. Binding stages on one pulse. Exploded binding is the home measure, not a journal.
enum BindStage: Int, CaseIterable, Sendable {
    case stamped = 1
    case codaLit = 2
    case stationSewn = 3
}

/// Window join. Progress mixes completed stages with sewn sections.
struct ExplodedBinding: Equatable, Sendable {
    var completedStages: Int
    var totalStages: Int
    var sewnSections: Int
    var totalSections: Int

    var progress: Double {
        BindProgress.mix(
            completedStages: completedStages,
            totalStages: totalStages,
            sewnSections: sewnSections,
            totalSections: totalSections
        )
    }
}

/// Window join. Desk formula: progress = (stages/totalStages + sewn/totalSections) / 2.
enum BindProgress {
    static let stagesPerPulse = BindStage.allCases.count

    static func mix(
        completedStages: Int,
        totalStages: Int,
        sewnSections: Int,
        totalSections: Int
    ) -> Double {
        let stagePart = totalStages == 0 ? 0 : Double(completedStages) / Double(totalStages)
        let sewnPart = totalSections == 0 ? 0 : Double(sewnSections) / Double(totalSections)
        return (stagePart + sewnPart) / 2
    }

    static func measure(day: DayTrace, lookbacks: [BodyRegion: Double]) -> ExplodedBinding {
        var completed = 0
        for pulse in day.pulses {
            completed += stagesCompleted(for: pulse, in: day, lookbacks: lookbacks)
        }
        let sewn = day.stations.filter { station in
            day.pulses.contains { pulse in
                pulse.boundStationIDs.contains(station.id)
                    && WindowJoin.canBind(
                        station: station,
                        to: pulse,
                        lookbackHours: lookbacks[pulse.region] ?? pulse.region.factoryLookbackHours
                    )
            }
        }.count
        return ExplodedBinding(
            completedStages: completed,
            totalStages: day.pulses.count * stagesPerPulse,
            sewnSections: sewn,
            totalSections: day.stations.count
        )
    }

    static func stagesCompleted(
        for pulse: PulseTrace,
        in day: DayTrace,
        lookbacks: [BodyRegion: Double]
    ) -> Int {
        let hours = lookbacks[pulse.region] ?? pulse.region.factoryLookbackHours
        let sewn = pulse.boundStationIDs.contains { stationID in
            guard let station = day.stations.first(where: { $0.id == stationID }) else { return false }
            return WindowJoin.canBind(station: station, to: pulse, lookbackHours: hours)
        }
        return sewn ? BindStage.stationSewn.rawValue : BindStage.codaLit.rawValue
    }
}
