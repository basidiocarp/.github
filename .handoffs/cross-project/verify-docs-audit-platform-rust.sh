#!/usr/bin/env bash
set -euo pipefail
PASS=0; FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$name"; FAIL=$((FAIL + 1))
  fi
}

check "rhizome README exists" test -f "$ROOT/rhizome/README.md"
check "stipe README exists" test -f "$ROOT/stipe/README.md"
check "canopy README exists" test -f "$ROOT/canopy/README.md"
check "stipe builds" /bin/zsh -lc "cd '$ROOT/stipe' && cargo build --release --quiet 2>&1"
check "canopy builds" /bin/zsh -lc "cd '$ROOT/canopy' && cargo build --release --quiet 2>&1"
check "rhizome builds" /bin/zsh -lc "cd '$ROOT/rhizome' && cargo build --release --quiet 2>&1"

# Verify no stale --interactive flag reference in stipe docs
check "no --interactive in stipe README" bash -c "! grep -q -- '--interactive' '$ROOT/stipe/README.md'"

# Verify rollback command is documented in stipe
check "rollback in stipe README" grep -q "stipe rollback" "$ROOT/stipe/README.md"

# Verify stipe init flags are documented
check "stipe init flags in README" grep -q "\-\-client\|--repair" "$ROOT/stipe/README.md"

# Verify stipe update flags are documented
check "stipe update flags in README" grep -q "\-\-profile" "$ROOT/stipe/README.md"

# Verify canopy situation command is documented
check "situation in canopy README" grep -q "canopy situation" "$ROOT/canopy/README.md"

# Verify task complete guard is hinted at
check "task complete in canopy README" grep -q "canopy task complete" "$ROOT/canopy/README.md"

# Verify actual CLI commands work
check "stipe init accepts --repair" /bin/zsh -lc "stipe init --help 2>&1 | grep -q '\-\-repair'"
check "stipe update accepts --profile" /bin/zsh -lc "stipe update --help 2>&1 | grep -q '\-\-profile'"
check "canopy situation exists" /bin/zsh -lc "canopy situation --help 2>&1 | grep -q 'agent-id'"
check "canopy task complete exists" /bin/zsh -lc "canopy task complete --help 2>&1" || true

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
