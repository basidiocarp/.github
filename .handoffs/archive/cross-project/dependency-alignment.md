# Dependency Alignment

<!-- Save as: .handoffs/cross-project/dependency-alignment.md -->
<!-- Verify script: .handoffs/cross-project/verify-dependency-alignment.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

The ecosystem has version splits across shared dependencies and inconsistent
edition/MSRV settings. This causes:

- Different behavior between projects using the same crate at different versions
- Dependabot bumps that pull in unexpected transitive dependencies (toml 1.0 → ICU4X)
- Missing MSRV on 3 projects, making compatibility unclear
- Rhizome still on Rust 2021 edition while everything else is 2024

### Current State

| Dimension | Projects at older version | Projects at newer version |
|-----------|--------------------------|--------------------------|
| **rusqlite** | 0.34: hyphae, canopy, cortina | 0.39: mycelium |
| **toml** | 0.8: hyphae, stipe, spore | 1.0: mycelium, rhizome |
| **Edition** | 2021: rhizome | 2024: all others |
| **MSRV** | Missing: mycelium, rhizome, spore | 1.85: hyphae, stipe, cortina, canopy |

### Target State

| Dimension | Target | Rationale |
|-----------|--------|-----------|
| **rusqlite** | 0.39 everywhere | Security fixes, API improvements |
| **toml** | 1.0 everywhere | TOML spec 1.1 support, maintained |
| **Edition** | 2024 everywhere | Consistent language features |
| **MSRV** | 1.85 everywhere | Minimum for edition 2024 |
| **Rust toolchain** | 1.94.0 | Already current, no action |

## Design

### Upgrade Order

Projects must be upgraded in dependency order. Spore is the shared library
that all other projects depend on — it goes first.

```
Phase 1: spore (shared library — all projects depend on this)
Phase 2: hyphae, canopy, cortina (rusqlite 0.34 → 0.39 consumers)
Phase 3: rhizome (edition 2021 → 2024)
Phase 4: stipe (toml 0.8 → 1.0)
Phase 5: ecosystem-versions.toml (update pinned versions)
```

### Verification Per Step

Every dependency bump MUST be verified with:

1. `cargo build --release` — compiles
2. `cargo test` — tests pass
3. `cargo clippy` — no new warnings
4. **Binary smoke test** — built binary actually runs (not just compiles)
5. Check for new transitive dependencies that might cause issues

### Known Risk: toml 1.0

The `toml` 0.8 → 1.0 bump pulls in ICU4X crates (`icu_properties`,
`icu_normalizer`, `icu_collections`, etc.) for Unicode normalization.
These add ~500KB to binary size but are functional. The earlier SIGKILL
issue was from macOS code signing, not ICU4X itself.

## Implementation

### Step 1: Spore — bump toml, add MSRV

**Project:** `spore/`
**Effort:** 15 minutes
**Depends on:** Nothing

#### Files to modify

**`spore/Cargo.toml`**:
- Add `rust-version = "1.85"` if missing
- Bump `toml` from `0.8` to `1.0`
- Run `cargo update` to resolve the dependency tree

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd spore && cargo build --release 2>&1 | tail -3 && cargo test 2>&1 | grep 'test result' && cargo clippy 2>&1 | tail -3
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `rust-version = "1.85"` in Cargo.toml
- [ ] `toml = "1.0"` in Cargo.toml
- [ ] `cargo build --release` succeeds
- [ ] `cargo test` passes
- [ ] `cargo clippy` clean
- [ ] Tag and push new spore version

---

### Step 2: Hyphae — bump rusqlite and toml

**Project:** `hyphae/`
**Effort:** 30 minutes
**Depends on:** Step 1 (new spore version)

#### Files to modify

**`hyphae/Cargo.toml`** (workspace root):
- Update `spore` git tag to new version from Step 1
- Bump `rusqlite` from `0.34` to `0.39` in workspace.dependencies
- Bump `toml` from `0.8` to `1.0` in workspace.dependencies

**Note:** rusqlite 0.34 → 0.39 may have API changes. Check:
- `Connection::open` signature
- `params![]` macro changes
- `execute_batch` behavior
- FTS5 and sqlite-vec compatibility

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd hyphae && cargo build --release --no-default-features 2>&1 | tail -3 && cargo test 2>&1 | grep 'test result' && timeout 5 target/release/hyphae --version 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `rusqlite = "0.39"` in workspace Cargo.toml
- [ ] `toml = "1.0"` in workspace Cargo.toml
- [ ] Updated spore git tag
- [ ] `cargo build --release --no-default-features` succeeds
- [ ] `cargo test` passes
- [ ] Built binary runs (`hyphae --version`)
- [ ] `hyphae doctor` completes (exercises rusqlite + sqlite-vec)
- [ ] Tag and push new hyphae version

---

### Step 3: Canopy — bump rusqlite

**Project:** `canopy/`
**Effort:** 15 minutes
**Depends on:** Step 1 (new spore version)

#### Files to modify

**`canopy/Cargo.toml`**:
- Update `spore` git tag
- Bump `rusqlite` from `0.34` to `0.39`

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd canopy && cargo build --release 2>&1 | tail -3 && cargo test 2>&1 | grep 'test result' && timeout 5 target/release/canopy --version 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `rusqlite = "0.39"` in Cargo.toml
- [ ] Updated spore git tag
- [ ] `cargo build --release` succeeds
- [ ] `cargo test` passes
- [ ] Built binary runs (`canopy --version`)
- [ ] `canopy task list` completes (exercises rusqlite)
- [ ] Tag and push new canopy version

---

### Step 4: Cortina — bump rusqlite

**Project:** `cortina/`
**Effort:** 15 minutes
**Depends on:** Step 1 (new spore version)

#### Files to modify

**`cortina/Cargo.toml`**:
- Update `spore` git tag
- Bump `rusqlite` from `0.34` to `0.39`

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd cortina && cargo build --release 2>&1 | tail -3 && cargo test 2>&1 | grep 'test result' && timeout 5 target/release/cortina --version 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `rusqlite = "0.39"` in Cargo.toml
- [ ] Updated spore git tag
- [ ] `cargo build --release` succeeds
- [ ] `cargo test` passes
- [ ] Built binary runs (`cortina --version`)
- [ ] Tag and push new cortina version

---

### Step 5: Rhizome — upgrade edition to 2024, add MSRV

**Project:** `rhizome/`
**Effort:** 30 minutes
**Depends on:** Step 1 (new spore version)

Edition 2024 changes that may require code updates:
- `gen` is a reserved keyword
- Lifetime elision changes in some patterns
- `unsafe` blocks in `unsafe fn` are now required
- `impl Trait` lifetime capture rules changed

#### Files to modify

**`rhizome/Cargo.toml`** (workspace root):
- Add `edition = "2024"` to workspace package settings
- Add `rust-version = "1.85"`
- Update `spore` git tag

**`rhizome/crates/*/Cargo.toml`** (each crate):
- Update `edition = "2024"` if set per-crate (rhizome-core was 2021)
- Or ensure crates inherit edition from workspace

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd rhizome && cargo build --release 2>&1 | tail -5 && cargo test --all 2>&1 | grep 'test result' && timeout 5 target/release/rhizome --version 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `edition = "2024"` in workspace or all crate Cargo.toml files
- [ ] `rust-version = "1.85"` added
- [ ] Updated spore git tag
- [ ] `cargo build --release` succeeds (fix any edition 2024 compat issues)
- [ ] `cargo test --all` passes
- [ ] Built binary runs (`rhizome --version`)
- [ ] `rhizome symbols <file>` works (exercises tree-sitter)
- [ ] Tag and push new rhizome version

---

### Step 6: Stipe — bump toml

**Project:** `stipe/`
**Effort:** 15 minutes
**Depends on:** Step 1 (new spore version)

#### Files to modify

**`stipe/Cargo.toml`**:
- Update `spore` git tag
- Bump `toml` from `0.8` to `1.0`

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd stipe && cargo build --release 2>&1 | tail -3 && cargo test 2>&1 | grep 'test result' && timeout 5 target/release/stipe --version 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `toml = "1.0"` in Cargo.toml
- [ ] Updated spore git tag
- [ ] `cargo build --release` succeeds
- [ ] `cargo test` passes
- [ ] Built binary runs (`stipe --version`)
- [ ] Tag and push new stipe version

---

### Step 7: Mycelium — add MSRV

**Project:** `mycelium/`
**Effort:** 5 minutes
**Depends on:** Step 1 (new spore version)

Mycelium already has toml 1.0 and rusqlite 0.39. Just needs MSRV and spore bump.

#### Files to modify

**`mycelium/Cargo.toml`**:
- Add `rust-version = "1.85"`
- Update `spore` git tag

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd mycelium && cargo build --release 2>&1 | tail -3 && cargo test 2>&1 | grep 'test result'
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `rust-version = "1.85"` in Cargo.toml
- [ ] Updated spore git tag
- [ ] `cargo build --release` succeeds
- [ ] `cargo test` passes
- [ ] Tag and push new mycelium version

---

### Step 8: Update ecosystem-versions.toml

**Project:** Root workspace
**Effort:** 5 minutes
**Depends on:** All previous steps

#### Files to modify

**`ecosystem-versions.toml`**:
- Update all version pins to match new releases
- Remove notes about version splits (now aligned)
- Add MSRV declaration

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cat ecosystem-versions.toml
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] All version pins updated
- [ ] Version split notes removed
- [ ] MSRV = 1.85 documented
- [ ] Edition = 2024 documented

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cross-project/verify-dependency-alignment.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cross-project/verify-dependency-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Dependabot Strategy After Alignment

Once aligned, configure dependabot consistently across all repos:

1. **Auto-merge patch bumps** — `x.y.Z` changes are safe
2. **Review minor bumps** — `x.Y.0` may have API changes
3. **Manual major bumps** — `X.0.0` requires migration work
4. **Group shared deps** — rusqlite, toml, spore bumps should be coordinated
5. **Pin problematic crates** — if a crate causes build issues, pin and document

## Context

The dependency splits were documented in `ecosystem-versions.toml` but never
resolved. Mycelium moved ahead to rusqlite 0.39 and toml 1.0 during active
development while other projects stayed on older versions. This handoff
aligns everything and adds missing MSRV constraints so future toolchain
requirements are explicit.

The toml 1.0 bump is safe — the earlier SIGKILL issue was from macOS code
signing (fixed in stipe v0.5.5), not from ICU4X or any dependency.
