import SwiftUI
import Security
import NetworkExtension
import Network
import CoreLocation

struct DeviceManagementView: View {
    var body: some View {
        List {
            Section("EFIS") {
                NavigationLink("Connect to RedOne") { EFISWiFiView() }
                NavigationLink("RedOne hardware diagnostics") { RecoveryDiagnosticsView() }
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
private struct RecoveryFirmwareInventory: Decodable {
    let schema: Int
    let device: String
    let running: String
    let otaA: String
    let otaB: String
    let otaASize: Int
    let otaBSize: Int
    let transferEnabled: Bool
    let activationEnabled: Bool
    let rollbackEnabled: Bool
    let reason: String
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
        guard let stored = try? JSONDecoder().decode(RecoveryPairing.self, from: data) else { return nil }
        // Early bench pairing used the station MAC suffix (FDC) rather than
        // the actual SoftAP MAC suffix (FDD). Migrate only this known device.
        if stored.ssid == "RedOne_3C0F02D61FDC" {
            let corrected = RecoveryPairing(
                ssid: "RedOne_3C0F02D61FDD",
                password: stored.password,
                token: stored.token
            )
            do {
                try save(corrected)
                SecItemDelete([
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecAttrAccount as String: stored.ssid
                ] as CFDictionary)
                return corrected
            } catch {
                return stored
            }
        }
        return stored
    }
}

struct RecoveryDiagnosticsView: View {
    @State private var report: RecoveryDiagnosticReport?
    @State private var firmwareInventory: RecoveryFirmwareInventory?
    @State private var firmwareStatus = "Firmware inventory not yet checked"
    @State private var status = "Connect to RedOne Wi-Fi, then read diagnostics."
    @State private var statusState: StatusState = .idle
    private enum StatusState { case idle, progress, success, failure }
    private var statusColor: Color {
        switch statusState {
        case .idle: return .secondary
        case .progress: return .blue
        case .success: return .green
        case .failure: return .red
        }
    }
    @State private var loading = false
    @State private var scanning = false
    @State private var currentSSID = "Checking…"
    @State private var locationPermission = WiFiLocationPermission()
    @State private var networkPath = "Checking…"
    @State private var pairing = RecoveryPairingStore.load()
    private let categories = ["Power supply and voltage monitoring", "ESP32 memory and flash", "Display and backlight", "Rotary encoder and push switch", "BMI088 attitude sensor", "BMP585 pressure sensor", "RM3100 magnetometer", "CAN bus and SMUX", "Wi-Fi communications", "Non-volatile configuration"]

    var body: some View {
        List {
            Section("Connection") {
                Button("Scan RedOne connection QR code") { scanning = true }
                    .disabled(loading)
                if let pairing {
                    LabeledContent("Paired RedOne", value: pairing.ssid)
                    Button("Connect to \(pairing.ssid)") { Task { await joinRedOne(pairing) } }
                        .disabled(loading)
                } else {
                    Text("Scan the RedOne connection QR code to pair this phone.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                LabeledContent("Current Wi-Fi", value: currentSSID)
                Button("Refresh Wi-Fi status") { Task { await refreshWiFiSSID() } }
                HStack(spacing: 10) {
                    if loading { ProgressView().tint(.blue) }
                    else { Image(systemName: statusState == .success ? "checkmark.circle.fill" : statusState == .failure ? "xmark.octagon.fill" : "info.circle.fill") }
                    Text(status).font(.headline).fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(statusColor)
                .padding(.vertical, 10)
                .accessibilityElement(children: .combine)
            }
            Section("Diagnostic tests") {
                Button("Read diagnostics from RedOne") { Task { await connectAndRead() } }
                    .disabled(loading || pairing == nil)
                if report == nil {
                    Text("No diagnostic report received yet.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(categories, id: \.self) { name in
                    let result = report?.tests.first(where: { $0.name == name })
                    let resultColor: Color = result == nil ? .gray : result?.result == "PASS" ? .green : result?.result == "FAIL" ? .red : .yellow
                    let detail = result == nil ? "Not Tested — awaiting diagnostics" : result?.result == "SKIP" ? (result?.detail ?? "Not Tested — device unavailable") : (result?.detail ?? "")
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(name).font(.headline)
                            Spacer()
                            Text(result?.result ?? "TODO")
                                .font(.caption).bold()
                                .foregroundStyle(resultColor)
                        }
                        Text(detail)
                            .font(.caption).foregroundStyle(resultColor)
                    }
                }
            }
            Section("Firmware and recovery readiness") {
                Button("Inspect RedOne firmware slots") { Task { await inspectFirmware() } }
                    .disabled(loading || pairing == nil)
                Text(firmwareStatus).font(.subheadline).foregroundStyle(.secondary)
                if let inventory = firmwareInventory {
                    LabeledContent("Running partition", value: inventory.running)
                    LabeledContent("Partition A", value: inventory.otaA)
                    LabeledContent("Partition B", value: inventory.otaB)
                    LabeledContent("A capacity", value: ByteCountFormatter.string(fromByteCount: Int64(inventory.otaASize), countStyle: .file))
                    LabeledContent("B capacity", value: ByteCountFormatter.string(fromByteCount: Int64(inventory.otaBSize), countStyle: .file))
                    LabeledContent("Transfer", value: inventory.transferEnabled ? "Enabled" : "Locked")
                    LabeledContent("Activation", value: inventory.activationEnabled ? "Enabled" : "Locked")
                    LabeledContent("Rollback", value: inventory.rollbackEnabled ? "Enabled" : "Locked")
                    Text(inventory.reason).font(.footnote).foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Diagnostics")
        .task { await refreshWiFiSSID() }
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
                    statusState = .idle
                    status = "Pairing saved. Connecting to RedOne…"
                    Task { await joinRedOne(saved) }
                } catch {
                    status = "Invalid pairing QR: \(error.localizedDescription)"
                }
            }, onCancel: { scanning = false }, acceptsRecovery: true)
            .ignoresSafeArea()
        }
    }

    @MainActor private func refreshWiFiSSID() async {
        locationPermission.requestIfNeeded()
        let network = await NEHotspotNetwork.fetchCurrent()
        currentSSID = network?.ssid ?? "SSID unavailable — allow Precise Location for Lollipop"
        networkPath = await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
            monitor.pathUpdateHandler = { path in
                let description = "Wi-Fi: \(path.status == .satisfied ? "available" : "unavailable"), IPv4: \(path.supportsIPv4 ? "yes" : "no")"
                monitor.cancel()
                continuation.resume(returning: description)
            }
            monitor.start(queue: DispatchQueue(label: "redone.recovery.path"))
        }
    }

    @MainActor private func joinRedOne(_ device: RecoveryPairing) async {
        loading = true
        statusState = .progress
        status = "Requesting Wi-Fi connection…"
        let configuration = NEHotspotConfiguration(ssid: device.ssid, passphrase: device.password, isWEP: false)
        configuration.joinOnce = false
        let error: Error? = await withCheckedContinuation { continuation in
            NEHotspotConfigurationManager.shared.apply(configuration) { result in
                continuation.resume(returning: result)
            }
        }
        if let error = error as NSError?,
           !(error.domain == NEHotspotConfigurationErrorDomain &&
             error.code == NEHotspotConfigurationError.alreadyAssociated.rawValue) {
            statusState = .failure
            status = "Wi-Fi connection failed: \(error.localizedDescription)"
        } else {
            try? await Task.sleep(for: .seconds(2))
            await refreshWiFiSSID()
            if currentSSID == device.ssid {
                statusState = .success
                status = "Connected to \(device.ssid). Ready for diagnostics."
            } else {
                statusState = .idle
                status = "Connection requested. Check iPhone Wi-Fi if needed."
            }
        }
        loading = false
    }

    @MainActor private func inspectFirmware() async {
        guard let pairing else { firmwareStatus = "Scan RedOne QR first"; return }
        loading = true
        defer { loading = false }
        do {
            let (data, statusCode) = try await RecoveryTCPHTTP.fetch(token: pairing.token, path: "/api/recovery/firmware")
            guard statusCode == 200 else { throw NSError(domain: "RedOne firmware inventory", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(statusCode)"]) }
            let inventory = try JSONDecoder().decode(RecoveryFirmwareInventory.self, from: data)
            guard inventory.schema == 1, inventory.device == "RedOne" else { throw URLError(.cannotParseResponse) }
            firmwareInventory = inventory
            firmwareStatus = "Live RedOne partition inventory received"
        } catch {
            firmwareInventory = nil
            firmwareStatus = "Firmware inspection failed: \(error.localizedDescription)"
        }
    }

    @MainActor private func connectAndRead() async {
        guard let pairing else { status = "Scan pairing QR first"; return }
        loading = true
        defer { loading = false }
        await refreshWiFiSSID()
        statusState = .progress
        status = "Reading diagnostics over the current Wi-Fi connection…"
        _ = await readDiagnostics(pairing, attempts: 3)
    }

    @MainActor private func readDiagnostics(_ pairing: RecoveryPairing, attempts: Int) async -> Bool {
        for attempt in 0..<attempts {
            do {
                let (data, httpStatus) = try await RecoveryTCPHTTP.fetch(token: pairing.token)
                guard httpStatus == 200 else {
                    throw NSError(domain: "RedOne recovery", code: httpStatus, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpStatus): \(httpStatus == 401 ? "Pairing token rejected" : "Diagnostics endpoint rejected the request")"])
                }
                let decoded = try JSONDecoder().decode(RecoveryDiagnosticReport.self, from: data)
                guard decoded.schema == 1, decoded.device == "RedOne", decoded.mode == "recovery" else {
                    throw URLError(.cannotParseResponse)
                }
                report = decoded
                statusState = .success
                status = "Connected to \(pairing.ssid) — diagnostics received"
                return true
            } catch {
                if attempt == attempts - 1 {
                    report = nil
                    statusState = .failure
                    let nsError = error as NSError
                    status = "Recovery diagnostics failed [\(nsError.domain):\(nsError.code)]: \(error.localizedDescription)"
                } else {
                    try? await Task.sleep(for: .seconds(1))
                }
            }
        }
        return false
    }
}

private enum RecoveryTCPHTTP {
    static func fetch(token: String, path: String = "/api/recovery/diagnostics") async throws -> (Data, Int) {
        try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "redone.recovery.http")
            let parameters = NWParameters.tcp
            parameters.requiredInterfaceType = .wifi
            let connection = NWConnection(host: "192.168.4.1", port: 80, using: parameters)
            let state = RecoveryHTTPState()
            state.setPhase("waiting for Wi-Fi TCP connection")
            @Sendable func finish(_ result: Result<(Data, Int), Error>) {
                guard state.claim() else { return }
                connection.cancel()
                continuation.resume(with: result)
            }
            connection.stateUpdateHandler = { status in
                switch status {
                case .ready:
                    state.setPhase("TCP connected; waiting for HTTP response")
                    let request = "GET \(path) HTTP/1.1\r\nHost: 192.168.4.1\r\nX-RedOne-Recovery-Token: \(token)\r\nConnection: close\r\n\r\n"
                    // Start receiving immediately: some ESP-IDF responses close quickly,
                    // and waiting for send completion can lose the reply on reset.
                    @Sendable func receive() {
                            connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, complete, error in
                                if let data { state.append(data) }
                                if let response = try? state.parseIfComplete() {
                                    finish(.success(response)); return
                                }
                                if let error {
                                    if let response = try? state.parseIfComplete() { finish(.success(response)) }
                                    else { finish(.failure(error)) }
                                    return
                                }
                                if state.count > 16384 {
                                    finish(.failure(URLError(.dataLengthExceedsMaximum))); return
                                }
                                if complete {
                                    do { finish(.success(try state.parse())) }
                                    catch { finish(.failure(error)) }
                                } else { receive() }
                            }
                        }
                    receive()
                    connection.send(content: Data(request.utf8), completion: .contentProcessed { error in
                        if let error {
                            if let response = try? state.parseIfComplete() { finish(.success(response)) }
                            else { finish(.failure(error)) }
                        }
                    })
                case .failed(let error):
                    if let response = try? state.parseIfComplete() { finish(.success(response)) }
                    else { finish(.failure(error)) }
                case .cancelled: break
                default: break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 15) {
                finish(.failure(NSError(domain: "RedOne TCP timeout", code: -1001,
                    userInfo: [NSLocalizedDescriptionKey: state.phase])))
            }
        }
    }
}

private final class RecoveryHTTPState: @unchecked Sendable {
    private let lock = NSLock()
    private var finished = false
    private var buffer = Data()
    private var currentPhase = "starting"
    var phase: String { lock.lock(); defer { lock.unlock() }; return currentPhase }
    func setPhase(_ value: String) { lock.lock(); currentPhase = value; lock.unlock() }
    var count: Int { lock.lock(); defer { lock.unlock() }; return buffer.count }
    func claim() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !finished else { return false }
        finished = true
        return true
    }
    func append(_ data: Data) { lock.lock(); buffer.append(data); lock.unlock() }
    func parseIfComplete() throws -> (Data, Int)? {
        lock.lock()
        let snapshot = buffer
        lock.unlock()
        let delimiter = Data("\r\n\r\n".utf8)
        guard let range = snapshot.range(of: delimiter),
              let headers = String(data: snapshot[..<range.lowerBound], encoding: .utf8) else {
            return nil
        }
        let body = Data(snapshot[range.upperBound...])
        if headers.lowercased().contains("transfer-encoding: chunked") {
            return try? parse()
        }
        let lengthLine = headers.components(separatedBy: "\r\n").first {
            $0.lowercased().hasPrefix("content-length:")
        }
        if let lengthLine,
           let expected = Int(lengthLine.split(separator: ":", maxSplits: 1).last?.trimmingCharacters(in: .whitespaces) ?? ""),
           expected >= 0, body.count >= expected {
            return try parse()
        }
        return nil
    }
    func parse() throws -> (Data, Int) {
        lock.lock(); defer { lock.unlock() }
        let delimiter = Data("\r\n\r\n".utf8)
        guard let range = buffer.range(of: delimiter),
              let headers = String(data: buffer[..<range.lowerBound], encoding: .utf8),
              let first = headers.components(separatedBy: "\r\n").first,
              let code = Int(first.split(separator: " ").dropFirst().first ?? "") else {
            throw URLError(.cannotParseResponse)
        }
        let body = Data(buffer[range.upperBound...])
        // ESP-IDF httpd may use chunked transfer encoding for streaming responses.
        if headers.lowercased().contains("transfer-encoding: chunked") {
            return (try Self.decodeChunks(body), code)
        }
        return (body, code)
    }
    private static func decodeChunks(_ data: Data) throws -> Data {
        var remaining = data
        var output = Data()
        while true {
            guard let line = remaining.range(of: Data("\r\n".utf8)),
                  let sizeText = String(data: remaining[..<line.lowerBound], encoding: .ascii),
                  let size = Int(sizeText.split(separator: ";").first ?? "", radix: 16) else {
                throw URLError(.cannotParseResponse)
            }
            remaining.removeSubrange(..<line.upperBound)
            if size == 0 { return output }
            guard remaining.count >= size + 2 else { throw URLError(.cannotParseResponse) }
            output.append(remaining.prefix(size))
            remaining.removeSubrange(..<(size + 2))
        }
    }
}

@MainActor private final class WiFiLocationPermission: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    override init() {
        super.init()
        manager.delegate = self
    }
    func requestIfNeeded() {
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
    }
}
