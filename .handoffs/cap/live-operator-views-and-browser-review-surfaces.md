# Cap Live Operator Views And Browser Review Surfaces

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** cap/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The audits now point to a stronger operator-surface gap than the current `cap` backlog captures. `cap` has useful dashboards and integrations, but it still lacks a coherent live operator layer for workflow state, browser-preview control, review-cycle visibility, and session-aware orchestration views. That work is valuable, but it should follow the underlying runtime and coordination contracts instead of racing ahead.

## What exists (state)

- **`cap` pages:** already has canopy, dashboard, diagnostics, sessions, status, and analytics pages
- **`cap` server routes:** already wraps `hyphae`, `rhizome`, settings, and status surfaces
- **No unified operator workflow layer:** live queue, browser-preview, review-cycle, and session surfaces are still fragmented
- **Examples:** `council`, `claude-mem`, `vibe-kanban`, `cmux`, and `Understand-Anything` all pointed to richer operator state

## What needs doing (intent)

Add a focused operator layer in `cap` for:

- live workflow and queue visibility
- browser-preview and review surfaces
- task, session, and council-linked operator state
- typed wrappers over `canopy`, `hyphae`, and `volva` data rather than raw process output

This should stay behind the groundwork tracks in priority.

---

### Step 1: Define the operator read models

**Project:** `cap/`
**Effort:** 2-3 hours
**Depends on:** stable `canopy` and `volva` groundwork

Define the typed UI models needed for queue, browser-preview, review-cycle, and live session views before building new screens.

#### Files to modify

**`cap/src/lib/types/`** — add operator-facing types.

**`cap/src/lib/api/`** — add typed clients for the new surfaces.

**`cap/server/routes/`** — add server-side wrappers where the current routes are too fragmented.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] operator read models are typed and explicit
- [ ] new routes or wrappers do not depend on raw stringly-typed process output
- [ ] build passes

---

### Step 2: Add live workflow and review surfaces

**Project:** `cap/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Add the first useful live workflow surfaces, likely under existing canopy pages:

- queue or execution status
- review-cycle summaries
- browser-preview state where available

#### Files to modify

**`cap/src/pages/canopy/`** — add or extend workflow and queue views.

**`cap/src/pages/sessions/`** — add session-aware operator state where it fits.

**`cap/src/lib/queries/`** — add the query layer for the new surfaces.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -40
cd cap && npm test 2>&1 | tail -60
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `cap` exposes at least one live workflow view
- [ ] review or browser-preview state is visible where the backend supports it
- [ ] build and tests pass

---

### Step 3: Link the operator surfaces to stable backend ownership

**Project:** `cap/`
**Effort:** 2-3 hours
**Depends on:** Step 2

Make the ownership model explicit in the UI and route layer:

- `canopy` owns orchestration state
- `volva` owns execution-host state
- `hyphae` owns durable recall and artifacts

Do not let `cap` become the new source of truth.

#### Files to modify

**`cap/server/routes/`** — make backend ownership visible in the route layer.

**`cap/src/pages/`** — keep labels and interactions consistent with backend ownership.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -40
bash .handoffs/cap/verify-live-operator-views-and-browser-review-surfaces.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `cap` reads orchestration, execution, and recall from the right owning backends
- [ ] browser-preview and review surfaces do not invent their own backend authority
- [ ] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cap/verify-live-operator-views-and-browser-review-surfaces.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/cap/verify-live-operator-views-and-browser-review-surfaces.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- `.audit/external/audits/council/ecosystem-borrow-audit.md`
- `.audit/external/audits/claude-mem/ecosystem-borrow-audit.md`
- `.audit/external/audits/vibe-kanban/ecosystem-borrow-audit.md`
- `.audit/external/audits/cmux/ecosystem-borrow-audit.md`
- `.audit/external/audits/Understand-Anything/ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
- `.audit/external/synthesis/next-session-context-second-wave-handoffs.md`
