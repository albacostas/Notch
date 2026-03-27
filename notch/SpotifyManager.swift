import AppKit
import SwiftUI
import Combine

class SpotifyManager: ObservableObject {
    @Published var dominantColor: Color = .clear
    
    // Nombre cancion y artisa
    @Published var trackName: String = "Abre Spotify"
    @Published var artistName: String = ""
    @Published var albumArt: NSImage? = nil
    
    // Controles
    @Published var isPlaying: Bool = false
    @Published var isSpotifyRunning: Bool = false

    // Barra de reproducción
    @Published var duration: Double = 0
    @Published var currentPosition: Double = 0
    @Published var isDraggingSlider: Bool = false
    private var progressTimer: Timer?
    
    
    private var clientID: String {
            guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
                  let data = try? Data(contentsOf: url),
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                return ""
            }
            return plist["SPOTIFY_CLIENT_ID"] as? String ?? ""
        }

        private var clientSecret: String {
            guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
                  let data = try? Data(contentsOf: url),
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                return ""
            }
            return plist["SPOTIFY_CLIENT_SECRET"] as? String ?? ""
        }
    private var accessToken: String? = nil
    private var tokenExpiry: Date? = nil
    private var timer: Timer?
    private var lastTrackID: String = ""
    
    init() {
        startPolling()
    }
    
    func startPolling() {
        // Timer principal para la info de la cancion
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.fetchCurrentTrack()
        }
        
        // Timer para barra de progreso
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.isPlaying && !self.isDraggingSlider {
                self.fetchCurrentPosition()

            }
        }
    }
    /*
    func fetchCurrentTrack() {
        assert(Thread.isMainThread)
        
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    set tid to id of current track
                    set tname to name of current track
                    set tartist to artist of current track
                    set tduration to duration of current track
                    set tposition to player position
                    return "PLAYING|" & tid & "|" & tname & "|" & tartist & "|" & tduration & "|" & tposition
                else if player state is paused then
                    set tid to id of current track
                    set tname to name of current track
                    set tartist to artist of current track
                    set tduration to duration of current track
                    set tposition to player position
                    return "PAUSED|" & tid & "|" & tname & "|" & tartist & "|" & tduration & "|" & tposition
                end if
            end tell
        else
            return "STOPPED"
        end if
        """
        
        var error: NSDictionary?
        guard let scriptObj = NSAppleScript(source: script) else { return }
        let descriptor = scriptObj.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript error: \(error)")
            self.isSpotifyRunning = false
            return
        }
        
        let result = descriptor.stringValue ?? "STOPPED"
        
        if result == "STOPPED" {
            self.isSpotifyRunning = false
            self.trackName = "Abre Spotify"
            self.artistName = ""
            return
        }
        
        self.isSpotifyRunning = true
        
        let parts = result.split(separator: "|", maxSplits: 5).map(String.init)
        guard parts.count == 6 else { return }
        
        let state = parts[0]
        self.isPlaying = state == "PLAYING"
        
        let trackID = parts[1].replacingOccurrences(of: "spotify:track:", with: "")
        self.trackName = parts[2]
        self.artistName = parts[3]
        
        if let durMs = Double(parts[4]){
            self.duration = durMs / 1000.0
        }
        
        if let posSec = Double(parts[5]), !isDraggingSlider {
            self.currentPosition = posSec
        }
        if trackID != self.lastTrackID {
            self.lastTrackID = trackID
            self.fetchAlbumArt(trackID: trackID)
        }
    }*/
    
    
    func fetchCurrentTrack() {
        // El script ahora pide: estado|id|nombre|artista|duración|posición
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                try
                    set tid to id of current track
                    set tname to name of current track
                    set tartist to artist of current track
                    set tduration to duration of current track
                    set tposition to player position
                    set tstate to player state as string
                    return tstate & "|" & tid & "|" & tname & "|" & tartist & "|" & tduration & "|" & tposition
                on error
                    return "STOPPED"
                end try
            end tell
        else
            return "STOPPED"
        end if
        """
        
        let result = runScript(script)
        
        if result == "STOPPED" || result == "" {
            DispatchQueue.main.async {
                self.isSpotifyRunning = false
                self.trackName = "Abre Spotify"
            }
            return
        }
        
        let parts = result.split(separator: "|").map(String.init)
        guard parts.count >= 6 else { return }
        
        DispatchQueue.main.async {
            self.isSpotifyRunning = true
            self.isPlaying = parts[0].lowercased().contains("playing")
            
            let trackID = parts[1].replacingOccurrences(of: "spotify:track:", with: "")
            self.trackName = parts[2]
            self.artistName = parts[3]
            
            // Spotify da la duración en milisegundos, la pasamos a segundos
            if let durMs = Double(parts[4]) {
                self.duration = durMs / 1000.0
            }
            
            // Solo actualizamos la posición si el usuario no está moviendo la barra
            if let posSec = Double(parts[5]), !self.isDraggingSlider {
                self.currentPosition = posSec
            }
            
            if trackID != self.lastTrackID {
                self.lastTrackID = trackID
                self.fetchAlbumArt(trackID: trackID)
            }
        }
    }

    func extractDominantColor(from image: NSImage) {
        // 1. Redimensionar a una escala muy pequeña para ganar velocidad y promediar ruido
        let thumbSize = NSSize(width: 50, height: 50)
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(thumbSize.width),
            pixelsHigh: Int(thumbSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: NSRect(origin: .zero, size: thumbSize), from: .zero, operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        // 2. Analizar píxeles
        var colorCounts: [NSColor: Int] = [:]
        
        for y in 0..<Int(thumbSize.height) {
            for x in 0..<Int(thumbSize.width) {
                guard let color = bitmap.colorAt(x: x, y: y) else { continue }
                
                // Filtro: Ignorar colores muy oscuros, muy claros o muy grises (baja saturación)
                let brightness = color.brightnessComponent
                let saturation = color.saturationComponent
                
                if brightness > 0.15 && brightness < 0.85 && saturation > 0.15 {
                    // Redondeamos el color para agrupar similares
                    let roundedColor = NSColor(
                        calibratedRed: round(color.redComponent * 10) / 10,
                        green: round(color.greenComponent * 10) / 10,
                        blue: round(color.blueComponent * 10) / 10,
                        alpha: 1.0
                    )
                    colorCounts[roundedColor, default: 0] += 1
                }
            }
        }

        // 3. Seleccionar el color dominante que no sea "aburrido"
        let sortedColors = colorCounts.sorted { $0.value > $1.value }
        
        if let bestColor = sortedColors.first?.key {
            DispatchQueue.main.async {
                // Convertimos NSColor a SwiftUI Color
                self.dominantColor = Color(bestColor)
            }
        }
    }
    
    
    // MARK: - Controles
    func playPause() {
        runScriptOnMain("tell application \"Spotify\" to playpause")
        self.isPlaying.toggle()
    }
    
    func nextTrack() {
        runScriptOnMain("tell application \"Spotify\" to next track")
    }
    
    func previousTrack() {
        runScriptOnMain("tell application \"Spotify\" to previous track")
    }
    
    // MARK: - Barra
    
    // Función ligera para actualizar solo el segundero
    func fetchCurrentPosition() {
            let script = "tell application \"Spotify\" to get player position"
            let pos = Double(runScript(script)) ?? self.currentPosition
            DispatchQueue.main.async {
                self.currentPosition = pos
            }
        }
    
    // Función para ejecutar scripts que devuelven un String
    private func runScript(_ source: String) -> String {
        var error: NSDictionary?
        if let scriptObj = NSAppleScript(source: source) {
            let descriptor = scriptObj.executeAndReturnError(&error)
            if let err = error {
                print("AppleScript error: \(err)")
                return ""
            }
            return descriptor.stringValue ?? ""
        }
        return ""
    }
    func seek(to seconds: Double){
        let script = "tell application \"Spotify\" to set player position to \(seconds)"
        runScriptOnMain(script)
    }
    func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func runScriptOnMain(_ source: String) {
        DispatchQueue.main.async {
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
            if let error = error { print("Control error: \(error)") }
        }
    }
    
    // MARK: - Token
    func getAccessToken(completion: @escaping (String?) -> Void) {
        if let token = accessToken, let expiry = tokenExpiry, Date() < expiry {
            completion(token)
            return
        }
        let credentials = "\(clientID):\(clientSecret)"
        guard let credData = credentials.data(using: .utf8) else { completion(nil); return }
        let base64 = credData.base64EncodedString()
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["access_token"] as? String,
                  let expiresIn = json["expires_in"] as? TimeInterval else { completion(nil); return }
            self.accessToken = token
            self.tokenExpiry = Date().addingTimeInterval(expiresIn - 60)
            completion(token)
        }.resume()
    }
    
    
    // MARK: - Carátula
    func fetchAlbumArt(trackID: String) {
        getAccessToken { token in
            guard let token = token else { return }
            var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/tracks/\(trackID)")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request) { data, _, _ in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let album = json["album"] as? [String: Any],
                      let images = album["images"] as? [[String: Any]],
                      let imageURL = images.first?["url"] as? String,
                      let url = URL(string: imageURL) else { return }
                URLSession.shared.dataTask(with: url) { imageData, _, _ in
                    guard let imageData = imageData,
                          let image = NSImage(data: imageData) else { return }
                    DispatchQueue.main.async {
                        self.albumArt = image
                        self.extractDominantColor(from: image) //añadir el color del fondo de la caratula
                    }
                }.resume()
            }.resume()
        }
    }
}
