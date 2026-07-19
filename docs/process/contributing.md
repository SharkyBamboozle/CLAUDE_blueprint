# Contributing

A short, practical guide to working on this project — the process manual. These
conventions are what make the project navigable for humans and AI agents alike;
they are recorded as the project's founding decisions in the
[decisions registry](../decisions/index.md).

## How the docs are organised

The top level is deliberately small: **Home**, the **Project** tab, and one
top-level tab per **domain area**. Project holds four meta sections —
**Direction** (vision → principles → requirements →
open questions → roadmap, the traceability chain in reading order),
**Decisions** (the ADR registry + one page per ADR), **Records** (epic
stories, agent-research reports, the changelog), and **Process** (this guide +
the glossary). The directory layout under `docs/` mirrors the nav — one
section, one directory.

**Where does a new page go?** Direction-setting pages → **Direction**; ADRs →
**Decisions**; history → **Records**; process manuals and lookups →
**Process**. Domain/system pages (architecture, design, …) get their own
**top-level tab** (`docs/<area>/`), a sibling of Home and Project — that is
where the topic pages ADRs link to live. Domain-area tabs are the one
sanctioned exception to a shallow top level: they are named up front (at
bootstrap, or when the project grows a new area) and need no ADR; otherwise
depth goes inside a tab. **Promoting any *other* section to a top-level tab
is a structural decision**: it gets an ADR and a registry row like any other
`D-xxx`. *(Advisory — no gate detects a new non-area nav tab that skipped its
ADR; caught at review, per D-004.)*

## Canonicality convention

**The docs site is canonical** — it supersedes any working notes or playbooks.

- The [decisions registry](../decisions/index.md) is the **authoritative list** of
  every `D-xxx` decision with its one-line statement + status.
- **Topic pages** hold the **detailed analysis** behind each decision. Each
  fact has exactly one canonical home; ADRs link to the topic pages rather than
  duplicating them. *(Advisory — no gate detects duplicated analysis; the
  single-home discipline is upheld by review, per D-004.)*
- Decision IDs (`D-xxx`), requirement IDs (`R##`), question IDs (`Q##`), and
  principle IDs (`P#`) are **shared across all pages** — there is one `D-004`,
  referenced from wherever it is relevant.
- When a decision's status changes, update its registry row and its ADR
  together so they stay in sync.

## Stable IDs & the status legend

- IDs are **never renumbered or reused**; new items take the next free number.
  A duplicate `D-###` registry ID or ADR file number (e.g. two branches both
  claiming "the next free number") fails `make verify` — the docs-truth
  checker's consistency lane (`scripts/check_docs_truth.py`).
- One status legend everywhere: ✅ Decided/Done · 🟡 Proposed/In progress ·
  🔴 Open · 🧊 Deferred/Superseded. 🟡 means *default unless challenged* — it
  lets the project move fast without pretending things are final. Every 🧊
  entry states its **reactivation trigger**. *(Advisory — no gate checks legend
  consistency or that a 🧊 entry names its trigger; upheld by review, D-004.)*
- **Resolved registry rows are never deleted** — they flip to ✅ with a
  one-line outcome and a link to the resolving ADR; the ADR reciprocally notes
  which question it resolves. *(The reciprocal ADR↔question citation is gated by
  the docs-truth consistency lane; "never delete a resolved row" itself is
  advisory review discipline — D-004.)*
- **Annotate, don't rewrite.** When a premise weakens, a standing entry gets an
  admonition naming the gating question and session; the entry stands as
  written. *(Advisory — annotation vs. rewrite is a judgment call upheld by
  review; D-004.)*
- **Never hardcode ID ranges or counts in prose** ("Q1–Q21") — they go stale as
  registries grow. Link to the registry instead. *(Advisory — no gate greps for
  hardcoded ranges; D-004.)*

## The ADR process

Architecture Decision Records capture significant decisions.

1. A new significant decision gets the **next free `D-0NN` ID**.
2. Create an `adr-00NN-*.md` page under `docs/decisions/` from the template at
   `docs/.templates/adr-template.md` (Status, Decision ID, Related
   requirements/questions, then Context / Decision / Consequences /
   Reversibility / References).
3. Add a row to the [decisions registry](../decisions/index.md) — ID + one-line
   statement + status + link — and add the page to the `nav` in `mkdocs.yml`.
4. Use the status legend consistently. Where a decision resolves an open
   question, note it in both places and link the two.
5. Keep ADRs focused: the deep analysis lives on the topic pages — link to
   them. The **Reversibility** section is mandatory: record what makes the
   decision cheap or expensive to undo.
6. A ✅ decision is never edited into something else — a changed decision is a
   **new ADR that supersedes** the old one (the old page stays, marked 🧊 with
   a pointer). An ADR may declare itself a *refinement* of another ("D-015
   refines D-014, not a reversal").

Config files that enforce a decision (`.gitignore`, `.gitattributes`, CI
workflows) **cite the decision ID in a comment**, so the file explains itself.
*(Advisory — salience via `.claude/rules/config-cites-decision.md`; no gate
verifies the citation, per D-004.)*

**Any path to a ✅ Decided page is gated** — an in-place edit (typo fix,
annotation admonition, the 🧊 supersession marker), **creating** an ADR
already stamped ✅, **promoting** a 🟡 page to ✅, and **deleting or
renaming** a Decided page via `git rm`/`git mv` — each goes through
`/unlock-adr <id>` first. The `guard-adr.sh` hook (registered for
Edit/Write/MultiEdit **and** Bash) blocks all of these without a fresh
token; `adr-gates.yml` requires an `Unlock-ADR: <id> — <reason>` commit
trailer for any path that reaches or leaves a Decided page — created-as-Decided,
promoted, edited, deleted, or renamed.
The same workflow's `registry-sync` job enforces "update the ADR **and**
the registry row together" (typo-only override: `Skip-Registry-Sync:
<reason>` trailer). Independently, `make verify`'s docs-truth **consistency
lane** fails whenever a registry row and its ADR page disagree on status, a
page/row/nav entry is missing its partners, or an ADR header cites a
`D-###`/`R##`/`Q##` that no registry contains — so drift that slips past a
diff-time check is still caught on every later run.

## The record lenses

Every unit of project history has exactly one home; the other surfaces link to
it (*advisory — no gate checks record placement; the one-home-per-record-type
discipline is upheld by review, per D-004*). Extend this table if a new record
type appears — one home per record type:

| Surface | Lens |
|---|---|
| [Epic page](../records/epics/index.md) | the epic's **curated story / retrospective** — the clean arc, dead-ends dropped |
| [Changelog](../records/changelog.md) | the **chronological diary** — every session, cross-epic, intermediate steps kept |
| [Lessons](../records/lessons.md) | the **distilled "never again" list** — load-bearing lessons only; append-only, superseded in place, real incidents only |
| The **GitHub epic issue** | the **live plan + tracker** — scope, sub-issue DAG, notes index |
| [Decisions](../decisions/index.md) + topic docs | the **canonical decisions & current system state** |
| [Agent-Research](../records/agent-research/index.md) | the curated output of a **fan-out research pass** — proposes and rates, never decides |

**Agent memory vs the canon.** A coding agent's private auto-memory
(machine-local, uncommitted) is its own scratch; the record lenses above are
the committed, **human-curated** canon. The only bridge is a proposal: the
`/session-close` reflection step proposes a [lessons](../records/lessons.md)
entry and writes it only on explicit approval — an agent never writes the
canon on its own initiative (advisory — the approval gate is the enforcer).

## Issues, sub-issues & notes

*Advisory (D-004): the issue-body templates (`docs/.templates/`) and the
`/note` and `/epic-*` ritual commands give these conventions their structural
scaffolding, but no gate rejects a mis-filed issue, a note added as a
sub-issue, or a missing readout comment — the discipline is upheld by the
templates, the rituals, and epic-closeout review.*

Work and findings are tracked as GitHub issues, and the distinction between
them is deliberate:

- **Epics** (`epic` label) group a body of work; children are attached as
  **native sub-issues**.
- **Sub-issues are build tasks** — concrete deliverables that count toward an
  epic's completion. Add them incrementally and reconcile the epic body as they
  land ("Living scope").
- **Notes** (`note` label) are **observations, design considerations, or run
  findings that are *not* build tasks**. A note is filed as its own issue with
  `note` (+ the relevant `area:*`), cross-linked to its epic, and listed in
  that epic's **Related notes** section. It is **not** added as a sub-issue: a
  note-as-sub-issue never reaches "done," so it would leave the epic
  perpetually unfinished and quietly distort "progress."
- **The `note` label is the durable index.** `label:note` returns every finding
  regardless of which epic it came from or whether that epic is still open.
- **Epic closeout triage.** Before closing an epic, sweep its `note` set: close
  the accepted or moot ones, and re-home the still-live ones under the
  successor epic, so no finding goes stale.
- **Outcomes get written back to the issue** — run/build results land as a
  readout comment on the build issue, cross-linked to the epic; heavy artifacts
  live elsewhere (the data repo, if the project has one).

Issue-body skeletons live in `docs/.templates/` (`epic-issue-body.md`,
`task-issue-body.md`, `note-issue-body.md`) — usable directly with
`gh issue create --body-file`.

This keeps two questions cleanly separable: *what's left to build?*
(sub-issues) and *what did we learn / should we reconsider?* (notes).

## Epic pages

Every epic gets a **page under [Epics](../records/epics/index.md)** that tells its story —
what it set out to do, what was built, what was found, what was decided, what
it carried forward — curated to *skip* the intermediate steps that don't matter
to the story.

- **Create** the page as a short stub with a status when the epic starts, from
  `docs/.templates/epic-page-template.md`; add its row to the epics index.
- **Fill it in** as work lands.
- **Finalise** it at **closeout** into the retrospective, and close the epic
  issue with a short pointer comment (skeleton:
  `docs/.templates/epic-closeout-comment.md`) plus the note triage above. The
  full narrative lives on the page — the closing comment is a pointer.
- Every epic body declares its **relation** to other epics (successor to /
  peer with an explicit boundary / supersedes / bridge before) and its
  **explicit non-goals**, naming where each deferred item lives.
- Superseded pages stay, marked 🧊 with a pointer admonition — nothing is
  deleted.

## Agent-research reports

Large fan-out research/analysis passes (many agents reading the codebase and
literature in parallel) get a dated report page under
[Agent-Research](../records/agent-research/index.md), from
`docs/.templates/agent-research-report.md`.

- A report is a **snapshot in time** — it reflects the codebase and literature
  as of its date.
- It **proposes and rates — it does not decide.** Anything load-bearing
  graduates into the appropriate canonical home (an ADR, an epic, a topic
  page, or a new open question); the report stays as the durable record of
  *how* the direction was found.
- Reports include a **"How this was produced"** methodology footer, including
  any adversarial-verification stage and what it downgraded.
- Code observations surfaced along the way are handed off to the `note` system.

## Changelog

[The changelog](../records/changelog.md) is the chronological diary and the project's
inter-session memory. One entry per working session:
`### Session N (YYYY-MM-DD) — title`, then 3–8 sentences: what was attempted →
what landed (PRs/commits) → what was found (link `note` issues) → what was
decided (link `D-xxx`) → what carries forward. Session numbers are citable IDs
— provenance tags elsewhere read *(Session N)*. *(Advisory — the
`/session-close` ritual creates the entry, but no gate validates its format;
D-004.)*

## Standard artifact packs & figures

*Adopt this section when the project produces experiments, figures, or other
non-textual outputs; otherwise leave it as a pointer. Every rule here is
advisory — review-upheld conventions with no mechanical gate (D-004).*

- **Standard artifact pack per change-class.** A change that isn't *seen* can't
  really be reviewed. For each change-class that warrants it (environments, UI,
  performance), define a **fixed artifact set** produced by **one shared
  helper** (never re-invented per issue); the canonical list lives on exactly
  one docs page; issues reference the pack by name in acceptance criteria; and
  `CLAUDE.md` carries a one-line trigger pointing at it.
- **Figures read as one system.** One shared plotting helper applies the house
  style globally; any curve aggregating ≥2 seeds/runs is drawn as the **mean
  with a shaded variance band** (state which measure), never a bare line.
  Exclude padding/placeholder data from any reported distribution.
- **Run provenance.** One namespaced config file is a run's single source of
  truth; the **fully-resolved** config (overrides + seed applied) is
  snapshotted into the run's artifact folder; every parameter single-sourced;
  validate and fail fast before running. Durable artifacts go to the data repo
  (data-repo module), never into this repo's history.

## Branch model

Develop on a **feature branch** → PR into **`development`** (the integration
branch, the repo default). **`main` is the promoted branch** — it advances
only by PR from `development`, never by direct push (branch protection +
the git guard hook enforce this; the single exception is the repo's birth
commit during bootstrap). Never merge your own PR.

## Commit conventions

- **The body of a non-trivial commit tells the story** in four short parts:
  symptom (what was wrong or missing) → cause → fix → and, where a test now
  guards the behaviour, a closing `Pin: <test path>` line naming it. For a
  change to anything load-bearing, add one sentence on why the guarantee still
  holds (e.g. "the check now fires in more cases, never fewer"). *(Advisory —
  no gate inspects commit-body quality; upheld by review, per D-004.)*
- **Exceptions are trailers.** A deliberate bypass of a convention is declared
  as a **git trailer** — a labelled line at the very end of the commit
  message, e.g. `Skip-Registry-Sync: typo-only fix in the ADR page`. The
  reason is mandatory. Trailers are permanent, searchable, and
  machine-checkable — a PR label or a chat-only approval is none of those.
  Any automated check added later verifies exactly these trailers, so the
  convention costs nothing now and becomes enforcement-ready. *(Advisory for
  now — only the `Unlock-ADR` and `Skip-Registry-Sync` trailers are gated
  today, by `adr-gates.yml`; the general "declare bypasses as trailers"
  convention is review-upheld until a trailer-checking gate exists, per D-004.)*

## Enforcement layering (D-004)

**Every process rule names what enforces it — or is explicitly advisory.**
A rule added to `CLAUDE.md` or this guide states the hook, CI gate, test,
or template section that catches violations; a rule nobody catches carries
the honest label *"advisory — deliberately unenforced because ⟨reason⟩"*.
*(This meta-rule is itself advisory — no gate can check whether a newly added
rule named its enforcer; PR review is the backstop, per D-004.)*
The enforcing artifact cites the rule back (the config-cites-decision
convention) — *advisory itself: the back-citation is a practiced
convention, not mechanically checked (D-004)*. The layers, from cheap to
binding:

1. **Prose** (`CLAUDE.md`, this guide) states the rule and points at its
   enforcer.
2. **Local hooks** (`.claude/hooks/`) nudge or deny at edit time; every
   block message says what to do instead. **Hooks are code**: each ships
   with a regression test asserting both the deny side *and* the
   still-allowed side (`scripts/test_guard_git.sh`,
   `scripts/test_guard_adr.sh`) — a fix must not over-tighten. The suites
   run inside `make verify`, so they bind in CI (D-005).
3. **CI gates** (`.github/workflows/`) are the binding layer — they
   survive every client configuration. The meta-gate
   (`scripts/check_ci_gates.py`, part of `make verify`) pins the gate
   wiring itself: gates must fire on PRs into `development` and must not
   carry `continue-on-error`; it also pins the scaffolding wiring, so a new
   deny-hook without a suite (or a checker without a wired `--self-test`)
   fails the gate (D-005).
4. **Exceptions are commit trailers** with a mandatory reason (see *Commit
   conventions*) — permanent, searchable, machine-checked; never PR labels
   or chat-only approvals.

House conventions that follow from the same principle: an allowed-to-fail
CI job ends with an explicit **failure beacon** (otherwise a green check
list hides a red lane); a file-targeted gate **fails loud when its target
file is missing** (a moved file may never turn a gate green); fake secrets
in tests follow the **canary naming convention** in `.gitleaks.toml`; and
**a dormant gate lane owns its activation condition** — it detects when it
becomes needed and fails until configured or explicitly declared off with
a reason, never relying on a human to remember the switch (the flag/env
citation lane of `scripts/check_docs_truth.py` and its seam
`.claude/docs-truth.txt` are the reference implementation).

Of these house conventions the dormant-gate-lane one names its reference
implementation above; the other three — the failure beacon, a file-targeted
gate failing loud when its target file is missing, and the canary naming
convention — are *advisory: convention-strength, with no meta-gate verifying
them (D-004)*.

## Exception lists are ledgers (D-004)

Every allowlist / skip-list / tolerated-issues list any gate grows is a
first-class ledger:

1. **A reason per entry** — inline, next to the entry.
2. **A ceiling** — the list states its maximum size; exceeding it is a
   visible, deliberate diff, never silent accretion.
3. **Staleness fails loud** — an entry that is no longer needed fails the
   gate until removed; the frontier only moves one way.
4. **Itemized, never blanket** — entries name specific items, never a
   whole directory or category.

*These four are advisory construction discipline — the reference ledgers
(`KNOWN_EXEMPT` in `check_docs_truth.py`, the gitleaks/ci-gates allowlists)
follow them, but no meta-gate verifies that every ledger a gate grows obeys
all four; upheld by review, per D-004.*

Honesty- and security-critical findings (a real secret, a fabricated
claim) are **never ledgerable**. *(Advisory — no gate prevents an entry being
added to an allowlist; this is honesty discipline, per D-004.)*

## Testing conventions (D-005)

**Scaffolding is code.** Every deny-hook ships a regression suite that
asserts both the deny side *and* the still-allowed side
(`scripts/test_guard_git.sh`, `scripts/test_guard_adr.sh`); every checker
script ships a `--self-test` proving each check both fails on bad input and
passes on good. All of them run inside `make verify` — and therefore in CI
on every PR (`docs.yml`) — so a broken guard fails the gate instead of
waiting for someone to remember a manual run. *This coverage binds the
**next** hook too:* the CI meta-gate (`scripts/check_ci_gates.py`) reads
the PreToolUse registrations in `.claude/settings.json` and fails
`make verify` if any deny-hook lacks a wired `scripts/test_*.sh`, or any
`check_*` checker lacks a wired `--self-test` — so "add a guard, skip its
suite" can't pass unnoticed. Tests are **hermetic**: no
network, no dependence on mutable repo state — a state-dependent verdict is
printed for human judgment, never asserted (`scripts/test_guard_git.sh`'s
push-to-main case is the reference implementation).

**Test-writing is event-driven, never scheduled.** A test is added when a
change creates the need — not on a cadence, and never to meet a number:

- **A behavior bugfix carries its regression test** — the reproduction
  becomes the test, and the commit body names it on its `Pin:` line (see
  *Commit conventions*). *Advisory — enforced by the commit convention and
  PR review.*
- **New behavior at a seam lands with its test in the same PR.** What makes
  a test worth writing is that it exercises observable behavior at a seam —
  not restating the implementation, testing mocks, or bulk snapshots.
  *Advisory — deliberately unenforced: "same PR" and "worth writing" are
  judgment calls no gate can make; upheld by review (D-004).*
- **A hook or checker change extends its suite in the same diff** —
  enforced on the deny side by the suites running in `make verify`; the
  still-allowed side relies on review.
- **Placement is module-defined:** product code follows its module's layout
  (python-package: `python/tests/` mirroring the package); scaffolding
  tests live in `scripts/` as `test_<target>.sh` suites or as a checker's
  `--self-test`. *(Advisory — placement is a convention upheld by review;
  D-004.)*
- **Weakening or deleting a test is a declared exception, never silent** —
  a `Test-Adjusted: <one-line reason>` commit trailer (the D-004 trailer
  machinery). Making a red test green by loosening its assertion without
  declaring it is an honest-reporting violation, not a fix. *Advisory until
  a trailer-checking gate exists.*
- **No coverage thresholds.** A percentage target trains authors — human or
  agent — to write tests for the metric. The defensible form, if a project
  ever wants coverage enforcement, is a ratchet (coverage never decreases),
  🧊 deferred as an opt-in python-module lane — reactivation trigger: the
  first time a coverage number is cited in a PR or requested by an owner
  (see [ADR-0005](../decisions/adr-0005-testing-policy.md)).

## Adversarial verification (advisory)

The author of a piece of work is its worst-placed checker — so
load-bearing claims (research findings, audit results, a diagnosis about
to drive work, release readiness) get a check whose explicit job is to
**refute** the claim, not confirm it. Three grades, scaled to what a wrong
claim would cost: **self-adversarial** (re-open everything you cited;
near-free, always on) → **independent verify** (one fresh checker with no
shared context, forced confirmed/corrected/refuted verdicts; ~doubles the
work) → **adversarial sweep** (several independent checkers; many ×). The
agent **proposes the grade with a rough cost and the owner scales it up,
down, or skips** — and a skip is recorded in the deliverable, never
silent. Full protocol: `.claude/skills/adversarial-verify/SKILL.md`.
Agent-research reports disclose the verification stage (or its absence)
and what it downgraded in their "How this was produced" footer. Decision
home: [D-006](../decisions/adr-0006-verification-and-honesty.md). Status
per D-004: *advisory* — genuine adversarialness isn't mechanically
checkable; the footer disclosure and review habit are its enforcers.

## Building the docs locally

```bash
pip install -r docs/requirements.txt
mkdocs serve
```

The site builds with `mkdocs build --strict` (also via `make verify`), so
**all internal links must resolve** — check links when you add or move pages.

**Publishing is opt-in and off by default.** The strict build is a *merge
gate* — it runs on every push and PR (`docs.yml`'s `build` job) and publishes
nothing. Deploying the built site to GitHub Pages on merges to
`development`/`main` happens only when the `DEPLOY_DOCS` repository variable is
`true`, which `scripts/github_setup.sh` sets solely under its `--deploy-docs`
opt-in. Keep publishing off for private projects — a Pages site can be publicly
reachable and would expose the docs (#3).

## Growth areas

Sections likely to be added as the project expands — extend this guide (and
`CLAUDE.md`'s map) as they land, keeping each fact in one canonical home.

<!-- BLUEPRINT: list the areas this project will likely grow into. -->
