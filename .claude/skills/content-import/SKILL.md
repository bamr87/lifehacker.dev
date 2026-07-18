---
name: content-import
description: >-
  The repeatable flow for importing and REWRITING external/legacy articles into
  on-voice lifehacker.dev content. Use when asked to "import these posts",
  "rewrite the it-journey import", "bring in content from <source>", or to process
  a bulk-import PR (like #55) article-by-article. Triages every source file, routes
  it to the right collection, rewrites it through the content agents (never by hand),
  reuses preview images, preserves it-journey quest links, verifies with the harness,
  and opens ONE PR per collection in batches of 10. Never merges, never self-approves.
---

# content-import — import + rewrite external content, the repeatable way

You are the **migration editor** for lifehacker.dev. Raw content arrives from somewhere else (a legacy blog, a sister site, a bulk-import PR). A mechanical copy is not publishable here: lifehacker has a voice, a Prime Directive, and a schema. Your job is to turn an import into a stream of small, on-voice, human-reviewable PRs — without hand-writing each article. The **agents** do the writing; you orchestrate, verify, and batch.

This skill is the destination-side companion to `grow-lifehacker` (which creates net-new content from the backlog). Same brand, same harness, same guardrails — different input: existing prose instead of a backlog idea.

## The Prime Directive (unchanged)

**The useful thing must actually be useful.** A rewrite may not invent commands or output. If the source's core claims can't be honestly reproduced (cloud account, paid API, physical hardware), the piece is **not** force-fit — it's either reframed as a Field Note that is honest about what wasn't re-run, or skipped. Satire never replaces the working knowledge.

## Hard guardrails (do not violate)

1. **Never push to `main`.** Branch off `main`; open a PR. (See memory: the owner
   merges fast — always branch off `main`, never off a merged import branch.)
2. **Never merge or approve your own work.** A human reviews every PR.
3. **Run through the agents.** Rewrites go through a rewrite agent + the
   `content-reviewer`; you do not author articles directly in the main thread.
4. **Honest attribution.** Robot-authored prose is `author: claude`; when the events
and engineering are a human's real work, keep `author: amr`. Author MUST be a key in `_data/authors.yml` (currently: `amr`, `claude`).
5. **Reuse, don't re-fetch.** Carry the source's preview/asset images over verbatim;
   never invent new screenshots for imported content.
6. **Preserve valid cross-links.** it-journey quest references stay, normalized to
absolute `https://it-journey.dev/...` URLs. Broken/dead source links get dropped, not carried.

## The flow (do these in order)

### 1. Snapshot the source
Get the import content into a readable tree without polluting your branch:
```bash
git fetch origin <import-branch>:refs/remotes/origin/<import-branch>
git worktree add /tmp/import-src origin/<import-branch>
```
If the import shipped a manifest (`docs/POST_IMPORT_MANIFEST.json`), keep its path — it maps each file to the asset images that travel with it.

### 2. Triage — facts, then verdict
**Facts (deterministic):**
```bash
ruby scripts/content/triage_import.rb /tmp/import-src docs/POST_IMPORT_MANIFEST.json \
  > docs/content-import/triage.skeleton.json
```
This records, per file: front matter, preview/assets, quest links, code/shell-block counts, word count, and a heuristic collection guess. It makes **no** editorial call.

**Verdict (through agents):** fan out a triage workflow (one agent per ~8 files) that reads each source file + the skeleton and returns, per file:
`{verdict: rewrite|skip, dest_collection, voice_profile, on_brand_tech, testable_here,
skip_reason, reframed_title, preview_image, quest_links[], rationale}`.

The routing rule is configurable per run; the **tech-only** rule (used for PR #55) is:
> `rewrite` only for genuinely technical pieces with a useful, portable payload
> (CI/CD, shell, Jekyll, Docker, dev env, git, honest tool reviews). Everything else
> — fiction/poetry, opinion/economic essays, non-tech, untestable cloud/hardware,
> thin stubs, quest-tied content — is `skip` with a recorded `skip_reason`.

Write the assembled verdicts to `docs/CONTENT_IMPORT.md` (human-readable table) and `docs/content-import/triage.plan.json` (machine-readable). That plan IS the repeatable record: a re-import is a diff against it, not a re-think.

### 3. Group into batches of 10, per section
Take the `rewrite` set, group by `dest_collection` (the news SECTION — hacks / tools / field-notes; issue #337), and slice into batches of **10**. Each batch becomes one PR. One section per PR — never mix hacks and tools in the same review.

### 4. Rewrite + review each batch — through the agents
For each file in the batch, run a two-stage pipeline (a Workflow is ideal):
- **Stage 1 — rewrite agent.** Give it: the source path, the target section's
front-matter template + voice profile (`_data/brand/voice.yml`), the glossary (`_data/brand/glossary.yml`), the reused preview image path, and the quest links to preserve. It writes the rewritten file to the correct section dir — `pages/_posts/{hacks,tools,field-notes}/<YYYY-MM-DD>-<slug>.md` — and returns a summary. Rules it must follow:
  - Keep the **useful payload**; cut the filler. Leave in **the part where it broke**.
  - Front matter to the schema (see templates below). Every item is a post now:
    `categories: [Hacks]` / `[Tools]` / `[Field Notes]` marks the section (no more
    `collection:` key); hacks/tools pin an explicit `permalink:` (`/hacks/<slug>/`,
    `/tools/<slug>/`); tools also carry `verdict:`. Tags come from the section's
    small reused pill vocabulary — no singletons.
  - Date = the source date if real and not in the future, else today; the **filename
    date must equal `date:`** for posts.
  - **Preview image — ALWAYS set the front-matter `preview:` key** to the reused
    image, where one applies (path like `/assets/images/...`). The `zer0-mistakes`
    theme reads `page.preview` for cards, og:image, and its hero/intro layouts, and
    the site's `_includes/home/cover.html` renders it as the card cover art (with a
    gradient fallback when absent). A hero image that lives only in the body as a
    markdown `![]()` will NOT appear on listings or social cards. Optionally ALSO
    embed it inline for an in-article visual — the `article` layout skips the theme's
    preview banner for `post_type: standard`, so front-matter + inline does not
    double-render. (Home-page and section cards pick the cover art from the item's
    `categories | first` via `_includes/home/card.html` → `home/cover.html`; the
    theme's `/news/<section>/` pages render `page.preview` directly.)
  - Only claim "we ran this" for commands actually re-run during the rewrite. Anything
    not re-run is shown as a plain block, not described as captured output.
  - **Code fences:** use plain ` ```bash ` / ` ```yaml ` fences. kramdown on this site
    renders a space-info fence (` ```bash lh:run `) as PROSE, not code — opt a block
    into the Prime Directive sandbox with a `# lh:run` comment line inside instead.
    Guard GitHub Actions `${{ }}` and Jekyll `{% %}`/`{{ }}` examples with `{% raw %}`.
  - No banned glossary words used **sincerely**; weasel `avoid_phrases` are a hard fail.
- **Stage 2 — `content-reviewer` agent.** One editorial pass over the rewritten file:
voice, completeness, the "you'll know it worked when…" tell, Prime Directive. It applies cheap fixes in place and comments judgment calls.

### 5. Carry the assets
Copy each rewritten file's reused images from the source tree into `assets/` at the SAME path (the theme is shared, so references resolve unchanged):
```bash
rsync -R --files-from=<list> /tmp/import-src/ .
```

### 6. Verify (the gate)
Run the harness and make it green before opening the PR:
```bash
scripts/ci/run-all.sh           # or the per-check scripts in scripts/ci/
```
Fix front-matter errors, broken internal links, and weasel phrases. A `prime_directive_candidate` (a command that didn't run) means demote to a Field Note or fix the command — don't paper over it.

### 7. Open ONE PR for the batch
```bash
git switch -c content-import/<section>-batch-<n> origin/main
git add pages/_posts/<section>/ assets/
git commit && gh pr create
```
PR body: the section, the 10 slugs, what was tested (harness verdict), which preview images were reused, and which quest links were preserved. Label `auto:content`
+ `collection/<section>`. Then **stop** — a human merges.

## Front-matter templates (the harness enforces these)

Field Note (`pages/_posts/field-notes/YYYY-MM-DD-<slug>.md`):
```yaml
---
title: "<what happened, specific>"
description: "<SEO, <=160 chars>"
date: YYYY-MM-DD            # MUST equal the filename date
categories: [Field Notes]  # required — the gate checks for it
tags: [<pill>, <pill>]     # from the field-notes vocabulary; non-empty, no singletons
author: amr                # or claude; must exist in _data/authors.yml
excerpt: "<one-line teaser>"
preview: /assets/images/...  # the hero image, where one applies (theme + cards render it)
---
```
Hack (`pages/_posts/hacks/YYYY-MM-DD-<slug>.md`): `title, description, date, categories: [Hacks], tags[], author, excerpt, permalink: /hacks/<slug>/`, plus `preview:` when a hero image applies. Tool (`pages/_posts/tools/YYYY-MM-DD-<slug>.md`): the hack keys with `categories: [Tools]`, `permalink: /tools/<slug>/`, and a non-empty `verdict:`. Tag from each section's small reused pill vocabulary (hacks: `shell git ci-cd jekyll docker security web-dev data`; tools: `search files data system editor productivity`; field-notes: `automation ai jekyll ci-cd satire business engineering career`).

## When you finish
Report, per batch: the PR URL, the 10 slugs, the harness verdict, the preview images reused, the quest links preserved, and the skip list with reasons. Then stop.
