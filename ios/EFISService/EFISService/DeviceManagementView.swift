import SwiftUI
import NetworkExtension
import Security

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
private struct RecoveryPairing: Codable {
    let ssid: String
    let password: String
    let token: String
}

private enum RecoveryPairingStore {
    private static let service = "uk.co.thingies.redone.recovery"
    static func save(_ pairing: RecoveryPairing) throws {
        let data = try JSONEncoder().encode(pairing)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: pairing.ssid]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
            throw NSError(domain: "RedOne pairing", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not save device credentials securely"])
        }
        UserDefaults.standard.set(pairing.ssid, forKey: "redone.recovery.lastSSID")
    }
    static func load() -> RecoveryPairing? {
        guard let ssid = UserDefaults.standard.string(forKey: "redone.recovery.lastSSID") else { return nil }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: ssid,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(RecoveryPairing.self, from: data)
    }
}

struct RecoveryDiagnosticsView: View {
    @State private var report: RecoveryDiagnosticReport?
    @State private var status = "Scan the device pairing QR code once, then reconnect without typing credentials."
    @State private var loading = false
    @State private var scanning = false
    @State private var pairing = RecoveryPairingStore.load()
    private let url = URL(string: "http://192.168.4.1/api/recovery/diagnostics")!
    private let categories = ["Power supply and voltage monitoring", "ESP32 memory and flash", "Display and backlight", "Rotary encoder and push switch", "BMI088 attitude sensor", "BMP585 pressure sensor", "RM3100 magnetometer", "CAN bus and SMUX", "Wi-Fi communications", "Non-volatile configuration"]

    var body: some View {
        List {
            Section("Recovery connection") {
                Text(status).foregroundStyle(.secondary)
                if let pairing {
                    LabeledContent("Remembered RedOne", value: pairing.ssid)
                    Button("Read diagnostics over current Wi-Fi") { Task { await connectAndRead() } }
                        .disabled(loading)
                    Button("Request automatic Wi-Fi join") { Task { await requestWiFiJoin() } }
                        .disabled(loading)
                }
                Button(pairing == nil ? "Scan RedOne pairing QR code" : "Pair another RedOne") {
                    scanning = true
                }
                .disabled(loading)
                Text("Pairing requires physical access to the QR label. iOS may request permission to join Wi-Fi. No internet connection is needed after the app is verified.")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("Bench-only: the QR contains a reusable Wi-Fi password and maintenance token. Keep it private. Firmware-changing operations are not enabled.")
                    .font(.footnote).foregroundStyle(.orange)
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
        }
        .navigationTitle("Recovery diagnostics")
        .sheet(isPresented: $scanning) {
            DeviceQRScannerView(onDeviceID: { value in
                scanning = false
                do {
                    guard let components = URLComponents(string: value),
                          components.scheme == "redone-recovery", components.host == "pair",
                          let fields = components.queryItems else { throw URLError(.badURL) }
                    func field(_ name: String) -> String? { fields.first(where: { $0.name == name })?.value }
                    guard let ssid = field("ssid"), ssid.hasPrefix("RedOne_"), ssid.count == 19,
                          let password = field("password"), (16...63).contains(password.count),
                          let token = field("token"), (32...64).contains(token.count) else {
                        throw URLError(.cannotParseResponse)
                    }
                    let saved = RecoveryPairing(ssid: ssid, password: password, token: token)
                    try RecoveryPairingStore.save(saved)
                    pairing = saved
                    status = "Pairing saved. Join RedOne Wi-Fi, then tap Read diagnostics over current Wi-Fi."
                } catch {
                    status = "Invalid pairing QR: \(error.localizedDescription)"
                }
            }, onCancel: { scanning = false }, acceptsRecovery: true)
            .ignoresSafeArea()
        }
    }

    @MainActor private func connectAndRead() async {
        guard let pairing else { status = "Scan pairing QR first"; return }
        loading = true
        defer { loading = false }
        status = "Reading diagnostics over the current Wi-Fi connection…"
        _ = await readDiagnostics(pairing, attempts: 3)
    }

    @MainActor private func requestWiFiJoin() async {
        guard let pairing else { status = "Scan pairing QR first"; return }
        loading = true
        defer { loading = false }
        status = "Requesting Wi-Fi connection to \(pairing.ssid)…"
        let config = NEHotspotConfiguration(ssid: pairing.ssid, passphrase: pairing.password, isWEP: false)
        config.joinOnce = false
        let joinError: Error? = await withCheckedContinuation { continuation in
            NEHotspotConfigurationManager.shared.apply(config) { error in
                continuation.resume(returning: error)
            }
        }
        if let error = joinError as NSError?,
           error.code != NEHotspotConfigurationError.alreadyAssociated.rawValue {
            status = "iOS could not join \(pairing.ssid): \(error.localizedDescription). Join it in Settings → Wi-Fi, then tap Connect again."
            return
        }
        status = "Wi-Fi join requested; waiting for RedOne diagnostics…"
        _ = await readDiagnostics(pairing, attempts: 6)
    }

    @MainActor private func readDiagnostics(_ pairing: RecoveryPairing, attempts: Int) async -> Bool {
        for attempt in 0..<attempts {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 4
                request.setValue(pairing.token, forHTTPHeaderField: "X-RedOne-Recovery-Token")
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                let decoded = try JSONDecoder().decode(RecoveryDiagnosticReport.self, from: data)
                guard decoded.schema == 1, decoded.device == "RedOne", decoded.mode == "recovery" else {
                    throw URLError(.cannotParseResponse)
                }
                report = decoded
                status = "Connected to \(pairing.ssid) — diagnostics received"
                return true
            } catch {
                if attempt == attempts - 1 {
                    report = nil
                    status = "Recovery diagnostics unavailable: \(error.localizedDescription)"
                } else {
                    try? await Task.sleep(for: .seconds(1))
                }
            }
        }
        return false
    }
}
