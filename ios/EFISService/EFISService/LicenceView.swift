import SwiftUI

struct LicenceView: View {
    @EnvironmentObject var model: LicenceViewModel
    @State private var showingScanner = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Status: " + model.status)
                        .font(.footnote)
                        .lineLimit(2)
                    Spacer()
                    if model.busy { ProgressView() }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Form {
                    Section("EFIS") {
                        TextField("Device ID", text: $model.deviceID)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        Button("Scan Device QR") { showingScanner = true }
                    }

                    Section("Licence account") {
                        Button("Load / Refresh Account") { Task { await model.loadManagement() } }
                            .disabled(model.busy || model.deviceID.isEmpty)
                        if let account = model.account {
                            LabeledContent("Ownership", value: account.ownership)
                            LabeledContent("Entitlement", value: account.entitlement)
                            LabeledContent("Plan", value: account.planName ?? "None")
                            LabeledContent("Transferable", value: account.transferable ? "Yes" : "No")
                        }
                    }

                    if !model.plans.isEmpty {
                        Section("Purchase licence — simulation") {
                            ForEach(model.plans) { plan in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.name).font(.headline)
                                    Text(plan.priceDisplay)
                                    Text(plan.description).font(.footnote).foregroundStyle(.secondary)
                                    Button("Purchase " + plan.name) { Task { await model.purchase(plan) } }
                                        .disabled(model.busy)
                                }.padding(.vertical, 4)
                            }
                            Text("Development simulation only. No payment is taken.")
                                .font(.footnote).foregroundStyle(.secondary)
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
                            Button("Clear Phone Cache", role: .destructive) { model.clearCache() }
                        } else {
                            Text("No signed licence cached").foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        Text("The phone never signs a licence. The licence service signs it; the EFIS verifies it before installation.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
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
