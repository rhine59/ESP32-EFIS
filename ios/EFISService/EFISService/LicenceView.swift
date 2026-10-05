import SwiftUI

struct LicenceView: View {
    @EnvironmentObject var model: LicenceViewModel
    @State private var showingScanner = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
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

                ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 18) {
                    GroupBox("EFIS") { VStack(alignment: .leading, spacing: 12) {
                        TextField("Device ID", text: $model.deviceID)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        Button("Scan Device QR") { showingScanner = true }
                    }.frame(maxWidth: .infinity, alignment: .leading) }

                    GroupBox("Licence account") { VStack(alignment: .leading, spacing: 12) {
                        Button("Load / Refresh Account") { Task { await model.loadManagement() } }
                            .disabled(model.busy || model.deviceID.isEmpty)
                        if let account = model.account {
                            LabeledContent("Ownership", value: account.ownership)
                            LabeledContent("Entitlement", value: account.entitlement)
                            LabeledContent("Plan", value: account.planName ?? "None")
                            LabeledContent("Transferable", value: account.transferable ? "Yes" : "No")
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading) }

                    if !model.plans.isEmpty {
                        GroupBox("Purchase licence — simulation") { VStack(alignment: .leading, spacing: 12) {
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
                        }.frame(maxWidth: .infinity, alignment: .leading) }
                    }

                    GroupBox("Entitlement service") { VStack(alignment: .leading, spacing: 12) {
                        TextField("Service URL", text: $model.serviceURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Get / Refresh Signed Entitlement") {
                            Task { await model.getEntitlement() }
                        }
                        .disabled(model.busy || model.deviceID.isEmpty)
                    }.frame(maxWidth: .infinity, alignment: .leading) }

                    GroupBox("Cached signed licence") { VStack(alignment: .leading, spacing: 12) {
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
                    }.frame(maxWidth: .infinity, alignment: .leading) }

                    GroupBox {
                        Text("The phone never signs a licence. The licence service signs it; the EFIS verifies it before installation.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, max(16, geometry.safeAreaInsets.bottom))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .scrollBounceBehavior(.always)
                .scrollIndicators(.visible)
                .scrollDismissesKeyboard(.interactively)
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
