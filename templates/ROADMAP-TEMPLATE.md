# [Tool] Roadmap

<!-- ─────────────────────────────────────────────
     PURPOSE AND AUDIENCE
     This is the [Tool]-specific backlog. It answers:
     - What shipped recently (so users know what changed without reading the changelog)
     - What's coming next (so contributors know what to work toward)
     - What's lower priority (so nobody builds it before the Next items are done)
     - What's genuinely uncertain (so Research items aren't mistaken for commitments)

     This is NOT an internal planning document. Do not put implementation notes,
     subtask breakdowns, or estimates here. Link to a separate planning doc
     (PHASES.md, plans/, handoffs/) for that level of detail.

     Cross-repo link — required if this is a per-tool roadmap in a monorepo:
-->
This page is the [Tool]-specific backlog. The workspace [ROADMAP.md](../ROADMAP.md)
keeps the ecosystem sequencing and cross-repo priorities.

---

## Recently Shipped

<!-- Required. What shipped in the last one to three release cycles.
     Purpose: lets users understand what changed without reading the full changelog.
     Purpose: tells contributors which past direction has been validated and closed.

     NAMING: "Recently Shipped" not "Completed" or "Done."
     "Completed" sounds like a history log. "Recently Shipped" signals recency —
     these items are still relevant context for understanding what comes next.

     FORMAT: bullet list. One to two sentences per item.
     Each item should be self-contained — a reader who missed the release can
     understand what changed from this entry alone.
     No version numbers, no dates — those belong in the CHANGELOG.

     DEPTH: Keep items at feature/capability level, not implementation level.
     Good: "Host-aware init flows instead of one generic setup path."
     Good: "Export reliability improvements for path resolution, cache recovery,
            and explicit partial-failure reporting."
     Bad:  "Added `host_policy.rs` with 14 fields and 3 trait impls."  ← too granular
     Bad:  "Fixed stuff and improved things."                           ← too vague

     MAINTENANCE: After two or three release cycles, prune items from this section.
     Stale "Recently Shipped" entries undermine trust in the whole doc.
-->

- [What shipped: capability-level description in one or two sentences.]
- [What shipped.]
- [What shipped.]
- [What shipped — include ecosystem impact if relevant, e.g., "now shared across stipe and mycelium."]

---

## Next

<!-- Required. The current priority work — items that should be done before
     anything in Later gets started.

     NAMING: "Next" not "In Progress" or "Planned." "In Progress" conflates the
     roadmap with a task tracker. "Planned" doesn't convey priority ordering.
     "Next" is explicit: this is what comes first.

     FORMAT: h3 heading + one paragraph per item.
     The heading is the feature name — specific enough to be unambiguous.
     The paragraph explains what it is, why it matters, and how far it extends.
     Do not describe implementation — describe the capability and its value.

     Good:
     ### Workspace index
     Move from the current scoped cache files to a stronger persistent index or
     daemon for larger repos so repeated queries stop paying full scan cost and
     can support richer symbol identity.

     Bad:
     ### Workspace index
     We will add a workspace index by refactoring the existing cache module in
     crates/rhizome-core/src/cache.rs to use a new SQLite-backed index stored
     in .rhizome/index.db with versioned schema migrations.
     ← Too much implementation detail. Links to a planning doc if you need this.

     CROSS-TOOL COORDINATION NOTE:
     If an item affects or depends on a sibling tool, say so explicitly.
     This prevents contributors from landing changes that break ecosystem
     contracts or require coordinated releases.

     Example: "This item should stay aligned with the ecosystem roadmap because
     it changes the shape of data Hyphae receives from [Tool]."

     HOW MANY: Three to six items is the right range. More than six means
     something should move to Later. Fewer than two means the tool may not
     have a clear next direction.
-->

### [Feature name]

[One paragraph: what this is, what problem it solves, where it extends from current
state. If it has cross-tool dependencies, say which tools and why.]

### [Feature name]

[One paragraph.]

### [Feature name]

[One paragraph. If this requires coordination with another tool or the ecosystem
roadmap, call it out: "This item should stay aligned with the ecosystem roadmap
because it affects how [Sibling] receives [data]."]

---

## Later

<!-- Required. Items that are lower priority but still committed direction —
     things that will happen after the Next items are solid.

     DISTINCTION FROM NEXT:
     Later = right direction, wrong time. Not starting until Next is done.
     Next  = right direction, right time. Starting now.

     DISTINCTION FROM RESEARCH:
     Later = committed, deprioritized. The approach is known.
     Research = uncertain. The approach may change based on what we learn.

     FORMAT: same as Next — h3 heading + one paragraph.
     Shorter paragraphs are fine here since these are further out.

     Good:
     ### Machine migration
     Add machine bootstrap import and export for moving full setups between devices.

     Bad:
     ### Machine migration
     Maybe someday we could add some kind of import/export thing.
     ← If it's that uncertain, it belongs in Research, not Later.
-->

### [Feature name]

[One paragraph — or a single sentence if the idea is clear enough.]

### [Feature name]

[One paragraph.]

### [Feature name]

[One paragraph.]

---

## Research

<!-- Conditional — include when there are genuinely open design questions
     worth tracking but not committing to.

     WHAT BELONGS HERE:
     Items where the value is known but the approach is not.
     Items that are conditional on learning something first.
     Items that require external input (user demand, upstream changes, etc.)
     before we can commit.

     WHAT DOES NOT BELONG HERE:
     Items that are clearly Later but you don't want to commit to publicly.
     Speculative features with no clear connection to user needs.
     Internal technical experiments that don't affect users.

     FORMAT: h3 heading + one to two sentences.
     The heading states what's being explored.
     The sentences state the open question or the prerequisite condition.

     Good:
     ### Drift watcher
     Explore a long-running local doctor or drift-watcher daemon once the current
     one-shot repair flows are solid.

     Good:
     ### Semantic refactoring
     Go beyond symbol-level edits toward semantic refactoring that combines
     tree-sitter precision with LSP-backed confidence. Blocked on the
     change-impact analysis work landing first.

     Bad:
     ### World domination
     [Tool] could someday expand to cover all use cases.
     ← Not a real research question.
-->

### [Area being explored]

[What the open question is. What would need to be true for this to move to Later.]

### [Area being explored]

[What the open question is.]

---

## Not Planned

<!-- Conditional — include only when there are features users frequently request
     or expect that are explicitly outside scope. This prevents repeated discussions
     about the same non-starters and makes the boundary clear.

     Format: bullet list. One sentence per item with a brief rationale.
     Keep the tone neutral — "not planned" not "never" or "rejected."
     If something is genuinely out of scope, say why in one clause.

     Good:
     - Cloud sync or remote storage — [Tool] is local-first by design.
     - GUI or web UI — Cap is the operator surface for the ecosystem.
     - Support for [X] — out of scope; [Sibling] owns that concern.

     Skip this section if there are no commonly requested out-of-scope features.
-->

- [Feature] — [one-clause rationale for why it's not planned]
- [Feature] — [rationale]

---

<!--
════════════════════════════════════════════════════════════
MAINTENANCE RULES — read before editing
════════════════════════════════════════════════════════════

MOVING ITEMS BETWEEN SECTIONS:
- Next → Recently Shipped: when the feature ships. Remove from Next, add to
  Recently Shipped. Prune Recently Shipped after two to three release cycles.
- Later → Next: when the Next items are mostly done and this is the right
  thing to start.
- Research → Later: when the approach is clear and the timing is right.
- Research → drop: when the question has been answered negatively or
  the feature is no longer relevant.

STALE ROADMAPS:
A roadmap that hasn't been updated in two or more release cycles is worse
than no roadmap. It signals that the project direction is unclear or that
the doc isn't maintained. If you ship something, move it. If priorities
shift, update the ordering. A roadmap is a commitment to keep the direction
visible — not a set-and-forget artifact.

LEVEL OF DETAIL:
If an item in Next needs more than two paragraphs to describe, it belongs in
a separate planning doc (plans/, handoffs/, PHASES.md) with a link from here.
The roadmap states direction. Planning docs state execution.

CROSS-REPO ITEMS:
If a Next item has dependencies on another tool, link to the ecosystem
roadmap and note the dependency in the item paragraph. Do not coordinate
cross-tool timing only in this file — the ecosystem roadmap is the source
of truth for sequencing across repos.
════════════════════════════════════════════════════════════
-->
