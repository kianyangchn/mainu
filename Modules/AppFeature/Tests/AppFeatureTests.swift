import XCTest
@testable import AppFeature

final class AppFeatureTests: XCTestCase {
    func testEnvironmentDefaults() {
        let environment = AppEnvironment()
        XCTAssertNotNil(environment.analytics)
    }

    func testShareLinkGenerator() async throws {
        let environment = AppEnvironment()
        let link = try await environment.shareLinkGenerator.generateShareLink(menuID: UUID())
        XCTAssertGreaterThan(link.expiresAt.timeIntervalSinceNow, 0)
    }
}
