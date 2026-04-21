# Cortina Memory Protocol Session Start

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** cortina/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** `cortina/src/utils/session_scope.rs`, `cortina/src/status.rs`, `cortina/src/utils/tests.rs`
- **Reference seams:** reuse the existing scoped Hyphae session-start flow and `cortina status` surface instead of creating a new command or storage path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Depends on

- [protocol-surface.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/hyphae/protocol-surface.md)

## What needs doing

Make the protocol available at Cortina session start in the narrowest way that
supports downstream exposure without changing Cortina's core signal-capture role.

## Verification

```bash
cd cortina && cargo build --release
cd cortina && cargo test
bash .handoffs/archive/cortina/verify-memory-protocol-session-start.sh
```

## Checklist

- [x] session start triggers protocol availability
- [x] Cortina boundary remains narrow and capture-focused
- [x] verify script passes with `Results: N passed, 0 failed`

## Verification Evidence

- `cd cortina && cargo build --release`
  - `Finished 'release' profile [optimized] target(s) in 21.03s`
- `cd cortina && cargo test`
  - `test result: ok. 175 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out`
- `bash .handoffs/archive/cortina/verify-memory-protocol-session-start.sh`
  - `Results: 3 passed, 0 failed`

## Audit Outcome

- Separate audit lane reviewed the final `cortina` diff and found no blocking issues.
- Residual low-risk gaps on status text coverage and verifier depth were fixed before close-out.
