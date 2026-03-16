# Plan: Unified Installer — One Command to Set Up the Ecosystem

## Context

Each tool lives in its own repository under the `basidiocarp` GitHub org. They install independently: `cargo install` for Rust binaries, `npm install` for Cap, manual MCP configuration for each. A unified installer lets users set up the full ecosystem (or selected tools) with a single command, including Claude Code hook configuration and MCP server registration.

## Repositories

| Tool | Repo | Language |
|------|------|----------|
| Mycelium | `basidiocarp/mycelium` | Rust |
| Hyphae | `basidiocarp/hyphae` | Rust |
| Rhizome | `basidiocarp/rhizome` | Rust |
| Cap | `basidiocarp/cap` | TypeScript |

## Design

Two installation paths:

### 1. Web installer (curl-pipe)
```bash
curl -sSfL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh
```

### 2. Mycelium bootstrapping
```bash
# If mycelium is already installed:
mycelium init --ecosystem
```

### What the installer does

```
1. Detect platform (macOS arm64/x86, Linux x86)
2. Download pre-built binaries from GitHub Releases:
   - basidiocarp/mycelium/releases
   - basidiocarp/hyphae/releases
   - basidiocarp/rhizome/releases
3. Install to ~/.local/bin/ (or user-chosen prefix)
4. Configure Claude Code:
   - Add mycelium hook to ~/.claude/settings.json
   - Register hyphae MCP server
   - Register rhizome MCP server
   - Add mycelium instructions to ~/.claude/CLAUDE.md
5. Initialize databases:
   - hyphae: create default config + DB
   - mycelium: create tracking DB
6. Verify installation:
   - mycelium --version
   - hyphae --version
   - rhizome --version
7. Print summary with next steps
```

## Tasks

### Phase 1 — Release infrastructure (parallel, one per repo)

#### Task 1: Add GitHub Actions release workflow for Mycelium

**Repo**: `basidiocarp/mycelium`
**Files**: `.github/workflows/release.yml` (new)

**Accept criteria**:
- [ ] Triggered on tag push `v*`
- [ ] Builds release binaries for: `x86_64-apple-darwin`, `aarch64-apple-darwin`, `x86_64-unknown-linux-gnu`, `x86_64-unknown-linux-musl`
- [ ] Uses `cross` for Linux cross-compilation
- [ ] Creates universal macOS binary via `lipo`
- [ ] Uploads binaries as release assets with checksum file
- [ ] Binary naming: `mycelium-{version}-{target}.tar.gz`
- [ ] Release notes generated from CHANGELOG.md

---

#### Task 2: Add GitHub Actions release workflow for Hyphae

**Repo**: `basidiocarp/hyphae`
**Files**: `.github/workflows/release.yml` (new)

**Accept criteria**:
- [ ] Same structure as Task 1
- [ ] Builds with `--no-default-features` for a slim binary (no embeddings) as an additional artifact
- [ ] Both `hyphae` and `hyphae-slim` binaries uploaded
- [ ] Binary naming: `hyphae-{version}-{target}.tar.gz`

---

#### Task 3: Add GitHub Actions release workflow for Rhizome

**Repo**: `basidiocarp/rhizome`
**Files**: `.github/workflows/release.yml` (new)

**Accept criteria**:
- [ ] Same structure as Task 1
- [ ] Tree-sitter grammars compiled in (no runtime deps)
- [ ] Binary naming: `rhizome-{version}-{target}.tar.gz`

---

### Phase 2 — Installer script (sequential)

#### Task 4: Write unified install script

**Repo**: `basidiocarp/.github`
**Files**: `install.sh`

**Blocked by**: Tasks 1-3 (need release URLs)

**Accept criteria**:
- [ ] POSIX sh compatible (no bashisms)
- [ ] `--help` shows usage
- [ ] `--tools mycelium,hyphae` — install only selected tools (default: all)
- [ ] `--prefix /usr/local/bin` — custom install directory (default: `~/.local/bin`)
- [ ] `--no-configure` — skip Claude Code configuration
- [ ] `--version 0.5.0` — install specific version (default: latest)
- [ ] Platform detection: `uname -s` + `uname -m`
- [ ] Downloads from each repo's GitHub Releases with checksum verification
- [ ] Adds install dir to PATH if not already present (appends to `~/.zshrc` or `~/.bashrc`)
- [ ] Claude Code configuration:
  - Adds pre-tool-use hook for mycelium in `~/.claude/settings.json`
  - Runs `claude mcp add hyphae -- hyphae serve` (if Claude Code installed)
  - Runs `claude mcp add rhizome -- rhizome serve` (if Claude Code installed)
  - Runs `mycelium init --global` to add instructions to CLAUDE.md
- [ ] Hyphae initialization: `hyphae init` (creates config + DB)
- [ ] Verification: runs `--version` for each installed tool
- [ ] Prints colored summary:
  ```
  ✓ mycelium v0.8.0 installed
  ✓ hyphae v0.6.0 installed
  ✓ rhizome v0.1.0 installed
  ✓ Claude Code hooks configured
  ✓ MCP servers registered

  Next steps:
    1. Restart Claude Code to pick up MCP servers
    2. Run: mycelium gain (verify token tracking)
    3. Run: hyphae store "test memory" (verify memory system)
  ```
- [ ] Idempotent: re-running upgrades existing installations
- [ ] Uninstall: `--uninstall` flag removes binaries and config

**Implementation notes**:
- Use `curl` or `wget` for downloads (detect which is available)
- Checksum verification: `sha256sum` or `shasum -a 256`
- Claude Code detection: check for `claude` binary in PATH
- JSON manipulation for settings.json: use `python3 -c` or `jq` (with fallback)
- Don't modify files without backup: copy original to `.bak` before editing
- Each tool downloads from its own repo: `https://github.com/basidiocarp/{tool}/releases/latest/download/{tool}-{target}.tar.gz`

---

### Phase 3 — Mycelium bootstrapping (sequential)

#### Task 5: Add `mycelium init --ecosystem` command

**Repo**: `basidiocarp/mycelium`
**Files**: `src/init.rs` (extend)

**Blocked by**: Task 4 design finalized

**Accept criteria**:
- [ ] `mycelium init --ecosystem` — detects and configures sibling tools
- [ ] Checks for `hyphae` and `rhizome` in PATH
- [ ] If missing: prints install instructions with curl command
- [ ] If present: configures MCP servers for Claude Code
- [ ] Prints ecosystem status summary:
  ```
  Ecosystem Status:
    mycelium v0.8.0  ✓ installed, hooks active
    hyphae   v0.6.0  ✓ installed, MCP registered
    rhizome  v0.1.0  ✓ installed, MCP registered
    cap      —       ✗ not installed (optional, run: npm install -g @basidiocarp/cap)
  ```
- [ ] `cargo test` passes

---

### Phase 4 — CI/CD for all repos (parallel)

#### Task 6: Add CI workflow for Mycelium

**Repo**: `basidiocarp/mycelium`
**Files**: `.github/workflows/ci.yml` (new)

**Accept criteria**:
- [ ] Triggered on push to main + PRs
- [ ] Matrix: macOS (latest) + Ubuntu (latest)
- [ ] Steps: `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test`, `cargo build --release`
- [ ] Caches: `~/.cargo/registry`, `target/`
- [ ] Runs integration tests on main branch only (`cargo test --ignored`)

---

#### Task 7: Add CI workflow for Hyphae

**Repo**: `basidiocarp/hyphae`
**Files**: `.github/workflows/ci.yml` (new)

**Accept criteria**:
- [ ] Same structure as Task 6
- [ ] Additional: test with `--no-default-features` (no embeddings)
- [ ] Additional: test with `--all-features`

---

#### Task 8: Add CI workflow for Rhizome

**Repo**: `basidiocarp/rhizome`
**Files**: `.github/workflows/ci.yml` (new)

**Accept criteria**:
- [ ] Same structure as Task 6
- [ ] Tree-sitter tests run on all platforms

---

#### Task 9: Add CI workflow for Cap

**Repo**: `basidiocarp/cap`
**Files**: `.github/workflows/ci.yml` (new)

**Accept criteria**:
- [ ] Triggered on push to main + PRs
- [ ] Steps: `npm ci`, `npm run lint`, `npm run build`
- [ ] Node.js version: 20

## Verification

```bash
# Test installer locally
curl -sSfL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh --tools mycelium --prefix /tmp/test-install
/tmp/test-install/mycelium --version

# Test ecosystem init
mycelium init --ecosystem

# Verify CI (push a test branch to any repo)
gh workflow view ci --repo basidiocarp/mycelium
```