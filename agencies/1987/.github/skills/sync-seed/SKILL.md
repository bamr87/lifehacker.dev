---
name: sync-seed
description: 'Keep seed.md (the repository DNA) in sync with the actual repo state. Use when: ending a growth tick; after adding content or structure; whenever the seed''s inventories may have drifted from reality. Concept-agnostic. Regenerates seed.md sections 1–7 from the live repo; never touches the Evolution Log (section 8).'
argument-hint: 'No arguments. Run after content/structure changes to refresh the DNA.'
---

# Sync Seed

`seed.md` is the repository's DNA and rebuild blueprint. This skill regenerates its **generated sections (1–7)** so they always reflect the real repo. The **Evolution Log (section 8)** is append-only and must never be regenerated or reordered here.

---

## Procedure

### Step 1 — Read current state
- Read [seed.md](../../../seed.md) (preserve section 8 verbatim).
- Scan `.github/` (skills, prompts, agents, instructions), [README.md](../../../README.md), [ROADMAP.md](../../../ROADMAP.md), and all category folders / generated artifacts.

### Step 2 — Regenerate sections 1–7
Rewrite each section to match reality:
1. **Concept Definition** — keep the existing `concept` block unless the concept genuinely changed (changing it is a deliberate retarget, not a sync). Do not invent changes.
2. **Identity & Mission** — keep aligned with `concept.subject`.
3. **Architecture** — regenerate the inventory table from the actual files present in `.github/` (one row per file, with its purpose). Add/remove rows as files change.
4. **Content Inventory** — current taxonomy, README table row count, and the list of dedicated topic files that exist.
5. **Structure Inventory** — which generated artifacts exist (category indices, `TIMELINE.md`, `index.md`/TOC, cross-refs) vs. not-yet-generated.
6. **Growth Loop** — keep current (only change if the loop itself changed).
7. **Rebuild Procedure** — keep current.

### Step 3 — Preserve the Evolution Log
Leave section 8 exactly as-is. Appending to it is the job of the `encode-seed` prompt, not this skill.

### Step 4 — Confirm
Report which sections changed and a one-line diff summary (e.g. "Architecture: +1 file; Content: 13→15 rows").

---

## Notes
- Idempotent: if nothing changed in the repo, sections 1–7 should come out identical (no diff).
- This skill is descriptive, not creative — it mirrors what exists; it does not add content or plan work (that's `add-topic` / `plan-roadmap`).
