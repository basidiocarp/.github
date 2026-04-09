# [Tool] Architecture

<!-- ─────────────────────────────────────────────
     OPENING — Required. Two to three sentences.
     Sentence 1: What the tool is and its structural shape (binary count, crate count).
     Sentence 2: The core mechanism or the key design tension it resolves.
     Sentence 3: What this document covers (optional — skip if obvious).

     Good: "Rhizome is a code intelligence MCP server with a 5-crate workspace design.
            Two backends — tree-sitter and LSP — are selected per tool call.
            This document describes the architecture and data flow."

     Good: "Hyphae is a Rust workspace of 5 crates that compile into a single binary.
            No runtime dependencies, no external services."

     Bad:  "This document describes the architecture of [Tool]."  ← circular
     ──────────────────────────────────────────── -->
[Tool] is [structural shape: X-crate workspace / single-crate binary / frontend + backend]. [Core mechanism or key design tension]. [What this doc covers, if not obvious.]

---

## Design Principles

<!-- Required. Three to six bullets.
     These are the non-obvious values that shaped the design — not generic engineering advice.
     A good test: would these be true of many tools, or specifically this one?
     Each principle should connect to something a contributor could violate.

     Good: "Task-first, not chat-first — explicit ownership and handoff, not freeform discussion"
           "Fail-safe: if filtering fails, fall back to original output unchanged"
           "Evidence-first — all decisions attached to external references, not opinion"
           "Exit code preservation — CI/CD reliability requires propagating original exit codes"

     Bad:  "Write clean code"
           "Keep it simple"
           "Use Rust best practices"
-->

- **[Principle]** — [one clause connecting this value to a specific design consequence]
- **[Principle]** — [consequence]
- **[Principle]** — [consequence]
- **[Principle]** — [consequence]

---

## System Boundary

<!-- Conditional — include when this tool has non-obvious overlap with siblings,
     or when contributors regularly try to put things in the wrong tool.
     Canopy's architecture doc has the best example of this pattern.
     Two formats work: a "what X owns / what Y owns" split, or a flat
     "X owns / X does not own" list. Use whichever makes the boundary clearer.
     Skip for tools with obviously scoped responsibilities (Mycelium, Spore).

     Good (Canopy):
     Canopy owns: agent registry, task ledger, handoff protocol, evidence references
     Hyphae owns: memory, recall logging, outcome signals, session history
     Cortina owns: host adapter lifecycle capture, structured host events

     Good (flat):
     [Tool] owns: [X], [Y], [Z]
     [Tool] does not own: [concern A] (handled by Hyphae), [concern B] (handled by Stipe)
-->

### [Tool] owns

- [Responsibility A]
- [Responsibility B]
- [Responsibility C]

### [Sibling] owns

- [What this sibling is responsible for that might seem like it belongs here]

### [Sibling] owns

- [Same]

---

## Workspace Structure

<!-- Required. Two parts: dependency graph + per-component descriptions.

     DEPENDENCY GRAPH:
     Use ASCII art, not mermaid — it renders everywhere (terminal, GitHub, docs sites).
     Show the actual dependency direction (arrows point from dependent to dependency).
     A flat tree is fine for single-crate projects.

     Good (multi-crate):
     rhizome-cli ──► rhizome-mcp ──► rhizome-treesitter ──► rhizome-core
                          │                                       ▲
                          └──────► rhizome-lsp ──────────────────┘

     Good (single-crate):
     src/
     ├── main.rs       # CLI entry and routing
     ├── filters/      # Per-command output filters
     └── tracking.rs   # Token savings (SQLite)

     PER-COMPONENT DESCRIPTIONS:
     Each entry should state the architectural role — not just rephrase the name.
     Lead with the constraint: "No I/O", "No database dependency", "Pure logic".
     For the core/foundation crate, say what it does NOT contain (prevents confusion).
-->

```
[tool]-cli ──► [tool]-[module] ──► [tool]-core
                   │                    ▲
                   └──► [tool]-[module]─┘
```

All [N] crates compile into a single binary.

- **[tool]-core**: [Domain types, central traits, shared logic. No I/O. No database dependency. What it defines.]
- **[tool]-[module]**: [What this crate implements, what interface it satisfies, key constraint or invariant.]
- **[tool]-[module]**: [Same pattern — role, interface, constraint.]
- **[tool]-cli**: [CLI entry point. Framework used. Commands exposed.]

---

## Core Abstraction

<!-- Conditional — include when a central trait or interface is the load-bearing
     seam of the system. Skip for tools with no such abstraction (Mycelium, Stipe).

     Show the REAL trait signature — abbreviated is fine, but use actual Rust.
     Follow with: what implements it, what consumes it, the key invariant.

     Good (Rhizome):
     pub trait CodeIntelligence {
         fn get_symbols(&self, file: &Path) -> Result<Vec<Symbol>>;
         fn find_references(&self, file: &Path, position: Position) -> Result<Vec<Location>>;
         // ...
     }
     Both tree-sitter and LSP backends implement this interface.
     The tool dispatcher selects which backend to use per call.
-->

```rust
pub trait [TraitName] {
    fn [method](&self, [params]) -> Result<[Return]>;
    fn [method](&self, [params]) -> Result<[Return]>;
    // ...
}
```

[What implements this trait. What consumes it. The key invariant that must hold across all implementations.]

---

## Request Flow

<!-- Required for any tool that handles requests (MCP servers, proxies, HTTP servers).
     This is the most valuable section in the document — and the most consistently missing.

     Format: numbered list, one step per item.
     Each step must name:
     - what happens (the transformation or decision)
     - which function or module is responsible (file::function or StructName.method)
     - at least one concrete example

     Rhizome's "Tool Call Flow: Request to Response" is the gold standard.
     Five to seven steps is the right range. More than that → some steps should merge.

     Good (Rhizome):
     1. Routing (ToolDispatcher.call_tool)
        - Maps tool name to handler
        - Example: get_symbols → symbol_tools::get_symbols()
     2. Backend Selection (BackendSelector.select)
        - Checks tool requirement (RequiresLsp, PrefersLsp, TreeSitter)
     3. Lazy LSP Initialization (ToolDispatcher.ensure_lsp)
        - First LSP call initializes; subsequent calls reuse cached client

     Bad:
     1. The request comes in
     2. It gets processed
     3. A response is returned
     ← No function names, no examples, no useful content.

     For CLI tools (not request-response): trace a command execution instead.
     For libraries: trace a typical caller usage.
-->

When [a request / a tool call / a command] arrives:

1. **[Step name]** (`[Module.function]` or `[file::function]`)
   - [What happens at this step]
   - Example: `[concrete example]`

2. **[Step name]** (`[Module.function]`)
   - [What happens]
   - [Edge case or fallback behavior at this step]

3. **[Step name]** (`[Module.function]`)
   - [What happens]
   - [Lazy init, caching, or retry behavior if applicable]

4. **[Step name]** (`[Module.function]`)
   - [What happens]

5. **[Step name]** (output)
   - [What the caller receives]

---

## [Key Subsystem A]

<!-- Conditional — include a per-subsystem section for each major component that
     has its own non-trivial internal flow. Rhizome has two (tree-sitter backend,
     LSP backend). Hyphae has one (the store). Mycelium has one (filtering pipeline).
     Skip for simple tools where the request flow section is sufficient.

     Format per subsystem:
     1. File reference (where to find it)
     2. "How It Works" — numbered flow, same pattern as the request flow section
     3. Any important tables (capability matrix, fallback behavior, config options)
     4. Extension guide — how to add a new [language / command / handler]

     Name this section after the subsystem, not a generic heading like "Backend".
-->

File: `[crates/tool-crate/src/file.rs]`

### How It Works

1. **[Step]** — [what happens, implementation detail worth knowing]
2. **[Step]** — [what happens]
3. **[Step]** — [what happens, including cache or fallback behavior]
4. **[Step]** — [what the output looks like]

### [Capability or Configuration Matrix]

| [Dimension] | [Options / Examples] | [Behavior] |
|------------|---------------------|------------|
| [Value A]  | [example, example]  | [behavior] |
| [Value B]  | [example]           | [behavior] |
| [Value C]  | [example]           | [error / fallback] |

### Adding a [Language / Command / Handler]

<!-- Keep this short — three to five steps with file references. This is the
     most common extension task and agents should be able to do it without guessing. -->

File: `[path to the relevant file]`

1. [Step with file reference]
2. [Step]
3. [Step]

---

## [Key Subsystem B]

<!-- Same pattern as above. Repeat for each major independent subsystem. -->

---

## Data Model

<!-- Conditional — include for tools that store structured data (Hyphae, Canopy).
     Skip for tools that are stateless or whose data model is trivially obvious.

     Show the REAL Rust structs — abbreviated is fine, but use actual field names and types.
     Include field-level comments for non-obvious fields (decay semantics, unit, constraints).
     For enums, include the behavioral implication of each variant (not just its name).
     For stores, include: schema table count, key invariants, cascade behavior.

     Good (Hyphae Importance enum):
     pub enum Importance {
         Critical,   // decay: 0.0 (never), prune: never
         High,       // decay: 0.5x rate, prune: never
         Medium,     // decay: 1.0x rate, prune: when weight < threshold
         Low,        // decay: 2.0x rate, prune: when weight < threshold
     }
-->

### [Primary Entity]

```rust
pub struct [EntityName] {
    pub [field]: [Type],          // [what it is, unit, constraints]
    pub [field]: [Type],          // [behavioral note if non-obvious]
    pub [field]: [Type],
}
```

### [Secondary Entity / Enum]

```rust
pub enum [EnumName] {
    [Variant],   // [behavioral implication]
    [Variant],   // [behavioral implication]
}
```

### Schema

[N] tables. Key invariants:

- [Constraint or cascade rule — e.g., "DELETE memoir cascades to concepts and links"]
- [Uniqueness constraint — e.g., "concept name unique within memoir (not globally)"]
- [Index strategy — e.g., "FTS5 virtual table on topic + summary for keyword search"]

---

## Configuration

<!-- Required if the tool has a config file or meaningful env var surface.
     Show the actual config file path and a real annotated example.
     Include the merge order if global + project configs are both supported.
     List env var overrides separately — they're often forgotten.
-->

Config file: `~/.config/[tool]/config.toml`
<!-- If project-level config exists: -->
Project override: `<project_root>/.[tool]/config.toml` (overrides global)

```toml
[section]
key = "value"   # [what it controls, valid values]

[[section.subsection]]
key = "value"   # [behavioral note]
```

Environment variables override config:
- `[TOOL_VAR]` — [what it overrides, when to use it]
- `[TOOL_VAR]` — [what it overrides]

---

## Error Handling

<!-- Conditional — include when the tool has a meaningful error surface with
     actionable user responses. Rhizome's error table is the gold standard.
     Format: error message → root cause → what the user should do.
     Skip for internal libraries where errors propagate to the caller.

     Good (Rhizome):
     | "LSP server not found: rust-analyzer" | Binary not in PATH | Install manually: rustup component add rust-analyzer |
     | "LSP auto-install disabled"           | Env var set        | Unset RHIZOME_DISABLE_LSP_DOWNLOAD or install manually |
-->

| Error | Cause | User Action |
|-------|-------|-------------|
| `"[error message]"` | [root cause] | [concrete remediation step] |
| `"[error message]"` | [root cause] | [concrete remediation step] |

---

## Security

<!-- Conditional — include for tools that store user data, handle credentials,
     or expose network surfaces. Skip for stateless tools and pure libraries.
     Hyphae's security section is the model.
     Cover: input sanitization, SQL injection prevention, network exposure,
     data locality, tested attack vectors.
-->

- [Input sanitization approach — e.g., "FTS5 queries sanitized: special chars stripped, tokens quoted"]
- [SQL safety — e.g., "All queries use parameterized statements, no string interpolation"]
- [Network exposure — e.g., "No network access for storage operations (local SQLite only)"]
- [Data locality — e.g., "Embedding model runs locally, no API calls unless configured"]
- Tested against: [SQL injection, null bytes, unicode boundaries, large payloads, etc.]

---

## Testing

<!-- Required. Use Hyphae's category breakdown as the model — it's far more useful
     than "we have unit tests and integration tests."
     Include: category name, count (approximate is fine), what's actually tested.
     Call out non-obvious test infrastructure (real fixtures vs synthetic, ignore flags,
     snapshot review workflow).
-->

```bash
cargo test --all           # Run all tests
cargo test -p [crate]      # Single crate
cargo test --ignored       # Integration tests (requires [installed binary / running service])
```

| Category | Count | What's Tested |
|----------|-------|---------------|
| Unit | ~[N] | [core behavior: CRUD, parsing, filtering, schema migrations] |
| Integration | ~[N] | [end-to-end flows: MCP dispatch, store+recall roundtrip, CLI output] |
| [Security / Edge cases] | ~[N] | [injection, null bytes, unicode, large inputs, empty states] |
| Performance | [N] | [[N] operations at [threshold]ms — stores, searches, exports] |

Fixtures live in `[tests/fixtures/]`. [Real output or synthetic? How to update them?]

---

## Key Dependencies

<!-- Required. Simple annotated bullet list.
     Only include dependencies a contributor would actually need to know about —
     the ones that constrain design choices or have non-obvious behavior.
     Skip trivial ones (serde, anyhow) unless there's a specific reason to call them out.
-->

- **[dep]** — [why it matters, what it enables, any key constraint]
- **[dep]** — [why it matters]
- **[dep]** — [why it matters — e.g., "used for async LSP clients; block_on() bridge for sync callers"]
- **spore** — shared IPC primitives. Pin must stay in sync with `../ecosystem-versions.toml`.
