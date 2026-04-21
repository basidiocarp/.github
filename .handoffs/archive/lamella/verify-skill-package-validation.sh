#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

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

check "Lamella has validation surface mentioning skills" \
  rg -q 'validate.*skill|skill.*validate|authoring.*validation' "$ROOT/lamella"

check "Lamella has scaffold or template flow for skills" \
  rg -q 'scaffold|template' "$ROOT/lamella/docs/authoring" "$ROOT/lamella/resources" "$ROOT/lamella"

check "Lamella manifests mention capability or packaged metadata" \
  rg -q 'capab|allowed_tools|hooks|mcp|skills' "$ROOT/lamella/manifests"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
