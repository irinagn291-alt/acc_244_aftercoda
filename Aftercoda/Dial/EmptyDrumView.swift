import SwiftUI

/// Dial. Empty Timeline: art, one headline, one line, one CTA to stamp.
struct EmptyDrumView: View {
    var onStamp: () -> Void
    var fillsPage: Bool

    init(fillsPage: Bool = true, onStamp: @escaping () -> Void = {}) {
        self.fillsPage = fillsPage
        self.onStamp = onStamp
    }

    var body: some View {
        VStack(spacing: DrumSpace.unit * 2) {
            DrumArt(name: DrumArtName.emptyHome)
                .frame(maxWidth: fillsPage ? 280 : 160, maxHeight: fillsPage ? 280 : 160)
                .frame(minHeight: fillsPage ? 160 : 120)
            Text("The drum is blank")
                .font(DrumType.heading)
                .foregroundStyle(DrumInk.ink)
                .multilineTextAlignment(.center)
            Text("Stamp a pulse or bind a station.")
                .font(DrumType.body)
                .foregroundStyle(DrumInk.muted)
                .multilineTextAlignment(.center)
            if fillsPage {
                Spacer(minLength: DrumSpace.unit)
            }
            DrumFillButton(title: "Stamp epicenter", action: onStamp)
        }
        .padding(DrumSpace.unit * 2)
        .frame(maxWidth: .infinity, maxHeight: fillsPage ? .infinity : nil)
        .background(fillsPage ? DrumInk.background.ignoresSafeArea() : nil)
    }
}

struct EmptyDrumMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect.insetBy(dx: 8, dy: 8))
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + 12))
        return path
    }
}
