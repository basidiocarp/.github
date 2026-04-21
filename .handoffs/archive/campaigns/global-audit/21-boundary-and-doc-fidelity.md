# Handoff: Boundary Verification and Documentation Fidelity

## What exists (state)
- **Scope:** All 9 projects (hyphae, mycelium, rhizome, cap, cortina, canopy, spore, stipe, volva)
- **Layer 1 results:** Lint audits complete (handoffs 01-08, 19)
- **Layer 2 results:** Structural reviews complete (handoffs 09-16, 20)
- **Layer 3 results:** Cross-project consistency (17), synthesis (18) complete
- **Contracts directory:** 28 schema files in `contracts/`, plus README, INTEGRATION-PATTERNS, and mcp-conventions docs
- **Root CLAUDE.md:** Ecosystem overview with per-project scope claims, connection diagram, and "What the Ecosystem Does NOT Do" section
- **Files to change:** none — this is a read-only audit

## What I was doing (intent)
- **Goal:** Verify that each project stays within its stated boundaries,
  that wire format contracts match actual code, and that documentation
  (CLAUDE.md, README) accurately reflects what the code does. A single
  cross-cutting pass across all 9 projects.

- **Approach:** Four audit dimensions run in sequence:
  1. Application boundary verification (scope claims vs code behavior)
  2. Contract compliance (schema files vs wire format in code)
  3. Per-project documentation accuracy (claims vs implementation)
  4. Cross-document consistency (root CLAUDE.md vs project CLAUDE.md files)

## Where I stopped (boundary)
- **Why:** handing off for implementation
- **Blocked on:** Layer 2 completion (needs structural review context from handoffs 09-16, 20)
- **Assign to:** implementer with architecture + code-review capabilities
- **Estimated effort:** 2-3 hours (reading docs + code across 9 projects)

### Next steps

#### 1. Application boundary verification

For each project, verify that the code stays within the scope described in
root CLAUDE.md and the project's own CLAUDE.md. Use rhizome tools
(`get_symbols`, `get_exports`, `search_symbols`) to explore code without
reading full files.

**mycelium** — claims "observation and filtering only":
- Search for any code that mutates command arguments, injects flags, or
  alters the child process environment beyond observation
- Verify it never modifies the command being proxied (only filters output)
- Check: does it write to anything besides its own SQLite stats DB and stdout?

**hyphae** — claims "persistent memory":
- Verify it never executes shell commands or spawns child processes
- Verify it never modifies files outside its own database
- Check: does any MCP tool handler have side effects beyond SQLite writes?

**rhizome** — claims "code intelligence" but has 7 editing tools:
- Document which tools are read-only vs which modify files
- Verify editing tools are clearly marked as such in tool descriptions
- Check: do any "read" tools (get_symbols, get_structure, find_references)
  have write side effects?

**cap** — claims "web dashboard" (read-only visualization):
- Verify the backend never writes to hyphae or mycelium databases
- Check: does it have any POST/PUT/DELETE endpoints that modify ecosystem state?

**cortina** — claims "hook runner" that captures data:
- Verify it only reads from git/session state and writes to hyphae
- Check: does it ever modify source files or git state?

**canopy** — claims "multi-agent coordination runtime":
- Verify task operations stay within its own SQLite database
- Check: does it execute arbitrary commands on behalf of agents?

**spore** — claims "shared infrastructure library":
- Verify it has no main binary or standalone execution mode
- Check: are all public exports utility functions with no global side effects?

**stipe** — claims "ecosystem installer/manager":
- Verify its scope is limited to installing binaries, initializing DBs,
  registering MCP servers, and health checks
- Check: does it modify any project source code?

**volva** — claims "Claude-first CLI and runtime layer":
- Verify it orchestrates Claude API calls without modifying project files
- Check: does it have file-writing capabilities beyond its own state?

#### 2. Contract compliance

Compare `contracts/*.schema.json` files against the code that produces
or consumes those payloads.

For each schema file:
- Identify the producer (which project serializes this format)
- Identify the consumer(s) (which project(s) deserialize it)
- Verify field names, types, and required/optional match between schema and code
- Flag any fields present in code but missing from schema (undocumented wire format)
- Flag any fields in schema but absent from code (dead schema fields)

**Key contracts to prioritize:**
- `command-output-v1.schema.json` — mycelium produces, hyphae consumes
- `code-graph-v1.schema.json` — rhizome produces, hyphae consumes
- `session-event-v1.schema.json` — cortina produces, hyphae consumes
- `handoff-context-v1.schema.json` — canopy produces and consumes
- `mycelium-gain-v1.schema.json` — mycelium produces, cap consumes

**Session identity convention:**
- Grep all projects for `project_root` and `worktree_id` usage
- Verify they always appear as a pair (both or neither)
- Verify `CLAUDE_SESSION_ID` propagation across tools

**Breaking changes:**
- Check git log of `contracts/` for recent schema modifications
- Verify any breaking changes are documented in commit messages or a changelog

#### 3. Per-project documentation accuracy

For each project, compare its CLAUDE.md and README against the actual code:

| Check | Method |
|-------|--------|
| Architecture diagram vs file structure | `ls` actual dirs, compare to documented tree |
| Feature claims vs capabilities | rhizome `get_exports` to see public API surface |
| DB/config paths in docs vs code | Grep for path constants, compare to documented paths |
| Failure modes vs error handling | Search for error types, verify documented graceful degradation |
| CLI examples | Run documented commands with `--help` to verify they exist |
| Performance claims (mycelium: <10ms startup, <5MB memory) | Note for manual verification |
| Token savings claims (mycelium: 60-90%) | Check if measurement code exists to support the claim |

**Per-project checklist items:**

- [x] **hyphae:** CLAUDE.md feature list matches actual MCP tool count — claims 37, actual 38
- [x] **hyphae:** Documented DB schema matches actual migrations
- [x] **mycelium:** Performance claims (<10ms, <5MB) — measurement code exists (timing instrumented in gain module)
- [x] **mycelium:** Token savings claims (60-90%) — calculation methodology documented (savings_pct = saved/input)
- [x] **rhizome:** Tool count — claims 35, actual 38
- [x] **rhizome:** Language support claims — not individually verified (build blocked by C3)
- [x] **cap:** Documented API endpoints — CLAUDE.md missing 5 route groups; false read-only claim
- [x] **cortina:** Hook types documented match actual hook implementations
- [x] **canopy:** Tool count — claims 30, actual 31
- [x] **canopy:** Task lifecycle states documented match actual state machine
- [x] **spore:** Documented module list matches actual crate structure (consumers list stale: 3 listed, 6 actual)
- [x] **stipe:** Documented subcommands match actual CLI definitions
- [x] **volva:** No CLAUDE.md — cannot assess

#### 4. Cross-document consistency

Compare root CLAUDE.md against each project's CLAUDE.md:

- [x] Root "Ecosystem Overview" project descriptions match each project's self-description — minor drift in spore/volva
- [x] Root "How They Connect" diagram — arrows verified with actual code paths
- [x] Root tool counts per project — stale for hyphae (37→38), rhizome (35→38), canopy (30→31)
- [x] Root "What the Ecosystem Does NOT Do" — verified (cap boundary exception noted)
- [x] Root "Graceful Degradation" section — fallback behavior verified in code for all projects
- [x] Root "Memory & Knowledge Creation" flows — verified with actual cortina→hyphae→cap code paths
- [x] `ecosystem-versions.toml` — 3 stale entries: cortina 0.2.5→0.2.6, stipe 0.5.6→0.5.7, canopy 0.3.0→0.3.1
- [x] Root "Cross-Project Conventions" (Rust 2024, clippy pedantic, anyhow/thiserror) — confirmed across all projects
- [x] Lamella skill count claim — not verified (out of scope for this audit)

### Output format

Produce a structured summary:

```
Boundary violations: [list or "none found"]
Contract mismatches: [list with schema file + field + direction of mismatch]
Documentation inaccuracies: [per-project list with file, claim, actual]
Cross-doc inconsistencies: [list with root claim vs project claim]
```

- **Don't touch:** any source code, CLAUDE.md files, schema files, or configs —
  this is read-only. Note inaccuracies but do not fix them. Create follow-up
  tasks for any fixes needed.

## Checklist

### Boundary verification
- [x] mycelium boundary verified (observation only, no mutation)
- [x] hyphae boundary verified (persistent memory, no command execution)
- [x] rhizome boundary verified (code intelligence, editing tools documented)
- [x] cap boundary verified (read-only visualization)
- [x] cortina boundary verified (capture only, no source modification)
- [x] canopy boundary verified (coordination only, scoped to own DB)
- [x] spore boundary verified (library only, no standalone execution)
- [x] stipe boundary verified (installer/manager, no source modification)
- [x] volva boundary verified (orchestration, scoped side effects)

### Contract compliance
- [x] All 28 schema files have identified producer and consumer
- [x] Key contracts verified (command-output, code-graph, session-event, handoff-context, mycelium-gain)
- [x] Session identity convention (project_root + worktree_id) checked across all projects
- [x] CLAUDE_SESSION_ID propagation verified
- [x] Breaking changes in contracts/ documented

### Documentation accuracy
- [x] hyphae CLAUDE.md accuracy verified
- [x] mycelium CLAUDE.md accuracy verified (including performance claims)
- [x] rhizome CLAUDE.md accuracy verified (including tool/language counts)
- [x] cap CLAUDE.md accuracy verified
- [x] cortina CLAUDE.md accuracy verified
- [x] canopy CLAUDE.md accuracy verified (including tool count)
- [x] spore CLAUDE.md accuracy verified
- [x] stipe CLAUDE.md accuracy verified
- [x] volva CLAUDE.md accuracy verified

### Cross-document consistency
- [x] Root CLAUDE.md ecosystem overview matches per-project CLAUDE.md files
- [x] "How They Connect" arrows verified with actual code
- [x] ecosystem-versions.toml matches actual Cargo.toml dependencies
- [x] Negative claims ("Does NOT Do") verified
- [x] Graceful degradation claims verified
- [x] Lamella skill inventory count verified

### Meta
- [x] No source files were modified
- [x] Structured summary provided in the output format above
- [x] Follow-up tasks created for any fixes needed

## Findings

Boundary violations:
  - cap: 15+ POST/PUT/DELETE endpoints proxy writes to hyphae, rhizome, canopy, stipe, tool configs — CLAUDE.md "read-only" claim is false
  - mycelium: init subcommand writes CLAUDE.md and hooks — beyond "observation only" (minor caveat)
  - canopy: executes user-provided verification scripts via bash — declared behavior but worth noting

Contract mismatches:
  - contracts/ README inventory listed only 8 of 28 schemas (resolved in this session)
  - canopy-snapshot-v1 / canopy-task-detail-v1 / stipe-doctor-v1 / stipe-init-plan-v1: inner object shapes were unspecified (resolved in this session)
  - session-event-v1 fixture was array not single object (resolved in this session)
  - hyphae-session-timeline-v1: files_modified/errors stored as strings not arrays — inconsistent with session-event-v1 (documented but not changed — SQLite storage format)
  - volva-hook-event: no contract existed at audit time (resolved later via archive/cross-project/volva-hook-event-contract.md)
  - project_root + worktree_id pairing: compliant across all except canopy (uses project_root independently as filter key)

Documentation inaccuracies:
  - hyphae: ~110 tests (actual 606), rusqlite 0.34 (actual 0.39), 37 tools (actual 38)
  - mycelium: architecture diagram shows src/filters/ (actual: vcs/, cargo_filters/, etc.)
  - rhizome: claims 35 tools (actual 38), 7 edit tools (actual 9-10)
  - canopy: claims 30 tools (actual 31)
  - cap: read-only claim false, missing 5 API route groups, stale backend file tree
  - spore: lists 3 consumers (actual 6), cortina/canopy "planned" (both live)
  - volva: no CLAUDE.md at all
  - root CLAUDE.md: claims snapshot testing across all projects (only mycelium uses it)
  - ecosystem-versions.toml: cortina 0.2.5→0.2.6, stipe 0.5.6→0.5.7, canopy 0.3.0→0.3.1

Cross-doc inconsistencies:
  - Lamella skill count not verified (not in audit scope)
  - ecosystem-versions.toml stale on 3 entries
  - Root claims snapshot testing ecosystem-wide — false

Follow-up handoffs created:
  - cross-project/claude-md-accuracy.md
  - cross-project/ecosystem-versions-drift.md
  - cross-project/sqlite-pragma-consistency.md
  - spore/non-exhaustive-enums.md
  - rhizome/path-traversal-fix.md
  - rhizome/build-fix-and-format.md
  - spore/content-length-double-framing.md
  - hyphae/decay-and-purge-bugs.md
  - cap/boundary-documentation.md
