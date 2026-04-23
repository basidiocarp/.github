# E2B Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `e2b-dev/E2B` (e2b.dev)
Lens: what to borrow from E2B, how it fits the `basidiocarp` ecosystem, and what it suggests improving in the ecosystem itself

---

## One-paragraph read

E2B is a sandboxed code execution platform built on Firecracker microVMs. Each sandbox is a fast, isolated Linux VM that boots in under 125ms, runs code in an optionally Jupyter-style kernel, captures structured output (stdout, stderr, display data, error name/value/traceback), and exposes a lifecycle API for create, pause, resume, kill, and timeout management. The core model is: you give E2B a Dockerfile that defines an environment; E2B converts that to a snapshotted microVM template; the SDK creates sandboxes from that snapshot on demand. The strongest ideas are the bounded execution contract (sandbox-level timeout separate from per-call timeout), the structured execution result envelope (logs + results + error), full VM-state pause/resume with file and memory preservation, and the clean separation between template definition and runtime instantiation. The MCP server layer is thin — effectively archived as of April 2026 — but the underlying SDK and API contracts are the real artifact. Primary ecosystem fit is `volva` (bounded execution model and lifecycle contract), with `septa` defining the execution request/result envelope.

---

## What E2B is doing that is solid

### 1. Bounded execution lifecycle with explicit timeout tiers

E2B separates timeout into two distinct axes. The sandbox-level timeout controls how long a VM stays alive before automatic kill (default 300s, configurable 1 hour on Hobby, 24 hours on Pro). The per-call timeout controls how long a command or code execution is allowed before cancellation (default 60s for `commands.run`). The SDK exposes `set_timeout` / `setTimeout` to extend or shorten the sandbox window dynamically, and exposes `kill` to terminate before expiry.

Evidence:
- `Sandbox.create({ timeoutMs: 60_000 })` in JS SDK, `AsyncSandbox.create(timeout=...)` in Python SDK
- `sandbox.set_timeout(...)` / `sandbox.setTimeout(...)` resetting the window without recreating the VM
- `CommandExitException` distinguishes a non-zero exit code from a timeout or sandbox-gone condition
- Three distinct exception types: `UnavailableException` (sandbox timeout), `CancelledException` (request timeout), `DeadlineExceededException` (per-process timeout)

Why this matters here:
- `volva` currently has a hook adapter timeout (`hook_adapter.timeout_ms`, default 30s) and a backend session concept, but no documented sandbox-level timeout distinct from hook delivery.
- Splitting these axes cleanly — sandbox lifetime vs. per-call deadline — is the right contract shape for any bounded execution host.
- `septa` should define these two timeout fields explicitly in an execution envelope contract rather than leaving them implicit in `volva.json`.

### 2. Structured execution result envelope

The Code Interpreter SDK's `Execution` object is a concrete, typed result contract:

```
Execution
  results:   List[Result]          # interactively interpreted output + display data (plots, DataFrames)
  logs:      Logs { stdout: List[str], stderr: List[str] }
  error:     Error? { name, value, traceback }
```

Each `Result` item can be text, image, chart data, or other MIME-typed display output, modeled after the Jupyter kernel messaging protocol. This is not a loosely typed string dump — it is a structured envelope where the caller can distinguish clean exit from traceback, command output from display data, and streaming lines from a final result.

Evidence:
- SDK returns `Execution` with `.results`, `.logs`, `.error` properties
- `logs.stdout` and `logs.stderr` are `List[str]` (one entry per line)
- `error.name / error.value / error.traceback` are always present or explicitly null
- `on_stdout` / `on_stderr` callbacks on `commands.run` enable streaming lines as they arrive

Why this matters here:
- `septa` has `command-output-v1.schema.json` for mycelium summarization, but no execution-result envelope that covers structured output, per-call errors, and display artifacts together.
- An `execution-result-v1` contract in `septa` would let `volva` emit normalized execution results that `cortina`, `hyphae`, and downstream tools can consume without each tool knowing the backend's specific format.

### 3. VM-state pause and resume with full memory preservation

E2B's pause/resume is not container stop/start. It serializes the full VM state — kernel memory, running processes, loaded variables, open file handles — into a snapshot (~4 seconds per GiB of RAM) and restores it (~150ms). A paused sandbox can resume after arbitrary wall-clock time to exactly the state it was in, including Python interpreter state and open file descriptors.

Evidence:
- `sandbox.beta_pause()` / `sandbox.beta_resume()` (marked beta in both SDKs)
- Documented: "not only state of the sandbox's filesystem but also the sandbox's memory"
- Pausing resets the sandbox timeout window, enabling pause-idle-resume patterns for long workloads
- `Sandbox.connect(sandboxId)` reconnects to a running or paused sandbox by ID

Why this matters here:
- `volva` has a backend session concept but no pause/resume with state preservation. For long agentic sessions that idle between tool calls, a freeze-and-restore model would reduce backend compute waste significantly.
- This is adapt-not-copy territory: the pattern is portable, but the implementation depends on microVM infrastructure that basidiocarp does not own.

### 4. Dockerfile-to-microVM template pipeline

E2B's template system converts a standard Dockerfile into a snapshotted microVM using its build system. The `e2b.toml` metadata file captures the template ID, resource specs (CPU 1–8 vCPU, RAM 512 MiB–8 GiB), and a `start-command` plus an optional `ready-command` (must exit 0 before template is considered live). Once built, the template can be instantiated repeatedly in ~150ms from the stored snapshot.

Evidence:
- `e2b template build` creates the template and writes `e2b.toml`
- `e2b.toml` contains `template_id`, `cpu_count`, `memory_mb`, `start_cmd`, `ready_cmd`
- Sandbox.create takes `{ template: "templateId" }` to select from user-defined environments
- Build System 2.0 blog post confirmed production use of Dockerfile-to-snapshot pipeline

Why this matters here:
- `volva` has a backend selector but no notion of pre-built, snapshotted execution environments. The template-as-snapshot model reduces cold-start latency from seconds (container pull + init) to ~150ms.
- The `ready-command` gate — a command that must succeed before the template is considered ready — is a clean pattern for host health gating. `volva`'s hook adapter contract emits phases like `session_start` but has no equivalent pre-session readiness check.

### 5. Resource limits as first-class sandbox parameters

E2B exposes CPU and memory as explicit, per-template parameters rather than system defaults. Default sandboxes get 2 vCPU and 1 GiB RAM; Pro templates can specify 1–8 vCPU and 512 MiB–8 GiB RAM. The platform also exposes `sandbox.getMetrics()` returning CPU, memory, and disk usage as live observability.

Evidence:
- `e2b.toml` `cpu_count` and `memory_mb` fields
- Pricing docs confirm $0.0504/vCPU-hr and $0.0162/GiB-hr metering
- `sandbox.getMetrics()` returns `SandboxMetric` with CPU, memory, disk fields (from OpenAPI spec `SandboxMetric` schema)
- `sandbox.kill()` is always available as a hard ceiling regardless of timeout

Why this matters here:
- `volva` and `septa` have no formal resource limit model. Hook events carry `exit_code` but not CPU/memory pressure or resource exhaustion signals.
- A minimal `resource-limits-v1` contract in `septa` — CPU ceiling, memory ceiling, timeout — would let `volva` enforce bounded execution semantics and let `cortina` capture resource pressure events.

### 6. Clean separation between MCP surface and execution SDK

E2B's MCP server is thin: it wraps the execution SDK into a small set of MCP tools. The archived `mcp-server` repo made the right call: the durable artifact is the SDK and the API, not the MCP transport layer. The MCP server can be rebuilt in a few hundred lines because the real contracts live in the SDK types.

Evidence:
- MCP server marked archived April 2026, but SDK (e2b and e2b-code-interpreter packages) remain active
- MCP server configuration is just an API key and `npx @e2b/mcp-server` — no stateful setup
- The execution result types are defined in the SDK, not in the MCP server

Why this matters here:
- This confirms the right pattern for `volva`: the host contract and execution model should live in `volva-runtime` and `septa`, not in the MCP adapter surface.

---

## What to borrow directly

### Borrow now

**Two-axis timeout model** (sandbox-level timeout + per-call deadline).
Best fit: `volva-runtime` for enforcement, `septa` for the contract shape.
The current `volva-hook-event-v1` schema has no timeout fields. Add `sandbox_timeout_ms` and `call_timeout_ms` to the execution envelope.

**Structured execution result envelope** (logs + typed results + structured error).
Best fit: `septa` as `execution-result-v1`, consumed by `volva`, `cortina`, and `hyphae`.
The result shape — `{ logs: { stdout, stderr }, results: [...], error: { name, value, traceback } | null }` — is the right contract for any bounded code execution result, independent of Firecracker.

**`ready-command` pre-session health gate**.
Best fit: `volva-runtime`.
Before considering a backend session live, run a readiness probe command and require exit code 0. This is cleaner than the current fail-open model where `session_start` fires before the backend is known-ready.

**Sandbox ID for reconnect**.
Best fit: `volva-runtime`.
E2B's `Sandbox.connect(sandboxId)` enables reconnection to an existing session. `volva` should emit a `session_id` in hook events so that tools like `cortina` and `hyphae` can correlate signals across reconnects.

---

## What to adapt, not copy

**Pause/resume with full memory preservation**.
E2B's pause/resume depends on Firecracker VM snapshotting. Basidiocarp does not own infrastructure at that layer. The portable idea is the pause/resume lifecycle model and the `paused` state in the sandbox state machine. Adapt: add `paused` as a valid session state to `volva-core` and emit it in hook events. The actual VM preservation is out of scope for `volva`, which routes to an external backend (the official Claude CLI or Anthropic API) rather than managing a VM directly.

**Dockerfile-to-snapshot template pipeline**.
The pipeline is sophisticated managed infrastructure. The portable idea is the template metadata contract: a template ID, resource spec, start command, and readiness gate that get resolved before a sandbox is created. Adapt: add a `template` field to `volva.json` and the `septa` execution request envelope so callers can specify what environment they expect, without `volva` needing to manage VM snapshots itself.

**Live resource metrics** (`getMetrics()` returning CPU/memory/disk).
E2B polls a managed metrics endpoint. Basidiocarp's backends are external CLIs and APIs, so a direct equivalent requires the backend to surface usage. Adapt: add a `resource_metrics` optional field to the `volva-hook-event-v1` schema so that backends that do expose metrics can forward them into `cortina`, even if not all backends populate it.

**Per-call streaming** (`on_stdout` / `on_stderr` callbacks).
E2B streams command output line by line via callbacks. Adapt: the execution result envelope in `septa` should mark `stdout` and `stderr` as ordered lists of lines (not a single blob), matching the streaming-as-accumulated-list shape E2B uses. `cortina` can treat the final list the same way it would treat a streamed accumulation.

---

## What not to borrow

**Firecracker microVM infrastructure**.
E2B owns significant cloud infrastructure for microVM lifecycle, tenant isolation, and snapshot storage. Basidiocarp is not a managed execution cloud. The infrastructure is not portable.

**E2B.toml and template build CLI**.
The build system and its tooling (`e2b template build`, `e2b template list`) are tightly coupled to E2B's cloud backend. The metadata format is portable (see adapt section); the tooling is not.

**Jupyter kernel protocol implementation**.
E2B's Code Interpreter SDK implements parts of the Jupyter kernel messaging protocol to enable interactive plotting and DataFrame rendering. This is useful for data-science workflows but is out of scope for basidiocarp's execution model. Borrow the result envelope shape, not the kernel protocol.

**MCP server** (the archived `e2b-dev/mcp-server`).
Archived April 2026, confirmed no further maintenance. The thin wrapper pattern is instructive, but there is nothing to borrow from the implementation itself.

**Pricing and billing model**.
Per-second vCPU and GiB-hr metering is specific to E2B's managed cloud. Not applicable.

---

## How E2B fits the ecosystem

### Primary fit: `volva`

`volva` is the execution-host runtime layer. E2B's strongest ideas — bounded sandbox lifetime, per-call timeout, structured result envelope, readiness gating, and session ID for reconnect — all belong in `volva-runtime` and the `septa` contracts that `volva` produces. The current `volva-hook-event-v1` schema covers `phase`, `backend_kind`, `cwd`, `prompt_text`, `exit_code`, and `error`, but has no execution result envelope, no timeout fields, no resource limit fields, and no session ID. These are the concrete gaps E2B identifies.

### Secondary fit: `septa`

Two new contracts warrant definition:

1. `execution-result-v1` — the normalized execution result envelope: `logs.stdout`, `logs.stderr`, `error` (nullable, with `name`, `value`, `traceback`), `exit_code`, `duration_ms`. This is the output side of any bounded execution call.
2. `execution-request-v1` — the input envelope: `sandbox_timeout_ms`, `call_timeout_ms`, optional `template_id`, optional `resource_limits` (cpu_count, memory_mb). This gives callers a way to request bounded execution semantics without knowing the backend.

These two contracts let `volva`, `cortina`, and any future execution backend speak the same language without tight coupling to E2B's specific SDK types.

### Tertiary fit: `cortina`

`cortina` captures lifecycle signals. If `volva` emits an `execution-result-v1` payload in its hook events, `cortina` can classify execution failures, timeout events, and resource pressure as structured signals — the same way it classifies `errors/active` and `errors/resolved` today. The `error.name` field from the execution result maps cleanly onto cortina's existing error signal model.

### No fit: `canopy`, `hyphae`, `mycelium`, `lamella`, `stipe`

- `canopy` tracks coordination state; execution result envelopes are not coordination records.
- `hyphae` stores memories; execution result data flows through `cortina` into `hyphae`, not directly.
- `mycelium` compresses command output; the structured execution envelope should not be compressed — it is typed data, not verbose text.
- `lamella` packages skills and hooks; execution host policy belongs in `volva`.
- `stipe` owns install and repair; no fit here.

---

## What E2B suggests improving in your ecosystem

### 1. Define execution-result-v1 in septa

The `volva-hook-event-v1` schema covers hook phases but does not include a normalized execution result. E2B demonstrates that a clean, typed result envelope — with `logs`, `results`, and `error` as distinct fields — is the right output contract for any bounded execution. Add `execution-result-v1` to `septa` and update `volva-runtime` to populate it in `response_complete` phase events.

### 2. Add timeout fields to the execution contract

`volva.json` has `hook_adapter.timeout_ms` for hook delivery, but no sandbox-level timeout or per-call deadline. E2B's two-axis timeout model (sandbox lifetime vs. per-call ceiling) is the right shape. Add `sandbox_timeout_ms` and `call_timeout_ms` to `execution-request-v1` in `septa`, and enforce them in `volva-runtime`'s backend execution path.

### 3. Emit a session ID in hook events

E2B's `sandboxId` enables reconnection to a live or paused sandbox. `volva`'s hook events include `cwd` and `backend_kind` but no session ID that downstream tools can use to correlate events across reconnects or tool calls within one session. Add a `session_id` field (a UUID generated at `session_start` and repeated in all subsequent phases) to `volva-hook-event-v1`. This also benefits `cortina`'s session attribution and `hyphae`'s session records.

### 4. Add a readiness gate to the backend session model

E2B's `ready-command` — a command that must exit 0 before the template is considered live — is a clean health-gate pattern. `volva-runtime` currently emits `session_start` as the first hook phase, but does not probe whether the backend is actually ready to accept work. A `pre_session_ready_command` field in `volva.json` (optional, defaults to no probe) would let operators configure a health check before `session_start` fires. Failed probes would emit `backend_failed` instead of `session_start`, making failures visible rather than silent.

### 5. Add resource_limits as an optional field to the execution request

E2B's per-template CPU and memory caps are explicit parameters. Basidiocarp's execution host currently has no resource limit model. Even if `volva` cannot enforce limits on external backends, adding a `resource_limits` optional field to the `septa` execution request envelope establishes the right semantics and lets future backends that do support limits (or let `cortina` emit resource-exhaustion signals when backends report OOM or SIGKILL exits) use a consistent field.

---

## Verification context

This audit was based on public documentation, the GitHub repositories `e2b-dev/E2B` and `e2b-dev/mcp-server`, SDK reference documentation, the DeepWiki analysis of the E2B REST API and OpenAPI spec, and multiple secondary sources (Northflank comparisons, ZenML breakdowns, Towards AI summary, and the Dwarves Memo breakdown). The E2B MCP server repository was confirmed archived as of April 16, 2026. Direct source code inspection was not possible for all files due to WebFetch access restrictions, but the API surface, SDK types, schema fields, and lifecycle model were confirmed from multiple independent sources. No local execution was performed.

---

## Final read

E2B's strongest contribution to basidiocarp is not the Firecracker infrastructure — that is non-portable — but the execution contract model: two-axis timeouts (sandbox lifetime vs. per-call deadline), a typed result envelope (logs + results + structured error), a session ID for reconnect correlation, and a readiness gate before declaring a session live. These are all missing from the current `volva-hook-event-v1` and `septa` contract set. The highest-leverage action from this audit is defining `execution-result-v1` and `execution-request-v1` in `septa`, then updating `volva-runtime` to emit normalized execution results in `response_complete` events. That work would also improve `cortina`'s ability to classify execution failures and resource exhaustion as structured signals, and `hyphae`'s ability to store session outcomes with richer attribution than the current exit-code-only model provides.
