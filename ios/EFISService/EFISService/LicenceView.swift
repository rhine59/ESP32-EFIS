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
                                if account.transferStatus == "PENDING" {
                                    Button("Cancel Pending Transfer", role: .destructive) {
                                        Task { await model.manage("cancel-transfer") }
                                    }
                                    .disabled(model.busy)
                                    Text("Cancel the pending transfer before starting a new ownership transfer.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                } else {
                                    TextField("Buyer email", text: $model.buyerEmail)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                    Button("Start Ownership Transfer") {
                                        Task { await model.manage("transfer", extra: ["buyer_email": model.buyerEmail]) }
                                    }
                                    .disabled(model.busy || model.buyerEmail.isEmpty)
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
                            if let installedLicenceID = model.installedLicenceID {
                                LabeledContent("Installed Licence ID", value: installedLicenceID)
                                    .textSelection(.enabled)
                            }
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


private enum ProcessStepState {
    case complete, current, waiting, attention, failed

    var color: Color {
        switch self {
        case .complete: return .green
        case .current: return .blue
        case .waiting: return .gray
        case .attention: return .orange
        case .failed: return .red
        }
    }

    var symbol: String {
        switch self {
        case .complete: return "checkmark"
        case .current: return "arrow.right"
        case .waiting: return "clock"
        case .attention: return "exclamationmark"
        case .failed: return "xmark"
        }
    }
}

private struct ProcessDefinition: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let steps: [String]
}

private let processCatalogue: [ProcessDefinition] = [
    .init(id: "setup", title: "Set up a new EFIS", subtitle: "Register, licence, install and verify a new unit", systemImage: "plus.circle", steps: ["Identify EFIS", "Register owner", "Choose licence", "Obtain signed licence", "Install on EFIS", "Verify installation"]),
    .init(id: "reassign", title: "Reassign / sell an EFIS", subtitle: "Transfer ownership safely to another user", systemImage: "person.2", steps: ["Confirm current EFIS", "Identify new owner", "Wait for buyer acceptance", "Issue replacement licence", "Install on EFIS", "Verify new ownership"]),
    .init(id: "receive", title: "Receive a transferred EFIS", subtitle: "Accept ownership and install your licence", systemImage: "person.crop.circle.badge.checkmark", steps: ["Open transfer invitation", "Authenticate buyer", "Accept ownership", "Obtain replacement licence", "Install on EFIS", "Verify ownership"]),
    .init(id: "renew", title: "Renew / manage a licence", subtitle: "Review entitlement and renewal state", systemImage: "arrow.triangle.2.circlepath", steps: ["Identify licence", "Review status", "Choose renewal action", "Confirm change", "Verify entitlement"]),
    .init(id: "install", title: "Install / update a licence", subtitle: "Securely install a signed entitlement", systemImage: "checkmark.seal", steps: ["Connect to EFIS", "Obtain signed entitlement", "Transfer to EFIS", "Verify signature and device", "Persist licence", "Confirm VALID"]),
    .init(id: "replace", title: "Replace an EFIS", subtitle: "Move service to replacement hardware", systemImage: "rectangle.2.swap", steps: ["Identify old EFIS", "Identify replacement", "Check eligibility", "Migrate entitlement", "Install licence", "Retire old association"]),
    .init(id: "recover", title: "Recover licence access", subtitle: "Recover after phone replacement or lost cache", systemImage: "lifepreserver", steps: ["Authenticate", "Find owned EFIS", "Retrieve entitlement", "Reconnect to EFIS", "Install licence", "Verify"]),
    .init(id: "firmware", title: "Update EFIS firmware", subtitle: "Guided OTA with compatibility and recovery checks", systemImage: "arrow.down.circle", steps: ["Identify EFIS", "Check versions", "Check compatibility", "Acquire firmware", "Transfer and validate", "Activate and reboot", "Post-update checks"]),
    .init(id: "commission", title: "Commission an EFIS", subtitle: "Bring a complete EFIS / SMUX installation into service", systemImage: "checklist", steps: ["Connect", "Identify hardware", "Check firmware", "Check licence", "Discover SMUX / CAN", "Configure sensors", "Set units and thresholds", "Validate displays", "Complete commissioning"]),
    .init(id: "diagnose", title: "Diagnose a problem", subtitle: "Collect state, guide checks and verify the repair", systemImage: "stethoscope", steps: ["Connect", "Collect system state", "Identify affected subsystem", "Run guided checks", "Apply corrective action", "Retest", "Record result"])
]

struct ProcessHomeView: View {
    @EnvironmentObject var model: LicenceViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What do you want to do?")
                            .font(.title2.bold())
                        Text("Choose a process. The app will show what is complete, what needs attention and the next action.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                Section("Processes") {
                    ForEach(processCatalogue) { process in
                        NavigationLink {
                            if process.id == "reassign" {
                                ReassignEFISFlowView()
                            } else {
                                GenericProcessFlowView(process: process)
                            }
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(process.title).font(.headline)
                                    Text(process.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: process.systemImage)
                                    .foregroundStyle(.blue)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }

                Section("Advanced") {
                    NavigationLink {
                        LicenceView()
                    } label: {
                        Label("Licence diagnostics & manual controls", systemImage: "wrench.and.screwdriver")
                    }
                }
            }
            .navigationTitle("EFIS Service")
        }
    }
}

private struct GenericProcessFlowView: View {
    let process: ProcessDefinition

    var body: some View {
        List {
            Section {
                Text(process.subtitle).foregroundStyle(.secondary)
            }
            Section("Process") {
                ForEach(Array(process.steps.enumerated()), id: \.offset) { index, title in
                    ProcessStepRow(number: index + 1, title: title, detail: index == 0 ? "Ready to start" : "Waiting for previous step", state: index == 0 ? .current : .waiting)
                }
            }
            Section {
                Label("This process is defined in the common workflow architecture. Its actions will be wired to the underlying service as migration continues.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(process.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReassignEFISFlowView: View {
    @EnvironmentObject var model: LicenceViewModel

    private var account: LicenceAccountStatus? { model.account }
    private var isPending: Bool { account?.transferStatus == "PENDING" }
    private var hasAccount: Bool { account != nil }

    var body: some View {
        List {
            Section {
                activityBanner
            }

            Section("Reassignment progress") {
                ProcessStepRow(
                    number: 1,
                    title: "Confirm current EFIS",
                    detail: hasAccount ? "\(model.deviceID) · \(account?.entitlement ?? "Unknown")" : "Load the current ownership and licence state",
                    state: hasAccount ? .complete : .current
                )
                ProcessStepRow(
                    number: 2,
                    title: "Identify new owner",
                    detail: isPending ? "Transfer request has been created" : "Enter the buyer's email address",
                    state: isPending ? .complete : (hasAccount ? .current : .waiting)
                )
                ProcessStepRow(
                    number: 3,
                    title: "Buyer accepts ownership",
                    detail: isPending ? "Waiting for buyer acceptance" : "Available after the transfer request is created",
                    state: isPending ? .attention : .waiting
                )
                ProcessStepRow(number: 4, title: "Issue replacement licence", detail: "Begins after buyer acceptance", state: .waiting)
                ProcessStepRow(number: 5, title: "Install licence on EFIS", detail: "Install the new owner's signed entitlement", state: .waiting)
                ProcessStepRow(number: 6, title: "Verify reassignment", detail: "Finish only when EFIS reports VALID", state: .waiting)
            }

            Section("Next action") {
                if !hasAccount {
                    Button("Load current EFIS") {
                        Task { await model.loadManagement() }
                    }
                    .disabled(model.busy)
                } else if isPending {
                    Label("Waiting for the new owner to accept the transfer.", systemImage: "clock")
                        .foregroundStyle(.orange)
                    Text("Buyer acceptance is part of the adopted architecture but is not yet implemented in the backend/client. This workflow will resume here when that capability is added.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Refresh transfer status") {
                        Task { await model.loadManagement() }
                    }
                    .disabled(model.busy)
                    Button("Cancel reassignment", role: .destructive) {
                        Task { await model.manage("cancel-transfer") }
                    }
                    .disabled(model.busy)
                } else if account?.transferable == true {
                    TextField("Buyer email", text: $model.buyerEmail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Start reassignment") {
                        Task { await model.manage("transfer", extra: ["buyer_email": model.buyerEmail]) }
                    }
                    .disabled(model.busy || model.buyerEmail.isEmpty)
                } else {
                    Label("This licence is not transferable.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            Section("Current state") {
                LabeledContent("EFIS", value: model.deviceID)
                if let account {
                    LabeledContent("Entitlement", value: account.entitlement)
                    LabeledContent("Renewal", value: account.renewal ?? "—")
                    LabeledContent("Transfer", value: account.transferStatus ?? "None")
                }
            }
        }
        .navigationTitle("Reassign EFIS")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if model.account == nil {
                await model.loadManagement()
            }
        }
    }

    @ViewBuilder
    private var activityBanner: some View {
        HStack(spacing: 12) {
            if model.busy {
                ProgressView()
            } else {
                Image(systemName: model.activitySeverity == .success ? "checkmark.circle.fill" : model.activitySeverity == .warning ? "exclamationmark.triangle.fill" : model.activitySeverity == .error ? "xmark.octagon.fill" : "info.circle.fill")
            }
            Text(model.status.isEmpty ? "Ready to reassign EFIS" : model.status)
                .font(.headline)
        }
        .foregroundStyle(model.busy ? Color.blue : model.activitySeverity == .success ? Color.green : model.activitySeverity == .warning ? Color.orange : model.activitySeverity == .error ? Color.red : Color.blue)
        .padding(.vertical, 8)
    }
}

private struct ProcessStepRow: View {
    let number: Int
    let title: String
    let detail: String
    let state: ProcessStepState

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(state.color)
                    .frame(width: 32, height: 32)
                Image(systemName: state.symbol)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(number) · \(title)")
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(state == .attention ? .orange : .secondary)
            }
        }
        .padding(.vertical, 5)
    }
}
