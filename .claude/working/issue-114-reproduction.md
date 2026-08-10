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
