---
name: check-lifecycle
description: "Gate every growth tick of this self-growing knowledge base: decide whether the next run should grow, replant (spawn a successor repo), or consolidate the lineage. Use at the start of each /grow tick, after a tick completes to reconcile the counter, or whenever lifecycle state may have drifted from seed.md §8. Concept-agnostic — reads policy and state from lifecycle.yml and tick history from seed.md. Writes lifecycle.yml only."
---

# Check Lifecycle (Claude Code adapter)

Canonical procedure: **`.github/skills/check-lifecycle/SKILL.md`**. Read that file and follow it exactly.

Summary — the lifecycle gate of the growth loop:
1. **Read** `lifecycle.yml` (policy + state) and `seed.md` §8 (tick history — the source of truth).
2. **Reconcile** `state.generation_ticks` = number of `Tick N` entries in §8 after the latest `Genesis`/`Replant` entry.
3. **Decide the phase**, in priority order:
   - `consolidate` — lineage (excluding the reference origin) ≥ `consolidate_at_members` and this repo is the newest member;
   - `replant` — `generation_ticks` ≥ `replant_after_ticks` and status is `growing`;
   - `grow` — otherwise (`dormant` if the repo is already mature/consolidated).
4. **Write back** only the reconciled counter; phase transitions belong to `/replant` and `/consolidate`.

End with the `## Lifecycle Decision` block (phase, ticks, lineage size, reason, next action). This skill **decides only** — it never grows, spawns, or consolidates.
