---
name: basidiocarp-lamella
description: Guides Lamella authoring, packaging, and migration work in this workspace. Use when editing lamella skills, commands, hooks, manifests, docs, or Codex and Claude export surfaces.
---

# Basidiocarp Lamella

Apply this skill when the task lives in `lamella/`.

## First Step

Read `lamella/docs/authoring/` before substantial work involving skills, agents, commands, manifests, hooks, or plugin audits.

## Working Rules

1. Preserve Lamella's packaging boundary. Push runtime capture to `cortina` and host management to `stipe`.
2. Audit across related files, not only the changed file. Check manifests, docs, hooks, and resource folders together.
3. Keep skill descriptions concise, action-led, and consistent with the local authoring guidance.
4. Prefer cross-platform guidance when the tool or workflow is not inherently shell-specific.
5. When touching commands, hooks, or manifests, watch for manifest drift and stale references.
6. Use `context7` only when current Codex, library, or framework docs are actually needed.

## Verification

- Run `make validate` from `lamella/`.
- If packaging behavior changes, check the relevant build output or manifest path as needed.
