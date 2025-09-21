import XCTest
@testable import Analytics

final class AnalyticsTests: XCTestCase {
    func testEventsAreEquatable() {
        let menuID = UUID()
        XCTAssertEqual(AnalyticsEvent.menuScanned(menuID: menuID), .menuScanned(menuID: menuID))
    }
}
