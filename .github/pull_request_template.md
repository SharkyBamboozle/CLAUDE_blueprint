Closes #___ (epic: #___)

## What / why

<!-- 2–4 lines. Deep reasoning belongs in docs/ (ADR or topic page), not here. -->

## Verification — tick exactly one per block (D-004)

<!-- A checked box is something you actually ran in this session. "Deferred"
     needs a reason AND a follow-up issue — never a silent skip.
     Enforcement of this block is advisory: the forced-choice layout + PR
     review are the enforcers, not a CI parser. A tick's *truth* (did you
     actually run verify?) is un-mechanizable — see D-006 honest reporting;
     a checkbox count would police form, not substance. -->

**`make verify`:**

- [ ] Green — result reported in the session summary
- [ ] Not run — reason: ___

**Behavior exercised end-to-end** (ran the script / hit the endpoint / opened the page):

- [ ] Done — evidence in the session summary
- [ ] N/A — no runtime behavior changed
- [ ] Deferred — reason + follow-up issue: ___

**Docs & records currency** (decision/convention changes: ADR **and** registry row together; changelog entry):

- [ ] Updated — listed in the session summary
- [ ] N/A — nothing decision- or convention-bearing changed
- [ ] Deferred — reason + follow-up issue: ___

## Hard-rule confirmations

- [ ] Target branch is `development` (never `main`)
- [ ] No binaries added (LFS-covered assets excepted; artifacts go to the data repo)
- [ ] Findings surfaced along the way filed as `note` issues, linked to their epic (or none surfaced — say so)
