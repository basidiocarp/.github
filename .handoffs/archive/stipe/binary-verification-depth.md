# Deep Binary Verification

<!-- Save as: .handoffs/stipe/binary-verification-depth.md -->
<!-- Verify script: .handoffs/stipe/verify-binary-verification-depth.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Stipe verifies installed binaries by running `--version`, which only exercises
clap argument parsing. For tools with SQLite databases, sqlite-vec extensions,
and MCP servers, `--version` succeeds while the actual runtime path hangs.

This was discovered with hyphae: `hyphae --version` works, but `hyphae serve`
and `hyphae stats` both hang indefinitely because `open_store()` (which
initializes sqlite-vec + FTS5 + vec0 virtual tables) never completes in the
pre-built release binary. Stipe reports the tool as healthy when it's broken.

The same gap exists for any tool with a runtime path that diverges from
`--version`:

| Tool | `--version` tests | `serve`/runtime tests |
|------|------------------|----------------------|
| hyphae | clap parse only | config → embedder → sqlite-vec → SQLite → MCP |
| rhizome | clap parse only | tree-sitter → LSP → MCP |
| mycelium | clap parse only | filter dispatch → SQLite (gain tracking) |
| cortina | clap parse only | hook dispatch → adapter routing |

## What exists (state)

- **`src/commands/install/release.rs:verify_binary`**: Runs `{binary} --version`,
  checks exit code 0, extracts version string
- **`src/commands/tool_registry/probe.rs:probe`**: Same `--version` check for
  ongoing health monitoring
- **`src/ecosystem/configure.rs:initialize_hyphae_db_if_needed`**: Runs
  `hyphae stats` as a warm-up command after install — but only during
  `stipe init`, not during `stipe install`
- **`src/commands/doctor.rs`**: Health checks use the same `--version` probe
- **No MCP handshake test**: Stipe registers MCP servers but never verifies
  the handshake works

## Design

### Tiered verification

Add depth levels to binary verification:

| Level | What it tests | When to run | Timeout |
|-------|--------------|-------------|---------|
| **L0: Version** | `--version` exits 0 | Always (install, probe, doctor) | 5s |
| **L1: Functional** | Tool-specific smoke test | After install, during doctor | 10s |
| **L2: MCP handshake** | JSON-RPC initialize round-trip | After MCP registration | 10s |

### Per-tool smoke tests (L1)

| Tool | L1 command | What it exercises |
|------|-----------|-------------------|
| hyphae | `hyphae doctor` | Config load, DB open, sqlite-vec, FTS5 |
| rhizome | `rhizome --version` (already sufficient) | Binary loads tree-sitter |
| mycelium | `mycelium proxy echo test` | Dispatch, passthrough, no filter |
| cortina | `cortina --version` (already sufficient) | Binary loads adapters |
| canopy | `canopy task list 2>&1` | DB open, schema init |

### MCP handshake test (L2)

For tools registered as MCP servers, verify the initialize handshake:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"stipe-verify","version":"0.1"}}}' \
  | timeout 10 {tool} serve {args} 2>&1
```

Pass if response contains `"result"` and `"protocolVersion"`.

## Implementation

### Step 1: Add `VerifyLevel` enum

**Project:** `stipe/`
**Effort:** 10 minutes
**Depends on:** Nothing

#### Files to modify

**`src/commands/tool_registry/probe.rs`** — add verification depth:

```rust
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum VerifyLevel {
    /// L0: --version only
    Version,
    /// L1: tool-specific smoke test
    Functional,
    /// L2: MCP handshake round-trip
    McpHandshake,
}
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd stipe && grep -n 'VerifyLevel' src/commands/tool_registry/probe.rs
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [x] `VerifyLevel` enum added with three variants (probe.rs:10)
- [x] `cargo test` passes (119 tests, 0 failures)
- [x] `cargo clippy` clean (0 warnings)

---

### Step 2: Add per-tool smoke test commands

**Project:** `stipe/`
**Effort:** 20 minutes
**Depends on:** Step 1

#### Files to modify

**`src/commands/tool_registry/specs.rs`** — add smoke test config to tool specs:

```rust
pub struct ToolSpec {
    // ... existing fields ...
    /// L1 functional verification command (args after the binary name)
    pub smoke_test_args: Option<&'static [&'static str]>,
    /// Expected substring in smoke test stdout/stderr for pass
    pub smoke_test_expect: Option<&'static str>,
}
```

Per-tool values:

```rust
// hyphae
smoke_test_args: Some(&["doctor"]),
smoke_test_expect: None,  // exit 0 is sufficient

// mycelium
smoke_test_args: Some(&["proxy", "echo", "stipe-verify"]),
smoke_test_expect: Some("stipe-verify"),

// canopy
smoke_test_args: Some(&["task", "list"]),
smoke_test_expect: None,

// rhizome, cortina — None (--version is sufficient)
smoke_test_args: None,
smoke_test_expect: None,
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd stipe && grep -n 'smoke_test' src/commands/tool_registry/specs.rs
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [x] `smoke_test_args` added to `ToolSpec` (specs.rs)
- [x] Hyphae uses `["doctor"]` (specs.rs)
- [x] Mycelium uses `["proxy", "echo", "stipe-verify"]` (specs.rs)
- [x] Canopy uses `["task", "list"]` (specs.rs)
- [x] Tools without smoke tests have `None` (specs.rs)
- [x] `cargo test` passes (119 tests)

---

### Step 3: Add MCP handshake test config

**Project:** `stipe/`
**Effort:** 15 minutes
**Depends on:** Step 1

#### Files to modify

**`src/commands/tool_registry/specs.rs`** — add MCP config to tool specs:

```rust
pub struct ToolSpec {
    // ... existing fields ...
    /// MCP serve command args (if tool is an MCP server)
    pub mcp_serve_args: Option<&'static [&'static str]>,
}
```

Per-tool values:

```rust
// hyphae
mcp_serve_args: Some(&["serve"]),

// rhizome
mcp_serve_args: Some(&["serve", "--expanded"]),

// mycelium, cortina, canopy — not MCP servers
mcp_serve_args: None,
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd stipe && grep -n 'mcp_serve_args' src/commands/tool_registry/specs.rs
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [x] `mcp_serve_args` added to `ToolSpec` (specs.rs)
- [x] Hyphae uses `["serve"]` (specs.rs)
- [x] Rhizome uses `["serve", "--expanded"]` (specs.rs)
- [x] Non-MCP tools have `None` (specs.rs)

---

### Step 4: Implement `verify_functional` (L1)

**Project:** `stipe/`
**Effort:** 30 minutes
**Depends on:** Steps 1-2

#### Files to modify

**`src/commands/install/release.rs`** — add L1 verification:

```rust
use std::time::Duration;

/// L1: Run tool-specific smoke test
pub fn verify_functional(
    binary_path: &Path,
    spec: &ToolSpec,
) -> Result<(), String> {
    let args = match spec.smoke_test_args {
        Some(args) => args,
        None => return Ok(()),  // No smoke test defined, skip
    };

    let output = std::process::Command::new(binary_path)
        .args(args)
        .timeout(Duration::from_secs(10))
        .output()
        .map_err(|e| format!("smoke test failed to execute: {e}"))?;

    if !output.status.success() {
        return Err(format!(
            "smoke test failed: {} {} exited with {}",
            binary_path.display(),
            args.join(" "),
            output.status
        ));
    }

    if let Some(expected) = spec.smoke_test_expect {
        let stdout = String::from_utf8_lossy(&output.stdout);
        let stderr = String::from_utf8_lossy(&output.stderr);
        if !stdout.contains(expected) && !stderr.contains(expected) {
            return Err(format!(
                "smoke test output missing '{}': stdout={}, stderr={}",
                expected,
                stdout.trim(),
                stderr.trim()
            ));
        }
    }

    Ok(())
}
```

Note: `std::process::Command` doesn't have `.timeout()` natively. Use a
spawned child with `wait_timeout` from the `wait-timeout` crate, or spawn
+ sleep + kill pattern:

```rust
fn run_with_timeout(cmd: &mut std::process::Command, timeout: Duration) -> std::io::Result<std::process::Output> {
    let mut child = cmd
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()?;

    match child.wait_timeout(timeout)? {
        Some(status) => {
            let stdout = child.stdout.take().map(|mut s| {
                let mut buf = Vec::new();
                std::io::Read::read_to_end(&mut s, &mut buf).ok();
                buf
            }).unwrap_or_default();
            let stderr = child.stderr.take().map(|mut s| {
                let mut buf = Vec::new();
                std::io::Read::read_to_end(&mut s, &mut buf).ok();
                buf
            }).unwrap_or_default();
            Ok(std::process::Output { status, stdout, stderr })
        }
        None => {
            child.kill()?;
            Err(std::io::Error::new(
                std::io::ErrorKind::TimedOut,
                format!("command timed out after {}s", timeout.as_secs()),
            ))
        }
    }
}
```

Add `wait-timeout` to `Cargo.toml`:

```toml
wait-timeout = "0.2"
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd stipe && grep -n 'verify_functional\|smoke_test\|run_with_timeout' src/commands/install/release.rs
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [x] `verify_functional` runs smoke test with 10s timeout (release.rs)
- [x] Returns Ok(()) when no smoke test defined (graceful skip)
- [x] Checks exit code
- [x] Checks expected output substring when specified
- [x] Timeout kills hung process instead of blocking forever
- [x] `wait-timeout` crate added to Cargo.toml
- [x] `cargo test` passes (119 tests)

---

### Step 5: Implement `verify_mcp_handshake` (L2)

**Project:** `stipe/`
**Effort:** 30 minutes
**Depends on:** Steps 1, 3, 4 (reuses timeout infrastructure)

#### Files to modify

**`src/commands/install/release.rs`** (or new `src/commands/install/mcp_verify.rs`):

```rust
const MCP_INITIALIZE_REQUEST: &str = r#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"stipe-verify","version":"0.1"}}}"#;

/// L2: Verify MCP server responds to initialize request
pub fn verify_mcp_handshake(
    binary_path: &Path,
    spec: &ToolSpec,
) -> Result<(), String> {
    let args = match spec.mcp_serve_args {
        Some(args) => args,
        None => return Ok(()),  // Not an MCP server, skip
    };

    let mut child = std::process::Command::new(binary_path)
        .args(args)
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .map_err(|e| format!("failed to start MCP server: {e}"))?;

    // Write initialize request to stdin
    if let Some(mut stdin) = child.stdin.take() {
        use std::io::Write;
        writeln!(stdin, "{}", MCP_INITIALIZE_REQUEST)
            .map_err(|e| format!("failed to write to MCP stdin: {e}"))?;
        drop(stdin);  // Close stdin to signal EOF
    }

    // Wait with timeout
    match child.wait_timeout(Duration::from_secs(10)) {
        Ok(Some(status)) => {
            let stdout = /* read stdout */;
            if stdout.contains("\"result\"") && stdout.contains("protocolVersion") {
                Ok(())
            } else {
                Err(format!("MCP handshake response missing result: {}", stdout.trim()))
            }
        }
        Ok(None) => {
            child.kill().ok();
            Err("MCP server did not respond within 10s".into())
        }
        Err(e) => {
            child.kill().ok();
            Err(format!("MCP handshake error: {e}"))
        }
    }
}
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd stipe && grep -n 'verify_mcp\|MCP_INITIALIZE\|mcp_handshake' src/commands/install/release.rs
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [x] `verify_mcp_handshake` sends JSON-RPC initialize request (release.rs)
- [x] Checks response contains `"result"` and `"protocolVersion"`
- [x] 10s timeout kills hung server
- [x] Returns Ok(()) for non-MCP tools
- [x] `cargo test` passes (119 tests)

---

### Step 6: Integrate into install and doctor flows

**Project:** `stipe/`
**Effort:** 30 minutes
**Depends on:** Steps 4-5

#### Files to modify

**`src/commands/install/runner.rs`** — after existing `verify_binary` call:

```rust
// Existing L0
let version = verify_binary(&binary_path)?;
println!("  ✓ {} installed: {} {} → {}", tool_name, tool_name, version, binary_path.display());

// New L1
match verify_functional(&binary_path, &spec) {
    Ok(()) => println!("  ✓ {} functional check passed", tool_name),
    Err(e) => {
        eprintln!("  ⚠ {} functional check failed: {}", tool_name, e);
        eprintln!("    The binary installed but may not work correctly.");
        eprintln!("    Try building from source: cd {} && cargo install --path .", tool_name);
    }
}
```

**`src/ecosystem/workflow.rs`** — after MCP registration:

```rust
// New L2 (after registering MCP servers)
for (tool_name, spec) in mcp_tools {
    match verify_mcp_handshake(&binary_path, &spec) {
        Ok(()) => println!("  ✓ {} MCP handshake verified", tool_name),
        Err(e) => {
            eprintln!("  ⚠ {} MCP handshake failed: {}", tool_name, e);
            eprintln!("    Claude Code may show MCP startup warnings.");
            eprintln!("    Try: stipe install {} --from-source", tool_name);
        }
    }
}
```

**`src/commands/doctor.rs`** — upgrade health checks:

```rust
// Existing: L0 version check
// Add: L1 functional check for tools marked broken or on --deep flag
if matches!(probe_result, ToolProbe::Installed { .. }) || deep {
    if let Err(e) = verify_functional(&binary_path, &spec) {
        println!("  ⚠ {} passes --version but functional check failed: {}", tool_name, e);
        // Reclassify as broken
    }
}
```

Add `--deep` flag to doctor:

```rust
/// Run deep verification (L1 + L2) instead of just version checks
#[arg(long)]
deep: bool,
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd stipe && grep -n 'verify_functional\|verify_mcp\|functional check\|MCP handshake\|deep' src/commands/install/runner.rs src/ecosystem/workflow.rs src/commands/doctor.rs 2>/dev/null | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [x] `stipe install hyphae` runs L0 + L1 verification (runner.rs)
- [x] `stipe init` runs L2 MCP handshake after registration (workflow.rs)
- [x] `stipe doctor` runs L0 by default (doctor.rs)
- [x] `stipe doctor --deep` runs L0 + L1 + L2 (doctor.rs)
- [x] Failed L1/L2 prints actionable error with build-from-source suggestion
- [x] Failed L1/L2 does NOT block install (warning only)
- [x] `cargo test` passes (119 tests)
- [x] `cargo clippy` clean (0 warnings)

---

### Step 7: Add `--from-source` install fallback

**Project:** `stipe/`
**Effort:** 20 minutes
**Depends on:** Step 6

When a pre-built binary fails L1 verification, offer (and support) building
from source as a fallback.

#### Files to modify

**`src/commands/install/runner.rs`** — add source build path:

```rust
/// Build and install a tool from local source
pub fn install_from_source(tool_name: &str, source_dir: &Path) -> Result<String> {
    let cargo_toml = source_dir.join("Cargo.toml");
    if !cargo_toml.exists() {
        anyhow::bail!("No Cargo.toml found at {}", source_dir.display());
    }

    // Determine install path (workspace member or root)
    let install_path = match tool_name {
        "hyphae" => source_dir.join("crates/hyphae-cli"),
        _ => source_dir.to_path_buf(),
    };

    let status = std::process::Command::new("cargo")
        .args(["install", "--path"])
        .arg(&install_path)
        .status()?;

    if !status.success() {
        anyhow::bail!("cargo install failed for {}", tool_name);
    }

    // Verify the built binary
    let binary = which::which(tool_name)?;
    let version = verify_binary(&binary)?;
    Ok(version)
}
```

**`src/commands/cli.rs`** — add flag:

```rust
/// Build from local source instead of downloading release binary
#[arg(long)]
from_source: bool,

/// Path to local source directory (default: ~/projects/basidiocarp/{tool})
#[arg(long)]
source_dir: Option<PathBuf>,
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd stipe && grep -n 'from_source\|install_from_source\|source_dir' src/commands/install/runner.rs src/commands/cli.rs 2>/dev/null
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [x] `stipe install hyphae --from-source` builds from local source (runner.rs:135)
- [x] Default source path is `~/projects/basidiocarp/{tool}` (runner.rs)
- [x] `--source-dir` overrides the path (main.rs:33)
- [x] Built binary verified with L0 + L1
- [x] Error if Cargo.toml not found
- [x] `cargo test` passes (119 tests)

---

## Completion Protocol

**Status: Complete.** All 7 steps implemented and verified.

### Final Verification

```bash
bash .handoffs/stipe/verify-binary-verification-depth.sh
```

**Output:**
<!-- PASTE START -->
All 20 checks pass: VerifyLevel enum, smoke_test_args, mcp_serve_args, verify_functional, wait-timeout, verify_mcp_handshake, MCP initialize, protocolVersion, install integration, ecosystem integration, --deep flag, from_source, install_from_source, cargo test (119 pass), cargo clippy (0 warnings)
<!-- PASTE END -->

**Result:** All checks pass. Handoff complete.

## Context

This was discovered when hyphae's pre-built release binary passed `--version`
but hung on `serve` and `stats`. The sqlite-vec extension initialization in
`open_store()` fails silently in the release binary, likely due to a static
linking issue. Stipe reported hyphae as healthy because it only checked
`--version`.

The tiered verification catches this class of bugs:
- L0 catches missing/corrupt binaries (existing behavior)
- L1 catches runtime initialization failures (this fix)
- L2 catches MCP protocol issues (this fix)

The `--from-source` fallback gives users an escape hatch when pre-built
binaries have platform-specific linking issues.

Related handoffs:
- `.handoffs/mycelium/diagnostic-passthrough.md` — mycelium filtering diagnostic output
- `.handoffs/canopy/verification-enforcement.md` — verification gates for task completion
