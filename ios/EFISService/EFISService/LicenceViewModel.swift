import Foundation

enum EFISServiceConfiguration {
    #if DEBUG
    static let licenceServiceURL = "https://granvillehouse.synology.me:8449"
    static let accountRegistrationURL = "https://granvillehouse.synology.me:8450/register"
    static let accountServiceURL = "https://granvillehouse.synology.me:8450"
    #else
    static let licenceServiceURL: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "EFISLicenceServiceURL") as? String,
              let url = URL(string: value),
              url.scheme == "https",
              url.host != nil,
              url.port == nil || url.port == 443 else {
            return ""
        }
        return value
    }()
    static let accountRegistrationURL: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "LollipopAccountRegistrationURL") as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil else { return "" }
        return value
    }()
    #endif
}

@MainActor
final class LicenceViewModel: ObservableObject {
    @Published var deviceID = "EFIS-SIM-0001"
    @Published var serviceURL = EFISServiceConfiguration.licenceServiceURL
    @Published var cached: LicenceSummary?
    enum ActivitySeverity { case info, success, warning, error }

    @Published var status = "Ready"
    @Published var activitySeverity: ActivitySeverity = .info
    @Published var busy = false
    @Published var plans: [LicencePlan] = []
    @Published var account: LicenceAccountStatus?
    @Published var buyerEmail = ""
    @Published var installedLicenceID: String?
    @Published var lollipopAccount: AccountSession?

    private let keychain = KeychainStore()


    init() {
        cached = keychain.load()
        lollipopAccount = keychain.loadAccount()
        if lollipopAccount != nil { Task { await validateAccountSession() } }
    }

    func handleAccountLogin(url: URL) async {
        guard url.scheme == "efisservice", url.host == "login", let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value else { return }
        guard let endpoint = URL(string: EFISServiceConfiguration.accountServiceURL + "/v1/app-login/exchange") else { return }
        var req = URLRequest(url: endpoint); req.httpMethod = "POST"; req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type"); req.httpBody = "code=".appending(code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "").data(using: .utf8)
        do { let (data,response)=try await URLSession.shared.data(for:req); guard let h=response as? HTTPURLResponse,h.statusCode==200 else { throw LicenceAppError.service("Account sign-in code was rejected or expired.") }; struct R:Decodable { let authenticated:Bool; let user_id:Int; let email:String; let session_token:String; let expires_at:String }; let r=try JSONDecoder().decode(R.self,from:data); let formatter=ISO8601DateFormatter(); guard let expiry=formatter.date(from:r.expires_at) else { throw LicenceAppError.service("Invalid account session expiry.") }; let session=AccountSession(userID:r.user_id,email:r.email,token:r.session_token,expiresAt:expiry); try keychain.saveAccount(session); lollipopAccount=session; status="Signed in as " + r.email; activitySeverity = .success } catch { status=error.localizedDescription; activitySeverity = .error }
    }

    func validateAccountSession() async {
        guard let session=keychain.loadAccount() else { lollipopAccount=nil; return }
        guard session.expiresAt > Date(), let endpoint=URL(string:EFISServiceConfiguration.accountServiceURL+"/v1/me") else { await expireAccount(session); return }
        var req=URLRequest(url:endpoint); req.setValue("Bearer \(session.token)",forHTTPHeaderField:"Authorization")
        do { let (_,response)=try await URLSession.shared.data(for:req); guard let h=response as? HTTPURLResponse else{return}; if h.statusCode==200 { lollipopAccount=session } else if h.statusCode==401 { await expireAccount(session) } } catch { lollipopAccount=session }
    }

    private func expireAccount(_ session:AccountSession) async {
        keychain.clearAccount(); lollipopAccount=nil; status="Sign-in expired — check your email for a new Lollipop QR code."; activitySeverity = .warning
        guard let endpoint=URL(string:EFISServiceConfiguration.accountServiceURL+"/v1/app-login/email") else{return}; var req=URLRequest(url:endpoint); req.httpMethod="POST"; req.setValue("application/x-www-form-urlencoded",forHTTPHeaderField:"Content-Type"); req.httpBody="email=".appending(session.email.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed) ?? "").data(using:.utf8); _=try? await URLSession.shared.data(for:req)
    }

    func signOut() async {
        if let session=keychain.loadAccount(), let endpoint=URL(string:EFISServiceConfiguration.accountServiceURL+"/v1/logout") { var req=URLRequest(url:endpoint); req.httpMethod="POST"; req.setValue("Bearer \(session.token)",forHTTPHeaderField:"Authorization"); _=try? await URLSession.shared.data(for:req) }; keychain.clearAccount(); lollipopAccount=nil; status="Signed out"; activitySeverity = .info
    }

    private func withManagement<T>(_ operation: (DevelopmentLicenceManagementService) async throws -> T) async throws -> T {
        guard let publicURL = URL(string: serviceURL) else { throw LicenceAppError.invalidURL }
        do {
            return try await operation(DevelopmentLicenceManagementService(baseURL: publicURL))
        } catch let networkError as URLError {
            guard await RedOneLocalGateway.isAvailable() else { throw networkError }
            return try await operation(DevelopmentLicenceManagementService(baseURL: RedOneLocalGateway.url,
                                                                           session: RedOneLocalGateway.session()))
        }
    }

    private func requestEntitlementWithFallback() async throws -> LicenceResponse {
        guard let publicURL = URL(string: serviceURL) else { throw LicenceAppError.invalidURL }
        do {
            return try await DevelopmentPhoneEntitlementService(baseURL: publicURL).requestLicence(deviceID: deviceID)
        } catch let networkError as URLError {
            guard await RedOneLocalGateway.isAvailable() else { throw networkError }
            return try await DevelopmentPhoneEntitlementService(baseURL: RedOneLocalGateway.url,
                                                                session: RedOneLocalGateway.session()).requestLicence(deviceID: deviceID)
        }
    }

    func loadManagement() async {
        busy = true; activitySeverity = .info; status = "Loading licence account…"; defer { busy = false }
        do {
            account = try await withManagement { try await $0.account(deviceID: deviceID) }
            do {
                plans = try await withManagement { try await $0.plans() }
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
        } catch {
            if let urlError = error as? URLError {
                status = "Network error \(urlError.code.rawValue) (\(urlError.code)): \(urlError.localizedDescription) — \(urlError.failingURL?.absoluteString ?? serviceURL)"
            } else {
                status = "\(type(of: error)): \(error.localizedDescription)"
            }
            activitySeverity = .error
        }
    }

    func purchase(_ plan: LicencePlan) async {
        busy = true; activitySeverity = .info; status = "Processing licence purchase…"; defer { busy = false }
        do {
            account = try await withManagement { try await $0.purchase(deviceID: deviceID, planID: plan.id) }
            status = "Purchase complete; entitlement ACTIVE"; activitySeverity = .success
            await getEntitlement()
        } catch { status = error.localizedDescription; activitySeverity = .error }
    }

    func manage(_ action: String, extra: [String:String] = [:]) async {
        busy = true; activitySeverity = .info; status = action == "transfer" ? "Starting ownership transfer…" : action == "cancel-transfer" ? "Cancelling ownership transfer…" : action == "renew" ? "Enabling auto-renewal…" : "Cancelling auto-renewal…"; defer { busy = false }
        do {
            account = try await withManagement { try await $0.lifecycle(deviceID: deviceID, action: action, extra: extra) }
            status = action == "transfer" ? "Ownership transfer pending" : action == "cancel-transfer" ? "Ownership transfer cancelled" : action == "renew" ? "Auto-renewal enabled" : "Auto-renewal cancelled"; activitySeverity = action == "transfer" ? .warning : .success
        } catch { status = error.localizedDescription; activitySeverity = .error }
    }

    func activateIncludedYear() async {
        busy = true; activitySeverity = .info; status = "Activating the included first year…"; defer { busy = false }
        do {
            account = try await withManagement { try await $0.lifecycle(deviceID: deviceID, action: "activate-included") }
            status = "Included first year activated"; activitySeverity = .success
        } catch { status = error.localizedDescription; activitySeverity = .error }
    }

    func acceptTransfer() async {
        busy = true; activitySeverity = .info; status = "Accepting ownership transfer…"; defer { busy = false }
        do {
            account = try await withManagement { try await $0.lifecycle(deviceID: deviceID, action: "accept-transfer", extra: ["buyer_email": buyerEmail]) }
            status = "Ownership transfer accepted"; activitySeverity = .success
            await getEntitlement()
        } catch { status = error.localizedDescription; activitySeverity = .error }
    }

    func getEntitlement() async {
        busy = true
        activitySeverity = .info
        status = "Retrieving signed entitlement…"
        defer { busy = false }
        do {
            let response = try await requestEntitlementWithFallback()
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
