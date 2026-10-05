import SwiftUI

@main
struct EFISServiceApp: App {
    @StateObject private var model = LicenceViewModel()

    var body: some Scene {
        WindowGroup {
            ProcessHomeView()
                .environmentObject(model)
        }
    }
}
