# Stipe Package Repair Safety Hardening

## Problem

`stipe package` now has the right broad shape for safe mutation: backup before mutation, rollback targets, and an audit log. The next gap is confidence. The command still needs tighter tests and clearer failure handling so operators can trust it when Lamella install partially succeeds, partially rewrites state, or fails mid-flight.

This is a hardening pass, not a feature expansion.

## What exists (state)

- **`stipe package`:** backs up package state, delegates install to Lamella, logs audit events, and attempts rollback on failure
- **`stipe doctor`:** can point operators at package drift and recommend package repair
- **Lamella:** remains the installer and package source of truth

## What needs doing (intent)

Harden `stipe package` so the repair path is safer and easier to trust under failure conditions.

Keep the boundary hard:

- `stipe` owns backup, rollback orchestration, audit logging, and operator-visible repair behavior
- `lamella` still owns what gets installed

Explicitly out of scope:

- changing package composition
- new package profile semantics
- deeper provider auth work

---

### Step 1: Tighten rollback behavior and failure reporting

**Project:** `stipe/`
**Effort:** 1-2 hours
**Depends on:** nothing

Review the current backup and rollback path and make failure handling more explicit.

Focus on:

- partial failure after Lamella recreates some package state
- operator-visible messaging about what was restored and what still needs manual inspection
- preserving backup artifacts when that is safer than deleting them silently

Do not add broad new install logic. This is about making the current mutation path safer.

#### Files to modify

**`stipe/src/commands/package_repair.rs`** — harden rollback and repair output.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cd stipe && cargo test package_repair 2>&1 | tail -40
cd stipe && cargo run -- package --dry-run 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
    Blocking waiting for file lock on artifact directory
    Finished `test` profile [unoptimized + debuginfo] target(s) in 0.10s
     Running unittests src/main.rs (target/debug/deps/stipe-fff34bb61a74d7a3)

running 15 tests
test commands::package_repair::tests::test_cursor_profile_has_no_package_repair_surface ... ok
test commands::package_repair::tests::test_lamella_invocations_for_codex_profile ... ok
test commands::package_repair::tests::test_lamella_invocations_for_full_profile_include_both_surfaces ... ok
test commands::package_repair::tests::test_lamella_root_candidates_include_workspace_sibling ... ok
test commands::package_repair::tests::test_missing_backup_is_treated_as_issue_in_failure_messaging ... ok
test commands::package_repair::tests::test_resolve_profile_prefers_explicit_then_saved_then_detected_default ... ok
test commands::package_repair::tests::test_package_targets_for_codex_profile_stay_on_codex_surface ... ok
test commands::package_repair::tests::test_package_targets_for_claude_profile_stay_on_claude_surface ... ok
test commands::package_repair::tests::test_audit_event_includes_rollback_details_on_failure ... ok
test commands::package_repair::tests::test_sibling_backup_path_includes_timestamp_suffix ... ok
test commands::package_repair::tests::test_supports_profile_only_for_host_package_surfaces ... ok
test commands::package_repair::tests::test_rollback_summary_lines_call_out_manual_inspection_when_needed ... ok
test commands::package_repair::tests::test_audit_log_best_effort_returns_warning_when_write_fails ... ok
test commands::package_repair::tests::test_rollback_decisions_restore_and_preserve_expected_paths ... ok
test commands::package_repair::tests::test_prepare_backups_roll_back_partial_state_when_later_backup_fails ... ok

test result: ok. 15 passed; 0 failed; 0 ignored; 0 measured; 140 filtered out; finished in 0.00s

    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.07s
     Running `target/debug/stipe package --dry-run`

Package Repair
───────────────────────────────────────────────────────────────────────────
Profile: codex
Lamella invocation(s):
Lamella source: ~/projects/basidiocarp/lamella
  - ./lamella install-codex --all --force
Would back up ~/.codex/agents before package install.
Would back up ~/.codex/skills before package install.

<!-- PASTE END -->

**Checklist:**
- [x] rollback behavior is clearer under failure conditions
- [x] operator output is explicit about backup and restore targets
- [x] no broad feature creep was added

---

### Step 2: Add focused safety tests

**Project:** `stipe/`
**Effort:** 1 hour
**Depends on:** Step 1

Add small tests for:

- rollback path decisions
- backup target naming stability
- failure-path messaging or audit-log shaping where practical

Prefer unit tests over end-to-end harnesses.

#### Files to modify

**`stipe/src/commands/package_repair.rs`** — add focused safety tests here.

#### Verification

```bash
cd stipe && cargo build 2>&1 | tail -20
cd stipe && cargo test 2>&1 | tail -40
bash .handoffs/stipe/verify-package-repair-safety-hardening.sh
```

**Output:**
<!-- PASTE START -->
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.07s

test ecosystem::clients::tests::test_collect_detected_clients_keeps_claude_hybrid_detection ... ok
test commands::uninstall::tests::test_build_uninstall_targets_marks_existing_files ... ok
test ecosystem::clients::tests::test_collect_detected_clients_keeps_continue_outside_shared_overlap ... ok
test ecosystem::clients::tests::test_collect_detected_clients_preserves_inventory_order ... ok
test ecosystem::clients::tests::test_ecosystem_special_case_clients_stay_explicit ... ok
test ecosystem::clients::tests::test_from_flag_aliases ... ok
test ecosystem::clients::tests::test_print_generic_config ... ok
test ecosystem::clients::tests::test_shared_editor_mapping_covers_supported_shared_hosts ... ok
test ecosystem::clients::tests::test_shared_host_config_paths_resolve_via_spore ... ok
test commands::doctor::tests::test_task_linked_council_check_passes_when_all_prereqs_exist ... ok
test commands::doctor::tool_checks::tests::probe_mcp_server_times_out_cleanly ... ok
test ecosystem::status::tests::test_installed_version_does_not_panic_for_optional_tool ... ok
test ecosystem::status::tests::test_render_status_report_snapshot ... ok
test ecosystem::status::tests::test_render_tool_status_snapshot_for_installed ... ok
test ecosystem::status::tests::test_render_tool_status_snapshot_for_optional_missing ... ok
test ecosystem::status::tests::test_discover_codex_version_does_not_panic ... ok
test tests::test_doctor_accepts_developer_flag ... ok
test tests::test_doctor_accepts_deep_flag ... ok
test tests::test_init_accepts_repair_flag ... ok
test tests::test_init_accepts_force_alias ... ok
test tests::test_install_accepts_full_profile_alias ... ok
test tests::test_install_accepts_developer_profile_alias ... ok
test tests::test_install_accepts_standard_profile ... ok
test tests::test_package_accepts_profile_and_dry_run ... ok
test tests::test_removed_setup_shim_is_rejected ... ok
test tests::test_self_update_check_subcommand_parses ... ok
test commands::host::tests::test_render_list_snapshot_includes_known_sections ... ok
test tests::test_update_accepts_profile_flag ... ok
test commands::doctor::tool_checks::tests::missing_volva_has_an_install_repair_action ... ok
test ecosystem::status::tests::test_claude_is_available_does_not_panic ... ok
test ecosystem::clients::tests::test_detect_clients_does_not_panic ... ok
test commands::doctor::tests::test_build_report_includes_host_inventory_checks ... ok
test commands::doctor::tool_checks::tests::probe_mcp_server_accepts_initialize_response ... ok
test commands::developer_tools::tests::developer_profile_tools_cover_all_tiers ... ok
test commands::doctor::tests::test_build_report_can_include_developer_tools ... ok
test commands::install::release::tests::verify_functional_checks_expected_output ... ok
test commands::install::release::tests::verify_mcp_handshake_accepts_initialize_round_trip ... ok

test result: ok. 155 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.72s

PASS: Package repair mentions rollback handling
PASS: Package repair has safety-focused tests
Results: 2 passed, 0 failed

<!-- PASTE END -->

**Checklist:**
- [x] tests cover rollback and backup-path behavior
- [x] full repo tests pass
- [x] verify script passes

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/stipe/verify-package-repair-safety-hardening.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/stipe/verify-package-repair-safety-hardening.sh
```

**Output:**
<!-- PASTE START -->
PASS: Package repair mentions rollback handling
PASS: Package repair has safety-focused tests
Results: 2 passed, 0 failed

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Follow-on from:

- `.handoffs/stipe/provider-mcp-plugin-doctor-expansion.md`
- `.handoffs/stipe/package-repair-profile-awareness.md`

This handoff exists to harden the package repair path after the profile-awareness work lands.
