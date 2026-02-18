# Troubleshooting Guide

Common issues and solutions when building and running NetView on macOS.

## Build Issues

### 1. "Xcode is not installed"

**Error:**
```
xcode-select: error: tool 'xcodebuild' requires Xcode
```

**Solution:**
```bash
# Install Xcode from App Store (free)
# Then install Command Line Tools:
xcode-select --install

# Verify installation:
xcodebuild -version
```

### 2. "No such module 'SwiftUI'"

**Error:**
```
error: no such module 'SwiftUI'
```

**Solution:**
- Ensure you're using Xcode 11+ and macOS 10.15+
- Update Xcode to latest version
- Set deployment target to macOS 12.0+:
```bash
# In Package.swift, verify:
platforms: [.macOS(.v12)]
```

### 3. Build fails with "SDK not found"

**Error:**
```
error: unable to find sdk 'macosx'
```

**Solution:**
```bash
# Reset Xcode CLI tools path:
sudo xcode-select --reset
sudo xcode-select --switch /Applications/Xcode.app

# Verify SDK:
xcrun --show-sdk-path
```

### 4. "create-dmg: command not found"

**Error:**
```
build-dmg.sh: line 45: create-dmg: command not found
```

**Solution:**
```bash
# Install Homebrew if not installed:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install create-dmg:
brew install create-dmg

# Verify:
which create-dmg
```

### 5. Permission denied when running scripts

**Error:**
```
bash: ./build-dmg.sh: Permission denied
```

**Solution:**
```bash
chmod +x build-dmg.sh
chmod +x build-spm.sh
./build-dmg.sh
```

### 6. Signing errors (optional)

**Error:**
```
error: No signing certificate "Mac Development" found
```

**Solution Option 1 (Don't sign - for personal use):**
```bash
xcodebuild \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO
```

**Solution Option 2 (Sign properly - for distribution):**
1. Get Apple Developer Account ($99/year)
2. Create Developer ID certificate in Keychain
3. Sign with your identity:
```bash
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name" \
    NetView.app
```

## Runtime Issues

### 7. "NetView is damaged and can't be opened"

**Problem:** macOS Gatekeeper blocking unsigned app

**Solution:**
```bash
# Remove quarantine attribute:
xattr -cr /Applications/NetView.app

# Or allow in System Settings:
# System Settings > Privacy & Security > Open Anyway
```

### 8. App crashes on launch

**Symptoms:** App quits immediately after opening

**Diagnostics:**
```bash
# Check crash logs:
log show --predicate 'process == "NetView"' --last 5m

# Run from Terminal to see errors:
/Applications/NetView.app/Contents/MacOS/NetView
```

**Common causes:**
- Missing entitlements
- Sandbox restrictions
- Network permissions not granted

**Solution:**
```bash
# Rebuild with proper entitlements:
cd NetViewMac
./build-dmg.sh

# Grant network permissions:
# System Settings > Privacy & Security > Full Disk Access
# Add NetView.app
```

### 9. Network monitoring not working

**Symptoms:** Always shows "0 B/s"

**Diagnostics:**
```bash
# Test network interfaces manually:
ifconfig
netstat -ib

# Check if getifaddrs works:
# Should see multiple interfaces
```

**Solution:**
1. Grant Full Disk Access:
   - System Settings > Privacy & Security > Full Disk Access
   - Click '+' and add NetView.app
   
2. Check entitlements:
   - Ensure `com.apple.security.network.client` is enabled
   
3. Restart NetView after granting permissions

### 10. Auto-start not working

**Symptoms:** App doesn't launch on boot

**Diagnostics:**
```bash
# Check login items:
osascript -e 'tell application "System Events" to get the name of every login item'

# Should show "NetView" in the list
```

**Solution:**
```bash
# Manually add login item:
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/NetView.app", hidden:false}'

# Or use System Settings:
# System Settings > General > Login Items
# Click '+' and add NetView
```

### 11. History not saving

**Symptoms:** Usage resets to zero after restart

**Diagnostics:**
```bash
# Check if history file exists:
ls -la ~/Library/Application\ Support/NetView/

# Should see history.txt

# Check file permissions:
ls -l ~/Library/Application\ Support/NetView/history.txt
```

**Solution:**
```bash
# Create directory manually if missing:
mkdir -p ~/Library/Application\ Support/NetView

# Set proper permissions:
chmod 755 ~/Library/Application\ Support/NetView
chmod 644 ~/Library/Application\ Support/NetView/history.txt

# Check if app has file access:
# System Settings > Privacy & Security > Files and Folders
# Enable for NetView
```

### 12. Trial period not working

**Symptoms:** App says trial expired immediately

**Diagnostics:**
```bash
# Check UserDefaults:
defaults read com.netview.NetView

# Look for InstallDate and Licensed keys
```

**Solution:**
```bash
# Reset trial (for testing only):
defaults delete com.netview.NetView InstallDate
defaults delete com.netview.NetView FirstRunComplete

# Or delete all preferences:
defaults delete com.netview.NetView

# Restart NetView
```

### 13. Menu bar icon not appearing

**Symptoms:** NetView runs but no menu bar icon

**Solution:**
1. Check if app is set to "accessory":
   - Should have `LSUIElement = true` in Info.plist
   
2. Restart SystemUIServer:
```bash
killall SystemUIServer
```

3. If still not showing, manually show:
```bash
# Remove LSUIElement temporarily to see if app window shows
```

## GitHub Actions Issues

### 14. Build fails in GitHub Actions

**Error:**
```
Error: No Xcode versions found
```

**Solution:**
```yaml
# Add Xcode setup step:
- name: Setup Xcode
  uses: maxim-lobanov/setup-xcode@v1
  with:
    xcode-version: latest-stable
```

### 15. DMG creation fails in CI

**Error:**
```
create-dmg: command not found
```

**Solution:**
```yaml
# Add installation step:
- name: Install create-dmg
  run: brew install create-dmg
```

### 16. Release not created

**Error:**
```
Error: Not Found
```

**Solution:**
- Ensure you're pushing a tag: `git push origin v1.0.0`
- Check repository permissions in Settings > Actions
- Verify GITHUB_TOKEN has write permissions

## Apple Silicon Issues

### 17. "Bad CPU type in executable" on M1/M2

**Problem:** Built for Intel only

**Solution:**
```bash
# Build universal binary:
xcodebuild \
    -project NetView.xcodeproj \
    -scheme NetView \
    -configuration Release \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO

# Verify architectures:
lipo -info NetView.app/Contents/MacOS/NetView
# Should show: arm64 x86_64
```

### 18. Rosetta required warning

**Problem:** Intel-only build running on Apple Silicon

**Solution:**
- Rebuild as universal binary (see #17)
- Or inform users to install Rosetta:
```bash
softwareupdate --install-rosetta --agree-to-license
```

## Debugging Tips

### Enable verbose logging

```swift
// Add to NetViewApp.swift
print("[DEBUG] App launched")
print("[DEBUG] Network monitoring started: \(result)")
```

### Check system logs

```bash
# Real-time logs:
log stream --predicate 'process == "NetView"' --level debug

# Search recent logs:
log show --predicate 'process == "NetView"' --last 1h
```

### Use Instruments

```bash
# Profile CPU usage:
instruments -t "Time Profiler" -D /tmp/profile.trace NetView.app

# Profile memory:
instruments -t "Allocations" NetView.app
```

### Network debugging

```bash
# Monitor all network activity:
sudo tcpdump -i any -n

# Check specific interface:
netstat -I en0 -w 1
```

## Common Gotchas

1. **Sandboxing**: macOS sandboxes apps aggressively. May need to disable for development.

2. **Entitlements**: Missing entitlements = silent failures. Always check NetView.entitlements.

3. **Code signing**: Required for distribution. Can skip for personal use.

4. **Notarization**: Required if distributing outside App Store. Takes 10-60 minutes.

5. **Intel vs ARM**: Build universal or users need Rosetta.

6. **System Settings**: Many features require explicit permission grants.

## Getting Help

If none of the above solutions work:

1. **Check logs**:
```bash
log show --predicate 'process == "NetView"' --last 5m > netview.log
```

2. **File an issue**: Include:
   - macOS version (`sw_vers`)
   - Xcode version (`xcodebuild -version`)
   - Processor type (`uname -m`)
   - Full error message
   - Relevant logs

3. **Contact support**:
   - Email: support@netview.app
   - GitHub: [Open an Issue](https://github.com/yourusername/NetView/issues)

## Quick Fixes Checklist

Before filing an issue, try:

- [ ] Restart NetView
- [ ] Rebuild from scratch (`rm -rf build`)
- [ ] Update Xcode to latest version
- [ ] Grant all necessary permissions
- [ ] Remove quarantine (`xattr -cr NetView.app`)
- [ ] Check Console.app for crash logs
- [ ] Verify macOS version is 12.0+
- [ ] Test on different network (WiFi/Ethernet)
- [ ] Disable antivirus temporarily
- [ ] Reset UserDefaults (`defaults delete com.netview.NetView`)

## Useful Commands Reference

```bash
# Build
./build-dmg.sh

# Clean
rm -rf build .build dist *.dmg

# Run unsigned app
spctl --add /Applications/NetView.app

# Remove from quarantine
xattr -cr NetView.app

# View logs
log stream --predicate 'process == "NetView"'

# Check network interfaces
ifconfig

# Monitor network stats
nettop -x -L 1

# Grant permissions
sudo tccutil reset All com.netview.NetView

# List login items
osascript -e 'tell application "System Events" to get the name of every login item'
```
