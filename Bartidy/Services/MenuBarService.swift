import AppKit
import Accessibility

// MARK: - MenuBarService Error

enum MenuBarServiceError: LocalizedError {
    case accessibilityDenied
    case failedToFetchIcons
    case invalidApplication
    
    var errorDescription: String? {
        switch self {
        case .accessibilityDenied:
            return "Accessibility permission is required to access menubar icons"
        case .failedToFetchIcons:
            return "Failed to fetch menubar icons"
        case .invalidApplication:
            return "Invalid application reference"
        }
    }
}

// MARK: - MenuBarService

final class MenuBarService {
    // MARK: - Singleton
    
    static let shared = MenuBarService()
    
    // MARK: - Constants
    
    private let menuBarWindowLayer: Int32 = 25
    private let menuBarHeight: CGFloat = 30.0
    
    // MARK: - Private Properties
    
    private init() {}
    
    // MARK: - Public Methods
    
    func isAccessibilityEnabled() -> Bool {
        return AXIsProcessTrusted()
    }
    
    func requestAccessibility() -> Bool {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func fetchMenuBarIcons() -> Result<[MenuBarIcon], MenuBarServiceError> {
        guard isAccessibilityEnabled() else {
            return .failure(.accessibilityDenied)
        }
        
        var icons: [MenuBarIcon] = []
        var seenBundleIds = Set<String>()
        
        guard let mainScreen = NSScreen.main else {
            return .failure(.failedToFetchIcons)
        }
        
        let menuBarFrame = CGRect(
            x: 0,
            y: 0,
            width: mainScreen.frame.width,
            height: menuBarHeight
        )
        
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return .failure(.failedToFetchIcons)
        }
        
        for windowInfo in windowList {
            guard let windowLayer = windowInfo[kCGWindowLayer as String] as? Int32 else {
                continue
            }
            
            guard windowLayer == menuBarWindowLayer else {
                continue
            }
            
            guard let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = boundsDict["X"],
                  let y = boundsDict["Y"],
                  let width = boundsDict["Width"],
                  let height = boundsDict["Height"] else {
                continue
            }
            
            let windowFrame = CGRect(x: x, y: y, width: width, height: height)
            
            guard windowFrame.minY < menuBarHeight else {
                continue
            }
            
            guard let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? pid_t,
                  let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
                  let windowNumber = windowInfo[kCGWindowNumber as String] as? UInt32 else {
                continue
            }
            
            guard let app = NSRunningApplication(processIdentifier: ownerPID) else {
                continue
            }
            
            let bundleIdentifier = app.bundleIdentifier ?? "com.unknown.\(ownerPID)"
            
            if seenBundleIds.contains(bundleIdentifier) {
                continue
            }
            seenBundleIds.insert(bundleIdentifier)
            
            if shouldSkipApplication(bundleIdentifier: bundleIdentifier, ownerName: ownerName) {
                continue
            }
            
            let icon = MenuBarIcon(
                bundleIdentifier: bundleIdentifier,
                appName: app.localizedName ?? ownerName,
                visibility: .alwaysShow,
                position: CGPoint(x: windowFrame.minX, y: windowFrame.minY),
                size: CGSize(width: windowFrame.width, height: windowFrame.height),
                ownerPID: ownerPID,
                windowID: windowNumber,
                image: app.icon
            )
            
            icons.append(icon)
        }
        
        icons.sort { $0.position.x < $1.position.x }
        
        return .success(icons)
    }
    
    // MARK: - Private Methods
    
    private func shouldSkipApplication(bundleIdentifier: String, ownerName: String) -> Bool {
        let skipBundleIds = [
            "com.apple.controlcenter",
            "com.apple.Spotlight",
            "com.apple.notificationcenterui",
        ]
        
        let skipOwnerNames = [
            "Spotlight",
            "Notification Center",
        ]
        
        return skipBundleIds.contains(bundleIdentifier) || skipOwnerNames.contains(ownerName)
    }
}
