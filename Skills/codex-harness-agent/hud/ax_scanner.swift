//
// ax_scanner.swift
// Native macOS Accessibility Tree Scanner for Computer Use Agent Grounding
// Traverses frontmost or targeted application UI hierarchy and outputs
// interactive elements with roles, titles, logical coordinates, and sensitivity tags.
//
// Author: Jamemm (@JameMy0001)
//

import Cocoa
import ApplicationServices

struct UIElementInfo: Codable {
    let role: String
    let subrole: String?
    let title: String
    let value: String?
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let centerX: Double
    let centerY: Double
    let normX: Int
    let normY: Int
    let isSensitive: Bool
}

class AccessibilityScanner {
    static let shared = AccessibilityScanner()
    
    private let targetRoles: Set<String> = [
        kAXButtonRole as String,
        kAXTextFieldRole as String,
        kAXCheckBoxRole as String,
        kAXRadioButtonRole as String,
        kAXPopUpButtonRole as String,
        kAXMenuButtonRole as String,
        kAXMenuItemRole as String,
        "AXLink",
        kAXTabGroupRole as String,
        "AXSearchField",
        kAXComboBoxRole as String,
        kAXSliderRole as String
    ]

    func scanApp(targetName: String? = nil, targetPid: pid_t? = nil, maxDepth: Int = 6, maxElements: Int = 100) -> [UIElementInfo] {
        var targetApp: NSRunningApplication? = nil
        
        if let pid = targetPid {
            targetApp = NSRunningApplication(processIdentifier: pid)
        } else if let name = targetName {
            targetApp = NSWorkspace.shared.runningApplications.first {
                $0.localizedName?.lowercased() == name.lowercased()
            }
        }
        
        if targetApp == nil {
            // Find active frontmost regular app, excluding our own CLI or daemon
            targetApp = NSWorkspace.shared.frontmostApplication
            if targetApp == nil || targetApp?.activationPolicy != .regular {
                targetApp = NSWorkspace.shared.runningApplications.first {
                    $0.activationPolicy == .regular && $0.isActive
                } ?? NSWorkspace.shared.runningApplications.first {
                    $0.activationPolicy == .regular
                }
            }
        }
        
        guard let app = targetApp else { return [] }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        
        var results: [UIElementInfo] = []
        var visitedCount = 0
        
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1710, height: 1112)
        let screenW = max(1.0, screen.width)
        let screenH = max(1.0, screen.height)
        
        var windowsRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
           let windows = windowsRef as? [AXUIElement] {
            for window in windows {
                traverse(
                    element: window,
                    depth: 0,
                    maxDepth: maxDepth,
                    screenW: screenW,
                    screenH: screenH,
                    results: &results,
                    visitedCount: &visitedCount,
                    maxElements: maxElements
                )
                if results.count >= maxElements { break }
            }
        }
        
        return results
    }

    private func traverse(
        element: AXUIElement,
        depth: Int,
        maxDepth: Int,
        screenW: CGFloat,
        screenH: CGFloat,
        results: inout [UIElementInfo],
        visitedCount: inout Int,
        maxElements: Int
    ) {
        if depth > maxDepth || results.count >= maxElements { return }
        visitedCount += 1

        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        let role = (roleRef as? String) ?? ""

        var subroleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef)
        let subrole = subroleRef as? String

        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)
        var title = (titleRef as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if title.isEmpty {
            var descRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
            title = (descRef as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }

        var valRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valRef)
        let valString = (valRef as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        let isSecure = (subrole == (kAXSecureTextFieldSubrole as String)) ||
                       role.lowercased().contains("secure") ||
                       title.lowercased().contains("password") ||
                       title.lowercased().contains("secret") ||
                       title.lowercased().contains("pin")

        if targetRoles.contains(role) || (!title.isEmpty && depth > 0) {
            var posRef: CFTypeRef?
            var sizeRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef)
            AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)

            var pt = CGPoint.zero
            var sz = CGSize.zero
            if let p = posRef { AXValueGetValue(p as! AXValue, .cgPoint, &pt) }
            if let s = sizeRef { AXValueGetValue(s as! AXValue, .cgSize, &sz) }

            if sz.width > 4 && sz.height > 4 && pt.x >= 0 && pt.y >= 0 {
                let cx = Double(pt.x + sz.width / 2.0)
                let cy = Double(pt.y + sz.height / 2.0)
                
                let normX = max(0, min(1000, Int(round((cx / Double(screenW)) * 1000.0))))
                let normY = max(0, min(1000, Int(round((cy / Double(screenH)) * 1000.0))))

                let info = UIElementInfo(
                    role: role,
                    subrole: subrole,
                    title: isSecure ? "[HIDDEN_CREDENTIAL_FIELD]" : title,
                    value: isSecure ? nil : (valString != nil && valString!.count < 60 ? valString : nil),
                    x: Double(pt.x),
                    y: Double(pt.y),
                    width: Double(sz.width),
                    height: Double(sz.height),
                    centerX: cx,
                    centerY: cy,
                    normX: normX,
                    normY: normY,
                    isSensitive: isSecure
                )
                results.append(info)
            }
        }

        var childrenRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement] {
            for child in children {
                traverse(
                    element: child,
                    depth: depth + 1,
                    maxDepth: maxDepth,
                    screenW: screenW,
                    screenH: screenH,
                    results: &results,
                    visitedCount: &visitedCount,
                    maxElements: maxElements
                )
                if results.count >= maxElements { break }
            }
        }
    }
}

// Parse CLI Arguments
let args = CommandLine.arguments
var targetAppName: String? = nil
var targetAppPid: pid_t? = nil
var isCompact = false

var idx = 1
while idx < args.count {
    let arg = args[idx]
    if arg == "--compact" {
        isCompact = true
    } else if arg == "--app" && idx + 1 < args.count {
        targetAppName = args[idx + 1]
        idx += 1
    } else if arg == "--pid" && idx + 1 < args.count {
        if let p = pid_t(args[idx + 1]) {
            targetAppPid = p
        }
        idx += 1
    }
    idx += 1
}

let elements = AccessibilityScanner.shared.scanApp(targetName: targetAppName, targetPid: targetAppPid)

if isCompact {
    for el in elements {
        let sensitiveTag = el.isSensitive ? " [SENSITIVE]" : ""
        let valTag = el.value != nil ? " val=\"\(el.value!)\"" : ""
        print("[\(el.role)] \"\(el.title)\"\(valTag) norm=[\(el.normX),\(el.normY)] pt=(\(Int(el.centerX)),\(Int(el.centerY))) size=(\(Int(el.width))x\(Int(el.height)))\(sensitiveTag)")
    }
} else {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    if let data = try? encoder.encode(elements), let str = String(data: data, encoding: .utf8) {
        print(str)
    }
}
