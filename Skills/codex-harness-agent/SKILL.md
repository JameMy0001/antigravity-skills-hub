---
name: codex-harness-agent
description: Comprehensive production guide and runner for OpenAI's Agents API, the managed Codex Cloud Harness, and Computer Use (CUA). Covers session state persistence, context compaction, execution environments (OpenAI cloud sandboxes, E2B, local PyAutoGUI/Playwright), multi-agent dispatch, and human-in-the-loop safety boundaries. Use when delegating autonomous tasks to OpenAI's managed harness, controlling GUI interfaces via Computer Use, or orchestrating hybrid multi-agent workflows.
aliases:
  - codex-harness-agent
  - openai-agents-api
  - codex-agent
  - computer-use-agent
  - cua-harness
category: "07 - Codebase Exploration & Tooling"
tags:
  - agent-skill
  - openai-agents
  - codex-harness
  - computer-use
  - stage-7
  - autonomous-agents
---

# Codex Harness Agent: OpenAI Agents API, Managed Cloud Runtime & Computer Use

This skill provides an enterprise engineering blueprint and execution runner for OpenAI's **Agents API**, leveraging the **Codex Harness**—the battle-tested agentic execution runtime that powers OpenAI Codex. It covers session persistence, context compaction, native **Computer Use (CUA)** for graphical user interface interaction, sandboxing, and hybrid multi-agent dispatch.

---

## Quick Invocation & Shortcuts

You can invoke this skill through multiple convenient methods:

### 1. In AI Chat (Antigravity & Cursor)
- **`/codex <task>`**: Dispatches task to the Codex Harness (runs in cloud or native Codex CLI).
- **`/cua <task>`** or **`/cua <url>`**: Triggers visual Computer Use (inspects UI, clicks buttons, captures screenshots).
- **Natural Language Triggers**:
  - "สั่ง codex ทำ..."
  - "รันบน codex harness..."
  - "ใช้ computer use ตรวจสอบหน้าเว็บ..."
  - "รันงานระยะยาวบนคลาวด์..."

### 2. From Terminal (Global CLI Shortcut)
```bash
# Run a task via native Codex CLI or cloud harness
codex-agent "Refactor auth middleware and verify tests"

# Run visual Computer Use on a target URL / web application
codex-agent --gui "http://localhost:3000"

# Run in an isolated managed git worktree
codex-agent --worktree "Implement new billing model"

# Cloud mode via OpenAI Agents API
export OPENAI_API_KEY="sk-..."
codex-agent --cloud "Run full overnight stress testing"
```

---

## 1. Architecture Overview: Managed Codex Harness vs. Client SDK

```
┌────────────────────────────────────────────────────────────────────────┐
│                   AGENT EXECUTION RUNTIME COMPARISON                   │
├────────────────────────────────┬───────────────────────────────────────┤
│ Client-Side Loop (Agents SDK)  │ Managed Cloud Loop (Codex Harness)    │
├────────────────────────────────┼───────────────────────────────────────┤
│ • Local Python/Node process    │ • OpenAI-managed serverless container │
│ • Local machine memory/state   │ • Durable session state persistence   │
│ • Manual context truncation    │ • Autonomous context compaction       │
│ • Client handles tool recovery │ • Built-in self-healing and recovery  │
│ • Stops if laptop closes       │ • Continues executing asynchronously  │
│ • Local OS / Docker runtime    │ • Native Cloud Sandbox & Computer Use │
└────────────────────────────────┴───────────────────────────────────────┘
```

### The Three Operational Layers:
1. **The Codex Harness**: The internal execution engine developed by OpenAI for Codex. It manages the agentic loop (Reasoning -> Tool Call -> Observation -> Reflection), state checkpointing, error recovery, and automatic context compaction so sessions never hit context window hard limits.
2. **The Agents API (Cloud Control Plane)**: A managed API service exposing the Codex Harness as a first-class developer primitive. Developers create an agent, define tools (including Computer Use and Bash), start a session, and dispatch long-lived tasks.
3. **Execution Sandboxes (The "Hands")**: Where tool actions actually run:
   - **OpenAI-Hosted Sandboxes**: Ephemeral or persistent Linux micro-VMs managed by OpenAI.
   - **Partner Cloud Sandboxes**: Isolated environments via E2B, Modal, or Cloudflare Workers.
   - **Local Desktop / Browser (Guarded)**: Local Playwright browser sessions or PyAutoGUI desktop control running on the developer's workstation.

---

## 2. Computer Use (CUA) Architecture

The Agents API supports **Computer Use**, enabling agents to interact with software through visual interfaces rather than purely via structured JSON APIs.

### A. Execution Modes
1. **Code Execution Mode (Recommended for Web & Scriptable Interfaces)**:
   - The model generates Python (`Playwright`) or Node.js scripts.
   - The runner executes the script against the target browser session.
   - Faster, more resilient to layout changes, and deterministic.
2. **Direct Visual Action Mode (For Desktop & Legacy GUI Apps)**:
   - The model receives high-resolution screenshots.
   - The model issues atomic GUI actions:
     ```json
     { "action": "click", "coordinate": [450, 220] }
     { "action": "type", "text": "npm test" }
     { "action": "key_press", "key": "Enter" }
     { "action": "screenshot" }
     ```
   - The runner performs the input action and sends back an updated screenshot.

---

## 3. Session Lifecycle & Python Implementation Pattern

```python
import os
from openai import OpenAI

# Initialize client with OpenAI API key
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

# 1. Define Agent with Codex Harness & Computer Use
agent = client.agents.create(
    name="qa-verification-agent",
    model="gpt-4o",
    instructions=(
        "You are an autonomous verification agent running inside the Codex harness. "
        "Use the computer_use tool to open the web application, verify UI workflows, "
        "and inspect console logs for errors. Report back with exact findings."
    ),
    tools=[
        {"type": "computer_use", "display_width": 1280, "display_height": 800},
        {"type": "bash"}
    ],
    sandbox={"type": "cloud", "persistence": "session"}
)

# 2. Create a Persistent Execution Session
session = client.agents.sessions.create(agent_id=agent.id)

# 3. Dispatch an Autonomous Task
task = client.agents.sessions.tasks.create(
    session_id=session.id,
    prompt="Navigate to http://localhost:3000, verify the checkout flow, and screenshot any validation errors."
)

# 4. Stream or Poll Task Execution
# The Codex harness automatically manages context compaction and recovery
print(f"Task dispatched with ID: {task.id}. Status: {task.status}")
```

---

## 4. Integration with `subagent-driven-development`

When breaking down large tasks in implementation plans, tasks that require visual inspection, end-to-end user flows, or long-running independent builds can be offloaded to the Codex Harness:

```
┌────────────────────────────────────────────────────────────────────────┐
│               HYBRID TASK DECOMPOSITION & DISPATCH                     │
├────────────────────────────────────────────────────────────────────────┤
│ Primary Orchestrator (Antigravity / Local Agent)                      │
│   │                                                                    │
│   ├── Task 1: Refactor Database Models ──► Local Direct Execution      │
│   ├── Task 2: Implement API Endpoint  ──► Local Direct Execution      │
│   └── Task 3: Visual E2E Checkout Flow ──► Offload to Codex Harness    │
│                                            (Computer Use Sandbox)      │
└────────────────────────────────────────────────────────────────────────┘
```

### Dispatch Protocol:
1. Orchestrator inspects the task. If the task requires interactive GUI manipulation, long-running batch execution (>15 minutes), or external visual verification, mark task as `Target: codex-harness`.
2. Invoke `scripts/codex_agent_runner.py` with `--task "<description>"` and `--env cloud`.
3. Capture final verification artifacts (screenshots, logs, and state summary).
4. Resume local orchestration loop with the returned evidence.

---

## 5. Security Boundaries & Guardrails

> [!CAUTION] Mandatory Safety Boundaries
> Agents executing OS-level actions or browsing the open web must be strictly constrained:

1. **Non-Privileged Execution**: Never run computer-using agents as root or with administrative OS privileges.
2. **Domain Whitelisting**: When browsing, enforce network proxy rules allowing only required application domains (e.g. `localhost`, `staging.internal`, `github.com`).
3. **Sensitive Data Masking**: Screen captures must mask password fields and auth bearer tokens before submitting images to external APIs.
4. **Approval Checkpoints**: Destructive actions (database drops, git force-pushes, financial payments, account deletions) require explicit human confirmation.

---

## 6. Verification Checklist Before Marking Work Complete

- [ ] Has the target environment (Cloud Sandbox vs Local Browser) been explicitly declared?
- [ ] Is `OPENAI_API_KEY` present and verified in the environment?
- [ ] Are safety boundaries (domain whitelisting, non-root execution) enforced?
- [ ] Did the agent capture evidence (screenshots or logs) proving task completion?
- [ ] Has session state been closed or persisted cleanly?

---

## 🔗 Connected Skills

- [[Skills/subagent-driven-development/SKILL|subagent-driven-development]] — Task decomposition and subagent coordination
- [[Skills/sdk/SKILL|sdk]] — Cursor Agent SDK and programmatic agent runtime patterns
- [[Skills/playwright-cli/SKILL|playwright-cli]] — Browser automation and UI test execution
- [[Skills/determine_threat_model/SKILL|determine_threat_model]] — Threat modeling and attack surface isolation
- [[Skills/review-security/SKILL|review-security]] — Security review and safety boundary enforcement
- [[Skills/verification-before-completion/SKILL|verification-before-completion]] — Evidence-based verification without assumptions

<!-- v1.1.0 synchronized: 2026-09-30 -->
