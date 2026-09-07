import SwiftUI

struct ContentView: View {
    @ObservedObject var hub: DrumHub

    init(hub: DrumHub = DrumFixtures.populated) {
        self.hub = hub
    }

    var body: some View {
        TimelineView(hub: hub)
            .preferredColorScheme(.dark)
            .fullScreenCover(isPresented: $hub.showsOnboarding) {
                OnboardingView(hub: hub)
                    .interactiveDismissDisabled()
            }
            .sheet(item: $hub.sheet) { sheet in
                sheetView(sheet)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DrumInk.background)
                    .presentationCompactAdaptation(.fullScreenCover)
            }
    }

    @ViewBuilder
    private func sheetView(_ sheet: DrumSheet) -> some View {
        switch sheet {
        case .bind:
            BindSheet(hub: hub)
        case .report:
            ReportView(
                pairings: hub.pairings,
                failure: reportFailure,
                onRetry: { Task { await hub.retry() } },
                onClose: { hub.sheet = nil }
            )
        case .settings:
            SettingsView(hub: hub)
        case .twist:
            RegionCodaView(lookbacks: hub.lookbacks, onClose: { hub.sheet = nil })
        }
    }

    private var reportFailure: String? {
        if case .failed(let text) = hub.phase { return text }
        return nil
    }
}

#Preview {
    ContentView()
}
