# Stipe Logging Audit

## Status

`partial`

## Coverage

- `stipe` uses the shared `spore` startup path and the rollout is present at the CLI boundary.
- Release verification already uses shared tracing concepts, so this is not a missing-adoption audit.
- The remaining work is around machine-safe output, tracing depth outside release verification, and subprocess/result correctness.

## Findings

- High: `stipe init --json` is not stdout-pure. It runs the normal human-printing ecosystem setup path before emitting JSON, which breaks structured consumers.
- High: tracing adoption remains shallow outside release verification. Startup is instrumented, but update, doctor, host setup, and registration flows still rely on plain output and boolean results instead of useful `tool_span`, `workflow_span`, or `subprocess_span` boundaries.
- Medium: shared context fields are misused in release verification. `tool` is used for operation names rather than stable tool identity, and `workspace_root` often points at temp or install directories rather than a real workspace root.
- Medium: host setup can report Hyphae DB initialization success without checking the subprocess result.
- Medium: cross-tool registration failures drop child-process diagnostics that operators need to act on the failure.

## Fragile Areas

- `init --json` output purity
- update, doctor, registration, and host-setup boundaries
- misuse of shared context fields
- setup success messages that do not actually verify subprocess success

## Recommendations

- Make `init --json` stdout-pure or move human output to stderr in JSON mode.
- Extend shared tracing beyond release verification into install, update, doctor, host setup, and registration.
- Fix `tool` and `workspace_root` field semantics in release verification spans.
- Preserve subprocess results and child diagnostics before printing success.
