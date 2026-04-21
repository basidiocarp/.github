# Cortina: Move inject_recall to hyphae

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina` (primary); `hyphae` (new CLI command)
- **Allowed write scope:** cortina/..., hyphae/...
- **Cross-repo edits:** hyphae gets a new CLI command; cortina delegates to it
- **Non-goals:** other cortina hooks, hyphae content_hash fix
- **Verification contract:** run repo-local commands in both repos
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problem

`cortina/src/hooks/user_prompt_submit.rs:260-459`

`inject_recall` performs memory retrieval: it queries `hyphae search --json`, deduplicates against a session-scoped seen-set, applies a token budget, and surfaces recalled memories to stderr. This is memory retrieval behavior that belongs in hyphae's domain. Cortina's operating model is "record signals and forward them" — not make retrieval decisions.

Consequences of current placement:
- Recall ranking, budget, and dedup logic must be changed in cortina rather than hyphae
- Cortina now has a hidden dependency on hyphae's search output shape
- The two systems are coupled at the wrong layer

## Desired end state

1. Hyphae gains a `hyphae auto-recall` (or equivalent name) CLI command that accepts a query context (current prompt text, session ID, project, token budget) and returns recalled memories formatted for injection. All ranking, dedup, and budget logic lives here.
2. Cortina's `inject_recall` function is replaced with a single shell-out to `hyphae auto-recall` and writes whatever it returns to stderr.
3. The session-scoped seen-set (dedup) either moves into hyphae (preferred, as session state) or is passed as an argument.

## Implementation Seam

- `hyphae/crates/hyphae-cli/src/commands/` — new `auto_recall.rs` command
- `cortina/src/hooks/user_prompt_submit.rs:260-459` — replace with shell-out

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/hyphae
cargo test --workspace 2>&1 | tail -5

cd /Users/williamnewton/projects/basidiocarp/cortina
cargo test 2>&1 | tail -5

cd /Users/williamnewton/projects/basidiocarp
bash scripts/test-lifecycle.sh 2>&1 | tail -3
```

Expected: all pass. Lifecycle test must continue to show recall working end-to-end.

## Checklist

- [ ] `hyphae auto-recall` (or equivalent) CLI command exists with ranking, dedup, and budget logic
- [ ] Cortina `inject_recall` delegates to hyphae CLI — no recall logic in cortina
- [ ] Session dedup state is handled (moved to hyphae or passed as argument)
- [ ] All tests pass in both repos
- [ ] Lifecycle test passes
