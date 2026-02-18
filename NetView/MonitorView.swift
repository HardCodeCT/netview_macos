//
//  MonitorView.swift
//  NetView for macOS
//
//  SwiftUI view for the monitor popover
//

import SwiftUI

struct MonitorView: View {
    @State private var dataIn: UInt64 = 0
    @State private var dataOut: UInt64 = 0
    @State private var rateIn: UInt64 = 0
    @State private var rateOut: UInt64 = 0
    @State private var isLicensed = false
    @State private var trialDaysRemaining = 0
    @State private var showHistoryWindow = false
    @State private var showPaymentWindow = false
    @State private var showContactCard = true  // Always true on startup
    @State private var hoveredSocialIcon: Int? = nil
    
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    // Social media links
    private let twitterURL = "https://x.com/Hard_Code_T"
    private let whatsappURL = "https://wa.me/2348165713623"
    private let gmailURL = "mailto:firmino3535@gmail.com?subject=Contact from NetView"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("NetView")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Close button
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.9))
            
            // Stats area
            VStack(spacing: 8) {
                // Download
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Download")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(formatBytes(dataIn))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(formatRate(rateIn))
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
                
                // Upload
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upload")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(formatBytes(dataOut))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(formatRate(rateOut))
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.8))
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
                    showHistoryWindow = true
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("History")
                            .font(.system(size: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(ActionButtonStyle(color: .purple))
                
                // Contact button
                Button(action: {
                    showContactCard.toggle()
                }) {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("Contact")
                            .font(.system(size: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(ActionButtonStyle(color: .blue))
                
                if !isLicensed {
                    Button(action: {
                        showPaymentWindow = true
                    }) {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                            Text("Pay")
                                .font(.system(size: 12))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(ActionButtonStyle(color: .orange))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            
            // Contact Card (shows below buttons)
            if showContactCard {
                VStack(spacing: 8) {
                    Text("Developer Contact")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 16) {
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
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 18/255, green: 18/255, blue: 18/255))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            
            // Trial warning
            if !isLicensed && trialDaysRemaining <= 7 {
                Text("Trial: \(trialDaysRemaining) days left")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                    .padding(.bottom, 4)
            }
        }
        .background(Color.black.opacity(0.95))
        .frame(width: 200)
        .onReceive(timer) { _ in
            updateData()
        }
        .onAppear {
            updateData()
        }
        .sheet(isPresented: $showHistoryWindow) {
            HistoryWindowView()
        }
        .sheet(isPresented: $showPaymentWindow) {
            PaymentWindowView()
        }
    }
    
    private func updateData() {
        let dataManager = DataManager.shared
        dataIn = dataManager.getDataIn()
        dataOut = dataManager.getDataOut()
        rateIn = dataManager.getRateIn()
        rateOut = dataManager.getRateOut()
        
        let licenseManager = LicenseManager.shared
        isLicensed = licenseManager.isLicensed()
        trialDaysRemaining = licenseManager.getTrialDaysRemaining()
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        return DataManager.shared.formatBytes(bytes)
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
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

// Social Icon Button Component
struct SocialIconButton: View {
    let imageName: String
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isHovered ? Color(white: 0.18) : Color(white: 0.12))
                    .frame(width: 40, height: 40)
                
                if let image = NSImage(named: imageName) {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else {
                    // Fallback SF Symbol icons if images not found
                    Image(systemName: fallbackIcon(for: imageName))
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                if isHovered {
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 42, height: 42)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .cursor(isHovered ? .pointingHand : .arrow)
    }
    
    private func fallbackIcon(for imageName: String) -> String {
        switch imageName {
        case "TwitterIcon": return "bird"
        case "WhatsAppIcon": return "message.fill"
        case "GmailIcon": return "envelope.fill"
        default: return "link"
        }
    }
}

struct ActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(configuration.isPressed ? 0.6 : 0.8))
            )
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    MonitorView()
}