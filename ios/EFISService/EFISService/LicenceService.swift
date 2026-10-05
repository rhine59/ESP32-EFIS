import Foundation

protocol LicenceServiceProtocol {
    func requestLicence(deviceID: String) async throws -> LicenceResponse
}

/// Development phone-facing broker. The app never receives the simulator
/// device HMAC credential and never receives a licence signing key.
struct DevelopmentPhoneEntitlementService: LicenceServiceProtocol {
    let baseURL: URL

    func requestLicence(deviceID: String) async throws -> LicenceResponse {
        let url = baseURL.appending(path: "/api/phone/entitlement")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["device_id": deviceID])
        let (data, response) = try await URLSession.shared.data(for: request)
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

    private func request(_ path: String, body: [String:String]? = nil) async throws -> Data {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        if let body {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
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
        let wire = try JSONDecoder().decode(Wire.self, from: try await request("/api/phone/account?device_id="+deviceID))
        guard wire.simulation_only, wire.device_id == deviceID else { throw LicenceAppError.service("Device/account mismatch.") }
        return LicenceAccountStatus(deviceID: wire.device_id, ownership: wire.ownership, entitlement: wire.entitlement,
                                    planID: wire.plan_id, planName: wire.plan_name, transferable: wire.transferable, renewal: wire.renewal, validUntil: wire.valid_until, transferStatus: wire.transfer_status)
    }

    func purchase(deviceID: String, planID: String) async throws -> LicenceAccountStatus {
        struct Wire: Decodable {
            let simulation_only: Bool; let device_id: String; let ownership: String
            let entitlement: String; let plan_id: String?; let plan_name: String?; let transferable: Bool
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
