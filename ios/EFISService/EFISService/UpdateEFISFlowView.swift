import SwiftUI

/// Guided RedOne firmware workflow. Only the published-firmware download
/// signed offline release preparation and connection inspection are operational. No unsafe flash
/// operation is exposed by this view.
struct UpdateEFISFlowView: View {
    var body: some View {
        List {
            Section("Download and verify") {
                Label("1. Download signed firmware", systemImage: "arrow.down.circle")
                    .font(.headline)
                Text("While connected to the internet, check the official publishing service and download its firmware image. The SHA-256 checksum is checked against the published manifest.")
                Text("A release is trusted only when its Ed25519 signature and firmware checksum both verify. Signed releases remain available offline.")
                    .font(.footnote).foregroundStyle(.orange)
                Label("2. Verify signed firmware", systemImage: "checkmark.shield")
                NavigationLink("Download / verify / connect") {
                    EFISWiFiView()
                }
            }
            Section("Connect and transfer") {
                Label("3. Connect to EFIS", systemImage: "wifi")
                Text("Join the RedOne Wi-Fi network and verify the device identity and installed firmware.")
                Label("4. Push firmware", systemImage: "arrow.up.circle")
                Label("5. Verify staged firmware", systemImage: "checkmark.shield")
                Label("6. Activate firmware", systemImage: "power")
                Label("7. Roll back if necessary", systemImage: "arrow.uturn.backward")
            }
            Section("Implementation status") {
                Label("Signed download, offline verification and connection inspection available", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
                Label("Push, verification, activation and rollback locked", systemImage: "lock.shield")
                    .foregroundStyle(.orange)
                Text("These operations require signed release verification, authenticated device access and proven A/B recovery. Activation must never occur during flight.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Update EFIS")
        .navigationBarTitleDisplayMode(.inline)
    }
}
