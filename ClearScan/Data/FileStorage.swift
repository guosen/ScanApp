import Foundation

enum FileStorageError: LocalizedError {
    case directoryUnavailable
    case writeFailed
    case readFailed

    var errorDescription: String? {
        switch self {
        case .directoryUnavailable:
            return String(localized: "Could not access app storage.")
        case .writeFailed:
            return String(localized: "Failed to save file.")
        case .readFailed:
            return String(localized: "Failed to read file.")
        }
    }
}

/// Separates source scans, generated PDFs, and scratch space.
final class FileStorage {
    static let shared = FileStorage()

    private let fileManager = FileManager.default

    private init() {}

    var applicationSupportURL: URL {
        get throws {
            let base = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let appDir = base.appendingPathComponent("ClearScan", isDirectory: true)
            try fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
            return appDir
        }
    }

    func directory(named name: String) throws -> URL {
        let dir = try applicationSupportURL.appendingPathComponent(name, isDirectory: true)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func sourcesDirectory() throws -> URL {
        try directory(named: "Sources")
    }

    func exportsDirectory() throws -> URL {
        try directory(named: "Exports")
    }

    func tempDirectory() throws -> URL {
        try directory(named: "Temp")
    }

    func writeJPEG(_ data: Data, filename: String, in directory: URL) throws -> URL {
        let url = directory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw FileStorageError.writeFailed
        }
    }

    func writePDF(_ data: Data, filename: String) throws -> URL {
        let dir = try exportsDirectory()
        return try writeJPEG(data, filename: filename, in: dir)
    }

    func removeItem(at url: URL) {
        try? fileManager.removeItem(at: url)
    }

    func urlForSource(filename: String) throws -> URL {
        try sourcesDirectory().appendingPathComponent(filename)
    }

    func urlForExport(filename: String) throws -> URL {
        try exportsDirectory().appendingPathComponent(filename)
    }
}
