---
description: "Lineage meta-review on the frontier model: analyze all member repos, improve the evolution cycle, and distill a minimal portable seed package that can spawn a similar-or-better lineage for ANY starting concept."
argument-hint: "[--force] — optional; re-distill even if state.distilled_at is set"
---

Run the **distillation** for this lineage.

Canonical playbook: read `.github/prompts/distill.prompt.md` and follow it exactly. Gate: the lifecycle phase must be `distill` (lineage ≥ `distill_at_members`, `state.distilled_at` null) or `$ARGUMENTS` contains `--force`.

Four parts:
1. **Review** — clone every lineage member via `GH_TOKEN="$LIFECYCLE_PAT"`; study seeds (§8
Evolution Logs), lifecycle state, content quality, framework, and the driver's merged-PR failure ledger.
2. **Improve** — apply concept-agnostic cycle improvements to the live framework (pollinate fans them out).
3. **Distill** — write `seed-package/` (README with configure-and-launch steps incl. the
"the year 1776" worked example, `seed.template.md`, `lifecycle.template.yml`, `MANIFEST.md` naming the minimal load-bearing framework files).
4. **Record** — set `state.distilled_at`, append a `### Distillation` Evolution Log entry, publish via publish-session.

End with the `## Distillation Report` block. Arguments: $ARGUMENTS
