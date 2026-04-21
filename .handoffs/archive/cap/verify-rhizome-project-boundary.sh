#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

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

ROOT="/Users/williamnewton/projects/basidiocarp"

check "Project route has explicit allowlist handling" \
  rg -q "CAP_ALLOWED_PROJECT_ROOTS|allowed project root|recent project|allowedRoots" "$ROOT/cap/server/routes/rhizome/project.ts"
check "Project route still validates directories" \
  rg -q "isDirectory|statSync|existsSync" "$ROOT/cap/server/routes/rhizome/project.ts"
check "Boundary tests cover project boundary cases" \
  rg -q "allowed the current recent project root|disallowed a directory path|CAP_ALLOWED_PROJECT_ROOTS|still rejects non-directory paths" "$ROOT/cap/server/__tests__/rhizome-project-boundary.test.ts"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
