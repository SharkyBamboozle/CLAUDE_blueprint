# Framework audit — Project Blueprint

**Repository:** `SharkyBamboozle/CLAUDE_blueprint` · **Version audited:** v1.0.4 ·
**Branch:** `claude/framework-audit-report-vv2udn` · **Date:** 2026-07-29

---

## How to read this report

This audit was run in two independent stages. Fifteen auditors surveyed the repository
along fifteen dimensions and produced 146 evidenced findings. Forty-four *separate*
verifiers — with no access to the finders' reasoning — were then instructed to **refute**
each finding, defaulting to REFUTED whenever the evidence did not independently hold up.

That second stage did real work, and the report is honest about it:

| | Finders claimed | After adversarial review |
|---|---|---|
| critical | 2 | **0** |
| high | 36 | **13** |
| medium | 93 | **36** |
| low | 15 | **93** |
| not a finding | — | **4** |

**Verdicts:** 45 CONFIRMED · 92 PARTIALLY_CONFIRMED · 9 REFUTED. Only 11 of the 36 claimed
"high" findings survived at that severity; 21 were downgraded to medium and 4 to low. Both
"critical" findings were downgraded to high. Nine findings were refuted outright.

Read that table as a statement about the audit's reliability, not the repository's. A survey
whose findings all survive its own verification has not been verified.

**Every number in this report was re-derived by the orchestrator**, because the auditors
disagreed with each other on several counts. Each figure names the command that produced it.
Numbers I did not measure are marked "not measured".

---

## 1. Verdict

**The framework is real, coherent, and unusually well-built.** `make verify` passes clean
(rc=0, 20.7 s, n=1, measured this session). The doctrine is genuinely thought through: D-004's
"a rule that names no enforcer is just a wish" is a good idea, executed with more rigour than
most production repositories manage. Eight hook/gate regression suites, two self-testing
Python checkers, and a meta-gate that pins the gate wiring are not window dressing — they run,
and they catch things.

**The problems cluster in one place: the gap between what the framework asserts is enforced
and what is actually enforced.** This is not a scattering of unrelated bugs. Of the 13
surviving high-severity findings, **nine are overclaims** — a document naming an enforcer that
does not cover the rule as stated. The doctrine's three flagship promises each failed
independent testing in a different way:

- **ADR-0004:** "a gate cannot be silently unwired" — the meta-gate misses `if: false`,
  `paths-ignore`, `branches-ignore`, `|| true` inside a step, a deleted job, and `.yaml`
  workflows (CHEC-02, CI-G-01, CHEC-03; all reproduced by execution).
- **ADR-0003:** "the flow and history rules therefore bind at the server" — the *history* half
  is true; the *flow* half is admin-bypassable, and in a solo project the agent holds the
  admin's identity (SECU-06, CONFIRMED).
- **AGENTS.md:** the hard rules "are enforced server-side by CI … by any agent or human" —
  of the six rules AGENTS.md names, two have a CI enforcer; self-merge has none at any layer
  (AGEN-01, CONFIRMED).

This matters more than any individual bug, because the framework's entire value proposition is
that a reader can tell *gated* from *advisory*. Where that distinction is wrong, the doctrine
is not merely incomplete — it is actively misleading, and it misleads most at the moments it
was built for.

**On the operator's own lens** — that rules must earn their place in *seeded* projects — the
audit found the archaeology is real, measurable, and has a single mechanical cause (§4.2). It
is smaller than the survey first claimed (several archaeology findings were refuted), but it
is concentrated in exactly the wrong places: guard block messages, CI failure text, and one
comment the framework **posts into the seeded project's own issue tracker**.

---

## 2. Method, scope, and limits

### What was done

- **15 dimension auditors**, each read-only on the repository, working in scratch copies:
  bootstrap dry-run · blueprint archaeology · hooks · CI workflows · the two Python checkers ·
  docs consistency · ADRs · modules · lifecycle rituals · Claude Code harness · security ·
  proportionality/value · the agent contract · templates & GitHub config · test-suite mutation
  coverage.
- **44 adversarial verifiers**, batched 3 findings per verifier for high/critical and 5 for
  medium/low, each instructed to open every cited `path:line`, re-derive every behavioural
  claim by execution, hunt for a handler that would kill the finding, judge seeded-project
  relevance separately, and steelman the case against fixing it.
- Findings were largely established **by execution**, not reading: hooks driven with crafted
  `PreToolUse` JSON on stdin, decision scripts run against hand-built fixtures, checkers run
  against deliberately mutated repository copies, `mkdocs build --strict` run against injected
  defects, and mutation testing against the guard suites.
- Total: 8.3M subagent tokens, 2,824 tool calls, across three workflow runs.

### Repository state

The audited repository was **not modified**. `git status --short` is empty at the time of
writing; every experiment ran in `/tmp` copies. This report is the only file added.

### Limits — what this audit did *not* establish

These are real gaps, stated so the report is not read as more complete than it is.

1. **Live GitHub settings were never read.** Every claim about branch protection describes
   what `scripts/github_setup.sh` *ships*, not what is configured on `SharkyBamboozle/CLAUDE_blueprint`
   or on any seeded repository today. CI-G-03 and SECU-06 are claims about the shipped default.
2. **`gh` is not installed in this container.** Where a finding says "`gh -R owner/repo issue close`
   is allowed", the *hook's* verdict is measured; `gh`'s own acceptance of that argument order is
   inferred from its documented interface, not executed. This affects SCRI-02 and part of AGEN-02.
3. **No end-to-end bootstrap was run against a real GitHub repository.** The bootstrap dry-run
   was executed in a local copy through step 7 plus `make verify`; steps 8's push and
   `github_setup.sh`'s API calls were not exercised.
4. **`UPDATE.md` and `ADOPT.md` were audited by reading and by tracing their inputs, not by
   running them.** No seeded project exists to update, and no mature project was retrofitted.
   LIFE-01…LIFE-10 are therefore analytical, not empirical, findings.
5. **Windows and macOS behaviour is unverified.** Portability findings (CRLF seams, BSD tool
   flags, missing `python3`) were reasoned from the code and, where possible, simulated on Linux.
6. **No performance or scale testing.** The only timing figure in this report is `make verify`
   at 20.7 s (n=1).
7. **Verifier judgement is itself unverified.** The refutation pass was single-vote per finding.
   A second, independent refutation round would likely move more findings again — the first one
   moved 108 of 146.

---

## 3. What is sound

An audit that lists only defects misrepresents the thing it audited. The following were
examined and found to work as claimed.

- **`make verify` is real and fast.** 20.7 s, rc=0, n=1. It runs 8 hook suites, a `bash -n`
  syntax pin over every shell script, a strict MkDocs build, and both checkers' `--self-test`
  before their live run. This is a genuinely good verification entrypoint.
- **The self-tests test both ways.** `check_docs_truth.py --self-test` and
  `check_ci_gates.py --self-test` each assert their checks both fail on bad input and pass on
  good — verified by reading the scenario tables and by running them. The verifier for CHEC-04
  found 11 self-test scenarios proving lanes that have no live inputs in this repository.
- **The version-arithmetic half of the release gate is airtight.** `release_gate_decision.sh`
  correctly enforces a bump of exactly one semver step; multiple verifiers tried to defeat it
  and could not. (Its *release-log* half is weaker — LIFE-07.)
- **The docs-truth consistency lane genuinely catches ADR drift.** Injecting an ADR whose
  status disagrees with its registry row, or a duplicate `D-###`, fails `make verify` —
  reproduced independently by two verifiers.
- **The issue-close server-side revert works as designed.** `issue_close_decision.sh`'s
  14-case suite covers the app-mediated, bot-mediated, last-event-wins, and fail-open paths,
  and the ledger logic is correct. Its *client-side* companion is weaker (SECU-07, SCRI-02).
- **The strict build does catch the failure that matters most.** A `nav` entry whose file is
  missing fails (rc=1, reproduced). The converse claim is the false one (§5, BOOT-09).
- **Several audit claims died on contact with the repository** — the framework had already
  handled them. Partial ADR supersession *is* legal (ADRS-05). The `development` branch *does*
  have a server-side enforcer (HARN-03). The harvest-candidate convention *does* have a live
  consumer (NOIS-04). `CODEOWNERS` is *not* inert (TEMP-06). See §7.

---

## 4. The systemic themes

146 findings are not 146 problems. They are five root causes.

### 4.1 The enforcement gap — named enforcers that do not cover their rule

The single largest theme, and the one that most threatens the framework's premise.

**Client-side, the guards share one parsing defect.** All three `PreToolUse` hooks identify a
command by `token == "git"` (or `"gh"`) followed by a **one-token lookahead**. Any global
option before the subcommand shifts the subcommand out of position and disarms the guard
completely. Measured against the real hooks (rc=2 means blocked, rc=0 allowed):

| command | rc |
|---|---|
| `git push origin main` | 2 — blocked (baseline) |
| `git -C . push origin main` | **0 — allowed** |
| `git --git-dir=.git push origin main` | **0 — allowed** |
| `git push --all origin` | **0 — allowed** (pushes `main` too) |
| `git push --mirror origin` | **0 — allowed** |
| `git push origin +HEAD:feature` | **0 — allowed** (force via `+` refspec) |
| `git push --force origin feature` | 2 — blocked (baseline) |

The same one-token defect disarms `guard-adr.sh` (Decided-ADR `git rm`/`git mv`) and
`guard-issue-close.sh` (`gh -R owner/repo issue close N` → rc=0). Root cause:
`guard-git.sh:218`. Findings HOOK-02, SCRI-02, AGEN-02, HARN-04 — all CONFIRMED, all
reproduced independently.

The *same* pre-tokenisation split also produces **false blocks**: `echo "step one; do not git
push origin main in this repo"` hard-blocks with the push-to-main message, because the guards
split the raw string on `;`/`&&`/`||`/`|` before quote-aware parsing (HOOK-04, SCRI-07, both
CONFIRMED). A guard that blocks innocent prose and allows `git -C . push origin main` has its
error budget backwards.

**Server-side, the backstop is narrower than advertised in three independent ways.**

- Five of the seven shipped gate jobs — `no-binaries`, `registry-sync`, `decided-adr-unlock`,
  `secret-scan`, `dependency-audit` — are required status checks on **neither** branch
  (`github_setup.sh:93,118`). They run, they report, and a red one is mergeable with one click
  (CI-G-03, CONFIRMED).
- `"enforce_admins": false` on both branches means an admin bypasses required PRs and required
  status checks. In a solo seeded project the owner *is* the admin, and the agent acts with the
  operator's identity — the framework says so itself in `issue-close-guard.yml`. The history
  rules (`allow_force_pushes: false`, `allow_deletions: false`) sit outside admin-bypass scope
  and genuinely do bind (SECU-06, CONFIRMED, verified against GitHub's documentation).
- The **MCP write surface is unguarded**. Every guard except `guard-issue-close.sh` is
  registered on the `Bash` matcher only, and the guard bodies read `tool_input.command`, which
  no MCP tool has. `mcp__github__merge_pull_request`, `push_files`, `create_or_update_file`,
  `delete_file` and `enable_pr_auto_merge` return rc=0 through every hook, and no `mcp__*` entry
  exists in the deny-list (HARN-02, HOOK-01). The verifiers narrowed the exposure usefully:
  binary commits and ADR rewrites *are* caught on the PR path by CI, so **the unmitigated
  residual is self-merge and a direct MCP write to a protected branch** — neither of which has
  any server-side recovery, and `required_approving_review_count: 0` means review is not one either.

**The meta-gate does not pin what ADR-0004 claims it pins.** Six mutations were executed
against `check_ci_gates.py`'s own scan and all passed green: job-level `if: false`, a stubbed
`run:` step, `|| true` appended inside a step, deleting the `release-gate` job,
`branches-ignore: [development]`, and `paths-ignore: ['**']`. A seventh: a workflow named
`.yaml` instead of `.yml` is invisible to the entire sweep (CHEC-03, CONFIRMED). And the
inverse hole — deleting *every* `PreToolUse` registration from `settings.json` leaves
`check_ci_gates.py` and `make verify` both at rc=0, because the checker derives its work-set
*from* that file (HOOK-07, CONFIRMED).

Two of these deserve special note because they are *inconsistent with the checker's own
purpose* rather than merely uncovered: `|| true` achieves exactly what `continue-on-error`
achieves, and `continue-on-error` is explicitly forbidden; and `paths-ignore` is the exact
complement of the `paths` filter the checker already rejects — so the checker forbids the front
door and documents the back door in its own failure message.

### 4.2 Blueprint archaeology — and its mechanical cause

The operator's headline concern, measured.

**About 70 references to this repository's own issue tracker survive into every seeded project.**
My count: **72 hits of 9 distinct blueprint issue numbers (#3, #12, #18, #35, #37, #39, #41,
#47, #54) across 22 inherited files**, method:
`git grep -nE '#(3|12|18|35|37|39|41|47|54)([^0-9]|$)'` over the 117-file inherited set,
excluding `scripts/test_*` fixtures and `.claude/archive/`. An independent verifier recounted
70 by a slightly different method. Both round to "about 70 across ~22 files".

The count is less important than the placement. **16 of them reach a downstream reader at
runtime**, not as source comments:

| location | what a seeded project sees |
|---|---|
| `guard-git.sh:267,279` | `BLOCKED (PR lifecycle, #39): …` — in the agent's face at the moment it is blocked |
| `guard-issue-close.sh:48` | `BLOCKED (CLAUDE.md hard rule, #54): …` |
| `issue_link_decision.sh:145,173,175` + `:72,153` | CI `::error::`/`OK:` annotations citing #18, #37, #41, #47 |
| `release_gate_decision.sh:81` | `::error::release-gate: … (#35)` |
| `.github/pull_request_template.md:9,12,25` | rendered in **every PR body**; GitHub autolinks `#41`/`#47`/`#37` to the seeded repo's own unrelated issues |
| `.github/labels.yml:18` | the `task` label's description, visible in the GitHub UI |
| `.github/ISSUE_TEMPLATE/task.yml:37` | a form field description |
| `issue_close_decision.sh:96` | **posted as a comment into the seeded project's issue tracker** |

That last row is the sharpest instance: the framework does not merely *carry* the archaeology,
it *writes* it into the downstream tracker, unattended, creating a permanent cross-reference to
an unrelated issue.

**Every seeded project also inherits this repository's own session forensics.**
`.claude/archive/2026-07-24/` — 2 files, 126 lines, 850 words — documents this repo's
reproductions for its issues #21 and #22, citing `modules/` and `BOOTSTRAP.md` paths that do
not exist after bootstrap. `BOOTSTRAP.md` never mentions the word "archive"; step 7's delete
list omits it. Worse, the inherited `.claude/archive/README.md` declares the directory
append-only and deletable "only on explicit user instruction" — so **the seed contains
instructions forbidding the removal of the blueprint's own debris**. It also trips the
bootstrap completion gate (RC=1, reproduced on a pristine `git archive HEAD` seed) with no
instruction anywhere for how to resolve it (BOOT-01, HARN-05, NOIS-06 — all CONFIRMED).

**The mechanical cause is a blind spot, and it is the same finding.** `BOOTSTRAP.md` step 7
promises that re-running `make verify` after deletion catches surviving citations of deleted
paths. But `check_docs_truth.py` scans `DOC_GLOBS_DIRS = ["docs"]` plus eight named root files
(`:70,73`). `.claude/`, `.github/`, `scripts/README.md`, `Makefile` and `mkdocs.yml` are valid
citation *targets* but are never walked as citation *sources* — proved by positive control:
five injected dead citations in those files produced **zero** findings. The region the checker
cannot see is precisely the region where the archaeology lives (NOIS-05, HARN-06, CHEC-09).

**Where the archaeology claims were refuted**, the report says so. The `contributing.md`
redirect stubs are *not* archaeology (NOIS-02, REFUTED): they are the live resolution target
for ~30 inherited prose pointers and 11 `#fragment` links from six hook-locked ✅ Decided ADRs,
and removing them breaks all of it silently. The residual is one word — "long-standing" at
line 27, which is false in a day-one seed. Likewise the harvest-candidate instruction has a
real consumer (NOIS-04, REFUTED): `HARVEST.md` explicitly designates `note` issues in live
projects as a primary input. Its residual is that "the blueprint" is an unnamed referent
downstream — an argument for parameterising it, not deleting it.

### 4.3 Weight without a dial

Measured, with methods:

| | value | method |
|---|---|---|
| Inherited set (survives bootstrap) | **117 files, 8,840 lines** | `git ls-files` minus step 7's delete list |
| Always-loaded agent instruction | **2,882 words** | `CLAUDE.md` 2,702 + `.claude/rules/README.md` 180 |
| Docs prose | **14,320 words** (15,792 incl. `.templates/`) | `find docs -name '*.md' \| xargs cat \| wc -w` |
| Enforcement mechanisms | **29** | 6 hooks + 7 workflows + 2 checkers + 6 decision scripts + 8 suites |
| `scripts/` | **3,205 lines** | `cat scripts/* \| wc -l` |

`.claude/rules/README.md` has no `paths:` frontmatter, so **by the directory's own documented
semantics it loads into every session** — 180 words of documentation *about* the rules
mechanism, to support one shipped rule that saves 122 on-demand words. Independently confirmed
by a verifier observing it in its own context (AGEN-03, HARN-09).

**All 8,840 lines ship undifferentiated.** The bootstrap interview asks six questions, none of
which is "how heavy should this project's process be?" — even though the repository has already
invented the exact mechanism for this three times over: `.claude/release.txt`,
`.claude/asset-dirs.txt` and `.claude/docs-truth.txt` are all seams with a `mode: off <reason>`
escape (WEIG-05).

**There is no low-ceremony lane.** A docs typo pays the same branch → PR → second-party-merge →
changelog-entry chain as a feature. The verifier correctly deflated the finder's headline
("9 steps, 4,171 words" is inflated — 2,702 of those words are `CLAUDE.md`, already loaded) and
found two partial reliefs the finder missed: `committing.md`'s "non-trivial" qualifier, and a
named, test-pinned `Skip-Issue-Link-Guard: trivial one-line fix` waiver. The accurate statement
is **"no lane", not "no exemption"** (WEIG-01).

**And there is no exit.** The framework has an entrance for every rule — ADRs, trailers,
ledgers, gates — and no doctrine, ritual, or review point for *removing* process that has
stopped earning its keep (WEIG-08). This is the mechanism by which a framework becomes the
thing the operator's lens warns against, and it applies to this report too: every
recommendation below, if adopted, is currently permanent.

### 4.4 Process is verified; the product is not

**29 enforcement mechanisms, ~3,205 lines under `scripts/`, and every one of them verifies
process artifacts.** `make verify`'s 15 recipe lines contain zero product-code steps. The only
shipped mechanism that adds any — the `python-package` module's `ruff check` + `pytest -q` — is
Python-only and dies with `modules/` at bootstrap. A seeded project on any other stack, or one
that declines the module, inherits a `verify` target that **cannot fail for a product reason**,
while `CLAUDE.md`'s *Definition of done* makes `make verify` the sole arbiter of done (WEIG-07).

The verifier trimmed the headline fairly: D-006 *does* require exercising the change by hand,
so it is not true that there is "no 'does the thing work' check" — it is that the check is
advisory prose while every process check is mechanised. That asymmetry is the finding.

Compounding it: `make verify` itself runs on an **unpinned floating toolchain**. All three
entries in `docs/requirements.txt` are `>=` floors with no lockfile — while
`docs/requirements.txt:3` describes the toolchain as "pinned, not floating blindly" and
attributes the rule to D-004, which contains no such rule (WEIG-06).

### 4.5 The rituals the agent cannot run

Nine of the eleven cards in `.claude/commands/` carry `disable-model-invocation: true`
(`adr-new`, `epic-kickoff`, `epic-closeout`, `note`, `handoff`, `session-close`, `promote`,
`lock-adr`, `unlock-adr`). Only `/tick` and `/checkpoint` are model-invocable — reproduced in
two independent sessions. Meanwhile `CLAUDE.md` issues the flagged commands as direct agent
instructions ("run `/promote`", "via `/handoff`", "Use them instead of reconstructing the steps
from memory"), `stale-working-docs.sh` nudges `/handoff` on every Stop, and `guard-adr.sh`
prints `/unlock-adr <id>` as its recovery path. The flag is documented nowhere in the
repository (HARN-08).

This is not necessarily a bug — operator-only invocation is defensible for `/promote` and
`/epic-closeout`. It is an *undocumented* design whose two surfaces contradict each other, and
it silently converts several named recovery paths into dead ends.

---

## 5. High-severity findings (13)

Each entry states the claim in the verifier's corrected form, not the finder's original.

**HOOK-02 · CONFIRMED · Any git/gh global option disarms all three guards.**
`git --no-pager push origin main`, `git -C . push origin main`, `git --git-dir=… push origin main`
all return rc=0 against the live hooks; the resulting commands are valid git that really performs
the forbidden operation (verified against git 2.43.0). Push-to-main, force-push, remote-branch
deletion, binary staging, zombie-push and Decided-ADR `git rm`/`git mv` are all opt-out by
prefixing a harmless flag. No CI gate covers the direct-push cases. The 35-case regression suites
contain no global-option case, so the gap is un-pinned as well as un-guarded.
*Fix:* a shared ~10-line argv normaliser that walks past global options (and their values) before
reading the subcommand, plus regression cases in both suites.

**AGEN-02 · CONFIRMED · All three guards are defeated by ordinary command forms; the backstops are asymmetric.**
13/13 exit codes reproduced independently. The defensible severity driver is not the bypass
count — it is that issue-close and Decided-ADR bypasses *are* recovered server-side, while
self-merge, a direct commit to `main`, and a binary committed to `main` have **no** server-side
recovery, and `CLAUDE.md` and `AGENTS.md` tell the agent all of them are covered.
*Caveat disclosed:* `gh` is not installed here, so the hook's verdict on `gh api --input` and
GraphQL forms is measured; `gh`'s acceptance of those forms is inferred from its documented interface.

**HARN-04 · CONFIRMED · The segment splitter ignores newlines, causing both false blocks and a false allow.**
`guard-git.sh:212` splits on `&&|\|\||;|\|` but not `\n`, and `rest = tokens[i+2:]` captures every
token to the end of the segment. In a multi-line Bash block, tokens from later lines become
arguments of an earlier `git`. Reproduced: a bare `:` on a later line triggers the branch-deletion
block; the word `main` triggers the push-to-main block; a bare `.` turns a narrow `git add <file>`
into a whole-worktree binary scan. **And the reverse** — a bare `git push` on `main` followed by any
second line sets `explicit_nonmain` from the over-captured tokens and passes rc=0, where the same
push alone is blocked. `test_guard_git.sh` has no multi-line fixture.
*Fix:* add `\n` to the splitter in all three hooks (one character class), plus fixtures.

**HOOK-01 · CONFIRMED · The MCP write surface reaches GitHub with no hook and no deny rule.**
`mcp__github__merge_pull_request`, `enable_pr_auto_merge`, `push_files`, `create_or_update_file`,
`delete_file` are dispatched to no hook and appear in no deny entry; all return exit 0 against all
three guards, while the control `mcp__github__issue_write {state:"closed"}` correctly returns 2.
`main`'s protection sets `required_approving_review_count: 0`, so review is not a server-side net
for self-merge either. ADR-0003's "the git guard hook blocks … self-merges at the client" is true
only of the `gh` spelling.

**HARN-02 · PARTIALLY_CONFIRMED (from critical) · The MCP residual, precisely scoped.**
The verifier narrowed this usefully and the narrowing is the publishable form: force-push is not
reachable through any MCP tool in this toolset; binary commits and ADR rewrites are caught on the
PR path by `repo-hygiene.yml` and `adr-gates.yml`. **The unmitigated residual is (a) self-merge via
`mcp__github__merge_pull_request` and (b) MCP writes straight to a protected branch by an
admin-privileged token.**

**HARN-01 · PARTIALLY_CONFIRMED (from critical) · `/tick`'s verification step is blind to its own failure mode.**
`/tick`'s anchored edit is a full-body rewrite composed from the GitHub MCP `issue_read` channel,
which is verified lossy — it strips HTML comments (including inside code fences) and
entity-escapes `'`, `"`, `&`. Step 1 explicitly sanctions that channel. **The increment over the
already-tracked #68 is step 4:** its "re-read and confirm nothing else changed" runs through the
*same* channel, and because comment-stripping is idempotent, the re-read of a just-gutted body is
byte-identical to the lossy pre-image — the ritual's own safety check cannot fire on its dominant
failure mode. Three corrections the verifier applied: the line numbers are off by 3–4; the claim
that #68 "does not mention entity-escaping" is **false** (#68 states it verbatim, and already names
the proposed fix); and "unrecoverable" overstates it, since GitHub retains issue edit history.
*Genuinely untracked increment: step-4 blindness alone.*

**SCRI-02 · CONFIRMED · `gh -R owner/repo issue close N` is allowed.**
Measured against the real hook: leading `-R o/r`, `--repo o/r` and `-R=o/r` forms all return rc=0,
while plain and trailing-`-R` forms correctly block. The `settings.json` prefix deny rules share
the hole. No case in the 25-case suite uses a leading global flag. The hook header and
`closing-issues.md:66-70` both state the Bash layer blocks `gh issue close` without qualification.
*Mitigation, not elimination:* the server-side revert makes the realistic outcome a
close-then-reopen — bounded by that workflow's fail-open on API errors and its blindness to
non-app tokens.

**CI-G-03 · CONFIRMED · Five of seven gates are required on neither branch.**
`github_setup.sh` requires four contexts on `main` and two on `development`. `no-binaries`,
`registry-sync`, `decided-adr-unlock`, `secret-scan`, `dependency-audit` are required on neither,
although all fire unfiltered on every PR and none is conditionally skipped (verified by parsing
all seven workflows). A PR that commits a binary, edits a Decided ADR without a trailer, or trips
gitleaks shows a red check and remains mergeable with one click, with no approval required. Six
surviving artifacts assert the opposite.

**CHEC-02 · PARTIALLY_CONFIRMED · The meta-gate models two filter forms and misses three more.**
`branches-ignore: [development]`, `paths-ignore: ['**']`, and a job- or step-level `if:` all leave
`check_ci_gates` green. `if:` additionally defeats branch protection, because a skipped job
*satisfies* a required status check — making it the only vector with no layer behind it. Neither
`branches-ignore` nor `paths-ignore` appears in any shipped workflow, so both fixes are
zero-false-positive. *Not supported:* the `jobs: {}` vector (GitHub rejects an empty `jobs:` map).

**SECU-06 · CONFIRMED · `enforce_admins: false` makes the flow rule advisory for the only actors present.**
Set in all three protection payloads (`:100`, `:119`, `:184`) with no rationale comment and no
mention in `docs/`. GitHub exempts admins from required PRs and required status checks when it is
off. In a solo seeded project the owner is the admin and the agent acts with the operator's
identity. The **history** half genuinely binds (`allow_force_pushes: false` sits outside
admin-bypass scope); the **flow** half does not, while ADR-0003, `pushing.md` and `CLAUDE.md` all
assert it. Severity is high on the doctrine axis, not the attacker axis — nobody's privilege is
escalated, but D-004's flagship rule gets the gated/advisory distinction backwards.

**AGEN-01 · CONFIRMED · AGENTS.md's central promise is false, and understated by the finder.**
Of the six rules `AGENTS.md:16-18` names, only two have a CI enforcer (`repo-hygiene.yml`,
`adr-gates.yml` — both `on: pull_request`, so both silent on a direct push). Branch-flow,
push-to-`main` and force-push rest on branch protection, which is not CI, is installed only by an
optional script, and does not bind an admin. **Self-merge has no server-side enforcer of any
kind.** ADR-0003 itself says so at lines 9 and 45 — so AGENTS.md contradicts a ✅ Decided decision.
On AGENTS.md's own enumeration the gap is **4 of 6, not 3 of 6**.

**TEMP-01 · CONFIRMED · The PR template's own example text parses as a real closing keyword.**
`"Closes #7 (partial)"` in `.github/pull_request_template.md` is extracted by
`issue_link_decision.sh` as a genuine closing reference. In a seeded project, once issue or PR #7
exists — i.e. almost immediately — every PR that leaves the template's instruction text in the
body is adjudicated against an unrelated issue. Note this **directly contradicts** NOIS-01's
recommendation to strip the parentheticals; the two must be reconciled by fixing the *parser*
(strip HTML comments and inline-code spans before extraction), not only the template.

**MODU-04 · CONFIRMED · `lfs-assets` produces inert patterns and both enforcers wave the raw blob through.**
Without `git lfs install`, the module's own mandatory step-2 verification
(`git check-attr filter -- <path>` → `filter: lfs`) **passes with no driver present** (measured).
A 300 KB `.glb` then commits as a raw 300,000-byte blob with rc=0 and no warning (measured). Both
shipped enforcers decide by `git check-attr` alone, so `guard-git.sh` returns rc=0 where the
identical un-patterned file returns rc=2, and a verbatim replay of `repo-hygiene.yml`'s lane exits 0.
`git lfs install` is a post-init, per-machine checklist item — one forgotten command away, permanently,
on every new machine. This violates ADR-0007's stated invariant.
*Verifier correction, material:* the finder's proposed pointer-shape check is **not implementable in
`guard-git.sh`**, which is `PreToolUse` and therefore runs *before* `git add`, when the worktree file
is raw even in a correctly configured repository. The check belongs in CI.

---

## 6. Medium-severity findings (36)

Grouped by theme; each is CONFIRMED or PARTIALLY_CONFIRMED after adversarial review.

**Guards and hooks.** HOOK-03 force detection misses bundled short flags (`-fu`, `-uf`, both
verified to force-update) and `--force-with-lease=<ref>`; a `+` refspec is a positional, never
examined, and matches no deny rule either — **zero** client-side enforcement for that form.
HOOK-04 / SCRI-07 false blocks from pre-tokenisation splitting (`echo "see (main|master): git
push --force is blocked"` → rc=2). HOOK-07 deleting every `PreToolUse` registration leaves
`make verify` green. HARN-07 neither seam parser normalises whitespace: a CRLF `.claude/release.txt`
makes `release_gate_decision.sh` reject its own required value with a message naming the correct
string as invalid.

**ADR lock.** ADRS-01 the 🟡→✅ promotion is guarded for only one of three natural edit shapes —
replacing just the glyph, or `"🟡 Proposed" → "✅ Decided"`, returns rc=0 (though
`adr_unlock_decision.sh` catches it on the PR path). ADRS-02 the unlock token is a gitignored
line an agent can mint with one `echo`; the edit-time lock is an anti-accident speed bump, not an
authorization gate. SCRI-03 neither layer tests that an unlock is *scoped* to the ADR being changed.

**CI and checkers.** CI-G-01 six executed mutations pass the meta-gate. CI-G-02 the checkbox
counter reads only `-`/`*` items, so a body mixing one ticked `-` box with unticked `+` or `1.`
items passes and prints "deliverables N/N ticked" — a silent pass plus a false completeness
assertion. CI-G-04 PR-triggered gates execute the PR's own decision scripts (narrower than
claimed: editing a `*_decision.sh` turns the required `build` check red via the suites). CHEC-01
the "gate never runs on PRs" branch is unreachable in the production path. CHEC-03 `.yaml`
workflows are invisible. CHEC-07 lane A rejects prospective paths — the natural way to write a
how-to — and all three opt-outs are undocumented.

**Bootstrap and seams.** BOOT-01 `.claude/archive/` trips the completion gate with no instruction.
BOOT-02 `design-principles.md` is the only seed file placing its stubs *outside* the `BLUEPRINT:`
marker, so deleting the marker without writing the principles yields green gate + green verify.
BOOT-04 ~70 tracker citations survive. HARN-05 / NOIS-06 the archive ships. NOIS-05 / HARN-06 the
checker's scan surface excludes the region where the archaeology sits. MODU-02 `pip` vs
`python3 -m` self-contradiction written into two files that survive forever.

**Docs and contract.** DOCS-01 the strict build does not validate anchors, so the entire
anchor-preservation scheme is unguarded. AGEN-04 `running-epics.md:17-20` still instructs an
agent-performed close, and **#63's acceptance criterion "0 matches" is ticked while this survives**.
HARN-08 nine rituals the agent cannot invoke.

**Lifecycle.** LIFE-01 the README version stamp is written by bootstrap, declared machine-read,
consumed by `UPDATE.md`, and checked by no gate — a later README rewrite removes it silently.
LIFE-05 `UPDATE.md` has no repo-settings step, so a gate delivered by a version bump arrives
present but non-binding; **one such span has already shipped — v1.0.3, which added `release-gate`**.

**Security and value.** SECU-01 `docs.yml` grants `pages: write` + `id-token: write` at workflow
level to a PR-triggered job running PR-controlled code. SECU-05 any `--profile` value other than
the literal `code` silently selects the data profile and exits 0 reporting "setup complete", leaving
`main` unprotected. SECU-07 the close guard allows at least eight spellings its header does not
exclude, and **#63 propagates the overclaim into the tracker** by asserting agent closes are
"mechanically impossible". SCRI-01 8 of 11 realistic mutations to `guard-git.sh` survive its suite.
WEIG-01/02/06/07 as in §4.

---

## 7. What the audit refuted

Reported because an audit that hides its misses is not an audit.

| finding | verdict | what is actually true |
|---|---|---|
| **ADRS-05** bundled ADRs have no legal path to partial revision | REFUTED | `adr-0001:86-88` explicitly authorizes superseding **any individual convention** with a 🧊 pointer on the affected part; `writing-adrs.md` authorizes a declared *refinement*. Residual: a one-clause cross-reference in the how-to. |
| **HARN-03** "never commit directly to `development`" has no enforcer at any layer | REFUTED | It has **no client-side** enforcer, but `github_setup.sh:109-118` puts required checks on `development` for exactly this stated purpose. The finder quoted line 116 while the answer sat at 109–115. Residual: admin bypass, and the enforcer is discoverable only from a shell comment. |
| **NOIS-02** the `contributing.md` stubs are archaeology | REFUTED | They are the live resolution target for ~30 inherited pointers and 11 locked-ADR anchors; removing them breaks all of it silently (mkdocs reports missing anchors at INFO only). Residual: the single word "long-standing". |
| **NOIS-04** the harvest-candidate instruction has no consumer | REFUTED | `HARVEST.md` designates exactly these `note` issues as a primary input and closes them at release. Residual: "the blueprint" is an unnamed referent downstream — parameterise, don't delete. |
| **CI-G-10** gate messages hardcode this repo's issue numbers | not a finding | True on the facts, but open issue **#63 already defers this deliberately** pending an owner convention decision. Reporting it as untracked would misrepresent the repo's state. The one genuine increment — that `issue_close_decision.sh:96` is *posted*, not logged — belongs as a comment on #63. |
| **TEMP-03** acceptance-criteria boxes make the gate un-passable | not a finding | An issue with an honestly unmet acceptance criterion is by the repo's own definition not complete, so blocking is the rule working. Residual: a one-word wording nit in the error string. |
| **TEMP-06** `CODEOWNERS` is a guaranteed no-op | not a finding | GitHub suppresses code-owner review requests only on *owner-authored* PRs; dependabot PRs on this very repo are non-owner-authored (verified: merged PR #55). |
| **SCRI-10** the Makefile lacks day-one affordances | not a finding | One target is a Decided design (D-006); `mkdocs serve` is documented at its canonical home. The finder's stated reason for filing separately from #29 was false, and its `--ignore-installed PyYAML` advice is worse than #29's. |
| **WEIG-10** unattended agents deadlock on operator-only stops | REFUTED | `CLAUDE.md:72-73` scopes a failed question to "stop **that line of work**", not the session; two of the five stops are where the agent's job is *defined* to end; the other three sit inside `disable-model-invocation` rituals an unattended agent cannot reach. Residual: no named convention for parking decisions. |

Two further corrections worth recording: **TEMP-01 directly contradicts NOIS-01** (one says the
PR template's `#N` parentheticals must go, the other shows the parser is what needs fixing), and
several findings' counts were inflated by their finders and corrected by verifiers (AGEN-07's
"64 dangling citations" includes a stub class that is not dangling; HARN-06's "41 path citations"
was withdrawn as unsupported).

---

## 8. Future work, prioritised

Ordered by value per unit of effort. Every item names what it buys.

### Wave 1 — make the enforcement claims true (highest value, lowest cost)

The framework's credibility rests on the gated/advisory distinction being accurate. Two of
these three items are pure documentation.

1. **Fix the argv parsing in all three guards.** One shared ~10-line normaliser that skips global
   options (and the values of `-C`, `-c`, `--git-dir`, `--work-tree`, `-R`, `--repo`) before
   reading the subcommand; add `\n` to the segment splitter; tokenize before splitting rather than
   after. Add regression cases for every form in the §4.1 table.
   *Value:* closes the largest client-side hole and the false-block problem in one change. These
   are the guards four of five hard rules depend on.
   *Cost:* ~40 lines across three hooks plus ~15 test cases.
2. **Correct every enforcement overclaim.** `AGENTS.md:25-27` (per-rule, not blanket), ADR-0003's
   enforcement paragraph (flow vs history), `writing-adrs.md`'s Bash-coverage sentence, the
   `guard-issue-close.sh` header, `docs/requirements.txt:3`'s "pinned", and `BOOTSTRAP.md:58-59`'s
   nav claim. ADR-0003 needs `/unlock-adr` — which makes it the worked example of the lock's cost.
   *Value:* restores the one property the whole doctrine sells. A reader can again trust "gated"
   to mean gated. Nearly free.
   *Cost:* prose only, plus one unlock pass.
3. **Register the five unrequired gates as required checks**, and decide `enforce_admins`
   deliberately — either set it `true` and accept that the operator goes through a PR, or leave it
   `false` and say so in ADR-0003 and `pushing.md`. Either is defensible; the current state is a
   documented guarantee that does not hold.
   *Value:* turns three shipped gates (binary, ADR-lock, secret-scan) from advisory into binding.
   *Cost:* one line in `github_setup.sh` plus an ADR amendment.
4. **Guard the MCP write surface**, or name the residual honestly. Widen the matchers to
   `Bash|mcp__.*(merge_pull_request|enable_pr_auto_merge|push_files|create_or_update_file|delete_file)`
   and add MCP branches reading `tool_input.branch`/`path` — `guard-issue-close.sh` is already the
   working template. Add the same names to the deny list.
   *Value:* self-merge is the one hard rule with no enforcer at any layer, and MCP is the *default*
   path in web sessions. *Cost:* ~10 lines of Python per guard plus two matcher strings.

### Wave 2 — close the blind spots that let archaeology accumulate

5. **Extend `check_docs_truth.py`'s scan surface** to `.claude/**/*.md`, `.github/**`,
   `scripts/README.md`, `Makefile`, `mkdocs.yml`. Exclude `.claude/archive/` explicitly.
   *Value:* this is the single highest-leverage change for the operator's stated concern. It makes
   the step-7 promise ("dead citations fail here, on your machine") true, and it is the mechanism
   that keeps future archaeology from accumulating. *Cost:* one constant plus a ledger entry.
6. **Add `.claude/archive/` to step 7's delete list**, and reword `.claude/archive/README.md` so it
   does not forbid removing inherited debris. *Value:* removes 126 lines of foreign forensics from
   every seed and un-breaks the completion gate. *Cost:* one token in a `git rm` line.
7. **Add `validation:` to `mkdocs.yml`** (`anchors: warn`, `nav.omitted_files: warn`).
   *Value:* makes the strict build guard the anchor scheme the ADR links depend on, and fixes #25's
   false claim at the same time. *Cost:* three lines. **Sequencing note:** run this *after* item 8,
   or the six already-missing anchors (DOCS-02) will fail the build.
8. **De-cite the 16 runtime-visible tracker references** — the guard block messages, the CI
   `::error::` strings, the posted comment, the PR template, the label and form descriptions.
   Replace `(#41)` with the durable artifact (`docs/process/opening-a-pr.md`, `D-002`) which
   survives seeding. Fix `issue_link_decision.sh`'s parser to strip HTML comments and inline-code
   spans, which resolves TEMP-01 at the same time. **Coordinate with open #63**, which already
   defers this class deliberately.
   *Value:* stops the framework writing false provenance into downstream trackers.

### Wave 3 — make the framework fit more than one project shape

9. **Add a process-weight dial to the bootstrap interview** — `minimal / standard / full`, wired as
   a `.claude/process-profile.txt` seam exactly like the three seams that already exist.
   *Value:* the framework currently has one setting, calibrated for a multi-year multi-agent
   platform, and ships it to a 200-line hobby project unchanged. This is the difference between
   adoption and abandonment for the smallest archetype, and between followed and ignored for the
   middle one. *Cost:* one interview question, one seam file, and conditional prose.
10. **Define a trivial-change lane** in the contributing hub: no issue, no closing keyword, a
    `Trivial:` trailer, one required check. *Value:* typo fixes currently pay feature-sized
    ceremony, so they either stop happening or the rules get ignored — and selective ignoring is
    what erodes the rules that matter.
11. **Give `make verify` a product seam.** Ship `verify-product` as a stub with an explicit
    "no product checks yet — declare why" declaration, in the same `mode: off <reason>` shape the
    repo already uses three times. *Value:* 29 mechanisms currently verify that the process is
    consistent and none verify that the software works; this makes that a visible, declared choice
    rather than a silent gap.
12. **Pin the docs toolchain** with a lockfile used by CI and `make verify`. *Value:* the sole
    arbiter of "done" is currently reproducible only by luck, and two shipped comments claim
    otherwise.

### Wave 4 — durability

13. **Write down what a blueprint version bump means downstream** (LIFE-09), and add a
    repo-settings step to `UPDATE.md` (LIFE-05) — a gate delivered by an update is currently
    present but non-binding, and v1.0.3 already shipped one.
14. **Protect the version stamp** `UPDATE.md` depends on: assert the README footer in
    `check_bootstrap_complete.sh`, and record `Blueprint-Commit: <sha>` in the birth commit so the
    update base is a commit, not a version guess (LIFE-01, LIFE-02).
15. **Add a retirement path for process.** A `Retired:` ADR status and a standing question at epic
    closeout: *which rule stopped earning its keep?* *Value:* without it, every recommendation in
    this report is permanent, and the framework accretes until it becomes the thing its own founding
    lens warns against.
16. **Document `disable-model-invocation`** and reconcile it with `CLAUDE.md`'s instructions to run
    the flagged rituals (HARN-08).

### Deliberately not recommended

- **Do not re-split D-001…D-007.** Renumbering breaks the stable-ID rule and costs more than it
  returns; partial supersession is already legal (ADRS-05, REFUTED).
- **Do not delete the `contributing.md` stubs** without first repointing the 11 locked-ADR anchors
  and ~30 prose pointers — they are load-bearing (NOIS-02, REFUTED).
- **Do not strip the harvest-candidate convention** — it has a live consumer (NOIS-04, REFUTED).
- **Do not apply the `#63` de-citation work silently** — that issue defers it deliberately pending
  an owner decision, and the audit should not override a standing instruction.

---

## 9. Relationship to the existing tracker

26 of the 146 findings cite an existing open issue. The tracker is in good shape: epic #20
("Bootstrap hardening") already covers much of the bootstrap-path surface, and #25, #27, #29,
#33, #34, #59, #63, #66 and #68 each anticipate something this audit re-derived independently.

Three places where an existing issue's framing is **incomplete**, verified:

- **#63** — its acceptance criterion *"finds no remaining instruction for an agent-performed
  manual close … (stale-phrase sweep: 0 matches)"* is ticked `[x]`, but
  `running-epics.md:17-20` still carries one, descended verbatim from `contributing.md:248`
  at `964546f^` — inside #63's own declared sweep scope (AGEN-04). #63 also asserts that agent
  closes are "mechanically impossible (the hook denies it)", which SECU-07 and SCRI-02 disprove.
- **#68** — correctly documents the lossy MCP read channel and even names the fix, but does not
  identify that `/tick` step 4's verification runs through the *same* channel and therefore cannot
  detect the corruption it just caused (HARN-01).
- **#25** — correctly identifies the `nav.omitted_files` defect, but scopes the fix to
  `BOOTSTRAP.md`, the one instance a seeded project never sees. The same overclaim ships in
  `docs/process/adding-docs-pages.md` and inside ✅ Decided ADR-0001 (DOCS-05).

---

## Appendix A — all 146 findings

Severity and verdict are **after** adversarial review. "Tracked" cites the open issue the
finder or verifier matched.

| ID | Dimension | Severity | Verdict | Tracked | Claim |
|---|---|---|---|---|---|
| `AGEN-01` | agent-contract | **high** | Confirmed | — | AGENTS.md's central promise is false: 3 of the 6 hard rules it names have NO server-side CI enforcer, and the  |
| `AGEN-02` | agent-contract | **high** | Confirmed | — | Every hard-rule hook CLAUDE.md names is bypassable by an ordinary command form — and for self-merge, push-to-m |
| `CHEC-02` | checkers | **high** | Partially Confirmed | — | Four common ways to neuter a required gate are not modelled at all: `branches-ignore`, `paths-ignore`, job/ste |
| `CI-G-03` | ci-gates | **high** | Confirmed | — | Five of the seven shipped gates are never registered as required status checks, so the binary, ADR-lock and se |
| `HARN-01` | harness | **high** | Partially Confirmed | #68 | `/tick` as shipped performs a full-body rewrite from a read channel that is provably lossy, and its own verifi |
| `HARN-02` | harness | **high** | Partially Confirmed | — | Every hard-rule guard except the issue-close one is wired to the `Bash` matcher only, so the GitHub MCP write  |
| `HARN-04` | harness | **high** | Confirmed | — | `guard-git.sh` treats every token to the end of a shell segment as arguments of the first `git` it sees, so or |
| `HOOK-01` | hooks | **high** | Confirmed | — | `mcp__github__merge_pull_request` is a first-class, always-available self-merge path that no hook and no deny- |
| `HOOK-02` | hooks | **high** | Confirmed | — | Any `git` global option before the subcommand disarms guard-git.sh AND guard-adr.sh entirely — `git --no-pager |
| `MODU-04` | modules | **high** | Confirmed | — | lfs-assets produces LFS patterns that are inert without `git lfs install` — and BOTH shipped binary enforcers  |
| `SCRI-02` | script-tests | **high** | Confirmed | — | `gh -R owner/repo issue close N` is ALLOWED by `guard-issue-close.sh` — a one-flag bypass of an operator-only  |
| `SECU-06` | security | **high** | Confirmed | — | ADR-0003 claims branch protection binds PR-only advancement and required checks "at the server"; with `enforce |
| `TEMP-01` | templates-github | **high** | Confirmed | — | The shipped PR template's own example text, `"Closes #7 (partial)"`, parses as a real closing reference and ma |
| `ADRS-01` | adrs | **medium** | Partially Confirmed | — | The ADR guard does not block the 🟡→✅ promotion when the edit takes its natural minimal form — including D-007' |
| `ADRS-02` | adrs | **medium** | Partially Confirmed | — | The unlock token is self-service — an agent can mint it with one `echo`, defeating the operator-gate the `disa |
| `AGEN-04` | agent-contract | **medium** | Partially Confirmed | #63 | Two shipped process pages still instruct an agent-performed manual close, contradicting the CLAUDE.md hard rul |
| `BOOT-01` | bootstrap | **medium** | Confirmed | — | The template's own `.claude/archive/` session notes trip the bootstrap completion gate's Tier-2 grep, and BOOT |
| `BOOT-02` | bootstrap | **medium** | Partially Confirmed | — | A fully compliant bootstrap still ships literal `<Pithy imperative name.>` placeholders — the completion gate' |
| `BOOT-04` | bootstrap | **medium** | Confirmed | — | 69 citations of *this repository's* issue numbers survive into every seeded project, including two runtime BLO |
| `CHEC-01` | checkers | **medium** | Partially Confirmed | — | check_ci_gates.py never notices a required gate that has lost its `pull_request` trigger — the "gate never run |
| `CHEC-03` | checkers | **medium** | Confirmed | — | The `continue-on-error` sweep claims to cover EVERY workflow but globs only `*.yml` — a `.yaml` workflow is in |
| `CHEC-07` | checkers | **medium** | Confirmed | — | Lane A rejects prospective/hypothetical paths — the natural way to write a how-to — and the only escape hatch  |
| `CI-G-01` | ci-gates | **medium** | Partially Confirmed | — | The CI meta-gate does not pin what its own ADR claims: a required gate can be neutered by `if: false`, a stubb |
| `CI-G-02` | ci-gates | **medium** | Confirmed | — | The issue-link guard's checkbox counter misses `+ [ ]` and `1. [ ]` task items, so a PR can close an issue wit |
| `CI-G-04` | ci-gates | **medium** | Partially Confirmed | — | Every PR-triggered gate executes its own decision script from the PR's merge ref, so one PR can disable the ga |
| `DOCS-01` | docs-consistency | **medium** | Partially Confirmed | — | The strict docs build does NOT validate anchors, so the whole `contributing.md` anchor-preservation scheme and |
| `HARN-05` | harness | **medium** | Confirmed | — | Every seeded project inherits 126 lines / 850 words of *this* repo's 2026-07-24 session reproduction notes, an |
| `HARN-06` | harness | **medium** | Partially Confirmed | — | The docs-truth path checker — advertised in CLAUDE.md as the enforcer for backtick-cited paths — does not scan |
| `HARN-07` | harness | **medium** | Confirmed | — | The three seam files normalise no whitespace: a CRLF `asset-dirs.txt` desynchronises the hook and the CI backs |
| `HARN-08` | harness | **medium** | Partially Confirmed | — | 9 of the 11 ritual commands carry `disable-model-invocation: true`, so the agent cannot run the commands CLAUD |
| `HOOK-03` | hooks | **medium** | Partially Confirmed | — | Force-push detection matches three exact strings; `-fu`, `--force-with-lease=<ref>`, `--force-if-includes` and |
| `HOOK-04` | hooks | **medium** | Confirmed | — | Splitting the raw command on shell metacharacters *before* tokenizing produces real false blocks: an innocent  |
| `HOOK-07` | hooks | **medium** | Confirmed | — | The meta-gate pins "every registered deny-hook has a suite" but not the reverse — deleting every PreToolUse ho |
| `LIFE-01` | lifecycle | **medium** | Partially Confirmed | — | The version stamp UPDATE.md reads is enforced by nothing and explained by nothing that survives bootstrap |
| `LIFE-05` | lifecycle | **medium** | Partially Confirmed | — | UPDATE.md has no repo-settings step, so a gate delivered by a version bump arrives downstream present but non- |
| `MODU-02` | modules | **medium** | Confirmed | #20, #33 | python-package step 4 installs with bare `pip` while step 5 of the same file explains why only `python3 -m` bi |
| `NOIS-01` | noise | **medium** | Partially Confirmed | — | 26 blueprint-tracker issue numbers ship into the inherited set; in `.github/pull_request_template.md` they are |
| `NOIS-05` | noise | **medium** | Partially Confirmed | #20, #24, #34 | BOOTSTRAP step 7's promised safety net scans only `docs/**` and 8 root `.md` files, so blueprint archaeology i |
| `NOIS-06` | noise | **medium** | Confirmed | — | Every seeded project inherits this repository's own 2026-07-24 session forensics (`.claude/archive/`, 126 line |
| `SCRI-01` | script-tests | **medium** | Confirmed | — | Mutation testing: 8 of 11 realistic single-line mutations to `guard-git.sh` survive its suite — including the  |
| `SCRI-03` | script-tests | **medium** | Confirmed | — | Neither ADR-lock layer tests that the unlock names the ADR being changed — and `test_guard_adr.sh` has a secti |
| `SCRI-07` | script-tests | **medium** | Confirmed | — | Both Bash hooks split on `|` before quote-aware parsing, so a pipe character inside a quoted string shreds the |
| `SECU-01` | security | **medium** | Partially Confirmed | — | docs.yml grants `pages: write` and `id-token: write` to every job, including the PR-triggered `build` job that |
| `SECU-05` | security | **medium** | Partially Confirmed | — | A mistyped `--profile` value silently applies the *data* profile: `github_setup.sh` exits 0 reporting "setup c |
| `SECU-07` | security | **medium** | Partially Confirmed | #60, #63 | `guard-issue-close.sh` allows seven of seven adversarial close paths, two of which its own header says it bloc |
| `WEIG-01` | weight-value | **medium** | Partially Confirmed | — | The framework ships no low-ceremony lane: a typo fix pays 9 process steps and ~4,170 words of required reading |
| `WEIG-02` | weight-value | **medium** | Partially Confirmed | #28 | Archetype A (solo, private repo, GitHub Free) gets zero server-side enforcement, and `AGENTS.md` states the op |
| `WEIG-06` | weight-value | **medium** | Partially Confirmed | #29 | `make verify` — the framework's entire definition of done — runs on an unpinned floating toolchain, while two  |
| `WEIG-07` | weight-value | **medium** | Partially Confirmed | — | 29 enforcement mechanisms verify the *process* and none verify the *product*: there is no runtime/product test |
| `ADRS-03` | adrs | **low** | Partially Confirmed | — | `writing-adrs.md` overclaims Bash coverage: the hook's Bash branch catches only literal `git rm`/`git mv` adja |
| `ADRS-04` | adrs | **low** | Partially Confirmed | — | The ADR lock has already forced 13 redirect-stub sections into `docs/process/contributing.md` that exist solel |
| `ADRS-05` | adrs | **low** | Refuted | — | Bundled ADRs collide with the supersede-never-rewrite rule — D-004 already carries two in-page 🧊 deferrals who |
| `ADRS-06` | adrs | **low** | Partially Confirmed | — | Load-bearing, hook-enforced doctrine has no D-number — most sharply the operator-only-close rule, whose entire |
| `ADRS-07` | adrs | **low** | Partially Confirmed | — | A seeded project inherits D-001…D-007 as its own Decided, locked decisions — written in blueprint voice, un-to |
| `ADRS-08` | adrs | **low** | Partially Confirmed | — | The CI layer D-004 calls "binding" parses ADR status more narrowly than the client hook it is supposed to back |
| `ADRS-09` | adrs | **low** | Partially Confirmed | — | Nothing checks ADR *shape* — and the four documents that describe it disagree on whether "Alternatives conside |
| `AGEN-03` | agent-contract | **low** | Confirmed | #34, #59 | `.claude/rules/README.md` has no `paths:` frontmatter, so by the directory's own documented semantics it loads |
| `AGEN-05` | agent-contract | **low** | Partially Confirmed | — | "Exceptions are commit trailers with a mandatory reason — machine-checked" is an overclaim on both halves: the |
| `AGEN-06` | agent-contract | **low** | Partially Confirmed | — | Three CLAUDE.md rules are neither enforcer-named nor marked advisory — direct violations of the file's own "Ne |
| `AGEN-07` | agent-contract | **low** | Partially Confirmed | #63 | 64 dangling tracker-ID citations from THIS repo's issue tracker ship into every seeded project — including 4 i |
| `AGEN-08` | agent-contract | **low** | Partially Confirmed | #59 | CLAUDE.md pays 2,816 always-loaded words to restate an on-demand canon of 2,314 words — the "Repo workflow" se |
| `AGEN-09` | agent-contract | **low** | Partially Confirmed | — | The SessionStart hook silently `pip install`s from the checked-out tree on every fresh session — the exact act |
| `AGEN-10` | agent-contract | **low** | Partially Confirmed | — | The contract has no non-interactive mode: "a failed question is a hard block" plus five hard STOPs across the  |
| `BOOT-03` | bootstrap | **low** | Confirmed | #24 | The only file step 7 names by name (`scripts/README.md`) is the one file no checker can see — its dead row sur |
| `BOOT-05` | bootstrap | **low** | Partially Confirmed | — | Two mandatory bootstrap decisions live only in seam files the interview never asks about, and the release seam |
| `BOOT-06` | bootstrap | **low** | Partially Confirmed | — | Step 4 orders the bootstrap session to run `/unlock-adr adr-0007`, a slash command the session cannot invoke — |
| `BOOT-07` | bootstrap | **low** | Partially Confirmed | — | A fully compliant bootstrap still leaves blueprint archaeology in the always-loaded files — enumerated |
| `BOOT-08` | bootstrap | **low** | Partially Confirmed | #29 | No toolchain prerequisite anywhere on the bootstrap path — and `.claude/settings.json`'s allow-list contains n |
| `BOOT-09` | bootstrap | **low** | Confirmed | #25 | Confirmed at v1.0.4 with the shipped `mkdocs.yml`: step 2.3's "the reverse also fails under `--strict`" is fal |
| `CHEC-04` | checkers | **low** | Partially Confirmed | — | Lanes B, E and F have zero inputs in the shipped template and skip entirely silently — three of six lanes are  |
| `CHEC-05` | checkers | **low** | Confirmed | — | The `(open)` alternative in `ISSUE_OPEN_CLAIM_RE` is unreachable for normal spacing, and the regex misses 8 of |
| `CHEC-06` | checkers | **low** | Partially Confirmed | #20 | `check_bootstrap_complete.sh` reports a clean bootstrap on a tree that `make verify` immediately rejects with  |
| `CHEC-08` | checkers | **low** | Partially Confirmed | — | Broken in-page anchors pass both `mkdocs --strict` and `check_docs_truth` — 24 anchor links ship in the inheri |
| `CHEC-09` | checkers | **low** | Partially Confirmed | — | `check_docs_truth`'s scan surface excludes `.claude/` and `.github/` markdown — 39 live backtick path citation |
| `CHEC-10` | checkers | **low** | Partially Confirmed | — | Seeded-project fit: 1,449 lines of Python with no external test file, hardcoding this repo's workflow list and |
| `CI-G-05` | ci-gates | **low** | Partially Confirmed | — | The release seam ships pointing at `blueprint/` — the directory BOOTSTRAP deletes — and no bootstrap step, gat |
| `CI-G-06` | ci-gates | **low** | Confirmed | — | `docs.yml` grants `pages: write` + `id-token: write` at workflow level, so the PR-triggered `build` job execut |
| `CI-G-07` | ci-gates | **low** | Partially Confirmed | — | `github-actions` in the issue-close guard's `ALLOWED_APPS` ledger is a live bypass of the operator-only close  |
| `CI-G-08` | ci-gates | **low** | Confirmed | — | The `Unlock-ADR` trailer is accepted with no reason, unlike both of its sibling trailers and contrary to D-004 |
| `CI-G-09` | ci-gates | **low** | Confirmed | — | The release gate's caboose check is "the version string appears somewhere in the log at HEAD", not "this PR ad |
| `DOCS-02` | docs-consistency | **low** | Partially Confirmed | — | Six section anchors were dropped in the contributing.md split with no stub, leaving at least one dangling pros |
| `DOCS-03` | docs-consistency | **low** | Partially Confirmed | — | "One status legend everywhere" is asserted in four places while the repo ships six mutually different legends  |
| `DOCS-04` | docs-consistency | **low** | Partially Confirmed | — | The docs' own map of the docs is stale post-split and omits `records/lessons.md`, a page `CLAUDE.md` marks as  |
| `DOCS-05` | docs-consistency | **low** | Partially Confirmed | #25 | The docs page whose whole subject is "what the docs gates enforce" repeats *both* strict-build overclaims in o |
| `DOCS-06` | docs-consistency | **low** | Partially Confirmed | #63 | `closing-issues.md` tells you an issue "is closed manually … with its readout as the closing comment" 44 lines |
| `DOCS-07` | docs-consistency | **low** | Partially Confirmed | — | The ADRs duplicate their topic pages nearly verbatim, breaking the repo's own "ADRs link rather than duplicate |
| `DOCS-08` | docs-consistency | **low** | Partially Confirmed | — | 60% of the contributing hub is a redirect table preserving *this repo's* refactor history; a seeded project in |
| `DOCS-09` | docs-consistency | **low** | Partially Confirmed | #59 | A seeded project inherits ~14,300 words of docs of which ~86% is process/decision doctrine and 0% is about the |
| `HARN-03` | harness | **low** | Refuted | — | The hard rule "never commit directly to `main` or `development`" has no enforcer at any layer: `Bash(git commi |
| `HARN-09` | harness | **low** | Confirmed | #34, #59 | `.claude/rules/README.md` has no `paths:` frontmatter, so by its own documented semantics it is always-loaded  |
| `HARN-10` | harness | **low** | Partially Confirmed | #59 | Always-loaded instruction measured at 2,882 words, of which CLAUDE.md is 2,702 — and CLAUDE.md has GROWN 93 wo |
| `HOOK-05` | hooks | **low** | Partially Confirmed | — | All three PreToolUse guards are a `python3` heredoc; with no `python3` on PATH they exit 127 and every hard ru |
| `HOOK-06` | hooks | **low** | Partially Confirmed | — | The `Stop` hook `stale-working-docs.sh` writes its nudge to stderr and exits 0 — the pattern that delivers the |
| `HOOK-08` | hooks | **low** | Partially Confirmed | #20, #29 | session-start.sh's dependency bootstrap discards all output and `|| true`s the failure — the "so `make verify` |
| `HOOK-09` | hooks | **low** | Partially Confirmed | — | The whole zombie-push defence (hook check + session-start verdict line) is silently inert wherever `gh` is mis |
| `HOOK-10` | hooks | **low** | Confirmed | — | `.claude/rules/config-cites-decision.md` — the worked example for "config files cite their governing decision" |
| `LIFE-02` | lifecycle | **low** | Partially Confirmed | — | The FROM/TO span is a version *number*, never a commit — a project seeded between tags, or an update run from  |
| `LIFE-03` | lifecycle | **low** | Partially Confirmed | — | After the first update the README stamp and the birth commit disagree by design, and UPDATE.md states no prece |
| `LIFE-04` | lifecycle | **low** | Partially Confirmed | #20, #32 | HARVEST's definition-by-exclusion classifies the per-project seam data files as "literal", and step 2 cannot r |
| `LIFE-06` | lifecycle | **low** | Partially Confirmed | — | An abandoned promotion permanently wedges the release-gate, and the error message misdirects the recovery |
| `LIFE-07` | lifecycle | **low** | Confirmed | — | The release-gate's release-log check is an unanchored substring grep — a version with no entry passes if anoth |
| `LIFE-08` | lifecycle | **low** | Confirmed | — | HARVEST.md's tag command contradicts /promote on both tag type and owner, and duplicates a fact /promote is de |
| `LIFE-09` | lifecycle | **low** | Partially Confirmed | — | Blueprint version semantics are defined nowhere, and /promote's bump-class vocabulary is blueprint archaeology |
| `LIFE-10` | lifecycle | **low** | Partially Confirmed | — | ADOPT.md is aspirational: its central deliverable has no invariant list, no template, and no exit criterion |
| `MODU-01` | modules | **low** | Confirmed | — | The python-package Makefile snippet, copied as it is written in MODULE.md, breaks `make verify` with "missing  |
| `MODU-03` | modules | **low** | Confirmed | #33 | Issue #33 confirmed by execution — and its own enumeration of the payload's judgment markers is incomplete |
| `MODU-05` | modules | **low** | Partially Confirmed | #20, #3 | data-repo's "push `seed/` as its initial commit" ships with zero mechanics — the natural in-place `git init` r |
| `MODU-06` | modules | **low** | Partially Confirmed | — | data-repo's ADR payload is not shippable as-is: MODULE.md never states the destination filename, the payload's |
| `MODU-07` | modules | **low** | Confirmed | #27 | Confirmed: the data-repo `gh` path pushes the seed from a directory both completion-gate lanes exclude (#27) |
| `MODU-08` | modules | **low** | Partially Confirmed | — | Nothing verifies a module was applied *correctly*, or applied *at all* — the only mechanical trace is the toke |
| `MODU-09` | modules | **low** | Partially Confirmed | — | The module set covers one of the eight project shapes the template's own tooling recognizes — as shipped it is |
| `MODU-10` | modules | **low** | Partially Confirmed | — | lfs-assets combined with the in-repo-assets posture is self-defeating: listing the asset dir in `.claude/asset |
| `NOIS-02` | noise | **low** | Refuted | — | `docs/process/contributing.md` ships 65 lines of "Moved:" redirect stubs whose stated justification ("long-sta |
| `NOIS-03` | noise | **low** | Partially Confirmed | — | The server-side issue-close guard automatically POSTs a comment containing `#54` onto a seeded project's issue |
| `NOIS-04` | noise | **low** | Refuted | — | `CLAUDE.md` permanently instructs every seeded project to file "harvest candidate" note issues for a blueprint |
| `NOIS-07` | noise | **low** | Partially Confirmed | — | `docs/direction/design-principles.md` ships three empty `P1/P2/P3` placeholder stubs OUTSIDE the `BLUEPRINT:`  |
| `NOIS-08` | noise | **low** | Partially Confirmed | — | Every seeded project's `guard-git.sh` permanently carries the one-shot bootstrap birth-push exemption — 32 lin |
| `NOIS-09` | noise | **low** | Confirmed | — | Template-voice prose ("the blueprint's conventions", "every seeded project", "the template ships this gate") s |
| `NOIS-10` | noise | **low** | Partially Confirmed | — | The "literal files stay byte-identical" contract is defined only in files deleted at bootstrap, and it covers  |
| `SCRI-04` | script-tests | **low** | Partially Confirmed | — | The CI ADR lock uses a stricter Status regex than the hook it claims to mirror, so a bullet-less `**Status:**  |
| `SCRI-05` | script-tests | **low** | Confirmed | — | Exit-code-only assertions make several cases vacuous: the mutated branch still exits with the expected code vi |
| `SCRI-06` | script-tests | **low** | Confirmed | — | `issue_link_decision.sh`'s unchecked-box threshold survives an off-by-one mutation: every fixture has ≥2 unche |
| `SCRI-08` | script-tests | **low** | Partially Confirmed | — | The meta-gate's "every deny-hook has a wired suite" check pins only a filename and a Makefile substring — an e |
| `SCRI-09` | script-tests | **low** | Partially Confirmed | — | `scripts/README.md` documents 11 of the 18 scripts it ships — the three CI decision scripts and four of the ei |
| `SECU-02` | security | **low** | Partially Confirmed | — | The pinned gitleaks binary is 12 minor versions stale with no updater, and the adjacent `pip-audit` install is |
| `SECU-03` | security | **low** | Confirmed | — | The gitleaks binary is fetched over the network into CI with no checksum or signature verification |
| `SECU-04` | security | **low** | Partially Confirmed | — | The secret gate scans only the working tree, so a PR that adds a secret in one commit and removes it in a late |
| `SECU-08` | security | **low** | Partially Confirmed | — | Nothing pins workflow `permissions:` blocks, and `github_setup.sh` enables none of GitHub's free repository se |
| `SECU-09` | security | **low** | Partially Confirmed | — | The weekly dependency sweep audits `>=` floors, not pins — it resolves to the newest release every run, so it  |
| `SECU-10` | security | **low** | Partially Confirmed | — | `docs/process/enforcement.md` names the gitleaks allowlist a reference implementation of the four-rule ledger, |
| `TEMP-02` | templates-github | **low** | Confirmed | — | `scripts/test_issue_link_guard.sh` never feeds the shipped PR templates to the guard, so the template↔gate con |
| `TEMP-04` | templates-github | **low** | Confirmed | — | `.github/ISSUE_TEMPLATE/*.yml` and `docs/.templates/*-issue-body.md` are declared equivalent ("the same struct |
| `TEMP-05` | templates-github | **low** | Partially Confirmed | — | `epic-page-template.md` names a five-beat arc (goal → built → found → decided → carried forward) and ships hea |
| `TEMP-07` | templates-github | **low** | Partially Confirmed | — | Dependency watching covers only the docs toolchain: the one module that ships a real dependency manifest never |
| `TEMP-08` | templates-github | **low** | Partially Confirmed | — | The promotion template calls its restated `Closes #N` lines "a harmless no-op", but `issue-link-guard` is a re |
| `TEMP-09` | templates-github | **low** | Partially Confirmed | — | `SECURITY.md`'s primary reporting channel is conditional on a repo setting nothing in the blueprint ever enabl |
| `WEIG-03` | weight-value | **low** | Partially Confirmed | #66 | The contributing.md act-split added 915 words to every seeded project and left 13 `CLAUDE.md` pointers landing |
| `WEIG-04` | weight-value | **low** | Confirmed | — | `.claude/archive/` ships this repository's own bug-reproduction notes — about files that no longer exist — int |
| `WEIG-05` | weight-value | **low** | Partially Confirmed | — | The bootstrap interview never asks how heavy the project wants to be: all 8,840 lines ship undifferentiated, a |
| `WEIG-08` | weight-value | **low** | Partially Confirmed | — | The framework has an entrance for every rule and an exit for none: no doctrine, ritual, or review point for *r |
| `WEIG-09` | weight-value | **low** | Partially Confirmed | — | Nothing in the framework addresses concurrent agents, and the taxonomy that would break first (epics with sub- |
| `WEIG-10` | weight-value | **low** | Refuted | — | An unattended agent session hits at least five hard operator-only stops with no documented fallback, and `CLAU |
| `CI-G-10` | ci-gates | **not-a-finding** | Refuted | — | Gate error messages and the auto-posted revert comment hardcode this repo's issue numbers, which resolve to un |
| `SCRI-10` | script-tests | **not-a-finding** | Refuted | #29 | The Makefile ships exactly one target and no day-one affordances — no `serve`, no `help`, no fast lane, and no |
| `TEMP-03` | templates-github | **not-a-finding** | Refuted | — | The task templates put "Acceptance criteria" in task-list checkboxes, but `issue-link-guard` counts every box  |
| `TEMP-06` | templates-github | **not-a-finding** | Refuted | — | `.github/CODEOWNERS` is a guaranteed no-op in the configuration the blueprint ships, and its own comment overs |

---

## Appendix B — how this was produced

Three workflow runs against the repository at
`claude/framework-audit-report-vv2udn`, 2026-07-29:

1. **Survey (failed).** 15 auditors; destroyed by a transient tool-permission fault in the
   execution environment that rejected every tool call, including structured output. 726k tokens,
   no usable findings. Two agents from before the fault were salvaged from their transcripts.
2. **Survey (succeeded).** 15 auditors, file-based output so partial work survives a repeat fault.
   146 findings. 2.27M tokens, 839 tool calls, 115 min.
3. **Adversarial refutation.** 44 independent verifiers, batched 3 (high/critical) or 5
   (medium/low) per verifier, instructed to default to REFUTED. 5.30M tokens, 1,700 tool calls,
   196 min.

**Adversarial verification grade: 2 (independent verify), applied to all 146 findings.** Not
grade 3 — verification was single-vote per finding, not a multi-checker sweep, and a second round
would likely move more findings. The first round moved 108 of 146, which is the honest measure of
how much a survey's self-assessment is worth.

**Orchestrator's own contribution**, executed directly rather than delegated: the guard bypass
table in §4.1; the `enforce_admins` semantics (checked twice against GitHub's documentation); the
`.claude/archive/` inheritance; and every measurement in this report, each re-derived from the
repository so that no published figure rests on an agent's unverified count.

**Repository state:** unmodified. `git status --short` empty; this file is the only addition.
