# Stipe: Doctor Cursor Host Gating (Lane 1 concern)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/commands/doctor/host_checks.rs` (or wherever Cursor host detection runs) and any related test fixtures
- **Cross-repo edits:** none
- **Non-goals:** does not change the doctor JSON shape; does not modify other host-mode checks
- **Verification contract:** `bash .handoffs/stipe/verify-doctor-cursor-host-gating.sh`
- **Completion update:** Stage 1 + Stage 2 review pass → commit → dashboard

## Problem (Lane 1 concern)

`stipe doctor --json` returns `healthy: false` on a host that doesn't have Cursor installed, because two host-mode checks fail with `"Cursor not detected"`. This is a false alarm: Cursor is optional and shouldn't fail the doctor unless the operator opted into Cursor host-mode.

The output **shape** is correct — schema-conformant, structured `repair_actions` — so cap's settings panel works. But operators reading `healthy: false` see a phantom problem.

## Step 1 — Locate the Cursor host check

```bash
grep -rnE 'Cursor.*not detected|cursor_host|HostMode::Cursor' stipe/src/ --include='*.rs'
```

## Step 2 — Gate it

Add an opt-in mechanism (config flag, env var, or detected-only-when-installed gate) so the Cursor check only runs when:
- Cursor is detectable on the host (binary in PATH, config file present), OR
- The operator has explicitly opted into Cursor support (e.g. `STIPE_CURSOR_HOST=1` or `cursor: true` in stipe config).

When neither condition is met, omit the Cursor checks from the doctor's check list entirely (don't emit them as `passed: false`). This way `healthy: true` reflects "all enabled checks pass" without the phantom Cursor failures.

If there's no clean signal for "Cursor opt-in", the safest default is "skip Cursor unless the binary is on PATH". Operators using Cursor will have it on PATH; everyone else won't.

## Step 3 — Tests

Add or update a test that:
- Runs the doctor with no Cursor install present and asserts the Cursor check is **absent** from the report (not just `passed: false`).
- Runs the doctor with Cursor mocked-as-present and asserts the check **runs** (passed or failed depending on mock state).

## Step 4 — Build + test

```bash
cd /Users/williamnewton/projects/personal/basidiocarp/stipe && cargo test --release
```

## Verify Script

`bash .handoffs/stipe/verify-doctor-cursor-host-gating.sh` confirms:
- Some gating logic exists for Cursor host-mode checks (env var / config / PATH detection)
- Cursor check is conditional on detection
- Tests pass

## Context

Closes the lane 1 concern about stipe doctor false-alarming `healthy: false`. Doesn't affect the F1 #1 core loop directly but improves operator signal-to-noise.
