import SwiftUI
import NetworkExtension

private struct RedOneStatus: Decodable {
    let device: String
    let version: String
    let running: String
    let next: String
}

struct EFISWiFiView: View {
    @State private var message = "Not connected"
    @State private var verified: RedOneStatus?
    @State private var checking = false
    @AppStorage("redone.savedMacAddress") private var savedMacAddress = ""
    @State private var macAddress = ""
    @State private var showingSavedNetworkChoice = false
    private var suffix: String {
        macAddress.uppercased().filter { "0123456789ABCDEF".contains($0) }
    }
    private var ssid: String { "RedOne_" + suffix }
    @State private var chooseNewDevice = false

    var body: some View {
        List {
            Section("RedOne EFIS") {
                Text("Enter the 12-digit Wi-Fi MAC address printed on your EFIS or its QR label.")
                    .font(.footnote).foregroundStyle(.secondary)
                if !savedMacAddress.isEmpty {
                    Button("Rejoin saved RedOne") {
                        macAddress = savedMacAddress
                        joinNetwork()
                    }
                    Button("Join a new RedOne") {
                        macAddress = ""
                        chooseNewDevice = true
                    }
                    LabeledContent("Saved network", value: "RedOne_" + savedMacAddress)
                }
                if savedMacAddress.isEmpty || chooseNewDevice {
                TextField("Wi-Fi MAC address", text: $macAddress)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                }
                LabeledContent("Network", value: ssid)
                Label(message, systemImage: verified == nil ? "wifi.exclamationmark" : "checkmark.circle.fill")
                    .foregroundStyle(verified == nil ? Color.secondary : Color.green)
                if let verified {
                    LabeledContent("Device", value: verified.device)
                    LabeledContent("Firmware", value: verified.version)
                    LabeledContent("Running partition", value: verified.running)
                    LabeledContent("Next update partition", value: verified.next)
                }
                Button("Join RedOne network") {
                    joinNetwork()
                }
                .disabled(suffix.count != 12 || checking)
                Button("Verify RedOne connection") {
                    Task { await verifyConnection() }
                }
                .disabled(checking)
            }
            Section("Firmware update") {
                Text("Firmware upload remains disabled until update validation is tested.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("EFIS Wi-Fi")
        .onAppear {
            if !savedMacAddress.isEmpty { macAddress = savedMacAddress }
        }
    }

    private func joinNetwork() {
                    verified = nil
                    message = "Requesting Wi-Fi connection…"
                    let config = NEHotspotConfiguration(ssid: ssid, passphrase: "BenchOnly-2026!", isWEP: false)
                    config.joinOnce = true
                    NEHotspotConfigurationManager.shared.apply(config) { error in
                        Task { @MainActor in
                            if let error = error as NSError?,
                               error.code != NEHotspotConfigurationError.alreadyAssociated.rawValue {
                                message = "Wi-Fi join failed: \(error.localizedDescription)"
                            } else {
                                await verifyConnection()
                            }
                        }
                    }
    }

    @MainActor
    private func verifyConnection() async {
        checking = true
        verified = nil
        message = "Checking RedOne device…"
        defer { checking = false }
        guard let url = URL(string: "http://192.168.4.1/status") else { return }
        for attempt in 0..<6 {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 3
                request.cachePolicy = .reloadIgnoringLocalCacheData
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                let status = try JSONDecoder().decode(RedOneStatus.self, from: data)
                guard status.device == "RedOne" else {
                    message = "Unexpected device response — connection not verified"
                    return
                }
                verified = status
                if suffix.count == 12 { savedMacAddress = suffix }
                message = "Connected to RedOne — device verified"
                return
            } catch {
                if attempt == 5 {
                    message = "Unable to verify RedOne. Check Wi-Fi and tap Verify again."
                    return
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
