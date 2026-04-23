# Lamella: Skill Progressive Disclosure Convention

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/` (conventions, docs, existing skill files); updates to skill frontmatter and file structure
- **Cross-repo edits:** none
- **Non-goals:** does not change how Claude Code loads skills; does not add a new runtime loader; does not change SKILL.md format beyond adding a `references/` convention
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by harness's 3-tier progressive disclosure model (audit: `.audit/external/audits/harness-ecosystem-borrow-audit.md`):

> "Skills use a 3-tier loading model: metadata+description always in context (cheap), SKILL.md loaded on trigger (medium), references/ directory loaded on demand (expensive, 300+ lines with nested ToC). This prevents context bloat while enabling deep detail."

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:**
  - `lamella/resources/` or equivalent — where SKILL.md files live
  - Authoring guide or README — where the convention is documented
  - An existing skill that can be refactored to demonstrate the pattern
- **Reference seams:**
  - harness `references/skill-writing-guide.md` as external pattern reference
  - Existing lamella SKILL.md files — read these first to understand current structure before adding
- **Spawn gate:** read the current lamella skill structure before spawning — identify the existing SKILL.md layout and any existing authoring guides

## Problem

Lamella skill files tend to be monolithic: all context (instructions, examples, architecture notes, edge cases) lives in one SKILL.md. As skills grow richer, this creates two failure modes:

1. **Context bloat**: large SKILL.md files are loaded in full even when only a subset is needed
2. **Discoverability gap**: context that should be available on demand (deep edge cases, architecture notes, extended examples) is either missing or always-loaded

Harness solves this with a three-tier loading model:
- **Tier 1** (always loaded): skill name, description, triggers — just enough for routing
- **Tier 2** (loaded on trigger): SKILL.md — the working instructions, concise enough to fit in context
- **Tier 3** (loaded on demand): `references/` directory — extended docs, examples, architecture notes

## What needs doing (intent)

Establish the three-tier convention as the standard for lamella skills:

1. Document the convention in lamella's authoring guide
2. Define the `references/` directory structure and naming convention
3. Refactor one existing skill to demonstrate the pattern
4. Add a validation check that SKILL.md files stay within a token budget (no runaway Tier 2)

## Tier structure

```
skills/
└── my-skill/
    ├── SKILL.md              # Tier 2: working instructions (≤ 200 lines recommended)
    └── references/
        ├── README.md         # Tier 3 index: what's in here and when to load it
        ├── architecture.md   # Extended architecture notes
        ├── examples.md       # Extended examples (>3 examples belong here, not in SKILL.md)
        └── edge-cases.md     # Edge cases and error handling
```

SKILL.md frontmatter should include a `references:` field listing available reference documents:

```yaml
---
name: my-skill
description: Short description for routing
triggers:
  - /my-skill
references:
  - references/architecture.md
  - references/examples.md
---
```

## Scope

- **Allowed files:** lamella authoring guide (update), one existing SKILL.md + new `references/` (refactor), validation script (new)
- **Explicit non-goals:**
  - No runtime loader changes — Claude Code already loads `references/` on demand when explicitly linked
  - No changes to SKILL.md schema beyond adding optional `references:` frontmatter field
  - No changes to how skills are packaged in lamella releases

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Read lamella before writing:
1. Where do SKILL.md files live? (`lamella/resources/`, `lamella/skills/`, or similar?)
2. Is there an existing authoring guide? (AUTHORING.md, CONTRIBUTING.md, or README?)
3. Pick one existing skill that is the best candidate for demonstrating the pattern (>100 lines, could benefit from a `references/` directory)

---

### Step 1: Document the convention

**Project:** `lamella/`
**Effort:** small
**Depends on:** Step 0

Add or update the lamella authoring guide to define the three-tier convention. Key points to cover:

- What belongs in each tier
- The `references/` directory structure and `README.md` index requirement
- The `references:` frontmatter field for listing available reference docs
- Token budget guidance: Tier 2 (SKILL.md) should stay under ~200 lines; overflow goes in `references/`

#### Verification

```bash
grep -l "references" lamella/*/SKILL.md 2>/dev/null || echo "no skills have references yet"
```

**Checklist:**
- [ ] Authoring guide updated with three-tier convention
- [ ] `references/` directory structure defined
- [ ] Frontmatter `references:` field documented

---

### Step 2: Refactor one skill to demonstrate the pattern

**Project:** `lamella/`
**Effort:** small
**Depends on:** Step 1

Take the skill identified in Step 0 and refactor it:
1. Keep SKILL.md concise (working instructions only, ≤200 lines)
2. Move extended architecture notes to `references/architecture.md`
3. Move extended examples to `references/examples.md`
4. Add `references/README.md` as an index
5. Add `references:` frontmatter to SKILL.md

The refactor should not change the skill's behavior — it is a reorganization only.

#### Verification

```bash
wc -l path/to/skill/SKILL.md  # should be ≤200 lines
ls path/to/skill/references/  # should have README.md + at least one reference doc
```

**Checklist:**
- [ ] SKILL.md ≤200 lines after refactor
- [ ] `references/` directory has README.md index
- [ ] `references:` frontmatter field present in SKILL.md

---

### Step 3: Add a token budget check script

**Project:** `lamella/`
**Effort:** small
**Depends on:** Step 2

Create `scripts/check-skill-sizes.sh` that checks all SKILL.md files for line count. Warn (not fail) if any SKILL.md exceeds the recommended 200-line budget. This is informational — skills can exceed the budget if they need to, but the check surfaces candidates for `references/` refactoring.

```bash
#!/usr/bin/env bash
# Check SKILL.md files for token budget compliance
WARN_LIMIT=200
FAILED=0

for f in $(find . -name "SKILL.md" -not -path "*/archive/*"); do
    lines=$(wc -l < "$f")
    if [ "$lines" -gt "$WARN_LIMIT" ]; then
        echo "WARN: $f has $lines lines (budget: $WARN_LIMIT) — consider moving extended content to references/"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
if [ "$FAILED" -gt 0 ]; then
    echo "$FAILED skill(s) exceed the recommended budget. Review for references/ candidates."
else
    echo "All SKILL.md files within budget."
fi
```

#### Verification

```bash
cd lamella && bash scripts/check-skill-sizes.sh
```

**Checklist:**
- [ ] Script runs without error
- [ ] Refactored skill passes (≤200 lines)

---

### Step 4: Full suite

```bash
cd lamella && make validate 2>&1 | tail -20
```

**Checklist:**
- [ ] Lamella validation passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Convention documented in authoring guide
2. One skill refactored to demonstrate the pattern
3. Token budget check script added
4. Lamella validation passes
5. `.handoffs/HANDOFFS.md` updated to reflect completion

## Follow-on work (not in scope here)

- Refactor remaining over-budget skills to use `references/`
- Add `references:` frontmatter validation to lamella's existing validation pipeline
- Document the pattern in CLAUDE.md and AGENTS.md for skill authors

## Context

Spawned from Wave 2 audit program (2026-04-23). harness demonstrates that skill context bloat is solved by tiered loading, not by writing shorter skills. The three-tier model keeps Tier 2 (SKILL.md) small and fast to load, while making Tier 3 (references/) available on demand for operators who need the depth. This is a convention change, not a runtime change — no loader modifications required.
