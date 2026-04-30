# Ecosystem Health Audit Fix Campaign — 2026-04-30

**Started:** 2026-04-30
**Status:** In Progress

## Purpose

Fix phase for the Ecosystem Health Audit (2026-04-22). The audit found 16 issues
across 5 phases. A verification pass on 2026-04-30 confirmed that many issues were
already closed in the interim. This campaign tracks the remaining open work.

## Verification Pass Summary (2026-04-30)

Before creating handoffs, each open issue was verified against current code.

| # | Severity | Issue | Verified Status | Notes |
|---|----------|-------|----------------|-------|
| 4 | Medium | Cap `validateCanopySnapshot` missing drift_signals | **Already fixed** | Line 172 of cap/server/canopy.ts already checks `!asRecord(record.drift_signals)` |
| 8 | Low | Cortina rusqlite unused | **False positive** | Used in `cortina/src/utils/session_store.rs:2` |
| 9 | High | Session state orphaning | **Open** | File persists on failure; no subprocess timeout |
| 10 | High | Cap no fallback when canopy down | **Already fixed** | Stale-on-error cache in cap/server/routes/canopy.ts:19-84 |
| 11 | Medium | Hyphae protocol shapes unseamed | **Open** | No septa schemas for MemoryProtocolSurface or session-context |
| 12 | Medium | Async hook signal loss | **Downgraded/closed** | SessionEnd is synchronous; loss only on crash (unavoidable) |
| 13 | Medium | Lamella hook envelope not schema-backed | **Open (Low)** | Still no septa schema; low urgency |
| 14 | Medium | Volva timeouts fail silently | **Already fixed** | `tracing::warn!` at context.rs lines 233 and 299 |
| 15 | Medium | Cortina no internal subprocess timeout | **Open** | `run_command` = `Command::output` with no timeout |
| 16 | Low | Cap canopy error swallowed | **Already fixed** | `err instanceof Error ? err.message : '...'` in all canopy route handlers |

**Net open work: 3 items** (issues #9+#15 together in cortina, #11 in septa, #13 in septa low-priority)

## Active Handoffs

| Handoff | Repos | Priority | Status |
|---------|-------|----------|--------|
| [Septa: Hyphae Protocol Schema](../../septa/hyphae-protocol-schema.md) | septa | Medium | Open |
| [Septa: Hook Envelope Schema](../../septa/hook-envelope-schema.md) | septa | Low | Open |

## Done

| Handoff | Done | Notes |
|---------|------|-------|
| [Cortina: Session Resilience — Timeout and Cleanup](../../cortina/session-resilience-timeout-and-cleanup.md) | 2026-04-30 | State file removed on both failure paths; run_with_timeout (5s) wired into end_scoped_hyphae_session |
