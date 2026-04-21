#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$script_dir/../../.." && pwd)"
handoff="$root/.handoffs/archive/mycelium/compile-info-optimization.md"
pass=0
fail=0
grep -q "bundled SQLite stays on purpose" "$handoff" && pass=$((pass+1)) || { echo "FAIL: SQLite decision missing"; fail=$((fail+1)); }
grep -q "direct \`ureq\` is removed" "$handoff" && pass=$((pass+1)) || { echo "FAIL: ureq completion missing"; fail=$((fail+1)); }
grep -q "dev builds use the tuned profile" "$handoff" && pass=$((pass+1)) || { echo "FAIL: profile.dev completion missing"; fail=$((fail+1)); }
grep -q "bundled SQLite keeps savings history and tracking analytics local and portable" "$root/mycelium/docs/architecture.md" && pass=$((pass+1)) || { echo "FAIL: bundled SQLite docs note missing"; fail=$((fail+1)); }
grep -q "\[profile.dev\]" "$root/mycelium/Cargo.toml" && pass=$((pass+1)) || { echo "FAIL: profile.dev block missing from Cargo.toml"; fail=$((fail+1)); }
! rg -q '^[[:space:]]*ureq[[:space:]]*=' "$root/mycelium/Cargo.toml" && pass=$((pass+1)) || { echo "FAIL: direct ureq still present in Cargo.toml"; fail=$((fail+1)); }
rg -q '^\[profile\.dev\]' "$root/mycelium/Cargo.toml" && pass=$((pass+1)) || { echo "FAIL: profile.dev target missing"; fail=$((fail+1)); }
echo "Results: $pass passed, $fail failed"
exit "$fail"
