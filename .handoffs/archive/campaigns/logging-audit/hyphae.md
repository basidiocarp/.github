# Hyphae Logging Audit

## Status

`partial`

## Coverage

- `hyphae` has adopted the shared `spore` init path and uses the repo-specific logger setup rather than an unrelated local logging stack.
- MCP dispatch is instrumented enough to show that the rollout landed structurally; this is now a depth and correctness audit around `request_span`, `workflow_span`, and stable context propagation.
- The repo keeps stdout/stderr discipline for MCP surfaces, so this is not blocked on basic transport safety.

## Findings

- High: request-local identity is not threaded deeply enough into tracing. At useful failure points, `session_id` and accurate `workspace_root` context are often absent or misleading, which weakens the value of the shared `spore` contract.
- Medium: instrumentation stops too early in the MCP stack. The dispatcher is instrumented, but heavy write and workflow paths do not consistently add `workflow_span` or `subprocess_span` boundaries where failure locality matters.
- Medium: CLI long-running and subprocess-heavy paths remain under-instrumented, so non-MCP work still drops boundary coverage.
- Low: docs are stale around serve/runtime details, stderr behavior, and current tool surface shape.

## Fragile Areas

- request context propagation below the MCP dispatcher
- memory and write-heavy workflow paths
- subprocess and long-running CLI boundaries
- docs that do not match current logging and tool behavior

## Recommendations

- Thread stable request-local fields such as `session_id`, `request_id`, and correct `workspace_root` through the deeper write and workflow layers.
- Extend `workflow_span` and `subprocess_span` coverage beyond the dispatcher into the heavy MCP bodies.
- Add CLI boundary spans for long-running and subprocess surfaces.
- Reconcile docs with the actual stderr-only logging and current runtime/tool behavior.
