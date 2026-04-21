#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$name"
    FAIL=$((FAIL + 1))
  fi
}

check "Hyphae MCP server mentions resources" \
  rg -q 'resource|resources' "$ROOT/hyphae/crates/hyphae-mcp/src/server.rs"

check "Hyphae context surface exists" \
  test -f "$ROOT/hyphae/crates/hyphae-mcp/src/tools/context.rs"

check "Hyphae mentions council, compact, or understanding artifacts" \
  rg -q 'council|compact|understanding|artifact' "$ROOT/hyphae/crates"

check "Hyphae retrieval mentions redaction or filtering" \
  rg -q 'redact|filter|sanitize' "$ROOT/hyphae/crates"

check "Hyphae resource reads require explicit project context" \
  cargo test --manifest-path "$ROOT/hyphae/Cargo.toml" test_handle_resources_read_requires_explicit_or_detected_project -- --exact --nocapture >/dev/null

check "Hyphae resource list hides current resources without project context" \
  cargo test --manifest-path "$ROOT/hyphae/Cargo.toml" test_handle_resources_list_requires_explicit_or_detected_project -- --exact --nocapture >/dev/null

check "Hyphae initialize preload is redacted" \
  cargo test --manifest-path "$ROOT/hyphae/Cargo.toml" test_handle_initialize_redacts_secret_preload_content -- --exact --nocapture >/dev/null

check "Hyphae initialize without project skips passive preload" \
  cargo test --manifest-path "$ROOT/hyphae/Cargo.toml" test_initial_context_without_project_skips_passive_preload -- --exact --nocapture >/dev/null

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
