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
    let inactiveImagePresent: Bool?
    let previousVersion: String?
    let updateReady: Bool?
    let apiVersion: Int?
    let bootState: String?
}

private struct RedOneBootHealth: Decodable {
    let pendingVerify: Bool
    let imageIdentityOk: Bool
    let inactiveSlotPresent: Bool
    let firmwareSelfTestOk: Bool
    let requiredSensorsOk: Bool
    let displayOk: Bool
    let powerOk: Bool
    let rollbackPathOk: Bool
    let operatorGroundConfirmation: Bool
    let mayConfirmBoot: Bool
    let updateReady: Bool
    let blocker: String
    let evidenceSource: String
}

struct EFISWiFiView: View {
    @State private var message = "Not connected"
    @State private var verified: RedOneStatus?
    @State private var checking = false
    @State private var bootHealth: RedOneBootHealth?
    @State private var bootHealthMessage = "Not checked"
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

    private func guidance(_ text: String, severity: Color = .orange) -> some View {
        Label(text, systemImage: severity == .red ? "xmark.octagon.fill" : severity == .green ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(severity)
            .fixedSize(horizontal: false, vertical: true)
    }

    // Device status is a positively authenticated readout, not disabled metadata.
    // A green value denotes a successful status read, NOT OTA deployment approval.
    private func efisStatusRow(_ title: String, _ value: String) -> some View {
        LabeledContent(title) {
            Text(value)
                .foregroundStyle(.green)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    private func bootCheck(_ label: String, _ passed: Bool) -> some View {
        Label(label, systemImage: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.subheadline)
            .foregroundStyle(passed ? .green : .orange)
            .accessibilityLabel("\(label): \(passed ? "reported satisfied" : "not satisfied")")
    }

    private var connectionMessageColor: Color {
        if verified != nil { return .green }
        let lower = message.lowercased()
        if lower.contains("failed") || lower.contains("unable") || lower.contains("required") || lower.contains("unexpected") { return .red }
        return .orange
    }

    var body: some View {
        List {
            Section {
                guidance("Connect to the internet using normal Wi-Fi or mobile data, not the RedOne EFIS network. Download and authenticate the signed release before connecting to the EFIS.")
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
                    .foregroundStyle(readyReleases.isEmpty ? Color.orange : Color.green)
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
                if let selectedRelease {
                    if let issue = FirmwareLibrary.transferPreflight(selectedRelease) {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("Not ready for real EFIS transfer", systemImage: "exclamationmark.shield.fill")
                                .font(.subheadline.weight(.semibold))
                            Text(issue).font(.caption)
                            Text("The deployment simulator below uses separate, non-flashable test images.")
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
                    } else {
                        Label("Signed firmware validated for RedOne", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                    }
                }
                if let firmwareError { Label(firmwareError, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red).font(.footnote) }
            } header: {
                Label("1. Download firmware", systemImage: "arrow.down.circle")
            }
            Section {
                guidance("Scan the RedOne QR code or rejoin your saved network, then read EFIS status.")
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
                Button { Task { await verifyConnection() } } label: {
                    Label(checking ? "Reading EFIS status…" : "Read EFIS status", systemImage: "info.circle")
                }
                .disabled(checking)
                guidance(message, severity: connectionMessageColor)
                if verified == nil {
                    Text("The iPhone must join RedOne Wi-Fi to read physical device status. Internet access is not needed for local diagnostics.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let qrError { Label(qrError, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red).font(.footnote) }
                if let verified {
                    VStack(alignment: .leading, spacing: 7) {
                        Label("EFIS status", systemImage: "checkmark.circle.fill")
                            .font(.headline).foregroundStyle(.green)
                        Spacer(minLength: 12)
                        efisStatusRow("Device", verified.device)
                        efisStatusRow("Wi-Fi network", ssid)
                        efisStatusRow("Connection", "Connected · authenticated")
                        efisStatusRow("Firmware", verified.version)
                        efisStatusRow("Active partition", verified.running)
                        efisStatusRow("Next OTA partition", verified.next)
                        efisStatusRow("Boot state", verified.bootState ?? "Not reported")
                        efisStatusRow("Management API", verified.apiVersion.map(String.init) ?? "Not reported")
                        efisStatusRow("Rollback", verified.rollbackAvailable == true ? "Reported available (unverified)" : "Unavailable / unverified")
                        if let reason = verified.rollbackReason {
                            Text(reason).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
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
            }
            Section("Physical RedOne readiness") {
                guidance("PHYSICAL DEVICE — Read-only Wi-Fi checks are permitted. Writing Partition B, changing boot selection and rollback commands remain NO-GO until the physical security and recovery gates pass.", severity: .red)
                if let verified {
                    LabeledContent("Read-only connection", value: "Authenticated")
                    LabeledContent("Running firmware", value: verified.version)
                    LabeledContent("Current partition", value: verified.running)
                    LabeledContent("Device rollback report", value: verified.rollbackAvailable == true ? "Reported available — not independently tested" : "Unavailable or unverified")
                    Button { Task { await readBootHealth() } } label: {
                        Label("Read boot-health diagnostics", systemImage: "heart.text.square")
                    }
                    .disabled(checking)
                    if let bootHealth {
                        guidance("Device-reported checks only. No boot confirmation or update authorisation.", severity: .red)
                        bootCheck("Pending verification", bootHealth.pendingVerify)
                        bootCheck("Running image identity", bootHealth.imageIdentityOk)
                        bootCheck("Inactive OTA slot", bootHealth.inactiveSlotPresent)
                        bootCheck("Firmware self-test", bootHealth.firmwareSelfTestOk)
                        bootCheck("Required sensors", bootHealth.requiredSensorsOk)
                        bootCheck("Display", bootHealth.displayOk)
                        bootCheck("Power", bootHealth.powerOk)
                        bootCheck("Rollback path", bootHealth.rollbackPathOk)
                        bootCheck("Operator ground confirmation", bootHealth.operatorGroundConfirmation)
                        guidance("Blocking reason: " + bootHealth.blocker, severity: .red)
                        LabeledContent("Boot confirmation", value: bootHealth.mayConfirmBoot ? "Reported eligible (not independently verified)" : "Locked")
                        LabeledContent("Firmware update", value: bootHealth.updateReady ? "Device reports ready — app remains locked" : "Locked")
                        Text("Source: " + bootHealth.evidenceSource).font(.caption).foregroundStyle(.secondary)
                    } else {
                        guidance(bootHealthMessage)
                    }
                } else {
                    guidance("Connect to the physical RedOne and select Read EFIS status above. Do not interpret simulator results as physical-device evidence.")
                }
            }
            Section("Simulation only — no physical flash") {
                guidance("The following controls operate a local or Synology simulator, not the connected ESP32. They cannot certify physical upgrade, activation or rollback.")
                RedOneDeploymentSimulator()
            }
            Section("Physical firmware update — locked") {
                guidance("Physical transfer, verification, activation and rollback are locked until independent signed-image, anti-downgrade, boot-health and recovery tests pass. Do not use simulator success as authorisation.", severity: .red)
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
                    guidance("Connect to RedOne and read EFIS status before managing firmware.")
                }
                Label("3. Push firmware to EFIS", systemImage: "arrow.up.circle")
                    .font(.headline)
                Button("Push selected firmware") { }
                    .disabled(true)
                Label("4. Verify transferred firmware", systemImage: "checkmark.shield")
                    .font(.headline)
                Button("Verify transferred image") { }
                    .disabled(true)
                Label("5. Activate firmware", systemImage: "power")
                    .font(.headline)
                Button("Activate verified firmware") { }
                    .disabled(true)
                Label("6. Rollback", systemImage: "arrow.uturn.backward")
                    .font(.headline)
                Button("Roll back to previous firmware") { }
                    .disabled(true)
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
        firmwareAssessment = FirmwareLibrary.transferPreflight(release) == nil
            ? "Firmware validated for RedOne transfer"
            : "Firmware checksum verified; deployment validation required"
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
            firmwareAssessment = FirmwareLibrary.transferPreflight(cached) == nil
                ? "Firmware validated for RedOne transfer"
                : "Firmware downloaded; deployment validation required"
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
        bootHealth = nil
        bootHealthMessage = "Not checked"
        guard let pairing = RecoveryPairingStore.load(),
              pairing.ssid == ssid,
              !pairing.password.isEmpty,
              pairing.token.count >= 32 else {
            message = "RedOne pairing required. Scan the device connection QR to securely save Wi-Fi credentials and the authentication token."
            return
        }
        message = "Requesting RedOne Wi-Fi connection…"
        let config = NEHotspotConfiguration(ssid: ssid, passphrase: pairing.password, isWEP: false)
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
    private func readBootHealth() async {
        bootHealth = nil
        bootHealthMessage = "Reading device boot-health diagnostics…"
        guard verified != nil, let url = URL(string: "http://192.168.4.1/boot-health") else {
            bootHealthMessage = "Read EFIS status first."
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let pairing = RecoveryPairingStore.load(), pairing.ssid == ssid {
            request.setValue(pairing.token, forHTTPHeaderField: "X-Lab-Token")
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if http.statusCode == 401 {
                bootHealthMessage = "Authentication required. Scan the device pairing QR again."
                return
            }
            if http.statusCode == 404 {
                bootHealthMessage = "Boot-health diagnostics are not supported by the installed RedOne firmware. Basic device status remains available. No firmware update is required to continue using existing functions."
                return
            }
            guard http.statusCode == 200 else {
                bootHealthMessage = "Boot-health diagnostics unavailable (HTTP \(http.statusCode)). Basic device status remains available."
                return
            }
            let health = try JSONDecoder().decode(RedOneBootHealth.self, from: data)
            guard health.evidenceSource == "device-live-read-only" else {
                bootHealthMessage = "Unrecognised boot-health evidence source."
                return
            }
            bootHealth = health
        } catch {
            bootHealthMessage = "Unable to read boot-health diagnostics. The installed firmware may not support this endpoint."
        }
    }

    @MainActor
    private func verifyConnection() async {
        checking = true
        verified = nil
        bootHealth = nil
        bootHealthMessage = "Not checked"
        message = "Checking RedOne device…"
        defer { checking = false }
        guard let url = URL(string: "http://192.168.4.1/status") else { return }
        for attempt in 0..<6 {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 3
                request.cachePolicy = .reloadIgnoringLocalCacheData
                // Normal OTA firmware requires an authenticated status request.
                // Reuse the device pairing already stored in the iOS Keychain;
                // never include tokens in UI text or logs.
                if let pairing = RecoveryPairingStore.load(),
                   pairing.ssid == ssid {
                    request.setValue(pairing.token, forHTTPHeaderField: "X-Lab-Token")
                }
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                if http.statusCode == 401 {
                    message = "RedOne is connected but authentication is required. Scan the device pairing QR again."
                    return
                }
                guard http.statusCode == 200 else {
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
                    message = "Unable to verify RedOne. Check Wi-Fi and tap Read EFIS status again."
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
    @State private var transferFraction = 0.0
    @State private var interrupted = false
    @State private var corruptNextTransfer = false
    @State private var transferring = false
    @State private var errorStatus = false
    @AppStorage("redone.simulatorEndpoint") private var simulatorEndpoint = "https://lollipop.granvillehouse.synology.me:8449"
    @State private var simulatorToken = ""
    @State private var remoteMode = false
    @State private var remoteConnected = false
    @State private var remoteBusy = false
    @State private var remoteDetails = "Not connected"

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
                Label(remoteMode && remoteConnected ? "SYNOLOGY" : "LOCAL", systemImage: remoteMode && remoteConnected ? "network" : "iphone")
                    .font(.caption2.weight(.bold)).foregroundStyle(remoteMode && remoteConnected ? .green : .orange)
            }
            DisclosureGroup("Network simulator") {
                TextField("HTTPS endpoint", text: $simulatorEndpoint)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                SecureField("Simulator access token", text: $simulatorToken)
                Button { Task { await connectRemote() } } label: {
                    Label("Connect to Synology simulator", systemImage: "network")
                }
                .disabled(remoteBusy)
                if remoteConnected {
                    Toggle("Use network simulator", isOn: $remoteMode)
                    Label(remoteDetails, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green).font(.caption)
                } else {
                    Label(remoteDetails, systemImage: "info.circle")
                        .foregroundStyle(.green).font(.caption)
                }
            }
            HStack(spacing: 10) {
                partition("A")
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3).foregroundStyle(.secondary)
                partition("B")
            }
            .padding(.vertical, 8)
            HStack(spacing: 12) {
                Image(systemName: "iphone.gen3").font(.title2)
                Spacer()
                Image(systemName: transferring ? "arrow.right.circle.fill" : "arrow.right.circle")
                    .font(.title2).foregroundStyle(transferring ? .blue : .secondary)
                    .symbolEffect(.pulse, options: .repeating, isActive: transferring)
                Spacer()
                Image(systemName: "cpu.fill").font(.title2)
            }
            .foregroundStyle(.blue)
            ProgressView(value: transferFraction) {
                Text("Phone → EFIS simulator").font(.caption)
            } currentValueLabel: {
                Text("\(Int(transferFraction * 100))%")
                    .font(.caption.monospacedDigit()).foregroundStyle(.green)
            }
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
            step("Download B", icon: "arrow.down.circle", done: downloaded == "B", enabled: true, action: { if remoteMode { Task { await remoteDownload() } } else { downloadB() } })
            step((transferFraction > 0 && transferFraction < 1 && !interrupted) ? "Resume transfer" : "Transfer B", icon: "arrow.up.circle", done: staged == "B" || activeSlot == "B", enabled: downloaded == "B" && staged == nil && activeSlot != "B" && !transferring, action: { Task { if remoteMode { await remoteTransfer() } else { await stageB() } } })
            step("Verify", icon: "checkmark.shield", done: verifiedStage || activeSlot == "B", enabled: staged != nil || (remoteMode && transferFraction >= 1), action: { if remoteMode { Task { await remoteVerify() } } else { verifyStaged() } })
            step("Activate B", icon: "power.circle", done: activeSlot == "B", enabled: verifiedStage && staged == "B", action: { showActivation = true })
            step("Rollback to A", icon: "arrow.uturn.backward.circle", done: false, enabled: previousSlot != nil, action: { if remoteMode { Task { await remoteAction("rollback") } } else { rollback() } })
            DisclosureGroup("Test failures") {
                Button("Interrupt transfer at 50%") {
                    interrupted = true
                    transferFraction = 0
                    staged = nil
                    verifiedStage = false
                    status = "Interruption armed — start transfer"
                    errorStatus = false
                }
                Button("Corrupt next transfer") {
                    corruptNextTransfer = true
                    staged = nil
                    verifiedStage = false
                    status = "Corruption armed — start transfer"
                    errorStatus = false
                }
                Button("Reset simulator") {
                    activeSlot = "A"; downloaded = nil; staged = nil
                    previousSlot = nil; verifiedStage = false
                    transferFraction = 0; interrupted = false
                    corruptNextTransfer = false; transferring = false
                    errorStatus = false; status = "Simulator reset — running A"
                }
            }
            Label(status, systemImage: errorStatus ? "exclamationmark.triangle.fill" : "info.circle")
                .font(.caption).foregroundStyle(errorStatus ? Color.red : Color.green)
        } header: {
            Text("Deployment simulator")
        } footer: {
            Label("Simulation only · no ESP32 flash", systemImage: "shield.lefthalf.filled")
        }
        .confirmationDialog("Activate simulated firmware?", isPresented: $showActivation) {
            Button("Activate B") { if remoteMode { Task { await remoteAction("activate") } } else { activate() } }
        } message: {
            Text("Simulation only. No firmware is sent to an ESP32.")
        }
    }

    private struct RemoteState: Decodable {
        let simulator: Bool
        let hardware: Bool
        let active_partition: String
        let staged_partition: String?
        let received_bytes: Int
        let verified: Bool
        let rollback_available: Bool
    }

    private func remoteRequest(_ path: String, method: String = "GET", bytes: Data? = nil, offset: Int? = nil) async throws -> (Data, RemoteState?) {
        guard let root = URL(string: simulatorEndpoint), root.scheme == "https", root.host != nil,
              root.user == nil, root.password == nil, !simulatorToken.isEmpty,
              let url = URL(string: path, relativeTo: root)?.absoluteURL,
              url.host == root.host, url.scheme == "https" else { throw URLError(.unsupportedURL) }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15
        request.setValue("Bearer " + simulatorToken, forHTTPHeaderField: "Authorization")
        if let offset { request.setValue(String(offset), forHTTPHeaderField: "X-Offset") }
        if method == "POST" { request.httpBody = bytes ?? Data() }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let state = try? JSONDecoder().decode(RemoteState.self, from: data)
        if let state, (!state.simulator || state.hardware) { throw URLError(.cannotParseResponse) }
        return (data, state)
    }

    @MainActor private func syncRemote(_ state: RemoteState) {
        activeSlot = state.active_partition
        staged = state.staged_partition
        verifiedStage = state.verified
        previousSlot = state.rollback_available ? "A" : nil
        transferFraction = Double(state.received_bytes) / 4096.0
        remoteDetails = "Synology · Partition " + state.active_partition
    }

    @MainActor private func connectRemote() async {
        remoteBusy = true; defer { remoteBusy = false }
        do {
            let (_, state) = try await remoteRequest("/api/status")
            guard let state else { throw URLError(.cannotParseResponse) }
            syncRemote(state); remoteConnected = true; remoteMode = true; errorStatus = false
            status = "Authenticated network simulator connected"
        } catch {
            remoteConnected = false; remoteMode = false
            remoteDetails = "Connection failed: " + error.localizedDescription
        }
    }

    @MainActor private func remoteDownload() async {
        do {
            let (bytes, _) = try await remoteRequest("/api/fixtures/B/download")
            let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
            guard bytes.count == 4096, bytes.first != 0xe9, digest == expectedHashes["B"] else {
                throw URLError(.cannotDecodeContentData)
            }
            downloaded = "B"; status = "Network test image downloaded and verified"; errorStatus = false
        } catch { status = error.localizedDescription; errorStatus = true }
    }

    @MainActor private func remoteTransfer() async {
        guard downloaded == "B" else { return }
        transferring = true; defer { transferring = false }
        do {
            let (bytes, _) = try await remoteRequest("/api/fixtures/B/download")
            guard bytes.count == 4096 else { throw URLError(.cannotDecodeContentData) }
            if transferFraction == 0 || transferFraction >= 1 {
                let (_, resetState) = try await remoteRequest("/api/transfer/reset", method: "POST")
                if let resetState { syncRemote(resetState) }
            }
            var offset = Int(transferFraction * 4096)
            while offset < bytes.count {
                let end = min(offset + 512, bytes.count)
                let (_, state) = try await remoteRequest("/api/transfer/chunk", method: "POST", bytes: bytes.subdata(in: offset..<end), offset: offset)
                guard let state else { throw URLError(.cannotParseResponse) }
                syncRemote(state)
                offset = end
                if interrupted && offset >= 2048 {
                    interrupted = false
                    status = "Network transfer interrupted — resume available"
                    errorStatus = true
                    return
                }
            }
            status = "Network transfer complete — verify next"; errorStatus = false
        } catch { status = error.localizedDescription; errorStatus = true }
    }

    @MainActor private func remoteVerify() async { await remoteAction("verify") }

    @MainActor private func remoteAction(_ name: String) async {
        do {
            let (_, state) = try await remoteRequest("/api/" + name, method: "POST")
            guard let state else { throw URLError(.cannotParseResponse) }
            syncRemote(state)
            if name == "rollback" { downloaded = nil; transferFraction = 0 }
            status = "Network simulator: " + name + " complete"
            errorStatus = false
        } catch { status = "Network " + name + " failed: " + error.localizedDescription; errorStatus = true }
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
        errorStatus = false
        status = "Simulator B downloaded and SHA-256 verified"
    }

    @MainActor
    private func stageB() async {
        guard downloaded == "B", valid("B"), !transferring else {
            errorStatus = true; status = "Download and verify B first"; return
        }
        transferring = true
        errorStatus = false
        let resume = transferFraction > 0 && transferFraction < 1 && !interrupted
        if !resume { transferFraction = 0 }
        status = resume ? "Resuming simulated transfer" : "Transferring simulated firmware"
        while transferFraction < 1 {
            try? await Task.sleep(for: .milliseconds(75))
            transferFraction = min(1, transferFraction + 0.05)
            if interrupted && transferFraction >= 0.5 {
                interrupted = false
                transferring = false
                errorStatus = true
                status = "Transfer interrupted — tap Resume transfer"
                return
            }
        }
        transferring = false
        if corruptNextTransfer {
            corruptNextTransfer = false
            transferFraction = 0
            errorStatus = true
            status = "SHA-256 mismatch — image rejected; A remains active"
            return
        }
        staged = "B"
        verifiedStage = false
        status = "Transfer complete — A remains active"
    }

    private func verifyStaged() {
        guard let staged, valid(staged) else { status = "Staged image verification failed"; return }
        verifiedStage = true
        errorStatus = false
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
