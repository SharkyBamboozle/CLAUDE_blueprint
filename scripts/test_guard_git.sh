#!/usr/bin/env bash
# Regression cases for .claude/hooks/guard-git.sh — run after any change to
# the hook (and inside `make verify`, so it binds in CI; D-004). Asserts BOTH
# sides (forbidden blocks, allowed still succeeds) so a fix can't silently
# over-tighten. State-dependent verdicts (push-to-main birth-vs-armed, bulk-add
# worktree scan) are made HERMETIC by exercising the hook inside throwaway git
# repos built here, with gh mocked through the hook's GUARD_GH_BIN seam — no
# network, no dependence on this repo's mutable state.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../.claude/hooks/guard-git.sh"
fails=0

emit() { # emit <command> -> PreToolUse JSON on stdout
  printf '{"tool_name":"Bash","tool_input":{"command":%s}}' \
    "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1")"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Hermetic gh for the zombie-push check: the hook's `gh pr list` gets
# $MOCK_PRS (JSON array; default: no PR history) at rc $MOCK_GH_RC — so the
# suite never touches the network even on machines with a real gh. The mock
# is delivered through the hook's explicit GUARD_GH_BIN seam (exported in
# expect below as a `bash <script>` argv), NOT via PATH: a Windows-native
# Python resolves the hook's spawn through CreateProcess, which cannot
# execute an extensionless shebang script and silently falls through to the
# real gh — PATH-only delivery would test the live API there while staying
# green on Linux.
mkdir -p "$TMP/mock"
cat >"$TMP/mock/gh" <<'MOCK'
#!/usr/bin/env bash
[ "${MOCK_GH_RC:-0}" -ne 0 ] && exit "${MOCK_GH_RC}"
printf '%s\n' "${MOCK_PRS:-[]}"
MOCK
chmod +x "$TMP/mock/gh"

# PATH still gets a gh, but it is a static DECOY that always answers "no
# PRs" — never the mock above. The decoy keeps the seam revert-sensitive
# where CI runs: if the hook's spawn ever regresses to bare ["gh", ...],
# PATH resolution finds the decoy on Linux too, the terminal-PR zombie
# cases see [] instead of their fixtures, fail open to "allowed", and go
# red. (A marker-file canary could not pin this — with the seam reverted, a
# PATH-delivered mock still answers on Linux; only divergent answers make
# the regression visible where CI runs.)
mkdir -p "$TMP/bin"
cat >"$TMP/bin/gh" <<'DECOY'
#!/usr/bin/env bash
printf '[]\n'
DECOY
chmod +x "$TMP/bin/gh"

expect() { # expect <rc> <label> <command> [cwd]
  local want="$1" label="$2" cmd="$3" dir="${4:-$HERE/..}"
  ( cd "$dir" && emit "$cmd" | env -u CLAUDE_PROJECT_DIR \
      PATH="$TMP/bin:$PATH" GUARD_GH_BIN="bash $TMP/mock/gh" \
      MOCK_PRS="${MOCK_PRS:-[]}" MOCK_GH_RC="${MOCK_GH_RC:-0}" \
      bash "$HOOK" >/dev/null 2>&1 )
  local rc=$?
  if [ "$rc" -eq "$want" ]; then echo "PASS (rc=$rc): $label"
  else echo "FAIL (rc=$rc, want $want): $label"; fails=$((fails + 1)); fi
}

# ---- state-independent cases (run against this repo) --------------------
expect 2 "force push -> blocked"                 "git push --force origin feature-x"
expect 2 "force-with-lease -> blocked"           "git push --force-with-lease origin feature-x"
expect 2 "gh pr merge -> blocked"                "gh pr merge 7 --squash"
expect 2 "gh api pulls/N/merge -> blocked"       "gh api repos/o/r/pulls/7/merge --method PUT"
expect 0 "gh api pulls/N (not merge) -> allowed" "gh api repos/o/r/pulls/7"
expect 2 "remote branch delete (--delete) -> blocked" "git push --delete origin somebranch"
expect 2 "remote branch delete (:dst) -> blocked"     "git push origin :somebranch"
expect 0 "feature push -> allowed"               "git push -u origin feature/x"
expect 0 "'main' inside a branch name -> allowed" "git push -u origin claude/fix-main-page"
expect 2 "binary add -> blocked"                 "git add plot.png"
expect 2 "quoted binary add -> blocked"          'git add "plot.png"'
expect 0 "quoted text add -> allowed"            'git add "docs/index.md"'
expect 0 "text add -> allowed"                   "git add docs/index.md"
expect 0 "read-only chain -> allowed"            "git status && git diff"
expect 0 "garbage input -> allowed (fail-open)"  "echo not even json"

# ---- hermetic push-to-main + bulk-add cases (throwaway repos) -----------
mk() { git init -q "$1"; git -C "$1" config user.email t@t.t; git -C "$1" config user.name t; }

# armed: origin/main exists with >1 commit (not the template birth state)
git init -q --bare "$TMP/origin-armed.git"
mk "$TMP/armed"; git -C "$TMP/armed" checkout -q -b main
echo 1 >"$TMP/armed/f"; git -C "$TMP/armed" add f; git -C "$TMP/armed" commit -qm 1
echo 2 >"$TMP/armed/f"; git -C "$TMP/armed" commit -qam 2
git -C "$TMP/armed" remote add origin "$TMP/origin-armed.git"
git -C "$TMP/armed" push -q origin main; git -C "$TMP/armed" fetch -q origin
expect 2 "armed: bare push on main -> blocked"        "git push"                       "$TMP/armed"
expect 2 "armed: push origin (implicit) on main -> blocked" "git push origin"          "$TMP/armed"
expect 2 "armed: push origin HEAD on main -> blocked" "git push origin HEAD"           "$TMP/armed"
expect 2 "armed: HEAD:main -> blocked"                "git push origin HEAD:main"      "$TMP/armed"
expect 2 "armed: refs/heads/main full-ref -> blocked" "git push origin refs/heads/main" "$TMP/armed"
expect 2 "armed: feature:main -> blocked"             "git push origin feature:main"   "$TMP/armed"
expect 0 "armed: explicit non-main from main -> allowed" "git push origin featbranch"  "$TMP/armed"
git -C "$TMP/armed" checkout -q -b feat
expect 0 "armed: bare push on feature -> allowed"     "git push"                       "$TMP/armed"

# birth: remote genuinely has no main (ls-remote --exit-code returns 2)
git init -q --bare "$TMP/origin-empty.git"
mk "$TMP/birth"; git -C "$TMP/birth" checkout -q -b main
echo x >"$TMP/birth/BOOTSTRAP.md"; git -C "$TMP/birth" add -A; git -C "$TMP/birth" commit -qm birth
git -C "$TMP/birth" remote add origin "$TMP/origin-empty.git"
expect 0 "birth: push to main allowed (un-bootstrapped)" "git push origin main"        "$TMP/birth"

# inconclusive origin: remote URL does not exist -> must FAIL CLOSED (armed)
mk "$TMP/broken"; git -C "$TMP/broken" checkout -q -b main
echo x >"$TMP/broken/f"; git -C "$TMP/broken" add -A; git -C "$TMP/broken" commit -qm c
git -C "$TMP/broken" remote add origin "$TMP/nope.git"
expect 2 "inconclusive origin: push to main -> blocked (fail closed)" "git push origin main" "$TMP/broken"

# bulk add scans the worktree for un-LFS'd binaries
printf '\x89PNG' >"$TMP/armed/pic.png"
expect 2 "bulk add -A with untracked binary -> blocked" "git add -A" "$TMP/armed"
expect 2 "bulk add . with untracked binary -> blocked"  "git add ."  "$TMP/armed"
rm -f "$TMP/armed/pic.png"
expect 0 "bulk add -A, no binaries -> allowed"          "git add -A" "$TMP/armed"

# ---- zombie-push cases: terminal-PR branches, mocked gh -----------------
# Fixture: feat branched from development@c1; development then moved to c3
# (the "merge landed"), so feat's line no longer contains the integration
# tip — the zombie shape. Restarting feat onto origin/development is the
# sanctioned recovery and must stay allowed.
git init -q --bare "$TMP/origin-z.git"
mk "$TMP/z"; git -C "$TMP/z" checkout -q -b development
echo 1 >"$TMP/z/f"; git -C "$TMP/z" add f; git -C "$TMP/z" commit -qm c1
git -C "$TMP/z" remote add origin "$TMP/origin-z.git"
git -C "$TMP/z" push -q origin development
git -C "$TMP/z" checkout -q -b feat
echo 2 >"$TMP/z/f"; git -C "$TMP/z" commit -qam c2
git -C "$TMP/z" checkout -q development
echo 3 >"$TMP/z/f"; git -C "$TMP/z" commit -qam c3
git -C "$TMP/z" push -q origin development
git -C "$TMP/z" checkout -q feat

MOCK_PRS='[{"number":9,"state":"MERGED"}]'
expect 2 "zombie: latest PR merged, branch on pre-merge line -> blocked" "git push -u origin feat" "$TMP/z"
MOCK_PRS='[{"number":9,"state":"CLOSED"}]'
expect 2 "zombie: latest PR closed-unmerged -> blocked (operator decision)" "git push" "$TMP/z"
MOCK_PRS='[{"number":9,"state":"MERGED"},{"number":12,"state":"OPEN"}]'
expect 0 "open PR alongside an older merged one -> allowed (normal appending)" "git push" "$TMP/z"
MOCK_PRS='[]'
expect 0 "no PR history -> allowed (first push)" "git push -u origin feat" "$TMP/z"
MOCK_PRS='[{"number":9,"state":"MERGED"}]' MOCK_GH_RC=1
expect 0 "gh unavailable/errors -> allowed (fail OPEN by design)" "git push" "$TMP/z"
MOCK_GH_RC=0
git -C "$TMP/z" checkout -q -B feat origin/development
MOCK_PRS='[{"number":9,"state":"MERGED"}]'
expect 0 "restarted branch on current integration line -> allowed (fresh PR next)" "git push -u origin feat" "$TMP/z"
MOCK_PRS='[]'

[ "$fails" -eq 0 ] && echo "all asserted cases pass" || echo "$fails case(s) FAILED"
exit "$fails"
