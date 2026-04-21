# Lamella Foundation Alignment

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** lamella/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

`lamella` already has the right ownership idea, but it needs to stay clearly on the authoring, packaging, and manifest side of the boundary. As skill validation, scaffolding, and richer package metadata are added, it will be easy to let install or runtime behavior leak inward unless the foundation is tightened first.

## What exists (state)

- **`lamella`** already owns packaged content, docs, manifests, and export surfaces
- **`stipe`** already owns install and repair behavior outside Lamella
- **Future handoffs** will add validation and scaffolding, increasing the need for a crisp source-of-truth boundary

## What needs doing (intent)

Reinforce:

- Lamella validates and packages
- Lamella does not mutate host runtime state
- authoring docs, manifests, and validation stay aligned
- larger validation or packaging tests move out of hotspot implementation files

---

### Step 1: Align boundary docs and source-of-truth notes

**Project:** `lamella/`
**Effort:** 1-2 hours
**Depends on:** nothing

Clarify that:

- `lamella` owns authoring and packaging
- runtime installation or repair belongs elsewhere
- manifests and resources are source of truth, not generated output

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
Running validators...
Validated 213 command files
Validated 68 hook matchers
Validated 210 rule files
Validated 297 skill directories
Validated 128 shared subagent files
Subagent parser and emitters passed
Validated 52 manifests (560 resources)
Validated marketplace catalog (52 plugins, version 0.5.10)
Scanned 367 files (15 references checked)
Validated 8 preset files
All validators passed.
<!-- PASTE END -->

**Checklist:**
- [x] docs state packaging vs runtime ownership clearly
- [x] docs state source-of-truth locations clearly
- [x] validate still passes

---

### Step 2: Add a lightweight alignment guard

**Project:** `lamella/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Add a lightweight guard that keeps docs, manifests, and validation expectations aligned for future work.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
Running validators...
Validated 213 command files
Validated 68 hook matchers
Validated 210 rule files
Validated 297 skill directories
Validated 128 shared subagent files
Subagent parser and emitters passed
Validated 52 manifests (560 resources)
Validated marketplace catalog (52 plugins, version 0.5.10)
Scanned 367 files (15 references checked)
Validated 8 preset files
All validators passed.
<!-- PASTE END -->

**Checklist:**
- [x] a future-work alignment guard exists
- [x] validation still passes

---

### Step 3: Split larger validation and packaging tests from hotspots

**Project:** `lamella/`
**Effort:** 2-3 hours
**Depends on:** Steps 1-2

Move larger behavior tests or heavy validation logic out of hotspot files where they obscure authoring or packaging code.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -40
bash .handoffs/lamella/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
Running validators...
Validated 213 command files
Validated 68 hook matchers
Validated 210 rule files
Validated 297 skill directories
Validated 128 shared subagent files
Subagent parser and emitters passed
Validated 52 manifests (560 resources)
Validated marketplace catalog (52 plugins, version 0.5.10)
Scanned 367 files (15 references checked)
Validated 8 preset files
All validators passed.
PASS: Workspace foundation docs live under docs/foundations
PASS: Lamella docs mention packaging or authoring ownership
PASS: Lamella docs mention runtime or install boundary
PASS: Lamella has validation or test surface
Results: 4 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] larger validation/packaging tests are split where needed
- [x] inline tests remain only for small invariants
- [x] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/lamella/verify-foundation-alignment.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/lamella/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->
PASS: Workspace foundation docs live under docs/foundations
PASS: Lamella docs mention packaging or authoring ownership
PASS: Lamella docs mention runtime or install boundary
PASS: Lamella has validation or test surface
Results: 4 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Companion standards:

- `docs/foundations/rust-workspace-architecture-standards.md`
- `docs/foundations/rust-workspace-standards-applied.md`
