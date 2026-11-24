# Seed Package — plant a self-growing knowledge-base lineage for ANY concept

This is the minimal, portable bootstrap kit distilled from a live lineage. Copy it into a fresh repo, fill two templates, set two secrets, and a scheduled workflow germinates and grows the repo on its own — then replants successors, consolidates them, and expands, with no further input.

**What it grows.** A repo that is two things at once: (1) a source-verified, encyclopedic knowledge base about one **concept**, and (2) the reusable framework that grows it. Point it at a new concept and it grows a different knowledge base — nothing in the framework hardcodes a subject; everything derives from `seed.md` §1.

See [`MANIFEST.md`](./MANIFEST.md) for the exact file list this package comprises.

---

## Prerequisites (one-time, ~10 minutes)

1. **Create a GitHub org** (or pick an owner account) to hold the lineage, e.g. `year-of-ai`.
2. **Install the Claude GitHub App** on the org (or the specific repos), so workflows can run Claude.
3. **Set org secrets** (Settings → Secrets and variables → Actions):
   - `ANTHROPIC_API_KEY` — your Anthropic API key (powers the growth model).
   - `LIFECYCLE_PAT` — a Personal Access Token with **repo create + archive** and **`workflow`** scope (classic) or **Administration: write + Workflows: write** (fine-grained). This is what lets a maturing repo spawn and register its successor, and lets consolidation archive members.
   - `CLAUDE_CODE_OAUTH_TOKEN` *(optional)* — if you drive Claude Code via OAuth instead of the API key.

> The ambient `GITHUB_TOKEN` is scoped to one repo. **All cross-repo actions (creating successors,
> cloning lineage members, archiving) use `LIFECYCLE_PAT`** — that is the whole reason it exists.

---

## Launch a new lineage

1. **Create the first repo**, named for the starting concept's slug, under the org:
   ```bash
   GH_TOKEN="$LIFECYCLE_PAT" gh repo create <owner>/<first-slug> --public
   ```
2. **Copy the package into the repo**: the framework layer (`.github/`, `.claude/`, `CLAUDE.md`, `LIFECYCLE.md`, `.gitignore`) verbatim, plus the two filled templates (next step).
3. **Fill `seed.template.md` → `seed.md`**: set `concept.subject`, write the `scope` paragraph, list 4–8 `taxonomy` categories, and name your `source_strategy` sources. Leave §2–7 out — they regenerate. (You can even leave the taxonomy rough; `/genesis` refines it.)
4. **Fill `lifecycle.template.yml` → `lifecycle.yml`**: write the `succession.rule`, `consolidation.naming_rule`, and `deepen_granularity`; leave the whole `state` block as-is.
5. **Push to `main`.** That's it. The scheduled `grow.yml` workflow takes over: on its first run it detects the un-germinated seed and runs `/genesis`, then every subsequent run grows one tick, replants at `replant_after_ticks`, consolidates at `consolidate_at_members`, and so on.

To kick the first run without waiting for the schedule: `GH_TOKEN="$LIFECYCLE_PAT" gh workflow run grow.yml --repo <owner>/<first-slug>`.

---

## Worked example — starting concept "the year 1776"

1. `GH_TOKEN="$LIFECYCLE_PAT" gh repo create year-of-ai/1776 --public`
2. Copy the framework layer + templates into the repo.
3. `seed.md` Concept Definition:
   ```yaml
   concept:
     subject: "the year 1776"
     scope: >
       All notable events, people, works, and discoveries that occurred in or significantly
       defined the calendar year 1776 — across politics, military conflict, science, arts,
       economics, and society worldwide.
     taxonomy:
       - { name: "Political Events",   slug: "politics" }
       - { name: "Military Events",    slug: "military" }
       - { name: "Science & Discovery", slug: "science" }
       - { name: "Arts & Culture",     slug: "arts" }
       - { name: "Economics & Trade",  slug: "economics" }
       - { name: "Key Figures",        slug: "people" }
     source_strategy:
       encyclopedic: "Wikipedia, Britannica"
       specialist: ["Library of Congress (loc.gov)", "Founders Online (founders.archives.gov)"]
       minimum_sources: 2
     conventions:
       knowledge_table: "## Notable Events of 1776"
       file_path: "<category-slug>/<topic-slug>.md"
       frontmatter: ["title", "date", "category"]
       tone: "factual, neutral, encyclopedic, third person"
   ```
4. `lifecycle.yml`: `succession.rule: "Increment the calendar year of the newest member by one."`, `consolidation.naming_rule: "Hyphenated range of the lineage's years, oldest-newest."`, `deepen_granularity: "month"`. Leave `state` virgin.
5. `git push`. The workflow germinates `1776`, grows it for 3 ticks, then replants `1777`, which replants `1778`; at 3 members the lineage `/distill`s (refreshing this very package), and at 7 it `/consolidate`s into `1776-1782`, which `/expand`s to month granularity and seeds the next era.

The same five steps with `subject: "an organization"` or `"a technology"` grow an entirely different knowledge base — only `seed.md` §1 and the `lifecycle.yml` policy rules change.
