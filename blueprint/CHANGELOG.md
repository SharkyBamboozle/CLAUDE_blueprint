# Blueprint changelog

What each blueprint version changed. Bumped by the harvest ritual
(`HARVEST.md`); each seeded project records the version it started from in
its init commit.

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
