# Release checklist

The single canonical release path. Every step is mandatory unless explicitly
marked optional — the person (or agent) running this checklist **is** the
release engineer; do not skip a step by deferring it to someone else.

<!-- BLUEPRINT: this page is a skeleton — replace the placeholder steps with
the project's real ones as the release process takes shape. If this project
never cuts releases, delete this page (plus its nav entry in mkdocs.yml and
its row in CLAUDE.md → "Where to read, by task") at bootstrap. -->

## 0. Pre-flight

- [ ] Working tree clean; on the exact commit to be released; `main` up to
      date.
- [ ] No open blocker issues against this release.

## 1. Verify

- [ ] `make verify` green on the release commit.
- [ ] *(project-specific test / benchmark gates go here)*

## 2. Docs currency

- [ ] The [changelog](../records/changelog.md) has an entry for this release —
      what changed, for whom.
- [ ] Docs affected by this release are updated (no stale claims).

## 3. Build & package

- [ ] *(build/package commands and their expected outputs go here)*

## 4. Version & tag

- [ ] Version bumped in *(the one canonical place)*.
- [ ] Annotated tag created from the **verified commit**, not from a branch
      tip that may have moved since verification.

## 5. Publish

- [ ] *(publish/deploy steps go here)*
- [ ] Post-publish smoke check: *(the one command or URL that proves it's
      live)*.

## 6. Rollback plan

If the release is bad: *(how to roll back goes here)*. A rollback is followed
by a post-mortem note naming **the check that failed to catch the problem**,
and the fix ships as a new release through this same checklist — never as a
hot patch outside it.

## Checklist meta

- This checklist is the **single source of truth** for releases. If a step is
  skipped, the release is non-conforming and must be marked as such in the
  changelog.
- When you find a step that was missed in a past release, **add it here** —
  not in a separate doc.
- When a step becomes reliably automated, mark it `(automated)` but **keep it
  in the list**, so the release engineer still verifies the automation ran.
