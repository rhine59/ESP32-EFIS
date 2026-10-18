import SwiftUI

/// Single entry point for the guided RedOne firmware update process.
/// Download, connection and future transfer actions share one screen.
struct UpdateEFISFlowView: View {
    var body: some View {
        EFISWiFiView()
    }
}
