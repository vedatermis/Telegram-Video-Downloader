//
//  ThumbnailManager.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 20.11.2025.
//

import Foundation
import AppKit

/// Thumbnail önbellek yöneticisi
final class ThumbnailManager {
    static let shared = ThumbnailManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("TGMediaBackup/Thumbnails")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Cache'den thumbnail yolunu getir
    func getThumbnailPath(fileId: Int) -> String? {
        let fileURL = cacheDirectory.appendingPathComponent("\(fileId).jpg")
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL.path
        }
        return nil
    }
    
    /// Thumbnail'i cache'e kaydet
    func saveThumbnail(fileId: Int, sourcePath: String) {
        let destinationURL = cacheDirectory.appendingPathComponent("\(fileId).jpg")
        
        // Eğer zaten varsa işlem yapma
        if fileManager.fileExists(atPath: destinationURL.path) { return }
        
        do {
            try fileManager.copyItem(atPath: sourcePath, toPath: destinationURL.path)
        } catch {
            print("Failed to cache thumbnail: \(error)")
        }
    }
    
    /// Mock data için placeholder thumbnail oluştur
    func generatePlaceholderThumbnail(fileId: String, isVideo: Bool = true) -> String? {
        let fileURL = cacheDirectory.appendingPathComponent("\(fileId).jpg")
        
        // Eğer zaten varsa path'i döndür
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL.path
        }
        
        // Placeholder image oluştur
        let size = NSSize(width: 640, height: 360)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Gradient background
        let gradient = NSGradient(colors: [
            NSColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0),
            NSColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0)
        ])
        let rect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        gradient?.draw(in: rect, angle: 45)
        
        // Icon
        let iconSize: CGFloat = 80
        let iconRect = NSRect(
            x: (size.width - iconSize) / 2,
            y: (size.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        
        if let icon = NSImage(systemSymbolName: isVideo ? "video.fill" : "photo.fill", accessibilityDescription: nil) {
            icon.draw(in: iconRect, from: NSRect(x: 0, y: 0, width: icon.size.width, height: icon.size.height), operation: .sourceOver, fraction: 0.3)
        }
        
        image.unlockFocus()
        
        // JPEG olarak kaydet
        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: NSNumber(value: 0.8)]) {
            try? jpegData.write(to: fileURL)
            return fileURL.path
        }
        
        return nil
    }
    
    /// Cache'i temizle
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Cache boyutunu getir (sadece thumbnail)
    func getCacheSize() -> String {
        return ByteCountFormatter.string(fromByteCount: getCacheSizeBytes(), countStyle: .file)
    }
    
    /// Cache boyutunu byte olarak getir
    func getCacheSizeBytes() -> Int64 {
        guard let urls = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var size: Int64 = 0
        for url in urls {
            if let resources = try? url.resourceValues(forKeys: [.fileSizeKey]), let fileSize = resources.fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }
    
    /// Toplam cache boyutunu getir (thumbnail + TDLib dosyaları)
    func getTotalCacheSize() -> String {
        let thumbnailSize = getCacheSizeBytes()
        let tdlibFilesSize = TelegramService.shared.getTDLibFilesSize()
        return ByteCountFormatter.string(fromByteCount: thumbnailSize + tdlibFilesSize, countStyle: .file)
    }
    
    /// TDLib dosya cache boyutunu getir
    func getTDLibCacheSize() -> String {
        return ByteCountFormatter.string(fromByteCount: TelegramService.shared.getTDLibFilesSize(), countStyle: .file)
    }
    
    /// TDLib veritabanı boyutunu getir
    func getTDLibDatabaseSize() -> String {
        return ByteCountFormatter.string(fromByteCount: TelegramService.shared.getTDLibDatabaseSize(), countStyle: .file)
    }
}
