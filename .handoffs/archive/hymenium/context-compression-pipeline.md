# Context Compression Pipeline

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/...`
- **Cross-repo edits:** none in this handoff; hyphae `on_pre_compress` hook is a follow-up concern
- **Non-goals:** implementing the LLM summarization step itself (requires a model call, separate concern); changes outside hymenium context and dispatch modules
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-context-compression-pipeline.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** new `src/context.rs` or `src/context/`; `src/dispatch/` for pipeline wiring
- **Reference seams:** hermes-agent `agent/context_manager.py` for the six-step algorithm and tool-pair sanitization logic; existing hymenium dispatch flow for integration points
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

No ecosystem tool treats context compression as a structured, pluggable concern. When context windows fill up, the response is either naive truncation or ad hoc summarization. Hermes Agent demonstrates a six-step algorithm: prune old tool results, protect the head, apply tail protection with token budget, align on message boundaries, run LLM summarization, and apply iterative update. The critical detail is tool-pair sanitization after compression — orphaned tool results (results whose call was removed) are deleted and stub results are inserted for calls whose results were removed. Without this, compressed context is structurally invalid for the model. The hermes-agent audit calls this "a correctness requirement, not an optimization."

## What exists (state)

- **`hymenium`:** has dispatch and phase gating but no structured context compression pipeline
- **Ecosystem:** no tool defines a pluggable compression trait or enforces tool-pair sanitization after compression
- **hermes-agent reference:** a six-step compression algorithm with mandatory tool-pair sanitization, focus_topic parameter for summarization bias, and iterative update after compression

## What needs doing (intent)

Add a `ContextEngine` trait to hymenium with pluggable compression steps. The minimum viable pipeline: define the trait with a `compress()` method, implement tool-pair sanitization as a mandatory post-compression step (remove orphaned results, insert stubs for dropped calls), add a `focus_topic` parameter that biases summarization toward a specific concern, and wire the pipeline into hymenium's dispatch flow so it can be invoked when context budget is exceeded.

## Scope

- **Primary seam:** context management and dispatch in hymenium
- **Allowed files:** `hymenium/src/` context and dispatch modules
- **Explicit non-goals:**
  - Do not implement the LLM summarization step itself (that requires a model call and is a separate concern)
  - Do not implement the hyphae `on_pre_compress` hook (tracked in #127)
  - Do not change hymenium modules outside of context and dispatch

---

### Step 1: Define ContextEngine trait and message model

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** nothing

Define a `ContextEngine` trait with a `compress()` method. The method accepts a message list and a `CompressionParams` struct (including `focus_topic: Option<String>` and a token budget). The return type is a compressed message list plus a `CompressionReport` describing what was removed, summarized, or stubbed. Use `#[non_exhaustive]` on `CompressionParams` to leave room for future parameters.

#### Verification

```bash
cd hymenium && cargo check 2>&1
cd hymenium && cargo test 2>&1
```

**Checklist:**
- [x] `ContextEngine` trait is defined with a `compress()` method
- [x] `CompressionParams` has `focus_topic: Option<String>` and a token budget field
- [x] `CompressionParams` is `#[non_exhaustive]`
- [x] `CompressionReport` describes removed, summarized, and stubbed items

---

### Step 2: Implement tool-pair sanitization

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** Step 1

Implement tool-pair sanitization as a standalone function that runs after any compression step. The sanitizer must: remove tool results whose corresponding tool call was removed by compression, and insert stub results for tool calls whose results were removed by compression. The stub result must be structurally valid for the model (matching the tool call id and a minimal content payload). This step is mandatory — it must run even when summarization is skipped.

#### Verification

```bash
cd hymenium && cargo test sanitize 2>&1
cd hymenium && cargo test tool_pair 2>&1
```

**Checklist:**
- [x] Orphaned tool results are removed after compression
- [x] Stub results are inserted for tool calls whose results were dropped
- [x] Stub results carry a matching tool call id
- [x] Sanitizer does not panic on any input, including empty message lists

---

### Step 3: Wire pipeline into dispatch flow

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** Step 2

Integrate the `ContextEngine` pipeline into hymenium's dispatch flow. When the context budget is exceeded (as classified by #121 `ContextOverflow`), the dispatch path invokes the engine, runs sanitization, and retries with the compressed context. The `focus_topic` should be populated from the current dispatch target when available.

#### Verification

```bash
cd hymenium && cargo test 2>&1
cd hymenium && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [x] Dispatch path invokes compression when context budget is exceeded
- [x] Tool-pair sanitization runs after every compression invocation
- [x] `focus_topic` is wired from dispatch context where available
- [x] No new clippy warnings
- [x] Existing dispatch behavior is preserved (no regression)

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/hymenium/verify-context-compression-pipeline.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/hymenium/verify-context-compression-pipeline.sh
```

### Verification Evidence

```text
$ cd hymenium && cargo fmt --all --check
$ cd hymenium && cargo check
Finished `dev` profile [unoptimized + debuginfo]

$ cd hymenium && cargo test
118 lib tests passed
11 parser tests passed
0 doc tests failed

$ cd hymenium && cargo clippy -- -D warnings
Finished `dev` profile [unoptimized + debuginfo]

$ bash .handoffs/hymenium/verify-context-compression-pipeline.sh
PASS: cargo check
PASS: cargo test
PASS: cargo clippy
PASS: ContextEngine trait exists
PASS: compress method exists
PASS: CompressionParams exists
PASS: focus_topic field exists
PASS: tool-pair sanitization exists

Results: 8 passed, 0 failed
```

### Completion Notes

- Added a pluggable `ContextEngine` surface in `hymenium/src/context.rs`.
- Dispatch now retries with compressed context only when the rendered dispatch surface exceeds budget.
- Tool-pair sanitization now inserts stub results relative to retained output order, so earlier removals do not break structural validity.
- The paired verifier script was fixed to work under `set -e`.

## Context

Source: hermes-agent audit (2026-04-14) section "Context compression pipeline with tool-pair sanitization". The tool-pair sanitization step is described as "a correctness requirement, not an optimization" — compressed context without it is structurally invalid for the model. The six-step algorithm and focus_topic parameter are borrowed from the hermes-agent reference implementation.

Related handoffs: #121 Error Classifier Taxonomy (context overflow is a classified failure that triggers compression); #127 Hyphae Memory Provider Lifecycle (on_pre_compress hook is a follow-up concern).
