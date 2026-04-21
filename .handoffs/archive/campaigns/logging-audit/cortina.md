# Cortina Logging Audit

## Status

`partial`

## Coverage

- `cortina` is on the shared `spore` logging contract and already uses repo-specific logging setup instead of a bespoke local logger.
- Hook and adapter work is instrumented enough to show rollout adoption, including shared span vocabulary and stderr-safe logging on the main CLI path.
- The remaining problems are around durability, adapter-boundary depth, and diagnostics that still bypass tracing.

## Findings

- High: the Canopy evidence attachment path is not durable enough at process exit. It depends on detached retry threads from a one-shot CLI, so evidence writes can be cut off before completion.
- Medium: adapter and rewrite subprocess boundaries are thinner than the shared contract expects. Parsed hook `session_id` is not threaded deeply enough, and `mycelium rewrite` lacks its own strong boundary instrumentation.
- Medium: several subprocess wrappers still black-hole child stderr, which removes actionable failure diagnostics.
- Low: README wording overstates how much diagnostics actually flow through `CORTINA_LOG`, because some warnings still use raw `eprintln!`.

## Fragile Areas

- evidence bridge durability at process exit
- adapter and rewrite subprocess boundaries
- child stderr handling in wrappers
- README claims about `CORTINA_LOG` coverage

## Recommendations

- Make evidence attachment durable rather than relying on detached retry threads from a short-lived CLI.
- Add explicit tracing around adapter and rewrite subprocess boundaries, including stable `session_id` propagation.
- Preserve child stderr on failure paths.
- Either route warnings through tracing or narrow the README claims so docs match runtime behavior.
