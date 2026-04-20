//
//  AppDelegate.swift
//  Bartidy
//

import AppKit
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {

    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.isAlreadyRunning() else {
            NSApplication.shared.terminate(nil)
            return
        }

        _ = MenuBarManager.shared
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
    
    private static func isAlreadyRunning() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1
    }
}
