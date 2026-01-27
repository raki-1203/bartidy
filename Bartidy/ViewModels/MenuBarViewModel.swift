import AppKit
import SwiftUI
import Combine

func logToFile(_ message: String) {
    let logPath = NSHomeDirectory() + "/bartidy_debug.log"
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let logMessage = "[\(timestamp)] \(message)\n"
    if let data = logMessage.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logPath) {
            if let handle = FileHandle(forWritingAtPath: logPath) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            FileManager.default.createFile(atPath: logPath, contents: data)
        }
    }
}

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published var menuBarIcons: [MenuBarIcon] = []
    @Published var isAccessibilityGranted = false
    
    init() {
        logToFile("MenuBarViewModel init called")
        checkAccessibility()
    }
    
    func checkAccessibility() {
        isAccessibilityGranted = AXIsProcessTrusted()
        print("[Bartidy] AXIsProcessTrusted: \(isAccessibilityGranted)")
        if isAccessibilityGranted {
            refreshIcons()
        }
    }
    
     func refreshIcons() {
         let result = MenuBarService.shared.fetchMenuBarIcons()
         switch result {
         case .success(var icons):
             print("[Bartidy] Found \(icons.count) icons")
             for i in 0..<icons.count {
                 icons[i].visibility = SettingsStore.shared.getVisibility(for: icons[i].bundleIdentifier)
             }
             menuBarIcons = icons
         case .failure(let error):
             print("[Bartidy] Failed to fetch icons: \(error)")
             menuBarIcons = []
         }
     }
    
    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
    
     func setVisibility(for icon: MenuBarIcon, visibility: IconVisibility) {
         logToFile("setVisibility called for \(icon.appName) -> \(visibility.rawValue)")
         guard let index = menuBarIcons.firstIndex(where: { $0.id == icon.id }) else {
             logToFile("Icon not found in array!")
             return
         }
         menuBarIcons[index].visibility = visibility
         SettingsStore.shared.setVisibility(for: icon.bundleIdentifier, visibility: visibility)
         logToFile("Visibility updated for \(icon.appName)")
     }
    
     
    var isHidden: Bool {
        MenuBarManager.shared.isHidden
    }
    
    func toggleHidden() {
        MenuBarManager.shared.toggle()
        objectWillChange.send()
    }
}
