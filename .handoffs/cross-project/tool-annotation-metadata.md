# Cross-Project: Tool Annotation Metadata

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `multiple`
- **Allowed write scope:** none directly; dispatch child handoffs only
- **Cross-repo edits:** child handoffs decide
- **Non-goals:** direct implementation from this umbrella handoff
- **Verification contract:** complete the child handoffs, keep their paired verify scripts green, and keep dashboard links current
- **Completion update:** when all child handoffs are complete, update `.handoffs/HANDOFFS.md` and archive the umbrella if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** child handoffs own the execution seams for this umbrella
- **Likely files/modules:** none directly; identify the file set inside the selected child handoff before spawning
- **Reference seams:** use the child handoffs as the execution source of truth rather than dispatching this umbrella directly
- **Spawn gate:** do not launch an implementer from this umbrella; pick a child handoff and complete seam-finding there first

This umbrella handoff is decomposed. Do not dispatch it directly.

Use these smaller handoffs instead:

1. [mcp-tool-annotation-classification.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/mcp-tool-annotation-classification.md)
2. [mcp-tool-annotations.md](/Users/williamnewton/projects/basidiocarp/.handoffs/rhizome/mcp-tool-annotations.md)
3. [mcp-tool-annotations.md](/Users/williamnewton/projects/basidiocarp/.handoffs/hyphae/mcp-tool-annotations.md)
4. [annotation-dispatch-policy.md](/Users/williamnewton/projects/basidiocarp/.handoffs/canopy/annotation-dispatch-policy.md)
5. [annotation-aware-hook-templates.md](/Users/williamnewton/projects/basidiocarp/.handoffs/lamella/annotation-aware-hook-templates.md)

Suggested order:

1. `cross-project/mcp-tool-annotation-classification`
2. `rhizome/mcp-tool-annotations`
3. `hyphae/mcp-tool-annotations`
4. `canopy/annotation-dispatch-policy`
5. `lamella/annotation-aware-hook-templates`

Intent preserved from the original umbrella:

- classify `rhizome` and `hyphae` MCP tools against the standard annotation fields
- add the actual annotations in both tool providers
- teach `canopy` to respect those annotations for autonomous dispatch
- expose hook-template patterns in `lamella` that consume the same metadata

Completion for the original umbrella means the five child handoffs above are complete.

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. Classification table covers 100% of rhizome and hyphae MCP tools
3. `cargo build --workspace` and `cargo test --workspace` pass in `rhizome/`,
   `hyphae/`, and `canopy/`
4. `canopy policy show` outputs the dispatch policy with annotation-based rules
5. All checklist items are checked

### Final Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/rhizome && cargo test --workspace 2>&1 | tail -3
cd /Users/williamnewton/projects/basidiocarp/hyphae && cargo test --workspace 2>&1 | tail -3
cd /Users/williamnewton/projects/basidiocarp/canopy && cargo test --workspace 2>&1 | tail -3
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass in all three repos.

## Context

Source: Serena audit. The MCP spec's `annotations` field was designed for exactly
this purpose: allowing hosts to make safety decisions about autonomous tool use.
The ecosystem exposes dozens of tools but treats them all as equivalent, making
principled autonomous operation impossible without blanket human-in-the-loop.

Related handoffs:
- `canopy/notification-lifecycle.md` (#101) — notifications for tool confirmation
  requests will use the same canopy dispatch infrastructure
- `rhizome/orchestration-export-status-contract.md` (#61) — rhizome export tools
  are read-only and should be safe for autonomous use once annotated
- `cross-project/smart-tool-redirection.md` (#65) — tool redirection policy
  intersects with annotation-based dispatch decisions
