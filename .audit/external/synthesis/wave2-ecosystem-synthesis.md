# Wave 2 External Audit Synthesis

**Date:** 2026-04-23
**Scope:** Cross-cutting synthesis from Wave 1 re-audit verdicts and 40 Wave 2 ecosystem audits
**Method:** Feature triage (borrow/adapt/skip per feature); bias toward existing repos; new tool only when no existing repo owns the responsibility

---

## Wave 1 Re-Audit Summary

Wave 1 completed verdict assignments for 25 external repos:

- **13 archived:** 1code, autogen, caveman, ccstatusline, ccusage, claude-mem, claude-squad, cmux, context-keeper, everything-claude-code, icm, mem0, multica
- **8 kept as-is:** autoresearch, claurst, council, hermes-agent, mempalace, oh-my-openagent, skill-manager, vibe-kanban
- **4 updated with handoff specs:**
  - `forgecode` → `canopy/permission-memory-policy.md` (runtime approval hardening)
  - `rtk` → `mycelium/declarative-filter-extensions.md` (TOML-based filter long tail)
  - `serena` → `septa/context-envelope-v1.md` (versioned memory+symbols+diagnostics envelope)
  - `Understand-Anything` → `rhizome/incremental-fingerprinting.md` (signature fingerprints + ChangeClass)

These 4 handoffs identified critical gaps in baseline ecosystem contracts that Wave 2 confirms and extends.

---

## Wave 2: Cross-Cutting Themes

### Theme 1: Orchestration and Workflow Control

**Repos:** crewAI, langgraph, OpenHands, cline, continue, harness

**Patterns identified:**
- Event-bus with handler execution graphs (crewAI)
- State-machine DAGs with typed channels and version tracking (langgraph)
- Structured action/observation contracts with sandboxed execution (OpenHands)
- Flow-based control with @start/@listen/@router decorators (crewAI)
- Checkpoint-and-resume with durability modes (langgraph)
- Phase-skipping matrix for incremental workflow updates (harness)
- Multi-agent team patterns: pipeline, fan-out/fan-in, expert pool, producer-reviewer, supervisor, hierarchical delegation (harness)

**Ecosystem owner:** `canopy`

**Improvements:**
1. Standardize task-output wrapping with usage metrics (prompt_tokens, completion_tokens, tool_calls)
2. Expose command-based control (Send, Goto) for dynamic routing
3. Implement phase-skipping matrix: re-run only affected phases when input changes
4. Interrupt handling at node boundaries with async channels
5. Stream execution in multiple modes (full state, deltas, messages, custom)

---

### Theme 2: Hook and Lifecycle Signal Architecture

**Repos:** cline, crewAI, cognee, headroom

**Patterns identified:**
- Pre/Post tool-use hooks with cancellation semantics (cline)
- Lifecycle hooks (PreToolUse, PostToolUse, TaskStart, TaskComplete, TaskCancel) loaded from global + workspace dirs (cline)
- Hook timeout protection (30s) with fail-open semantics (cline)
- Event-bus with handler ordering and scope-stack management (crewAI)
- Decorator-based function instrumentation with contextvars (cognee `@agent_memory`)
- Canonical 8-stage lifecycle pipeline: ToolCallReceived → ToolCallValidated → ToolCallDispatched → ToolCallCompleted → OutputCaptured → OutputFiltered → OutputStored → SessionSignalEmitted (headroom-inspired)
- OpenTelemetry baggage context propagation (crewAI)

**Ecosystem owner:** `cortina`

**Improvements:**
1. Hook timeout (30s default) with fail-open: only `cancel: true` blocks
2. Context modification payload with size limits (50KB)
3. Standardize hook loading (workspace overrides global; all hooks run)
4. Integrate OTel baggage for async tracing
5. Define named pipeline stages as first-class contract

---

### Theme 3: Memory Architecture and Knowledge Persistence

**Repos:** letta, cognee, graphrag, beads, headroom

**Patterns identified:**
- Tiered memory: core/archival/recall with compression (letta)
- Git-backed versioned blocks with lineage/authorship (letta)
- Pluggable multi-backend abstractions: Kuzu, Neo4j, PostgreSQL, LanceDB, ChromaDB, PGVector, Qdrant, Weaviate, Milvus (cognee)
- Ontology-based entity grounding with fuzzy matching (cognee)
- 15+ search type registry: CHUNKS, GRAPH_COMPLETION, TRIPLET_COMPLETION, RAG_COMPLETION, SUMMARIES, CYPHER, NATURAL_LANGUAGE, TEMPORAL, FEELING_LUCKY, CODING_RULES, etc. (cognee)
- Dual-mode search with community detection + ranked summaries (graphrag)
- Semantic dependency types: blocks, relates_to, discovered_from, supersedes, duplicates (beads)
- Memory decay and compaction model (beads, letta)
- Cross-agent shared memory with context passing (headroom SharedContext)

**Ecosystem owner:** `hyphae`

**Improvements:**
1. Formalize tiered memory with explicit capacity limits and context-window-aware eviction
2. Add git-backed versioning to memoirs (author, timestamp, file-change tracking)
3. Implement compaction: summarize old topics, don't delete
4. Support temporal scheduling (defer_until, due_at)
5. Implement shared context for cross-agent state passing
6. Add search type registry with pluggable retrievers

---

### Theme 4: Permission and Tool Governance

**Repos:** cline, agnix, cognee

**Patterns identified:**
- Command permission controller with glob-pattern allow/deny lists (cline)
- Tool metadata: idempotent, read_only, destructive, acceptance_criteria (cline)
- Validator trait with auto-discovered rule registry (agnix: 405 rules, extensible via ValidatorProvider SPI)
- Evidence-driven rule design: source verification, normative level, test coverage (agnix)
- Permission config with safety tiers: HIGH/MEDIUM/LOW (agnix)

**Ecosystem owners:** `canopy` + `lamella`

**Improvements:**
1. Maintain tool registry with idempotency/read-only/destructive metadata
2. Enforce command permission gates with glob-pattern allow/deny
3. Implement approval gates based on tool properties
4. Lamella: validate skill/hook manifests on registration using pluggable Validator SPI

---

### Theme 5: Content-Aware Filtering and Compression

**Repos:** headroom, letta, agnix, beads, harness

**Patterns identified:**
- Content-aware routing to specialized compressors (headroom: SmartCrusher for JSON, CodeCompressor for AST, Kompress-base for general text)
- Reversible compression (CCR) with retrieval handles (headroom)
- Context-window-aware message buffering and streaming (letta)
- Progressive disclosure in skill loading: 3-tier (metadata / SKILL.md / references/) (harness)
- Auto-fix safety tiers (agnix: HIGH/MEDIUM/LOW)
- Memory decay and compaction (beads, letta)

**Ecosystem owner:** `mycelium`

**Improvements:**
1. Replace text-only filtering with content-type detection and specialized handlers
2. Implement reversible compression with retrieval handles in hyphae
3. Add progressive disclosure for skill context (3-tier loading)
4. Support safety-tier annotations on transformations

---

### Theme 6: Operator Surfaces and Multi-Interface Access

**Repos:** agent-deck, squad-monitor, vibe-dash, plandb, harness

**Patterns identified:**
- Persistent session identity with resumable conversation state (agent-deck: --resume <id>)
- Multi-interface remote operator model: TUI, CLI, HTTP, Telegram, Slack (agent-deck conductor)
- Cost tracking and token budgeting (agent-deck: daily/weekly/monthly/per-session limits)
- Event-forwarding adapters for inbound events: webhook, GitHub, ntfy, Slack (agent-deck watchers)
- Multi-agent dashboard with session timeline visualization (agent-deck, squad-monitor, vibe-dash)
- Compound graph model for task/dependency tracking (plandb)
- Evolution feedback loop: capture generated vs. shipped deltas (harness /harness:evolve)

**Ecosystem owner:** `cap`

**Improvements:**
1. Expose persistent session identity via API; support --resume <id>
2. Implement cost tracking dashboard with budget enforcement
3. Support TUI, CLI, HTTP, and remote channels through unified API
4. Add watcher framework for event-forwarding adapters
5. Display session timeline visualization

---

### Theme 7: Code Intelligence and Structural Analysis

**Repos:** rhizome, cline, continue, agnix, beads

**Patterns identified:**
- Codebase indexing and config layering (continue)
- Dynamic model routing by task type (claude-code-router: Haiku for simple, Opus for complex)
- Multi-backend architecture for validators (agnix: LSP/MCP/CLI/WASM)
- Incremental fingerprinting (Understand-Anything, now in rhizome handoff)
- Hash-based task IDs preventing merge collisions (beads: bd-a1b2 format)

**Ecosystem owner:** `rhizome`

---

### Theme 8: Shared Infrastructure and Configuration

**Repos:** spore, rulesync, ab-method, better-ccflare, tools (Strands)

**Patterns identified:**
- Rule sync with inheritance and override semantics (rulesync)
- Multi-provider adapter with OAuth token lifecycle (better-ccflare)
- Tool provider abstraction with env-driven config (tools/Strands)
- A/B testing for prompts (ab-method)

**Ecosystem owner:** `spore`

---

### Theme 9: Plugin and Skill Packaging

**Repos:** lamella, agnix, harness, cognee

**Patterns identified:**
- Hook system with global + workspace loading (cline)
- Progressive disclosure in skill context (harness)
- Pluggable validator architecture with auto-discovered rules (agnix)
- Modular pipeline-based processing with composable tasks (cognee)
- Evolution feedback loop for skill generation (harness /harness:evolve)

**Ecosystem owner:** `lamella`

---

### Theme 10: Terminal and Infrastructure Patterns

**Repos:** claude-tmux, annulus, headroom, vibe-log-cli

**Patterns identified:**
- Status detection via output regex patterns (claude-tmux)
- Terminal operator surfaces (annulus)
- Canonical lifecycle pipeline with hooks (headroom)
- Structured CLI log format (vibe-log-cli)

**Ecosystem owner:** `annulus`

---

## Findings by Ecosystem Repo

### hyphae
1. Tiered memory with explicit capacity limits and context-window eviction
2. Git-backed versioning for memoirs (author, timestamp, lineage)
3. Pluggable multi-backend abstraction (SqliteBackend + InMemoryBackend for tests)
4. Search type registry with 15+ pluggable retrievers
5. Shared context for cross-agent state passing

### cortina
1. Hook timeout (30s) with fail-open semantics
2. Standardize to named pipeline stages (headroom model)
3. OTel baggage context propagation
4. Decorator-based memory instrumentation (cognee pattern)

### canopy
1. Task output wrapping with usage metrics (crewAI TaskOutput pattern)
2. Command-based control (Send, Goto) for dynamic routing
3. Phase-skipping matrix for incremental updates
4. Interrupt handling at node boundaries (LangGraph human-in-the-loop)
5. DAG-based multi-agent graph with get_ready_nodes primitive

### mycelium
1. Content-aware routing with specialized handlers (headroom ContentRouter)
2. Reversible compression (CCR) with retrieval handles
3. Progressive disclosure for skill context (3-tier loading)
4. Declarative TOML-based filter extensions

### septa
New contracts required:
- `credential-v1` — credential envelope (type, source, status, lifecycle)
- `context-envelope-v1` — versioned memory+symbols+session bundle with token counts

### lamella
1. Validator plugin architecture (agnix ValidatorProvider SPI)
2. Enforce 3-tier skill loading as convention
3. Safety tiers for auto-applied skill fixes
4. Evolution feedback loop for skill generation

### rhizome
1. Multi-backend validator exposure (LSP/MCP/CLI/WASM)
2. Incremental fingerprinting with ChangeClass taxonomy

### cap
1. Session persistence and --resume <id> pattern
2. Cost tracking dashboard with budget enforcement
3. Multi-interface access (TUI, CLI, HTTP, remote channels)
4. Watcher framework for event-forwarding adapters

---

## Handoffs Spawned from Wave 2

| # | Handoff | Target Repo | Source |
|---|---------|------------|--------|
| W2a | [Cortina: Lifecycle Pipeline Stages](../cortina/lifecycle-pipeline-stages.md) | cortina | headroom + cognee Wave 2 |
| W2b | [Lamella: Skill Progressive Disclosure](../lamella/skill-progressive-disclosure.md) | lamella | harness Wave 2 |
| W2c | [Hyphae: Pluggable Backend Adapters](../hyphae/pluggable-backends.md) | hyphae | cognee + letta + strands Wave 2 |
| W2d | [Hyphae: Tiered Memory with Context-Window Eviction](../hyphae/tiered-memory-eviction.md) | hyphae | letta + graphrag Wave 2 |
| W2e | [Septa: Credential Abstraction V1 Contract](../septa/credential-abstraction-v1.md) | septa | better-ccflare + cognee + letta + headroom Wave 2 |
| W2f | [Canopy: DAG-Based Task Graph](../canopy/dag-task-graph.md) | canopy | crewAI + langgraph + strands + openHands + beads Wave 2 |

---

## What Not to Act On

1. **Monolithic Go binary pattern** (agent-deck) — basidiocarp is distributed Rust
2. **Tmux-centric process management** (claude-tmux) — extract status-detection pattern, not tmux as dependency
3. **ML-based compression** (headroom Kompress-base) — adopt framework, skip model weights
4. **Product-specific UI rendering** (React, Ink, VSCode API) — borrow data models, not rendering code
5. **Tight LLM agent coupling** (crewAI, letta, langgraph) — basidiocarp is LLM-agnostic
6. **Vendor lock-in backends** (Dolt, Neo4j) — adopt multi-backend abstraction, let operators choose
7. **Decorator-only instrumentation** (cognee `@agent_memory`) — only if core hooks support it
8. **Claude Code-specific generation** (harness) — adapt patterns for any multi-agent orchestration

---

## Wave 2 Consensus

1. **Orchestration decoupled from memory:** Canopy owns coordination; hyphae owns state; septa defines contracts
2. **Hooks are the integration backbone:** Cortina owns hook semantics, lifecycle stages, telemetry
3. **Progressive disclosure prevents context bloat:** 3-tier loading standard in lamella, mycelium, hyphae
4. **Safety tiers distinguish urgency from risk:** HIGH/MEDIUM/LOW for approval gates, auto-fixes, transformations
5. **Contracts are evidence-based:** Each contract includes why (evidence, normative level, test coverage)
6. **Reversible operations preserve optionality:** CCR handles in mycelium, git versioning in hyphae, phase-skipping in canopy
7. **Multi-interface access is non-negotiable:** TUI, CLI, HTTP, remote channels expose same API
8. **Evolution closes the learning loop:** Capture generated vs. shipped deltas as permanent lessons

The six handoffs above encode these insights as concrete implementation specs. Implementation should be prioritized in the next cycle.
