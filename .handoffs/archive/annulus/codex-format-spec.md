# Annulus: Codex Transcript Format Spec

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** `annulus/docs/providers/`, `annulus/tests/fixtures/codex/`
- **Cross-repo edits:** none
- **Non-goals:** implementing the Codex provider reader (#118b); changing the `TokenProvider` trait; touching production source files in `annulus/src/`
- **Verification contract:** repo-local `bash .handoffs/annulus/verify-codex-format-spec.sh` plus `python3 -m json.tool` (or `jq`) against the fixture
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive this handoff

## Problem

`CodexProvider` is a stub that returns `Ok(None)`. The handoff that adds the
real reader (#118b) needs a documented format spec to work against, plus a
fixture so the reader's tests are deterministic. Today no one has written down
where the Codex CLI stores session data on disk, what the schema looks like,
or how to recognize a token-usage entry.

This handoff is research + docs only. No annulus runtime code changes.

## What exists (state)

- **`annulus/src/providers/codex.rs`**: stub provider, no reader
- **`annulus/docs/`**: does not exist yet — this handoff creates it
- **No Codex fixtures**: nothing in `annulus/tests/fixtures/`
- **External**: Codex CLI is openai/codex on GitHub. Session data location and
  schema are documented (informally) in its codebase / cache directory.

## What needs doing (intent)

Discover and document, in the annulus repo:

1. The on-disk path Codex CLI writes session/usage data to (per platform)
2. The file format (NDJSON, JSON, SQLite, …) and the relevant top-level shape
3. Which fields carry token counts (prompt, completion, cache reads, etc.)
4. How to identify a "session" boundary, if any
5. A real-format fixture file that #118b's tests can load

The downstream reader handoff (#118b) does not need to research any of this —
it consumes the spec and fixture this handoff produces.

## Scope

- **Primary seam:** documentation + test fixtures, no source changes
- **Allowed files:**
  - `annulus/docs/providers/codex.md` (new)
  - `annulus/tests/fixtures/codex/sample-session.<ext>` (new — extension chosen by reality)
  - `annulus/tests/fixtures/codex/README.md` (new — provenance note)
- **Explicit non-goals:**
  - `annulus/src/providers/codex.rs` modifications
  - reader code (#118b)
  - bumping `CodexProvider::is_available` (#118b)

---

### Step 1: Discover the on-disk format

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** nothing

Find where the Codex CLI writes session data. Likely candidates:
- `~/.codex/`
- `~/.cache/codex/`
- `~/Library/Application Support/codex/` (macOS)
- An XDG-respecting variant

Approaches in priority order:

1. Run the Codex CLI locally for a short session and `find` recent files in
   the candidate directories (`find ~ -newer /tmp/marker -type f 2>/dev/null`).
2. Read the openai/codex source on GitHub for the path-resolution code (look
   for `dirs::home_dir`, `XDG`, `cache_dir`, or `config_dir` references).
3. Skim its release notes for the documented config / cache layout.

Capture findings in `annulus/docs/providers/codex.md` with explicit per-OS
paths and a note on the resolution order Codex uses.

#### Verification

```bash
test -f annulus/docs/providers/codex.md && wc -l annulus/docs/providers/codex.md
```

**Output:**
<!-- PASTE START -->
PASS: codex format spec exists
     137 annulus/docs/providers/codex.md
<!-- PASTE END -->

**Checklist:**
- [x] `annulus/docs/providers/codex.md` exists
- [x] Lists the canonical session-data path on macOS, Linux, and Windows (or notes "not yet observed" with a TODO)
- [x] Documents the resolution order (env var → XDG → home fallback)

---

### Step 2: Document the file format and token fields

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** Step 1

For the chosen file (or the canonical one if there are several), document:

- File format (e.g. NDJSON one entry per turn, single JSON, SQLite tables)
- Top-level shape — a representative entry copied from a real session
- Which fields carry token counts: prompt/input tokens, completion/output
  tokens, cache hits if Codex distinguishes them, cumulative vs per-turn
- How to detect session boundaries (timestamp gaps, explicit markers, file
  rotation, …) — or "no boundary signal" with a recommended heuristic
- Edge cases the reader must tolerate: partial writes, log-rotation, missing
  fields on system entries, multiple concurrent sessions

Update `annulus/docs/providers/codex.md` with these sections.

#### Verification

```bash
rg -q '^## Format' annulus/docs/providers/codex.md
rg -q '^## Token fields' annulus/docs/providers/codex.md
rg -q '^## Session boundary' annulus/docs/providers/codex.md
```

**Output:**
<!-- PASTE START -->
PASS: format section present
PASS: token-fields section present
PASS: session-boundary section present
<!-- PASTE END -->

**Checklist:**
- [x] Format section names the on-disk format and gives a real entry example
- [x] Token-fields section maps each Codex field to its meaning
- [x] Session-boundary section explains how to detect (or that you can't)
- [x] Edge-cases section names at least three failure modes the reader must handle

---

### Step 3: Capture a real-format fixture

**Project:** `annulus/`
**Effort:** 0.25 day
**Depends on:** Step 2

Save a small but realistic fixture under `annulus/tests/fixtures/codex/`.
Anonymize any prompts or model output — the fixture only needs the structural
fields the reader will parse (timestamps, token counts, identifiers).

`annulus/tests/fixtures/codex/README.md` must record:

- How the fixture was captured (CLI version, date)
- What was redacted and why
- Which entries to exercise in tests (the "gold" entries)

#### Verification

```bash
test -d annulus/tests/fixtures/codex
test -f annulus/tests/fixtures/codex/README.md
ls annulus/tests/fixtures/codex/ | grep -v README.md | head -1
```

**Output:**
<!-- PASTE START -->
PASS: fixture directory exists
PASS: fixture README documents provenance
PASS: at least one fixture file present
sample-session.jsonl
<!-- PASTE END -->

**Checklist:**
- [x] Fixture file exists and is non-empty
- [x] Fixture parses as the documented format (validate with `python3 -m json.tool`, `jq`, or equivalent if applicable)
- [x] README documents capture provenance and redaction
- [x] Fixture includes at least two assistant turns so the reader can exercise both single-entry and aggregation paths

---

## Completion Protocol

This handoff is NOT complete until ALL of the following are true:

1. Every step above has verification output pasted between the markers
2. `bash .handoffs/annulus/verify-codex-format-spec.sh` passes
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated and this handoff is archived

### Final Verification

```bash
bash .handoffs/annulus/verify-codex-format-spec.sh
```

**Output:**
<!-- PASTE START -->
PASS: codex format spec exists
PASS: format section present
PASS: token-fields section present
PASS: session-boundary section present
PASS: fixture directory exists
PASS: fixture README documents provenance
PASS: at least one fixture file present
PASS: no source changes (research-only handoff)
Results: 8 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Splits the original "implement Codex provider" intent from #104d into a
research/docs phase and an implementation phase. This handoff is the upstream
of #118b. Mirrored by #119a for Gemini.
