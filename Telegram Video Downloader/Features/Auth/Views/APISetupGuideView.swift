//
//  APISetupGuideView.swift
//  TG Media Backup
//
//  Created by Vedat ERMIS on 30.10.2025.
//

import SwiftUI

/// API kurulum rehberi
/// Kullanıcıya my.telegram.org'dan API ID ve Hash alma adımlarını gösterir
struct APISetupGuideView: View {
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                    
                    Divider()
                    
                    // Steps
                    VStack(alignment: .leading, spacing: 20) {
                        stepView(
                            number: 1,
                            title: "guide.step1_title",
                            description: "guide.step1_desc",
                            action: {
                                NSWorkspace.shared.open(URL(string: "https://my.telegram.org")!)
                            }
                        )
                        
                        stepView(
                            number: 2,
                            title: "guide.step2_title",
                            description: "guide.step2_desc"
                        )
                        
                        stepView(
                            number: 3,
                            title: "guide.step3_title",
                            description: "guide.step3_desc"
                        )
                        
                        stepView(
                            number: 4,
                            title: "guide.step4_title",
                            description: "guide.step4_desc"
                        )
                        
                        stepView(
                            number: 5,
                            title: "guide.step5_title",
                            description: "guide.step5_desc"
                        )
                    }
                    
                    Divider()
                    
                    // Warning
                    warningSection
                }
                .padding(24)
            }
            .navigationTitle(Text("guide.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("guide.close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 700)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("guide.header_title")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("guide.header_desc")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("guide.header_info")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Step View
    
    @ViewBuilder
    private func stepView(
        number: Int,
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Number circle
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let action = action {
                    Button(action: action) {
                        Label("guide.open_browser", systemImage: "arrow.up.right.square")
                            .font(.subheadline)
                    }
                    .buttonStyle(.link)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Warning Section
    
    private var warningSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("guide.warning_title")
                    .font(.headline)
                
                Text("guide.warning_desc")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    APISetupGuideView()
}
