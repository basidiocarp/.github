# Resolved Status and Customization Contract

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** septa/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

There is no shared contract defining what a "resolved status configuration" looks like. Cap handoff #60 (Status Preview and Customization Surface) is explicitly blocked on this contract. Without it, every tool that needs to display or customize status — the annulus statusline, cap's preview surface, stipe's host injection — invents its own shape and drifts apart. Multiple audits (ccstatusline, ccusage, 1code) converge on a contract-plus-adapter design where the payload is host-neutral and adapters handle injection per CLI.

## What exists (state)

- **`septa/`**: 33 existing contracts with established governance and validation workflow.
- **Annulus statusline (#83)**: defines segments (context, git, mycelium, hyphae, canopy, volva) but has no corresponding septa contract yet.
- **Cap #60**: blocked on "Septa Resolved Status And Customization Contract" — this handoff is that dependency.
- **`ecosystem-versions.toml`**: contracts section lists families but no `resolved-status-customization-v1` entry.
- **Stipe**: handles host injection but has no portable bundle to inject.

## What needs doing (intent)

Define `resolved-status-customization-v1` as a septa contract. The schema covers segments, theme, and per-host overrides. A matching fixture validates the schema. The contract lets stipe inject one portable bundle into Claude Code, Codex, and Cursor rather than each adapter inventing its own config shape. Cap previews it, lamella packages presets against it, and annulus renders from it.

---

### Step 1: Define the resolved-status-customization-v1 schema

**Project:** `septa/`
**Effort:** 4-8 hours
**Depends on:** nothing

Create `septa/resolved-status-customization-v1.schema.json`. The schema must be host-neutral: it describes segments and preferences, not host-specific config file shapes. Host adapters in stipe translate the payload into whatever the target CLI expects.

Top-level fields:

- `schema_version`: string, fixed `"1.0"`
- `segments`: ordered array of segment objects, each with:
  - `id`: string identifier matching annulus segment names (context, git, mycelium, hyphae, canopy, volva)
  - `enabled`: boolean
  - `config`: object, segment-specific optional config (e.g. display format, threshold values)
- `theme`: object with color and formatting preferences
  - `color_mode`: `"auto" | "always" | "never"`
  - `separator`: string (default `" | "`)
- `host_overrides`: object keyed by host name (`claude_code`, `codex`, `cursor`) with optional per-host field overrides
- `metadata`: object with `created_at`, `version`, `preset_name` (optional)

Create matching fixture: `septa/resolved-status-customization-v1.fixture.json`

The fixture should enable three segments (context, git, hyphae), disable the rest, use auto color mode, and include a `claude_code` host override.

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/septa && ls *.schema.json | wc -l
```

**Output:**
<!-- PASTE START -->
39
<!-- PASTE END -->

**Checklist:**
- [x] `septa/resolved-status-customization-v1.schema.json` exists
- [x] `septa/resolved-status-customization-v1.fixture.json` exists and validates against the schema
- [x] Schema version field is `"1.0"`
- [x] Segment model uses `id`, `enabled`, `config` — no host-specific fields at top level
- [x] `host_overrides` keyed by host name, not embedded throughout
- [x] Fixture covers the enabled, disabled, and override cases

---

### Step 2: Add contract to ecosystem-versions.toml

**Project:** workspace root
**Effort:** 15 min
**Depends on:** Step 1

Add `resolved-status-customization` to the `[contracts]` section of `ecosystem-versions.toml`. Follow the existing pattern for other contract entries.

#### Verification

```bash
grep "resolved-status-customization" /Users/williamnewton/projects/basidiocarp/ecosystem-versions.toml
```

**Output:**
<!-- PASTE START -->
DEFERRED: ecosystem-versions.toml update reserved for orchestrator (concurrent agent impl/septa/fail-open-hook-contracts/1 is also adding a contracts entry; orchestrator will batch both).
<!-- PASTE END -->

**Checklist:**
- [ ] `resolved-status-customization` appears in `[contracts]` section of `ecosystem-versions.toml`

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/septa/verify-resolved-status-customization-contract.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/septa/verify-resolved-status-customization-contract.sh
```

**Output:**
<!-- PASTE START -->
Results: 39 passed, 0 failed, 0 skipped
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete with failures.

## Context

From synthesis DN-6 and DX-7. CCStatusline audit makes the missing seam explicit: portable status and customization across Claude Code, Codex, and Cursor requires a host-neutral contract, not one config writer per CLI. The ccusage and 1code audits reinforce this. Directly blocks Cap #60 (Status Preview and Customization Surface) and informs annulus statusline (#83) segment design. The intended production split: septa defines the payload, cortina supplies normalized inputs, lamella packages presets, stipe injects and repairs per host, cap provides preview and editing.
