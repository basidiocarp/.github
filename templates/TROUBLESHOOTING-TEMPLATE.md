# [Tool] Troubleshooting

[One sentence telling the reader where to start. Name the single most likely root
cause and the first command to run. This sentence alone saves most users from reading
the rest of the doc.]

Example: "If you've just installed [Tool] and something isn't working, start with #1—
most issues trace back to the MCP config or a missing restart."

Example: "Start with `[tool] doctor`. Most failures come down to missing registration
or a stale binary path."

---

## Fast Triage

<!-- Conditional — include when the tool has multiple distinct failure surfaces or
     when there is a single first-command-to-run that narrows the problem space quickly.
     The Basidiocarp troubleshooting doc's fast triage table is the gold standard.

     Format: three columns — Symptom | First Command | What it usually means
     Keep symptoms short (one clause). First command should be copy-pasteable.
     "What it usually means" is the most likely cause, not an exhaustive list.

     Skip this section for simple tools with only one or two failure modes.
-->

| Symptom | First Command | What it usually means |
|---------|---------------|-----------------------|
| [Observable behavior A] | `[tool] doctor` | [Most likely cause] |
| [Observable behavior B] | `[tool] status` | [Most likely cause] |
| [Observable behavior C] | `[tool] [command] --diagnostics` | [Most likely cause] |
| [Observable behavior D] | `[sibling] --version` | [Most likely cause] |

---

## [Category A: e.g., Setup and Registration Issues]

<!-- Organize issues into thematic categories when there are more than six total
     issues. Use numbered issues when there are six or fewer — numbers make
     cross-referencing easy ("see issue #3").

     Category names should match the failure surface, not the fix:
     Good: "Setup and Registration Issues", "LSP Server Issues", "Performance Issues"
     Bad: "Initialization", "Server", "Slow"

     Within each category, order issues by frequency — most common first.
-->

### [Issue title as an observable symptom, not a cause]

<!-- Title format: describe what the user sees, not what the cause is.
     Good: "Agent doesn't use [Tool] tools"
           "`[tool] recall` returns nothing"
           "Commands pass through raw instead of filtering"
     Bad:  "MCP registration failure"  ← internal cause, not user-visible
           "Embeddings issue"           ← too vague
-->

**Symptom:** [What the user observes. One or two sentences. Specific enough that
the user can confirm they have this exact problem.]

**Diagnosis:** [Why this is happening. One sentence. This is the most consistently
missing piece in weak troubleshooting docs — explaining root cause helps users
confirm they have the right issue before following the fix steps. Skip if the
cause is obvious from the symptom.]

**Fix:**

1. [First diagnostic step — the narrowest command that confirms or rules out the most likely cause]
   ```bash
   [copy-pasteable command]
   ```
   [What to look for in the output. What "healthy" looks like vs. "broken".]

2. [Second step — if step 1 confirmed the problem, this is the repair]
   ```bash
   [copy-pasteable command]
   ```

3. [Edge case or alternative fix for a different root cause of the same symptom]
   ```bash
   [copy-pasteable command]
   ```

---

### [Second issue in same category]

**Symptom:** [What the user observes.]

**Diagnosis:** [Root cause.]

**Fix:**

1. [Step]
   ```bash
   [command]
   ```

2. [Step]

---

## [Category B: e.g., Integration Issues]

### [Issue title]

**Symptom:** [What the user observes.]

**Diagnosis:** [Root cause.]

**Fix:**

1. Check whether [sibling tool] is available:
   ```bash
   [sibling] --version
   ```

2. [Repair step]
   ```bash
   [command]
   ```

3. Verify:
   ```bash
   [tool] doctor
   ```

---

## [Category C: e.g., Configuration Issues]

### [Issue title]

**Symptom:** [What the user observes.]

**Diagnosis:** [Root cause — e.g., "Config file in wrong location, TOML syntax error, or wrong permissions."]

**Fix:**

1. Confirm the config file exists and is readable:
   ```bash
   cat ~/.config/[tool]/config.toml
   ```

2. Validate TOML syntax:
   ```bash
   # Python
   python3 -c "import tomllib; tomllib.loads(open('config.toml').read())"
   ```

3. [Tool] loads config in this order — later entries override earlier ones:
   ```
   1. Global:  ~/.config/[tool]/config.toml
   2. Project: <project_root>/.[tool]/config.toml
   3. Env:     [TOOL_VAR]_* variables (override both)
   ```

---

## [Category D: e.g., Performance Issues]

<!-- Include only if the tool has real performance failure modes that aren't obvious.
     Performance "issues" that are actually expected behavior (first-run model download,
     large file processing) should be documented here so users don't file bugs. -->

### [Issue title — e.g., "Slow on first launch"]

**Symptom:** [Tool] takes [N] seconds on first [operation].

**Diagnosis:** [What is happening — e.g., "The embedding model (~45MB) is downloaded on first use.
Subsequent runs load from cache in 1-2 seconds."]

This is expected behavior. [What the user can do to speed it up, if anything.]

```bash
[optional: command to check status or accelerate]
```

---

### [Issue title — e.g., "Slow on large files"]

**Symptom:** [Operation] is slow on files over [threshold].

**Fix:**

1. Check file size — above [N] lines or [N]MB, expect slower processing:
   ```bash
   wc -l path/to/file
   ```

2. [Alternative approach that is faster for large inputs]

3. Check resource usage during operation:
   ```bash
   top -p $(pgrep [tool])
   ```
   If memory or CPU is unexpectedly high, [file a bug / check logs].

---

## Error Message Quick Reference

<!-- Required. The single most useful section for users who get an error message
     and want to know what to do. Rhizome's version is the gold standard.

     Format: three columns — Error string | Cause | Fix
     Use the exact error message text (or a close match) in the Error column so
     users can find their specific error quickly.
     Fix column should be one actionable step, not a paragraph.
     Link to the full issue section above where the fix needs more detail.
-->

| Error | Cause | Fix |
|-------|-------|-----|
| `"[exact error string]"` | [Root cause] | [One-line fix or link to section above] |
| `"[exact error string]"` | [Root cause] | [One-line fix] |
| `"[exact error string]"` | [Root cause] | [One-line fix] |
| `"[exact error string]"` | [Root cause] | [One-line fix] |
| `"[exact error string]"` | [Root cause] | [One-line fix] |

---

## Diagnostic Commands

<!-- Required. Covers: enabling debug logging, checking version, inspecting state.
     These are the commands to run before filing a bug.
-->

**Enable debug logging:**
```bash
# All debug output
[TOOL_LOG_VAR]=debug [tool] [command]

# [Tool]-specific only (excludes noisy dependency logs)
[TOOL_LOG_VAR]=[tool]=debug [tool] [command]
```

**Check version:**
```bash
[tool] --version
```

**Inspect current configuration:**
```bash
[tool] [config-command]
# or
cat ~/.config/[tool]/config.toml
```

**Check state and health:**
```bash
[tool] doctor
[tool] status
```

---

## Performance Benchmarks

<!-- Conditional — include only if you have real measured numbers.
     The purpose of this section is to answer "is my performance normal?"
     so users don't file bugs for expected behavior.
     Skip if you don't have numbers to back it up.

     Rhizome's benchmark table is the model.
-->

For reference, typical performance on a modern machine:

| Operation | Input Size | Expected Time | Notes |
|-----------|-----------|---------------|-------|
| [Operation A] | [N lines / N MB] | [<Xms] | [Backend or mode used] |
| [Operation B] | [N items] | [~Xms] | [Any caveats] |
| [Operation C] | [N files] | [X-Xs] | [What affects this] |

If your times are significantly worse, check:
- [Most common cause of slow performance #1]
- [Most common cause #2]
- [System resource check command]

---

## When to Escalate

<!-- Required. Tells users when to stop trying to self-diagnose and file a bug.
     Rhizome's version is the model. Four to six clear triggers.
     Avoids the "file a bug if something feels wrong" vagueness.
-->

Stop troubleshooting and file a bug if:

1. The same operation fails consistently on multiple [files / inputs / sessions]
2. An error message is unclear or contradicts this documentation
3. Performance degraded significantly after an upgrade
4. The tool crashes with a stack trace
5. [Tool-specific escalation trigger — e.g., "LSP server crashes with logs you can capture"]
6. `[tool] doctor` reports healthy but the tool still misbehaves

---

## Report a Bug

When filing a bug, include:

1. `[tool] --version` output
2. `[tool] doctor` or `[tool] status` output
3. Relevant config file contents (`~/.config/[tool]/config.toml`)
4. Full debug log: `[TOOL_LOG_VAR]=debug [tool] [command] 2>&1`
5. [Smallest input that reproduces the issue — e.g., "Example file", "Exact command run"]
6. Expected behavior vs. actual behavior

---

## FAQ

<!-- Conditional — include for tools where there are recurring conceptual questions
     that don't fit the Symptom/Fix pattern. Hyphae's FAQ is the gold standard.

     Format: Q: question in plain language / A: direct answer, first word signals yes/no where possible.
     Order by frequency — most common first.
     Keep answers short. Link to deeper docs where more detail is needed.

     Good questions: data privacy, multi-project usage, model/backend swapping,
                     token cost, backup/restore, scale limits, comparison to alternatives.
     Bad questions: "How do I install [Tool]?" — that belongs in the README.
                    "What is [Tool]?" — that belongs in the README.
-->

### Does [Tool] send data over the internet?

[Direct answer. Call out any exceptions clearly — e.g., initial model download.]

### Can I use [Tool] with multiple projects?

[Direct answer with the recommended approach.]

### How do I back up and restore [Tool]'s data?

```bash
# Backup
[command]

# Restore
[command]
```

### [Common question about behavior that surprises users]

[Direct answer.]

### [Common question about limits or scale]

[Direct answer with concrete numbers if available.]

---

## See Also

<!-- Required. Link to the docs that are most useful after reading this one.
     Three to five links max. One clause each explaining what's in the linked doc. -->

- [[GUIDE.md]](GUIDE.md) — [what it covers]
- [[CLI-REFERENCE.md]](CLI-REFERENCE.md) — [what it covers]
- [[ARCHITECTURE.md]](ARCHITECTURE.md) — [what it covers, when to read it]
