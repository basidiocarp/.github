# Crystal Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `crystal`
Lens: what to borrow from crystal, how it fits the basidiocarp ecosystem, and what it suggests improving

> **Status note:** Crystal is deprecated as of February 2026 and replaced by Nimbalyst. Do NOT adopt Crystal directly. Extract architectural patterns only; expect these patterns to have evolved in Nimbalyst.

## One-paragraph read

Crystal is a deprecated Electron desktop app for managing parallel Claude Code instances via git worktrees, with rich terminal UI (XTerm.js) and a Zustand-backed React frontend communicating with Node.js via IPC. Its strongest portable ideas are: git worktree isolation per agent session, terminal panel lazy initialization (spawn PTY only when viewed), IPC event bus for real-time renderer-to-main communication, and Zustand store for reactive frontend state management. Basidiocarp benefits most in `volva` (worktree isolation, subprocess management), `cortina` (IPC event bus pattern), and `cap` (Zustand store, component patterns). Crystal is deprecated — treat it as a reference for these patterns, not as an adoption target.

## What Crystal is doing that is solid

### 1. Git worktree isolation per session

Each Claude Code instance runs in an isolated git worktree via `git worktree add`. Prevents conflicts between parallel development efforts. Sessions can independently commit, branch, and diff without touching each other.

Evidence:
- `main/src/services/worktreeManager.ts` (931 lines): `GitWorktreeManager` class handling `git worktree add`, `list`, `remove`
- Session lifecycle tied to worktree: session created → worktree created; session destroyed → worktree removed (configurable)
- Worktree paths are deterministic (derived from session name) for idempotent create/remove

Why that matters here:
- `volva` (execution host) should use worktree isolation as the default for parallel agent executions.
- `canopy` task ownership can map to worktree boundaries: one task → one worktree.

### 2. Terminal panel architecture with lazy initialization

Panels only spawn PTY processes when first viewed (memory efficiency). Multiple terminal instances per session, each with independent scrollback. Panel state (scroll position, buffer) persists across app restarts.

Evidence:
- `main/src/services/terminalPanelManager.ts` (370 lines): `TerminalPanelManager` with lazy PTY initialization
- Panels created in "suspended" state; PTY spawned on first `activate()` call
- Panel state serialized to SQLite on each screen-width change or scroll event

Why that matters here:
- `annulus` (terminal operator surfaces) should borrow lazy initialization to avoid spawning PTY until needed.
- `volva` can use the same pattern for subprocess management: create process record, start process on first access.

### 3. IPC event bus for async renderer-main communication

Real-time bidirectional communication between Electron frontend and Node.js backend. IPC handlers coordinate session lifecycle, git operations, and file I/O without blocking the UI thread.

Evidence:
- `main/src/events.ts` (1108 lines): `EventManager` class with typed `on(event, handler)` / `emit(event, data)` API
- Events grouped by domain: `session:*`, `worktree:*`, `git:*`, `file:*` with consistent naming
- Async handlers with error propagation back to renderer

Why that matters here:
- `cortina` signal runner should adopt the same typed event bus pattern for lifecycle signal propagation.
- `septa` should define an IPC method naming convention (`tool:action` format).

### 4. Zustand store for reactive frontend state management

Lightweight reactive store (not Redux/Context) centralizing session state, panel state, and preferences. Easy to serialize/deserialize for persistence. State transitions are explicit actions.

Evidence:
- `frontend/src/stores/sessionStore.ts` (699 lines): `useSessionStore` Zustand store
- Per-store slices: sessions, panels, preferences, ui — each with typed actions
- Persistence via `zustand/middleware` serialize to localStorage/SQLite

Why that matters here:
- `cap` (dashboard UI) should evaluate Zustand over heavier state management; Crystal's store structure maps directly to cap's needs.

## What to borrow directly

### Borrow now

- Git worktree isolation per execution.
  Best fit: `volva` core pattern — each agent execution gets own worktree.

- Terminal panel lazy initialization.
  Best fit: `annulus` — don't spawn PTY until panel is activated; suspend when hidden.

- IPC event bus pattern.
  Best fit: `cortina` — typed event dispatcher with `domain:action` naming for lifecycle signals.

- Zustand store pattern.
  Best fit: `cap` frontend state management.

## What to adapt, not copy

### Adapt

- Electron + React frontend.
  Adapt: `cap` is web-based; extract React patterns (Zustand, component structure) but use web stack, not Electron.

- Multi-panel terminal system.
  Adapt: generalize to multi-panel for all tool types (CLI, logs, diff, editor), not just terminals.

- Session → worktree → agent mapping (currently 1:1:1).
  Adapt: `canopy` allows task handoffs; the mapping should be task → worktree with potential agent reassignment.

## What not to borrow

### Skip

- Full Electron dependency.
  Basidiocarp is CLI/web/MCP-first; desktop app dependency adds unnecessary complexity.

- Crystal's SQLite schema (session-specific tables).
  Use `hyphae` for session memory, git for state; don't duplicate with another session store.

- Session templating/numbering system.
  UI convenience, not core pattern. `lamella` handles skill templating.

- Project/folder tree hierarchy.
  Use git repo structure instead; don't reinvent project management.

## How Crystal fits the ecosystem

### Best fit by repo

- `volva`: Worktree isolation and lazy subprocess management.
- `cortina`: IPC event bus for lifecycle signals.
- `cap`: Zustand store and React component patterns.
- `annulus`: Terminal panel architecture with lazy loading and scrollback persistence.
- `canopy`: Session ↔ worktree mapping (extend to allow task-to-multiple-agents).

## What Crystal suggests improving in your ecosystem

### 1. Explicit session/execution lifecycle in volva

Crystal tracks: `initializing → running → waiting → stopped → error`. `volva` should emit similar status events (start, progress, complete, error) with structured data.

### 2. IPC protocol for tool coordination

Crystal's IPC handlers are ad-hoc per domain. `septa` should define an IPC method naming convention (`tool:action` format) for cross-tool event coordination.

### 3. Lazy-load UI components in cap

Crystal's lazy panel initialization is memory-efficient. `cap` should lazy-render tabs, session lists, diffs — not load all content at mount.

## Final read

**Borrow:** git worktree isolation, terminal panel lazy initialization, IPC event bus, Zustand store.

**Adapt:** Electron + React → web-only component patterns; multi-panel terminal → generalize to all tool types; 1:1:1 session mapping → flexible task-to-worktree assignment.

**Skip:** full Electron dependency, Crystal's SQLite schema, session templating, project/folder tree.
