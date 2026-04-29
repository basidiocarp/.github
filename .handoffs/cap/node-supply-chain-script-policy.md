# Cap: Node Supply Chain Script Policy

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/package.json`, `cap/package-lock.json`, `cap/scripts/release.sh`, `cap/README.md`, `cap/docs/`, `cap/server/__tests__/`, `.handoffs/cap/`
- **Cross-repo edits:** none
- **Non-goals:** no UI feature work and no auth-policy changes
- **Verification contract:** run the commands below and `bash .handoffs/cap/verify-node-supply-chain-script-policy.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** npm scripts, release script, docs install commands, verification docs
- **Reference seams:** package lock, Biome/Vitest/TypeScript scripts, native dependency install scripts
- **Spawn gate:** do not launch an implementer until the parent agent chooses whether Cap uses `npm ci` only or supports `npm install` for local development with a documented lifecycle-script policy

## Problem

Cap scripts and release checks call `npx` for Biome and TypeScript. If `node_modules` is absent or stale, `npx` can resolve from the registry instead of the committed lockfile. Docs also recommend `npm install`, and the lockfile includes native/runtime packages with install scripts such as `better-sqlite3`, `esbuild`, and `fsevents` without a documented allowlist.

The docs drift audit also found that workspace validation guidance says Cap's standard check is `npm run build && npm test`, while `cap/scripts/release.sh` stops at Biome, TypeScript, and build. The install/release docs and release automation need to agree on whether tests are required before release.

## What needs doing

1. Replace `npx` script/release invocations with lockfile-bound local scripts or `npm exec --offline --`.
2. Update handoff verification examples that currently recommend `npx vitest` where Cap has local scripts.
3. Prefer `npm ci` in setup/CI docs for reproducible installs.
4. Document install-script expectations and the allowlist/rebuild path for native dependencies.
5. Add a simple validation check that rejects new unqualified `npx` usage in Cap scripts/docs unless explicitly justified.
6. Align `cap/scripts/release.sh` with the documented validation bar, or update docs to explain why release checks intentionally omit tests.

## Verification

```bash
cd cap && npm ci
cd cap && npm audit --omit=dev
cd cap && npm run build
cd cap && npm test
cd cap && npm exec --offline -- biome check .
cd cap && npm exec --offline -- tsc --noEmit
bash .handoffs/cap/verify-node-supply-chain-script-policy.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Cap scripts do not rely on registry-resolving `npx`
- [ ] release checks use lockfile-bound tools
- [ ] docs prefer `npm ci` for reproducible setup
- [ ] lifecycle-script/native dependency policy is documented
- [ ] release script and workspace validation docs agree on whether Cap tests are part of the release gate
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 6 dependency and supply-chain audit and expanded by Phase 7 docs drift audit. Severity: medium.
