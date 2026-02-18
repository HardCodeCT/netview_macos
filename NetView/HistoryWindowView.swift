//
//  HistoryWindowView.swift
//  NetView for macOS
//
//  Displays network usage history with social media contact icons
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
    @State private var hoveredSocialIcon: Int? = nil
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    // Social media links (same as Windows version)
    private let twitterURL = "https://x.com/Hard_Code_T"
    private let whatsappURL = "https://wa.me/2348165713623"
    private let gmailURL = "mailto:firmino3535@gmail.com?subject=Contact from NetView"
    
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
            
            Spacer()
            
            // Social Media Icons Footer (just like Windows version)
            HStack(spacing: 20) {
                Text("Developer Contact:")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Twitter
                SocialIconButton(
                    imageName: "TwitterIcon",
                    isHovered: hoveredSocialIcon == 0,
                    action: {
                        openURL(twitterURL)
                    }
                )
                .onHover { isHovered in
                    hoveredSocialIcon = isHovered ? 0 : nil
                }
                
                // WhatsApp
                SocialIconButton(
                    imageName: "WhatsAppIcon",
                    isHovered: hoveredSocialIcon == 1,
                    action: {
                        openURL(whatsappURL)
                    }
                )
                .onHover { isHovered in
                    hoveredSocialIcon = isHovered ? 1 : nil
                }
                
                // Gmail
                SocialIconButton(
                    imageName: "GmailIcon",
                    isHovered: hoveredSocialIcon == 2,
                    action: {
                        openURL(gmailURL)
                    }
                )
                .onHover { isHovered in
                    hoveredSocialIcon = isHovered ? 2 : nil
                }
            }
            .padding()
            .background(Color.black.opacity(0.8))
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
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
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