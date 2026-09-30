//
// ComputerUseHUD.swift
// Native macOS Mini Display (Picture-in-Picture) and Ghost Cursor for Computer Use
// Incorporating Apple Vision Neural OCR Grounding, Safety Guardrail Approval Gate,
// In-HUD Quick Command Box (⌘K / ⌥Space), and Action Filmstrip History Carousel.
//
// Author: Jamemm (@JameMy0001)
//

import Cocoa
import CoreGraphics
import QuartzCore
import Vision

// MARK: - Screen OCR Detector (Phase 1: Apple Neural Vision Framework)
class ScreenOCRDetector {
    static let shared = ScreenOCRDetector()

    func findTextLocation(query: String, in image: CGImage, completion: @escaping (CGPoint?, String?) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil, let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil, nil)
                return
            }

            let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            for obs in observations {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let candText = candidate.string.lowercased()
                if candText.contains(trimmedQuery) {
                    let box = obs.boundingBox
                    // Convert normalized Vision coordinates (0,0 bottom-left) to primary screen coordinates
                    if let screen = NSScreen.main {
                        let screenWidth = screen.frame.width
                        let screenHeight = screen.frame.height
                        let centerX = screen.frame.origin.x + (box.origin.x + box.size.width / 2.0) * screenWidth
                        let centerY = screen.frame.origin.y + (box.origin.y + box.size.height / 2.0) * screenHeight
                        completion(CGPoint(x: centerX, y: centerY), candidate.string)
                        return
                    }
                }
            }
            completion(nil, nil)
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "th-TH"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}

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

        let img = createPointerImage()
        pointerLayer.contents = img

        pointerLayer.shadowColor = NSColor.cyan.cgColor
        pointerLayer.shadowRadius = 8
        pointerLayer.shadowOpacity = 0.85
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
        CATransaction.setAnimationDuration(0.4)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        CATransaction.setCompletionBlock { [weak self] in
            self?.currentPosition = point
            completion?()
        }

        let anim = CABasicAnimation(keyPath: "position")
        anim.fromValue = NSValue(point: pointerLayer.position)
        anim.toValue = NSValue(point: point)
        anim.duration = 0.4
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        pointerLayer.position = point
        pointerLayer.add(anim, forKey: "position")
        CATransaction.commit()
    }

    func clickAt(point: CGPoint, completion: (() -> Void)? = nil) {
        moveTo(point: point, animated: true) { [weak self] in
            guard let self = self else { return }
            self.triggerClickRipple(at: point)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
        scaleAnim.duration = 0.35
        scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let fadeAnim = CABasicAnimation(keyPath: "opacity")
        fadeAnim.fromValue = 1.0
        fadeAnim.toValue = 0.0
        fadeAnim.duration = 0.35
        fadeAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let group = CAAnimationGroup()
        group.animations = [scaleAnim, fadeAnim]
        group.duration = 0.35
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards

        rippleLayer.add(group, forKey: "ripple")
    }
}

// MARK: - Action Frame Model (Phase 4: Action Filmstrip History)
struct ActionFrame {
    let image: NSImage
    let label: String
    let timestamp: Date
}

// MARK: - Mini Display (Picture-in-Picture) Window
class MiniDisplayWindow: NSPanel, NSTextFieldDelegate {
    private var visualEffectView: NSVisualEffectView!
    private var previewImageView: NSImageView!
    private var statusPillView: NSVisualEffectView!
    private var statusLabel: NSTextField!
    private var spinnerIndicator: NSProgressIndicator!
    private var miniPointerLayer: CALayer!

    // Phase 2: Approval Gate UI
    private var approvalContainer: NSView!
    private var approvalLabel: NSTextField!
    private var approveBtn: NSButton!
    private var denyBtn: NSButton!

    // Phase 3: Quick Command Box UI
    private var commandInputBox: NSTextField!
    private var commandBoxVisible = false

    // Phase 4: Filmstrip History Carousel UI
    private var filmstripStackView: NSStackView!
    private var historyFrames: [ActionFrame] = []
    private var thumbnailViews: [NSImageView] = []

    private var isCollapsed = false
    private let standardWidth: CGFloat = 460
    private let standardHeight: CGFloat = 345

    init() {
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let padding: CGFloat = 20
        let x = screenRect.maxX - standardWidth - padding
        let y = screenRect.maxY - standardHeight - padding

        super.init(
            contentRect: NSRect(x: x, y: y, width: standardWidth, height: standardHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating + 2
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.isMovable = true
        self.isMovableByWindowBackground = true
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        setupUI(width: standardWidth, height: standardHeight)
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
        visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.25).cgColor

        // Header: Traffic Lights + Title + Command Box Toggle
        setupHeader(width: width, height: height)

        // Phase 3: Quick Command Bar (Collapsible)
        setupCommandInput(width: width, height: height)

        // Screen Preview Area
        let previewRect = NSRect(x: 14, y: 92, width: width - 28, height: height - 138)
        previewImageView = NSImageView(frame: previewRect)
        previewImageView.imageScaling = .scaleAxesIndependently
        previewImageView.wantsLayer = true
        previewImageView.layer?.cornerRadius = 10
        previewImageView.layer?.masksToBounds = true
        previewImageView.layer?.borderWidth = 1.0
        previewImageView.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        previewImageView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.35).cgColor
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handlePreviewClick))
        previewImageView.addGestureRecognizer(clickGesture)
        visualEffectView.addSubview(previewImageView)

        // Mini Ghost Pointer on Preview
        setupMiniPointer(in: previewRect)

        // Phase 4: Filmstrip History Carousel Tray
        setupFilmstripTray(width: width)

        // Phase 2: Status Pill & Safety Approval Container (Bottom)
        setupStatusAndApprovalPill(width: width)

        self.contentView = visualEffectView
        updateScreenPreview()
    }

    private func setupHeader(width: CGFloat, height: CGFloat) {
        // Red: Close
        let redBtn = NSButton(frame: NSRect(x: 16, y: height - 28, width: 12, height: 12))
        redBtn.isBordered = false
        redBtn.title = ""
        redBtn.wantsLayer = true
        redBtn.layer?.cornerRadius = 6
        redBtn.layer?.backgroundColor = NSColor(red: 1.0, green: 0.37, blue: 0.34, alpha: 0.95).cgColor
        redBtn.toolTip = "ปิดหน้าต่าง Mini Display (Close)"
        redBtn.target = self
        redBtn.action = #selector(handleCloseHUD)
        visualEffectView.addSubview(redBtn)

        // Yellow: Collapse / Expand
        let yellowBtn = NSButton(frame: NSRect(x: 34, y: height - 28, width: 12, height: 12))
        yellowBtn.isBordered = false
        yellowBtn.title = ""
        yellowBtn.wantsLayer = true
        yellowBtn.layer?.cornerRadius = 6
        yellowBtn.layer?.backgroundColor = NSColor(red: 1.0, green: 0.74, blue: 0.18, alpha: 0.95).cgColor
        yellowBtn.toolTip = "ย่อ/ขยายหน้าต่าง (Collapse / Expand)"
        yellowBtn.target = self
        yellowBtn.action = #selector(handleToggleCollapse)
        visualEffectView.addSubview(yellowBtn)

        // Green: Refresh Snapshot
        let greenBtn = NSButton(frame: NSRect(x: 52, y: height - 28, width: 12, height: 12))
        greenBtn.isBordered = false
        greenBtn.title = ""
        greenBtn.wantsLayer = true
        greenBtn.layer?.cornerRadius = 6
        greenBtn.layer?.backgroundColor = NSColor(red: 0.15, green: 0.79, blue: 0.25, alpha: 0.95).cgColor
        greenBtn.toolTip = "รีเฟรชภาพหน้าจอล่าสุด (Refresh Preview)"
        greenBtn.target = self
        greenBtn.action = #selector(handleRefreshPreview)
        visualEffectView.addSubview(greenBtn)

        // Title Label (Draggable Area)
        let titleLabel = NSTextField(labelWithString: "Computer Use Mini Display")
        titleLabel.frame = NSRect(x: 74, y: height - 30, width: width - 150, height: 20)
        titleLabel.font = NSFont.systemFont(ofSize: 11.5, weight: .semibold)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.9)
        titleLabel.alignment = .center
        visualEffectView.addSubview(titleLabel)

        // Phase 3: Toggle Command Box Button [⌘K]
        let cmdToggleBtn = NSButton(frame: NSRect(x: width - 48, y: height - 30, width: 34, height: 18))
        cmdToggleBtn.isBordered = false
        cmdToggleBtn.title = "⌘K"
        cmdToggleBtn.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
        cmdToggleBtn.wantsLayer = true
        cmdToggleBtn.layer?.cornerRadius = 4
        cmdToggleBtn.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.15).cgColor
        cmdToggleBtn.contentTintColor = NSColor.white
        cmdToggleBtn.toolTip = "สั่งงาน Agent หรือป้อนคำสั่งลัด (Toggle Command Bar)"
        cmdToggleBtn.target = self
        cmdToggleBtn.action = #selector(toggleCommandInput)
        visualEffectView.addSubview(cmdToggleBtn)
    }

    private func setupCommandInput(width: CGFloat, height: CGFloat) {
        commandInputBox = NSTextField(frame: NSRect(x: 14, y: height - 58, width: width - 28, height: 24))
        commandInputBox.placeholderString = "⌘K สั่งงาน Agent (กด Enter เพื่อเริ่ม, ⌥Space เปิดจากทุกที่)..."
        commandInputBox.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        commandInputBox.textColor = NSColor.white
        commandInputBox.backgroundColor = NSColor.black.withAlphaComponent(0.4)
        commandInputBox.isBordered = true
        commandInputBox.wantsLayer = true
        commandInputBox.layer?.cornerRadius = 6
        commandInputBox.layer?.borderColor = NSColor.cyan.withAlphaComponent(0.5).cgColor
        commandInputBox.layer?.borderWidth = 1.0
        commandInputBox.target = self
        commandInputBox.action = #selector(handleCommandSubmit)
        commandInputBox.delegate = self
        commandInputBox.isHidden = true
        visualEffectView.addSubview(commandInputBox)
    }

    @objc func toggleCommandInput() {
        commandBoxVisible = !commandBoxVisible
        commandInputBox.isHidden = !commandBoxVisible
        if commandBoxVisible {
            self.makeKeyAndOrderFront(nil)
            self.makeFirstResponder(commandInputBox)
        }
    }

    func showAndFocusCommandBar() {
        commandBoxVisible = true
        commandInputBox.isHidden = false
        self.makeKeyAndOrderFront(nil)
        self.makeFirstResponder(commandInputBox)
    }

    @objc func handleCommandSubmit() {
        let taskText = commandInputBox.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !taskText.isEmpty {
            setStatus("Working... เริ่มต้นคำสั่ง: \(taskText)", isDone: false)
            commandInputBox.stringValue = ""
            commandBoxVisible = false
            commandInputBox.isHidden = true

            // Dispatch command in background via codex-agent runner
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                proc.launchPath = "/bin/zsh"
                proc.arguments = ["-c", "codex-agent --gui \"\(taskText)\""]
                try? proc.run()
            }
        }
    }

    private func setupMiniPointer(in bounds: NSRect) {
        miniPointerLayer = CALayer()
        miniPointerLayer.bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
        miniPointerLayer.anchorPoint = CGPoint(x: 0.1, y: 0.9)
        miniPointerLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)

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

    // MARK: - Phase 4: Filmstrip History Carousel
    private func setupFilmstripTray(width: CGFloat) {
        let trayRect = NSRect(x: 14, y: 48, width: width - 28, height: 38)
        let trayContainer = NSView(frame: trayRect)
        trayContainer.wantsLayer = true
        trayContainer.layer?.cornerRadius = 6
        trayContainer.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.2).cgColor
        trayContainer.layer?.borderWidth = 0.5
        trayContainer.layer?.borderColor = NSColor.white.withAlphaComponent(0.1).cgColor

        filmstripStackView = NSStackView(frame: NSRect(x: 4, y: 3, width: trayRect.width - 8, height: 32))
        filmstripStackView.orientation = .horizontal
        filmstripStackView.spacing = 6
        filmstripStackView.distribution = .fillEqually

        // Create 6 thumbnail slots
        thumbnailViews.removeAll()
        for i in 0..<6 {
            let thumb = NSImageView(frame: NSRect(x: 0, y: 0, width: 64, height: 32))
            thumb.wantsLayer = true
            thumb.layer?.cornerRadius = 4
            thumb.layer?.masksToBounds = true
            thumb.layer?.borderWidth = 1.0
            thumb.layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
            thumb.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
            thumb.imageScaling = .scaleAxesIndependently
            thumb.tag = i

            let click = NSClickGestureRecognizer(target: self, action: #selector(handleThumbnailClick(_:)))
            thumb.addGestureRecognizer(click)

            thumbnailViews.append(thumb)
            filmstripStackView.addArrangedSubview(thumb)
        }

        trayContainer.addSubview(filmstripStackView)
        visualEffectView.addSubview(trayContainer)
    }

    func addActionSnapshot(label: String) {
        let path = "/tmp/cua_preview.jpg"
        guard let img = NSImage(contentsOfFile: path) else { return }
        let frame = ActionFrame(image: img, label: label, timestamp: Date())

        if historyFrames.count >= 6 {
            historyFrames.removeFirst()
        }
        historyFrames.append(frame)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for (idx, thumb) in self.thumbnailViews.enumerated() {
                if idx < self.historyFrames.count {
                    let f = self.historyFrames[idx]
                    thumb.image = f.image
                    thumb.toolTip = "Step \(idx + 1): \(f.label)"
                    thumb.layer?.borderColor = (idx == self.historyFrames.count - 1) ?
                        NSColor.cyan.cgColor : NSColor.white.withAlphaComponent(0.2).cgColor
                } else {
                    thumb.image = nil
                    thumb.toolTip = nil
                    thumb.layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
                }
            }
        }
    }

    @objc func handleThumbnailClick(_ sender: NSClickGestureRecognizer) {
        guard let view = sender.view as? NSImageView else { return }
        let index = view.tag
        if index < historyFrames.count {
            let frame = historyFrames[index]
            previewImageView.image = frame.image
            statusLabel.stringValue = "[ประวัติขั้นตอนที่ \(index + 1)] \(frame.label)"
        }
    }

    // MARK: - Phase 2: Status Pill & Safety Approval Container
    private func setupStatusAndApprovalPill(width: CGFloat) {
        let pillWidth: CGFloat = width - 28
        let pillHeight: CGFloat = 32
        statusPillView = NSVisualEffectView(frame: NSRect(x: 14, y: 10, width: pillWidth, height: pillHeight))
        statusPillView.material = .hudWindow
        statusPillView.blendingMode = .withinWindow
        statusPillView.state = .active
        statusPillView.wantsLayer = true
        statusPillView.layer?.cornerRadius = 16
        statusPillView.layer?.masksToBounds = true
        statusPillView.layer?.borderWidth = 1.0
        statusPillView.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        statusPillView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.25).cgColor

        // Spinner
        spinnerIndicator = NSProgressIndicator(frame: NSRect(x: 10, y: 8, width: 16, height: 16))
        spinnerIndicator.style = .spinning
        spinnerIndicator.controlSize = .small
        spinnerIndicator.startAnimation(nil)
        statusPillView.addSubview(spinnerIndicator)

        // Status Label
        statusLabel = NSTextField(labelWithString: "Working... เตรียมความพร้อมระบบ")
        statusLabel.frame = NSRect(x: 34, y: 6, width: pillWidth - 44, height: 20)
        statusLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = NSColor.white
        statusPillView.addSubview(statusLabel)

        // Approval Gate Overlay (Hidden by default)
        approvalContainer = NSView(frame: NSRect(x: 0, y: 0, width: pillWidth, height: pillHeight))
        approvalContainer.wantsLayer = true
        approvalContainer.layer?.cornerRadius = 16
        approvalContainer.layer?.backgroundColor = NSColor(red: 0.25, green: 0.05, blue: 0.05, alpha: 0.95).cgColor
        approvalContainer.isHidden = true

        approvalLabel = NSTextField(labelWithString: "🔴 ยืนยันการทำงานที่มีความเสี่ยง?")
        approvalLabel.frame = NSRect(x: 10, y: 6, width: pillWidth - 170, height: 20)
        approvalLabel.font = NSFont.systemFont(ofSize: 10.5, weight: .bold)
        approvalLabel.textColor = NSColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
        approvalContainer.addSubview(approvalLabel)

        // Approve Button
        approveBtn = NSButton(frame: NSRect(x: pillWidth - 156, y: 5, width: 72, height: 22))
        approveBtn.title = "อนุมัติ"
        approveBtn.font = NSFont.systemFont(ofSize: 10.5, weight: .bold)
        approveBtn.wantsLayer = true
        approveBtn.layer?.cornerRadius = 5
        approveBtn.layer?.backgroundColor = NSColor(red: 0.15, green: 0.75, blue: 0.25, alpha: 0.9).cgColor
        approveBtn.contentTintColor = NSColor.white
        approveBtn.isBordered = false
        approveBtn.target = self
        approveBtn.action = #selector(handleApproveClick)
        approvalContainer.addSubview(approveBtn)

        // Deny Button
        denyBtn = NSButton(frame: NSRect(x: pillWidth - 78, y: 5, width: 70, height: 22))
        denyBtn.title = "ปฏิเสธ"
        denyBtn.font = NSFont.systemFont(ofSize: 10.5, weight: .bold)
        denyBtn.wantsLayer = true
        denyBtn.layer?.cornerRadius = 5
        denyBtn.layer?.backgroundColor = NSColor(red: 0.9, green: 0.25, blue: 0.25, alpha: 0.9).cgColor
        denyBtn.contentTintColor = NSColor.white
        denyBtn.isBordered = false
        denyBtn.target = self
        denyBtn.action = #selector(handleDenyClick)
        approvalContainer.addSubview(denyBtn)

        statusPillView.addSubview(approvalContainer)
        visualEffectView.addSubview(statusPillView)
    }

    func requestApproval(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.approvalLabel.stringValue = "🔴 \(message)"
            self.approvalContainer.isHidden = false
            self.visualEffectView.layer?.borderColor = NSColor.systemRed.cgColor
            self.visualEffectView.layer?.borderWidth = 2.0
            self.orderFrontRegardless()
        }
    }

    @objc func handleApproveClick() {
        sendApprovalResponse("approve")
        dismissApprovalUI()
    }

    @objc func handleDenyClick() {
        sendApprovalResponse("deny")
        dismissApprovalUI()
    }

    private func sendApprovalResponse(_ response: String) {
        let pipePath = "/tmp/cua_approval.pipe"
        DispatchQueue.global(qos: .userInitiated).async {
            if let handle = FileHandle(forWritingAtPath: pipePath) {
                if let data = (response + "\n").data(using: .utf8) {
                    handle.write(data)
                    try? handle.close()
                }
            }
        }
    }

    private func dismissApprovalUI() {
        approvalContainer.isHidden = true
        visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.25).cgColor
        visualEffectView.layer?.borderWidth = 1.0
    }

    func setStatus(_ text: String, isDone: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.statusLabel.stringValue = text
            if isDone {
                self.spinnerIndicator.stopAnimation(nil)
                self.spinnerIndicator.isHidden = true
                self.statusLabel.frame = NSRect(x: 14, y: 6, width: self.statusPillView.frame.width - 28, height: 20)
                self.statusLabel.alignment = .center
            } else {
                self.spinnerIndicator.isHidden = false
                self.spinnerIndicator.startAnimation(nil)
                self.statusLabel.frame = NSRect(x: 34, y: 6, width: self.statusPillView.frame.width - 44, height: 20)
                self.statusLabel.alignment = .left
            }
            self.updateScreenPreview()
            self.addActionSnapshot(label: text)
        }
    }

    private var lastCaptureTime: TimeInterval = 0
    func updateScreenPreview() {
        let now = Date().timeIntervalSince1970
        if now - lastCaptureTime < 1.5 { return }
        lastCaptureTime = now
        forceScreenPreview()
    }

    func forceScreenPreview() {
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

    @objc func handleCloseHUD() {
        NSApp.terminate(nil)
    }

    @objc func handleToggleCollapse() {
        var frame = self.frame
        if isCollapsed {
            frame.size.height = standardHeight
            frame.origin.y -= (standardHeight - 48)
            previewImageView.isHidden = false
            filmstripStackView.superview?.isHidden = false
            statusPillView.isHidden = false
            isCollapsed = false
        } else {
            frame.size.height = 48
            frame.origin.y += (standardHeight - 48)
            previewImageView.isHidden = true
            filmstripStackView.superview?.isHidden = true
            statusPillView.isHidden = true
            isCollapsed = true
        }
        self.setFrame(frame, display: true, animate: true)
    }

    @objc func handleRefreshPreview() {
        forceScreenPreview()
    }

    @objc func handlePreviewClick() {
        forceScreenPreview()
        let script = "tell application \"System Events\" to tell (first process whose frontmost is false and visible is true) to set frontmost to true"
        let p = Process()
        p.launchPath = "/usr/bin/osascript"
        p.arguments = ["-e", script]
        try? p.run()
    }

    func updateMiniPointer(targetScreenPoint: CGPoint) {
        guard let screen = NSScreen.main else { return }
        let previewBounds = previewImageView.bounds
        let normX = targetScreenPoint.x / screen.frame.width
        let normY = targetScreenPoint.y / screen.frame.height

        let miniX = normX * previewBounds.width
        let miniY = normY * previewBounds.height

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.4)
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

        registerGlobalHotkeys()
        startPipeListener()

        let args = ProcessInfo.processInfo.arguments
        if args.contains("demo") {
            runDemoScenario()
        }
    }

    // Phase 3: Global Hotkey Listener (⌥Space and ⌘K)
    private func registerGlobalHotkeys() {
        // Global monitor for ⌥Space (Option + Space) across any app
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                DispatchQueue.main.async {
                    self?.miniDisplay.showAndFocusCommandBar()
                }
            }
        }

        // Local monitor when HUD is active (⌘K to toggle command bar)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.command) && event.keyCode == 40 {
                DispatchQueue.main.async {
                    self?.miniDisplay.toggleCommandInput()
                }
                return nil
            }
            return event
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
        if !FileManager.default.fileExists(atPath: commandPipePath) {
            mkfifo(commandPipePath, 0o666)
        }
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
        let parts = line.components(separatedBy: "|")
        guard let header = parts.first else { return }

        // 1. Quit Command
        if header.lowercased() == "quit" || header.lowercased() == "exit" {
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
            return
        }

        // 2. Phase 2: Safety Approval Gate Command: ask_approval|<message>
        if header.lowercased() == "ask_approval" {
            let warningMsg = (parts.count > 1) ? parts[1] : "ยืนยันการทำคำสั่งเสี่ยง?"
            miniDisplay.requestApproval(message: warningMsg)
            return
        }

        // 3. Phase 1: Neural Vision OCR Click Command: ocr_click|<target_text>
        if header.lowercased() == "ocr_click" {
            let targetQuery = (parts.count > 1) ? parts[1] : ""
            executeOCRClick(query: targetQuery)
            return
        }

        // 4. Standard Coordinate Movement Command: <status>|<x>|<y>|<click>|<done>
        let status = header
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
        }
    }

    // Phase 1: Apple Vision Neural Engine OCR Execution
    private func executeOCRClick(query: String) {
        miniDisplay.setStatus("Working... Apple Vision กำลังตรวจหา '\(query)' บนหน้าจอ")
        let snapshotPath = "/tmp/cua_ocr_temp.jpg"

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let captureProc = Process()
            captureProc.launchPath = "/usr/sbin/screencapture"
            captureProc.arguments = ["-x", "-t", "jpg", snapshotPath]
            try? captureProc.run()
            captureProc.waitUntilExit()

            guard let img = NSImage(contentsOfFile: snapshotPath),
                  let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                DispatchQueue.main.async {
                    self?.miniDisplay.setStatus("ล้มเหลว: ไม่สามารถจับภาพหน้าจอเพื่อทำ OCR", isDone: true)
                }
                return
            }

            ScreenOCRDetector.shared.findTextLocation(query: query, in: cgImage) { [weak self] targetPoint, matchedText in
                DispatchQueue.main.async {
                    if let pt = targetPoint, let found = matchedText {
                        self?.updateAction(
                            status: "พบ '\(found)' บนหน้าจอ! กำลังคลิก (x:\(Int(pt.x)), y:\(Int(pt.y)))",
                            x: pt.x,
                            y: pt.y,
                            click: true,
                            isDone: true
                        )
                    } else {
                        self?.miniDisplay.setStatus("ไม่พบข้อความ '\(query)' บนหน้าจอ [WARN]", isDone: true)
                    }
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
    }
}

// MARK: - Main Entry Point
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = HUDAppController()
app.delegate = delegate
app.run()
