# Cost and Usage Tracking

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

Cap has no token usage or cost visibility. Session transcripts contain token counts but nothing parses them. Operators have no way to see spend trends, high-cost sessions, or per-project usage — all common asks once the ecosystem is in regular use.

## What exists (state)

- **Cap**: Analytics tab exists but has no cost/usage data
- **Session transcripts**: `~/.claude/projects/*/sessions/*.jsonl` contain `usage` fields with input/output token counts
- **No `/api/usage` endpoint exists**

## What needs doing (intent)

Parse session transcripts for token usage, estimate costs using model pricing, expose via API, and add a Usage & Cost tab to the Analytics view.

---

### Step 1: Transcript parser and usage API

**Project:** `cap/`
**Effort:** 2-3 hours
**Depends on:** nothing

Create `cap/server/lib/transcript-parser.ts` that scans session JSONL files, extracts `usage.input_tokens` and `usage.output_tokens` per message, groups by session/project/date. Add `/api/usage` route returning:
```json
{
  "total_input_tokens": 1234567,
  "total_output_tokens": 567890,
  "estimated_cost_usd": 12.34,
  "sessions": [...],
  "by_project": {...},
  "by_day": [...]
}
```
Use static pricing table (Claude Sonnet, Haiku, Opus rates). Keep parser in a shared module — agent-telemetry will reuse it.

#### Verification

```bash
cd cap && npx tsc -b 2>&1 | tail -5
curl -s http://localhost:3001/api/usage | python3 -m json.tool 2>&1 | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `transcript-parser.ts` module created, exported functions typed
- [ ] `/api/usage` returns valid JSON with required fields
- [ ] TypeScript build passes

---

### Step 2: Usage & Cost tab in Analytics

**Project:** `cap/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Add "Usage & Cost" tab to the Analytics page. Show: total cost KPI card, input/output token KPI cards, cost-over-time line chart (30 days), top sessions table (sorted by cost). Reuse existing chart components.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] "Usage & Cost" tab renders without errors
- [ ] KPI cards show total cost, input tokens, output tokens
- [ ] Cost chart shows 30-day trend
- [ ] Build passes

---

## Completion Protocol

1. All step verification output pasted
2. `/api/usage` returns valid JSON
3. `npm run build` passes
4. Usage & Cost tab visible and populated

## Context

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom `.plans/priority-phase-4.md` Plan 13. Agent Telemetry (cap/agent-telemetry) depends on the `transcript-parser.ts` module created here — do cost tracking first.
