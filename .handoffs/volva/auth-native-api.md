# Volva Auth and Native API Backend

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** volva/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `volva` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Volva's current shipping backend uses `claude -p` (official Claude Code headless
execution). The native Anthropic API-key backend mode is planned but not shipped.
Auth flows — API-key resolution, secure token storage — are also not yet
implemented. Without this, users who don't have Claude Code installed or who want
direct API access cannot use volva.

## What exists (state)

- **`volva-auth` crate**: exists in the crate layout; auth flows not yet implemented
- **`volva-api` crate**: Anthropic HTTP client, SSE parser, retries — implemented
- **`volva chat`**: native API mode command exists; implementation status unclear
- **`volva backend status` / `volva backend doctor`**: operator readiness checks exist
- **Context assembly**: static host envelope prepended; recall injection is gap #10

## What needs doing (intent)

Implement API-key-based auth (resolve from env var → config file → secure OS keychain)
and wire the native Anthropic API backend to a runnable state. The backend should
share the same hook dispatch and context assembly path as the `claude -p` backend.

---

### Step 1: Implement API key resolution in volva-auth

**Project:** `volva/`
**Effort:** 1 day
**Depends on:** nothing

Implement `volva-auth` API key resolution:

1. Check `ANTHROPIC_API_KEY` environment variable
2. Check `~/.config/volva/config.toml` `api_key` field
3. Check OS keychain (`security` on macOS, `secret-tool` on Linux, credential
   manager on Windows) for a stored key under service `volva`
4. If none found, return a clear error with setup instructions

```rust
pub struct ApiKeyResolver;

impl ApiKeyResolver {
    pub fn resolve() -> Result<ApiKey, AuthError>;
}

#[derive(Debug, thiserror::Error)]
pub enum AuthError {
    #[error("No API key found. Set ANTHROPIC_API_KEY or run: volva auth setup")]
    NotFound,
    #[error("Keychain error: {0}")]
    Keychain(String),
}
```

Add `volva auth setup` command that prompts for the API key and stores it in the
keychain.

#### Verification

```bash
cd volva && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
ANTHROPIC_API_KEY=test_key volva backend status 2>&1 | grep -i api
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `ApiKeyResolver::resolve()` checks env var → config → keychain in order
- [ ] `AuthError::NotFound` includes setup instructions
- [ ] `volva auth setup` stores key in OS keychain
- [ ] `volva backend status` shows auth resolution status
- [ ] Build and tests pass

---

### Step 2: Wire native API backend to volva-runtime

**Project:** `volva/`
**Effort:** 2–3 days
**Depends on:** Step 1

Connect `volva-api` (Anthropic HTTP client) to `volva-runtime` as a selectable
backend. The native API backend should:

1. Resolve the API key via `volva-auth`
2. Accept the same host context envelope as the `claude -p` backend
3. Stream responses via SSE (already in `volva-api`)
4. Forward hook events through the same cortina adapter path as the `claude -p` backend
5. Capture usage (input/output tokens) for `volva-core` usage accounting

Backend selection: `--backend api` flag on `volva run`, or `backend = "api"` in
`~/.config/volva/config.toml`.

#### Files to modify

**`volva-runtime/src/backends/api.rs`** — implement native API backend:

```rust
pub struct NativeApiBackend {
    auth: ApiKeyResolver,
    client: AnthropicClient, // from volva-api
    model: String,
}

impl Backend for NativeApiBackend {
    fn run(&self, ctx: ContextEnvelope, hooks: &HookDispatcher) -> Result<SessionOutcome>;
}
```

#### Verification

```bash
cd volva && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `NativeApiBackend` implements the `Backend` trait
- [ ] `volva run --backend api` dispatches to native API backend
- [ ] Hook events forwarded through cortina adapter
- [ ] Usage tokens captured in session outcome
- [ ] Build and tests pass

---

### Step 3: Add native API backend to volva doctor

**Project:** `volva/`
**Effort:** 2–4 hours
**Depends on:** Step 1, Step 2

Extend `volva doctor` to check native API backend health:
- API key resolution status (env/config/keychain/missing)
- Model availability check (lightweight API probe with the resolved key)
- Backend selection configuration

```
volva doctor
  ✓ claude-cli backend: claude found at /usr/local/bin/claude
  ✓ api backend: ANTHROPIC_API_KEY set, model claude-3-5-sonnet-20241022 reachable
  ✓ cortina adapter: healthy
  ✓ hyphae recall: available (gap #10)
```

#### Verification

```bash
cd volva && cargo build --workspace 2>&1 | tail -3
ANTHROPIC_API_KEY=sk-test volva doctor 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `volva doctor` shows API key resolution status
- [ ] Doctor shows native API backend availability
- [ ] Model reachability check runs (or skips gracefully on invalid key)
- [ ] Build passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `volva/`
3. `volva run --backend api` runs a session using the Anthropic API directly
4. `volva doctor` shows auth and API backend status
5. All checklist items are checked

### Final Verification

```bash
cd volva && cargo test --workspace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass, no failures.

## Context

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `volva` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsGap #21 in `docs/workspace/ECOSYSTEM-REVIEW.md`. Listed as "planned next in volva"
after context assembly. The native API backend unlocks volva for users who want
direct API access without Claude Code. Auth flows are pre-requisite for the API
backend and are also needed for any future OpenAI/ChatGPT provider support. The
crate structure (`volva-auth`, `volva-api`) is already laid out; this handoff
fills in the implementation.
