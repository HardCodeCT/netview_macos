//
//  AutoStartManager.swift
//  NetView for macOS
//
//  Manages auto-start on system boot using Login Items
//

import Foundation
import ServiceManagement
import AppKit

class AutoStartManager {
    static let shared = AutoStartManager()
    
    private init() {}
    
    func enableAutoStart() -> Bool {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                print("[AutoStartManager] Auto-start enabled (macOS 13+)")
                return true
            } catch {
                print("[AutoStartManager] Failed to enable auto-start: \(error.localizedDescription)")
                return false
            }
        } else {
            // For macOS 12, use simpler approach
            return enableAutoStartLegacy()
        }
    }
    
    func disableAutoStart() -> Bool {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                print("[AutoStartManager] Auto-start disabled (macOS 13+)")
                return true
            } catch {
                print("[AutoStartManager] Failed to disable auto-start: \(error.localizedDescription)")
                return false
            }
        } else {
            return disableAutoStartLegacy()
        }
    }
    
    func isEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return isEnabledLegacy()
        }
    }
    
    // MARK: - Legacy Methods (macOS 12 and earlier)
    
    private func enableAutoStartLegacy() -> Bool {
        let bundleURL = Bundle.main.bundleURL
        
        // Use osascript as a simpler approach for macOS 12
        let script = """
        tell application "System Events"
            make login item at end with properties {path:"\(bundleURL.path)", hidden:false}
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if error == nil {
                print("[AutoStartManager] Auto-start enabled (legacy)")
                return true
            }
        }
        
        print("[AutoStartManager] Failed to enable auto-start (legacy)")
        return false
    }
    
    private func disableAutoStartLegacy() -> Bool {
        let script = """
        tell application "System Events"
            delete login item "NetView"
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if error == nil {
                print("[AutoStartManager] Auto-start disabled (legacy)")
                return true
            }
        }
        
        return false
    }
    
    private func isEnabledLegacy() -> Bool {
        let script = """
        tell application "System Events"
            get the name of every login item
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let result = scriptObject.executeAndReturnError(&error)
            if error == nil {
                let loginItems = result.stringValue ?? ""
                return loginItems.contains("NetView")
            }
        }
        
        return false
    }
}