# Changelog

<!-- ─────────────────────────────────────────────
     FORMAT RULES — read before editing this file

     VERSION FORMAT
     Every release heading must follow this exact format:
       ## [MAJOR.MINOR.PATCH] - YYYY-MM-DD
     Examples:
       ## [1.2.3] - 2026-04-01    ✓
       ## v1.2.3 - 2026-04-01     ✗  (no v prefix)
       ## [1.2.3]                 ✗  (no date)
       ## 1.2.3 - 2026-04-01      ✗  (no brackets)

     SEMVER RULES
     PATCH (0.0.X) — bug fixes, internal refactors with no behavior change
     MINOR (0.X.0) — new features, new CLI flags, new MCP tools, new config options
     MAJOR (X.0.0) — breaking changes to public API, CLI surface, or wire contracts

     Any change that breaks a downstream consumer's integration (contract schema
     change, removed flag, renamed tool) is a breaking change and requires a major bump.
     When in doubt between patch and minor, prefer minor.

     UNRELEASED SECTION
     Keep [Unreleased] at the top. Accumulate changes here as work lands.
     On release: rename [Unreleased] to [MAJOR.MINOR.PATCH] - YYYY-MM-DD,
     add a new empty [Unreleased] above it.
     Never leave [Unreleased] empty for more than one commit cycle — add entries as you go.

     STANDARD SECTION NAMES
     Use only these six, and only when you have entries for them:
       ### Added      — new features, new commands, new tools, new config options
       ### Changed    — behavior changes, refactors with visible effect, deprecations
       ### Fixed      — bug fixes
       ### Removed    — deleted features, removed flags, dropped dependencies
       ### Security   — vulnerability fixes (use even for patch releases)
       ### Deprecated — features marked for future removal

     DO NOT use custom section names:
       ### Features      ✗    use ### Added
       ### Bug Fixes     ✗    use ### Fixed
       ### Improvements  ✗    use ### Changed
       ### New Features  ✗    use ### Added
       ### Performance   ✗    use ### Changed (add a note about perf in the entry)
       ### CI            ✗    use ### Changed or omit entirely
       ### Tests         ✗    use ### Changed or omit entirely
       ### Code Quality  ✗    omit entirely unless it has user-visible effect

     ENTRY FORMAT — the bolded subject pattern
     Every entry must have a bolded subject, then a colon, then a description:

       - **[Subject]**: [Description of what changed and why it matters.]

     The subject is 2-5 words summarizing the change.
     The description answers: what changed, what it enables or fixes, what the
     user should know. Present tense preferred ("now does X" not "did X").

     Good:
       - **Hyphae session bridge**: Cortina can now start, reuse, and end Hyphae
         sessions around structured signals instead of only writing ad hoc memories.
       - **LSP auto-install disabled**: Returning an error with install hint instead
         of silently falling back when RHIZOME_DISABLE_LSP_DOWNLOAD=1 is set.

     Bad:
       - route diagnostic shell commands through raw invoke passthrough    ✗ (no subject)
       - Fixed bug (`b79e5cc`)                                             ✗ (commit hash)
       - Updated store traits, models, and schema                          ✗ (no "why")
       - **Improvements**: Various improvements were made                  ✗ (vague)

     WHAT NOT TO INCLUDE
     - Commit hashes or PR numbers (link them if you must reference them)
     - Internal implementation details with no user-visible effect
     - "Bumped lockfile dependencies" as a standalone entry (fold into a real entry or omit)
     - "Updated README/docs" as a standalone entry unless the docs are a primary deliverable
     - Entries for CI-only changes unless they affect contributors directly
     ──────────────────────────────────────────── -->

All notable changes to [Tool] are documented in this file.

## [Unreleased]

<!-- Accumulate changes here as they land. On release, rename this section to
     ## [MAJOR.MINOR.PATCH] - YYYY-MM-DD and add a new empty [Unreleased] above. -->

---

## [0.1.0] - YYYY-MM-DD

<!-- Initial release section. Use ### Added only — nothing was changed or fixed
     before the first release. List the headline capabilities, not implementation details.
     Three to eight bullets is the right range for an initial release.
     Users reading this should understand what the tool does from this section alone. -->

### Added

- **[Core capability]**: [What the tool does at its most fundamental level.]
- **[Feature A]**: [What it enables for the user.]
- **[Feature B]**: [What it enables for the user.]
- **[Integration]**: [Key ecosystem integration if applicable.]
- **[CLI surface]**: [Key commands available.]

---

<!--
════════════════════════════════════════════════════════════
EXAMPLE ENTRIES — for reference when filling in real releases
════════════════════════════════════════════════════════════

## [0.5.0] - 2026-03-31

### Added

- **Statusline command**: `cortina statusline` reads Claude Code's stdin payload
  and prints a compact one-line summary with context usage, token counts,
  estimated session cost, model name, git branch, and Mycelium savings.
  Point Claude Code at it with `statusLine.command = "cortina statusline"`.
- **Canopy evidence bridge**: Cortina can now attach best-effort outcome evidence
  to the active Canopy task for the current worktree when Canopy is available.

### Changed

- **Strict identity-v1 runtime**: Session startup, stop handling, and Hyphae
  interaction now require the structured project/worktree/runtime identity
  instead of falling back to the older scope-only hot path.
- **Published Spore discovery**: Cortina now consumes released `spore v0.4.6`
  discovery for Hyphae, Canopy, and its own tool identity.

### Fixed

- **Stop-path attribution**: Outcome attribution now prefers exact session or
  identity matches and no longer mirrors legacy project-scoped fallback memories.
- **Lifecycle consistency**: Runtime session propagation and outcome persistence
  now align with the shared Hyphae/Cap timeline contract.


## [0.4.0] - 2026-03-22

### Changed

- **Public error types**: All public APIs now return `Result<T, SporeError>`
  instead of `anyhow::Result<T>`. Consumers can match on specific variants
  (`ToolNotFound`, `RpcError`, `Timeout`, `Config`, etc.) for targeted handling.
- **Lazy tool discovery**: Per-tool `OnceLock` replaces eager HashMap probe.
  `discover(Tool::Hyphae)` no longer probes all four tools on first call.

### Fixed

- **Subprocess restoration**: Replaced `.unwrap()` with safe `if let` on child
  process restoration to avoid panics when the child exits unexpectedly.
- **Path argument encoding**: `tar` and `unzip` commands now receive `OsStr`
  paths instead of lossy UTF-8 conversions, fixing archives with non-UTF-8 paths.

### Removed

- **`anyhow` public surface**: Removed `anyhow::Result` from all public function
  signatures. Internal error handling still uses `anyhow` where appropriate.


## [0.3.0] - 2026-03-15

### Added

- **[New feature]**: [Description.]

### Deprecated

- **[Old flag or command]**: Deprecated in favor of `[new flag or command]`.
  Will be removed in [0.X.0 or 1.0.0].


## [0.2.1] - 2026-03-10

### Security

- **[Vulnerability description]**: [What the vulnerability was, what the fix is,
  who is affected.] Reported by [name/handle if applicable].
════════════════════════════════════════════════════════════
-->
