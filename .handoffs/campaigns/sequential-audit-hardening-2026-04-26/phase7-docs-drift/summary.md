# Phase 7: Docs-To-Code Drift Audit Summary

**Status:** Complete
**Date:** 2026-04-26

## Result

Phase 7 audited README/AGENTS/CLAUDE/docs/manifests against current code behavior, command surfaces, repo ownership, generated output, release/install inventory, validation guidance, and handoff references.

## New Handoffs

| # | Handoff | Priority | Reason |
|---|---------|----------|--------|
| A49 | `hymenium/docs-and-cli-surface-drift.md` | High | Public docs advertise `run`, `serve`, `retry`, MCP server behavior, and stale module paths that do not match the current CLI. |
| A50 | `cap/dashboard-api-docs-drift.md` | Medium | API, route inventory, internals docs, and getting-started UI behavior drift from mounted routes and frontend code. |
| A51 | `lamella/docs-and-authoring-drift.md` | High | Operator commands, plugin/marketplace builder docs, hook authoring examples, inventory counts, and Codex manifest docs are stale. |
| A52 | `cross-project/workspace-docs-link-drift.md` | Medium | Foundation/workspace/research docs contain validator failures, missing active-handoff links, rendered command defects, and unavailable skill references. |
| A53 | `stipe/install-release-docs-drift.md` | High | Install/release docs omit tools present in Stipe's registry and misstate full-stack profile contents. |

## Folded Into Existing Handoffs

| Existing | Added finding |
|----------|---------------|
| A6 `cortina/capture-policy-boundary.md` | README still points `usage-event-v1` work at nonexistent `src/statusline.rs`. |
| A7 `annulus/operator-boundary-statusline-contracts.md` | Annulus docs still present read-only two-command behavior while `status`/`notify` exist and `notify --poll` can write Canopy state. |
| A16 `septa/validation-tooling-and-inventory.md` | `CROSS-TOOL-PAYLOADS.md` and README inventory miss current schema-backed payloads. |
| A21 `cap/api-auth-and-webhook-defaults.md` | Public Cap docs underdocument auth, CORS, webhook secrets, public routes, and local-dev bypass behavior. |
| A25 `cross-project/verification-command-and-script-hardening.md` | Troubleshooting shell pipes render incorrectly in Markdown tables; validation docs and release gates disagree in places. |
| A39 `cross-project/version-ledger-authority.md` | Hyphae release script claims all crates but omits `hyphae-ingest`. |
| A46 `cap/node-supply-chain-script-policy.md` | Cap release script and docs disagree on whether tests are part of release validation. |

## Notes

- The workspace/root lane reported top-level repos as absent based on `fd`; local `ls` confirmed the repos are present. The carried-forward issue is command-choice/documentation robustness, not missing repos.
- Full repo validation was not run as part of consolidation. The new verify scripts were syntax-checked only.
