# Cap: Session Persistence and Cost Tracking

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/src/` (new session and cost API routes + UI components)
- **Cross-repo edits:** `canopy/src/store/` (store conversation_id in session snapshots), `septa/` (cost-report-v1 schema — follow-on)
- **Non-goals:** does not implement tmux process management; does not add Telegram/Slack bots; does not add external cost data integrations; does not replace canopy's session identity model
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Extracted from the agent-deck ecosystem borrow audit (`.audit/external/audits/agent-deck-ecosystem-borrow-audit.md`):

> "Agent-deck persists ClaudeSessionID through tmux crashes, SSH logouts, and process SIGKILLs... When a session restarts, it looks up the prior conversation ID and passes --resume <id> to Claude, restoring full history."

> "Agent-deck tracks token usage from Claude transcripts (13 models priced), enforces daily/weekly/monthly/per-session/per-group budget limits with 80% warning and 100% hard stop, and exposes costs via TUI ($), web dashboard, and CSV export."

> "Best fit: `cap` (dashboard), `canopy` (snapshot API), `septa` (cost reporting contract)."

## Implementation Seam

- **Likely repo:** `cap` (TypeScript/React dashboard)
- **Likely files/modules:**
  - `src/api/sessions.ts` (new) — session persistence API (store + retrieve conversation_id)
  - `src/api/costs.ts` (new) — cost tracking API (record + query cost entries)
  - `src/components/CostDashboard/` (new) — cost dashboard UI component
  - `src/components/SessionPanel/` (update) — add resume button using persisted conversation_id
- **Reference seams:**
  - `cap/src/api/` — read existing API structure before adding
  - `cap/src/components/` — read existing component patterns
  - `canopy/src/store/` — understand how session snapshots are stored
- **Spawn gate:** read cap's existing API and component structure before spawning

## Problem

Cap has no persistent session identity. When a session restarts (SSH disconnect, crash, reload), there is no way to resume the prior conversation. There is also no cost tracking — the operator has no visibility into token spend, no budget enforcement, and no historical cost data.

agent-deck shows both are production concerns: session resumption requires only persisting a `conversation_id` and passing `--resume` on restart. Cost tracking requires a simple cost entry store with budget limit enforcement.

## What needs doing (intent)

1. Add `conversation_id` persistence to canopy session snapshots
2. Add a cap API route for recording and querying cost entries
3. Add budget configuration with 80% warning + 100% hard stop
4. Add a cost dashboard UI panel in cap
5. Add a "Resume" action in cap's session panel that uses the persisted conversation_id

## Data model

### Session resumption (canopy + cap)

Canopy session snapshots should store `conversation_id` (the Claude conversation ID returned on first interaction). Cap reads this and passes `--resume <conversation_id>` when restarting a session.

```typescript
interface SessionSnapshot {
  session_id: string;
  conversation_id: string | null;  // null if never started
  started_at: string;
  last_active_at: string;
  status: 'active' | 'paused' | 'terminated';
}
```

### Cost tracking

```typescript
interface CostEntry {
  entry_id: string;       // ULID
  session_id: string;
  model: string;          // e.g. "claude-opus-4-6"
  prompt_tokens: number;
  completion_tokens: number;
  cost_usd: number;
  recorded_at: string;    // ISO 8601
}

interface BudgetConfig {
  daily_limit_usd: number | null;
  weekly_limit_usd: number | null;
  monthly_limit_usd: number | null;
  per_session_limit_usd: number | null;
  warn_at_percent: number;   // default: 80
}

type BudgetStatus =
  | { status: 'ok'; spent_usd: number; limit_usd: number }
  | { status: 'warning'; spent_usd: number; limit_usd: number; percent: number }
  | { status: 'exceeded'; spent_usd: number; limit_usd: number };
```

## API routes

```
POST /api/sessions/{id}/cost          — record a cost entry
GET  /api/sessions/{id}/cost          — list cost entries for session
GET  /api/sessions/{id}/cost/total    — total cost for session
GET  /api/cost/summary                — aggregate cost by day/week/month
GET  /api/cost/budget/status          — current BudgetStatus
GET  /api/sessions/{id}/conversation  — retrieve persisted conversation_id
POST /api/sessions/{id}/conversation  — store conversation_id after first turn
```

## Budget enforcement

On each `POST /api/sessions/{id}/cost`:
1. Compute new cumulative spend for the relevant period (day/week/month/session)
2. Compare to limits in BudgetConfig
3. If > warn_at_percent (default 80%) → return `BudgetStatus.warning` in response header
4. If ≥ 100% of any limit → return HTTP 402 with `BudgetStatus.exceeded`
5. Cap UI listens for warning/exceeded responses and displays alert banner

## Scope

- **Allowed files:** `cap/src/api/sessions.ts` (update), `cap/src/api/costs.ts` (new), `cap/src/components/CostDashboard/` (new), `cap/src/components/SessionPanel/` (update for resume button), canopy store for conversation_id field
- **Explicit non-goals:**
  - No tmux process management
  - No Telegram/Slack notification adapters
  - No external cost API integrations (Anthropic billing API)
  - No CSV export in this handoff (follow-on)

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `cap/src/api/` — what API routes exist? What pattern do they follow?
2. `cap/src/components/` — how are UI components structured?
3. `canopy/src/store/` — does canopy already store conversation_id in snapshots?

---

### Step 1: Add conversation_id to canopy session snapshots

**Project:** `canopy/`
**Effort:** tiny
**Depends on:** Step 0

Add `conversation_id TEXT` column to the sessions/snapshots table. Add a store function and a retrieval function.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] sessions table has nullable `conversation_id` column
- [ ] store + retrieve functions compile

---

### Step 2: Add cost tracking API in cap

**Project:** `cap/`
**Effort:** small
**Depends on:** Step 1

Create `src/api/costs.ts`. Implement the cost entry routes listed above. Store cost entries in cap's SQLite (or canopy's store via API). Implement budget enforcement logic on POST.

#### Verification

```bash
cd cap && npm test 2>&1 | tail -20
```

**Checklist:**
- [ ] `POST /api/sessions/{id}/cost` records entry and enforces budget
- [ ] `GET /api/cost/summary` returns aggregate by day/week/month
- [ ] `GET /api/cost/budget/status` returns correct BudgetStatus
- [ ] Warning returned at 80%, 402 at 100%

---

### Step 3: Add cost dashboard UI

**Project:** `cap/`
**Effort:** medium
**Depends on:** Step 2

Create `src/components/CostDashboard/` with:
- Running total by period (today / this week / this month)
- Per-session cost list
- Budget bar showing % of limit consumed
- Warning banner when BudgetStatus is warning or exceeded

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Checklist:**
- [ ] CostDashboard component renders without errors
- [ ] Budget bar shows correct percentage
- [ ] Warning banner appears when status is warning or exceeded

---

### Step 4: Add Resume button in session panel

**Project:** `cap/`
**Effort:** small
**Depends on:** Step 3

Update `src/components/SessionPanel/` to show a "Resume" button when a session has a persisted `conversation_id`. The button constructs the `--resume <conversation_id>` flag and passes it through the session restart flow.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Checklist:**
- [ ] Resume button visible when conversation_id is present
- [ ] Resume button absent when conversation_id is null
- [ ] Correct --resume flag constructed

---

### Step 5: Full suite

```bash
cd cap && npm run build 2>&1 | tail -5
cd cap && npm test 2>&1 | tail -20
cd canopy && cargo test 2>&1 | tail -10
```

**Checklist:**
- [ ] Cap build succeeds
- [ ] Cap tests pass
- [ ] Canopy tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step has verification output
2. Full test suite passes in cap and canopy
3. All checklist items checked
4. `.handoffs/HANDOFFS.md` updated

## Follow-on work (not in scope here)

- `septa/cost-report-v1.schema.json` — define the cost reporting contract for cross-tool consumption
- CSV export of cost history
- Per-group budget overrides (e.g., different limits per project or team)
- Watcher framework: atomic event claiming, HMAC verification, SQLite dedup (agent-deck watcher pattern)
- Cost breakdown by tool type (rhizome vs. hyphae calls)

## Context

Spawned from Wave 2 audit program (2026-04-23). agent-deck's session persistence shows that conversation resumption requires almost nothing — just persisting the conversation_id returned by Claude on first turn and passing --resume on restart. The cost tracking system is more substantial but follows a clear pattern: record CostEntry per turn, aggregate by period, compare to BudgetConfig limits, enforce at 80% (warn) and 100% (hard stop). Both patterns are independent of tmux — the portable ideas are the data model and enforcement logic, not the process management shell.
