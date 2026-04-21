# Cortina: Canopy Evidence Causal Chaining

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/...`
- **Cross-repo edits:** `none`
- **Non-goals:** writing new canopy evidence refs or adding canopy review UI/CLI
- **Verification contract:** run the repo-local commands below and `bash .handoffs/archive/cortina/verify-canopy-evidence-causal-chaining.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Problem

`cortina` emits outcome signals and outcome events, but it does not persist a
causal link between related signals. That prevents later bridge code from saying
which earlier error a resolution closed or which write a correction refers to.

## What exists (state)

- **Outcome events:** [outcome_events.rs](../../cortina/src/events/outcome_events.rs) already carries event identity plus optional `signal_type`.
- **Signal emission:** [outcomes.rs](../../cortina/src/outcomes.rs) and the hook handlers under [hooks/](../../cortina/src/hooks/) already produce the relevant events.
- **Canopy bridge:** [canopy_client.rs](../../cortina/src/utils/canopy_client.rs) already writes evidence for existing outcome events, so this handoff only needs to enrich the event shape.

## What needs doing (intent)

Add causal attribution metadata to the Cortina signal pipeline so later evidence
bridge work can emit `caused_by` links without guessing after the fact.

## Scope

- **Primary seam:** Cortina outcome-event capture and short causal lookup
- **Allowed files:** `cortina/src/events/...`, `cortina/src/outcomes.rs`, `cortina/src/hooks/...`, tests
- **Explicit non-goals:**
- Do not change `canopy` in this handoff.
- Do not widen the evidence-writing surface beyond what is needed to persist causal metadata.

## Files To Modify

- `cortina/src/events/outcome_events.rs`
- `cortina/src/outcomes.rs`
- `cortina/src/hooks/post_tool_use/*.rs`
- `cortina/src/hooks/stop.rs`
- tests as needed

## Verification

```bash
cd cortina && cargo test --workspace 2>&1 | tail -10
bash .handoffs/archive/cortina/verify-canopy-evidence-causal-chaining.sh
```

## Checklist

- [x] outcome events can persist causal attribution for follow-on signals
- [x] resolution signals can point at a prior relevant error signal
- [x] correction signals can point at a prior relevant write signal
- [x] tests cover the new causal matching behavior

## Verification Evidence

```text
test utils::tests::session_identity_for_cwd_falls_back_to_canonical_path_identity ... ok
test utils::tests::session_identity_for_cwd_uses_canonical_cwd_and_git_dir ... ok
test utils::tests::session_outcome_feedback_classifies_failure_keywords ... ok
test utils::tests::successful_validation_feedback_prefers_test_commands ... ok
test utils::tests::temp_state_path_uses_system_temp_dir ... ok
test utils::tests::update_json_file_recovers_stale_lock ... ok
test utils::tests::update_json_file_serializes_concurrent_mutations ... ok

test result: ok. 170 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 128.84s
```

```text
PASS: outcome event file exists
PASS: cortina causal attribution seam exists
PASS: cortina workspace tests pass
Results: 3 passed, 0 failed
```

## Context

Child 1 of [Canopy Evidence Bridge — Attribution Completeness](../../cross-project/canopy-evidence-attribution.md).
