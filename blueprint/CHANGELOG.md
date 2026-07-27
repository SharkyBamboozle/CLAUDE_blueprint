# Blueprint changelog

What each blueprint version changed. Bumped by the harvest ritual
(`HARVEST.md`); each seeded project records the version it started from in
its init commit.

## v1.0.4 — Operator-only issue closing, the /tick ritual, gate & bootstrap fixes

Seven backward-compatible changes since v1.0.3 — an enforcement pair making
manual issue closes operator-only, a ritual command for deliverable-box
ticking, a hardening pass on `issue-link-guard`, a fail-safe fix to the
lfs-assets module, two bootstrap-hardening fixes from the epic #20 audit,
and a dependency bump. A clean `UPDATE.md` pull for downstream projects: no
breaking changes.

- **Operator-only issue closing** (#54): agents can no longer manually close
  or delete issues — the `guard-issue-close.sh` PreToolUse hook denies MCP
  `state=closed` writes and `gh issue close`/`delete` at the source, and the
  `issue-close-guard.yml` workflow reverts app-/bot-mediated manual closes
  server-side (commit/PR-merge closes and the operator's own clicks stand;
  allowlisted first-party apps; fail-open on read errors). Both suites wired
  into `make verify`; new CLAUDE.md hard-rule bullet + contributing.md
  paragraph. The `issues:`-triggered workflow arms on the default branch at
  this promotion; the live-fire probe is tracked in #57.
- **The `/tick` ritual** (#52): attestation-first deliverable box ticking —
  per box, *did I deliver this?* answered with named evidence or no tick —
  then the anchored body edit and a verify re-read; five pointer edits put
  the affordance at the work-time sites (CLAUDE.md, contributing.md, the
  task skeleton, the PR template). An affordance for the existing
  `issue-link-guard` rule (#37, #41), not a new gate.
- **`issue-link-guard` evaluates merits before waivers, loudly** (#47): the
  decision script now counts deliverable boxes first, consults the
  `Skip-Issue-Link-Guard` trailer only when merits fail, logs which path
  passed, and announces waiver-passes with per-finding `waived:` lines plus
  a `::warning::` quoting the reason; the tick-your-boxes duty becomes
  visible work-time instruction text. Exit codes unchanged for every input.
- **lfs-assets applies fail-safe** (#22): the module now instructs
  uncommenting the chosen menu lines (not appending them as comments) into
  the repo's root `.gitattributes`, creating the file if absent, with a
  mandatory `git check-attr filter` proof step — verbatim application
  previously yielded zero LFS coverage, silently.
- **Bootstrap names the ADR unlock it triggers** (#21): the three sites
  claiming ADR-0007's 🟡→✅ finalization "needs no ADR unlock" now instruct
  `/unlock-adr adr-0007` plus the `Unlock-ADR:` trailer in the birth
  commit's body, and the data-repo module's ADR payload ships 🟡 Proposed —
  the hook and gates themselves are untouched.
- **Tier-1 gate false positive removed** (#23): the illustrative literal
  `{{TOKEN}}` in a `scripts/github_setup.sh` comment — a pre-baked
  completion-gate failure shipped to every seed — reworded to "unresolved
  placeholders".
- **Dependency bump** (#55): `actions/setup-python` 6 → 7 in the GitHub
  Actions group (Dependabot).

## v1.0.3 — Lifecycle guardrails: issue-link guard, promotion train, zombie-push

Five changes hardening how issues close and how releases are cut, plus
push-time protection against stacking commits on an already-merged PR. Each
lands or extends enforcement machinery — CI gates, a ritual command, a push
hook — carrying its own both-ways test suite in `make verify`.

- **`issue-link-guard` — closing keywords may only target issues a PR
  completes** (#18): a required CI gate that blocks a closing reference to an
  `epic`-labeled issue with open sub-issues (closeout PRs pass; the
  `Skip-Issue-Link-Guard:` trailer is the declared exception; an inconclusive
  `gh` fails closed). Adds the forced-choice linking block to the PR template,
  the canonical *PR ↔ issue linking* section in `contributing.md`, and the
  docs-truth `epic-state` lane covering the residual paths.
- **Standardized promotion train** (#35): the `/promote` ritual — contents
  derived from `main..development`, a per-change bump proposal, a hard operator
  STOP on patch/minor/major, caboose PR, promotion PR, operator-only merge +
  tag — plus a promotion PR template and the `release-gate` job (the seam-named
  version file bumped by exactly one semver step and a release-log entry for
  it; seam `.claude/release.txt`). Fills the release checklist and the
  surrounding process prose.
- **Close-at-completion guardrails** (#37): the symmetric rule that an issue
  closes when its deliverables are met. Deliverables become task-list
  checkboxes in the task template; `issue-link-guard` gains the general-issue
  check (a `Closes` at any issue with unchecked boxes fails, the trailer
  excepted); `/session-close` gains the per-issue `n/m` reconciliation sweep;
  the docs-truth `built-state` lane mirrors `epic-state` for the under-closing
  case.
- **Zombie-push guardrails** (#39): `guard-git.sh` now reads the destination
  branch's PR state at push time — terminal (merged or closed) history blocks
  with state-specific recovery instructions, unless the push carries the
  current `origin/development` restart line — and fails open on `gh`/network
  errors. The session-start orientation prints the branch's PR verdict, and the
  canonical *PR lifecycle* section is added.
- **Mandatory deliverable checklist at close time** (#41): a `Closes` at a
  box-less non-epic, non-`note` issue now fails unless a `Skip-Issue-Link-Guard`
  trailer is present — absence no longer reads as compliance — and checkbox
  counting is fence-aware, so a fenced *sample* of `- [ ]` syntax is not
  miscounted as a real deliverable box.

## v1.0.2 — Multi-agent entry point (AGENTS.md)

Two backward-compatible changes since v1.0.1: a tool-neutral entry point
(`AGENTS.md`) so agents that aren't Claude Code can find the contract, and a
fix flipping the seeded changelog convention to newest-first. A clean
`UPDATE.md` pull for downstream projects — no new machinery, no breaking
changes.

- **`AGENTS.md` routes non-Claude agents to `CLAUDE.md`**: a thin pointer file
  (no duplicated rules) so tools following the `AGENTS.md` convention (e.g.
  Codex) are sent to the one maintained contract. It names which rules are
  tool-neutral and CI-enforced for any agent, and which `.claude/` machinery
  is Claude Code-specific and safe for other agents to ignore. No ADR —
  additive entry point, consistent with D-001 (docs canonical) and D-004 (CI
  is the cross-agent enforcer).
- **`AGENTS.md` is truth-checked like its siblings**: added to
  `check_docs_truth.py`'s `DOC_ROOT_FILES` and `ROOT_FILES`, so its
  backtick-cited paths are validated in `make verify`/CI alongside `CLAUDE.md`
  and `README.md` (D-004 — a new entry point names its enforcer).
- **README documents the agent-agnostic posture**: a note that the process and
  its enforcement are tool-neutral while the agent-facing ergonomics
  (`CLAUDE.md`, `.claude/`) are tuned for Claude Code, other agents routed
  through `AGENTS.md`.
- **Seeded changelog convention flips to newest-first** (#12): the seeded
  `docs/records/changelog.md` grew oldest-first while its sibling logs
  (`docs/records/lessons.md`, `blueprint/CHANGELOG.md`) are newest-first, so
  the session-start orientation hook (`grep -m1 '^### '`) surfaced the *oldest*
  entry mislabeled "Last" in multi-session projects. The convention is flipped
  to newest-first across `docs/records/changelog.md`,
  `.claude/commands/session-close.md`, `docs/process/contributing.md`, and
  `CLAUDE.md`; no code change — the hook's existing grep becomes correct. No
  ADR — ADR-0001 (D-001) calls the changelog a "chronological diary" without
  fixing a direction.

## v1.0.1 — Post-launch dogfooding fixes

First patch after the public release — five changes surfaced by using the
template, all backward-compatible (a clean `UPDATE.md` pull for downstream
projects): no new machinery, no breaking changes.

- **Domain areas become top-level nav tabs** (#2): BOOTSTRAP placed chosen
  domain areas as sections *inside* the `Project` tab, reading as
  project-meta. Each area is now its own top-level tab; `Project` keeps only
  the four meta sections. Four editable sources brought into agreement
  (`BOOTSTRAP.md`, both `mkdocs.yml` comments, `contributing.md`,
  `docs/index.md`). No ADR — nav topology isn't ADR-governed.
- **Docs-to-Pages publishing is opt-in, default off** (#3):
  `scripts/github_setup.sh` set `DEPLOY_DOCS=true` unconditionally, so a
  freshly-seeded (often `--private`) project published placeholder-filled
  docs to a public URL on the first merge. Now gated behind `--deploy-docs`,
  with the choice and its public-exposure risk surfaced in BOOTSTRAP. Only
  publishing changes — the strict-build merge gate runs regardless.
- **Seeded README footer links to the blueprint** (#5): the
  `Initialized from Project Blueprint vN` stamp now links "Project Blueprint"
  to the blueprint repo (attribution / backlink). The machine-read anchors
  (birth commit message, changelog Session 1 entry) stay plain, so `UPDATE.md`
  still reads the version whether the footer is bare or linked.
- **README documents the GitHub UI instantiation route** (#6): the "Use this
  template" flow is now a first-class option (badge CTA to `/generate` plus a
  link to GitHub's official guide) alongside the `gh` CLI; the "run
  BOOTSTRAP" step is location-agnostic.
- **Dependency bump** (#1): `pyyaml` requirement `>=6` → `>=6.0.3` in
  `docs/requirements.txt` (Dependabot).

## v1.0.0 — First release

The template is complete and validated end-to-end: the core documentation
skeleton, the GitHub layer (labels, issue forms, PR template, gate workflows),
the Claude harness layer (guard hooks, ritual commands, skill cards), the
optional modules (python-package, data-repo, lfs-assets), and the bootstrap /
harvest / update / adopt lifecycle rituals. A full end-to-end BOOTSTRAP
dry-run — driven through machinery deletion to a green first `make verify` on
the seeded-repo state — validates the seeding path. Seeded projects record
"Initialized from Project Blueprint v1.0.0".
