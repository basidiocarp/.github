# Rhizome Structural Fallback for Large/Unsupported Files

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** rhizome/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `rhizome`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `rhizome` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

When both tree-sitter and LSP backends fail — for large files, unsupported
languages, or binary-adjacent formats — rhizome errors and agents fall back to
raw file reads. A parserless outline mode using indentation, bracket depth, and
entropy heuristics would keep rhizome useful as a navigation layer even when real
parsing is impossible. This is the strongest directly applicable idea from the
external tools audit.

## What exists (state)

- **`BackendSelector`**: picks between tree-sitter and LSP per tool call; no
  third fallback path exists
- **Tree-sitter**: 18 languages; fails on unsupported languages and malformed files
- **LSP**: 32 languages; can time out or fail on very large files
- **Current behavior**: when both fail, rhizome returns an error and agents read
  the whole file via Read tool
- **Region IDs**: rhizome uses stable region IDs in some contexts; the fallback
  needs its own stable ID scheme

## What needs doing (intent)

Add a `HeuristicBackend` as a new fallback tier in `BackendSelector`. It produces
a structural outline using indentation depth and bracket counting, assigns stable
region IDs based on line numbers and content hashes, and supports `get_structure`,
`get_region`, and `summarize_file` with degraded but useful output.

---

### Step 1: Implement HeuristicBackend

**Project:** `rhizome/`
**Effort:** 2–3 days
**Depends on:** nothing

Create `rhizome-core/src/backends/heuristic.rs`. The backend:

1. Reads the file line by line (streaming, no full load into memory for files >2 MB)
2. Computes indentation depth per line (tabs = 4 spaces equivalent)
3. Tracks bracket depth: `{`, `[`, `(` increase depth; closing brackets decrease
4. Identifies "section boundaries" where indentation resets to 0 or bracket depth
   returns to baseline
5. Assigns stable region IDs: `h-{sha256_of_first_line_of_region}-{line_number}`
6. Produces a `StructureOutline` with regions, depth, and estimated line ranges

The outline format must be compatible with the existing `get_structure` response
schema so no new MCP tool surface is needed.

#### Files to modify

**`rhizome-core/src/backends/heuristic.rs`** — new file:

```rust
pub struct HeuristicBackend;

impl HeuristicBackend {
    pub fn outline(path: &Path) -> Result<StructureOutline>;
    pub fn get_region(path: &Path, region_id: &str) -> Result<FileRegion>;
}

pub struct StructureOutline {
    pub regions: Vec<HeuristicRegion>,
    pub backend: BackendLabel, // BackendLabel::Heuristic
}

pub struct HeuristicRegion {
    pub id: String,       // "h-{hash}-{line}"
    pub label: String,    // first non-blank content of the region
    pub start_line: u32,
    pub end_line: u32,
    pub depth: u32,
}
```

**`rhizome-core/src/backends/selector.rs`** — add heuristic fallback tier:

```rust
BackendResult::Err(_) if self.heuristic_enabled => {
    HeuristicBackend::outline(path).map(BackendResult::Heuristic)
}
```

#### Verification

```bash
cd rhizome && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `HeuristicBackend::outline` handles files of any language/size
- [ ] Region IDs are stable across repeated calls on unchanged files
- [ ] `BackendSelector` falls back to heuristic after tree-sitter and LSP both fail
- [ ] Outline is compatible with existing `get_structure` response schema
- [ ] Build and tests pass

---

### Step 2: Add expand-region workflow

**Project:** `rhizome/`
**Effort:** 4–8 hours
**Depends on:** Step 1

Implement `get_region` for the `HeuristicBackend`: given a `region_id`, return the
raw file content for that line range. This enables the expand-region workflow where
the agent can request just the section they need instead of reading the whole file.

Also add a `--backend heuristic` flag to `rhizome summarize-file` for operators
to force heuristic mode explicitly during debugging.

#### Verification

```bash
cd rhizome && cargo test --workspace -- --test-output immediate 2>&1 | grep -E "(heuristic|FAILED|ok)" | tail -15
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `get_region` returns correct line range for heuristic region IDs
- [ ] `rhizome summarize-file --backend heuristic` works on an unsupported file type
- [ ] Region IDs are stable when file content is unchanged
- [ ] Tests cover a file >1000 lines

---

### Step 3: Surface heuristic backend in rhizome doctor

**Project:** `rhizome/`
**Effort:** 1–2 hours
**Depends on:** Step 1

Add a note to `rhizome doctor` output: "heuristic fallback enabled — files with
no tree-sitter or LSP support will use indentation-based outline." This makes the
fallback visible to operators rather than silently activating.

#### Verification

```bash
cd rhizome && cargo build --workspace 2>&1 | tail -3
rhizome doctor 2>&1 | grep -i heuristic
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `rhizome doctor` mentions heuristic fallback status
- [ ] Doctor shows whether heuristic is enabled and what triggers it

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `rhizome/`
3. A file in an unsupported language returns a structural outline instead of an error
4. `get_region` returns the correct content for a heuristic region ID
5. All checklist items are checked

### Final Verification

```bash
cd rhizome && cargo test --workspace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass, no failures.

## Context

## Implementation Seam

- **Likely repo:** `rhizome`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `rhizome` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsGap #7 in `docs/workspace/ECOSYSTEM-REVIEW.md`. Identified as the strongest
directly applicable idea from the external tools audit. The heuristic backend is
explicitly scoped as a new tier in `BackendSelector` — not a rewrite of existing
backends. It degrades gracefully: tree-sitter is tried first, LSP second, heuristic
last. The region ID scheme must be stable so agents can cache region references
across sessions without re-parsing the outline every time.
