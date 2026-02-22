//
//  PaymentWindowView.swift
//  NetView for macOS
//
//  Payment window with multiple cryptocurrency options (matches Windows version)
//

import SwiftUI

struct CryptoWallet {
    let name: String
    let symbol: String
    let minAmount: String
    let address: String
    let iconName: String  // Asset name
}

struct PaymentWindowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var walletAddress = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hoveredCopyButton: Int? = nil
    @State private var copiedWallet: Int? = nil
    
    private let installationKey = LicenseManager.shared.getInstallationKey()
    
    // Crypto wallets (same as Windows version)
    private let wallets: [CryptoWallet] = [
        CryptoWallet(
            name: "Bitcoin",
            symbol: "BTC",
            minAmount: "0.0006 BTC",
            address: "bc1qaqdwv7tzfr4m597pad4f894m69gf83dqze93ck",
            iconName: "BTCIcon"
        ),
        CryptoWallet(
            name: "Ethereum",
            symbol: "ETH",
            minAmount: "0.016 ETH",
            address: "0xF18022fE8D3a432464B7740392e16793C41AD746",
            iconName: "ETHIcon"
        ),
        CryptoWallet(
            name: "Tether",
            symbol: "USDT",
            minAmount: "40 USDT",
            address: "0xF18022fE8D3a432464B7740392e16793C41AD746",
            iconName: "USDTIcon"
        ),
        CryptoWallet(
            name: "Binance Coin",
            symbol: "BNB",
            minAmount: "0.06 BNB",
            address: "0xF18022fE8D3a432464B7740392e16793C41AD746",
            iconName: "BNBIcon"
        ),
        CryptoWallet(
            name: "Solana",
            symbol: "SOL",
            minAmount: "0.30 SOL",
            address: "CWnyw7pFhBFY8HYoo3sQx1gyGjbNLi28oq1UAqsabkDv",
            iconName: "SOLIcon"
        ),
        CryptoWallet(
            name: "Litecoin",
            symbol: "LTC",
            minAmount: "0.4 LTC",
            address: "ltc1qeuwatekvym4txerz5fa23lajw2y4t2ttx8zzj9",
            iconName: "LTCIcon"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("NetView - Payment ($9.99 Lifetime Access)")
                    .font(.system(size: 16, weight: .semibold))
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header instruction
                    Text("Send minimum $9.99 equivalent to any wallet below")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 176/255, green: 176/255, blue: 176/255))
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Wallet cards
                    ForEach(Array(wallets.enumerated()), id: \.offset) { index, wallet in
                        WalletCardView(
                            wallet: wallet,
                            isHovered: hoveredCopyButton == index,
                            isCopied: copiedWallet == index,
                            onCopy: {
                                copyToClipboard(wallet.address)
                                withAnimation {
                                    copiedWallet = index
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        copiedWallet = nil
                                    }
                                }
                            }
                        )
                        .onHover { isHovered in
                            hoveredCopyButton = isHovered ? index : nil
                        }
                    }
                    
                    // User wallet input section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enter Your Wallet Address")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Paste the wallet address you sent payment from")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255))
                        
                        TextEditor(text: $walletAddress)
                            .frame(height: 56)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 224/255, green: 224/255, blue: 224/255))
                            .scrollContentBackground(.hidden)
                            .background(Color(red: 18/255, green: 18/255, blue: 18/255))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(red: 50/255, green: 50/255, blue: 50/255), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Confirm button
                    Button(action: {
                        submitPayment()
                    }) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("CONFIRM PAYMENT")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 46/255, green: 46/255, blue: 46/255))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 62/255, green: 62/255, blue: 62/255), lineWidth: 1)
                            )
                    )
                    .disabled(walletAddress.isEmpty || isSubmitting)
                    .padding(.horizontal)
                    
                    // Footer text
                    Text("After payment, enter your wallet address and tap 'Confirm Payment'.\nVerification usually takes 1-24 hours.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
        }
        .background(Color.black.opacity(0.95))
        .frame(width: 500, height: 700)
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Payment submitted successfully!\n\nYour submission is being verified.\nThis usually takes 1-24 hours.\n\nThank you for supporting NetView!")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func submitPayment() {
        let trimmed = walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter your wallet address!"
            showError = true
            return
        }
        
        guard trimmed.count >= 20 else {
            errorMessage = "Invalid wallet address!"
            showError = true
            return
        }
        
        isSubmitting = true
        
        // Simulate submission (in production, connect to Firebase)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSubmitting = false
            showSuccess = true
            walletAddress = ""
            
            // For demo, activate immediately
            // In production, wait for server verification
            LicenseManager.shared.activateLicense()
        }
    }
}

// Wallet Card Component (matches Windows design)
struct WalletCardView: View {
    let wallet: CryptoWallet
    let isHovered: Bool
    let isCopied: Bool
    let onCopy: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Card content
            HStack(alignment: .top, spacing: 12) {
                // Coin icon
                if let image = NSImage(named: wallet.iconName) {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .cornerRadius(6)
                } else {
                    // Fallback icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 45/255, green: 45/255, blue: 45/255))
                            .frame(width: 30, height: 30)
                        Text(String(wallet.symbol.prefix(1)))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 180/255, green: 180/255, blue: 180/255))
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Name and symbol
                    Text("\(wallet.name)  (\(wallet.symbol))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Min amount
                    Text("Min: \(wallet.minAmount)  (~$9.99)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 176/255, green: 176/255, blue: 176/255))
                }
                
                Spacer()
            }
            .padding(.top, 11)
            .padding(.horizontal, 16)
            
            // Address box
            HStack {
                Text(wallet.address)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(red: 200/255, green: 200/255, blue: 200/255))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(height: 25)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .background(Color(red: 13/255, green: 13/255, blue: 13/255))
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // Copy button
            Button(action: onCopy) {
                HStack {
                    if isCopied {
                        Image(systemName: "checkmark")
                        Text("COPIED!")
                    } else {
                        Text("COPY \(wallet.symbol) ADDRESS")
                    }
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isCopied ? .green : Color(red: 100/255, green: 181/255, blue: 246/255))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered && !isCopied ? Color(red: 42/255, green: 42/255, blue: 42/255) : Color(red: 28/255, green: 28/255, blue: 28/255))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isHovered && !isCopied ?
                                    LinearGradient(
                                        colors: [
                                            Color(red: 190/255, green: 190/255, blue: 190/255, opacity: 0.5),
                                            Color(red: 200/255, green: 200/255, blue: 200/255, opacity: 0.16)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ) :
                                    LinearGradient(
                                        colors: [Color(red: 62/255, green: 62/255, blue: 62/255)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: isHovered && !isCopied ? 2 : 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 11)
            .cursor(isHovered ? .pointingHand : .arrow)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 26/255, green: 26/255, blue: 26/255))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 48/255, green: 48/255, blue: 48/255), lineWidth: 1)
                )
        )
        .padding(.horizontal)
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
    PaymentWindowView()
}
