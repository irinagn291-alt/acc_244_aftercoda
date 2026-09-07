import SwiftUI
import UIKit

/// Dial. Brief soot puncture after a successful stamp or bind. Reduce Motion keeps a fade.
struct SuccessStampView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var visible: Bool
    var fillsPage: Bool

    init(visible: Bool = true, fillsPage: Bool = true) {
        self.visible = visible
        self.fillsPage = fillsPage
    }

    var body: some View {
        ZStack {
            if fillsPage {
                DrumInk.background.ignoresSafeArea()
            }
            mark
                .opacity(visible ? 1 : 0)
                .animation(reduceMotion ? .easeOut(duration: 0.2) : DrumMotion.ease, value: visible)
        }
        .frame(maxWidth: fillsPage ? .infinity : nil, maxHeight: fillsPage ? .infinity : nil)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var mark: some View {
        ZStack {
            DrumInk.surface
            if UIImage(named: DrumArtName.success) != nil {
                Image(DrumArtName.success)
                    .resizable()
                    .scaledToFit()
                    .padding(DrumSpace.unit * 2)
            } else {
                SuccessCheckMark()
                    .stroke(
                        DrumInk.ink,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round)
                    )
                    .padding(28)
            }
        }
        .frame(width: 128, height: 128)
    }
}

struct SuccessCheckMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY + rect.height * 0.02))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.14))
        return path
    }
}

struct SuccessStampOverlay: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var visible: Bool

    func body(content: Content) -> some View {
        content.overlay {
            SuccessStampView(visible: visible, fillsPage: false)
                .animation(reduceMotion ? .easeOut(duration: 0.2) : DrumMotion.ease, value: visible)
        }
    }
}

enum DrumMotion {
    static let ease: Animation = .easeInOut(duration: 0.28)
}
