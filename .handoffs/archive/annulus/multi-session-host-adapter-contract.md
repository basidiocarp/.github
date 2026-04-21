# Multi-Session Host Adapter Contract

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** `annulus/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** implementing the host adapter hooks (cortina/lamella concern); changes to the provider code (covered by #141); septa schema changes (the stdin JSON is a host-to-annulus protocol, not a cross-tool payload)
- **Verification contract:** run the repo-local commands below and `bash .handoffs/annulus/verify-multi-session-host-adapter-contract.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `annulus`
- **Likely files/modules:** `README.md` or `docs/` — stdin JSON schema documentation and example hook snippets
- **Reference seams:** Claude Code's native statusline protocol (pipes JSON to stdin with `transcript_path`, `model`, `workspace`); Codex `sessions/YYYY/MM/DD/<id>.jsonl` layout; Gemini `~/.gemini/tmp/<uuid>.json` layout
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

After #141 adds session-scoped provider resolution, annulus will accept `provider` and `session_path` from stdin JSON. But there is no documentation of what host adapters should pass or how to configure hooks for Codex and Gemini to pipe session identity to annulus. Without this, the session-scoping capability exists but is unusable for non-Claude hosts.

Claude Code natively passes `transcript_path` — no adapter needed. Codex and Gemini hosts need hook scripts that:
1. Determine the current session file path
2. Pipe JSON to annulus with `provider`, `session_path`, and optionally `model`

## What exists (state)

- **Claude Code integration:** Claude Code natively passes `{"transcript_path": "...", "model": {...}, "workspace": {...}}` to the statusline hook's stdin. This works without any adapter.
- **Codex hook gap:** No documented mechanism for a Codex hook to discover the current session's JSONL file path and pipe it to annulus.
- **Gemini hook gap:** Same — no documented mechanism for Gemini CLI hooks.
- **Codex session layout:** `$CODEX_HOME/sessions/YYYY/MM/DD/<id>.jsonl` (or `$CODEX_HOME/archived_sessions/<id>.jsonl`). The current session file is the one being written to during the active session.
- **Gemini session layout:** `$GEMINI_HISTORY_DIR/<uuid>.json` (or `~/.gemini/tmp/<uuid>.json`). The current session file is the one being written to during the active session.

## What needs doing (intent)

1. Document the extended stdin JSON schema that annulus accepts (after #141), including the new `provider` and `session_path` fields alongside the existing `transcript_path`, `model`, and `workspace` fields.
2. Document how Codex hooks can discover the current session file path (e.g., `$CODEX_SESSION_FILE` env var if Codex sets one, or the most recent file in the session directory at hook invocation time).
3. Document how Gemini hooks can discover the current session file path.
4. Provide example hook snippets that pipe the right JSON to `annulus statusline`.
5. Document the precedence chain: stdin `provider` > config `provider` > auto-detect by recency.

## Scope

- **Primary seam:** annulus documentation — README section or `docs/` file
- **Allowed files:** `annulus/README.md`, `annulus/docs/`
- **Explicit non-goals:**
  - Do not implement the hooks themselves (cortina/lamella concern)
  - Do not change provider code (covered by #141)
  - Do not add this to septa — the stdin JSON is a host-to-annulus protocol, not a multi-tool contract

---

### Step 1: Document stdin JSON schema

**Project:** `annulus/`
**Effort:** 0.25 day
**Depends on:** #141 (Session-Scoped Provider Resolution)

Document the full stdin JSON schema that `annulus statusline` accepts:

```json
{
  "provider": "codex",
  "session_path": "/path/to/current/session.jsonl",
  "transcript_path": "/path/to/claude/transcript.jsonl",
  "model": { "display_name": "gpt-4.1" },
  "workspace": { "current_dir": "/home/user/project" }
}
```

Field semantics:
- `provider` (optional): explicit provider name, overrides config and auto-detect
- `session_path` (optional): path to the active session file for Codex or Gemini
- `transcript_path` (optional): path to the Claude transcript file (Claude-specific, kept for backward compat)
- `model` (optional): model display name for the statusline
- `workspace` (optional): current working directory for git branch detection

#### Verification

```bash
cd annulus && grep -q "session_path" README.md 2>&1 || grep -rq "session_path" docs/ 2>&1
```

**Checklist:**
- [ ] Full stdin JSON schema is documented with all fields
- [ ] Each field has clear semantics and optionality documented
- [ ] Precedence chain is documented (stdin provider > config provider > auto-detect)

---

### Step 2: Document host adapter patterns and example hooks

**Project:** `annulus/`
**Effort:** 0.25 day
**Depends on:** Step 1

Provide example hook snippets for each host:

**Claude Code** — already works natively, document that no adapter is needed.

**Codex** — example bash hook that:
1. Finds the current session file (most recent in `$CODEX_HOME/sessions/`)
2. Pipes JSON with `provider: "codex"` and `session_path` to `annulus statusline`

**Gemini** — example bash hook that:
1. Finds the current session file (most recent in `$GEMINI_HISTORY_DIR` or `~/.gemini/tmp/`)
2. Pipes JSON with `provider: "gemini"` and `session_path` to `annulus statusline`

Document the limitations: if the host CLI does not expose a session file path via env var, the hook must infer it from the most recent file at invocation time. This is a best-effort match that breaks only if two sessions write to the same directory within the same second.

#### Verification

```bash
cd annulus && grep -q "codex" README.md 2>&1 || grep -rq "codex.*hook\|hook.*codex" docs/ 2>&1
cd annulus && grep -q "gemini" README.md 2>&1 || grep -rq "gemini.*hook\|hook.*gemini" docs/ 2>&1
```

**Checklist:**
- [ ] Claude Code integration documented as native (no adapter needed)
- [ ] Codex example hook snippet included
- [ ] Gemini example hook snippet included
- [ ] Session file discovery limitations documented
- [ ] Multi-session scenario (two Codex terminals) addressed

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/annulus/verify-multi-session-host-adapter-contract.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/annulus/verify-multi-session-host-adapter-contract.sh
```

## Context

Source: user report — multi-CLI / multi-session statusline support. This is the documentation companion to #141 (Session-Scoped Provider Resolution), which adds the code support. Without this documentation, Codex and Gemini hosts cannot use the new session-scoping capability.

Related handoffs: #141 Annulus Session-Scoped Provider Resolution (prerequisite — adds the code support this documents); #129 Annulus Flag-File State Bridge (complementary — bridge is for external state, this is for session identity).
