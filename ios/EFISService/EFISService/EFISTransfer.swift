import Foundation

@MainActor
protocol EFISLicenceTransfer {
    func transferSignedEnvelope(_ envelope: String, deviceID: String) async throws
}

struct LocalEFISLicenceTransfer: EFISLicenceTransfer {
    let baseURL: URL

    func transferSignedEnvelope(_ envelope: String, deviceID: String) async throws {
        let url = baseURL.appendingPathComponent("api/phone/install-license")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "device_id": deviceID,
            "license": envelope
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LicenceAppError.service("Invalid EFIS response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw LicenceAppError.service(detail ?? "EFIS rejected signed licence (HTTP \(http.statusCode))")
        }
    }
}
