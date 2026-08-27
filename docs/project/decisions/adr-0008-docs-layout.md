# ADR-0008 — Docs layout: one top-level tab, one directory

- **Status:** ✅ Decided <!-- operator decision, 2026-08-27 -->
- **Decision ID:** D-008
- **Related requirements:** —
- **Related questions:** —
- **Related decisions:** refines D-001 (docs are canonical; layout conventions)

## Context

The docs nav has three kinds of top-level entries: **Home**, the **Project**
tab (the four project-meta sections — Direction, Decisions, Records, Process),
and one tab per **domain area**. Before this decision the four project-meta
sections lived flat at the docs root (`docs/direction/`, `docs/decisions/`,
`docs/records/`, `docs/process/`) and were grouped into the Project tab only
by the `nav` in `mkdocs.yml`, while every domain area gets one directory per
tab (`docs/<area>/`). The layout doctrine therefore needed an exception
clause: "one section = one directory — except the Project tab, which is
nav-only."

Timing forced the decision: the blueprint seeds projects, and once the first
seed exists the chassis paths are frozen across the fleet (harvest and
upgrade flows depend on the paths being shared). Restructuring was cheap at
exactly one moment — before any seed existed.

## Decision

**One top-level tab is one directory under `docs/` — uniformly, with no
exception for the Project tab: the four project-meta sections live under
`docs/project/`.**

- `docs/project/direction/`, `docs/project/decisions/`,
  `docs/project/records/`, `docs/project/process/` hold the project-meta
  sections; the **Project** tab maps to `docs/project/`.
- Each domain area keeps its own top-level tab and its own `docs/<area>/`
  directory, a sibling of `docs/project/` — that rule is unchanged, and now
  exception-free.
- The docs root holds only the Home page (`docs/index.md`), non-page
  support files (e.g. `docs/requirements.txt`), dot-directories
  (`docs/.templates/` — skeletons, not pages), and the tab directories.
  The root namespace is fully free for domain-area tabs; no names are
  reserved by the chassis.
- Nav labels and nesting are unchanged by this decision — the rendered site
  is identical except that Project-tab URLs gain one `/project/` segment.
- Enforcement (D-004): the strict MkDocs build gates the nav↔file pairing in
  both directions; the tab↔directory *mirroring* itself is advisory — no
  gate compares the nav's top level to the directory tree — upheld by this
  page, the layout comment above `nav:` in `mkdocs.yml`, and review.

## Consequences

- The layout doctrine collapses to one clean rule with nothing for seeded
  projects to learn around: one top-level tab, one directory.
- `docs/project/` structurally encodes the durable **meta vs domain**
  boundary: in a mature seed, the docs root shows the project's own domain
  directories, with the blueprint chassis bounded in one directory.
- Every path citation into the four sections gains one `/project/` segment —
  paid once, repo-wide, at the only moment it was cheap (no seeds existed).
- Hooks, CI gates, and ritual commands that navigate by these paths were
  re-pointed in the same change; the guard suites re-prove their behavior at
  the new paths.

## Alternatives considered

- **Keep the flat layout** (four sections at the docs root, grouped into the
  Project tab by nav only). Rejected: its remaining benefits — slightly
  shorter cited paths, and free nav-only regrouping in the rare seed that
  promotes one meta section to its own tab — were judged minor. That rare
  case breaks the mirror only aesthetically, since MkDocs never requires the
  tree to mirror the nav; against it stood a permanent exception clause in
  the layout doctrine and a reserved-names burden on the docs root.

## Reversibility / notes

Mechanically cheap to reverse before any project is seeded: `git mv` the four
directories back and re-run the same reference sweep (the strict build and
the docs-truth lane catch stragglers). Expensive to reverse — effectively
frozen — once seeds exist, because chassis paths are shared fleet-wide by
harvest and upgrade flows. The same freeze is why the decision was taken when
it was; a future relayout is a new superseding ADR plus a fleet migration,
not an edit.

## References

- Related docs: [Adding docs pages](../process/adding-docs-pages.md) (the
  layout doctrine this decision simplifies), the layout comment above `nav:`
  in `mkdocs.yml`
- Related decisions: [ADR-0001](adr-0001-documentation-and-records.md)
  (docs are canonical), [ADR-0004](adr-0004-enforcement-doctrine.md)
  (advisory-vs-gated labeling)
