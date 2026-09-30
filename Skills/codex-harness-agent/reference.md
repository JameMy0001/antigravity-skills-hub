# Codex Harness & Computer Use: Technical Reference

This document provides detailed API specifications, tool definition schemas, sandboxing configuration patterns, and comparison matrices for the OpenAI Codex Harness and Computer Use (CUA).

---

## 1. Industry Benchmark Comparison

| Feature | OpenAI Codex Harness (Agents API / Operator) | Anthropic Computer Use API | OpenDevin / AutoGen | Codex Harness Agent (Target Parity) |
| :--- | :--- | :--- | :--- | :--- |
| **Runtime Management** | Autonomous closed-loop VLM ReAct engine | Client-driven agent loop | Script execution | Autonomous closed-loop VLM ReAct engine |
| **GUI Grounding** | Pixel coordinates from VLM | Viewport pixel coordinates | Script selectors | Triple Grounding: AXTree + OCR + VLM Coordinates |
| **Coordinate Normalization** | Model normalized grid | Screen physical pixels | CSS pixels | Universal Coordinate Normalization [0..1000] |
| **Visual Monitoring** | Remote video stream | Web canvas / VNC | Web VNC viewer | Native macOS Mini Display HUD + Ghost Cursor |
| **Human Supervision** | Watch Mode + Takeover Mode | Basic Confirmation | None | Approval Gate Modal + Human Takeover Mode |
| **Sensitive Data Privacy** | Hardware-level input masking | None (Raw screenshots) | None | Automated Credential Field & Screenshot Shield |
| **Context Window Control** | Autonomous background compaction | Manual message truncation | Manual prompt summarization | Sliding-Window Multi-Frame Compaction (< 40k tokens) |
| **Action Primitives** | 8 Primitives (Drag, Click, Type) | 7 Primitives | 4 Primitives | Full 9-Primitive Humanized Space |

---

## 2. Structured 9-Primitive Tool Definition Schema (`computer_use`)

In the Agents API and Autonomous VLM Loop (`codex_vision_loop.py`), the `computer_use` tool is declared as follows:

```json
{
  "type": "function",
  "function": {
    "name": "computer_use",
    "description": "Execute atomic GUI action on macOS desktop or application.",
    "parameters": {
      "type": "object",
      "properties": {
        "action": {
          "type": "string",
          "enum": [
            "click",
            "double_click",
            "right_click",
            "move",
            "drag",
            "type",
            "press_key",
            "scroll",
            "wait",
            "takeover",
            "done"
          ],
          "description": "The atomic GUI action primitive to execute."
        },
        "coordinate": {
          "type": "array",
          "items": { "type": "number" },
          "description": "Target [x, y] in normalized space [0..1000, 0..1000]."
        },
        "end_coordinate": {
          "type": "array",
          "items": { "type": "number" },
          "description": "End [x, y] for drag action in normalized space."
        },
        "text": {
          "type": "string",
          "description": "Text to type into focused field."
        },
        "key": {
          "type": "string",
          "description": "Key or shortcut to press, e.g. 'return', 'tab', 'escape', 'space', 'cmd+c', 'cmd+v'."
        },
        "scroll_direction": {
          "type": "string",
          "enum": ["up", "down"],
          "description": "Direction to scroll."
        },
        "scroll_amount": {
          "type": "integer",
          "description": "Number of scroll ticks (default 5)."
        },
        "wait_seconds": {
          "type": "number",
          "description": "Seconds to wait."
        },
        "thought": {
          "type": "string",
          "description": "Explicit chain-of-thought rationale: state verification, visual landmarks identified, and expected action outcome."
        }
      },
      "required": ["action", "thought"]
    }
  }
}
```

---

## 3. Universal Coordinate Normalization Mathematics

To prevent Retina display coordinate drift and multi-monitor clipping, coordinates are normalized to `[0..1000, 0..1000]`:

$$\text{point}_x = \text{origin}_x + \left(\frac{\text{norm}_x}{1000.0}\right) \times W_{\text{logical}}$$

$$\text{point}_y = \text{origin}_y + \left(\frac{\text{norm}_y}{1000.0}\right) \times H_{\text{logical}}$$

$$\text{pixel}_x = \text{point}_x \times \text{scale\_factor}$$

$$\text{pixel}_y = \text{point}_y \times \text{scale\_factor}$$

On modern MacBook displays with Retina 2.0x scaling:
- $W_{\text{logical}} = 1710.0\text{ pt}$, $H_{\text{logical}} = 1112.0\text{ pt}$
- $W_{\text{pixel}} = 3420\text{ px}$, $H_{\text{pixel}} = 2224\text{ px}$
- $\text{scale\_factor} = 2.0$

---

## 4. IPC Pipe Architecture & Communications

The agent harness and Swift Mini Display HUD exchange asynchronous events via Unix Named FIFOs:

| Pipe Path | Direction | Command / Payload Format | Description |
| :--- | :--- | :--- | :--- |
| `/tmp/cua_hud.pipe` | Python -> HUD | `<status>\|<x>\|<y>\|<click>\|<done>` | Live cursor glide, ripple click, and status updates |
| `/tmp/cua_hud.pipe` | Python -> HUD | `ocr_click\|<query>` | Trigger Apple Vision Neural OCR search & click |
| `/tmp/cua_hud.pipe` | Python -> HUD | `takeover\|<reason>` | Pause AI and enter Human Takeover Mode |
| `/tmp/cua_hud.pipe` | Python -> HUD | `resume` | Exit Takeover Mode |
| `/tmp/cua_hud.pipe` | Python -> HUD | `ask_approval\|<message>` | Open modal Approval Gate for dangerous actions |
| `/tmp/cua_approval.pipe` | HUD -> Python | `approve` or `deny` | Response from user clicking modal buttons |
| `/tmp/cua_takeover.pipe` | HUD -> Python | `takeover_active` or `resumed` | Signal when user enters or exits Takeover Mode |

---

## 5. Sliding-Window Visual Context Compaction

To ensure long-running desktop workflows never exhaust VLM token limits or trigger HTTP 429 quota exhaustion:
1. **Frame Retention Window**:
   - Turn 0 (Initial Baseline State): Kept with active base64 image data.
   - Turn $N-1$ (Prior Step): Kept with active base64 image data.
   - Turn $N$ (Active Step): Kept with active base64 image data.
2. **Older Turn Compaction ($1 \dots N-2$)**:
   - The heavy base64 image payload is evicted from context.
   - Replaced by structured Markdown execution summary:
     `[Visual frame for Step K compacted. Action outcome verified in trace.]`
3. **Session Ledger**:
   - Every completed or aborted session is automatically written to `~/.codex/sessions/<session_id>.md`.

---

## 6. CLI Environment Variables & Options

| Flag / Variable | Description | Default |
| :--- | :--- | :--- |
| `ANTHROPIC_AUTH_TOKEN` / `OPENROUTER_API_KEY` | OpenRouter API authentication key | Auto-detected from environment |
| `OPENAI_API_KEY` | OpenAI API key for native Cloud Agents API | Required for cloud mode |
| `--gui` | Execute autonomous Computer Use with persistent HUD | Off |
| `--model <id>` | Target VLM model (`google/gemini-2.5-flash`, `openai/gpt-4o-mini`) | `google/gemini-2.5-flash` |
| `--steps <int>` | Maximum ReAct loop steps | `15` |
| `--ocr "<query>"` | Directly trigger Apple Silicon Neural Vision text detection | Off |
| `--mode hybrid` | Cloud Brain planning + Local Hands execution | Auto-detect |
| `--mode dry-run` | Zero-dependency simulation test | Off |

<!-- v2.0.0 synchronized: 2026-10-01 -->
