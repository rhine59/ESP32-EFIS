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
    let signedEnvelope: SignedFirmwareEnvelope?
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

    static func store(_ bytes: Data, envelope: SignedFirmwareEnvelope) throws -> CachedFirmwareRelease {
        guard SignedFirmwareVerifier.verify(envelope),
              let source = URL(string: envelope.payload.image_url),
              source.scheme == "https" else { throw CocoaError(.fileReadNoPermission) }
        let version = envelope.payload.version
        let hardware = envelope.payload.hardware_profile
        let digest = envelope.payload.sha256
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
                                             downloadedAt: Date(), sourceURL: source, signedEnvelope: envelope)
        var items = try load()
        items.removeAll { $0.sha256 == actual }
        items.insert(release, at: 0)
        try JSONEncoder().encode(items).write(to: index, options: .atomic)
        return release
    }

    // Conservative pre-transfer checks for the current RedOne partition table.
    // This is not device-side authentication and does not authorize flashing.
    static let maximumOTAImageBytes = 0x300000

    static func transferPreflight(_ release: CachedFirmwareRelease) -> String? {
        guard verify(release) else { return "Signed release or downloaded image failed verification" }
        let file = folder.appendingPathComponent(release.filename)
        guard let data = try? Data(contentsOf: file),
              data.count >= 1024, data.count <= maximumOTAImageBytes else {
            return "Firmware exceeds the 3 MiB OTA partition or is too small"
        }
        guard data.first == 0xE9, (1...16).contains(Int(data[1])) else {
            return "File does not have a valid ESP application image header"
        }
        // ESP-IDF application descriptor: image header (24), segment header (8),
        // descriptor magic (4), then project_name at offset 80 (32 bytes).
        guard Array(data[32..<36]) == [0x32, 0x54, 0xcd, 0xab] else {
            return "Firmware is missing its ESP-IDF application descriptor"
        }
        let projectBytes = data[80..<112].prefix(while: { $0 != 0 })
        guard String(bytes: projectBytes, encoding: .utf8) == "esp32_efis" else {
            return "Firmware is not the RedOne EFIS application"
        }
        guard release.hardwareProfile == "s3-n16r2-v1" else {
            return "Firmware is not intended for this RedOne hardware profile"
        }
        return nil
    }

    static func verify(_ release: CachedFirmwareRelease) -> Bool {
        guard let envelope = release.signedEnvelope,
              SignedFirmwareVerifier.verify(envelope),
              envelope.payload.sha256.caseInsensitiveCompare(release.sha256) == .orderedSame,
              envelope.payload.version == release.version,
              envelope.payload.hardware_profile == release.hardwareProfile,
              envelope.payload.image_url == release.sourceURL.absoluteString,
              release.filename == release.sha256.lowercased() + ".bin",
              let data = try? Data(contentsOf: folder.appendingPathComponent(release.filename)),
              data.count >= 1024, data.count <= 16 * 1024 * 1024 else { return false }
        let actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return actual.caseInsensitiveCompare(release.sha256) == .orderedSame
    }
}
