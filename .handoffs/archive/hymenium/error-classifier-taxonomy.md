# Error Classifier Taxonomy

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/...`
- **Cross-repo edits:** `septa/` for the shared `FailoverReason` contract if the enum is published as a cross-tool schema
- **Non-goals:** credential pool management (volva/spore), retry execution logic, or provider-specific HTTP client code
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-error-classifier-taxonomy.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** `src/error.rs` or new `src/classify.rs`; potentially `src/dispatch/` if retry/recovery already exists
- **Reference seams:** hermes-agent `agent/error_classifier.py:233-406` for the classification priority chain; existing `hymenium` error types for integration points
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The ecosystem has no shared, typed taxonomy for API failure modes with composable recovery hints. Errors are handled locally per tool with ad hoc string matching. When `hymenium` dispatches work to providers and encounters failures, it cannot express why a request failed or what to try next in a way that `volva`, `canopy`, or any other consumer can act on programmatically. This is the highest-leverage structural gap identified in the hermes-agent audit.

## What exists (state)

- **`hymenium`:** has retry/recovery logic but no typed error classification
- **Ecosystem:** each tool handles API errors independently with tool-local logic
- **hermes-agent reference:** a priority-ordered classifier mapping API exceptions to `ClassifiedError` with `FailoverReason` enum and four composable recovery hint flags

## What needs doing (intent)

Introduce a `FailoverReason` enum and a composable recovery hint struct into `hymenium` that classifies API failures into actionable categories. The classifier should be a priority-ordered match chain that handles: auth failure (401), quota exhaustion vs rate limit vs content policy (402 disambiguation), transport errors, and disconnect-with-overflow inference. Recovery hints should be additive flags — a single classified error can be retryable AND suggest compression AND suggest credential rotation.

## Scope

- **Primary seam:** error classification at the provider dispatch boundary
- **Allowed files:** `hymenium/src/` error and dispatch modules
- **Explicit non-goals:**
  - Do not implement the actual retry/fallback execution logic in this handoff (that is existing hymenium responsibility)
  - Do not build a credential pool or rotation mechanism (volva/spore concern)
  - Do not publish the enum to septa in this handoff (separate contract handoff if needed)

---

### Step 1: Define FailoverReason enum and RecoveryHint struct

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** nothing

Define a `FailoverReason` enum with variants covering the major API failure categories:
- `AuthFailure` — 401, invalid or expired credentials
- `QuotaExhausted` — 402 with quota semantics
- `RateLimited` — 402/429 with rate semantics
- `ContentPolicy` — 402/400 with content filter semantics
- `TransportError` — network, DNS, TLS failures
- `ContextOverflow` — disconnect combined with large-session inference
- `ServerError` — 5xx responses
- `Unknown` — unclassifiable

Define a `RecoveryHint` struct with four composable boolean flags:
- `retryable` — safe to retry after backoff
- `should_compress` — context reduction may resolve the failure
- `should_rotate_credential` — try a different credential
- `should_fallback` — try a different provider or model

Use `#[non_exhaustive]` on the enum.

#### Verification

```bash
cd hymenium && cargo check 2>&1
cd hymenium && cargo test 2>&1
```

**Checklist:**
- [ ] `FailoverReason` enum is `#[non_exhaustive]` with documented variants
- [ ] `RecoveryHint` has four boolean flags, all defaulting to false
- [ ] Both types derive `Debug, Clone, PartialEq`

---

### Step 2: Implement priority-ordered classifier

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** Step 1

Implement a `classify_error` function that takes an error (or status code + optional body/metadata) and returns a `(FailoverReason, RecoveryHint)` pair. The classifier should be a priority-ordered match chain:

1. 401 → `AuthFailure` + rotate credential
2. 402 with quota signal → `QuotaExhausted` + fallback
3. 402/429 with rate signal → `RateLimited` + retryable
4. 402 with content signal → `ContentPolicy` + compress
5. 5xx → `ServerError` + retryable
6. Transport/network error → `TransportError` + retryable
7. Disconnect + large context → `ContextOverflow` + compress + fallback
8. Fallthrough → `Unknown`

#### Verification

```bash
cd hymenium && cargo test classify 2>&1
```

**Checklist:**
- [ ] Each FailoverReason variant has at least one test case
- [ ] Recovery hints are additive (a single error can set multiple flags)
- [ ] The classifier does not panic on any input

---

### Step 3: Wire classifier into dispatch error path

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** Step 2

Integrate the classifier at the point where `hymenium` handles provider dispatch failures. The existing error/retry path should now receive `(FailoverReason, RecoveryHint)` instead of raw error types. Existing retry logic can match on the hints to decide next action.

#### Verification

```bash
cd hymenium && cargo test 2>&1
cd hymenium && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Dispatch error path uses the classifier
- [ ] Existing retry behavior is preserved (no regression)
- [ ] No new clippy warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/hymenium/verify-error-classifier-taxonomy.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/hymenium/verify-error-classifier-taxonomy.sh
```

## Context

Source: hermes-agent ecosystem borrow audit (2026-04-14). The `FailoverReason` enum and composable recovery hints are the highest-leverage structural gap identified across the external audit corpus. See `.audit/external/audits/hermes-agent-ecosystem-borrow-audit.md` section "Priority-ordered error classifier with typed recovery hints" for the full reference design.

Related handoffs: none directly. If the enum proves useful across tools, a follow-up septa contract handoff should formalize it.
