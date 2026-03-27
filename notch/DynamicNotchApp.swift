import SwiftUI
import AppKit

@main
struct DynamicNotchApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Arrancamos el notch
        _ = NotchWindowController.shared
        
        // Necesario para recibir eventos de teclado sin ventana en el Dock
        NSApp.setActivationPolicy(.accessory)
    }
}
