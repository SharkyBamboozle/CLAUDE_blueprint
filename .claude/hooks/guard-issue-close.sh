#!/usr/bin/env bash
# PreToolUse guard for issue-close authority. Registered in
# .claude/settings.json for Bash AND the GitHub MCP issue-write tools
# (matcher: Bash|mcp__.*issue_write) — one home for all close-gating logic.
# Exit 0 = allow · exit 2 = block (stderr is fed back to the agent).
#
# Enforces the CLAUDE.md hard rule "never manually close or delete an
# issue": a close rides the completing PR's `Closes #N` (fired when the
# OPERATOR merges) or is the operator's own click; the agent's job ends at
# the readout comment + ticked boxes + the close request. There is NO
# unlock ritual here BY DESIGN (contrast guard-adr.sh): any sanctioned
# manual close is one operator click, which costs less than an unlock —
# and a client-side unlock token could not be honored by the server-side
# backstop (issue-close-guard.yml) without trusting agent-postable markers.
#
# Blocked, per tool layer:
#   MCP  — any *issue_write call with state=closed (create or update);
#   Bash — `gh issue close` / `gh issue delete`, and `gh api` calls that
#          set an issue's state to closed or invoke the closeIssue /
#          deleteIssue GraphQL mutations.
# Still allowed (anti-over-tighten): creating issues, commenting, editing
# bodies/labels (box-ticking is expected tracker upkeep), REOPENING
# (state=open — it is the guard's own remedy), and `gh pr close` (PRs are
# not issues and out of this guard's scope).
#
# Named residuals (D-004): raw HTTPS calls bypass the token match — the
# server-side issue-close-guard.yml reverts app-mediated closes that slip
# through; issue DELETION is additionally admin-only at the GitHub layer
# and unexposed in the MCP toolset, so the gh-CLI match here is
# belt-and-suspenders on an already-narrow path.
# Defaults to ALLOW on any parse failure: a broken guard must not brick
# every tool call.
set -uo pipefail

INPUT=$(cat 2>/dev/null || true)

python3 - "$INPUT" <<'PY'
import json, re, shlex, sys

try:
    data = json.loads(sys.argv[1])
    tool = data.get("tool_name", "") or ""
    ti = data.get("tool_input", {}) or {}
except Exception:
    sys.exit(0)  # never brick tool calls on parse failure

MSG = (
    "BLOCKED (CLAUDE.md hard rule): manually closing or deleting an "
    "issue is operator-only. The sanctioned paths: (1) the completing PR "
    "carries `Closes #N` and the close fires when the OPERATOR merges it; "
    "(2) for a readout-close, post the readout comment, tick the delivered "
    "boxes, and ASK THE OPERATOR to close the issue — do not close it "
    "yourself and do not route around this guard via other tools (the "
    "server-side issue-close-guard reverts app-mediated closes). Creating, "
    "commenting, labeling, body edits (box-ticking), and reopening all "
    "remain allowed. See docs/process/contributing.md → Issues, sub-issues "
    "& notes."
)

def block():
    print(MSG, file=sys.stderr)
    sys.exit(2)

if tool != "Bash" and tool.endswith("issue_write"):
    # MCP issue-write tools, any server name (mcp__github__issue_write,
    # forks/renames included). A close is state=closed on create or update;
    # everything else — create, retitle, label, body edit, reopen — passes.
    if (ti.get("state") or "") == "closed":
        block()

elif tool == "Bash":
    cmd = ti.get("command", "") or ""
    # Examine each shell segment separately (handles `a && b`, `a; b`, pipes).
    for seg in re.split(r"&&|\|\||;|\|", cmd):
        try:
            toks = shlex.split(seg)          # strips quotes
        except Exception:
            toks = seg.split()               # fall back on unbalanced quotes
        for i, t in enumerate(toks):
            if t != "gh" or i + 1 >= len(toks):
                continue
            sub = toks[i + 1]
            rest = toks[i + 2:]
            if sub == "issue" and rest and rest[0] in ("close", "delete"):
                block()
            if sub == "api":
                # REST: any /issues/ path plus a state=closed field, in any
                # -f/-F/--field/--raw-field spelling. A comment POST or a
                # title-only PATCH carries no state=closed and passes.
                touches_issues = any("/issues/" in a or a.endswith("/issues")
                                     for a in rest)
                sets_closed = any("state=closed" in a for a in rest)
                if touches_issues and sets_closed:
                    block()
                # GraphQL: the close/delete mutations by name.
                if any("closeIssue" in a or "deleteIssue" in a for a in rest):
                    block()

sys.exit(0)
PY
exit $?
