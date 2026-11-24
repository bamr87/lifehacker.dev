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

Artifacts:
1. **Category index pages** `<category-slug>/index.md` — list every topic file in that folder (link + one-line description).
2. **Timeline** `TIMELINE.md` — only if the `subject` is time-oriented; dated items sorted chronologically.
3. **Master index** `INDEX.md` — all content grouped by `concept.taxonomy`, plus pointers to category indices and the timeline.
4. **Cross-references** — a `## Related` block (2–4 links) inside each dedicated topic file.

Never alter hand-written content outside the markers, and never touch `seed.md` sections 1–7 (that's `sync-seed`'s job). Keep output deterministic (stable ordering) so reruns are diff-free. Report created / updated / unchanged.
