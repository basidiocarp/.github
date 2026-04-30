# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`basidiocarp` is a workspace of related projects for AI coding agent infrastructure. It mixes Rust CLIs and libraries, a React and TypeScript dashboard, Markdown packaging content, and shared cross-project contracts. The root owns conventions, shared docs, contract governance, and version pins. Most major subprojects are their own git repositories.

---

## Operating Model

- Do not build or test from the root as one unified project. Run commands inside the subproject you change.
- Do not assume one shared git history. Use git in the repo that owns the files you changed.
- Do not treat cross-tool payloads as informal. Schema changes go through `septa/`.
- Do not let shared dependency drift hide in subrepos. Shared pins live in `ecosystem-versions.toml`.
- Do not treat the external audit corpus as source of truth. Use `.audit/external/` to evaluate borrowed ideas, then land the real decisions in the owning repo, `septa/`, or `docs/foundations/`.

---

## Failure Modes

- **Wrong working directory**: Commands fail or hit the wrong repository. Change into the touched subproject before building, testing, or using git.
- **Contract drift**: One tool changes a payload and another breaks later. Check `septa/README.md`, update the schema and fixture first, then update every producer and consumer in the same change.
- **Version drift**: Shared libraries, especially `spore`, move out of sync across projects. Check `ecosystem-versions.toml` before changing shared dependencies.
- **Workspace-level git assumptions**: The root is a small workspace meta-repo. Nested project repos still own their own code history. Use root git for workspace docs, shared config, and coordination assets; use git inside the specific subproject for code changes.

---

## Build & Test Commands

```bash
cd mycelium && cargo build --release && cargo test
cd hyphae && cargo build --release && cargo test
cd rhizome && cargo build && cargo test --all
cd spore && cargo build && cargo test
cd stipe && cargo build --release && cargo test
cd cortina && cargo build --release && cargo test
cd canopy && cargo build --release && cargo test
cd annulus && cargo build --release && cargo test
cd hymenium && cargo build --release && cargo test
cd volva && cargo check && cargo test

cd cap && npm run dev:all
cd cap && npm run build && npm test

cd lamella && make validate
cd lamella && make build-marketplace
```

---

## Architecture

```text
basidiocarp/
├── mycelium/   token-optimized CLI proxy
├── hyphae/     persistent memory and RAG
├── cap/        dashboard and operator UI
├── rhizome/    code intelligence MCP server
├── spore/      shared Rust infrastructure
├── stipe/      installer and manager
├── cortina/    lifecycle signal runner
├── lamella/    skills, hooks, and plugin packaging
├── canopy/     multi-agent coordination runtime
├── annulus/    operator utilities and statusline tooling
├── hymenium/   workflow orchestration engine
├── volva/      execution-host runtime layer
├── septa/      shared schemas and fixtures
└── docs/       workspace-level notes
```

- **mycelium**: Filters command output before it reaches the model.
- **hyphae**: Stores memories, memoirs, sessions, and indexed documents.
- **cap**: Reads ecosystem data, renders operator views, and brokers explicit write-through actions where the UI needs them.
- **rhizome**: Provides structure-aware code intelligence and export.
- **spore**: Supplies shared discovery, transport, config, and path primitives.
- **stipe**: Handles install, init, update, and doctor flows.
- **cortina**: Captures hook events and writes structured signals.
- **lamella**: Packages shared content for Claude and Codex.
- **canopy**: Tracks task ownership, handoffs, and evidence.
- **annulus**: Renders terminal operator surfaces such as the statusline and related utilities.
- **hymenium**: Orchestrates workflow dispatch, phase gating, and retry/recovery.
- **volva**: Hosts backend orchestration at the runtime seam.

---

## Tool Selection Guide

The ecosystem tools are globally available. Use them instead of native fallbacks
when the task fits:

### Rhizome (code navigation and structural editing)

**Structural reads** — use when you need code intelligence beyond text search:

- `mcp__rhizome__search_symbols`: find all definitions and uses of a symbol
- `mcp__rhizome__find_references`: find all places a symbol is referenced
- `mcp__rhizome__get_definition`: jump to a symbol's definition
- `mcp__rhizome__get_structure`: understand a file's class/function tree
- `mcp__rhizome__summarize_file`: get a high-level overview without reading every line
- `mcp__rhizome__get_call_sites`: see where a function is called
- `mcp__rhizome__analyze_impact`: predict the blast radius of a change
- `mcp__rhizome__get_diagnostics`: check for syntax/type errors

Prefer these over `Grep` when: finding callers or references, navigating definitions, understanding scope and dependencies, or checking impact before refactoring.

**Structural edits** — use for safe, multi-file refactoring:

- `mcp__rhizome__rename_symbol`: rename a symbol across its entire scope
- `mcp__rhizome__move_symbol`: move a symbol to a different file
- `mcp__rhizome__copy_symbol`: duplicate a symbol
- `mcp__rhizome__replace_symbol_body`: rewrite a function's body
- `mcp__rhizome__insert_before_symbol`, `mcp__rhizome__insert_after_symbol`: add code around a symbol
- `mcp__rhizome__insert_at_line`, `mcp__rhizome__replace_lines`, `mcp__rhizome__delete_lines`: surgical line-level edits
- `mcp__rhizome__create_file`: create a new file with proper structure

**What-if analysis**:

- `mcp__rhizome__rhizome_simulate_change`: predict the effect of a change without committing it

**Export**:

- `mcp__rhizome__export_repo_understanding`: generate a code-graph summary for long-term analysis
- `mcp__rhizome__export_to_hyphae`: send code structure to Hyphae for memoir-backed recall

Use `Grep` when searching for a string pattern across files or when the search is purely textual (not structural). Rhizome does not replace text search.

### Hyphae (persistent memory, memoirs, and session management)

**Memory (episodic recall)**:

- `mcp__hyphae__hyphae_memory_recall`: search prior-session decisions, errors, and context
- `mcp__hyphae__hyphae_memory_store`: save a decision, error fix, or learning for later
- `mcp__hyphae__hyphae_memory_consolidate`: merge redundant memories when a topic grows
- `mcp__hyphae__hyphae_memory_invalidate`: mark a memory obsolete
- `mcp__hyphae__hyphae_memory_health`: check storage health and decay status
- `mcp__hyphae__hyphae_memory_stats`: view memory count and topic distribution

Call `mcp__hyphae__hyphae_memory_recall` before starting work in any area you haven't touched in this session if you want prior-session decisions, errors resolved, or relevant context loaded. Call `mcp__hyphae__hyphae_memory_store` after resolving a non-obvious error, making an architecture decision, or discovering a non-obvious constraint. Use topic `"errors/resolved"` for error fixes, `"decisions/{project}"` for architecture choices. Do NOT recall at every step — one recall at the start of a task is usually enough.

**Memoir (structural knowledge graphs)**:

- `mcp__hyphae__hyphae_memoir_create`: start a persistent knowledge graph on system architecture, domain models, or patterns
- `mcp__hyphae__hyphae_memoir_add_concept`: add a named node to a memoir
- `mcp__hyphae__hyphae_memoir_link`: connect concepts with labeled relationships
- `mcp__hyphae__hyphae_memoir_refine`: deepen concept definitions as understanding grows
- `mcp__hyphae__hyphae_memoir_search`: query a memoir by concept or relationship
- `mcp__hyphae__hyphae_memoir_inspect`: explore a memoir's graph structure
- `mcp__hyphae__hyphae_memoir_show`: display a memoir or its concepts

Use memoirs to capture system architecture, recurring patterns, and domain models that persist across sessions.

**Session management**:

- `mcp__hyphae__hyphae_session_start`: open a session context (automatically called; manual invoke rare)
- `mcp__hyphae__hyphae_session_end`: close a session and write its context to storage
- `mcp__hyphae__hyphae_session_context`: retrieve the current session's metadata

**Cross-project and utility functions**:

- `mcp__hyphae__hyphae_recall_global`: search memories across all projects when local recall is empty
- `mcp__hyphae__hyphae_extract_lessons`: extract patterns and lessons from accumulated error fixes and corrections
- `mcp__hyphae__hyphae_artifact_query`, `mcp__hyphae__hyphae_artifact_store`: store and retrieve large structured outputs (code, specs, analysis) for long-term reuse
- `mcp__hyphae__hyphae_gather_context`: assemble ambient context (file, project, user state) for a focused task
- `mcp__hyphae__hyphae_onboard`: initialize Hyphae with your preferences and project baseline
- `mcp__hyphae__hyphae_ingest_file`: bulk-ingest a file or transcript into memory

### Mycelium (command output compression)

You do not invoke mycelium directly. The cortina pre-tool-use hook automatically
pipes verbose Bash command output through mycelium before it reaches the model.
This is active for: git log, cargo test, cargo build, and other high-volume
commands.

If you see compressed/summarized command output, that is mycelium working.
Do not attempt to "undo" the compression — the full output is available via
hyphae chunked storage if needed.

### When to use native tools

- `Read` for reading a specific file when you already know the path
- `Glob` for file discovery by name pattern
- `Grep` for text/regex search across files
- `Bash` for commands not covered by the above

Native tools are fine when the task is bounded. The ecosystem tools add value
for cross-session continuity (hyphae), structural code navigation (rhizome),
and output compression (mycelium/cortina).

---

## Key Design Decisions

- **Mostly independent repositories**: keeps release cadence and ownership per tool clear without forcing every root-level directory to be a standalone repo.
- **Septa directory**: makes cross-project payload changes explicit and testable.
- **Shared version pin file**: keeps common dependencies, especially `spore`, from drifting silently.
- **Project-local commands**: prevents the root from becoming a fake build system that hides real repo boundaries.

---

## Key Files

| File | Purpose |
|------|---------|
| [AGENTS.md](/Users/williamnewton/projects/personal/basidiocarp/AGENTS.md) | Workspace-wide repo guidance, build commands, and Lamella-specific authoring rules |
| [septa/README.md](/Users/williamnewton/projects/personal/basidiocarp/septa/README.md) | Contract ownership, versioning rules, and validation workflow |
| [ecosystem-versions.toml](/Users/williamnewton/projects/personal/basidiocarp/ecosystem-versions.toml) | Shared dependency pins across projects |
| [docs/foundations/README.md](/Users/williamnewton/projects/personal/basidiocarp/docs/foundations/README.md) | Workspace Rust architecture standards, checklist, and audit templates |
| [.audit/external/SYNTHESIS.md](/Users/williamnewton/projects/personal/basidiocarp/.audit/external/SYNTHESIS.md) | Fast entrypoint to the external audit corpus and current ecosystem-level conclusions |
| [.audit/external/AUDITING.md](/Users/williamnewton/projects/personal/basidiocarp/.audit/external/AUDITING.md) | Method for mapping external features into existing repos, `septa`, or true new-tool candidates |
| [ECOSYSTEM-OVERVIEW.md](/Users/williamnewton/projects/personal/basidiocarp/docs/workspace/ECOSYSTEM-OVERVIEW.md) | Thin ecosystem map, repo responsibilities, and cross-tool boundaries |
| [ECOSYSTEM-INTERACTIONS.md](/Users/williamnewton/projects/personal/basidiocarp/docs/workspace/ECOSYSTEM-INTERACTIONS.md) | Lower-level prompt, memory, handoff, operator, and orchestration flows |
| [ECOSYSTEM-REVIEW.md](/Users/williamnewton/projects/personal/basidiocarp/docs/workspace/ECOSYSTEM-REVIEW.md) | Detailed ecosystem state, gap analysis, and near-term review surface |

---

## Communication Contracts

The workspace root does not send or receive runtime payloads. It owns the shared `septa/` directory and the rules for changing those contracts.

- Update the schema and example fixture before changing any cross-tool payload.
- Check downstream consumers before renaming tool names, fields, CLI flags, or SQLite tables.
- Validate all contracts after schema changes: `cd septa && bash validate-all.sh`
- Run `./scripts/test-integration.sh` when a change crosses a project boundary.

---

## Delegation Contract

When the user asks for the implementer/auditor pattern, treat it as a strict workflow, not a loose preference.

Start with one implementation agent on one concrete handoff or child handoff. That agent must stay inside the owning repo, do implementation only, inspect repo state and the named target files before editing, make the code changes, update the handoff when the handoff expects verification evidence, run the repo-local verification named in the handoff, and occasionally report progress back to the parent agent. Orchestration, decomposition, relaunch decisions, dashboard edits, and archive moves stay with the parent agent. Status chatter does not count as progress.

### Two-stage review — required before signoff

Every handoff implementation goes through two review stages before it is committed and marked Done:

**Stage 1 — Code review (after implementation, before committing):**
Run a `code-reviewer` agent against the uncommitted diff. It checks for spec compliance, correctness bugs, regressions in existing behavior, and security issues. Do not commit until Stage 1 findings are resolved. Fix all blockers and concerns before proceeding.

**Stage 2 — Pre-signoff review (after fixes, before marking Done):**
Run a second review agent against the final state. Confirms Stage 1 findings were addressed, checks the complete change holistically, and gives a final PASS or FAIL verdict. Only commit and update the dashboard after Stage 2 passes.

Do not collapse both stages into one agent. Do not run either stage after committing. The sequence is: implement → Stage 1 review → fix → Stage 2 review → commit → mark Done.

If the auditor finds issues, fix them and rerun the relevant verification before treating the work as complete. Close the implementer when implementation is accepted. Close both review agents when Stage 2 passes. Once the review is clean and verification is green, commit, update the handoff dashboard, and archive or remove the entry if the dashboard tracks active work only. Do not leave stalled or completed agents open.

Parallel strict workflows are allowed when they target different concrete handoffs with disjoint write scopes. Parallel implementers for the same handoff, or overlapping ownership inside one repo, are not allowed.

Use this naming convention for strict-workflow agents:

`<role>/<repo>/<handoff-slug>/<run>`

Examples:

- `impl/spore/otel-foundation/1`
- `audit/spore/otel-foundation/1`

If a human nickname is available, keep it secondary:

- `impl/spore/otel-foundation/1 (Dalton)`

Triage strict workflows actively. Check early for a real repo diff. If a lane is still empty, treat it as at risk. If it produces an off-scope diff, close it immediately. Only lanes with an on-scope diff and repo-local verification output should advance to audit. Workflow summaries, relaunch notes, or other meta-status replies without a repo diff count as failure and should be closed immediately.

Do not spawn an implementation agent until the parent has already done a short seam-finding pass. That means the parent has identified the owning repo, the most likely files or modules to change, and the exact repo-local verification commands. If those are still unknown, keep the work local until the seam is concrete enough for a code-only worker.

---

## CI and Release Gates

**CI must be green before committing, releasing, or marking a handoff Done.**

This rule exists because red pipelines have blocked releases. A handoff marked Done with a red pipeline is not done.

### Before every commit

1. Run the repo-local build and test suite inside the subproject being changed.
2. Run clippy (Rust) or lint (TypeScript/Node) and fix all errors.
3. Do not commit if either fails. Fix the failure first.

### Before marking a handoff Done

1. Confirm the repo-local verification commands from the handoff pass.
2. Check CI status for the touched repos: `gh run list --repo <owner>/<repo> --limit 5`
3. If CI is red on main, do not mark Done — investigate and resolve the failure first.

### Before cutting a release

1. All touched repos must have green CI on the branch being released.
2. No open handoffs in the release scope should be marked Done with known failing tests.
3. Confirm with `gh run list` before tagging or publishing.

### Failure mode

If CI is red and you cannot determine why from local output, stop and surface the failure explicitly rather than proceeding. Do not mark work complete to make the dashboard look clean while pipelines are broken.

---

## Testing Strategy

- Use each project's native test command inside that project's directory.
- Treat contract changes as multi-repo work, not local refactors.
- Prefer real fixtures and existing snapshot workflows over synthetic examples.
- Re-run the nearest build, test, and lint commands in every touched subproject.
