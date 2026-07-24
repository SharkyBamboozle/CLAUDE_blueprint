# Instruction compartmentalization — a plan against instruction pollution (2026-07-24)

> **Status: proposal.** This document analyzes the blueprint's standing
> instruction load and proposes a compartmentalization architecture. It
> proposes and rates — it decides nothing; every load-bearing change below
> would land through the normal path (ADR + registry row, epic + sub-issues).
> Produced on commit `3c71795` (branch
> `claude/instruction-compartmentalization-design-gtqmwt`).

## TL;DR

The framework already compartmentalizes well at its edges — 9 of 10 ritual
commands cost zero standing context, skills load bodies on demand, hooks
teach rules at the moment of violation, and one path-scoped rule exists as a
worked example. The pollution is concentrated in exactly one place:
**`CLAUDE.md` itself carries ~86% of the always-loaded instruction mass
(2,609 of ~3,040 words)**, and the framework's growth pressure is one-way —
the lessons escalation path promotes rules *into* `CLAUDE.md`, `/doctor` is
mentioned as a trim aid, but nothing measures the load, nothing gates it,
and nothing ever demotes a rule to a cheaper tier.

The plan: (1) name the loading doctrine in an ADR — *every standing
instruction declares its load moment*, the twin of D-004's "every rule names
its enforcer"; (2) build the missing structural enforcement — a
context-budget lane in `make verify` that counts the always-on surfaces
against a ledgered ceiling; (3) put `CLAUDE.md` on a diet to a ~900-word
core (hard-rule index + autonomy contract + router), moving each removed
section to the tier that matches its work moment; (4) deliver the
commit/PR/release protocols just-in-time via the mechanism the repo has
already proven — instructive hook messages at the exact tool call they
govern; (5) wire the same discipline into `BOOTSTRAP.md` and `HARVEST.md` so
seeded projects don't regrow the mass.

---

## 1 · The load map as measured

The repo *already implements* a five-tier loading model — it has just never
been named, measured, or enforced. Word counts: `wc -w`, this session, commit
`3c71795`. Token figures are estimates (~1.3 tokens/word), labeled as such.

### Tier 0 — always loaded (session start, every session)

| Surface | Words | Note |
|---|---|---|
| `CLAUDE.md` | 2,609 | the mass |
| `.claude/rules/README.md` | 180 | no `paths:` frontmatter → launch tier (confirmed: present in this session's context) |
| 5 skill descriptions (frontmatter) | 195 | the trigger surface; bodies load on demand |
| `/checkpoint` command description | ~10 | the only command *without* `disable-model-invocation` |
| `session-start.sh` output | ~20–100 | dynamic; zero-noise discipline already applied |
| **Total** | **~3,040** | **≈ 4.0k tokens (estimate)** |

### Tier 1 — path-scoped (loads on touching matching files)

`config-cites-decision.md` (117 words; `paths:` = `.github/**`,
`.gitignore`, `.gitattributes`, `mkdocs.yml`, `.claude/settings.json`,
`docs/requirements.txt`). Confirmed live this session: it fired when
`.claude/settings.json` was read, not before. **This tier has exactly one
occupant.** It is the mechanism the whole plan builds on.

### Tier 2 — on demand (invocation or agent-directed read)

- 10 ritual commands, 2,155 words total — **9 carry
  `disable-model-invocation: true` and cost zero standing context**
  (confirmed: absent from this session's context; `/checkpoint`, the one
  deliberate exception, is present).
- 5 skill bodies, ~2,000 words — load only when the skill fires.
- `docs/process/contributing.md` (5,169 words), ADRs, templates — read when
  the task requires; `CLAUDE.md`'s router points at them.

### Tier 3 — event-injected (hook output at the governed moment)

- `guard-git.sh` deny messages (~40–90 words each): push-to-main,
  force-push, binary staging, self-merge, zombie-push — each block message
  *teaches the rule and the recovery path at exactly the moment it matters*.
- `guard-adr.sh` deny message: the ADR-lock protocol, delivered on the
  violating edit.
- `pre-compact.sh` (~70 words, only when no fresh checkpoint exists),
  `stale-working-docs.sh` (Stop-time nudge), `session-start.sh` verdict
  lines (branch PR state, only when it has PR history).

### Tier 4 — mechanical (never enters context)

CI gates + decision scripts + their suites, settings permissions/deny lists,
branch protection. Their *failure messages* are a just-in-time instruction
surface of their own (Tier 3 at CI distance).

### The two structural findings

1. **The mass is one file.** Everything outside `CLAUDE.md` is already lean
   or demand-loaded. Any plan that doesn't restructure `CLAUDE.md` itself is
   cosmetic.
2. **Growth is structurally one-way.** `lessons.md` names the escalation
   path (lesson → `CLAUDE.md` one-liner or skill → automated check) and even
   says "this keeps `CLAUDE.md` growth demand-driven" — but there is no
   counter-pressure: no measurement, no ceiling, no demotion path, and no
   rule that a new instruction must declare *when it loads*. D-004 forces
   every rule to name its **enforcer**; nothing forces it to name its
   **load moment**. That asymmetry is where the pollution comes from.

---

## 2 · `CLAUDE.md`, section by section — when is each actually needed?

| Section | Words | Actually needed | Disposition |
|---|---|---|---|
| Header + blueprint admonition | 92 | orientation; admonition only pre-bootstrap | Keep header; admonition already deletes at bootstrap |
| Hard rules | 249 | *awareness* always; *detail* at the git/edit moment — and every bullet already has a Tier-3/4 enforcer that teaches on violation | Compress to a one-line-per-rule index (~120 w) |
| Autonomy contract | 389 | every turn — this governs judgment itself and cannot be event-triggered ("stop and ask" must be known *before* acting) | Keep; trim the reproduce-first paragraph to one line (full protocol is already a skill) |
| What this project is | 29 | always | Keep |
| Commands | 64 | always (`make verify` is the verification entrypoint) | Keep |
| Canonical docs + router | 210 | always — the router is what makes on-demand loading work | Keep, tighten |
| Repo layout | 178 | orientation | Compress ~half; detail is discoverable |
| Conventions | 294 | only when editing docs/registries/config | Move to a path-scoped rule on `docs/**` (+ keep the one-line "new decision → /adr-new" pointer) |
| Code style | 51 | rarely; already a pointer | Keep |
| Repo workflow | 669 | each bullet at a *specific* moment: issue filing, PR open, push, release, session end | Split: one-line index stays; substance moves to Tier 2/3 (see §3.4) |
| Definition of done + honest reporting + adversarial verification | 290 | at claim/report/PR time — and ~duplicated by the `honest-numbers` + `adversarial-verify` skills whose triggers are already always-loaded | Compress to ~80 w naming the bar + pointing at the two skills |
| Extending this file | 148 | only when editing `CLAUDE.md`/process files | Move to a path-scoped rule on `CLAUDE.md` + `.claude/**` |

Kept core: ~900–1,000 words. Moved: ~1,600–1,700 words (−~60% of
`CLAUDE.md`, −~2.1k tokens estimated at Tier 0). Honest accounting of the
add-backs: new path-scoped rules cost 0 until touched; a new skill costs its
~40-word description at Tier 0; hook-delivered text costs 0 until the moment
it governs.

### Known duplication to collapse while moving (one canonical home each)

- **D-006 texts** — `CLAUDE.md` §Definition-of-done ↔ `honest-numbers` ↔
  `adversarial-verify` ↔ `contributing.md` §Adversarial verification ↔
  ADR-0006. Canon: ADR + contributing; delivery: the two skills;
  `CLAUDE.md`: two lines.
- **Reproduce-first** — Autonomy-contract paragraph ("Reproduce before you
  fix", "Know when to stop") ↔ the `reproduce-first` skill (which contains
  the same "one workaround per problem" hard rule). Canon: the skill.
- **Config-cites-decision** — `CLAUDE.md` Conventions bullet ↔ the existing
  path rule ↔ contributing. The bullet can go; the rule already fires at the
  right moment.
- **PR ↔ issue linking** — `CLAUDE.md` bullet ↔ contributing §PR ↔ issue
  linking ↔ `/epic-kickoff` step 7 restatement ↔ PR template forced-choice
  block ↔ `issue-link-guard` failure message. Canon: contributing; delivery:
  template + gate message (both already exist at the right moments).

---

## 3 · The plan

Ordered so each step is independently valuable; enforcement status labeled
per D-004.

### 3.1 · Name the doctrine: a new ADR, "Instruction loading" (next free D-0NN)

The twin of D-004. Decision statement, roughly:

> **Every standing instruction declares its load moment** — one of the named
> tiers (always / path-scoped / on-demand skill or command / event-injected
> hook or gate message / mechanical) — and the always tier carries a
> **budget with a ledgered ceiling**. New rules default to the cheapest tier
> that still reaches the agent *before* the action they govern; promotion to
> a costlier tier cites the incident that demanded it (the lessons
> escalation path), and the budget gate makes growth a visible, deliberate
> diff — never accretion.

Also codified there: the **demotion path** (the missing counter-pressure) —
when a Tier-0 rule gains a mechanical enforcer whose message teaches the
recovery, its standing prose *shrinks to the index line* in the same PR that
lands the enforcer. Enforcement: the budget gate (3.2) for the ceiling; the
declaration itself is advisory, review-upheld — same honest split D-004 uses.

### 3.2 · Build the missing enforcement: a context-budget lane in `make verify`

The user's diagnosis is exact: compartmentalization exists but is not
*structurally enforced*. The repo's own doctrine says what to do with a rule
nobody catches — give it a gate. A new checker (pattern:
`scripts/check_context_budget.py`, `--self-test` per D-005, wired into
`make verify` so the meta-gate pins it):

- **Counts Tier 0**: `CLAUDE.md` + every `.claude/rules/*.md` lacking
  `paths:` + every skill frontmatter description + descriptions of commands
  without `disable-model-invocation` + the *worst-case* static text of
  `session-start.sh`. Fails over the ceiling. The ceiling lives in a
  four-rule ledger (D-004): stated maximum (proposal: **1,200 words core /
  1,600 hard fail**), a reason per over-budget entry, staleness fails loud,
  itemized never blanket.
- **Enforces tier declarations mechanically where it can**: a
  `.claude/rules/*.md` without `paths:` must be on the launch-tier ledger
  with a reason; a new command without `disable-model-invocation` likewise
  (`/checkpoint` is the seeded ledger entry — its file already argues why).
- Reports the full tier table on every run, so load growth shows up in
  diffs and review, not in vibes.

This is the only genuinely *new* machinery the plan needs; everything else
reuses proven mechanisms.

### 3.3 · The `CLAUDE.md` diet (per the §2 table)

The kept core (~900–1,000 words): identity → commands → **hard-rule index**
(one line per rule + "each is hook/CI-enforced; the block message names the
recovery") → **autonomy contract** → **router** ("when doing X, first read
Y" — extended with rows for the moved content) → code-style pointer →
ritual-command index. The hard rules keep Tier-0 *awareness* (an agent must
not plan around an action that will be denied) while the ~130 words of
per-rule detail move to the moment of violation — where the hooks already
deliver them today.

New path-scoped rules (Tier 1, ≤30 lines each per `rules/README.md`):

| Rule file | `paths:` | Carries (from `CLAUDE.md`) |
|---|---|---|
| `docs-conventions.md` | `docs/**` | status legend, stable IDs, canonicality, ADR-and-registry-together |
| `adr-work.md` | `docs/decisions/**` | the unlock protocol pointer, supersede-never-edit |
| `claude-md-hygiene.md` | `CLAUDE.md`, `.claude/**` | "Extending this file", pointer-over-import, harvest-candidate flagging |

### 3.4 · Just-in-time delivery for the commit/PR/release protocols

The user's worked example — "how to commit and PR gets its own instruction
place, ingested when it becomes relevant" — maps onto three mechanisms, in
order of preference:

1. **The gate message IS the instruction** (Tier 3 — already proven here).
   `guard-git.sh`'s zombie-push block delivers the full PR-lifecycle
   recovery protocol at push time; `issue-link-guard`'s failure text and the
   PR template's forced-choice block deliver the linking rules at PR time.
   Extend the pattern instead of inventing a new one: the *Repo workflow*
   prose about append-only PRs, close-direction, and box-ticking shrinks to
   index lines because its substance is already delivered by the enforcers.
2. **A `git-workflow` skill card** (Tier 2, ~40-word trigger) holding what
   the gates *can't* teach because it's needed slightly *before* the tool
   call: branch naming, commit-body story + trailers, when to open the PR,
   the `Closes` grammar. Canon stays in `contributing.md`; the card is the
   delivery vehicle, like `reproduce-first` is for its contributing section.
3. **A one-shot read-before-act gate** (new, optional — the "structurally
   enforced ingestion" the user asked about). A PreToolUse matcher on the
   first `gh pr create` / `mcp__github__create_pull_request` of a session
   exits 2 *once*, with the linking-conventions card inline in the block
   message, then writes a marker (the `UNLOCKED_ADRS` pattern) so the retry
   passes. The instruction is physically injected at the exact moment, with
   zero reliance on the model choosing to read. **Caution, from D-004's own
   alternatives-considered:** over-strict local blocks train workarounds —
   so: once per session, fail-open, suite-tested, and only at the PR-open
   moment (not every commit). Recommend piloting on exactly one moment
   before generalizing.

Note the residual D-004 already names: MCP/API operations bypass Bash-matcher
hooks. PreToolUse *can* match MCP tools by name — wiring the same guards for
`mcp__github__*` merge/push/PR tools closes a gap that exists today and is
Phase-0 verification work regardless of this plan.

### 3.5 · `session-start.sh` stays the dynamic briefer

It already embodies the target discipline ("every unconditional line taxes
every future session's context, forever"). Two conditional additions only:
a bootstrap pointer when `BOOTSTRAP.md` still exists, and a one-liner when
`docs/decisions/` files are dirty ("ADR edits are gated — /unlock-adr").
Nothing unconditional.

### 3.6 · Blueprint-level wiring (so seeded projects don't regrow it)

- **`BOOTSTRAP.md`**: the gate (step 5) runs the budget checker, so a
  seeded project *starts* within budget; the interview's module step notes
  each module's Tier-0 cost when it extends `CLAUDE.md`.
- **`HARVEST.md`**: the checklist gains one question — "did this change grow
  a Tier-0 surface, and did it declare its load moment?"
- **`lessons.md` escalation path**: gains its counterpart sentence — the
  demotion rule from 3.1.
- **`modules/*/MODULE.md`**: any `CLAUDE.md` extension a module makes states
  its word cost and tier.

---

## 4 · What must NOT move (the honest counterarguments)

- **The autonomy contract.** It governs how the agent decides *anything*,
  including whether to load more instructions. There is no event to hang it
  on: by the time a hook could fire, the wrong judgment was already made.
- **Hard-rule awareness.** An agent that first learns "never push to main"
  from a deny message has already built a wrong plan; the index line must
  stay at Tier 0 even though the detail moves. The compressed index is the
  compromise, not full removal.
- **The router.** On-demand loading only works if the dispatch table is
  always present. Cutting the router to save its ~180 words would break
  every other tier.
- **Non-Claude agents** (`AGENTS.md` consumers) never load `.claude/` at
  all — their contract is docs + CI. So compartmentalization must move
  *salience*, never *canon*: everything stays canonical in
  `docs/process/contributing.md`; the tiers only decide when Claude gets
  reminded. (This also means the diet makes `CLAUDE.md` *more* honest to its
  own charter: "a map to the real docs, not a duplicate of them.")
- **Moved ≠ saved.** Skill descriptions and hook outputs still cost context;
  the budget checker counts all Tier-0 surfaces precisely so savings can't
  be faked by relocation.
- **Compaction.** After compaction, `CLAUDE.md` is re-injected but a
  path-rule or skill that fired mid-task may not survive. The existing
  `/checkpoint` + PreCompact machinery is the mitigation; worth one line in
  the context-engineering skill ("re-trigger the rules you were working
  under after resume").

## 5 · Known unknowns → Phase 0 verification spike

Per the repo's own reproduce-first doctrine, the plan's platform assumptions
get verified on the pinned Claude Code version before anything is built:

1. **The new-file gap**: does a `paths:` rule fire when the agent *creates*
   a matching file? (`rules/README.md` already flags this as
   community-reported, unverified.)
2. **PreToolUse matching on MCP tool names** (for 3.4's gap-closing).
3. **Which hook events inject non-blocking context** on the current version
   (the PreCompact header already notes stdout delivery is
   version-dependent) — determines whether Tier 3 has a nudge channel or
   only the exit-2 block channel.
4. **Frontmatter behavior**: `disable-model-invocation` semantics for
   skills vs commands; whether command `description` fields load for
   user-invocable commands (this session's evidence says yes for
   `/checkpoint`, no for the 9 disabled ones — re-confirm on the target
   version).

Each answer lands as a dated note issue; a "no" reroutes the affected
proposal to the hook/gate mechanism, which works on every version.

## 6 · Rated proposal map

Savings = estimated Tier-0 words removed. Risk = chance the change causes a
rule to miss its moment. Effort in issue-sized units.

| # | Proposal | Savings | Risk | Effort | Depends on |
|---|---|---|---|---|---|
| 3.1 | Loading-doctrine ADR | 0 (enables the rest) | none | 1 | — |
| 3.2 | Context-budget gate | 0 directly; stops regrowth | low | 2–3 | 3.1 |
| 3.3 | `CLAUDE.md` diet + 3 path rules | ~1,600 | medium (mitigated by index lines + Phase 0) | 3–4 | 3.1, Phase 0 |
| 3.4 | Just-in-time git/PR delivery | ~450 of the 3.3 total | low (mechanisms proven) | 2–3 | Phase 0 |
| 3.5 | Session-start additions | −0 (conditional only) | none | 1 | — |
| 3.6 | Blueprint wiring | future-proofing | low | 2 | 3.2 |

**Suggested sequence:** Phase 0 spike → 3.1 + 3.2 (measurement first — no
behavior change, immediate visibility) → 3.3 + 3.4 as one epic (the diet and
the delivery must land together: never delete prose before its cheaper tier
exists) → 3.5 + 3.6. Per repo conventions this is one epic with ~6 sub-issues
plus the ADR.

## How this was produced

Single-agent analysis (one session, 2026-07-24): full read of `CLAUDE.md`,
`AGENTS.md`, all 10 commands, all 5 skills, all 5 hooks, `settings.json`,
`contributing.md`, ADR-0004, the records/direction surfaces, and
`BOOTSTRAP.md`/`HARVEST.md`; word counts measured with `wc -w`/`awk` at
commit `3c71795` (token figures are ×1.3 estimates, not measured). Loading
behaviors marked "confirmed" were observed empirically **in this session on
the web harness**: launch-tier rules README present at start, the path rule
firing on `settings.json` read, 9 `disable-model-invocation` commands absent
from context, 5 skill descriptions present. Hook-injection channels beyond
exit-2 stderr were **not** verified (hence Phase 0). A planned multi-agent
fan-out with adversarial verification was declined by the operator;
per the adversarial-verification protocol this had a Grade-1 self-check only
(counts and quotes re-opened before writing) — **no independent (Grade-2)
pass ran**; the proposal stands: one fresh agent refuting §1's tier claims
and §3's mechanism feasibility would roughly double this task's cost.
