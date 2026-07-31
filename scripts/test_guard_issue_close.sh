#!/usr/bin/env bash
# Regression cases for .claude/hooks/guard-issue-close.sh — run after any
# change to the hook (and inside `make verify`, so it binds in CI; D-004).
# Asserts BOTH sides (deny and still-allowed) so a fix can't silently
# over-tighten. Fully hermetic: the hook reads only its stdin — no repo
# state, no network, no fixtures.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../.claude/hooks/guard-issue-close.sh"
fails=0

J() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

expect() { # expect <rc> <label> <tool_name> <tool_input_json>
  printf '{"tool_name":%s,"tool_input":%s}' "$(J "$3")" "$4" \
    | bash "$HOOK" >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -eq "$1" ]; then echo "PASS (rc=$rc): $2"
  else echo "FAIL (rc=$rc, want $1): $2"; fails=$((fails + 1)); fi
}

# ---- deny side: MCP layer ---------------------------------------------
expect 2 "MCP issue_write update state=closed -> blocked" \
  mcp__github__issue_write '{"method":"update","owner":"o","repo":"r","issue_number":5,"state":"closed"}'
expect 2 "MCP issue_write close with state_reason -> blocked" \
  mcp__github__issue_write '{"method":"update","owner":"o","repo":"r","issue_number":5,"state":"closed","state_reason":"completed"}'
expect 2 "MCP issue_write create born-closed -> blocked" \
  mcp__github__issue_write '{"method":"create","owner":"o","repo":"r","title":"t","state":"closed"}'
expect 2 "issue_write on a differently-named MCP server -> blocked" \
  mcp__github-enterprise__issue_write '{"method":"update","issue_number":5,"state":"closed"}'

# ---- deny side: Bash layer --------------------------------------------
expect 2 "gh issue close -> blocked" \
  Bash "{\"command\":$(J 'gh issue close 12')}"
expect 2 "gh issue close with flags/comment -> blocked" \
  Bash "{\"command\":$(J 'gh issue close 12 --comment "readout done" -R o/r')}"
expect 2 "gh issue delete -> blocked" \
  Bash "{\"command\":$(J 'gh issue delete 12 --yes')}"
expect 2 "chained command hiding the close -> blocked" \
  Bash "{\"command\":$(J 'git status && gh issue close 5')}"
expect 2 "gh api PATCH state=closed on an issue -> blocked" \
  Bash "{\"command\":$(J 'gh api -X PATCH repos/o/r/issues/12 -f state=closed')}"
expect 2 "gh api graphql closeIssue mutation -> blocked" \
  Bash "{\"command\":$(J 'gh api graphql -f query="mutation { closeIssue(input:{issueId:\"I_x\"}) { issue { number } } }"')}"
expect 2 "gh api graphql deleteIssue mutation -> blocked" \
  Bash "{\"command\":$(J 'gh api graphql -f query="mutation { deleteIssue(input:{issueId:\"I_x\"}) { repository { name } } }"')}"

# ---- allow side (anti-over-tighten) -----------------------------------
expect 0 "MCP issue_write create (no state) -> allowed" \
  mcp__github__issue_write '{"method":"create","owner":"o","repo":"r","title":"t","body":"b"}'
expect 0 "MCP issue_write reopen (state=open) -> allowed" \
  mcp__github__issue_write '{"method":"update","issue_number":5,"state":"open"}'
expect 0 "MCP issue_write body edit / box tick -> allowed" \
  mcp__github__issue_write '{"method":"update","issue_number":5,"body":"- [x] ticked"}'
expect 0 "MCP sub_issue_write (no state field) -> allowed" \
  mcp__github__sub_issue_write '{"method":"add","issue_number":5,"sub_issue_id":9}'
expect 0 "unrelated MCP tool -> allowed" \
  mcp__github__add_issue_comment '{"issue_number":5,"body":"readout"}'
expect 0 "gh issue view/list/comment -> allowed" \
  Bash "{\"command\":$(J 'gh issue view 12 && gh issue list && gh issue comment 12 --body readout')}"
expect 0 "gh issue edit (labels/body, no close) -> allowed" \
  Bash "{\"command\":$(J 'gh issue edit 12 --add-label note')}"
expect 0 "gh api comment POST (issues path, no state) -> allowed" \
  Bash "{\"command\":$(J 'gh api repos/o/r/issues/12/comments -f body="readout"')}"
expect 0 "gh api title-only PATCH -> allowed" \
  Bash "{\"command\":$(J 'gh api -X PATCH repos/o/r/issues/12 -f title="new"')}"
expect 0 "gh api reopen (state=open) -> allowed" \
  Bash "{\"command\":$(J 'gh api -X PATCH repos/o/r/issues/12 -f state=open')}"
expect 0 "gh pr close (a PR, not an issue) -> allowed" \
  Bash "{\"command\":$(J 'gh pr close 7 --comment "superseded"')}"
expect 0 "plain git work -> allowed" \
  Bash "{\"command\":$(J 'git add -u && git commit -m x && git push -u origin b')}"
expect 0 "Edit tool (not this guard's concern) -> allowed" \
  Edit '{"file_path":"docs/x.md","new_string":"state=closed prose"}'

# ---- fail-open --------------------------------------------------------
printf 'not json at all' | bash "$HOOK" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then echo "PASS (rc=$rc): garbage stdin -> allowed (fail-open)"
else echo "FAIL (rc=$rc, want 0): garbage stdin -> allowed (fail-open)"; fails=$((fails + 1)); fi

[ "$fails" -eq 0 ] && echo "all asserted cases pass" || echo "$fails case(s) FAILED"
exit "$fails"
