import SwiftUI
import UIKit
import Analytics
import Capture
import DesignSystem
import InteractiveMenu
import MenuProcessing
import OrderCart
import ShareLink

public struct AppEnvironment {
    public var analytics: AnalyticsTracking
    public var shareLinkGenerator: ShareLinkGenerating
    public var menuProcessingService: MenuProcessingService
    public var menuProcessingDebugClient: MenuProcessingDebugClient?

    public static let defaultMenuToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJpb3MtYXBwIiwiYXVkIjoiYWktcHJveHkiLCJpc3MiOiJpc3N1ZXItaWQiLCJpYXQiOjE3NTkwMDMwOTEsImV4cCI6MTc1OTAwNjY5MX0.93RGR-LeM-9XnGqMjkm2rqLsCNu00sSlibcvUSzvj1E"

    public init(
        analytics: AnalyticsTracking = NoopAnalyticsTracker(),
        shareLinkGenerator: ShareLinkGenerating = MockShareLinkGenerator(),
        menuProcessingService: MenuProcessingService = ProxyMenuProcessingService(
            token: AppEnvironment.defaultMenuToken
        ),
        menuProcessingDebugClient: MenuProcessingDebugClient? = MenuProcessingDebugClient(
            token: AppEnvironment.defaultMenuToken
        )
    ) {
        self.analytics = analytics
        self.shareLinkGenerator = shareLinkGenerator
        self.menuProcessingService = menuProcessingService
        self.menuProcessingDebugClient = menuProcessingDebugClient
    }
}

public struct AppRootView: View {
    @State private var coordinator = MenuCaptureCoordinator()
    @State private var phase: Phase = .capture
    @State private var processingProgress: Double = 0
    @State private var cart = OrderCart()
    @State private var selectedDish: MenuDish?
    @State private var shareLink: MenuShareLink?
    @State private var isPresentingSummary = false
    @State private var errorMessage: String?
    @State private var isConfirmingReturnToCapture = false
    @State private var readyOrderSummary: ReadyOrderSummary?

    private let environment: AppEnvironment

    public init(environment: AppEnvironment = AppEnvironment()) {
        self.environment = environment
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .capture:
                    #if targetEnvironment(simulator)
                    let isCameraDisabled = true
                    #else
                    let isCameraDisabled = false
                    #endif
                    CaptureStepView(
                        capturedPages: coordinator.capturedPages,
                        onCapture: appendCapturedPage,
                        onRemove: removeCapturedPage,
                        onReset: { coordinator.reset() },
                        onProcess: startProcessing,
                        onAddSamplePage: addSamplePage,
                        isCameraDisabled: isCameraDisabled
                    )
                case .processing:
                    ProcessingStepView(progress: processingProgress)
                case let .menu(template, recognizedText, backendOutput):
                    menuView(for: template, recognizedText: recognizedText, backendOutput: backendOutput)
                case .error(let message):
                    ErrorStateView(message: message, retry: resetFlow)
                }
            }
            .navigationTitle(title(for: phase))
            .toolbar { toolbarContent }
            .sheet(item: $selectedDish) { dish in
                DishDetailView(
                    dish: dish,
                    quantity: cart.quantity(for: dish),
                    onIncrement: { withAnimation { cart.increment(dish) } },
                    onDecrement: { withAnimation { cart.decrement(dish) } },
                    onClear: { withAnimation { cart.setQuantity(0, for: dish) } }
                )
            }
            .sheet(isPresented: $isPresentingSummary) {
                CartSummaryView(
                    cart: cart,
                    onIncrement: { dish in withAnimation { cart.increment(dish) } },
                    onDecrement: { dish in withAnimation { cart.decrement(dish) } }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $shareLink) { link in
                ShareLinkSheet(link: link)
                    .presentationDetents([.medium])
            }
            .sheet(item: $readyOrderSummary) { summary in
                ReadyToOrderView(summary: summary) { readyOrderSummary = nil }
            }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Dismiss", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            if let message = errorMessage {
                Text(message)
            }
        }
        .confirmationDialog(
            "Return to capture?",
            isPresented: $isConfirmingReturnToCapture,
            titleVisibility: .visible
        ) {
            Button("Return to capture", role: .destructive) {
                returnToCapture()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Going back will close the interactive menu so you can rescan or adjust your menu photos.")
        }
    }

    private enum Phase: Equatable {
        case capture
        case processing
        case menu(MenuTemplate, recognizedText: String, backendOutput: DebugPayload?)
        case error(String)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if case .menu(_, _, _) = phase {
                Button {
                    isConfirmingReturnToCapture = true
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .accessibilityLabel("Capture Again")
                }
            } else {
                EmptyView()
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            if case let .menu(template, _, _) = phase {
                Button {
                    Task { await generateShareLink(for: template) }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } else {
                EmptyView()
            }
        }

        ToolbarItem(placement: .bottomBar) {
            if case let .menu(template, _, _) = phase {
                HStack(spacing: 12) {
                    Button(action: { isPresentingSummary = true }) {
                        Label("Review Order", systemImage: "cart")
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .disabled(cart.isEmpty)

                    Button(action: { presentReadyToOrder(for: template) }) {
                        Text("Ready to order!")
                            .font(.headline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.accentColor.opacity(0.9))
                            .foregroundStyle(Color.white)
                            .clipShape(Capsule())
                    }
                    .disabled(cart.isEmpty)
                    .accessibilityHint("Generates a text summary of your selections in the menu language")
                }
            } else {
                EmptyView()
            }
        }
    }

    private func title(for phase: Phase) -> String {
        switch phase {
        case .capture: return "Capture Menu"
        case .processing: return "Processing"
        case .menu(_, _, _): return "Interactive Menu"
        case .error: return "Retry"
        }
    }

    private func menuView(for template: MenuTemplate, recognizedText _: String, backendOutput _: DebugPayload?) -> some View {
        InteractiveMenuView(
            template: template,
            quantityProvider: { cart.quantity(for: $0) },
            onDishTapped: { selectedDish = $0 },
            onQuickAdd: { dish in withAnimation { cart.increment(dish) } },
            onQuickRemove: { dish in withAnimation { cart.decrement(dish) } }
        )
        .animation(.default, value: cart)
    }

    private func appendCapturedPage(_ page: CapturedPage) {
        coordinator.append(page)
    }

    private func addSamplePage() {
        let index = coordinator.pageCount + 1
        coordinator.append(.mock(index: index))
    }

    private func removeCapturedPage(_ page: CapturedPage) {
        coordinator.remove(page)
    }

    private func resetFlow() {
        coordinator.reset()
        cart = OrderCart()
        phase = .capture
    }

    private func startProcessing() {
        guard coordinator.pageCount > 0 else {
            errorMessage = "Add at least one menu page to get started."
            return
        }

        phase = .processing
        processingProgress = 0

        let recognizedText = coordinator.concatenatedRecognizedText

        let debugClient = environment.menuProcessingDebugClient
        let currentLocale = Locale.current
        let langOut = Locale.preferredLanguages.first ?? currentLocale.identifier
        let langIn: String = {
            if let regionID = currentLocale.region?.identifier ?? currentLocale.regionCode {
                return currentLocale.localizedString(forRegionCode: regionID) ?? regionID
            }
            return currentLocale.identifier
        }()

        Task {
            async let progressTask: Void = animateProgress()
            async let debugTask: DebugPayload? = {
                guard let debugClient else { return nil }
                return await debugClient.sendMenuText(
                    recognizedText,
                    langIn: langIn,
                    langOut: langOut
                )
            }()
            do {
                let request = MenuProcessingRequest(
                    pageCount: coordinator.pageCount,
                    recognizedText: recognizedText,
                    languageIn: langIn,
                    languageOut: langOut
                )
                let template = try await environment.menuProcessingService.submit(request)
                let backendOutput = await debugTask
                await MainActor.run {
                    phase = .menu(
                        template,
                        recognizedText: recognizedText,
                        backendOutput: backendOutput
                    )
                    environment.analytics.track(event: .menuScanned(menuID: template.id))
                }
            } catch {
                _ = await debugTask
                await MainActor.run {
                    phase = .error("Unable to process the menu right now. Please try again.")
                }
            }
            _ = await progressTask
        }
    }

    private func returnToCapture() {
        selectedDish = nil
        shareLink = nil
        isPresentingSummary = false
        readyOrderSummary = nil
        cart = OrderCart()
        processingProgress = 0
        coordinator.reset()
        phase = .capture
    }

    private func animateProgress() async {
        for step in 1...4 {
            try? await Task.sleep(for: .milliseconds(300))
            await MainActor.run {
                processingProgress = Double(step) / 4.0
            }
        }
    }

    @MainActor
    private func generateShareLink(for template: MenuTemplate) async {
        environment.analytics.track(event: .shareLinkCreated(menuID: template.id))
        do {
            let link = try await environment.shareLinkGenerator.generateShareLink(menuID: template.id)
            shareLink = link
        } catch {
            errorMessage = "We couldn't generate a share link. Check your connection and try again."
        }
    }

    private func presentReadyToOrder(for template: MenuTemplate) {
        let summaryText = readyOrderText(for: template)
        guard !summaryText.isEmpty else { return }
        readyOrderSummary = ReadyOrderSummary(text: summaryText)
    }

    private func readyOrderText(for template: MenuTemplate) -> String {
        guard !cart.isEmpty else { return "" }

        let menuLanguage = "Italiano"
        let locale = Locale.current
        let languageCode = locale.language.languageCode?.identifier ?? locale.languageCode ?? locale.identifier
        let userLanguageName = locale.localizedString(forLanguageCode: languageCode) ?? languageCode

        var components: [String] = []
        components.append("Lingua del menu: \(menuLanguage)")
        components.append("Lingua dell'utente: \(userLanguageName)")
        components.append("")
        components.append("Ordine:")
        components.append(contentsOf: cart.summaryLines())
        return components.joined(separator: "\n")
    }
}

private struct ReadyOrderSummary: Identifiable {
    let id = UUID()
    let text: String
}

private struct ReadyToOrderView: View {
    let summary: ReadyOrderSummary
    let onDismiss: () -> Void

    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(summary.text)
                    .font(.body.monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle("Ready to Order")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onDismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(copied ? "Copied" : "Copy") {
                        UIPasteboard.general.string = summary.text
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
