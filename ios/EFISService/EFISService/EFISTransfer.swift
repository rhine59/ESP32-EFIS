import Foundation

struct EFISLicenceInstallAcknowledgement {
    let result: String
    let status: String
    let licenceID: String?
}

@MainActor
protocol EFISLicenceTransfer {
    func transferSignedEnvelope(_ envelope: String, deviceID: String) async throws -> EFISLicenceInstallAcknowledgement
}

struct LocalEFISLicenceTransfer: EFISLicenceTransfer {
    let baseURL: URL

    func transferSignedEnvelope(_ envelope: String, deviceID: String) async throws -> EFISLicenceInstallAcknowledgement {
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
        guard let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = body["result"] as? String, result == "INSTALLED",
              let licence = body["license"] as? [String: Any],
              let status = licence["status"] as? String, status == "VALID" else {
            throw LicenceAppError.service("EFIS did not confirm a valid installed licence.")
        }
        return EFISLicenceInstallAcknowledgement(
            result: result,
            status: status,
            licenceID: licence["license_id"] as? String
        )
    }
}
