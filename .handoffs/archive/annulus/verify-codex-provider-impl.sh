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

check "codex provider source modified" \
  bash -c "! grep -q 'Ok(None)$' '$ROOT/annulus/src/providers/codex.rs' || grep -q 'fn session_usage' '$ROOT/annulus/src/providers/codex.rs'"

check "codex provider has real reader (not stub)" \
  bash -c "wc -l < '$ROOT/annulus/src/providers/codex.rs' | awk '{ exit !(\$1 > 50) }'"

check "codex integration test exists" \
  test -f "$ROOT/annulus/tests/codex_provider.rs"

check "codex format spec exists (dependency #118a)" \
  test -f "$ROOT/annulus/docs/providers/codex.md"

check "codex fixture exists (dependency #118a)" \
  test -d "$ROOT/annulus/tests/fixtures/codex"

check "annulus tests pass" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo test --quiet >/dev/null"

check "codex provider tests pass" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo test --quiet providers::codex >/dev/null"

check "annulus clippy clean" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo clippy --all-targets --quiet -- -D warnings >/dev/null 2>&1"

check "annulus fmt check" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo fmt --check >/dev/null"

check "no new unwrap in codex.rs production code" \
  bash -c "! grep -nE '\.unwrap\(\)' '$ROOT/annulus/src/providers/codex.rs' | grep -v '#\[cfg(test)\]' | grep -v 'mod tests' | grep -q ."

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
