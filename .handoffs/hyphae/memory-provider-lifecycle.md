# Memory Provider Lifecycle Hooks

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** context compression implementation (hymenium/volva), credential management, or gateway/platform integration
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hyphae/verify-memory-provider-lifecycle.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** `hyphae-core/src/` memory backend trait or provider interface; workspace crate that defines the memory lifecycle
- **Reference seams:** hermes-agent `agent/memory_provider.py` for the `MemoryProvider` abstract interface; `agent/memory_manager.py:71-362` for the routing and isolation pattern
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Hyphae memory backends do not expose hooks for three important lifecycle events: (1) background prefetch before a turn starts (`queue_prefetch`), so recall can begin before the model needs it; (2) compression participation (`on_pre_compress`), so memory backends can protect critical content from being summarized away; and (3) delegation handoff (`on_delegation`), so memory state can be prepared when a task is handed to another agent. Without these hooks, memory backends are passive passengers — they cannot participate in compression decisions, anticipate recall needs, or prepare for delegation.

## What exists (state)

- **`hyphae`:** has memory store, recall, consolidation, and search but no lifecycle hooks for compression or delegation
- **hermes-agent reference:** a `MemoryProvider` abstract interface defining `initialize`, `system_prompt_block`, `prefetch`, `queue_prefetch`, `sync_turn`, `on_pre_compress`, `on_delegation`, and `get_config_schema`
- **hermes-agent `MemoryManager`:** routes tool calls across providers with individual isolation so one provider's failure does not suppress others

## What needs doing (intent)

Add three lifecycle hooks to hyphae's memory provider interface:

1. **`queue_prefetch`** — allow callers to trigger background recall before a turn starts, so relevant memories are warm when the model needs them
2. **`on_pre_compress`** — notify the memory backend before context compression occurs, allowing it to flag critical content that should not be summarized away
3. **`on_delegation`** — notify the memory backend when a task is being delegated to another agent, allowing it to prepare handoff-relevant memory state

Each hook should be optional (default no-op) so existing backends are not forced to implement all three immediately. Hook failures should be isolated — one hook failing should not prevent others from running.

## Scope

- **Primary seam:** memory provider lifecycle trait extension
- **Allowed files:** `hyphae/` core memory trait and provider modules
- **Explicit non-goals:**
  - Do not implement context compression (hymenium/volva concern)
  - Do not change the existing recall, store, or consolidation interfaces
  - Do not add new memory backends in this handoff

---

### Step 1: Add queue_prefetch hook

**Project:** `hyphae/`
**Effort:** 0.5 day
**Depends on:** nothing

Add a `queue_prefetch` method to the memory provider trait with a default no-op implementation. The method accepts a topic or query hint and triggers background recall. Callers can fire this before the model turn starts.

#### Verification

```bash
cd hyphae && cargo check 2>&1
cd hyphae && cargo test prefetch 2>&1
```

**Checklist:**
- [ ] `queue_prefetch` exists on the trait with a default no-op
- [ ] At least one test exercises the prefetch path
- [ ] Existing backends compile without changes

---

### Step 2: Add on_pre_compress hook

**Project:** `hyphae/`
**Effort:** 0.5 day
**Depends on:** Step 1

Add an `on_pre_compress` method that receives context about the upcoming compression (e.g., which messages are candidates for removal) and returns a set of content identifiers that should be protected. Default implementation returns an empty set.

#### Verification

```bash
cd hyphae && cargo test compress 2>&1
```

**Checklist:**
- [ ] `on_pre_compress` exists with a default returning empty protection set
- [ ] A test verifies that protected content identifiers are returned correctly
- [ ] Hook failure does not prevent compression from proceeding

---

### Step 3: Add on_delegation hook

**Project:** `hyphae/`
**Effort:** 0.5 day
**Depends on:** Step 1

Add an `on_delegation` method that receives the target agent identity and prepares relevant memory state for handoff. Default implementation is a no-op.

#### Verification

```bash
cd hyphae && cargo test delegation 2>&1
cd hyphae && cargo test 2>&1
cd hyphae && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] `on_delegation` exists with a default no-op
- [ ] A test exercises the delegation hook
- [ ] All existing tests pass without regression
- [ ] No new clippy warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/hyphae/verify-memory-provider-lifecycle.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/hyphae/verify-memory-provider-lifecycle.sh
```

## Context

Source: hermes-agent ecosystem borrow audit (2026-04-14) section "Memory provider lifecycle interface with background prefetch and delegation hooks." See `.audit/external/audits/hermes-agent-ecosystem-borrow-audit.md`.

Related handoffs: #85 Hyphae Memory Boundary Hardening (hardening existing boundaries), #69 Hyphae Rhizome AST Chunking. This handoff adds the lifecycle hooks that make hyphae an active participant in agent loops rather than a passive store.
