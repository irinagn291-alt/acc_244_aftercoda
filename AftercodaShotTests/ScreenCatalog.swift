import SwiftUI
@testable import Aftercoda

enum ScreenCatalog {
    @MainActor
    static var shots: [(String, AnyView)] {
        [
            ("timeline", AnyView(TimelineView())),
            ("report", AnyView(ReportView())),
            ("settings", AnyView(SettingsView()))
        ]
    }
}
