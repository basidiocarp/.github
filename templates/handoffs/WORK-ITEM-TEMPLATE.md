# [Title]

<!-- Save as: .handoffs/<project>/<topic>.md -->
<!-- Create verify script: .handoffs/<project>/verify-<topic>.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `[repo-name]`
- **Allowed write scope:** `[repo]/...`
- **Cross-repo edits:** `none` | `[allowed repo paths only]`
- **Non-goals:** [1 short sentence stating what this handoff does not include]
- **Verification contract:** run the repo-local commands below and `bash .handoffs/<project>/verify-<topic>.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `[repo-name]`
- **Likely files/modules:** [name the most likely files or modules to change; if exact files are not known yet, name the owning seam and tighten this before spawning an implementer]
- **Reference seams:** [existing files, commands, or surfaces to imitate rather than parallel implementations]
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

[1-3 sentences: what's broken or missing, and why it matters]

## What exists (state)

- **[Component]:** [Current state — what's built, what's not]
- **[File/Feature]:** [Current state]

## What needs doing (intent)

[High-level description of the work]

## Scope

- **Primary seam:** [the one subsystem or boundary this handoff owns]
- **Allowed files:** [specific paths or path prefixes]
- **Explicit non-goals:** [bullets for nearby work that should not be folded into this handoff]

---

### Step 1: [Step Title]

**Project:** `[directory/]`
**Effort:** [estimate]
**Depends on:** [nothing / Step N]

[Description of what to do, with code snippets if helpful]

#### Files to modify

**`path/to/file`** — [what to change]:

```
[code snippet or pseudocode]
```

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

<!-- AGENT: Run the command and paste output between the markers -->
```bash
[verification command]
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] [Specific, testable assertion]
- [ ] [Specific, testable assertion]

---

### Step 2: [Step Title]

[Repeat structure for each step]

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/<project>/verify-<topic>.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/<project>/verify-<topic>.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

[Why this work exists, links to related handoffs or issues]

## Style Notes

- Prefer one repo, one primary seam, and one verification surface per handoff.
- If the work spans multiple repos or phases, create an umbrella handoff and split it into child handoffs before dispatch.
- Use `Dispatch: umbrella` only for decomposition or coordination notes. Umbrella handoffs should not be sent to implementers directly.
