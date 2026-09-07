import SwiftUI

/// Pulse pipeline. Anatomical figure on Timeline. Region owns the coda; colour is not the only signal.
struct BodyMapView: View {
    var selected: BodyRegion?
    var pulses: [PulseTrace]
    var lookbacks: [BodyRegion: Double]
    var failure: String?
    var onSelect: (BodyRegion) -> Void
    var onRetry: () -> Void
    var fillsCanvas: Bool
    var showsFigure: Bool
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(
        selected: BodyRegion? = nil,
        pulses: [PulseTrace] = [],
        lookbacks: [BodyRegion: Double] = DrumSettings.factory.lookbackHours,
        failure: String? = nil,
        onSelect: @escaping (BodyRegion) -> Void = { _ in },
        onRetry: @escaping () -> Void = {},
        fillsCanvas: Bool = true,
        showsFigure: Bool = true
    ) {
        self.selected = selected
        self.pulses = pulses
        self.lookbacks = lookbacks
        self.failure = failure
        self.onSelect = onSelect
        self.onRetry = onRetry
        self.fillsCanvas = fillsCanvas
        self.showsFigure = showsFigure
    }

    init() {
        let day = DrumSeed.day(on: Date())
        self.selected = .head
        self.pulses = day.pulses
        self.lookbacks = DrumSettings.factory.lookbackHours
        self.failure = nil
        self.onSelect = { _ in }
        self.onRetry = {}
        self.fillsCanvas = true
        self.showsFigure = true
    }

    var body: some View {
        VStack(spacing: DrumSpace.unit * 2) {
            if let failure {
                VStack(spacing: DrumSpace.unit) {
                    Text("The figure would not load.")
                        .font(DrumType.body)
                        .foregroundStyle(DrumInk.ink)
                    Text(failure)
                        .font(DrumType.callout)
                        .foregroundStyle(DrumInk.muted)
                    DrumFillButton(title: "Retry", action: onRetry)
                }
            } else {
                if showsFigure {
                    figure
                        .frame(width: 120, height: 160)
                        .scaleEffect(x: figureSize.width / 120, y: figureSize.height / 160)
                        .frame(width: figureSize.width, height: figureSize.height)
                        .frame(maxWidth: fillsCanvas ? .infinity : nil, maxHeight: fillsCanvas ? .infinity : nil)
                        .accessibilityHidden(true)
                }
                if pulses.isEmpty {
                    Text("No epicenter yet")
                        .font(DrumType.caption)
                        .foregroundStyle(DrumInk.muted)
                }
                HStack(spacing: DrumSpace.unit) {
                    ForEach(BodyRegion.allCases, id: \.self) { region in
                        Button {
                            onSelect(region)
                        } label: {
                            VStack(spacing: 2) {
                                Text(region.title)
                                    .font(DrumType.caption)
                                Text("\(TraceFigures.hours(hours(for: region))) h")
                                    .font(DrumType.caption)
                            }
                            .foregroundStyle(selected == region ? DrumInk.background : DrumInk.ink)
                            .frame(maxWidth: .infinity, minHeight: DrumSpace.tap)
                            .background(selected == region ? DrumInk.accent : DrumInk.surface)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(region.title), lookback \(TraceFigures.hours(hours(for: region))) hours")
                        .accessibilityAddTraits(selected == region ? .isSelected : [])
                    }
                }
            }
        }
        .padding(fillsCanvas ? DrumSpace.unit * 2 : 0)
        .frame(maxWidth: .infinity, maxHeight: fillsCanvas ? .infinity : nil)
        .background(fillsCanvas ? DrumInk.background.ignoresSafeArea() : nil)
    }

    private var figure: some View {
        ZStack {
            SkinOutline()
                .stroke(selected == .skin ? DrumInk.accent : DrumInk.ink, lineWidth: selected == .skin ? 3 : 1.5)
            GutMass()
                .fill(selected == .gut ? DrumInk.accent.opacity(0.45) : DrumInk.surface)
            HeadMass()
                .fill(selected == .head ? DrumInk.accent.opacity(0.45) : DrumInk.surface)
            HeadMass()
                .stroke(selected == .head ? DrumInk.ink : DrumInk.muted, lineWidth: 1.5)
            GutMass()
                .stroke(selected == .gut ? DrumInk.ink : DrumInk.muted, lineWidth: 1.5)
        }
    }

    private var figureSize: CGSize {
        if !fillsCanvas {
            return CGSize(width: 120, height: 160)
        }
        if sizeClass == .regular {
            return CGSize(width: 280, height: 380)
        }
        return CGSize(width: 180, height: 240)
    }

    private func hours(for region: BodyRegion) -> Double {
        CodaWindow.clamp(lookbacks[region] ?? region.factoryLookbackHours)
    }
}

extension BodyRegion {
    var title: String {
        switch self {
        case .head: "Head"
        case .gut: "Gut"
        case .skin: "Skin"
        }
    }
}

struct HeadMass: Shape {
    func path(in rect: CGRect) -> Path {
        let box = CGRect(x: rect.midX - 18, y: rect.minY + 4, width: 36, height: 36)
        return Path(ellipseIn: box)
    }
}

struct GutMass: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: rect.midX - 22, y: rect.minY + 44, width: 44, height: 52),
            cornerSize: .zero
        )
        return path
    }
}

struct SkinOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.midX - 20, y: rect.minY + 2, width: 40, height: 40))
        path.addRect(CGRect(x: rect.midX - 24, y: rect.minY + 42, width: 48, height: 70))
        path.move(to: CGPoint(x: rect.midX - 24, y: rect.minY + 50))
        path.addLine(to: CGPoint(x: rect.minX + 8, y: rect.minY + 88))
        path.move(to: CGPoint(x: rect.midX + 24, y: rect.minY + 50))
        path.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.minY + 88))
        path.move(to: CGPoint(x: rect.midX - 12, y: rect.minY + 112))
        path.addLine(to: CGPoint(x: rect.midX - 16, y: rect.maxY - 4))
        path.move(to: CGPoint(x: rect.midX + 12, y: rect.minY + 112))
        path.addLine(to: CGPoint(x: rect.midX + 16, y: rect.maxY - 4))
        return path
    }
}
