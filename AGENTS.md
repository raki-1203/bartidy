# AGENTS.md - Bartidy (macOS Menubar Organizer)

> A Bartender 5-like menubar organization app for macOS, built with Swift/SwiftUI.

## Project Overview

**Bartidy** is a native macOS application that helps users organize and hide menubar icons.
Built with Swift and SwiftUI, targeting macOS 13.0+ (Ventura and later).

---

## Build & Run Commands

### Xcode Project

```bash
# Open in Xcode
open Bartidy.xcodeproj

# Build from command line
xcodebuild -scheme Bartidy -configuration Debug build

# Build for release
xcodebuild -scheme Bartidy -configuration Release build

# Clean build
xcodebuild -scheme Bartidy clean
```

### Swift Package Manager (if applicable)

```bash
# Build
swift build

# Build release
swift build -c release

# Clean
swift package clean
```

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme Bartidy -destination 'platform=macOS'

# Run specific test class
xcodebuild test -scheme Bartidy -destination 'platform=macOS' \
  -only-testing:BartidyTests/MenuBarManagerTests

# Run single test method
xcodebuild test -scheme Bartidy -destination 'platform=macOS' \
  -only-testing:BartidyTests/MenuBarManagerTests/testIconVisibility

# Using swift test (SPM)
swift test

# Run single test
swift test --filter MenuBarManagerTests.testIconVisibility
```

---

## Linting & Formatting

### SwiftLint

```bash
# Run linter
swiftlint

# Auto-fix violations
swiftlint --fix

# Lint specific file
swiftlint lint --path Sources/Bartidy/MenuBarManager.swift
```

### SwiftFormat

```bash
# Format all Swift files
swiftformat .

# Check formatting (CI mode)
swiftformat --lint .

# Format specific file
swiftformat Sources/Bartidy/Views/SettingsView.swift
```

---

## Code Style Guidelines

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Types (class, struct, enum, protocol) | PascalCase | `MenuBarManager`, `IconState` |
| Variables & Properties | camelCase | `isHidden`, `menuBarItems` |
| Functions & Methods | camelCase | `toggleVisibility()`, `fetchIcons()` |
| Constants | camelCase | `let maxIconCount = 20` |
| Enum cases | camelCase | `case hidden, visible, alwaysShow` |
| Protocol names | PascalCase + adjective/-able | `Configurable`, `IconManaging` |

### File Organization

```
Bartidy/
├── App/
│   ├── BartidyApp.swift          # App entry point
│   └── AppDelegate.swift         # NSApplicationDelegate
├── Models/
│   ├── MenuBarIcon.swift
│   └── IconConfiguration.swift
├── Views/
│   ├── MenuBarView.swift
│   ├── SettingsView.swift
│   └── Components/
├── ViewModels/
│   └── MenuBarViewModel.swift
├── Services/
│   ├── MenuBarManager.swift
│   ├── AccessibilityService.swift
│   └── PersistenceService.swift
├── Utilities/
│   └── Extensions/
└── Resources/
    └── Assets.xcassets
```

### Import Order

```swift
// 1. Foundation/System frameworks
import Foundation
import AppKit
import SwiftUI

// 2. Third-party dependencies
import Sparkle
import KeyboardShortcuts

// 3. Local modules (if any)
import BartidyCore
```

### SwiftUI View Structure

```swift
struct SettingsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        content
            .onAppear { viewModel.load() }
    }
    
    // MARK: - Subviews
    private var content: some View {
        // ...
    }
}
```

### Error Handling

```swift
// Use Result type for async operations
func fetchMenuBarIcons() async -> Result<[MenuBarIcon], MenuBarError> {
    // ...
}

// Use throws for synchronous operations
func saveConfiguration() throws {
    guard isValid else {
        throw ConfigurationError.invalidState
    }
    // ...
}

// Define typed errors
enum MenuBarError: LocalizedError {
    case accessibilityDenied
    case iconNotFound(bundleId: String)
    
    var errorDescription: String? {
        switch self {
        case .accessibilityDenied:
            return "Accessibility permission required"
        case .iconNotFound(let bundleId):
            return "Icon not found: \(bundleId)"
        }
    }
}
```

### MARK Comments

```swift
// MARK: - Properties
// MARK: - Lifecycle
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Actions
```

---

## macOS Menubar App Specifics

### NSStatusItem Setup

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Configure menu and icon
    }
}
```

### Accessibility Permissions

This app requires **Accessibility** permissions to read and manipulate other apps' menubar icons.

```swift
// Check accessibility permission
func checkAccessibility() -> Bool {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
    return AXIsProcessTrustedWithOptions(options)
}
```

### Launch at Login

Use `ServiceManagement` framework for login item registration:

```swift
import ServiceManagement

func setLaunchAtLogin(_ enabled: Bool) {
    try? SMAppService.mainApp.register()  // or unregister()
}
```

---

## Testing Guidelines

### Unit Tests

```swift
@testable import Bartidy

final class MenuBarManagerTests: XCTestCase {
    var sut: MenuBarManager!
    
    override func setUp() {
        super.setUp()
        sut = MenuBarManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testIconVisibility() {
        // Given
        let icon = MenuBarIcon(bundleId: "com.example.app")
        
        // When
        sut.hide(icon)
        
        // Then
        XCTAssertTrue(icon.isHidden)
    }
}
```

### UI Tests

```swift
final class BartidyUITests: XCTestCase {
    func testSettingsWindowOpens() {
        let app = XCUIApplication()
        app.launch()
        
        // Click status item and open settings
        // ...
    }
}
```

---

## Dependencies

### Recommended Libraries

| Library | Purpose | Installation |
|---------|---------|--------------|
| [Sparkle](https://sparkle-project.org/) | Auto-updates | SPM |
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | Global shortcuts | SPM |
| [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) | Login item | SPM |
| [Defaults](https://github.com/sindresorhus/Defaults) | UserDefaults wrapper | SPM |

---

## Common Pitfalls

1. **Accessibility API requires permission** - Always check `AXIsProcessTrusted()` before calling accessibility APIs
2. **NSStatusItem must be retained** - Store as instance property, not local variable
3. **Main thread for UI** - All AppKit/SwiftUI updates must be on `@MainActor`
4. **Sandboxing limitations** - Accessibility features may require disabling App Sandbox

---

## Git Workflow

```bash
# Commit message format
feat: add icon drag-and-drop reordering
fix: resolve crash when hiding system icons
refactor: extract MenuBarManager to separate module
docs: update README with installation instructions
```

---

## Resources

- [Apple Human Interface Guidelines - Menu Bar](https://developer.apple.com/design/human-interface-guidelines/menu-bar)
- [NSStatusItem Documentation](https://developer.apple.com/documentation/appkit/nsstatusitem)
- [Accessibility API Guide](https://developer.apple.com/documentation/accessibility)
