# Agent Telemetry Dashboard

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

Cap shows session health but not agent behavior patterns: which tools are used most, what files are touched frequently, command frequency, sessions per day. Without this, operators can't spot inefficiency or understand how agents spend context.

## What exists (state)

- **Cap**: Analytics tab, existing chart components
- **No `/api/telemetry` endpoint**
- **`transcript-parser.ts`**: created by cost-usage-tracking handoff (depends on it)

## What needs doing (intent)

Parse transcripts for tool usage patterns and file activity. Expose via `/api/telemetry`. Add "Agent Activity" tab to Analytics.

---

### Step 1: Telemetry parser and API

**Project:** `cap/`
**Effort:** 2 hours
**Depends on:** cost-usage-tracking (for `transcript-parser.ts`)

Extend `transcript-parser.ts` with telemetry extraction: tool call counts by tool name, file paths written/edited, commands run via Bash tool, sessions per day. Add `/api/telemetry` route:
```json
{
  "tool_distribution": {"Read": 450, "Edit": 230, "Bash": 180, ...},
  "top_files": [{"path": "src/main.rs", "edit_count": 12}, ...],
  "top_commands": [{"command": "cargo build", "count": 45}, ...],
  "sessions_per_day": [{"date": "2026-04-07", "count": 3}, ...]
}
```

#### Verification

```bash
cd cap && npx tsc -b 2>&1 | tail -5
curl -s http://localhost:3001/api/telemetry | python3 -m json.tool 2>&1 | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `/api/telemetry` returns valid JSON with required fields
- [ ] Tool distribution includes all MCP tool names
- [ ] TypeScript build passes

---

### Step 2: Agent Activity tab

**Project:** `cap/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Add "Agent Activity" tab to Analytics. Show: sessions/day bar chart, tool distribution pie chart, top files table, top commands table.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] "Agent Activity" tab renders without errors
- [ ] All four data views present
- [ ] Build passes

---

## Completion Protocol

1. All step verification output pasted
2. `/api/telemetry` returns valid JSON
3. `npm run build` passes

## Context

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom `.plans/priority-phase-4.md` Plan 14. Depends on `cap/cost-usage-tracking` for the shared transcript parser module.
