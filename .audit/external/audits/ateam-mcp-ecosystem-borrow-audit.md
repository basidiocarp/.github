# ateam-mcp Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `ariekogan/ateam-mcp`
Lens: what to borrow from the tool, how it fits the `basidiocarp` ecosystem, and what it suggests improving in the ecosystem itself

## One-paragraph read

`ateam-mcp` is a thin MCP adapter in front of a proprietary hosted multi-agent platform (ADAS). As an MCP server implementation it is straightforward: 12–50+ tools that forward calls to `api.ateam-ai.com` with tenant headers. The architecture is middleware, not a runtime. The concrete strengths are: a composite build-validate-deploy tool that collapses a multi-phase pipeline into one conversational call, a two-tier tool visibility model that hides advanced tools from the advertised `tools/list`, session-scoped credential management, and a validation pipeline that distinguishes blocking errors from non-fatal warnings. The best fit is `canopy` for the composite operation semantics and phase-gating model, `hymenium` for the async job polling pattern, `lamella` for the skill definition and packaging conventions, and `septa` for validation pipeline contracts. The main caution is that most of the platform — the ADAS runtime, GitHub-as-source-of-truth, multi-tenant infra — is a hosted product that is not portable. Do not borrow the platform; borrow the interface patterns.

## What ateam-mcp is doing that is solid

### 1. The composite operation collapses a multi-phase pipeline into one conversational entry point

`ateam_build_and_run` runs five sequential phases — schema validation, cross-skill contract validation, deploy to production, health-check, and GitHub push — with per-phase result capture and early-exit on failure. Agents never call `ateam_validate_solution` or `ateam_deploy_solution` directly in normal use. The single composite call reduces partial-failure scenarios and eliminates the need for orchestration knowledge in the caller.

Evidence: The `tools.js` implementation shows `ateam_build_and_run` calling `/validate/solution`, then `/deploy/solution`, then `/deploy/solutions/{id}/health`, then skill test, then GitHub push in sequence. Each phase result is captured. Failure in one halts the sequence.

Why this matters: `hymenium` owns workflow dispatch and phase gating. The composite operation pattern here is close to what `hymenium` should offer for multi-step deployment workflows: a named workflow that folds discrete operations into a sequenced run with checkpoints, not a freeform call chain.

### 2. The two-tier tool visibility model is a useful MCP design pattern

The server divides tools into a `core` set (advertised in `tools/list`) and an `advanced` set (callable but hidden). Agents discover and use the core set for daily work; advanced tools remain callable without cluttering the model's context window. The server also inserts a bootstrap instruction into the first user message, ensuring a mandatory context-load before any other response.

Evidence: `server.js` shows `coreTools` filtering on `tool.core === true` for the list response, with all tools remaining callable via `CallToolRequestSchema`. The bootstrap instruction is embedded as a static string in the server factory.

Why this matters: `lamella` ships skill packages and the hook/rules system. The two-tier model maps directly to how `lamella` could manage skill surface area — core tools as the default skill surface, advanced tools as opt-in extensions. The bootstrap instruction maps to how `lamella` hooks could inject context initialization at session start.

### 3. Session-scoped credential isolation is concrete

The server tracks sessions with activity timestamps and a 60-minute expiry. Credentials resolve through three tiers: per-session overrides (set by `ateam_auth`), environment variables, and defaults. A background sweep removes stale sessions every 5 minutes. HTTP transport sessions and stdio transport sessions share the same credential resolution path.

Evidence: `api.js` shows a session map with TTL expiry, a background `setInterval` sweeper, and the three-tier resolution order: session override → env var → default.

Why this matters: `canopy` tracks task ownership and handoffs. When canopy coordinates agents across sessions, it needs a credential or context isolation model like this — one that stays per-session, not per-process.

### 4. The validation pipeline distinguishes blocking errors from warnings

`adas_validate_solution` runs five discrete stages: schema validation, cross-skill contract checks, grant economy verification, LLM quality scoring, and connector compatibility. Blocking errors prevent deploy. Non-fatal warnings are collected and returned without blocking. This is a real five-stage gate, not a single pass-fail check.

Evidence: The `tools.js` analysis describes the five stages with explicit `{ errors: [...], warnings: [...] }` output shape. The grant economy stage specifically verifies that permissions flow correctly from solution to skill tools — a graph-level consistency check, not just a schema check.

Why this matters: `septa` owns shared contracts and their validation. The grant economy check (permissions graph from solution → skill → tool) is a contract-boundary check, not a local type check. `septa` should be the place where multi-skill permission graphs are validated across producers and consumers.

### 5. The async job polling pattern with sync-first fallback is well-engineered

`ateam_build_and_run` tries a synchronous POST first because small solutions complete within the 90-second window. On 502, 503, 524, or `ETIMEDOUT`, it retries with `async: true`, receives a `job_id`, and polls `/deploy/jobs/{job_id}` every 5 seconds for up to 10 minutes. The retry is automatic and the caller never has to manage the mode switch.

Evidence: `api.js` documents exponential backoff capped at 15 seconds, 120-second default timeout, and specific retry conditions (502/504 status codes and connection failures).

Why this matters: `hymenium` handles workflow dispatch, retry, and recovery. The sync-first-then-async pattern is exactly the kind of adaptive dispatch `hymenium` should offer: try the fast path, fall back to the job path transparently, and poll for completion without exposing the mode switch to the caller.

### 6. Surgical patch operations with partial-success semantics

`ateam_patch` reads the current solution from GitHub, applies dot-notation edits and array operations (`tools_push`, `tools_delete`, `tools_update`), writes the result back to GitHub, and then redeploys. If the redeploy times out, the patch returns `ok: true` with a warning — the patch is safe on GitHub; only the deploy phase failed. Agents can retry with `ateam_redeploy`.

Evidence: The dot-notation path system and the partial-success contract are explicit in the `tools.js` analysis.

Why this matters: `canopy` will need surgical update semantics for task and handoff records. The partial-success model here — write succeeds, activation fails, retry the activation — is a clean separation that `canopy` and `hymenium` should apply to their own handoff and redeploy paths.

## What to borrow directly

### Borrow now

- Composite operation pattern: fold multi-phase pipelines into a named workflow with per-phase checkpoints and early-exit on failure. Best fit: `hymenium`. The validate → deploy → health-check → test sequence maps directly to a workflow definition with named phases.

- Two-tier tool visibility: separate the advertised tool surface from the full callable surface. Best fit: `lamella` for the packaging model, with the concept applicable wherever `lamella`-packaged skills register their MCP tools.

- Validation pipeline with blocking-vs-warning distinction: a multi-stage gate that separates schema errors, contract errors, and quality warnings. Best fit: `septa` for the contract schema and the output type; `hymenium` for the phase-gate integration.

- Async job polling with sync-first fallback. Best fit: `hymenium`. The pattern is directly applicable to any `hymenium` workflow that calls external operations with variable latency.

- Partial-success semantics for write-then-activate operations. Best fit: `canopy` and `hymenium`. The write phase and the activation phase should be distinct recovery points.

- Session-aware credential isolation with TTL expiry and background sweep. Best fit: `canopy`, where session-scoped context would include credential or auth overrides per task. The sweeper pattern is portable as a background maintenance worker.

## What to adapt, not copy

### Adapt

- Skill definition format. ADAS skills carry `name`, `description`, `problem.statement`, `tools[]`, `grants[]`, and `scenarios[]`. The grant economy and scenario fields are useful structured additions beyond the `lamella` skill/hook packaging conventions. Adaptation: extract the grant-economy concept and scenario-anchored descriptions as principles for `lamella` skill metadata, not a copy of the ADAS schema.

- The bootstrap instruction injection. The server hardcodes a mandatory context-load on first message. Adaptation: `lamella` hooks already handle session-start injection. Make bootstrap instructions part of the hook lifecycle rather than a hardcoded string in the MCP server factory.

- The connector constraint (no HTTP frameworks, all MCP transports must be stdio). This is an ADAS platform policy, but the underlying discipline — enforce transport contracts on hosted skills — is worth adapting. Adaptation: `septa` could carry a transport contract for any skill that runs as an MCP server, not just ADAS-hosted ones.

- The `ateam_conversation` tool with `actor_id` for multi-turn continuity. This is the multi-turn context threading pattern. Adaptation: `canopy` manages session and task identity. The actor_id concept maps to `canopy`'s task-owner or agent-identity field. Do not copy the conversational UX; absorb the identity-threading discipline.

## What not to borrow

### Skip

- The ADAS platform itself. The runtime (`api.ateam-ai.com`, ADAS Core, GitHub-as-source-of-truth, multi-tenant infra) is a proprietary hosted product. Nothing from the API layer is portable.

- GitHub as the primary source of truth for connector code. ADAS uses GitHub to persist connector bundles because it is a hosted platform with no local storage. The `basidiocarp` tools own their repos directly; this pattern is unnecessary and would add external dependency.

- Single-branch (`main`) deployment with rollback via git tags. This is an ADAS platform policy driven by the hosted model. The ecosystem uses conventional per-feature branches and CI gates.

- The master-key cross-tenant mode. This is a multi-tenant SaaS concern, not an ecosystem concern.

- The Solution Bot (`ateam_solution_chat` / guided modification via dialogue). This is a product feature of the ADAS platform, not a portable pattern. `lamella` skills and `hymenium` workflows are the equivalent surface.

- The tenant-aware tool guard (`TENANT_TOOLS` set). This is ADAS-specific auth separation. The ecosystem has its own auth and session boundaries.

## How ateam-mcp fits the ecosystem

### Best fit by repo

- `hymenium`
  Primary fit. The composite operation pattern, async job polling with sync-first fallback, and partial-success semantics are exactly what `hymenium` should express as first-class workflow constructs. Phase-gating, retry, and recovery belong here.

- `canopy`
  Strong fit. Session-scoped credential isolation, actor identity threading, and partial-success write-then-activate semantics are relevant to task ownership and handoff management. The sweeper pattern (background TTL cleanup) maps to `canopy`'s lifecycle management of stale tasks.

- `lamella`
  Strong fit. The two-tier tool visibility model (core vs advanced) and the grant-economy + scenario-anchored skill metadata are useful inputs to how `lamella` packages and exposes skills. The bootstrap instruction injection should be absorbed into the hook lifecycle.

- `septa`
  Moderate fit. The five-stage validation pipeline with its `{ errors, warnings }` output contract and the grant-economy permissions graph are septa-level contracts. Any multi-skill system that needs cross-component validation needs a shared schema for what a validation result looks like.

- `cortina`
  Weak fit. The session sweeper and lifecycle events are relevant to what `cortina` captures, but `ateam-mcp` has no real lifecycle signal system beyond TTL expiry.

- `stipe`
  Weak fit. Installation is npm-based and trivial. Nothing in the install path is worth borrowing beyond the reminder that an MCP server should support both stdio and HTTP transport modes.

- All others (`hyphae`, `mycelium`, `rhizome`, `cap`, `annulus`, `volva`, `spore`)
  No meaningful fit. The project is a thin HTTP adapter, not a memory, code intelligence, or runtime system.

## What ateam-mcp suggests improving in the ecosystem

### 1. Hymenium needs named composite workflows with per-phase capture

The `ateam_build_and_run` pattern shows that callers should not orchestrate multi-phase operations by chaining raw tool calls. A single named workflow should own the sequence, capture phase results, and handle failure isolation. If `hymenium` does not yet expose named composite workflows as first-class dispatch targets, this is the pattern that argues for it.

### 2. Lamella should formalize a two-tier skill surface

The core-vs-advanced split is a pragmatic way to manage context window pressure in MCP environments. `lamella` packages skills; it should also have a concept of which tools in a package are the normal surface and which are advanced-but-callable. This belongs in the skill manifest, not in the MCP server code.

### 3. Septa should add a validation-result envelope contract

Multiple audited projects (CrewAI, ateam-mcp) have converged on validation pipelines with structured results. Septa should own a canonical `ValidationResult` type: `{ stage: string, errors: Error[], warnings: Warning[], blocking: bool }`. Any cross-component validation should emit this shape.

### 4. Canopy should model partial-success handoffs explicitly

When a write phase succeeds and an activation phase fails, the handoff record should distinguish "written but not live" from "live" from "failed entirely." `ateam-mcp` handles this cleanly by returning `ok: true` with a warning and advising a follow-up `ateam_redeploy`. `canopy` handoffs should have equivalent lifecycle states at the activation boundary.

### 5. Session TTL and sweeper are an underspecified concern

The ecosystem has session lifecycle at the `hyphae` level (session context, session end) and at the `cortina` level (lifecycle signals). Neither currently handles per-session credential isolation with TTL expiry. If `canopy` grows per-session context bundles, a sweeper pattern should be part of the design from the start.

## Verification context

This audit is based entirely on remote inspection: the GitHub repository page, the raw README, `package.json`, `src/index.js`, `src/server.js`, `src/tools.js`, and `src/api.js` via WebFetch. No local clone was made. The implementation details are derived from what the WebFetch model extracted — the `tools.js` description of 50+ tools and the five-stage validation pipeline is stronger evidence than the earlier README description of 12 tools, suggesting the repo has grown significantly from the version described in the README. The core architectural observations are grounded in the code-level analysis of tools.js and api.js.

## Final read

Borrow: the composite multi-phase workflow pattern, async job polling with sync-first fallback, two-tier tool visibility, partial-success write-then-activate semantics, and validation-result envelope design.

Adapt: skill metadata (grant economy and scenarios as principles for lamella, not as schema copy), bootstrap instruction injection into the hook lifecycle, and the transport constraint discipline into a septa contract.

Skip: the ADAS platform runtime, GitHub-as-source-of-truth, single-branch deploy model, multi-tenant master-key auth, and the Solution Bot product surface.

Primary ecosystem destination: `hymenium` for the workflow mechanics, `canopy` for session and handoff semantics, `lamella` for the two-tier skill surface, `septa` for the validation envelope contract.
