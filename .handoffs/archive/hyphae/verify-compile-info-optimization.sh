#!/usr/bin/env bash
set -euo pipefail

handoff=".handoffs/archive/hyphae/compile-info-optimization.md"
pass=0
fail=0

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "PASS: file exists - $path"
    pass=$((pass + 1))
  else
    echo "FAIL: missing file - $path"
    fail=$((fail + 1))
  fi
}

check_grep() {
  local pattern="$1"
  local path="$2"
  if rg -q "$pattern" "$path"; then
    echo "PASS: pattern '$pattern' found in $path"
    pass=$((pass + 1))
  else
    echo "FAIL: pattern '$pattern' missing in $path"
    fail=$((fail + 1))
  fi
}

check_absent() {
  local pattern="$1"
  local path="$2"
  if rg -q "$pattern" "$path"; then
    echo "FAIL: unexpected pattern '$pattern' still present in $path"
    fail=$((fail + 1))
  else
    echo "PASS: pattern '$pattern' absent from $path"
    pass=$((pass + 1))
  fi
}

check_nonempty_paste_blocks() {
  local path="$1"
  local expected_blocks="$2"
  local result

  result="$(awk '
    /<!-- PASTE START -->/ { in_block=1; block_count++; has_content=0; next }
    /<!-- PASTE END -->/ {
      if (in_block && has_content) {
        filled_count++;
      }
      in_block=0;
      next
    }
    in_block {
      line=$0;
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line);
      if (line != "") {
        has_content=1;
      }
    }
    END {
      printf "%d %d\n", block_count, filled_count;
    }
  ' "$path")"

  local block_count="${result%% *}"
  local filled_count="${result##* }"

  if [[ "$block_count" == "$expected_blocks" ]]; then
    echo "PASS: found $block_count paste blocks in $path"
    pass=$((pass + 1))
  else
    echo "FAIL: expected $expected_blocks paste blocks in $path, found $block_count"
    fail=$((fail + 1))
  fi

  if [[ "$filled_count" == "$expected_blocks" ]]; then
    echo "PASS: all $filled_count paste blocks contain output in $path"
    pass=$((pass + 1))
  else
    echo "FAIL: expected $expected_blocks filled paste blocks in $path, found $filled_count"
    fail=$((fail + 1))
  fi
}

check_file "$handoff"
check_grep "profile.dev" "$handoff"
check_grep "modern_sqlite" "$handoff"
check_grep "hf-hub" "$handoff"
check_grep "ureq" "$handoff"
check_grep "cargo build --workspace" "$handoff"
check_grep "cargo test --workspace" "$handoff"
check_grep "cargo build --workspace --no-default-features" "$handoff"
check_grep "Landed repo-local dev profile tuning" "$handoff"
check_grep "Removed the unneeded" "$handoff"
check_grep "prebuilt binaries" "$handoff"
check_grep "Left the" "$handoff"
check_grep "upstream .*fastembed" "$handoff"
check_grep "hf-hub 0.5.x" "$handoff"
check_grep "This handoff is complete under the current scope" "$handoff"
check_absent "no repo-local \\[profile\\.dev\\] tuning" "$handoff"
check_absent "modern_sqlite may be enabled without proven need" "$handoff"
check_grep "^\\[profile\\.dev\\]$" "hyphae/Cargo.toml"
check_absent "modern_sqlite" "hyphae/Cargo.toml"
check_grep "Install the prebuilt binary with the default embeddings feature" "hyphae/install.sh"
check_grep "unknown-linux-musl" "hyphae/install.sh"
check_nonempty_paste_blocks "$handoff" 3

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -ne 0 ]]; then
  exit 1
fi
