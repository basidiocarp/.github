# Rhizome Orchestration Export Status Contract

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

`rhizome` now exports richer repo-understanding artifacts, but the current `update_class` field is still too coarse for orchestration. It works as a display label, but it does not let downstream agents distinguish full success from partial success, cached reuse, or degraded exports with failures.

If multiple agents start consuming `rhizome` understanding exports, using `update_class` as the machine-facing trust signal will create false confidence around partial or stale results.

## What exists (state)

- **`repo_understanding.rs`:** exposes `UnderstandingUpdateClass` with `fresh`, `incremental`, `unchanged`, and `failed`
- **`export_tools.rs`:** exports repo-understanding artifacts through MCP and CLI surfaces
- **Current semantics:** mixed outcomes collapse into a success-ish label instead of a precise machine contract
- **Archived precursor:** richer analyzer and incremental understanding work is complete under [archive/rhizome/richer-analyzer-plugins-and-incremental-understanding.md](../archive/rhizome/richer-analyzer-plugins-and-incremental-understanding.md)

## What needs doing (intent)

Add a machine-facing export status contract for repo-understanding artifacts. Keep `update_class` only as a human-facing summary label, and introduce explicit orchestration-safe status data for downstream consumers.

The follow-up should make it possible for multiple agents or tools to answer:

- did any export work succeed
- did any export work fail
- was this a full refresh, partial refresh, or cached reuse
- is the artifact safe to consume automatically

---

### Step 1: Add a machine-facing export status model

**Project:** `rhizome/`
**Effort:** 2-3 hours
**Depends on:** archived richer-analyzer handoff

Introduce a typed status surface alongside the existing display-oriented `update_class`. Prefer explicit fields or a richer status enum over overloading the display label.

The resulting artifact should expose enough information for orchestration to distinguish:

- complete success
- partial success
- cached reuse / no-op reuse
- full failure

#### Files to modify

**`rhizome/crates/rhizome-core/src/repo_understanding.rs`** — add a machine-facing status type and derived logic from export stats.

**`rhizome/crates/rhizome-core/src/project_summary.rs`** — include the new status data in exported understanding artifacts if needed.

#### Verification

```bash
cd rhizome && cargo test repo_understanding -- --nocapture
```

**Output:**
<!-- PASTE START -->
Finished `test` profile [optimized + debuginfo] target(s) in 8.82s
running 4 tests
test repo_understanding::tests::export_status_distinguishes_complete_partial_cached_and_failed_runs ... ok
test repo_understanding::tests::classifies_docs_and_build_surfaces ... ok
test repo_understanding::tests::update_class_tracks_incremental_and_failed_exports ... ok
test repo_understanding::tests::repo_surface_summary_records_samples ... ok
test result: ok. 4 passed; 0 failed; 0 ignored; 0 measured; 98 filtered out; finished in 0.00s
<!-- PASTE END -->

**Checklist:**
- [x] machine-facing status distinguishes complete, partial, cached, failed, and no-supported-files outcomes
- [x] `update_class` is no longer the only trust signal for exports
- [x] tests cover at least one mixed success/failure case

---

### Step 2: Use the machine status in export surfaces

**Project:** `rhizome/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Update CLI and MCP export paths so downstream consumers receive the machine-facing status contract directly. Keep the display label if useful, but make the machine fields first-class.

#### Files to modify

**`rhizome/crates/rhizome-mcp/src/tools/export_tools.rs`** — include the machine-facing status in exported output.

**`rhizome/crates/rhizome-cli/src/main.rs`** — ensure the CLI export path emits the same contract.

**`rhizome/crates/rhizome-mcp/tests/`** — add or update integration coverage for the new status shape.

#### Verification

```bash
cd rhizome && cargo test --workspace
```

**Output:**
<!-- PASTE START -->
running 20 tests
test tests::format_understanding_output_preserves_machine_status_in_json_mode ... ok
test result: ok. 20 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.21s

running 102 tests
test repo_understanding::tests::export_status_distinguishes_complete_partial_cached_and_failed_runs ... ok
test result: ok. 102 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.19s

running 29 tests
test tools::export_tools::tests::understanding_export_distinguishes_cached_reuse_from_no_supported_files ... ok
test result: ok. 29 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s

running 55 tests
test test_export_repo_understanding_exposes_machine_status_contract ... ok
test result: ok. 54 passed; 0 failed; 1 ignored; 0 measured; 0 filtered out; finished in 0.08s
<!-- PASTE END -->

**Checklist:**
- [x] CLI and MCP export surfaces expose the same machine-facing status
- [x] partial-failure exports are represented as degraded rather than fully successful
- [x] workspace tests pass

---

### Step 3: Document orchestration semantics

**Project:** `rhizome/`
**Effort:** 1-2 hours
**Depends on:** Steps 1-2

Document how downstream agents should interpret the new status contract. Make clear which fields are human-facing summaries and which are intended for automated decision-making.

#### Files to modify

**`rhizome/README.md`** or adjacent docs — document the export-status contract.

**`rhizome` MCP or onboarding docs** — mention the orchestration-safe status semantics where appropriate.

#### Verification

```bash
cd rhizome && cargo build --workspace
bash .handoffs/archive/rhizome/verify-orchestration-export-status-contract.sh
```

**Output:**
<!-- PASTE START -->
Finished `dev` profile [optimized + debuginfo] target(s) in 0.48s
PASS: Handoff defines machine-facing export status intent
PASS: Handoff includes repo_understanding step
PASS: Handoff includes export surface step
PASS: Handoff includes orchestration semantics docs step
Results: 4 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] docs distinguish machine-facing status from display-only labels
- [x] orchestration guidance says partial exports are degraded inputs
- [x] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/rhizome/verify-orchestration-export-status-contract.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/rhizome/verify-orchestration-export-status-contract.sh
```

**Output:**
<!-- PASTE START -->
PASS: Handoff defines machine-facing export status intent
PASS: Handoff includes repo_understanding step
PASS: Handoff includes export surface step
PASS: Handoff includes orchestration semantics docs step
Results: 4 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

- follow-up to [archive/rhizome/richer-analyzer-plugins-and-incremental-understanding.md](../archive/rhizome/richer-analyzer-plugins-and-incremental-understanding.md)
- motivated by orchestration use where multiple agents may consume `rhizome` exports as bounded repo-understanding inputs
