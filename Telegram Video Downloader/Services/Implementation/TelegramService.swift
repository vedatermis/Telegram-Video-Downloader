import Foundation
import TDLibKit

// MARK: - TelegramService Implementation

final class TelegramService: TelegramServiceProtocol {
    
    static let shared = TelegramService()
    
    private let clientManager: TDLibClientManager
    private var client: TDLibClient!
    
    // Auth Continuations
    private var connectContinuation: CheckedContinuation<Bool, Swift.Error>?
    private var sendCodeContinuation: CheckedContinuation<String, Swift.Error>?
    private var verifyCodeContinuation: CheckedContinuation<AuthResult, Swift.Error>?
    private var passwordContinuation: CheckedContinuation<TelegramUser, Swift.Error>?
    
    // Download Handlers: FileID -> ProgressHandler
    private var downloadHandlers: [Int32: (Double, Int64) -> Void] = [:]
    private var downloadContinuations: [Int32: CheckedContinuation<URL, Swift.Error>] = [:]
    
    private var apiId: Int32 = 0
    private var apiHash: String = ""
    private var isTdlibParametersSet = false
    
    private init() {
        self.clientManager = TDLibClientManager()
        createClient()
    }
    
    private func createClient() {
        if let client = client {
            let clientToClose = client
            Task {
                try? await clientToClose.close()
            }
        }
        
        self.client = clientManager.createClient(updateHandler: { [weak self] data, client in
            guard let self = self else { return }
            do {
                let update = try client.decoder.decode(Update.self, from: data)
                // print("Received Update: \(update)") // Too verbose for all updates
                self.handleUpdate(update)
            } catch {
                print("TDLib Update Decode Error: \(error)")
            }
        })
    }
    
    private func handleUpdate(_ update: Update) {
        switch update {
        case .updateAuthorizationState(let state):
            handleAuthState(state.authorizationState)
        case .updateFile(let fileUpdate):
            handleFileUpdate(fileUpdate.file)
        default:
            break
        }
    }
    
    private func handleAuthState(_ state: AuthorizationState) {
        print("Authorization State Changed: \(state)")
        switch state {
        case .authorizationStateWaitTdlibParameters:
            if isTdlibParametersSet { return }
            if apiId == 0 { return }
            isTdlibParametersSet = true
            
            Task {
                do {
                    try await client.setTdlibParameters(
                        apiHash: self.apiHash,
                        apiId: Int(self.apiId),
                        applicationVersion: "1.0.0",
                        databaseDirectory: getDocumentsDirectory().appendingPathComponent("tdlib/db").path,
                        databaseEncryptionKey: nil,
                        deviceModel: "Mac",
                        filesDirectory: getDocumentsDirectory().appendingPathComponent("tdlib/files").path,
                        systemLanguageCode: "en",
                        systemVersion: "14.0",
                        useChatInfoDatabase: true,
                        useFileDatabase: true,
                        useMessageDatabase: true,
                        useSecretChats: true,
                        useTestDc: false
                    )
                    print("TDLib parameters set successfully")
                } catch {
                    print("Failed to set TDLib parameters: \(error)")
                }
            }
            
        case .authorizationStateWaitPhoneNumber:
            print("Received authorizationStateWaitPhoneNumber")
            connectContinuation?.resume(returning: false)
            connectContinuation = nil
            
        case .authorizationStateWaitCode:
            print("Received authorizationStateWaitCode")
            sendCodeContinuation?.resume(returning: "")
            sendCodeContinuation = nil
            
        case .authorizationStateWaitPassword:
            verifyCodeContinuation?.resume(returning: .needPassword)
            verifyCodeContinuation = nil
            
        case .authorizationStateReady:
            // Connect success (already logged in)
            connectContinuation?.resume(returning: true)
            connectContinuation = nil
            
            // Verify code success
            if let continuation = verifyCodeContinuation {
                Task {
                    do {
                        let user = try await getCurrentUser()
                        continuation.resume(returning: .success(user))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                    verifyCodeContinuation = nil
                }
            }
            
            // Verify password success
            if let continuation = passwordContinuation {
                Task {
                    do {
                        let user = try await getCurrentUser()
                        continuation.resume(returning: user)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                    passwordContinuation = nil
                }
            }
            
        case .authorizationStateClosed:
            connectContinuation?.resume(returning: false)
            connectContinuation = nil
            
        default:
            break
        }
    }
    
    private func handleFileUpdate(_ file: File) {
        let fileId = Int32(file.id)
        // Progress update
        if let handler = downloadHandlers[fileId] {
            let total = Int64(file.expectedSize)
            let downloaded = Int64(file.local.downloadedPrefixSize)
            
            if total > 0 {
                let progress = Double(downloaded) / Double(total)
                handler(progress, total)
            }
        }
        
        // Completion update
        if file.local.isDownloadingCompleted {
            if let continuation = downloadContinuations[fileId] {
                let fileURL = URL(fileURLWithPath: file.local.path)
                continuation.resume(returning: fileURL)
                downloadContinuations.removeValue(forKey: fileId)
            }
            downloadHandlers.removeValue(forKey: fileId)
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - TelegramServiceProtocol
    
    func connect(apiId: String, apiHash: String) async throws -> Bool {
        guard let apiIdInt = Int32(apiId) else { throw TelegramError.invalidInput("API ID must be a number") }
        self.apiId = apiIdInt
        self.apiHash = apiHash
        
        // Reset state for new connection attempt if needed
        // self.isTdlibParametersSet = false // Do not reset if client is reused
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Swift.Error>) in
            self.connectContinuation = continuation
            Task {
                do {
                    let state = try await client.getAuthorizationState()
                    switch state {
                    case .authorizationStateWaitTdlibParameters:
                        self.handleAuthState(.authorizationStateWaitTdlibParameters)
                    case .authorizationStateReady, .authorizationStateWaitPhoneNumber:
                        self.handleAuthState(state)
                    default:
                        break
                    }
                } catch {
                    continuation.resume(throwing: error)
                    self.connectContinuation = nil
                }
            }
        }
    }
    
    func sendCode(phoneNumber: String) async throws -> String {
        print("Sending code to: \(phoneNumber)")
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Swift.Error>) in
            self.sendCodeContinuation = continuation
            Task {
                do {
                    try await client.setAuthenticationPhoneNumber(phoneNumber: phoneNumber, settings: nil)
                    print("setAuthenticationPhoneNumber called successfully")
                } catch {
                    print("setAuthenticationPhoneNumber failed: \(error)")
                    continuation.resume(throwing: error)
                    self.sendCodeContinuation = nil
                }
            }
        }
    }
    
    func verifyCode(phoneNumber: String, code: String, codeHash: String) async throws -> AuthResult {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthResult, Swift.Error>) in
            self.verifyCodeContinuation = continuation
            Task {
                do {
                    try await client.checkAuthenticationCode(code: code)
                } catch {
                    continuation.resume(throwing: error)
                    self.verifyCodeContinuation = nil
                }
            }
        }
    }
    
    func verifyPassword(password: String) async throws -> TelegramUser {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TelegramUser, Swift.Error>) in
            self.passwordContinuation = continuation
            Task {
                do {
                    try await client.checkAuthenticationPassword(password: password)
                } catch {
                    continuation.resume(throwing: error)
                    self.passwordContinuation = nil
                }
            }
        }
    }
    
    func logout() async throws {
        try await client.logOut()
    }
    
    func fetchDialogs(limit: Int, offsetId: Int?) async throws -> [TelegramDialog] {
        let chats = try await client.getChats(chatList: .chatListMain, limit: limit)
        
        var dialogs: [TelegramDialog] = []
        for chatId in chats.chatIds {
            let chat = try await client.getChat(chatId: chatId)
            dialogs.append(mapToTelegramDialog(chat))
        }
        return dialogs
    }
    
    func getDialogInfo(dialogId: String) async throws -> TelegramDialog {
        guard let chatId = Int64(dialogId) else { throw TelegramError.invalidInput("Invalid Chat ID") }
        let chat = try await client.getChat(chatId: chatId)
        return mapToTelegramDialog(chat)
    }
    
    func fetchMediaMessages(dialogId: String, filter: AppMediaFilter, limit: Int, offsetId: Int?) async throws -> [TelegramMessage] {
        guard let chatId = Int64(dialogId) else { throw TelegramError.invalidInput("Invalid Chat ID") }
        
        let fromMessageId = Int64(offsetId ?? 0)
        
        if filter == .all {
            let result = try await client.getChatHistory(
                chatId: chatId,
                fromMessageId: fromMessageId,
                limit: limit,
                offset: 0,
                onlyLocal: false
            )
            return try await mapToTelegramMessages(result.messages ?? [], chatId: chatId)
        } else {
            let tdFilter: SearchMessagesFilter
            switch filter {
            case .photo: tdFilter = .searchMessagesFilterPhoto
            case .video: tdFilter = .searchMessagesFilterVideo
            case .document: tdFilter = .searchMessagesFilterDocument
            default: tdFilter = .searchMessagesFilterEmpty
            }
            
            let result = try await client.searchChatMessages(
                chatId: chatId,
                filter: tdFilter,
                fromMessageId: fromMessageId,
                limit: limit,
                offset: 0,
                query: "",
                senderId: nil,
                topicId: nil
            )
            return try await mapToTelegramMessages(result.messages, chatId: chatId)
        }
    }
    
    func getMessage(dialogId: String, messageId: String) async throws -> TelegramMessage {
        guard let chatId = Int64(dialogId), let msgId = Int64(messageId) else { throw TelegramError.invalidInput("Invalid IDs") }
        let message = try await client.getMessage(chatId: chatId, messageId: msgId)
        return try await mapToTelegramMessage(message, chatId: chatId)
    }
    
    func downloadMedia(remoteFileId: String, destinationURL: URL, progressHandler: @escaping (Double, Int64) -> Void) async throws -> URL {
        guard let fileId = Int32(remoteFileId) else { throw TelegramError.invalidInput("Invalid File ID") }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Swift.Error>) in
            // Register handlers before starting download to ensure we don't miss updates
            // Use a lock or serial queue in a real app, but for now we assume main thread or serial execution for simplicity
            // or that race conditions are rare enough for this fix.
            // Better: Dispatch to main queue for dictionary access if possible, or use a lock.
            // For this specific issue (stuck at 0%), checking the result is the most important fix.
            
            self.downloadHandlers[fileId] = progressHandler
            self.downloadContinuations[fileId] = continuation
            
            Task {
                do {
                    let file = try await client.downloadFile(fileId: Int(fileId), limit: 0, offset: 0, priority: 32, synchronous: false)
                    
                    // Check if already completed
                    if file.local.isDownloadingCompleted {
                        print("DEBUG: File \(fileId) is already downloaded at \(file.local.path)")
                        let fileURL = URL(fileURLWithPath: file.local.path)
                        
                        // Call progress handler with 100%
                        progressHandler(1.0, Int64(file.expectedSize))
                        
                        continuation.resume(returning: fileURL)
                        self.downloadHandlers.removeValue(forKey: fileId)
                        self.downloadContinuations.removeValue(forKey: fileId)
                    } else {
                        print("DEBUG: Started download for \(fileId). Expected size: \(file.expectedSize), Downloaded: \(file.local.downloadedPrefixSize)")
                        // Trigger an initial progress update
                        let total = Int64(file.expectedSize)
                        let downloaded = Int64(file.local.downloadedPrefixSize)
                        if total > 0 {
                            progressHandler(Double(downloaded) / Double(total), downloaded)
                        }
                    }
                } catch {
                    print("DEBUG: Failed to start download for \(fileId): \(error)")
                    continuation.resume(throwing: error)
                    self.downloadHandlers.removeValue(forKey: fileId)
                    self.downloadContinuations.removeValue(forKey: fileId)
                }
            }
        }
    }
    
    func cancelDownload(remoteFileId: String) async throws {
        guard let fileId = Int32(remoteFileId) else { return }
        try await client.cancelDownloadFile(fileId: Int(fileId), onlyIfPending: false)
        downloadHandlers.removeValue(forKey: fileId)
        downloadContinuations.removeValue(forKey: fileId)
    }
    
    func pauseDownload(remoteFileId: String) async throws {
        try await cancelDownload(remoteFileId: remoteFileId)
    }
    
    func resumeDownload(remoteFileId: String) async throws {
        guard let fileId = Int32(remoteFileId) else { return }
        _ = try await client.downloadFile(fileId: Int(fileId), limit: 0, offset: 0, priority: 32, synchronous: false)
    }
    
    func getCurrentUser() async throws -> TelegramUser {
        let user = try await client.getMe()
        return mapToTelegramUser(user)
    }
    
    func getMediaStreamURL(remoteFileId: String) async throws -> URL {
        guard let fileId = Int32(remoteFileId) else { throw TelegramError.invalidInput("Invalid File ID") }
        
        // Get file info first
        let file = try await client.getFile(fileId: Int(fileId))
        
        // If already downloaded locally, return local path
        if file.local.isDownloadingCompleted {
            return URL(fileURLWithPath: file.local.path)
        }
        
        // Start download with high priority for streaming
        let result = try await client.downloadFile(fileId: Int(fileId), limit: 0, offset: 0, priority: 32, synchronous: true)
        
        // Return the path once download starts (TDLib will stream it)
        if !result.local.path.isEmpty {
            return URL(fileURLWithPath: result.local.path)
        }
        
        throw TelegramError.invalidInput("Could not get media URL")
    }
    
    func downloadThumbnail(fileId: Int) async throws -> String {
        let file = try await client.downloadFile(fileId: fileId, limit: 0, offset: 0, priority: 32, synchronous: true)
        return file.local.path
    }
    
    // MARK: - Storage Management
    
    /// TDLib depolama istatistiklerini hızlı şekilde getir
    func getStorageStatisticsFast() async throws -> StorageStatisticsFast {
        return try await client.getStorageStatisticsFast()
    }
    
    /// TDLib önbelleğini optimize et (eski dosyaları sil)
    func optimizeStorage() async throws -> StorageStatistics {
        return try await client.optimizeStorage(
            chatIds: nil,
            chatLimit: 0,
            count: -1,
            excludeChatIds: nil,
            fileTypes: nil,
            immunityDelay: 0,
            returnDeletedFileStatistics: true,
            size: 0,
            ttl: 0
        )
    }
    
    /// TDLib dosya dizininin boyutunu hesapla
    func getTDLibFilesSize() -> Int64 {
        let filesDir = getDocumentsDirectory().appendingPathComponent("tdlib/files")
        return calculateDirectorySize(url: filesDir)
    }
    
    /// TDLib veritabanı dizininin boyutunu hesapla
    func getTDLibDatabaseSize() -> Int64 {
        let dbDir = getDocumentsDirectory().appendingPathComponent("tdlib/db")
        return calculateDirectorySize(url: dbDir)
    }
    
    /// TDLib dosya önbelleğini temizle (indirilen medya dosyaları)
    func clearTDLibFileCache() {
        let filesDir = getDocumentsDirectory().appendingPathComponent("tdlib/files")
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: filesDir, includingPropertiesForKeys: nil) else { return }
        for item in contents {
            try? fm.removeItem(at: item)
        }
    }
    
    private func calculateDirectorySize(url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else { return 0 }
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let resources = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resources.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }
    
    // MARK: - Mappers
    
    private func mapToTelegramUser(_ user: User) -> TelegramUser {
        return TelegramUser(
            id: String(user.id),
            username: user.usernames?.activeUsernames.first,
            firstName: user.firstName,
            lastName: user.lastName,
            phoneNumber: user.phoneNumber,
            profilePhotoPath: user.profilePhoto?.small.local.path
        )
    }
    
    private func mapToTelegramDialog(_ chat: Chat) -> TelegramDialog {
        var type: TelegramDialog.DialogType = .privateChat
        switch chat.type {
        case .chatTypePrivate: type = .privateChat
        case .chatTypeBasicGroup: type = .group
        case .chatTypeSupergroup(let sg):
            type = sg.isChannel ? .channel : .supergroup
        case .chatTypeSecret: type = .privateChat
        }
        
        return TelegramDialog(
            id: String(chat.id),
            title: chat.title,
            type: type,
            photoPath: chat.photo?.small.local.path,
            unreadCount: Int(chat.unreadCount),
            lastMessage: chat.lastMessage?.content.textDescription ?? "",
            lastMessageDate: Date(timeIntervalSince1970: TimeInterval(chat.lastMessage?.date ?? 0)),
            memberCount: nil
        )
    }
    
    private func mapToTelegramMessages(_ messages: [Message], chatId: Int64) async throws -> [TelegramMessage] {
        var result: [TelegramMessage] = []
        for msg in messages {
            result.append(try await mapToTelegramMessage(msg, chatId: chatId))
        }
        return result
    }
    
    private func mapToTelegramMessage(_ message: Message, chatId: Int64) async throws -> TelegramMessage {
        var mediaItem: MediaItem?
        var mediaType: TelegramMessage.MediaType?
        
        switch message.content {
        case .messageVideo(let video):
            mediaType = .video
            mediaItem = MediaItem(
                id: String(video.video.video.id),
                messageId: String(message.id),
                fileName: video.video.fileName,
                mimeType: video.video.mimeType,
                fileSize: Int64(video.video.video.size),
                duration: Double(video.video.duration),
                width: Int(video.video.width),
                height: Int(video.video.height),
                thumbnailPath: video.video.thumbnail?.file.local.path,
                thumbnailFileId: video.video.thumbnail?.file.id != nil ? Int(video.video.thumbnail!.file.id) : nil,
                remoteFileId: String(video.video.video.id)
            )
        case .messagePhoto(let photo):
            mediaType = .photo
            if let largest = photo.photo.sizes.last {
                // Use small photo as thumbnail if available
                let thumbnail = photo.photo.sizes.first
                
                mediaItem = MediaItem(
                    id: String(largest.photo.id),
                    messageId: String(message.id),
                    fileName: nil,
                    mimeType: "image/jpeg",
                    fileSize: Int64(largest.photo.size),
                    duration: nil,
                    width: Int(largest.width),
                    height: Int(largest.height),
                    thumbnailPath: thumbnail?.photo.local.path,
                    thumbnailFileId: thumbnail?.photo.id != nil ? Int(thumbnail!.photo.id) : nil,
                    remoteFileId: String(largest.photo.id)
                )
            }
        case .messageDocument(let doc):
            mediaType = .document
            mediaItem = MediaItem(
                id: String(doc.document.document.id),
                messageId: String(message.id),
                fileName: doc.document.fileName,
                mimeType: doc.document.mimeType,
                fileSize: Int64(doc.document.document.size),
                duration: nil,
                width: nil,
                height: nil,
                thumbnailPath: doc.document.thumbnail?.file.local.path,
                thumbnailFileId: doc.document.thumbnail?.file.id != nil ? Int(doc.document.thumbnail!.file.id) : nil,
                remoteFileId: String(doc.document.document.id)
            )
        default:
            break
        }
        
        return TelegramMessage(
            id: String(message.id),
            dialogId: String(chatId),
            senderId: String(message.senderId.getSenderId()),
            senderName: nil,
            text: message.content.textDescription,
            date: Date(timeIntervalSince1970: TimeInterval(message.date)),
            mediaType: mediaType,
            mediaItem: mediaItem
        )
    }
}

private extension MessageSender {
    func getSenderId() -> Int64 {
        switch self {
        case .messageSenderUser(let user): return user.userId
        case .messageSenderChat(let chat): return chat.chatId
        }
    }
}

private extension MessageContent {
    var textDescription: String {
        switch self {
        case .messageText(let text): return text.text.text
        case .messageVideo(let video): return video.caption.text
        case .messagePhoto(let photo): return photo.caption.text
        case .messageDocument(let doc): return doc.caption.text
        default: return ""
        }
    }
}

// MARK: - Custom Error

enum TelegramError: LocalizedError {
    case notConnected
    case authenticationFailed(String?)
    case downloadFailed(String?)
    case mappingFailed(String)
    case invalidInput(String?)
    case apiError(String)
    case notImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected: 
            return "Telegram client is not connected."
        case .authenticationFailed(let reason): 
            return "Failed to authenticate user. \(reason ?? "")"
        case .downloadFailed(let reason): 
            return "File download failed. \(reason ?? "")"
        case .mappingFailed(let description): 
            return "Failed to map model: \(description)"
        case .invalidInput(let reason): 
            return "Invalid input provided. \(reason ?? "")"
        case .apiError(let message): 
            return "Telegram API Error: \(message)"
        case .notImplemented(let feature): 
            return "\(feature) is not implemented."
        }
    }
}
