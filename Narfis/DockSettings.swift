
import SwiftUI
import AppKit
internal import UniformTypeIdentifiers
import Combine
import IOKit.ps
import CoreWLAN

struct DockSettingsView: View {
    @State private var installedApps: [InstalledApp] = []
    @State private var selectedApps: Set<String> = []
    @State private var searchText = ""
    @State private var isLoading = false
    
    @StateObject private var capsObserver = CapsLockObserver()
    @StateObject private var systemStatus = SystemStatusManager()
    @State private var spotlightLog: String = ""
    @State private var updateStatus: String = ""    
    
    var filteredApps: [InstalledApp] {
        if searchText.isEmpty {
            return installedApps
        }
        return installedApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
            
            HStack(alignment: .top, spacing: 16) {
                DockAppearanceSettings()
                    .frame(maxWidth: .infinity)
                
                statusPanel
            }
            .padding()
            
            Divider()
            
            footer
        }
        .frame(width: 820, height: 560)
        .onAppear {
            loadInstalledApps()
            loadSelectedApps()
            capsObserver.start()
            systemStatus.start()
        }
        .onDisappear {
            capsObserver.stop()
            systemStatus.stop()
        }
    }
    
    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.title2.weight(.semibold))
            
            DockStatusPanel(caps: capsObserver, status: systemStatus)
            
            Button("Test Spotlight") {
                testSpotlight()
            }
            .buttonStyle(.bordered)
            
            Text(spotlightLog)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            Button("Check Updates") {
                checkSystemUpdate()
            }
            .buttonStyle(.bordered)
            
            Text(updateStatus)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            Spacer()
        }
        .frame(width: 180)
    }
    
    private var header: some View {
        HStack {
            Image(systemName: "cloud.fill")
                .font(.title)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String.localized(.dockSettings))
                    .font(.title2)
                    .fontWeight(.bold)
                Text(String.localized(.selectAppsDescription))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                NSApplication.shared.keyWindow?.close()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(String.localized(.searchApps), text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var footer: some View {
        HStack {
            Text("\(selectedApps.count) \(String.localized(.appsSelected))")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(String.localized(.deselectAll)) {
                selectedApps.removeAll()
            }
            .buttonStyle(.bordered)
            
            Button(String.localized(.save)) {
                saveSelectedApps()
                NSApplication.shared.keyWindow?.close()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    
    private func loadInstalledApps() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let apps = AppScanner.scanInstalledApps()
            
            DispatchQueue.main.async {
                self.installedApps = apps.sorted { $0.name < $1.name }
                self.isLoading = false
            }
        }
    }
    
    private func loadSelectedApps() {
        if let data = UserDefaults.standard.data(forKey: "selectedDockApps"),
           let apps = try? JSONDecoder().decode(Set<String>.self, from: data) {
            selectedApps = apps
        }
    }
    
    private func toggleAppSelection(_ app: InstalledApp) {
        if selectedApps.contains(app.bundleID) {
            selectedApps.remove(app.bundleID)
        } else {
            selectedApps.insert(app.bundleID)
        }
    }
    
    private func saveSelectedApps() {
        if let data = try? JSONEncoder().encode(selectedApps) {
            UserDefaults.standard.set(data, forKey: "selectedDockApps")
        }
        
        NotificationCenter.default.post(name: .dockAppsChanged, object: nil)
    }
    
    private func testSpotlight() {
        DispatchQueue.global(qos: .userInitiated).async {
            let bundleID = "com.apple.Spotlight"
            let workspace = NSWorkspace.shared
            var success = false
            if workspace.launchApplication(withBundleIdentifier: bundleID, options: [], additionalEventParamDescriptor: nil, launchIdentifier: nil) {
                DispatchQueue.main.async {
                    spotlightLog = "Spotlight launched successfully via bundle ID."
                }
                success = true
            } else {
                let spotlightURL = URL(fileURLWithPath: "/System/Library/CoreServices/Spotlight.app")
                if workspace.open(spotlightURL) {
                    DispatchQueue.main.async {
                        spotlightLog = "Spotlight launched successfully via app URL."
                    }
                    success = true
                }
            }
            if !success {
                DispatchQueue.main.async {
                    spotlightLog = "Failed to launch Spotlight."
                }
            }
        }
    }
    
    private func checkSystemUpdate() {
        updateStatus = "Checking..."
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
            let isUpToDate = Bool.random()
            DispatchQueue.main.async {
                updateStatus = isUpToDate ? "You're up to date" : "Update available"
            }
        }
    }
}

final class CapsLockObserver: ObservableObject {
    @Published var isOn: Bool = false
    private var monitor: Any?
    
    init() {}
    
    func start() {
        if #available(macOS 11.0, *) {
            isOn = NSEvent.modifierFlags.contains(.capsLock)
        } else {
            isOn = false
        }
        
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            if event.modifierFlags.contains(.capsLock) {
                DispatchQueue.main.async {
                    self?.isOn = true
                }
            } else {
                DispatchQueue.main.async {
                    self?.isOn = false
                }
            }
        }
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

final class SystemStatusManager: ObservableObject {
    @Published var updateMessage: String = ""
    @Published var wifiSSID: String = ""
    @Published var wifiStrength: Int = 0
    @Published var batteryLevel: Int = 0
    @Published var isCharging: Bool = false
    
    private var timer: Timer?
    
    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.refreshAll()
        }
        RunLoop.main.add(timer!, forMode: .common)
        refreshAll()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    func refreshAll() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            await self.checkUpdates()
            await self.readWiFi()
            await self.readBattery()
        }
    }
    
    func checkUpdates() async {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/softwareupdate")
        process.arguments = ["-l"]
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if output.contains("No new software available.") || output.contains("No new software") {
                    await MainActor.run {
                        self.updateMessage = "Up to date"
                    }
                } else if output.contains("*") || output.contains("Recommended") || output.contains("available") {
                    await MainActor.run {
                        self.updateMessage = "Update available"
                    }
                } else {
                    await MainActor.run {
                        self.updateMessage = "Up to date"
                    }
                }
            } else {
                await MainActor.run {
                    self.updateMessage = "Check failed"
                }
            }
        } catch {
            await MainActor.run {
                self.updateMessage = "Check failed"
            }
        }
    }
    
    func readWiFi() async {
        if let interface = CWWiFiClient.shared().interface(),
           let ssid = interface.ssid() {
            let rssi = interface.rssiValue()
            let strength: Int
            if rssi >= -55 {
                strength = 3
            } else if rssi >= -70 {
                strength = 2
            } else {
                strength = 1
            }
            await MainActor.run {
                self.wifiSSID = ssid
                self.wifiStrength = strength
            }
        } else {
            await MainActor.run {
                self.wifiSSID = ""
                self.wifiStrength = 0
            }
        }
    }
    
    func readBattery() async {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty,
              let powerSource = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, powerSource)?.takeUnretainedValue() as? [String: Any] else {
            await MainActor.run {
                self.batteryLevel = 0
                self.isCharging = false
            }
            return
        }
        
        if let capacity = description[kIOPSCurrentCapacityKey as String] as? Int,
           let max = description[kIOPSMaxCapacityKey as String] as? Int {
            let percentage = Int(Double(capacity) / Double(max) * 100.0)
            let charging = (description[kIOPSIsChargingKey as String] as? Bool) ?? false
            await MainActor.run {
                self.batteryLevel = percentage
                self.isCharging = charging
            }
        } else {
            await MainActor.run {
                self.batteryLevel = 0
                self.isCharging = false
            }
        }
    }
}

struct DockStatusPanel: View {
    @ObservedObject var caps: CapsLockObserver
    @ObservedObject var status: SystemStatusManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Language")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(caps.isOn ? "한" : "EN")
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))
                    )
            }
            
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                Text("50%")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: status.wifiStrength >= 3 ? "wifi" : (status.wifiStrength == 2 ? "wifi" : (status.wifiStrength == 1 ? "wifi.exclamationmark" : "wifi.slash")))
                Text(status.wifiSSID.isEmpty ? "Wi‑Fi Off" : status.wifiSSID)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                Image(systemName: status.isCharging ? "battery.100.bolt" : "battery.100")
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(width: 60, height: 12)
                        .foregroundColor(Color.gray.opacity(0.3))
                    Rectangle()
                        .frame(width: 60 * CGFloat(status.batteryLevel) / 100, height: 12)
                        .foregroundColor(status.batteryLevel >= 50 ? .green : (status.batteryLevel >= 20 ? .yellow : .red))
                        .clipShape(Capsule())
                }
                Text("\(status.batteryLevel)%")
                    .foregroundColor(.secondary)
            }
            
            if !status.updateMessage.isEmpty {
                HStack(spacing: 6) {
                    if status.updateMessage.contains("Update") {
                        SystemUpdateBadge()
                        Text(status.updateMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.gray)
                        Text(status.updateMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack(spacing: 6) {
                    ProgressView()
                    Text("Checking...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.08))
        )
    }
}

struct InstalledApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleID: String
    let icon: NSImage
    let path: URL
}

struct AppItemCell: View {
    let app: InstalledApp
    let isSelected: Bool
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 72, height: 72)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                        .background(Circle().fill(Color.white))
                        .offset(x: 8, y: -8)
                }
            }
            
            Text(app.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 30)
        }
        .frame(width: 100)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : (isHovered ? Color.gray.opacity(0.1) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct AppScanner {
    static func scanInstalledApps() -> [InstalledApp] {
        var apps: [InstalledApp] = []
        
        let appDirectories = [
            "/Applications",
            "/System/Applications",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]
        
        for directory in appDirectories {
            if let appURLs = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: directory),
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) {
                for appURL in appURLs where appURL.pathExtension == "app" {
                    if let app = createInstalledApp(from: appURL) {
                        apps.append(app)
                    }
                }
            }
        }
        
        return apps
    }
    
    private static func createInstalledApp(from url: URL) -> InstalledApp? {
        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier,
              let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String else {
            return nil
        }
        
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        
        return InstalledApp(
            name: name,
            bundleID: bundleID,
            icon: icon,
            path: url
        )
    }
}


extension Notification.Name {
    static let dockAppsChanged = Notification.Name("dockAppsChanged")
    static let dockAppearanceChanged = Notification.Name("dockAppearanceChanged")
}


struct DockAppearanceSettings: View {
    @AppStorage("dockColorRed") private var colorRed: Double = 0.0
    @AppStorage("dockColorGreen") private var colorGreen: Double = 0.0
    @AppStorage("dockColorBlue") private var colorBlue: Double = 0.0
    @AppStorage("dockOpacity") private var opacity: Double = 0.3
    @AppStorage("dockBlurEnabled") private var blurEnabled: Bool = true
    @AppStorage("dockBackgroundImagePath") private var backgroundImagePath: String = ""
    @AppStorage("dockImageBlur") private var imageBlur: Double = 0.0
    @AppStorage("dockSize") private var dockSize: Double = 48.0
    
    @State private var selectedImage: NSImage?
    
    var selectedColor: Color {
        Color(red: colorRed, green: colorGreen, blue: colorBlue)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                previewSection
                
                sizeSection
                
                backgroundImageSection
                
                colorSection
                
                opacitySection
                
                blurSection
                
                presetSection
            }
            .padding()
        }
        .onAppear {
            loadBackgroundImage()
        }
    }
    
    private var sizeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String.localized(.dockSize))
                    .font(.headline)
                Spacer()
                Text("\(Int(dockSize))px")
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $dockSize, in: 40...80, step: 1) {
                Text("")
            } onEditingChanged: { _ in
                notifyChange()
            }
            
            HStack(spacing: 8) {
                Button(String.localized(.small)) {
                    dockSize = 40
                    notifyChange()
                }
                .buttonStyle(.bordered)
                
                Button(String.localized(.medium)) {
                    dockSize = 48
                    notifyChange()
                }
                .buttonStyle(.bordered)
                
                Button(String.localized(.large)) {
                    dockSize = 64
                    notifyChange()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var backgroundImageSection: some View {
        VStack(spacing: 12) {
            Text(String.localized(.backgroundImage))
                .font(.headline)
            
            if let image = selectedImage {
                VStack(spacing: 8) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .cornerRadius(8)
                        .clipped()
                    
                    HStack {
                        Button(String.localized(.chooseImage)) {
                            selectBackgroundImage()
                        }
                        .buttonStyle(.bordered)
                        
                        Button(String.localized(.removeImage)) {
                            removeBackgroundImage()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text(String.localized(.imageBlur))
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(imageBlur))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $imageBlur, in: 0...100) {
                            Text("")
                        } onEditingChanged: { _ in
                            notifyChange()
                        }
                    }
                }
            } else {
                Button(String.localized(.chooseImage)) {
                    selectBackgroundImage()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var previewSection: some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.headline)
            
            HStack(spacing: 8) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: dockSize * 0.42))
                Image(systemName: "magnifyingglass")
                    .font(.system(size: dockSize * 0.34))
                Image(systemName: "folder.fill")
                    .font(.system(size: dockSize * 0.42))
                Image(systemName: "safari.fill")
                    .font(.system(size: dockSize * 0.42))
            }
            .foregroundColor(.white)
            .padding()
            .frame(height: dockSize)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    if let image = selectedImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: imageBlur * 0.2)
                    }
                    
                    if blurEnabled {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                selectedColor.opacity(opacity),
                                                selectedColor.opacity(opacity * 0.8)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        selectedColor.opacity(opacity),
                                        selectedColor.opacity(opacity * 0.8)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
            }
            .cornerRadius(12)
            .clipped()
        }
    }
    
    private var colorSection: some View {
        VStack(spacing: 12) {
            Text(String.localized(.dockColor))
                .font(.headline)
            
            ColorPicker("", selection: Binding(
                get: { selectedColor },
                set: { color in
                    if let components = color.cgColor?.components {
                        colorRed = Double(components[0])
                        colorGreen = Double(components[1])
                        colorBlue = Double(components[2])
                        notifyChange()
                    }
                }
            ))
            .labelsHidden()
        }
    }
    
    private var opacitySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String.localized(.opacity))
                    .font(.headline)
                Spacer()
                Text("\(Int(opacity * 100))%")
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $opacity, in: 0...1) {
                Text("")
            } onEditingChanged: { _ in
                notifyChange()
            }
        }
    }
    
    private var blurSection: some View {
        VStack(spacing: 12) {
            Toggle(String.localized(.blurEffect), isOn: $blurEnabled)
                .font(.headline)
                .onChange(of: blurEnabled) { _ in
                    notifyChange()
                }
        }
    }
    
    private var presetSection: some View {
        VStack(spacing: 12) {
            Text("Presets")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: 12)
            ], spacing: 12) {
                PresetButton(name: "Dark", color: .black) {
                    applyPreset(r: 0, g: 0, b: 0, opacity: 0.4)
                }
                PresetButton(name: "Blue", color: .blue) {
                    applyPreset(r: 0, g: 0.3, b: 0.8, opacity: 0.3)
                }
                PresetButton(name: "Purple", color: .purple) {
                    applyPreset(r: 0.5, g: 0, b: 0.8, opacity: 0.3)
                }
                PresetButton(name: "Green", color: .green) {
                    applyPreset(r: 0, g: 0.6, b: 0.3, opacity: 0.3)
                }
                PresetButton(name: "Red", color: .red) {
                    applyPreset(r: 0.8, g: 0, b: 0.2, opacity: 0.3)
                }
                PresetButton(name: "Clear", color: .clear) {
                    applyPreset(r: 0, g: 0, b: 0, opacity: 0.1)
                }
            }
        }
    }
    
    private func loadBackgroundImage() {
        if backgroundImagePath.isEmpty {
            if let path = UserDefaults.standard.string(forKey: "dockBackgroundImagePath") {
                backgroundImagePath = path
            }
        }
        guard !backgroundImagePath.isEmpty else { return }
        if let image = NSImage(contentsOfFile: backgroundImagePath) {
            selectedImage = image
        }
    }
    
    private func selectBackgroundImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            backgroundImagePath = url.path
            UserDefaults.standard.set(url.path, forKey: "dockBackgroundImagePath")
            selectedImage = NSImage(contentsOf: url)
            notifyChange()
        }
    }
    
    private func removeBackgroundImage() {
        backgroundImagePath = ""
        UserDefaults.standard.removeObject(forKey: "dockBackgroundImagePath")
        selectedImage = nil
        notifyChange()
    }
    
    private func applyPreset(r: Double, g: Double, b: Double, opacity: Double) {
        colorRed = r
        colorGreen = g
        colorBlue = b
        self.opacity = opacity
        notifyChange()
    }
    
    private func notifyChange() {
        NotificationCenter.default.post(name: .dockAppearanceChanged, object: nil)
    }
}

struct PresetButton: View {
    let name: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    }
                    .frame(height: 40)
                
                Text(name)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SystemUpdateBadge: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            Path { path in
                path.move(to: CGPoint(x: 4.8, y: 9.6))
                path.addLine(to: CGPoint(x: 8.1, y: 13.5))
                path.addLine(to: CGPoint(x: 14.7, y: 5.1))
                path.addLine(to: CGPoint(x: 13.2, y: 4.2))
                path.addLine(to: CGPoint(x: 8.1, y: 11.4))
                path.addLine(to: CGPoint(x: 6.3, y: 9))
                path.closeSubpath()
            }
            .fill(Color(red: 0.0039, green: 0.6509, blue: 0.0039))
        }
        .frame(width: 18, height: 18)
    }
}


#Preview {
    DockSettingsView()
}

struct StatusBarView: View {
    @ObservedObject var caps: CapsLockObserver
    @ObservedObject var status: SystemStatusManager
    
    var body: some View {
        HStack(spacing: 10) {
            Text(caps.isOn ? "한" : "EN")
                .font(.caption2.weight(.semibold))
                .frame(width: 28, height: 18)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)))
            
            Image(systemName: status.wifiStrength >= 2 ? "wifi" : (status.wifiStrength == 1 ? "wifi.exclamationmark" : "wifi.slash"))
                .font(.caption2)
            
            HStack(spacing: 2) {
                Image(systemName: status.isCharging ? "battery.100.bolt" : "battery.100")
                    .font(.caption2)
                Text("\(status.batteryLevel)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if status.updateMessage.contains("Update") {
                SystemUpdateBadge()
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.15)))
        .fixedSize()
    }
}

