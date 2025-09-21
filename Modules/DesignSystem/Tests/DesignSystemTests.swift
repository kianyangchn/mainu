import XCTest
@testable import DesignSystem

final class DesignSystemTests: XCTestCase {
    func testGradientHasTwoStops() {
        XCTAssertEqual(DesignSystem.primaryGradient.stops.count, 2)
    }
}
