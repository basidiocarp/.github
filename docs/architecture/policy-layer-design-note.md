# Policy and Control Layer (Deferred)

This note records an architectural gap, not a planned project. The policy layer covers guardrails,
AuthN/AuthZ, human-in-the-loop checkpoints, auditability, and compliance rules. The decision today
is to not build it.

## What the Policy Layer Would Cover

| Capability | What it means |
|---|---|
| Guardrails | Content filtering, action restrictions, disallowed tool patterns |
| AuthN/AuthZ | Who can run which agents against which repos, with what permissions |
| HITL checkpoints | Approval gates inserted by the harness, not delegated to the host |
| Auditability | Structured audit trail usable for compliance review or incident investigation |
| Compliance rules | Per-team or per-org policies applied consistently across workflows |

None of these exist as harness-owned infrastructure today.

## Why It Is Deferred

- Solo developers do not need a policy engine. Claude Code's permission prompts handle HITL for
  tool use. That coverage is sufficient for the current user base.
- AuthN/AuthZ only matters with multi-user team adoption, which is not the current priority. Adding
  an access control system before there are multiple users to control would be speculative.
- Cortina's planned PreToolUse advisories (handoff #65) are the first harness-side policy
  enforcement point. Those should be implemented and evaluated before designing a full policy engine.
- Compliance infrastructure built before a compliance requirement exists is waste.

The gap is real at scale. It is not a gap that blocks current use.

## What Exists That Partially Addresses It

| Component | What it contributes |
|---|---|
| Host (Claude Code, Codex CLI) | Permission prompts and HITL — the primary policy enforcement point today |
| `cortina` | Captures lifecycle signals that could feed policy decisions; does not enforce them |
| Cortina PreToolUse advisories (#65) | Planned harness-side advisory before tool execution; the first enforcement-adjacent hook |
| `canopy` task ownership | Only the owning agent can complete a task — implicit access scoping without explicit AuthZ |

The current posture is: delegate policy to the host, observe via cortina, and expand from there when
demand appears.

## What Would Trigger Building It

| Trigger | Signal |
|---|---|
| Team adoption | Multiple users need different permission levels for the same repos or agents |
| Compliance requirement | Enterprise or regulated-industry context requires structured audit trails |
| Action restriction demand | Operators need "no force-push in production repos" class rules beyond host defaults |
| PreToolUse advisories insufficient | Cortina advisory hooks prove too weak for real policy enforcement needs |

If team adoption and one of the other triggers appear together, revisit the deferral.

## Where It Would Sit

A policy layer would sit at the execution boundary — consulted before actions are taken, not after
signals are captured:

```
policy layer
    ├── consulted at volva's execution boundary (before dispatch)
    ├── consulted at cortina's PreToolUse hook (before tool execution)
    └── reads identity and context from the host or an AuthN provider
```

This mirrors the hymenium pattern: the integration points already exist (volva dispatch, cortina
hooks), the active decision-maker does not. It could be a new tool or an expansion of cortina's
adapter boundary. Septa would govern any cross-tool policy payloads.

## Related

- [hymenium-design-note.md](./hymenium-design-note.md) — deferred orchestration kernel; same pattern of existing integration points without an active coordinator
- [platform-layer-model.md](./platform-layer-model.md) — Layer 4 analysis and coverage summary
- [annulus-design-note.md](./annulus-design-note.md) — cross-ecosystem utilities; a contrast in scope (small shared utilities, not enforcement infrastructure)
