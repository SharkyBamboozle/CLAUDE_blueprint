# Closing issues

An issue's deliverables are met: the boxes must be ticked, the readout
posted, and the close left to the right party. *Enforcement (D-004): the
`issue-link-guard` gate blocks under-ticked closes (mechanics:
[Opening a PR](opening-a-pr.md)); the `guard-issue-close.sh` hook and the
`issue-close-guard.yml` workflow hold manual closes to the operator; no
gate rejects a missing readout comment — that part is advisory, upheld by
the rituals and review.*

**An issue closes at the moment its deliverables are met — never batched
to session end or epic closeout.** This holds for standalone tasks and
epic sub-issues alike. The completing PR carries `Closes #NN` (plus
`(epic: #MM)` when it has a parent — see
[PR ↔ issue linking](opening-a-pr.md)); an issue no single PR completes
(substrate growing across PRs) is closed manually the moment its boxes are
all ticked, with its **readout as the closing comment**.

## Deliverable boxes & ticking

Deliverables and acceptance criteria are task-list checkboxes — on **any
issue that defines deliverables, however authored**: free-form design
issues included, not only build tasks created from
`docs/.templates/task-issue-body.md`.
GitHub renders the `n/m` progress, and the `issue-link-guard` blocks a
`Closes` aimed at an issue with unchecked boxes **or with no checklist at
all**; writing the checklist
**retroactively is sanctioned** (one ticked box per delivered artifact is
a completion record, not busywork), fenced code samples never count (the
counter strips them), and the declared exception is the
`Skip-Issue-Link-Guard: <reason>` trailer — the argued exception for
deferred or re-homed deliverables, never the cheap path past ticking: the
gate checks merits first and announces any waiver-pass loudly
([Opening a PR](opening-a-pr.md) has the gate's full mechanics).

**Ticking is the completing session's job:** edit the issue body and
tick each box the moment its artifact lands — a box a PR delivers at
PR-open (pre-merge ticking is the designed order: the gate counts boxes
from the moment the PR opens, and the open PR is the evidence), a readout
box right after the readout posts. Editing the owner's issue body to tick
a delivered box is expected tracker upkeep, not an intrusion; delivered
work left unticked is the process failure. The `/tick` ritual
(`.claude/commands/tick.md`) packages the edit **attestation-first**: per
box, *did I deliver this?* answered with named evidence (the PR, commit,
file, or posted readout) — no evidence, no tick — then the anchored flip
of exactly those lines, then a verify re-read; the attestation lines
travel into the PR body so review checks the ticks against them.
*(Checkbox counts are self-reported — the boxes make deliverable state
visible and gateable, not true; honest ticking (D-006) is the substrate,
and the reconciliation sweep is where drift gets caught.)*

## Readouts

**Outcomes get written back to the issue** — run/build results land as a
readout comment on the build issue, cross-linked to the epic; heavy
artifacts live elsewhere (the data repo, if the project has one).

## Who closes

**Manual closes are operator-only.** An agent's completion duty ends
at the readout comment, the ticked boxes, and the close request — the close
itself is the completing PR's `Closes #N` (fired when the operator merges)
or the operator's own click, and this holds even when an operator asks an
agent in chat (at the GitHub layer an agent acts with the operator's own
identity via an app user-to-server token, so the app marker on the close
event is the only enforceable boundary). Enforced at the source by the
`guard-issue-close.sh` hook (suite: `scripts/test_guard_issue_close.sh`)
and server-side by the `issue-close-guard.yml` workflow reverting
app-mediated closes (logic: `scripts/issue_close_decision.sh`; suite:
`scripts/test_issue_close_guard.sh`).

Manual closes fire no PR event — the server-side revert above (it covers
app- **and** bot-mediated closes) and the session-end
[reconciliation sweep](ending-a-session.md) are that path's completeness
net. Two exceptions: **epics** close only via their
[closeout](running-epics.md), and **notes** are triaged, never "done"
([Filing work](filing-work.md)).
