//
//  MediaListViewModel.swift
//  TeleGrab
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import Foundation
import Combine

/// Medya listesi view model
@MainActor
final class MediaListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var media: [TelegramMessage] = []
    @Published var selectedFilter: MediaFilter = .videos
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private var lastLoadedMessageId: Int?
    private var hasMoreMedia: Bool = true
    
    // MARK: - Sorting
    
    enum SortOption: String, CaseIterable, Identifiable {
        case dateNewest = "Tarihe Göre (Yeni > Eski)"
        case dateOldest = "Tarihe Göre (Eski > Yeni)"
        case sizeLargest = "Boyuta Göre (Büyük > Küçük)"
        case sizeSmallest = "Boyuta Göre (Küçük > Büyük)"
        
        var id: String { rawValue }
    }
    
    @Published var sortOption: SortOption = .dateNewest
    
    // MARK: - Computed Properties
    
    /// Filtrelenmiş medya listesi
    var filteredMedia: [TelegramMessage] {
        var filtered: [TelegramMessage]
        switch selectedFilter {
        case .all:
            filtered = media
        case .videos:
            filtered = media.filter { $0.isVideo }
        case .photos:
            filtered = media.filter { $0.mediaType == .photo }
        }
        
        // Arama filtresi
        if !searchText.isEmpty {
            filtered = filtered.filter { message in
                let captionMatch = message.text?.localizedCaseInsensitiveContains(searchText) ?? false
                let filenameMatch = message.mediaItem?.displayFileName.localizedCaseInsensitiveContains(searchText) ?? false
                return captionMatch || filenameMatch
            }
        }
        
        switch sortOption {
        case .dateNewest:
            return filtered.sorted { $0.date > $1.date }
        case .dateOldest:
            return filtered.sorted { $0.date < $1.date }
        case .sizeLargest:
            return filtered.sorted { ($0.mediaItem?.fileSize ?? 0) > ($1.mediaItem?.fileSize ?? 0) }
        case .sizeSmallest:
            return filtered.sorted { ($0.mediaItem?.fileSize ?? 0) < ($1.mediaItem?.fileSize ?? 0) }
        }
    }
    
    // MARK: - Public Methods
    
    /// Medya listesini yükle (İlk yükleme)
    func loadMedia(dialogId: String, appState: AppState) async {
        isLoading = true
        error = nil
        media = []
        lastLoadedMessageId = nil
        hasMoreMedia = true
        
        defer { isLoading = false }
        
        await loadMoreMedia(dialogId: dialogId, appState: appState)
    }
    
    /// Daha fazla medya yükle (Pagination)
    func loadMoreMedia(dialogId: String, appState: AppState) async {
        guard hasMoreMedia, !isLoading || media.isEmpty else { return }
        
        isLoading = true
        
        do {
            let filter: AppMediaFilter
            switch selectedFilter {
            case .all: filter = .all
            case .videos: filter = .video
            case .photos: filter = .photo
            }
            
            let messages = try await TelegramService.shared.fetchMediaMessages(
                dialogId: dialogId,
                filter: filter,
                limit: 50,
                offsetId: lastLoadedMessageId
            )
            
            if messages.isEmpty {
                hasMoreMedia = false
            } else {
                // Filter out duplicates
                let newMessages = messages.filter { newMsg in
                    !self.media.contains(where: { $0.id == newMsg.id })
                }
                
                self.media.append(contentsOf: newMessages)
                
                // Update lastLoadedMessageId from the last message
                if let lastMsg = messages.last, let id = Int(lastMsg.id) {
                    self.lastLoadedMessageId = id
                }
                appState.currentMediaList = self.media
            }
            
        } catch {
            self.error = error
            print("Error loading media: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Mock Data
    
    private func mockMedia(dialogId: String) -> [TelegramMessage] {
        (1...15).map { index in
            TelegramMessage(
                id: "\(dialogId)_\(index)",
                dialogId: dialogId,
                senderId: "sender_\(index)",
                senderName: "User \(index)",
                text: "Video açıklaması \(index)",
                date: Date().addingTimeInterval(-Double(index * 3600)),
                mediaType: .video,
                mediaItem: MediaItem(
                    id: "media_\(index)",
                    messageId: "\(dialogId)_\(index)",
                    fileName: "video_\(index).mp4",
                    mimeType: "video/mp4",
                    fileSize: Int64.random(in: 10_000_000...500_000_000),
                    duration: Double.random(in: 60...3600),
                    width: [1280, 1920, 3840].randomElement(),
                    height: [720, 1080, 2160].randomElement(),
                    thumbnailPath: nil,
                    thumbnailFileId: nil,
                    remoteFileId: "remote_\(index)"
                )
            )
        }
    }
}
