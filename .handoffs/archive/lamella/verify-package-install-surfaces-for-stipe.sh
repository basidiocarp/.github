#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"
LAMELLA_ROOT="$ROOT/lamella"

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

check "Lamella handoff mentions install surface contract" \
  rg -q 'install surface|preset|machine-callable|stipe' "$ROOT/.handoffs/archive/lamella/package-install-surfaces-for-stipe.md"

check "Lamella preset surface file exists" \
  test -f "$LAMELLA_ROOT/resources/presets/stipe-package-repair.toml"

check "Lamella preset defines an install plugin surface" \
  rg -q '^\[install\]|plugins = \[' "$LAMELLA_ROOT/resources/presets/stipe-package-repair.toml"

check "Lamella install help exposes --preset" \
  /bin/zsh -lc "cd '$LAMELLA_ROOT' && ./lamella install --help 2>&1 | rg -q -- '--preset <name>'"

check "Lamella preset dry-run resolves the Stipe repair surface" \
  /bin/zsh -lc "cd '$LAMELLA_ROOT' && ./lamella install --preset stipe-package-repair --dry-run 2>&1 | rg -q 'Installing preset surface:'"

check "Lamella docs explain the Stipe-facing boundary" \
  rg -q 'stipe-package-repair|Lamella-owned repair surface|Lamella-owned contracts' \
    "$LAMELLA_ROOT/README.md" \
    "$LAMELLA_ROOT/CLAUDE.md" \
    "$LAMELLA_ROOT/docs/maintainers/tool-boundary-cleanup.md"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
