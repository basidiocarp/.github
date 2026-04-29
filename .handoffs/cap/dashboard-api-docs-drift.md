# Cap: Dashboard And API Docs Drift

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/README.md`, `cap/docs/`, `cap/src/App.tsx`, `cap/src/components/AppLayout.tsx`, `cap/server/index.ts`, `cap/server/routes/`, `cap/src/lib/api/`, `cap/src/lib/queries/`
- **Cross-repo edits:** none
- **Non-goals:** no UI feature changes, no server auth policy changes, and no endpoint redesign
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cap/verify-dashboard-api-docs-drift.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** public README route inventory, API reference, internals docs, getting-started feature notes
- **Reference seams:** `server/index.ts`, `server/routes/*`, `src/App.tsx`, `src/components/AppLayout.tsx`, `src/lib/api/*`, `src/lib/queries/*`
- **Spawn gate:** do not launch an implementer until the parent agent decides whether to make docs generated from route metadata or keep a manually maintained inventory

## Problem

Cap's docs no longer describe the mounted API and dashboard surfaces accurately. The API reference documents nine namespaces but the server also mounts `/api/cost`, `/api/ecosystem`, `/api/sessions`, `/api/watchers`, `/api/health`, and `/api/client-config`. It also misses real endpoints such as `/hyphae/evaluate`, `/canopy/agents`, and Annulus notification routes used by the UI.

The README route inventory omits shipped routes including `/sessions`, `/lessons`, `/canopy`, and `/settings`. `docs/internals.md` still points maintainers at removed files such as `server/db.ts`, `src/lib/queries.ts`, and `src/lib/api.ts` instead of the current split route, API, and query modules.

`docs/getting-started.md` also contains stale UI behavior: memoir graph depth is documented as 1-5 while the UI offers 1-4, LSP Manager is documented as install/uninstall while the current route only installs, backend changes are said to require manual restart even though `dev:server` watches, and Code Explorer promises syntax highlighting where the current definition view is a plain code block.

## What needs doing

1. Reconcile API docs with the routes mounted in `server/index.ts`.
2. Document public, auth, webhook, and client-config behavior without duplicating the security handoff.
3. Update README route inventory from the actual router and sidebar.
4. Update internals docs to reference the current `src/lib/api/` and `src/lib/queries/` module split.
5. Correct getting-started claims for Memoirs, LSP Manager, dev server restart behavior, and Code Explorer rendering.
6. Consider adding a small docs inventory check so mounted route names and README/API docs do not drift silently.

## Verification

```bash
cd cap && npm run build
cd cap && npm test
bash .handoffs/cap/verify-dashboard-api-docs-drift.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] API docs list every mounted API namespace or clearly mark internal endpoints
- [ ] README route inventory matches `src/App.tsx` and sidebar navigation
- [ ] internals docs do not reference removed file paths
- [ ] getting-started UI behavior matches the shipped controls
- [ ] build and tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 7 docs-to-code drift audit. Severity: medium plus one high auth-doc overlap folded into `api-auth-and-webhook-defaults.md`.
