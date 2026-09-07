import SwiftUI
import UIKit

/// Window join. Twist screen: region-owned coda. Visible on home as the lit sector.
struct RegionCodaView: View {
    var lookbacks: [BodyRegion: Double]
    var onClose: () -> Void

    init(
        lookbacks: [BodyRegion: Double] = DrumSettings.factory.lookbackHours,
        onClose: @escaping () -> Void = {}
    ) {
        self.lookbacks = lookbacks
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DrumSpace.unit * 2) {
            DrumCloseBar(title: "Region-owned coda", onClose: onClose)
            ScrollView {
                VStack(alignment: .leading, spacing: DrumSpace.unit * 2) {
                    if UIImage(named: DrumArtName.twist) != nil {
                        Image(DrumArtName.twist)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .accessibilityHidden(true)
                    }
                    ZStack {
                        RingOutline().stroke(DrumInk.muted, lineWidth: 2)
                        CodaSector(startHour: 7, endHour: 13)
                            .fill(DrumInk.accent.opacity(0.3))
                        CodaSector(startHour: 7, endHour: 13)
                            .stroke(DrumInk.accent, lineWidth: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .accessibilityLabel("Coda sector on the ring")
                    Text("Each body region carries its own lookback. Stamping a region at hour T lights only that sector. Meals outside it cannot bind.")
                        .font(DrumType.body)
                        .foregroundStyle(DrumInk.muted)
                    ForEach(BodyRegion.allCases, id: \.self) { region in
                        HStack {
                            Text(region.title)
                                .font(DrumType.body)
                                .foregroundStyle(DrumInk.ink)
                            Spacer()
                            Text("\(TraceFigures.hours(hours(for: region))) h")
                                .font(DrumType.mark)
                                .foregroundStyle(DrumInk.accent)
                                .monospacedDigit()
                        }
                        .padding(DrumSpace.unit * 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DrumInk.surface)
                        .contentShape(Rectangle())
                    }
                    Text("A pairing is reported only after two matches. This is a counted join, not a medical claim.")
                        .font(DrumType.callout)
                        .foregroundStyle(DrumInk.muted)
                }
            }
        }
        .padding(DrumSpace.unit * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DrumInk.background.ignoresSafeArea())
    }

    private func hours(for region: BodyRegion) -> Double {
        CodaWindow.clamp(lookbacks[region] ?? region.factoryLookbackHours)
    }
}
