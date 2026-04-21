# Rhizome Logging Audit

## Status

`partial`

## Coverage

- `rhizome` initializes through `spore::logging::init_app("rhizome", WARN)`, so the shared `spore` contract is present at startup and the runtime knob is `RHIZOME_LOG`.
- The serve path enters shared root and request boundaries, so MCP and LSP-adjacent work is not starting from a raw `env_logger`-style baseline anymore.
- The repo is already using shared span concepts such as `root_span` and request-scoped tracing fields; this is an adoption review, not a missing-rollout review.

## Findings

- Medium: doc/runtime drift remains around the repo-specific log knob. Runtime uses `spore::logging::init_app("rhizome", WARN)` in `rhizome/crates/rhizome-cli/src/main.rs`, but docs still describe `RUST_LOG` with an `info` default instead of `RHIZOME_LOG` with an effective `warn` default.
- Medium: important subprocess and background boundaries are still under-instrumented. LSP startup, installer paths, and export/probe subprocesses do not consistently wrap work in `subprocess_span`, so failures lose local tracing boundaries.
- Low: non-serve CLI flows still do not consistently enter a root span. Direct commands such as install or setup paths can run without the same `workspace_root` and lifecycle coverage that the serve loop gets.

## Fragile Areas

- LSP server startup and long-running reader tasks
- installer and export subprocess execution
- direct CLI flows outside `serve`
- docs that still describe `RUST_LOG` instead of `RHIZOME_LOG`

## Recommendations

- Align docs with the shipped `spore` init path and document `RHIZOME_LOG` as the primary knob.
- Add `subprocess_span` coverage around LSP, installer, and export boundaries.
- Ensure non-serve CLI entrypoints also enter a shared `root_span` with stable `workspace_root` context.
