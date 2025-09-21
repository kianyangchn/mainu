import XCTest
@testable import Capture

final class MenuCaptureCoordinatorTests: XCTestCase {
    func testAppendAddsPage() {
        var coordinator = MenuCaptureCoordinator()
        let page = CapturedPage(fileURL: URL(fileURLWithPath: "/tmp/page.jpg"))
        coordinator.append(page)
        XCTAssertEqual(coordinator.capturedPages.count, 1)
    }

    func testConcatenatedRecognizedTextJoinsEntries() {
        var coordinator = MenuCaptureCoordinator()
        let first = CapturedPage(
            fileURL: URL(fileURLWithPath: "/tmp/page1.jpg"),
            recognizedText: "First page text"
        )
        let second = CapturedPage(
            fileURL: URL(fileURLWithPath: "/tmp/page2.jpg"),
            recognizedText: "Second page text"
        )

        coordinator.append(first)
        coordinator.append(second)

        XCTAssertEqual(
            coordinator.concatenatedRecognizedText,
            "First page text\n\nSecond page text"
        )
    }
}
