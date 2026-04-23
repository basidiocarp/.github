# Beads Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `beads`
Lens: what to borrow from beads, how it fits the basidiocarp ecosystem, and what it suggests improving

## One-paragraph read

Beads (bd) is a distributed, dependency-aware issue tracker built on Dolt (versioned SQL database) that replaces markdown task files with a graph-backed persistent database designed for multi-agent collaboration. Its strongest portable ideas are: semantic dependency types (`blocks`, `relates_to`, `discovered_from`, `supersedes`) enabling directional dependency navigation, hash-based task IDs preventing merge collisions in multi-agent workflows, temporal scheduling (`defer_until`, `due_at`) for hiding future work until ready, and a "compaction" model that summarizes closed issues to prevent token bloat. Basidiocarp benefits most in `septa` (dependency semantics contract), `canopy` (unblocked task detection), and `hyphae` (temporal scheduling + memory decay/consolidation). Dolt itself is too specialized to adopt as basidiocarp's primary store.

## What Beads is doing that is solid

### 1. Semantic dependency types with directional edges

Issue struct encodes `blocks`/`relates_to`/`parent_child`/`discovered_from` relationships as first-class data. Agents can query "what's blocking me?" or "what did I discover?" with directional semantics. Edge types are not all equivalent — the direction and meaning matter.

Evidence:
- `internal/types/types.go` lines 14-96: Issue struct with Blocks, RelatesTo, DiscoveredFrom, ParentID, ChildIDs fields
- `internal/storage/sqlite/schema.go`: `dependencies` table with `dep_type` column (blocks, relates_to, discovered_from, supersedes, duplicates)
- `bd link`, `bd unlink` commands for managing typed dependency edges

Why that matters here:
- `canopy` uses dependency tracking for task ownership handoffs; typed edges are more precise than a flat dependency list.
- `hyphae` memoir relationships are currently untyped; borrowing these semantic types would make memoir links navigable.
- `septa` should standardize this dependency type vocabulary across all tools.

### 2. Hash-based task IDs preventing merge collisions

Task IDs use content hash (`bd-a1b2` format), not sequence numbers. Two agents creating work simultaneously never collide. Critical for distributed multi-agent workflows without a central ID authority.

Evidence:
- `cmd/bd/id*.go`: ID generation using content hash (path + timestamp + random component)
- `bd-a3f8.1.1` hierarchical format for epic/subtask relationships (dot notation)
- Collision probability is negligible at the expected task count per repo

Why that matters here:
- `canopy` task IDs use ULIDs today (good), but the hierarchical ID format for parent-child relationships is worth borrowing.
- `septa` should standardize task/handoff ID format across the ecosystem.

### 3. Temporal scheduling with `defer_until` and `due_at`

`bd ready` shows only work with no open blockers AND whose `defer_until` timestamp has passed. Work can be scheduled into the future without blocking the backlog. `due_at` adds urgency sorting for time-constrained work.

Evidence:
- `internal/types/types.go` lines 49-50: `DeferUntil`, `DueAt` fields on Issue struct
- `bd ready` command filters by both `defer_until <= now` and `status == open` and `blockers_count == 0`
- `bd update <id> --defer=+1h` for relative scheduling

Why that matters here:
- `hyphae` memory entries should support `defer_until` for hiding context until needed.
- `hymenium` workflow engine should support temporal dependencies: "start this step not before T".

### 4. Compaction model (semantic memory decay)

`bd compact` summarizes old closed issues into a short summary block, reducing token bloat in long-running projects. Preserves decision context without carrying all historical detail.

Evidence:
- `cmd/bd/compact.go`: Compaction command
- CLAUDE.md describes "semantic memory decay" as the design intent
- Output: compact.md with summarized closed issues, retained as permanent context

Why that matters here:
- `hyphae` memory consolidation (`hyphae_memory_consolidate`) should adopt this decay model explicitly.
- Old closed memories/topics should be summarizable into one entry, not just deleted.

## What to borrow directly

### Borrow now

- Semantic dependency types contract.
  Best fit: `septa` (standardize `blocks`, `relates_to`, `discovered_from`, `supersedes`, `duplicates` as shared edge vocabulary).

- Temporal scheduling (`defer_until`, `due_at`).
  Best fit: `hyphae` (add to memory entries), `hymenium` (temporal workflow step dependency).

- Compaction/consolidation model.
  Best fit: `hyphae` (`hyphae_memory_consolidate` should summarize old topics, not just delete them).

- Unblocked-task detection (`bd ready` pattern).
  Best fit: `canopy` (task ownership model should expose "what tasks are unblocked for this agent?" query).

## What to adapt, not copy

### Adapt

- Dolt as storage backend.
  Adapt as an optional `hyphae` backend if concurrent multi-writer memory becomes critical. Stay on SQLite for now.

- Hierarchical IDs (dot notation for epic/subtask).
  Adapt for `canopy` parent-child task trees; ULID base + dot notation extension preserves sort order.

- Compaction output format (compact.md).
  Adapt for `hyphae` topic summaries; output format can be JSON/structured rather than Markdown.

## What not to borrow

### Skip

- Dolt dependency for core basidiocarp.
  Adds complexity for scenarios not yet needed (multi-writer, cell-level merge).

- Full issue type taxonomy (bug|feature|task|epic|chore).
  This is issue-tracking-specific; use simpler `memory`/`decision`/`error`/`context` types in `hyphae`.

- Audit/rollback system (`ado` package).
  Too specialized for agent memory; use git for auditability in basidiocarp.

## How Beads fits the ecosystem

### Best fit by repo

- `septa`: Dependency semantic types as a shared contract vocabulary.
- `canopy`: Typed dependency edges for task handoffs; unblocked-task detection.
- `hyphae`: Temporal scheduling on memory entries; compaction/decay model.
- `hymenium`: Temporal workflow step dependencies.
- `cortina`: Event routing could borrow Beads' typed event edges for signal flow.

## What Beads suggests improving in your ecosystem

### 1. Add temporal scheduling to hyphae and hymenium

Beads shows `defer_until`/`due_at` is critical for agent workflows — hiding future work until ready. Add to `hyphae` memory entries and `hymenium` workflow steps.

### 2. Standardize dependency semantics across tools

Every tool (canopy, cortina, hyphae) that models relationships should speak the same edge vocabulary. Add to `septa` as a shared dependency-type contract.

### 3. Implement "ready" detection for task trees in canopy

`bd ready` (unblocked, not deferred, open) is a powerful coordination primitive. `canopy` task ownership should expose an equivalent query: "what tasks are unblocked for this agent right now?"

### 4. Formalize memory consolidation as decay, not deletion

Beads' compaction preserves decision context in a summarized form. `hyphae_memory_consolidate` should summarize and compress, not delete.

## Final read

**Borrow:** semantic dependency types, temporal scheduling, unblocked-task detection, compaction/decay model.

**Adapt:** Dolt as optional backend (low priority), hierarchical IDs for task trees, compaction output format.

**Skip:** full Dolt dependency, issue type taxonomy, audit/rollback system.
