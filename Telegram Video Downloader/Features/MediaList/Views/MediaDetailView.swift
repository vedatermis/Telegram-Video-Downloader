//
//  MediaDetailView.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// Seçili medyanın detay görünümü
struct MediaDetailView: View {
    
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Selection info
                    selectionInfo
                    
                    Divider()
                    
                    // Download options
                    downloadOptions
                    
                    Divider()
                    
                    // Actions
                    actions
                }
                .padding()
            }
        }
        .navigationTitle(Text("media.details"))
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("\(appState.selectedMediaItems.count) \(localizationManager.localizedString("media.videos_selected"))")
                .font(.headline)
            
            Spacer()
            
            Button("media.clear_selection") {
                appState.clearSelection()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Selection Info
    
    private var selectionInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("media.selected_videos", systemImage: "video.fill")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("media.total_size")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formattedTotalSize)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("media.avg_duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formattedAverageDuration)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Download Options
    
    private var downloadOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("settings.download_settings", systemImage: "gearshape")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Destination folder
                HStack {
                    Text("settings.destination_folder")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Button(action: { selectFolder() }) {
                        Text(folderName)
                            .font(.caption)
                            .lineLimit(1)
                            .frame(maxWidth: 150)
                    }
                    .buttonStyle(.bordered)
                }
                
                // Concurrent downloads
                HStack {
                    Text("settings.concurrent_downloads")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Stepper(
                        "\(appState.maxConcurrentDownloads)",
                        value: $appState.maxConcurrentDownloads,
                        in: 1...10
                    )
                    .frame(width: 100)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Actions
    
    private var actions: some View {
        VStack(spacing: 12) {
            Button(action: downloadSelected) {
                Label("common.start_download", systemImage: "arrow.down.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button(action: { appState.clearSelection() }) {
                Text("common.cancel")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Computed Properties
    
    private var folderName: String {
        guard !appState.downloadFolderPath.isEmpty else {
            return localizationManager.localizedString("settings.select_folder")
        }
        return (appState.downloadFolderPath as NSString).lastPathComponent
    }
    
    private var selectedItems: [MediaItem] {
        appState.currentMediaList
            .compactMap { $0.mediaItem }
            .filter { appState.selectedMediaItems.contains($0.id) }
    }
    
    private var formattedTotalSize: String {
        let size = selectedItems.reduce(0) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    private var formattedAverageDuration: String {
        let itemsWithDuration = selectedItems.filter { ($0.duration ?? 0) > 0 }
        guard !itemsWithDuration.isEmpty else { return "-" }
        
        let totalDuration = itemsWithDuration.reduce(0.0) { $0 + ($1.duration ?? 0) }
        let avg = totalDuration / Double(itemsWithDuration.count)
        
        let minutes = Int(avg) / 60
        let seconds = Int(avg) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Actions
    
    @discardableResult
    private func selectFolder() -> Bool {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK, let url = panel.url {
            appState.setDownloadFolder(url: url)
            return true
        }
        return false
    }
    
    private func downloadSelected() {
        if appState.isDownloadFolderWritable {
            appState.startDownloadForSelectedItems()
        } else {
            if selectFolder() {
                appState.startDownloadForSelectedItems()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let appState = AppState()
    appState.selectedMediaItems = ["1", "2", "3"]
    
    return NavigationStack {
        MediaDetailView()
            .environmentObject(appState)
    }
    .frame(width: 350, height: 600)
}
