#!/usr/bin/env bash
# One-shot, idempotent GitHub repo setup — everything a template repository
# CANNOT carry (GitHub templates copy files only: no labels, branches,
# protection, Pages config, environments, or variables). Run once after
# seeding a new repo; safe to re-run.
#
# Usage:
#   scripts/github_setup.sh [-R owner/repo] [--profile code|data]
#                           [--areas "name1,name2"] [--require-check <ctx>]...
#
#   -R               target repo (default: origin of the current directory)
#   --profile code   full setup: labels, development branch (made default),
#                    branch protection, Pages via Actions + github-pages
#                    environment branch policy, DEPLOY_DOCS variable, merge
#                    settings. (default)
#   --profile data   paired data repo: labels + anti-force-push protection
#                    only (no development branch, no Pages — data repos take
#                    direct pushes from tooling).
#   --areas          extra area:* labels to create, comma-separated
#   --require-check  a status-check context required on main (repeatable);
#                    default when omitted: build + flow-guard — the two jobs
#                    the template itself ships (docs.yml, branch-flow-guard.yml)
#
# Requires: gh (authenticated with repo admin), python3 + PyYAML (labels).
# Not scriptable here (do manually if wanted): secrets, Pages custom domain,
# LICENSE decision, marking a repo as a template.
set -euo pipefail

PROFILE=code
AREAS=""
CHECKS=()
REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    -R) REPO="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --areas) AREAS="$2"; shift 2 ;;
    --require-check) CHECKS+=("$2"); shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
fi
echo "== Setting up $REPO (profile: $PROFILE) =="

# --- Labels (both profiles) ---------------------------------------------
"$(dirname "$0")/bootstrap_labels.sh" -R "$REPO"
if [ -n "$AREAS" ]; then
  IFS=',' read -ra AREA_ARR <<<"$AREAS"
  for a in "${AREA_ARR[@]}"; do
    a=$(echo "$a" | xargs)  # trim
    [ -n "$a" ] && gh label create "area:$a" --color 1D76DB --force -R "$REPO"
  done
fi

DEFAULT_BRANCH=$(gh api "repos/$REPO" --jq .default_branch)

if [ "$PROFILE" = "code" ]; then
  # --- development branch, made the default ------------------------------
  # Feature branches PR into development; main is the promoted branch
  # (docs/process/contributing.md, CLAUDE.md → Repo workflow).
  if ! gh api "repos/$REPO/git/ref/heads/development" >/dev/null 2>&1; then
    SHA=$(gh api "repos/$REPO/git/ref/heads/$DEFAULT_BRANCH" --jq .object.sha)
    gh api -X POST "repos/$REPO/git/refs" \
      -f ref="refs/heads/development" -f sha="$SHA" >/dev/null
    echo "created branch: development (from $DEFAULT_BRANCH @ ${SHA:0:7})"
  else
    echo "branch exists: development"
  fi
  gh api -X PATCH "repos/$REPO" -f default_branch=development >/dev/null
  echo "default branch: development"

  # --- Branch protection --------------------------------------------------
  # main: PRs only (0 approvals — solo-dev calibrated: require checks, not
  # reviews), no force-pushes, no deletion, required status checks.
  # Default contexts: the template's own shipped gates — docs.yml's `build`
  # and branch-flow-guard.yml's `flow-guard` — so the prose rules are backed
  # by required checks out of the box (D-004; a required context that never
  # reports blocks merges forever, hence only jobs the template itself
  # ships). Override with --require-check.
  if [ ${#CHECKS[@]} -eq 0 ]; then
    CHECKS=(build flow-guard)
  fi
  CONTEXTS_JSON=$(printf '%s\n' "${CHECKS[@]:-}" | python3 -c \
    'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')
  gh api -X PUT "repos/$REPO/branches/main/protection" --input - >/dev/null <<JSON
{
  "required_status_checks": {"strict": true, "contexts": $CONTEXTS_JSON},
  "enforce_admins": false,
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
  echo "protected: main (PRs only, checks: $CONTEXTS_JSON)"

  # development: block force-pushes/deletion AND require the docs build to
  # pass — CLAUDE.md's "never commit directly to development" was previously
  # prose-only here; a required check makes green-build the price of landing
  # anything on the integration branch (D-004). strict=false: development
  # PRs need green checks but not a rebase race.
  gh api -X PUT "repos/$REPO/branches/development/protection" --input - >/dev/null <<'JSON'
{
  "required_status_checks": {"strict": false, "contexts": ["build"]},
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
  echo "protected: development (no force-push; required check: build)"

  # --- GitHub Pages via Actions + environment branch policy ---------------
  # The silent-breakage trap: the github-pages environment must ALLOW deploys
  # from development as well as main, or the deploy job is rejected for any
  # non-default branch. docs.yml deploys only when DEPLOY_DOCS=true.
  if ! gh api "repos/$REPO/pages" >/dev/null 2>&1; then
    gh api -X POST "repos/$REPO/pages" -f build_type=workflow >/dev/null
    echo "pages: created (source = GitHub Actions)"
  else
    gh api -X PUT "repos/$REPO/pages" -f build_type=workflow >/dev/null
    echo "pages: source = GitHub Actions"
  fi
  gh api -X PUT "repos/$REPO/environments/github-pages" --input - >/dev/null <<'JSON'
{"deployment_branch_policy": {"protected_branches": false, "custom_branch_policies": true}}
JSON
  for BR in main development; do
    gh api -X POST "repos/$REPO/environments/github-pages/deployment-branch-policies" \
      -f name="$BR" >/dev/null 2>&1 || true   # 422 = policy already exists
  done
  echo "pages env: deploys allowed from main + development"
  gh variable set DEPLOY_DOCS -b "true" -R "$REPO"
  echo "variable: DEPLOY_DOCS=true (docs.yml deploy job enabled)"

  # --- Merge settings ------------------------------------------------------
  gh api -X PATCH "repos/$REPO" \
    -F delete_branch_on_merge=true \
    -F allow_squash_merge=true -F allow_merge_commit=true -F allow_rebase_merge=false \
    >/dev/null
  echo "merge: squash+merge-commit enabled, rebase off, delete-branch-on-merge"

else
  # --- data profile --------------------------------------------------------
  # Data repos take direct pushes from run tooling; protect only against
  # history rewrites on the default branch.
  gh api -X PUT "repos/$REPO/branches/$DEFAULT_BRANCH/protection" --input - >/dev/null <<'JSON'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
  echo "protected: $DEFAULT_BRANCH (no force-push; direct pushes allowed)"
fi

echo "== $REPO setup complete =="
echo "Manual residue (not API-reachable / judgment-bound):"
echo "  - git lfs install        (once per machine, before touching LFS paths)"
echo "  - LICENSE decision       (seeded project's own — template LICENSE deleted at bootstrap)"
echo "  - secrets / integrations (if any)"
