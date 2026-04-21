# Cross-Project Hyphae Archive Contract

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** only the repos explicitly named in this handoff
- **Cross-repo edits:** allowed when this handoff names the touched repos explicitly
- **Non-goals:** unplanned umbrella decomposition or opportunistic adjacent repo edits
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`structured-export-archive` is too large to hand to one worker. The first unit of
work is just the archive contract, fixture, and version pin. Until that exists,
the CLI implementation has no stable target.

## What needs doing

Add the versioned archive contract for Hyphae export and import:

- `septa/hyphae-archive-v1.schema.json`
- `septa/fixtures/hyphae-archive-v1-example.json`
- `ecosystem-versions.toml` contract pin
- `septa/README.md` contract listing

Keep this handoff limited to the contract surface. Do not implement `hyphae export`,
`hyphae import`, or `stipe` backup logic here.

## Files to modify

- `septa/hyphae-archive-v1.schema.json`
- `septa/fixtures/hyphae-archive-v1-example.json`
- `septa/README.md`
- `ecosystem-versions.toml`

## Verification

```bash
ls septa/hyphae-archive-v1.schema.json
rg "hyphae-archive" septa/README.md ecosystem-versions.toml
bash .handoffs/cross-project/verify-hyphae-archive-contract.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] schema defines `schema_version`, `exported_at`, `identity`, `filter`, `memories`, `memoirs`, and `sessions`
- [ ] fixture exists and matches the schema shape
- [ ] `ecosystem-versions.toml` pins `hyphae-archive = "1.0"`
- [ ] `septa/README.md` lists the contract
- [ ] verify script passes with `Results: N passed, 0 failed`
