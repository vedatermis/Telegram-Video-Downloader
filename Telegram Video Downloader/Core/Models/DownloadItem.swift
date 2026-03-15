//
//  DownloadItem.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import Foundation

/// İndirme item modeli (indirme kuyruğu için)
struct DownloadItem: Identifiable, Equatable {
    let id: String
    let messageId: String
    let mediaItem: MediaItem
    let dialogTitle: String
    var status: DownloadStatus
    var progress: Double
    var downloadedBytes: Int64
    var error: String?
    var localURL: URL?
    var startDate: Date?
    var endDate: Date?
    
    /// İndirme durumu
    enum DownloadStatus: Equatable {
        case pending
        case downloading
        case paused
        case completed
        case failed
        case cancelled
        
        var displayName: String {
            let manager = LocalizationManager.shared
            switch self {
            case .pending: return manager.localizedString("status.pending")
            case .downloading: return manager.localizedString("status.downloading")
            case .paused: return manager.localizedString("status.paused")
            case .completed: return manager.localizedString("status.completed")
            case .failed: return manager.localizedString("status.failed")
            case .cancelled: return manager.localizedString("status.cancelled")
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .downloading: return "arrow.down.circle.fill"
            case .paused: return "pause.circle"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            case .cancelled: return "xmark.circle"
            }
        }
        
        var canRetry: Bool {
            self == .failed || self == .cancelled
        }
        
        var canPause: Bool {
            self == .downloading
        }
        
        var canResume: Bool {
            self == .paused
        }
        
        var canCancel: Bool {
            self == .downloading || self == .pending || self == .paused
        }
    }
    
    /// İndirme hızı (bytes/second)
    var downloadSpeed: Double? {
        guard let startDate = startDate,
              status == .downloading,
              downloadedBytes > 0 else {
            return nil
        }
        
        let elapsed = Date().timeIntervalSince(startDate)
        guard elapsed > 0 else { return nil }
        
        return Double(downloadedBytes) / elapsed
    }
    
    /// Formatlanmış indirme hızı
    var formattedSpeed: String? {
        guard let speed = downloadSpeed else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .file) + "/s"
    }
    
    /// Tahmini kalan süre
    var estimatedTimeRemaining: TimeInterval? {
        guard let speed = downloadSpeed,
              speed > 0,
              status == .downloading else {
            return nil
        }
        
        let remaining = mediaItem.fileSize - downloadedBytes
        return Double(remaining) / speed
    }
    
    /// Formatlanmış kalan süre
    var formattedTimeRemaining: String? {
        guard let time = estimatedTimeRemaining else { return nil }
        
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%dsa %ddk", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%ddk %dsn", minutes, seconds)
        } else {
            return String(format: "%dsn", seconds)
        }
    }
    
    /// İndirme ilerleme yüzdesi (0-100)
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    /// Hedef dosya adı
    var targetFileName: String {
        // Format: <dialogTitle>_<messageId>_<originalFileName>
        let cleanDialogTitle = dialogTitle
            .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
            .prefix(30)
        
        let originalName = mediaItem.displayFileName
        let ext = (originalName as NSString).pathExtension
        let nameWithoutExt = (originalName as NSString).deletingPathExtension
        
        return "\(cleanDialogTitle)_\(messageId)_\(nameWithoutExt).\(ext)"
    }
}

// MARK: - Equatable
extension DownloadItem {
    static func == (lhs: DownloadItem, rhs: DownloadItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.status == rhs.status &&
        lhs.progress == rhs.progress &&
        lhs.downloadedBytes == rhs.downloadedBytes
    }
}
