//
//  LocalizedStrings.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 2.12.2025.
//

import Foundation

struct LocalizedStrings {
    
    static let shared = LocalizedStrings()
    
    private let strings: [String: [String: String]] = [
        // Turkish
        "tr": [
            // Common
            "common.cancel": "İptal",
            "common.ok": "Tamam",
            "common.error": "Hata",
            

            // Main
            "main.select_chat_title": "Sohbet Seçin",
            "main.select_chat_desc": "Sol panelden bir sohbet seçerek medya dosyalarını görüntüleyin",
            
            // Media
            "media.select_media": "Medya Seçin",
            "media.select_media_desc": "İndirmek için bir veya daha fazla video seçin",
            
            // Chat
            "chat.title": "Sohbetler",
            "chat.search_placeholder": "Sohbet ara...",
            "chat.loading": "Sohbetler yükleniyor...",
            "chat.no_chats": "Sohbet yok",
            "chat.no_chats_desc": "Henüz hiç sohbetiniz yok",
        ],
        
        // English
        "en": [
            // Common
            "common.cancel": "Cancel",
            "common.ok": "OK",
            "common.error": "Error",
            

            // Main
            "main.select_chat_title": "Select Chat",
            "main.select_chat_desc": "Choose a chat from the left panel to view media files",
            
            // Media
            "media.select_media": "Select Media",
            "media.select_media_desc": "Choose one or more videos to download",
            
            // Chat
            "chat.title": "Chats",
            "chat.search_placeholder": "Search chats...",
            "chat.loading": "Loading chats...",
            "chat.no_chats": "No chats",
            "chat.no_chats_desc": "You don't have any chats yet",
        ]
    ]
    
    func string(for key: String, language: String = "en") -> String {
        return strings[language]?[key] ?? strings["en"]?[key] ?? key
    }
}
