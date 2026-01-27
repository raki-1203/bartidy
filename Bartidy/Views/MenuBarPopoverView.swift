//
//  MenuBarPopoverView.swift
//  Bartidy
//
//  Created by Bartidy Team
//

import SwiftUI

struct MenuBarPopoverView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = MenuBarViewModel()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
            
            contentView
            
            Divider()
            
            footerView
        }
        .frame(width: 320, height: 400)
        .onAppear {
            viewModel.checkAccessibility()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text("Bartidy")
                .font(.headline)
            
            Spacer()
            
            Button(action: { viewModel.toggleHidden() }) {
                Image(systemName: viewModel.isHidden ? "eye" : "eye.slash")
            }
            .buttonStyle(.borderless)
            
            Button(action: {
                viewModel.checkAccessibility()
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if viewModel.menuBarIcons.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.menuBarIcons) { icon in
                        MenuBarIconRow(icon: icon) { newVisibility in
                            viewModel.setVisibility(for: icon, visibility: newVisibility)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "menubar.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No menu bar icons detected")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Accessibility: \(viewModel.isAccessibilityGranted ? "Granted" : "Not Granted")")
                .font(.caption)
                .foregroundColor(viewModel.isAccessibilityGranted ? .green : .red)
            
            if !viewModel.isAccessibilityGranted {
                Text("Grant Accessibility permission in System Settings to detect and manage menu bar icons.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Open System Settings") {
                    viewModel.openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Permission granted but no icons found. Try clicking Refresh.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
    }
    
    private var footerView: some View {
        HStack {
            Button(action: {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
            
            Spacer()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    MenuBarPopoverView()
}
