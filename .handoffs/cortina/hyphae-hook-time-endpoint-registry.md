# Cortina: Hyphae Hook-Time CLI → Local Service Endpoint

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina` (primary), `hyphae` (must expose socket endpoint first)
- **Allowed write scope:** `cortina/src/utils/hyphae_client.rs`, `cortina/Cargo.toml`
- **Cross-repo edits:** `hyphae` must expose a local service endpoint before cortina can migrate; see Prerequisites
- **Non-goals:** no changes to session capture behavior; no changes to the session-event-v1 payload shape
- **Verification contract:** `cd cortina && cargo test && cargo clippy`
- **Completion update:** update `.handoffs/HANDOFFS.md` when done

## Problem

`cortina/src/utils/hyphae_client.rs` writes session signals to hyphae by spawning the hyphae CLI:

```rust
// hyphae_client.rs:78-109
let Some(mut cmd) = resolved_command("hyphae") else {
    debug!("Hyphae binary is not discoverable; skipping store");
    return;
};
cmd.args(["store", "--topic", topic])
   .args(["--content", content])
   // ...
   .spawn()
```

Classified in C7 as "hook-time CLI exception" with the rationale: calling hyphae MCP during a hook would create circular dependencies. That reasoning applies to calling hyphae through Claude Code's MCP protocol — but it does not apply to calling hyphae through a direct local service endpoint that hyphae owns independently of Claude Code's MCP server.

**The real constraint:** cortina runs as a hook subprocess inside a Claude Code session where hyphae is also running as an MCP server. Calling back through the MCP protocol would require routing through Claude Code, creating the circular dependency. A direct socket connection to hyphae bypasses Claude Code entirely and has no circular dependency risk.

## Current State

**File:** `cortina/src/utils/hyphae_client.rs`

Three functions that spawn the hyphae CLI:

1. `store_in_hyphae(topic, content, importance, project, agent_id)` — fire-and-forget
2. `store_compact_summary_artifact(payload, project)` — fire-and-forget
3. `spawn_async_checked(cmd, args) -> bool` — generic async spawn helper (also used by other cortina hooks, not only hyphae)

All three use `resolved_command("hyphae")` which calls `spore::discover(Tool::Hyphae)` to find the binary and constructs a `Command`. They are all fire-and-forget (`spawn()` not `wait()`).

**Constraint:** Because these are fire-and-forget at hook time, latency matters — cortina should not block the outer tool (Claude Code) while waiting for hyphae to acknowledge writes. The socket endpoint approach must also be non-blocking.

## Prerequisites

This handoff requires hyphae to expose a local service endpoint:

| Prerequisite | Status |
|---|---|
| `hyphae/local-service-endpoint-registration.md` | Not yet created |

Hyphae must: register a unix-socket endpoint at a stable path (e.g., `~/.local/share/hyphae/hyphae.sock`), expose a `memory_store` method via JSON-RPC 2.0, and write an endpoint descriptor to `~/.config/hyphae/hyphae.endpoint.json` on startup.

**Do not start this handoff until hyphae exposes a working socket endpoint.**

## Migration Plan

Once hyphae exposes a socket endpoint, replace the CLI spawn pattern in `hyphae_client.rs` with `spore::LocalServiceClient` calls, preserving the fire-and-forget semantics via a background thread.

### 1. Add `spore` dependency with `transport` feature

Verify `spore` is already a dep of cortina. If `LocalServiceClient` and `LocalServiceEndpoint` are not already in scope, add the import:

```rust
use spore::{LocalServiceClient, LocalServiceEndpoint, TransportError};
```

### 2. Add a cached endpoint resolver

Hyphae writes its endpoint descriptor to disk on startup. Cortina should read it once per hook invocation (not per call) and cache the result in a `OnceLock` or similar:

```rust
static HYPHAE_ENDPOINT: OnceLock<Option<LocalServiceEndpoint>> = OnceLock::new();

fn hyphae_endpoint() -> Option<&'static LocalServiceEndpoint> {
    HYPHAE_ENDPOINT.get_or_init(|| {
        let path = spore::paths::config_dir("hyphae")?.join("hyphae.endpoint.json");
        let json = std::fs::read_to_string(&path).ok()?;
        LocalServiceEndpoint::from_json(&json).ok()
    }).as_ref()
}
```

### 3. Rewrite `store_in_hyphae`

```rust
pub fn store_in_hyphae(
    topic: &str,
    content: &str,
    importance: Importance,
    project: Option<&str>,
    agent_id: Option<&str>,
) {
    let span_ctx = span_context("hyphae_store");
    let _tool_span = tool_span("hyphae_store", &span_ctx).entered();

    let Some(endpoint) = hyphae_endpoint() else {
        // Fall back to CLI if endpoint not registered (hyphae not running as service)
        eprintln!("[cortina] hyphae endpoint not found; falling back to CLI store");
        store_in_hyphae_cli(topic, content, importance, project, agent_id);
        return;
    };

    // Build the memory_store params matching hyphae's MCP tool input shape
    let mut params = serde_json::json!({
        "topic": topic,
        "content": content,
        "importance": importance.as_str(),
        "keywords": ["cortina", "hook"],
    });
    if let Some(proj) = project {
        params["project"] = serde_json::json!(proj);
    }
    if let Some(id) = agent_id {
        params["agent_id"] = serde_json::json!(id);
    }

    // Fire-and-forget: spawn background thread to avoid blocking the hook
    let endpoint = endpoint.clone();
    let _spawn_span = subprocess_span("hyphae store (socket)", &span_ctx).entered();
    std::thread::spawn(move || {
        let client = LocalServiceClient::new(endpoint);
        if let Err(e) = client.call("hyphae_memory_store", params) {
            warn!("hyphae_memory_store socket call failed: {e}");
        }
    });
}
```

### 4. Keep CLI fallback for degraded mode

Rename the current implementation to `store_in_hyphae_cli(...)` as a private function. Call it when the endpoint descriptor is not found (hyphae not running as a service). Emit a visible warning at runtime per C8 rule:

```rust
fn store_in_hyphae_cli(...) {
    // [COMPATIBILITY FALLBACK] CLI dispatch — use only when hyphae socket endpoint unavailable
    eprintln!("[cortina] WARNING: hyphae socket endpoint unavailable; using CLI fallback");
    // ... existing Command::new("hyphae") logic ...
}
```

### 5. Migrate `store_compact_summary_artifact`

Apply the same pattern: try socket endpoint first, fall back to CLI with a warning.

### 6. Leave `spawn_async_checked` as-is

`spawn_async_checked` is a generic helper used for tools beyond hyphae (e.g., other hook targets). It should not be migrated in this handoff — it is out of scope.

## Verification

```bash
cd cortina && cargo test
cd cortina && cargo clippy
```

The fire-and-forget semantics must be preserved — cortina's hook handlers must return without waiting for hyphae writes to complete. Verify no new `wait()` or blocking calls are introduced.

Integration path (requires hyphae endpoint running):
```bash
cd cortina && cargo test --ignored
```

## Context

- C7: `cortina → hyphae` classified as "hook-time CLI exception" with note "Candidate for eventual hook-time endpoint registry"
- C8: `docs/foundations/inter-app-communication.md` — local service endpoint is preferred; CLI fallback must emit a visible warning
- The key insight: the "circular dependency" applies to MCP-via-Claude-Code protocol, not to a direct socket connection to hyphae. The socket path is safe at hook time.
- `spore/src/transport.rs` (`LocalServiceClient`) is the Rust-side client — already implemented in C6
- `septa/local-service-endpoint-v1.schema.json` — the endpoint descriptor format hyphae will emit
- Companion: `cap/operator-surface-socket-endpoints.md` — cap does the same migration on the Node.js side for dashboard queries
