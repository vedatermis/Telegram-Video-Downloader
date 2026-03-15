//
//  StorageServiceProtocol.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import Foundation

/// Local storage yönetimi için servis protokolü
/// İndirilen dosyaların organize edilmesi ve metadata yönetimi
protocol StorageServiceProtocol {
    
    // MARK: - File Management
    
    /// İndirme klasörünü hazırla
    /// - Parameter path: Klasör yolu
    /// - Returns: Oluşturulan klasörün URL'i
    func prepareDownloadDirectory(at path: String) throws -> URL
    
    /// Dosya için benzersiz isim oluştur
    /// - Parameters:
    ///   - mediaItem: Medya item bilgisi
    ///   - dialogTitle: Sohbet/Kanal adı
    ///   - messageId: Mesaj ID
    /// - Returns: Sanitize edilmiş, benzersiz dosya adı
    func generateUniqueFileName(
        for mediaItem: MediaItem,
        dialogTitle: String,
        messageId: String
    ) -> String
    
    /// Dosya zaten indirilmiş mi kontrol et
    /// - Parameters:
    ///   - fileName: Dosya adı
    ///   - directory: Klasör URL'i
    /// - Returns: Dosya mevcutsa true
    func fileExists(fileName: String, in directory: URL) -> Bool
    
    /// İndirilen dosyayı taşı
    /// - Parameters:
    ///   - sourceURL: Kaynak dosya URL'i
    ///   - destinationURL: Hedef dosya URL'i
    /// - Returns: Taşınan dosyanın URL'i
    func moveFile(from sourceURL: URL, to destinationURL: URL) throws -> URL
    
    /// Dosyayı sil
    /// - Parameter url: Silinecek dosyanın URL'i
    func deleteFile(at url: URL) throws
    
    // MARK: - Metadata Management
    
    /// İndirme metadata'sını kaydet
    /// - Parameters:
    ///   - metadata: Metadata bilgisi
    ///   - fileURL: Dosya URL'i
    func saveMetadata(_ metadata: DownloadMetadata, for fileURL: URL) throws
    
    /// Dosyanın metadata'sını oku
    /// - Parameter fileURL: Dosya URL'i
    /// - Returns: Metadata bilgisi
    func getMetadata(for fileURL: URL) throws -> DownloadMetadata?
    
    /// Tüm indirilen dosyaların metadata'sını getir
    /// - Returns: Metadata listesi
    func getAllMetadata() throws -> [DownloadMetadata]
    
    // MARK: - Disk Space
    
    /// Boş disk alanını kontrol et
    /// - Parameter requiredSpace: Gerekli alan (bytes)
    /// - Returns: Yeterli alan varsa true
    func hasEnoughSpace(requiredSpace: Int64) -> Bool
    
    /// Kullanılabilir disk alanını getir
    /// - Returns: Boş alan (bytes)
    func getAvailableDiskSpace() -> Int64?
    
    // MARK: - File Organization
    
    /// Dosyaları tarih bazlı organize et
    /// - Parameter directoryURL: Ana klasör URL'i
    func organizeFilesByDate(in directoryURL: URL) throws
    
    /// Dosyaları kanal bazlı organize et
    /// - Parameter directoryURL: Ana klasör URL'i
    func organizeFilesByChannel(in directoryURL: URL) throws
}

// MARK: - Download Metadata

/// İndirilen dosyanın metadata'sı
struct DownloadMetadata: Codable {
    let fileURL: URL
    let originalFileName: String
    let dialogId: String
    let dialogTitle: String
    let messageId: String
    let downloadDate: Date
    let fileSize: Int64
    let mimeType: String?
    let duration: TimeInterval?
    let resolution: String?
    
    /// Metadata dosya adı
    var metadataFileName: String {
        "\(messageId)_metadata.json"
    }
}

// MARK: - Storage Service Error

enum StorageServiceError: Error, LocalizedError {
    case directoryCreationFailed
    case fileNotFound
    case fileAlreadyExists
    case insufficientPermissions
    case insufficientSpace
    case metadataCorrupted
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed:
            return "Klasör oluşturulamadı."
        case .fileNotFound:
            return "Dosya bulunamadı."
        case .fileAlreadyExists:
            return "Dosya zaten mevcut."
        case .insufficientPermissions:
            return "Yeterli izin yok."
        case .insufficientSpace:
            return "Disk alanı yetersiz."
        case .metadataCorrupted:
            return "Metadata dosyası bozuk."
        case .unknownError(let message):
            return "Bilinmeyen hata: \(message)"
        }
    }
}

// MARK: - Implementation Note

/*
 Bu servisin implementasyonunda dikkat edilmesi gerekenler:
 
 1. File Naming Strategy
    - Format: <channelName>_<messageId>_<originalName>.<ext>
    - Special character sanitization: [^a-zA-Z0-9_-] -> _
    - Maximum length: 255 characters (macOS limit)
    - Collision handling: append _1, _2, etc.
 
 2. Directory Structure Options
    
    Option A: Flat structure
    ~/Downloads/TG Media Backup/
        channel1_msg1_video.mp4
        channel1_msg2_video.mp4
    
    Option B: Channel-based
    ~/Downloads/TG Media Backup/
        Channel1/
            msg1_video.mp4
            msg2_video.mp4
        Channel2/
            msg1_video.mp4
    
    Option C: Date-based
    ~/Downloads/TG Media Backup/
        2025-10-30/
            video1.mp4
            video2.mp4
        2025-10-31/
            video3.mp4
 
 3. Metadata Storage
    - JSON format
    - Same directory as downloaded file
    - Naming: <originalName>_metadata.json
    - Enables search and filtering later
 
 4. Disk Space Checks
    - Check before starting download
    - Reserve extra space (10% buffer)
    - Alert user if space is low
 
 5. File Attributes
    - Set creation/modification dates
    - Preserve Telegram metadata in extended attributes
    - macOS Spotlight indexing support
 
 ⚠️ macOS Sandbox Considerations:
 - User must explicitly choose download directory
 - Use security-scoped bookmarks for persistence
 - Request necessary entitlements in .entitlements file
 */
