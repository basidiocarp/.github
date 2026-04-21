# Cap: Fix analytics tab correctness (type contract, most_active_project, since semantics)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** cap/...
- **Cross-repo edits:** none
- **Non-goals:** existing Cap tier-6/tier-7 handoffs (separate)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — Server `AgentRuntimeStatus` type missing two fields (HIGH)
`server/routes/status/types.ts:44-56` vs `src/lib/types/status.ts:28-37`

The server emits `resolved_config_path: string` and `resolved_config_source` (see
`server/lib/agent-runtimes.ts:81-82,91-92`) but the server's own type definition
omits both fields. The client type declares them correctly. If code ever constructs an
`AgentRuntimeStatus` on the server side using the server type, the client receives
`undefined` for fields it treats as `string`. Add both fields to the server type.

### 2 — `most_active_project` "unknown" sentinel defeats UI guard (HIGH)
`server/lib/telemetry/aggregate.ts:38`

When `sessions` is empty, `mostActiveProject` is set to the hardcoded string
`'unknown'`. The `AggregateTelemetry.most_active_project` field is typed `string`
(not `string | null`), so `{data.most_active_project && ...}` in `TelemetryTab.tsx:107`
is always truthy — the badge renders "unknown" instead of hiding.

Fix: return `null` from the server when no project data exists, and update the type
to `string | null`. The UI guard `{data.most_active_project && ...}` then works as
intended.

### 3 — `since` parameter has divergent semantics (HIGH)
`server/lib/usage/scan.ts:29`, `server/routes/usage.ts:27`

`scan.ts` filters by file `mtime`; the route filter at `usage.ts:27` filters by
`s.timestamp >= since` (ISO string comparison). A session file re-written after its
original timestamp passes the mtime gate but fails the string comparison, or vice
versa. Align to one semantic: use ISO string comparison consistently, or use mtime
consistently. Document the chosen semantic.

### 4 — `since` NaN validation gap (MEDIUM)
`server/lib/usage/scan.ts:29`

`new Date(since).getTime()` returns `NaN` for non-date strings. `NaN > 0` is `false`,
so invalid `since` values silently return all sessions instead of a 400. The `/sessions`
route already validates `limit` — add equivalent validation for `since`.

### 5 — `_transcriptPath ?? ''` passes empty string to `readFileSync` (MEDIUM)
`server/lib/telemetry/aggregate.ts:22`

When `_transcriptPath` is missing, `readFileSync('', 'utf-8')` throws `ENOENT`.
The outer `try/catch` catches it as `null`, producing a silent skip rather than a
diagnostic. Add `if (!session._transcriptPath) continue` before the call.

### 6 — Telemetry route caches failure result for full TTL (LOW)
`server/routes/telemetry.ts:7-13`

If `aggregateTelemetry()` throws, the `cached()` wrapper stores `null`. The next call
within the 5-minute TTL returns the cached `null` rather than retrying. If the
telemetry directory becomes available within the TTL, the UI stays broken until
expiry. Use a cache-on-success-only pattern.

### 7 — Loading state incomplete for new analytics tabs (MEDIUM)
`src/pages/analytics/AnalyticsPage.tsx:40`

The page-level `loading` flag combines only `hyphaeLoading || myceliumLoading || rhizomeLoading`.
New tab queries (`useTelemetry`, `useUsageAggregate`, `useUsageTrend`, `useUsageSessions`)
are not included. The page loader does not show while new tabs fetch. Add the new
loading states.

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cap
npm test 2>&1 | tail -10
npm run build 2>&1 | tail -5
```

Expected: all 328 server + 119 frontend assertions pass; build succeeds.

## Checklist

- [ ] `AgentRuntimeStatus` server type includes `resolved_config_path` and `resolved_config_source`
- [ ] `most_active_project` returns `null` when empty; type updated to `string | null`
- [ ] `since` semantics aligned across scan and route filter
- [ ] `since` validated before use; invalid input returns 400
- [ ] `_transcriptPath` pre-checked before calling `readFileSync`
- [ ] Telemetry route caching clears on failure
- [ ] Analytics page loading flag includes new tab queries
- [ ] All tests pass, build green
