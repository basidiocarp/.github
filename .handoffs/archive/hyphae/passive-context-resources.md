# Hyphae Passive Context Resources

## Problem

The audit set repeatedly pointed at the same gap in `hyphae`: it is strong at active retrieval tools, but it still lacks passive resource-style context surfaces and richer durable artifact types for things like council output, compact summaries, and project-understanding bundles. That limits preload and makes some context assembly more tool-call-driven than it needs to be.

## What exists (state)

- **`hyphae-mcp`:** already exposes rich context-gathering and session tools
- **`hyphae-store`:** already stores memories, sessions, code, and documents
- **No MCP resources:** current server surface is tools-first
- **Examples:** `context-keeper`, `icm`, `council`, and `Understand-Anything` all pointed to passive resources or richer durable artifact types

## What needs doing (intent)

Add passive MCP resources and richer typed artifact surfaces to `hyphae` so clients can preload context without always issuing tool calls. Start with:

- resource-style context bundles
- typed council artifacts
- typed compact artifacts
- typed project-understanding bundles
- redaction at the recall boundary

---

### Step 1: Add passive MCP resource surfaces

**Project:** `hyphae/`
**Effort:** 3-4 hours
**Depends on:** nothing

Extend the MCP server so it can expose at least one passive context resource alongside the existing tools. Start with a bounded project/session context resource rather than trying to expose everything at once.

#### Files to modify

**`hyphae/crates/hyphae-mcp/src/server.rs`** — add MCP resource registration and routing.

**`hyphae/crates/hyphae-mcp/src/tools/context.rs`** — reuse existing bounded assembly logic rather than duplicating context construction.

#### Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -20
cd hyphae && cargo test --workspace 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Finished `dev` profile [optimized + debuginfo] target(s) in 0.40s

test store::tests::test_stats ... ok
test store::tests::test_stats_empty ... ok
test store::tests::test_store_and_get ... ok
test store::tests::test_store_round_trip_preserves_branch_and_worktree ... ok
test store::tests::test_topic_health_not_found ... ok
test store::tests::test_store_with_embedding ... ok
test store::tests::test_topic_health ... ok
test store::tests::test_update ... ok
test store::tests::test_update_access ... ok
test store::tests::test_update_memoir ... ok
test store::tests::test_update_concept ... ok
test store::tests::test_update_with_embedding ... ok
test store::tests::test_with_dims_applies_sqlite_pragmas ... ok

test result: ok. 243 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.94s

   Doc-tests hyphae_core
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
   Doc-tests hyphae_ingest
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
   Doc-tests hyphae_mcp
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
   Doc-tests hyphae_store
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
<!-- PASTE END -->

**Checklist:**
- [x] hyphae MCP server exposes at least one passive context resource
- [x] resource content is built from existing bounded context logic
- [x] build and tests pass

---

### Step 2: Add richer typed artifact records

**Project:** `hyphae/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Add typed storage or retrieval surfaces for at least two of:

- council artifacts
- compact summaries
- project-understanding bundles

Prefer typed records over markdown append patterns or opaque blobs.

#### Files to modify

**`hyphae/` store and MCP crates** — add artifact types, storage, and retrieval surfaces where needed.

#### Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -20
cd hyphae && cargo test --workspace 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Finished `dev` profile [optimized + debuginfo] target(s) in 0.40s

test store::tests::test_stats ... ok
test store::tests::test_stats_empty ... ok
test store::tests::test_store_and_get ... ok
test store::tests::test_store_round_trip_preserves_branch_and_worktree ... ok
test store::tests::test_topic_health_not_found ... ok
test store::tests::test_store_with_embedding ... ok
test store::tests::test_topic_health ... ok
test store::tests::test_update ... ok
test store::tests::test_update_access ... ok
test store::tests::test_update_memoir ... ok
test store::tests::test_update_concept ... ok
test store::tests::test_update_with_embedding ... ok
test store::tests::test_with_dims_applies_sqlite_pragmas ... ok

test result: ok. 243 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.94s

   Doc-tests hyphae_core
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
   Doc-tests hyphae_ingest
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
   Doc-tests hyphae_mcp
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
   Doc-tests hyphae_store
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
<!-- PASTE END -->

**Checklist:**
- [x] at least two richer artifact types are represented explicitly
- [x] retrieval surface exists for the new artifact types
- [x] build and tests pass

---

### Step 3: Add redaction at the context boundary

**Project:** `hyphae/`
**Effort:** 2-3 hours
**Depends on:** Steps 1-2

Filter or redact sensitive values before passive resources or retrieval summaries are surfaced. Start with obvious secret-bearing fields and make the policy explicit.

#### Files to modify

**`hyphae/` context and retrieval surfaces** — add boundary filtering before output.

#### Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -20
cd hyphae && cargo test --workspace 2>&1 | tail -40
bash .handoffs/archive/hyphae/verify-passive-context-resources.sh
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Finished `dev` profile [optimized + debuginfo] target(s) in 0.40s

test store::tests::test_stats ... ok
test store::tests::test_stats_empty ... ok
test store::tests::test_store_and_get ... ok
test store::tests::test_store_round_trip_preserves_branch_and_worktree ... ok
test store::tests::test_topic_health_not_found ... ok
test store::tests::test_store_with_embedding ... ok
test store::tests::test_topic_health ... ok
test store::tests::test_update ... ok
test store::tests::test_update_access ... ok
test store::tests::test_update_memoir ... ok
test store::tests::test_update_concept ... ok
test store::tests::test_update_with_embedding ... ok
test store::tests::test_with_dims_applies_sqlite_pragmas ... ok

test result: ok. 243 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.94s

   Doc-tests hyphae_core
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
   Doc-tests hyphae_ingest
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
   Doc-tests hyphae_mcp
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
   Doc-tests hyphae_store
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

PASS: Hyphae MCP server mentions resources
PASS: Hyphae context surface exists
PASS: Hyphae mentions council, compact, or understanding artifacts
PASS: Hyphae retrieval mentions redaction or filtering
PASS: Hyphae resource reads require explicit project context
PASS: Hyphae resource list hides current resources without project context
PASS: Hyphae initialize preload is redacted
PASS: Hyphae initialize without project skips passive preload
Results: 8 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] passive context surfaces redact or filter sensitive values
- [x] typed artifact retrieval uses the same boundary policy
- [x] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/hyphae/verify-passive-context-resources.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/hyphae/verify-passive-context-resources.sh
```

**Output:**
<!-- PASTE START -->
PASS: Hyphae MCP server mentions resources
PASS: Hyphae context surface exists
PASS: Hyphae mentions council, compact, or understanding artifacts
PASS: Hyphae retrieval mentions redaction or filtering
PASS: Hyphae resource reads require explicit project context
PASS: Hyphae resource list hides current resources without project context
PASS: Hyphae initialize preload is redacted
PASS: Hyphae initialize without project skips passive preload
Results: 8 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/context-keeper/ecosystem-borrow-audit.md`
- `.audit/external/audits/icm/ecosystem-borrow-audit.md`
- `.audit/external/audits/council/ecosystem-borrow-audit.md`
- `.audit/external/audits/Understand-Anything/ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
