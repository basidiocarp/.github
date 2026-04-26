# Stipe: Install Mode Prompt

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** stipe (prompt + config write); volva (config read)
- **Allowed write scope:** `stipe/src/commands/init/`, `volva/crates/volva-config/src/`, `volva/crates/volva-cli/src/main.rs`
- **Cross-repo edits:** volva (config reader) — allowed; no other repos
- **Non-goals:** changing the `--mode` flag itself (done in C5); changing stipe's uninstall path; adding a mode selection UI to cap
- **Verification contract:** `stipe init` (dry-run or actual) asks which mode; writing `~/.config/volva/config.toml` with `mode = "baseline"` causes `volva doctor` to reflect baseline mode as default; `--mode orchestration` CLI flag still overrides
- **Completion update:** update dashboard when prompt is implemented and verified

## Context

C5 (orchestration-mode-definition.md) locked the following decision:

> **Stipe during install:** Ask the user which mode, default to baseline if they skip the prompt.

C5 implemented `volva --mode baseline|orchestration` as an explicit CLI flag. This handoff implements the stipe side: asking the user during `stipe init` and persisting the choice so that volva's default matches their intent across sessions.

Currently:
- `volva --mode` defaults to `baseline` (hardcoded in clap via `default_value = "baseline"`)
- Nothing in stipe's init path asks about mode
- No global volva config file exists at `~/.config/volva/config.toml`

## Decision: Global Config File

Volva's workspace-local config is `volva.json` (read from `cwd`). A mode preference is global (per-user, not per-project), so it needs a global config file: `~/.config/volva/config.toml`.

volva-config should read this file as a fallback when computing the default mode. The `--mode` CLI flag overrides the global config file. This means the precedence chain is:

```
--mode flag > ~/.config/volva/config.toml > built-in default (baseline)
```

## What needs doing

### Part 1: volva — add global config file reader

In `volva/crates/volva-config/src/`:

Add a `GlobalVolvaConfig` struct and a load function:

```rust
/// Loads the global user-level config from ~/.config/volva/config.toml.
/// Returns defaults if the file does not exist.
#[derive(Debug, Default)]
pub struct GlobalVolvaConfig {
    pub mode: Option<String>, // "baseline" | "orchestration"
}

impl GlobalVolvaConfig {
    pub fn load() -> Self {
        let path = dirs::config_dir()
            .map(|d| d.join("volva").join("config.toml"))
            .filter(|p| p.exists());

        match path.and_then(|p| std::fs::read_to_string(p).ok()) {
            Some(contents) => {
                let mode = contents
                    .lines()
                    .find_map(|line| {
                        let line = line.trim();
                        line.strip_prefix("mode").and_then(|rest| {
                            rest.trim_start().strip_prefix('=').map(|v| {
                                v.trim().trim_matches('"').to_string()
                            })
                        })
                    });
                GlobalVolvaConfig { mode }
            }
            None => GlobalVolvaConfig::default(),
        }
    }

    pub fn operation_mode(&self) -> Option<volva_core::OperationMode> {
        use volva_core::OperationMode;
        match self.mode.as_deref() {
            Some("baseline") => Some(OperationMode::Baseline),
            Some("orchestration") => Some(OperationMode::Orchestration),
            _ => None,
        }
    }
}
```

If `dirs` crate is not already a dependency, add it to `volva-config/Cargo.toml`.

In `volva/crates/volva-cli/src/main.rs`, update the CLI struct so `--mode` falls back to the global config:

```rust
fn main() -> Result<()> {
    // ...
    let global_config = GlobalVolvaConfig::load();
    let cli = Cli::parse();

    // Resolve mode: CLI flag > global config > built-in default
    let mode = if std::env::args().any(|a| a == "--mode") {
        cli.mode
    } else {
        global_config
            .operation_mode()
            .unwrap_or(cli.mode)
    };
    // use `mode` instead of `cli.mode` for the rest of main
```

**Important:** detect whether `--mode` was explicitly passed rather than using the clap default. Use `clap`'s `ArgMatches::contains_id("mode")` or make the field `Option<OperationMode>` with `default_value = None` and fall back in code. The latter is cleaner.

Recommended approach — change the CLI struct:

```rust
#[derive(Debug, Parser)]
struct Cli {
    #[arg(long, value_enum)]
    pub mode: Option<OperationMode>,  // None = not explicitly passed
    // ...
}
```

Then resolve:
```rust
let mode = cli.mode
    .or_else(|| global_config.operation_mode())
    .unwrap_or(OperationMode::Baseline);
```

### Part 2: stipe — add mode prompt to `stipe init`

Read `stipe/src/commands/init/` to understand the current init flow before editing.

Add a mode selection prompt during `stipe init`. The prompt should appear after the core install steps complete:

```
Which mode do you want for volva?
  [1] baseline      — hyphae, mycelium, rhizome (default)
  [2] orchestration — full coordination with canopy and hymenium
Choose [1/2] (default: 1):
```

If the user presses Enter or types `1`, write `mode = "baseline"`.
If the user types `2`, write `mode = "orchestration"`.
If the user types anything else or the prompt cannot run interactively, default to `baseline`.

Write the choice to `~/.config/volva/config.toml`:

```toml
# Volva global configuration
# Managed by stipe. Edit manually or re-run stipe init to change.
mode = "baseline"
```

Create the directory if it does not exist: `~/.config/volva/`

The write should be idempotent — if the file already exists, overwrite `mode` without changing other fields (or replace the file entirely if it is simple enough).

### Part 3: stipe doctor — verify mode config

If `stipe doctor` already checks volva, add a check that reads `~/.config/volva/config.toml` and reports the configured mode. If the file does not exist, report `mode: not configured (default: baseline)`.

This is optional but helpful for operators troubleshooting mode behavior.

## Implementation Seam

- **Primary files:**
  - `volva/crates/volva-config/src/` — add `GlobalVolvaConfig`
  - `volva/crates/volva-cli/src/main.rs` — resolve mode with fallback
  - `stipe/src/commands/init/` — add mode prompt and config write
- **Reference seams:** read how `VolvaConfig::load_from` works before adding global config; read the existing stipe init flow before adding the prompt
- **Spawn gate:** do not spawn an implementer until you have read both `volva/crates/volva-config/src/` and `stipe/src/commands/init/` to confirm the exact insertion points

---

### Step 1: Read volva-config and stipe init

**Project:** volva, stipe
**Effort:** 30 min
**Depends on:** nothing

Read:
- `volva/crates/volva-config/src/lib.rs` — how config is currently loaded
- `volva/crates/volva-cli/src/main.rs` — how `cli.mode` is currently used (lines 32-160)
- `stipe/src/commands/init/` — the init flow

Confirm: does `volva-config` already depend on `dirs`? Does stipe have a prompt utility?

#### Verification

```bash
grep -r "dirs\b" volva/Cargo.toml volva/crates/volva-config/Cargo.toml
grep -rn "prompt\|inquire\|dialoguer" stipe/Cargo.toml stipe/src/
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] volva-config load path understood
- [ ] stipe init flow understood
- [ ] Prompt library identified (or need to add one)

---

### Step 2: Add GlobalVolvaConfig to volva-config

**Project:** volva
**Effort:** 1-2 hours
**Depends on:** Step 1

Add `GlobalVolvaConfig::load()` and `operation_mode()` to `volva-config`.

Update `volva-cli/src/main.rs` to resolve mode via the fallback chain:
`--mode flag > GlobalVolvaConfig > OperationMode::Baseline`

#### Verification

```bash
cd volva
cargo test -p volva-config
cargo test -p volva-cli
cargo clippy -p volva-config -p volva-cli -- -D warnings

# Functional check: no global config → baseline
cargo run -p volva-cli -- doctor 2>&1 | head -5

# Functional check: write baseline config then run without --mode
mkdir -p ~/.config/volva
echo 'mode = "baseline"' > ~/.config/volva/config.toml
cargo run -p volva-cli -- doctor 2>&1 | head -5

# Functional check: --mode flag still overrides
cargo run -p volva-cli -- --mode orchestration doctor 2>&1 | head -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] GlobalVolvaConfig reads ~/.config/volva/config.toml
- [ ] Missing file returns default (baseline)
- [ ] --mode flag overrides global config
- [ ] Tests and clippy pass

---

### Step 3: Add mode prompt to stipe init

**Project:** stipe
**Effort:** 1-2 hours
**Depends on:** Step 1

Add the mode selection prompt to `stipe init`. Write `~/.config/volva/config.toml` with the chosen mode.

#### Verification

```bash
cd stipe

# Dry-run (if stipe supports --dry-run)
cargo run -- init --dry-run 2>&1 | grep -i mode

# Confirm file is written
echo 'mode = "orchestration"' > ~/.config/volva/config.toml
cat ~/.config/volva/config.toml

cargo test
cargo clippy -- -D warnings
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Prompt appears during stipe init
- [ ] Default is baseline when user skips
- [ ] Config file written to correct path
- [ ] Idempotent: running init twice doesn't corrupt the file
- [ ] Tests and clippy pass

---

## Completion Protocol

1. `~/.config/volva/config.toml` is written by `stipe init` with the user's chosen mode
2. `volva` reads this file as the default mode (CLI `--mode` still overrides)
3. `volva doctor` reflects the correct default mode without needing `--mode` on the command line
4. Default is baseline when file is missing or mode is unrecognized
5. Dashboard updated

### Final Verification

```bash
# Write baseline config
echo 'mode = "baseline"' > ~/.config/volva/config.toml
volva doctor 2>&1 | grep -i "baseline\|mode"

# Write orchestration config
echo 'mode = "orchestration"' > ~/.config/volva/config.toml
volva doctor 2>&1 | grep -i "orchestration\|mode"

# --mode flag overrides config
echo 'mode = "orchestration"' > ~/.config/volva/config.toml
volva --mode baseline doctor 2>&1 | grep -i "baseline\|mode"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] stipe init prompts for mode
- [ ] ~/.config/volva/config.toml written with correct mode
- [ ] volva reflects global config as default
- [ ] --mode flag overrides global config
- [ ] Missing config defaults to baseline
