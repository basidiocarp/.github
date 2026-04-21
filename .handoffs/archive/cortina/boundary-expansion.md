# Cortina: Resolve boundary expansion (handoff audit, rules, mycelium DB read)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** cortina/...
- **Cross-repo edits:** possibly canopy or hymenium if handoff audit logic moves there
- **Non-goals:** recall-boundary fix (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

Cortina's operating model is "capture lifecycle signals and forward them." Three areas have grown beyond that scope.

### 1 — Handoff audit/lint system (~1000 LOC)
`src/handoff_audit.rs`, `src/handoff_lint.rs`, `src/handoff_paths.rs`, `src/hooks/pre_commit.rs`, `src/cli.rs:48-56`

Cortina has a full handoff auditing subsystem that reads handoff markdown, checks filesystem for implementation evidence, classifies confidence, and validates coordination artifact completeness. This is canopy/hymenium territory.

Resolution options:
- **Move to canopy**: canopy already consumes `cortina audit-handoff` via CLI; move the logic there and make canopy the owner
- **Move to hymenium**: if this is phase-gating behavior, hymenium is the right owner
- **Keep with explicit contract**: if cortina keeps it, declare it in cortina's CLAUDE.md as an explicit responsibility with a septa schema for the audit output

### 2 — Pre-write relevance rules as policy enforcer
`src/rules.rs`, `src/hooks/pre_tool_use.rs:227-259`

Cortina nudges tool adoption behavior by checking whether rhizome tools were called before file edits. This is policy enforcement, not signal capture.

Resolution: move the nudge logic to a lamella skill or canopy's dispatch policy layer, or accept it as an advisory signal (logging only, no user-facing messages from cortina).

### 3 — Direct mycelium SQLite read
`src/statusline.rs:440-487` (deprecated)

Opens mycelium's `history.db` directly to read token savings for the statusline. This violates the boundary — sibling tools should be consumed via CLI or MCP, not direct DB access. The file is deprecated in favour of annulus.

Resolution: remove the deprecated `statusline.rs` and its mycelium DB access entirely, or ensure it is fully dead-code gated.

## Decision needed

Review each area and choose a resolution. Document the decision in this handoff and in cortina's CLAUDE.md.

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina
cargo test 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

## Checklist

- [ ] Handoff audit/lint system: moved to correct owner or declared with explicit contract
- [ ] Pre-write rules: moved to lamella/canopy or reclassified as advisory-only signal
- [ ] Deprecated `statusline.rs` mycelium DB access removed or dead-code gated
- [ ] cortina CLAUDE.md updated to reflect resolution
- [ ] All tests pass, clippy clean
