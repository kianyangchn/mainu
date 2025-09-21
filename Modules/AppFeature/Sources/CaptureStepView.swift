import SwiftUI
import Capture
import PhotosUI
import UIKit

struct CaptureStepView: View {
    let capturedPages: [CapturedPage]
    let onCapture: (CapturedPage) -> Void
    let onRemove: (CapturedPage) -> Void
    let onReset: () -> Void
    let onProcess: () -> Void
    let onAddSamplePage: () -> Void
    let isCameraDisabled: Bool

    private let textRecognizer = MenuTextRecognizer()
    @StateObject private var cameraController = MenuCameraController()
    @State private var isCaptureInProgress = false
    @State private var isImportInProgress = false
    @State private var isPresentingPhotoPicker = false
    @State private var photoLibrarySelection: [PhotosPickerItem] = []
    @State private var alertTitle: String = "Camera Issue"
    @State private var alertMessage: String?
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack(alignment: .bottom) {
            cameraBackdrop
                .ignoresSafeArea()

            VStack(spacing: 20) {
                CaptureStepHeader()
                CapturedPagesStripView(capturedPages: capturedPages, onRemove: onRemove)
                CaptureControlsView(
                    isCaptureInProgress: isCaptureInProgress,
                    authorizationStatus: cameraController.authorizationStatus,
                    hasCapturedPages: !capturedPages.isEmpty,
                    isCameraDisabled: isCameraDisabled,
                    isImportInProgress: isImportInProgress,
                    onCapture: captureMenuPage,
                    onImportFromLibrary: importMenuPages,
                    onProcess: onProcess,
                    onReset: onReset
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                    .padding(.horizontal, -16)
            )
            .padding(.horizontal)
            .padding(.bottom)
        }
        .task {
            guard !isCameraDisabled else { return }
            await prepareCameraIfNeeded()
        }
        .onChange(of: cameraController.authorizationStatus) { _, newStatus in
            guard !isCameraDisabled else { return }
            if newStatus == .authorized {
                Task { await cameraController.configureSession(); cameraController.startSession() }
            }
        }
        .onReceive(cameraController.$lastError) { error in
            guard !isCameraDisabled else { return }
            guard let error else { return }
            alertTitle = "Camera Issue"
            alertMessage = error.userFacingMessage
        }
        .onDisappear {
            guard !isCameraDisabled else { return }
            cameraController.stopSession()
        }
        .alert(alertTitle, isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            if alertTitle == "Camera Issue" && cameraController.authorizationStatus == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            if let alertMessage {
                Text(alertMessage)
            }
        }
        .photosPicker(
            isPresented: $isPresentingPhotoPicker,
            selection: $photoLibrarySelection,
            maxSelectionCount: 0,
            matching: .images
        )
        .onChange(of: photoLibrarySelection) { _, newSelection in
            guard !newSelection.isEmpty else { return }
            handlePhotoLibrarySelection(newSelection)
        }
    }

    @ViewBuilder
    private var cameraBackdrop: some View {
        if isCameraDisabled {
            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.85), Color.black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack(spacing: 12) {
                    Image(systemName: "camera.slash")
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                    Text("Camera capture is disabled in the simulator. Use \"Add sample page\" to continue testing.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }
        } else {
            switch cameraController.authorizationStatus {
            case .authorized:
                MenuCameraPreviewView(session: cameraController.session)
                    .overlay(alignment: .top) {
                        LinearGradient(
                            colors: [Color.black.opacity(0.6), Color.black.opacity(0)],
                            startPoint: .top,
                            endPoint: .center
                        )
                    }
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [Color.black.opacity(0.7), Color.black.opacity(0)],
                            startPoint: .bottom,
                            endPoint: .center
                        )
                    }
            case .notDetermined:
                ProgressView("Preparing camera...")
                    .progressViewStyle(.circular)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            case .denied, .restricted:
                VStack(spacing: 16) {
                    Image(systemName: "camera.on.rectangle")
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                    Text("Enable camera access in Settings to capture menu pages.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
    }

    private func prepareCameraIfNeeded() async {
        guard !isCameraDisabled else { return }
        cameraController.refreshAuthorizationStatus()
        await cameraController.requestAccessIfNeeded()
        if cameraController.authorizationStatus == .authorized {
            await cameraController.configureSession()
            cameraController.startSession()
        } else if cameraController.authorizationStatus == .denied {
            alertMessage = MenuCameraError.permissionDenied.userFacingMessage
        }
    }

    private func captureMenuPage() {
        guard !isCaptureInProgress else { return }
        isCaptureInProgress = true

        if isCameraDisabled {
            isCaptureInProgress = false
            onAddSamplePage()
            return
        }

        cameraController.capturePhoto { result in
            Task { @MainActor in
                switch result {
                case .success(let page):
                    onCapture(page)
                case .failure(let error):
                    alertMessage = error.userFacingMessage
                }
                isCaptureInProgress = false
            }
        }
    }

    private func importMenuPages() {
        guard !isImportInProgress else { return }
        isPresentingPhotoPicker = true
    }

    private func handlePhotoLibrarySelection(_ items: [PhotosPickerItem]) {
        isImportInProgress = true

        let sendableItems = items.map(SendablePhotosPickerItem.init)

        Task {
            var importedPages: [CapturedPage] = []
            var encounteredError: Error?

            for wrapper in sendableItems {
                do {
                    let item = wrapper.item
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        throw PhotoImportError.couldNotLoadData
                    }

                    guard let image = UIImage(data: data) else {
                        throw PhotoImportError.invalidImage
                    }

                    guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
                        throw PhotoImportError.couldNotEncodeJPEG
                    }

                    let recognizedText = try await textRecognizer.recognizeText(in: image)
                    let fileURL = try MenuCaptureStorage.persistJPEGData(jpegData)
                    importedPages.append(
                        CapturedPage(
                            fileURL: fileURL,
                            recognizedText: recognizedText
                        )
                    )
                } catch {
                    encounteredError = error
                }
            }

            await MainActor.run {
                importedPages.forEach(onCapture)
                isImportInProgress = false
                photoLibrarySelection.removeAll()
                isPresentingPhotoPicker = false

                if let encounteredError {
                    alertTitle = "Import Issue"
                    alertMessage = PhotoImportError.userFacingMessage(for: encounteredError)
                }
            }
        }
    }
}

private enum PhotoImportError: Error {
    case couldNotLoadData
    case invalidImage
    case couldNotEncodeJPEG

    static func userFacingMessage(for error: Error) -> String {
        switch error {
        case let error as PhotoImportError:
            switch error {
            case .couldNotLoadData:
                return "We couldn't load one of the selected photos."
            case .invalidImage:
                return "One of the selected files isn't a supported image."
            case .couldNotEncodeJPEG:
                return "We couldn't prepare an image for processing."
            }
        case let error as MenuTextRecognizer.RecognitionError:
            return "We couldn't read text from one of the photos."
        default:
            return "Something went wrong while importing photos."
        }
    }
}

private struct SendablePhotosPickerItem: @unchecked Sendable {
    let item: PhotosPickerItem
}
