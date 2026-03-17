# Plan: L-2 — End-to-End Integration Test Suite

## Context
Create a cross-project E2E test that verifies the full basidiocarp ecosystem works together: mycelium filters output, hyphae stores/recalls memories, rhizome exports code symbols to hyphae, and all tools are discoverable. This runs as a scheduled GitHub Actions workflow in the `.github` org repo.

**IMPORTANT**: No coauthors on any commits.

## Codebase References
- `basidiocarp/.github/.github/workflows/` — Shared reusable workflows
- `basidiocarp/.github/install.sh` — Ecosystem installer (downloads binaries)
- `basidiocarp/mycelium` — CLI proxy, `mycelium init --ecosystem`
- `basidiocarp/hyphae` — Memory system, `hyphae serve` MCP server
- `basidiocarp/rhizome` — Code intelligence, `rhizome serve` MCP server, `rhizome export`

## Tasks

### Phase 1 (single task)

#### Task 1: Create E2E integration test workflow
**Files**: `.github/workflows/e2e-integration.yml` (new)
**Context**: This workflow installs all 3 tools from GitHub Releases, then runs a series of integration tests. It should run on a schedule (weekly) and on manual trigger. Uses ubuntu-latest.

**Accept criteria**:
- [ ] Triggered on `schedule` (weekly, Sunday 6am UTC) and `workflow_dispatch`
- [ ] Downloads latest release binaries for mycelium, hyphae, rhizome from GitHub Releases
- [ ] Installs to `~/.local/bin/` and adds to PATH
- [ ] **Test 1 — Tool discovery**: `mycelium --version`, `hyphae --version`, `rhizome --version` all succeed
- [ ] **Test 2 — Mycelium filtering**: `echo 'line1\nline2\nline3' | mycelium summary` produces output shorter than input
- [ ] **Test 3 — Hyphae store + recall**: `hyphae store -t test -c "E2E test memory"` succeeds, then `hyphae search --query "E2E test" --limit 1` returns the memory
- [ ] **Test 4 — Hyphae prune**: `hyphae prune --dry-run` succeeds without error
- [ ] **Test 5 — Rhizome symbols**: Create a sample Rust file, run `rhizome symbols sample.rs`, verify output contains symbol names
- [ ] **Test 6 — Rhizome export**: Run `rhizome export --project .` (should fail gracefully since hyphae serve isn't running, but exit 0 or 1 without panic)
- [ ] **Test 7 — Cross-tool**: `mycelium init --ecosystem` detects all tools without error
- [ ] Each test step has a descriptive name and `if: always()` to run all tests even if one fails
- [ ] Final step: summarize pass/fail count
- [ ] Timeout: 10 minutes for full workflow

**Implementation notes**:
- Download binaries using the install.sh script or direct GitHub Releases API:
  ```yaml
  - name: Install ecosystem
    run: |
      curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh -s -- --no-configure
  ```
- `--no-configure` skips Claude Code configuration (not available in CI)
- Create sample Rust file inline for rhizome test:
  ```bash
  cat > sample.rs << 'EOF'
  pub fn hello() -> String { "hello".into() }
  pub struct Config { pub name: String }
  EOF
  ```
- Hyphae needs a writable data directory: `mkdir -p ~/.local/share/hyphae`
- Use `set +e` for individual test commands and track failures manually

## Verification
```bash
# Trigger manually from GitHub:
gh workflow run e2e-integration.yml --repo basidiocarp/.github

# Check results:
gh run list --repo basidiocarp/.github --workflow e2e-integration.yml --limit 1
```
