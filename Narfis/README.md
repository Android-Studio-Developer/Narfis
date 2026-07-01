# Narfis ☁️

> A beautiful Windows 11 inspired taskbar/dock for macOS

![macOS](https://img.shields.io/badge/macOS-11.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0+-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## ✨ Features

- 🎨 **Windows 11 Acrylic Design** - Beautiful translucent material with gradient overlay
- 🔋 **Real-time System Status** - Live battery level, Wi-Fi, and volume indicators
- 🔍 **Spotlight Integration** - Quick search with Cmd+Space
- 🚀 **Fast App Launching** - Click to open apps instantly
- ⚙️ **Easy App Management UI** - Visual app picker, no coding required! ⭐ NEW
- 🖱️ **Interactive Icons** - Hover effects and click actions
- 📱 **Native macOS Integration** - Uses actual app icons
- 🔄 **Auto App Discovery** - Automatically finds all installed apps

## 📸 Screenshots

_Coming soon_

## 🛠️ Installation

### Requirements
- macOS 11.0 or later
- Xcode 14.0 or later
- Swift 5.9 or later

### Build from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/narfis.git
cd narfis
```

2. Open in Xcode:
```bash
open Narfis.xcodeproj
```

3. Build and run (⌘R)

## 🎯 Usage

### 🌟 Easy App Management (No Coding Required!)

**Simply click the cloud icon** (☁️ start button) to open the settings window!

The visual app picker lets you:

1. ✅ **Browse all installed apps** - Automatically scans your Applications folder
2. 🔍 **Search apps instantly** - Quick filter by name
3. 🎨 **See beautiful app icons** - Grid layout with real app icons
4. ✔️ **Click to select/deselect** - Toggle apps on/off with a single click
5. 💾 **Save your preferences** - Choices are remembered automatically

**Perfect for everyone!** No need to know bundle IDs or edit code.

### Advanced: Manual Configuration

For advanced users who prefer code editing:

```swift
// In DockWindow.swift -> getDefaultApps()
return [
    addApp("Chrome", "globe", "com.google.Chrome"),
    addApp("Custom App", "icon.name", "com.company.bundleid"),
]
```

### System Controls

- **Wi-Fi Icon** - Click to open Network settings
- **Volume Icon** - Click to toggle mute
- **Battery Icon** - Click to open Battery settings  
- **Time/Date** - Click to open Calendar app
- **Search Bar** - Click or press Cmd+Space for Spotlight

### Keyboard Shortcuts

- `Cmd+Space` - Open Spotlight search (works anywhere)

## 🔧 Customization

### Supported Apps

The following apps are pre-configured with bundle identifiers:

**System Apps:**
- Finder, Safari, Mail, Messages, Calendar, Photos, Notes, Reminders, Maps, FaceTime, Contacts, App Store

**Media Apps:**
- Music, TV, Podcasts, Books, News

**Development:**
- Xcode, Terminal

**Third-party:**
- Chrome, Firefox, VSCode, Slack, Discord, Spotify

### Adding Custom Apps

To add an app not in the list:

```swift
addApp("AppName", "sf.symbol.icon", "com.company.appbundleid")
```

To find an app's bundle identifier:
```bash
osascript -e 'id of app "AppName"'
```

## 🏗️ Architecture

- **DockWindow**: NSPanel subclass for the window management
- **DockView**: Main SwiftUI view with all UI components
- **DockItem**: Model for dock items with app icons
- **DockItemView**: Individual app icon view component

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 TODO

- [ ] Custom app picker UI
- [ ] Dock position options (bottom/top)
- [ ] Dock size customization
- [ ] Theme support (light/dark/custom)
- [ ] Start menu implementation
- [ ] Running app indicators
- [ ] App right-click menu
- [ ] System tray notifications
- [ ] Dock auto-hide option
- [ ] Multi-monitor support

## 🐛 Known Issues

- Spotlight integration requires Accessibility permissions
- Some third-party apps may not launch if bundle ID is incorrect
- Battery status may not update on desktop Macs

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👏 Acknowledgments

- Inspired by Windows 11 taskbar design
- Built with SwiftUI and AppKit
- Created by [HashtagPro](https://github.com/yourusername)

## 💬 Contact

- GitHub: [@yourusername](https://github.com/yourusername)
- Twitter: [@yourusername](https://twitter.com/yourusername)

---

⭐️ Star this repo if you like it!
