# Cap: Realtime Invalidation Read Models

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/...`
- **Cross-repo edits:** none unless this handoff explicitly names a backend contract gap
- **Non-goals:** replacing backend ownership, streaming whole datasets over WebSocket, or building a new event bus outside the current Cap surface
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cap/verify-realtime-invalidation-read-models.sh`
- **Completion update:** once review is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** query keys, query hooks, any realtime client module, and the first operator pages that need live invalidation
- **Reference seams:** existing TanStack Query usage in `cap/src/lib/queries/` and the operator surfaces in [Live Operator Views And Browser Review Surfaces](live-operator-views-and-browser-review-surfaces.md)
- **Spawn gate:** do not launch an implementer until the parent agent can name the exact file set and exact repo-local verification commands

## Problem

Cap already uses query-backed read models, but it does not yet have an explicit realtime strategy for operator surfaces. As live queue, review, runtime, and notification views grow, Cap needs a clear rule: the API remains the source of truth, realtime signals invalidate or refresh query-backed views, and only narrow hot paths patch cache directly when that is clearly justified. The `multica` audit makes this seam explicit.

## What exists (state)

- **Cap:** already uses `@tanstack/react-query` for most read and mutation flows
- **Operator surfaces:** active and planned pages need fresher state as Canopy, Hymenium, and Volva become more dynamic
- **External reference:** `multica` uses WebSocket as invalidation, not as the canonical data channel, and re-fetches through stable API reads

## What needs doing (intent)

Add an explicit realtime invalidation architecture for Cap so that:

- query-backed reads stay authoritative
- realtime messages identify what changed, not the full replacement payload
- invalidation is grouped by a small set of topics or keys
- hot-path cache patching is rare and named explicitly

## Scope

- **Primary seam:** realtime invalidation over typed query-backed views
- **Allowed files:** `cap/src/...`, `cap/server/...`, `cap/tests/...`
- **Explicit non-goals:**
  - Do not let WebSocket payloads become a second backend authority
  - Do not widen the operator UI before the underlying routes exist
  - Do not add a giant custom client cache layer beside TanStack Query

---

### Step 1: Define the realtime invalidation contract for Cap

**Project:** `cap/`
**Effort:** 2-4 hours
**Depends on:** [Cap: Live Operator Views And Browser Review Surfaces](live-operator-views-and-browser-review-surfaces.md)

Choose the small set of invalidation topics and the query keys they refresh.

#### Verification

```bash
cd cap && npm run build 2>&1
```

**Checklist:**
- [ ] Realtime topics are documented and intentionally small
- [ ] Query keys that each topic invalidates are named explicitly
- [ ] API reads remain the source of truth

---

### Step 2: Wire invalidation into the first operator surfaces

**Project:** `cap/`
**Effort:** 0.5 day
**Depends on:** Step 1

Use the invalidation contract for the first live operator views that need it, such as queue, review, runtime, or notification state.

#### Verification

```bash
cd cap && npm run build 2>&1
cd cap && npm test 2>&1
```

**Checklist:**
- [ ] At least one operator surface refreshes from realtime invalidation
- [ ] The refreshed data still comes from normal query-backed reads
- [ ] Tests cover invalidation behavior at the hook or component level

---

### Step 3: Keep hot-path cache patching narrow and explicit

**Project:** `cap/`
**Effort:** 2-4 hours
**Depends on:** Step 2

If any hot path needs direct cache patching, keep it local, typed, and documented instead of letting it spread into a second state model.

#### Verification

```bash
cd cap && npm run build 2>&1
cd cap && npm test 2>&1
```

**Checklist:**
- [ ] Any direct cache patching is narrow and justified
- [ ] Most realtime-driven updates still use query invalidation
- [ ] No operator surface depends on a WebSocket-only payload to render correctly

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Cap has an explicit realtime invalidation strategy over query-backed reads
2. `bash .handoffs/cap/verify-realtime-invalidation-read-models.sh` passes
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion

### Final Verification

```bash
bash .handoffs/cap/verify-realtime-invalidation-read-models.sh
```

## Context

Source: `multica` ecosystem borrow audit, especially the "Event bus with WebSocket-as-invalidation" finding. This is an operator-surface hardening handoff, not a new backend authority model.
