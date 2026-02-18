//
//  AutoStartManager.swift
//  NetView for macOS
//
//  Manages auto-start on system boot using Login Items
//

import Foundation
import ServiceManagement

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
            // For macOS 12 and earlier, use legacy method
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
        guard let bundleURL = Bundle.main.bundleURL else { return false }
        
        let workspace = NSWorkspace.shared
        
        // Check if already in login items
        if isEnabledLegacy() {
            return true
        }
        
        // Add to login items using deprecated API (still works on macOS 12)
        // Note: This uses LSSharedFileList which is deprecated but functional
        // For production, consider using SMLoginItemSetEnabled
        
        let loginItems = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)
        if let loginItemsRef = loginItems?.takeRetainedValue() {
            LSSharedFileListInsertItemURL(
                loginItemsRef,
                kLSSharedFileListItemLast.takeRetainedValue(),
                nil,
                nil,
                bundleURL as CFURL,
                nil,
                nil
            )
            print("[AutoStartManager] Auto-start enabled (legacy)")
            return true
        }
        
        return false
    }
    
    private func disableAutoStartLegacy() -> Bool {
        guard let bundleURL = Bundle.main.bundleURL else { return false }
        
        let loginItems = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)
        if let loginItemsRef = loginItems?.takeRetainedValue() {
            let loginItemsArray = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as? [LSSharedFileListItem]
            
            if let items = loginItemsArray {
                for item in items {
                    if let itemURL = LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() as URL? {
                        if itemURL == bundleURL {
                            LSSharedFileListItemRemove(loginItemsRef, item)
                            print("[AutoStartManager] Auto-start disabled (legacy)")
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    private func isEnabledLegacy() -> Bool {
        guard let bundleURL = Bundle.main.bundleURL else { return false }
        
        let loginItems = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)
        if let loginItemsRef = loginItems?.takeRetainedValue() {
            let loginItemsArray = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as? [LSSharedFileListItem]
            
            if let items = loginItemsArray {
                for item in items {
                    if let itemURL = LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() as URL? {
                        if itemURL == bundleURL {
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
}
