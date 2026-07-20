---
description: End a working session — changelog entry, findings sweep, state check
disable-model-invocation: true
---

Close out this working session. Steps, in order:

1. **Changelog entry** — prepend (newest first, under the header) to
   `docs/records/changelog.md`:
   `### Session N (YYYY-MM-DD) — <title>` (next free N), then 3–8 sentences:
   what was attempted → what landed (PRs/commits) → what was found (link
   `note` issues) → what was decided (link `D-xxx`) → what carries forward.
2. **Findings sweep** — scan this session for observations that were noticed
   but never filed. File each as a `note` issue per /note (cross-linked to
   its epic). If unsure whether something is worth a note, list it and ask.
3. **Lessons reflection (gated)** — did this session learn something a
   future session must not re-learn (an expensive dead-end, a broken
   assumption, a real "never again")? If yes, PROPOSE an entry per the
   skeleton in `docs/records/lessons.md` (dated, one screen, real incidents
   only) and append it ONLY on explicit approval — "skip" is a legitimate
   answer and is simply reported. If nothing qualifies, say so in one line
   and move on. Never write to `docs/` without the approval.
4. **State check** — report honestly:
   - `git status`: any uncommitted work? (Report it; do not auto-commit.)
   - Current branch pushed? Any open PR and its CI state?
   - Anything claimed done this session that was NOT verified end-to-end?
5. **Verify** — if the working tree touched docs or code, run `make verify`
   and include the result.
6. Report: the changelog entry text, the lessons proposal and its verdict,
   notes filed, and the exact state the next session will find (branch, PR,
   loose ends).
