import XCTest
@testable import Aftercoda

/// Placeholder. Replace with the cases required by SPEC.md section 17.
final class AftercodaTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: AftercodaApp.self), "AftercodaApp")
    }
}
