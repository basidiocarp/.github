# Cap Dependency Cleanup

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** cap/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Cap has a missing direct dependency (zustand) and 5 unused dependencies (Tiptap stack).
zustand resolves only via transitive deps — a clean `npm install` in CI could fail.
The Tiptap packages add ~2-3MB of unnecessary bundle weight.

## What exists (state)

- **Missing:** `zustand` — imported by `src/store/project-context.ts` and
  `src/store/host-coverage.ts` but not in package.json
- **Unused:** `@mantine/tiptap`, `@tiptap/extension-link`, `@tiptap/pm`,
  `@tiptap/react`, `@tiptap/starter-kit` — zero imports in `src/` or `server/`
- **Also flagged:** `@mantine/spotlight` — depcheck reports unused

## What needs doing (intent)

Add zustand as a direct dependency. Remove unused Tiptap and spotlight packages.

---

### Step 1: Fix dependencies

**Project:** `cap/`
**Effort:** 10 min

```bash
cd cap
npm install zustand
npm uninstall @mantine/tiptap @tiptap/extension-link @tiptap/pm @tiptap/react @tiptap/starter-kit @mantine/spotlight
```

Verify build still works: `npm run build`

**Checklist:**
- [ ] zustand in package.json dependencies
- [ ] Tiptap packages removed
- [ ] `npm run build` succeeds
- [ ] `npm test` passes (294 tests, may still have 1 flaky timeout)

## Context

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFound during global ecosystem audit (2026-04-04), Layer 1 lint audit of cap.
