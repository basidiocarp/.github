# Ecosystem Drift Follow-Up Audit (2026-04-30)

Read-only audit campaign. Validates F1 exit criteria the prior
[Post-Execution Boundary Compliance Audit (2026-04-29)](../post-execution-boundary-audit-2026-04-29/README.md)
did not directly check.

The prior campaign's three lanes covered:
- Boundary compliance (CLI coupling table accuracy)
- Septa contract accuracy from the **consumer** side
- Low queue prioritization

This campaign covers what those lanes did not:

| Lane | Closes which gap | Maps to F1 |
|------|------------------|------------|
| 1 — End-to-End Smoke | Static schema checks pass; nothing has actually run the core loop end-to-end. | Exit criterion #1 (core loop works end-to-end). |
| 2 — Producer-Side Schema Drift | Lane 2 of prior campaign audited consumers vs schemas; never deeply audited that producers still emit matching shapes. | Exit criterion #2 (validate-all.sh stays green AND producers haven't drifted from it). |
| 3 — Shared Version Pin Drift | `ecosystem-versions.toml` documents shared pins (especially `spore`); per-repo `Cargo.toml` may have drifted silently. | Operational hygiene; not directly an exit criterion but blocks F1 if it surfaces ABI mismatches. |
| 4 — MCP Surface vs CLAUDE.md | mycelium / hyphae / rhizome are MCP servers consumed by Claude Code; tool-name drift breaks `mcp__*` calls in `CLAUDE.md` instructions. | Operator-loop reliability under F1. |

## Lanes

Each lane runs in parallel against a disjoint write surface (`findings/<lane>.md`).

| Lane | Handoff | Findings file |
|------|---------|---------------|
| 1 | [lane1-end-to-end-smoke.md](lane1-end-to-end-smoke.md) | `findings/lane1-end-to-end-smoke.md` |
| 2 | [lane2-producer-schema-drift.md](lane2-producer-schema-drift.md) | `findings/lane2-producer-schema-drift.md` |
| 3 | [lane3-version-pin-drift.md](lane3-version-pin-drift.md) | `findings/lane3-version-pin-drift.md` |
| 4 | [lane4-mcp-surface-drift.md](lane4-mcp-surface-drift.md) | `findings/lane4-mcp-surface-drift.md` |

## Evaluation Lens

The same F1 lens as the prior campaign applies. The exit criteria
are at [`docs/foundations/core-hardening-freeze-roadmap.md`](/Users/williamnewton/projects/personal/basidiocarp/docs/foundations/core-hardening-freeze-roadmap.md).

## Out of Scope

- Producer or consumer migrations (those become fix-phase handoffs)
- Schema redesign (use the existing septa contract governance flow)
- Per-repo CLAUDE.md drift (deferred — analog of A50 work)
- Hyphae DB schema integrity (defer until a hyphae migration triggers it)
- Lamella content link integrity (lamella is frozen)

## Completion

Each lane is complete when its findings file exists and its verify
script exits 0. The campaign is complete when all four lanes are
complete. Findings become input to a fix-phase pass that opens
specific handoffs.

After completion, the methodologies used here are extracted into
[`templates/audits/`](/Users/williamnewton/projects/personal/basidiocarp/templates/audits/)
so they can be re-run on a cadence without re-deriving the approach.
