import SwiftUI
import NetworkExtension
import UniformTypeIdentifiers
import CryptoKit

private struct PublishedFirmware: Decodable {
    let product: String
    let version: String
    let hardware_profile: String
    let image_url: URL
    let sha256: String
    let release_notes: String?
}

private struct RedOneStatus: Decodable {
    let device: String
    let version: String
    let running: String
    let next: String
    let rollbackAvailable: Bool?
    let rollbackReason: String?
    let previousVersion: String?
    let updateReady: Bool?
    let apiVersion: Int?
    let bootState: String?
}

struct EFISWiFiView: View {
    @State private var message = "Not connected"
    @State private var verified: RedOneStatus?
    @State private var checking = false
    @State private var showingFirmwarePicker = false
    @State private var firmwareName: String?
    @State private var firmwareSize: Int64?
    @State private var firmwareDigest: String?
    @State private var firmwareError: String?
    @State private var preparingFirmware = false
    @State private var publishedFirmware: PublishedFirmware?
    @State private var signedReleaseStatus = "No signed release checked"
    @State private var trustedEnvelope: SignedFirmwareEnvelope?
    @State private var firmwareSource = "publisher"
    @State private var firmwareAssessment = "No release verified"
    @State private var selectedRelease: CachedFirmwareRelease?
    @State private var downloadedReleases: [CachedFirmwareRelease] = []
    private let publisherURL = URL(string: "https://granvillehouse.synology.me:8448/efis/manifest.json")!
    @AppStorage("redone.savedMacAddress") private var savedMacAddress = ""
    @State private var macAddress = ""
    @State private var showingSavedNetworkChoice = false
    private var suffix: String {
        macAddress.uppercased().filter { "0123456789ABCDEF".contains($0) }
    }
    private var ssid: String { "RedOne_" + suffix }
    @State private var chooseNewDevice = false

    var body: some View {
        List {
            Section("1. Download signed firmware") {
                Text("While online, check for a signed release and download it. Signature and SHA-256 checks are performed automatically. Select a previously downloaded release to continue offline.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Check publisher for signed release") { Task { await fetchPublishedFirmware() } }
                    .disabled(preparingFirmware)
                Text(signedReleaseStatus).font(.footnote).foregroundStyle(.secondary)
                if let publishedFirmware {
                    LabeledContent("Published version", value: publishedFirmware.version)
                    LabeledContent("Hardware profile", value: publishedFirmware.hardware_profile)
                    if let notes = publishedFirmware.release_notes { Text(notes).font(.footnote) }
                    Button("Download signed release") { Task { await downloadPublishedFirmware() } }
                        .disabled(preparingFirmware || trustedEnvelope == nil)
                }
                if downloadedReleases.isEmpty {
                    Text("No published firmware downloaded. Prepare while online before visiting the aircraft.")
                        .foregroundStyle(.secondary)
                }
                ForEach(downloadedReleases) { release in
                    Button {
                        selectCachedRelease(release)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("RedOne \(release.version)").font(.headline)
                            Text(release.hardwareProfile).font(.caption)
                            Text(release.downloadedAt, style: .date).font(.caption)
                            Text(FirmwareLibrary.verify(release) ? "Trusted signed release verified" :
                                 release.signedEnvelope == nil ? "Legacy unsigned cache — download a signed copy" : "Signed release verification failed — download again")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()
                Text("Automatic release verification").font(.headline)
                if let selectedRelease {
                    LabeledContent("Selected release", value: selectedRelease.version)
                    Label(FirmwareLibrary.verify(selectedRelease) ? "Signature and SHA-256 verified" : "Verification failed — transfer blocked", systemImage: FirmwareLibrary.verify(selectedRelease) ? "checkmark.shield" : "xmark.shield")
                        .foregroundStyle(FirmwareLibrary.verify(selectedRelease) ? .green : .red)
                    if let firmwareDigest { Text("SHA-256: \(firmwareDigest)").font(.caption2).textSelection(.enabled) }
                    if let problem = FirmwareLibrary.transferPreflight(selectedRelease) {
                        Text("Transfer preflight: \(problem)").foregroundStyle(.orange)
                    }
                } else {
                    Text("Select a downloaded release above to verify its signature and checksum before connecting.")
                        .foregroundStyle(.secondary)
                }
                Text(firmwareAssessment).font(.footnote).foregroundStyle(.secondary)
                if let firmwareError { Text(firmwareError).foregroundStyle(.red).font(.footnote) }
            }
            Section("2. Connect to EFIS") {
                Text("Enter the 12-digit Wi-Fi MAC address printed on your EFIS or its QR label.")
                    .font(.footnote).foregroundStyle(.secondary)
                if !savedMacAddress.isEmpty {
                    Button("Rejoin saved RedOne") {
                        macAddress = savedMacAddress
                        joinNetwork()
                    }
                    Button("Join a new RedOne") {
                        macAddress = ""
                        chooseNewDevice = true
                    }
                    LabeledContent("Saved network", value: "RedOne_" + savedMacAddress)
                }
                if savedMacAddress.isEmpty || chooseNewDevice {
                TextField("Wi-Fi MAC address", text: $macAddress)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                }
                LabeledContent("Network", value: ssid)
                Label(message, systemImage: verified == nil ? "wifi.exclamationmark" : "checkmark.circle.fill")
                    .foregroundStyle(verified == nil ? Color.secondary : Color.green)
                if let verified {
                    LabeledContent("Device", value: verified.device)
                    LabeledContent("Firmware", value: verified.version)
                    LabeledContent("Running partition", value: verified.running)
                    LabeledContent("Next update partition", value: verified.next)
                }
                Button("Join RedOne network") {
                    joinNetwork()
                }
                .disabled(suffix.count != 12 || checking)
                Button("Verify RedOne connection") {
                    Task { await verifyConnection() }
                }
                .disabled(checking)
            }
            Section("Firmware update") {
                if let verified {
                    LabeledContent("Installed version", value: verified.version)
                    LabeledContent("Active partition", value: verified.running)
                    LabeledContent("Boot state", value: verified.bootState ?? "Not reported")
                    LabeledContent("Management API", value: verified.apiVersion.map(String.init) ?? "Legacy")
                    LabeledContent("Update destination", value: verified.next)
                    LabeledContent("Previous version", value: verified.previousVersion ?? "Not reported")
                    LabeledContent("Rollback", value: verified.rollbackAvailable == true ? "Available" : "Unavailable")
                    if let reason = verified.rollbackReason, verified.rollbackAvailable != true {
                        Text(reason).font(.footnote).foregroundStyle(.secondary)
                    }
                } else {
                    Text("Connect to and verify your RedOne to inspect firmware.")
                        .foregroundStyle(.secondary)
                }
                Text("Firmware transfer requires a previously downloaded and verified signed release. The device must independently authenticate the release before writing flash.")
                    .font(.footnote).foregroundStyle(.secondary)
                Label("3. Push firmware to EFIS", systemImage: "arrow.up.circle")
                    .font(.headline)
                Button("Push selected firmware") { }
                    .disabled(true)
                Text("Requires an authenticated RedOne connection and a verified, signed release.")
                    .font(.footnote).foregroundStyle(.secondary)
                Label("4. Verify transferred firmware", systemImage: "checkmark.shield")
                    .font(.headline)
                Button("Verify transferred image") { }
                    .disabled(true)
                Label("5. Activate firmware", systemImage: "power")
                    .font(.headline)
                Button("Activate verified firmware") { }
                    .disabled(true)
                Text("Activation requires explicit confirmation on the ground, followed by reboot and health verification.")
                    .font(.footnote).foregroundStyle(.secondary)
                Label("6. Rollback", systemImage: "arrow.uturn.backward")
                    .font(.headline)
                Button("Roll back to previous firmware") { }
                    .disabled(true)
                Text("Firmware changes are locked until signed-image validation, device authentication and A/B recovery testing pass. No firmware will be changed by this screen.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .fileImporter(isPresented: $showingFirmwarePicker, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
            Task { await inspectFirmware(result) }
        }
        .navigationTitle("Update EFIS")
        .onAppear {
            if !savedMacAddress.isEmpty { macAddress = savedMacAddress }
            reloadLibrary()
        }
    }

    private func reloadLibrary() {
        do { downloadedReleases = try FirmwareLibrary.load() }
        catch { firmwareError = "Cannot read firmware library: \(error.localizedDescription)" }
    }

    private func selectCachedRelease(_ release: CachedFirmwareRelease) {
        guard FirmwareLibrary.verify(release) else {
            selectedRelease = nil
            firmwareError = "Cached firmware is missing or corrupt."
            return
        }
        firmwareError = nil
        selectedRelease = release
        firmwareName = release.filename
        firmwareDigest = release.sha256
        firmwareSize = (try? FirmwareLibrary.folder.appendingPathComponent(release.filename)
            .resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
        firmwareAssessment = "Offline signed release and checksum verified"
    }

    @MainActor
    private func checkSignedRelease() async {
        signedReleaseStatus = "Checking signed release…"
        trustedEnvelope = nil
        do {
            let url = publisherURL.deletingLastPathComponent().appendingPathComponent("manifest.signed.json")
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                signedReleaseStatus = "Publisher has not supplied a signed release"
                return
            }
            let envelope = try JSONDecoder().decode(SignedFirmwareEnvelope.self, from: data)
            guard SignedFirmwareVerifier.verify(envelope),
                  let release = publishedFirmware,
                  envelope.payload.version == release.version,
                  envelope.payload.hardware_profile == release.hardware_profile,
                  envelope.payload.sha256.caseInsensitiveCompare(release.sha256) == .orderedSame,
                  envelope.payload.image_url == release.image_url.absoluteString else {
                signedReleaseStatus = "Signed release does not match published firmware — update locked"
                return
            }
            trustedEnvelope = envelope
            signedReleaseStatus = "Signed release verified"
        } catch { signedReleaseStatus = "Signed release unavailable — update locked" }
    }

    @MainActor
    private func fetchPublishedFirmware() async {
        preparingFirmware = true
        defer { preparingFirmware = false }
        publishedFirmware = nil
        trustedEnvelope = nil
        firmwareError = nil
        firmwareAssessment = "Checking publisher…"
        do {
            var request = URLRequest(url: publisherURL)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200, data.count < 65536 else { throw URLError(.badServerResponse) }
            let release = try JSONDecoder().decode(PublishedFirmware.self, from: data)
            guard release.product == "ESP32-EFIS", release.hardware_profile == "s3-n16r2-v1",
                  release.image_url.scheme == "https", release.image_url.host == publisherURL.host,
                  release.image_url.port == publisherURL.port,
                  release.sha256.count == 64,
                  release.sha256.allSatisfy({ $0.isHexDigit }) else { throw URLError(.cannotParseResponse) }
            publishedFirmware = release
            firmwareAssessment = "Publisher metadata retrieved; not cryptographically certified"
            await checkSignedRelease()
        } catch { firmwareAssessment = "Publisher unavailable"; firmwareError = error.localizedDescription }
    }

    @MainActor
    private func downloadPublishedFirmware() async {
        guard let release = publishedFirmware, let envelope = trustedEnvelope,
              SignedFirmwareVerifier.verify(envelope),
              envelope.payload.sha256.caseInsensitiveCompare(release.sha256) == .orderedSame,
              envelope.payload.image_url == release.image_url.absoluteString else {
            firmwareError = "A matching trusted signed manifest is required before download."
            return
        }
        preparingFirmware = true
        defer { preparingFirmware = false }
        firmwareError = nil
        firmwareAssessment = "Downloading and checking checksum…"
        do {
            var request = URLRequest(url: release.image_url)
            request.timeoutInterval = 60
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  data.count >= 1024, data.count <= 16 * 1024 * 1024 else { throw URLError(.badServerResponse) }
            let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard digest.caseInsensitiveCompare(release.sha256) == .orderedSame else { throw URLError(.cannotDecodeContentData) }
            let cached = try FirmwareLibrary.store(data, envelope: envelope)
            let destination = FirmwareLibrary.folder.appendingPathComponent(cached.filename)
            reloadLibrary()
            selectedRelease = cached
            firmwareName = destination.lastPathComponent
            firmwareSize = Int64(data.count)
            firmwareDigest = digest
            firmwareAssessment = "Trusted signed release downloaded and verified for offline use"
        } catch {
            firmwareName = nil; firmwareSize = nil; firmwareDigest = nil
            firmwareAssessment = "Download verification failed"
            firmwareError = error.localizedDescription
        }
    }

    @MainActor
    private func inspectFirmware(_ result: Result<[URL], Error>) async {
        selectedRelease = nil
        firmwareName = nil
        firmwareSize = nil
        firmwareDigest = nil
        firmwareError = nil
        guard case .success(let urls) = result, let url = urls.first else {
            if case .failure(let error) = result { firmwareError = error.localizedDescription }
            return
        }
        preparingFirmware = true
        defer { preparingFirmware = false }
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values.isRegularFile == true, let size = values.fileSize,
                  size >= 1024, size <= 16 * 1024 * 1024 else {
                firmwareError = "Select a regular firmware file between 1 KB and 16 MB."
                return
            }
            let data = try Data(contentsOf: url)
            let digest = SHA256.hash(data: data)
            firmwareName = url.lastPathComponent
            firmwareSize = Int64(data.count)
            firmwareDigest = digest.map { String(format: "%02x", $0) }.joined()
            if let publishedFirmware,
               firmwareDigest?.caseInsensitiveCompare(publishedFirmware.sha256) == .orderedSame {
                firmwareAssessment = "Matches publisher checksum; imported files are not trusted releases"
            } else {
                firmwareAssessment = "Local copy inspected, NOT certified; signed release proof required"
            }
        } catch { firmwareError = "Cannot inspect firmware: \(error.localizedDescription)" }
    }

    private func joinNetwork() {
                    verified = nil
                    message = "Requesting Wi-Fi connection…"
                    let config = NEHotspotConfiguration(ssid: ssid, passphrase: "BenchOnly-2026!", isWEP: false)
                    config.joinOnce = true
                    NEHotspotConfigurationManager.shared.apply(config) { error in
                        Task { @MainActor in
                            if let error = error as NSError?,
                               error.code != NEHotspotConfigurationError.alreadyAssociated.rawValue {
                                message = "Wi-Fi join failed: \(error.localizedDescription)"
                            } else {
                                await verifyConnection()
                            }
                        }
                    }
    }

    @MainActor
    private func verifyConnection() async {
        checking = true
        verified = nil
        message = "Checking RedOne device…"
        defer { checking = false }
        guard let url = URL(string: "http://192.168.4.1/status") else { return }
        for attempt in 0..<6 {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 3
                request.cachePolicy = .reloadIgnoringLocalCacheData
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                let status = try JSONDecoder().decode(RedOneStatus.self, from: data)
                guard status.device == "RedOne" else {
                    message = "Unexpected device response — connection not verified"
                    return
                }
                verified = status
                if suffix.count == 12 { savedMacAddress = suffix }
                message = "Connected to RedOne — device verified"
                return
            } catch {
                if attempt == 5 {
                    message = "Unable to verify RedOne. Check Wi-Fi and tap Verify again."
                    return
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
