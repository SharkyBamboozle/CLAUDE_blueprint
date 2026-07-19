#!/usr/bin/env bash
# Regression cases for .claude/hooks/guard-adr.sh — run after any change to
# the hook (and inside `make verify`, so it binds in CI; D-004). Asserts BOTH
# sides (deny and still-allowed) so a fix can't silently over-tighten. Fully
# hermetic: a throwaway CLAUDE_PROJECT_DIR with fixture ADRs and its own token
# file — no dependence on this repo's real ADR statuses, no touching the real
# .claude/working/UNLOCKED_ADRS.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../.claude/hooks/guard-adr.sh"
fails=0

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/docs/decisions" "$TMP/docs/process" "$TMP/.claude/working"
DECIDED="docs/decisions/adr-0001-fixture.md"
PROPOSED="docs/decisions/adr-0007-fixture.md"
printf '# ADR-0001 — Fixture\n\n- **Status:** ✅ Decided\n' >"$TMP/$DECIDED"
# The Proposed fixture deliberately embeds "✅ Decided" inside a comment and
# prose, to prove the status parse keys on the VALUE, not mere presence of ✅.
printf '# ADR-0007 — Fixture\n\n- **Status:** 🟡 Proposed\n<!-- at bootstrap, flip Status to ✅ Decided -->\nThis page is live while 🟡; promotion to ✅ Decided is the owner call.\n' >"$TMP/$PROPOSED"
printf '# Contributing\n' >"$TMP/docs/process/contributing.md"
printf '# Decisions\n' >"$TMP/docs/decisions/index.md"
TOKENS="$TMP/.claude/working/UNLOCKED_ADRS"

J() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

expect() { # expect <rc> <label> <tool_name> <tool_input_json>
  printf '{"tool_name":%s,"tool_input":%s}' "$(J "$3")" "$4" \
    | CLAUDE_PROJECT_DIR="$TMP" bash "$HOOK" >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -eq "$1" ]; then echo "PASS (rc=$rc): $2"
  else echo "FAIL (rc=$rc, want $1): $2"; fails=$((fails + 1)); fi
}

rm -f "$TOKENS"

# ---- deny side --------------------------------------------------------
expect 2 "edit Decided ADR, no token -> blocked" \
  Edit "{\"file_path\":$(J "$DECIDED")}"
expect 2 "create new ADR stamped ✅ -> blocked" \
  Write "{\"file_path\":$(J docs/decisions/adr-0099-new.md),\"content\":$(J '# ADR-0099
- **Status:** ✅ Decided')}"
expect 2 "off-format ✅ status line (no bullet) -> blocked" \
  Write "{\"file_path\":$(J docs/decisions/adr-0099-new.md),\"content\":$(J '**Status:** ✅ Decided')}"
expect 2 "promote 🟡→✅ via Edit -> blocked" \
  Edit "{\"file_path\":$(J "$PROPOSED"),\"new_string\":$(J '- **Status:** ✅ Decided')}"
expect 2 "promote 🟡→✅ via MultiEdit -> blocked" \
  MultiEdit "{\"file_path\":$(J "$PROPOSED"),\"edits\":[{\"old_string\":$(J '- **Status:** 🟡 Proposed'),\"new_string\":$(J '- **Status:** ✅ Decided')}]}"
expect 2 "Decided ADR via ../ path (normalization) -> blocked" \
  Edit "{\"file_path\":$(J docs/decisions/../decisions/adr-0001-fixture.md)}"
expect 2 "git rm Decided ADR (delete) -> blocked" \
  Bash "{\"command\":$(J "git rm $DECIDED")}"
expect 2 "git mv Decided ADR (rename) -> blocked" \
  Bash "{\"command\":$(J "git mv $DECIDED docs/decisions/adr-0001-renamed.md")}"

# ---- allow side (anti-over-tighten) -----------------------------------
expect 0 "edit Proposed ADR, no token -> allowed" \
  Edit "{\"file_path\":$(J "$PROPOSED")}"
expect 0 "create new ADR stamped 🟡 -> allowed" \
  Write "{\"file_path\":$(J docs/decisions/adr-0099-new.md),\"content\":$(J '# ADR-0099
- **Status:** 🟡 Proposed')}"
expect 0 "edit Proposed ADR body (non-status) -> allowed" \
  Edit "{\"file_path\":$(J "$PROPOSED"),\"new_string\":$(J 'some prose change')}"
expect 0 "git rm Proposed ADR -> allowed" \
  Bash "{\"command\":$(J "git rm $PROPOSED")}"
expect 0 "git rm a non-ADR file -> allowed" \
  Bash "{\"command\":$(J 'git rm README.md')}"
expect 0 "git status (not rm/mv) -> allowed" \
  Bash "{\"command\":$(J 'git status && git diff')}"
expect 0 "registry index.md (not an ADR) -> allowed" \
  Edit "{\"file_path\":$(J docs/decisions/index.md)}"
expect 0 "unrelated docs page -> allowed" \
  Edit "{\"file_path\":$(J docs/process/contributing.md)}"
expect 0 "garbage input -> allowed (fail-open)" \
  Edit "{\"file_path\":$(J 'not even a path')}"

# ---- token unlocks exactly the named ADR ------------------------------
mkdir -p "$TMP/.claude/working"
echo "adr-0001 $(date +%s)" >"$TOKENS"
expect 0 "edit Decided ADR with fresh token -> allowed" \
  Edit "{\"file_path\":$(J "$DECIDED")}"
expect 0 "git rm Decided ADR with fresh token -> allowed" \
  Bash "{\"command\":$(J "git rm $DECIDED")}"
echo "adr-0001 $(( $(date +%s) - 7200 ))" >"$TOKENS"
expect 2 "edit Decided ADR with expired token -> blocked" \
  Edit "{\"file_path\":$(J "$DECIDED")}"

[ "$fails" -eq 0 ] && echo "all asserted cases pass" || echo "$fails case(s) FAILED"
exit "$fails"
