# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

<!-- ─────────────────────────────────────────────
     SECTION: Project
     Required. Three sentences max.
     Sentence 1: What the tool is and its core mechanism.
     Sentence 2: Key technical characteristics (binary count, dependency model, protocol).
     Sentence 3: How it fits in the ecosystem / what it owns vs. defers.

     Good: "Hyphae is a persistent memory system for AI coding agents. Single binary,
            zero runtime dependencies, MCP-native. Two complementary memory models:
            episodic memories (temporal, decay-based) and semantic memoirs (permanent
            knowledge graphs)."

     Bad:  "This project provides various features to help AI coding agents work better
            in a number of useful ways."
     ──────────────────────────────────────────── -->
## Project

[Tool] is [what it is and its core mechanism]. [Key technical characteristics: binary count,
dependency model, language, protocol]. [Ecosystem role: what it owns, what it defers to siblings].

---

<!-- ─────────────────────────────────────────────
     SECTION: What [Tool] Does NOT Do
     Required. Four to six bullets.
     These bound the agent's mental model before it starts working.
     Each bullet should address a plausible wrong assumption.
     Frame as behavior, not features: "does not X" not "no X support".

     Good: "Does not modify command behavior (observation and filtering only)"
           "Does not auto-delete memories (decay affects recall ranking, not deletion)"
           "Does not write to Hyphae or Mycelium databases (read-only access)"

     Bad:  "Does not have a GUI"  ← nobody would assume this
           "Does not support X yet"  ← "yet" implies roadmap intent, use ROADMAP.md
     ──────────────────────────────────────────── -->
## What [Tool] Does NOT Do

- Does not [plausible wrong assumption #1] ([clarifying parenthetical])
- Does not [plausible wrong assumption #2] ([clarifying parenthetical])
- Does not [plausible wrong assumption #3] ([clarifying parenthetical])
- Does not [plausible wrong assumption #4] ([clarifying parenthetical])

---

<!-- ─────────────────────────────────────────────
     SECTION: Failure Modes
     Required unless the tool has no meaningful failure surface (e.g., a pure library
     that panics at the call site on error).
     Format: **Trigger**: What actually happens, and whether it degrades gracefully.
     Cover the top four to six real failure paths — not exhaustive, not hypothetical.
     Explicitly call out graceful degradation vs. hard failure.

     Good: "**Hyphae unavailable**: Falls back to local filtering (no chunked storage)"
           "**LSP server unavailable**: Falls back to tree-sitter (reduced features, clear error)"
           "**SQLite locked**: Retry with exponential backoff up to 5 seconds, then fail with clear error"

     Bad:  "**Error**: Returns an error"  ← useless
           "**Network failure**: May fail"  ← too vague
     ──────────────────────────────────────────── -->
## Failure Modes

- **[Dependency or subsystem unavailable]**: [what happens — falls back to X / logs warning / fails with clear error]
- **[Bad input or missing config]**: [what happens]
- **[Resource contention or I/O failure]**: [what happens]
- **[Auth or permission failure]**: [what happens]

---

<!-- ─────────────────────────────────────────────
     SECTION: State Locations
     Required if the tool writes any persistent state.
     Skip if stateless (note that in the "Does NOT Do" section instead).
     Use a table. Include env var overrides in the Description column.
     Platform-specific paths should use the generic form (~/ not /Users/name/).

     Good:
     | Token stats database | `~/.local/share/mycelium/mycelium.db` |
     | Config file          | `~/.config/mycelium/config.toml`       |

     Bad:
     | Database | /home/will/.local/share/mycelium/mycelium.db |  ← hardcoded user path
     | Logs     | (various)                                     |  ← too vague
     ──────────────────────────────────────────── -->
## State Locations

| What | Path |
|------|------|
| [Primary database or store] | `~/.local/share/[tool]/[tool].db` (or `[ENV_VAR]` env) |
| [Config file] | `~/.config/[tool]/config.toml` (or `[ENV_VAR]` env) |
| [Cache or runtime artifacts] | `~/.cache/[tool]/` |
| [Log output] | stderr ([level via `[ENV_VAR]` env]) |

---

<!-- ─────────────────────────────────────────────
     SECTION: Build & Test Commands
     Required. Code block only — no prose around it.
     Inline comments explain non-obvious flags.
     Include: build, local install, test (all + targeted), lint, format, snapshot review.
     For multi-crate workspaces, include per-crate test commands.
     For JS/TS projects, include dev, build, preview, lint.

     Good: commands with aligned inline comments, real flags, non-obvious variants called out
     Bad:  "cargo build  # build the project"  ← redundant comment
           Missing: snapshot review, integration test flag, no-default-features variant
     ──────────────────────────────────────────── -->
## Build & Test Commands

```bash
# [Language: Rust]
cargo build --release                        # Optimized build
cargo build --release --no-default-features  # Without [optional feature] (faster iteration)
cargo install --path .                       # Install binary locally

cargo test                                   # All tests
cargo test -p [crate-name]                   # Single crate tests
cargo test [test_name]                       # Single test by name
cargo test --ignored                         # Integration tests (requires installed binary)

cargo clippy                                 # Lint (CI uses -D warnings)
cargo fmt --check                            # Format check
cargo fmt                                    # Auto-format

cargo insta review                           # Review snapshot test changes
cargo insta accept                           # Accept all pending snapshots
```

```bash
# [Language: JS/TS — use instead of Rust block above]
npm run dev           # Frontend only
npm run dev:server    # Backend only
npm run dev:all       # Both concurrently

npm run build         # Production build
npm run preview       # Preview production build
npm run lint          # Lint + auto-fix
npm test              # Run test suite
```

---

<!-- ─────────────────────────────────────────────
     SECTION: Architecture
     Required.
     For multi-crate workspaces: dependency tree diagram + per-crate description table or bullets.
     For single-crate projects: module tree with purpose annotations.
     For frontend+backend: separate blocks per layer + a data flow description.
     Descriptions should state the architectural role, not just rephrase the name.

     Good (multi-crate):
     ```
     rhizome-cli ──► rhizome-mcp ──► rhizome-treesitter ──► rhizome-core
                          │                                       ▲
                          └──────► rhizome-lsp ──────────────────┘
     ```
     - **rhizome-core**: Domain types, `CodeIntelligence` trait, backend selector. No I/O.
     - **rhizome-mcp**: 35 MCP tool handlers. Routes calls, auto-selects backend.

     Good (single-crate):
     ```
     src/
     ├── main.rs       # CLI entry point and command routing
     ├── filters/      # Per-command output filter implementations
     │   ├── git.rs    # git log, status, diff, show, branch
     │   └── cargo.rs  # cargo build, test, clippy, check
     └── gain.rs       # Token savings tracking (SQLite)
     ```

     Bad:
     ```
     src/
     ├── main.rs
     ├── lib.rs
     └── utils.rs
     ```
     ← No annotations, no architectural signal.
     ──────────────────────────────────────────── -->
## Architecture

<!-- Option A: Multi-crate workspace -->
```
[tool]-cli ──► [tool]-[module] ──► [tool]-core    (types, traits — no I/O)
                   │                    ▲
                   └──► [tool]-[module]─┘
```

- **[tool]-core**: [Domain types, central traits, shared logic. No I/O. What it defines.]
- **[tool]-[module]**: [What this crate implements, what interface it satisfies, key dependencies.]
- **[tool]-[module]**: [Same pattern.]
- **[tool]-cli**: [CLI entry point. Clap-based. What commands it exposes.]

<!-- Option B: Single-crate module tree -->
```
src/
├── main.rs              # [CLI entry point and routing]
├── [module]/            # [What this module family does]
│   ├── [file].rs        # [Specific responsibility]
│   └── [file].rs        # [Specific responsibility]
├── [module].rs          # [Responsibility]
└── [module].rs          # [Responsibility]
```

<!-- Option C: Frontend + backend (use both blocks) -->
```
src/                          # Frontend (React/TypeScript)
├── main.tsx                  # [Entry point, providers]
├── App.tsx                   # [Route config]
├── pages/
│   └── [Page].tsx            # [What this page shows]
└── lib/
    ├── api.ts                # [Typed API client]
    └── queries.ts            # [TanStack Query hooks]
```

```
server/                       # Backend ([framework])
├── index.ts                  # [App factory, middleware, shutdown]
├── db.ts                     # [Database connection and mode]
├── [module].ts               # [What this module handles]
└── routes/
    └── [route].ts            # [Route family and what it exposes]
```

**Data flow**: [One or two sentences tracing the path from request to data to response. Call out protocol boundaries — e.g., "frontend proxies /api/* to the backend via Vite dev proxy; backend reads Hyphae's SQLite DB directly in read-only mode; write operations shell out to the hyphae CLI."]

---

<!-- ─────────────────────────────────────────────
     SECTION: Core Abstraction
     Conditional — include when there is a meaningful central trait, interface, or type
     that a contributor must understand to work in the codebase.
     Show the actual code — abbreviated is fine, but use the real type signatures.
     Follow with a plain-English description of the contract.
     Skip for tools with no central abstraction (installers, dashboards, libraries
     with many small utilities).

     Good: CodeIntelligence trait in Rhizome, MemoryStore in Hyphae.
     Bad:  A utility function or a config struct — not worth highlighting here.
     ──────────────────────────────────────────── -->
## Core Abstraction

<!-- [If Rust] -->
```rust
pub trait [TraitName] {
    fn [method](&self, [params]) -> Result<[Return]>;
    fn [method](&self, [params]) -> Result<[Return]>;
    // ...
}
```

[What this trait represents. What implements it. What consumes it. What the key invariant is — e.g., "Both tree-sitter and LSP backends implement this interface. The tool dispatcher selects which backend to use per call."]

---

<!-- ─────────────────────────────────────────────
     SECTION: Key Design Decisions
     Conditional — include when there are non-obvious architectural choices that
     a contributor might question or accidentally undo.
     Each entry: the decision + one-clause rationale.
     Not a changelog — only include decisions that are permanent and load-bearing.

     Good: "**SQLite** for token savings tracking — bundled, zero-dep, sufficient for local use"
           "**Release profile**: LTO, single codegen unit, stripped symbols for <5MB binary"
           "**Snapshot tests** as primary strategy — filter output is volatile, snapshots catch regressions"

     Bad:  "**Rust** — chosen for performance"  ← too obvious to call out
           "**React** — used for the frontend"  ← redundant with the architecture section
     ──────────────────────────────────────────── -->
## Key Design Decisions

- **[Decision]** — [one-clause rationale: why this choice, what it prevents or enables]
- **[Decision]** — [rationale]
- **[Decision]** — [rationale]

---

<!-- ─────────────────────────────────────────────
     SECTION: Key Files
     Conditional — include for larger codebases (5+ crates or complex module structure)
     where knowing which file owns a concern saves significant grep time.
     Use a table: file path → purpose.
     Only include files where the name does not already make the purpose obvious.
     Skip for small single-crate projects.

     Good: rhizome's key files table mapping backend_selector.rs, installer.rs, etc.
     Bad:  Listing every .rs file in the project.
     ──────────────────────────────────────────── -->
## Key Files

| File | Purpose |
|------|---------|
| `[path/to/file.rs]` | [What concern this file owns] |
| `[path/to/file.rs]` | [What concern this file owns] |
| `[path/to/file.rs]` | [What concern this file owns] |

---

<!-- ─────────────────────────────────────────────
     SECTION: Environment Variables / Configuration
     Conditional — include if the tool has meaningful runtime configuration via
     env vars or a config file. Skip for tools with no meaningful knobs.
     Use a table: variable → default → description.
     Group by concern if there are more than six variables.

     Good: Cortina's policy table (CORTINA_DEDUPE_WINDOW_MS etc.)
           Cap's env table split into Network, Tools, Logging groups.

     Bad:  Prose listing env vars inline.
           Listing variables that have obvious names and defaults.
     ──────────────────────────────────────────── -->
## Configuration

Config file: `~/.config/[tool]/config.toml` (override with `[ENV_VAR]` env).

| Variable | Default | Description |
|----------|---------|-------------|
| `[VAR_NAME]` | `[default]` | [What it controls] |
| `[VAR_NAME]` | `[default]` | [What it controls] |

---

<!-- ─────────────────────────────────────────────
     SECTION: Communication Contracts
     Required for any tool that sends or receives structured data to/from ecosystem siblings.
     This is the most consistently underspecified section in the weaker CLAUDE.md files.
     Split into three subsections: Outbound, Inbound, Shared Dependencies.

     For each contract, you need five things:
     1. Contract name    — the versioned identifier (e.g., command-output-v1)
     2. Target/source    — which tool produces or consumes it
     3. Protocol         — MCP tool call, CLI shell-out, HTTP, direct SQLite read, etc.
     4. Schema ref       — the file in septa/ that defines the shape
     5. Breaking change  — one sentence on what fails if you change this without updating the consumer

     Source files: call out the specific function or module that sends/receives each contract.
     This lets a contributor jump straight to the right place.

     Good (Mycelium outbound):
     | command-output-v1 | Hyphae | MCP tool hyphae_store_command_output (JSON-RPC over stdio) | septa/command-output-v1.schema.json |
     Source: src/hyphae_client.rs (builds request), src/hyphae.rs (routing decision)
     Breaking: Hyphae fails on chunked storage; Mycelium falls back to local filtering but stored chunks become unparseable.

     Bad: "Sends data to Hyphae."  ← no protocol, no schema, no source, no break description.

     For library crates (Spore), use a Provides table instead:
     | Module | Consumers | Impact of Breaking Change |
     ──────────────────────────────────────────── -->
## Communication Contracts

<!-- Standard tool: use inbound/outbound split -->
### Outbound (this project sends)

| Contract | Target | Protocol | Schema |
|----------|--------|----------|--------|
| `[contract-name-v1]` | [Target tool] | [MCP tool `tool_name` / CLI `cmd` / HTTP] | `septa/[contract-name-v1].schema.json` |

**Source files:**
- `[path/to/file.rs]` — `[function_name()]` — [what it does with this contract]

Breaking change impact: [What fails in the downstream consumer if you change this payload. Be specific.]

### Inbound (this project receives)

| Contract | Source | Protocol | Schema |
|----------|--------|----------|--------|
| `[contract-name-v1]` | [Source tool] | [MCP tool / CLI / HTTP / direct SQLite] | `septa/[contract-name-v1].schema.json` |

**Receiver source files:**
- `[path/to/file.rs]` — `[function_name()]` — [where this contract is parsed/consumed]

### Shared Dependencies

- **spore**: check `../ecosystem-versions.toml` before upgrading. Pin must stay in sync across all consumers.
- **[Other pinned dep]**: [why it matters, what breaks if it drifts]
- **[Wire format detail]**: [e.g., "JSON-RPC framing: line-delimited, not Content-Length"]

<!-- For library crates (Spore pattern): replace inbound/outbound with a Provides table -->
<!-- ### Provides (used by other projects)

| Module | Consumers | Impact of Breaking Change |
|--------|-----------|--------------------------|
| `[module]` | [Consumer tools] | [What breaks] |

### Version Policy

[How consumers should pin this library. What the upgrade process looks like.] -->

---

<!-- ─────────────────────────────────────────────
     SECTION: Feature Flags
     Conditional — include only for Rust projects with non-obvious feature gates
     that affect binary size, build time, or runtime behavior.
     Skip for tools with no feature flags or only internal-use flags.

     Good: Hyphae's `embeddings` flag — adds ~2GB to debug build, changes search behavior.
     Bad:  Listing flags the consumer never needs to know about.
     ──────────────────────────────────────────── -->
## Feature Flags

- `[feature-name]` (default: [on/off]): [What it enables, compile cost, when to disable it].
- `[feature-name]` (default: [on/off]): [What it enables].

---

<!-- ─────────────────────────────────────────────
     SECTION: Performance Targets
     Conditional — include only if you have real measured numbers.
     Skip if you're writing targets without benchmarks to back them up.
     A table works well here.
     ──────────────────────────────────────────── -->
## Performance Targets

| Metric | Target |
|--------|--------|
| [Startup time] | [<Xms] |
| [Operation latency] | [<Xµs] |
| [Binary size] | [<XMB] |
| [Memory usage] | [<XMB] |

---

<!-- ─────────────────────────────────────────────
     SECTION: Testing Strategy
     Required. Brief — three to six bullets.
     State the primary strategy, what fixtures look like, and the integration test model.
     Call out any non-obvious test patterns (snapshot tests, ignore flags, real fixtures vs synthetic).

     Good: "Snapshot tests (insta) are the primary strategy for filter output validation."
           "Integration tests marked #[ignore] require the installed binary."
           "Fixtures in tests/fixtures/ use real command output, not synthetic data."

     Bad:  "Tests are important and we have them."
     ──────────────────────────────────────────── -->
## Testing Strategy

- **[Primary strategy]** — [what it covers and why it's the right tool]
- **[Secondary strategy]** — [scope and how to run it]
- **Integration tests** — marked `#[ignore]`, run with `cargo test --ignored`. Require [installed binary / running service / etc.].
- **Fixtures** — [real output vs synthetic, where they live, how to update them]
- **[Any non-obvious pattern]** — [e.g., snapshot review workflow, accuracy thresholds]
