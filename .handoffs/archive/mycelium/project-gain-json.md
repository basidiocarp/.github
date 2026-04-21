# Mycelium Project Gain JSON

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** mycelium/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Depends on

- [project-savings-scope.md](/Users/williamnewton/projects/basidiocarp/.handoffs/mycelium/project-savings-scope.md)

## What needs doing

Add machine-facing JSON output for project analytics:

- `--format json`
- `schema_version: "1.0"`
- global totals plus per-project breakdown

Keep this handoff limited to the Mycelium contract surface for consumers.

## Verification

```bash
cd mycelium && cargo test --workspace
bash .handoffs/mycelium/verify-project-gain-json.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] project analytics JSON exists and is valid
- [ ] schema version is pinned
- [ ] global plus per-project totals are both present
- [ ] verify script passes with `Results: N passed, 0 failed`
