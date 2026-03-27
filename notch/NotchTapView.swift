//
//  NotchTapView.swift
//  notch
//
//  Created by Alba Costas Fernández on 23/3/26.
//

import SwiftUI

enum NotchTab {
    case notes
    case spotify
}

struct NotchTabView: View {
    @State private var activeTab: NotchTab = .notes
    @State private var isExpanded = false
    @FocusState private var inputFocused: Bool
    @StateObject private var spotify = SpotifyManager()
    let controller: NotchWindowController
    
    private let notesHeight: CGFloat = 220
    private let spotifyHeight: CGFloat = 220
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isExpanded ? 20 : 10)
                .fill(Color.black)
            
            if isExpanded {
                expandedView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                collapsedView
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        .onHover { hovering in
            if hovering && !isExpanded {
                isExpanded = true
                let height = activeTab == .notes ? notesHeight : spotifyHeight
                controller.expand(height: height)
                if activeTab == .notes {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        inputFocused = true
                    }
                }
            } else if !hovering && isExpanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    if !self.isMouseInsideWindow() {
                        self.isExpanded = false
                        self.controller.collapse()
                    }
                }
            }
        }
    }
    
    // Vista colapsada: icono dinámico según tab activo
    var collapsedView: some View {
        HStack(spacing: 6) {
            Image(systemName: activeTab == .notes ? "note.text" : "music.note")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(activeTab == .notes ? .yellow : .green)
            Text(activeTab == .notes ? "Quick Notes" : "Spotify")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 12)
    }
    
    private func isMouseInsideWindow() -> Bool {
        guard let window = controller.window else { return false }
        let mouseLocation = NSEvent.mouseLocation
        return window.frame.contains(mouseLocation)
    }
    
    
    // Vista expandida: tabs + contenido
    var expandedView: some View {
        VStack(spacing: 0) {
            
            HStack(spacing: 0) {
                TabButton(icon: "note.text", label: "Notas",
                          isActive: activeTab == .notes, color: .yellow) {
                    withAnimation(.spring(response: 0.25)) { activeTab = .notes }
                    controller.resize(height: notesHeight)
                }
                TabButton(icon: "music.note", label: "Música",
                          isActive: activeTab == .spotify, color: .green) {
                    withAnimation(.spring(response: 0.25)) { activeTab = .spotify }
                    controller.resize(height: spotifyHeight)
                }
                Spacer()
                Button(action: {
                    isExpanded = false
                    controller.collapse()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 14)
            }
            .frame(height: 44)
            
            Divider().background(Color.white.opacity(0.1))
            
            Group {
                if activeTab == .notes {
                    NotesTabContent(inputFocused: $inputFocused)
                        
                } else {
                    SpotifyTabContent(spotify: spotify)
                }
            }
            //.animation(.spring(response: 0.3, dampingFraction: 0.85), value: activeTab)
            
            //Spacer(minLength: 0) // ← empuja contenido hacia arriba
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        // ← SIN padding top en el VStack
        .frame(maxHeight: .infinity, alignment: .top) // ← ancla todo arriba
    }
}



// MARK: - Botón de tab reutilizable
struct TabButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(label)
                    .font(.system(size: 12, weight: isActive ? .semibold : .regular))
            }
            .foregroundColor(isActive ? color : .white.opacity(0.4))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? color.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.leading, 8)
    }
}
