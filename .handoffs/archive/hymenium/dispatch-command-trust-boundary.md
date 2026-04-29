# Hymenium: Dispatch Command Trust Boundary

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/commands/dispatch.rs`, `hymenium/src/dispatch/cli.rs`, `hymenium/src/dispatch/`, `hymenium/tests/`
- **Cross-repo edits:** none; Spore capability registry work belongs in the capability-dispatch handoff
- **Non-goals:** no full capability registry migration and no Canopy CLI behavior changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-dispatch-command-trust-boundary.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** dispatch command, CLI Canopy client, subprocess runner
- **Reference seams:** existing dispatch command tests, capability dispatch client handoff, workflow gate integration tests
- **Spawn gate:** do not launch an implementer until the parent agent decides whether the interim fix is a configured Canopy path, trusted discovery, or bounded CLI fallback only

## Problem

`hymenium dispatch` shells out to `canopy` from `PATH` with `.output()` and no deadline. A compromised or PATH-preferred binary can intercept dispatch payloads, inherit the environment, or hang orchestration indefinitely.

This is an interim hardening item. The longer-term direction may route through Spore capability discovery, but the current CLI fallback still needs a bounded and explicit trust boundary.

## What needs doing

1. Add bounded subprocess execution for Canopy CLI dispatch calls.
2. Use an explicit configured/trusted Canopy path or discovery result rather than blindly resolving `canopy` from ambient `PATH`.
3. Minimize inherited environment for the dispatch subprocess where practical.
4. Add tests with a fake `canopy` earlier in `PATH` that sleeps or records env.
5. Keep errors actionable when Canopy is not found or is rejected as untrusted.

## Verification

```bash
cd hymenium && cargo test dispatch
bash .handoffs/hymenium/verify-dispatch-command-trust-boundary.sh
```

**Output:**
<!-- PASTE START -->
PASS: dispatch tests pass
PASS: env_clear used in dispatch cli
PASS: timeout applied to canopy subprocess
PASS: explicit canopy path resolution
PASS: actionable error on canopy not found
Results: 5 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] dispatch subprocesses have deadlines and cleanup
- [x] ambient `PATH` cannot silently substitute an untrusted `canopy`
- [x] dispatch subprocess env is minimized or explicitly justified
- [x] tests cover fake PATH binaries and hanging dispatch calls
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 5 security and secrets audit. Severity: medium.
