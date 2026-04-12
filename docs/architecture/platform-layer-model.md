# Platform Layer Model

This document maps the basidiocarp ecosystem to a standard six-layer orchestration platform architecture. The harness model (in [harness-overview.md](./harness-overview.md)) describes how repos compose into a working loop; this model shows where the ecosystem sits relative to the broader industry framing. Both are accurate — they serve different audiences and different questions.

## The Six Layers

### 1. Execution / Integration Layer

Connectors, MCP tool surfaces, sandbox and approval flows, shell and file access.

| Tool | Contribution | Coverage |
|------|-------------|----------|
| `volva` | Execution host, backend dispatch, host-context assembly | Strong |
| `mycelium` | CLI proxy between agent and shell, token-optimized execution | Strong |
| `rhizome` | 37 MCP tools: symbol navigation, diagnostics, structured edits | Strong |
| `hyphae` | MCP tool surface for memory and document retrieval | Strong |
| `canopy` | 30 MCP tools: task state, handoffs, coordination | Strong |

**Coverage: strong.** The MCP tool surface is well-developed. Shell execution (mycelium) and code-aware tool use (rhizome) are genuine strengths. Formal sandbox isolation and host-level approval policies are delegated to the host (Claude Code, Codex CLI) rather than enforced by the harness.

---

### 2. Coordination / Orchestration Kernel

Task model, ownership and claiming, scheduling, dependency resolution, routing, retry, timeout, and escalation.

| Tool | Contribution | Coverage |
|------|-------------|----------|
| `canopy` | Task ledger, ownership, handoffs, evidence refs, council threads, file-scope conflict detection | Partial |

**Coverage: partial.** Canopy is a coordination ledger, not a full orchestration engine. Ownership and handoffs work. Scheduling, dependency resolution, routing between agents, retry, and timeout handling are gaps. A future tool (hymenium) is documented as a deferred option when these gaps become blocking — see [hymenium-design-note.md](./hymenium-design-note.md).

---

### 3. Knowledge Layer

Working state, persistent memory, retrieval and RAG, context assembly, provenance.

| Tool | Contribution | Coverage |
|------|-------------|----------|
| `hyphae` | Episodic memory, semantic memoirs, hybrid search, RAG, session lifecycle, feedback signals | Strong |
| `rhizome` | Code intelligence, structure-aware navigation, code graph export to hyphae | Strong |

**Coverage: strong.** Hyphae is the most complete layer in the ecosystem. Episodic and semantic memory, hybrid retrieval, and session lifecycle are all implemented. Rhizome feeds structured code context into the knowledge graph. Provenance for how memories were created is partial — it exists for some signal types but not uniformly across all ingestion paths.

---

### 4. Policy / Control Layer

Guardrails, authentication and authorization, human-in-the-loop checkpoints, auditability, compliance, safety and approval policies.

| Tool | Contribution | Coverage |
|------|-------------|----------|
| `cortina` | Signal capture (observability side only, not enforcement) | Thin |
| Host (Claude Code, Codex CLI) | Permission prompts, HITL — delegated entirely to the host | External |

**Coverage: thin.** This is the weakest layer in the ecosystem. Cortina captures signals but does not enforce policy. There is no dedicated guardrails engine, no AuthN/AuthZ layer, and no compliance rules. Cortina's planned PreToolUse advisories would be the first harness-side policy enforcement point if implemented. Human-in-the-loop exists through the host, not through basidiocarp tooling.

---

### 5. Observability / Operations

Logs, metrics, traces, cost and latency tracking, model and workflow versioning, recovery and self-healing.

| Tool | Contribution | Coverage |
|------|-------------|----------|
| `cortina` | Signal capture pipeline: errors, corrections, builds, tests, session events | Partial |
| `cap` | Operator dashboard — reads and renders ecosystem state | Partial |

**Coverage: partial.** Cortina captures structured lifecycle signals, which is more than most harnesses provide at this layer. Cap gives a human operator view of that state. What's missing: distributed tracing, OpenTelemetry integration, unified cost/latency metrics, and any recovery or self-healing automation. OTel in spore is a planned direction but not yet implemented.

---

### 6. Authoring / Operator Surface

Workflow definitions, agent definitions, testing and replay, dashboards and UI, intervention tools.

| Tool | Contribution | Coverage |
|------|-------------|----------|
| `cap` | Operator dashboard, memory browser, token analytics | Partial |
| `lamella` | Skill and agent packaging, plugin build system, shared content export | Strong |
| `stipe` | Installer, doctor flows, health management | Strong |

**Coverage: partial to strong.** Lamella (packaging) and stipe (install/repair) are solid. Cap has useful read surfaces but lacks replay, evals, and intervention tooling beyond viewing state. Workflow definitions live in lamella as skills and hooks but there is no formal workflow authoring system or replay harness.

---

## Cross-Cutting Infrastructure

These two repos underpin every layer and are not confined to one.

| Repo | Role |
|------|------|
| `spore` | Shared Rust primitives: discovery, transport, path resolution, config. Every harness repo depends on it. |
| `septa` | Cross-tool contracts and payload schemas. Foundational for any communication across layer boundaries. |

Spore is internal plumbing — operators rarely interact with it directly. Septa is the governance point for any shape that crosses a repo boundary; changes to those shapes go through septa before touching producers or consumers.

---

## Two Important Architectural Properties

### Contracts and Schemas (septa)

Multi-tool systems fail at their seams. Septa makes those seams explicit: shared payload shapes, versioned fixtures, and a defined change process before any producer or consumer is updated. The discipline here is more important than the current schema count — it prevents the silent drift that usually defeats multi-repo ecosystems.

### Resumability and Idempotency

This property is genuinely underserved today. There is no crash recovery, no checkpoint/restore, no replay of failed task sequences. If a multi-agent run fails mid-way, the operator restarts manually. Canopy's evidence refs and task ledger provide partial state recovery material, but no tooling assembles that into an actual resume path. This is a known gap with no scheduled solution.

---

## Coverage Summary

| Layer | Coverage | Primary Gaps |
|-------|----------|-------------|
| 1. Execution / Integration | Strong | Sandbox isolation, host-level approval policies |
| 2. Coordination / Orchestration | Partial | Scheduling, dependency resolution, routing, retry, timeout |
| 3. Knowledge | Strong | Uniform provenance across all ingestion paths |
| 4. Policy / Control | Thin | Guardrails engine, AuthN/AuthZ, compliance, harness-side HITL |
| 5. Observability / Operations | Partial | Distributed tracing, OTel, unified metrics, recovery automation |
| 6. Authoring / Operator Surface | Partial | Replay, evals, intervention tooling, workflow authoring |

---

## Relationship to the Harness Model

The harness model (harness-overview.md, harness-composition.md) is the internal framing: which repo owns which part of the loop, how the repos compose, and what each layer is for. It answers the question "how does basidiocarp work?"

This document is the external framing: where basidiocarp sits relative to how the broader industry structures orchestration platforms. It answers the question "what kind of system is this and what does it cover?"

Both framings are correct. Use the harness model when working inside the ecosystem. Use this model when comparing basidiocarp to other platforms or evaluating what to build next.

---

## Related

- [harness-overview.md](./harness-overview.md) — internal eight-layer harness model
- [harness-composition.md](./harness-composition.md) — how repos compose one working harness
- [hymenium-design-note.md](./hymenium-design-note.md) — deferred orchestration kernel design
- [ECOSYSTEM-OVERVIEW.md](../workspace/ECOSYSTEM-OVERVIEW.md) — thin ecosystem map and repo responsibilities
