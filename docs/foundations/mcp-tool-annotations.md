# MCP Tool Annotation Classification

Authoritative annotation hints for all rhizome and hyphae MCP tools.
These values inform dispatch policy (#103d), hook templates (#103e), and
agent system prompts about tool semantics.

## Annotation Semantics

| Annotation | Meaning |
|---|---|
| `readOnlyHint` | Tool does not modify any persistent state |
| `destructiveHint` | Tool may permanently remove or overwrite data without recovery path |
| `idempotentHint` | Repeated identical calls produce the same result as one call |

---

## Rhizome Tools

| Tool | readOnlyHint | destructiveHint | idempotentHint | Notes |
|---|---|---|---|---|
| `get_symbols` | true | false | true | |
| `get_structure` | true | false | true | |
| `get_definition` | true | false | true | |
| `search_symbols` | true | false | true | |
| `find_references` | true | false | true | |
| `analyze_impact` | true | false | true | |
| `go_to_definition` | true | false | true | |
| `get_signature` | true | false | true | |
| `get_imports` | true | false | true | |
| `get_exports` | true | false | true | |
| `get_call_sites` | true | false | true | |
| `get_scope` | true | false | true | |
| `get_dependencies` | true | false | true | |
| `get_parameters` | true | false | true | |
| `get_enclosing_class` | true | false | true | |
| `get_symbol_body` | true | false | true | |
| `get_region` | true | false | true | |
| `get_annotations` | true | false | true | |
| `get_complexity` | true | false | true | |
| `get_type_definitions` | true | false | true | |
| `get_tests` | true | false | true | |
| `get_diff_symbols` | true | false | true | Reads git diff state |
| `get_changed_files` | true | false | true | Reads git state |
| `get_diagnostics` | true | false | true | |
| `get_hover_info` | true | false | true | |
| `summarize_file` | true | false | true | |
| `summarize_project` | true | false | true | |
| `replace_symbol_body` | false | false | false | Modifies source; recoverable via git |
| `insert_after_symbol` | false | false | false | Additive; not idempotent (inserts accumulate) |
| `insert_before_symbol` | false | false | false | Additive; not idempotent |
| `replace_lines` | false | false | false | Overwrites lines; recoverable via git |
| `insert_at_line` | false | false | false | Additive; not idempotent |
| `delete_lines` | false | true | false | Removes content; destructive — git is recovery path |
| `create_file` | false | false | true | Idempotent if content is identical; destructive=false because new file only |
| `copy_symbol` | false | false | false | Additive; calling twice creates duplicates |
| `move_symbol` | false | false | false | Two moves with same args produce wrong result |
| `rename_symbol` | false | false | false | Renaming twice with same args produces wrong result |
| `export_to_hyphae` | false | false | true | Writes to hyphae; idempotent — re-export overwrites same record |
| `export_repo_understanding` | false | false | true | Idempotent — same repo state yields same export |
| `rhizome_onboard` | false | false | true | Setup op; safe to run multiple times |

---

## Hyphae Tools

| Tool | readOnlyHint | destructiveHint | idempotentHint | Notes |
|---|---|---|---|---|
| `hyphae_memory_recall` | true | false | true | |
| `hyphae_memory_list_topics` | true | false | true | |
| `hyphae_memory_stats` | true | false | true | |
| `hyphae_memory_health` | true | false | true | |
| `hyphae_memory_list_invalidated` | true | false | true | |
| `hyphae_memory_store` | false | false | false | Adds a memory; calling twice creates duplicates |
| `hyphae_memory_update` | false | false | true | Updates existing memory; idempotent for same content |
| `hyphae_memory_forget` | false | true | true | Deletes memory permanently |
| `hyphae_memory_invalidate` | false | true | true | Marks memories invalid; destructive to recall quality |
| `hyphae_memory_consolidate` | false | false | true | Merges redundant memories; safe to re-run |
| `hyphae_memory_embed_all` | false | false | true | Generates embeddings; idempotent for same state |
| `hyphae_memoir_list` | true | false | true | |
| `hyphae_memoir_show` | true | false | true | |
| `hyphae_memoir_search` | true | false | true | |
| `hyphae_memoir_inspect` | true | false | true | |
| `hyphae_memoir_search_all` | true | false | true | |
| `hyphae_memoir_create` | false | false | false | Creates new memoir; calling twice creates duplicates |
| `hyphae_memoir_add_concept` | false | false | false | Additive; not idempotent |
| `hyphae_memoir_refine` | false | false | true | Updates memoir; idempotent for same content |
| `hyphae_memoir_link` | false | false | true | Linking is idempotent — re-linking same pair is a no-op |
| `hyphae_code_query` | true | false | true | Query only |
| `hyphae_recall_global` | true | false | true | |
| `hyphae_promote_to_memoir` | false | false | true | Idempotent — promoting same memory yields same memoir |
| `hyphae_search_docs` | true | false | true | |
| `hyphae_list_sources` | true | false | true | |
| `hyphae_ingest_file` | false | false | true | Re-ingesting same file overwrites; idempotent for same content |
| `hyphae_forget_source` | false | true | true | Removes source from index permanently |
| `hyphae_gather_context` | true | false | true | |
| `hyphae_search_all` | true | false | true | |
| `hyphae_import_code_graph` | false | false | true | Idempotent — re-import of same graph overwrites |
| `hyphae_session_start` | false | false | false | Creates a new session record; calling twice creates two sessions |
| `hyphae_session_end` | false | false | true | Closing same session twice is safe |
| `hyphae_session_context` | true | false | true | |
| `hyphae_store_command_output` | false | false | false | Stores command output; calling twice creates duplicate entries |
| `hyphae_get_command_chunks` | true | false | true | |
| `hyphae_artifact_store` | false | false | true | Upserts; idempotent for same artifact |
| `hyphae_artifact_query` | true | false | true | |
| `hyphae_extract_lessons` | true | false | true | Reads memories and returns formatted analysis; no writes |
| `hyphae_evaluate` | true | false | true | Evaluation is read-only |
| `hyphae_onboard` | false | false | true | Setup; safe to re-run |

---

## Ambiguous Cases and Rationale

### `delete_lines` (rhizome) — destructiveHint: true
While git history provides recovery, `delete_lines` operates directly on the filesystem. An agent in a non-git directory has no recovery path. Marked destructive to match the actual filesystem semantics.

### `hyphae_memory_forget` — destructiveHint: true
Permanently removes a memory from the store. Unlike invalidation (which flags for decay), forget removes the record. No recovery path unless a backup exists.

### `hyphae_forget_source` — destructiveHint: true
Removes a source document from the index. Re-ingestion is possible but requires the original file to still exist.

### `hyphae_memory_invalidate` — destructiveHint: true
Marking memories invalid degrades recall quality in a way that is not directly reversible. The memories persist as invalid records but cease to surface in recall.

### `export_to_hyphae` (rhizome) — readOnlyHint: false
Although the rhizome side is read-only, the tool writes a code graph record into hyphae. The hyphae side is a mutation, so `readOnlyHint` is false.

### `hyphae_session_start` — idempotentHint: false
Each call creates a distinct session record with a new ULID. Calling twice creates two separate sessions — not idempotent.

### `hyphae_memory_embed_all` — readOnlyHint: false, idempotentHint: true
Generates embeddings for memories if not already present. Creates mutable state (embeddings), but re-running with identical configuration produces the same result.

### `create_file` (rhizome) — destructiveHint: false
Creating a new file is not destructive. If the file already exists, behavior may vary (overwrite vs error) — callers should treat this as potentially overwriting an existing file, but git provides recovery.

### `hyphae_memory_store` vs `hyphae_memory_update`
`store` creates new and always produces duplicates on repeat; `update` finds existing by ID and is idempotent for identical content.

### `hyphae_memoir_add_concept` vs `hyphae_memoir_refine`
`add_concept` always appends and is not idempotent; `refine` updates a known concept and is idempotent for the same definition.
