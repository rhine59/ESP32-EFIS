import SwiftUI
import NetworkExtension
import CoreLocation
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
    @State private var signedReleaseStatus = "No release checked"
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
    @State private var scanningConnectionQR = false
    @State private var currentWiFi = "Not connected to WiFi"
    @State private var connectionPassword: String?
    @State private var qrError: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down.on.square.fill")
                        .font(.largeTitle).foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("FIRMWARE LIBRARY").font(.caption.weight(.bold))
                        Text("Signed releases only").font(.caption).foregroundStyle(.green)
                    }
                    Spacer()
                    Image(systemName: trustedEnvelope != nil ? "checkmark.shield.fill" : "shield")
                        .font(.title2).foregroundStyle(trustedEnvelope != nil ? Color.green : Color.secondary)
                }
                Button { Task { await fetchPublishedFirmware() } } label: {
                    Label("Find releases", systemImage: "arrow.triangle.2.circlepath.circle")
                        .font(.headline)
                }
                .disabled(preparingFirmware)
                if preparingFirmware {
                    Label("Checking releases…", systemImage: "arrow.down.circle")
                        .font(.footnote).foregroundStyle(.green)
                } else if signedReleaseStatus != "No release checked" && trustedEnvelope == nil {
                    Label("Release verification failed", systemImage: "xmark.shield")
                        .font(.footnote).foregroundStyle(.red)
                }
                if let publishedFirmware {
                    HStack(spacing: 12) {
                        Image(systemName: "shippingbox.fill")
                            .font(.title).foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("RedOne \(publishedFirmware.version)").font(.headline)
                            Text(publishedFirmware.hardware_profile).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: trustedEnvelope == nil ? "lock.fill" : "checkmark.seal.fill")
                            .foregroundStyle(trustedEnvelope == nil ? Color.secondary : Color.green)
                    }
                    if let notes = publishedFirmware.release_notes {
                        Text(notes).font(.caption).foregroundStyle(.green)
                    }
                    Button { Task { await downloadPublishedFirmware() } } label: {
                        Label("Download verified release", systemImage: "arrow.down.to.line.compact")
                    }
                    .disabled(preparingFirmware || trustedEnvelope == nil)
                }
                let readyReleases = downloadedReleases.filter {
                    FirmwareLibrary.verify($0) && FirmwareLibrary.transferPreflight($0) == nil
                }
                Label(readyReleases.isEmpty ? "No firmware downloaded" : "\(readyReleases.count) verified release(s) ready",
                      systemImage: readyReleases.isEmpty ? "tray" : "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                ForEach(readyReleases) { release in
                    Button { selectCachedRelease(release) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title2).foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("RedOne \(release.version)").font(.headline)
                                Text(release.hardwareProfile).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: selectedRelease?.filename == release.filename ? "checkmark.circle.fill" : "chevron.right")
                                .foregroundStyle(selectedRelease?.filename == release.filename ? Color.green : Color.secondary)
                        }
                    }
                }
                if let selectedRelease, FirmwareLibrary.transferPreflight(selectedRelease) != nil {
                    Label("Selected firmware needs verification", systemImage: "xmark.shield")
                        .foregroundStyle(.red)
                }
                if let firmwareError { Label(firmwareError, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red).font(.footnote) }
            } header: {
                Label("1. Download firmware", systemImage: "arrow.down.circle")
            }
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.router.fill")
                        .font(.largeTitle).foregroundStyle(verified == nil ? Color.secondary : Color.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("REDONE CONNECTION").font(.caption.weight(.bold))
                        Text(currentWiFi.replacingOccurrences(of: "Connected to Wi-Fi ", with: ""))
                            .font(.subheadline).foregroundStyle(currentWiFi.hasPrefix("Connected to Wi-Fi ") ? Color.green : Color.secondary)
                    }
                    Spacer()
                    Image(systemName: verified == nil ? "circle.dashed" : "checkmark.circle.fill")
                        .font(.title2).foregroundStyle(verified == nil ? Color.secondary : Color.green)
                }
                Button { Task { await refreshCurrentWiFi() } } label: {
                    Label("Refresh connection", systemImage: "arrow.clockwise.circle")
                }
                if !savedMacAddress.isEmpty {
                    Button {
                        macAddress = savedMacAddress
                        connectionPassword = RecoveryPairingStore.load().flatMap {
                            $0.ssid == ssid ? $0.password : nil
                        }
                        joinNetwork()
                    } label: {
                        Label("Rejoin RedOne_" + savedMacAddress, systemImage: "wifi")
                    }
                }
                Button { scanningConnectionQR = true } label: {
                    Label("Scan RedOne QR", systemImage: "qrcode.viewfinder")
                        .font(.headline)
                }
                if let qrError { Label(qrError, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red).font(.footnote) }
                if let verified {
                    HStack(spacing: 12) {
                        Image(systemName: "cpu.fill").font(.title2).foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(verified.device + " · " + verified.version).font(.headline)
                            Text("Running \(verified.running)  →  Next \(verified.next)")
                                .font(.caption).foregroundStyle(.green)
                        }
                        Spacer()
                        Image(systemName: "checkmark.shield.fill").foregroundStyle(.green)
                    }
                }
            } header: {
                Label("2. Connect to EFIS", systemImage: "wifi")
            } footer: {
                Text("Scan the QR on your RedOne or rejoin a saved connection.")
            }
            RedOneDeploymentSimulator()
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
        .sheet(isPresented: $scanningConnectionQR) {
            DeviceQRScannerView(onDeviceID: { value in
                scanningConnectionQR = false
                acceptConnectionQR(value)
            }, onCancel: { scanningConnectionQR = false }, acceptsRecovery: true)
                .ignoresSafeArea()
        }
        .task { await refreshCurrentWiFi() }
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
        firmwareAssessment = "Firmware verified and ready for use"
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
                signedReleaseStatus = "Publisher release cannot be verified"
                return
            }
            let envelope = try JSONDecoder().decode(SignedFirmwareEnvelope.self, from: data)
            guard SignedFirmwareVerifier.verify(envelope),
                  let release = publishedFirmware,
                  envelope.payload.version == release.version,
                  envelope.payload.hardware_profile == release.hardware_profile,
                  envelope.payload.sha256.caseInsensitiveCompare(release.sha256) == .orderedSame,
                  envelope.payload.image_url == release.image_url.absoluteString else {
                signedReleaseStatus = "Published release verification failed — update blocked"
                return
            }
            trustedEnvelope = envelope
            signedReleaseStatus = "Published release authenticated"
        } catch { signedReleaseStatus = "Release verification unavailable — update blocked" }
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
            firmwareAssessment = "Firmware verified and ready for use"
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

    @MainActor private func refreshCurrentWiFi() async {
        let network = await NEHotspotNetwork.fetchCurrent()
        currentWiFi = network.map { "Connected to Wi-Fi \($0.ssid)" } ?? "Not connected to WiFi"
    }

    private func acceptConnectionQR(_ value: String) {
        guard let components = URLComponents(string: value),
              components.scheme == "redone-recovery", components.host == "pair",
              let fields = components.queryItems else {
            qrError = "This is not a RedOne connection QR code."
            return
        }
        func field(_ name: String) -> String? {
            fields.first(where: { $0.name == name })?.value
        }
        guard let network = field("ssid"), network.hasPrefix("RedOne_"),
              network.count == 19,
              network.dropFirst(7).allSatisfy({ $0.isHexDigit }),
              let password = field("password"), (16...63).contains(password.count),
              let token = field("token"), (32...64).contains(token.count) else {
            qrError = "QR code is missing valid RedOne connection information."
            return
        }
        do {
            try RecoveryPairingStore.save(
                RecoveryPairing(ssid: network, password: password, token: token)
            )
            macAddress = String(network.dropFirst(7))
            connectionPassword = password
            qrError = nil
            joinNetwork()
        } catch {
            qrError = "Unable to securely save RedOne connection details."
        }
    }

    private func joinNetwork() {
                    verified = nil
                    message = "Requesting Wi-Fi connection…"
                    let config = NEHotspotConfiguration(ssid: ssid, passphrase: connectionPassword ?? "BenchOnly-2026!", isWEP: false)
                    config.joinOnce = false
                    NEHotspotConfigurationManager.shared.apply(config) { error in
                        Task { @MainActor in
                            if let error = error as NSError?,
                               error.code != NEHotspotConfigurationError.alreadyAssociated.rawValue {
                                message = "Wi-Fi join failed: \(error.localizedDescription)"
                            } else {
                                await refreshCurrentWiFi()
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
import SwiftUI
import CryptoKit

/// Completely local OTA workflow simulator. Never writes firmware or contacts a device.
struct RedOneDeploymentSimulator: View {
    private let versions = ["A": "0.1.0-sim-A", "B": "0.1.1-sim-B"]
    private let expectedHashes = [
        "A": "aa0621fe57d4b5d6831c963c0e5c52b693493e9d7e6585797826bc80c6a4c06d",
        "B": "f9acbce913f72c1c235a1fb11e7eb766737bb4a12765132153df2646aaee97df"
    ]
    @State private var activeSlot = "A"
    @State private var downloaded: String?
    @State private var staged: String?
    @State private var previousSlot: String?
    @State private var status = "Simulator ready — running A"
    @State private var showActivation = false

    @State private var verifiedStage = false

    private func step(_ title: String, icon: String, done: Bool, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: done ? "checkmark.circle.fill" : icon)
                    .font(.title2)
                    .foregroundStyle(done ? .green : (enabled ? .blue : .gray))
                    .frame(width: 30)
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
        .disabled(!enabled)
    }

    var body: some View {
        Section {
            HStack {
                Image(systemName: "cpu.fill").font(.title2).foregroundStyle(.blue)
                Text("REDONE SIMULATOR").font(.caption.weight(.bold))
                Spacer()
                Label("OFFLINE", systemImage: "wifi.slash")
                    .font(.caption2.weight(.bold)).foregroundStyle(.orange)
            }
            HStack(spacing: 10) {
                partition("A")
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3).foregroundStyle(.secondary)
                partition("B")
            }
            .padding(.vertical, 8)
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    Capsule().fill(progress > index ? Color.green : Color.gray.opacity(0.2))
                        .frame(height: 6)
                }
            }
            HStack {
                Text("DOWNLOAD"); Spacer(); Text("STAGE"); Spacer(); Text("VERIFY"); Spacer(); Text("ACTIVATE")
            }
            .font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
            step("Download B", icon: "arrow.down.circle", done: downloaded == "B", enabled: true, action: downloadB)
            step("Stage B", icon: "arrow.up.circle", done: staged == "B" || activeSlot == "B", enabled: downloaded == "B" && staged == nil && activeSlot != "B", action: stageB)
            step("Verify", icon: "checkmark.shield", done: verifiedStage || activeSlot == "B", enabled: staged != nil, action: verifyStaged)
            step("Activate B", icon: "power.circle", done: activeSlot == "B", enabled: verifiedStage && staged == "B", action: { showActivation = true })
            step("Rollback to A", icon: "arrow.uturn.backward.circle", done: false, enabled: previousSlot != nil, action: rollback)
            Label(status, systemImage: "info.circle")
                .font(.caption).foregroundStyle(.green)
        } header: {
            Text("Deployment simulator")
        } footer: {
            Label("Simulation only · no ESP32 flash", systemImage: "shield.lefthalf.filled")
        }
        .confirmationDialog("Activate simulated firmware?", isPresented: $showActivation) {
            Button("Activate B") { activate() }
        } message: {
            Text("Simulation only. No firmware is sent to an ESP32.")
        }
    }

    private var progress: Int {
        if activeSlot == "B" { return 4 }
        if verifiedStage { return 3 }
        if staged != nil { return 2 }
        if downloaded != nil { return 1 }
        return 0
    }

    private func partition(_ slot: String) -> some View {
        let running = activeSlot == slot
        return VStack(spacing: 5) {
            Image(systemName: running ? "cpu.fill" : "cpu")
                .font(.title2).foregroundStyle(running ? .green : .secondary)
            Text("PARTITION \(slot)").font(.caption2.weight(.bold))
            Text(versions[slot] ?? "").font(.system(size: 10, design: .monospaced))
            Text(running ? "RUNNING" : (staged == slot ? "STAGED" : "STANDBY"))
                .font(.caption2.weight(.bold))
                .foregroundStyle(running ? .green : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(running ? Color.green.opacity(0.12) : Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func payload(_ label: String) -> Data {
        let version = versions[label]!
        let header = Data("MICROSKY-HORIZON-SIMULATOR-OTA\nNON-FLASHABLE TEST PAYLOAD\nVERSION=\(version)\n".utf8)
        let seed = Array(SHA256.hash(data: header))
        var bytes = Array(header)
        while bytes.count < 4096 { bytes.append(contentsOf: seed.prefix(4096 - bytes.count)) }
        return Data(bytes)
    }

    private func valid(_ label: String) -> Bool {
        let data = payload(label)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return data.count == 4096 && data.first != 0xe9 && digest == expectedHashes[label]
    }

    private func downloadB() {
        guard valid("B") else { status = "Simulator image verification failed"; return }
        downloaded = "B"
        status = "Simulator B downloaded and SHA-256 verified"
    }

    private func stageB() {
        guard downloaded == "B", valid("B") else { status = "Download and verify B first"; return }
        staged = "B"
        verifiedStage = false
        status = "Simulator B staged; A remains active"
    }

    private func verifyStaged() {
        guard let staged, valid(staged) else { status = "Staged image verification failed"; return }
        verifiedStage = true
        status = "Staged simulator image verified"
    }

    private func activate() {
        guard staged == "B", verifiedStage, valid("B") else { return }
        previousSlot = activeSlot
        activeSlot = "B"
        staged = nil
        verifiedStage = false
        status = "Simulator B activated; rollback available"
    }

    private func rollback() {
        guard let previousSlot else { return }
        activeSlot = previousSlot
        self.previousSlot = nil
        status = "Rolled back to simulator A"
    }
}
