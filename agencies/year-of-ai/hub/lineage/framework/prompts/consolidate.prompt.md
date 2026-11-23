---
name: Consolidate
description: "Merge a completed lineage of sibling knowledge-base repos into one consolidated repository named for their combined range (e.g. 2005-2011), then archive the members. Use when: check-lifecycle reports phase `consolidate` (lineage reached consolidate_at_members); manually closing out a finished family of repos. Concept-agnostic — lineage, naming rule, and layout come from lifecycle.yml."
argument-hint: "Optional: `--dry-run` to plan the merge without creating or archiving anything."
agent: agent
tools: [read, edit, execute, web, github]
---

Run the **consolidation routine**: combine every repository in this lineage into a single consolidated repository named for the family's range, then archive the members. This is the terminal phase of the lifecycle — after it, the lineage is one repo.

Read [lifecycle.yml](../../lifecycle.yml) first — the lineage, the `consolidation.naming_rule`, and the `consolidation.layout` parameterize everything.

## Preconditions

1. Run the **check-lifecycle** skill. Proceed only if it reports phase `consolidate`: the lineage (excluding the reference `origin`) has ≥ `consolidate_at_members` members and this repo is the **newest** member (only the newest member ever consolidates — it is the one whose lineage list is complete).
2. The newest member has **finished its growth generation** before this fires (the gate requires `generation_ticks ≥ replant_after_ticks`), so it has a full generation of content like the others — never consolidate a half-grown final member. It is still `growing` (it hit budget but consolidates *instead of* replanting): finish Part A of the **replant** prompt first (finalize in place — settle structure, compact roadmap, sync seed, mark mature) — but do **not** spawn a successor. Every other member is already `mature`.
3. Confirm repo-creation and archive permissions. In CI the ambient GitHub token is scoped to this repo only — use the `LIFECYCLE_PAT` environment variable (`GH_TOKEN="$LIFECYCLE_PAT" gh …`) for creating the consolidated repo, pushing to members, and archiving them. With `--dry-run`, skip all writes and emit the plan only.

## Procedure

1. **Name the consolidated repo** by applying `consolidation.naming_rule` to the lineage's subjects (e.g. members 2005…2011 → `2005-2011`).
2. **Create the consolidated repository** under the same owner and clone it.
3. **Merge content** per `consolidation.layout` — one top-level directory per member, named by its subject slug:
   - copy each member's category directories and topic files under `<member-slug>/…`;
   - copy each member's `seed.md` to `<member-slug>/seed.md` **unchanged** — every Evolution Log is preserved verbatim;
   - copy each member's `README.md` to `<member-slug>/README.md`.
4. **Write the consolidated root**:
   - `seed.md` — a new Concept Definition spanning the combined range (e.g. subject "the years 2005–2011"; scope = union of member scopes; taxonomy = the shared taxonomy); §8 starts with a `### Consolidation — <date>` genesis entry listing the merged members;
   - `README.md` — title for the range, a member table linking each `<member-slug>/` section, and a note on the lineage's origin;
   - `lifecycle.yml` — carry the `policy` forward; set `state.status: consolidated`, `state.granularity: <policy.consolidation.deepen_granularity, default month>`, `state.next_lineage_planted: null`, lineage rewritten to the single consolidated entry. This primes the **expand** phase: the consolidated repo is **not terminal** — its own cron will deepen it (month-level) and seed the next era's lineage via `/expand`.
   - `.github/` + `.claude/` layers copied verbatim (including `grow.yml`, `telemetry.yml`, `learn.yml`, and the `expand` prompt/command), so the consolidated repo keeps expanding via its own scheduled runs.
5. **Regenerate structure** — run the **build-structure** skill at the root: a master `INDEX.md` and `TIMELINE.md` spanning all members, plus per-member index links.
6. **Verify** — every member directory present; per-member seeds' Evolution Logs intact; no content files lost (compare file counts per member before/after).
7. **Publish** the consolidated repo (commit + push to its `main`).
8. **Retire the members** — for each member repo: set `lifecycle.yml` `state.status: consolidated`, add a README banner `Consolidated into <owner>/<range-name>`, push, then **archive** the repository on GitHub (read-only). Never delete.

## Output Format

```
## Consolidation Summary

**Consolidated repo**: <owner>/<range-name> (pushed <SHA>)
**Members merged**: <m> — <slug list>
**Content moved**: <files> topic files, <rows> table rows, <m> evolution logs preserved
**Members archived**: <list | dry-run: none>
**Next**: the consolidated repo's cron runs `/expand` — deepens to month granularity and seeds the next lineage (`policy.succession.next_lineage`)
```
