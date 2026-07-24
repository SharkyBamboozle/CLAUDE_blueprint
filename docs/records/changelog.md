# Changelog

Per-session narrative — the **chronological diary** of the project and its
inter-session memory. One entry per working session, **prepended newest first**
(newest entry directly under the header, `Session N` down to `Session 1` at the
bottom — mirroring `lessons.md` and `blueprint/CHANGELOG.md`); session numbers
are citable IDs (provenance tags elsewhere read *(Session N)*).

**Entry grammar:** `### Session N (YYYY-MM-DD) — title`, then 3–8 sentences:
what was attempted → what landed (PRs/commits) → what was found (link `note`
issues) → what was decided (link `D-xxx`) → what carries forward.

### Session 2 (2026-07-24) — /tick ritual: attestation-first box ticking (#52)

Resolved #52 by adding the `/tick` ritual command (`.claude/commands/tick.md`)
— a model-invocable card that front-loads the per-box question *did I deliver
this?* (named evidence, or no tick) and scripts the awkward read-modify-write
of an issue body — then wired it in at five work-time sites (CLAUDE.md ticking
bullet + ritual list, `contributing.md`, the task-issue template, the PR
template). Landed on PR #53 into `development`; `make verify` green end to end,
and no enforcement surface changed (implements D-004/D-006; no decision
changes — the command is an affordance for the existing `issue-link-guard`,
not a new gate). Dogfooded the new command on #52's own eight
deliverable/acceptance boxes as its first live exercise: the session read tool
HTML-encodes issue bodies while the write tool takes raw, so the anchored flip
`html.unescape`d before flipping only the attested lines and verified
byte-identity by re-read — a concrete datum for the clobber risk #52 names.
Carries forward: nothing blocking; PR #53 awaits review/merge into
`development`.

### Session 1 (<!-- BLUEPRINT: date -->) — Project start

<!-- BLUEPRINT: first entry — initialized from Project Blueprint vN; which
modules were applied; the first real decisions/questions filed. -->
