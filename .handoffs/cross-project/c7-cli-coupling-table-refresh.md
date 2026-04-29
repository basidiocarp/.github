# Cross-Project: C7 CLI Coupling Table Refresh (F1.1 + F1.2 + F1.3)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa` (primary write); read-only access across `stipe/`, `annulus/`
- **Allowed write scope:**
  - `septa/integration-patterns.md` (the CLI Coupling Classification table)
  - `.handoffs/cross-project/verify-cli-coupling-exemption-audit.sh` (only if the existing C7 verifier needs new sites added to its KNOWN_SITES list — minor edit if so)
- **Cross-repo edits:** none — only documentation in septa
- **Non-goals:** does not migrate any of the documented couplings (those become separate handoffs); does not add a new schema; does not modify stipe or annulus source
- **Verification contract:** `bash .handoffs/cross-project/verify-c7-cli-coupling-table-refresh.sh`
- **Completion update:** Stage 1 + Stage 2 → commit → dashboard

## Implementation Seam

- **Likely files/modules:**
  - `septa/integration-patterns.md` — "CLI Coupling Classification" section currently has 10 active rows + a "Recently Migrated" subsection
  - `stipe/src/commands/init/seed.rs` — shells out to `hyphae` (F1.1)
  - `stipe/src/ecosystem/configure.rs` — shells out to `hyphae` (F1.1)
  - `stipe/src/commands/package_repair.rs:501` — shells out to `lamella` (F1.2)
  - `stipe/src/commands/plugin_inventory_checks.rs:62` — calls `annulus validate-hooks --json` (F1.3 — current row says `annulus --version` which is wrong)
- **Reference seams:** existing rows in the table for the "operator surface", "hook-time exception", and "system-to-system (must migrate)" classifications — each new row picks one
- **Spawn gate:** locations are precise; can dispatch directly

## Problem

Three C7 table accuracy findings from lane 1:

- **F1.1** — `stipe → hyphae` call sites in `init/seed.rs` (memory store/stats setup) and `ecosystem/configure.rs` are not in the C7 table. They exist in source but the table does not classify them.
- **F1.2** — `stipe → lamella` call site in `package_repair.rs:501` is not in the table.
- **F1.3** — The existing `stipe → annulus (Hook Setup)` row says the coupling is `annulus --version` (a presence probe), but the actual code at `plugin_inventory_checks.rs:62` calls `annulus validate-hooks --json` and parses structured output. That's a real contract, not a probe — the row understates it.

Each finding either needs a new row in the table or a correction to an existing row.

## Scope

- **Primary seam:** the C7 CLI Coupling Classification table in `septa/integration-patterns.md`
- **Allowed files:** see Handoff Metadata
- **Explicit non-goals:**
  - Migrating any of these couplings (they become separate handoffs after this one classifies them)
  - Adding a septa schema for `annulus validate-hooks --json` (the row may note the contract is an unschemaed wire format, similar to F2.8 before that handoff landed; a follow-up handoff can model it later)
  - Modifying stipe or annulus source

---

### Step 1: Confirm each call site exists and capture the exact form

**Project:** workspace root (read-only)
**Effort:** small

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp && grep -nE 'Command::new\("hyphae"|hyphae_bin' stipe/src/commands/init/seed.rs stipe/src/ecosystem/configure.rs 2>/dev/null)
(cd /Users/williamnewton/projects/personal/basidiocarp && grep -nE 'Command::new\("lamella"|lamella_bin' stipe/src/commands/package_repair.rs 2>/dev/null)
(cd /Users/williamnewton/projects/personal/basidiocarp && grep -n "validate-hooks" stipe/src/commands/plugin_inventory_checks.rs)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Each call site confirmed by line number
- [ ] The actual subcommand and args captured for the table row

---

### Step 2: Add F1.1 rows to the C7 table

**Project:** `septa/`
**Effort:** small

For each `stipe → hyphae` call site identified in Step 1, add a row to the CLI Coupling Classification table with:
- Caller (e.g. `stipe/src/commands/init/seed.rs:N`)
- Target (`hyphae <subcommand>`)
- Classification (likely "operator surface" or "system-to-system" — pick based on whether stipe is brokering an operator action vs. a runtime data exchange)
- Migration plan column or `n/a` per existing row format

Match the existing table style. Don't reorder rows.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && grep -nE "stipe.*hyphae" integration-patterns.md)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Both `stipe → hyphae` rows added (one per call site)
- [ ] Each row classified (no "TBD" placeholder)

---

### Step 3: Add F1.2 row to the C7 table

**Project:** `septa/`
**Effort:** trivial

Add a `stipe → lamella` row for the call site at `package_repair.rs:501`. Classify (likely "operator surface" since stipe is doing repair on behalf of the operator).

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && grep -nE "stipe.*lamella" integration-patterns.md)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Row added with classification

---

### Step 4: Reword F1.3 row

**Project:** `septa/`
**Effort:** trivial

Find the existing `stipe → annulus (Hook Setup)` row. Update it to:
- Reflect the actual command: `annulus validate-hooks --json`
- Note that it parses structured output (not a presence probe)
- Note that the wire format is currently unschemaed and a future handoff should model it (mirror the F2.8 pattern)

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && grep -B 1 -A 2 "annulus.*Hook Setup\|stipe.*annulus" integration-patterns.md)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Row mentions `validate-hooks --json` (not `--version`)
- [ ] Row notes the contract is unschemaed (or schema-less, or pending schema work)
- [ ] Row remains in the existing position (no reordering)

---

### Step 5: Update the C7 verifier KNOWN_SITES list (if needed)

**Project:** `.handoffs/`
**Effort:** trivial

Open `.handoffs/cross-project/verify-cli-coupling-exemption-audit.sh`. The `KNOWN_SITES` array enumerates known call site files. If any of the three new sites (`init/seed.rs`, `ecosystem/configure.rs`, `package_repair.rs`) are missing, add them so the verifier's "no unclassified call sites" check stays accurate. The annulus call site (`plugin_inventory_checks.rs`) may or may not be in the list — verify both ways and add only what's missing.

#### Verification

```bash
bash /Users/williamnewton/projects/personal/basidiocarp/.handoffs/cross-project/verify-cli-coupling-exemption-audit.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] C7 verifier exits 0
- [ ] No "UNCLASSIFIED" lines in its output

---

## Completion Protocol

1. All steps verified
2. `bash .handoffs/cross-project/verify-c7-cli-coupling-table-refresh.sh` passes
3. Stage 1 + Stage 2 pass
4. Commit + dashboard

### Final Verification

```bash
bash .handoffs/cross-project/verify-c7-cli-coupling-table-refresh.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Closes lane 1 concerns F1.1, F1.2, F1.3 from the post-execution boundary compliance audit. F1 exit criterion #3 ("CLI coupling table is current"). Pure documentation/classification work — no code migration.

## Style Notes

- Don't migrate the couplings as part of this handoff. The point is to classify what exists; migration is follow-up work.
- Match the existing table style. New rows go in the order of repo source layout (alphabetical within section), not appended at the end.
- For F1.3, the rewording is the priority; modeling the wire format is for a later handoff.
