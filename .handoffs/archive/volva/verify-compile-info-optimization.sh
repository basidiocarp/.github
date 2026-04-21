#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$script_dir/../../.." && pwd)"
repo="$root/volva/Cargo.toml"
README="$root/volva/README.md"
handoff="$root/.handoffs/archive/volva/compile-info-optimization.md"
pass=0
fail=0
section_has() {
  local section="$1"
  local pattern="$2"
  awk -v section="$section" -v pattern="$pattern" '
    BEGIN { in_section = 0; found = 0 }
    /^\[/ {
      in_section = ($0 == section)
    }
    in_section && $0 ~ pattern {
      found = 1
    }
    END {
      exit(found ? 0 : 1)
    }
  ' "$repo"
}

section_has "[profile.release]" 'opt-level = 3' && pass=$((pass+1)) || { echo "FAIL: release opt-level missing"; fail=$((fail+1)); }
section_has "[profile.release]" 'lto = true' && pass=$((pass+1)) || { echo "FAIL: release lto missing"; fail=$((fail+1)); }
section_has "[profile.release]" 'codegen-units = 1' && pass=$((pass+1)) || { echo "FAIL: release codegen-units missing"; fail=$((fail+1)); }
section_has "[profile.release]" 'panic = "abort"' && pass=$((pass+1)) || { echo "FAIL: release panic policy missing"; fail=$((fail+1)); }
section_has "[profile.release]" 'strip = true' && pass=$((pass+1)) || { echo "FAIL: release strip missing"; fail=$((fail+1)); }
section_has "[profile.dev]" 'opt-level = 1' && pass=$((pass+1)) || { echo "FAIL: dev opt-level missing"; fail=$((fail+1)); }
section_has "[profile.dev]" 'debug = "line-tables-only"' && pass=$((pass+1)) || { echo "FAIL: dev debug info missing"; fail=$((fail+1)); }
section_has '[profile.dev.package."*"]' 'opt-level = 3' && pass=$((pass+1)) || { echo "FAIL: dev package opt-level missing"; fail=$((fail+1)); }
grep -q "reqwest stays the intended async HTTP stack" "$README" && pass=$((pass+1)) || { echo "FAIL: README async HTTP note missing"; fail=$((fail+1)); }
grep -q "Complete." "$handoff" && pass=$((pass+1)) || { echo "FAIL: handoff status missing"; fail=$((fail+1)); }
echo "Results: $pass passed, $fail failed"
exit "$fail"
