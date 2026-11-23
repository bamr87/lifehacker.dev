# ADR-0007: Maturity-gated automatic spawning

**Status:** Accepted **Date:** 2026-07-29 **Deciders:** Repo owner (@bamr87) **Depends on:** [ADR-0002](ADR-0002-tangential-era-spawning.md) (the spawn mechanism), [ADR-0003](ADR-0003-self-improving-agent-fleet.md) (kill-switch + serializer doctrine), [ADR-0006](ADR-0006-operational-hardening-and-cadence.md) (cadence + gate-job pattern)

## Context

ADR-0002 built tangential spawning as a **manual** two-key operation (a human or model authors the seed, then `plant-lineage.rb --apply --confirm <id>`) and explicitly deferred automation: *"Once proven, a later ADR can gate automatic spawning on a frontier-maturity signal (e.g. the newest repo passing a tick/coverage threshold)."* The manual path is proven (`2012` was spawned this way and is growing), and the owner has asked for the deferred capability: the lineage should **widen on its own** — a new member repo after so many growth cycles — in this hub and in every org planted from this model (the ai-world-view hub adopts it in the same change, spawning new country repos beyond `japan`).

## Decision

Automatic spawning is **policy-gated, maturity-gated, and self-regulating**:

```
orchestrate.yml (daily)                      plant-lineage.yml
──────────────────────                       ────────────────────────────────
after grow dispatch, compute:        →       RE-VERIFY the same gate from a
  spawn.enabled                              fresh checkout (never trust the
  AND every member's ticks_logged            dispatcher; not-due = clean no-op)
      >= spawn.frontier_ticks                DECIDE (policy `distill` model):
  AND roster < spawn.max_members             author ONE tangential seed
if due → dispatch plant-lineage              validate: exactly one new seed,
        -f auto=true                           valid slug, §8 empty, else abort
                                             PLANT: plant-lineage.rb --apply
                                             commit seed to hub main (AFTER
                                               the repo exists)
```

### The maturity signal (why `min(ticks) >= frontier_ticks`)

Spawn only when **every member — including the newest — has logged at least `spawn.frontier_ticks` growth cycles** (from `_data/lineage.yml` `ticks_logged`, itself derived from each seed's §8 Evolution Log). Properties:

- **Stateless**: no "last spawn" bookkeeping to persist or lose — each spawn adds a 0-tick member that blocks the next spawn until it matures. The spawn *interval* is therefore `frontier_ticks` growth cycles of the newest repo, which is exactly "a new repo after so many growth cycles".
- **Fleet-health-first**: one stalled member (never ticking) freezes widening — deliberate: deepen reliably before widening further.
- **Race-safe**: the planted seed reaches hub main before the next orchestrate refreshes the ledger, so the new 0-tick member closes the gate on the very next evaluation; plant-lineage re-verifies on a fresh checkout and the planter is idempotent (refuses existing repos/seeds), so a stale or duplicate dispatch plants nothing.

### The two keys in auto mode

ADR-0002 rejected fully-autonomous spawning "with zero human gate". Auto mode keeps two independent gates in place of the human keys, per the owner's explicit request for automation:

1. the **policy gate** — `spawn.enabled` + the maturity signal + the `max_members` hard cap, re-verified inside the workflow from a fresh checkout, beneath the fleet kill-switch (`_data/fleet_pause.yml`);
2. the **DECIDE-output validation** — the model pass is untrusted: the workflow accepts exactly ONE new `lineage/seeds/<id>.md` (valid slug, `subject:` present, empty §8) and touches nothing else, or plants nothing.

The manual path (pre-authored seed + `confirm==id` two-key + dry-run default) is unchanged and remains the recovery/override route.

### Configuration (`lineage/policy.yml`)

```yaml
spawn:
  enabled: true          # false stops all automatic spawning (manual path stays)
  frontier_ticks: 12     # growth cycles EVERY member must log between spawns
  max_members: 16        # hard roster cap — auto-spawn never exceeds it
```

## Consequences

**Easier** — the lineage widens without operator attention, at a rate the policy controls; planted orgs (ai-world-view) inherit the same behavior with only concept-level prompt differences (tangential *country*, no-web rule).

**Harder / watch-outs** — public repo creation is still effectively irreversible: the cap, the kill-switch, the idempotent planter, and the one-repo-per-run rule are the containment. The DECIDE pass consumes a frontier-model call per spawn (rare by construction). `LIFECYCLE_PAT` must hold org repo-creation scope; `secret-expiry-watch` already probes it daily.

**To revisit** — per-member maturity weighting (coverage, not just tick count); letting DECIDE consult the telemetry ledger for subject gaps.

## Action items

1. [x] `spawn:` policy block in both hubs.
2. [x] `plant-lineage.yml` (auto + manual modes) in both hubs — closes ADR-0002 action item 4.
3. [x] Orchestrate spawn-check + dispatch in both hubs.
4. [x] Docs (`ARCHITECTURE.md` §8, CLAUDE.md, `/orchestration/`), genome classification, changelog.
