import AVFoundation
import SwiftUI
import UIKit

struct DeviceQRScannerView: UIViewControllerRepresentable {
    let onDeviceID: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onDeviceID = onDeviceID
        controller.onCancel = onCancel
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onDeviceID: ((String) -> Void)?
    var onCancel: (() -> Void)?
    private let session = AVCaptureSession()
    private var preview: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.addTarget(self, action: #selector(cancelled), for: .touchUpInside)
        cancel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancel)
        NSLayoutConstraint.activate([
            cancel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            cancel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        preview = layer
        Task.detached { [session] in session.startRunning() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    @objc private func cancelled() { onCancel?() }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let value = (metadataObjects.first as? AVMetadataMachineReadableCodeObject)?.stringValue,
              let id = Self.parseDeviceID(value) else { return }
        session.stopRunning()
        onDeviceID?(id)
    }

    static func parseDeviceID(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("EFIS-") { return trimmed }
        if let url = URL(string: trimmed),
           url.scheme == "efis",
           url.host == "device" {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.hasPrefix("EFIS-") ? id : nil
        }
        return nil
    }
}
