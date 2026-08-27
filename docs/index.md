# {{PROJECT_NAME}}

<!-- BLUEPRINT: Write the landing page — 2–3 sentences on what this project is
and who it is for, then keep the sections below. -->

{{ONE_LINER}}

!!! abstract "About this documentation"
    This site is the **single source of truth** for the project. It supersedes
    any pre-repo working notes. The [decisions registry](project/decisions/index.md) is
    the authoritative list of every `D-xxx` decision; topic pages hold the
    detailed reasoning; each fact has exactly one canonical home
    (see [contributing](project/process/contributing.md)).

## How the docs are organised

One top-level tab is one directory under `docs/`
([D-008](project/decisions/adr-0008-docs-layout.md)). Everything project-meta
lives in the **Project** tab — the `docs/project/` directory — in four
sections:

- **Direction** — why, and where this is going: [vision](project/direction/vision.md),
  [design principles](project/direction/design-principles.md),
  [requirements](project/direction/requirements.md),
  [open questions](project/direction/open-questions.md), and the
  [roadmap](project/direction/roadmap.md) — the traceability chain, in reading order.
- **Decisions** — the [decisions registry](project/decisions/index.md) and one ADR page
  per `D-xxx`.
- **Records** — the history lenses: [epic stories](project/records/epics/index.md),
  [agent-research reports](project/records/agent-research/index.md), and the
  [changelog](project/records/changelog.md).
- **Process** — the [contributing guide](project/process/contributing.md) (the process
  manual) and the [glossary](project/process/glossary.md) (track new terminology here).

<!-- BLUEPRINT: As domain areas appear (architecture, design, etc.), add each
as its own top-level tab with its own docs/<area>/ directory (a sibling of
Home and docs/project/) — that is where topic pages live; one tab, one
directory (D-008). Domain-area tabs need no ADR; promoting any other section
to a top-level tab is a structural decision — record that as an ADR. -->

## Status legend

One legend, used identically across registries, epic pages, issue bodies, and
ADRs:

| Symbol | Meaning |
|--------|---------|
| ✅ | Decided / Done |
| 🟡 | Proposed / In progress — *the default unless challenged* |
| 🔴 | Open |
| 🧊 | Deferred / Superseded — *always names its reactivation trigger* |
