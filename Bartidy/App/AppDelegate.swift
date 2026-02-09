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
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        return running.count > 1
    }
}
