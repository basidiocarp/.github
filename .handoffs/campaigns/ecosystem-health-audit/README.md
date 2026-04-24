# Ecosystem Health Audit Campaign

**Started:** 2026-04-22
**Status:** ALL PHASES COMPLETE — Fix phase ready

## Purpose

A structured multi-phase audit of the basidiocarp ecosystem covering contract
integrity, code quality, architecture drift, bug patterns, and inter-tool
interaction correctness. Two passes per phase: Pass 1 is automated/mechanical
discovery; Pass 2 is agent-driven deep review of findings and areas automated
tools miss.

## Motivation

The handoff tracker drifted significantly from codebase reality (~60% of active
handoffs found already implemented during 2026-04-22 session). If the tracker
drifted, the code may have too — in both directions: things the tracker claimed
done may have regressed, and things added without a handoff may have introduced
problems. This campaign audits all five health dimensions before the next
feature wave.

## Pass Model

- **Pass 1 (Discovery):** Automated tools, grep patterns, script-driven
  mechanical scan. Fast, parallelizable, catches obvious issues.
- **Pass 2 (Deep Review):** Agent reads Pass 1 findings and manually inspects
  areas automated tools miss. Catches subtle issues, false positives, and
  things that require reading intent not just structure.

---

## Phase 1: Contract Audit

**Goal:** Verify septa schemas match what tools actually emit and consume.
Find cross-tool payloads that have no septa backing at all.

| Pass | Status | Agent | Findings |
|------|--------|-------|----------|
| Pass 1 — Discovery | Complete | Explore agent | [findings-p1.md](phase1-contract/findings-p1.md) |
| Pass 2 — Deep Review | Complete | Explore agent | [findings-p2.md](phase1-contract/findings-p2.md) |

**Scope:**
- Run `cd septa && bash validate-all.sh`
- For each schema: grep producer repos for the emitting type/struct, verify
  serialized shape matches schema definition
- Check every cross-tool call site for whether it goes through a septa schema
  or uses informal JSON
- Verify `canopy-snapshot-v1` `drift_signals` addition (2026-04-22) is correct
  in both schema and live code

**Repos to cover:** septa, canopy, cap, hyphae, cortina, mycelium, volva, rhizome

**Verification commands:**
```bash
cd septa && bash validate-all.sh
```

---

## Phase 2: Code Quality Audit

**Goal:** Surface unwrap abuse, error handling gaps, dead code, and formatting
drift across all Rust repos. Catch TypeScript type errors and lint violations
in cap.

| Pass | Status | Agent | Findings |
|------|--------|-------|----------|
| Pass 1 — Discovery | Complete | Explore agent | [findings-p1.md](phase2-quality/findings-p1.md) |
| Pass 2 — Deep Review | Complete | Explore agent | [findings-p2.md](phase2-quality/findings-p2.md) |

**Scope:**
- Rust: `cargo clippy --all-targets -- -D warnings` in each repo
- Rust: `cargo fmt --check` in each repo
- TypeScript: `tsc --noEmit` + `biome check` in cap
- Lamella: `make validate`
- Manual: `.unwrap()` / `.expect()` outside `#[test]` blocks, bare `?` chains
  without context at cross-boundary calls

**Repos:** mycelium, hyphae, canopy, rhizome, spore, stipe, cortina, annulus,
hymenium, volva, cap, lamella

---

## Phase 3: Architecture Drift Audit

**Goal:** Verify each repo's CLAUDE.md "operating model" and "does not"
constraints are honored in actual code. Check for unexpected cross-crate
coupling and repos that have grown beyond their stated scope.

| Pass | Status | Agent | Findings |
|------|--------|-------|----------|
| Pass 1 — Discovery | Complete | Explore agent | [findings-p1.md](phase3-architecture/findings-p1.md) |
| Pass 2 — Deep Review | Complete | Explore agent | [findings-p2.md](phase3-architecture/findings-p2.md) |

**Scope:**
- For each repo: extract "does not" constraints from CLAUDE.md, check against
  code mechanically
- Verify rhizome `backend_boundary.rs` test still passes and covers current
  crate layout
- Verify cortina/lamella boundary (observe.js removal, no runtime in lamella)
- Check `Cargo.toml` dependency graphs for unexpected coupling between repos
  that should be isolated

**Key constraints to check:**
- canopy: does not orchestrate workflows, does not store copied external payloads
- lamella: does not execute skills or agents, does not own runtime capture
- cortina: does not own long-term memory (hyphae does)
- hyphae: does not own coordination state (canopy does)

---

## Phase 4: Bug Audit

**Goal:** Find panic-prone patterns, missing input validation, and error
handling gaps at system boundaries.

| Pass | Status | Agent | Findings |
|------|--------|-------|----------|
| Pass 1 — Discovery | Pending | — | [findings-p1.md](phase4-bugs/findings-p1.md) |
| Pass 2 — Deep Review | Pending | — | [findings-p2.md](phase4-bugs/findings-p2.md) |

**Scope:**
- Grep all Rust for `.unwrap()` / `.expect()` / `panic!()` / `unreachable!()`
  outside `#[test]` and `#[cfg(test)]`
- Grep for unchecked integer casts (`as u32`, `as usize` on external input)
- Audit CLI entry points, MCP tool handlers, HTTP route handlers (cap server)
  for input validation at system boundaries
- Check that parse-don't-validate is applied at every external input boundary

**Repos:** all Rust repos, cap server routes

---

## Phase 5: Inter-Tool Interaction Audit

**Goal:** Trace each named integration seam end-to-end. Verify data flows
correctly between tools and that each side of a seam handles missing, stale,
or malformed input gracefully.

| Pass | Status | Agent | Findings |
|------|--------|-------|----------|
| Pass 1 — Discovery | Pending | — | [findings-p1.md](phase5-interaction/findings-p1.md) |
| Pass 2 — Deep Review | Pending | — | [findings-p2.md](phase5-interaction/findings-p2.md) |

**Seams to trace:**
1. `cortina adapter claude-code post-tool-use` → hyphae signal write → canopy evidence ref
2. `canopy api snapshot` → cap server reads → cap frontend renders
3. `hyphae MCP session-start` → context injection → claude code session
4. `lamella hooks.json` → hook scripts → cortina adapter calls
5. `rhizome export-to-hyphae` → hyphae ingest path
6. `volva run` → execenv setup → cortina adapter → hyphae recall injection

**For each seam:** trace the happy path, then ask "what breaks if X is
missing, stale, or malformed?" and verify the error handling is graceful.

---

## Findings Summary

Updated as each phase completes.

| Phase | Pass | Critical | High | Medium | Low | Status |
|-------|------|----------|------|--------|-----|--------|
| 1 Contract | P1 | 1 | 0 | 1 | 2 | Complete |
| 1 Contract | P2 | 1 | 2 | 1 | 2 | Complete — verdict: FAIR |
| 2 Quality | P1 | 0 | 0 | 0 | 4 | Complete — 119 clippy errors, all fmt fail, 736 unwrap count |
| 2 Quality | P2 | 0 | 0 | 1 | 4 | Complete — verdict: FAIR (most P1 highs were false positives) |
| 3 Architecture | P1 | 0 | 0 | 0 | 0 | Complete — PASS, 11/11 constraints verified, 0 violations |
| 3 Architecture | P2 | 0 | 1 | 0 | 1 | Complete — verdict: FAIR (spore version drift found) |
| 4 Bugs | P1 | 0 | 0 | 0 | 0 | Complete — verdict: PASS (all panics test-only, validation solid) |
| 4 Bugs | P2 | 0 | 0 | 0 | 2 | Complete — verdict: PASS (confirmed, SQLite WAL advisory, annulus schema contract advisory) |
| 5 Interaction | P1 | 0 | 1 | 3 | 2 | Complete — verdict: FAIR (cap→canopy FRAGILE, 3 unseamed seams) |
| 5 Interaction | P2 | 0 | 1 | 3 | 2 | Complete — verdict: FAIR (1 FRAGILE trivially fixable, 3 PARTIAL, new cortina timeout issue) |

---

## Fix Tracking

Issues found during audit are tracked here once confirmed real (not false
positives). Each gets a severity, owning repo, and fix status.

| # | Severity | Repo | Issue | Fix Status |
|---|----------|------|-------|------------|
| 1 | Critical | septa + canopy | HandoffStatus enum drift — schema has `pending/accepted/completed/rejected`, Rust has `Open/Accepted/Rejected/Expired/Cancelled/Completed` | Fixed (2026-04-23) |
| 2 | High | septa + canopy | `canopy-snapshot-v1` schema has `additionalProperties: false` but struct emits 21 fields; schema documents only ~10 | Fixed (2026-04-23) |
| 3 | High | septa + cortina + canopy | `cortina audit-handoff` response has no septa schema backing a critical cross-tool dispatch boundary | Fixed (2026-04-23) |
| 4 | Medium | cap | `validateCanopySnapshot()` doesn't check `drift_signals` — required field added 2026-04-22 not validated | Open |
| 5 | Low | cap | Hook error log NDJSON format undocumented — graceful fallback is solid, no action needed | Accepted risk |
| 6 | Low | cap | `hyphae-search-v1` consumer doesn't validate `schema_version` | Accepted risk |
| 7 | High | ecosystem | Spore version drift — canonical `ecosystem-versions.toml` pins v0.4.10; mycelium/rhizome/stipe/hymenium on v0.4.9, hyphae/cortina/canopy/volva/annulus on v0.4.11; no repo on canonical | Fixed (2026-04-23) |
| 8 | Low | cortina | `rusqlite` declared in Cargo.toml but appears unused in source — possible dead dependency | Open |
| 9 | High | cortina + hyphae | Session state orphaning — stale session scope file reused when hyphae unavailable; parallel worktrees collapse to same session ID | Open |
| 10 | High | cap + canopy | Cap has no secondary read path if canopy is down — dashboard returns 500, operator loses all visibility | Fixed (2026-04-23) |
| 11 | Medium | hyphae + volva + cortina | Hyphae protocol/recall response shapes not in septa — changes break volva/cortina without detection | Open |
| 12 | Medium | cortina + lamella | Async hook execution without persistence guarantee — captures dropped if session exits before cortina write completes | Open |
| 13 | Medium | cortina + lamella | Lamella hook envelope not schema-backed — Claude Code envelope changes break cortina silently | Open |
| 14 | Medium | volva + hyphae | Volva context injection timeouts (250ms/500ms) fail silently — user unaware of memory context loss | Open |
| 15 | Medium | cortina | `Command::output()` on hyphae write has no internal timeout — cortina blocks until hook timeout kills it, state file not cleaned | Open |
| 16 | Low | cap | Canopy CLI error swallowed — 500 response returns generic message, hides root cause (e.g., "database locked") | Open |

---

## Related

- [HANDOFFS.md](../../HANDOFFS.md) — active handoff dashboard
- [septa/README.md](../../../../septa/README.md) — contract ownership and validation
- [docs/foundations/README.md](../../../../docs/foundations/README.md) — Rust architecture standards
- [AGENTS.md](../../../../AGENTS.md) — workspace agent orchestration rules
