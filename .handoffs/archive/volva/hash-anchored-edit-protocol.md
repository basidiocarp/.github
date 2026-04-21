# Hash-Anchored Edit Protocol

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** `volva/...`
- **Cross-repo edits:** none
- **Non-goals:** MCP tool surface changes in rhizome; full hashline rendering format from oh-my-openagent; changes outside the edit and file operations modules
- **Verification contract:** run the repo-local commands below and `bash .handoffs/volva/verify-hash-anchored-edit-protocol.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** `src/edit.rs` or new `src/hash_edit.rs`; `src/file.rs` or equivalent file operations module
- **Reference seams:** oh-my-openagent hash-anchored edit tool (hashline format) for the per-line tag concept; existing volva file read/write paths for integration points
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Agents editing files frequently apply edits against stale context — the file changed since the agent last read it, and the edit silently corrupts the file or fails. oh-my-openagent ships a measurable fix: every line is tagged with a two-character xxHash32 fingerprint, edit proposals reference those tags, and before applying, the tool re-hashes target lines to detect staleness. Streaming uses 200-line or 64KB chunks. The claimed improvement went from 6.7% to 68.3% accuracy on Grok Code Fast 1. Volva owns the agent edit surface at the runtime seam and has no equivalent staleness detection.

## What exists (state)

- **`volva`:** has file read and write operations but no per-line hash tagging or staleness detection
- **Ecosystem:** no tool in the ecosystem tags lines for edit-time staleness verification
- **oh-my-openagent reference:** a hashline format (`{line}#{hash}|{content}`) with edit proposals referencing tags, staleness re-check before applying, and chunked streaming at 200-line or 64KB boundaries

## What needs doing (intent)

Add a hash-anchored edit protocol to volva. Define a per-line hashing function, expose a "read with hashes" operation that returns content with per-line tags, add a "write with staleness check" operation that re-hashes target lines and rejects edits if tags do not match, and add chunked streaming for large files at 200-line or 64KB boundaries.

## Scope

- **Primary seam:** file read and edit operations in volva
- **Allowed files:** `volva/src/` edit and file operations modules
- **Explicit non-goals:**
  - Do not change the MCP tool surface in rhizome (separate concern)
  - Do not implement the full hashline rendering format from oh-my-openagent (adapt the concept to Rust)
  - Do not change volva modules outside of file and edit operations

---

### Step 1: Define line-hashing function and tagged line type

**Project:** `volva/`
**Effort:** 0.5 day
**Depends on:** nothing

Define a short per-line hash function using xxHash32 or an equivalent fast, stable hash available in the Rust ecosystem. Produce a compact tag (two to four hex characters is sufficient). Define a `TaggedLine` type that pairs a line number, a hash tag, and the line content. The tag must be deterministic — same content always produces the same tag.

#### Verification

```bash
cd volva && cargo check 2>&1
cd volva && cargo test 2>&1
```

**Checklist:**
- [ ] Hash function is deterministic and tested with known inputs
- [ ] `TaggedLine` type derives `Debug, Clone, PartialEq`
- [ ] Tag format is documented in the type definition

---

### Step 2: Add "read with hashes" operation

**Project:** `volva/`
**Effort:** 0.5 day
**Depends on:** Step 1

Add a read operation that returns file content as a `Vec<TaggedLine>`. For files larger than 200 lines or 64KB, the operation must return chunks rather than the full file in one call. Each chunk carries the line range it covers so callers can request specific ranges.

#### Verification

```bash
cd volva && cargo test read 2>&1
```

**Checklist:**
- [ ] Read operation returns tagged lines for every line in the file
- [ ] Chunking triggers at 200-line or 64KB boundary, whichever comes first
- [ ] Chunk metadata includes the line range covered
- [ ] Empty files and single-line files are handled without panic

---

### Step 3: Add "write with staleness check" operation

**Project:** `volva/`
**Effort:** 0.5 day
**Depends on:** Step 2

Add a write operation that accepts an edit proposal referencing one or more line tags. Before applying the edit, re-hash the target lines from the current file state. If any tag does not match the current hash, reject the edit and return a `StalenessError` with the mismatched line numbers and current vs expected tags. Only apply the edit when all referenced tags are still current.

#### Verification

```bash
cd volva && cargo test write 2>&1
cd volva && cargo test staleness 2>&1
```

**Checklist:**
- [ ] Edit is rejected with a typed error when any tag is stale
- [ ] Edit is applied when all tags match current file state
- [ ] `StalenessError` includes mismatched line numbers and both tags
- [ ] No panic on any input, including missing lines or empty proposals

---

### Step 4: Wire into volva's existing edit surface and run full check

**Project:** `volva/`
**Effort:** 0.5 day
**Depends on:** Step 3

Integrate the hash-anchored protocol into the existing volva edit path. Existing callers that do not supply tags continue to work via a bypass path or by auto-reading hashes before write. No breaking changes to the existing API surface.

#### Verification

```bash
cd volva && cargo test 2>&1
cd volva && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Existing edit behavior is preserved (no regression)
- [ ] New protocol is reachable from the main edit surface
- [ ] No new clippy warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/volva/verify-hash-anchored-edit-protocol.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/volva/verify-hash-anchored-edit-protocol.sh
```

## Context

Source: oh-my-openagent audit (2026-04-14) section "Hash-anchored edit tool (hashline)". This was identified as "the strongest direct borrow target in the entire repo for volva" by the sonnet verification agent. The measured accuracy improvement (6.7% to 68.3% on Grok Code Fast 1) makes this the highest-signal structural borrow in the external audit corpus for the volva runtime seam.

Related handoffs: #126 Volva Execution Environment Isolation.
