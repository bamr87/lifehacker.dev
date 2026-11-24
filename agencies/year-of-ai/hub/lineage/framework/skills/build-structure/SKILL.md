---
name: build-structure
description: 'Generate and refresh the structural artifacts of this knowledge base in the theme''s news layout — per-section index pages (/news/<slug>/), the /news/ magazine landing, the navigation data, SVG preview placeholders, and an optional timeline. Use when: new posts were added and section counts/landing need updating; wiring a repo into the news layout; running a structure item from the roadmap. Concept-agnostic and idempotent — derives everything from the concept and existing posts.'
argument-hint: 'Optional: which artifact to (re)build — sections | landing | nav | previews | timeline. Leave blank to refresh all.'
---

# Build Structure

Regenerates the repository's structural layer **from existing posts**, in the shared theme's **news layout**. Idempotent: running it twice with no content change produces no diff. Read the **Concept Definition** in [seed.md](../../../seed.md) first for `subject`, `taxonomy`, and `conventions`, and the layout rules in [content.instructions.md](../../instructions/content.instructions.md).

> For a **one-time conversion** of a legacy flat repo (`<section>/<topic>.md` at the root) into this
> layout, use the hub tool `scripts/migrate-to-news-structure.rb` instead — it moves posts, rewrites
> links, and generates every artifact below in one deterministic pass. This skill maintains the
> layout thereafter.

Every generated file/region is wrapped in markers so regeneration only replaces generated content:

```
<!-- BEGIN GENERATED: <artifact> — maintained by build-structure; do not edit by hand -->
...generated content...
<!-- END GENERATED: <artifact> -->
```

---

## Artifacts

### 1. Section index pages — `_posts/<section-slug>/<year>-01-01-index.md`
For each entry in `concept.taxonomy`, create/update the section index that publishes at `/news/<section-slug>/`. Front matter: `layout: section`, `title` (section name), `category`/`categories` (section name), `tags: [<section-slug>]`, `icon` (a Bootstrap icon name without the `bi-` prefix), `description`, `section_style: grid`, `index: true`, `sitemap: false`, `permalink: /news/<section-slug>/`, `preview: /images/previews/<section-slug>.svg`. The `section` layout auto-discovers the section's posts and builds the topic (tag) sidebar/filters from them.

### 2. `/news/` landing — `news.md` (and the homepage `index.html`)
The magazine landing (`layout: news`, `section_style: magazine`, `permalink: /news/`). Unless the concept says otherwise the site homepage (`index.html`, `permalink: /`) is the same magazine, and `jekyll-readme-index` is dropped from `_config.yml` so it owns `/`.

### 3. Navigation data — `_data/navigation/posts.yml` + `main.yml`
`posts.yml` lists the sections (`title`, `icon: bi-<name>`, `url: /news/<slug>/`, `description`) — this drives the section nav, the /news/ landing counts, and "explore other sections". `main.yml` is the navbar: Home, a **News** dropdown (children = the sections), the timeline, the knowledge index, and the source link.

### 4. Preview placeholders — `assets/images/previews/<section-slug>.svg` + `default.svg`
Self-contained gradient SVG cards (so posts never render broken images). Set `site.teaser` and `site.og_image` in `_config.yml` to `default.svg`. **XML-escape** section names in the SVG (`&` → `&amp;`) — a raw `&` makes the SVG an invalid image.

### 5. Timeline — `TIMELINE.md` (optional)
Only if the `subject` is time-oriented. Dated posts sorted chronologically; links use each post's
permalink (`{{ '/news/<slug>/<topic>/' | relative_url }}`).

---

## Procedure
1. Read the concept + scan `_posts/<section-slug>/` for posts and their `tags`.
2. For each requested artifact (or all), regenerate deterministically (stable ordering) so reruns are diff-free. Create files with the marker block if missing.
3. Do not alter hand-written post bodies, and never touch seed.md sections 1–7 (that's `sync-seed`'s job).
4. Report which artifacts were created/updated/unchanged.

## Notes
- A post's `tags` are its section's sub-topics — do not invent new grouping mechanisms; the `section` layout already renders tags as the sidebar + filter pills.
- Determine time-orientation from the concept, not hardcoded — if `subject` has no temporal axis, skip the timeline and note it.
