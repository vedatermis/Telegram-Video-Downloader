//
//  DownloadQueueView.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// İndirme kuyruğu görünümü
struct DownloadQueueView: View {
    
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Download list
            if appState.activeDownloads.isEmpty {
                EmptyStateView(
                    icon: "arrow.down.circle",
                    title: "download.no_downloads",
                    message: "download.no_downloads_desc"
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(appState.activeDownloads) { download in
                            DownloadRowView(download: download)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(Text("download.title"))
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("\(activeCount) \(localizationManager.localizedString("download.active_downloads"))")
                .font(.headline)
            
            Spacer()
            
            if completedCount > 0 {
                Button("download.clear_completed") {
                    appState.clearCompletedDownloads()
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Computed Properties
    
    private var activeCount: Int {
        appState.activeDownloads.filter { $0.status == .downloading || $0.status == .pending }.count
    }
    
    private var completedCount: Int {
        appState.activeDownloads.filter { $0.status == .completed }.count
    }
}

/// İndirme satırı görünümü
struct DownloadRowView: View {
    
    @EnvironmentObject private var appState: AppState
    let download: DownloadItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and action button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(download.targetFileName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    // Speed/Status info
                    if download.status == .downloading {
                        if let speed = download.formattedSpeed {
                            Text(speed)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else if download.status == .completed {
                        Text("Completed")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else if download.status == .paused {
                        Text("Paused")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    } else if download.status == .failed {
                        Text("Failed")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                // Action button
                if download.status == .downloading {
                    Button(action: { appState.pauseDownload(download) }) {
                        Image(systemName: "pause.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                } else if download.status == .paused {
                    Button(action: { appState.resumeDownload(download) }) {
                        Image(systemName: "play.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                } else if download.status == .completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                } else if download.status == .failed {
                    Button(action: { appState.retryDownload(download) }) {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Progress bar
            if download.status != .completed {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(download.status == .failed ? Color.red : Color.blue)
                            .frame(width: geometry.size.width * download.progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
            
            // Progress percentage
            HStack {
                Text("\(download.progressPercentage)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // Error message
            if let error = download.error {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    let appState = AppState()
    
    NavigationStack {
        DownloadQueueView()
            .environmentObject(appState)
            .onAppear {
                appState.activeDownloads = [
                    DownloadItem(
                        id: "1",
                        messageId: "msg1",
                        mediaItem: MediaItem(
                            id: "1",
                            messageId: "msg1",
                            fileName: "video1.mp4",
                            mimeType: "video/mp4",
                            fileSize: 100_000_000,
                            duration: 300,
                            width: 1920,
                            height: 1080,
                            thumbnailPath: nil,
                            thumbnailFileId: nil,
                            remoteFileId: "remote1"
                        ),
                        dialogTitle: "Test Channel",
                        status: .downloading,
                        progress: 0.45,
                        downloadedBytes: 45_000_000,
                        startDate: Date()
                    ),
                    DownloadItem(
                        id: "2",
                        messageId: "msg2",
                        mediaItem: MediaItem(
                            id: "2",
                            messageId: "msg2",
                            fileName: "video2.mp4",
                            mimeType: "video/mp4",
                            fileSize: 50_000_000,
                            duration: 180,
                            width: 1280,
                            height: 720,
                            thumbnailPath: nil,
                            thumbnailFileId: nil,
                            remoteFileId: "remote2"
                        ),
                        dialogTitle: "Test Channel",
                        status: .completed,
                        progress: 1.0,
                        downloadedBytes: 50_000_000
                    )
                ]
            }
    }
    .frame(width: 400, height: 600)
}
