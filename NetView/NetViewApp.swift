//
//  NetViewApp.swift
//  NetView for macOS
//
//  Main application entry point
//

import SwiftUI
import AppKit

@main
struct NetViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var dataManager: DataManager?
    var historyManager: HistoryManager?
    var licenseManager: LicenseManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - we're a menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize managers
        licenseManager = LicenseManager.shared
        historyManager = HistoryManager.shared
        dataManager = DataManager.shared
        
        // Check if this is first run
        let isFirstRun = !UserDefaults.standard.bool(forKey: "FirstRunComplete")
        
        if isFirstRun {
            setupFirstRun()
        }
        
        // Check license/trial status
        let isLicensed = licenseManager?.isLicensed() ?? false
        let isTrialActive = licenseManager?.isTrialActive() ?? false
        
        // Check if launched via auto-start
        let isAutoStart = CommandLine.arguments.contains("--autostart")
        
        if !isLicensed && !isTrialActive {
            if isAutoStart {
                // Auto-started with expired trial - exit silently
                NSApp.terminate(nil)
                return
            } else {
                showTrialExpiredDialog()
            }
        }
        
        // Start network monitoring
        dataManager?.startMonitoring()
        
        // Create status bar controller (menu bar widget)
        statusBarController = StatusBarController()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Save history before exit
        historyManager?.saveTodayUsage()
        dataManager?.stopMonitoring()
    }
    
    private func setupFirstRun() {
        // Configure auto-start
        AutoStartManager.shared.enableAutoStart()
        
        // Start trial
        licenseManager?.startTrial()
        
        // Show welcome dialog
        let alert = NSAlert()
        alert.messageText = "Welcome to NetView!"
        alert.informativeText = """
        You have a 7-day FREE trial to explore all features.
        
        NetView monitors your network activity and displays:
        • Real-time download/upload statistics
        • Daily, monthly, and yearly usage
        • Persistent history tracking
        
        After 7 days, purchase lifetime access for just $9.99!
        
        NetView will start automatically on system boot.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Get Started")
        alert.runModal()
        
        // Mark first run complete
        UserDefaults.standard.set(true, forKey: "FirstRunComplete")
    }
    
    private func showTrialExpiredDialog() {
        let alert = NSAlert()
        alert.messageText = "NetView - Trial Expired"
        alert.informativeText = """
        Your 7-day trial has expired!
        
        To continue using NetView, please purchase a lifetime license for $9.99.
        
        Click 'View Payment Options' to continue, or 'Quit' to exit.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "View Payment Options")
        alert.addButton(withTitle: "Quit")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            NSApp.terminate(nil)
        }
    }
}
