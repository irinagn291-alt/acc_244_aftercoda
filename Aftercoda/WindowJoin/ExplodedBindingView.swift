import SwiftUI

/// Window join. Exploded binding is the home measure: stages mixed with sewn sections.
struct ExplodedBindingView: View {
    var exploded: ExplodedBinding
    var pulse: PulseTrace?
    var completedOnPulse: Int

    init(exploded: ExplodedBinding, pulse: PulseTrace? = nil, completedOnPulse: Int = 0) {
        self.exploded = exploded
        self.pulse = pulse
        self.completedOnPulse = completedOnPulse
    }

    init() {
        let day = DrumSeed.day(on: Date())
        let lookbacks = DrumSettings.factory.lookbackHours
        self.exploded = BindProgress.measure(day: day, lookbacks: lookbacks)
        self.pulse = day.pulses.first
        self.completedOnPulse = BindProgress.stagesCompleted(
            for: day.pulses[0],
            in: day,
            lookbacks: lookbacks
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DrumSpace.unit) {
            Text("Exploded bind")
                .font(DrumType.caption)
                .foregroundStyle(DrumInk.muted)
            HStack(spacing: DrumSpace.unit * 2) {
                ForEach(BindStage.allCases, id: \.rawValue) { stage in
                    VStack(spacing: 4) {
                        Circle()
                            .stroke(DrumInk.muted, lineWidth: 1)
                            .background(
                                Circle().fill(completedOnPulse >= stage.rawValue ? DrumInk.accent : Color.clear)
                            )
                            .frame(width: 16, height: 16)
                        Text(stage.label)
                            .font(DrumType.caption)
                            .foregroundStyle(completedOnPulse >= stage.rawValue ? DrumInk.ink : DrumInk.muted)
                    }
                    .frame(minWidth: DrumSpace.tap)
                    if stage != .stationSewn {
                        Rectangle()
                            .fill(DrumInk.muted)
                            .frame(height: 1)
                    }
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(DrumInk.surface)
                    Rectangle()
                        .fill(DrumInk.accent)
                        .frame(width: geo.size.width * exploded.progress)
                }
            }
            .frame(height: 8)
            .accessibilityLabel("Bind progress \(TraceFigures.score(exploded.progress))")
            Text(mixCopy)
                .font(DrumType.callout)
                .foregroundStyle(DrumInk.ink)
                .lineLimit(2)
        }
        .padding(DrumSpace.unit * 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DrumInk.surface)
    }

    private var mixCopy: String {
        let stages = "\(TraceFigures.score(Double(exploded.completedStages)))/\(TraceFigures.score(Double(exploded.totalStages))) stages"
        let sewn = "\(TraceFigures.score(Double(exploded.sewnSections)))/\(TraceFigures.score(Double(exploded.totalSections))) sewn"
        return "\(stages) · \(sewn)"
    }
}

extension BindStage {
    var label: String {
        switch self {
        case .stamped: "Stamp"
        case .codaLit: "Coda"
        case .stationSewn: "Sewn"
        }
    }
}
