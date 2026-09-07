import SwiftUI
import UIKit

/// Dial. Sector fills and traces as Path. The UIControl only owns gestures.
struct RingFace: View {
    var hour: Double
    var dayStart: Date
    var stations: [StationRecord]
    var pulses: [PulseTrace]
    var coda: CodaWindow?
    var codaTitle: String
    var calendar: Calendar
    var onSelectPulse: (UUID) -> Void

    init(
        hour: Double,
        dayStart: Date,
        stations: [StationRecord],
        pulses: [PulseTrace],
        coda: CodaWindow?,
        codaTitle: String = "",
        calendar: Calendar,
        onSelectPulse: @escaping (UUID) -> Void
    ) {
        self.hour = hour
        self.dayStart = dayStart
        self.stations = stations
        self.pulses = pulses
        self.coda = coda
        self.codaTitle = codaTitle
        self.calendar = calendar
        self.onSelectPulse = onSelectPulse
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                if UIImage(named: DrumArtName.control) != nil {
                    Image(DrumArtName.control)
                        .resizable()
                        .scaledToFit()
                        .opacity(0.28)
                        .accessibilityHidden(true)
                }
                RingOutline()
                    .stroke(DrumInk.muted, lineWidth: 2)
                if let coda {
                    let startHour = RingHour.of(coda.opensAt, calendar: calendar).value
                    let endHour = RingHour.of(coda.pulseAt, calendar: calendar).value
                    CodaSector(startHour: startHour, endHour: endHour)
                        .fill(DrumInk.accent.opacity(0.42))
                    CodaSector(startHour: startHour, endHour: endHour)
                        .stroke(DrumInk.accent, lineWidth: 3)
                    if !codaTitle.isEmpty {
                        PolarCaption(
                            hour: midHour(start: startHour, end: endHour),
                            radius: 0.78,
                            text: codaTitle,
                            ink: DrumInk.ink
                        )
                    }
                }
                ForEach(stations) { station in
                    StationMark(hour: RingHour.of(station.stampedAt, calendar: calendar).value)
                        .fill(DrumInk.ink)
                        .accessibilityLabel("Station \(station.label)")
                }
                ForEach(mealCaptions()) { caption in
                    PolarCaption(hour: caption.hour, radius: 0.64, text: caption.title, ink: DrumInk.ink)
                }
                ForEach(pulses) { pulse in
                    let markHour = RingHour.of(pulse.stampedAt, calendar: calendar).value
                    PulseMark(hour: markHour)
                        .fill(DrumInk.accent)
                        .contentShape(PulseMark(hour: markHour))
                        .onTapGesture { onSelectPulse(pulse.id) }
                        .accessibilityLabel("Pulse \(pulse.region.title)")
                        .accessibilityAddTraits(.isButton)
                    PolarCaption(hour: markHour, radius: 0.54, text: pulse.region.title, ink: DrumInk.accent)
                }
                StylusNeedle(hour: hour)
                    .stroke(DrumInk.ink, lineWidth: 2)
                HourLabels()
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
    }

    private func mealCaptions() -> [RingCaption] {
        let grouped = Dictionary(grouping: stations) { station in
            Int((RingHour.of(station.stampedAt, calendar: calendar).value * 2).rounded())
        }
        return grouped.values.map { group in
            let hour = RingHour.of(group[0].stampedAt, calendar: calendar).value
            var names: [String] = []
            for label in group.map(\.label) where !names.contains(label) {
                names.append(label)
            }
            return RingCaption(id: "meal-\(hour)-\(names.joined())", hour: hour, title: names.joined(separator: " · "))
        }
    }

    private func midHour(start: Double, end: Double) -> Double {
        var first = start.truncatingRemainder(dividingBy: 24)
        if first < 0 { first += 24 }
        var last = end.truncatingRemainder(dividingBy: 24)
        if last < 0 { last += 24 }
        if last < first { last += 24 }
        return ((first + last) / 2).truncatingRemainder(dividingBy: 24)
    }
}

private struct RingCaption: Identifiable {
    var id: String
    var hour: Double
    var title: String
}

private struct PolarCaption: View {
    var hour: Double
    var radius: CGFloat
    var text: String
    var ink: Color

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let reach = min(geo.size.width, geo.size.height) / 2 * radius
            let angle = RingGeometry.angle(for: hour).radians
            Text(text)
                .font(DrumType.callout)
                .foregroundStyle(ink)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
                .frame(width: 86)
                .position(
                    x: center.x + CGFloat(cos(angle)) * reach,
                    y: center.y + CGFloat(sin(angle)) * reach
                )
        }
        .allowsHitTesting(false)
    }
}

struct RingOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = min(rect.width, rect.height) * 0.08
        return Path(ellipseIn: rect.insetBy(dx: inset, dy: inset))
    }
}

struct CodaSector: Shape {
    var startHour: Double
    var endHour: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let outer = radius * 0.92
        let inner = radius * 0.68
        var start = startHour.truncatingRemainder(dividingBy: 24)
        if start < 0 { start += 24 }
        var end = endHour.truncatingRemainder(dividingBy: 24)
        if end < 0 { end += 24 }
        if end < start { end += 24 }
        let startAngle = RingGeometry.angle(for: start)
        let endAngle = RingGeometry.angle(for: end)
        path.addArc(center: center, radius: outer, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}

struct StylusNeedle: Shape {
    var hour: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let angle = RingGeometry.angle(for: hour).radians
        let tip = CGPoint(
            x: center.x + cos(angle) * radius * 0.9,
            y: center.y + sin(angle) * radius * 0.9
        )
        path.move(to: center)
        path.addLine(to: tip)
        return path
    }
}

struct StationMark: Shape {
    var hour: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.8
        let angle = RingGeometry.angle(for: hour).radians
        let point = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
        return Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
    }
}

struct PulseMark: Shape {
    var hour: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.86
        let angle = RingGeometry.angle(for: hour).radians
        let point = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
        var path = Path()
        path.move(to: CGPoint(x: point.x, y: point.y - 6))
        path.addLine(to: CGPoint(x: point.x + 5, y: point.y + 4))
        path.addLine(to: CGPoint(x: point.x - 5, y: point.y + 4))
        path.closeSubpath()
        return path
    }
}

private struct HourLabels: View {
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 * 0.58
            ForEach([0, 6, 12, 18], id: \.self) { mark in
                let angle = RingGeometry.angle(for: Double(mark)).radians
                Text(TraceFigures.hours(Double(mark)))
                    .font(DrumType.caption)
                    .foregroundStyle(DrumInk.muted)
                    .position(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius
                    )
            }
        }
        .allowsHitTesting(false)
    }
}
