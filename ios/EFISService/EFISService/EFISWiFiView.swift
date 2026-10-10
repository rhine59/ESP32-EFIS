import SwiftUI
import NetworkExtension

struct EFISWiFiView: View {
    @State private var message = "Not connected"
    private let ssid = "EFIS-BOOT-LAB"

    var body: some View {
        List {
            Section("EFIS Wi-Fi") {
                LabeledContent("Network", value: ssid)
                Text(message).font(.footnote)
                Button("Join EFIS network") {
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
            }
            Section("Firmware update") {
                Text("Device verification and firmware upload are not enabled yet.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("EFIS Wi-Fi")
    }
}
