//
//  ControlItem.swift
//  Bartidy
//
//  Hiding mechanism based on dwarvesf/Hidden Bar pattern:
//  - Two NSStatusItems: chevron (toggle) + divider (expands to hide)
//  - User Cmd-drags icons to the LEFT of the chevron to mark them for hiding
//  - Divider sits immediately left of chevron; expanding it pushes left-side items off-screen
//  - Position validation before collapse prevents "all icons disappearing" bug

import AppKit
import SwiftUI

@MainActor
final class ControlItem {
    
    enum HidingState {
        case hideItems
        case showItems
    }
    
    enum Lengths {
        static let collapsed: CGFloat = 20
        static let expanded: CGFloat = 10_000
    }

    private static let chevronShowImage: NSImage? = NSImage(
        systemSymbolName: "chevron.down",
        accessibilityDescription: "Show menu bar icons"
    )

    private static let chevronHideImage: NSImage? = NSImage(
        systemSymbolName: "chevron.left",
        accessibilityDescription: "Hide menu bar icons"
    )
    
    // MARK: - Properties
    
    private let chevronItem: NSStatusItem
    private let dividerItem: NSStatusItem
    private(set) var state: HidingState = .showItems
    private var settingsWindow: NSWindow?
    private let settingsWindowDelegate = HideOnCloseWindowDelegate()
    
    // MARK: - Initialization
    
    init() {
        Self.migrateFromBrokenPositions()
        
        chevronItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        dividerItem = NSStatusBar.system.statusItem(withLength: Lengths.collapsed)
        
        chevronItem.autosaveName = "Bartidy_Chevron"
        dividerItem.autosaveName = "Bartidy_Divider"
        
        setupButton()
        setupDivider()
        updateAppearance()
    }
    
    // MARK: - Migration
    
    /// Clear position data corrupted by v5/v6 migrations that forced positions to 0/1.
    /// After clearing, macOS assigns natural positions via autosaveName.
    private static func migrateFromBrokenPositions() {
        let defaults = UserDefaults.standard
        let migrationKey = "Bartidy_PositionMigration_v7"
        
        guard !defaults.bool(forKey: migrationKey) else { return }
        
        defaults.removeObject(forKey: "NSStatusItem Preferred Position Bartidy_Chevron")
        defaults.removeObject(forKey: "NSStatusItem Preferred Position Bartidy_Divider")
        defaults.removeObject(forKey: "NSStatusItem Visible Bartidy_Chevron")
        defaults.removeObject(forKey: "NSStatusItem Visible Bartidy_Divider")
        defaults.set(true, forKey: migrationKey)
    }
    
    // MARK: - Position Validation
    
    private var isDividerLeftOfChevron: Bool {
        guard
            let chevronX = chevronItem.button?.window?.frame.origin.x,
            let dividerX = dividerItem.button?.window?.frame.origin.x
        else { return false }
        
        return chevronX > dividerX
    }
    
    // MARK: - Public Methods
    
    func toggle() {
        state = (state == .showItems) ? .hideItems : .showItems
        updateAppearance()
    }
    
    func show() {
        guard state != .showItems else { return }
        state = .showItems
        updateAppearance()
    }
    
    func hide() {
        guard state != .hideItems else { return }
        state = .hideItems
        updateAppearance()
    }
    
    // MARK: - Private Methods
    
    private func setupButton() {
        guard let button = chevronItem.button else { return }
        button.target = self
        button.action = #selector(performAction)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    private func setupDivider() {
        guard let button = dividerItem.button else { return }
        button.title = "│"
        button.appearsDisabled = true
    }
    
    @objc private func performAction() {
        guard let event = NSApp.currentEvent else { return }
        
        switch event.type {
        case .leftMouseUp:
            toggle()
        case .rightMouseUp:
            showMenu()
        default:
            break
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let updateItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Bartidy", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        if let button = chevronItem.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        }
    }
    
    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)

        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Bartidy Settings"
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView())
        window.isReleasedWhenClosed = false
        window.delegate = settingsWindowDelegate
        window.makeKeyAndOrderFront(nil)
        settingsWindow = window
    }

    @objc private func checkForUpdates() {
        NSApp.activate(ignoringOtherApps: true)
        (NSApp.delegate as? AppDelegate)?.updaterController.checkForUpdates(nil)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func updateAppearance() {
        guard let chevronButton = chevronItem.button else { return }
        
        switch state {
        case .hideItems:
            guard isDividerLeftOfChevron else {
                state = .showItems
                return
            }
            
            dividerItem.length = Lengths.expanded
            
            if let dividerButton = dividerItem.button {
                dividerButton.image = nil
                dividerButton.cell?.isEnabled = false
                dividerButton.isHighlighted = false
            }
            
            chevronButton.image = Self.chevronShowImage

        case .showItems:
            dividerItem.length = Lengths.collapsed

            if let dividerButton = dividerItem.button {
                dividerButton.cell?.isEnabled = true
                dividerButton.title = "│"
            }

            chevronButton.image = Self.chevronHideImage
        }
    }
}

/// Hide the window on close instead of releasing it. SwiftUI's App
/// lifecycle treats a closed last-window as a termination signal even
/// when applicationShouldTerminateAfterLastWindowClosed returns false.
final class HideOnCloseWindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
