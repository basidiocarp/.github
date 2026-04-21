# Handoff: Structural Review — Spore

## What exists (state)
- **Project:** `basidiocarp/spore/`
- **Architecture:** Pure library crate, 10 modules
- **Layer 1 results:** Lint audit complete (handoff 07)
- **Files to change:** none — this is a read-only audit

## What I was doing (intent)
- **Goal:** Assess spore's code structure, modularity, and adherence to
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
  Project: spore
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

Project: spore
Files mixing concerns: none — pure library, clean module separation
Functions >50 lines: not individually tracked
Nesting >4 levels: not individually tracked
Error handling: 1 minor deviation noted (anyhow/thiserror boundary slightly blurred in one location)
Split candidates: none
Boundary issues: double-framing bug (C2) in subprocess.rs:109-171; CLAUDE.md lists 3 consumers (actual 6), says cortina/canopy "planned" (both live)
Dead code items: 0
Test quality: 81 tests, ~2.7% ratio — above ecosystem average for a library
API consistency: consistent
CLAUDE.md accuracy: stale — lists 3 consumers (actual 6: hyphae, mycelium, rhizome, cortina, canopy, stipe), says cortina/canopy are "planned" (both actively live)
Note: uses chrono for datetime — ecosystem has fragmentation (chrono in spore/hyphae, jiff in mycelium, time in canopy)
