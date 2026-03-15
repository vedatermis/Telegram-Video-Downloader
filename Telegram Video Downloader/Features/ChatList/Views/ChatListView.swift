//
//  ChatListView.swift
//  TeleGrab
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// Telegram sohbet listesi görünümü
/// Sol sidebar'da gösterilir
struct ChatListView: View {
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ChatListViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern search bar
            modernSearchBar
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(red: 0.13, green: 0.13, blue: 0.14))
            
            // Chat list
            content
        }
        .background(Color(red: 0.13, green: 0.13, blue: 0.14))
        .navigationTitle(Text("chat.title"))
        .task {
            await viewModel.loadChats()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshRequested)) { _ in
            Task {
                await viewModel.loadChats()
            }
        }
        
    }
    
    // MARK: - Modern Search Bar
    
    private var modernSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.62))
            
            TextField("chat.search_placeholder", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(red: 0.18, green: 0.18, blue: 0.20))
        .cornerRadius(8)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.chats.isEmpty {
            LoadingView(message: "chat.loading")
        } else if let error = viewModel.error {
            ErrorView(error: error) {
                Task { await viewModel.loadChats() }
            }
        } else if viewModel.filteredChats.isEmpty {
            EmptyStateView(
                icon: "message.fill",
                title: "chat.no_chats",
                message: viewModel.searchText.isEmpty ?
                "chat.no_chats_desc" :
                    String(format: localizationManager.localizedString("chat.no_results_for"), viewModel.searchText)
            )
        } else {
            chatList
        }
    }
    
    // MARK: - Chat List
    
    private var chatList: some View {
        List(viewModel.filteredChats, selection: $appState.selectedDialog) { dialog in
            ChatRowView(dialog: dialog)
                .tag(dialog)
        }
        .listStyle(.sidebar)
    }
    
    // MARK: - Preview
    
}
