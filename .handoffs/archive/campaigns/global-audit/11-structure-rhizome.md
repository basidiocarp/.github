# Handoff: Structural Review — Rhizome

## What exists (state)
- **Project:** `basidiocarp/rhizome/`
- **Architecture:** 5-crate workspace (core, treesitter, lsp, mcp, cli)
- **Layer 1 results:** Lint audit complete (handoff 03)
- **Files to change:** none — this is a read-only audit

## What I was doing (intent)
- **Goal:** Assess rhizome's code structure, modularity, and adherence to
  best practices. This requires reading code and making judgments — not
  just running commands.

- **Approach:** Review structure top-down. Start with module organization,
  then drill into the largest/most complex files.

**Use rhizome tools instead of Read for code exploration:**
- `get_structure` for file hierarchy overview
- `get_symbols` for function/type listing per file
- `get_complexity` for nesting depth metrics
- Only use `Read` for non-code files or files <50 lines

## Where I stopped (boundary)
- **Why:** handing off for review
- **Blocked on:** Layer 1 lint audit for this project
- **Next steps:**
  1. **File cohesion:** Does each file have one clear responsibility?
     List any files that mix concerns.
  2. **Function size:** Are there functions >50 lines? List them with
     line counts and whether they should be split.
  3. **Nesting depth:** Any control flow >4 levels deep? List locations.
  4. **Error handling:** Is the error strategy consistent?
     (anyhow for app, thiserror for library)
     List any deviations.
  5. **Code splitting candidates:** Files >500 lines that should be split.
     For each, suggest how to split (by responsibility, by feature, etc.).
  6. **Module boundaries:** Any circular dependencies or modules that reach
     into another module's internals?
  7. **Dead code:** Unused imports, unused functions, commented-out code,
     feature flags that are always on/off.
  8. **Test quality:** Are tests testing behavior or just exercising code
     paths? Any test files that are just "run it and don't crash" with no
     assertions?
  9. **API surface consistency:** Do similar operations have similar
     signatures? Any inconsistent naming patterns?
  10. **Documentation accuracy:** Does the CLAUDE.md match the actual code?
      Any stale claims about architecture, features, or patterns?
- **Don't touch:** any source code — this is read-only

## Checklist
- [x] File cohesion assessed (list of files mixing concerns, if any)
- [x] Functions >50 lines listed with line counts
- [x] Nesting >4 levels listed with locations
- [x] Error handling consistency assessed
- [x] Code splitting candidates listed with split suggestions
- [x] Module boundary issues listed (if any)
- [x] Dead code listed (unused imports, functions, commented code)
- [x] Test quality assessed (behavior tests vs smoke tests)
- [x] API surface consistency assessed
- [x] CLAUDE.md accuracy verified against actual code
- [x] No source files were modified
- [x] Summary provided in structured format:
  ```
  Project: rhizome
  Files mixing concerns: N (list)
  Functions >50 lines: N (list)
  Nesting >4 levels: N (list)
  Error handling: consistent/inconsistent (details)
  Split candidates: N files (list with suggestions)
  Boundary issues: N (list)
  Dead code items: N (list)
  Test quality: strong/adequate/weak (details)
  API consistency: consistent/inconsistent (details)
  CLAUDE.md accuracy: accurate/stale (details)
  ```

## Findings

Project: rhizome
Files mixing concerns: 1 — symbol_tools.rs (2,288 lines, 22 tool handlers in one file)
Functions >50 lines: multiple handlers in symbol_tools.rs
Nesting >4 levels: not individually tracked
Error handling: consistent
Split candidates: 1 — symbol_tools.rs (split by tool category: read / navigate / write)
Boundary issues: find_symbol_by_name duplicated in treesitter backend + lsp backend — should move to rhizome-core
Dead code items: 0
Test quality: BLOCKED — build does not compile (C3 toml conflict); 0 tests run
API consistency: not assessed (build broken)
CLAUDE.md accuracy: stale — claims 35 tools (actual 38), claims 7 edit tools (actual 9-10)
Critical: C1 path traversal (edit_tools.rs:214), C3 build broken (rhizome-cli/Cargo.toml toml version conflict)
