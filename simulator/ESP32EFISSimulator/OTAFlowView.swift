import SwiftUI

enum OTAUserState: String { case maintenance="Maintenance", checking="Checking for update", available="Update available", downloading="Downloading update", ready="Update ready", rebooting="Restarting", firstBoot="Verifying new software", installed="Update complete", rollback="Restoring previous software", restored="Previous software restored" }

struct OTAFlowView: View {
 @AppStorage("efis.ota.autoDownload") private var autoDownload=true
 @State private var state:OTAUserState = .maintenance; @State private var progress=0.0; @State private var simulateFailure=false; @State private var currentVersion="0.4.0"; private let candidateVersion="0.4.1"
 private let timer=Timer.publish(every:0.12,on:.main,in:.common).autoconnect()
 var body:some View { NavigationStack { ScrollView { VStack(spacing:18) {
  Text("OTA USER-FLOW SIMULATION").font(.caption.bold()).foregroundStyle(.white).padding(.horizontal,12).padding(.vertical,6).background(.red,in:Capsule())
  Image(systemName:icon).font(.system(size:54,weight:.semibold)).symbolRenderingMode(.hierarchical)
  Text(state.rawValue).font(.title2.bold()); Text(detail).multilineTextAlignment(.center).foregroundStyle(.secondary)
  Grid(alignment:.leading,horizontalSpacing:24,verticalSpacing:8){ GridRow{Text("Installed").foregroundStyle(.secondary);Text(currentVersion).monospaced()}; GridRow{Text("Published").foregroundStyle(.secondary);Text(candidateVersion).monospaced()}; GridRow{Text("Source").foregroundStyle(.secondary);Text("HTTPS OTA server")} }.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:16))
  if state == .maintenance { Toggle("Automatically download next update",isOn:$autoDownload); Text("Downloads only while in maintenance with a configured network. Activation and reboot always require your command.").font(.footnote).foregroundStyle(.secondary) }
  if [.downloading,.firstBoot,.rollback].contains(state){ProgressView(value:progress);Text("\(Int(progress*100))%").font(.caption.monospacedDigit())}
  controls
  if state == .ready { Toggle("Simulate first-boot failure",isOn:$simulateFailure) }
  Text("Simulation only. Automatic download never means automatic activation.").font(.footnote).foregroundStyle(.secondary)
 }.frame(maxWidth:620).padding(24).frame(maxWidth:.infinity) }.navigationTitle("Software Update") }.onReceive(timer){_ in advance()} }
 @ViewBuilder private var controls:some View { switch state {
 case .maintenance: Button("Check for Update"){state = .checking;progress=0}.buttonStyle(.borderedProminent)
 case .checking: ProgressView()
 case .available: Button("Download \(candidateVersion)"){state = .downloading;progress=0}.buttonStyle(.borderedProminent);Button("Later"){reset()}.buttonStyle(.bordered)
 case .ready: Button("ACTIVATE & REBOOT"){state = .rebooting;progress=0}.buttonStyle(.borderedProminent);Button("Later"){reset()}.buttonStyle(.bordered)
 case .installed,.restored: Button("Return to Maintenance"){reset()}.buttonStyle(.borderedProminent)
 default: EmptyView() } }
 private var icon:String { switch state {case .installed:return "checkmark.circle.fill";case .rollback,.restored:return "arrow.uturn.backward.circle.fill";case .downloading:return "arrow.down.circle.fill";case .ready:return "checkmark.seal.fill";case .rebooting,.firstBoot:return "power.circle.fill";default:return "arrow.triangle.2.circlepath.circle.fill"} }
 private var detail:String { switch state {case .maintenance:return "Check the administrator-published release. The next update may be downloaded automatically, but never activated automatically.";case .checking:return "Retrieving the published manifest and checking compatibility.";case .available:return "A published compatible release is available.";case .downloading:return "Writing the verified download to the inactive OTA slot. Current software remains untouched.";case .ready:return "The new image is downloaded and verified. It will not run until you select ACTIVATE & REBOOT.";case .rebooting:return "Selecting the candidate slot and restarting.";case .firstBoot:return "The candidate must pass first-boot self-tests before becoming known-good.";case .installed:return "The candidate passed verification and is now known-good.";case .rollback:return "Verification failed. Restoring the previous known-good slot.";case .restored:return "The previous known-good software is active again."} }
 private func advance(){switch state {case .checking:progress += 0.2;if progress>=1 {progress=0;state=autoDownload ? .downloading:.available};case .downloading:progress += 0.025;if progress>=1 {progress=0;state = .ready};case .rebooting:progress += 0.2;if progress>=1 {progress=0;state = .firstBoot};case .firstBoot:progress += 0.05;if progress>=1 {progress=0;if simulateFailure {state = .rollback}else{currentVersion=candidateVersion;state = .installed}};case .rollback:progress += 0.08;if progress>=1 {progress=0;state = .restored};default:break}}
 private func reset(){state = .maintenance;progress=0;simulateFailure=false}
}
