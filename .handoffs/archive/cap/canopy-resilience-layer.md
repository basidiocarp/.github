# Cap: Canopy Resilience Layer

## ⚠ STOP — READ BEFORE STARTING ANYTHING

This handoff requires a design decision before any implementation begins. Do not write code, modify files, or spawn subagents until the question in the "Decision Required" section has been answered by the human engineer.

Read this entire handoff, then ask the questions in "Decision Required." Implementation starts only after the human has chosen an approach.

---

## Handoff Metadata

- **Dispatch:** `umbrella — do not send to implementer directly`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/` only
- **Cross-repo edits:** none
- **Non-goals:** changing the canopy API; modifying how canopy produces snapshots; adding new canopy data fields; anything in a Rust repo
- **Verification contract:** cap server must return a non-500 response for `/api/snapshot` when canopy is not installed or not running
- **Completion update:** update dashboard after decision is made and implementation is verified

## Context

Phase 5 of the Ecosystem Health Audit rated the cap→canopy seam as **FRAGILE**: if canopy is unavailable (not running, not installed, or briefly down), the cap server returns HTTP 500 and the dashboard becomes completely unusable. There is no secondary read path. The `cachedAsync<T>()` helper already exists in `cap/server/lib/cache.ts` but is not used for the snapshot endpoint.

Audit findings: `.handoffs/campaigns/ecosystem-health-audit/phase5-interaction/findings-p2.md` (Task 1)

---

## Decision Required

Before any implementation, the human engineer must choose **one** of the following approaches. Each has meaningful tradeoffs.

---

### Option A: In-process memory cache with stale-on-error (recommended starting point)

**What it does:** Wraps `getSnapshot()` with the existing `cachedAsync(ttl)` helper. On success, the result is cached in memory for `ttl` seconds. On error, returns the last cached result with a `stale: true` flag, or a structured error if no cached result exists yet.

**How it works:**
```typescript
// cap/server/routes/canopy.ts
const snapshot = await cachedAsync('canopy:snapshot', 60, async () => {
  return await canopy.getSnapshot();
});
```

**Tradeoffs:**
- ✅ Two lines of code using already-existing infrastructure
- ✅ No new dependencies, no new services to run
- ✅ Dashboard stays up for 60s after canopy goes down
- ❌ Cache is in-process — lost on cap server restart
- ❌ 60s of stale data is invisible to operator unless `stale: true` flag is surfaced in the UI
- ❌ Cap runs as a single process — no cache sharing across multiple cap instances (not a current concern, but worth noting)

**When to pick this:** You want the minimal viable fix fast. The priority is "dashboard doesn't 500" rather than "dashboard has perfect data freshness visibility."

---

### Option B: Disk-based stale cache (snapshot persisted to JSON file)

**What it does:** On successful snapshot fetch, writes the result to a local file (e.g., `~/.basidiocarp/cap/canopy-snapshot-cache.json`). On error, reads the file and returns it with a `stale: true` flag and a `stale_since` timestamp.

**How it works:**
```typescript
// On success: write to disk
await fs.writeFile(CACHE_PATH, JSON.stringify({ snapshot, cached_at: Date.now() }));

// On error: read from disk
const { snapshot, cached_at } = JSON.parse(await fs.readFile(CACHE_PATH, 'utf8'));
return { ...snapshot, stale: true, stale_since: cached_at };
```

**Tradeoffs:**
- ✅ Survives cap server restart — stale data persists across process restarts
- ✅ Operator can see exactly when the data went stale (`stale_since`)
- ✅ No new dependencies
- ❌ More code than Option A (~30 lines vs. ~2 lines)
- ❌ Cache file can become corrupted (needs error handling on read)
- ❌ Cache file path needs to be configurable and respect the ecosystem's path conventions (spore path primitives)

**When to pick this:** You want the dashboard to survive a cap server restart with stale data, and you want to surface staleness prominently to the operator.

---

### Option C: Valkey (Redis-compatible) cache between cap and canopy

**What it does:** Adds a Valkey/Redis daemon as a caching layer. Cap writes snapshot to Valkey on success; reads from Valkey on error. Valkey handles TTL and persistence.

**Tradeoffs:**
- ✅ Distributed — works across multiple cap instances
- ✅ Configurable TTL, persistence, and eviction
- ✅ Valkey is Apache-licensed, Redis-compatible, production-grade
- ❌ Adds a new service that must run as a daemon (install, configure, monitor separately)
- ❌ Increases ecosystem operational complexity significantly for a localhost-first tool
- ❌ stipe would need to know how to install/manage Valkey
- ❌ All existing tooling (spore, stipe, canopy) assumes SQLite or file-based persistence — Valkey is a different operational model
- ❌ Overkill for a single-machine, single-user deployment model

**When to pick this:** You are planning to move cap toward a shared/multi-user deployment model where multiple cap instances need a shared cache. If the ecosystem stays local-first and single-machine, this is the wrong tool.

**Assessment:** Valkey is a strong choice for distributed or multi-process scenarios. For this ecosystem's current local-first model, Options A or B deliver 95% of the benefit with 5% of the operational cost. Valkey makes sense to revisit if/when cap moves toward a hosted or multi-user deployment.

---

### Option D: Read canopy SQLite directly as fallback

**What it does:** If the canopy CLI fails, cap reads the canopy SQLite database directly to construct a snapshot. This is a secondary read path rather than a stale cache.

**Tradeoffs:**
- ✅ Always returns current data, not stale data
- ✅ No extra services or files
- ❌ Violates the cap CLAUDE.md constraint: "does not write directly to Hyphae/Mycelium databases — reads sibling state via CLI" — reading SQLite directly bypasses the contract
- ❌ Couples cap to canopy's internal schema — any schema change in canopy breaks cap's fallback silently
- ❌ Requires cap to know and maintain the canopy DB schema

**When to pick this:** Do not pick this. It violates the architecture boundary that the audit confirmed is currently clean.

---

## Questions for the Human Engineer

Before implementation starts, answer:

1. **Which option?** (A, B, or C — D is not recommended)
2. **Should staleness be surfaced in the UI?** If yes, the React frontend needs a banner or indicator when `stale: true` is in the snapshot response.
3. **What is the acceptable stale window?** (60s? 5min? Operator-configurable?)
4. **Is multi-instance cap a near-term concern?** If yes, reconsider Valkey. If no, Option A or B is sufficient.

---

## Implementation Seam (after decision)

- **Likely repo:** `cap`
- **Likely files:**
  - `cap/server/routes/canopy.ts` — wrap `getSnapshot()` with chosen cache
  - `cap/server/lib/cache.ts` — already exists; may need extension for stale-on-error behavior
  - `cap/src/` — frontend indicator if staleness is surfaced in UI
- **Reference seams:** read `cachedAsync` implementation in `cap/server/lib/cache.ts` before modifying it
- **Spawn gate:** do not spawn implementer until the human has answered the decision questions above

---

## Scope (after decision)

- **Primary seam:** cap server snapshot endpoint resilience
- **Allowed files:** `cap/server/routes/canopy.ts`, `cap/server/lib/cache.ts`, and optionally `cap/src/` (UI staleness indicator)
- **Explicit non-goals:** changes to canopy; changes to septa; adding Valkey unless explicitly chosen

---

## Verification (after implementation)

```bash
# With canopy not running:
cd cap && npm run dev:server &
curl -s http://localhost:PORT/api/snapshot
# Should return 200 with stale data (or structured error), NOT 500

# With canopy running:
curl -s http://localhost:PORT/api/snapshot
# Should return 200 with live snapshot
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `/api/snapshot` returns non-500 when canopy is unavailable
- [ ] Stale data is flagged in response (`stale: true`) if Option B chosen
- [ ] UI surfaces staleness if that was decided
- [ ] No new services required unless Valkey was explicitly chosen
- [ ] `npm test` passes in cap

## Completion Protocol

1. Decision questions answered by human
2. Implementation matches chosen option
3. Verification commands pass
4. Dashboard updated
