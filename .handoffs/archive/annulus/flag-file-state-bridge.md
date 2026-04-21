# Flag-File State Bridge

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** `annulus/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** hook content authoring (lamella/cortina), IPC mechanisms, or statusline segment design beyond the bridge reader
- **Verification contract:** run the repo-local commands below and `bash .handoffs/annulus/verify-flag-file-state-bridge.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `annulus`
- **Likely files/modules:** new `src/bridge.rs` or within `src/statusline.rs`; `src/config.rs` for bridge path configuration
- **Reference seams:** caveman `hooks/caveman-mode-tracker.js:13-56` for the writer pattern; `hooks/caveman-statusline.sh:11-19` for the reader pattern
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Annulus surfaces statusline badges but has no defined mechanism for hooks or external tools to communicate mode or badge state to the statusline reader. Currently, statusline segments must probe tools directly. Caveman demonstrates a simple, working alternative: a flag file at a well-known path that hooks write to and the statusline reads from. Three components — a writer hook, an updater hook, and a reader — stay fully decoupled via one flat file. No IPC, no shared process, no socket.

## What exists (state)

- **`annulus`:** reads from ecosystem tools via CLI probes or direct file access for each segment
- **No bridge spec:** there is no documented mechanism for external state to reach the statusline without a tool probe
- **caveman reference:** `~/.claude/.caveman-active` file written by hooks, read by the statusline script

## What needs doing (intent)

1. Define a bridge file spec: a well-known path (e.g., `~/.config/annulus/bridge.json` or similar) with a documented schema for key-value state entries.
2. Implement a bridge reader in annulus that reads the file and exposes state entries as statusline segment data.
3. Document the writer contract: what hooks or tools should write to the bridge file, what format, and how staleness is detected (e.g., mtime check, TTL field).
4. Add a statusline segment that renders bridge state (e.g., active mode badges).

## Scope

- **Primary seam:** flag-file reader in annulus and documented writer contract
- **Allowed files:** `annulus/src/` bridge reader and statusline modules
- **Explicit non-goals:**
  - Do not implement the writer hooks (cortina/lamella concern)
  - Do not build IPC or socket-based alternatives
  - Do not change existing segment architecture

---

### Step 1: Define bridge file spec and reader

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** nothing

Define the bridge file path and schema. Implement a reader that:
- Reads the file if present
- Parses key-value state entries
- Checks staleness (mtime or TTL)
- Returns empty state if the file is missing, unreadable, or stale

#### Verification

```bash
cd annulus && cargo check 2>&1
cd annulus && cargo test bridge 2>&1
```

**Checklist:**
- [ ] Bridge file path is well-defined and configurable
- [ ] Schema is documented (in code comments or a README section)
- [ ] Missing/unreadable/stale file returns empty state, not an error
- [ ] Reader has unit tests

---

### Step 2: Add bridge statusline segment

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** Step 1

Add a statusline segment that renders badge or mode state from the bridge file. The segment follows the existing segment trait pattern: it renders nothing if no bridge state is available.

#### Verification

```bash
cd annulus && cargo test statusline 2>&1
cd annulus && cargo test 2>&1
cd annulus && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Bridge segment renders state when bridge file has entries
- [ ] Bridge segment renders nothing when bridge file is absent or empty
- [ ] Segment follows existing segment trait pattern
- [ ] No new clippy warnings

---

### Step 3: Document writer contract

**Project:** `annulus/`
**Effort:** 0.25 day
**Depends on:** Step 1

Document the bridge file contract in annulus's README or a dedicated doc: what path, what schema, how to write entries, staleness semantics, and an example hook snippet showing how cortina or lamella hooks would write to the bridge.

#### Verification

```bash
cd annulus && grep -q "bridge" README.md 2>&1 || grep -rq "bridge" docs/ 2>&1
```

**Checklist:**
- [ ] Writer contract is documented with path, schema, and example
- [ ] Staleness semantics are described
- [ ] Example hook snippet is included

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/annulus/verify-flag-file-state-bridge.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/annulus/verify-flag-file-state-bridge.sh
```

## Context

Source: caveman ecosystem borrow audit (2026-04-14) sections "Flag-file state bridge" and "Annulus lacks a concrete flag-file bridge spec." See `.audit/external/audits/caveman-ecosystem-borrow-audit.md`.

Related handoffs: archived Annulus Degradation Status Surfaces, #114db Annulus Tool Adoption Statusline. The bridge gives annulus a general mechanism to receive external state that those segments can also use.
