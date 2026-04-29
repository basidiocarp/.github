# Spore: Shared Primitive Quality

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `spore`
- **Allowed write scope:** `spore/src/logging.rs`, `spore/src/subprocess.rs`, `spore/src/discovery.rs`, `spore/tests/`, `spore/README.md`
- **Cross-repo edits:** none; consumer updates belong in separate repo handoffs unless Spore intentionally changes a public API
- **Non-goals:** no new telemetry backend and no workspace-wide dependency bump
- **Verification contract:** run the repo-local commands below and `bash .handoffs/spore/verify-shared-primitive-quality.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `spore`
- **Likely files/modules:** `src/logging.rs`, `src/subprocess.rs`, `src/discovery.rs`, README development section
- **Reference seams:** current consumers of Spore logging config in Stipe, Canopy, Volva; Spore CI commands
- **Spawn gate:** do not launch an implementer until the parent agent confirms whether the dirty logging API change should remain public or be made compatibility-preserving

## Problem

The audit found a dirty Spore logging API change that can break current consumers if released, MCP subprocess cleanup paths that kill children without waiting, and README drift around the current version and CI verification commands.

The runtime safety audit also found `discover()` probes tools with `--version` using an unbounded child process; because discovery is cached behind `OnceLock`, a hung probe can block the first caller and every status path waiting on it.

## What needs doing

1. Preserve logging API compatibility, for example with `impl Borrow<LoggingConfig>`, or coordinate all consumer updates in the same release.
2. After `kill()`, call `wait()` best-effort in subprocess timeout/restart/drop cleanup paths.
3. Add bounded deadlines and cleanup to discovery `--version` probes.
4. Update README dependency example from stale `v0.4.9` to current `v0.4.11` or point to `ecosystem-versions.toml`.
5. Make README verification commands mirror CI: `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test`.

## Verification

```bash
cd spore && cargo test
cd spore && cargo test discovery
cd spore && cargo clippy -- -D warnings
cd spore && cargo fmt --check
bash .handoffs/spore/verify-shared-primitive-quality.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] logging API does not break existing consumers unexpectedly
- [ ] subprocess cleanup waits after kill in timeout/restart/drop paths
- [ ] discovery `--version` probes cannot hang indefinitely
- [ ] README version example matches `ecosystem-versions.toml`
- [ ] README green path matches CI
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 Rust ecosystem audit. Severity: high/medium plus docs drift. Spore had a dirty worktree during audit, so recheck current diff before implementing.
