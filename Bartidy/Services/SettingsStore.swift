import Foundation

class SettingsStore {
    static let shared = SettingsStore()
    
    private let userDefaults = UserDefaults.standard
    private let iconVisibilityKey = "iconVisibilitySettings"
    
    private var visibilityCache: [String: String] = [:]
    
    private init() {
        loadSettings()
    }
    
    func getVisibility(for bundleId: String) -> IconVisibility {
        if let rawValue = visibilityCache[bundleId],
           let visibility = IconVisibility(rawValue: rawValue) {
            return visibility
        }
        return .alwaysShow
    }
    
    func setVisibility(for bundleId: String, visibility: IconVisibility) {
        visibilityCache[bundleId] = visibility.rawValue
        saveSettings()
    }
    
    private func loadSettings() {
        if let savedSettings = userDefaults.dictionary(forKey: iconVisibilityKey) as? [String: String] {
            visibilityCache = savedSettings
        }
    }
    
    private func saveSettings() {
        userDefaults.set(visibilityCache, forKey: iconVisibilityKey)
    }
}
