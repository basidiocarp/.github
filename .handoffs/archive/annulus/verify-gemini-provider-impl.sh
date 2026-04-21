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

check "gemini provider source modified" \
  bash -c "! grep -q 'Ok(None)$' '$ROOT/annulus/src/providers/gemini.rs' || grep -q 'fn session_usage' '$ROOT/annulus/src/providers/gemini.rs'"

check "gemini provider has real reader (not stub)" \
  bash -c "wc -l < '$ROOT/annulus/src/providers/gemini.rs' | awk '{ exit !(\$1 > 50) }'"

check "gemini integration test exists" \
  test -f "$ROOT/annulus/tests/gemini_provider.rs"

check "gemini format spec exists (dependency #119a)" \
  test -f "$ROOT/annulus/docs/providers/gemini.md"

check "gemini fixture exists (dependency #119a)" \
  test -d "$ROOT/annulus/tests/fixtures/gemini"

check "annulus tests pass" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo test --quiet >/dev/null"

check "gemini provider tests pass" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo test --quiet providers::gemini >/dev/null"

check "annulus clippy clean" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo clippy --all-targets --quiet -- -D warnings >/dev/null 2>&1"

check "annulus fmt check" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo fmt --check >/dev/null"

check "no new unwrap in gemini.rs production code" \
  bash -c "! grep -nE '\.unwrap\(\)' '$ROOT/annulus/src/providers/gemini.rs' | grep -v '#\[cfg(test)\]' | grep -v 'mod tests' | grep -q ."

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
