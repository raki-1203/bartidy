//
//  ControlItem.swift
//  Bartidy
//

import AppKit

@MainActor
final class ControlItem {
    
    enum HidingState {
        case hideItems
        case showItems
    }
    
    enum Lengths {
        static let expanded: CGFloat = 10_000
    }
    
    private let chevronItem: NSStatusItem
    private let dividerItem: NSStatusItem
    private(set) var state: HidingState = .showItems
    
    init() {
        chevronItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        dividerItem = NSStatusBar.system.statusItem(withLength: 0)
        
        // CRITICAL: Set preferred positions BEFORE assigning autosaveName
        // LOWER values = closer to Control Center (RIGHT side of menubar)
        // HIGHER values = more to the LEFT
        // Chevron must have LOWER value than Divider to stay visible when Divider expands
        // (Ice uses: Chevron=0, Divider=1)
        let chevronKey = "NSStatusItem Preferred Position Bartidy_Chevron"
        if UserDefaults.standard.object(forKey: chevronKey) == nil {
            UserDefaults.standard.set(0, forKey: chevronKey)  // Rightmost (like Ice)
        }
        
        let dividerKey = "NSStatusItem Preferred Position Bartidy_Divider"
        if UserDefaults.standard.object(forKey: dividerKey) == nil {
            UserDefaults.standard.set(1, forKey: dividerKey)  // To the left of chevron
        }
        
        // NOW assign autosaveName (system reads UserDefaults at this moment)
        dividerItem.autosaveName = "Bartidy_Divider"
        chevronItem.autosaveName = "Bartidy_Chevron"
        
        setupButton()
        updateAppearance()
    }
    
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
    
    private func setupButton() {
        guard let button = chevronItem.button else { return }
        button.target = self
        button.action = #selector(performAction)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
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
        let quitItem = NSMenuItem(title: "Quit Bartidy", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        if let button = chevronItem.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func updateAppearance() {
        guard let button = chevronItem.button else { return }
        
        switch state {
        case .hideItems:
            dividerItem.length = Lengths.expanded
            button.image = NSImage(
                systemSymbolName: "chevron.down",
                accessibilityDescription: "Show menu bar icons"
            )
            
        case .showItems:
            dividerItem.length = 0
            button.image = NSImage(
                systemSymbolName: "chevron.left",
                accessibilityDescription: "Hide menu bar icons"
            )
        }
    }
}
