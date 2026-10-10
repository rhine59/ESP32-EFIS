import SwiftUI

/// Guided RedOne firmware workflow. Only the published-firmware download
/// and connection inspection are currently operational. No unsafe flash
/// operation is exposed by this view.
struct UpdateEFISFlowView: View {
    var body: some View {
        List {
            Section("Prepare online") {
                Label("1. Download published firmware", systemImage: "arrow.down.circle")
                    .font(.headline)
                Text("While connected to the internet, check the official publishing service and download its firmware image. The SHA-256 checksum is checked against the published manifest.")
                Text("Release signatures and an offline trusted-release library are not yet implemented. A matching checksum alone does not authenticate a release.")
                    .font(.footnote).foregroundStyle(.orange)
                NavigationLink("Open firmware download and connection") {
                    EFISWiFiView()
                }
            }
            Section("At the EFIS") {
                Label("2. Connect to EFIS", systemImage: "wifi")
                Text("Join the RedOne Wi-Fi network and verify the device identity and installed firmware.")
                Label("3. Push firmware", systemImage: "arrow.up.circle")
                Label("4. Verify staged firmware", systemImage: "checkmark.shield")
                Label("5. Activate firmware", systemImage: "power")
                Label("6. Roll back if necessary", systemImage: "arrow.uturn.backward")
            }
            Section("Implementation status") {
                Label("Download and connection inspection available", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
                Label("Push, verification, activation and rollback locked", systemImage: "lock.shield")
                    .foregroundStyle(.orange)
                Text("These operations require signed release verification, authenticated device access and proven A/B recovery. Activation must never occur during flight.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Update an EFIS")
        .navigationBarTitleDisplayMode(.inline)
    }
}
