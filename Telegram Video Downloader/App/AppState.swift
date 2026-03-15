//
//  AppState.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI
import Combine

/// Uygulama genelinde paylaşılan state yönetimi
/// Authentication durumu, seçili sohbet, indirmeler vb. için merkezi state
@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Kullanıcı authenticate olmuş mu?
    @Published var isAuthenticated: Bool = false
    
    /// Aktif kullanıcı bilgisi
    @Published var currentUser: TelegramUser?
    
    /// Seçili sohbet/kanal
    @Published var selectedDialog: TelegramDialog?
    
    /// Şu anki sohbetteki medya listesi
    @Published var currentMediaList: [TelegramMessage] = []
    
    /// Seçili medya item'ları (çoklu seçim için)
    @Published var selectedMediaItems: Set<String> = []
    
    /// Aktif indirmeler
    @Published var activeDownloads: [DownloadItem] = []
    
    /// Hata mesajı (alert için)
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - AppStorage Properties
    
    /// İndirme hedef klasörü
    @AppStorage("downloadFolderPath") var downloadFolderPath: String = ""
    
    /// İndirme hedef klasörü bookmark verisi (Sandbox erişimi için)
    @AppStorage("downloadFolderBookmark") var downloadFolderBookmark: Data = Data()
    
    /// Dark mode tercihi
    @AppStorage("prefersDarkMode") var prefersDarkMode: Bool = true
    
    /// Otomatik indirme chunk size (MB)
    @AppStorage("chunkSizeMB") var chunkSizeMB: Int = 2
    
    /// Eş zamanlı indirme sayısı
    @AppStorage("maxConcurrentDownloads") var maxConcurrentDownloads: Int = 3
    
    /// İndirilen dosyaların ID'leri (kalıcı saklama)
    @AppStorage("downloadedMediaIds") private var downloadedMediaIdsData: Data = Data()
    
    /// İndirilen medya ID'leri
    var downloadedMediaIds: Set<String> {
        get {
            guard let ids = try? JSONDecoder().decode(Set<String>.self, from: downloadedMediaIdsData) else {
                return Set<String>()
            }
            return ids
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            downloadedMediaIdsData = data
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupDefaultDownloadFolder()
        checkExistingSession()
    }
    
    // MARK: - Private Methods
    
    /// Varsayılan indirme klasörünü ayarla
    private func setupDefaultDownloadFolder() {
        if downloadFolderPath.isEmpty {
            let downloadsPath = FileManager.default.urls(
                for: .downloadsDirectory,
                in: .userDomainMask
            ).first
            
            let appFolder = downloadsPath?.appendingPathComponent("TG Media Backup")
            downloadFolderPath = appFolder?.path ?? ""
            
            // Klasör yoksa oluştur
            if let path = appFolder {
                try? FileManager.default.createDirectory(
                    at: path,
                    withIntermediateDirectories: true
                )
            }
        }
    }
    
    /// Mevcut oturum var mı kontrol et
    private func checkExistingSession() {
        Task {
            // API Credentials kontrolü
            guard let apiId = KeychainHelper.shared.getApiId(),
                  let apiHash = KeychainHelper.shared.getApiHash() else {
                await MainActor.run {
                    self.isAuthenticated = false
                }
                return
            }
            
            do {
                // Telegram servisine bağlanmayı dene
                // connect returns true if we reached a state where we can interact (Ready or WaitPhoneNumber)
                let isConnected = try await TelegramService.shared.connect(apiId: apiId, apiHash: apiHash)
                
                if isConnected {
                    // Kullanıcı bilgilerini almayı dene - eğer başarılıysa login olmuşuz demektir
                    do {
                        let user = try await TelegramService.shared.getCurrentUser()
                        await MainActor.run {
                            self.currentUser = user
                            self.isAuthenticated = true
                        }
                    } catch {
                        // Kullanıcı bilgisi alınamadıysa (örn: WaitPhoneNumber state), login değiliz
                        print("User fetch failed, likely not logged in: \(error)")
                        await MainActor.run {
                            self.isAuthenticated = false
                        }
                    }
                } else {
                    await MainActor.run {
                        self.isAuthenticated = false
                    }
                }
            } catch {
                print("Session check failed: \(error)")
                await MainActor.run {
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Kullanıcı giriş yaptı
    func didAuthenticate(user: TelegramUser) {
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    /// Logout işlemi
    func logout() {
        Task {
            // Session'ı temizle
            await KeychainHelper.shared.clearSession()
            
            // State'i resetle
            await MainActor.run {
                isAuthenticated = false
                currentUser = nil
                selectedDialog = nil
                selectedMediaItems.removeAll()
                activeDownloads.removeAll()
            }
        }
    }
    
    /// Hata göster
    func showError(_ message: String) {
        self.errorMessage = message
        self.showError = true
    }
    
    /// Seçili medya item'ları toggle
    func toggleMediaSelection(_ itemId: String) {
        if selectedMediaItems.contains(itemId) {
            selectedMediaItems.remove(itemId)
        } else {
            selectedMediaItems.insert(itemId)
        }
    }
    
    /// Tüm seçimleri temizle
    func clearSelection() {
        selectedMediaItems.removeAll()
    }
    
    /// İndirme item'ı ekle
    func addDownload(_ item: DownloadItem) {
        activeDownloads.append(item)
    }
    
    /// İndirme item'ını güncelle
    func updateDownload(_ item: DownloadItem) {
        if let index = activeDownloads.firstIndex(where: { $0.id == item.id }) {
            activeDownloads[index] = item
        }
    }
    
    /// Tamamlanan indirmeleri temizle
    func clearCompletedDownloads() {
        activeDownloads.removeAll { $0.status == .completed }
    }
    
    /// Seçili medyaları indirmeye başla
    func startDownloadForSelectedItems() {
        print("DEBUG: startDownloadForSelectedItems called")
        
        // Güvenli URL'i al
        guard let destinationFolder = getSecureDownloadFolder() else {
            print("DEBUG: Could not resolve secure download folder")
            errorMessage = "İndirme klasörüne erişilemiyor. Lütfen klasörü tekrar seçin."
            showError = true
            return
        }
        
        print("DEBUG: downloadFolderPath: \(destinationFolder.path)")
        print("DEBUG: selectedMediaItems count: \(selectedMediaItems.count)")
        print("DEBUG: currentMediaList count: \(currentMediaList.count)")
        
        // Seçili itemları bul
        let itemsToDownload = currentMediaList.filter { message in
            guard let mediaId = message.mediaItem?.id else { return false }
            return selectedMediaItems.contains(mediaId)
        }
        print("DEBUG: itemsToDownload count: \(itemsToDownload.count)")
        
        for message in itemsToDownload {
            guard let mediaItem = message.mediaItem else {
                print("DEBUG: No mediaItem for message \(message.id)")
                continue
            }
            
            // Zaten indirme listesinde mi?
            if activeDownloads.contains(where: { $0.id == mediaItem.id }) {
                print("DEBUG: Already downloading \(mediaItem.id)")
                continue
            }
            
            let downloadItem = DownloadItem(
                id: mediaItem.id,
                messageId: message.id,
                mediaItem: mediaItem,
                dialogTitle: selectedDialog?.title ?? "Unknown",
                status: .pending,
                progress: 0,
                downloadedBytes: 0,
                error: nil,
                localURL: nil,
                startDate: Date(),
                endDate: nil
            )
            
            activeDownloads.append(downloadItem)
            print("DEBUG: Added download item \(downloadItem.id)")
        }
        
        // İndirme kuyruğunu işle
        Task {
            await processDownloadQueue()
        }
        
        // Seçimi temizle
        clearSelection()
    }
    
    /// İndirme kuyruğunu işle
    func processDownloadQueue() async {
        let effectiveMaxConcurrent = maxConcurrentDownloads
        
        let downloadingCount = activeDownloads.filter { $0.status == .downloading }.count
        let slotsAvailable = effectiveMaxConcurrent - downloadingCount
        
        guard slotsAvailable > 0 else { return }
        
        // Pending olanları bul (sırayla)
        for index in activeDownloads.indices {
            if activeDownloads[index].status == .pending {
                // Slot var mı?
                if activeDownloads.filter({ $0.status == .downloading }).count < effectiveMaxConcurrent {
                    let item = activeDownloads[index]
                    
                    // Status güncelle
                    activeDownloads[index].status = .downloading
                    activeDownloads[index].startDate = Date()
                    
                    // İndirmeyi başlat
                    Task {
                        await downloadMedia(item: item)
                    }
                } else {
                    break
                }
            }
        }
    }
    
    private func downloadMedia(item: DownloadItem) async {
        print("DEBUG: downloadMedia called for \(item.id)")
        
        // Klasörü al
        guard let folder = getSecureDownloadFolder() else {
            if let index = activeDownloads.firstIndex(where: { $0.id == item.id }) {
                activeDownloads[index].status = .failed
                activeDownloads[index].error = "İndirme klasörüne erişilemiyor"
                activeDownloads[index].endDate = Date()
            }
            Task {
                await processDownloadQueue()
            }
            return
        }
        
        let destinationURL = folder.appendingPathComponent(item.targetFileName)
        print("DEBUG: Destination URL: \(destinationURL.path)")
        
        // İşlem bitince kuyruğu tekrar kontrol et
        defer {
            Task { @MainActor in
                await self.processDownloadQueue()
            }
        }
        
        do {
            let tempUrl = try await TelegramService.shared.downloadMedia(
                remoteFileId: item.mediaItem.remoteFileId,
                destinationURL: destinationURL
            ) { progress, downloadedBytes in
                Task { @MainActor in
                    if let index = self.activeDownloads.firstIndex(where: { $0.id == item.id }) {
                        self.activeDownloads[index].progress = progress
                        self.activeDownloads[index].downloadedBytes = downloadedBytes
                    }
                }
            }
            print("DEBUG: Download finished at temp URL: \(tempUrl.path)")
            
            // Move file to destination with security scope access
            let didStartAccessing = folder.startAccessingSecurityScopedResource()
            print("DEBUG: startAccessingSecurityScopedResource returned: \(didStartAccessing)")
            
            defer {
                if didStartAccessing {
                    folder.stopAccessingSecurityScopedResource()
                    print("DEBUG: stopAccessingSecurityScopedResource called")
                }
            }
            
            if !didStartAccessing {
                print("DEBUG: Failed to access security scoped resource. Check App Sandbox entitlements.")
            }
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: tempUrl, to: destinationURL)
            print("DEBUG: File moved to destination")
            
            // Success
            if let index = activeDownloads.firstIndex(where: { $0.id == item.id }) {
                activeDownloads[index].status = .completed
                activeDownloads[index].progress = 1.0
                activeDownloads[index].localURL = destinationURL
                activeDownloads[index].endDate = Date()
                
                // Mark as downloaded
                var ids = downloadedMediaIds
                ids.insert(item.mediaItem.id)
                downloadedMediaIds = ids
            }
            
        } catch {
            print("DEBUG: Download error: \(error)")
            // Error
            if let index = activeDownloads.firstIndex(where: { $0.id == item.id }) {
                // Eğer iptal edildiyse status zaten cancelled olmuştur, dokunma
                if activeDownloads[index].status != .cancelled {
                    activeDownloads[index].status = .failed
                    activeDownloads[index].error = error.localizedDescription
                    activeDownloads[index].endDate = Date()
                }
            }
        }
    }
    
    /// İndirmeyi iptal et
    func cancelDownload(_ item: DownloadItem) {
        Task {
            try? await TelegramService.shared.cancelDownload(remoteFileId: item.mediaItem.remoteFileId)
            await MainActor.run {
                if let index = activeDownloads.firstIndex(where: { $0.id == item.id }) {
                    activeDownloads[index].status = .cancelled
                    Task {
                        await processDownloadQueue()
                    }
                }
            }
        }
    }
    
    /// İndirmeyi duraklat
    func pauseDownload(_ item: DownloadItem) {
        Task {
            try? await TelegramService.shared.pauseDownload(remoteFileId: item.mediaItem.remoteFileId)
            await MainActor.run {
                if let index = activeDownloads.firstIndex(where: { $0.id == item.id }) {
                    activeDownloads[index].status = .paused
                    Task {
                        await processDownloadQueue()
                    }
                }
            }
        }
    }
    
    /// İndirmeyi devam ettir
    func resumeDownload(_ item: DownloadItem) {
        if let index = activeDownloads.firstIndex(where: { $0.id == item.id }) {
            activeDownloads[index].status = .pending
            Task {
                await processDownloadQueue()
            }
        }
    }
    
    /// İndirmeyi tekrar dene
    func retryDownload(_ item: DownloadItem) {
        resumeDownload(item)
    }
    
    /// İndirmeyi listeden sil
    func removeDownload(_ item: DownloadItem) {
        if let index = activeDownloads.firstIndex(where: { $0.id == item.id }) {
            let itemToRemove = activeDownloads[index]
            
            // Eğer indiriliyorsa iptal et
            if itemToRemove.status == .downloading {
                Task {
                    try? await TelegramService.shared.cancelDownload(remoteFileId: itemToRemove.mediaItem.remoteFileId)
                }
            }
            
            activeDownloads.remove(at: index)
            Task {
                await processDownloadQueue()
            }
        }
    }
    
    /// İndirme klasörüne yazma izni var mı kontrolü
    var isDownloadFolderWritable: Bool {
        guard !downloadFolderPath.isEmpty else { return false }
        return FileManager.default.isWritableFile(atPath: downloadFolderPath)
    }
    
    /// İndirme klasörünü ayarla ve bookmark oluştur
    func setDownloadFolder(url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            downloadFolderBookmark = bookmarkData
            downloadFolderPath = url.path
        } catch {
            print("Failed to create bookmark: \(error)")
            // Fallback to just path if bookmark fails (though it likely won't work for sandbox)
            downloadFolderPath = url.path
        }
    }
    
    /// Güvenli indirme klasörü URL'ini getir
    func getSecureDownloadFolder() -> URL? {
        guard !downloadFolderBookmark.isEmpty else { return nil }
        
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: downloadFolderBookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("Bookmark is stale")
                // In a real app, we might want to ask the user to re-select
            }
            return url
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }
}
