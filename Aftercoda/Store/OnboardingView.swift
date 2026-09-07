import SwiftUI

/// Store. Four pages. Skip still writes factory lookbacks and the completion flag.
struct OnboardingView: View {
    @ObservedObject var hub: DrumHub
    @State private var page = 0

    init(hub: DrumHub = DrumHub.preview(onboarded: false)) {
        self.hub = hub
    }

    var body: some View {
        VStack(spacing: DrumSpace.unit * 2) {
            plate
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: DrumSpace.unit) {
                DrumFillButton(title: page == 3 ? "Open the drum" : "Next") {
                    if page == 3 {
                        Task { await hub.completeOnboarding() }
                    } else {
                        page += 1
                    }
                }
                Button {
                    Task { await hub.completeOnboarding() }
                } label: {
                    Text("Skip")
                        .font(DrumType.body)
                        .foregroundStyle(DrumInk.ink)
                        .frame(maxWidth: .infinity, minHeight: DrumSpace.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DrumSpace.unit * 3)
        .padding(.vertical, DrumSpace.unit * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DrumInk.background.ignoresSafeArea())
    }

    @ViewBuilder
    private var plate: some View {
        switch page {
        case 0:
            pageView(
                image: "afc_Onboarding1",
                title: "The pulse opens a window",
                line: "Stamp a body region. That region’s own coda lights on the ring."
            )
        case 1:
            pageView(
                image: "afc_Onboarding2",
                title: "Stamp the epicenter",
                line: "Scrub the 24h ring or use now. Head, gut, and skin each keep a lookback."
            )
        case 2:
            pageView(
                image: "afc_Onboarding3",
                title: "Bind inside the coda",
                line: "A station joins only when it already sits in that sector. Comma splits stations."
            )
        default:
            pageView(
                image: DrumArtName.twist,
                title: "Two matches make a pairing",
                line: "Score is matched over total pulses. Fewer than two matches is dropped. Not calories."
            )
        }
    }

    private func pageView(image: String, title: String, line: String) -> some View {
        VStack(spacing: DrumSpace.unit * 2) {
            DrumArt(name: image)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 180)
            Text(title)
                .font(DrumType.heading)
                .foregroundStyle(DrumInk.ink)
                .multilineTextAlignment(.center)
            Text(line)
                .font(DrumType.body)
                .foregroundStyle(DrumInk.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
