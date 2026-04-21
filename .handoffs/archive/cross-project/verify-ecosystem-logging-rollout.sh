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

check "Spore owns shared logging surface" \
  rg -q 'init_with_env|stderr|RUST_LOG' "$ROOT/spore/src/logging.rs" "$ROOT/spore/CLAUDE.md" "$ROOT/spore/README.md"

check "Spore exposes app-aware and safe logging init surface" \
  rg -q 'init_app|try_init|LoggingConfig|format|json|pretty' "$ROOT/spore/src/logging.rs" "$ROOT/spore/CLAUDE.md" "$ROOT/spore/README.md"

check "Spore documents tracing or span-aware failure localization" \
  rg -q 'span|trace|request_id|session_id|workflow|subprocess' "$ROOT/spore/src/logging.rs" "$ROOT/spore/CLAUDE.md" "$ROOT/spore/README.md"

check "Rhizome exposes repo-specific logging" \
  rg -q 'RHIZOME_LOG|spore::logging::init_with_env|spore::logging::init' "$ROOT/rhizome"

check "Hyphae exposes repo-specific logging" \
  rg -q 'HYPHAE_LOG|spore::logging::init_with_env|spore::logging::init' "$ROOT/hyphae"

check "Mycelium exposes repo-specific logging" \
  rg -q 'MYCELIUM_LOG|spore::logging::init_with_env|spore::logging::init' "$ROOT/mycelium"

check "Cortina exposes repo-specific logging" \
  rg -q 'CORTINA_LOG|spore::logging::init_with_env|spore::logging::init' "$ROOT/cortina"

check "Canopy exposes repo-specific logging" \
  rg -q 'CANOPY_LOG|spore::logging::init_with_env|spore::logging::init' "$ROOT/canopy"

check "Stipe exposes repo-specific logging" \
  rg -q 'STIPE_LOG|spore::logging::init_with_env|spore::logging::init' "$ROOT/stipe"

check "Volva exposes repo-specific logging" \
  rg -q 'VOLVA_LOG|spore::logging::init_with_env|spore::logging::init' "$ROOT/volva"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
