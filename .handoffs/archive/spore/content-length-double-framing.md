# Spore ContentLength Double-Framing Bug

## Problem

In `subprocess.rs`, `call_tool()` encodes the request via `jsonrpc::encode()` which
adds a Content-Length header, then `send_request()` wraps the already-framed string
in a second Content-Length header. Any LSP server receiving ContentLength-framed
requests gets `Content-Length: M\r\n\r\nContent-Length: N\r\n\r\n{json}` — malformed input.

Currently masked because all consumers use LineDelimited framing, but rhizome's LSP
backend path would hit this.

## What exists (state)

- **File:** `spore/src/subprocess.rs:109-171`
- **`call_tool()` (line 113):** calls `jsonrpc::encode(&request)` for ContentLength mode,
  which produces `Content-Length: N\r\n\r\n{json}`
- **`send_request()` (line 163-172):** ContentLength branch wraps the input in another
  `Content-Length: M\r\n\r\n{encoded}` header
- **Tests:** Mock Python server reads char-by-char until `}`, masking the bug

## What needs doing (intent)

Fix the double-framing so ContentLength mode produces exactly one Content-Length header.
Add a test with a spec-compliant Content-Length parser to prevent regression.

---

### Step 1: Fix the framing path

**Project:** `spore/`
**Effort:** 30 min
**Depends on:** nothing

Two approaches (pick one):

**Option A** — Skip `jsonrpc::encode()` in `call_tool()` for ContentLength:
In `call_tool()`, serialize the request to JSON only (not framed), let `send_request()`
add the single Content-Length header.

**Option B** — Skip the header in `send_request()` when input is already framed:
In `send_request()`, detect that the input starts with `Content-Length:` and write it directly.

Option A is cleaner — `send_request()` should own all framing.

#### Files to modify

**`src/subprocess.rs`** — in `call_tool()`, change the ContentLength branch to produce
raw JSON (via `serde_json::to_string(&request)`) instead of `jsonrpc::encode(&request)`.
Leave `send_request()` as the single point that adds framing.

#### Verification

```bash
cd spore && cargo test 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] ContentLength mode sends exactly one Content-Length header
- [ ] LineDelimited mode still works (no regression)
- [ ] Existing tests pass

---

### Step 2: Add spec-compliant ContentLength test

**Project:** `spore/`
**Effort:** 20 min
**Depends on:** Step 1

Update the Python mock server in the ContentLength test to parse Content-Length headers
properly (read header, parse length, read exact N bytes) instead of scanning for `}`.
This ensures the test would fail if double-framing reappears.

#### Verification

```bash
cd spore && cargo test content_length 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Mock server parses Content-Length header, reads exact N bytes
- [ ] Test passes with single-framed input
- [ ] Test would fail with double-framed input (verify by temporarily reintroducing bug)

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. All checklist items are checked
3. A real LSP server could receive valid ContentLength-framed requests

## Context

Found during global ecosystem audit (2026-04-04), Layer 2 structural review of spore.
See `ECOSYSTEM-AUDIT-2026-04-04.md` C2. Currently latent — no consumer uses ContentLength
mode in production — but rhizome's LSP backend would be the first.
