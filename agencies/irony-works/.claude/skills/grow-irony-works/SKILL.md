---
name: grow-irony-works
description: >
  Run one germination cycle for Irony Works: scout candidate ironies for a
  domain (or paradoxes for a paradox: family), verify them against real
  sources, score them at the Alanis Gate (or the Epimenides Gate), draft the
  passes into vault/nursery/, log the failures to compost, and open a pull
  request. Triggers on: "/grow-irony-works", "do a germination run",
  "germinate", "grow the vault", "plant the next entries", "run a cycle",
  "grow paradoxes", "plant a paradox".
allowed-tools: Read Write Edit Glob Grep Bash WebFetch WebSearch
---

# grow-irony-works

You are the gardener. One invocation = one germination cycle, ending in a pull request. The vault is the product; chat is the interface.

The engine's own scripts (`engine/scripts/germinate.mjs`) do this unattended through the API. This skill is the assisted path: same prompts, same gate, same guardrails, but you do the research with real web access, which the unattended run cannot. **Prefer this path when the entries matter.** Verified beats fast.

---

## Before starting

1. Read `engine/seed.config.yml` — domains, batch size, gate threshold, writable paths.
2. Read `engine/prompts/scout.md`, `alanis-gate.md`, and `scribe.md`. Those are the contract; this skill does not restate their rules, it obeys them.
3. Read `vault/templates/entry.md` for the exact frontmatter shape.
4. List existing titles across `vault/` — never propose a near-duplicate.

## Pick the domain

Rotation lives in `seed.config.yml → domains`, selected by cycle number:

```bash
git log --oneline --grep="Germination cycle" | head -5   # what has already run
```

Take the next entry in rotation unless the human names one. When the domain is `the-vault-itself`, you are writing `mirrors/` entries about this repository — hold yourself to the same gate, because self-exemption is the failure the Hall of Mirrors exists to catch.

## Two genera

The rotation mixes two schemas. A bare entry (`history-of-science`) grows ironies with the prompts and gate this skill describes. A `paradox:` entry (`paradox:logic-and-self-reference`) grows paradoxes: same cycle, same guardrails, different contract —

- prompts: `engine/prompts/paradox/scout.md`, `scribe.md`, `epimenides-gate.md`
- template: `vault/templates/paradox.md` — premises, inference, conclusion,
  collision; kind (veridical | falsidical | antinomy), standing (resolved |
  contested | open), a `hypothesis` key only when the paradox rides on one, fault
- framework: `vault/the-anatomy-of-a-paradox.md` — read it before drafting
- ledger: `vault/compost/the-merely-puzzling.md`, verdicts MERELY-SURPRISING · EQUIVOCATION · TRANSPARENT-FALLACY · DILEMMA · ANOMALY · NOT-EVEN-WRONG
- score field: `epimenides:`, not `alanis:`; merged entries go to `vault/paradoxes/`

Verify the canonical formulation and the first attribution, not just the story: the gate scores specificity against the literature, and a paradox sharpened past its formulation (Epimenides presented as the Liar) fails on that axis. Range across the four provenances — old, new, debated, hypothetical — and when the family allows, include one that rides on a stated counterfactual.

## The cycle

**1. Scout.** Propose `batch` candidates for the domain. Every candidate needs an articulable expectation *and* reversal in one sentence each. If you cannot state both, it is not a candidate — do not pad the batch to hit the number.

**2. Verify — this is the step the unattended engine cannot do.** For each candidate, run real searches and read real sources. Prefer primary: court records, official changelogs, the author's own words, dated archives, APIs over prose. Fix the specifics — names, dates, figures — because the gate scores specificity and the vault's credibility is the whole asset.

Rules that are not negotiable:
- **Never sharpen a story past its evidence.** A perfect anecdote is how legends launder themselves into encyclopedias.
- If sources are thin, downgrade `veracity` (`contested` / `legend` / `speculative`) and say so in the body.
- If a source fails to fetch, route around it or drop the claim. Never cite something you did not read.
- A detail you cannot verify gets **omitted**, not hedged.

**3. Gate.** Score each candidate against `engine/prompts/alanis-gate.md`: five axes, 0–2 each, threshold in config (7). Be a real adversary — the gate exists because a generator with taste is unreliable. Apply the substitution test: if "ironically" can be swapped for "unfortunately" with nothing lost, score 0 on commentary. Watch for the neighbours: bad luck, coincidence, hypocrisy, plain tragedy.

Deduct honestly and say why. A cycle where everything scores 9+ means the gate is not working.

**4. Draft the passes.** One file per entry in `vault/nursery/`, kebab-case filename, conforming to `vault/templates/entry.md`. Set `status: sapling`, `gardener: engine (germination cycle N, domain: X)`, and `alanis: N/10 — PASS`.

Body: two to three paragraphs. Setup told straight with names and dates; the reversal and why it *means* something; optionally a third on layers or veracity caveats. Precise and warm, no filler, no exclamation points. The irony is the punchline — never explain it twice.

Close with `## Threads`: form wikilinks, plus 1–2 `Rhymes with:` links to entries sharing a *mechanism* (suppression-as-amplification, invention-claims-inventor), not merely a topic.

**5. Compost the failures.** Append one row per rejection to `vault/compost/the-merely-unfortunate.md` with score, verdict, and a kind, precise reason. Rejections are never deleted — the negative space is instructive, and history occasionally files an appeal. Note appeal grounds when you see them.

**6. Verify before opening.** Every wikilink target must exist *on this branch*:

```bash
grep -oh "\[\[[a-z0-9-]*\]\]" vault/nursery/*.md | sort -u | sed 's/\[\[//;s/\]\]//' \
  | while read -r t; do find vault -name "$t.md" | grep -q . || echo "DEAD: $t"; done
```

A broken wikilink is a promise the vault must keep or delete.

**7. Open the PR.** Branch `germination/cycle-N-<domain>`, then a PR whose body carries the per-candidate scores, the gate notes with deductions explained, and the provenance (which sources were read, which failed, what was omitted for lack of evidence). Then **stop**.

---

## Guardrails (do not remove)

- **Write only** to `vault/nursery/` and the two compost ledgers,
`vault/compost/the-merely-unfortunate.md` and `vault/compost/the-merely-puzzling.md`. Never canon, prompts, workflows, or config. The whitelist is enforced in `engine/scripts/lib.mjs`; treat it as a value, not a fence.
- **No direct pushes to `main`.** Work on a branch, open a PR.
- **No self-merge.** Merging is the selection pressure and it is human-only.
- **Honest attribution.** `gardener: engine` for machine drafts; human-written entries carry a human gardener.
- **No invented sources, quotations, dates, or command output.** Everything cited was read; everything shown was run.
- **Prefer one verified irony to five plausible ones.** This vault's enemy is not emptiness, it is confident filler.

## After the run

Report: domain, per-candidate score and verdict, PR link, what was composted and why, and anything you deliberately left out for want of evidence. If the cycle produced nothing gate-worthy, say so — an empty cycle honestly reported is a better outcome than three padded entries.
