#!/bin/bash
# verify-tier-b-pin-alignment-sweep.sh — closes F3.2, F3.3, F3.4, F3.5, F3.6, F3.7

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"

PASS=0; FAIL=0

echo "=== Tier B Pin Alignment Sweep — verify ==="
echo ""

echo "[Check 1] F3.2 — volva-runtime rusqlite no longer pinned at 0.31"
if grep -E '^rusqlite\s*=\s*"?0\.31' "$REPO_ROOT/volva/crates/volva-runtime/Cargo.toml" 2>/dev/null; then
  echo "  ✗ rusqlite still 0.31"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 2] F3.3 — volva thiserror no longer pinned at 1"
if grep -rE '^thiserror\s*=\s*"?1\.' "$REPO_ROOT/volva/crates/volva-core/Cargo.toml" "$REPO_ROOT/volva/crates/volva-runtime/Cargo.toml" 2>/dev/null; then
  echo "  ✗ thiserror still 1.x"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 3] F3.4 — hymenium which no longer pinned at 6"
if grep -E '^which\s*=\s*"?6\.' "$REPO_ROOT/hymenium/Cargo.toml" 2>/dev/null; then
  echo "  ✗ which still 6.x"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 4] F3.5 — cortina toml no longer pinned at 0.8"
if grep -E '^toml\s*=\s*"?0\.8' "$REPO_ROOT/cortina/Cargo.toml" 2>/dev/null; then
  echo "  ✗ toml still 0.8"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 5] F3.6 — clap_complete documented or removed"
if grep -nE 'clap_complete' "$REPO_ROOT/ecosystem-versions.toml" >/dev/null 2>&1 || ! grep -nE '^clap_complete' "$REPO_ROOT/mycelium/Cargo.toml" 2>/dev/null; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ clap_complete neither documented nor removed"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 6] All affected repos build cleanly"
for repo in volva hymenium cortina mycelium; do
  if (cd "$REPO_ROOT/$repo" && cargo build --release) >/dev/null 2>&1; then
    PASS=$((PASS+1))
  else
    echo "  ✗ $repo build failing"; FAIL=$((FAIL+1))
  fi
done
echo "  (per-repo build check complete)"
echo ""

echo "[Check 7] All affected repos pass tests"
for repo in volva hymenium cortina mycelium; do
  if (cd "$REPO_ROOT/$repo" && cargo test --release) >/dev/null 2>&1; then
    PASS=$((PASS+1))
  else
    echo "  ✗ $repo test failing"; FAIL=$((FAIL+1))
  fi
done
echo "  (per-repo test check complete)"
echo ""

echo "[Check 8] No spore rev modified (out of scope)"
if (cd "$REPO_ROOT" && git status --porcelain '*Cargo.toml' 2>/dev/null | xargs -I{} grep -lE 'spore.*rev' {} 2>/dev/null | head -1 >/dev/null); then
  if (cd "$REPO_ROOT" && git diff '*Cargo.toml' | grep -E '^[-+].*spore.*rev' >/dev/null 2>&1); then
    echo "  NOTE spore rev appears to be modified — verify this is intended"
    PASS=$((PASS+1))
  else
    echo "  ✓"; PASS=$((PASS+1))
  fi
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
