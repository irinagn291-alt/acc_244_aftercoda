import SwiftUI
import UIKit

/// Window join. Report sheet. Which meals sat inside which region's coda.
struct ReportView: View {
    var pairings: [PairingTrace]
    var failure: String?
    var onRetry: () -> Void
    var onClose: () -> Void

    init(
        pairings: [PairingTrace] = [],
        failure: String? = nil,
        onRetry: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {}
    ) {
        self.pairings = pairings
        self.failure = failure
        self.onRetry = onRetry
        self.onClose = onClose
    }

    init() {
        let day = DrumSeed.day(on: Date())
        self.pairings = WindowJoin.pairings(on: day, lookbacks: DrumSettings.factory.lookbackHours)
        self.failure = nil
        self.onRetry = {}
        self.onClose = {}
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DrumSpace.unit * 2) {
            DrumCloseBar(title: "Meals inside each coda", onClose: onClose)
            if let failure {
                errorState(failure)
            } else if pairings.isEmpty {
                emptyState
            } else {
                populated
            }
        }
        .padding(DrumSpace.unit * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DrumInk.background.ignoresSafeArea())
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: DrumSpace.unit * 2) {
            Text(jobLine)
                .font(DrumType.body)
                .foregroundStyle(DrumInk.ink)
                .fixedSize(horizontal: false, vertical: true)
            joinBoard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var joinBoard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Coda")
                    .font(DrumType.caption)
                    .foregroundStyle(DrumInk.muted)
                    .frame(width: 80, alignment: .leading)
                    .padding(.horizontal, DrumSpace.unit)
                ForEach(mealColumns, id: \.self) { meal in
                    Text(meal)
                        .font(DrumType.heading)
                        .foregroundStyle(DrumInk.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: DrumSpace.tap)
                }
            }
            .padding(.vertical, DrumSpace.unit)
            ForEach(BodyRegion.allCases, id: \.self) { region in
                Rectangle()
                    .fill(DrumInk.muted.opacity(0.35))
                    .frame(height: 1)
                HStack(spacing: 0) {
                    Text(region.title)
                        .font(DrumType.body)
                        .foregroundStyle(DrumInk.ink)
                        .frame(width: 80, alignment: .leading)
                        .padding(.horizontal, DrumSpace.unit)
                    ForEach(mealColumns, id: \.self) { meal in
                        joinCell(region: region, meal: meal)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(DrumSpace.unit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DrumInk.surface)
    }

    private var mealColumns: [String] {
        var seen: [String] = []
        for pairing in pairings where !seen.contains(pairing.stationLabel) {
            seen.append(pairing.stationLabel)
        }
        return seen.sorted()
    }

    private var jobLine: String {
        let groups = Dictionary(grouping: pairings, by: \.region)
        let clauses = BodyRegion.allCases.compactMap { region -> String? in
            guard let rows = groups[region], !rows.isEmpty else { return nil }
            let meals = rows.map(\.stationLabel)
            return "\(list(meals)) sat inside \(region.title) coda"
        }
        guard !clauses.isEmpty else { return "Counted meals that sat inside a region's coda." }
        return clauses.joined(separator: ". ") + "."
    }

    private func joinCell(region: BodyRegion, meal: String) -> some View {
        let found = pairings.first { $0.region == region && $0.stationLabel == meal }
        return VStack(spacing: 6) {
            if let found {
                Text(meal)
                    .font(DrumType.mark)
                    .foregroundStyle(DrumInk.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("inside \(region.title) coda")
                    .font(DrumType.caption)
                    .foregroundStyle(DrumInk.ink)
                Text(
                    "\(TraceFigures.score(Double(found.matched))) of \(TraceFigures.score(Double(found.totalSymptoms))) \(region.title) pulses"
                )
                .font(DrumType.callout)
                .foregroundStyle(DrumInk.accent)
                .monospacedDigit()
            } else {
                Text("—")
                    .font(DrumType.mark)
                    .foregroundStyle(DrumInk.muted)
                Text("no join")
                    .font(DrumType.caption)
                    .foregroundStyle(DrumInk.muted)
            }
        }
        .multilineTextAlignment(.center)
        .padding(DrumSpace.unit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cellLabel(region: region, meal: meal, found: found))
    }

    private func cellLabel(region: BodyRegion, meal: String, found: PairingTrace?) -> String {
        guard let found else {
            return "\(meal) did not sit inside \(region.title) coda"
        }
        return "\(meal) sat inside \(region.title) coda, \(TraceFigures.score(Double(found.matched))) of \(TraceFigures.score(Double(found.totalSymptoms))) pulses"
    }

    private func list(_ names: [String]) -> String {
        var seen: [String] = []
        for name in names where !seen.contains(name) {
            seen.append(name)
        }
        switch seen.count {
        case 0: return ""
        case 1: return seen[0]
        case 2: return "\(seen[0]) and \(seen[1])"
        default:
            return seen.dropLast().joined(separator: ", ") + ", and " + seen[seen.count - 1]
        }
    }

    private var emptyState: some View {
        VStack(spacing: DrumSpace.unit * 2) {
            DrumArt(name: DrumArtName.emptyList)
                .frame(maxWidth: 280, maxHeight: 280)
                .frame(minHeight: 160)
            Text("No meal has sat in the same coda twice")
                .font(DrumType.heading)
                .foregroundStyle(DrumInk.ink)
                .multilineTextAlignment(.center)
            Text("Stamp a region, then bind that meal again.")
                .font(DrumType.body)
                .foregroundStyle(DrumInk.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: DrumSpace.unit)
            DrumFillButton(title: "Close", action: onClose)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ text: String) -> some View {
        VStack(spacing: DrumSpace.unit * 2) {
            Text("The report would not load.")
                .font(DrumType.heading)
                .foregroundStyle(DrumInk.ink)
            Text(text)
                .font(DrumType.body)
                .foregroundStyle(DrumInk.muted)
            DrumFillButton(title: "Retry", action: onRetry)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
