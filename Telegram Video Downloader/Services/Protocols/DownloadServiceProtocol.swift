//
//  DownloadServiceProtocol.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import Foundation

/// İndirme yönetimi için servis protokolü
/// Çoklu indirme, kuyruk yönetimi, resume/pause özelliklerini sağlar
protocol DownloadServiceProtocol {
    
    // MARK: - Download Queue Management
    
    /// İndirme kuyruğuna item ekle
    /// - Parameter item: İndirilecek item
    func addToQueue(_ item: DownloadItem) async
    
    /// Kuyruktaki tüm indirmeleri başlat
    func startQueue() async
    
    /// Kuyruğu durdur
    func stopQueue() async
    
    /// Kuyruğu temizle
    func clearQueue() async
    
    // MARK: - Individual Download Control
    
    /// Tek bir dosyayı indir
    /// - Parameters:
    ///   - remoteFileId: Telegram file ID
    ///   - mediaItem: Medya item bilgisi
    ///   - destinationURL: Hedef dosya yolu
    ///   - progressHandler: İlerleme callback'i
    /// - Returns: İndirilen dosyanın URL'i
    func downloadFile(
        remoteFileId: String,
        mediaItem: MediaItem,
        destinationURL: URL,
        progressHandler: @escaping (DownloadProgress) -> Void
    ) async throws -> URL
    
    /// İndirmeyi duraklat
    /// - Parameter itemId: Download item ID
    func pauseDownload(itemId: String) async throws
    
    /// İndirmeye devam et
    /// - Parameter itemId: Download item ID
    func resumeDownload(itemId: String) async throws
    
    /// İndirmeyi iptal et
    /// - Parameter itemId: Download item ID
    func cancelDownload(itemId: String) async throws
    
    /// İndirmeyi tekrar dene
    /// - Parameter itemId: Download item ID
    func retryDownload(itemId: String) async throws
    
    // MARK: - Chunk Download (Büyük Dosyalar İçin)
    
    /// Dosyayı parçalı olarak indir
    /// - Parameters:
    ///   - remoteFileId: Telegram file ID
    ///   - destinationURL: Hedef dosya yolu
    ///   - chunkSize: Her parça boyutu (bytes)
    ///   - progressHandler: İlerleme callback'i
    /// - Returns: İndirilen dosyanın URL'i
    func downloadInChunks(
        remoteFileId: String,
        destinationURL: URL,
        chunkSize: Int,
        progressHandler: @escaping (DownloadProgress) -> Void
    ) async throws -> URL
    
    // MARK: - Query
    
    /// Aktif indirmeleri getir
    /// - Returns: Aktif download item'ları
    func getActiveDownloads() async -> [DownloadItem]
    
    /// Belirli bir indirmenin durumunu getir
    /// - Parameter itemId: Download item ID
    /// - Returns: Download item
    func getDownloadStatus(itemId: String) async -> DownloadItem?
}

// MARK: - Download Progress

/// İndirme ilerleme bilgisi
struct DownloadProgress {
    let itemId: String
    let progress: Double // 0.0 - 1.0
    let downloadedBytes: Int64
    let totalBytes: Int64
    let speed: Double? // bytes/second
    let estimatedTimeRemaining: TimeInterval?
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
}

// MARK: - Download Service Error

enum DownloadServiceError: Error, LocalizedError {
    case itemNotFound
    case fileAlreadyExists
    case destinationNotWritable
    case insufficientSpace
    case downloadCancelled
    case downloadPaused
    case networkError
    case corruptedFile
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "İndirme item'ı bulunamadı."
        case .fileAlreadyExists:
            return "Dosya zaten mevcut."
        case .destinationNotWritable:
            return "Hedef klasöre yazma izni yok."
        case .insufficientSpace:
            return "Disk alanı yetersiz."
        case .downloadCancelled:
            return "İndirme iptal edildi."
        case .downloadPaused:
            return "İndirme duraklatıldı."
        case .networkError:
            return "Ağ bağlantısı hatası."
        case .corruptedFile:
            return "İndirilen dosya bozuk."
        case .unknownError(let message):
            return "Bilinmeyen hata: \(message)"
        }
    }
}

// MARK: - Implementation Note

/*
 Bu servisin implementasyonunda dikkat edilmesi gerekenler:
 
 1. Concurrent Download Limit
    - Aynı anda maksimum N dosya indirme (kullanıcı ayarı)
    - Kuyruk sistemi ile yönetim
 
 2. Resume Capability
    - URLSession ile resumeData kullanımı
    - Telegram'ın partial content desteğini kontrol et
 
 3. Error Handling
    - Network timeout'ları
    - Disk dolu durumu
    - File corruption checks (MD5/SHA256)
 
 4. Progress Reporting
    - Main thread'de UI güncelleme
    - Throttle progress updates (her 100ms'de bir)
 
 5. Chunk Download Strategy
    - Büyük dosyalar için (>100MB)
    - Her chunk'ı ayrı ayrı indir ve birleştir
    - Partial download resume desteği
 
 6. File Naming
    - Format: <channelName>_<messageId>_<originalName>
    - Special character sanitization
    - Duplicate name handling
 
 ⚠️ Telegram'ın download rate limit'lerine dikkat!
 */
