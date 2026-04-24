#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/stipe" 2>/dev/null || {
  echo "FAIL: could not find stipe repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "annulus probe in context" grep -rq "annulus_probe\|annulus.*ToolProbe" src/ecosystem/context.rs
check "annulus in tool snapshot" grep -rq "annulus_installed" src/commands/init/model.rs
check "annulus statusline command" grep -rq "annulus statusline\|ANNULUS_STATUSLINE" src/commands/claude_hooks.rs
check "annulus in init plan" grep -rq "annulus" src/commands/init/plan.rs
check "annulus config generation" grep -rq "statusline.toml\|annulus.*config\|config.*annulus" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
