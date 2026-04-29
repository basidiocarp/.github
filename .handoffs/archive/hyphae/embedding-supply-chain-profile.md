# Hyphae: Embedding Supply Chain Profile

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/Cargo.toml`, `hyphae/crates/hyphae-cli/Cargo.toml`, `hyphae/crates/hyphae-ingest/Cargo.toml`, `hyphae/README.md`, `hyphae/AGENTS.md`, `hyphae/tests/`, `hyphae/.github/workflows/`
- **Cross-repo edits:** none
- **Non-goals:** no embedding model quality rewrite and no memory schema change
- **Verification contract:** run the commands below and `bash .handoffs/hyphae/verify-embedding-supply-chain-profile.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** workspace features, CLI/ingest default features, install docs, CI feature matrix
- **Reference seams:** `fastembed`, `ort`, `ort-sys`, `spm_precompiled`, no-default-features build path
- **Spawn gate:** do not launch an implementer until the parent agent decides whether embeddings should be opt-in by default or remain default with binary provenance checks

## Problem

Hyphae enables embeddings by default in the CLI and ingest crates. That pulls a native/ML dependency chain through `fastembed`, `ort`, `ort-sys`, `spm_precompiled`, and downloaded/precompiled binary paths. This increases install and release supply-chain risk for users who only need local memory/search without embeddings.

## What needs doing

1. Decide whether embeddings should be opt-in for default release/install profiles.
2. If embeddings remain default, add explicit verification for ORT/precompiled binary provenance and expected artifacts.
3. Add CI coverage for both default and `--no-default-features` builds.
4. Document the dependency and binary-download implications of enabling embeddings.
5. Add cargo tree/audit checks focused on the embedding feature graph.

## Verification

```bash
cd hyphae && cargo tree -i fastembed --locked
cd hyphae && cargo tree -i ort-sys --locked
cd hyphae && cargo build --no-default-features
cd hyphae && cargo test --no-default-features
bash .handoffs/hyphae/verify-embedding-supply-chain-profile.sh
```

**Output:**
<!-- PASTE START -->
==> fastembed dependency graph — ok
==> ort-sys dependency graph — ok
==> no default features build — ok
==> no default features tests — ok (0 failed)
Results: 4 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] default feature profile intentionally includes or excludes embeddings — embeddings remain default; slim build via --no-default-features
- [x] embedding binary/native supply-chain risk is documented — Supply Chain section added to README.md and AGENTS.md
- [x] no-default-features build/test path is covered — verify script + explicit ci-no-embeddings CI job
- [x] ORT/precompiled binary provenance is verified when embeddings are enabled — documented: ort-sys version pinned in Cargo.lock, ORT binary version determined by ort-sys; upgrade guidance in AGENTS.md
- [x] verify script passes with `Results: N passed, 0 failed` — Results: 4 passed, 0 failed

## Context

Created from Phase 6 dependency and supply-chain audit. Severity: high.
