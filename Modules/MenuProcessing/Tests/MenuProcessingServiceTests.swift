import XCTest
@testable import MenuProcessing

final class MenuProcessingServiceTests: XCTestCase {
    func testMockServiceReturnsTemplate() async throws {
        let service = MockMenuProcessingService()
        let request = MenuProcessingRequest(pageCount: 2, recognizedText: "Sample OCR text")
        let template = try await service.submit(request)
        XCTAssertEqual(template.id, request.uploadID)
        XCTAssertEqual(template.sections.count, 4)
        XCTAssertEqual(template.sections.first?.dishes.first?.localizedName, "Tomato Bruschetta")
    }
}
