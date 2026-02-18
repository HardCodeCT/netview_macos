//
//  HistoryManager.swift
//  NetView for macOS
//
//  Manages persistent network usage history
//

import Foundation

struct DailyUsage {
    let date: String
    let downloadBytes: UInt64
    let uploadBytes: UInt64
    var totalBytes: UInt64 {
        return downloadBytes + uploadBytes
    }
}

class HistoryManager {
    static let shared = HistoryManager()
    
    private var dailyHistory: [String: (download: UInt64, upload: UInt64)] = [:]
    private var todayDate: String
    private var todayDownload: UInt64 = 0
    private var todayUpload: UInt64 = 0
    private var lastSavedDownload: UInt64 = 0
    private var lastSavedUpload: UInt64 = 0
    private var sessionBaseDownload: UInt64 = 0
    private var sessionBaseUpload: UInt64 = 0
    private var lastSaveTime: Date = Date()
    
    private let saveIntervalSeconds: TimeInterval = 2.0
    
    private init() {
        todayDate = Self.getTodayDate()
        loadHistory()
    }
    
    // MARK: - Public Interface
    
    func updateTodayUsage(sessionDownload: UInt64, sessionUpload: UInt64) {
        // Check if date has changed (new day started)
        let currentDate = Self.getTodayDate()
        if currentDate != todayDate {
            // Save previous day's final data
            saveTodayUsageSafe()
            
            // Reset for new day
            todayDate = currentDate
            todayDownload = 0
            todayUpload = 0
            lastSavedDownload = 0
            lastSavedUpload = 0
            lastSaveTime = Date()
            sessionBaseDownload = 0
            sessionBaseUpload = 0
            
            print("[HistoryManager] New day started, reset counters")
        }
        
        // ADD session data to baseline (don't overwrite!)
        todayDownload = sessionBaseDownload + sessionDownload
        todayUpload = sessionBaseUpload + sessionUpload
        
        // Update in-memory map
        dailyHistory[todayDate] = (todayDownload, todayUpload)
        
        // Auto-save every 2 seconds if there's new data
        let totalChange = (todayDownload + todayUpload) - (lastSavedDownload + lastSavedUpload)
        let timeSinceLastSave = Date().timeIntervalSince(lastSaveTime)
        
        if totalChange > 0 && timeSinceLastSave >= saveIntervalSeconds {
            saveTodayUsageSafe()
        }
    }
    
    func saveTodayUsage() {
        saveTodayUsageSafe()
    }
    
    func getAllDailyRecords() -> [DailyUsage] {
        var result: [DailyUsage] = []
        
        for (date, data) in dailyHistory {
            result.append(DailyUsage(
                date: date,
                downloadBytes: data.download,
                uploadBytes: data.upload
            ))
        }
        
        // Sort by date descending (newest first)
        result.sort { $0.date > $1.date }
        
        return result
    }
    
    func getTodayTotal() -> UInt64 {
        return todayDownload + todayUpload
    }
    
    func getThisMonthTotal() -> UInt64 {
        let currentMonth = Self.getCurrentMonth()
        var total: UInt64 = 0
        
        for (date, data) in dailyHistory {
            if date.hasPrefix(currentMonth) {
                total += data.download + data.upload
            }
        }
        
        return total
    }
    
    func getThisYearTotal() -> UInt64 {
        let currentYear = Self.getCurrentYear()
        var total: UInt64 = 0
        
        for (date, data) in dailyHistory {
            if date.hasPrefix(currentYear) {
                total += data.download + data.upload
            }
        }
        
        return total
    }
    
    func getAllTimeTotal() -> UInt64 {
        var total: UInt64 = 0
        
        for (_, data) in dailyHistory {
            total += data.download + data.upload
        }
        
        return total
    }
    
    func getCumulativeTotalsFrom(fromDate: String) -> (download: UInt64, upload: UInt64) {
        var totalDownload: UInt64 = 0
        var totalUpload: UInt64 = 0
        
        for (date, data) in dailyHistory {
            if date >= fromDate {
                totalDownload += data.download
                totalUpload += data.upload
            }
        }
        
        return (totalDownload, totalUpload)
    }
    
    func getTodayDownload() -> UInt64 {
        return todayDownload
    }
    
    func getTodayUpload() -> UInt64 {
        return todayUpload
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
    
    private func loadHistory() {
        guard let filePath = getHistoryFilePath() else {
            print("[HistoryManager] Could not determine history file path")
            return
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        
        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
            print("[HistoryManager] No history file found at: \(filePath) (first run)")
            return
        }
        
        let lines = contents.components(separatedBy: .newlines)
        var lineCount = 0
        
        for line in lines {
            guard !line.isEmpty else { continue }
            
            let components = line.components(separatedBy: ",")
            guard components.count == 3 else { continue }
            
            let date = components[0]
            guard let download = UInt64(components[1]),
                  let upload = UInt64(components[2]) else { continue }
            
            dailyHistory[date] = (download, upload)
            
            // If this is today's data, restore it
            if date == todayDate {
                todayDownload = download
                todayUpload = upload
                lastSavedDownload = download
                lastSavedUpload = upload
                sessionBaseDownload = download
                sessionBaseUpload = upload
                
                print("[HistoryManager] Restored today's data: \(download) down, \(upload) up")
            }
            
            lineCount += 1
        }
        
        print("[HistoryManager] Loaded \(lineCount) records from file")
    }
    
    private func saveTodayUsageSafe() {
        // Only save if usage has changed
        guard todayDownload != lastSavedDownload || todayUpload != lastSavedUpload else {
            return
        }
        
        // Update in-memory map
        dailyHistory[todayDate] = (todayDownload, todayUpload)
        
        guard let filePath = getHistoryFilePath() else {
            print("[HistoryManager] ERROR: Could not determine history file path")
            return
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        let tempURL = URL(fileURLWithPath: filePath + ".tmp")
        
        // Build CSV content
        var csvContent = ""
        
        // Sort dates for consistent ordering
        let sortedDates = dailyHistory.keys.sorted()
        
        for date in sortedDates {
            if let data = dailyHistory[date] {
                csvContent += "\(date),\(data.download),\(data.upload)\n"
            }
        }
        
        do {
            // STEP 1: Write to temporary file
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // STEP 2: Replace old file with new file atomically
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL)
            
            // Update saved state
            lastSavedDownload = todayDownload
            lastSavedUpload = todayUpload
            lastSaveTime = Date()
            
            print("[HistoryManager] SAFE SAVE: \(dailyHistory.count) records to: \(filePath) (Today: \(todayDownload) down, \(todayUpload) up)")
        } catch {
            print("[HistoryManager] ERROR saving: \(error.localizedDescription)")
            
            // Clean up temp file if it exists
            try? FileManager.default.removeItem(at: tempURL)
        }
    }
    
    private func getHistoryFilePath() -> String? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let netViewDir = appSupport.appendingPathComponent("NetView")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: netViewDir, withIntermediateDirectories: true)
        
        return netViewDir.appendingPathComponent("history.txt").path
    }
    
    private static func getTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private static func getCurrentMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
    
    private static func getCurrentYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
}
