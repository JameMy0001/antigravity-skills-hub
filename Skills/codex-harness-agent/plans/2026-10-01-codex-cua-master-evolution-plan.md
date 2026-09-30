# Master Blueprint: OpenAI Codex Computer-Using Agent (CUA) Architecture & Evolution Plan

## 1. Executive Summary & Forensic Teardown of OpenAI CUA / Operator

OpenAI's Computer-Using Agent (CUA)—originally introduced in the Operator preview and foundational to the Codex Harness and OpenAI Agents API—represents a paradigm shift from brittle programmatic web scrapers to an autonomous, multimodal "Perceive–Think–Act–Observe" loop capable of driving any graphical interface like a human operator.

### 1.1 The Fundamental Core Loop: "Perceive–Think–Act–Observe"

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 THE AUTONOMOUS COMPUTER USE RE-ACT CYCLE                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌────────────────┐      Screenshot (JPEG/WebP)     ┌──────────────────┐   │
│   │ 1. PERCEIVE    │ ──────────────────────────────> │ 2. THINK         │   │
│   │ Screen Capture │                                 │ VLM Reasoning &  │   │
│   │ & Resolution   │ <────────────────────────────── │ Grounding (CoT)  │   │
│   │ Normalization  │       Observation Verification  └──────────────────┘   │
│   └────────────────┘                                           │            │
│           ▲                                                    │            │
│           │                                         Structured Action       │
│           │                                         (click, type, scroll)   │
│           │                                                    │            │
│           │                                                    ▼            │
│   ┌────────────────┐      Physical Event Glide       ┌──────────────────┐   │
│   │ 4. OBSERVE     │ <────────────────────────────── │ 3. ACT           │   │
│   │ Visual Delta & │                                 │ macOS Window     │   │
│   │ State Tracking │                                 │ Server Execution │   │
│   └────────────────┘                                 └──────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **Perception (Visual & Semantic Ingestion)**:
   - Captures high-fidelity desktop or browser frames.
   - Converts coordinates into a normalized space (e.g. `[0..1000, 0..1000]`).
   - Compresses images to ~75% WebP/JPEG to optimize token consumption and network round-trip latency.
2. **Reasoning (Chain-of-Thought UI Grounding)**:
   - The model generates explicit internal monologue before choosing an action:
     - Identification of visual landmarks (buttons, forms, modals).
     - Verification of prior action outcome ("Did the popup dismiss?").
     - Selection of target coordinate and action primitive.
3. **Action (Structured Primitive Dispatch)**:
   - Emits strict JSON schemas describing atomic GUI events: `mouse_click`, `move_cursor`, `mouse_down`, `mouse_up`, `type_text`, `key_combination`, `scroll`, `wait`.
   - The local harness executes the action using human-like mouse glide curves (ease-in-out), visual ripple indicators, and natural typing cadences.
4. **Observation & Reflection (Self-Healing Loop)**:
   - Re-captures the updated screen.
   - Compares visual deltas to confirm state transition.
   - If an unexpected error, captcha, or dialog appears, the agent dynamically adjusts its plan without failing the entire run.

---

## 2. Industry Benchmark Comparison Matrix

| Architectural Feature | OpenAI Operator / CUA | Anthropic Computer Use API | Current Codex Harness Agent | Codex Harness Agent v2.0 (Target) |
| :--- | :--- | :--- | :--- | :--- |
| **Agent Reasoning Loop** | Closed-Loop Autonomous VLM | Closed-Loop Autonomous VLM | Hybrid Heuristics + OCR matching | Closed-Loop Autonomous VLM Engine |
| **GUI Grounding Stack** | VLM Pixel Coordinates | VLM Pixel Coordinates | Apple Silicon Neural Vision OCR | Triple Grounding: AXTree + OCR + VLM |
| **Coordinate Normalization** | 1000x1000 Normalized Grid | Logical Viewport Coordinates | Logical Screen Bounds | Universal Normalized Coordinate Engine |
| **Visual Monitoring HUD** | Cloud Remote Stream | External Web Canvas / VNC | Native Swift 6 Glass HUD | Native Swift 6 Glass HUD + Dynamic Island |
| **Human Supervision Modes** | Watch Mode + Takeover Mode | Basic Confirmation | Approval Gate Modal | Watch Mode + Takeover + Stealth Input |
| **Sensitive Data Privacy** | Masked screen & paused capture | None (Raw screenshots) | Plain text in terminal | Hardware-level secure input masking |
| **Context Window Control** | Autonomous Compaction | Manual Message Truncation | Single session memory | Sliding-Window Multi-Frame Compaction |
| **Action Primitives** | 8 Primitives (Drag, Click, Type) | 7 Primitives | 4 Primitives | Full 9-Primitive Humanized Space |

---

## 3. The 5 Core Gaps in Our Current Implementation

### Gap 1: Heuristic Routing vs. Autonomous Closed-Loop ReAct Engine
- **Current State**: `codex_agent_runner.py` uses keyword inspection (`"supabase"`, `"youtube"`, `"safari"`) to select hardcoded coordinate paths or Playwright scripts.
- **Real CUA Standard**: The agent operates as an open-ended autonomous loop where a Vision-Language Model (`gpt-4o`, `o3-mini`, or `gemini-2.0-flash`) inspects the actual live screenshot, outputs structured tool calls, verifies the visual delta, and iterates until completion.

### Gap 2: Coordinate Space Discrepancy & Retina Drift
- **Current State**: macOS Retina displays operate at a 2.0 scale factor (e.g. 1710x1112 points = 3420x2224 physical pixels). Passing unnormalized coordinates causes clicking offset bugs.
- **Real CUA Standard**: Strict bidirectional coordinate mapping between Model Normalized Space `[0..1000, 0..1000]`, Logical macOS Points `[0..W, 0..H]`, and Physical Retina Pixels.

### Gap 3: Missing Takeover Mode for Sensitive Operations
- **Current State**: The Approval Gate handles destructive actions (`rm -rf`, `drop table`), but does not have a dedicated **Takeover Mode** allowing the human to enter passwords, credit cards, or 2FA codes while suspending screen recording.
- **Real CUA Standard**: The AI detects sensitive fields, enters "Takeover Mode", suspends screenshot logging, unlocks the keyboard for the human, and resumes only after the human clicks "Resume".

### Gap 4: Grounding Fragility (Single Layer vs. Triple Hybrid Grounding)
- **Current State**: Relies solely on Apple Vision OCR text search. Icons without text (e.g. hamburger menus, search icons, close buttons) cannot be clicked.
- **Real CUA Standard**: Triple-Layer Hybrid Grounding:
  1. *Layer 1 (Fast Path)*: macOS Accessibility API (`AXUIElement`) for instant semantic button lookup (< 5ms).
  2. *Layer 2 (Text Path)*: Apple Silicon Vision Neural Engine OCR (< 20ms).
  3. *Layer 3 (Visual Path)*: Multimodal VLM bounding box / coordinate grounding for iconographic and non-text elements.

### Gap 5: Token Explosion & Context Window Exhaustion
- **Current State**: In long tasks, sending full high-res screenshots on every step exhausts visual tokens and triggers rate limits.
- **Real CUA Standard**: Sliding-Window Visual Context Compaction: retain only the latest 2 screenshots in context, and summarize previous steps into a structured Markdown execution log.

---

## 4. Phase-by-Phase Master Implementation Plan

### Phase 1: Autonomous Closed-Loop VLM ReAct Engine (`codex_vision_loop.py`)
- [ ] Implement `ComputerUseAgentLoop` class in Python.
- [ ] Implement OpenAI / Gemini API tool call schema for `computer_use`:
  - `action`: `click`, `double_click`, `right_click`, `drag`, `move`, `type`, `press_key`, `scroll`, `wait`, `takeover`.
  - `coordinate`: `[x, y]` (normalized `0..1000`).
  - `text`: string for typing.
  - `thought`: chain-of-thought rationale.
- [ ] Connect loop output directly to native macOS WindowServer events and HUD streaming.

### Phase 2: Triple Grounding Engine (AXTree + Apple OCR + VLM Coordinates)
- [ ] Create Swift helper `macOSAccessibilityScanner` using `ApplicationServices`:
  - Enumerate visible UI elements (`AXButton`, `AXTextField`, `AXMenuItem`).
  - Extract bounds and titles.
- [ ] Integrate with existing `ScreenOCRDetector` (Apple Vision framework).
- [ ] Combine semantic element list into prompt context as structured landmarks.

### Phase 3: Universal Coordinate Normalization Engine
- [ ] Implement `CoordinateTransformer` class:
  - `model_to_screen(x_norm, y_norm) -> (x_pt, y_pt)`
  - `screen_to_retina(x_pt, y_pt) -> (x_px, y_px)`
  - Support multi-monitor coordinate offsets and notch safe areas.

### Phase 4: Human Takeover Mode & Sensitive Field Shield
- [ ] Add `[ Take Over ]` and `[ Pause / Resume ]` controls to `ComputerUseHUD.swift`.
- [ ] Add `takeover_request` IPC pipe command.
- [ ] When in Takeover Mode:
  - Mini Display switches to gold/amber border.
  - Ghost Cursor and auto-screenshots are suspended immediately.
  - User interacts freely.
  - User clicks `[ Resume Agent ]` to re-enable the AI loop.

### Phase 5: Sliding-Window Visual Compaction & Audit Trail
- [ ] Implement image compressor producing optimized WebP/JPEG (< 150 KB per frame).
- [ ] Implement visual compaction queue: keep current frame + previous frame; convert older turns to Markdown audit ledger.
- [ ] Persist execution log in `~/.codex/sessions/<session_id>.md`.

---

## 5. Verification Checklist & Success Criteria

- [ ] Complete autonomous closed-loop navigation without hardcoded application heuristics.
- [ ] Bounding box and coordinate clicks land within 5px accuracy across Retina displays.
- [ ] Takeover Mode suspends screenshots and safely hands control to the user.
- [ ] Task runs of 15+ steps maintain token usage under 40,000 total tokens via sliding-window compaction.
- [ ] Zero decorative emojis maintained across all documentation, commits, and code.
