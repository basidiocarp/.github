#!/bin/bash
# Verification script for hook-registration.md
# Run: bash .handoffs/mycelium/verify-hook-registration.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MYCELIUM_REPO="$ROOT/mycelium"
VERIFY_REPO=""

cleanup() {
  if [ -n "$VERIFY_REPO" ] && [ -d "$VERIFY_REPO" ]; then
    git -C "$MYCELIUM_REPO" worktree remove --force "$VERIFY_REPO" >/dev/null 2>&1 || rm -rf "$VERIFY_REPO"
  fi
}

prepare_verify_repo() {
  VERIFY_REPO="$(mktemp -d /tmp/mycelium-hook-registration.XXXXXX)"
  rmdir "$VERIFY_REPO"
  git -C "$MYCELIUM_REPO" worktree add --detach "$VERIFY_REPO" HEAD >/dev/null

  for path in \
    src/doctor_cmd.rs \
    src/gain/export.rs \
    src/hyphae_client.rs \
    src/init/context.rs \
    src/init/host_status.rs
  do
    cp "$MYCELIUM_REPO/$path" "$VERIFY_REPO/$path"
  done
}

trap cleanup EXIT

run_doctor() {
  (
    cd "$VERIFY_REPO"
    cargo run --quiet -- doctor
  )
}

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== MYCELIUM HOOK-REGISTRATION Verification ==="
echo ""

prepare_verify_repo

echo "--- Doctor Checks ---"
check "mycelium doctor runs" \
  "run_doctor"
check "no hook warning in doctor output" \
  "! run_doctor 2>&1 | grep -q '! Claude Code hook'"
check "no settings warning in doctor output" \
  "! run_doctor 2>&1 | grep -q '! claude settings'"

echo ""
echo "--- Hook Functionality ---"
check "cortina hook routes bash through mycelium" \
  "which git 2>/dev/null | grep -q '/'"
check "diagnostic passthrough works" \
  "echo 'passthrough test' 2>/dev/null | grep -q 'passthrough'"

echo ""
echo "--- Build ---"
check "cargo test passes" \
  "cd \"$VERIFY_REPO\" && cargo test --quiet 2>&1"
check "cargo clippy clean" \
  "cd \"$VERIFY_REPO\" && cargo clippy --all-targets --quiet 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
