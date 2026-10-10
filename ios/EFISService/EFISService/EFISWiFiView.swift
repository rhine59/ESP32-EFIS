import SwiftUI
import NetworkExtension

struct EFISWiFiView: View {
    @State private var message = "Not connected"
    @State private var macAddress = ""
    private var suffix: String {
        macAddress.uppercased().filter { "0123456789ABCDEF".contains($0) }
    }
    private var ssid: String { "RedOne_" + suffix }

    var body: some View {
        List {
            Section("RedOne EFIS") {
                Text("Enter the 12-digit Wi-Fi MAC address printed on your EFIS or its QR label.")
                    .font(.footnote).foregroundStyle(.secondary)
                TextField("Wi-Fi MAC address", text: $macAddress)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                LabeledContent("Network", value: ssid)
                Text(message).font(.footnote)
                Button("Join RedOne network") {
                    let config = NEHotspotConfiguration(ssid: ssid, passphrase: "BenchOnly-2026!", isWEP: false)
                    config.joinOnce = true
                    NEHotspotConfigurationManager.shared.apply(config) { error in
                        DispatchQueue.main.async {
                            if let error = error as NSError?,
                               error.code != NEHotspotConfigurationError.alreadyAssociated.rawValue {
                                message = error.localizedDescription
                            } else {
                                message = "Join requested. Check Wi-Fi connection."
                            }
                        }
                    }
                }
                .disabled(suffix.count != 12)
            }
            Section("Firmware update") {
                Text("Firmware upload is disabled pending device identity and status verification.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("EFIS Wi-Fi")
    }
}
