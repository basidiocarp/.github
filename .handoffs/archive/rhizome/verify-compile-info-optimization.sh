#!/usr/bin/env bash
set -euo pipefail

handoff=".handoffs/archive/rhizome/compile-info-optimization.md"
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
    echo "FAIL: unexpected pattern '$pattern' present in $path"
    fail=$((fail + 1))
  else
    echo "PASS: pattern '$pattern' absent from $path"
    pass=$((pass + 1))
  fi
}

check_checked() {
  local text="$1"
  local path="$2"
  if rg -Fq "[x] $text" "$path"; then
    echo "PASS: checked item '$text' found in $path"
    pass=$((pass + 1))
  else
    echo "FAIL: checked item '$text' missing in $path"
    fail=$((fail + 1))
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

check_tree_sitter_support_absent() {
  local language="$1"
  local path="$2"
  if sed -n '/pub fn tree_sitter_supported/,/}/p' "$path" | rg -q "$language"; then
    echo "FAIL: tree_sitter_supported still includes $language in $path"
    fail=$((fail + 1))
  else
    echo "PASS: tree_sitter_supported excludes $language in $path"
    pass=$((pass + 1))
  fi
}

check_file "$handoff"
check_grep "lang-all" "$handoff"
check_grep "tokio/full" "$handoff"
check_grep "profile.dev" "$handoff"
check_grep "tree-sitter-toml" "$handoff"
check_grep "C#" "$handoff"
check_grep "Swift" "$handoff"
check_grep "Haskell" "$handoff"
check_grep "This handoff is complete under the current scope" "$handoff"

check_grep "^\\[profile\\.dev\\]$" "rhizome/Cargo.toml"
check_grep '^debug = "line-tables-only"$' "rhizome/Cargo.toml"
check_grep '^opt-level = 1$' "rhizome/Cargo.toml"
check_grep '^\[profile\.dev\.package\."\*"\]$' "rhizome/Cargo.toml"

check_grep 'default-features = false' "rhizome/crates/rhizome-cli/Cargo.toml"
check_grep 'default-features = false' "rhizome/crates/rhizome-mcp/Cargo.toml"
check_grep 'default-features = false' "rhizome/crates/rhizome-lsp/Cargo.toml"
check_absent 'features = \["full"\]' "rhizome/crates/rhizome-cli/Cargo.toml"
check_absent 'features = \["full"\]' "rhizome/crates/rhizome-mcp/Cargo.toml"
check_absent 'features = \["full"\]' "rhizome/crates/rhizome-lsp/Cargo.toml"

check_grep '^\[features\]$' "rhizome/crates/rhizome-treesitter/Cargo.toml"
check_grep 'lang-all' "rhizome/crates/rhizome-treesitter/Cargo.toml"
check_grep 'lang-csharp = \["dep:tree-sitter-c-sharp"\]' "rhizome/crates/rhizome-treesitter/Cargo.toml"
check_grep 'lang-swift = \["dep:tree-sitter-swift"\]' "rhizome/crates/rhizome-treesitter/Cargo.toml"
check_grep 'lang-haskell = \["dep:tree-sitter-haskell"\]' "rhizome/crates/rhizome-treesitter/Cargo.toml"
check_grep 'optional = true' "rhizome/crates/rhizome-treesitter/Cargo.toml"
check_absent 'tree-sitter-toml' "rhizome/crates/rhizome-treesitter/Cargo.toml"

check_tree_sitter_support_absent 'Language::CSharp' "rhizome/crates/rhizome-core/src/language.rs"
check_tree_sitter_support_absent 'Language::Swift' "rhizome/crates/rhizome-core/src/language.rs"
check_tree_sitter_support_absent 'Language::Haskell' "rhizome/crates/rhizome-core/src/language.rs"
check_grep 'lang-all' "rhizome/README.md"
check_grep 'optional grammar pack' "rhizome/docs/language-setup.md"

check_checked 'the heaviest niche grammars are feature-flagged behind `lang-all`' "$handoff"
check_checked '`C#`, `Swift`, and `Haskell` are no longer tree-sitter-backed in the default build' "$handoff"
check_checked '`tokio/full` is removed from the Rhizome workspace crates' "$handoff"
check_checked 'repo-local `[profile.dev]` tuning is present' "$handoff"
check_checked 'the default grammar set is documented in repo docs' "$handoff"
check_checked 'the verification output is pasted into this handoff' "$handoff"
check_nonempty_paste_blocks "$handoff" 3

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -ne 0 ]]; then
  exit 1
fi
