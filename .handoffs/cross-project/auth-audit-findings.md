# Auth and Access Control Audit Findings

**Date:** 2026-04-23
**Scope:** volva-auth, canopy DispatchPolicy, cap server
**Pass:** Read-only audit (U4 Pass 1)

---

## Verdict Summary

| Surface | Verdict | Severity |
|---------|---------|----------|
| volva-auth | Adequate | Low |
| canopy dispatch policy | Adequate | Low |
| cap server | Adequate by design | Medium (if exposed on LAN without CAP_API_KEY) |

---

## Surface 1: volva-auth

**Credential storage**
- Path: `~/.volva/auth/anthropic.json` — plaintext JSON
- Contains: access_token, refresh_token, api_key, expires_at, scopes, email, org_id, subscription_type
- File permissions: `0o600` on Unix — correct. Written atomically via temp file to prevent race conditions.
- No encryption at rest. Acceptable for a localhost-first single-user tool; would be a gap in a multi-user deployment.

**Token validation**
- Bearer tokens checked for expiration via `is_expired_at()` before use.
- API keys have no expiration field and are assumed valid.
- Expired tokens return `None` — clear error path, not silent failure.
- Users are directed to re-authenticate via `login_hint()` messages.

**Secrets handling**
- API keys, access tokens, and refresh tokens are not logged, printed to stderr, or included in tracing spans.
- Tracing uses correlation IDs only.

**Verdict:** Adequate for localhost-first use. No action required unless multi-user deployment is planned.

---

## Surface 2: canopy DispatchPolicy

**DispatchDecision::Proceed conditions**
- Read-only tools (21 known): auto-proceed
- Idempotent tools (6 known): auto-proceed
- Unknown tools: auto-proceed (permissive default)
- Destructive tools (4 known): FlagForReview

**Task ownership enforcement**
- Claim is atomic via SQL: `UPDATE tasks WHERE task_id=? AND status='open' AND owner_agent_id IS NULL`
- An agent cannot claim a task already owned by another agent — SQL constraint enforces this at the store level.
- Returns `Option<Task>`: `None` on collision, `Some(task)` on success.
- Concurrency cap available via `atomic_claim_task_with_cap()`.

**Gaps found**
- No rate limiting on task creation — a misconfigured or runaway agent can create unbounded tasks. Acceptable for the current single-operator model; a real gap if untrusted agents join.
- Policy decisions are not logged durably — evaluated in memory only. No audit trail for which decisions were made and why.
- Task store operations (create/update) are not gated by dispatch policy by design — policy gates MCP tool calls, not the store directly. This is intentional but worth noting: a code path that writes to the store without going through MCP bypasses policy entirely.

**Verdict:** Adequate for current use. Ownership enforcement is correct. Rate limiting and durable policy logging are gaps worth addressing before untrusted agents are introduced.

---

## Surface 3: cap server

**Authentication middleware**
- Bearer token middleware is present on all `/api/*` routes.
- Checks `Authorization: Bearer <token>` against `CAP_API_KEY` env var.
- Health check and client-config endpoints bypass auth intentionally.

**Critical gap — optional auth**
- If `CAP_API_KEY` is not set, all requests are allowed with no authentication.
- This is acceptable when the server binds to `127.0.0.1` (the default), since LAN cannot reach it.
- If `CAP_HOST` is changed to `0.0.0.0` without setting `CAP_API_KEY`, anyone on the LAN can modify tasks, config, and invoke write routes with no authentication. There is no startup warning for this combination.

**CORS policy**
- Restricted to a single origin (default: `http://localhost:5173`).
- Configurable via `CORS_ORIGIN` env var.
- No wildcard origins.

**Write routes (all behind middleware when CAP_API_KEY is set)**
- `POST /api/canopy/tasks/:taskId/actions` — task operations
- `POST /api/canopy/handoffs/:handoffId/actions` — handoff operations
- `POST /api/canopy/notifications/:id/mark-read` — notification state
- `POST /api/lsp/install` — shells out to rhizome
- `POST /api/settings/hyphae/prune` — shells out to hyphae
- `PUT /api/settings/mycelium` — writes config file

**LAN exposure scenarios**
- **Default (127.0.0.1, no CAP_API_KEY):** Safe — LAN cannot reach the port.
- **CAP_HOST=0.0.0.0, CAP_API_KEY set:** Safe — auth required.
- **CAP_HOST=0.0.0.0, no CAP_API_KEY:** Unsafe — no authentication, anyone on LAN has full write access. No warning is currently emitted.

**Verdict:** Adequate by design for localhost-first use. The missing startup warning for the exposed+unauthenticated combination is a real gap.

---

## Recommended Follow-up

| # | Surface | Issue | Severity | Action |
|---|---------|-------|----------|--------|
| 1 | cap | No startup warning when `CAP_HOST != 127.0.0.1` and `CAP_API_KEY` unset | Medium | Add warning on server start |
| 2 | canopy | No per-agent rate limit on task creation | Medium | Add before introducing untrusted agents |
| 3 | canopy | Policy decisions not logged durably | Medium | Add `policy_events` table before audit requirements exist |
| 4 | volva | Credential storage posture not documented | Low | Document in CLAUDE.md or security notes |

Items 2 and 3 can wait until the agent model expands beyond the current single-operator pattern. Item 1 is the most actionable now — it's a small startup check that prevents a silent misconfiguration.

---

## Child Handoffs

If any follow-up items are prioritized, open child handoffs for:
- `cap/server-exposure-warning.md` — add startup check for `CAP_HOST` + `CAP_API_KEY` combination
- `canopy/dispatch-rate-limiting.md` — per-agent task-creation rate cap
- `canopy/policy-event-log.md` — durable audit log for dispatch decisions
