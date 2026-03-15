//
//  AuthView.swift
//  TeleGrab
//
//  Created by Vedat ERMIS on 30.10.2025.
//
//  ⚠️ UYARI: Telegram API kullanmak için my.telegram.org'dan API ID ve Hash almanız gerekir.
//

import SwiftUI

/// Authentication ekranı
/// Kullanıcıdan API credentials ve telefon numarası alır
struct AuthView: View {
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var showAPIGuide = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                Spacer()
                
                // Auth card
                authCardView
                    .frame(maxWidth: 500)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Footer
                footerView
            }
        }
        .sheet(isPresented: $showAPIGuide) {
            APISetupGuideView()
        }
        .alert("common.error", isPresented: $viewModel.showError) {
            Button("common.ok", role: .cancel) {}
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("auth.title")
                .font(.system(size: 42, weight: .bold))
            
            Text("auth.subtitle")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Auth Card
    
    private var authCardView: some View {
        VStack(spacing: 24) {
            // Step indicator
            stepIndicator
            
            Divider()
            
            // Content based on step
            switch viewModel.currentStep {
            case .apiCredentials:
                apiCredentialsStep
            case .phoneNumber:
                phoneNumberStep
            case .verificationCode:
                verificationCodeStep
            case .twoFactorAuth:
                twoFactorAuthStep
            }
            
            Divider()
            
            // Actions
            actionButtons
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
    }
    
    // MARK: - Step Indicator
    
    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(AuthViewModel.AuthStep.allCases, id: \.self) { step in
                Circle()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }
    
    // MARK: - API Credentials Step
    
    private var apiCredentialsStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("auth.api_credentials")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("auth.api_credentials_desc")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                TextField("API ID", text: $viewModel.apiId)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                
                SecureField("API Hash", text: $viewModel.apiHash)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }
            
            Button(action: { showAPIGuide = true }) {
                Label("auth.how_to_get_api", systemImage: "questionmark.circle")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
    }
    
    // MARK: - Phone Number Step
    
    private var phoneNumberStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("auth.phone_number")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("auth.phone_number_desc")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            TextField("+90 555 123 45 67", text: $viewModel.phoneNumber)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .autocorrectionDisabled()
            
            Text("auth.example")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Verification Code Step
    
    private var verificationCodeStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("auth.verification_code")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("auth.verification_code_desc")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            TextField("12345", text: $viewModel.verificationCode)
                .textFieldStyle(.roundedBorder)
                .font(.system(.title3, design: .monospaced))
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
            
            Button("auth.resend_code") {
                viewModel.resendCode()
            }
            .buttonStyle(.plain)
            .font(.subheadline)
            .foregroundStyle(.blue)
        }
    }
    
    // MARK: - Two Factor Auth Step
    
    private var twoFactorAuthStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("auth.2fa")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("auth.2fa_desc")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            SecureField("auth.password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if viewModel.canGoBack {
                Button("auth.back") {
                    viewModel.goBack()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            Spacer()
            
            Button(LocalizedStringKey(viewModel.currentStep.actionTitleKey)) {
                Task {
                    await viewModel.proceed(appState: appState)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canProceed || viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .offset(x: 100)
                }
            }
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        VStack(spacing: 8) {
            Text("auth.footer_warning1")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("auth.footer_warning2")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
