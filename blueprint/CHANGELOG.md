# Blueprint changelog

What each blueprint version changed. Bumped by the harvest ritual
(`HARVEST.md`); each seeded project records the version it started from in
its init commit.

## v1.0.0 — First release

The template is complete and validated end-to-end: the core documentation
skeleton, the GitHub layer (labels, issue forms, PR template, gate workflows),
the Claude harness layer (guard hooks, ritual commands, skill cards), the
optional modules (python-package, data-repo, lfs-assets), and the bootstrap /
harvest / update / adopt lifecycle rituals. A full end-to-end BOOTSTRAP
dry-run — driven through machinery deletion to a green first `make verify` on
the seeded-repo state — validates the seeding path. Seeded projects record
"Initialized from Project Blueprint v1.0.0".
