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

run_check "Lamella validate" sh -c "cd lamella && make validate"
run_check "skill validation" sh -c "cd lamella && ./lamella validate skills"
run_check "skill package validation" sh -c "cd lamella && ./lamella validate skill-packages"
run_check "classification inventory exists" test -f lamella/docs/maintainers/skill-pack-classification.md
run_check "classification inventory names required buckets" sh -c "rg -n '\\b(general|basidiocarp|adapter-candidate)\\b' lamella/docs/maintainers/skill-pack-classification.md"
run_check "authoring docs explain adapter pattern" sh -c "rg -n 'adapter|Basidiocarp|general skill|ecosystem skill' lamella/docs/authoring lamella/docs/maintainers"
run_check "manifests include general and Basidiocarp pack split" sh -c "rg -n 'general|basidiocarp' lamella/manifests"

echo "Results: $pass passed, $fail failed"
test "$fail" -eq 0
