# Install Completeness Verification

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/...`
- **Cross-repo edits:** none
- **Non-goals:** SQLite state tracking (stipe is intentionally minimal-state); changes to the tool registry spec format; changes outside install, uninstall, and doctor modules
- **Verification contract:** run the repo-local commands below and `bash .handoffs/stipe/verify-install-completeness-verification.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** `src/commands/install.rs`, `src/commands/uninstall.rs`, `src/commands/doctor.rs`; potentially a new `src/verify.rs` for shared completeness logic
- **Reference seams:** caveman four-condition completeness check (files present, hook registrations, statusline entry, config consistency); ECC schema-validated install manifests; existing stipe install profiles for integration points
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Stipe declares install or uninstall complete without verifying all integration points. Caveman demonstrates a four-condition completeness check: files present, hook registrations in settings.json, statusline entry present, and config entries consistent — all verified before claiming success. ECC adds schema-validated install manifests with SQLite install-state tracking so doctor/repair can reason about what the installer owns. Stipe currently has install profiles but no pre-success completeness verification and no schema-validated manifests.

## What exists (state)

- **`stipe`:** has install profiles and doctor flows, but no pre-success completeness verification and no schema-validated install manifests
- **Ecosystem:** no stipe command verifies all integration points before returning success
- **Caveman reference:** four-condition completeness check run before declaring install or uninstall complete
- **ECC reference:** schema-validated install manifests, install ownership state to distinguish stipe-managed from user-managed entries

## What needs doing (intent)

Add a completeness check that verifies all integration points before declaring install or uninstall complete. Add schema validation to stipe's tool registry and install profiles so manifest drift is caught at build time and install time. Track install ownership state using file-based state (not SQLite) so doctor can distinguish stipe-managed entries from user-added entries.

## Scope

- **Primary seam:** install, uninstall, and doctor command paths in stipe
- **Allowed files:** `stipe/src/commands/` install, uninstall, and doctor modules; a new shared verify module if needed
- **Explicit non-goals:**
  - Do not add SQLite state tracking (stipe is intentionally minimal-state; use file-based state if tracking is needed)
  - Do not change the tool registry spec format (Rust structs are fine, validate at test time)
  - Do not change stipe modules outside of install, uninstall, and doctor paths

---

### Step 1: Define completeness check and integration point types

**Project:** `stipe/`
**Effort:** 0.5 day
**Depends on:** nothing

Define an `IntegrationPoint` enum covering the four conditions: binary present, hook registration present, statusline entry present, config entries consistent. Define a `CompletenessReport` struct that carries a result for each integration point. Add a `check_completeness()` function that verifies all points and returns the report. Use `#[non_exhaustive]` on `IntegrationPoint` to allow future points without breaking matches.

#### Verification

```bash
cd stipe && cargo check 2>&1
cd stipe && cargo test 2>&1
```

**Checklist:**
- [ ] `IntegrationPoint` enum covers all four conditions and is `#[non_exhaustive]`
- [ ] `CompletenessReport` carries a per-point result
- [ ] `check_completeness()` returns a typed report, not a boolean
- [ ] Both types derive `Debug, Clone`

---

### Step 2: Wire completeness check into install and uninstall

**Project:** `stipe/`
**Effort:** 0.5 day
**Depends on:** Step 1

Call `check_completeness()` at the end of install and uninstall before returning success. If any integration point fails the post-install check, return an error with the `CompletenessReport` rather than reporting success. For uninstall, verify that all previously present integration points are now absent.

#### Verification

```bash
cd stipe && cargo test install 2>&1
cd stipe && cargo test uninstall 2>&1
```

**Checklist:**
- [ ] Install returns an error if any integration point is missing after install
- [ ] Uninstall returns an error if any integration point is still present after uninstall
- [ ] Existing happy-path behavior is preserved (no regression on successful installs)
- [ ] Error output names the failing integration points

---

### Step 3: Add schema validation for install manifests and profiles

**Project:** `stipe/`
**Effort:** 0.5 day
**Depends on:** Step 1

Add validation of stipe's tool registry and install profiles at two points: at build time (via a test that deserializes all manifests and validates required fields) and at install time (validate the manifest before applying it). Invalid manifests must be rejected with a typed parse error before any file system changes occur.

#### Verification

```bash
cd stipe && cargo test manifest 2>&1
cd stipe && cargo test schema 2>&1
```

**Checklist:**
- [ ] A test deserializes all bundled manifests and fails the build if any are invalid
- [ ] Install rejects an invalid manifest before touching the file system
- [ ] Required manifest fields are documented in the manifest type
- [ ] No panic on malformed manifest input

---

### Step 4: Add file-based install ownership state and wire into doctor

**Project:** `stipe/`
**Effort:** 0.5 day
**Depends on:** Step 2

Track install ownership using a simple file-based state (e.g., a TOML or JSON file in stipe's state directory) that records which integration points stipe installed. The doctor command reads this state to distinguish stipe-managed entries from user-added entries and reports each category separately. Run the full check and clippy clean pass.

#### Verification

```bash
cd stipe && cargo test doctor 2>&1
cd stipe && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Install ownership state is written after a successful install
- [ ] Ownership state is removed after a successful uninstall
- [ ] Doctor distinguishes stipe-managed from user-added entries
- [ ] No new clippy warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/stipe/verify-install-completeness-verification.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/stipe/verify-install-completeness-verification.sh
```

## Context

Source: caveman audit (idempotent install/uninstall completeness checks) and ECC audit (schema-validated manifests with dependency expansion). The four-condition completeness check is adapted from caveman's pattern of verifying all integration points before declaring install or uninstall complete. Schema-validated manifests borrow the ECC approach but use Rust struct validation at test time rather than AJV, and file-based ownership state rather than SQLite, to keep stipe intentionally minimal-state.

Related handoffs: #92 Stipe Doctor Expansion; #93 Stipe Safe Install and Rollback.
