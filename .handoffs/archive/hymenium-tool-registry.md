# Stipe: Register Hymenium in Tool Registry

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/commands/tool_registry/specs.rs`, `stipe/src/commands/tool_registry/` (only if a new variant is genuinely needed), `stipe/CHANGELOG.md`
- **Cross-repo edits:** none
- **Non-goals:** changing the `ToolSpec` shape; refactoring `tool_registry`; adding new install profiles; touching `cap`, `septa`, or `spore` (those are intentionally not user-installable from stipe today)
- **Verification contract:** repo-local `cargo test`, `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check`, plus `bash .handoffs/stipe/verify-hymenium-tool-registry.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive this handoff

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Hymenium (workflow orchestration engine, recently spun out into its own repo)
is missing from stipe's tool registry. Operators running `stipe install`,
`stipe update`, `stipe doctor`, `stipe status`, or `stipe ecosystem` get no
visibility into hymenium's installed/version state, and cannot install or
update it through stipe.

The companion newer tools — `annulus` and `volva` — are already registered
(see `stipe/src/commands/tool_registry/specs.rs:123` for volva and `:141`
for annulus). Hymenium was added to the workspace and pinned in
`ecosystem-versions.toml` (`hymenium = "0.1.0"`) but the stipe registry
update was skipped when it moved to its own repo.

## What exists (state)

- **`stipe/src/commands/tool_registry/specs.rs`**: single-source-of-truth
  registry. Every install / update / doctor / status / ecosystem command
  reads from `TOOL_SPECS`. Adding a tool is one entry; no per-command
  wiring required.
- **`ecosystem-versions.toml`**: already lists `hymenium = "0.1.0"` and
  includes hymenium in the spore consumers list.
- **`hymenium/`** (separate repo): publishes a CLI binary named `hymenium`
  with subcommands `dispatch`, `status`, `decompose`, `cancel`.

## What needs doing (intent)

Add one `ToolSpec` entry for hymenium following the same shape as
volva/annulus. Description, install profile, doctor coverage, smoke test,
and missing-hint should match the established pattern.

## Scope

- **Primary seam:** the `TOOL_SPECS` constant array in
  `stipe/src/commands/tool_registry/specs.rs`
- **Allowed files:** `stipe/src/commands/tool_registry/specs.rs`,
  `stipe/CHANGELOG.md` (one-liner under the next unreleased entry)
- **Explicit non-goals:**
  - changing the `ToolSpec` struct or any registry helpers
  - reordering existing entries
  - touching `cap`, `septa`, or `spore` registry status

---

### Step 1: Add the hymenium entry

**Project:** `stipe/`
**Effort:** 0.1 day
**Depends on:** nothing

Insert a new `ToolSpec` in `TOOL_SPECS` after `annulus` (preserve
declaration order: pre-existing tools first, then newer additions).

Use these field values (mirror volva/annulus where possible):

```rust
ToolSpec {
    name: "hymenium",
    binary_name: "hymenium",
    release_repo: "hymenium",
    description: "workflow orchestration engine",
    installable: true,
    include_in_update_all: true,
    include_in_uninstall_all: true,
    include_in_status: true,
    include_in_ecosystem: true,
    include_in_install_all: true,
    doctor_coverage: DoctorCoverage::Optional,
    install_profiles: &[InstallProfile::FullStack],
    missing_hint: Some("stipe install hymenium"),
    smoke_test_args: Some(&["status"]),
    smoke_test_expect: None,
    mcp_serve_args: None,
},
```

Notes:
- `description`: keep it terse and aligned with the existing one-line
  style ("workflow orchestration engine" matches the Cargo.toml summary).
- `smoke_test_args`: `hymenium status` is a no-side-effect read, mirroring
  volva's `backend status` choice.
- `doctor_coverage: Optional`: hymenium is not yet a hard dependency for
  every operator workflow, so a missing install should warn, not fail.
- `install_profiles`: `FullStack` matches volva/annulus.

Add a CHANGELOG.md line:

```markdown
- Add hymenium to the tool registry (install/update/doctor/status/ecosystem support)
```

#### Files to modify

**`stipe/src/commands/tool_registry/specs.rs`** — append the entry.

**`stipe/CHANGELOG.md`** — one-line note under the next unreleased section.

#### Verification

```bash
cd stipe && cargo test --quiet 2>&1 | tail -5
cd stipe && cargo run --quiet -- ecosystem 2>&1 | grep -i hymenium
cd stipe && cargo run --quiet -- status 2>&1 | grep -i hymenium
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `TOOL_SPECS` contains exactly one `hymenium` entry
- [ ] `cargo test` passes — registry tests stay green
- [ ] `stipe ecosystem` lists hymenium with its version
- [ ] `stipe status` reports hymenium (installed or missing, depending on local state)
- [ ] `stipe doctor` mentions hymenium under Optional coverage
- [ ] `stipe install hymenium` resolves (do not run end-to-end if it would mutate the operator's environment; just confirm the command surface)
- [ ] CHANGELOG entry added under the next unreleased version
- [ ] No changes to `ToolSpec` struct or registry helpers

---

## Completion Protocol

This handoff is NOT complete until ALL of the following are true:

1. Step 1 has verification output pasted between the markers
2. `bash .handoffs/stipe/verify-hymenium-tool-registry.sh` passes
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated and this handoff is archived

### Final Verification

```bash
bash .handoffs/stipe/verify-hymenium-tool-registry.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Cleanup after the hymenium repo split (commit 1a260cc, "chore: move
hymenium to its own repository"). The workspace ecosystem-versions
file and CLAUDE.md/ECOSYSTEM-OVERVIEW.md were updated, but the stipe
registry change was skipped.

Once this lands, an operator running `stipe install` (FullStack profile)
gets hymenium alongside the rest of the orchestration tools, and `stipe
doctor` reports its install/version state.

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsIf the existing `annulus` entry's description ("operator utilities") feels
stale relative to its current scope as a statusline tool, that's a
separate concern — do not bundle it into this handoff. Open a follow-up
if it matters.
