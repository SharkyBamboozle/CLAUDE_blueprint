# ADR-0004 — Enforcement doctrine

- **Status:** ✅ Decided
- **Decision ID:** D-004
- **Related requirements:** —
- **Related questions:** —
- **Related decisions:** D-001 (documentation & records — the registry and
  docs this doctrine keeps true); applied by D-005 (testing policy) and
  D-006 (verification & honesty)

## Context

**Rules that exist only as prose drift.** Everywhere a rule is backed by a
gate, test, or ledger it holds; everywhere it relies on prose alone, it
decays silently under time pressure — and an AI-assisted project applies
that pressure at machine speed. The complementary failure sits at the
gates' escape hatches: every gate eventually grows an exception list, and
ungoverned lists grow until "excepted" is the norm and the gate checks
nothing. One doctrine must govern both: how rules bind, and how exceptions
stay honest.

## Decision

**Every process rule names what enforces it — or is explicitly advisory;
enforcement is layered; exceptions are reasoned and ledgered.**

- **Rules declare their enforcement.** A rule added to `CLAUDE.md` or the
  process docs states the hook, CI gate, test, or template section that
  catches violations — or carries the honest label *"advisory —
  deliberately unenforced because ⟨reason⟩"*. The reference is
  bidirectional: the enforcing artifact cites the rule or decision it
  enforces in a comment, so config files explain themselves.
- **Enforcement is layered**, from cheap to binding: prose states the rule
  and points at its enforcer → **local hooks** nudge or deny at edit time,
  every block message naming the recovery path → **CI gates** are the
  binding layer that survives every client configuration. Hooks are code:
  every deny-hook ships a regression suite asserting both the deny side
  *and* the still-allowed side. A meta-gate pins the gate wiring itself,
  so a gate cannot be silently unwired.
- **Sanctioned exceptions are commit trailers** with a mandatory reason —
  the generic `Skip-<Rule>: <one-line reason>` form, or a rule-specific
  named trailer (e.g. `Test-Adjusted:`, D-005) — permanent, searchable,
  machine-checkable. Never chat-only approvals, and never PR labels — with
  one deliberate exception, the `allow-binaries` label (D-007), whose
  trailer-ization is deferred below.
- **PR verification blocks are forced-choice** — each block offers its
  applicable options (verified-with-evidence / N-A-with-reason /
  deferred-with-reason-and-follow-up) and exactly one is ticked — so
  "didn't check" can never hide inside "didn't tick".
- **No silent lanes.** An allowed-to-fail CI job ends with an explicit
  failure beacon; a file-targeted gate fails loud when its target file is
  missing (a moved file may never turn a gate green); and a dormant gate
  lane owns its activation condition — it detects when it becomes needed
  and fails until configured or explicitly declared off with a reason.
- **Exception lists are ledgers**, governed by four rules: **a reason per
  entry**, inline; **a ceiling** on size, so growth is a visible diff;
  **staleness fails loud** — an entry no longer needed fails the gate until
  removed; **itemized, never blanket** — entries name specific items, never
  a directory or category. One boundary: honesty- and security-critical
  findings (a real secret, a fabricated claim) are **never ledgerable**.

Current enforcers of this doctrine: the git and ADR guard hooks with their
regression suites, the ADR gates and branch-flow guard workflows, the
repo-hygiene and security gates, the CI meta-gate, and the docs-truth
checker — all bound into `make verify` and the PR gates.

## Consequences

- Unenforced rules become *visible*: several conventions honestly carry an
  advisory label until someone builds their gate — that visibility is the
  point, not a defect.
- Writing a new rule costs one extra sentence; reviewing one gains a
  standard question: "who catches violations of this?"
- Excepting something costs one honest sentence in a trailer or ledger
  entry — deliberately: an exception is a decision.
- Gates stay trustworthy as they age; "how many exceptions do we carry?" is
  always answerable and trendable.

## Alternatives considered

- **Enforce everything mechanically** — rejected: heavyweight, and
  over-strict local blocks train agents and humans to improvise
  workarounds; the layered model keeps strictness at the binding (CI)
  layer.
- **Prose + good intentions** — rejected: exactly what produces the drift
  described in Context.
- **Judgment-call exceptions per review** — rejected: leaves no durable
  record, and reviewer memory does not scale across sessions, contributors,
  and agents.
- **No exceptions allowed** — rejected: gates without escape hatches get
  disabled wholesale under pressure, which is worse than governed
  exceptions.

## Reversibility / notes

- Cheap to undo: stop requiring the declaration; the existing gates keep
  working standalone. Ledgered lists degrade gracefully into plain lists.
- 🧊 **Deferred, with reactivation triggers:**
    - **Consecutive-failure escalation for scheduled lanes** (auto-filed
      tracking issue after N failed scheduled runs, auto-closed on
      recovery) — reactivate when a scheduled lane's failure goes
      unnoticed, or when the first nightly workflow lands.
    - **Trailer-izing the `allow-binaries` label** (the repo-hygiene escape
      hatch is label-based rather than trailer-based) — reactivate the
      next time the repo-hygiene gate changes materially.

## References

- Related docs: [Contributing → Enforcement layering](../process/contributing.md#enforcement-layering-d-004),
  [Contributing → Exception lists are ledgers](../process/contributing.md#exception-lists-are-ledgers-d-004),
  [Contributing → Commit conventions](../process/contributing.md#commit-conventions)
- Related decisions: [ADR-0001](adr-0001-documentation-and-records.md),
  [ADR-0005](adr-0005-testing-policy.md),
  [ADR-0006](adr-0006-verification-and-honesty.md)
