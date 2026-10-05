import Foundation

@MainActor
final class LicenceViewModel: ObservableObject {
    @Published var deviceID = "EFIS-SIM-0001"
    @Published var serviceURL = "https://granvillehouse.synology.me:8449"
    @Published var cached: LicenceSummary?
    @Published var status = "Ready"
    @Published var busy = false

    private let keychain = KeychainStore()


    init() {
        cached = keychain.load()
    }

    func getEntitlement() async {
        busy = true
        defer { busy = false }
        do {
            guard let url = URL(string: serviceURL) else { throw LicenceAppError.invalidURL }
            let service = DevelopmentPhoneEntitlementService(baseURL: url)
            let response = try await service.requestLicence(deviceID: deviceID)
            guard response.device_id == deviceID else {
                throw LicenceAppError.service("Entitlement Device ID does not match the requested EFIS.")
            }
            let summary = LicenceSummary(
                deviceID: response.device_id,
                entitlement: response.entitlement,
                envelope: response.license,
                cachedAt: Date()
            )
            try keychain.save(summary)
            cached = summary
            status = "Signed entitlement cached"
        } catch {
            status = error.localizedDescription
        }
    }

    func transferToEFIS() async {
        guard let cached else { status = "No signed licence is cached"; return }
        busy = true
        defer { busy = false }
        do {
            guard let url = URL(string: serviceURL) else { throw LicenceAppError.invalidURL }
            let transfer = LocalEFISLicenceTransfer(baseURL: url)
            try await transfer.transferSignedEnvelope(cached.envelope, deviceID: cached.deviceID)
            status = "Transferred; EFIS must verify and install"
        } catch {
            status = error.localizedDescription
        }
    }

    func clearCache() {
        keychain.clear()
        cached = nil
        status = "Phone licence cache cleared"
    }
}
