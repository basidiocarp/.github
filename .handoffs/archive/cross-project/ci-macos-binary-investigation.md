# CI macOS Binary Investigation

<!-- Save as: .handoffs/cross-project/ci-macos-binary-investigation.md -->
<!-- Verify script: .handoffs/cross-project/verify-ci-macos-binary-investigation.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Pre-built release binaries from GitHub Actions for `aarch64-apple-darwin`
are killed by macOS (exit 137 / SIGKILL) when they attempt to initialize
SQLite with sqlite-vec or tree-sitter grammars. `--version` works (clap
parse + exit), but any command that touches native C dependencies fails.

Building the same code locally with `cargo install` produces working
binaries. The `macos-14` runner fix (arm64 native) did NOT resolve the
issue — the problem is not cross-compilation.

## Resolution

The concrete release-pipeline root cause was identified:

- **Hyphae release workflow:** the macOS functional smoke step used `./$BINARY doctor || true`, so known runtime failures were logged but did not fail the job.
- **Rhizome release workflow:** the macOS functional smoke step used `./$BINARY symbols ... || true`, so any future runtime failure on the native path would also be swallowed.

The workflow fix is:

- make the macOS smoke tests release-blocking instead of advisory
- capture verbose native build diagnostics for Apple targets
- pin a deterministic macOS SDK and deployment target at build time
- re-sign the built macOS binary before packaging
- upload macOS build and smoke logs as artifacts on failure

The verification helper was also fixed so it can actually finish on macOS:

- avoid `((PASS++))` / `((FAIL++))` under `set -e`
- support `timeout` or `gtimeout`
- prefer repo-built binaries, or explicit env overrides, so local verification is not forced to use already-broken installed artifacts

## Final Status

Operationally resolved.

- `hyphae v0.10.2` release published: `https://github.com/basidiocarp/hyphae/releases/tag/v0.10.2`
- `rhizome v0.7.2` release published: `https://github.com/basidiocarp/rhizome/releases/tag/v0.7.2`
- both Apple release jobs passed the hardened functional smoke tests on GitHub Actions
- the downloaded published arm64 macOS tarballs also passed the local verification script on this machine

The original low-level native-runtime difference was narrowed to the Apple build/runtime path, but the single underlying C-level cause was not isolated to one hypothesis in this session. The shipped fix is the hardened release pipeline plus deterministic macOS build settings and failure diagnostics, which prevents publishing broken binaries and produced working release artifacts.

### Affected tools

| Tool | C dependency | Symptom |
|------|-------------|---------|
| hyphae | sqlite-vec, bundled SQLite (rusqlite) | SIGKILL on `doctor`, `stats`, `serve` |
| rhizome | tree-sitter grammars (C compiled) | SIGKILL on `--version` |

### Not affected

| Tool | Why |
|------|-----|
| mycelium | Uses rusqlite but no sqlite-vec; bundled SQLite works |
| canopy | Uses rusqlite but no sqlite-vec; functional check passes |
| cortina | No native C dependencies beyond standard |

### What works

- `cargo install --path .` locally → binary works
- GitHub CI `--version` check → passes (doesn't exercise C deps)
- GitHub CI smoke test on `v0.10.2` / `v0.7.2` → passes on both Apple targets

## Diagnostic Data

### Release workflow output (v0.10.1)

```
✓ Found hyphae: v0.10.1
⏳ Downloading hyphae-aarch64-apple-darwin.tar.gz...
⏳ Extracting...
⏳ Verifying...
! hyphae functional check failed: smoke test failed:
  /Users/williamnewton/.local/bin/hyphae doctor exited with signal: 9 (SIGKILL)
  (stdout: , stderr: )
```

### Binary comparison

Both binaries have identical code signatures:
```
Signature=adhoc
Format=Mach-O thin (arm64)
CodeDirectory v=20400 size=56376 flags=0x20002(adhoc,linker-signed)
```

The source-built binary works; the CI-built binary doesn't. Same arch,
same signing, same features (`--no-default-features`).

### Extended attributes

Both have `com.apple.provenance`. Neither has `com.apple.quarantine`.

## Hypotheses

### H1: sqlite-vec C compilation flags (most likely for hyphae)

sqlite-vec's `build.rs` compiles C code via the `cc` crate. GitHub's
macOS runner may have a different Xcode SDK, C compiler version, or
system headers than local. Specific suspects:

- `-target` flag passed to clang by cc crate
- Missing or different `SDKROOT` / `MACOSX_DEPLOYMENT_TARGET`
- sqlite-vec uses `mmap` or memory-mapped I/O that triggers a security
  policy difference on GitHub runners

### H2: tree-sitter grammar compilation (most likely for rhizome)

tree-sitter grammars compile C/C++ code per language. Same cc crate
issue as H1, but with more C compilation units.

### H3: macOS hardened runtime / SIP

GitHub runners may have different System Integrity Protection settings.
A binary compiled on a runner might use a code path that's rejected
on the user's machine.

### H4: Static linking issue with bundled SQLite

rusqlite with `bundled` feature compiles SQLite from source. The
amalgamation's compile flags might differ between CI and local.

### H5: Cargo cache contamination

GitHub Actions caches `~/.cargo/registry`, `~/.cargo/git`, and `target/`.
If a previous build left x86_64 artifacts in the cache and the runner
switched to arm64, the link step might pull wrong-arch object files.

## Investigation Steps

### Step 1: Reproduce on CI with verbose C compilation

Add debug output to the release workflow to capture cc crate compilation:

```yaml
- name: Build (debug C compilation)
  env:
    CC_LOG: 1
    CARGO_BUILD_JOBS: 1
  run: |
    cargo build --release --no-default-features --target ${{ matrix.target }} -vv 2>&1 | tee build.log
    # Extract cc crate invocations
    grep -E 'running:.*clang|cc.*-o' build.log | head -20
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
echo "Step 1: manual CI investigation — check workflow logs"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] CI workflow has verbose build output
- [ ] C compiler flags captured for sqlite-vec and tree-sitter
- [ ] Compare flags with local build: `CC_LOG=1 cargo build --release -vv 2>&1 | grep clang`

---

### Step 2: Disable cargo cache for macOS builds

Test if cache contamination is the issue:

```yaml
- uses: actions/cache@v5.0.4
  if: "!startsWith(matrix.target, 'aarch64-apple')"
  with:
    # ... existing cache config ...
```

Or add a cache key that includes the runner arch:

```yaml
key: ${{ runner.os }}-${{ runner.arch }}-cargo-release-${{ matrix.target }}-${{ hashFiles('**/Cargo.lock') }}
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
echo "Step 2: disable cache and re-run release"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Cache disabled or arch-keyed for aarch64-apple-darwin
- [ ] Release re-run without cache
- [ ] Binary tested: `hyphae doctor` and `rhizome --version`

---

### Step 3: Pin Xcode version and SDK

Ensure consistent C compilation:

```yaml
- name: Pin Xcode (macOS)
  if: runner.os == 'macOS'
  run: |
    sudo xcode-select -s /Applications/Xcode_15.4.app
    echo "SDKROOT=$(xcrun --show-sdk-path)" >> $GITHUB_ENV
    echo "MACOSX_DEPLOYMENT_TARGET=14.0" >> $GITHUB_ENV
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
echo "Step 3: pin Xcode and re-run release"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Xcode version pinned
- [ ] SDKROOT and MACOSX_DEPLOYMENT_TARGET set
- [ ] Release re-run with pinned SDK
- [ ] Binary tested

---

### Step 4: Add `codesign --force --sign -` after build

Force ad-hoc re-signing after build to ensure valid signature:

```yaml
- name: Re-sign binary (macOS)
  if: runner.os == 'macOS'
  run: |
    BINARY=target/${{ matrix.target }}/release/${TOOL_NAME}
    codesign --force --sign - $BINARY
    codesign -dv $BINARY 2>&1
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
echo "Step 4: re-sign and re-run release"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Binary re-signed after build
- [ ] codesign output shows valid signature
- [ ] Binary tested after re-signing

---

### Step 5: Smoke test exercises C dependencies

Upgrade the smoke test to specifically test the failing code path:

```yaml
- name: Smoke test (macOS native)
  if: runner.os == 'macOS'
  run: |
    BINARY=target/${{ matrix.target }}/release/${TOOL_NAME}
    echo "--- L0: version ---"
    ./$BINARY --version
    echo "--- L1: C dependency test ---"
    # hyphae: tests sqlite-vec + bundled SQLite
    ./$BINARY doctor
    # rhizome: tests tree-sitter grammar loading
    # ./$BINARY symbols src/main.rs
    echo "--- PASS ---"
```

If the smoke test fails, the release is blocked — no broken binary published.

#### Verification

<!-- AGENT: Run and paste output -->
```bash
echo "Step 5: upgrade smoke test"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Smoke test exercises sqlite-vec (hyphae) or tree-sitter (rhizome)
- [ ] Failed smoke test blocks the release
- [ ] Smoke test passes on working binary

---

## Completion Protocol

**Completion status:** complete for the release-pipeline fix and published artifacts.

The original binary breakage was operationally resolved by hardening the release pipeline and validating the shipped binaries. A single low-level C-runtime cause was not isolated beyond the Apple native build/runtime path.

**Satisfied in this session:**

1. Release-gating root cause identified: both workflows swallowed macOS smoke-test failures with `|| true`
2. Fix applied to both hyphae and rhizome release workflows
3. Release binaries pass functional checks on real arm64 macOS in GitHub Actions
4. The verification script passes locally against both repo-built and downloaded published binaries

### Final Verification

```bash
bash .handoffs/cross-project/verify-ci-macos-binary-investigation.sh
```

**Output:**
<!-- PASTE START -->
=== CI-MACOS-BINARY-INVESTIGATION Verification ===

Using hyphae:   /tmp/hyphae-v0.10.2/hyphae
Using rhizome:  /tmp/rhizome-v0.7.2/rhizome
Using mycelium: /Users/williamnewton/projects/basidiocarp/mycelium/target/release/mycelium

--- Hyphae Binary ---
  PASS: hyphae binary exists at ~/.local/bin/
  PASS: hyphae --version responds
  PASS: hyphae stats completes without SIGKILL
  PASS: hyphae MCP handshake responds

--- Rhizome Binary ---
  PASS: rhizome binary exists at ~/.local/bin/
  PASS: rhizome --version responds
  PASS: rhizome symbols exercises tree-sitter
  PASS: rhizome MCP handshake responds

--- Mycelium Doctor ---
  PASS: mycelium doctor shows no broken tools

================================
Results: 9 passed, 0 failed

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Workaround (current)

Until the CI issue is fixed, users must build from source:

```bash
# Hyphae
cd hyphae && cargo install --path crates/hyphae-cli --no-default-features
cp ~/.cargo/bin/hyphae ~/.local/bin/hyphae

# Rhizome
cd rhizome && cargo install --path crates/rhizome-cli
cp ~/.cargo/bin/rhizome ~/.local/bin/rhizome
```

Stipe's L1 functional check correctly warns users when the pre-built
binary is broken, and the repair hint suggests `cargo install --git`.

## Context

Discovered during MCP startup debugging. The pre-built release binaries
passed stipe's `--version` check but failed at runtime. The investigation
in this session confirmed: locally built = works, CI built = SIGKILL.
The `macos-14` runner fix was applied but didn't resolve the issue,
narrowing the root cause to C dependency compilation or cache contamination
rather than architecture mismatch.

Related:
- `.handoffs/stipe/binary-verification-depth.md` — tiered verification (L0/L1/L2)
- `.handoffs/mycelium/diagnostic-passthrough.md` — output filtering fix (now implemented)
