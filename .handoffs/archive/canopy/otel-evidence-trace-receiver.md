# Canopy OTel Evidence Trace Receiver

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Canopy is the final downstream receiver in the initial tracing chain. It should
be implemented separately from the `spore` foundation and separate from Cortina.

## Depends on

- [otel-foundation.md](/Users/williamnewton/projects/basidiocarp/.handoffs/spore/otel-foundation.md)

## What needs doing

Enable `spore/otel` in `canopy`, extract incoming trace context, and create
child spans around evidence writes and related orchestration edges.

Keep this handoff limited to Canopy.

## Files to modify

- `canopy/Cargo.toml`
- `canopy/src/...`
- tests as needed

## Verification

```bash
cd canopy && cargo build
cd canopy && cargo test
bash .handoffs/canopy/verify-otel-evidence-trace-receiver.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] Canopy extracts incoming trace context
- [ ] evidence writes create child spans
- [ ] verify script passes with `Results: N passed, 0 failed`
