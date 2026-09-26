import SwiftUI

struct EFISDevice: Identifiable {
    let id = UUID()
    let deviceID: String
    let licence: String
}

struct ContentView: View {
    @State private var devices = [EFISDevice(deviceID: "EFIS-DEMO-0001", licence: "Demo / not activated")]
    @State private var showingRegister = false

    var body: some View {
        NavigationStack {
            List {
                Section("My instruments") {
                    ForEach(devices) { device in
                        NavigationLink {
                            DeviceView(device: device)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(device.deviceID).font(.headline)
                                Text(device.licence).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section {
                    Button("Register an EFIS") { showingRegister = true }
                }
            }
            .navigationTitle("EFIS Account")
            .sheet(isPresented: $showingRegister) { RegisterDeviceView() }
        }
    }
}

struct DeviceView: View {
    let device: EFISDevice
    var body: some View {
        Form {
            Section("Instrument") {
                LabeledContent("Device ID", value: device.deviceID)
                LabeledContent("Licence", value: device.licence)
            }
            Section("Licence") {
                Button("Get / Refresh Licence") { }.disabled(true)
                Button("Manage Payment") { }.disabled(true)
                Button("Offline Activation") { }.disabled(true)
            }
            Section {
                Text("Payment and licence signing remain disabled until secure server integrations are validated.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }.navigationTitle("Instrument")
    }
}

struct RegisterDeviceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var deviceID = ""
    var body: some View {
        NavigationStack {
            Form {
                TextField("EFIS Device ID", text: $deviceID)
                    .textInputAutocapitalization(.characters)
                Text("Use the permanent Device ID shown by the instrument boot/licence menu.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("Register EFIS")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Register") { dismiss() }.disabled(deviceID.isEmpty) }
            }
        }
    }
}
