# Volva Memory Protocol Injection

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

## Depends on

- [protocol-surface.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/hyphae/protocol-surface.md)

## What needs doing

Inject the Hyphae memory-use protocol into Volva's context assembly as a concise
context block, without changing unrelated Volva behavior.

## Verification

```bash
cd volva && cargo build --release
cd volva && cargo test
bash .handoffs/volva/verify-memory-protocol-injection.sh
```

## Checklist

- [x] Volva includes the memory protocol when Hyphae is available
- [x] injected protocol stays concise
- [x] verify script passes with `Results: N passed, 0 failed`

## Verification Evidence

```text
$ cd /Users/williamnewton/projects/basidiocarp/volva && cargo build --release
Finished `release` profile [optimized] target(s) in 32.15s
```

```text
$ cd /Users/williamnewton/projects/basidiocarp/volva && cargo test
test result: ok. 28 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.76s
test result: ok. 21 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.20s
test result: ok. 20 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 3.00s
```

```text
$ bash /Users/williamnewton/projects/basidiocarp/.handoffs/volva/verify-memory-protocol-injection.sh
PASS: volva memory protocol injection exists
PASS: volva context tests cover memory protocol injection
PASS: volva verifier targets real crate layout
Results: 3 passed, 0 failed
```
