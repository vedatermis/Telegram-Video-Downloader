//
//  TelegramDialog.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import Foundation

/// Telegram sohbet/kanal/grup modeli
struct TelegramDialog: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String
    let type: DialogType
    let photoPath: String?
    let unreadCount: Int
    let lastMessage: String?
    let lastMessageDate: Date?
    let memberCount: Int?
    
    /// Sohbet türü
    enum DialogType: String, Codable {
        case privateChat = "private"
        case group = "group"
        case channel = "channel"
        case supergroup = "supergroup"
        case bot = "bot"
        
        var displayName: String {
            let manager = LocalizationManager.shared
            switch self {
            case .privateChat: return manager.localizedString("dialog.private")
            case .group: return manager.localizedString("dialog.group")
            case .channel: return manager.localizedString("dialog.channel")
            case .supergroup: return manager.localizedString("dialog.supergroup")
            case .bot: return manager.localizedString("dialog.bot")
            }
        }
        
        var icon: String {
            switch self {
            case .privateChat: return "person.fill"
            case .group: return "person.2.fill"
            case .channel: return "megaphone.fill"
            case .supergroup: return "person.3.fill"
            case .bot: return "cpu"
            }
        }
    }
    
    /// Görüntülenecek son mesaj zamanı
    var displayTime: String {
        guard let date = lastMessageDate else { return "" }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Dün"
        } else if let days = calendar.dateComponents([.day], from: date, to: now).day, days < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}
