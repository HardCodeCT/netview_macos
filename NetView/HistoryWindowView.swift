//
//  HistoryWindowView.swift
//  NetView for macOS
//
//  Displays network usage history
//

import SwiftUI

struct HistoryWindowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dailyRecords: [DailyUsage] = []
    @State private var todayTotal: UInt64 = 0
    @State private var monthTotal: UInt64 = 0
    @State private var yearTotal: UInt64 = 0
    @State private var selectedDate: String?
    @State private var isCumulativeMode = false
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Network Usage History")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.black.opacity(0.9))
            
            // Summary cards
            HStack(spacing: 12) {
                SummaryCard(title: "Today", value: formatBytes(todayTotal), color: .blue)
                SummaryCard(title: "This Month", value: formatBytes(monthTotal), color: .green)
                SummaryCard(title: "This Year", value: formatBytes(yearTotal), color: .purple)
            }
            .padding()
            
            // History table
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Date")
                            .frame(width: 100, alignment: .leading)
                        Text("Download")
                            .frame(width: 120, alignment: .leading)
                        Text("Upload")
                            .frame(width: 120, alignment: .leading)
                        Text("Total")
                            .frame(width: 120, alignment: .leading)
                        Spacer()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    
                    // Records
                    ForEach(dailyRecords, id: \.date) { record in
                        HStack {
                            Text(record.date)
                                .frame(width: 100, alignment: .leading)
                            Text(formatBytes(record.downloadBytes))
                                .frame(width: 120, alignment: .leading)
                            Text(formatBytes(record.uploadBytes))
                                .frame(width: 120, alignment: .leading)
                            Text(formatBytes(record.totalBytes))
                                .frame(width: 120, alignment: .leading)
                            
                            Spacer()
                            
                            // Cumulative toggle button
                            Button(action: {
                                toggleCumulative(date: record.date)
                            }) {
                                Image(systemName: selectedDate == record.date ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedDate == record.date ? .green : .gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(
                            Color.white.opacity(record.date == selectedDate ? 0.1 : 0.0)
                        )
                    }
                }
            }
        }
        .background(Color.black.opacity(0.95))
        .frame(width: 700, height: 600)
        .onAppear {
            loadData()
        }
        .onReceive(timer) { _ in
            loadData()
        }
    }
    
    private func loadData() {
        let historyManager = HistoryManager.shared
        dailyRecords = historyManager.getAllDailyRecords()
        todayTotal = historyManager.getTodayTotal()
        monthTotal = historyManager.getThisMonthTotal()
        yearTotal = historyManager.getThisYearTotal()
    }
    
    private func toggleCumulative(date: String) {
        if selectedDate == date {
            // Disable cumulative mode
            selectedDate = nil
            isCumulativeMode = false
        } else {
            // Enable cumulative mode from this date
            selectedDate = date
            isCumulativeMode = true
            
            // Calculate cumulative totals
            let (download, upload) = HistoryManager.shared.getCumulativeTotalsFrom(fromDate: date)
            print("Cumulative from \(date): \(formatBytes(download)) down, \(formatBytes(upload)) up")
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        return HistoryManager.shared.formatBytes(bytes)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

#Preview {
    HistoryWindowView()
}
