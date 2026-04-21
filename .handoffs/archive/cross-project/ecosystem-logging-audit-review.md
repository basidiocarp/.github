# Cross-Project Ecosystem Logging Audit Review

## Status

Complete. Audit collection finished, the per-repo reports and synthesis were
produced, and the follow-up hardening pass named in the audit has now landed.

## Problem

The ecosystem now has a shared `spore` logging and tracing contract plus a
rollout handoff, but there is no consistent review loop that checks whether
each repo is actually using it well. Without a bounded audit pattern, reviews
either miss fragile areas or accumulate too much context across repos.

## What exists (state)

- **`spore/src/logging.rs`:** shared logging and tracing helpers for
  app-specific init, span context, and standardized root/request/tool/workflow
  boundaries.
- **`cross-project/ecosystem-logging-rollout.md`:** implementation handoff for
  rolling the shared logging contract into each repo.
- **Current gap:** there is no reviewer-oriented handoff that audits one repo at
  a time, checks whether the new `spore` logger and tracer are being used well,
  and highlights fragile or under-instrumented boundaries before the rollout
  expands.

## What needs doing (intent)

This handoff created a reviewer-led audit loop for the logging rollout.

The reviewer agent owns synthesis and does not implement fixes. It uses exactly
two fresh read-only subagents at a time. Each subagent audits only:

- `spore/`
- one target repo

After a subagent returns its report, close it. Do not reuse the same subagent
for the next repo. Spawn a fresh subagent for the next repo so context stays
bounded and audits do not drift.

The target outcome is:

- one per-repo audit report
- one ecosystem summary report
- concrete findings about missing `spore` adoption, weak tracing coverage,
  fragile boundaries, and doc/runtime drift
- follow-up handoffs created only when the audit finds real work that should be
  tracked separately

---

### Step 1: Establish The Audit Rubric And Output Layout

**Project:** `cross-project/`
**Effort:** 30-45 minutes
**Depends on:** nothing

Set up the audit output layout before reviewing repos. The reviewer agent should
create:

- `.handoffs/archive/campaigns/logging-audit/summary.md`
- `.handoffs/archive/campaigns/logging-audit/rhizome.md`
- `.handoffs/archive/campaigns/logging-audit/hyphae.md`
- `.handoffs/archive/campaigns/logging-audit/mycelium.md`
- `.handoffs/archive/campaigns/logging-audit/cortina.md`
- `.handoffs/archive/campaigns/logging-audit/canopy.md`
- `.handoffs/archive/campaigns/logging-audit/stipe.md`
- `.handoffs/archive/campaigns/logging-audit/volva.md`

Each per-repo report should use the same sections:

- `## Status`
- `## Coverage`
- `## Findings`
- `## Fragile Areas`
- `## Recommendations`

The summary report should include:

- audit queue and round order
- which two repos were reviewed in each round
- explicit note that each repo audit used a fresh subagent
- overall rollout health
- priority-sorted follow-up items

#### Files to modify

**`.handoffs/archive/campaigns/logging-audit/summary.md`** — final synthesis across
all audited repos, including queue, round structure, and follow-up backlog.

**`.handoffs/archive/campaigns/logging-audit/<repo>.md`** — one report per repo
using the shared section layout above.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
mkdir -p .handoffs/archive/campaigns/logging-audit
ls -1 .handoffs/archive/campaigns/logging-audit
```

**Output:**
<!-- PASTE START -->
canopy.md
cortina.md
hyphae.md
mycelium.md
rhizome.md
stipe.md
summary.md
volva.md

<!-- PASTE END -->

**Checklist:**
- [x] the audit output directory exists
- [x] there is one report path reserved for each target repo
- [x] there is one ecosystem summary report path
- [x] the per-repo report structure is standardized

---

### Step 2: Audit Repos In Two-Subagent Rounds

**Project:** `spore/` plus one target repo per subagent
**Effort:** 4-6 hours total
**Depends on:** Step 1

Run the audit as a bounded review workflow, not as one giant exploration.

#### Required orchestration rules

- The lead reviewer agent stays read-only and owns the synthesis.
- Use at most **two fresh subagents** at the same time.
- Each subagent audits **one target repo at a time**.
- Each subagent may read only `spore/` plus its assigned target repo.
- After a subagent reports back, close it.
- For the next repo, spawn a **new fresh subagent** rather than reusing the old
  one.
- Do not let subagents drift into sibling repos outside their assignment.

#### Suggested queue

Start with the repos in the rollout queue:

1. `rhizome`
2. `hyphae`
3. `mycelium`
4. `cortina`
5. `canopy`
6. `stipe`
7. `volva`

#### Subagent audit prompt shape

Each subagent should be told to audit whether the target repo:

- uses the shared `spore` init path correctly
- exposes or documents its repo-specific log knob such as `<APP>_LOG`
- creates spans where failure locality matters
- uses stable context fields such as `service`, `tool`, `request_id`,
  `session_id`, and `workspace_root` when available
- keeps stdout/stderr safe for MCP, hooks, or subprocess surfaces
- documents runtime behavior accurately

Each subagent should specifically look for fragile or under-instrumented areas
such as:

- CLI startup and serve loops
- MCP request dispatch
- subprocess execution
- retries and background tasks
- workflow orchestration
- persistence or store writes
- hook/lifecycle handlers
- adapters and long-running async boundaries

Each subagent must return findings first, with file references and severity,
then concise recommendations. No code changes in this handoff.

#### Files to modify

**`.handoffs/archive/campaigns/logging-audit/<repo>.md`** — record the audit result
for that repo, including concrete file references, missing coverage, fragile
areas, and recommended follow-up.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
rg -n '^## (Status|Coverage|Findings|Fragile Areas|Recommendations)$' .handoffs/archive/campaigns/logging-audit/*.md
rg -n 'fresh subagent|two fresh subagents|one target repo at a time|spore/' .handoffs/archive/campaigns/logging-audit/summary.md
```

**Output:**
<!-- PASTE START -->
.handoffs/campaigns/logging-audit/cortina.md:3:## Status
.handoffs/campaigns/logging-audit/cortina.md:7:## Coverage
.handoffs/campaigns/logging-audit/cortina.md:13:## Findings
.handoffs/campaigns/logging-audit/cortina.md:20:## Fragile Areas
.handoffs/campaigns/logging-audit/cortina.md:27:## Recommendations
.handoffs/campaigns/logging-audit/hyphae.md:3:## Status
.handoffs/campaigns/logging-audit/hyphae.md:7:## Coverage
.handoffs/campaigns/logging-audit/hyphae.md:13:## Findings
.handoffs/campaigns/logging-audit/hyphae.md:20:## Fragile Areas
.handoffs/campaigns/logging-audit/hyphae.md:27:## Recommendations
.handoffs/campaigns/logging-audit/canopy.md:3:## Status
.handoffs/campaigns/logging-audit/canopy.md:7:## Coverage
.handoffs/campaigns/logging-audit/canopy.md:13:## Findings
.handoffs/campaigns/logging-audit/canopy.md:20:## Fragile Areas
.handoffs/campaigns/logging-audit/canopy.md:27:## Recommendations
.handoffs/campaigns/logging-audit/volva.md:3:## Status
.handoffs/campaigns/logging-audit/volva.md:7:## Coverage
.handoffs/campaigns/logging-audit/volva.md:13:## Findings
.handoffs/campaigns/logging-audit/volva.md:19:## Fragile Areas
.handoffs/campaigns/logging-audit/volva.md:26:## Recommendations
.handoffs/campaigns/logging-audit/rhizome.md:3:## Status
.handoffs/campaigns/logging-audit/rhizome.md:7:## Coverage
.handoffs/campaigns/logging-audit/rhizome.md:13:## Findings
.handoffs/campaigns/logging-audit/rhizome.md:19:## Fragile Areas
.handoffs/campaigns/logging-audit/rhizome.md:26:## Recommendations
.handoffs/campaigns/logging-audit/mycelium.md:3:## Status
.handoffs/campaigns/logging-audit/mycelium.md:7:## Coverage
.handoffs/campaigns/logging-audit/mycelium.md:13:## Findings
.handoffs/campaigns/logging-audit/mycelium.md:20:## Fragile Areas
.handoffs/campaigns/logging-audit/mycelium.md:27:## Recommendations
.handoffs/campaigns/logging-audit/stipe.md:3:## Status
.handoffs/campaigns/logging-audit/stipe.md:7:## Coverage
.handoffs/campaigns/logging-audit/stipe.md:13:## Findings
.handoffs/campaigns/logging-audit/stipe.md:21:## Fragile Areas
.handoffs/campaigns/logging-audit/stipe.md:28:## Recommendations
13:- Each round used exactly two fresh subagents.
14:- Each subagent audited only `spore/` plus one target repo at a time.
31:- Round 1 used two fresh subagents:
32:  - `spore/` + `rhizome/` -> `partial`
33:  - `spore/` + `hyphae/` -> `partial`
34:- Round 2 used two fresh subagents:
35:  - `spore/` + `mycelium/` -> `partial`
36:  - `spore/` + `cortina/` -> `partial`
37:- Round 3 used two fresh subagents:
38:  - `spore/` + `canopy/` -> `partial`
39:  - `spore/` + `stipe/` -> `partial`
40:- Round 4 used one fresh subagent:
41:  - `spore/` + `volva/` -> `partial`

<!-- PASTE END -->

**Checklist:**
- [x] every target repo has its own audit report
- [x] the reviewer used no more than two fresh subagents at once
- [x] each repo audit was limited to `spore/` plus one target repo
- [x] each finished repo used a new fresh subagent rather than reusing context
- [x] every report calls out both current coverage and fragile or missing areas

---

### Step 3: Synthesize Ecosystem Findings And Follow-Up Work

**Project:** `cross-project/`
**Effort:** 1-2 hours
**Depends on:** Step 2

Once all repo audits are complete, the reviewer agent should write the summary
report as the source of truth for rollout quality.

The summary should include:

- a table of repo status: `good`, `partial`, `missing`, or `not started`
- the most important cross-repo gaps
- repeated fragile patterns across repos
- where the `spore` contract is strong enough versus where it may still need
  improvement
- whether any follow-up handoffs should be created

If a repo is missing coverage in a way that clearly needs implementation, create
a focused follow-up handoff rather than burying the work in prose.

#### Files to modify

**`.handoffs/campaigns/logging-audit/summary.md`** — final summary and
follow-up backlog for the ecosystem logging review.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
rg -n '^## ' .handoffs/campaigns/logging-audit/summary.md
rg -n 'rhizome|hyphae|mycelium|cortina|canopy|stipe' .handoffs/campaigns/logging-audit/summary.md
```

**Output:**
<!-- PASTE START -->
3:## Queue
10:## Audit Method
17:## Rollout Health
29:## Round Results
43:## Cross-Repo Findings
51:## Follow-Up Work
5:- Round 1: `rhizome`, `hyphae`
6:- Round 2: `mycelium`, `cortina`
7:- Round 3: `canopy`, `stipe`
19:- `rhizome`: `partial`
20:- `hyphae`: `partial`
21:- `mycelium`: `partial`
22:- `cortina`: `partial`
23:- `canopy`: `partial`
24:- `stipe`: `partial`
32:  - `spore/` + `rhizome/` -> `partial`
33:  - `spore/` + `hyphae/` -> `partial`
35:  - `spore/` + `mycelium/` -> `partial`
36:  - `spore/` + `cortina/` -> `partial`
38:  - `spore/` + `canopy/` -> `partial`
39:  - `spore/` + `stipe/` -> `partial`
46:- Several repos still lose child-process diagnostics. `mycelium`, `cortina`, and `stipe` all have paths where subprocess stderr is discarded or reduced to a boolean result, which weakens operator debugging.
47:- Stable context propagation is inconsistent. `session_id`, `request_id`, `tool`, and `workspace_root` are not threaded or normalized consistently enough in `hyphae`, `canopy`, `stipe`, and `volva`.
48:- Doc/runtime drift remains common. `rhizome`, `cortina`, and `canopy` all overstate or misdescribe the real behavior of repo-specific log knobs or stderr-controlled diagnostics.
49:- Some of the highest-risk issues are correctness issues that happen to intersect logging, not just missing trace calls. The clearest examples are `mycelium` plugin fallback double-execution risk, `cortina` evidence bridge durability, and `stipe init --json` not being stdout-pure.
55:  - `mycelium`: fix plugin fallback correctness and preserve child stderr
56:  - `cortina`: make evidence attachment durable and improve adapter-boundary tracing
57:  - `stipe`: make `init --json` stdout-pure and extend tracing beyond release verification
58:  - `hyphae`: propagate `session_id` and `workspace_root` through deeper workflow and write paths
59:  - `rhizome`: align docs with `RHIZOME_LOG` and add missing subprocess boundaries
60:  - `canopy`: make boundary spans emit under normal settings and cover verification/polling paths

<!-- PASTE END -->

**Checklist:**
- [x] the summary names every audited repo
- [x] the summary includes rollout status and cross-repo findings
- [x] the summary calls out fragile patterns, not just missing API usage
- [x] follow-up work is split into focused handoffs when needed

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes:
   `bash .handoffs/cross-project/verify-ecosystem-logging-audit-review.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/cross-project/verify-ecosystem-logging-audit-review.sh
```

**Output:**
<!-- PASTE START -->
PASS: Summary report exists
PASS: Summary report describes bounded fresh-subagent review flow
PASS: Report exists for rhizome
PASS: Report for rhizome has Status section
PASS: Report for rhizome has Coverage section
PASS: Report for rhizome has Findings section
PASS: Report for rhizome has Fragile Areas section
PASS: Report for rhizome has Recommendations section
PASS: Report for rhizome mentions spore logging contract or tracing coverage
PASS: Report exists for hyphae
PASS: Report for hyphae has Status section
PASS: Report for hyphae has Coverage section
PASS: Report for hyphae has Findings section
PASS: Report for hyphae has Fragile Areas section
PASS: Report for hyphae has Recommendations section
PASS: Report for hyphae mentions spore logging contract or tracing coverage
PASS: Report exists for mycelium
PASS: Report for mycelium has Status section
PASS: Report for mycelium has Coverage section
PASS: Report for mycelium has Findings section
PASS: Report for mycelium has Fragile Areas section
PASS: Report for mycelium has Recommendations section
PASS: Report for mycelium mentions spore logging contract or tracing coverage
PASS: Report exists for cortina
PASS: Report for cortina has Status section
PASS: Report for cortina has Coverage section
PASS: Report for cortina has Findings section
PASS: Report for cortina has Fragile Areas section
PASS: Report for cortina has Recommendations section
PASS: Report for cortina mentions spore logging contract or tracing coverage
PASS: Report exists for canopy
PASS: Report for canopy has Status section
PASS: Report for canopy has Coverage section
PASS: Report for canopy has Findings section
PASS: Report for canopy has Fragile Areas section
PASS: Report for canopy has Recommendations section
PASS: Report for canopy mentions spore logging contract or tracing coverage
PASS: Report exists for stipe
PASS: Report for stipe has Status section
PASS: Report for stipe has Coverage section
PASS: Report for stipe has Findings section
PASS: Report for stipe has Fragile Areas section
PASS: Report for stipe has Recommendations section
PASS: Report for stipe mentions spore logging contract or tracing coverage
PASS: Summary mentions rhizome
PASS: Summary mentions hyphae
PASS: Summary mentions mycelium
PASS: Summary mentions cortina
PASS: Summary mentions canopy
PASS: Summary mentions stipe
Results: 50 passed, 0 failed

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete with
failures.

## Context

This handoff is the review counterpart to
`cross-project/ecosystem-logging-rollout.md`. Use it to audit the quality of
the rollout without letting one reviewer or subagent accumulate the full
ecosystem context. The key operating constraint is deliberate turnover: two
fresh subagents maximum at a time, one target repo each, then retire them and
spawn fresh reviewers for the next repos.
