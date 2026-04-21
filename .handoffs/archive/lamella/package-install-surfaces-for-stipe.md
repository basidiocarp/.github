# Lamella Package Install Surfaces For Stipe

## Problem

`stipe package` can now target Lamella’s coarse install surfaces, but only at the command level:

- `./lamella install`
- `./lamella install-codex`

That is enough for host-specific package repair, but it is not enough for finer-grained repair tied to Stipe install profiles or smaller package subsets. Right now, Stipe has to stop at the surface boundary because Lamella does not expose a narrower package-selection contract that Stipe can rely on.

This is the next missing layer: Lamella needs a first-class, machine-usable way to expose installable package surfaces or presets so Stipe can invoke them without inventing package semantics.

## What exists (state)

- **`lamella install`:** installs Claude-facing plugin/package content
- **`lamella install-codex`:** installs Codex-facing exported skills and agents
- **`stipe package`:** can call those coarse Lamella surfaces safely, with backup and rollback behavior on the Stipe side
- **No fine-grained contract:** there is no smaller Lamella-owned install surface that Stipe can target for profile-specific or subset-specific repair

## What needs doing (intent)

Expose a Lamella-owned contract for finer-grained package installation that Stipe can call directly.

Keep the boundary hard:

- `lamella` defines package surfaces, preset names, and what each one installs
- `stipe` calls those Lamella-defined surfaces and protects host state before mutation
- `stipe` does not learn package composition

The goal is not “teach Stipe what full or standard means.” The goal is “give Stipe a Lamella contract it can trust.”

---

### Step 1: Define a Lamella-side install surface contract

**Project:** `lamella/`
**Effort:** 1-2 hours
**Depends on:** nothing

Add an explicit install-surface or preset contract that is owned by Lamella and can represent smaller install subsets than the current `install` and `install-codex` split.

This can be:

- a new preset or profile layer
- a manifest-driven install target
- a machine-readable install map
- a CLI selection surface that resolves through Lamella metadata

What matters:

- Lamella owns the names and composition
- the contract is stable enough for Stipe to call
- the install surface is narrower than today’s coarse command split where useful

#### Files to modify

**`lamella/`** — add the contract in the right script, manifest, or metadata layer.

**`lamella/docs/`** — document the install surface contract and intended consumer boundary.

#### Verification

```bash
cd lamella && ./lamella --help 2>&1 | tail -40
cd lamella && ./lamella install --help 2>&1 | tail -60
cd lamella && ./lamella install-codex --help 2>&1 | tail -60
```

**Output:**
<!-- PASTE START -->
```text
$ cd lamella && ./lamella --help 2>&1 | tail -40
...
    ./lamella install --preset explore-codebase
    ./lamella install --preset stipe-package-repair
    ./lamella preset list
    ./lamella preset show tdd-cycle
...

$ cd lamella && ./lamella install --help 2>&1 | tail -60
lamella install - install Claude plugins
USAGE
    ./lamella install [options] [plugin-names...]
    ./lamella install --preset <name> [install-options]
...
    --preset <name>   Install a Lamella-owned preset surface by name
...
    ./lamella install --preset stipe-package-repair --dry-run

$ cd lamella && ./lamella install-codex --help 2>&1 | tail -60
install-codex-skills.sh - Install built lamella Codex skills and agents
...
```

<!-- PASTE END -->

**Checklist:**
- [x] Lamella exposes a finer-grained install surface or preset contract
- [x] the contract is Lamella-owned rather than inferred in Stipe
- [x] docs explain the new boundary clearly

---

### Step 2: Make the contract callable from Lamella CLI

**Project:** `lamella/`
**Effort:** 2 hours
**Depends on:** Step 1

Make sure the new install surface can be selected from the Lamella CLI in a way that another tool can invoke without scraping human-readable output.

The CLI does not need to become complex. It just needs a stable entrypoint.

Examples of acceptable shapes:

- `./lamella install --surface <name>`
- `./lamella install-codex --surface <name>`
- `./lamella preset install <name>`
- another narrow CLI path that clearly belongs to Lamella

#### Files to modify

**`lamella/lamella`** — add or route the CLI entrypoint.

**`lamella/install.sh`**, **`lamella/install-codex.sh`**, or adjacent builder/install scripts — wire the contract through the actual install flow.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -40
bash .handoffs/archive/lamella/verify-package-install-surfaces-for-stipe.sh
```

**Output:**
<!-- PASTE START -->
```text
$ cd lamella && make validate 2>&1 | tail -40
Running validators...
Validated 52 manifests (559 resources)
Validated marketplace catalog (52 plugins, version 0.5.10)
Validated 7 preset files
All validators passed.

$ bash .handoffs/archive/lamella/verify-package-install-surfaces-for-stipe.sh
PASS: Lamella handoff mentions install surface contract
PASS: Lamella preset surface file exists
PASS: Lamella preset defines an install plugin surface
PASS: Lamella install help exposes --preset
PASS: Lamella preset dry-run resolves the Stipe repair surface
PASS: Lamella docs explain the Stipe-facing boundary
Results: 6 passed, 0 failed
```

<!-- PASTE END -->

**Checklist:**
- [x] Lamella CLI has a stable machine-callable install-surface entrypoint
- [x] the install surface resolves through Lamella-owned metadata or presets
- [x] validation still passes
- [x] verify script passes

---

### Step 3: Add a Stipe-facing compatibility note or example

**Project:** `lamella/`
**Effort:** 1 hour
**Depends on:** Steps 1-2

Add one small compatibility note or example showing how Stipe or another installer should call the new surface.

This should stay documentation-level. Do not implement Stipe changes here.

#### Files to modify

**`lamella/docs/`** or nearby maintainer docs — add a small integration example or compatibility note.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -40
bash .handoffs/archive/lamella/verify-package-install-surfaces-for-stipe.sh
```

**Output:**
<!-- PASTE START -->
```text
$ cd lamella && make validate 2>&1 | tail -40
Validated 7 preset files
All validators passed.

$ bash .handoffs/archive/lamella/verify-package-install-surfaces-for-stipe.sh
PASS: Lamella handoff mentions install surface contract
PASS: Lamella preset surface file exists
PASS: Lamella preset defines an install plugin surface
PASS: Lamella install help exposes --preset
PASS: Lamella preset dry-run resolves the Stipe repair surface
PASS: Lamella docs explain the Stipe-facing boundary
Results: 6 passed, 0 failed
```

<!-- PASTE END -->

**Checklist:**
- [x] docs include a Stipe-facing invocation example or compatibility note
- [x] Lamella remains the source of truth for package composition
- [x] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/lamella/verify-package-install-surfaces-for-stipe.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/lamella/verify-package-install-surfaces-for-stipe.sh
```

**Output:**
<!-- PASTE START -->
```text
$ bash .handoffs/archive/lamella/verify-package-install-surfaces-for-stipe.sh
PASS: Lamella handoff mentions install surface contract
PASS: Lamella preset surface file exists
PASS: Lamella preset defines an install plugin surface
PASS: Lamella install help exposes --preset
PASS: Lamella preset dry-run resolves the Stipe repair surface
PASS: Lamella docs explain the Stipe-facing boundary
Results: 6 passed, 0 failed
```

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Follow-on from:

- `.handoffs/stipe/package-repair-profile-awareness.md`
- `.handoffs/stipe/package-repair-safety-hardening.md`

Motivated by the remaining limitation in Stipe:

- `stipe package` can only target Lamella’s coarse install surfaces until Lamella exposes a finer-grained install contract
