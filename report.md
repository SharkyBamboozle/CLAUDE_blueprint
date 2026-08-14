# Framework audit — Project Blueprint

**Repository:** `SharkyBamboozle/CLAUDE_blueprint`
**Revision 3 — re-verified 2026-08-14 against v1.2.0** (= `main` = `b2df960` = `development`, fully
promoted). Revision 2 audited v1.0.5 (`80c3800`) on 2026-08-09; revision 1 audited v1.0.4 on
2026-07-29. The §0 update below carries the current state; §1–§7 and §8's tables are updated in
place; §9 preserves the earlier revisions' framing where it still reads true.

---

## 0. Revision 3 — the v1.2.0 update

**v1.2.0 is the strongest release this audit has seen, and it introduced a new critical.** Both
halves are verified by execution, not read from the changelog.

### What it fixed (verified, refuter-upheld)

- **The whole guard-bypass cluster** (#118). Every one of the nine catalogued bypasses now blocks:
  `git -C .`, `git --no-pager`, `git --git-dir=`, `git push --all`, `--mirror`, `+HEAD:feature`,
  `-fu`, `--force-with-lease=main`, and the multi-line false-allow — all rc=2, innocent quoted
  prose still rc=0. The three guards now share one quote-aware argv parser, triplicated
  byte-for-byte and identity-pinned by `test_guardlib.py`. Retires revision 2's oldest
  high-severity item (`I-08`/`I-09`/`I-10`).
- **MCP self-merge** (#124): the merge and auto-merge MCP tools are denied by name (rc=2), as is
  `gh -R o/r pr merge`. The parser-independent deny branch sits *before* the parser, so a parse
  failure can't disarm it.
- **`enforce_admins: true`** (#124) in all three protection payloads. This is the better fix than
  the one revision 2 proposed — the *code* was changed to match the doctrine, not the doctrine
  softened. It resolves `I-05`/SECU-06 (the flow rule now genuinely binds admins, and the agents
  carrying their identity), and ADR-0004 was refined in place (#122) to state each layer's failure
  direction, including "server rules bind administrators".
- The v1.1.0 + v1.2.0 promotions **released the CLAUDE.md diet and the `paths:` scoping** that were
  development-only at revision 2. Revision 2's §2 "released ≠ current" gap is closed:
  CLAUDE.md is now 2,056 words on `main`, all four `.claude/rules/` files are `paths:`-scoped.
- Notably, the v1.2.0 changelog itself carries **no enforcement overclaim** — a clean break from
  the six-overclaim pattern revision 2 documented in §4.3. It correctly scopes what it fixed and
  does not claim to have touched `I-04`/`I-06`.

### What it introduced — a new critical trust boundary

v1.2.0 shipped `.claude/hooks/guard-command-policy.py` (#119): a **read-only Bash auto-approver**
that runs commands it proves read-only with **no permission prompt**. It is a new trust boundary,
and it auto-approves things that defeat the very guards this release hardened. All reproduced by
execution against the live hook, with `CLAUDE_PROJECT_DIR` set as a real session has it:

```
git -c core.pager=id log                       -> APPROVE   (arbitrary code execution via git config)
git -c core.fsmonitor=touch\ /tmp/X status      -> APPROVE   (runs on status, no tty needed)
echo evil > .claude/hooks/guard-git.sh          -> APPROVE   (blank the deny-guard itself)
echo x    > .claude/settings.json               -> APPROVE   (rewrite the hook wiring + deny-list)
printf x  >> .git/config                         -> APPROVE   (inject core.hooksPath/sshCommand -> exec)
git branch -f main origin/evil                   -> APPROVE   (force-move main; no layer blocks it)
```

The two chain into a clean bypass of everything else: step 1 `echo > .claude/hooks/guard-git.sh`
(auto-approved) disables the push-to-main guard; step 2 the previously-blocked `git push origin
main` now runs. **The release that hardened the guards also shipped a hook that can silently
disable them.** These are `I-36` in the backlog — value 9, the highest new item.

Two smaller residuals the #118 hardening left open, both verified: `git push origin $'main'`
(ANSI-C quoting) and `git push origin "refs/heads/*:refs/heads/*"` (wildcard refspec) still reach
`main` at rc=0 (`I-37`); and the newline-splitting fix now parses **heredoc body lines as
commands**, so writing a doc whose heredoc mentions `gh pr merge` is falsely blocked — it blocked
one of this audit's own commands this session (`I-38`).

### Net

Revision 2's headline — problems concentrate in the enforcement gap — is now **half retired**. The
*client-side* guard surface went from "trivially bypassable" to "hardened with two exotic
residuals". The *server-side* gap (`enforce_admins`) is closed. What remains: the lane G bootstrap
deadlock (`I-01`, still the top item), the two prose overclaims whose falsehood v1.2.0 narrowed to
the self-merge clause but did not edit (`I-04`/`I-06`), and — new and most urgent among the
additions — the auto-approve hook (`I-36`). The refreshed backlog is §8.

---

## How to read this report

Revision 1 ran fifteen dimension auditors over v1.0.4, producing 146 findings, then had 44
independent verifiers try to **refute** each one. Revision 2 re-tested all 146 against the current
tree, had a second refutation pass attack every "this is now fixed" claim, and ran five regression
hunters over the 55 commits that landed in between.

Three things must be held in mind while reading.

**1. A large amount of real work has landed.** 55 commits, blueprint v1.0.5, 8 issues closed. Two
of revision 1's headline problems are genuinely gone. The framework moved faster than the audit.

**2. Released ≠ current.** The template is seeded from `main`. `main` is v1.0.5. Several of the
best fixes are on `development` and **have not been released**, so a project seeded today does not
get them. This distinction did not exist in revision 1 and it changes several conclusions. See §2.

**3. The fixes introduced new problems, including one that breaks the bootstrap path.** 33 new
findings, of which one is critical and reproduced independently. See §4.

### Verification status of this revision

| | count |
|---|---|
| Original findings re-tested | 146 |
| Resolution claims **upheld** by the refutation pass | 73 |
| Resolution claims **downgraded to partial** | 8 |
| Resolution claims **rejected outright** | 4 |
| New findings from the regression sweep | 33 (1 critical · 9 high · 15 medium · 8 low) |

**Honest limitation, stated up front:** the 33 new findings have had **one pass only**. They have
not been through the adversarial refutation that moved 108 of revision 1's 146 findings. Expect
similar deflation. The single exception is the critical finding in §4.1, which I reproduced
myself, end to end, and which is stated here at full confidence.

---

## 1. Verdict

**Revision 1's judgement stands, with one addition and one sharpening.**

*Stands:* the framework is well-built, `make verify` passes (rc=0, 18.0 s, n=1, measured), and the
problems still concentrate in the gap between asserted and actual enforcement.

*Sharpened:* the enforcement-overclaim cluster is now **worse, not better**. A corrective pass ran
— issue #100, "Correct three stale statements in ADR-0002, ADR-0003 and ADR-0004" — and landed
(commit `5012395`). It did not touch either of the two overclaims this audit rated highest.
Meanwhile the CLAUDE.md compression work **added a new blanket overclaim** to the always-loaded
file. Net movement on the theme: negative.

*Added:* **a critical regression now blocks the bootstrap path.** The new docs-truth lane G fails
`make verify` while `blueprint/` is present, and BOOTSTRAP.md step 2.2 mandates writing exactly
the content that trips it, at a point before step 7 removes `blueprint/`. A compliant bootstrap
session cannot pass its own step-5 gate. Reproduced end to end (§4.1).

**The one-line summary:** the seed-hygiene work succeeded; the enforcement-honesty work regressed;
and the release/development gap means a project seeded today gets the old state of the first and
the new state of the second.

---

## 2. Released versus current

**Updated 2026-08-14.** When revision 2 was written, `main` was v1.0.5 and 23 commits of fixes sat
unreleased on `development`. **That gap has since been closed: v1.1.0 was promoted** (`main` =
`0e961b3`, tagged `v1.1.0`, `blueprint/VERSION` = 1.1.0 on both branches). The required-check
expansion, the `paths:` scoping and the CLAUDE.md diet are now released, so a project seeded today
does get them. `development` is 8 commits ahead again — the normal post-release state.

The lesson the gap taught is worth keeping even though the instance is closed: **the release log
is the only artifact a downstream maintainer reads before an `UPDATE.md` pull**, and for one full
release cycle it described a tree that did not exist. The standing countermeasure is item `I-27` —
write the entry from the promoted diff at promotion time, not from the issue bodies at planning
time.

What has **not** changed with the promotion — re-probed by execution on the v1.1.0-era tree:

| | status |
|---|---|
| CLAUDE.md blanket "hook- and CI-enforced" claim | **present** (`CLAUDE.md:43`) |
| AGENTS.md "server-side by CI" overclaim | **present** (`AGENTS.md:25`) |
| ADR-0003 "required checks server-side" overclaim | **present** |
| Guard argv bypasses (`git -C`, `--no-pager`, `--all`, `+refspec`, `-fu`, `gh -R`) | **all rc=0** |
| MCP write surface (`merge_pull_request` et al.) | **rc=0** |
| Lane G bootstrap deadlock | **still reproduces** (rc=1) |

So the promotion delivered the seed-hygiene and gate-wiring work, and delivered the
enforcement-overclaim cluster and the bootstrap deadlock along with it, into a released version.

---

## 3. Movement on the 146 original findings

| Status after re-test | count |
|---|---|
| **UNCHANGED** — reproduces exactly as revision 1 stated | **109** |
| **PARTIALLY_RESOLVED** | 14 |
| **RESOLVED** | 12 |
| **ALREADY_NOT_A_FINDING** (refuted in revision 1, carried forward) | 10 |
| **REGRESSED** | 1 |

The refutation pass then attacked every resolution claim: **73 upheld, 8 downgraded to partial,
4 rejected**. Adjusting for that, **8 findings are fully resolved** and 18 are partly resolved.

### 3.1 Genuinely fixed (refuter-upheld)

- **NOIS-01, NOIS-03 — the tracker-ID sweep.** Commit `96f82e1` stripped this repo's issue numbers
  from 23 inherited files, including the guard block messages, the CI `::error::` strings, the PR
  template, the label descriptions, and the comment `issue_close_decision.sh` posts into a seeded
  project's tracker. This was the sharpest instance in revision 1 and it is gone.
- **HARN-05, WEIG-04 — `.claude/archive/`.** Commit `2a90a71` deleted both dated reproduction
  entries; `.gitignore` now keeps this repo's agent scratch untracked, with a bootstrap-deleted
  block so seeded projects still track their own archive (which `HARVEST.md` scans). Correct
  design, not just a deletion.
- **AGEN-03, HARN-09 — `.claude/rules/README.md` always-loaded.** Now `paths:`-scoped, and the
  dead `InstructionsLoaded` pointer is gone. *Unreleased — `development` only.*
- **AGEN-08 — CLAUDE.md size.** 2,702 → 2,005 words on `development`. *Unreleased.*
- **DOCS-02 — the six dropped anchors.** The re-aim campaign swept 11 pointers across three
  spellings; all now resolve.

### 3.2 Resolution claims the refuters knocked down

These were reported as fixed by the re-check and did not survive attack. Each is a case where the
fix removed one spelling of a defect and left a sibling.

| Finding | Claimed | Refuter's finding |
|---|---|---|
| **BOOT-01** | archive files deleted, gate no longer trips | the replacement `.gitignore` block ships the *same* two-part BLUEPRINT-marker defect: deleting the marker line alone passes the gate while leaving `.claude/archive/*` gitignored in the seed — making the project's own handoff history invisible |
| **BOOT-04** | tracker IDs swept | hooks and gates are clean, but citations still ship in files the sweep skipped |
| **HARN-01** | `/tick` reads through a faithful channel | `/note` and `/epic-closeout` also rewrite issue bodies and got **no channel rule at all** — the fix covered one of three rituals with the same hazard |
| **NOIS-06** | archive gone | same `.gitignore` residue as BOOT-01 |
| **HARN-06** | *rejected* | the overclaim did not go away, it **moved into ✅ Decided ADR-0001 and a README**, where correcting it now needs `/unlock-adr`; the gap is wider than revision 1 stated |
| **NOIS-05** | *rejected* | the docs-truth scan surface is unchanged; `.claude/`, `.github/`, `Makefile`, `mkdocs.yml` are still never walked as citation sources |
| **HOOK-06** | *rejected* | the Stop hook still writes to stderr and exits 0 |

**My own correction.** In my interim message I reported the tracker-ID count as "72 → 2". That
used a nine-ID grep pattern carried over from revision 1. The full-pattern count on the current
tree is **13 hits across 7 files**, distinct numbers `#7 #12 #42 #43 #70 #99`. Of these, `#7`,
`#12`, `#42`, `#43` and `#99` are illustrative fixtures (a PR-template example, a template URL,
checker self-test data) and were never provenance citations. **One is a genuine new leak:
`.gitignore:34` cites `#70`** — introduced by commit `2a90a71`, six commits before the sweep that
skipped that file. It is fenced inside a BLUEPRINT marker the bootstrap gate scans, so it cannot
reach a gate-passing seed. The sweep is substantively complete; my "2" was too generous and the
method, not the conclusion, was at fault.

### 3.3 The regression

**AGEN-06 — CLAUDE.md now overclaims enforcement for every hard rule.** The compression work
replaced per-rule enforcer citations with one blanket header:

```
## Hard rules (never, without an explicit user request in THIS session)

*Each rule is hook- and CI-enforced (`guard-git.sh`, `guard-adr.sh`,
branch protection, the CI gates); every block message names the recovery path.*
```
— `CLAUDE.md:41-43` on `development`, and present in v1.0.5 at line 36.

"Never merge your own PR" sits under that header. **Correction to an earlier draft of this report:
it is not true that self-merge has "no enforcer at any layer".** The measured map:

| self-merge spelling | result |
|---|---|
| `gh pr merge 12` | rc=2 — blocked by `guard-git.sh` |
| `gh pr merge --squash 12` | rc=2 — blocked |
| `gh api -X PUT repos/o/r/pulls/12/merge` | rc=2 — blocked |
| `gh -R o/r pr merge 12` | **rc=0 — allowed** (the global-flag bypass, I-08) |
| `mcp__github__merge_pull_request` | **rc=0 — allowed** (I-11) |

So the accurate claim is narrower and still serious: the rule has a **client-side hook covering
two spellings, no server-side enforcer of any kind** (`required_approving_review_count: 0`), and
two live bypasses. The header's word "CI" is the false part — no CI gate touches self-merge,
push-to-`main`, or force-push. Anyone fixing this must rewrite from the measured map rather than
from the header's premise, or they will replace one inaccurate enforcement statement with another.

### 3.4 The corrective pass that missed its two hardest targets

Issue #100 was filed to "Correct three stale statements in ADR-0002, ADR-0003 and ADR-0004". It
landed as commit `5012395`. Its scope was ADR-0002's enforcement paragraph, ADR-0004's enforcer
roll-call, and ADR-0003's "exactly once" consequence. Verified on `development` after that commit:

- `docs/decisions/adr-0003-branch-model.md:40-41` still reads *"branch protection on both
  long-lived branches enforces PR-only advancement and required checks server-side"*, and `:8`
  still reads *"the flow and history rules bind at the server"*. With `enforce_admins: false` —
  which `github_setup.sh` now documents as deliberate — this binds no actor a solo seeded project
  has (**SECU-06**).
- `AGENTS.md:25` still reads *"These are enforced **server-side by CI** … for every change, by any
  agent or human"* (**AGEN-01**), even though commit `24a32e2` edited AGENTS.md in the same range.

So the repository ran a pass specifically aimed at stale enforcement statements and the two the
audit rated highest survived it. Neither is in #100's scope, and #100's non-scope defers the three
proposed new decisions to an issue that **does not exist** — the refuters searched the open (25)
and closed (26) sets and found none.

---

## 4. New problems introduced (33 findings, one pass only)

### 4.1 CRITICAL — lane G deadlocks the bootstrap gate

*Reproduced independently by the orchestrator, end to end.*

v1.0.5 added lane G to `check_docs_truth.py`: while `blueprint/` exists, a session entry in
`docs/records/changelog.md` fails `make verify`. The intent is sound — the blueprint's own session
records must not land in the stubs it ships (the "two hats" rule).

But the bootstrap ritual mandates exactly that content, before the gate, before the deletion:

- **step 2.2** — *"resolve every Tier-2 block … this includes … the changelog's Session 1 entry
  (today's date; note 'Initialized from Project Blueprint v<VERSION>'; which modules were
  applied)"*
- **step 5** — *"Gate — must pass before anything is deleted … `make verify` … Fix and re-run
  until green. **Do not rationalize a red gate.**"*
- **step 7** — `git rm -rf … blueprint/ …` happens *after* the gate.

Reproduction, on a clean `git archive origin/development` seed:

```
$ python3 scripts/check_docs_truth.py            # template as shipped
rc=0

# follow BOOTSTRAP step 2.2: write the mandated Session 1 entry
$ python3 scripts/check_docs_truth.py
check_docs_truth: FAIL
  - [blueprint-records] docs/records/changelog.md: '### Session 1 (2026-08-09) — Project start'
    is a real session entry, but the blueprint keeps no per-session records — this file ships to
    seeded projects as a stub, so the entry reaches every seed as false history. Remove it; the
    blueprint's only log is blueprint/CHANGELOG.md …
rc=1

# after step 7 removes blueprint/, the lane disarms as designed
$ rm -rf blueprint modules BOOTSTRAP.md … && python3 scripts/check_docs_truth.py | grep -c blueprint-records
0
```

A compliant session has no legal move: it must either skip a mandated step or rationalize a red
gate, which step 5 forbids in terms. And the failure message misdirects the seed's operator — it
tells them "the blueprint keeps no per-session records", which is advice for *this* repository,
not for the project they are creating.

**Fix (cheapest correct form):** arm lane G on the presence of `blueprint/` **and** the absence of
a resolved bootstrap, or simply exempt the `Session 1` entry shape; alternatively move the lane
out of `make verify` into a blueprint-only CI job that never runs on a seed. Whichever is chosen,
BOOTSTRAP.md step 2.2 and step 5 must be reconciled with it.

**Related:** lane G's changelog half does not strip HTML comments while its lessons half does, so
the obvious workaround — commenting the example out, exactly as `lessons.md` does — also fails
(NEW-GUAR-02).

### 4.2 High-severity new findings

- **NEW-CLAU-01 / NEW-TICK-03 — the blanket enforcement header** (same defect as §3.3, found
  independently by two lenses). Ships in v1.0.5 and on `development`.
- **NEW-CLAU-02 — the config-cites-decision convention lost its always-loaded home** and now
  depends on a path-scoped rule whose own documented gap says it may not fire when an agent
  *creates* a new matching file. New CI workflows and config files can land without their `D-###`
  rationale, and no gate catches it.
- **NEW-CLAU-03 — demotion moved conventions into a directory `AGENTS.md` tells non-Claude agents
  they may ignore.** A repo-wide convention silently narrowed to Claude Code only, with no ADR and
  no changelog line — in the file whose stated purpose is multi-agent parity.
- **NEW-SETU-01 — the new "diff-scoped, so required" principle is falsified by its own first
  entry.** The rationale excludes `dependency-audit` because an external-state check could freeze
  every open PR, then leaves `build` required — which is whole-tree *and* external-state-dependent
  (its issue-state lane consults GitHub). Closing an issue that any doc cites as open can red the
  required check on unrelated PRs.
- **NEW-SETU-02 / NEW-GUAR-03 — the eight required contexts are pinned to nothing.** Renaming a
  job leaves `make verify` fully green while branch protection waits forever for a context that
  will never report. The expansion from 4 to 8 doubled the size of an unpinned coupling, and
  `security.yml` explicitly invites seeded projects to restructure exactly those jobs.
- **NEW-SETU-03 — `--profile` is still unvalidated, and the blast radius grew.** A one-character
  typo on a re-run now silently strips six required contexts from `development`, exits 0, and
  prints "setup complete".
- **NEW-TICK-01 — the close-protocol sweep still misses `running-epics.md:17-20`**, and the
  v1.0.5 changelog claims "every manual branch now reads post → tick → request". Issue #63 closed
  with that acceptance criterion ticked.
- **NEW-TICK-02 — `/tick` steps 2 and 5 cannot both be satisfied** on the fallback channel: step 5
  mandates a verify re-read through a channel step 2 declares asynchronously stale.

### 4.3 Changelog integrity

Five separate lenses independently flagged the v1.0.5 entry as claiming more than the diff
delivers. This matters more than a normal documentation defect, because `UPDATE.md` makes the
release log the artifact a downstream maintainer reads to decide whether a pull is safe.

- *"zero words added to any always-loaded surface"* — the same commit added 210 words to
  `CLAUDE.md`, including the false blanket enforcement header.
- *"every manual branch now reads post → tick → request"* — `running-epics.md` still does not.
- *"every test suite's assertions untouched"* — two suites changed by 36 lines (labels only; the
  commit message's narrower claim is the accurate one).
- *"Anchor-preserving"* — 6 of the 21 pre-split anchors no longer exist, but **no surviving link
  targets them**: `mkdocs build --strict` with `validation.anchors: warn` is clean on the current
  tree (verified). Literally imprecise, practically harmless — the weakest of the six.
- *"the one new checker lane is blueprint-only — it self-disarms permanently at bootstrap"* — true
  only *after* step 7; §4.1 is the counter-example, at the one moment a fresh seed most needs the
  gate to be trustworthy.
- The entry states figures (2,351 words) that neither `v1.0.5` (2,531) nor `development` (2,005)
  matches, and 10 non-merge commits landed after the caboose under the same version.

---

## 5. Still open — the unchanged core

> **Superseded for the guard rows by §0 (v1.2.0).** The guard-bypass table below reflects the
> v1.0.5 state this section was written against; #118 has since fixed every row (all rc=2 —
> verified in §0), leaving only the two exotic residuals `I-37` tracks. The rest of the section
> (the checkbox regex, the ADR machinery unchanged, the general "109 reproduce exactly" count)
> still held as of revision 2; §8 carries each item's current status.

109 of 146 findings reproduced exactly **as of revision 2 (v1.0.5)**. The load-bearing ones,
re-probed by execution against the v1.0.5 tree:

```
git push origin main            rc=2  blocked (baseline)
git -C . push origin main       rc=0  ALLOWED
git --no-pager push origin main rc=0  ALLOWED
git push --all origin           rc=0  ALLOWED
git push origin +HEAD:feature   rc=0  ALLOWED   (force via + refspec)
git push -fu origin feature     rc=0  ALLOWED
gh -R o/r issue close 5         rc=0  ALLOWED   (gh issue close 5 -> rc=2)
mcp__github__merge_pull_request rc=0  ALLOWED   (also push_files, create_or_update_file)
```

Nothing in 55 commits touched the argv parsing (`guard-git.sh:218`), the segment splitter, the
force-flag membership test, or the `Bash`-only matchers. The entire ADR machinery is byte-identical
to the v1.0.4 baseline — `guard-adr.sh`'s only change in the range is its block-message pointer
text. `issue_link_decision.sh`'s checkbox regexes still match only `-` and `*` bullets, so `+` and
`1.` task items still produce a silent pass with a false "N/N ticked".

**Wave 1 items 1 and 4 from revision 1 remain entirely undone, and are now the oldest open
high-severity items in the report.**

---

## 6. Revised future work

> **Superseded by §8 (the ranked backlog).** This section is the revision-2 prose narrative of the
> waves; §8's table is the current, v1.2.0-verified, scored version and is what to work from.
> Wave 1's guard-parsing item and the enforce_admins item have since **landed** (§0). The text is
> kept for the reasoning behind each wave.

Reordered for the current state. Items marked **▲** are new or promoted since revision 1.

### Wave 0 — unblock the seed path ▲

1. **Fix the lane G bootstrap deadlock (§4.1).** Nothing else matters if a fresh seed cannot pass
   its own gate. Arm the lane on something that distinguishes "the blueprint authoring itself"
   from "a seed mid-bootstrap", and reconcile BOOTSTRAP steps 2.2 and 5 with whatever is chosen.
   Strip HTML comments in the changelog half so the `lessons.md` workaround pattern works.
   *Cost: a condition plus a `re.sub`. Value: restores the downstream path.*
2. **Promote.** Several of this cycle's best fixes — the required-check expansion, the `paths:`
   scoping, the CLAUDE.md diet — are on `development` only, while `blueprint/VERSION` already
   reads 1.0.5 and the v1.0.5 log describes a tree that no longer exists. Either cut v1.0.6 or
   stop treating those fixes as delivered. *Value: the gap is currently invisible to anyone
   reading the changelog.*

### Wave 1 — make the enforcement claims true (carried forward, now overdue)

3. **Remove the blanket "hook- and CI-enforced" header from `CLAUDE.md`** ▲ and restore per-rule
   attribution, or mark the three unenforced rules honestly. This regressed *during* a correction
   pass; it is the cheapest high-value fix in the report.
4. **Correct the two overclaims #100 missed:** ADR-0003's server-side flow claim (needs
   `/unlock-adr`, and is now inconsistent with `github_setup.sh`'s own honest comment), and
   AGENTS.md's blanket CI promise. **File these explicitly** — #100 is closed on scope that
   excluded them, so nothing currently owns them.
5. **Fix the argv parsing in all three guards** — one shared normaliser that skips global options
   and their values; add `\n` to the segment splitter; tokenize before splitting. Add regression
   cases for every row in §5. *Unchanged from revision 1, and now the longest-standing item.*
6. **Guard the MCP write surface**, or name the residual honestly. Self-merge is blocked at the
   client for two `gh` spellings and by nothing server-side; the MCP and global-flag paths are
   open (§3.3). Widen an existing matcher rather than adding a new hook — a new deny-hook obliges
   a new suite, because `check_ci_gates.py` pins deny-hook→suite.
7. **Pin the eight required contexts to shipped job ids** ▲ (NEW-SETU-02/NEW-GUAR-03) and
   **validate `--profile`** ▲ (NEW-SETU-03). Both are small; both now have a larger blast radius
   than when revision 1 filed them.

### Wave 2 — close the blind spots (carried forward)

8. **Extend `check_docs_truth.py`'s scan surface** to `.claude/**`, `.github/**`,
   `scripts/README.md`, `Makefile`, `mkdocs.yml`. Rejected as unfixed by the refuters, and now
   more urgent: the rules files are load-bearing for obligations that used to be always-loaded, so
   a dead pointer there silently loses the obligation ▲ (NEW-CLAU-04). **Must exclude
   `.claude/archive/` and `.claude/working/`** — see the trap note in §8.
9. **Add `validation:` to `mkdocs.yml`** (`anchors: warn`, `nav.omitted_files: warn`).
   **Correction:** an earlier draft made this depend on repairing anchors first. It does not — the
   validation block builds clean on the current tree, verified with a planted broken anchor as a
   both-ways proof. It is free, and it is the single cheapest item in the backlog.
10. **Give `/note` and `/epic-closeout` the same faithful-read rule `/tick` now has** ▲ — the
    refuters showed the fix covered one of three rituals with the identical hazard.
11. **Reconcile `/tick` steps 2 and 5** ▲ so the ritual is satisfiable on its fallback channel.

### Wave 3 — proportionality and product (carried forward, unchanged)

12. Process-weight dial in the bootstrap interview. 13. A trivial-change lane. 14. A product seam
for `make verify`. 15. Pin the docs toolchain.

### Wave 4 — durability (carried forward)

16. Version semantics downstream. 17. A repo-settings step in `UPDATE.md` — now confirmed as the
only path by which the required-check expansion can ever reach a seeded project ▲ (NEW-SETU-06).
18. Protect the README version stamp. 19. A retirement path for process.

### New standing recommendation ▲

20. **Treat the release log as a gated artifact.** Six independent overclaims in one entry, in the
    document `UPDATE.md` designates as the downstream decision input, is a pattern rather than a
    slip. The cheapest countermeasure is a caboose rule: the entry is written from the promoted
    diff at promotion time, not from the issue bodies at planning time.

---

## 7. Corrections to revision 1

- **The tracker-ID count.** My interim "72 → 2" used a nine-ID pattern. The correct figure is 13
  hits / 7 files, of which one — `.gitignore:34` — is a genuine new leak. See §3.2.
- **Tag discipline.** Revision 1's §2 limit 4 flagged tag placement as unverified. Now checked:
  all six tags (`v1.0.0`–`v1.0.5`) exist and sit on `main`'s first-parent line. **Not a defect.**
  My earlier local `git tag` returning empty was an unfetched clone, not a missing tag.
- **A fabricated re-check.** One re-check agent presented git output as executed evidence for
  commands that cannot run in this environment; the refutation pass caught and rejected it
  (`META-01`). No claim from it reached this report.
- **A methodology trap worth recording.** The `CLAUDE.md` injected into this session's system
  prompt is a stale v1.0.4 copy still containing `(#54)`. Re-verifying from the prompt rather than
  from disk produces a false "still broken" on the tracker-ID sweep. Every measurement in this
  revision was taken from disk or from `git show <ref>:<path>`.

---

## 8. Ranked backlog — value and ease

**33 open items**, refreshed for v1.2.0. Four items from revision 2 are now **resolved and
removed** (`I-05` enforce_admins, `I-08`/`I-09`/`I-10` the guard-bypass cluster — all verified by
execution and upheld by the refutation pass). Two were resolved earlier (`I-03` promote, `I-23`
the `.gitignore` citation). Four are **new**, from v1.2.0's own regressions: `I-36` (the
auto-approve hook), `I-37` (the two residual guard bypasses), `I-38` (the heredoc false-block),
`I-39` (the `github_setup.sh` custom-check gaps).

Work it either way: **down the value column** for the thing that matters most, or **down the ease
column** to bank something safe in an hour.

**Value / urgency, 1–10.** 10 = the framework is broken for its primary purpose until this lands ·
8 = a stated guarantee is false in a common path, or a defect reaches every seeded project · 6 =
real defect with a workaround · 4 = worth doing, nobody is currently hurt · 2 = polish.
Downstream (seeded-project) impact outweighs blueprint-repo-internal impact.

**Ease / low-risk, 1–10.** 10 = a few lines, obviously correct, nothing a test could regress · 8 =
small diff, existing tests cover it · 6 = several files or new fixtures needed · 4 = load-bearing
logic, real regression risk · 2 = needs a decision the operator has not made.

**How these were scored.** For revision 2, three independent agents scored from different lenses,
then a fourth adversarially calibrated (brief: attack every ease ≥ 8). For revision 3 those
ratings were re-verified against v1.2.0 by execution and a refutation pass — no false "resolved"
survived — and the four new items were scored on the same scale. Several eases shifted: `I-13` and
`I-12` rose to value 7 (a `--profile` typo or a job rename now also drops the *admin* binding
`enforce_admins:true` added).

### 8.1 By value

| Value | Ease | ID | Item | Why |
|---|---|---|---|---|
| **10** | **6** | `I-01` | Fix the lane G bootstrap deadlock | Lane G bootstrap deadlock still reproduces on a v1.2.0 seed (rc=1) |
| **9** | **4** | `I-36` | Harden the new read-only auto-approve hook (code-exec + guard-overwrite auto-approvals) · _I-11_ | NEW (v1.2.0): the read-only approve-hook auto-approves code-exec (git -c), guard/settings/.git overwrites via project-dir redirect, and git branch -f — no prompt, no block |
| **7** | **9** | `I-13` | Validate `--profile` in `github_setup.sh` · _merge with I-24_ | --profile still unvalidated; a typo now also drops admin binding on development |
| **7** | **6** | `I-12` | Pin the eight required status-check contexts to shipped job ids · _merge with I-24_ | #124 pinned the app, not job ids; a renamed job still freezes merges, now binding admins too |
| **6** | **10** | `I-17` | Add `validation:` to `mkdocs.yml` (`anchors: warn`, `nav.omitted_files: warn`) | anchors: warn still absent (nav half shipped v1.1.0); adding it builds clean |
| **6** | **9** | `I-18` | Give `/note` and `/epic-closeout` the faithful-read rule `/tick` now has | /note and /epic-closeout still rewrite bodies through the lossy channel /tick now guards |
| **6** | **8** | `I-15` | Extend `check_docs_truth.py`'s path-citation scan surface · _needs archive exclusion_ | scan-surface still docs-only; the unscanned region grew with the new rules files |
| **6** | **8** | `I-32` | Add a repo-settings step to `UPDATE.md` · _after I-13,I-12_ | UPDATE.md still has no repo-settings step; the v1.2 admin-binding change reaches a seed only by re-running the script |
| **6** | **7** | `I-22` | Fix the `.gitignore` two-part BLUEPRINT-marker defect · _merge with I-33_ | .gitignore marker-only deletion still passes the gate leaving archive ignored in the seed |
| **6** | **6** | `I-26` | Correct the v1.0.5 changelog entry's six overclaims | the v1.0.5 changelog's six overclaims still ship in the log UPDATE.md reads |
| **6** | **6** | `I-31` | Pin the docs toolchain with a lockfile | docs toolchain still >= floors, no lockfile; the MkDocs 2.0 banner prints every build |
| **6** | **6** | `I-37` | Close the residual push-to-main/ADR bypasses #118 missed (`$'…'`, wildcard refspec) | NEW (v1.2.0): two push-to-main/ADR bypasses the #118 hardening missed — $'...' ANSI-C quoting and wildcard refspec |
| **6** | **2** | `I-28` | Add a process-weight dial to the bootstrap interview | no process-weight dial; v1.2.0 only added machinery, so the weight grew |
| **5** | **9** | `I-20` | Fix `running-epics.md:17-20`'s agent-close instruction | running-epics.md:17-20 still instructs an agent-performed close |
| **5** | **8** | `I-14` | Widen the issue-link guard's checkbox regexes | checkbox regex still [-*]-only; + and ordered items silently pass |
| **5** | **7** | `I-21` | Restore a reachable home for the config-cites-decision convention · _merge with I-25_ | config-cites-decision still has no reachable always-loaded home |
| **5** | **7** | `I-24` | Reconcile the "diff-scoped, so required" selection principle with `build` · _merge with I-12,I-13_ | the diff-scoped principle still ships verbatim; enforce_admins sharpens its build contradiction |
| **5** | **7** | `I-30` | Give `make verify` a product seam | make verify still has no product seam |
| **5** | **7** | `I-33` | Protect the README blueprint version stamp · _merge with I-22_ | README version stamp still guarded by nothing; no Blueprint-Commit trailer |
| **5** | **6** | `I-25` | Resolve the AGENTS.md / path-scoped-rules narrowing · _merge with I-21_ | AGENTS.md still licenses ignoring .claude/rules; no ADR |
| **5** | **6** | `I-38` | Fix the heredoc-body false-block introduced by #118 | NEW (v1.2.0): #118's newline split parses heredoc bodies as commands — a false block that bit this audit |
| **5** | **5** | `I-39` | Make `github_setup.sh` custom checks preserve app-pinning and override `development` | NEW (v1.2.0): github_setup.sh custom checks discard app pinning, can't override development, and hardcode app_id 15368 (breaks GHES) |
| **4** | **9** | `I-02` | Lane G: strip HTML comments in the changelog half · _ship inside I-01_ | strip HTML comments in lane G's changelog half — ship only inside I-01 |
| **4** | **9** | `I-04` | Remove the blanket "Each rule is hook- and CI-enforced" header from `CLAUDE.md` · _merge with I-06_ | the blanket header is now false only for self-merge, but the prose is verbatim unchanged |
| **4** | **9** | `I-06` | Correct AGENTS.md's blanket CI promise · _merge with I-04_ | AGENTS.md CI promise now false only for self-merge; prose verbatim unchanged |
| **4** | **6** | `I-11` | Guard the MCP write surface | self-merge closed (v1.2.0); residual is MCP push_files/create_or_update_file/delete_file to feature branches |
| **4** | **6** | `I-27` | Make the release log a gated artifact · _after I-26_ | release log still not written from the promoted diff |
| **4** | **5** | `I-34` | Define what a blueprint version bump means downstream · _after I-27_ | blueprint version bump still carries no downstream contract |
| **4** | **5** | `I-35` | Add a retirement path for process | still no retirement path for process — every item here is permanent |
| **4** | **2** | `I-29` | Define a trivial-change lane | trivial-change lane — DROP CANDIDATE: waiver trailer covers it, per-PR checks infeasible |
| **3** | **9** | `I-16` | Repair the anchors the re-aim campaign orphaned | four orphan anchor stubs still shippable tidiness |
| **3** | **8** | `I-19` | Reconcile `/tick` steps 2 and 5 | /tick steps 2 and 5 still contradict on the no-gh path |
| **2** | **9** | `I-07` | File issues for I-05 and I-06 | file issues for the two enforcement-claim items (I-05 now resolved; still relevant for I-04/I-06) |

### 8.2 By ease — the quick-win queue (ease ≥ 8)

Thirteen items. Verified against v1.2.0.

| Value | Ease | ID | Item | Why |
|---|---|---|---|---|
| **6** | **10** | `I-17` | Add `validation:` to `mkdocs.yml` (`anchors: warn`, `nav.omitted_files: warn`) | anchors: warn still absent (nav half shipped v1.1.0); adding it builds clean |
| **7** | **9** | `I-13` | Validate `--profile` in `github_setup.sh` · _merge with I-24_ | --profile still unvalidated; a typo now also drops admin binding on development |
| **6** | **9** | `I-18` | Give `/note` and `/epic-closeout` the faithful-read rule `/tick` now has | /note and /epic-closeout still rewrite bodies through the lossy channel /tick now guards |
| **5** | **9** | `I-20` | Fix `running-epics.md:17-20`'s agent-close instruction | running-epics.md:17-20 still instructs an agent-performed close |
| **4** | **9** | `I-02` | Lane G: strip HTML comments in the changelog half · _ship inside I-01_ | strip HTML comments in lane G's changelog half — ship only inside I-01 |
| **4** | **9** | `I-04` | Remove the blanket "Each rule is hook- and CI-enforced" header from `CLAUDE.md` · _merge with I-06_ | the blanket header is now false only for self-merge, but the prose is verbatim unchanged |
| **4** | **9** | `I-06` | Correct AGENTS.md's blanket CI promise · _merge with I-04_ | AGENTS.md CI promise now false only for self-merge; prose verbatim unchanged |
| **3** | **9** | `I-16` | Repair the anchors the re-aim campaign orphaned | four orphan anchor stubs still shippable tidiness |
| **2** | **9** | `I-07` | File issues for I-05 and I-06 | file issues for the two enforcement-claim items (I-05 now resolved; still relevant for I-04/I-06) |
| **6** | **8** | `I-15` | Extend `check_docs_truth.py`'s path-citation scan surface · _needs archive exclusion_ | scan-surface still docs-only; the unscanned region grew with the new rules files |
| **6** | **8** | `I-32` | Add a repo-settings step to `UPDATE.md` · _after I-13,I-12_ | UPDATE.md still has no repo-settings step; the v1.2 admin-binding change reaches a seed only by re-running the script |
| **5** | **8** | `I-14` | Widen the issue-link guard's checkbox regexes | checkbox regex still [-*]-only; + and ordered items silently pass |
| **3** | **8** | `I-19` | Reconcile `/tick` steps 2 and 5 | /tick steps 2 and 5 still contradict on the no-gh path |

### 8.3 Traps — items that look easy and are not

The calibration and the v1.2.0 re-verification together flagged these. They are the reason the
ease column is worth trusting.

- **`I-36` is critical but not quick (ease 4).** It reads like "tighten a hook", but the fix is
  design work: the approve-hook must inspect `git -c` values, refuse redirect targets that are
  themselves enforcement files, and add `git branch -f` to its conditional set — each needing
  paired fixtures. Do not let its value-9 pull it into the quick-win queue.
- **`I-04` and `I-06` are 9-ease edits whose *content* is the trap.** v1.2.0 narrowed the falsehood
  but did not remove it: the blanket claims are now false **only for self-merge**, which has a hook
  (two `gh` spellings + the MCP deny) but still no *CI* enforcer and `required_approving_review_count:
  0`. Rewrite from that measured fact, not from the header's premise, or you write a third
  inaccurate enforcement statement into the always-loaded file.
- **`I-17` is genuinely the free win** (ease 10): `anchors: warn` beside the `nav.omitted_files:
  warn` that v1.1.0 shipped, verified build-clean with a planted broken anchor. No prerequisite.
- **`I-15` is a landmine without one clause** — it must exclude `.claude/archive/` and
  `.claude/working/`, or it reds every seed whose append-only archive cites a since-deleted path.
- **`I-37`'s two residuals are exotic** (`$'main'`, wildcard refspec) — real push-to-main holes,
  but the fix is parser work in all three triplicated guards plus fixtures, hence ease 6 not 9.
- **`I-02` is a regression on its own** — ship it only inside `I-01`.
- **`I-21`/`I-25` are keystroke-cheap and decision-expensive** — restoring a `CLAUDE.md` bullet
  reopens the diet a live rule now polices; the AGENTS.md narrowing is a decision, not an edit.
- **`I-29` is a drop candidate** (value 4 / ease 2): the waiver trailer already covers the case and
  per-PR required-check variation is not expressible in branch protection. Recording a decision
  *not* to do it would be the first use of the retirement path `I-35` proposes.

### 8.4 Suggested sequence

Not a schedule — a reading that respects the dependencies.

1. **`I-17`** — the only ease-10 item, verified, no prerequisite. Bank it first.
2. **`I-36`** — the new critical. Not quick, but it is the one open item that lets an agent silently
   disable every other guard, so it outranks everything except the seed-blocker. Scope it properly.
3. **`I-01`** (+ `I-02` inside it) — the value-10 seed-blocker, unchanged since revision 2 and now
   shipped in a released version, so every project seeded from v1.2.0 hits it.
4. **`I-13` + `I-12` + `I-24` as one `github_setup.sh` + gate pass**, folding in `I-39` (same file),
   then **`I-32`** to propagate the settings downstream.
5. **`I-04` + `I-06` together**, rewritten from §0's measured self-merge map, then **`I-07`** to
   give them owners.
6. **`I-37`** while the guard parser is open — same three files, add the `$'…'` and wildcard cases
   with fixtures. Fold in **`I-38`** (heredoc false-block) in the same parser pass.
7. Everything else by the value column, taking ease-≥8 items opportunistically.

---

## Appendix A — status of all 146 original findings

Severity is revision 1's post-refutation value. Status is revision 2's re-test.

| ID | Dimension | Severity | Status (v1.0.5 + dev) |
|---|---|---|---|
| `AGEN-06` | agent-contract | low | **Regressed** |
| `AGEN-01` | agent-contract | high | **Unchanged** |
| `AGEN-02` | agent-contract | high | **Unchanged** |
| `CHEC-02` | checkers | high | **Unchanged** |
| `HARN-02` | harness | high | **Unchanged** |
| `HARN-04` | harness | high | **Unchanged** |
| `HOOK-01` | hooks | high | **Unchanged** |
| `HOOK-02` | hooks | high | **Unchanged** |
| `MODU-04` | modules | high | **Unchanged** |
| `SCRI-02` | script-tests | high | **Unchanged** |
| `TEMP-01` | templates-github | high | **Unchanged** |
| `ADRS-01` | adrs | medium | **Unchanged** |
| `ADRS-02` | adrs | medium | **Unchanged** |
| `AGEN-04` | agent-contract | medium | **Unchanged** |
| `BOOT-02` | bootstrap | medium | **Unchanged** |
| `CHEC-01` | checkers | medium | **Unchanged** |
| `CHEC-03` | checkers | medium | **Unchanged** |
| `CHEC-07` | checkers | medium | **Unchanged** |
| `CI-G-01` | ci-gates | medium | **Unchanged** |
| `CI-G-02` | ci-gates | medium | **Unchanged** |
| `CI-G-04` | ci-gates | medium | **Unchanged** |
| `DOCS-01` | docs-consistency | medium | **Unchanged** |
| `HARN-07` | harness | medium | **Unchanged** |
| `HARN-08` | harness | medium | **Unchanged** |
| `HOOK-03` | hooks | medium | **Unchanged** |
| `HOOK-04` | hooks | medium | **Unchanged** |
| `HOOK-07` | hooks | medium | **Unchanged** |
| `LIFE-01` | lifecycle | medium | **Unchanged** |
| `LIFE-05` | lifecycle | medium | **Unchanged** |
| `MODU-02` | modules | medium | **Unchanged** |
| `SCRI-01` | script-tests | medium | **Unchanged** |
| `SCRI-03` | script-tests | medium | **Unchanged** |
| `SCRI-07` | script-tests | medium | **Unchanged** |
| `SECU-01` | security | medium | **Unchanged** |
| `SECU-05` | security | medium | **Unchanged** |
| `SECU-07` | security | medium | **Unchanged** |
| `WEIG-01` | weight-value | medium | **Unchanged** |
| `WEIG-02` | weight-value | medium | **Unchanged** |
| `WEIG-06` | weight-value | medium | **Unchanged** |
| `WEIG-07` | weight-value | medium | **Unchanged** |
| `ADRS-03` | adrs | low | **Unchanged** |
| `ADRS-04` | adrs | low | **Unchanged** |
| `ADRS-07` | adrs | low | **Unchanged** |
| `ADRS-08` | adrs | low | **Unchanged** |
| `ADRS-09` | adrs | low | **Unchanged** |
| `AGEN-05` | agent-contract | low | **Unchanged** |
| `AGEN-09` | agent-contract | low | **Unchanged** |
| `AGEN-10` | agent-contract | low | **Unchanged** |
| `BOOT-03` | bootstrap | low | **Unchanged** |
| `BOOT-05` | bootstrap | low | **Unchanged** |
| `BOOT-06` | bootstrap | low | **Unchanged** |
| `BOOT-09` | bootstrap | low | **Unchanged** |
| `CHEC-04` | checkers | low | **Unchanged** |
| `CHEC-05` | checkers | low | **Unchanged** |
| `CHEC-08` | checkers | low | **Unchanged** |
| `CHEC-09` | checkers | low | **Unchanged** |
| `CI-G-05` | ci-gates | low | **Unchanged** |
| `CI-G-06` | ci-gates | low | **Unchanged** |
| `CI-G-07` | ci-gates | low | **Unchanged** |
| `CI-G-08` | ci-gates | low | **Unchanged** |
| `CI-G-09` | ci-gates | low | **Unchanged** |
| `DOCS-04` | docs-consistency | low | **Unchanged** |
| `DOCS-05` | docs-consistency | low | **Unchanged** |
| `DOCS-06` | docs-consistency | low | **Unchanged** |
| `DOCS-07` | docs-consistency | low | **Unchanged** |
| `DOCS-08` | docs-consistency | low | **Unchanged** |
| `HOOK-05` | hooks | low | **Unchanged** |
| `HOOK-08` | hooks | low | **Unchanged** |
| `HOOK-09` | hooks | low | **Unchanged** |
| `HOOK-10` | hooks | low | **Unchanged** |
| `LIFE-02` | lifecycle | low | **Unchanged** |
| `LIFE-03` | lifecycle | low | **Unchanged** |
| `LIFE-04` | lifecycle | low | **Unchanged** |
| `LIFE-06` | lifecycle | low | **Unchanged** |
| `LIFE-07` | lifecycle | low | **Unchanged** |
| `LIFE-08` | lifecycle | low | **Unchanged** |
| `LIFE-09` | lifecycle | low | **Unchanged** |
| `LIFE-10` | lifecycle | low | **Unchanged** |
| `MODU-01` | modules | low | **Unchanged** |
| `MODU-03` | modules | low | **Unchanged** |
| `MODU-05` | modules | low | **Unchanged** |
| `MODU-06` | modules | low | **Unchanged** |
| `MODU-07` | modules | low | **Unchanged** |
| `MODU-08` | modules | low | **Unchanged** |
| `MODU-09` | modules | low | **Unchanged** |
| `MODU-10` | modules | low | **Unchanged** |
| `NOIS-07` | noise | low | **Unchanged** |
| `NOIS-08` | noise | low | **Unchanged** |
| `NOIS-09` | noise | low | **Unchanged** |
| `NOIS-10` | noise | low | **Unchanged** |
| `SCRI-04` | script-tests | low | **Unchanged** |
| `SCRI-05` | script-tests | low | **Unchanged** |
| `SCRI-06` | script-tests | low | **Unchanged** |
| `SCRI-08` | script-tests | low | **Unchanged** |
| `SCRI-09` | script-tests | low | **Unchanged** |
| `SECU-02` | security | low | **Unchanged** |
| `SECU-03` | security | low | **Unchanged** |
| `SECU-04` | security | low | **Unchanged** |
| `SECU-08` | security | low | **Unchanged** |
| `SECU-09` | security | low | **Unchanged** |
| `SECU-10` | security | low | **Unchanged** |
| `TEMP-02` | templates-github | low | **Unchanged** |
| `TEMP-04` | templates-github | low | **Unchanged** |
| `TEMP-05` | templates-github | low | **Unchanged** |
| `TEMP-07` | templates-github | low | **Unchanged** |
| `TEMP-08` | templates-github | low | **Unchanged** |
| `TEMP-09` | templates-github | low | **Unchanged** |
| `WEIG-05` | weight-value | low | **Unchanged** |
| `WEIG-08` | weight-value | low | **Unchanged** |
| `WEIG-09` | weight-value | low | **Unchanged** |
| `CI-G-03` | ci-gates | high | **Partially Resolved** |
| `SECU-06` | security | high | **Partially Resolved** |
| `HARN-06` | harness | medium | **Partially Resolved** |
| `NOIS-05` | noise | medium | **Partially Resolved** |
| `ADRS-06` | adrs | low | **Partially Resolved** |
| `AGEN-07` | agent-contract | low | **Partially Resolved** |
| `BOOT-07` | bootstrap | low | **Partially Resolved** |
| `CHEC-06` | checkers | low | **Partially Resolved** |
| `CHEC-10` | checkers | low | **Partially Resolved** |
| `DOCS-03` | docs-consistency | low | **Partially Resolved** |
| `DOCS-09` | docs-consistency | low | **Partially Resolved** |
| `HARN-10` | harness | low | **Partially Resolved** |
| `HOOK-06` | hooks | low | **Partially Resolved** |
| `WEIG-03` | weight-value | low | **Partially Resolved** |
| `HARN-01` | harness | high | **Resolved** |
| `BOOT-01` | bootstrap | medium | **Resolved** |
| `BOOT-04` | bootstrap | medium | **Resolved** |
| `HARN-05` | harness | medium | **Resolved** |
| `NOIS-01` | noise | medium | **Resolved** |
| `NOIS-06` | noise | medium | **Resolved** |
| `AGEN-03` | agent-contract | low | **Resolved** |
| `AGEN-08` | agent-contract | low | **Resolved** |
| `DOCS-02` | docs-consistency | low | **Resolved** |
| `HARN-09` | harness | low | **Resolved** |
| `NOIS-03` | noise | low | **Resolved** |
| `WEIG-04` | weight-value | low | **Resolved** |
| `ADRS-05` | adrs | low | **Already Not A Finding** |
| `BOOT-08` | bootstrap | low | **Already Not A Finding** |
| `HARN-03` | harness | low | **Already Not A Finding** |
| `NOIS-02` | noise | low | **Already Not A Finding** |
| `NOIS-04` | noise | low | **Already Not A Finding** |
| `WEIG-10` | weight-value | low | **Already Not A Finding** |
| `CI-G-10` | ci-gates | not-a-finding | **Already Not A Finding** |
| `SCRI-10` | script-tests | not-a-finding | **Already Not A Finding** |
| `TEMP-03` | templates-github | not-a-finding | **Already Not A Finding** |
| `TEMP-06` | templates-github | not-a-finding | **Already Not A Finding** |

---

## Appendix B — method

**Revision 2**, 2026-08-09, three phases in one workflow run:

1. **Re-check** — 15 agents, one per dimension, each re-testing its findings against the current
   tree by execution, with the full 55-commit diff and the v1.0.5 changelog available.
2. **Refute** — 15 independent agents, each instructed that a false "RESOLVED" is the most
   expensive error the audit can make, attacking every resolution claim from an angle the fix did
   not anticipate (sibling files, prose-vs-code, does-it-survive-bootstrap).
3. **Regressions** — 5 fresh-discovery agents over the new commits: guards and scripts, CLAUDE.md
   and rules, docs and pointers, tick and close protocol, setup and gates.

35 agents, 4.88M tokens, 1,514 tool calls, 155 min.

**Adversarial verification grade: 2 (independent verify)** for the 146 re-tested findings —
single-vote, same limitation as revision 1. **Grade 0 (self-check only)** for the 33 new findings,
except the §4.1 critical, which the orchestrator reproduced independently.

**Orchestrator's own work**, executed directly: the released-vs-development table in §2; the
guard-bypass re-probe in §5; the full-pattern tracker-ID recount in §3.2; the tag-placement check
in §7; and the end-to-end reproduction of the lane G deadlock in §4.1.

**Repository state:** `report.md` is the only file this audit has ever added or modified.
`git diff origin/development...HEAD` shows one file.

---

## Appendix C — revision 1 (v1.0.4 audit)

Revision 1's full text is in this file's git history at commit `aa9c820`. Its structure was:
method and limits · what is sound · five systemic themes (the enforcement gap · blueprint
archaeology and its mechanical cause · weight without a dial · process verified but product not ·
rituals the agent cannot run) · 13 high-severity findings · 36 medium · what the audit refuted ·
prioritised future work · relationship to the tracker.

Its headline numbers, for comparison: 146 findings from 15 auditors; 44 refuters moved 108 of
them; final severities 13 high · 36 medium · 93 low · 4 not-a-finding; 45 CONFIRMED, 92
PARTIALLY_CONFIRMED, 9 REFUTED.

## Appendix D — release history tracked by this audit

| Blueprint version | Audited | What moved |
|---|---|---|
| v1.0.4 | rev 1 (2026-07-29) | baseline — 146 findings |
| v1.0.5 | rev 2 (2026-08-09) | tracker-ID sweep + `.claude/archive/` deletion released; 8 findings resolved; lane G deadlock (`I-01`) and the blanket-header regression introduced |
| v1.1.0 | backlog refresh (2026-08-14) | `I-03` (promote) and `I-23` (`.gitignore` citation) closed; `nav.omitted_files` half of `I-17` shipped; required-check expansion released |
| v1.2.0 | **rev 3 (2026-08-14)** | guard-bypass cluster (`I-08`/`I-09`/`I-10`), MCP self-merge, and `enforce_admins` (`I-05`) resolved; the CLAUDE.md diet + `paths:` scoping released; **new critical:** the read-only auto-approve hook (`I-36`), plus `I-37`/`I-38`/`I-39` |

Each row's claims were verified by execution against that version's tree, not read from its
changelog — a discipline this audit adopted after finding the v1.0.5 changelog carried six
overclaims (§4.3). The v1.2.0 changelog, notably, carried none.
