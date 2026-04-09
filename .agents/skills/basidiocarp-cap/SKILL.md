---
name: basidiocarp-cap
description: Guides work in the cap dashboard and server. Use when changing the React, TypeScript, Vitest, or Vite surface in cap and you need the right commands, MCPs, and verification loop.
---

# Basidiocarp Cap

Apply this skill when the task lives in `cap/`.

## Stack

- React 19
- TypeScript
- Vite
- Vitest
- Hono server
- Biome
- Mantine UI

## Working Rules

1. Work from `cap/`.
2. Use `npm run dev:all` for local full-stack development.
3. Use `npm run build` and `npm test` for validation.
4. Use `npm run lint` when formatting or style drift matters.
5. Keep changes aligned with the existing Mantine and app structure instead of inventing a parallel UI system.
6. Use `playwright` MCP for browser verification when UI behavior, routing, or rendering is part of the task.
7. Use `context7` when current React, Vite, Vitest, or Mantine docs matter.

## Verification

- For UI or client logic: `npm run build` and frontend tests as needed.
- For API or server logic: server tests as needed.
- For cross-cutting changes: `npm test`.
