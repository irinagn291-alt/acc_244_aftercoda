import SwiftUI

/// Store. Per-region lookbacks, local export, contact. Re-run onboarding and reset live here.
struct SettingsView: View {
    @ObservedObject var hub: DrumHub
    @State private var confirmReset = false
    @State private var hours: [BodyRegion: Double]

    init(hub: DrumHub = DrumFixtures.populated) {
        self.hub = hub
        _hours = State(initialValue: hub.lookbacks)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DrumSpace.unit * 2) {
            DrumCloseBar(title: "Lookbacks") { hub.sheet = nil }
            if case .failed(let text) = hub.phase {
                errorState(text)
            } else {
                populated
            }
        }
        .padding(DrumSpace.unit * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DrumInk.background.ignoresSafeArea())
        .alert("Reset the drum?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                Task { await hub.resetAll() }
            }
            Button("Keep traces", role: .cancel) {}
        } message: {
            Text("Every day file and lookback will be cleared.")
        }
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DrumSpace.unit * 2) {
                Text("Each region owns its coda. Width stays 0 to 6 hours.")
                    .font(DrumType.callout)
                    .foregroundStyle(DrumInk.muted)
                ForEach(BodyRegion.allCases, id: \.self) { region in
                    VStack(alignment: .leading, spacing: DrumSpace.unit) {
                        HStack {
                            Text(region.title)
                                .font(DrumType.body)
                                .foregroundStyle(DrumInk.ink)
                                .lineLimit(1)
                            Spacer()
                            Text("\(TraceFigures.hours(hours[region] ?? region.factoryLookbackHours)) h")
                                .font(DrumType.mark)
                                .foregroundStyle(DrumInk.accent)
                                .monospacedDigit()
                        }
                        Slider(
                            value: binding(for: region),
                            in: CodaWindow.minimumHours ... CodaWindow.maximumHours,
                            step: 0.5
                        ) { editing in
                            if !editing {
                                Task { await hub.persistSettings() }
                            }
                        }
                        .tint(DrumInk.accent)
                        .frame(minHeight: DrumSpace.tap)
                        .accessibilityLabel("\(region.title) lookback")
                    }
                    .padding(DrumSpace.unit * 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DrumInk.surface)
                    .contentShape(Rectangle())
                }
                ShareLink(item: hub.reportText()) {
                    Text("Export pairings")
                        .font(DrumType.body)
                        .foregroundStyle(DrumInk.ink)
                        .frame(maxWidth: .infinity, minHeight: DrumSpace.tap)
                        .background(DrumInk.surface)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Link(destination: hub.contactURL) {
                    Text("Contact")
                        .font(DrumType.body)
                        .foregroundStyle(DrumInk.ink)
                        .frame(maxWidth: .infinity, minHeight: DrumSpace.tap)
                        .background(DrumInk.surface)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Contact")
                DrumFillButton(title: "Replay the briefing", ink: DrumInk.ink, fill: DrumInk.surface) {
                    hub.rerunOnboarding()
                }
                DrumFillButton(title: "Reset all traces", ink: DrumInk.ink, fill: DrumInk.surface) {
                    confirmReset = true
                }
                Text("A counted pairing, not a diagnosis.")
                    .font(DrumType.caption)
                    .foregroundStyle(DrumInk.muted)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func errorState(_ text: String) -> some View {
        VStack(spacing: DrumSpace.unit * 2) {
            Text("Lookbacks would not load.")
                .font(DrumType.heading)
                .foregroundStyle(DrumInk.ink)
            Text(text)
                .font(DrumType.body)
                .foregroundStyle(DrumInk.muted)
            DrumFillButton(title: "Retry") { Task { await hub.retry() } }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func binding(for region: BodyRegion) -> Binding<Double> {
        Binding(
            get: { hours[region] ?? region.factoryLookbackHours },
            set: { value in
                hours[region] = value
                hub.retune(region, hours: value)
            }
        )
    }
}
