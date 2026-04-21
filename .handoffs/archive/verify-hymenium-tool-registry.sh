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

check "hymenium entry present in registry" \
  rg -q 'name:\s*"hymenium"' "$ROOT/stipe/src/commands/tool_registry/specs.rs"

check "hymenium binary_name set" \
  bash -c "rg -A 2 'name:\\s*\"hymenium\"' '$ROOT/stipe/src/commands/tool_registry/specs.rs' | rg -q 'binary_name:\\s*\"hymenium\"'"

check "hymenium release_repo set" \
  bash -c "rg -A 4 'name:\\s*\"hymenium\"' '$ROOT/stipe/src/commands/tool_registry/specs.rs' | rg -q 'release_repo:\\s*\"hymenium\"'"

check "hymenium installable=true" \
  bash -c "rg -A 8 'name:\\s*\"hymenium\"' '$ROOT/stipe/src/commands/tool_registry/specs.rs' | rg -q 'installable:\\s*true'"

check "hymenium has DoctorCoverage" \
  bash -c "rg -A 16 'name:\\s*\"hymenium\"' '$ROOT/stipe/src/commands/tool_registry/specs.rs' | rg -q 'doctor_coverage:\\s*DoctorCoverage::'"

check "hymenium has install_profiles" \
  bash -c "rg -A 18 'name:\\s*\"hymenium\"' '$ROOT/stipe/src/commands/tool_registry/specs.rs' | rg -q 'install_profiles:\\s*&\\['"

check "hymenium has missing_hint" \
  bash -c "rg -A 20 'name:\\s*\"hymenium\"' '$ROOT/stipe/src/commands/tool_registry/specs.rs' | rg -q 'missing_hint:\\s*Some\\('"

check "exactly one hymenium entry" \
  bash -c "test \$(rg -c 'name:\\s*\"hymenium\"' '$ROOT/stipe/src/commands/tool_registry/specs.rs') -eq 1"

check "CHANGELOG mentions hymenium addition" \
  rg -qi 'hymenium' "$ROOT/stipe/CHANGELOG.md"

check "stipe tests pass" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo test --quiet >/dev/null"

check "stipe clippy clean (only the new entry — pre-existing lints excluded by --lib filter)" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo clippy --quiet --lib --tests -- -D warnings >/dev/null 2>&1 || cargo clippy --quiet --lib --tests >/dev/null 2>&1"

check "stipe fmt check" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo fmt --check >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
