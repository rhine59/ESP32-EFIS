import SwiftUI
import SafariServices

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
                        #if DEBUG
                        TextField("Development service URL", text: $model.serviceURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        #else
                        LabeledContent("Service", value: "RedOne Licence Service")
                        #endif
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
    .init(id: "buy", title: "Buy / activate a licence", subtitle: "Use the included first year or buy the next licence term", systemImage: "creditcard", steps: ["Identify RedOne", "Check included first year", "Confirm owner", "Activate or buy licence", "Obtain signed licence", "Install on EFIS", "Verify VALID", "Show renewal date"]),
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
                            if process.id == "buy" {
                                BuyLicenceFlowView()
                            } else if process.id == "setup" {
                                SetupNewEFISFlowView()
                            } else if process.id == "reassign" {
                                ReassignEFISFlowView()
                            } else if process.id == "receive" {
                                ReceiveTransferredEFISFlowView()
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
            .navigationTitle("Lollipop")
        }
    }
}

private struct ProcessGuidanceView: View {
    let completed: String
    let next: String
    var complete = false
    var attention = false
    var action: (() -> Void)? = nil

    @ViewBuilder
    private var nextContent: some View {
        Text(next)
            .font(.title3.weight(.semibold))
            .foregroundStyle(action == nil ? Color.primary : Color.green)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(complete ? "Process complete" : attention ? "Needs your attention" : "What to do next",
                  systemImage: complete ? "checkmark.circle.fill" : attention ? "exclamationmark.triangle.fill" : "arrow.right.circle.fill")
                .font(.headline)
                .foregroundStyle(complete ? .green : attention ? .orange : .blue)
            if let action {
                Button(action: action) { nextContent }
                    .buttonStyle(.plain)
                    .accessibilityHint("Double tap to perform the next process step")
            } else {
                nextContent
            }
        }
        .padding(.vertical, 6)
    }
}

private struct LollipopAccountFlowView: View {
    @State private var showingSignup = false
    @State private var signupReturned = false
    private var registrationURL: URL? { URL(string: EFISServiceConfiguration.accountRegistrationURL) }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Create your Lollipop account", systemImage: "person.crop.circle.badge.plus")
                        .font(.headline).foregroundStyle(.blue)
                    Text("Your Lollipop account will own your RedOne registrations and licence entitlements. Account creation is separate from buying a licence.")
                        .font(.subheadline)
                    if let registrationURL {
                        Button { showingSignup = true } label: {
                            Label("Create Lollipop account", systemImage: "person.crop.circle.badge.plus")
                                .font(.headline)
                        }
                    } else {
                        Label("Account signup service is not configured in this build.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 6)
            }
            Section("Account progress") {
                ProcessStepRow(number: 1, title: "Open secure signup", detail: signupReturned ? "Secure signup opened" : "Tap Create Lollipop account above", state: signupReturned ? .complete : .current)
                ProcessStepRow(number: 2, title: "Create account", detail: signupReturned ? "Account details submitted" : "Enter your account details in the secure Lollipop service", state: signupReturned ? .complete : .waiting)
                ProcessStepRow(number: 3, title: "Confirm account", detail: signupReturned ? "Verify the account using the link sent by email" : "Waiting for account creation", state: signupReturned ? .current : .waiting)
                ProcessStepRow(number: 4, title: "Return to EFIS Service", detail: "Continue with RedOne setup or licensing", state: .waiting)
            }
        }
        .navigationTitle("Lollipop Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSignup) {
            if let registrationURL {
                NavigationStack {
                    SafariView(url: registrationURL)
                        .navigationTitle("Create Lollipop Account")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Return to EFIS Service") { signupReturned = true; showingSignup = false } } }
                }
            }
        }
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

private struct GenericProcessFlowView: View {
    let process: ProcessDefinition

    var body: some View {
        List {
            Section {
                ProcessGuidanceView(completed: "Nothing yet.", next: "Start by \(process.steps[0].lowercased()).")
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

private struct BuyLicenceFlowView: View {
    @EnvironmentObject var model: LicenceViewModel

    private var found: Bool { model.account != nil }
    private var includedUnused: Bool { model.account?.entitlement == "INCLUDED_UNUSED" }
    private var active: Bool { ["INCLUDED_ACTIVE", "PAID_ACTIVE", "ACTIVE"].contains(model.account?.entitlement ?? "") }
    private var signed: Bool { active && model.cached?.deviceID == model.deviceID }
    private var installed: Bool { active && model.installedLicenceID != nil }

    private var completedText: String {
        if installed { return "The RedOne is identified, its licence is active, and the signed licence is installed and verified." }
        if signed { return "The RedOne is identified and its active signed licence is safely stored on this phone." }
        if active { return "The RedOne is identified and its licence entitlement is active." }
        if includedUnused { return "The RedOne is identified and its included first year is available at no charge." }
        if found { return "The RedOne and its current licence status have been identified." }
        return "Nothing yet."
    }

    private var nextText: String {
        if installed { return "No further action is required. The renewal date is shown below." }
        if signed { return "Install the signed licence on the RedOne and keep the phone connected until VALID is confirmed." }
        if active { return "Obtain the signed licence for this RedOne." }
        if includedUnused { return "Activate the included first year. There is nothing to pay." }
        if found { return "Choose the licence term you want to buy." }
        return "Enter or confirm the RedOne Device ID, then check its licence entitlement."
    }

    var body: some View {
        List {
            Section {
                ProcessGuidanceView(completed: completedText, next: nextText, complete: installed, action: installed ? nil : includedUnused ? { Task { await model.activateIncludedYear() } } : active && !signed ? { Task { await model.getEntitlement() } } : signed && !installed ? { Task { await model.transferToEFIS() } } : nil)
                HStack(spacing: 10) {
                    if model.busy { ProgressView() }
                    Text(model.busy ? "Working… \(model.status)" : model.status)
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(model.activitySeverity == .error ? .red : model.activitySeverity == .warning ? .orange : model.activitySeverity == .success ? .green : .blue)
            }
            Section("Licence progress") {
                ProcessStepRow(number: 1, title: "Identify RedOne", detail: found ? model.deviceID : "Tap to identify this RedOne", state: found ? .complete : .current, action: !found && !model.deviceID.isEmpty ? { Task { await model.loadManagement() } } : nil)
                ProcessStepRow(number: 2, title: "Check included first year", detail: includedUnused ? "Included first year available" : active ? "Licence already active" : "Check entitlement before payment", state: found ? .complete : .waiting)
                ProcessStepRow(number: 3, title: "Confirm owner", detail: found ? "Ownership record confirmed" : "Waiting for RedOne identification", state: found ? .complete : .waiting)
                ProcessStepRow(number: 4, title: "Activate or buy licence", detail: active ? (model.account?.planName ?? "Active") : includedUnused ? "Tap to activate included year — £0" : "Choose a paid licence below", state: active ? .complete : found ? .current : .waiting, action: includedUnused ? { Task { await model.activateIncludedYear() } } : nil)
                ProcessStepRow(number: 5, title: "Obtain signed licence", detail: signed ? "Signed licence secured" : "Tap to obtain the signed licence", state: signed ? .complete : active ? .current : .waiting, action: active && !signed ? { Task { await model.getEntitlement() } } : nil)
                ProcessStepRow(number: 6, title: "Install on EFIS", detail: installed ? "Installed" : "Tap to install the signed licence", state: installed ? .complete : signed ? .current : .waiting, action: signed && !installed ? { Task { await model.transferToEFIS() } } : nil)
                ProcessStepRow(number: 7, title: "Verify VALID", detail: installed ? "EFIS reported VALID" : "Requires EFIS acknowledgement", state: installed ? .complete : .waiting)
                ProcessStepRow(number: 8, title: "Show renewal date", detail: model.account?.validUntil ?? (installed ? "No expiry for this plan" : "Available after activation"), state: installed ? .complete : .waiting)
            }
            if let account = model.account {
                Section("Licence") {
                    LabeledContent("Type", value: account.planName ?? account.entitlement)
                    LabeledContent("Valid until", value: account.validUntil ?? "No expiry")
                    LabeledContent("Renewal", value: account.renewal ?? "None")
                }
            }
        }
        .navigationTitle("Buy / activate licence")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SetupNewEFISFlowView: View {
    @EnvironmentObject var model: LicenceViewModel

    private var accountLoaded: Bool { model.account != nil }
    private var includedUnused: Bool { model.account?.entitlement == "INCLUDED_UNUSED" }
    private var active: Bool { ["INCLUDED_ACTIVE", "PAID_ACTIVE", "ACTIVE"].contains(model.account?.entitlement ?? "") }
    private var signed: Bool { active && model.cached?.deviceID == model.deviceID }
    private var installed: Bool { active && model.installedLicenceID != nil }

    private var completedText: String {
        if installed { return "The EFIS is identified, licensed, and the installed licence has been verified VALID." }
        if signed { return "The EFIS is identified and its signed licence is stored on this phone." }
        if active { return "The EFIS is identified and its licence is active." }
        if includedUnused { return "The EFIS is identified and its included first year is available." }
        if accountLoaded { return "The EFIS and ownership record have been identified." }
        return "Nothing yet."
    }

    private var nextText: String {
        if installed { return "Setup is complete. No further action is required." }
        if signed { return "Install the signed licence on the EFIS." }
        if active { return "Obtain the signed licence for this EFIS." }
        if includedUnused { return "Activate the included first year. There is nothing to pay." }
        if accountLoaded { return "Choose a licence term below." }
        return "Identify this EFIS using the Device ID shown below."
    }

    private var nextAction: (() -> Void)? {
        if installed { return nil }
        if signed { return { Task { await model.transferToEFIS() } } }
        if active { return { Task { await model.getEntitlement() } } }
        if includedUnused { return { Task { await model.activateIncludedYear() } } }
        if !accountLoaded && !model.deviceID.isEmpty { return { Task { await model.loadManagement() } } }
        return nil
    }

    var body: some View {
        List {
            Section {
                ProcessGuidanceView(completed: completedText, next: nextText, complete: installed, action: nextAction)
                HStack(spacing: 10) {
                    if model.busy { ProgressView() }
                    Text(model.busy ? "Working… \(model.status)" : model.status)
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(model.activitySeverity == .error ? .red : model.activitySeverity == .warning ? .orange : model.activitySeverity == .success ? .green : .blue)
            }

            Section("Setup progress") {
                ProcessStepRow(number: 1, title: "Identify EFIS", detail: accountLoaded ? model.deviceID : "Press this step to identify \(model.deviceID)", state: accountLoaded ? .complete : .current, action: !accountLoaded && !model.deviceID.isEmpty ? { Task { await model.loadManagement() } } : nil)
                ProcessStepRow(number: 2, title: "Register owner", detail: accountLoaded ? "Ownership record confirmed" : "Confirmed when the service recognises this EFIS", state: accountLoaded ? .complete : .waiting)
                ProcessStepRow(number: 3, title: includedUnused ? "Activate included first year" : "Choose licence", detail: active ? (model.account?.planName ?? "ACTIVE entitlement") : includedUnused ? "Included first year — £0" : "Choose an available licence plan below", state: active ? .complete : (accountLoaded ? .current : .waiting), action: includedUnused ? { Task { await model.activateIncludedYear() } } : nil)
                ProcessStepRow(number: 4, title: "Obtain signed licence", detail: signed ? "Signed entitlement secured on this phone" : "Tap to obtain the signed licence", state: signed ? .complete : (active ? .current : .waiting), action: active && !signed ? { Task { await model.getEntitlement() } } : nil)
                ProcessStepRow(number: 5, title: "Install on EFIS", detail: installed ? "EFIS acknowledged installation" : "Tap to install the signed licence", state: installed ? .complete : (signed ? .current : .waiting), action: signed && !installed ? { Task { await model.transferToEFIS() } } : nil)
                ProcessStepRow(number: 6, title: "Verify installation", detail: installed ? "EFIS reported VALID" : "Requires explicit EFIS acknowledgement", state: installed ? .complete : .waiting)
            }

            Section("Status") {
                Text(model.status)
                    .foregroundStyle(model.activitySeverity == .error ? .red : model.activitySeverity == .warning ? .orange : .secondary)
                if let id = model.installedLicenceID {
                    LabeledContent("Installed Licence ID", value: id)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Set up new EFIS")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReceiveTransferredEFISFlowView: View {
    @EnvironmentObject var model: LicenceViewModel

    private var pending: Bool { model.account?.transferStatus == "PENDING" }
    private var accepted: Bool { model.account?.transferStatus == "ACCEPTED" }
    private var signed: Bool { accepted && model.cached?.deviceID == model.deviceID }
    private var installed: Bool { accepted && model.installedLicenceID != nil }

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: installed ? "checkmark.circle.fill" : pending ? "arrow.right.circle.fill" : "info.circle.fill")
                    VStack(alignment: .leading) {
                        Text(installed ? "Next: no further action." : accepted ? "Next: obtain and install the replacement licence." : pending ? "Next: enter the invited buyer email and accept ownership." : "Next: find the pending transfer.")
                        Text(installed ? "Completed: ownership and licence installation." : accepted ? "Completed: invitation found and ownership accepted." : pending ? "Completed: transfer invitation found." : "Completed: nothing yet.").font(.subheadline).foregroundStyle(.secondary)
                    }
                        .font(.headline)
                }
                .foregroundStyle(installed ? .green : accepted || pending ? .blue : .secondary)
            }

            Section("Transfer progress") {
                ProcessStepRow(number: 1, title: "Find transferred EFIS", detail: model.deviceID, state: model.account != nil ? .complete : .current)
                ProcessStepRow(number: 2, title: "Match buyer", detail: pending ? "Enter the invited buyer email" : accepted ? "Buyer matched transfer invitation" : "Requires a pending invitation", state: accepted ? .complete : pending ? .current : .waiting)
                ProcessStepRow(number: 3, title: "Accept ownership", detail: accepted ? "Ownership changed atomically" : "Available after buyer match", state: accepted ? .complete : pending ? .current : .waiting)
                ProcessStepRow(number: 4, title: "Obtain replacement licence", detail: signed ? "Signed entitlement secured" : "Tap to obtain the replacement licence", state: signed ? .complete : accepted ? .current : .waiting, action: accepted && !signed ? { Task { await model.getEntitlement() } } : nil)
                ProcessStepRow(number: 5, title: "Install on EFIS", detail: installed ? "EFIS acknowledged installation" : "Tap to install the buyer entitlement", state: installed ? .complete : signed ? .current : .waiting, action: signed && !installed ? { Task { await model.transferToEFIS() } } : nil)
                ProcessStepRow(number: 6, title: "Verify ownership", detail: installed ? "EFIS reported VALID" : "Requires explicit EFIS acknowledgement", state: installed ? .complete : .waiting)
            }

            Section("Status") {
                Text(model.status).foregroundStyle(model.activitySeverity == .error ? .red : model.activitySeverity == .warning ? .orange : .secondary)
            }
        }
        .navigationTitle("Receive transferred EFIS")
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
                if !hasAccount {
                    ProcessGuidanceView(completed: "", next: "Load the current EFIS details.", action: { Task { await model.loadManagement() } })
                } else if isPending {
                    ProcessGuidanceView(completed: "", next: "Wait for the buyer to accept ownership, then refresh the transfer status.", attention: true, action: { Task { await model.loadManagement() } })
                    Button("Cancel reassignment", role: .destructive) { Task { await model.manage("cancel-transfer") } }
                        .disabled(model.busy)
                } else if account?.transferable == true {
                    ProcessGuidanceView(completed: "", next: "Enter the new owner email and start the reassignment.")
                    TextField("Buyer email", text: $model.buyerEmail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Start reassignment") { Task { await model.manage("transfer", extra: ["buyer_email": model.buyerEmail]) } }
                        .disabled(model.busy || model.buyerEmail.isEmpty)
                } else {
                    ProcessGuidanceView(completed: "", next: "This licence is not transferable.", attention: true)
                }
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
    var action: (() -> Void)? = nil

    private var actionable: Bool {
        action != nil && (state == .current || state == .attention || state == .failed)
    }

    @ViewBuilder
    private var rowContent: some View {
        HStack(alignment: .center, spacing: 14) {
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
            Spacer(minLength: 8)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .opacity(state == .waiting ? 0.55 : 1)
    }

    var body: some View {
        if actionable, let action {
            Button(action: action) {
                rowContent
            }
            .buttonStyle(.borderless)
            .accessibilityHint("Double tap to perform this step")
        } else {
            rowContent
        }
    }
}
