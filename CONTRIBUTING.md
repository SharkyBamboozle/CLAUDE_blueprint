# Contributing to Project Blueprint

Thanks for looking at the blueprint itself. **This guide is for people improving
the template.** If you came here wanting to *use* it to start a project, you
don't contribute here — see the [README](README.md) and run `BOOTSTRAP.md` in
your new repo. Like the lifecycle rituals, this file is blueprint machinery: it
is deleted the moment a project is seeded, so nothing here ships downstream.

For the *process* itself — ADRs, stable IDs, notes vs sub-issues, epics, the
changelog, commit conventions — the blueprint follows its own manual,
[`docs/process/contributing.md`](docs/process/contributing.md). Read it; it
applies here too. This page only covers what's **different** about working on a
template.

## The repo is its own working skeleton

Core files live at their real destinations, so the blueprint self-tests. Three
consequences:

- **`make verify` is the gate for this repo, not just seeded ones.** Keep it
  green — the strict docs build, the CI meta-gate, and the docs truth-checker
  all run here.
- **The guards guard the blueprint.** Push-to-main, self-merge, and the ADR edit
  lock all apply here. Work on a feature branch → PR into `development`; never
  merge your own PR. Changing a ✅ Decided ADR means a *superseding* ADR (or
  `/unlock-adr` for a maintenance edit).
- **Your scratch stays out of the tree.** `.claude/archive/` is gitignored in
  *this* repo only — seeded projects track theirs, so the `BLUEPRINT:` marker in
  `.gitignore` removes the block at bootstrap. Committing session notes here
  ships blueprint-internal history into every seed (#70). One visible
  consequence: a `/handoff` that follows an already-committed working doc lands
  as a **deletion**, not a rename. That is the intended shape.

Durable findings therefore need a permanent home other than an archive file. A
reproduced bug in the machinery becomes a case in the matching
`scripts/test_*.sh` suite, where `make verify` keeps it honest. The #21
reproduction is the cautionary example: the 🟡→✅ block it demonstrated was
already asserted by `scripts/test_guard_adr.sh`, which shipped in v1.0.0 — the
archive file was redundant the day it was written, and still reached every seed.
A module's instructions are proved the same way, by executing them verbatim in a
throwaway `git init` repo and asserting the result (`git check-attr filter --
<path>` for lfs-assets, per #22), with the assertion folded back into the
module's own steps.

## Know which tier a file is before you touch it

Every file is one of three tiers (`blueprint/TOKENS.md`), and the tier sets the
blast radius of your change:

- **Literal** — byte-identical in every seeded project (hooks, workflows,
  commands, skills, doc templates, `docs/process/contributing.md`). A change here
  reaches every downstream project through `HARVEST` / `UPDATE`. Highest
  scrutiny; keep it project-agnostic.
- **Tokenized** — carries `{{TOKEN}}` placeholders filled at bootstrap. Never
  hardcode a value a project must choose for itself.
- **Generated / identity** — written fresh per project (README body, filled
  registries, changelog). A blueprint change must not presume its contents.

## Add invariants, not shape

The blueprint stays minimal on purpose. Before adding anything, ask the `HARVEST`
question: is this a **process invariant** (every project wants it → it belongs
here) or **project shape** (a language, a layout, a tool → a `modules/` payload,
or it stays downstream)? **When unsure, leave it out** — it can always be
harvested in a later round.

## Every rule names its enforcer (D-004)

A rule that names no enforcer is just a wish. If you add a convention to
`CLAUDE.md`, the process manual, or a template, wire the thing that catches
violations — a hook, a CI gate, a test, or a template section — and have that
artifact cite the rule back. If it genuinely can't be enforced, label it
*advisory — ⟨reason⟩*. Exception lists you grow are ledgers (D-004): a reason per
entry, a size ceiling, stale entries fail loud, itemized matching only.

## Changes are versioned and tagged

- `blueprint/VERSION` and `blueprint/CHANGELOG.md` record what each release
  changed — bump the version and add a changelog line naming your change.
- Releases are **tagged** `v<VERSION>` on `main`; `UPDATE.md` reads those tags to
  find a seeded project's merge base, so downstream sync depends on them. The tag
  is cut when the change lands on `main` (the `HARVEST` / release step) — not on
  your feature branch.

## Test the machinery you touched

- `make verify` green.
- `bash -n` any script you edited; run the guard suites when a hook changes
  (`scripts/test_guard_git.sh`, `scripts/test_guard_adr.sh`).
- A **new** guard ships with a both-ways demonstration — proof it blocks the bad
  case *and* still allows the good one — in the PR body.
- Touched a bootstrap-path file? A clean run must leave no orphaned `{{TOKEN}}`
  or `BLUEPRINT:` marker, and a new top-level machinery file must be added to
  `BOOTSTRAP.md`'s delete list **and** the bootstrap gate's exclude set (this
  file is the reference example — see `scripts/check_bootstrap_complete.sh`).

## Most improvements arrive through HARVEST

The best ideas are found in real projects, not invented here. Hit a rough edge in
a seeded project? That's a **harvest candidate** — file it as a `note` issue
mentioning the blueprint, and it gets judged and batched in via `HARVEST.md`.
Direct PRs are welcome too, especially for bugs, docs, and self-evident wins; for
anything larger, open an issue first so we can weigh it against "keep the
blueprint minimal."

The blueprint is MIT-licensed (see `LICENSE`); contributions are accepted under
the same license.
