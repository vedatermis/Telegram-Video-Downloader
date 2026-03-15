//
//  TelegramServiceProtocol.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//
//  ⚠️ TELEGRAM HİZMET ŞARTLARI UYARISI:
//  Bu servisi kullanırken Telegram'ın Terms of Service'ine uygun davranın.
//  - Spam yapmayın
//  - Rate limit'lere dikkat edin
//  - Kısıtlanmış içeriklere erişmeye çalışmayın
//  - Bot detection'dan kaçınmak için makul gecikme ekleyin
//

import Foundation

/// Telegram API entegrasyonu için ana servis protokolü
/// TDLib veya MTProto implementasyonu bu protokolü uygulamalıdır
protocol TelegramServiceProtocol {
    
    // MARK: - Authentication
    
    /// Telegram'a bağlan ve session başlat
    /// - Parameters:
    ///   - apiId: Telegram API ID (my.telegram.org'dan)
    ///   - apiHash: Telegram API Hash
    /// - Returns: Bağlantı durumu
    func connect(apiId: String, apiHash: String) async throws -> Bool
    
    /// Doğrulama kodu gönder
    /// - Parameter phoneNumber: Kullanıcı telefon numarası (format: +905551234567)
    /// - Returns: Code hash (sonraki adımda kullanılacak)
    func sendCode(phoneNumber: String) async throws -> String
    
    /// Doğrulama kodunu verify et
    /// - Parameters:
    ///   - phoneNumber: Telefon numarası
    ///   - code: SMS ile gelen kod
    ///   - codeHash: sendCode'dan dönen hash
    /// - Returns: Authentication durumu (2FA gerekiyorsa false)
    func verifyCode(phoneNumber: String, code: String, codeHash: String) async throws -> AuthResult
    
    /// İki faktörlü authentication (2FA) şifresini verify et
    /// - Parameter password: Kullanıcı şifresi
    /// - Returns: Kullanıcı bilgisi
    func verifyPassword(password: String) async throws -> TelegramUser
    
    /// Çıkış yap ve session'ı kapat
    func logout() async throws
    
    // MARK: - Dialogs (Chats/Channels)
    
    /// Kullanıcının tüm sohbetlerini getir
    /// - Parameters:
    ///   - limit: Maksimum sohbet sayısı
    ///   - offsetId: Pagination için offset
    /// - Returns: Sohbet listesi
    func fetchDialogs(limit: Int, offsetId: Int?) async throws -> [TelegramDialog]
    
    /// Belirli bir sohbetin detaylarını getir
    /// - Parameter dialogId: Sohbet ID'si
    /// - Returns: Sohbet detayı
    func getDialogInfo(dialogId: String) async throws -> TelegramDialog
    
    // MARK: - Messages & Media
    
    /// Sohbetteki mesajları getir (medya filtreli)
    /// - Parameters:
    ///   - dialogId: Sohbet ID'si
    ///   - filter: Medya filtresi (video, photo, etc.)
    ///   - limit: Maksimum mesaj sayısı
    ///   - offsetId: Pagination için offset
    /// - Returns: Mesaj listesi
    func fetchMediaMessages(
        dialogId: String,
        filter: AppMediaFilter,
        limit: Int,
        offsetId: Int?
    ) async throws -> [TelegramMessage]
    
    /// Mesajın detaylı bilgisini getir
    /// - Parameters:
    ///   - dialogId: Sohbet ID'si
    ///   - messageId: Mesaj ID'si
    /// - Returns: Mesaj detayı
    func getMessage(dialogId: String, messageId: String) async throws -> TelegramMessage
    
    // MARK: - File Download
    
    /// Medya dosyasını indir
    /// - Parameters:
    ///   - remoteFileId: Telegram'daki remote file ID
    ///   - destinationURL: Hedef dosya URL'i
    ///   - progressHandler: İndirme ilerlemesi callback'i
    /// - Returns: İndirilen dosyanın local URL'i
    func downloadMedia(
        remoteFileId: String,
        destinationURL: URL,
        progressHandler: @escaping (Double, Int64) -> Void
    ) async throws -> URL
    
    /// İndirmeyi iptal et
    /// - Parameter remoteFileId: İptal edilecek dosyanın ID'si
    func cancelDownload(remoteFileId: String) async throws
    
    /// İndirmeyi duraklat
    /// - Parameter remoteFileId: Duraklatılacak dosyanın ID'si
    func pauseDownload(remoteFileId: String) async throws
    
    /// İndirmeye devam et
    /// - Parameter remoteFileId: Devam edilecek dosyanın ID'si
    func resumeDownload(remoteFileId: String) async throws
    
    // MARK: - User Info
    
    /// Mevcut kullanıcı bilgisini getir
    /// - Returns: Kullanıcı bilgisi
    func getCurrentUser() async throws -> TelegramUser
}

// MARK: - Enums

/// Authentication sonucu
enum AuthResult {
    case success(TelegramUser)
    case needPassword // 2FA gerekli
}

/// Medya filtreleme seçenekleri
enum AppMediaFilter {
    case all, photo, video, document
}

// MARK: - Usage Note

/*
 Bu protokolü implement etmek için seçenekler:
 
 1. TDLib (Telegram Database Library) - ÖNERİLEN
    - Telegram'ın resmi C++ kütüphanesi
    - Swift bridge gerektirir
    - En stabil ve feature-complete çözüm
    - Kurulum: https://github.com/tdlib/td
 
 2. MTProto Direct Implementation
    - Düşük seviye protokol implementasyonu
    - Daha fazla kontrol ama daha karmaşık
    - Encryption ve serialization kendiniz handle etmelisiniz
 
 3. Third-party Swift Libraries
    - SwiftTelegramApi gibi kütüphaneler
    - Henüz mature değil, production'da dikkatli kullanın
 
 ⚠️ ÖNEMLİ: Her implementasyonda Telegram'ın flood wait'lerine dikkat edin!
 Rate limit aşılırsa hesabınız geçici olarak kısıtlanabilir.
 */
