# [Tool]

<!-- One sentence. What it does and why that matters. No fluff.
     Good: "Token-optimized CLI proxy. Filters and compresses command output before it reaches your LLM context."
     Bad:  "A powerful new tool for optimizing your AI coding workflow." -->
[One-line value proposition.]

<!-- Named after line. Keep it tight — one clause explaining the metaphor.
     The name should connect to the tool's actual behavior, not just sound cool.
     Good: "Named after fungal spores—lightweight carriers of information between separate organisms."
     Good: "Named after the fungal cortina—a veil between the cap and stipe that intercepts what passes between them."
     Bad:  "Named after [thing] because it's cool and fungal." -->
Named after [fungal structure]—[what it does in the fungal world, connected to what the tool does].

Part of the [Basidiocarp ecosystem](https://github.com/basidiocarp).

---

## The Problem

<!-- One short paragraph. State the pain directly. No hedging.
     Good: "AI agents forget everything between sessions. Architecture decisions, resolved bugs, project conventions—all lost when the context window compacts."
     Bad:  "Many developers find that AI tools could be improved in various ways..." -->
[What breaks or is missing without this tool. Be specific.]

## The Solution

<!-- Two to four sentences or a short bullet list. Map directly onto the problem above.
     If the solution has two distinct modes or models, describe each one. -->
[What this tool provides. How it solves the problem above.]

---

## The Ecosystem

<!-- Standard ecosystem table. Include all first-party tools.
     Keep descriptions to one clause each. -->
| Tool | Purpose |
|------|---------|
| **[[Tool]](https://github.com/basidiocarp/[tool])** | [This tool] (this project) |
| **[mycelium](https://github.com/basidiocarp/mycelium)** | Token-optimized command output |
| **[hyphae](https://github.com/basidiocarp/hyphae)** | Persistent agent memory |
| **[rhizome](https://github.com/basidiocarp/rhizome)** | Code intelligence via tree-sitter and LSP |
| **[canopy](https://github.com/basidiocarp/canopy)** | Multi-agent coordination runtime |
| **[cap](https://github.com/basidiocarp/cap)** | Web dashboard for the ecosystem |
| **[lamella](https://github.com/basidiocarp/lamella)** | Skills, hooks, and plugins for Claude Code |
| **[stipe](https://github.com/basidiocarp/stipe)** | Ecosystem installer and manager |

<!-- Ownership note: call out what this tool owns vs. what it defers to siblings.
     Only include if there's a real boundary worth stating — e.g. Cortina defers
     lifecycle setup to Stipe, Spore defers ecosystem policy to Stipe.
     Skip this block for tools with no meaningful overlap. -->
> **Boundary:** `[Tool]` owns [X]. `stipe` owns [Y]. `[sibling]` owns [Z].

---

## Quick Start

```bash
# Recommended: full ecosystem setup
curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh
stipe init
```

<!-- Tool-specific install path for users who only want this tool. -->
```bash
# [Tool]-only install
cargo install --git https://github.com/basidiocarp/[tool]

# Or build from source
cargo build --release
```

<!-- First commands a new user should run. Show expected output where it helps.
     Don't over-explain — the commands should be self-evident. -->
```bash
[tool] init       # configure for detected editors
[tool] doctor     # verify setup
[tool] [command]  # first meaningful action
```

---

## How It Works

<!-- ASCII flow diagram or mermaid block. Required for tools with non-obvious data flow.
     Keep it narrow — max ~60 chars wide so it renders in terminals and narrow viewports.
     ASCII is preferred over mermaid for tools aimed at CLI users.

     Example (Cortina):
     Claude Code              Cortina                   Ecosystem
     ──────────               ───────                   ─────────
     PreToolUse  ──stdin──►   Claude adapter   ──►      Hyphae store
     PostToolUse ──stdin──►   Claude adapter   ──►      Session summary
     SessionEnd  ──stdin──►   Claude adapter   ──►      Rhizome export -->

```
[Flow diagram showing input → this tool → output / downstream effects]
```

<!-- Short numbered list of what the tool actually does, in order.
     Use verb phrases. Three to six items is the right range. -->
1. **[First thing]** — [what and why]
2. **[Second thing]** — [what and why]
3. **[Third thing]** — [what and why]

---

## [Core Feature or Value Metric]

<!-- Use a table when the value can be expressed in concrete numbers or structured comparisons.
     Mycelium's savings table is the gold standard — frequency × before × after × delta.
     Rhizome's language support table is the right model for capability matrices.
     Skip this section if the value doesn't reduce to something tabular. -->

| [Dimension] | [Before / Without] | [[Tool]] | [Delta / Savings] |
|-------------|-------------------|----------|-------------------|
| [Example A] | [Metric]          | [Metric] | [−X%]             |
| [Example B] | [Metric]          | [Metric] | [−X%]             |
| **Total**   | **[N]**           | **[N]**  | **[−X%]**         |

---

## What [Tool] Owns

<!-- Required for tools with non-obvious scope boundaries.
     Especially important when a tool could be confused with a sibling.
     If the scope is obvious from the name and tagline, skip this section. -->
- [Responsibility A]
- [Responsibility B]
- [Responsibility C]

## What [Tool] Does Not Own

<!-- Mirror of the above. Call out what belongs to siblings.
     This prevents users from filing the wrong issue and prevents scope creep. -->
- [Concern X] — handled by `[sibling]`
- [Concern Y] — handled by `[sibling]`
- [Concern Z] — handled by `[sibling]`

---

## Key Features

<!-- Bullet list or short table.
     Lead each entry with the feature name in bold, then one clause of explanation.
     Don't describe behavior the name already implies. -->
- **[Feature A]** — [what makes it worth calling out]
- **[Feature B]** — [what makes it worth calling out]
- **[Feature C]** — [what makes it worth calling out]

---

## Architecture

<!-- ASCII box diagram showing crate/module structure.
     Hyphae's tree and Rhizome's layered box are both good models.
     Include the binary count and tool count if they're worth surfacing. -->

```
[tool] (single binary)
├── [tool]-core      [types, traits, shared logic — no I/O]
├── [tool]-[module]  [description]
├── [tool]-[module]  [description]
└── [tool]-cli       [CLI entry point]
```

<!-- Optional: CLI command reference if the surface is small enough to list here.
     If the surface is large, link to a dedicated reference doc instead. -->

```
[tool] [command] [flags]   [description]
[tool] [command] [flags]   [description]
[tool] doctor              diagnose configuration issues
[tool] self-update         check for and apply updates
```

---

## Configuration

<!-- Only include if the tool has meaningful config. Show the actual file path and format.
     A minimal real example beats a comprehensive abstract one. -->

```toml
# [platform config dir]/[tool]/config.toml

[section]
key = "value"
```

---

## Performance

<!-- Include only if you have real numbers.
     Latency table or throughput numbers go here.
     Don't include "fast" or "lightweight" claims without backing data. -->

| Operation | Latency |
|-----------|---------|
| [Op A]    | [N µs]  |
| [Op B]    | [N ms]  |

---

## Documentation

<!-- Link to every doc file in docs/. Keep descriptions to one clause.
     Hyphae's docs index is the right model. -->
- [COMMANDS.md](docs/COMMANDS.md) — [what it covers]
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — [what it covers]
- [troubleshooting.md](docs/operate/troubleshooting.md) — [what it covers]

---

## Development

```bash
cargo build --release
cargo test
cargo clippy
cargo fmt
```

## License

MIT
