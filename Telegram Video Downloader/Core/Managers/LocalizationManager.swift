//
//  LocalizationManager.swift
//  TeleGrab
//
//  Created by Vedat ERMIS on 20.11.2025.
//

import SwiftUI
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: "appLanguage")
        }
    }
    
    private init() {
        self.language = UserDefaults.standard.string(forKey: "appLanguage") ?? 
                       Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    var locale: Locale {
        return Locale(identifier: language)
    }
    
    func setLanguage(_ lang: String) {
        language = lang
    }
    
    func localizedString(_ key: String) -> String {
        return LocalizedStrings.shared.string(for: key, language: language)
    }
}
