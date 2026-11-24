# ADR-0004: The organizational genome — replantable model DNA

**Status:** Accepted (foundation); planter staged **Date:** 2026-06-18 **Deciders:** Repo owner (@bamr87) **Depends on:** [ADR-0001](ADR-0001-centralized-growth-orchestration.md), [ADR-0002](ADR-0002-tangential-era-spawning.md), [ADR-0003](ADR-0003-self-improving-agent-fleet.md)

## Context

The "seed" used to mean two small things: a per-member `lineage/seeds/<id>.md` (one knowledge base's DNA) and the old per-repo `seed-package/`. But the *whole organizational model* — centralized orchestration (ADR-0001), tangential spawning (ADR-0002), the self-improvement fleet (ADR-0003), the framework, the policy, the hub site — was only ever instantiated for one concept ("years of AI") in one org. Standing it up for a new concept (e.g. *countries*) meant re-deriving all of it.

The goal: make the **seed the DNA of the entire model**, abstracted and concept-agnostic, so it can be **planted in a new org for a new concept without reinventing the wheel**, and **kept routinely in sync** so it doesn't rot.

## Decision

Add `genome/` — the organizational genome — alongside `lineage/`:

- **One concept manifest** ([`genome/genome.yml`](../../genome/genome.yml), contract [`schema.json`](../../genome/schema.json)) isolates the entire concept-delta into ~9 required fields. [`genome.example.countries.yml`](../../genome/genome.example.countries.yml) is a complete worked fill — the proof of abstraction.
- **A 4-tier transplant inventory** ([`manifest.yml`](../../genome/manifest.yml)) classifies every concept-bearing asset: `transplant` (agnostic, verbatim), `template` (tokenized via a literal→`{{TOKEN}}` map), `override` (templated overlay), `regenerate` (narrative re-authored by a genesis agent). Everything else is `ignore`d.
- **A routine-sync gate** ([`bin/verify.rb`](../../genome/bin/verify.rb), wired into `.github/workflows/genome-sync.yml`) fails CI when the model drifts from the genome — an unclassified concept-bearing file, or a concept literal leaking into a "verbatim" file. This is what makes "routinely updated" enforceable, not aspirational.
- The full spec, transplant map, and plant runbook live in [`genome/GENOME.md`](../../genome/GENOME.md).

## Options considered

- **A — keep `seed-package/` as the bootstrap kit.** Rejected: it bootstraps *one repo*, not the org model, and (like all bootstrap kits) silently drifts. It is superseded; its concept-bearing parts now live in the genome's `override` tier.
- **B — a one-shot "fork and find/replace" doc.** Rejected: no contract, no drift protection, and a blind gsub mangles SVG labels and prose (hence the `regenerate` tier + the leak gate).
- **C — the genome with a manifest + tiered transplant + a CI sync gate (chosen).** Minimal human surface (one manifest), complete (every asset classified), and self-checking (the gate can't let it rot).

## Consequences

- **Easier:** a new concept is a manifest fill, not a rebuild; the model's improvements (every ADR-0003 agent, every framework edit) propagate to the genome under CI pressure, so a planted org inherits the *current* model.
- **Harder / watch-outs:** the genome is a third surface to keep current (mitigated by the gate); the executable planter creates public org infrastructure, so — like ADR-0002 — it runs only on an explicit go.
- **Irreducibly human:** creating the GitHub org and minting the three secrets. Everything else is automatable.

## Action Items
1. [x] `genome/` foundation: manifest, schema, `genome.yml`, the *countries* example, `bin/verify.rb`, the CI sync gate, `GENOME.md`.
2. [ ] The executable planter: `bin/render.rb`, `bin/extract.rb` (build/refresh the payload from the live repo), `bin/plant.rb` (dry-run-first, two-key confirm).
3. [ ] The grow-lineage genesis branch (a freshly-planted first member's seed §2–7).
4. [ ] A `genome-sync` agent in the ADR-0003 fleet that re-abstracts drift into a PR.
5. [ ] Retire `lineage/seed-package/README.md` + `MANIFEST.md` once the genome supersedes them (avoid two competing kits).
