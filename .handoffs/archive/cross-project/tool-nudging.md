# Handoff: Smart Tool Nudging (Items #22-25)

Nudge AI agents toward token-efficient tools (rhizome, rg, fd) instead of
raw Read/Grep/find. Four sequential steps, each independently shippable.

## Status

Implemented on 2026-04-01.

Shipped work:
- `~/.claude/rules/common/tool-preferences.md`
- `cortina` commit `6e2df5d` (`feat: add rhizome tool nudges to pre-tool-use`)
- `mycelium` commit `3554038` (`chore: bump version to v0.8.5`) with the safe `find -> fd` rewrite already included from the preceding feature commit

## What exists (state)

- **Design doc:** `RHIZOME-FIRST-EXPLORATION.md` (workspace root) — full
  design with Rust snippets for all three rules
- **CLAUDE.md instruction:** Already has one-liner: "For code files >100
  lines, prefer rhizome tools... 80-90% fewer tokens"
- **Cortina PreToolUse:** `cortina/src/hooks/pre_tool_use.rs` handles
  Bash→mycelium rewrite only. No Read/Grep interception yet.
- **Mycelium rewrite:** `mycelium rewrite` handles shell command rewrites.
  No `find→fd` rule yet.
- **Lamella skill:** `lamella/resources/skills/tools/token-reduction-optimizer/SKILL.md`
  references "RTK" (stale name for mycelium)
- **PHASES.md items:** #22 (Read advisory), #23 (Grep advisory), #24 (find→fd),
  #25 (feedback loop)
- **Build:** cortina and mycelium both build clean

## What needs doing (intent)

Four steps in dependency order. Each is independently deployable.

---

### Step 1: Global Claude Rule — Tool Preferences

**Project:** `~/.claude/rules/common/`
**Effort:** 5 minutes
**Impact:** Immediate, all sessions

Create `~/.claude/rules/common/tool-preferences.md`:

```markdown
# Tool Preferences

When available, prefer token-efficient tools over raw file operations:

| Task | Prefer | Over | Why |
|------|--------|------|-----|
| Understand file structure | rhizome `get_symbols` / `get_structure` | `Read` full file | 90% fewer tokens |
| Read specific function | rhizome `get_symbol_body` | `Read` full file | 80% fewer tokens |
| Find callers/references | rhizome `find_references` | `Grep` for name | 85% fewer tokens |
| Search for symbol | rhizome `search_symbols` | `Grep` for name | 75% fewer tokens |
| Quick diagnostics | rhizome `get_diagnostics` | Running linter | 70% fewer tokens |

### When to use Read/Grep instead

- Non-code files (README, config, .env)
- Small files (<50 lines)
- Text/pattern search (log patterns, string literals, comments)
- File discovery by name (Glob is correct here)
- Rhizome not available in current session
```

**Verification:**
- [x] File created at `~/.claude/rules/common/tool-preferences.md`
- [x] Rule content is installed at the standard global Claude rules path for future sessions
- [x] Runtime nudging now also exists independently via Cortina `Read`/`Grep` advisories

---

### Step 2: Cortina Read → Rhizome Advisory (PHASES #22)

**Project:** `cortina/`
**Effort:** ~1 hour
**Depends on:** Nothing (Step 1 is nice-to-have but not required)

When an agent calls `Read` on a code file >100 lines and rhizome is
installed, log an advisory to stderr suggesting rhizome tools.

#### Files to modify

**`cortina/src/hooks/pre_tool_use.rs`** — Add Read handler after Bash handler:

```rust
// After existing Bash rewrite logic, add:

if envelope.tool_name_is("Read") {
    return handle_read_suggestion(&envelope);
}

// ---

const CODE_EXTENSIONS: &[&str] = &[
    "rs", "py", "js", "ts", "tsx", "jsx", "go", "java", "c", "cpp", "h", "hpp",
    "rb", "php", "swift", "zig", "ex", "exs", "lua", "hs", "cs", "kt", "dart",
    "vue", "svelte", "astro",
];

const RHIZOME_SUGGEST_THRESHOLD: usize = 100;

fn handle_read_suggestion(envelope: &ClaudeCodeHookEnvelope) -> Result<()> {
    if !command_exists("rhizome") {
        return Ok(());
    }

    let file_path = match envelope.tool_input_string("file_path") {
        Some(path) => path,
        None => return Ok(()),
    };

    let extension = Path::new(file_path)
        .extension()
        .and_then(|ext| ext.to_str())
        .unwrap_or("");
    if !CODE_EXTENSIONS.contains(&extension) {
        return Ok(());
    }

    let line_count = match std::fs::read_to_string(file_path) {
        Ok(content) => content.lines().count(),
        Err(_) => return Ok(()),
    };
    if line_count < RHIZOME_SUGGEST_THRESHOLD {
        return Ok(());
    }

    eprintln!(
        "cortina: rhizome suggestion for {file_path} ({line_count} lines): \
         prefer get_symbols/get_structure/get_symbol_body before full Read"
    );
    Ok(())
}
```

**`cortina/src/adapters/claude_code.rs`** — Add helper if not present:

```rust
impl ClaudeCodeHookEnvelope {
    pub fn tool_name_is(&self, name: &str) -> bool {
        self.tool_name().map_or(false, |n| n == name)
    }
}
```

**`cortina/src/policy.rs`** — Add config:

```rust
pub rhizome_suggest_threshold: usize,  // env: CORTINA_RHIZOME_SUGGEST_THRESHOLD, default: 100
pub rhizome_suggest_enabled: bool,     // env: CORTINA_RHIZOME_SUGGEST_ENABLED, default: true
```

#### Testing

```bash
# Unit test: mock envelope with Read tool + large code file path
# Verify: stderr contains "rhizome suggestion" when file >100 lines
# Verify: no output for non-code files (.md, .toml, .env)
# Verify: no output for small files (<100 lines)
# Verify: no output when rhizome not installed

cd cortina && cargo test
cargo clippy
```

**Verification checklist:**
- [x] `cargo test` passes
- [x] `cargo clippy` clean
- [x] Manual test: large `.rs` file shows a `rhizome suggestion` advisory
- [x] Manual test: same with a `.md` file shows no advisory
- [x] Advisory disabled when `CORTINA_RHIZOME_SUGGEST_ENABLED=false`

---

### Step 3: Cortina Grep → Rhizome Advisory (PHASES #23)

**Project:** `cortina/`
**Effort:** ~45 minutes
**Depends on:** Step 2 (shares the same PreToolUse handler structure)

When an agent calls `Grep` with a symbol-like pattern and rhizome is
installed, suggest `search_symbols` or `find_references`.

#### Symbol detection heuristic

```rust
fn looks_like_symbol(pattern: &str) -> bool {
    if pattern.len() < 4 { return false; }
    if pattern.chars().any(|c| ".*+?[]{}()|^$\\".contains(c)) { return false; }
    if pattern.contains(' ') { return false; }

    let has_upper = pattern.chars().any(|c| c.is_uppercase());
    let has_lower = pattern.chars().any(|c| c.is_lowercase());
    let has_underscore = pattern.contains('_');

    (has_upper && has_lower) || has_underscore
}
```

**Catches:** `AuthService`, `validate_token`, `getUserById`
**Skips:** `TODO|FIXME`, `error:`, `fn main`, `id`

#### Files to modify

**`cortina/src/hooks/pre_tool_use.rs`** — Add after Read handler:

```rust
if envelope.tool_name_is("Grep") {
    return handle_grep_suggestion(&envelope);
}

fn handle_grep_suggestion(envelope: &ClaudeCodeHookEnvelope) -> Result<()> {
    if !command_exists("rhizome") { return Ok(()); }

    let pattern = match envelope.tool_input_string("pattern") {
        Some(p) => p,
        None => return Ok(()),
    };

    if !looks_like_symbol(pattern) { return Ok(()); }

    eprintln!(
        "cortina: rhizome suggestion for grep pattern '{pattern}': \
         search_symbols('{pattern}') for semantic matches, \
         find_references for call sites"
    );
    Ok(())
}
```

**Verification checklist:**
- [x] `cargo test` passes (with unit tests for `looks_like_symbol`)
- [x] `cargo clippy` clean
- [x] Test: symbol patterns trigger advisory
- [x] Test: regex patterns, short strings, multi-word patterns do NOT trigger
- [x] Disabled when `CORTINA_RHIZOME_SUGGEST_ENABLED=false`

---

### Step 4: Mycelium `find` → `fd` Rewrite (PHASES #24)

**Project:** `mycelium/`
**Effort:** ~1 hour
**Depends on:** Nothing (independent of Steps 2-3)

Add a rewrite rule to mycelium so `find` commands become `fd` commands
when `fd` is installed. Skip complex find commands (`-exec`, `-delete`,
`-print0`).

#### Rewrite rules

| find | fd | Notes |
|------|----|-------|
| `find src -name '*.rs'` | `fd -e rs src` | Extension extraction |
| `find . -name '*.ts' -type f` | `fd -e ts . --type f` | Type preserved |
| `find . -name 'test_*'` | `fd 'test_' .` | Glob → regex |
| Complex (has `-exec`) | Pass through unchanged | Too risky to rewrite |

`fd` respects `.gitignore` by default, so `--not-path '*/target/*'` and
similar exclusions become implicit.

#### Files to modify

Find mycelium's rewrite module (likely `src/rewrite.rs` or similar) and add
a `find` → `fd` translation. The rewrite should:

1. Check `fd` is in PATH
2. Parse basic `find` args: path, `-name`, `-type`
3. Skip if command has `-exec`, `-delete`, `-print0`, `-newer`, or pipes
4. Construct equivalent `fd` command
5. Return `Some(fd_command)` or `None` for passthrough

#### Testing

```bash
# Snapshot tests with insta for find→fd translations
# Token accuracy: fd output vs find output (expect ~30% savings from gitignore filtering)
cd mycelium && cargo test
cargo clippy
```

**Verification checklist:**
- [x] `cargo test` passes with registry tests for common `find -> fd` patterns
- [x] Complex find commands pass through unchanged
- [x] `fd` not installed → find passes through unchanged at runtime
- [x] `MYCELIUM_FD_REWRITE_ENABLED=false` disables the rewrite

---

## Where I stopped (boundary)

- **Why:** Completed
- **Blocked on:** Nothing
- **Reference design:** `RHIZOME-FIRST-EXPLORATION.md` has full Rust snippets
  for all rules

## Execution order

```
Step 1 (rule file)     → immediate, no code changes
Step 2 (Read advisory) → cortina PR
Step 3 (Grep advisory) → same cortina PR or follow-up
Step 4 (find→fd)       → separate mycelium PR

Step 5 (future, PHASES #25): feedback loop
  - Track suggestion-accepted events in hyphae
  - Surface in cap analytics
  - Not in scope for this handoff
```

## Token savings projection

| Rule | Per-session savings | Mechanism |
|------|-------------------|-----------|
| Global rule (Step 1) | ~40% of exploration tokens | Agent reads rule, chooses rhizome |
| Read advisory (Step 2) | ~20% additional | Catches habit-driven Reads |
| Grep advisory (Step 3) | ~15% additional | Catches symbol-searching via Grep |
| find→fd rewrite (Step 4) | ~5% additional | Cleaner output, gitignore filtering |
| **Combined** | **~70-80% of exploration tokens** | Layered nudging |

Combined with mycelium's CLI output compression (60-90%), the ecosystem
reduces total token consumption by **75-90%** across command output and
code exploration.
