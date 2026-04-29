# Lane 1: Boundary Compliance Findings (2026-04-29)

## Summary

Six findings: 0 blockers, 4 concerns, 2 nits. Both existing C7 and C8 verifiers
remain green. The 14→10 row reduction in `septa/integration-patterns.md` and the
"Recently Migrated" subsection match `git log` for 2026-04-29. The drift is
concentrated in the C7 table's coverage: several stipe→sibling-CLI sites (init
seed, configure, package_repair, plugin_inventory, generic update) are not
represented as rows even though they fall under the operator-surface
classification, and `stipe/src/commands/rollback.rs` is listed as a known site
even though the actual `Command::new` lives in `stipe/src/commands/backup.rs`.

## Baseline

```
$ bash .handoffs/cross-project/verify-cli-coupling-exemption-audit.sh
=== CLI Coupling Exemption Audit ===

[Check 1] Verifying known call sites exist...
  ✓ cortina/src/utils/hyphae_client.rs
  ✓ cortina/src/hooks/trigger_word.rs
  ✓ hymenium/src/dispatch/cli.rs
  ✓ hyphae/crates/hyphae-ingest/src/rhizome.rs
  ✓ mycelium/src/rhizome_client.rs
  ✓ volva/crates/volva-runtime/src/hooks.rs
  ✓ volva/crates/volva-cli/src/run.rs
  ✓ volva/crates/volva-cli/src/chat.rs
  ✓ stipe/src/commands/codex_notify.rs
  ✓ stipe/src/commands/claude_hooks.rs
  ✓ stipe/src/commands/backup.rs
  ✓ stipe/src/commands/rollback.rs
  ✓ annulus/src/notify.rs

[Check 2] Checking known sites for sibling CLI calls...
  NOTE cortina/src/utils/hyphae_client.rs → no literal Command::new match
  ✓ cortina/src/hooks/trigger_word.rs → literal sibling call detected
  ✓ hymenium/src/dispatch/cli.rs → literal sibling call detected
  NOTE hyphae/crates/hyphae-ingest/src/rhizome.rs → no literal Command::new match
  NOTE mycelium/src/rhizome_client.rs → no literal Command::new match
  NOTE volva/crates/volva-runtime/src/hooks.rs → no literal Command::new match
  NOTE volva/crates/volva-cli/src/run.rs → no literal Command::new match
  ✓ volva/crates/volva-cli/src/chat.rs → literal sibling call detected
  ✓ stipe/src/commands/codex_notify.rs → literal sibling call detected
  ✓ stipe/src/commands/claude_hooks.rs → literal sibling call detected
  ✓ stipe/src/commands/backup.rs → literal sibling call detected
  NOTE stipe/src/commands/rollback.rs → no literal Command::new match
  NOTE annulus/src/notify.rs → no literal Command::new match

[Check 3] Scanning for unexpected new sibling CLI call sites...
  ✓ No new unclassified sibling CLI call sites detected

[Check 4] Verifying septa/integration-patterns.md has CLI Coupling Classification...
  ✓ CLI Coupling Classification section found

=== Results ===
Passed: 28
Failed: 0
✓ CLI coupling exemption audit passed

$ bash .handoffs/cross-project/verify-system-to-system-communication-boundary.sh
PASS: AGENTS states CLI is not preferred system-to-system protocol
PASS: contracts or foundations document the integration hierarchy
PASS: Canopy dispatch endpoint handoff treats CLI as operator surface
PASS: Hymenium capability client handoff treats CLI as fallback only
PASS: dashboard tracks the communication boundary handoff
Results: 5 passed, 0 failed
```

Manual sweep (`grep -rn "Command::new\|tokio::process::Command::new" cortina hyphae hymenium mycelium rhizome spore stipe --include="*.rs" | grep -v clap | grep -v target`):
- 189 raw hits across the active hardening repos.
- After excluding generic tools (git, cargo, npx, gh, docker, kubectl, aws, python3, etc.), tests, doctests, the mycelium dispatch families (mycelium IS the wrapper for generic tools — operator/agent surface by design), and the documented C7 rows, the residual sibling-tool spawns in active repos are:
  - `cortina/src/hooks/trigger_word.rs:82` — `Command::new("hyphae")` — covered by C7 (hook-time exception, "cortina → hyphae (Session Lifecycle)").
  - `hyphae/crates/hyphae-cli/src/commands/doctor.rs:342` — `Command::new("claude")` (`mcp list`) — host-tool probe, not sibling-Basidiocarp; no row needed.
  - `hymenium/src/dispatch/cli.rs:90` — `Command::new(&bin)` (canopy) — covered by C7 ("hymenium → canopy (Dispatch)").
  - `hymenium/src/dispatch/capability_client.rs:173` — `Command::new(&bin)` (canopy) — capability-resolution path is the C8/C6 replacement target, not a violation.
  - `stipe/src/commands/codex_notify.rs:14` — `Command::new("hyphae")` — covered by `stipe → hyphae (Backup)`'s row and the operator-surface class, but not enumerated.
  - `stipe/src/commands/claude_hooks.rs:87,94` — `Command::new("cortina")`, `Command::new("annulus")` — covered by `stipe → cortina` and `stipe → annulus` rows.
  - `stipe/src/commands/backup.rs:65` — `Command::new("hyphae")` — covered.
  - `stipe/src/commands/init/seed.rs:21,30,59` — `Command::new(hyphae_cmd)` — **NOT enumerated**.
  - `stipe/src/ecosystem/configure.rs:138` — `Command::new(&hyphae_bin).arg("stats")` — **NOT enumerated**.
  - `stipe/src/commands/package_repair.rs:501` — `Command::new(&lamella_bin)` — **NOT enumerated** (no stipe → lamella row).
  - `stipe/src/commands/doctor/plugin_inventory_checks.rs:62` — `Command::new(&annulus_path).args(["validate-hooks", "--json"])` — partly covered by `stipe → annulus (Hook Setup)` but pattern is different (`--version` vs `validate-hooks --json`).
  - `stipe/src/commands/update.rs:16` — `Command::new(tool).arg("--version")` — generic version probe over every registered tool; not enumerated.

## Findings

### [F1.1] C7 table missing stipe → hyphae rows for `init seed` and `ecosystem configure` — severity: concern

- **Location:** `septa/integration-patterns.md:271-281` (active CLI Coupling table); call sites at `stipe/src/commands/init/seed.rs:21,30,59` and `stipe/src/ecosystem/configure.rs:138`
- **Evidence:** `seed.rs` shells out to `hyphae --version`, `hyphae memory stats --json`, and `hyphae store ...` during `stipe init` first-run seeding. `configure.rs` shells out to `hyphae stats` during `stipe init` configure. Neither call site is represented in the CLI Coupling Classification table; the only existing `stipe → hyphae` row is `Backup` (`hyphae --version`), which describes a different command.
- **Why it matters:** F1 exit criterion 3 requires "the 10 remaining active CLI couplings in `septa/integration-patterns.md` have either been migrated or classified as permanent exceptions." Couplings that exist in code but are not rows are neither.
- **Proposed handoff:** "septa: add stipe → hyphae rows for `init seed` and `init configure` to CLI Coupling Classification"

### [F1.2] C7 table missing stipe → lamella row for package_repair — severity: concern

- **Location:** `septa/integration-patterns.md:271-281`; call site at `stipe/src/commands/package_repair.rs:501`
- **Evidence:** `package_repair.rs` resolves a lamella binary and shells out with `Command::new(&lamella_bin).arg(invocation.subcommand).args(invocation.args)` to run lamella subcommands. There is no `stipe → lamella` row in the active classification table.
- **Why it matters:** F1 exit criterion 3 — see F1.1. Adds another silent operator-surface coupling that is not on the migration ledger.
- **Proposed handoff:** "septa: add stipe → lamella package_repair row to CLI Coupling Classification"

### [F1.3] C7 table row for `stipe → annulus (Hook Setup)` understates the coupling — severity: concern

- **Location:** `septa/integration-patterns.md:281` (`stipe → annulus (Hook Setup)` row says `annulus --version`); actual call sites also include `stipe/src/commands/doctor/plugin_inventory_checks.rs:62` (`annulus validate-hooks --json`)
- **Evidence:** The row claims the pattern is "`annulus --version` (availability check)", but `plugin_inventory_checks.rs` calls `annulus validate-hooks --json` and parses the structured output. That is a contract-bearing call, not a presence probe.
- **Why it matters:** F1 exit criterion 3 expects classification accuracy. A row that hides the structured-output contract (which is closer to a `stipe-doctor` consumer pattern) underestimates the migration cost when the operator-surface set transitions to typed endpoints.
- **Proposed handoff:** "septa: split stipe → annulus row into `--version` probe and `validate-hooks --json` contract entries"

### [F1.4] C7 verifier known-site for `stipe/src/commands/rollback.rs` is stale — severity: concern

- **Location:** `.handoffs/cross-project/verify-cli-coupling-exemption-audit.sh` (Check 1 list) and the C7 table's `stipe → hyphae (Backup)` mapping
- **Evidence:** `stipe/src/commands/rollback.rs` has no `Command::new` (the verifier emits "NOTE … no literal Command::new match"). Rollback delegates to `backup::list_backups`, `backup::load_manifest`, and `backup::restore`; the actual sibling-CLI call (`hyphae --version`) lives in `stipe/src/commands/backup.rs:65`. Listing rollback as a known site dilutes the coverage signal because the file no longer matches.
- **Why it matters:** F1 exit criterion 3 plus C7 audit credibility. NOTE rows hide whether a site has been migrated or never existed there.
- **Proposed handoff:** "cross-project: drop stale rollback.rs entry from verify-cli-coupling-exemption-audit.sh (covered by backup.rs)"

### [F1.5] AGENTS.md "3-tier hierarchy" wording does not appear verbatim — severity: nit

- **Location:** `AGENTS.md:78-88`
- **Evidence:** The lane handoff and the campaign README describe the C8 rule as a "3-tier hierarchy". `AGENTS.md` lists three numbered options (library/crate, local service endpoint, CLI fallback) but does not use the words "tier" or "hierarchy". Verifier check still passes because it greps for "system-to-system" wording, but a reader cross-referencing the campaign description for "3-tier" finds nothing.
- **Why it matters:** Documentation-cross-check (Step 3 of this audit). Low impact — the policy itself is intact and the C8 verifier passes 5/5.
- **Proposed handoff:** "docs: align AGENTS.md C8 wording with campaign 'three-tier' phrasing or update campaign description"

### [F1.6] `stipe/src/commands/update.rs` runs `<tool> --version` over every registered sibling tool but is not enumerated — severity: nit

- **Location:** `stipe/src/commands/update.rs:16`
- **Evidence:** `get_installed_version(tool)` calls `Command::new(tool).arg("--version")` for whichever sibling tool is being updated (cortina, hyphae, mycelium, annulus, lamella, etc.). The behavior is the same `--version` probe that the existing rows already classify as operator-surface, but no single row covers it because it is parametric.
- **Why it matters:** F1 exit criterion 3 — finishing the table means choosing whether parametric `--version` probes need a single "stipe → \* (update version probe)" row or whether the existing per-tool rows already imply it. Not blocking; the migration class is already settled (operator surface).
- **Proposed handoff:** "septa: decide whether to enumerate stipe update.rs `--version` parametric probe in CLI Coupling Classification"

## Clean Areas

- **C7 verifier (`verify-cli-coupling-exemption-audit.sh`)**: 28 passed, 0 failed.
- **C8 verifier (`verify-system-to-system-communication-boundary.sh`)**: 5 passed, 0 failed.
- **`Recently Migrated` subsection** in `septa/integration-patterns.md` (4 rows: stipe self, hyphae→rhizome, mycelium→rhizome, volva→canopy) matches `git log --since="2026-04-28" integration-patterns.md` exactly. No drift.
- **Cap operator-surface scope** is intact: all `cap/server/**/*.ts` `child_process`/`execFile` callers (`lib/cli.ts`, `routes/rhizome/reads.ts`, `routes/settings/shared.ts`, `routes/status/checks.ts`, `lib/platform.ts`, `rhizome/client.ts`) are read-path or operator-brokered and bind to the configured sibling binary; no new direct DB writes or unbrokered system-to-system writes were introduced.
- **`hymenium/src/dispatch/capability_client.rs`** is the C6/C8 capability-resolution successor to `dispatch/cli.rs`, not a regression. Both are owned by the `hymenium → canopy (Dispatch)` "temporary compatibility" row in C7.
- **`mycelium` per-tool spawns** (cargo, gh, docker, kubectl, aws, npx, pnpm, etc.) are mycelium's wrapper surface for generic tools, not sibling-Basidiocarp coupling. Not in scope for C7/C8.
- **Frozen-repo integration boundaries** (cap, hymenium, annulus) checked from the outside: each sibling-CLI call points back to a row in C7. No new system-to-system surface added during the freeze.
- **F1 active/frozen repo split** in `docs/foundations/core-hardening-freeze-roadmap.md` matches the in-flight Active row for hyphae/mycelium/rhizome/septa/spore/stipe/cortina and the Maintenance/Frozen row for cap/canopy/hymenium/lamella/annulus/volva. No drift between the roadmap and the audit scope.
