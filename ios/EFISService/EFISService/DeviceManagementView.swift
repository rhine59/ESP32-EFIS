import SwiftUI

struct DeviceManagementView: View {
    var body: some View {
        List {
            Section("EFIS") {
                NavigationLink("Connect to RedOne") { EFISWiFiView() }
                NavigationLink("Recovery hardware diagnostics") { RecoveryDiagnosticsView() }
            }
            Section("SMUX") {
                Text("SMUX discovery and management are not yet implemented.")
                Text("CAN communication and firmware authentication must be validated first.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Devices")
    }
}


private struct RecoveryDiagnostic: Decodable, Identifiable {
    let id: String
    let name: String
    let result: String
    let detail: String
}
private struct RecoveryDiagnosticReport: Decodable {
    let schema: Int
    let device: String
    let mode: String
    let tests: [RecoveryDiagnostic]
}
struct RecoveryDiagnosticsView: View {
    @State private var report: RecoveryDiagnosticReport?
    @State private var status = "Not connected. Recovery Wi-Fi diagnostics API is not yet enabled."
    @State private var loading = false
    private let url = URL(string: "http://192.168.4.1/api/recovery/diagnostics")!
    private let categories = ["Power supply and voltage monitoring", "ESP32 memory and flash", "Display and backlight", "Rotary encoder and push switch", "BMI088 attitude sensor", "BMP585 pressure sensor", "RM3100 magnetometer", "CAN bus and SMUX", "Wi-Fi communications", "Non-volatile configuration"]
    var body: some View {
        List {
            Section("Recovery connection") {
                Text(status).foregroundStyle(.secondary)
                Button(loading ? "Checking…" : "Read recovery diagnostics") { Task { await load() } }
                    .disabled(loading)
                Text("Requires a future authenticated RedOne recovery API. This screen does not claim that hardware tests have run until the device returns a valid report.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Hardware tests") {
                ForEach(categories, id: \.self) { name in
                    let result = report?.tests.first(where: { $0.name == name })
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(name).font(.headline)
                            Spacer()
                            Text(result?.result ?? "SKIP")
                                .font(.caption).bold()
                                .foregroundStyle(result?.result == "PASS" ? .green : result?.result == "FAIL" ? .red : .secondary)
                        }
                        Text(result?.detail ?? "Not tested; waiting for recovery device")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }.navigationTitle("Recovery diagnostics")
    }
    @MainActor private func load() async {
        loading = true
        defer { loading = false }
        do {
            var request = URLRequest(url: url); request.timeoutInterval = 5
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let decoded = try JSONDecoder().decode(RecoveryDiagnosticReport.self, from: data)
            guard decoded.schema == 1, decoded.device == "RedOne", decoded.mode == "recovery" else { throw URLError(.cannotParseResponse) }
            report = decoded
            status = "Received recovery diagnostics from RedOne"
        } catch {
            report = nil
            status = "Recovery diagnostics unavailable: \(error.localizedDescription)"
        }
    }
}
