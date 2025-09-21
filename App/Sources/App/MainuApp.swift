import SwiftUI
import AppFeature

@main
struct MainuApp: App {
    private let environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            AppRootView(environment: environment)
        }
    }
}
