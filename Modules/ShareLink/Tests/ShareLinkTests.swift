import XCTest
@testable import ShareLink

final class ShareLinkTests: XCTestCase {
    func testMockGeneratorCreatesLink() async throws {
        let generator = MockShareLinkGenerator()
        let link = try await generator.generateShareLink(menuID: UUID())
        XCTAssertGreaterThan(link.expiresAt.timeIntervalSinceNow, 0)
    }
}
