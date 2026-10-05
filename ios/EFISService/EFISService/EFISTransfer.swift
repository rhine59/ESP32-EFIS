import Foundation

protocol EFISLicenceTransfer {
    func transferSignedEnvelope(_ envelope: String, deviceID: String) async throws
}

/// First-stage placeholder. The production implementation will use the same
/// local phone-to-EFIS service transport selected for phone-mediated OTA.
struct UnconfiguredEFISTransfer: EFISLicenceTransfer {
    func transferSignedEnvelope(_ envelope: String, deviceID: String) async throws {
        throw LicenceAppError.transferUnavailable
    }
}
