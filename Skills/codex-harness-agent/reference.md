# Codex Harness & Computer Use: Technical Reference

This document provides detailed API specifications, tool definition schemas, sandboxing configuration patterns, and comparison matrices for the OpenAI Codex Harness and Computer Use (CUA).

---

## 1. Industry Benchmark Comparison

| Feature | OpenAI Codex Harness (Agents API) | Anthropic Computer Use API | OpenDevin / AutoGen | Codex Harness Agent (Enterprise HUD) |
| :--- | :--- | :--- | :--- | :--- |
| **Runtime Management** | Fully managed cloud harness | Client-driven agent loop | Self-hosted orchestration | Hybrid Cloud-Brain + Local-Hands |
| **GUI Grounding** | Coordinate actions | Coordinate actions | Script execution | Apple Neural Vision OCR (`VNRecognizeTextRequest`) |
| **Visual Monitoring** | None (Cloud blackbox) | External web stream | Web VNC viewer | Native macOS Mini Display HUD + Ghost Cursor |
| **Safety Approval Gate** | API-level policies | None | None | Interactive In-HUD Modal (`[ Approve ]` / `[ Deny ]`) |
| **Command Bar** | API endpoint | API endpoint | Web input box | In-HUD Expandable `⌘K` + Global Hotkey `⌥Space` |
| **History Inspection** | Turn JSON logs | Turn JSON logs | Log stream | 6-Frame Rolling Filmstrip Carousel |
| **Context Compaction** | Autonomous background compaction | Manual message truncation | Manual prompt summarization | Autonomous cloud session state |

---

## 2. Tool Definition Schema (`computer_use`)

In the Agents API and Hybrid Runner, the `computer_use` tool is declared as part of the agent's tool bundle:

```json
{
  "type": "function",
  "function": {
    "name": "computer_use",
    "description": "Control macOS GUI interface via mouse, keyboard, or Apple Vision OCR",
    "parameters": {
      "type": "object",
      "properties": {
        "action": {
          "type": "string",
          "enum": ["click", "ocr_click", "move", "type", "press_key", "open_app", "screenshot"]
        },
        "coordinate": {
          "type": "array",
          "items": { "type": "number" },
          "description": "[x, y] screen coordinates"
        },
        "text": {
          "type": "string",
          "description": "Text to type or OCR query text to find and click"
        },
        "key": {
          "type": "string",
          "description": "Key to press"
        }
      },
      "required": ["action"]
    }
  }
}
```

---

## 3. Sandboxing & Execution Environments

### A. Local macOS HUD Environment (Default for `--gui`, `--mode hybrid`)
- Native Swift 6 binary (`computer-use-hud`) running at `.floating + 2` level.
- Communicates with Python orchestrator via Unix Domain FIFO pipe (`/tmp/cua_hud.pipe`).
- Approvals handled via separate secure pipe (`/tmp/cua_approval.pipe`).
- OCR runs locally on Apple Silicon Neural Engine in < 20ms.

### B. Cloud Sandboxes (OpenAI Managed / E2B)
- Provides an isolated ephemeral container for executing bash and browser commands.
- Network policy: Restricted egress with domain allowlisting.
- Automatic teardown after session expiry.

---

## 4. Environment Variables & CLI Options

| Flag / Variable | Description | Default |
| :--- | :--- | :--- |
| `OPENAI_API_KEY` | OpenAI API authentication key (`sk-...`) | Required for cloud/hybrid |
| `--mode hybrid` / `--hybrid` | Hybrid Cloud-Brain reasoning + Local-Hands GUI execution | Auto-detect |
| `--gui` | Shortcut for local visual Computer Use with Mini Display HUD | Off |
| `--ocr "<query>"` | Directly trigger Apple Silicon Neural Vision text detection | Off |
| `--pip` | Enable picture-in-picture mode | Off |
| `--sandbox <mode>` | Sandbox level for native codex (`workspace-write`, `read-only`) | `workspace-write` |

<!-- v1.2.0 synchronized: 2026-10-01 -->
