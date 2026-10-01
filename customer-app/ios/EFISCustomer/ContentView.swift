import SwiftUI

struct FirmwareNode: Identifiable {
    let id = UUID(); let type:String; let installed:String; let available:String; let capabilities:[String]
}
struct ContentView: View {
 @State private var cached=false
 @State private var connected=false
 @State private var nodes=[
   FirmwareNode(type:"Horizon",installed:"2.4.0",available:"2.5.0",capabilities:["AEF-CAN 1.3","ENGINE_DATA_V2","OTA_V1"]),
   FirmwareNode(type:"EIU",installed:"1.7.0",available:"1.9.0",capabilities:["AEF-CAN 1.3","ENGINE_DATA_V1+V2","OTA_V1"])
 ]
 var body: some View {
  NavigationStack { List {
   Section("My instrument") {
    LabeledContent("Device ID",value:"EFIS-DEMO-0001")
    LabeledContent("Licence",value:"Demo / not activated")
   }
   Section("Firmware release set") {
    ForEach(nodes) { n in
     VStack(alignment:.leading,spacing:4) {
      Text(n.type).font(.headline)
      Text("Installed \(n.installed)  →  Available \(n.available)")
      Text(n.capabilities.joined(separator:" • ")).font(.caption).foregroundStyle(.secondary)
     }
    }
    LabeledContent("Update order",value:"EIU → Horizon")
    LabeledContent("Offline readiness",value:cached ? "READY" : "NOT CACHED")
    Button(cached ? "Release Set Cached" : "Cache Release Set for Offline Update") { cached=true }.disabled(cached)
   }
   Section("At aircraft") {
    Toggle("Connected to Horizon maintenance Wi-Fi",isOn:$connected)
    Button("Transfer Cached Release Set to Horizon") { }.disabled(!cached || !connected)
    Text("Horizon verifies signatures, hardware, AEF-CAN capabilities and safe sequencing. The phone cannot override activation gates. EIU firmware is delivered by Horizon over AEF-CAN.")
      .font(.footnote).foregroundStyle(.secondary)
   }
   Section("Account") {
    Button("Get / Refresh Licence"){}.disabled(true)
    Button("Manage Payment"){}.disabled(true)
    Button("Offline Activation"){}.disabled(true)
   }
  }.navigationTitle("MicroSky Horizon") }
 }
}
