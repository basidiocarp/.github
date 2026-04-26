# Cap: Drift Signal Surface

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** cap
- **Allowed write scope:** `cap/server/routes/`, `cap/client/src/components/`, `cap/server/lib/`
- **Cross-repo edits:** none (cap reads canopy's existing API; canopy source is not changed)
- **Non-goals:** autonomous correction or enforcement; changing canopy's DriftSignal model; changing how drift is detected (detection stays in canopy)
- **Verification contract:** cap dashboard shows a visible warning indicator when canopy reports drift signals for the current project
- **Completion update:** update dashboard when warning surface is visible in a running cap session

## Context

Phase 5 of the audit confirmed that the cortina→hyphae→canopy→cap chain has a weak link at cap: canopy generates `DriftSignal` events (version drift, unseamed payloads, config mismatches) but cap has no UI surface for them. Operators must query canopy directly to see drift.

This is an early warning problem, not an enforcement problem. The goal is to surface signals the operator can act on, not to have cap take automated corrective action.

The cap→canopy interaction is currently scoped to: fetch snapshot, render operator view. Drift signals are a parallel read path — cap reads them, renders a badge or panel, and the operator decides what to do.

## Implementation Seam

- **Canopy API**: read `canopy/src/api.rs` or equivalent to find the drift signal endpoint (e.g., `GET /api/drift` or similar)
- **Cap server**: `cap/server/routes/canopy.ts` — add a new route or extend the existing canopy proxy
- **Cap client**: `cap/client/src/components/` — add a DriftWarning component or extend the existing status panel
- **Reference seams**: the existing cap→canopy snapshot fetch is the pattern to follow; find how cap currently calls canopy and mirror that pattern

**Spawn gate:** read `canopy/src/api.rs` and `cap/server/routes/canopy.ts` before writing any code. The canopy API surface and cap's calling pattern must be understood before implementing the new read path.

---

## Decision Required (lightweight — no implementation block)

Before implementing, answer one scoping question:

**Where should drift signals appear in the UI?**

- **Option A: Badge on the existing status panel** — a small red/yellow dot with a count next to the canopy status row. Click to expand into a list of signals. Minimal surface change.
- **Option B: Dedicated warnings panel** — a collapsible "Drift Warnings" section below the main status panel, listing each signal with its severity and a short description.
- **Option C: Toast notifications** — transient banners that appear when new drift signals arrive. Dismissible. Good for new-signal notification, less good for persistent visibility.

**Recommended: Option A** (badge first, expand later). The audit found that the primary need is "I can see drift without querying canopy directly." A badge satisfies that with minimal UI change. Option B can be built on top of Option A if the operator wants more detail.

Answer this before implementing. If the answer is Option A, proceed. If Option B or C, the component work changes scope.

---

### Step 1: Read the canopy drift signal API

**Project:** cap + canopy
**Effort:** 30 min
**Depends on:** nothing

Find where canopy exposes drift signals and what the response shape looks like:

```bash
# Find drift signal API in canopy
grep -rn "drift\|DriftSignal\|drift_signal" canopy/src/ | grep -v "target\|\.git"

# Find existing cap→canopy routes
grep -rn "canopy\|snapshot" cap/server/routes/ | head -20
```

Document:
1. The canopy endpoint (path, method, response schema)
2. The field names for severity, message, and source in the DriftSignal
3. Whether there is a septa schema for this payload

#### Verification

```bash
grep -rn "DriftSignal\|drift_signal" canopy/src/ | grep -v "target\|\.git" | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Canopy drift signal endpoint found
- [ ] Response shape (fields) documented
- [ ] Septa schema status checked

---

### Step 2: Add canopy drift route to cap server

**Project:** cap
**Effort:** 30-60 min
**Depends on:** Step 1

Add a server-side route that proxies or reads the canopy drift signal API. Follow the same pattern as the existing canopy snapshot route.

The route should:
- Call the canopy drift endpoint
- Return a normalized response to the cap client
- Return `{ signals: [], available: false }` when canopy is unavailable (do not error)

```typescript
// cap/server/routes/canopy.ts (extend existing file)
// GET /api/canopy/drift
router.get('/canopy/drift', async (req, res) => {
  try {
    const response = await callCanopy('/api/drift'); // adjust path per Step 1
    res.json({ signals: response.signals ?? [], available: true });
  } catch {
    // Canopy unavailable — return empty, do not error
    res.json({ signals: [], available: false });
  }
});
```

#### Verification

```bash
cd cap && npm run dev &
sleep 2
curl -s http://localhost:<port>/api/canopy/drift | python3 -c "import sys, json; d = json.load(sys.stdin); print('signals:', len(d.get('signals', [])), 'available:', d.get('available'))"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Route returns valid JSON when canopy is running
- [ ] Route returns `{ signals: [], available: false }` when canopy is not running
- [ ] No uncaught errors in cap server logs

---

### Step 3: Add drift warning badge to cap dashboard

**Project:** cap
**Effort:** 1-2 hours
**Depends on:** Step 2

Add a DriftWarning component that:
- Polls `/api/canopy/drift` every 30 seconds
- Shows a yellow/red badge when `signals.length > 0`
- Shows the count on the badge
- Expands to a list on click (severity + message per signal)
- Shows nothing when `available: false` or `signals.length === 0`

Place it in the existing canopy status row or status panel. Do not add a new top-level section.

```tsx
// cap/client/src/components/DriftWarning.tsx
// Shows a badge when canopy reports drift signals.
// Returns null when canopy is unavailable or no signals present.
```

#### Verification

```bash
cd cap && npm run dev
# Open http://localhost:<port> in a browser
# If canopy has drift signals: badge should appear on the canopy row
# If canopy is unavailable: no badge, no error
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Badge appears when signals.length > 0
- [ ] Count is correct (matches canopy API response)
- [ ] No badge when canopy unavailable
- [ ] No badge when signals.length === 0
- [ ] Click expands to signal list (severity + message)
- [ ] No console errors

---

## Completion Protocol

1. Canopy drift endpoint confirmed (path and response shape documented)
2. Cap server proxies drift signals at `/api/canopy/drift`
3. Cap dashboard shows badge when drift signals are present
4. Badge is absent when canopy is not running (no error state)
5. Dashboard updated

### Final Verification

```bash
bash .handoffs/cap/verify-drift-signal-surface.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->
