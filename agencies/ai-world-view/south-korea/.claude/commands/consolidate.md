---
description: "Merge a completed lineage of sibling knowledge-base repos into one consolidated repository named for their combined range (e.g. 2005-2011), then archive the members."
argument-hint: "[--dry-run] — optional; plan the merge without creating or archiving anything"
---

Run the **consolidation routine** for this lineage of self-growing knowledge bases.

Canonical playbook: read `.github/prompts/consolidate.prompt.md` and follow it exactly. The lineage, `consolidation.naming_rule`, and `consolidation.layout` in `lifecycle.yml` parameterize everything — read it first; never assume subjects or a repo name.

Outline:

1. **Gate** — check-lifecycle must report phase `consolidate` (lineage ≥ `consolidate_at_members`, this repo is the newest member). Finalize this repo first (replant Part A, no spawn) if still growing.
2. **Create** the consolidated repo named per the naming rule (e.g. `2005-2011`).
3. **Merge** — one top-level directory per member (`<member-slug>/…`) holding its content, its `seed.md` (Evolution Log preserved verbatim), and its `README.md`.
4. **Root layer** — range-spanning `seed.md` + `README.md`, `lifecycle.yml` (`status: consolidated`), and the verbatim `.github/` + `.claude/` layers so it can keep growing.
5. **Structure** — build-structure at the root (master INDEX/TIMELINE across members). Verify no files lost, then publish.
6. **Retire members** — status `consolidated`, README banner pointing to the new repo, push, then archive on GitHub. Never delete.

Honor `--dry-run`: plan only, no writes. In CI the ambient token is repo-scoped — use `GH_TOKEN="$LIFECYCLE_PAT" gh …` for repo creation, member pushes, and archival. End with the `## Consolidation Summary` block from the canonical prompt.

Arguments: $ARGUMENTS
