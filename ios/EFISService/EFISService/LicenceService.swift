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
