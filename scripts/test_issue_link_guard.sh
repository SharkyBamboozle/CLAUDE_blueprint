#!/usr/bin/env bash
# Regression cases for scripts/issue_link_decision.sh (the issue-link guard
# logic, #18). Runs inside `make verify`, so it binds in CI (D-004). Hermetic:
# a mocked `gh` on PATH serves canned issue records and closing-reference
# lists — no network. Asserts BOTH sides (block and allow) so a fix can't
# silently over/under-tighten.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/issue_link_decision.sh"
fails=0

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# Mock gh, dispatching on the call shape:
#   api graphql …                     -> $MOCK_LINKED numbers (one per line), rc $MOCK_LINKED_RC
#   api repos/*/issues/N (counters)   -> $MOCK_ISSUE_<N> ("<epic|-> <total> <completed>"),
#                                        rc $MOCK_ISSUE_<N>_RC, stderr $MOCK_ISSUE_<N>_ERR
#   api repos/*/issues/N --jq .body   -> $MOCK_BODY_<N> (raw multi-line body)
cat >"$TMP/gh" <<'MOCK'
#!/usr/bin/env bash
args="$*"
case "$args" in
  *graphql*)
    if [ "${MOCK_LINKED_RC:-0}" -ne 0 ]; then
      printf '%s\n' "${MOCK_LINKED_ERR:-gh: HTTP 500 backend error}" >&2
      exit "${MOCK_LINKED_RC}"
    fi
    for n in ${MOCK_LINKED:-}; do printf '%s\n' "$n"; done
    exit 0 ;;
  *issues/*)
    num=$(printf '%s' "$args" | sed -n 's|.*issues/\([0-9][0-9]*\).*|\1|p')
    if printf '%s' "$args" | grep -q 'sub_issues_summary'; then
      rc_var="MOCK_ISSUE_${num}_RC"; out_var="MOCK_ISSUE_${num}"; err_var="MOCK_ISSUE_${num}_ERR"
      if [ "${!rc_var:-0}" -ne 0 ]; then
        printf '%s\n' "${!err_var:-gh: Not Found (HTTP 404)}" >&2
        exit "${!rc_var}"
      fi
      out="${!out_var:-}"; [ -z "$out" ] && out="- 0 0"
      printf '%s\n' "$out"
    else
      bvar="MOCK_BODY_${num}"
      printf '%s\n' "${!bvar:-}"
    fi
    exit 0 ;;
esac
exit 0
MOCK
chmod +x "$TMP/gh"

# Standing fixtures: #61 an epic mid-flight, #45 an epic fully complete
# (with leftover unchecked body boxes — the epic path judges sub-issues,
# never boxes), #65 an ordinary issue with all boxes ticked, #50 an epic
# with no sub-issues yet, #70 an ordinary issue with unchecked deliverables
# (one indented/nested), #72 an ordinary issue whose body merely QUOTES the
# checkbox syntax mid-line — the #37 false-positive regression shape.
export MOCK_ISSUE_61="epic 16 4"
export MOCK_ISSUE_45="epic 16 16"
export MOCK_ISSUE_65="- 0 0"
export MOCK_ISSUE_50="epic 0 0"
export MOCK_ISSUE_70="- 0 0"
export MOCK_ISSUE_72="- 0 0"
export MOCK_BODY_45="## Exit criteria
- [ ] leftover box the epic path must ignore"
export MOCK_BODY_65="## Deliverables
- [x] code landed
* [x] readout posted"
export MOCK_BODY_70="## Deliverables
- [x] code landed
- [ ] readout pending
  - [ ] nested follow-through"
export MOCK_BODY_72="Switch plain bullets to task-list items (\`- [ ]\`) per the template.
- [x] shipped"

check() { # check <want_rc> <label> — uses the currently-exported case vars
  PATH="$TMP:$PATH" REPO="org/repo" PR_NUMBER=1 \
  PR_BODY="${PR_BODY:-}" PR_TITLE="${PR_TITLE:-}" COMMITS="${COMMITS:-}" \
    bash "$SCRIPT" >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -eq "$1" ]; then echo "PASS (rc=$rc): $2"
  else echo "FAIL (rc=$rc, want $1): $2"; fails=$((fails + 1)); fi
  unset PR_BODY PR_TITLE COMMITS \
    MOCK_LINKED MOCK_LINKED_RC MOCK_LINKED_ERR \
    MOCK_ISSUE_999_RC MOCK_ISSUE_61_RC MOCK_ISSUE_61_ERR
}

export PR_BODY="Closes #61 (partial — the qualifier changes nothing) (epic: #61)"
check 1 "closing keyword on an epic with open sub-issues -> block"

export PR_BODY="Closes — · Part of #61 (epic)"
check 0 "progress idiom (no keyword-adjacent number) -> allow"

export PR_BODY="Closes #65 (epic: #61)"
check 0 "closes a non-epic sub-issue, epic referenced without keyword -> allow"

export PR_BODY="Closes #45 (epic) — closes atomically when this retrospective lands"
check 0 "closeout PR: epic with every sub-issue complete -> allow (body boxes ignored on the epic path)"

export PR_BODY="Closes #70"
check 1 "ordinary issue with unchecked deliverable boxes (incl. nested) -> block (#37)"

export PR_BODY="Closes #72"
check 0 "body only QUOTES checkbox syntax mid-line, boxes ticked -> allow (the #37 false-positive regression)"

export PR_BODY="Closes #70 (deliverables re-homed)"
export COMMITS="fix: final slice

Skip-Issue-Link-Guard: remaining deliverables deferred to a follow-up issue"
check 0 "unchecked deliverables + declared trailer -> allow (argued exception)"

export PR_BODY="closes #50"
check 0 "epic with zero sub-issues -> allow (nothing open to orphan)"

export PR_TITLE="fix #61 for real this time"
check 1 "closing keyword in the PR title (squash-merge surface) -> block"

export COMMITS="feat: partial views

Fixes #61"
check 1 "closing keyword in a commit message -> block"

export PR_BODY="Resolves: org/repo#61"
check 1 "explicit same-repo owner/repo#N form -> block"

export PR_BODY="Fixes https://github.com/org/repo/issues/61"
check 1 "full-URL form -> block"

export PR_BODY="Closes other/repo#61 and https://github.com/other/repo/issues/61"
check 0 "cross-repo closing references -> allow (another repo's policy)"

export PR_BODY="Closes #61 (epic closeout follows atomically)"
export COMMITS="docs: closeout

Skip-Issue-Link-Guard: deliberate atomic closeout, sub-issues close in this train"
check 0 "Skip-Issue-Link-Guard trailer with reason -> allow (declared exception)"

export MOCK_LINKED="61"
check 1 "sidebar-linked epic with a clean body -> block (GraphQL set caught it)"

export MOCK_LINKED_RC=1
check 1 "closing-reference listing fails -> block (fail closed)"

export PR_BODY="Closes #999"
export MOCK_ISSUE_999_RC=1
check 0 "reference to a nonexistent issue (definitive 404) -> allow with note"

export PR_BODY="Closes #61"
export MOCK_ISSUE_61_RC=1 MOCK_ISSUE_61_ERR="gh: HTTP 500 backend error"
check 1 "issue lookup transient error -> block (fail closed)"

export PR_BODY="The unfixed #61 backlog and prefixes #61 must not trip the guard"
check 0 "keyword substring inside a word -> allow (no false positive)"

[ "$fails" -eq 0 ] && echo "all asserted cases pass" || echo "$fails case(s) FAILED"
exit "$fails"
