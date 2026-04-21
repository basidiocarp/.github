# Cortina OTel Trace Propagation

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
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Once `spore` owns the OTel foundation, Cortina is the first downstream repo that
should consume it. This is the signal hub and the best first propagation point.

## Depends on

- [otel-foundation.md](/Users/williamnewton/projects/basidiocarp/.handoffs/spore/otel-foundation.md)

## What needs doing

Enable `spore/otel` in `cortina` and instrument:

- event dispatch
- Hyphae bridge calls
- Canopy evidence writes

Propagate trace context through downstream CLI invocations. Keep this handoff
limited to Cortina.

## Files to modify

- `cortina/Cargo.toml`
- `cortina/src/...` OTel wiring and spans
- tests as needed

## Verification

```bash
cd cortina && cargo build --release
cd cortina && cargo test
bash .handoffs/cortina/verify-otel-trace-propagation.sh
```

## Checklist

- [x] Cortina creates spans around event dispatch and downstream calls
- [x] trace context is propagated to Hyphae and Canopy invocations (`TraceContextCarrier::from_current()` in hyphae_client.rs and canopy_client.rs)
- [x] no-op path remains cheap when OTel is not configured (`init_tracer` falls back to disabled)
- [x] verify script passes with `Results: 3 passed, 0 failed`

## Verification Output

<!-- PASTE START -->
PASS: cortina uses spore otel feature
PASS: cortina tracing instrumentation exists
PASS: cortina tests pass
Results: 3 passed, 0 failed
<!-- PASTE END -->
