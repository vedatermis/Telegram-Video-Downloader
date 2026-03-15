//
//  ErrorView.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// Hata durumu için yeniden kullanılabilir view
struct ErrorView: View {
    
    let error: Error
    let retryAction: (() -> Void)?
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    init(error: Error, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            VStack(spacing: 8) {
                Text("error.title")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Label("error.retry", systemImage: "arrow.clockwise")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Preview

#Preview {
    ErrorView(
        error: NSError(
            domain: "TGMediaBackup",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Bağlantı kurulamadı"]
        ),
        retryAction: {}
    )
    .frame(width: 400, height: 300)
}
