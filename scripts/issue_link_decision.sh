#!/usr/bin/env bash
# Decision logic for the issue-link guard (.github/workflows/issue-link-guard.yml).
# A GitHub closing keyword (close/closes/closed/fix/fixes/fixed/resolve/
# resolves/resolved) auto-closes its target when the PR merges into the
# default branch — and GitHub ignores qualifiers: "Closes #7 (partial)" still
# closes #7. The rule (#18, #37; docs/process/contributing.md → PR ↔ issue
# linking): a closing keyword may only target an issue the PR fully
# completes. This script blocks any closing reference — in the PR body, PR
# title, a commit message, or GitHub's own resolved link set (which
# includes sidebar-linked issues) — whose target is not completion-ready:
#   epic-labeled issue  -> blocked while it has open sub-issues (only its
#                          closeout PR, every sub-issue closed, passes);
#   note-labeled issue  -> exempt (#41): a note never reaches "done" — its
#                          completion semantics are the triage verbs;
#   any other issue     -> blocked while its body carries unchecked
#                          task-list deliverable boxes (- [ ] / * [ ]) —
#                          tick what is done, re-home what is deferred, or
#                          declare the exception (#37) — AND blocked when it
#                          carries no checklist at all (#41): a box-less
#                          close is a faith-based close; state the
#                          deliverables (retroactively is sanctioned: one
#                          ticked box per delivered artifact) or declare
#                          the exception. Fenced code blocks are stripped
#                          before counting — samples never count.
#
# Extracted into a script so the decision is unit-testable with a mocked `gh`
# (scripts/test_issue_link_guard.sh) — the workflow just supplies the inputs.
#
# Exit 0 = allow · exit 1 = block.
# Env: REPO (owner/name), PR_NUMBER, PR_TITLE, PR_BODY, COMMITS (concatenated
#      commit messages over the PR range), GH_TOKEN (for `gh api`).
#
# Inconclusive `gh` outcomes fail CLOSED (house rule — same as the
# branch-flow guard: a transient error must not silently drop the policy).
# The one exception: a definitive 404 on a referenced issue number, which
# nothing can close, is allowed through with a note.
# Override: a `Skip-Issue-Link-Guard: <reason>` commit trailer (D-004 —
# exceptions are declared trailers, never silent).
set -uo pipefail

REPO="${REPO:-}"
PR_NUMBER="${PR_NUMBER:-}"
PR_TITLE="${PR_TITLE:-}"
PR_BODY="${PR_BODY:-}"
COMMITS="${COMMITS:-}"

if printf '%s\n' "$COMMITS" | grep -qE '^Skip-Issue-Link-Guard:[[:space:]]*[^[:space:]]'; then
  echo "Skip-Issue-Link-Guard trailer present — OK."
  exit 0
fi

# The nine closing keywords. (^|[^[:alnum:]_]) instead of \b so the pattern
# is portable ERE ("unfixed #7" must not match).
KW='(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved)'
TEXT="$PR_BODY
$PR_TITLE
$COMMITS"
# Only '.' in an owner/name is regex-special (allowed chars: [A-Za-z0-9_.-]).
REPO_RE=$(printf '%s' "$REPO" | sed 's/\./\\./g')

# Closing references in the supplied text: same-repo shorthand (#N), the
# explicit owner/repo#N form, and the full-URL form — each only when it
# targets THIS repo (cross-repo closes are another repo's policy).
refs=$(
  {
    printf '%s' "$TEXT" | grep -oiE "(^|[^[:alnum:]_])${KW}:?[[:space:]]*#[0-9]+" | sed 's/.*#//'
    printf '%s' "$TEXT" | grep -oiE "(^|[^[:alnum:]_])${KW}:?[[:space:]]*${REPO_RE}#[0-9]+" | sed 's/.*#//'
    printf '%s' "$TEXT" | grep -oiE "(^|[^[:alnum:]_])${KW}:?[[:space:]]*https://github\.com/${REPO_RE}/issues/[0-9]+" | sed 's|.*/||'
  } | sort -un
)

# GitHub's own resolved link set for this PR: body keywords as GitHub parsed
# them, plus manually-linked (Development sidebar) issues as of this run.
linked=$(gh api graphql \
  -f query='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){closingIssuesReferences(first:100){nodes{number}}}}}' \
  -f o="${REPO%%/*}" -f r="${REPO#*/}" -F n="${PR_NUMBER:-0}" \
  --jq '.data.repository.pullRequest.closingIssuesReferences.nodes[].number' 2>&1)
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "::error::issue-link-guard could not list this PR's closing references — 'gh api graphql' failed (transient / auth / network). Failing CLOSED to avoid a silent policy bypass. Details: $linked"
  exit 1
fi

candidates=$(printf '%s\n%s\n' "$refs" "$linked" | grep -E '^[0-9]+$' | sort -un)
if [ -z "$candidates" ]; then
  echo "OK: no closing references to this repo's issues."
  exit 0
fi

blocked=0
for num in $candidates; do
  # One line per issue: "<epic|note|-> <total> <completed>" (label class +
  # sub-issue counters; epic wins over note if ever both).
  info=$(gh api "repos/$REPO/issues/$num" \
    --jq '([.labels[].name] | if index("epic") then "epic" elif index("note") then "note" else "-" end) + " " + ((.sub_issues_summary.total // 0) | tostring) + " " + ((.sub_issues_summary.completed // 0) | tostring)' 2>&1)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    if printf '%s' "$info" | grep -qiE 'HTTP 404|not found'; then
      echo "note: closing reference to #$num, which does not exist — nothing to close, not blocking."
      continue
    fi
    echo "::error::issue-link-guard could not read issue #$num — 'gh api' failed (transient / auth / network). Failing CLOSED to avoid a silent policy bypass. Details: $info"
    exit 1
  fi
  read -r flag total completed <<<"$info"
  if [ "$flag" = "epic" ] && [ "${completed:-0}" -lt "${total:-0}" ]; then
    echo "::error::This PR would close epic #$num, which has open sub-issues ($completed/$total complete). A closing keyword targets only an issue the PR fully completes; an epic closes only via its closeout PR. Reference progress as 'Closes — · Part of #$num (epic)' — or declare a deliberate exception with a 'Skip-Issue-Link-Guard: <reason>' commit trailer. See docs/process/contributing.md → PR ↔ issue linking (#18)."
    blocked=1
    continue
  fi
  if [ "$flag" = "epic" ]; then
    echo "OK: closing reference to epic #$num — all $total sub-issues complete (closeout)."
    continue
  fi
  if [ "$flag" = "note" ]; then
    echo "OK: closing reference to note #$num — notes are checklist-exempt (#41); triage verbs are their completion semantics."
    continue
  fi
  # Non-epic, non-note: count deliverable boxes LINE-ANCHORED, in the
  # script (not jq), so the counting seam is covered by the mocked suite.
  # GitHub renders a task item only at a list-item line start — prose
  # QUOTING the syntax ("… task-list items (\`- [ ]\`) …") must not count;
  # the gate's first live run false-positived on exactly that (#37's own
  # spec body). Fenced code blocks are stripped first (#41) — a fenced
  # SAMPLE of checkbox syntax is not a checkbox (the promotion PR restating
  # 'Closes #18' would otherwise trip on #18's fenced template snippet).
  body=$(gh api "repos/$REPO/issues/$num" --jq '.body // ""' 2>&1)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "::error::issue-link-guard could not read issue #$num's body — 'gh api' failed (transient / auth / network). Failing CLOSED to avoid a silent policy bypass. Details: $body"
    exit 1
  fi
  stripped=$(printf '%s\n' "$body" | awk '/^[[:space:]]*```/{f=!f; next} !f')
  unchecked=$(printf '%s\n' "$stripped" | grep -cE '^[[:space:]]*[-*][[:space:]]+\[ \]')
  checked=$(printf '%s\n' "$stripped" | grep -cE '^[[:space:]]*[-*][[:space:]]+\[[xX]\]')
  if [ "$unchecked" -gt 0 ]; then
    echo "::error::This PR would close #$num, which still has $unchecked unchecked deliverable box(es). Close only what is complete: tick the boxes that are done, re-home what is deferred (and say where), or declare the exception with a 'Skip-Issue-Link-Guard: <reason>' commit trailer. See docs/process/contributing.md → Issues, sub-issues & notes (#37)."
    blocked=1
  elif [ "$checked" -eq 0 ]; then
    echo "::error::This PR would close #$num, which carries no deliverable checklist — a box-less close is a faith-based close (#41). State the issue's deliverables as task-list boxes (retroactively is sanctioned: one ticked box per delivered artifact is a completion record, not busywork), or declare the exception with a 'Skip-Issue-Link-Guard: <reason, e.g. trivial one-line fix>' commit trailer. See docs/process/contributing.md → Issues, sub-issues & notes."
    blocked=1
  else
    echo "OK: closing reference to #$num — deliverables $checked/$checked ticked."
  fi
done

exit "$blocked"
