import SwiftUI
import UIKit

/// Dial. Hour from a point on the 24h ring. Midnight sits at the top, clockwise.
enum RingGeometry {
    static func hour(from point: CGPoint, in bounds: CGRect) -> Double {
        let dx = point.x - bounds.midX
        let dy = point.y - bounds.midY
        var degrees = atan2(dy, dx) * 180 / .pi
        degrees += 90
        if degrees < 0 { degrees += 360 }
        return (degrees / 360) * 24
    }

    static func angle(for hour: Double) -> Angle {
        .degrees(hour / 24 * 360 - 90)
    }
}

/// Dial. The only UIKit surface. Pan scrubs the hour; tap stamps now.
@MainActor
final class RingControl: UIControl {
    var hour: Double = 0 {
        didSet {
            if abs(hour - oldValue) > 0.0001 {
                sendActions(for: .valueChanged)
            }
        }
    }

    var onNowStamp: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isAccessibilityElement = true
        accessibilityLabel = "Twenty-four hour ring"
        accessibilityHint = "Scrub to choose an hour. Double tap stamps now."
        accessibilityTraits.insert(.adjustable)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(pan)
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override var accessibilityValue: String? {
        get { TraceFigures.hours(hour) }
        set {}
    }

    override func accessibilityIncrement() {
        hour = min(hour + 0.25, 23.75)
    }

    override func accessibilityDecrement() {
        hour = max(hour - 0.25, 0)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let radius = min(bounds.width, bounds.height) / 2
        let distance = hypot(point.x - bounds.midX, point.y - bounds.midY)
        return distance >= radius * 0.62 && distance <= radius
    }

    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: self)
        hour = RingGeometry.hour(from: point, in: bounds)
    }

    @objc
    private func handleTap(_ _: UITapGestureRecognizer) {
        onNowStamp?()
    }
}

/// Dial. SwiftUI host for the polar UIControl. Drawing stays in Path/Shape.
struct RingHost: UIViewRepresentable {
    @Binding var hour: Double
    var onNowStamp: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(hour: $hour, onNowStamp: onNowStamp)
    }

    func makeUIView(context: Context) -> RingControl {
        let control = RingControl()
        control.hour = hour
        control.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        control.onNowStamp = { [weak coordinator = context.coordinator] in
            coordinator?.onNowStamp()
        }
        return control
    }

    func updateUIView(_ control: RingControl, context: Context) {
        context.coordinator.hour = $hour
        context.coordinator.onNowStamp = onNowStamp
        if abs(control.hour - hour) > 0.0001 {
            control.hour = hour
        }
        control.onNowStamp = { [weak coordinator = context.coordinator] in
            coordinator?.onNowStamp()
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var hour: Binding<Double>
        var onNowStamp: () -> Void

        init(hour: Binding<Double>, onNowStamp: @escaping () -> Void) {
            self.hour = hour
            self.onNowStamp = onNowStamp
        }

        @objc
        func changed(_ sender: RingControl) {
            hour.wrappedValue = sender.hour
        }
    }
}
