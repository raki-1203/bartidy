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
        // NSStatusItem position: higher value = further left in menubar.
        // Positions MUST be written to UserDefaults BEFORE setting autosaveName,
        // because macOS reads positions at the moment autosaveName is assigned.
        let chevronKey = "NSStatusItem Preferred Position Bartidy_Chevron"
        let dividerKey = "NSStatusItem Preferred Position Bartidy_Divider"
        
        let chevronPos = UserDefaults.standard.object(forKey: chevronKey) as? CGFloat
        let dividerPos = UserDefaults.standard.object(forKey: dividerKey) as? CGFloat
        
        if let cp = chevronPos, let dp = dividerPos {
            if dp <= cp {
                UserDefaults.standard.set(cp + 1, forKey: dividerKey)
            }
        } else if chevronPos == nil && dividerPos == nil {
            UserDefaults.standard.set(CGFloat(0), forKey: chevronKey)
            UserDefaults.standard.set(CGFloat(1), forKey: dividerKey)
        } else if let cp = chevronPos {
            UserDefaults.standard.set(cp + 1, forKey: dividerKey)
        } else if let dp = dividerPos {
            UserDefaults.standard.set(max(dp - 1, 0), forKey: chevronKey)
        }
        
        chevronItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        dividerItem = NSStatusBar.system.statusItem(withLength: 0)
        
        chevronItem.autosaveName = "Bartidy_Chevron"
        dividerItem.autosaveName = "Bartidy_Divider"
        
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
