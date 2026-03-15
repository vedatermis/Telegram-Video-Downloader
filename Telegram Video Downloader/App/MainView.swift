//
//  MainView.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// Ana uygulama görünümü
/// 3-panel layout: Sol sidebar (sohbetler), Orta panel (medya listesi), Sağ panel (detaylar)
struct MainView: View {
    
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                authenticatedView
            } else {
                AuthView()
            }
        }
        .alert("common.error", isPresented: $appState.showError) {
            Button("common.ok", role: .cancel) {
                appState.errorMessage = nil
            }
        } message: {
            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
            }
        }

    }
    
    // MARK: - Authenticated View
    
    private var authenticatedView: some View {
        ZStack {
            // Dark background
            Color(red: 0.11, green: 0.11, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom toolbar
                modernToolbar
                    .background(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                NavigationSplitView(
                    columnVisibility: $columnVisibility,
                    sidebar: {
                        ChatListView()
                            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
                    },
                    content: {
                        if appState.selectedDialog != nil {
                            MediaListView()
                                .navigationSplitViewColumnWidth(min: 400, ideal: 600)
                        } else {
                            EmptyStateView(
                                icon: "message.fill",
                                title: "main.select_chat_title",
                                message: "main.select_chat_desc"
                            )
                        }
                    },
                    detail: {
                        if !appState.selectedMediaItems.isEmpty {
                            MediaDetailView()
                                .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 450)
                        } else if !appState.activeDownloads.isEmpty {
                            DownloadQueueView()
                                .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 450)
                        } else {
                            EmptyStateView(
                                icon: "video.fill",
                                title: "media.select_media",
                                message: "media.select_media_desc"
                            )
                            .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
                        }
                    }
                )
            }
        }
        .frame(minWidth: 1000, minHeight: 600)
    }
    
    // MARK: - Modern Toolbar
    
    private var modernToolbar: some View {
        HStack(spacing: 16) {
            Spacer()
            
            // Action buttons
            modernToolbarButton(icon: "arrow.clockwise", action: refreshAction)
            modernToolbarButton(icon: "folder", action: selectFolderAction)
            modernToolbarButton(
                icon: "arrow.down.circle.fill",
                action: downloadAllAction,
                isDisabled: appState.selectedMediaItems.isEmpty
            )
            
            Divider()
                .frame(height: 20)
            
            // Profile menu
            Menu {
                if let user = appState.currentUser {
                    Text(user.displayName)
                        .font(.headline)
                    Divider()
                }
                
                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Label("main.settings", systemImage: "gearshape")
                    }
                }
                
                Divider()
                
                Button(role: .destructive, action: { appState.logout() }) {
                    Label("auth.logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private func modernToolbarButton(icon: String, action: @escaping () -> Void, isDisabled: Bool = false) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isDisabled ? Color(red: 0.4, green: 0.4, blue: 0.4) : Color(red: 0.85, green: 0.85, blue: 0.85))
                .frame(width: 32, height: 32)
                .background(isDisabled ? Color.clear : Color(red: 0.2, green: 0.2, blue: 0.22))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    // MARK: - Actions
    
    private func refreshAction() {
        NotificationCenter.default.post(name: .refreshRequested, object: nil)
    }
    
    private func selectFolderAction() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.title = localizationManager.localizedString("main.select_folder_title")
        panel.prompt = localizationManager.localizedString("main.select")
        
        if panel.runModal() == .OK, let url = panel.url {
            appState.setDownloadFolder(url: url)
        }
    }
    
    private func downloadAllAction() {
        appState.startDownloadForSelectedItems()
    }
}

// MARK: - Preview

#Preview("Authenticated") {
    let appState = AppState()
    appState.isAuthenticated = true
    appState.currentUser = TelegramUser(
        id: "123",
        username: "testuser",
        firstName: "Test",
        lastName: "User",
        phoneNumber: "+905551234567",
        profilePhotoPath: nil
    )
    
    return MainView()
        .environmentObject(appState)
        .frame(width: 1200, height: 700)
}

#Preview("Not Authenticated") {
    MainView()
        .environmentObject(AppState())
        .frame(width: 1200, height: 700)
}
