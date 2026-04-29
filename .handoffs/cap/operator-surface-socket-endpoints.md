# Cap: Operator Surface CLI → Socket Endpoint Migration

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/` adapter modules and route files; `cap/server/index.ts` configuration
- **Cross-repo edits:** each sibling tool must expose a socket endpoint before cap can migrate off its CLI; see Prerequisites below
- **Non-goals:** no frontend changes; no behavior changes to what data is returned to the dashboard
- **Verification contract:** `cd cap && npm run build && npm test`
- **Completion update:** update `.handoffs/HANDOFFS.md` when done; this handoff can be closed in stages as each CLI path is replaced

## Problem

The cap backend spawns sibling tool CLIs to read data for the operator dashboard. Four CLI paths are currently classified as "operator surface" in the C7 coupling table:

| CLI call | Cap server file | Schema |
|---|---|---|
| `hyphae stats/health/search/session/analytics/memoir --json` | `server/db.ts` (direct SQLite read), `server/hyphae.ts` | `hyphae-*-v1.schema.json` |
| `mycelium gain --format json` | `server/mycelium.ts` | `mycelium-gain-v1.schema.json` |
| `canopy snapshot/task get --format json` | `server/routes/canopy.ts` | `canopy-snapshot-v1`, `canopy-task-detail-v1` |
| `stipe doctor/init --json` | `server/routes/` | `stipe-doctor-v1`, `stipe-init-plan-v1` |

These CLI calls are the correct current approach for a dashboard reading sibling tool state. But they have known drawbacks:
- Each call spawns a subprocess and waits for it to exit — no streaming, no incremental updates
- The dashboard cannot subscribe to state changes; it must poll
- Parsing errors surface as silent failures or stale data

The migration target is typed local service endpoints (unix-socket or HTTP) in each sibling tool that cap queries directly without spawning subprocesses.

## Prerequisites

This handoff cannot be completed until each sibling tool registers a local service endpoint. Track those separately:

| Tool | Prerequisite handoff | Status |
|---|---|---|
| hyphae | `hyphae/local-service-endpoint-registration.md` | Not yet created |
| mycelium | `mycelium/local-service-endpoint-registration.md` | Not yet created |
| canopy | `canopy/dispatch-request-service-endpoint.md` | Stub exists — needs implementation |
| stipe | `stipe/local-service-endpoint-registration.md` | Not yet created |

**Do not start cap-side migration work until at least one sibling tool has a working socket endpoint.**

## Migration Pattern (per tool, once endpoint exists)

Each sibling tool will register a `local-service-endpoint-v1` descriptor (e.g., at `~/.config/<tool>/<tool>.endpoint.json`). Cap reads that descriptor and connects via `fetch()` (HTTP) or a Node.js Unix socket client.

### Example: hyphae (once socket endpoint exists)

**Before:**
```typescript
// server/hyphae.ts — current pattern
import { execFile } from 'node:child_process'
const result = await execFile(process.env.HYPHAE_BIN ?? 'hyphae', ['stats', '--json'])
const stats = HyphaeStatsSchema.parse(JSON.parse(result.stdout))
```

**After:**
```typescript
// server/hyphae.ts — socket endpoint pattern
import { readEndpointDescriptor, callEndpoint } from './lib/local-service'
const endpoint = await readEndpointDescriptor('hyphae')
const stats = HyphaeStatsSchema.parse(await callEndpoint(endpoint, 'hyphae_stats', {}))
```

### `server/lib/local-service.ts` (new)

Create a shared helper that:
1. Reads the endpoint descriptor JSON from `~/.config/<tool>/<tool>.endpoint.json` (path via `local-service-endpoint-v1` convention)
2. Validates `schema_version === "1.0"` and extracts `transport`, `endpoint`, `timeout_ms`
3. For `unix-socket`: opens a Node.js `net.Socket`, sends newline-delimited JSON-RPC 2.0 request, reads response
4. For `http`: uses `fetch()` with the endpoint URL
5. Returns parsed JSON result or throws a typed error

This helper replaces the scattered `execFile` calls across `server/mycelium.ts`, `server/routes/canopy.ts`, `server/routes/stipe.ts` etc.

## Migration Stages

Work in stages as each sibling endpoint becomes available:

### Stage 1: Mycelium (analytics — simplest)

`mycelium gain --format json` is a read-only query with a stable schema. Once mycelium exposes a socket endpoint, migrate `server/mycelium.ts` first since it has the smallest surface (one query, one schema).

### Stage 2: Canopy (task board)

`server/routes/canopy.ts` currently calls `canopy snapshot` and `canopy task get`. This pairs with the `canopy/dispatch-request-service-endpoint.md` implementation.

### Stage 3: Stipe (health and setup)

`stipe doctor --json` and `stipe init --dry-run --json` are setup-time queries. Lower urgency than the live dashboard data.

### Stage 4: Hyphae (largest surface)

Hyphae has the most CLI surfaces (stats, health, search, sessions, analytics, memoirs). Cap already reads the SQLite database directly for some queries (`server/db.ts`). The socket endpoint migration should be coordinated with hyphae's endpoint registration handoff.

## Verification

```bash
cd cap && npm run build  # TypeScript compilation
cd cap && npm test       # unit and contract tests
```

Manually verify dashboard renders correctly for each migrated data source. The septa schemas remain the source of truth for payload shapes — the migration changes the transport, not the payload.

## Context

- C7: all four integrations classified as "operator surface" with migration note "should transition to HTTP or socket endpoint"
- C8: `docs/foundations/inter-app-communication.md` tier 2 (local service endpoint) is the preferred cross-binary integration
- `septa/local-service-endpoint-v1.schema.json` defines the endpoint descriptor format
- `spore/src/transport.rs` (`LocalServiceClient`) is the Rust-side transport client that sibling tools will use to expose these endpoints; cap's Node.js side needs a matching client in `server/lib/local-service.ts`
