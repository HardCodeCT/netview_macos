//
//  StatusBarController.swift
//  NetView for macOS
//
//  Menu bar widget that displays network statistics
//

import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var updateTimer: Timer?
    
    init() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create popover for detailed view
        popover = NSPopover()
        popover.contentSize = NSSize(width: 200, height: 140)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MonitorView())
        
        // Setup status bar button
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Start update timer
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateStatusBar()
        }
        
        // Initial update
        updateStatusBar()
    }
    
    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    private func updateStatusBar() {
        guard let button = statusItem.button else { return }
        
        let dataManager = DataManager.shared
        let rateIn = dataManager.getRateIn()
        let rateOut = dataManager.getRateOut()
        
        // Format rates for display
        let downText = formatRate(rateIn)
        let upText = formatRate(rateOut)
        
        // Create attributed string with arrows
        let text = NSMutableAttributedString()
        
        // Download (green)
        text.append(NSAttributedString(
            string: "↓ ",
            attributes: [.foregroundColor: NSColor.systemGreen]
        ))
        text.append(NSAttributedString(
            string: downText,
            attributes: [.foregroundColor: NSColor.white]
        ))
        
        text.append(NSAttributedString(string: "  "))
        
        // Upload (red)
        text.append(NSAttributedString(
            string: "↑ ",
            attributes: [.foregroundColor: NSColor.systemRed]
        ))
        text.append(NSAttributedString(
            string: upText,
            attributes: [.foregroundColor: NSColor.white]
        ))
        
        button.attributedTitle = text
        
        // Update popover content
        if let contentView = popover.contentViewController as? NSHostingController<MonitorView> {
            contentView.rootView = MonitorView()
        }
    }
    
    private func formatRate(_ bytesPerSecond: UInt64) -> String {
        if bytesPerSecond == 0 {
            return "0 B/s"
        }
        
        let units = ["B/s", "KB/s", "MB/s", "GB/s"]
        var value = Double(bytesPerSecond)
        var unitIndex = 0
        
        while value >= 1024.0 && unitIndex < units.count - 1 {
            value /= 1024.0
            unitIndex += 1
        }
        
        if unitIndex == 0 {
            return "\(bytesPerSecond) \(units[unitIndex])"
        } else {
            return String(format: "%.1f %@", value, units[unitIndex])
        }
    }
}
