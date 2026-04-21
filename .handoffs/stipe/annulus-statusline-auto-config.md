# Annulus Statusline Auto-Configuration

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/...`
- **Cross-repo edits:** none
- **Non-goals:** Codex statusline hook installation (separate handoff), annulus code changes, septa schema changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/stipe/verify-annulus-statusline-auto-config.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:**
  - `src/ecosystem/context.rs` — add `annulus_probe` to `EcosystemContext`
  - `src/commands/claude_hooks.rs` — add annulus statusline installation alongside cortina
  - `src/ecosystem/workflow.rs` — wire annulus statusline into `configure_claude_code`
  - `src/commands/init/model.rs` — add `annulus_installed` to `ToolSnapshot`
  - `src/commands/init/snapshot.rs` — probe for annulus
  - `src/commands/init/plan.rs` — add annulus statusline step
- **Reference seams:**
  - `src/commands/claude_hooks.rs:74` — `CORTINA_STATUSLINE_COMMAND` constant and `install_statusline()` function
  - `src/ecosystem/workflow.rs:204-225` — where cortina hooks are installed during Claude Code configuration
  - `src/ecosystem/context.rs:31-41` — where tool probes are built
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

When annulus is installed, the user must manually configure Claude Code's statusline to use `annulus statusline`. Stipe already auto-configures `cortina statusline` during `stipe init` — the same mechanism should prefer annulus when it's available, since annulus provides richer statusline data (token usage, context bar, cost, savings, multi-provider support).

## What exists (state)

- **`claude_hooks.rs:74`**: `CORTINA_STATUSLINE_COMMAND = "cortina statusline"` — hardcoded
- **`claude_hooks.rs:179-195`**: `install_statusline()` writes `{"statusLine": {"type": "command", "command": "cortina statusline"}}` to `~/.claude/settings.json`
- **`workflow.rs:204-213`**: `configure_claude_code` calls `install_claude_hooks()` only when cortina is installed
- **`context.rs:38`**: `cortina_probe` exists but no `annulus_probe`
- **`init/model.rs:25`**: `cortina_installed` in `ToolSnapshot` but no `annulus_installed`
- **`init/snapshot.rs:55-57`**: probes cortina but not annulus

## What needs doing (intent)

1. Add `annulus_probe` to `EcosystemContext` (context.rs)
2. Add `annulus_installed` and `annulus_broken` to `ToolSnapshot` (init/model.rs)
3. Probe for annulus in `build_snapshot` (init/snapshot.rs)
4. Add an `ANNULUS_STATUSLINE_COMMAND` constant to `claude_hooks.rs` (`"annulus statusline"`)
5. Update `install_statusline()` to accept a command parameter instead of hardcoding cortina
6. In `configure_claude_code` (workflow.rs), prefer annulus statusline when annulus is installed, fall back to cortina statusline when only cortina is installed
7. Add an init plan step for annulus statusline configuration
8. Add a function to generate default `~/.config/annulus/statusline.toml` if missing when annulus is installed

## Scope

- **Primary seam:** stipe init and ecosystem configuration flows
- **Allowed files:** `stipe/src/`
- **Explicit non-goals:**
  - Do not install a Codex statusline hook (separate handoff #144)
  - Do not change annulus code
  - Do not change septa schemas (the statusline command is a host-local setting, not a cross-tool payload)
  - Do not remove cortina statusline support — it remains the fallback when annulus is not installed

---

### Step 1: Add annulus to tool probing

**Project:** `stipe/`
**Effort:** 0.25 day
**Depends on:** nothing

Add `annulus_probe: ToolProbe` to `EcosystemContext` in `context.rs`. Add `annulus_installed: bool` and `annulus_broken: bool` to `ToolSnapshot` in `init/model.rs`. Probe for annulus in `build_snapshot` in `init/snapshot.rs`.

#### Verification

```bash
cd stipe && cargo check 2>&1
```

**Checklist:**
- [ ] `annulus_probe` added to `EcosystemContext`
- [ ] `annulus_installed` and `annulus_broken` added to `ToolSnapshot`
- [ ] `build_snapshot` probes for annulus
- [ ] `probe_for_tool("annulus")` returns the probe

---

### Step 2: Prefer annulus statusline in Claude Code configuration

**Project:** `stipe/`
**Effort:** 0.5 day
**Depends on:** Step 1

Add `ANNULUS_STATUSLINE_COMMAND = "annulus statusline"` to `claude_hooks.rs`. Refactor `install_statusline()` to accept a command string parameter. In `configure_claude_code` (workflow.rs), after MCP registration:

1. If annulus is installed → write `"annulus statusline"` as the statusline command
2. Else if cortina is installed → write `"cortina statusline"` (existing behavior)
3. Else → skip statusline configuration

Also handle upgrade: if the existing statusline is `"cortina statusline"` and annulus is now installed, upgrade it to `"annulus statusline"`.

The `statusline_installed()` check in `claude_hooks.rs` should accept both annulus and cortina commands as "already configured."

#### Verification

```bash
cd stipe && cargo test 2>&1
cd stipe && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Annulus statusline preferred when annulus is installed
- [ ] Falls back to cortina when annulus is not installed
- [ ] Existing cortina statusline is upgraded to annulus when annulus becomes available
- [ ] Both annulus and cortina statusline commands are recognized as "already configured"
- [ ] Idempotent: re-running init doesn't change an already-correct statusline setting

---

### Step 3: Add annulus statusline init plan step

**Project:** `stipe/`
**Effort:** 0.25 day
**Depends on:** Step 1

Add an `annulus_statusline_step` function in `plan.rs` that shows:
- `AlreadyOk` when annulus statusline is already configured
- `Planned` when annulus is installed but statusline not yet configured
- `Skipped` when annulus is not installed

Add it to `build_steps()` alongside the existing claude hooks step.

#### Verification

```bash
cd stipe && cargo test 2>&1
```

**Checklist:**
- [ ] Init plan shows annulus statusline step
- [ ] Step status reflects actual state (AlreadyOk / Planned / Skipped)

---

### Step 4: Generate default annulus config

**Project:** `stipe/`
**Effort:** 0.25 day
**Depends on:** Step 2

Add a function that creates `~/.config/annulus/statusline.toml` with sensible defaults if the file does not exist and annulus is installed. Call it during `configure_claude_code` when annulus is selected as the statusline provider. The default config should be minimal — annulus already has built-in defaults for segments and context limits.

#### Verification

```bash
cd stipe && cargo test 2>&1
cd stipe && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Default config file created when missing and annulus is installed
- [ ] Existing config file is not overwritten
- [ ] Config directory is created if needed
- [ ] Config content is minimal and correct TOML

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/stipe/verify-annulus-statusline-auto-config.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/stipe/verify-annulus-statusline-auto-config.sh
```

## Context

Source: user request — annulus should auto-configure during `stipe init` instead of requiring manual setup. Stipe already has the infrastructure (tool registry, init plan, ecosystem workflow). The gap is purely integration: probe annulus, prefer it for statusline, generate config.

Related handoffs: archived Annulus Session-Scoped Provider Resolution (shipped in v0.5.0), archived Annulus Multi-Session Host Adapter Contract.
