
import SwiftUI
import AppKit
import Combine
import IOKit.ps

class DockWindow: NSPanel {
    
    @AppStorage("dockSize") private var dockSize: Double = 48.0
    
    init() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        let dockHeight = UserDefaults.standard.double(forKey: "dockSize")
        let height = dockHeight > 0 ? dockHeight : 48.0
        
        let dockFrame = NSRect(
            x: 0,
            y: 0,
            width: screenFrame.width,
            height: height
        )
        
        super.init(
            contentRect: dockFrame,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isOpaque = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        
        let hostingView = NSHostingView(rootView: DockView(dockWindow: self))
        self.contentView = hostingView
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appearanceDidChange),
            name: .dockAppearanceChanged,
            object: nil
        )
    }
    
    @objc func screenDidChange() {
        updateDockFrame()
    }
    
    @objc func appearanceDidChange() {
        updateDockFrame()
    }
    
    private func updateDockFrame() {
        guard let screenFrame = NSScreen.main?.frame else { return }
        let dockHeight = UserDefaults.standard.double(forKey: "dockSize")
        let height = dockHeight > 0 ? dockHeight : 48.0
        
        self.setFrame(
            NSRect(x: 0, y: 0, width: screenFrame.width, height: height),
            display: true,
            animate: true
        )
    }
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

struct DockItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let appIcon: NSImage?
    let action: () -> Void
    
    init(name: String, icon: String, bundleIdentifier: String? = nil, action: @escaping () -> Void) {
        self.name = name
        self.icon = icon
        self.action = action
        
        if let bundleID = bundleIdentifier,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            self.appIcon = NSWorkspace.shared.icon(forFile: appURL.path)
        } else {
            self.appIcon = nil
        }
    }
}

struct DockView: View {
    weak var dockWindow: DockWindow?
    
    @State private var hoveredItem: UUID?
    @State private var dockItems: [DockItem] = []
    @State private var currentTime = Date()
    @State private var searchHovered = false
    @State private var startMenuHovered = false
    @State private var widgetsHovered = false
    @State private var localEventMonitor: Any?
    @State private var systemTrayHovered = false
    @State private var batteryLevel: Int = 100
    @State private var isCharging: Bool = false
    @State private var volumeLevel: Float = 0.5
    @StateObject private var localization = LocalizationManager.shared
    
    @AppStorage("dockColorRed") private var colorRed: Double = 0.0
    @AppStorage("dockColorGreen") private var colorGreen: Double = 0.0
    @AppStorage("dockColorBlue") private var colorBlue: Double = 0.0
    @AppStorage("dockOpacity") private var opacity: Double = 0.3
    @AppStorage("dockBlurEnabled") private var blurEnabled: Bool = true
    @AppStorage("dockBackgroundImagePath") private var backgroundImagePath: String = ""
    @AppStorage("dockImageBlur") private var imageBlur: Double = 0.0
    @AppStorage("dockSize") private var dockSize: Double = 48.0
    
    @State private var backgroundImage: NSImage?
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var dockBackgroundColor: Color {
        Color(red: colorRed, green: colorGreen, blue: colorBlue)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            widgetsButton
                .padding(.leading, 8)
            
            Spacer()
            
            HStack(spacing: 4) {
                startButton
                searchBar
                
                HStack(spacing: 4) {
                    ForEach(dockItems) { item in
                        DockItemView(
                            item: item,
                            isHovered: hoveredItem == item.id
                        )
                        .onHover { isHovering in
                            hoveredItem = isHovering ? item.id : nil
                        }
                        .onTapGesture {
                            item.action()
                        }
                    }
                }
                .padding(.leading, 8)
            }
            
            Spacer()
            
            systemTray
                .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                if let bgImage = backgroundImage {
                    Image(nsImage: bgImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: imageBlur * 0.5)
                }
                
                if blurEnabled {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            dockBackgroundColor.opacity(opacity),
                                            dockBackgroundColor.opacity(opacity * 0.8)
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
                                    dockBackgroundColor.opacity(opacity),
                                    dockBackgroundColor.opacity(opacity * 0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
        }
        .onAppear {
            loadDockItems()
            setupKeyboardShortcut()
            updateBatteryStatus()
            updateVolumeLevel()
            loadBackgroundImage()
            
            NotificationCenter.default.addObserver(
                forName: .dockAppsChanged,
                object: nil,
                queue: .main
            ) { _ in
                loadDockItems()
            }
            
            NotificationCenter.default.addObserver(
                forName: .dockAppearanceChanged,
                object: nil,
                queue: .main
            ) { _ in
                loadBackgroundImage()
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            updateBatteryStatus()
        }
        .onDisappear {
            removeKeyboardShortcut()
        }
    }
    
    private var widgetsButton: some View {
        Button {
            openWidgets()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.3x3")
                    .font(.system(size: 16))
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 14))
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 40)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(widgetsHovered ? Color.white.opacity(0.2) : Color.clear)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                widgetsHovered = hovering
            }
        }
    }
    
    private var startButton: some View {
        Button {
            openSettingsWindow()
        } label: {
            Image(systemName: "cloud.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(startMenuHovered ? Color.white.opacity(0.2) : Color.clear)
                }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                startMenuHovered = hovering
            }
        }
        .contextMenu {
            Menu(String.localized(.language)) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button {
                        localization.currentLanguage = language
                    } label: {
                        HStack {
                            Text(language.displayName)
                            if localization.currentLanguage == language {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 14))
            
            Text(String.localized(.search))
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 13))
        }
        .frame(width: 240, height: 32)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(searchHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.1))
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                searchHovered = hovering
            }
        }
        .onTapGesture {
            openSearchInterface()
        }
    }
    
    private var systemTray: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    openWiFiSettings()
                } label: {
                    Image(systemName: "wifi")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                
                Button {
                    toggleMute()
                } label: {
                    Image(systemName: volumeLevel > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                
                Button {
                    openBatterySettings()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: batteryIcon)
                            .font(.system(size: 14))
                            .foregroundColor(batteryColor)
                        if isCharging {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            
            Divider()
              .frame(height: 20)
                .background(Color.white.opacity(0.3))
            
            Button {
                openCalendar()
            } label: {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(currentTime, format: .dateTime.hour().minute())
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    Text(currentTime, format: .dateTime.year().month().day())
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(systemTrayHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.1))
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                systemTrayHovered = hovering
            }
        }
    }
    
    private var batteryIcon: String {
        if isCharging {
            return "battery.100.bolt"
        }
        
        switch batteryLevel {
        case 0..<20:
            return "battery.0"
        case 20..<50:
            return "battery.25"
        case 50..<75:
            return "battery.50"
        case 75..<95:
            return "battery.75"
        default:
            return "battery.100"
        }
    }
    
    private var batteryColor: Color {
        if isCharging {
            return .green
        }
        return batteryLevel < 20 ? .red : .white
    }
    
    private func loadDockItems() {
        let selectedBundleIDs = loadSelectedApps()
        
        if selectedBundleIDs.isEmpty {
            dockItems = getDefaultApps()
        } else {
            dockItems = selectedBundleIDs.compactMap { bundleID in
                guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
                      let bundle = Bundle(url: appURL),
                      let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String else {
                    return nil
                }
                
                return DockItem(name: name, icon: "app", bundleIdentifier: bundleID) {
                    self.openApplicationByBundleID(bundleID)
                }
            }
        }
    }
    
    private func getDefaultApps() -> [DockItem] {
        return [
            addApp("Chrome", "globe", "com.google.Chrome"),
            addApp("Safari", "safari", "com.apple.Safari"),
            addApp("Finder", "folder.fill", "com.apple.finder"),
            addApp("Music", "music.note", "com.apple.Music"),
            addApp("TV", "tv.fill", "com.apple.TV"),
            addApp("Mail", "envelope.fill", "com.apple.mail"),
            addApp("Messages", "message.fill", "com.apple.MobileSMS"),
            addApp("Calendar", "calendar", "com.apple.iCal"),
            addApp("App Store", "app.gift.fill", "com.apple.AppStore"),
            addApp("Photos", "photo.fill", "com.apple.Photos"),
        ]
    }
    
    private func loadSelectedApps() -> [String] {
        if let data = UserDefaults.standard.data(forKey: "selectedDockApps"),
           let apps = try? JSONDecoder().decode(Set<String>.self, from: data) {
            return Array(apps)
        }
        return []
    }
    
    private func loadBackgroundImage() {
        guard !backgroundImagePath.isEmpty else {
            backgroundImage = nil
            return
        }
        if let image = NSImage(contentsOfFile: backgroundImagePath) {
            backgroundImage = image
        }
    }
    
    private func openApplicationByBundleID(_ bundleID: String) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            print("❌ Failed to find app with bundle ID: \(bundleID)")
            return
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
            if let error = error {
                print("❌ Failed to open app: \(error.localizedDescription)")
            }
        }
    }
    
    private func addApp(_ name: String, _ icon: String, _ bundleID: String) -> DockItem {
        return DockItem(name: name, icon: icon, bundleIdentifier: bundleID) {
            self.openApplication(named: name)
        }
    }
    
    private func openSearchInterface() {
        let script = """
        tell application "System Events"
            keystroke space using command down
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            print("❌ Failed to open Spotlight: \(error)")
            
            fallbackToLaunchpad()
        }
    }
    
    private func fallbackToLaunchpad() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", "Spotlight"]
        
        do {
            try task.run()
        } catch {
            print("❌ Failed to open Spotlight: \(error)")
        }
    }
    
    private func setupKeyboardShortcut() {
    }
    
    private func removeKeyboardShortcut() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
    
    private func updateBatteryStatus() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for source in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as! [String: Any]
            
            if let capacity = info[kIOPSCurrentCapacityKey] as? Int,
               let maxCapacity = info[kIOPSMaxCapacityKey] as? Int {
                batteryLevel = (capacity * 100) / maxCapacity
            }
            
            if let charging = info[kIOPSIsChargingKey] as? Bool {
                isCharging = charging
            }
        }
    }
    
    private func updateVolumeLevel() {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", "output volume of (get volume settings)"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8),
           let volume = Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) {
            volumeLevel = Float(volume) / 100.0
        }
    }
    
    private func openWiFiSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.network")!)
    }
    
    private func openBatterySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.battery")!)
    }
    
    private func openCalendar() {
        openApplication(named: "Calendar")
    }
    
    private func toggleMute() {
        let script = """
        set volume output volume (100 - (output volume of (get volume settings)))
        """
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(nil)
        updateVolumeLevel()
    }
    
    private func openSettingsWindow() {
        let settingsView = DockSettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = String.localized(.dockSettings)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
    }
    
    private func openWidgets() {
        let script = """
        tell application "System Events"
            tell process "NotificationCenter"
                set frontmost to true
            end tell
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        
        if error != nil {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:")!)
        }
    }
    
    private func openApplication(named name: String) {
        let bundleID = bundleIdentifier(for: name)
        
        if bundleID.isEmpty {
            print("❌ No bundle ID found for: \(name)")
            return
        }
        
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            print("❌ Failed to find application: \(name)")
            return
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
            if let error = error {
                print("❌ Failed to open \(name): \(error.localizedDescription)")
            } else {
                print("✅ Opened \(name)")
            }
        }
    }
    
    private func bundleIdentifier(for appName: String) -> String {
        switch appName {
        case "Finder": return "com.apple.finder"
        case "Safari": return "com.apple.Safari"
        case "Mail": return "com.apple.mail"
        case "Messages": return "com.apple.MobileSMS"
        case "Calendar": return "com.apple.iCal"
        case "Photos": return "com.apple.Photos"
        case "Contacts": return "com.apple.AddressBook"
        case "Notes": return "com.apple.Notes"
        case "Reminders": return "com.apple.reminders"
        case "Maps": return "com.apple.Maps"
        case "FaceTime": return "com.apple.FaceTime"
        case "App Store": return "com.apple.AppStore"
        
        case "Music": return "com.apple.Music"
        case "TV": return "com.apple.TV"
        case "Podcasts": return "com.apple.podcasts"
        case "Books": return "com.apple.iBooksX"
        case "News": return "com.apple.news"
        
        case "Xcode": return "com.apple.dt.Xcode"
        case "Terminal": return "com.apple.Terminal"
        
        case "Chrome": return "com.google.Chrome"
        case "Firefox": return "org.mozilla.firefox"
        case "VSCode": return "com.microsoft.VSCode"
        case "Slack": return "com.tinyspeck.slackmacgap"
        case "Discord": return "com.ongasoft.discord"
        case "Spotify": return "com.spotify.client"
        
        default: return ""
        }
    }
}

struct DockItemView: View {
    let item: DockItem
    let isHovered: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Group {
                if let appIcon = item.appIcon {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: item.icon)
                        .font(.system(size: 22))
                }
            }
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.2) : Color.clear)
            }
            .padding(2)
            
            if !isHovered {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 4, height: 4)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

#Preview {
    DockView()
        .frame(width: 800, height: 60)
}
