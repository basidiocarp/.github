# Lamella: Resolve homunculus observation system boundary

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella` (primary decision); `cortina` (if consolidating)
- **Allowed write scope:** lamella/..., cortina/... (if consolidating)
- **Cross-repo edits:** cortina only if the resolution is to consolidate into cortina
- **Non-goals:** other lamella hook fixes (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problem

`lamella/scripts/hooks/observe.js`

This hook maintains a persistent observation store at `~/.claude/homunculus/`:
- Writes project registries
- Writes JSONL observation files per project
- Manages archive rotation
- Signals observer processes via SIGUSR1

This is runtime lifecycle capture behavior. Lamella's CLAUDE.md explicitly states: "Do not treat Lamella as a runtime" and "Do not move setup or runtime capture into Lamella."

The hook fires on `PreToolUse` and `PostToolUse` with a `"*"` matcher — the same events cortina's `PostToolUse` hook captures. Two independent capture systems run on every tool use with undefined ownership of the `homunculus/` state.

## Options

### Option A — Consolidate into cortina
Move the observation logic into a cortina adapter. Cortina already captures tool-use events (`PostToolUse`). The JSONL writing and project registry could become a cortina output format. `~/.claude/homunculus/` would be declared in cortina's state locations.

### Option B — Declare as a first-class system
If the homunculus system serves a purpose distinct from cortina's capture (e.g., it feeds a specific consumer that cortina does not), declare it explicitly:
- Add `~/.claude/homunculus/` to the ecosystem state location documentation
- Define the JSONL schema in `septa/`
- Document the producer (lamella hook) and consumers
- Establish ownership clearly so the duplication is intentional and governed

### Option C — Remove
If the homunculus system has no active consumers and was an experiment, remove `observe.js` and the associated hook entries from `hooks.json`.

## Decision needed

Review the homunculus consumers (anything reading `~/.claude/homunculus/`) and decide which option applies. Document the decision in this handoff and in the relevant CLAUDE.md files.

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/lamella
make validate 2>&1 | tail -5

# If consolidating into cortina:
cd /Users/williamnewton/projects/basidiocarp/cortina
cargo test 2>&1 | tail -5

cd /Users/williamnewton/projects/basidiocarp
bash scripts/test-lifecycle.sh 2>&1 | tail -3
```

## Checklist

- [ ] Consumers of `~/.claude/homunculus/` identified
- [ ] Option A, B, or C chosen and documented
- [ ] If A: observe.js logic moved to cortina, lamella hook entries removed
- [ ] If B: schema declared in septa, state location documented, ownership assigned
- [ ] If C: observe.js and hook entries removed
- [ ] `make validate` passes
- [ ] Lifecycle test passes
