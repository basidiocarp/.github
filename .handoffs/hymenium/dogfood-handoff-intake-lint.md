# Hymenium: Dogfood Handoff Intake Lint

<!-- Save as: .handoffs/hymenium/dogfood-handoff-intake-lint.md -->
<!-- Create verify script: .handoffs/hymenium/verify-dogfood-handoff-intake-lint.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/parser/`, `hymenium/src/commands/`, `hymenium/tests/`, `hymenium/tests/fixtures/`, `hymenium/README.md`
- **Cross-repo edits:** none
- **Non-goals:** no Canopy dispatch changes and no CentralCommand handoff edits
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-dogfood-handoff-intake-lint.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** `hymenium/src/parser/markdown.rs`, parser error types, dispatch preflight command path, parser fixtures
- **Reference seams:** `hymenium/tests/parser_test.rs`, `hymenium/tests/fixtures/crate-scaffold.md`, existing `ParseError::MissingSection`
- **Spawn gate:** do not launch an implementer until the parent agent names the exact fixture variants to accept or reject

## Spawn Gate Decision

- **Alias strategy:** accept all common variants of each required heading (case-insensitive, with or without parenthetical context suffix) and normalize them to one internal section type. Do not require the verbose form.
- **Examples of accepted aliases for `WhatNeedsDoing`:** `## What needs doing`, `## What needs doing (intent)`, `## What Needs Doing`, `## What Needs Doing (Intent)` — all map to the same parsed section.
- **Apply the same alias treatment** to all other required headings that have parenthetical variants (`## Problem`, `## Scope`, `## Verification`, etc.).
- **Hard rejection:** only when no heading in the document matches any alias for a required section. The error must name the missing section and list at least two accepted spellings.
- **No silent coercion of free-form headings:** unrecognized headings that don't match any alias are ignored (not rejected), but missing required sections are always a hard error.

## Problem

The CentralCommand dogfood handoff initially failed because the parser required exact section headings such as `## What needs doing (intent)`. That strictness turns small authoring drift into dispatch failure, and the error does not tell the user which accepted headings or lint command can repair the handoff.

Read-only audits also need a first-class intake shape: source write scope can be `none` while report and verify-script artifact writes are allowed.

## What exists (state)

- **Parser:** exact heading matching in `hymenium/src/parser/markdown.rs`
- **Tests:** parser fixtures cover the current strict format but not common casing variants or read-only audit artifact scope
- **CLI:** dispatch performs parsing, but there is no dedicated handoff lint/preflight surface for operators

## What needs doing (intent)

Make handoff intake robust enough for dogfood: accepted heading aliases should be normalized or rejected with actionable diagnostics, and read-only audit artifact scopes should parse into structured metadata instead of relying on prose constraints.

## Scope

- **Primary seam:** Hymenium handoff parsing and preflight validation
- **Allowed files:** parser modules, parser tests, parser fixtures, dispatch/preflight docs
- **Explicit non-goals:** no workflow scheduling changes, no Canopy CLI changes, no automatic rewrite of user handoff files

## Verification

```bash
cd hymenium && cargo test parser
cd hymenium && cargo test handoff_intake
bash .handoffs/hymenium/verify-dogfood-handoff-intake-lint.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] parser accepts or clearly diagnoses common heading variants from the dogfood run
- [ ] errors include the missing section and at least one accepted heading spelling
- [ ] read-only source scope and artifact write scope are represented separately
- [ ] fixture coverage includes the CentralCommand drop-shipping handoff shape
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 CentralCommand dogfood run. This should reduce early dispatch failure and make handoff authoring mistakes visible before a workflow is created.

