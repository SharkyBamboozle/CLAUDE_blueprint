---
description: Tick delivered deliverable box(es) on an issue — attest each with evidence, then the anchored body edit
argument-hint: <issue #NN> [box-text fragment]
---

Tick deliverable box(es) on: $ARGUMENTS — an issue number, optionally followed
by a box-text fragment naming which box(es). With no fragment, attest every box
this session delivered; with no issue named, the one this session is completing.

A tick is an **attestation, never a routine step.** The boxes exist so no close
is faith-based (#41); a tick is the session's on-record claim that a deliverable
is DONE (D-006). Running `/tick` over every box as PR boilerplate defeats the
boxes exactly as much as a routine `Skip-Issue-Link-Guard` trailer would (#47) —
so the per-box question below is mandatory, and *no attestable box* is a valid
answer (step 5).

Steps, in order:

1. **Fresh read.** Fetch the issue body NOW (this session's GitHub tools or
   `gh api`); never edit from a body read earlier in the session — bodies change
   under you. List every task-list line with its current state (ticked `[x]` /
   unticked `[ ]`).
2. **Attest, box by box.** For each box you claim, write one line: the box text,
   then `evidence:` naming the PR / commit / file / posted readout **this
   session produced**. The rules are hard:
   - Concrete, checkable evidence or **no tick** — an unchecked box plus an
     honest sentence beats an optimistic tick (D-006).
   - Partially delivered stays unticked — state on the issue what remains, or
     re-home it and say where.
   - A box this session did not work stays untouched, **always**.
   - Box text no longer matching what was actually built → do NOT
     reword-and-tick; **STOP** and surface it (scope moved — the owner decides).
3. **Anchored edit.** Flip ONLY the attested lines from `- [ ]` to `- [x]`,
   byte-identical otherwise, composed from the fresh read — never retyped from
   memory. An attested line matching more than one body line → **STOP** and
   disambiguate first.
4. **Write, then verify.** Update the body, re-read it, and confirm: each
   attested line ticked, the unchecked count dropped by **exactly** the attested
   number, nothing else changed. Any other difference is a concurrent edit —
   redo from step 1; never overwrite it.
5. **Record.** Carry the attestation lines into the PR body (or session summary)
   next to the `n/m` tally. The gate polices *form* (boxes ticked); the
   attestation is the *substance* review checks the ticks against.

Timing (#47): a box a PR delivers is ticked **at PR-open** — the open PR is the
evidence; a readout box, right after the readout posts. If no box is
attestable, **say so and stop with no body edit**: honest unticked boxes are a
valid outcome of this ritual.
