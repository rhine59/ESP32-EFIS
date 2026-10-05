import Foundation
import CryptoKit

protocol LicenceServiceProtocol {
    func requestLicence(deviceID: String) async throws -> LicenceResponse
}

struct DevelopmentLicenceService: LicenceServiceProtocol {
    let baseURL: URL
    let deviceSecret: Data

    func requestLicence(deviceID: String) async throws -> LicenceResponse {
        let challenge: ChallengeResponse = try await post("/v1/device/challenge", body: ["device_id": deviceID])
        let message = Data((deviceID + "\n" + challenge.challenge).utf8)
        let key = SymmetricKey(data: deviceSecret)
        let proof = HMAC<SHA256>.authenticationCode(for: message, using: key)
            .map { String(format: "%02x", $0) }.joined()

        return try await post("/v1/device/license", body: [
            "device_id": deviceID,
            "challenge": challenge.challenge,
            "proof": proof
        ])
    }

    private func post<T: Decodable>(_ path: String, body: [String: String]) async throws -> T {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw LicenceAppError.service("Invalid service response.") }
        guard (200..<300).contains(http.statusCode) else {
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw LicenceAppError.service(detail ?? "Licence service returned HTTP \(http.statusCode).")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
