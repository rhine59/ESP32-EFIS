import SwiftUI

enum NetworkTestState: String {
    case idle = "Not tested"
    case associating = "Connecting to phone"
    case internet = "Checking Internet"
    case server = "Checking update server"
    case success = "Connection ready"
    case failed = "Connection failed"
}

struct NetworkSetupView: View {
    @AppStorage("efis.hotspot.ssid") private var ssid = "Richard’s iPhone"
    @AppStorage("efis.hotspot.password") private var password = ""
    @AppStorage("efis.ota.manifest") private var manifestURL = "https://efis-updates.example.net/efis/manifest.json"
    @State private var showPassword = false
    @State private var state: NetworkTestState = .idle
    @State private var testStep = 0
    @State private var saved = false
    private let timer = Timer.publish(every: 0.7, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("MAINTENANCE NETWORK SIMULATION", systemImage: "wrench.and.screwdriver.fill")
                        .font(.caption.bold()).foregroundStyle(.orange)
                    Text("The production EFIS will use Wi-Fi station mode to join the phone’s Personal Hotspot. The phone then supplies the Internet path to the public HTTPS OTA server.")
                        .font(.footnote)
                }

                Section("Phone hotspot") {
                    TextField("Hotspot name (SSID)", text: $ssid)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    HStack {
                        Group {
                            if showPassword { TextField("Hotspot password", text: $password) }
                            else { SecureField("Hotspot password", text: $password) }
                        }
                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                        }.buttonStyle(.plain)
                    }
                    Text("On iPhone, enable Personal Hotspot and Allow Others to Join before testing. Credentials are configuration data and must never be committed to Git.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Update server") {
                    TextField("HTTPS manifest URL", text: $manifestURL)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .keyboardType(.URL)
                    if !manifestURL.lowercased().hasPrefix("https://") {
                        Label("Production OTA requires HTTPS", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
                    }
                }

                Section("Connection test") {
                    LabeledContent("Status", value: state.rawValue)
                    Button("Test Phone → Internet → OTA Server") { startTest() }
                        .disabled(ssid.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty || !manifestURL.lowercased().hasPrefix("https://") || isTesting)
                    if isTesting { ProgressView() }
                    if state == .success {
                        Label("Hotspot, Internet route and HTTPS server simulated as reachable", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                }

                Section {
                    Button("Save Connection Configuration") { saved = true }
                        .buttonStyle(.borderedProminent)
                        .disabled(state != .success)
                    if saved { Label("Configuration saved in simulator storage", systemImage: "checkmark") }
                    Button("Forget Phone Configuration", role: .destructive) {
                        ssid = ""; password = ""; state = .idle; saved = false
                    }
                }

                Text("SIMULATOR ONLY — this screen models the instrument workflow. It does not join a real hotspot or contact the server. Production firmware must store the password in NVS, keep Wi-Fi off outside explicit maintenance mode, validate TLS certificates and never auto-install firmware.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .navigationTitle("Network Connection")
        }
        .onReceive(timer) { _ in advanceTest() }
    }

    private var isTesting: Bool { [.associating, .internet, .server].contains(state) }

    private func startTest() {
        saved = false; testStep = 0; state = .associating
    }

    private func advanceTest() {
        guard isTesting else { return }
        testStep += 1
        switch testStep {
        case 1: state = .internet
        case 2: state = .server
        default: state = .success
        }
    }
}
