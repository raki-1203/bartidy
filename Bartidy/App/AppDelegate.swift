//
//  AppDelegate.swift
//  Bartidy
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = MenuBarManager.shared
    }
}
