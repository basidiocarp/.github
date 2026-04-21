# Stipe Ratatui Console Surface

## Problem

`stipe` is the most operator-facing Rust CLI in the ecosystem, so it is the strongest
candidate for a richer terminal UI. But moving from `dialoguer`/`indicatif` to
`ratatui` is a product and maintenance decision, not just a dependency addition.

Adding `ratatui` without a scoped operator flow would create UI bloat and increase
maintenance cost for uncertain user benefit.

## What exists (state)

- **Current interaction model:** `stipe` uses `dialoguer` for selection and `indicatif`
  for progress.
- **User surface:** install, doctor, and host setup are the main operator workflows.
- **No TUI baseline:** there is no existing full-screen terminal UI in the ecosystem.

## What needs doing (intent)

Evaluate whether `ratatui` should be adopted in `stipe`, and if so, land it through
one bounded operator surface rather than a repo-wide UI rewrite.

---

### Step 1: Pick one bounded TUI candidate flow

**Project:** `stipe/`
**Effort:** 20-30 min
**Depends on:** nothing

Choose one operator workflow where a TUI would materially help. Good candidates are
install profile selection, doctor status display, or host setup previews.

#### Files to modify

**`stipe/` docs or handoff notes** — state the chosen TUI slice:

```text
- which flow is in scope
- which flows stay on plain CLI for now
- why ratatui adds value there
```

**Decision:** The only bounded candidate flow is `stipe doctor`.

- In scope as the only future `ratatui` candidate: the human-readable doctor status
  display, because it is the densest operator-facing view in the repo.
- Explicitly out of scope for now: install profile selection, host setup previews,
  package repair, and any repo-wide TUI shell around existing commands.
- Why this is the only credible slice: `doctor` already aggregates the most status
  data, so a dashboard would only make sense there. The other flows are shorter,
  more linear, and already fit the current `dialoguer` and `indicatif` model.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cd stipe && cargo tree | rg 'dialoguer|indicatif|ratatui'
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
├── dialoguer v0.12.0
├── indicatif v0.17.11

<!-- PASTE END -->

**Checklist:**
- [x] one bounded operator flow is selected
- [x] the handoff explicitly says where ratatui should not spread yet

---

### Step 2: Add or reject ratatui with a concrete decision

**Project:** `stipe/`
**Effort:** 45-90 min
**Depends on:** Step 1

Either add `ratatui` for the selected flow or explicitly reject it and record why the
existing `dialoguer`/`indicatif` model remains the better fit.

#### Files to modify

**`stipe/` source and docs** — implement or record the decision:

```text
- if adopted: one bounded ratatui slice only
- if rejected: document the decision and keep current interaction model
```

**Decision:** Reject `ratatui` for now and keep the current `dialoguer` and
`indicatif` interaction model.

Why reject it now:

- `stipe doctor` is the only bounded surface where a fullscreen dashboard might
  plausibly help, but the current plain output is already snapshot-tested, readable,
  and paired with `doctor --json` for machine consumers.
- A `ratatui` adoption would introduce a second rendering stack and a larger testing
  surface without a demonstrated operator workflow that is failing today.
- `stipe` commands are expected to stay easy to script, log, and run over SSH or in
  CI. The current text-first model preserves those properties with lower maintenance cost.

Recorded repo change:

- `stipe/README.md` now documents the terminal UI boundary: only `doctor` is a future
  candidate, and `ratatui` should not spread into install or host setup until one
  bounded `doctor` dashboard proves itself.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cd stipe && cargo test
```

**Output:**
<!-- PASTE START -->
    Finished `test` profile [unoptimized + debuginfo] target(s) in 0.23s
     Running unittests src/main.rs (target/debug/deps/stipe-fff34bb61a74d7a3)

running 168 tests
test commands::bin_paths::tests::test_local_bin_dir_prefers_override ... ok
test commands::bin_paths::tests::test_local_bin_dir_uses_home_on_non_windows ... ok
test commands::developer_tools::tests::parse_version_handles_plain_and_prefixed_output ... ok
test commands::doctor::package_checks::tests::test_lamella_roots_include_workspace_sibling ... ok
test commands::doctor::tests::test_build_report_includes_repair_actions_for_failures ... ok
test commands::developer_tools::tests::unknown_requested_tools_are_reported ... ok
test commands::claude_hooks::tests::test_claude_hooks_configured_at_path_detects_missing_hook ... ok
test commands::claude_hooks::tests::test_install_claude_hooks_at_path_is_idempotent ... ok
test commands::developer_tools::tests::install_advice_mentions_advisory_boundary ... ok
test commands::doctor::tests::test_check_hyphae_db_exists ... ok
test commands::codex_notify::tests::test_codex_notify_configured_at_path_detects_required_entries_with_extras ... ok
test commands::doctor::tests::test_config_mentions_servers_detects_required_names ... ok
test commands::doctor::tests::test_config_mentions_servers_detects_codex_toml ... ok
test commands::doctor::tests::test_health_check_struct ... ok
test commands::doctor::tests::test_render_report_includes_drift_section ... ok
test commands::doctor::tests::test_check_hyphae_db_missing ... ok
test commands::claude_hooks::tests::test_claude_hooks_configured_at_path_detects_missing_statusline ... ok
test commands::doctor::tests::test_render_report_snapshot_for_failure ... ok
test commands::doctor::tests::test_render_report_includes_hook_paths_section ... ok
test commands::doctor::tests::test_codex_notify_helpers_are_shared ... ok
test commands::codex_notify::tests::test_codex_notify_repair_action_points_at_host_setup ... ok
test commands::doctor::tests::test_render_report_includes_runtime_policy_section ... ok
test commands::doctor::tool_checks::tests::parse_initialize_response_accepts_expected_server ... ok
test commands::doctor::tests::test_codex_notify_adapter_configured_at_path_detects_notify_entry ... ok
test commands::doctor::tool_checks::tests::parse_initialize_response_rejects_wrong_server ... ok
test commands::codex_notify::tests::test_install_codex_notify_preserves_existing_notify_entries ... ok
test commands::host::tests::test_codex_doctor_report_includes_notify_repair ... ok
test commands::host::tests::test_doctor_checks_reflect_inventory_entry ... ok
test commands::host::tests::test_host_mode_mappings_are_explicit ... ok
test commands::doctor::tool_checks::tests::manual_tools_detect_standalone_repo_roots ... ok
test commands::host::tests::test_render_doctor_snapshot_for_failure ... ok
test commands::doctor::tool_checks::tests::manual_tools_detect_workspace_sibling_repos ... ok
test commands::host::tests::test_inventory_entry_uses_shared_host_descriptor_metadata ... ok
test commands::host_policy::tests::test_claude_hook_settings_paths_follow_scope ... ok
test commands::host_policy::tests::test_host_modes_resolve_config_paths_via_clients ... ok
test commands::host_policy::tests::test_codex_notify_paths_follow_scope ... ok
test commands::host_policy::tests::test_host_setup_repair_action_points_at_new_host_surface ... ok
test commands::host_policy::tests::test_install_profile_repair_action_keeps_cursor_distinct ... ok
test commands::host_policy::tests::test_local_scope_is_not_supported_for_codex_notify ... ok
test commands::host_policy::tests::test_supported_host_modes_have_explicit_descriptors ... ok
test commands::host_policy::tests::test_supported_scope_hint_is_stable_for_host_modes ... ok
test commands::init::baseline::tests::checksum_bytes_changes_with_content ... ok
test commands::init::baseline::tests::evaluate_drift_reports_modified_config_file ... ok
test commands::init::baseline::tests::evaluate_drift_reports_missing_mcp_registration ... ok
test commands::init::tests::test_build_plan_contains_repair_actions ... ok
test commands::init::tests::test_build_plan_does_not_switch_to_codex_profile_for_non_codex_targets ... ok
test commands::init::tests::test_build_plan_prefers_codex_profile_for_codex_targets ... ok
test commands::init::tests::test_build_plan_prefers_codex_profile_when_codex_is_detected_by_default ... ok
test commands::init::tests::test_claude_hooks_step_skips_broken_cortina_with_repair_guidance ... ok
test commands::init::tests::test_codex_notify_helpers_use_expected_values ... ok
test commands::init::tests::test_mcp_registration_step_skips_broken_tools_with_repair_guidance ... ok
test commands::init::tests::test_render_preview_lists_detected_clients_when_unfiltered ... ok
test commands::init::tests::test_build_plan_uses_host_setup_for_supported_target_hosts ... ok
test commands::init::tests::test_render_preview_mentions_codex_notify_adapter ... ok
test commands::init::tests::test_render_preview_mentions_claude_hooks_when_cortina_is_available ... ok
test commands::init::tests::test_render_preview_mentions_target_client_and_actions ... ok
test commands::init::tests::test_render_preview_snapshot_for_cursor_target ... ok
test commands::init::tests::test_targeted_claude_plan_does_not_pull_in_codex_repairs_from_detected_hosts ... ok
test commands::install::release::tests::parse_initialize_response_requires_protocol_version ... ok
test commands::init::tests::test_render_preview_reports_multiple_detected_hosts ... ok
test commands::doctor::tests::test_task_linked_council_check_reports_missing_prereqs ... ok
test commands::doctor::tests::test_optional_canopy_missing_is_not_a_failure ... ok
test commands::install::tests::test_extract_tarball_missing_binary ... ok
test commands::install::tests::test_find_matching_asset_missing_platform ... ok
test commands::install::tests::test_find_matching_asset_requires_tar_gz ... ok
test commands::install::tests::test_find_matching_asset_success ... ok
test commands::install::tests::test_format_install_preview_reports_existing_and_missing_tools ... ok
test commands::install::tests::test_extract_tarball_with_binary ... ok
test commands::install::tests::test_install_run_honors_project_runtime_policy_deny ... ok
test commands::install::tests::test_install_run_fails_when_project_runtime_policy_cannot_load ... ok
test commands::install::tests::test_install_run_honors_user_runtime_policy_deny_without_project_override ... ok
test commands::install::tests::test_install_run_persists_profile_and_approval_memory_on_success ... ok
test commands::install::tests::test_platform_key_known ... ok
test commands::install::tests::test_profile_config_round_trips ... ok
test commands::install::tests::test_profile_mode_labels_make_codex_explicit ... ok
test commands::install::tests::test_install_run_prefers_project_runtime_policy_over_user_policy ... ok
test commands::install::tests::test_profile_tools_cover_expected_sets ... ok
test commands::install::tests::test_render_install_preview_snapshot_for_interactive_mode ... ok
test commands::install::tests::test_render_profile_install_preview_snapshot ... ok
test commands::install::tests::test_render_install_preview_snapshot_for_explicit_tools ... ok
test commands::install::tests::test_resolve_requested_tools_handles_all_mode ... ok
test commands::install::tests::test_resolve_requested_tools_includes_manual_profile_members ... ok
test commands::install::tests::test_selected_profile_for_persistence_keeps_successful_non_developer_profile ... ok
test commands::install::tests::test_resolve_requested_tools_uses_profile_and_dedupes_extras ... ok
test commands::install::tests::test_selected_profile_for_persistence_skips_failed_installs ... ok
test commands::install::tests::test_split_requested_tools_keeps_manual_members_out_of_managed_installs ... ok
test commands::package_repair::tests::test_audit_event_includes_rollback_details_on_failure ... ok
test commands::package_repair::tests::test_cursor_profile_has_no_package_repair_surface ... ok
test commands::package_repair::tests::test_lamella_invocations_for_codex_profile ... ok
test commands::package_repair::tests::test_lamella_invocations_for_full_profile_include_both_surfaces ... ok
test commands::package_repair::tests::test_audit_log_best_effort_returns_warning_when_write_fails ... ok
test commands::package_repair::tests::test_lamella_root_candidates_include_workspace_sibling ... ok
test commands::package_repair::tests::test_missing_backup_is_treated_as_issue_in_failure_messaging ... ok
test commands::package_repair::tests::test_package_targets_for_claude_profile_stay_on_claude_surface ... ok
test commands::package_repair::tests::test_package_targets_for_codex_profile_stay_on_codex_surface ... ok
test commands::package_repair::tests::test_resolve_profile_prefers_explicit_then_saved_then_detected_default ... ok
test commands::package_repair::tests::test_rollback_decisions_restore_and_preserve_expected_paths ... ok
test commands::package_repair::tests::test_prepare_backups_roll_back_partial_state_when_later_backup_fails ... ok
test commands::package_repair::tests::test_rollback_summary_lines_call_out_manual_inspection_when_needed ... ok
test commands::package_repair::tests::test_sibling_backup_path_includes_timestamp_suffix ... ok
test commands::package_repair::tests::test_supports_profile_only_for_host_package_surfaces ... ok
test commands::runtime_policy::tests::test_enforce_install_profile_policy_blocks_load_errors ... ok
test commands::runtime_policy::tests::test_enforce_install_profile_policy_blocks_remembered_deny ... ok
test commands::runtime_policy::tests::test_project_scope_takes_precedence_over_user_scope ... ok
test commands::runtime_policy::tests::test_render_install_policy_lines_mentions_approval_memory ... ok
test commands::self_update::tests::normalize_version_trims_release_prefix ... ok
test commands::self_update::tests::replacement_path_uses_neighbor_file ... ok
test commands::tool_registry::probe::tests::supported_ecosystem_binaries_map_to_spore_tools ... ok
test commands::tool_registry::probe::tests::unmanaged_binaries_stay_outside_spore_mapping ... ok
test commands::tool_registry::probe::tests::verify_levels_are_ordered_from_shallow_to_deep ... ok
test commands::tool_registry::tests::test_doctor_specs_include_optional_canopy_and_volva ... ok
test commands::tool_registry::tests::test_ecosystem_and_status_views_only_reference_visible_tools ... ok
test commands::tool_registry::tests::test_install_all_and_update_all_cover_same_managed_release_tools ... ok
test commands::runtime_policy::tests::test_runtime_policy_round_trips_remembered_decisions ... ok
test commands::tool_registry::tests::test_install_profiles_only_reference_installable_tools ... ok
test commands::tool_registry::tests::test_mcp_serve_specs_match_expected_tools ... ok
test commands::tool_registry::tests::test_optional_doctor_tools_have_install_hints ... ok
test commands::tool_registry::tests::test_profile_tools_cover_expected_sets ... ok
test commands::tool_registry::tests::test_release_archive_binaries_include_managed_tools_and_stipe ... ok
test commands::tool_registry::tests::test_smoke_test_specs_match_expected_tools ... ok
test commands::tool_registry::tests::test_status_specs_include_optional_and_managed_tools ... ok
test commands::tool_registry::tests::test_volva_has_the_intended_operator_surface_membership ... ok
test commands::uninstall::tests::test_render_preview_output_snapshot ... ok
test commands::uninstall::tests::test_render_uninstall_preview_mentions_manual_cleanup ... ok
test commands::uninstall::tests::test_build_uninstall_targets_marks_existing_files ... ok
test commands::uninstall::tests::test_resolve_uninstall_tools_all_mode_includes_stipe ... ok
test commands::update::tests::installed_profile_tools_only_keep_installed_or_broken_members ... ok
test commands::update::tests::installed_profile_tools_with_helper_keeps_only_present_tools ... ok
test commands::update::tests::unique_tools_appends_explicit_extras_without_duplicates ... ok
test ecosystem::clients::tests::test_client_flag_roundtrip ... ok
test ecosystem::clients::tests::test_client_name_not_empty ... ok
test ecosystem::clients::tests::test_collect_detected_clients_does_not_map_vscode_to_cline ... ok
test ecosystem::clients::tests::test_collect_detected_clients_keeps_claude_hybrid_detection ... ok
test ecosystem::clients::tests::test_collect_detected_clients_preserves_inventory_order ... ok
test ecosystem::clients::tests::test_collect_detected_clients_keeps_continue_outside_shared_overlap ... ok
test ecosystem::clients::tests::test_ecosystem_special_case_clients_stay_explicit ... ok
test ecosystem::clients::tests::test_from_flag_aliases ... ok
test ecosystem::clients::tests::test_print_generic_config ... ok
test ecosystem::clients::tests::test_shared_editor_mapping_covers_supported_shared_hosts ... ok
test ecosystem::clients::tests::test_shared_host_config_paths_resolve_via_spore ... ok
test commands::doctor::tests::test_task_linked_council_check_passes_when_all_prereqs_exist ... ok
test ecosystem::status::tests::test_discover_codex_version_does_not_panic ... ok
test ecosystem::status::tests::test_installed_version_does_not_panic_for_optional_tool ... ok
test ecosystem::status::tests::test_render_status_report_snapshot ... ok
test ecosystem::status::tests::test_render_tool_status_snapshot_for_installed ... ok
test ecosystem::status::tests::test_render_tool_status_snapshot_for_optional_missing ... ok
test tests::test_doctor_accepts_deep_flag ... ok
test tests::test_doctor_accepts_developer_flag ... ok
test tests::test_init_accepts_force_alias ... ok
test tests::test_init_accepts_repair_flag ... ok
test tests::test_install_accepts_developer_profile_alias ... ok
test tests::test_install_accepts_full_profile_alias ... ok
test tests::test_install_accepts_standard_profile ... ok
test tests::test_package_accepts_profile_and_dry_run ... ok
test tests::test_removed_setup_shim_is_rejected ... ok
test commands::host::tests::test_render_list_snapshot_includes_known_sections ... ok
test tests::test_self_update_check_subcommand_parses ... ok
test tests::test_update_accepts_profile_flag ... ok
test commands::doctor::tool_checks::tests::probe_mcp_server_times_out_cleanly ... ok
test commands::doctor::tool_checks::tests::missing_volva_has_an_install_repair_action ... ok
test ecosystem::status::tests::test_claude_is_available_does_not_panic ... ok
test ecosystem::clients::tests::test_detect_clients_does_not_panic ... ok
test commands::doctor::tests::test_build_report_includes_host_inventory_checks ... ok
test commands::doctor::tool_checks::tests::probe_mcp_server_accepts_initialize_response ... ok
test commands::developer_tools::tests::developer_profile_tools_cover_all_tiers ... ok
test commands::doctor::tests::test_build_report_can_include_developer_tools ... ok
test commands::install::release::tests::verify_functional_checks_expected_output ... ok
test commands::install::release::tests::verify_mcp_handshake_accepts_initialize_round_trip ... ok

test result: ok. 168 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.63s

<!-- PASTE END -->

**Checklist:**
- [x] ratatui adoption is either implemented in one bounded slice or explicitly rejected
- [x] stipe remains test-green after the decision

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/stipe/verify-ratatui-console-surface.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/stipe/verify-ratatui-console-surface.sh
```

**Output:**
<!-- PASTE START -->
PASS: file exists - .handoffs/archive/stipe/ratatui-console-surface.md
PASS: pattern 'ratatui' found in .handoffs/archive/stipe/ratatui-console-surface.md
PASS: pattern 'dialoguer' found in .handoffs/archive/stipe/ratatui-console-surface.md
PASS: pattern 'indicatif' found in .handoffs/archive/stipe/ratatui-console-surface.md
PASS: pattern '\[x\] one bounded operator flow is selected|\[ \] one bounded operator flow is selected' found in .handoffs/archive/stipe/ratatui-console-surface.md
PASS: pattern '\[x\] ratatui adoption is either implemented in one bounded slice or explicitly rejected|\[ \] ratatui adoption is either implemented in one bounded slice or explicitly rejected' found in .handoffs/archive/stipe/ratatui-console-surface.md
Results: 6 passed, 0 failed

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

This handoff exists because `stipe` is the most user-facing Rust CLI in the ecosystem,
so if any repo should adopt `ratatui`, it is the right place to evaluate it first.
