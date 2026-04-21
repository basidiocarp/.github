# Codex / Gemini Adapters in Cortina

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** cortina/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Cortina's signal pipeline is adapter-first, but only two adapters exist: Claude
Code and Volva. Teams using Codex or Gemini-based tooling get none of the cortina
signal capture — no error signals, no recall attribution, no session bridge. The
cortina roadmap lists this as low priority ("only if another host proves it needs
real implementation work and can't be handled as thin packaging") — the gate is
proving the need before building.

## What exists (state)

- **Claude Code adapter**: full — `PreToolUse`, `PostToolUse`, `Stop`, `SessionEnd`
- **Volva adapter**: `cortina adapter volva hook-event` — normalized hook events
  from volva forwarded through shared signal pipeline
- **Adapter boundary**: explicitly isolated; adding a new adapter does not touch
  the shared signal pipeline
- **Lamella skills/agents**: can wrap thin hook calls for environments that support
  custom hook configuration

## What needs doing (intent)

Evaluate whether Codex or Gemini tooling can be served by thin packaging (lamella
skills or hook wrappers) before committing to a full adapter. If thin packaging
suffices, document the pattern. If a full adapter is justified, implement it
following the Claude Code adapter as a template.

---

### Step 1: Evaluate Codex hook surface and document findings

**Project:** `cortina/`
**Effort:** 2–4 hours
**Depends on:** nothing

Determine whether Codex exposes lifecycle hooks that cortina can intercept:

1. Check Codex documentation for equivalent hook events (`PreToolUse`,
   `PostToolUse`, `Stop`/`SessionEnd`)
2. If hooks exist: determine if they can call an arbitrary command (like Claude
   Code hooks do) — if yes, a thin wrapper calling `cortina adapter codex
   hook-event <event>` may suffice
3. If no hooks: determine if stdin/stdout wrapping (like the volva pattern) can
   capture signals
4. Document findings in `cortina/docs/adapter-evaluation-codex.md`

Decision gate: if thin packaging covers >80% of signal capture, create a lamella
skill/hook wrapper instead of a full adapter. Only build a full adapter if Codex
has a rich enough hook surface that thin packaging would miss important signals.

#### Verification

```bash
# Document the findings
ls cortina/docs/adapter-evaluation-codex.md
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Codex hook surface documented
- [ ] Decision recorded: thin packaging vs. full adapter
- [ ] If thin packaging: lamella wrapper path documented
- [ ] If full adapter: proceed to Step 2

---

### Step 2: Implement thin lamella wrapper for Codex (if thin packaging path chosen)

**Project:** `lamella/`
**Effort:** 4–8 hours
**Depends on:** Step 1 (thin packaging decision)

If Step 1 determines thin packaging is sufficient, create lamella hooks for Codex:

- A session-end hook wrapper calling `cortina adapter codex hook-event SessionEnd`
- A post-tool hook wrapper (if Codex supports it)

Follow the same pattern as the cortina-delegating shim from the lamella boundary
cleanup handoff. The wrappers are thin — all business logic stays in cortina.

#### Files to modify

**`lamella/resources/hooks/codex-session-end.js`** — thin shim calling cortina

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Codex session-end shim validates
- [ ] Shim delegates to cortina adapter
- [ ] Shim exits 0 when cortina unavailable

---

### Step 3: Implement full Codex adapter (if full adapter path chosen)

**Project:** `cortina/`
**Effort:** 2–3 days
**Depends on:** Step 1 (full adapter decision)

If Step 1 determines a full adapter is justified, implement `cortina/src/adapters/codex/`
following the Claude Code adapter as a template:

1. Map Codex hook events to cortina's normalized `HookEvent` enum
2. Implement the same signal capture pipeline (errors, corrections, build/test,
   session lifecycle)
3. Add `cortina adapter codex hook-event <event>` CLI command
4. Wire into the shared `hyphae` and `canopy` signal bridge

#### Verification

```bash
cd cortina && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
cortina adapter codex hook-event --help 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Codex adapter implements the shared `Adapter` trait
- [ ] `cortina adapter codex hook-event` CLI command works
- [ ] Signals flow through hyphae and canopy bridge correctly
- [ ] Build and tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Step 1 evaluation is documented with a clear thin-vs-full decision
2. Either Step 2 OR Step 3 is implemented (based on Step 1 decision)
3. The chosen path is verified end-to-end
4. All checklist items for the chosen path are checked

### Final Verification

For thin packaging path:
```bash
cd lamella && make validate 2>&1 | tail -5
```

For full adapter path:
```bash
cd cortina && cargo test --workspace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** validate/tests pass for the chosen implementation path.

## Context

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsGap #22 in `docs/workspace/ECOSYSTEM-REVIEW.md`. Lowest priority gap. The cortina
roadmap explicitly gates this on proving need before building. Volva is the second
adapter and already shares the full signal pipeline — it covers the use case for
teams who want non-Claude-Code execution without a new adapter. Codex/Gemini
adapters only make sense if those environments have hook surfaces that can't be
served by thin lamella wrappers. Start with the evaluation (Step 1) before
committing to any implementation work.
