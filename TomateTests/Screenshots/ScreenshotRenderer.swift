import AppKit
import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import XCTest
@testable import Tomate

@MainActor
enum ScreenshotRenderer {
    /// README screenshots are exported at 2× the window point size.
    private static let exportScale: CGFloat = 2
    static var outputDirectory: URL {
        if let path = ProcessInfo.processInfo.environment["SCREENSHOTS_DIR"] {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/screenshots", isDirectory: true)
    }

    static func renderWindow<V: View>(
        _ view: V,
        title: String,
        named filename: String,
        contentSize: CGSize = AppWindowMetrics.defaultSize,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let window = makeWindow(title: title, contentSize: contentSize)
        defer { window.orderOut(nil) }

        let rootView = view
            .frame(width: contentSize.width, height: contentSize.height)
            .background(AppColors.background)

        let hostingView = NSHostingView(rootView: rootView)
        if #available(macOS 13.0, *) {
            hostingView.sizingOptions = []
        }
        hostingView.frame = NSRect(origin: .zero, size: contentSize)
        window.contentView = hostingView

        window.setContentSize(contentSize)
        placeOnMainScreen(window)
        window.orderFrontRegardless()
        window.displayIfNeeded()
        hostingView.layoutSubtreeIfNeeded()
        drainMainRunLoop()

        guard let captured = captureWindowFrame(window),
              let flattened = flattenOntoBackground(captured),
              let png = pngData(from: flattened) else {
            XCTFail("Failed to capture window for \(filename)", file: file, line: line)
            return
        }

        let url = outputDirectory.appendingPathComponent(filename)
        try png.write(to: url)
    }

    private static func makeWindow(title: String, contentSize: CGSize) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor(AppColors.background)
        return window
    }

    private static func placeOnMainScreen(_ window: NSWindow) {
        guard let screen = NSScreen.main else {
            window.center()
            return
        }
        let frame = window.frame
        let visible = screen.visibleFrame
        let origin = NSPoint(
            x: visible.midX - frame.width / 2,
            y: visible.midY - frame.height / 2
        )
        window.setFrameOrigin(origin)
    }

    private static func captureWindowFrame(_ window: NSWindow) -> CGImage? {
        window.displayIfNeeded()

        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            CGWindowID(window.windowNumber),
            [.bestResolution]
        ) else {
            return nil
        }

        let targetWidth = Int((window.frame.width * exportScale).rounded())
        let targetHeight = Int((window.frame.height * exportScale).rounded())

        if cgImage.width >= targetWidth && cgImage.height >= targetHeight {
            return cgImage
        }

        return scaleImage(cgImage, width: targetWidth, height: targetHeight)
    }

    /// Composites premultiplied RGBA onto the app background so anti-aliased pixels are stable across runs.
    private static func flattenOntoBackground(_ image: CGImage) -> CGImage? {
        let width = image.width
        let height = image.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }

        context.setFillColor(NSColor(AppColors.background).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    private static func scaleImage(_ image: CGImage, width: Int, height: Int) -> CGImage? {
        let colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    private static func pngData(from cgImage: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        let properties: [CFString: Any] = [
            kCGImagePropertyPNGDictionary: [
                kCGImagePropertyPNGCompressionFilter: 0,
            ] as [CFString: Any],
        ]
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return data as Data
    }

    private static func drainMainRunLoop() {
        let deadline = Date(timeIntervalSinceNow: 0.25)
        while Date() < deadline {
            RunLoop.current.run(mode: .default, before: deadline)
        }
    }
}
