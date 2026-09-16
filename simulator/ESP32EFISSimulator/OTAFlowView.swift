import SwiftUI

enum OTAUserState: String {
    case maintenance = "Maintenance"
    case checking = "Checking for update"
    case available = "Update available"
    case confirm = "Confirm installation"
    case downloading = "Downloading"
    case verifying = "Verifying image"
    case rebooting = "Restarting"
    case firstBoot = "Verifying new software"
    case installed = "Update complete"
    case rollback = "Restoring previous software"
    case restored = "Previous software restored"
}

struct OTAFlowView: View {
    @State private var state: OTAUserState = .maintenance
    @State private var progress = 0.0
    @State private var simulateFailure = false
    @State private var currentVersion = "0.4.0"
    private let candidateVersion = "0.4.1"
    private let timer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text("OTA USER-FLOW SIMULATION")
                        .font(.caption.bold()).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.red, in: Capsule())

                    Image(systemName: icon)
                        .font(.system(size: 54, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)

                    Text(state.rawValue).font(.title2.bold()).multilineTextAlignment(.center)
                    Text(detail).multilineTextAlignment(.center).foregroundStyle(.secondary)

                    if showsVersions {
                        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
                            GridRow { Text("Installed").foregroundStyle(.secondary); Text(currentVersion).monospaced() }
                            GridRow { Text("Available").foregroundStyle(.secondary); Text(candidateVersion).monospaced() }
                            GridRow { Text("Hardware").foregroundStyle(.secondary); Text("s3-n16r2-v1").monospaced() }
                            GridRow { Text("Source").foregroundStyle(.secondary); Text("HTTPS OTA server") }
                        }
                        .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }

                    if state == .downloading || state == .verifying || state == .firstBoot || state == .rollback {
                        ProgressView(value: progress).progressViewStyle(.linear)
                        Text("\(Int(progress * 100))%").font(.caption.monospacedDigit())
                    }

                    controls

                    if state == .available || state == .confirm {
                        Toggle("Simulate first-boot failure", isOn: $simulateFailure)
                            .padding(.top, 8)
                    }

                    Text("Simulation only. No network connection, firmware download, flash write or reboot is performed by this iOS simulator.")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: 620).padding(24).frame(maxWidth: .infinity)
            }
            .navigationTitle("Software Update")
        }
        .onReceive(timer) { _ in advanceTimedState() }
    }

    @ViewBuilder private var controls: some View {
        switch state {
        case .maintenance:
            Button("Check for Update") { state = .checking; progress = 0 }.buttonStyle(.borderedProminent)
        case .checking:
            ProgressView()
        case .available:
            Button("Review Update") { state = .confirm }.buttonStyle(.borderedProminent)
            Button("Not Now") { reset() }.buttonStyle(.bordered)
        case .confirm:
            Button("Install \(candidateVersion)") { state = .downloading; progress = 0 }.buttonStyle(.borderedProminent)
            Button("Cancel") { state = .available }.buttonStyle(.bordered)
        case .installed, .restored:
            Button("Return to Maintenance") { reset() }.buttonStyle(.borderedProminent)
        default:
            EmptyView()
        }
    }

    private var showsVersions: Bool { state != .checking }

    private var icon: String {
        switch state {
        case .installed: return "checkmark.circle.fill"
        case .rollback, .restored: return "arrow.uturn.backward.circle.fill"
        case .downloading: return "arrow.down.circle.fill"
        case .rebooting, .firstBoot: return "power.circle.fill"
        default: return "arrow.triangle.2.circlepath.circle.fill"
        }
    }

    private var detail: String {
        switch state {
        case .maintenance: return "Updates are a deliberate maintenance operation. Normal flight pages are not part of this workflow."
        case .checking: return "Simulating HTTPS manifest retrieval and compatibility checks."
        case .available: return "A compatible approved release is available. Nothing is installed until you explicitly confirm."
        case .confirm: return "The candidate will be written to the inactive OTA slot. The current known-good software remains available for rollback."
        case .downloading: return "Downloading to the inactive slot. The current firmware is not overwritten."
        case .verifying: return "Checking the completed candidate image before it can be selected for boot."
        case .rebooting: return "The candidate slot has been selected. Simulating restart into pending-verification software."
        case .firstBoot: return "Running first-boot software self-tests before the candidate is accepted as known-good."
        case .installed: return "The candidate passed verification and is now the known-good software."
        case .rollback: return "First-boot verification failed. The candidate is rejected and the previous known-good slot is being restored."
        case .restored: return "Update failed safely. The previous known-good software is active again."
        }
    }

    private func advanceTimedState() {
        switch state {
        case .checking:
            progress += 0.2
            if progress >= 1 { progress = 0; state = .available }
        case .downloading:
            progress += 0.025
            if progress >= 1 { progress = 0; state = .verifying }
        case .verifying:
            progress += 0.08
            if progress >= 1 { progress = 0; state = .rebooting }
        case .rebooting:
            progress += 0.2
            if progress >= 1 { progress = 0; state = .firstBoot }
        case .firstBoot:
            progress += 0.05
            if progress >= 1 {
                progress = 0
                if simulateFailure { state = .rollback } else { currentVersion = candidateVersion; state = .installed }
            }
        case .rollback:
            progress += 0.08
            if progress >= 1 { progress = 0; state = .restored }
        default: break
        }
    }

    private func reset() {
        state = .maintenance
        progress = 0
        simulateFailure = false
    }
}
