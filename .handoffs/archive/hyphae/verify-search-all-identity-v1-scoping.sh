#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../../.."/hyphae

echo "[1/3] search_all identity tests"
cargo test search_all

echo "[2/3] targeted identity contract tests"
cargo test test_tool_search_all_rejects_partial_identity_pair

echo "[3/3] full hyphae suite"
cargo test
