# Cap Deep Audit

<!-- Save as: .handoffs/cap/deep-audit.md -->
<!-- Create verify script: .handoffs/cap/verify-deep-audit.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

The global ecosystem audit on 2026-04-04 only lightly covered `cap/`. The dashboard and
API surface needed a dedicated follow-up so React, TypeScript, UX, boundary, and
security issues could be captured as real handoffs instead of informal notes.

## What exists (state)

- **Stack:** React 19, TypeScript, Vite, Vitest, Biome, Hono, better-sqlite3
- **Known handoffs before this audit:** `boundary-documentation.md`, `dependency-cleanup.md`
- **Frontend routes:** 13 route targets in [`cap/src/App.tsx`](/Users/williamnewton/projects/basidiocarp/cap/src/App.tsx)
- **Server surface:** 75 route handlers, including 18 write endpoints

## What needs doing (intent)

Document all 8 audit slices, create follow-up handoffs for significant new findings,
and close this audit handoff with a machine-checkable verification script.

---

### Step 1: Lint and Format Audit

**Project:** `cap/`
**Effort:** completed

#### Findings

- `npx @biomejs/biome check .` fails with 27 diagnostics, mostly `useSortedKeys`
  ordering in existing server tests.
- `package.json` defines `lint` as `biome check --write .`, so the normal lint script
  mutates tracked files instead of acting as a CI-style gate.
- `biome.json` excludes all `*.config.ts` files, so `vite.config.ts`,
  `vitest.config.ts`, and `vitest.frontend.config.ts` are not linted.

#### Output

```bash
npx @biomejs/biome check .
```

**Output:**
<!-- PASTE START -->
Biome reported 27 diagnostics. The highest-signal audit finding was structural:
`biome.json` excludes all `*.config.ts` files, and `npm run lint` is defined as a
write command (`--write`) instead of a check-only verification command.
<!-- PASTE END -->

**Checklist:**
- [x] Biome result documented
- [x] Security-relevant lint/config drift documented
- [x] Formatting gate behavior documented

---

### Step 2: Dependency Audit

**Project:** `cap/`
**Effort:** completed

#### Findings

- Existing handoff [`dependency-cleanup.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/dependency-cleanup.md)
  still accurately captures the direct dependency drift:
  missing `zustand`, unused Tiptap packages, and unused `@mantine/spotlight`.
- Live `npm audit` could not be completed in this workspace because outbound registry
  access is blocked.

#### Output

```bash
npm audit --json
```

**Output:**
<!-- PASTE START -->
`npm audit --json` failed with `getaddrinfo ENOTFOUND registry.npmjs.org` in the
network-restricted workspace, so no live advisory data was available during this audit.
The existing dependency-cleanup handoff remains the actionable dependency result.
<!-- PASTE END -->

**Checklist:**
- [x] Audit limitation documented
- [x] Existing dependency handoff cross-referenced
- [x] Missing and unused dependency state recorded

---

### Step 3: Architecture and Structure Review

**Project:** `cap/`
**Effort:** completed

#### Findings

- No concrete `any` usage was found in `src/` or `server/`.
- Main size hotspots:
  - `src/pages/canopy/TaskOperatorActionsSection.tsx` — 800 lines
  - `src/pages/canopy/useCanopyPageState.ts` — 475 lines
  - `src/lib/types/canopy.ts` — 571 lines
- `useCanopyPageState` eagerly creates 37 `useCanopySnapshot` observers, making the
  Canopy page the biggest architecture/performance hotspot found in the frontend.

**Checklist:**
- [x] Large modules identified
- [x] `any` usage checked
- [x] State-management hotspot documented

---

### Step 4: API and Security Review

**Project:** `cap/`
**Effort:** completed

#### Findings

- High: auth is fail-open when `CAP_API_KEY` is unset in
  [`cap/server/index.ts`](/Users/williamnewton/projects/basidiocarp/cap/server/index.ts).
- Medium: settings write endpoints in
  [`cap/server/routes/settings/writes.ts`](/Users/williamnewton/projects/basidiocarp/cap/server/routes/settings/writes.ts)
  interpolate request data directly into TOML with partial validation.
- Medium: `POST /api/rhizome/project` in
  [`cap/server/routes/rhizome/project.ts`](/Users/williamnewton/projects/basidiocarp/cap/server/routes/rhizome/project.ts)
  allows unrestricted project-root switching to any readable directory.
- Low: [`cap/docs/API.md`](/Users/williamnewton/projects/basidiocarp/cap/docs/API.md)
  is stale relative to the server route surface.
- Existing handoff [`boundary-documentation.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/boundary-documentation.md)
  still covers the false “read-only” claim, but it misses several newer write endpoints.

#### Output

```bash
rg -n "app\\.(get|post|put|delete)\\(" cap/server/routes cap/server/index.ts | wc -l
```

**Output:**
<!-- PASTE START -->
75 route handlers total, including 18 write endpoints.
<!-- PASTE END -->

**Checklist:**
- [x] Endpoint inventory documented
- [x] Input validation assessed
- [x] No explicit HTML/XSS sink found in audited files
- [x] CORS/auth behavior documented
- [x] Write-endpoint surface verified against existing boundary handoff

---

### Step 5: Test Coverage Review

**Project:** `cap/`
**Effort:** completed

#### Findings

- `npm test` passed:
  - server: 23 files / 208 tests
  - frontend: 20 files / 87 tests
- Good page-level test coverage exists for `Analytics`, `Canopy`, `CodeExplorer`,
  `Memoirs`, `Onboard`, `Sessions`, `Settings`, and `Status`.
- Critical route gaps remain for `Dashboard`, `Diagnostics`, `Lessons`, `Memories`,
  and `SymbolSearch`, which have no matching page-level `*.test.tsx` coverage.

#### Output

```bash
npm test
```

**Output:**
<!-- PASTE START -->
Server tests: 23 files passed, 208 tests passed.
Frontend tests: 20 files passed, 87 tests passed.
Overall `npm test` exited 0.
<!-- PASTE END -->

**Checklist:**
- [x] Test counts documented
- [x] Coverage gaps identified
- [x] Critical untested routes listed

---

### Step 6: Performance and Bundle Review

**Project:** `cap/`
**Effort:** completed

#### Findings

- `npm run build` passed.
- Largest emitted JS chunks:
  - `mantine-charts` — 392.25 kB
  - `mantine` — 296.27 kB
  - `vendor` — 249.97 kB
  - `flow` — 185.27 kB
  - `force-graph` — 138.49 kB
  - `Canopy` route chunk — 88.25 kB
- The route-level lazy loading in `App.tsx` is working, but the Canopy page still has
  the heaviest route-local fetch/render fan-out.

#### Output

```bash
npm run build
```

**Output:**
<!-- PASTE START -->
`npm run build` exited 0. The largest emitted chunks were `mantine-charts`
(392.25 kB), `mantine` (296.27 kB), `vendor` (249.97 kB), `flow` (185.27 kB),
`force-graph` (138.49 kB), and the `Canopy` route chunk (88.25 kB).
<!-- PASTE END -->

**Checklist:**
- [x] Bundle output documented
- [x] Large dependencies identified
- [x] Code splitting strategy assessed

---

### Step 7: UI/UX Audit

**Project:** `cap/`
**Effort:** completed

#### Findings

- Route inventory from `App.tsx` confirms 13 navigable route targets.
- Live browser inspection covered all 13 routes successfully:
  `/`, `/memories`, `/memoirs`, `/sessions`, `/lessons`, `/onboard`, `/canopy`,
  `/analytics`, `/code`, `/symbols`, `/diagnostics`, `/settings`, `/status`.
- Medium: mobile navigation is toggled by clicking the `cap` title in
  [`cap/src/components/AppLayout.tsx`](/Users/williamnewton/projects/basidiocarp/cap/src/components/AppLayout.tsx),
  which is not a button and is not keyboard focusable.
- Medium: lifecycle adapter badges use `key={hook.event}` and produced a duplicate
  React key warning during live inspection.
- Low: analytics charts render, but the browser console warns about negative chart
  measurements from the responsive chart container path.

**Checklist:**
- [x] All routes inventoried
- [x] Empty/error/loading-state evidence documented
- [x] Navigation coverage gaps noted
- [x] Main accessibility/visual follow-up areas noted

---

### Step 8: Component Functional Correctness

**Project:** `cap/`
**Effort:** completed

#### Functional Status

- Memory browser: works in live inspection
- Session list: works, but current project only showed an empty state
- Stats / evaluate panel: works in live inspection and route tests
- Rhizome code panel: works in live inspection and route tests
- Canopy task board: works, but only empty-state behavior was available in the active project
- Mycelium filter history: not yet implemented as a dedicated Cap surface
- Diagnostics, Lessons, SymbolSearch: work in live inspection

**Checklist:**
- [x] Major feature status documented
- [x] Partial/broken/untested areas called out

---

### Step 9: Synthesize Findings

**Project:** `.handoffs/cap/`
**Effort:** completed

#### New Follow-Up Handoffs

- [`auth-hardening.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cap/auth-hardening.md)
- [`config-write-validation.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/config-write-validation.md)
- [`rhizome-project-boundary.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cap/rhizome-project-boundary.md)
- [`tooling-coverage.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/tooling-coverage.md)
- [`canopy-performance.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/canopy-performance.md)
- [`app-layout-mobile-nav-a11y.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/app-layout-mobile-nav-a11y.md)
- [`status-lifecycle-key-stability.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/status-lifecycle-key-stability.md)
- [`analytics-chart-sizing.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/analytics-chart-sizing.md)

**Checklist:**
- [x] Significant findings turned into handoffs
- [x] Existing Cap handoffs cross-referenced instead of duplicated
- [x] Handoff index updated

---

## Completion Protocol

**This handoff is complete because ALL of the following are true:**

1. All 9 audit steps above have findings documented
2. Significant new findings have dedicated follow-up handoffs
3. The verification script passes: `bash .handoffs/cap/verify-deep-audit.sh`

### Final Verification

```bash
bash .handoffs/cap/verify-deep-audit.sh
```

**Output:**
<!-- PASTE START -->
PASS: Deep audit follow-up handoffs exist
PASS: Deep audit findings document all steps
PASS: Handoff index marks Deep Audit complete
PASS: Handoff index lists new follow-up handoffs
Results: 4 passed, 0 failed
<!-- PASTE END -->

## Context

Follow-up to the global ecosystem audit on 2026-04-04. This audit closes the Cap
review slice and breaks new work into focused follow-up handoffs instead of leaving
the dashboard audit as an open-ended note.
