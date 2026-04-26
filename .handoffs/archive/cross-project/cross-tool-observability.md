# Cross-Tool Observability

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** cross-project (changes distributed across cortina, hyphae, canopy, cap, volva)
- **Allowed write scope:** logging/tracing setup in each named repo
- **Cross-repo edits:** yes — structured log fields and trace IDs added to each integration seam
- **Non-goals:** building a new observability backend; replacing existing `tracing` usage; adding metrics/dashboards (that belongs in cap)
- **Verification contract:** a single cross-tool operation (e.g., hook fires → hyphae write → canopy read) produces correlated log lines with the same trace/correlation ID
- **Completion update:** once correlated log lines confirmed across at least 3 tools, update dashboard and archive

## Context

The Phase 5 Pass 2 audit found that each tool logs independently with no correlation between them. When something breaks at a seam (e.g., volva times out waiting for hyphae, cortina fails to write a session signal, cap gets a 500 from canopy), operators have no way to correlate the failure across tools without manually reading log files from multiple repos.

The ecosystem already uses `tracing` across Rust repos. This is an enrichment pass, not a new infrastructure build.

## Implementation Seam

- **Likely repos:** cortina, hyphae, canopy, cap (server), volva
- **Likely files:** existing tracing setup (`tracing_subscriber` init, span creation at integration points)
- **Reference seams:** read how cortina currently logs hook events before adding to it
- **Spawn gate:** do not spawn an implementer until you have confirmed the `tracing` crate version and subscriber setup in at least two repos, so correlation IDs use a compatible span format

## Problem

Each tool logs in isolation. A cortina hook fires and logs "hook completed." Hyphae receives a write and logs "memory stored." Canopy reads evidence and logs "snapshot produced." Cap renders the result. If any step fails, these log lines are unconnected — operators cannot correlate them to a single session or tool invocation without reading timestamps manually across multiple files.

## What needs doing (intent)

Add a correlation ID (session-scoped, not per-request) that flows through the primary integration paths:

1. cortina → hyphae: include session ID as a structured log field at write time
2. hyphae → canopy: include evidence source session ID in structured log at snapshot time
3. volva → hyphae: include session ID at protocol/recall load time
4. cap server: log canopy CLI call result with timestamp and duration

The goal is that grep-ing a session ID across all tool logs returns a coherent timeline.

## Scope

- **Primary seam:** structured log fields at integration call sites
- **Allowed files:** tracing span setup and log call sites at the 6 seams
- **Explicit non-goals:** new observability UI; metrics collection; log aggregation infrastructure; changing log output format

---

### Step 1: Audit current logging at each seam

**Project:** all repos
**Effort:** 1 hour
**Depends on:** nothing

Read the current log call sites at each integration seam:
- `cortina/src/utils/session_scope.rs` — what is logged at session-end write?
- `hyphae/crates/hyphae-mcp/src/server.rs` — what is logged at memory-store calls?
- `canopy/src/api.rs` — what is logged at snapshot creation?
- `volva/crates/volva-runtime/src/context.rs` — what is logged at protocol/recall load?
- `cap/server/routes/canopy.ts` — what is logged at CLI call?

Document: what fields are currently in each log line? Is a session ID present anywhere?

#### Verification

```bash
grep -n "tracing::\|log::\|eprintln\|warn!\|info!\|error!" \
  cortina/src/utils/session_scope.rs | head -20
grep -n "info!\|warn!\|error!" \
  hyphae/crates/hyphae-mcp/src/server.rs | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Current log fields documented at each seam
- [ ] Session ID presence/absence confirmed at each site

---

### Step 2: Define correlation ID propagation model

**Project:** all repos
**Effort:** 30 min (design only)
**Depends on:** Step 1

Decide: where does the correlation ID come from and how does it flow?

Options:
- **Session ID** (already exists in cortina's session scope): simplest, already threaded through cortina, propagate via structured log field `session_id`
- **ULID per tool invocation**: finer-grained, but requires a new ID at each call site
- **Env var propagation**: set `BASIDIOCARP_SESSION_ID` in cortina's hook scripts; downstream tools read it

The simplest approach for this ecosystem: use the cortina session ID (already a ULID) as the correlation ID. Pass it as a structured tracing field. In cap (TypeScript), pass it as a request header or log field.

Document the chosen approach before Step 3.

#### Verification

```bash
# Confirm cortina session ID is a ULID
grep -r "session_id\|ulid\|Ulid" cortina/src/ | head -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Correlation ID source confirmed
- [ ] Propagation mechanism decided (log field vs. env var vs. header)

---

### Step 3: Add session ID to cortina log calls

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** Step 2

At each integration point in cortina, add `session_id` as a structured tracing field:

```rust
tracing::info!(
    session_id = %session_state.session_id,
    "cortina: writing session signal to hyphae"
);
```

Key sites: session-end write, hook success/failure, signal store call.

#### Verification

```bash
cd cortina && cargo test && cargo clippy -- -D warnings
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `session_id` field present in log calls at hyphae write sites
- [ ] No new clippy warnings

---

### Step 4: Add duration and status logging to volva timeout paths

**Project:** `volva/`
**Effort:** 1 hour
**Depends on:** Step 2

At timeout paths in `context.rs`, add warning log with duration and session context:

```rust
tracing::warn!(
    timeout_ms = MEMORY_PROTOCOL_TIMEOUT.as_millis(),
    "volva: hyphae protocol load timed out — session starts without memory context"
);
```

This surfaces the silent timeout (fix #14) as a structured log event.

#### Verification

```bash
cd volva && cargo test && cargo clippy -- -D warnings
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Timeout path logs warning with duration
- [ ] No panics on timeout

---

### Step 5: Add duration logging to cap canopy CLI call

**Project:** `cap/`
**Effort:** 30 min
**Depends on:** Step 2

In `cap/server/routes/canopy.ts`, log the canopy CLI call result with timing:

```typescript
const start = Date.now();
try {
  const snapshot = await canopy.getSnapshot();
  logger.info({ duration_ms: Date.now() - start }, 'canopy snapshot fetched');
  return snapshot;
} catch (err) {
  logger.error({ duration_ms: Date.now() - start, error: err.message }, 'canopy snapshot failed');
  throw err;
}
```

#### Verification

```bash
cd cap && npm run build && npm test
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Duration logged on success and failure
- [ ] Error message included in failure log (not swallowed)

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Session ID present as a structured field in cortina log calls at hyphae write sites
2. Volva timeout paths log a warning with duration
3. Cap canopy CLI call logs duration and error message
4. A single simulated operation produces correlated log lines traceable by session ID across at least 3 tools
5. No production behavior changed — logging only

### Final Verification

```bash
bash .handoffs/cross-project/verify-cross-tool-observability.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->
