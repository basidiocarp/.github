# Cortina: Tool Advisory Status Counts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/...`
- **Cross-repo edits:** `none`
- **Non-goals:** implementing the advisory matcher itself or changing `mycelium`
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-tool-advisory-status-counts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Even after `cortina` emits `rhizome` advisories, operators still need a simple
status surface that shows whether those rules are firing in the current session.

## What Exists (State)

- [status.rs](../../cortina/src/status.rs) already reports session counters and capability availability.
- [pre_tool_use.rs](../../cortina/src/hooks/pre_tool_use.rs) already persists advisory state for rate limiting.
- the advisory feature should already exist before this handoff begins.

## What Needs Doing

Extend `cortina status` to show advisory counts for the `Read` and `Grep`
redirection rules, based on the same scoped state the PreToolUse hook writes.

This handoff should only surface the counts. It should not widen the advisory
rule set or add new rewrite logic.

## Scope

- **Primary seam:** status reporting for advisory counters
- **Allowed files:** `cortina/src/status.rs`, `cortina/src/hooks/pre_tool_use.rs`, status-related tests
- **Explicit non-goals:**
- Do not add new advisory types in this handoff.
- Do not change `mycelium`.
- Do not create a second advisory state store if the existing scoped state can be reused.

## Files To Modify

- `cortina/src/status.rs`
- `cortina/src/hooks/pre_tool_use.rs` only if the status surface needs a cleaner read seam
- tests as needed

## Verification

```bash
cd cortina && cargo build --workspace 2>&1 | tail -5
cd cortina && cargo test --workspace 2>&1 | tail -10
bash .handoffs/cortina/verify-tool-advisory-status-counts.sh
```

## Checklist

- [ ] `cortina status` reports advisory counts for the `Read` and `Grep` redirect rules
- [ ] counts are scoped to the current session state
- [ ] tests cover the status rendering or report collection path
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 3 of [Smart Tool Redirection — PreToolUse Advisories](../cross-project/smart-tool-redirection.md). This child should start only after [rhizome-read-grep-advisories.md](rhizome-read-grep-advisories.md) is complete.
