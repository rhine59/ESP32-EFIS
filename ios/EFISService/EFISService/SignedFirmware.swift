import Foundation
import CryptoKit

struct SignedFirmwareEnvelope: Decodable {
    let signature_format: String
    let key_id: String
    let payload: SignedFirmwarePayload
    let signature: String
}

struct SignedFirmwarePayload: Codable {
    let product: String
    let version: String
    let build: Int
    let hardware_profile: String
    let idf: String
    let image_url: String
    let sha256: String
    let minimum_allowed_version: String
    let release_notes: String
}

// Pinned public key for the RedOne release publisher. Keep the private key off devices.
enum RedOneTrustedKeys {
    static let rawHex: [String: String] = ["redone-v1": "b772b85fefb06862e1597174c5bbef23d42995d97f1e3c5e1a0efe29c5127d0f"]
}

enum SignedFirmwareVerifier {
    static func verify(_ envelope: SignedFirmwareEnvelope) -> Bool {
        guard envelope.signature_format == "redone-ed25519-json-v1",
              let publicHex = RedOneTrustedKeys.rawHex[envelope.key_id],
              let publicBytes = Data(hex: publicHex), publicBytes.count == 32,
              let signature = Data(base64Encoded: envelope.signature), signature.count == 64,
              envelope.payload.product == "ESP32-EFIS",
              envelope.payload.hardware_profile == "s3-n16r2-v1",
              Data(hex: envelope.payload.sha256)?.count == 32,
              envelope.payload.image_url.hasPrefix("https://") else { return false }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            let canonical = try encoder.encode(envelope.payload)
            let key = try Curve25519.Signing.PublicKey(rawRepresentation: publicBytes)
            return key.isValidSignature(signature, for: canonical)
        } catch { return false }
    }
}

private extension Data {
    init?(hex: String) {
        guard hex.count.isMultiple(of: 2) else { return nil }
        self.init()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            append(byte)
            index = next
        }
    }
}
