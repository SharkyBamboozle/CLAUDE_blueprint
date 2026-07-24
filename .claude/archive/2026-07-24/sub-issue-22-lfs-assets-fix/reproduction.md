# Reproduction — sub-issue #22 (epic #20, F2): lfs-assets literal application

## Hypothesis (context only, NOT load-bearing)

Issue #22 claims: the lfs-assets pattern menu ships fully commented out, and
neither `modules/lfs-assets/MODULE.md` nor the payload header says to
*uncomment* — both say only to "append the chosen lines/patterns". A session
following the steps verbatim therefore produces a root `.gitattributes` that
filters nothing, silently; the template also ships no root `.gitattributes`,
and no step verifies the result. Evidence in the issue is pinned at v1.0.2.

## Reproduction (load-bearing)

- Commit: `16b9dce` (current `main`, post-v1.0.3 promotion) · git 2.43.0 ·
  clean checkout, no fixes applied.
- Shipped instruction texts at this commit (verbatim):
  - `modules/lfs-assets/MODULE.md:21-22` — "…and append the chosen patterns
    to the repo's `.gitattributes`…"
  - `modules/lfs-assets/.gitattributes:6` — "Append the chosen lines to the
    repo's root .gitattributes."
  - "uncomment" appears in neither file (`grep -ri uncomment modules/` → no
    matches).
- `git ls-files | grep -x '.gitattributes'` → no match: the template ships
  **no root `.gitattributes`** (must be created; instructions don't say so).
- Literal application in a fresh `git init` repo (scratchpad
  `lfs-repro/literal-before/`): chose the `.glb` menu line and appended it
  as shipped —
  - Command: `grep 'assets/\*\*/\*\.glb' modules/lfs-assets/.gitattributes
    > .gitattributes` → file content:
    `# assets/**/*.glb  filter=lfs diff=lfs merge=lfs -text`
  - Command: `git check-attr filter -- assets/example.glb`
  - Exit code: 0 · Key output: `assets/example.glb: filter: unspecified`
- Nothing failed loudly at any point: the result is a syntactically valid
  `.gitattributes` with zero effect.

## Diagnosis (grounded ONLY in the reproduction block)

Every menu entry is a `#` comment and the shipped instructions say only
"append", so verbatim execution copies comments; `git check-attr` proves the
resulting file filters nothing (`filter: unspecified`), and no instruction
step runs any such check, so the no-op is silent. Fix accordingly: (1) both
instruction sites must say *uncomment the chosen lines (strip the leading
`# `)* and *create the root `.gitattributes` if it does not exist*; (2) a
mandatory verify step must require `git check-attr filter -- <matching
path>` to print `filter: lfs` before continuing; (3) per the
config-cites-decision rule, the created file gets a D-007 header comment.

**Verdict: reproduction CONFIRMS the brief → proceed.** Fix evidence = the
same `git check-attr` command flipping from `filter: unspecified` to
`filter: lfs` when the *new* instructions are followed verbatim.

## Fix re-run (same command, after edits)

Fresh `git init` repo (scratchpad `lfs-repro/verbatim-after/`), following the
**new** step 1 + 2 verbatim: uncommented the chosen `.glb` line (stripped
leading `# `), created root `.gitattributes` (none exists), D-007 header
comment first.

- File content:
  `# Git LFS patterns for authored assets — D-007 (binary hygiene).`
  `assets/**/*.glb  filter=lfs diff=lfs merge=lfs -text`
- Command (same as reproduction): `git check-attr filter -- assets/example.glb`
- Output: `assets/example.glb: filter: lfs` — **flipped from
  `filter: unspecified`**; acceptance criterion met.
- Negative control: `git check-attr filter -- example.glb` →
  `example.glb: filter: unspecified` (directory scoping intact — menu
  contents untouched per the issue's non-scope).
- `make verify` after the edits: strict mkdocs build OK, check_ci_gates
  self-test + run OK, check_docs_truth self-test + run OK.
