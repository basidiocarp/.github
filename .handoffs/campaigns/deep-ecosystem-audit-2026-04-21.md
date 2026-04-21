# Deep Ecosystem Audit — 2026-04-21

## Campaign Metadata

- **Type:** Audit
- **Priority:** Medium — run after post-session contract audit is archived
- **Scope:** All repos touched in the 2026-04-21 session; ecosystem-wide boundary and integration health
- **Goal:** Catch bugs and code quality issues in session-changed code; verify repos stay within their stated responsibilities; confirm cross-tool contracts and wiring are sound

---

## Lanes

| # | Lane | Repo(s) | Owner file |
|---|------|---------|------------|
| A | Code quality — hyphae | hyphae | this file §A |
| B | Code quality — stipe | stipe | this file §B |
| C | Code quality — canopy | canopy | this file §C |
| D | Code quality — lamella | lamella | this file §D |
| E | Boundary audit | all | this file §E |
| F | Integration health | workspace | this file §F |

Lanes A–D and E–F are independent. Run A–D in parallel, then E–F in parallel.

---

## Auditor Ground Rules

- **Read-only**: do not change production code. File findings only.
- **Stay in scope**: only review code changed in the 2026-04-21 session (see each lane's scope section).
- **Be concrete**: report file path, line number, and exact concern. No vague warnings.
- **Verification first**: run the lane's verification command and report its result before reviewing code.
- **Done means**: verification passes AND findings are reported (even if findings are "none").

---

## Lane A — Code Quality: hyphae

### Scope (2026-04-21 changes)
- `content_hash` field added to `Document` struct + schema migration
- `compute_content_hash` function (likely in `hyphae-ingest` or `hyphae-store`)
- Skip-on-reindex logic in `tool_ingest_file` MCP handler
- `hyphae bench-retrieval` CLI command

### Files to review
- `crates/hyphae-ingest/src/` — hash computation and skip logic
- `crates/hyphae-mcp/src/tools/ingest.rs` — MCP handler skip path
- `crates/hyphae-store/src/` — any schema migration touching Document
- `crates/hyphae-cli/src/commands/` — bench-retrieval command

### Look for
- Hash computation correctness: edge cases (empty file, binary content, very large files)
- Skip logic: does it handle hash collisions or partial re-index correctly?
- Error handling: any `.unwrap()` or bare `?` without context on I/O paths
- Migration safety: is the `content_hash` column nullable/defaulted for existing rows?
- bench-retrieval: does it respect HYPHAE_DB env var? Does it handle empty store gracefully?

### Verification
```bash
cd /Users/williamnewton/projects/basidiocarp/hyphae
cargo test --workspace 2>&1 | tail -5
```
Expected: all pass.

### Done when
Verification passes. Findings documented below under "Lane A Findings".

**Lane A Findings:** *(auditor fills in)*

---

## Lane B — Code Quality: stipe

### Scope (2026-04-21 changes)
- `stipe init --interactive` interactive flow
- `stipe backup hyphae` command and `pre_upgrade_backup_hyphae` logic

### Files to review
- `src/commands/init.rs` — interactive path
- `src/backup.rs` — backup logic, path handling, error cases

### Look for
- Interactive flow: does it handle non-TTY environments gracefully? Any panic paths?
- Backup: what happens if hyphae binary is not installed? If target dir is not writable?
- Path handling: are paths validated before use? Tilde expansion handled correctly?
- Error context: do errors on backup failure propagate with enough context for the operator?
- Any `.unwrap()` on I/O operations outside of tests

### Verification
```bash
cd /Users/williamnewton/projects/basidiocarp/stipe
cargo test 2>&1 | tail -5
```
Expected: all pass.

### Done when
Verification passes. Findings documented below under "Lane B Findings".

**Lane B Findings:** *(auditor fills in)*

---

## Lane C — Code Quality: canopy

### Scope (2026-04-21 changes)
- Task tree implementation
- Completion guard: `canopy task complete` now errors on open children

### Files to review
- Wherever task tree and parent/child relationships are stored and queried
- The `task complete` command handler

### Look for
- Completion guard: does it handle deeply nested trees correctly? Cycles?
- Task tree: are orphaned children cleaned up if a parent is force-deleted?
- Error messages: does the "open children" error tell the operator which children are blocking?
- Concurrency: is there a TOCTOU race between the child check and the completion write?
- Any unwrap on SQLite queries outside test code

### Verification
```bash
cd /Users/williamnewton/projects/basidiocarp/canopy
cargo test --all 2>&1 | tail -5
```
Expected: all pass.

### Done when
Verification passes. Findings documented below under "Lane C Findings".

**Lane C Findings:** *(auditor fills in)*

---

## Lane D — Code Quality: lamella

### Scope (2026-04-21 changes)
- Session-end shim removed; `cortina adapter claude-code session-end` is now the live hook
- 2 new skills added
- Eval harness added

### Files to review
- Hook definitions — confirm session-end hook points to cortina correctly
- New skill manifest files — validate structure and content
- Eval harness — correctness of evaluation logic, any hardcoded paths

### Look for
- Hook routing: does the cortina adapter handle non-zero exit from claude-code gracefully?
- New skills: do manifests declare all required fields? Any broken relative paths?
- Eval harness: does it handle missing rubric files or empty outputs without panicking?
- Any environment-specific assumptions (hardcoded home dirs, assumed binary locations)

### Verification
```bash
cd /Users/williamnewton/projects/basidiocarp/lamella
make validate 2>&1 | tail -5
```
Expected: all validators passed.

### Done when
Verification passes. Findings documented below under "Lane D Findings".

**Lane D Findings:** *(auditor fills in)*

---

## Lane E — Boundary Audit

### Goal
Verify each repo is staying within its stated responsibilities. After a multi-repo session it is easy for one tool to silently absorb behavior that belongs to another.

### Repos to check
hyphae, stipe, canopy, lamella, cortina, cap (any UI wiring added)

### Method
For each repo:
1. Read its `CLAUDE.md` "Operating Model" and "Failure Modes" sections.
2. Scan recently changed files (use `git log --oneline -20` in the repo).
3. Ask: does any new code contradict the operating model? Is any logic living in the wrong tool?

### Specific risks from this session
- hyphae absorbing session capture (should stay in cortina)
- stipe absorbing runtime behavior from installed tools
- canopy growing orchestration logic that belongs in hymenium
- lamella growing runtime hook behavior that belongs in cortina

### Verification
No single command. Report findings as a structured list: `repo / concern / evidence (file:line)`.

### Done when
Each repo checked; findings or "within bounds" verdict per repo documented below.

**Lane E Findings:** *(auditor fills in)*

---

## Lane F — Integration Health

### Goal
Verify the cross-tool data flows and contracts are sound end-to-end after the session's changes.

### Checks

1. **Lifecycle signal chain** (re-run after all session commits are in):
```bash
cd /Users/williamnewton/projects/basidiocarp
bash scripts/test-lifecycle.sh
```
Expected: 14 passed, 0 failed, 1 skipped.

2. **Septa contract validation**:
```bash
bash septa/validate-all.sh
```
Expected: all pass.

3. **Cross-tool contract review** — for each contract in `septa/`:
   - Identify the producer and consumer
   - Confirm the producer's current output shape matches the schema
   - Confirm the consumer's current parser matches the schema
   - Flag any mismatch

4. **cortina → hyphae wiring**: confirm the session-end hook path (`cortina adapter claude-code session-end`) correctly produces a `session-event-v1` payload and that hyphae's consumer accepts it.

5. **Cap consumers**: Cap shells out to `hyphae activity`, `hyphae analytics`, `hyphae lessons`, `hyphae session timeline`. Confirm those CLI commands still exist and their output shapes match what Cap expects.

### Done when
All verification commands pass. Contract review findings documented below.

**Lane F Findings:** *(auditor fills in)*

---

## Completion

This campaign is complete when:
- [ ] Lanes A–D: verification passes and findings documented
- [ ] Lanes E–F: all checks pass and findings documented
- [ ] Any blocking findings addressed (new handoffs created if fixes needed)
- [ ] Non-blocking findings triaged (new handoffs or accepted-risk notes)

Archive to `.handoffs/archive/campaigns/` and note the date completed.
