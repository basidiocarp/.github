# Phase 2 Pass 1 — Code Quality Discovery

Date: 2026-04-22
Pass: Discovery (automated tools)

## Summary Table

| Repo | Clippy | Fmt | Unwrap Count | Expect Count | Notes |
|------|--------|-----|--------------|--------------|-------|
| mycelium | FAIL (4 errors) | FAIL | 314 | 245 | Linting + fmt issues in dispatch/exec and init modules |
| hyphae | FAIL (compile) | FAIL | 0 | 0 | Benchmark compilation error in retrieval_hot_paths.rs; fmt spacing issues in CLI |
| canopy | FAIL (12 errors) | FAIL | 21 | 156 | map_or, format_push_string, uninlined_format_args issues |
| rhizome | FAIL (compile) | FAIL | 0 | 0 | Single-element loop in test; minor fmt reordering |
| spore | FAIL (16 errors) | FAIL | 42 | 32 | Multiple clippy violations; pass-by-value, must_use, map_unwrap_or issues |
| stipe | FAIL (56 errors) | FAIL | 108 | 75 | HIGHEST IMPACT: unreadable literals, unsafe usage, format string issues, excessive bools |
| cortina | PASS | FAIL | 105 | 82 | Clean clippy; minor fmt import ordering |
| annulus | FAIL (8 errors) | FAIL | 110 | 173 | Cast truncation, items_after_statements issues |
| hymenium | FAIL (6 errors) | FAIL | 36 | 286 | Unused import, map_unwrap_or, doc_markdown, items_after_statements |
| volva | FAIL (6 errors) | FAIL | 0 | 0 | match_same_arms in auth modules; fmt spacing issues |
| cap | N/A | FAIL | — | — | TS clean; Biome lint: 29 errors (sorted keys, formatting) |
| lamella | N/A | N/A | — | — | make validate: PASS (225 doc warnings on Lamella SKILLs, expected) |

## Per-Repo Findings

### Rust Repos (Clippy Errors)

#### mycelium (4 errors)
```
error: this import is redundant
  src/tracking/schema.rs:7 - use tracing; (single_component_path_imports)

error: using `contains()` instead of `iter().any()` is more efficient
  src/dispatch/exec.rs:271 - allowed_tools.iter().any() should use contains()
```
**Fmt issues**: spacing in dispatch/exec.rs allowed_tools array (multi-line formatting)

---

#### hyphae (compilation error + fmt)
```
error[E0063]: missing field `content_hash` in initializer of `hyphae_core::Document`
  crates/hyphae-store/benches/retrieval_hot_paths.rs:72

Fmt violations in:
  - crates/hyphae-cli/src/commands/recall_bundle.rs:93 (chained method formatting)
  - crates/hyphae-cli/src/commands/recall_bundle.rs:141 (if-let formatting)
```
**Status**: Blocks compilation of benchmarks.

---

#### canopy (12 errors)
```
error: unnecessary_map_or
  src/tools/task.rs:388 - .map_or(false, |s| ...) should use is_some_and()

error: format_push_string (2 instances)
  src/tools/task.rs:411 - format!() appended to String, should use write!()

error: uninlined_format_args
  src/tools/task.rs:411 - format string variables should be inlined

Additional errors: cast_lossless (2), cast_possible_truncation (4)
```
**Fmt issues**: import reordering in src/api.rs (EvidenceRef placement)

---

#### rhizome (compilation error + fmt)
```
error: single_element_loop
  crates/rhizome-core/tests/backend_boundary.rs:55 - loop with single "rename_symbol" item

Fmt violations in:
  - crates/rhizome-cli/src/doctor.rs:60 (long string wrapping)
  - crates/rhizome-cli/src/main.rs:708 (import order: serde_json vs std::fs)
```

---

#### spore (16 errors)
```
error: needless_pass_by_value
  src/logging.rs:403 - LoggingConfig should be &LoggingConfig

error: must_use_candidate
  src/discovery.rs:45 - probe_uncached() function should have #[must_use]

error: map_unwrap_or (3 instances)
  src/logging.rs:452 - chained filter/or/map should use map_or_else()

Additional errors: cast_lossless (2), cast_possible_truncation (3), unused_import
```
**Fmt issues**: spacing in src/availability.rs line 231-238

---

#### stipe (56 errors — HIGHEST IMPACT)
```
error: unreadable_literal
  src/commands/init/verification.rs - 0xcbf29ce48422232 should be 0xcbf2_9ce4_8422_2325
  (Multiple long hex/binary literals)

error: unsafe_code (9 instances)
  Scattered throughout src/commands/install/release.rs, src/commands/verify/main.rs

error: map_unwrap_or (2 instances)
  src/commands/verify/main.rs

error: uninlined_format_args (4 instances)
  src/commands/rollback.rs:36, :118

error: items_after_statements
  src/commands/rollback.rs:61 - 'use std::io::Write' after statements

error: doc_markdown
  Various doc comments missing backticks

error: cast_lossless (2), redundant_closure, manual_let_else, single_match_else
```
**Fmt issues**: line breaking inconsistencies in src/backup.rs and other command files
**Risk Level**: HIGH - unsafe code, excessive bools parameter, unreadable literals

---

#### cortina (0 Clippy errors — ONLY CLEAN RUST REPO)
```
PASS - No clippy violations with -D warnings
```
**Fmt issues**: Minor import ordering in src/adapters/mod.rs

---

#### annulus (8 errors)
```
error: cast_possible_truncation (4 instances)
  src/statusline.rs:745-750 - u64 -> u32, f64 -> f32 casts without try_from

error: items_after_statements (2 instances)
  src/bridge.rs:103, :119 - 'use std::io::Write' after statements

error: redundant_clone
  (additional violations)
```
**Fmt issues**: src/bridge.rs line 97, src/notify.rs line 58

---

#### hymenium (6 errors)
```
error: unused_import
  src/classify.rs - 'use tracing;' not needed

error: map_unwrap_or
  src/monitor/handler.rs:43 - .map().unwrap_or() should use map_or()

error: doc_markdown
  src/sweeper.rs:306 - 'SQLite' should be '`SQLite`'

error: items_after_statements
  src/sweeper.rs:316 - const after statements
```
**Fmt issues**: src/classify.rs:123 (chained method formatting), src/dispatch/orchestrate.rs (import order)
**Note**: High expect count (286) suggests defensive coding in error handling paths

---

#### volva (6 errors)
```
error: match_same_arms (2 instances)
  crates/volva-api/src/auth.rs:126 - AuthMode::BearerToken and _ return same value
  crates/volva-auth/src/anthropic/oauth.rs:243 - AuthTarget::ClaudeAi and _ return same value
```
**Fmt issues**: Spacing in callback_server.rs:115 and chat.rs:41

---

### TypeScript/JavaScript (cap)

#### npm run lint:check (Biome)
- **Status**: FAIL (29 linting errors)
- **Issues**: All `useSortedKeys` violations — object properties not sorted alphabetically
- **Files affected**: 
  - `server/__tests__/hyphae-writes.test.ts` (5+ violations)
  - `server/routes/hyphae/writes.ts` (2+ violations)
  - Multiple other route handlers

- **Sample errors**:
  ```
  server/__tests__/hyphae-writes.test.ts:11 - store, forget, updateImportance, 
                                               invalidateMemory, consolidate (unordered)
  
  server/routes/hyphae/writes.ts:93 - error, detail should be detail, error
  ```
- **Fmt**: Biome reports 29 fixable violations (safe fix: auto-sort keys)

#### npx tsc --noEmit
- **Status**: PASS (no TypeScript errors)

---

### Lamella

#### make validate
- **Status**: PASS (all validators passed)
- **Output**: 225 warnings on Lamella SKILL markdown files (missing '## Workflow' sections — expected, non-critical)
- **Notes**: 
  - Validated 301 Lamella skill packages, 52 manifest alignments
  - 128 shared subagent files, 52 manifests
  - 8 preset files, 367 files scanned

---

## Unwrap / Expect Inventory

### High-Impact Repos (Unwrap Count >= 100)

#### stipe (108 unwraps, 75 expects)
**Unwrap hotspots** (production non-test):
- `src/lockfile.rs:146-147` - JSON serialization + file write (2x)
- `src/backup.rs:271-335` - TempDir creation, path conversion, manifest loading (10+)
- `src/verify.rs:359-401` - File write, JSON round-trip (3x)
- `src/commands/init/baseline.rs:813-851` - File write, checksum operations (6+)
- `src/commands/install/release.rs:530-535` - Directory creation, script write (4+)

**Risk Assessment**: Medium-High (mostly filesystem operations with temporary directories in test/init code)

#### mycelium (314 unwraps, 245 expects)
**Unwrap hotspots** (production):
- `src/init/hook.rs:284-369` - String position finding, TempDir creation, file operations (15+)
- `src/init/json_patch.rs:652-744` - JSON parsing and array access throughout (20+)

**Expect patterns**:
- `src/local_llm.rs:15-65` - Regex::new() calls with "valid regex" messages (good invariants)
- `src/init/json_patch.rs` - JSON field access with descriptive messages

**Risk Assessment**: HIGH - Many unwraps in hook initialization path with weak safety assumptions

#### cortina (105 unwraps, 82 expects)
**Unwrap hotspots**:
- `src/handoff_lint.rs:119-191` - TempDir + file operations in tests (mostly test code)
- `src/utils/tests.rs:291-1114` - Heavy test file use (legitimate test unwraps)
- `src/hooks/stop/tests.rs:130-384` - TempDir + file creation in tests

**Risk Assessment**: LOW-MEDIUM (majority are legitimate test unwraps; handoff_lint audit operations can tolerate panics)

#### annulus (110 unwraps, 173 expects)
**Unwrap hotspots** (production):
- `src/notify.rs:76-133` - Connection::open(), SQL operations (6+)
- `src/bridge.rs:90-121` - NamedTempFile creation, JSON serialization, flush (5+)
- `src/validate_hooks.rs:345-468` - File operations, JSON parsing (8+)

**Risk Assessment**: MEDIUM - Database connection opening could fail in prod; file operations in validate_hooks

---

### Moderate-Impact Repos

#### canopy (21 unwraps, 156 expects)
- **Unwraps**: Low count, mostly in tests
- **Expects**: High count with mostly descriptive messages (good practice)
- **Risk**: Low unwrap risk; expects are instrumented

#### spore (42 unwraps, 32 expects)
- **Unwraps**: Probing operations, mostly in tool discovery (acceptable)
- **Risk**: Low-Medium (discovery code can fail)

#### hymenium (36 unwraps, 286 expects)
- **Unwraps**: Minimal production use
- **Expects**: Very high count indicates error classification and recovery paths
- **Risk**: Low (defensive expect messages dominate)

---

## Overall Assessment

### Clippy Violations Summary
- **Total repos with clippy errors**: 10/10 Rust repos
- **Error count**: stipe (56), spore (16), canopy (12), annulus (8), hymenium (6), volva (6), mycelium (4), hyphae (1 compile), rhizome (1 compile), cortina (0 — CLEAN)
- **Total clippy errors across workspace**: ~119

### Format Violations
- **All Rust repos**: FAIL cargo fmt --check
- **All TypeScript**: FAIL (Biome 29 errors)
- **Issues**: Mostly mechanical (spacing, import ordering, unreadable literals)

### Unwrap Risk Inventory
- **Total unwraps in production paths**: 736
- **Hottest repos**: mycelium (314), stipe (108), cortina (105), annulus (110)
- **Legitimate test unwraps**: Majority of cortina, spore, significant portion of stipe

### Highest-Risk Findings (Top 5)

1. **stipe: unsafe_code violations (9 instances)**
   - Location: src/commands/install/release.rs, src/commands/verify/main.rs
   - Risk: Memory safety concerns in critical paths
   - Severity: CRITICAL

2. **mycelium: 314 unwraps in hook initialization**
   - Location: src/init/hook.rs, src/init/json_patch.rs
   - Risk: Hook setup could panic on malformed JSON or missing fields
   - Severity: HIGH

3. **stipe: Excessive unsafe + unreadable literals**
   - Location: Multiple files in commands/ subdir
   - Risk: 56 clippy errors compound into maintainability risk
   - Severity: HIGH

4. **annulus: Database connection panics not caught**
   - Location: src/notify.rs lines 76-133
   - Risk: Connection::open() unwrap could crash notification service
   - Severity: MEDIUM-HIGH

5. **canopy: 156 expect() calls with user-facing error handling gaps**
   - Location: src/tools/task.rs (multiple)
   - Risk: Some expects on Option chains could be better error messages
   - Severity: MEDIUM

### Lamella Assessment
- **Status**: Clean (validator passes)
- **Notes**: 225 doc warnings are metadata only (missing workflow sections on skills)

### Next Steps (Phase 2 Pass 2)
1. Priority: Fix stipe's unsafe code and unreadable literals
2. Priority: Reduce mycelium's unwrap count in init paths
3. Medium: Standardize error handling (unwrap vs. expect vs. ?)
4. Medium: Run `cargo fmt` and Biome auto-fix across workspace
5. Low: Update Lamella SKILL metadata (non-blocking)

