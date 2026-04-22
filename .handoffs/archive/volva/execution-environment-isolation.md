# Execution Environment Isolation

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** `volva/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** skill content packaging (lamella), task lifecycle state machine (hymenium/canopy), or dashboard surfaces (cap)
- **Verification contract:** run the repo-local commands below and `bash .handoffs/volva/verify-execution-environment-isolation.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** new `src/execenv.rs` or `src/execenv/` module; existing runtime/session initialization code for integration
- **Reference seams:** multica `server/internal/daemon/execenv/execenv.go` and `runtime_config.go` for the named subsystem; existing volva runtime initialization for integration points
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Volva hosts agent execution but scatters execution environment concerns — directory tree setup, provider-native config injection, skill injection, GC metadata, worktree caching — across daemon startup code with no named boundary. Multica treats this as a dedicated `execenv` package with clear responsibilities. Without a named subsystem, each new concern (a new provider, a new injection target, worktree cleanup) must be wired into startup code ad hoc, and the environment setup cannot be tested in isolation.

## What exists (state)

- **`volva`:** has runtime session initialization but no named execution environment module
- **`lamella`:** owns skill content that needs to be injected into execution environments
- **multica reference:** a dedicated `execenv` package handling directory tree, provider config injection (CLAUDE.md/AGENTS.md/GEMINI.md), skill injection, GC metadata, and worktree caching

## What needs doing (intent)

Define a named `ExecEnv` module in volva that owns:
1. **Directory tree setup** — create the isolated working directory for a task
2. **Provider config injection** — write provider-native context files (CLAUDE.md, AGENTS.md, etc.) into the working directory based on the target provider
3. **Skill injection** — place lamella-packaged skill content into provider-native paths
4. **Worktree management** — set up and cache git worktrees for the task scope
5. **Cleanup** — tear down the environment after task completion, with GC metadata for deferred cleanup

## Scope

- **Primary seam:** execution environment setup and teardown as a named module
- **Allowed files:** `volva/src/` execution environment and runtime modules
- **Explicit non-goals:**
  - Do not implement the task state machine (hymenium/canopy concern)
  - Do not build skill content (lamella concern)
  - Do not build a sweeper for stale environments (that is hymenium's sweeper responsibility at the orchestration layer)

---

### Step 1: Define ExecEnv module with directory tree setup

**Project:** `volva/`
**Effort:** 0.5 day
**Depends on:** nothing

Create an `ExecEnv` struct (or module) that owns the lifecycle of an isolated task directory. It should create the directory, track its path, and clean up on drop or explicit teardown.

#### Verification

```bash
cd volva && cargo check 2>&1
cd volva && cargo test execenv 2>&1
```

**Checklist:**
- [ ] ExecEnv module exists as a named boundary
- [ ] Directory creation and cleanup are tested
- [ ] Paths are platform-aware (not Unix-only)

---

### Step 2: Add provider config injection

**Project:** `volva/`
**Effort:** 0.5 day
**Depends on:** Step 1

Add a method that writes provider-native context files into the ExecEnv working directory. The provider type determines which files are written (e.g., CLAUDE.md for Claude, AGENTS.md for Codex). Content comes from configuration or from lamella-provided paths.

#### Verification

```bash
cd volva && cargo test inject 2>&1
```

**Checklist:**
- [ ] Provider-specific files are written to the correct locations
- [ ] Multiple providers can be supported without conditional explosion
- [ ] Missing content is handled gracefully (skip, not crash)

---

### Step 3: Add skill injection and worktree management

**Project:** `volva/`
**Effort:** 0.5 day
**Depends on:** Step 2

Add skill injection: place skill files from lamella-provided paths into the ExecEnv. Add worktree setup: create or reuse a git worktree scoped to the task. Add GC metadata: record creation time and task association so stale environments can be cleaned up later.

#### Verification

```bash
cd volva && cargo test 2>&1
cd volva && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Skill files are placed in provider-native paths within the ExecEnv
- [ ] Worktree setup and reuse are tested
- [ ] GC metadata is recorded
- [ ] No new clippy warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/volva/verify-execution-environment-isolation.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/volva/verify-execution-environment-isolation.sh
```

## Context

Source: multica ecosystem borrow audit (2026-04-14) section "Provider-native config injection in execution environments" and improvement suggestion "Treat execution environment isolation as a named subsystem in volva." See `.audit/external/audits/multica-ecosystem-borrow-audit.md`.

Related handoffs: #84b Volva Memory Protocol Injection (writes into the exec env), #71 Volva Hyphae Recall Injection (reads from hyphae during exec env setup). This handoff provides the named boundary those features should target.
