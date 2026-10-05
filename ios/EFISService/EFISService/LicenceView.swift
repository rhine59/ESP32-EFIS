import SwiftUI

struct LicenceView: View {
    @EnvironmentObject var model: LicenceViewModel
    @State private var showingScanner = false

    var body: some View {
        NavigationStack {
            Form {
                Section("EFIS") {
                    TextField("Device ID", text: $model.deviceID)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Button("Scan Device QR") {
                        showingScanner = true
                    }
                }

                Section("Entitlement service") {
                    TextField("Service URL", text: $model.serviceURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Get / Refresh Signed Entitlement") {
                        Task { await model.getEntitlement() }
                    }
                    .disabled(model.busy || model.deviceID.isEmpty)
                }

                Section("Cached signed licence") {
                    if let licence = model.cached {
                        LabeledContent("Device", value: licence.deviceID)
                        LabeledContent("Entitlement", value: licence.entitlement)
                        LabeledContent("Cached", value: licence.cachedAt.formatted())
                        Text("Signed envelope cached securely on this iPhone.")
                            .font(.footnote)
                        Button("Transfer to EFIS") {
                            Task { await model.transferToEFIS() }
                        }
                        .disabled(model.busy)
                        Button("Clear Phone Cache", role: .destructive) {
                            model.clearCache()
                        }
                    } else {
                        Text("No signed licence cached")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Status") {
                    Text(model.status)
                }

                Section {
                    Text("The phone never signs a licence. The licence service signs it; the EFIS verifies it before installation.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("EFIS Licence")
            .fullScreenCover(isPresented: $showingScanner) {
                DeviceQRScannerView(
                    onDeviceID: { id in
                        model.deviceID = id
                        model.status = "Scanned Device ID " + id
                        showingScanner = false
                    },
                    onCancel: { showingScanner = false }
                )
                .ignoresSafeArea()
            }
        }
    }
}
