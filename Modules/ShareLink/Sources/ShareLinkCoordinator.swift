import Foundation

public struct MenuShareLink: Equatable, Sendable {
    public let url: URL
    public let expiresAt: Date

    public init(url: URL, expiresAt: Date) {
        self.url = url
        self.expiresAt = expiresAt
    }
}

public protocol ShareLinkGenerating: Sendable {
    func generateShareLink(menuID: UUID) async throws -> MenuShareLink
}

public final class MockShareLinkGenerator: ShareLinkGenerating, @unchecked Sendable {
    public init() {}

    public func generateShareLink(menuID: UUID) async throws -> MenuShareLink {
        let url = URL(string: "https://mainu.app/share/\(menuID.uuidString)")!
        return MenuShareLink(url: url, expiresAt: Date().addingTimeInterval(60 * 60 * 24))
    }
}

public extension MenuShareLink {
    var expiresDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: expiresAt, relativeTo: Date())
    }
}

extension MenuShareLink: Identifiable {
    public var id: URL { url }
}
