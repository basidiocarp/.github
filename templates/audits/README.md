# Audit Templates

Reusable audit methodologies for the basidiocarp ecosystem. Each
template defines a single recurring audit: scope, method, findings
file shape, severity calibration, and a paired verify script.

## When to use these

- An audit-shaped concern recurs (drift, contract accuracy, hygiene).
- The methodology is portable across multiple instances.
- The output is a findings file, not a fix.

## Available templates

| Template | What it audits | Recommended cadence | Why |
|----------|----------------|---------------------|-----|
| [end-to-end-smoke-audit.md](end-to-end-smoke-audit.md) | Whether the core ecosystem loop actually runs (cortina/hyphae/mycelium/canopy/stipe/annulus). | **Monthly during active hardening**, then quarterly. | Static schema checks pass on every shape but never prove flows work end-to-end. Validates F1 exit criterion #1. |
| [schema-accuracy-audit.md](schema-accuracy-audit.md) | Whether septa schemas match their producers AND consumers field-by-field. Two passes (consumer, producer). | **Quarterly**, or after any septa schema change touching ≥3 schemas. | Producer/consumer/schema triangle silently drifts. Validates F1 exit criterion #2. |
| [boundary-compliance-audit.md](boundary-compliance-audit.md) | Whether the C7 CLI Coupling Classification table matches the actual cross-tool spawn call sites in the codebase. | **Quarterly**, or after any tool-boundary refactor. | New CLI couplings creep in silently; classification rules fall out of date. Validates F1 exit criterion #3. |
| [version-pin-drift-audit.md](version-pin-drift-audit.md) | Whether each repo's `Cargo.toml` (or `package.json`) matches the workspace pins in `ecosystem-versions.toml`. | **Monthly during active hardening**, then before each release. | Silent ABI drift on shared crates (esp. spore) is invisible at compile time per-repo. Cheap to run; cheap to fix. |
| [mcp-surface-drift-audit.md](mcp-surface-drift-audit.md) | Whether `mcp__<server>__<tool>` references in CLAUDE.md / AGENTS.md match the actual MCP tool registrations across hyphae, rhizome, and any other MCP servers. | **Quarterly**, or after any MCP server tool-set change. | CLAUDE.md instructions that reference renamed/removed tools cause silent agent failures. |
| [low-queue-prioritization-audit.md](low-queue-prioritization-audit.md) | Whether the dashboard's Low queue is correctly classified against the current freeze policy / roadmap. | **Once per freeze period**, or whenever the roadmap shifts. | Low queue grows without active triage; umbrella handoffs go stale. Hygiene rather than drift. |

## Running an audit from a template

1. Copy the template `.md` into a campaign directory:
   ```text
   .handoffs/campaigns/<campaign-name>-<YYYY-MM-DD>/<lane-name>.md
   ```
   Adjust the handoff-metadata scope paths, the verification-command campaign-name, and the date.
2. Write a paired verify script at:
   ```text
   .handoffs/campaigns/<campaign-name>-<YYYY-MM-DD>/verify-<lane-name>.sh
   ```
   The "Verify Script" section in each template lists the required checks. Copy the
   working examples from the most recent live campaign at
   [`.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/`](/Users/williamnewton/projects/personal/basidiocarp/.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/)
   as a structural starting point — they all follow the same pattern (section presence,
   table presence, baseline verifier still green, scope-discipline checks).
3. Add the campaign to `.handoffs/HANDOFFS.md` with status `Active`.
4. Dispatch a read-only audit agent against the handoff per the
   [delegation contract](/Users/williamnewton/projects/personal/basidiocarp/CLAUDE.md).
5. When the findings file is written and the verify script exits 0,
   the audit is complete. The findings file becomes input to a
   fix-phase pass that opens specific implementation handoffs.

## Conventions across templates

- **Read-only.** Audits never modify source, schemas, or the dashboard. Their only write is the findings file.
- **Findings file structure** is fixed per template. The verify script enforces required sections.
- **Severity** is `blocker | concern | nit`:
  - `blocker` — maps to a specific F1 exit criterion or causes a runtime failure.
  - `concern` — real drift but not blocking.
  - `nit` — cosmetic, doc-only, or low-impact polish.
- **Each finding** includes location, evidence, why-it-matters (linked to a roadmap criterion), and a one-line proposed fix-phase handoff title — never a fix.
- **Parallel safety.** Multiple lanes from one campaign run in parallel against disjoint findings files. The audits do not need to share state.

## When to create a new template (not just a one-off audit)

Promote a new template when:
- The same audit shape has been run twice or more.
- The methodology is independent of any specific finding set.
- The findings file format is stable and the verify script can be parameterized.

Otherwise the audit can live as a one-off lane in a campaign without
template extraction.

## See Also

- [Work Item Template](/Users/williamnewton/projects/personal/basidiocarp/templates/handoffs/WORK-ITEM-TEMPLATE.md) — the underlying handoff template each audit specializes.
- [Campaign README Template](/Users/williamnewton/projects/personal/basidiocarp/templates/handoffs/CAMPAIGN-README-TEMPLATE.md) — wraps multi-lane audit campaigns.
- [F1 Freeze Roadmap](/Users/williamnewton/projects/personal/basidiocarp/docs/foundations/core-hardening-freeze-roadmap.md) — the exit criteria audits validate against.
