# Codex Harness Computer Use Evolution: 5-Pillar Architecture Plan

> **For agentic workers:** Execute tasks directly in the current session (recommended). Only use subagents if explicitly instructed by the user. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform `codex-harness-agent` into an enterprise-grade Computer Use system featuring Apple Neural Vision OCR grounding, in-HUD quick command box with global hotkey, safety guardrail approval gates, action filmstrip visual history, and hybrid cloud-brain + local-hands execution.

**Architecture:** Native Swift 6 HUD compiled to lightweight macOS binary (< 250 KB) communicating via Unix Domain FIFO pipe (`/tmp/cua_hud.pipe`) with Python orchestrator, integrating Apple Vision framework (`VNRecognizeTextRequest`) on Neural Engine and streaming OpenAI Agents API tool calls down to macOS WindowServer.

**Tech Stack:** Swift 6, AppKit (Cocoa), Vision.framework, CoreGraphics, QuartzCore, Python 3.10+, OpenAI Agents API, Playwright, macOS TCC Accessibility.

**Spec Reference:** [`Skills/codex-harness-agent/SKILL.md`](file:///Users/mac/Documents/Obsidian%20Vault/Skills/codex-harness-agent/SKILL.md) and [`reference.md`](file:///Users/mac/Documents/Obsidian%20Vault/Skills/codex-harness-agent/reference.md)

## Global Constraints
- Zero decorative emojis across all source code, commit messages, and headings (Zero Decorative Emoji Protocol).
- Single-Agent Mode execution; all tasks executed sequentially within main thread.
- Memory consumption of HUD must remain < 40 MB RSS during continuous idle monitoring.
- Neural Vision OCR query response time must remain < 50ms on Apple Silicon.

---

## Architecture Blueprint: The 5-Pillar Matrix

```
┌────────────────────────────────────────────────────────────────────────┐
│               CODEX HARNESS COMPUTER USE ENTERPRISE HUD                │
├────────────────────────────────────────────────────────────────────────┤
│ [Red/Yellow/Green]    Computer Use Mini Display       [Safety: Green]  │
├────────────────────────────────────────────────────────────────────────┤
│ ┌────────────────────────────────────────────────────────────────────┐ │
│ │                                                                    │ │
│ │                     Live Desktop Mini Preview                      │ │
│ │             (Apple Vision OCR Bounding Box Tracking)               │ │
│ │                                                                    │ │
│ └────────────────────────────────────────────────────────────────────┘ │
│ ┌─ Filmstrip History (Last 5 Action Snapshots) ──────────────────────┐ │
│ │ [ Frame 1 ] [ Frame 2 ] [ Frame 3 ] [ Frame 4 ] [ Active Frame ]   │ │
│ └────────────────────────────────────────────────────────────────────┘ │
│ Status Pill: [Spinner] Working... Clicking 'Table Editor' [Approve/Deny]│
│ Quick Command Bar: [ ⌘K Type command or press ⌥Space...              ] │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Apple Neural Vision OCR Grounding (`VNRecognizeTextRequest`)

### Task 1.1: Implement Vision OCR Detector in Swift HUD
**Files:**
- Modify: `Skills/codex-harness-agent/hud/ComputerUseHUD.swift`
- Test: `tests/test_vision_ocr.sh`

- [ ] **Step 1: Import Vision Framework & Implement `ScreenOCRDetector`**
  Add `import Vision` to `ComputerUseHUD.swift`. Implement class `ScreenOCRDetector`:
  ```swift
  import Vision

  class ScreenOCRDetector {
      static let shared = ScreenOCRDetector()
      
      func findTextLocation(query: String, in image: CGImage, completion: @escaping (CGRect?) -> Void) {
          let request = VNRecognizeTextRequest { request, error in
              guard let observations = request.results as? [VNRecognizedTextObservation] else {
                  completion(nil)
                  return
              }
              for observation in observations {
                  guard let candidate = observation.topCandidates(1).first else { continue }
                  if candidate.string.localizedCaseInsensitiveContains(query) {
                      completion(observation.boundingBox)
                      return
                  }
              }
              completion(nil)
          }
          request.recognitionLevel = .accurate
          request.recognitionLanguages = ["en-US", "th-TH"]
          request.usesLanguageCorrection = true
          
          let handler = VNImageRequestHandler(cgImage: image, options: [:])
          try? handler.perform([request])
      }
  }
  ```

- [ ] **Step 2: Add Pipe Command for OCR Click (`ocr_click|<text>`)**
  Update `handleCommandString` in `HUDAppController` to parse `ocr_click|<target_text>`:
  - Captures current display image via `screencapture`.
  - Runs `ScreenOCRDetector.shared.findTextLocation`.
  - Converts normalized Vision coordinates (`0.0 - 1.0` bottom-left origin) to macOS display coordinates (`top-left origin`).
  - Animates Ghost Cursor directly to the detected bounding box center and executes click ripple.

- [ ] **Step 3: Verification Test**
  Compile and verify Vision OCR detection with test script:
  ```bash
  swiftc -O "Skills/codex-harness-agent/hud/ComputerUseHUD.swift" \
      -o "Skills/codex-harness-agent/hud/computer-use-hud" \
      -framework Cocoa -framework CoreGraphics -framework QuartzCore -framework Vision
  echo "ocr_click|Safari" > /tmp/cua_hud.pipe
  ```
  Confirm Ghost Cursor accurately glides to the text "Safari" on screen.

- [ ] **Step 4: Commit**
  ```bash
  git commit -m "feat(cua-hud): implement Apple Vision Neural Engine OCR text grounding"
  ```

---

## Phase 2: Safety Guardrails & Human-in-the-Loop Approval Gate

### Task 2.1: Add Interactive Approval Modal in Mini Display
**Files:**
- Modify: `Skills/codex-harness-agent/hud/ComputerUseHUD.swift`
- Modify: `Skills/codex-harness-agent/scripts/codex_agent_runner.py`

- [ ] **Step 1: Add Risk Classification Table in Python Runner**
  In `codex_agent_runner.py`, define pattern matcher:
  ```python
  DANGEROUS_ACTIONS = [
      "rm ", "drop table", "truncate", "delete", "format",
      "shutdown", "reboot", "transfer", "pay", "password"
  ]

  def classify_action_risk(action_text):
      text_lower = action_text.lower()
      if any(p in text_lower for p in DANGEROUS_ACTIONS):
          return "critical"
      if any(w in text_lower for w in ["commit", "push", "upload", "write"]):
          return "warning"
      return "info"
  ```

- [ ] **Step 2: Add Visual Warning & Approval Buttons to HUD**
  In `MiniDisplayWindow`:
  - When `risk == "critical"`:
    - Set HUD border color to Orange/Red (`#EF4444`).
    - Status pill displays: `🔴 Warning: Dangerous Action! [ Approve ] [ Deny ]`.
    - Ghost Cursor movement is paused until user clicks `Approve`.
    - Writes approval result (`approved` / `denied`) to `/tmp/cua_approval.pipe`.

- [ ] **Step 3: Verification Test**
  Trigger test dangerous action:
  ```bash
  codex-agent --gui "drop table patient_medications in supabase"
  ```
  Confirm HUD pauses with red border and waits for human click before proceeding.

- [ ] **Step 4: Commit**
  ```bash
  git commit -m "feat(cua-safety): add human-in-the-loop approval gate for critical actions"
  ```

---

## Phase 3: In-HUD Quick Command Box & Global Hotkey (`⌥Space`)

### Task 3.1: Add Expandable Command Box and Hotkey Listener
**Files:**
- Modify: `Skills/codex-harness-agent/hud/ComputerUseHUD.swift`

- [ ] **Step 1: Create Expandable `NSTextField` in Mini Display**
  In `MiniDisplayWindow`:
  - Add search bar container below title or pill:
    ```swift
    private var commandInputBox: NSTextField!
    
    private func setupCommandInput() {
        commandInputBox = NSTextField(frame: NSRect(x: 14, y: 10, width: width - 28, height: 28))
        commandInputBox.placeholderString = "⌘K สั่งงาน Agent หรือพิมพ์คำสั่ง..."
        commandInputBox.target = self
        commandInputBox.action = #selector(handleCommandSubmit)
        commandInputBox.isHidden = true
    }
    ```
  - Toggle visibility with `⌘ + K` or by clicking a search icon button in the header.

- [ ] **Step 2: Register Global Hotkey (`⌥ + Space`)**
  Use Carbon `RegisterEventHotKey` or `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)`:
  - When `⌥ + Space` is pressed anywhere in macOS:
    - Mini Display orders to front (`makeKeyAndOrderFront`).
    - Focuses `commandInputBox` immediately.

- [ ] **Step 3: Wire Submission to `codex-agent`**
  When Enter is pressed:
  - Reads input text.
  - Spawns `codex-agent --gui "<entered_task>"` in background.
  - Clears text and updates status pill to `Working...`.

- [ ] **Step 4: Commit**
  ```bash
  git commit -m "feat(cua-hud): add in-HUD quick command box and global hotkey invocation"
  ```

---

## Phase 4: Action Filmstrip History Carousel

### Task 4.1: Multi-Frame Action History Filmstrip
**Files:**
- Modify: `Skills/codex-harness-agent/hud/ComputerUseHUD.swift`

- [ ] **Step 1: Implement Action Frame History Ring Buffer**
  In `MiniDisplayWindow`, maintain a queue of up to 6 frames:
  ```swift
  struct ActionFrame {
      let image: NSImage
      let label: String
      let timestamp: Date
  }
  private var historyFrames: [ActionFrame] = []
  ```

- [ ] **Step 2: Add Filmstrip Tray UI**
  Add horizontal scrollview / stackview at the bottom of the preview area:
  - Width: 48px per thumbnail, Height: 32px, Corner Radius: 4px.
  - Hovering over a frame swaps the main preview to that historical frame and displays its action label.

- [ ] **Step 3: Verification Test**
  Run a 4-step task:
  ```bash
  codex-agent --gui "เปิด Safari -> เปิด YouTube -> ค้นหาเพลง -> คลิกเล่น"
  ```
  Confirm all 4 historical snapshots appear in the filmstrip tray and can be inspected by hover.

- [ ] **Step 4: Commit**
  ```bash
  git commit -m "feat(cua-hud): implement action filmstrip visual history carousel"
  ```

---

## Phase 5: Hybrid Cloud-Brain + Local-Hands Architecture

### Task 5.1: Stream Cloud Harness Tool Calls to Local HUD
**Files:**
- Modify: `Skills/codex-harness-agent/scripts/codex_agent_runner.py`
- Modify: `Skills/codex-harness-agent/SKILL.md`

- [ ] **Step 1: Implement Streaming Agent Dispatch in Python**
  In `codex_agent_runner.py`:
  - When `--mode hybrid` is specified:
    - Boots OpenAI Agents API session with `gpt-4o` / `o3-mini`.
    - Polls or streams task turn tool calls (`type == "computer_use"`).
    - For each tool call:
      - Intercepts action: `click`, `type`, `move`, `key_press`.
      - Maps coordinates to local macOS display.
      - Dispatches to `send_hud()` and triggers local Ghost Cursor and native action.
      - Takes fresh screenshot and returns it to the Cloud Session as tool observation.

- [ ] **Step 2: End-to-End Verification Test**
  ```bash
  codex-agent --mode hybrid "ตรวจสอบสคีมาของโปรเจกต์ YaCheck ใน Supabase"
  ```
  Verify that reasoning occurs in OpenAI Cloud Harness while physical actions visibly execute on local screen via HUD and Ghost Cursor.

- [ ] **Step 3: Update Skills Vault Documentation**
  Update `Skills/codex-harness-agent/SKILL.md` and `reference.md` documenting the new flags:
  `--mode hybrid`, `--vision-ocr`, `--safety-gate`, `--filmstrip`.

- [ ] **Step 4: Parity & Vault Verification**
  Run `python3 verify_skills_vault.py` to confirm 100% parity with iCloud Vault and zero broken links.

- [ ] **Step 5: Final Push & Release**
  ```bash
  git commit -m "feat(codex-harness-agent): complete 5-pillar enterprise computer use evolution"
  git push origin main
  ```

---

## Execution Schedule & Deliverable Milestones

| Milestone | Deliverables | Target Artifact |
| :--- | :--- | :--- |
| **M1: Vision OCR** | Swift Neural Vision integration, text-based button clicking | `ComputerUseHUD.swift` + `computer-use-hud` |
| **M2: Safety Guardrails** | Risk classifier, interactive Approve/Deny modal | `codex_agent_runner.py` + HUD dialogs |
| **M3: Quick Command Box**| `⌘K` command bar, `⌥Space` global system hotkey | In-HUD input textfield |
| **M4: Filmstrip History** | 6-frame historical action carousel, hover inspection | Filmstrip tray component |
| **M5: Hybrid Engine**   | Cloud Agents API reasoning + local GUI hands | `--mode hybrid` pipeline |

---

*Plan author: Jamemm (@JameMy0001)*  
*Vault Version: 1.1.0 (67 Skills across 8 SDLC Stages)*
