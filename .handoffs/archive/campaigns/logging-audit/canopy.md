# Canopy Logging Audit

## Status

`partial`

## Coverage

- `canopy` initializes through the shared `spore` logging path and has shared span usage across app startup, runtime, and MCP surfaces.
- The rollout is structurally present: `root_span`, request-oriented boundaries, and shared field names are in code.
- The main gap is that the current `init_app("canopy", WARN)` setup plus non-emitting span defaults means much of that boundary structure is invisible in normal operator runs.

## Findings

- High: shared boundary spans are mostly non-emitting at default runtime settings. `canopy` uses `init_app("canopy", WARN)`, and the default `spore` span lifecycle settings keep most entered spans silent unless explicit events are emitted.
- Medium: verification, completeness checks, and polling/retry loops are still under-instrumented. Those long-running and failure-prone paths do not consistently use `tool_span`, `workflow_span`, or `subprocess_span`.
- Medium: some MCP import diagnostics still use raw `eprintln!`, so docs overstate how much stderr behavior is controlled by `CANOPY_LOG`.
- Medium: CLI `workspace_root` context is inconsistent outside the serve path because top-level spans use the launch cwd even when command inputs point at another project root.

## Fragile Areas

- verification subprocesses
- completeness checks and polling loops
- MCP import warnings
- CLI paths where `workspace_root` should come from command input rather than cwd

## Recommendations

- Make boundary spans visible under normal operator settings, either through lifecycle events or explicit trace events.
- Add shared span helpers around verification, completeness, and polling/retry work.
- Replace MCP-path `eprintln!` warnings with tracing events.
- Derive `workspace_root` from explicit command inputs when available.
