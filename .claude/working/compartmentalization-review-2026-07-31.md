# Review of the compartmentalization plan against the shipped state (2026-07-31)

> **What this is.** A review of
> `.claude/archive/2026-07-24/instruction-compartmentalization-design/plan.md`
> (the "report") against `origin/main` @ `80c3800` (blueprint **v1.0.5**), two
> releases after the report's base commit `3c71795` (v1.0.3). It **revises**;
> it does not rewrite — the report is a dated snapshot and stands as written
> (*records-and-canon.md → Annotate, don't rewrite*). Read the report first;
> this page says which parts are now wrong, which landed, and what the plan
> should become.

## TL;DR

The report's **diagnosis survives intact and is now measured rather than
argued**. Its *plan*, however, was written against a repo that no longer
exists in three ways that matter:

1. **Slice 1 of the diet landed** (#59, −351 words) — and **51% of it was
   erased inside the same release** by unrelated work (+180). The report
   predicted one-way growth; the release cycle since demonstrates it.
2. **`contributing.md` split into 13 act-shaped pages** (#66). This
   invalidates §3.4's delivery design (a `git-workflow` skill card would now
   duplicate an act page) and leaves 9 of `CLAUDE.md`'s 11 process pointers
   landing on redirect stubs.
3. **Phase-0 unknown #2 is answered in-repo.** `guard-issue-close.sh` ships
   a `PreToolUse` matcher on MCP tool names with a regression suite and a
   server-side backstop — §3.4's "optional, pilot it" option 3 is now a
   design decision, not a feasibility question.

Plus one finding the report could not have had: **the blueprint has two
Tier-0 budgets, not one** (its own vs. the seed's), and the single ceiling in
§3.2 would govern the wrong one.

---

## A · The measured delta (method: `wc -w`, the report's method)

### A.1 · `CLAUDE.md`, commit by commit

| Commit | Words | What moved it |
|---|---|---|
| `3c71795` | **2,609** | the report's baseline |
| `c7a3fc5` | 2,700 | +91 — v1.0.4 work landing before the diet |
| `135704c` | **2,351** | **−351 — the deliberate diet, slice 1 (#59)** |
| `937bf49` | 2,531 | **+180 — the two-hats admonition (#75)** |
| `80c3800` (main) | **2,531** | — |

**Net from the report's baseline: −78 words (−3.0%).** Deliberate removal
totalled 351; incidental growth over the same span totalled 271. The
counter-pressure the report said was missing is missing in exactly the way it
predicted, on a measured trace — not an inference from the lessons ladder.

> The v1.0.5 release log states the diet as "2,702 → 2,351 (351 removed)".
> That start point is the diet branch's own tip; measured from the report's
> base commit the same edit reads 2,609 → 2,351. Both are correct against
> their stated base — noting it so the two figures aren't read as a
> discrepancy.

### A.2 · Tier 0, recomputed (the report's §1 table)

| Surface | `3c71795` | `80c3800` | Δ |
|---|---|---|---|
| `CLAUDE.md` | 2,609 | 2,531 | −78 |
| `.claude/rules/README.md` | 180 | 180 | 0 |
| 5 skill frontmatters | 215 | 215 | **0** |
| Model-invocable command frontmatter | 13 (`/checkpoint`) | **35** (`/checkpoint` + `/tick`) | +22 |
| `session-start.sh` static text | ~20–100 (dynamic) | ~20–110 (dynamic; a lessons block was added) | + |
| **Total (static surfaces)** | **3,017** | **2,961** | **−56 (−1.9%)** |

Two corrections to the report's table:

- **Skill descriptions did not grow.** The report's `195` and this `215` are
  the same files measured with a slightly different slice (whole frontmatter
  vs. description text). Measured identically at both commits: **215 → 215**.
  Any future budget checker must pin its slice definition, or it will
  manufacture drift like this.
- **The commands row is stale.** 10 → 11 commands; 9 still carry
  `disable-model-invocation: true`, but `/tick` joined `/checkpoint` as a
  second always-loaded description. Small in words — significant as evidence:
  **a second Tier-0 exception landed in one release with no ledger and no
  argument**, which is precisely what §3.2's second bullet exists to catch.

### A.3 · Tier 2 was restructured (`contributing.md`, #66)

| | `3c71795` | `80c3800` |
|---|---|---|
| Process manual | one page, **5,169 w** | 643-w dispatch hub + **13 act pages** |
| Largest read unit | 5,169 w | 785 w (`records-and-canon.md`) |
| Median read unit | — | **401 w** |

The monolith the router pointed at is gone; the on-demand read unit shrank
~6.6×. This is a *large* compartmentalization win the report predates, and it
changes §3.4's economics (see C.4).

---

## B · The report's §2 disposition table, marked to shipped state

| Section | Report's disposition | Words `3c71795` → main | Status |
|---|---|---|---|
| Definition of done + honesty + adversarial | compress to ~80 w, point at the 2 skills | 290 → **82** | ✅ **delivered** |
| Autonomy contract | trim reproduce-first to one line | 389 → **339** | ✅ **delivered** |
| Hard rules | compress to a ~120-w index | 249 → **250** | ⚠️ **compressed, then refilled** — the per-rule detail did move to the block messages, but a 5th rule (operator-only issue closing) landed in the same window. Net zero. |
| Conventions | move to a `docs/**` path rule | 294 → 256 | ❌ partial (dedup only; no rule file) |
| Repo workflow | index lines; substance to Tier 2/3 | 669 → **698** | ❌ **grew** (+29, the `/tick` sentence) |
| Repo layout | compress ~half | 178 → 178 | ❌ untouched |
| Extending this file | move to a `CLAUDE.md`/`.claude/**` rule | 148 → 148 | ❌ untouched |
| Header + admonition | admonition deletes at bootstrap | 92 → **337** | ⚠️ **+245** (two-hats rules) — blueprint-only, see C.2 |

**Read of the pattern:** slice 1 took the half that was *pure deduplication* —
the release log says so explicitly ("zero words added to any always-loaded
surface"). Every remaining row needs a destination that does not exist yet.
**Slice 2 cannot be free**, and the plan should stop implying it can: the
~1,280 words still sitting in Conventions / Repo workflow / Repo layout /
Extending require the three Tier-1 rule files of §3.3 to be written first.
The report's ~900-word core is still ~1,600 words away, and the cheap 30% of
that distance is spent.

---

## C · Revisions to the plan, proposal by proposal

### C.1 · §3.1 (loading-doctrine ADR) — unchanged in substance, better sited

Still the right first move; still unbuilt (registry is D-001…D-007). Two
adjustments:

- The doctrine now has an obvious topic home: **`docs/process/enforcement.md`**
  (created by #66) already carries *Enforcement layering (D-004)* and
  *Exception lists are ledgers (D-004)*. The new ADR's topic prose belongs
  beside them — not in a new page and not in the hub.
- The report's "four-rule ledger" citation should point at
  `enforcement.md#exception-lists-are-ledgers-d-004`, which is now an
  anchored, canonical statement of the four rules.

### C.2 · **NEW** — split the budget in two: blueprint Tier-0 vs seed Tier-0

The single biggest correction. The +180 that erased half the diet is the
two-hats admonition, which carries
`<!-- BLUEPRINT: delete this whole admonition, rules included, at bootstrap. -->`.
It is **correct**, it is **load-bearing for this repo**, and it **never ships
downstream**. A single ceiling either blocks legitimate blueprint machinery or
lets the seed's budget drift.

Measured on main (`wc -w`):

| | Words |
|---|---|
| `CLAUDE.md`, full (blueprint session Tier-0) | **2,531** |
| − blueprint-state admonition | −245 |
| − `<!-- BLUEPRINT: … -->` blocks | −288 |
| (the two overlap by 14 — the admonition ends in a BLUEPRINT comment) | +14 |
| **Seed-inherited remainder** | **2,012** |

**519 words — ≈20% of this repo's own `CLAUDE.md` Tier-0 — is scaffolding a
seeded project never sees.** So §3.2's checker reports and gates **two numbers**:
*authoring budget* (full file, this repo) and *seed budget* (with the
admonition and BLUEPRINT blocks stripped — the number that governs the
template's charter). The ~900-word core target should be restated against the
**seed** budget; today's seed figure is 2,012, i.e. the real gap is ~1,100
words, not ~1,600.

Precedent to copy for the two-mode behaviour: **Lane G** of
`check_docs_truth.py` — a lane that arms on `blueprint/` being present and
**self-disarms forever at bootstrap**. The seed-budget lane is the same shape
inverted.

### C.3 · §3.2 (context-budget gate) — same proposal, three in-repo patterns to copy

Still the only genuinely new machinery, still unbuilt (`make verify` has no
budget lane). It no longer needs to invent its conventions:

- **Ledger shape** → `enforcement.md` → *Exception lists are ledgers* (reason
  per entry, stated ceiling, staleness fails loud, itemized never blanket).
- **A lane that owns its activation condition** → the house convention named
  in `enforcement.md`, with `.claude/docs-truth.txt` as the shipped reference
  implementation (`mode: unconfigured|configured|off <reason>`). A budget lane
  should ship `unconfigured` and arm itself, not wait to be switched on.
- **Blueprint-only / self-disarming** → Lane G (C.2).

Two seeded ledger entries already exist and should be written into the
proposal: `/checkpoint` (its card argues why) and **`/tick`** (which arrived
with no argument at all — the first thing the gate would have caught).

Add one requirement the A.2 correction exposed: **the checker pins its own
measurement slice** (which lines of frontmatter, whether BLUEPRINT blocks
count, `wc -w` semantics), or it will invent drift where there is none.

### C.4 · §3.4 (just-in-time git/PR delivery) — **the skill card should be dropped**

§3.4 option 2 proposed a `git-workflow` skill holding "what the gates can't
teach", with "canon stays in `contributing.md`". After #66 that canon is
**already act-sized and act-named**: `committing.md` (236 w), `pushing.md`
(537 w), `opening-a-pr.md` (654 w), `closing-issues.md` (773 w). A skill card
would be a fourth copy of text that is now one hop from the hub, and it would
cost ~40 words at Tier 0 — the exact accretion the plan exists to stop.

**Revised option 2:** no new skill. The act page *is* the payload; the
delivery vehicles are the ones that already fire at the moment —
`guard-git.sh` block messages, the PR template's forced-choice block,
`issue-link-guard`'s failure text — each re-aimed to name its act page.
Tier-0 cost: **zero** instead of ~40 words.

Options 1 and 3 stand. Option 3 is upgraded from "feasibility unknown" to
"design decision" by C.7, and `guard-issue-close.sh` is its template — copy
its three defensive properties verbatim: an explicit **anti-over-tighten
allowlist** ("still allowed: …"), **fail-open on parse failure**, and a
**named-residuals** paragraph (D-004).

### C.5 · **NEW** — re-aim the pointers that now land on redirect stubs (cheap, do it first)

#66 deliberately kept every old `contributing.md` heading as a *"Moved: …"*
stub, because ✅ Decided ADRs cite those anchors and ADR pages are
`/unlock-adr`-gated. **The stubs are correct and must stay.** But
non-ADR pointers were only partly re-aimed: `041d658` re-aimed
`config-cites-decision.md`; `CLAUDE.md` and the hook block messages were not.

Measured on main: **9 of `CLAUDE.md`'s 11 `contributing.md` pointers now
resolve to a redirect stub** (Testing conventions, Commit conventions,
Enforcement layering, Issues sub-issues & notes ×2, Epic pages, PR lifecycle,
Promotion & releases, PR ↔ issue linking). Same for `session-start.sh`'s
zombie-branch verdict and `guard-issue-close.sh`'s block message.

Every one of these is a **two-hop read at the moment of need** — the failure
mode the whole plan is about, in the always-loaded file itself. And CI cannot
see it: `check_docs_truth.py` validates the backtick *path* but explicitly
skips arrow/section tokens as "illustrative"
(`path_citations()`, `PATH_TOKEN_RE`). So this decays silently.

**Proposal:** a standalone, pre-diet PR re-aiming the unlocked pointers at
their act pages (ADR citations untouched). Zero risk, no dependencies, and it
makes the §3.3 diet strictly easier — several `CLAUDE.md` bullets exist only
to carry a pointer that will now be one word longer and one hop shorter.

*Optional follow-on:* teach the docs-truth checker a "no standing pointer
resolves to a redirect stub" lane, exempting ADR pages by ledger. That would
make this class of decay gated rather than advisory.

### C.6 · §3.3 (the diet + 3 path rules) — same shape, smaller rules

Unchanged in direction; the rule files get cheaper to write because their
canon now exists at act granularity:

| Report's rule file | Revised content | Now points at |
|---|---|---|
| `docs-conventions.md` (`docs/**`) | status legend, stable IDs, canonicality | `records-and-canon.md`, `adding-docs-pages.md` |
| `adr-work.md` (`docs/decisions/**`) | unlock protocol, supersede-never-edit | **`writing-adrs.md`** (new act page) |
| `claude-md-hygiene.md` (`CLAUDE.md`, `.claude/**`) | extending-this-file, pointer-over-import, harvest flagging | `HARVEST.md`, `CONTRIBUTING.md` → *Two hats* |

Each is now genuinely a ≤30-line pointer card, per `rules/README.md`.

### C.7 · §5 Phase 0 — one unknown is answered; three remain

**Unknown #2 (PreToolUse matching on MCP tool names) is settled in-repo.**
`.claude/settings.json` ships `"matcher": "Bash|mcp__.*issue_write"` for
`guard-issue-close.sh`, with `scripts/test_guard_issue_close.sh` +
`scripts/test_issue_close_guard.sh` in `make verify` and
`.github/workflows/issue-close-guard.yml` as the server-side backstop. Drop it
from the spike and cite the implementation instead.

The report also flagged "MCP/API operations bypass Bash-matcher hooks" as an
open gap that is "Phase-0 verification work regardless" — **that gap is now
closed for issue-closing** and has a documented residual (raw HTTPS calls,
covered server-side). The pattern to generalize exists; what remains is
deciding which other operations deserve it.

Still open, unchanged: **#1** (does a `paths:` rule fire when the agent
*creates* a matching file), **#3** (which hook events inject non-blocking
context on the pinned version), **#4** (frontmatter semantics for skills vs
commands). Spike shrinks from 4 questions to 3.

### C.8 · §3.5 / §3.6 — still unbuilt, one addition already landed

`session-start.sh` gained a conditional lessons block (correct, zero-noise
discipline held). Neither proposed addition (bootstrap pointer; dirty-ADR
one-liner) landed. `BOOTSTRAP.md` and `HARVEST.md` have no budget wiring.
`HARVEST.md` §"Placement of a harvested `CLAUDE.md` convention" is now the
natural hook for §3.6's checklist question — it already argues one-home-per-fact.

### C.9 · **NEW** — this report's own file location is now against the rules

`.gitignore` on `development`/`main` carries `.claude/archive/*` (+
`!README.md`), and #70 **deleted the two archive entries this repo had
committed**. `CONTRIBUTING.md` → *The repo is its own working skeleton* is
explicit: *"Your scratch stays out of the tree… Durable findings therefore
need a permanent home other than an archive file."*

The report at `.claude/archive/2026-07-24/instruction-compartmentalization-design/plan.md`
is tracked on this branch only because the branch predates that change.
**Merging it as-is would re-introduce exactly what #70 removed** — and ship a
blueprint-internal design doc, citing this repo's machinery, into every
seeded project.

Recommended disposition: **do not merge the archive file.** Its durable
content graduates to permanent homes — the ADR (C.1), the topic prose in
`enforcement.md`, and the checker plus its self-tests (C.3) — which is what
the repo's own doctrine prescribes for a durable finding.

> **Note a gap while here:** `docs/records/agent-research/` looks like the
> obvious destination — the report describes itself in that lens's exact
> words ("proposes and rates — it does not decide"). It is **not** safe here.
> That index is a shipped stub carrying a `<!-- BLUEPRINT: one row per
> report -->` marker; a row added in this repo is blueprint-internal history
> in a file every seed inherits — the same failure two-hats rule 2 names for
> `changelog.md` and `lessons.md`. **Lane G gates those two files only.**
> Worth a `note` issue: either extend Lane G to the agent-research and epics
> indexes, or state in *Two hats* why they are out of scope.

---

## D · Re-rated proposal map

Savings are **seed-budget** Tier-0 words (C.2). Effort in issue-sized units.

| # | Proposal | Change since the report | Savings | Risk | Effort | Depends on |
|---|---|---|---|---|---|---|
| **C.5** | Re-aim stub-hop pointers | **new — do first** | ~0 (quality, not words) | none | 1 | — |
| 3.1 | Loading-doctrine ADR | site it in `enforcement.md` | 0 (enables the rest) | none | 1 | — |
| **C.2** | Two-budget model | **new — folds into 3.2** | 0 (correctness of the ceiling) | none | +0.5 on 3.2 | 3.1 |
| 3.2 | Context-budget gate | 3 patterns to copy; 2 ledger entries seeded | 0 direct; stops regrowth | low | 2–3 | 3.1, C.2 |
| 3.3 | Diet slice 2 + 3 path rules | ~1,280 w left in 4 sections; rules now cheaper | ~1,100 to the ~900 target | medium | 3–4 | 3.1, C.5, Phase 0 |
| 3.4 | Just-in-time git/PR delivery | **skill card dropped**; option 3 de-risked | ~450 of 3.3's total | low | 2 | C.5 |
| 3.5 | Session-start additions | unchanged | 0 (conditional only) | none | 1 | — |
| 3.6 | Blueprint wiring | hook it into HARVEST's placement rule | future-proofing | low | 2 | 3.2 |
| **C.9** | Retire the archive file | **new** | n/a (hygiene) | none | 0.5 | 3.1 |

**Revised sequence:** C.5 (free, immediate) → 3.1 + 3.2/C.2 (measure before
cutting) → Phase 0 (3 questions) → 3.3 + 3.4 as one epic → 3.5 + 3.6 → C.9 at
closeout. Still one epic; the sub-issue count goes from ~6 to ~8.

---

## E · What still holds, unrevised

- **§1's two structural findings.** Both confirmed by measurement (A.1, A.2).
- **§4's counterarguments in full.** The autonomy contract, hard-rule
  awareness, and the router all held under an actual diet — #59 cut around all
  three, and the one section it compressed hardest (Definition of done) is the
  one whose substance had two always-loaded skill triggers. §4 predicted the
  cut lines correctly.
- **"Moved ≠ saved."** A.2 is the proof: skill descriptions were flat only
  because nothing moved there; `/tick` shows the surface grows the moment
  something does.
- **The tier model itself.** Five tiers, unchanged and now with one more
  Tier-3 occupant (`guard-issue-close.sh`).

## F · How this was produced, and what was not checked

Single-agent review, one session, against `origin/main` @ `80c3800` in a
clean worktree. All word counts are `wc -w` at the named commits — the
report's method — and are reproducible from the commands in this repo's
history; where I state a figure the report gave differently (skill
frontmatter, the diet's start point) I say which slice each used rather than
calling either wrong.

**Not measured:** token figures (none published here — the report's ×1.3
estimates are not carried forward). **Not verified:** every Phase-0 unknown
in C.7 that is still listed as open — I confirmed #2 from shipped code and
tests, and did **not** test #1, #3, or #4 on this harness. **Not run:**
`make verify` (this review changes no gated surface); the `docs/` build is
untouched by this file, which lives in `.claude/working/`.

**A measurement hazard, hit while writing this.** The same `CLAUDE.md` counts
**2,531** words under `wc -w` in one shell and **2,638** under `wc -w` invoked
from Python — a locale difference in what counts as whitespace (this file uses
non-ASCII spacing). Every figure here is `wc -w < file` from one shell, and
the ±4% spread between two invocations of the *same tool* is the sharpest
argument for C.3's "pin the measurement slice" requirement: a budget gate that
does not pin its counter will fail or pass on the runner's locale.

**Adversarial verification (D-006).** This review had a **Grade-1
self-check**, plus a targeted recount of its two most falsifiable claims.
Every count was re-measured from a second angle (per-commit trace vs. section
sums vs. the release log's own figures) — that is what caught the
skill-frontmatter method artifact, the two diet baselines, and the locale
hazard above. Two claims were then checked mechanically and **confirmed**:
the stub-hop count (parsed `contributing.md`'s sections for a leading
*"Moved:"*, matched against `CLAUDE.md`'s pointer lines — **9 of 11**, all
nine being the section-arrow pointers), and the two-budget arithmetic
(re-derived under one consistent counter; the 245 + 288 parts overlap by 14
words, which reconciles to the 519 total).

**No independent (Grade-2) pass ran.** What remains genuinely refutable is
judgment, not arithmetic: **(a)** that two budgets are *needed* rather than
merely measurable — a reviewer could argue one ceiling on the seed number
suffices, since blueprint-only text is bounded by the admonition; and
**(b) the one call most likely to be wrong** — that dropping the
`git-workflow` skill (C.4) loses nothing the act pages don't already carry,
which assumes an agent reaches `pushing.md` from a block message as reliably
as it would fire a skill trigger. Unknown #3 of the Phase-0 spike bears
directly on that assumption and is untested here. A Grade-2 pass on those
two: roughly a third of this task again.
