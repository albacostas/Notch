//
//  SpotifyTabContent.swift
//  notch
//
//  Created by Alba Costas Fernández on 23/3/26.
//

import SwiftUI
/*
struct SpotifyTabContent: View {
    @ObservedObject var spotify : SpotifyManager

    var body: some View {
        
        // Fondo de color dominante de la caratula
        ZStack{
            if spotify.dominantColor != .clear {
                Rectangle()
                    .fill(spotify.dominantColor)
                    .opacity(0.8)
                    .blur(radius: 30)
            }
        }
        HStack(alignment: .center, spacing: 14) {

            // Carátula
            Group {
                if let art = spotify.albumArt {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.15))
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.green.opacity(0.6))
                                .font(.system(size: 22))
                        )
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: spotify.dominantColor.opacity(0.6), radius: 8) // Sombra del color
            // Info + controles
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(spotify.trackName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(spotify.artistName)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }

                HStack(spacing: 18) {
                    Button(action: { spotify.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)

                    Button(action: { spotify.playPause() }) {
                        Image(systemName: spotify.isPlaying
                              ? "pause.circle.fill"
                              : "play.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)

                    Button(action: { spotify.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        //.padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.6),value: spotify.dominantColor.description)
    }
}
*/
struct SpotifyTabContent: View {
    @ObservedObject var spotify: SpotifyManager

    var body: some View {
        ZStack {
            // Fondo difuminado
            if spotify.dominantColor != .clear {
                Rectangle()
                    .fill(spotify.dominantColor)
                    .opacity(0.4)
                    .blur(radius: 30)
            }
            
            HStack(alignment: .center, spacing: 30) {
                
                // Carátula con tamaño fijo
                Group {
                    if let art = spotify.albumArt {
                        Image(nsImage: art)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.white.opacity(0.4))
                                    .font(.system(size: 26))
                            )
                    }
                }
               
                .frame(width: 130, height: 130) // Tamaño fijo para que no desborde
                .clipShape(RoundedRectangle(cornerRadius: 10))
                // La sombra ahora será proporcional al tamaño fijo
                //.shadow(color: spotify.dominantColor.opacity(0.6), radius: 8, x: 0, y: 4)
                .padding(.leading, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    // Nombre y artista
                    VStack(alignment: .leading, spacing: 2) {
                        Text(spotify.trackName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(spotify.artistName)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    .frame(width: 150, alignment: .leading)
                    
                    // Barra de reproduccion
                    VStack(spacing: 4){
                        /*Slider(value: $spotify.currentPosition, in: 0...max(1, spotify.duration)) { editing in
                            spotify.isDraggingSlider = editing
                            if !editing{
                                spotify.seek(to: spotify.currentPosition)
                            }
                        }
                        .controlSize(.mini)
                        .accentColor(spotify.dominantColor)
                        */
                        VStack(spacing: 4) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Carril de fondo (la barra gris)
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 3) // Aquí controlas el grosor de la barra

                                    // Progreso real (la barra de color)
                                    Capsule()
                                        .fill(spotify.dominantColor)
                                        .frame(width: geometry.size.width * CGFloat(spotify.currentPosition / max(1, spotify.duration)), height: 3)

                                    // El "Punto" (Thumb)
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 8, height: 8) // Aquí controlas el tamaño del punto
                                        .offset(x: geometry.size.width * CGFloat(spotify.currentPosition / max(1, spotify.duration)) - 4)
                                        .shadow(radius: 2)
                                }
                                .contentShape(Rectangle()) // Área de toque
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            spotify.isDraggingSlider = true
                                            let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                                            spotify.currentPosition = Double(percentage) * spotify.duration
                                        }
                                        .onEnded { _ in
                                            spotify.seek(to: spotify.currentPosition)
                                            spotify.isDraggingSlider = false
                                        }
                                )
                            }
                            .frame(height: 8) // Altura del contenedor de la barra
                            .padding(.horizontal, 15)
                            
                            // Tiempos (0:00 / 3:45)
                            HStack {
                                Text(spotify.formatTime(spotify.currentPosition))
                                Spacer()
                                Text(spotify.formatTime(spotify.duration))
                            }
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 15)
                        }
                        .frame(width: 150)
                        
                    }
                    .frame(width: 120) 
                    // Controles
                    HStack(spacing: 30) {
                        Button(action: { spotify.previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                        
                        //Spacer()
                        
                        Button(action: { spotify.playPause() }) {
                            Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                        
                        //Spacer()
                        
                        Button(action: { spotify.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundColor(.white)
                    //.frame(maxWidth: 80) // Limita el ancho de los controles
                }
            }
            .padding(.horizontal, 12)
        }
        // Evita que cualquier efecto (como sombras o blur) se salga del contenedor principal
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: spotify.trackName)
    }
}
