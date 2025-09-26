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

    func testProxyServiceParsesBackendMenu() async throws {
        let expectation = expectation(description: "backend called")

        let backendMenuString = """
        {
          "items": [
            {
              "original_name": "Garlic Bread",
              "translated_name": "蒜香面包",
              "description": "香脆的蒜香烤面包",
              "category": "Antipasti",
              "allergens": "Gluten, Dairy",
              "recommended_pairing": "House prosecco"
            },
            {
              "original_name": "Tiramisu",
              "translated_name": "提拉米苏",
              "description": "经典意大利甜点",
              "category": "Dolci",
              "spice_level": "none"
            }
          ]
        }
        """

        let responseObject: [String: Any] = [
            "output": [
                ["content": [["text": "\u200b"]]],
                ["content": [["text": backendMenuString]]]
            ]
        ]
        let responseData = try JSONSerialization.data(withJSONObject: responseObject, options: [])

        let service = ProxyMenuProcessingService(
            token: "test-token",
            performRequest: { request in
                expectation.fulfill()
                XCTAssertEqual(request.httpMethod, "POST")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (responseData, response)
            },
            logger: { _ in }
        )

        let request = MenuProcessingRequest(
            pageCount: 1,
            recognizedText: "Garlic bread",
            languageIn: "it",
            languageOut: "zh"
        )

        let template = try await service.submit(request)
        await fulfillment(of: [expectation], timeout: 0.1)

        XCTAssertEqual(template.id, request.uploadID)
        XCTAssertEqual(template.sections.count, 2)
        XCTAssertEqual(template.sections.first?.title, "Antipasti")
        XCTAssertEqual(template.sections.first?.dishes.count, 1)
        XCTAssertEqual(template.sections.first?.dishes.first?.localizedName, "蒜香面包")
        XCTAssertEqual(template.sections.first?.dishes.first?.allergens, ["Gluten", "Dairy"])
        XCTAssertEqual(template.sections.last?.title, "Dolci")
        XCTAssertEqual(template.sections.last?.dishes.first?.spiceLevel, .none)
    }
}
