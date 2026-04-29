# Lamella: General And Ecosystem Skill Pack Split

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/resources/skills/`, `lamella/manifests/`, `lamella/docs/authoring/`, `lamella/docs/maintainers/`, `lamella/README.md`, `lamella/CLAUDE.md`, `lamella/Makefile`, `lamella/scripts/`, `.agents/skills/`
- **Cross-repo edits:** `.agents/skills/` only for Basidiocarp-local adapter skills; no production repo source changes
- **Non-goals:** no separate repository split, no packaging engine rewrite, and no generated `dist/` hand-edits
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-general-and-ecosystem-skill-pack-split.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** skill resources, package manifests, skill inventory docs, authoring guidance, package validation scripts
- **Reference seams:** `lamella/docs/authoring/skills-spec.md`, `lamella/docs/authoring/best-practices.md`, existing manifests under `lamella/manifests/`, existing Basidiocarp skills under `.agents/skills/`
- **Spawn gate:** do not launch an implementer until the parent agent has generated the skill classification inventory and identified the exact manifest files to change

## Problem

Lamella currently mixes broadly reusable skills with Basidiocarp-specific operational guidance. Some skills are clearly general, some are ecosystem-only, and some enhance the ecosystem but could remain portable if Basidiocarp behavior is moved into a thin adapter layer.

Without an explicit content-pack boundary, general skills risk accumulating local repo names, handoff conventions, Septa/Cortina/Stipe assumptions, and workspace-specific validation rules. That makes the skill library less reusable and adds unnecessary context to agents that only need general guidance.

## What needs doing

1. Inventory all Lamella skills and classify each as `general`, `basidiocarp`, or `adapter-candidate`.
2. Define package boundaries:
   - `general`: reusable skills with no Basidiocarp source-of-truth files or repo names required.
   - `basidiocarp`: local operational skills that depend on this workspace's repos, handoffs, contracts, or conventions.
   - `adapter-candidate`: skills whose core guidance is reusable but needs a Basidiocarp companion.
3. For adapter candidates, keep the reusable core general and create thin Basidiocarp adapter skills that say which local files, contracts, and verification rules to apply.
4. Update manifests so general packs and Basidiocarp packs can be built independently without duplicating whole skill bodies.
5. Document the classification rule in Lamella authoring/maintainer docs.
6. Keep the same Lamella build and validation pipeline; do not split repos until the content-pack boundary proves stable.

## Scope

- **Primary seam:** Lamella skill content packaging and manifest organization
- **Allowed files:** skill resources, manifests, authoring/maintainer docs, validation scripts, local `.agents/skills/` adapters
- **Explicit non-goals:**
  - no production code changes in `canopy`, `cortina`, `hymenium`, `hyphae`, `septa`, `stipe`, or other sibling repos
  - no separate Git repository split
  - no runtime capture, host install, or hook policy changes
  - no generated output edits unless produced by the normal Lamella build

## Suggested Classification Rule

- If the skill is useful without Basidiocarp repo names, keep it general.
- If the skill only needs Basidiocarp examples, keep examples in a local reference file or adapter.
- If the skill requires Basidiocarp source-of-truth files such as `septa/`, `.handoffs/`, `docs/foundations/`, or `ecosystem-versions.toml`, make it Basidiocarp-specific or create a Basidiocarp adapter.
- If more than roughly one third of the skill is ecosystem-specific, classify it as Basidiocarp-specific and extract reusable guidance later.

## Verification

```bash
cd lamella && make validate
cd lamella && ./lamella validate skills
cd lamella && ./lamella validate skill-packages
bash .handoffs/lamella/verify-general-and-ecosystem-skill-pack-split.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] every Lamella skill has a documented classification
- [ ] general packs do not require Basidiocarp repo paths or workspace-specific source-of-truth files
- [ ] Basidiocarp adapters are thin and reference the general skill instead of duplicating it wholesale
- [ ] manifests can build general and Basidiocarp packs independently
- [ ] authoring docs explain when to write a general skill, ecosystem skill, or adapter skill
- [ ] generated output is refreshed only through normal Lamella commands
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the post-audit packaging discussion about splitting Lamella into a reusable general skills library and an ecosystem-specific skill library. The preferred direction is a content-pack split first, with `core + adapter` handling skills that are generally useful but need Basidiocarp-specific enhancements.
