# Stipe: Install and update quality fixes (round 2)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** stipe/...
- **Cross-repo edits:** none
- **Non-goals:** tar security fix (separate handoff), backup correctness (separate handoff), quality-fixes round 1 (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — Rollback doctor errors discarded, false-positive success (HIGH)
`src/commands/rollback.rs:82-84`

Post-restore `stipe doctor` failure is caught with `eprintln!` and the function returns `Ok(())`. The user sees a success message after a broken rollback. Propagate the error or at minimum exit with a non-zero status so the operator knows doctor failed.

### 2 — codesign invoked with empty path (HIGH)
`src/commands/install/runner.rs:97`

`install_path.to_str().unwrap_or("")` passes an empty string to `codesign --sign - ""` on non-UTF-8 paths. The error is discarded with `let _ = ...`. On macOS this deploys the binary without an ad-hoc signature, causing Gatekeeper kill on first run. Use `install_path.display()` or propagate a proper error when the path is not valid UTF-8.

### 3 — Busy-poll in run_command_with_timeout (MEDIUM)
`src/commands/install/release.rs:424-436`

10ms sleep × up to 500 iterations per subprocess. Called during `stipe doctor` across all installed tools. Replace with a blocking wait with a deadline (e.g. `child.wait_timeout` from `wait-timeout` crate, or reuse the channel pattern already used in `probe_mcp_server`).

### 4 — Version extraction inconsistency (MEDIUM)
`src/commands/update.rs:30-33`

`get_installed_version` uses `split_whitespace().last()`. `verify_binary_with_timeout` uses full trimmed stdout. If a binary appends metadata to its version line, these produce different strings and `check_tool_update` may miss available updates. Align both to the same extraction strategy.

### 5 — hyphae initialisation uses bare binary name (MEDIUM)
`src/ecosystem/configure.rs:129`

`Command::new("hyphae").arg("stats")` fails with a misleading error if hyphae was just installed to `~/.local/bin/` and PATH hasn't been refreshed. Resolve the binary path from the tool registry as `verify_registered_mcp_servers` already does.

### 6 — register_mcp shells out to bare "claude" without availability guard (MEDIUM)
`src/ecosystem/mcp.rs:80`

The error message on failure doesn't indicate that Claude Code itself may be missing. The `claude_is_available()` guard in `workflow.rs` is bypassed when reaching `register_mcp` via non-primary client paths. Add an availability check inside `register_mcp` or improve the error message.

### 7 — ProgressStyle::template(...).unwrap() in install hot path (MEDIUM)
`src/commands/install/release.rs:56-62` and `src/commands/self_update.rs:109-115`

Replace `.unwrap()` with `.expect("valid progress bar template")` to surface the panic location, or propagate the error.

### 8 — auth_detail silent failure in doctor (MEDIUM)
`src/commands/doctor/provider_checks.rs:221-228`

`fs::metadata(...).modified()` errors treated as `None` in `max_by_key`. An unreadable config file silently produces no auth detail in the doctor report. Log the access error or surface it in the doctor output.

### 9 — Low severity items
- `runner.rs:150` — another `home_dir().unwrap_or(".")` fallback with no warning
- `update.rs:346` — backup labeled `"unknown"` when version fetch fails; warn and note in rollback list
- `ecosystem/clients/registration.rs:267` — `serde_json::from_str(...).unwrap_or_else(|_| json!({}))` silently destroys a corrupted config; log the parse error
- `release.rs:185` — version verification reads stdout; some tools write to stderr

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/stipe
cargo test 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

## Checklist

- [ ] Rollback doctor failure propagated or causes non-zero exit
- [ ] codesign non-UTF-8 path handled; error not discarded
- [ ] `run_command_with_timeout` uses blocking wait, not busy-poll
- [ ] Version extraction strategy consistent across `get_installed_version` and `verify_binary_with_timeout`
- [ ] hyphae initialisation uses resolved binary path
- [ ] `register_mcp` availability guard or improved error message
- [ ] `ProgressStyle::template` panic replaced with expect or propagated
- [ ] auth_detail failure logged in doctor report
- [ ] Low severity items addressed
- [ ] All tests pass, clippy clean
