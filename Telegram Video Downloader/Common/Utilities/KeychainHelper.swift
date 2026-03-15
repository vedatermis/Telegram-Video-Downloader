//
//  KeychainHelper.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//
//  ⚠️ UYARI: Hassas bilgiler (API keys, session tokens) Keychain'de güvenli şekilde saklanır.
//

import Foundation
import Security

/// Keychain yönetimi için helper sınıfı
/// Telegram API credentials ve session bilgilerini güvenli şekilde saklar
final class KeychainHelper {
    
    static let shared = KeychainHelper()
    
    private init() {}
    
    // MARK: - Keychain Keys
    
    private enum KeychainKey: String, CaseIterable {
        case apiId = "com.tgmediabackup.apiId"
        case apiHash = "com.tgmediabackup.apiHash"
        case sessionData = "com.tgmediabackup.sessionData"
        case phoneNumber = "com.tgmediabackup.phoneNumber"
    }
    
    // MARK: - Public Methods
    
    /// API ID'yi kaydet
    func saveApiId(_ apiId: String) throws {
        try save(apiId, for: .apiId)
    }
    
    /// API ID'yi oku
    func getApiId() -> String? {
        try? read(for: .apiId)
    }
    
    /// API Hash'i kaydet
    func saveApiHash(_ apiHash: String) throws {
        try save(apiHash, for: .apiHash)
    }
    
    /// API Hash'i oku
    func getApiHash() -> String? {
        try? read(for: .apiHash)
    }
    
    /// Session data'yı kaydet
    func saveSessionData(_ data: Data) throws {
        try saveData(data, for: .sessionData)
    }
    
    /// Session data'yı oku
    func getSessionData() -> Data? {
        try? readData(for: .sessionData)
    }
    
    /// Telefon numarasını kaydet
    func savePhoneNumber(_ phoneNumber: String) throws {
        try save(phoneNumber, for: .phoneNumber)
    }
    
    /// Telefon numarasını oku
    func getPhoneNumber() -> String? {
        try? read(for: .phoneNumber)
    }
    
    /// Geçerli session var mı kontrol et
    func hasValidSession() async -> Bool {
        // Session data varsa geçerli session var demektir
        return getSessionData() != nil
    }
    
    /// Tüm Telegram verilerini temizle
    func clearSession() async {
        try? delete(for: .sessionData)
        try? delete(for: .phoneNumber)
        // API credentials'ı silmiyoruz, kullanıcı tekrar giriş yaparken lazım olabilir
    }
    
    /// Tüm verileri temizle (logout + API credentials)
    func clearAll() {
        try? delete(for: .apiId)
        try? delete(for: .apiHash)
        try? delete(for: .sessionData)
        try? delete(for: .phoneNumber)
    }
    
    // MARK: - Generic Methods
    
    /// Generic data kaydet (herhangi bir key ile)
    func saveGenericData(_ data: Data, forKey key: String) throws {
        // Önce mevcut değeri sil
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Yeni değeri ekle
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveError(status)
        }
    }
    
    /// Generic data oku (herhangi bir key ile)
    func readGenericData(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.readError(status)
        }
        
        return result as? Data
    }
    
    // MARK: - Private Methods
    
    /// String değeri Keychain'e kaydet
    private func save(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingError
        }
        try saveData(data, for: key)
    }
    
    /// Data'yı Keychain'e kaydet
    private func saveData(_ data: Data, for key: KeychainKey) throws {
        // Önce mevcut değeri sil
        try? delete(for: key)
        
        // Yeni değeri ekle
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveError(status)
        }
    }
    
    /// String değeri Keychain'den oku
    private func read(for key: KeychainKey) throws -> String? {
        guard let data = try readData(for: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// Data'yı Keychain'den oku
    private func readData(for key: KeychainKey) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.readError(status)
        }
        
        return result as? Data
    }
    
    /// Keychain'den sil
    private func delete(for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteError(status)
        }
    }
}

// MARK: - Keychain Error
enum KeychainError: Error, LocalizedError {
    case encodingError
    case saveError(OSStatus)
    case readError(OSStatus)
    case deleteError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .encodingError:
            return "Veri kodlanamadı"
        case .saveError(let status):
            return "Keychain'e kaydedilemedi: \(status)"
        case .readError(let status): 
            return "Keychain'den okunamadı: \(status)"
        case .deleteError(let status):
            return "Keychain'den silinemedi: \(status)"
        }
    }
}
