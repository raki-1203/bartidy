//
//  MenuBarIconRow.swift
//  Bartidy
//
//  Created by Bartidy Team
//

import SwiftUI

struct MenuBarIconRow: View {
    // MARK: - Properties
    
    let icon: MenuBarIcon
    var onVisibilityChange: ((IconVisibility) -> Void)? = nil
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            iconImage
            
            VStack(alignment: .leading, spacing: 2) {
                Text(icon.appName)
                    .font(.system(size: 13, weight: .medium))
                
                Text(icon.bundleIdentifier)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            visibilityToggle
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Subviews
    
    private var iconImage: some View {
        Group {
            if let image = icon.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.fill")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 20, height: 20)
    }
    
    private var visibilityToggle: some View {
        Picker("", selection: Binding(
            get: { icon.visibility },
            set: { onVisibilityChange?($0) }
        )) {
            ForEach(IconVisibility.allCases, id: \.self) { visibility in
                Label(visibility.displayName, systemImage: visibility.systemImage)
                    .tag(visibility)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 120)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        MenuBarIconRow(icon: MenuBarIcon(
            bundleIdentifier: "com.apple.controlcenter",
            appName: "Control Center",
            visibility: .alwaysShow
        ))
        
        MenuBarIconRow(icon: MenuBarIcon(
            bundleIdentifier: "com.spotify.client",
            appName: "Spotify",
            visibility: .alwaysHidden
        ))
    }
    .padding()
    .frame(width: 320)
}
