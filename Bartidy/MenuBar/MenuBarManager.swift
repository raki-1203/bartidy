//
//  MenuBarManager.swift
//  Bartidy
//
//  Created by Bartidy on 2024.
//

import AppKit

/// Singleton manager for the control item that manages menubar icon visibility.
@MainActor
final class MenuBarManager {
    // MARK: - Singleton
    
    static let shared = MenuBarManager()
    
    // MARK: - Properties
    
    private let controlItem: ControlItem
    
    var isHidden: Bool { controlItem.state == .hideItems }
    
    // MARK: - Initialization
    
    private init() {
        controlItem = ControlItem()
    }
    
    // MARK: - Public Methods
    
    /// Toggle between hiding and showing menubar items
    func toggle() {
        controlItem.toggle()
    }
    
    /// Show menubar items
    func show() {
        controlItem.show()
    }
    
    /// Hide menubar items
    func hide() {
        controlItem.hide()
    }
}
