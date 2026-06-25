import AppKit
import SwiftUI

enum AppWindowMetrics {
    static let defaultSize = CGSize(width: 680, height: 300)
    static let minSize = CGSize(width: 360, height: AppLayoutMetrics.minimumWindowHeight)
}

enum AppWindowController {
    private static weak var mainWindow: NSWindow?

    static func registerMainWindow(_ window: NSWindow) {
        mainWindow = window
    }

    static func activate() {
        NSApp.activate(ignoringOtherApps: true)
        if let mainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
        } else {
            NSApp.windows.first { $0.canBecomeKey && $0.isVisible }?.makeKeyAndOrderFront(nil)
        }
    }
}

@available(macOS 13.0, *)
private protocol WindowHostingView: AnyObject {
    var sizingOptions: NSHostingSizingOptions { get set }
}

@available(macOS 13.0, *)
extension NSHostingView: WindowHostingView {}

struct WindowConfigurator: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WindowAnchorView {
        let view = WindowAnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: WindowAnchorView, context: Context) {
        nsView.coordinator = context.coordinator
        nsView.applyWindowPolicy()
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        var didApplyInitialFrame = false
        weak var attachedWindow: NSWindow?

        func attach(to window: NSWindow) {
            guard attachedWindow !== window else { return }
            attachedWindow?.delegate = nil
            attachedWindow = window
            window.delegate = self
            AppWindowController.registerMainWindow(window)
        }

        func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
            let minFrame = sender.frameRect(
                forContentRect: NSRect(origin: .zero, size: minContentSize)
            ).size
            return NSSize(
                width: max(frameSize.width, minFrame.width),
                height: max(frameSize.height, minFrame.height)
            )
        }

        func windowDidMove(_ notification: Notification) {
            persistFrame()
        }

        func windowDidResize(_ notification: Notification) {
            persistFrame()
        }

        func windowWillClose(_ notification: Notification) {
            persistFrame()
        }

        func persistFrame() {
            guard let window = attachedWindow else { return }
            AppPreferences.saveWindowFrame(window.frame)
        }
    }
}

private extension WindowConfigurator.Coordinator {
    var minContentSize: NSSize {
        NSSize(
            width: AppWindowMetrics.minSize.width,
            height: AppWindowMetrics.minSize.height
        )
    }
}

final class WindowAnchorView: NSView {
    weak var coordinator: WindowConfigurator.Coordinator?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyWindowPolicy()
    }

    override func layout() {
        super.layout()
        applyWindowPolicy()
    }

    func applyWindowPolicy() {
        guard let window, let coordinator else { return }
        coordinator.attach(to: window)

        let minContent = NSSize(
            width: AppWindowMetrics.minSize.width,
            height: AppWindowMetrics.minSize.height
        )
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: minContent)).size
        window.contentMinSize = minContent

        if #available(macOS 13.0, *) {
            disableHostingContentMinSize(in: window.contentView)
        }

        guard !coordinator.didApplyInitialFrame else { return }
        coordinator.didApplyInitialFrame = true

        let minFrameSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: minContent)).size
        if let savedFrame = AppPreferences.loadWindowFrame(minFrameSize: minFrameSize) {
            window.setFrame(savedFrame, display: true)
        } else {
            window.setContentSize(NSSize(
                width: AppWindowMetrics.defaultSize.width,
                height: AppWindowMetrics.defaultSize.height
            ))
            window.center()
        }
    }
}

@available(macOS 13.0, *)
private func disableHostingContentMinSize(in view: NSView?) {
    guard let view else { return }

    if var hosting = view as? any WindowHostingView {
        hosting.sizingOptions = []
    } else if NSStringFromClass(type(of: view)).contains("NSHostingView") {
        view.setValue(NSHostingSizingOptions(), forKey: "sizingOptions")
    }

    for subview in view.subviews {
        disableHostingContentMinSize(in: subview)
    }
}

extension View {
    func configureAppWindow() -> some View {
        background(WindowConfigurator())
    }
}
