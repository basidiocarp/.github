# Hyphae Identity-v1 Read Asymmetry

## Problem

Cortina and mycelium send `project_root` and `worktree_id` on writes, giving
worktree-level isolation on the way in. But recall reads still match on legacy
`project + scope` patterns in some surfaces. A recall in worktree A can surface
memories written by worktree B of the same project. The ADR states explicitly:
"memory recall and other project-scoped memory surfaces still do not expose a
full identity-v1-aware read contract." This is the leakiest correctness gap in
the pipeline — it affects what the agent actually uses to make decisions.

## What exists (state)

- **Identity-v1 write path:** wired — cortina and mycelium send `project_root` + `worktree_id`
- **Identity-v1 read path:** incomplete — some recall surfaces still match on legacy `project + scope`
- **ADR:** `ADR-HYPHAE-SESSION-IDENTITY-CONTRACT.md` documents the contract and the gap
- **Impact:** memories from worktree B may appear in worktree A recalls for the same project

## What needs doing (intent)

Audit all hyphae recall surfaces and update them to filter by `worktree_id` when
provided in the identity pair, matching the same scoping used on writes.

---

### Step 1: Audit recall surfaces

**Project:** `hyphae/`
**Effort:** 1 hour

Identify all `hyphae_memory_recall`, `hyphae_search_docs`, `hyphae_gather_context`,
and `hyphae_session_context` code paths. For each, check whether it applies
`worktree_id` filtering when the caller provides an identity pair.

**Files to check:**
- `crates/hyphae-store/src/store/memory_store.rs` — core recall queries
- `crates/hyphae-server/src/tools/` — MCP tool handlers that call recall
- `crates/hyphae-cli/src/commands/` — CLI recall commands

#### Verification

```bash
cd hyphae && grep -rn "worktree_id" crates/ --include="*.rs" | grep -v "test\|//\|write\|insert\|update" | head -20
```

**Output:**
<!-- PASTE START -->
```
crates/hyphae-store/src/schema.rs:99:            worktree_id TEXT,
crates/hyphae-store/src/schema.rs:487:    let has_worktree_id_sessions: bool = tx
crates/hyphae-store/src/schema.rs:496:        tx.execute_batch("ALTER TABLE sessions ADD COLUMN worktree_id TEXT;")
crates/hyphae-store/src/store/session.rs:17:    pub worktree_id: Option<String>,
crates/hyphae-store/src/store/session.rs:124:    /// When both `project_root` and `worktree_id` are present they become the
crates/hyphae-store/src/store/session.rs:294:        worktree_id: Option<&str>,
crates/hyphae-store/src/store/session.rs:300:        if let (Some(project_root), Some(worktree_id)) = (project_root, worktree_id) {
crates/hyphae-store/src/store/session.rs:463:                   AND worktree_id = ?3
crates/hyphae-mcp/src/tools/context.rs:45:    let (project_root, worktree_id) =
crates/hyphae-mcp/src/tools/context.rs:106:            store.session_context_identity(proj, project_root, worktree_id, scope, 10_000)
crates/hyphae-mcp/src/tools/schema.rs:52:            "name": "hyphae_memory_recall",
crates/hyphae-mcp/src/tools/schema.rs:86:                "project_root": {
crates/hyphae-mcp/src/tools/schema.rs:90:                "worktree_id": {
crates/hyphae-mcp/src/tools/schema.rs:601:                    "description": "Project name to scope the search (optional, uses configured project if omitted). Required when project_root and worktree_id are supplied so structured session lookup stays bounded."
crates/hyphae-mcp/src/tools/schema.rs:643:                        "required": ["project_root", "worktree_id"]
crates/hyphae-cli/src/commands/context.rs:19:    pub(crate) project_root: Option<String>,
crates/hyphae-cli/src/commands/context.rs:22:    pub(crate) worktree_id: Option<String>,
```

<!-- PASTE END -->

**Checklist:**
- [x] All recall surfaces listed
- [x] Each surface marked: identity-v1 aware / legacy / unscoped

---

### Step 2: Fix legacy recall surfaces

**Project:** `hyphae/`
**Effort:** 2-3 hours
**Depends on:** Step 1

For each legacy recall surface found in Step 1, add worktree-scoped filtering.
The pattern from the write side: when `worktree_id` is present in the caller
context, add `AND worktree_id = ?` to the SQL query. When absent, fall back to
project-only scoping (not cross-worktree).

#### Verification

```bash
cd hyphae && cargo test recall 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
```
test tools::tests::test_recall_scopes_to_worktree_when_identity_is_provided ... ok
test tools::tests::test_recall_falls_back_without_identity_pair ... ok
test tools::context::tests::test_gather_context_scopes_memories_to_worktree_identity ... ok
test store::feedback::tests::test_log_recall_event_persists_payload ... ok
test store::feedback::tests::test_compute_session_effectiveness_prefers_direct_recall_attribution ... ok
test store::evaluation::tests::test_collect_evaluation_window_dedupes_structured_recall_mirrors ... ok
test store::evaluation::tests::test_collect_evaluation_window_keeps_distinct_legacy_recalls_in_mixed_mode ... ok
test store::feedback::tests::test_log_outcome_signal_computes_recall_effectiveness_after_session_end ... ok
test store::tests::test_search_hybrid_applies_recall_effectiveness_bias ... ok

test result: ok. 9 passed; 0 failed; 0 ignored; 0 measured; 218 filtered out; finished in 0.08s
```

<!-- PASTE END -->

**Checklist:**
- [x] All surfaces from Step 1 updated
- [x] Test: recall in worktree A does not return memories written by worktree B
- [x] Test: recall without worktree_id returns project-scoped memories (not cross-worktree)
- [x] Existing recall tests still pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. All checklist items are checked
3. No recall surface returns cross-worktree results when a worktree_id is provided

## Context

Identified in `IMPROVEMENTS-OBSERVATION-V1.md` as the leakiest correctness gap
in the pipeline. The ADR `ADR-HYPHAE-SESSION-IDENTITY-CONTRACT.md` has the full
identity-v1 contract. Write-side is complete; read-side is the remaining gap.
