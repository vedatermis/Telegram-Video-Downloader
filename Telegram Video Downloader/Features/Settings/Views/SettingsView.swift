//
//  SettingsView.swift
//  TeleGrab
//
//  Created by Vedat ERMIS on 20.11.2025.
//

import SwiftUI

/// Uygulama ayarları görünümü
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var thumbnailCacheSize: String = LocalizationManager.shared.localizedString("common.calculating")
    @State private var tdlibCacheSize: String = LocalizationManager.shared.localizedString("common.calculating")
    @State private var tdlibDbSize: String = LocalizationManager.shared.localizedString("common.calculating")
    @State private var isOptimizing = false
    @State private var showLogoutAlert = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Hesap Kartı
                if let user = appState.currentUser {
                    HStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Text(String(user.firstName.prefix(1)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accentColor)
                        }
                        
                        // Bilgiler
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(user.firstName) \(user.lastName ?? "")")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            if let phone = user.phoneNumber {
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Çıkış Butonu
                        Button(action: { showLogoutAlert = true }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                                .font(.system(size: 16, weight: .medium))
                                .padding(10)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help("auth.logout")
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                    )
                }
                
                // MARK: - Ayarlar Grubu
                VStack(spacing: 0) {
                    // Dil Seçimi
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.language")
                                    .font(.body)
                            }
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundStyle(.blue)
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        Picker("", selection: $localizationManager.language) {
                            Text("language.turkish").tag("tr")
                            Text("language.english").tag("en")
                        }
                        .frame(width: 120)
                    }
                    .padding()
                    
                    Divider()
                        .padding(.leading, 50)

                    // İndirme Limiti
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.concurrent_downloads")
                                    .font(.body)
                                Text("settings.concurrent_downloads_desc")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "arrow.down.circle")
                                .foregroundStyle(.blue)
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Text("\(appState.maxConcurrentDownloads)")
                                .monospacedDigit()
                                .frame(width: 20)
                            Stepper("", value: $appState.maxConcurrentDownloads, in: 1...10)
                                .labelsHidden()
                        }
                    }
                    .padding()
                    
                    Divider()
                        .padding(.leading, 50)
                    
                    // Thumbnail Önbellek
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.thumbnail_cache")
                                    .font(.body)
                                Text(thumbnailCacheSize)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "photo.stack")
                                .foregroundStyle(.purple)
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        Button("common.clear") {
                            clearThumbnailCache()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding()
                    
                    Divider()
                        .padding(.leading, 50)
                    
                    // TDLib Dosya Önbellek
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.tdlib_cache")
                                    .font(.body)
                                Text(tdlibCacheSize)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "externaldrive")
                                .foregroundStyle(.orange)
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        Button("common.clear") {
                            clearTDLibCache()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isOptimizing)
                    }
                    .padding()
                    
                    Divider()
                        .padding(.leading, 50)
                    
                    // TDLib Veritabanı
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.tdlib_database")
                                    .font(.body)
                                Text(tdlibDbSize)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "cylinder.split.1x2")
                                .foregroundStyle(.green)
                                .font(.title2)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
            }
            .padding(20)
        }
        .frame(width: 480, height: 700)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            updateCacheSize()
        }
        .onChange(of: localizationManager.language) { _ in
            updateCacheSize()
        }
        .alert("auth.logout", isPresented: $showLogoutAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("auth.logout", role: .destructive) {
                appState.logout()
            }
        } message: {
            Text("auth.logout_confirmation")
        }

    }
    
    private func updateCacheSize() {
        thumbnailCacheSize = ThumbnailManager.shared.getCacheSize()
        tdlibCacheSize = ThumbnailManager.shared.getTDLibCacheSize()
        tdlibDbSize = ThumbnailManager.shared.getTDLibDatabaseSize()
    }
    
    private func clearThumbnailCache() {
        ThumbnailManager.shared.clearCache()
        updateCacheSize()
    }
    
    private func clearTDLibCache() {
        isOptimizing = true
        TelegramService.shared.clearTDLibFileCache()
        Task {
            try? await TelegramService.shared.optimizeStorage()
            await MainActor.run {
                isOptimizing = false
                updateCacheSize()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
