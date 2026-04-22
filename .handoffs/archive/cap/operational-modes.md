# Operational Modes

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

Cap has no mode concept — the same UI and behavior regardless of whether the user is exploring a codebase, actively developing, or reviewing changes. An explicit mode selector would let users configure tool nudges, memory capture aggressiveness, and display density per workflow.

## What exists (state)

- **Cap**: Settings page exists with some config options
- **No `~/.config/basidiocarp/modes.json`**
- **No `/api/settings/modes` endpoint**

## What needs doing (intent)

Add an Explore / Develop / Review mode selector. Persist mode in `~/.config/basidiocarp/modes.json`. Surface current mode in the cap header. Each mode can carry different defaults for hyphae recall depth, rhizome analysis level, and display density.

---

### Step 1: Mode backend

**Project:** `cap/`
**Effort:** 1 hour
**Depends on:** nothing

Add `GET /api/settings/modes` (returns current mode + available modes) and `POST /api/settings/modes` (sets mode). Persist to `~/.config/basidiocarp/modes.json`. Three modes: `explore` (read-heavy, deep recall), `develop` (balanced), `review` (diff-focused, light recall).

#### Verification

```bash
cd cap && npx tsc -b 2>&1 | tail -3
curl -s -X POST http://localhost:3001/api/settings/modes -H 'Content-Type: application/json' -d '{"mode":"develop"}' | python3 -m json.tool
curl -s http://localhost:3001/api/settings/modes | python3 -m json.tool
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] GET and POST endpoints work
- [ ] Mode persists across cap restarts
- [ ] TypeScript build passes

---

### Step 2: Mode selector in cap UI

**Project:** `cap/`
**Effort:** 1 hour
**Depends on:** Step 1

Add a segmented control (Explore / Develop / Review) to the cap header or Settings page. Active mode highlighted. Persists via API on change.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -3
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Mode selector renders in header or Settings
- [ ] Changing mode calls API and persists
- [ ] Build passes

---

## Completion Protocol

1. All step verification output pasted
2. Mode persists across restart
3. `npm run build` passes

## Context

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom `.plans/priority-phase-4.md` Plan 15. Low priority standalone feature — no other handoffs depend on it.
