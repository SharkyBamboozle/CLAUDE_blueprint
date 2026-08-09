#!/usr/bin/env bash
# PreToolUse guard for ADR governance (D-004). Registered in
# .claude/settings.json for Edit|Write|MultiEdit AND Bash — one home for all
# ADR-lock logic.
# Exit 0 = allow · exit 2 = block (stderr is fed back to the agent).
#
# Enforces the CLAUDE.md hard rule "never change a ✅ Decided ADR", widened to
# every path TO a Decided state: editing a Decided page, creating one already
# stamped ✅, promoting 🟡→✅, and deleting/renaming a Decided page via
# `git rm`/`git mv`. Any of these needs a fresh /unlock-adr token (≤1h).
# Creating or editing a 🟡/🔴/🧊 page is always allowed — the lock protects
# decisions, not authoring or proposing. CI closes the loop: adr-gates.yml
# requires an 'Unlock-ADR: <id> — <reason>' commit trailer.
#
# Paths are normalized before matching (defeats `../`//`//` bypasses); the
# status parse tolerates format variants. Every block says WHAT TO DO INSTEAD.
# Defaults to ALLOW on parse failure: a broken guard must not brick edits.
set -uo pipefail

INPUT=$(cat 2>/dev/null || true)

python3 - "$INPUT" <<'PY'
import json, os, re, shlex, sys, time

try:
    data = json.loads(sys.argv[1])
    tool = data.get("tool_name", "") or ""
    ti = data.get("tool_input", {}) or {}
except Exception:
    sys.exit(0)  # never brick edits on parse failure

ROOT_ABS = os.path.abspath(os.environ.get("CLAUDE_PROJECT_DIR", "."))

# A Status field whose VALUE is ✅ — tolerant of markup/bullet variants
# (`- **Status:** ✅`, `**Status**: ✅`, `Status: ✅`) but anchored so the ✅
# must follow "Status" with only markup/space/colon between: a legend line
# ("Status legend: ✅ Decided · 🟡 …") has the word "legend" in the gap and
# does NOT match, nor does prose like "flip Status to ✅".
STATUS_DECIDED = re.compile(r"\bStatus\b[*_:\s]*✅", re.IGNORECASE)

def block(rel, short, action):
    print(
        f"BLOCKED (CLAUDE.md hard rule): {rel} is (or would become) a "
        f"✅ Decided ADR, and {action} a Decided decision is gated. A changed "
        "decision is a NEW superseding ADR (docs/process/writing-adrs.md, "
        "/adr-new). For a legitimate governance action "
        "(maintenance edit, create-as-Decided, 🟡→✅ promotion, delete, "
        f"rename), first run:\n\n    /unlock-adr {short or '<adr-id>'}\n\n"
        "(1h token; the commit must then carry an 'Unlock-ADR: "
        f"{short or '<adr-id>'} — <reason>' trailer, checked by adr-gates.yml). "
        "Reading an ADR never needs an unlock.",
        file=sys.stderr,
    )
    sys.exit(2)

def norm_rel(path):
    if not path:
        return ""
    ap = path if os.path.isabs(path) else os.path.join(ROOT_ABS, path)
    ap = os.path.normpath(ap)  # collapses .. and //
    try:
        return os.path.relpath(ap, ROOT_ABS).replace(os.sep, "/")
    except Exception:
        return ""

def is_adr(rel):
    return rel.startswith("docs/decisions/adr-") and rel.endswith(".md")

def adr_short(rel):
    m = re.search(r"adr-\d+", os.path.basename(rel))
    return m.group(0) if m else ""

def on_disk_decided(rel):
    try:
        with open(os.path.join(ROOT_ABS, rel), encoding="utf-8") as f:
            return any(STATUS_DECIDED.search(line) for line in f)
    except Exception:
        return False

def content_decides(text):
    return bool(text) and any(STATUS_DECIDED.search(l) for l in text.splitlines())

def fresh_token(short):
    try:
        now = int(time.time())
        path = os.path.join(ROOT_ABS, ".claude", "working", "UNLOCKED_ADRS")
        with open(path, encoding="utf-8") as f:
            for line in f:
                p = line.split()
                if len(p) >= 2 and p[0] == short and p[1].isdigit() \
                        and now - int(p[1]) < 3600:
                    return True
    except Exception:
        pass
    return False

def enforce(rel, incoming_decided, action):
    if not is_adr(rel):
        return
    # Locked when the target IS a Decided ADR on disk, or the action WOULD make
    # it one (create-as-✅ / 🟡→✅). Authoring/editing a non-Decided page: free.
    if not (on_disk_decided(rel) or incoming_decided):
        return
    short = adr_short(rel)
    if short and fresh_token(short):
        return
    block(rel, short, action)

if tool in ("Edit", "Write", "MultiEdit"):
    fp = ti.get("file_path", "") or ""
    if tool == "Write":
        incoming = ti.get("content", "") or ""
    elif tool == "Edit":
        incoming = ti.get("new_string", "") or ""
    else:  # MultiEdit
        incoming = "\n".join(
            (e.get("new_string", "") or "") for e in (ti.get("edits") or [])
        )
    enforce(norm_rel(fp), content_decides(incoming), "editing")

elif tool == "Bash":
    cmd = ti.get("command", "") or ""
    for seg in re.split(r"&&|\|\||;|\|", cmd):
        try:
            toks = shlex.split(seg)
        except Exception:
            toks = seg.split()
        for i, t in enumerate(toks):
            if t == "git" and i + 1 < len(toks) and toks[i + 1] in ("rm", "mv"):
                action = "deleting" if toks[i + 1] == "rm" else "renaming/moving"
                for a in toks[i + 2:]:
                    if a.startswith("-"):
                        continue
                    rel = norm_rel(a)
                    if is_adr(rel) and on_disk_decided(rel):
                        short = adr_short(rel)
                        if not (short and fresh_token(short)):
                            block(rel, short, action)

sys.exit(0)
PY
exit $?
