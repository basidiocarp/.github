# End-to-End Smoke Audit Template

Validates that the core ecosystem loop (cortina → hyphae → mycelium → canopy → cap, plus stipe and annulus) actually runs. Static schema checks pass on every shape but never prove flows work end-to-end.

**Cadence:** monthly during active hardening, quarterly after.
**Maps to:** F1 exit criterion #1 ("core loop works end-to-end").
**Runtime:** ~30–60 minutes for one operator, depending on flow count.

---

## Handoff Metadata (instance — fill in when copying)

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only)
- **Allowed write scope:** `.handoffs/campaigns/<campaign-name>/findings/lane<N>-end-to-end-smoke.md`
- **Cross-repo edits:** none — read-only audit; may run ecosystem CLIs and observe behavior, but must not mutate state
- **Non-goals:** does not fix any flow that breaks; does not run destructive commands (no `stipe install`, no `hyphae forget`, no DB writes beyond what read-only flows naturally do)
- **Verification contract:** `bash .handoffs/campaigns/<campaign-name>/verify-lane<N>-end-to-end-smoke.sh`
- **Completion update:** parent updates campaign README + dashboard

## Problem (parameterize per run)

State the F1 criterion or operational concern that motivates the run. Example:

> Static schema checks pass on every shape but nothing has actually exercised the core ecosystem loop end-to-end since the F1 freeze began. F1 exit criterion #1 demands "core loop works end-to-end (cortina → hyphae → mycelium → rhizome → cap)" — that's an unverified claim today.

## Standard Smoke Flows

A baseline set the auditor must attempt. Adjust per run if a tool is genuinely out of scope; do not silently skip.

### Flow 1 — Cortina session lifecycle → Hyphae ingest

```bash
cortina --version
cortina adapter claude-code --help 2>&1 | head -10
hyphae session list --limit 5
```

### Flow 2 — Hyphae memory recall

```bash
hyphae --version
hyphae stats --json
hyphae memory recall --query "test" --limit 3
```

### Flow 3 — Mycelium gain → Cap rendering surface

```bash
mycelium --version
mycelium gain --format json | head -40
```

### Flow 4 — Rhizome MCP surface

```bash
rhizome --version
rhizome --help 2>&1 | head -10
```

### Flow 5 — Canopy snapshot → Cap consumer

```bash
canopy --version
canopy api snapshot 2>&1 | head -40
```

### Flow 6 — Stipe doctor → Cap settings

```bash
stipe --version
stipe doctor --json 2>&1 | head -40
```

### Flow 7 — Annulus status (post-F2.8 contract)

```bash
annulus --version
annulus status --json 2>&1 | head -20
```

### Flow 8 — Septa validator self-check (sanity)

```bash
cd septa && bash validate-all.sh 2>&1 | tail -3
```

## Findings File Format

Write `findings/lane<N>-end-to-end-smoke.md`:

```markdown
# Lane N: End-to-End Smoke Findings (YYYY-MM-DD)

## Summary
[1–2 sentences: blocker/concern/nit/UNRUNNABLE counts]

## Environment
[`<tool> --version` outputs collected, OS, shell]

## Per-flow Results

### Flow 1 — [name] — verdict: PASS|DEGRADED|FAIL|UNRUNNABLE
- Command(s) run
- Output (or summary if voluminous)
- Notes

[repeat per flow]

## Findings

### [F#.M] Title — severity: blocker|concern|nit
- **Flow:** N
- **Location:** [tool/file/line if applicable]
- **Evidence:** [the actual error/output excerpt]
- **Why it matters:** [link to F1 #1]
- **Proposed handoff:** "[handoff title]"

## Clean Areas
[flows that ran cleanly and what they prove]
```

## Severity Calibration

- `blocker` — flow does not produce usable output for its consumer (maps to F1 #1).
- `concern` — flow works but degrades, warns, or returns degraded data.
- `nit` — cosmetic.
- `UNRUNNABLE` — tool not installed or environment can't run it. Informational; not a fail.

## Verify Script

Pair with `verify-lane<N>-end-to-end-smoke.sh` (template at [templates/audits/verify-end-to-end-smoke.sh](verify-end-to-end-smoke.sh)).

The verify script confirms:
- Findings file exists and has the 5 required sections
- At least one flow verdict is recorded
- `septa/validate-all.sh` is still green (sanity check)

## Style Notes

- Don't propose fixes beyond a one-line handoff title.
- Don't escalate cosmetic warnings to blockers.
- If a tool is missing, mark UNRUNNABLE — do not chase the install.
- Capture output verbatim or as a tight summary. Don't paraphrase errors.
