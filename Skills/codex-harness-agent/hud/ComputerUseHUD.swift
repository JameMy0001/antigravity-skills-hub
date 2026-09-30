//
// ComputerUseHUD.swift
// Native macOS Mini Display (Picture-in-Picture) and Ghost Cursor for Computer Use
// Author: Jamemm (@JameMy0001)
//

import Cocoa
import CoreGraphics
import QuartzCore

// MARK: - Ghost Cursor Overlay Window
class GhostCursorWindow: NSPanel {
    var cursorView: GhostCursorView!

    init() {
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        super.init(
            contentRect: screenRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.level = .floating + 1
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        cursorView = GhostCursorView(frame: screenRect)
        self.contentView = cursorView
    }

    func moveCursor(to point: CGPoint, animated: Bool = true, completion: (() -> Void)? = nil) {
        cursorView.moveTo(point: point, animated: animated, completion: completion)
    }

    func clickAt(point: CGPoint, completion: (() -> Void)? = nil) {
        cursorView.clickAt(point: point, completion: completion)
    }
}

// MARK: - Ghost Cursor View
class GhostCursorView: NSView {
    private var pointerLayer: CALayer!
    private var rippleLayer: CAShapeLayer!
    private(set) var currentPosition: CGPoint = CGPoint(x: 400, y: 400)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        setupPointer()
        setupRipple()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPointer() {
        pointerLayer = CALayer()
        pointerLayer.bounds = CGRect(x: 0, y: 0, width: 32, height: 32)
        pointerLayer.anchorPoint = CGPoint(x: 0.15, y: 0.85)
        pointerLayer.position = currentPosition

        // Create glowing pointer image
        let img = createPointerImage()
        pointerLayer.contents = img

        // Shadow
        pointerLayer.shadowColor = NSColor.cyan.cgColor
        pointerLayer.shadowRadius = 8
        pointerLayer.shadowOpacity = 0.8
        pointerLayer.shadowOffset = CGSize(width: 0, height: -2)

        self.layer?.addSublayer(pointerLayer)
    }

    private func setupRipple() {
        rippleLayer = CAShapeLayer()
        rippleLayer.bounds = CGRect(x: 0, y: 0, width: 60, height: 60)
        let circlePath = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 60, height: 60), transform: nil)
        rippleLayer.path = circlePath
        rippleLayer.fillColor = NSColor.clear.cgColor
        rippleLayer.strokeColor = NSColor.cyan.cgColor
        rippleLayer.lineWidth = 2.5
        rippleLayer.opacity = 0.0
        self.layer?.addSublayer(rippleLayer)
    }

    private func createPointerImage() -> CGImage? {
        let size = CGSize(width: 32, height: 32)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        // Draw modern Mac-style arrow with cyan tint
        context.setFillColor(NSColor.white.cgColor)
        context.setStrokeColor(NSColor.cyan.cgColor)
        context.setLineWidth(1.5)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: 4, y: 28))
        path.addLine(to: CGPoint(x: 4, y: 4))
        path.addLine(to: CGPoint(x: 14, y: 14))
        path.addLine(to: CGPoint(x: 24, y: 14))
        path.closeSubpath()

        context.addPath(path)
        context.drawPath(using: .fillStroke)

        return context.makeImage()
    }

    func moveTo(point: CGPoint, animated: Bool, completion: (() -> Void)? = nil) {
        if !animated {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            pointerLayer.position = point
            currentPosition = point
            CATransaction.commit()
            completion?()
            return
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.6)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        CATransaction.setCompletionBlock { [weak self] in
            self?.currentPosition = point
            completion?()
        }

        let anim = CABasicAnimation(keyPath: "position")
        anim.fromValue = NSValue(point: pointerLayer.position)
        anim.toValue = NSValue(point: point)
        anim.duration = 0.6
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        pointerLayer.position = point
        pointerLayer.add(anim, forKey: "position")
        CATransaction.commit()
    }

    func clickAt(point: CGPoint, completion: (() -> Void)? = nil) {
        moveTo(point: point, animated: true) { [weak self] in
            guard let self = self else { return }
            self.triggerClickRipple(at: point)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                completion?()
            }
        }
    }

    private func triggerClickRipple(at point: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rippleLayer.position = point
        rippleLayer.transform = CATransform3DMakeScale(0.2, 0.2, 1.0)
        rippleLayer.opacity = 1.0
        CATransaction.commit()

        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 0.2
        scaleAnim.toValue = 1.3
        scaleAnim.duration = 0.4
        scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let fadeAnim = CABasicAnimation(keyPath: "opacity")
        fadeAnim.fromValue = 1.0
        fadeAnim.toValue = 0.0
        fadeAnim.duration = 0.4
        fadeAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let group = CAAnimationGroup()
        group.animations = [scaleAnim, fadeAnim]
        group.duration = 0.4
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards

        rippleLayer.add(group, forKey: "ripple")
    }
}

// MARK: - Mini Display (Picture-in-Picture) Window
class MiniDisplayWindow: NSPanel {
    private var visualEffectView: NSVisualEffectView!
    private var previewImageView: NSImageView!
    private var statusPillView: NSVisualEffectView!
    private var statusLabel: NSTextField!
    private var spinnerIndicator: NSProgressIndicator!
    private var miniPointerLayer: CALayer!

    init() {
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width: CGFloat = 430
        let height: CGFloat = 270
        let padding: CGFloat = 20
        let x = screenRect.maxX - width - padding
        let y = screenRect.maxY - height - padding

        super.init(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        setupUI(width: width, height: height)
    }

    private func setupUI(width: CGFloat, height: CGFloat) {
        // Frosted Glass Background
        visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 18
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.borderWidth = 1.0
        visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.22).cgColor

        // Traffic Light Dots
        setupTrafficLights()

        // Title Label
        let titleLabel = NSTextField(labelWithString: "Computer Use Mini Display")
        titleLabel.frame = NSRect(x: 80, y: height - 30, width: 260, height: 20)
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.85)
        titleLabel.alignment = .center
        visualEffectView.addSubview(titleLabel)

        // Mini Screen Preview
        let previewRect = NSRect(x: 14, y: 48, width: width - 28, height: height - 86)
        previewImageView = NSImageView(frame: previewRect)
        previewImageView.imageScaling = .scaleAxesIndependently
        previewImageView.wantsLayer = true
        previewImageView.layer?.cornerRadius = 10
        previewImageView.layer?.masksToBounds = true
        previewImageView.layer?.borderWidth = 1.0
        previewImageView.layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
        previewImageView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.35).cgColor
        visualEffectView.addSubview(previewImageView)

        // Mini Ghost Pointer on Preview
        setupMiniPointer(in: previewRect)

        // Status Pill Badge (Bottom)
        setupStatusPill(width: width)

        self.contentView = visualEffectView
        updateScreenPreview()
    }

    private func setupTrafficLights() {
        let colors: [NSColor] = [
            NSColor(red: 1.0, green: 0.37, blue: 0.34, alpha: 0.9), // Red
            NSColor(red: 1.0, green: 0.74, blue: 0.18, alpha: 0.9), // Yellow
            NSColor(red: 0.15, green: 0.79, blue: 0.25, alpha: 0.9)  // Green
        ]
        for (i, color) in colors.enumerated() {
            let dot = NSView(frame: NSRect(x: 16 + (i * 18), y: 242, width: 11, height: 11))
            dot.wantsLayer = true
            dot.layer?.cornerRadius = 5.5
            dot.layer?.backgroundColor = color.cgColor
            visualEffectView.addSubview(dot)
        }
    }

    private func setupMiniPointer(in bounds: NSRect) {
        miniPointerLayer = CALayer()
        miniPointerLayer.bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
        miniPointerLayer.anchorPoint = CGPoint(x: 0.1, y: 0.9)
        miniPointerLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)

        // Draw small pointer
        let size = CGSize(width: 14, height: 14)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        if let ctx = context {
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.setStrokeColor(NSColor.cyan.cgColor)
            ctx.setLineWidth(1.0)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 2, y: 12))
            path.addLine(to: CGPoint(x: 2, y: 2))
            path.addLine(to: CGPoint(x: 7, y: 7))
            path.addLine(to: CGPoint(x: 12, y: 7))
            path.closeSubpath()
            ctx.addPath(path)
            ctx.drawPath(using: .fillStroke)
            miniPointerLayer.contents = ctx.makeImage()
        }

        miniPointerLayer.shadowColor = NSColor.cyan.cgColor
        miniPointerLayer.shadowRadius = 4
        miniPointerLayer.shadowOpacity = 0.9
        previewImageView.layer?.addSublayer(miniPointerLayer)
    }

    private func setupStatusPill(width: CGFloat) {
        let pillWidth: CGFloat = width - 28
        let pillHeight: CGFloat = 30
        statusPillView = NSVisualEffectView(frame: NSRect(x: 14, y: 10, width: pillWidth, height: pillHeight))
        statusPillView.material = .hudWindow
        statusPillView.blendingMode = .withinWindow
        statusPillView.state = .active
        statusPillView.wantsLayer = true
        statusPillView.layer?.cornerRadius = 15
        statusPillView.layer?.masksToBounds = true
        statusPillView.layer?.borderWidth = 1.0
        statusPillView.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        statusPillView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.25).cgColor

        // Spinner
        spinnerIndicator = NSProgressIndicator(frame: NSRect(x: 10, y: 7, width: 16, height: 16))
        spinnerIndicator.style = .spinning
        spinnerIndicator.controlSize = .small
        spinnerIndicator.startAnimation(nil)
        statusPillView.addSubview(spinnerIndicator)

        // Status Text Label
        statusLabel = NSTextField(labelWithString: "Working... กำลังเตรียมการ")
        statusLabel.frame = NSRect(x: 34, y: 5, width: pillWidth - 44, height: 20)
        statusLabel.font = NSFont.systemFont(ofSize: 11.5, weight: .medium)
        statusLabel.textColor = NSColor.white
        statusPillView.addSubview(statusLabel)

        visualEffectView.addSubview(statusPillView)
    }

    func setStatus(_ text: String, isDone: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.statusLabel.stringValue = text
            if isDone {
                self.spinnerIndicator.stopAnimation(nil)
                self.spinnerIndicator.isHidden = true
                self.statusLabel.frame = NSRect(x: 14, y: 5, width: self.statusPillView.frame.width - 28, height: 20)
                self.statusLabel.alignment = .center
            } else {
                self.spinnerIndicator.isHidden = false
                self.spinnerIndicator.startAnimation(nil)
                self.statusLabel.frame = NSRect(x: 34, y: 5, width: self.statusPillView.frame.width - 44, height: 20)
                self.statusLabel.alignment = .left
            }
            self.updateScreenPreview()
        }
    }

    func updateScreenPreview() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let path = "/tmp/cua_preview.jpg"
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = ["-x", "-t", "jpg", path]
            try? task.run()
            task.waitUntilExit()

            if let img = NSImage(contentsOfFile: path) {
                DispatchQueue.main.async {
                    self?.previewImageView.image = img
                }
            }
        }
    }

    func updateMiniPointer(targetScreenPoint: CGPoint) {
        guard let screen = NSScreen.main else { return }
        let previewBounds = previewImageView.bounds
        let normX = targetScreenPoint.x / screen.frame.width
        let normY = targetScreenPoint.y / screen.frame.height

        let miniX = normX * previewBounds.width
        let miniY = normY * previewBounds.height

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        miniPointerLayer.position = CGPoint(x: miniX, y: miniY)
        CATransaction.commit()
    }
}

// MARK: - Controller & Runner
class HUDAppController: NSObject, NSApplicationDelegate {
    var miniDisplay: MiniDisplayWindow!
    var ghostCursor: GhostCursorWindow!
    var commandPipePath = "/tmp/cua_hud.pipe"

    func applicationDidFinishLaunching(_ notification: Notification) {
        miniDisplay = MiniDisplayWindow()
        ghostCursor = GhostCursorWindow()

        miniDisplay.orderFrontRegardless()
        ghostCursor.orderFrontRegardless()

        let args = ProcessInfo.processInfo.arguments
        if args.contains("demo") {
            runDemoScenario()
        } else {
            startPipeListener()
        }
    }

    func updateAction(status: String, x: CGFloat? = nil, y: CGFloat? = nil, click: Bool = false, isDone: Bool = false) {
        miniDisplay.setStatus(status, isDone: isDone)

        if let px = x, let py = y {
            let pt = CGPoint(x: px, y: py)
            miniDisplay.updateMiniPointer(targetScreenPoint: pt)
            if click {
                ghostCursor.clickAt(point: pt)
            } else {
                ghostCursor.moveCursor(to: pt)
            }
        }
    }

    func startPipeListener() {
        mkfifo(commandPipePath, 0o666)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            while true {
                guard let handle = FileHandle(forReadingAtPath: self?.commandPipePath ?? "") else {
                    Thread.sleep(forTimeInterval: 0.5)
                    continue
                }
                let data = handle.readDataToEndOfFile()
                if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
                    self?.handleCommandString(str)
                }
            }
        }
    }

    private func handleCommandString(_ line: String) {
        // Parses simple json or key=value
        // Format: status|x|y|click|done
        let parts = line.components(separatedBy: "|")
        let status = parts.first ?? "Working..."
        var x: CGFloat? = nil
        var y: CGFloat? = nil
        var click = false
        var isDone = false

        if parts.count >= 3, let px = Double(parts[1]), let py = Double(parts[2]) {
            x = CGFloat(px)
            y = CGFloat(py)
        }
        if parts.count >= 4 {
            click = (parts[3] == "true" || parts[3] == "1")
        }
        if parts.count >= 5 {
            isDone = (parts[4] == "true" || parts[4] == "1")
        }

        DispatchQueue.main.async { [weak self] in
            self?.updateAction(status: status, x: x, y: y, click: click, isDone: isDone)
            if isDone {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    func runDemoScenario() {
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let centerX = screen.width / 2
        let centerY = screen.height / 2

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateAction(status: "Working... กำลังเปิดเบราว์เซอร์ Safari", x: centerX - 200, y: 80, click: true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.updateAction(status: "กำลังค้นหา: 'อนันเป็ด'", x: centerX, y: centerY + 150, click: true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            self?.updateAction(status: "กำลังคลิกลิงก์ช่อง YouTube อนันเป็ด", x: centerX - 100, y: centerY, click: true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            self?.updateAction(status: "ดำเนินการเรียบร้อยแล้ว [PASS] ✅", isDone: true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 9.0) {
            NSApp.terminate(nil)
        }
    }
}

// MARK: - Main Entry Point
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = HUDAppController()
app.delegate = delegate
app.run()
