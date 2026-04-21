# Hyphae: Round 2 quality fixes

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none
- **Non-goals:** cross-project safety (separate handoff), content_hash TOCTOU (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — Purge date-parsing fallback is a no-op (HIGH)
`crates/hyphae-cli/src/commands/purge.rs:141-148`

Both arms of the `or_else` produce the identical string `format!("{before_str}T00:00:00+00:00")`. The fallback was presumably meant to handle a different input format, but it never does. Fix: implement the intended second parse attempt (e.g. accept bare `YYYY-MM-DD` as well as full RFC 3339) or remove the misleading `or_else` and document that only one format is accepted.

### 2 — Audit log written before transaction opens (MEDIUM, systemic)
`crates/hyphae-store/src/store/memory_store.rs:676-746`

`audit_memory(...)` is called before `unchecked_transaction(...)` in `replace_memory` (and the same pattern exists in `store`, `update`, `delete`, `prune`, `apply_decay`, `prune_expired`). If the transaction fails, the audit log records an operation that never happened. Move audit writes inside the transaction, or adopt a post-commit audit approach.

### 3 — consolidate_hint materialises full topic into memory (MEDIUM)
`crates/hyphae-mcp/src/tools/memory/recall.rs:267-268`

`compute_consolidation_hint` calls `store.get_by_topic(topic, project)` and loads all memories to compute `len()`, `min_by_key`, and `max_by_key`. This materialises the full row set for a potentially large topic. Use the existing aggregate SQL (`count_by_topic`, date fields in `topic_health`) instead.

### 4 — matches_call_relation over-matches (MEDIUM)
`crates/hyphae-mcp/src/tools/memoir.rs:930-938`

`RelatedTo` is the fallback for any unrecognized relation string and is also matched as a call-graph edge. A link with relation `"owns"` or `"manages"` appears in caller/callee queries. Tighten the match to explicit call-semantics relations only, or document and test the intentional catch-all behavior.

### 5 — session_context_all(10_000) fetches unconditionally (MEDIUM)
`crates/hyphae-mcp/src/tools/context.rs:147`

Fetches up to 10,000 session rows then filters in Rust with no early termination. Add project scoping before the fetch and terminate once `MAX_PER_SOURCE` quota is satisfied.

### 6 — chunk_sliding_window destroys whitespace (MEDIUM)
`crates/hyphae-ingest/src/chunker.rs:192`

Tokenises by splitting on whitespace and rejoins with single spaces, permanently collapsing all indentation and line structure. Code content routed through this path loses syntactic meaning. Either preserve original whitespace in the join or apply the sliding window only to prose content.

### 7 — Low severity items
- `tools/memory/maintenance.rs:75` — consolidation always sets `Importance::High` regardless of source importance; accept an optional importance parameter.
- `tools/memoir.rs:64` — `memoir_stats` errors silently produce `concept_count = 0`; log the error.
- `tools/memory/store.rs:45` — Unrecognized importance string silently defaults to `Medium`; warn or error.
- `tools/memoir.rs:410` — `tool_memoir_link` allows duplicate links; add a uniqueness check.
- `store/search.rs:297` — `sanitize_fts_query` does not strip NUL bytes; add a NUL guard.

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/hyphae
cargo test --workspace 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

## Checklist

- [ ] Purge date parsing handles both formats correctly (or documents one format)
- [ ] Audit writes are inside transactions across all affected methods
- [ ] Consolidation hint uses aggregate SQL, not full materialisation
- [ ] `matches_call_relation` does not match unrecognised relations
- [ ] `session_context_all` is project-scoped and terminates early
- [ ] `chunk_sliding_window` preserves or correctly handles whitespace
- [ ] Low severity items addressed
- [ ] All tests pass, clippy clean
