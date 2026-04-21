# Doctor Expansion

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** stipe/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`stipe doctor` checks binary availability and basic host config but doesn't surface provider or API key health, MCP server connection status, installed plugin inventory, worktree state, or hook registration integrity. Operators get a pass or fail on binary presence with no visibility into whether the ecosystem is actually functional end-to-end. Multiple audits (1code, claurst, vibe-kanban, context-keeper, skill-manager, ccstatusline) all point at this gap.

## What exists (state)

- **`stipe doctor`**: checks binary health and basic host config.
- **`stipe doctor --developer`**: checks recommended CLI tooling.
- **`stipe host doctor`**: per-host health checks scoped to config presence.
- **`annulus validate-hooks` (#70)**: will check hook path validity and return a machine-readable exit code. This handoff can consume that output when available.
- **No MCP server health check**: stipe doesn't ping or probe registered MCP servers.
- **No provider key check**: API key presence is not surfaced.
- **No plugin inventory**: installed lamella skills and hooks are not listed.

## What needs doing (intent)

Expand `stipe doctor` with three new check groups: MCP server health (binary present, server reachable), provider and API key presence (configured vs missing, no secrets logged), and plugin and hook inventory (installed vs stale, version drift). Each group is independently useful and independently shippable.

---

### Step 1: Add MCP server health checks

**Project:** `stipe/`
**Effort:** 1 day
**Depends on:** nothing

Check each registered MCP server (hyphae, rhizome, canopy) for binary existence, executability, and basic responsiveness. Use a short timeout (3 seconds) so a non-responding server doesn't hang the doctor run.

Status categories:
- `not-installed`: binary not found
- `installed-not-responding`: binary present but no response within timeout
- `running`: binary present and responds to a basic JSON-RPC `initialize` handshake

Output in `stipe doctor` should follow the existing check-group format: one line per server with status indicator.

The MCP check should be non-blocking. If all MCP servers time out, doctor still completes and reports the failures.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5 && cargo test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe doctor` reports MCP server status for hyphae, rhizome, and canopy
- [ ] Distinguishes `not-installed` vs `installed-not-responding`
- [ ] Timeout is enforced (no hang on unresponsive server)
- [ ] Doctor run still completes when all servers are unresponsive
- [ ] Build and tests pass

---

### Step 2: Add provider and API key health checks

**Project:** `stipe/`
**Effort:** 4-8 hours
**Depends on:** nothing

Check whether API keys and provider config are present for known providers. This is a presence and format check only — no network calls to validate keys against the API.

Checks:
- `ANTHROPIC_API_KEY`: set and non-empty, format starts with `sk-ant-` (warn if set but format is unexpected)
- Volva backend config: config file present and parseable
- Report status: `configured` / `missing` / `unexpected-format`

Keys must never appear in output. Mask with `***` if echoed for any reason. Missing keys are warnings, not errors — some users authenticate through host-managed auth that doesn't use env vars.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5 && cargo test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe doctor` reports provider key presence for `ANTHROPIC_API_KEY`
- [ ] Volva backend config presence reported
- [ ] No secrets logged or echoed in output
- [ ] Missing keys produce warnings, not errors
- [ ] Build and tests pass

---

### Step 3: Add plugin and hook inventory

**Project:** `stipe/`
**Effort:** 4-8 hours
**Depends on:** nothing

List installed lamella skills, hooks, and commands. For each, show whether the path is valid, the version installed, and whether it matches the pin in `ecosystem-versions.toml`.

When `annulus validate-hooks` (#70) is available, consume its exit code and output to populate hook status. When annulus is not installed, fall back to direct path stat checks.

Output in `stipe doctor`:
- Total installed skills by category
- Hook paths with status: `valid` / `stale` / `missing`
- Version drift: `up-to-date` / `behind (installed: X, pinned: Y)`

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5 && cargo test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe doctor` shows installed plugin and hook inventory
- [ ] Stale hooks flagged (leverages annulus when available, direct check otherwise)
- [ ] Version drift between installed and pinned versions reported
- [ ] Build and tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/stipe/verify-doctor-expansion.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/stipe/verify-doctor-expansion.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete with failures.

## Context

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom synthesis DN-4. Stipe is identified as the single clearest beneficiary of the full 19-audit set. The doctor surface is the most direct gap: operators cannot tell whether the ecosystem is healthy from a single command. Sources that converge on stronger doctor visibility: 1code (MCP auth health, plugin discovery), claurst (provider health, MCP connection status), vibe-kanban (agent and MCP availability checks), context-keeper (config precedence and setup-drift visibility), skill-manager (safe install and audit), ccstatusline (statusline install and hook sync).
