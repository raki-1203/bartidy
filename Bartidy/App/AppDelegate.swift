//
//  AppDelegate.swift
//  Bartidy
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.isAlreadyRunning() else {
            NSApplication.shared.terminate(nil)
            return
        }
        
        _ = MenuBarManager.shared
    }
    
    private static func isAlreadyRunning() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1
    }
}
