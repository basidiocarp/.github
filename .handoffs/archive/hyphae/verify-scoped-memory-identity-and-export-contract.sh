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

check "Hyphae core defines a shared scoped identity contract" \
  rg -q 'pub struct ScopedIdentity' "$ROOT/hyphae/crates/hyphae-core/src/identity.rs"

check "Hyphae store layer exposes scoped identity from structured sessions" \
  rg -q 'pub fn scoped_identity' "$ROOT/hyphae/crates/hyphae-store/src/store/session.rs"

check "Hyphae passive export bundles carry a scoped identity envelope" \
  rg -q 'schema_version: .*SCOPED_IDENTITY_SCHEMA_VERSION|scoped_identity: ScopedIdentity' \
    "$ROOT/hyphae/crates/hyphae-store/src/store/passive.rs"

check "Hyphae gather-context surfaces emit scoped identity in CLI and MCP" \
  rg -q 'scoped_identity' \
    "$ROOT/hyphae/crates/hyphae-cli/src/commands/context.rs" \
    "$ROOT/hyphae/crates/hyphae-mcp/src/tools/context.rs"

check "Hyphae session surfaces emit scoped identity envelopes" \
  rg -q 'scoped_identity' "$ROOT/hyphae/crates/hyphae-mcp/src/tools/session.rs"

check "Hyphae memory JSON payloads carry scoped identity" \
  rg -q 'scoped_identity: ScopedIdentity' "$ROOT/hyphae/crates/hyphae-cli/src/commands/memory.rs"

check "Hyphae backup command writes a stable export manifest" \
  rg -q 'BackupExportManifest|write_backup_manifest|manifest' "$ROOT/hyphae/crates/hyphae-cli/src/commands/backup.rs"

check "Hyphae MCP tool descriptions mention scoped identity envelopes" \
  rg -q 'scoped_identity envelope' "$ROOT/hyphae/crates/hyphae-mcp/src/tools/schema.rs"

check "Handoff checklist is marked complete" \
  rg -q 'scope semantics are stable across store, MCP, CLI, and export' \
    "$ROOT/.handoffs/archive/hyphae/scoped-memory-identity-and-export-contract.md"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
