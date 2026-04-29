#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

pass=0
fail=0

run_check() {
  local name="$1"
  shift
  echo "==> $name"
  if "$@"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
  fi
}

run_check "docs validator" python3 scripts/validate-docs.py
run_check "install matrix names current tools" sh -c "rg -n 'annulus' docs/operate/release-and-install-matrix.md && rg -n 'hymenium' docs/operate/release-and-install-matrix.md && rg -n 'volva' docs/operate/release-and-install-matrix.md"
run_check "install scope names Volva" sh -c "rg -n 'volva' docs/getting-started/install-scope.md"
run_check "Stipe README full profile names registry tools" sh -c "rg -n 'annulus' stipe/README.md && rg -n 'hymenium' stipe/README.md && rg -n 'volva' stipe/README.md"
run_check "full-stack dry run" sh -c "cd stipe && cargo run -- install --profile full-stack --dry-run"
run_check "direct tool dry runs" sh -c "cd stipe && cargo run -- install annulus --dry-run && cargo run -- install hymenium --dry-run && cargo run -- install volva --dry-run"

echo "Results: $pass passed, $fail failed"
test "$fail" -eq 0
