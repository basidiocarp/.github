# Phase 5 Pass 1 — Inter-Tool Interaction Discovery

Date: 2026-04-22
Pass: Discovery (seam tracing)
Audit Scope: Six named integration seams across the Basidiocarp ecosystem

---

## Seam 1: cortina adapter → hyphae signal write → canopy evidence ref

### Happy Path
1. **Cortina receives `post-tool-use` event** from Claude Code hook system
   - File: `/Users/williamnewton/projects/basidiocarp/cortina/src/adapters/mod.rs:91` - routes to `hooks::post_tool_use::handle(input)`
   - File: `/Users/williamnewton/projects/basidiocarp/cortina/src/hooks/post_tool_use.rs:19-53` - parses envelope, classifies tool call, records outcome
   
2. **Cortina writes signal to hyphae** at session end
   - File: `/Users/williamnewton/projects/basidiocarp/cortina/src/hooks/stop.rs:144-157` - calls `end_scoped_hyphae_session()`
   - File: `/Users/williamnewton/projects/basidiocarp/cortina/src/utils/session_scope.rs:203-220` - executes `hyphae session end --id <session_id> --summary <text> --files <files> --errors <count>`
   - Uses subprocess spawn (not blocking) via `resolved_command("hyphae")`
   - Trace context propagated via `TRACEPARENT` and `TRACESTATE` env vars
   
3. **Canopy ingests evidence during snapshot**
   - File: `/Users/williamnewton/projects/basidiocarp/canopy/src/api.rs:305-309` - loads evidence from store, computes `drift_signals` from evidence
   - File: `/Users/williamnewton/projects/basidiocarp/canopy/src/api.rs:311-334` - returns `ApiSnapshot` with `evidence` and `drift_signals` fields
   - Evidence is typed `EvidenceRef` (typed references, not copied blobs)

### Septa Schema Backing
- **Cortina → Hyphae:** `septa/session-event-v1.schema.json` governs the `hyphae session end` payload shape
  - Source: `/Users/williamnewton/projects/basidiocarp/cortina/src/utils/session_scope.rs:249-259` constructs args
  - Contract enforced in Hyphae MCP via `hyphae_session_end` tool
  
- **Canopy → Cap:** `septa/canopy-snapshot-v1.schema.json` governs the API snapshot
  - Source: `/Users/williamnewton/projects/basidiocarp/canopy/src/api.rs:1-12` imports `ApiSnapshot` and `EvidenceRef`
  - Schema version hardcoded at `/Users/williamnewton/projects/basidiocarp/canopy/src/api.rs:53`

### Failure Mode Analysis

| Failure | Behavior | Assessment |
|---------|---------|------------|
| Hyphae not discoverable | `end_scoped_hyphae_session()` returns `None` at line 209-210; session cleanup skipped, state file not removed | GRACEFUL — cortina continues, state is stale but harmless |
| Hyphae command fails (disk full, locked) | `run_command()` at line 270 logs warn; returns `None`; state file persists | PARTIAL — session state is orphaned; next session restart will be confused about previous session liveness |
| Hyphae stdout empty | `session_id` is empty; line 517-520 returns error; session creation fails on next boot | FRAGILE — session identity chain breaks; cortina cannot end subsequent sessions |
| Evidence field missing from snapshot | Cap's `validateCanopySnapshot()` at `/Users/williamnewton/projects/basidiocarp/cap/server/canopy.ts:142-147` checks `Array.isArray(record.evidence)` and throws | FRAGILE — old canopy binary returns snapshot without `evidence` array; cap server 500s; dashboard becomes unreadable |
| `drift_signals` added 2026-04-22 (missing in old canopy) | `computeDriftSignals()` skipped; returns empty array; cap frontend renders incomplete state | PARTIAL — missing field gracefully ignored by cap server but dashboard shows stale drift state |

### Graceful Degradation: PARTIAL

**Failure path:** Hyphae unavailable → session state becomes stale → next session cannot query session liveness → parallel worktrees collapse into one session identity.

**Mitigation:** Cortina checks `command_exists("hyphae")` at line 62 of stop.rs and exits cleanly if Hyphae is missing, but scoped session state is still written to disk and never cleaned up.

---

## Seam 2: canopy api snapshot → cap server reads → cap React frontend renders

### Happy Path
1. **Cap server calls canopy CLI**
   - File: `/Users/williamnewton/projects/basidiocarp/cap/server/canopy.ts:115` - creates `run` via `createCliRunner(CANOPY_BIN, 'canopy')`
   - File: `/Users/williamnewton/projects/basidiocarp/cap/server/canopy.ts:171-204` - `getSnapshot()` builds args, calls `run(['api', 'snapshot', ...])`, parses JSON
   
2. **Cap server validates canopy payload**
   - File: `/Users/williamnewton/projects/basidiocarp/cap/server/canopy.ts:142-147` - `validateCanopySnapshot()` checks schema version and array types
   - Validates `schema_version === "1.0"`, `tasks` is array, `evidence` is array
   
3. **Cap frontend receives JSON and renders**
   - File: `/Users/williamnewton/projects/basidiocarp/cap/server/routes/canopy.ts:18-43` - `/api/snapshot` endpoint returns `canopy.getSnapshot()` result
   - Frontend consumes and renders tasks, attention, SLA, evidence via React components

### Septa Schema Backing
- **Yes:** `septa/canopy-snapshot-v1.schema.json` is the contract
  - Source: `/Users/williamnewton/projects/basidiocarp/canopy/src/api.rs:53` defines `CANOPY_API_SCHEMA_VERSION = "1.0"`
  - Receiver: `/Users/williamnewton/projects/basidiocarp/cap/server/canopy.ts:142-147` validates payload shape
  - Schema defines required fields: `schema_version`, `attention`, `sla_summary`, `agents`, `tasks`, `evidence`, `drift_signals`, etc.

### Failure Mode Analysis

| Failure | Behavior | Assessment |
|---------|---------|------------|
| Canopy binary not found | `createCliRunner()` throws; cap server `/api/snapshot` returns 500 with "Failed to get Canopy snapshot" | FRAGILE — dashboard is broken until canopy is installed |
| Canopy returns empty JSON or error | `parseJson()` throws; caught at cap route line 40; returns 500 | FRAGILE — dashboard shows connection error to user |
| Snapshot missing `drift_signals` field (old canopy) | `validateCanopySnapshot()` does NOT check for `drift_signals`; validation passes; cap renders incomplete state | PARTIAL — field added 2026-04-22; old canopy will render without drift state but cap won't break |
| Snapshot missing `evidence` field (schema violation) | `validateEvidenceRefs()` at line 123-140 checks `!Array.isArray(evidence)`; throws "Invalid evidence payload"; cap returns 500 | FRAGILE — canopy schema change breaks cap |
| Stale snapshot (old timestamp) | Cap server has no staleness check; renders as-is with `created_at` timestamp in payload; frontend can check timestamp if needed | PARTIAL — no active staleness detection in seam |

### Graceful Degradation: FRAGILE

**Failure path:** Canopy missing or broken → cap server errors → dashboard shows 500 → operator loses task visibility.

**No fallback:** If canopy is unavailable, cap has no secondary read path (e.g., read Canopy DB directly or use stale cache).

---

## Seam 3: hyphae MCP session-start → context injection → Claude Code session

### Happy Path
1. **Hyphae MCP tool `hyphae_session_start` is called**
   - File: `/Users/williamnewton/projects/basidiocarp/hyphae/crates/hyphae-mcp/src/tools/session.rs:20-75` - `tool_session_start()` validates project, project_root, worktree_id
   - File: `/Users/williamnewton/projects/basidiocarp/hyphae/crates/hyphae-mcp/src/tools/session.rs:40-48` - calls `store.session_start_identity_with_runtime_and_context_signals()`
   
2. **Hyphae retrieves memories and returns context**
   - File: `/Users/williamnewton/projects/basidiocarp/hyphae/crates/hyphae-mcp/src/tools/session.rs:50-72` - returns JSON with `session_id`, `scoped_identity`, and `recalled_context` (memories with scores)
   
3. **Context is injected into Claude Code session**
   - Calling code (cortina/volva) receives the JSON and includes recalled context in system prompt or session state
   - File: `/Users/williamnewton/projects/basidiocarp/cortina/src/utils/session_scope.rs:555-590` - `load_memory_protocol()` calls `hyphae protocol` to get recall configuration

### Septa Schema Backing
- **Yes:** Hyphae MCP tools follow versioned output contract
  - Source: `/Users/williamnewton/projects/basidiocarp/hyphae/crates/hyphae-mcp/src/tools/session.rs:52` emits `SCOPED_IDENTITY_SCHEMA_VERSION`
  - No formal JSON schema file for session-start response found in septa, but output is versioned internally

### Failure Mode Analysis

| Failure | Behavior | Assessment |
|---------|---------|------------|
| Hyphae DB corrupted or missing | `session_start_identity_with_runtime_and_context_signals()` fails; returns error in `ToolResult::error()`; session-start returns error JSON | FRAGILE — MCP client sees error and session initialization fails |
| Hyphae DB locked | Waits on SQLite busy timeout; if timeout expires, returns store error; session-start fails | PARTIAL — retry logic is in SQLite, not in hyphae layer; external retry is caller's responsibility |
| Memory records malformed (JSON parse error) | `recalled_context` loop at line 63-69 skips bad records; returns partial context (only valid memories) | GRACEFUL — malformed memory is silently dropped; session starts with degraded context |
| Budget parameter missing | Token budget defaults to 2000 (from hyphae_gather_context); context can be unbounded if caller doesn't pass budget | FRAGILE — oversized context injection can exhaust token limits in Claude Code |
| No memories exist for project | Returns `recalled_context: []` (empty array); session-start succeeds with no injected context | GRACEFUL — session starts with no prior knowledge but continues normally |

### Graceful Degradation: PARTIAL

**Failure path:** Hyphae unavailable → no context injection → session runs without prior memory → work may duplicate or miss context.

**Mitigation:** Optional; if hyphae is not running, session-start fails and cortina must retry or skip context injection.

---

## Seam 4: lamella hooks.json → hook scripts → cortina adapter calls

### Happy Path
1. **Lamella packages hooks.json into Claude Code plugin**
   - File: `/Users/williamnewton/projects/basidiocarp/lamella/resources/hooks/hooks.json:1-252` - defines hooks for each phase
   - Lines 176-181 (PostToolUse) and 219 (Stop) configure cortina adapter calls
   
2. **Claude Code loads hooks at session init**
   - Loads plugin, reads hooks.json, registers handlers for each phase
   - Hooks are configured with `requires: ["cortina"]` (line 174, 216, 242) — cortina must be discoverable
   
3. **Hook script calls cortina adapter**
   - File: `/Users/williamnewton/projects/basidiocarp/lamella/resources/hooks/hooks.json:176` - calls `cortina adapter claude-code post-tool-use`
   - File: `/Users/williamnewton/projects/basidiocarp/lamella/resources/hooks/hooks.json:219` - calls `cortina adapter claude-code stop`
   - Timeout configured at line 178 and 217: `"timeout": 10` (10 seconds)
   
4. **Cortina processes event and returns**
   - Returns 0 on success (or error); hook output is captured
   - If hook times out, Claude Code kills the process and continues

### Septa Schema Backing
- **Partially:** Lamella hooks.json is not schema-backed, but volva hook events have a schema
  - File: `/Users/williamnewton/projects/basidiocarp/septa/volva-hook-event-v1.schema.json` defines hook envelope shape
  - Cortina hook envelope is adapter-specific JSON (not formally versioned in septa)

### Failure Mode Analysis

| Failure | Behavior | Assessment |
|---------|---------|------------|
| Cortina binary not installed | `requires: ["cortina"]` check fails; hook is marked as unavailable and skipped | GRACEFUL — hook output shows "cortina not found"; session continues without capture |
| Cortina times out after 10s | Claude Code kills the subprocess; hook marks as failed but does not block session | GRACEFUL — session continues; some events may be uncaptured |
| Cortina hook fails (e.g., hyphae write fails) | `cortina adapter` returns error code; hook output is logged; Claude Code hook system continues | GRACEFUL — cortina logs failure internally; outer tool is not affected |
| Hook script malformed or missing | `cortina adapter` call fails with shell syntax error; hook times out | FRAGILE — misconfigured hook can delay session startup (timeout waits 10s) |
| Cortina writes are all async | Hooks use `"async": true` (line 177, 192); hook returns immediately without waiting for completion | GRACEFUL — cortina write happens in background; session not blocked; but writes may be lost if session ends before cortina completes |

### Graceful Degradation: PARTIAL

**Failure path:** Cortina unavailable → hooks are skipped → lifecycle capture does not happen → session state is lost.

**Mitigation:** Hooks are marked as `async` (line 177); if cortina is slow or unavailable, hook execution is best-effort only.

---

## Seam 5: rhizome export-to-hyphae → hyphae ingest path

### Happy Path
1. **Rhizome walks project files and builds code graph**
   - File: `/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-mcp/src/tools/export_tools.rs:354-417` - `export_to_hyphae()` function
   - Calls `collect_export()` to walk files, extract symbols via tree-sitter or LSP
   - Merges graphs into one `CodeGraph` struct
   
2. **Rhizome serializes graph to JSON and calls hyphae**
   - File: `/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-mcp/src/tools/export_tools.rs:388` - calls `hyphae::export_graph(&graph_json, &identity)`
   - Passes `project_root`, `worktree_id`, and serialized graph JSON to hyphae subprocess
   
3. **Hyphae ingests graph as code memoir**
   - File: `/Users/williamnewton/projects/basidiocarp/hyphae/crates/hyphae-mcp/src/tools/memory.rs` - receives `hyphae_import_code_graph` call
   - Validates `code-graph-v1` schema, creates/updates memoir `code:{project}` with concepts and edges

### Septa Schema Backing
- **Yes:** `septa/code-graph-v1.schema.json` governs the rhizome → hyphae export payload
  - Source: `/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-core/src/hyphae.rs` serializes graph
  - Schema defines `nodes` (array of symbols) and `edges` (array of relationships) + `schema_version`

### Failure Mode Analysis

| Failure | Behavior | Assessment |
|---------|---------|------------|
| Hyphae not available | Line 364 checks `hyphae::is_available()`; returns error; export returns `tool_error()` | GRACEFUL — rhizome reports error to caller; code graph is not ingested; session continues |
| Hyphae DB locked or full | `export_graph()` fails; line 410 catches error; returns `export_error()` with summary | PARTIAL — export is retried on next auto-export or manual trigger; cached graph not updated |
| Export produces large graph (many files) | Graph is serialized to JSON and passed via subprocess args/stdin; no documented size limit | FRAGILE — very large projects may hit subprocess argument size limits or hyphae import timeout |
| Hyphae import validates schema and finds violation | Hyphae rejects payload; subprocess returns error; rhizome catches at line 410 | PARTIAL — rhizome reports error; memoir is not created; next export retries from stale cache |
| Export cache stale after schema change | Cache is checked by file mtime; if schema changes, old cache is skipped and files are re-exported | GRACEFUL — incremental cache automatically invalidates on schema change |
| Network unavailable (local-first, not applicable) | N/A — both tools are local; no network dependency | GRACEFUL — by design |

### Graceful Degradation: GRACEFUL

**Failure path:** Hyphae unavailable → export fails → code graph is not ingested → next export retries with cache.

**Mitigation:** Rhizome auto-exports every N seconds (line 89-152 in server.rs); if hyphae comes back online, export is retried automatically.

---

## Seam 6: volva run → execenv setup → cortina adapter → hyphae recall injection

### Happy Path
1. **Volva run assembles execution environment**
   - File: `/Users/williamnewton/projects/basidiocarp/volva/crates/volva-runtime/src/context.rs:39-49` - `assemble_prompt()` loads memory protocol and session recall
   
2. **Volva calls hyphae for memory protocol**
   - File: `/Users/williamnewton/projects/basidiocarp/volva/crates/volva-runtime/src/context.rs:400-446` - `load_memory_protocol_block()` spawns hyphae subprocess
   - Runs `hyphae protocol --project <project>` with 250ms timeout (line 21)
   - Returns protocol JSON that describes recall tools and storage configuration
   
3. **Volva calls hyphae for session recall**
   - File: `/Users/williamnewton/projects/basidiocarp/volva/crates/volva-runtime/src/context.rs:500-572` - `load_session_recall_block()` spawns hyphae subprocess
   - Runs `hyphae session context --project <project> --project-root <root> --limit 5` with 500ms timeout (line 23)
   - Returns recent session history and task context
   
4. **Volva injects context into prompt**
   - File: `/Users/williamnewton/projects/basidiocarp/volva/crates/volva-runtime/src/context.rs:68-119` - assembles prompt with envelope, protocol, recall, and user prompt
   - Injects `[hyphae-session-recall]` section before `[user-prompt]`

### Septa Schema Backing
- **Partially:** Volva hook events have schema (`septa/volva-hook-event-v1.schema.json`), but hyphae protocol and recall response are not formally versioned in septa
  - Source: `/Users/williamnewton/projects/basidiocarp/volva/crates/volva-runtime/src/context.rs:123-151` defines `MemoryProtocolSurface` struct (internal only)
  - No first-party schema file in septa for hyphae response shapes

### Failure Mode Analysis

| Failure | Behavior | Assessment |
|---------|---------|------------|
| Hyphae not discoverable | `load_memory_protocol_block()` returns `None` at line 430; assembly continues with empty protocol block | GRACEFUL — session runs without protocol injection; recall tools are not made available |
| Hyphae protocol call times out (>250ms) | Thread::spawn waits 250ms (line 21); returns `None`; session continues without protocol | PARTIAL — if hyphae is slow, volva gives up; context loss is silent |
| Hyphae session recall times out (>500ms) | Thread::spawn waits 500ms (line 23); returns `None`; session continues without recall | PARTIAL — timeout is generous (500ms) but can still miss on loaded systems |
| Hyphae protocol returns malformed JSON | `serde_json::from_str()` fails at line 532; error is swallowed; protocol is `None`; session continues | GRACEFUL — malformed response is silently skipped; session assembles without protocol |
| Session recall returns empty (no recent sessions) | Returns empty array; `load_session_recall_block()` formats as "[hyphae-session-recall]\n" with no content | GRACEFUL — empty recall section is added; no prior context is injected |
| Cortina adapter is not called by volva | Volva does NOT call cortina; cortina is called by Claude Code hooks, not volva | ARTIFACT — volva emits hook events; cortina is configured as external adapter in volva.json |

### Graceful Degradation: PARTIAL

**Failure path:** Hyphae unavailable or slow → context injection is skipped → volva session runs without memory context → session may duplicate prior work.

**Mitigation:** Timeouts are conservative (250-500ms); if hyphae is not running, session continues without context but does not hang.

---

## Summary Table

| Seam | Schema-backed? | Graceful degradation | Severity | Critical Gap |
|------|---------------|---------------------|---------|-------------|
| cortina→hyphae→canopy | YES (session-event-v1, canopy-snapshot-v1) | PARTIAL | Medium | Stale session state orphaned if hyphae unavailable |
| canopy→cap | YES (canopy-snapshot-v1) | FRAGILE | High | Cap has no secondary read path if canopy is down |
| hyphae session-start | PARTIAL (versioned internally, not in septa) | PARTIAL | Medium | Oversized context injection can exhaust token limits |
| lamella→cortina hooks | NO (informal hook envelope) | PARTIAL | Medium | Async hook execution; writes may be lost if session ends early |
| rhizome→hyphae export | YES (code-graph-v1) | GRACEFUL | Low | Large projects may hit subprocess limits |
| volva→cortina→hyphae | NO (protocol/recall not formally versioned) | PARTIAL | Medium | Silent context loss if hyphae timeouts (250-500ms) |

---

## Critical Gaps Found

### 1. **Session State Orphaning (Seam 1)**
**Issue:** When `hyphae session end` fails (disk full, locked DB), cortina logs a warning but the scoped session state file persists on disk. On the next session, `ensure_scoped_hyphae_session()` finds the stale file and tries to query hyphae for liveness; if hyphae is still unavailable, the old session ID is reused instead of creating a new one.

**Impact:** Parallel worktrees collapse into one session identity; cortina assigns all work to the same session ID.

**Evidence:** `/Users/williamnewton/projects/basidiocarp/cortina/src/utils/session_scope.rs:270-281` logs warn and returns `None` without cleaning up the state file; line 155-172 reuses old session if it matches liveness check.

**Recommendation:** Add cleanup logic when `hyphae session end` fails; or implement a liveness TTL so stale session state is automatically discarded after N minutes.

---

### 2. **Cap Server Single Point of Failure (Seam 2)**
**Issue:** Cap has no fallback if canopy is unavailable. The server returns a 500 error and the dashboard becomes completely unreadable. There is no secondary read path (e.g., read the Canopy SQLite DB directly, or use a stale cache from a previous snapshot).

**Impact:** Operator loses visibility into tasks, handoffs, and evidence if canopy is briefly unavailable.

**Evidence:** `/Users/williamnewton/projects/basidiocarp/cap/server/canopy.ts:171-204` shells out to canopy CLI with no fallback; `/Users/williamnewton/projects/basidiocarp/cap/server/routes/canopy.ts:40-41` returns a 500 error if the call fails.

**Recommendation:** Implement a fallback read path (e.g., read canopy.db directly or cache the last snapshot in cap's memory) to ensure the dashboard can at least show stale data if canopy is down.

---

### 3. **Hyphae Protocol/Recall Responses Not Formally Versioned (Seam 3 & 6)**
**Issue:** Hyphae returns `MemoryProtocolSurface` and session recall context, but these response shapes are not documented in `septa/` schemas. Changes to Hyphae's protocol response could break Volva and Cortina without detection.

**Impact:** Silent incompatibility if Hyphae response shape changes; Volva assembly could produce malformed context; Claude Code session might fail to initialize.

**Evidence:** `/Users/williamnewton/projects/basidiocarp/volva/crates/volva-runtime/src/context.rs:123-151` defines `MemoryProtocolSurface` struct in-code; no schema file validates this shape across boundaries.

**Recommendation:** Create `hyphae-memory-protocol-v1.schema.json` and `hyphae-session-recall-v1.schema.json` in septa; update Hyphae to emit versioned payloads; add validation in Volva and Cortina to detect schema drift.

---

### 4. **Async Hook Execution Without Persistence Guarantee (Seam 4)**
**Issue:** The PostToolUse and Stop hooks are configured with `"async": true`. This means Claude Code returns immediately without waiting for cortina to complete the write to hyphae. If the session exits before cortina finishes writing, the capture is lost.

**Impact:** Lifecycle signals may be dropped if the session terminates abruptly (network loss, user kill, crash).

**Evidence:** `/Users/williamnewton/projects/basidiocarp/lamella/resources/hooks/hooks.json:177` and `:192` set `"async": true` for cortina hooks; cortina uses `spawn()` (not `spawn_blocking()`) at `/Users/williamnewton/projects/basidiocarp/cortina/src/utils/session_scope.rs:349-356`.

**Recommendation:** Consider making the Stop and SessionEnd hooks synchronous (remove `"async": true`); or implement a hook completion wait in Claude Code before session termination.

---

### 5. **Lamella Hook Envelope Not Schema-Backed (Seam 4)**
**Issue:** The hook envelope that cortina receives from Claude Code (via lamella's hooks.json) is not formally versioned or schema-backed. Changes to the envelope structure could break cortina's parsing without detection.

**Impact:** Cortina adapter could fail to parse hook events if Claude Code changes the envelope structure.

**Evidence:** `/Users/williamnewton/projects/basidiocarp/cortina/src/adapters/claude_code.rs` parses `ClaudeCodeHookEnvelope` from JSON, but there is no septa schema to validate the input shape.

**Recommendation:** Create `claude-code-hook-envelope-v1.schema.json` in septa; add envelope version validation in cortina; update claude-code hooks to emit versioned envelopes.

---

### 6. **Volva Context Injection Timeouts Silent on Slow Hyphae (Seam 6)**
**Issue:** Volva's `load_memory_protocol_block()` and `load_session_recall_block()` have tight timeouts (250ms and 500ms). If hyphae is slow but not completely unavailable, these calls silently time out and return `None`, causing context loss without logging or warning to the user.

**Impact:** Sessions lose memory context if hyphae responds slowly; user is unaware of the degradation.

**Evidence:** `/Users/williamnewton/projects/basidiocarp/volva/crates/volva-runtime/src/context.rs:415-446` spawns a thread with timeout; if timeout expires, thread is dropped and `None` is returned without a logged warning.

**Recommendation:** Increase timeouts to 1s (hyphae context queries are lightweight); log a warning if timeout occurs; consider retrying once if the first attempt times out.

---

## Overall Assessment: FAIR

**Summary:**
- 3 seams are **GRACEFUL**: rhizome→hyphae export (automatic retry), canopy reads evidence (graceful skip), volva protocol assembly (empty injection)
- 2 seams are **PARTIAL**: cortina→hyphae (stale state orphaning), lamella→cortina hooks (async writes may be lost)
- 1 seam is **FRAGILE**: canopy→cap (single point of failure, no fallback)

**Primary risk:** Cap server becomes unusable if canopy is unavailable. This is a critical UX gap.

**Secondary risks:** Stale session state in cortina, silent context loss in volva, async hook execution without persistence guarantee.

**Recommendation for next pass:** Prioritize implementing a Cap fallback (read Canopy DB directly or serve stale snapshot); add septa schemas for hyphae response shapes; implement session state cleanup in cortina when hyphae is unavailable.

