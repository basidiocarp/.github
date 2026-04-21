# Volva Logging Audit

## Status

`addressed`

## Coverage

- `volva` uses the shared `spore` startup path with lifecycle span events enabled at the CLI boundary.
- Backend and hook-adapter spans still carry the existing structured fields such as `tool` and `workspace_root`.
- The original audit gaps in API retry behavior and auth/callback failure locality were addressed in `v0.1.1`.

## Findings

- Resolved: the API retry and backoff path now emits shared tracing events instead of raw `eprintln!` notices, with request-local context attached when Anthropic returns a request id.
- Resolved: the auth and callback flow now adds local tracing boundaries for session start, browser launch, callback wait, token exchange, and API-key minting instead of relying only on the top-level CLI span.
- Resolved: Volva now creates a per-invocation correlation id for auth and API flows and threads it through shared span context as `session_id`, while upstream `request_id` values are attached when they become available.

## Fragile Areas

- Anthropic-specific retry and rate-limit handling still depends on upstream header behavior for the best request-local detail.
- Auth callback wait and parse remains an inherently failure-prone boundary, but it is now instrumented rather than silent.
- Token exchange and API-key minting remain provider-owned network edges and should stay under regression watch when Anthropic changes auth behavior.

## Recommendations

- Keep new auth and API tracing boundaries stable unless the shared `spore` contract changes.
- If future debugging still needs more granularity, prefer attaching real upstream ids over inventing additional synthetic fields.
- Treat this repo's original audit findings as closed by `volva v0.1.1`.
