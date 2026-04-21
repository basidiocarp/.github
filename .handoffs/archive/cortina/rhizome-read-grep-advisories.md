# Cortina: Rhizome Read/Grep Advisories

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/...`
- **Cross-repo edits:** `none`
- **Non-goals:** implementing `mycelium` rewrites or adding `cortina status` counters
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-rhizome-read-grep-advisories.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`cortina` already has a PreToolUse hook and non-blocking stderr messaging, but it
does not steer agents away from whole-file reads or broad symbol searches when
`rhizome` could answer more precisely with fewer tokens.

## What Exists (State)

- [pre_tool_use.rs](../../cortina/src/hooks/pre_tool_use.rs) already has advisory plumbing and `rhizome` availability checks.
- [tests/](../../cortina/src/hooks/pre_tool_use/tests.rs) already covers the existing PreToolUse behavior.
- `cortina` already emits stderr advisories without blocking the original tool call.

## What Needs Doing

Add two advisory rules in the `cortina` PreToolUse flow:

- `Read` on a code file over the configured line threshold should suggest `mcp__rhizome__get_symbols` or `mcp__rhizome__get_structure`
- symbol-like `Grep` patterns should suggest `mcp__rhizome__search_symbols` or `mcp__rhizome__find_references`

The original tool call must still run. This handoff is only about the advisory
decision and message path.

## Scope

- **Primary seam:** PreToolUse advisory classification for `Read` and `Grep`
- **Allowed files:** `cortina/src/hooks/pre_tool_use.rs`, `cortina/src/hooks/pre_tool_use/tests.rs`, closely related helper files if required
- **Explicit non-goals:**
- Do not add status reporting in this handoff.
- Do not change `mycelium`.
- Do not widen the rule set beyond the two `rhizome` advisory cases.

## Files To Modify

- `cortina/src/hooks/pre_tool_use.rs`
- `cortina/src/hooks/pre_tool_use/tests.rs`
- closely related helper files only if required

## Verification

```bash
cd cortina && cargo build --workspace 2>&1 | tail -5
cd cortina && cargo test --workspace 2>&1 | tail -10
bash .handoffs/cortina/verify-rhizome-read-grep-advisories.sh
```

## Checklist

- [ ] `Read` on large code files emits a `rhizome` advisory when `rhizome` is available
- [ ] symbol-like `Grep` patterns emit a `rhizome` advisory when `rhizome` is available
- [ ] advisories are non-blocking
- [ ] tests cover both advisory paths
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 1 of [Smart Tool Redirection — PreToolUse Advisories](../cross-project/smart-tool-redirection.md).
