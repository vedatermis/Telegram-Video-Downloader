//
//  MediaListView.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// Medya listesi görünümü
/// Seçili sohbetteki videoları gösterir
struct MediaListView: View {
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = MediaListViewModel()
    
    @AppStorage("mediaViewMode") private var viewMode: ViewMode = .mediumGrid
    
    enum ViewMode: String, CaseIterable {
        case smallGrid = "Küçük Grid"
        case mediumGrid = "Orta Grid"
        case largeGrid = "Büyük Grid"
        case list = "Liste"
        
        var gridSize: CGFloat {
            switch self {
            case .smallGrid: return 120
            case .mediumGrid: return 180
            case .largeGrid: return 280
            case .list: return 0
            }
        }
        
        var iconName: String {
            switch self {
            case .smallGrid: return "square.grid.3x3"
            case .mediumGrid: return "square.grid.2x2"
            case .largeGrid: return "square.grid.2x2.fill"
            case .list: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
            
            Divider()
            
                        // Content
            content
        }
        .navigationTitle(appState.selectedDialog?.title ?? "Medya")
        .task(id: appState.selectedDialog?.id) {
            if let dialogId = appState.selectedDialog?.id {
                await viewModel.loadMedia(dialogId: dialogId, appState: appState)
            }
        }
        .task(id: viewModel.selectedFilter) {
            if let dialogId = appState.selectedDialog?.id {
                await viewModel.loadMedia(dialogId: dialogId, appState: appState)
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack {
            // Filter buttons
            HStack(spacing: 4) {
                ForEach([MediaFilter.all, .videos, .photos], id: \.self) { filter in
                    Button(action: { viewModel.selectedFilter = filter }) {
                        Text(filter.displayName)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.selectedFilter == filter ?
                                    Color.accentColor : Color.clear,
                                in: Capsule()
                            )
                            .foregroundStyle(
                                viewModel.selectedFilter == filter ?
                                    .white : .primary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Ara...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
            .frame(width: 200)
            
            Spacer()
            
            // View Mode Picker
            Picker("", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
            .padding(.trailing, 8)
            
            // Sort Menu
            Menu {
                Picker("Sıralama", selection: $viewModel.sortOption) {
                    ForEach(MediaListViewModel.SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                Label("Sırala", systemImage: "arrow.up.arrow.down")
            }
            .padding(.trailing, 8)
            
            // Select All button
            Button(action: toggleSelectAll) {
                Text(appState.selectedMediaItems.count == viewModel.filteredMedia.count ? "Seçimi Kaldır" : "Tümünü Seç")
            }
            .disabled(viewModel.filteredMedia.isEmpty)
            .padding(.trailing)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.media.isEmpty {
            LoadingView(message: "media.loading")
        } else if let error = viewModel.error {
            ErrorView(error: error) {
                Task {
                    if let dialogId = appState.selectedDialog?.id {
                        await viewModel.loadMedia(dialogId: dialogId, appState: appState)
                    }
                }
            }
        } else if viewModel.filteredMedia.isEmpty {
            EmptyStateView(
                icon: "video.slash",
                title: "media.no_videos",
                message: "media.no_videos_desc"
            )
        } else {
            if viewMode == .list {
                MediaListScrollView(
                    media: viewModel.filteredMedia,
                    selectedItems: appState.selectedMediaItems,
                    onSelect: { id in
                        appState.toggleMediaSelection(id)
                    },
                    onLoadMore: {
                        Task {
                            if let dialogId = appState.selectedDialog?.id {
                                await viewModel.loadMoreMedia(dialogId: dialogId, appState: appState)
                            }
                        }
                    }
                )
            } else {
                MediaGridScrollView(
                    media: viewModel.filteredMedia,
                    selectedItems: appState.selectedMediaItems,
                    gridSize: viewMode.gridSize,
                    onSelect: { id in
                        appState.toggleMediaSelection(id)
                    },
                    onLoadMore: {
                        Task {
                            if let dialogId = appState.selectedDialog?.id {
                                await viewModel.loadMoreMedia(dialogId: dialogId, appState: appState)
                            }
                        }
                    }
                )
            }
        }
    }
    

    // MARK: - Actions
    
    private func toggleSelectAll() {
        if appState.selectedMediaItems.count == viewModel.filteredMedia.count {
            appState.clearSelection()
        } else {
            viewModel.filteredMedia.forEach { message in
                if let mediaId = message.mediaItem?.id {
                    appState.selectedMediaItems.insert(mediaId)
                }
            }
        }
    }
}

// MARK: - Media Filter

enum MediaFilter {
    case all, videos, photos
    
    var displayName: String {
        switch self {
        case .all: return "Tümü"
        case .videos: return "Videolar"
        case .photos: return "Fotoğraflar"
        }
    }
}

// MARK: - Media List Scroll View

struct MediaListScrollView: View {
    let media: [TelegramMessage]
    let selectedItems: Set<String>
    let onSelect: (String) -> Void
    let onLoadMore: () -> Void
    
    var body: some View {
        List {
            ForEach(media) { message in
                if let mediaItem = message.mediaItem {
                    MediaRowView(
                        message: message,
                        mediaItem: mediaItem,
                        isSelected: selectedItems.contains(mediaItem.id),
                        onSelect: { onSelect(mediaItem.id) }
                    )
                    .onAppear {
                        if message == media.last {
                            onLoadMore()
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Media Grid Scroll View

struct MediaGridScrollView: View {
    let media: [TelegramMessage]
    let selectedItems: Set<String>
    let gridSize: CGFloat
    let onSelect: (String) -> Void
    let onLoadMore: () -> Void
    
    private let spacing: CGFloat = 8
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: gridSize, maximum: gridSize), spacing: spacing)],
                spacing: spacing
            ) {
                ForEach(media) { message in
                    if let mediaItem = message.mediaItem {
                        MediaGridItemView(
                            message: message,
                            mediaItem: mediaItem,
                            size: gridSize,
                            isSelected: selectedItems.contains(mediaItem.id),
                            onSelect: { onSelect(mediaItem.id) }
                        )
                        .onAppear {
                            if message == media.last {
                                onLoadMore()
                            }
                        }
                    }
                }
            }
            .padding(spacing)
        }
    }
}

// MARK: - Media Grid Item View

struct MediaGridItemView: View {
    let message: TelegramMessage
    let mediaItem: MediaItem
    let size: CGFloat
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovering = false
    @State private var isPlaying = false
    @State private var thumbnailImage: NSImage?
    
    private var isVideo: Bool {
        mediaItem.mimeType?.hasPrefix("video/") ?? false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                // Main thumbnail image
                Group {
                    if let nsImage = thumbnailImage {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: size, height: size)
                            .overlay(
                                Image(systemName: isVideo ? "video.fill" : "photo.fill")
                                    .font(.system(size: size * 0.3))
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .overlay {
                    // Play button overlay for videos
                    if isVideo {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: size * 0.25))
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .opacity(isHovering ? 1 : 0.7)
                            .animation(.easeInOut(duration: 0.2), value: isHovering)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Task {
                        await playMedia()
                    }
                }
                
                // Selection checkbox (always visible on hover or when selected)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            onSelect()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.accentColor : Color.black.opacity(0.5))
                                    .frame(width: 28, height: 28)
                                
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                } else {
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .opacity(isHovering || isSelected ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: isHovering)
                    }
                    Spacer()
                }
                .allowsHitTesting(true)
                
                // Video duration badge
                if isVideo, let duration = mediaItem.duration {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(formatDuration(duration))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.black.opacity(0.7))
                                .cornerRadius(4)
                                .padding(6)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(width: size, height: size)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            
            // Info (only for larger sizes)
            if size >= 180 {
                VStack(alignment: .leading, spacing: 4) {
                    // Message text if available (fixed height)
                    if let text = message.text, !text.isEmpty {
                        Text(text)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                            .frame(height: 28, alignment: .top)
                    } else {
                        // Placeholder to maintain consistent height
                        Spacer()
                            .frame(height: 28)
                    }
                    
                    Text(mediaItem.displayFileName)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(formatFileSize(mediaItem.fileSize))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(formatDate(message.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .frame(width: size, alignment: .leading)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .task(id: mediaItem.id) {
            await loadThumbnail()
        }
        .onChange(of: mediaItem.thumbnailPath) { _, newPath in
            // When thumbnail path updates (real thumbnail downloaded), reload
            if newPath != nil {
                Task {
                    await loadThumbnail()
                }
            }
        }
    }
    
    private func loadThumbnail() async {
        // Check if current thumbnail is a placeholder
        let isPlaceholder = thumbnailImage != nil && 
                           mediaItem.thumbnailFileId != nil &&
                           ThumbnailManager.shared.getThumbnailPath(fileId: mediaItem.thumbnailFileId!) == nil
        
        // 1. Check custom cache first (skip if we already have a placeholder)
        if !isPlaceholder, 
           let fileId = mediaItem.thumbnailFileId,
           let cachedPath = ThumbnailManager.shared.getThumbnailPath(fileId: fileId),
           let nsImage = NSImage(contentsOfFile: cachedPath) {
            await MainActor.run {
                self.thumbnailImage = nsImage
            }
            return
        }
        
        // 2. Check if we already have a valid path from the model (TDLib cache)
        if let path = mediaItem.thumbnailPath, 
           FileManager.default.fileExists(atPath: path),
           let nsImage = NSImage(contentsOfFile: path) {
            await MainActor.run {
                self.thumbnailImage = nsImage
            }
            // Cache it for future
            if let fileId = mediaItem.thumbnailFileId {
                ThumbnailManager.shared.saveThumbnail(fileId: fileId, sourcePath: path)
            }
            return
        }
        
        // 3. Download if needed (or if we have a placeholder but need real thumbnail)
        if let fileId = mediaItem.thumbnailFileId {
            // First show placeholder if we don't have any image yet
            if thumbnailImage == nil {
                await loadPlaceholder()
            }
            
            do {
                let path = try await TelegramService.shared.downloadThumbnail(fileId: fileId)
                if let nsImage = NSImage(contentsOfFile: path) {
                    await MainActor.run {
                        self.thumbnailImage = nsImage
                    }
                    // Cache it
                    ThumbnailManager.shared.saveThumbnail(fileId: fileId, sourcePath: path)
                }
            } catch {
                print("Failed to download thumbnail: \(error)")
                // Keep placeholder if download fails
                if thumbnailImage == nil {
                    await loadPlaceholder()
                }
            }
        } else {
            // No thumbnail file ID, use placeholder for mock data
            await loadPlaceholder()
        }
    }
    
    private func loadPlaceholder() async {
        if let placeholderPath = ThumbnailManager.shared.generatePlaceholderThumbnail(
            fileId: mediaItem.id,
            isVideo: isVideo
        ), let nsImage = NSImage(contentsOfFile: placeholderPath) {
            await MainActor.run {
                self.thumbnailImage = nsImage
            }
        }
    }
    
    private func playMedia() async {
        guard !isPlaying else { return }
        isPlaying = true
        
        do {
            // Try to stream from Telegram first
            let url = try await TelegramService.shared.getMediaStreamURL(remoteFileId: mediaItem.remoteFileId)
            
            await MainActor.run {
                NSWorkspace.shared.open(url)
                isPlaying = false
            }
        } catch {
            print("Error streaming video: \(error)")
            
            // Fallback to local file if available
            await MainActor.run {
                if let filePath = mediaItem.filePath, !filePath.isEmpty {
                    let url = URL(fileURLWithPath: filePath)
                    if FileManager.default.fileExists(atPath: filePath) {
                        NSWorkspace.shared.open(url)
                    } else {
                        print("File not found at path: \(filePath)")
                    }
                } else {
                    print("No file path available and streaming failed for media item: \(mediaItem.id)")
                }
                isPlaying = false
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    let appState = AppState()
    appState.isAuthenticated = true
    appState.selectedDialog = TelegramDialog(
        id: "1",
        title: "Test Channel",
        type: .channel,
        photoPath: nil,
        unreadCount: 0,
        lastMessage: nil,
        lastMessageDate: nil,
        memberCount: 100
    )
    
    return NavigationStack {
        MediaListView()
            .environmentObject(appState)
    }
    .frame(width: 800, height: 600)
}
