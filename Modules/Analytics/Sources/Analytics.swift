import Foundation

public protocol AnalyticsTracking {
    func track(event: AnalyticsEvent)
}

public enum AnalyticsEvent: Equatable {
    case menuScanned(menuID: UUID)
    case shareLinkCreated(menuID: UUID)
    case orderFinalized(items: Int)
}

public final class NoopAnalyticsTracker: AnalyticsTracking {
    public init() {}

    public func track(event: AnalyticsEvent) {
        // Placeholder for wiring analytics SDKs in the future.
    }
}
