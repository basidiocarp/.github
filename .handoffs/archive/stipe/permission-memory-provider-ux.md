# Permission Memory and Provider UX

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** stipe/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Approvals and permissions in the ecosystem are ephemeral — each session starts fresh. Users who approved a tool operation last session approve it again next session. There is no persistent record of approval decisions that stipe or the host can consult at session start. Additionally, provider setup (API keys, MCP registration, host config) lacks a unified operator surface. Operators piece together configuration across environment variables, host config files, and per-tool config with no single place to inspect or repair provider state. ForgeCode, mempalace, and context-keeper all surface these patterns from the audit set.

## What exists (state)

- **Claude Code**: has its own permission model (`allowedTools` in settings.json) but it is host-local and not managed by stipe.
- **`stipe init`**: configures hosts but does not manage permission state or provider registration.
- **No persistent approval memory**: approval decisions do not survive sessions and are not stored by any ecosystem tool.
- **No unified provider surface**: `ANTHROPIC_API_KEY` and volva backend config are configured independently with no command to check combined status.

## What needs doing (intent)

Two independent pieces. First, check the archived handoff to understand what was already shipped for permission memory so this handoff only covers the remaining gap. Second, add a `stipe provider` subcommand that lists configured providers with status and walks through setup for a specific provider.

---

### Step 1: Review archived permission memory handoff scope

**Project:** workspace root
**Effort:** 30 min
**Depends on:** nothing

Before implementing, read the archived handoff to understand what was already shipped:

```
/Users/williamnewton/projects/basidiocarp/.handoffs/archive/stipe/permission-memory-and-runtime-policy.md
```

If the file does not exist, check the archive directory for any stipe-related entries covering permission memory or runtime policy.

Document what was shipped and what remains unaddressed. This step gates the remaining steps — only implement what was not already shipped.

#### Verification

```bash
ls /Users/williamnewton/projects/basidiocarp/.handoffs/archive/stipe/ 2>/dev/null || echo "no stipe archive"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Archive reviewed (or confirmed absent)
- [ ] Remaining permission memory gaps identified and noted here before proceeding

---

### Step 2: Add provider list and status surface

**Project:** `stipe/`
**Effort:** 1 day
**Depends on:** Step 1 (scope review confirms this is not already shipped)

Add `stipe provider list` to show configured providers with health status in a single output. This covers what `stipe doctor` surfaces at a higher level but gives operators a focused provider-specific view.

Output columns per provider:
- Provider name (Anthropic, Volva, per-registered MCP server)
- Status: `configured` / `missing` / `unexpected-format`
- API key: `present` / `not set` (never print the key value)
- Connection: `reachable` / `not reachable` / `not checked` (MCP servers only)

Secrets must never appear in output. Mask any key value with `***`.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5 && cargo test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe provider list` shows all configured providers with status
- [ ] API key presence reported, key value never printed
- [ ] MCP server reachability reported separately from key presence
- [ ] Build and tests pass

---

### Step 3: Add guided provider setup

**Project:** `stipe/`
**Effort:** 4-8 hours
**Depends on:** Step 2

`stipe provider setup <provider>` walks through configuration for a specific provider. Supported providers initially: `anthropic`, `volva`.

Anthropic setup:
- Prompt for API key if `ANTHROPIC_API_KEY` is not set
- Write to shell profile or `.env` file based on user preference
- Validate format (starts with `sk-ant-`)
- Confirm with `stipe provider list` output after setup

Volva setup:
- Check for existing volva backend config
- If missing, generate a default config at the expected path
- Print the config path and suggest next steps

The command must not overwrite existing config without confirming with the user. Non-interactive mode (`--yes`) accepts defaults for scripted setup.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5 && cargo test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe provider setup anthropic` prompts for key when not set
- [ ] `stipe provider setup volva` generates default config when missing
- [ ] Existing config not overwritten without user confirmation
- [ ] `--yes` flag enables non-interactive mode
- [ ] Build and tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/stipe/verify-permission-memory-provider-ux.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/stipe/verify-permission-memory-provider-ux.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete with failures.

## Context

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom synthesis DN-2. ForgeCode audit identifies permission memory as a first-class runtime policy feature and treats provider and MCP operator UX as product APIs rather than setup afterthoughts. Mempalace and context-keeper audits reinforce ephemeral approval state as a concrete operator pain point. Claurst and mem0 audits add provider normalization and health surfaces to the same cluster. Step 1 gates on the archived handoff to prevent duplicating already-shipped work.
