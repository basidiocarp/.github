# Hyphae Artifact Model

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

## What needs doing

Add the typed artifact storage foundation in Hyphae only:

- schema support
- `ArtifactType`
- store/query/latest artifact APIs
- search integration or explicit documented fallback

Keep this handoff limited to the Hyphae model and CLI surface.

## Verification

```bash
cd hyphae && cargo build --workspace
cd hyphae && cargo test --workspace
bash .handoffs/hyphae/verify-artifact-model.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] artifact storage model exists in Hyphae
- [ ] typed queries work by type and project
- [ ] artifact CLI or equivalent access surface exists where intended
- [ ] verify script passes with `Results: N passed, 0 failed`
