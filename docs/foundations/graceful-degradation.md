# Graceful Degradation Tiers

The Basidiocarp ecosystem organizes tools into three degradation tiers to guide runtime resilience and fallback behavior. This classification helps teams understand which tool failures are fatal to the agent loop and which can be handled gracefully.

---

## The Three Tiers

### Tier 1: Critical
Tool unavailability **breaks the core agent loop**. Without these tools, the agent cannot function or fulfill its purpose.

Agent must have these to:
- Accept and parse input from the user
- Execute decisions and output results
- Manage the execution environment
- Run hooks that guard safety boundaries

**How to handle Tier 1 failure**: Block the agent. Emit a clear fatal error. Do not attempt to continue.

### Tier 2: Optional
Tool unavailability **degrades quality but the agent loop continues**. The agent can still function; some capabilities are reduced.

Agent can still:
- Reason and execute
- Produce output
- But may lack context, tracking, or decision support

**How to handle Tier 2 failure**: Log a warning. Degrade gracefully. Continue with reduced capability. Offer the user reduced context or re-plan when possible.

### Tier 3: Enhancement
Tool unavailability **reduces observability or operator UX only**. Does not affect the agent's ability to reason or produce results.

Agent loses:
- Visibility into execution flow
- Rich status display
- Post-run analysis
- Discovery and update capabilities

**How to handle Tier 3 failure**: Log as informational. Continue normally. No degradation visible to agent execution.

---

## Ecosystem Tool Classification

| Tool | Tier | Rationale |
|------|------|-----------|
| **mycelium** | Tier 1 | Token-optimized output proxy. Blocks if unavailable; the agent cannot read command output. |
| **volva** | Tier 1 | Execution host runtime layer. Blocks if unavailable; commands cannot be executed. |
| **cortina** | Tier 1 | Hook lifecycle runner. Blocks if hooks cannot be executed; safety boundaries are unguarded. |
| **hyphae** | Tier 2 | Persistent memory and RAG. Agent continues; reasoning lacks prior context, decisions may repeat. |
| **rhizome** | Tier 2 | Code intelligence and structure awareness. Agent continues; code reasoning is less precise. |
| **canopy** | Tier 2 | Task tracking and multi-agent coordination. Single-agent workflows continue; complex orchestration degrades. |
| **cap** | Tier 3 | Operator dashboard and UI. Continues normally; operator visibility is limited. |
| **annulus** | Tier 3 | Operator statusline and terminal utilities. Continues normally; real-time operator feedback is reduced. |
| **stipe** | Tier 3 | Ecosystem installer and manager. Continues normally; discovery and self-update are unavailable. |
| **spore** | Tier 1 | Shared transport, discovery, config, and infrastructure primitives. Blocks if unavailable; core runtime services cannot operate. |
| **lamella** | Tier 2 | Hooks and plugins for Claude Code. Continues; custom hooks and skills are unavailable. |
| **hymenium** | Tier 1 | Workflow orchestration engine. Blocks if unavailable; complex workflows cannot be dispatched. |

---

## Behavior Contract Per Tier

### Tier 1: Critical (Block on Failure)

**Startup**: Tool availability must be verified before the agent loop begins. If any Tier 1 tool is unavailable, the agent must exit with a clear error and a non-zero exit code.

**Runtime**: If a Tier 1 tool becomes unavailable during execution, the agent must:
1. Emit a clear fatal error with the tool name, reason, and timestamp.
2. Cease accepting new work.
3. Finish any in-flight operation cleanly and exit.

**Example**:
```
FATAL: volva execution host unreachable (connection refused on localhost:12345)
Set VOLVA_ENDPOINT or ensure volva is running before proceeding.
Exit code: 127
```

### Tier 2: Optional (Warn and Continue)

**Startup**: Tool availability is checked but not required. If unavailable at startup, a warning is logged and execution proceeds.

**Runtime**: If a Tier 2 tool becomes unavailable, the agent must:
1. Log a warning with the tool name, reason, and timestamp.
2. Degrade the capability gracefully (no context recall, no structure awareness, etc.).
3. Continue accepting and processing work.
4. Optionally suggest workarounds or fallbacks to the user.

**Example**:
```
WARNING: hyphae memory service unavailable (connection refused) — continuing without prior context recall.
Set HYPHAE_ENDPOINT or ensure hyphae is running for context-aware reasoning.
```

### Tier 3: Enhancement (Inform and Continue)

**Startup**: Tool availability is optional. Failure at startup is not logged as an error; it is noted in debug or trace logs only.

**Runtime**: If a Tier 3 tool becomes unavailable or fails, the agent must:
1. Log as informational only (no warning level).
2. Continue normal operation.
3. Do not mention the failure to the user unless they explicitly ask for detailed status.

**Example**:
```
[DEBUG] annulus statusline service unavailable; terminal status updates will not display.
```

---

## Implementation Guidance

### For Tool Producers (emit runtime state)

When a tool emits degradation status:

1. Use the `degradation-tier-v1` schema to describe the failure.
2. Include the tool name, tier number, and reason for unavailability.
3. List affected capabilities so consumers know what is lost.
4. Emit this status through the event or logging channel (cortina, volva, or direct log).

See [`degradation-tier-v1.schema.json`](../../septa/degradation-tier-v1.schema.json) for the canonical payload shape.

### For Tool Consumers (handle degradation)

When consuming tool outputs or managing dependencies:

1. Check tool health at startup for Tier 1 tools only. Tier 2 and 3 are optional.
2. On Tier 1 failure, block and emit a fatal error before proceeding.
3. On Tier 2 failure, log a warning and degrade gracefully (skip context lookup, fall back to simple reasoning, etc.).
4. On Tier 3 failure, do nothing visible — fail silently and continue.
5. Parse the `degradation-tier-v1` payload to understand what capabilities are lost.

### For Framework Authors (hyphae, canopy, cortina, etc.)

Design your tool to report degradation clearly:

1. Track availability of direct dependencies (typically Tier 1 tools like spore or volva).
2. Emit `degradation-tier-v1` payloads when downstreams become unavailable.
3. Document which Tier 2 or Tier 3 capabilities degrade when you are unavailable.
4. Allow graceful fallback in your API (e.g., memory recall returns empty on connection failure, does not panic).

---

## Current Behavior

This section audits what each major ecosystem tool actually does when it fails, comparing against the tier classification above.

### Tier 1: Critical

| Tool | Actual Behavior | Matches Tier 1? |
|------|-----------------|-----------------|
| **mycelium** | Falls back to passthrough; still returns command output. | ✓ Correct — continues with degraded output. |
| **volva** | Fails before launch or during runtime; does not execute commands without the host. | ✓ Correct — blocks execution. |
| **cortina** | Logs warning and retries; does not block the outer tool even when Hyphae is unavailable. | ⚠ Actually Tier 2 behavior — continues with local scoped state. |
| **spore** | Used by all tools; unavailability blocks runtime services. | ✓ Correct — shared transport unavailability is critical. |
| **hymenium** | Pauses workflow execution on Canopy unavailability; retries on reconnect rather than corrupting state. | ⚠ Actually Tier 2 behavior — continues with degraded dispatch capability. |

### Tier 2: Optional

| Tool | Actual Behavior | Matches Tier 2? |
|------|-----------------|-----------------|
| **hyphae** | Falls back to FTS-only search when embeddings unavailable; storage errors fail cleanly; reads may continue during write failures. | ✓ Correct — agent continues without vector search. |
| **rhizome** | Falls back to tree-sitter when LSP unavailable; parse failures return clear errors tied to files; workspace-root loss narrows context. | ✓ Correct — agent continues with reduced precision. |
| **canopy** | Database locked waits on SQLite timeout; foreign-key checks fail fast with clear errors; agent-not-registered returns explicit errors. | ✓ Correct — coordination degrades but agent still runs. |
| **lamella** | Validation failures stop the build with specific validator output; missing manifest resources fail with unresolved paths. | ⚠ Validation-time tool, not runtime — doesn't degrade. |

### Tier 3: Enhancement

| Tool | Actual Behavior | Matches Tier 3? |
|------|-----------------|-----------------|
| **cap** | Hyphae DB missing returns empty memory views; Mycelium unavailable zeroes analytics; backend unreachable shows connection error; API key mismatch fails with `401`. | ⚠ Varies — some failures degrade UI silently, others show user-facing errors. |
| **annulus** | Tool not installed renders nothing instead of erroring; data source unavailable degrades statusline gracefully — only available segments appear; config missing uses defaults. | ✓ Correct — continues normally without operator feedback. |
| **stipe** | GitHub release lookup fails until metadata can be read; partial install reports what is missing; host not detected offers supported-host guidance. | ⚠ Setup-time tool — doesn't degrade at runtime. |

### Mismatch Summary

Two tools have degradation behavior that diverges from their tier classification:

1. **Cortina** is classified Tier 1 but behaves like Tier 2: when Hyphae unavailable, it falls back to local scoped state and retries later instead of blocking the outer tool.
2. **Hymenium** is classified Tier 1 but behaves like Tier 2: when Canopy unavailable, it pauses workflow execution and retries rather than blocking the entire agent loop.

Both tools are correct to continue with degradation, but their tier should be reconsidered. The distinction is whether the tool's own unavailability breaks the agent loop (Tier 1) versus whether a dependency's unavailability causes graceful degradation (Tier 2). Cortina and Hymenium continue operation when their sibling dependencies fail, placing them closer to Tier 2.

---

## Reference

- **Degradation Payload Schema**: [`septa/degradation-tier-v1.schema.json`](../../septa/degradation-tier-v1.schema.json)
- **Workspace Architecture**: [`docs/workspace/ECOSYSTEM-OVERVIEW.md`](../workspace/ECOSYSTEM-OVERVIEW.md)
- **Contract Inventory**: [`septa/README.md`](../../septa/README.md)
