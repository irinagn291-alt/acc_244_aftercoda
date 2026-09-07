import SwiftUI

/// Window join. Bind a station only inside the lit coda. Comma or newline splits stations.
struct BindSheet: View {
    @ObservedObject var hub: DrumHub
    @FocusState private var drafting: Bool

    init(hub: DrumHub = DrumFixtures.populated) {
        self.hub = hub
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DrumSpace.unit * 2) {
            DrumCloseBar(title: "Sew a station") { hub.sheet = nil }
            ScrollView {
                VStack(alignment: .leading, spacing: DrumSpace.unit * 2) {
                    if let pulse = hub.selectedPulse {
                        Text("\(pulse.region.title) coda · \(TraceFigures.hours(hub.settings.hours(for: pulse.region))) h")
                            .font(DrumType.callout)
                            .foregroundStyle(DrumInk.muted)
                    } else {
                        Text("Stamp an epicenter before a bind.")
                            .font(DrumType.body)
                            .foregroundStyle(DrumInk.muted)
                    }
                    if hub.eligibleStations.isEmpty {
                        emptyEligible
                    } else {
                        ForEach(hub.eligibleStations) { station in
                            Button {
                                Task { await hub.sew(stationID: station.id) }
                            } label: {
                                HStack {
                                    Text(station.label)
                                        .font(DrumType.body)
                                        .foregroundStyle(DrumInk.ink)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(TraceFigures.hours(RingHour.of(station.stampedAt).value))
                                        .font(DrumType.callout)
                                        .foregroundStyle(DrumInk.muted)
                                }
                                .padding(DrumSpace.unit * 2)
                                .frame(maxWidth: .infinity, minHeight: DrumSpace.tap)
                                .background(DrumInk.surface)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(hub.actionInFlight)
                            .accessibilityLabel("Bind \(station.label)")
                        }
                    }
                    TextField("oats, tea", text: $hub.bindDraft, axis: .vertical)
                        .font(DrumType.body)
                        .foregroundStyle(DrumInk.ink)
                        .padding(DrumSpace.unit * 2)
                        .frame(minHeight: DrumSpace.tap)
                        .background(DrumInk.surface)
                        .focused($drafting)
                        .submitLabel(.done)
                    DrumFillButton(
                        title: "Sew typed stations",
                        enabled: !hub.actionInFlight
                            && hub.selectedPulse != nil
                            && !hub.bindDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        drafting = false
                        Task { await hub.sewDraft() }
                    }
                    if let failure = hub.bindFailure {
                        Text(copy(for: failure))
                            .font(DrumType.callout)
                            .foregroundStyle(DrumInk.ink)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(TapGesture().onEnded { drafting = false })
        }
        .padding(DrumSpace.unit * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DrumInk.background.ignoresSafeArea())
    }

    private var emptyEligible: some View {
        VStack(spacing: DrumSpace.unit) {
            DrumArt(name: DrumArtName.emptyList)
                .frame(width: 96, height: 96)
            Text("No station sits in this coda")
                .font(DrumType.heading)
                .foregroundStyle(DrumInk.ink)
            Text("Type one. Comma or a new line splits stations.")
                .font(DrumType.callout)
                .foregroundStyle(DrumInk.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(DrumSpace.unit * 2)
    }

    private func copy(for failure: BindFailure) -> String {
        switch failure {
        case .stationMissing: "That station is gone from the drum."
        case .pulseMissing: "That pulse is gone from the drum."
        case .outsideCoda: "That station sits outside this coda."
        case .alreadyBound: "That station is already sewn to this pulse."
        }
    }
}
