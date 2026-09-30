# Codex Harness & Computer Use: Technical Reference

This document provides detailed API specifications, tool definition schemas, sandboxing configuration patterns, and comparison matrices for the OpenAI Codex Harness and Computer Use (CUA).

---

## 1. Industry Benchmark Comparison

| Feature | OpenAI Codex Harness (Agents API) | Anthropic Computer Use API | OpenDevin / AutoGen |
| :--- | :--- | :--- | :--- |
| **Runtime Management** | Fully managed cloud harness | Client-driven agent loop | Self-hosted orchestration |
| **Context Compaction** | Autonomous background compaction | Manual message truncation | Manual prompt summarization |
| **Session Persistence** | Built-in cloud session state | Stateless API | Requires external DB/Redis |
| **GUI Interaction** | Code Execution + Visual Actions | Visual Coordinate Actions | Script execution |
| **Multi-Agent Swarm** | Native Agent Session Hierarchy | Requires custom client code | Local graph orchestration |
| **Ultrafast Tier** | Up to 8x acceleration | Standard generation speeds | Dependent on local/model host |

---

## 2. Tool Definition Schema (`computer_use`)

In the Agents API, the `computer_use` tool is declared as part of the agent's tool bundle:

```json
{
  "type": "computer_use",
  "display_width": 1280,
  "display_height": 800,
  "environment": {
    "type": "cloud_microvm",
    "os": "ubuntu-24.04",
    "browser": "chromium",
    "preinstalled_tools": ["playwright", "curl", "git", "python3"]
  }
}
```

---

## 3. Sandboxing Configurations

### A. Cloud Sandboxes (OpenAI Managed / E2B)
- Provides an isolated ephemeral container for executing bash and browser commands.
- Network policy: Restricted egress with domain allowlisting.
- Automatic teardown after session expiry.

### B. Local Guarded Sandboxes (Workstation Runner)
- Executes inside a local Docker container or via an unprivileged user process.
- PyAutoGUI / Playwright controlled via unix socket.
- Screenshots are saved to temporary directories and never uploaded unless required for task verification.

---

## 4. Environment Variables

| Variable | Description | Required |
| :--- | :--- | :--- |
| `OPENAI_API_KEY` | OpenAI API authentication key (`sk-...`) | Yes (for cloud mode) |
| `OPENAI_ORG_ID` | Optional organization ID for enterprise billing | No |
| `CODEX_SANDBOX_TYPE` | Sandbox provider: `cloud`, `e2b`, or `local` | No (default: `cloud`) |
| `CODEX_DISPLAY_RES` | Screen resolution for Computer Use (e.g. `1280x800`) | No (default: `1280x800`) |

<!-- v1.1.0 synchronized: 2026-09-30 -->
