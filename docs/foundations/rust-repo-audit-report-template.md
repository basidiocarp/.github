# Rust Repo Audit Report Template

Date: YYYY-MM-DD
Repo: `repo-name`
Auditor: `name`
Scope: short description of what was reviewed
Standards used:

- [docs/foundations/rust-workspace-architecture-standards.md](/docs/foundations/rust-workspace-architecture-standards.md)
- [docs/foundations/rust-repo-audit-checklist.md](/docs/foundations/rust-repo-audit-checklist.md)

This template is for repo-specific audits in the `basidiocarp` ecosystem. Fill it in after running the checklist. Keep
it concrete. Use file references where they matter.

## One-paragraph read

What is the shortest honest summary of the repo’s current structural health?

Example:

`repo-name` has a clear product boundary and mostly clean layering, but the transport surface is starting to absorb
policy and config logic that should stay lower in the stack. CI is credible, contracts are explicit, and the next risk
is hotspot growth rather than immediate architectural failure.

## What the repo owns

Write two or three sentences.

- Owns:
- Does not own:
- Key sibling boundaries:

## Current shape

Describe the actual shape, not the ideal one.

- Package or workspace layout:
- Main crates or modules:
- Obvious composition root:
- Core abstraction or trait:

## Findings

### 1. Boundary

What is structurally right? What is leaking?

- Keep:
- Tighten:
- Watch:

Evidence:

- `path/to/file-or-doc`

### 2. Dependency direction

Are dependencies flowing the way the crate names imply?

- Keep:
- Tighten:
- Watch:

Evidence:

- `path/to/file-or-doc`

### 3. Domain and shared types

Is the core narrow and coherent, or turning into a catch-all?

- Keep:
- Tighten:
- Watch:

Evidence:

- `path/to/file-or-doc`

### 4. Composition and orchestration

Is wiring centralized, or bleeding through the repo?

- Keep:
- Tighten:
- Watch:

Evidence:

- `path/to/file-or-doc`

### 5. Hotspots

Which files, modules, or crates are under the most structural pressure?

- Hotspot 1:
- Hotspot 2:
- Hotspot 3:

Why they matter:

-

Evidence:

- `path/to/file-or-doc`

### 6. Config, policy, and operator UX

Is config a real product surface? Are permissions and runtime safety explicit where needed?

- Keep:
- Tighten:
- Watch:

Evidence:

- `path/to/file-or-doc`

### 7. Contracts and ecosystem fit

How well does the repo behave as part of the larger ecosystem?

- Keep:
- Tighten:
- Watch:

Evidence:

- `path/to/file-or-doc`

### 8. CI, tests, and verification

What does green mean here, and can you trust it?

- Verification run:
- Passed:
- Failed:
- Gaps:

Evidence:

- `path/to/file-or-doc`

## Severity summary

Use short prose or a flat list.

- Critical:
- High:
- Medium:
- Low:

If there are no critical issues, say so directly.

## Recommended actions

Split this into three buckets only. That keeps the report useful.

### Do now

-

### Do next

-

### Revisit later

-

## Borrow or reuse value

If this repo has patterns worth reusing elsewhere, list them here.

- Pattern worth reusing:
- Why:
- Best destination repo:

## Final read

Finish with three lines:

Keep:

Tighten:

Watch:

## Optional appendix

Use this only if the audit needs more detail.

### Commands run

```bash
# add commands here
```

### Extra notes

-
