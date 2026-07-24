# Reproduction — issue #21 (F1): bootstrap docs contradict guard-adr.sh

## Hypothesis (context only, NOT load-bearing)

Issue #21 (audited by a prior session against v1.0.2) claims:

1. Three texts — `BOOTSTRAP.md` step 4, `modules/README.md` → *Binary
   policy*, and the ADR-0007 `BLUEPRINT:` comment — state that the 🟡→✅
   finalization of ADR-0007 at bootstrap "needs no ADR unlock" because
   "no ✅ Decided page is touched".
2. That is false: `.claude/hooks/guard-adr.sh` gates every path TO the
   Decided state (editing a Decided page, creating one already ✅,
   promoting 🟡→✅), so the by-the-book bootstrap hits an undocumented
   exit-2 block mid-step-4.
3. Twin instance: `modules/data-repo/adr-data-repository.md` ships
   pre-stamped `✅ Decided`, and `modules/data-repo/MODULE.md` step 5
   creates the seed's ADR from it with no unlock step — the hook's
   create-as-Decided path, a second undocumented block. Also inconsistent
   with `/adr-new`, which defaults new ADRs to 🟡 Proposed.

## Reproduction (load-bearing)

- Commit: `0b25964` (= `origin/development` tip, post-v1.0.3 promotion) ·
  2026-07-24 · hook exercised directly via `bash`, `CLAUDE_PROJECT_DIR=.`
- All five text sites re-verified verbatim at this commit:
  `BOOTSTRAP.md:89-90`, `modules/README.md:47-50`,
  `docs/decisions/adr-0007-binary-hygiene.md:19-20` (BLUEPRINT comment),
  `modules/data-repo/adr-data-repository.md:3`,
  `modules/data-repo/MODULE.md:49-50`.
- No unlock tokens active (`.claude/working/UNLOCKED_ADRS` absent).
- **(a)** Synthetic PreToolUse JSON — `Edit` on
  `docs/decisions/adr-0007-binary-hygiene.md` with `new_string`
  `- **Status:** ✅ Decided` piped into `.claude/hooks/guard-adr.sh` →
  **exit 2**: "BLOCKED (CLAUDE.md hard rule): … first run: /unlock-adr
  adr-0007 … the commit must then carry an 'Unlock-ADR: adr-0007 —
  <reason>' trailer, checked by adr-gates.yml".
- **(b)** `Write` of new `docs/decisions/adr-0099-test.md` whose content
  carries `- **Status:** ✅ Decided` → **exit 2**, same block for
  `adr-0099` (the data-repo payload path).
- **(c)** Control: `Edit` of the same 🟡 page with a non-status
  `new_string` → **exit 0** (authoring a non-Decided page stays free —
  the path this fix's own edits take).

## Diagnosis (grounded ONLY in the reproduction block)

The hook blocks both flows that the bootstrap documents describe as
unlock-free, and its block message itself names the remediation
(`/unlock-adr` + `Unlock-ADR:` trailer) that no bootstrap document
mentions. The docs are wrong; the hook is right. Fix (per #21, approach
approved by the owner): make the three texts instruct the unlock before
the gated edit, and ship the data-repo ADR payload 🟡 Proposed so seeds
promote it through the normal ritual.

## Fix evidence (appended after verification)

- Pending — filled in once the same commands and the full suite have run
  against the fixed tree.
