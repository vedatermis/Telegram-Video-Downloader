//
//  LoadingView.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// Yükleniyor durumu için yeniden kullanılabilir view
struct LoadingView: View {
    
    let message: LocalizedStringKey?
    
    init(message: LocalizedStringKey? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .scaleEffect(1.2)
            
            if let message = message {
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Preview

#Preview {
    LoadingView(message: "Sohbetler yükleniyor...")
        .frame(width: 400, height: 300)
}
