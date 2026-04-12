# Annulus: Cross-Ecosystem Utilities

Small Rust crate for lightweight operator-facing utilities that are cross-cutting
by nature and don't belong in any single existing tool.

## Why a New Tool

The New Tool Bar from ECOSYSTEM-OVERVIEW.md asks three questions:

1. **Is the responsibility stable and first-class?** Yes. Operator-facing
   cross-cutting utilities are a distinct surface — not signal capture, not
   memory storage, not packaging. The need is stable.

2. **Does it fit an existing tool?** No. Statusline isn't lifecycle capture
   (cortina). Hook path validation isn't content packaging (lamella). Training
   data export isn't primary memory work (hyphae). Each of these is currently
   in the wrong home.

3. **Do more than one repos benefit?** Yes. Cortina sheds statusline, lamella
   sheds hook validation, hyphae sheds training export. Three repos get cleaner
   boundaries from a single seam.

The name follows the mycology convention: the annulus is the small structural
ring on a mushroom stipe that connects pieces without being a major organ.

## Confirmed Utilities

### Statusline

**What it does:** Renders a two-line operator status bar showing context usage,
token counts, session cost, model name, git branch, mycelium savings, and
(when available) hyphae health and canopy task state.

**Where it lives today:** `cortina/src/statusline.rs`. It doesn't belong there
because cortina is a signal capture pipeline. Statusline is an operator display
surface — it reads data, it doesn't capture events.

**What changes:** Moves to `annulus`. Refactored to read from ecosystem tools
directly rather than cortina internals. Becomes segment-based and
discovery-driven. Gains config support.

### Hook Path Validator

**What it does:** Reads `~/.claude/settings.json` (and other host configs),
checks that every registered hook path exists and points to a valid executable,
and reports stale, missing, or broken entries.

**Where it lives today:** Assigned to lamella (handoff #70). Lamella authors
hooks — it shouldn't also be the validator. Validation is a cross-cutting
operator concern that needs to work regardless of which hooks came from lamella,
stipe, or user-written scripts.

**What changes:** Lands in annulus as `annulus validate-hooks`. Output format is
suitable for both direct use and piped into `stipe doctor`.

### Training Data Export (Future Resident)

**What it does:** Reads hyphae's SQLite database and reformats session and
correction records into SFT, DPO, or Alpaca format for fine-tuning workflows.

**Where it lives today:** Frozen inside hyphae as a deferred feature. Belongs
here if/when fine-tuning becomes a real workflow, because hyphae is the storage
layer, not the export surface.

**What changes:** Not built yet. Documented here so the right home is clear when
the time comes.

## Statusline Design

### Agent-agnostic

Statusline reads from ecosystem tools directly — git CLI, mycelium's SQLite db,
hyphae's SQLite db, canopy's state, volva's status endpoint — not from cortina
internals or from Claude Code-specific data. The same binary works unchanged
regardless of whether the operator is using Claude Code, volva, Codex, or
Cursor.

### Segment-based architecture

Each data source is an independent segment:

| Segment | Source | Shows |
|---------|--------|-------|
| `context` | transcript path (stdin) | context %, input/output/cache tokens, cost |
| `git` | `git rev-parse` | branch name, dirty state |
| `mycelium` | mycelium SQLite history.db | tokens saved this session |
| `hyphae` | hyphae SQLite | memory health, active session indicator |
| `canopy` | canopy state files | active agents, open task count |
| `volva` | volva status probe | backend status |
| `model` | transcript or stdin | compact model name |

### Discovery-driven

Annulus uses spore discovery to detect which tools are installed. A segment only
renders if the data source is available. A user with only mycelium and hyphae
sees token savings and memory health. A canopy user sees active agents and task
counts. Missing tools produce no output rather than errors.

### Configurable

Segment ordering, format strings, and color themes are controlled via
`~/.config/annulus/config.toml`. Defaults give the current cortina statusline
appearance. Users can reorder segments, disable segments, or change colors.

**Minimal install (mycelium only):**
```
ctx: ▲ 42% │ in: 45.0K • out: 12.0K • cache: 89.0K │ $1.23
sonnet 4.6 │ ↓8.2K saved │ git: main │ ws: basidiocarp
```

**Full install (mycelium + hyphae + canopy + volva):**
```
ctx: ▲ 42% │ in: 45.0K • out: 12.0K • cache: 89.0K │ $1.23
sonnet 4.6 │ ↓8.2K saved │ mem: healthy │ agents: 2 │ tasks: 5 open │ backend: ok │ git: main
```

### Multi-host

Because statusline reads from stable data sources (SQLite files, git, spore
paths) rather than from any host's internal state, it works with Claude Code,
volva, Codex, and Cursor equally. Host-specific data (transcript path, model
name) is passed via stdin JSON if available, matching cortina's current
interface.

## Crate Structure

Single crate, one binary. Not a workspace — these utilities are small and don't
need separate release cadence.

```text
annulus/
├── Cargo.toml
└── src/
    ├── main.rs          CLI entry, subcommand dispatch
    ├── statusline.rs    segment rendering and composition
    ├── segments/        one file per data-source segment
    │   ├── context.rs
    │   ├── git.rs
    │   ├── mycelium.rs
    │   ├── hyphae.rs
    │   ├── canopy.rs
    │   └── volva.rs
    ├── config.rs        config file loading and defaults
    └── validate_hooks.rs hook path validation
```

## Integration Points

- **spore**: tool discovery and shared path resolution for segment data sources
- **mycelium, hyphae, canopy, volva**: read via CLI probes or direct SQLite/file
  access using spore path resolution
- **git**: read via `git rev-parse` and `git status --short`
- **stipe**: installs and manages the annulus binary; `stipe doctor` can consume
  `annulus validate-hooks` output
- **cap**: could read statusline segment data via a structured output mode if the
  dashboard needs it — add a septa contract at that point

## What Does Not Belong in Annulus

The surface is narrow by design:

- Not a home for anything that is merely "cross-cutting" — that bar is not enough
- Signal capture, normalization, event pipelines: those are cortina
- Memory storage or retrieval: those are hyphae
- Build tooling, workspace scripts, CI helpers: those belong in the owning repo
- Host setup or injection: those are stipe
- Packaged prompts, hooks, or skills: those are lamella

If a proposed addition doesn't fit that short list of operator-facing display or
validation utilities, it belongs somewhere else.

## Future Residents

**Training data export** is the most likely next addition. The trigger: a
working fine-tuning workflow exists and hyphae's session and correction data is
actually being used to train. At that point, move the export command here as
`annulus export-training-data`.

**The bar for adding to annulus**: small, operator-facing, read-only or
diagnostic, doesn't fit any existing tool, and genuinely cross-cutting (multiple
tools are its data sources or its consumers). If a utility only touches one
tool's data, it belongs in that tool.

## Related

- [platform-layer-model.md](./platform-layer-model.md) — six-layer model; annulus
  contributes to the Authoring / Operator Surface layer
- [harness-overview.md](./harness-overview.md) — end-to-end harness model
- [ECOSYSTEM-OVERVIEW.md](../workspace/ECOSYSTEM-OVERVIEW.md) — repo
  responsibilities and New Tool Bar criteria
