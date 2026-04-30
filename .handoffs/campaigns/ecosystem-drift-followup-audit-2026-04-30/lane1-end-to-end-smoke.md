# Audit Lane 1: End-to-End Smoke

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only across all subprojects)
- **Allowed write scope:** `.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/findings/lane1-end-to-end-smoke.md`
- **Cross-repo edits:** none — read-only audit. May spawn ecosystem CLIs (cortina, hyphae, mycelium, canopy, stipe, annulus) and observe behavior, but must not modify state.
- **Non-goals:** does not fix any flow that breaks; does not modify any source; does not run destructive commands (no `stipe install`, no `hyphae forget`, no DB writes beyond what read-only flows naturally do).
- **Verification contract:** `bash .handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/verify-lane1-end-to-end-smoke.sh`
- **Completion update:** when findings file is written and verification is green, parent updates campaign README + dashboard.

## Problem

Static schema checks pass on every shape but nothing has actually exercised the core ecosystem loop end-to-end since the F1 freeze began. F1 exit criterion #1 demands "core loop works end-to-end (cortina → hyphae → mycelium → rhizome → cap)" — that's an unverified claim today.

## Scope

Run a fixed set of minimal, non-destructive flows. For each flow:
- Capture the command(s) run and the actual output.
- Note any error, warning, missing field, or unexpected shape.
- Severity: `blocker` (flow fails), `concern` (flow works but degrades or warns), `nit` (cosmetic).

Do **not** redesign or extend the flow set during the run — if a flow is unrunnable in the current environment, record that as a finding and move on.

## The smoke flows

Run each of these. Capture the full command output (or a summary if it's voluminous) into the findings file's "Per-flow Results" section.

### Flow 1 — Cortina session lifecycle → Hyphae ingest

```bash
# Verify the lifecycle event surface exists and emits something parseable
cortina --version
cortina adapter claude-code --help 2>&1 | head -10
# If a recent session-event-v1 payload exists in cortina's emit log, capture one and confirm it round-trips through hyphae's session ingest:
hyphae session list --limit 5
```

### Flow 2 — Hyphae memory recall

```bash
hyphae --version
hyphae stats --json
hyphae memory recall --query "test" --limit 3
```

### Flow 3 — Mycelium gain → Cap rendering surface

```bash
mycelium --version
mycelium gain --format json | head -40
# The cap consumer for this is cap/server/mycelium/gain.ts — confirm cap can parse the shape:
cd cap && grep -nE "schema_version|isGainCliOutput" server/mycelium/gain.ts | head -5
```

### Flow 4 — Rhizome MCP surface

```bash
rhizome --version
rhizome --help 2>&1 | head -10
# Spore-based discovery (the post-C7 typed availability check):
# Note actual command used; the goal is verifying the MCP server starts and exposes tools.
```

### Flow 5 — Canopy snapshot → Cap consumer

```bash
canopy --version
canopy api snapshot 2>&1 | head -40
# Optionally invoke the cap consumer path if cap is running:
# curl -s http://localhost:3001/api/canopy/snapshot | jq '.schema_version, .attention, .sla_summary, .drift_signals'
```

### Flow 6 — Stipe doctor → Cap settings

```bash
stipe --version
stipe doctor --json 2>&1 | head -40
```

### Flow 7 — Annulus status (post-F2.8 contract)

```bash
annulus --version
annulus status --json 2>&1 | head -20
# Should match septa/annulus-status-v1.schema.json — schema=annulus-status-v1, version=1, reports=[…]
```

### Flow 8 — Septa validator self-check (sanity)

```bash
cd septa && bash validate-all.sh 2>&1 | tail -3
```

## Findings file format

Write `findings/lane1-end-to-end-smoke.md` with sections:

- **Summary** — one paragraph, blocker/concern/nit counts.
- **Environment** — versions of each tool encountered (`<tool> --version` outputs collected).
- **Per-flow Results** — one subsection per flow above with the actual command output and the verdict (PASS / DEGRADED / FAIL / UNRUNNABLE).
- **Findings** — one entry per non-PASS flow, with location, evidence, why-it-matters (link to F1 #1), proposed handoff title.
- **Clean Areas** — flows that ran cleanly.

## Style Notes

- If a tool isn't installed in the environment, that's `UNRUNNABLE`, not a fail. Note it and move on.
- Don't propose fixes beyond the one-line "Proposed handoff" title.
- Don't escalate cosmetic warnings to blockers. A blocker is "flow does not produce usable output for its consumer."

## Completion Protocol

1. All flows attempted (passed, degraded, failed, or marked unrunnable).
2. Findings file written with the 5 sections above.
3. Verify script exits 0.

```bash
bash .handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/verify-lane1-end-to-end-smoke.sh
```

**Required result:** `Results: N passed, 0 failed`.
