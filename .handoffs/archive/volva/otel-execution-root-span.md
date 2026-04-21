# Volva OTel Execution Root Span

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** volva/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `volva` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

After `spore` and `cortina`, Volva is the execution entry point that should
create the root span for end-to-end tracing.

## Depends on

- [otel-foundation.md](/Users/williamnewton/projects/basidiocarp/.handoffs/spore/otel-foundation.md)

## What needs doing

Enable `spore/otel` in `volva` and add:

- root span for `run` / `chat`
- trace propagation when forwarding hook phases to Cortina
- backend and session identity span attributes

Keep this handoff limited to Volva.

## Files to modify

- `volva/Cargo.toml`
- `volva/src/...`
- tests as needed

## Verification

```bash
cd volva && cargo build --release
cd volva && cargo test
bash .handoffs/volva/verify-otel-execution-root-span.sh
```

## Checklist

- [x] Volva creates a root execution span (`root_span` in volva-cli main.rs)
- [x] `init_logging_with_otel` wires OTel tracing subscriber
- [x] backend type and session identity are attached as span attributes
- [x] verify script passes with `Results: 3 passed, 0 failed`

## Verification Output

<!-- PASTE START -->
PASS: volva uses spore otel feature
PASS: volva tracing instrumentation exists
PASS: volva tests pass
Results: 3 passed, 0 failed
<!-- PASTE END -->
