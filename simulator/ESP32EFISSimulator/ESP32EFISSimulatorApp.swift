import SwiftUI

@main
struct ESP32EFISSimulatorApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem { Label("Instruments", systemImage: "airplane") }

                OTAFlowView()
                    .tabItem { Label("Software Update", systemImage: "arrow.triangle.2.circlepath") }
            }
        }
    }
}
