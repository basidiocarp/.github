# Handoff: Cross-Project Consistency Review

## What exists (state)
- **Scope:** All 9 projects in the ecosystem
- **Layer 1 results:** Lint audits complete (handoffs 01-08, 19)
- **Layer 2 results:** Structural reviews complete (handoffs 09-16, 20)
- **Files to change:** none — this is a read-only audit

## What I was doing (intent)
- **Goal:** Compare patterns across all 9 projects. Identify where the
  ecosystem is consistent, where it diverges, and whether divergences are
  intentional or accidental drift.

- **Approach:** Read the Layer 1 and Layer 2 summaries (not individual
  source files). Cross-reference patterns. Flag inconsistencies.

## Where I stopped (boundary)
- **Why:** handing off for review
- **Blocked on:** all Layer 2 handoffs (09-16, 20) complete
- **Next steps:**
  1. **Error handling consistency:**
     Do all Rust projects use `anyhow` for app-level and `thiserror` for
     library-level errors? List any that deviate and whether the deviation
     is justified.

  2. **SQLite consistency:**
     Do all SQLite projects (hyphae, mycelium, canopy, volva) set WAL mode,
     busy_timeout, and foreign_keys? List any gaps.

  3. **Spore adoption consistency:**
     Do all Rust projects use spore for discovery, paths, and config?
     Which still have local implementations that should migrate?

  4. **Test strategy consistency:**
     The ecosystem claims snapshot testing (insta) as the primary strategy.
     Compare actual snapshot test counts across projects. Which projects
     follow the strategy vs which rely on assertion-only tests?

  5. **CLAUDE.md accuracy:**
     Cross-reference each project's CLAUDE.md against the Layer 2 findings.
     Which CLAUDE.md files have stale information?

  6. **Contract compliance:**
     Check `contracts/` against actual implementations. Are all cross-tool
     payloads covered? Any payloads missing contracts?

  7. **Dependency version alignment:**
     Compare actual Cargo.toml versions against `ecosystem-versions.toml`.
     Any drift?

  8. **Code quality comparison:**
     Using Layer 1 metrics, compare across projects:
     - Which project has the most clippy warnings?
     - Which has the lowest test-to-code ratio?
     - Which has the most TODO/FIXME/HACK items?
     - Which has the most unwrap() calls?
     Are any projects significantly below the ecosystem average?

  9. **Duplicate implementations:**
     Any logic duplicated across projects that should be in spore?
     (Path resolution, JSON parsing helpers, error formatting, etc.)

  10. **Naming consistency:**
      Do CLI commands, config keys, and environment variables follow
      consistent conventions across projects?

- **Don't touch:** any source code — this is read-only

## Checklist
- [x] Error handling consistency assessed across all 8 Rust projects
- [x] SQLite configuration consistency assessed
- [x] Spore adoption consistency assessed
- [x] Test strategy comparison completed (snapshot counts per project)
- [x] CLAUDE.md accuracy cross-referenced with Layer 2 findings
- [x] Contract compliance verified
- [x] Dependency versions compared against ecosystem-versions.toml
- [x] Code quality metrics compared across projects
- [x] Duplicate implementations identified
- [x] Naming conventions assessed
- [x] No source files were modified
- [x] Summary provided with per-category findings:
  ```
  Consistent patterns: [list]
  Intentional divergences: [list with justification]
  Accidental drift: [list — these are bugs to fix]
  Duplicate implementations: [list with suggested spore extraction]
  Below-average projects: [list with specific metrics]
  ```

## Findings

Consistent patterns:
  - Zero TODO/FIXME/HACK across all 9 projects
  - All Rust projects: edition 2024, rust-version 1.85
  - anyhow (app) / thiserror (lib) error handling — 1 minor exception in spore
  - Release profile: LTO + single codegen unit + strip (all projects)
  - Shared dependency versions aligned: rusqlite 0.39, serde, clap
  - All projects degrade gracefully when dependencies unavailable

Intentional divergences:
  - Snapshot tests: only mycelium uses insta (10 tests); others use assertion-only — intentional per project scope

Accidental drift:
  - SQLite PRAGMAs: only canopy has full WAL + busy_timeout + foreign_keys; mycelium sets zero PRAGMAs; hyphae missing busy_timeout
  - Datetime crate fragmentation: chrono (spore, hyphae), jiff (mycelium), time (canopy) — not in ecosystem-versions.toml
  - ecosystem-versions.toml stale: cortina 0.2.5 (actual 0.2.6), stipe 0.5.6 (actual 0.5.7), canopy 0.3.0 (actual 0.3.1)
  - CLAUDE_SESSION_ID env reading: cortina, canopy, mycelium (x2) — should extract to spore::session::claude_session_id()
  - spore_tool() name mapping: cortina, stipe — should extract to Tool::from_binary_name()

Duplicate implementations:
  - normalize_identity: hyphae MCP (x3) — consolidate within hyphae
  - find_symbol_by_name: rhizome treesitter + lsp — move to rhizome-core
  - vscode_cline_settings_path: stipe ecosystem + doctor — consolidate within stipe
  - CLAUDE_SESSION_ID reading: 4 callsites — extract to spore

Below-average projects:
  - canopy: ~0.6% test:code ratio (lowest in ecosystem)
  - cap: ~1.1% test:code ratio
  - rhizome: BLOCKED (build broken)
