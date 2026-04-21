# Hyphae OTel Trace Receiver

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Hyphae should become a child-span receiver after the upstream OTel foundation is
in place.

## Depends on

- [otel-foundation.md](/Users/williamnewton/projects/basidiocarp/.handoffs/spore/otel-foundation.md)

## What needs doing

Enable `spore/otel` in `hyphae`, extract trace context from incoming CLI
invocations, and create child spans around storage and search operations.

Keep this handoff limited to Hyphae.

## Files to modify

- `hyphae/Cargo.toml`
- `hyphae/src/...`
- tests as needed

## Verification

```bash
cd hyphae && cargo build --workspace
cd hyphae && cargo test --workspace
bash .handoffs/hyphae/verify-otel-trace-receiver.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] Hyphae extracts incoming trace context
- [ ] storage and search create child spans
- [ ] verify script passes with `Results: N passed, 0 failed`
