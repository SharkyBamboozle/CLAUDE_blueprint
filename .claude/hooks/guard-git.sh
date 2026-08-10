#!/usr/bin/env bash
# PreToolUse guard for Bash commands (registered in .claude/settings.json).
# Exit 0 = allow · exit 2 = block (stderr is fed back to the agent).
#
# Guards CLAUDE.md's hard rules at the Bash layer — push to main, force-push,
# remote branch deletion, staging un-LFS'd binaries, self-merging PRs, and
# zombie pushes to a branch whose PR is already merged/closed. It
# normalizes each command to its INTENT before matching (refspec forms,
# quoting, bulk adds) rather than pattern-matching one literal form, and
# FAILS CLOSED when repo state is inconclusive (D-004) — except the
# zombie-push check, which fails OPEN by design: blocking every push on a
# gh/network error would brick normal work, and a wrongly-allowed zombie
# push wastes effort but destroys nothing. The thorough net is
# repo-hygiene CI + branch protection: enforcement is layered by design.
#
# Every block message says WHAT TO DO INSTEAD — a blocked agent with no
# alternative starts improvising workarounds.
#
# Defaults to ALLOW on any parse failure: a broken guard must not brick
# every Bash call.
set -uo pipefail

INPUT=$(cat 2>/dev/null || true)

python3 - "$INPUT" <<'PY'
import json, os, re, shlex, subprocess, sys

try:
    data = json.loads(sys.argv[1])
    cmd = data.get("tool_input", {}).get("command", "") or ""
except Exception:
    sys.exit(0)  # never brick Bash on parse failure

def block(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

BINARY_EXT = (
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".mp4", ".mov", ".avi",
    ".pdf", ".zip", ".tar", ".gz", ".7z",
    ".pt", ".pth", ".ckpt", ".onnx", ".safetensors", ".npy", ".npz",
    ".uasset", ".umap", ".fbx", ".glb", ".blend", ".exr", ".psd",
    ".wav", ".mp3",
)

# Sanctioned asset-dir prefixes come from ONE data file shared with the CI
# backstop (.github/workflows/repo-hygiene.yml) so the two layers can never
# disagree — .claude/asset-dirs.txt is the single source (D-004). Missing or
# unreadable file = strict posture (empty).
def _allowed_binary_prefixes():
    path = os.path.join(
        os.environ.get("CLAUDE_PROJECT_DIR", "."), ".claude", "asset-dirs.txt"
    )
    try:
        with open(path, encoding="utf-8") as f:
            return tuple(
                line.strip() for line in f
                if line.strip() and not line.lstrip().startswith("#")
            )
    except Exception:
        return ()

ALLOWED_BINARY_DIR_PREFIXES = _allowed_binary_prefixes()

def lfs_tracked(path):
    try:
        out = subprocess.run(
            ["git", "check-attr", "filter", "--", path],
            capture_output=True, text=True, timeout=5,
        ).stdout
        return "filter: lfs" in out
    except Exception:
        return False

def current_branch():
    try:
        r = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True, text=True, timeout=5)
        return r.stdout.strip() if r.returncode == 0 else ""
    except Exception:
        return ""

def push_to_main_is_birth():
    # Sanctioned direct push (BOOTSTRAP.md step 8): allowed only while the
    # repo is demonstrably un-bootstrapped —
    #   (a) origin/main is exactly the template's SINGLE initial commit and
    #       still carries BOOTSTRAP.md, or
    #   (b) the remote definitively has no main at all.
    # ANY inconclusive signal (no origin, network error, ls-remote exit != 2)
    # fails closed → treated as armed → push blocked.
    try:
        have_local = subprocess.run(
            ["git", "rev-parse", "--verify", "-q", "origin/main"],
            capture_output=True, timeout=5).returncode == 0
        if have_local:
            has_bootstrap = subprocess.run(
                ["git", "cat-file", "-e", "origin/main:BOOTSTRAP.md"],
                capture_output=True, timeout=5).returncode == 0
            count = subprocess.run(
                ["git", "rev-list", "--count", "origin/main"],
                capture_output=True, text=True, timeout=10).stdout.strip()
            return has_bootstrap and count == "1"
        # No local origin/main: birth ONLY if ls-remote definitively reports
        # main absent (its documented --exit-code value is 2). A single-branch
        # clone lacks origin/main even when the remote has it, so we must ask
        # the remote — but a missing/renamed origin or a network error returns
        # a DIFFERENT non-zero code, which must NOT disarm the guard.
        r = subprocess.run(
            ["git", "ls-remote", "--exit-code", "--heads", "origin", "main"],
            capture_output=True, timeout=15)
        return r.returncode == 2
    except Exception:
        return False  # fail closed: treat as armed

def norm_branch(ref, cur):
    # Reduce a push refspec token to its destination branch name:
    # src:dst -> dst · refs/heads/main -> main · HEAD -> current branch.
    dst = ref.split(":")[-1]
    if dst == "HEAD":
        return cur
    return dst.rsplit("/", 1)[-1]

def dead_pr(branch, src_ref):
    """Zombie-push detection: returns (state, number) when the branch's
    PR history is terminal (latest PR MERGED/CLOSED, none open) AND the
    commits being pushed still sit on the old pre-merge line; None otherwise.
    A branch legitimately RESTARTED from the integration line (its history
    contains current origin/development) is fresh follow-up work headed for
    a fresh PR — allowed. FAILS OPEN (None) on any gh/network error: see the
    header. MCP/API pushes bypass this hook entirely — the session-start
    PR verdict and the PR-lifecycle rule are that net
    (docs/process/pushing.md)."""
    try:
        # gh is reached through an explicit seam: GUARD_GH_BIN (POSIX
        # shlex-split — forward-slash paths, e.g. "bash /path/to/mock")
        # replaces the leading "gh" so the regression suite can substitute
        # its hermetic mock on every platform. PATH interception alone
        # cannot: a Windows-native Python resolves this spawn via
        # CreateProcess, which cannot execute an extensionless shebang
        # script and silently falls through to the real gh. Unset or
        # empty -> exactly ["gh"], byte-identical production behavior.
        gh_argv = shlex.split(os.environ.get("GUARD_GH_BIN", "")) or ["gh"]
        r = subprocess.run(
            gh_argv + ["pr", "list", "--head", branch, "--state", "all",
                       "--json", "number,state", "--limit", "20"],
            capture_output=True, text=True, timeout=15)
        if r.returncode != 0:
            return None
        prs = json.loads(r.stdout or "[]")
        if not prs or any(p.get("state") == "OPEN" for p in prs):
            return None
        latest = max(prs, key=lambda p: p.get("number", 0))
        if latest.get("state") not in ("MERGED", "CLOSED"):
            return None
        # Best-effort fetch so a stale local origin/development ref cannot
        # hide a moved integration line; ignore failures (offline degrades
        # to the local ref, still better than memory).
        subprocess.run(["git", "fetch", "origin", "development"],
                       capture_output=True, timeout=20)
        anc = subprocess.run(
            ["git", "merge-base", "--is-ancestor", "origin/development",
             src_ref], capture_output=True, timeout=10)
        if anc.returncode == 0:
            return None  # restarted on the current integration line
        return (latest.get("state"), latest.get("number"))
    except Exception:
        return None

def worktree_new_binaries():
    # Files a bulk `git add` would stage: untracked + modified, .gitignore
    # respected. Fail-open (empty) on error — repo-hygiene CI is the backstop.
    try:
        out = subprocess.run(
            ["git", "ls-files", "--others", "--modified", "--exclude-standard"],
            capture_output=True, text=True, timeout=10).stdout
    except Exception:
        return []
    bad = []
    for f in out.splitlines():
        f = f.strip()
        if not f or f.startswith(ALLOWED_BINARY_DIR_PREFIXES):
            continue
        if f.lower().endswith(BINARY_EXT) and not lfs_tracked(f):
            bad.append(f)
    return bad

PUSH_MAIN_MSG = (
    "BLOCKED (CLAUDE.md hard rule): never push to main. Instead: push the "
    "feature branch and open a PR into development — main is promoted via PR "
    "only. If this IS a fresh un-bootstrapped template clone, ask the user to "
    "approve this push explicitly."
)
FORCE_MSG = (
    "BLOCKED (CLAUDE.md hard rule): no force-pushes or history rewrites. "
    "Rebase or merge onto the moved remote instead; if a force-push is "
    "genuinely required, ask the user explicitly first."
)
DELETE_MSG = (
    "BLOCKED (CLAUDE.md hard rule): remote branch deletion is guarded — you "
    "may delete only branches you created in this session. If that is the "
    "case here, ask the user to confirm and run the deletion themselves."
)
MERGE_MSG = (
    "BLOCKED (CLAUDE.md hard rule): never merge your own PR (this includes "
    "`gh pr merge` and `gh api .../merge`). Leave the PR for the user to "
    "review and merge."
)

def binary_msg(arg):
    return (
        f"BLOCKED (CLAUDE.md hard rule): '{arg}' is a binary-type file not "
        "covered by LFS. Never commit binaries — run artifacts go to the data "
        "repo; for a genuinely-needed authored asset, add an LFS pattern to "
        ".gitattributes and ask the user first."
    )

cur = None  # current branch, fetched lazily (one subprocess at most)

# Examine each shell segment separately (handles `a && b`, `a; b`, pipes).
for seg in re.split(r"&&|\|\||;|\|", cmd):
    try:
        tokens = shlex.split(seg)          # strips quotes; handles "foo.png"
    except Exception:
        tokens = seg.split()               # fall back on unbalanced quotes
    for i, t in enumerate(tokens):
        if t == "git" and i + 1 < len(tokens):
            sub = tokens[i + 1]
            rest = tokens[i + 2:]
            flags = [a for a in rest if a.startswith("-")]
            positional = [a for a in rest if not a.startswith("-")]
            if sub == "push":
                # Remote branch deletion: --delete/-d flag, or a :dst (empty
                # source) refspec. Guarded regardless of branch — the hook
                # can't verify session-authorship, so it defers to the user.
                if any(f in ("--delete", "-d") for f in flags) or \
                   any(a.startswith(":") for a in positional):
                    block(DELETE_MSG)
                if cur is None:
                    cur = current_branch()
                # R1 — any explicit refspec destination names main/master
                # (covers `origin main`, `HEAD:main`, `refs/heads/main`,
                # `feature:main`).
                targets_main = any(
                    norm_branch(a, cur) in ("main", "master") for a in positional
                )
                # R2 — implicit push while checked out ON main (bare `git
                # push`, `git push origin`, `git push origin HEAD`): the first
                # positional is the remote, refspecs follow it; if none names a
                # non-main branch, the push lands on main.
                refspecs = positional[1:]
                explicit_nonmain = any(
                    norm_branch(a, cur) not in ("main", "master") for a in refspecs
                )
                implicit_to_main = cur in ("main", "master") and not explicit_nonmain
                if (targets_main or implicit_to_main) and not push_to_main_is_birth():
                    block(PUSH_MAIN_MSG)
                if any(a in ("--force", "-f", "--force-with-lease") for a in flags):
                    block(FORCE_MSG)
                # R3 — zombie push: git happily pushes to a branch whose
                # PR was already merged or closed (delete-on-merge even
                # recreates the pruned branch) and GitHub attaches the commits
                # to nothing; the agent then reports "landed on the PR" off a
                # local exit code. Verify the PR state before the push.
                dests = {}
                for a in refspecs:
                    dests[norm_branch(a, cur)] = a.split(":")[0] or "HEAD"
                if not dests and cur:
                    dests[cur] = "HEAD"
                for dest, src in dests.items():
                    if not dest or dest in ("main", "master"):
                        continue
                    hit = dead_pr(dest, src)
                    if hit and hit[0] == "MERGED":
                        block(
                            f"BLOCKED (PR lifecycle): PR #{hit[1]} for "
                            f"branch '{dest}' is MERGED — this branch is dead "
                            "history; pushing would strand commits on a zombie "
                            "branch that no PR will ever merge. Instead: "
                            "restart the branch from the integration line "
                            "(git fetch origin development && git checkout -B "
                            f"{dest} origin/development), re-apply the "
                            "follow-up work, push, and open a FRESH PR. Never "
                            "stack new commits on merged history."
                        )
                    if hit and hit[0] == "CLOSED":
                        block(
                            f"BLOCKED (PR lifecycle): PR #{hit[1]} for "
                            f"branch '{dest}' was CLOSED without merging — the "
                            "operator rejected that line of work; more commits "
                            "do not reverse the decision. Ask the user how to "
                            "proceed; if new work under this branch name is "
                            "wanted, restart it from origin/development first."
                        )
            elif sub == "add":
                # Bulk add (`-A`, `--all`, `.`) stages the whole worktree, so
                # inspect what it would actually stage, not just named paths.
                if any(a in (".", "-A", "--all") for a in rest):
                    for f in worktree_new_binaries():
                        block(binary_msg(f))
                for arg in positional:
                    if arg == "." or arg.startswith(ALLOWED_BINARY_DIR_PREFIXES):
                        continue
                    if arg.lower().endswith(BINARY_EXT) and not lfs_tracked(arg):
                        block(binary_msg(arg))
            # `git rm`/`git mv` of a Decided ADR is guarded by guard-adr.sh,
            # which is also registered on Bash (single home for ADR logic).
        elif t == "gh" and i + 1 < len(tokens):
            nxt = tokens[i + 1]
            rest = tokens[i + 2:]
            if nxt == "pr" and rest and rest[0] == "merge":
                block(MERGE_MSG)
            # Self-merge via the REST API: `gh api .../pulls/N/merge`.
            if nxt == "api" and any(re.search(r"/merge\b", a) for a in rest):
                block(MERGE_MSG)

sys.exit(0)
PY
exit $?
