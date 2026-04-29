# Hyphae: Obsidian Second-Brain Export

<!-- Save as: .handoffs/hyphae/obsidian-second-brain-export.md -->
<!-- Create verify script: .handoffs/hyphae/verify-obsidian-second-brain-export.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/docs/`, `hyphae/crates/`, `septa/*obsidian*.schema.json`, `septa/fixtures/*obsidian*.json`, `septa/integration-patterns.md`, `.handoffs/hyphae/`
- **Cross-repo edits:** Septa contract and docs only if this moves past design into implementation
- **Non-goals:** no Cap second-brain UI, no Obsidian plugin, no bidirectional sync, and no core-hardening priority change
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hyphae/verify-obsidian-second-brain-export.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** Hyphae export/archive/read-model code, session summaries, memoir export, docs; optional Septa export manifest contract
- **Reference seams:** `hyphae` memoir/session read models, Cortina lifecycle/session capture, Canopy/Hymenium workflow outcomes, `docs/foundations/inter-app-communication.md`
- **Spawn gate:** do not launch an implementer until the core hardening freeze is lifted or the user explicitly promotes this from deferred research to active implementation

## Problem

Many users already use Obsidian as a human-readable "second brain" for Claude and agent work. Basidiocarp has similar raw material: memories, session summaries, handoff outcomes, lessons, decisions, audit findings, and workflow history. But building a second-brain UI inside Cap would expand scope before the core memory/orchestration loop is proven.

The safer future direction is export-first: let Hyphae produce structured Markdown into an Obsidian vault, then let Cap link to or preview that knowledge later if dogfood proves value.

## What exists (state)

- **Hyphae:** owns structured memory, memoirs, lessons, sessions, archive/read models, and search.
- **Cortina:** captures session and lifecycle events that can become durable notes.
- **Canopy/Hymenium:** produce task/workflow outcomes that may be useful as audit trail notes.
- **Cap:** should remain an operator console, not become the primary second-brain product.

## What needs doing (intent)

Design and eventually implement a one-way Obsidian export path:

- export selected Hyphae memories, lessons, memoir summaries, and session summaries as Markdown
- generate stable filenames and frontmatter for project, session, tags, source ids, and timestamps
- support dry-run and preview modes
- avoid writing secrets or raw transcript fragments unless explicitly allowed
- preserve Hyphae as the structured source of truth
- document that Obsidian is a human-readable projection, not the canonical database

## Scope

- **Primary seam:** Hyphae-to-Markdown/Obsidian export
- **Allowed files:** listed in metadata
- **Explicit non-goals:** no Obsidian plugin API, no bidirectional import/sync, no Cap UI, no automatic vault watcher, no rewriting Hyphae memory storage

## Required Design Report

Before implementation, create `hyphae/docs/obsidian-export-design.md` with:

```markdown
# Obsidian Export Design

## Status
[deferred / proposed / active]

## Source Of Truth
[Hyphae remains canonical; Obsidian is projection]

## Exported Note Types
[session summaries, lessons, decisions, handoff outcomes, audit findings, memoir indexes]

## Markdown Layout
[vault folders, filenames, frontmatter, links]

## Redaction Rules
[secret, transcript, PII, and raw command handling]

## Contract Needs
[whether Septa needs an export manifest schema]

## Cap Relationship
[links/previews only; no second-brain ownership]

## Open Questions
```

## Verification

```bash
cd hyphae && cargo test obsidian export
cd septa && bash validate-all.sh
bash .handoffs/hyphae/verify-obsidian-second-brain-export.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] design doc exists at `hyphae/docs/obsidian-export-design.md`
- [ ] design keeps Hyphae as canonical source of truth
- [ ] design defines exported note types and Markdown/frontmatter shape
- [ ] design includes redaction rules
- [ ] design explicitly keeps Cap out of second-brain ownership
- [ ] if implemented, export has dry-run/preview mode
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Future/deferred idea captured on 2026-04-26. This should stay behind the core hardening freeze and Cap scope reset. If pursued, start with a design report and one-way export rather than a Cap-owned knowledge UI.

