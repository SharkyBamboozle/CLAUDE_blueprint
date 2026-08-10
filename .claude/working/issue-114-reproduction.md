# Reproduction — gh-mock bypass in test_guard_git.sh (issue #114)

## Hypothesis (context only, NOT load-bearing)

Issue #114 claims: the suite's hermetic `gh` mock is delivered only via a
PATH-prepended extensionless shebang script; on Windows the hook's native
Python resolves `subprocess.run(["gh", ...])` through CreateProcess, which
cannot execute such a script, silently falls through to the real `gh.exe`,
and the two rc=2 zombie cases fail with rc=0 (live API answers "no PRs" →
fail-open → push allowed). On Linux at HEAD the suite is green (control).
Recommended fix: explicit `GUARD_GH_BIN` seam in `dead_pr()`; suite delivers
the mock through the seam; the PATH copy becomes a static `[]` decoy so a
seam revert goes red on Linux, where CI runs.

## Reproduction (load-bearing)

- Commit: 76e6c9f (= origin/development tip) · Linux container ·
  Python 3.11.15 · GNU bash 5.2.21 · no real `gh` on PATH
  (`command -v gh` returns nothing)
- Command: `bash scripts/test_guard_git.sh`
- Exit code: 0 · Key output: all 34 cases PASS — including both rc=2
  zombie cases and "gh unavailable/errors -> allowed (fail OPEN by
  design)" — final line `all asserted cases pass`.
- The Windows-side failure is NOT reproducible in this environment (no
  Windows host). It stays hypothesis-class here: reported downstream
  evidence (transcript in the provenance note) + documented CreateProcess
  behavior. The Linux control above matches the issue's "measured" block
  exactly, so the brief and the reproduction agree — no HALT.

## Diagnosis (grounded ONLY in the reproduction block)

The zombie cases pass on this box **with no real `gh` installed**, so the
PATH-prepended mock at `$TMP/bin/gh` is necessarily what answered the
hook's spawn — nothing else on this machine could have. Mock delivery
therefore rides entirely on POSIX PATH + shebang execution semantics; the
suite carries no other delivery channel. Any platform (or future spawn
mechanism) that resolves argv[0] without honoring shebang scripts gets no
mock and no error — `dead_pr()`'s fail-open design converts every such
miss into "push allowed", which flips exactly the two rc=2 cases.

Fix: move delivery onto an explicit argv seam (`GUARD_GH_BIN`,
shlex-split, default `["gh"]`) and make the PATH slot a decoy that
disagrees with the mock (`[]`, rc 0). Then a regression to PATH delivery
is visible on Linux: reverted hook → PATH finds decoy → `[]` → fail-open
allow → both rc=2 zombie cases FAIL.

## Fix evidence (same command, after)

- Fixed tree (commit 6514d97): `bash scripts/test_guard_git.sh` → rc=0,
  all 34 cases PASS, `all asserted cases pass`. The two rc=2 zombie
  cases now pass THROUGH the seam — the PATH decoy would answer `[]`
  and allow, so their PASS is itself the seam-over-PATH proof.
- Revert check (dead_pr spawn temporarily reverted to bare
  `["gh", ...]`, suite changes kept): suite rc=2 — exactly the two
  zombie cases FAIL (`FAIL (rc=0, want 2)` both), all other 32 PASS,
  including "gh unavailable/errors -> allowed (fail OPEN by design)".
  Fix restored via `git checkout -- .claude/hooks/guard-git.sh`; suite
  back to rc=0.
- Seam default: python one-liner — unset and empty `GUARD_GH_BIN` both
  yield argv prefix exactly `['gh']`.
- `make verify` → rc=0 (all eight suites, bash -n loop, strict mkdocs
  build, check_ci_gates + check_docs_truth incl. self-tests). Note:
  mkdocs was absent in this container; installed per
  docs/process/contributing.md (`pip install -r docs/requirements.txt`,
  with `--ignore-installed` to bypass the Debian-owned PyYAML) — an
  environment gap, not a repo defect.

## Round 2 — Windows verification failed; second bare-name trap

Windows pass (issue comment, 2026-08-10, MINGW64 + Python 3.13.1 via
PATH shim): control 76e6c9f reproduced the defect exactly (2 zombie
FAILs); fix branch 8822588 FAILED IDENTICALLY — 32/34, same two cases.

Their diagnosis, accepted on measured evidence: the suite's seam value
`bash $TMP/mock/gh` re-trips the same class of trap the seam was built
to avoid — CreateProcess resolves the bare name `bash` through System32
BEFORE PATH, finding the WSL launcher (rc=1 "no installed
distributions" → dead_pr fail-open → allowed → red). Their probes:
shutil.which (PATH-only) disagrees with CreateProcess; with an explicit
absolute Git Bash path the mock answered `[{"number":9,"state":
"MERGED"}]` rc=0 through the seam — hook-side seam confirmed sound.

Fix (commit 1075cfe): suite resolves the RUNNING bash to an absolute
path — `$BASH` + `.exe` probe + `cygpath -m` (Windows-mixed C:/ form),
POSIX no-ops — and shlex-quotes both seam tokens ("C:/Program
Files/..." has a space). New Linux-expressible FORM pin: seam program
token must be absolute (bare-vs-absolute cannot diverge behaviorally on
POSIX, so the form is what CI can hold). Hook + suite comments name the
System32 trap.

Evidence at 1075cfe (Linux): suite rc=0, 35 asserted (form pin + 34
cases); revert check (hook → bare `["gh"]`, suite kept) → exactly the
two zombie FAILs, rc=2, restored green; form-pin negative (SEAM_BASH
forced to bare `bash`) → `FAIL (form)`, rc=1, restored green; seam
value composes as `"/usr/bin/bash" "/tmp/.../mock/gh"`; make verify
rc=0. Process note: round-2 edits were once wiped by `git checkout --`
restores made before committing (restores pull from HEAD); re-applied,
committed FIRST, all checks re-run against the committed tree. Windows
re-verification: pending (round 2).
