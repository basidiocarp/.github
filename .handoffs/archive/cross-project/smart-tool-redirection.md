# Smart Tool Redirection — PreToolUse Advisories

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

1. [rhizome-read-grep-advisories.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/rhizome-read-grep-advisories.md)
2. [find-fd-rewrite.md](/Users/williamnewton/projects/basidiocarp/.handoffs/mycelium/find-fd-rewrite.md)
3. [tool-advisory-status-counts.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/tool-advisory-status-counts.md)

Suggested order:

1. `cortina/rhizome-read-grep-advisories`
2. `mycelium/find-fd-rewrite`
3. `cortina/tool-advisory-status-counts`

Intent preserved from the original umbrella:

- add non-blocking `cortina` advisories that steer code-navigation calls toward `rhizome`
- add a `mycelium` rewrite seam for safe `find` to `fd` upgrades
- expose `cortina` advisory activity in status output so operators can confirm the rules are live

Completion for the original umbrella means the three child handoffs above are complete.

## Context

Gap #4 in `docs/workspace/ECOSYSTEM-REVIEW.md`. Estimated combined token reduction
is 70–90% on code navigation tasks. The advisory is intentionally non-blocking:
the agent still gets the answer and learns the pattern over sessions. `mycelium
read` already does the rhizome delegation for large reads — this extends the same
principle to the hook layer and to the `find` command case.
