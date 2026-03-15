//
//  ChatRowView.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// Sohbet satırı görünümü
struct ChatRowView: View {
    
    let dialog: TelegramDialog
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            avatar
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title and time
                HStack {
                    Text(dialog.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if !dialog.displayTime.isEmpty {
                        Text(dialog.displayTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Last message and badge
                HStack {
                    if let lastMessage = dialog.lastMessage {
                        Text(lastMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if dialog.unreadCount > 0 {
                        unreadBadge
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    // MARK: - Avatar
    
    private var avatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 44, height: 44)
            
            Image(systemName: dialog.type.icon)
                .font(.system(size: 20))
                .foregroundStyle(.white)
        }
    }
    
    private var avatarColor: Color {
        // Dialog ID'ye göre renk oluştur
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .indigo]
        let hash = abs(dialog.id.hashValue)
        return colors[hash % colors.count]
    }
    
    // MARK: - Unread Badge
    
    private var unreadBadge: some View {
        Text("\(dialog.unreadCount)")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue, in: Capsule())
            .frame(minWidth: 20)
    }
}

// MARK: - Preview

#Preview {
    List {
        ChatRowView(dialog: TelegramDialog(
            id: "1",
            title: "Saved Messages",
            type: .privateChat,
            photoPath: nil,
            unreadCount: 3,
            lastMessage: "Test message",
            lastMessageDate: Date(),
            memberCount: nil
        ))
        
        ChatRowView(dialog: TelegramDialog(
            id: "2",
            title: "Teknoloji Grubu",
            type: .group,
            photoPath: nil,
            unreadCount: 0,
            lastMessage: "Merhaba dünya!",
            lastMessageDate: Date().addingTimeInterval(-86400),
            memberCount: 150
        ))
        
        ChatRowView(dialog: TelegramDialog(
            id: "3",
            title: "Haber Kanalı",
            type: .channel,
            photoPath: nil,
            unreadCount: 42,
            lastMessage: "Yeni içerik yayınlandı",
            lastMessageDate: Date().addingTimeInterval(-3600),
            memberCount: 10000
        ))
    }
    .listStyle(.sidebar)
    .frame(width: 300)
}
