import AppKit
import SwiftUI

class NotchWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

class NotchWindowController: NSWindowController {
    
    static let shared = NotchWindowController()
    private var isExpanded = false
    
    private init() {
        guard let screen = NSScreen.main else {
            super.init(window: nil)
            return
        }
        
        let notchWidth: CGFloat = 180
        let barHeight : CGFloat = 24
        let x = (screen.frame.width - notchWidth) / 2
        let y = screen.frame.height - barHeight
        
        let window = NotchWindow(
            contentRect: NSRect(x: x, y: y, width: notchWidth, height: barHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = true
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        super.init(window: window)
        
        let contentView = NotchTabView(controller: self)
        window.contentView = NSHostingView(rootView: contentView)
        window.orderFront(nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func expand(height: CGFloat = 320) {
        guard !isExpanded, let screen = NSScreen.main, let window = self.window else { return }
        isExpanded = true
        
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        
        let expandedWidth: CGFloat = 360
        let x = (screen.frame.width - expandedWidth) / 2
        
        let y = screen.visibleFrame.maxY - height
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(
                NSRect(x: x, y: y, width: expandedWidth, height: height),
                display: true
            )
        }
    }
    
    func resize(height: CGFloat) {
        guard isExpanded, let screen = NSScreen.main, let window = self.window else { return }
        
        let expandedWidth: CGFloat = 360
        let x = (screen.frame.width - expandedWidth) / 2
        let barHeight = screen.frame.height - screen.visibleFrame.maxY
        let y = screen.visibleFrame.maxY - height
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            //ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(
                NSRect(x: x, y: y, width: expandedWidth, height: height),
                display: true
            )
        }
    }
    
    func collapse() {
        guard isExpanded, let screen = NSScreen.main, let window = self.window else { return }
        isExpanded = false
        
        NSApp.setActivationPolicy(.accessory)
        
        let notchWidth: CGFloat = 180
        let barHeight: CGFloat = 24
        let x = (screen.frame.width - notchWidth) / 2
        let y = screen.visibleFrame.maxY
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(
                NSRect(x: x, y: y, width: notchWidth, height: barHeight),
                display: true
            )
        }
    }
}
