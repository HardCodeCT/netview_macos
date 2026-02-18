//
//  DataManager.swift
//  NetView for macOS
//
//  Monitors network traffic using SystemConfiguration framework
//

import Foundation
import SystemConfiguration

class DataManager {
    static let shared = DataManager()
    
    private var monitoring = false
    private var monitorTimer: Timer?
    
    // Cumulative counters
    private var totalDataIn: UInt64 = 0
    private var totalDataOut: UInt64 = 0
    
    // Rates (bytes per second)
    private var rateIn: UInt64 = 0
    private var rateOut: UInt64 = 0
    
    // For rate calculation
    private var prevDataIn: UInt64 = 0
    private var prevDataOut: UInt64 = 0
    
    // Baseline (starting point when monitoring began)
    private var baselineDataIn: UInt64 = 0
    private var baselineDataOut: UInt64 = 0
    
    // Smoothing to reduce jitter
    private var smoothedRateIn: Double = 0.0
    private var smoothedRateOut: Double = 0.0
    private let smoothingFactor: Double = 0.3
    
    // Selected network interface
    private var selectedInterface: String?
    
    private init() {}
    
    // MARK: - Public Interface
    
    func startMonitoring() -> Bool {
        guard !monitoring else { return true }
        
        // Auto-select best network interface
        selectedInterface = autoSelectAdapter()
        
        guard selectedInterface != nil else {
            print("[DataManager] No network interface available")
            return false
        }
        
        // Set initial baseline
        if let (inBytes, outBytes) = getCurrentInterfaceStats() {
            baselineDataIn = inBytes
            baselineDataOut = outBytes
            prevDataIn = 0
            prevDataOut = 0
            smoothedRateIn = 0.0
            smoothedRateOut = 0.0
        }
        
        monitoring = true
        
        // Start update timer (1 second interval)
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNetworkStats()
        }
        
        print("[DataManager] Monitoring started on interface: \(selectedInterface ?? "unknown")")
        return true
    }
    
    func stopMonitoring() {
        guard monitoring else { return }
        
        monitorTimer?.invalidate()
        monitorTimer = nil
        monitoring = false
        
        print("[DataManager] Monitoring stopped")
    }
    
    func isMonitoring() -> Bool {
        return monitoring
    }
    
    // Getters (thread-safe via main queue)
    func getDataIn() -> UInt64 {
        return totalDataIn
    }
    
    func getDataOut() -> UInt64 {
        return totalDataOut
    }
    
    func getRateIn() -> UInt64 {
        return rateIn
    }
    
    func getRateOut() -> UInt64 {
        return rateOut
    }
    
    func formatBytes(_ bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0
        
        while value >= 1024.0 && unitIndex < units.count - 1 {
            value /= 1024.0
            unitIndex += 1
        }
        
        if unitIndex == 0 {
            return "\(bytes) \(units[unitIndex])"
        } else {
            return String(format: "%.2f %@", value, units[unitIndex])
        }
    }
    
    // MARK: - Private Methods
    
    private func autoSelectAdapter() -> String? {
        let store = SCDynamicStoreCreate(nil, "NetView" as CFString, nil, nil)
        guard let storeRef = store else { return nil }
        
        // Priority 1: Active WiFi
        if let interface = findActiveInterface(ofType: "Airport", in: storeRef) {
            return interface
        }
        
        // Priority 2: Active Ethernet
        if let interface = findActiveInterface(ofType: "Ethernet", in: storeRef) {
            return interface
        }
        
        // Priority 3: Any active interface (excluding loopback)
        if let interface = findAnyActiveInterface(in: storeRef) {
            return interface
        }
        
        return nil
    }
    
    private func findActiveInterface(ofType type: String, in store: SCDynamicStore) -> String? {
        // Get list of network interfaces
        guard let interfaces = SCDynamicStoreCopyKeyList(store, "State:/Network/Interface/.*" as CFString) as? [String] else {
            return nil
        }
        
        for key in interfaces {
            if key.contains(type) {
                if let dict = SCDynamicStoreCopyValue(store, key as CFString) as? [String: Any] {
                    if let link = dict["Link"] as? [String: Any],
                       let active = link["Active"] as? Bool,
                       active {
                        // Extract interface name from key
                        let components = key.components(separatedBy: "/")
                        if components.count > 3 {
                            return components[3]
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func findAnyActiveInterface(in store: SCDynamicStore) -> String? {
        // Get primary interface
        if let globalIPv4 = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any],
           let primaryInterface = globalIPv4["PrimaryInterface"] as? String,
           primaryInterface != "lo0" { // Exclude loopback
            return primaryInterface
        }
        
        return nil
    }
    
    private func getCurrentInterfaceStats() -> (inBytes: UInt64, outBytes: UInt64)? {
        guard let interface = selectedInterface else { return nil }
        
        var ifaddrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrs) == 0 else { return nil }
        defer { freeifaddrs(ifaddrs) }
        
        var ptr = ifaddrs
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let addr = ptr?.pointee else { continue }
            let name = String(cString: addr.ifa_name)
            
            if name == interface {
                if addr.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                    // Cast to link layer data
                    let data = withUnsafePointer(to: &addr.ifa_data) { $0 }
                    if let ifData = data?.pointee?.assumingMemoryBound(to: if_data.self).pointee {
                        let inBytes = UInt64(ifData.ifi_ibytes)
                        let outBytes = UInt64(ifData.ifi_obytes)
                        return (inBytes, outBytes)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func updateNetworkStats() {
        guard let (currentIn, currentOut) = getCurrentInterfaceStats() else {
            // Interface disconnected - try to reconnect
            reconnectInterface()
            return
        }
        
        // Calculate usage since monitoring started
        let deltaSinceStart = currentIn >= baselineDataIn ? currentIn - baselineDataIn : 0
        let deltaOut = currentOut >= baselineDataOut ? currentOut - baselineDataOut : 0
        
        // Store totals
        totalDataIn = deltaSinceStart
        totalDataOut = deltaOut
        
        // Calculate delta (bytes transferred in last second)
        let rawDeltaIn = totalDataIn > prevDataIn ? totalDataIn - prevDataIn : 0
        let rawDeltaOut = totalDataOut > prevDataOut ? totalDataOut - prevDataOut : 0
        
        // Apply exponential smoothing
        smoothedRateIn = (smoothedRateIn * (1.0 - smoothingFactor)) + (Double(rawDeltaIn) * smoothingFactor)
        smoothedRateOut = (smoothedRateOut * (1.0 - smoothingFactor)) + (Double(rawDeltaOut) * smoothingFactor)
        
        // Clamp small values to zero (remove background noise)
        let noiseThreshold: UInt64 = 100 // bytes/sec
        rateIn = smoothedRateIn < Double(noiseThreshold) ? 0 : UInt64(smoothedRateIn)
        rateOut = smoothedRateOut < Double(noiseThreshold) ? 0 : UInt64(smoothedRateOut)
        
        // Update previous values
        prevDataIn = totalDataIn
        prevDataOut = totalDataOut
    }
    
    private func reconnectInterface() {
        print("[DataManager] Interface disconnect detected, attempting reconnect...")
        
        // Preserve accumulated data
        let preservedIn = totalDataIn
        let preservedOut = totalDataOut
        
        // Try to find new active interface
        let oldInterface = selectedInterface
        selectedInterface = autoSelectAdapter()
        
        if let newInterface = selectedInterface, newInterface != oldInterface {
            // Get new interface stats
            if let (newIn, newOut) = getCurrentInterfaceStats() {
                // Adjust baseline to preserve accumulated data
                if newIn >= preservedIn {
                    baselineDataIn = newIn - preservedIn
                } else {
                    baselineDataIn = 0
                    totalDataIn = preservedIn
                }
                
                if newOut >= preservedOut {
                    baselineDataOut = newOut - preservedOut
                } else {
                    baselineDataOut = 0
                    totalDataOut = preservedOut
                }
                
                // Reset rate tracking
                prevDataIn = preservedIn
                prevDataOut = preservedOut
                smoothedRateIn = 0.0
                smoothedRateOut = 0.0
                
                print("[DataManager] ✓ Reconnected to \(newInterface), continuing from \(preservedIn) in, \(preservedOut) out")
            }
        }
    }
}
