import SwiftUI

@main
struct ESP32EFISSimulatorApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem { Label("Instruments", systemImage: "airplane") }

                NetworkSetupView()
                    .tabItem { Label("Network", systemImage: "iphone.and.arrow.forward") }

                OTAFlowView()
                    .tabItem { Label("Software Update", systemImage: "arrow.triangle.2.circlepath") }
            }
        }
    }
}
