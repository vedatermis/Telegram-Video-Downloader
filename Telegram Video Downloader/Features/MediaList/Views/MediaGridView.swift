//
//  MediaGridView.swift
//  TeleGrab
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// Grid görünümü ile medya listesi
struct MediaGridView: View {
    
    let media: [TelegramMessage]
    let selectedItems: Set<String>
    let onSelect: (String) -> Void
    let size: CGFloat = 200
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(media) { message in
                    if let mediaItem = message.mediaItem {
                        MediaGridItemCompactView(
                            message: message,
                            mediaItem: mediaItem,
                            isSelected: selectedItems.contains(mediaItem.id),
                            onSelect: { onSelect(mediaItem.id) }
                        )
                    }
                }
            }
            .padding()
        }
    }
}

/// Grid item görünümü (compact version for backward compatibility)
struct MediaGridItemCompactView: View {
    
    let message: TelegramMessage
    let mediaItem: MediaItem
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                
                // Selection indicator
                Circle()
                    .fill(isSelected ? Color.blue : Color.white)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(8)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(mediaItem.displayFileName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack {
                    if let duration = mediaItem.formattedDuration {
                        Label(duration, systemImage: "clock")
                            .font(.caption2)
                    }
                    
                    Spacer()
                    
                    Text(mediaItem.formattedFileSize)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        }
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Preview

#Preview {
    MediaGridView(
        media: [],
        selectedItems: [],
        onSelect: { _ in }
    )
    .frame(width: 600, height: 400)
}
