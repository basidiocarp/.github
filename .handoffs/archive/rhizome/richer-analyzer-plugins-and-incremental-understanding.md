# Rhizome Richer Analyzer Plugins And Incremental Understanding

## Concrete contract

This handoff is implemented in `rhizome` as a bounded understanding layer, not as a new downstream `hyphae` schema.

Implemented pieces:

- `rhizome/crates/rhizome-core/src/repo_understanding.rs`
  - `RepoSurfaceKind`
  - `RepoSurfaceNode`
  - `RepoSurfaceSummary`
  - `UnderstandingUpdateClass`
  - `RepoUnderstandingArtifact`
  - `classify_repo_surface(...)`
- `rhizome/crates/rhizome-core/src/project_summary.rs`
  - `ProjectSummary` now includes `repo_surfaces`
  - project summary output shows repo-surface counts and samples
- `rhizome/crates/rhizome-mcp/src/tools/export_tools.rs`
  - `export_to_hyphae` now reports an explicit update class
  - new `export_repo_understanding` tool returns a typed repo-understanding artifact
  - understanding export advances the scoped export cache so repeat runs are incremental
- `rhizome/crates/rhizome-cli/src/main.rs`
  - `rhizome export-understanding` prints the new understanding artifact
- `rhizome/crates/rhizome-mcp/src/tools/mod.rs`
  - new tool dispatch for `export_repo_understanding`
- `rhizome/crates/rhizome-mcp/src/server.rs`
  - server instructions and tool listing mention the new export surface
- `rhizome/crates/rhizome-mcp/src/tools/symbol_tools/onboard.rs`
  - onboarding text now advertises the understanding export path

## What this covers

- richer analyzer/plugin surface: typed repo-surface classification alongside code summary
- incremental update semantics: explicit `fresh`, `incremental`, `unchanged`, `failed` update classes
- broader understanding export: a structured artifact that includes `ProjectSummary` plus repo-surface data

## Deferred

- A new `hyphae` consumer-side schema or storage path is deferred.
- The current `hyphae` export path remains the code-graph path.
- This handoff intentionally does not pretend that the downstream consumer rewrite was completed.

## Validation

Validated in `rhizome`:

- `cargo build --workspace`
- `cargo test --workspace`
- `bash .handoffs/archive/rhizome/verify-richer-analyzer-plugins-and-incremental-understanding.sh`
