import Foundation

public enum MenuCaptureStorageError: Error {
    case writingFailed
}

public enum MenuCaptureStorage {
    private static let directoryName = "MainuMenuCaptures"

    private static var directoryURL: URL {
        let baseDirectory = FileManager.default.temporaryDirectory
        return baseDirectory.appendingPathComponent(directoryName, isDirectory: true)
    }

    public static func prepareIfNeeded() throws {
        let directory = directoryURL
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    @discardableResult
    public static func persistJPEGData(_ data: Data) throws -> URL {
        try prepareIfNeeded()
        let fileName = UUID().uuidString + ".jpg"
        let destination = directoryURL.appendingPathComponent(fileName)
        do {
            try data.write(to: destination, options: [.atomic])
            return destination
        } catch {
            throw MenuCaptureStorageError.writingFailed
        }
    }

    public static func removeFile(at url: URL) {
        guard url.isFileURL else { return }
        let standardizedURL = url.standardizedFileURL
        guard standardizedURL.path.hasPrefix(directoryURL.standardizedFileURL.path) else { return }
        try? FileManager.default.removeItem(at: standardizedURL)
    }

    public static func removeAll() {
        let directory = directoryURL
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try? FileManager.default.removeItem(at: directory)
    }
}
