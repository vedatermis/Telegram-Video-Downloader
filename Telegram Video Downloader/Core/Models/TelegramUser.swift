//
//  TelegramUser.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import Foundation

/// Telegram kullanıcı modeli
struct TelegramUser: Identifiable, Codable, Equatable {
    let id: String
    let username: String?
    let firstName: String
    let lastName: String?
    let phoneNumber: String?
    let profilePhotoPath: String?
    
    /// Görüntülenecek isim
    var displayName: String {
        if let firstName = firstName.nilIfEmpty, let lastName = lastName?.nilIfEmpty {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName.nilIfEmpty {
            return firstName
        } else if let username = username?.nilIfEmpty {
            return "@\(username)"
        } else {
            return phoneNumber ?? LocalizationManager.shared.localizedString("user.unknown")
        }
    }
    
    /// Kullanıcı identifier (username veya ID)
    var identifier: String {
        username ?? id
    }
}

// MARK: - String Extension
private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
