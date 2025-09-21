import Foundation

public struct MenuCaptureCoordinator: Sendable {
    public private(set) var capturedPages: [CapturedPage]

    public init(capturedPages: [CapturedPage] = []) {
        self.capturedPages = capturedPages
    }

    public var pageCount: Int {
        capturedPages.count
    }

    public var concatenatedRecognizedText: String {
        capturedPages
            .compactMap { $0.recognizedText?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    public mutating func append(_ page: CapturedPage) {
        capturedPages.append(page)
    }

    public mutating func remove(_ page: CapturedPage) {
        capturedPages.removeAll { candidate in
            if candidate.id == page.id {
                MenuCaptureStorage.removeFile(at: candidate.fileURL)
                return true
            }
            return false
        }
    }

    public mutating func reset() {
        capturedPages.forEach { MenuCaptureStorage.removeFile(at: $0.fileURL) }
        capturedPages.removeAll()
    }
}

public struct CapturedPage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let fileURL: URL
    public let createdAt: Date
    public let recognizedText: String?

    public init(
        id: UUID = UUID(),
        fileURL: URL,
        createdAt: Date = .init(),
        recognizedText: String? = nil
    ) {
        self.id = id
        self.fileURL = fileURL
        self.createdAt = createdAt
        self.recognizedText = recognizedText
    }
}

public extension CapturedPage {
    static func mock(index: Int, recognizedText: String? = nil) -> CapturedPage {
        let url = URL(fileURLWithPath: "/tmp/mainu-capture-page-\(index).jpg")
        return CapturedPage(fileURL: url, recognizedText: recognizedText)
    }
}
