# Repo Documentation Standards

This document defines the default documentation layout for repos in the
Basidiocarp workspace.

## Goals

- make repo docs easy to scan without reading every file name
- separate live operator guidance from planning and historical material
- keep vendor or host reference snapshots from looking like project policy
- make cross-repo audits cheaper because the same paths mean the same thing

## Default Layout

Use this structure when a repo has enough documentation to justify a `docs/`
tree:

```text
docs/
  README.md
  getting-started/
    README.md
  authoring/          # only when the repo has content-authoring rules
    README.md
  reference/
    README.md
  maintainers/        # optional, for maintainer-only operational notes
    README.md
  plans/
    README.md
```

Not every repo needs every section. The requirement is consistency, not
maximalism.

## Section Meanings

- `docs/README.md`: the repo docs entrypoint; group docs by use case rather than by filename dump
- `docs/getting-started/`: shortest path for onboarding or first-run usage
- `docs/authoring/`: writing, packaging, or content-authoring rules when the repo produces reusable artifacts
- `docs/reference/`: host, vendor, or imported reference material; not the repo's source of truth
- `docs/maintainers/`: maintainer-facing docs such as inventories, boundary cleanup notes, or internal operating guidance
- `docs/plans/`: active plans that may still change

## Placement Rules

- Keep durable architecture docs near the docs root, for example `docs/architecture.md` and `docs/roadmap.md`.
- Put active project plans in `docs/plans/`, not beside onboarding docs.
- When a doc is mainly for maintainers rather than normal users, prefer `docs/maintainers/`.
- When importing host documentation, add a local `README.md` that explains how to interpret that subtree in repo context.

## Naming Rules

- Prefer kebab-case file names.
- Use `README.md` as the entrypoint for any browsable docs subtree.
- Avoid all-caps filenames unless the file is intentionally mirroring an external upstream artifact.

## Anti-Patterns

- mixing historical migration studies with the live backlog in one folder
- leaving imported vendor docs without a local index or context note
- using the docs root as a flat pile of unrelated files
- putting maintainer cleanup notes in the main onboarding path

## Minimum Standard

For most repos, the practical minimum is:

```text
docs/
  README.md
  plans/
    README.md
```

Add the other sections only when the repo genuinely needs them.
