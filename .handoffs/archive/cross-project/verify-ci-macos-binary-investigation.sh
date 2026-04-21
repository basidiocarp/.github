#!/bin/bash
# Verification script for ci-macos-binary-investigation.md
# Run: bash .handoffs/cross-project/verify-ci-macos-binary-investigation.sh

set -euo pipefail
PASS=0
FAIL=0

workspace_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
timeout_bin="${TIMEOUT_BIN:-}"
if [ -z "$timeout_bin" ]; then
  if command -v timeout >/dev/null 2>&1; then
    timeout_bin="$(command -v timeout)"
  elif command -v gtimeout >/dev/null 2>&1; then
    timeout_bin="$(command -v gtimeout)"
  else
    echo "Missing timeout command (need timeout or gtimeout)" >&2
    exit 1
  fi
fi

pick_binary() {
  for candidate in "$@"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

HYPHAE_BIN="${HYPHAE_BIN:-$(pick_binary \
  "$workspace_root/hyphae/target/release/hyphae" \
  "$HOME/.local/bin/hyphae" || true)}"
RHIZOME_BIN="${RHIZOME_BIN:-$(pick_binary \
  "$workspace_root/rhizome/target/release/rhizome" \
  "$HOME/.local/bin/rhizome" || true)}"
MYCELIUM_BIN="${MYCELIUM_BIN:-$(pick_binary \
  "$workspace_root/mycelium/target/release/mycelium" \
  "$HOME/.local/bin/mycelium" \
  "$(command -v mycelium 2>/dev/null || true)" || true)}"

if [ -n "${HYPHAE_BIN:-}" ]; then
  export PATH="$(dirname "$HYPHAE_BIN"):$PATH"
fi
if [ -n "${RHIZOME_BIN:-}" ]; then
  export PATH="$(dirname "$RHIZOME_BIN"):$PATH"
fi
if [ -n "${MYCELIUM_BIN:-}" ]; then
  export PATH="$(dirname "$MYCELIUM_BIN"):$PATH"
fi

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

echo "=== CI-MACOS-BINARY-INVESTIGATION Verification ==="
echo ""
echo "Using hyphae:   ${HYPHAE_BIN:-missing}"
echo "Using rhizome:  ${RHIZOME_BIN:-missing}"
echo "Using mycelium: ${MYCELIUM_BIN:-missing}"
echo ""

echo "--- Hyphae Binary ---"
check "hyphae binary exists at ~/.local/bin/" \
  "test -x \"$HYPHAE_BIN\""
check "hyphae --version responds" \
  "\"$timeout_bin\" 5 \"$HYPHAE_BIN\" --version"
check "hyphae stats completes without SIGKILL" \
  "\"$timeout_bin\" 10 \"$HYPHAE_BIN\" stats"
check "hyphae MCP handshake responds" \
  "printf '%s' '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{},\"clientInfo\":{\"name\":\"test\",\"version\":\"0.1\"}}}' | \"$timeout_bin\" 10 \"$HYPHAE_BIN\" serve 2>&1 | grep -q protocolVersion"

echo ""
echo "--- Rhizome Binary ---"
check "rhizome binary exists at ~/.local/bin/" \
  "test -x \"$RHIZOME_BIN\""
check "rhizome --version responds" \
  "\"$timeout_bin\" 5 \"$RHIZOME_BIN\" --version"
check "rhizome symbols exercises tree-sitter" \
  "\"$timeout_bin\" 10 \"$RHIZOME_BIN\" symbols \"$workspace_root/rhizome/crates/rhizome-cli/src/main.rs\" 2>&1 | grep -q 'fn main'"
check "rhizome MCP handshake responds" \
  "printf '%s' '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{},\"clientInfo\":{\"name\":\"test\",\"version\":\"0.1\"}}}' | \"$timeout_bin\" 10 \"$RHIZOME_BIN\" serve --expanded 2>&1 | grep -q protocolVersion"

echo ""
echo "--- Mycelium Doctor ---"
check "mycelium doctor shows no broken tools" \
  "\"$MYCELIUM_BIN\" doctor >/tmp/mycelium-doctor.log 2>&1 && ! grep -q '^!' /tmp/mycelium-doctor.log"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
