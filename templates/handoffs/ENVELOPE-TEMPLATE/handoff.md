# [Handoff Title]

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `<repo>`
- **Allowed write scope:** `<repo>/...`
- **Hot shared files touched:** `none` | `[Cargo.toml, Cargo.lock, ecosystem-versions.toml, mod.rs/lib.rs hub, septa/** fixtures]` — listed files serialize this lane behind a checkpoint or worktree
- **Contract dependency:** `none` | `[slug of the §septa contract handoff this waits on]` — if set, cannot be marked Done until that contract is committed and `septa/validate-all.sh` + `scripts/test-integration.sh` pass
- **Verification contract:** `bash .handoffs/work-items/<project>/<slug>/verify.sh`

## Problem

[Describe the problem this handoff solves.]

## Implementation Seam

_Completed by the parent during the seam-finding pass — required before dispatch:_

| File | Symbol / anchor | Callers | Captured @ commit | Change |
|------|-----------------|---------|-------------------|--------|
| `[path]` | `[function_or_type_name]` | `[N from find_references; note cross-repo]` | `[git -C <repo> log -1 --format=%h -- <file>]` | [what to add or change] |

> Use function or symbol names as anchors, not line numbers. Line numbers go stale when agents touch the same file concurrently. Use Rhizome to locate the exact symbol.
>
> **Caller census:** fill Callers via `find_references` / `get_call_sites` / `analyze_impact`. If > 5 callers or any cross-repo caller, an invariant must cover cross-call behavior and verification must include the callers' tests.
>
> **Staleness stamp:** if the file's current `log -1` differs from `Captured @ commit` at dispatch, re-verify the whole seam, not just problem existence.

**Behavioral invariants:**
- _(example: existing callers must still compile without changes)_
- _(example: fixture round-trips must be lossless)_

## Scope

- **Allowed files:** ...
- **Non-goals:** ...

---

### Step 1: [Title]

**Project:** `<repo>/`
**Effort:** small | medium | large
**Depends on:** nothing

[Description of the step.]

#### Verification

```bash
(cd <repo> && [verification command]); echo "exit:$?"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Exit code:** `[exit:N line — must be exit:0; Stage 2 re-runs this itself, not the paste]`

---

## Review Record

_Reviewers get only the diff, the frozen plan body, and the verification command — never the implementer's self-report. Stage 2 model must differ from Stage 1._

- **Stage 1** (`review/<repo>/<slug>/<run>`, model `[model]`): `PASS` | `FAIL` — [findings or "none"]
- **Stage 2** (`audit/<repo>/<slug>/<run>`, model `[different model]`, adversarial): `PASS` | `FAIL` — [findings or "none"]
- **Disputed findings:** [none | resolved by fresh same-stage review on a different model — never unilateral overrule]
- **Verification re-run by Stage 2:** `bash .handoffs/work-items/<project>/<slug>/verify.sh` → exit `[0]`

## Residual Work

| Finding | Disposition | Link / Note |
|---------|-------------|-------------|
| _(none on open handoff)_ | — | — |

## Completion

- **Contract barrier (only if `Contract dependency` is set):** the named contract handoff is committed and `cd septa && bash validate-all.sh` + `./scripts/test-integration.sh` both pass
- **Disposition:** `keep` | `discard` | `crash` | `pre-existing` | `design-invalid` | `deferred` — reason required for anything but `keep` (see WORK-ITEM-TEMPLATE for meanings)
- **Commit:** _(git short hash when done; for `pre-existing`, the commit that already contains the fix)_
- **Evidence ref:** _(canopy `evidence add --source-kind code_diff` id, or the commit + binary-version fallback note)_
