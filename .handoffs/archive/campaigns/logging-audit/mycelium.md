# Mycelium Logging Audit

## Status

`partial`

## Coverage

- `mycelium` uses the shared `spore` startup path and already documents its repo-specific log knob, so the initial rollout landed.
- Startup and some Hyphae-related chunking paths are instrumented, which means shared tracing is present in the codebase and not just declared in docs.
- The audit focus is on correctness and depth: subprocess diagnostics, plugin execution, tracking, and onboarding are not yet covered consistently by `tool_span` or `workflow_span`.

## Findings

- High: the plugin fallback path can hide real command failures and can execute side-effecting commands twice. That is both a control-flow problem and a tracing problem because raw status and stderr are dropped on fallback paths.
- Medium: shared `spore` tracing adoption is only partial. Plugin execution, Rhizome client work, onboarding, tracking writes, and execution hot spots are not consistently instrumented with `tool_span`, `workflow_span`, or `subprocess_span`.
- Medium: some subprocess boundaries discard child stderr entirely, which keeps stdout safe but removes the diagnostics operators need when a failure happens.
- Low: plugin documentation is stale versus the current ownership-check implementation.

## Fragile Areas

- plugin fallback and subprocess execution
- onboarding and tracking write paths
- Rhizome and Hyphae integration boundaries
- docs around plugin ownership and runtime behavior

## Recommendations

- Fix plugin fallback correctness first so failures preserve raw status and stderr and do not run side-effecting commands twice.
- Extend shared `spore` tracing across plugin, onboarding, tracking, and client hot spots.
- Capture child stderr on failure while preserving stdout safety.
- Reconcile plugin docs with the current ownership and execution model.
