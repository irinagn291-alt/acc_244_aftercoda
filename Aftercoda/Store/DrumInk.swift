import SwiftUI
import UIKit

/// Presentation. Named soot-drum colours. Hex lives only here.
enum DrumInk {
    static let backgroundHex = "#14110E"
    static let surfaceHex = "#2A241C"
    static let inkHex = "#EDE6D6"
    static let accentHex = "#C9B896"
    static let mutedHex = "#8C8274"

    static let background = Color(uiColor: named("background", r: 20, g: 17, b: 14))
    static let surface = Color(uiColor: named("surface", r: 42, g: 36, b: 28))
    static let ink = Color(uiColor: named("ink", r: 237, g: 230, b: 214))
    static let accent = Color(uiColor: named("accent", r: 201, g: 184, b: 150))
    static let muted = Color(uiColor: named("muted", r: 184, g: 174, b: 158)) // #B8AE9E fallback ≥ 4.5 on soot

    private static func named(_ name: String, r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        UIColor(named: name) ?? UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }
}

/// Presentation. Cochin scale. Six steps, none above 34 pt.
enum DrumType {
    static let title = Font.custom("Cochin-Bold", size: 28, relativeTo: .title)
    static let heading = Font.custom("Cochin-Bold", size: 22, relativeTo: .title2)
    static let mark = Font.custom("Cochin-Bold", size: 20, relativeTo: .title3)
    static let body = Font.custom("Cochin", size: 17, relativeTo: .body)
    static let callout = Font.custom("Cochin", size: 15, relativeTo: .callout)
    static let caption = Font.custom("Cochin", size: 13, relativeTo: .caption)
}

/// Presentation. 8 pt grid. Hard edges — teak, not a card radius.
enum DrumSpace {
    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
}

/// Presentation. Catalog names. Load only when UIImage(named:) is non-nil.
enum DrumArtName {
    static let emptyHome = "afc_EmptyHome"
    static let emptyList = "afc_EmptyList"
    static let card = "afc_CardBackdrop"
    static let control = "afc_ControlFace"
    static let twist = "afc_TwistHero"
    static let success = "afc_SuccessMark"
    static let header = "afc_HeaderDecor"
}

/// Presentation. Named art, or a Path plate. Never the yellow missing-image tile.
struct DrumArt: View {
    var name: String
    var fallback: DrumArtFallback = .drum

    var body: some View {
        Group {
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFit()
            } else {
                fallbackPlate
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var fallbackPlate: some View {
        switch fallback {
        case .none:
            EmptyView()
        case .drum:
            EmptyDrumMark()
                .stroke(DrumInk.accent, lineWidth: 3)
                .padding(DrumSpace.unit * 3)
                .background(DrumInk.surface)
        case .surface:
            DrumInk.surface
        }
    }
}

enum DrumArtFallback {
    case none
    case drum
    case surface
}

/// Presentation. Full-width chrome lives inside the label.
struct DrumFillButton: View {
    var title: String
    var ink: Color = DrumInk.background
    var fill: Color = DrumInk.accent
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DrumType.body)
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity, minHeight: DrumSpace.tap)
                .background(fill)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Presentation. In-body close so shots do not depend on a toolbar.
struct DrumCloseBar: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(DrumType.heading)
                .foregroundStyle(DrumInk.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Spacer(minLength: DrumSpace.unit)
            Button(action: onClose) {
                Text("Close")
                    .font(DrumType.body)
                    .foregroundStyle(DrumInk.ink)
                    .frame(minWidth: DrumSpace.tap, minHeight: DrumSpace.tap)
                    .padding(.horizontal, DrumSpace.unit)
                    .background(DrumInk.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
}
