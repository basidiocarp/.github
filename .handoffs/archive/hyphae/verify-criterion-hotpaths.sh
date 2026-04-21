#!/usr/bin/env bash
set -euo pipefail

pass_count=0
fail_count=0

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "PASS: file exists - $path"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: missing file - $path"
    fail_count=$((fail_count + 1))
  fi
}

check_grep() {
  local pattern="$1"
  local path="$2"
  if rg -q "$pattern" "$path"; then
    echo "PASS: pattern '$pattern' found in $path"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: pattern '$pattern' missing in $path"
    fail_count=$((fail_count + 1))
  fi
}

check_checked() {
  local text="$1"
  local path="$2"
  if rg -Fq "[x] $text" "$path"; then
    echo "PASS: checked item '$text' found in $path"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: checked item '$text' missing in $path"
    fail_count=$((fail_count + 1))
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
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: expected $expected_blocks paste blocks in $path, found $block_count"
    fail_count=$((fail_count + 1))
  fi

  if [[ "$filled_count" == "$expected_blocks" ]]; then
    echo "PASS: all $filled_count paste blocks contain output in $path"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: expected $expected_blocks filled paste blocks in $path, found $filled_count"
    fail_count=$((fail_count + 1))
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDOFF="$SCRIPT_DIR/criterion-hotpaths.md"
BENCH_FILE="hyphae/crates/hyphae-store/benches/retrieval_hot_paths.rs"
CARGO_TOML="hyphae/crates/hyphae-store/Cargo.toml"

check_file "$HANDOFF"
check_file "$BENCH_FILE"
check_file "$CARGO_TOML"
check_grep "criterion = \"0.5\"" "$CARGO_TOML"
check_grep "\\[\\[bench\\]\\]" "$CARGO_TOML"
check_grep "retrieval_hot_paths" "$BENCH_FILE"
check_grep "search_hybrid_scoped" "$BENCH_FILE"
check_grep "search_all" "$BENCH_FILE"
check_grep "build_fixture" "$BENCH_FILE"
check_grep "SqliteStore::in_memory" "$BENCH_FILE"
check_grep "with_ymd_and_hms" "$BENCH_FILE"
check_grep "store_document" "$BENCH_FILE"
check_grep "store_chunks" "$BENCH_FILE"
check_grep "cargo bench --no-run -p hyphae-store --bench retrieval_hot_paths" "$HANDOFF"
check_grep "search_hybrid_scoped" "$HANDOFF"
check_grep "search_all" "$HANDOFF"
check_grep "apply_decay" "$HANDOFF"
check_grep "get_neighborhood" "$HANDOFF"
check_grep "chunk_text" "$HANDOFF"
check_checked "criterion was added only to hyphae-store" "$HANDOFF"
check_checked "retrieval_hot_paths.rs benchmarks search_hybrid_scoped" "$HANDOFF"
check_checked "retrieval_hot_paths.rs benchmarks search_all" "$HANDOFF"
check_checked "the benchmark fixtures are deterministic and network-free" "$HANDOFF"
check_checked "later-wave candidates are documented but intentionally left out of the first bench target" "$HANDOFF"
check_checked "the verification output is pasted into this handoff" "$HANDOFF"
check_nonempty_paste_blocks "$HANDOFF" 2

echo "Results: ${pass_count} passed, ${fail_count} failed"
if [[ "$fail_count" -ne 0 ]]; then
  exit 1
fi
