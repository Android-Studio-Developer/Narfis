
import SwiftUI
import AppKit

class DockWindow: NSPanel {
    
    init() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        let dockHeight: CGFloat = 60
        let dockFrame = NSRect(
            x: 0,
            y: 0,
            width: screenFrame.width,
            height: dockHeight
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
        
        let hostingView = NSHostingView(rootView: DockView())
        self.contentView = hostingView
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc func screenDidChange() {
        guard let screenFrame = NSScreen.main?.frame else { return }
        let dockHeight: CGFloat = 60
        self.setFrame(
            NSRect(x: 0, y: 0, width: screenFrame.width, height: dockHeight),
            display: true
        )
    }
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

struct DockItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let action: () -> Void
}

struct DockView: View {
    @State private var hoveredItem: UUID?
    @State private var dockItems: [DockItem] = []
    
    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            
            ForEach(dockItems) { item in
                DockItemView(
                    item: item,
                    isHovered: hoveredItem == item.id
                )
                .onHover { isHovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        hoveredItem = isHovering ? item.id : nil
                    }
                }
                .onTapGesture {
                    item.action()
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .onAppear {
            loadDockItems()
        }
    }
    
    private func loadDockItems() {
        dockItems = [
            DockItem(name: "Finder", icon: "folder.fill") {
                openFinder()
            },
            DockItem(name: "Safari", icon: "safari.fill") {
                openSafari()
            },
            DockItem(name: "Mail", icon: "envelope.fill") {
                openMail()
            },
            DockItem(name: "Messages", icon: "message.fill") {
                openMessages()
            },
            DockItem(name: "Music", icon: "music.note") {
                openMusic()
            },
            DockItem(name: "Calendar", icon: "calendar") {
                openCalendar()
            },
            DockItem(name: "Photos", icon: "photo.fill") {
                openPhotos()
            },
            DockItem(name: "Settings", icon: "gearshape.fill") {
                openSettings()
            }
        ]
    }
    
    private func openFinder() {
        NSWorkspace.shared.launchApplication("Finder")
    }
    
    private func openSafari() {
        NSWorkspace.shared.launchApplication("Safari")
    }
    
    private func openMail() {
        NSWorkspace.shared.launchApplication("Mail")
    }
    
    private func openMessages() {
        NSWorkspace.shared.launchApplication("Messages")
    }
    
    private func openMusic() {
        NSWorkspace.shared.launchApplication("Music")
    }
    
    private func openCalendar() {
        NSWorkspace.shared.launchApplication("Calendar")
    }
    
    private func openPhotos() {
        NSWorkspace.shared.launchApplication("Photos")
    }
    
    private func openSettings() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }
}

struct DockItemView: View {
    let item: DockItem
    let isHovered: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: item.icon)
                .font(.system(size: isHovered ? 36 : 32))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .scaleEffect(isHovered ? 1.2 : 1.0)
            
            if isHovered {
                Text(item.name)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

#Preview {
    DockView()
        .frame(width: 800, height: 60)
}
