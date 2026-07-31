# Lessons

The distilled **"never again" list** — an append-only ledger of load-bearing
lessons this project has paid for. The [changelog](changelog.md) is the
chronological diary; this page keeps only what must change future behaviour.
**Read it before starting substantial work; append to it when a session
learns something expensive** (the `/session-close` reflection step proposes
candidates — entries land only on explicit approval).

## The contract

- **Append-only, newest first.** Entries are never deleted. A lesson that no
  longer applies is marked **(SUPERSEDED — see entry of YYYY-MM-DD)** in
  place, mirroring the ADR supersede rule.
- **One screen per entry.** Date + title, what happened, the rule that
  follows, and links to the PR / issue / session that carry the full story.
  Details live in their canonical homes — this page holds the lesson.
- **Real incidents only.** An entry records something that actually happened
  in this project — never a hypothetical.
- **Escalation path.** A lesson starts here. If it keeps being violated, it
  graduates to a one-line rule in `CLAUDE.md` or a skill card under
  `.claude/skills/`; if it still recurs, it becomes an automated check. Note
  the promotion in the entry when it happens — this keeps `CLAUDE.md` growth
  demand-driven, never default.

---

<!-- BLUEPRINT: entries accumulate below as the project earns them. Entry
skeleton (copy, fill, keep newest first):

## YYYY-MM-DD — <short title of the lesson>

**What happened:** 1–3 sentences, with links (PR #N, issue #N, Session N).

**The rule:** one or two sentences of "therefore, from now on …".

**Promoted:** (optional) where this lesson graduated to, and when.
-->

## 2026-07-31 — A broken tool is not a broken channel

**What happened:** Ticking a deliverable box rewrites the whole issue body
(GitHub has no per-checkbox write), so the write is only as good as the read it
was composed from. Two of the GitHub MCP read tools return bodies lossily — they
strip HTML comments and `<angle-tokens>` and entity-escape quotes and ampersands
— and stripping leaves no trace, so a write composed from one destroys content
invisibly, including to the verify re-read taken through the same tool. One
issue in this repo permanently lost an `<angle-token>` this way.

Four sessions hit this. Each measured the two lossy tools, generalised the result
to "the GitHub channel is lossy in remote sessions", and stopped testing. Two of
them independently re-invented the same partial workaround; two ended in a gate
waiver; none looked at the other tools. A third read tool — `search_issues`,
available in exactly the same sessions — returns the same bodies faithfully, as
do the file and diff reads. The transform was per-tool, never channel-wide.

**The rule:** when a channel looks unusable, **test each tool on it separately
before concluding anything about the channel** — the fault is more often one
code path than the whole transport. And never compose a write from a read whose
fidelity you have not established: no faithful read, no write. `/tick`
(`.claude/commands/tick.md`) now makes the channel choice its first step and
refuses the body edit when no faithful read is available.

**Promoted:** the read-channel table and the refuse-to-write rule live in
`.claude/commands/tick.md`; the doctrine is in
[Closing issues](../process/closing-issues.md).
