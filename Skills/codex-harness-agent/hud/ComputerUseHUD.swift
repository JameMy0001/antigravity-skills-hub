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
        self.hidesOnDeactivate = false
        self.isReleasedWhenClosed = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        cursorView = GhostCursorView(frame: screenRect)
        self.contentView = cursorView
    }

    func moveCursor(to point: CGPoint, animated: Bool = true, completion: (() -> Void)? = nil) {
        cursorView.moveTo(point: point, animated: animated, completion: completion)
    }

    func clickAt(point: CGPoint, completion: (() -> Void)? = nil) {
        cursorView.clickAt(point: point, completion: completion)
    }

    func hideCursor(animated: Bool = true) {
        cursorView.hideCursor(animated: animated)
    }

    func showCursor(animated: Bool = true) {
        cursorView.showCursor(animated: animated)
    }
}

// MARK: - Ghost Cursor View
class GhostCursorView: NSView {
    private var pointerLayer: CALayer!
    private var rippleLayer: CAShapeLayer!
    private(set) var currentPosition: CGPoint = CGPoint(x: 400, y: 400)
    private var idleTimer: Timer?

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
        pointerLayer.opacity = 0.0 // Start hidden on boot! Zero frozen cursor.

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

    func showCursor(animated: Bool = true) {
        resetIdleTimer()
        if pointerLayer.opacity >= 0.95 { return }
        if animated {
            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue = pointerLayer.opacity
            anim.toValue = 1.0
            anim.duration = 0.2
            pointerLayer.opacity = 1.0
            pointerLayer.add(anim, forKey: "fadeIn")
        } else {
            pointerLayer.opacity = 1.0
        }
    }

    func hideCursor(animated: Bool = true) {
        idleTimer?.invalidate()
        idleTimer = nil
        if pointerLayer.opacity <= 0.05 { return }
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.35)
            CATransaction.setCompletionBlock { [weak self] in
                self?.pointerLayer.opacity = 0.0
            }
            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue = pointerLayer.opacity
            anim.toValue = 0.0
            anim.duration = 0.35
            pointerLayer.opacity = 0.0
            pointerLayer.add(anim, forKey: "fadeOut")
            CATransaction.commit()
        } else {
            pointerLayer.opacity = 0.0
        }
    }

    private func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.hideCursor(animated: true)
        }
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
        showCursor(animated: animated)
        if !animated {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            pointerLayer.position = point
            currentPosition = point
            CATransaction.commit()
            resetIdleTimer()
            completion?()
            return
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.4)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        CATransaction.setCompletionBlock { [weak self] in
            self?.currentPosition = point
            self?.resetIdleTimer()
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
        showCursor(animated: true)
        moveTo(point: point, animated: true) { [weak self] in
            guard let self = self else { return }
            self.triggerClickRipple(at: point)
            self.resetIdleTimer()
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
    private var headerBarView: NSView!
    private var redBtn: NSButton!
    private var yellowBtn: NSButton!
    private var greenBtn: NSButton!
    private var titleLabel: NSTextField!
    private var cmdToggleBtn: NSButton!

    // Phase 4: Human Takeover Mode & Sensitive Field Privacy Shield
    var isTakeoverMode = false
    private var takeoverHeaderBtn: NSButton!
    private var takeoverContainer: NSView!
    private var takeoverLabel: NSTextField!
    private var takeoverResumeBtn: NSButton!

    // Collapsed Dynamic Island Pill Controls
    private var headerSpinner: NSProgressIndicator!
    private var headerStatusLabel: NSTextField!
    private var headerExpandBtn: NSButton!

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
    private var filmstripTrayContainer: NSView!
    private var emptyHistoryLabel: NSTextField!
    private var filmstripStackView: NSStackView!
    private var historyFrames: [ActionFrame] = []
    private var thumbnailViews: [NSImageView] = []

    private var isCollapsed = false
    private let standardWidth: CGFloat = 460
    private let standardHeight: CGFloat = 350

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    init() {
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let padding: CGFloat = 20
        let x = screenRect.maxX - standardWidth - padding
        let y = screenRect.maxY - standardHeight - padding

        super.init(
            contentRect: NSRect(x: x, y: y, width: standardWidth, height: standardHeight),
            styleMask: [.borderless],
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
        self.hidesOnDeactivate = false
        self.isReleasedWhenClosed = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        setupUI(width: standardWidth, height: standardHeight)
    }

    override func cancelOperation(_ sender: Any?) {
        if commandBoxVisible {
            commandBoxVisible = false
            applyCommandBoxVisibility()
        }
        // Do not call super to prevent closing/ordering out the Mini Display
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

        // Header Bar Container
        setupHeader(width: width, height: height)

        // Screen Preview Area (Clean 8px below header, 8px above filmstrip)
        let previewRect = NSRect(x: 14, y: 94, width: width - 28, height: 210)
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

        // Phase 4: Filmstrip History Carousel Tray (y: 50, height: 36)
        setupFilmstripTray(width: width)

        // Phase 2 & 3: Status Pill, Safety Approval Container & Integrated Command Bar (Bottom y: 10, height: 32)
        setupStatusAndApprovalPill(width: width)

        self.contentView = visualEffectView
        updateScreenPreview()
    }

    private func setupHeader(width: CGFloat, height: CGFloat) {
        headerBarView = NSView(frame: NSRect(x: 0, y: height - 38, width: width, height: 38))
        headerBarView.wantsLayer = true

        let headerClick = NSClickGestureRecognizer(target: self, action: #selector(handleHeaderBarClick))
        headerBarView.addGestureRecognizer(headerClick)

        // Red: Close
        redBtn = NSButton(frame: NSRect(x: 16, y: 13, width: 12, height: 12))
        redBtn.isBordered = false
        redBtn.title = ""
        redBtn.wantsLayer = true
        redBtn.layer?.cornerRadius = 6
        redBtn.layer?.backgroundColor = NSColor(red: 1.0, green: 0.37, blue: 0.34, alpha: 0.95).cgColor
        redBtn.toolTip = "ปิดหน้าต่าง Mini Display (Close)"
        redBtn.target = self
        redBtn.action = #selector(handleCloseHUD)
        headerBarView.addSubview(redBtn)

        // Yellow: Collapse / Expand
        yellowBtn = NSButton(frame: NSRect(x: 34, y: 13, width: 12, height: 12))
        yellowBtn.isBordered = false
        yellowBtn.title = ""
        yellowBtn.wantsLayer = true
        yellowBtn.layer?.cornerRadius = 6
        yellowBtn.layer?.backgroundColor = NSColor(red: 1.0, green: 0.74, blue: 0.18, alpha: 0.95).cgColor
        yellowBtn.toolTip = "ย่อหน้าต่างเป็นแถบสถานะ (Collapse to Pill)"
        yellowBtn.target = self
        yellowBtn.action = #selector(handleToggleCollapse)
        headerBarView.addSubview(yellowBtn)

        // Green: Refresh Snapshot
        greenBtn = NSButton(frame: NSRect(x: 52, y: 13, width: 12, height: 12))
        greenBtn.isBordered = false
        greenBtn.title = ""
        greenBtn.wantsLayer = true
        greenBtn.layer?.cornerRadius = 6
        greenBtn.layer?.backgroundColor = NSColor(red: 0.15, green: 0.79, blue: 0.25, alpha: 0.95).cgColor
        greenBtn.toolTip = "รีเฟรชภาพหน้าจอล่าสุด (Refresh Preview)"
        greenBtn.target = self
        greenBtn.action = #selector(handleRefreshPreview)
        headerBarView.addSubview(greenBtn)

        // Title Label (Shown when expanded)
        titleLabel = NSTextField(labelWithString: "Computer Use Mini Display")
        titleLabel.frame = NSRect(x: 74, y: 9, width: width - 235, height: 20)
        titleLabel.font = NSFont.systemFont(ofSize: 11.5, weight: .semibold)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.9)
        titleLabel.alignment = .center
        headerBarView.addSubview(titleLabel)

        // Phase 4: Human Takeover Button [Take Over]
        takeoverHeaderBtn = NSButton(frame: NSRect(x: width - 142, y: 9, width: 88, height: 18))
        takeoverHeaderBtn.isBordered = false
        takeoverHeaderBtn.title = "Take Over"
        takeoverHeaderBtn.font = NSFont.systemFont(ofSize: 9.5, weight: .bold)
        takeoverHeaderBtn.wantsLayer = true
        takeoverHeaderBtn.layer?.cornerRadius = 4
        takeoverHeaderBtn.layer?.backgroundColor = NSColor(red: 0.96, green: 0.62, blue: 0.07, alpha: 0.2).cgColor
        takeoverHeaderBtn.layer?.borderWidth = 0.8
        takeoverHeaderBtn.layer?.borderColor = NSColor(red: 0.96, green: 0.62, blue: 0.07, alpha: 0.8).cgColor
        takeoverHeaderBtn.contentTintColor = NSColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        takeoverHeaderBtn.toolTip = "เข้าควบคุมหน้าจอด้วยตัวเองชั่วคราวและระงับการจับภาพ (Human Takeover Mode)"
        takeoverHeaderBtn.target = self
        takeoverHeaderBtn.action = #selector(handleTakeoverHeaderClick)
        headerBarView.addSubview(takeoverHeaderBtn)

        // Phase 3: Toggle Command Box Button [⌘K] (Shown when expanded)
        cmdToggleBtn = NSButton(frame: NSRect(x: width - 48, y: 9, width: 34, height: 18))
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
        headerBarView.addSubview(cmdToggleBtn)

        // Collapsed View: Mini Spinner (Hidden when expanded)
        headerSpinner = NSProgressIndicator(frame: NSRect(x: 74, y: 11, width: 16, height: 16))
        headerSpinner.style = .spinning
        headerSpinner.controlSize = .small
        headerSpinner.startAnimation(nil)
        headerSpinner.isHidden = true
        headerBarView.addSubview(headerSpinner)

        // Collapsed View: Live Status Label (Hidden when expanded)
        headerStatusLabel = NSTextField(labelWithString: "พร้อมทำงาน...")
        headerStatusLabel.frame = NSRect(x: 96, y: 9, width: width - 140, height: 20)
        headerStatusLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        headerStatusLabel.textColor = NSColor.white
        headerStatusLabel.alignment = .left
        headerStatusLabel.isHidden = true
        headerBarView.addSubview(headerStatusLabel)

        // Collapsed View: Expand Button (Hidden when expanded)
        headerExpandBtn = NSButton(frame: NSRect(x: width - 38, y: 9, width: 24, height: 20))
        headerExpandBtn.isBordered = false
        headerExpandBtn.title = "⤢"
        headerExpandBtn.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        headerExpandBtn.wantsLayer = true
        headerExpandBtn.layer?.cornerRadius = 4
        headerExpandBtn.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.15).cgColor
        headerExpandBtn.contentTintColor = NSColor.white
        headerExpandBtn.toolTip = "ขยายหน้าต่าง (Expand)"
        headerExpandBtn.target = self
        headerExpandBtn.action = #selector(handleToggleCollapse)
        headerExpandBtn.isHidden = true
        headerBarView.addSubview(headerExpandBtn)

        visualEffectView.addSubview(headerBarView)
    }

    @objc func handleHeaderBarClick() {
        if isCollapsed {
            handleToggleCollapse()
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            commandBoxVisible = false
            applyCommandBoxVisibility()
            return true
        }
        return false
    }

    func controlTextDidBeginEditing(_ obj: Notification) {
        if let fieldEditor = (obj.object as? NSTextField)?.currentEditor() as? NSTextView {
            fieldEditor.insertionPointColor = NSColor.cyan
        }
    }

    @objc func handleStatusPillClick() {
        if !commandBoxVisible && (approvalContainer == nil || approvalContainer.isHidden) {
            showAndFocusCommandBar()
        }
    }

    @objc func toggleCommandInput() {
        if isCollapsed {
            handleToggleCollapse()
        }
        commandBoxVisible = !commandBoxVisible
        applyCommandBoxVisibility()
    }

    func showAndFocusCommandBar() {
        if isCollapsed {
            handleToggleCollapse()
        }
        commandBoxVisible = true
        applyCommandBoxVisibility()
    }

    private func applyCommandBoxVisibility() {
        if commandBoxVisible {
            spinnerIndicator.isHidden = true
            statusLabel.isHidden = true
            commandInputBox.isHidden = false
            statusPillView.layer?.borderColor = NSColor.cyan.cgColor
            statusPillView.layer?.borderWidth = 1.5
            cmdToggleBtn.layer?.backgroundColor = NSColor.cyan.withAlphaComponent(0.3).cgColor
            cmdToggleBtn.contentTintColor = NSColor.cyan

            NSApp.activate(ignoringOtherApps: true)
            self.makeKeyAndOrderFront(nil)
            self.makeFirstResponder(commandInputBox)
            if let fieldEditor = self.fieldEditor(true, for: commandInputBox) as? NSTextView {
                fieldEditor.insertionPointColor = NSColor.cyan
            }
        } else {
            commandInputBox.isHidden = true
            statusLabel.isHidden = false
            spinnerIndicator.isHidden = statusLabel.stringValue.contains("[PASS]") || statusLabel.stringValue.contains("พร้อม")
            statusPillView.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
            statusPillView.layer?.borderWidth = 1.0
            cmdToggleBtn.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.15).cgColor
            cmdToggleBtn.contentTintColor = NSColor.white
            self.resignFirstResponder()
        }
    }

    @objc func handleCommandSubmit() {
        let taskText = commandInputBox.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        commandInputBox.stringValue = ""
        commandBoxVisible = false
        applyCommandBoxVisibility()

        if !taskText.isEmpty {
            setStatus("Working... เริ่มต้นคำสั่ง: \(taskText)", isDone: false)

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
        miniPointerLayer.opacity = 0.0 // Start hidden on boot! Zero frozen pointer.
        previewImageView.layer?.addSublayer(miniPointerLayer)
    }

    // MARK: - Phase 4: Filmstrip History Carousel
    private func setupFilmstripTray(width: CGFloat) {
        let trayRect = NSRect(x: 14, y: 50, width: width - 28, height: 36)
        filmstripTrayContainer = NSView(frame: trayRect)
        filmstripTrayContainer.wantsLayer = true
        filmstripTrayContainer.layer?.cornerRadius = 6
        filmstripTrayContainer.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.2).cgColor
        filmstripTrayContainer.layer?.borderWidth = 0.5
        filmstripTrayContainer.layer?.borderColor = NSColor.white.withAlphaComponent(0.1).cgColor

        emptyHistoryLabel = NSTextField(labelWithString: "Filmstrip Carousel: บันทึกภาพย้อนหลังอัตโนมัติเมื่อเริ่มงาน")
        emptyHistoryLabel.frame = NSRect(x: 10, y: 9, width: trayRect.width - 20, height: 18)
        emptyHistoryLabel.alignment = .center
        emptyHistoryLabel.font = NSFont.systemFont(ofSize: 10.5, weight: .regular)
        emptyHistoryLabel.textColor = NSColor.white.withAlphaComponent(0.35)
        emptyHistoryLabel.isHidden = true
        filmstripTrayContainer.addSubview(emptyHistoryLabel)

        filmstripStackView = NSStackView(frame: NSRect(x: 4, y: 3, width: trayRect.width - 8, height: 30))
        filmstripStackView.orientation = .horizontal
        filmstripStackView.spacing = 6
        filmstripStackView.distribution = .fillEqually

        // Create 6 thumbnail slots
        thumbnailViews.removeAll()
        for i in 0..<6 {
            let thumb = NSImageView(frame: NSRect(x: 0, y: 0, width: 64, height: 30))
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

        filmstripTrayContainer.addSubview(filmstripStackView)
        visualEffectView.addSubview(filmstripTrayContainer)
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
            self.emptyHistoryLabel.isHidden = !self.historyFrames.isEmpty
            self.filmstripStackView.isHidden = self.historyFrames.isEmpty

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

        // Click anywhere on status pill to open command bar
        let pillClickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleStatusPillClick))
        statusPillView.addGestureRecognizer(pillClickGesture)

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

        // Phase 3: Seamless In-Pill Command Input Box (Zero overlap on preview!)
        commandInputBox = NSTextField(frame: NSRect(x: 14, y: 5, width: pillWidth - 28, height: 22))
        commandInputBox.placeholderString = "⌘K สั่งงาน Agent (พิมพ์คำสั่งแล้วกด Enter, Esc เพื่อยกเลิก)..."
        commandInputBox.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        commandInputBox.textColor = NSColor.white
        commandInputBox.backgroundColor = .clear
        commandInputBox.isBordered = false
        commandInputBox.focusRingType = .none
        commandInputBox.isEditable = true
        commandInputBox.isSelectable = true
        commandInputBox.refusesFirstResponder = false
        commandInputBox.target = self
        commandInputBox.action = #selector(handleCommandSubmit)
        commandInputBox.delegate = self
        commandInputBox.isHidden = true
        statusPillView.addSubview(commandInputBox)

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

        // Phase 4: Human Takeover Overlay Container (Hidden by default)
        takeoverContainer = NSView(frame: NSRect(x: 0, y: 0, width: pillWidth, height: pillHeight))
        takeoverContainer.wantsLayer = true
        takeoverContainer.layer?.cornerRadius = 16
        takeoverContainer.layer?.backgroundColor = NSColor(red: 0.26, green: 0.16, blue: 0.03, alpha: 0.96).cgColor
        takeoverContainer.layer?.borderWidth = 1.0
        takeoverContainer.layer?.borderColor = NSColor(red: 0.96, green: 0.62, blue: 0.07, alpha: 0.95).cgColor
        takeoverContainer.isHidden = true

        takeoverLabel = NSTextField(labelWithString: "🟡 [TAKEOVER] AI Paused - Private Shield Active")
        takeoverLabel.frame = NSRect(x: 12, y: 6, width: pillWidth - 118, height: 20)
        takeoverLabel.font = NSFont.systemFont(ofSize: 10.0, weight: .bold)
        takeoverLabel.textColor = NSColor(red: 1.0, green: 0.82, blue: 0.2, alpha: 1.0)
        takeoverContainer.addSubview(takeoverLabel)

        takeoverResumeBtn = NSButton(frame: NSRect(x: pillWidth - 96, y: 5, width: 90, height: 22))
        takeoverResumeBtn.title = "Resume AI"
        takeoverResumeBtn.font = NSFont.systemFont(ofSize: 10.5, weight: .bold)
        takeoverResumeBtn.wantsLayer = true
        takeoverResumeBtn.layer?.cornerRadius = 5
        takeoverResumeBtn.layer?.backgroundColor = NSColor(red: 0.15, green: 0.75, blue: 0.25, alpha: 0.95).cgColor
        takeoverResumeBtn.contentTintColor = NSColor.white
        takeoverResumeBtn.isBordered = false
        takeoverResumeBtn.target = self
        takeoverResumeBtn.action = #selector(handleTakeoverResumeClick)
        takeoverContainer.addSubview(takeoverResumeBtn)

        statusPillView.addSubview(takeoverContainer)
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

    // MARK: - Phase 4: Human Takeover Mode Handlers
    @objc func handleTakeoverHeaderClick() {
        if isTakeoverMode {
            exitTakeoverMode()
        } else {
            enterTakeoverMode(reason: "Human Takeover Mode (Screen Capture Paused)")
        }
    }

    @objc func handleTakeoverResumeClick() {
        exitTakeoverMode()
    }

    func enterTakeoverMode(reason: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isTakeoverMode = true
            self.takeoverLabel.stringValue = "🟡 [TAKEOVER] \(reason)"
            self.takeoverContainer.isHidden = false
            self.takeoverHeaderBtn.title = "Resume"
            self.takeoverHeaderBtn.layer?.backgroundColor = NSColor(red: 0.15, green: 0.75, blue: 0.25, alpha: 0.4).cgColor
            self.takeoverHeaderBtn.contentTintColor = NSColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1.0)
            self.visualEffectView.layer?.borderColor = NSColor(red: 0.96, green: 0.62, blue: 0.07, alpha: 0.95).cgColor
            self.visualEffectView.layer?.borderWidth = 2.0
            self.hideMiniPointer(animated: true)
            HUDAppController.shared?.ghostCursor.hideCursor(animated: true)
            self.orderFrontRegardless()
            self.sendTakeoverSignal("takeover_active")
        }
    }

    func exitTakeoverMode() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isTakeoverMode = false
            self.takeoverContainer.isHidden = true
            self.takeoverHeaderBtn.title = "Take Over"
            self.takeoverHeaderBtn.layer?.backgroundColor = NSColor(red: 0.96, green: 0.62, blue: 0.07, alpha: 0.2).cgColor
            self.takeoverHeaderBtn.contentTintColor = NSColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
            self.visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.25).cgColor
            self.visualEffectView.layer?.borderWidth = 1.0
            self.sendTakeoverSignal("resumed")
            self.setStatus("Working... ผู้ใช้ส่งคืนการควบคุม กำลังดำเนินงานต่อ")
        }
    }

    private func sendTakeoverSignal(_ signal: String) {
        let pipePath = "/tmp/cua_takeover.pipe"
        DispatchQueue.global(qos: .userInitiated).async {
            if let handle = FileHandle(forWritingAtPath: pipePath) {
                if let data = (signal + "\n").data(using: .utf8) {
                    handle.write(data)
                    try? handle.close()
                }
            }
        }
    }

    func setStatus(_ text: String, isDone: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.statusLabel.stringValue = text
            self.headerStatusLabel.stringValue = text

            if isDone {
                self.spinnerIndicator.stopAnimation(nil)
                self.spinnerIndicator.isHidden = true
                self.headerSpinner.stopAnimation(nil)
                self.headerSpinner.isHidden = true
                self.statusLabel.frame = NSRect(x: 14, y: 6, width: self.statusPillView.frame.width - 28, height: 20)
                self.statusLabel.alignment = .center
                self.hideMiniPointer(animated: true)
            } else {
                self.spinnerIndicator.isHidden = false
                self.spinnerIndicator.startAnimation(nil)
                if self.isCollapsed {
                    self.headerSpinner.isHidden = false
                    self.headerSpinner.startAnimation(nil)
                }
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
        if isTakeoverMode {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, !self.isTakeoverMode else { return }
            let path = "/tmp/cua_preview.jpg"
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = ["-x", "-t", "jpg", path]
            try? task.run()
            task.waitUntilExit()

            if let img = NSImage(contentsOfFile: path) {
                DispatchQueue.main.async {
                    self.previewImageView.image = img
                }
            }
        }
    }

    @objc func handleCloseHUD() {
        NSApp.terminate(nil)
    }

    @objc func handleToggleCollapse() {
        let currentFrame = self.frame
        let topY = currentFrame.maxY

        if isCollapsed {
            // Expand to full Mini Display
            let newFrame = NSRect(x: currentFrame.origin.x, y: topY - standardHeight, width: standardWidth, height: standardHeight)
            self.setFrame(newFrame, display: true, animate: true)

            visualEffectView.frame = NSRect(x: 0, y: 0, width: standardWidth, height: standardHeight)
            visualEffectView.layer?.cornerRadius = 18

            headerBarView.frame = NSRect(x: 0, y: standardHeight - 38, width: standardWidth, height: 38)
            titleLabel.isHidden = false
            takeoverHeaderBtn?.isHidden = false
            cmdToggleBtn.isHidden = false
            headerSpinner.isHidden = true
            headerStatusLabel.isHidden = true
            headerExpandBtn.isHidden = true

            previewImageView.isHidden = false
            filmstripTrayContainer?.isHidden = false
            statusPillView.isHidden = false
            yellowBtn.toolTip = "ย่อหน้าต่างเป็นแถบสถานะ (Collapse to Pill)"
            isCollapsed = false
        } else {
            // Collapse to compact Dynamic Island pill
            let collapsedHeight: CGFloat = 40
            let newFrame = NSRect(x: currentFrame.origin.x, y: topY - collapsedHeight, width: standardWidth, height: collapsedHeight)
            self.setFrame(newFrame, display: true, animate: true)

            visualEffectView.frame = NSRect(x: 0, y: 0, width: standardWidth, height: collapsedHeight)
            visualEffectView.layer?.cornerRadius = 20

            headerBarView.frame = NSRect(x: 0, y: 1, width: standardWidth, height: 38)
            titleLabel.isHidden = true
            takeoverHeaderBtn?.isHidden = true
            cmdToggleBtn.isHidden = true
            let isFinished = statusLabel.stringValue.contains("[PASS]") || statusLabel.stringValue.contains("พร้อม")
            headerSpinner.isHidden = isFinished
            if !isFinished {
                headerSpinner.startAnimation(nil)
            }
            headerStatusLabel.stringValue = statusLabel.stringValue
            headerStatusLabel.isHidden = false
            headerExpandBtn.isHidden = false

            previewImageView.isHidden = true
            filmstripTrayContainer?.isHidden = true
            statusPillView.isHidden = true
            commandInputBox.isHidden = true
            commandBoxVisible = false
            yellowBtn.toolTip = "ขยายหน้าต่างเต็ม (Expand)"
            isCollapsed = true
        }
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

    func showMiniPointer(animated: Bool = true) {
        if miniPointerLayer.opacity >= 0.95 { return }
        if animated {
            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue = miniPointerLayer.opacity
            anim.toValue = 1.0
            anim.duration = 0.2
            miniPointerLayer.opacity = 1.0
            miniPointerLayer.add(anim, forKey: "fadeIn")
        } else {
            miniPointerLayer.opacity = 1.0
        }
    }

    func hideMiniPointer(animated: Bool = true) {
        if miniPointerLayer.opacity <= 0.05 { return }
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.35)
            CATransaction.setCompletionBlock { [weak self] in
                self?.miniPointerLayer.opacity = 0.0
            }
            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue = miniPointerLayer.opacity
            anim.toValue = 0.0
            anim.duration = 0.35
            miniPointerLayer.opacity = 0.0
            miniPointerLayer.add(anim, forKey: "fadeOut")
            CATransaction.commit()
        } else {
            miniPointerLayer.opacity = 0.0
        }
    }

    func updateMiniPointer(targetScreenPoint: CGPoint) {
        showMiniPointer(animated: true)
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
    static weak var shared: HUDAppController?
    var miniDisplay: MiniDisplayWindow!
    var ghostCursor: GhostCursorWindow!
    var commandPipePath = "/tmp/cua_hud.pipe"

    func applicationDidFinishLaunching(_ notification: Notification) {
        HUDAppController.shared = self
        miniDisplay = MiniDisplayWindow()
        ghostCursor = GhostCursorWindow()

        miniDisplay.orderFrontRegardless()
        ghostCursor.orderFrontRegardless()

        registerGlobalHotkeys()
        startPipeListener()

        // Populate initial frame so filmstrip is never an empty void
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.miniDisplay.forceScreenPreview()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.miniDisplay.addActionSnapshot(label: "เริ่มต้นระบบ (Ready)")
            }
        }

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

        if isDone {
            ghostCursor.hideCursor(animated: true)
            miniDisplay.hideMiniPointer(animated: true)
        }

        if let px = x, let py = y {
            if px > 0 || py > 0 {
                let pt = CGPoint(x: px, y: py)
                miniDisplay.updateMiniPointer(targetScreenPoint: pt)
                if click {
                    ghostCursor.clickAt(point: pt)
                } else {
                    ghostCursor.moveCursor(to: pt)
                }
            }
        }
    }

    func startPipeListener() {
        if !FileManager.default.fileExists(atPath: commandPipePath) {
            mkfifo(commandPipePath, 0o666)
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let pipePath = self?.commandPipePath else { return }
            let fd = open(pipePath, O_RDWR)
            guard fd >= 0 else { return }
            var buffer = [UInt8](repeating: 0, count: 4096)
            var currentLine = ""
            while true {
                let bytesRead = read(fd, &buffer, buffer.count)
                if bytesRead > 0 {
                    let chunk = String(decoding: buffer[0..<bytesRead], as: UTF8.self)
                    currentLine += chunk
                    while let newlineRange = currentLine.range(of: "\n") {
                        let line = String(currentLine[..<newlineRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                        currentLine = String(currentLine[newlineRange.upperBound...])
                        if !line.isEmpty {
                            self?.handleCommandString(line)
                        }
                    }
                } else {
                    usleep(10000) // 10ms sleep
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

        // Hide Cursor Command: hide_cursor or cursor_hide
        if header.lowercased() == "hide_cursor" || header.lowercased() == "cursor_hide" {
            DispatchQueue.main.async { [weak self] in
                self?.ghostCursor.hideCursor(animated: true)
                self?.miniDisplay.hideMiniPointer(animated: true)
            }
            return
        }

        // Toggle Collapse Command: collapse or toggle_collapse
        if header.lowercased() == "collapse" || header.lowercased() == "toggle_collapse" {
            DispatchQueue.main.async { [weak self] in
                self?.miniDisplay.handleToggleCollapse()
            }
            return
        }

        // Toggle Command Bar Command: input or cmdk
        if header.lowercased() == "input" || header.lowercased() == "cmdk" {
            DispatchQueue.main.async { [weak self] in
                self?.miniDisplay.toggleCommandInput()
            }
            return
        }

        // 2. Phase 4: Human Takeover Mode Command: takeover|<reason> or resume
        if header.lowercased() == "takeover" {
            let reason = (parts.count > 1) ? parts[1] : "Human Takeover Active (Screen Capture Suspended)"
            DispatchQueue.main.async { [weak self] in
                self?.miniDisplay.enterTakeoverMode(reason: reason)
            }
            return
        }

        if header.lowercased() == "resume" {
            DispatchQueue.main.async { [weak self] in
                self?.miniDisplay.exitTakeoverMode()
            }
            return
        }

        // 3. Phase 2: Safety Approval Gate Command: ask_approval|<message>
        if header.lowercased() == "ask_approval" {
            let warningMsg = (parts.count > 1) ? parts[1] : "ยืนยันการทำคำสั่งเสี่ยง?"
            miniDisplay.requestApproval(message: warningMsg)
            return
        }

        // 4. Phase 1: Neural Vision OCR Click Command: ocr_click|<target_text>
        if header.lowercased() == "ocr_click" {
            let targetQuery = (parts.count > 1) ? parts[1] : ""
            executeOCRClick(query: targetQuery)
            return
        }

        // 5. Standard Coordinate Movement Command: <status>|<x>|<y>|<click>|<done>
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
        if miniDisplay.isTakeoverMode {
            return
        }
        miniDisplay.setStatus("Working... Apple Vision กำลังตรวจหา '\(query)' บนหน้าจอ")
        let snapshotPath = "/tmp/cua_ocr_temp.jpg"

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, !self.miniDisplay.isTakeoverMode else { return }
            let captureProc = Process()
            captureProc.launchPath = "/usr/sbin/screencapture"
            captureProc.arguments = ["-x", "-t", "jpg", snapshotPath]
            try? captureProc.run()
            captureProc.waitUntilExit()

            guard let img = NSImage(contentsOfFile: snapshotPath),
                  let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                DispatchQueue.main.async {
                    self.miniDisplay.setStatus("ล้มเหลว: ไม่สามารถจับภาพหน้าจอเพื่อทำ OCR", isDone: true)
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
