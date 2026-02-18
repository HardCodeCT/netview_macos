# Quick Start Guide - NetView for macOS

Get NetView running on macOS in under 5 minutes.

## Option 1: Download Pre-built DMG (Easiest)

### Step 1: Download
```bash
# Visit GitHub Releases
open https://github.com/yourusername/NetView/releases

# Download NetView-macOS.dmg
```

### Step 2: Install
1. Double-click `NetView-macOS.dmg`
2. Drag `NetView.app` to `Applications` folder
3. Open `Applications` folder
4. Double-click `NetView`

### Step 3: Grant Permissions
When you see "NetView can't be opened":
1. Go to **System Settings** > **Privacy & Security**
2. Scroll to **Security** section
3. Click **Open Anyway** next to NetView
4. Click **Open** in the confirmation dialog

✅ Done! NetView is now running in your menu bar.

---

## Option 2: Build from Source (Developers)

### Prerequisites
- macOS 12.0 (Monterey) or later
- Internet connection
- ~30 minutes for first-time setup

### Step 1: Clone Repository
```bash
git clone https://github.com/yourusername/NetView.git
cd NetView/NetViewMac
```

### Step 2: Run Setup
```bash
chmod +x setup.sh
./setup.sh
```

This installs:
- Xcode Command Line Tools (if needed)
- Homebrew (if needed)
- create-dmg tool

### Step 3: Build
```bash
./build-dmg.sh
```

Output: `NetView-macOS.dmg`

### Step 4: Install
```bash
open NetView-macOS.dmg
# Drag to Applications as in Option 1
```

✅ Done!

---

## Option 3: GitHub Actions (Automated CI/CD)

### Step 1: Fork Repository
1. Visit https://github.com/yourusername/NetView
2. Click "Fork" button
3. Clone your fork:
```bash
git clone https://github.com/YOURUSERNAME/NetView.git
cd NetView
```

### Step 2: Enable GitHub Actions
1. Go to your forked repository on GitHub
2. Click **Settings** > **Actions** > **General**
3. Under "Workflow permissions", select:
   - ✅ Read and write permissions
4. Click **Save**

### Step 3: Push Code (Triggers Build)
```bash
# Make any change
touch test.txt
git add test.txt
git commit -m "Test build"
git push origin main
```

### Step 4: Download Artifact
1. Go to **Actions** tab on GitHub
2. Click your workflow run
3. Download **NetView-macOS-DMG** artifact
4. Extract and install

### Step 5: Create Release (Optional)
```bash
# Tag for release
git tag v1.0.0
git push origin v1.0.0
```

GitHub will automatically:
- Build the app
- Create DMG
- Create Release
- Attach DMG to release

✅ Done! Your release is at: github.com/YOURUSERNAME/NetView/releases

---

## Usage

### First Launch
After installation, NetView will:
1. Show welcome dialog
2. Start 7-day free trial
3. Appear in menu bar (top-right)
4. Begin monitoring network

### Menu Bar Widget
Click the menu bar icon to see:
- Current speeds (↓ download, ↑ upload)
- Total data transferred
- Quick actions:
  - **History** - View usage history
  - **Pay** - Activate license (after trial)

### Keyboard Shortcuts
- **Click icon** - Toggle popover
- **Option+Click** - Quick close

### History Window
View your complete network usage:
- **Today** - Current day statistics
- **This Month** - Monthly total
- **This Year** - Yearly total
- **Daily Records** - Complete history

**Cumulative Mode**: Click circles next to dates to see cumulative totals from that date.

### License Management
Free trial: 7 days
After trial:
- Click **Pay** button
- Copy Installation Key
- Send $9.99 payment
- Submit wallet address
- License activates within 24 hours

---

## Verification

### Check if Running
```bash
# Should see NetView in output
ps aux | grep NetView
```

### Check Menu Bar
Look for network stats in top-right corner:
```
↓ 5.2 MB/s  ↑ 1.3 MB/s
```

### Check History
```bash
# Should exist and contain data
cat ~/Library/Application\ Support/NetView/history.txt
```

### Check Auto-start
```bash
# Should show NetView
osascript -e 'tell application "System Events" to get the name of every login item'
```

---

## Customization

### Change Update Interval
Edit `DataManager.swift`:
```swift
// Line 45: Change from 1.0 to desired seconds
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)
```

### Change Colors
Edit `MonitorView.swift`:
```swift
// Line 89: Download color
.foregroundColor(.green)

// Line 107: Upload color
.foregroundColor(.red)
```

### Disable Auto-start
```bash
osascript -e 'tell application "System Events" to delete login item "NetView"'
```

---

## Troubleshooting

### App doesn't open
```bash
xattr -cr /Applications/NetView.app
open /Applications/NetView.app
```

### No menu bar icon
```bash
killall SystemUIServer
```

### Network not monitoring
1. Grant **Full Disk Access**:
   - System Settings > Privacy & Security > Full Disk Access
   - Add NetView.app

### History not saving
```bash
mkdir -p ~/Library/Application\ Support/NetView
chmod 755 ~/Library/Application\ Support/NetView
```

### Reset everything
```bash
# Delete app
rm -rf /Applications/NetView.app

# Delete preferences
defaults delete com.netview.NetView

# Delete history
rm -rf ~/Library/Application\ Support/NetView

# Reinstall
```

For more issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Development Workflow

### Typical Development Cycle
```bash
# 1. Edit code in Xcode
open NetView.xcodeproj

# 2. Build and test
cmd+B  # Build
cmd+R  # Run

# 3. Create DMG
./build-dmg.sh

# 4. Test DMG
open NetView-macOS.dmg

# 5. Commit changes
git add .
git commit -m "Add feature"
git push origin main
```

### Hot Reload (Swift)
SwiftUI supports hot reload:
1. Make code changes
2. Save file (Cmd+S)
3. Changes apply immediately in Preview

### Debugging
```bash
# Run with logs
/Applications/NetView.app/Contents/MacOS/NetView

# Monitor system logs
log stream --predicate 'process == "NetView"' --level debug
```

---

## File Locations

| Item | Location |
|------|----------|
| App Bundle | `/Applications/NetView.app` |
| History | `~/Library/Application Support/NetView/history.txt` |
| Preferences | `~/Library/Preferences/com.netview.NetView.plist` |
| Logs | `~/Library/Logs/NetView/` |
| Crash Reports | `~/Library/Logs/DiagnosticReports/NetView*` |

---

## Comparison: Windows vs macOS

| Feature | Windows | macOS |
|---------|---------|-------|
| Install | NetView-Setup.exe | NetView-macOS.dmg |
| Location | C:\Program Files\NetView | /Applications/NetView.app |
| UI | System tray | Menu bar |
| Data | %APPDATA%\NetView | ~/Library/Application Support/NetView |
| Settings | Registry | UserDefaults |
| Auto-start | Registry Run key | Login Items |

---

## Getting Help

### Documentation
- [README.md](README.md) - Overview
- [PORTING_GUIDE.md](PORTING_GUIDE.md) - Windows → macOS changes
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

### Community
- **Email**: support@netview.app
- **Twitter**: [@NetViewApp](https://twitter.com/NetViewApp)
- **GitHub**: [Issues](https://github.com/yourusername/NetView/issues)

### Logs to Include When Reporting Issues
```bash
# System info
sw_vers
uname -m
xcodebuild -version

# Recent logs
log show --predicate 'process == "NetView"' --last 5m > netview.log

# Crash report (if crashed)
ls -lt ~/Library/Logs/DiagnosticReports/NetView* | head -1
```

---

## Next Steps

1. ✅ Got NetView running
2. ⬜ Explore History window
3. ⬜ Set daily usage goal
4. ⬜ Share on Twitter
5. ⬜ Purchase license after trial
6. ⬜ Star on GitHub ⭐

---

**🎉 Congratulations!** NetView is now monitoring your network on macOS.

Questions? Read the [full README](README.md) or open an [issue](https://github.com/yourusername/NetView/issues).
