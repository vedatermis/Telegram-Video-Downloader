//
//  AuthViewModel.swift
//  TeleGrab
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import Foundation
import Combine

/// Authentication view model
/// Kullanıcı login akışını yönetir
@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentStep: AuthStep = .apiCredentials
    @Published var apiId: String = ""
    @Published var apiHash: String = ""
    @Published var phoneNumber: String = ""
    @Published var verificationCode: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // Private state
    private var codeHash: String = ""
    
    // MARK: - Auth Steps
    
    enum AuthStep: Int, CaseIterable {
        case apiCredentials = 0
        case phoneNumber = 1
        case verificationCode = 2
        case twoFactorAuth = 3
        
        var actionTitleKey: String {
            switch self {
            case .apiCredentials: return "auth.continue"
            case .phoneNumber: return "auth.send_code"
            case .verificationCode: return "auth.verify"
            case .twoFactorAuth: return "auth.login"
            }
        }
        
        var actionTitle: String {
            // Deprecated, use actionTitleKey
            switch self {
            case .apiCredentials: return "Devam"
            case .phoneNumber: return "Kod Gönder"
            case .verificationCode: return "Doğrula"
            case .twoFactorAuth: return "Giriş Yap"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var canGoBack: Bool {
        currentStep.rawValue > 0
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .apiCredentials:
            return !apiId.isEmpty && !apiHash.isEmpty
        case .phoneNumber:
            return !phoneNumber.isEmpty && phoneNumber.hasPrefix("+")
        case .verificationCode:
            return verificationCode.count >= 5
        case .twoFactorAuth:
            return !password.isEmpty
        }
    }
    
    // MARK: - Initialization
    
    init() {
        loadSavedCredentials()
    }
    
    // MARK: - Public Methods
    
    /// Geri git
    func goBack() {
        guard canGoBack else { return }
        currentStep = AuthStep(rawValue: currentStep.rawValue - 1) ?? .apiCredentials
    }
    
    /// İlerle
    func proceed(appState: AppState) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            switch currentStep {
            case .apiCredentials:
                let isLoggedIn = try await validateAndSaveAPICredentials()
                if isLoggedIn {
                    let user = try await TelegramService.shared.getCurrentUser()
                    appState.didAuthenticate(user: user)
                } else {
                    currentStep = .phoneNumber
                }
                
            case .phoneNumber:
                try await sendVerificationCode()
                currentStep = .verificationCode
                
            case .verificationCode:
                try await verifyCode(appState: appState)
                
            case .twoFactorAuth:
                try await verifyPassword(appState: appState)
            }
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    /// Kodu tekrar gönder
    func resendCode() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await sendVerificationCode()
                // Başarılı mesajı göster
            } catch {
                showError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Kaydedilmiş credentials'ı yükle
    private func loadSavedCredentials() {
        if let savedApiId = KeychainHelper.shared.getApiId() {
            apiId = savedApiId
        }
        if let savedApiHash = KeychainHelper.shared.getApiHash() {
            apiHash = savedApiHash
        }
        if let savedPhoneNumber = KeychainHelper.shared.getPhoneNumber() {
            phoneNumber = savedPhoneNumber
        }
    }
    
    /// API credentials'ı doğrula ve kaydet
    private func validateAndSaveAPICredentials() async throws -> Bool {
        // API ID numeric olmalı
        guard apiId.allSatisfy({ $0.isNumber }) else {
            throw AuthError.invalidAPIId
        }
        
        // API Hash hex string olmalı (32 karakter)
        guard apiHash.count == 32 else {
            throw AuthError.invalidAPIHash
        }
        
        // Keychain'e kaydet
        try KeychainHelper.shared.saveApiId(apiId)
        try KeychainHelper.shared.saveApiHash(apiHash)
        
        // TelegramService'e connect
        return try await TelegramService.shared.connect(apiId: apiId, apiHash: apiHash)
    }
    
    /// Doğrulama kodu gönder
    private func sendVerificationCode() async throws {
        // Telefon numarasını formatla ve validate et
        let cleanPhone = phoneNumber.replacingOccurrences(of: " ", with: "")
        guard cleanPhone.hasPrefix("+") && cleanPhone.count >= 10 else {
            throw AuthError.invalidPhoneNumber
        }
        
        // Keychain'e kaydet
        try KeychainHelper.shared.savePhoneNumber(cleanPhone)
        
        // Telegram API ile kod gönder
        let hash = try await TelegramService.shared.sendCode(phoneNumber: cleanPhone)
        self.codeHash = hash
    }
    
    /// Kodu doğrula
    private func verifyCode(appState: AppState) async throws {
        guard !verificationCode.isEmpty else {
            throw AuthError.invalidVerificationCode
        }
        
        // Telefon numarasını al
        let cleanPhone = phoneNumber.replacingOccurrences(of: " ", with: "")
        
        // Telegram API ile kodu doğrula
        let result = try await TelegramService.shared.verifyCode(
            phoneNumber: cleanPhone,
            code: verificationCode,
            codeHash: codeHash
        )
        
        // Sonuca göre işlem yap
        switch result {
        case .success(let user):
            // Kullanıcı başarıyla giriş yaptı
            appState.didAuthenticate(user: user)
            
        case .needPassword:
            // 2FA gerekiyor
            currentStep = .twoFactorAuth
        }
    }
    
    /// Şifreyi doğrula (2FA)
    private func verifyPassword(appState: AppState) async throws {
        guard !password.isEmpty else {
            throw AuthError.invalidPassword
        }
        
        // Telegram API ile şifreyi doğrula (2FA)
        let user = try await TelegramService.shared.verifyPassword(password: password)
        
        // Kullanıcı başarıyla giriş yaptı
        appState.didAuthenticate(user: user)
    }
    
    /// Hata göster
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Auth Error

enum AuthError: Error, LocalizedError {
    case invalidAPIId
    case invalidAPIHash
    case invalidPhoneNumber
    case invalidVerificationCode
    case invalidPassword
    case networkError
    case telegramError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIId:
            return "Geçersiz API ID. Sadece sayı içermelidir."
        case .invalidAPIHash:
            return "Geçersiz API Hash. 32 karakterlik hex string olmalıdır."
        case .invalidPhoneNumber:
            return "Geçersiz telefon numarası. Format: +905551234567"
        case .invalidVerificationCode:
            return "Geçersiz doğrulama kodu."
        case .invalidPassword:
            return "Şifre boş olamaz."
        case .networkError:
            return "Bağlantı hatası. İnternet bağlantınızı kontrol edin."
        case .telegramError(let message):
            return "Telegram hatası: \(message)"
        }
    }
}
