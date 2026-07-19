---
paths:
  - ".github/**"
  - ".gitignore"
  - ".gitattributes"
  - "mkdocs.yml"
  - ".claude/settings.json"
  - "docs/requirements.txt"
---

# Config files cite their governing decision

You are editing CI or repo config. Non-obvious lines carry a rationale
comment naming the `D-###` decision or `#issue` that put them there, so the
file explains itself. Canonical rule: `CLAUDE.md` → *Conventions*; rationale:
`docs/process/contributing.md` → *Enforcement layering (D-004)*.

Files that can't carry inline comments (JSON) cite their rationale here or in
the governing doc — e.g. `.claude/settings.json`'s permission deny-list
(`git push --force`/`-f`, `gh pr merge`, `git reset --hard`, `gh repo delete`)
mirrors the CLAUDE.md hard rules (no force-push, no self-merge) and the
irreversible-operation guardrails.

Advisory salience only — the enforcers remain the hooks and CI gates named
there.
