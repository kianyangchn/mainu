@preconcurrency import AVFoundation
import Foundation

public enum MenuCameraAuthorizationStatus: Equatable {
    case notDetermined
    case denied
    case restricted
    case authorized

    init(_ status: AVAuthorizationStatus) {
        switch status {
        case .authorized: self = .authorized
        case .denied: self = .denied
        case .restricted: self = .restricted
        case .notDetermined: self = .notDetermined
        @unknown default: self = .restricted
        }
    }
}

public enum MenuCameraError: Error {
    case permissionDenied
    case configurationFailed
    case captureFailed
    case dataWritingFailed
}

@preconcurrency @MainActor
public final class MenuCameraController: NSObject, ObservableObject {
    @Published public private(set) var authorizationStatus: MenuCameraAuthorizationStatus
    @Published public private(set) var lastError: MenuCameraError?
    @Published public private(set) var isSessionRunning: Bool = false

    public let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private var hasConfiguredSession = false
    private var captureCompletion: ((Result<CapturedPage, MenuCameraError>) -> Void)?

    public override init() {
        authorizationStatus = MenuCameraAuthorizationStatus(AVCaptureDevice.authorizationStatus(for: .video))
        super.init()
    }

    public func requestAccessIfNeeded() async {
        guard authorizationStatus == .notDetermined else { return }

        let granted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }

        authorizationStatus = granted ? .authorized : .denied
        if !granted {
            lastError = .permissionDenied
        }
    }

    public func refreshAuthorizationStatus() {
        let status = MenuCameraAuthorizationStatus(AVCaptureDevice.authorizationStatus(for: .video))
        authorizationStatus = status
    }

    public func configureSession() {
        guard authorizationStatus == .authorized else {
            lastError = .permissionDenied
            return
        }
        guard !hasConfiguredSession else { return }

        let success = makeSessionConfiguration()
        if success {
            hasConfiguredSession = true
            lastError = nil
        } else {
            hasConfiguredSession = false
            lastError = .configurationFailed
        }
    }

    private func makeSessionConfiguration() -> Bool {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return false
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                return false
            }
        } catch {
            return false
        }

        guard session.canAddOutput(photoOutput) else {
            return false
        }

        session.addOutput(photoOutput)
        photoOutput.isHighResolutionCaptureEnabled = true
        return true
    }

    public func startSession() {
        guard hasConfiguredSession else { return }
        guard !session.isRunning else { return }
        session.startRunning()
        isSessionRunning = true
    }

    public func stopSession() {
        guard session.isRunning else { return }
        session.stopRunning()
        isSessionRunning = false
    }

    public func capturePhoto(completion: @escaping (Result<CapturedPage, MenuCameraError>) -> Void) {
        guard authorizationStatus == .authorized else {
            lastError = .permissionDenied
            completion(.failure(.permissionDenied))
            return
        }
        guard hasConfiguredSession else {
            lastError = .configurationFailed
            completion(.failure(.configurationFailed))
            return
        }
        guard captureCompletion == nil else {
            completion(.failure(.captureFailed))
            return
        }

        captureCompletion = completion

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        settings.isHighResolutionPhotoEnabled = true

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    fileprivate func handleCaptureResult(
        _ result: Result<Data, Error>
    ) {
        guard let completion = captureCompletion else { return }
        captureCompletion = nil

        switch result {
        case .success(let data):
            do {
                let fileURL = try MenuCaptureStorage.persistJPEGData(data)
                let page = CapturedPage(fileURL: fileURL)
                completion(.success(page))
                lastError = nil
            } catch {
                lastError = .dataWritingFailed
                completion(.failure(.dataWritingFailed))
            }
        case .failure:
            lastError = .captureFailed
            completion(.failure(.captureFailed))
        }
    }
}

extension MenuCameraController: @unchecked Sendable {}

extension MenuCameraController: AVCapturePhotoCaptureDelegate {
    nonisolated public func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let error {
                self.handleCaptureResult(.failure(error))
                return
            }

            guard let data = photo.fileDataRepresentation() else {
                self.handleCaptureResult(.failure(MenuCameraError.captureFailed))
                return
            }

            self.handleCaptureResult(.success(data))
        }
    }
}
