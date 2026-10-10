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
    @State private var firmwareSource = "publisher"
    @State private var firmwareAssessment = "No release verified"
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
            Section("RedOne EFIS") {
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
            Section("Offline firmware library") {
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
                            Text(FirmwareLibrary.verify(release) ? "Checksum verified; signature pending" : "Missing or damaged file")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Firmware management") {
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
                Picker("Firmware source", selection: $firmwareSource) {
                    Text("Publishing service").tag("publisher")
                    Text("Downloaded copy").tag("local")
                }
                .pickerStyle(.segmented)
                if firmwareSource == "publisher" {
                    Button("Check published firmware") { Task { await fetchPublishedFirmware() } }
                        .disabled(preparingFirmware)
                    if let publishedFirmware {
                        LabeledContent("Published version", value: publishedFirmware.version)
                        LabeledContent("Hardware", value: publishedFirmware.hardware_profile)
                        if let notes = publishedFirmware.release_notes { Text(notes).font(.footnote) }
                        Button("Download published copy") { Task { await downloadPublishedFirmware() } }
                            .disabled(preparingFirmware)
                    }
                } else {
                    Button("Choose downloaded firmware") { showingFirmwarePicker = true }
                        .disabled(preparingFirmware)
                }
                Text(firmwareAssessment).font(.footnote).foregroundStyle(.secondary)
                if preparingFirmware { ProgressView("Inspecting firmware file…") }
                if let firmwareName {
                    LabeledContent("Selected file", value: firmwareName)
                    if let firmwareSize { LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: firmwareSize, countStyle: .file)) }
                    if let firmwareDigest { Text("SHA-256: \(firmwareDigest)").font(.caption2).textSelection(.enabled) }
                }
                if let firmwareError { Text(firmwareError).foregroundStyle(.red).font(.footnote) }
                Button("Transfer and stage firmware") { }
                    .disabled(true)
                Button("Roll back to previous firmware") { }
                    .disabled(true)
                Text("Firmware changes are locked until signed-image validation, device authentication and A/B recovery testing pass. No firmware will be changed by this screen.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .fileImporter(isPresented: $showingFirmwarePicker, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
            Task { await inspectFirmware(result) }
        }
        .navigationTitle("EFIS Wi-Fi")
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
            firmwareError = "Cached firmware is missing or corrupt."
            return
        }
        firmwareError = nil
        firmwareName = release.filename
        firmwareDigest = release.sha256
        firmwareSize = (try? FirmwareLibrary.folder.appendingPathComponent(release.filename)
            .resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
        firmwareAssessment = "Offline checksum verified; signature verification still required"
    }

    @MainActor
    private func fetchPublishedFirmware() async {
        preparingFirmware = true
        defer { preparingFirmware = false }
        publishedFirmware = nil
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
        } catch { firmwareAssessment = "Publisher unavailable"; firmwareError = error.localizedDescription }
    }

    @MainActor
    private func downloadPublishedFirmware() async {
        guard let release = publishedFirmware else { return }
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
            let cached = try FirmwareLibrary.store(data, version: release.version,
                hardware: release.hardware_profile, digest: digest, source: release.image_url)
            let destination = FirmwareLibrary.folder.appendingPathComponent(cached.filename)
            reloadLibrary()
            firmwareName = destination.lastPathComponent
            firmwareSize = Int64(data.count)
            firmwareDigest = digest
            firmwareAssessment = "Checksum matches published manifest; signature verification still required"
        } catch {
            firmwareName = nil; firmwareSize = nil; firmwareDigest = nil
            firmwareAssessment = "Download verification failed"
            firmwareError = error.localizedDescription
        }
    }

    @MainActor
    private func inspectFirmware(_ result: Result<[URL], Error>) async {
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
                firmwareAssessment = "Matches publisher checksum; signature verification still required"
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
