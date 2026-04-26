# Cortina: Hook Governance and Tool Metadata

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/hooks/` (new hook type registry + executor), `cortina/src/permissions/` (new command permission controller)
- **Cross-repo edits:** `canopy/src/tools/` (add ToolMetadata to tool registry)
- **Non-goals:** does not change existing cortina signal emission pipeline; does not add VS Code-specific extension wiring; does not add webview or proto compilation
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Extracted from the cline ecosystem borrow audit (`.audit/external/audits/cline-ecosystem-borrow-audit.md`):

> "Cline's hook system (PreToolUse, PostToolUse, TaskStart, TaskResume, TaskCancel, TaskComplete, Notification, PreCompact) is stateless, timeout-protected (30s), and fail-open — only explicit `cancel: true` blocks execution. Hook output includes cancellation, context modification, and error messaging."

> "CommandPermissionController validates shell commands against glob-pattern allow/deny lists. Detects dangerous operators. Parses chained commands and validates each segment."

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:**
  - `src/hooks/types.rs` (new) — `HookType` enum, `HookInput`, `HookOutput` structs
  - `src/hooks/executor.rs` (new) — hook runner with 30s timeout + fail-open semantics
  - `src/permissions/mod.rs` (new) — `CommandPermissionController`
  - `canopy/src/tools/metadata.rs` (new) — `ToolMetadata` struct with idempotency flags
- **Reference seams:**
  - `cortina/src/` — read existing lifecycle signal pipeline before adding
  - `canopy/src/tools/` — read existing tool dispatch before adding metadata
- **Spawn gate:** read cortina's existing hook mechanism before spawning

## Problem

Cortina's current hooks have no timeout protection — a misbehaving hook can block the entire tool-use pipeline indefinitely. There is also no standardized vocabulary for hook lifecycle types, so different parts of the ecosystem invent their own names. Finally, there is no ToolMetadata annotation system: canopy cannot distinguish idempotent reads from destructive writes when making approval gate decisions.

## What needs doing (intent)

1. Define `HookType` enum with the eight types from cline
2. Add 30s timeout + fail-open executor for hook processes
3. Add context modification payload support with 50KB limit
4. Define `ToolMetadata` struct for the canopy tool registry
5. Add `CommandPermissionController` for shell command validation

## Hook model

```rust
/// Lifecycle hook types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum HookType {
    PreToolUse,
    PostToolUse,
    TaskStart,
    TaskResume,
    TaskCancel,
    TaskComplete,
    Notification,
    PreCompact,
}

pub struct HookInput {
    pub hook_type: HookType,
    pub tool_name: Option<String>,
    pub context: serde_json::Value,
}

pub struct HookOutput {
    /// If true, execution is blocked. Default: false (fail-open).
    pub cancel: bool,
    /// Modified context payload. Capped at 50KB.
    pub context_modification: Option<serde_json::Value>,
    pub error: Option<String>,
}
```

Executor contract:
- 30s timeout per hook invocation
- If hook times out or errors: log warning, return `HookOutput { cancel: false, .. }` (fail-open)
- Only `cancel: true` blocks downstream execution
- Context modifications are applied before the tool call but capped at 50KB

## Tool metadata

```rust
/// Annotation for tools registered in canopy's tool registry.
pub struct ToolMetadata {
    /// Tool is safe to call multiple times with the same args.
    pub idempotent: bool,
    /// Tool only reads; never mutates state.
    pub read_only: bool,
    /// Tool may delete or overwrite data irreversibly.
    pub destructive: bool,
    /// Human-readable prompt shown in approval gates.
    pub acceptance_criteria: Option<String>,
}
```

Approval gate logic in canopy dispatch:
- `read_only = true` → skip approval gate
- `destructive = true` → require explicit `allow` in permission policy
- default → apply existing policy rules

## Command permission controller

```rust
pub struct CommandPermissionController {
    allow_patterns: Vec<glob::Pattern>,
    deny_patterns: Vec<glob::Pattern>,
    allow_redirects: bool,
}

impl CommandPermissionController {
    /// Validate a shell command string.
    /// Splits chained commands (&&, ||, |, ;) and validates each segment.
    pub fn validate(&self, command: &str) -> Result<(), PermissionError>;

    /// Detect dangerous shell operators.
    fn has_dangerous_operators(segment: &str) -> bool;
}
```

Config loaded from `~/.config/basidiocarp/permissions.toml` and `.basidiocarp/permissions.toml` (workspace overrides global). Format:

```toml
allow_redirects = false

[[allow]]
pattern = "cargo *"

[[allow]]
pattern = "git *"

[[deny]]
pattern = "rm -rf *"
```

## Hook loading precedence

Load hooks from two directories in order:
1. `~/.config/basidiocarp/hooks/` — global hooks (run first)
2. `.basidiocarp/hooks/` — workspace hooks (run second)

Both layers run; workspace does not replace global. All hooks for a given HookType run before execution proceeds.

## Scope

- **Allowed files:** `cortina/src/hooks/types.rs` (new), `cortina/src/hooks/executor.rs` (new), `cortina/src/permissions/mod.rs` (new), `canopy/src/tools/metadata.rs` (new), `canopy/src/tools/mod.rs` (register ToolMetadata)
- **Explicit non-goals:**
  - No VS Code extension wiring
  - No proto/gRPC compilation pipeline
  - No webview UI
  - No changes to existing cortina signal emission

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `cortina/src/` — what does the current hook/signal pipeline look like? Is there already a HookType or hook runner?
2. `canopy/src/tools/` — is there already a tool registry? What does tool registration look like today?

---

### Step 1: Define hook types and HookInput/HookOutput

**Project:** `cortina/`
**Effort:** small
**Depends on:** Step 0

Create `src/hooks/types.rs` with `HookType`, `HookInput`, `HookOutput` as above.

#### Verification

```bash
cd cortina && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `HookType` enum compiles with all 8 variants
- [ ] `HookInput` and `HookOutput` compile with serde derives

---

### Step 2: Add hook executor with timeout and fail-open

**Project:** `cortina/`
**Effort:** small
**Depends on:** Step 1

Create `src/hooks/executor.rs`. Run hooks as subprocesses (stdin/stdout) with a 30-second timeout. On timeout or error: log `warn!`, return `HookOutput { cancel: false, context_modification: None, error: Some(...) }`.

```rust
pub struct HookExecutor {
    hooks_dirs: Vec<PathBuf>,  // global + workspace dirs
}

impl HookExecutor {
    pub async fn run_hooks(
        &self,
        hook_type: HookType,
        input: &HookInput,
    ) -> HookOutput;
}
```

#### Verification

```bash
cd cortina && cargo build 2>&1 | tail -5
cd cortina && cargo test hook 2>&1
```

**Checklist:**
- [ ] Executor compiles and is async-safe
- [ ] 30s timeout enforced (test with a slow hook)
- [ ] Fail-open: timeout returns `cancel: false`
- [ ] Context modification capped at 50KB

---

### Step 3: Add CommandPermissionController

**Project:** `cortina/`
**Effort:** small
**Depends on:** Step 2

Create `src/permissions/mod.rs`. Load config from global + workspace TOML. Validate shell commands by splitting on `&&`, `||`, `|`, `;` and checking each segment against allow/deny glob patterns. Detect dangerous operators (backtick substitution, unquoted newlines, bare redirects when `allow_redirects = false`).

#### Verification

```bash
cd cortina && cargo test permission 2>&1
```

**Checklist:**
- [ ] Allow/deny glob patterns load from TOML
- [ ] Chained command splitting works (&&, ||, |, ;)
- [ ] Dangerous operator detection correct
- [ ] Backward-compatible: empty config allows all

---

### Step 4: Add ToolMetadata to canopy tool registry

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 3

Create `canopy/src/tools/metadata.rs` with `ToolMetadata` struct. Update tool registration to accept optional `ToolMetadata`. Update canopy dispatch to check `read_only` (skip approval) and `destructive` (require explicit allow) before applying policy rules.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `ToolMetadata` compiles and is registered with tools
- [ ] `read_only` tools skip approval gate
- [ ] `destructive` tools require explicit allow

---

### Step 5: Full suite

```bash
cd cortina && cargo test 2>&1 | tail -20
cd cortina && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd cortina && cargo fmt --check 2>&1
cd canopy && cargo test 2>&1 | tail -20
cd canopy && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
```

**Checklist:**
- [ ] All tests pass in cortina
- [ ] All tests pass in canopy
- [ ] Clippy clean in both
- [ ] Fmt clean in both

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output
2. Full test suite passes in both cortina and canopy
3. All checklist items checked
4. `.handoffs/HANDOFFS.md` updated

## Follow-on work (not in scope here)

- `septa/hook-contracts-v1.schema.json` — if hooks need to cross tool boundaries
- HTTP/gRPC hook delivery (instead of subprocess) for in-process hosts
- `stipe`: formalize hook directory installation at `~/.config/basidiocarp/hooks/`
- Hook telemetry: emit per-hook duration + outcome as cortina lifecycle signals

## Context

Spawned from Wave 2 audit program (2026-04-23). Cline's hook system is production-grade: 8 lifecycle types, 30s timeout, fail-open semantics, context modification with size limit. The cortina equivalent is missing the timeout guard and the ToolMetadata annotation that enables principled approval gates. Both patterns are framework-agnostic — the VS Code extension shell is not needed.
