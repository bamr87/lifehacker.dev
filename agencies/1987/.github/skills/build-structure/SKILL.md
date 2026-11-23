---
name: build-structure
description: 'Generate and refresh the structural artifacts of this knowledge base — category index pages, a timeline, a master index/TOC, and cross-reference links. Use when: new topic files were added and indices need updating; building out repository structure beyond flat content; running a structure item from the roadmap. Concept-agnostic and idempotent — derives everything from the concept and existing content; only rewrites generated regions.'
argument-hint: 'Optional: which artifact to (re)build — indices | timeline | toc | crossrefs. Leave blank to refresh all.'
---

# Build Structure

Regenerates the repository's structural layer **from existing content**. Idempotent: running it twice with no content change produces no diff. Read the **Concept Definition** in [seed.md](../../../seed.md) first for `subject`, `taxonomy`, and `conventions`.

Every generated file/region is wrapped in markers so regeneration only replaces generated content:

```
<!-- BEGIN GENERATED: <artifact> — maintained by build-structure; do not edit by hand -->
...generated content...
<!-- END GENERATED: <artifact> -->
```

---

## Artifacts

### 1. Category index pages — `<category-slug>/index.md`
For each entry in `concept.taxonomy`, create/update an index listing every topic file in that folder (link + the topic's one-line description from its frontmatter/summary). Skip folders with no topic files (or write a "no entries yet" stub).

### 2. Timeline — `TIMELINE.md`
Only if the `subject` is time-oriented (e.g. a year, era, or event sequence). Collect dated items from the README knowledge table and dedicated files, sort chronologically, and render
`| Date | Item | Category | Link |`.

### 3. Master index / TOC — `index.md`
A map of all content grouped by `concept.taxonomy` category: every topic file linked, plus a pointer to each category index and to `TIMELINE.md`. Filename is **lowercase `index.md`** so GitHub Pages' Jekyll build emits the site-root `index.html` — an uppercase `INDEX.md` renders to `INDEX.html` and leaves the repo's Pages root (`/`) a 404. (Alternatively maintain a generated TOC region inside README.md — pick one and be consistent.)

### 4. Cross-references
For each dedicated topic file, add/refresh a `## Related` section linking 2–4 closely related topic files (same category or shared people/events). Maintain these inside the generated marker block so they don't clobber hand-written content.

---

## Procedure
1. Read the concept + scan the repo (category folders, topic files, README table).
2. For each requested artifact (or all), regenerate **only** the marked region; create the file with the marker block if it doesn't exist.
3. Do not alter hand-written content outside the markers, and never touch seed.md sections 1–7 (that's `sync-seed`'s job).
4. Report which artifacts were created/updated and which were unchanged.

## Notes
- Determine time-orientation from the concept, not hardcoded — if `subject` has no temporal axis, skip the timeline and note it.
- Keep generated content deterministic (stable ordering) so reruns are diff-free.
