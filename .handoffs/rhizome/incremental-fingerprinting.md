# Rhizome: Incremental Fingerprinting and Change Classification

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** `rhizome/src/` (fingerprint module, change classifier), `rhizome/` (tests)
- **Cross-repo edits:** none (this handoff adds internal rhizome capability; septa contract extension is follow-on)
- **Non-goals:** does not add a CLI surface for querying fingerprints; does not change how rhizome indexes code today; does not build the dashboard UI showing diffs
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by Understand-Anything's incremental analysis model (audit: `.audit/external/audits/Understand-Anything-ecosystem-borrow-audit.md`):

> "Fingerprints intentionally track signatures rather than bodies, and change classification is explicit about SKIP, PARTIAL_UPDATE, ARCHITECTURE_UPDATE, and FULL_UPDATE."
> — `packages/core/src/fingerprint.ts`, `packages/core/src/change-classifier.ts`

## Implementation Seam

- **Likely repo:** `rhizome`
- **Likely files/modules:**
  - `src/fingerprint.rs` (new) — signature-based fingerprint for a file or symbol
  - `src/change_classifier.rs` (new) — classifies a pair of fingerprints as SKIP/PARTIAL/ARCH/FULL
  - `src/store/` or `src/db/` — persist fingerprint snapshots (use existing DB pattern)
  - `src/` entry point — wire fingerprint check into the existing analysis flow
- **Reference seams:**
  - Read rhizome's existing analysis entry point before writing code — identify how re-analysis is triggered today
  - `Understand-Anything/understand-anything-plugin/packages/core/src/fingerprint.ts` — the external reference (do not copy; understand the pattern)
- **Spawn gate:** do a short seam-finding pass to identify the existing analysis trigger point and DB pattern before spawning

## Problem

Rhizome re-analyzes files on every request. For large codebases, this is expensive. Understand-Anything's insight: fingerprint file signatures (exports, imports, function/class names) — not file bodies. If the signature fingerprint has not changed, the analysis result can be reused. If only body content changed (no signature change), only internal edges need updating. Architecture-level changes (new exports, removed functions) need a full re-index.

This is a pure optimization that improves rhizome's throughput without changing any external behavior.

## What needs doing (intent)

Add a fingerprint layer to rhizome:

1. `Fingerprint` — a hash over a file's stable signature: exports, imports, function/class/type names (not bodies)
2. `ChangeClass` enum — four values: `Skip`, `PartialUpdate`, `ArchitectureUpdate`, `FullUpdate`
3. `classify_change(old: &Fingerprint, new: &Fingerprint) -> ChangeClass` — compare old and new fingerprints and return the appropriate class
4. Persist fingerprints in rhizome's existing DB alongside the graph nodes
5. At analysis time: compute the new fingerprint, classify the change, and skip or scope the re-analysis accordingly

## Change Classification Logic

| Old fingerprint | New fingerprint | Change class |
|---|---|---|
| Same hash | Same hash | `Skip` — reuse cached result |
| Same exports/imports | Different body content | `PartialUpdate` — update internal edges only |
| Different exports or imports | Any | `ArchitectureUpdate` — update all edges from this node |
| No prior fingerprint | Any | `FullUpdate` — full analysis required |
| File deleted | — | `FullUpdate` — remove from index |

## Scope

- **Allowed files:** `rhizome/src/fingerprint.rs`, `rhizome/src/change_classifier.rs`, `rhizome/src/` (wiring), relevant test files
- **Explicit non-goals:**
  - No API change — consumers call the same analysis tools; they get faster responses
  - No septa contract yet — fingerprint storage is rhizome-internal for now
  - No dashboard UI for viewing fingerprint diff history

---

### Step 0: Seam-finding pass (do this before implementation)

**Effort:** tiny
**Depends on:** nothing

Before writing code, answer these questions by reading the repo:

1. What triggers re-analysis in rhizome today? (e.g. `analyze_file`, `import_code_graph`, or similar)
2. Does rhizome have a SQLite or other persistent DB? What tables exist?
3. What is the primary data structure for a file/symbol node in the graph?
4. What crates are already in scope (ring/sha2/blake3 for hashing, etc.)?

Document the answers as a brief comment block at the top of `src/fingerprint.rs` before implementing.

---

### Step 1: Define the Fingerprint type

**Project:** `rhizome/`
**Effort:** small
**Depends on:** Step 0 (seam-finding)

Create `src/fingerprint.rs`:

```rust
use std::collections::BTreeSet;

/// A content-independent signature fingerprint for a source file.
/// Hashes exports, imports, and top-level names — not bodies.
/// A matching fingerprint means the file's public interface is unchanged.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Fingerprint {
    /// The file path this fingerprint covers.
    pub path: String,
    /// Stable hash of the signature (exports + imports + top-level names).
    pub signature_hash: String,
    /// Stable hash of the full file content.
    pub content_hash: String,
    /// Exported names at the top level.
    pub exports: BTreeSet<String>,
    /// Imported module paths.
    pub imports: BTreeSet<String>,
}

impl Fingerprint {
    /// True if the public interface (exports + imports) is unchanged.
    pub fn signature_matches(&self, other: &Fingerprint) -> bool {
        self.signature_hash == other.signature_hash
    }

    /// True if the full file content is unchanged.
    pub fn content_matches(&self, other: &Fingerprint) -> bool {
        self.content_hash == other.content_hash
    }
}
```

Use whatever hashing crate is already in scope in rhizome (check `Cargo.toml`). If none, add `blake3` — it is fast and does not require `unsafe`.

#### Verification

```bash
cd rhizome && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] Type compiles
- [ ] Uses an existing hashing crate from `Cargo.toml` or adds `blake3`

---

### Step 2: Define ChangeClass and the classifier

**Project:** `rhizome/`
**Effort:** small
**Depends on:** Step 1

Create `src/change_classifier.rs`:

```rust
use crate::fingerprint::Fingerprint;

/// Describes how much re-analysis a changed file requires.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChangeClass {
    /// No change detected — reuse cached analysis result.
    Skip,
    /// Body content changed but public interface is the same.
    /// Update internal edges only; do not re-export or update callers.
    PartialUpdate,
    /// Exports or imports changed.
    /// Re-analyze this node and update all edges from it.
    ArchitectureUpdate,
    /// No prior fingerprint exists or file was deleted.
    /// Full analysis required.
    FullUpdate,
}

/// Classify the change between an old and new fingerprint.
/// Pass `None` for `old` when no prior fingerprint exists.
pub fn classify_change(old: Option<&Fingerprint>, new: &Fingerprint) -> ChangeClass {
    let Some(old) = old else {
        return ChangeClass::FullUpdate;
    };
    if old.content_matches(new) {
        return ChangeClass::Skip;
    }
    if old.signature_matches(new) {
        return ChangeClass::PartialUpdate;
    }
    ChangeClass::ArchitectureUpdate
}
```

#### Verification

```bash
cd rhizome && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `ChangeClass` and `classify_change` compile
- [ ] Logic matches the table above

---

### Step 3: Persist fingerprints

**Project:** `rhizome/`
**Effort:** small
**Depends on:** Step 2 and Step 0 (DB pattern identified)

Add fingerprint storage to rhizome's existing persistence layer. If rhizome uses SQLite, add a `fingerprints` table:

```sql
CREATE TABLE IF NOT EXISTS fingerprints (
    path            TEXT PRIMARY KEY,
    signature_hash  TEXT NOT NULL,
    content_hash    TEXT NOT NULL,
    exports_json    TEXT NOT NULL,  -- JSON array of export names
    imports_json    TEXT NOT NULL,  -- JSON array of import paths
    indexed_at      INTEGER NOT NULL
);
```

Add `store_fingerprint(fp: &Fingerprint)` and `load_fingerprint(path: &str) -> Option<Fingerprint>` functions following rhizome's existing DB module pattern.

#### Verification

```bash
cd rhizome && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] Fingerprint persistence compiles and integrates with existing DB

---

### Step 4: Wire into the analysis flow

**Project:** `rhizome/`
**Effort:** medium
**Depends on:** Step 3

At the existing analysis entry point (identified in Step 0), add the fingerprint check:

```rust
// 1. Compute the new fingerprint from the file.
let new_fp = compute_fingerprint(&file_path, &parsed_ast)?;

// 2. Load the prior fingerprint if it exists.
let old_fp = db.load_fingerprint(&file_path);

// 3. Classify the change.
let change = classify_change(old_fp.as_ref(), &new_fp);

// 4. Apply the appropriate analysis scope.
match change {
    ChangeClass::Skip => {
        tracing::debug!(path = %file_path, "fingerprint match — skipping re-analysis");
        return Ok(());
    }
    ChangeClass::PartialUpdate => {
        // update internal edges only
        update_internal_edges(&file_path, &parsed_ast, &db)?;
    }
    ChangeClass::ArchitectureUpdate | ChangeClass::FullUpdate => {
        // full re-analysis
        full_reindex(&file_path, &parsed_ast, &db)?;
    }
}

// 5. Store the new fingerprint.
db.store_fingerprint(&new_fp)?;
```

Add a `compute_fingerprint(path, ast) -> StoreResult<Fingerprint>` function that extracts exports and imports from the AST and hashes them.

#### Verification

```bash
cd rhizome && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] Analysis flow consults fingerprint before re-analysis
- [ ] Skip path returns early correctly
- [ ] New fingerprint stored after analysis

---

### Step 5: Add unit tests

**Project:** `rhizome/`
**Effort:** small
**Depends on:** Step 4

Test the classifier in `src/change_classifier.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use crate::fingerprint::Fingerprint;
    use std::collections::BTreeSet;

    fn fp(sig: &str, content: &str) -> Fingerprint {
        Fingerprint {
            path: "test.ts".into(),
            signature_hash: sig.into(),
            content_hash: content.into(),
            exports: BTreeSet::new(),
            imports: BTreeSet::new(),
        }
    }

    #[test] fn no_prior_is_full_update() {
        assert_eq!(classify_change(None, &fp("s1", "c1")), ChangeClass::FullUpdate);
    }
    #[test] fn identical_is_skip() {
        let f = fp("s1", "c1");
        assert_eq!(classify_change(Some(&f), &fp("s1", "c1")), ChangeClass::Skip);
    }
    #[test] fn same_signature_different_content_is_partial() {
        assert_eq!(classify_change(Some(&fp("s1", "c1")), &fp("s1", "c2")), ChangeClass::PartialUpdate);
    }
    #[test] fn different_signature_is_arch_update() {
        assert_eq!(classify_change(Some(&fp("s1", "c1")), &fp("s2", "c2")), ChangeClass::ArchitectureUpdate);
    }
}
```

#### Verification

```bash
cd rhizome && cargo test change_classifier 2>&1
cd rhizome && cargo test fingerprint 2>&1
```

**Checklist:**
- [ ] All 4 classifier tests pass
- [ ] No test panics or compilation errors

---

### Step 6: Full suite

```bash
cd rhizome && cargo test 2>&1 | tail -20
cd rhizome && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd rhizome && cargo fmt --check 2>&1
```

**Checklist:**
- [ ] All tests pass
- [ ] Clippy clean
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The full test suite passes
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated to reflect completion

## Follow-on work (not in scope here)

- `septa/fingerprint-v1.schema.json` — if fingerprints need to move between repos
- `mycelium` — surface "N files skipped (fingerprint match)" in analysis output
- `cap` — show fingerprint-based cache hit rate in operator view

## Context

Spawned from the Understand-Anything Wave 1 re-audit (2026-04-23). The key pattern is signature-only fingerprinting: hash exports, imports, and top-level names — not bodies. This means a formatting-only change does not trigger a full re-index, and a new export correctly triggers an architecture update. The four-class taxonomy (Skip, PartialUpdate, ArchitectureUpdate, FullUpdate) maps precisely to the four work amounts rhizome needs to do.
