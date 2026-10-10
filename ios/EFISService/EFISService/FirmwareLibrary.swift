import Foundation
import CryptoKit

struct CachedFirmwareRelease: Codable, Identifiable {
    var id: String { sha256 }
    let version: String
    let hardwareProfile: String
    let sha256: String
    let filename: String
    let downloadedAt: Date
    let sourceURL: URL
}

enum FirmwareLibrary {
    static var folder: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Firmware", isDirectory: true)
    }
    private static var index: URL { folder.appendingPathComponent("releases.json") }

    static func load() throws -> [CachedFirmwareRelease] {
        guard FileManager.default.fileExists(atPath: index.path) else { return [] }
        return try JSONDecoder().decode([CachedFirmwareRelease].self, from: Data(contentsOf: index))
    }

    static func store(_ bytes: Data, version: String, hardware: String,
                      digest: String, source: URL) throws -> CachedFirmwareRelease {
        let actual = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        guard actual.caseInsensitiveCompare(digest) == .orderedSame,
              digest.count == 64, digest.allSatisfy({ $0.isHexDigit }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let name = actual.lowercased() + ".bin"
        try bytes.write(to: folder.appendingPathComponent(name), options: .atomic)
        let release = CachedFirmwareRelease(version: version, hardwareProfile: hardware,
                                             sha256: actual, filename: name,
                                             downloadedAt: Date(), sourceURL: source)
        var items = try load()
        items.removeAll { $0.sha256 == actual }
        items.insert(release, at: 0)
        try JSONEncoder().encode(items).write(to: index, options: .atomic)
        return release
    }

    static func verify(_ release: CachedFirmwareRelease) -> Bool {
        guard release.filename == release.sha256.lowercased() + ".bin",
              let data = try? Data(contentsOf: folder.appendingPathComponent(release.filename)),
              data.count >= 1024, data.count <= 16 * 1024 * 1024 else { return false }
        let actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return actual.caseInsensitiveCompare(release.sha256) == .orderedSame
    }
}
