# Merkle Tree Incremental Re-Indexing in Hyphae

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

`hyphae_ingest_file` re-processes entire files on every run, even when content
is unchanged. For large codebases with frequent re-indexing triggers (cortina
fires `hyphae ingest-file` on 3+ doc edits), this wastes significant time and
produces redundant chunk records. Content hashing to skip unchanged files matters
at scale.

## What exists (state)

- **`hyphae_ingest_file`**: ingests a file by splitting into chunks and storing
  each chunk; no content hash check before processing
- **Cortina trigger**: 3+ doc edits trigger `hyphae ingest-file`; can fire
  multiple times per session on active files
- **`hyphae list-sources`**: lists ingested documents; tracks ingest timestamp
  but not content hash
- **Chunking strategies**: `SlidingWindow`, `ByHeading`, `ByFunction`, and (after
  gap #8) `ByAst` — all re-run the full strategy on every ingest call

## What needs doing (intent)

Add a content-hash store to the hyphae document index. On ingest, compute the
SHA-256 of the file content and compare to the stored hash. If unchanged, skip
re-chunking and re-embedding. If changed, re-index only the changed file (not the
whole corpus).

---

### Step 1: Add content hash to document records

**Project:** `hyphae/`
**Effort:** 1 day
**Depends on:** nothing

Add a `content_hash` column to the `documents` table via migration:

```sql
ALTER TABLE documents ADD COLUMN content_hash TEXT;
```

Update `hyphae_ingest_file` to:
1. Compute `SHA-256(file_content)` before any chunking
2. Query `documents` for an existing record with the same `source_path`
3. If `content_hash` matches, return early with "unchanged, skipped"
4. If `content_hash` differs (or no record exists), proceed with re-chunking and
   delete old chunks for this document first
5. Store the new `content_hash` with the updated document record

#### Files to modify

**`hyphae-core/src/db/migrations/`** — add content_hash migration

**`hyphae-core/src/ingest.rs`** — add skip-if-unchanged logic:

```rust
pub struct IngestResult {
    pub skipped: bool,         // true if content hash matched
    pub chunks_added: usize,
    pub chunks_replaced: usize,
}

fn should_skip(conn: &Connection, path: &Path, hash: &str) -> Result<bool>;
fn compute_hash(content: &[u8]) -> String; // SHA-256 hex
```

#### Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `content_hash` column added to documents table via migration
- [ ] Unchanged files skipped on re-ingest
- [ ] Changed files re-indexed with old chunks replaced
- [ ] `IngestResult::skipped` reported in CLI output
- [ ] Build and tests pass

---

### Step 2: Surface skip counts in `hyphae ingest-file` output

**Project:** `hyphae/`
**Effort:** 1–2 hours
**Depends on:** Step 1

Update the CLI output for `hyphae ingest-file` to show skip stats:

```
Ingested: 3 files (2 unchanged, skipped)
  updated:  src/main.rs  (18 chunks)
  skipped:  src/lib.rs   (unchanged)
  skipped:  README.md    (unchanged)
```

Also surface skip counts in the cortina trigger log so operators can see when
cortina triggers are effectively no-ops.

#### Verification

```bash
cd hyphae && hyphae ingest-file . 2>&1
hyphae ingest-file . 2>&1  # second run — should show skipped
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] CLI shows which files were updated vs skipped
- [ ] Second ingest run on unchanged files shows all skipped
- [ ] Cortina trigger log shows skip counts

---

### Step 3: Add `--force` flag to bypass hash check

**Project:** `hyphae/`
**Effort:** 1 hour
**Depends on:** Step 1

Add `hyphae ingest-file --force` that bypasses the content hash check and
re-indexes regardless. Useful when chunking strategy changes (e.g., upgrading
to `ByAst` after rhizome becomes available) and the operator wants to re-index
everything.

#### Verification

```bash
cd hyphae && hyphae ingest-file . --force 2>&1 | head -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `--force` re-indexes all files regardless of content hash
- [ ] `--force` output clearly indicates forced re-index
- [ ] Without `--force`, unchanged files still skipped

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `hyphae/`
3. Running `hyphae ingest-file` twice in a row skips unchanged files on the second run
4. `--force` bypasses the hash check
5. All checklist items are checked

### Final Verification

```bash
cd hyphae && cargo test --workspace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass, no failures.

## Context

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsGap #15 in `docs/workspace/ECOSYSTEM-REVIEW.md`. The performance impact grows
linearly with codebase size and cortina trigger frequency. The fix is a standard
content-addressed store pattern. The `--force` flag is important for cases where
the chunking strategy changes (especially if gap #8, rhizome-backed AST chunking,
ships and operators want to re-index existing files with better chunking).
