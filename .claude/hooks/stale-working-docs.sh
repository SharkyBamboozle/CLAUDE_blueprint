#!/usr/bin/env bash
# Stop hook: a short stderr nudge when .claude/working/ still holds files
# from before today. Purely informational — always exits 0, never blocks.
# Convention: working docs are archived via /handoff at task end
# (.claude/working/README.md).
set -euo pipefail

dir="${CLAUDE_PROJECT_DIR:-.}/.claude/working"
[[ -d "$dir" ]] || exit 0

stale=$(find "$dir" -mindepth 1 -not -name 'README*' \
  -not -newermt 'today 00:00' 2>/dev/null | head -5 || true)

if [[ -n "$stale" ]]; then
  {
    echo "[stale-working-docs] .claude/working/ holds files from before today:"
    echo "$stale"
    echo "Run /handoff <task-slug> to archive finished working docs" \
      "(never archive a still-running task's state files)."
  } >&2
fi
exit 0
