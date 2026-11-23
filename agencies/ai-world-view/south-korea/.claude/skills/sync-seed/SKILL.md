---
name: sync-seed
description: "Keep seed.md (the repository DNA) in sync with the actual repo state. Use when ending a growth tick, after adding content or structure, or whenever the seed's inventories may have drifted from reality. Concept-agnostic. Regenerates seed.md sections 1–7 from the live repo; never touches the Evolution Log (section 8)."
---

# Sync Seed (Claude Code adapter)

Canonical procedure: **`.github/skills/sync-seed/SKILL.md`**. Read that file and follow it exactly.

Summary — regenerate `seed.md`'s **generated sections (1–7)** so they reflect the real repo; the **Evolution Log (section 8)** is append-only and must never be regenerated or reordered here.

1. **Read current state** — `seed.md` (preserve section 8 verbatim), `.github/` (skills/prompts/agents/instructions), `README.md`, `ROADMAP.md`, all category folders / generated artifacts.
2. **Regenerate sections 1–7** to match reality: keep the `concept` block unless genuinely retargeted; regenerate the **Architecture** inventory table from the files actually present in `.github/`; update **Content Inventory** (taxonomy, README row count, dedicated files) and **Structure Inventory** (which generated artifacts exist vs. not).
3. **Preserve section 8** exactly.
4. **Report** which sections changed (e.g. "Architecture: +1 file; Content: 13→15 rows").

Idempotent and descriptive — it mirrors what exists; it does not add content or plan work.
