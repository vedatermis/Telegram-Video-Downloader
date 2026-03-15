//
//  TGMediaBackupApp.swift
//  TG Media Backup - macOS Media Backup Tool
//
//  Created by Vedat ERMIS on 30.10.2025.
//
//  ⚠️ UYARI: Bu uygulama Telegram'ın resmi API'lerini kullanır.
//  Telegram'ın hizmet şartlarına uygun şekilde kullanılmalıdır.
//  Kısıtlanmış içerikleri indirmeden önce yasal durumu kontrol edin.
//

import SwiftUI

/// Ana uygulama entry point'i
/// macOS için optimize edilmiş, modern SwiftUI tabanlı media backup aracı
@main
struct TGMediaBackupApp: App {
    
    /// Uygulama genelinde paylaşılan state
    @StateObject private var appState = AppState()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .environment(\.locale, localizationManager.locale)
                .frame(minWidth: 1000, minHeight: 600)
                .preferredColorScheme(.dark) // Force dark mode
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // macOS menü komutları
            CommandGroup(replacing: .newItem) {
                Button("Yenile") {
                    NotificationCenter.default.post(name: .refreshRequested, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Klasör Seç") {
                    NotificationCenter.default.post(name: .selectFolderRequested, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .toolbar) {
                Button("Tümünü İndir") {
                    NotificationCenter.default.post(name: .downloadAllRequested, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
                .disabled(!appState.isAuthenticated)
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let refreshRequested = Notification.Name("refreshRequested")
    static let selectFolderRequested = Notification.Name("selectFolderRequested")
    static let downloadAllRequested = Notification.Name("downloadAllRequested")
}
