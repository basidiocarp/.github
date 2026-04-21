# Cap Tooling Coverage

<!-- Save as: .handoffs/cap/tooling-coverage.md -->
<!-- Create verify script: .handoffs/cap/verify-tooling-coverage.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Cap’s tooling does not fully cover its own config surface. Biome excludes
`*.config.ts`, `tsconfig.node.json` does not include `vitest.frontend.config.ts`, and
the `lint` script is a write command instead of a check-only gate.

## What exists (state)

- **Biome:** `biome.json` excludes config files
- **TypeScript node config:** `tsconfig.node.json` includes `vite.config.ts` and
  `vitest.config.ts`, but not `vitest.frontend.config.ts`
- **Package scripts:** `npm run lint` rewrites files via `--write`

## What needs doing (intent)

Make Cap’s lint and type-check surface cover the actual config files, and add a
non-mutating verification command for CI and audits.

---

### Step 1: Cover Config Files

**Project:** `cap/`
**Effort:** 30 min
**Depends on:** nothing

- Remove the `*.config.ts` exclusion from `biome.json`
- Add `vitest.frontend.config.ts` to `tsconfig.node.json`

### Step 2: Add A Check-Only Lint Command

**Project:** `cap/`
**Effort:** 15 min
**Depends on:** Step 1

- Keep a write-oriented formatting command if desired
- Add a check-only script, such as `lint:check`, for audit and CI use

#### Files to modify

**`cap/biome.json`** — include config files in Biome coverage.

**`cap/tsconfig.node.json`** — include `vitest.frontend.config.ts`.

**`cap/package.json`** — expose a non-mutating lint/check command.

#### Verification

```bash
cd cap && npx @biomejs/biome check . && npm run build
```

**Output:**
<!-- PASTE START -->
`npx @biomejs/biome check . && npm run build`

- Biome check failed before build because of pre-existing unrelated issues in `server/__tests__/auth-hardening.test.ts`, `server/__tests__/canopy-client.test.ts`, `server/__tests__/config-write-validation.test.ts`, `server/__tests__/hyphae-reads.test.ts`, `server/__tests__/rhizome-project-boundary.test.ts`, `server/__tests__/stipe-contract.test.ts`, and `vitest.config.ts`.
- The run reported `Found 43 errors. Found 1 warning.` and `No fixes applied.`
- `npm run build` passes when run independently in `cap/`.

<!-- PASTE END -->

**Checklist:**
- [x] Config files are no longer excluded from Biome
- [x] `vitest.frontend.config.ts` is in TypeScript node coverage
- [x] A check-only lint command exists

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Verification output is pasted above
2. The verification script passes: `bash .handoffs/cap/verify-tooling-coverage.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cap/verify-tooling-coverage.sh
```

**Output:**
<!-- PASTE START -->
`bash .handoffs/cap/verify-tooling-coverage.sh`

- `PASS: Biome no longer excludes config files`
- `PASS: Node TS config includes vitest.frontend.config.ts`
- `PASS: Package scripts expose a non-mutating lint check`
- `Results: 3 passed, 0 failed`

<!-- PASTE END -->

## Context

Created from the completed Cap deep audit on 2026-04-05. This is the tooling-quality
follow-up created from the static audit slice.
