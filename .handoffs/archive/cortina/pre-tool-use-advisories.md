# Cortina PreToolUse Advisories

## Problem

Two cortina PreToolUse advisory rules are unimplemented: redirect `Read` on large
code files to rhizome `get_symbols`/`get_structure`, and redirect `Grep` with
symbol-like patterns to rhizome `search_symbols`/`find_references`. The advisory
model (original tool still runs; a hint goes to stderr so the agent learns the
pattern) is designed but not wired. This is gap #4 in the ecosystem gap analysis
and represents the highest-leverage token reduction not yet implemented — estimated
70-90% additional reduction on top of mycelium's existing savings.

## What exists (state)

- **PreToolUse hook:** `cortina/src/hooks/pre_tool_use.rs` — already handles bash rewrites
- **Global rule:** `~/.claude/rules/common/tool-preferences.md` — exists but agents ignore it
- **mycelium PreToolUse:** rewrites shell commands; does NOT intercept Read/Grep MCP calls
- **Cortina receives:** Read and Grep as tool events via `adapters/claude_code.rs`
- **Coverage gap table in IMPROVEMENTS-TOOLS.md:** `Read tool: large_file.rs → raw read → nothing`

## What needs doing (intent)

Add two advisory rules to cortina's Claude Code adapter: when it sees a Read or
Grep tool call matching specific patterns, emit a stderr advisory suggesting the
rhizome equivalent. The original tool still executes — this is advisory only.

---

### Step 1: Add Read advisory for large code files

**Project:** `cortina/`
**Effort:** 1-2 hours

In `pre_tool_use.rs` (or the Claude Code adapter), when cortina receives a `Read`
tool event where:
1. The file has a code extension (`.rs`, `.ts`, `.js`, `.py`, `.go`, etc.)
2. Rhizome is available (check via spore discovery)

Emit an advisory to stderr:
```
[cortina] Large code file — consider: mcp__rhizome__get_symbols for structure or mcp__rhizome__get_symbol_body for a specific function
```

Do NOT block the Read. The file still reads. This is a learning signal only.

#### Files to modify

**`cortina/src/hooks/pre_tool_use.rs`** or **`cortina/src/adapters/claude_code.rs`** — add Read advisory logic.

#### Verification

```bash
cd cortina && cargo test advisory 2>&1
```

**Output:**
<!-- PASTE START -->
    Finished `test` profile [unoptimized + debuginfo] target(s) in 1.73s
     Running unittests src/main.rs (target/debug/deps/cortina-d2bee19604b8741e)

running 6 tests
test hooks::pre_tool_use::tests::advisory_rate_limiting_emits_once_per_cadence ... ok
test hooks::pre_tool_use::tests::grep_advisory_matches_symbol_like_patterns ... ok
test hooks::pre_tool_use::tests::grep_advisory_skips_regex_patterns ... ok
test hooks::pre_tool_use::tests::read_advisory_skips_non_code_files ... ok
test hooks::pre_tool_use::tests::read_advisory_skips_small_code_files ... ok
test hooks::pre_tool_use::tests::read_advisory_triggers_for_large_code_files ... ok

test result: ok. 6 passed; 0 failed; 0 ignored; 0 measured; 134 filtered out; finished in 0.19s

<!-- PASTE END -->

**Checklist:**
- [x] Advisory fires for Read on `.rs` / `.ts` / `.py` files when rhizome is available
- [x] Advisory does NOT fire for non-code files (`.md`, `.json`, `.toml`, config)
- [x] Advisory does NOT fire when rhizome is unavailable
- [x] Original Read tool call proceeds (advisory only, not blocking)

---

### Step 2: Add Grep advisory for symbol-like patterns

**Project:** `cortina/`
**Effort:** 1 hour
**Depends on:** Step 1

When cortina receives a `Grep` tool event where the pattern looks like a symbol
(no regex metacharacters, starts with uppercase or followed by `(`, matches
`[A-Za-z_][A-Za-z0-9_]*`), emit:

```
[cortina] Symbol search — consider: mcp__rhizome__search_symbols or mcp__rhizome__find_references
```

#### Verification

```bash
cd cortina && cargo test grep_advisory 2>&1
```

**Output:**
<!-- PASTE START -->
    Finished `test` profile [unoptimized + debuginfo] target(s) in 1.79s
     Running unittests src/main.rs (target/debug/deps/cortina-d2bee19604b8741e)

running 2 tests
test hooks::pre_tool_use::tests::grep_advisory_matches_symbol_like_patterns ... ok
test hooks::pre_tool_use::tests::grep_advisory_skips_regex_patterns ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 138 filtered out; finished in 0.00s

<!-- PASTE END -->

**Checklist:**
- [x] Advisory fires for Grep with symbol-like patterns (e.g., `MyStruct`, `parse_command`)
- [x] Advisory does NOT fire for regex patterns (e.g., `foo.*bar`, `^fn `)
- [x] Advisory does NOT fire when rhizome is unavailable
- [x] Original Grep still runs

---

### Step 3: Add rate limiting to advisories

**Project:** `cortina/`
**Effort:** 30 min
**Depends on:** Step 1, Step 2

Advisories should not fire on every single Read/Grep call — that's noisy. Add a
per-session counter: advisory fires at most once every N calls for a given file
extension / pattern type. Use the existing cortina dedupe/threshold infrastructure.

**Checklist:**
- [x] Advisory fires at most once per N calls per pattern type (N configurable, default 5)
- [x] Rate limit resets per session

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. All checklist items are checked
3. `cd cortina && cargo test --all` passes

Completion notes (2026-04-07):
- Implemented in `cortina/src/hooks/pre_tool_use.rs` with per-session advisory cadence from `CORTINA_RHIZOME_SUGGEST_EVERY` (default `5`).
- Final follow-up fixed relative `Read` paths to resolve against the event `cwd`, so advisory detection now works correctly outside Cortina's own launch directory.
- Repo-local verification passed: `cargo build`, `cargo test advisory`, `cargo test grep_advisory`, and `cargo test --all` (`150 passed; 0 failed`).

## Context

`ECOSYSTEM-OVERVIEW.md` gap #4. `IMPROVEMENTS-TOOLS.md` documents the coverage
gap table showing Read/Grep tool calls bypass mycelium entirely. The advisory
model was designed in the Tool Nudging handoff (completed 2026-04) but only the
global rules file and shell-level rewrites were implemented — the MCP tool
interception was explicitly left for this follow-up.
