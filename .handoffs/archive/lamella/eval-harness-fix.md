# Lamella: Fix eval harness placeholder snapshots and delta convention

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** lamella/...
- **Cross-repo edits:** none
- **Non-goals:** hook timeout/async fixes (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — Eval harness writes placeholder snapshots that look real
`evals/run_eval.py:48-56`

`simulate_response()` always returns a deterministic placeholder string. The script produces and writes snapshot JSON to `evals/snapshots/` that conforms to the schema and looks like real measurement data, but measures nothing. Committed snapshots in `evals/snapshots/` are all synthetic. Risk: downstream CI or human reviewers treat them as evidence of skill quality.

Fix:
- Add a `--simulate` / `--dry-run` flag that controls whether real or synthetic responses are used.
- When running in simulation mode, either skip writing snapshots or write them to a clearly named `evals/snapshots/synthetic/` subdirectory.
- Delete or move the currently committed synthetic snapshots.
- Update the README to clarify that real evaluation requires a live model and how to invoke it.

### 2 — Delta sign convention inverted
`evals/schema.json:64-66` and `evals/run_eval.py:116`

`primary_delta = skill_response_length - terse_control_length`. For a token-efficiency skill, a shorter response is better, meaning a *negative* delta indicates improvement. But the README describes positive delta as "strong positive effect." The sign convention and the README interpretation are inverted.

Fix: either flip the formula to `terse_control_length - skill_response_length` (positive = improvement) and update the README, or keep the formula and correct the README to say negative delta is the desired direction for token-efficiency skills.

### 3 — print_summary truncation cosmetic bug
`evals/run_eval.py:151`

`result['task'][:60]...` appends `"..."` even when the task string is shorter than 60 characters. Use `result['task'][:60] + ('...' if len(result['task']) > 60 else '')`.

## Implementation Seam

- `evals/run_eval.py` — simulate flag, snapshot write guard, truncation fix
- `evals/schema.json` — delta description update
- `evals/snapshots/` — delete or move synthetic files
- `evals/README.md` — update to clarify simulation vs real evaluation

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/lamella
make validate 2>&1 | tail -5
python3 evals/run_eval.py --help
```

## Checklist

- [x] Simulation mode guard prevents synthetic snapshots from landing in `snapshots/`
- [x] Committed synthetic snapshots deleted or clearly marked (moved to `snapshots/synthetic/`)
- [x] Delta sign convention and README are consistent (positive = improvement)
- [x] Truncation cosmetic fixed
- [x] `make validate` passes
- [x] `make build-marketplace` passes

## Verification Output (2026-04-21)

```
make validate: All validators passed.
make build-marketplace: succeeded (52 plugins, version 0.5.15)
python3 evals/run_eval.py --help: --simulate/--dry-run flag present
--simulate smoke test: wrote to snapshots/synthetic/, simulate:true in output
```
