//
//  EmptyStateView.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// Boş durum gösterimi için yeniden kullanılabilir view
struct EmptyStateView: View {
    
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    @State private var isHovering = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.1),
                                Color.blue.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.secondary, Color.secondary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text(localizationManager.localizedString(title))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                
                Text(localizationManager.localizedString(message))
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 0.65, green: 0.65, blue: 0.67))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                    .lineSpacing(4)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Text(localizationManager.localizedString(actionTitle))
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(8)
                    .shadow(color: Color.blue.opacity(isHovering ? 0.4 : 0.2), radius: 8, x: 0, y: 4)
                    .scaleEffect(isHovering ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHovering = hovering
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
    }
}

// MARK: - Preview

#Preview {
    EmptyStateView(
        icon: "video.fill",
        title: "Video Yok",
        message: "Bu sohbette henüz video yok",
        actionTitle: "Yenile",
        action: {}
    )
    .frame(width: 400, height: 300)
}
