# Cortina Evidence Bridge Retry Semantics

## Problem

The cortina→canopy evidence bridge is "best-effort" — if canopy is briefly
unavailable when cortina tries to write an evidence ref, the write silently fails.
For solo use this is acceptable. For orchestration decisions ("has this task been
verified?", "what did the implementer observe?"), silent evidence failures are a
correctness problem: an evidence ref that wasn't written due to transient failure
looks identical to one that was deliberately left empty. The bridge needs retry
semantics (or at minimum observable failure counts) before evidence refs can be
relied on for orchestration decisions.

## What exists (state)

- **Bridge:** `cortina/src/bridges/canopy.rs` (or equivalent) — best-effort write
- **`cortina status`:** shows session state but not evidence write failure counts
- **No retry:** failed writes are dropped silently
- **No observable failures:** no counter in `cortina status` output

## What needs doing (intent)

Add retry with backoff for transient canopy failures, and surface evidence write
failure counts in `cortina status` output.

---

### Step 1: Add retry with backoff

**Project:** `cortina/`
**Effort:** 1-2 hours

Wrap evidence writes with a simple retry loop: 3 attempts, exponential backoff
(100ms, 500ms, 2s). If all three attempts fail, record the failure in a local
counter and log at warn level. Do NOT block the session — evidence writes remain
async/fire-and-forget, just with retries before giving up.

#### Files to modify

**`cortina/src/bridges/canopy.rs`** (or equivalent) — add retry wrapper.

#### Verification

```bash
cd cortina && cargo test evidence 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Evidence writes retry up to 3 times before failing
- [ ] Failed write increments a local counter
- [ ] Session is not blocked by evidence write failures

---

### Step 2: Surface failure counts in cortina status

**Project:** `cortina/`
**Effort:** 30 min
**Depends on:** Step 1

Add evidence write failure count to `cortina status` output so operators can see
when evidence is not flowing to canopy.

```
Evidence refs written: 12
Evidence write failures: 0
```

**Checklist:**
- [ ] `cortina status` shows evidence refs written and failure count
- [ ] Counter resets per session or persists (choose one, document it)

---

## Completion Protocol

1. Every step has verification output pasted
2. All checklist items checked
3. `cd cortina && cargo test --all` passes

## Context

`IMPROVEMENTS-OBSERVATION-V1.md` identified this as a prerequisite before
evidence refs can drive orchestration decisions. The canopy evidence bridge
write path shipped in cortina v0.2.0.
