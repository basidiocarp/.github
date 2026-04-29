# Audit Lane 1: Boundary Compliance

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only across all subprojects)
- **Allowed write scope:** `.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane1-boundary-compliance.md`
- **Cross-repo edits:** none (read-only audit)
- **Non-goals:** does not fix any issues found, does not modify septa schemas, does not modify CLI coupling table
- **Verification contract:** run the repo-local commands below and `bash .handoffs/campaigns/post-execution-boundary-audit-2026-04-29/verify-lane1-boundary-compliance.sh`
- **Completion update:** once findings file is written and verification is green, update `.handoffs/HANDOFFS.md` campaigns row to reflect lane 1 complete

## Implementation Seam

- **Likely repo:** workspace root + all active hardening subprojects (cortina, hyphae, hymenium, mycelium, rhizome, septa, spore, stipe)
- **Likely files/modules:**
  - `septa/integration-patterns.md` (CLI Coupling Classification table — 10 active rows)
  - `AGENTS.md` (CLI boundary rule, 3-tier hierarchy from C8)
  - `*.rs` files in active hardening repos (grep for `Command::new`, sibling spawns, `process::Command`)
  - `cap/server/**/*.ts` (sibling CLI calls — exempt under operator surface but verify scope)
- **Reference seams:** `verify-cli-coupling-exemption-audit.sh` (the existing C7 verifier) and `verify-system-to-system-communication-boundary.sh` (C8)
- **Spawn gate:** the audit is read-only and the seam is well-known — proceed directly

## Problem

After C7 marked 4 CLI couplings as migrated and C8 wrote the 3-tier system-to-system rule into `AGENTS.md`, no one has re-verified that:

1. The 14→10 row reduction in `septa/integration-patterns.md` reflects the actual repo state
2. No new sibling-spawn call sites have appeared since the table was last updated
3. The C8 boundary rule is honored by the active hardening repos
4. Cap's operator-surface exemption is still scoped correctly (no creep into write paths that should go through endpoints)

## What exists (state)

- **C7 table:** 10 active rows in `septa/integration-patterns.md` "CLI Coupling Classification" + a "Recently Migrated" subsection with 4 entries from 2026-04-29
- **C8 boundary rule:** `AGENTS.md` codifies system-to-system → endpoint, hook-time → CLI exception, operator surface → CLI exempt
- **Existing verifiers:** `verify-cli-coupling-exemption-audit.sh` (C7) and `verify-system-to-system-communication-boundary.sh` (C8) — both pass on main
- **Frozen repos:** cap, canopy, hymenium, lamella, annulus, volva — under freeze per F1 — evaluate their **integration boundaries** only

## What needs doing (intent)

Produce a findings file enumerating:

- Stale rows in the C7 table (file moved/renamed, call site removed but row remains)
- New sibling-spawn call sites not present in the table (re-run the C7 logic against current `HEAD`)
- C8 violations: any `system → system` call that goes through CLI subprocess instead of `spore::LocalServiceClient` endpoint
- Operator-surface scope creep: cap routes that have started doing work outside the operator-broker pattern
- Documentation drift between `AGENTS.md`, `septa/integration-patterns.md`, and the actual repo state

Each finding gets a severity (`blocker | concern | nit`) and a proposed handoff title (the fix-phase work).

## Scope

- **Primary seam:** the cross-repo CLI/endpoint boundary as documented by C7 and C8
- **Allowed files:** read everything; write only `findings/lane1-boundary-compliance.md`
- **Explicit non-goals:**
  - Fixing any boundary violations found (those become new handoffs)
  - Auditing septa schema correctness (lane 2 owns that)
  - Triaging Low-priority handoffs (lane 3 owns that)
  - Auditing internal architecture of frozen repos

---

### Step 1: Re-run C7 + C8 verifiers and capture state

**Project:** workspace root
**Effort:** small
**Depends on:** nothing

Run both existing verifiers, capture output, and use that as the baseline before manual deeper inspection.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp && bash .handoffs/cross-project/verify-cli-coupling-exemption-audit.sh)
(cd /Users/williamnewton/projects/personal/basidiocarp && bash .handoffs/cross-project/verify-system-to-system-communication-boundary.sh)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Both verifiers exit 0
- [ ] Output captured in findings file under "Baseline"

---

### Step 2: Manual cross-repo sibling-spawn sweep

**Project:** workspace root
**Effort:** medium
**Depends on:** Step 1

Search for `Command::new`, `tokio::process::Command::new`, `Stdio`, and `child_process.spawn` across all active hardening repos. For each hit:

- Match against the C7 table — does the call site appear?
- Match against C8 — is it `system → system`, `hook → tool`, or operator-surface?
- Note any hit not classifiable by either rule.

#### Files to inspect

- `cortina/**/*.rs`
- `hyphae/**/*.rs`
- `hymenium/**/*.rs`
- `mycelium/**/*.rs`
- `rhizome/**/*.rs`
- `septa/**/*.rs` (if any)
- `spore/**/*.rs`
- `stipe/**/*.rs`
- `cap/server/**/*.ts` (operator-surface exemption — verify only that the calls are read paths or operator-brokered writes, not silent system-to-system)

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp && grep -rn "Command::new" cortina hyphae hymenium mycelium rhizome spore stipe --include="*.rs" | grep -v "clap::Command" | grep -v "/target/" | wc -l)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Every literal sibling spawn classified against C7 or C8
- [ ] Findings file lists each unclassified or stale call site

---

### Step 3: Documentation cross-check

**Project:** workspace root
**Effort:** small
**Depends on:** Step 2

Cross-check three documents for drift:

1. `septa/integration-patterns.md` — does its "Recently Migrated" section match git history for 2026-04-29 commits?
2. `AGENTS.md` — does the 3-tier hierarchy still match what C8 set up?
3. `docs/foundations/core-hardening-freeze-roadmap.md` (F1) — does the active/frozen repo split still match what's actively shipping?

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && git log --since="2026-04-28" --oneline integration-patterns.md)
(cd /Users/williamnewton/projects/personal/basidiocarp && grep -A5 "CLI boundary rule" AGENTS.md | head -30)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Documentation drift findings recorded with file paths and line numbers
- [ ] No new criteria invented beyond what F1 already lists

---

### Step 4: Write findings file

**Project:** workspace root
**Effort:** small
**Depends on:** Steps 1-3

Write `findings/lane1-boundary-compliance.md` with this structure:

```markdown
# Lane 1: Boundary Compliance Findings (2026-04-29)

## Summary
[1-2 sentences: how many findings, severity breakdown]

## Baseline
[verifier output from Step 1]

## Findings

### [F1.1] Title — severity: blocker|concern|nit
- **Location:** path:line
- **Evidence:** [what was found]
- **Why it matters:** [link to C7/C8/F1 criterion]
- **Proposed handoff:** "[handoff title]"

[repeat per finding]

## Clean Areas
[list checks that came back clean — useful for the fix-phase scoping decision]
```

#### Verification

```bash
test -f /Users/williamnewton/projects/personal/basidiocarp/.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane1-boundary-compliance.md && echo "findings file exists"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Findings file exists with the four sections (Summary, Baseline, Findings, Clean Areas)
- [ ] Each finding has location, evidence, criterion link, proposed handoff title
- [ ] No fixes attempted in this run

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/campaigns/post-execution-boundary-audit-2026-04-29/verify-lane1-boundary-compliance.sh`
3. All checklist items are checked
4. The campaign README's lane table is updated (lane 1 row marked complete) — or the parent flags it for closure

### Final Verification

```bash
bash .handoffs/campaigns/post-execution-boundary-audit-2026-04-29/verify-lane1-boundary-compliance.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Closes a known gap: C7/C8 set up the policy and the table, but no run has confirmed the post-migration state since the 2026-04-29 sweep. This audit feeds the fix phase that follows.

## Style Notes

- Findings are evidence-only. Do not propose fixes beyond a one-line "Proposed handoff" title.
- Severity calibration: a `blocker` should map to F1 exit criteria. A `concern` is real drift but does not block exit. A `nit` is a documentation refinement.
