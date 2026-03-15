//
//  Logger.swift
//  TG Media Backup
//
//  Created for production logging
//

import Foundation

enum Logger {
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("🐛 [\(fileName):\(line)] \(function) - \(message)")
        #endif
    }
    
    static func info(_ message: String) {
        #if DEBUG
        print("ℹ️ \(message)")
        #endif
    }
    
    static func warning(_ message: String) {
        #if DEBUG
        print("⚠️ \(message)")
        #endif
    }
    
    static func error(_ message: String, error: Error? = nil) {
        #if DEBUG
        if let error = error {
            print("❌ \(message): \(error.localizedDescription)")
        } else {
            print("❌ \(message)")
        }
        #endif
    }
}
