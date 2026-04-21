# Cortina: Canopy Evidence Signal Bridge

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/...`
- **Cross-repo edits:** `none`
- **Non-goals:** changing canopy storage or operator rendering
- **Verification contract:** run the repo-local commands below and `bash .handoffs/archive/cortina/verify-canopy-evidence-signal-bridge.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Problem

The existing evidence bridge writes only a shallow subset of Cortina outcomes into
Canopy. Richer outcome types should attach as evidence refs so the task timeline
is populated continuously, not just at stop/session-end boundaries.

## What exists (state)

- **Evidence writing:** [canopy_client.rs](../../cortina/src/utils/canopy_client.rs) already issues `canopy evidence add`.
- **Outcome events:** `cortina` already has typed outcome events and, after child `64a`, causal metadata should be available.

## What needs doing (intent)

Extend the Cortina evidence bridge so additional signal types emit evidence refs,
including any available `caused_by` relationship from the causal chaining step.

## Scope

- **Primary seam:** Cortina -> Canopy evidence writing
- **Allowed files:** `cortina/src/utils/canopy_client.rs`, `cortina/src/outcomes.rs`, tests
- **Explicit non-goals:**
- Do not add new canopy CLI output in this handoff.
- Do not redesign the `septa` evidence schema unless a concrete contract gap is discovered.

## Files To Modify

- `cortina/src/utils/canopy_client.rs`
- `cortina/src/outcomes.rs`
- tests as needed

## Verification

```bash
cd cortina && cargo test --workspace 2>&1 | tail -10
bash .handoffs/archive/cortina/verify-canopy-evidence-signal-bridge.sh
```

## Checklist

- [x] additional signal types emit evidence refs through the bridge
- [x] evidence payload carries causal attribution when available
- [x] best-effort behavior remains intact when canopy is unavailable
- [x] tests cover the widened evidence-writing surface

## Verification Evidence

```text
test utils::tests::session_identity_for_cwd_falls_back_to_canonical_path_identity ... ok
test utils::tests::session_identity_for_cwd_uses_canonical_cwd_and_git_dir ... ok
test utils::tests::session_outcome_feedback_classifies_failure_keywords ... ok
test utils::tests::successful_validation_feedback_prefers_test_commands ... ok
test utils::tests::temp_state_path_uses_system_temp_dir ... ok
test utils::tests::update_json_file_recovers_stale_lock ... ok
test utils::tests::update_json_file_serializes_concurrent_mutations ... ok

test result: ok. 173 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 128.38s
```

```text
PASS: canopy bridge file exists
PASS: bridge references evidence payload metadata
PASS: cortina workspace tests pass
Results: 3 passed, 0 failed
```

## Context

Child 2 of [Canopy Evidence Bridge — Attribution Completeness](../../cross-project/canopy-evidence-attribution.md). Depends on child `64a`.
