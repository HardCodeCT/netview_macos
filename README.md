# NetView for macOS

A native macOS network monitoring application that tracks your download and upload statistics in real-time. Port of the Windows NetView application.

![NetView Screenshot](screenshot.png)

## Features

- 📊 **Real-time Monitoring**: Live download/upload speed display in menu bar
- 📈 **Usage History**: Track daily, monthly, and yearly network usage
- 💾 **Persistent Data**: Never lose your usage history
- 🚀 **Auto-start**: Launches automatically on system boot
- 🎨 **Native macOS Design**: SwiftUI-based beautiful dark theme
- 🔒 **7-Day Free Trial**: Full access to test all features
- 💰 **Lifetime License**: One-time payment of $9.99

## System Requirements

- macOS 12.0 (Monterey) or later.
- 64-bit Intel or Apple Silicon processor
- ~20 MB disk space

## Installation

### Method 1: Download Pre-built DMG (Recommended)

1. Download the latest `NetView-macOS.dmg` from [Releases](https://github.com/yourusername/NetView/releases)
2. Open the DMG file
3. Drag **NetView.app** to your **Applications** folder
4. Open NetView from Applications

**Security Note**: On first launch, macOS may show a security warning because the app is not signed. To allow it:
1. Go to **System Settings** > **Privacy & Security**
2. Scroll down to find **NetView** in the security section
3. Click **Open Anyway**

### Method 2: Build from Source

Prerequisites:
- Xcode 15.0 or later
- macOS 12.0 or later
- Homebrew (for create-dmg tool)

```bash
# Clone the repository
git clone https://github.com/yourusername/NetView.git
cd NetView/NetViewMac

# Make build script executable
chmod +x build-dmg.sh

# Build the DMG
./build-dmg.sh
```

The script will:
- Install required dependencies (create-dmg)
- Build NetView.app using Xcode
- Create a distributable DMG installer
- Output: `NetView-macOS.dmg`

## Building with GitHub Actions

The project includes a GitHub Actions workflow that automatically builds and creates DMG installers.

### Automatic Builds

Every push to `main` or `master` branch triggers a build:

```yaml
on:
  push:
    branches: [ main, master ]
```

The workflow:
1. Checks out code
2. Sets up latest Xcode
3. Builds NetView.app
4. Creates DMG installer
5. Uploads DMG as artifact (available for 90 days)

### Creating a Release

To create an official release with the DMG:

```bash
# Tag your commit
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will:
- Build the DMG
- Create a GitHub Release
- Attach the DMG to the release
- Generate release notes automatically

## Project Structure

```
NetViewMac/
├── NetView/                      # Main app source code
│   ├── NetViewApp.swift          # App entry point
│   ├── DataManager.swift         # Network monitoring
│   ├── HistoryManager.swift      # Usage history tracking
│   ├── LicenseManager.swift      # Trial/license management
│   ├── AutoStartManager.swift    # Auto-start functionality
│   ├── StatusBarController.swift # Menu bar widget
│   ├── MonitorView.swift         # Main popover UI
│   ├── HistoryWindowView.swift   # History window UI
│   ├── PaymentWindowView.swift   # Payment UI
│   ├── Info.plist                # App metadata
│   └── NetView.entitlements      # App permissions
├── NetView.xcodeproj/            # Xcode project
├── Package.swift                 # Swift Package Manager
├── build-dmg.sh                  # Local build script
├── .github/
│   └── workflows/
│       └── build.yml             # CI/CD pipeline
└── README.md                     # This file
```

## Usage

### First Launch

1. NetView will show a welcome dialog explaining the 7-day trial
2. The app icon appears in your menu bar (top-right)
3. Click the icon to see real-time stats
4. Network monitoring starts automatically

### Menu Bar Widget

The menu bar shows:
- **↓ Download speed** (green)
- **↑ Upload speed** (red)

Click the widget to see:
- Total data transferred (this session)
- Current transfer rates
- Quick access to History and Payment

### History Window

Click **History** button to view:
- **Summary Cards**: Today, This Month, This Year totals
- **Daily Records**: Complete history sorted by date
- **Cumulative Mode**: Click circles to see cumulative totals from any date

### License & Trial

- **Trial**: 7 days full access, no credit card required
- **After Trial**: $9.99 one-time payment for lifetime access
- **Installation Key**: Unique identifier for license activation
- **Payment**: Click **Pay** button in widget

## Technical Details

### Network Monitoring

NetView uses macOS `SystemConfiguration` framework to:
- Detect active network interfaces (WiFi, Ethernet)
- Read network statistics via `getifaddrs()`
- Calculate real-time transfer rates
- Handle interface switches seamlessly

Key features:
- **Auto-reconnect**: Switches interfaces if connection drops
- **Data preservation**: Maintains totals across reconnects
- **Smoothing**: Reduces rate fluctuations (30% new, 70% old)
- **Noise filtering**: Ignores background traffic < 100 B/s

### Data Persistence

History is stored in:
```
~/Library/Application Support/NetView/history.txt
```

Format: CSV with daily records
```
2025-02-17,1073741824,536870912
Date,Download,Upload (bytes)
```

**Crash-resistant saves**:
- Atomic file writes with temp files
- Auto-save every 2 seconds
- Flush to disk before rename
- Cumulative mode support

### Auto-Start

Uses `ServiceManagement` framework:
- **macOS 13+**: `SMAppService.mainApp`
- **macOS 12**: `LSSharedFileList` (deprecated but functional)

Configured on first run, persists across updates.

### Trial & Licensing

Stored in `UserDefaults`:
- `InstallationKey`: Unique 32-character hex key
- `InstallDate`: Trial start date
- `Licensed`: Activation status
- `FirstRunComplete`: Setup flag

Trial: 7 days from `InstallDate`, calculated by calendar days.

## Differences from Windows Version

| Feature | Windows | macOS |
|---------|---------|-------|
| UI Framework | Win32 GDI | SwiftUI |
| Network API | IP Helper API | SystemConfiguration |
| Persistence | Registry | UserDefaults |
| Auto-start | Registry Run key | Login Items |
| Packaging | Inno Setup | DMG |
| Menu | Tray icon | Menu bar |

## Code Signing & Notarization (Optional)

For distribution outside GitHub, you should code sign and notarize:

### Prerequisites

1. Apple Developer Account ($99/year)
2. Developer ID Application certificate
3. App-specific password for notarization

### Sign the App

```bash
# Import your certificate to Keychain

# Sign the app
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  --entitlements NetView/NetView.entitlements \
  dist/NetView.app

# Verify signature
codesign --verify --deep --strict --verbose=2 dist/NetView.app
```

### Notarize

```bash
# Create a ZIP for notarization
ditto -c -k --keepParent dist/NetView.app NetView.zip

# Submit for notarization
xcrun notarytool submit NetView.zip \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait

# Staple the ticket
xcrun stapler staple dist/NetView.app

# Now create DMG with signed app
./build-dmg.sh
```

### Sign the DMG

```bash
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" NetView-macOS.dmg
```

## Troubleshooting

### "NetView is damaged and can't be opened"

This happens with unsigned apps. Fix:
```bash
xattr -cr /Applications/NetView.app
```

### Network monitoring not working

1. Check System Settings > Privacy & Security > Full Disk Access
2. Add NetView.app to the list
3. Restart NetView

### Auto-start not working

```bash
# Check login items
osascript -e 'tell application "System Events" to get the name of every login item'

# Manually add if needed
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/NetView.app", hidden:false}'
```

### Build errors

```bash
# Clean build
rm -rf build
xcodebuild clean

# Verify Xcode CLI tools
xcode-select --install

# Check Xcode version
xcodebuild -version
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on macOS 12+
5. Submit a pull request

## License

Copyright © 2025 NetView. All rights reserved.

This is proprietary software. The 7-day trial allows evaluation of all features. After the trial period, a license must be purchased for continued use.

## Support

- **Email**: support@netview.app
- **Twitter**: [@NetViewApp](https://twitter.com/NetViewApp)
- **Issues**: [GitHub Issues](https://github.com/yourusername/NetView/issues)

## Changelog

### v1.0.0 (2025-02-17)
- Initial macOS release
- Native SwiftUI interface
- Real-time network monitoring
- Usage history tracking
- 7-day free trial
- Lifetime license ($9.99)
- Auto-start on boot
- GitHub Actions CI/CD

---

**Made with ❤️ for macOS**
