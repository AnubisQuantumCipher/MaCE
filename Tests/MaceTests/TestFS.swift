import Foundation
import XCTest

enum TestFS {
    static func tempDir(_ name: String = "mace-tests") throws -> URL {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent(name)
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func ensureEmptyFile(at url: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !fm.fileExists(atPath: url.path) {
            fm.createFile(atPath: url.path, contents: Data(), attributes: nil)
        } else {
            try Data().write(to: url, options: .atomic)
        }
    }
}


