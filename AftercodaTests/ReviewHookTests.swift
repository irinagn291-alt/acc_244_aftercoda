import XCTest
@testable import Aftercoda

final class ReviewHookTests: XCTestCase {
    func test_readsTodayLogGoals() {
        XCTAssertEqual(ReviewHook.pending(in: ["-ReviewScreen", "today"]), .today)
        XCTAssertEqual(ReviewHook.pending(in: ["-ReviewScreen", "log"]), .log)
        XCTAssertEqual(ReviewHook.pending(in: ["-ReviewScreen", "goals"]), .goals)
    }

    func test_missingOrUnknownIsNil() {
        XCTAssertNil(ReviewHook.pending(in: []))
        XCTAssertNil(ReviewHook.pending(in: ["-ReviewScreen"]))
        XCTAssertNil(ReviewHook.pending(in: ["-ReviewScreen", "charts"]))
        XCTAssertNil(ReviewHook.pending(in: ["other"]))
    }
}
