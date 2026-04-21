#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"
RHIZOME="$ROOT/rhizome"
PARSER_RS="$RHIZOME/crates/rhizome-treesitter/src/parser.rs"

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

check "serve-path regression test passes" \
  bash -lc "cd '$RHIZOME' && cargo test -p rhizome-cli --test serve_lsp_runtime --quiet"

check "rhizome-mcp tests pass" \
  bash -lc "cd '$RHIZOME' && cargo test -p rhizome-mcp --quiet"

check "get_diagnostics via serve returns JSON-RPC without runtime panic" \
  bash -lc "cd '$RHIZOME' && OUT=\$(printf '%s\n%s\n' \
    '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}' \
    '{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"get_diagnostics\",\"arguments\":{\"file\":\"$PARSER_RS\"}}}' \
    | cargo run -q -p rhizome-cli -- serve --expanded 2>&1); \
    printf '%s' \"\$OUT\" | rg -q '\"id\":2'; \
    ! printf '%s' \"\$OUT\" | rg -q 'Cannot start a runtime from within a runtime|panicked at'"

check "find_references via serve returns JSON-RPC without runtime panic" \
  bash -lc "cd '$RHIZOME' && OUT=\$(printf '%s\n%s\n' \
    '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}' \
    '{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"find_references\",\"arguments\":{\"file\":\"$PARSER_RS\",\"line\":29,\"column\":11}}}' \
    | cargo run -q -p rhizome-cli -- serve --expanded 2>&1); \
    printf '%s' \"\$OUT\" | rg -q '\"id\":2'; \
    ! printf '%s' \"\$OUT\" | rg -q 'Cannot start a runtime from within a runtime|panicked at'"

check "LSP client no longer discards stderr to Stdio::null" \
  bash -lc "! rg -q 'stderr\\(std::process::Stdio::null\\(\\)\\)' '$RHIZOME/crates/rhizome-lsp/src/client.rs'"

check "troubleshooting docs mention stderr and debug logging for live serve failures" \
  bash -lc "rg -q 'forwards child stderr|RHIZOME_LOG=debug rhizome serve' '$RHIZOME/docs/troubleshooting.md'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
