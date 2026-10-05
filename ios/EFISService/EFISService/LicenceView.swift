import SwiftUI

struct LicenceView: View {
    @EnvironmentObject var model: LicenceViewModel
    @State private var showingScanner = false

    private var activityColour: Color {
        if model.busy { return .blue }
        switch model.activitySeverity {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }

    private var activityBanner: some View {
        HStack(spacing: 12) {
            if model.busy { ProgressView() }
            Image(systemName: model.busy ? "hourglass" :
                    model.activitySeverity == .success ? "checkmark.circle.fill" :
                    model.activitySeverity == .warning ? "exclamationmark.triangle.fill" :
                    model.activitySeverity == .error ? "xmark.octagon.fill" : "info.circle.fill")
            Text(model.status)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .foregroundStyle(activityColour)
        .padding(12)
        .background(activityColour.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(activityColour.opacity(0.45), lineWidth: 1))
    }

    var body: some View {
        TabView {
            NavigationStack {
                List {
                    Section { activityBanner }
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
            .tabItem { Label("Licence", systemImage: "checkmark.seal") }

            NavigationStack {
                List {
                    Section { activityBanner }
                    if !model.plans.isEmpty {
                        ForEach(model.plans) { plan in
                            Section(plan.name) {
                                LabeledContent("Price", value: plan.priceDisplay)
                                Text(plan.description).foregroundStyle(.secondary)
                                Button("Purchase " + plan.name) {
                                    Task { await model.purchase(plan) }
                                }
                                .disabled(model.busy)
                            }
                        }
                    } else {
                        Section {
                            Text("Load / Refresh Account on the Licence tab to retrieve available plans.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Section {
                        Text("Development simulation only. No payment is taken.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Purchase")
            }
            .tabItem { Label("Purchase", systemImage: "cart") }

            NavigationStack {
                List {
                    Section { activityBanner }
                    Section("Account") {
                        if let account = model.account {
                            LabeledContent("Plan", value: account.planName ?? "None")
                            LabeledContent("Entitlement", value: account.entitlement)
                            if let renewal = account.renewal, renewal != "NONE" {
                                LabeledContent("Renewal", value: renewal)
                            }
                            if let transfer = account.transferStatus, transfer != "NONE" {
                                LabeledContent("Transfer", value: transfer)
                            }
                        } else {
                            Text("Load the licence account to enable management actions.")
                                .foregroundStyle(.secondary)
                            Button("Load / Refresh Account") {
                                Task { await model.loadManagement() }
                            }
                            .disabled(model.busy || model.deviceID.isEmpty)
                        }
                    }

                    if let account = model.account {
                        Section("Renewal") {
                            if account.planID == "annual" {
                                if account.renewal == "CANCELLED" {
                                    Button("Renew / Enable Auto-Renewal") {
                                        Task { await model.manage("renew") }
                                    }
                                    .disabled(model.busy)
                                    Text("Auto-renewal is cancelled. The current licence remains active until its expiry date.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Button("Cancel Renewal", role: .destructive) {
                                        Task { await model.manage("cancel-renewal") }
                                    }
                                    .disabled(model.busy)
                                }
                            } else {
                                Text("This licence does not require annual renewal.")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Section("Ownership transfer") {
                            if account.transferable {
                                TextField("Buyer email", text: $model.buyerEmail)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                Button("Start Ownership Transfer") {
                                    Task { await model.manage("transfer", extra: ["buyer_email": model.buyerEmail]) }
                                }
                                .disabled(model.busy || model.buyerEmail.isEmpty)
                                if account.transferStatus == "PENDING" {
                                    Button("Cancel Pending Transfer", role: .destructive) {
                                        Task { await model.manage("cancel-transfer") }
                                    }
                                    .disabled(model.busy)
                                }
                            } else {
                                Text("This licence is not transferable.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .contentMargins(.bottom, 110, for: .scrollContent)
                .navigationTitle("Manage Licence")
            }
            .tabItem { Label("Manage", systemImage: "slider.horizontal.3") }

            NavigationStack {
                List {
                    Section { activityBanner }
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
                .navigationTitle("Transfer")
            }
            .tabItem { Label("Transfer", systemImage: "arrow.right.arrow.left") }
        }
    }
}
