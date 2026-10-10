import SwiftUI

struct DeviceManagementView: View {
    var body: some View {
        List {
            Section("EFIS") {
                NavigationLink("Connect to RedOne") { EFISWiFiView() }
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
