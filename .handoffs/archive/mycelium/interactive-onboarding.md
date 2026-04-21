# Interactive Ecosystem Onboarding

## Problem

`mycelium init` used to be non-interactive for first-run setup. New users had no guided flow to configure the ecosystem (hyphae memory, rhizome code intelligence, cap dashboard). `hyphae_onboard` and `rhizome_onboard` MCP tools existed but weren't surfaced in a coherent first-run experience.

## What exists (state)

- **`mycelium/src/init/onboard.rs`**: interactive onboarding now exists and drives host-aware setup
- **`hyphae_onboard` MCP tool**: exists in hyphae-mcp
- **`rhizome_onboard` MCP tool**: exists in rhizome-mcp
- **Cap**: no `/onboard` page

## What needs doing (intent)

Add `mycelium init --onboard` interactive wizard that walks through: detect installed tools → configure MCP servers → store first memory → scan code with rhizome → show summary. Optional cap onboard page.

---

### Step 1: Add `--onboard` flag and wizard flow to mycelium

**Project:** `mycelium/`
**Effort:** 2-3 hours
**Depends on:** nothing

Add `--onboard` flag to `mycelium init`. Implement a step-by-step wizard:
1. Detect which tools are installed (hyphae, rhizome, cap)
2. Configure MCP servers using the existing host-aware init/setup helpers
3. Prompt to store a first memory: "What are you working on today?"
4. Offer to scan the current directory with rhizome (`rhizome summarize`)
5. Print a summary of what was configured

Keep prompts skippable (Ctrl+C exits cleanly). Use `colored` (already a dep) for output.

#### Verification

```bash
cd mycelium && echo -e "y\ny\ny\ny\ny" | ./target/debug/mycelium init --onboard 2>&1 | tail -20
cargo test && cargo clippy && cargo fmt --check
```

**Output:**
<!-- PASTE START -->
- `cargo test` passed in `mycelium`
- `cargo clippy --all-targets --all-features -- -D warnings` passed
- `mycelium init --onboard` smoke run completed in an isolated home dir
<!-- PASTE END -->

**Checklist:**
- [x] `mycelium init --onboard` runs without error
- [x] Each step is skippable / non-blocking
- [x] Calls the existing init/setup helpers for MCP and host configuration
- [x] Exits cleanly on Ctrl+C
- [x] Build, test, clippy, fmt pass

---

### Step 2: Cap onboard stepper page (optional)

**Project:** `cap/`
**Effort:** 2 hours
**Depends on:** Step 1

Add a `/onboard` route in cap showing a step-by-step checklist: ecosystem configured, first memory stored, rhizome scan complete. Links to relevant cap views on completion. Shown automatically when `~/.config/basidiocarp/onboarded` does not exist.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->
- `npm run build` passed in `cap`
- `/onboard` route shipped and renders the completion checklist flow
<!-- PASTE END -->

**Checklist:**
- [x] `/onboard` route renders without errors
- [x] Shows completion checklist with 3+ steps
- [x] `npm run build` passes

---

## Completion Protocol

1. All step verification output pasted
2. `cd mycelium && cargo test` passes
3. `mycelium init --onboard` completes without error

## Context

From `.plans/interactive-onboarding.md` and `.plans/priority-phase-4.md` Plan 16. Complements agent-agnostic work — onboarding should work for Codex and Cursor users too, not just Claude Code.
