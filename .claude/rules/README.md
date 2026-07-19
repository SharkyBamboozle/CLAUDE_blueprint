# `.claude/rules/` — path-scoped rules

Claude Code loads every `*.md` file in this directory as standing
instructions. A file **without** `paths:` frontmatter loads at launch (same
tier as `CLAUDE.md`); a file **with** `paths:` (glob patterns) loads only
when Claude works with matching files — guidance that stays out of context
until it is relevant.

Use a rule when guidance is genuinely **path-local** (an area's conventions,
a config directory's discipline) and would otherwise bloat the always-loaded
`CLAUDE.md`. Keep each rule a **thin pointer** into its canonical home in
`CLAUDE.md`/`docs/` (one home per fact), one concern per file, ≤ ~30 lines.
`config-cites-decision.md` is the worked example.

Hard limits, per D-004 (enforcement doctrine):

- **Rules are context, not enforcement.** A hard "never" rule stays in
  `CLAUDE.md` *and* keeps its hook/CI enforcer; a rule file may remind,
  never guard.
- **Known gap** (community-reported, not verified upstream): a path-scoped
  rule may not fire when Claude **creates a new** matching file. Verify on
  your Claude Code version before relying on the trigger.

To check whether a rule actually fired, the `InstructionsLoaded` hook logs
which instruction files loaded and why.
