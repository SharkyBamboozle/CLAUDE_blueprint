# Module: lfs-assets

Git LFS for **authored binary assets** (3D models, textures, audio, design
files) that genuinely belong in the code repo — as opposed to run artifacts,
which go to the data repo (data-repo module) and are never committed here.

**Apply when:** the project will hand-author or vendor large binary assets
(game/graphics/audio projects). Skip for pure code/docs projects.

## The rule this module enforces

**Configure LFS patterns BEFORE any binaries exist** — the first binary
committed as a plain blob is the point of no return for git history.
Patterns are **scoped per directory** (e.g. `assets/**/*.glb`), never global
(`*.glb`), so a stray binary outside the sanctioned directory is still
caught by the repo-hygiene CI check instead of being silently LFS'd.

## How to apply (the bootstrap session executes this)

1. **Judgment (Tier 2):** pick the asset directories and file types from the
   menu in `.gitattributes` (this directory) and append the chosen patterns
   to the repo's `.gitattributes` — even if the directories don't exist yet.
2. Reserve LFS for these authored assets only; keep the quota away from run
   outputs (data-repo module) and generated files (`.gitignore`).
3. Post-init checklist items:
   - `git lfs install` — once per machine, before touching LFS paths.
   - Watch the GitHub LFS quota (~1 GiB free storage/bandwidth); budget or
     escalate if asset volume approaches it.
4. Add to `CLAUDE.md` → Repo layout: the asset directory bullet + the
   "Git LFS preconfigured, `git lfs install` once per machine" note.
