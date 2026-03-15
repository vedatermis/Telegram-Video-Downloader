//
//  MediaItem.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import Foundation

/// Medya dosyası detay modeli
struct MediaItem: Identifiable, Codable, Equatable {
    let id: String
    let messageId: String
    let fileName: String?
    let mimeType: String?
    let fileSize: Int64
    let duration: TimeInterval?
    let width: Int?
    let height: Int?
    let thumbnailPath: String?
    let thumbnailFileId: Int?
    let remoteFileId: String
    var filePath: String? // İndirilen dosyanın lokal yolu
    
    /// Dosya adı (fallback ile)
    var displayFileName: String {
        if let fileName = fileName, !fileName.isEmpty {
            return fileName
        } else {
            // Mesaj ID'den dosya adı oluştur
            let ext = fileExtension ?? "mp4"
            return "telegram_\(messageId).\(ext)"
        }
    }
    
    /// Dosya uzantısı
    var fileExtension: String? {
        if let fileName = fileName {
            return (fileName as NSString).pathExtension
        } else if let mimeType = mimeType {
            // MIME type'dan uzantı çıkar
            switch mimeType {
            case "video/mp4": return "mp4"
            case "video/quicktime": return "mov"
            case "video/x-matroska": return "mkv"
            case "video/webm": return "webm"
            case "video/avi": return "avi"
            case "image/jpeg": return "jpg"
            case "image/png": return "png"
            case "image/gif": return "gif"
            case "image/webp": return "webp"
            default: return nil
            }
        }
        return nil
    }
    
    /// Formatlanmış dosya boyutu
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    /// Formatlanmış süre (video için)
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// Çözünürlük string'i (ör: "1920x1080")
    var resolution: String? {
        guard let width = width, let height = height else { return nil }
        return "\(width)×\(height)"
    }
    
    /// Video kalitesi tahmini (resolution'a göre)
    var estimatedQuality: VideoQuality? {
        guard let height = height else { return nil }
        
        switch height {
        case 0..<480: return .low
        case 480..<720: return .sd
        case 720..<1080: return .hd
        case 1080..<2160: return .fullHD
        case 2160...: return .uhd
        default: return nil
        }
    }
    
    enum VideoQuality: String {
        case low = "360p"
        case sd = "480p"
        case hd = "720p"
        case fullHD = "1080p"
        case uhd = "4K"
    }
}
