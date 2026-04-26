# Cap: Watcher Framework

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/src/api/watchers.ts` (new), `cap/src/lib/watchers/` (new), `cap/src/store/` (watcher config)
- **Cross-repo edits:** none in this handoff
- **Non-goals:** no Slack or Telegram adapters; no persistent event log; no auth beyond HMAC secret validation; no webhook retry or dead-letter queue
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Extracted from the agent-deck ecosystem borrow audit (`.audit/external/audits/agent-deck-ecosystem-borrow-audit.md`) and Wave 2 ecosystem synthesis (Theme 6: event-forwarding adapters):

> "agent-deck's conductor receives events via lightweight watchers — adapters that listen on a channel, validate the payload, and route to the correct session action. Each watcher is a named adapter registered at startup."

> "Best fit: `cap` (dashboard API layer), watcher registry in cap config."

## Implementation Seam

- **Likely repo:** `cap` (TypeScript/React + Hono backend)
- **Likely files/modules:**
  - `src/api/watchers.ts` (new) — Hono routes for the webhook watcher POST endpoint
  - `src/lib/watchers/types.ts` (new) — `WatcherAdapter` interface and `CapEvent` union type
  - `src/lib/watchers/webhook.ts` (new) — `WebhookWatcher` implementation with HMAC validation
  - `src/lib/watchers/github.ts` (new) — `GithubWatcher` listening for push/PR payloads
  - `src/lib/watchers/registry.ts` (new) — watcher registry: register adapters at startup, iterate on incoming events
  - `src/store/` (update) — watcher config (enabled adapters, secrets)
- **Reference seams:**
  - `cap/src/api/` — read existing API structure and Hono route patterns before adding
  - `cap/src/store/` — read existing config/store patterns before adding watcher config
- **Spawn gate:** read cap's existing API and store structure before spawning

## Problem

Cap is a pull-based dashboard. It has no mechanism for receiving inbound events from external sources — GitHub push hooks, custom webhooks, or notification services. Operators cannot automate session starts or dashboard updates in response to external triggers.

agent-deck's watcher pattern shows the right shape: a named adapter interface that converts inbound events into typed cap actions, registered at startup. The key insight is that watchers are thin adapters — they do not contain business logic, they only validate, transform, and forward.

## What needs doing (intent)

1. Define the `WatcherAdapter` TypeScript interface and `CapEvent` union type
2. Implement `WebhookWatcher` — POST endpoint at `/api/watchers/webhook` with HMAC secret validation
3. Implement `GithubWatcher` — listen for GitHub push and PR events via webhook, transform to `CapEvent`
4. Add a watcher registry that registers adapters at startup and routes `CapEvent` values to cap actions
5. Wire the watcher routes into cap's existing Hono API layer
6. Store watcher config (enabled adapters, secrets) in cap's existing store

## Data model

```typescript
interface WatcherAdapter {
  name: string;
  listen(): AsyncIterable<RawEvent>;
  validate(event: unknown): event is RawEvent;
  transform(event: RawEvent): CapEvent;
}

interface RawEvent {
  source: string;
  payload: unknown;
  received_at: string; // ISO 8601
}

type CapEvent =
  | { type: 'session_start'; session_id: string }
  | { type: 'notify'; message: string; severity: 'info' | 'warning' | 'error' }
  | { type: 'dashboard_update'; data: Record<string, unknown> };

interface WatcherConfig {
  enabled: string[];         // adapter names that are active
  webhook_secret: string;    // HMAC secret for WebhookWatcher
  github_secret: string;     // HMAC secret for GithubWatcher
}
```

## API routes

```
POST /api/watchers/webhook    — receive raw webhook payload; validates HMAC; emits CapEvent
POST /api/watchers/github     — receive GitHub event; validates X-Hub-Signature-256; emits CapEvent
GET  /api/watchers            — list registered adapters and their enabled status
```

## HMAC validation

On each `POST /api/watchers/webhook` and `POST /api/watchers/github`:
1. Read the raw body before JSON parsing
2. Compute `HMAC-SHA256(secret, raw_body)` using Node's `crypto` module
3. Compare to the `X-Hub-Signature-256` (GitHub) or `X-Webhook-Signature` (generic) header using a constant-time comparison
4. Reject with HTTP 401 if signatures do not match
5. Only parse and route the payload after validation passes

## Scope

- **Allowed files:** `cap/src/api/watchers.ts` (new), `cap/src/lib/watchers/` (new directory with types, webhook, github, registry modules), `cap/src/store/` (watcher config extension)
- **Explicit non-goals:**
  - No Slack, Telegram, or ntfy adapters in this handoff
  - No persistent event log or event replay
  - No webhook retry logic or dead-letter queue
  - No auth beyond HMAC secret validation

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `cap/src/api/` — what routes exist? What Hono pattern do they follow?
2. `cap/src/store/` — how is config/state stored?
3. `cap/src/` — is there an existing event bus or emitter pattern to extend?

---

### Step 1: Define types

**Project:** `cap/`
**Effort:** tiny
**Depends on:** Step 0

Create `src/lib/watchers/types.ts`. Define `WatcherAdapter`, `RawEvent`, `CapEvent`, and `WatcherConfig` exactly as specified in the data model above.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Checklist:**
- [ ] `WatcherAdapter` interface defined
- [ ] `CapEvent` union type defined with three variants
- [ ] `WatcherConfig` interface defined
- [ ] TypeScript compiles without errors

---

### Step 2: Implement watcher registry

**Project:** `cap/`
**Effort:** small
**Depends on:** Step 1

Create `src/lib/watchers/registry.ts`. The registry holds registered `WatcherAdapter` instances, allows lookup by name, and provides a `dispatch(event: CapEvent)` function that routes events to cap actions. Wire dispatch to a simple console log and a no-op handler stub — the real action handlers are follow-on work.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Checklist:**
- [ ] Registry accepts adapter registration
- [ ] `dispatch` function routes `CapEvent` by type
- [ ] Registry compiles without errors

---

### Step 3: Implement WebhookWatcher and GithubWatcher

**Project:** `cap/`
**Effort:** small
**Depends on:** Step 2

Create `src/lib/watchers/webhook.ts` and `src/lib/watchers/github.ts`. Each implements `WatcherAdapter`. Both validate their respective HMAC signatures before transforming payloads. `GithubWatcher` maps `push` events to `dashboard_update` and `pull_request` opened/closed events to `notify`.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Checklist:**
- [ ] `WebhookWatcher` validates HMAC and transforms payload to `CapEvent`
- [ ] `GithubWatcher` validates `X-Hub-Signature-256` and maps push/PR to `CapEvent`
- [ ] Both reject with 401 on bad signatures
- [ ] Both compile without errors

---

### Step 4: Add API routes and wire into Hono

**Project:** `cap/`
**Effort:** small
**Depends on:** Step 3

Create `src/api/watchers.ts`. Add Hono routes for `POST /api/watchers/webhook`, `POST /api/watchers/github`, and `GET /api/watchers`. Register the routes in cap's main app. Register `WebhookWatcher` and `GithubWatcher` in the watcher registry at startup using config from `WatcherConfig`.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Checklist:**
- [ ] Routes registered in Hono app
- [ ] `GET /api/watchers` returns list of adapters
- [ ] `POST /api/watchers/webhook` reachable
- [ ] `POST /api/watchers/github` reachable

---

### Step 5: Full suite

```bash
cd cap && npm run build 2>&1 | tail -5
cd cap && npm test 2>&1 | tail -20
```

**Checklist:**
- [ ] Cap build succeeds with no TypeScript errors
- [ ] Cap tests pass
- [ ] HMAC rejection verified by test or manual curl with wrong secret

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step has verification output
2. Full build and test suite pass in cap
3. All checklist items checked
4. `.handoffs/HANDOFFS.md` updated

## Follow-on work (not in scope here)

- Persistent event log: store each `RawEvent` and `CapEvent` in SQLite for replay and audit
- Slack and ntfy adapters following the same `WatcherAdapter` interface
- Webhook retry logic and dead-letter queue for failed dispatches
- Real `session_start` action handler wired to canopy session creation
- Per-adapter enable/disable toggle in cap's operator UI

## Context

Spawned from Wave 2 audit program (2026-04-23). agent-deck's watcher pattern shows that event-forwarding adapters need only a thin interface: name, listen, validate, transform. The conductor (registry) handles routing. For cap, this means the dashboard can react to external triggers — GitHub pushes, custom webhooks — without polling. The HMAC validation step is the critical security seam: raw body must be captured before JSON parsing, and comparison must be constant-time to prevent timing attacks.
