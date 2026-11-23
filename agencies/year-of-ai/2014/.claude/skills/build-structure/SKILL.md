---
name: build-structure
description: "Generate and refresh the structural artifacts of this knowledge base — category index pages, a timeline, a master index/TOC, and cross-reference links. Use when new topic files were added and indices need updating, when building repository structure beyond flat content, or when running a structure item from the roadmap. Concept-agnostic and idempotent — derives everything from the concept and existing content; only rewrites generated regions."
---

# Build Structure (Claude Code adapter)

Canonical procedure: **`.github/skills/build-structure/SKILL.md`**. Read that file and follow it exactly. Read the **Concept Definition** in `seed.md` first (`subject`, `taxonomy`, `conventions`).

Summary — regenerate structural artifacts **from existing content**, idempotently. Every generated file/region is wrapped in markers so regeneration only replaces generated content:

```
<!-- BEGIN GENERATED: <artifact> — maintained by build-structure; do not edit by hand -->
...
<!-- END GENERATED: <artifact> -->
```

Artifacts (theme news layout):
1. **Section index pages** `_posts/<section-slug>/<year>-01-01-index.md` (`layout: section`, `permalink: /news/<slug>/`) — one per taxonomy category; the `section` layout auto-lists that section's posts and builds the topic (tag) sidebar/filters.
2. **/news/ landing** `news.md` (`layout: news`) + the homepage `index.html` (the magazine).
3. **Navigation data** `_data/navigation/posts.yml` (the sections) + `main.yml` (the navbar with a News dropdown).
4. **Preview placeholders** `assets/images/previews/<section-slug>.svg` + `default.svg` (XML-escape `&` in section names).
5. **Timeline** `TIMELINE.md` — only if the `subject` is time-oriented; dated posts sorted chronologically, linked by permalink.

A post's **tags** are its section's sub-topics — the `section` layout renders them; do not invent other grouping files. For a one-time conversion of a legacy flat repo, use the hub's `scripts/migrate-to-news-structure.rb`. Never alter hand-written post bodies or `seed.md` sections 1–7 (that's `sync-seed`'s job). Keep output deterministic (stable ordering) so reruns are diff-free. Report created / updated / unchanged.
