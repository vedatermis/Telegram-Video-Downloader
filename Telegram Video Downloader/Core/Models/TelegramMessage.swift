//
//  TelegramMessage.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import Foundation

/// Telegram mesaj modeli
struct TelegramMessage: Identifiable, Codable, Equatable {
    let id: String
    let dialogId: String
    let senderId: String?
    let senderName: String?
    let text: String?
    let date: Date
    let mediaType: MediaType?
    let mediaItem: MediaItem?
    
    /// Medya türü
    enum MediaType: String, Codable {
        case photo
        case video
        case audio
        case voice
        case document
        case sticker
        case animation
        case videoNote
        
        var displayName: String {
            let manager = LocalizationManager.shared
            switch self {
            case .photo: return manager.localizedString("media.type.photo")
            case .video: return manager.localizedString("media.type.video")
            case .audio: return manager.localizedString("media.type.audio")
            case .voice: return manager.localizedString("media.type.voice")
            case .document: return manager.localizedString("media.type.document")
            case .sticker: return manager.localizedString("media.type.sticker")
            case .animation: return manager.localizedString("media.type.animation")
            case .videoNote: return manager.localizedString("media.type.videoNote")
            }
        }
        
        var icon: String {
            switch self {
            case .photo: return "photo"
            case .video: return "video.fill"
            case .audio: return "music.note"
            case .voice: return "waveform"
            case .document: return "doc.fill"
            case .sticker: return "face.smiling"
            case .animation: return "rectangle.stack.fill"
            case .videoNote: return "video.circle.fill"
            }
        }
    }
    
    /// Mesajın medya içerip içermediği
    var hasMedia: Bool {
        mediaType != nil && mediaItem != nil
    }
    
    /// Video mesajı mı?
    var isVideo: Bool {
        mediaType == .video || mediaType == .videoNote || mediaType == .animation
    }
}
