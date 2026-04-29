# Phase 2 Summary: Runtime Safety Audit

**Status:** consolidated into active handoffs

## New Handoffs

- `rhizome/mcp-write-boundary-and-runtime-timeouts.md`: MCP root override can expand write authority; package-manager installs can hang.
- `canopy/mcp-handoff-runtime-boundaries.md`: handoff completeness can execute caller-selected sibling scripts; handoff import and file locks are too permissive.
- `hyphae/storage-and-ingest-runtime-safety.md`: WAL-unsafe backup/restore and unbounded/arbitrary ingest inputs.
- `stipe/install-hooks-and-secret-safety.md`: non-atomic install lock, unbounded install/repair subprocesses, plaintext key persistence, and generated hook divergence.
- `cap/api-auth-and-webhook-defaults.md`: API auth and webhook signatures fail open when secrets are unset.
- `lamella/session-logger-secret-redaction.md`: session logger can persist command-line secrets without redaction or restrictive permissions.
- `volva/backend-and-credential-runtime-safety.md`: official backend has no deadline, project-local hook adapters inherit secrets, and token loads ignore file modes.
- `mycelium/input-size-boundaries.md`: read/diff/json commands read unbounded inputs before safeguards.

## Folded Into Existing Handoffs

- Cortina GateGuard process-local retry risk: `cortina/capture-policy-boundary.md`.
- Hyphae archive import partial commit: `hyphae/read-model-and-archive-contracts.md`.
- Spore discovery `--version` timeout: `spore/shared-primitive-quality.md`.
- Annulus notification mutation remains covered by `annulus/operator-boundary-statusline-contracts.md`.

## Noted Existing Coverage

- Volva hook timeout bounds remain in `volva/hook-runtime-contracts.md`.
- Rhizome backend probing install-policy drift remains adjacent to `rhizome/code-graph-contract-and-install-boundary.md`, but the timeout/write-boundary work is now tracked separately.

## Validation Notes

The audit was read-only. Follow-up handoffs include concrete repo-local commands and lightweight verification scripts; the new scripts were syntax-checked after creation.
