import Foundation
import CryptoKit
import Security

protocol LicenceServiceProtocol {
    func requestLicence(deviceID: String) async throws -> LicenceResponse
}

/// Development phone-facing broker. The app never receives the simulator
/// device HMAC credential and never receives a licence signing key.
struct DevelopmentPhoneEntitlementService: LicenceServiceProtocol {
    let baseURL: URL
    var session: URLSession = .shared

    func requestLicence(deviceID: String) async throws -> LicenceResponse {
        let url = baseURL.appending(path: "/api/phone/entitlement")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["device_id": deviceID])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LicenceAppError.service("Invalid service response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw LicenceAppError.service(detail ?? "Entitlement service returned HTTP \(http.statusCode).")
        }
        let wire = try JSONDecoder().decode(PhoneLicenceResponse.self, from: data)
        guard wire.simulation_only else {
            throw LicenceAppError.service("Development app refused a non-simulator broker response.")
        }
        return LicenceResponse(device_id: wire.device_id, product: wire.product,
                               entitlement: wire.entitlement, license: wire.license)
    }
}

private struct PhoneLicenceResponse: Decodable {
    let simulation_only: Bool
    let device_id: String
    let product: String
    let entitlement: String
    let license: String
}


struct DevelopmentLicenceManagementService {
    let baseURL: URL
    var session: URLSession = .shared

    private func request(_ path: String, body: [String:String]? = nil) async throws -> Data {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        if let body {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String:Any])?["error"] as? String
            throw LicenceAppError.service(detail ?? "Licence management request failed.")
        }
        return data
    }

    func plans() async throws -> [LicencePlan] {
        struct Wire: Decodable { let simulation_only: Bool; let plans: [LicencePlan] }
        let wire = try JSONDecoder().decode(Wire.self, from: try await request("/api/phone/plans"))
        guard wire.simulation_only else { throw LicenceAppError.service("Refusing non-simulator management response.") }
        return wire.plans
    }

    func account(deviceID: String) async throws -> LicenceAccountStatus {
        struct Wire: Decodable {
            let simulation_only: Bool; let device_id: String; let ownership: String
            let entitlement: String; let plan_id: String?; let plan_name: String?; let transferable: Bool
            let renewal: String?; let valid_until: String?; let transfer_status: String?
        }
        let accountURL = baseURL.appending(path: "/api/phone/account")
        guard var components = URLComponents(url: accountURL, resolvingAgainstBaseURL: false) else {
            throw LicenceAppError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "device_id", value: deviceID)]
        guard let url = components.url else { throw LicenceAppError.invalidURL }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String:Any])?["error"] as? String
            throw LicenceAppError.service(detail ?? "Licence account request failed.")
        }
        let wire = try JSONDecoder().decode(Wire.self, from: data)
        guard wire.simulation_only, wire.device_id == deviceID else { throw LicenceAppError.service("Device/account mismatch.") }
        return LicenceAccountStatus(deviceID: wire.device_id, ownership: wire.ownership, entitlement: wire.entitlement,
                                    planID: wire.plan_id, planName: wire.plan_name, transferable: wire.transferable, renewal: wire.renewal, validUntil: wire.valid_until, transferStatus: wire.transfer_status)
    }

    func purchase(deviceID: String, planID: String) async throws -> LicenceAccountStatus {
        struct Wire: Decodable {
            let simulation_only: Bool; let device_id: String; let ownership: String
            let entitlement: String; let plan_id: String?; let plan_name: String?; let transferable: Bool
            let renewal: String?; let valid_until: String?; let transfer_status: String?
        }
        let data = try await request("/api/phone/purchase", body:["device_id":deviceID,"plan_id":planID])
        let wire = try JSONDecoder().decode(Wire.self, from:data)
        guard wire.simulation_only, wire.device_id == deviceID else { throw LicenceAppError.service("Device/account mismatch.") }
        return LicenceAccountStatus(deviceID: wire.device_id, ownership: wire.ownership, entitlement: wire.entitlement,
                                    planID: wire.plan_id, planName: wire.plan_name, transferable: wire.transferable, renewal: wire.renewal, validUntil: wire.valid_until, transferStatus: wire.transfer_status)
    }
    func lifecycle(deviceID: String, action: String, extra: [String:String] = [:]) async throws -> LicenceAccountStatus {
        struct Wire: Decodable {
            let simulation_only: Bool; let device_id: String; let ownership: String
            let entitlement: String; let plan_id: String?; let plan_name: String?; let transferable: Bool
            let renewal: String?; let valid_until: String?; let transfer_status: String?
        }
        var body = extra
        body["device_id"] = deviceID
        let data = try await request("/api/phone/" + action, body: body)
        let wire = try JSONDecoder().decode(Wire.self, from: data)
        guard wire.simulation_only, wire.device_id == deviceID else { throw LicenceAppError.service("Device/account mismatch.") }
        return LicenceAccountStatus(deviceID: wire.device_id, ownership: wire.ownership, entitlement: wire.entitlement,
                                    planID: wire.plan_id, planName: wire.plan_name, transferable: wire.transferable,
                                    renewal: wire.renewal, validUntil: wire.valid_until, transferStatus: wire.transfer_status)
    }

}

final class RedOnePinnedTLSDelegate: NSObject, URLSessionDelegate {
    private let allowedCertificateSHA256: Set<String>

    init(allowedCertificateSHA256: Set<String>) {
        self.allowedCertificateSHA256 = allowedCertificateSHA256
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust,
              let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let certificate = chain.first else {
            completionHandler(.performDefaultHandling, nil); return
        }
        let digest = SHA256.hash(data: SecCertificateCopyData(certificate) as Data)
        let fingerprint = digest.map { String(format: "%02X", $0) }.joined()
        guard allowedCertificateSHA256.contains(fingerprint) else {
            completionHandler(.cancelAuthenticationChallenge, nil); return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}

enum RedOneLocalGateway {
    static let url = URL(string: "https://redone-license.local:9443")!
    static let certificatePins: Set<String> = [
        "4591A97263BA799075D3D38443B6C0FA0047BD6619B72FBE612764D5AF2C0C1A"
    ]

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 10
        return URLSession(configuration: configuration,
                          delegate: RedOnePinnedTLSDelegate(allowedCertificateSHA256: certificatePins),
                          delegateQueue: nil)
    }

    static func isAvailable() async -> Bool {
        do {
            let (data, response) = try await session().data(from: url.appending(path: "/healthz"))
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return false }
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return object?["service"] as? String == "redone-local-gateway"
        } catch { return false }
    }
}
