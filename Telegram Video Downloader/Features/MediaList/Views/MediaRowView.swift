//
//  MediaRowView.swift
//  TeleGrab
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// Liste görünümü için medya satırı
struct MediaRowView: View {
    
    @EnvironmentObject private var appState: AppState
    let message: TelegramMessage
    let mediaItem: MediaItem
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var localThumbnailPath: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                if let path = localThumbnailPath, FileManager.default.fileExists(atPath: path) {
                    AsyncImage(url: URL(fileURLWithPath: path)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .frame(width: 80, height: 60)
            .cornerRadius(6)
            .clipped()
            .overlay {
                if mediaItem.mimeType?.contains("video") == true {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .onTapGesture {
                Task {
                    await streamVideo()
                }
            }
            .task {
                await loadThumbnail()
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(mediaItem.displayFileName)
                    .font(.body)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Text(message.date.formatted(date: .numeric, time: .shortened))
                        .font(.caption)
                    
                    if let duration = mediaItem.formattedDuration {
                        Label(duration, systemImage: "clock")
                            .font(.caption)
                    }
                    
                    if let resolution = mediaItem.resolution {
                        Label(resolution, systemImage: "rectangle")
                            .font(.caption)
                    }
                    
                    Text(mediaItem.formattedFileSize)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Selection checkbox or downloaded indicator
            if appState.downloadedMediaIds.contains(mediaItem.id) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
    
    // MARK: - Methods
    
    private func streamVideo() async {
        do {
            // Get temporary streaming URL from TelegramService
            let url = try await TelegramService.shared.getMediaStreamURL(remoteFileId: mediaItem.remoteFileId)
            
            // Open in default video player
            await MainActor.run {
                NSWorkspace.shared.open(url)
            }
        } catch {
            print("Error streaming video: \(error)")
        }
    }
    
    private func loadThumbnail() async {
        // 1. Check custom cache first
        if let fileId = mediaItem.thumbnailFileId,
           let cachedPath = ThumbnailManager.shared.getThumbnailPath(fileId: fileId) {
            self.localThumbnailPath = cachedPath
            return
        }
        
        // 2. Check if we already have a valid path from the model (TDLib cache)
        if let path = mediaItem.thumbnailPath, FileManager.default.fileExists(atPath: path) {
            self.localThumbnailPath = path
            // Cache it for future
            if let fileId = mediaItem.thumbnailFileId {
                ThumbnailManager.shared.saveThumbnail(fileId: fileId, sourcePath: path)
            }
            return
        }
        
        // 3. Download if needed
        if let fileId = mediaItem.thumbnailFileId {
            do {
                let path = try await TelegramService.shared.downloadThumbnail(fileId: fileId)
                await MainActor.run {
                    self.localThumbnailPath = path
                }
                // Cache it
                ThumbnailManager.shared.saveThumbnail(fileId: fileId, sourcePath: path)
            } catch {
                print("Failed to download thumbnail: \(error)")
            }
        }
    }
}
