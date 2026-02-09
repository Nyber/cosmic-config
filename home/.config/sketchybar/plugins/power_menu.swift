import AppKit

class PowerMenu: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    let actions = ["Lock Screen", "Sleep", "Restart", "Shut Down", "Log Out"]

    func applicationDidFinishLaunching(_ notification: Notification) {
        let width: CGFloat = 180
        let buttonHeight: CGFloat = 28
        let padding: CGFloat = 12
        let spacing: CGFloat = 6
        let height = padding * 2 + buttonHeight * CGFloat(actions.count) + spacing * CGFloat(actions.count - 1)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Power"
        window.center()
        window.delegate = self
        window.isReleasedWhenClosed = false

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        for (i, action) in actions.enumerated() {
            let y = height - padding - buttonHeight - CGFloat(i) * (buttonHeight + spacing)
            let button = NSButton(frame: NSRect(x: padding, y: y, width: width - padding * 2, height: buttonHeight))
            button.title = action
            button.bezelStyle = .rounded
            button.target = self
            button.action = #selector(buttonClicked(_:))
            contentView.addSubview(button)
        }

        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func buttonClicked(_ sender: NSButton) {
        try? sender.title.write(toFile: "/tmp/.sketchybar_power_choice", atomically: true, encoding: .utf8)
        NSApp.terminate(nil)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = PowerMenu()
app.delegate = delegate
app.run()
