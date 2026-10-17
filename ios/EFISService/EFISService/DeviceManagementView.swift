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
    @State private var tcpResult = "Not tested"
    @State private var pairing = RecoveryPairingStore.load()
    private let url = URL(string: "http://192.168.4.1/api/recovery/diagnostics")!
    private let diagnosticsSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.allowsCellularAccess = false
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        return URLSession(configuration: config)
    }()
    private let categories = ["Power supply and voltage monitoring", "ESP32 memory and flash", "Display and backlight", "Rotary encoder and push switch", "BMI088 attitude sensor", "BMP585 pressure sensor", "RM3100 magnetometer", "CAN bus and SMUX", "Wi-Fi communications", "Non-volatile configuration"]

    var body: some View {
        List {
            Section {
                LabeledContent("Current Wi-Fi", value: currentSSID)
                LabeledContent("Network path", value: networkPath)
                Button("Refresh Wi-Fi status") { Task { await refreshWiFiSSID() } }
                LabeledContent("Direct TCP", value: tcpResult)
                Button("Test direct TCP connection") { Task { await testDirectTCP() } }
                HStack(spacing: 10) {
                    if loading { ProgressView().tint(.blue) }
                    else { Image(systemName: statusState == .success ? "checkmark.circle.fill" : statusState == .failure ? "xmark.octagon.fill" : "info.circle.fill") }
                    Text(status).font(.headline).fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(statusColor)
                .padding(.vertical, 10)
                .accessibilityElement(children: .combine)
                if let pairing {
                    Text("In iPhone Settings → Wi-Fi, connect to \(pairing.ssid), then return to Lollipop.")
                        .font(.footnote)
                    Button("Read diagnostics") { Task { await connectAndRead() } }
                        .disabled(loading)
                }
                if pairing == nil {
                    Button("Scan RedOne pairing QR code") { scanning = true }
                        .disabled(loading)
                }
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
                    status = "Pairing saved. Join RedOne Wi-Fi, then tap Read diagnostics."
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

    @MainActor private func testDirectTCP() async {
        tcpResult = "Connecting…"
        let result = await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
            let queue = DispatchQueue(label: "redone.recovery.tcp")
            let connection = NWConnection(host: "192.168.4.1", port: 80, using: .tcp)
            let completion = TCPCompletionState()
            @Sendable func finish(_ value: String) {
                let shouldResume = completion.claim()
                guard shouldResume else { return }
                connection.cancel()
                continuation.resume(returning: value)
            }
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready: finish("Connected to 192.168.4.1:80")
                case .failed(let error): finish("Failed: \(error.localizedDescription)")
                case .cancelled: finish("Cancelled")
                default: break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 8) { finish("Timed out after 8 seconds") }
        }
        tcpResult = result
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

private final class TCPCompletionState: @unchecked Sendable {
    private let lock = NSLock()
    private var completed = false
    func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !completed else { return false }
        completed = true
        return true
    }
}

private enum RecoveryTCPHTTP {
    static func fetch(token: String) async throws -> (Data, Int) {
        try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "redone.recovery.http")
            let connection = NWConnection(host: "192.168.4.1", port: 80, using: .tcp)
            let state = RecoveryHTTPState()
            @Sendable func finish(_ result: Result<(Data, Int), Error>) {
                guard state.claim() else { return }
                connection.cancel()
                continuation.resume(with: result)
            }
            connection.stateUpdateHandler = { status in
                switch status {
                case .ready:
                    let request = "GET /api/recovery/diagnostics HTTP/1.1\r\nHost: 192.168.4.1\r\nX-RedOne-Recovery-Token: \(token)\r\nConnection: close\r\n\r\n"
                    connection.send(content: Data(request.utf8), completion: .contentProcessed { error in
                        if let error { finish(.failure(error)); return }
                        @Sendable func receive() {
                            connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, complete, error in
                                if let data { state.append(data) }
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
                    })
                case .failed(let error): finish(.failure(error))
                case .cancelled: break
                default: break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 10) { finish(.failure(URLError(.timedOut))) }
        }
    }
}

private final class RecoveryHTTPState: @unchecked Sendable {
    private let lock = NSLock()
    private var finished = false
    private var buffer = Data()
    var count: Int { lock.lock(); defer { lock.unlock() }; return buffer.count }
    func claim() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !finished else { return false }
        finished = true
        return true
    }
    func append(_ data: Data) { lock.lock(); buffer.append(data); lock.unlock() }
    func parseIfComplete() throws -> (Data, Int)? {
        let response = try parse()
        return response.0.isEmpty ? nil : response
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
