//
//  PaymentWindowView.swift
//  NetView for macOS
//
//  Payment and license activation window
//

import SwiftUI

struct PaymentWindowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var walletAddress = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let installationKey = LicenseManager.shared.getInstallationKey()
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Activate NetView License")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            // License info
            VStack(spacing: 12) {
                InfoRow(label: "Price", value: "$9.99 USD (One-time)")
                InfoRow(label: "Installation Key", value: installationKey)
                
                Text("Copy your installation key and send payment to:")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            
            // Payment instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Payment Instructions:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("1. Copy your Installation Key above")
                Text("2. Send $9.99 to our payment address")
                Text("3. Include your Installation Key in the payment note")
                Text("4. Enter the wallet address you paid from below")
                Text("5. Click Submit - we'll verify and activate your license")
            }
            .font(.system(size: 11))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            
            // Wallet address input
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Wallet Address:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                
                TextField("Enter wallet address you paid from", text: $walletAddress)
                    .textFieldStyle(CustomTextFieldStyle())
                    .disabled(isSubmitting)
            }
            
            // Buttons
            HStack(spacing: 12) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: {
                    submitPayment()
                }) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    } else {
                        Text("Submit Payment")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(walletAddress.isEmpty || isSubmitting)
            }
            
            // Copy key button
            Button(action: {
                copyToClipboard(installationKey)
            }) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Installation Key")
                        .font(.system(size: 12))
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(24)
        .frame(width: 500, height: 600)
        .background(Color.black.opacity(0.95))
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Payment submitted successfully! We'll verify and activate your license within 24 hours.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func submitPayment() {
        guard !walletAddress.isEmpty else { return }
        
        isSubmitting = true
        
        // Simulate payment submission (in real app, connect to Firebase)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSubmitting = false
            showSuccess = true
            
            // For demo purposes, activate immediately
            // In production, wait for server verification
            LicenseManager.shared.activateLicense()
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(configuration.isPressed ? 0.6 : 1.0))
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(configuration.isPressed ? 0.1 : 0.0))
                    )
            )
    }
}

#Preview {
    PaymentWindowView()
}
