import SwiftUI
struct Device: Identifiable { let id=UUID(); let deviceID:String; let licence:String }
struct ContentView: View {
 @State private var devices=[Device(deviceID:"EFIS-DEMO-0001",licence:"Demo / not activated")]
 var body: some View { NavigationStack { List {
  Section("My instruments") { ForEach(devices) { d in NavigationLink(d.deviceID) { Form { LabeledContent("Device ID",value:d.deviceID); LabeledContent("Licence",value:d.licence); Button("Get / Refresh Licence"){}.disabled(true); Button("Manage Payment"){}.disabled(true); Button("Offline Activation"){}.disabled(true) }.navigationTitle("Instrument") } } }
  Section { Button("Register an EFIS"){} }
 }.navigationTitle("EFIS Account") } }
}
