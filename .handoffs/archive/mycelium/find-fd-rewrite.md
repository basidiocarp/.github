# Mycelium: Find To FD Rewrite

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** `mycelium/...`
- **Cross-repo edits:** `none`
- **Non-goals:** adding `cortina` advisories or status surfaces
- **Verification contract:** run the repo-local commands below and `bash .handoffs/mycelium/verify-find-fd-rewrite.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The ecosystem wants safe `find` calls to collapse into `fd` when `fd` is
available, but that behavior should live in `mycelium` rewrite resolution rather
than inside a cross-project umbrella.

## What Exists (State)

- [registry.rs](../../mycelium/src/discover/registry.rs) already owns command rewrite classification and includes a `rewrite_find_to_fd(...)` seam.
- [rewrite_cmd.rs](../../mycelium/src/rewrite_cmd.rs) already explains rewrite reasons and estimated savings.
- existing rewrite tests already exercise other command families and the rewrite explanation surface.

## What Needs Doing

Finish or tighten the safe `find` to `fd` rewrite behavior in the real rewrite
registry, keeping the behavior transparent to callers and visible through
`mycelium rewrite --explain`.

Preferred supported shapes:

- `find . -name "*.ext"` -> `fd -e ext .`
- `find . -type f -name "..."` -> `fd --type f ...`
- safe glob-like names should map to `fd --glob`
- complex or unsafe `find` forms should pass through unchanged

## Scope

- **Primary seam:** `mycelium` rewrite classification and explanation for safe `find` commands
- **Allowed files:** `mycelium/src/discover/registry.rs`, `mycelium/src/rewrite_cmd.rs`, related tests
- **Explicit non-goals:**
- Do not add a new standalone filter framework for this handoff.
- Do not change `cortina`.
- Do not rewrite complex `find` expressions that the current parser cannot classify safely.

## Files To Modify

- `mycelium/src/discover/registry.rs`
- `mycelium/src/rewrite_cmd.rs`
- tests as needed

## Verification

```bash
cd mycelium && cargo build --workspace 2>&1 | tail -5
cd mycelium && cargo test --workspace 2>&1 | tail -10
bash .handoffs/mycelium/verify-find-fd-rewrite.sh
```

## Checklist

- [ ] safe `find` patterns rewrite to `fd` when `fd` is available
- [ ] complex or unsupported `find` patterns pass through unchanged
- [ ] `mycelium rewrite --explain` reports the `find` to `fd` reason
- [ ] tests cover both rewritten and passthrough cases
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 2 of [Smart Tool Redirection — PreToolUse Advisories](../cross-project/smart-tool-redirection.md).
