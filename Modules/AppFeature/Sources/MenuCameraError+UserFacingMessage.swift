import Capture

extension MenuCameraError {
    var userFacingMessage: String {
        switch self {
        case .permissionDenied:
            return "Camera access is required to scan the menu."
        case .configurationFailed:
            return "We couldn't configure the camera. Restart the app and try again."
        case .captureFailed:
            return "We couldn't capture that photo. Hold steady and try again."
        case .dataWritingFailed:
            return "We couldn't save the photo. Please check your storage and retry."
        }
    }
}
