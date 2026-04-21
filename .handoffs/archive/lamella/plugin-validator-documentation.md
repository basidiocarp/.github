# Plugin Validator Documentation

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** reverse-engineering the Claude Code validator internals, changing plugin build logic, or creating new plugins
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-plugin-validator-documentation.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** `lamella/docs/plugin-validator-reference.md` as the new reference doc; `lamella/docs/` index for registration
- **Reference seams:** ECC `.claude-plugin/PLUGIN_SCHEMA_NOTES.md` for observed constraints, anti-patterns, and known-good examples
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The Claude Code plugin validator has undocumented constraints that cause silent failures. Directory paths are rejected — only explicit file paths are accepted. The hooks field flip-flopped across 4 releases, causing duplicate errors in some versions when the field is present. Certain frontmatter formats are silently ignored without error. This tribal knowledge exists in ECC's `PLUGIN_SCHEMA_NOTES.md` but is absent from the basidiocarp ecosystem. Every lamella contributor working with plugins must rediscover these constraints through trial and error, or copy-paste from ECC without understanding the underlying rules.

## What exists (state)

- **`lamella`:** has plugin packaging and `make validate`; no documentation of validator constraints or anti-patterns
- **ECC reference:** `PLUGIN_SCHEMA_NOTES.md` with documented constraints, hooks registration behavior, known-good minimal examples, and a list of observed silent failures

## What needs doing (intent)

1. Create `lamella/docs/plugin-validator-reference.md` as a living reference for Claude Code plugin validator constraints observed in practice.
2. Populate it with known constraints: file path vs directory path rules, hooks field behavior across versions, frontmatter formats that are silently ignored, and other failure modes from the ECC reference.
3. Include known-good minimal examples (what definitely works) and known-bad examples (what silently fails or causes errors).
4. Register the new document in the lamella docs index so contributors can find it.

## Scope

- **Primary seam:** documentation of observed plugin validator behavior
- **Allowed files:** `lamella/docs/plugin-validator-reference.md` and the lamella docs index
- **Explicit non-goals:**
  - Do not reverse-engineer the validator; document observed behavior only
  - Do not change plugin build logic or the validator itself
  - Do not create new plugins in this handoff

---

### Step 1: Create the plugin validator reference document

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** nothing

Create `lamella/docs/plugin-validator-reference.md`. The document must cover:

- **File path constraints:** why directory paths are rejected and what the correct form looks like
- **Hooks field behavior:** the version-by-version history of the hooks field, which versions cause duplicate errors, and the current safe default
- **Frontmatter formats:** which formats are silently ignored and which are processed
- **Other observed silent failures:** any additional constraints from the ECC reference

Structure the document as a living reference: include a "Last validated against" version field and a "Known open questions" section for unresolved behavior.

#### Verification

```bash
cd lamella && test -f docs/plugin-validator-reference.md && echo "reference doc exists"
```

**Checklist:**
- [ ] Reference document exists at `lamella/docs/plugin-validator-reference.md`
- [ ] File path vs directory path constraint is documented
- [ ] Hooks field version history is documented
- [ ] Silent frontmatter failures are documented
- [ ] "Last validated against" version field is present
- [ ] "Known open questions" section is present

---

### Step 2: Add known-good and known-bad examples

**Project:** `lamella/`
**Effort:** 0.25 day
**Depends on:** Step 1

Add a section to the reference document with minimal known-good examples (the smallest plugin definition that passes validation) and known-bad examples (definitions that silently fail or produce confusing errors). Each example must include an explanation of why it works or fails.

#### Verification

```bash
cd lamella && grep -c "known-good\|known-bad\|example" docs/plugin-validator-reference.md 2>&1
```

**Checklist:**
- [ ] At least one known-good minimal example is present
- [ ] At least one known-bad example is present with explanation
- [ ] Each example has a prose explanation of the behavior

---

### Step 3: Register in the docs index

**Project:** `lamella/`
**Effort:** 0.1 day
**Depends on:** Step 1

Add an entry for `plugin-validator-reference.md` in the lamella docs index (whatever file serves as the docs table of contents). If no index exists, create `lamella/docs/README.md` as the index.

#### Verification

```bash
cd lamella && grep -r "plugin-validator" docs/ 2>&1
```

**Checklist:**
- [ ] Reference document is listed in the docs index
- [ ] Index entry has a one-line description of what the document covers

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/lamella/verify-plugin-validator-documentation.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/lamella/verify-plugin-validator-documentation.sh
```

## Context

Source: ECC ecosystem borrow audit (2026-04-14) section "Plugin validator constraints." Reference file: ECC `.claude-plugin/PLUGIN_SCHEMA_NOTES.md`. See `.audit/external/audits/` for the full ECC audit. This document should be treated as a living reference — update it whenever a new validator constraint is discovered or a previously documented constraint changes with a new Claude Code release.

Related handoffs: none. This handoff is self-contained and has no blocking dependencies.
