import XCTest
@testable import Hawthorn

/// Launch keys are arguments. today stays on Surprise. log and goals open other desks.
final class HawthornTests: XCTestCase {
    func testReviewScreenParser() {
        XCTAssertEqual(ReviewLaunch.desk(from: []), .surprise)
        XCTAssertEqual(ReviewLaunch.desk(from: ["-ReviewScreen"]), .surprise)
        XCTAssertEqual(ReviewLaunch.desk(from: ["-ReviewScreen", "today"]), .surprise)
        XCTAssertEqual(ReviewLaunch.desk(from: ["Hawthorn", "-ReviewScreen", "log"]), .bar)
        XCTAssertEqual(ReviewLaunch.desk(from: ["-ReviewScreen", "goals"]), .settings)
        XCTAssertEqual(ReviewLaunch.desk(from: ["-ReviewScreen", "discover"]), .discover)
        XCTAssertEqual(ReviewLaunch.desk(from: ["-ReviewScreen", "favorites"]), .favorites)
        XCTAssertEqual(ReviewLaunch.desk(from: ["-ReviewScreen", "other"]), .surprise)
    }
}
