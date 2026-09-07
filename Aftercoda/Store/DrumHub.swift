import Combine
import Foundation
import UIKit

/// Presentation. Sheets over the dial. The ring never leaves.
enum DrumSheet: String, Identifiable, Equatable, Sendable {
    case bind
    case report
    case settings
    case twist

    var id: String { rawValue }
}

/// Presentation. Load phase for the hub. Views do not talk to FileManager.
enum DrumPhase: Equatable, Sendable {
    case idle
    case loading
    case ready
    case failed(String)
}

/// Presentation. Owns today's meal stream ⋈ pulse stream. Views never compute the join.
@MainActor
final class DrumHub: ObservableObject {
    @Published var day: DayTrace
    @Published var settings: DrumSettings
    @Published var phase: DrumPhase
    @Published var warning: DrumLoadWarning?
    @Published var showSpinner: Bool
    @Published var selectedRegion: BodyRegion?
    @Published var selectedPulseID: UUID?
    @Published var scrubHour: Double
    @Published var sheet: DrumSheet?
    @Published var showsOnboarding: Bool
    @Published var bindDraft: String
    @Published var bindFailure: BindFailure?
    @Published var actionInFlight: Bool
    @Published var errorMessage: String?

    private let store: any TraceStoring
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private let arguments: [String]
    private let loadsFromStore: Bool
    private var reviewConsumed = false
    private var didOnboard = false

    var lookbacks: [BodyRegion: Double] {
        Dictionary(uniqueKeysWithValues: BodyRegion.allCases.map { ($0, settings.hours(for: $0)) })
    }

    var pairings: [PairingTrace] {
        WindowJoin.pairings(on: day, lookbacks: lookbacks)
    }

    var exploded: ExplodedBinding {
        BindProgress.measure(day: day, lookbacks: lookbacks)
    }

    var selectedPulse: PulseTrace? {
        day.pulses.first { $0.id == selectedPulseID }
    }

    var coda: CodaWindow? {
        if let pulse = selectedPulse {
            return WindowJoin.window(for: pulse, lookbackHours: settings.hours(for: pulse.region))
        }
        guard let region = selectedRegion else { return nil }
        return CodaWindow(
            pulseAt: dateOnToday(hour: scrubHour),
            lookbackHours: settings.hours(for: region)
        )
    }

    var eligibleStations: [StationRecord] {
        guard let pulse = selectedPulse else { return [] }
        return WindowJoin.eligibleStations(
            for: pulse,
            in: day.stations,
            lookbackHours: settings.hours(for: pulse.region)
        )
    }

    var isEmpty: Bool {
        day.stations.isEmpty && day.pulses.isEmpty
    }

    var contactURL: URL {
        URL(string: "https://aftercoda.pro/contact-us")!
    }

    init(
        store: any TraceStoring,
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() },
        arguments: [String] = ProcessInfo.processInfo.arguments,
        skipLoad: Bool = false
    ) {
        self.store = store
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
        self.arguments = arguments
        self.loadsFromStore = !skipLoad
        self.day = DayTrace.empty(on: now(), calendar: calendar)
        self.settings = .factory
        self.phase = skipLoad ? .ready : .idle
        self.warning = nil
        self.showSpinner = false
        self.selectedRegion = nil
        self.selectedPulseID = nil
        self.scrubHour = RingHour.of(now(), calendar: calendar).value
        self.sheet = nil
        self.showsOnboarding = false
        self.bindDraft = ""
        self.bindFailure = nil
        self.actionInFlight = false
        self.errorMessage = nil
    }

    static func live() -> DrumHub {
        let directory: URL
        do {
            directory = try TraceStore.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("Aftercoda/Days", isDirectory: true)
        }
        return DrumHub(store: TraceStore(directory: directory))
    }

    static func preview(
        day: DayTrace? = nil,
        warning: DrumLoadWarning? = nil,
        onboarded: Bool = true,
        arguments: [String] = []
    ) -> DrumHub {
        let calendar = Calendar.current
        let origin = calendar.startOfDay(for: Date())
        let resolved = day ?? DrumSeed.day(on: origin, calendar: calendar)
        let store = MemoryTraceStore(days: [resolved], settings: .factory, warning: warning)
        let suite = "afc.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.set(onboarded, forKey: PreferenceKey.onboardingComplete)
        let hub = DrumHub(
            store: store,
            defaults: defaults,
            calendar: calendar,
            now: { Date() },
            arguments: arguments,
            skipLoad: true
        )
        hub.day = resolved
        hub.settings = .factory
        hub.warning = warning
        hub.didOnboard = onboarded
        hub.showsOnboarding = !onboarded
        hub.phase = .ready
        if let first = resolved.pulses.first {
            hub.selectedPulseID = first.id
            hub.selectedRegion = first.region
            hub.scrubHour = RingHour.of(first.stampedAt, calendar: calendar).value
        }
        if onboarded {
            hub.applyReviewHookOnce()
        }
        return hub
    }

    func bootstrap() async {
        guard loadsFromStore else { return }
        await reload(seed: true)
    }

    func retry() async {
        await reload(seed: false)
    }

    func flush() async {
        do {
            try await store.flush()
        } catch {
            errorMessage = "The drum could not save. Try again."
        }
    }

    func noteDayBoundary() {
        let key = DayKey.milliseconds(for: now(), calendar: calendar)
        guard key != day.dayKey else { return }
        Task { await reloadToday() }
    }

    func useNow() {
        scrubHour = RingHour.of(now(), calendar: calendar).value
    }

    func select(region: BodyRegion) {
        selectedRegion = region
        if let pulse = day.pulses.first(where: { $0.region == region }) {
            selectedPulseID = pulse.id
            scrubHour = RingHour.of(pulse.stampedAt, calendar: calendar).value
        } else {
            selectedPulseID = nil
        }
    }

    func select(pulseID: UUID) {
        selectedPulseID = pulseID
        if let pulse = day.pulses.first(where: { $0.id == pulseID }) {
            selectedRegion = pulse.region
            scrubHour = RingHour.of(pulse.stampedAt, calendar: calendar).value
        }
    }

    func stampSelected() async {
        let region = selectedRegion ?? .head
        selectedRegion = region
        await stamp(region: region, at: dateOnToday(hour: scrubHour))
    }

    func stampNow() async {
        useNow()
        await stampSelected()
    }

    func stamp(region: BodyRegion, at date: Date) async {
        guard !actionInFlight else { return }
        actionInFlight = true
        defer { actionInFlight = false }
        var next = alignedDay(for: date)
        let pulse = EpicenterStamp.make(region: region, at: date)
        next = next.adding(pulse)
        do {
            try await store.save(next)
            day = next
            selectedRegion = region
            selectedPulseID = pulse.id
            scrubHour = RingHour.of(date, calendar: calendar).value
            errorMessage = nil
            commitHaptic()
        } catch {
            errorMessage = "The drum could not keep that stamp."
        }
    }

    func sew(stationID: UUID) async {
        guard let pulse = selectedPulse else { return }
        guard !actionInFlight else { return }
        actionInFlight = true
        defer { actionInFlight = false }
        do {
            let hours = settings.hours(for: pulse.region)
            let next = try WindowJoin.bind(
                stationID: stationID,
                pulseID: pulse.id,
                on: day,
                lookbackHours: hours
            )
            try await store.save(next)
            day = next
            bindFailure = nil
            errorMessage = nil
            commitHaptic()
        } catch let failure as BindFailure {
            bindFailure = failure
        } catch {
            errorMessage = "The drum could not keep that bind."
        }
    }

    func sewDraft() async {
        let incoming = MealPipeline.stations(from: bindDraft, at: dateOnToday(hour: scrubHour))
        guard !incoming.isEmpty else { return }
        guard let pulse = selectedPulse else { return }
        guard !actionInFlight else { return }
        actionInFlight = true
        defer { actionInFlight = false }
        var next = day.adding(stations: incoming)
        let hours = settings.hours(for: pulse.region)
        var sewnAny = false
        for station in incoming {
            guard let current = next.pulses.first(where: { $0.id == pulse.id }) else { continue }
            do {
                let sewn = try WindowJoin.bind(station: station, onto: current, lookbackHours: hours)
                next = next.replacing(sewn)
                sewnAny = true
            } catch let failure as BindFailure {
                bindFailure = failure
            } catch {
                bindFailure = .outsideCoda
            }
        }
        do {
            try await store.save(next)
            day = next
            if sewnAny {
                bindDraft = ""
                errorMessage = nil
                commitHaptic()
            }
        } catch {
            errorMessage = "The drum could not keep that bind."
        }
    }

    func retune(_ region: BodyRegion, hours: Double) {
        settings = settings.retuning(region, hours: hours)
    }

    func persistSettings() async {
        do {
            try await store.saveSettings(settings)
            errorMessage = nil
        } catch {
            errorMessage = "The drum could not keep those lookbacks."
        }
    }

    func completeOnboarding() async {
        settings = .factory
        try? await store.saveSettings(settings)
        defaults.set(true, forKey: PreferenceKey.onboardingComplete)
        didOnboard = true
        showsOnboarding = false
        applyReviewHookOnce()
    }

    func rerunOnboarding() {
        sheet = nil
        showsOnboarding = true
    }

    func resetAll() async {
        guard !actionInFlight else { return }
        actionInFlight = true
        defer { actionInFlight = false }
        do {
            try await store.resetAllData()
            defaults.removeObject(forKey: PreferenceKey.onboardingComplete)
            day = DayTrace.empty(on: now(), calendar: calendar)
            settings = .factory
            warning = nil
            selectedRegion = nil
            selectedPulseID = nil
            bindDraft = ""
            bindFailure = nil
            errorMessage = nil
            sheet = nil
            didOnboard = false
            showsOnboarding = true
            reviewConsumed = true
        } catch {
            errorMessage = "The drum could not reset."
        }
    }

    func open(_ next: DrumSheet) {
        bindFailure = nil
        sheet = next
    }

    func reportText() -> String {
        var lines = ["Aftercoda pairing report"]
        if pairings.isEmpty {
            lines.append("No pairing has two matches yet.")
        } else {
            for pairing in pairings {
                let matched = TraceFigures.score(Double(pairing.matched))
                let total = TraceFigures.score(Double(pairing.totalSymptoms))
                let score = TraceFigures.score(pairing.score)
                lines.append(
                    "\(pairing.region.rawValue) × \(pairing.stationLabel)  \(matched)/\(total)  \(score)"
                )
            }
        }
        lines.append("A counted pairing, not a diagnosis.")
        return lines.joined(separator: "\n")
    }

    func applyReviewHookOnce() {
        guard !reviewConsumed else { return }
        guard didOnboard else { return }
        reviewConsumed = true
        guard let screen = ReviewHook.pending(in: arguments) else { return }
        switch screen {
        case .today:
            break
        case .log:
            sheet = .report
        case .goals:
            sheet = .settings
        }
    }

    func dateOnToday(hour: Double) -> Date {
        let origin = calendar.startOfDay(for: now())
        let clamped = min(max(hour, 0), 23.999)
        return origin.addingTimeInterval(clamped * 3600)
    }

    private func alignedDay(for date: Date) -> DayTrace {
        let key = DayKey.milliseconds(for: date, calendar: calendar)
        if day.dayKey == key {
            return day
        }
        return DayTrace.empty(on: date, calendar: calendar)
    }

    private func reload(seed: Bool) async {
        phase = .loading
        showSpinner = false
        let spinner = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !Task.isCancelled, phase == .loading {
                showSpinner = true
            }
        }
        do {
            if seed {
                try await store.seedDemoIfNeeded()
            }
            let loaded = await store.load()
            warning = loaded.warning
            settings = await store.settings()
            applyLoaded(loaded.days)
            didOnboard = defaults.bool(forKey: PreferenceKey.onboardingComplete)
            showsOnboarding = !didOnboard
            phase = .ready
            errorMessage = nil
            if didOnboard {
                applyReviewHookOnce()
            }
        } catch {
            phase = .failed("The drum could not read today's traces.")
        }
        spinner.cancel()
        showSpinner = false
    }

    private func reloadToday() async {
        let loaded = await store.load()
        applyLoaded(loaded.days)
    }

    private func applyLoaded(_ days: [DayTrace]) {
        let key = DayKey.milliseconds(for: now(), calendar: calendar)
        if let existing = days.first(where: { $0.dayKey == key }) {
            day = existing
        } else {
            day = DayTrace.empty(on: now(), calendar: calendar)
        }
        if selectedPulseID == nil, let first = day.pulses.first {
            selectedPulseID = first.id
            selectedRegion = first.region
        }
    }

    private func commitHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

@MainActor
enum DrumFixtures {
    static let populated = DrumHub.preview()
    static let empty = DrumHub.preview(day: .empty(on: Date()))
}
