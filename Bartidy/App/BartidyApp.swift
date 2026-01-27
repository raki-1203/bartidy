//
//  BartidyApp.swift
//  Bartidy
//
//  Created by Bartidy Team
//

import SwiftUI

@main
struct BartidyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
