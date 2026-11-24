---
name: check-lifecycle
description: "Gate every growth tick of this self-growing knowledge base: decide whether the next run should grow, replant (spawn a successor repo), or consolidate the lineage. Use at the start of each /grow tick, after a tick completes to reconcile the counter, or whenever lifecycle state may have drifted from seed.md §8. Concept-agnostic — reads policy and state from lifecycle.yml and tick history from seed.md. Writes lifecycle.yml only."
---

# Check Lifecycle

Decide which **phase** the next run of this repository should execute: `grow`, `replant`, `consolidate`, or `expand`. This skill is the gate at the start of every tick and the reconciler at the end of one. It never grows content, spawns repos, or consolidates anything itself — it only reads state, repairs the counter, and reports a decision.

## Inputs

- [lifecycle.yml](../../../lifecycle.yml) — policy knobs (`replant_after_ticks`, `consolidate_at_members`, succession/consolidation rules) and current state.
- [seed.md](../../../seed.md) §8 Evolution Log — the source of truth for tick history.

## Procedure

1. **Read** `lifecycle.yml`. If it does not exist, create it from the template documented in [LIFECYCLE.md](../../../LIFECYCLE.md), inferring `lineage` from the seed's Identity section and `generation_ticks` from step 2.
2. **Count generation ticks** — if `state.status` is `mature`, the generation is closed and `state.generation_ticks` is finalized; skip the §8 recount, skip the write-back, and proceed directly to step 3 (which will report `dormant`). Otherwise, count from seed.md §8: the number of growth-tick entries (entries titled `Tick N: …`) appended **after** the most recent `Genesis` or `Replant` entry. Reconcile `state.generation_ticks` to this count — §8 wins over the YAML on any disagreement. **Stall diagnostic**: if `generation_ticks` does not advance despite §8 having new entries, check that the safety-net in `grow.yml` titles its §8 headers with the `Tick N:` scheme (the same format `encode-seed` uses). Any other title (e.g. "Growth tick (safety net)") is invisible to this counter and will stall the generation indefinitely.
3. **Decide the phase**, in priority order:
   - `consolidate` — if `state.lineage` (excluding `state.origin`) has ≥ `consolidate_at_members` entries, this repo is the **newest** lineage member, `state.status` is `growing`, **and this member has finished its growth generation** (`state.generation_ticks` ≥ `replant_after_ticks`). The final member grows its full generation first, **then consolidates instead of replanting** (no extra member is spawned). A freshly-spawned final member (ticks < budget) keeps growing — it must NOT be consolidated half-grown.
   - `expand` — if `state.status` is `consolidated`. **Consolidation is not terminal**: a consolidated repo keeps growing at a finer time granularity (`state.granularity`, default `month`) and seeds the next era's lineage. Report `expand`, never `dormant`, for a consolidated repo.
   - `replant` — if `state.generation_ticks` ≥ `replant_after_ticks` and `state.status` is `growing` (and the consolidate condition above did not fire — i.e. the lineage is below the consolidation threshold, or this is not the newest member).
   - `grow` — otherwise. A `mature` repo reports `dormant` (or runs shepherd mode for the lineage); a `growing` repo under its tick budget reports `grow`.
4. **Write back** the reconciled `state.generation_ticks` (and nothing else — phase transitions are written by the `replant` / `consolidate` / `expand` prompts, not by this skill).

## Output Format

A single decision block:

```
## Lifecycle Decision

**Phase**: grow | replant | consolidate | dormant
**Generation ticks**: <n> / <replant_after_ticks>
**Lineage size**: <m> / <consolidate_at_members>
**Reason**: <one line>
**Next**: <run a normal tick | run the replant prompt | run the consolidate prompt | nothing — repo is mature/consolidated>
```
