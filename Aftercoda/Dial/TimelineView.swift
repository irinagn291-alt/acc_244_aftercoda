import SwiftUI
import UIKit

/// Dial. Timeline is home: 24h ring with named pulses and meals. Stamp a region, then bind in the coda.
struct TimelineView: View {
    @ObservedObject var hub: DrumHub
    @State private var showSuccess = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(hub: DrumHub = DrumFixtures.populated) {
        self.hub = hub
    }

    var body: some View {
        ZStack {
            DrumInk.background.ignoresSafeArea()
            VStack(spacing: DrumSpace.unit) {
                header
                if hub.isEmpty {
                    EmptyDrumView(fillsPage: true) {
                        if hub.selectedRegion == nil {
                            hub.select(region: .head)
                        }
                        Task { await hub.stampSelected() }
                    }
                } else {
                    jobLine
                    canvas
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    regionRow
                    chrome
                }
            }
            .padding(.horizontal, DrumSpace.unit * 2)
            .padding(.bottom, DrumSpace.unit * 2)
            if hub.showSpinner {
                ProgressView()
                    .tint(DrumInk.accent)
            }
            SuccessStampView(visible: showSuccess, fillsPage: false)
        }
        .onChange(of: hub.day.pulses.count) { old, new in
            if new > old { flashSuccess() }
        }
        .onChange(of: hub.exploded.sewnSections) { old, new in
            if new > old { flashSuccess() }
        }
        .overlay(alignment: .top) {
            if let message = overlayMessage {
                Text(message)
                    .font(DrumType.caption)
                    .foregroundStyle(DrumInk.ink)
                    .padding(DrumSpace.unit)
                    .frame(maxWidth: .infinity)
                    .background(DrumInk.surface)
            }
        }
    }

    private var header: some View {
        VStack(spacing: DrumSpace.unit) {
            if UIImage(named: DrumArtName.header) != nil {
                Image(DrumArtName.header)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 48)
                    .clipped()
                    .accessibilityHidden(true)
            }
            HStack(spacing: DrumSpace.unit) {
                Text("Aftercoda")
                    .font(DrumType.title)
                    .foregroundStyle(DrumInk.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: DrumSpace.unit)
                chromeButton("Pairings") { hub.open(.report) }
                chromeButton("Lookbacks") { hub.open(.settings) }
                chromeButton("Coda") { hub.open(.twist) }
            }
        }
    }

    private var jobLine: some View {
        Text(jobCopy)
            .font(DrumType.body)
            .foregroundStyle(DrumInk.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    private var canvas: some View {
        ZStack {
            RingFace(
                hour: hub.scrubHour,
                dayStart: Calendar.current.startOfDay(for: Date()),
                stations: hub.day.stations,
                pulses: hub.day.pulses,
                coda: hub.coda,
                codaTitle: ringCodaTitle,
                calendar: Calendar.current,
                onSelectPulse: { hub.select(pulseID: $0) }
            )
            codaWell
            RingHost(hour: $hub.scrubHour, onNowStamp: {
                Task { await hub.stampNow() }
            })
        }
        .frame(minHeight: sizeClass == .regular ? 420 : 280)
    }

    private var codaWell: some View {
        VStack(spacing: 4) {
            Text(codaCaption)
                .font(DrumType.callout)
                .foregroundStyle(DrumInk.ink)
                .multilineTextAlignment(.center)
            if !codaMealCopy.isEmpty {
                Text(codaMealCopy)
                    .font(DrumType.caption)
                    .foregroundStyle(DrumInk.accent)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(DrumSpace.unit)
        .frame(width: 132)
        .allowsHitTesting(false)
    }

    private var regionRow: some View {
        BodyMapView(
            selected: hub.selectedRegion,
            pulses: hub.day.pulses,
            lookbacks: hub.lookbacks,
            failure: bodyFailure,
            onSelect: { hub.select(region: $0) },
            onRetry: { Task { await hub.retry() } },
            fillsCanvas: false,
            showsFigure: sizeClass == .regular
        )
    }

    private var chrome: some View {
        VStack(spacing: DrumSpace.unit) {
            Text(hourCopy)
                .font(DrumType.mark)
                .foregroundStyle(DrumInk.ink)
                .monospacedDigit()
            HStack(spacing: DrumSpace.unit) {
                action("Now", fill: DrumInk.surface, ink: DrumInk.ink) {
                    hub.useNow()
                }
                action(stampTitle, fill: DrumInk.accent, ink: DrumInk.background) {
                    Task { await hub.stampSelected() }
                }
                .disabled(hub.actionInFlight)
                action("Bind", fill: DrumInk.surface, ink: DrumInk.ink) {
                    hub.open(.bind)
                }
                .disabled(hub.selectedPulse == nil || hub.actionInFlight)
            }
        }
    }

    private var jobCopy: String {
        let region = hub.selectedRegion ?? hub.selectedPulse?.region ?? .head
        let meals = uniqueLabels(hub.eligibleStations.map(\.label))
        if meals.isEmpty {
            return "Stamp \(region.title), then bind a station inside the lit coda."
        }
        return "Stamp \(region.title), then bind \(list(meals)) inside this coda."
    }

    private var stampTitle: String {
        let region = hub.selectedRegion ?? hub.selectedPulse?.region
        if let region {
            return "Stamp \(region.title)"
        }
        return "Stamp"
    }

    private var codaCaption: String {
        let region = hub.selectedPulse?.region ?? hub.selectedRegion
        guard let region else { return "Pick a region" }
        let hours = hub.settings.hours(for: region)
        return "\(region.title) coda · \(TraceFigures.hours(hours)) h"
    }

    private var ringCodaTitle: String {
        let region = hub.selectedPulse?.region ?? hub.selectedRegion
        guard let region else { return "" }
        return "\(region.title) coda"
    }

    private var codaMealCopy: String {
        list(uniqueLabels(hub.eligibleStations.map(\.label)))
    }

    private var hourCopy: String {
        "Hour \(TraceFigures.hours(hub.scrubHour))"
    }

    private var overlayMessage: String? {
        if case .failed(let text) = hub.phase { return text }
        if let errorMessage = hub.errorMessage { return errorMessage }
        switch hub.warning {
        case .recoveredFromBackup:
            return "A day file was recovered from backup."
        case .startedEmpty:
            return "A day file was unreadable. The drum started empty."
        case .none:
            return nil
        }
    }

    private var bodyFailure: String? {
        if case .failed(let text) = hub.phase { return text }
        return nil
    }

    private func uniqueLabels(_ labels: [String]) -> [String] {
        var seen: [String] = []
        for label in labels where !seen.contains(label) {
            seen.append(label)
        }
        return seen
    }

    private func list(_ names: [String]) -> String {
        switch names.count {
        case 0: return ""
        case 1: return names[0]
        case 2: return "\(names[0]) and \(names[1])"
        default:
            return names.dropLast().joined(separator: ", ") + ", and " + names[names.count - 1]
        }
    }

    private func flashSuccess() {
        showSuccess = true
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            showSuccess = false
        }
    }

    private func chromeButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(DrumType.caption)
                .foregroundStyle(DrumInk.ink)
                .frame(minWidth: DrumSpace.tap, minHeight: DrumSpace.tap)
                .padding(.horizontal, DrumSpace.unit)
                .background(DrumInk.surface)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func action(_ title: String, fill: Color, ink: Color, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Text(title)
                .font(DrumType.body)
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: DrumSpace.tap)
                .background(fill)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
