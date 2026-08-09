# issue-link-guard waiver announcement — reproduction

## Hypothesis (context only, NOT load-bearing)

Issue #82 claims: the guard collects `Skip-Issue-Link-Guard` trailers from
every commit in the PR range but keeps only the first extracted line
(`head -n1`, `scripts/issue_link_decision.sh:56-58`). `git log` prints newest
first, so the **newest** trailer is quoted as THE declared exception. On a
promotion PR (range = everything since the last release) this announced a
false reason on PR #81: the annotation quoted an obsolete trailer for an
already-fixed finding instead of the trailer arguing the live finding.
Evidence table in the issue was verified 2026-08-09 at `fe8d906`.

## Reproduction (load-bearing)

- Commit: `efb2ff8` (tip of `development`, branch `claude/issue-82-d14ywt`) ·
  bash suite, mocked `gh` — hermetic, no network.
- Evidence re-check at `efb2ff8` (development moved past `fe8d906`): all nine
  rows still hold — `head -n1` present at lines 56-58; trailer commits
  `de88a58` 07:46:38 / `964546f` 06:41:13 (newest wins); `blueprint/VERSION`
  = 1.0.5, last caboose `25b328e`; 0 trailers since the caboose (dormant); no
  trailer ever written names an issue number; both competing authors
  `Claude`; one `head -n1` site in scripts/hooks; every existing waiver case
  single-trailer; no "waiv" match in promote.md / releases.md.
- Command: `bash scripts/test_issue_link_guard.sh` with three new two-trailer
  `check_out` cases appended (fixture #70, live unchecked box; COMMITS carries
  a newest trailer arguing an unrelated already-fixed finding and an older
  trailer arguing the real box).
- Exit code: suite exits 3 — the three new cases FAIL, all 30 existing cases
  PASS:
  - `FAIL (; forbidden /Declared exception \(commit trailer\):/ present)` —
    a single trailer is presented as THE reason.
  - `FAIL (; missing /::warning::.*older trailer, argues the real unchecked
    box/)` — the older reason never reaches the annotation.
  - `FAIL (; missing /::warning::.*could not be fully evaluated.*older
    trailer…/; forbidden … present)` — same defect on the infra waiver exit.
- Direct run of the unmodified script (same two-trailer COMMITS, mocked gh),
  exit 0, annotation verbatim:

  ```
  ::warning::issue-link-guard: passed on WAIVER, not on merits — 1 blocking
  finding(s) waived (listed in the job log). Declared exception (commit
  trailer): 'Skip-Issue-Link-Guard: newest trailer, argues an unrelated
  finding that is already fixed'
  ```

  The trailer arguing the live finding is silently dropped.

## Diagnosis (grounded ONLY in the reproduction block)

`WAIVER_REASON` keeps one line of the extracted trailer list (`head -n1` on
`git log`-ordered COMMITS → the newest trailer). Both waiver exits then quote
that single value as the declared exception. Exit codes are correct (a
trailer exists → 0); only the announcement is wrong. Fix per the selected
scope: keep the whole list, announce every reason inside the `::warning::`
annotation at both waiver exits (newline-escaped `%0A` — an annotation is one
line), present none as THE reason; no exit-code changes. Ritual side:
`/promote` step 4 + releases.md state the true per-finding reason in the
promotion PR body (advisory, D-004 — nothing checks a PR body; the guard
cannot match a trailer to a finding, so a human states the match).
