# Codex Host Adapter

## Problem

The ecosystem had Claude Code-specific seams in three places: hyphae only ingested Claude Code transcripts, mycelium onboarding was Claude-first, and cap treated missing Claude hooks as a broken setup rather than a different host. Codex and Cursor users got a degraded or broken experience.

## What exists (state)

- **hyphae**: `hyphae-ingest/src/transcript.rs` parses Claude Code `.jsonl` transcripts only
- **hyphae-cli**: `codex_notify.rs` exists but is a stub — stores only `agent-turn-complete`
- **mycelium**: host-aware onboarding/setup now lives under `init/onboard.rs` and `init/host_status.rs`
- **cap**: `usage.ts` checks Claude Code session files — shows errors for Codex setups
- **stipe**: install guidance is Claude Code-first in doctor output

## What needs doing (intent)

Phase 1: Add a real Codex event adapter path in hyphae and update cap to report host adapter health honestly.
Phase 2: Normalize host events and add lifecycle health to cap.
Phase 3: Host-aware onboarding in mycelium.

---

### Step 1: Hyphae Codex event adapter (Phase 1)

**Project:** `hyphae/`
**Effort:** 2-3 hours
**Depends on:** nothing

Expand `hyphae-cli/src/commands/codex_notify.rs` beyond `agent-turn-complete`. Support `session_start`, `session_end`, `tool_use`, and `tool_result` event types. Normalize into the same internal `SessionEvent` shape used by transcript ingestion. Wire via `hyphae codex-notify --event <type> --data <json>`.

#### Verification

```bash
cd hyphae && cargo build --workspace --no-default-features 2>&1 | tail -5
cargo test --workspace --no-default-features 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
- `cargo test -p hyphae-cli codex_notify --no-default-features --quiet` passed
- Codex session and tool events now normalize into the Hyphae session-event ingestion path
<!-- PASTE END -->

**Checklist:**
- [x] `codex_notify` handles `session_start`, `session_end`, `tool_use`, `tool_result`
- [x] Events normalize to internal session event shape
- [x] Build and tests pass

---

### Step 2: Cap host adapter health reporting (Phase 1)

**Project:** `cap/`
**Effort:** 1-2 hours
**Depends on:** nothing (parallel with Step 1)

In `cap/server/lib/usage.ts` and the health/status route, replace Claude-specific session file checks with a host-agnostic adapter health check. Report `host: "claude-code" | "codex" | "cursor" | "unknown"` and `adapter_status: "connected" | "partial" | "none"` rather than treating missing Claude hooks as an error.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->
- `npm run test:server -- server/__tests__/status-checks.test.ts server/__tests__/status-health.test.ts server/__tests__/onboarding.test.ts` passed
- `npm run build` passed
<!-- PASTE END -->

**Checklist:**
- [x] Health check no longer fails for Codex setups
- [x] `host` and `adapter_status` fields present in status response
- [x] Build passes

---

### Step 3: Host-aware mycelium onboarding and host detection (Phase 3)

**Project:** `mycelium/`
**Effort:** 2 hours
**Depends on:** Steps 1-2

In `mycelium init --onboard`, detect the active host (Claude Code, Codex, Cursor) and route setup guidance accordingly. The shipped implementation uses `init/onboard.rs` and `init/host_status.rs` rather than the older `run_ecosystem()` path named in the original plan.

#### Verification

```bash
cd mycelium && cargo build && cargo test && cargo clippy 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
- `cargo test` passed in `mycelium`
- `mycelium init --onboard` now offers Codex-aware MCP patch/setup guidance without regressing Claude Code
<!-- PASTE END -->

**Checklist:**
- [x] Host detection logic lives in the current onboarding/host-status flow
- [x] Codex path is handled in host-aware onboarding/setup guidance without regressing Claude Code
- [x] Claude Code path unchanged
- [x] Build and tests pass

---

## Completion Protocol

1. All step verification output pasted
2. `cd hyphae && cargo build --no-default-features && cargo test --no-default-features` passes
3. `cd mycelium && cargo build && cargo test` passes
4. `cd cap && npm run build` passes

## Context

From `.plans/agent-agnostic.md` and `.plans/codex-host-adapter-phase-1.md` through `phase-3.md`. The ecosystem works with any MCP client for reads; this closes the session lifecycle and init gaps that still assume Claude Code.
