# [Title]

<!-- Save as: .handoffs/<project>/<topic>.md -->
<!-- Create verify script: .handoffs/<project>/verify-<topic>.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

[1-3 sentences: what's broken or missing, and why it matters]

## What exists (state)

- **[Component]:** [Current state — what's built, what's not]
- **[File/Feature]:** [Current state]

## What needs doing (intent)

[High-level description of the work]

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
