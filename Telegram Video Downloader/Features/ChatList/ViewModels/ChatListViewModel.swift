//
//  ChatListViewModel.swift
//  TeleGrab
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import Foundation
import Combine

/// Sohbet listesi view model
@MainActor
final class ChatListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var chats: [TelegramDialog] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Filtrelenmiş sohbet listesi
    var filteredChats: [TelegramDialog] {
        guard !searchText.isEmpty else { return chats }
        
        return chats.filter { dialog in
            dialog.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Public Methods
    
    /// Sohbetleri yükle
    func loadChats() async {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let dialogs = try await TelegramService.shared.fetchDialogs(limit: 100, offsetId: nil)
            self.chats = dialogs
        } catch {
            self.error = error
            print("Error loading chats: \(error)")
        }
    }
    
    // MARK: - Mock Data
    
    private func mockChats() -> [TelegramDialog] {
        [
            TelegramDialog(
                id: "1",
                title: "Saved Messages",
                type: .privateChat,
                photoPath: nil,
                unreadCount: 0,
                lastMessage: "Kayıtlı mesajlarım",
                lastMessageDate: Date(),
                memberCount: nil
            ),
            TelegramDialog(
                id: "2",
                title: "iOS Geliştiriciler",
                type: .group,
                photoPath: nil,
                unreadCount: 5,
                lastMessage: "SwiftUI hakkında yeni bir makale paylaşıldı",
                lastMessageDate: Date().addingTimeInterval(-1800),
                memberCount: 234
            ),
            TelegramDialog(
                id: "3",
                title: "Teknoloji Haberleri",
                type: .channel,
                photoPath: nil,
                unreadCount: 12,
                lastMessage: "Apple'dan yeni açıklama",
                lastMessageDate: Date().addingTimeInterval(-3600),
                memberCount: 5420
            ),
            TelegramDialog(
                id: "4",
                title: "Video Arşivi",
                type: .supergroup,
                photoPath: nil,
                unreadCount: 0,
                lastMessage: "Yeni video eklendi",
                lastMessageDate: Date().addingTimeInterval(-7200),
                memberCount: 890
            ),
            TelegramDialog(
                id: "5",
                title: "Eğitim Kanalı",
                type: .channel,
                photoPath: nil,
                unreadCount: 3,
                lastMessage: "Yeni ders videosu: SwiftUI Advanced",
                lastMessageDate: Date().addingTimeInterval(-86400),
                memberCount: 12340
            )
        ]
    }
}
