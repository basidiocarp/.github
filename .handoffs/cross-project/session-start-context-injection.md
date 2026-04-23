# Cross-Project: Session-Start Context Injection (Baseline Mode)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** stipe (deploys hooks); lamella (defines hook content); hyphae (provides context)
- **Allowed write scope:** `~/.claude/settings.json` hook addition; `~/.claude/hooks/scripts/session-start.js` (create); lamella hook template update
- **Cross-repo edits:** lamella/resources/hooks/settings.json (template update to match deployed reality)
- **Non-goals:** changing how hyphae stores memories; changing volva's prompt assembly; this only covers the non-volva baseline session path
- **Verification contract:** opening a new Claude Code session results in hyphae recall context appearing in the first turn without any manual action
- **Completion update:** update dashboard when session-start hook is deployed and verified

## Context

Two findings from the audit:

**Finding 1 — No SessionStart hook is deployed.** The lamella `settings.json` template defines three `SessionStart` hooks (claudemd-scanner, mycelium-baseline, session-start.js). None of them are in the live `~/.claude/settings.json`. The deployed hooks are cortina-only. This means when a session starts without volva, hyphae recall is never automatically injected.

**Finding 2 — The referenced hook scripts don't exist.** The template references `$HOME/.claude/hooks/scripts/session-start.js` and `$HOME/.claude/hooks/mycelium-baseline.sh` but `~/.claude/hooks/` is empty. Stipe has not deployed these scripts.

The global rule `~/.claude/rules/hyphae-context.md` does instruct agents to search hyphae manually. But a rule that says "you should call hyphae" is weaker than a SessionStart hook that automatically calls it and injects the result. The hook model removes the dependency on the agent remembering to comply.

## Implementation Seam

- **Likely repo:** stipe (the deploy mechanism); lamella (the hook source)
- **Likely files:** 
  - `~/.claude/settings.json` (add SessionStart hook)
  - `~/.claude/hooks/scripts/session-start.js` (create this script)
  - `lamella/resources/hooks/settings.json` (update template to match deployed state)
- **Reference seams:** the cortina hooks already in `~/.claude/settings.json` are the pattern to follow
- **Spawn gate:** read `stipe/src/commands/init/` to understand how stipe deploys hooks before touching `~/.claude/settings.json` manually

## Problem

Without a SessionStart hook, every non-volva session starts cold — no prior context from hyphae, no memory of decisions from previous sessions. The hyphae MCP tools are available but nothing calls them. Agents rely entirely on their own context window for knowledge that should come from hyphae.

The two modes should work as follows:
- **Without volva**: SessionStart hook calls hyphae, injects recall context via system prompt injection (limited to ~500 tokens, project-scoped)
- **With volva**: volva's `assemble_prompt()` does the same thing but with a larger budget (2000+ tokens) and access to the full memory protocol surface

Both modes should get hyphae recall. They differ in budget and richness, not in whether recall happens at all.

## What needs doing (intent)

1. Create `~/.claude/hooks/scripts/session-start.js` — a lightweight script that:
   - Detects the current project directory
   - Calls `hyphae gather-context --project <project> --budget 500` (or equivalent)
   - Injects the result as a system prompt addition

2. Add a `SessionStart` hook to `~/.claude/settings.json` that calls this script

3. Update the lamella `settings.json` template to reflect the deployed state (currently the template has hooks pointing to scripts that don't exist — the template and deployed reality are out of sync)

4. Understand the stipe deployment model so that future installs deploy this hook automatically instead of requiring manual editing

## Scope

- **Primary seam:** SessionStart hook → hyphae context injection (baseline mode)
- **Allowed files:** `~/.claude/settings.json`, `~/.claude/hooks/scripts/session-start.js`, `lamella/resources/hooks/settings.json`
- **Explicit non-goals:** changing volva's prompt assembly; changing hyphae's storage model; changing the hook budget for volva sessions

---

### Step 1: Investigate stipe's hook deployment model

**Project:** stipe
**Effort:** 30-60 min
**Depends on:** nothing

Before touching `~/.claude/settings.json` manually, understand how stipe is supposed to deploy hooks:
- Read `stipe/src/commands/init/` — does stipe write to `~/.claude/settings.json`? Does it deploy scripts to `~/.claude/hooks/`?
- Read `stipe/src/commands/` for any hook-related command (`stipe hooks install`, `stipe init hooks`, etc.)

Answer: should the SessionStart hook be added by stipe (and this handoff adds it to stipe's install path), or is `~/.claude/settings.json` managed manually?

#### Verification

```bash
grep -rn "settings.json\|hooks\|\.claude" stipe/src/commands/ | grep -v "\.cargo\|target/" | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Stipe hook deployment model understood
- [ ] Decision made: stipe-managed vs. manual

---

### Step 2: Create session-start.js

**Project:** stipe or lamella (depending on Step 1 finding)
**Effort:** 1-2 hours
**Depends on:** Step 1

Create `session-start.js`. This script runs at session start and injects hyphae recall context.

```javascript
#!/usr/bin/env node
// Baseline session-start hook — injects hyphae recall context
// Runs at SessionStart without volva. Budget is intentionally limited
// (volva uses a larger budget when it assembles the system prompt directly).

const { execSync } = require('child_process');
const path = require('path');

const BUDGET = 500; // tokens — small but enough for recent errors and decisions
const PROJECT = path.basename(process.cwd());

let recallContext = null;

try {
  const output = execSync(
    `hyphae recall --project "${PROJECT}" --budget ${BUDGET} --format text`,
    { timeout: 3000, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] }
  );
  if (output && output.trim()) {
    recallContext = output.trim();
  }
} catch {
  // hyphae unavailable — proceed without recall, do not block session start
}

// Always inject mode signal so agents know what's available.
// This fires whether or not hyphae has recall context.
// Agents in a non-volva session should not attempt canopy or hymenium operations.
const MODE_SIGNAL = `[mode: baseline — mycelium, hyphae, and rhizome are active; canopy and hymenium are not available in this session]`;

const content = recallContext
  ? `${MODE_SIGNAL}\n\n[hyphae-session-recall: project=${PROJECT}]\n${recallContext}`
  : MODE_SIGNAL;

// Inject into Claude Code as a system prompt addition
// (Claude Code reads stdout from SessionStart hooks as context to inject)
process.stdout.write(JSON.stringify({
  type: 'system',
  content
}));
```

**Important:** Verify the exact protocol Claude Code uses for SessionStart hook output before finalizing this. Read the Claude Code documentation or test with a minimal hook to confirm the injection mechanism.

#### Verification

```bash
# Test the script in isolation (with hyphae running)
node session-start.js
# Should output JSON or nothing (if no memories)
# Should NOT throw an error if hyphae is unavailable

# Simulate hyphae unavailable
HYPHAE_DISABLED=1 node session-start.js
# Should exit cleanly with no output
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Script runs cleanly with hyphae available
- [ ] Script exits cleanly when hyphae is unavailable (no error, no hang)
- [ ] Output always includes `[mode: baseline]` signal regardless of hyphae availability
- [ ] Output format matches Claude Code's SessionStart injection protocol
- [ ] Budget respected (output is bounded)

---

### Step 3: Add SessionStart hook to ~/.claude/settings.json

**Project:** stipe or manual (per Step 1)
**Effort:** 30 min
**Depends on:** Step 2

Add the SessionStart hook to the live settings:

```json
"SessionStart": [
  {
    "matcher": "*",
    "hooks": [
      {
        "type": "command",
        "command": "node \"$HOME/.claude/hooks/scripts/session-start.js\"",
        "timeout": 5
      }
    ]
  }
]
```

If stipe owns this, add it to stipe's init/install path so it deploys on `stipe init` or `stipe hooks install`. If manual, edit `~/.claude/settings.json` directly.

#### Verification

```bash
# Confirm SessionStart hook is present
cat ~/.claude/settings.json | python3 -c "
import sys, json
d = json.load(sys.stdin)
hooks = d.get('hooks', {})
ss = hooks.get('SessionStart', [])
print(f'SessionStart hooks: {len(ss)}')
for h in ss:
    for hook in h.get('hooks', []):
        print(' ', hook.get('command', '?'))
"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] SessionStart hook present in `~/.claude/settings.json`
- [ ] Script path resolves correctly
- [ ] Timeout is set (5s max — session start should not block)

---

### Step 4: Update lamella hooks template

**Project:** lamella
**Effort:** 30 min
**Depends on:** Step 3

Update `lamella/resources/hooks/settings.json` to match deployed reality:
- Remove or stub the scripts that don't exist yet (claudemd-scanner, mycelium-baseline)
- Add the session-start.js hook that now exists
- Add a comment marking each hook as `deployed` vs `template-only`

This keeps the template as a reliable source of truth for what `stipe hooks install` should deploy.

#### Verification

```bash
cd lamella && make validate
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] lamella validate passes
- [ ] Template reflects deployed state

---

## Completion Protocol

1. `session-start.js` exists at `~/.claude/hooks/scripts/session-start.js`
2. `SessionStart` hook present in `~/.claude/settings.json`
3. Opening a new session in this repo produces `[mode: baseline]` signal in the first turn, always
4. Opening a new session produces hyphae recall context when memories exist for the project
5. Script degrades gracefully when hyphae is unavailable — mode signal still injects, no hang, no error
6. lamella template updated to reflect deployed state
7. Dashboard updated

### Final Verification

```bash
bash .handoffs/cross-project/verify-session-start-context-injection.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->
