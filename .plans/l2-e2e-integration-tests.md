# Plan: L-2 — End-to-End Integration Test Suite

## Context
Create a cross-project E2E test that verifies the full basidiocarp ecosystem works together: mycelium filters output, hyphae stores/recalls memories, rhizome exports code symbols to hyphae, and all tools are discoverable. This runs as a scheduled GitHub Actions workflow in the `.github` org repo.

**IMPORTANT**: No coauthors on any commits.

**Status**: ✅ Complete — workflow created and triggered

## Tasks

### Phase 1 (single task)

#### Task 1: Create E2E integration test workflow
**Status**: ✅ Complete

**Accept criteria**:
- [x] Triggered on `schedule` (weekly, Sunday 6am UTC) and `workflow_dispatch`
- [x] Downloads latest release binaries via install.sh with `--no-configure`
- [x] Installs to `~/.local/bin/` and adds to PATH
- [x] **Test 1 — Tool discovery**: `mycelium --version`, `hyphae --version`, `rhizome --version` all succeed
- [x] **Test 2 — Mycelium filtering**: pipes input through `mycelium summary`, verifies no crash
- [x] **Test 3 — Hyphae store + recall**: stores memory, searches, verifies round-trip
- [x] **Test 4 — Hyphae prune**: `hyphae prune --dry-run` succeeds
- [x] **Test 5 — Rhizome symbols**: creates sample.rs, extracts symbols, verifies `hello` in output
- [x] **Test 6 — Rhizome export**: runs export without hyphae serve, verifies no crash
- [x] **Test 7 — Cross-tool**: `mycelium init --ecosystem` detects all 3 tools
- [x] Each test step has `if: always()` to run all tests regardless of earlier failures
- [x] Final step: pass/fail summary with checkmarks
- [x] Timeout: 10 minutes

## Verification
```bash
gh workflow run e2e-integration.yml --repo basidiocarp/.github
gh run list --repo basidiocarp/.github --workflow e2e-integration.yml --limit 1
```
