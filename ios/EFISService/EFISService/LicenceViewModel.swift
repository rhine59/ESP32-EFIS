import Foundation

@MainActor
final class LicenceViewModel: ObservableObject {
    @Published var deviceID = "EFIS-SIM-0001"
    @Published var serviceURL = "https://granvillehouse.synology.me:8449"
    @Published var cached: LicenceSummary?
    enum ActivitySeverity { case info, success, warning, error }

    @Published var status = "Ready"
    @Published var activitySeverity: ActivitySeverity = .info
    @Published var busy = false
    @Published var plans: [LicencePlan] = []
    @Published var account: LicenceAccountStatus?
    @Published var buyerEmail = ""
    @Published var installedLicenceID: String?

    private let keychain = KeychainStore()


    init() {
        cached = keychain.load()
    }

    func loadManagement() async {
        busy = true; activitySeverity = .info; status = "Loading licence account…"; defer { busy = false }
        do {
            guard let url = URL(string: serviceURL) else { throw LicenceAppError.invalidURL }
            let service = DevelopmentLicenceManagementService(baseURL: url)
            account = try await service.account(deviceID: deviceID)
            do {
                plans = try await service.plans()
                if account?.transferStatus == "PENDING" {
                    status = "Ownership transfer pending"
                    activitySeverity = .warning
                } else if account?.renewal == "CANCELLED" {
                    status = "Auto-renewal is cancelled"
                    activitySeverity = .warning
                } else {
                    status = "Licence account loaded"
                    activitySeverity = .success
                }
            } catch {
                plans = []
                status = "Account loaded; licence catalogue unavailable: " + error.localizedDescription; activitySeverity = .warning
            }
        } catch { status = error.localizedDescription; activitySeverity = .error }
    }

    func purchase(_ plan: LicencePlan) async {
        busy = true; activitySeverity = .info; status = "Processing licence purchase…"; defer { busy = false }
        do {
            guard let url = URL(string: serviceURL) else { throw LicenceAppError.invalidURL }
            account = try await DevelopmentLicenceManagementService(baseURL: url).purchase(deviceID: deviceID, planID: plan.id)
            status = "Purchase complete; entitlement ACTIVE"; activitySeverity = .success
            await getEntitlement()
        } catch { status = error.localizedDescription; activitySeverity = .error }
    }

    func manage(_ action: String, extra: [String:String] = [:]) async {
        busy = true; activitySeverity = .info; status = action == "transfer" ? "Starting ownership transfer…" : action == "cancel-transfer" ? "Cancelling ownership transfer…" : action == "renew" ? "Enabling auto-renewal…" : "Cancelling auto-renewal…"; defer { busy = false }
        do {
            guard let url = URL(string: serviceURL) else { throw LicenceAppError.invalidURL }
            account = try await DevelopmentLicenceManagementService(baseURL: url).lifecycle(deviceID: deviceID, action: action, extra: extra)
            status = action == "transfer" ? "Ownership transfer pending" : action == "cancel-transfer" ? "Ownership transfer cancelled" : action == "renew" ? "Auto-renewal enabled" : "Auto-renewal cancelled"; activitySeverity = action == "transfer" ? .warning : .success
        } catch { status = error.localizedDescription; activitySeverity = .error }
    }

    func getEntitlement() async {
        busy = true
        activitySeverity = .info
        status = "Retrieving signed entitlement…"
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
            status = "Signed entitlement cached"; activitySeverity = .success
        } catch {
            status = error.localizedDescription
            activitySeverity = .error
        }
    }

    func transferToEFIS() async {
        guard let cached else { status = "No signed licence is cached"; activitySeverity = .warning; return }
        busy = true
        activitySeverity = .info
        status = "Transferring signed licence to EFIS…"
        defer { busy = false }
        do {
            guard let url = URL(string: serviceURL) else { throw LicenceAppError.invalidURL }
            let transfer = LocalEFISLicenceTransfer(baseURL: url)
            let acknowledgement = try await transfer.transferSignedEnvelope(cached.envelope, deviceID: cached.deviceID)
            installedLicenceID = acknowledgement.licenceID
            status = "Licence verified and installed on EFIS"
            activitySeverity = .success
        } catch {
            status = error.localizedDescription
            activitySeverity = .error
        }
    }

    func clearCache() {
        keychain.clear()
        cached = nil
        status = "Phone licence cache cleared"; activitySeverity = .success
    }
}
