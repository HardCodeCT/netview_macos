//
//  LicenseManager.swift
//  NetView for macOS
//
//  Manages trial period and license activation
//

import Foundation

class LicenseManager {
    static let shared = LicenseManager()
    
    private let defaults = UserDefaults.standard
    private let installationKey: String
    
    private init() {
        // Get or generate installation key
        if let existingKey = defaults.string(forKey: "InstallationKey") {
            installationKey = existingKey
        } else {
            installationKey = Self.generateInstallationKey()
            defaults.set(installationKey, forKey: "InstallationKey")
        }
    }
    
    // MARK: - Public Interface
    
    func getInstallationKey() -> String {
        return installationKey
    }
    
    func startTrial() {
        // Only set install date if it doesn't exist
        guard defaults.object(forKey: "InstallDate") == nil else {
            return
        }
        
        let now = Date()
        defaults.set(now, forKey: "InstallDate")
        print("[LicenseManager] Trial started: \(now)")
    }
    
    func isTrialActive() -> Bool {
        if isLicensed() {
            return true // Licensed users have unlimited access
        }
        
        guard let installDate = defaults.object(forKey: "InstallDate") as? Date else {
            return false
        }
        
        let daysUsed = calculateDaysSince(installDate)
        return daysUsed < 7
    }
    
    func getTrialDaysUsed() -> Int {
        if isLicensed() {
            return 0
        }
        
        guard let installDate = defaults.object(forKey: "InstallDate") as? Date else {
            return 0
        }
        
        let days = calculateDaysSince(installDate)
        return min(days, 7)
    }
    
    func getTrialDaysRemaining() -> Int {
        if isLicensed() {
            return 999 // Unlimited for licensed users
        }
        
        let daysUsed = getTrialDaysUsed()
        let remaining = 7 - daysUsed
        return max(remaining, 0)
    }
    
    func isLicensed() -> Bool {
        return defaults.bool(forKey: "Licensed")
    }
    
    func activateLicense() {
        defaults.set(true, forKey: "Licensed")
        print("[LicenseManager] License activated")
    }
    
    // MARK: - Private Methods
    
    private func calculateDaysSince(_ past: Date) -> Int {
        let now = Date()
        
        // Validate past date is not in the future
        guard past <= now else {
            return 0
        }
        
        let components = Calendar.current.dateComponents([.day], from: past, to: now)
        return components.day ?? 0
    }
    
    private static func generateInstallationKey() -> String {
        let characters = "0123456789ABCDEF"
        var key = ""
        
        for i in 0..<32 {
            if i > 0 && i % 8 == 0 {
                key += "-"
            }
            let randomIndex = Int.random(in: 0..<characters.count)
            let char = characters[characters.index(characters.startIndex, offsetBy: randomIndex)]
            key.append(char)
        }
        
        return key
    }
}
