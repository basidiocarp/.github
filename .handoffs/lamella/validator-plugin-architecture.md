# Lamella: Validator Plugin Architecture

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/scripts/` (new validate-*.sh scripts), `lamella/Makefile` (extend validate target), `lamella/schemas/` (output format schema if it does not exist)
- **Cross-repo edits:** none
- **Non-goals:** does not change skill or hook content; does not add a Rust codebase to lamella; does not gate the marketplace build on validator output in this handoff
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by agnix Wave 2 audit and wave2-ecosystem-synthesis Theme 4 (Permission and Tool Governance):

> "405 rules organized by validator providers, each with evidence-driven rule design — source citation, normative level (MUST/SHOULD/MAY), test coverage per rule. The ValidatorProvider SPI is what makes the rule set evolvable without touching the core runner."
> — agnix Wave 2 audit, ValidatorProvider section

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:**
  - `Makefile` — the `validate` target; extend to discover and run all `validate-*.sh` providers
  - `scripts/` or `scripts/ci/` — new `validate-skills.sh`, `validate-hooks.sh`, `validate-agents.sh` scripts
  - `schemas/` — optional: add a JSON schema for the standard findings output format
- **Reference seams:**
  - `lamella/Makefile` — read the current `validate` target to understand what it runs and how it reports failures
  - `lamella/scripts/ci/` — read existing CI validation scripts to understand current conventions before adding new ones
  - `lamella/resources/hooks/hooks.json` — the hook manifest; `validate-hooks.sh` will read this
  - `lamella/resources/skills/` — skill documents; `validate-skills.sh` will read these
- **Spawn gate:** do a short seam-finding pass first — read the current `make validate` target and `scripts/ci/` to understand existing validation conventions, then spawn

## Problem

Lamella's current `make validate` runs monolithic validation logic concentrated in `scripts/ci/`. Adding a new validation concern — for example, checking that all skills have a required frontmatter field, or that all hook entries reference files that exist — requires modifying shared CI scripts. There is no well-defined extension point, no standard output format, and no way to run a single validator in isolation during development.

The agnix pattern of ValidatorProvider SPI solves this cleanly: each validator is a standalone script with a known naming convention, produces structured JSON output in a standard findings format, and is discovered and run automatically by the validate target. Validators can be added, removed, or iterated independently.

## What needs doing (intent)

Add a pluggable validator architecture to lamella:

1. Define a standard findings output format (JSON with a `findings` array) that all validators must emit
2. Define the naming convention: any executable `scripts/validate-<domain>.sh` is a validator provider
3. Implement three initial providers: `validate-skills.sh`, `validate-hooks.sh`, `validate-agents.sh`
4. Update `make validate` to discover all `validate-*.sh` scripts and run them in sequence, collecting findings and failing on any `MUST`-level violation
5. Add certainty annotation to findings: `HIGH` for `MUST` violations, `MEDIUM` for `SHOULD`, `LOW` for `MAY`

## Output Format

Each validator script must write a JSON object to stdout:

```json
{
  "validator": "validate-skills",
  "findings": [
    {
      "rule_id": "skill-001",
      "level": "MUST",
      "certainty": "HIGH",
      "file": "resources/skills/some-skill.md",
      "message": "Skill document missing required 'activation' frontmatter field",
      "normative_source": "lamella skill authoring guide"
    }
  ]
}
```

Exit code: `0` if no `MUST`-level findings; `1` if any `MUST`-level finding is present. `SHOULD` and `MAY` findings are reported but do not cause a non-zero exit on their own.

## Scope

- **Allowed files:**
  - `lamella/scripts/validate-skills.sh` (new)
  - `lamella/scripts/validate-hooks.sh` (new)
  - `lamella/scripts/validate-agents.sh` (new)
  - `lamella/Makefile` — extend the `validate` target
  - `lamella/schemas/findings.schema.json` (new, optional) — JSON schema for the findings format
- **Explicit non-goals:**
  - No Rust codebase added to lamella
  - No changes to skill, hook, or agent content
  - No marketplace build gate on validator output in this handoff
  - No per-rule test harness — validators are shell scripts, not test suites

---

### Step 1: Read the current validate seam

**Project:** `lamella/`
**Effort:** tiny (read-only)
**Depends on:** nothing

Before writing any script, read:
- `Makefile` — what does the `validate` target currently run? What does it check? Does it already discover scripts by naming convention?
- `scripts/ci/` — what validation logic already exists? What format does it use for errors?
- `resources/hooks/hooks.json` — what fields does a hook entry have?
- `resources/skills/` — pick two or three skill documents and read their frontmatter

Do not write any code in this step.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -10
```

**Checklist:**
- [ ] Current `validate` target behavior understood
- [ ] Existing CI validation scripts reviewed
- [ ] Hook manifest structure understood
- [ ] Skill frontmatter fields identified (required vs optional)

---

### Step 2: Define the findings format and discovery convention

**Project:** `lamella/`
**Effort:** tiny
**Depends on:** Step 1

Document the findings JSON format and the naming convention in a brief comment block at the top of each new script (no separate doc file needed — the format lives in the scripts themselves). Optionally write `schemas/findings.schema.json` if lamella already has a `schemas/` directory.

Naming convention: `scripts/validate-<domain>.sh`, executable, writes JSON to stdout, exits 0 or 1 per the output format rules above.

Update `Makefile` so the `validate` target:
1. Uses a glob or `find` to discover all `scripts/validate-*.sh` files
2. Runs each in sequence
3. Collects findings (parse JSON or check exit codes)
4. Fails the overall target if any script exits non-zero

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -10
```

**Checklist:**
- [ ] Makefile discovery loop in place
- [ ] `make validate` runs without error (even with no validators present yet)

---

### Step 3: Implement `validate-skills.sh`

**Project:** `lamella/`
**Effort:** small
**Depends on:** Step 2

Write `scripts/validate-skills.sh`. Rules to check (derive exact field names from Step 1 seam-finding):

- **skill-001 MUST**: every skill document in `resources/skills/` has a non-empty `name` (or equivalent identifier) in its frontmatter
- **skill-002 MUST**: every skill document has a non-empty description or purpose field in its frontmatter
- **skill-003 SHOULD**: every skill document has an `activation` or `trigger` field describing when it is invoked
- **skill-004 MAY**: every skill document has an examples section

Output the findings JSON to stdout. Exit 1 if any MUST-level finding is present.

#### Verification

```bash
cd lamella && bash scripts/validate-skills.sh 2>&1 | head -30
cd lamella && make validate 2>&1 | tail -10
```

**Checklist:**
- [ ] `validate-skills.sh` runs and emits valid JSON
- [ ] MUST violations produce exit code 1
- [ ] SHOULD/MAY findings produce exit code 0
- [ ] `make validate` picks up the script automatically

---

### Step 4: Implement `validate-hooks.sh`

**Project:** `lamella/`
**Effort:** small
**Depends on:** Step 2

Write `scripts/validate-hooks.sh`. Rules to check against `resources/hooks/hooks.json`:

- **hook-001 MUST**: every hook entry has a `type` field with a recognized value (`PreToolUse`, `PostToolUse`, `Stop`, `SessionEnd`, or equivalent values present in the manifest)
- **hook-002 MUST**: every hook entry that references a script file has a `script` or equivalent field, and the referenced path exists relative to the lamella root
- **hook-003 SHOULD**: every hook entry has a `description` field
- **hook-004 MAY**: every hook entry has a `matcher` or trigger condition field

Use `jq` for JSON parsing if available; fall back to `python3 -m json.tool` for basic validation if `jq` is absent.

#### Verification

```bash
cd lamella && bash scripts/validate-hooks.sh 2>&1 | head -30
cd lamella && make validate 2>&1 | tail -10
```

**Checklist:**
- [ ] `validate-hooks.sh` runs and emits valid JSON
- [ ] Missing referenced script files are flagged as MUST violations
- [ ] `make validate` picks up the script automatically

---

### Step 5: Implement `validate-agents.sh`

**Project:** `lamella/`
**Effort:** small
**Depends on:** Step 2

Write `scripts/validate-agents.sh`. If lamella has an agent manifest or agent document directory, apply equivalent rules. If no agent manifest exists yet, emit an empty findings array and exit 0 — the validator is a placeholder that will gain rules when the agent manifest is added.

Rules (if agent manifest exists):
- **agent-001 MUST**: every agent entry has a `name` field
- **agent-002 MUST**: every agent entry has a `description` field
- **agent-003 SHOULD**: every agent entry has a `scope` or `owning-repo` field
- **agent-004 MAY**: every agent entry has a `handoff-slug` reference

#### Verification

```bash
cd lamella && bash scripts/validate-agents.sh 2>&1 | head -20
cd lamella && make validate 2>&1 | tail -10
```

**Checklist:**
- [ ] `validate-agents.sh` runs and emits valid JSON (empty findings if no manifest)
- [ ] `make validate` picks up the script automatically
- [ ] No spurious failures from missing optional manifest

---

### Step 6: Full suite

```bash
cd lamella && make validate 2>&1 | tail -10
cd lamella && make build-marketplace 2>&1 | tail -10
```

**Checklist:**
- [ ] `make validate` runs all three validators and reports findings
- [ ] `make validate` exits 0 when no MUST-level violations are present
- [ ] `make build-marketplace` still succeeds (validator changes are additive)

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `make validate` discovers and runs all three validator scripts
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated to reflect completion

## Follow-on

- Gate the marketplace build on `make validate` once the validator output is stable and false-positive rates are known
- Add `validate-contracts.sh` to check septa schema fixtures against lamella-consumed schemas
- Expand `validate-skills.sh` with rules from the lamella skill authoring guide as that guide is formalized
- Add a `--fix` mode to validators that can auto-add missing optional fields with placeholder values

## Context

Spawned from agnix Wave 2 audit (2026-04-23) and wave2-ecosystem-synthesis Theme 4. Lamella's existing `make validate` is monolithic — adding a new validation concern requires touching shared CI scripts with no defined extension point. The agnix ValidatorProvider pattern (a naming convention plus a standard output format) gives each concern its own script, makes validators independently runnable during development, and keeps the discovery loop thin. This is a lamella-native shell-script convention, not a Rust code change.
