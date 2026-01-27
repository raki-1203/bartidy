//
//  SettingsView.swift
//  Bartidy
//
//  Created by Bartidy Team
//

import SwiftUI

struct SettingsView: View {
    // MARK: - Properties
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInDock") private var showInDock = false
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
    
    // MARK: - Tabs
    
    private var generalTab: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show in Dock", isOn: $showInDock)
            }
            
            Section("Permissions") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Accessibility")
                            .font(.headline)
                        Text("Required to detect and manage menu bar icons")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Open Settings") {
                        openAccessibilitySettings()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private var appearanceTab: some View {
        Form {
            Section {
                Text("Appearance settings coming soon...")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private var aboutTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("Bartidy")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("A simple menu bar organizer for macOS")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Link("GitHub Repository", destination: URL(string: "https://github.com")!)
                .font(.caption)
        }
        .padding(40)
    }
    
    // MARK: - Actions
    
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
