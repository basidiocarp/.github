# Volva: Orchestration Mode Definition

## ⚠ STOP — READ BEFORE STARTING ANYTHING

This handoff requires a design decision before any implementation begins. Do not write code, modify files, or spawn subagents until the questions in the "Decision Required" section have been answered by the human engineer.

Read this entire handoff, then ask the questions in "Decision Required." Implementation starts only after the human has chosen an approach.

---

## Handoff Metadata

- **Dispatch:** `umbrella — do not send to implementer directly`
- **Owning repo:** volva (runtime entry point)
- **Allowed write scope:** `volva/src/`, `volva/crates/volva-runtime/src/`, volva config surface
- **Cross-repo edits:** documentation only (update CLAUDE.md in dependent repos to reference Mode 1 vs Mode 2); no source changes in canopy, hyphae, or cortina
- **Non-goals:** implementing canopy multi-agent delegation; adding new MCP tools; changing how cortina hooks fire
- **Verification contract:** `volva --mode baseline` and `volva --mode orchestration` both start cleanly; missing dependencies in orchestration mode produce a clear error, not a silent hang
- **Completion update:** update dashboard when mode detection is implemented and tested

## Context

The ecosystem supports two meaningful operating modes, but nothing in the code makes this distinction explicit:

**Mode 1 — Baseline** (works without volva):
- mycelium filters command output
- hyphae provides cross-session memory
- rhizome provides code intelligence
- cortina fires lifecycle hooks
- No coordination layer; each tool works independently

**Mode 2 — Orchestration** (requires volva):
- Everything in Mode 1, plus:
- canopy tracks task ownership and handoffs
- hymenium orchestrates workflow dispatch and phase gating
- volva assembles the system prompt with a larger memory budget (2000+ tokens vs 500)
- multi-agent delegation is available through the canopy coordination surface

The problem: volva currently starts up and attempts to wire all dependencies regardless of which mode the user wants. If canopy is not running, volva may silently degrade or fail in non-obvious ways. There is no way for a user to say "I want baseline benefits only — don't try to connect to canopy."

This also creates documentation confusion. Agents don't know which mode they're in, so they don't know whether to attempt canopy operations.

---

## Decision Required

Before any implementation, the human engineer must answer these questions:

### Question 1: How should mode be selected?

**Option A: Explicit flag** — user passes `--mode baseline` or `--mode orchestration` to volva at startup. No auto-detection. Simple, explicit.

**Option B: Config file** — a `~/.config/volva/config.toml` field: `mode = "baseline" | "orchestration"`. Default is `"baseline"`. stipe sets this during install.

**Option C: Auto-detect** — volva probes for canopy availability at startup. If canopy responds within a short timeout, Mode 2 activates. If not, falls back to Mode 1 silently.

**Option D: Explicit, with graceful probe** — default is `"baseline"`. Pass `--mode orchestration` to request orchestration. Volva then probes canopy: if available, activates; if not, exits with a clear error ("orchestration mode requires canopy — start canopy first").

**Recommended: Option D.** Auto-detection (Option C) hides the mode from the operator and makes behavior hard to predict. Explicit selection with a clear error for missing deps is better. The error message is more useful than a silent fallback.

---

### Question 2: What changes when mode changes?

Answer these concretely before implementing:

| Behavior | Mode 1 (Baseline) | Mode 2 (Orchestration) |
|----------|-------------------|------------------------|
| hyphae recall budget | ~500 tokens | ~2000 tokens |
| canopy connection | not attempted | required |
| hymenium connection | not attempted | optional (graceful degradation) |
| system prompt assembly | hyphae recall only | hyphae + canopy task context + workflow state |
| multi-agent delegation | not available | available via canopy |

Are these the right differences? Does orchestration mode need anything else? Does baseline mode need anything removed (e.g., should baseline mode not even load canopy client code)?

---

### Question 3: Where does mode-gating logic live?

**Option A: In volva's `assemble_prompt()`** — check mode before calling canopy APIs. Most invasive change is isolated to one function.

**Option B: In volva's startup / init path** — determine mode early, build a capability set, pass it down. Functions that need canopy take a `&Capabilities` struct that says whether canopy is available.

**Option C: Feature flag in config** — no explicit mode enum; just a set of boolean flags (`canopy_enabled`, `hymenium_enabled`). More granular but also more complex.

**Recommended: Option B.** Capability set built at startup is more testable and makes it impossible for `assemble_prompt()` to accidentally call canopy in baseline mode. Option A works but tends to accumulate if-else chains.

---

### Question 4: What should the user experience be when starting each mode?

Volva should print something at startup that makes the mode visible. For example:

```
volva: baseline mode — hyphae + rhizome + mycelium active
volva: orchestration mode — canopy connected, full memory budget active
```

Or it can be silent (only log errors). Which do you prefer?

---

### Question 5: How does stipe handle mode during install?

When `stipe init` sets up volva, should it:
- Always configure baseline mode (safest, minimal deps)
- Probe for canopy and configure accordingly
- Ask the user which mode they want

This determines what stipe writes to the volva config during install. Answer here so the volva implementation and stipe's init path stay aligned. This handoff does not change stipe, but the answer should be recorded so the stipe handoff (if created) stays consistent.

---

## Questions for the Human Engineer

Before implementation starts, answer:

1. **Which mode selection approach?** (A, B, C, or D from Question 1)
2. **Are the mode difference table values correct?** Any behaviors to add or remove?
3. **Where does mode-gating logic live?** (A, B, or C from Question 3)
4. **Silent startup or visible mode announcement?**
5. **What should stipe write during install?**

---

## Implementation Seam (after decision)

- **Likely files:** `volva/src/main.rs` or startup path, `volva/crates/volva-runtime/src/context.rs`, `volva/config/` or equivalent
- **Reference seams:** read `volva/src/main.rs` before writing — find where canopy client is initialized and where `assemble_prompt()` is called
- **Spawn gate:** do not spawn an implementer until Questions 1-5 are answered
- **Read first:** `volva/crates/volva-runtime/src/context.rs` (the `assemble_prompt()` path identified in the audit as the place hyphae recall happens with a larger budget)

---

## Verification (after implementation)

```bash
# Baseline mode starts cleanly without canopy
volva --mode baseline
# Should start and print baseline mode announcement (or be silent per Q4 answer)

# Orchestration mode with canopy not running
volva --mode orchestration
# Should exit with clear error: "orchestration mode requires canopy"

# Orchestration mode with canopy running
canopy &
volva --mode orchestration
# Should start and connect to canopy

# Mode is visible in hyphae recall budget
# assemble_prompt() in baseline uses ~500 tokens
# assemble_prompt() in orchestration uses ~2000 tokens
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `--mode baseline` starts cleanly without canopy
- [ ] `--mode orchestration` fails with clear error when canopy is absent
- [ ] `--mode orchestration` connects when canopy is running
- [ ] Memory budget differs between modes
- [ ] No silent hangs or timeouts in either mode

## Completion Protocol

1. Decision questions answered by human
2. Mode selection implemented per chosen approach
3. Baseline mode works without canopy, rhizome, or hymenium
4. Orchestration mode emits clear error when canopy is unavailable (not a silent hang)
5. Memory budget correctly scoped per mode
6. Dashboard updated
