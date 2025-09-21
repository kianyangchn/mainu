import CoreImage
import Foundation
import UIKit
import Vision

public struct MenuTextRecognizer: Sendable {
    public enum RecognitionError: Swift.Error {
        case unsupportedImage
    }

    public init() {}

    public func recognizeText(in image: UIImage) async throws -> String {
        let cgImage = try image.ensureCGImage()
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(returning: "")
                    return
                }

                let lines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: lines.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.02

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

private extension UIImage {
    func ensureCGImage() throws -> CGImage {
        if let cgImage {
            return cgImage
        }

        if let ciImage {
            let context = CIContext(options: nil)
            if let rendered = context.createCGImage(ciImage, from: ciImage.extent) {
                return rendered
            }
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let rendered = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }

        if let cgImage = rendered.cgImage {
            return cgImage
        }

        throw MenuTextRecognizer.RecognitionError.unsupportedImage
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}
