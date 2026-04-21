# Memory Boundary Hardening

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Two defensive features hyphae lacks that mempalace implements: write-ahead audit logging for all memory mutations, and query sanitization to strip system-prompt contamination from search queries before embedding. Without these, silent quality degradation — from bad writes or polluted queries — is invisible until retrieval noticeably degrades.

## What exists (state)

- **`hyphae-store/`**: SQLite-backed memory mutations with no audit trail
- **`hyphae-core/`**: search path calls embedding model directly; no sanitization layer
- **`hyphae` CLI**: `search` command with no `--raw` bypass or debug transparency

## What needs doing (intent)

Add an append-only audit log for every memory mutation (store, update, forget, decay) and a sanitization pass for search queries before they reach the embedding model. Add transparency metadata to recall responses so operators can see what the search path actually did.

---

### Step 1: Add write-ahead audit log for memory mutations

**Project:** `hyphae/`
**Effort:** 1-2 days
**Depends on:** nothing

Add a local write-ahead audit log that records every memory mutation before it executes. This supports review, rollback, and debugging when memory quality degrades.

Implementation:
- Add an `audit_log` table in hyphae-store SQLite: `id`, `timestamp`, `operation` (`store`/`update`/`forget`/`decay`), `memory_id`, `topic`, `content_hash`, `metadata_json`
- Wrap memory mutation methods in hyphae-store to write an audit record before the actual mutation
- Add `hyphae audit list [--since <date>] [--operation <type>]` CLI command to inspect the log
- Add `hyphae audit rollback <audit_id>` for single-mutation undo (restores previous state from the log)
- Audit log is append-only. No silent writes.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd hyphae && cargo test --workspace 2>&1 | tail -15
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `audit_log` table created via migration
- [ ] Every `store_memory`, `update_memory`, `forget_memory` writes an audit record first
- [ ] `hyphae audit list` shows recent mutations
- [ ] `hyphae audit rollback` restores a single mutation
- [ ] Audit log survives crashes (written before the mutation, not after)
- [ ] Existing tests still pass (audit log is additive, not breaking)

---

### Step 2: Add query sanitization for search

**Project:** `hyphae/`
**Effort:** 4-8 hours
**Depends on:** nothing (independent of Step 1)

Sanitize search queries before they reach the embedding model. Agent context can leak into queries — system prompt fragments, tool-use XML, conversation metadata — which pollutes embeddings and degrades retrieval quality.

Implementation:
- Add a `sanitize_query` function in hyphae-core that:
  1. Strips common system-prompt prefixes (XML tags like `<system>`, `<tool_use>`, markdown headers from injected context)
  2. Removes conversation framing ("The user asked...", "Based on the previous context...")
  3. Normalizes whitespace
  4. Truncates to a maximum query length (e.g., 512 tokens) to prevent embedding model overload
- Wire `sanitize_query` into the search path before embedding generation in both `hyphae search` and MCP search tools
- Add `--raw` flag to bypass sanitization for debugging
- Log original vs sanitized query when `HYPHAE_LOG=debug`

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd hyphae && cargo test --workspace 2>&1 | tail -15
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `sanitize_query` strips XML tags, conversation framing, excess whitespace
- [ ] Search path calls `sanitize_query` before embedding
- [ ] `--raw` flag bypasses sanitization
- [ ] Debug logging shows original vs sanitized query
- [ ] Existing search tests still pass

---

### Step 3: Add transparency metadata to recall responses

**Project:** `hyphae/`
**Effort:** 2-4 hours
**Depends on:** Step 2

When hyphae returns search results (CLI or MCP), include transparency metadata: was the query sanitized, what was removed, how many results were filtered by decay, what the effective search radius was. This helps operators and agents understand why specific memories were or weren't recalled.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd hyphae && cargo test --workspace 2>&1 | tail -15
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Search results include `query_metadata` with sanitization info
- [ ] MCP search tool returns transparency fields
- [ ] `hyphae search --explain` shows query processing details

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/hyphae/verify-memory-boundary-hardening.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/hyphae/verify-memory-boundary-hardening.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete with failures.

## Context

From mempalace borrow audit. Mempalace's write-ahead log and query sanitization are the clearest examples of memory boundary hardening. These are defensive features that prevent silent quality degradation — invisible until retrieval noticeably degrades.

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsSteps 1 and 2 are independent and can be implemented in parallel.
